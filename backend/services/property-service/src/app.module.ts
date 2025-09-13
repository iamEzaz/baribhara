import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PropertyController } from './controllers/property.controller';
import { PropertyService } from './services/property.service';
import { Property } from './entities/property.entity';
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
    
    TypeOrmModule.forFeature([Property]),
    
    DatabaseModule,
    RedisModule,
    KafkaModule,
  ],
  controllers: [PropertyController, HealthController],
  providers: [PropertyService],
  exports: [PropertyService],
})
export class AppModule {}
