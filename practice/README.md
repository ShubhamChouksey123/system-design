# Senior System Design Mock Interviews — Scored & Analyzed

> Real system-design **mock interviews** for **senior software engineer** prep — each with the problem, the design produced (with diagrams), the interviewer's **/10 scorecard**, and a gap-by-gap breakdown of **exactly what lost points and how to fix it.**

Every `NN-session/` folder is a **standalone analyzed write-up** ([`README.md`](./01-session/README.md)) backed by the **raw transcript** (`script.md`). This page rolls them up so recurring weak spots turn into a study plan.

📣 **Rehearsal tools:** work through the [Answer Framework playbook](./answer-framework.md) — the 8 steps to cover in every answer — and run the [framework's in-the-room checklist](../concepts/00-framework/system-design-interview-framework.md#4-in-the-room-checklist-quick-reference) as a dry-run before each mock. Structured delivery is the consistent weak spot (see [How to Improve](#how-to-improve)).

---

## Sessions

Scores are **/10** across the mock platform's five axes. Verdict: ✅ Pass (≥ 7) · ⚠️ Borderline (5.5–6.9) · ❌ Needs work (< 5.5).

| # | Problem | Type | Verdict | Req. | Design | Prob-Solving | Scale & Trade-offs | Comm. | Overall |
|---|---------|------|---------|:----:|:------:|:------------:|:------------------:|:-----:|:-------:|
| [01](./01-session/README.md) | URL shortener (bit.ly / TinyURL) | Read-heavy KV store + analytics | ⚠️ Borderline | 6.0 | 6.0 | 6.5 | 5.5 | 5.5 | **5.9** |

**Related concepts**: [Back-of-the-Envelope Estimation](../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md) (01) · [Interview Framework](../concepts/00-framework/system-design-interview-framework.md) (01) · [Load Balancing & Consistent Hashing](../concepts/03-networking-and-delivery/load-balancing-and-consistent-hashing.md) (01)

---

## Session write-ups

Each session has a full **analyzed page** — problem, design + diagram, scorecard, and gap-by-gap fixes.

### [01 — URL Shortener (bit.ly / TinyURL)](./01-session/README.md) · ⚠️ 5.9/10

Read-heavy KV store + click analytics. **Strong:** throughput estimation, cache-aside, DB failover, async analytics. **Lost points on:** key-generation depth (base62 / predictable-ID security), HTTP **3xx** redirect semantics, and reaching for **consistent hashing** without prompting. → **[Read the full write-up →](./01-session/README.md)**

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
- Know **cache eviction/invalidation**: LRU/LFU, TTL, and how expired URLs leave the cache. `[S01]` → [caching](../concepts/06-caching/caching.md)

### Problem Solving — `6.5` (strongest)
- Keep leading with estimation and async-decoupling instincts — both landed well. `[S01]`
- **Offer 2–3 options before committing** and name their trade-offs, rather than settling on the first idea. `[S01]`

---

## Recurring Action Items

1. **Open with a 5-minute requirements checklist** on the canvas (functional / non-functional / analytics) — [framework](../concepts/00-framework/system-design-interview-framework.md) Step 1.
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
- **Rehearse the framework's 4-step flow out loud** using the [in-the-room checklist](../concepts/00-framework/system-design-interview-framework.md#4-in-the-room-checklist-quick-reference), forcing the requirements checklist and labeled diagram every time.
- **Re-attempt the URL shortener** after studying the gaps and compare scores — the same-problem re-solve is the clearest signal of progress.

> **Implication**: with only knowledge + delivery both in play, split practice time — ~60% studying the recurring fundamentals, ~40% rehearsing structured narration. Re-score the same problem to confirm the gaps closed.
