# Baribhara Backend - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Prerequisites
- Node.js 18+
- Docker and Docker Compose
- Git

### 1. Clone and Setup
```bash
# Clone the repository
git clone <repository-url>
cd Baribhara/backend

# Make setup script executable
chmod +x scripts/setup.sh

# Run the automated setup
./scripts/setup.sh
```

### 2. Start Development Environment
```bash
# Start all infrastructure services
docker-compose -f infrastructure/docker-compose.yml up -d

# Start individual services (in separate terminals)
cd services/api-gateway && npm run start:dev
cd services/auth-service && npm run start:dev
cd services/user-service && npm run start:dev
# ... continue for other services
```

### 3. Access Your Services
- **API Gateway**: http://localhost:8000
- **Swagger Docs**: http://localhost:8000/api/docs
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Jaeger**: http://localhost:16686
- **Kong Admin**: http://localhost:8001

### 4. Test the API
```bash
# Register a new user
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "phoneNumber": "+8801000000000",
    "email": "john@example.com",
    "password": "password123"
  }'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "identifier": "john@example.com",
    "password": "password123"
  }'
```

## 🏗️ Architecture Overview

### Core Services
| Service | Port | Description |
|---------|------|-------------|
| API Gateway | 3000 | Entry point for all requests |
| Auth Service | 3001 | Authentication & authorization |
| User Service | 3002 | User profile management |
| Property Service | 3003 | Property management |
| Tenant Service | 3004 | Tenant relationships |
| Invoice Service | 3005 | Billing & payments |
| Notification Service | 3006 | Multi-channel notifications |
| Report Service | 3007 | Analytics & reporting |
| Admin Service | 3008 | Super admin functions |

### Technology Stack
- **Backend**: NestJS (TypeScript), Go, PHP, Rust
- **Database**: PostgreSQL + Redis
- **Message Queue**: Apache Kafka
- **API Gateway**: Kong
- **Monitoring**: Prometheus + Grafana
- **Tracing**: Jaeger
- **Containerization**: Docker + Kubernetes

## 📁 Project Structure

```
backend/
├── services/                    # 9 microservices
│   ├── api-gateway/            # API Gateway
│   ├── auth-service/           # Authentication
│   ├── user-service/           # User management
│   ├── property-service/       # Property management
│   ├── tenant-service/         # Tenant management
│   ├── invoice-service/        # Invoice & payments
│   ├── notification-service/   # Notifications
│   ├── report-service/         # Reports & analytics
│   └── admin-service/          # Super admin
├── shared/                     # Shared libraries
│   ├── types/                  # TypeScript types
│   ├── logger/                 # Logging service
│   └── proto/                  # gRPC definitions
├── infrastructure/             # Infrastructure
│   ├── docker-compose.yml      # Local development
│   ├── kong/                   # API Gateway config
│   └── init-scripts/           # Database setup
├── deployment/                 # Deployment configs
│   └── kubernetes/             # K8s manifests
├── monitoring/                 # Observability
│   ├── prometheus/             # Metrics
│   └── grafana/                # Dashboards
├── database/                   # Database
│   └── migrations/             # Schema migrations
└── docs/                       # Documentation
```

## 🔧 Development Workflow

### 1. Adding a New Feature
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes to relevant service
cd services/auth-service
# ... make changes ...

# Run tests
npm test

# Commit changes
git add .
git commit -m "feat: add new feature"

# Push and create PR
git push origin feature/new-feature
```

### 2. Running Tests
```bash
# Run all tests
npm test

# Run tests for specific service
cd services/auth-service
npm test

# Run e2e tests
npm run test:e2e

# Run with coverage
npm run test:cov
```

### 3. Database Migrations
```bash
# Generate migration
npm run migration:generate -- -n AddNewTable

# Run migrations
npm run migration:run

# Revert migration
npm run migration:revert
```

## 🚀 Deployment

### Local Development
```bash
# Start all services
docker-compose -f infrastructure/docker-compose.yml up -d

# Check service status
docker-compose -f infrastructure/docker-compose.yml ps
```

### Staging Environment
```bash
# Deploy to staging
kubectl apply -f deployment/kubernetes/namespace.yml
kubectl apply -f deployment/kubernetes/
```

### Production Environment
```bash
# Deploy to production
kubectl apply -f deployment/kubernetes/namespace.yml
kubectl apply -f deployment/kubernetes/
kubectl apply -f deployment/kubernetes/monitoring/
```

## 📊 Monitoring & Observability

### Metrics
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000 (admin/admin123)

### Logs
- **Service Logs**: Check individual service logs
- **Centralized Logging**: ELK Stack (production)

### Tracing
- **Jaeger**: http://localhost:16686

## 🔐 Security

### Authentication
- JWT tokens for API access
- Role-based access control (RBAC)
- Password hashing with bcrypt

### Data Protection
- Input validation and sanitization
- SQL injection prevention
- CORS configuration
- Rate limiting

## 🧪 Testing

### Test Types
- **Unit Tests**: Individual component testing
- **Integration Tests**: Service integration testing
- **E2E Tests**: Complete workflow testing
- **Performance Tests**: Load and stress testing

### Test Commands
```bash
# Run all tests
npm test

# Run specific test suite
npm run test:auth

# Run with coverage
npm run test:cov

# Run e2e tests
npm run test:e2e
```

## 📚 Documentation

### API Documentation
- **Swagger UI**: http://localhost:8000/api/docs
- **OpenAPI Spec**: Available in each service

### Architecture Documentation
- **Architecture Guide**: `docs/ARCHITECTURE.md`
- **Deployment Guide**: `docs/DEPLOYMENT.md`
- **Stability Checklist**: `STABILITY_CHECKLIST.md`

## 🤝 Contributing

### Code Standards
- TypeScript with strict mode
- ESLint and Prettier for code formatting
- Conventional commits for commit messages
- Comprehensive test coverage

### Pull Request Process
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 🆘 Troubleshooting

### Common Issues

#### Service Won't Start
```bash
# Check logs
docker-compose logs <service-name>

# Check service status
docker-compose ps
```

#### Database Connection Issues
```bash
# Check database status
docker-compose logs postgres

# Test connection
docker exec -it baribhara-postgres psql -U baribhara -d baribhara
```

#### Port Conflicts
```bash
# Check port usage
lsof -i :3000

# Kill process using port
kill -9 <PID>
```

### Getting Help
- Check the documentation in `docs/`
- Create an issue on GitHub
- Contact the development team

## 🎯 Next Steps

1. **Explore the Codebase**: Start with `services/api-gateway`
2. **Read the Documentation**: Check `docs/ARCHITECTURE.md`
3. **Run the Tests**: Ensure everything works
4. **Start Building**: Add your first feature
5. **Deploy**: Follow the deployment guide

---

**Happy Coding! 🚀**

For more detailed information, check the full documentation in the `docs/` folder.
