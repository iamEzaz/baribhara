# Baribhara Microservices Architecture

## Overview

Baribhara is a comprehensive property management system built with a microservices architecture, designed for scalability, maintainability, and high availability. The system serves the Bangladesh market with features for property management, tenant management, invoice processing, and comprehensive reporting.

## Architecture Principles

### 1. Domain-Driven Design (DDD)
Each microservice represents a distinct business domain:
- **Auth Service**: Authentication and authorization
- **User Service**: User profile management
- **Property Service**: Property management and listings
- **Tenant Service**: Tenant management and relationships
- **Invoice Service**: Billing and payment processing
- **Notification Service**: Multi-channel notifications
- **Report Service**: Analytics and reporting
- **Admin Service**: Super admin functionality

### 2. Event-Driven Architecture
Services communicate asynchronously using Apache Kafka for:
- Loose coupling between services
- Event sourcing for audit trails
- Real-time notifications
- Data consistency across services

### 3. API-First Design
- RESTful APIs for client communication
- gRPC for service-to-service communication
- OpenAPI/Swagger documentation
- Versioned APIs for backward compatibility

### 4. Container-First Approach
- Docker containers for all services
- Kubernetes for orchestration
- Helm charts for deployment management
- Multi-stage builds for optimized images

## Technology Stack

### Backend Services
- **NestJS (TypeScript)**: Primary framework for most services
- **Go**: High-performance services (report generation, file processing)
- **PHP**: Legacy integration services
- **Rust**: Performance-critical services (payment processing)

### Data Layer
- **PostgreSQL**: Primary database for transactional data
- **Redis**: Caching, session storage, and pub/sub
- **Apache Kafka**: Message streaming and event sourcing

### Infrastructure
- **Kong/Nginx**: API Gateway and load balancing
- **Istio**: Service mesh for traffic management
- **Consul**: Service discovery and configuration
- **Docker + Kubernetes**: Container orchestration

### Monitoring & Observability
- **Prometheus**: Metrics collection
- **Grafana**: Visualization and dashboards
- **Jaeger**: Distributed tracing
- **Sentry**: Error tracking and monitoring
- **ELK Stack**: Centralized logging

### Communication
- **REST APIs**: Client-to-service communication
- **gRPC**: Service-to-service communication
- **WebSockets**: Real-time updates
- **Kafka**: Event streaming

### Security
- **JWT**: Authentication tokens
- **RBAC**: Role-based access control
- **OAuth 2.0**: Third-party authentication
- **mTLS**: Service-to-service encryption

## Service Architecture

### API Gateway
- **Purpose**: Single entry point for all client requests
- **Responsibilities**:
  - Request routing and load balancing
  - Authentication and authorization
  - Rate limiting and throttling
  - Request/response transformation
  - API versioning
  - CORS handling

### Core Services

#### Auth Service
- **Port**: 3001 (HTTP), 50051 (gRPC)
- **Database**: PostgreSQL (users, roles, sessions)
- **Cache**: Redis (JWT tokens, session data)
- **Responsibilities**:
  - User authentication (login/logout)
  - JWT token management
  - Role-based access control
  - Password management
  - Session management

#### User Service
- **Port**: 3002 (HTTP), 50052 (gRPC)
- **Database**: PostgreSQL (user profiles)
- **Cache**: Redis (user data)
- **Responsibilities**:
  - User profile management
  - User registration
  - Profile updates
  - User search and discovery

#### Property Service
- **Port**: 3003 (HTTP), 50053 (gRPC)
- **Database**: PostgreSQL (properties, addresses)
- **Cache**: Redis (property listings)
- **Responsibilities**:
  - Property CRUD operations
  - Property search and filtering
  - Address management
  - Property images and documents
  - Property availability management

#### Tenant Service
- **Port**: 3004 (HTTP), 50054 (gRPC)
- **Database**: PostgreSQL (tenants, relationships)
- **Cache**: Redis (tenant data)
- **Responsibilities**:
  - Tenant management
  - Property-tenant relationships
  - Tenant requests and approvals
  - Contract management
  - Tenant history tracking

#### Invoice Service
- **Port**: 3005 (HTTP), 50055 (gRPC)
- **Database**: PostgreSQL (invoices, payments)
- **Cache**: Redis (invoice data)
- **Responsibilities**:
  - Invoice generation and management
  - Payment processing
  - Due date tracking
  - Payment method integration
  - Invoice templates and customization

#### Notification Service
- **Port**: 3006 (HTTP), 50056 (gRPC)
- **Database**: PostgreSQL (notification logs)
- **Cache**: Redis (notification queues)
- **Responsibilities**:
  - Email notifications (SMTP)
  - SMS notifications (Twilio)
  - WhatsApp notifications
  - Push notifications
  - Notification templates
  - Delivery tracking

