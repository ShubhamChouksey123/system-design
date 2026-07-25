# System Design Interview — Answer Framework (Playbook)

> A step-by-step scaffold for **structuring your answer** to any system design problem. Run it top-to-bottom in the room so nothing important is missed.

**How this relates to the other framework doc:** [`concepts/02-framework`](../concepts/02-framework/system-design-interview-framework.md) is the *behavioral* process — **how** to run the interview (clarify → high-level → deep dive → wrap, collaboration, don'ts). **This** doc is the *content checklist* — **what** to actually cover. Use them together: the 4 phases tell you how to pace the room; the 8 steps below tell you what goes in each phase.

## At a glance — the 8 steps (and where they land in a 45-min interview)

| Phase (from `02-framework`) | Time | Steps to cover here |
|---|---|---|
| 1. Understand & scope | ~3–10 min | ① Functional requirements · ② Non-functional requirements |
| 2. High-level design & buy-in | ~10–15 min | ③ Envelope estimation · ④ Sketch the architecture |
| 3. Design deep dive | ~10–25 min | ⑤ Walk through the design · ⑥ Data model · ⑦ Trade-offs & alternatives |
| 4. Wrap up | ~3–5 min | ⑧ Testing & monitoring (+ recap, bottlenecks, next 10×) |

> **Golden rule:** write requirements and assumptions on the canvas as a **visible checklist** before designing, and **label every diagram arrow** (data + protocol). Both were flagged in [session 01](./README.md#how-to-improve).

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
