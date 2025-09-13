import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tenant } from '../src/entities/tenant.entity';

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
        provide: getRepositoryToken(Tenant),
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
export const createMockTenant = (overrides: Partial<Tenant> = {}): Tenant => ({
  id: 'test-tenant-id',
  name: 'Test Tenant',
  phoneNumber: '+8801000000000',
  email: 'tenant@example.com',
  nationalId: '1234567890123',
  type: 'INDIVIDUAL' as any,
  status: 'ACTIVE' as any,
  emergencyContactName: 'Emergency Contact',
  emergencyContactPhone: '+8801000000001',
  emergencyContactRelation: 'Spouse',
  street: '123 Test Street',
  city: 'Dhaka',
  district: 'Dhanmondi',
  division: 'Dhaka',
  postalCode: '1205',
  occupation: 'Software Engineer',
  employer: 'Test Company',
  monthlyIncome: 100000,
  preferences: ['Parking', 'Lift'],
  documents: ['nid.jpg', 'photo.jpg'],
  userId: 'test-user-id',
  currentPropertyId: null,
  caretakerId: null,
  leaseStartDate: null,
  leaseEndDate: null,
  monthlyRent: null,
  securityDeposit: null,
  leaseTerms: null,
  preferredPaymentMethod: 'bKash',
  bankAccountNumber: '1234567890',
  bankName: 'Test Bank',
  bkashNumber: '+8801000000000',
  nagadNumber: '+8801000000000',
  isVerified: false,
  verifiedAt: null,
  totalProperties: 0,
  activeLeases: 0,
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
