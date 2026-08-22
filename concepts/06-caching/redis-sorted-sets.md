# Redis Sorted Sets (ZSET)

---

The Redis data structure that shows up in almost every "rank / top-N / leaderboard / live-highest" design. A **sorted set** holds unique **members**, each tagged with a numeric **score**, and keeps them **permanently ordered by score** — so "who's #1?" and "top 10?" are cheap at any scale. Read [Redis & Memcached](./redis-and-memcached.md) first for the cache fundamentals; this is the deep-dive its leaderboard bullet points to.

## 1. What it is

A `ZSET` is a set (members are unique) plus a **float score per member**, maintained in sorted order by a **skip list + hash map** internally. That dual structure is why it can do both *"rank of member X"* and *"members in score range"* in `O(log n)`.

| Property | Behaviour |
|---|---|
| Members | Unique strings (like a `SET`) |
| Score | A `double` per member — the sort key |
| Order | Always sorted by score (ties broken lexicographically by member) |
| Re-score | `ZADD` on an existing member just **moves** it — no duplicate |

## 2. Core commands

| Command | Does | Cost |
|---|---|---|
| `ZADD key score member` | Insert / update a member's score | `O(log n)` |
| `ZINCRBY key delta member` | Atomically bump a score (counters!) | `O(log n)` |
| `ZSCORE key member` | Read one member's score | `O(1)` |
| `ZRANK` / `ZREVRANK` | Position of a member (asc / desc) | `O(log n)` |
| `ZREVRANGE key 0 9 WITHSCORES` | **Top-10** by score, highest first | `O(log n + k)` |
| `ZRANGEBYSCORE key min max` | Members in a score window | `O(log n + k)` |
| `ZREMRANGEBYRANK` / `BYSCORE` | Trim the set (keep top-N, drop old) | `O(log n + k)` |
| `ZCARD` / `ZCOUNT` | Size / count in a range | `O(1)` / `O(log n)` |

**Atomicity matters:** `ZADD` and `ZINCRBY` are single-threaded Redis commands, so concurrent updates to the same leaderboard serialize cleanly — no read-modify-write race.

## 3. When to reach for a ZSET

| Pattern | Score = | How |
|---|---|---|
| **Leaderboard / ranking** | points, votes, rating | `ZINCRBY` on score change; `ZREVRANGE 0 9` for the board |
| **Live highest bid** (auction) | current bid amount | `ZADD` per bid; `ZREVRANGE 0 0` = current winner |
| **Sliding-window rate limit** | request timestamp | `ZADD ts`, `ZREMRANGEBYSCORE 0 (now-window)`, `ZCARD` vs limit |
| **Priority queue / delay queue** | priority or run-at time | `ZRANGEBYSCORE -inf now` to pop what's due |
| **Recent / trending items** | timestamp or decayed score | `ZREVRANGEBYSCORE`, trim old with `ZREMRANGEBYRANK` |

## 4. Design notes & gotchas

- **It's a derived view, not the source of truth.** In a write path (e.g. auction bids), commit to the durable DB first, then project into the ZSET — updating the ZSET *before* the commit risks showing a value the DB later rolled back. Best-effort with retry; rebuild from the DB if it drifts.
- **Cap unbounded sets.** Leaderboards and time-series grow forever — trim with `ZREMRANGEBYRANK key 0 -(N+1)` (keep top-N) or `ZREMRANGEBYSCORE` (drop old) so memory stays bounded.
- **One key = one shard.** A single ZSET lives on one node, so a global leaderboard is a **hot key**. Options: shard by segment (per-region/per-day boards, merge on read), or accept the hot key if throughput fits one node.
- **Ranks are integers, scores are floats.** Equal scores tie-break by member name — fine for leaderboards, but pack a timestamp into the score (or a sub-score) when you need stable "first to reach N wins" ordering.
- **`WITHSCORES`** returns score alongside member — use it so the client isn't doing N follow-up `ZSCORE` calls.

## 5. Real-world usage

- **Gaming / social leaderboards** — the canonical use; `ZINCRBY` per event, `ZREVRANGE` for the board, per-period keys (`board:2026-08`) for daily/weekly resets.
- **Auction "current highest"** — see the [S04 auction design](../../practice/04-session/README.md); the ZSET is the live-winner projection behind the durable bids log.
- **API rate limiting** — sliding-window log per user key, far more accurate than a fixed-window counter.
- **Job schedulers** — score = run-at epoch; a worker polls `ZRANGEBYSCORE -inf now` to claim due jobs (a lightweight [delay queue](../07-messaging-and-events/message-queue.md)).

## 6. One-Paragraph Summary (for quick revision)

A **Redis Sorted Set (ZSET)** is a set of unique members each carrying a numeric **score**, kept **permanently ordered by score** via an internal skip-list + hash-map — giving `O(log n)` inserts/rank lookups and `O(log n + k)` top-N / range reads. `ZADD` and `ZINCRBY` update scores **atomically** (single-threaded Redis), so concurrent updates to the same board serialize without a read-modify-write race. It's the default tool for **leaderboards, live-highest values (auctions), sliding-window rate limiting, priority/delay queues, and trending/recent lists** — score being points, a bid amount, a timestamp, or a priority. Treat it as a **derived view over a durable store** (project *after* the DB commits, rebuild on drift), **cap growth** by trimming with `ZREMRANGEBYRANK`/`BYSCORE`, and remember a single ZSET is **one key on one node** — a global board is a hot key you shard by segment or accept within one node's throughput.
