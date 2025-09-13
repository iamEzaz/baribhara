-- Baribhara Migration Cleanup Script
-- Migration 004: Cleanup after successful migration
-- This script renames new tables to replace old ones and removes backup tables

-- Step 1: Rename old tables to _old suffix (for final backup)
ALTER TABLE users RENAME TO users_old;
ALTER TABLE properties RENAME TO properties_old;
ALTER TABLE tenants RENAME TO tenants_old;
ALTER TABLE tenant_requests RENAME TO tenant_requests_old;
ALTER TABLE invoices RENAME TO invoices_old;
ALTER TABLE invoice_fields RENAME TO invoice_fields_old;
ALTER TABLE payments RENAME TO payments_old;

-- Step 2: Rename new tables to their final names
ALTER TABLE users_new RENAME TO users;
ALTER TABLE properties_new RENAME TO properties;
ALTER TABLE tenant_property_relationships RENAME TO tenant_property_relationships;
ALTER TABLE tenant_requests_new RENAME TO tenant_requests;
ALTER TABLE invoices_new RENAME TO invoices;
ALTER TABLE invoice_fields_new RENAME TO invoice_fields;
ALTER TABLE payments_new RENAME TO payments;

-- Step 3: Update foreign key references in user_roles table
-- (This should already be correct, but let's verify)
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey;
ALTER TABLE user_roles ADD CONSTRAINT user_roles_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Step 4: Update foreign key references in properties table
ALTER TABLE properties DROP CONSTRAINT IF EXISTS properties_caretaker_id_fkey;
ALTER TABLE properties ADD CONSTRAINT properties_caretaker_id_fkey 
    FOREIGN KEY (caretaker_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE properties DROP CONSTRAINT IF EXISTS properties_current_tenant_id_fkey;
ALTER TABLE properties ADD CONSTRAINT properties_current_tenant_id_fkey 
    FOREIGN KEY (current_tenant_id) REFERENCES users(id) ON DELETE SET NULL;

-- Step 5: Update foreign key references in property_field_templates table
ALTER TABLE property_field_templates DROP CONSTRAINT IF EXISTS property_field_templates_property_id_fkey;
ALTER TABLE property_field_templates ADD CONSTRAINT property_field_templates_property_id_fkey 
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE;

-- Step 6: Update foreign key references in tenant_property_relationships table
ALTER TABLE tenant_property_relationships DROP CONSTRAINT IF EXISTS tenant_property_relationships_tenant_id_fkey;
ALTER TABLE tenant_property_relationships ADD CONSTRAINT tenant_property_relationships_tenant_id_fkey 
    FOREIGN KEY (tenant_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE tenant_property_relationships DROP CONSTRAINT IF EXISTS tenant_property_relationships_property_id_fkey;
ALTER TABLE tenant_property_relationships ADD CONSTRAINT tenant_property_relationships_property_id_fkey 
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE;

ALTER TABLE tenant_property_relationships DROP CONSTRAINT IF EXISTS tenant_property_relationships_caretaker_id_fkey;
ALTER TABLE tenant_property_relationships ADD CONSTRAINT tenant_property_relationships_caretaker_id_fkey 
    FOREIGN KEY (caretaker_id) REFERENCES users(id) ON DELETE CASCADE;

-- Step 7: Update foreign key references in tenant_requests table
ALTER TABLE tenant_requests DROP CONSTRAINT IF EXISTS tenant_requests_tenant_id_fkey;
ALTER TABLE tenant_requests ADD CONSTRAINT tenant_requests_tenant_id_fkey 
    FOREIGN KEY (tenant_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE tenant_requests DROP CONSTRAINT IF EXISTS tenant_requests_property_id_fkey;
ALTER TABLE tenant_requests ADD CONSTRAINT tenant_requests_property_id_fkey 
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE;

ALTER TABLE tenant_requests DROP CONSTRAINT IF EXISTS tenant_requests_caretaker_id_fkey;
ALTER TABLE tenant_requests ADD CONSTRAINT tenant_requests_caretaker_id_fkey 
    FOREIGN KEY (caretaker_id) REFERENCES users(id) ON DELETE CASCADE;

-- Step 8: Update foreign key references in invoices table
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_property_id_fkey;
ALTER TABLE invoices ADD CONSTRAINT invoices_property_id_fkey 
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE;

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_tenant_id_fkey;
ALTER TABLE invoices ADD CONSTRAINT invoices_tenant_id_fkey 
    FOREIGN KEY (tenant_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_caretaker_id_fkey;
ALTER TABLE invoices ADD CONSTRAINT invoices_caretaker_id_fkey 
    FOREIGN KEY (caretaker_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_relationship_id_fkey;
ALTER TABLE invoices ADD CONSTRAINT invoices_relationship_id_fkey 
    FOREIGN KEY (relationship_id) REFERENCES tenant_property_relationships(id) ON DELETE CASCADE;

-- Step 9: Update foreign key references in invoice_fields table
ALTER TABLE invoice_fields DROP CONSTRAINT IF EXISTS invoice_fields_invoice_id_fkey;
ALTER TABLE invoice_fields ADD CONSTRAINT invoice_fields_invoice_id_fkey 
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE;

-- Step 10: Update foreign key references in payments table
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_invoice_id_fkey;
ALTER TABLE payments ADD CONSTRAINT payments_invoice_id_fkey 
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE;

ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_tenant_id_fkey;
ALTER TABLE payments ADD CONSTRAINT payments_tenant_id_fkey 
    FOREIGN KEY (tenant_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_property_id_fkey;
ALTER TABLE payments ADD CONSTRAINT payments_property_id_fkey 
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE;

ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_caretaker_id_fkey;
ALTER TABLE payments ADD CONSTRAINT payments_caretaker_id_fkey 
    FOREIGN KEY (caretaker_id) REFERENCES users(id) ON DELETE CASCADE;

-- Step 11: Update foreign key references in dues table
ALTER TABLE dues DROP CONSTRAINT IF EXISTS dues_tenant_id_fkey;
ALTER TABLE dues ADD CONSTRAINT dues_tenant_id_fkey 
    FOREIGN KEY (tenant_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE dues DROP CONSTRAINT IF EXISTS dues_property_id_fkey;
ALTER TABLE dues ADD CONSTRAINT dues_property_id_fkey 
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE;

ALTER TABLE dues DROP CONSTRAINT IF EXISTS dues_invoice_id_fkey;
ALTER TABLE dues ADD CONSTRAINT dues_invoice_id_fkey 
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE;

ALTER TABLE dues DROP CONSTRAINT IF EXISTS dues_payment_id_fkey;
ALTER TABLE dues ADD CONSTRAINT dues_payment_id_fkey 
    FOREIGN KEY (payment_id) REFERENCES payments(id);

ALTER TABLE dues DROP CONSTRAINT IF EXISTS dues_waived_by_fkey;
ALTER TABLE dues ADD CONSTRAINT dues_waived_by_fkey 
    FOREIGN KEY (waived_by) REFERENCES users(id);

-- Step 12: Update foreign key references in reports table
ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_caretaker_id_fkey;
ALTER TABLE reports ADD CONSTRAINT reports_caretaker_id_fkey 
    FOREIGN KEY (caretaker_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE reports DROP CONSTRAINT IF EXISTS reports_generated_by_fkey;
ALTER TABLE reports ADD CONSTRAINT reports_generated_by_fkey 
    FOREIGN KEY (generated_by) REFERENCES users(id);

-- Step 13: Update foreign key references in notifications table
ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;
ALTER TABLE notifications ADD CONSTRAINT notifications_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Step 14: Update views to use new table names
DROP VIEW IF EXISTS active_tenant_properties;
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

DROP VIEW IF EXISTS overdue_payments;
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

DROP VIEW IF EXISTS monthly_rent_summary;
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

-- Step 15: Create final indexes on renamed tables
-- User indexes
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

-- User roles indexes
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON user_roles(role);
CREATE INDEX IF NOT EXISTS idx_user_roles_active ON user_roles(is_active) WHERE is_active = TRUE;

-- Property indexes
CREATE INDEX IF NOT EXISTS idx_properties_caretaker ON properties(caretaker_id);
CREATE INDEX IF NOT EXISTS idx_properties_current_tenant ON properties(current_tenant_id);
CREATE INDEX IF NOT EXISTS idx_properties_status ON properties(status);
CREATE INDEX IF NOT EXISTS idx_properties_type ON properties(type);
CREATE INDEX IF NOT EXISTS idx_properties_city ON properties(city);
CREATE INDEX IF NOT EXISTS idx_properties_district ON properties(district);
CREATE INDEX IF NOT EXISTS idx_properties_division ON properties(division);
CREATE INDEX IF NOT EXISTS idx_properties_rent_amount ON properties(rent_amount);

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
CREATE INDEX IF NOT EXISTS idx_tenant_requests_tenant ON tenant_requests(tenant_id);
CREATE INDEX IF NOT EXISTS idx_tenant_requests_property ON tenant_requests(property_id);
CREATE INDEX IF NOT EXISTS idx_tenant_requests_caretaker ON tenant_requests(caretaker_id);
CREATE INDEX IF NOT EXISTS idx_tenant_requests_status ON tenant_requests(status);
CREATE INDEX IF NOT EXISTS idx_tenant_requests_requested_at ON tenant_requests(requested_at);

-- Invoice indexes
CREATE INDEX IF NOT EXISTS idx_invoices_property ON invoices(property_id);
CREATE INDEX IF NOT EXISTS idx_invoices_tenant ON invoices(tenant_id);
CREATE INDEX IF NOT EXISTS idx_invoices_caretaker ON invoices(caretaker_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_month_year ON invoices(month, year);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_number ON invoices(invoice_number);

-- Invoice fields indexes
CREATE INDEX IF NOT EXISTS idx_invoice_fields_invoice ON invoice_fields(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoice_fields_type ON invoice_fields(field_type);

-- Payment indexes
CREATE INDEX IF NOT EXISTS idx_payments_invoice ON payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_tenant ON payments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_payments_property ON payments(property_id);
CREATE INDEX IF NOT EXISTS idx_payments_caretaker ON payments(caretaker_id);
CREATE INDEX IF NOT EXISTS idx_payments_method ON payments(method);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);
CREATE INDEX IF NOT EXISTS idx_payments_paid_at ON payments(paid_at);

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

-- Step 16: Final verification
DO $$
DECLARE
    user_count INTEGER;
    property_count INTEGER;
    relationship_count INTEGER;
    invoice_count INTEGER;
BEGIN
    -- Count records in final tables
    SELECT COUNT(*) INTO user_count FROM users;
    SELECT COUNT(*) INTO property_count FROM properties;
    SELECT COUNT(*) INTO relationship_count FROM tenant_property_relationships;
    SELECT COUNT(*) INTO invoice_count FROM invoices;
    
    RAISE NOTICE 'Migration cleanup completed successfully!';
    RAISE NOTICE 'Final table counts:';
    RAISE NOTICE '  Users: %', user_count;
    RAISE NOTICE '  Properties: %', property_count;
    RAISE NOTICE '  Tenant-Property Relationships: %', relationship_count;
    RAISE NOTICE '  Invoices: %', invoice_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Old tables renamed to _old suffix for backup';
    RAISE NOTICE 'Backup tables with _backup suffix are available';
    RAISE NOTICE 'You can now drop the old tables if everything works correctly';
END $$;
