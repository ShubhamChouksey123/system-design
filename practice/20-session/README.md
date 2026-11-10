# Session 20 — Food Delivery Platform (DoorDash style) · ✅ 7.0/10

> A brand-new problem with three actors (customer, restaurant, driver) instead of two, scored **7.0/10** and called **Lean Hire** by the platform (numerically a Pass, qualitatively a lean). What landed: an agenda stated up front, sharp scoping questions (cash on delivery, the cancellation cut-off, dynamic pricing out of scope), CDC-fed search (Debezium → Kafka → Elasticsearch), a WebSocket gateway tier with a presence registry for live tracking, the webhook-plus-polling payment backstop, and a photo pipeline sized correctly this time (resize to WebP, not video transcoding). What cost points is the part that makes this problem *delivery* and not *e-commerce*: **dispatch** was a sentence ("notify drivers around the restaurant, one accepts") with no geo-index, no atomic claim and no timeout, so two drivers accepting the same order, a driver vanishing mid-delivery, and a restaurant rejecting the order all went unanswered unless the interviewer raised them. Around it: the busiest write path in the system (driver location, about 20K/s against about 46 orders/s) was never sized, "shard by city" had no number behind it, the API design sat on the candidate's own agenda and was never reached, and the walkthroughs repeated themselves. Scale & Trade-offs (6.0) fell 2.0 from S19; Requirements fell 1.0; the other axes held.

