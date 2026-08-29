# Session 09 — Real-Time Chat Application (WhatsApp / Slack style) · ✅ 7.5/10
x
> A scored, analyzed system-design mock — and a **milestone**: the **first clear Pass (✅ 7.5)** in the log, up a **full point** from [S08](../08-session/README.md)'s 6.5 Borderline on the **same question**. This is the re-solve the tracker explicitly called for, and it worked: the two crux problems that held S08 to Borderline — **connection routing** and the **offline/failover recovery path** — were both solved *unprompted* this time, and the candidate independently reproduced nearly the entire S08 **ideal design** (WebSocket gateways + a **Session Store** presence registry, a **Kafka + Delivery Worker** backbone, `conversation_id` sharding, per-conversation `seq_no` ordering, signed-S3-URL + compression, SNS/FCM offline push, read-replica + cache, Redis for ephemeral activity). What keeps it at a *solid* pass rather than a strong one is now **finer**: the **message/file ordering** fix (denormalize into one table) needed a nudge, **trade-offs were reactive** (consistency-over-availability, batching, caching all arrived when asked, not volunteered), the **delivery guarantee stopped at "Kafka is at-least-once"** without the per-recipient cursor + `message_id` dedup that makes it exact, and **advanced failure handling** (connection draining, replication strategy) stayed shallow. The **fan-out model** (push vs pull for large groups) is still unnamed. The habits transfer; the next tier is depth and proactivity.

| | |
|---|---|
| **Problem** | Design a real-time chat app like WhatsApp / Slack — millions of concurrent users, group chats, file sharing, delivery guarantees |
| **Focus** | Routing to millions of persistent connections + end-to-end delivery, online and offline |
| **Overall** | **7.5 / 10** — ✅ Pass — ▲ 1.0 vs S08's 6.5 (the first pass in the log; a strong pass sits at 8+) |
| **Weakest areas** | Scalability & Trade-offs (7.0), Problem-Solving (7.5) — both now *above* the pass bar |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |

## The problem

> Design a **real-time chat application** like **WhatsApp or Slack** that supports **millions of concurrent users**, **group chats**, **file sharing**, and **message delivery guarantees**.

A chat app looks like a CRUD-over-messages problem and is actually a **stateful-connection-routing** problem. The recipient holds a **persistent connection to one specific server out of hundreds**; the moment a message is written, the system must **find that server and push the message down that exact socket** in milliseconds, for millions of simultaneous connections. Two questions decide the design: **(1) when a message arrives for user X, which connection server is X attached to** (a presence/session registry + routing), and **(2) how do you guarantee delivery even if X is offline, reconnecting, or on a flaky network** (persist-then-ack + a per-recipient sync cursor + offline push). This is a **re-attempt of the [S08](../08-session/README.md) prompt** after drilling exactly those two gaps — so the story of this page is whether the fixes landed.

## Requirements & estimation

- **Functional** — **1:1 messaging**, **group messaging**, **file sharing**, **message status** (sent / received / read), **online & last-seen** presence, **reading old conversations** (history), and **notifications to the receiver** on a new message. A comprehensive, senior-level cut — status and presence were named upfront this time, not bolted on.
- **Out of scope (stated upfront)** — **encryption of chats** and **block/unblock**. Naming the boundary is a good scoping habit.
- **Non-functional** — **low latency (feels instantaneous) · highly available · scalable · resilient · fault-tolerant.** Right list; latency correctly leads.
- **Estimation** — 10M total · **5M DAU** (50%) · **500 messages/user/day** · 10% files → 50 file-messages/user/day → **~2.5B messages/day → ~25k QPS average, ~50k peak**. Files: average **10 MB** (2 MB images, 20 MB video) → **~2.5 PB/day** of media (912 PB/year). **And — the number S08 missed — ~1M concurrent connections** (20% of DAU online at peak). That concurrent-connection figure is the one that actually designs the system, and it was computed this time.

