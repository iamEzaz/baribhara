import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

export enum CaretakerStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  SUSPENDED = 'suspended',
}

export enum CaretakerType {
  INDIVIDUAL = 'individual',
  COMPANY = 'company',
  AGENCY = 'agency',
}

@Entity('caretakers')
export class Caretaker {
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

  @Column({ type: 'enum', enum: CaretakerType, default: CaretakerType.INDIVIDUAL })
  @Index()
  type: CaretakerType;

  @Column({ type: 'enum', enum: CaretakerStatus, default: CaretakerStatus.ACTIVE })
  @Index()
  status: CaretakerStatus;

  // Company/Agency specific fields
  @Column({ type: 'varchar', length: 255, nullable: true })
  companyName?: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  licenseNumber?: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

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

  // Profile and preferences
  @Column({ type: 'text', array: true, default: '{}' })
  specialties: string[];

  @Column({ type: 'text', array: true, default: '{}' })
  languages: string[];

  @Column({ type: 'decimal', precision: 5, scale: 2, nullable: true })
  rating?: number;

  @Column({ type: 'int', default: 0 })
  totalProperties: number;

  @Column({ type: 'int', default: 0 })
  activeProperties: number;

  @Column({ type: 'int', default: 0 })
  totalTenants: number;

  // Verification and compliance
  @Column({ type: 'boolean', default: false })
  isVerified: boolean;

  @Column({ type: 'timestamp', nullable: true })
  verifiedAt?: Date;

  @Column({ type: 'text', array: true, default: '{}' })
  documents: string[];

  // Relationships
  @Column({ type: 'uuid' })
  @Index()
  userId: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
