# Baribhara Database Migration Guide

## 🎯 **Migration Overview**

This guide will help you safely migrate from your existing database schema to the new comprehensive design that supports dual roles and Bangladesh market features.

## 📋 **What This Migration Does**

### **Before Migration (Old Schema)**
- Single role per user (tenant OR caretaker)
- Basic invoice system
- Limited payment methods
- Simple tenant-property relationships

### **After Migration (New Schema)**
- ✅ **Dual Role Support** - Users can be both tenant and caretaker
- ✅ **Historical Data** - Complete audit trail of all relationships
- ✅ **Flexible Rent Management** - Customizable invoice fields per property
- ✅ **Due Management** - Comprehensive payment tracking
- ✅ **Bangladesh Payment Methods** - bKash, Nagad, Rocket, Upaay
- ✅ **Enhanced Reporting** - Monthly, yearly, tenant, property reports
- ✅ **Notification System** - Email, SMS, WhatsApp integration

## 🚀 **Migration Process**

### **Step 1: Prerequisites**

1. **Backup Your Database** (Always!)
   ```bash
   pg_dump -h localhost -U postgres -d baribhara > baribhara_backup_$(date +%Y%m%d_%H%M%S).sql
   ```

2. **Check Database Connection**
   ```bash
   psql -h localhost -U postgres -d baribhara -c "SELECT 1;"
   ```

3. **Ensure You Have Required Extensions**
   ```sql
   CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
   CREATE EXTENSION IF NOT EXISTS "pg_trgm";
   ```

### **Step 2: Run Migration**

#### **Option A: Automated Migration (Recommended)**
```bash
cd /home/iamezaz/Code/Baribhara/backend
./scripts/migrate-database.sh
```

#### **Option B: Manual Migration**
```bash
# Step 1: Run safe migration
psql -h localhost -U postgres -d baribhara -f database/migrations/003_safe_migration.sql

# Step 2: Test your application

# Step 3: Run cleanup
psql -h localhost -U postgres -d baribhara -f database/migrations/004_cleanup_migration.sql
```

### **Step 3: Verify Migration**

After migration, verify these tables exist:
```sql
-- Check new tables
\dt

-- Verify data migration
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM user_roles;
SELECT COUNT(*) FROM properties;
SELECT COUNT(*) FROM tenant_property_relationships;
SELECT COUNT(*) FROM invoices;
```

## 📊 **Migration Details**

### **What Happens During Migration**

1. **Data Backup**: All existing data is backed up
2. **New Tables Created**: New schema tables with `_new` suffix
3. **Data Migration**: Existing data is migrated to new structure
4. **Role Conversion**: User roles are moved to separate `user_roles` table
5. **Relationship Mapping**: Tenant-property relationships are preserved
6. **Index Creation**: Performance indexes are created
7. **View Creation**: Common query views are created

### **Data Preservation**

- ✅ **All Users** - Migrated with role information
- ✅ **All Properties** - Migrated with full details
- ✅ **All Relationships** - Preserved in new structure
- ✅ **All Invoices** - Migrated with enhanced fields
- ✅ **All Payments** - Migrated with Bangladesh methods
- ✅ **All Requests** - Preserved with enhanced status

## 🔍 **Post-Migration Verification**

### **1. Check Table Structure**
```sql
-- Verify new tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'user_roles', 'properties', 'tenant_property_relationships', 'invoices', 'payments', 'dues');
```

### **2. Check Data Integrity**
```sql
-- Verify user roles
SELECT u.name, ur.role 
FROM users u 
JOIN user_roles ur ON u.id = ur.user_id 
WHERE ur.is_active = true;

-- Verify relationships
SELECT COUNT(*) FROM tenant_property_relationships;

-- Verify invoices
SELECT COUNT(*) FROM invoices;
```

