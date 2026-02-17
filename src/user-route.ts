import Elysia from 'elysia';

export const userRoute = new Elysia({ prefix: 'api' }).get(
  '/user/:id',
  ({ params: { id } }) => id,
);
