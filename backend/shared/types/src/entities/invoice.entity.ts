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

export enum FieldType {
  RENT = 'rent',
  GAS = 'gas',
  WATER = 'water',
  ELECTRIC = 'electric',
  PARKING = 'parking',
  SERVICE = 'service',
  CUSTOM = 'custom',
}

export class InvoiceField {
  @IsString()
  id: string;

  @IsString()
  invoiceId: string;

  @IsString()
  fieldName: string;

  @IsEnum(FieldType)
  fieldType: FieldType;

  @IsNumber()
  amount: number;

  @IsOptional()
  @IsString()
  unit?: string; // per unit, per month, per sqft

  @IsOptional()
  @IsNumber()
  quantity?: number;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsBoolean()
  isTaxable?: boolean;

  @IsOptional()
  @IsNumber()
  taxRate?: number;

  @IsString()
  createdAt: string;
}

export enum PaymentStatus {
  PENDING = 'pending',
  COMPLETED = 'completed',
  FAILED = 'failed',
  REFUNDED = 'refunded',
}

export class Payment {
  @IsString()
  id: string;

  @IsString()
  invoiceId: string;

  @IsString()
  tenantId: string;

  @IsString()
  propertyId: string;

  @IsString()
  caretakerId: string;

  @IsNumber()
  amount: number;

  @IsEnum(PaymentMethod)
  method: PaymentMethod;

  @IsEnum(PaymentStatus)
  status: PaymentStatus;

  @IsOptional()
  @IsString()
  transactionId?: string;

  @IsOptional()
  @IsString()
  referenceNumber?: string;

  @IsOptional()
  @IsString()
  bankName?: string;

  @IsOptional()
  @IsString()
  accountNumber?: string;

  @IsOptional()
  @IsString()
  branchName?: string;

  // Bangladesh specific payment methods
  @IsOptional()
  @IsString()
  bkashNumber?: string;

  @IsOptional()
  @IsString()
  nagadNumber?: string;

  @IsOptional()
  @IsString()
  rocketNumber?: string;

  @IsOptional()
  @IsString()
  upaayNumber?: string;

  @IsString()
  paidAt: string;

  @IsOptional()
  @IsString()
  verifiedAt?: string;

  @IsOptional()
  @IsString()
  verifiedBy?: string;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsOptional()
  @IsString()
  receiptUrl?: string;

  @IsString()
  createdAt: string;
}

export class Invoice {
  @IsString()
  id: string;

  @IsString()
  propertyId: string;

  @IsString()
  tenantId: string;

  @IsString()
  caretakerId: string;

  @IsString()
  relationshipId: string;

  @IsNumber()
  month: number; // 1-12

  @IsNumber()
  year: number;

  @IsString()
  billingPeriodStart: string;

  @IsString()
  billingPeriodEnd: string;

  @IsString()
  invoiceNumber: string;

  @IsEnum(InvoiceStatus)
  status: InvoiceStatus;

  @IsNumber()
  totalAmount: number;

  @IsString()
  dueDate: string;

  @IsOptional()
  @IsString()
  paidAt?: string;

  @IsBoolean()
  isEditable: boolean;

  @IsNumber()
  lateFee: number;

  @IsNumber()
  discountAmount: number;

  @IsBoolean()
  sentViaEmail: boolean;

  @IsBoolean()
  sentViaSms: boolean;

  @IsBoolean()
  sentViaWhatsapp: boolean;

  @IsOptional()
  @IsString()
  notes?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => InvoiceField)
  fields: InvoiceField[];

  @IsOptional()
  @ValidateNested()
  @Type(() => Payment)
  payment?: Payment;

  @IsString()
  createdAt: string;

  @IsString()
  updatedAt: string;
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
