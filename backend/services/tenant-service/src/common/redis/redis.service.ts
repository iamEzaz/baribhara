import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private client: Redis;

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    this.client = new Redis({
      host: this.configService.get('REDIS_HOST', 'localhost'),
      port: this.configService.get('REDIS_PORT', 6379),
      password: this.configService.get('REDIS_PASSWORD'),
      retryDelayOnFailover: 100,
      enableReadyCheck: false,
      maxRetriesPerRequest: null,
    });

    this.client.on('error', (err) => {
      console.error('Redis Client Error:', err);
    });

    this.client.on('connect', () => {
      console.log('Redis Client Connected');
    });
  }

  async onModuleDestroy() {
    await this.client.quit();
  }

  async get(key: string): Promise<string | null> {
    return this.client.get(key);
  }

  async set(key: string, value: string, ttl?: number): Promise<'OK'> {
    if (ttl) {
      return this.client.setex(key, ttl, value);
    }
    return this.client.set(key, value);
  }

  async del(key: string): Promise<number> {
    return this.client.del(key);
  }

  async exists(key: string): Promise<number> {
    return this.client.exists(key);
  }

  async expire(key: string, ttl: number): Promise<number> {
    return this.client.expire(key, ttl);
  }

  async ttl(key: string): Promise<number> {
    return this.client.ttl(key);
  }

  async hget(key: string, field: string): Promise<string | null> {
    return this.client.hget(key, field);
  }

  async hset(key: string, field: string, value: string): Promise<number> {
    return this.client.hset(key, field, value);
  }

  async hgetall(key: string): Promise<Record<string, string>> {
    return this.client.hgetall(key);
  }

  async hdel(key: string, field: string): Promise<number> {
    return this.client.hdel(key, field);
  }

  async sadd(key: string, ...members: string[]): Promise<number> {
    return this.client.sadd(key, ...members);
  }

  async smembers(key: string): Promise<string[]> {
    return this.client.smembers(key);
  }

  async srem(key: string, ...members: string[]): Promise<number> {
    return this.client.srem(key, ...members);
  }

  async lpush(key: string, ...values: string[]): Promise<number> {
    return this.client.lpush(key, ...values);
  }

  async rpop(key: string): Promise<string | null> {
    return this.client.rpop(key);
  }

  async llen(key: string): Promise<number> {
    return this.client.llen(key);
  }

  async lrange(key: string, start: number, stop: number): Promise<string[]> {
    return this.client.lrange(key, start, stop);
  }
}
