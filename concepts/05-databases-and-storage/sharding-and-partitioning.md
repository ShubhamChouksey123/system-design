# Sharding / Partitioning

---

When one database can no longer hold all the data — or take all the writes — you **split it into pieces**. **Partitioning** is that split in general; **sharding** is partitioning **across separate machines**. This is the deep dive on the "shard last" step in [database scaling](./databases-scaling.md); it leans on [consistent hashing](../03-networking-and-delivery/load-balancing-and-consistent-hashing.md) and shows up in every [NoSQL](./nosql-databases.md) store.

## 1. Partitioning vs sharding

- **Vertical partitioning** — split by **columns**: move big or rarely-used columns (or whole tables) to their own store. Good first step; limited ceiling.
- **Horizontal partitioning** — split by **rows**: each partition holds a *subset of the rows* (e.g. users A–M vs N–Z).
- **Sharding** = horizontal partitioning where the partitions live on **different machines** ("shards"), so you scale storage *and* throughput, not just organization.

The row is placed by a **shard key** (also called a partition key) — the column whose value decides which shard a row lands on.

## 2. Sharding strategies

| Strategy | How rows are placed | Pro | Con |
|---|---|---|---|
| **Range** | by key ranges (A–M, N–Z; dates) | fast **range scans** | **hotspots** — recent/popular ranges get hammered |
| **Hash** | `hash(key) % N` | **even** spread, no hotspots | range queries scatter; **adding a shard reshuffles almost everything** |
| **Consistent hashing** | keys + nodes on a ring | even spread **and** minimal movement when resizing | more complex; needs virtual nodes for balance |
| **Directory / lookup** | a lookup table maps key → shard | flexible, easy to rebalance | the lookup table is an extra hop + a **single point of failure** |
| **Geo** | by region (EU, US) | data near users, compliance | uneven if traffic is regional |

**Consistent hashing** is the usual answer for "hash, but I need to add/remove nodes without re-sharding everything" — only `keys/N` move instead of nearly all of them.

## 3. Choosing the shard key (the whole game)

A good shard key has three traits:

- **High cardinality** — many possible values, so data divides finely (user ID ✅; country ❌ — only ~200 values).
- **Even distribution** — no single value dominates, or that shard becomes a hotspot.
- **Matches the query pattern** — you want common queries to hit **one shard**. Shard orders by `customer_id` if you usually query "orders for a customer."

A bad key is worse than no sharding: e.g. sharding by **`status`** (only a few values) piles most rows on one shard.

## 4. The hard parts (why you shard *last*)

- **Cross-shard queries** — a query spanning shards must **fan out** to all of them and merge results (scatter-gather) — slow. Joins often move into **application code**.
- **Cross-shard transactions** — no single-node ACID across shards; you need **two-phase commit** (slow, locking) or a **[Saga](../08-distributed-systems/single-point-of-failure.md)** (eventual). Avoid designs that need them.
- **Rebalancing / resharding** — adding shards must move data; **consistent hashing** minimizes it. Pre-split into many logical shards early so you rebalance by *moving* shards, not re-hashing.
- **Hot key / "celebrity" problem** — one key (a viral user) overwhelms its shard. Mitigate by **splitting** that key's data or adding a cache in front.

## 5. Real-world technologies

| System | Sharding approach |
|---|---|
| **MongoDB** | built-in sharding by a shard key (range or hashed) |
| **Cassandra / DynamoDB** | **partition key** hashed onto a ring (consistent hashing) |
| **Vitess** (YouTube's MySQL) | horizontal sharding layer over MySQL |
| **Citus** | sharding extension for PostgreSQL |
| **Elasticsearch** | index split into shards + replicas |

## 6. When to use what

- **Don't shard yet** if replicas + caching + a bigger box still cope — sharding adds the most operational complexity of any scaling step.
- **Range** → time-series / ordered scans, if you can tolerate hotspots on recent data.
- **Hash / consistent hashing** → default for even load and elastic scaling (most NoSQL).
- **Directory** → when the mapping must be flexible or move keys freely.
- **Geo** → latency or data-residency (GDPR) requirements.

## 7. One-Paragraph Summary (for quick revision)

**Partitioning** splits a dataset; **sharding** spreads those partitions across **machines** to scale storage and write throughput. Split **vertically** (by columns) as an easy first step, but real scale comes from **horizontal** sharding by a **shard key**. Pick the key carefully — **high cardinality, even distribution, and aligned with your queries** — because a bad key (few values like `status`) creates a **hotspot** and is worse than not sharding. Placement strategies trade off: **range** enables scans but hotspots on popular ranges; **hash** spreads evenly but scatters range queries and reshuffles on resize; **consistent hashing** keeps the even spread while moving only `keys/N` when nodes change; a **directory** is flexible but an extra hop and SPOF; **geo** puts data near users. The catch — and why you **shard last** — is that **cross-shard queries fan out** and **cross-shard transactions need 2PC or Sagas**, so design to keep related data on one shard. In practice: MongoDB, Cassandra/DynamoDB (partition key on a ring), Vitess (MySQL), and Citus (Postgres).
