# Mock Interview Practice — System Design

> Log of system design mock interviews — the problem, the design produced, the scorecard, and consolidated tips distilled from feedback across sessions.

Each `NN-session/` folder holds a `script.md` with the full transcript, the interviewer's scorecard, and per-session tips. This index rolls them up so progress and recurring weak spots are visible at a glance.

📣 **Rehearsal tools:** work through the [Answer Framework playbook](./answer-framework.md) — the 8 steps to cover in every answer — and run the [framework's in-the-room checklist](../concepts/02-framework/system-design-interview-framework.md#4-in-the-room-checklist-quick-reference) as a dry-run before each mock. Structured delivery is the consistent weak spot (see [How to Improve](#how-to-improve)).

---

## Sessions

Scores are **/10** across the mock platform's five axes. Verdict: ✅ Pass (≥ 7) · ⚠️ Borderline (5.5–6.9) · ❌ Needs work (< 5.5).

| # | Problem | Type | Verdict | Req. | Design | Prob-Solving | Scale & Trade-offs | Comm. | Overall |
|---|---------|------|---------|:----:|:------:|:------------:|:------------------:|:-----:|:-------:|
| [01](01-session/script.md) | URL shortener (bit.ly / TinyURL) | Read-heavy KV store + analytics | ⚠️ Borderline | 6.0 | 6.0 | 6.5 | 5.5 | 5.5 | **5.9** |

**Related concepts**: [Back-of-the-Envelope Estimation](../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md) (01) · [Interview Framework](../concepts/02-framework/system-design-interview-framework.md) (01) · _Consistent Hashing — concept doc TODO_ (01)

---

## Session Summaries

### 01 — URL Shortener ⚠️ Borderline (5.9/10)

**Problem**: Design a URL shortening service like bit.ly / TinyURL — billions of URLs, click analytics, high availability, low-latency redirects.

**Design produced**: API Gateway → multiple URL-shortener service instances → write DB with a read replica (async replication) → cache-aside (Redis) on the read path. DB-generated ID as the short key; data model `{id, original_url, short_url, created_at, expires_at}`; async queue to capture click events for analytics off the redirect path; leader-election failover for the write DB; consistent hashing to route cache keys (reached only after heavy prompting).

**Estimation**: ~1B URLs/year → **~3 writes/sec**; assumed **100:1** read:write → **~300 reads/sec**.

**What went well**:
- Systematically identified the core functional operations (create short URL, resolve to long URL).
- Clean back-of-the-envelope throughput math for both reads and writes.
- Solid grasp of read replicas, the cache-aside pattern, and DB leader-election failover.
- Chose async processing for analytics to protect redirect latency.
- Reasoned about replication-lag trade-off and its (acceptable) UX impact.

**What hurt the score**:
- **Key generation stayed shallow** — proposed hashing, hand-waved collisions ("keep the rate low"), and did **not** recognize the security/predictability risk of sequential DB IDs. Never reached base62 / key-pool / counter approaches.
- **Wrong HTTP semantics for redirects** — answered 202 / 200 / 404 instead of **3xx** (301 permanent vs 302 temporary) and their caching/analytics implications.
- **Consistent hashing needed heavy prompting** — went vertical-scaling-first for the cache and only reached hash-based node routing after multiple hints.
- **Diagram lacked labels** — no data/protocol on arrows, no API signatures on the canvas.
- **Analytics requirements** were explored late and thinly given the problem called them out explicitly.
- **Verbal delivery** was repetitive and sometimes unclear.

---

## Consolidated Tips

Grouped by the axis interviewers score, weakest axis first. Session tags like `[S01]` mark the source; a repeat across sessions is a priority to drill. Per-axis score history is shown so trends are visible.

### Communication — `5.5` (top priority)
- **Structure every answer**: *decision → why → trade-off.* Cut repetition — say each point once. `[S01]`
- **Front-load requirements as a visible checklist** on the canvas, split into functional / non-functional / analytics, before designing. `[S01]`
- **Label diagrams**: every arrow gets its data + protocol (HTTP/gRPC/async); put API signatures on the canvas, e.g. `POST /urls {longUrl} → {shortUrl}`. `[S01]`
- Be concise and direct; a short pause beats filler while you think. `[S01]`

### Scalability & Trade-offs — `5.5`
- **Reach for the standard scaling tool directly** — for a distributed cache/DB that's **consistent hashing**; don't detour through vertical scaling first. `[S01]`
- **Analyze bottlenecks at 10×/100×**, not just current load — name where each layer breaks and the fix. `[S01]`
- When you state a trade-off (e.g. replication lag), also state **when it's unacceptable** and the mitigation (read-your-writes, route critical reads to primary). `[S01]`

### Requirements Gathering — `6.0`
- **Explore every stated requirement upfront**, especially ones the prompt names explicitly (analytics here) — don't leave them to the end. `[S01]`
- Nail scale numbers early (read:write ratio, QPS, storage/retention) — did this well; keep it. `[S01]`

### Design Skills — `6.0`
- **Go deep on key generation** — compare hashing (collision handling), base62 of a counter, pre-generated key pools, and the **security implication of predictable IDs**. `[S01]`
- **Design the data model for the use cases** — add analytics fields (click count, user agent, referrer, timestamp) when analytics is a requirement. `[S01]`
- Know **cache eviction/invalidation**: LRU/LFU, TTL, and how expired URLs leave the cache. `[S01]`

### Problem Solving — `6.5` (strongest)
- Keep leading with estimation and async-decoupling instincts — both landed well. `[S01]`
- **Offer 2–3 options before committing** and name their trade-offs, rather than settling on the first idea. `[S01]`

---

## Recurring Action Items

1. **Open with a 5-minute requirements checklist** on the canvas (functional / non-functional / analytics) — [framework](../concepts/02-framework/system-design-interview-framework.md) Step 1.
2. **Study the recurring fundamentals** that cut across problems: **consistent hashing, base62 encoding, HTTP 3xx redirects, cache eviction (LRU/LFU/TTL), sharding/partitioning.**
3. **Label diagrams** — data + protocol on arrows, API signatures on the canvas.
4. For every decision, verbalize **"Option A trades X; Option B trades Y; I'd pick ___ because ___."**
5. **Design data models against the use cases**, including analytics fields.

---

## How to Improve

### The diagnosis

Session 01 splits into two different kinds of gap:

1. **Knowledge gaps** (fixable by study) — the score was pulled down by missing *specific fundamentals*: consistent hashing, base62 key generation, HTTP 3xx redirect semantics, and cache eviction. These recur in almost every system design problem, so filling them has high leverage. **This is the priority right now** — unlike a pure-communication problem, grinding fundamentals *will* move the score.
2. **Delivery gaps** (fixable by rehearsal) — unstructured, repetitive explanation and unlabeled diagrams. Communication (5.5) and Scale & Trade-offs (5.5) were the lowest axes; problem-solving instinct (6.5) was the highest, so the raw reasoning is there — it needs structure and depth around it.

### The plan

- **Build the concept library for the recurring gaps** — next concept doc: **consistent hashing** (already flagged TODO in the Sessions table), then base62 key generation and HTTP redirect semantics. Pull these from the Alex Xu book chapters.
- **Rehearse the framework's 4-step flow out loud** using the [in-the-room checklist](../concepts/02-framework/system-design-interview-framework.md#4-in-the-room-checklist-quick-reference), forcing the requirements checklist and labeled diagram every time.
- **Re-attempt the URL shortener** after studying the gaps and compare scores — the same-problem re-solve is the clearest signal of progress.

> **Implication**: with only knowledge + delivery both in play, split practice time — ~60% studying the recurring fundamentals, ~40% rehearsing structured narration. Re-score the same problem to confirm the gaps closed.
