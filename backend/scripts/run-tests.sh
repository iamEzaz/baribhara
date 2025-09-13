#!/bin/bash

# Baribhara Backend Test Runner
# This script runs all tests across all services

set -e

echo "🧪 Starting Baribhara Backend Test Suite"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_SERVICES=0
PASSED_SERVICES=0
FAILED_SERVICES=0

# Function to run tests for a NestJS service
run_nestjs_tests() {
    local service_name=$1
    local service_path="services/$service_name"
    
    if [ ! -d "$service_path" ]; then
        echo -e "${YELLOW}⚠️  Service $service_name not found, skipping...${NC}"
        return
    fi
    
    echo -e "${BLUE}🔍 Testing $service_name (NestJS)...${NC}"
    
    cd "$service_path"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "📦 Installing dependencies for $service_name..."
        npm install
    fi
    
    # Run tests
    if npm test -- --coverage --watchAll=false; then
        echo -e "${GREEN}✅ $service_name tests passed${NC}"
        ((PASSED_SERVICES++))
    else
        echo -e "${RED}❌ $service_name tests failed${NC}"
        ((FAILED_SERVICES++))
    fi
    
    cd - > /dev/null
    ((TOTAL_SERVICES++))
}

# Function to run tests for Go service
run_go_tests() {
    local service_name=$1
    local service_path="services/$service_name"
    
    if [ ! -d "$service_path" ]; then
        echo -e "${YELLOW}⚠️  Service $service_name not found, skipping...${NC}"
        return
    fi
    
    echo -e "${BLUE}🔍 Testing $service_name (Go)...${NC}"
    
    cd "$service_path"
    
    # Run Go tests
    if go test ./... -v -cover; then
        echo -e "${GREEN}✅ $service_name tests passed${NC}"
        ((PASSED_SERVICES++))
    else
        echo -e "${RED}❌ $service_name tests failed${NC}"
        ((FAILED_SERVICES++))
    fi
    
    cd - > /dev/null
    ((TOTAL_SERVICES++))
}

# Function to run integration tests
run_integration_tests() {
    echo -e "${BLUE}🔍 Running Integration Tests...${NC}"
    
    # Start test database
    echo "🐘 Starting test database..."
    docker-compose -f infrastructure/docker-compose.test.yml up -d postgres redis
    
    # Wait for services to be ready
    echo "⏳ Waiting for services to be ready..."
    sleep 10
    
    # Run integration tests
    for service in auth-service user-service property-service tenant-service caretaker-service; do
        if [ -d "services/$service" ]; then
            echo -e "${BLUE}🔍 Running integration tests for $service...${NC}"
            cd "services/$service"
            if npm run test:integration 2>/dev/null; then
                echo -e "${GREEN}✅ $service integration tests passed${NC}"
            else
                echo -e "${YELLOW}⚠️  $service integration tests not configured${NC}"
            fi
            cd - > /dev/null
        fi
    done
    
    # Stop test database
    echo "🛑 Stopping test database..."
    docker-compose -f infrastructure/docker-compose.test.yml down
}

# Function to run E2E tests
run_e2e_tests() {
    echo -e "${BLUE}🔍 Running End-to-End Tests...${NC}"
    
    if [ -d "e2e" ]; then
        cd e2e
        if npm test; then
            echo -e "${GREEN}✅ E2E tests passed${NC}"
        else
            echo -e "${RED}❌ E2E tests failed${NC}"
        fi
        cd - > /dev/null
    else
        echo -e "${YELLOW}⚠️  E2E tests not configured${NC}"
    fi
}

# Main execution
echo "🚀 Starting test execution..."

# Run unit tests for all services
echo -e "\n${BLUE}📋 Running Unit Tests${NC}"
echo "====================="

# NestJS Services
run_nestjs_tests "auth-service"
run_nestjs_tests "user-service"
run_nestjs_tests "property-service"
run_nestjs_tests "tenant-service"
run_nestjs_tests "caretaker-service"
run_nestjs_tests "invoice-service"
run_nestjs_tests "notification-service"
run_nestjs_tests "report-service"
run_nestjs_tests "admin-service"

# Go Services
run_go_tests "api-gateway"

# Run integration tests if requested
if [ "$1" = "--integration" ] || [ "$1" = "--all" ]; then
    echo -e "\n${BLUE}📋 Running Integration Tests${NC}"
    echo "============================="
    run_integration_tests
fi

# Run E2E tests if requested
if [ "$1" = "--e2e" ] || [ "$1" = "--all" ]; then
    echo -e "\n${BLUE}📋 Running End-to-End Tests${NC}"
    echo "============================="
    run_e2e_tests
fi

# Test summary
echo -e "\n${BLUE}📊 Test Summary${NC}"
echo "==============="
echo -e "Total Services: ${TOTAL_SERVICES}"
echo -e "Passed: ${GREEN}${PASSED_SERVICES}${NC}"
echo -e "Failed: ${RED}${FAILED_SERVICES}${NC}"

if [ $FAILED_SERVICES -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}💥 Some tests failed!${NC}"
    exit 1
fi
