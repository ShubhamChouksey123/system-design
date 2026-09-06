# Session 11 — High-Frequency Stock Trading System · ✅ 7.5/10

> A scored, analyzed system-design mock — and **the second proof that the re-solve method works.** [S10](../10-session/README.md) was the *first* encounter with this brand-new hard problem and it fell to **⚠️ 5.5** — the matching engine, the heart of the system, was modeled as a database-backed worker and never actually built. S11 is the **same prompt, re-solved after drilling that exact crux**, and it lands the log's second clean **Pass (✅ 7.5, Hire)** — a **+2.0 jump**, the same shape as the [S08 → S09](../09-session/README.md) breakthrough. This time the engine *was* designed: an **in-memory order book per stock**, a **single writer per stock** reached and stated up front, a **Sequencer → append-only order log → cursor-based matching engine** event-sourcing spine, a **warm standby with its own cursor**, and **two ring buffers** handing trades and prices off the hot path fire-and-forget. The candidate reproduced the S10 ideal design almost box-for-box, *on their own*, and defended the two hardest calls cold: **why you never split one stock across engines** (it breaks price-time priority) and **why the fast path touches no disk and no network** (log reads + ring-buffer writes = microseconds). The gaps that remain are now the *senior-plus* layer — a real exchange's **price-level-aggregated** book, the **order-cancellation / expiry** interaction with reserved funds, **market-data fairness**, **monitoring**, and a verbal delivery that still **rambles**. This is the clearest single-session improvement in the log, and it confirms the pattern: **re-solve a sub-7 problem after drilling its crux, and the named-but-unbuilt component becomes a built one.**

