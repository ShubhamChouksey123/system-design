# API Design

---

How to design a **good** API — a clear, consistent, evolvable contract between a service and its callers. See [HTTP](./http.md) for methods/status/headers and [auth](./authentication-and-authorization.md) for securing it.

## 1. What makes a good API?

An API is a **contract**. A good one is **consistent** (predictable naming and patterns), **intuitive** (guessable without docs), **stable** (versioned, backward-compatible), **well-documented**, and **hard to misuse** (validation + clear errors). Design the API **first** — it shapes the whole system and is expensive to change once clients depend on it.

## 2. Styles — pick the right one

| Style | Shape | Best for |
|---|---|---|
| [**REST**](./rest.md) | resources over HTTP verbs (JSON) | public / CRUD APIs, cacheable, ubiquitous |
| [**gRPC**](./grpc.md) | binary RPC over HTTP/2 | fast internal service-to-service, streaming |
| [**GraphQL**](./graphql.md) | client-shaped queries, one endpoint | flexible reads, avoid over/under-fetching |
| [**Webhooks**](./webhooks.md) | server → client callback on an event | async notifications (payments, CI) |

## 3. RESTful design principles

- **Resource-oriented** — URLs are **nouns**, the HTTP method is the verb. Good: `GET /users/123/orders`; bad: `GET /getUserOrders?id=123`.
- **Plural nouns + hierarchy** for relationships: `/users/{id}/orders/{orderId}`.
- **Methods → actions, status codes → outcomes** (see [HTTP](./http.md)).
- **Stateless** — each request carries its own auth/params; no server-side session.

| Action | Method + path |
|---|---|
| List / create | `GET /orders`, `POST /orders` |
| Read / update / delete one | `GET`, `PUT`, `PATCH`, `DELETE` on `/orders/{id}` |

## 4. Key design decisions

| Concern | Do this |
|---|---|
| **Versioning** | Version from day one — `/v1/...` or an `Accept` header; never break `v1` |
| **Pagination** | **Cursor-based** for large/changing sets (stable); offset/limit for small |
| **Filtering / sorting** | Query params: `?status=paid&sort=-createdAt` |
| **Idempotency** | `GET/PUT/DELETE` idempotent; make `POST` retry-safe with an **Idempotency-Key** |
| **Errors** | Consistent shape + right status: `{ "error": { "code", "message" } }` |
| **Auth** | [OAuth2 / JWT / API keys](./authentication-and-authorization.md) over **TLS**; least-privilege scopes |
| **Rate limiting** | Throttle and return **429** with `Retry-After` + limit headers (see [security](./api-security.md)) |

## 5. Best practices (Do / Don't)

**Do:** design the contract first; keep naming consistent; use nouns + the right verb/status code; paginate list endpoints; validate input; document with **OpenAPI/Swagger**; version from the start.

**Don't:** put verbs in URLs; return `200` for errors; remove or rename existing fields (add, don't break); leak stack traces / internal details; expose sequential guessable IDs (prefer **UUIDs** — a session-01 miss).

## 6. One-Paragraph Summary (for quick revision)

A good API is a **consistent, intuitive, stable, well-documented, hard-to-misuse contract** — design it first. Pick the **style** for the job: **REST** for public CRUD, **gRPC** for fast internal calls, **GraphQL** for flexible reads, **webhooks** for async callbacks. RESTful design is **resource-oriented**: noun URLs (`/users/{id}/orders`), HTTP methods as verbs, status codes as outcomes, and **stateless** requests. Nail the key decisions: **version** from day one, **cursor pagination**, query-param filtering, **idempotency keys** for safe retries, a **consistent error shape**, TLS + scoped **auth**, and **rate limiting** with `429`. Do use nouns, pagination, validation, and OpenAPI docs; don't put verbs in URLs, return `200` on errors, break existing fields, leak internals, or expose guessable sequential IDs.
