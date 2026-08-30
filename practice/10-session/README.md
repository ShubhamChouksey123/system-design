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
- **Estimation (the weak spot)** — 1M users, 500K daily active, a 1:100 write-to-read ratio, **1M trades/sec** (given), 5,000 stocks, **100M reads/sec**. But then I said each instance handles "1000 req/sec" and did the math with "100 req/sec," landing on "100K instances" — a guess. The numbers **contradicted each other and led to no real decision.** Worst of all, I never did the one division that matters: **1M trades/sec ÷ 5,000 stocks ≈ 200 trades/sec per stock** — small enough to fit comfortably in one in-memory book, which would have dissolved my whole "hot stock" worry.

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
| **Hot-stock problem left open** — I stalled at "batch processing," which the interviewer noted breaks the low-latency requirement | One stock's book can only be worked one order at a time — that's its nature, so you **don't split one stock, you spread different stocks across machines**. And the math removes the fear entirely: **~200 trades/sec per stock** fits one in-memory book easily. There was never a hot-stock problem to batch around. | [Sharding & Partitioning](../../concepts/05-databases-and-storage/sharding-and-partitioning.md) |
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

### 1. Ideal estimation (the numbers that size the engine and remove the hot-stock fear)

| Quantity | Assumption | Result | Decision it forces |
|---|---|---|---|
| Trades / sec | given | **1M/sec** | match in memory; no database on the fast path |
| Stocks | major exchange | **~5,000** | the number everything divides by |
| **Trades/sec per stock** | 1M ÷ 5,000 | **~200/sec** | **the key number** — one book handles this easily; **there is no hot-stock problem to batch around** |
| Order book memory | ~10K waiting orders × ~100 B | **~1 MB per stock** | the book lives **in memory, not a table**; all 5,000 books fit on modest hardware |
| **Reads / sec (live prices)** | given | **100M/sec** | **a push/fan-out layer**, never read replicas |
| Latency budget | "ultra-low" | **microseconds to a few ms** | rules out outside calls, database writes, and locks on the fast path |
| Durability | no order lost in a crash | log replicated ×3 | **a replicated log + replay**, not a database write per match |

> The number that changes everything: **~200 trades/sec per stock.** It shows one in-memory book per stock is more than enough, so the "hot stock" fear disappears and the design centers on **one fast worker per stock** — not on splitting a single stock's work.

### 2. Requirements — the ideal cut

- **In scope:** place **limit** and **market** orders; **cancel/modify** an order; **match by price-time priority**; a **live price + order-book feed**; **portfolio & order history**; **reserving and settling funds**.
- **Out of scope (say so):** sign-up/identity checks, regulatory reporting, margin/derivatives, tax accounting.
- **Qualities, in priority order:** **very low latency** (the whole point — microseconds to match) → **strong consistency + durability on writes** (never lose or double-match an order) → **fault tolerance** (a standby takes over with no loss) → **huge read scale** (100M price reads/sec) → **availability**.

### 3. Ideal architecture

The system breaks into **three separate flows** that only meet at the matching engine: a **write/match flow** (order comes in → gets matched), a **read/price flow** (trades → millions of screens), and an **after-trade flow** (trades → money and records settle). The whole trick is to keep the first flow in memory and microsecond-fast by moving *everything slow* — outside payments, database writes, fan-out — onto the other two, which run **in the background, off the fast path**. Steps are numbered along the order path (1–7) and the after-trade fan-out (8a–8c).

![Ideal high-frequency trading system as a Mermaid flowchart with numbered steps. A trader places orders into an order gateway that checks login and balance and reserves funds from a wallet with no slow payment on the fast path, reading available and reserved money from a wallet and balances store that is pre-loaded and topped up separately. Step 1 place order reaches the gateway, step 2 reserve balance hits the wallet, step 3 the validated order goes to a sequencer that stamps an ever-increasing number and writes to the log before matching, step 4 write to log first writes to a write-once input log that is the durable record whose replay rebuilds the books, is copied three times, and feeds the standby, step 5 the sequencer feeds the ordered stream to the matching engine which is the core, holding an in-memory order book per stock with best price first then oldest first, one thread per stock, stocks spread across machines, matching in microseconds with no disk or network on the fast path. The log also replays into the engine on recovery and feeds the same stream to a standby engine ready to take over. Step 6 the engine sends trade and book change events to a price publisher that pushes out trades and book changes to a fan-out layer using WebSocket or SSE with an edge cache that absorbs 100 million reads per second and pushes live prices to viewers, who also read slow-changing stock profile company data from a profile store with read replica and cache. Step 7 the engine sends an after-trade event to Kafka which carries retry, dead-letter queue, and wallet-credit fallback. From Kafka, step 8a settle and pay seller goes to a clearing and settlement service that runs in the background off the fast path to move cash and shares and pay the seller and then credits or debits the wallet, step 8b update holdings goes to a portfolio and positions store keyed by user id symbol quantity and average price, and step 8c record the trade goes to a write-once trade log store holding trades for compliance and history.](./diagrams/ideal-design.png)

