import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../entities/user.entity';
import { UserResponseDto, UpdateUserDto } from '@baribhara/shared-types';

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}

  async findById(id: string): Promise<UserResponseDto> {
    const user = await this.userRepository.findOne({ where: { id } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return this.mapUserToResponse(user);
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
    return this.mapUserToResponse(updatedUser);
  }

  async delete(id: string): Promise<void> {
    const result = await this.userRepository.delete(id);
    if (result.affected === 0) {
      throw new NotFoundException('User not found');
    }
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
