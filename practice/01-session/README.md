# Session 01 — Design a URL Shortener (bit.ly / TinyURL) · ⚠️ 5.9/10

> A scored, analyzed system-design mock interview: the problem, the design I produced, the interviewer's scorecard, and — most usefully — **exactly which gaps cost points and how to close them.**

| | |
|---|---|
| **Problem** | Design a URL shortening service (bit.ly / TinyURL) |
| **Focus** | read-heavy key-value store + click analytics, high availability, low-latency redirects |
| **Overall** | **5.9 / 10** — ⚠️ Borderline |
| **Weakest axes** | Communication (5.5), Scale & Trade-offs (5.5) |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |

## The problem

> Design a URL shortening service like bit.ly or TinyURL that can handle **billions of URLs**, provide **analytics**, and ensure **high availability and low latency for redirects**.

## Requirements I scoped

- **Functional:** `createShortUrl(longUrl) → shortUrl` and `resolve(shortUrl) → longUrl`. Analytics: click counts, share of URLs actually used, cleanup of stale URLs.
- **Non-functional:** high availability, low read latency (p95), fault tolerance.
- **Miss:** analytics was named in the prompt but explored late and thinly — it should have been a first-class requirement from the start.

## Back-of-the-envelope estimation

- ~1B URLs/year ÷ 365 days/year ÷ ~10⁵ s/day → **~27 writes/sec**.
- Assumed **100:1 read:write** → **~2,700 reads/sec**. → confirms this is a **read-heavy** system, so caching and read replicas drive the design.

## The design I produced

![URL shortener architecture — client to API gateway to service instances, cache-aside Redis, write DB with an async read replica, and an async queue feeding analytics](./diagrams/url-shortener-architecture.png)

- **Write path:** `Client → API Gateway → URL Shortener Service → persist mapping → return shortUrl`. Key = the **DB-generated ID** (chosen to sidestep hash collisions).
- **Read path:** service checks **Redis (cache-aside)** first; on miss, reads the **read replica**, populates the cache, returns.
- **Availability:** write DB **primary → read replica** with **leader-election failover** (a replica is promoted if the primary dies).
- **Analytics:** redirects **emit click events to an async queue**; a separate consumer aggregates them — keeping analytics off the latency-critical redirect path.

## Scorecard

| Axis | Score |
|---|:--:|
| Requirements Gathering | 6.0 |
| Design Skills | 6.0 |
| Problem-Solving | 6.5 |
| Scalability & Trade-offs | 5.5 |
| Communication | 5.5 |
| **Overall** | **5.9** |

## What lost points — and the fix

| Gap in the room | The senior answer | Study |
|---|---|---|
| **Key generation stayed shallow** — hashing, hand-waved collisions ("keep the rate low"); missed that sequential DB IDs are **guessable** | Compare hashing+collision handling vs **base62 of a counter** vs **pre-generated key pool**; call out predictable-ID **security** risk | *(todo: unique ID generation)* |
| **Wrong redirect status code** — answered 202/200/404 | **3xx** — **301** (permanent, cacheable) vs **302** (temporary, better for analytics) | [HTTP](../../concepts/04-apis/http.md) |
| **Consistent hashing needed heavy prompting** — went vertical-first for the cache | Reach for **consistent hashing** directly to shard the distributed cache/DB | [Consistent Hashing](../../concepts/03-networking-and-delivery/load-balancing-and-consistent-hashing.md) · [Sharding](../../concepts/05-databases-and-storage/sharding-and-partitioning.md) |
| **Data model ignored analytics** | Add click count, user-agent, referrer, timestamp — **design the schema for the use cases** | [Databases](../../concepts/05-databases-and-storage/databases-fundamentals.md) |
| **No cache eviction story** | Know **LRU/LFU + TTL** and invalidation for expired URLs | [Caching](../../concepts/06-caching/caching.md) |

## What went well

Systematic functional-requirements breakdown · clean read/write throughput math · solid grasp of read replicas, cache-aside, and DB failover · async analytics to protect redirect latency · sound reasoning about the replication-lag trade-off.

---

## The ideal design

**The crux:** a URL shortener is a **key-generation-under-concurrency** problem wearing a caching problem's clothes — the write path needs a globally unique, non-guessable key produced by many concurrent instances with **zero coordination** (no shared lock, no collision-retry loop), and once that's solved the rest is a textbook 100:1 read-heavy system that caching and replicas handle on their own.

### Ideal estimation (decision-tied)

