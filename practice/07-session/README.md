# Session 07 — Distributed API Rate Limiter (Stripe / Cloudflare style) · ⚠️ 6.0/10

> A scored, analyzed system-design mock. This was a **classic infrastructure problem** where the whole design lives in two hard details — **how you count concurrently** and **which windowing algorithm you pick** — and I got close to both without landing either. The strengths were real and process-level: I **self-corrected twice** (killed the `Update Tokens Job` for lazy window reset; introduced then correctly dropped consistent hashing once the state moved to a shared cache) and reasoned cleanly about the **availability-vs-accuracy** and **fail-open-vs-fail-closed** trade-offs. What held it to Lean-Hire-with-reservations is that the two crux problems went **unsolved**: I named the **fixed-window boundary burst** and the **read-modify-write race** but couldn't reach **atomic increments** (`INCR` / a Lua script) or **sliding-window / token-bucket** as the answers — and for a rate limiter, those *are* the design. The usual estimation-to-decision gap and a **stale diagram** (never updated after the design evolved) recur again.

| | |
|---|---|
| **Problem** | Design a distributed rate limiting system that protects APIs from abuse, ensures fair usage across clients, and stays high-performance |
| **Focus** | The counter as shared hot state: correct concurrent increment + a windowing algorithm that bounds burst |
| **Overall** | **6.0 / 10** — ⚠️ Borderline (Lean Hire, with reservations) — ▼ 0.5 vs S06's 6.5 |
| **Weakest areas** | Problem-Solving (5.0), Design (6.0), Scale & Trade-offs (6.0), Communication (6.0) |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |

## The problem

> Design a **distributed rate limiting system** that can **protect APIs from abuse** while ensuring **fair usage across different clients** and **maintaining high performance**.

Rate limiting looks like a CRUD-with-a-counter problem and is actually a **distributed-concurrency** problem wearing a small diagram. Every incoming request reads and mutates the *same* per-client counter, at peak QPS, across many stateless instances — so the entire design collapses to two questions: **(1) how do you increment that counter correctly when N instances race on it?** (answer: an *atomic* operation in the shared store, never read-modify-write in app code) and **(2) which counting algorithm do you use?** (fixed window is trivial but bursts 2× at boundaries; sliding-window-counter and token-bucket are what real limiters ship). Everything else — 429s, `Retry-After`, config, High Availability — is standard. The trap is designing the boxes and hand-waving the counter.

## Requirements & estimation

- **Functional** — each client may make a **max fixed number of requests** (e.g. 200) within a **rolling window** (e.g. 1 s); on breach, return **HTTP 429 Too Many Requests** + a **`Retry-After`** header and **block further requests** in that window. Clients identified by **client ID / user ID** (a "client" = anyone sharing a contract — an org or an individual).
- **Non-functional** — **high throughput · highly available · fault-tolerant · scalable · fast · "near accurate"** counts. The *near accurate* call was a genuinely good instinct: perfect per-request accuracy would demand coordination that kills latency, so approximate counting is the right trade.
- **Estimation** — 10M total clients · **5M DAU** (50%) · 1000 req/client/day → **~50k QPS average, ~100k QPS peak**; each instance ~1000 QPS → **~100 instances × 2 (failover) = ~200**.
  - **Gap:** the numbers stopped at *instance count*. The decisive figure was never computed — **counter memory**: 5M active clients × ~100 B ≈ **~500 MB**, which *fits in a single Redis node*. That number is the argument that the datastore is tiny and the whole problem is throughput + atomicity, not capacity. (Estimation-depth miss, recurring: S01/S04/S05/S06.)

![Requirements canvas — problem statement for a distributed rate limiter; functional requirements that each client may make a maximum fixed number of requests within a rolling fixed-size window, returning HTTP 429 and a Retry-After header and blocking new requests when the limit is reached; non-functional requirements of high throughput, high availability, fault tolerance, scalability, speed, and near-accurate per-client counts; an estimations block deriving 50k average QPS and 100k peak QPS from 10 million clients at 50 percent daily active and 1000 requests per client per day, sizing about 100 instances doubled to 200 for failover; and a partial schema noting client id, window start time, and total request](./diagrams/requirements.png)

## The design I produced

![Architecture canvas — a Clients box sends GET api and POST api requests to a combined API Gateway and Rate Limiting Service. The service reads total request count by client from a Cache as step one, falls back to reading from a Database only on a cache miss as step two, increments the total request count in the Cache as step three, and forwards allowed requests to a Backend Service as step four. The Database and Cache are drawn as separate cylinders on the right](./diagrams/architecture.png)

