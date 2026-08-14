# TODO — Backlog

Work to add, split into **Concepts** (under `concepts/`) and **Case Studies** (worked "Design X" problems under `practice/` or a new `03-case-studies/`).

# Concepts

Grouped by topic.

## Data & Storage
- [ ] **Sharding / partitioning** — range vs hash vs geo, hotspots, rebalancing. *(a few lines in databases-scaling)*
- [ ] **Object / blob storage** (S3-style) & file storage. *(referenced everywhere, never defined)*
- [ ] **Full-text search / inverted index** (Elasticsearch).
- [ ] **OLTP vs OLAP / data warehouse**.
- [ ] **Geospatial indexing** — geohash, quadtree (proximity / "nearby" designs).
- [ ] **Bloom filters** (own note; mentioned in caching).
- [ ] **Unique ID generation** — Snowflake, UUID, ticket server.

## Distributed Systems
*(could become its own numbered section, e.g. `03-distributed-systems/`)*
- [ ] **Consistency models** — strong / eventual / causal / read-your-writes; quorum (`R + W > N`). *(only CAP/BASE inside databases-fundamentals today)*
- [ ] **Consensus & leader election** — Raft / Paxos, Zookeeper; **distributed locks** (Redlock). *(touched in Kafka/MQ)*
- [ ] **Distributed transactions** — 2PC, **Saga**, **outbox pattern / CDC**. *(Saga named in microservices, not explained)*
- [ ] **Batch vs stream processing** — MapReduce, Spark, Flink. *(streaming touched in Kafka/EDA)*

## Networking & Traffic Management
- [ ] **DNS & networking** — resolution, GSLB / geo-routing, forward vs reverse proxy.
- [ ] **API gateway & reverse proxy** — routing, aggregation, BFF, proxy vs load balancer. *(2-line §6 in api-security)*
- [ ] **Rate limiting** — token bucket / leaky bucket / sliding window; distributed counters. *(bullets in api-security)*

## Reliability & Operations
- [ ] **Resilience patterns** — timeouts, retries + backoff, circuit breaker, bulkhead, idempotency keys. *(scattered)*
- [ ] **Observability** — logging, metrics, distributed tracing, health checks, alerting / SLO.

## APIs
- [ ] **Serialization formats** — JSON vs Protobuf vs Avro/Thrift; schema evolution. *(only inside grpc/Kafka)*
- [ ] Diagram for **real-time communication** (WebSocket vs SSE vs polling).

## Security
- [ ] **Signing algorithms** — symmetric vs asymmetric key pairs, RSA, EdDSA, SHA-256.

## Broader Tracks (scope before starting)
- [ ] **AWS** — core services mapped to the concepts above (EC2, S3, RDS/DynamoDB, SQS/SNS, ELB, CloudFront, Lambda).
- [ ] **AI curriculum** — separate domain from SDI prep; needs its own scoping.

# Case Studies — "Design X"

Biggest structural gap. Run each through `practice/answer-framework.md` (→ `practice/` or a new `03-case-studies/`).

- [ ] URL shortener
- [ ] Rate limiter
- [ ] Chat / WhatsApp
- [ ] News feed
- [ ] Notification system
- [ ] Search autocomplete / typeahead
- [ ] Web crawler
- [ ] YouTube / video streaming
- [ ] Google Drive / file storage
- [ ] Nearby friends / proximity service
- [ ] Key-value store
