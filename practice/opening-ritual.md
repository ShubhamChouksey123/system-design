# The Opening Ritual — Pre-Mock Drill Card

> The **fixed sequence** you run on *every* system-design mock, in the same order, no exceptions — the opening six steps (~12 min) then the deep-dive close. Pin it next to the screen. It exists because the two mock FAILs weren't reasoning failures — they were **omissions of things you already know** (data model, auth, caching). A ritual makes those reflexive instead of remembered-at-the-end.

**Why this card:** across [both scored sessions](./README.md#how-to-improve) the two weakest axes were **Communication** and **Scale & Trade-offs**, and [Session 02 FAILed](./02-session/README.md) purely on *silent* omissions. One repeatable opening sequence attacks all of it at once.

---

## The ritual — say each step out loud, write each on the canvas

| # | Step (≈ time) | Say it / draw it | The trap it closes |
|:-:|---|---|---|
| **1** | **Restate + confirm** (~1 min) | • "So we're designing X, with A/B/C in scope — right?" | Solving the wrong problem = auto-fail. |
| **2** | **Functional reqs** (~2 min) | • **Name the actors / roles** — "who uses this, and what can each *do*?" (buyer vs seller)<br>• 2–4 core ops as **API verbs**<br>• Park nice-to-haves *out of scope*<br>• Name **monitoring / analytics** needs | Vague scope; forgetting a prompt-named feature (e.g. analytics). **Roles are a requirements question, not just a step-7 auth one** — surfacing them late cost S02 Requirements points. |
| **3** | **Non-functional reqs** (~2 min) | • Availability (nines)<br>• Fault tolerance<br>• Consistency<br>• Time-to-ship<br>• Performance (p95/p99)<br>• Security<br>• **Scalability (read:write)** | Un-anchored design; no reason to add caching/replicas later. |
| **4** | **Envelope estimation** (~2 min) | • Throughput & **read:write**<br>• Storage<br>• Bandwidth<br>• Compute<br>• "Read-heavy ~100:1" *pre-justifies* cache + replicas | S02 skipped numbers → caching looked reactive. |
| **5** | **Draw the design** (~3 min) | • **Components:** clients (buyer/seller) · CDN · API gateway · services · cache · DB · queue · S3 · external (payment/email/SMS) · async jobs<br>• **Arrows:** API signature + protocol (HTTP / gRPC / GraphQL / WebSocket / SSE) | Stale diagram was called out in S02 — keep it **live**. |
| **6** | **Database model** (~2 min) | • Tables<br>• Key columns<br>• **State machine** (`pending → cancelled / success`)<br>• Relationships<br>• Indexing | **Missing in BOTH sessions** — fastest Design points on the table. |
| **7** | **Walkthrough** *(deep dive)* | • Client types<br>• **AuthN / AuthZ**<br>• **Trace the write path, then the read path** end-to-end<br>• Business logic<br>• **Cache strategy**<br>• **Load balancing** (across app tier + DB reads)<br>• DB (RDBMS/NoSQL/blob, replication, **sharding / consistent hashing**, indexing)<br>• **Fault tolerance** — failover, retries, **idempotency** | Security/auth never came up (S02); scale answers stopped at read replicas — *push to load balancing, consistent hashing & sharding* `[S01]` `[S02]`. This is where they land. |
| **8** | **Trade-offs & alternatives** *(deep dive)* | • Pick 1–2 pivotal decisions; give **2–3 options + pros/cons**<br>• "Option A trades X; B trades Y — **I'd pick ___ because ___**"<br>• For each trade-off: **when is it unacceptable, and the mitigation** (replication lag → read-your-writes / route critical reads to primary) | Scale & Trade-offs is a bottom-two axis — *asserting* one design without naming what it costs is the recurring point-loss `[S01]` `[S02]`. |
| **9** | **Testing & monitoring** (~2 min) | • **MELT** — metrics · events · logs · traces<br>• Dashboards / alerting<br>• Name the **bottleneck** + fix | Skipping the close; the framework's step ⑧ left on the floor. |

> Steps **1–6** are the opening muscle memory (~12 min); **7–9** carry into the deep dive. Reach for the [8-step Answer Framework](./answer-framework.md) when you need depth on any single step.

---

## The 4 silent senior axes — cover unprompted, or lose points

These are **never in the prompt**, but their *absence* is what sinks the score. Glance here before you say "I think that's the design":

- [ ] **Security / auth** — who authenticates, who's authorized for which endpoint? → [AuthN & AuthZ](../concepts/04-apis/authentication-and-authorization.md)
- [ ] **Caching** — cache-aside on read-heavy paths; name eviction (LRU/LFU/TTL) + invalidation. → [Caching](../concepts/06-caching/caching.md)
- [ ] **CDN** — static assets / images served through a CDN, not the origin on every read. → [CDN](../concepts/03-networking-and-delivery/cdn.md)
- [ ] **The concurrency edge case** — "what if two users grab the last unit?" → atomic conditional update / row lock / optimistic version. → [Consistency Models](../concepts/08-distributed-systems/consistency-models.md)

---

## Three rules that run the whole interview

1. **Keep the diagram alive.** Draw each component *the moment you name it* — the webhook, the cache, the CDN. If you say it, it's on the canvas.
2. **Structure every point:** *decision → why → trade-off.* Say each thing once; a short pause beats filler.
3. **Every number forces a decision.** A figure with no architectural consequence (shard vs single DB, CDN vs origin) is incomplete.

---

## 15-second pre-mock warm-up

Read this list aloud right before you start, then start:

> *Restate → functional (**actors/roles** +analytics) → non-functional (read:write) → **estimate** → **draw it live** → **data model** → walkthrough (**authN/Z, write/read path, cache, load balancing, consistent hashing / sharding, DB type, idempotency**) → **trade-offs (2–3 options + when-unacceptable + mitigation)** → **testing/monitoring**. Silent axes: **security, caching, CDN, last-unit race.** Diagram is alive. Decision → why → trade-off.*

---

Full step detail: [Answer Framework playbook](./answer-framework.md) · behavioral pacing: [in-the-room checklist](../concepts/00-framework/system-design-interview-framework.md#4-in-the-room-checklist-quick-reference) · what this fixes: [practice tracker](./README.md).
