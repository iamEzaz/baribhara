#!/bin/bash

# Baribhara Modular Services Startup Script
# This script starts the modular architecture (NestJS + Go API Gateway)

set -e

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

# Function to check if port is available
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 1
    else
        return 0
    fi
}

# Function to start NestJS services
start_nest_services() {
    local nest_dir="../services/nest-services"
    
    print_status "Starting NestJS Services (All Modules)..."
    
    # Check if directory exists
    if [ ! -d "$nest_dir" ]; then
        print_error "NestJS services directory $nest_dir not found!"
        return 1
    fi
    
    # Check if port is available
    if ! check_port 3000; then
        print_warning "Port 3000 is already in use. Skipping NestJS services"
        return 1
    fi
    
    # Change to directory
    cd "$nest_dir"
    
    # Install dependencies if node_modules doesn't exist
    if [ ! -d "node_modules" ]; then
        print_status "Installing dependencies for NestJS services..."
        npm install
    fi
    
    # Start the services
    print_status "Starting NestJS services..."
    npm run start:dev &
    
    # Store the PID
    echo $! > "/tmp/baribhara_nest_services.pid"
    
    # Wait a moment for the service to start
    sleep 5
    
    # Check if service is running
    if check_port 3000; then
        print_error "Failed to start NestJS services on port 3000"
        return 1
    else
        print_success "NestJS services started successfully on port 3000"
    fi
    
    # Return to backend directory
    cd - > /dev/null
}

# Function to start API Gateway
start_api_gateway() {
    local gateway_dir="../services/api-gateway"
    
    print_status "Starting Go API Gateway..."
    
    # Check if directory exists
    if [ ! -d "$gateway_dir" ]; then
        print_error "API Gateway directory $gateway_dir not found!"
        return 1
    fi
    
    # Check if port is available
    if ! check_port 8080; then
        print_warning "Port 8080 is already in use. Skipping API Gateway"
        return 1
    fi
    
    # Change to directory
    cd "$gateway_dir"
    
    # Build if needed
    if [ ! -f "api-gateway" ]; then
        print_status "Building API Gateway..."
        go build -o api-gateway cmd/main.go
    fi
    
    # Start the gateway
    print_status "Starting API Gateway..."
    ./api-gateway &
    
    # Store the PID
    echo $! > "/tmp/baribhara_api_gateway.pid"
    
    # Wait a moment for the service to start
    sleep 3
    
    # Check if service is running
    if check_port 8080; then
        print_error "Failed to start API Gateway on port 8080"
        return 1
    else
        print_success "API Gateway started successfully on port 8080"
    fi
    
    # Return to backend directory
    cd - > /dev/null
}

# Function to stop all services
stop_services() {
    print_status "Stopping all Baribhara services..."
    
    # Stop API Gateway
    if [ -f "/tmp/baribhara_api_gateway.pid" ]; then
        local pid=$(cat /tmp/baribhara_api_gateway.pid)
        if kill -0 $pid 2>/dev/null; then
            kill $pid
            print_success "API Gateway stopped"
        fi
        rm -f /tmp/baribhara_api_gateway.pid
    fi
    
    # Stop NestJS services
    if [ -f "/tmp/baribhara_nest_services.pid" ]; then
        local pid=$(cat /tmp/baribhara_nest_services.pid)
        if kill -0 $pid 2>/dev/null; then
            kill $pid
            print_success "NestJS services stopped"
        fi
        rm -f /tmp/baribhara_nest_services.pid
    fi
}

# Function to show service status
show_status() {
    print_status "Baribhara Modular Services Status:"
    echo "========================================"
    
    # Check NestJS services
    if check_port 3000; then
        print_warning "NestJS Services - Port 3000 - NOT RUNNING"
    else
        print_success "NestJS Services - Port 3000 - RUNNING"
    fi
    
    # Check API Gateway
    if check_port 8080; then
        print_warning "API Gateway (Go) - Port 8080 - NOT RUNNING"
    else
        print_success "API Gateway (Go) - Port 8080 - RUNNING"
    fi
}

# Function to show help
show_help() {
    echo "Baribhara Modular Services Management Script"
    echo "============================================"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start     Start all services (NestJS + Go API Gateway)"
    echo "  stop      Stop all services"
    echo "  restart   Restart all services"
    echo "  status    Show service status"
    echo "  help      Show this help message"
    echo ""
    echo "Services:"
    echo "  NestJS Services (All Modules) - Port 3000"
    echo "  API Gateway (Go)              - Port 8080"
    echo ""
    echo "Examples:"
    echo "  $0 start    # Start all services"
    echo "  $0 status   # Check which services are running"
    echo "  $0 stop     # Stop all services"
}

# Main script logic
case "${1:-start}" in
    start)
        print_status "Starting Baribhara modular services..."
        echo "============================================="
        
        # Start NestJS services first
        start_nest_services
        
        # Start API Gateway
        start_api_gateway
        
        echo ""
        print_success "All services started! Use '$0 status' to check status."
        echo ""
        print_status "Service URLs:"
        echo "  NestJS Services: http://localhost:3000"
        echo "  API Gateway:     http://localhost:8080"
        echo "  API Docs:        http://localhost:3000/api/docs"
        echo "  Health Check:    http://localhost:3000/health"
        ;;
        
    stop)
        stop_services
        ;;
        
    restart)
        print_status "Restarting all services..."
        stop_services
        sleep 2
        $0 start
        ;;
        
    status)
        show_status
        ;;
        
    help)
        show_help
        ;;
        
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
