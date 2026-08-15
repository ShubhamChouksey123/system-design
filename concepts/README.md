# System Design Interview — Concept Resources

Interview-prep resources for **Senior Software Engineer** roles at product-based companies.
Each concept is distilled from *System Design Interview – An Insider's Guide* by **Alex Xu**, with added frameworks, cheat sheets, and practice problems.

> 📐 Authoring a new file? Follow [`GUIDELINES.md`](./GUIDELINES.md) — notably the **< 120 lines** per-file cap.

## 📊 Progress Tracking

Track your overall concepts: **9 / 47 completed (19%)** *(read + revised)*

- **Written:** 27 / 47 — **57%** *(20 in backlog — the `*(todo)*` rows)*
- **Read:** 9 / 47 — **19%**
- **Revised:** 0 / 47 — **0%**

> Tick `☐ → ✅` in the table as you go; run `scripts/progress.sh` to refresh these counts.

## Concepts

Topic sections (numbered folders); read top-to-bottom. **Read** / **Revised**: tick ✅ as you go. **Unlinked rows are not yet written** — backlog lives in [`docs/TODO.md`](../docs/TODO.md).

| Section | Concept | Read | Revised | Last Revision |
|---|---|:--:|:--:|---------------|
| **00 · Framework** | [System Design Interview Framework](./00-framework/system-design-interview-framework.md) | ☐ | ☐ | —             |
| **01 · Envelope Estimation** | [Back-of-the-Envelope Estimation](./01-envelope-estimation/back-of-the-envelope-estimation.md) | ☐ | ☐ | —             |
| | ↳ [Worked Examples](./01-envelope-estimation/back-of-the-envelope-examples.md) | ☐ | ☐ | —             |
| **02 · Foundations** | [Basics — Cloud, API, Scalability](./02-foundations/basics.md) | ☐ | ☐ | —             |
| | [Monolithic vs Microservices](./02-foundations/monolithic-vs-microservices.md) | ☐ | ☐ | —             |
| **03 · Networking & Delivery** | [Load Balancing & Consistent Hashing](./03-networking-and-delivery/load-balancing-and-consistent-hashing.md) | ☐ | ☐ | —             |
| | [Content Delivery Network (CDN)](./03-networking-and-delivery/cdn.md) | ☐ | ☐ | —             |
| | DNS & Networking *(todo)* | ☐ | ☐ | —             |
| | API Gateway & Reverse Proxy *(todo)* | ☐ | ☐ | —             |
| | Rate Limiting *(todo)* | ☐ | ☐ | —             |
| **04 · APIs** | [API Design](./04-apis/api-design.md) | ✅ | ☐ | 2026-08-14    |
| | [HTTP — Methods, Status, Headers](./04-apis/http.md) | ✅ | ☐ | 2026-08-14    |
| | [HTTP Versions (1.0 → 3)](./04-apis/http-versions.md) | ✅ | ☐ | 2026-08-15    |
| | [REST](./04-apis/rest.md) | ✅ | ☐ | 2026-08-15    |
| | [gRPC](./04-apis/grpc.md) | ✅ | ☐ | 2026-08-15    |
| | [GraphQL](./04-apis/graphql.md) | ✅ | ☐ | 2026-08-15            |
| | [Real-Time Communication](./04-apis/realtime-communication.md) | ✅ | ☐ | 2026-08-15            |
| | [Webhooks](./04-apis/webhooks.md) | ✅ | ☐ | 2026-08-15            |
| | [Authentication & Authorization](./04-apis/authentication-and-authorization.md) | ✅ | ☐ | 2026-08-15             |
| | [SSO: SAML, OAuth 2.0 & OIDC](./04-apis/oauth-oidc-saml.md) | ☐ | ☐ | —             |
| | [API Security](./04-apis/api-security.md) | ☐ | ☐ | —             |
| | Serialization Formats — JSON / Protobuf / Avro *(todo)* | ☐ | ☐ | —             |
| | Signing Algorithms — symmetric / asymmetric, RSA, SHA *(todo)* | ☐ | ☐ | —             |
| **05 · Databases & Storage** | [Databases — Fundamentals](./05-databases-and-storage/databases-fundamentals.md) | ☐ | ☐ | —             |
| | [Databases — Scaling](./05-databases-and-storage/databases-scaling.md) | ☐ | ☐ | —             |
| | [NoSQL Databases](./05-databases-and-storage/nosql-databases.md) | ☐ | ☐ | —             |
| | Sharding / Partitioning *(todo)* | ☐ | ☐ | —             |
| | Object / Blob Storage *(todo)* | ☐ | ☐ | —             |
| | Full-Text Search / Inverted Index *(todo)* | ☐ | ☐ | —             |
| | OLTP vs OLAP / Data Warehouse *(todo)* | ☐ | ☐ | —             |
| | Geospatial Indexing — geohash, quadtree *(todo)* | ☐ | ☐ | —             |
| | Bloom Filters *(todo)* | ☐ | ☐ | —             |
| | Unique ID Generation — Snowflake, UUID *(todo)* | ☐ | ☐ | —             |
| **06 · Caching** | [Caching](./06-caching/caching.md) | ☐ | ☐ | —             |
| | [Distributed Caching — Redis & Memcached](./06-caching/redis-and-memcached.md) | ☐ | ☐ | —             |
| **07 · Messaging & Events** | [Message Queue](./07-messaging-and-events/message-queue.md) | ☐ | ☐ | —             |
| | [Apache Kafka](./07-messaging-and-events/apache-kafka.md) | ☐ | ☐ | —             |
| | [Event-Driven Architecture](./07-messaging-and-events/event-driven-architecture.md) | ☐ | ☐ | —             |
| **08 · Distributed Systems** | [Single Point of Failure](./08-distributed-systems/single-point-of-failure.md) | ☐ | ☐ | —             |
| | Consistency Models — strong / eventual / quorum *(todo)* | ☐ | ☐ | —             |
| | Consensus & Leader Election — Raft / Paxos *(todo)* | ☐ | ☐ | —             |
| | Distributed Transactions — 2PC / Saga / CDC *(todo)* | ☐ | ☐ | —             |
| | Batch vs Stream Processing *(todo)* | ☐ | ☐ | —             |
| **09 · Reliability & Operations** | Resilience Patterns — retries, circuit breaker *(todo)* | ☐ | ☐ | —             |
| | Observability — logs, metrics, tracing, SLO *(todo)* | ☐ | ☐ | —             |
| **Broader tracks** | AWS — core services mapped to concepts *(todo)* | ☐ | ☐ | —             |
| | AI curriculum *(todo)* | ☐ | ☐ | —             |

Worked **case studies** ("Design X") are tracked separately in [`docs/TODO.md`](../docs/TODO.md).

## Useful material

External resources worth watching/reading alongside these notes.

| Type | Resource |
|------|----------|
| 📺 Video | [System design walkthrough (YouTube)](https://www.youtube.com/watch?v=Ooy-KpRH66M) |
