-- Baribhara Comprehensive Database Schema
-- Migration 002: Complete schema supporting dual roles and Bangladesh market

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search

-- Drop existing tables if they exist (for clean migration)
DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS invoice_fields CASCADE;
DROP TABLE IF EXISTS invoices CASCADE;
DROP TABLE IF EXISTS tenant_requests CASCADE;
DROP TABLE IF EXISTS tenants CASCADE;
DROP TABLE IF EXISTS properties CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- 1. Users Table (Central user registry)
CREATE TABLE users (
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
CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('tenant', 'caretaker', 'admin', 'super_admin')),
    is_active BOOLEAN DEFAULT TRUE,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    granted_by UUID REFERENCES users(id),
    expires_at TIMESTAMP, -- for temporary roles
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Properties Table
CREATE TABLE properties (
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
    caretaker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    current_tenant_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Property Field Templates Table
CREATE TABLE property_field_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
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
CREATE TABLE tenant_property_relationships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    caretaker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
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

-- 6. Tenant Requests Table
CREATE TABLE tenant_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    caretaker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
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

-- 7. Invoices Table
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

-- 8. Invoice Fields Table
CREATE TABLE invoice_fields (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
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

-- 9. Payments Table (Bangladesh payment methods)
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    property_id UUID NOT NULL REFERENCES properties(id) ON DELETE CASCADE,
    caretaker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
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
    verified_by UUID REFERENCES users(id),
    
    -- Additional info
    notes TEXT,
    receipt_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Due Management Table
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
    status VARCHAR(50) NOT NULL DEFAULT 'outstanding' CHECK (status IN ('outstanding', 'paid', 'waived', 'written_off')),
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

-- 11. Reports Table
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    caretaker_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('monthly', 'yearly', 'tenant', 'property', 'custom')),
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
    file_format VARCHAR(20) CHECK (file_format IN ('pdf', 'excel', 'csv')),
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. Notifications Table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
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

-- Create Indexes for Performance

-- User indexes
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);

-- User roles indexes
CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role);
CREATE INDEX idx_user_roles_active ON user_roles(is_active) WHERE is_active = TRUE;

-- Property indexes
CREATE INDEX idx_properties_caretaker ON properties(caretaker_id);
CREATE INDEX idx_properties_current_tenant ON properties(current_tenant_id);
CREATE INDEX idx_properties_status ON properties(status);
CREATE INDEX idx_properties_type ON properties(type);
CREATE INDEX idx_properties_city ON properties(city);
CREATE INDEX idx_properties_district ON properties(district);
CREATE INDEX idx_properties_division ON properties(division);
CREATE INDEX idx_properties_rent_amount ON properties(rent_amount);

-- Property field templates indexes
CREATE INDEX idx_property_field_templates_property ON property_field_templates(property_id);
CREATE INDEX idx_property_field_templates_active ON property_field_templates(is_active) WHERE is_active = TRUE;

-- Tenant property relationships indexes
CREATE INDEX idx_tenant_property_tenant ON tenant_property_relationships(tenant_id);
CREATE INDEX idx_tenant_property_property ON tenant_property_relationships(property_id);
CREATE INDEX idx_tenant_property_caretaker ON tenant_property_relationships(caretaker_id);
CREATE INDEX idx_tenant_property_status ON tenant_property_relationships(status);
CREATE INDEX idx_tenant_property_active ON tenant_property_relationships(tenant_id, property_id) WHERE status = 'active';

-- Tenant requests indexes
CREATE INDEX idx_tenant_requests_tenant ON tenant_requests(tenant_id);
CREATE INDEX idx_tenant_requests_property ON tenant_requests(property_id);
CREATE INDEX idx_tenant_requests_caretaker ON tenant_requests(caretaker_id);
CREATE INDEX idx_tenant_requests_status ON tenant_requests(status);
CREATE INDEX idx_tenant_requests_requested_at ON tenant_requests(requested_at);

-- Invoice indexes
CREATE INDEX idx_invoices_property ON invoices(property_id);
CREATE INDEX idx_invoices_tenant ON invoices(tenant_id);
CREATE INDEX idx_invoices_caretaker ON invoices(caretaker_id);
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_month_year ON invoices(month, year);
CREATE INDEX idx_invoices_due_date ON invoices(due_date);
CREATE INDEX idx_invoices_invoice_number ON invoices(invoice_number);

-- Invoice fields indexes
CREATE INDEX idx_invoice_fields_invoice ON invoice_fields(invoice_id);
CREATE INDEX idx_invoice_fields_type ON invoice_fields(field_type);

-- Payment indexes
CREATE INDEX idx_payments_invoice ON payments(invoice_id);
CREATE INDEX idx_payments_tenant ON payments(tenant_id);
CREATE INDEX idx_payments_property ON payments(property_id);
CREATE INDEX idx_payments_caretaker ON payments(caretaker_id);
CREATE INDEX idx_payments_method ON payments(method);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_paid_at ON payments(paid_at);

