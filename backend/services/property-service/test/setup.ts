import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Property } from '../src/entities/property.entity';

// Mock repository factory
export const createMockRepository = () => ({
  find: jest.fn(),
  findOne: jest.fn(),
  findOneBy: jest.fn(),
  create: jest.fn(),
  save: jest.fn(),
  update: jest.fn(),
  delete: jest.fn(),
  createQueryBuilder: jest.fn(() => ({
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    orWhere: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    addOrderBy: jest.fn().mockReturnThis(),
    skip: jest.fn().mockReturnThis(),
    take: jest.fn().mockReturnThis(),
    getManyAndCount: jest.fn(),
    getMany: jest.fn(),
    getOne: jest.fn(),
    getRawOne: jest.fn(),
    getRawMany: jest.fn(),
  })),
});

// Mock Redis service
export const createMockRedisService = () => ({
  get: jest.fn(),
  set: jest.fn(),
  del: jest.fn(),
  exists: jest.fn(),
  expire: jest.fn(),
  ttl: jest.fn(),
  hget: jest.fn(),
  hset: jest.fn(),
  hgetall: jest.fn(),
  hdel: jest.fn(),
  sadd: jest.fn(),
  smembers: jest.fn(),
  srem: jest.fn(),
  lpush: jest.fn(),
  rpop: jest.fn(),
  llen: jest.fn(),
  lrange: jest.fn(),
});

// Mock Kafka service
export const createMockKafkaService = () => ({
  emit: jest.fn(),
  subscribe: jest.fn(),
  unsubscribe: jest.fn(),
});

// Test utilities
export const createTestModule = async (providers: any[] = []) => {
  const module: TestingModule = await Test.createTestingModule({
    providers: [
      ...providers,
      {
        provide: getRepositoryToken(Property),
        useValue: createMockRepository(),
      },
      {
        provide: 'RedisService',
        useValue: createMockRedisService(),
      },
      {
        provide: 'KafkaService',
        useValue: createMockKafkaService(),
      },
    ],
  }).compile();

  return module;
};

// Test data factories
export const createMockProperty = (overrides: Partial<Property> = {}): Property => ({
  id: 'test-property-id',
  name: 'Test Property',
  description: 'Test Description',
  type: 'APARTMENT' as any,
  status: 'AVAILABLE' as any,
  street: '123 Test Street',
  city: 'Dhaka',
  district: 'Dhanmondi',
  division: 'Dhaka',
  postalCode: '1205',
  landmark: 'Near Test Landmark',
  rentAmount: 50000,
  securityDeposit: 100000,
  area: 1200,
  bedrooms: 3,
  bathrooms: 2,
  floor: 5,
  totalFloors: 10,
  amenities: ['Parking', 'Lift', 'Generator'],
  images: ['image1.jpg', 'image2.jpg'],
  caretakerId: 'test-caretaker-id',
  currentTenantId: null,
  createdAt: new Date('2024-01-01T00:00:00Z'),
  updatedAt: new Date('2024-01-01T00:00:00Z'),
  ...overrides,
});

// Global test setup
beforeAll(async () => {
  // Setup any global test configuration
});

afterAll(async () => {
  // Cleanup any global test resources
});

beforeEach(() => {
  // Reset mocks before each test
  jest.clearAllMocks();
});
