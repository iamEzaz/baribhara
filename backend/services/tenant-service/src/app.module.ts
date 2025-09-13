import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { TenantController } from './controllers/tenant.controller';
import { TenantService } from './services/tenant.service';
import { Tenant } from './entities/tenant.entity';
import { DatabaseModule } from './common/database/database.module';
import { RedisModule } from './common/redis/redis.module';
import { KafkaModule } from './common/kafka/kafka.module';
import { HealthController } from './controllers/health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: ['.env.local', '.env'],
    }),
    
    TypeOrmModule.forFeature([Tenant]),
    
    DatabaseModule,
    RedisModule,
    KafkaModule,
  ],
  controllers: [TenantController, HealthController],
  providers: [TenantService],
  exports: [TenantService],
})
export class AppModule {}
