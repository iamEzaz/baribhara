import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Global validation pipe
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }));

  // CORS configuration
  app.enableCors({
    origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000', 'http://localhost:8080'],
    credentials: true,
  });

  // Swagger documentation
  const config = new DocumentBuilder()
    .setTitle('Baribhara API')
    .setDescription('Property Management System API - All Services as Modules')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('auth', 'Authentication and authorization')
    .addTag('users', 'User profile management')
    .addTag('properties', 'Property management and listings')
    .addTag('tenants', 'Tenant management and relationships')
    .addTag('invoices', 'Billing and payment processing')
    .addTag('notifications', 'Multi-channel notifications')
    .addTag('reports', 'Analytics and reporting')
    .addTag('admin', 'Super admin functionality')
    .addTag('caretakers', 'Caretaker management')
    .addTag('dashboard', 'Real-time dashboards and analytics')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT || 3000;
  await app.listen(port);
  
  console.log(`🚀 Baribhara NestJS Services running on port ${port}`);
  console.log(`📚 API Documentation: http://localhost:${port}/api/docs`);
  console.log(`🔗 Health Check: http://localhost:${port}/health`);
}

bootstrap();
