import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';
import { TenantStatus, TenantType } from '@baribhara/shared-types';

@Entity('tenants')
export class Tenant {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'varchar', length: 20, unique: true })
  @Index()
  phoneNumber: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  email?: string;

  @Column({ type: 'varchar', length: 20, nullable: true })
  nationalId?: string;

  @Column({ type: 'enum', enum: TenantType, default: TenantType.INDIVIDUAL })
  @Index()
  type: TenantType;

  @Column({ type: 'enum', enum: TenantStatus, default: TenantStatus.ACTIVE })
  @Index()
  status: TenantStatus;

  // Emergency contact
  @Column({ type: 'varchar', length: 255, nullable: true })
  emergencyContactName?: string;

  @Column({ type: 'varchar', length: 20, nullable: true })
  emergencyContactPhone?: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  emergencyContactRelation?: string;

  // Address fields
  @Column({ type: 'varchar', length: 255, nullable: true })
  street?: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  @Index()
  city?: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  @Index()
  district?: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  division?: string;

  @Column({ type: 'varchar', length: 20, nullable: true })
  postalCode?: string;

  // Employment information
  @Column({ type: 'varchar', length: 255, nullable: true })
  occupation?: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  employer?: string;

  @Column({ type: 'decimal', precision: 12, scale: 2, nullable: true })
  monthlyIncome?: number;

  // Preferences
  @Column({ type: 'text', array: true, default: '{}' })
  preferences: string[];

  @Column({ type: 'text', array: true, default: '{}' })
  documents: string[];

  // Relationships
  @Column({ type: 'uuid' })
  @Index()
  userId: string;

  @Column({ type: 'uuid', nullable: true })
  @Index()
  currentPropertyId?: string;

  @Column({ type: 'uuid', nullable: true })
  @Index()
  caretakerId?: string;

  // Lease information
  @Column({ type: 'timestamp', nullable: true })
  leaseStartDate?: Date;

  @Column({ type: 'timestamp', nullable: true })
  leaseEndDate?: Date;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  monthlyRent?: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  securityDeposit?: number;

  @Column({ type: 'text', nullable: true })
  leaseTerms?: string;

  // Payment information
  @Column({ type: 'varchar', length: 50, nullable: true })
  preferredPaymentMethod?: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  bankAccountNumber?: string;

  @Column({ type: 'varchar', length: 100, nullable: true })
  bankName?: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  bkashNumber?: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  nagadNumber?: string;

  // Verification and compliance
  @Column({ type: 'boolean', default: false })
  isVerified: boolean;

  @Column({ type: 'timestamp', nullable: true })
  verifiedAt?: Date;

  @Column({ type: 'int', default: 0 })
  totalProperties: number;

  @Column({ type: 'int', default: 0 })
  activeLeases: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