![Requirements canvas for a chat application. The problem is to design a real-time chat application like WhatsApp or Slack supporting millions of concurrent users, group chats, file sharing, and message delivery guarantees. Functional requirements list one-to-one chat messages, messages in a group, file sharing, message status of sent received or read by receiver, online and last seen status of a person, reading old conversations, and sending notifications to a receiver when a new message is sent. Non-functional requirements list low latency feeling instantaneous, highly available, scalable, resilient, and fault tolerant. Out of scope features are encryption of chats and block or unblock user. The estimations block derives 10 million total users, 5 million daily active users at 50 percent, 500 messages per user per day, 10 percent or 50 file messages per user per day, a throughput of about 25 thousand queries per second average and 50 thousand peak, an average file size of 10 megabytes, daily storage of about 2.5 petabytes, yearly storage of 912 petabytes, and about 1 million concurrent active users at 20 percent of daily active users. A schema block lists User with id name bio created_at, Group with id and member_user_id, Message with id sender_id conversation_id text_message created_at sequence_id, File with id sender_id aws_s3_url created_at sequence_id, User Activity with user_id last_active_at, and Session_info with user_id connected_api_gateway_id](./diagrams/requirements.png)

## The design I produced

![Architecture canvas for the chat application. User A the sender connects by WebSocket to an API Gateway WebSocket Gateway A and receives an ack sent. The gateway forwards to a Message Writer Service, which writes the message to a Message Store and returns a message_id and sequence_id in the conversation, and which also emits write message events to a Kafka Message Queue and updates the sender last activity timestamp in a User Activity store. The Message Store replicates to a Message Store Read Replica. A Message Read Service reads a Cache and, only on cache miss, the read replica, so users can read older conversations. A Delivery Worker consumes read message events from Kafka, fetches member information from a Group Member Info Store for groups, looks up each destination user's connected gateway in a Session Store, and updates the receiver last activity timestamp. For online users the worker sends the notification to the receiver's gateway which pushes ws receive message to User B, who acks received; for offline users the worker routes to AWS SNS or Google FCM which sends a push notification to User C. For files, User C posts an upload-file request to its gateway which calls the Message Writer Service that returns a signed S3 upload URL and a file_id; User C uploads the file directly to AWS S3 using the signed URL; an S3 upload event flows through a Kafka Message Queue to a File Compressor and Transcode service that uploads the compressed file back to S3 and updates the database with the file_id and S3 path; the recipient later does a GET read file through a CDN that falls back to S3 on cache miss](./diagrams/architecture.png)

- **API Gateway (WebSocket)** — terminates the persistent socket; **stateless**, so a client can connect to any instance. Correctly identified as the connection tier.
- **Message Writer Service** — writes to the **Message Store**, returns `message_id` + `sequence_id`, **acks the sender** ("sent"), and **emits a write event to Kafka**. Also updates the sender's last-activity timestamp.
- **Kafka + Delivery Worker (the S08 fix, now present)** — the writer produces one event; a **Delivery Worker** consumes it, expands group members via the **Group Member Info Store**, looks up each recipient's gateway in the **Session Store** (`user_id → connected_api_gateway_id`), and routes to the owning gateway. **This is exactly the presence-registry + pub-sub routing S08 was missing.**
- **Offline path** — if the recipient isn't in the Session Store, the worker routes to **AWS SNS / Google FCM** to wake the device.
- **Failover recovery (the other S08 fix)** — a gateway dies → clients reconnect to a new instance → **resume from the stored `sequence_id`** via the Message Read Service. The reconnect *is* the recovery path — stated unprompted.
- **Read path** — **Message Read Service → Cache → (cache miss) read replica** for scrolling older history.
- **File path** — signed **S3** upload URL + `file_id`, direct client upload, a **Kafka compression/transcode pipeline**, and a **CDN** (cache-miss → S3) for reads.
- **User Activity Store** — `user_id → last_active_at` in **Redis**; online/last-seen derived from the timestamp delta. Correctly chosen as ephemeral, write-heavy KV.
- **Sharding & ordering** — Message Store sharded by **`conversation_id`** (whole conversation co-located), ordered by an auto-generated per-conversation **`sequence_id`**; correctly argued that same-conversation writes never cross shards.

## Scorecard

