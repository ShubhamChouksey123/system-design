# Distributed Caching — Redis & Memcached

---

This file describes the two main **distributed cache** tiers (the "Distributed" row in [caching](./caching.md)). Both are **in-memory key-value stores**. Clients use them over the network. All app servers share them. Read the caching file first.

## 1. What is Redis?

**Redis** is an in-memory data store. It keeps keys and values in RAM. Values can be strings, hashes, lists, sets, sorted sets, or streams. Persistence is optional. Common uses: cache, session store, rate limiter, leaderboard, queue.

## 2. How Redis handles concurrency

Many clients connect at the same time. Redis runs their commands on **one thread**.

| Part | What it does |
|---|---|
| **Event loop** | One thread watches all sockets (`epoll`/`kqueue`). It serves the sockets that are ready. |
| **Serial execution** | Redis runs one command at a time, to the end. |
| **Atomic commands** | No other command can run in the middle of `INCR` or `ZADD`. No locks are necessary. |
| **Many steps** | Use `MULTI/EXEC` or a **Lua script**. Redis runs them as one unit. |
| **Optimistic lock** | `WATCH` a key. `EXEC` fails if the key changes. |
| **Background work** | Snapshots and disk writes run in the background. Redis 6+ can use I/O threads for sockets. Commands stay single-threaded. |

**Warning:** a slow command (`KEYS *`, a very large `SMEMBERS`) blocks all clients. Use `SCAN`. To use more CPU cores, add shards (Redis Cluster).

## 3. Why Redis is fast

| Reason | Effect |
|---|---|
| **RAM storage** | RAM access is about 100 ns. SSD access is about 100 µs or more. |
| **Single thread** | No locks. No thread switches. |
| **Event loop** | One thread serves thousands of connections. |
| **Good data structures** | Hash table `O(1)`. Skip list `O(log n)`. Compact formats for small data. |
| **Simple protocol** | RESP is easy to parse. Pipelining sends many commands in one round trip. |
| **Disk off the hot path** | Writes go to RAM first. Disk writes happen in the background. |

One node handles about 100K operations per second at sub-millisecond latency. The network is usually the limit, not the CPU. Trade-off: RAM size limits the data, and each shard uses one core.

## 4. Redis vs Memcached

| | **Redis** | **Memcached** |
|---|---|---|
| Data types | Strings, hashes, lists, sets, **sorted sets**, streams, bitmaps | Strings and blobs only |
| Threading | **Single-threaded** commands with an event loop | **Multi-threaded**. Uses many cores. |
| Persistence | Optional (**RDB** snapshots and **AOF** log) | None |
| Replication / HA | Built in (**Sentinel**, **Cluster**) | None. Client handles it. |
| Sharding | **Redis Cluster** (hash slots) | Client-side (consistent hashing) |
| Extras | Pub/sub, Lua, transactions, TTLs, geo | Simple, small, very fast |

**Rule of thumb:** use **Memcached** for a simple, large cache that needs many cores. Use **Redis** when you need data structures, persistence, HA, or pub/sub. Redis is the usual default.

## 5. Memcached architecture

Memcached is a **multi-threaded** key-value store in RAM. It has no persistence and no replication. If a node fails, its data is lost. **The client does the sharding.** The client hashes the key (use **consistent hashing**) to choose a node.

## 6. Redis architecture

| Part | Purpose |
|---|---|
| **RDB** | Point-in-time snapshots. Small files. Fast restart. Loses writes since the last snapshot. |
| **AOF** | Log of all writes (`fsync everysec` loses at most 1 s). A pure cache can turn off both. |
| **Replication** | One **primary** and many async **replicas**. Replicas serve reads and take over on failure. |
| **Sentinel** | Monitors nodes. Promotes a replica when the primary fails. HA without sharding. |
| **Cluster** | Splits data across primaries with **16,384 hash slots**. Each primary has replicas. Gives scale and HA. |

**Persistence in brief:**

