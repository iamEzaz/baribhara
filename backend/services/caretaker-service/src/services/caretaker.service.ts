import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Caretaker, CaretakerStatus, CaretakerType } from '../entities/caretaker.entity';
import { CreateCaretakerDto, UpdateCaretakerDto, CaretakerResponseDto, PaginationDto } from '@baribhara/shared-types';
import { RedisService } from '../common/redis/redis.service';
import { KafkaService } from '../common/kafka/kafka.service';

@Injectable()
export class CaretakerService {
  constructor(
    @InjectRepository(Caretaker)
    private caretakerRepository: Repository<Caretaker>,
    private redisService: RedisService,
    private kafkaService: KafkaService,
  ) {}

  async create(createCaretakerDto: CreateCaretakerDto): Promise<CaretakerResponseDto> {
    // Check if caretaker already exists for this user
    const existingCaretaker = await this.caretakerRepository.findOne({
      where: { userId: createCaretakerDto.userId }
    });

    if (existingCaretaker) {
      throw new ConflictException('Caretaker profile already exists for this user');
    }

    const caretaker = this.caretakerRepository.create({
      ...createCaretakerDto,
      status: CaretakerStatus.ACTIVE,
    });

    const savedCaretaker = await this.caretakerRepository.save(caretaker);

    // Cache caretaker data
    await this.redisService.set(`caretaker:${savedCaretaker.id}`, JSON.stringify(this.mapCaretakerToResponse(savedCaretaker)), 3600);

    // Emit caretaker created event
    await this.kafkaService.emit('caretaker.created', {
      caretakerId: savedCaretaker.id,
      userId: savedCaretaker.userId,
      type: savedCaretaker.type,
    });

    return this.mapCaretakerToResponse(savedCaretaker);
  }

  async findAll(paginationDto: PaginationDto): Promise<{ caretakers: CaretakerResponseDto[]; total: number; page: number; limit: number }> {
    const { page = 1, limit = 10, search, sortBy = 'createdAt', sortOrder = 'DESC' } = paginationDto;
    const skip = (page - 1) * limit;

    const queryBuilder = this.caretakerRepository.createQueryBuilder('caretaker');

    if (search) {
      queryBuilder.where(
        'caretaker.name ILIKE :search OR caretaker.companyName ILIKE :search OR caretaker.city ILIKE :search',
        { search: `%${search}%` }
      );
    }

    const [caretakers, total] = await queryBuilder
      .orderBy(`caretaker.${sortBy}`, sortOrder as 'ASC' | 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      caretakers: caretakers.map(caretaker => this.mapCaretakerToResponse(caretaker)),
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
    specialties?: string[];
    minRating?: number;
    page: number;
    limit: number;
  }): Promise<{ caretakers: CaretakerResponseDto[]; total: number; page: number; limit: number }> {
    const { query, city, district, type, specialties, minRating, page, limit } = searchParams;
    const skip = (page - 1) * limit;

    const queryBuilder = this.caretakerRepository.createQueryBuilder('caretaker')
      .where('caretaker.status = :status', { status: CaretakerStatus.ACTIVE });

    if (query) {
      queryBuilder.andWhere(
        'caretaker.name ILIKE :query OR caretaker.companyName ILIKE :query OR caretaker.city ILIKE :query',
        { query: `%${query}%` }
      );
    }

    if (city) {
      queryBuilder.andWhere('caretaker.city = :city', { city });
    }

    if (district) {
      queryBuilder.andWhere('caretaker.district = :district', { district });
    }

    if (type) {
      queryBuilder.andWhere('caretaker.type = :type', { type });
    }

    if (specialties && specialties.length > 0) {
      queryBuilder.andWhere('caretaker.specialties && :specialties', { specialties });
    }

    if (minRating !== undefined) {
      queryBuilder.andWhere('caretaker.rating >= :minRating', { minRating });
    }

    const [caretakers, total] = await queryBuilder
      .orderBy('caretaker.rating', 'DESC')
      .addOrderBy('caretaker.createdAt', 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      caretakers: caretakers.map(caretaker => this.mapCaretakerToResponse(caretaker)),
      total,
      page,
      limit,
    };
  }

  async findByUserId(userId: string): Promise<CaretakerResponseDto> {
    const caretaker = await this.caretakerRepository.findOne({ where: { userId } });
    if (!caretaker) {
      throw new NotFoundException('Caretaker not found for this user');
    }

    return this.mapCaretakerToResponse(caretaker);
  }

  async findVerified(paginationDto: PaginationDto): Promise<{ caretakers: CaretakerResponseDto[]; total: number; page: number; limit: number }> {
    const { page = 1, limit = 10, search, sortBy = 'createdAt', sortOrder = 'DESC' } = paginationDto;
    const skip = (page - 1) * limit;

    const queryBuilder = this.caretakerRepository.createQueryBuilder('caretaker')
      .where('caretaker.isVerified = :isVerified', { isVerified: true })
      .andWhere('caretaker.status = :status', { status: CaretakerStatus.ACTIVE });

    if (search) {
      queryBuilder.andWhere(
        'caretaker.name ILIKE :search OR caretaker.companyName ILIKE :search OR caretaker.city ILIKE :search',
        { search: `%${search}%` }
      );
    }

    const [caretakers, total] = await queryBuilder
      .orderBy(`caretaker.${sortBy}`, sortOrder as 'ASC' | 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      caretakers: caretakers.map(caretaker => this.mapCaretakerToResponse(caretaker)),
      total,
      page,
      limit,
    };
  }

