import { IsString, IsOptional, IsNumber, IsEnum, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export enum PropertyType {
  APARTMENT = 'apartment',
  HOUSE = 'house',
  COMMERCIAL = 'commercial',
  LAND = 'land',
}

export enum PropertyStatus {
  AVAILABLE = 'available',
  OCCUPIED = 'occupied',
  MAINTENANCE = 'maintenance',
  RENTED = 'rented',
}

export class PropertyAddress {
  @IsString()
  street: string;

  @IsString()
  city: string;

  @IsString()
  district: string;

  @IsString()
  division: string;

  @IsString()
  postalCode: string;

  @IsOptional()
  @IsString()
  landmark?: string;
}

export class Property {
  id: string;
  name: string;
  description?: string;
  type: PropertyType;
  status: PropertyStatus;
  address: PropertyAddress;
  rentAmount: number;
  securityDeposit: number;
  area: number; // in sq ft
  bedrooms?: number;
  bathrooms?: number;
  floor?: number;
  totalFloors?: number;
  amenities: string[];
  images: string[];
  caretakerId: string;
  currentTenantId?: string;
  createdAt: Date;
  updatedAt: Date;
}

export class CreatePropertyDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsEnum(PropertyType)
  type: PropertyType;

  @ValidateNested()
  @Type(() => PropertyAddress)
  address: PropertyAddress;

  @IsNumber()
  rentAmount: number;

  @IsNumber()
  securityDeposit: number;

  @IsNumber()
  area: number;

  @IsOptional()
  @IsNumber()
  bedrooms?: number;

  @IsOptional()
  @IsNumber()
  bathrooms?: number;

  @IsOptional()
  @IsNumber()
  floor?: number;

  @IsOptional()
  @IsNumber()
  totalFloors?: number;

  @IsArray()
  @IsString({ each: true })
  amenities: string[];

  @IsArray()
  @IsString({ each: true })
  images: string[];
}

export class UpdatePropertyDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsEnum(PropertyType)
  type?: PropertyType;

  @IsOptional()
  @ValidateNested()
  @Type(() => PropertyAddress)
  address?: PropertyAddress;

  @IsOptional()
  @IsNumber()
  rentAmount?: number;

  @IsOptional()
  @IsNumber()
  securityDeposit?: number;

  @IsOptional()
  @IsNumber()
  area?: number;

  @IsOptional()
  @IsNumber()
  bedrooms?: number;

  @IsOptional()
  @IsNumber()
  bathrooms?: number;

  @IsOptional()
  @IsNumber()
  floor?: number;

  @IsOptional()
  @IsNumber()
  totalFloors?: number;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  amenities?: string[];

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];
}
