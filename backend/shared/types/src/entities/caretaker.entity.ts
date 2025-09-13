export enum CaretakerType {
  INDIVIDUAL = 'individual',
  COMPANY = 'company',
  AGENCY = 'agency',
}

export enum CaretakerStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  SUSPENDED = 'suspended',
}

export interface CaretakerAddress {
  street?: string;
  city?: string;
  district?: string;
  division?: string;
  postalCode?: string;
}

export interface CaretakerResponseDto {
  id: string;
  name: string;
  phoneNumber: string;
  email?: string;
  nationalId?: string;
  type: CaretakerType;
  status: CaretakerStatus;
  companyName?: string;
  licenseNumber?: string;
  description?: string;
  address?: CaretakerAddress;
  specialties: string[];
  languages: string[];
  rating?: number;
  totalProperties: number;
  activeProperties: number;
  totalTenants: number;
  isVerified: boolean;
  verifiedAt?: Date;
  documents: string[];
  userId: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateCaretakerDto {
  name: string;
  phoneNumber: string;
  email?: string;
  nationalId?: string;
  type: CaretakerType;
  companyName?: string;
  licenseNumber?: string;
  description?: string;
  address?: CaretakerAddress;
  specialties?: string[];
  languages?: string[];
  documents?: string[];
  userId: string;
}

export interface UpdateCaretakerDto {
  name?: string;
  email?: string;
  nationalId?: string;
  type?: CaretakerType;
  companyName?: string;
  licenseNumber?: string;
  description?: string;
  address?: CaretakerAddress;
  specialties?: string[];
  languages?: string[];
  documents?: string[];
}
