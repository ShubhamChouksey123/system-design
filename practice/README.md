# Senior System Design Mock Interviews — Scored & Analyzed

> Real system-design **mock interviews** for **senior software engineer** prep — each with the problem, the design produced (with diagrams), the interviewer's **/10 scorecard**, and a gap-by-gap breakdown of **exactly what lost points and how to fix it.**

Every `NN-session/` folder is a **standalone analyzed write-up** ([`README.md`](./01-session/README.md)) backed by the **raw transcript** (`script.md`). This page rolls them up so recurring weak spots turn into a study plan.

📣 **Rehearsal tools:** pin the [Opening Ritual drill card](./opening-ritual.md) — the fixed opening sequence you run before every mock — work through the [Answer Framework playbook](./answer-framework.md) — the 8 steps to cover in every answer — and run the [framework's in-the-room checklist](../concepts/00-framework/system-design-interview-framework.md#4-in-the-room-checklist-quick-reference) as a dry-run before each mock. The **concurrency / write-path reflex** is the confirmed #1 weak spot on write-first problems; the two misses that recur on *every* problem are **capacity estimation** (5 of 5) and a **drawn data model** (4 of 5) (see [How to Improve](#how-to-improve)).

---

## Sessions

Scores are **/10** across the mock platform's five axes. Verdict: ✅ Pass (≥ 7) · ⚠️ Borderline (5.5–6.9) · ❌ Needs work (< 5.5).

| # | Problem | Type | Verdict | Req. | Design | Prob-Solving | Scale & Trade-offs | Comm. | Overall |
|---|---------|------|---------|:----:|:------:|:------------:|:------------------:|:-----:|:-------:|
| [01](./01-session/README.md) | URL shortener (bit.ly / TinyURL) | Read-heavy KV store + analytics | ⚠️ Borderline | 6.0 | 6.0 | 6.5 | 5.5 | 5.5 | **5.9** |
| [02](./02-session/README.md) | Basic e-commerce platform | Listings + cart + payments; delivery-first | ⚠️ Borderline | 7.0 | 7.0 | 7.0 | 6.0 | 6.0 | **6.6** |
| [03](./03-session/README.md) | Basic e-commerce platform *(re-solve of 02)* | Same prompt, after drilling S02 gaps | ⚠️ Borderline *(Lean Hire)* | 7.0 | 7.0 | 6.0 | 6.0 | 6.0 | **6.5** |
| [04](./04-session/README.md) | Online auction system (eBay-style) | Concurrent bidding + real-time fan-out at scale | ❌ Needs work | 6.5 | 6.0 | 5.0 | 5.0 | 6.0 | **5.5** |
| [05](./05-session/README.md) | Online learning platform (Udemy/Coursera-style) | Read-heavy video delivery + progress tracking + forum | ⚠️ Borderline *(Lean Hire)* | 7.0 | 7.0 | 6.0 | 7.0 | 6.0 | **6.5** |

**Related concepts**: [Estimation](../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md) (01, 04, 05) · [Interview Framework](../concepts/00-framework/system-design-interview-framework.md) (01) · [Load Balancing & Consistent Hashing](../concepts/03-networking-and-delivery/load-balancing-and-consistent-hashing.md) (01, 03) · [AuthN & AuthZ](../concepts/04-apis/authentication-and-authorization.md) (02) · [Caching](../concepts/06-caching/caching.md) (02, 03, 05) · [Redis Sorted Sets (ZSET)](../concepts/06-caching/redis-sorted-sets.md) (04) · [Real-Time Communication](../concepts/04-apis/realtime-communication.md) (04) · [Message Queue](../concepts/07-messaging-and-events/message-queue.md) (04, 05) · [CDN](../concepts/03-networking-and-delivery/cdn.md) (03, 05) · [Object / Blob Storage](../concepts/05-databases-and-storage/object-blob-storage.md) (05) · [Full-Text Search](../concepts/05-databases-and-storage/full-text-search.md) (05) · [Concurrency Control](../concepts/08-distributed-systems/concurrency-control.md) (04, 05) · [API Security](../concepts/04-apis/api-security.md) (03, 04) · [Consistency Models](../concepts/08-distributed-systems/consistency-models.md) (02, 03, 04, 05) · [Databases](../concepts/05-databases-and-storage/databases-fundamentals.md) (03, 04, 05) · [Monolith vs Microservices](../concepts/02-foundations/monolithic-vs-microservices.md) (02)

---

## Session write-ups

Each session has a full **analyzed page** — problem, design + diagram, scorecard, and gap-by-gap fixes.

### [01 — URL Shortener (bit.ly / TinyURL)](./01-session/README.md) · ⚠️ 5.9/10

Read-heavy KV store + click analytics. **Strong:** throughput estimation, cache-aside, DB failover, async analytics. **Lost points on:** key-generation depth (base62 / predictable-ID security), HTTP **3xx** redirect semantics, and reaching for **consistent hashing** without prompting. → **[Read the full write-up →](./01-session/README.md)**

### [02 — Basic E-commerce Platform](./02-session/README.md) · ⚠️ 6.6/10

Listings + cart + payments for small businesses; delivery-first, scale deprioritized. **Strong:** pragmatic requirements trade-off, monolith-first instinct, clean REST design, **failure handling** (pending-status + async reconciliation), and sound bottleneck reasoning (read replicas, replication lag, webhook, SSE). **Lost points on:** no **data model / schema**, no **security / auth** (buyer vs seller), no **caching or CDN** for a read-heavy catalog, a **stale diagram**, and the missed **concurrent-last-unit** edge case. Interviewer's own verdict was **FAIL** — the silent senior axes sank it. → **[Read the full write-up →](./02-session/README.md)**

### [03 — E-commerce Platform (Re-attempt of S02)](./03-session/README.md) · ⚠️ 6.5/10

**Same prompt as S02, re-solved after drilling the gaps** — the clearest progress signal so far. **What closed:** the blind spots that failed S02 all appeared *unprompted* — estimation numbers (5k users, 100:1, ~1000 RPS), a **drawn data-model schema**, **Redis caching** + invalidation, a **CDN** for images, and an **auth module** with buyer/seller authZ. That flipped the interviewer's verdict **FAIL → Lean Hire**. **What survived:** the **concurrent-last-unit race** was missed *again* (Problem-Solving dropped 7 → 6), no **Orders** table (only Payments), **payment-data / PCI security** untouched, and the diagram went from *stale* to *cluttered*. → **[Read the full write-up →](./03-session/README.md)**

### [04 — Online Auction System (eBay-style)](./04-session/README.md) · ❌ 5.5/10

**First brand-new problem since the S02/S03 re-solves — and the lowest score yet.** Without a rehearsed checklist to lean on, a problem whose *entire point* is concurrency and shared state exposed the two weakest axes head-on: **Problem-Solving and Scale both fell to 5.0**. **What went wrong (three wrong mental models):** thought an auction is **fixed ~5 re-bidding rounds** (it's one hard `end_time`, highest wins); planned to **save all bids and pick the max after the timer** (bid integrity means checking against the current highest *at write time*); wanted to keep the highest bid in an **in-memory max-heap** (lost on crash, diverges across N servers). **The recurring misses returned:** no **Orders** table, no **payment-data / PCI**, a **cluttered diagram** — now 2+ sessions each. **The new gap:** estimation sized daily users but **never the hot auction** (bids/sec on one row, concurrent viewer connections). **What held:** clean service split, reconcile-job backstop, wallet pre-validation, primary-replica failover, and the correct consistency-over-availability call. **Key fixes:** atomic conditional UPDATE / single-writer-per-auction · **Redis ZSET** + append-only bids log · **SSE + pub/sub** to decouple watchers from bid throughput · guarded exactly-once close. → **[Read the full write-up →](./04-session/README.md)**

### [05 — Online Learning Platform (Udemy/Coursera-style)](./05-session/README.md) · ⚠️ 6.5/10

**A rebound after S04 — 5.5 → 6.5 (Lean Hire), and the drilled read-path instincts finally showed up *unprompted*.** **What went well:** **CQRS** (read/write split for courses *and* forum), **event-driven progress tracking** with Kafka (+ correct consumer-durability reasoning), **cache-aside + invalidation**, **CDN for video**, stateless→horizontal scaling, and a crisp **read-your-writes** answer for replica lag — **Scale jumped 5.0 → 7.0**. **What still held it to Lean Hire:** the *same recurring pair* — **no capacity estimation** (S01/S04/S05) and **no data model** (S01/S02/S04/S05, interviewer-flagged again) — plus three domain-specific gaps: **video streaming never explained end-to-end** (no transcoding / HLS-DASH / adaptive bitrate — the heart of the problem), **progress modeled as a lossy Kafka→analytics stream** instead of an idempotent user-facing write, and **search left shallow** (no indexing/CDC). Also needed **prompting** to reach the replication-lag and stale-cache edge cases, and the **CDN was drawn but not wired** to the video path. **Key fixes:** open with storage + egress numbers · draw the `progress` table (upsert on `(student, lesson)`) · transcode → segment (HLS/DASH) → CDN → ABR · authoritative progress write + *derived* analytics · CDC → Elasticsearch. → **[Read the full write-up →](./05-session/README.md)**

---

## Consolidated Tips

Grouped by the axis interviewers score, weakest axis first. Session tags like `[S01]` mark the source; a repeat across sessions is a priority to drill. Per-axis score history is shown so trends are visible.

### Problem Solving — `6.5 → 7.0 → 6.0 → 5.0 → 6.0` (recovered in S05 · still holds the #1 recurring miss)
- **Hunt the concurrency edge case — the confirmed #1 recurring miss, now three sessions running.** Missed as an *edge case* in S02/S03 (two buyers grab the last unit); in **S04 it was the *entire problem*** and still never made concrete — I said "grab a lock," then switched to "save all bids, pick the max later." Make it reflexive: enforce the invariant *at write time* via an **atomic conditional update** (`UPDATE … WHERE current_price < :bid`, check rows-affected), a **row lock**, an **optimistic version check**, or a **single writer per partition** (`auction_id`). `[S02]` `[S03]` `[S04]` → [concurrency control](../concepts/08-distributed-systems/concurrency-control.md)
- **Distributed shared state lives in a shared store, never process memory.** S04's in-memory **max-heap** for the highest bid is lost on a crash and diverges across N service instances. Any "track the highest/latest X across servers" → **Redis ZSET + an append-only durable log** to rebuild from. `[S04]` → [Redis ZSET](../concepts/06-caching/redis-sorted-sets.md)
- **Offer 2–3 options before committing, then commit.** S04 *flip-flopped* — lock → save-all-and-pick → SSE-vs-polling — and landed decisions on none. Name the options and their trade-offs, then pick one and defend it. `[S01]` `[S04]`
- **Model the domain before the mechanism.** S04's "fixed ~5 rounds" detour came from not knowing how an auction actually *ends* — one `end_time`, highest bid wins. Understand termination/state before designing the machinery. `[S04]`
- **Surface edge cases *before* being asked.** S05 had the right answers for **replication lag** and **stale cache** — but only *after* the interviewer dug. Volunteer "here's the consistency risk and my mitigation" proactively; being self-driven on edge cases is the gap between Lean Hire and Hire. `[S05]`
- **Don't reconstruct authoritative state from a lossy analytics stream.** S05 modeled a student's own progress as a Kafka read-event → Analytics, making their progress bar eventually consistent (then patched with client-side optimism). User-facing state = a direct **idempotent write**; derive dashboards/analytics *from* the truth, never the reverse. `[S05]` → [concurrency control](../concepts/08-distributed-systems/concurrency-control.md)
- Keep leading with estimation, async-decoupling, and **failure-recovery** instincts — the pending-status + async reconciliation in S02 landed well. *(S03 note: the webhook-never-arrives fallback was stronger in S02 — don't let it slip on re-solves.)* `[S01]` `[S02]`

### Scalability & Trade-offs — `5.5 → 6.0 → 6.0 → 5.0 → 7.0` (▲ rebounded to strongest — read-path scaling reflexes landed unprompted)
- **Size the hot key, not the aggregate.** S04 estimated daily users (1M → 10k → 1k) but **never the hot auction** — bids/sec on one row in the final seconds, and concurrent live-viewer connections. Those size the write path and the fan-out layer; daily-user totals don't. Frame the **hot-key / hot-partition** explicitly. `[S04]` → [estimation](../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md)
- **Split consistency per path.** S04 correctly chose consistency for money but didn't *split* it: **write path → CP** (reject an invalid bid), **browse/watch path → AP** (a price stale by a second is fine, the live layer corrects it). Naming the split is the senior signal. `[S04]` → [consistency models](../concepts/08-distributed-systems/consistency-models.md)
- **Decouple fan-out from write throughput.** A celebrity auction's 50k *watchers* must add zero load to the bid *writer* — **pub/sub + a stateless connection tier** absorb watchers via more connection servers + read replicas, never by touching the serialization point. `[S04]` → [message queue](../concepts/07-messaging-and-events/message-queue.md)
- **Reach for the standard scaling tool directly** — for a distributed cache/DB that's **consistent hashing**; don't detour through vertical scaling first. `[S01]`
- **Don't stop at bottleneck #1.** S03 added replicas + cache but stalled there — name the *next* bottlenecks: **horizontal backend scaling** behind the LB, **DB sharding**, **rate limiting** at the gateway, connection pooling. `[S02]` `[S03]`
- When you state a trade-off (e.g. replication lag), also state **when it's unacceptable** and the mitigation (read-your-writes, route critical reads to primary). `[S01]` `[S02]`
- **Cache-consistency reasoning landed** — write-DB-first-then-cache + backoff retry for eventual consistency was a solid, defended choice. Keep pairing the strategy with its staleness window. `[S03]` → [caching](../concepts/06-caching/caching.md)
- **The read-heavy scaling stack is now a reflex** — S05 reached for cache-aside + invalidation, read replicas, CDN, and stateless→horizontal scaling *unprompted* (drove Scale 5.0 → 7.0). Keep it, and for **media platforms make the CDN load-bearing**: egress is Gbps, so the CDN must carry ~95%+ of bytes — say that explicitly, don't leave it as a nicety. `[S05]` → [CDN](../concepts/03-networking-and-delivery/cdn.md)

### Communication — `5.5 → 6.0 → 6.0 → 6.0 → 6.0` (⚠️ dead flat four sessions — now the most stubborn low)
- **The diagram is the artifact the interviewer reads — keep it live *and* legible.** S02 lost points for a *stale* diagram; S03/S04 for a *cluttered* one; **S05 drew the CDN but never connected it to the video read path**. Four sessions of diagram notes now: separate **read vs write flows**, color per journey, space components, and **wire every box you draw** — an unconnected component reads as "named but not understood." `[S02]` `[S03]` `[S04]` `[S05]`
- **Structure every answer**: *decision → why → trade-off.* Cut repetition — say each point once. `[S01]` `[S02]`
- **Front-load requirements as a visible checklist** on the canvas, split into functional / non-functional / analytics, before designing. `[S01]`
- **Label diagrams**: every arrow gets its data + protocol (HTTP/gRPC/async); put API signatures on the canvas, e.g. `POST /urls {longUrl} → {shortUrl}`. `[S01]`
- Be concise and direct; a short pause beats filler while you think. `[S01]` `[S02]`

### Design Skills — `6.0 → 7.0 → 7.0 → 6.0 → 7.0` (recovered — but the schema is still missing 4 of 5 sessions)
- **Always draw the data model** — schema + keys + any state machine. Missing in S01, S02, S04, and **S05** (interviewer-flagged again); only **S03 drew it** — 4 of 5 sessions now. Non-negotiable. For S05 the crux box is the **`progress` table (upsert on `(student_id, lesson_id)`)**; more generally, **model Orders / order_items separately from Payments** (payment ≠ order — missed in S03 and S04). `[S01]` `[S02]` `[S03]` `[S04]` `[S05]` → [databases](../concepts/05-databases-and-storage/databases-fundamentals.md)
- **Know the media pipeline cold on any content/video problem.** S05 said "chunk the video into S3" but never explained *why*: upload (pre-signed URL) → **transcode to bitrate renditions** → **segment (HLS/DASH)** → CDN → **adaptive bitrate** playback. That end-to-end path is the domain depth that separates Lean Hire from Hire on a media system. `[S05]` → [object / blob storage](../concepts/05-databases-and-storage/object-blob-storage.md) · [CDN](../concepts/03-networking-and-delivery/cdn.md)
- **Say how search stays current** — don't stop at "add Elasticsearch later." S05 left it at heading-match; name the pipeline: **CDC / dual-write → Elasticsearch**, index title + body + tags, query with relevance ranking. `[S05]` → [full-text search](../concepts/05-databases-and-storage/full-text-search.md)
- **Close the last silent senior box: payment-data / PCI.** Untouched in **both S03 and S04** — tokenize via the provider (Stripe), never store raw card data, and put an **idempotency key** on each charge so a retry can't double-bill. `[S03]` `[S04]` → [API Security](../concepts/04-apis/api-security.md)
- **Cover the silent senior axes unprompted** — **security/auth**, **caching**, **CDN**. Their *absence* failed S02; **S03 surfaced all three** and flipped the verdict. `[S02]` `[S03]` → [AuthN & AuthZ](../concepts/04-apis/authentication-and-authorization.md) · [caching](../concepts/06-caching/caching.md) · [CDN](../concepts/03-networking-and-delivery/cdn.md)
- **Commit to one real-time strategy: persistent connections + pub/sub fan-out.** S04 oscillated SSE-vs-polling under pressure. Default to **SSE** (one-way server→client) unless the *client* must push frequently (then WebSocket). `[S04]` → [real-time communication](../concepts/04-apis/realtime-communication.md)
- **Exactly-once on schedulers** — guarded status transition (`OPEN→CLOSING→CLOSED`) + idempotent close; always ask "what if the scheduler fires twice / crashes mid-task?" `[S04]` → [message queue](../concepts/07-messaging-and-events/message-queue.md)
- **Go deep on key generation** — hashing (collision handling), base62 of a counter, pre-generated key pools, and the **security implication of predictable IDs**. `[S01]`
- Know **cache eviction/invalidation**: LRU/LFU, TTL, and how expired/updated entries leave the cache. `[S01]` `[S02]` `[S03]` → [caching](../concepts/06-caching/caching.md)
- **Justify a service split** by independent scaling / blast-radius / different access patterns — or defend staying monolith. `[S02]` `[S03]` `[S04]` → [monolith vs microservices](../concepts/02-foundations/monolithic-vs-microservices.md)

### Requirements Gathering — `6.0 → 7.0 → 7.0 → 6.5 → 7.0` (held — but estimation is still the recurring hole)
- **Nail scale numbers early** (read:write ratio, QPS, storage/retention) — *and the hot-key number.* S03 nailed the aggregates; **S04 missed the hot auction**; **S05 produced no numbers at all** for a video platform. For content/media, **storage + egress bandwidth *are* the argument** for S3 + CDN + transcoding — size them or the "why" stays implicit. Ask "what's the *hottest* unit of load, not just the average?" `[S01]` `[S02]` `[S03]` `[S04]` `[S05]` → [estimation](../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md)
- **Explore every stated requirement upfront**, especially ones the prompt names explicitly (analytics; "bid integrity") — don't leave them to the end. `[S01]` `[S04]`
- **Make the constraint an explicit trade-off** — "delivery over scale, so monolith-first" was a strong, defensible move; keep verbalizing the *why*. `[S02]` `[S03]`
- **Surface user roles / auth in scoping** — "who are the actors and what can each do?" (buyer vs seller) is a requirements question, not just a security one. `[S02]` `[S03]`

---

## Recurring Action Items

*Ordered by how stubborn the miss is. #1–#2 are the standouts — they cost points on **every** problem regardless of type; #3 is the write-first standout that *was* the whole problem in S04.*

1. **Always open with capacity estimation — the most consistent miss (5 of 5 sessions).** Even the well-handled S05 produced no numbers. Before designing: DAU / concurrent users, read:write, QPS, and for content/media **storage + egress bandwidth** (they're the argument for S3 + CDN + transcoding). → [estimation](../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md)
2. **Always draw the data model (missed 4 of 5) — interviewer-flagged twice.** Schema + keys + any state machine. Pick out the *crux* table for the problem (S05: `progress`, upsert on `(student, lesson)`; e-commerce/auction: `orders` separate from `payments`). → [databases](../concepts/05-databases-and-storage/databases-fundamentals.md)
3. **Hunt the concurrency edge case — the #1 recurring miss on write-first problems.** Missed as an edge case in **S02/S03** (last-in-stock race), then in **S04 it was the entire problem**. Enforce the invariant *at write time*: **atomic conditional update** (`UPDATE … WHERE current < :new`, check rows-affected), row lock, optimistic version, or **single writer per partition**. Reflex on any stock / bid / counter / booking design. → [concurrency control](../concepts/08-distributed-systems/concurrency-control.md)
4. **Distributed shared state = a shared store, never process memory.** S04 tried an in-memory max-heap for the highest bid (lost on crash, diverges across instances). Any "highest/latest X across N servers" → **Redis ZSET + append-only durable log**. → [Redis ZSET](../concepts/06-caching/redis-sorted-sets.md)
5. **Go deep on the domain-defining component.** Naming it isn't enough (S05 named the video pipeline, couldn't explain it). Media → transcode → **HLS/DASH** → CDN → **adaptive bitrate**; search → **CDC → Elasticsearch**; write-first → the concurrency guard. → [object / blob storage](../concepts/05-databases-and-storage/object-blob-storage.md) · [full-text search](../concepts/05-databases-and-storage/full-text-search.md)
6. **Separate user-facing state from analytics.** S05 derived a student's progress bar from a lossy Kafka→analytics stream. Authoritative state = a direct **idempotent write**; fan a *copy* to Kafka for dashboards. Never reconstruct truth from the derived stream. → [concurrency control](../concepts/08-distributed-systems/concurrency-control.md)
7. **Add the write/checkout-path items to the opening checklist.** Read-path axes (caching/CDN/auth) are automatic now; extend the ritual with: **"where's the concurrent write, and how do I guard it?"** · **"is there sensitive data (payments/PII), and how is it secured?"** · **"what's the hot key, and what's its peak load?"** → [framework](../concepts/00-framework/system-design-interview-framework.md) Step 1 · [Opening Ritual](./opening-ritual.md).
8. **Model Orders separately from Payments** — add `orders` + `order_items` (line items, qty, price-at-purchase, fulfillment). Missed in **both S03 and S04**. Payment ≠ order.
9. **Close the last silent senior box: payment-data / PCI.** Untouched in **S03 and S04** — **tokenize via the provider, never store raw card data**, add an **idempotency key** per charge, and name PCI-scope reduction as *why* you use an external gateway.
10. **Commit to one real-time strategy: SSE + pub/sub fan-out.** S04 oscillated SSE-vs-polling. Default to SSE (server→client); reach for WebSocket only when the client must also push frequently. Decouple watcher count from write throughput. → [real-time communication](../concepts/04-apis/realtime-communication.md)
11. **Exactly-once on schedulers.** Guarded `OPEN→CLOSING→CLOSED` transition + idempotent close; always ask "what if the scheduler fires twice or crashes mid-task?" → [message queue](../concepts/07-messaging-and-events/message-queue.md)
12. **Surface edge cases proactively + keep the diagram legible *and* fully wired.** Volunteer replication-lag/stale-cache risks before being asked (S05 needed prompting). Diagram notes now 4 sessions: *stale* (S02) → *cluttered* (S03, S04) → **unconnected CDN (S05)** — separate read vs write flows, color per journey, **wire every box you draw**.
13. **Don't stop at bottleneck #1.** After read replicas + cache, name the next ones: **horizontal backend scale** behind the LB, **DB sharding**, **rate limiting** at the gateway, connection pooling.
14. **Study the recurring fundamentals** that cut across problems: **consistent hashing, base62 encoding, HTTP 3xx redirects, cache eviction (LRU/LFU/TTL), sharding/partitioning, load balancing, Redis ZSET.**

---

## How to Improve

### The diagnosis

**S03 proved a habit fix works; S04 proved it isn't enough; S05 shows exactly where the ceiling now sits.** Re-solving S02's problem flipped **FAIL → Lean Hire** as the read-path habits (schema, caching, CDN, auth) appeared unprompted. **S04** — a brand-new *write-first* problem — fell to the **lowest yet (5.5)** because those habits do nothing for on-the-spot write-path reasoning. **S05** — a read-heavy problem — **rebounded to 6.5**: the read-path scaling stack (CQRS, cache + invalidation, CDN, replicas, read-your-writes) fired *unprompted* and drove **Scale 5.0 → 7.0**. So the pattern is now clear: **the drilled habits reliably carry read-heavy problems to Lean Hire, and the remaining points are the same two universal misses plus per-domain depth and proactivity.**

What S05 confirmed (the recurring, problem-independent gaps):

1. **Capacity estimation is missed on every session (5 of 5).** Even on a well-handled problem, S05 produced *no numbers*. For a video platform, storage + egress *are* the architecture argument — their absence left every good component choice (S3, CDN, transcoding) justified only implicitly. This is now the single most consistent hole.
2. **The data model is missed 4 of 5 sessions** — interviewer-flagged *again* in S05. The `progress` table (upsert on `(student, lesson)`) was the crux of the problem and never drawn.
3. **Per-domain depth is the Lean-Hire→Hire lever.** S05 named the video pipeline but couldn't explain it (transcoding, HLS/DASH, adaptive bitrate); search stayed at "Elasticsearch later." On read-heavy problems the scaling reflex is solved — the next points are *going deep on the one component that defines the domain.*
4. **Proactivity + delivery still cost points** — replication-lag and stale-cache answers were correct but only came *when asked*, and the CDN was drawn unconnected (diagram notes now 4 sessions running).

What S04 exposed (still open on write-first problems):

1. **The concurrency reflex is now the confirmed #1 gap — no longer a maybe.** Missed as an *edge case* in S02/S03, it was the *entire problem* in S04 and still never made concrete (I cycled through "lock" → "save all, pick max later" → "not sure how"). It's not a checklist item — it's the instinct to interrogate the write path, and it's the single biggest scoring lever. **Paired failure:** distributed shared state — reaching for an in-memory max-heap instead of a shared store (ZSET) + durable log.
2. **The write/checkout-path silent boxes are still open, now across two sessions** — a **proper Orders model** (records *what was won*) and **payment-data / PCI** (tokenize, idempotency key). The checklist surfaced the read-path senior axes; the write-path ones still aren't automatic.
3. **Delivery is stuck** — the diagram went *stale* (S02) → *cluttered* (S03) → *cluttered again* (S04); the artifact is live but still not legible. Scale regressed because it never even framed the **hot key** (peak bids/sec on one auction, concurrent viewer connections) — it sized daily-user averages instead.

### The plan

- **Make estimation and the schema non-negotiable opening moves** — the two misses that recur on *every* problem (estimation 5/5, schema 4/5). Never start the design without a capacity block (DAU, read:write, QPS, **storage + egress**) and never finish without drawing the tables. These two alone are the difference between Lean Hire and Hire on the read-path problems the habits already carry.
- **Go deep on the one component that defines the domain** — media → video pipeline (transcode → HLS/DASH → CDN → ABR); search → CDC → Elasticsearch; auction → concurrency guard. Pick the defining component and show expert depth rather than naming it and moving on.
- **Drill the concurrency edge case as a reflex** — on every stock / bid / booking / counter problem, force "two clients race for the same thing" and answer it cold: atomic conditional update / row lock / optimistic version / single-writer-per-partition. It's a reflex, not a fact.
- **Internalize distributed shared state** — "highest/latest X across N servers" always means a shared store (Redis ZSET) + an append-only log to rebuild from, never process memory.
- **Add the write-path items to the opening checklist** — after the data model, ask **"where's the concurrent write, and how do I guard it?"**, **"is there sensitive data (payments/PII) — how is it secured?"**, and **"what's the hot key, and what's its peak load?"**
- **Fix diagram legibility once and for all** — separate read vs write flows, color per journey, space components. Three sessions of the same note.
- **Frame scale as the hot key first** — before aggregate QPS, size the hottest single unit of load and design the write path + fan-out around it (pub/sub decouples watchers from writers).
- **Keep re-solving** — the same-problem re-attempt is the clearest progress signal. A re-solve of **S04** targeting *concrete concurrency handling + a clean diagram* is the natural next mock.

> **Implication**: the drilled habits reliably carry read-heavy problems to Lean Hire (S05), and collapse on write-first ones (S04). **The next tier of points splits in two: (a) the two universal misses — capacity estimation and a drawn schema — that cost points on *every* problem regardless of type; and (b) the type-specific depth — concurrency + distributed-state reflex on write-first problems, per-domain component depth (media pipeline, search) on read-heavy ones — plus proactive edge-case surfacing and a legible, fully-wired diagram throughout.** Split practice ~30% estimation + schema as automatic opening/closing moves, ~35% concurrency/write-path reflex, ~20% per-domain depth, ~15% proactive delivery.
