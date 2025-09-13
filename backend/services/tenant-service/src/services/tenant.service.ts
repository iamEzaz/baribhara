import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tenant, TenantStatus, TenantType } from '../entities/tenant.entity';
import { CreateTenantDto, UpdateTenantDto, TenantResponseDto, PaginationDto } from '@baribhara/shared-types';
import { RedisService } from '../common/redis/redis.service';
import { KafkaService } from '../common/kafka/kafka.service';

@Injectable()
export class TenantService {
  constructor(
    @InjectRepository(Tenant)
    private tenantRepository: Repository<Tenant>,
    private redisService: RedisService,
    private kafkaService: KafkaService,
  ) {}

  async create(createTenantDto: CreateTenantDto): Promise<TenantResponseDto> {
    // Check if tenant already exists for this user
    const existingTenant = await this.tenantRepository.findOne({
      where: { userId: createTenantDto.userId }
    });

    if (existingTenant) {
      throw new ConflictException('Tenant profile already exists for this user');
    }

    const tenant = this.tenantRepository.create({
      ...createTenantDto,
      status: TenantStatus.ACTIVE,
    });

    const savedTenant = await this.tenantRepository.save(tenant);

    // Cache tenant data
    await this.redisService.set(`tenant:${savedTenant.id}`, JSON.stringify(this.mapTenantToResponse(savedTenant)), 3600);

    // Emit tenant created event
    await this.kafkaService.emit('tenant.created', {
      tenantId: savedTenant.id,
      userId: savedTenant.userId,
      type: savedTenant.type,
    });

    return this.mapTenantToResponse(savedTenant);
  }

  async findAll(paginationDto: PaginationDto): Promise<{ tenants: TenantResponseDto[]; total: number; page: number; limit: number }> {
    const { page = 1, limit = 10, search, sortBy = 'createdAt', sortOrder = 'DESC' } = paginationDto;
    const skip = (page - 1) * limit;

    const queryBuilder = this.tenantRepository.createQueryBuilder('tenant');

    if (search) {
      queryBuilder.where(
        'tenant.name ILIKE :search OR tenant.phoneNumber ILIKE :search OR tenant.email ILIKE :search',
        { search: `%${search}%` }
      );
    }

    const [tenants, total] = await queryBuilder
      .orderBy(`tenant.${sortBy}`, sortOrder as 'ASC' | 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      tenants: tenants.map(tenant => this.mapTenantToResponse(tenant)),
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
    status?: string;
    page: number;
    limit: number;
  }): Promise<{ tenants: TenantResponseDto[]; total: number; page: number; limit: number }> {
    const { query, city, district, type, status, page, limit } = searchParams;
    const skip = (page - 1) * limit;

    const queryBuilder = this.tenantRepository.createQueryBuilder('tenant');

    if (query) {
      queryBuilder.andWhere(
        'tenant.name ILIKE :query OR tenant.phoneNumber ILIKE :query OR tenant.email ILIKE :query',
        { query: `%${query}%` }
      );
    }

    if (city) {
      queryBuilder.andWhere('tenant.city = :city', { city });
    }

    if (district) {
      queryBuilder.andWhere('tenant.district = :district', { district });
    }

    if (type) {
      queryBuilder.andWhere('tenant.type = :type', { type });
    }

    if (status) {
      queryBuilder.andWhere('tenant.status = :status', { status });
    }

    const [tenants, total] = await queryBuilder
      .orderBy('tenant.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      tenants: tenants.map(tenant => this.mapTenantToResponse(tenant)),
      total,
      page,
      limit,
    };
  }

  async findByUserId(userId: string): Promise<TenantResponseDto> {
    const tenant = await this.tenantRepository.findOne({ where: { userId } });
    if (!tenant) {
      throw new NotFoundException('Tenant not found for this user');
    }

    return this.mapTenantToResponse(tenant);
  }

  async findByProperty(propertyId: string, paginationDto: PaginationDto): Promise<{ tenants: TenantResponseDto[]; total: number; page: number; limit: number }> {
    const { page = 1, limit = 10, search, sortBy = 'createdAt', sortOrder = 'DESC' } = paginationDto;
    const skip = (page - 1) * limit;

    const queryBuilder = this.tenantRepository.createQueryBuilder('tenant')
      .where('tenant.currentPropertyId = :propertyId', { propertyId });

    if (search) {
      queryBuilder.andWhere(
        'tenant.name ILIKE :search OR tenant.phoneNumber ILIKE :search OR tenant.email ILIKE :search',
        { search: `%${search}%` }
      );
    }

    const [tenants, total] = await queryBuilder
      .orderBy(`tenant.${sortBy}`, sortOrder as 'ASC' | 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      tenants: tenants.map(tenant => this.mapTenantToResponse(tenant)),
      total,
      page,
      limit,
    };
  }