#### Flow A — the write / match path (steps 1–5): *"an order comes in and gets matched"*

This is the **fast path**, measured in microseconds. Everything here is built to avoid touching a disk, a lock, or the network while a match is happening.

1. **① Place order** — a trader sends a buy/sell order (market or limit) to the **order gateway**, which checks their login and their risk/balance.
2. **② Reserve balance** — the gateway **holds the needed money in the trader's pre-loaded wallet** (moves it from `available` to `reserved`). This is a *fast local check*, **not** an outside payment call — this is the fix for the biggest flaw in my interview design. If there isn't enough money, the order is rejected here, before it reaches the engine.
3. **③ Validated order → sequencer** — the accepted order goes to the **sequencer**, which stamps it with an ever-increasing **sequence number**. This guarantees every engine copy (main and standby) processes orders in the *exact same order*.
4. **④ Write to the log, then match** — the sequencer **writes the order to a replicated log before matching it**. This ordering is the durability trick: the durable record exists first, so a crash at any later step loses nothing — you can always replay. The log is copied ×3 and also feeds the standby engine.
5. **⑤ Feed the ordered stream → matching engine** — the engine reads the ordered stream and matches against that **stock's in-memory book**, using **one thread per stock** (so nothing clashes) and **price-time priority**. A match produces one or more **trades**; anything left over waits on the book. This is the [§4 core loop](#4-the-crux--the-order-matching-engine) — microseconds, no disk or network.

> **Why this order matters:** reserve → log → match means the two slow-or-risky things (money and durability) are both settled *before* the fast in-memory step, so the fast step never has to wait on either.

#### Flow B — the read / price path (step 6): *"millions of people watch the price move"*

Trades are **outputs** of the engine, not part of matching. This flow carries the **100M reads/sec** and is deliberately a *separate system*, so read load can never slow down matching.

6. **⑥ Trade + book change → price publisher → fan-out layer.** Every trade and book change is **pushed** (not polled) to a **price publisher**, which fans it out through an **edge layer** (WebSocket/SSE + edge caching) that **absorbs the 100M reads/sec** and pushes live prices down to every subscriber. Slow-changing **company profile** data is served separately from a **read replica + cache** — the one place replicas actually fit, because it barely changes.

> **Why push, not pull:** a number that changes on *every* trade can't be served to 100M readers/sec from read replicas — the replicas would collapse. Instead you publish each change once and let the edge layer spread it out. This is the second core idea I never raised.

#### Flow C — the after-trade path (steps 7–8c): *"money and records settle, in the background"*

Once a trade is matched, the *bookkeeping* — paying the seller, updating who owns what, writing the audit log — is **asynchronous** and runs through Kafka. None of it is on the fast path, and all of it can retry safely.

7. **⑦ Send after-trade event → Kafka.** The engine sends one durable event per trade to **Kafka**, then moves on. Kafka provides **retry + dead-letter queue + wallet-credit fallback** for anything downstream that fails.
8. Three independent consumers each do one job:
   - **⑧a Settle & pay seller → clearing/settlement service** — moves the cash and shares between the two parties and credits the seller's wallet. Runs **off the fast path**, so a slow settlement never delays a trade; a failed payout retries via Kafka → dead-letter queue → wallet-credit (my interview answer, kept).
   - **⑧b Update holdings → portfolio store** — updates `user_id, symbol, qty, avg_price` so the buyer's portfolio shows the new shares.
   - **⑧c Record the trade → trade log** — writes the trade to a write-once log for **compliance and history**.

> **Why background:** settlement and records must be *correct and durable*, but not *instant*. Running them through Kafka keeps the fast path fast, and each consumer can fail, retry, and recover on its own without ever touching the engine.

