-- Baribhara Safe Migration Script
-- Migration 003: Safe migration from old schema to new comprehensive schema
-- This script preserves existing data while updating to the new design

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Step 1: Create backup tables for existing data
CREATE TABLE IF NOT EXISTS users_backup AS SELECT * FROM users;
CREATE TABLE IF NOT EXISTS properties_backup AS SELECT * FROM properties;
CREATE TABLE IF NOT EXISTS tenants_backup AS SELECT * FROM tenants;
CREATE TABLE IF NOT EXISTS tenant_requests_backup AS SELECT * FROM tenant_requests;
CREATE TABLE IF NOT EXISTS invoices_backup AS SELECT * FROM invoices;
CREATE TABLE IF NOT EXISTS invoice_fields_backup AS SELECT * FROM invoice_fields;
CREATE TABLE IF NOT EXISTS payments_backup AS SELECT * FROM payments;

-- Step 2: Create new tables (without dropping old ones yet)
-- 1. New Users Table (without role column)
CREATE TABLE IF NOT EXISTS users_new (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    national_id VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'banned')),
    is_email_verified BOOLEAN DEFAULT FALSE,
    is_phone_verified BOOLEAN DEFAULT FALSE,
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. User Roles Table (Support dual roles)
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('tenant', 'caretaker', 'admin', 'super_admin')),
    is_active BOOLEAN DEFAULT TRUE,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    granted_by UUID REFERENCES users_new(id),
    expires_at TIMESTAMP, -- for temporary roles
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. New Properties Table
CREATE TABLE IF NOT EXISTS properties_new (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL CHECK (type IN ('apartment', 'house', 'commercial', 'land')),
    status VARCHAR(50) NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'occupied', 'maintenance', 'sold')),
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
    caretaker_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    current_tenant_id UUID REFERENCES users_new(id) ON DELETE SET NULL,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Property Field Templates Table
CREATE TABLE IF NOT EXISTS property_field_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties_new(id) ON DELETE CASCADE,
    field_name VARCHAR(255) NOT NULL,
    field_type VARCHAR(50) NOT NULL CHECK (field_type IN ('fixed', 'variable', 'percentage')),
    default_amount DECIMAL(10,2) DEFAULT 0,
    is_required BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(property_id, field_name)
);

-- 5. Tenant-Property Relationships Table (Historical tracking)
CREATE TABLE IF NOT EXISTS tenant_property_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties_new(id) ON DELETE CASCADE,
    caretaker_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    
    -- Relationship status
    status VARCHAR(50) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'terminated', 'suspended')),
    relationship_type VARCHAR(50) NOT NULL DEFAULT 'tenant' CHECK (relationship_type IN ('tenant', 'sub_tenant')),
    
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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. New Tenant Requests Table
CREATE TABLE IF NOT EXISTS tenant_requests_new (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties_new(id) ON DELETE CASCADE,
    caretaker_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    
    -- Request details
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'expired')),
    request_type VARCHAR(50) NOT NULL DEFAULT 'join' CHECK (request_type IN ('join', 'leave', 'transfer')),
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

