# Baribhara Database Design

## Overview

This document outlines the comprehensive database design for the Baribhara property management system, specifically addressing the complex requirement where users can act as both **tenant** and **caretaker** simultaneously.

## Key Design Principles

1. **Dual Role Support**: Users can be both tenants and caretakers
2. **Historical Data**: Maintain complete history of tenant-property relationships
3. **Flexible Rent Management**: Customizable invoice fields per property
4. **Due Management**: Track and manage outstanding payments
5. **Audit Trail**: Complete tracking of all changes and transactions
6. **Bangladesh Market**: Support for local payment methods (bKash, Nagad, etc.)

## Core Tables

### 1. Users Table
**Purpose**: Central user registry supporting dual roles

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    national_id VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, suspended, banned
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 2. User Roles Table
**Purpose**: Track user roles and capabilities

```sql
CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL, -- tenant, caretaker, admin, super_admin
    is_active BOOLEAN DEFAULT TRUE,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    granted_by UUID REFERENCES users(id),
    expires_at TIMESTAMP, -- for temporary roles
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for efficient role queries
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role);
```

### 3. Properties Table
**Purpose**: Property information and management

```sql
CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL, -- apartment, house, commercial, land
    status VARCHAR(50) NOT NULL DEFAULT 'available', -- available, occupied, maintenance, sold
    unique_code VARCHAR(50) UNIQUE, -- For tenant requests by code
    
    -- Address (Bangladesh specific)
    street VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    division VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20),
    landmark VARCHAR(255),
    
    -- Property details
    rent_amount DECIMAL(10,2) NOT NULL,
    security_deposit DECIMAL(10,2) NOT NULL,
    area DECIMAL(8,2) NOT NULL,
    bedrooms INTEGER,
    bathrooms INTEGER,
    floor INTEGER,
    total_floors INTEGER,
    amenities TEXT[], -- Array of amenities
    images TEXT[], -- Array of image URLs
    
    -- Ownership
    caretaker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    current_tenant_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 4. Property Field Templates Table
**Purpose**: Define customizable fields for each property's invoices

```sql
CREATE TABLE property_field_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    field_name VARCHAR(255) NOT NULL, -- rent, gas, water, electric, parking, service
    field_type VARCHAR(50) NOT NULL, -- fixed, variable, percentage
    default_amount DECIMAL(10,2) DEFAULT 0,
    is_required BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(property_id, field_name)
);
```

### 5. Tenant-Property Relationships Table
**Purpose**: Historical tracking of tenant-property relationships

```sql
CREATE TABLE tenant_property_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    caretaker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Relationship status
    status VARCHAR(50) NOT NULL DEFAULT 'active', -- active, terminated, suspended
    relationship_type VARCHAR(50) NOT NULL DEFAULT 'tenant', -- tenant, sub_tenant
    
    -- Contract details
    contract_start_date DATE NOT NULL,
    contract_end_date DATE,
    monthly_rent DECIMAL(10,2) NOT NULL,
    security_deposit DECIMAL(10,2) NOT NULL,
    lease_terms TEXT,
    
    -- Timeline
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP,
    termination_reason TEXT,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure one active relationship per tenant-property pair
    UNIQUE(tenant_id, property_id, status) WHERE status = 'active'
);

-- Indexes for efficient queries
CREATE INDEX idx_tenant_property_tenant ON tenant_property_relationships(tenant_id);
CREATE INDEX idx_tenant_property_property ON tenant_property_relationships(property_id);
CREATE INDEX idx_tenant_property_caretaker ON tenant_property_relationships(caretaker_id);
CREATE INDEX idx_tenant_property_status ON tenant_property_relationships(status);
```

### 6. Tenant Requests Table
**Purpose**: Handle tenant requests for properties

```sql
CREATE TABLE tenant_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    caretaker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Request details
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, approved, rejected, expired
    request_type VARCHAR(50) NOT NULL DEFAULT 'join', -- join, leave, transfer
    message TEXT,
    requested_rent DECIMAL(10,2),
    requested_deposit DECIMAL(10,2),
    
    -- Timeline
    requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    responded_at TIMESTAMP,
    expires_at TIMESTAMP,
    
    -- Response details
    response_message TEXT,
    approved_rent DECIMAL(10,2),
    approved_deposit DECIMAL(10,2),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 7. Invoices Table
