# Caching

---

Storing a copy of data closer to the requester so repeat reads are fast and the backing store is spared. The highest-leverage lever for read-heavy systems. Related: [databases — scaling](../05-databases-and-storage/databases-scaling.md).

## 1. What is caching?

A **cache** is a fast, usually in-memory store holding a **copy** of data that's expensive to fetch or compute, so future requests are served from the cache instead of the slow source (DB, disk, network, another service). Works because of **locality** — a small "hot" set (the 80/20 rule) is requested far more often than the rest.

- **Hit** = found in cache (fast). **Miss** = not there → fetch from source, then store.
- Key metric: **hit ratio** = hits / (hits + misses).

## 2. Types of caching

| Type | Where | Examples |
|---|---|---|
| **Client / browser** | On the user's device | HTTP cache headers |
| **In-memory (local)** | In the app process | Caffeine, Guava |
| **Distributed** | Shared cache tier across servers | **Redis**, **Memcached** |
| **CDN** | Edge servers near users | CloudFront, Cloudflare, Akamai |
| **Database cache** | Query/buffer cache in the DB | built-in |

Local is fastest but per-node (duplicated, inconsistent); **distributed** is shared and scales out (via [consistent hashing](../03-networking-and-delivery/load-balancing-and-consistent-hashing.md)); **CDN** caches static/media at the edge (see [CDN](../03-networking-and-delivery/cdn.md)). For the distributed tier in depth — Redis vs Memcached, architecture, and scaling — see [Redis & Memcached](./redis-and-memcached.md).

## 3. Caching strategies

**Read:** **Cache-aside (lazy)** — app checks cache, on miss reads DB and populates it (most common). **Read-through** — cache library fetches from DB on miss transparently.

| Write strategy | How | Trade-off |
|---|---|---|
| **Write-through** | Write to cache **and** DB synchronously | Cache always fresh; slower writes |
| **Write-around** | Write only to DB; cache filled on later read | Avoids caching write-once data; first read misses |
| **Write-back (write-behind)** | Write to cache, flush to DB async | Fastest writes; **risk of data loss** on cache crash |

```
Write-through   App ─write─▶ Cache ─write─▶ DB ─▶ ack        (both written before ack; always fresh)

Write-around    App ─write──────────────▶ DB ─▶ ack          (cache skipped on write)
                App ─read─▶ Cache ✗miss ─▶ DB ─fill─▶ Cache   (cache filled on a later read)

Write-back      App ─write─▶ Cache ─▶ ack                     (ack immediately — fast)
                              Cache ┄┄async flush┄┄▶ DB       (flushed later, may batch)
```

## 4. Eviction policies

Caches are size-bounded, so something must be evicted when full:

| Policy | Evicts | Best when |
|---|---|---|
| **LRU** (Least Recently Used) | Item unused longest | General-purpose default |
| **LFU** (Least Frequently Used) | Item accessed least often | Stable popularity skew |
| **FIFO** | Oldest inserted | Simple; ignores access pattern |

**TTL** (time-to-live) also expires entries after a set time, independent of eviction.

## 5. Consistency & invalidation

Cache holds a *copy*, so it can go **stale** when the source changes. Options: **TTL** (accept staleness up to the TTL — simplest); **explicit invalidation** (delete/update the key on write); **write-through** (keep cache and DB in lockstep). Invalidation is famously hard — prefer short TTLs + event-driven invalidation for correctness-sensitive data.

**Eventual consistency.** A cached system is usually **eventually consistent**: after the source changes there's a **staleness window** where reads return the old value, until the entry expires (TTL) or is invalidated — after which the cache **converges** to the source. This is an acceptable trade for most reads (feeds, product listings, view counts). Reach for **strong consistency** (synchronous write-through **and** invalidation, or versioned/read-through reads) only when a stale read is unacceptable — account balances, inventory, authorization. Tune the **TTL** to the staleness you can tolerate: shorter = fresher but lower hit ratio.

## 6. Warm-up & prefetching

A cold cache (empty, after deploy/restart) sends all traffic to the DB. **Warm-up** = pre-load hot keys before serving traffic; **prefetching** = proactively load data likely to be needed soon (e.g. next page). Both trade extra work for avoiding a miss storm.

## 7. Monitoring & metrics

- Track: **hit ratio** (the headline number), **latency** (p95/p99), **eviction rate** (too high → cache too small), **memory usage**, and **key/hot-key distribution**. 
- A falling hit ratio or rising evictions signals the cache is undersized or poorly keyed.

## 8. Pros & cons

- **Pros:** lower latency, higher throughput, less DB/backend load, lower cost. 
- **Cons:** **stale data** risk, added complexity, another failure mode, memory cost, cold-start misses.

## 9. Mitigating the drawbacks

| Problem | What happens | Mitigation |
|---|---|---|
| **Thundering herd / stampede** | A hot key expires → many requests hit the DB at once | **Request coalescing** (single-flight), lock/leased refresh, stagger TTLs |
| **Cache avalanche** | Many keys expire together → DB overload | **Jitter** TTLs (randomize expiry) |
| **Cache penetration** | Queries for non-existent keys always miss → hit DB | Cache **negative results**; **Bloom filter** to reject unknown keys |
| **Hot key** | One key overwhelms a single node | Replicate the key; add a local cache in front |
| **Cache thrashing (churn)** | Working set > cache size → entries evicted before they're reused; **hit ratio collapses** and the cache does work for almost no benefit | **Size the cache to the working set**; use LRU / scan-resistant eviction (2Q, ARC); don't cache huge one-off scans that flush the hot set |
| **Stale data** | Copy diverges from source | Short TTLs + explicit/event-driven invalidation |

## 10. One-Paragraph Summary (for quick revision)

A **cache** stores a fast copy of expensive-to-fetch data, exploiting the 80/20 hot set; the key metric is **hit ratio**. Caches live at the **client, in-process (local), a distributed tier (Redis/Memcached), or the CDN edge**. Reads use **cache-aside** (most common) or read-through; writes use **write-through** (fresh, slower), **write-around** (skip write-once data), or **write-back** (fast, risky). When full, evict via **LRU/LFU/FIFO**, and expire via **TTL**. The hard part is **consistency** — copies go stale, so caches are typically **eventually consistent** (a staleness window until TTL/invalidation, then convergence); accept it for most reads and use short TTLs + explicit invalidation, reserving strong consistency for balances/inventory/auth. **Warm up** or **prefetch** to avoid cold-start miss storms, and monitor **hit ratio, evictions, and latency**. Caching cuts latency and backend load but adds staleness and complexity — mitigate the classic failures (**stampede, avalanche, penetration, hot keys, thrashing**) with request coalescing, TTL jitter, negative caching/Bloom filters, key replication, and sizing the cache to the working set.