-- 7. New Invoices Table
CREATE TABLE IF NOT EXISTS invoices_new (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties_new(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    caretaker_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    relationship_id UUID NOT NULL REFERENCES tenant_property_relationships(id) ON DELETE CASCADE,
    
    -- Invoice period
    month INTEGER NOT NULL CHECK (month >= 1 AND month <= 12),
    year INTEGER NOT NULL,
    billing_period_start DATE NOT NULL,
    billing_period_end DATE NOT NULL,
    
    -- Invoice details
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
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

-- 8. New Invoice Fields Table
CREATE TABLE IF NOT EXISTS invoice_fields_new (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices_new(id) ON DELETE CASCADE,
    field_name VARCHAR(255) NOT NULL,
    field_type VARCHAR(50) NOT NULL CHECK (field_type IN ('rent', 'gas', 'water', 'electric', 'parking', 'service', 'custom')),
    amount DECIMAL(10,2) NOT NULL,
    unit VARCHAR(50), -- per unit, per month, per sqft
    quantity DECIMAL(10,2) DEFAULT 1,
    description TEXT,
    is_taxable BOOLEAN DEFAULT FALSE,
    tax_rate DECIMAL(5,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 9. New Payments Table (Bangladesh payment methods)
CREATE TABLE IF NOT EXISTS payments_new (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices_new(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties_new(id) ON DELETE CASCADE,
    caretaker_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    
    -- Payment details
    amount DECIMAL(10,2) NOT NULL,
    method VARCHAR(50) NOT NULL CHECK (method IN ('cash', 'bank_transfer', 'bkash', 'nagad', 'rocket', 'upaay', 'check')),
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    
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
    verified_by UUID REFERENCES users_new(id),
    
    -- Additional info
    notes TEXT,
    receipt_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Due Management Table
CREATE TABLE IF NOT EXISTS dues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties_new(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices_new(id) ON DELETE CASCADE,
    
    -- Due details
    due_amount DECIMAL(10,2) NOT NULL,
    due_date DATE NOT NULL,
    days_overdue INTEGER DEFAULT 0,
    late_fee DECIMAL(10,2) DEFAULT 0,
    total_due DECIMAL(10,2) NOT NULL,
    
    -- Status tracking
    status VARCHAR(50) NOT NULL DEFAULT 'outstanding' CHECK (status IN ('outstanding', 'paid', 'waived', 'written_off')),
    payment_reminder_count INTEGER DEFAULT 0,
    last_reminder_sent TIMESTAMP,
    
    -- Resolution
    paid_at TIMESTAMP,
    payment_id UUID REFERENCES payments_new(id),
    waived_at TIMESTAMP,
    waived_by UUID REFERENCES users_new(id),
    waiver_reason TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 11. Reports Table
CREATE TABLE IF NOT EXISTS reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    caretaker_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('monthly', 'yearly', 'tenant', 'property', 'custom')),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Filter criteria (stored as JSON)
    filters JSONB NOT NULL,
    
    -- Report data (stored as JSON for flexibility)
    data JSONB NOT NULL,
    
    -- Report metadata
    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    generated_by UUID NOT NULL REFERENCES users_new(id),
    file_url VARCHAR(500),
    file_format VARCHAR(20) CHECK (file_format IN ('pdf', 'excel', 'csv')),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users_new(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('invoice', 'payment', 'request', 'system', 'reminder')),
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    
    -- Notification channels
    sent_via_email BOOLEAN DEFAULT FALSE,
    sent_via_sms BOOLEAN DEFAULT FALSE,
    sent_via_push BOOLEAN DEFAULT FALSE,
    sent_via_whatsapp BOOLEAN DEFAULT FALSE,
    
    -- Status tracking
    status VARCHAR(50) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'delivered', 'failed')),
    read_at TIMESTAMP,
    delivered_at TIMESTAMP,
    
    -- Related entities
    related_entity_type VARCHAR(50) CHECK (related_entity_type IN ('invoice', 'payment', 'property', 'tenant')),
    related_entity_id UUID,
    
    -- Metadata
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Step 3: Migrate data from old tables to new tables
-- Migrate users (remove role column, add to user_roles)
INSERT INTO users_new (id, name, phone_number, email, national_id, password_hash, status, is_email_verified, is_phone_verified, last_login_at, created_at, updated_at)
SELECT id, name, phone_number, email, national_id, password_hash, 
       CASE 
           WHEN status = 'inactive' THEN 'suspended'
           ELSE status 
       END,
       is_email_verified, is_phone_verified, last_login_at, created_at, updated_at
FROM users
ON CONFLICT (id) DO NOTHING;

-- Migrate user roles from old users table
INSERT INTO user_roles (user_id, role, is_active, granted_at, created_at)
SELECT id, 
       CASE 
           WHEN role = 'super_admin' THEN 'super_admin'
           WHEN role = 'caretaker' THEN 'caretaker'
           WHEN role = 'tenant' THEN 'tenant'
           ELSE 'tenant'
       END,
       TRUE, created_at, created_at
FROM users
ON CONFLICT DO NOTHING;

-- Migrate properties
INSERT INTO properties_new (id, name, description, type, status, street, city, district, division, postal_code, landmark, rent_amount, security_deposit, area, bedrooms, bathrooms, floor, total_floors, amenities, images, caretaker_id, current_tenant_id, created_at, updated_at)
SELECT id, name, description, type, status, street, city, district, division, postal_code, landmark, rent_amount, security_deposit, area, bedrooms, bathrooms, floor, total_floors, amenities, images, caretaker_id, current_tenant_id, created_at, updated_at
FROM properties
ON CONFLICT (id) DO NOTHING;

-- Migrate tenant-property relationships from old tenants table
INSERT INTO tenant_property_relationships (id, tenant_id, property_id, caretaker_id, status, relationship_type, contract_start_date, contract_end_date, monthly_rent, security_deposit, joined_at, left_at, created_at, updated_at)
SELECT id, user_id, property_id, caretaker_id, 
       CASE 
           WHEN status = 'active' THEN 'active'
           ELSE 'terminated'
       END,
       'tenant', contract_start_date, contract_end_date, monthly_rent, security_deposit, joined_at, left_at, created_at, updated_at
FROM tenants
ON CONFLICT (id) DO NOTHING;

-- Migrate tenant requests
INSERT INTO tenant_requests_new (id, tenant_id, property_id, caretaker_id, status, message, requested_at, responded_at, created_at, updated_at)
SELECT id, tenant_id, property_id, caretaker_id, status, message, requested_at, responded_at, created_at, updated_at
FROM tenant_requests
ON CONFLICT (id) DO NOTHING;

-- Migrate invoices (need to create relationship_id mapping)
INSERT INTO invoices_new (id, property_id, tenant_id, caretaker_id, relationship_id, month, year, billing_period_start, billing_period_end, invoice_number, status, total_amount, due_date, paid_at, notes, created_at, updated_at)
SELECT i.id, i.property_id, i.tenant_id, i.caretaker_id, 
       COALESCE(tpr.id, uuid_generate_v4()) as relationship_id,
       i.month, i.year, 
       DATE(i.year || '-' || i.month || '-01') as billing_period_start,
       (DATE(i.year || '-' || i.month || '-01') + INTERVAL '1 month' - INTERVAL '1 day') as billing_period_end,
       'INV-' || TO_CHAR(i.created_at, 'YYYYMMDD') || '-' || SUBSTRING(i.id::text, 1, 8) as invoice_number,
       i.status, i.total_amount, i.due_date, i.paid_at, i.notes, i.created_at, i.updated_at
FROM invoices i
LEFT JOIN tenant_property_relationships tpr ON i.tenant_id = tpr.tenant_id AND i.property_id = tpr.property_id
ON CONFLICT (id) DO NOTHING;

-- Migrate invoice fields
INSERT INTO invoice_fields_new (id, invoice_id, field_name, field_type, amount, unit, description, created_at)
SELECT id, invoice_id, name, 'custom', amount, unit, description, created_at
FROM invoice_fields
ON CONFLICT (id) DO NOTHING;

-- Migrate payments
INSERT INTO payments_new (id, invoice_id, tenant_id, property_id, caretaker_id, amount, method, status, transaction_id, bank_name, account_number, paid_at, notes, created_at)
SELECT p.id, p.invoice_id, i.tenant_id, i.property_id, i.caretaker_id, p.amount, p.method, 'completed', p.transaction_id, p.bank_name, p.account_number, p.paid_at, p.notes, p.created_at
FROM payments p
JOIN invoices i ON p.invoice_id = i.id
ON CONFLICT (id) DO NOTHING;

-- Step 4: Create indexes for new tables
-- User indexes
CREATE INDEX IF NOT EXISTS idx_users_new_phone ON users_new(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_new_email ON users_new(email);
CREATE INDEX IF NOT EXISTS idx_users_new_status ON users_new(status);

-- User roles indexes
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role);
CREATE INDEX IF NOT EXISTS idx_user_roles_active ON user_roles(is_active) WHERE is_active = TRUE;

-- Property indexes
CREATE INDEX IF NOT EXISTS idx_properties_new_caretaker ON properties_new(caretaker_id);
CREATE INDEX IF NOT EXISTS idx_properties_new_current_tenant ON properties_new(current_tenant_id);
CREATE INDEX IF NOT EXISTS idx_properties_new_status ON properties_new(status);
CREATE INDEX IF NOT EXISTS idx_properties_new_type ON properties_new(type);
CREATE INDEX IF NOT EXISTS idx_properties_new_city ON properties_new(city);
CREATE INDEX IF NOT EXISTS idx_properties_new_district ON properties_new(district);
CREATE INDEX IF NOT EXISTS idx_properties_new_division ON properties_new(division);
CREATE INDEX IF NOT EXISTS idx_properties_new_rent_amount ON properties_new(rent_amount);

-- Property field templates indexes
CREATE INDEX IF NOT EXISTS idx_property_field_templates_property ON property_field_templates(property_id);
CREATE INDEX IF NOT EXISTS idx_property_field_templates_active ON property_field_templates(is_active) WHERE is_active = TRUE;

-- Tenant property relationships indexes
CREATE INDEX IF NOT EXISTS idx_tenant_property_tenant ON tenant_property_relationships(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_property_property ON tenant_property_relationships(property_id);
CREATE INDEX IF NOT EXISTS idx_tenant_property_caretaker ON tenant_property_relationships(caretaker_id);
CREATE INDEX IF NOT EXISTS idx_tenant_property_status ON tenant_property_relationships(status);
CREATE INDEX IF NOT EXISTS idx_tenant_property_active ON tenant_property_relationships(tenant_id, property_id) WHERE status = 'active';

-- Tenant requests indexes
CREATE INDEX IF NOT EXISTS idx_tenant_requests_new_tenant ON tenant_requests_new(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_requests_new_property ON tenant_requests_new(property_id);
CREATE INDEX IF NOT EXISTS idx_tenant_requests_new_caretaker ON tenant_requests_new(caretaker_id);
CREATE INDEX IF NOT EXISTS idx_tenant_requests_new_status ON tenant_requests_new(status);
CREATE INDEX IF NOT EXISTS idx_tenant_requests_new_requested_at ON tenant_requests_new(requested_at);

-- Invoice indexes
CREATE INDEX IF NOT EXISTS idx_invoices_new_property ON invoices_new(property_id);
CREATE INDEX IF NOT EXISTS idx_invoices_new_tenant ON invoices_new(tenant_id);
CREATE INDEX IF NOT EXISTS idx_invoices_new_caretaker ON invoices_new(caretaker_id);
CREATE INDEX IF NOT EXISTS idx_invoices_new_status ON invoices_new(status);
CREATE INDEX IF NOT EXISTS idx_invoices_new_month_year ON invoices_new(month, year);
CREATE INDEX IF NOT EXISTS idx_invoices_new_due_date ON invoices_new(due_date);
CREATE INDEX IF NOT EXISTS idx_invoices_new_invoice_number ON invoices_new(invoice_number);

-- Invoice fields indexes
CREATE INDEX IF NOT EXISTS idx_invoice_fields_new_invoice ON invoice_fields_new(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_fields_new_type ON invoice_fields_new(field_type);

-- Payment indexes
CREATE INDEX IF NOT EXISTS idx_payments_new_invoice ON payments_new(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_new_tenant ON payments_new(tenant_id);
CREATE INDEX IF NOT EXISTS idx_payments_new_property ON payments_new(property_id);
CREATE INDEX IF NOT EXISTS idx_payments_new_caretaker ON payments_new(caretaker_id);
CREATE INDEX IF NOT EXISTS idx_payments_new_method ON payments_new(method);
CREATE INDEX IF NOT EXISTS idx_payments_new_status ON payments_new(status);
CREATE INDEX IF NOT EXISTS idx_payments_new_paid_at ON payments_new(paid_at);

-- Due indexes
CREATE INDEX IF NOT EXISTS idx_dues_tenant ON dues(tenant_id);
CREATE INDEX IF NOT EXISTS idx_dues_property ON dues(property_id);
CREATE INDEX IF NOT EXISTS idx_dues_invoice ON dues(invoice_id);
CREATE INDEX IF NOT EXISTS idx_dues_status ON dues(status);
CREATE INDEX IF NOT EXISTS idx_dues_due_date ON dues(due_date);
CREATE INDEX IF NOT EXISTS idx_dues_overdue ON dues(days_overdue) WHERE status = 'outstanding';

-- Report indexes
CREATE INDEX IF NOT EXISTS idx_reports_caretaker ON reports(caretaker_id);
CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(report_type);
CREATE INDEX IF NOT EXISTS idx_reports_generated_at ON reports(generated_at);

-- Notification indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications(status);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_priority ON notifications(priority);

-- Step 5: Create triggers for automatic updates
-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at column
CREATE TRIGGER update_users_new_updated_at BEFORE UPDATE ON users_new FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_properties_new_updated_at BEFORE UPDATE ON properties_new FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_property_field_templates_updated_at BEFORE UPDATE ON property_field_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tenant_property_relationships_updated_at BEFORE UPDATE ON tenant_property_relationships FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tenant_requests_new_updated_at BEFORE UPDATE ON tenant_requests_new FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_invoices_new_updated_at BEFORE UPDATE ON invoices_new FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dues_updated_at BEFORE UPDATE ON dues FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate days overdue
CREATE OR REPLACE FUNCTION calculate_days_overdue()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.due_date < CURRENT_DATE AND NEW.status = 'outstanding' THEN
        NEW.days_overdue = CURRENT_DATE - NEW.due_date;
    ELSE
        NEW.days_overdue = 0;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to dues table
CREATE TRIGGER calculate_dues_overdue BEFORE INSERT OR UPDATE ON dues FOR EACH ROW EXECUTE FUNCTION calculate_days_overdue();

-- Function to generate invoice number
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
        NEW.invoice_number = 'INV-' || TO_CHAR(NEW.created_at, 'YYYYMMDD') || '-' || SUBSTRING(NEW.id::text, 1, 8);
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to invoices_new table
CREATE TRIGGER generate_invoice_number_trigger BEFORE INSERT ON invoices_new FOR EACH ROW EXECUTE FUNCTION generate_invoice_number();

-- Step 6: Create views for common queries
-- View for active tenant-property relationships
CREATE OR REPLACE VIEW active_tenant_properties AS
SELECT 
    tpr.*,
    u.name as tenant_name,
    u.phone_number as tenant_phone,
    u.email as tenant_email,
    p.name as property_name,
    p.street as property_street,
    p.city as property_city,
    p.rent_amount as property_rent,
    c.name as caretaker_name,
    c.phone_number as caretaker_phone
FROM tenant_property_relationships tpr
JOIN users_new u ON tpr.tenant_id = u.id
JOIN properties_new p ON tpr.property_id = p.id
JOIN users_new c ON tpr.caretaker_id = c.id
WHERE tpr.status = 'active';

-- View for overdue payments
CREATE OR REPLACE VIEW overdue_payments AS
SELECT 
    d.*,
    u.name as tenant_name,
    u.phone_number as tenant_phone,
    p.name as property_name,
    p.street as property_street,
    p.city as property_city,
    i.invoice_number,
    i.total_amount as invoice_amount
FROM dues d
JOIN users_new u ON d.tenant_id = u.id
JOIN properties_new p ON d.property_id = p.id
JOIN invoices_new i ON d.invoice_id = i.id
WHERE d.status = 'outstanding' AND d.due_date < CURRENT_DATE;

-- View for monthly rent summary
CREATE OR REPLACE VIEW monthly_rent_summary AS
SELECT 
    i.caretaker_id,
    i.property_id,
    i.tenant_id,
    i.month,
    i.year,
    p.name as property_name,
    u.name as tenant_name,
    i.total_amount,
    i.status,
    i.paid_at
FROM invoices_new i
JOIN properties_new p ON i.property_id = p.id
JOIN users_new u ON i.tenant_id = u.id
ORDER BY i.year DESC, i.month DESC, p.name;

-- Step 7: Verify data migration
-- Check if all users were migrated
DO $$
DECLARE
    old_count INTEGER;
    new_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO old_count FROM users;
    SELECT COUNT(*) INTO new_count FROM users_new;
    
    IF old_count != new_count THEN
        RAISE EXCEPTION 'User migration failed: old_count=%, new_count=%', old_count, new_count;
    ELSE
        RAISE NOTICE 'User migration successful: % users migrated', new_count;
    END IF;
END $$;

-- Check if all properties were migrated
DO $$
DECLARE
    old_count INTEGER;
    new_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO old_count FROM properties;
    SELECT COUNT(*) INTO new_count FROM properties_new;
    
    IF old_count != new_count THEN
        RAISE EXCEPTION 'Property migration failed: old_count=%, new_count=%', old_count, new_count;
    ELSE
        RAISE NOTICE 'Property migration successful: % properties migrated', new_count;
    END IF;
END $$;

-- Check if all tenants were migrated
DO $$
DECLARE
    old_count INTEGER;
    new_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO old_count FROM tenants;
    SELECT COUNT(*) INTO new_count FROM tenant_property_relationships;
    
    IF old_count != new_count THEN
        RAISE EXCEPTION 'Tenant migration failed: old_count=%, new_count=%', old_count, new_count;
    ELSE
        RAISE NOTICE 'Tenant migration successful: % relationships migrated', new_count;
    END IF;
END $$;

-- Step 8: Final verification message
DO $$
BEGIN
    RAISE NOTICE 'Migration completed successfully!';
    RAISE NOTICE 'New tables created with _new suffix';
    RAISE NOTICE 'Old tables preserved with _backup suffix';
    RAISE NOTICE 'Next step: Test the new schema and then run the cleanup script';
END $$;
