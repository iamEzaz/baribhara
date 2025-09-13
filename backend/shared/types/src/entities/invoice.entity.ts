import { IsString, IsOptional, IsNumber, IsEnum, IsDateString, IsArray, ValidateNested, IsBoolean } from 'class-validator';
import { Type } from 'class-transformer';

export enum InvoiceStatus {
  DRAFT = 'draft',
  SENT = 'sent',
  PAID = 'paid',
  OVERDUE = 'overdue',
  CANCELLED = 'cancelled',
}

export enum PaymentMethod {
  CASH = 'cash',
  BANK_TRANSFER = 'bank_transfer',
  BKASH = 'bkash',
  NAGAD = 'nagad',
  ROCKET = 'rocket',
  UPAAY = 'upaay',
}

export class InvoiceField {
  @IsString()
  name: string;

  @IsString()
  description: string;

  @IsNumber()
  amount: number;

  @IsOptional()
  @IsString()
  unit?: string; // e.g., "per unit", "per month"
}

export class Payment {
  id: string;
  invoiceId: string;
  amount: number;
  method: PaymentMethod;
  transactionId?: string;
  bankName?: string;
  accountNumber?: string;
  paidAt: Date;
  notes?: string;
  createdAt: Date;
}

export class Invoice {
  id: string;
  propertyId: string;
  tenantId: string;
  caretakerId: string;
  month: number; // 1-12
  year: number;
  status: InvoiceStatus;
  fields: InvoiceField[];
  totalAmount: number;
  dueDate: Date;
  paidAt?: Date;
  payment?: Payment;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

export class CreateInvoiceDto {
  @IsString()
  propertyId: string;

  @IsString()
  tenantId: string;

  @IsNumber()
  month: number;

  @IsNumber()
  year: number;

  @IsDateString()
  dueDate: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => InvoiceField)
  fields: InvoiceField[];

  @IsOptional()
  @IsString()
  notes?: string;
}

export class UpdateInvoiceDto {
  @IsOptional()
  @IsNumber()
  month?: number;

  @IsOptional()
  @IsNumber()
  year?: number;

  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => InvoiceField)
  fields?: InvoiceField[];

  @IsOptional()
  @IsString()
  notes?: string;
}

export class PaymentDto {
  @IsString()
  invoiceId: string;

  @IsNumber()
  amount: number;

  @IsEnum(PaymentMethod)
  method: PaymentMethod;

  @IsOptional()
  @IsString()
  transactionId?: string;

  @IsOptional()
  @IsString()
  bankName?: string;

  @IsOptional()
  @IsString()
  accountNumber?: string;

  @IsOptional()
  @IsString()
  notes?: string;
}

export class InvoiceReportFilter {
  @IsOptional()
  @IsString()
  propertyId?: string;

  @IsOptional()
  @IsString()
  tenantId?: string;

  @IsOptional()
  @IsString()
  caretakerId?: string;

  @IsOptional()
  @IsNumber()
  month?: number;

  @IsOptional()
  @IsNumber()
  year?: number;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  endDate?: string;

  @IsOptional()
  @IsEnum(InvoiceStatus)
  status?: InvoiceStatus;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  fieldNames?: string[];
}