### **3. Test Dual Role Functionality**
```sql
-- Find users with multiple roles
SELECT u.name, array_agg(ur.role) as roles
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
WHERE ur.is_active = true
GROUP BY u.id, u.name
HAVING COUNT(ur.role) > 1;
```

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **1. Migration Fails**
```bash
# Check database connection
psql -h localhost -U postgres -d baribhara -c "SELECT 1;"

# Check if tables exist
psql -h localhost -U postgres -d baribhara -c "\dt"

# Restore from backup if needed
psql -h localhost -U postgres -d baribhara < baribhara_backup_YYYYMMDD_HHMMSS.sql
```

#### **2. Data Not Migrated**
```sql
-- Check backup tables
SELECT COUNT(*) FROM users_backup;
SELECT COUNT(*) FROM properties_backup;
SELECT COUNT(*) FROM tenants_backup;

-- Check new tables
SELECT COUNT(*) FROM users_new;
SELECT COUNT(*) FROM properties_new;
SELECT COUNT(*) FROM tenant_property_relationships;
```

#### **3. Foreign Key Errors**
```sql
-- Check foreign key constraints
SELECT conname, conrelid::regclass, confrelid::regclass
FROM pg_constraint
WHERE contype = 'f';
```

### **Recovery Options**

#### **Option 1: Rollback to Old Schema**
```sql
-- Rename new tables back
ALTER TABLE users RENAME TO users_new;
ALTER TABLE users_old RENAME TO users;
-- Repeat for other tables...
```

#### **Option 2: Restore from Backup**
```bash
# Drop current database
dropdb -h localhost -U postgres baribhara

# Recreate database
createdb -h localhost -U postgres baribhara

# Restore from backup
psql -h localhost -U postgres -d baribhara < baribhara_backup_YYYYMMDD_HHMMSS.sql
```

## 📈 **Performance Considerations**

### **New Indexes Created**
- User lookups (phone, email, status)
- Property queries (caretaker, location, rent)
- Relationship queries (tenant-property combinations)
- Invoice queries (date ranges, status, amounts)

### **Views for Common Queries**
- `active_tenant_properties` - Pre-computed active relationships
- `overdue_payments` - Real-time overdue calculation
- `monthly_rent_summary` - Aggregated rent data

## 🔧 **Application Updates Required**

### **1. Update Entity Imports**
```typescript
// Old imports
import { User, Property, Tenant, Invoice } from '@baribhara/shared-types';

// New imports
import { 
  User, 
  UserRoleAssignment, 
  Property, 
  TenantPropertyRelationship, 
  Invoice, 
  Due,
  PropertyFieldTemplate 
} from '@baribhara/shared-types';
```

### **2. Update User Queries**
```typescript
// Old: Single role
const user = await userRepository.findOne({ where: { id, role: 'caretaker' } });

// New: Multiple roles
const user = await userRepository.findOne({ where: { id } });
const roles = await userRoleRepository.find({ where: { userId: id, isActive: true } });
```

### **3. Update Relationship Queries**
```typescript
// Old: Direct tenant-property relationship
const tenant = await tenantRepository.findOne({ where: { userId, propertyId } });

// New: Historical relationship tracking
const relationship = await relationshipRepository.findOne({ 
  where: { tenantId: userId, propertyId, status: 'active' } 
});
```

## ✅ **Migration Checklist**

- [ ] Database backup created
- [ ] Migration script executed
- [ ] Data verification completed
- [ ] Application updated for new schema
- [ ] Tests passing
- [ ] Performance verified
- [ ] Old tables cleaned up (optional)

## 🎉 **Benefits After Migration**

1. **Dual Role Support** - Users can be both tenant and caretaker
2. **Historical Data** - Complete audit trail of all relationships
3. **Flexible Rent Management** - Customizable invoice fields per property
4. **Due Management** - Comprehensive payment tracking and reminders
5. **Bangladesh Market** - Local payment methods and address structure
6. **Enhanced Reporting** - Detailed reports with filters
7. **Notification System** - Multi-channel communication
8. **Better Performance** - Optimized indexes and views

## 📞 **Support**

If you encounter any issues during migration:

1. Check the troubleshooting section above
2. Verify your database connection and permissions
3. Ensure all required extensions are installed
4. Check the migration logs for specific error messages

The migration is designed to be safe and reversible, with complete data preservation throughout the process.

---

**Happy Migrating! 🚀**
