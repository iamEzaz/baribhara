-- Baribhara Database Cleanup Script
-- Migration 005: Remove old and backup tables after successful migration

-- This script removes all old and backup tables that are no longer needed
-- after the successful migration to the new comprehensive schema

-- Step 1: Verify current state
DO $$
BEGIN
    RAISE NOTICE 'Starting cleanup of old and backup tables...';
    RAISE NOTICE 'Current time: %', NOW();
END $$;

-- Step 2: Drop old tables (renamed during migration)
DROP TABLE IF EXISTS users_old CASCADE;
DROP TABLE IF EXISTS properties_old CASCADE;
DROP TABLE IF EXISTS tenants_old CASCADE;
DROP TABLE IF EXISTS invoices_old CASCADE;
DROP TABLE IF EXISTS invoice_fields_old CASCADE;
DROP TABLE IF EXISTS payments_old CASCADE;
DROP TABLE IF EXISTS tenant_requests_old CASCADE;

-- Step 3: Drop backup tables (created during migration)
DROP TABLE IF EXISTS users_backup CASCADE;
DROP TABLE IF EXISTS properties_backup CASCADE;
DROP TABLE IF EXISTS tenants_backup CASCADE;
DROP TABLE IF EXISTS invoices_backup CASCADE;
DROP TABLE IF EXISTS invoice_fields_backup CASCADE;
DROP TABLE IF EXISTS payments_backup CASCADE;
DROP TABLE IF EXISTS tenant_requests_backup CASCADE;

-- Step 4: Drop any remaining _new tables (if they exist)
DROP TABLE IF EXISTS users_new CASCADE;
DROP TABLE IF EXISTS properties_new CASCADE;
DROP TABLE IF EXISTS tenants_new CASCADE;
DROP TABLE IF EXISTS invoices_new CASCADE;
DROP TABLE IF EXISTS invoice_fields_new CASCADE;
DROP TABLE IF EXISTS payments_new CASCADE;
DROP TABLE IF EXISTS tenant_requests_new CASCADE;

-- Step 5: Verify cleanup
DO $$
DECLARE
    table_count INTEGER;
    old_table_count INTEGER;
BEGIN
    -- Count remaining tables
    SELECT COUNT(*) INTO table_count 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE';
    
    -- Count any remaining old/backup tables
    SELECT COUNT(*) INTO old_table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
    AND (table_name LIKE '%_old' OR table_name LIKE '%_backup' OR table_name LIKE '%_new');
    
    RAISE NOTICE 'Cleanup completed successfully!';
    RAISE NOTICE 'Total tables remaining: %', table_count;
    RAISE NOTICE 'Old/backup tables remaining: %', old_table_count;
    
    IF old_table_count = 0 THEN
        RAISE NOTICE '✅ All old and backup tables have been removed!';
    ELSE
        RAISE NOTICE '⚠️  Some old tables may still exist. Check manually.';
    END IF;
END $$;

-- Step 6: Show final table list
SELECT 
    'Final Database Tables:' as status,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name;
