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

**Related concepts**: [Estimation](../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md) (01) · [Interview Framework](../concepts/00-framework/system-design-interview-framework.md) (01) · [Load Balancing & Consistent Hashing](../concepts/03-networking-and-delivery/load-balancing-and-consistent-hashing.md) (01) · [AuthN & AuthZ](../concepts/04-apis/authentication-and-authorization.md) (02) · [Caching](../concepts/06-caching/caching.md) (02) · [Consistency Models](../concepts/08-distributed-systems/consistency-models.md) (02) · [Monolith vs Microservices](../concepts/02-foundations/monolithic-vs-microservices.md) (02)

---

## Session write-ups

Each session has a full **analyzed page** — problem, design + diagram, scorecard, and gap-by-gap fixes.

### [01 — URL Shortener (bit.ly / TinyURL)](./01-session/README.md) · ⚠️ 5.9/10

Read-heavy KV store + click analytics. **Strong:** throughput estimation, cache-aside, DB failover, async analytics. **Lost points on:** key-generation depth (base62 / predictable-ID security), HTTP **3xx** redirect semantics, and reaching for **consistent hashing** without prompting. → **[Read the full write-up →](./01-session/README.md)**

### [02 — Basic E-commerce Platform](./02-session/README.md) · ⚠️ 6.6/10

Listings + cart + payments for small businesses; delivery-first, scale deprioritized. **Strong:** pragmatic requirements trade-off, monolith-first instinct, clean REST design, **failure handling** (pending-status + async reconciliation), and sound bottleneck reasoning (read replicas, replication lag, webhook, SSE). **Lost points on:** no **data model / schema**, no **security / auth** (buyer vs seller), no **caching or CDN** for a read-heavy catalog, a **stale diagram**, and the missed **concurrent-last-unit** edge case. Interviewer's own verdict was **FAIL** — the silent senior axes sank it. → **[Read the full write-up →](./02-session/README.md)**

---

## Consolidated Tips

Grouped by the axis interviewers score, weakest axis first. Session tags like `[S01]` mark the source; a repeat across sessions is a priority to drill. Per-axis score history is shown so trends are visible.

### Communication — `5.5 → 6.0` (top priority · low in both)
- **Structure every answer**: *decision → why → trade-off.* Cut repetition — say each point once. `[S01]` `[S02]`
- **Front-load requirements as a visible checklist** on the canvas, split into functional / non-functional / analytics, before designing. `[S01]`
- **Keep the diagram live** — update the canvas the moment a component enters the conversation. The webhook, SSE, cache, and CDN were *discussed but never drawn*, and the stale diagram was explicitly called out. `[S02]`
- **Label diagrams**: every arrow gets its data + protocol (HTTP/gRPC/async); put API signatures on the canvas, e.g. `POST /urls {longUrl} → {shortUrl}`. `[S01]`
- Be concise and direct; a short pause beats filler while you think. `[S01]` `[S02]`

### Scalability & Trade-offs — `5.5 → 6.0` (low in both)
- **Reach for the standard scaling tool directly** — for a distributed cache/DB that's **consistent hashing**; don't detour through vertical scaling first. `[S01]`
- **Analyze bottlenecks at 10×/100×**, not just current load — name where each layer breaks and the fix. `[S01]`
- **Push past replicas** to caching, **load balancing**, and **sharding** — read replicas alone don't fully answer a read-heavy scaling question. `[S02]`
- When you state a trade-off (e.g. replication lag), also state **when it's unacceptable** and the mitigation (read-your-writes, route critical reads to primary). `[S01]` `[S02]`

### Requirements Gathering — `6.0 → 7.0` (improving)
- **Explore every stated requirement upfront**, especially ones the prompt names explicitly (analytics here) — don't leave them to the end. `[S01]`
- **Make the constraint an explicit trade-off** — "delivery over scale, so monolith-first" was a strong, defensible move; keep verbalizing the *why*. `[S02]`
- Nail scale numbers early (read:write ratio, QPS, storage/retention) — strong in S01; **S02 skipped them** and lost the pre-justification for caching/replicas, so keep doing it every time. `[S01]` `[S02]`
- **Surface user roles / auth in scoping** — "who are the actors and what can each do?" (buyer vs seller) is a requirements question, not just a security one. `[S02]`