| Number | Value | Decision it forces |
|---|---|---|
| Write throughput | 1B URLs/yr ÷ 365 ÷ 10⁵ s/day ≈ **~27 writes/sec avg**, ×2 → **~55/sec peak** | Trivial write volume — no need to shard the write path yet; the difficulty is never throughput, it's correctness of key generation under concurrency |
| Read throughput | 100:1 read:write → **~2,700 reads/sec avg**, ×2 → **~5,500/sec peak** | Confirms this is emphatically read-heavy — caching and read replicas, not write scaling, are where the design effort goes |
| Key space | 7-char base62 → 62⁷ ≈ **3.5 × 10¹² possible keys** | At 1B new keys/year that's **~3,500 years** of headroom — 7 characters is enough; no need to grow the key length as a scaling lever |
| Storage | ~300B/row (long URL + key + metadata) × 5B rows (5yr @ 1B/yr) × ×3 replication ≈ **~4.5 TB** | Comfortably fits a single sharded-later relational store; no need to shard *today*, but the growth curve says revisit once yearly volume grows an order of magnitude |
| Click-event rate | ≈ read rate → **~2,700/sec avg, ~5,500/sec peak** | This is the number that forces analytics **off** the synchronous redirect path — a durable write at this rate on the latency-critical read path is the wrong shape; it belongs on an async queue |

### Functional & non-functional requirements (the ideal cut)

- **Functional** — `createShortUrl(longUrl, customAlias?, expiresAt?) → shortUrl`; `resolve(shortUrl) → redirect`; per-URL analytics (click count, referrer, user agent, timestamp); optional custom alias; expiration/TTL with a cleanup sweep for stale links.
- **Non-functional, ranked** — **low read latency** (the redirect is on every clicking user's critical path, single-digit ms p95) → **high availability** (an outage breaks every link ever shared) → **durability of accepted mappings** (never lose a URL once `createShortUrl` returns success) → **eventual consistency is fine for analytics** → **horizontal read scalability** → **non-guessable keys** (a security requirement, not a nice-to-have — sequential or predictable keys let anyone enumerate other users' links).

### Ideal architecture

![Architecture diagram for the ideal URL shortener. A client sends a POST to urls with a long URL and an optional custom alias through an API gateway doing authentication and rate limiting into a URL Write Service, which requests a unique id from a Snowflake ID Generator that base62 encodes it with a permutation mask, inserts the short key, long url, and expiry into a URL DB Primary that replicates to a URL DB Read Replica, and returns the short URL to the client. On the read side the client sends a GET for a short key first to a CDN edge cache for cacheable redirects, which either serves a cached permanent link directly with no backend hit, or on a cache miss or non cacheable link forwards through the API gateway to a URL Read Service, which checks a Redis cache aside, falling back to the URL DB Read Replica on a cache miss, returns a 301 or 302 redirect to the client, and emits a fire and forget click event onto a Kafka click events topic consumed by an Analytics Consumer into an Analytics Store. An Expiry Cleanup Job sweeps expired or stale urls from the URL DB Primary and evicts the corresponding expired keys from the Redis cache.](./diagrams/url-shortener-architecture.png)

### Component walk-through

- **Write path** — `POST /urls` → Write Service asks the **key generator** for one unique id, encodes it to a 7-character key, then does one `INSERT` (`short_key`, `long_url`, `expires_at`) — no read-before-write, no retry loop, because the key is guaranteed unique by construction, not by hoping a hash doesn't collide.
- **Read path** — `GET /{shortKey}` hits the **CDN first**; a link served as a long-lived, cacheable **301** short-circuits straight back to the client with **zero backend load** on repeat visits. Anything not cached that way falls through to the Read Service, which checks **Redis (cache-aside)**, falls back to a **read replica** on a miss, and returns the redirect.
- **Analytics path** — every redirect **fires a click event at the queue and moves on** — the event is never awaited, so a slow or backed-up analytics pipeline can never add latency to a redirect.
- **Cleanup path** — a scheduled job sweeps `expires_at`-passed rows, deletes/archives them, and **positively evicts** the matching cache entries (a TTL alone would let a deleted link keep "working" from cache for a while).

### Database schema

| Table | Fields | Note |
|---|---|---|
| `url` | `short_key` (PK, 7-char base62), `long_url`, `owner_id` (nullable), `created_at`, `expires_at` (nullable), `status` | **Crux table.** `status`: `ACTIVE → EXPIRED → DELETED`; point-lookup by `short_key` on every redirect, so this key *is* the whole access pattern |
| `click_event` | `short_key` (FK), `ts`, `referrer`, `user_agent`, `geo`, `ip_hash` | Append-only, one row per redirect — never point-updated |
| `user` | `id` (PK), `email`, `plan_tier` | Only needed once custom aliases / ownership / per-user rate tiers exist |

