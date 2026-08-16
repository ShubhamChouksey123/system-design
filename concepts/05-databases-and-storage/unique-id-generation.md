# Unique ID Generation — Snowflake, UUID

---

How do you generate **unique IDs** for billions of rows across **many machines** with no collisions and no central bottleneck? A single DB's `AUTO_INCREMENT` breaks once you [shard](./sharding-and-partitioning.md) — there's no one counter. This is a classic interview sub-problem (it sank [session 01's](../../practice/01-session/README.md) key-generation answer).

## 1. What a good distributed ID needs

- **Unique** — no collisions, ever, across all nodes.
- **Roughly time-sortable (k-sorted)** — IDs increase over time, so they append to the end of a B-tree index (good **write locality**) and support "newest first" without a separate timestamp column.
- **Compact** — ideally **64-bit** (fits a `BIGINT`, half the size of a 128-bit UUID).
- **High throughput, no coordination** — generated locally without a network round-trip or a **single point of failure**.
- **Sometimes: non-guessable** — sequential IDs let attackers enumerate your data (a session-01 miss). Public-facing IDs may need randomness.

No single scheme wins all of these — you trade among them.

## 2. The main approaches

| Approach | How | Pros | Cons |
|---|---|---|---|
| **DB auto-increment** | one DB hands out `1,2,3…` | simple, sorted, compact | **SPOF + bottleneck**, doesn't shard, **guessable** |
| **UUID v4** | 122 random bits | no coordination, collision-safe | **128-bit**, **not sortable** → index fragmentation |
| **UUID v7** | 48-bit time + random | no coordination, **time-sortable** | still 128-bit |
| **Ticket / segment server** | DB hands out **ranges** (e.g. 1000 IDs) per node | few DB hits, compact | needs the DB; ranges lost on crash |
| **Snowflake** | time + node + sequence in 64 bits | **64-bit, sorted, no coordination** | needs unique node IDs + **clock sync** |

## 3. Snowflake IDs (the interview favorite)

Twitter's **Snowflake** packs a unique, time-sortable ID into a single **64-bit** integer, generated **locally** on each node:

```
64-bit Snowflake ID
┌─┬─────────────────────────────┬────────────┬─────────────┐
│0│   timestamp — 41 bits (ms)  │ node — 10  │ sequence 12 │
└─┴─────────────────────────────┴────────────┴─────────────┘
 sign     ~69 yrs from a custom     1024 nodes  4096 ids per
 bit      epoch                                 ms per node
```

- **Timestamp first** → IDs are **globally time-ordered** (sortable, great index locality).
- **Node ID** → each machine is unique, so no two nodes collide.
- **Sequence** → up to **4096 IDs per millisecond per node**; rolls over within the same ms.
- **The catch — clock skew:** if a node's clock moves **backward** (NTP correction), it could reissue timestamps. Snowflake refuses to generate until the clock catches up. Nodes need reasonably synced clocks.

Variants: **Sonyflake**, Instagram's Postgres scheme (shard ID in the bits), Discord/Twitter snowflakes.

## 4. UUIDs — know v4 vs v7

- **UUID v4** — 122 random bits. Collision probability is negligible and it needs **zero coordination**, but it's **random**, so inserts scatter across a B-tree index → **page splits, poor cache locality** on large tables.
- **UUID v7** (modern) — a **48-bit Unix-ms timestamp** prefix + randomness → **time-ordered**, fixing v4's index problem while keeping decentralization. **Prefer v7** for new systems that want UUIDs.
- All UUIDs are **128-bit** (2× a Snowflake), so they cost more storage/index space.

## 5. When to use what

- **Snowflake / segment server** → you need **compact 64-bit, sortable** IDs at scale (feeds, tweets, orders) and can manage node IDs / clocks.
- **UUID v7** → you want **fully decentralized** generation (clients/edge, offline-first) and can spend 128 bits.
- **UUID v4** → only when unordered randomness is fine or **unpredictability** is the point.
- **Public short IDs** (URL shortener) → generate a number (counter/Snowflake) then **base62-encode** it for a short slug; use randomness/hashing if guessability is a concern.

## 6. Real-world technologies

| System | ID scheme |
|---|---|
| **Twitter / Discord** | Snowflake (64-bit time-ordered) |
| **Instagram** | Postgres `stored procedure`: timestamp + shard ID + sequence |
| **MongoDB** | **ObjectId** — 12 bytes: timestamp + machine + counter |
| **Stripe** | prefixed random IDs (`cus_…`, `ch_…`) — non-guessable |
| **Modern apps** | **UUID v7** / **ULID** (both time-sortable) |

## 7. One-Paragraph Summary (for quick revision)

At scale a single DB `AUTO_INCREMENT` can't issue IDs — it's a bottleneck and doesn't shard — so you need **distributed** ID generation that's **unique, compact, roughly time-sortable, and coordination-free**. **Snowflake** is the go-to: a **64-bit** integer = **41-bit timestamp + 10-bit node ID + 12-bit sequence**, generated locally, globally time-ordered (great B-tree write locality), giving ~4096 IDs/ms/node — its risk is **clock skew**. **UUIDs** need no coordination at all but are **128-bit**; **v4** is random (unsortable → index fragmentation) while **v7** adds a time prefix so it's ordered (**prefer v7**). Other options: a **ticket/segment server** handing out ID ranges, and MongoDB's **ObjectId**. Sortability buys index performance and "newest-first" ordering; when IDs are public, weigh **guessability** (sequential = enumerable) and reach for randomness or **base62** of a generated number (the URL-shortener pattern).
