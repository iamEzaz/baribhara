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
    .setTitle('Baribhara Tenant Service')
    .setDescription('Tenant Management Service')
    .setVersion('1.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const microservice = app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.GRPC,
    options: {
      package: 'tenant',
      protoPath: join(__dirname, 'proto/tenant.proto'),
      url: `0.0.0.0:${process.env.GRPC_PORT || 50054}`,
    },
  });

  await app.startAllMicroservices();
  
  const port = process.env.PORT || 3004;
  await app.listen(port);
  
  console.log(`🏠 Tenant Service running on port ${port}`);
  console.log(`📚 Swagger docs: http://localhost:${port}/api/docs`);
  console.log(`🔌 gRPC server running on port ${process.env.GRPC_PORT || 50054}`);
}

bootstrap();