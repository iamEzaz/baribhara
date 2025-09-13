import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';
import { PropertyType, PropertyStatus } from '@baribhara/shared-types';

@Entity('properties')
export class Property {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description?: string;

  @Column({ type: 'enum', enum: PropertyType })
  @Index()
  type: PropertyType;

  @Column({ type: 'enum', enum: PropertyStatus, default: PropertyStatus.AVAILABLE })
  @Index()
  status: PropertyStatus;

  // Address fields
  @Column({ type: 'varchar', length: 255 })
  street: string;

  @Column({ type: 'varchar', length: 100 })
  @Index()
  city: string;

  @Column({ type: 'varchar', length: 100 })
  @Index()
  district: string;

  @Column({ type: 'varchar', length: 100 })
  division: string;

  @Column({ type: 'varchar', length: 20, nullable: true })
  postalCode?: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  landmark?: string;

  // Property details
  @Column({ type: 'decimal', precision: 10, scale: 2 })
  @Index()
  rentAmount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  securityDeposit: number;

  @Column({ type: 'decimal', precision: 8, scale: 2 })
  area: number;

  @Column({ type: 'int', nullable: true })
  bedrooms?: number;

  @Column({ type: 'int', nullable: true })
  bathrooms?: number;

  @Column({ type: 'int', nullable: true })
  floor?: number;

  @Column({ type: 'int', nullable: true })
  totalFloors?: number;

  @Column({ type: 'text', array: true, default: '{}' })
  amenities: string[];

  @Column({ type: 'text', array: true, default: '{}' })
  images: string[];

  // Relationships
  @Column({ type: 'uuid' })
  @Index()
  caretakerId: string;

  @Column({ type: 'uuid', nullable: true })
  @Index()
  currentTenantId?: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
