import { IsString, IsUUID, IsDateString, IsNumber, IsOptional, IsEnum } from 'class-validator';
import { Expose } from 'class-transformer';

export enum RelationshipStatus {
  ACTIVE = 'active',
  TERMINATED = 'terminated',
  SUSPENDED = 'suspended',
}

export enum RelationshipType {
  TENANT = 'tenant',
  SUB_TENANT = 'sub_tenant',
}

export class TenantPropertyRelationship {
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
  @IsEnum(RelationshipStatus)
  status: RelationshipStatus;

  @Expose()
  @IsEnum(RelationshipType)
  relationshipType: RelationshipType;

  @Expose()
  @IsDateString()
  contractStartDate: string;

  @Expose()
  @IsOptional()
  @IsDateString()
  contractEndDate?: string;

  @Expose()
  @IsNumber()
  monthlyRent: number;

  @Expose()
  @IsNumber()
  securityDeposit: number;

  @Expose()
  @IsOptional()
  @IsString()
  leaseTerms?: string;

  @Expose()
  @IsDateString()
  joinedAt: string;

  @Expose()
  @IsOptional()
  @IsDateString()
  leftAt?: string;

  @Expose()
  @IsOptional()
  @IsString()
  terminationReason?: string;

  @Expose()
  @IsDateString()
  createdAt: string;

  @Expose()
  @IsDateString()
  updatedAt: string;
}

export class CreateTenantPropertyRelationshipDto {
  @IsUUID()
  tenantId: string;

  @IsUUID()
  propertyId: string;

  @IsUUID()
  caretakerId: string;

  @IsEnum(RelationshipType)
  relationshipType: RelationshipType;

  @IsDateString()
  contractStartDate: string;

  @IsOptional()
  @IsDateString()
  contractEndDate?: string;

  @IsNumber()
  monthlyRent: number;

  @IsNumber()
  securityDeposit: number;

  @IsOptional()
  @IsString()
  leaseTerms?: string;
}

export class UpdateTenantPropertyRelationshipDto {
  @IsOptional()
  @IsEnum(RelationshipStatus)
  status?: RelationshipStatus;

  @IsOptional()
  @IsDateString()
  contractEndDate?: string;

  @IsOptional()
  @IsNumber()
  monthlyRent?: number;

  @IsOptional()
  @IsNumber()
  securityDeposit?: number;

  @IsOptional()
  @IsString()
  leaseTerms?: string;

  @IsOptional()
  @IsString()
  terminationReason?: string;
}
