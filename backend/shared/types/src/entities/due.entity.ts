import { IsString, IsUUID, IsNumber, IsOptional, IsEnum, IsDateString } from 'class-validator';
import { Expose } from 'class-transformer';

export enum DueStatus {
  OUTSTANDING = 'outstanding',
  PAID = 'paid',
  WAIVED = 'waived',
  WRITTEN_OFF = 'written_off',
}

export class Due {
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
  invoiceId: string;

  @Expose()
  @IsNumber()
  dueAmount: number;

  @Expose()
  @IsDateString()
  dueDate: string;

  @Expose()
  @IsNumber()
  daysOverdue: number;

  @Expose()
  @IsNumber()
  lateFee: number;

  @Expose()
  @IsNumber()
  totalDue: number;

  @Expose()
  @IsEnum(DueStatus)
  status: DueStatus;

  @Expose()
  @IsNumber()
  paymentReminderCount: number;

  @Expose()
  @IsOptional()
  @IsDateString()
  lastReminderSent?: string;

  @Expose()
  @IsOptional()
  @IsDateString()
  paidAt?: string;

  @Expose()
  @IsOptional()
  @IsUUID()
  paymentId?: string;

  @Expose()
  @IsOptional()
  @IsDateString()
  waivedAt?: string;

  @Expose()
  @IsOptional()
  @IsUUID()
  waivedBy?: string;

  @Expose()
  @IsOptional()
  @IsString()
  waiverReason?: string;

  @Expose()
  @IsDateString()
  createdAt: string;

  @Expose()
  @IsDateString()
  updatedAt: string;
}

export class CreateDueDto {
  @IsUUID()
  tenantId: string;

  @IsUUID()
  propertyId: string;

  @IsUUID()
  invoiceId: string;

  @IsNumber()
  dueAmount: number;

  @IsDateString()
  dueDate: string;

  @IsOptional()
  @IsNumber()
  lateFee?: number;
}

export class UpdateDueDto {
  @IsOptional()
  @IsEnum(DueStatus)
  status?: DueStatus;

  @IsOptional()
  @IsNumber()
  lateFee?: number;

  @IsOptional()
  @IsString()
  waiverReason?: string;
}