  async findTopRated(limit: number = 10): Promise<CaretakerResponseDto[]> {
    const caretakers = await this.caretakerRepository.find({
      where: { 
        status: CaretakerStatus.ACTIVE,
        isVerified: true,
      },
      order: { rating: 'DESC' },
      take: limit,
    });

    return caretakers.map(caretaker => this.mapCaretakerToResponse(caretaker));
  }

  async findOne(id: string): Promise<CaretakerResponseDto> {
    // Try cache first
    const cachedCaretaker = await this.redisService.get(`caretaker:${id}`);
    if (cachedCaretaker) {
      return JSON.parse(cachedCaretaker);
    }

    const caretaker = await this.caretakerRepository.findOne({ where: { id } });
    if (!caretaker) {
      throw new NotFoundException('Caretaker not found');
    }

    const caretakerResponse = this.mapCaretakerToResponse(caretaker);
    
    // Cache caretaker data
    await this.redisService.set(`caretaker:${id}`, JSON.stringify(caretakerResponse), 3600);

    return caretakerResponse;
  }

  async update(id: string, updateCaretakerDto: UpdateCaretakerDto): Promise<CaretakerResponseDto> {
    const caretaker = await this.caretakerRepository.findOne({ where: { id } });
    if (!caretaker) {
      throw new NotFoundException('Caretaker not found');
    }

    Object.assign(caretaker, updateCaretakerDto);
    const updatedCaretaker = await this.caretakerRepository.save(caretaker);

    // Update cache
    await this.redisService.set(`caretaker:${id}`, JSON.stringify(this.mapCaretakerToResponse(updatedCaretaker)), 3600);

    // Emit caretaker updated event
    await this.kafkaService.emit('caretaker.updated', {
      caretakerId: updatedCaretaker.id,
      userId: updatedCaretaker.userId,
      changes: updateCaretakerDto,
    });

    return this.mapCaretakerToResponse(updatedCaretaker);
  }

  async verify(id: string): Promise<void> {
    const caretaker = await this.caretakerRepository.findOne({ where: { id } });
    if (!caretaker) {
      throw new NotFoundException('Caretaker not found');
    }

    caretaker.isVerified = true;
    caretaker.verifiedAt = new Date();
    await this.caretakerRepository.save(caretaker);

    // Update cache
    await this.redisService.set(`caretaker:${id}`, JSON.stringify(this.mapCaretakerToResponse(caretaker)), 3600);

    // Emit verification event
    await this.kafkaService.emit('caretaker.verified', {
      caretakerId: id,
      userId: caretaker.userId,
    });
  }

  async suspend(id: string): Promise<void> {
    const caretaker = await this.caretakerRepository.findOne({ where: { id } });
    if (!caretaker) {
      throw new NotFoundException('Caretaker not found');
    }

    caretaker.status = CaretakerStatus.SUSPENDED;
    await this.caretakerRepository.save(caretaker);

    // Update cache
    await this.redisService.set(`caretaker:${id}`, JSON.stringify(this.mapCaretakerToResponse(caretaker)), 3600);

    // Emit suspension event
    await this.kafkaService.emit('caretaker.suspended', {
      caretakerId: id,
      userId: caretaker.userId,
    });
  }

  async activate(id: string): Promise<void> {
    const caretaker = await this.caretakerRepository.findOne({ where: { id } });
    if (!caretaker) {
      throw new NotFoundException('Caretaker not found');
    }

    caretaker.status = CaretakerStatus.ACTIVE;
    await this.caretakerRepository.save(caretaker);

    // Update cache
    await this.redisService.set(`caretaker:${id}`, JSON.stringify(this.mapCaretakerToResponse(caretaker)), 3600);

    // Emit activation event
    await this.kafkaService.emit('caretaker.activated', {
      caretakerId: id,
      userId: caretaker.userId,
    });
  }

  async remove(id: string): Promise<void> {
    const result = await this.caretakerRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException('Caretaker not found');
    }

    // Remove from cache
    await this.redisService.del(`caretaker:${id}`);

    // Emit deletion event
    await this.kafkaService.emit('caretaker.deleted', {
      caretakerId: id,
    });
  }

  private mapCaretakerToResponse(caretaker: Caretaker): CaretakerResponseDto {
    return {
      id: caretaker.id,
      name: caretaker.name,
      phoneNumber: caretaker.phoneNumber,
      email: caretaker.email,
      nationalId: caretaker.nationalId,
      type: caretaker.type,
      status: caretaker.status,
      companyName: caretaker.companyName,
      licenseNumber: caretaker.licenseNumber,
      description: caretaker.description,
      address: {
        street: caretaker.street,
        city: caretaker.city,
        district: caretaker.district,
        division: caretaker.division,
        postalCode: caretaker.postalCode,
      },
      specialties: caretaker.specialties,
      languages: caretaker.languages,
      rating: caretaker.rating,
      totalProperties: caretaker.totalProperties,
      activeProperties: caretaker.activeProperties,
      totalTenants: caretaker.totalTenants,
      isVerified: caretaker.isVerified,
      verifiedAt: caretaker.verifiedAt,
      documents: caretaker.documents,
      userId: caretaker.userId,
      createdAt: caretaker.createdAt,
      updatedAt: caretaker.updatedAt,
    };
  }
}