**Purpose**: Monthly rent invoices with customizable fields

```sql
CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    caretaker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    relationship_id UUID NOT NULL REFERENCES tenant_property_relationships(id) ON DELETE CASCADE,
    
    -- Invoice period
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    year INTEGER NOT NULL,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    
    -- Invoice details
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft', -- draft, sent, paid, overdue, cancelled
    total_amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    paid_at TIMESTAMP,
    
    -- Payment tracking
    is_editable BOOLEAN DEFAULT TRUE, -- becomes false after payment
    late_fee DECIMAL(10,2) DEFAULT 0,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    
    -- Communication
    sent_via_email BOOLEAN DEFAULT FALSE,
    sent_via_sms BOOLEAN DEFAULT FALSE,
    sent_via_whatsapp BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure one invoice per property-tenant-month-year
    UNIQUE(property_id, tenant_id, month, year)
);
```

### 8. Invoice Fields Table
**Purpose**: Individual line items for each invoice

```sql
CREATE TABLE invoice_fields (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    field_name VARCHAR(255) NOT NULL,
    field_type VARCHAR(50) NOT NULL, -- rent, gas, water, electric, parking, service, custom
    amount DECIMAL(10,2) NOT NULL,
    unit VARCHAR(50), -- per unit, per month, per sqft
    quantity DECIMAL(10,2) DEFAULT 1,
    description TEXT,
    is_taxable BOOLEAN DEFAULT FALSE,
    tax_rate DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 9. Payments Table
**Purpose**: Track all payments with Bangladesh-specific methods

```sql
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    caretaker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Payment details
    amount DECIMAL(10,2) NOT NULL,
    method VARCHAR(50) NOT NULL, -- cash, bank_transfer, bkash, nagad, rocket, upaay, check
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, completed, failed, refunded
    
    -- Transaction details
    transaction_id VARCHAR(255),
    reference_number VARCHAR(255),
    bank_name VARCHAR(255),
    account_number VARCHAR(255),
    branch_name VARCHAR(255),
    
    -- Bangladesh specific payment methods
    bkash_number VARCHAR(50),
    nagad_number VARCHAR(50),
    rocket_number VARCHAR(50),
    upaay_number VARCHAR(50),
    
    -- Payment timeline
    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    verified_at TIMESTAMP,
    verified_by UUID REFERENCES users(id),
    
    -- Additional info
    notes TEXT,
    receipt_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 10. Due Management Table
**Purpose**: Track outstanding dues and payment history

```sql
CREATE TABLE dues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    
    -- Due details
    due_amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    days_overdue INTEGER DEFAULT 0,
    late_fee DECIMAL(10,2) DEFAULT 0,
    total_due DECIMAL(10,2) NOT NULL,
    
    -- Status tracking
    status VARCHAR(50) NOT NULL DEFAULT 'outstanding', -- outstanding, paid, waived, written_off
    payment_reminder_count INTEGER DEFAULT 0,
    last_reminder_sent TIMESTAMP,
    
    -- Resolution
    paid_at TIMESTAMP,
    payment_id UUID REFERENCES payments(id),
    waived_at TIMESTAMP,
    waived_by UUID REFERENCES users(id),
    waiver_reason TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 11. Reports Table
**Purpose**: Store generated reports with filters

```sql
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    caretaker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    report_type VARCHAR(50) NOT NULL, -- monthly, yearly, tenant, property, custom
    title VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Filter criteria (stored as JSON)
    filters JSONB NOT NULL,
    
    -- Report data (stored as JSON for flexibility)
    data JSONB NOT NULL,
    
    -- Report metadata
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    generated_by UUID NOT NULL REFERENCES users(id),
    file_url VARCHAR(500),
    file_format VARCHAR(20), -- pdf, excel, csv
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 12. Notifications Table
**Purpose**: System notifications and communications

