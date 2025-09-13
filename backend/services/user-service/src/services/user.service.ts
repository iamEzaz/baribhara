import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';
import { CreateUserDto, UpdateUserDto, UserResponseDto, PaginationDto, UserRole, UserStatus } from '@baribhara/shared-types';
import { RedisService } from '../common/redis/redis.service';
import { KafkaService } from '../common/kafka/kafka.service';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private redisService: RedisService,
    private kafkaService: KafkaService,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<UserResponseDto> {
    const { name, phoneNumber, email, nationalId, role = UserRole.TENANT } = createUserDto;

    // Check if user already exists
    const existingUser = await this.userRepository.findOne({
      where: [
        { phoneNumber },
        ...(email ? [{ email }] : []),
        ...(nationalId ? [{ nationalId }] : []),
      ],
    });

    if (existingUser) {
      throw new ConflictException('User with this phone number, email, or national ID already exists');
    }

    // Create user
    const user = this.userRepository.create({
      name,
      phoneNumber,
      email,
      nationalId,
      role,
      status: UserStatus.ACTIVE,
    });

    const savedUser = await this.userRepository.save(user);

    // Cache user data
    await this.redisService.set(`user:${savedUser.id}`, JSON.stringify(this.mapUserToResponse(savedUser)), 3600);

    // Emit user created event
    await this.kafkaService.emit('user.created', {
      userId: savedUser.id,
      phoneNumber: savedUser.phoneNumber,
      email: savedUser.email,
    });

    return this.mapUserToResponse(savedUser);
  }

  async findAll(paginationDto: PaginationDto): Promise<{ users: UserResponseDto[]; total: number; page: number; limit: number }> {
    const { page = 1, limit = 10, search, sortBy = 'createdAt', sortOrder = 'DESC' } = paginationDto;
    const skip = (page - 1) * limit;

    const queryBuilder = this.userRepository.createQueryBuilder('user');

    if (search) {
      queryBuilder.where(
        'user.name ILIKE :search OR user.phoneNumber ILIKE :search OR user.email ILIKE :search',
        { search: `%${search}%` }
      );
    }

    const [users, total] = await queryBuilder
      .orderBy(`user.${sortBy}`, sortOrder as 'ASC' | 'DESC')
      .skip(skip)
      .take(limit)
      .getManyAndCount();

    return {
      users: users.map(user => this.mapUserToResponse(user)),
      total,
      page,
      limit,
    };
  }

  async findOne(id: string): Promise<UserResponseDto> {
    // Try cache first
    const cachedUser = await this.redisService.get(`user:${id}`);
    if (cachedUser) {
      return JSON.parse(cachedUser);
    }

    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const userResponse = this.mapUserToResponse(user);
    
    // Cache user data
    await this.redisService.set(`user:${id}`, JSON.stringify(userResponse), 3600);

    return userResponse;
  }

  async findByPhoneNumber(phoneNumber: string): Promise<UserResponseDto> {
    const user = await this.userRepository.findOne({ where: { phoneNumber } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return this.mapUserToResponse(user);
  }

  async findByEmail(email: string): Promise<UserResponseDto> {
    const user = await this.userRepository.findOne({ where: { email } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return this.mapUserToResponse(user);
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<UserResponseDto> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    Object.assign(user, updateUserDto);
    const updatedUser = await this.userRepository.save(user);

    // Update cache
    await this.redisService.set(`user:${id}`, JSON.stringify(this.mapUserToResponse(updatedUser)), 3600);

    // Emit user updated event
    await this.kafkaService.emit('user.updated', {
      userId: updatedUser.id,
      changes: updateUserDto,
    });

    return this.mapUserToResponse(updatedUser);
  }

  async remove(id: string): Promise<void> {
    const result = await this.userRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException('User not found');
    }

    // Remove from cache
    await this.redisService.del(`user:${id}`);

    // Emit user deleted event
    await this.kafkaService.emit('user.deleted', {
      userId: id,
    });
  }

  private mapUserToResponse(user: User): UserResponseDto {
    return {
      id: user.id,
      name: user.name,
      phoneNumber: user.phoneNumber,
      email: user.email,
      nationalId: user.nationalId,
      role: user.role,
      status: user.status,
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
      isEmailVerified: user.isEmailVerified,
      isPhoneVerified: user.isPhoneVerified,
    };
  }
}
