# System Design Interview — Concept Resources

Interview-prep resources for **Senior Software Engineer** roles at product-based companies.
Each concept is distilled from *System Design Interview – An Insider's Guide* by **Alex Xu**, with added frameworks, cheat sheets, and practice problems.

> 📐 Authoring a new file? Follow [`GUIDELINES.md`](./GUIDELINES.md) — notably the **< 120 lines** per-file cap.

## 📊 Progress Tracking

Track your overall concepts: **27 / 50 completed (54%)** *(read + revised)*

- **Written:** 41 / 50 — **82%** *(9 in backlog — the `*(todo)*` rows)*
- **Read:** 27 / 50 — **54%**
- **Revised:** 0 / 50 — **0%**

> Tick `☐ → ✅` in the table as you go; run `scripts/progress.sh` to refresh these counts.

## Concepts

Topic sections (numbered folders); read top-to-bottom. **Read** / **Revised**: tick ✅ as you go. **Unlinked rows are not yet written** — backlog lives in [`docs/TODO.md`](../docs/TODO.md).

| Section | Concept | Read | Revised | Last Revision |
|---|---|:----:|:--:|---------------|
| **00 · Framework** | [System Design Interview Framework](./00-framework/system-design-interview-framework.md) |  ☐   | ☐ | —             |
| **01 · Envelope Estimation** | [Back-of-the-Envelope Estimation](./01-envelope-estimation/back-of-the-envelope-estimation.md) |  ✅   | ☐ | 2026-08-23    |
| | ↳ [Worked Examples](./01-envelope-estimation/back-of-the-envelope-examples.md) |  ✅   | ☐ | 2026-08-23    |
| **02 · Foundations** | [Basics — Cloud, API, Scalability](./02-foundations/basics.md) |  ☐   | ☐ | —             |
| | [Non-Functional Requirements — the "-ilities"](./02-foundations/non-functional-requirements.md) |  ☐   | ☐ | —             |
| | [Monolithic vs Microservices](./02-foundations/monolithic-vs-microservices.md) |  ☐   | ☐ | —             |
| **03 · Networking & Delivery** | [Load Balancing & Consistent Hashing](./03-networking-and-delivery/load-balancing-and-consistent-hashing.md) |  ✅   | ☐ | 2026-08-17    |
| | [Content Delivery Network (CDN)](./03-networking-and-delivery/cdn.md) |  ☐   | ☐ | —             |
| | DNS & Networking *(todo)* |  ☐   | ☐ | —             |
| | [API Gateway & Reverse Proxy](./03-networking-and-delivery/api-gateway-and-reverse-proxy.md) |  ☐   | ☐ | —             |
| | Rate Limiting *(todo)* |  ☐   | ☐ | —             |
| **04 · APIs** | [API Design](./04-apis/api-design.md) |  ✅   | ☐ | 2026-08-14    |
| | [HTTP — Methods, Status, Headers](./04-apis/http.md) |  ✅   | ☐ | 2026-08-14    |
| | [HTTP Versions (1.0 → 3)](./04-apis/http-versions.md) |  ✅   | ☐ | 2026-08-15    |
| | [REST](./04-apis/rest.md) |  ✅   | ☐ | 2026-08-15    |
| | [gRPC](./04-apis/grpc.md) |  ✅   | ☐ | 2026-08-15    |
| | [GraphQL](./04-apis/graphql.md) |  ✅   | ☐ | 2026-08-15    |
| | [Real-Time Communication](./04-apis/realtime-communication.md) |  ✅   | ☐ | 2026-08-15    |
| | [Webhooks](./04-apis/webhooks.md) |  ✅   | ☐ | 2026-08-15    |
| | [Authentication & Authorization](./04-apis/authentication-and-authorization.md) |  ✅   | ☐ | 2026-08-15    |
| | [SSO: SAML, OAuth 2.0 & OIDC](./04-apis/oauth-oidc-saml.md) |  ✅   | ☐ | 2026-08-15    |
| | [API Security](./04-apis/api-security.md) |  ✅   | ☐ | 2026-08-15    |
| | [Serialization Formats — JSON / Protobuf / Avro](./04-apis/serialization-formats.md) |  ✅   | ☐ | 2026-08-15    |
| | [Signing Algorithms — symmetric / asymmetric, RSA, SHA](./04-apis/signing-algorithms.md) |  ✅   | ☐ | 2026-08-16    |
| **05 · Databases & Storage** | [Databases — Fundamentals](./05-databases-and-storage/databases-fundamentals.md) |  ✅   | ☐ | 2026-08-16    |
| | [Databases — Scaling](./05-databases-and-storage/databases-scaling.md) |  ✅   | ☐ | 2026-08-16    |
| | [NoSQL Databases](./05-databases-and-storage/nosql-databases.md) |  ✅   | ☐ | 2026-08-16    |
| | [Sharding / Partitioning](./05-databases-and-storage/sharding-and-partitioning.md) |  ✅   | ☐ | 2026-08-16    |
| | [Object / Blob Storage](./05-databases-and-storage/object-blob-storage.md) |  ✅   | ☐ | 2026-08-16    |
| | [Full-Text Search / Inverted Index](./05-databases-and-storage/full-text-search.md) |  ✅   | ☐ | 2026-08-16    |
| | [OLTP vs OLAP / Data Warehouse](./05-databases-and-storage/oltp-vs-olap.md) |  ✅   | ☐ | 2026-08-16    |
| | Geospatial Indexing — geohash, quadtree *(todo)* |  ☐   | ☐ | —             |
| | Bloom Filters *(todo)* |  ☐   | ☐ | —             |
| | [Unique ID Generation — Snowflake, UUID](./05-databases-and-storage/unique-id-generation.md) |  ☐   | ☐ | —             |
| **06 · Caching** | [Caching](./06-caching/caching.md) |  ☐   | ☐ | —             |
| | [Distributed Caching — Redis & Memcached](./06-caching/redis-and-memcached.md) |  ☐   | ☐ | —             |
| | ↳ [Redis Sorted Sets (ZSET)](./06-caching/redis-sorted-sets.md) |  ☐   | ☐ | —             |
| **07 · Messaging & Events** | [Message Queue](./07-messaging-and-events/message-queue.md) |  ☐   | ☐ | —             |
| | [Apache Kafka](./07-messaging-and-events/apache-kafka.md) |  ☐   | ☐ | —             |
| | [Event-Driven Architecture](./07-messaging-and-events/event-driven-architecture.md) |  ☐   | ☐ | —             |
| **08 · Distributed Systems** | [Single Point of Failure](./08-distributed-systems/single-point-of-failure.md) |  ✅   | ☐ | 2026-08-17    |
| | [Consistency Models — strong / eventual / quorum](./08-distributed-systems/consistency-models.md) |  ✅   | ☐ | 2026-08-18    |
| | [Concurrency Control — locks / CAS / atomic update / single-writer](./08-distributed-systems/concurrency-control.md) |  ☐   | ☐ | —             |
| | Consensus & Leader Election — Raft / Paxos *(todo)* |  ☐   | ☐ | —             |
| | Distributed Transactions — 2PC / Saga / CDC *(todo)* |  ☐   | ☐ | —             |
| | Batch vs Stream Processing *(todo)* |  ☐   | ☐ | —             |
| **09 · Reliability & Operations** | [Resilience Patterns — retries, circuit breaker](./09-reliability-and-operations/resilience-patterns.md) |  ✅   | ☐ | 2026-08-18    |
| | [Observability — logs, metrics, tracing, SLO](./09-reliability-and-operations/observability.md) |  ✅   | ☐ | 2026-08-18    |
| **Broader tracks** | AWS — core services mapped to concepts *(todo)* |  ☐   | ☐ | —             |
| | AI curriculum *(todo)* |  ☐   | ☐ | —             |

Worked **case studies** ("Design X") are tracked separately in [`docs/TODO.md`](../docs/TODO.md).

## Useful material

External resources worth watching/reading alongside these notes.

| Type | Resource |
|------|----------|
| 📺 Video | [System design walkthrough (YouTube)](https://www.youtube.com/watch?v=Ooy-KpRH66M) |
