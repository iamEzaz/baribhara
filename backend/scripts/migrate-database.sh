#!/bin/bash

# Baribhara Database Migration Script
# This script safely migrates from old schema to new comprehensive schema

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database connection parameters
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-baribhara}
DB_USER=${DB_USER:-root}

echo -e "${BLUE}🏠 Baribhara Database Migration Script${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Function to run SQL file
run_sql_file() {
    local file=$1
    local description=$2

    
    
    echo -e "${YELLOW}📄 Running: ${description}${NC}"
    echo -e "   File: ${file}"
    
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -f "$file"; then
        echo -e "${GREEN}✅ Success: ${description}${NC}"
    else
        echo -e "${RED}❌ Error: Failed to run ${description}${NC}"
        exit 1
    fi
    echo ""
}

# Function to check if database exists
check_database() {
    echo -e "${YELLOW}🔍 Checking database connection...${NC}"
    
    if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Database connection successful${NC}"
    else
        echo -e "${RED}❌ Error: Cannot connect to database${NC}"
        echo "Please check your database connection parameters:"
        echo "  DB_HOST: $DB_HOST"
        echo "  DB_PORT: $DB_PORT"
        echo "  DB_NAME: $DB_NAME"
        echo "  DB_USER: $DB_USER"
        exit 1
    fi
    echo ""
}

# Function to backup database
backup_database() {
    echo -e "${YELLOW}💾 Creating database backup...${NC}"
    
    local backup_file="baribhara_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if pg_dump -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME > "$backup_file"; then
        echo -e "${GREEN}✅ Database backup created: ${backup_file}${NC}"
    else
        echo -e "${RED}❌ Error: Failed to create database backup${NC}"
        exit 1
    fi
    echo ""
}

# Function to verify migration
verify_migration() {
    echo -e "${YELLOW}🔍 Verifying migration...${NC}"
    
    # Check if new tables exist
    local tables=("users" "user_roles" "properties" "tenant_property_relationships" "invoices" "payments")
    
    for table in "${tables[@]}"; do
        if psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c "SELECT 1 FROM $table LIMIT 1;" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Table $table exists${NC}"
        else
            echo -e "${RED}❌ Error: Table $table does not exist${NC}"
            exit 1
        fi
    done
    
    echo -e "${GREEN}✅ Migration verification successful${NC}"
    echo ""
}

# Main migration process
main() {
    echo -e "${BLUE}Starting migration process...${NC}"
    echo ""
    
    # Step 1: Check database connection
    check_database
    
    # Step 2: Create backup
    backup_database
    
    # Step 3: Run safe migration
    run_sql_file "database/migrations/003_safe_migration.sql" "Safe Migration (Step 1/2)"
    
    # Step 4: Verify migration
    verify_migration
    
    # Step 5: Ask for confirmation before cleanup
    echo -e "${YELLOW}⚠️  Migration completed successfully!${NC}"
    echo -e "${YELLOW}The new schema is now available with '_new' suffixes.${NC}"
    echo -e "${YELLOW}Old tables are preserved with '_backup' suffixes.${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Test your application with the new schema"
    echo "2. If everything works correctly, run the cleanup script:"
    echo "   ./scripts/migrate-database.sh cleanup"
    echo ""
    echo -e "${YELLOW}Do you want to proceed with cleanup now? (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        run_sql_file "database/migrations/004_cleanup_migration.sql" "Cleanup Migration (Step 2/2)"
        echo -e "${GREEN}🎉 Migration completed successfully!${NC}"
        echo -e "${GREEN}Your database now uses the new comprehensive schema.${NC}"
    else
        echo -e "${YELLOW}Migration paused. Run cleanup when ready.${NC}"
    fi
}

# Cleanup function
cleanup() {
    echo -e "${BLUE}🧹 Running cleanup migration...${NC}"
    echo ""
    
    check_database
    run_sql_file "database/migrations/004_cleanup_migration.sql" "Cleanup Migration"
    
    echo -e "${GREEN}🎉 Cleanup completed successfully!${NC}"
    echo -e "${GREEN}Your database now uses the new comprehensive schema.${NC}"
}

# Handle command line arguments
case "${1:-}" in
    "cleanup")
        cleanup
        ;;
    "help"|"-h"|"--help")
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no command)  Run full migration process"
        echo "  cleanup       Run cleanup migration only"
        echo "  help          Show this help message"
        echo ""
        echo "Environment variables:"
        echo "  DB_HOST       Database host (default: localhost)"
        echo "  DB_PORT       Database port (default: 5432)"
        echo "  DB_NAME       Database name (default: baribhara)"
        echo "  DB_USER       Database user (default: postgres)"
        echo ""
        echo "Example:"
        echo "  DB_HOST=localhost DB_NAME=baribhara $0"
        ;;
    "")
        main
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac
