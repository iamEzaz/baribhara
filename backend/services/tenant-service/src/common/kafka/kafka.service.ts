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
      clientId: 'baribhara-property-service',
      brokers: [this.configService.get('KAFKA_BROKERS', 'localhost:9092')],
    });

    this.producer = this.kafka.producer();
    this.consumer = this.kafka.consumer({ groupId: 'property-service-group' });

    await this.producer.connect();
    await this.consumer.connect();

    // Subscribe to relevant topics
    await this.consumer.subscribe({ topic: 'property.events', fromBeginning: false });
    await this.consumer.subscribe({ topic: 'tenant.events', fromBeginning: false });

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
            key: data.propertyId || data.id || 'unknown',
            value: JSON.stringify({
              ...data,
              timestamp: new Date().toISOString(),
              service: 'property-service',
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
      case 'property.events':
        await this.handlePropertyEvent(data);
        break;
      case 'tenant.events':
        await this.handleTenantEvent(data);
        break;
      default:
        console.log(`Unhandled topic: ${topic}`);
    }
  }

  private async handlePropertyEvent(data: any): Promise<void> {
    console.log('Handling property event:', data);
    // Handle property-related events
  }

  private async handleTenantEvent(data: any): Promise<void> {
    console.log('Handling tenant event:', data);
    // Handle tenant-related events
  }
}
