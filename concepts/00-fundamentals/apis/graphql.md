# GraphQL

---

A query language for APIs: the **client asks for exactly the data it wants** from a single endpoint. Companion to [API design](./api-design.md); contrast with [REST](./rest.md) and [gRPC](./grpc.md).

## 1. What is GraphQL?

**GraphQL** (Meta) exposes **one endpoint** (`POST /graphql`) backed by a typed **schema**. The client sends a query describing the exact shape of data it needs; the server returns exactly that — no more, no less. It solves REST's over-/under-fetching.

## 2. Core pieces

| Piece | What it is |
|---|---|
| **Schema** | typed contract — types, fields, and their relationships |
| **Query** | read data (client-shaped) |
| **Mutation** | write/modify data |
| **Subscription** | real-time stream of updates (over WebSocket) |
| **Resolver** | server function that fetches each field's data |

```graphql
query {
  user(id: "123") {
    name
    orders(last: 3) { id amount }
  }
}
```

One request returns the user's name **and** their last 3 orders — shaped exactly as asked.

## 3. Why teams use it

- **No over-fetching** — get only the fields you request (great for mobile/bandwidth).
- **No under-fetching** — fetch nested/related data in **one round trip** (vs several REST calls).
- **Strongly typed schema** — introspectable, self-documenting, great tooling.
- **Evolvable** — add fields without versioning; deprecate old ones.

## 4. Trade-offs

| Advantages | Disadvantages |
|---|---|
| Client-shaped responses, one round trip | **Caching is harder** (one URL, POST) vs REST's per-URL HTTP cache |
| Strongly-typed, introspectable schema | **N+1 query** problem in resolvers — needs batching (**DataLoader**) |
| Add fields without breaking clients | Complex/expensive queries → need **depth/complexity limits** |
| One endpoint for many data needs | More server-side machinery than plain REST |

## 5. When to use

Reach for GraphQL when clients need **flexible, varied views** of related data (rich mobile/web frontends, aggregating many backends into one graph). Prefer **REST** for simple CRUD and easy HTTP caching, and **gRPC** for fast internal service-to-service calls.

## 6. One-Paragraph Summary (for quick revision)

**GraphQL** is a typed query language over a **single endpoint**: the client sends a query for **exactly the fields it wants**, and the server returns precisely that — solving REST's over-fetching (too much data) and under-fetching (too many round trips). Its schema defines **queries** (read), **mutations** (write), and **subscriptions** (real-time), with **resolvers** fetching each field. Strengths: client-shaped responses in one round trip, a strongly-typed introspectable schema, and schema evolution without versioning. Costs: **harder HTTP caching** (one POST URL), the resolver **N+1 problem** (fix with DataLoader batching), and the need for **query depth/complexity limits**. Use it for flexible frontends aggregating related data; keep REST for cacheable CRUD and gRPC for internal RPC.