### Design Skills — `6.0 → 7.0` (improving)
- **Always draw the data model** — schema + keys + any state machine (e.g. payment `pending → success/failed`). Missing in *both* sessions; it's the fastest Design points to earn. `[S01]` `[S02]`
- **Cover the silent senior axes unprompted** — **security/auth**, **caching**, **CDN**. They're not in the prompt, but their *absence* failed S02. `[S02]` → [AuthN & AuthZ](../concepts/04-apis/authentication-and-authorization.md) · [caching](../concepts/06-caching/caching.md) · [CDN](../concepts/03-networking-and-delivery/cdn.md)
- **Go deep on key generation** — compare hashing (collision handling), base62 of a counter, pre-generated key pools, and the **security implication of predictable IDs**. `[S01]`
- Know **cache eviction/invalidation**: LRU/LFU, TTL, and how expired/updated entries leave the cache. `[S01]` `[S02]` → [caching](../concepts/06-caching/caching.md)
- **Justify a service split** by independent scaling / blast-radius / different access patterns — or defend staying monolith. Don't assert the split. `[S02]` → [monolith vs microservices](../concepts/02-foundations/monolithic-vs-microservices.md)

### Problem Solving — `6.5 → 7.0` (strongest)
- Keep leading with estimation, async-decoupling, and **failure-recovery** instincts — the pending-status + async reconciliation in S02 landed well. `[S01]` `[S02]`
- **Hunt the concurrency edge case** — "what if two buyers grab the last unit?" should be reflexive on any inventory/stock design (atomic conditional update / row lock / optimistic version). `[S02]` → [consistency models](../concepts/08-distributed-systems/consistency-models.md)
- **Offer 2–3 options before committing** and name their trade-offs, rather than settling on the first idea. `[S01]`

---

## Recurring Action Items

1. **Open with a 5-minute requirements checklist** on the canvas (functional / non-functional / analytics / **actors & auth**) — [framework](../concepts/00-framework/system-design-interview-framework.md) Step 1.
2. **Always draw the data model** — schema, keys, and any state machine. Missing in *both* sessions; make it a non-negotiable step.
3. **Cover the silent senior axes unprompted** every time: **security / auth, caching, CDN** for read-heavy paths — their *absence* is what sinks the score, not the prompt asking for them.
4. **Keep the diagram a live artifact** — draw each component (webhook, SSE, cache, CDN) the moment you say it; a stale diagram was called out in S02.
5. **Study the recurring fundamentals** that cut across problems: **consistent hashing, base62 encoding, HTTP 3xx redirects, cache eviction (LRU/LFU/TTL), sharding/partitioning, load balancing.**
6. **Hunt the concurrency edge case** — e.g. concurrent purchase of the last-in-stock unit (atomic conditional update / row lock / optimistic version).
7. **Label diagrams** — data + protocol on arrows, API signatures on the canvas.
8. For every decision, verbalize **"Option A trades X; Option B trades Y; I'd pick ___ because ___."** — including *why* you split (or didn't split) services.

---

## How to Improve

### The diagnosis

Two sessions in, the same two axes sit at the bottom of **both** scorecards: **Communication** (5.5 → 6.0) and **Scale & Trade-offs** (5.5 → 6.0). Problem-solving (6.5 → 7.0) is consistently the strongest, so the raw reasoning is there — the points are lost *around* it. The gaps sort into three kinds:

1. **Recurring blind spots** (highest leverage) — three things go missing whether or not the prompt asks for them: the **data model / schema** (absent in both), **security / auth**, and **caching / CDN** for read-heavy paths. In S02 their absence alone drove the interviewer's **FAIL**. These aren't knowledge gaps so much as *habit* gaps — they need to become reflexive opening moves, not things remembered at the end.
2. **Knowledge gaps** (fixable by study) — specific fundamentals that recur across problems: consistent hashing, base62 key generation, HTTP 3xx redirects, cache eviction, and **load balancing / sharding depth**. Grinding these *will* move the Scale axis.
3. **Delivery gaps** (fixable by rehearsal) — unstructured, repetitive walkthroughs and a **stale diagram** (S02) that lagged the discussion. The reasoning was sound; it wasn't captured on the canvas or narrated concisely.

### The plan

- **Make a fixed opening checklist muscle-memory**: requirements (functional / non-functional / **actors & auth**) → one estimate (read:write) → **data-model sketch** → then components. This single habit attacks the recurring blind spots and both weak axes at once.
- **Build the concept library for the recurring gaps** — consistent hashing, base62 key generation, load balancing & sharding depth. Pull from the Alex Xu book chapters.
- **Rehearse the framework's 4-step flow out loud** using the [in-the-room checklist](../concepts/00-framework/system-design-interview-framework.md#4-in-the-room-checklist-quick-reference), forcing the requirements checklist, a live diagram, and a labeled data model every time.
- **Re-attempt a scored problem** after drilling the gaps and compare — the same-problem re-solve is the clearest signal of progress.

> **Implication**: the reasoning engine is fine — what's missing is a *repeatable checklist* that surfaces data model, security, and caching every time, plus keeping the diagram live. Split practice ~50% habit-drilling that checklist, ~30% studying the recurring fundamentals, ~20% concise structured narration.
