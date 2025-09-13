import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';

// Mock external dependencies
jest.mock('ioredis');
jest.mock('kafkajs');

export class TestHelper {
  static async createTestingModule(providers: any[] = [], imports: any[] = []): Promise<TestingModule> {
    return Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          envFilePath: ['.env.test'],
        }),
        TypeOrmModule.forRoot({
          type: 'sqlite',
          database: ':memory:',
          entities: [__dirname + '/../src/entities/*.entity{.ts,.js}'],
          synchronize: true,
          logging: false,
        }),
        JwtModule.register({
          secret: 'test-secret',
          signOptions: { expiresIn: '1h' },
        }),
        ...imports,
      ],
      providers,
    }).compile();
  }

  static async createApp(module: TestingModule): Promise<INestApplication> {
    const app = module.createNestApplication();
    await app.init();
    return app;
  }

  static async closeApp(app: INestApplication): Promise<void> {
    await app.close();
  }
}

// Global test setup
beforeAll(async () => {
  // Setup global test configuration
});

afterAll(async () => {
  // Cleanup global test configuration
});

// Mock console methods to reduce noise in tests
global.console = {
  ...console,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
};
