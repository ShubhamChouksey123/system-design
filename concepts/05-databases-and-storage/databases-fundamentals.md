 # Databases — Fundamentals

---

Data modeling and theory. Companion: [scaling databases](./databases-scaling.md) (indexing, replication, sharding).

## 1. What is a database?

A **database** is an organized, persistent store of data; a **DBMS** (Database Management System) is the software that manages storage, querying, concurrency, and durability. The datastore choice is usually the highest-impact decision in a system design.

## 2. Types of databases

| Type | Model | Examples | Best for |
|---|---|---|---|
| **Relational (SQL)** | Tables + rows, fixed schema, joins | PostgreSQL, MySQL | Structured data, transactions, complex queries |
| **NoSQL** | Non-relational (see below) | see below | Scale, flexible schema, high write throughput |
| **NewSQL** | SQL + ACID at NoSQL scale | Google Spanner, CockroachDB | Relational guarantees that scale horizontally |
| **Time-series** | Append-only, partitioned by series key + time, built-in downsampling/rollups | **Prometheus**, **InfluxDB**, AWS Timestream | Metrics, monitoring/alerting, IoT sensor data — write-heavy, range-scan reads |
| **Geospatial** | Maps lat/lng to a 1-D key (**geohash**: shared prefix = nearby) or a tree (quadtree, R-tree, S2/H3) | **Redis GEO**, PostGIS, Elasticsearch `geo_point` | "Nearest K / within radius" — drivers, restaurants, places |

**NoSQL families:**

| Family | Shape | Examples |
|---|---|---|
| **Key-value** | `key → value` | Redis, DynamoDB |
| **Document** | JSON-like documents | MongoDB |
| **Wide-column** | rows with dynamic columns | Cassandra, HBase |
| **Graph** | nodes + edges | Neo4j |

**Geospatial example — Redis GEO** stores members in a sorted set scored by their 52-bit geohash, so a radius query is a range scan:

```
GEOADD drivers:blr 77.5946 12.9716 D1                                      # upsert a driver's position
GEOSEARCH drivers:blr FROMLONLAT 77.60 12.97 BYRADIUS 3 km ASC COUNT 10   # nearest within 3 km
```

Geohash precision: 5 chars ≈ 5 km cell · 6 ≈ 1.2 km · 7 ≈ 150 m. Points near a cell edge can have different prefixes, so query the cell **plus its 8 neighbours**. Redis GEO is in-memory and has no per-member TTL (use a `last_seen` set + sweeper); use PostGIS for polygons or durable data. Worked use: [Session 20 dispatch](../../practice/20-session/README.md).

Deep dive on families, trade-offs, and use cases: [NoSQL databases](./nosql-databases.md).

## 3. SQL vs NoSQL — when?

- **SQL** — you need **ACID transactions**, complex joins/queries, and a well-defined schema (payments, orders, users).
- **NoSQL** — you need **horizontal scale**, flexible/evolving schema, or very high write throughput, and can relax joins/strong consistency (feeds, logs, catalogs, sessions).
- **Time-series** — your access pattern is "scan a time range for one series" (not point lookups) and the write volume is relentless — **Prometheus** (pull-based scraping, in-process + remote-write storage) and **InfluxDB** (push-based ingest) are the canonical examples; both compress well because consecutive values in one series are similar, and both build in **rollup/downsampling** so long-range queries don't scan raw resolution.

## 4. ACID properties

Guarantees for reliable transactions (classic in relational DBs):
- **Atomicity** — all steps commit, or none do.
- **Consistency** — a transaction moves the DB from one valid state to another (constraints hold).
- **Isolation** — concurrent transactions don't interfere; tuned via **isolation levels** (read committed → repeatable read → serializable, trading concurrency for correctness).
- **Durability** — once committed, data survives crashes (persisted, often via a **write-ahead log**).

## 5. CAP theorem

In a distributed store, during a **network partition** you can keep only **two** of three: **C**onsistency, **A**vailability, **P**artition tolerance. Since partitions are unavoidable, the real choice is **C vs A** when one happens:
- **CP** — refuse some requests to stay consistent (HBase, MongoDB default).
- **AP** — stay available, serve possibly-stale data (Cassandra, DynamoDB).

Related: **BASE** (Basically Available, Soft state, Eventual consistency) is the NoSQL counterpart to ACID; **PACELC** adds that even without a partition you trade **latency vs consistency**.

## 6. Normalization vs denormalization

- **Normalization** — split data into related tables to remove redundancy (1NF → 3NF). Fewer update anomalies, but reads need **joins**. Default for write-heavy / OLTP.
- **Denormalization** — deliberately duplicate data to avoid joins → **faster reads**, at the cost of more storage and harder writes (copies must be kept in sync). Common in read-heavy systems and NoSQL.

## 7. One-Paragraph Summary (for quick revision)

A **database** stores data persistently, managed by a **DBMS**. Pick **relational (SQL)** for structured data with **ACID** transactions and joins, **NoSQL** (key-value, document, wide-column, graph) for horizontal scale and flexible schema, **NewSQL** for both, or a **time-series database** (Prometheus, InfluxDB) when the access pattern is "scan a time range per series" at relentless write volume. **ACID** (atomicity, consistency, isolation, durability) governs reliable transactions; the **CAP theorem** says a distributed store must choose **consistency vs availability** during a partition (CP vs AP), with **BASE** / eventual consistency the NoSQL trade-off. **Normalize** to remove redundancy (more joins, safer writes) or **denormalize** to speed reads (duplicated data, harder writes). For "nearby" queries use a **geospatial** index (geohash in Redis GEO, or PostGIS). See the companion for indexing, replication, and sharding.
