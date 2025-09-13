import { IsString, IsOptional, IsEnum, IsDateString } from 'class-validator';

export enum TenantStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  PENDING_APPROVAL = 'pending_approval',
  REJECTED = 'rejected',
  TERMINATED = 'terminated',
}

export enum TenantRequestStatus {
  PENDING = 'pending',
  APPROVED = 'approved',
  REJECTED = 'rejected',
  CANCELLED = 'cancelled',
}

export class Tenant {
  id: string;
  userId: string;
  propertyId: string;
  caretakerId: string;
  status: TenantStatus;
  joinedAt: Date;
  leftAt?: Date;
  contractStartDate: Date;
  contractEndDate?: Date;
  monthlyRent: number;
  securityDeposit: number;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

export class TenantRequest {
  id: string;
  tenantId: string;
  propertyId: string;
  caretakerId: string;
  status: TenantRequestStatus;
  message?: string;
  requestedAt: Date;
  respondedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

export class CreateTenantDto {
  @IsString()
  propertyId: string;

  @IsString()
  phoneNumber: string;

  @IsOptional()
  @IsString()
  message?: string;
}

export class UpdateTenantDto {
  @IsOptional()
  @IsEnum(TenantStatus)
  status?: TenantStatus;

  @IsOptional()
  @IsDateString()
  contractStartDate?: string;

  @IsOptional()
  @IsDateString()
  contractEndDate?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class TenantRequestResponseDto {
  @IsString()
  requestId: string;

  @IsEnum(TenantRequestStatus)
  status: TenantRequestStatus;

  @IsOptional()
  @IsString()
  message?: string;
}
