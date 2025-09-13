# Baribhara Deployment Guide

## Overview

This guide covers the deployment of Baribhara microservices architecture across different environments (development, staging, production).

## Prerequisites

### Development Environment
- Node.js 18+
- Docker and Docker Compose
- Git
- Code editor (VS Code recommended)

### Production Environment
- AWS Account
- Kubernetes cluster (EKS recommended)
- Terraform (for infrastructure)
- kubectl
- Helm
- AWS CLI configured

## Local Development Setup

### 1. Clone Repository
```bash
git clone <repository-url>
cd Baribhara/backend
```

### 2. Run Setup Script
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

### 3. Start Individual Services
```bash
# Start API Gateway
cd services/api-gateway
npm run start:dev

# Start Auth Service (in new terminal)
cd services/auth-service
npm run start:dev

# Continue for other services...
```

### 4. Access Services
- API Gateway: http://localhost:8000
- Swagger Docs: http://localhost:8000/api/docs
- Grafana: http://localhost:3000 (admin/admin123)
- Jaeger: http://localhost:16686
- Kong Admin: http://localhost:8001

## Docker Deployment

### 1. Build Images
```bash
# Build all service images
docker-compose -f infrastructure/docker-compose.yml build

# Or build individual services
docker build -t baribhara/api-gateway:latest services/api-gateway/
docker build -t baribhara/auth-service:latest services/auth-service/
# ... continue for other services
```

### 2. Start All Services
```bash
docker-compose -f infrastructure/docker-compose.yml up -d
```

### 3. Check Service Status
```bash
docker-compose -f infrastructure/docker-compose.yml ps
```

## Kubernetes Deployment

### 1. Infrastructure Setup

#### Using Terraform
```bash
cd infrastructure/terraform
terraform init
terraform plan
terraform apply
```

#### Manual Setup
```bash
# Create EKS cluster
eksctl create cluster --name baribhara-production --region ap-southeast-1 --nodes 3 --node-type t3.medium

# Update kubeconfig
aws eks update-kubeconfig --region ap-southeast-1 --name baribhara-production
```

### 2. Deploy Infrastructure
```bash
# Create namespace
kubectl apply -f deployment/kubernetes/namespace.yml

# Deploy databases
kubectl apply -f deployment/kubernetes/postgres-deployment.yml
kubectl apply -f deployment/kubernetes/redis-deployment.yml

# Deploy message queue
kubectl apply -f deployment/kubernetes/kafka-deployment.yml

# Deploy monitoring
kubectl apply -f deployment/kubernetes/monitoring/
```

### 3. Deploy Services
```bash
# Deploy all services
kubectl apply -f deployment/kubernetes/

# Check deployment status
kubectl get pods -n baribhara
kubectl get services -n baribhara
```

### 4. Configure Ingress
```bash
# Deploy ingress controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/aws/deploy.yaml

# Deploy ingress
kubectl apply -f deployment/kubernetes/ingress.yml
```

## AWS Deployment

### 1. EKS Cluster Setup
```bash
# Create cluster
eksctl create cluster \
  --name baribhara-production \
  --region ap-southeast-1 \
  --version 1.27 \
  --nodegroup-name workers \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 1 \
  --nodes-max 5 \
  --managed
```

### 2. RDS Database Setup
```bash
# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier baribhara-postgres \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username baribhara \
  --master-user-password baribhara123 \
  --allocated-storage 20 \
  --vpc-security-group-ids sg-xxxxxxxxx
```

### 3. ElastiCache Redis Setup
```bash
# Create Redis cluster
aws elasticache create-cache-cluster \
  --cache-cluster-id baribhara-redis \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --num-cache-nodes 1
```

### 4. MSK Kafka Setup
```bash
# Create MSK cluster
aws kafka create-cluster \
  --cluster-name baribhara-kafka \
  --broker-node-group-info BrokerAZDistribution=SINGLE_AZ,ClientSubnets=subnet-xxxxxxxxx,InstanceType=kafka.t3.small \
  --kafka-version 2.8.1 \
  --number-of-broker-nodes 1
```

## CI/CD Pipeline

### 1. GitHub Actions Setup
The CI/CD pipeline is configured in `.github/workflows/ci-cd.yml` and includes:

- **Test Stage**: Runs unit tests, integration tests, and linting
- **Build Stage**: Builds Docker images for all services
- **Security Scan**: Scans images for vulnerabilities
- **Deploy Staging**: Automatic deployment to staging environment
- **Deploy Production**: Manual approval required for production