```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- invoice, payment, request, system, reminder
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    
    -- Notification channels
    sent_via_email BOOLEAN DEFAULT FALSE,
    sent_via_sms BOOLEAN DEFAULT FALSE,
    sent_via_push BOOLEAN DEFAULT FALSE,
    sent_via_whatsapp BOOLEAN DEFAULT FALSE,
    
    -- Status tracking
    status VARCHAR(50) NOT NULL DEFAULT 'pending', -- pending, sent, delivered, failed
    read_at TIMESTAMP,
    delivered_at TIMESTAMP,
    
    -- Related entities
    related_entity_type VARCHAR(50), -- invoice, payment, property, tenant
    related_entity_id UUID,
    
    -- Metadata
    priority VARCHAR(20) DEFAULT 'normal', -- low, normal, high, urgent
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Key Relationships and Constraints

### 1. Dual Role Support
- Users can have multiple roles in `user_roles` table
- A user can be a tenant in one property and caretaker of another
- Historical relationships are preserved in `tenant_property_relationships`

### 2. Data Integrity
- Foreign key constraints ensure referential integrity
- Unique constraints prevent duplicate relationships
- Check constraints validate data ranges

### 3. Audit Trail
- All tables include `created_at` and `updated_at` timestamps
- Soft deletes where appropriate (using status fields)
- Complete history of tenant-property relationships

### 4. Performance Optimization
- Strategic indexes on frequently queried columns
- Composite indexes for complex queries
- JSONB for flexible data storage

## Bangladesh Market Specific Features

### 1. Payment Methods
- Support for bKash, Nagad, Rocket, Upaay
- Bank transfer with branch information
- Mobile banking integration

### 2. Address Structure
- Division, District, City hierarchy
- Postal code support
- Landmark references

### 3. Currency and Formatting
- Taka (BDT) as primary currency
- Local number formatting
- Bengali language support in metadata

## Query Examples

### 1. Find all properties where a user is both tenant and caretaker
```sql
SELECT DISTINCT p.*
FROM properties p
WHERE p.caretaker_id = $1
   OR p.id IN (
       SELECT tpr.property_id 
       FROM tenant_property_relationships tpr 
       WHERE tpr.tenant_id = $1 AND tpr.status = 'active'
   );
```

### 2. Get monthly rent summary for a caretaker
```sql
SELECT 
    p.name as property_name,
    u.name as tenant_name,
    i.month,
    i.year,
    i.total_amount,
    i.status
FROM invoices i
JOIN properties p ON i.property_id = p.id
JOIN users u ON i.tenant_id = u.id
WHERE i.caretaker_id = $1
  AND i.year = $2
ORDER BY i.month, p.name;
```

### 3. Find overdue payments
```sql
SELECT 
    u.name as tenant_name,
    p.name as property_name,
    d.due_amount,
    d.days_overdue,
    d.late_fee,
    d.total_due
FROM dues d
JOIN users u ON d.tenant_id = u.id
JOIN properties p ON d.property_id = p.id
WHERE d.status = 'outstanding'
  AND d.due_date < CURRENT_DATE
ORDER BY d.days_overdue DESC;
```

## Migration Strategy

1. **Phase 1**: Create core tables (users, properties, tenant_property_relationships)
2. **Phase 2**: Add invoice and payment systems
3. **Phase 3**: Implement due management and reporting
4. **Phase 4**: Add notification and communication features

This design ensures scalability, data integrity, and supports the complex dual-role requirements while being optimized for the Bangladesh market.
