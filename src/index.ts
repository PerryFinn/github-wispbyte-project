import openapi from '@elysiajs/openapi';
import { Elysia } from 'elysia';
import { userRoute } from './user-route';

const app = new Elysia()
  .use(openapi())
  .use(userRoute)
  .get('/', () => 'Hello Elysia')

  .listen(15087);

console.log(
  `🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`,
);
