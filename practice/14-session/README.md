# Session 14 — Multi-Channel Notification System (SMS / Email / Push) · ⚠️ 7.0/10

> A scored, analyzed system-design mock — and the first standalone attempt at the **notification system** case study this repo's own [backlog](../../docs/TODO.md) had flagged as unpracticed. Unlike S08/S09's chat app or S13's social platform (where notifications were a feature bolted onto something bigger), here the notification pipeline *is* the whole problem: fan out one event across SMS, email, and push, each with its own provider, failure mode, and delivery guarantee. The design landed the right infrastructure — per-provider Kafka topics for fault isolation, a circuit breaker per provider, retry-then-DLQ, an idempotency-key dedup check, and a genuinely well-reasoned delivery-rate-over-latency trade-off — and estimation was internally consistent this time (100 rps average → 200 rps peak, matching the repo's own `Peak ≈ 2× Average` convention exactly). The platform's own verdict was a hedge — **🟡 "Lean Hire / Borderline Pass"** — even though the numeric average (7.0) sits right on the ✅ Pass threshold; the axis scores explain why: **Scalability & Trade-offs (6.0)** and **Communication (6.0)** both slipped from S13, and the interviewer's own closing notes were specific — notification **priority** (OTP vs. marketing sharing a queue), **ordering guarantees**, and concrete **Kafka partition/consumer-scaling math** were never reached, and the candidate audibly lost the thread mid-walkthrough ("I confuse the walk through... I haven't finish that"). This write-up marks the verdict ⚠️ Borderline to match the platform's own hedge rather than the boundary-case arithmetic.

