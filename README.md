#Copyright (c) 2025 Ezazul Islam

##Baribhara -- 0ur taregetted market is Bangladesh.

Our system's Tech stack:

1. web based super Admin panel for admin to moniotor and control all the user. [Vue]
2. web based user panel [React] and mobile app [Flutter] for each user.
3. Microservice Server [Nest js, go, laravel, rust]
4. Postgres database and reddis for session, caching.
5. Restful API for server to client communication
6. JWT and RBAC for authentication and authorization
7. Swagger for documentation
8. Prometheus and grafana for monitoring and visualization
9. Docker and Kubernetese for Containers
10. Grpc for server to server communication
11. AWS for Deployment
12. Github action for CI/CD
13. Webhook for live notification and payment.
14. Jaeger for tracing platform designed to monitor and troubleshoot microservices.
15. Unit Testing and Database migration
16. Kafka for live messaging
17. Nginx for reverse proxy and traffic handling
18. Sentry for error tracking 


Features:

1. This app can manage property and tenant for caretaker. 
After logging in to the system a user can act as both tenant and caretaker at the same time. Because a caretaker can be a tenant of another caretaker. So the entire app's flow should be organized that way. 

2. For registration Name, Phone Number, National ID(optional) , Email(optional) and password require. For login email/phone and password needed.

3. For each property there can be multiple caretaker but one tenant only at a time. tenant can't see the info of the previous tenant but caretaker can.
 
4. In the Caretaker option: caretaker can add property with details. caretaker can add tenant by phone number and tenant will get notification. If tenants accept then tenants will able to see the details of that property.

4.1. There should be proper rent management system. Caretaker can add create invoice based on months. Common fields are: Rent, gas, water, electric, parking, service etc but user can add or delete fields.

4.2 Tenants are replaceable. So there should be proper tenant management for each property so that user can have records of previous Tenants.

4.3 New Tenants can track month's from the month they have joined.

4.4 There should be proper due management system.

4.5 Caretaker can track each month's progress.

4.6 Once the invoice is marked as paid it can't be edited.

4.7 Report creation filter based on months, year, date, tenant, property, fields(rent, gas, water, electric, parking, service etc but user can add or delete fields).

4.8 Invoice can be sent to tenant by email, sms or share in whatsapp from Baribhara APP.

5. Tenants can also send request for each property by unique id or name and if the caretaker accepts then tenants can see the details. Tenant can see the progress of property each month and download invoices and track them. After the payment tenant will be able to share the bkash, nagad or bank's transection number in property each month.

6. Superadmin can literally do anything technically possible for giving all the user extensive support and solve the problem.

#Architecture

backend/
├── services/
│   ├── nest-services/          # Single NestJS app
│   │   ├── src/
│   │   │   ├── modules/        # All modules here
│   │   │   │   ├── auth/
│   │   │   │   ├── user/
│   │   │   │   └── ...
│   │   │   ├── app.module.ts
│   │   │   └── main.ts
│   │   ├── package.json
│   │   └── Dockerfile
│   └── api-gateway/            # Go API Gateway
├── shared/                     # Use existing shared folder
│   ├── types/                  # Shared types for all services
│   ├── logger/                 # Shared logging utilities
│   └── proto/                  # gRPC definitions
├── infrastructure/             # Docker compose, etc.
└── database/                   # Database migrations