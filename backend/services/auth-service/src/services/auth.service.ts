import { Injectable, UnauthorizedException, ConflictException, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';

import { User } from '../entities/user.entity';
import { CreateUserDto, LoginDto, UserResponseDto, UserRole, UserStatus } from '@baribhara/shared-types';
import { RedisService } from '../common/redis/redis.service';
import { KafkaService } from '../common/kafka/kafka.service';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    private jwtService: JwtService,
    private redisService: RedisService,
    private kafkaService: KafkaService,
  ) {}

  async register(createUserDto: CreateUserDto): Promise<UserResponseDto> {
    const { name, phoneNumber, email, nationalId, password, role = UserRole.TENANT } = createUserDto;

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

    // Hash password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const user = this.userRepository.create({
      name,
      phoneNumber,
      email,
      nationalId,
      passwordHash,
      role,
      status: UserStatus.PENDING_VERIFICATION,
    });

    const savedUser = await this.userRepository.save(user);

    // Emit user created event
    await this.kafkaService.emit('user.created', {
      userId: savedUser.id,
      phoneNumber: savedUser.phoneNumber,
      email: savedUser.email,
    });

    return this.mapUserToResponse(savedUser);
  }

  async login(loginDto: LoginDto): Promise<{ accessToken: string; refreshToken: string; user: UserResponseDto; expiresAt: number }> {
    const { identifier, password } = loginDto;

    // Find user by email or phone
    const user = await this.userRepository.findOne({
      where: [
        { email: identifier },
        { phoneNumber: identifier },
      ],
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check password
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Check user status
    if (user.status === UserStatus.SUSPENDED) {
      throw new UnauthorizedException('Account is suspended');
    }

    // Update last login
    user.lastLoginAt = new Date();
    await this.userRepository.save(user);

    // Generate tokens
    const payload = { sub: user.id, email: user.email, role: user.role };
    const accessToken = this.jwtService.sign(payload);
    const refreshToken = this.jwtService.sign(payload, { expiresIn: '7d' });

    // Store refresh token in Redis
    await this.redisService.set(`refresh_token:${user.id}`, refreshToken, 7 * 24 * 60 * 60); // 7 days

    const expiresAt = Math.floor(Date.now() / 1000) + (24 * 60 * 60); // 24 hours

    return {
      accessToken,
      refreshToken,
      user: this.mapUserToResponse(user),
      expiresAt,
    };
  }

  async getProfile(userId: string): Promise<UserResponseDto> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return this.mapUserToResponse(user);
  }

  async refreshToken(refreshToken: string): Promise<{ accessToken: string; refreshToken: string; expiresAt: number }> {
    try {
      const payload = this.jwtService.verify(refreshToken);
      const userId = payload.sub;

      // Verify refresh token exists in Redis
      const storedToken = await this.redisService.get(`refresh_token:${userId}`);
      if (!storedToken || storedToken !== refreshToken) {
        throw new UnauthorizedException('Invalid refresh token');
      }

      // Get user
      const user = await this.userRepository.findOne({ where: { id: userId } });
      if (!user) {
        throw new UnauthorizedException('User not found');
      }

      // Generate new tokens
      const newPayload = { sub: user.id, email: user.email, role: user.role };
      const newAccessToken = this.jwtService.sign(newPayload);
      const newRefreshToken = this.jwtService.sign(newPayload, { expiresIn: '7d' });

      // Update refresh token in Redis
      await this.redisService.set(`refresh_token:${userId}`, newRefreshToken, 7 * 24 * 60 * 60);

      const expiresAt = Math.floor(Date.now() / 1000) + (24 * 60 * 60);

      return {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        expiresAt,
      };
    } catch (error) {
      throw new UnauthorizedException('Invalid refresh token');
    }
  }

  async logout(userId: string): Promise<{ message: string }> {
    // Remove refresh token from Redis
    await this.redisService.del(`refresh_token:${userId}`);
    
    // Add token to blacklist (optional)
    await this.redisService.set(`blacklist:${userId}`, 'true', 24 * 60 * 60); // 24 hours

    return { message: 'Successfully logged out' };
  }

  async verifyEmail(token: string): Promise<{ message: string }> {
    // In a real implementation, you would verify the email token
    // For now, we'll just return success
    return { message: 'Email verified successfully' };
  }

  async verifyPhone(phoneNumber: string, code: string): Promise<{ message: string }> {
    // In a real implementation, you would verify the SMS code
    // For now, we'll just return success
    return { message: 'Phone verified successfully' };
  }

  async forgotPassword(identifier: string): Promise<{ message: string }> {
    const user = await this.userRepository.findOne({
      where: [
        { email: identifier },
        { phoneNumber: identifier },
      ],
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Generate reset token
    const resetToken = uuidv4();
    await this.redisService.set(`reset_token:${resetToken}`, user.id, 60 * 60); // 1 hour

    // Emit forgot password event
    await this.kafkaService.emit('user.forgot_password', {
      userId: user.id,
      email: user.email,
      phoneNumber: user.phoneNumber,
      resetToken,
    });

    return { message: 'Password reset instructions sent' };
  }

  async resetPassword(token: string, newPassword: string): Promise<{ message: string }> {
    const userId = await this.redisService.get(`reset_token:${token}`);
    if (!userId) {
      throw new BadRequestException('Invalid or expired reset token');
    }

    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Hash new password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    user.passwordHash = passwordHash;
    await this.userRepository.save(user);

    // Remove reset token
    await this.redisService.del(`reset_token:${token}`);

    return { message: 'Password reset successfully' };
  }

  async validateUser(identifier: string, password: string): Promise<any> {
    const user = await this.userRepository.findOne({
      where: [
        { email: identifier },
        { phoneNumber: identifier },
      ],
    });

    if (user && await bcrypt.compare(password, user.passwordHash)) {
      const { passwordHash, ...result } = user;
      return result;
    }
    return null;
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
