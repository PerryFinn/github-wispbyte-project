// index.ts
var server = Bun.serve({
  routes: {
    "/api/status": new Response("OK"),
    "/users/:id": (req) => {
      return new Response(`Hello User ${req.params.id}!`);
    },
    "/api/posts": {
      GET: () => new Response("List posts"),
      POST: async (req) => {
        const body = await req.json();
        return Response.json({ created: true, data: body });
      }
    },
    "/api/*": Response.json({ message: "Not found" }, { status: 404 })
  },
  fetch(req) {
    return new Response("Not Found", { status: 404 });
  }
});
console.log(`Server running at ${server.url}`);