| Axis | S08 | **S09** | Δ |
|---|:--:|:--:|:--:|
| Requirements Gathering | 7.0 | **8.0** | ▲ 1.0 |
| Design Skills | 7.0 | **8.0** | ▲ 1.0 |
| Problem-Solving | 6.0 | **7.5** | ▲ 1.5 |
| Scalability & Trade-offs | 6.0 | **7.0** | ▲ 1.0 |
| Communication | 7.0 | **8.0** | ▲ 1.0 |
| **Overall** | 6.5 | **7.5** | ▲ 1.0 |

> **Every axis rose, and all five now sit at or above the pass bar (≥7).** The re-solve worked because the two crux misses were *closed*, not patched: **connection routing** (Session Store + Delivery Worker) and **failover recovery** (reconnect + `sequence_id` resume) were both volunteered. Problem-Solving jumped **▲1.5** — the biggest single-axis gain in the log — on independent saves (file-compression metadata, User Activity Store design, a correct push-back on cross-shard ordering). The remaining gap is **finer than any prior session**: depth on failure/replication, *proactive* trade-offs, and upfront schema care — the difference between a solid pass and a strong one, not between pass and fail.

## What lost points — and the fix

| What I missed in the room | The answer a senior would give | Study |
|---|---|---|
| **Message/file ordering needed prompting** — separate `Message` and `File` tables, each with its own `sequence_id`, can't be interleaved into one timeline | **Denormalize into one `messages` table** with a **single per-conversation `seq_no`** and a `type` column; file-specific fields (`file_id`, `s3_url`) are **nullable** for text. One counter = one correct order. Design this *upfront* — it's the crux table. | [Databases](../../concepts/05-databases-and-storage/databases-fundamentals.md) |
| **Delivery guarantee stopped at "Kafka is at-least-once"** — that's the *pipeline* guarantee, not the *device* guarantee | **Persist-then-ack + a per-recipient sync cursor** (`last_delivered_seq` per user per conversation): "delivered" only on the client's ack; **re-send unacked on reconnect**; client **dedups by `message_id`**. At-least-once + idempotent = effectively exactly-once *to the device*. | [Message Queue](../../concepts/07-messaging-and-events/message-queue.md) |
| **Trade-offs were reactive** — consistency-vs-availability, batching session lookups, caching group membership all arrived *when asked* | **Volunteer them.** "For chat I'll take **availability over consistency** on the message store, ordered per conversation by `seq_no`; group fan-out **batches** presence lookups and **caches** membership." Saying the risk + mitigation before being probed is the Lean-Hire→Hire signal. | [Consistency Models](../../concepts/08-distributed-systems/consistency-models.md) |
| **Fan-out model never named** — a 1000-member group is 1000 deliveries; "multiple Kafka consumers + batching" scales the *worker*, not the *model* | State the choice: **write fan-out (push)** for small groups, **read fan-out (pull)** for large channels (members read the shard on open), **hybrid** with presence-aware push. It's the decision that sizes the delivery tier. | [Message Queue](../../concepts/07-messaging-and-events/message-queue.md) |
| **Failure handling stayed shallow** — reconnect was covered, but **connection draining** during a rolling deploy and the **replication strategy** were not | On graceful shutdown, **drain**: stop accepting new sockets, signal clients to reconnect elsewhere, hand off before terminating (vs. a hard crash's mass reconnect). Replicate the message store **×3** cross-AZ; the read replica is async, so route read-your-writes to the primary. | [Single Point of Failure](../../concepts/08-distributed-systems/single-point-of-failure.md) |
| **File metadata association was solved but stored loosely** — "store sender/receiver metadata in S3 with the file" | Better: the **durable message carries an opaque `file_id`** (never a URL); the file/media service owns `file_id → renditions` and mints a **fresh signed CDN URL at read time**. Metadata lives with the message row, not smuggled into the blob. | [Object / Blob Storage](../../concepts/05-databases-and-storage/object-blob-storage.md) |

## What went well

This reads as a candidate who **drilled the right things and delivered them** — the clearest progress signal in the log:

- **The two S08 crux misses are gone.** **Connection routing** (Session Store `user_id → gateway_id` + Delivery Worker routing to the owning gateway) and **failover recovery** (reconnect + `sequence_id` resume) were both produced *unprompted* — the exact gaps that held S08 to Borderline.
- **The design independently matched the S08 ideal.** Kafka backbone + Delivery Worker, `conversation_id` sharding, per-conversation `sequence_id`, signed-S3 + compression pipeline, CDN reads, read-replica + cache, Redis for ephemeral activity — reproduced from established reasoning, not memorized.
- **Independent problem-solving under pressure** — solved the file-compression metadata association, designed the User Activity Store (Redis, passive timestamp updates, derived presence) end-to-end, and **correctly pushed back** on the cross-shard-ordering question ("same conversation is one shard, so it can't happen").
- **Estimation reached the deciding number** — the **~1M concurrent connections** that S08 never computed, plus a clean text-vs-file storage clarification (the 2.5 PB is S3, not the DB).
- **Schema evolved correctly when challenged** — recognized that separate message/file counters can't be interleaved and reached **denormalize into one table** (with the interviewer's nudge on nullable fields).
- **Communication was clean and structured** — a legible diagram and a logical end-to-end walkthrough, sustaining the delivery gain S08 first showed.

