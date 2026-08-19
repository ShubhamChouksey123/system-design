# Senior System Design Mock Interviews — Scored & Analyzed

> Real system-design **mock interviews** for **senior software engineer** prep — each with the problem, the design produced (with diagrams), the interviewer's **/10 scorecard**, and a gap-by-gap breakdown of **exactly what lost points and how to fix it.**

Every `NN-session/` folder is a **standalone analyzed write-up** ([`README.md`](./01-session/README.md)) backed by the **raw transcript** (`script.md`). This page rolls them up so recurring weak spots turn into a study plan.

📣 **Rehearsal tools:** pin the [Opening Ritual drill card](./opening-ritual.md) — the fixed opening sequence you run before every mock — work through the [Answer Framework playbook](./answer-framework.md) — the 8 steps to cover in every answer — and run the [framework's in-the-room checklist](../concepts/00-framework/system-design-interview-framework.md#4-in-the-room-checklist-quick-reference) as a dry-run before each mock. Structured delivery is the consistent weak spot (see [How to Improve](#how-to-improve)).

---

## Sessions

Scores are **/10** across the mock platform's five axes. Verdict: ✅ Pass (≥ 7) · ⚠️ Borderline (5.5–6.9) · ❌ Needs work (< 5.5).

| # | Problem | Type | Verdict | Req. | Design | Prob-Solving | Scale & Trade-offs | Comm. | Overall |
|---|---------|------|---------|:----:|:------:|:------------:|:------------------:|:-----:|:-------:|
| [01](./01-session/README.md) | URL shortener (bit.ly / TinyURL) | Read-heavy KV store + analytics | ⚠️ Borderline | 6.0 | 6.0 | 6.5 | 5.5 | 5.5 | **5.9** |
| [02](./02-session/README.md) | Basic e-commerce platform | Listings + cart + payments; delivery-first | ⚠️ Borderline | 7.0 | 7.0 | 7.0 | 6.0 | 6.0 | **6.6** |
| [03](./03-session/README.md) | Basic e-commerce platform *(re-solve of 02)* | Same prompt, after drilling S02 gaps | ⚠️ Borderline *(Lean Hire)* | 7.0 | 7.0 | 6.0 | 6.0 | 6.0 | **6.5** |

**Related concepts**: [Estimation](../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md) (01) · [Interview Framework](../concepts/00-framework/system-design-interview-framework.md) (01) · [Load Balancing & Consistent Hashing](../concepts/03-networking-and-delivery/load-balancing-and-consistent-hashing.md) (01, 03) · [AuthN & AuthZ](../concepts/04-apis/authentication-and-authorization.md) (02) · [Caching](../concepts/06-caching/caching.md) (02, 03) · [CDN](../concepts/03-networking-and-delivery/cdn.md) (03) · [API Security](../concepts/04-apis/api-security.md) (03) · [Consistency Models](../concepts/08-distributed-systems/consistency-models.md) (02, 03) · [Databases](../concepts/05-databases-and-storage/databases-fundamentals.md) (03) · [Monolith vs Microservices](../concepts/02-foundations/monolithic-vs-microservices.md) (02)

---

## Session write-ups

Each session has a full **analyzed page** — problem, design + diagram, scorecard, and gap-by-gap fixes.

### [01 — URL Shortener (bit.ly / TinyURL)](./01-session/README.md) · ⚠️ 5.9/10

Read-heavy KV store + click analytics. **Strong:** throughput estimation, cache-aside, DB failover, async analytics. **Lost points on:** key-generation depth (base62 / predictable-ID security), HTTP **3xx** redirect semantics, and reaching for **consistent hashing** without prompting. → **[Read the full write-up →](./01-session/README.md)**

### [02 — Basic E-commerce Platform](./02-session/README.md) · ⚠️ 6.6/10

Listings + cart + payments for small businesses; delivery-first, scale deprioritized. **Strong:** pragmatic requirements trade-off, monolith-first instinct, clean REST design, **failure handling** (pending-status + async reconciliation), and sound bottleneck reasoning (read replicas, replication lag, webhook, SSE). **Lost points on:** no **data model / schema**, no **security / auth** (buyer vs seller), no **caching or CDN** for a read-heavy catalog, a **stale diagram**, and the missed **concurrent-last-unit** edge case. Interviewer's own verdict was **FAIL** — the silent senior axes sank it. → **[Read the full write-up →](./02-session/README.md)**

### [03 — E-commerce Platform (Re-attempt of S02)](./03-session/README.md) · ⚠️ 6.5/10

**Same prompt as S02, re-solved after drilling the gaps** — the clearest progress signal so far. **What closed:** the blind spots that failed S02 all appeared *unprompted* — estimation numbers (5k users, 100:1, ~1000 RPS), a **drawn data-model schema**, **Redis caching** + invalidation, a **CDN** for images, and an **auth module** with buyer/seller authZ. That flipped the interviewer's verdict **FAIL → Lean Hire**. **What survived:** the **concurrent-last-unit race** was missed *again* (Problem-Solving dropped 7 → 6), no **Orders** table (only Payments), **payment-data / PCI security** untouched, and the diagram went from *stale* to *cluttered*. → **[Read the full write-up →](./03-session/README.md)**

---

## Consolidated Tips

Grouped by the axis interviewers score, weakest axis first. Session tags like `[S01]` mark the source; a repeat across sessions is a priority to drill. Per-axis score history is shown so trends are visible.

### Communication — `5.5 → 6.0 → 6.0` (top priority · lowest across all three, now flat)
- **Structure every answer**: *decision → why → trade-off.* Cut repetition — say each point once. `[S01]` `[S02]`
- **Front-load requirements as a visible checklist** on the canvas, split into functional / non-functional / analytics, before designing. `[S01]`
- **The diagram is the artifact the interviewer reads — keep it live *and* legible.** S02 lost points for a *stale* diagram (webhook/SSE/cache/CDN discussed but never drawn); S03 kept it live but lost the same point for a *cluttered* one (overlapping arrows). Next target: separate **read vs write flows**, color per journey, space components. `[S02]` `[S03]`
- **Label diagrams**: every arrow gets its data + protocol (HTTP/gRPC/async); put API signatures on the canvas, e.g. `POST /urls {longUrl} → {shortUrl}`. `[S01]`
- Be concise and direct; a short pause beats filler while you think. `[S01]` `[S02]`

### Scalability & Trade-offs — `5.5 → 6.0 → 6.0` (still low · plateaued)
- **Reach for the standard scaling tool directly** — for a distributed cache/DB that's **consistent hashing**; don't detour through vertical scaling first. `[S01]`
- **Analyze bottlenecks at 10×/100×**, not just current load — name where each layer breaks and the fix. `[S01]`
- **Don't stop at bottleneck #1.** S03 added replicas + cache but stalled there — name the *next* bottlenecks: **horizontal backend scaling** behind the LB, **DB sharding**, **rate limiting** at the gateway, connection pooling. `[S02]` `[S03]`
- When you state a trade-off (e.g. replication lag), also state **when it's unacceptable** and the mitigation (read-your-writes, route critical reads to primary). `[S01]` `[S02]`
- **Cache-consistency reasoning landed** — write-DB-first-then-cache + backoff retry for eventual consistency was a solid, defended choice. Keep pairing the strategy with its staleness window. `[S03]` → [caching](../concepts/06-caching/caching.md)

### Requirements Gathering — `6.0 → 7.0 → 7.0` (gain held)
- **Explore every stated requirement upfront**, especially ones the prompt names explicitly (analytics here) — don't leave them to the end. `[S01]`
- **Make the constraint an explicit trade-off** — "delivery over scale, so monolith-first" was a strong, defensible move; keep verbalizing the *why*. `[S02]` `[S03]`
- **Nail scale numbers early** (read:write ratio, QPS, storage/retention). S02 skipped them and lost the pre-justification for caching/replicas; **S03 stated them up front (5k users, 100:1, ~1000 RPS)** and it pre-justified the whole read-path design. Keep doing it every time. `[S01]` `[S02]` `[S03]`
- **Surface user roles / auth in scoping** — "who are the actors and what can each do?" (buyer vs seller) is a requirements question, not just a security one. `[S02]` `[S03]`

### Design Skills — `6.0 → 7.0 → 7.0` (gain held · the S02 blind spots closed)
- **Always draw the data model** — schema + keys + any state machine. Missing in S01 **and** S02; **S03 finally drew it** (Products / Users / Carts / Payments with a `pending → cancelled/success` status). Keep it a non-negotiable — and go one further: **model Orders / order_items separately from Payments** (payment ≠ order — S03's schema still lacked it). `[S01]` `[S02]` `[S03]` → [databases](../concepts/05-databases-and-storage/databases-fundamentals.md)
- **Cover the silent senior axes unprompted** — **security/auth**, **caching**, **CDN**. Their *absence* failed S02; **S03 surfaced all three unprompted** (auth module, Redis, CDN) and that flipped the verdict. The **last silent box** still open: **payment-data / PCI** — tokenize via the provider, never store raw card data. `[S02]` `[S03]` → [AuthN & AuthZ](../concepts/04-apis/authentication-and-authorization.md) · [caching](../concepts/06-caching/caching.md) · [CDN](../concepts/03-networking-and-delivery/cdn.md) · [API Security](../concepts/04-apis/api-security.md)
- **Go deep on key generation** — compare hashing (collision handling), base62 of a counter, pre-generated key pools, and the **security implication of predictable IDs**. `[S01]`
- Know **cache eviction/invalidation**: LRU/LFU, TTL, and how expired/updated entries leave the cache. `[S01]` `[S02]` `[S03]` → [caching](../concepts/06-caching/caching.md)
- **Justify a service split** by independent scaling / blast-radius / different access patterns — or defend staying monolith. S03 *defended* the monolith when probed rather than asserting it — the right move. `[S02]` `[S03]` → [monolith vs microservices](../concepts/02-foundations/monolithic-vs-microservices.md)

### Problem Solving — `6.5 → 7.0 → 6.0` (⚠️ regressed — the repeat concurrency miss)
- **Hunt the concurrency edge case — this is now the #1 recurring miss.** "What if two buyers grab the last unit?" was missed in *both* S02 and S03; it's what pulled Problem-Solving down a full point in S03. Make guarding the decrement (**atomic conditional update / row lock / optimistic version**, or reserve-stock-with-timeout) a reflex on any inventory/stock design. `[S02]` `[S03]` → [consistency models](../concepts/08-distributed-systems/consistency-models.md)
- Keep leading with estimation, async-decoupling, and **failure-recovery** instincts — the pending-status + async reconciliation in S02 landed well. *(S03 note: the webhook-never-arrives fallback was stronger in S02 — don't let it slip on re-solves.)* `[S01]` `[S02]`
- **Offer 2–3 options before committing** and name their trade-offs, rather than settling on the first idea. `[S01]`

---

## Recurring Action Items

*Ordered by how stubborn the miss is. #1 is the standout: missed in two mocks of the same problem even after drilling.*

1. **Hunt the concurrency edge case — the #1 recurring miss.** Concurrent purchase of the last-in-stock unit was missed in **both S02 and S03**; it cost a full Problem-Solving point on the re-solve. Guard the decrement (**atomic conditional update / row lock / optimistic version**, or reserve-stock-with-timeout) — make it reflexive on any inventory/stock design. → [consistency models](../concepts/08-distributed-systems/consistency-models.md)
2. **Open with a 5-minute requirements checklist** on the canvas (functional / non-functional / analytics / **actors & auth**) → **one estimate** (read:write, RPS) → **data-model sketch**, *before* components. **This closed the S02 blind spots in S03** — keep it muscle-memory. → [framework](../concepts/00-framework/system-design-interview-framework.md) Step 1 · [Opening Ritual](./opening-ritual.md).
3. **Model Orders separately from Payments** — add `orders` + `order_items` (line items, qty, price-at-purchase, fulfillment). S03 drew Payments but nothing recording *what was bought*. Payment ≠ order.
4. **Close the last silent senior box: payment-data / PCI.** S03 surfaced auth/caching/CDN unprompted but left payment security blank — **tokenize via the provider, never store raw card data**, and name PCI-scope reduction as *why* you use an external gateway.
5. **Keep the diagram live *and* legible.** The problem moved from *stale* (S02) to *cluttered* (S03) — next target is a clean canvas with **read vs write flows separated**, colored per journey, components spaced. Still: draw each component the moment you say it.
6. **Don't stop at bottleneck #1.** After read replicas + cache, name the next ones: **horizontal backend scale** behind the LB, **DB sharding**, **rate limiting** at the gateway, connection pooling.
7. **Study the recurring fundamentals** that cut across problems: **consistent hashing, base62 encoding, HTTP 3xx redirects, cache eviction (LRU/LFU/TTL), sharding/partitioning, load balancing.**
8. **Label diagrams** — data + protocol on arrows, API signatures on the canvas — and for every decision verbalize **"Option A trades X; Option B trades Y; I'd pick ___ because ___,"** including *why* you split (or didn't split) services.

---

## How to Improve

### The diagnosis

**S03 was the experiment: re-solve S02's exact problem after drilling the gaps — and it worked.** The blind spots that drove S02's **FAIL** (no schema, no caching, no CDN, no auth) all appeared *unprompted*, and the verdict flipped to **Lean Hire**. That confirms the earlier read: the reasoning engine is fine; **the fix was a habit, not knowledge.** The opening checklist is now the proven lever.

What the re-solve *didn't* fix tells us where the remaining work is:

1. **The concurrency reflex is the highest-leverage gap now.** The concurrent-last-unit race was missed *twice* on the same problem — the one thing drilling the checklist didn't catch, because it's not a checklist item, it's an instinct to interrogate the write path. It cost a full Problem-Solving point in S03. This is now the single biggest scoring lever.
2. **Two silent boxes remain** — **payment-data / PCI** (tokenize, never store cards) and a **proper Orders model** (S03 has Payments but nothing recording *what* was bought). The checklist surfaced the *read-path* senior axes; it now needs the *write/checkout-path* ones added.
3. **Delivery plateaued** — **Communication and Scale both flat at 6.0.** The diagram problem shifted from *stale* (S02) to *cluttered* (S03) — the artifact is now live but not legible. Scale stops at bottleneck #1 (replicas + cache) without naming sharding / horizontal scale / rate limiting.

### The plan

- **Add the write-path items to the opening checklist** — the read-path version is now automatic (caching/CDN/auth landed). Extend it: after the data model, ask **"where's the concurrent write, and how do I guard it?"** and **"is there sensitive data (payments/PII) — how is it secured?"**
- **Drill the concurrency edge case specifically** — on every stock/inventory/booking/counter problem, force the "two clients race for the last one" question and answer it (atomic update / row lock / optimistic version / reservation). It's a reflex, not a fact.
- **Fix diagram legibility** — separate read vs write flows, color per journey, space components. Live *and* legible.
- **Push scaling past the first bottleneck** — after replicas + cache, always name horizontal scale, sharding, and rate limiting; pull sharding/consistent-hashing depth from the Alex Xu chapters.
- **Keep re-solving** — the same-problem re-attempt is the clearest progress signal; the next one should target a *clean diagram + guarded concurrency* on this same prompt before moving on.

> **Implication**: the checklist habit is validated — it converts a FAIL to a Hire on the read-path axes. The next tier of points is **the concurrency reflex + the write/checkout-path senior boxes (PCI, Orders) + a legible diagram.** Split practice ~40% drilling the concurrency/write-path reflex, ~30% deeper scaling fundamentals, ~30% clean structured delivery.