  async findByCaretaker(caretakerId: string, paginationDto: PaginationDto): Promise<{ tenants: TenantResponseDto[]; total: number; page: number; limit: number }> {
    const { page = 1, limit = 10, search, sortBy = 'createdAt', sortOrder = 'DESC' } = paginationDto;
    const skip = (page - 1) * limit;

    const queryBuilder = this.tenantRepository.createQueryBuilder('tenant')
      .where('tenant.caretakerId = :caretakerId', { caretakerId });

    if (search) {
      queryBuilder.andWhere(
        'tenant.name ILIKE :search OR tenant.phoneNumber ILIKE :search OR tenant.email ILIKE :search',
        { search: `%${search}%` }
      );
    }

    const [tenants, total] = await queryBuilder
      .orderBy(`tenant.${sortBy}`, sortOrder as 'ASC' | 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      tenants: tenants.map(tenant => this.mapTenantToResponse(tenant)),
      total,
      page,
      limit,
    };
  }

  async findVerified(paginationDto: PaginationDto): Promise<{ tenants: TenantResponseDto[]; total: number; page: number; limit: number }> {
    const { page = 1, limit = 10, search, sortBy = 'createdAt', sortOrder = 'DESC' } = paginationDto;
    const skip = (page - 1) * limit;

    const queryBuilder = this.tenantRepository.createQueryBuilder('tenant')
      .where('tenant.isVerified = :isVerified', { isVerified: true })
      .andWhere('tenant.status = :status', { status: TenantStatus.ACTIVE });

    if (search) {
      queryBuilder.andWhere(
        'tenant.name ILIKE :search OR tenant.phoneNumber ILIKE :search OR tenant.email ILIKE :search',
        { search: `%${search}%` }
      );
    }

    const [tenants, total] = await queryBuilder
      .orderBy(`tenant.${sortBy}`, sortOrder as 'ASC' | 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      tenants: tenants.map(tenant => this.mapTenantToResponse(tenant)),
      total,
      page,
      limit,
    };
  }

  async findOne(id: string): Promise<TenantResponseDto> {
    // Try cache first
    const cachedTenant = await this.redisService.get(`tenant:${id}`);
    if (cachedTenant) {
      return JSON.parse(cachedTenant);
    }

    const tenant = await this.tenantRepository.findOne({ where: { id } });
    if (!tenant) {
      throw new NotFoundException('Tenant not found');
    }

    const tenantResponse = this.mapTenantToResponse(tenant);
    
    // Cache tenant data
    await this.redisService.set(`tenant:${id}`, JSON.stringify(tenantResponse), 3600);

    return tenantResponse;
  }

  async update(id: string, updateTenantDto: UpdateTenantDto): Promise<TenantResponseDto> {
    const tenant = await this.tenantRepository.findOne({ where: { id } });
    if (!tenant) {
      throw new NotFoundException('Tenant not found');
    }

    Object.assign(tenant, updateTenantDto);
    const updatedTenant = await this.tenantRepository.save(tenant);

    // Update cache
    await this.redisService.set(`tenant:${id}`, JSON.stringify(this.mapTenantToResponse(updatedTenant)), 3600);

    // Emit tenant updated event
    await this.kafkaService.emit('tenant.updated', {
      tenantId: updatedTenant.id,
      userId: updatedTenant.userId,
      changes: updateTenantDto,
    });

    return this.mapTenantToResponse(updatedTenant);
  }

  async verify(id: string): Promise<void> {
    const tenant = await this.tenantRepository.findOne({ where: { id } });
    if (!tenant) {
      throw new NotFoundException('Tenant not found');
    }

    tenant.isVerified = true;
    tenant.verifiedAt = new Date();
    await this.tenantRepository.save(tenant);

    // Update cache
    await this.redisService.set(`tenant:${id}`, JSON.stringify(this.mapTenantToResponse(tenant)), 3600);

    // Emit verification event
    await this.kafkaService.emit('tenant.verified', {
      tenantId: id,
      userId: tenant.userId,
    });
  }

