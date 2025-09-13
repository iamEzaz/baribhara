import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException, ConflictException } from '@nestjs/common';
import { PropertyService } from './property.service';
import { Property } from '../entities/property.entity';
import { CreatePropertyDto, UpdatePropertyDto, PropertyType, PropertyStatus } from '@baribhara/shared-types';
import { RedisService } from '../common/redis/redis.service';
import { KafkaService } from '../common/kafka/kafka.service';
import { createMockRepository, createMockRedisService, createMockKafkaService, createMockProperty } from '../../test/setup';

describe('PropertyService', () => {
  let service: PropertyService;
  let propertyRepository: jest.Mocked<Repository<Property>>;
  let redisService: jest.Mocked<RedisService>;
  let kafkaService: jest.Mocked<KafkaService>;

  beforeEach(async () => {
    const mockRepository = createMockRepository();
    const mockRedisService = createMockRedisService();
    const mockKafkaService = createMockKafkaService();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PropertyService,
        {
          provide: getRepositoryToken(Property),
          useValue: mockRepository,
        },
        {
          provide: RedisService,
          useValue: mockRedisService,
        },
        {
          provide: KafkaService,
          useValue: mockKafkaService,
        },
      ],
    }).compile();

    service = module.get<PropertyService>(PropertyService);
    propertyRepository = module.get(getRepositoryToken(Property));
    redisService = module.get<RedisService>(RedisService);
    kafkaService = module.get<KafkaService>(KafkaService);
  });

  describe('create', () => {
    it('should create a new property successfully', async () => {
      const createPropertyDto: CreatePropertyDto = {
        name: 'Test Property',
        description: 'Test Description',
        type: PropertyType.APARTMENT,
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
      };

      const mockProperty = createMockProperty();
      propertyRepository.create.mockReturnValue(mockProperty as any);
      propertyRepository.save.mockResolvedValue(mockProperty as any);
      redisService.set.mockResolvedValue('OK');
      kafkaService.emit.mockResolvedValue(undefined);

      const result = await service.create(createPropertyDto);

      expect(propertyRepository.create).toHaveBeenCalledWith({
        ...createPropertyDto,
        status: PropertyStatus.AVAILABLE,
      });
      expect(propertyRepository.save).toHaveBeenCalledWith(mockProperty);
      expect(redisService.set).toHaveBeenCalledWith(
        `property:${mockProperty.id}`,
        expect.any(String),
        3600
      );
      expect(kafkaService.emit).toHaveBeenCalledWith('property.created', {
        propertyId: mockProperty.id,
        caretakerId: mockProperty.caretakerId,
        type: mockProperty.type,
      });
      expect(result).toEqual(expect.objectContaining({
        id: mockProperty.id,
        name: mockProperty.name,
        type: mockProperty.type,
        status: mockProperty.status,
      }));
    });
  });

  describe('findOne', () => {
    it('should return property from cache if available', async () => {
      const mockProperty = createMockProperty();
      const cachedProperty = JSON.stringify(mockProperty);
      redisService.get.mockResolvedValue(cachedProperty);

      const result = await service.findOne('test-property-id');

      expect(redisService.get).toHaveBeenCalledWith('property:test-property-id');
      expect(propertyRepository.findOne).not.toHaveBeenCalled();
      expect(result).toEqual(mockProperty);
    });

    it('should fetch from database and cache if not in cache', async () => {
      const mockProperty = createMockProperty();
      redisService.get.mockResolvedValue(null);
      propertyRepository.findOne.mockResolvedValue(mockProperty as any);
      redisService.set.mockResolvedValue('OK');

      const result = await service.findOne('test-property-id');

      expect(redisService.get).toHaveBeenCalledWith('property:test-property-id');
      expect(propertyRepository.findOne).toHaveBeenCalledWith({
        where: { id: 'test-property-id' },
      });
      expect(redisService.set).toHaveBeenCalledWith(
        'property:test-property-id',
        expect.any(String),
        3600
      );
      expect(result).toEqual(expect.objectContaining({
        id: mockProperty.id,
        name: mockProperty.name,
      }));
    });

    it('should throw NotFoundException if property not found', async () => {
      redisService.get.mockResolvedValue(null);
      propertyRepository.findOne.mockResolvedValue(null);

      await expect(service.findOne('non-existent-id')).rejects.toThrow(NotFoundException);
    });
  });

  describe('update', () => {
    it('should update property successfully', async () => {
      const mockProperty = createMockProperty();
      const updateDto: UpdatePropertyDto = {
        name: 'Updated Property Name',
        description: 'Updated Description',
      };
      const updatedProperty = { ...mockProperty, ...updateDto };

      propertyRepository.findOne.mockResolvedValue(mockProperty as any);
      propertyRepository.save.mockResolvedValue(updatedProperty as any);
      redisService.set.mockResolvedValue('OK');
      kafkaService.emit.mockResolvedValue(undefined);

      const result = await service.update('test-property-id', updateDto);

      expect(propertyRepository.findOne).toHaveBeenCalledWith({
        where: { id: 'test-property-id' },
      });
      expect(propertyRepository.save).toHaveBeenCalledWith(updatedProperty);
      expect(redisService.set).toHaveBeenCalledWith(
        'property:test-property-id',
        expect.any(String),
        3600
      );
      expect(kafkaService.emit).toHaveBeenCalledWith('property.updated', {
        propertyId: updatedProperty.id,
        caretakerId: updatedProperty.caretakerId,
        changes: updateDto,
      });
      expect(result).toEqual(expect.objectContaining({
        id: updatedProperty.id,
        name: updateDto.name,
        description: updateDto.description,
      }));
    });

    it('should throw NotFoundException if property not found', async () => {
      const updateDto: UpdatePropertyDto = { name: 'Updated Name' };
      propertyRepository.findOne.mockResolvedValue(null);

      await expect(service.update('non-existent-id', updateDto)).rejects.toThrow(NotFoundException);
    });
  });

  describe('remove', () => {
    it('should delete property successfully', async () => {
      propertyRepository.delete.mockResolvedValue({ affected: 1 } as any);
      redisService.del.mockResolvedValue(1);
      kafkaService.emit.mockResolvedValue(undefined);

      await service.remove('test-property-id');

      expect(propertyRepository.delete).toHaveBeenCalledWith('test-property-id');
      expect(redisService.del).toHaveBeenCalledWith('property:test-property-id');
      expect(kafkaService.emit).toHaveBeenCalledWith('property.deleted', {
        propertyId: 'test-property-id',
      });
    });

    it('should throw NotFoundException if property not found', async () => {
      propertyRepository.delete.mockResolvedValue({ affected: 0 } as any);

      await expect(service.remove('non-existent-id')).rejects.toThrow(NotFoundException);
    });
  });

  describe('search', () => {
    it('should search properties with filters', async () => {
      const searchParams = {
        query: 'test',
        city: 'Dhaka',
        type: 'APARTMENT',
        minRent: 30000,
        maxRent: 100000,
        page: 1,
        limit: 10,
      };

      const mockProperties = [createMockProperty()];
      const mockQueryBuilder = {
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        skip: jest.fn().mockReturnThis(),
        take: jest.fn().mockReturnThis(),
        getManyAndCount: jest.fn().mockResolvedValue([mockProperties, 1]),
      };

      propertyRepository.createQueryBuilder.mockReturnValue(mockQueryBuilder as any);

      const result = await service.search(searchParams);

      expect(propertyRepository.createQueryBuilder).toHaveBeenCalledWith('property');
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        'property.name ILIKE :query OR property.city ILIKE :query OR property.district ILIKE :query',
        { query: '%test%' }
      );
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith('property.city = :city', { city: 'Dhaka' });
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith('property.type = :type', { type: 'APARTMENT' });
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith('property.rentAmount >= :minRent', { minRent: 30000 });
      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith('property.rentAmount <= :maxRent', { maxRent: 100000 });
      expect(result).toEqual({
        properties: expect.arrayContaining([
          expect.objectContaining({
            id: mockProperties[0].id,
            name: mockProperties[0].name,
          }),
        ]),
        total: 1,
        page: 1,
        limit: 10,
      });
    });
  });
});