-- Due indexes
CREATE INDEX idx_dues_tenant ON dues(tenant_id);
CREATE INDEX idx_dues_property ON dues(property_id);
CREATE INDEX idx_dues_invoice ON dues(invoice_id);
CREATE INDEX idx_dues_status ON dues(status);
CREATE INDEX idx_dues_due_date ON dues(due_date);
CREATE INDEX idx_dues_overdue ON dues(days_overdue) WHERE status = 'outstanding';

-- Report indexes
CREATE INDEX idx_reports_caretaker ON reports(caretaker_id);
CREATE INDEX idx_reports_type ON reports(report_type);
CREATE INDEX idx_reports_generated_at ON reports(generated_at);

-- Notification indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_priority ON notifications(priority);

-- Create Triggers for Automatic Updates

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at column
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_properties_updated_at BEFORE UPDATE ON properties FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_property_field_templates_updated_at BEFORE UPDATE ON property_field_templates FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tenant_property_relationships_updated_at BEFORE UPDATE ON tenant_property_relationships FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tenant_requests_updated_at BEFORE UPDATE ON tenant_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dues_updated_at BEFORE UPDATE ON dues FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create Functions for Business Logic

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

-- Apply trigger to invoices table
CREATE TRIGGER generate_invoice_number_trigger BEFORE INSERT ON invoices FOR EACH ROW EXECUTE FUNCTION generate_invoice_number();

-- Create Views for Common Queries

-- View for active tenant-property relationships
CREATE VIEW active_tenant_properties AS
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
JOIN users u ON tpr.tenant_id = u.id
JOIN properties p ON tpr.property_id = p.id
JOIN users c ON tpr.caretaker_id = c.id
WHERE tpr.status = 'active';

-- View for overdue payments
CREATE VIEW overdue_payments AS
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
JOIN users u ON d.tenant_id = u.id
JOIN properties p ON d.property_id = p.id
JOIN invoices i ON d.invoice_id = i.id
WHERE d.status = 'outstanding' AND d.due_date < CURRENT_DATE;

-- View for monthly rent summary
CREATE VIEW monthly_rent_summary AS
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
FROM invoices i
JOIN properties p ON i.property_id = p.id
JOIN users u ON i.tenant_id = u.id
ORDER BY i.year DESC, i.month DESC, p.name;

-- Insert Sample Data for Testing

-- Insert sample users
INSERT INTO users (id, name, phone_number, email, password_hash, status) VALUES
('11111111-1111-1111-1111-111111111111', 'Admin User', '+8801712345678', 'admin@baribhara.com', '$2b$10$hashedpassword', 'active'),
('22222222-2222-2222-2222-222222222222', 'John Doe', '+8801712345679', 'john@example.com', '$2b$10$hashedpassword', 'active'),
('33333333-3333-3333-3333-333333333333', 'Jane Smith', '+8801712345680', 'jane@example.com', '$2b$10$hashedpassword', 'active'),
('44444444-4444-4444-4444-444444444444', 'Ahmed Rahman', '+8801712345681', 'ahmed@example.com', '$2b$10$hashedpassword', 'active');

-- Insert user roles
INSERT INTO user_roles (user_id, role) VALUES
('11111111-1111-1111-1111-111111111111', 'super_admin'),
('22222222-2222-2222-2222-222222222222', 'caretaker'),
('33333333-3333-3333-3333-333333333333', 'tenant'),
('44444444-4444-4444-4444-444444444444', 'caretaker');

-- Insert sample properties
INSERT INTO properties (id, name, type, street, city, district, division, rent_amount, security_deposit, area, bedrooms, bathrooms, caretaker_id, unique_code) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Luxury Apartment Dhaka', 'apartment', 'House 123, Road 45', 'Dhaka', 'Dhanmondi', 'Dhaka', 50000.00, 100000.00, 1200.00, 3, 2, '22222222-2222-2222-2222-222222222222', 'APT001'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Modern House Chittagong', 'house', 'Plot 456, Block A', 'Chittagong', 'Panchlaish', 'Chittagong', 35000.00, 70000.00, 2000.00, 4, 3, '44444444-4444-4444-4444-444444444444', 'HSE001');

-- Insert property field templates
INSERT INTO property_field_templates (property_id, field_name, field_type, default_amount, is_required, display_order) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Rent', 'fixed', 50000.00, TRUE, 1),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Gas', 'variable', 2000.00, TRUE, 2),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Water', 'variable', 1500.00, TRUE, 3),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Electric', 'variable', 3000.00, TRUE, 4),
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Parking', 'fixed', 5000.00, FALSE, 5),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Rent', 'fixed', 35000.00, TRUE, 1),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Gas', 'variable', 1500.00, TRUE, 2),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Water', 'variable', 1000.00, TRUE, 3),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'Electric', 'variable', 2500.00, TRUE, 4);

-- Insert tenant-property relationships
INSERT INTO tenant_property_relationships (tenant_id, property_id, caretaker_id, contract_start_date, monthly_rent, security_deposit) VALUES
('33333333-3333-3333-3333-333333333333', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '22222222-2222-2222-2222-222222222222', '2024-01-01', 50000.00, 100000.00);

-- Update properties with current tenant
UPDATE properties SET current_tenant_id = '33333333-3333-3333-3333-333333333333' WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

COMMIT;
