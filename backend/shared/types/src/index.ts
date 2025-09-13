// Entities
export * from './entities/user.entity';
export * from './entities/property.entity';
export * from './entities/tenant.entity';
export * from './entities/invoice.entity';
export * from './entities/caretaker.entity';
export * from './entities/tenant-property-relationship.entity';
export * from './entities/property-field-template.entity';
export * from './entities/tenant-request.entity';
export * from './entities/due.entity';

// Common
export * from './common/api-response';

// Enums
export enum ServiceName {
  API_GATEWAY = 'api-gateway',
  AUTH_SERVICE = 'auth-service',
  USER_SERVICE = 'user-service',
  PROPERTY_SERVICE = 'property-service',
  TENANT_SERVICE = 'tenant-service',
  INVOICE_SERVICE = 'invoice-service',
  NOTIFICATION_SERVICE = 'notification-service',
  REPORT_SERVICE = 'report-service',
  ADMIN_SERVICE = 'admin-service',
  CARETAKER_SERVICE = 'caretaker-service',
}

export enum EventType {
  USER_CREATED = 'user.created',
  USER_UPDATED = 'user.updated',
  USER_DELETED = 'user.deleted',
  PROPERTY_CREATED = 'property.created',
  PROPERTY_UPDATED = 'property.updated',
  PROPERTY_DELETED = 'property.deleted',
  TENANT_CREATED = 'tenant.created',
  TENANT_UPDATED = 'tenant.updated',
  TENANT_DELETED = 'tenant.deleted',
  INVOICE_CREATED = 'invoice.created',
  INVOICE_UPDATED = 'invoice.updated',
  INVOICE_PAID = 'invoice.paid',
  NOTIFICATION_SENT = 'notification.sent',
  CARETAKER_CREATED = 'caretaker.created',
  CARETAKER_UPDATED = 'caretaker.updated',
  CARETAKER_DELETED = 'caretaker.deleted',
  CARETAKER_VERIFIED = 'caretaker.verified',
  CARETAKER_SUSPENDED = 'caretaker.suspended',
  CARETAKER_ACTIVATED = 'caretaker.activated',
}

export interface BaseEvent {
  id: string;
  type: EventType;
  service: ServiceName;
  timestamp: Date;
  data: any;
  correlationId?: string;
}
