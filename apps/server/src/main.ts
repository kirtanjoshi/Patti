import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { cors: true });
  app.enableCors({ origin: '*' });
  const port = process.env.PORT || 4000;
  await app.listen(port, '0.0.0.0');
  console.log(`Patii Game Server running on port ${port}`);
}

if (process.env.NODE_ENV !== 'test') {
  bootstrap().catch((err) => {
    console.error('Fatal bootstrap error:', err);
    process.exit(1);
  });
}
