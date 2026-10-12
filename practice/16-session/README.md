# Session 16 — Trending Songs (Spotify / music-streaming style) · self-practiced

> A **self-practiced, crux-focused** design — not a full mock interview, and not a whole "design a music streaming service" prompt. The question that triggered this session was narrow and concrete: *"how do we serve the Top 10 trending songs without querying the database for every user, or the database crashes under read volume?"* There's no transcript and no mock-platform score, so this write-up skips the "design I produced" / scorecard / lost-points sections entirely (there was no flawed first attempt to critique) and goes straight to the reasoning and the reference answer — the same shape a 2–3 minute rapid-fire version of this question would take, expanded to full depth.

| | |
|---|---|
| **Problem** | Within a music-streaming platform, serve a "Top 10 Trending Songs" widget to every user without the read volume collapsing the primary database |
| **Focus** | Recognizing that an **identical result for every reader** turns a scaling problem into a caching problem, one layer beyond a per-user leaderboard |
| **Format** | Self-practiced — no mock-platform score, no `script.md` transcript; written directly as a reference answer |
| **Weakest areas** | N/A — no prior attempt exists to grade; treat the "Takeaways to drill" section as the checklist for next time this crux appears |

## The problem

> Design the "Top 10 Trending Songs" feature for a music-streaming app. Every user sees the same (global or regional) list on their home screen. Don't query the database per user — at streaming scale that's millions of identical reads per minute, and the database can't absorb that fan-out.

What makes this *not* just "add a cache": the naive instinct is to cache the *query result* per request, but every single user is asking for the exact same bytes. That's a stronger property than typical read-heavy caching (a user's own feed, a product page) — it means the correct answer isn't "cache it," it's "compute it once, on a schedule, and let every request read the same precomputed answer." The same trick scales further here than it did for a per-tag or per-user leaderboard, because there's exactly one list to maintain per region instead of millions of personalized ones.

## Terminology

| Term | Meaning |
|---|---|
| **Fan-out-identical read** | A read where every caller gets the same response regardless of who's asking — the property that makes an endpoint cacheable at the edge, not just at the app tier. |
| **Write amplification** | When one real-world event (a song play) turns into disproportionately many downstream operations (a synchronous counter update per play) — the thing batching exists to avoid. |
| **Time-decayed / windowed trending** | A "trending" score that favors recent activity over all-time totals, implemented either by a decay function on the score or by keeping separate time-bucketed counters and summing only the recent ones. |
| **Precompute-and-refresh** | Running the expensive computation (ranking) on a fixed interval in the background, and serving every read from the cached *result* of the last run — as opposed to computing on demand per request. |

## Requirements & estimation

**Functional** — serve a Top-10 (or Top-N) trending songs list, globally and per region; the list should reflect *recent* popularity, not all-time play counts; update frequently enough to feel "live" (seconds to a couple of minutes of staleness is acceptable); survive a single song going viral without the system falling over.

**Non-functional** — the read path must cost **O(1) work independent of traffic**, since every reader wants the same answer; the write path (play events) must not create **write amplification** at streaming scale; eventual consistency is explicitly fine for this feature — nobody notices a trending list that's 15 seconds stale.

**Ideal estimation (decision-tied):**

| Number | Value | Decision it forces |
|---|---|---|
| Trending-widget reads | 100M DAU × ~5 app opens/day ≈ 500M reads/day → **~5,800 reads/sec avg, ~11,600/sec peak** (`Peak ≈ 2× Average`) | At this volume, **no per-request path may touch the database or even Redis directly** — the read must terminate at a cache (app-layer or edge) that costs the same whether 1 or 1M people hit it in the same second |
| Play events (write side) | 100M DAU × ~20 plays/day ≈ 2B plays/day ≈ **~23,000 writes/sec avg, ~46,000/sec peak** | Writing a synchronous counter increment per play (even to Redis) at this rate risks **hot-key contention** on a viral song's counter and needless Redis round-trips; forces **async ingestion + batched increments**, not a increment-per-event path |
| Catalog × candidates | ~100M songs total, but only the **top few thousand per region** ever contend for a Top-10 slot in any given window | Confirms the ranking structure (a sorted set) only needs to stay *accurate at the top* — exact precision for song #4,000,000 doesn't matter, which is why an approximate, windowed count is an acceptable trade, not a correctness risk |
| Precomputed payload size | Top 10 song IDs + minimal metadata ≈ a few KB per region | Trivially small — confirms the final cached artifact is cheap to replicate to every edge location and app-server instance; the cost in this design is all in *how often* it's recomputed, never in its size |

## The ideal design

**The crux:** because the Top-10 list is **identical for every single reader**, the right fix isn't "cache the database query," it's "stop computing it per-request at all" — precompute the ranked list on a short interval from a cheap, write-optimized counter store, and let every read terminate at a cache (or CDN edge) that costs nothing extra no matter how many users hit it in the same second. The database never sits on the hot path, for either reads or writes.

### Ideal architecture

