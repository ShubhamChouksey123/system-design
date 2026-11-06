# Apache Kafka

---

A deeper look at the broker that shows up in almost every design. Kafka is the concrete implementation behind much of the [message queue](./message-queue.md) concept — read that first for the general model.

## 1. What is Kafka?

**Apache Kafka** is a distributed, durable, **append-only commit log** built for high-throughput event streaming. Unlike a traditional queue that *deletes* a message once consumed, Kafka **retains** messages for a configured period and lets many independent consumers read (and re-read) them at their own offset. It routinely handles **millions of messages/sec**.

Think of it as a replayable log, not a mailbox.

## 2. Core concepts

| Term | What it is |
|---|---|
| **Broker** | A Kafka server; a **cluster** is many brokers. In production each broker runs on its **own machine** (or VM/pod) — never co-located on one host — so a single machine failure doesn't take down the partitions it hosts |
| **Topic** | A named stream of messages (a logical log) |
| **Partition** | A topic is split into partitions — the unit of **parallelism, ordering, and replication** |
| **Offset** | A message's sequential position within a partition |
| **Producer** | Writes messages; picks a partition (round-robin or by **key**) |
| **Consumer** | Reads messages, tracking its **offset** per partition |
| **Consumer group** | Consumers sharing the load — each partition goes to **one** consumer in the group |

```
Topic "orders"
  Partition 0:  [o0][o1][o2][o3 ...   ← append-only, each has an offset
  Partition 1:  [o0][o1][o2 ...
```

## 3. Ordering, parallelism & delivery

- **Ordering** is guaranteed **only within a partition** — send messages that must stay ordered with the same **key** (e.g. `orderId`) so they land in one partition.
- **Parallelism** scales with partition count: add consumers up to the number of partitions.
- **Delivery** is **at-least-once** by default; Kafka also supports **exactly-once** semantics (idempotent producer + transactions). Make consumers **idempotent** regardless.

## 4. Durability: replication & leader election

Each partition is **replicated** across brokers (replication factor, commonly ×3):
- One replica is the **leader** (all reads/writes); the rest are **followers** that replicate it.
- The **ISR** (in-sync replicas) are followers caught up with the leader. If the leader's broker dies, a new leader is **elected from the ISR** — no data loss, partition stays available.
- Coordination (metadata, membership, election) uses **Apache Zookeeper** in classic Kafka; newer versions use built-in **KRaft** (Raft-based, no Zookeeper).

**Worked example** — a 5-broker cluster (`broker-1` … `broker-5`, each on its own machine) with a topic `user_creation` created at **3 partitions, replication factor 3**:

| Partition | Leader | Followers (ISR) |
|---|---|---|
| `user_creation-0` | `broker-1` | `broker-2`, `broker-3` |
| `user_creation-1` | `broker-2` | `broker-3`, `broker-4` |
| `user_creation-2` | `broker-3` | `broker-4`, `broker-5` |

Each partition has 3 copies on 3 **different** brokers, and leadership is spread across brokers rather than piled onto one — so no single broker is a bottleneck for all writes. If `broker-1` dies, `user_creation-0` fails over to an ISR member (`broker-2` or `broker-3`) with zero data loss; `broker-4` and `broker-5` can be down at the same time and every partition still has a majority of its replicas alive. A producer sending `{ userId: "u123", event: "created" }` with key `userId` always lands on the same partition for that user, so every event for `u123` stays in order.

## 5. Retention & replay (Kafka's superpower)

- Messages are kept for a **retention period** (e.g. 7 days) or size cap — consumers can **replay** by resetting their offset. Great for reprocessing, new consumers, and debugging.
- **Log compaction** — instead of time-based deletion, keep only the **latest value per key** (e.g. a changelog / current-state topic).

## 6. Monitoring — the signals that actually matter

Naming "we'll monitor it" is half-credit — a Kafka-backed design should name these signals and their alert condition explicitly (see [Observability](../09-reliability-and-operations/observability.md)):

| Signal | What it means | Alert when |
|---|---|---|
| **Consumer lag** | How far a consumer group's offset trails the latest written offset, per partition | Lag is **growing**, not draining — the earliest sign a consumer can't keep up with producers |
| **Under-replicated partitions** | Partitions where the ISR has fewer replicas than the replication factor | **> 0**, sustained — a broker is down, slow, or network-partitioned |
| **Offline partitions** | Partitions with **no leader at all** | **> 0**, ever — the partition is unavailable for reads/writes right now |
| **Active controller count** | Should be exactly **1** cluster-wide | **≠ 1** — signals a split-brain or controller election in progress |
| **Bytes in/out per sec**, per topic/partition | Throughput, and the fastest way to spot a **hot partition** | One partition's rate far exceeds its peers (key/partitioning skew) |
| **Request latency (p99)** — produce, fetch | Time a broker takes to ack a write / serve a read | Approaching the client's own timeout, or a sustained upward trend |
| **Log/disk usage per broker** | How close a broker is to running out of retention headroom | Approaching the configured retention size cap before the time-based cap kicks in |

**Consumer lag is the one to lead with** — it's the single number that tells you whether the "worked example" cluster above is actually keeping up, and it's exactly the kind of concrete signal this tracker's [Component Checklists](../../practice/answer-framework.md#component-checklists--what-to-say-every-time-this-component-appears) expects for any message-queue component, not just Kafka.

## 7. When to use — and not

**Use Kafka for:** high-throughput event streaming, activity/log/metrics pipelines, event sourcing, decoupling microservices, feeding stream processors (Flink, Kafka Streams), and any case needing **replay**.

**Avoid it when:** you need per-message routing/priorities or a simple task queue (RabbitMQ/SQS fit better), you need request/reply, or the operational weight of a cluster isn't justified.

## 8. One-Paragraph Summary (for quick revision)

**Apache Kafka** is a distributed, append-only **commit log** for high-throughput event streaming — it **retains** messages so many consumers can read and **replay** them by offset, unlike a delete-on-read queue. A **topic** is split into **partitions** (the unit of parallelism, ordering, and replication); producers key messages into partitions, consumers in a **consumer group** each own some partitions and track **offsets**. Durability comes from **replication** with a **leader** elected from the **ISR** (coordinated by Zookeeper, or newer **KRaft**). **Retention** and **log compaction** enable replay and changelog use-cases. Operating one means watching **consumer lag**, **under-replicated/offline partitions**, and **per-broker throughput** as first-class signals, not an afterthought. Reach for Kafka for streaming, event sourcing, and decoupling at scale — but use RabbitMQ/SQS for simple task queues, routing, or request/reply.
