import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';

import { AuthController } from './controllers/auth.controller';
import { AuthService } from './services/auth.service';
import { UserService } from './services/user.service';
import { JwtStrategy } from './strategies/jwt.strategy';
import { LocalStrategy } from './strategies/local.strategy';
import { User } from './entities/user.entity';
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
    
    TypeOrmModule.forFeature([User]),
    
    PassportModule,
    
    JwtModule.registerAsync({
      useFactory: () => ({
        secret: process.env.JWT_SECRET || 'your-super-secret-jwt-key',
        signOptions: {
          expiresIn: process.env.JWT_EXPIRES_IN || '24h',
        },
      }),
    }),
    
    DatabaseModule,
    RedisModule,
    KafkaModule,
  ],
  controllers: [AuthController, HealthController],
  providers: [AuthService, UserService, JwtStrategy, LocalStrategy],
  exports: [AuthService, UserService],
})
export class AppModule {}