#### Report Service
- **Port**: 3007 (HTTP), 50057 (gRPC)
- **Database**: PostgreSQL (report data)
- **Cache**: Redis (cached reports)
- **Responsibilities**:
  - Report generation
  - Data analytics
  - Export functionality (PDF, Excel)
  - Scheduled reports
  - Custom report builder

#### Admin Service
- **Port**: 3008 (HTTP), 50058 (gRPC)
- **Database**: PostgreSQL (admin data)
- **Cache**: Redis (admin cache)
- **Responsibilities**:
  - Super admin functions
  - System configuration
  - User management
  - System monitoring
  - Audit logging

## Data Flow

### 1. User Registration Flow
```
Client → API Gateway → Auth Service → User Service → Database
                    ↓
                Notification Service → Email/SMS
```

### 2. Property Management Flow
```
Client → API Gateway → Property Service → Database
                    ↓
                Event → Kafka → Tenant Service
```

### 3. Invoice Processing Flow
```
Invoice Service → Generate Invoice → Database
                ↓
            Event → Kafka → Notification Service → Email/SMS
```

### 4. Payment Processing Flow
```
Client → API Gateway → Invoice Service → Payment Gateway
                    ↓
                Event → Kafka → Notification Service
```

## Security Architecture

### Authentication Flow
1. User provides credentials to Auth Service
2. Auth Service validates credentials against database
3. JWT token generated and stored in Redis
4. Token returned to client with expiration
5. Subsequent requests include JWT in Authorization header

### Authorization Flow
1. API Gateway validates JWT token
2. User role and permissions extracted from token
3. Request forwarded to appropriate service
4. Service validates permissions for specific action
5. Action executed if authorized

### Data Protection
- All data encrypted in transit (TLS)
- Sensitive data encrypted at rest
- PII data masked in logs
- Regular security audits and penetration testing

## Deployment Architecture

### Development Environment
- Docker Compose for local development
- All services running in containers
- Local databases and message queues
- Hot reloading for development

### Staging Environment
- Kubernetes cluster on AWS EKS
- Production-like configuration
- Automated testing and validation
- Performance testing

### Production Environment
- Multi-AZ Kubernetes cluster
- Auto-scaling based on metrics
- Blue-green deployments
- Disaster recovery setup

## Monitoring and Observability

### Metrics Collection
- Application metrics via Prometheus
- Infrastructure metrics via Node Exporter
- Custom business metrics
- Real-time alerting

### Logging
- Centralized logging with ELK Stack
- Structured logging (JSON)
- Log aggregation and analysis
- Error tracking with Sentry

### Tracing
- Distributed tracing with Jaeger
- Request flow visualization
- Performance bottleneck identification
- Service dependency mapping

## Scalability Considerations

### Horizontal Scaling
- Stateless services for easy scaling
- Load balancing across multiple instances
- Database read replicas
- Caching strategies

### Performance Optimization
- Redis caching for frequently accessed data
- Database query optimization
- Connection pooling
- CDN for static assets

### High Availability
- Multi-AZ deployment
- Database clustering
- Message queue replication
- Circuit breakers and retries

## Development Guidelines

### Code Organization
- Monorepo structure for shared code
- Shared types and interfaces
- Common utilities and libraries
- Consistent coding standards

### Testing Strategy
- Unit tests for all services
- Integration tests for API endpoints
- End-to-end tests for critical flows
- Performance testing for scalability

### CI/CD Pipeline
- Automated testing on every commit
- Security scanning and vulnerability assessment
- Automated deployment to staging
- Manual approval for production deployment

## Future Enhancements

### Planned Features
- Machine learning for property recommendations
- Advanced analytics and insights
- Mobile app API optimization
- Third-party integrations

### Technical Improvements
- Service mesh implementation
- Event sourcing for audit trails
- CQRS for read/write separation
- GraphQL API layer

## Getting Started

### Prerequisites
- Node.js 18+
- Docker and Docker Compose
- Kubernetes cluster (for production)
- AWS account (for deployment)

### Local Development
1. Clone the repository
2. Run `docker-compose up` for infrastructure
3. Start individual services with `npm run start:dev`
4. Access services via API Gateway at `http://localhost:8000`

### Production Deployment
1. Configure AWS credentials
2. Deploy infrastructure with Terraform
3. Deploy services with Kubernetes
4. Configure monitoring and alerting

## Support and Maintenance

### Documentation
- API documentation via Swagger
- Architecture decision records
- Runbooks for operations
- Troubleshooting guides

### Monitoring
- 24/7 monitoring and alerting
- Performance dashboards
- Error tracking and resolution
- Capacity planning

### Maintenance
- Regular security updates
- Performance optimization
- Database maintenance
- Backup and recovery procedures
