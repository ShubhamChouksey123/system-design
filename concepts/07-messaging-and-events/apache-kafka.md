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

## 7. Scaling for a sudden traffic spike

The honest answer splits on **how long the spike lasts**, because the levers available in seconds are different from the ones available over hours — and mixing them up makes a spike worse, not better.

| Lever | Time to take effect | Use when | Trade-off / caveat |
|---|---|---|---|
| **Do nothing — let retention absorb it** | Instant | The spike is short-lived and the topic's **retention window** has headroom | **Consumer lag** rises temporarily (freshness degrades), but no data is lost — this is Kafka's actual superpower during a burst: the log *is* the buffer |
| **Scale out consumers** (add instances to the consumer group, up to the partition count) | Seconds | The spike is write-heavy and `consumers < partitions` | Hard-capped by partition count — a 6th consumer on a 5-partition topic sits idle; this is why you provision partitions for peak, not average (§ below) |
| **Rate-limit / reject at the producer edge** | Instant | Brokers themselves are saturated (disk or network I/O), not just a slow consumer | Trades some writes (rejected/throttled) for protecting the cluster — the same **reject-over-queue-indefinitely** trade-off this tracker uses elsewhere when a non-functional requirement explicitly tolerates small data loss |
| **Add partitions to the topic** | Minutes, but changes behavior | The spike reveals you're genuinely under-partitioned **going forward**, not just for this one burst | Partition count only **grows**, never shrinks, and an existing key now maps to a *different* partition — breaks per-key ordering continuity. Plan this ahead of a known peak, don't do it reactively mid-incident |
| **Add brokers + reassign partitions** | Hours (real data movement across the network) | Sustained growth, not a sudden spike | The rebalance itself consumes disk and network I/O — doing this *during* the spike competes with the spike for the same resources and can make latency worse before it gets better |

**The real fix is upfront, not reactive:** size partition count for **peak**, not average, using the same `Peak ≈ 2× Average` convention as [envelope estimation](../01-envelope-estimation/back-of-the-envelope-estimation.md). For the `user_creation` topic from the worked example above: if average throughput is 5,000 msgs/sec and a single partition sustains roughly that, `Peak ≈ 10,000 msgs/sec` needs **at least 2 partitions just to survive peak** — the topic's actual 3 partitions give one partition of headroom. Decide the partition count from the peak number *before* the spike happens; by the time a real spike hits, "add partitions" and "add brokers" are both too slow to be the first response — **consumer autoscaling (fast) and retention-as-buffer (instant) are what you reach for in the moment**, and they only work because the partition count was sized correctly ahead of time.

## 8. When to use — and not

**Use Kafka for:** high-throughput event streaming, activity/log/metrics pipelines, event sourcing, decoupling microservices, feeding stream processors (Flink, Kafka Streams), and any case needing **replay**.

**Avoid it when:** you need per-message routing/priorities or a simple task queue (RabbitMQ/SQS fit better), you need request/reply, or the operational weight of a cluster isn't justified.

## 9. One-Paragraph Summary (for quick revision)

**Apache Kafka** is a distributed, append-only **commit log** for high-throughput event streaming — it **retains** messages so many consumers can read and **replay** them by offset, unlike a delete-on-read queue. A **topic** is split into **partitions** (the unit of parallelism, ordering, and replication); producers key messages into partitions, consumers in a **consumer group** each own some partitions and track **offsets**. Durability comes from **replication** with a **leader** elected from the **ISR** (coordinated by Zookeeper, or newer **KRaft**). **Retention** and **log compaction** enable replay and changelog use-cases. Operating one means watching **consumer lag**, **under-replicated/offline partitions**, and **per-broker throughput** as first-class signals, not an afterthought. A sudden spike is absorbed **instantly** by retention and fast consumer autoscaling, never by adding partitions or brokers mid-incident — those are hours-scale moves planned ahead of peak, not seconds-scale reactions. Reach for Kafka for streaming, event sourcing, and decoupling at scale — but use RabbitMQ/SQS for simple task queues, routing, or request/reply.