  async assignProperty(id: string, assignPropertyDto: {
    propertyId: string;
    caretakerId: string;
    leaseStartDate: Date;
    leaseEndDate: Date;
    monthlyRent: number;
    securityDeposit: number;
    leaseTerms?: string;
  }): Promise<void> {
    const tenant = await this.tenantRepository.findOne({ where: { id } });
    if (!tenant) {
      throw new NotFoundException('Tenant not found');
    }

    tenant.currentPropertyId = assignPropertyDto.propertyId;
    tenant.caretakerId = assignPropertyDto.caretakerId;
    tenant.leaseStartDate = assignPropertyDto.leaseStartDate;
    tenant.leaseEndDate = assignPropertyDto.leaseEndDate;
    tenant.monthlyRent = assignPropertyDto.monthlyRent;
    tenant.securityDeposit = assignPropertyDto.securityDeposit;
    tenant.leaseTerms = assignPropertyDto.leaseTerms;
    tenant.activeLeases = 1;

    await this.tenantRepository.save(tenant);

    // Update cache
    await this.redisService.set(`tenant:${id}`, JSON.stringify(this.mapTenantToResponse(tenant)), 3600);

    // Emit property assignment event
    await this.kafkaService.emit('tenant.property_assigned', {
      tenantId: id,
      propertyId: assignPropertyDto.propertyId,
      caretakerId: assignPropertyDto.caretakerId,
    });
  }

  async removeProperty(id: string): Promise<void> {
    const tenant = await this.tenantRepository.findOne({ where: { id } });
    if (!tenant) {
      throw new NotFoundException('Tenant not found');
    }

    tenant.currentPropertyId = null;
    tenant.caretakerId = null;
    tenant.leaseStartDate = null;
    tenant.leaseEndDate = null;
    tenant.monthlyRent = null;
    tenant.securityDeposit = null;
    tenant.leaseTerms = null;
    tenant.activeLeases = 0;

    await this.tenantRepository.save(tenant);

    // Update cache
    await this.redisService.set(`tenant:${id}`, JSON.stringify(this.mapTenantToResponse(tenant)), 3600);

    // Emit property removal event
    await this.kafkaService.emit('tenant.property_removed', {
      tenantId: id,
    });
  }

  async remove(id: string): Promise<void> {
    const result = await this.tenantRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException('Tenant not found');
    }

    // Remove from cache
    await this.redisService.del(`tenant:${id}`);

    // Emit deletion event
    await this.kafkaService.emit('tenant.deleted', {
      tenantId: id,
    });
  }

  private mapTenantToResponse(tenant: Tenant): TenantResponseDto {
    return {
      id: tenant.id,
      name: tenant.name,
      phoneNumber: tenant.phoneNumber,
      email: tenant.email,
      nationalId: tenant.nationalId,
      type: tenant.type,
      status: tenant.status,
      emergencyContact: {
        name: tenant.emergencyContactName,
        phone: tenant.emergencyContactPhone,
        relation: tenant.emergencyContactRelation,
      },
      address: {
        street: tenant.street,
        city: tenant.city,
        district: tenant.district,
        division: tenant.division,
        postalCode: tenant.postalCode,
      },
      employment: {
        occupation: tenant.occupation,
        employer: tenant.employer,
        monthlyIncome: tenant.monthlyIncome,
      },
      preferences: tenant.preferences,
      documents: tenant.documents,
      userId: tenant.userId,
      currentPropertyId: tenant.currentPropertyId,
      caretakerId: tenant.caretakerId,
      lease: {
        startDate: tenant.leaseStartDate,
        endDate: tenant.leaseEndDate,
        monthlyRent: tenant.monthlyRent,
        securityDeposit: tenant.securityDeposit,
        terms: tenant.leaseTerms,
      },
      payment: {
        preferredMethod: tenant.preferredPaymentMethod,
        bankAccount: tenant.bankAccountNumber,
        bankName: tenant.bankName,
        bkashNumber: tenant.bkashNumber,
        nagadNumber: tenant.nagadNumber,
      },
      isVerified: tenant.isVerified,
      verifiedAt: tenant.verifiedAt,
      totalProperties: tenant.totalProperties,
      activeLeases: tenant.activeLeases,
      createdAt: tenant.createdAt,
      updatedAt: tenant.updatedAt,
    };
  }
}
