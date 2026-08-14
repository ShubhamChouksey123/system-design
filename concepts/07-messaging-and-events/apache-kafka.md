# Apache Kafka

---

A deeper look at the broker that shows up in almost every design. Kafka is the concrete implementation behind much of the [message queue](./message-queue.md) concept — read that first for the general model.

## 1. What is Kafka?

**Apache Kafka** is a distributed, durable, **append-only commit log** built for high-throughput event streaming. Unlike a traditional queue that *deletes* a message once consumed, Kafka **retains** messages for a configured period and lets many independent consumers read (and re-read) them at their own offset. It routinely handles **millions of messages/sec**.

Think of it as a replayable log, not a mailbox.

## 2. Core concepts

| Term | What it is |
|---|---|
| **Broker** | A Kafka server; a **cluster** is many brokers |
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

## 5. Retention & replay (Kafka's superpower)

- Messages are kept for a **retention period** (e.g. 7 days) or size cap — consumers can **replay** by resetting their offset. Great for reprocessing, new consumers, and debugging.
- **Log compaction** — instead of time-based deletion, keep only the **latest value per key** (e.g. a changelog / current-state topic).

## 6. When to use — and not

**Use Kafka for:** high-throughput event streaming, activity/log/metrics pipelines, event sourcing, decoupling microservices, feeding stream processors (Flink, Kafka Streams), and any case needing **replay**.

**Avoid it when:** you need per-message routing/priorities or a simple task queue (RabbitMQ/SQS fit better), you need request/reply, or the operational weight of a cluster isn't justified.

## 7. One-Paragraph Summary (for quick revision)

**Apache Kafka** is a distributed, append-only **commit log** for high-throughput event streaming — it **retains** messages so many consumers can read and **replay** them by offset, unlike a delete-on-read queue. A **topic** is split into **partitions** (the unit of parallelism, ordering, and replication); producers key messages into partitions, consumers in a **consumer group** each own some partitions and track **offsets**. Durability comes from **replication** with a **leader** elected from the **ISR** (coordinated by Zookeeper, or newer **KRaft**). **Retention** and **log compaction** enable replay and changelog use-cases. Reach for Kafka for streaming, event sourcing, and decoupling at scale — but use RabbitMQ/SQS for simple task queues, routing, or request/reply.
