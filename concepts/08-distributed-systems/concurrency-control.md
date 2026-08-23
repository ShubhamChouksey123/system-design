# Concurrency Control — making the write path correct

---

When two clients write the **same row at the same time**, who wins and how do you enforce it? This is **not** the [consistency-models](./consistency-models.md) question (that's *replication*: once written, when do replicas see it). This is **contention**: guarding a single hot record so a race can't corrupt it. It's the #1 recurring interview miss — the last-unit-in-stock race and the highest-bid race are the same problem, and the answer is always one of four strategies below.

## 1. The lost-update race (why you need any of this)

Two requests read `stock = 1`, both decide "OK to buy," both write `stock = 0` → **two buyers, one unit**. Read-modify-write without guarding is the bug. The fix is to make the check-and-write **one indivisible step**, or to remove the concurrency entirely.

## 2. The four strategies (the decision tree)

| Strategy | How | Best when | Hot-key behavior |
|---|---|---|---|
| **Pessimistic lock** (`SELECT … FOR UPDATE`) | Lock the row, then read-modify-write, then commit | High contention on a **short** transaction; simplest to reason about | **Serializes** the row, holds locks — a hot item bottlenecks, risk of lock waits/deadlock |
| **Optimistic / version CAS** | `UPDATE … SET v=v+1 WHERE id=? AND v=:read_v`; retry if 0 rows | **Low** contention (conflicts rare) | **Retry storms** under a burst — every loser re-reads and retries |
| **Atomic conditional update** | `UPDATE … SET x=:new WHERE id=? AND <invariant>`; check rows-affected | The invariant is expressible in **one SQL predicate** (stock>0, price<bid) | DB enforces it in **one statement** — no app-side read; still one hot row |
| **Single writer per partition** | Route all writes for a key to **one owner** (queue/actor by `id`); process sequentially | **Hot keys** — removes contention instead of fighting it | **No contention at all**; scales *across* keys, one key = one writer's throughput |

**Rule of thumb:** default to the **atomic conditional update** for RDBMS (cleanest, one round-trip); reach for a **single writer per partition** when one key is *hot* (a celebrity auction, a flash-sale SKU); use pessimistic locks only for multi-step transactions you can't collapse into one predicate; use optimistic CAS when conflicts are genuinely rare.

## 3. Source of truth vs. derived view

The authoritative write and the fast-read copies are **not the same store**. Commit to the durable source **first**, then project into derived views — never the reverse.

| Layer | Role | Example |
|---|---|---|
| **Durable log** (append-only) | source of truth; replay to rebuild | `bids` table, `orders`, an event log |
| **Current-state row** | latest value, overwritten | `auctions.current_price`, `inventory.stock` |
| **Derived projection** | fast read, rebuildable, best-effort | Redis **ZSET** leaderboard, cache key |

- Update order is **DB commit → ack → then ZSET/cache**. Projecting *before* the commit can advertise a value a rollback erased.
- Projections live outside the DB transaction → each is **best-effort with retry**; a short TTL + the live push (SSE) self-heal drift. See [Redis ZSET](../06-caching/redis-sorted-sets.md).

## 4. Idempotency & exactly-once

Networks retry; schedulers double-fire. Make the repeat **harmless**, because true "exactly-once delivery" doesn't exist — you get **at-least-once delivery + idempotent processing**.

- **Idempotency key** — client sends a unique key per intent; the server stores it and returns the *same* result on replay (never charges twice). Stripe's `Idempotency-Key` header is the canonical example.
- **Exactly-once effect on a scheduler** — a guarded state transition makes a double-fire a no-op:

```sql
-- Only the first worker to flip OPEN→CLOSING proceeds; the rest affect 0 rows.
UPDATE auctions SET status='CLOSING' WHERE id=:a AND status='OPEN';
-- if rows_affected == 0: another worker already closed it → return
```

- **Dedup on the consumer** — a unique constraint on `(event_id)` or a seen-set turns a redelivered message into a swallowed duplicate. See [message queue](../07-messaging-and-events/message-queue.md).

## 5. Worked examples (one per pattern)

**Last-unit checkout — atomic conditional update:**

```sql
UPDATE inventory SET stock = stock - 1 WHERE sku = :s AND stock > 0;
-- rows_affected == 1 → reserved it; == 0 → sold out, reject. The WHERE is the guard.
```

**Highest bid — atomic conditional update + durable log:**

```sql
BEGIN;
  UPDATE auctions SET current_price=:bid, top_bidder=:u WHERE id=:a AND current_price < :bid;
  -- rows_affected == 0 → not higher, reject the bid
  INSERT INTO bids(auction_id, bidder_id, amount) VALUES (:a,:u,:bid);  -- append-only truth
COMMIT;   -- then project to Redis ZSET + cache, publish to pub/sub
```

**Counter (likes / view count) — atomic increment, contention-tolerant:**

```
Redis:  INCR post:123:likes         # single-threaded, no read-modify-write race
SQL:    UPDATE posts SET likes = likes + 1 WHERE id = 123   # DB does the add
Hot counter? shard it: INCR post:123:likes:{0..9}, sum on read (fan-in)
```

## 6. In-the-room checklist

- Name the **hottest single row/key** and who writes it concurrently — *before* designing the mechanism.
- State the invariant as a **predicate** (`stock > 0`, `current_price < :bid`) → that's your atomic `UPDATE … WHERE`.
- If one key is hot, say **"single writer per partition"** and route by `id`.
- Separate **source of truth** (durable log) from **derived views** (ZSET/cache); commit first, project after.
- Any external side effect (charge, email) or scheduler → **idempotency key** / **guarded transition**.

## 7. Tips — Do / Don't

- **Do** let the database enforce the invariant in one statement; **don't** read-then-write in app code without a guard.
- **Do** check **rows-affected** — that's how you know the conditional actually applied.
- **Don't** keep authoritative state in **process memory** (an in-memory max-heap is lost on crash and diverges across N instances) — use a shared store + durable log.
- **Don't** claim "exactly-once delivery"; say **at-least-once + idempotent**.

## 8. One-Paragraph Summary (for quick revision)

**Concurrency control** guards a single contended record so a race can't corrupt it — distinct from replication *consistency*. Four strategies: **pessimistic lock** (`SELECT … FOR UPDATE`, serializes, simplest for multi-step txns), **optimistic/version CAS** (retry on conflict, great at low contention, retry-storms when hot), **atomic conditional update** (`UPDATE … WHERE <invariant>` + check rows-affected — the clean RDBMS default), and **single writer per partition** (route a key to one owner — removes contention for hot keys, scales across keys). Keep the **source of truth** in an append-only durable log, overwrite a **current-state row**, and treat caches/ZSETs as **best-effort derived projections** written *after* the DB commits. Make retries and double-firing schedulers safe with **idempotency keys** (Stripe-style) and **guarded state transitions** (`WHERE status='OPEN'`), since you get at-least-once delivery, not exactly-once. Worked reflexes: last-unit checkout and highest-bid are both `UPDATE … WHERE`, and hot counters shard the `INCR`.