- **Clients → Rate Limiting Service** — every request carries a client/user ID; the service validates the client and looks up remaining quota.
- **Cache-first counter** — read the client's count from a **distributed cache**; on a **cache miss**, fall back to the **database**, then write back to cache. Increment the count in cache on each request; allowed requests forward to the **Backend Service**.
- **Lazy window reset (the good pivot):** started with an **`Update Tokens Job`** resetting every client's quota each second — realized that's *10M writes/second*, then redesigned to store **`(client_id, window_start_time, total_request)`** and **reset lazily**: on each request, if `now − window_start ≥ window`, start a fresh window. This **eliminated the background job entirely** — the session's best moment.
- **Same-client routing:** proposed **consistent hashing** to pin a client to one cache node / RL instance — then, once the RL logic merged into the API Gateway and the cache became the shared source of truth, **correctly dropped it** (any stateless instance can serve any client). A second clean self-correction.
- **Trade-offs stated well:** chose **availability + speed over strict accuracy** (accepts a race-induced overcount as "near accurate"); **fail-open vs fail-closed depends on the business** (block for banking/gov, allow for a learning platform); named the **fixed-window boundary burst** (up to 400 req across two adjacent 1-s windows).
- **Left unresolved:** the concurrent **read-modify-write race** (two instances both read 100, both write 101, truth is 102); a **real fix for the boundary burst**; **cache-DB sync**; and where **rate-limit rules/config** live.

## Scorecard

| Axis | S06 | **S07** | Δ |
|---|:--:|:--:|:--:|
| Requirements Gathering | 7.0 | **7.0** | — |
| Design Skills | 6.0 | **6.0** | — |
| Problem-Solving | 6.0 | **5.0** | ▼ 1.0 |
| Scalability & Trade-offs | 7.0 | **6.0** | ▼ 1.0 |
| Communication | 6.0 | **6.0** | — |
| **Overall** | 6.5 | **6.0** | ▼ 0.5 |

> The dip is concentrated in **Problem-Solving (▼1.0 → 5.0)**: on a problem whose *entire difficulty* is two well-known sub-problems, I identified both (race condition, boundary burst) but solved neither — no atomic `INCR`, no sliding window / token bucket. **Scale slipped (▼1.0)** because cache scaling stayed at "add more nodes," hot keys (a popular client hammering one shard) went unnamed, and the DB-fallback story was "hope the cache stays up." **Requirements and process instincts held** — the self-corrections are genuine design maturity — but this is a topic where *knowing the standard algorithms* is table stakes, and that knowledge gap is what the score reflects.

## What lost points — and the fix

| What I missed in the room | The answer a senior would give | Study |
|---|---|---|
| **The concurrent race went unsolved** — two instances read the same count and both write count+1; overcount under load, and a malicious client can *exploit* it | Never read-modify-write in app code. Do the increment **atomically in the store**: `INCR` (fixed window) or a **single Lua script** (token bucket / sliding window) that read-checks-and-writes in one round trip on the node holding the key. Atomicity — not locks — is the answer. | [Concurrency Control](../../concepts/08-distributed-systems/concurrency-control.md) |
| **No fix for the fixed-window boundary burst** — "make the window smaller" only shrinks it | Switch algorithm. **Sliding-window counter**: weight the previous window's count by the fraction still overlapping (`prev × overlap% + curr`) — smooth, ~2 counters/client, cheap. Or **token bucket**: tokens refill at a steady rate, bucket caps burst — the industry default (Stripe, AWS). | [Rate Limiter](../../concepts/08-distributed-systems/concurrency-control.md) |
| **Didn't reach the standard algorithms** — fixed window was the only tool | Know the four cold: **fixed window** (simple, boundary burst) · **sliding-window log** (exact, memory-heavy) · **sliding-window counter** (approx, cheap — the sweet spot) · **token / leaky bucket** (burst control / smoothing). Naming and choosing among these *is* the design. | [Concurrency Control](../../concepts/08-distributed-systems/concurrency-control.md) |
| **Cache-to-DB sync never defined** — and the DB doesn't belong on the hot path at all | Counters are **ephemeral** — they live in **Redis with a TTL** and don't need a durable DB behind them; the DB (or a config store) holds only **rate-limit rules**, not live counts. Removing the DB from the request path removes the "cache miss floods the DB" problem entirely. | [Caching](../../concepts/06-caching/caching.md) |
| **Cache scaling = "just add nodes"; hot keys unnamed** | Shard counters by `client_id`; a **hot client** (one key, huge QPS) can saturate a single shard — mitigate with **local pre-aggregation** at the edge (count locally, flush deltas) or a **dedicated shard**. Name the hot key before it's asked. | [Caching](../../concepts/06-caching/caching.md) |
| **No config / multi-tier rate limits** — one global rule | Rules are **data**, not code: a **config store** keyed by client · tier · endpoint, cached in memory with a short TTL and hot-reloaded. Enables per-endpoint and per-tier limits without a redeploy. | [Databases](../../concepts/05-databases-and-storage/databases-fundamentals.md) |
| **Diagram never updated as the design evolved** — still showed the deleted `Update Tokens Job` and a DB on the hot path | The diagram is the artifact the interviewer grades — **keep it live**: erase the killed job, redraw the counter store as the source of truth, separate the **allow / deny / check** flows. A stale diagram reads as "didn't follow my own redesign." | [Consistency Models](../../concepts/08-distributed-systems/consistency-models.md) |

