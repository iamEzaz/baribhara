-- Initialize Baribhara Database
-- This script creates the database and initial setup

-- Create database if it doesn't exist
SELECT 'CREATE DATABASE baribhara'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'baribhara')\gexec

-- Connect to the baribhara database
\c baribhara;

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create initial admin user
INSERT INTO users (
    id,
    name,
    phone_number,
    email,
    password_hash,
    role,
    status,
    is_email_verified,
    is_phone_verified
) VALUES (
    uuid_generate_v4(),
    'Super Admin',
    '+8801000000000',
    'admin@baribhara.com',
    crypt('admin123', gen_salt('bf', 12)),
    'super_admin',
    'active',
    true,
    true
) ON CONFLICT (phone_number) DO NOTHING;

-- Insert system configurations
INSERT INTO system_configs (key, value, description, type) VALUES
('app_name', 'Baribhara', 'Application name', 'string'),
('app_version', '1.0.0', 'Application version', 'string'),
('maintenance_mode', 'false', 'Maintenance mode status', 'boolean'),
('max_file_size', '10485760', 'Maximum file upload size in bytes', 'number'),
('allowed_file_types', '["image/jpeg", "image/png", "image/gif", "application/pdf"]', 'Allowed file types for upload', 'json'),
('default_rent_fields', '["rent", "gas", "water", "electric", "parking", "service"]', 'Default rent fields', 'json'),
('payment_methods', '["cash", "bank_transfer", "bkash", "nagad", "rocket", "upaay"]', 'Available payment methods', 'json'),
('invoice_due_days', '7', 'Default invoice due days', 'number'),
('notification_retry_attempts', '3', 'Number of retry attempts for notifications', 'number'),
('session_timeout', '86400', 'Session timeout in seconds (24 hours)', 'number')
ON CONFLICT (key) DO NOTHING;

-- Create indexes for better performance
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_phone_number ON users(phone_number);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_status ON users(status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_properties_caretaker_id ON properties(caretaker_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_properties_current_tenant_id ON properties(current_tenant_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_properties_city ON properties(city);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_properties_district ON properties(district);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_properties_type ON properties(type);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_properties_status ON properties(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_properties_rent_amount ON properties(rent_amount);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tenants_user_id ON tenants(user_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tenants_property_id ON tenants(property_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tenants_caretaker_id ON tenants(caretaker_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_tenants_status ON tenants(status);

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_invoices_property_id ON invoices(property_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_invoices_tenant_id ON invoices(tenant_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_invoices_caretaker_id ON invoices(caretaker_id);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_invoices_month_year ON invoices(month, year);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);

-- Create views for common queries
CREATE OR REPLACE VIEW active_tenants AS
SELECT 
    t.*,
    u.name as tenant_name,
    u.phone_number as tenant_phone,
    u.email as tenant_email,
    p.name as property_name,
    p.rent_amount,
    p.address
FROM tenants t
JOIN users u ON t.user_id = u.id
JOIN properties p ON t.property_id = p.id
WHERE t.status = 'active';

CREATE OR REPLACE VIEW property_summary AS
SELECT 
    p.id,
    p.name,
    p.type,
    p.status,
    p.rent_amount,
    p.city,
    p.district,
    p.caretaker_id,
    u.name as caretaker_name,
    t.tenant_name,
    t.tenant_phone
FROM properties p
JOIN users u ON p.caretaker_id = u.id
LEFT JOIN active_tenants t ON p.id = t.property_id;

CREATE OR REPLACE VIEW monthly_invoice_summary AS
SELECT 
    i.property_id,
    i.tenant_id,
    i.caretaker_id,
    i.month,
    i.year,
    i.total_amount,
    i.status,
    i.due_date,
    p.name as property_name,
    u.name as tenant_name,
    c.name as caretaker_name
FROM invoices i
JOIN properties p ON i.property_id = p.id
JOIN users u ON i.tenant_id = u.id
JOIN users c ON i.caretaker_id = c.id;

-- Create functions for common operations
CREATE OR REPLACE FUNCTION get_user_properties(user_id UUID)
RETURNS TABLE (
    property_id UUID,
    property_name VARCHAR,
    property_type VARCHAR,
    rent_amount DECIMAL,
    status VARCHAR,
    tenant_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id,
        p.name,
        p.type,
        p.rent_amount,
        p.status,
        COALESCE(u.name, 'No tenant') as tenant_name
    FROM properties p
    LEFT JOIN tenants t ON p.id = t.property_id AND t.status = 'active'
    LEFT JOIN users u ON t.user_id = u.id
    WHERE p.caretaker_id = user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_tenant_invoices(tenant_id UUID, year INTEGER DEFAULT NULL)
RETURNS TABLE (
    invoice_id UUID,
    property_name VARCHAR,
    month INTEGER,
    year INTEGER,
    total_amount DECIMAL,
    status VARCHAR,
    due_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        p.name,
        i.month,
        i.year,
        i.total_amount,
        i.status,
        i.due_date
    FROM invoices i
    JOIN properties p ON i.property_id = p.id
    WHERE i.tenant_id = tenant_id
    AND (year IS NULL OR i.year = year)
    ORDER BY i.year DESC, i.month DESC;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for audit logging
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_logs (action, entity_type, entity_id, old_values)
        VALUES (TG_OP, TG_TABLE_NAME, OLD.id, row_to_json(OLD));
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_logs (action, entity_type, entity_id, old_values, new_values)
        VALUES (TG_OP, TG_TABLE_NAME, NEW.id, row_to_json(OLD), row_to_json(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_logs (action, entity_type, entity_id, new_values)
        VALUES (TG_OP, TG_TABLE_NAME, NEW.id, row_to_json(NEW));
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Apply audit triggers to important tables
CREATE TRIGGER users_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON users
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER properties_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON properties
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER tenants_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON tenants
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER invoices_audit_trigger
    AFTER INSERT OR UPDATE OR DELETE ON invoices
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO baribhara;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO baribhara;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO baribhara;