![Architecture diagram for a music streaming trending songs feature. On the read path, a client sends an HTTPS GET to a CDN edge cache, which on a cache miss every fifteen to thirty seconds forwards to an API Gateway and a Trending Read Service, which reads a precomputed Top Ten JSON string from a Trending Cache in Redis keyed by region, and hydrates song ids into display objects via a Song Metadata Cache falling back to a relational Song Metadata Database, then returns the response which gets edge cached and served to all other users directly from the CDN. On the write path, a client playing a song triggers the Playback Service to publish a play event asynchronously and at least once to a Kafka topic called play events keyed by song id, user id, region, and timestamp; an Aggregator Worker consumes the topic and applies a batched increment every few seconds into a Trending ZSET, a Redis sorted set partitioned per region and per hour bucket with a forty eight hour time to live, while also asynchronously writing a durable copy into a Play Count Archive on a wide column NoSQL store such as Cassandra for royalties and analytics, fully decoupled from the real time ranking path. A separate Trending Refresh Job runs every fifteen to thirty seconds, reads the top ten entries summed across the recent hour buckets from the Trending ZSET, writes the resulting precomputed list into the Trending Cache, and purges or short-TTL invalidates the CDN edge cache so the next read picks up the refreshed list. A Monitoring and Alerts component watches Kafka consumer lag on the play events topic, the Trending Cache hit ratio, and the refresh job's success and latency.](./diagrams/ideal-design.png)

### Component walk-through

- **Read path never computes anything.** `Client → CDN edge → API Gateway → Trending Read Service → Trending Cache (Redis, precomputed JSON)`. The Redis string lookup is the only data-dependent step; song metadata (title, artist, art) is hydrated from its own cache, kept separate because it changes on a completely different cadence than the ranking does. The CDN sits in front of all of this for the public, identical-for-everyone response — once one request refills the edge cache, every other user in that edge location is served without the request ever reaching the app tier at all.
- **Write path never touches the ranking store synchronously.** A play doesn't call `ZINCRBY` directly — it's published to a Kafka topic (`play-events`) and forgotten by the client-facing path immediately. An **Aggregator Worker** consumes the topic and applies **batched** increments (summing a few seconds' worth of plays per song before one `ZINCRBY`), which is what actually prevents a viral song's counter from becoming a hot key hammered thousands of times a second.
- **"Trending" is a sliding window, not an all-time total.** The ZSET is partitioned per **region** and per **hour bucket** (`trending:{region}:{hour_bucket}`), each with a TTL (e.g. 48h) so old buckets disappear on their own. Ranking sums the last few hours' buckets rather than reading one all-time counter — an old song that was huge last year never permanently occupies a slot, and no explicit decay job is needed because expiry does the forgetting for free.
- **A separate background job, not the read path, does the expensive work.** The **Trending Refresh Job** runs on a fixed interval (e.g. every 15–30s), reads `ZREVRANGE` across the relevant hour buckets, and writes the resulting Top-10 straight into the **Trending Cache** that the read path actually serves from. This is the step that converts "compute per request" into "compute once per interval, serve many times" — the single idea the whole design hangs on.
- **Durability for royalties is a separate concern from ranking.** The Aggregator Worker also writes play counts into a durable archive (e.g. Cassandra) for billing/analytics — this path can afford to be exact and durable precisely because it's decoupled from the latency- and throughput-sensitive ranking path; losing a trending-list refresh for a few seconds is a non-event, losing a royalty-relevant play count is not, so they don't share infrastructure.

### Database schema

| Store | Fields | Note |
|---|---|---|
| `play_events` (Kafka topic, not a table) | `song_id`, `user_id`, `region`, `timestamp` | Not persisted relationally on the hot path — the topic *is* the durable buffer between ingestion and aggregation. |
| `trending:{region}:{hour_bucket}` (Redis ZSET) | member = `song_id`, score = play count in that bucket | **The crux store.** Sparse by construction — only songs actually played in that region/hour appear; TTL per bucket (e.g. 48h) retires old data automatically. |
| `trending:top10:{region}` (Redis string) | precomputed JSON: ranked list of `song_id` + rank | What the read path actually serves from — written only by the Refresh Job, never computed inline. |
| `song_metadata` | `song_id` (PK), `title`, `artist`, `art_url`, `album_id` | Relational; changes rarely (new releases, metadata edits), cached separately with a long TTL since it's not tied to play volume at all. |
| `play_count_archive` | `song_id`, `region`, `day`, `play_count` | Durable, append-friendly; feeds royalty/analytics pipelines, intentionally isolated from the real-time ranking path. |

### Storage choices — which engine for which store

| Store | Category | Why this category, not another |
|---|---|---|
| `play_events` | **Durable log (Kafka)** | Needs to absorb a huge, bursty write rate without blocking the client, and be replayable if the aggregator falls behind or crashes — a queue, not a database table, is the right medium for an ingest buffer. |
| `trending:{region}:{hour_bucket}` | **In-memory KV, sorted set (Redis ZSET)** | The access pattern is "give me the top N by score" — a sorted set gives `O(log N)` increments and `O(log N + k)` top-K reads natively; ephemeral is fine because it's rebuildable from the event stream if ever lost. |
| `trending:top10:{region}` | **In-memory KV, simple string (Redis)** | A few KB of precomputed JSON read millions of times between refreshes — the cheapest possible read, deliberately decoupled from the ZSET so a read never does a `ZREVRANGE` itself. |
| `song_metadata` | **Relational (RDBMS)** | Small, structured rows with real relationships (song → album → artist) and infrequent writes — a textbook relational fit, cached separately with its own invalidation cadence. |
| `play_count_archive` | **Wide-column NoSQL (Cassandra)** | High-volume, append-heavy, partitionable by `song_id`/`day` — a billing/analytics access pattern, not a point-lookup one, and explicitly isolated so its throughput needs never compete with the latency-sensitive ranking path. |

### Design trade-offs

- **Precompute-and-refresh over compute-on-read** — chosen specifically because the result is identical for every reader; this is the one design choice that doesn't generalize to a *personalized* feed (where compute-on-read with per-user caching is often unavoidable). When every reader wants the same answer, always prefer paying the compute cost once per interval over paying it once per request.
- **Async ingestion + batched increments over a synchronous increment per play** — trades a few seconds of staleness in the ranking for removing write amplification and hot-key contention entirely from the client-facing path. The staleness is free to accept because nothing in the requirements needs the trending list to reflect a play that happened half a second ago.
- **Time-bucketed ZSETs with TTL over a single all-time counter plus a manual decay job** — gets a sliding "trending window" essentially for free (expiry does the forgetting), at the cost of summing a handful of buckets per read instead of reading one key — a cost paid by the Refresh Job, never by the request path.
- **CDN/edge caching layered on top of the app-level Redis cache, not instead of it** — the Redis cache is still the correct layer for same-region app servers and for any client that bypasses the CDN; the CDN is the final hop that removes load from the app tier entirely for the single highest-fan-out endpoint in the product. If personalization is ever added (e.g. "trending among people you follow"), this layer is the first one that stops working as-is, since CDN cache keys can't vary per user without losing the benefit.
- **Consistency: AP, explicitly, for the entire trending path** — reads tolerate staleness up to one refresh interval; writes tolerate at-least-once delivery with no per-event dedup, because an occasional double-counted play has no visible effect on a Top-10 ranking. This is the opposite trade from the royalty archive, which is why the two paths are kept physically separate.

### Logging, Monitoring & Alerts

| Signal | Alert threshold | Why it matters |
|---|---|---|
| **Kafka consumer lag on `play-events`** | Lag growing rather than draining | The aggregator is falling behind real-time plays — the trending list will go stale even though the cache layer looks healthy |
| **Trending Cache hit ratio** (app + CDN edge) | Sustained drop below ~99% | Signals a cache stampede, a bad invalidation, or the Refresh Job failing to repopulate the cache in time |
| **Refresh Job latency / failure count** | Job runtime exceeding the refresh interval, or any failure | If this job stalls, every reader silently gets a stale list — there's no natural error, so this must be monitored directly |
| **ZSET hot-key / increment-rate skew** | One `song_id` dominating aggregator throughput | Rare since batched sums are cheap, but a genuinely unprecedented viral spike could still warrant a dedicated code path |
| **Play-event duplicate/drop rate** | Sustained non-zero rate beyond expected at-least-once overlap | Confirms the dedup/idempotency assumptions on the royalty archive path specifically (the ranking path tolerates this; the archive should not) |

## Takeaways to drill

1. **An identical-for-every-reader response is the signal to precompute, not just to cache.** The moment every caller wants the same bytes, the right move is "compute once per interval, serve from that result," not "cache the query per request" — that's a stronger, cheaper pattern than typical per-user caching.
2. **Decouple ingestion from aggregation with a queue, then batch the aggregation.** Writing straight to a counter on every event creates write amplification and hot-key risk at scale; a queue plus a periodic batched increment removes both.
3. **Time-bucketed sorted sets with TTL give you a sliding window for free.** No explicit decay function is needed if old buckets simply expire — "trending now" falls out of the data structure's own TTL behavior.
4. **Separate the real-time ranking path from the durable/exact archive path.** Royalty/analytics data can afford to be exact and durable because it's decoupled from the latency-sensitive ranking path — don't make one store serve both access patterns.
5. **CDN/edge caching is the correct final layer for any public, identical-for-all-users endpoint** — and the first thing to reconsider the moment personalization gets added to that same endpoint.
6. **State the CP/AP split out loud, per path** — this design is AP end-to-end for ranking, and that's a feature of the requirements, not a shortcut: say explicitly *why* staleness is acceptable here, since the royalty archive right next to it needs the opposite guarantee.

> Tracker: [../README.md](../README.md) · drills: [Opening Ritual](../opening-ritual.md) · [Answer Framework](../answer-framework.md).