- **RDB:** snapshot of all data. A `fork`ed child writes the file. The parent keeps serving (copy-on-write). Trigger: `save 300 100` or `BGSAVE`. Restart is fast. You lose writes after the last snapshot.
- **AOF:** log of every write. Redis replays it at restart. `appendfsync`: `always` (slow, almost no loss), `everysec` (loses at most 1 s, common), `no` (the OS decides). `BGREWRITEAOF` shrinks the log.
- **Both on:** Redis loads the AOF, because it is more complete.
- **Pure cache:** turn both off. The database is the source of truth. Redis restarts empty, and the app refills it.
- **Replicas only:** failover takes a few seconds. Each replica doubles memory.
- **Choose by the loss you accept:** none = whole cache · RDB = minutes · AOF `everysec` = 1 s.

## 7. Key routing

A key must **always map to the same node**. If it does not, a read can go to a different node than the write. The read then misses or returns old data. There are two methods:

| Method | How it works |
|---|---|
| **Client-side** (Memcached, twemproxy, Envoy) | The client hashes the key on a ring with virtual nodes. When you add or remove a node, only about `K/N` keys move. See [consistent hashing](../03-networking-and-delivery/load-balancing-and-consistent-hashing.md). |
| **Hash slots** (Redis Cluster) | `slot = CRC16(key) mod 16384`. One primary owns each slot. The client keeps a slot-to-node map. If the node is wrong, it replies `MOVED <slot> <host>`. The client then updates its map. |

```
key ──CRC16 mod 16384──▶ slot 8412 ──owned by──▶ Primary B
wrong node?  → MOVED 8412 10.0.0.3:6379  → client retries and updates its map
```

Use a **hash tag** to keep related keys together. Redis hashes only the `{...}` part. `user:{42}:profile` and `user:{42}:sessions` use the same slot. Multi-key commands then work.

## 8. Use cases

| Use case | Redis feature |
|---|---|
| Cache for hot reads | Both |
| Session store (stateless app servers) | Both |
| Rate limiting | `INCR` and TTL |
| Leaderboards | [Sorted sets](./redis-sorted-sets.md) |
| Queues, pub/sub, streams | Streams, lists, [pub/sub](./redis-pub-sub.md) |
| Real-time counters | Atomic commands, bitmaps, HyperLogLog |

## 9. Deployment and scaling

- **Scale reads** with replicas. **Scale writes and data** with sharding.
- **Set a memory limit and an eviction policy** (`maxmemory`, `allkeys-lru` or `lfu`). **Set a TTL on every key.**
- **HA:** put replicas in **many AZs**. Use **Sentinel or Cluster** for failover. Do not run one node in production.
- **Avoid big keys and hot keys.** They cause imbalance and blocking. Split them, or add a local cache.
- **Be efficient:** use pipelining, connection pools, and `SCAN` (not `KEYS`).
- **A cache is not the source of truth.** Treat it as disposable. Use Redis as a datastore only with persistence and replication.
- **Managed services:** AWS ElastiCache (Redis or Memcached), GCP Memorystore, Redis Enterprise.
- **Monitor:** hit ratio, memory, evictions, p99 latency, replication lag.

## 10. One-Paragraph Summary (for quick revision)

**Redis** and **Memcached** are the two standard **distributed in-memory caches**. **Memcached** is simple and multi-threaded. It has no persistence, and the client shards with consistent hashing. **Redis** runs commands on **one thread** with an **event loop**. Each command is atomic and needs no lock. Redis is fast because data is in RAM and the core has no locks. One slow command blocks all clients, so add shards for more cores. Redis also has data structures (sorted sets, hashes, streams), optional persistence (none, replicas, RDB, or AOF `everysec`), replication, **Sentinel** for failover, and **Cluster** (16,384 hash slots) for sharding and HA. Routing is deterministic: Memcached uses client-side consistent hashing. Redis Cluster uses `CRC16 mod 16384` with `MOVED` redirects and hash tags. At scale: set a memory limit and TTLs, add replicas in many AZs, avoid big and hot keys, use pipelining and pools, and monitor hit ratio, evictions, and latency.