## What went well

The process instincts were the strength this time — the ability to *evolve* a design under questioning is a genuine senior signal:

- **Two clean self-corrections** — killed the `Update Tokens Job` for **lazy window reset** (spotting the 10M-writes/s absurdity unprompted), and introduced then **dropped consistent hashing** once the shared cache made it unnecessary. Recognizing your own over-engineering and removing it is hard and valuable.
- **The "near accurate" trade-off, reasoned not guessed** — explicitly chose availability + speed over strict consistency, and understood *why* (coordination cost per request). That's the correct instinct for a rate limiter.
- **Fail-open vs fail-closed tied to business context** — block for banking/government, allow for a learning platform. A nuanced, senior answer.
- **Named the hard problems** — the boundary burst and the read-modify-write race were both surfaced correctly, even though the solutions didn't land. Seeing the problem is half of it.

---

## The ideal design

**The crux:** a rate limiter is a **shared-counter-under-contention** problem — the counter is a hot key hit on *every* request by *every* stateless instance, so the design reduces to **(1) an atomic increment in the shared store** (so concurrent requests can't lose updates) and **(2) an algorithm that bounds burst at window edges** (token bucket or sliding-window counter, not fixed window). The datastore is tiny (~500 MB); the difficulty is entirely throughput + atomicity. Everything else follows.

### 1. Ideal estimation (the numbers that pick the datastore and expose the hot key)

| Quantity | Assumption | Result | Decision it forces |
|---|---|---|---|
| Clients / DAU | 10M total · 50% active | **5M DAU** | key space is millions, not billions |
| Average QPS | 5M × 1000/day ÷ 10⁵ s | **~50k QPS** | in-memory store only; a DB can't sit on this path |
| Peak QPS | 2× average | **~100k QPS** | atomic op must be **O(1)**, single round trip |
| Counter memory | 5M clients × ~100 B | **~500 MB** | **fits one Redis node** — capacity is a non-issue; replicate for High Availability, shard for throughput |
| Edge instances | 100k ÷ ~1k QPS each, ×2 failover | **~200** | stateless tier behind an LB; scale horizontally |

> The number that reframes the problem: **~500 MB of counters.** It proves the store is trivially small, there's **no durable-DB requirement on the hot path**, and the real constraints are **atomic-op latency** and **hot-key throughput** — not storage.

### 2. Requirements — the ideal cut

- **Functional (in scope):** per-client quota over a rolling window; **429 + `Retry-After`** on breach; **multi-tier / per-endpoint limits** (free vs paid, cheap vs expensive endpoints); rules **configurable without redeploy**.
- **Argued *into* scope:** a **config store for rules** and **multi-tier limits** — a real limiter is never one global number, and rules-as-data is cheap to add. **Out:** billing, analytics dashboards, per-user ML abuse detection.
- **Non-functional (ranked):** **low added latency** (it's on every request — single-digit ms) → **high availability + fault tolerance** (a limiter outage must not take down the API) → **near-accurate counts** (approximate is fine; explicitly trade strict consistency away) → **horizontal scalability**.

### 3. Ideal architecture

The limiter lives **inside the edge tier** (API gateway / middleware), stateless and horizontally scaled. The only stateful component on the hot path is the **counter store** (Redis), hit with one **atomic** operation per request. A separate **config store** holds the rules, cached in memory.

![Ideal distributed rate limiter as a Mermaid flowchart. A client sends each request carrying a client id or API key into a stateless edge tier of API gateway instances with rate-limit middleware behind a load balancer, where any instance can handle any client. On every request the gateway performs a single atomic check-and-increment using a Lua script implementing token bucket or sliding window, routed by client id to the shard that owns that client. The counters live in a Redis cluster shown as the source of truth and split into two shards, shard 1 holding client ids that hash to slot A and shard 2 holding client ids that hash to slot B, giving horizontal throughput; each shard primary replicates to a replica with automatic failover for fault tolerance. The gateway also loads rate-limit rules from a config store keyed by client, tier, and endpoint, cached in memory with a short TTL. When the client is under its limit the gateway forwards the request to the backend service; when over the limit it returns 429 Too Many Requests with a Retry-After header to the client. If a shard goes down the gateway fails open or fails closed according to business policy](./diagrams/ideal-design.png)

| Layer | Component | Store |
|---|---|---|
| Edge | **API Gateway + rate-limit middleware** — stateless, any instance serves any client, behind an LB | — |
| Hot path | **atomic check-and-increment** per request (Lua: token bucket / sliding window) | **Redis cluster** (counters, sharded by client_id, replicated) |
| Config | rate-limit **rules** per client · tier · endpoint, cached in memory + short TTL | **Config store** (SQL / KV) |
| Allow | under limit → forward | → Backend Service |
| Deny | over limit → **429 + `Retry-After`** | → Client |
| Resilience | Redis node down → **fail-open or fail-closed** per policy | — |

### 4. The algorithm — the one component worth real depth

For a rate limiter, the counting algorithm *is* the domain. Know the five and their trade-offs cold — and, crucially, be able to **pick one and defend it**:

| Algorithm | How it works | Trade-off | Verdict for this design |
|---|---|---|:--|
| **Fixed window** | one counter per `(client, window)`; `INCR`, reset each window | Simplest, but **~2× burst at boundaries** (400 req across two adjacent 1-s windows) | ❌ the boundary burst is an abuse vector — unacceptable for an abuse-protection tool |
| **Sliding-window log** | store a timestamp per request, count those inside the window | **Exact**, but O(requests) memory — too heavy at scale | ❌ one entry per request blows the ~500 MB budget at 100k QPS |
| **Sliding-window counter** | weight prev window by overlap fraction: `prev × overlap% + curr` | **Approximate but smooth**, ~2 counters/client | ✅ strong runner-up — pick it if the business must **forbid bursts** |
| **Token bucket** | tokens refill at a fixed rate; each request spends one; bucket caps burst | **Allows controlled bursts**, industry default (Stripe, AWS, Cloudflare) | ✅✅ **chosen** — bursts-but-bounded matches "fair usage without blocking legit spikes" |
| **Leaky bucket** | requests queue and drain at a fixed rate | **Smooths output**, adds queueing latency | ❌ it *queues* to pace a downstream; a limiter should **reject** (429), not buffer |

**Verdict — use token bucket.** After ruling out fixed window (boundary burst), sliding-window log (memory), and leaky bucket (queues instead of rejecting), the choice is token bucket vs. sliding-window counter — both defensible. Token bucket wins as the default because real API traffic is **bursty but legitimate**: a client idle for a while then firing 10 requests has *saved up tokens* and should pass, while one sustaining 1000 req/s is stopped. That is exactly "protect from abuse **while ensuring fair usage**." Switch to **sliding-window counter** only when bursts must be strictly forbidden (e.g. a fragile downstream that can't absorb spikes).

**The concurrency fix that makes any of them correct:** do the read-check-write as **one atomic operation on the node that owns the key** — `INCR` + `EXPIRE` for fixed window, or a **Lua script** for token bucket / sliding window (Redis runs it atomically, single round trip). This dissolves the read-modify-write race *and* the malicious-concurrency exploit — no locks, no transactions, no added latency.

Concretely, the **fixed-window** check on each request is just this — the whole race disappears because `INCR` is executed indivisibly *on the Redis server*, so N racing instances can never read the same value and both write back `+1`:

```text
# Indivisible increment executed on the Redis server — key is rl:{client_id}:{window}
current_count = INCR "rl:user_123:1700000000"

# First hit in this window creates the key at 1 → attach the TTL so it self-expires
IF current_count == 1 THEN
    EXPIRE "rl:user_123:1700000000" 60
END IF

IF current_count > 100 THEN
    RETURN 429 Too Many Requests   # + Retry-After
END IF
# else: under limit → forward to backend
```

> **Why the `IF … == 1` and not a plain `EXPIRE` every time:** you only want to stamp the TTL when the window *starts*, so a busy client can't keep pushing the expiry forward and never reset. The one subtlety: `INCR` and `EXPIRE` are two commands, so if the process dies between them the key could live forever without a TTL — in production fold both into a **single Lua script** (or `SET … EX` semantics) so the create-and-expire is itself atomic. Token bucket / sliding-window counter follow the same shape, just with more state per key (`tokens, last_refill`), which is *why* they need a Lua script rather than a bare `INCR`.

#### Token bucket — the chosen algorithm, end to end

The bucket holds up to **`capacity`** tokens; each allowed request **spends one**; tokens **refill at a steady `rate`** (e.g. 100/s). `capacity` caps the *instantaneous* burst, `rate` caps the *sustained* average. The refill is computed **lazily on each request** from elapsed time — there is **no background job** topping up 5M buckets every second (the trap that would be 5M writes/s).

![Token bucket algorithm as a flowchart. A request carrying a client id enters a single atomic Lua script that runs on the Redis shard owning that client id. Inside the script the bucket state — tokens and last refill timestamp — is loaded, and on a client's first sighting the bucket starts full at capacity. The script then lazily refills the bucket with no background job by setting tokens to the minimum of capacity and the current tokens plus elapsed time times the refill rate, and updates last refill to now. It then checks whether tokens is at least one; if yes it spends a token by decrementing, saves the new tokens and last refill and sets a TTL, and the request is forwarded to the backend as under limit; if no the request is rejected over limit with a 429 and a Retry-After header](./diagrams/token-bucket.png)

The entire load → refill → check → spend runs as **one atomic Lua script on the shard owning the key** (the whole yellow box). Concise pseudo-code:

```text
-- KEYS[1] = rl:{client_id}   ARGV = now, rate (tokens/sec), capacity, requested (=1)
-- The whole block executes atomically on the node that owns the key
tokens, last_refill = HMGET rl:user_123 tokens last_refill

IF tokens == nil THEN                       # first sighting → start full
    tokens = capacity
    last_refill = now
END IF

# LAZY REFILL: credit the tokens accrued since the last request, capped at capacity
tokens = MIN(capacity, tokens + (now - last_refill) * rate)
last_refill = now

IF tokens >= requested THEN
    tokens = tokens - requested
    HMSET  rl:user_123 tokens=tokens last_refill=last_refill
    EXPIRE rl:user_123 <ttl>                # idle buckets self-evict → memory ∝ active clients
    RETURN allow                            # → forward to backend
ELSE
    HMSET  rl:user_123 tokens=tokens last_refill=last_refill
    EXPIRE rl:user_123 <ttl>
    RETURN 429                              # + Retry-After
END IF
```

**How token bucket kills both hard problems the session left unsolved:**

| Problem | Why it happens | How token bucket solves it |
|---|---|---|
| **Race condition** (concurrent read-modify-write) | N instances read the same `tokens`, all decrement, all write back → lost updates, overcount, exploitable | The whole read → refill → check → decrement → write is **one atomic Lua script**. Redis executes it single-threaded on the key's owning node, so concurrent requests are **serialized** — no lost updates, no locks, one round trip. |
| **Boundary burst** (fixed window's 2× spike) | Fixed window resets the counter *instantly* at the edge, so 100 req at `0.999s` + 100 at `1.001s` = 200 in ~2 ms | Token bucket **has no window edge** — tokens refill *continuously* at `rate`, so a full new allowance never appears at an instant. `capacity` bounds the max burst, `rate` bounds the sustained average. The burst can't exist because there's no boundary to exploit. |

> Naming **token bucket** *and* **atomic `INCR`/Lua** is the senior signal the session missed — it's the difference between "a box called Cache" and a limiter that actually enforces the limit under contention.

### 5. Resilience & fair usage

- **Fail-open vs fail-closed** on counter-store outage — a business decision: **fail-open** (allow, prioritize availability) for most APIs; **fail-closed** (block, prioritize protection) for security-critical ones. Say which and why.
- **Hot key** — one very active client is a single hot shard; mitigate with **local pre-aggregation** (edge counts locally, periodically flushes deltas to Redis — trading a little accuracy for a lot of throughput) or a dedicated shard.
- **High Availability** — Redis with **replication + automatic failover** (or a managed service); the counter is ephemeral, so a lost replica costs at most one window of accuracy, never durability.
- **Fairness** — per-client keys give isolation by default; tiers and per-endpoint limits prevent one expensive endpoint from starving others.

### 6. Data model

The bucket state is an **ephemeral cache entry**, not a durable row — that's the key modeling insight. Only the **rules** are persisted.

| Store | Key / structure | Fields | Note |
|---|---|---|---|
| **Redis** (bucket — the crux) | `rl:{client_id}` (add `:{endpoint}` for per-endpoint limits) as a **Redis Hash** | `tokens` (fractional), `last_refill` (unix ts) + **TTL** | **the crux "table" — the two-field token-bucket state; ephemeral, mutated by one atomic Lua script, TTL'd so idle buckets self-evict; never in a durable DB** |
| Config (rules) | `rate_limit_rules` | client_id / tier / endpoint → **`capacity`** (max burst), **`refill_rate`** (tokens/s), algorithm | the limit *as data*; cached in memory + short TTL, hot-reloadable |
| Config (clients) | `clients` | client_id, api_key, tier | identity + tier lookup |

**Why the key has no `:{window}` suffix.** Fixed window needs a discrete bucket per time slice — `rl:{client_id}:{window}` → an integer `count` + TTL — because the count is meaningless once the slice ends. Token bucket is **continuous**: the same two fields (`tokens`, `last_refill`) live under one stable key and are re-derived from elapsed time on every request, so there's no window to encode. `tokens` is **fractional** (a refill of `elapsed × rate` rarely lands on a whole number) — store it as a float, or scale tokens ×1000 and keep integers if you prefer exactness.

### 7. Design trade-offs

| Decision | Alternatives | Why this choice (and when to switch) |
|---|---|---|
| **Atomic `INCR` / Lua in Redis** | App-side read-modify-write; distributed lock; DB transaction | Locks/transactions add latency on every request and still race across instances; one atomic op is O(1) and correct. **No reason to switch** |
| **Token bucket / sliding-window counter** | Fixed window | Fixed window bursts 2× at boundaries; these bound burst cheaply. Use **fixed window** only when a rough limit is acceptable and simplicity wins |
| **Counters in Redis only (no durable DB)** | Cache-aside over a DB (the session's design) | Counters are ephemeral; a DB on the hot path can't take 100k QPS and adds a cache-miss flood risk. Keep the DB for **rules only** |
| **Limiter in the edge/gateway tier** | A separate rate-limiting service | Co-locating removes a network hop on every request; a standalone service only earns its keep when many gateways must share bespoke logic |
| **Near-accurate (AP) counting** | Strictly consistent (CP) counting | Per-request coordination kills latency; a small overcount is acceptable. **Switch toward CP** only for hard quotas (e.g. paid API billing) |
| **Fail-open on outage** | Fail-closed | Availability-first for general APIs; **fail-closed** for security/abuse-critical or billing paths |
| **Stateless edge, any-instance-any-client** | Consistent-hash clients to instances | Shared Redis is the source of truth, so pinning adds fragility (instance down = clients stranded) for no gain. The session correctly reached this |

## Takeaways to drill

1. **A rate limiter = atomic counter + windowing algorithm. Memorize both answers.** The race is solved by **atomic `INCR` / a Lua script in the store**, never app-side read-modify-write; the boundary burst is solved by **token bucket or sliding-window counter**, not a smaller fixed window. On this topic, knowing the standard answers is table stakes.
2. **Learn the four algorithms cold** — fixed window · sliding-window log · sliding-window counter · token/leaky bucket — with the one-line trade-off for each. Being able to *choose* among them is the design.
3. **Counters are ephemeral — keep the durable DB off the hot path.** Live counts live in Redis with a TTL; the DB holds only rules. This deletes the cache-miss-floods-the-DB problem the session wrestled with.
4. **Compute the memory number, not just the instance count.** ~500 MB of counters is the figure that reframes the whole problem as throughput-not-storage — estimation must reach the number that *decides* the datastore.
5. **Keep the diagram live as the design evolves.** After killing the `Update Tokens Job`, the canvas still showed it — redraw on every pivot; the diagram is a graded artifact. (Diagram-hygiene miss, now recurring across sessions.)
6. **When you name a hard problem, push to the solution.** Surfacing the race and the boundary burst is good; leaving both unsolved is where Problem-Solving points went. Practice pushing one level past "here's the issue" to "here's how I fix it."

→ Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
