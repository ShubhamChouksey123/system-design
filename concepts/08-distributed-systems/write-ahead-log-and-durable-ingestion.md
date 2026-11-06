# Write-Ahead Log (WAL) & Durability-First Ingestion

---

The question behind every "design an ingestion pipeline" prompt that treats data loss as unacceptable (billing events, security telemetry, order events): **how do you guarantee a write survives a crash before you've finished processing it?** The answer is almost always the same primitive — append the write to a durable, sequential **log** *before* doing anything else with it, and rebuild state by **replaying** that log. This pairs with [consistency models](./consistency-models.md) (it's how a replica *catches up*) and [message queues](../07-messaging-and-events/message-queue.md) (a queue's durability is a WAL under the hood).

## 1. What a WAL is

A **write-ahead log (WAL)** is an **append-only, sequential** file: every mutation is written to it *before* it's applied to the actual data structure (an in-memory table, a B-tree page, an order book). Three properties make it the cheapest possible durability mechanism:

- **Sequential writes are fast** — no seeking, no random I/O; disks (even spinning ones) are good at appending.
- **A crash mid-write loses at most the last unflushed record**, never the whole data structure — on restart, replay the log from the last known-good point to rebuild state.
- **The log *is* the source of truth** — the in-memory/indexed view is a derived, rebuildable cache of it, not the other way around.

## 2. The write path

| Step | What happens | Why this order |
|---|---|---|
| 1. Append to WAL | Write the record to the log, `fsync` to disk | Durable before anything else touches it |
| 2. Ack the write | Caller is told "committed" | Caller's guarantee matches what's actually durable |
| 3. Apply to state | Update the in-memory structure / index / materialized view | Can be redone from the log if it's lost |
| 4. Checkpoint (periodic) | Snapshot applied state, truncate the log up to that point | Bounds replay time after a crash — otherwise the log grows forever |

Skip step 1 and ack before the disk write lands, and a crash between "ack" and "flush" silently loses an acknowledged write — the exact bug durability-first framing exists to prevent.

![Sequence diagram of a write ahead log workflow. A Client sends a write request to a Server Process. The Server Process appends the record to the Write Ahead Log on disk, which then fsyncs to disk, after which a note states the record is durable now and survives a crash from this point on. The Server Process then acknowledges the commit back to the Client. The Server Process then applies the record to the In Memory State or Index, with a note stating this is rebuildable by replaying the Write Ahead Log if lost. A highlighted region notes that a crash before the apply step is safe, because on restart the system replays the Write Ahead Log from the last checkpoint to rebuild the state, since the acknowledgement already matched durable data.](./diagrams/wal-write-path.png)

## 3. At-least-once delivery and why it's the honest default

A WAL/durable-log system can promise a record **will** be processed — but after a crash and replay, it may be processed **more than once** (the consumer crashed after processing but before marking its read position). This is **at-least-once delivery**: never silently drop a record, but tolerate the occasional duplicate. The alternative, **exactly-once**, requires coordinating the write and the offset-commit in one atomic step — expensive enough that most real systems choose at-least-once + **idempotent consumers** instead.

## 4. Idempotent consumers — making "maybe twice" safe

Since at-least-once is the realistic guarantee, the consumer must make reprocessing a no-op:

- **Idempotency key** — a unique ID per logical event (not per delivery attempt); the consumer checks "have I already applied this key?" before acting (e.g. a `(dedup_key)` unique constraint, or a Redis `SETNX`).
- **Natural idempotency** — design the operation so re-applying it changes nothing: `UPDATE balance = 100` (idempotent) vs `UPDATE balance = balance + 10` (not — applying twice double-counts).
- **Offset/cursor tracking** — a consumer records the last log position it successfully processed (`last_applied_offset`), and resumes *from* there, not from the start, after a restart.

Without one of these, "durable ingestion" just moves the data-loss bug from *lost writes* to *double-counted writes* — which is worse in a billing or security-event context, since it produces confidently wrong data instead of an obvious gap.

## 5. Event sourcing — the WAL as the entire data model

Taken further, some systems make the **log the only store of truth** and derive every view from replaying it — this is **event sourcing**. Instead of storing "current balance," you store every `Deposited`/`Withdrawn` event and compute the balance by replaying them (or periodically checkpointing a snapshot to avoid replaying from the beginning). This is the pattern behind an in-memory order-matching engine's durability story (see [session 11](../../practice/11-session/README.md)'s `Sequencer → append-only order log → cursor-engine → warm standby` spine) — the engine's state is disposable and rebuildable because the log isn't.

## 6. Real-world systems

| System | What the log is called | Notes |
|---|---|---|
| **PostgreSQL / MySQL (InnoDB)** | WAL / redo log | Classic DB durability primitive this pattern is named after |
| **Apache Kafka** | the partition log itself | A WAL exposed *as* the product — durability is the whole point |
| **Cassandra** | commit log | Same idea, feeds the in-memory memtable before SSTable flush |
| **Raft / Paxos replicated state machines** | replicated log | Consensus = agreeing on the log's order, then replaying it everywhere |
| **AWS DynamoDB Streams / Kinesis** | change/event stream | Downstream consumers replay it — the basis of **CDC** |
| **EventStoreDB** | event store | Event sourcing taken to a dedicated product |

## 7. In-the-room checklist

When a prompt says (or implies) "this data must never be lost":

- [ ] State the write path explicitly: **append to a durable log → ack → apply to state** — never ack before the log write is durable.
- [ ] Name the delivery guarantee: **at-least-once**, and say *why* (exactly-once needs atomic write+offset-commit, which is expensive at scale).
- [ ] Pair it with an **idempotency key** or **idempotent operation** on the consumer side — a WAL without this just relocates the bug.
- [ ] If asked "what happens on a crash?" — answer with **replay from the log / last checkpoint**, not "we'd lose the in-flight request."
- [ ] For a long-lived system, mention **checkpointing/snapshotting** so replay time stays bounded — an unbounded log replays forever after a long outage.

## 8. Do / Don't

- **Do** treat the in-memory or indexed view as a *cache* of the log — rebuildable, not authoritative.
- **Do** make the consumer's write operation idempotent rather than chasing exactly-once delivery.
- **Don't** ack a write before it's durably on disk — that's the single most common way this pattern gets silently broken.
- **Don't** confuse "durable" with "replicated" — a WAL on one disk is durable against a process crash, not a disk failure; combine it with replication (see [consistency models](./consistency-models.md)) for the latter.

## 9. One-Paragraph Summary (for quick revision)

A **write-ahead log (WAL)** makes a system durable cheaply: append every mutation to a sequential, durable log **before** applying it or acking the caller, and treat the actual data structure as a rebuildable cache of the log — on crash, **replay** from the last checkpoint. This naturally yields **at-least-once delivery** (a replay can reprocess an already-applied record), which is the honest, cheap default versus exactly-once (which needs an atomic write+offset-commit). Make reprocessing safe with **idempotent consumers** — an idempotency key, a natural-idempotent operation, or offset tracking — otherwise durability just trades data loss for silent double-counting, which is worse in a billing or security-event context. Taken to its extreme this becomes **event sourcing**, where the log *is* the data model and every view is derived by replay. Real systems expose this primitive directly or indirectly: **Postgres/MySQL's WAL**, **Kafka's partition log**, **Cassandra's commit log**, **Raft's replicated log**, and **DynamoDB Streams/CDC**. In an interview, naming this explicitly — append-before-ack, at-least-once, idempotent consumer, checkpointed replay — is the single most reliable signal that you're designing for "never lose this," not just "usually works."