### 2. Environment Variables
Configure the following secrets in GitHub:

```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
DOCKER_USERNAME
DOCKER_PASSWORD
SENTRY_DSN
SMTP_PASSWORD
TWILIO_AUTH_TOKEN
WHATSAPP_TOKEN
```

### 3. Manual Deployment
```bash
# Deploy to staging
git push origin develop

# Deploy to production
git push origin main
```

## Monitoring and Observability

### 1. Prometheus Setup
```bash
# Deploy Prometheus
kubectl apply -f monitoring/prometheus/

# Access Prometheus UI
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
```

### 2. Grafana Setup
```bash
# Deploy Grafana
kubectl apply -f monitoring/grafana/

# Access Grafana UI
kubectl port-forward svc/grafana 3000:3000 -n monitoring
# Default credentials: admin/admin123
```

### 3. Jaeger Setup
```bash
# Deploy Jaeger
kubectl apply -f monitoring/jaeger/

# Access Jaeger UI
kubectl port-forward svc/jaeger 16686:16686 -n monitoring
```

## Database Migrations

### 1. Run Migrations
```bash
# For each service
cd services/auth-service
npm run migration:run

cd ../user-service
npm run migration:run

# Continue for other services...
```

### 2. Rollback Migrations
```bash
# Rollback last migration
npm run migration:revert

# Rollback all migrations
npm run migration:revert:all
```

## Backup and Recovery

### 1. Database Backup
```bash
# PostgreSQL backup
pg_dump -h localhost -U baribhara baribhara > backup_$(date +%Y%m%d_%H%M%S).sql

# Restore from backup
psql -h localhost -U baribhara baribhara < backup_20231201_120000.sql
```

### 2. Redis Backup
```bash
# Redis backup
redis-cli --rdb backup_$(date +%Y%m%d_%H%M%S).rdb

# Restore from backup
redis-cli --pipe < backup_20231201_120000.rdb
```

## Troubleshooting

### Common Issues

#### 1. Service Not Starting
```bash
# Check logs
kubectl logs -f deployment/api-gateway -n baribhara

# Check service status
kubectl get pods -n baribhara
kubectl describe pod <pod-name> -n baribhara
```

#### 2. Database Connection Issues
```bash
# Check database connectivity
kubectl exec -it <postgres-pod> -n baribhara -- psql -U baribhara -d baribhara

# Check network policies
kubectl get networkpolicies -n baribhara
```

#### 3. High Memory Usage
```bash
# Check resource usage
kubectl top pods -n baribhara

# Scale up if needed
kubectl scale deployment api-gateway --replicas=3 -n baribhara
```

### Log Analysis
```bash
# View logs from all services
kubectl logs -f -l app=baribhara -n baribhara

# View logs from specific service
kubectl logs -f deployment/auth-service -n baribhara

# View logs with timestamps
kubectl logs -f deployment/api-gateway -n baribhara --timestamps
```

## Security Considerations

### 1. Secrets Management
- Use Kubernetes secrets for sensitive data
- Rotate secrets regularly
- Use external secret management (AWS Secrets Manager)

### 2. Network Security
- Implement network policies
- Use service mesh (Istio) for mTLS
- Configure firewall rules

### 3. Access Control
- Implement RBAC for Kubernetes
- Use IAM roles for AWS resources
- Regular access reviews

## Performance Optimization

### 1. Resource Optimization
```bash
# Set resource limits
kubectl patch deployment api-gateway -n baribhara -p '{"spec":{"template":{"spec":{"containers":[{"name":"api-gateway","resources":{"limits":{"memory":"512Mi","cpu":"500m"}}}]}}}}'
```

### 2. Horizontal Pod Autoscaling
```bash
# Create HPA
kubectl autoscale deployment api-gateway --cpu-percent=70 --min=2 --max=10 -n baribhara
```

### 3. Database Optimization
- Use read replicas for read-heavy workloads
- Implement connection pooling
- Optimize queries and indexes

## Maintenance

### 1. Regular Updates
- Update base images regularly
- Apply security patches
- Update dependencies

### 2. Health Checks
- Monitor service health
- Set up alerting
- Regular backup verification

### 3. Capacity Planning
- Monitor resource usage
- Plan for scaling
- Regular performance testing

## Support

For additional support:
- Check the troubleshooting section
- Review logs and metrics
- Contact the development team
- Create an issue in the repository
