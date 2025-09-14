-- Baribhara Database Optimizations for Modular Architecture
-- Migration 006: Optimize database for single NestJS app with modules

-- This migration optimizes the database for the new modular architecture
-- where all business logic is in a single NestJS application

-- Step 1: Add module-specific indexes for better performance
DO $$
BEGIN
    RAISE NOTICE 'Starting modular architecture optimizations...';
    RAISE NOTICE 'Current time: %', NOW();
END $$;

-- Step 2: Add indexes for module-specific queries
-- Auth Module optimizations
CREATE INDEX IF NOT EXISTS idx_users_phone_email ON users(phone_number, email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_user_roles_active ON user_roles(user_id, is_active) WHERE is_active = true;

-- Property Module optimizations
CREATE INDEX IF NOT EXISTS idx_properties_caretaker ON properties(caretaker_id);
CREATE INDEX IF NOT EXISTS idx_properties_city ON properties(city);
CREATE INDEX IF NOT EXISTS idx_properties_status ON properties(status);

-- Tenant Module optimizations
CREATE INDEX IF NOT EXISTS idx_tenant_relationships_active ON tenant_property_relationships(tenant_id, status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_tenant_relationships_caretaker ON tenant_property_relationships(caretaker_id, status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_tenant_requests_status ON tenant_requests(status);

-- Invoice Module optimizations
CREATE INDEX IF NOT EXISTS idx_invoices_tenant ON invoices(tenant_id);
CREATE INDEX IF NOT EXISTS idx_invoices_caretaker ON invoices(caretaker_id);
CREATE INDEX IF NOT EXISTS idx_invoices_property ON invoices(property_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_due_date ON invoices(due_date);
CREATE INDEX IF NOT EXISTS idx_payments_invoice ON payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_tenant ON payments(tenant_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);

-- Dashboard Module optimizations
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(user_id, read_at) WHERE read_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_reports_user ON reports(user_id);
CREATE INDEX IF NOT EXISTS idx_reports_type ON reports(report_type);

-- Step 3: Add composite indexes for common module queries
-- Auth + User modules
CREATE INDEX IF NOT EXISTS idx_users_roles_lookup ON users(id, status) INCLUDE (name, phone_number, email);

-- Property + Tenant modules
CREATE INDEX IF NOT EXISTS idx_property_tenant_lookup ON properties(id, caretaker_id) INCLUDE (name, city, rent_amount);

-- Invoice + Payment modules
CREATE INDEX IF NOT EXISTS idx_invoice_payment_lookup ON invoices(id, tenant_id, status) INCLUDE (total_amount, due_date);

-- Dashboard + Analytics modules
CREATE INDEX IF NOT EXISTS idx_dashboard_metrics ON invoices(created_at, status) INCLUDE (total_amount, tenant_id, property_id);

-- Step 4: Add partial indexes for better performance
-- Active relationships only
CREATE INDEX IF NOT EXISTS idx_active_relationships ON tenant_property_relationships(tenant_id, property_id) WHERE status = 'active';

-- Pending payments only
CREATE INDEX IF NOT EXISTS idx_pending_payments ON payments(tenant_id, status) WHERE status = 'pending';

-- Unread notifications only
CREATE INDEX IF NOT EXISTS idx_unread_notifications ON notifications(user_id, created_at) WHERE read_at IS NULL;

-- Step 5: Add indexes for time-based queries (common in dashboards)
CREATE INDEX IF NOT EXISTS idx_invoices_monthly ON invoices(EXTRACT(YEAR FROM created_at), EXTRACT(MONTH FROM created_at));
CREATE INDEX IF NOT EXISTS idx_payments_daily ON payments(EXTRACT(YEAR FROM paid_at), EXTRACT(MONTH FROM paid_at), EXTRACT(DAY FROM paid_at));

-- Step 6: Add indexes for text search (if using full-text search)
CREATE INDEX IF NOT EXISTS idx_properties_search ON properties USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '')));
CREATE INDEX IF NOT EXISTS idx_users_search ON users USING gin(to_tsvector('english', name || ' ' || COALESCE(email, '')));

-- Step 7: Add indexes for foreign key lookups (improve JOIN performance)
CREATE INDEX IF NOT EXISTS idx_invoice_fields_invoice ON invoice_fields(invoice_id);
CREATE INDEX IF NOT EXISTS idx_dues_invoice ON dues(invoice_id);
CREATE INDEX IF NOT EXISTS idx_property_templates_property ON property_field_templates(property_id);

-- Step 8: Add indexes for audit and reporting queries
CREATE INDEX IF NOT EXISTS idx_audit_created ON users(created_at);
CREATE INDEX IF NOT EXISTS idx_audit_updated ON users(updated_at);
CREATE INDEX IF NOT EXISTS idx_payment_audit ON payments(paid_at, status);

-- Step 9: Add indexes for module-specific business logic
-- Caretaker module: Properties owned by user
CREATE INDEX IF NOT EXISTS idx_caretaker_properties ON properties(caretaker_id, status) INCLUDE (name, rent_amount);

-- Tenant module: Properties rented by user
CREATE INDEX IF NOT EXISTS idx_tenant_properties ON tenant_property_relationships(tenant_id, status) INCLUDE (property_id, monthly_rent);

-- Admin module: System-wide queries
CREATE INDEX IF NOT EXISTS idx_admin_users ON users(created_at, status);
CREATE INDEX IF NOT EXISTS idx_admin_properties ON properties(created_at, status);

-- Step 10: Add indexes for notification and communication modules
CREATE INDEX IF NOT EXISTS idx_notifications_priority ON notifications(priority, created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type, user_id);

-- Step 11: Add indexes for report generation
CREATE INDEX IF NOT EXISTS idx_reports_date_range ON reports(created_at, report_type);
CREATE INDEX IF NOT EXISTS idx_reports_user_type ON reports(user_id, report_type, created_at);

-- Step 12: Add indexes for due management
CREATE INDEX IF NOT EXISTS idx_dues_outstanding ON dues(status, due_date) WHERE status = 'outstanding';
CREATE INDEX IF NOT EXISTS idx_dues_tenant ON dues(tenant_id, status) WHERE status = 'outstanding';

-- Step 13: Add indexes for property field templates
CREATE INDEX IF NOT EXISTS idx_templates_property_active ON property_field_templates(property_id, is_active) WHERE is_active = true;

-- Step 14: Add indexes for tenant requests
CREATE INDEX IF NOT EXISTS idx_requests_caretaker ON tenant_requests(caretaker_id, status);
CREATE INDEX IF NOT EXISTS idx_requests_tenant ON tenant_requests(tenant_id, status);

-- Step 15: Add indexes for payment method queries (Bangladesh-specific)
CREATE INDEX IF NOT EXISTS idx_payments_bkash ON payments(bkash_number) WHERE bkash_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payments_nagad ON payments(nagad_number) WHERE nagad_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payments_rocket ON payments(rocket_number) WHERE rocket_number IS NOT NULL;

-- Step 16: Add indexes for financial reporting
CREATE INDEX IF NOT EXISTS idx_financial_monthly ON invoices(EXTRACT(YEAR FROM created_at), EXTRACT(MONTH FROM created_at), status);
CREATE INDEX IF NOT EXISTS idx_financial_yearly ON invoices(EXTRACT(YEAR FROM created_at), status);

-- Step 17: Add indexes for user activity tracking
CREATE INDEX IF NOT EXISTS idx_user_activity ON users(last_login_at) WHERE last_login_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_user_verification ON users(is_email_verified, is_phone_verified);

-- Step 18: Add indexes for property search and filtering
CREATE INDEX IF NOT EXISTS idx_property_location ON properties(city, area);
CREATE INDEX IF NOT EXISTS idx_property_rent_range ON properties(rent_amount) WHERE status = 'available';
CREATE INDEX IF NOT EXISTS idx_property_type ON properties(property_type, status);

-- Step 19: Add indexes for invoice generation and management
CREATE INDEX IF NOT EXISTS idx_invoice_generation ON invoices(property_id, EXTRACT(YEAR FROM created_at), EXTRACT(MONTH FROM created_at));
CREATE INDEX IF NOT EXISTS idx_invoice_overdue ON invoices(due_date, status) WHERE due_date < CURRENT_DATE AND status = 'pending';

-- Step 20: Add indexes for notification delivery
CREATE INDEX IF NOT EXISTS idx_notification_delivery ON notifications(user_id, delivery_status, created_at);
CREATE INDEX IF NOT EXISTS idx_notification_channels ON notifications(user_id, notification_channels);

-- Step 21: Add indexes for report caching and performance
CREATE INDEX IF NOT EXISTS idx_reports_cache ON reports(user_id, report_type, created_at) INCLUDE (report_data);
CREATE INDEX IF NOT EXISTS idx_reports_filters ON reports(report_filters, created_at);

-- Step 22: Add indexes for due management and collection
CREATE INDEX IF NOT EXISTS idx_dues_collection ON dues(caretaker_id, status, due_date);
CREATE INDEX IF NOT EXISTS idx_dues_escalation ON dues(due_date, status) WHERE due_date < CURRENT_DATE - INTERVAL '7 days';

-- Step 23: Add indexes for property maintenance and management
CREATE INDEX IF NOT EXISTS idx_property_maintenance ON properties(last_maintenance_date, status);
CREATE INDEX IF NOT EXISTS idx_property_occupancy ON properties(occupancy_status, status);

-- Step 24: Add indexes for user role management
CREATE INDEX IF NOT EXISTS idx_role_management ON user_roles(role, is_active, granted_at);
CREATE INDEX IF NOT EXISTS idx_role_expiry ON user_roles(expires_at) WHERE expires_at IS NOT NULL;

-- Step 25: Add indexes for audit trail and compliance
CREATE INDEX IF NOT EXISTS idx_audit_trail ON users(updated_at, status);
CREATE INDEX IF NOT EXISTS idx_payment_audit_trail ON payments(created_at, status, amount);

-- Step 26: Add indexes for module integration points
-- These indexes help with inter-module communication and data sharing
CREATE INDEX IF NOT EXISTS idx_module_integration ON users(id, status) INCLUDE (name, phone_number, email, created_at);
CREATE INDEX IF NOT EXISTS idx_property_integration ON properties(id, caretaker_id, status) INCLUDE (name, city, rent_amount, created_at);
CREATE INDEX IF NOT EXISTS idx_tenant_integration ON tenant_property_relationships(tenant_id, property_id, status) INCLUDE (monthly_rent, start_date, end_date);

-- Step 27: Add indexes for performance monitoring
CREATE INDEX IF NOT EXISTS idx_performance_monitoring ON invoices(created_at, status, total_amount);
CREATE INDEX IF NOT EXISTS idx_user_activity_monitoring ON users(last_login_at, status) WHERE last_login_at IS NOT NULL;

-- Step 28: Add indexes for data consistency checks
CREATE INDEX IF NOT EXISTS idx_consistency_checks ON users(id, status, created_at);
CREATE INDEX IF NOT EXISTS idx_property_consistency ON properties(id, caretaker_id, status, created_at);

-- Step 29: Add indexes for backup and recovery
CREATE INDEX IF NOT EXISTS idx_backup_recovery ON users(created_at, updated_at);
CREATE INDEX IF NOT EXISTS idx_critical_data ON invoices(id, tenant_id, property_id, created_at);

-- Step 30: Add indexes for module-specific business rules
-- These indexes support the specific business logic of each module
CREATE INDEX IF NOT EXISTS idx_auth_module ON users(phone_number, email, status) INCLUDE (id, name, password_hash);
CREATE INDEX IF NOT EXISTS idx_user_module ON users(id, status) INCLUDE (name, phone_number, email, created_at, last_login_at);
CREATE INDEX IF NOT EXISTS idx_property_module ON properties(id, caretaker_id, status) INCLUDE (name, city, rent_amount, property_type);
CREATE INDEX IF NOT EXISTS idx_tenant_module ON tenant_property_relationships(tenant_id, property_id, status) INCLUDE (monthly_rent, start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_invoice_module ON invoices(id, tenant_id, property_id, status) INCLUDE (total_amount, due_date, created_at);
CREATE INDEX IF NOT EXISTS idx_dashboard_module ON invoices(created_at, status) INCLUDE (total_amount, tenant_id, property_id);
CREATE INDEX IF NOT EXISTS idx_notification_module ON notifications(user_id, type, status) INCLUDE (title, message, created_at);
CREATE INDEX IF NOT EXISTS idx_report_module ON reports(user_id, report_type, created_at) INCLUDE (report_data, filters);
CREATE INDEX IF NOT EXISTS idx_admin_module ON users(created_at, status) INCLUDE (name, phone_number, email, last_login_at);
CREATE INDEX IF NOT EXISTS idx_caretaker_module ON properties(caretaker_id, status) INCLUDE (name, city, rent_amount, occupancy_status);

-- Step 31: Verify all indexes were created successfully
DO $$
DECLARE
    index_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO index_count 
    FROM pg_indexes 
    WHERE schemaname = 'public' 
    AND indexname LIKE 'idx_%';
    
    RAISE NOTICE 'Modular architecture optimizations completed successfully!';
    RAISE NOTICE 'Total indexes created: %', index_count;
    RAISE NOTICE 'Database is now optimized for modular architecture';
END $$;

-- Step 32: Show final index summary
SELECT 
    'Index Optimization Summary' as status,
    COUNT(*) as total_indexes,
    COUNT(CASE WHEN indexname LIKE 'idx_%' THEN 1 END) as modular_indexes
FROM pg_indexes 
WHERE schemaname = 'public';