| | |
|---|---|
| **Problem** | Design a high-frequency stock trading system — millions of trades/sec, ultra-low latency, strong consistency *(identical to [S10](../10-session/README.md))* |
| **Focus** | The order matching engine — this time **built**, not just named — plus the price fan-out and after-trade paths |
| **Overall** | **7.5 / 10** — ✅ **Hire** — up **2.0** from S10's 5.5, on the *same* problem after a targeted re-solve |
| **Strongest areas** | High-Level Design (8.5), Problem-Solving (8.0) — the two axes that sank S10 (5.0 each) are now the *top* scores |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |
| **Ideal design** | Not repeated here — the fully worked reference lives in **[S10 → The ideal design](../10-session/README.md#the-ideal-design)** |

## The problem

> Design a **high-frequency stock trading system** that can process **millions of trades per second** with **ultra-low latency** and ensure **data consistency**.

Same prompt as S10. The full breakdown of *why* the order matching engine is the crux — in-memory order book, price-time priority, log-then-match durability, and a completely separate price-read problem — is in the [S10 write-up](../10-session/README.md#the-problem). This page is about **what changed in the room the second time**.

## Requirements & estimation

The functional cut was solid and product-shaped, and — unlike S10 — the estimation **fed decisions** and the **schema was drawn upfront**.

- **Functional** — see a **stock list + profile** (name, description, company, yearly profit); see the **live stock value**; place a **limit or market order**; **payment on placing an order**; the system returns **best value sorted by price-time**; view **portfolio + current values**.
- **Non-functional** — **fast order matching + settlement**, **writes consistent + durable**, **fault tolerant**, **reads fast**. The write-consistency / read-speed split — the one good instinct from S10 — was stated again cleanly.
- **Estimation that decided things** — 5M users, 2.5M DAU (50%), **1M trades/sec** (given), **5,000 stocks**, **~10K orders waiting per stock × ~100 B ≈ 1 MB/stock**, **~5 MB/stock at peak** (orders queue up before market open), read:write **100:1**. The order-book memory figure is the one that matters: it proves the book **fits in memory per stock**, so it is *not* a database table — exactly the reasoning S10 never reached.

![Requirements canvas for a high-frequency stock trading system. The problem is to design a system that can process millions of trades per second with ultra-low latency and ensure data consistency. Functional requirements list seeing a stock list and each stock profile with name description company and year-wise profit, seeing live stock value, placing a limit order or a market order, payment required on placing an order, the system providing best value sorted by price then time, and viewing stocks in the portfolio with current values. Non-functional requirements list fast trade order matching and settlement, writes should be consistent and durable, the system should be fault tolerant, and reads should be fast. The estimations block assumes 5 million total users, 2.5 million daily active users, 1 million trade executions per second, 5000 total stocks listed, 10 thousand orders waiting for a match per stock, 100 bytes per waiting order giving a space requirement of about 1 megabyte per stock, a peak of about 5 megabytes per stock because orders line up before market open, and a read to write ratio of 100 to 1. The schema block lists a Stock Profile table with id name description company and valuation, an Order table with user_id order_id seq buy or sell price and quantity, a Portfolio table with id user_id stock_id quantity and created_at, and a Wallet table with user_id available balance and current balance.](./diagrams/requirements.png)

> **What improved over S10:** S10's numbers *contradicted* each other (1000 vs 100 req/instance) and drove no decision. Here the per-stock order-book footprint is derived and **used** — it's the number that says "keep the book in RAM, one owner per stock." The schema was also drawn *during* requirements rather than at the buzzer, and it named the four crux tables — `Stock Profile`, `Order` (with `seq`), `Portfolio`, `Wallet` (`available` + `current` balance).

## The design produced — the crux, built this time

This is the headline change. In S10 the "matching engine" was a **Trade Settlement Worker reading DB-backed sorted lists**. In S11 the candidate drew the real thing, and walked it end-to-end.

![Architecture canvas produced in the interview. A client sends POST buy, GET portfolio by user id, and GET stock by id to an API Gateway doing authentication authorization and rate limiting. Order writes go to an Order Service which validates the request, reserves funds, and routes requests using consistent hashing on stock id to a Sequencer that adds an auto-incrementing integer stamp. The Sequencer appends to Order Logs which are append-only. Both a Matching Engine and a Standby Engine read the Order Logs through their own cursor-based log readers. The Matching Engine keeps in-memory lists of buy and sell orders per stock sorted by price and timestamp, matches the buy with the best sell order, and writes matched trades into ring buffers as fire-and-forget events. The Standby Engine is a second engine for fault tolerance that reads the same logs but does not write. The Matching Engine writes a fire-and-forget event into a Trade ring buffer held in a memory map, which a Trade Provider reads and writes into a Trade event Kafka queue. Three consumers read the Kafka queue: a Settlement Service that settles to the sender and writes to a Wallet Datastore, a Portfolio Update Service that updates the portfolio of buyer and seller and writes to a Portfolio Datastore Writer, and Trade Logs. The Matching Engine also writes a fire-and-forget event into a Price ring buffer held in a memory map, which a Price Provider reads and sends via multicast UDP to Price WebSocket connections and SSE and to a Price Cache. A Portfolio Service reads from a Portfolio Cache in Redis backed by a Portfolio Datastore Reader instance that replicates from the Portfolio Datastore Writer, and the latest price of a stock is pushed to the client via websockets. A Stock Profile Service reads from a Stock Profile Cache in Redis backed by a Stock Profile Datastore Reader instance replicating from a Stock Profile Datastore Writer.](./diagrams/architecture.png)

**The write / match path (the part S10 missed entirely):**

- **API Gateway** — authN, authZ, rate limiting. Standard.
- **Order Service** — validates the order, **reserves funds from the wallet** (for a limit order, `price × qty` moves `available → reserved`) *before* the order can trade, and **routes by `stock_id` using consistent hashing** so every order for one stock reaches the same Sequencer + engine. The wallet-reserve — which S10 only reached under pressure — was stated **proactively** this time.
- **Sequencer** — stamps each order with an **auto-incrementing integer**, guaranteeing every engine copy processes orders in the identical order. Correctly defended as **not a bottleneck** — it does one trivial op — and, when pushed on a celebrity stock, correctly reached "give that stock its own Sequencer + engine, but never split *one* stock."
- **Order Logs (append-only)** — the Sequencer **writes the log before any matching happens**. This is the durability trick: the durable record exists first, so a crash loses nothing — replay rebuilds the book.
- **Matching Engine (the core)** — reads the log **by its own cursor**, keeps the **buy/sell book in memory per stock** sorted by price then timestamp, matches the incoming order against the **best opposing order** (price-time priority), and writes results **fire-and-forget into ring buffers** before reading the next log entry, in a tight loop. **One engine owns one stock's `stock_id`** — the partitioning that both bounds memory (5 MB × 5,000 stocks won't fit one node) *and* serializes matching so nothing clashes.
- **Standby Engine** — a replica that **reads the same logs by its own cursor** but writes nothing; on primary failure it takes over having already replayed identical state. The candidate correctly noted each engine keeps an **independent cursor** and accepted the **one-standby-per-engine infrastructure cost** as a deliberate consistency/durability trade-off.

**The two ring buffers (hand-off off the hot path):**

- **Price ring buffer → Price Provider → multicast UDP → WebSocket/SSE + Price Cache** — one publish reaches every subscriber *at the same instant* (the multicast fairness argument the candidate made), with a **price cache as the fallback** for dropped UDP packets — clients can read the latest price from cache instead of waiting for a re-push.
- **Trade ring buffer → Trade Provider → Kafka** — a **separate** buffer feeds Kafka, whose three consumers each do one job: **Settlement Service** (pays the seller, writes the wallet), **Portfolio Update Service** (updates buyer + seller holdings), **Trade Logs** (append-only audit record).

**Read paths** — Portfolio and Stock Profile each have their own service reading from a **Redis cache backed by a read replica** (writer → reader replication), keeping slow-changing data off the write path. Portfolio value = `qty × cached price`.

**The matching-engine data structure** — two **sorted linked lists** per stock (bids high-to-low, asks low-to-high), plus a **`price → node` map** and an **`order_id → node` map** to get O(1) insertion near a known price and O(1) order update — the candidate reached the hash-map index unprompted when challenged on linked-list insertion cost.

**Market vs limit orders** — correctly handled in the schema: `price` is **null for a market order** (the engine fills at the best available price at execution time).

## Scorecard

| Axis | S10 | **S11** | Δ |
|---|:--:|:--:|:--:|
| Requirements Gathering | 6.0 | **7.5** | ▲ 1.5 |
| Design Skills | 7.0 | **8.5** | ▲ 1.5 |
| Problem-Solving | 5.0 | **8.0** | ▲ 3.0 |
| Scalability & Trade-offs | 5.0 | **7.5** | ▲ 2.5 |
| Communication | 6.0 | **7.0** | ▲ 1.0 |
| **Overall** | 5.5 | **7.5** | ▲ 2.0 |

> **The two axes that sank S10 became the two highest scores.** Problem-Solving (▲3.0) and Scale & Trade-offs (▲2.5) — exactly where the matching engine, hot-stock question, and read fan-out all live — flipped because the crux was *built and defended*, not named and abandoned. Design led at 8.5 because the whole event-sourced spine (Sequencer → log → cursor engine → standby → ring buffers) was drawn correctly and walked coherently. Communication rose only 1.0 and is now the **lowest** axis — the one clear thing still holding back a Strong Hire.

## What went well — the re-solve landed

Nearly every gap that capped S10 was closed *unprompted* this time. These are now **confirmed strengths**:

- **The matching engine was designed as the core** — in-memory order book per stock, price-time priority, matched in a tight loop with no disk and no network on the fast path. This *is* the system, and this time it was built.
- **Single writer per stock, stated up front** — "all orders for one stock go to one matching engine" via consistent hashing on `stock_id`, and the correct refusal to split one stock ("we couldn't guarantee best price-time priority"). The concurrency guard the tracker has chased since S01 was reached as *the design*, not under interrogation.
- **Event sourcing done right** — Sequencer stamps + appends to the log **before** matching; the engine and standby each replay by their own cursor; recovery is a replay. The candidate explained *why* the standby stays in lockstep (same logs, own cursor).
- **Ring-buffer hand-off** — two separate buffers, trade vs price, written fire-and-forget so the slow Kafka path can never gate the microsecond price path.
- **Wallet-reserve on the fast path, settlement async** — reserve funds at order entry (fast local check), settle later via Kafka — proactively, not under challenge as in S10.
- **Latency discipline verbalized** — when asked how to make a hot stock fast, the candidate named the principle directly: **no disk I/O, no network calls; read append-only logs, write ring buffers → microseconds.**
- **Multicast fairness reasoning** — chose multicast UDP so every subscriber is notified simultaneously (vs a loop where early clients win), and named the **cache fallback** for UDP's unreliability when the interviewer pushed on dropped packets.
- **Estimation that decided something + a schema drawn early** — the per-stock order-book memory figure justified keeping the book in RAM; the schema named `Order.seq`, wallet `available`/`current`, and null price for market orders.

## What still lost points — the senior-plus layer

The remaining gaps are no longer about the crux — they're the depth that separates a **Hire from a Strong Hire**:

| What was thin in the room | What a senior-plus answer adds | Study |
|---|---|---|
| **Order book = sorted linked list + hashmap** — works, but not how real exchanges do it | Use a **price-level-aggregated** book: a tree/skip-list of **price levels**, each level a **FIFO queue** of orders, plus an `order_id → node` index. Be ready with **time complexity for insert / cancel / match / modify** and know when a skip list vs red-black tree fits. | [S10 §4 order-book structures](../10-session/README.md#4-the-crux--the-order-matching-engine) |
| **Order cancellation, partial fills & expiry never covered** — and how they interact with reserved funds | Cancels flow through the **same Sequencer → log → engine path** (no race with a match); on cancel/partial-fill/expiry the engine emits a **fund-release event** so the wallet un-reserves the unfilled quantity. Every reserve nets to *spent* or *released*. | [S10 reservation lifecycle](../10-session/README.md#the-ideal-design) |
| **Market-data fairness left at "multicast is simultaneous"** | Real exchanges go further — **equal-length cabling**, a single multicast fan-out point, and **gap-fill via TCP unicast** (request missing sequence numbers) rather than full-snapshot re-download, so no subscriber is structurally advantaged. | [Low-Latency Messaging](../../concepts/07-messaging-and-events/low-latency-messaging.md) |
| **Monitoring & observability not raised** | For a system this critical, name it proactively: match-latency percentiles (p50/p99), order-log lag, ring-buffer depth, cursor skew between primary and standby, dropped-packet counters on the feed. | [Non-Functional Requirements](../../concepts/02-foundations/non-functional-requirements.md) |
| **Communication rambled and repeated** — the lowest axis, flagged explicitly | Run **State → Explain → Justify**, then stop: state the decision, explain the mechanism, justify the choice — one pass, no repeats. Practice explaining any single flow in **under 90 seconds**. | [Answer Framework](../answer-framework.md) |

The interviewer also nudged toward **proactive failure reasoning** — volunteer "what if Kafka is down / the wallet is slow / the Sequencer crashes between two writes" before being asked. The fully worked answers to all of these — failover correctness (`exec_id = f(seq)` + fencing), gap-fill, the reservation lifecycle — are in the **[S10 ideal design](../10-session/README.md#5-resilience--failover)**, which this session's design now closely matches.

## Takeaways to drill

1. **The re-solve method works — twice now.** S08 → S09 flipped Borderline → Pass; S10 → S11 flipped Lean-No-Hire → **Hire (+2.0)** on the same problem. The mechanism is identical: **drill the exact named-but-unbuilt crux, then re-solve.** The matching engine went from a DB-backed worker to a real in-memory single-writer state machine, and the two axes it lived on became the top scores.
2. **Bank the crux as a permanent strength.** For a trading problem the core is now reliable: **in-memory order book per stock · price-time priority · one writer per stock (consistent hashing on `stock_id`) · Sequencer → append-only log → cursor engine → warm standby · two ring buffers off the hot path.** This is the S10 ideal design, reproduced under interview pressure.
3. **The next tier is the *senior-plus* layer, not the fundamentals.** Price-level-aggregated books with FIFO queues, the **cancellation / expiry ↔ reserved-funds** lifecycle, **market-data fairness + gap-fill**, and **observability** are the depth that turns Hire into Strong Hire.
4. **Communication is now the ceiling — structure beats volume.** The design knowledge is there; the delivery rambles. **State → Explain → Justify, say each point once, any flow in under 90 seconds.** It's the lowest axis (7.0) and the cheapest 1–2 points left on the table.
5. **Volunteer trade-offs and failure modes before being asked.** The wallet-reserve and multicast fairness came out well, but cancellation, monitoring, and Kafka-down were left for the interviewer to raise. Proactivity is the Pass → Strong-Pass lever the tracker keeps flagging.

→ Consolidated feedback across all sessions lives in the [practice tracker](../README.md). The fully worked reference architecture for this problem is **[S10 → The ideal design](../10-session/README.md#the-ideal-design)**. Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
