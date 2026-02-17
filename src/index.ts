import openapi from '@elysiajs/openapi';
import { Elysia } from 'elysia';
import { userRoute } from './user-route';

console.log('process.env :>> ', process.env);
const app = new Elysia()
  .use(openapi())
  .use(userRoute)
  .get('/', () => 'Hello Elysia')

  .listen({
    port: process.env.SERVER_PORT ?? 3000,
    hostname: '0.0.0.0',
  });

console.log(
  `🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`,
);
