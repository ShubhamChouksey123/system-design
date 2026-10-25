# System Design Interview — Answer Framework (Playbook)

> A step-by-step scaffold for **structuring your answer** to any system design problem. Run it top-to-bottom in the room so nothing important is missed.

**How this relates to the other framework doc:** [`concepts/00-framework`](../concepts/00-framework/system-design-interview-framework.md) is the *behavioral* process — **how** to run the interview (clarify → high-level → deep dive → wrap, collaboration, don'ts). **This** doc is the *content checklist* — **what** to actually cover. Use them together: the 4 phases tell you how to pace the room; the 8 steps below tell you what goes in each phase.

## At a glance — the 8 steps (and where they land in a 45-min interview)

| Phase (from `00-framework`) | Time | Steps to cover here |
|---|---|---|
| 1. Understand & scope | ~3–10 min | ① Functional requirements · ② Non-functional requirements |
| 2. High-level design & buy-in | ~10–15 min | ③ Envelope estimation · ④ Sketch the architecture |
| 3. Design deep dive | ~10–25 min | ⑤ Walk through the design · ⑥ Data model · ⑦ Trade-offs & alternatives |
| 4. Wrap up | ~3–5 min | ⑧ Testing & monitoring (+ recap, bottlenecks, next 10×) |

> **Golden rule:** write requirements and assumptions on the canvas as a **visible checklist** before designing, and **label every diagram arrow** (data + protocol). Both were flagged in [session 01](./README.md#how-to-improve).

> **Second golden rule:** whenever you draw a database, cache, queue, notification call, or any other recurring component, run its entry in [**Component Checklists**](#component-checklists--what-to-say-every-time-this-component-appears) below before moving on — the recurring miss across this log isn't forgetting a component, it's naming one and skipping a specific property of it.

---

## ① Functional Requirements

**Goal:** pin down *what the system does* — the concrete user-facing operations. Answering the wrong problem is an automatic fail.

**Produce:** a short bulleted list of the 2–4 core features, confirmed with the interviewer. Explicitly park nice-to-haves as out of scope.

**Checklist:**
- What are the core operations (the API verbs)? e.g. `createShortUrl(longUrl) → shortUrl`, `resolve(shortUrl) → longUrl`.
- Who are the actors/clients (web, mobile, internal services)?
- Which features are **in scope** vs explicitly **out of scope** for this session?
- Any feature the prompt names explicitly (e.g. *analytics*) — capture it now, not at the end.

---

## ② Non-Functional Requirements

**Goal:** define the *qualities* the system must hold under real-world load. These drive most architecture decisions.

**Cover each:**
| Attribute | Question to answer | Typical lever |
|---|---|---|
| **Availability** | How many nines? What downtime is tolerable? | replication, failover, multi-AZ/region |
| **Scalability** | Scale to what, and how fast? Read vs write heavy? | horizontal scaling, sharding, caching |
| **Reliability** | Can we lose/corrupt data? Exactly-once vs at-least-once? | durable storage, replication, idempotency |
| **Performance** | Target latency (p95/p99)? | caching, CDN, indexes, denormalization |
| **Security** | Auth, data sensitivity, abuse/predictability? | authN/authZ, rate limiting, non-guessable IDs |

**Checklist:**
- State the target **availability** in nines and the **latency** budget (p95/p99).
- Establish the **read:write ratio** — it decides caching and replication strategy.
- Call out **security** concerns early (e.g. predictable sequential IDs are guessable — a session-01 miss).

---

## ③ Envelope Estimation

**Goal:** size the system with rough numbers so the design provably fits the scale. → full method in [back-of-the-envelope estimation](../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md) and [worked examples](../concepts/01-envelope-estimation/back-of-the-envelope-examples.md).

**Estimate (label units at every step):**
- **Latency (read/write):** target p95/p99; where the budget is spent (cache hit vs DB vs cross-region).
- **Throughput:** `Avg QPS = DAU × actions/user/day ÷ 86,400`; `Peak ≈ 2 × Avg`. Do reads and writes separately.
- **Storage:** `writes/day × size/write × retention × replication (×3)`.
- **Bandwidth:** `QPS × payload size` — network in **bits**, storage in **bytes** (`1 Gbps = 125 MB/s`).
- **Compute:** `servers ≈ peak QPS ÷ per-server QPS`, then add redundancy headroom.

**Reusable constants:** `1 day ≈ 10^5 s` · `Peak ≈ 2× Avg` · `×3` replication · `1 byte = 8 bits`.

> Every number must force a decision (shard vs single DB, CDN vs origin, blob store vs filesystem). A figure with no consequence is incomplete.

---

## ④ Sketch the System Architecture

**Goal:** a high-level blueprint you and the interviewer agree on before going deep.

**Produce:** a box diagram — `client → LB / API gateway → services → cache → data store`, plus CDN / message queue / analytics pipeline as needed.

**Checklist:**
- Draw the **major components** and the **data flow** (arrows) for one end-to-end use case.
- **Label every arrow** with the data passed and the protocol (HTTP / gRPC / async) — a session-01 gap.
- Put **API signatures** on the canvas: `POST /urls {longUrl} → 201 {shortUrl}`.
- Sanity-check the blueprint against the ③ estimates; get explicit buy-in before drilling down.

---

## ⑤ Walk Through the System Design

**Goal:** trace the critical flows end to end and detail the important components.

**Walk both paths:**
- **Write path:** request → gateway → service → key generation → persist → response.
- **Read path:** request → gateway → service → cache lookup → (miss →) data store → populate cache → response.

**Detail each concern:**
- **Component responsibilities** and how they interact.
- **Data storage & retrieval:** SQL vs NoSQL vs blob, and why.
- **Caching strategy:** cache-aside vs write-through, **eviction (LRU/LFU/TTL)**, invalidation.
- **Load balancing:** L4/L7, health checks, routing.
- **Fault tolerance:** replication, **leader-election failover**, retries/idempotency, graceful degradation.
- **Scaling the critical component:** partitioning / **consistent hashing** for distributed cache or DB.

> Go deep where it's interesting (e.g. key generation: hashing + collision handling vs **base62 of a counter** vs pre-generated key pools). Watch the clock — don't over-detail one box.

> As each component comes up here — database, cache, queue, notification, gateway, CDN, connection tier — check its row in [**Component Checklists**](#component-checklists--what-to-say-every-time-this-component-appears) so you state the specific property, not just the component's name.

---

## ⑥ Data Model

**Goal:** a schema that supports the use cases from ① and the analytics from ②.

**Checklist:**
- **Schema design:** tables/collections with key fields and types.
- **Relationships:** entities and how they relate (1:1, 1:N, N:M).
- **Indexing strategy:** which fields are indexed and which queries they serve.
- **Design for the use cases:** if analytics is required, include fields for it (click count, user agent, referrer, timestamp) — a session-01 miss.
- Note **hot vs cold** data and how it's stored/tiered.

---

## ⑦ Trade-offs and Alternatives

**Goal:** show senior-level judgment — that you chose deliberately among options.

**For each major decision, use the pattern:**
> *"Option A does X but has drawback Y; Option B trades Z; I'd choose ___ because ___."*

**Checklist:**
- **Trade-offs made:** e.g. read replicas → **replication lag**; state *when* it's unacceptable and the mitigation (read-your-writes, route critical reads to primary).
- **Alternatives considered:** name 2–3 approaches even if not implemented.
- **Pros/cons** of each — consistency vs availability, cost vs latency, simplicity vs flexibility.

---

## ⑧ Testing and Monitoring

**Goal:** show the design is operable in production (great use of the wrap-up minutes).

**Checklist:**
- **Testing:** unit / integration / load tests; how you'd validate the ③ throughput targets.
- **Monitoring & alerting:** dashboards, SLO-based alerts, on-call runbooks.
- **Metrics to track:** latency (p95/p99), error rate, QPS, cache hit ratio, replication lag, queue depth, storage growth.
- **Wrap-up extras:** recap the design, name the top **bottleneck**, and describe handling the **next 10× of scale** and key **failure modes**.

---

## Component Checklists — what to say, every time this component appears

**Why this section exists:** across the logged sessions in `practice/README.md`, the recurring pattern isn't "forgot the component" — it's **named the component, then skipped one specific property of it**, over and over, on different problems. A cache gets drawn but never gets an eviction policy; a Kafka topic gets drawn but never gets a partition/consumer number; a database gets drawn but its category and sharding key are never named. This section is a per-component reference: whenever one of these shows up on the canvas, run its checklist before moving on. Each row cites the session(s) that lost points for skipping it, so the cost of skipping it is visible, not abstract.

### Database (any kind)

| Say this | Why | Evidence |
|---|---|---|
| **Category** — relational / wide-column NoSQL / document / graph / time-series / in-memory KV / search index / object storage, **and why that category fits the access pattern** | "We'll use a database" names nothing; the category is the decision | `practice/GUIDELINES.md`'s Storage-choices requirement; see [S13](./13-session/README.md#storage-choices--which-engine-for-which-store) for the worked example |
| **The crux table**, drawn *upfront*, with its state machine if it has one | Missed/partial in 8 of the first 10 sessions, interviewer-flagged repeatedly | Recurring Action Item #2; [databases](../concepts/05-databases-and-storage/databases-fundamentals.md) |
| **Where the crux data actually lives** — RAM, an append-only log, or a row in a DB — not just "it's stored" | S10 put an in-memory-only order book in a database matched by a worker; S11 fixed it by stating the medium explicitly | [write-ahead log](../concepts/08-distributed-systems/write-ahead-log-and-durable-ingestion.md) |
| **Sharding/partitioning key**, checked against the schema you actually drew | S13 sharded by `conversation_id` on a schema that didn't have that column | [sharding & partitioning](../concepts/05-databases-and-storage/sharding-and-partitioning.md) |
| **Replication** for read scaling, and its consistency cost (replication lag) | S01's "created it but the read replica hasn't caught up" bug | [consistency models](../concepts/08-distributed-systems/consistency-models.md) |
| **Consistency stated per path** (CP write / AP read), not left implicit | S04/S10/S11 did this; S12/S13 didn't, despite having several distinct consistency needs | [consistency models](../concepts/08-distributed-systems/consistency-models.md) |
| **The hot key/partition**, sized explicitly — not just aggregate QPS | S04 (hot auction), S07 (hot client), S10 (hot stock) all missed this | [sharding & partitioning](../concepts/05-databases-and-storage/sharding-and-partitioning.md) |
| **Connection pooling** between stateless callers and the datastore | S17 scaled services horizontally but never named how each instance talks to the DB efficiently | [Databases — Scaling](../concepts/05-databases-and-storage/databases-scaling.md) |
| **Indexing strategy** for the queries you actually described | Generic "we'll add indexes" with no named field/query pairing is half-credit | [databases](../concepts/05-databases-and-storage/databases-fundamentals.md) |

### Cache

| Say this | Why | Evidence |
|---|---|---|
| **Strategy** — cache-aside / write-through / write-back, named explicitly | S06 added a cache with no strategy, asked twice before answering | [caching](../concepts/06-caching/caching.md) |
| **Eviction policy** — LRU / LFU / TTL | Flagged in S01/S02/S03 | [caching](../concepts/06-caching/caching.md) |
| **Invalidation rule** — invalidate-on-write, with TTL as the backstop | Recurring Action Item; S06 | [caching](../concepts/06-caching/caching.md) |
| **The staleness window**, and when it's unacceptable | S01 — route a user's own writes to primary or the replica that has them | [consistency models](../concepts/08-distributed-systems/consistency-models.md) |
| **Hot-key handling** — shard by key, name the hot shard, don't just "add more nodes" | S07 | [caching](../concepts/06-caching/caching.md) |
| **Is the cached state ephemeral-and-rebuildable, or does it need a durable backstop** | S07 put a DB *behind* an ephemeral counter (wrong direction); S16/S17's window state is correctly ephemeral, rebuilt from the stream if lost | [Redis ZSET](../concepts/06-caching/redis-sorted-sets.md) |

### Message Queue / Kafka (or any async broker)

| Say this | Why | Evidence |
|---|---|---|
| **Partitioning key**, and the ordering-vs-parallelism trade-off it makes | S08's key evolved geographic → sender → conversation, each step motivated by read pattern — the senior signal | [message queue](../concepts/07-messaging-and-events/message-queue.md) |
| **Consumer scaling math** — an actual partition/consumer count against a throughput number, not "it scales horizontally" | S14 had 100–200 rps on the canvas and never extended it — the exact thing asked for | [Databases — Scaling](../concepts/05-databases-and-storage/databases-scaling.md) |
| **Delivery semantics** — at-least-once vs. exactly-once, and the idempotent-consumer fix that makes at-least-once safe | S08/S09 stopped at "Kafka is at-least-once" without the per-recipient dedup cursor | [write-ahead log](../concepts/08-distributed-systems/write-ahead-log-and-durable-ingestion.md) |
| **Retry policy with a stated terminal case** — retry-then-dead-letter-queue + alert, not an open-ended retry loop | S12's heartbeat-reassignment had no answer for a task that keeps failing | Recurring Action Item #17; [message queue](../concepts/07-messaging-and-events/message-queue.md) |
| **Topic isolation** by provider/tenant/priority, when traffic classes genuinely differ | S14 isolated by provider but not by urgency (OTP vs. marketing blast sharing a queue) | [message queue](../concepts/07-messaging-and-events/message-queue.md) |
| **Consumer lag** named as a monitored signal | S17, S12 | [Observability](../concepts/09-reliability-and-operations/observability.md) |

### Notification / any external API call (PagerDuty, Slack, email, payment provider, etc.)

| Say this | Why | Evidence |
|---|---|---|
| **Delivery guarantee + idempotency key on the send** — so a redelivered event can't double-notify / double-charge | S17 never raised this until asked at the very end | [write-ahead log](../concepts/08-distributed-systems/write-ahead-log-and-durable-ingestion.md) |
| **Circuit breaker + retry + fallback** per external dependency | Reused cleanly across S08/S12/S14; name it as a reflex for *any* external call | [Resilience Patterns](../concepts/09-reliability-and-operations/resilience-patterns.md) |
| **Dedup against open/unresolved state** before firing another notification | S17's alert-dedup fix | — |
| **Credentials by reference**, not raw storage (a secrets manager, not a plaintext column) | S17 schema note | [API Security](../concepts/04-apis/api-security.md) |
| **PCI/payment-data scope** named explicitly if money moves — tokenize via the provider, idempotency key per charge | Untouched in S03 and S04 both | [API Security](../concepts/04-apis/api-security.md) |

### Load Balancer / API Gateway

| Say this | Why | Evidence |
|---|---|---|
| **L4 vs L7**, health checks, routing | Baseline, rarely scored but expected | [Load Balancing & Consistent Hashing](../concepts/03-networking-and-delivery/load-balancing-and-consistent-hashing.md) |
| **Rules are data, in a config store** — multi-tier/per-endpoint limits, hot-reloadable, not one hard-coded global limit | S07 hard-coded one limit | [databases](../concepts/05-databases-and-storage/databases-fundamentals.md) |
| **Per-tenant isolation**, on any multi-tenant system — not just abuse protection, noisy-neighbor protection | S17 framed rate limiting as DoS-only, never as tenant fairness | [Non-Functional Requirements](../concepts/02-foundations/non-functional-requirements.md) |

### CDN

| Say this | Why | Evidence |
|---|---|---|
| **The egress number that makes it load-bearing**, not a nicety | S05 — a media platform's egress is in Gbps; say so explicitly | [CDN](../concepts/03-networking-and-delivery/cdn.md) |
| **Cache eviction/promotion rule**, not a bare view-count threshold | S12 — one-directional threshold never demotes a faded-popularity item | [CDN](../concepts/03-networking-and-delivery/cdn.md) |
| **Wired into the actual read path on the diagram**, not drawn and orphaned | S05 drew the CDN, never connected it | [CDN](../concepts/03-networking-and-delivery/cdn.md) |

### Real-Time / WebSocket / Connection Tier

| Say this | Why | Evidence |
|---|---|---|
| **The concurrent-connection count**, sized explicitly — it's the number that actually designs the system | S08 sized QPS and storage but never ~1M+ connections; S09 computed it | [Real-Time Communication](../concepts/04-apis/realtime-communication.md) |
| **Presence registry** (`user_id → gateway_id`) + per-gateway pub/sub for routing | S08's core unsolved miss; S09 landed it | [Real-Time Communication](../concepts/04-apis/realtime-communication.md) |
| **The fan-out model, named** — push / pull / hybrid | Unnamed across S06, S08, S09, S10; S11 named it | [Real-Time Communication](../concepts/04-apis/realtime-communication.md) |
| **Failover = reconnect → re-register → sync from cursor**, and connection draining on a planned shutdown | S09 got reconnect-resume; draining stayed open | [Real-Time Communication](../concepts/04-apis/realtime-communication.md) |

### Object / Blob Storage

| Say this | Why | Evidence |
|---|---|---|
| **Lifecycle/tiering policy** — hot → cold, with the triggering condition | S05, S12 | [Object / Blob Storage](../concepts/05-databases-and-storage/object-blob-storage.md) |
| **Direct-serve vs. CDN-in-front**, decided by access-pattern/popularity | S12 | [CDN](../concepts/03-networking-and-delivery/cdn.md) |

### Rate Limiter (as a component inside a larger design)

| Say this | Why | Evidence |
|---|---|---|
| **The algorithm, named** — token bucket / sliding-window counter / sliding-window log / fixed window, with its trade-off | S07 named neither | [concurrency control](../concepts/08-distributed-systems/concurrency-control.md) |
| **Atomic `INCR`/Lua in the store** — never app-side read-modify-write | S07's unsolved counter race | [concurrency control](../concepts/08-distributed-systems/concurrency-control.md) |

### Search / Full-Text Index

| Say this | Why | Evidence |
|---|---|---|
| **The sync pipeline, named** — CDC / dual-write into the index, not "add Elasticsearch later" | S05 left it at heading-match | [Full-Text Search](../concepts/05-databases-and-storage/full-text-search.md) |
| **Matches the real query shape** (geo, multi-attribute, relevance) and says why | S15 | [Full-Text Search](../concepts/05-databases-and-storage/full-text-search.md) |

### Background Worker / Async Pipeline

| Say this | Why | Evidence |
|---|---|---|
| **A state machine for the job** (`queued → processing → ready/failed`) | S12's `video_rendition` state machine went undrawn | [databases](../concepts/05-databases-and-storage/databases-fundamentals.md) |
| **Heartbeat + reassignment, plus the terminal case** — retry-then-dead-letter + alert | S12 reassigned a dead worker's task but never said what happens after N failures | Recurring Action Item #17 |

### Monitoring & Observability (cross-cutting — say this for *every* design, not one component)

| Say this | Why | Evidence |
|---|---|---|
| **Named, concrete signals** — queue depth, consumer lag, cache hit ratio, error rate per dependency, replication lag — never the bare word "monitoring" | S10 never raised it; S12 built a real pipeline and still never named a metric until asked | Recurring Action Item #16; [Observability](../concepts/09-reliability-and-operations/observability.md) |
| **Said proactively**, before the interviewer asks for it | Same sessions — it was always prompted, never volunteered | [Observability](../concepts/09-reliability-and-operations/observability.md) |

---

## Blank template (copy into each practice attempt)

```
Problem: ________________________________________________

① Functional requirements
   - core ops / APIs:
   - in scope / out of scope:

② Non-functional (Availability · Scalability · Reliability · Performance · Security)
   - availability (nines):        latency (p95/p99):
   - read:write ratio:            security notes:

③ Envelope estimation
   - QPS (write / read):          storage/yr (×3):
   - bandwidth:                   servers (peak ÷ per-server):

④ Architecture sketch
   - components + data flow (labeled arrows, API signatures):

⑤ Walkthrough
   - write path:                  read path:
   - storage · cache(+eviction) · LB · fault tolerance · scaling(consistent hashing):

⑥ Data model
   - schema / relationships / indexes / analytics fields:

⑦ Trade-offs & alternatives
   - decision → option A vs B → chosen because:

⑧ Testing & monitoring
   - tests · metrics (p95, error rate, cache hit, lag) · bottleneck · next 10×:
```
