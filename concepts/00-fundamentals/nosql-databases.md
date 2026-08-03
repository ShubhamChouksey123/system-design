# NoSQL Databases

---

A deeper look at non-relational stores. Companion to [databases — fundamentals](./databases-fundamentals.md) (SQL vs NoSQL, ACID, CAP).

## 1. What & why

**NoSQL** ("not only SQL") = non-relational databases built for **horizontal scale, flexible/evolving schemas, and high write throughput**. They typically trade strict **ACID** for **BASE** (Basically Available, Soft state, Eventual consistency) and lean toward **availability + partition tolerance** (AP) over strong consistency — see [CAP](./databases-fundamentals.md). There are **no joins**: you **denormalize** and model data around your access patterns up front.

## 2. Types & use cases

| Type | Data model | Best-fit use cases | Examples |
|---|---|---|---|
| **Key-value** | `key → opaque value`; O(1) get/put, no query on value | caching, sessions, feature flags, rate-limit counters | Redis, DynamoDB, Riak |
| **Document** | self-contained **JSON/BSON** docs; query on fields, nested | user profiles, catalogs, CMS, config | MongoDB, Couchbase, Firestore |
| **Wide-column** | partition key + **dynamic columns** (column families) | time-series, IoT/event logs, messaging, feeds at massive scale | Cassandra, HBase, Bigtable |
| **Graph** | **nodes + edges** first-class; fast multi-hop traversal | social graphs, recommendations, fraud rings, knowledge graphs | Neo4j, Neptune, JanusGraph |

- **Key-value** is the simplest/fastest but you can only look up by key.
- **Document** is the most general-purpose NoSQL choice.
- **Wide-column** wins on write volume + horizontal scale (uses [consistent hashing](./load-balancing-and-consistent-hashing.md)).
- **Graph** is the only one optimized for **relationships** — "friends of friends" is O(hops), not a costly join.

## 3. Advantages & disadvantages

| Advantages | Disadvantages |
|---|---|
| **Horizontal scale-out** on commodity nodes | **Weaker consistency** (usually eventual) |
| **Flexible/evolving schema** — no migrations to add fields | **No joins / limited ad-hoc queries** — model for access patterns |
| **High write throughput** | **No standard query language** — varies per database |
| **High availability** (AP; survives partitions) | **Data duplication** from denormalization |
| Handles **unstructured / semi-structured** data | **Weaker multi-record transactions** than SQL |

## 4. When to use NoSQL (and when not)

- **Reach for NoSQL** when: you need **massive scale / high write volume**, the schema is **fluid**, access patterns are **known and simple** (lookup by key/partition), data is **unstructured**, or **availability** matters more than strong consistency.
- **Stick with SQL** when: you need **complex queries/joins**, **strong ACID transactions** (payments, inventory), a **well-defined relational** model, or flexible **ad-hoc analytics**.
- **Polyglot persistence** is common: use each store where it fits (e.g. Postgres for orders + Redis for sessions + Cassandra for the event log).

## 5. One-Paragraph Summary (for quick revision)

**NoSQL** databases are non-relational stores built for **horizontal scale, flexible schemas, and high write throughput**, usually trading ACID for **BASE**/eventual consistency (AP under CAP) and replacing joins with **denormalized, access-pattern-driven** modeling. Four families: **key-value** (caching/sessions — Redis, DynamoDB), **document** (profiles/catalogs — MongoDB), **wide-column** (time-series/feeds at scale — Cassandra, HBase), and **graph** (relationships/recommendations — Neo4j). They win on scale, schema flexibility, availability, and unstructured data, but cost consistency guarantees, joins/ad-hoc queries, and strong transactions. Choose NoSQL for massive-scale, fluid-schema, known-access-pattern workloads; keep SQL for complex queries and strong transactions — and mix both (**polyglot persistence**) when it fits.