**Resilience note (not a request flow):** the **log also replays into the engine after a crash**, and constantly feeds a **standby engine** that mirrors the main one and takes over if it fails — see [§5](#5-resilience--failover).

| Layer | Component | Store / note |
|---|---|---|
| Entry | **Order gateway** — login, risk/balance check, **reserve funds from wallet** (no outside payment on the fast path) | → Wallet |
| Wallet | **Wallet / balances** — `available` + `reserved`; pre-loaded, topped up separately | KV / RDBMS |
| Spine | **Sequencer** — stamps an ever-increasing `seq`, **writes to the log before matching** | → Log, → Engine |
| Spine | **Input log** — write-once, durable + **replayable**, copied ×3, feeds the standby | append-only log |
| **Core** | **Matching engine** — **in-memory order book per stock**, price-time priority, **one thread per stock**, split across machines by stock, **no disk/network on the fast path** | in-memory |
| **Core** | **Standby engine** — replays the same log, takes over on failure | in-memory |
| Read | **Price publisher** — pushes out trades + book changes | → Fan-out layer |
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

**Problem B — stay crash-safe without touching a database on the fast path.** The engine never writes to a database. Safety comes from **replaying a log** (this technique is called event sourcing):

```text
# BEFORE matching: the sequencer writes every incoming order to a replicated log.
seq = next_sequence()
journal.append(seq, order)          # copied x3; THIS is the durable record
feed_to_engine(seq, order)          # the engine reads the ordered stream

# RECOVERY / FAILOVER: replay the log.
#   The engine's state is fully decided by the log: replay seq 0..N -> the exact same book.
#   The standby engine constantly replays the same stream, so it is always warm and ready.
#   A crash loses nothing -> restart or standby replays from the last snapshot + the log's tail.
# TRADES are outputs: send them to the read layer (push) and to Kafka (after-trade),
#   both OFF the fast path.
```

| The hard problem | How the ideal design solves it |
|---|---|
| Two orders try to grab the same waiting order | **One thread per stock** — matching happens one at a time, so nothing can clash; no locks, no half-written reads |
| A "hot stock" overwhelms one machine | ~200 trades/sec/stock fits one book easily; **spread different stocks across machines**, never split one stock |
| A crash mid-match loses orders | **Log first, then match** + **replay**; the book is fully rebuildable from the log |
| Speed vs. durability | Durability is one **sequential append to a log**, not a slow random database write; matching stays in memory, in microseconds |
| 100M readers of a number that changes every trade | **Push it out through a fan-out layer**, not read replicas — trades stream out; readers subscribe |

### 5. Resilience & failover

- **Warm standby by replay** — the standby constantly reads the same log, so failover is instant and loses nothing; there's no leader election on the fast path itself.
- **The log is the source of truth** — copied ×3; occasional **snapshots of the book** keep replay time short (replay = latest snapshot + the log since then).
- **Reserve funds early, settle later** — because money is reserved when the order arrives, a settlement failure never blocks or reverses a match; **Kafka retry → dead-letter queue → wallet-credit** handles payout failures (my interview answer, kept).
- **The read layer can fall behind on its own** — if the fan-out layer lags, matching is unaffected and prices simply catch up. The two systems fail separately by design.

### 6. Data model — where the crux actually lives

The single most important insight: **the order book is an in-memory data structure, not a database table.** In the interview I modeled it as sorted lists in a database matched by a worker — the right idea in the wrong place.

| Store | Structure | Fields | Note |
|---|---|---|---|
| **Order book** (the core) | **in memory, per stock** — bids (high→low), asks (low→high), by price then time | waiting `order_id`, `price`, `qty`, `ts`, `user_id` | **NOT a table** — in memory, ~1 MB/stock, owned by one thread |
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
| **Reserve wallet funds, settle later** | Outside payment inside the trade path | Keeps slow outside calls off the microsecond path (the original flaw); a settlement failure never blocks a match |
| **Push prices through a fan-out layer** | Read replicas + cache | 100M reads/sec of a number that changes every trade is a push problem; replicas would collapse. Publish each change once and fan it out |
| **Spread stocks across machines, don't split one stock** | Batch or split a hot stock | One book can only run one at a time; ~200 trades/sec/stock needs no splitting. Batching adds delay, breaking the whole premise |
| **Consistency on writes, availability on reads** | One model for everything | Orders/matches need strong consistency + durability; prices/profiles can tolerate being a fraction of a second stale (my correct call, kept) |

## Takeaways to drill

1. **The matching engine *is* the interview — build it, don't just name it.** For a trading problem the core is an **in-memory order book per stock**, **price-time priority**, **one thread per stock**, and a **replicated log + replay** for safety. Landing on "a background worker over a database" is the miss. Drill this part cold, then **re-solve S10** — the fix that's already proven to work.
2. **Finish the clashing idea.** One thread per stock (reached on my own!) *is* the answer — but only if I then build the **lock-free in-memory match loop** on top of it. Naming the idea scored points; not building on it lost them.
3. **Keep slow outside calls, database writes, and locks off the fast path.** Putting an external payment in the trade path was a basic mistake. **Reserve now, settle later; log first, project later; push, don't poll.** For every step, ask: if this can be slow, does it belong on the fast path?
4. **Take every estimate to the decision it forces — and keep the numbers consistent.** `1M ÷ 5,000 ≈ 200/sec per stock` **removes the hot-stock fear**; `100M reads/sec` **forces a push layer**. Numbers that contradict each other and decide nothing (1000 vs 100 req/instance) score nothing.
5. **Put the core in the right place.** The order book lives **in memory**, not in a database table. When the key data structure clearly needs memory and a single owner, drawing it as a datastore is the tell that I didn't really understand the core.
6. **Huge read loads are a fan-out problem.** 100M reads/sec of a number that changes every trade → **a price publisher + edge push layer (WebSocket/SSE)**, kept separate from matching. Read replicas are only for slow-changing data.
7. **Bank the wins — they're senior instincts.** One thread per stock, the wallet fix, the Kafka failure handling, and the consistency split are real strengths that carried into a brand-new domain. The gap is **depth on the core**, not the fundamentals — which is exactly what a focused re-solve fixes.

→ Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
