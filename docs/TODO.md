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

Biggest structural gap. Run each through `practice/answer-framework.md` (→ `practice/` or a new `03-case-studies/`).

- [x] URL shortener *(session 01)*
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
