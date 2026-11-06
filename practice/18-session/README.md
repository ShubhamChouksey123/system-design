# Session 18 — Multi-Channel Notification System (SMS / Email / Push) · ✅ 8.0/10

> A scored, analyzed mock — and a **de facto re-solve of [Session 14](../14-session/README.md)**: the same notification-system prompt, attempted again after S14's gaps were written up. The two things S14 was marked down for both showed up this time without the interviewer naming them first: **priority tiers** (the walkthrough volunteered `sms-high` vs. `sms-low` topics, with OTP as the reason) and **concrete scaling math** (a 10,000 rps campaign spike ÷ 50 rps per worker = 200 workers). The platform scored it **✅ Strong Hire, 8.0/10** (every axis 7–8). Read the scores against this repo's own bar, though: **partition-by-`user_id` ordering** was never said, **no schema or API contract** was produced despite both being on the candidate's own outline, and the duplicate-delivery window was *accepted* rather than closed. Those are the gaps worth drilling; the [S14 ideal design](../14-session/README.md#the-ideal-design) is the reference answer.

| | |
|---|---|
| **Problem** | Design a scalable notification system sending millions of push notifications, emails, and SMS with high delivery rates and minimal latency |
| **Focus** | Re-solve of S14 — priority isolation, spike-sizing math, provider failover, and the at-least-once duplicate window |
| **Overall** | **8.0 / 10** — ✅ **Strong Hire** *(platform's verdict)* — up 1.0 from S14's 7.0 on the same prompt, up 1.5 from S17's 6.5 |
| **Weakest areas** | Problem-Solving (7.0) — provider-level failover and the status-check bottleneck both needed a nudge; no API/schema produced |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |

## The problem

> Design a **scalable notification system** that can send **millions of push notifications, emails, and SMS messages** with **high delivery rates** and **minimal latency**.

Same crux as [S14](../14-session/README.md#the-problem): three unreliable external providers, no cross-channel blast radius, no spam to unsubscribed users, and no marketing blast starving an OTP. What changed is how much of it was volunteered.

## Terminology

| Term | Meaning |
|---|---|
| **Priority tier** | Splitting traffic by urgency (OTP vs. marketing) into separate topics and worker pools per channel — distinct from per-provider fault isolation. See [S14](../14-session/README.md#terminology). |
| **Provider failover vs. channel fallback** | Two different reactions to an outage. **Failover** swaps the *provider* inside one channel (Twilio → standby SMS vendor). **Fallback** moves the notification to a *different channel* (SMS → email). Try failover first — fallback changes what the user receives. |
| **Campaign spike** | A bulk send (promo to millions) that dwarfs the smoothed daily average — the number that sizes the consumer pool, not `2× average`. |
| **At-least-once window** | The gap between "provider accepted the send" and "offset committed / status written." A crash inside it redelivers the message, so the user can get a duplicate. |

## Requirements & estimation

- **Functional** — send SMS/email/push via **templates**; users can **unsubscribe per channel**; **at-least-once** delivery; **pluggable providers**; **fallback channel** when a provider is down. A sharper set than S14 on resilience (plugin providers and fallback were requirements, not afterthoughts) but **per-customer rate limiting dropped off the list** (it reappeared only as a cache in the diagram) and delivery-status tracking was absent until the closing minutes.
- **Non-functional** — highly available (OTPs sit on the login hot path — a good, specific justification), scalable, reliable, resilient, small delay tolerable.
- **Estimation, decision-tied end to end** — 10M/day ÷ 86,400 ≈ **100 rps**, peak **200 rps**, and — the S14 miss — a **spike**: 5M notifications in 10 minutes ≈ **10,000 rps** (exact: 5M ÷ 600 s ≈ 8,300; rounded up, fine), then **50 rps/worker → 200 workers**. That last step is the "give a number, not a mechanism" fix S14 was asked for.
- **Missing numbers** — no storage figure (10M/day × ~1 KB ≈ 10 GB/day for the request + log tables), no Kafka partition count (200 workers needs ≥ 200 partitions on the busiest topic — Kafka caps consumers at partitions), no cache-size or hit-ratio estimate (the interviewer's own closing note).
- **Scoping question that paid off** — internal vs. public callers, asked unprompted; the answer drove an auth split (internal trusted, external via API gateway).
- **API / schema** — both were on the candidate's own outline and neither was produced ("I think API is schema is remaining"). The interviewer let it go; a stricter room would not.

![Requirements canvas for a notification system. The functional requirements list sending SMS, email, and push notifications using templates, letting users unsubscribe per channel, an at-least-once send guarantee, a plugin approach so providers can be switched, and a fallback channel when a provider is down. The non-functional requirements list highly available, scalable, reliable, resilient, and small delay is tolerable. The estimations assume 10 million notifications per day, 100 requests per second average, 200 requests per second peak, a spike of 5 million notifications in 10 minutes equal to about 10,000 requests per second, and one worker handling 50 requests per second which means 200 workers.](./diagrams/requirements.png)

## The design I produced

![Architecture canvas produced in the interview. An external user goes through an API Gateway with authentication and rate limiting to a Notification Service, while a marketing service and a login service for OTP call it directly. The Notification Service reads user details and subscription status from a User Cache backed by a User DB reader instance on a cache miss, checks an Idempotency cache on Redis and a rate limit cache, and writes to a NoSQL Notification DB holding the notification_request. It routes into Kafka topics per channel for push, email, and SMS, with SMS split into low priority and high priority topics. Delivery workers consume each topic, fill a template from a Template Cache, call providers such as Google FCM, Apple APNs, SendGrid, and Twilio behind circuit breakers with retry and backoff, and send exhausted retries to a Dead letter queue.](./diagrams/architecture.png)

- **Notification Service** — internal callers: authN + rate limit; external callers arrive through an **API Gateway**. Steps, in the order narrated: user lookup (cache → DB reader on miss) → **idempotency check** (duplicate → reject) → **rate-limit check** → insert into the **NoSQL `notification_request`** store → route to a Kafka topic by channel *and* priority.
- **Unsubscribe filtered before Kafka** — an unsubscribed request is dropped at the front door, never enqueued. Right place; saves downstream work.
- **Kafka per channel (and per priority for SMS)** — OTP SMS gets a dedicated `high` topic so it never waits behind a promo; the candidate stated the reason in the room and generalized it verbally ("channel × priority number of topics"). SMS was drawn as the worked example, a reasonable whiteboard shortcut; a one-line "same for push and email" note on the canvas would make it explicit.
- **Delivery workers** — one pool per topic, scaled on CPU > 70% or consumer lag (auto or manual); fetch the template from a cache, call the provider behind a **circuit breaker**, retry with backoff, **DLQ + alert** on exhaustion. **Plugin interface** per provider; a breaker open for a configurable time triggers a provider swap, then a channel fallback.
- **Kafka as the burst buffer, async ack to the caller** — the strongest answer to "what absorbs a 100× spike": the API acks *accepted*, never waits on the provider.
- **Weak spots** — the failover swap was described as a code-level switch that might need a **restart** (config should be runtime-reloadable); Template Cache and DLQ were wired only to the SMS worker group in the drawing; there is no analytics/log store, no fallback arrow, and no circuit-breaker box on the canvas (it lived only in the narration).

## Scorecard

Scored by the mock platform. Compared against the previous session (S17), with the same-prompt baseline (S14) alongside.

| Axis | S14 (same prompt) | S17 (previous) | **S18** | Δ vs S17 | Note |
|---|:--:|:--:|:--:|:--:|---|
| Requirements | 7.0 | 7.0 | **8.0** | ▲ 1.0 | Spike estimate and worker count added; plugin providers + fallback named as requirements; no API/schema, no storage number |
| Design | 7.0 | 7.0 | **8.0** | ▲ 1.0 | Priority isolation, per-provider breakers, DLQ, idempotency |
| Problem-Solving | 7.0 | 6.0 | **7.0** | ▲ 1.0 | Provider-before-channel failover and the status-check bottleneck both needed a nudge |
| Scale & Trade-offs | 6.0 | 6.0 | **8.0** | ▲ 2.0 | Spike → 200 workers, Kafka as buffer, explicit eventual-consistency and "rare duplicate" trade-offs |
| Communication | 6.0 | 5.0 | **8.0** | ▲ 3.0 | Outline up front, then a structured end-to-end walkthrough; the platform still asked for more concision |
| **Overall** | **7.0** | **6.5** | **8.0** | ▲ 1.5 | ✅ Strong Hire — platform's own verdict (+1.0 over the S14 attempt of the same prompt) |

> **How much of this is the re-solve effect?** S14's two named gaps — priority and scaling math — are exactly the two that closed, and Scale & Trade-offs jumped 6.0 → 8.0 while Communication recovered from the tracker's low (5.0). That matches the [S08 → S09](../09-session/README.md) and [S10 → S11](../11-session/README.md) pattern: a targeted re-solve converts a named gap into a volunteered answer. The caveat is that the platform's rubric is lenient on the items below; treat 8.0 as the platform's number and the table that follows as this repo's.

## What lost points — and the fix

| What I missed in the room | What a senior would say | Study |
|---|---|---|
| **Ordering never mentioned** — no partition key named for any topic | Partition each topic by `user_id`: one user's notifications on one channel stay ordered; no cross-channel guarantee, and that's fine. Also state that partitions ≥ peak consumers (200 here). | [Sharding & Partitioning](../../concepts/05-databases-and-storage/sharding-and-partitioning.md) |
| **Duplicate-delivery window accepted, not closed** — worker crashes after the provider accepts but before the offset commit → user gets two; the status-in-DB fix was then judged a bottleneck at 10K rps and replaced with async status writes, leaving the window open | "Rare, acceptable" is fine for a marketing email, wrong for a billing or security alert. Close most of it cheaply: a Redis `sent:{notification_id}` key (TTL 24h) checked before the send and set after the provider ack — ~10K ops/sec is trivial for Redis, unlike 10K DB reads — and say what remains (crash between ack and set). Make idempotency per-type, not blanket. | [Message Queue](../../concepts/07-messaging-and-events/message-queue.md) · [Caching](../../concepts/06-caching/caching.md) |
| **Provider failover and channel fallback conflated until prompted** — first answer jumped straight to SMS → email | Failover to a standby provider inside the channel first; fall back to another channel only if that fails *and* the notification type's policy allows it. Also name the duplicate risk: a *slow* (not down) SMS provider plus a fallback email delivers both. | [Resilience Patterns](../../concepts/09-reliability-and-operations/resilience-patterns.md) |
| **Provider switch needing a restart** | Active provider per channel is runtime config (reloaded, or flipped automatically by breaker state) — no deploy on the incident path. | [Deployment & Rollback](../../concepts/09-reliability-and-operations/deployment-and-rollback-strategies.md) |
| **API contract and schema never produced** — both were on the candidate's own outline | `POST /notifications` with an `Idempotency-Key` header, `user_id`, `channel`, `priority`, `template_id`, `fields`; and the `notification_request` / `user_preference` / `notification_log` tables with the status state machine. Ten lines on the canvas, early. | [API Design](../../concepts/04-apis/api-design.md) · [Databases](../../concepts/05-databases-and-storage/databases-fundamentals.md) |
| **Unsubscribe staleness waved through as "within a minute"** — the right trade-off style, but unsubscribes carry legal weight | Invalidate on write *and* keep a short TTL; for marketing sends, re-check preference at the worker just before sending, since that path tolerates the extra lookup. State the staleness window and who it's unacceptable for. | [Caching](../../concepts/06-caching/caching.md) |
| **Monitoring metrics named, thresholds mostly not** — a long list (lag, bytes in/out, breaker-open time, DLQ size, hit ratio) with one threshold (CPU 70%) | Pair each signal with a trigger — see the [S14 monitoring table](../14-session/README.md#logging-monitoring--alerts). Also drop low-signal items (DB size, "indexing") in favor of delivery-rate and per-provider failure rate. | [Observability](../../concepts/09-reliability-and-operations/observability.md) |
| **Campaign path not designed** — marketing spike absorbed only by "Kafka buffers it" | A bulk request is not 5M API calls: a campaign expander turns a segment into per-user messages, throttled into the low-priority topics, so a blast can neither overwhelm the API nor starve the high topics. (The interviewer's own suggestion: batching.) | [Message Queue](../../concepts/07-messaging-and-events/message-queue.md) |

## What went well

- **Priority isolation volunteered with the right reason** — OTPs need instant delivery, promos can wait — the single biggest S14 → S18 improvement.
- **Spike sizing closed the loop** — spike rps → per-worker rate → worker count, with consumer lag and CPU as the autoscaling signals. A number, not a mechanism.
- **Kafka's role stated precisely** — buffer for bursts *and* decoupling the caller's ack from provider latency.
- **Outline-first delivery** — wrote the agenda on the canvas, then worked through it; Communication 5.0 → 8.0.
- **Explicit, requirement-tied trade-offs** — eventual consistency on the preference cache, NoSQL for write throughput (no ACID needed), and "don't over-engineer" on the duplicate window.
- **Resilience stack volunteered in the walkthrough** — circuit breakers, retry with backoff, DLQ with alerting on its size, pluggable providers; not extracted by questions as in S14.
- **Honest self-diagnosis of the bottleneck** — asked "would a DB status check on every send bottleneck at 10K rps?", answered yes immediately and reached for async writes.

---

## The ideal design

This is the same prompt as Session 14, so the reference answer is the one already written there — see **[Session 14 → The ideal design](../14-session/README.md#the-ideal-design)**. It covers the ideal estimation, requirements, Mermaid architecture diagram, schema, storage choices, trade-offs, and the logging/monitoring/alerts table.

The refinements this session adds on top of it are in the [What lost points](#what-lost-points--and-the-fix) table: a Redis `sent:{notification_id}` send-dedup to shrink the duplicate window, provider failover before channel fallback with runtime provider config, a throttled campaign expander for bulk sends, and applying the priority split to every channel.

## Takeaways to drill

1. **A re-solve works because the gap list is concrete.** Priority tiers and spike math were S14's two named gaps; both came out volunteered here. Keep re-solving: the next lift is the *next* tier of gaps (below), not the same ones.
2. **Drawing one channel as the example is fine — label it.** SMS carried the channel × priority split on the canvas and the others were covered verbally; a one-line "same for push and email" note costs nothing and removes any doubt.
3. **"Rare, acceptable" needs a per-type answer.** Fine for a promo; not for billing alerts. Show a cheap mitigation (Redis send-dedup) and name the residual window.
4. **Failover is not fallback.** Swap provider inside the channel first; change channel only by policy — and name the double-delivery risk of falling back from a slow primary.
5. **A scale number needs its partition count.** 200 workers → at least 200 partitions on that topic; say it in the same breath.
6. **Produce the artifacts on your own outline.** API contract and schema were both listed and skipped; ten lines on the canvas, early, is worth more points than another resilience pattern.
7. **Attach a threshold to every metric you name.** A long metric list with one number is the same half-credit as the bare word "monitoring."

> → Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
