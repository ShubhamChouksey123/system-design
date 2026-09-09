# TODO — Backlog

Work across three tracks: **Growth & Distribution** (get the live site found), **Concepts** (under `concepts/`), and **Case Studies** (worked "Design X" mocks under `practice/`).

# Growth & Distribution (higher-impact)

The site is live at <https://shubhamchouksey123.github.io/system-design/>. These move the needle on **reach** far more than another concept doc — roughly in priority order.

> **▶ Right now:** (1) resubmit the sitemap as `sitemap.xml` (no leading slash); (2) add the site link to your **GitHub profile README + LinkedIn** and cross-link the **DSA repo** — cheap backlinks that start earning authority; (3) on the content side, fill the **Distributed Systems** gap (consistency → consensus → transactions).

## 1. Get indexed (do first — nothing ranks until this is done)
- [~] **Google Search Console** — property added + **ownership verified** (HTML-file, `site-docs/google…​.html`). Sitemap first submit showed *"Couldn't fetch"* (leading-slash `/sitemap.xml` 404s at the domain root). **Remaining: resubmit as `sitemap.xml`** — no leading slash → resolves to `…/system-design/sitemap.xml` (confirmed 200).
- [x] **Set the repo `homepage` field** to the live site URL (About panel + a backlink signal).
- [ ] **Bing Webmaster Tools** — import from Search Console (covers Bing / DuckDuckGo + IndexNow).

## 2. Backlinks & distribution (the real ranking driver)
- [ ] Link the site from your **GitHub profile README** and **LinkedIn**.
- [ ] Cross-link with the **DSA repo** (`data-structures-java-solution`) both ways.
- [ ] When content is fuller, post one quality thread each to **r/leetcode**, **r/cscareerquestions**, **dev.to**, **Hacker News (Show HN)**.

## 3. Deepen the differentiator (what makes people link & share)
- [ ] **Log more mock-interview sessions** — the scored, analyzed transcripts are the moat; target a handful of "Design X" mocks (see Case Studies).
- [ ] Add **architecture diagrams** to more concept pages (shareable, boosts dwell time).

## 4. On-site SEO polish
- [x] Sharpen page/nav titles for the top pages.
- [ ] Add a **social card / `og:image`** (Material `social` plugin) for rich link previews on LinkedIn/Twitter/Slack.
- [ ] Optionally exclude internal `GUIDELINES` / `docs/TODO` pages from the sitemap.

## 5. Finish the study goal (feeds everything above)
- [ ] Reach the **75% read** mark to start the practice phase (depth-first plan).
- [ ] Prioritize the unread **foundational** sections (framework, estimation, networking, caching) over the long tail.

# Concepts

Grouped by topic.

## Data & Storage
- [x] **Sharding / partitioning** — range vs hash vs geo, hotspots, rebalancing. *(a few lines in databases-scaling)*
- [x] **Object / blob storage** (S3-style) & file storage. *(referenced everywhere, never defined)*
- [x] **Full-text search / inverted index** (Elasticsearch).
- [x] **OLTP vs OLAP / data warehouse**.
- [ ] **Geospatial indexing** — geohash, quadtree (proximity / "nearby" designs).
- [ ] **Bloom filters** (own note; mentioned in caching).
- [x] **Unique ID generation** — Snowflake, UUID, ticket server.

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
- [x] **Serialization formats** — JSON vs Protobuf vs Avro/Thrift; schema evolution. *(only inside grpc/Kafka)*
- [ ] Diagram for **real-time communication** (WebSocket vs SSE vs polling).

## Security
- [x] **Signing algorithms** — symmetric vs asymmetric key pairs, RSA, EdDSA, SHA-256.

## Broader Tracks (scope before starting)
- [ ] **AWS** — core services mapped to the concepts above (EC2, S3, RDS/DynamoDB, SQS/SNS, ELB, CloudFront, Lambda).
- [ ] **AI curriculum** — separate domain from SDI prep; needs its own scoping.

# Case Studies — "Design X"

