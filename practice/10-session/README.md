# Session 10 — High-Frequency Stock Trading System · ⚠️ 5.5/10

> A scored, analyzed system-design mock — and a **regression that confirms the tracker's central thesis** rather than contradicting it. After [S09](../09-session/README.md)'s breakthrough **Pass (✅ 7.5)** on a *re-solved* problem, S10 is a **brand-new, hard-crux** problem — and it drops to **⚠️ 5.5**, the lowest since [S04](../04-session/README.md). This is **S04's exact shape**: a strong re-solve (S03 / S09) followed by first contact with a hard crux that re-exposes the **"name-but-don't-solve" ceiling**. The candidate showed genuine senior instincts — **single-writer-per-symbol via consistent hashing reached *unprompted***, a **wallet optimization** to pull external payment off the hot path when challenged, **Kafka retry → DLQ → wallet-credit fallback** for a failed seller payout, and a **read/write consistency split** stated upfront. But the **order matching engine — the heart of a trading system — was never designed** (modeled as a DB-backed "settlement worker" reading sorted lists), the **hot-stock partition stalled at "batch processing"** (which contradicts ultra-low latency), **external payment sat in the critical trade path** until challenged, the **100M-reads/sec real-time price feed** was never raised as a push problem, and the **estimation was internally inconsistent and drove no decision**. The periphery held; the crux did not.