---

## The ideal design

**The crux:** a chat system is a **stateful-connection-routing + guaranteed-delivery** problem. Millions of clients each hold a **persistent WebSocket** to one specific gateway; the design reduces to **(1) a presence/session registry + pub-sub routing** that finds and reaches the recipient's gateway in real time, and **(2) persist-then-ack with a per-recipient sync cursor** so no message is lost across offline periods, reconnects, or server failures. S09 built most of this — the ideal below **sharpens the three edges that kept it from a strong pass**: an upfront denormalized schema, an explicit delivery cursor, and proactively-named trade-offs (fan-out model, consistency split, connection draining).

### 1. Ideal estimation (the numbers that size the connection tier and force the design)

| Quantity | Assumption | Result | Decision it forces |
|---|---|---|---|
| Users / DAU | 10M total · 50% active | **5M DAU** | millions of identities to route to |
| Messages/day | 5M × 500/day | **~2.5B/day** | event-driven pipeline, not synchronous fan-out |
| Average / peak QPS | 2.5B ÷ 10⁵ s · 2× peak | **~25k avg → ~50k peak** | horizontally scaled stateless write tier |
| **Concurrent connections** | ~20% of DAU online at peak | **~1M live sockets** | **the decisive number** *(computed this time)* — demands a **connection tier + session registry**; QPS alone never reveals it |
| Connection servers | 1M ÷ ~100–500k sockets/server | **dozens–hundreds** | stateful tier, sticky per connection, routed by the registry |
| Media storage | 5M × 50 × 10 MB/day | **~2.5 PB/day** (912 PB/yr) | **object store + CDN + Glacier tiering** mandatory; never a DB |
| Text storage | ~2.5B × ~1 KB/day | **~2.5 TB/day** | tiny next to media — shard the NoSQL store by conversation, don't over-engineer |

> The number that reframes the problem: **~1M concurrent connections.** It proves the system is defined by its **stateful connection layer**, not its request rate — which is why a **session registry** and **connection-aware routing** are the heart of the design.

### 2. Requirements — the ideal cut

- **Functional (in scope):** 1:1 + group messaging; file sharing; **delivery states** (sent/received/read); **ordering per conversation**; **presence / last-seen**; reading old conversations; real-time push to online users + **offline notification**.
- **Out (correctly scoped):** end-to-end encryption internals, block/unblock, voice/video, search.
- **Non-functional (ranked):** **low latency** (chat *is* the latency — sub-100ms delivery) → **high availability + fault tolerance** (a dropped connection must self-heal) → **durability** (no message lost, ever) → **horizontal scalability** to millions of connections.

### 3. Ideal architecture