| | |
|---|---|
| **Problem** | Design a food delivery platform like DoorDash: restaurant management, order processing, delivery tracking, and real-time location updates |
| **Focus** | Getting exactly one driver onto each order while a location firehose and an order state machine run side by side |
| **Overall** | **7.0 / 10** — ✅ numerically *(platform's verdict: **Lean Hire**)* — down 0.5 from S19's 7.5 on another brand-new problem |
| **Weakest areas** | Scale & Trade-offs (6.0) — surface-level scaling, no number driving "shard by city"; then Requirements, Problem-Solving and Communication (7.0 each) — no driver or restaurant-side lifecycle, failure modes only when prompted, repetitive delivery |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |

## The problem

> Design a **food delivery platform like DoorDash** that can handle **restaurant management, order processing, delivery tracking, and real-time location updates**.

What it really tests: an order that moves through a **state machine driven by three different actors**, a **dispatch step that must give each order to exactly one nearby driver** while many drivers can say yes at once, and a **location stream** that is an order of magnitude hotter than the order writes themselves. Search, menus and photos are patterns the log has already solved (S12, S15, S19); the new ground is dispatch and live location.

## Terminology

| Term | Meaning |
|---|---|
| **Dispatch** | Choosing which driver is offered an order, and recording who accepted it; the matching step that makes this a logistics problem. |
| **Offer** | A request sent to one or a few nearby drivers to take a delivery; it carries a timeout and is not an assignment until a driver accepts. |
| **Assignment (claim)** | The single atomic write that binds one driver to one delivery. Offers are many; the claim is one. |
| **Geo-index** | A structure that answers "who is within 3 km of this point?" (Redis GEO, geohash, or H3 cells); a plain `driver_id → location` key cannot. |
| **Presence registry** | A map of which WebSocket gateway holds each connected user or driver, so the location service can push to the right server. |
| **Prep time** | The restaurant's estimate of how long the food takes; dispatch is timed so the driver arrives as the food is ready. |
| **Order state machine** | The guarded lifecycle `PLACED → PAID → ACCEPTED → PREPARING → READY → PICKED_UP → DELIVERED`, plus `CANCELLED` and `REJECTED` branches. |
| **Idempotency key** | Client-supplied token making a retried request return the first result instead of creating a second order or charge. |

## Requirements & estimation

- **Functional** — browse and search restaurants or dishes, view a menu, create an order with online payment **or cash on delivery**, cancel only before the meal is prepared, track the order with live delivery status and driver location; restaurant owners register a restaurant and add, update or delete menu items. Strong scoping: cash on delivery (asked, then decided), the cancellation cut-off (a clear rule with a reason: wasted food), and **dynamic pricing explicitly out of scope**. Missing: the **restaurant's side of the order** (accept, reject, mark ready), the **driver's side** (go online, accept or decline, confirm pickup and delivery), **ETA**, refunds on cancellation, and order history. The interviewer's note was the same: delivery-driver requirements were thin.
- **Non-functional** — high availability for reads, scalable, resilient. Right words, no numbers: no freshness target for driver location, nothing saying orders are CP while browsing is AP (the candidate did say it later, out loud, when asked about replicas).
- **Estimation** — 100K restaurants × 50 items; 10M users, 5M DAU, 0.2 orders per user per day → **2M orders/day ≈ 20/s, 40/s peak**; read:write 10:1 → **400 reads/s peak**. Clean and decision-capable on the order path. Gaps: the **5M DAU figure was written down and never used** (the 2M came from total users, so state which one the 0.2 applies to; with DAU it is 1M/day); lunch and dinner concentrate the day, so a real peak is closer to 80/s than 40/s, though still one primary's work; and **nothing was sized for driver location or WebSocket connections**, the only numbers in this system that are large (about 20K location writes/s and about 180K connections at peak, see the ideal estimation).
- **Sharding with no number** — the scaling answer proposed read replicas, caches and "shard by city." At 20 orders/s and about 5 GB of restaurant data nothing needs sharding; the city is the right partition for **dispatch and location** (drivers only match locally), not for the order database. A figure that decides nothing is the recurring estimation miss.
- **API and schema, promised but not produced** — "API design / DB schema" sat on the opening agenda; the schema was named aloud (restaurant, menu item, order, payment, user, delivery person) and two endpoints appeared on the canvas (`POST /menu`, `GET /menu/{restaurant_id}`). No columns, no order status field, no order-items table, no payment-table drawing (the candidate said so), no driver or delivery endpoints. The interviewer ended on "worth exploring the API design you mentioned."

![Requirements canvas for a food delivery platform. The agenda lists functional requirements, non functional requirements, estimations, architecture, walkthrough, API design and DB schema, trade offs, and logging monitoring and alerts. Functional requirements: browse and search restaurants or food items, view menu, create an order from a restaurant with payment, support cash on delivery, cancellation only before the meal is prepared, track the order with real time delivery tracking, and an admin side where restaurant owners register their restaurant and add, delete or update menu items. Non functional: high availability for the reads, scalable, resilient. Out of scope is dynamic pricing. Estimations: 100 thousand restaurants, 50 menu items per restaurant, 10 million total users, 5 million daily active users, 0.2 orders per day per user, average throughput 2 million orders per day which is about 20 orders per second, peak throughput 40 orders per second, read to write ratio 10 to 1, and peak read throughput 400 reads per second.](./diagrams/requirements.png)

## The design I produced

![Architecture canvas produced in the interview. Buyers and restaurant owners go through an API Gateway with authentication, authorization and rate limiting. A Restaurant Write Service writes to a Restaurant DB writer instance that replicates to a reader instance, invalidates a restaurant cache, and has a Debezium instance reading the write ahead log into Kafka, where an upload worker indexes into AWS Elasticsearch for a Search Service. A Restaurant Read Service reads the restaurant cache and falls back to the reader instance. An Order Service creates an order with pending payment status in an Order DB writer instance with a reader instance and an order cache, calls a Payment Service that charges an external payment provider, receives a webhook and also runs an async job that pulls the status of pending payments, then updates the order and adds an order event to Kafka, which a Notification service consumes to inform the restaurant owner. A Delivery Service sends notifications to delivery persons, records accepted deliveries in a Delivery DB, and reads a delivery person location cache in Redis. Delivery persons connect through WebSocket Gateways A and B; a Location Service updates the location cache, looks up connected users in a presence registry, and sends the location to the buyer's gateway. Restaurant owners upload images to AWS S3 with a pre-signed URL, an image processing step checks malware and converts to WebP and several resolutions, and a CDN serves images.](./diagrams/architecture.png)

- **Read path** — search through **Debezium on the restaurant DB's WAL → Kafka → upload worker → AWS Elasticsearch** (dish, restaurant, rating); restaurant detail through a **Restaurant Read service + Redis cache** over a reader replica; orders read from the **writer**, restaurant and menu data tolerate replica staleness. The consistency split was justified correctly when the interviewer pushed on it.
- **Order and payment** — Order service creates a **pending order**, Payment service charges the provider, and a **webhook plus an async polling job** settle the status; the order service flips the payment state and puts an event on Kafka for the restaurant notification. Good resilience thinking, with an idempotency gap noted below.
- **Delivery and tracking** — the Delivery service consumes the order event, finds drivers near the restaurant, notifies them, and writes a `delivery` row when one accepts. Drivers hold a **WebSocket** to a gateway; a **Location service** writes the **Redis location cache** and pushes updates to the buyer's gateway through a **presence registry**. The scaling answer for this tier (more gateways plus a registry for routing) is the right shape, reused from S08/S13.
- **Media** — pre-signed S3 upload → malware check → WebP and multiple widths → CDN. Proportionate to photos, the opposite of S19's video-grade pipeline.
- **Weak spots on the canvas** — a **`Restaurant Write Service` box sits unwired next to the Order service** (a stray duplicate); **two Notification service boxes** and **two API gateways** without a stated reason; the Kafka order-events queue is **unlabeled and has no edge into the Delivery service**, though the walkthrough said the Delivery service consumes it; the **Payment DB was admitted as undrawn**; the location cache is a per-driver key, so "drivers around this restaurant" has no structure to run on; and there are **no accept, reject or ready endpoints** for the restaurant, nor a cancel path.

## Scorecard

Scored by the mock platform. Compared against the previous session (S19).

| Axis | S19 | **S20** | Δ | Note |
|---|:--:|:--:|:--:|---|
| Requirements | 8.0 | **7.0** | ▼ 1.0 | Good cash-on-delivery, cancellation and dynamic-pricing scoping and a clear agenda; no driver or restaurant-side requirements, no ETA, and the estimate left out the location and connection load |
| Design | 8.0 | **8.0** | — | Well-separated services; CDC search, pre-signed uploads and an image pipeline, WebSocket gateways with a presence registry; dispatch undefined, canvas had unwired and duplicated boxes |
| Problem-Solving | 7.0 | **7.0** | — | Webhook plus polling payment backstop and an answer for a payment-service outage; driver reassignment, restaurant rejection and two-drivers-one-order never raised |
| Scale & Trade-offs | 8.0 | **6.0** | ▼ 2.0 | Replicas, caches, city sharding named; the platform called it surface-level — no capacity planning, no load-balancing detail, replication lag unquantified |
| Communication | 7.0 | **7.0** | — | Agenda up front and a dense, legible diagram; repeated points and long walkthroughs that crowded out API design and scaling depth |
| **Overall** | **7.5** | **7.0** | ▼ 0.5 | ✅ numerically; platform verdict **Lean Hire** |

> **A bigger dip on Scale than on any other axis, on a problem whose scale story is the point.** S19's 8.0 came from volunteering the locking and CAP trade-offs; here the same candidate stayed at "we use replication" and "shard by city" without a number. The pattern matches [S14](../14-session/README.md): the infrastructure habits transfer to a new domain, the domain-specific layer (here dispatch and location volume) needs its own first pass.

## What lost points — and the fix

| What I missed in the room | What a senior would say | Study |
|---|---|---|
| **Dispatch was a sentence, not a design** — "search people around the restaurant and notify them; one accepts and a delivery row is created." No geo query structure, no rule for two drivers accepting at once, no timeout, no retry | Run `GEOSEARCH` on a per-city **Redis GEO index** for drivers who are `AVAILABLE` near the restaurant, rank by distance or ETA, and **offer to the nearest K with a 20 s timeout**. Accept is one conditional write: `UPDATE delivery SET driver_id=:d WHERE id=? AND driver_id IS NULL`, together with `driver_state AVAILABLE → BUSY`, in one transaction; the loser gets "already taken." Expired offers widen the radius and re-offer. | [Concurrency Control](../../concepts/08-distributed-systems/concurrency-control.md) · [Redis & Memcached](../../concepts/06-caching/redis-and-memcached.md) |
| **Location cache can't answer "who is nearby"** — one cache key per driver is a lookup table, not a spatial index | Store drivers in a **geo structure per city** (`GEOADD drivers:{city}`; geohash or H3 cells are the same idea) with a `last_seen` TTL so a silent driver ages out. Partition by city because matching is local. | [Redis Sorted Sets](../../concepts/06-caching/redis-sorted-sets.md) · [Sharding & Partitioning](../../concepts/05-databases-and-storage/sharding-and-partitioning.md) |
| **The hottest write path was never sized** — 40 orders/s was estimated, driver pings were not | Little's law: 23 orders/s × ~30 min on the road ≈ 41K busy drivers (80K at peak), plus idle ones, ≈ **100K online drivers × a ping every 5 s ≈ 20K writes/s**, about 400× the order writes. That decides it: location lives in memory, never in the order database, with a sampled trail archived asynchronously. Connections: ~100K drivers + ~80K buyers watching ≈ **180K WebSockets ≈ 4–8 gateways**. | [Estimation](../../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md) · [Real-Time Communication](../../concepts/04-apis/realtime-communication.md) |
| **"Shard by city" with no number** — and for the wrong store; the replication-lag answer stayed qualitative ("takes time") | ~20 orders/s and ~0.7 TB/yr of order rows fit **one primary plus replicas**; restaurant data is ~5 GB. Say "no sharding for orders; partition location and dispatch by city, where matching is local." Quantify replica lag (typically sub-second) and name the flows that must read the primary (order status, payment, assignment). | [Sharding & Partitioning](../../concepts/05-databases-and-storage/sharding-and-partitioning.md) · [Consistency Models](../../concepts/08-distributed-systems/consistency-models.md) |
| **No order lifecycle or restaurant/driver side** — the owner is "notified" and then nothing: no accept, reject, prep time, ready, and cancellation had no status to check | A guarded state machine, each step `UPDATE … WHERE status = :expected`: `PLACED → PAID → ACCEPTED/REJECTED → PREPARING → READY → PICKED_UP → DELIVERED`; cancel allowed only while `status ∈ {PLACED, PAID, ACCEPTED}`, with a refund. Every wait has a timeout: unaccepted by the restaurant in N min → auto-cancel and refund. | [Concurrency Control](../../concepts/08-distributed-systems/concurrency-control.md) · [Event-Driven Architecture](../../concepts/07-messaging-and-events/event-driven-architecture.md) |
| **Failure modes only when the interviewer asked** — driver goes offline mid-delivery, nobody accepts, restaurant goes offline, payment succeeds after cancel (the platform's own list) | Raise them yourself: driver heartbeat lost (the geo TTL) → delivery returns to `UNASSIGNED` and re-dispatches; no driver in N attempts → alert and offer the customer a refund; restaurant rejects or times out → refund; late payment on a cancelled order → auto-refund. | [Resilience Patterns](../../concepts/09-reliability-and-operations/resilience-patterns.md) |
| **No idempotency on order or payment** — a retried `POST /orders` or a duplicated webhook can create two orders or charge twice (now a repeat from S15 and S19) | `Idempotency-Key` header → `key → order_id`; PaymentIntent keyed by `order_id`; webhooks deduped by provider event id and signature-verified. | [API Design](../../concepts/04-apis/api-design.md) · [Webhooks](../../concepts/04-apis/webhooks.md) |
| **Order and event writes not tied together; pending orders never expire** — "adds an order event" after the DB write is a dual write; an unpaid `PENDING` order lives forever | Write the order and an **outbox** row in one transaction; a relay publishes to Kafka. Expire unpaid orders after N minutes with a guarded `PLACED → EXPIRED`. | [Event-Driven Architecture](../../concepts/07-messaging-and-events/event-driven-architecture.md) |
| **Live-tracking transport switched three times** — polling the cache, then SSE, then WebSocket pushes on the canvas | Commit: drivers already hold a WebSocket for upload, so push the buyer's updates on a WebSocket too (or SSE if you want a simpler one-way channel), throttled to one update every 3–5 s per delivery; ETA recomputed on thresholds, not per ping. | [Real-Time Communication](../../concepts/04-apis/realtime-communication.md) |
| **API and schema not produced** — on the agenda, skipped, now the same miss as S18 | Two minutes: `POST /orders`, `PUT /orders/{id}/status`, `POST /deliveries/{id}/accept`, WebSocket `location` message; tables `restaurant`, `menu_item`, `orders`, `order_items`, `payment`, `delivery`, `driver_state`. See the schema below. | [API Design](../../concepts/04-apis/api-design.md) · [Databases](../../concepts/05-databases-and-storage/databases-fundamentals.md) |
| **Monitoring was infrastructure-only** — CPU, throughput, error rate, Kafka lag and replication count were all named, but no business signal | Add: time from `ACCEPTED` to driver assigned, unassigned-delivery age, offer acceptance rate, location staleness, pending-payment age, WebSocket connections per gateway. | [Observability](../../concepts/09-reliability-and-operations/observability.md) |
| **Diagram hygiene** — an unwired Restaurant Write Service box, duplicated Notification and gateway boxes, an unlabeled Kafka queue with no consumer edge to Delivery, Payment DB undrawn | Delete or wire every box; label the queue (`order-events`); draw the edge the walkthrough describes. Delivery is a scored axis. | [Answer Framework](../answer-framework.md) |
| **Repetition** (platform note) — the same point restated, and walkthroughs that crowded out API design | One sentence, one reason, details only if asked: "driver accepts with a conditional update on the delivery row, so exactly one wins." | [Answer Framework](../answer-framework.md) |

## What went well

- **Agenda on the canvas first** — functional → non-functional → estimation → architecture → walkthrough → API/schema → trade-offs → monitoring → testing; it kept the session on rails.
- **Scoping questions that changed the design** — cash on delivery, the cancellation cut-off with a reason, and dynamic pricing explicitly parked.
- **Estimation was methodical** — users → orders/day → per-second → peak → reads, with units.
- **CDC over dual writes** — Debezium on the WAL into Elasticsearch for dish and restaurant search.
- **Payment resilience, volunteered** — webhook plus an async polling job so the system is "doubly sure," and the right answer to a payment-service outage.
- **WebSocket tier with a presence registry** — gateway-to-user routing for live tracking, reused cleanly from S08/S13.
- **Read/write consistency split in plain words** — menus tolerate replica lag; orders read the writer.
- **Photo pipeline proportionate to photos** — pre-signed upload, malware check, WebP and multiple widths, CDN (the S19 lesson applied).
- **Monitoring named per layer** — services, Kafka (under-replicated partitions, bytes in and out, consumer lag), databases (size, index size), WebSocket health.

---

## The ideal design

**The crux:** an order is a guarded state machine driven by three actors, and the one genuinely new problem is **dispatch** — offer an order to several nearby drivers but bind it to **exactly one** with a single conditional write — running alongside a **location firehose (about 20K writes/s)** that has to live in memory and must never touch the order database.

### Ideal estimation

| Number | Value | Decision it forces |
|---|---|---|
| Orders | 10M users × 0.2 ≈ **2M/day ≈ 23/s avg, ~46/s peak** (lunch/dinner skew: 60% in 4 h ≈ 85/s) | One relational primary handles it either way; no order sharding |
| Browse reads | 10:1 on the canvas; a browse funnel is closer to 50:1 → **~2–4K rps peak** | Elasticsearch + Redis cache carry it; the order DB never serves browse |
| Open orders | 23/s × ~40 min (prep + ride) ≈ **55K in flight** (~110K at peak) | The "active orders" working set is small enough for primary-backed lookups and a Redis status cache |
| Online drivers and pings | ~100K online at peak × a ping every 5 s ≈ **20K location writes/s** (~2 MB/s at ~100 B) — about **400× the order write rate** | Location lives in a **Redis GEO index**, never the order DB; a sampled trail goes to Kafka → AWS S3 |
| Live tracking fan-out | ~80K busy drivers / 5 s ≈ 16K updates/s; throttle each delivery to one push per 3–5 s to the buyer | Cuts pushes ~3× and phone battery; ETA recomputed on change, not per ping |
| WebSocket connections | ~100K drivers + ~80K tracking buyers ≈ **~180K** at ~50K per gateway ≈ **4 gateways, 8 with headroom** | A presence registry is required; gateways are stateless apart from connections |
| Dispatch fan-out | 46 orders/s × K=3–5 offers ≈ **~150–250 offers/s** | Push-service load is trivial; the cost is the correctness of the claim, not the volume |
| Orders storage | 2M/day × ~1 KB ≈ 2 GB/day ≈ **~0.7 TB/yr** (~2 TB with ×3 replicas) | One primary + replicas for years; archive after N months — "shard by city" is not justified for orders |
| Restaurant data | 100K × 50 items × ~1 KB ≈ **~5 GB** | One DB + Elasticsearch copy; trivially cached |
| Photos | 5M items × ~2 MB ≈ **~10 TB** originals (+~50% renditions) | AWS S3 + CDN with a resize worker |
| Hot key | One viral restaurant at lunch: ~20 orders/min ≈ 0.3/s | Not a DB problem — the kitchen is the limit; add a per-restaurant **accept rate cap or pause** switch |

### Functional & non-functional requirements (the ideal cut)

- **Functional** — search restaurants or dishes (geo, open now, rating); view menu; place an order (online payment or COD) with the price locked; restaurant **accepts or rejects**, sets prep time, marks ready; **dispatch** to a nearby driver (accept or decline, confirm pickup and delivery); **live tracking with ETA**; cancel before preparation with a refund; push notifications; restaurant and menu management with photos. Out of scope for v1: dynamic pricing, batching several orders per driver, ratings and promotions.
- **Non-functional** — **orders and assignment are CP** (never two drivers, never a lost paid order); **browse and search are AP** (cache-first, seconds of staleness); **location is ephemeral and AP** with a freshness target of ≤ 5–10 s; every wait has a timeout and every transition is idempotent.

### Ideal architecture

![Architecture diagram for the ideal food delivery platform. A customer app, a restaurant owner app and a driver app go through an API gateway; drivers and customers also hold WebSocket connections to a tier of WebSocket gateways. The read path has a Search Service over AWS Elasticsearch, a Restaurant Read Service and a Redis restaurant and menu cache over a restaurant database replica. The admin path has a Restaurant Write Service, the Restaurant DB primary, Debezium reading the write ahead log into Kafka and an index worker updating Elasticsearch, and pre-signed uploads to AWS S3 with an image worker and a dead letter queue feeding a CDN. The order path has an Order Service that checks an idempotency store and runs one transaction on the Order DB primary inserting the order and an outbox row, a Payment Service that creates a payment intent keyed by order id with the external provider and accepts a signed deduplicated webhook, a reconciliation job that polls the provider for old pending payments, and a Kafka topic of order and delivery events fed by the outbox. A notification service pushes new orders to the restaurant owner, who accepts, rejects or marks the order ready through guarded status transitions. A Dispatch Service consumes the accepted event, searches a Redis GEO index per city for available drivers near the restaurant, creates an unassigned delivery in the Delivery DB, and offers the order to the nearest few drivers through a push service with a timeout; the accept call runs one conditional update that sets the driver on the delivery only if none is set and flips the driver state from available to busy in the same transaction. A heartbeat TTL in the geo index triggers re-dispatch when a driver goes silent. The location path has drivers sending a ping every five seconds over WebSocket to a Location Service that updates the geo index and last seen time, looks up the buyer's gateway in a presence registry, and pushes throttled location and ETA to the customer, while a Kafka location trail feeds an ETA service backed by a maps routing API and a sampled trail archive in AWS S3. Order, dispatch, location and Kafka lag feed monitoring and alerting.](./diagrams/ideal-design.png)

- **Place the order** — `POST /orders` with an `Idempotency-Key`. The Order service dedupes, then in **one transaction** inserts `orders(PLACED)` with an `order_items` price snapshot and an **outbox** row. It asks the Payment service for a PaymentIntent keyed by `order_id`; COD skips this step and goes straight to `PAID`-equivalent with a per-user COD limit. The signed **webhook**, deduped by event id, triggers the guarded `PLACED → PAID`; the **reconciliation job** polls the provider for `PLACED` older than N minutes (the candidate's async job, given a stated purpose). Unpaid orders expire.
- **Restaurant side** — the outbox relay puts `order.paid` on Kafka; a notification service pushes it to the restaurant app. The owner calls accept or reject (with a prep time) and later ready; each is `UPDATE … WHERE status = :expected`. No answer in N minutes → auto-reject and refund. Cancellation is allowed only while the status is before `PREPARING`.
- **Dispatch** — on `order.accepted` the Dispatch service starts at about *prep time − pickup travel time*, so the driver arrives as the food is ready. It runs `GEOSEARCH` around the restaurant on the city's geo index for `AVAILABLE` drivers, ranks by ETA, creates the `delivery(UNASSIGNED)` row and **offers the order to the nearest K** through the push service (WebSocket if connected, APNs/FCM otherwise) with a ~20 s timeout.
- **Accept (the claim)** — `POST /deliveries/{id}/accept` runs one transaction in the Delivery DB: `UPDATE delivery SET driver_id=:d, status='ASSIGNED' WHERE id=:id AND driver_id IS NULL` and `UPDATE driver_state SET status='BUSY' WHERE driver_id=:d AND status='AVAILABLE'`. One row on each → winner; zero → "already taken," the offer is withdrawn from everyone else. Offers expire → widen the radius and re-offer; N failed rounds → alert and let the customer cancel with a refund.
- **Driver drops** — the geo entry carries a `last_seen` TTL (~30 s). When it lapses on a `BUSY` driver, the delivery returns to `UNASSIGNED` and re-dispatches with higher priority; if the food was already picked up, route to support.
- **Live tracking** — drivers ping every ~5 s over WebSocket; the Location service writes `GEOADD` and `last_seen`, looks up the delivery's buyer in the **presence registry**, and pushes a throttled location plus ETA through that buyer's gateway. A Kafka trail feeds an ETA service (maps routing API) and a sampled archive in AWS S3 for disputes.
- **Search and media** — Debezium on the restaurant DB's WAL → Kafka → index worker → Elasticsearch (candidate's design, unchanged); the open-now and delivery-radius filter runs against the cached restaurant document. Photos: pre-signed PUT → resize worker (malware scan, WebP, widths) with a DLQ → CDN.
- **Plain-language picture** — a restaurant pass with a dispatch board: the kitchen rings a bell (order ready soon), the dispatcher shouts to the three nearest riders, the first one to grab the ticket from the hook keeps it and the others see the hook is empty. Riders who stop reporting in for half a minute lose their tickets back to the hook.

### Worked example — placing an order (what each step writes)

**Setup:** customer `U` orders from restaurant `R1` (Burger Hub): 2 × Veg Burger at 200 + a 40 delivery fee = **440**, paid online. `Idempotency-Key = key-abc`. Browsing already happened on the read path (Elasticsearch for candidates, Redis cache or a replica for the menu, cart kept on the client), so nothing has been written yet.

**Step 1 — `POST /orders` (12:00:00): create the order.** The Order service first re-prices from `menu_item` (never trusting the client's total) and checks `restaurant.accepting_orders` and `menu_item.available`. It then claims the key (`SET idem:key-abc <order_id> NX EX 86400` in Redis; a retry finds the key and returns the same order) and runs **one transaction** on the Order DB:

```sql
BEGIN;
INSERT INTO orders (id, idempotency_key, user_id, restaurant_id, status,
                    payment_mode, total, address, created_at)
VALUES ('O1', 'key-abc', 'U', 'R1', 'PLACED', 'ONLINE', 440, '...', now());
INSERT INTO order_items (order_id, menu_item_id, name, unit_price, qty)
VALUES ('O1', 'm17', 'Veg Burger', 200, 2);       -- price snapshot
INSERT INTO outbox (order_id, event) VALUES ('O1', 'order.placed');
COMMIT;
```

The unique `idempotency_key` column is the durable backstop if Redis loses the key. The Order service then asks the Payment service for a PaymentIntent keyed by `O1`, which inserts `payment(O1, PENDING, provider_intent_id)` and returns a client secret; the app confirms with the provider.

| Table | Row | After step 1 |
|---|---|---|
| `orders` | `O1` | `status = PLACED`, `total = 440` |
| `order_items` | `O1 / m17` | `qty = 2`, `unit_price = 200` (snapshot) |
| `payment` | for `O1` | `status = PENDING` |
| `outbox` | `order.placed` | relayed to Kafka (analytics only; the restaurant is **not** told yet) |

**Step 2 — customer pays (12:00:40): the webhook confirms.** The provider's signed webhook reaches the Payment service, which verifies the signature, dedupes on the event id, and sets `payment.status = SUCCEEDED`. It then tells the Order service, which does the guarded transition and the outbox write together:

```sql
BEGIN;
UPDATE orders SET status = 'PAID'
 WHERE id = 'O1' AND status = 'PLACED';           -- 1 row affected
INSERT INTO outbox (order_id, event) VALUES ('O1', 'order.paid');
COMMIT;
```

Payment and order are two services, so these are two idempotent steps rather than one transaction: if the process dies between them, the provider re-sends the webhook, and the **reconciliation job** polls for `PLACED` orders older than N minutes and settles them the same way. Zero rows affected means the order was already `PAID`, `EXPIRED` or `CANCELLED`; a payment that lands on a cancelled or expired order is **auto-refunded**.

| Table | Row | After step 2 |
|---|---|---|
| `payment` | for `O1` | `status = SUCCEEDED` |
| `orders` | `O1` | `status = PAID` |
| `outbox` | `order.paid` | relayed to Kafka, then to the restaurant |

**COD variant:** no PaymentIntent. The order is created with `payment_mode = COD` and moves straight to the `PAID`-equivalent state (subject to a per-user COD limit and a cap on the amount for new users), and the cash is recorded against the delivery when the driver hands over the food.

**Step 3 — the restaurant answers (12:01:10).** The notification service consumes `order.paid` and pushes it to the owner's app. The owner accepts with a prep time:

```sql
UPDATE orders SET status = 'ACCEPTED', prep_ready_at = now() + interval '15 minutes'
 WHERE id = 'O1' AND status = 'PAID';             -- guarded transition
INSERT INTO outbox (order_id, event) VALUES ('O1', 'order.accepted');  -- same transaction
```

`order.accepted` is what the Dispatch service waits for (next worked example). If the owner **rejects**, or does not answer within N minutes, the order goes `PAID → REJECTED` and the Payment service refunds. If the owner marks it `PREPARING` later, cancellation closes.

**Step 4 — the customer cancels instead (say at 12:03).** `POST /orders/O1/cancel` runs `UPDATE orders SET status = 'CANCELLED' WHERE id = 'O1' AND status IN ('PLACED','PAID','ACCEPTED')`. One row → cancelled: a refund is issued, and `order.cancelled` tells the restaurant to stop and tells Dispatch to drop any `delivery` row. Zero rows → the kitchen has already started (`PREPARING` or later), and the customer gets "too late to cancel," which is the rule the candidate set.

| Time | Event | `orders.status` | `payment.status` |
|---|---|---|---|
| 12:00:00 | `POST /orders` | `PLACED` | `PENDING` |
| 12:00:40 | Webhook, paid | `PAID` | `SUCCEEDED` |
| 12:01:10 | Restaurant accepts (prep 15 min) | `ACCEPTED` | `SUCCEEDED` |
| *alt* 12:03 | Customer cancels before preparing | `CANCELLED` | `REFUNDED` |
| *alt* never paid | Expiry job after N minutes | `EXPIRED` | `CANCELLED` |

### Worked example — dispatch, driver acceptance and live location

**Setup:** order `O1` is `ACCEPTED` at 12:00 with `prep_ready_at = 12:15`. The restaurant is in Bengaluru; the pickup trip takes about 6 min, so dispatch starts at **12:09**. Four drivers are online near it: `D1` (0.8 km, app open), `D2` (1.5 km, app open), `D3` (2.4 km, app in the background) and `D4` (6 km, out of the 3 km radius).

**Step 1 — drivers are visible all along (before 12:09).** Each driver app holds a WebSocket to a gateway and pings every ~5 s. The Location service handles each ping with two writes in memory: `GEOADD drivers:blr <lng> <lat> D1` and `ZADD last_seen <ts> D1`. Redis GEO has no per-member TTL, so a small sweeper removes members whose `last_seen` is older than 30 s. The gateway also registers `driver:D1 → gateway A` in the presence registry. The durable `driver_state` row holds `AVAILABLE`/`BUSY`/`OFFLINE`; the position never touches a relational database.

**Step 2 — 12:09:00 dispatch: find and offer.** On `order.accepted` (timed to the prep estimate) the Dispatch service runs:

```
GEOSEARCH drivers:blr FROMLONLAT <restaurant lng> <restaurant lat> BYRADIUS 3 km ASC COUNT 10
→ D1, D2, D3          (D4 is outside the radius)
```

It drops any driver whose `driver_state` is not `AVAILABLE`, inserts `delivery(O1, UNASSIGNED, attempts = 1)` into the Delivery DB, and **offers the order to the nearest K = 3** with a 20 s deadline: a WebSocket message to `D1` and `D2`, an FCM push to `D3`. Nothing is assigned yet; the offer lives in a Redis key with a 20 s TTL.

**Step 3 — the race: `D1` and `D2` both tap Accept within 200 ms.** Each calls `POST /deliveries/{id}/accept`, and each runs the same single transaction in the Delivery DB:

```sql
BEGIN;
UPDATE delivery SET driver_id = :d, status = 'ASSIGNED', assigned_at = now()
 WHERE id = 'DL1' AND driver_id IS NULL;                      -- must hit 1 row
UPDATE driver_state SET status = 'BUSY'
 WHERE driver_id = :d AND status = 'AVAILABLE';               -- must hit 1 row
INSERT INTO outbox (order_id, event) VALUES ('O1', 'delivery.assigned');
COMMIT;                                                        -- else ROLLBACK
```

`D1` commits first. `D2`'s first `UPDATE` waits on the row lock, then re-checks `driver_id IS NULL`, finds it set, hits **0 rows**, and the transaction rolls back: `D2` gets `409 already taken` and the app dismisses the offer, and the offer to `D3` is withdrawn. The second `UPDATE` matters too: if `D1` had just accepted a different delivery, its `AVAILABLE → BUSY` would hit 0 rows and roll back the claim, leaving `DL1` unassigned instead of bound to a busy driver. That is why the two writes share a transaction.

| Table | Row | After step 3 |
|---|---|---|
| `delivery` | `DL1` | `driver_id = D1`, `status = ASSIGNED` |
| `driver_state` | `D1` | `status = BUSY` |
| `driver_state` | `D2`, `D3` | still `AVAILABLE` |
| `outbox` | `delivery.assigned` | relayed to Kafka; the customer is told "Ravi is picking up your order" |

**No one accepts within 20 s?** The Dispatch service increments `attempts`, widens the radius (3 → 5 km), raises K and re-offers; after N rounds it raises an alert and lets the customer cancel with a refund.

**Step 4 — live location while `D1` drives (12:09 → delivery).** Every ~5 s the same ping path runs, and for a driver on an active delivery the Location service does three more things:

1. Look up the active delivery (`driver:D1:delivery → O1`) and the buyer's gateway in the presence registry (`user:U → gateway B`).
2. **Throttle**: `SET track:O1 1 NX EX 3`. Only the ping that wins the key is forwarded, so the buyer gets about one update per 3–5 s, not one per ping.
3. Push `delivery.update {lat, lng, eta}` to gateway B, which writes it down the buyer's WebSocket. The ETA comes from the ETA service, which recomputes from the routing API when the driver deviates or every ~30 s, not on every ping.

A sampled copy of the pings (about one in six) goes to the Kafka location trail and then to AWS S3, for ETA training and disputes. If the buyer opens the app mid-trip, it connects to a gateway, registers presence, and is immediately sent the driver's last known position from Redis, so the map is not blank until the next ping.

**Step 5 — pickup and drop-off.** At the restaurant, `D1` taps pickup once inside a ~100 m geofence and the order is `READY`: `UPDATE delivery SET status = 'PICKED_UP' WHERE id = 'DL1' AND driver_id = 'D1' AND status = 'ASSIGNED'`, and the Order service follows with the guarded `READY → PICKED_UP`. On drop-off the delivery goes to `DELIVERED`, `D1` goes `BUSY → AVAILABLE` in the **same transaction**, the active-delivery mapping is removed, and for COD the collected cash is recorded. Early arrival just waits for `READY`.

**Step 6 — the failures this design closes.**

- **`D1`'s phone loses signal at 12:12, before pickup.** Pings stop; `last_seen` goes stale past 30 s. If the food has not been picked up, the delivery returns to `UNASSIGNED` (`driver_id = NULL`, `D1` marked `OFFLINE`) and re-dispatches ahead of newer orders; if it has, Dispatch alerts support instead of silently reassigning. A signal blip under 30 s changes nothing.
- **Gateway A crashes.** The driver apps reconnect with backoff to another gateway and the presence entries are overwritten; pings resume, and nobody is reassigned unless the gap exceeds 30 s.
- **Redis geo shard restarts.** Positions are empty for a few seconds until the next pings repopulate them; assignments are unaffected, because they live in the Delivery DB.

| Time | Event | `delivery` | `driver_state` (`D1`) | Redis |
|---|---|---|---|---|
| 12:08 | Online, waiting | — | `AVAILABLE` | `drivers:blr` has `D1` |
| 12:09:00 | Dispatch offers to `D1`, `D2`, `D3` | `UNASSIGNED` | `AVAILABLE` | offer key, TTL 20 s |
| 12:09:08 | `D1` wins the claim | `ASSIGNED`, `driver_id = D1` | `BUSY` | `driver:D1:delivery = O1` |
| 12:09–12:14 | Pings every 5 s | `ASSIGNED` | `BUSY` | `GEOADD`, buyer push every 3–5 s |
| 12:15 | Pickup (food `READY`) | `PICKED_UP` | `BUSY` | — |
| 12:30 | Delivered | `DELIVERED` | `AVAILABLE` | mapping removed |
| *alt* 12:12 | `D1` goes silent > 30 s before pickup | `UNASSIGNED`, re-dispatch | `OFFLINE` | sweeper removes `D1` |

### Database schema

| Table | Fields | Note |
|---|---|---|
| `orders` | `id` (PK), `idempotency_key` (unique), `user_id`, `restaurant_id`, `status` (`PLACED → PAID → ACCEPTED → PREPARING → READY → PICKED_UP → DELIVERED`; branches `REJECTED`, `CANCELLED`, `EXPIRED`), `payment_mode` (`ONLINE`/`COD`), `total`, `address`, `prep_ready_at`, `created_at` | **Crux table #1.** Every transition is a guarded `UPDATE … WHERE status = :expected`; index on `(status, created_at)` for the expiry job |
| `order_items` | `order_id`, `menu_item_id`, `name`, `unit_price`, `qty` | **Price snapshot** at order time so a later menu edit never changes a placed order |
| `outbox` | `id`, `order_id`, `event`, `published_at` | Written in the order transaction; a relay publishes to Kafka |
| `payment` | `id`, `order_id`, `provider_intent_id`, `status`, `provider_event_ids` | Webhook dedupe key; `PENDING → SUCCEEDED/FAILED/REFUNDED` |
| `delivery` | `id`, `order_id` (unique), `driver_id` (nullable), `status` (`UNASSIGNED → ASSIGNED → PICKED_UP → DELIVERED`), `assigned_at`, `attempts` | **Crux table #2.** `driver_id IS NULL` is the guard in the claim; lives in the same DB as `driver_state` |
| `driver_state` | `driver_id` (PK), `status` (`OFFLINE`/`AVAILABLE`/`BUSY`), `city`, `updated_at` | Durable availability; same transaction as the claim. Live position is in Redis, not here |
| `driver` | `id`, `name`, `phone`, `vehicle`, `city` | Static profile |
| `restaurant` | `id`, `owner_id`, `name`, `geo`, `city`, `status`, `accepting_orders`, `hours` | Source of truth for search via CDC; `accepting_orders` is the pause switch |
| `menu_item` | `id`, `restaurant_id`, `name`, `price`, `available`, `image_key` | Photos referenced by AWS S3 key |
| `user` | `id`, `name`, `email`, `role` (`CUSTOMER`/`OWNER`/`DRIVER`/`ADMIN`) | One table, role column |

**Key API**: `POST /orders` (Idempotency-Key) · `POST /orders/{id}/cancel` · `PUT /orders/{id}/status` (restaurant: accept/reject/ready) · `POST /deliveries/{id}/accept` · `POST /deliveries/{id}/pickup` · WebSocket `location {lat, lng, ts}` (driver → server) and `delivery.update {lat, lng, eta}` (server → buyer) · `POST /restaurants`, `PUT /restaurants/{id}/menu`.

### Storage choices — which engine for which store

| Store | Category | Why this category, not another |
|---|---|---|
| `orders`, `order_items`, `outbox`, `payment` | **Relational** (PostgreSQL / MySQL) | Multi-row ACID (order + items + outbox), guarded status transitions, a unique idempotency key; ~0.7 TB/yr fits one primary |
| `delivery`, `driver_state` | **Relational**, a separate Delivery DB | The claim is a conditional write across two rows and must be one local transaction; volume is tiny |
| `restaurant`, `menu_item`, `user`, `driver` | **Relational** | Small structured admin-written rows, key lookups, CDC to the index |
| Driver location (live) | **In-memory geo index** (Redis GEO per city) with `last_seen` TTL | ~20K writes/s, ephemeral, needs radius queries; rebuilt from the next ping after a loss, so no durability needed |
| Search index | **Search index** (AWS Elasticsearch) | Dish, restaurant and rating text queries with geo filters; a relational `LIKE` can't do it |
| Restaurant cache, idempotency store, presence registry | **In-memory KV with TTL** (Redis) | Hot lookups with a durable fallback (replica, primary, order row); presence entries die with the connection |
| Photos, location trail | **Object storage** (AWS S3) + CDN for photos | Large read-mostly blobs; the trail is a cold, sampled archive |
| Order, delivery and CDC events | **Log-based broker** (Kafka) | Replayable fan-out to notification, dispatch, order service, search indexing; consumer lag is a monitored signal |

### Design trade-offs

- **Offer to K, claim with one conditional write** over locking a driver for an order → no lock to leak, no coordination between offers; the loser gets an instant "taken." Switch to a sequential offer (one driver at a time) if drivers dislike racing, at the cost of slower assignment.
- **Redis GEO per city for live location over a database** → 20K writes/s is memory work; losing it costs seconds until the next ping. Alternative: a geohash or H3 cell key per driver; same idea, more control over cell size.
- **City as the partition for dispatch and location, not for orders** → matching never crosses a city, so geo shards are independent; orders at ~20/s don't need sharding, and city sharding there would only add cross-shard queries.
- **Delivery and driver availability in one database** → the claim is one local transaction instead of a saga across two services; costs independent scaling of the two, irrelevant at ~46 claims/s peak.
- **Outbox + Kafka over a dual write** → an order and its event commit together or not at all; costs a small relay delay.
- **Webhook plus polling reconciliation** (kept from the room) → the polling job is the lost-webhook backstop, not a second source of truth.
- **WebSocket for drivers' pings and buyers' updates, throttled** → one channel and a presence registry for routing; SSE is a valid simpler choice for the buyer since the stream is one-way. Dispatch offers fall back to APNs/FCM when the driver is offline.
- **CP orders and assignment, AP browse and location** → orders and claims go to the primary; menu and search use replicas, caches and Elasticsearch with seconds of staleness; the order step reads live data.
- **Time the dispatch to prep time** over dispatching immediately → drivers wait less at the restaurant; costs a dependency on an accurate prep estimate, so cap early dispatch and let the restaurant mark ready.
- **Auto-expire and auto-refund over leaving states open** → every wait (payment, restaurant accept, driver accept) has a deadline; simpler to reason about, costs an occasional spurious cancel.

### Logging, Monitoring & Alerts

| Signal | Alert threshold | Why it matters |
|---|---|---|
| **Time from `ACCEPTED` to driver assigned**, p95 | > ~3–5 min | Dispatch is failing or the area is short of drivers |
| **Unassigned deliveries** (count and oldest age) | Oldest age > N min, or growing | Food is going cold with no driver |
| **Offer acceptance rate** per city | Sharp drop vs. baseline | Offers going unseen (push failure) or pay too low |
| **Double-claim attempts / conditional-update failures** | Spike over baseline | A hot order being raced by many drivers, or a bug retrying accepts |
| **Location staleness** (share of `BUSY` drivers with `last_seen` > 30 s) | > a few percent | Location pipeline or WebSocket tier degraded; false re-dispatches follow |
| **WebSocket connections per gateway** and reconnect rate | Near the per-node limit; reconnect storm | Capacity, or a gateway failing over |
| **Location write rate / Redis memory and ops** | Approaching node limits | Geo index needs another shard |
| **Pending-payment age** and webhook failure ratio | Any `PLACED` order older than N min unresolved | Webhooks lost or provider unreachable |
| **Order-event consumer lag** (notification, dispatch) | > ~30 s | Restaurants not seeing orders; dispatch late |
| **Restaurant response time** (`PAID` → accept/reject) | > N min | Kitchen not seeing orders; triggers auto-reject |
| **Replica lag** (restaurant and order replicas) | > ~1–2 s | Stale menus or status screens |
| **Image pipeline DLQ depth** | > 0 and growing | Menu uploads silently failing |

## Takeaways to drill

1. **Name the crux early: dispatch.** Offers are many, the claim is one — a conditional `UPDATE … WHERE driver_id IS NULL`, in the same transaction as the driver's `AVAILABLE → BUSY`.
2. **Size the hottest write path, not the aggregate.** 100K drivers pinging every 5 s is ~20K writes/s, about 400× the order rate: it decides the store (Redis GEO), the transport and the connection tier.
3. **"Who is nearby?" needs a spatial index.** A per-driver key lookup can't answer it; use a geo structure per city with a `last_seen` TTL.
4. **Make the estimate decide.** ~20 orders/s and ~0.7 TB/yr say "no order sharding"; city is the partition for dispatch and location, where matching is local.
5. **An order is a guarded state machine with a deadline on every wait.** Payment, restaurant accept, driver accept, pickup — each with a timeout and a stated terminal case.
6. **Raise the failure modes yourself.** Driver drops, nobody accepts, restaurant rejects, late payment on a cancelled order — one sentence each, before being asked.
7. **Idempotency on every money-adjacent call** — order `POST`, payment intent, webhook — now a repeat across S15, S19 and S20.
8. **Keep atomic things in one database** (delivery with driver availability; order with its outbox row) and use events for the rest.
9. **Produce the API and schema on your own agenda.** Five endpoints and the table list take two minutes (skipped in S18 and again here).
10. **Say each point once.** One sentence, one reason, details on request.

> → Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
