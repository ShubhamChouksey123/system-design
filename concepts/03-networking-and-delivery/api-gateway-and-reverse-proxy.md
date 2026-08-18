# API Gateway & Reverse Proxy

---

Both sit **in front of your servers** as an intermediary that clients talk to instead of hitting backends directly. A **reverse proxy** is the general primitive; an **API gateway** is a specialized reverse proxy for APIs — the **single entry point** into a [microservices](../02-foundations/monolithic-vs-microservices.md) backend that also handles cross-cutting concerns. Both often sit right beside a [load balancer](./load-balancing-and-consistent-hashing.md).

## 1. Forward proxy vs reverse proxy

The direction it faces is the whole distinction:

| | **Forward proxy** | **Reverse proxy** |
|---|---|---|
| Acts on behalf of | the **client** | the **server** |
| Hides | the client from the server | the server fleet from the client |
| Client knows the real server? | yes | no — sees only the proxy |
| Typical use | corporate egress, VPN, content filtering | TLS termination, caching, LB, security shield |

Clients hit **one public endpoint**; the proxy decides which backend actually serves the request.

## 2. Reverse proxy — what it does

A thin, high-performance intermediary that offloads work from application servers:

- **Single entry point** — one hostname/IP hides the whole fleet; servers can move/scale freely.
- **TLS termination** — decrypt HTTPS once at the edge so backends speak plain HTTP internally.
- **Caching & compression** — serve cached/static responses and gzip/brotli without touching the app.
- **Load balancing** — distribute across backends (most reverse proxies double as an [L7 LB](./load-balancing-and-consistent-hashing.md)).
- **Security shield** — hides internal topology; a natural place for WAF, IP allow/deny, DDoS absorption.

## 3. API Gateway — the API front door

An API gateway is a reverse proxy **built for APIs**: it routes each call to the right service and handles **cross-cutting concerns once, at the edge**, so every service doesn't reimplement them.

| Responsibility | What it does |
|---|---|
| **Routing** | map `path` / `host` / `version` → the right backend service |
| **Authn / authz** | validate JWT / API key / OAuth token once; reject before it reaches services ([auth](../04-apis/authentication-and-authorization.md)) |
| **Rate limiting & throttling** | protect backends from abuse and traffic spikes |
| **TLS termination** | one place to manage certs |
| **Transformation** | rewrite/enrich requests; **protocol translation** (public REST ↔ internal [gRPC](../04-apis/grpc.md)) |
| **Aggregation / composition** | fan out to several services and merge into one response (fewer client round-trips) |
| **Caching** | cache idempotent `GET`s at the edge |
| **Observability** | central access logs, metrics, tracing headers ([observability](../09-reliability-and-operations/observability.md)) |
| **Versioning / canary** | route `/v2` or a % of traffic to new deployments |

The point: a client makes **one call** to the gateway instead of knowing about, authenticating to, and coordinating dozens of services.

## 4. Gateway vs reverse proxy vs load balancer

Overlapping, not identical — a gateway is usually the superset:

| | Load balancer | Reverse proxy | API gateway |
|---|---|---|---|
| Primary job | spread load across identical servers | intermediary for one/many backends | API-aware front door for many services |
| Layer | L4 or L7 | L7 (usually) | L7, application-aware |
| Routes on | connections / simple rules | host / path | path, headers, version, **per-API policy** |
| Auth, rate limit, aggregation | ✗ | limited | ✅ core feature |

In practice they stack: **LB → gateway → services**, or one product (NGINX, Envoy) plays several roles.

## 5. BFF — Backend for Frontend

A common gateway variant: run **one gateway per client type** (web, mobile, partner) so each gets a tailored, right-sized API instead of a lowest-common-denominator one — mobile gets slimmer payloads, web gets richer aggregation.

## 6. Real-world tech

| Tool | Type | Notes |
|---|---|---|
| **NGINX**, **HAProxy** | reverse proxy / L7 LB | ubiquitous; NGINX also serves static + caching |
| **Envoy** | reverse proxy / edge & mesh | powers many gateways and service meshes |
| **Kong**, **Traefik**, **Apigee** | API gateway | plugins for auth, rate limit, transforms |
| **AWS API Gateway** | managed API gateway | integrates with AWS Lambda, IAM, usage plans |
| **Spring Cloud Gateway**, Netflix **Zuul** | app-framework gateway | JVM ecosystems |

## 7. When to use — and pitfalls

- **Use it** when you have **multiple services and multiple clients**: consolidate auth, rate limiting, TLS, and routing in one place instead of N.
- **Skip / keep thin** for a simple monolith or a single service — a plain reverse proxy or LB is enough; a gateway adds a hop and moving part.
- **Pitfalls:**
  - **Single point of failure** — the gateway fronts everything, so run it **redundant + auto-scaled** ([SPOF](../08-distributed-systems/single-point-of-failure.md)).
  - **Latency hop** — one more network segment; keep gateway logic cheap.
  - **God object** — resist putting **business logic** in the gateway; it handles cross-cutting concerns only, or it becomes a distributed monolith and a deploy bottleneck.

## 8. One-Paragraph Summary (for quick revision)

A **reverse proxy** is an intermediary that faces the **server** — clients hit one public endpoint and it forwards to hidden backends, handling **TLS termination, caching, compression, load balancing, and security shielding** (NGINX, HAProxy, Envoy). An **API gateway** is a reverse proxy **specialized for APIs**: the **single entry point** into a microservices backend that routes each call to the right service and centralizes **cross-cutting concerns** — **auth, rate limiting, TLS, request/response transformation and protocol translation (REST↔gRPC), response aggregation, caching, and observability** — so clients make one call and services don't each reimplement the edge (AWS API Gateway, Kong, Apigee, Spring Cloud Gateway). It overlaps with the **load balancer** (spread load) and reverse proxy (forward requests) but adds per-API policy on top; they commonly stack as **LB → gateway → services**. Variant: a **BFF** runs one gateway per client type for tailored payloads. Because it fronts everything, run it **highly available**, keep the hop **cheap**, and keep **business logic out** — or it degenerates into a distributed-monolith chokepoint.
