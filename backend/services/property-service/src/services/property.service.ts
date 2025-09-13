import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Property } from '../entities/property.entity';
import { CreatePropertyDto, UpdatePropertyDto, PropertyResponseDto, PaginationDto, PropertyType, PropertyStatus } from '@baribhara/shared-types';
import { RedisService } from '../common/redis/redis.service';
import { KafkaService } from '../common/kafka/kafka.service';

@Injectable()
export class PropertyService {
  constructor(
    @InjectRepository(Property)
    private propertyRepository: Repository<Property>,
    private redisService: RedisService,
    private kafkaService: KafkaService,
  ) {}

  async create(createPropertyDto: CreatePropertyDto): Promise<PropertyResponseDto> {
    const property = this.propertyRepository.create({
      ...createPropertyDto,
      status: PropertyStatus.AVAILABLE,
    });

    const savedProperty = await this.propertyRepository.save(property);

    // Cache property data
    await this.redisService.set(`property:${savedProperty.id}`, JSON.stringify(this.mapPropertyToResponse(savedProperty)), 3600);

    // Emit property created event
    await this.kafkaService.emit('property.created', {
      propertyId: savedProperty.id,
      caretakerId: savedProperty.caretakerId,
      type: savedProperty.type,
    });

    return this.mapPropertyToResponse(savedProperty);
  }

  async findAll(paginationDto: PaginationDto): Promise<{ properties: PropertyResponseDto[]; total: number; page: number; limit: number }> {
    const { page = 1, limit = 10, search, sortBy = 'createdAt', sortOrder = 'DESC' } = paginationDto;
    const skip = (page - 1) * limit;

    const queryBuilder = this.propertyRepository.createQueryBuilder('property');

    if (search) {
      queryBuilder.where(
        'property.name ILIKE :search OR property.city ILIKE :search OR property.district ILIKE :search',
        { search: `%${search}%` }
      );
    }

    const [properties, total] = await queryBuilder
      .orderBy(`property.${sortBy}`, sortOrder as 'ASC' | 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      properties: properties.map(property => this.mapPropertyToResponse(property)),
      total,
      page,
      limit,
    };
  }

  async search(searchParams: {
    query?: string;
    city?: string;
    district?: string;
    type?: string;
    minRent?: number;
    maxRent?: number;
    minBedrooms?: number;
    maxBedrooms?: number;
    page: number;
    limit: number;
  }): Promise<{ properties: PropertyResponseDto[]; total: number; page: number; limit: number }> {
    const { query, city, district, type, minRent, maxRent, minBedrooms, maxBedrooms, page, limit } = searchParams;
    const skip = (page - 1) * limit;

    const queryBuilder = this.propertyRepository.createQueryBuilder('property');

    if (query) {
      queryBuilder.andWhere(
        'property.name ILIKE :query OR property.city ILIKE :query OR property.district ILIKE :query',
        { query: `%${query}%` }
      );
    }

    if (city) {
      queryBuilder.andWhere('property.city = :city', { city });
    }

    if (district) {
      queryBuilder.andWhere('property.district = :district', { district });
    }

    if (type) {
      queryBuilder.andWhere('property.type = :type', { type });
    }

    if (minRent !== undefined) {
      queryBuilder.andWhere('property.rentAmount >= :minRent', { minRent });
    }

    if (maxRent !== undefined) {
      queryBuilder.andWhere('property.rentAmount <= :maxRent', { maxRent });
    }

    if (minBedrooms !== undefined) {
      queryBuilder.andWhere('property.bedrooms >= :minBedrooms', { minBedrooms });
    }

    if (maxBedrooms !== undefined) {
      queryBuilder.andWhere('property.bedrooms <= :maxBedrooms', { maxBedrooms });
    }

    queryBuilder.andWhere('property.status = :status', { status: PropertyStatus.AVAILABLE });

    const [properties, total] = await queryBuilder
      .orderBy('property.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      properties: properties.map(property => this.mapPropertyToResponse(property)),
      total,
      page,
      limit,
    };
  }

  async findByCaretaker(caretakerId: string, paginationDto: PaginationDto): Promise<{ properties: PropertyResponseDto[]; total: number; page: number; limit: number }> {
    const { page = 1, limit = 10, search, sortBy = 'createdAt', sortOrder = 'DESC' } = paginationDto;
    const skip = (page - 1) * limit;

    const queryBuilder = this.propertyRepository.createQueryBuilder('property')
      .where('property.caretakerId = :caretakerId', { caretakerId });

    if (search) {
      queryBuilder.andWhere(
        'property.name ILIKE :search OR property.city ILIKE :search OR property.district ILIKE :search',
        { search: `%${search}%` }
      );
    }

    const [properties, total] = await queryBuilder
      .orderBy(`property.${sortBy}`, sortOrder as 'ASC' | 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      properties: properties.map(property => this.mapPropertyToResponse(property)),
      total,
      page,
      limit,
    };
  }

  async findOne(id: string): Promise<PropertyResponseDto> {
    // Try cache first
    const cachedProperty = await this.redisService.get(`property:${id}`);
    if (cachedProperty) {
      return JSON.parse(cachedProperty);
    }

    const property = await this.propertyRepository.findOne({ where: { id } });
    if (!property) {
      throw new NotFoundException('Property not found');
    }

    const propertyResponse = this.mapPropertyToResponse(property);
    
    // Cache property data
    await this.redisService.set(`property:${id}`, JSON.stringify(propertyResponse), 3600);

    return propertyResponse;
  }

  async update(id: string, updatePropertyDto: UpdatePropertyDto): Promise<PropertyResponseDto> {
    const property = await this.propertyRepository.findOne({ where: { id } });
    if (!property) {
      throw new NotFoundException('Property not found');
    }

    Object.assign(property, updatePropertyDto);
    const updatedProperty = await this.propertyRepository.save(property);

    // Update cache
    await this.redisService.set(`property:${id}`, JSON.stringify(this.mapPropertyToResponse(updatedProperty)), 3600);

    // Emit property updated event
    await this.kafkaService.emit('property.updated', {
      propertyId: updatedProperty.id,
      caretakerId: updatedProperty.caretakerId,
      changes: updatePropertyDto,
    });

    return this.mapPropertyToResponse(updatedProperty);
  }

  async remove(id: string): Promise<void> {
    const result = await this.propertyRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException('Property not found');
    }

    // Remove from cache
    await this.redisService.del(`property:${id}`);

    // Emit property deleted event
    await this.kafkaService.emit('property.deleted', {
      propertyId: id,
    });
  }

  private mapPropertyToResponse(property: Property): PropertyResponseDto {
    return {
      id: property.id,
      name: property.name,
      description: property.description,
      type: property.type,
      status: property.status,
      address: {
        street: property.street,
        city: property.city,
        district: property.district,
        division: property.division,
        postalCode: property.postalCode,
        landmark: property.landmark,
      },
      rentAmount: property.rentAmount,
      securityDeposit: property.securityDeposit,
      area: property.area,
      bedrooms: property.bedrooms,
      bathrooms: property.bathrooms,
      floor: property.floor,
      totalFloors: property.totalFloors,
      amenities: property.amenities,
      images: property.images,
      caretakerId: property.caretakerId,
      currentTenantId: property.currentTenantId,
      createdAt: property.createdAt,
      updatedAt: property.updatedAt,
    };
  }
}
