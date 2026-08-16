# Databases — Scaling

---

How to make a database handle more data and traffic. Companion: [database fundamentals](./databases-fundamentals.md). Related: [consistent hashing](../03-networking-and-delivery/load-balancing-and-consistent-hashing.md).

## 1. Optimize the queries first (cheapest win)

Before adding hardware, make the existing DB do less work — no new infrastructure, no new failure modes:
- **Read the query plan** (`EXPLAIN` / `EXPLAIN ANALYZE`) to find full-table scans and slow joins.
- **Select only needed columns** (avoid `SELECT *`); filter/paginate instead of pulling everything.
- **Fix N+1 queries** — batch or join instead of one query per row.
- **Add the right indexes** (see §2) for the columns you filter/join/sort on.
- Tune **connection pooling** and add a **cache** for hot reads.

> Slow queries, not lack of servers, are the most common cause of DB pain. Exhaust this step before replication or sharding.

## 2. Indexing

An **index** is an auxiliary structure (usually a **B-tree**, sometimes a **hash**) mapping column values → row locations, turning a full-table scan (O(n)) into a fast lookup (O(log n)).
- **Speeds reads**, but **slows writes** (every insert/update maintains the index) and uses extra storage.
- Index the columns you **filter / join / sort** on; don't over-index.

## 3. Replication

Keep **copies** of the data on multiple nodes for availability and read scaling.

**Master–Slave (leader–follower):** one **master** takes all **writes**; **replicas (slaves)** copy from it and serve **reads** → scales read-heavy workloads. If the master dies, a replica is **promoted** (failover).
- **Sync** replication = no data loss, higher latency; **async** = fast but risks losing the last writes (**replication lag** → stale reads just after a write).
- **Master–Master (multi-leader)** allows writes on several nodes but must resolve **write conflicts**.
- **Quorum** — read/write from a majority so that `R + W > N` balances consistency vs availability (Dynamo-style).

## 4. Partitioning & sharding (last resort)

When a single node can't hold the data or take the write volume, split the dataset across nodes — **vertical** (by columns) or **horizontal / sharding** (by rows). It's the highest-complexity step, so it comes last.

→ The **shard key**, placement strategies (range / hash / consistent hashing), and the hard parts (cross-shard queries & transactions) are the deep dive in **[Sharding / Partitioning](./sharding-and-partitioning.md)**.

## 5. Putting it together

Typical scaling order: **optimize queries** → **index** → add a **cache** + **read replicas** → **shard** only when one node can't hold the data or the write volume. Do the cheap, low-risk steps first; shard **last** — it adds the most complexity.

## 6. One-Paragraph Summary (for quick revision)

Scale a database in roughly this order. First **optimize the queries** (read the `EXPLAIN` plan, avoid `SELECT *`, kill N+1s, pool connections) — the cheapest win, no new infrastructure. **Indexing** (B-tree/hash) turns scans into fast lookups — great for reads, a small tax on writes. **Replication** copies data across nodes: **master–slave** sends writes to one leader and reads to replicas (watch **replication lag** / stale reads and failover), while multi-master and **quorum** (`R + W > N`) trade consistency vs availability. **Partitioning** splits data — **vertical** by columns, **horizontal (sharding)** by rows across nodes with a carefully chosen **shard key** (hash / consistent hashing to avoid hotspots), at the cost of hard cross-shard joins/transactions. Rule of thumb: **optimize queries first**, then index and cache, add read replicas, and **shard last**.
