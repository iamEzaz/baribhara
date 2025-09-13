import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CaretakerController } from './controllers/caretaker.controller';
import { CaretakerService } from './services/caretaker.service';
import { Caretaker } from './entities/caretaker.entity';
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
    
    TypeOrmModule.forFeature([Caretaker]),
    
    DatabaseModule,
    RedisModule,
    KafkaModule,
  ],
  controllers: [CaretakerController, HealthController],
  providers: [CaretakerService],
  exports: [CaretakerService],
})
export class AppModule {}
