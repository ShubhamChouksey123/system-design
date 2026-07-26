# Databases — Scaling

---

How to make a database handle more data and traffic. Companion: [database fundamentals](./databases-fundamentals.md). Related: [consistent hashing](./load-balancing-and-consistent-hashing.md).

## 1. Indexing

An **index** is an auxiliary structure (usually a **B-tree**, sometimes a **hash**) mapping column values → row locations, turning a full-table scan (O(n)) into a fast lookup (O(log n)).
- **Speeds reads**, but **slows writes** (every insert/update maintains the index) and uses extra storage.
- Index the columns you **filter / join / sort** on; don't over-index.

## 2. Replication

Keep **copies** of the data on multiple nodes for availability and read scaling.

**Master–Slave (leader–follower):** one **master** takes all **writes**; **replicas (slaves)** copy from it and serve **reads** → scales read-heavy workloads. If the master dies, a replica is **promoted** (failover).
- **Sync** replication = no data loss, higher latency; **async** = fast but risks losing the last writes (**replication lag** → stale reads just after a write).
- **Master–Master (multi-leader)** allows writes on several nodes but must resolve **write conflicts**.
- **Quorum** — read/write from a majority so that `R + W > N` balances consistency vs availability (Dynamo-style).

## 3. Partitioning & sharding

Split one big dataset into pieces so no single node holds it all.
- **Vertical partitioning** — split by **columns/tables** (e.g. move rarely-used or large columns out).
- **Horizontal partitioning / sharding** — split by **rows** across nodes, each shard holding a subset.
- **Shard key** choice is critical: a bad key creates **hotspots** (uneven load). Use hashing / **consistent hashing** to distribute keys and minimize resharding.
- Cost: **cross-shard queries and transactions become hard**; joins may move to application code.

## 4. Putting it together

Typical scaling order: **index** → add a **cache** + **read replicas** → **shard** only when one node can't hold the data or the write volume. Shard **last** — it adds the most complexity.

## 5. One-Paragraph Summary (for quick revision)

Scale a database in roughly this order. **Indexing** (B-tree/hash) turns scans into fast lookups — great for reads, a small tax on writes. **Replication** copies data across nodes: **master–slave** sends writes to one leader and reads to replicas (watch **replication lag** / stale reads and failover), while multi-master and **quorum** (`R + W > N`) trade consistency vs availability. **Partitioning** splits data — **vertical** by columns, **horizontal (sharding)** by rows across nodes with a carefully chosen **shard key** (hash / consistent hashing to avoid hotspots), at the cost of hard cross-shard joins/transactions. Rule of thumb: index and cache first, add read replicas, and **shard last**.