A dedicated **connection tier** (WebSocket gateways) owns the live sockets; a **session store** maps each user to their gateway; a **stateless Message Writer** persists-then-acks and emits **one Kafka event**; a **delivery worker** does the presence lookup (batched for groups) and routes through per-gateway pub-sub to exactly the gateways holding recipients; **offline recipients** get an SNS/FCM push; the *same* event feeds unread-count, search, and analytics consumers. History rides a **Message Read service → cache → read replica**; presence/last-seen live in a **Redis activity store**; media rides the `file_id` → signed-URL → compression → CDN path. Every edge is numbered on the send-deliver spine (1–12), the reconnect/history path (R1–R2), and the file path (F1–F7).

![Ideal chat application as a Mermaid flowchart with numbered steps. A sender client and recipient clients each hold a persistent WebSocket to a connection tier of API Gateway WebSocket servers that terminate and authenticate the socket, scale horizontally, and drain connections on graceful shutdown, registering each connection in a Redis session store that maps user id to gateway id with a heartbeat TTL, alongside a Redis user activity store mapping user id to last active at from which online and last seen are derived. On the numbered send and deliver spine, step 1 a sender frame for a conversation id reaches a gateway, step 2 the gateway posts to a stateless Message Writer service, step 3 the service persists the message and sequence number to a NoSQL message store sharded by conversation id with one row per message and a nullable file id before acking, step 4 it acks the sender, step 5 it produces one event to a Kafka messages topic the durable event backbone and also updates last active at, step 6 a delivery worker consumes the event while the same event is read by other consumers for unread counts search index and analytics, step 7 for group messages the worker expands members from the group and conversation store, step 8 it batch looks up where each recipient is in the session store, step 9 it publishes to the owning gateways through per gateway pub sub topics, step 10 online recipients get the frame delivered to their owning gateway, step 11 the gateway pushes the WebSocket frame down the socket, and step 12 the recipient acks delivered or read which advances a per recipient sync cursor storing last delivered and last read sequence. Offline recipients are instead notified via a push service using AWS SNS or Google FCM. For reconnect and history scroll back, steps R1 and R2, a client loads since its sequence number through a Message Read service that reads a page from the message store read replica and reads the cursor, with the message store replicating to that replica. For files, steps F1 through F7, the sender requests an upload, a file and media service mints a file id and returns a signed PUT URL, the client uploads original bytes directly to S3, a Kafka compression and transcode pipeline writes compressed and thumbnail renditions under the same file id, the chat message carries only the file id, and the recipient resolves the file id to a freshly signed CDN URL to download the media, with cold media tiering to Glacier.](./diagrams/ideal-design.png)

| Layer | Component | Store |
|---|---|---|
| Connection | **API Gateway (WebSocket)** — terminate + authenticate sockets, one per online device, horizontally scaled, **connection draining** on shutdown | — |
| Presence | **Session store** — `user_id → gateway_id`, heartbeat TTL | **Redis** |
| Presence | **User activity store** — `user_id → last_active_at`; online/last-seen derived | **Redis** |
| Write | **Message Writer service** — assigns `message_id` + per-conversation `seq_no`, **persist-then-ack**, then emits one event | → Message store, → Kafka |
| Backbone | **`messages` Kafka topic** — durable log; decouples the writer from every consumer (delivery, push, unread, search, analytics) | **Kafka** |
| Fan-out | **Delivery worker** (Kafka consumer) — expands members, **batched** presence lookup, per-gateway pub-sub to owning gateways | Kafka + Redis pub/sub |
| Storage | **message store**, sharded by **conversation_id**, ordered by `seq_no`, one row/message with nullable `file_id` | **NoSQL** (Cassandra / DynamoDB) |
| Read | **Message Read service** → **cache** → **read replica** for history scroll-back | Redis + replica |
| Delivery | **per-recipient sync cursor** — `last_delivered_seq` / `last_read_seq` per user per conversation | **Redis / KV** |
| Offline | **push service** — AWS SNS / Google FCM wake for offline recipients | — |
| Media | **signed S3 URL → compression pipeline → CDN**, Glacier for cold | **S3 + CDN** |

### 4. The crux — connection routing + guaranteed delivery (built this time; here's the complete answer)

**Problem A — routing to the right connection.** A recipient holds one socket on one of hundreds of gateways. On send:

