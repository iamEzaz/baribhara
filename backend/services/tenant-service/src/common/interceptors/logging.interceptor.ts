import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const { method, url, body, query, params } = request;
    const startTime = Date.now();

    console.log(`[${new Date().toISOString()}] ${method} ${url}`, {
      body: method !== 'GET' ? body : undefined,
      query,
      params,
    });

    return next.handle().pipe(
      tap(() => {
        const duration = Date.now() - startTime;
        console.log(`[${new Date().toISOString()}] ${method} ${url} - ${duration}ms`);
      }),
    );
  }
}
