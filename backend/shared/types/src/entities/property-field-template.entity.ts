import { IsString, IsUUID, IsNumber, IsBoolean, IsOptional, IsEnum } from 'class-validator';
import { Expose } from 'class-transformer';

export enum FieldType {
  FIXED = 'fixed',
  VARIABLE = 'variable',
  PERCENTAGE = 'percentage',
}

export class PropertyFieldTemplate {
  @Expose()
  @IsUUID()
  id: string;

  @Expose()
  @IsUUID()
  propertyId: string;

  @Expose()
  @IsString()
  fieldName: string;

  @Expose()
  @IsEnum(FieldType)
  fieldType: FieldType;

  @Expose()
  @IsNumber()
  defaultAmount: number;

  @Expose()
  @IsBoolean()
  isRequired: boolean;

  @Expose()
  @IsBoolean()
  isActive: boolean;

  @Expose()
  @IsNumber()
  displayOrder: number;

  @Expose()
  @IsString()
  createdAt: string;

  @Expose()
  @IsString()
  updatedAt: string;
}

export class CreatePropertyFieldTemplateDto {
  @IsUUID()
  propertyId: string;

  @IsString()
  fieldName: string;

  @IsEnum(FieldType)
  fieldType: FieldType;

  @IsNumber()
  defaultAmount: number;

  @IsBoolean()
  isRequired: boolean;

  @IsOptional()
  @IsNumber()
  displayOrder?: number;
}

export class UpdatePropertyFieldTemplateDto {
  @IsOptional()
  @IsString()
  fieldName?: string;

  @IsOptional()
  @IsEnum(FieldType)
  fieldType?: FieldType;

  @IsOptional()
  @IsNumber()
  defaultAmount?: number;

  @IsOptional()
  @IsBoolean()
  isRequired?: boolean;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;

  @IsOptional()
  @IsNumber()
  displayOrder?: number;
}
