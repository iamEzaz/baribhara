import { IsString, IsUUID, IsNumber, IsOptional, IsEnum, IsDateString } from 'class-validator';
import { Expose } from 'class-transformer';

export enum RequestStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  EXPIRED = 'expired',
}

export enum RequestType {
  JOIN = 'join',
  LEAVE = 'leave',
  TRANSFER = 'transfer',
}

export class TenantRequest {
  @Expose()
  @IsUUID()
  id: string;

  @Expose()
  @IsUUID()
  tenantId: string;

  @Expose()
  @IsUUID()
  propertyId: string;

  @Expose()
  @IsUUID()
  caretakerId: string;

  @Expose()
  @IsEnum(RequestStatus)
  status: RequestStatus;

  @Expose()
  @IsEnum(RequestType)
  requestType: RequestType;

  @Expose()
  @IsOptional()
  @IsString()
  message?: string;

  @Expose()
  @IsOptional()
  @IsNumber()
  requestedRent?: number;

  @Expose()
  @IsOptional()
  @IsNumber()
  requestedDeposit?: number;

  @Expose()
  @IsDateString()
  requestedAt: string;

  @Expose()
  @IsOptional()
  @IsDateString()
  respondedAt?: string;

  @Expose()
  @IsOptional()
  @IsDateString()
  expiresAt?: string;

  @Expose()
  @IsOptional()
  @IsString()
  responseMessage?: string;

  @Expose()
  @IsOptional()
  @IsNumber()
  approvedRent?: number;

  @Expose()
  @IsOptional()
  @IsNumber()
  approvedDeposit?: number;

  @Expose()
  @IsDateString()
  createdAt: string;

  @Expose()
  @IsDateString()
  updatedAt: string;
}

export class CreateTenantRequestDto {
  @IsUUID()
  tenantId: string;

  @IsUUID()
  propertyId: string;

  @IsEnum(RequestType)
  requestType: RequestType;

  @IsOptional()
  @IsString()
  message?: string;

  @IsOptional()
  @IsNumber()
  requestedRent?: number;

  @IsOptional()
  @IsNumber()
  requestedDeposit?: number;
}

export class UpdateTenantRequestDto {
  @IsOptional()
  @IsEnum(RequestStatus)
  status?: RequestStatus;

  @IsOptional()
  @IsString()
  responseMessage?: string;

  @IsOptional()
  @IsNumber()
  approvedRent?: number;

  @IsOptional()
  @IsNumber()
  approvedDeposit?: number;
}
