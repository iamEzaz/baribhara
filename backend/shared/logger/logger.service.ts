import { Injectable, LoggerService as NestLoggerService } from '@nestjs/common';
import * as winston from 'winston';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class LoggerService implements NestLoggerService {
  private logger: winston.Logger;

  constructor(private configService: ConfigService) {
    this.logger = winston.createLogger({
      level: this.configService.get('LOG_LEVEL', 'info'),
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json(),
        winston.format.printf(({ timestamp, level, message, context, trace, ...meta }) => {
          return JSON.stringify({
            timestamp,
            level,
            message,
            context,
            trace,
            ...meta,
          });
        }),
      ),
      defaultMeta: {
        service: 'baribhara-backend',
        version: '1.0.0',
      },
      transports: [
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple(),
          ),
        }),
        new winston.transports.File({
          filename: 'logs/error.log',
          level: 'error',
          maxsize: 5242880, // 5MB
          maxFiles: 5,
        }),
        new winston.transports.File({
          filename: 'logs/combined.log',
          maxsize: 5242880, // 5MB
          maxFiles: 5,
        }),
      ],
    });
  }

  log(message: string, context?: string) {
    this.logger.info(message, { context });
  }

  error(message: string, trace?: string, context?: string) {
    this.logger.error(message, { trace, context });
  }

  warn(message: string, context?: string) {
    this.logger.warn(message, { context });
  }

  debug(message: string, context?: string) {
    this.logger.debug(message, { context });
  }

  verbose(message: string, context?: string) {
    this.logger.verbose(message, { context });
  }

  // Custom logging methods for business events
  logUserAction(userId: string, action: string, details?: any) {
    this.logger.info('User action', {
      context: 'UserAction',
      userId,
      action,
      details,
    });
  }

  logBusinessEvent(event: string, data: any) {
    this.logger.info('Business event', {
      context: 'BusinessEvent',
      event,
      data,
    });
  }

  logSecurityEvent(event: string, details: any) {
    this.logger.warn('Security event', {
      context: 'SecurityEvent',
      event,
      details,
    });
  }

  logPerformance(operation: string, duration: number, details?: any) {
    this.logger.info('Performance metric', {
      context: 'Performance',
      operation,
      duration,
      details,
    });
  }

  logDatabaseQuery(query: string, duration: number, params?: any) {
    this.logger.debug('Database query', {
      context: 'Database',
      query,
      duration,
      params,
    });
  }

  logExternalApiCall(service: string, endpoint: string, duration: number, status: number) {
    this.logger.info('External API call', {
      context: 'ExternalAPI',
      service,
      endpoint,
      duration,
      status,
    });
  }
}