Cross-checked against `practice/README.md`'s 13 logged sessions (see the tracker's own ["How to Improve" plan](../practice/README.md#how-to-improve) for the re-solve backlog on problems already attempted). **Already run** (mark done, don't re-list as backlog — re-attempts belong in the re-solve plan above, not here):

- [x] URL shortener → S01 *(re-solve: none needed, S01 was the only pass at this one but it's low-stakes)*
- [x] Rate limiter → S07 *(⚠️ 6.0 — a good re-solve candidate; see practice tracker)*
- [x] Chat / WhatsApp → S08 (⚠️ 6.5) → S09 re-solve (✅ 7.5)
- [x] YouTube / video streaming → S12 (✅ 7.2)
- [x] News feed *(as a component, not standalone)* → built inside S06's MVP feed and S13's hybrid push/pull feed (✅ 7.5) — the celebrity fan-out crux is now a banked strength; a **standalone** feed-only session isn't high-value anymore
- [x] Multi-channel notification system, standalone → S14 (⚠️ 7.0) — per-provider fault isolation and circuit breakers landed; priority tiers, ordering, and concrete Kafka partition/consumer-scaling math didn't — good re-solve candidate

**Not yet attempted — prioritized by which *new* crux each tests** (the log's diminishing-returns problem: feed/messaging/media-pipeline cruxes are now well-drilled across S09–S13; the next-highest-leverage sessions are ones that force a crux this log has *never* faced):

- [ ] **Google Drive / cloud file storage** — new crux: **file versioning + diff/delta sync** (block-level chunking so editing a large file doesn't re-upload it whole), **folder-tree metadata** (a recursive structure, not a flat table), and **conflict resolution** for concurrent edits from multiple devices. Shares the upload/CDN plumbing from S12 but the sync/versioning crux is untested.
- [ ] **Personalized recommendation service** (e.g. "Design a feed/product ranking system") — new crux: **offline vs. online split** (batch-trained candidate generation + a low-latency real-time ranking/scoring path), a **feature store**, and cold-start handling. This log has never touched an ML-adjacent system; it's a distinct interview archetype at senior/staff level, especially at a company like Google.
- [ ] **Monitoring / observability platform** (Datadog / New Relic style) — new crux: **high-cardinality time-series ingestion at extreme write volume**, **downsampling/rollup strategy** (can't keep raw resolution forever), and an **alerting rules engine** evaluating thresholds over sliding windows. Directly closes the `concepts/09-reliability-and-operations/observability.md` gap this log's own Action Item #16 keeps citing as thin — this session would let you *design* the very topic that's been dinged for not being named in S10/S12/S13.
- [ ] **Distributed job scheduler / cron** (e.g. "Design a task scheduler like Airflow/Cron-as-a-service") — new crux: **exactly-once trigger** despite multiple scheduler replicas (leader election), and DAG-based dependency scheduling. Closes the `concepts/08-distributed-systems` "Consensus & leader election" gap that's currently a `*(todo)*` row with zero session coverage.
- [ ] **Ad click / impression counting & fraud detection** — new crux: **exactly-once counting at extreme write throughput** with late/duplicate event handling (watermarks), distinct from every prior "cache a counter" pattern in this log because correctness *is* the product (billing depends on it). Also the log's first real OLAP/analytics-pipeline design.
- [ ] **Ride-sharing / proximity matching** (Uber-style, or "nearby friends") — new crux: **geospatial indexing** (geohash / quadtree / S2) for "who's near me" queries, plus real-time driver-rider matching under a moving-target constraint. Closes the `concepts/05-databases-and-storage` "Geospatial indexing" `*(todo)*` gap — currently zero session coverage.
- [ ] **Distributed key-value store** (Dynamo/Redis-clone style — the infra system itself, not an app that merely *uses* one) — new crux: **consistent hashing with virtual nodes, replication factor, quorum reads/writes, and read-repair/anti-entropy** as the entire point of the design, not a one-line mention. The log has used Redis/Cassandra as a component in nearly every session but never designed the store itself.
- [ ] **Payment system / ledger** (Stripe-style, as its own dedicated crux, not a feature bolted onto e-commerce) — new crux: **double-entry ledger correctness**, idempotency keys end-to-end, and reconciliation against a payment processor's async webhooks. Payments have been touched shallowly in S02–S04 and flagged as a recurring silent gap (Action Item #9) but never designed as the primary system.
- [ ] **Search autocomplete / typeahead** — new crux: a **trie or prefix-index** structure with ranking, and a write path (popular-query promotion) decoupled from the read path. Smaller in scope than the others above — good as a quick, focused session rather than a big one.
- [ ] **Web crawler** — new crux: **politeness/crawl-rate scheduling per domain**, dedup at web-scale (Bloom filters — another currently-`*(todo)*` concept gap), and a URL-frontier priority queue. Good pairing with the Bloom Filters concept doc once it's written.