| | |
|---|---|
| **Problem** | Design a high-frequency stock trading system — millions of trades/sec, ultra-low latency, strong consistency |
| **Focus** | The order matching engine (concurrency + latency) + real-time price fan-out at extreme read scale |
| **Overall** | **5.5 / 10** — ⚠️ Borderline *(the platform's words: "Lean No Hire")* — ▼ 2.0 vs S09's 7.5, on a new problem |
| **Weakest areas** | Problem-Solving (5.0), Scale & Trade-offs (5.0) — the crux axes |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |

## The problem

> Design a **high-frequency stock trading system** that can process **millions of trades per second** with **ultra-low latency** and ensure **data consistency**.

A trading system looks like a buy/sell-CRUD problem and is actually an **in-memory, single-writer, deterministic-matching** problem. The defining component is the **order matching engine**: a **limit order book per symbol** where incoming orders match against resting orders by **price-time priority** in microseconds, with **no I/O on the hot path**. Two questions decide the design: **(1) how do you match orders correctly and fast** — one serialized writer per symbol against an in-memory book, made durable by a **sequenced, replicated input journal + deterministic replay** — and **(2) how do millions of readers see live prices** — a 100M-reads/sec **push/fan-out** tier fed by executions, decoupled from the match path. The candidate reached neither crux directly, which is what capped the score.

## Requirements & estimation

- **Functional** — **view a stock profile** (current/previous value, daily/monthly/yearly change, company info, quarterly/annual financials); **place a trade** as a **market order** or **limit order**; **view portfolio** (holdings, current value, past orders). A reasonable cut, though **real-time price feeds** and the **matching engine** itself were never named as requirements.
- **Non-functional** — **scalable · consistent · reliable · fault-tolerant · resilient · highly available**. Listed but not deeply reasoned initially; the **latency target** (the whole point) was not quantified.
- **The one good trade-off call** — **consistency for writes, availability + low latency for reads** — stated upfront, and correct.
- **Estimation (the weak spot)** — 1M users · 500K DAU · write:read 1:100 · problem states **1M trades/sec** · 5000 total stocks · **100M reads/sec**. Then: each instance handles "1000 req/sec" but the math used "100 req/sec" → **100K instances** (a hand-wave). The numbers were **internally inconsistent and drove no decision** — critically, the estimate never derived the number that *dissolves the whole hot-stock fear*: **1M trades/sec ÷ 5000 symbols ≈ 200 trades/sec per symbol**, which fits comfortably in one in-memory book.

![Requirements canvas for a high-frequency stock trading system. The problem is to design a system that can process millions of trades per second with ultra-low latency and ensure data consistency. Functional requirements list viewing a list of stocks where each stock has a current value, previous value, daily monthly and yearly change, company name and description, annual and quarterly profits, and quarterly turnover forming a stock profile; sending a trade as either a market order or a limit order where a limit order settles at a user-specified price and a market order settles at the current market price; and viewing the user portfolio with current value of holdings and previous orders. Non-functional requirements list scalable, consistent, reliable, fault tolerant, resilient, and highly available, with a note that writes should be consistent while reads should be highly available and low latency. The estimation block assumes 1 million total users, 500 thousand daily active users at 50 percent, a write to read ratio of 1 to 100, a stated write throughput of 1 million trades per second, 5000 total stocks in the exchange, a read throughput of 100 million per second, a per-instance capacity of around 100 to 1000 requests per second, and a resulting estimate of about 100 thousand instances.](./diagrams/requirements.png)

## The design I produced

![Architecture canvas for the stock trading system as produced in the interview. A client connects to an API Gateway containing a load balancer, authentication and authorization, and rate limiting. Reads go to a Read Stock Profile Service backed by a stock profile datastore with a read replica and cache. Trades go to a Trade Service which writes to a User Orders datastore and, for sell orders, to a Sell Orders datastore, and for buy orders to a Buy Orders datastore after a payment step. A Payment Service calls an external payment provider like PayPal using a payment id and webhook URL, and a Notification Service pushes payment status to the client over SSE. A Trade Settlement Worker reads sorted lists of buy and sell orders per stock and matches them by price, partitioned so that a single worker handles a given stock via consistent hashing on stock id, then writes the updated price to a Stock Price datastore with a read replica and cache and emits a trade settlement event to a Kafka message queue. Two consumers read the event: a Seller Payout Service that pays the seller via the Payment Service with retry and dead letter queue and wallet-credit fallback, and a User Portfolio Write Service that updates a User Portfolio datastore. A User Portfolio Read Service reads holdings and multiplies units by the cached stock price to show current value.](./diagrams/architecture.png)

- **API Gateway** — load balancer, auth, rate limiting. Standard, correct.
- **Read Stock Profile Service** — slow-changing reference data behind a **read replica + cache**. Correct call — profiles don't change per second.
- **Trade Service (stateless)** — writes orders to **User Orders**, **Sell Orders**, **Buy Orders** datastores (append-only). Scales horizontally — a fair observation.
- **Trade Settlement Worker (the crux, modeled wrong)** — reads **DB-backed sorted lists** of buy/sell orders per stock and matches by price. **Partitioned by `stock_id` via consistent hashing so one worker owns a stock** — the concurrency guard, reached *unprompted*. But this is a **batch matcher over a database**, not an **in-memory order book** — the canonical miss.
- **Payment Service + external provider** — originally **in the critical buy path** (pay PayPal before the order books); later fixed to a **wallet** (reserve/deduct from balance, top-up off-path) when challenged.
- **Kafka post-settlement** — **Seller Payout Service** (retry → DLQ → wallet-credit/bank fallback) and **User Portfolio Write Service** consume settlement events. The failure-handling here was genuinely good.
- **Stock Price datastore + Portfolio read** — worker writes the latest price; portfolio value = `units × cached price`. But **how 100M readers get live prices** (push vs pull) was never addressed.

## Scorecard

| Axis | S09 | **S10** | Δ |
|---|:--:|:--:|:--:|
| Requirements Gathering | 8.0 | **6.0** | ▼ 2.0 |
| Design Skills | 8.0 | **7.0** | ▼ 1.0 |
| Problem-Solving | 7.5 | **5.0** | ▼ 2.5 |
| Scalability & Trade-offs | 7.0 | **5.0** | ▼ 2.0 |
| Communication | 8.0 | **6.0** | ▼ 2.0 |
| **Overall** | 7.5 | **5.5** | ▼ 2.0 |

> **Design held highest (7.0) — the periphery is now a drilled habit.** What collapsed are the **crux axes**: Problem-Solving (▼2.5) and Scale & Trade-offs (▼2.0), exactly where the matching engine, hot partition, and extreme read scale live. This is **not a loss of skill** — it's the tracker's confirmed pattern: a drilled candidate carries the scaffolding of *any* problem to a competent baseline, but a **first encounter with a hard crux** re-exposes the ceiling. The remedy is the one S09 proved: **re-solve after drilling the exact crux.**

## What lost points — and the fix

| What I missed in the room | The answer a senior would give | Study |
|---|---|---|
| **The order matching engine was never designed** — modeled as a "settlement worker" reading DB-backed sorted lists and batch-matching | The engine *is* the system: an **in-memory limit order book per symbol** (bids/asks as price-sorted structures), matching incoming orders by **price-time priority** in microseconds with **no DB and no I/O on the hot path** (LMAX-Disruptor style). Durability comes from a **sequenced, replicated input journal + deterministic replay**, not from a database write per match. | [Concurrency Control](../../concepts/08-distributed-systems/concurrency-control.md) |
| **Concurrency named but under-solved** — "first-come-first-serve," then consistent hashing per stock (good), but the *matching itself* stayed a DB operation with dirty-read worries | Consistent-hashing-per-symbol was the right instinct — finish it: **one single-writer thread per symbol** owns that book, so there is **no lock, no dirty read, no two-workers-race** by construction. Serialization *is* the correctness guarantee. | [Concurrency Control](../../concepts/08-distributed-systems/concurrency-control.md) |
| **Hot-stock partition unresolved** — stalled at "batch processing," which the interviewer flagged as contradicting ultra-low latency | A single symbol's book is **one serialization point by nature** — you don't split *within* a symbol, you **scale across symbols**. And the estimate dissolves the fear: **~200 trades/sec per symbol** fits one in-memory book with headroom; there is no hot-partition problem to batch around. | [Sharding & Partitioning](../../concepts/05-databases-and-storage/sharding-and-partitioning.md) |
| **External payment in the critical trade path** — pay PayPal before the order enters the book, on an *ultra-low-latency* system | Keep external I/O **off the hot path**: **reserve funds from a pre-funded wallet at order entry** (a fast local balance check), match immediately, **settle cash asynchronously** after execution. Wallet top-up via the external provider happens **independently of trading**. (Reached — but only when challenged.) | [Non-Functional Requirements](../../concepts/02-foundations/non-functional-requirements.md) |
| **Real-time price fan-out never raised** — 100M reads/sec of live prices, but only "cache + read replica" | This is a **push/fan-out** problem, not a query problem: executions feed a **market-data publisher → edge fan-out tier (WebSocket/SSE + internal multicast + edge cache)** that pushes deltas to millions of subscribers. A read replica can't serve 100M reads/sec of a value that changes every trade. | [Real-Time Communication](../../concepts/04-apis/realtime-communication.md) |
| **Estimation inconsistent and decision-free** — 1000 vs 100 req/instance, hand-wave 100K instances; never the deciding number | Push each number to the **decision it forces**: **1M trades/sec ÷ 5000 symbols ≈ 200/sec per symbol** → the book fits in RAM (no sharding *within* a symbol); **100M reads/sec** → a push tier, not replicas; order-book memory → megabytes, not a table. A figure with no decision attached is incomplete. | [Back-of-the-Envelope Estimation](../../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md) |

## What went well

Despite the score, several answers were genuinely senior and are **transferable strengths**:

- **Single-writer-per-symbol via consistent hashing on `stock_id` — reached *unprompted*.** The candidate independently identified that assigning each stock to exactly one worker eliminates the concurrent-match race. The **primitive was right**; the miss was not building the in-memory book *on top of* it.
- **The wallet optimization.** When challenged on external payment latency, the candidate proposed **pre-funded wallets** with off-path top-up — exactly the right way to pull a slow external call off the hot path.
- **Kafka retry → DLQ → wallet-credit / bank fallback** for a failed seller payout — a clean, complete failure-handling answer for the post-trade path.
- **Read/write consistency split stated upfront** — eventual consistency for reads (profiles, portfolio), strong/quorum for order books. Correct instinct, volunteered early.
- **Clean service decomposition and a legible diagram** — the scaffolding that held Design at 7.0 and shows the drilled habits transfer to a brand-new domain.

---

## The ideal design

**The crux:** a trading system is an **in-memory, single-writer, deterministic-matching** problem with a **separate extreme-read fan-out** problem bolted alongside it. The match path must be **microsecond-fast and lossless**: one **limit order book per symbol** in RAM, **one writer thread per symbol** (no locks), made durable by **appending every input to a sequenced, replicated journal *before* matching** and recovering by **deterministic replay**. The read path is a **different system**: executions fan out through a **push tier** to millions of subscribers. S10 built the periphery well; the ideal below installs the two pieces it missed — the engine and the fan-out.

### 1. Ideal estimation (the numbers that size the engine and *dissolve* the hot-stock fear)

| Quantity | Assumption | Result | Decision it forces |
|---|---|---|---|
| Trades / sec | stated | **1M/sec** | in-memory matching; no DB on the hot path |
| Symbols | major exchange | **~5,000** | the divisor everything hinges on |
| **Trades/sec per symbol** | 1M ÷ 5,000 | **~200/sec** | **the decisive number** — one book handles it easily; **there is no hot-partition problem to batch around** |
| Order book memory | ~10K resting orders × ~100 B | **~1 MB/symbol** | the book is **in RAM, not a table**; all 5,000 books fit on modest hardware |
| **Reads / sec (live prices)** | stated | **100M/sec** | **a push/fan-out tier**, never read replicas |
| Match latency budget | "ultra-low" | **microseconds–low ms** | rules out external I/O, synchronous DB writes, and locks on the match path |
| Durability | every order must survive a crash | replicated journal ×3 | **sequenced input journal + replay**, not per-match DB writes |

> The number that reframes the problem: **~200 trades/sec per symbol.** It proves a single in-memory book per symbol is *ample*, so the "hot stock" fear evaporates and the design centers on **one fast writer per symbol**, not on splitting a symbol's work.

### 2. Requirements — the ideal cut

- **Functional (in scope):** place **limit** and **market** orders; **cancel/modify**; **match by price-time priority**; **live price + order-book feed**; **portfolio & order history**; **funds reserve + settlement**.
- **Out (scope explicitly):** KYC/onboarding internals, regulatory reporting pipelines, margin/derivatives, tax lots.
- **Non-functional (ranked):** **ultra-low latency** (the entire premise — microseconds on the match path) → **strong consistency & durability on the write path** (no lost or double-matched order) → **fault tolerance** (hot-standby failover with zero loss) → **extreme read scalability** (100M price reads/sec) → **availability**.

### 3. Ideal architecture

The **order gateway** validates and **reserves funds from a wallet** (no external payment on the hot path); a **sequencer** assigns a global monotonic sequence and **appends to a replicated input journal *before* matching**; the **matching engine** runs an **in-memory limit order book per symbol** with **one writer per symbol** and emits executions with **zero I/O on the hot path**; a **hot-standby** replays the same journal, ready to take over. Executions fan **two ways**: to a **market-data publisher → edge fan-out tier** that absorbs 100M reads/sec via push, and to **Kafka** for **async post-trade** work (clearing/settlement, portfolio, immutable trade log) — all *off* the match path. Edges are numbered along the order spine (1–7) and the post-trade fan-out (8a–8c).

![Ideal high-frequency trading system as a Mermaid flowchart with numbered steps. A trader places orders into an order gateway that authenticates, runs a risk and balance check, and reserves funds from a wallet with no external payment on the hot path, reading available and reserved balances from a wallet and balances store that is pre-funded and topped up off path. Step 1 place order reaches the gateway, step 2 reserve balance hits the wallet, step 3 the validated order goes to a sequencer that assigns a global monotonic sequence number and appends to a replicated input journal before matching, step 4 append then sequence writes to an append-only input journal that provides durability and deterministic replay and is replicated three times and feeds a hot standby, step 5 the sequencer feeds the sequenced stream to the matching engine which is the core, holding an in-memory limit order book per symbol with price-time priority and a single writer per symbol, sharded by symbol, performing microsecond matches with no I O on the hot path. The journal also replays into the engine on recovery and feeds the same stream to a hot-standby engine ready to take over. Step 6 the engine emits execution and book delta events to a market-data publisher that fans out executions and book deltas by push to an edge fan-out tier using WebSocket or SSE with internal multicast and edge cache that absorbs 100 million reads per second and pushes live prices to read clients, who also read slow-changing stock profile reference data from a profile store with read replica and cache. Step 7 the engine emits a post-trade event to Kafka which carries retry, dead letter queue, and wallet-credit fallback. From Kafka, step 8a clear and pay seller goes to a clearing and settlement service that runs asynchronously off the match path to move cash and securities and credit the seller and then credits or debits the wallet, step 8b update holdings goes to a portfolio and positions store keyed by user id symbol quantity and average price, and step 8c append execution goes to an immutable trade log store holding executions for compliance and history.](./diagrams/ideal-design.png)

| Layer | Component | Store / note |
|---|---|---|
| Entry | **Order gateway** — auth, risk/balance check, **reserve funds from wallet** (no external payment on hot path) | → Wallet |
| Wallet | **Wallet / balances** — `available` + `reserved`; pre-funded, topped up off-path | KV / RDBMS |
| Spine | **Sequencer** — global monotonic `seq`, **append to replicated journal *before* matching** | → Journal, → Engine |
| Spine | **Input journal** — append-only, durability + **deterministic replay**, replicated ×3, feeds hot-standby | append-only log |
| **Core** | **Matching engine** — **in-memory limit order book per symbol**, price-time priority, **single writer per symbol**, sharded by symbol, **no I/O on hot path** | in-memory |
| **Core** | **Hot-standby engine** — replays the same journal, takes over on failure | in-memory |
| Read | **Market-data publisher** — fan out executions + book deltas via push | → Edge tier |
| Read | **Edge fan-out tier** — WebSocket/SSE + internal multicast + edge cache, **absorbs 100M reads/sec** | edge cache |
| Read | **Stock profile** — slow-changing reference data | read replica + cache |
| Post-trade | **Kafka** — post-trade events; retry + DLQ + wallet-credit fallback | Kafka |
| Post-trade | **Clearing / settlement** — **async, off the match path**; move cash + securities, credit seller | → Wallet |
| Post-trade | **Portfolio / positions** — `user_id, symbol, qty, avg_price` | RDBMS/KV |
| Post-trade | **Trade log** — immutable executions for compliance + history | append-only |

### 4. The crux — the order matching engine

**Problem A — match correctly and fast.** Each symbol has one in-memory book; one thread owns it, so matching is a **single serialized loop with no locks**:

```text
# One thread per symbol owns this book. No lock — serialization IS the guarantee.
on_order(o):                       # o already sequenced + journaled BEFORE we get here
    book = books[o.symbol]         # in-memory: bids (desc), asks (asc), price-time ordered
    if o.side == BUY:
        while o.qty > 0 and book.asks and book.asks.best.price <= o.limit:
            resting = book.asks.best        # best price; oldest first = price-time priority
            fill = min(o.qty, resting.qty)
            emit_execution(o, resting, fill, resting.price)
            o.qty -= fill; resting.qty -= fill
            if resting.qty == 0: book.asks.pop()
        if o.qty > 0: book.bids.insert(o)   # remainder rests on the book
    else:  # SELL — symmetric against book.bids
        ...
# A MARKET order is the same loop with no price bound (limit = +/-infinity).
```

**Problem B — durability without I/O on the hot path.** The engine never touches a database. Durability is **event sourcing**:

```text
# BEFORE matching: sequencer appends every input to a replicated journal.
seq = next_sequence()
journal.append(seq, order)          # replicated x3; THIS is the durable record
feed_to_engine(seq, order)          # engine consumes the sequenced stream

# RECOVERY / FAILOVER: deterministic replay.
#   The engine is a pure function of the journal: replay seq 0..N -> identical book.
#   Hot-standby continuously replays the same stream and is always warm.
#   A crash loses nothing -> restart/standby replays from the last snapshot + journal tail.
# EXECUTIONS are outputs: fan them to the read tier (push) and to Kafka (post-trade),
#   both OFF the match path.
```

| The hard problem | How the ideal design kills it |
|---|---|
| Two orders race for the same resting order | **One writer thread per symbol** — matching is serialized by construction; no lock, no dirty read |
| "Hot stock" overwhelms a partition | ~200 trades/sec/symbol fits one book; **scale across symbols**, never split a symbol's book |
| Crash mid-match loses orders | **Journal-then-match** + **deterministic replay**; the book is a pure function of the journal |
| Ultra-low latency vs. durability | Durability is a **sequential append**, not a random DB write; matching stays in RAM, microseconds |
| 100M readers of a value that changes every trade | **Push fan-out tier**, not read replicas — executions stream out; readers subscribe |

### 5. Resilience & failover

- **Hot-standby by replay** — the standby continuously consumes the same journal, so failover is warm and lossless; no leader election on the match path itself.
- **Journal is the source of truth** — replicated ×3; periodic **book snapshots** bound replay time (replay = snapshot + journal tail).
- **Wallet reserve, async settle** — reserving funds at entry means a settlement failure never blocks or reverses a match; **Kafka retry → DLQ → wallet-credit** handles payout failures (the candidate's answer, kept).
- **Read tier degrades independently** — if the fan-out tier lags, the match path is unaffected; prices catch up. The two systems fail separately by design.

### 6. Data model — where the crux actually lives

The single most important insight: **the order book is an in-memory data structure, not a database table.** The room modeled it as DB-backed sorted lists matched by a worker — the crux table in the *wrong medium*.

| Store | Structure | Fields | Note |
|---|---|---|---|
| **Order book** (the crux) | **in-memory per symbol** — bids (desc), asks (asc), price-time ordered | resting `order_id`, `price`, `qty`, `ts`, `user_id` | **NOT a table** — RAM, ~1 MB/symbol, owned by one thread |
| **Input journal** | append-only log, replicated ×3 | `seq`, `order`, `ts` | durable truth; deterministic replay rebuilds every book |
| **Wallet** | KV / RDBMS | `user_id`, `available`, `reserved` | fast balance check on entry; settled async |
| **Portfolio** | RDBMS/KV | `user_id`, `symbol`, `qty`, `avg_price` | updated by a Kafka consumer, off the match path |
| **Trade log** | append-only, immutable | `exec_id`, `symbol`, `price`, `qty`, `buy_order_id`, `sell_order_id`, `ts` | compliance + history; the durable execution record |
| **Stock profile** | RDBMS + replica + cache | company info, financials | slow-changing reference data — the one place replicas fit |

### 7. Design trade-offs

| Decision | Alternatives | Why this choice (and when to switch) |
|---|---|---|
| **In-memory book, single writer per symbol** | DB-backed sorted lists + worker matching | RAM + serialization gives microsecond, lock-free, race-free matching; a DB on the hot path can't hit the latency bar. No reason to switch |
| **Journal-then-match (event sourcing)** | DB write per match | Sequential append is fast + durable; replay gives free recovery + warm standby. A per-match DB write is both slower and less recoverable |
| **Wallet reserve, async settlement** | External payment in the trade path | Keeps slow external I/O off the microsecond path (the room's original flaw); settlement failures never block a match |
| **Push fan-out tier for prices** | Read replicas + cache | 100M reads/sec of a per-trade-changing value is a fan-out problem; replicas melt. Push deltas to subscribers |
| **Scale across symbols, not within** | Batch / split a hot symbol | A book is one serialization point; ~200 trades/sec/symbol needs no splitting. Batching adds latency, violating the premise |
| **Consistency on writes, availability on reads** | Uniform model | Orders/matches need strong consistency + durability; prices/profiles tolerate sub-second staleness (the room's correct call, kept) |

## Takeaways to drill

1. **The matching engine *is* the interview — design it, don't name it.** A trading prompt's crux is an **in-memory limit order book per symbol**, **price-time priority**, **single writer per symbol**, **sequenced journal + deterministic replay** for durability. Reaching "settlement worker over a DB" is the miss. Drill this component cold, then **re-solve S10** — the proven remedy.
2. **Finish the concurrency thought.** Single-writer-per-symbol (reached unprompted!) *is* the answer — but only if you then build the **lock-free in-memory match loop** on top of it. Naming the primitive scored; not designing on it didn't.
3. **Keep external I/O, synchronous writes, and locks off the latency-critical path.** External payment in the trade path was a fundamental error. **Reserve-then-settle, journal-then-project, push-don't-poll.** Interrogate every hop: if it can fail slowly, it doesn't belong on the hot path.
4. **Push each estimate to the decision it forces — and keep the numbers consistent.** `1M ÷ 5000 ≈ 200/sec per symbol` **dissolves the hot-stock fear**; `100M reads/sec` **forces a push tier**. Inconsistent, decision-free numbers (1000 vs 100 req/instance) score nothing.
5. **Model the crux in the right medium.** The order book is **in RAM**, not a DB table. When the defining data structure demands memory + a single writer, drawing it as a datastore is the tell that the crux wasn't understood.
6. **Extreme reads are a fan-out problem.** 100M reads/sec of a value that changes every trade → **market-data publisher → edge push tier (WebSocket/SSE + multicast)**, decoupled from the match path. Read replicas are for slow-changing reference data only.
7. **Bank the wins — they're senior instincts.** Single-writer-per-symbol, the wallet fix, Kafka DLQ fallback, and the consistency split are genuine strengths that transferred to a brand-new domain. The gap is **depth on the crux**, not the fundamentals — exactly what a targeted re-solve closes.

→ Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
