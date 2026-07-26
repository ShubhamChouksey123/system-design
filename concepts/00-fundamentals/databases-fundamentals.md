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

**NoSQL families:**

| Family | Shape | Examples |
|---|---|---|
| **Key-value** | `key → value` | Redis, DynamoDB |
| **Document** | JSON-like documents | MongoDB |
| **Wide-column** | rows with dynamic columns | Cassandra, HBase |
| **Graph** | nodes + edges | Neo4j |

## 3. SQL vs NoSQL — when?

- **SQL** — you need **ACID transactions**, complex joins/queries, and a well-defined schema (payments, orders, users).
- **NoSQL** — you need **horizontal scale**, flexible/evolving schema, or very high write throughput, and can relax joins/strong consistency (feeds, logs, catalogs, sessions).

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

A **database** stores data persistently, managed by a **DBMS**. Pick **relational (SQL)** for structured data with **ACID** transactions and joins, **NoSQL** (key-value, document, wide-column, graph) for horizontal scale and flexible schema, or **NewSQL** for both. **ACID** (atomicity, consistency, isolation, durability) governs reliable transactions; the **CAP theorem** says a distributed store must choose **consistency vs availability** during a partition (CP vs AP), with **BASE** / eventual consistency the NoSQL trade-off. **Normalize** to remove redundancy (more joins, safer writes) or **denormalize** to speed reads (duplicated data, harder writes). See the companion for indexing, replication, and sharding.