```text
# 1. Sender's gateway hands the message to the stateless Message Writer service
# 2. Writer persists it (message_id + per-conversation seq_no) BEFORE acking the sender
# 3. Writer produces ONE event to the Kafka `messages` topic, then its job is done
# 4. Delivery worker consumes; expands recipients (1:1 = 1 user; group = members from the store)
# 5. For each recipient (BATCHED for groups):
#      gw = session_store.get(user_id)          # Redis: user_id -> gateway_id
#      if gw:  publish(topic=gw, message)        # online -> routed to the owning gateway
#      else:   push_service.notify(user_id)      # offline -> AWS SNS / Google FCM
# 6. Recipient's gateway pushes the frame down that user's socket
```

The **session store** is what S09 got right — consistent hashing spreads *connections* across gateways, but only the registry answers *which gateway holds user X right now*. **Kafka does not know where the socket is** — the presence lookup lives in the worker; Kafka sits *in front of* it.

**Problem B — guaranteed delivery, including offline and failover.** Delivery is **persist-then-ack with a cursor** — the half S09 left implicit:

```text
# ORDERING     per-conversation monotonic seq_no (not wall-clock -- clocks skew across shards)
# DEDUP        client discards any message_id it has already applied (at-least-once -> idempotent)
# CURSOR       last_delivered_seq per (user, conversation); message is "delivered" only on client ack
# RECONNECT    client reconnects -> re-registers in session store ->
#              Message Read service returns all messages with seq_no > cursor  (the gap it missed)
# FAILOVER     a gateway dies (or drains) -> its sockets drop -> clients auto-reconnect via the LB ->
#              the same cursor-sync recovers everything buffered while they were gone
```

This closes both threads at once: **failover recovery and offline delivery are the same reconnect-and-sync path**, and because the message is persisted before the sender is acked, a crash anywhere loses nothing.

| The hard problem | How the ideal design kills it |
|---|---|
| Which server holds the recipient? | **Session store** (`user_id → gateway_id`) + **per-gateway pub-sub** to the exact owning gateway |
| Gateway dies / rolling deploy | **Connection draining** on graceful shutdown; on crash, clients **auto-reconnect** and **sync from cursor** — none lost |
| Recipient offline | **Push service** (SNS/FCM) wakes the device; backlog pulled via **cursor sync** on next open |
| Duplicate / out-of-order delivery | **`message_id` dedup** + **per-conversation `seq_no`** ordering, independent of at-least-once retries |

### 5. Resilience & failover

- **Stateless everything except sockets** — gateways hold connections but no session truth; the stores are the source of truth, so any gateway can serve any reconnecting client.
- **Presence TTL heals itself** — a crashed gateway's session entries expire on missed heartbeats; reconnects repopulate them.
- **Connection draining** — on a *planned* shutdown, stop accepting new sockets, signal connected clients to reconnect elsewhere, and hand off before terminating, so a rolling deploy doesn't trigger a mass-reconnect storm.
- **Persist-then-ack** guarantees durability across every failure window; **replicate** the message store ×3 cross-AZ; **S3** provides cross-AZ durability for media.
- **Backpressure** — a slow or offline recipient never blocks the sender; delivery is decoupled through Kafka + pub-sub + the cursor.

### 6. Data model

The **denormalized `messages` table** (one `seq_no` across text and files) and the **sync cursor** are the crux artifacts — the first is what needed prompting in the room, the second is what makes guaranteed delivery work.

| Store | Key / structure | Fields | Note |
|---|---|---|---|
| **Messages** (NoSQL — the crux) | partition = **`conversation_id`**, clustering = **`seq_no`** | `message_id`, `sender_id`, `type` (text/file), `text`, **`file_id`** (nullable), `created_at` | **denormalized — text and files share one per-conversation `seq_no`, so a mixed timeline orders with a single sort; sharded by conversation so a chat is co-located and read in order** |
| **Session** (Redis) | `session:{user_id}` | `gateway_id`, `last_heartbeat` + **TTL** | live routing map; ephemeral |
| **User activity** (Redis) | `activity:{user_id}` | `last_active_at` | online/last-seen derived from `now − last_active_at` |
| **Sync cursor** (Redis/KV) | `cursor:{user_id}:{conversation_id}` | `last_delivered_seq`, `last_read_seq` | drives delivered/read receipts + reconnect gap-sync |
| **Groups** | `conversation_id` | `type` (1:1/group), `member_ids[]`, metadata | member expansion for fan-out; **cached** |
| **Media** | `file_id` → keys in S3 | `content_type`, `size`, renditions under `media/{file_id}/` | direct signed-URL upload; served via CDN |

