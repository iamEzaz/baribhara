import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Kafka, Producer, Consumer } from 'kafkajs';

@Injectable()
export class KafkaService implements OnModuleInit, OnModuleDestroy {
  private kafka: Kafka;
  private producer: Producer;
  private consumer: Consumer;

  constructor(private configService: ConfigService) {}

  async onModuleInit() {
    this.kafka = new Kafka({
      clientId: 'baribhara-auth-service',
      brokers: [this.configService.get('KAFKA_BROKERS', 'localhost:9092')],
    });

    this.producer = this.kafka.producer();
    this.consumer = this.kafka.consumer({ groupId: 'auth-service-group' });

    await this.producer.connect();
    await this.consumer.connect();

    // Subscribe to relevant topics
    await this.consumer.subscribe({ topic: 'user.events', fromBeginning: false });
    await this.consumer.subscribe({ topic: 'notification.events', fromBeginning: false });

    // Start consuming messages
    await this.consumer.run({
      eachMessage: async ({ topic, partition, message }) => {
        try {
          const value = JSON.parse(message.value?.toString() || '{}');
          await this.handleMessage(topic, value);
        } catch (error) {
          console.error('Error processing Kafka message:', error);
        }
      },
    });
  }

  async onModuleDestroy() {
    await this.producer.disconnect();
    await this.consumer.disconnect();
  }

  async emit(topic: string, data: any): Promise<void> {
    try {
      await this.producer.send({
        topic,
        messages: [
          {
            key: data.userId || data.id || 'unknown',
            value: JSON.stringify({
              ...data,
              timestamp: new Date().toISOString(),
              service: 'auth-service',
            }),
          },
        ],
      });
    } catch (error) {
      console.error('Error emitting Kafka message:', error);
      throw error;
    }
  }

  private async handleMessage(topic: string, data: any): Promise<void> {
    switch (topic) {
      case 'user.events':
        await this.handleUserEvent(data);
        break;
      case 'notification.events':
        await this.handleNotificationEvent(data);
        break;
      default:
        console.log(`Unhandled topic: ${topic}`);
    }
  }

  private async handleUserEvent(data: any): Promise<void> {
    console.log('Handling user event:', data);
    // Handle user-related events
  }

  private async handleNotificationEvent(data: any): Promise<void> {
    console.log('Handling notification event:', data);
    // Handle notification-related events
  }
}
