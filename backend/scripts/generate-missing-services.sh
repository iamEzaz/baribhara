#!/bin/bash

# Script to generate missing service implementations
# This ensures all services have complete implementations

echo "🚀 Generating missing service implementations..."

# Function to create service structure
create_service() {
    local service_name=$1
    local port=$2
    local grpc_port=$3
    
    echo "Creating $service_name service..."
    
    # Create main.ts
    cat > "services/$service_name/src/main.ts" << EOF
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { join } from 'path';

import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalInterceptors(new LoggingInterceptor());

  app.enableCors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true,
  });

  const config = new DocumentBuilder()
    .setTitle('Baribhara $service_name')
    .setDescription('$service_name Service')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const microservice = app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.GRPC,
    options: {
      package: '${service_name//-/_}',
      protoPath: join(__dirname, 'proto/${service_name//-/_}.proto'),
      url: \`0.0.0.0:\${process.env.GRPC_PORT || $grpc_port}\`,
    },
  });

  await app.startAllMicroservices();
  
  const port = process.env.PORT || $port;
  await app.listen(port);
  
  console.log(\`🔧 $service_name running on port \${port}\`);
  console.log(\`📚 Swagger docs: http://localhost:\${port}/api/docs\`);
  console.log(\`🔌 gRPC server running on port \${process.env.GRPC_PORT || $grpc_port}\`);
}

bootstrap();
EOF

    # Create app.module.ts
    cat > "services/$service_name/src/app.module.ts" << EOF
import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DatabaseModule } from './common/database/database.module';
import { RedisModule } from './common/redis/redis.module';
import { KafkaModule } from './common/kafka/kafka.module';
import { HealthController } from './controllers/health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),
    
    DatabaseModule,
    RedisModule,
    KafkaModule,
  ],
  controllers: [HealthController],
  providers: [],
  exports: [],
})
export class AppModule {}
EOF

    # Create health controller
    cat > "services/$service_name/src/controllers/health.controller.ts" << EOF
import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('health')
@Controller('health')
export class HealthController {
  @Get()
  @ApiOperation({ summary: 'Health check endpoint' })
  @ApiResponse({ status: 200, description: 'Service is healthy' })
  check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: '$service_name',
      version: '1.0.0',
    };
  }

  @Get('ready')
  @ApiOperation({ summary: 'Readiness check endpoint' })
  @ApiResponse({ status: 200, description: 'Service is ready' })
  ready() {
    return {
      status: 'ready',
      timestamp: new Date().toISOString(),
      service: '$service_name',
    };
  }

  @Get('live')
  @ApiOperation({ summary: 'Liveness check endpoint' })
  @ApiResponse({ status: 200, description: 'Service is alive' })
  live() {
    return {
      status: 'alive',
      timestamp: new Date().toISOString(),
      service: '$service_name',
    };
  }
}
EOF

    # Create common modules
    mkdir -p "services/$service_name/src/common/database"
    mkdir -p "services/$service_name/src/common/redis"
    mkdir -p "services/$service_name/src/common/kafka"
    mkdir -p "services/$service_name/src/common/filters"
    mkdir -p "services/$service_name/src/common/interceptors"
    mkdir -p "services/$service_name/src/guards"

    # Copy common modules from auth-service
    cp services/auth-service/src/common/database/database.module.ts "services/$service_name/src/common/database/"
    cp services/auth-service/src/common/redis/redis.module.ts "services/$service_name/src/common/redis/"
    cp services/auth-service/src/common/redis/redis.service.ts "services/$service_name/src/common/redis/"
    cp services/auth-service/src/common/kafka/kafka.module.ts "services/$service_name/src/common/kafka/"
    cp services/auth-service/src/common/kafka/kafka.service.ts "services/$service_name/src/common/kafka/"
    cp services/property-service/src/common/filters/http-exception.filter.ts "services/$service_name/src/common/filters/"
    cp services/property-service/src/common/interceptors/logging.interceptor.ts "services/$service_name/src/common/interceptors/"
    cp services/property-service/src/guards/jwt-auth.guard.ts "services/$service_name/src/guards/"

    # Create Dockerfile
    cat > "services/$service_name/Dockerfile" << EOF
# Multi-stage build for production
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
COPY tsconfig*.json ./
RUN npm ci --only=production && npm cache clean --force

COPY src/ ./src/
RUN npm run build

FROM node:18-alpine AS production
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nestjs -u 1001

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

COPY --from=builder /app/dist ./dist
RUN chown -R nestjs:nodejs /app
USER nestjs

EXPOSE $port $grpc_port

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \\
  CMD node -e "require('http').get('http://localhost:$port/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

CMD ["node", "dist/main.js"]
EOF

    echo "✅ $service_name service created"
}

# Create missing services
create_service "tenant-service" 3004 50054
create_service "invoice-service" 3005 50055
create_service "notification-service" 3006 50056
create_service "report-service" 3007 50057
create_service "admin-service" 3008 50058

echo "🎉 All missing services generated successfully!"
echo "📝 Next steps:"
echo "1. Add specific controllers and services for each service"
echo "2. Add entity definitions"
echo "3. Add business logic"
echo "4. Test each service"
