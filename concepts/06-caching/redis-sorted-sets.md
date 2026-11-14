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
| **Leaderboard / ranking** | points, votes, rating | `ZINCRBY` on score change; `ZREVRANGE 0 9` for the board; `ZREVRANK` for one user (see section 4) |
| **Live highest bid** (auction) | current bid amount | `ZADD` per bid; `ZREVRANGE 0 0` = current winner |
| **Sliding-window rate limit** | request timestamp | `ZADD ts`, `ZREMRANGEBYSCORE 0 (now-window)`, `ZCARD` vs limit |
| **Priority queue / delay queue** | priority or run-at time | `ZRANGEBYSCORE -inf now` to pop what's due |
| **Recent / trending items** | timestamp or decayed score | `ZREVRANGEBYSCORE`, trim old with `ZREMRANGEBYRANK` |

## 4. Example — game leaderboard

**Scenario:** each time a user wins a game, their score goes up by 1. Show the top 10 and any user's rank.

**Syntax** (`<key>` is the leaderboard name, `<member>` is the user):

| Command | Syntax |
|---|---|
| Add points | `ZINCRBY <key> <increment> <member>` |
| Top N | `ZREVRANGE <key> <start> <stop> [WITHSCORES]` |
| Rank | `ZREVRANK <key> <member>` |
| Score | `ZSCORE <key> <member>` |

Your form is correct. The order is **key, increment, member**. The increment can be negative (`-1`) or a decimal. In `ZADD`, the score also comes **before** the member: `ZADD <key> <score> <member>`.

| Step | Command | Result |
|---|---|---|
| A win. `ZINCRBY` **creates** a new user with score 1, or adds 1 to an existing user. | `ZINCRBY leaderboard 1 alice` | `"1"` (new user) |
| Same user wins again | `ZINCRBY leaderboard 1 alice` | `"2"` |
| Top 10, highest first | `ZREVRANGE leaderboard 0 9 WITHSCORES` | `alice 3, bob 2, carol 1` (after more wins) |
| Rank of one user | `ZREVRANK leaderboard bob` | `1` |
| Score of one user | `ZSCORE leaderboard bob` | `"2"` |

```
ZINCRBY leaderboard 1 alice          # alice wins  -> 1
ZINCRBY leaderboard 1 bob            # bob wins    -> 1
ZINCRBY leaderboard 1 alice          # alice wins  -> 2
ZINCRBY leaderboard 1 carol          # carol wins  -> 1
ZINCRBY leaderboard 1 alice          # alice wins  -> 3
ZINCRBY leaderboard 1 bob            # bob wins    -> 2

ZREVRANGE leaderboard 0 9 WITHSCORES # 1) alice 3  2) bob 2  3) carol 1
ZREVRANK leaderboard bob             # 1   (0-based: show rank 2 to the user)
ZREVRANK leaderboard dave            # nil (user has no wins yet)
```

- **No "add user" step.** `ZINCRBY` on a missing member starts it at 0, then adds the delta.
- **`ZREV...` = highest score first.** `ZREVRANGE 0 9` is the top 10. `ZREVRANK` gives the position of one user (**0 = first place**).
- **Cost:** each win and each rank lookup is `O(log n)`. The top 10 is `O(log n + 10)`.
- **Atomic:** two wins at the same time both count. No read-modify-write race.

## 5. Design notes & gotchas

- **It's a derived view, not the source of truth.** In a write path (e.g. auction bids), commit to the durable DB first, then project into the ZSET — updating the ZSET *before* the commit risks showing a value the DB later rolled back. Best-effort with retry; rebuild from the DB if it drifts.
- **Cap unbounded sets.** Leaderboards and time-series grow forever — trim with `ZREMRANGEBYRANK key 0 -(N+1)` (keep top-N) or `ZREMRANGEBYSCORE` (drop old) so memory stays bounded.
- **One key = one shard.** A single ZSET lives on one node, so a global leaderboard is a **hot key**. Options: shard by segment (per-region/per-day boards, merge on read), or accept the hot key if throughput fits one node.
- **Ranks are integers, scores are floats.** Equal scores tie-break by member name — fine for leaderboards, but pack a timestamp into the score (or a sub-score) when you need stable "first to reach N wins" ordering.
- **`WITHSCORES`** returns score alongside member — use it so the client isn't doing N follow-up `ZSCORE` calls.

## 6. Real-world usage

- **Gaming / social leaderboards** — the canonical use; `ZINCRBY` per event, `ZREVRANGE` for the board, per-period keys (`board:2026-08`) for daily/weekly resets.
- **Auction "current highest"** — see the [S04 auction design](../../practice/04-session/README.md); the ZSET is the live-winner projection behind the durable bids log.
- **API rate limiting** — sliding-window log per user key, far more accurate than a fixed-window counter.
- **Job schedulers** — score = run-at epoch; a worker polls `ZRANGEBYSCORE -inf now` to claim due jobs (a lightweight [delay queue](../07-messaging-and-events/message-queue.md)).

## 7. One-Paragraph Summary (for quick revision)

A **Redis Sorted Set (ZSET)** is a set of unique members each carrying a numeric **score**, kept **permanently ordered by score** via an internal skip-list + hash-map — giving `O(log n)` inserts/rank lookups and `O(log n + k)` top-N / range reads. `ZADD` and `ZINCRBY` update scores **atomically** (single-threaded Redis), so concurrent updates to the same board serialize without a read-modify-write race. It's the default tool for **leaderboards, live-highest values (auctions), sliding-window rate limiting, priority/delay queues, and trending/recent lists** — score being points, a bid amount, a timestamp, or a priority. Treat it as a **derived view over a durable store** (project *after* the DB commits, rebuild on drift), **cap growth** by trimming with `ZREMRANGEBYRANK`/`BYSCORE`, and remember a single ZSET is **one key on one node** — a global board is a hot key you shard by segment or accept within one node's throughput.
