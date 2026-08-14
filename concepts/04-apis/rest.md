# REST

---

The dominant API style: model everything as **resources** addressed by URLs and manipulated with [HTTP](./http.md) methods. Companion to [API design](./api-design.md) (which covers versioning, pagination, errors).

## 1. What is REST?

**REST** (REpresentational State Transfer) is an architectural style, not a protocol. A **resource** (a user, an order) has a URL; the client acts on it with HTTP **methods** and receives a **representation** (usually JSON). It's ubiquitous, cacheable, and human-readable — the default for public APIs.

## 2. The constraints (what makes an API "RESTful")

| Constraint | Meaning |
|---|---|
| **Client–server** | separate concerns; evolve independently |
| **Stateless** | each request carries all it needs; no server session |
| **Cacheable** | responses declare cacheability (`Cache-Control`, `ETag`) |
| **Uniform interface** | resources + standard methods + representations |
| **Layered system** | client can't tell if it hit the origin, a proxy, or a [CDN](../03-networking-and-delivery/cdn.md) |
| **Code on demand** *(optional)* | server may ship executable code (rare) |

**Statelessness** is the one that matters most for scale — it lets any server behind a [load balancer](../03-networking-and-delivery/load-balancing-and-consistent-hashing.md) handle any request.

## 3. Resource modeling

- URLs are **nouns**, plural, hierarchical: `/users/{id}/orders/{orderId}`.
- The **method is the verb** (`GET/POST/PUT/PATCH/DELETE`) — never `/getUser` or `/createOrder`.
- **Status codes** carry the outcome (`201 Created`, `404`, `409`). See [HTTP](./http.md).

## 4. Richardson Maturity Model

A ladder for "how RESTful":

- **Level 0** — one URL, one method (RPC-over-HTTP, e.g. SOAP).
- **Level 1** — many resource URLs, but ad-hoc methods.
- **Level 2** — resources **+ correct HTTP verbs + status codes** (where most "REST" APIs live, and it's plenty).
- **Level 3** — **HATEOAS**: responses embed **links** to related actions/resources, so clients navigate by following links rather than hardcoding URLs. Purest REST; rarely fully adopted.

## 5. Strengths & weaknesses

**Strengths:** simple, ubiquitous, human-readable, cacheable, great tooling, browser-friendly. **Weaknesses:** **over-/under-fetching** (fixed response shapes → [GraphQL](./graphql.md) addresses this), multiple round trips for related data, no built-in streaming (→ [gRPC](./grpc.md)), and no strict schema unless you add **OpenAPI**.

## 6. One-Paragraph Summary (for quick revision)

**REST** models the system as **resources** with noun URLs, acted on by HTTP **methods**, returning **representations** (JSON) and **status codes**. Its constraints — client–server, **stateless**, cacheable, uniform interface, layered — are what make it scale (statelessness lets any server serve any request). Model URLs as plural nouns with hierarchy, let the method be the verb, and use status codes for outcomes. The **Richardson Maturity Model** grades REST from Level 0 (RPC) to Level 3 (**HATEOAS**, link-driven); most good APIs sit at **Level 2** (resources + verbs + status codes). REST wins on simplicity, ubiquity, and caching but suffers over-/under-fetching and extra round trips — where **GraphQL** and **gRPC** step in.
