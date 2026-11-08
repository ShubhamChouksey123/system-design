# Session 19 — Hotel Booking System (Booking.com style) · ✅ 7.5/10

> The first **scored** hotel-booking mock — [Session 15](../15-session/README.md) worked an Airbnb-style variant solo, with no score. This prompt is the Booking.com shape: hotels with **room types and per-date inventory counts**, dynamic pricing, external payments, and thousands of properties. The platform scored it **7.5/10** and called it **Lean Hire** (its verdict wording sits below the ✅ Pass line this log uses, so read the header as "numerically a Pass, qualitatively a lean"). What landed: a clean read/write split, CDC-fed search (Debezium → Elasticsearch, not dual writes), a step-by-step optimistic-locking walkthrough, and a sharp read-AP / write-CP consistency statement. What cost points is the thing the interviewer asked about directly and the answer slid past: **the window between reserving inventory and receiving payment** — no hold with an expiry was ever designed. Around it: a booking and an inventory table in **separate databases**, multi-night stays spanning many inventory rows, no idempotency on the booking or payment path, estimates that contradicted themselves (1,000 vs 100,000 reads/sec), a video-style media pipeline spent on hotel photos, and search that doesn't filter by date (the same gap S15 flagged).

| | |
|---|---|
| **Problem** | Design a hotel booking system like Booking.com: inventory management, real-time availability, pricing, and concurrent bookings across thousands of properties |
| **Focus** | Never selling the same night twice (concurrency on per-date inventory) while payment happens outside your database |
| **Overall** | **7.5 / 10** — ✅ numerically *(platform's verdict: **Lean Hire**)* — down 0.5 from S18's 8.0 on a brand-new problem |
| **Weakest areas** | Problem-Solving and Communication (7.0 each) — partial-failure handling around payment, and a verbose delivery that spent time on the wrong subsystem |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |

## The problem

> Design a **hotel booking system like Booking.com** that can handle **inventory management, real-time availability, pricing, and concurrent bookings** across **thousands of properties**.

What it really tests: a **counted-inventory-per-date** model (20 Deluxe rooms on 20 September, 18 already sold), a purchase that spans **several nights and therefore several rows**, and a payment step that takes seconds to minutes and can fail — all while two guests race for the last room.

## Terminology

| Term | Meaning |
|---|---|
| **Room type** | A bookable category within a hotel (Deluxe, Platinum) with a count, price, and features — you sell *a Deluxe room*, not a specific room number. |
| **Inventory row** | One row per `(hotel, room_type, date)` holding `total_inventory` and `reserved_count`. A 3-night stay touches 3 rows. |
| **Hold (pending reservation)** | A reservation that has claimed inventory but isn't paid yet; carries an `expires_at` so abandoned checkouts release their rooms. |
| **Overbooking** | Deliberately selling more rooms than exist, expecting cancellations. Hotels do it; this design forbids it by default (`reserved_count <= total_inventory`) and treats it as a policy extension. |
| **Optimistic locking / conditional update** | Write only if the row is still what you read (version match) or still satisfies the rule (`reserved + n <= total`); the loser gets zero rows affected, not a lock wait. |
| **Idempotency key** | Client-supplied token making a retried `POST` return the first result instead of booking or charging twice. |
| **CDC** | Change data capture — streaming the database's write-ahead log (here via Debezium) to keep a search index in sync without dual writes. |

## Requirements & estimation

- **Functional** — browse/search hotels and room types; check availability; reserve one or more rooms for dates; cancel; **dynamic pricing**; **external payment** (Stripe/PayPal); admin add/update/delete hotels and rooms. Strong clarifying questions: payment up front vs. at check-in (answer: up front, paid = confirmed), and whether pricing is dynamic (yes) — both changed the design. Missing: **search by date range**, cancellation/refund policy, and overbooking policy (the platform's own note).
- **Non-functional** — concurrent bookings, no data loss, highly available, fast reads. Right set; the consistency split (CP writes, AP reads) was stated cleanly later but not on the canvas.
- **Estimation** — 100K hotels × 50 rooms × 70% occupancy ÷ 3-day stays ÷ 86,400 s. The canvas says **~10 bookings/s**; the arithmetic gives 5M × 0.7 ÷ 3 ≈ 1.17M bookings/day ≈ **13.5/s**, peak ≈ 27/s — rounded down, and the speech garbled the divisor (`24 into 16 to 60`). Reads at 100:1 → **1,000 rps**; 1M users. Reasonable and decision-capable.
- **The inconsistency** — in the scaling answer the candidate said "read throughput is **100,000** requests per second, so the DB is the first bottleneck." The canvas says 1,000. At 1,000 rps (even 14K with a realistic search-heavy funnel) a cached read path and a single primary are comfortable; the number never decided anything, which is the recurring estimation miss.
- **API and schema, produced late but produced** — 5 tables (`hotel`, `room_type`, `room_type_inventory`, `reservation`, `user`) plus `admin`, and admin / user-facing endpoints. Gaps: `reservation` has no `status`, `expires_at`, `price`, or `payment_id`; `GET /availability/{hotel_id}/{room_type_id}` has no dates; no cancel, pay, or webhook endpoint; no idempotency header; admin has `GET`/`POST`/`DELETE` but no update.

![Requirements canvas for a hotel booking system. Functional requirements: browse and search hotels and room types, get availability of a room, reserve rooms for a desired date, cancel a booking, dynamic pricing, payment using an external provider, and admin add update delete of hotels or rooms. Non-functional: handle concurrent bookings, reliable with no data loss, highly available, fast reads. Estimations: 100 thousand hotels, 50 rooms average, 3 day average stay, 70 percent occupancy, about 10 bookings per second write throughput, read to write 100 to 1, 1000 reads per second, 1 million users. The right side lists the DB schema with hotels, room_type, room_type_inventory, reservation, user and admin tables, and admin, room type, and user facing API endpoints.](./diagrams/requirements.png)

## The design I produced

![Architecture canvas produced in the interview. A guest goes through a user API gateway with authentication, authorization, and rate limiting to a Search service backed by Elasticsearch, a Hotel Read service with a hotel cache in front of the Hotel DB reader instance, a Rate service, a Booking service, and a Payment service that calls an external payment provider and receives a webhook, and also runs an async job that fetches pending payment status. The Booking service writes to a Bookings DB and to an Inventory DB writer with a replicated reader instance behind an inventory cache; the inventory table holds total rooms, reserved rooms, and a version. A Debezium instance reads the Hotel DB write-ahead log into CDC events consumed by an upload worker that indexes into Elasticsearch. An admin goes through an admin API gateway to a Hotel Writer service, uploads images to AWS S3 with a pre-signed URL, which triggers a transcode pipeline with a manager and workers that produce renditions and report back, and a CDN serves media.](./diagrams/architecture.png)

- **Read path** — gateway (authN/authZ/rate limit) → **Search service → Elasticsearch**, kept current by **Debezium reading the Hotel DB's WAL → Kafka → index worker**; hotel detail via a **Hotel Read service + cache-aside Hotel cache** (TTL + purge on admin update) over a reader replica.
- **Booking path** — Booking service checks the Inventory DB (reading the **writer**, not the cache or replica), hands back a reservation ID, the user pays through the **Payment service** (PaymentIntent via an external provider), and a webhook flips the payment to done and the booking to confirmed; an **async job** polls pending payments as a lost-webhook backstop.
- **Concurrency** — optimistic locking with a `version` column plus a DB constraint (`reserved <= total`) plus an application check; the loser gets "room not available." Trade-off stated correctly: occasional rejections under contention vs. pessimistic locking's DB load.
- **Admin + media** — pre-signed S3 upload, event-driven pipeline, CDN. Spent roughly as much time as the booking flow (see below).
- **Weak spots** — `Bookings DB` and `Inventory DB` are drawn as **separate databases** written by one service (no atomicity between "decrement inventory" and "record booking"); the Rate service is a box with one edge into the inventory cache and no explanation of how a price is computed or locked; no hold/expiry component; no idempotency store; no reaper or release path.

## Scorecard

Scored by the mock platform. Compared against the previous session (S18); S15, the self-practiced hotel variant, had no score.

| Axis | S18 | **S19** | Δ | Note |
|---|:--:|:--:|:--:|---|
| Requirements | 8.0 | **8.0** | — | Good payment/pricing clarifiers and decision-capable estimates; no date-range search, overbooking/cancellation policy; 1K vs 100K reads inconsistency |
| Design | 8.0 | **8.0** | — | Clean service split, CDC search, read/write DB separation; booking and inventory in separate DBs, no hold/expiry, Rate service undefined |
| Problem-Solving | 7.0 | **7.0** | — | Optimistic locking walked through well; the interviewer's reserve-to-pay window question was answered with locking instead of a hold; partial failure unexplored |
| Scale & Trade-offs | 8.0 | **8.0** | — | Locking trade-off and CP-writes / AP-reads split were clear and volunteered; no sharding discussion, estimate didn't drive the "DB bottleneck" claim |
| Communication | 8.0 | **7.0** | ▼ 1.0 | Outline up front and a detailed diagram; answers ran long, the candidate's own closing remark was that concurrency was hard to explain concisely |
| **Overall** | **8.0** | **7.5** | ▼ 0.5 | ✅ numerically; platform verdict **Lean Hire** |

> **A small dip on a fresh problem, in the same band as S12–S14.** The S18 habits (outline first, volunteered trade-offs, spike-style estimation) held; what's new is domain depth: the money-in-the-middle window and multi-row inventory atomicity are the crux of booking systems and were only half-solved. The platform's closing advice — lead with a one-sentence answer, expand only on request — is the right fix for the Communication slip.

## What lost points — and the fix

| What I missed in the room | What a senior would say | Study |
|---|---|---|
| **No hold between reserve and pay** — the interviewer asked how another guest is blocked during the payment window; the answer was optimistic locking, which prevents oversell but not the abandoned-checkout problem | Reserving **is** the hold: insert the reservation as `PENDING` with `expires_at = now + 10 min` in the same transaction that bumps `reserved_count`; a **reaper** expires stale PENDING rows and releases the nights; the webhook does the guarded transition `PENDING → CONFIRMED`. Late payment after expiry → re-acquire inventory or auto-refund. | [Concurrency Control](../../concepts/08-distributed-systems/concurrency-control.md) |
| **Bookings DB and Inventory DB drawn separately** — "decrement inventory" and "record booking" can't commit together | Put `reservation` and `room_type_inventory` in **one database** (sharded by `hotel_id` if ever needed) so the hold is one local ACID transaction; use the outbox + Kafka for everything else (notifications, search refresh). Cross-DB would need a saga and compensations — avoid it. | [Sharding & Partitioning](../../concepts/05-databases-and-storage/sharding-and-partitioning.md) |
| **Multi-night stays span several inventory rows; the lock example was garbled** ("total 20, reserved 90, version 100") | A 3-night stay is **3 conditional updates in one transaction**, ordered by date to avoid deadlocks, rolled back if any returns 0 rows: `UPDATE … SET reserved_count = reserved_count + :n WHERE hotel_id=? AND room_type_id=? AND date=? AND reserved_count + :n <= total_inventory`. The conditional `WHERE` is already atomic; `version` is optional, and a `CHECK (reserved_count <= total_inventory)` is the backstop. | [Concurrency Control](../../concepts/08-distributed-systems/concurrency-control.md) |
| **Estimates didn't decide anything and contradicted themselves** — 1,000 rps on the canvas, 100,000 in the bottleneck answer; "10 bookings/s" (really ~13.5); no sharding case either way | Use the numbers: ~27 bookings/s peak and ~9 GB of inventory rows per year fit **one primary + replicas** — say "no write sharding needed, `hotel_id` is the key if we outgrow it." Reads ≈ 1–14K rps are a cache-and-index problem, not a DB-sharding one. | [Estimation](../../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md) |
| **No idempotency on booking or payment** — a retried `POST /book` or a duplicated webhook could double-book or double-charge | `Idempotency-Key` header → `key → reservation_id` store; PaymentIntent keyed by `reservation_id`; webhook deduped by provider event id and signature-verified. A crash after commit but before the response is safe on retry. | [API Design](../../concepts/04-apis/api-design.md) |
| **Partial failure around payment left open** (interviewer's own note) — payment service down after inventory is reserved; webhook never arrives; pay succeeds after the hold expired | Service down → hold expires, inventory returns, the user retries. Lost webhook → the reconciliation job polls the provider for PENDING older than N minutes (the candidate's async job, given a stated purpose). Late success → guarded transition fails → refund or re-acquire. | [Resilience Patterns](../../concepts/09-reliability-and-operations/resilience-patterns.md) |
| **Media pipeline built for video, not photos** — GOP chunking, transcode manager with heartbeats, adaptive-bitrate streaming, for hotel images; it took about as long as the booking flow | Photos need pre-signed upload → S3 event → a **resize worker** (thumbnails, WebP, a couple of widths) with a DLQ → CDN. State it in three sentences and return to the crux. Borrowing S12 wholesale reads as pattern-matching, and it burned the time the hold/expiry design needed. | [Object / Blob Storage](../../concepts/05-databases-and-storage/object-blob-storage.md) · [CDN](../../concepts/03-networking-and-delivery/cdn.md) |
| **Search isn't date-aware** — Elasticsearch finds hotels by city/name; availability is a separate call | Search returns candidates from ES, then an **availability filter** batch-checks cached inventory for the requested dates and drops sold-out hotels; slight staleness is fine, the reserve step is the authority. Same gap as [S15](../15-session/README.md). | [Full-Text Search](../../concepts/05-databases-and-storage/full-text-search.md) |
| **Dynamic pricing named, never designed** — a Rate service box only | Quote at search time (cacheable, short TTL), **lock the price into the reservation at hold time** so the guest pays what they saw; occupancy/season/demand rules live in the Rate service, inputs from the inventory cache. | [Caching](../../concepts/06-caching/caching.md) |
| **Schema and API incomplete** — no `status`/`expires_at`/`price`/`payment_id` on `reservation`; availability endpoint without dates; no cancel/pay endpoint | See the schema table below; add `POST /reservations/{id}/cancel`, the payment webhook, `Idempotency-Key`, and `?start=&end=` on availability. | [Databases](../../concepts/05-databases-and-storage/databases-fundamentals.md) |
| **Verbose delivery** (platform note; candidate flagged it too) — explanations ran long, especially concurrency | Pyramid: one-sentence answer, one reason, the step-by-step only if asked ("conditional UPDATE per night in one transaction, so exactly one wins the last room"). | [Answer Framework](../answer-framework.md) |

## What went well

- **Outline first, clarifiers early** — payment timing and dynamic pricing asked before drawing, and both reshaped the design.
- **Read/write separation held throughout** — reader/writer instances, and the explicit rule "bookings read the writer, never the cache or replica."
- **Optimistic-locking walkthrough was concrete** — two users, the last room, one commit, one rejection.
- **CP-writes / AP-reads said out loud and justified** — "we don't want double booking or double charge" — the CAP split that went unstated in S10/S12/S13.
- **CDC over dual writes** for the search index (Debezium → Kafka → Elasticsearch).
- **Pre-signed S3 uploads and a DLQ** on the media path.
- **Observability with business metrics** — consumer lag, hit ratios, per-service error/latency, JVM/GC, and the payment failure ratio.
- **Good self-diagnosis at the close** — identifying that "too much to say" is the delivery problem, not a knowledge gap.

---

## The ideal design

**The crux:** never sell the same room-night twice when a purchase spans many per-date inventory rows and a payment that happens outside your database — so the reservation **is** the hold, it commits atomically with the inventory decrement, and everything after it (pay, confirm, expire, cancel) is a guarded state transition.

### Ideal estimation

| Number | Value | Decision it forces |
|---|---|---|
| Bookings | 100K × 50 × 0.7 ÷ 3 ≈ 1.17M/day ≈ **13.5/s avg, ~27/s peak** | One relational primary handles it; no write sharding needed |
| Reads | 100:1 → ~1.4K rps (a search-heavy funnel could be 10×: ~14K) | Elasticsearch + Redis caches carry reads; the booking DB never serves search |
| Inventory rows | 100K hotels × ~5 room types × 365 days ≈ 180M rows/yr × ~50 B ≈ **~9 GB/yr** (×3 ≈ 27 GB) | Fits one primary + replicas; partition by `hotel_id` is headroom, not a need |
| Reservations | 1.17M/day × ~300 B ≈ 350 MB/day ≈ ~130 GB/yr | Archive reservations after checkout + N months to cold storage |
| Concurrent holds | 13.5/s × 600 s (10-min hold) ≈ **~8K PENDING rows** | The reaper's `expires_at` index scan is trivial; a short hold keeps abandoned carts from starving real demand |
| Hot key | Peak sale, 1,000 guests on the last room of one hotel-night | Contention is on a handful of inventory rows; the conditional UPDATE serializes it, losers fail fast with "sold out" — no queue needed |
| Photos | 100K × 20 photos × 3 MB ≈ **6 TB** originals (+ resized renditions ≈ 10 TB) | S3 + CDN; resize workers, not a video-transcode pipeline |

### Functional & non-functional requirements (the ideal cut)

- **Functional** — search by city/dates/filters with availability filtered; hotel + room-type detail; availability by date range; reserve (hold) → pay → confirm; cancel with a refund policy; **dynamic price quoted and locked at hold time**; admin CRUD and bulk inventory updates; confirmation/cancellation notifications (via the [notification system](../18-session/README.md)). Explicitly out of scope for v1: overbooking policy, multi-currency.
- **Non-functional** — **no double booking** (CP on the booking path); **no lost reservations** (durable commit, outbox events); reads fast and highly available (AP, cache-first); payments idempotent; every abandoned hold self-heals.

### Ideal architecture

![Architecture diagram for the ideal hotel booking system. A guest and a hotel admin go through an API gateway. The read path, cache first, has a Search service over Elasticsearch that passes candidate hotel ids to an availability filter backed by a Redis availability cache filled from booking database replicas, a Hotel read service with a Redis hotel cache over the Hotel DB, and a Rate service that quotes and locks dynamic prices. The booking path has a Booking service that checks an idempotency store and then runs one transaction on the Booking DB primary, which holds the room type inventory and reservation tables in the same database, doing a conditional update per night and inserting a pending reservation with an expiry. A Payment service creates a PaymentIntent with the external provider keyed by reservation id and receives a signed, deduplicated webhook that moves the reservation from pending to confirmed. A hold reaper expires pending reservations and releases inventory, a reconciliation job polls the provider for old pending reservations, and the Booking service emits outbox events through Kafka to the notification system. The admin path has a Hotel writer service with the Hotel DB, Debezium reading the write-ahead log into Kafka and an index worker updating Elasticsearch, and pre-signed S3 uploads feeding an image resize worker with a dead-letter queue and a CDN. Booking, reaper, payment, and Kafka feed monitoring and alerting.](./diagrams/ideal-design.png)

- **Reserve (hold)** — `POST /reservations` with `Idempotency-Key`. The Booking service dedupes, asks the Rate service for a locked price, then in **one transaction on the primary**: for each night (ordered by date) run the conditional `UPDATE … reserved_count + :n <= total_inventory`; if any night affects 0 rows, roll back and return `409 sold out`; otherwise insert `reservation(PENDING, expires_at = now+10m, price, idempotency_key)`. Commit. Return the reservation id and the payment client secret.
- **Pay and confirm** — the Payment service creates the PaymentIntent keyed by `reservation_id`. The provider's **signed webhook**, deduped by event id, calls Booking: `UPDATE reservation SET status='CONFIRMED' WHERE id=? AND status='PENDING'`. Zero rows (hold expired or already confirmed) → look at whether inventory can be re-acquired, else refund.
- **Expire** — the **reaper** runs every ~30 s: expire PENDING past `expires_at` and decrement `reserved_count` per night in the same transaction. The **reconciliation job** polls the provider for PENDING older than N minutes — the lost-webhook backstop (the candidate's async job).
- **Cancel** — guarded `CONFIRMED → CANCELLED`, decrement nights, refund per policy, emit an event; partial cancel works because each room type is its own `reservation` row (the candidate's good answer).
- **Search** — Elasticsearch narrows by city/geo/filters; the **availability filter** batch-reads `hotel:room_type:date` counters from Redis (TTL ~30 s, filled from replicas) and drops sold-out hotels. Stale-by-seconds is acceptable; the reserve transaction is the authority. Same CDC pipeline as the candidate's (Debezium → Kafka → index worker) keeps ES current.
- **Plain-language picture** — a hotel front desk with a sticky note: when you ask for a room, the clerk writes your name on the room-nights *and* pencils in a 10-minute deadline; pay in time and it's inked; miss it and the note comes off. One clerk-desk (one database) means two guests can't both get the pencil.

### Database schema

| Table | Fields | Note |
|---|---|---|
| `room_type_inventory` | `hotel_id`, `room_type_id`, `date` (PK together), `total_inventory`, `reserved_count`, `version` (optional) | **Crux table.** `CHECK (reserved_count <= total_inventory)`; one row per night, updated by the conditional UPDATE |
| `reservation` | `id` (PK), `idempotency_key` (unique), `user_id`, `hotel_id`, `room_type_id`, `start_date`, `end_date`, `rooms`, `price_locked`, `status` (`PENDING → CONFIRMED / EXPIRED / CANCELLED`), `expires_at`, `payment_id`, `created_at` | Lives in the **same database** as the inventory; index on `(status, expires_at)` for the reaper |
| `payment` | `id`, `reservation_id`, `provider_intent_id`, `status`, `provider_event_ids` | Dedupe key for webhooks |
| `hotel` | `id`, `name`, `address`, `geo`, `status` | Source of truth for search via CDC |
| `room_type` | `id`, `hotel_id`, `name`, `base_price`, `features` (JSON), `capacity` | Static attributes; photos referenced by S3 key |
| `user` | `id`, `name`, `email` | Admins are a role on `user`, not a separate table |

### Storage choices — which engine for which store

| Store | Category | Why this category, not another |
|---|---|---|
| `room_type_inventory`, `reservation`, `payment` | **Relational** (PostgreSQL / MySQL) | Needs multi-row ACID, a `CHECK` constraint, and guarded status transitions in one transaction — the exact job NoSQL's per-item atomicity makes awkward; volume (~9 GB/yr inventory) fits one primary |
| `hotel`, `room_type` | **Relational** | Small, structured, admin-written, with CDC to the index |
| Search index | **Search index** (Elasticsearch) | Geo, text, and facet queries over static attributes; a relational `LIKE` won't do |
| Availability cache, hotel cache, idempotency store | **In-memory KV with TTL** (Redis) | Hot, ephemeral lookups with a durable fallback (replica / primary / reservation row) |
| Photos | **Object storage** (AWS S3) + CDN | Large, read-mostly blobs; originals plus resized renditions |
| Events | **Log-based broker** (Kafka) | CDC and outbox events replayable to ES and notifications |

### Design trade-offs

- **Hold with TTL over "reserve on payment success"** → the hold prevents a guest paying for a room someone else just took, at the price of temporarily withholding inventory (10 min) from other guests; a shorter TTL reduces that cost.
- **One database for inventory + reservation over service-per-table** → one local transaction instead of a saga with compensations; costs independent scaling of the two, irrelevant at ~27 writes/s.
- **Conditional UPDATE (+ CHECK) over a `version` column or pessimistic locks** → the rule itself is the guard; no read-then-write round trip, no lock waits. Losers get an immediate "sold out." Switch to pessimistic locking only if contention-driven retries become the dominant cost.
- **CP writes, AP reads** → booking reads the primary; search/detail/availability use caches and replicas with seconds of staleness; the final reserve step corrects any stale "available" the guest saw.
- **Date-aware search via ES + availability filter, not availability in ES** → availability changes every booking; indexing it would turn each reservation into an index write. A cached counter lookup per candidate keeps ES static.
- **Lock the price at hold time** → the guest pays what they saw; costs a small revenue risk if demand spikes during the 10-minute hold, usually acceptable.
- **Auto-refund late payments over resurrecting expired holds** → simpler and safe; re-acquiring inventory is an optional upgrade when it's still free.
- **CDC over dual writes** (kept from the room) → search never diverges from the Hotel DB's committed truth; costs seconds of indexing lag.

### Logging, Monitoring & Alerts

| Signal | Alert threshold | Why it matters |
|---|---|---|
| **Inventory invariant**: rows where `reserved_count > total_inventory` | **> 0, ever** | Direct evidence of a double-booking bug; the `CHECK` should make it impossible, so this catches constraint bypass |
| **Pending-hold age / backlog** (PENDING past `expires_at`) | > a few minutes past expiry | The reaper is stuck; rooms are being withheld from real guests |
| **Payment failure ratio** (failed ÷ attempted) | > 2–3 points over baseline | Provider trouble or a checkout bug |
| **Late-payment / refund-after-expiry rate** | > ~1% of confirmations | Hold TTL too short, or webhooks delayed |
| **Reconciliation backlog** (PENDING older than N min unresolved) | Growing | Webhooks being lost or provider unreachable |
| **Booking p99 latency + 409 rate**, per hotel | p99 > ~1 s; 409 spike on one hotel | A hot hotel-night, or a contention problem |
| **CDC / index lag** (Kafka consumer lag, WAL-to-ES delay) | > ~1 min | Search showing stale hotels |
| **Availability cache hit ratio** | < ~90% | The search path is leaking onto replicas |
| **Image pipeline DLQ depth** | > 0 and growing | Admin uploads silently failing |

## Takeaways to drill

1. **Reserve is the hold.** Inventory claim, reservation row, and `expires_at` commit together; a reaper cleans up; payment only does a guarded `PENDING → CONFIRMED`. Say "hold with expiry" the moment payment sits between choosing and owning.
2. **Keep atomic things in one database.** If two writes must commit together, they share a transaction — not a service boundary. Reach for the outbox for everything else.
3. **Multi-night means multi-row.** One conditional UPDATE per date, ordered, all-or-nothing in one transaction; the `WHERE` clause is the lock.
4. **Make the estimate decide.** 27 writes/s and ~9 GB/yr says "no sharding yet" — and a number you state on the canvas must match the number you use later.
5. **Don't import a pipeline wholesale.** Hotel photos need a resize worker and a CDN, not GOP chunking and adaptive bitrate; match the machinery to the media.
6. **Idempotency on every money-adjacent call** — the booking `POST`, the payment intent, and the webhook.
7. **Lead with the one-sentence answer.** "Conditional update per night in one transaction, so exactly one guest wins the last room" — then stop unless asked.

> → Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