### Storage choices — which engine for which store

| Store | Category | Why this category, not another |
|---|---|---|
| `url` | **Relational (or a KV store — either is defensible)** | Access is 100% point-lookup by `short_key` (plus an occasional lookup by `owner_id`), so a KV store like DynamoDB fits the access pattern exactly; relational (Postgres) is equally valid here and adds an easy secondary index for a "my links" feature — pick either, the point is this is *not* a case for a wide-column or search-index store |
| Redis cache | **In-memory KV, TTL + invalidate-on-delete** | Sub-millisecond reads for the 100:1 hot path; fully rebuildable from `url`, so losing it costs latency, never correctness |
| `click_event` | **Wide-column NoSQL / append-only log** | High-volume, strictly-append, time-ordered writes with no point updates — the wrong shape for a relational table, the right shape for Cassandra/DynamoDB or a Kafka-backed sink |
| Analytics aggregates (click counts, top URLs) | **Columnar / OLAP store** | The query pattern here is scan-and-aggregate ("what % of URLs get used"), not point lookup — a different access shape from `url` entirely, so it lives in its own store rather than being computed live against the hot path |
| CDN | **Edge cache** | Offloads the backend entirely for permanent, established links — the read scaling technique with the best cost/latency trade-off, when it applies |

### Design trade-offs

- **Snowflake-style unique ID + base62 (with a permutation mask) over a DB auto-increment or a content hash** — an auto-increment key is sequential and guessable (this session's own flagged security gap); a content hash needs collision handling and a retry loop. A 64-bit unique id (timestamp + worker-id + sequence, so no coordination between write instances) masked and base62-encoded is unique by construction, non-sequential-looking, and needs no retry. Switch to a pre-generated **key-generation-service (KGS) pool** only if you need a shorter key than a masked 64-bit id encodes to.
- **301 vs. 302 redirect — the single biggest lever on read-path load, and it trades directly against analytics.** A 301 is cacheable by browsers and CDNs, so a repeat visitor never hits the backend again — but that also means you **stop seeing their clicks**. A 302 keeps every click visible to analytics at the cost of hitting the backend every time. Say which one you're choosing and why the requirements point that way, rather than picking one by default.
- **Async click events (Kafka) over a synchronous analytics write** — a durable write on every redirect at ~2,700–5,500/sec would put the exact same anti-pattern this repo's rate-limiter session flagged (a slow dependency on the hot path) onto the most latency-sensitive path in the system. Decoupling costs only "analytics is eventually consistent," which the requirements already accept.
- **Cache invalidation on delete, not TTL alone** — an expired/deleted link must be actively evicted from Redis; a bare TTL would let it keep resolving from cache for up to a full TTL window after deletion.

### Logging, Monitoring & Alerts

| Signal | Alert threshold | Why it matters |
|---|---|---|
| **Cache hit ratio** (Redis) | Sustained drop | Signals a cache stampede, or a single viral short link's read volume outpacing what cache-aside alone can absorb |
| **Key-generation collision rate** | Any sustained non-zero rate | Should be ~0 by construction; a nonzero rate means the id generator's clock/worker-id assumptions are broken |
| **404 / expired-link rate** | Spike over baseline | Either a key-enumeration/scraping attempt, or a bug in the cleanup job deleting live links |
| **Click-event consumer lag** (Kafka) | Growing rather than draining | Analytics is falling behind the live redirect rate |
| **Read-replica replication lag** | Above a few hundred ms | A freshly created URL might briefly 404 on a replica that hasn't caught up |
| **Redirect p95/p99 latency** | Above the latency budget | This is the actual user-facing SLA — the number everything else in this design exists to protect |

## Takeaways to drill

1. **Open with a visible requirements checklist** (functional / non-functional / analytics) before designing.
2. **Reach for the standard tool directly** — consistent hashing for a distributed cache, not vertical-scaling-first.
3. **Go deep on the interesting decision** (key generation) with 2–3 options and their trade-offs — a unique-ID generator (Snowflake + base62) beats both a hash-with-collision-retry and a guessable auto-increment.
4. **Label every diagram arrow** (data + protocol) and put API signatures on the canvas.
5. **301 vs. 302 is a real trade-off, not a coin flip** — a cacheable 301 kills backend read load but also kills click visibility; decide based on whether analytics fidelity matters for that link.

→ Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Answer Framework](../answer-framework.md) before the next mock.
