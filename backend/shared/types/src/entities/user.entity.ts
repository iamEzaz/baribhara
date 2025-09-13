import { IsEmail, IsOptional, IsPhoneNumber, IsString, MinLength } from 'class-validator';
import { Exclude, Expose } from 'class-transformer';

export enum UserRole {
  SUPER_ADMIN = 'super_admin',
  CARETAKER = 'caretaker',
  TENANT = 'tenant',
}

export enum UserStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  SUSPENDED = 'suspended',
  PENDING_VERIFICATION = 'pending_verification',
}

export class User {
  @Expose()
  id: string;

  @Expose()
  @IsString()
  name: string;

  @Expose()
  @IsPhoneNumber('BD')
  phoneNumber: string;

  @Expose()
  @IsOptional()
  @IsEmail()
  email?: string;

  @Expose()
  @IsOptional()
  @IsString()
  nationalId?: string;

  @Exclude()
  @IsString()
  @MinLength(6)
  password: string;

  @Expose()
  role: UserRole;

  @Expose()
  status: UserStatus;

  @Expose()
  createdAt: Date;

  @Expose()
  updatedAt: Date;

  @Expose()
  lastLoginAt?: Date;

  @Expose()
  isEmailVerified: boolean;

  @Expose()
  isPhoneVerified: boolean;
}

export class CreateUserDto {
  @IsString()
  name: string;

  @IsPhoneNumber('BD')
  phoneNumber: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  nationalId?: string;

  @IsString()
  @MinLength(6)
  password: string;
}

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsPhoneNumber('BD')
  phoneNumber?: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  nationalId?: string;
}

export class LoginDto {
  @IsString()
  identifier: string; // email or phone

  @IsString()
  password: string;
}

export class UserResponseDto {
  @Expose()
  id: string;

  @Expose()
  name: string;

  @Expose()
  phoneNumber: string;

  @Expose()
  email?: string;

  @Expose()
  nationalId?: string;

  @Expose()
  role: UserRole;

  @Expose()
  status: UserStatus;

  @Expose()
  createdAt: Date;

  @Expose()
  lastLoginAt?: Date;

  @Expose()
  isEmailVerified: boolean;

  @Expose()
  isPhoneVerified: boolean;
}
