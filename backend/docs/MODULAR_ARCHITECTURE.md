# 🏗️ Baribhara Modular Architecture

## **New Architecture Overview**

Baribhara now uses a **modular architecture** that combines the benefits of microservices with the simplicity of a monolith.

### **Architecture Components:**

```
Baribhara Backend
├── services/
│   ├── nest-services/          # Single NestJS app with all modules
│   │   ├── src/
│   │   │   ├── modules/        # All business logic as modules
│   │   │   │   ├── auth/       # Authentication & authorization
│   │   │   │   ├── user/       # User profile management
│   │   │   │   ├── property/   # Property management
│   │   │   │   ├── tenant/     # Tenant relationships
│   │   │   │   ├── invoice/    # Billing & payments
│   │   │   │   ├── notification/ # Multi-channel notifications
│   │   │   │   ├── report/     # Analytics & reporting
│   │   │   │   ├── admin/      # Super admin functions
│   │   │   │   ├── caretaker/  # Caretaker management
│   │   │   │   └── dashboard/  # Real-time dashboards
│   │   │   ├── app.module.ts   # Main app module
│   │   │   └── main.ts         # Application entry point
│   │   ├── package.json        # Single package.json
│   │   ├── Dockerfile
│   │   └── .env
│   └── api-gateway/            # Go API Gateway (unchanged)
│       ├── cmd/
│       ├── internal/
│       └── go.mod
├── shared/                     # Shared libraries (unchanged)
├── infrastructure/             # Docker compose (unchanged)
└── database/                   # Database migrations (unchanged)
```

## **🚀 Benefits of Modular Architecture**

### **✅ Development Benefits**
- **Single codebase** - All NestJS code in one place
- **Shared dependencies** - One `node_modules` folder
- **Easy debugging** - No service discovery complexity
- **Faster development** - No network calls between services
- **Hot reload** - Changes reflect immediately

### **✅ Deployment Benefits**
- **2 containers** instead of 11
- **Simpler CI/CD** - Build and deploy 2 services
- **Easier scaling** - Scale NestJS app as one unit
- **Better resource utilization**

### **✅ Maintenance Benefits**
- **Single package.json** to maintain
- **Single environment file** to manage
- **Easier dependency updates**
- **Simpler testing** - Test entire app as one unit

### **✅ Performance Benefits**
- **No network calls** between services
- **Faster response times**
- **Better resource utilization**
- **Easier caching** strategies

## **🔧 Service Ports**

| Service | Port | URL | Description |
|---------|------|-----|-------------|
| **NestJS Services** | 3000 | http://localhost:3000 | All modules in one app |
| **API Gateway** | 8080 | http://localhost:8080 | Entry point for all requests |
| **PostgreSQL** | 5432 | localhost:5432 | Database |
| **Redis** | 6379 | localhost:6379 | Cache & sessions |
| **Kafka** | 9092 | localhost:9092 | Message queue |

## **📦 Module Structure**

Each module follows the same structure:

```
modules/[module-name]/
├── [module-name].module.ts     # Module definition
├── [module-name].controller.ts # REST endpoints
├── [module-name].service.ts    # Business logic
├── entities/                   # Database entities
├── dto/                        # Data transfer objects
├── guards/                     # Authentication guards
└── strategies/                 # Passport strategies
```

## **🚀 Quick Start**

### **Option 1: Development Mode**
```bash
# Start all services
cd backend
./scripts/start-modular.sh start

# Check status
./scripts/start-modular.sh status

# Stop services
./scripts/start-modular.sh stop
```

### **Option 2: Docker Compose**
```bash
# Start with Docker
cd infrastructure
docker-compose -f docker-compose.modular.yml up -d

# Check status
docker-compose -f docker-compose.modular.yml ps
```

### **Option 3: Manual Start**
```bash
# Start NestJS services
cd services/nest-services
npm install
npm run start:dev

# Start API Gateway (in another terminal)
cd services/api-gateway
go run cmd/main.go
```

## **🔍 API Endpoints**

### **NestJS Services (Port 3000)**
- **Health Check**: `GET /health`
- **API Documentation**: `GET /api/docs`
- **Auth Module**: `POST /auth/login`, `POST /auth/register`
- **User Module**: `GET /users/profile`
- **Property Module**: `GET /properties`
- **Tenant Module**: `GET /tenants`
- **Invoice Module**: `GET /invoices`
- **Dashboard Module**: `GET /dashboard/overview`

### **API Gateway (Port 8080)**
- **Health Check**: `GET /health`
- **All Routes**: Routes to NestJS services
- **Load Balancing**: Distributes requests
- **Rate Limiting**: Protects against abuse

## **🛠️ Development Workflow**

### **1. Adding New Features**
```bash
# Create new module
cd services/nest-services/src/modules
mkdir new-feature
cd new-feature

# Create module files
touch new-feature.module.ts
touch new-feature.controller.ts
touch new-feature.service.ts
```

### **2. Database Changes**
```bash
# Create migration
cd database/migrations
touch 006_new_feature.sql

# Run migration
cd backend
./scripts/migrate-database.sh
```

### **3. Testing**
```bash
# Run all tests
cd services/nest-services
npm run test

# Run specific module tests
npm run test -- --testPathPattern=auth
```

## **📊 Monitoring & Observability**

### **Health Checks**
- **NestJS Services**: http://localhost:3000/health
- **API Gateway**: http://localhost:8080/health

### **API Documentation**
- **Swagger UI**: http://localhost:3000/api/docs

### **Monitoring**
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3001 (admin/admin123)

## **🔧 Configuration**

### **Environment Variables**
```env
# Database
DB_HOST=localhost
DB_PORT=5432
DB_USERNAME=root
DB_PASSWORD=password
DB_NAME=baribhara

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=24h

# Service
PORT=3000
NODE_ENV=development
```

## **🎯 Migration from Microservices**

### **What Changed:**
1. **11 separate services** → **1 NestJS app with modules**
2. **11 separate package.json** → **1 package.json**
3. **11 separate node_modules** → **1 node_modules**
4. **11 separate deployments** → **2 deployments**
5. **Service discovery** → **Direct module imports**

### **What Stayed the Same:**
1. **API Gateway** - Still Go, still port 8080
2. **Database** - Same PostgreSQL database
3. **Shared libraries** - Same shared folder
4. **API endpoints** - Same REST API structure
5. **Business logic** - Same functionality

## **🚀 Next Steps**

1. **Complete Module Implementation** - Finish all 10 modules
2. **Add Shared Services** - Database, Redis, Kafka modules
3. **Update API Gateway** - Point to NestJS services
4. **Add Testing** - Unit and integration tests
5. **Add Monitoring** - Metrics and logging
6. **Deploy to Production** - Use Docker Compose

---

**This modular architecture gives you the best of both worlds: the simplicity of a monolith with the modularity of microservices!** 🎉
