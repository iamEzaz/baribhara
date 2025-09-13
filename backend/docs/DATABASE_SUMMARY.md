# Baribhara Database Design Summary

## 🎯 **Key Design Challenge Solved**

**Problem**: Users can act as both **tenant** and **caretaker** simultaneously because a caretaker can be a tenant of another caretaker.

**Solution**: Implemented a **dual-role architecture** with separate role management and historical relationship tracking.

## 🏗️ **Architecture Overview**

### **Core Design Principles**
1. **Dual Role Support** - Users can have multiple active roles
2. **Historical Data** - Complete audit trail of all relationships
3. **Flexible Rent Management** - Customizable invoice fields per property
4. **Due Management** - Comprehensive payment tracking
5. **Bangladesh Market** - Local payment methods and address structure

## 📊 **Database Schema**

### **1. User Management**
```sql
users                    -- Central user registry
user_roles              -- Role assignments (supports multiple roles)
```

### **2. Property Management**
```sql
properties              -- Property information
property_field_templates -- Customizable invoice fields per property
```

### **3. Relationship Management**
```sql
tenant_property_relationships -- Historical tenant-property relationships
tenant_requests              -- Tenant requests and approvals
```

### **4. Financial Management**
```sql
invoices                -- Monthly rent invoices
invoice_fields          -- Individual line items
payments                -- Payment records (Bangladesh methods)
dues                    -- Due management and tracking
```

### **5. Communication & Reporting**
```sql
notifications           -- System notifications
reports                 -- Generated reports with filters
```

## 🔄 **Dual Role Implementation**

### **How It Works**
1. **User Registration**: User creates account in `users` table
2. **Role Assignment**: Roles assigned in `user_roles` table
3. **Multiple Roles**: User can have both 'tenant' and 'caretaker' roles
4. **Relationship Tracking**: `tenant_property_relationships` tracks all relationships
5. **Historical Data**: Complete history preserved even after relationship ends

### **Example Scenario**
```
User A (Ahmed) - Roles: [caretaker, tenant]
├── As Caretaker: Owns Property X, manages Tenant B
└── As Tenant: Rents Property Y from Caretaker C
```

## 💰 **Rent Management System**

### **Flexible Invoice Fields**
- **Fixed Fields**: Rent, parking (constant amount)
- **Variable Fields**: Gas, water, electric (varies monthly)
- **Percentage Fields**: Service charges (percentage of rent)
- **Custom Fields**: User-defined fields per property

### **Invoice Structure**
```
Invoice
├── Property Information
├── Tenant Information
├── Billing Period (month/year)
├── Fields (rent, gas, water, electric, parking, service, custom)
├── Total Amount
├── Due Date
└── Payment Status
```

## 🇧🇩 **Bangladesh Market Features**

### **Payment Methods**
- **Mobile Banking**: bKash, Nagad, Rocket, Upaay
- **Bank Transfer**: With branch information
- **Cash**: Physical payment
- **Check**: Traditional payment method

### **Address Structure**
```
Division → District → City → Street
Dhaka → Dhanmondi → Dhaka → House 123, Road 45
```

### **Currency & Formatting**
- **Primary Currency**: Taka (BDT)
- **Phone Numbers**: Bangladesh format (+880)
- **Postal Codes**: Local postal code system

## 📈 **Key Features Implemented**

### **1. Tenant Management**
- ✅ Multiple tenants per property (historical)
- ✅ Tenant requests by property code
- ✅ Contract management with start/end dates
- ✅ Security deposit tracking

### **2. Invoice System**
- ✅ Monthly invoice generation
- ✅ Customizable fields per property
- ✅ Due date management
- ✅ Late fee calculation
- ✅ Payment tracking

### **3. Due Management**
- ✅ Outstanding payment tracking
- ✅ Days overdue calculation
- ✅ Payment reminders
- ✅ Waiver management

### **4. Reporting**
- ✅ Monthly/yearly reports
- ✅ Tenant-specific reports
- ✅ Property-specific reports
- ✅ Custom filtered reports

### **5. Notifications**
- ✅ Email notifications
- ✅ SMS notifications
- ✅ WhatsApp integration
- ✅ Push notifications

## 🔍 **Query Examples**

### **Find User's Dual Roles**
```sql
SELECT u.name, ur.role
FROM users u
JOIN user_roles ur ON u.id = ur.user_id
WHERE u.id = $1 AND ur.is_active = TRUE;
```

### **Get User's Properties (as caretaker)**
```sql
SELECT p.* FROM properties p
WHERE p.caretaker_id = $1;
```

### **Get User's Rentals (as tenant)**
```sql
SELECT p.*, tpr.monthly_rent, tpr.contract_start_date
FROM properties p
JOIN tenant_property_relationships tpr ON p.id = tpr.property_id
WHERE tpr.tenant_id = $1 AND tpr.status = 'active';
```

### **Monthly Rent Summary**
```sql
SELECT 
    p.name as property_name,
    u.name as tenant_name,
    i.month, i.year, i.total_amount, i.status
FROM invoices i
JOIN properties p ON i.property_id = p.id
JOIN users u ON i.tenant_id = u.id
WHERE i.caretaker_id = $1 AND i.year = $2
ORDER BY i.month, p.name;
```

## 🚀 **Performance Optimizations**

### **Indexes**
- **User Lookups**: Phone, email, status
- **Property Queries**: Caretaker, location, rent range
- **Relationship Queries**: Tenant-property combinations
- **Invoice Queries**: Date ranges, status, amounts

### **Views**
- **Active Relationships**: Pre-computed active tenant-property pairs
- **Overdue Payments**: Real-time overdue calculation
- **Monthly Summary**: Aggregated rent data

## 📋 **Migration Strategy**

### **Phase 1: Core Tables**
1. Users and user roles
2. Properties and field templates
3. Tenant-property relationships

### **Phase 2: Financial System**
1. Invoices and invoice fields
2. Payments and dues
3. Due management

### **Phase 3: Communication**
1. Notifications
2. Reports
3. Integration features

## ✅ **Benefits of This Design**

### **1. Scalability**
- Supports unlimited users with dual roles
- Efficient queries with proper indexing
- Horizontal scaling ready

### **2. Flexibility**
- Customizable invoice fields per property
- Multiple payment methods
- Flexible reporting

### **3. Data Integrity**
- Foreign key constraints
- Check constraints for data validation
- Audit trail for all changes

### **4. Bangladesh Market Ready**
- Local payment methods
- Address structure
- Currency formatting

### **5. Business Logic Support**
- Complete tenant history
- Due management
- Invoice generation
- Payment tracking

## 🎯 **Next Steps**

1. **Implement Services**: Create NestJS services for each entity
2. **API Development**: Build RESTful APIs for all operations
3. **Testing**: Comprehensive unit and integration tests
4. **Documentation**: API documentation with Swagger
5. **Deployment**: Production-ready deployment configuration

This database design fully supports the complex dual-role requirement while providing a robust foundation for the Baribhara property management system! 🏠✨