**Why `conversation_id` is the shard key.** A user opening a chat reads *one conversation's* messages in order — co-locating them on one shard makes that a single-partition, already-sorted read, and (as the candidate correctly argued) same-conversation writes never cross shards, so ordering needs no global clock. `seq_no` is a **per-conversation** counter, not wall-clock.

### 7. Design trade-offs

| Decision | Alternatives | Why this choice (and when to switch) |
|---|---|---|
| **WebSocket for all chat** | SSE; long-polling | Chat is bidirectional + low-latency; SSE is one-way and still holds a connection, so it buys nothing. No reason to switch |
| **Session store + per-gateway pub-sub** | Broadcast to all gateways; sticky LB only | Registry routes to the *exact* owning gateway — no broadcast storm. Broadcast only survives at tiny scale |
| **Shard messages by `conversation_id`** | By `sender_id`; by geography | Co-locates a conversation for ordered single-shard reads; sender/geo sharding forces cross-shard joins on group reads |
| **Denormalized `messages` (nullable `file_id`)** | Separate `Message` + `File` tables | One `seq_no` = one correct timeline; separate counters can't be interleaved (the room's ordering bug) |
| **Persist-then-ack + sync cursor** | Fire-and-forget over Kafka | Kafka at-least-once covers the *pipeline*, not the *device*; the cursor makes last-mile + offline + failover correct |
| **Availability over consistency (message store)** | Strong consistency | A chat tolerates a sub-second stale read; ordering is preserved *per conversation* by `seq_no`, which is what actually matters |
| **Write fan-out (push) small / read fan-out (pull) large** | Push to everyone always | Pushing a 10k-member channel to mostly-idle members wastes the delivery tier; pull + presence-aware push scales |
| **Media: signed URL → compression → CDN** | Upload through app servers | Keeps 2.5 PB/day off the servers; CDN carries egress; Glacier for cold. No reason to switch |

## Takeaways to drill

1. **The re-solve worked — bank the method.** Re-attempting S08 after drilling its two crux gaps flipped **Borderline → Pass**: connection routing and failover recovery were both *volunteered* this time. The same-problem re-attempt remains the clearest progress lever — keep using it on any sub-7 problem.
2. **Design the crux table upfront, denormalized.** The one stumble was separate `Message`/`File` tables with independent counters — un-interleavable. A chat's crux table is **one `messages` table, one per-conversation `seq_no`, nullable `file_id`**. Draw the schema early, not at the buzzer.
3. **State the delivery guarantee as persist-then-ack + a cursor — don't stop at "Kafka is at-least-once."** That's the pipeline guarantee, not the device guarantee. Add a **per-recipient `last_delivered_seq`**, mark delivered only on client ack, re-send unacked on reconnect, and **dedup by `message_id`**. This is the half that was implicit.
4. **Volunteer trade-offs before being asked — this is the pass→strong-pass lever.** Consistency-over-availability, batched presence lookups, cached group membership were all *correct* but *reactive*. Say "here's the trade-off and my mitigation" proactively.
5. **Name the fan-out model out loud** — push for small groups, pull for large channels, hybrid with presence. "More Kafka consumers + batching" scales the *worker*; it doesn't choose the *model* that sizes the delivery tier.
6. **Go one level deeper on failure** — beyond reconnect, name **connection draining** for planned gateway shutdown (vs. crash), the **×3 cross-AZ replication** factor, and **read-your-writes** routing given async replica lag.
7. **Keep the wins** — the ~1M concurrent-connection estimate, the Session-Store presence registry, the `sequence_id` failover resume, and the legible diagram are now *strengths*. The gap from here is depth and proactivity, not the fundamentals.

→ Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
