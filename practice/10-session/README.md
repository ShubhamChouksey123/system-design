# Session 10 — High-Frequency Stock Trading System · ⚠️ 5.5/10

> A scored, analyzed system-design mock — and a **step backward that actually proves the tracker's main point** rather than breaking it. [S09](../09-session/README.md) was a breakthrough **Pass (✅ 7.5)**, but that was a problem I'd already solved once. S10 is a **brand-new, hard problem**, and the score fell to **⚠️ 5.5** — the lowest since [S04](../04-session/README.md). This is the same story as S04: do well on a familiar problem, then hit a fresh one with a hard core and run into the same wall — **I can name the key idea but can't fully build it.** The good news: several answers were genuinely senior. I reached **one writer per stock** (the trick that prevents two matches clashing) on my own, I moved payment **off the fast path** by using a wallet when pushed, I handled a **failed seller payout** cleanly with Kafka retries and a fallback, and I split **consistency for writes vs. speed for reads** up front. The bad news: I never actually designed the **order matching engine** — the heart of any trading system. I treated it as a background worker reading sorted lists from a database. I stalled on the "hot stock" problem, left an external payment sitting in the fast path until challenged, never addressed how **100M price reads/sec** reach users, and my estimates contradicted each other and led to no decision. The supporting parts held up; the core did not.