| | |
|---|---|
| **Problem** | Design a scalable notification system sending millions of push notifications, emails, and SMS with high delivery rates and minimal latency |
| **Focus** | Multi-channel fan-out with per-provider fault isolation, retries, idempotent delivery, and (unaddressed) priority tiers |
| **Overall** | **7.0 / 10** — ⚠️ **Borderline** *(platform's own words: "Lean Hire / Borderline Pass" — a hedge despite the numeric average landing exactly on the ✅ Pass threshold)* — down 0.5 from S13's 7.5, on a brand-new problem |
| **Strongest areas** | Requirements Gathering, Design Skills, Problem-Solving (7.0 each) |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |

## The problem

> Design a **scalable notification system** that can send **millions of push notifications, emails, and SMS messages** with **high delivery rates** and **minimal latency**.

The crux isn't sending one notification — it's sending millions across **three independent, unreliable external providers** (APNs/FCM, an email provider, an SMS provider) without letting one provider's outage stall the other two, without spamming an unsubscribed or already-notified user, and without a mass marketing blast starving a time-sensitive OTP of its delivery window. That last part — **priority** — is the one dimension this session's design never resolved: a "per-provider queue" answers fault isolation but not "should an OTP wait behind ten thousand promo emails."

## Terminology

| Term | Meaning |
|---|---|
| **Circuit breaker** | A guard in front of an unreliable dependency (here, a notification provider) with three states: **closed** (calls flow normally), **open** (the dependency has failed too often — stop calling it and fail fast) and **half-open** (after a cooldown, let a trial call through to test recovery before fully closing again). Prevents a struggling provider from being hammered further, and stops one provider's slowness from starving the workers calling it — see [Resilience Patterns](../../concepts/09-reliability-and-operations/resilience-patterns.md#4-circuit-breaker--stop-calling-a-dead-dependency) for the full state-machine diagram and how it pairs with timeouts, retry backoff/jitter, and bulkheads. |
| **Idempotency key** | A client-supplied unique token on a request so that a retried or duplicated call (e.g. Billing Service resending a payment confirmation) is recognized and **not processed twice**. The server stores a short-lived record of keys it's already handled and short-circuits a repeat. |
| **Dead-letter queue (DLQ)** | Where a notification lands after exhausting its retry budget — see [S12's terminology](../12-session/README.md#terminology) for the fuller retry/DLQ vocabulary, reused here per provider. |
| **Fan-out isolation (per-provider queue)** | Giving each notification channel (SMS, email, push) its **own** Kafka topic and consumer group, so a slow or down provider only backs up its own queue — the other channels keep delivering. |
| **Priority tier / QoS** | Classifying traffic by urgency (e.g. a login OTP vs. a marketing blast) so time-sensitive messages aren't stuck behind a large low-priority batch in the same queue. Distinct from fault isolation (which channel) — this is *which order within* a channel. |

## Requirements & estimation

- **Functional** — send **email/push/SMS** via **predefined templates**; **rate-limit** notifications per customer; **never send to an unsubscribed user**; **logging, monitoring, and alerts**. A clean, senior-flavored cut — rate limiting and the unsubscribe check were named as first-class requirements without prompting, and logging/monitoring was named as a requirement *before* any design existed (though it stayed thin later — see below).
- **Non-functional** — **scalable**, **high delivery rate**, **minimal delay acceptable**, **resilient**. Correctly leads with delivery rate over latency, foreshadowing the trade-off answer given later.
- **A good scoping question, underused** — asked upfront whether this is a public-facing or internal (service-to-service) system, then didn't push on *why* it might matter when the interviewer bounced the question back ("it doesn't matter much"). It does: an internal system can trust its callers' `user_id`s and skip public-API abuse defenses; a public one needs its own authN per end-user. Worth following through on a scoping question once asked, not just asking it.
- **Estimation, internally consistent this time** — 10M notifications/day → **10,000,000 / 86,400 ≈ 100 rps average**, peak **= 2× average = 200 rps**, matching this repo's own estimation convention exactly. No inconsistency to flag here, unlike some earlier sessions — a real, clean instance of the habit.
- **The missing number**: a **campaign-burst scenario**. 10M/day smoothed over 24 hours gives 100–200 rps, but a marketing blast to millions of users fired in a 10-minute window looks nothing like that — see the Ideal Estimation table for the worked number this session never computed, and the one the interviewer's "deeper scaling" critique was really asking for.
- **A solid API spec** — `POST /notify` with an **idempotency key in the header**, `user_id`, `notification_type`, `template_to_use`, and custom template fields (e.g. an OTP code) in the body. The idempotency key placement (header, optional) is a nice, correct detail.

![Requirements canvas for a notification system. The problem is to design a scalable notification system that can send millions of push notifications, emails, and SMS messages with high delivery rates and minimal latency. Functional requirements list the notification service supporting sending emails, push notifications, and SMS, using a predefined set of templates for SMS, email, and notifications, rate limiting notifications sent to a customer, not sending to a user who has unsubscribed, and logging, monitoring, and alerts. Non-functional requirements list scalable, high delivery rate, minimal delay acceptable, and resilient. The estimations block assumes 10 million total notifications sent per day, a throughput per second of 10 times 1 million divided by 24 times 60 times 60 equaling 100 requests per second, and a peak throughput of 200 requests per second. The API specification block lists the HTTP method POST, a request header containing an optional idempotency key, and a request body containing user_id, notification_type such as email or sms, template_to_use such as user login or live sale, and custom fields to be set such as an OTP value.](./diagrams/requirements.png)

## The design produced

![Architecture canvas produced in the interview. A Promotion Service client and a Billing Service client send a POST to notify request to a Notification Service doing authentication and rate limiting. The Notification Service reads user details like name and subscribe status from a User Cache, falling back to a User DB Reader instance on a cache miss, and routes notification events into separate Kafka message queues, one per provider such as push via Apple APNS, push via Google FCM, email via SendGrid, and SMS via Twilio. Each queue feeds its own delivery worker, which fetches the notification template from a Memory Cache, fills in user details, calls the corresponding Notification Provider API, writes to a Notification Log, and on exhausted retry attempts sends the event to a Dead Letter Queue. The Notification Service also checks a Rate Limit Cache, and both the Notification Service and the delivery workers send metrics and events to an Analytics Service.](./diagrams/architecture.png)

- **Notification Service** — authN + rate limiting entry point; looks up the caller's user details (name, unsubscribe status) from a **User Cache**, falling back to a **User DB reader instance** on a miss.
- **Per-provider Kafka topics** — one topic per channel/provider (APNs, FCM, SendGrid, Twilio), each with its **own delivery worker(s)** — a slow or down provider only backs up its own topic, not the others. The same isolation instinct S08 reached for chat gateways, correctly reused here.
- **Delivery worker** — consumes its topic, fetches the notification's template from a **memory cache**, fills in user fields, calls the provider API, writes the outcome to a **Notification Log**, and on exhausted retries (3 attempts, exponential backoff, via Kafka's own unacked-message redelivery) routes to a **Dead-Letter Queue**.
- **Circuit breaker** — introduced when asked "what if a provider is down for 30 minutes?": open the breaker per provider after a failure threshold, stop calling it, and periodically test recovery — correctly scoped **per provider**, so one open breaker doesn't affect other channels' workers. See [Resilience Patterns §4](../../concepts/09-reliability-and-operations/resilience-patterns.md#4-circuit-breaker--stop-calling-a-dead-dependency) for the canonical Closed → Open → Half-Open state machine this maps onto.
- **Fallback channels** — for something like an OTP, send via **both SMS and email** so one channel's outage doesn't block the message — a good, if reactive, answer to a provider-outage probe.
- **Idempotency** — check the idempotency key against a cache before processing; if present, treat as already-handled and skip.
- **Analytics Service** — delivery rate, open/click engagement, and unsubscribe-trend tracking — named as a component in the diagram before being asked what it's for, then explained well when prompted.
- **A self-admitted communication stumble** — mid-walkthrough the candidate lost the thread ("I confuse the walk through... I haven't finish that") and had to restart the explanation. Directly visible in the transcript, and consistent with the Communication score (6.0).

## Scorecard

| Axis | S13 | **S14** | Δ |
|---|:--:|:--:|:--:|
| Requirements Gathering | 8.0 | **7.0** | ▼ 1.0 |
| Design Skills | 8.0 | **7.0** | ▼ 1.0 |
| Problem-Solving | 7.0 | **7.0** | — |
| Scalability & Trade-offs | 7.0 | **6.0** | ▼ 1.0 |
| Communication | 7.0 | **6.0** | ▼ 1.0 |
| **Overall** | 7.5 | **7.0** | ▼ 0.5 |

> **A moderate dip, not a crash — the third fresh-problem session running that didn't fall apart on first contact, but the first of the three to slip below 7.2.** Requirements/Design/Problem-Solving held at a respectable 7.0 (the infrastructure — Kafka isolation, circuit breaker, DLQ, idempotency — is now a genuinely reusable toolkit across sessions). What actually cost points was **new to this domain**: priority tiers and ordering were never raised, and the concrete "how many partitions, how many consumers" math the interviewer explicitly asked for stayed at "make it stateless and scale horizontally." Combined with the mid-session communication stumble, Scale and Communication both fell to 6.0 — the platform's own hedge ("Lean Hire / Borderline Pass") reads as accurate given the specific, cross-cutting nature of what's missing.

## What lost points — and the fix

| What I missed in the room | What a senior would say | Study |
|---|---|---|
| **Notification priority (OTP vs. marketing) never addressed** — the interviewer named this directly at the buzzer: would they share a queue? | No — split by **channel × priority tier** (e.g. `sms.high` / `sms.low`), not channel alone. A time-sensitive OTP must never sit behind a marketing batch in the same partition. | [Message Queue](../../concepts/07-messaging-and-events/message-queue.md) |
| **Ordering guarantees never raised** — does it matter if two notifications to the same user arrive out of order? | Partition each per-channel topic by **`user_id`** so one user's notifications on one channel stay ordered; note explicitly that ordering *across* channels (a push vs. an SMS for the same event) isn't guaranteed and generally doesn't need to be. | [Sharding & Partitioning](../../concepts/05-databases-and-storage/sharding-and-partitioning.md) |
| **Scaling stayed at "stateless, so horizontal scale" — no concrete math** — the interviewer's own critique: practice calculating partition counts, replica needs, throughput per node | Compute it: if a delivery worker sustains ~50 provider calls/sec, a burst of a few thousand rps needs dozens of partitions/consumers per hot topic, not a hand-wave. Say the number, not just the mechanism. | [Databases — Scaling](../../concepts/05-databases-and-storage/databases-scaling.md) |
| **Monitoring named as a requirement, never made concrete** — "logging, monitoring, alerts" appeared upfront, but no specific alert or threshold was ever named | Name the actual triggers: **DLQ depth over N**, **circuit breaker open for over M minutes**, **per-provider failure rate over X%**, **consumer lag over a threshold** — a named requirement with no concrete alert is only half-credit. | [Observability](../../concepts/09-reliability-and-operations/observability.md) |
| **Every fix was reactive** — circuit breaker, fallback channels, and the delivery-rate-vs-latency trade-off were all *correct*, but all arrived only when asked | Volunteer them: "I'd add a circuit breaker per provider before you ask, because provider outages are the most likely failure here" is the Lean-Hire→Hire lever this tracker keeps naming. | [Answer Framework](../answer-framework.md) |

## What went well

- **Estimation was internally consistent** — 100 rps average, 200 rps peak, cleanly matching `Peak ≈ 2× Average`. No contradiction to flag, a real and now-recurring strength.
- **Per-provider Kafka topics for fault isolation** — reused the exact isolation instinct from S08's chat gateways in a new domain, unprompted.
- **Circuit breaker correctly scoped per provider** — reached for the right pattern when pushed on an extended outage, and correctly reasoned that an open breaker on one provider shouldn't affect the others.
- **Idempotency handled at the API layer with a header-based key** — clean placement, and the dedup mechanism (check-before-process against a cache) is the right shape.
- **A genuinely well-reasoned trade-off**: prioritizing delivery rate over latency, with the correct justification (most notifications tolerate a few seconds of delay; a lost notification is worse than a late one).
- **Honest, specific answer on cache failure** — rather than hand-waving, named exactly what degrades (personalized fields become unavailable) if the User Cache is fully down, and that the DB reader fallback is what keeps it from being a hard outage.
- **This closes a real gap in the practice log** — the [notification-system backlog item](../../docs/TODO.md) flagged as unpracticed now has a first real attempt, and it landed the fault-isolation and resilience fundamentals cleanly.

---

## The ideal design

**The crux:** fan out one logical event across three independent, unreliable external providers, where the two axes that actually define the system are **which provider** (fault isolation — the part this session got right) and **which priority** (an OTP must never wait behind a marketing blast — the part this session never reached), while staying idempotent and honoring unsubscribes on every send.

### Ideal estimation (decision-tied)

| Number | Value | Decision it forces |
|---|---|---|
| Steady throughput | 10M/day ÷ 86,400s ≈ **100 rps avg**, ×2 → **200 rps peak** | Confirms the steady-state load is modest — a handful of stateless service instances and a small consumer pool would cover it alone |
| **Campaign burst** | A promo blast to 5M users in a 10-minute window ≈ 5,000,000 ÷ 600s ≈ **8,300 rps** — a **~40× spike** over the smoothed peak | The steady-state number *undersells the real design problem*; Kafka must absorb a burst this size without rejecting writes, and the low-priority topic's consumer pool must be sized (or autoscaled) for it — never assume "2× average" covers a marketing send |
| Partition / consumer sizing | If one delivery worker sustains ~50 provider calls/sec (network + provider latency bound), 8,300 rps ÷ 50 ≈ **~166 consumers** needed across the low-priority topics during a burst | Forces the partition count (must be ≥ the peak consumer count, since Kafka caps parallelism at partition count) and an autoscaling policy on the low-priority consumer group, separate from the always-small high-priority pool |
| Per-provider outbound rate | A single provider (e.g. Twilio) rate-limits inbound calls — say ~1,000 req/sec allowed | Caps how many workers can safely call one provider concurrently regardless of internal capacity — the circuit breaker's failure threshold and a client-side rate limiter both need to respect this external ceiling |

### Functional & non-functional requirements (the ideal cut)

- **Functional** — send via SMS/email/push using **templates**; **per-user, per-channel rate limiting**; **honor unsubscribe** on every send; **idempotent** delivery via a client-supplied key; **priority tiers** (transactional/OTP vs. marketing/best-effort); **delivery status** tracking (queued/sent/delivered/failed) exposed back to the caller and to analytics; **fallback channel policy** for critical sends (configurable per notification type, not automatic for everything).
- **Non-functional** — **delivery rate over latency** (correctly reasoned in the room, kept as-is); **fault isolation per provider**; **burst absorption** for campaign-scale sends without dropping writes; **auditable** (every send logged, unsubscribes never violated).

### Ideal architecture

![Architecture diagram for the ideal notification system. Billing and Promotion service clients call a Notification API that authenticates, applies a per-client rate limit, and checks an idempotency cache and a user preference and unsubscribe cache before proceeding, also checking a per-user and per-channel rate-limit config store. A priority classifier routes each notification into one of six Kafka topics split by channel, SMS, email, or push, and by priority tier, high or low, with every topic partitioned by user_id to preserve per-user ordering within a channel. Each channel has its own pool of delivery workers consuming both its high and low priority topics, fetching the rendering template from a template cache, calling its provider through a dedicated circuit breaker, Twilio for SMS, SendGrid for email, and APNs or FCM for push, and writing every outcome to an append-only notification log. A fallback policy, for example sending an OTP through SMS then email on failure, can reroute a failed send from one channel's workers into another channel's high-priority topic. Workers that exhaust their retries send the event to a per-channel dead-letter queue with alerting. The notification log feeds a delivery and engagement event stream into an analytics service tracking delivery rate, open and click behavior, and unsubscribe trends. A monitoring and alerting component watches dead-letter queue depth, circuit breaker open duration, per-provider failure rate, and consumer lag across all three channels.](./diagrams/ideal-design.png)

- **Priority classification at the front door** — the classifier splits every notification into one of **six topics** (3 channels × 2 priority tiers), so a marketing batch physically cannot sit in front of an OTP; it's a different queue with its own consumer pool, not a field checked mid-processing.
- **Per-user ordering, per channel** — each topic is **partitioned by `user_id`**, so a given user's SMS notifications arrive in send order on that channel; ordering across different channels is explicitly not guaranteed, and doesn't need to be.
- **Fault isolation, unchanged from the session's own design** — one circuit breaker per provider, one topic-pair per channel, so an outage on one provider never touches another channel's delivery.
- **Fallback as an explicit policy, not a blanket rule** — a failed send re-enters *another channel's high-priority topic* only when the notification type's policy says so (an OTP, yes; a marketing email bounced, no) — configurable per notification type, not automatic for everything.
- **Idempotency backed by a cache with a durable fallback** — the fast path is a cache check; on a cache miss, fall back to a lookup in the durable Notification Log rather than risk a double-send during a cache outage.
- **Observability with named triggers** — see the dedicated Logging, Monitoring & Alerts section below.

### Database schema

| Table | Fields | Note |
|---|---|---|
| `notification_request` | `notification_id` (PK), `idempotency_key` (unique), `user_id`, `channel`, `priority`, `template_id`, `custom_fields` (JSON), `status` (`queued → sent → delivered → failed`), `created_at` | The durable record behind the idempotency cache — a cache miss falls back to a lookup here |
| `user_preference` | `user_id`, `channel`, `subscribed` (bool), `updated_at` | Checked on every send; the unsubscribe requirement lives here, not scattered across services |
| `template_metadata` | `template_id` (PK), `channel`, `s3_key`, `active_version`, `variables` (JSON), `updated_at` | Points at the template **body**, which lives in object storage, not in this row — see Storage choices below |
| `notification_log` | `notification_id` (FK), `channel`, `provider`, `attempt_count`, `status`, `updated_at` | Append-only outcome history — what the Analytics Service and the DLQ both read from |
| `dead_letter` | `notification_id` (FK), `channel`, `reason`, `failed_at` | One row per exhausted-retry event, per channel |

### Storage choices — which engine for which store

The actual session named "User Cache," "Rate Limit Cache," "Memory cache," and a "User DB Reader instance" without ever saying what category each runs on beyond "a cache" or "a database" — worth being explicit, because the right engine differs store by store:

| Store | Category | Example tech | Why this category, not another |
|---|---|---|---|
| `notification_request` | **Wide-column NoSQL / KV** | DynamoDB / Cassandra, keyed by `notification_id`, with `idempotency_key` as a lookup index | Write-heavy at burst (thousands/sec during a campaign), simple key-based access (insert on send, occasional status update) — the classic wide-column shape, and one that scales elastically for a traffic spike a relational store's connection pool would choke on |
| `user_preference` | **Relational (RDBMS)** | PostgreSQL — likely part of the broader User service's own DB | Small, structured rows (`user_id`, `channel`, `subscribed`), simple key lookups, infrequent writes (an opt-out is rare relative to sends) — no benefit from NoSQL's flexibility here |
| Template **body** | **Object storage**, versioned | AWS S3, key `templates/{channel}/{template_id}/{version}.html`, S3 versioning on | A template body (HTML/MJML with embedded styling, sometimes images) is exactly the blob shape S3 is built for — large-ish, read-heavy, almost never written, and S3's native **object versioning gives free rollback** without a bespoke version column. Storing it as a TEXT column in an RDBMS works at small scale but bloats table/backup size and gives up that built-in versioning. |
| Template **metadata** (`template_metadata`) | **Relational (RDBMS) or small KV**, source of truth for *which* version is active | PostgreSQL or DynamoDB — `template_id → s3_key, active_version` | A tiny, frequently-*read*, rarely-*written* pointer table; small enough that either category works, chosen mainly to sit next to whatever else the Notification Service already queries |
| Template **cache** (the session's own "Memory cache") | **In-process / Redis, pulled at startup** | Workers pull all active template bodies from S3 at boot, cache in memory (or Redis if shared across many worker instances), refresh on an **S3-event-driven invalidation** rather than a blind poll | Templates change rarely, so pulling once at startup and invalidating only on an actual update avoids re-fetching from S3 on every send while still picking up a template edit within seconds, not a stale TTL window |
| `notification_log` | **Wide-column NoSQL** | Cassandra / DynamoDB, partitioned by `notification_id` or `channel` | Append-only, high-volume outcome history — the same append-heavy, key-based shape as `notification_request`; analytics rollups (delivery rate, engagement trends) stream out of this into a separate OLAP store rather than querying it directly |
| `dead_letter` | Same **wide-column NoSQL** family, co-located with `notification_log` | Cassandra / DynamoDB | Low volume relative to the main log, but the same access shape (key lookup by `notification_id`) — no reason to introduce a second storage technology for it |
| Idempotency cache, User Cache, rate-limit config | **In-memory KV, TTL-backed** | Redis | Every one of these is a fast, ephemeral lookup on the hot send path (`idempotency_key`, `user_id`, `client:endpoint`) — exactly Redis's shape; each has a durable fallback (the tables above, or a small config table for rate limits) for a cache-miss or full cache outage |

The pattern: **wide-column NoSQL for anything append-heavy and burst-prone** (the notification and outcome records), **relational for small, slow-changing, structured data** (preferences, template metadata), **object storage for large, versioned, read-heavy blobs** (template bodies), and **Redis/in-process caches for every hot-path lookup**, each backed by one of the durable stores above so a cache outage degrades rather than breaks the send path.

### Design trade-offs

- **Split by channel × priority, not channel alone** — a single per-channel topic conflates fault isolation (which provider) with urgency (how soon), forcing a marketing batch and an OTP to compete for the same consumer's attention; splitting into a high/low pair per channel costs one extra topic per channel and removes that conflict entirely.
- **Fallback is a policy, not automatic** — auto-failing-over every failed send to another channel would silently email people who only opted into SMS, or vice versa; a per-notification-type policy (OTP: yes; marketing: no) respects channel-specific opt-in rules.
- **Burst absorption over strict peak sizing** — sizing consumers to the smoothed "2× average" peak works for steady traffic but collapses under a real campaign send; the low-priority consumer pool needs autoscaling headroom (or a bounded backlog with a burst-absorbing partition count) sized to a burst scenario, not the daily average.
- **Idempotency cache with a durable fallback, not cache-only** — a pure cache-based dedup check risks a double-send if the cache is unavailable during a retry storm; falling back to the durable `notification_request` table on a cache miss trades a slower dedup check for correctness during exactly the failure window it matters most.
- **Delivery rate over latency, kept as reasoned in the room** — a few seconds of delay is invisible to a user; a dropped notification isn't. No change from the session's own (correct) answer here.
- **Template body in versioned object storage, metadata in a small pointer table** — the session put the whole template (body included) in a relational store fronted by a memory cache; splitting the large, rarely-written, read-heavy **body** into S3 (versioned, so rollback is free) from a tiny **metadata** row (`template_id → active s3_key/version`) keeps the RDBMS small and gives template edits a built-in audit trail without a bespoke version column. Workers pull active bodies from S3 at boot and refresh on an **S3-event-driven cache invalidation**, not a blind poll — a template change propagates in seconds instead of waiting out a TTL.

### Logging, Monitoring & Alerts

"Logging, monitoring, and alerts" was named as a requirement in the room and never made concrete — here's what that actually looks like, signal by signal:

| Signal | Alert threshold | Why it matters |
|---|---|---|
| **DLQ depth**, per channel | Growing for more than ~5 minutes, or > 100 messages | A few dead-lettered messages is normal retry noise; sustained growth means a provider (or a template bug) is systemically broken, not just flaky |
| **Circuit-breaker-open duration**, per provider | Open for more than ~10 minutes | A brief open-then-recover is the pattern working as designed; an extended open means a human decision is needed — activate the fallback channel, or page the provider's status page |
| **Per-provider failure rate** | > 5% over a rolling 5-minute window | Catches a degrading provider *before* it trips the breaker's harder threshold — an early warning, not a hard failure |
| **Consumer lag**, per topic | Lag growing faster than the production rate for more than ~2 minutes | The burst-not-absorbed signal — and because topics are split by channel × priority, the specific topic that's lagging tells you exactly which channel or tier is under-provisioned |
| **Unsubscribe-rate spike** | More than ~2× the rolling baseline in an hour | An operational signal, not just an engineering one — usually means a campaign's content, frequency, or targeting went wrong, not a system failure |

## Takeaways to drill

1. **Priority is a queue-topology decision, not a processing-time check.** The moment a prompt has both time-sensitive and best-effort traffic (OTP vs. marketing, here — but the same shape recurs in any multi-tenant queue), split the queue by priority tier *before* anything else, the same way channel isolation splits by provider.
2. **When asked for scaling math, give a number, not a mechanism.** "Stateless, so it scales horizontally" answers *whether* it scales, not *how much of what you'd need* — this session's specific miss was never computing a partition/consumer count against an actual throughput target, even though the numbers were sitting right there (100–200 rps steady, easily extended to a burst scenario).
3. **A named requirement with no concrete trigger is half-credit.** "Logging, monitoring, and alerts" was named upfront (good instinct) but never got a specific threshold — DLQ depth, breaker-open duration, per-provider failure rate. Naming the category isn't the same as designing it.
4. **Ordering is a partitioning key, and it's worth stating even when nobody asks.** Any Kafka-backed design should say out loud what ordering guarantee exists and why: "partitioned by `user_id`, so one user's events on one channel stay ordered; no cross-channel guarantee, and that's fine here."
5. **Keep volunteering trade-offs before being asked — still the log's most repeated lesson.** Circuit breaker, fallback channels, and the delivery-rate trade-off were all correct and all reactive. This session's specific gaps (priority, ordering, concrete scaling) are exactly the kind of thing that scores better said proactively during the opening design pass, not recovered only under questioning.

→ Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
