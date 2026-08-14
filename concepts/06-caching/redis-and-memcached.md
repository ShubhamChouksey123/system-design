# Distributed Caching — Redis & Memcached

---

A deeper look at the two dominant **distributed cache** tiers (the "Distributed" row in [caching](./caching.md)). Both are **in-memory key-value stores** accessed over the network and shared by all app servers — read that doc first for caching fundamentals.

## 1. Redis vs Memcached

| | **Redis** | **Memcached** |
|---|---|---|
| Data types | Rich: strings, hashes, lists, sets, **sorted sets**, streams, bitmaps | Strings/blobs only |
| Threading | Mostly **single-threaded** event loop | **Multi-threaded** (scales on cores) |
| Persistence | Optional (**RDB** snapshots + **AOF** log) | None (pure cache) |
| Replication / HA | Built-in (leader–follower, **Sentinel**, **Cluster**) | None built-in (client-side only) |
| Sharding | **Redis Cluster** (hash slots) | Client-side (consistent hashing) |
| Extras | Pub/sub, Lua, transactions, TTLs, geo | Simple, tiny, very fast |

**Rule of thumb:** **Memcached** for a simple, huge, multi-threaded look-aside cache; **Redis** for anything richer (data structures, persistence, HA, pub/sub) — it's the default choice today.

## 2. Memcached architecture

A **multi-threaded**, pure in-memory slab-allocated key-value store. No persistence, no replication — a node loss = that shard's data is gone. **Sharding is client-side**: the client hashes the key (ideally **consistent hashing**) to pick a node. Simple and blazing fast for offloading DB reads.

## 3. Redis architecture

Single-threaded command processing (no lock contention; commands are atomic), with:
- **Persistence** — **RDB** (point-in-time snapshots, compact, fast restart) and/or **AOF** (append-only command log, more durable). A pure cache can disable both.
- **Replication** — one **primary**, N **replicas** (async) for read scaling and failover.
- **Sentinel** — monitors nodes and does automatic **failover** (promote a replica) — HA without sharding.
- **Cluster** — shards data across primaries using **16,384 hash slots**, each primary with replicas → horizontal scale **and** HA.

## 4. Key routing — reading from the right node

With data spread over many nodes, a key must **always map to the same node**, or a write and a later read land on different nodes → a guaranteed miss (or stale copy). Two approaches:

- **Client-side (Memcached, proxies like twemproxy/Envoy)** — the client hashes the key to pick a node using **consistent hashing** (hash ring + virtual nodes), so adding/removing a node reshuffles only ~`K/N` keys instead of all of them. See [consistent hashing](../03-networking-and-delivery/load-balancing-and-consistent-hashing.md).
- **Server-side hash slots (Redis Cluster)** — the keyspace is split into **16,384 slots**; `slot = CRC16(key) mod 16384`, each slot owned by one primary. The client caches the slot→node map and routes directly; if it guesses wrong, the node replies **`MOVED <slot> <host>`** to redirect it (and the client refreshes its map).

```
key ──CRC16 mod 16384──▶ slot 8412 ──owned by──▶ Primary B   (read & write here)
wrong node?  → node replies  MOVED 8412 10.0.0.3:6379  → client retries + caches map
```

**Keep related keys together** with a **hash tag** — only the `{...}` part is hashed, so `user:{42}:profile` and `user:{42}:sessions` share a slot, enabling multi-key ops/transactions on the same node.

## 5. Use cases

- **Cache** (both) — offload DB/compute for hot reads.
- **Session store** — shared sessions so app servers stay **stateless**.
- **Rate limiting** — atomic `INCR` + TTL (Redis).
- **Leaderboards / ranking** — Redis **sorted sets**.
- **Queues / pub-sub / streams** — lightweight messaging (Redis).
- **Real-time counters & analytics** — atomic ops, bitmaps, HyperLogLog (Redis).

## 6. Deployment & scaling best practices

- **Scale reads** with replicas; **scale data/writes** by sharding (Redis Cluster hash slots, or client-side consistent hashing for Memcached).
- **Cap memory + set an eviction policy** (`maxmemory` + `allkeys-lru`/`lfu`); **put TTLs on everything** to bound growth.
- **HA**: run replicas across **multiple AZs**; use **Sentinel or Cluster** for automatic failover; never a single node in prod.
- **Avoid big keys and hot keys** — they create imbalance and blocking; split them or add a local cache in front.
- **Efficiency**: use **pipelining/batching**, **connection pooling**, and avoid `O(n)` commands (`KEYS`) on large datasets.
- **Know cache vs source-of-truth**: treat the cache as **disposable** unless you deliberately enable Redis persistence + replication as a datastore.
- **Managed options**: AWS **ElastiCache** (Redis/Memcached), GCP **MemoryStore**, **Redis Enterprise** — offload ops.
- **Monitor**: hit ratio, memory usage, eviction rate, p99 latency, replication lag.

## 7. One-Paragraph Summary (for quick revision)

**Redis** and **Memcached** are the two standard **distributed in-memory KV caches**. **Memcached** is a simple, multi-threaded, no-persistence cache sharded **client-side** (consistent hashing) — great for a huge plain look-aside cache. **Redis** is mostly single-threaded but far richer: **data structures** (sorted sets, hashes, streams), optional **persistence** (RDB/AOF), **replication**, **Sentinel** for automatic failover, and **Cluster** (16,384 hash slots) for horizontal sharding + HA — powering sessions, rate limiting, leaderboards, queues, and real-time analytics, and it's the usual default. **Routing is deterministic** so reads land where writes went: client-side **consistent hashing** (Memcached) or Redis Cluster's `CRC16 mod 16384` slot map with **`MOVED`** redirects (and **hash tags** to co-locate related keys). To deploy at scale: cap memory with an LRU/LFU eviction policy, TTL everything, scale reads with multi-AZ replicas and data with sharding, avoid big/hot keys, use pipelining + pooling, lean on managed services (ElastiCache/MemoryStore), and monitor hit ratio, memory, evictions, and latency.