| | |
|---|---|
| **Problem** | Design a high-frequency stock trading system — millions of trades/sec, very low latency, strong consistency |
| **Focus** | The order matching engine (speed + no clashing) plus pushing live prices to huge numbers of readers |
| **Overall** | **5.5 / 10** — ⚠️ Borderline *(the platform's words: "Lean No Hire")* — down 2.0 from S09's 7.5, on a new problem |
| **Weakest areas** | Problem-Solving (5.0), Scale & Trade-offs (5.0) — exactly where the hard core lives |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |

## The problem

> Design a **high-frequency stock trading system** that can process **millions of trades per second** with **very low latency** and keep its **data consistent**.

This looks like a simple "buy and sell" app, but the hard part is the **order matching engine**. For each stock, the system keeps an **order book** — the list of unmatched buy and sell orders — **in memory**, and matches new orders against it in microseconds without touching a disk or waiting on the network. Two questions decide the whole design:

1. **How do you match orders quickly and without clashing?** Answer: one dedicated worker per stock, working through orders one at a time on an in-memory book. To make this safe against crashes, first write every incoming order to a durable, replicated log; if a machine dies, replay the log to rebuild the exact same state.
2. **How do millions of people see live prices?** Answer: when trades happen, **push** those price updates out through a fan-out layer to everyone watching — don't make them repeatedly ask a database.

In the interview I didn't get to either of these directly, and that's what held the score down.

## Terminology

The domain words this write-up uses. Saying them out loud in the interview signals you know the space.

| Term | Meaning |
|---|---|
| **Symbol** | One tradable stock, named by its ticker (e.g. `AAPL`, `GOOGL`). "Per symbol" just means "per stock"; an exchange lists about 5,000 of them. Used interchangeably with *stock* / `stock_id` here. |
| **Order** | A request to buy or sell some quantity of a stock. Comes in two kinds (below). |
| **Market order** | Buy or sell **right now at the best available price** — you care about speed, not the exact price. |
| **Limit order** | Buy or sell **only at your chosen price or better** — you care about price, so it waits on the book until someone matches it. |
| **Order book** | The list of waiting buy and sell orders for one stock, kept **in memory** and sorted by price then time. **Bids** = buyers, **asks** = sellers. |
| **Price-time priority** | The matching rule: best price wins; if two orders have the same price, the one that arrived **first** wins. |
| **Resting order** | An order sitting on the book, waiting to be matched (versus a new order being matched right now). |
| **Matching / execution** | Pairing a new order with a waiting order on the other side. A completed pair is an **execution** (a trade). |
| **Matching engine** | The part that holds the books and runs the matching — **the heart of the system**. |
| **Settlement / clearing** | The **after-the-trade** step that actually moves the money and shares between the two people. Happens later, separate from matching. |

## Requirements & estimation

- **Functional (what it does)** — **view a stock's profile** (current and past price, daily/monthly/yearly change, company info, financials); **place a trade** as a **market** or **limit** order; **view your portfolio** (what you own, its current value, past orders). A reasonable list, but I never named **live price feeds** or the **matching engine** as requirements — and those are the core.
- **Non-functional (qualities)** — **scalable, consistent, reliable, fault-tolerant, resilient, highly available**. I listed these but didn't reason about them deeply, and I never put a number on the **latency target**, which is the whole point of the problem.
- **One good call** — I said up front: **writes need consistency, reads need speed and availability.** That's correct.
- **Estimation (the weak spot)** — 1M users, 500K daily active, a 1:100 write-to-read ratio, **1M trades/sec** (given), 5,000 stocks, **100M reads/sec**. But then I said each instance handles "1000 req/sec" and did the math with "100 req/sec," landing on "100K instances" — a guess. The numbers **contradicted each other and led to no real decision.** Worst of all, I never did the sizing that matters: **1M ÷ 5,000 ≈ 200 trades/sec per stock** — though that's only the *average*, and the real hot-stock answer is the engine's single-thread throughput, not average volume (see §1). Either way I never engaged the question.

![Requirements canvas for a high-frequency stock trading system. The problem is to design a system that can process millions of trades per second with ultra-low latency and ensure data consistency. Functional requirements list viewing a list of stocks where each stock has a current value, previous value, daily monthly and yearly change, company name and description, annual and quarterly profits, and quarterly turnover forming a stock profile; sending a trade as either a market order or a limit order where a limit order settles at a user-specified price and a market order settles at the current market price; and viewing the user portfolio with current value of holdings and previous orders. Non-functional requirements list scalable, consistent, reliable, fault tolerant, resilient, and highly available, with a note that writes should be consistent while reads should be highly available and low latency. The estimation block assumes 1 million total users, 500 thousand daily active users at 50 percent, a write to read ratio of 1 to 100, a stated write throughput of 1 million trades per second, 5000 total stocks in the exchange, a read throughput of 100 million per second, a per-instance capacity of around 100 to 1000 requests per second, and a resulting estimate of about 100 thousand instances.](./diagrams/requirements.png)

## The design I produced

![Architecture canvas for the stock trading system as produced in the interview. A client connects to an API Gateway containing a load balancer, authentication and authorization, and rate limiting. Reads go to a Read Stock Profile Service backed by a stock profile datastore with a read replica and cache. Trades go to a Trade Service which writes to a User Orders datastore and, for sell orders, to a Sell Orders datastore, and for buy orders to a Buy Orders datastore after a payment step. A Payment Service calls an external payment provider like PayPal using a payment id and webhook URL, and a Notification Service pushes payment status to the client over SSE. A Trade Settlement Worker reads sorted lists of buy and sell orders per stock and matches them by price, partitioned so that a single worker handles a given stock via consistent hashing on stock id, then writes the updated price to a Stock Price datastore with a read replica and cache and emits a trade settlement event to a Kafka message queue. Two consumers read the event: a Seller Payout Service that pays the seller via the Payment Service with retry and dead letter queue and wallet-credit fallback, and a User Portfolio Write Service that updates a User Portfolio datastore. A User Portfolio Read Service reads holdings and multiplies units by the cached stock price to show current value.](./diagrams/architecture.png)

- **API Gateway** — load balancer, login, rate limiting. Standard and correct.
- **Read Stock Profile Service** — company data that rarely changes, served from a **read replica + cache**. Good call; profiles don't change every second.
- **Trade Service (stateless)** — writes orders into **User Orders**, **Sell Orders**, and **Buy Orders** stores. Can scale out horizontally — a fair point.
- **Trade Settlement Worker (the core, done wrong)** — reads **sorted lists from a database** and matches buy/sell by price. I did partition it so **one worker owns one stock** (via consistent hashing on `stock_id`), which stops two workers fighting over the same order — a good instinct, reached on my own. But this is a **batch job over a database**, not a fast **in-memory order book**. That's the classic miss.
- **Payment Service + external provider** — at first I put an external payment (like PayPal) **in the buy path**, before the order could trade. I later fixed this to a **wallet** (reserve/deduct a balance, top it up separately) when challenged.
- **Kafka after settlement** — a **Seller Payout Service** (with retry, dead-letter queue, and wallet-credit fallback) and a **User Portfolio Write Service** react to settled trades. The failure handling here was genuinely good.
- **Stock Price store + Portfolio read** — the worker writes the latest price; portfolio value = `shares owned × cached price`. But I never addressed **how 100M readers actually get live prices** (push vs. pull).

## Scorecard

| Axis | S09 | **S10** | Δ |
|---|:--:|:--:|:--:|
| Requirements Gathering | 8.0 | **6.0** | ▼ 2.0 |
| Design Skills | 8.0 | **7.0** | ▼ 1.0 |
| Problem-Solving | 7.5 | **5.0** | ▼ 2.5 |
| Scalability & Trade-offs | 7.0 | **5.0** | ▼ 2.0 |
| Communication | 8.0 | **6.0** | ▼ 2.0 |
| **Overall** | 7.5 | **5.5** | ▼ 2.0 |

> **Design held up best (7.0) — laying out services is now a habit.** What fell were the two axes tied to the hard core: Problem-Solving (▼2.5) and Scale & Trade-offs (▼2.0), which is exactly where the matching engine, the hot-stock question, and the huge read load all sit. This isn't lost skill — it's the tracker's recurring pattern: drilled habits carry the easy scaffolding of *any* problem to a decent baseline, but the **first time you meet a hard core**, the old ceiling shows up again. The fix is the one S09 proved works: **drill that exact core, then re-solve the problem.**

## What lost points — and the fix

| What I missed in the room | What a senior would say | Study |
|---|---|---|
| **Never designed the matching engine** — treated it as a background worker reading sorted lists from a database and matching in batches | The engine *is* the system: keep an **in-memory order book per stock** (buy and sell sides, sorted by price), and match new orders by **price-time priority** in microseconds with **no database and no network on the fast path**. To stay safe, get durability from a **replicated log of incoming orders + replay**, not from a database write per match. | [Concurrency Control](../../concepts/08-distributed-systems/concurrency-control.md) |
| **Named the clashing problem but under-solved it** — I said "first-come-first-serve" and used one worker per stock (good), but the matching itself stayed a database operation with worries about reading half-written data | The one-worker-per-stock idea was right — finish it: **one dedicated thread per stock** owns that book, so **nothing can clash** — no locks, no half-written reads, no two workers on the same order. Doing one thing at a time *is* the correctness guarantee. | [Concurrency Control](../../concepts/08-distributed-systems/concurrency-control.md) |
| **Hot-stock problem left open** — I stalled at "batch processing," which the interviewer noted breaks the low-latency requirement | One stock's book can only be worked one order at a time — that's its nature, so you **don't split one stock, you spread different stocks across machines**. And the fear is misplaced — for the right reason: volume is **power-law** (a hot symbol can burst to 50K+/sec, far above the ~200/sec average), but a **single zero-allocation thread matches 5–10M orders/sec**, so one book absorbs even peak bursts. Batching was never needed. | [Sharding & Partitioning](../../concepts/05-databases-and-storage/sharding-and-partitioning.md) |
| **External payment in the fast path** — pay PayPal before the order can trade, on a system that's supposed to be ultra-fast | Keep slow outside calls **off the fast path**: **reserve money from a pre-loaded wallet** when the order arrives (a quick local check), match immediately, and **move the actual cash afterward**. Topping up the wallet via PayPal happens **separately from trading**. (I got here — but only when pushed.) | [Non-Functional Requirements](../../concepts/02-foundations/non-functional-requirements.md) |
| **Never handled live price fan-out** — 100M price reads/sec, but I only offered "cache + read replica" | This is a **push problem, not a query problem**: when trades happen, **push** the new prices out through a **fan-out layer** (WebSocket/SSE + edge caching) to millions of subscribers. A read replica can't answer 100M reads/sec for a number that changes on every single trade. | [Real-Time Communication](../../concepts/04-apis/realtime-communication.md) |
| **Estimates contradicted themselves and decided nothing** — 1000 vs 100 req/instance, a hand-waved 100K instances, and never the number that matters | Take every number to the **decision it forces**: **1M trades/sec ÷ 5,000 stocks ≈ 200/sec each** → the book fits in memory; **100M reads/sec** → you need a push layer, not replicas; the book's memory → a few megabytes, not a database table. A number with no decision attached is unfinished. | [Back-of-the-Envelope Estimation](../../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md) |

## What went well

Despite the score, several answers were genuinely senior and are **strengths I can carry forward**:

- **One writer per stock — reached on my own.** I spotted that giving each stock a single owner removes the risk of two matches clashing. The **core idea was right**; the miss was not building the in-memory book on top of it.
- **The wallet fix.** When challenged on the slow payment step, I proposed **pre-loaded wallets** with separate top-ups — exactly the right way to pull a slow outside call off the fast path.
- **Clean failure handling for a failed payout** — Kafka retries, then a dead-letter queue, then a fallback to crediting the wallet or paying the bank. Complete and sensible.
- **Consistency split, stated up front** — eventual consistency for reads (profiles, portfolio), strong consistency for order books. Good instinct, offered early without being asked.
- **Clear service breakdown and a readable diagram** — the scaffolding that kept Design at 7.0 and shows the drilled habits transfer to a new domain.

---

## The ideal design

**The heart of it:** a trading system is really two problems glued together. One is **matching orders fast and safely** — for each stock, keep the order book **in memory**, let **one worker** handle it one order at a time (so nothing clashes), and stay crash-safe by **writing every order to a replicated log before matching** and replaying that log to recover. The other is a **completely separate read problem** — pushing live prices to millions of people. S10 built the supporting parts well; the ideal design below adds the two missing pieces: the engine and the price fan-out.

### 1. Ideal estimation (the numbers that size the engine and settle the hot-stock question)

| Quantity | Assumption | Result | Decision it forces |
|---|---|---|---|
| Trades / sec | given | **1M/sec** | match in memory; no database on the fast path |
| Stocks | major exchange | **~5,000** | the number everything divides by |
| Trades/sec per stock (**average**) | 1M ÷ 5,000 | **~200/sec avg** | sizes *aggregate* load — but the average **hides** the real shape (next rows) |
| **Peak on a hot symbol** | power-law, market open / earnings | **50,000+/sec** | volume is heavy-tailed — TSLA/NVDA burst while most stocks sit near zero; the average does **not** prove "no hot-stock problem" |
| **Single-thread engine throughput** | zero-allocation in-memory match | **5–10M ops/sec** | **the number that actually settles it** — one thread absorbs even a 50K/sec burst (~1% of a core), so **one writer per stock holds at peak**, not just on average |
| Order book memory | ~10K waiting orders × ~100 B | **~1 MB per stock** | the book lives **in memory, not a table**; all 5,000 books fit on modest hardware |
| **Reads / sec (live prices)** | given | **100M/sec** | **a push/fan-out layer**, never read replicas |
| Latency budget | "ultra-low" | **microseconds to a few ms** | rules out outside calls, database writes, and locks on the fast path |
| Durability | no order lost in a crash | log replicated ×3 | **a replicated log + replay**, not a database write per match |

> **Don't let the average fool you.** ~200 trades/sec is only the *average*; real market volume is **power-law** — at the open or on an earnings day a single hot symbol (TSLA, NVDA) bursts to **50,000+ orders/sec** while most stocks sit near zero. What proves one writer per stock is safe is **not** the average but the engine's raw speed: a **zero-allocation, single-threaded matching core does 5–10M in-memory ops/sec**, so a 50K/sec burst on one symbol is ~1% of one core. The design conclusion is unchanged — **spread different stocks across machines, never split one stock's book** — but the *reason* is single-thread throughput, not low average volume.

### 2. Requirements — the ideal cut

- **In scope:** place **limit** and **market** orders; **cancel/modify** an order; **match by price-time priority**; a **live price + order-book feed**; **portfolio & order history**; **reserving, releasing, and settling funds** (including un-reserving on cancels and partial fills).
- **Out of scope (say so):** sign-up/identity checks, regulatory reporting, margin/derivatives, tax accounting.
- **Qualities, in priority order:** **very low latency** (the whole point — microseconds to match) → **strong consistency + durability on writes** (never lose or double-match an order) → **fault tolerance** (a standby takes over with no loss) → **huge read scale** (100M price reads/sec) → **availability**.

### 3. Ideal architecture

The system breaks into **three separate flows** that only meet at the matching engine: a **write/match flow** (order comes in → gets matched), a **read/price flow** (trades → millions of screens), and an **after-trade flow** (trades → money and records settle). The whole trick is to keep the first flow in memory and microsecond-fast by moving *everything slow* — outside payments, database writes, fan-out — onto the other two, which run **in the background, off the fast path**. Steps are numbered along the order path (1–7) and the after-trade fan-out (8a–8c).

![Ideal high-frequency trading system as a Mermaid flowchart with numbered steps. A trader places orders into an order gateway that checks login and balance, reserves funds from a wallet with no slow payment on the fast path, and routes each order by stock id using consistent hashing or a shard map, reading available and reserved money from a wallet and balances store that is pre-loaded and topped up separately. Step 1 place order reaches the gateway, step 2 reserve balance hits the wallet, step 3 the validated order is routed by stock id to a sequencer that is the one active writer per partition, stamps an ever-increasing number, and writes to the log before matching, step 4 write to log first writes to a write-once input log that is the durable record whose replay rebuilds the books, is copied three times, and feeds the standby, step 5 the matching engine reads the ordered stream from the log by advancing its own cursor rather than being pushed, and matches against its in-memory order book per stock with best price first then oldest first, one thread per stock, stocks spread across machines, matching in microseconds with no disk or network on the fast path. The standby engine reads the same log by its own cursor to stay in lockstep, and recovery is the same read replayed. Step 6 the engine writes each execution and book delta fire-and-forget into a lock-free single-writer price ring buffer that drops or conflates on overflow, and a price publisher reads that ring buffer by its own cursor, normalizes and conflates them, stamps a per-symbol sequence number, in step 6a writes the latest snapshot to an edge cache, and in step 6b publishes them once onto an internal multicast bus using Aeron or UDP where one send reaches every edge node in a one-to-thousands fan-out. The multicast bus reaches the edge fan-out tier which holds the client connections and in step 6c pushes deltas to viewers over WebSocket or SSE in a thousands-to-millions fan-out. In step 6d a viewer fetches the latest snapshot from the edge cache on connect and resyncs from it on a sequence gap, and also reads slow-changing stock profile company data from a profile store with read replica and cache. Step 7 the engine writes each after-trade event fire-and-forget into a separate trade ring buffer, kept separate so the slow Kafka path can never gate the fast price path, and a trade publisher reads that ring buffer by its own cursor and produces to Kafka with acks equal to all plus retry and a dead-letter queue, all off the hot path. Kafka carries retry, dead-letter queue, and wallet-credit fallback. From Kafka, step 8a settle and pay seller goes to a clearing and settlement service that runs in the background off the fast path to move cash and shares and pay the seller and then credits or debits the wallet, step 8b update holdings goes to a portfolio and positions store keyed by user id symbol quantity and average price, and step 8c record the trade goes to a write-once trade log store holding trades for compliance and history.](./diagrams/ideal-design.png)

#### Flow A — the write / match path (steps 1–5): *"an order comes in and gets matched"*

This is the **fast path**, measured in microseconds. Everything here is built to avoid touching a disk, a lock, or the network while a match is happening.

1. **① Place order** — a trader sends a buy/sell order (market or limit) to the **order gateway**, which checks their login and their risk/balance.
2. **② Reserve balance** — the gateway **holds the needed money in the trader's pre-loaded wallet** (moves it from `available` to `reserved`). This is a *fast local check*, **not** an outside payment call — this is the fix for the biggest flaw in my interview design. If there isn't enough money, the order is rejected here, before it reaches the engine. A **limit** buy reserves exactly `limit_price × qty`; a **market** buy has no price, so it reserves against the **top-of-book ask + a slippage buffer** (or a fixed cash cap) and releases the unspent remainder after the match — see the reservation-lifecycle note below.
3. **③ Validated order → sequencer** — the accepted order goes to the **sequencer**, which stamps it with an ever-increasing **sequence number**. This guarantees every engine copy (main and standby) processes orders in the *exact same order*.
4. **④ Stamp seq, append to the log** — the sequencer stamps the order with its `seq` and **appends it to the replicated log before any matching happens**. This ordering is the durability trick: the durable record exists first, so a crash at any later step loses nothing — you can always replay. The sequencer's job **ends here** — it never talks to the engine directly. The log is copied ×3.
5. **⑤ Engine reads the ordered stream from the log** — the engine doesn't get *pushed* orders; it **reads the log in `seq` order, advancing its own cursor** (an in-memory ring buffer on the hot path, so no network or lock). It matches each order against that **stock's in-memory book**, using **one thread per stock** (so nothing clashes) and **price-time priority**. A match produces one or more **trades**; anything left over waits on the book. The **standby reads the same log by its own cursor** — that's why it stays in lockstep — and **recovery is this exact same read** replayed from a snapshot. This is the [§4 core loop](#4-the-crux--the-order-matching-engine) — microseconds, no disk or network.

> **Why this order matters:** reserve → log → match means the two slow-or-risky things (money and durability) are both settled *before* the fast in-memory step, so the fast step never has to wait on either.

> **Routing & partitioning (steps ①→③):** the gateway routes each order by its **`stock_id`** — so **every order for one stock always reaches the same partition → the same sequencer → the same book**. That's what makes the single, ordered, single-writer stream per stock possible. Different stocks never match against each other, so a **global order across the whole exchange is never needed** — only a consistent order *within* each stock. Full reasoning in [§4](#4-the-crux--the-order-matching-engine).

> **The reservation lifecycle — market buys, cancels & partial fills.** Reserving funds is a *round trip*, not a one-way lock, and the tricky cases are worth naming:
> - **Market buy (no price):** you can't compute `limit_price × qty` up front, because the fill price isn't known until matching. Reserve against the **current best ask + a slippage buffer (say 5–10%)**, or require a **fixed cash cap**; once matched, Flow C **releases the unspent buffer** back to `available`.
> - **Cancel / modify:** a cancel is **not** a side channel — it flows through the **exact same Sequencer → Log → Engine path** as an order, so it can't race an in-flight match. When the engine applies the cancel, it emits a **fund-release event** so the wallet un-reserves the unfilled quantity.
> - **Partial fill & expiry:** a limit order that fills 300 of 1,000 leaves 700 resting; when the remainder fills, cancels, or expires, the engine emits the same **fund-release event** for exactly the unexecuted portion. Every reserve eventually nets to *spent* or *released* — nothing is left stuck in `reserved`.

#### Flow B — the read / price path (step 6): *"millions of people watch the price move"*

Trades and book changes are **outputs** of the engine, not part of matching. This flow carries the **100M reads/sec** and is deliberately a *separate system*, so read load can never slow matching down. It's a **two-stage amplifier** — one event becomes thousands of edge deliveries, then millions of client pushes — and the engine stays completely unaware of it.

6. **⑥ Write execution + book delta → price ring buffer (fire-and-forget).** The engine does a **single non-blocking write** into a **lock-free ring buffer** (the LMAX Disruptor pattern) and immediately goes back to matching — it holds **no client connections** and waits for no one. The **price publisher** reads that ring buffer *by its own cursor* and does three jobs *once, centrally*, so a million clients don't each repeat them: **normalize** to the public wire format; **conflate** (collapse a burst of ticks for one symbol to the latest — humans can't see 50 ticks/ms); and **stamp a per-symbol sequence number** so a client can detect a gap.
   - **⑥a Write the latest snapshot → edge cache.** The newest price/book snapshot is cached at the edge so a *newly-connecting* client can bootstrap instantly, and pollers are absorbed here — they never reach the engine.
   - **⑥b Publish once → internal multicast bus.** The publisher sends each update **one time** onto an **internal multicast bus (Aeron / UDP)**. Instead of looping and sending 1,000 copies, it sends once and the **network duplicates** the packet to every edge node at the same instant — a **1 → thousands** fan-out. (Full mechanism: [Low-Latency Messaging](../../concepts/07-messaging-and-events/low-latency-messaging.md).)
   - **⑥c Push deltas → viewers (WebSocket / SSE).** Each **edge node** holds the actual long-lived client connections and pushes updates down them — a **thousands → millions** fan-out. The edge tier can crash and scale on its own without ever touching the engine.
   - **⑥d Snapshot on connect, gap-fill on loss.** A client fetches the current snapshot from the edge cache when it connects, then applies live deltas. Because **multicast is inherently lossy**, gaps are recovered at the **edge node**, not the client: if a node receives `#109` right after `#104`, it requests the missing `#105–#108` from a **TCP unicast gap-fill server** and re-emits them — no forcing a full-snapshot re-download. Only an *unrecoverable* gap makes a client fall back to re-reading the snapshot. (This is the NAK-retransmit idea from [Low-Latency Messaging](../../concepts/07-messaging-and-events/low-latency-messaging.md).) Slow-changing **company profile** data is served separately from a **read replica + cache** — the one place replicas actually fit.

