#!/bin/bash

# Baribhara Backend Setup Script
# This script sets up the development environment for Baribhara microservices

set -e

echo "🚀 Setting up Baribhara Backend Development Environment"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js 18+ from https://nodejs.org/"
        exit 1
    fi
    
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js version 18+ is required. Current version: $(node --version)"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker from https://docker.com/"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed. Please install Docker Compose from https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    print_success "All dependencies are installed"
}

# Create environment files
create_env_files() {
    print_status "Creating environment files..."
    
    # Create .env files for each service
    SERVICES=("api-gateway" "auth-service" "user-service" "property-service" "tenant-service" "invoice-service" "notification-service" "report-service" "admin-service")
    
    for service in "${SERVICES[@]}"; do
        if [ ! -f "services/$service/.env" ]; then
            cat > "services/$service/.env" << EOF
# Database Configuration
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_NAME=baribhara
DATABASE_USER=baribhara
DATABASE_PASSWORD=baribhara123

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRES_IN=24h
JWT_REFRESH_EXPIRES_IN=7d

# Service Configuration
NODE_ENV=development
PORT=3000

# Kafka Configuration
KAFKA_BROKERS=localhost:9092

# External Services
SENTRY_DSN=your-sentry-dsn
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=your-twilio-phone-number
EOF
            print_success "Created .env file for $service"
        else
            print_warning ".env file already exists for $service"
        fi
    done
}

# Install dependencies for all services
install_dependencies() {
    print_status "Installing dependencies for all services..."
    
    # Install shared types first
    print_status "Installing shared types..."
    cd shared/types
    npm install
    npm run build
    cd ../..
    
    # Install dependencies for each service
    SERVICES=("api-gateway" "auth-service" "user-service" "property-service" "tenant-service" "invoice-service" "notification-service" "report-service" "admin-service")
    
    for service in "${SERVICES[@]}"; do
        if [ -d "services/$service" ]; then
            print_status "Installing dependencies for $service..."
            cd "services/$service"
            npm install
            cd ../..
            print_success "Dependencies installed for $service"
        else
            print_warning "Service directory $service not found, skipping..."
        fi
    done
}

# Start infrastructure services
start_infrastructure() {
    print_status "Starting infrastructure services..."
    
    cd infrastructure
    docker-compose up -d postgres redis kafka zookeeper kong prometheus grafana jaeger consul nginx
    cd ..
    
    print_success "Infrastructure services started"
    print_status "Waiting for services to be ready..."
    sleep 30
}

# Build shared types
build_shared_types() {
    print_status "Building shared types..."
    cd shared/types
    npm run build
    cd ../..
    print_success "Shared types built successfully"
}

# Create database schema
create_database_schema() {
    print_status "Creating database schema..."
    
    # Wait for PostgreSQL to be ready
    print_status "Waiting for PostgreSQL to be ready..."
    until docker exec baribhara-postgres pg_isready -U baribhara; do
        sleep 2
    done
    
    # Create database schema (this would typically be done with migrations)
    print_success "Database is ready"
}

# Run health checks
run_health_checks() {
    print_status "Running health checks..."
    
    # Check PostgreSQL
    if docker exec baribhara-postgres pg_isready -U baribhara; then
        print_success "PostgreSQL is healthy"
    else
        print_error "PostgreSQL is not healthy"
    fi
    
    # Check Redis
    if docker exec baribhara-redis redis-cli ping | grep -q PONG; then
        print_success "Redis is healthy"
    else
        print_error "Redis is not healthy"
    fi
    
    # Check Kafka
    if docker exec baribhara-kafka kafka-topics --bootstrap-server localhost:9092 --list &> /dev/null; then
        print_success "Kafka is healthy"
    else
        print_error "Kafka is not healthy"
    fi
}

# Main setup function
main() {
    print_status "Starting Baribhara Backend Setup..."
    
    # Check if we're in the right directory
    if [ ! -f "backend/README.md" ]; then
        print_error "Please run this script from the Baribhara project root directory"
        exit 1
    fi
    
    cd backend
    
    check_dependencies
    create_env_files
    install_dependencies
    build_shared_types
    start_infrastructure
    create_database_schema
    run_health_checks
    
    print_success "🎉 Baribhara Backend setup completed successfully!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Start individual services with: npm run start:dev"
    print_status "2. Access API Gateway at: http://localhost:8000"
    print_status "3. Access Swagger docs at: http://localhost:8000/api/docs"
    print_status "4. Access Grafana at: http://localhost:3000 (admin/admin123)"
    print_status "5. Access Jaeger at: http://localhost:16686"
    print_status "6. Access Kong Admin at: http://localhost:8001"
    print_status ""
    print_status "For production deployment, see docs/DEPLOYMENT.md"
}

# Run main function
main "$@"