> **Why push, not pull — and why multicast:** a number that changes on *every* trade can't be served to 100M readers/sec from read replicas — they'd collapse. You publish each change **once** and let the network + edge tier spread it. Routing this *live* feed through Kafka would add broker latency and jitter (see [§8](#8-alternative-designs-considered)); the durable **after-trade** events in Flow C are exactly where Kafka *does* belong.

#### Flow C — the after-trade path (steps 7–8c): *"money and records settle, in the background"*

Once a trade is matched, the *bookkeeping* — paying the seller, updating who owns what, writing the audit log — is **asynchronous** and runs through Kafka. None of it is on the fast path, and all of it can retry safely.

7. **⑦ Write after-trade event → trade ring buffer → Kafka.** The engine does the *same non-blocking hand-off* as the price path: it writes each trade event into a **separate trade ring buffer** and returns to matching. A dedicated **trade publisher** drains that buffer and produces to **Kafka** with `acks=all` + retry + dead-letter queue — so the durable, blocking work happens on a **background thread, never on the matching thread**. Kafka then provides **retry + dead-letter queue + wallet-credit fallback** for anything downstream that fails.
8. Three independent consumers each do one job:
   - **⑧a Settle & pay seller → clearing/settlement service** — moves the cash and shares between the two parties and credits the seller's wallet. Runs **off the fast path**, so a slow settlement never delays a trade; a failed payout retries via Kafka → dead-letter queue → wallet-credit (my interview answer, kept).
   - **⑧b Update holdings → portfolio store** — updates `user_id, symbol, qty, avg_price` so the buyer's portfolio shows the new shares.
   - **⑧c Record the trade → trade log** — writes the trade to a write-once log for **compliance and history**.

> **Why background:** settlement and records must be *correct and durable*, but not *instant*. Running them through Kafka keeps the fast path fast, and each consumer can fail, retry, and recover on its own without ever touching the engine.

> **Why two separate ring buffers — and why the engine never blocks.** The matching thread does exactly one thing per output: a **non-blocking write into a lock-free ring buffer** (the LMAX Disruptor pattern), then straight back to matching. Everything slow — normalize, conflate, multicast, and especially the Kafka `send` with `acks=all` + retry — happens on **separate publisher threads** reading those buffers by their own cursors. Crucially, the price feed and the trade feed get **their own buffers**. In a shared ring the producer can't overwrite a slot until *every* consumer has passed it, so the **slowest consumer gates the buffer** — and the Kafka publisher is the slow one (network + broker acks). A separate trade buffer means a backed-up Kafka never stalls the µs price path. On overflow the two buffers behave differently by design: the **price buffer drops/conflates** (a stale tick is worthless), while the **trade buffer must not lose events** → it spills to a larger durable queue and alerts rather than blocking the engine. The safety net underneath: trade durability doesn't actually *depend* on Kafka — the order is already in the replicated input log before matching, so the trade buffer → Kafka is a *delivery pipeline*, not the system of record. Rule of thumb: **latency-critical + loss-tolerant → drop-on-overflow, no ack; money-critical → durable, `acks=all`, but push the ack-wait onto a background thread.**

**Resilience note (not a request flow):** because the engine's state comes entirely from *reading the log*, a **standby engine reads the same log in lockstep** and takes over instantly if the primary fails, and **recovery is just a replay** — see [§5](#5-resilience--failover).

| Layer | Component | Store / note |
|---|---|---|
| Entry | **Order gateway** — login, risk/balance check, **reserve funds from wallet** (no outside payment on the fast path) | → Wallet |
| Wallet | **Wallet / balances** — `available` + `reserved`; pre-loaded, topped up separately | KV / RDBMS |
| Spine | **Sequencer** — stamps an ever-increasing `seq`, **appends to the log before matching**; never calls the engine | → Log |
| Spine | **Input log** — write-once, durable + **replayable**, copied ×3; **engine and standby each read it by cursor** | → Engine, → Standby |
| **Core** | **Matching engine** — **in-memory order book per stock**, price-time priority, **one thread per stock**, split across machines by stock, **no disk/network on the fast path** | in-memory |
| **Core** | **Standby engine** — replays the same log, takes over on failure | in-memory |
| Hand-off | **Ring buffers** (×2, lock-free) — engine does one non-blocking write per output; **separate price + trade buffers** so slow Kafka can't gate the µs price path | in-memory (Disruptor) |
| Read | **Price publisher** — reads the price ring buffer by cursor; normalize + conflate + push | → Fan-out layer |
| After-trade | **Trade publisher** — reads the trade ring buffer by cursor; produces to Kafka `acks=all` + retry + DLQ, **off the hot path** | → Kafka |
| Read | **Fan-out layer** — WebSocket/SSE + edge caching, **absorbs 100M reads/sec** | edge cache |
| Read | **Stock profile** — slow-changing company data | read replica + cache |
| After-trade | **Kafka** — after-trade events; retry + dead-letter queue + wallet-credit fallback | Kafka |
| After-trade | **Clearing / settlement** — **background, off the fast path**; move cash + shares, pay seller | → Wallet |
| After-trade | **Portfolio / positions** — `user_id, symbol, qty, avg_price` | RDBMS/KV |
| After-trade | **Trade log** — write-once trades for compliance + history | append-only |

### 4. The crux — the order matching engine

**Problem A — match correctly and fast.** Each stock has one in-memory book, and one thread owns it, so matching is a **single loop with no locks**:

```text
# One thread per stock owns this book. Doing one thing at a time IS the safety guarantee.
on_order(o):                       # o was already sequenced + logged BEFORE we got here
    book = books[o.symbol]         # in memory: bids (high to low), asks (low to high), by price then time
    if o.side == BUY:
        while o.qty > 0 and book.asks and book.asks.best.price <= o.limit:
            resting = book.asks.best        # best price; oldest first = price-time priority
            fill = min(o.qty, resting.qty)
            emit_execution(o, resting, fill, resting.price)
            o.qty -= fill; resting.qty -= fill
            if resting.qty == 0: book.asks.pop()
        if o.qty > 0: book.bids.insert(o)   # leftover waits on the book
    else:  # SELL — mirror image against book.bids
        ...
# A MARKET order is the same loop with no price limit (limit = +/-infinity).
```

**How the book is structured (so match *and* cancel are O(1)).** "Sorted by price then time" is really three data structures working together — and the third is what makes cancellation cheap:

| Part | Structure | Why |
|---|---|---|
| **Price levels** | radix tree / B-tree keyed by price tick | jump to the best bid/ask and walk levels in order |
| **Queue at each price** | **doubly-linked list** (FIFO) | O(1) append of a new resting order and O(1) pop of the oldest → price-**time** priority |
| **Order index** | hash map `order_id → node pointer` | **O(1) cancel/modify** — jump straight to the order without scanning a price level |

Without the hash-map index, a cancel means *searching* a price level for the order; with it, a cancel is a pointer lookup + an O(1) unlink. That matters because **cancels and modifies are a large fraction of real exchange traffic**, not a rare case.

**Problem B — stay crash-safe without touching a database on the fast path.** The engine never writes to a database. Safety comes from **replaying a log** (this technique is called event sourcing):

```text
# SEQUENCER side — stamp + append, then done. It never calls the engine.
seq = next_sequence()
journal.append(seq, order)          # copied x3; THIS is the durable record

# ENGINE side — a SEPARATE loop that reads the log by its own cursor (pull, not push).
cursor = last_applied_seq           # on restart: resume from snapshot's seq
while True:
    seq, order = journal.read_next(cursor)   # ring buffer on the hot path — no network, no lock
    on_order(order); cursor = seq            # match against the in-memory book

# RECOVERY / FAILOVER: replay the log.
#   The engine's state is fully decided by the log: replay seq 0..N -> the exact same book.
#   The standby engine constantly replays the same stream, so it is always warm and ready.
#   A crash loses nothing -> restart or standby replays from the last snapshot + the log's tail.
# TRADES are outputs: the engine does ONE non-blocking write into a lock-free ring buffer
#   (Disruptor). Separate publisher threads drain it -> read layer (push) and Kafka (after-trade).
#   Two buffers, so the slow Kafka publisher can never gate the microsecond price path.
```

> **Read-a-log, not RPC.** The sequencer and engine never call each other — the sequencer *appends*, the engine *reads by cursor*. That one choice is what lets the **standby stay in lockstep** and makes **recovery just a replay** ([§5](#5-resilience--failover)); a direct push would force the sequencer to track every consumer and would break both.

| The hard problem | How the ideal design solves it |
|---|---|
| Two orders try to grab the same waiting order | **One thread per stock** — matching happens one at a time, so nothing can clash; no locks, no half-written reads |
| A "hot stock" overwhelms one machine | Volume is **power-law** — a hot symbol bursts to **50K+/sec**, far above the ~200/sec average — but a **single zero-alloc thread matches 5–10M orders/sec**, absorbing the spike; **spread different stocks across machines**, never split one stock's book |
| A crash mid-match loses orders | **Log first, then match** + **replay**; the book is fully rebuildable from the log |
| Speed vs. durability | Durability is one **sequential append to a log**, not a slow random database write; matching stays in memory, in microseconds |
| 100M readers of a number that changes every trade | **Push it out through a fan-out layer**, not read replicas — trades stream out; readers subscribe |

**Routing & partitioning — how an order reaches the right book.** The single-writer trick only works if every order for a stock reliably lands on the *one* engine that owns it. The gateway routes each order by its **`stock_id`**, so **same stock → same partition → same sequencer → same book**, every time. Because different stocks never match against each other, you **never need a global order across the exchange** — only a consistent order *within* each stock's stream, which one partition gives you for free.

- **Routing function** — consistent hashing on `stock_id`, or (often the better fit here) an explicit **`stock_id → partition` shard map** held in a coordination service such as ZooKeeper/etcd. Both are deterministic; the shard map also lets you **place hot stocks deliberately** to balance load instead of leaving it to a hash. See [Load Balancing & Consistent Hashing](../../concepts/03-networking-and-delivery/load-balancing-and-consistent-hashing.md).
- **One active writer per partition** — the routing key points to a *partition*, not a fixed machine. Exactly **one sequencer writes each stream**, so `seq = seq + 1` is consistent by construction — no locks, no distributed consensus on the hot path ([single-writer principle](../../concepts/08-distributed-systems/concurrency-control.md)). A hot standby + the replicated log preserve that single-writer invariant across failover: the old primary is **fenced off** before the promoted standby accepts writes and resumes `seq` from the log. Failover changes *which machine* serves a partition, never *how many writers* it has.

### 5. Resilience & failover

When the primary engine dies, the standby must take over **without losing or double-counting a single trade** — and the design gets this almost for free from one fact: **both engines read the same seq-ordered log by cursor** (Flow A ⑤). The standby isn't reconstructing state *after* the crash; it has already applied the log up to some `seq`, so **the sequence number *is* its bookmark** — it knows exactly where it is and simply keeps reading. "Which trades are already processed?" has a precise answer: whatever `seq` range has been applied.

![Failover timeline for the matching engine drawn as a sequence diagram across five participants - the sequencer which is the one writer per stock, the replicated log copied three times which is the source of truth, the primary engine, the standby engine, and downstream Kafka consumers for settlement portfolio and trade log. In the normal run both engines replay the same seq-ordered log in lockstep. The sequencer appends seq6 with the order to the log before any match, and the log delivers seq6 to both the primary and the standby. Each applies seq6 and reaches the same book state deterministically. The primary emits the trade to downstream with exec_id equal to f of seq6 and downstream records that exec_id. The primary then crashes right after emitting seq6. On failover the standby fences the old primary by revoking its lease so it can no longer write, then is promoted to primary - it already applied up to seq6 so it knows exactly where it is because the seq number is the bookmark. The sequencer continues appending seq7 which the log delivers to the new primary, which continues from seq7 onward with no reconstruction needed. If the handover replays seq6 again it re-emits the same exec_id f of seq6, and downstream dedups on the identical exec_id so there is no double trade. Finally on a cold restart where both engines are lost, recovery loads the latest snapshot at seq N and replays only the log tail after seq N.](./diagrams/failover-sequence.png)

**How failover stays correct:**

- **The seq number is the bookmark.** Primary and standby consume the same replicated log in lockstep, so the standby always knows it has applied "up to `seq N`". On promotion it just continues from `N+1` — no reconstruction, no "figure out what the dead primary did".
- **Deterministic outputs, so a replay can't double-count.** A trade's id is derived from its input (`exec_id = f(seq)`), **not** a random value or wall-clock. If the handover replays a `seq` the dead primary had already emitted, the re-emit carries the **same** `exec_id`, and downstream (settlement, portfolio, trade log) is **idempotent** — it dedups by `exec_id`. At-least-once emit + idempotent consumers = an exactly-once *effect*.
- **Fencing prevents two writers.** Before the standby is promoted, the old primary is **fenced** — its lease revoked, its writes rejected — so a slow-but-alive old primary can never keep emitting alongside the new one (no split-brain). This preserves the single-writer-per-partition invariant across failover.
- **Warm standby, no election on the fast path.** The standby is always caught up, so failover is instant; there's no consensus round on the hot path.
- **Cold restart = snapshot + tail.** If *both* engines are lost, recovery loads the latest **book snapshot at `seq N`** and replays only the **log tail after `N`** — the same read, from a checkpoint, so it's fast even after millions of orders.
- **Reserve funds early, settle later** — money is reserved when the order arrives, so a settlement failure never blocks or reverses a match; **Kafka retry → dead-letter queue → wallet-credit** handles payout failures (my interview answer, kept).
- **The read layer fails on its own** — if the fan-out layer lags, matching is unaffected and prices simply catch up. The two systems fail separately by design.

> **Do the two cursors stay in sync?** No — and they don't need to. "Lockstep" means *same input, same order, same deterministic result at each `seq`* — **not** "same cursor at the same instant." The primary does more per order (it also emits to the price feed and Kafka, fire-and-forget), so the **standby, doing less, often runs slightly *ahead*** — momentary skew in either direction is normal. It's harmless because the **durable log holds every order before matching**, so a cursor position is just "how far this reader has read"; the unread tail is safe in the log, not lost. On failover the standby **resumes from its own cursor and reads the tail forward** — if it was ahead there's nothing to catch up, if behind it drains the remaining log entries (bounded by replication lag) *before* accepting new orders. Determinism guarantees that at `seq N` its book is identical to what the primary's was, and idempotent `exec_id = f(seq)` cleans up any re-emitted overlap. It's exactly two Kafka consumers on one partition at different offsets — a non-issue by design.

### 6. Data model — where the crux actually lives

The single most important insight: **the order book is an in-memory data structure, not a database table.** In the interview I modeled it as sorted lists in a database matched by a worker — the right idea in the wrong place.

| Store | Structure | Fields | Note |
|---|---|---|---|
| **Order book** (the core) | **in memory, per stock** — price levels in a **radix/B-tree**, a **FIFO doubly-linked list** at each level, and an `order_id → node` **hash map** for O(1) cancel (see [§4](#4-the-crux--the-order-matching-engine)) | waiting `order_id`, `price`, `qty`, `ts` (timestamp), `user_id` | **NOT a table** — in memory, ~1 MB/stock, owned by one thread |
| **Input log** | write-once log, copied ×3 | `seq`, `order`, `ts` | the durable truth; replay rebuilds every book |
| **Wallet** | KV / RDBMS | `user_id`, `available`, `reserved` | fast balance check on entry; cash moved later |
| **Portfolio** | RDBMS/KV | `user_id`, `symbol`, `qty`, `avg_price` | updated by a Kafka consumer, off the fast path |
| **Trade log** | write-once, unchangeable | `exec_id`, `symbol`, `price`, `qty`, `buy_order_id`, `sell_order_id`, `ts` | compliance + history; the durable trade record |
| **Stock profile** | RDBMS + replica + cache | company info, financials | slow-changing data — the one place replicas fit |

### 7. Design trade-offs

| Decision | Alternatives | Why this choice (and when to switch) |
|---|---|---|
| **In-memory book, one thread per stock** | Sorted lists in a database + a matching worker | Memory + one-at-a-time gives microsecond, lock-free, clash-free matching; a database on the fast path can't hit the speed target. No reason to switch |
| **Log first, then match (event sourcing)** | A database write per match | Appending to a log is fast *and* durable, and replay gives you recovery and a warm standby for free. A database write per match is slower and harder to recover |
| **Sequence = the log's own commit offset** | A separate sequencer service that stamps `seq` | Folding the sequence number into the **replicated log's commit offset** (Aeron Archive / Raft index) removes a network hop, guarantees **gap-free** numbering, and erases the dual-sequencer split-brain surface. Prefer offset-as-`seq` in a latency-critical build; a standalone sequencer is only clearer conceptually |
| **Reserve wallet funds, settle later** | Outside payment inside the trade path | Keeps slow outside calls off the microsecond path (the original flaw); a settlement failure never blocks a match |
| **Push prices through a fan-out layer** | Read replicas + cache | 100M reads/sec of a number that changes every trade is a push problem; replicas would collapse. Publish each change once and fan it out |
| **In-memory → multicast for the live feed** | Route the live feed through Kafka too | Multicast gives µs, one-to-thousands fan-out for the latency-critical feed; Kafka adds broker latency + tail jitter. Kafka is right for the **durable after-trade** events, not the live tick feed — **tee both** when you serve ms-tolerant *and* µs consumers ([§8](#8-alternative-designs-considered)) |
| **Spread stocks across machines, don't split one stock** | Batch or split a hot stock | One book can only run one at a time; ~200 trades/sec/stock needs no splitting. Batching adds delay, breaking the whole premise |
| **Consistency on writes, availability on reads** | One model for everything | Orders/matches need strong consistency + durability; prices/profiles can tolerate being a fraction of a second stale (my correct call, kept) |

### 8. Alternative designs considered

Part of getting this right was **challenging the design and proposing alternatives** — the most instructive one: *"why not send everything through a single Kafka topic, and make the price publisher just another Kafka consumer?"* It's a legitimate design, and comparing it sharpens *why* the ideal design splits transports.

**Proposed — one Kafka log for everything.** The engine emits one trade event to Kafka; settlement, trade-log, portfolio, **and** the price publisher all consume it; the price publisher then updates a CDN/edge cache and pushes to clients over WebSocket/SSE.

| | Single-Kafka design | Ideal design (split transports) |
|---|---|---|
| Simplicity / ops | ✅ **one** backbone, fewer moving parts | more parts — multicast bus + edge tier + Kafka |
| Durability + replay | ✅ every consumer replays by offset | after-trade replays; live feed is ephemeral |
| After-trade fan-out | ✅ identical — settle / log / portfolio | ✅ identical |
| **Live-feed latency** | ❌ inherits Kafka broker latency + tail jitter | ✅ µs via in-memory ring → multicast → edge |
| Book-delta coverage | ⚠️ "trade events" miss best-bid/ask moves with no trade | book deltas emitted explicitly |
| Wasted I/O | ⚠️ persists every ephemeral tick durably | ephemeral ticks never touch disk |

**Verdict — it depends on *who reads the price feed*:**

- **Retail / consumer app** (humans watching a browser): a few ms via Kafka is imperceptible → the **single-Kafka design is arguably better** — simpler, durable, replayable. My earlier "microseconds" objection doesn't apply to this audience.
- **Professional / algo / co-located consumers** (microseconds matter): Kafka is disqualifying for the live feed → you need the **in-memory → multicast** path.
- **A real venue serves both** → **tee the feed**: emit once to Kafka (durable, ms-tolerant consumers) *and* once to multicast (µs consumers). This is the **transport-per-consumer** principle — match the transport to each consumer's latency and durability needs; don't force one bus to do both. See [Low-Latency Messaging](../../concepts/07-messaging-and-events/low-latency-messaging.md).

> **One gap in the proposed sketch:** the price publisher had **no incoming source** drawn — it must be fed by the engine's (or Kafka's) trade + book-delta stream. Always wire the publisher's input explicitly, or the whole read path floats disconnected.

## Takeaways to drill

1. **The matching engine *is* the interview — build it, don't just name it.** For a trading problem the core is an **in-memory order book per stock**, **price-time priority**, **one thread per stock**, and a **replicated log + replay** for safety. Landing on "a background worker over a database" is the miss. Drill this part cold, then **re-solve S10** — the fix that's already proven to work.
2. **Finish the clashing idea.** One thread per stock (reached on my own!) *is* the answer — but only if I then build the **lock-free in-memory match loop** on top of it. Naming the idea scored points; not building on it lost them.
3. **Keep slow outside calls, database writes, and locks off the fast path.** Putting an external payment in the trade path was a basic mistake. **Reserve now, settle later; log first, project later; push, don't poll.** For every step, ask: if this can be slow, does it belong on the fast path?
4. **Take every estimate to the decision it forces — and keep the numbers consistent.** `1M ÷ 5,000 ≈ 200/sec` sizes *aggregate* load, but it's only an **average** — volume is power-law, so the real hot-stock answer is the engine's **single-thread throughput (5–10M ops/sec vs. a 50K/sec peak burst)**, not the average; `100M reads/sec` **forces a push layer**. Numbers that contradict each other and decide nothing (1000 vs 100 req/instance) score nothing.
5. **Put the core in the right place.** The order book lives **in memory**, not in a database table. When the key data structure clearly needs memory and a single owner, drawing it as a datastore is the tell that I didn't really understand the core.
6. **Huge read loads are a fan-out problem.** 100M reads/sec of a number that changes every trade → **a price publisher + edge push layer (WebSocket/SSE)**, kept separate from matching. Read replicas are only for slow-changing data.
7. **Bank the wins — they're senior instincts.** One thread per stock, the wallet fix, the Kafka failure handling, and the consistency split are real strengths that carried into a brand-new domain. The gap is **depth on the core**, not the fundamentals — which is exactly what a focused re-solve fixes.
8. **Know the plumbing, not just the boxes.** The two things worth being able to defend cold: the engine **reads the log by cursor (pull), it isn't pushed** — which is *why* the standby stays in lockstep and recovery is a replay; and failover is correct because **the seq is a bookmark + outputs are idempotent (`exec_id = f(seq)`) + the old primary is fenced**. Draw the data path so it can't imply the wrong mechanism, and match the **transport to each consumer** (µs multicast for the live feed, durable Kafka for after-trade) instead of forcing one bus to do both. And know how the engine *hands off* without blocking: **one non-blocking write into a lock-free ring buffer** per output, with **separate buffers** for the fast price feed and the slow Kafka path so the slow consumer can never gate the matching thread — the ack-wait for `acks=all` lives on a background publisher, never on the hot path.

9. **The average can lie, and the reverse paths matter.** Two senior tells this write-up now bakes in: (a) never justify "no hot-stock problem" with an *average* — market volume is **power-law**, so the real answer is **single-thread engine throughput (5–10M ops/sec) absorbing 50K/sec bursts**, not `1M ÷ 5,000`; and (b) design the **reverse and edge paths**, not just the happy path — **market-buy reservation** (best-ask + slippage, then release the unspent buffer), **cancels routed through the same log** with a **fund-release** event, **partial-fill/expiry** un-reserving, **O(1) cancel** via an `order_id → node` map, and **edge-node gap-fill** for lossy multicast. Naming the happy path is the baseline; the edge cases are where senior depth shows.

→ Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
