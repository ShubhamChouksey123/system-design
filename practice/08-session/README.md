# Session 08 — Real-Time Chat Application (WhatsApp / Slack style) · ⚠️ 6.5/10

> A scored, analyzed system-design mock. This was a **stateful-connections-at-scale** problem: the whole design turns on **routing a message to the right one of millions of persistent connections in real time** and **guaranteeing delivery even when the recipient is offline** — and both were named but only partly solved. The **improvement over S07 is real**: Design, Problem-Solving, and Communication each **rose 1.0**, driven by a genuinely good **sharding-key evolution** (geographic → sender → conversation/group ID, reached under questioning) and clean practical calls (signed S3 URLs, a Kafka compression pipeline, S3→Glacier tiering). What held it to Borderline is that the **two crux distributed-systems problems went unresolved** — **which WebSocket server holds a given user, and how the system heals when one dies**, and the **last-mile delivery guarantee to an offline device** (the answer stayed at "Kafka is at-least-once" without a per-recipient sync cursor). The **SSE-vs-WebSocket reasoning was muddled** before landing on WebSockets, and read receipts, ordering, presence, and caching/CDN went uncovered.

| | |
|---|---|
| **Problem** | Design a real-time chat app like WhatsApp / Slack — millions of concurrent users, group chats, file sharing, delivery guarantees |
| **Focus** | Routing to millions of persistent connections + end-to-end delivery, online and offline |
| **Overall** | **6.5 / 10** — ⚠️ Borderline — ▲ 0.5 vs S07's 6.0 (a comfortable pass sits at 7.5+) |
| **Weakest areas** | Problem-Solving (6.0), Scale & Trade-offs (6.0) |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |

## The problem

> Design a **real-time chat application** like **WhatsApp or Slack** that supports **millions of concurrent users**, **group chats**, **file sharing**, and **message delivery guarantees**.

A chat app looks like a CRUD-over-messages problem and is actually a **stateful-connection-routing** problem. The hard part isn't storing a message — it's that the recipient is holding a **persistent connection to one specific server out of thousands**, and the moment a message is written, the system must **find that server and push the message down that exact socket**, in milliseconds, for millions of simultaneous connections. Two questions decide the whole design: **(1) when a message arrives for user X, how does the system know which connection server X is attached to** (a presence/session registry + a routing layer), and **(2) how do you guarantee the message reaches X even if X is offline, reconnecting, or on a flaky network** (persist-then-ack + a per-recipient sync cursor + offline push). Everything else — services, object storage, compression — is standard. The trap is drawing the boxes and hand-waving the connection layer.

## Requirements & estimation

- **Functional** — **1:1 messaging**, **group messaging**, sharing **text and files**, **delivery guarantees** (at-least-once + idempotency), and **real-time notifications to receivers** (added mid-session — a good catch).
- **Non-functional** — **highly available · low latency · scalable · resilient · fault-tolerant.** Right list; latency is the one that should have been ranked first (chat *is* the latency).
- **Estimation** — 10M total · **5M DAU** (50%) · **500 messages/user/day** · 10% carry files → **50 file-messages/user/day**. That gives **~2.5B messages/day → ~29k QPS average (~25k as stated), ~50–60k peak**. Files: average **10 MB** (2 MB photos, larger videos) → 5M × 50 × 10 MB = **~2.5 PB/day** of media.
  - **Gap:** the numbers sized *message throughput and storage* but **never the concurrent-connection count** — the figure that actually designs this system. At even ~15–20% of 5M DAU online at peak, that's **~1M+ simultaneous persistent connections**; with a well-tuned server holding ~100–500k sockets, you need **dozens to hundreds of connection servers plus a presence registry to track them**. That's the decisive number, and it went uncomputed. (Estimation-depth miss, recurring — S01/S04/S05/S06/S07.)

![Requirements canvas for a chat application. The problem is to design a real-time chat application like WhatsApp or Slack supporting millions of concurrent users, group chats, file sharing, and message delivery guarantees. Functional requirements list one-to-one messaging, group messaging, sharing text and files, a message delivery guarantee that is at least once and idempotent, and sending real-time notifications to receivers. Non-functional requirements list highly available, low latency, scalable, resilient, and fault tolerant. The estimations block derives 10 million total users, 5 million daily active users at 50 percent, 500 messages per user per day with 10 percent or 50 messages carrying files, giving about 25 thousand queries per second average and 50 thousand peak, and using an average file size of 10 megabytes reaches about 2.5 petabytes of file storage per day](./diagrams/requirements.png)

## The design I produced

![Architecture canvas. A sender client sends text or file messages through an API Gateway that performs authentication, authorization, and rate limiting. The gateway routes to a Write Text Service and a Write File Service. The Write Text Service writes the message to a Message Store and emits an event carrying source id, message id, and destination id to a Kafka message queue. A Notification Service consumes those events, reads the Group Info Store to expand a group into its members, and pushes notifications over server-sent events to receiver clients. The Write File Service returns a signed AWS S3 URL so the client uploads the file directly to S3, after which an upload event flows through a Kafka compression queue to a File Compression Service that compresses the file and writes it back to S3. A Read Message Service reads a Message Store read replica so clients can pull older messages, and the Message Store replicates to that read replica](./diagrams/architecture.png)

- **API Gateway** — authN + authZ + rate limiting; fans requests to **Write Text**, **Write File**, and **Read Message** services.
- **Write Text Service** — persists the message to the **Message Store** and **emits an event** (source, message ID, destination) to **Kafka**; the **Notification Service** consumes it, expands the group via the **Group Info Store**, and pushes to receivers.
- **File path (the strongest part)** — Write File Service returns a **signed S3 URL**; the client **uploads directly to S3**; an S3 upload event flows through a **Kafka compression queue** to a **File Compression Service** that compresses and writes back — offloading bytes from the servers entirely.
- **Read Message Service** — reads a **Message Store read replica** so users can pull message history / offline backlog.
- **Sharding evolved well under pressure** — geographic → by-sender → finally **by conversation/group ID** (co-locating a whole conversation on one shard) after the interviewer walked through the group-read query pattern.
- **Left unresolved:** which **connection server** holds a given recipient and how **failover** works; the **last-mile delivery guarantee** to an offline device (stayed at "Kafka is at-least-once"); the **SSE-vs-WebSocket** choice (oscillated, then landed on WebSockets); **read/unread receipts, message ordering, presence**; and **caching / CDN** for media reads.

## Scorecard

| Axis | S07 | **S08** | Δ |
|---|:--:|:--:|:--:|
| Requirements Gathering | 7.0 | **7.0** | — |
| Design Skills | 6.0 | **7.0** | ▲ 1.0 |
| Problem-Solving | 5.0 | **6.0** | ▲ 1.0 |
| Scalability & Trade-offs | 6.0 | **6.0** | — |
| Communication | 6.0 | **7.0** | ▲ 1.0 |
| **Overall** | 6.0 | **6.5** | ▲ 0.5 |

> The rebound is broad: **Design, Problem-Solving, and Communication all ▲1.0.** Design rose on clean component separation and the signed-URL/compression file path; Problem-Solving rose because the **sharding-key evolution was a real, defended iteration** (not a flip-flop like S04); Communication rose on a legible diagram and a logical end-to-end walkthrough. **Scale held flat at 6.0** — the WebSocket connection-management gap (routing + failover) is exactly the scaling problem this domain is *about*, and it stayed open, alongside missing caching/CDN depth. The through-line with S07 is unchanged: **the crux problems were named but not fully solved, and depth arrived mainly when prompted.**

## What lost points — and the fix

| What I missed in the room | The answer a senior would give | Study |
|---|---|---|
| **Connection routing unsolved** — "more WebSocket servers," but not *how a message finds the server holding the recipient* | A **presence / session registry** (Redis: `user_id → gateway_id`, heartbeat TTL). On send, look up each recipient's gateway and route the message there via **per-gateway pub/sub topics** (Redis pub/sub or a Kafka topic per gateway). Consistent hashing distributes *connections*; the registry answers *where is user X right now*. | [Real-Time Communication](../../concepts/04-apis/realtime-communication.md) |
| **WebSocket failover left open** ("I'm not sure how to solve this") — a server dies, its connections drop | The client **auto-reconnects** to any gateway (via the LB), re-registers in the presence store, and **syncs missed messages from its cursor**. Because messages are persisted before ack, nothing is lost — the reconnect path *is* the recovery path. Draw it. | [Single Point of Failure](../../concepts/08-distributed-systems/single-point-of-failure.md) |
| **Last-mile guarantee stopped at Kafka** — "at-least-once to the Notification Service" ≠ delivered to the device | **Persist-then-ack** with a **per-recipient sync cursor** (`last_delivered_seq` per user per conversation). Delivery is done only when the client acks; unacked messages are re-sent on reconnect. Client **dedups by `message_id`**; ordering comes from a **per-conversation sequence number**. | [Message Queue](../../concepts/07-messaging-and-events/message-queue.md) |
| **SSE vs WebSocket muddled** — proposed SSE for groups, WebSocket for 1:1, on a shaky rationale | Chat is **bidirectional and low-latency** → **WebSocket for both**. SSE is server→client only and still holds an open connection per client, so it buys nothing here. State the decision rule once: *client must push frequently → WebSocket*. | [Real-Time Communication](../../concepts/04-apis/realtime-communication.md) |
| **Read receipts, ordering, presence uncovered** — the interviewer flagged all three | Model **message states** (`sent → delivered → read`) as cursor advances; **order per conversation** by a monotonic `seq_no` (not wall-clock); **presence** falls out of the registry's heartbeat TTL (online = key alive). | [Consistency Models](../../concepts/08-distributed-systems/consistency-models.md) |
| **No caching / CDN for media** — 2.5 PB/day served straight from S3 | Serve media through a **CDN** by signed URL (egress at this scale must not hit origin); cache **hot conversation metadata and group membership** in Redis. Reads, not just writes, need a scaling story. | [CDN](../../concepts/03-networking-and-delivery/cdn.md) |
| **Fan-out model never named** — a group message to N members is N deliveries | State the choice: **write fan-out (push)** for small groups, **read fan-out (pull)** for very large groups/channels, **hybrid** with presence-aware push. It's the decision that sizes the delivery tier. | [Message Queue](../../concepts/07-messaging-and-events/message-queue.md) |

## What went well

The design instincts were noticeably sharper than S07 — this reads as an improving candidate:

- **Sharding-key evolution, defended not flip-flopped** — walked geographic → by-sender → **by conversation/group ID**, each step motivated by a concrete read pattern (group reads spanning shards). That's the senior signal S04 lacked: *iterate toward the right answer with a reason at each step*.
- **File path was genuinely strong** — **signed S3 URLs** to keep large uploads off the servers, a **Kafka-driven compression pipeline**, and **S3→Glacier tiering** for cold media. Practical, cost-aware, and correctly asynchronous.
- **Idempotency + at-least-once named** for delivery, and **replication** reasoned for durability across the message store, group store, and S3.
- **Stateless-gateway horizontal scaling** identified immediately, and the **metadata-on-upload** fix for the compression→sender association came quickly once prompted.

---

## The ideal design

**The crux:** a chat system is a **stateful-connection-routing + guaranteed-delivery** problem. Millions of clients each hold a **persistent WebSocket** to one specific gateway server; the design reduces to **(1) a presence/session registry + pub-sub routing** that finds and reaches the recipient's gateway in real time, and **(2) persist-then-ack with a per-recipient sync cursor** so no message is lost across offline periods, reconnects, or server failures. Message *storage* is easy; the difficulty is the live connection layer and the delivery guarantee. Everything else follows.

### 1. Ideal estimation (the numbers that size the connection tier and force the design)

| Quantity | Assumption | Result | Decision it forces |
|---|---|---|---|
| Users / DAU | 10M total · 50% active | **5M DAU** | millions of identities to route to |
| Messages/day | 5M × 500/day | **~2.5B/day** | event-driven pipeline, not synchronous fan-out |
| Average / peak QPS | 2.5B ÷ 10⁵ s · 2× peak | **~29k avg → ~60k peak** | horizontally scaled stateless write tier |
| **Concurrent connections** | ~15–20% of DAU online at peak | **~1M+ live sockets** | **the decisive number** — demands a dedicated **connection tier + presence registry**; QPS alone doesn't size it |
| Connection servers | 1M ÷ ~100–500k sockets/server | **dozens–hundreds** | stateful tier, sticky per connection, routed by a registry |
| Media storage | 5M × 50 × 10 MB/day | **~2.5 PB/day** | **object store + CDN + Glacier tiering** mandatory; never a DB |

> The number that reframes the problem: **~1M+ concurrent connections.** It proves the system is defined by its **stateful connection layer**, not its request rate — which is why a **presence registry** and **connection-aware routing** are the heart of the design, and why "add more servers" is a non-answer without saying *how a message finds the right one*.

### 2. Requirements — the ideal cut

- **Functional (in scope):** 1:1 + group messaging; text + file sharing; **delivery states** (sent/delivered/read); **ordering per conversation**; **presence**; real-time push to online users + **offline notification**.
- **Argued *into* scope:** **read receipts, ordering, and presence** — first-class for a chat app, and the interviewer flagged their absence. **Out:** end-to-end encryption internals, voice/video calling, search.
- **Non-functional (ranked):** **low latency** (chat is the latency — sub-100ms delivery) → **high availability + fault tolerance** (a dropped connection must self-heal) → **durability** (no message lost, ever) → **horizontal scalability** to millions of connections.

### 3. Ideal architecture

A dedicated **connection tier** (WebSocket gateways) owns the live sockets; a **presence registry** maps each user to their gateway; a **stateless send service** persists-then-acks and emits **one Kafka event**; a **delivery worker** (Kafka consumer) does the presence lookup and routes through a **pub-sub layer** to exactly the gateways holding its recipients; **offline recipients** get an APNs/FCM push; and the *same* event feeds unread-count, search, and analytics consumers. Media rides the `file_id` → signed-URL → compression → CDN path. *(This overview overlays every flow; the numbered per-flow diagrams below untangle them.)*

![Ideal chat application as a Mermaid flowchart with numbered steps. A sender client and recipient clients each hold a persistent WebSocket to a connection tier of WebSocket gateway servers that terminate and authenticate the socket and scale horizontally, registering each connection in a Redis presence and session registry that maps user id to gateway id with a heartbeat TTL. On the numbered send and deliver spine: step 1 a sender frame for a conversation id reaches a gateway; step 2 the gateway posts to a stateless send and message service; step 3 the service persists the message and sequence number to a NoSQL message store sharded by conversation id before acking; step 4 it acks the sender; step 5 it produces one event to a Kafka messages topic, the durable event backbone; step 6 a delivery worker consumes the event while the same event is also read by other consumers for unread counts, search index, and analytics; step 7 for group messages the worker expands members from the group and conversation store; step 8 it looks up where each recipient is in the presence registry; step 9 it publishes to the owning gateways through per-gateway pub-sub topics; step 10 online recipients get the frame delivered to their owning gateway; step 11 the gateway pushes the WebSocket frame down the socket; and step 12 the recipient acks delivered or read which advances a per-recipient sync cursor. Offline recipients are instead notified via a push service using APNs or FCM. On reconnect, steps R1 and R2, a client syncs since its cursor through a sync service that reads the gap by sequence number from the message store. For scrolling back, steps H1 and H2, a history and read service does a keyset paginated range scan by sequence number. For files, steps F1 through F7, the sender requests an upload, a file and media service mints a file_id and returns a signed PUT URL, the client uploads original bytes directly to S3, a Kafka compression pipeline transcodes and writes compressed and thumbnail renditions under the same file_id, the chat message carries only the file_id, and the recipient resolves the file_id to a freshly signed CDN URL to download the media, with cold media tiering to Glacier.](./diagrams/ideal-design.png)

| Layer | Component | Store |
|---|---|---|
| Connection | **WebSocket gateways** — terminate + authenticate sockets, one per online device, horizontally scaled | — |
| Presence | **session registry** — `user_id → gateway_id`, heartbeat TTL (doubles as online/offline) | **Redis** |
| Write | **Send/Message service** — assigns `message_id` + per-conversation `seq_no`, **persist-then-ack**, then emits one event | → Message store, → Kafka |
| Backbone | **`messages` Kafka topic** — durable event log; decouples the send service from every consumer (delivery, push, unread, search, analytics) | **Kafka** |
| Fan-out | **Delivery worker** (Kafka consumer) — expands members, presence lookup, then **per-gateway pub-sub topics** deliver to exactly the gateways holding recipients | Kafka + Redis pub/sub |
| Storage | **message store**, sharded by **conversation_id** (whole chat co-located, ordered by `seq_no`) | **NoSQL** (Cassandra / Mongo) |
| Delivery | **per-recipient sync cursor** — `last_delivered_seq` per user per conversation | **Redis / KV** |
| Offline | **push service** — APNs / FCM wake for offline recipients | — |
| Media | **signed S3 URL → compression pipeline → CDN**, Glacier for cold | **S3 + CDN** |

#### The three flows, one at a time

The diagram above overlays all three paths at once, which makes it dense. Here is each flow on its own. Every one rides the **same spine** — `persist → ack → find the recipient's gateway → route via pub/sub → deliver → advance cursor` — with a single twist per flow.

**Flow 1 — one-to-one chat (Alice → Bob).** One recipient, one lookup — with **Kafka as the durable event backbone** between persistence and delivery.

![One-to-one chat flow as a Mermaid flowchart. Step 1, Alice's client pushes a WebSocket frame addressed to conversation alice-bob up to Gateway-A which holds her socket. Gateway-A forwards it to the stateless Send and Message service, which assigns a message id and a per-conversation sequence number. Step 2, the service persists the message to the message store shard for conversation alice-bob before doing anything else. Step 3, only then does it ack Alice with a sent tick. Step 4, the service produces one event to a Kafka topic named messages, the durable event backbone, and its job ends there. Step 5, a delivery worker that is a Kafka consumer consumes the event, while the same event is also read by other consumers such as unread counts, the search index, and analytics. Step 6, the delivery worker asks the presence registry which maps user id to gateway id where Bob is, and the registry answers Gateway-B. Step 7, the worker forwards the message to Bob's owning gateway. Step 8, Gateway-B pushes the WebSocket frame down Bob's socket. Step 9, Bob's client returns a delivered or read ack that advances the sync cursor storing last delivered sequence. If Bob is offline the worker instead notifies the push service using APNs or FCM to wake his device.](./diagrams/flow-1-one-to-one.png)

1. **Alice sends** a WS frame up her persistent socket to **Gateway-A** (whichever gateway she is connected to).
2. **Persist first.** The **Send/Message service** stamps a `message_id` (idempotency) and per-conversation `seq_no` (ordering) and writes to the **message store before anything else** — so the message survives any downstream failure.
3. **Ack the sender** ("sent" ✓) — only now, because the message is already durable.
4. **Emit one event to Kafka** — the send service produces the message to a `messages` topic and its job is *done*. It no longer owns fan-out, routing, or retry. This is the decoupling: durability + buffering + back-pressure come for free, and the send service stays tiny.
5. **Many consumers, one event** — a **delivery worker** (Kafka consumer) picks it up for real-time delivery, while **other consumers** (unread counts, search index, analytics) read the *same* event independently. Fanning these out synchronously from the send service would be the anti-pattern Kafka removes.
6. **Find Bob** — the *delivery worker* (not the send service) asks the **presence registry** → `Gateway-B`. **Kafka does not know where Bob's socket is** — a consumer group spreads partitions arbitrarily, so this presence lookup is still required; Kafka sits *in front of* it, it doesn't replace it.
7–8. **Route to the one owning gateway** and **deliver** — the worker forwards only to Gateway-B (where Bob's socket lives), which pushes the frame down the socket.
9. **Close the loop** — Bob's delivered/read ack advances the **sync cursor** (powers read receipts + reconnect recovery). **If Bob is offline at step 6**, the worker routes to the **push service** instead, and the message waits in the store until Bob reconnects and syncs.

> **Trade-off:** the Kafka hop adds a few ms of latency, so ultra-low-latency designs (classic WhatsApp/Erlang) route directly and skip the log on the hot path. Most systems accept the few ms because the decoupling — one durable event feeding delivery, push, unread, and search independently — is worth far more than it costs.

**Flow 2 — group chat (Alice → Bob, Carol, Dave).** The twist: **persist once, emit one Kafka event, then the delivery worker expands the member list and loops the lookup-and-route per member** — one write becomes N deliveries.

![Group chat flow as a Mermaid flowchart. Step 1, Alice sends a WebSocket frame addressed to conversation group-123 to Gateway-A, which forwards it to the Send and Message service that assigns a message id and sequence number. Step 2, the service persists the message once to the message store shard for group-123 and acks Alice. Step 3, the service produces one event to the Kafka messages topic, the durable event backbone. Step 4, a delivery worker that is a Kafka consumer consumes the event. Step 5, the worker expands the membership by reading the group store for group-123, which returns Bob, Carol, and Dave. Step 6, it looks up each member's gateway in the presence registry. Step 7a, Bob is online so it routes to Gateway-B which reaches Bob. Step 7b, Carol is online so it routes to Gateway-C which reaches Carol. Step 7c, Dave is offline so it notifies the push service, and Dave receives a notification while Bob and Carol receive the real-time push.](./diagrams/flow-2-group-chat.png)

1–2. **Persist once, ack once** — identical to 1:1. The message is stored a single time under the group's conversation shard, with one `seq_no`, then Alice is acked.
3–4. **Emit one event, consume once** — the send service produces **a single Kafka event** and stops; a **delivery worker** consumes it. Note the fan-out lives in the *worker*, not the send service — and the group's *one* write is still *one* event on the log (the multiplication into N deliveries happens after the log, not on it).
5. **Expand the group** — the worker reads the **group store** to get `[Bob, Carol, Dave]`. This is the step 1:1 doesn't have.
6. **Look up each member** in the **presence registry** — Bob and Carol online, Dave offline.
7. **Fan out** — route to Bob's and Carol's owning gateways (real-time pushes); route Dave to the **push service**. Each member has their *own* sync cursor for the group, so read receipts and reconnect-catch-up are tracked per person. *(This is **write fan-out / push**, ideal for small groups; a 10k-member channel would switch to **pull fan-out** — members read the shard on open — with presence-aware push for the currently-active few.)*

**Flow 3 — sharing a file (Alice uploads a 10 MB video).** The twist: **the bytes go out-of-band to S3/CDN; the chat message carries only an opaque `file_id`** — never a URL — and the *current* signed URL is resolved lazily at read time.

![File sharing flow as a Mermaid flowchart. Step 1, Alice's client requests an upload from the file and media service, which owns the file_id to renditions mapping only and holds no chat metadata. Step 2, the service mints a file_id and returns it plus a pre-signed PUT URL for the original. Step 3, Alice uploads the original bytes directly to the S3 object store, which holds bytes only, never touching the application servers. Step 4, S3 emits an upload event to a Kafka compression pipeline that transcodes the file and writes compressed and thumbnail renditions to deterministic keys under the same file_id. Step 5, Alice's client sends an ordinary chat message whose body is a file type carrying the file_id, not a URL, to the Send and Message service, which runs the same persist, ack, route, and deliver spine as one-to-one or group chat. Step 5a, the send service persists the message row to the message store, and that row, carrying sender_id, conversation_id, seq_no, and file_id, is where the file association lives, not in S3. Step 6, the recipient receives the file_id rather than the bytes. Step 7, when the recipient opens the media its client asks the file and media service to resolve the file_id. Step 8, the service picks the best available rendition and returns a freshly signed CDN URL. Step 9, the recipient downloads by that signed URL from the CDN, which serves the media cached from S3.](./diagrams/flow-3-file-sharing.png)

1. **Ask for a spot** — Alice's client asks the **file/media service**, which **mints a `file_id`**, reserves the key namespace `media/{file_id}/…`, and records the technical blob facts it owns (`content_type`, `size`, rendition/transcode status) keyed by `file_id`. **The sender/conversation association is *not* written here** — it lands on the message row in step 5 (`sender_id` + `conversation_id` + `seq_no` already identify who shared what, where, and in what order). *This is the fix for the mock's "store metadata in S3 with the file" answer:* the blob store keeps only bytes + `file_id → renditions`; the durable message carries the association. S3 object metadata isn't queryable, drifts from the source of truth, and couples the blob to chat semantics — and since a `file_id` can be forwarded across conversations, `conversation_id` doesn't belong on the blob at all.
2–3. **Upload direct to S3** — the service returns a **pre-signed PUT URL for the original**; Alice `PUT`s the 10 MB straight to **S3**. The gateways and message service carry none of these bytes — that is what makes 2.5 PB/day survivable.
4. **Compress asynchronously** — an S3 upload event flows through a **Kafka pipeline** that transcodes and writes `compressed`/`thumb` to **deterministic keys under the same `file_id`**; cold files later tier to **Glacier**. Nobody has to be *told* these URLs — the naming is derived from `file_id`.
5. **Send the `file_id`, not a URL** — Alice's client sends a chat message with body `{ type: file, file_id }` (plus a client-side thumbnail/blurhash), which from here is **identical to Flow 1 or 2** — same persist-then-ack under `conversation_id` with a `seq_no`. **This message row *is* the file's association:** `sender_id`, `conversation_id`, `seq_no`, and `file_id` in one durable, queryable, shard-aligned record — no metadata smuggled into the blob. She does **not** wait for compression. *Why store `file_id`, not a URL?* Signed URLs expire, the compressed rendition doesn't exist yet at send time, and one upload yields many renditions — so the durable message stores a stable handle, not a link.
6. **Deliver the handle** — the recipient receives the small `file_id`, not the bytes.
7–8. **Resolve at read time** — when the recipient *opens* the media, their client asks the **file/media service to resolve `file_id`** → the service picks the best available rendition (compressed if ready, else original) and returns a **freshly signed CDN URL**, scoped per-viewer and short-lived.
9. **Download via CDN** — tapping fetches the media from the **CDN** (cached near them), so egress never hits the origin.

### 4. The crux — connection routing + guaranteed delivery (the depth that was missing)

The two problems the mock left open *are* the design. Here is the end-to-end answer for each.

**Problem A — routing to the right connection.** A recipient holds one socket on one of hundreds of gateways. On send:

```text
# 1. Sender's gateway hands the message to the stateless Send service
# 2. Send service persists it (message_id + per-conversation seq_no) BEFORE acking the sender
# 3. Expand recipients (1:1 = 1 user; group = members from the conversation store)
# 4. For each recipient:
#      gw = presence_registry.get(user_id)      # Redis: user_id -> gateway_id
#      if gw:  publish(topic=gw, message)        # online → routed to the owning gateway
#      else:   push_service.notify(user_id)      # offline → APNs / FCM
# 5. Recipient's gateway pushes the frame down that user's socket
```

The **presence registry** is what the mock was missing — consistent hashing spreads *connections* across gateways, but only the registry answers *which gateway holds user X right now*. Each gateway subscribes to its own pub-sub topic, so a message is routed to **exactly** the gateways that need it — no broadcast.

**Problem B — guaranteed delivery, including offline and failover.** Delivery is **persist-then-ack with a cursor**, never fire-and-forget:

```text
# ORDERING     per-conversation monotonic seq_no (not wall-clock — clocks skew across shards)
# DEDUP        client discards any message_id it has already applied (at-least-once → idempotent)
# CURSOR       last_delivered_seq per (user, conversation); message is "delivered" only on client ack
# RECONNECT    client reconnects → re-registers in presence store →
#              Sync service returns all messages with seq_no > cursor  (the gap it missed)
# FAILOVER     a gateway dies → its sockets drop → clients auto-reconnect to any gateway via the LB →
#              the same cursor-sync recovers everything buffered while they were gone
```

This closes both open threads at once: **failover recovery and offline delivery are the same reconnect-and-sync path**, and because the message is persisted before the sender is acked, a crash anywhere loses nothing.

| The hard problem | How the ideal design kills it |
|---|---|
| Which server holds the recipient? | **Presence registry** (`user_id → gateway_id`) + **per-gateway pub-sub** route to the exact owning gateway |
| Gateway dies mid-conversation | Client **auto-reconnects**, re-registers, **syncs from its cursor** — persisted messages replay, none lost |
| Recipient offline | **Push service** (APNs/FCM) wakes the device; backlog pulled via **cursor sync** on next open |
| Duplicate / out-of-order delivery | **`message_id` dedup** + **per-conversation `seq_no`** ordering, independent of at-least-once retries |

### 5. Resilience & failover

- **Stateless everything except sockets** — gateways hold connections but no session truth; the registry and stores are the source of truth, so any gateway can serve any reconnecting client.
- **Presence TTL heals itself** — a crashed gateway's registry entries expire on missed heartbeats; reconnects repopulate them. Presence *is* the heartbeat.
- **Persist-then-ack** guarantees durability across every failure window; **replicate** the message store, group store, and cursor store; **S3** provides cross-AZ durability for media.
- **Backpressure** — a slow or offline recipient never blocks the sender; delivery is decoupled through pub-sub + the cursor, and undelivered messages simply wait in the store.

### 6. Data model

The **per-conversation sequence** and the **sync cursor** are the crux artifacts — they're what make ordering and guaranteed delivery work, and neither was drawn in the room.

| Store | Key / structure | Fields | Note |
|---|---|---|---|
| **Messages** (NoSQL — the crux) | partition = **`conversation_id`**, clustering = **`seq_no`** | `message_id`, `sender_id`, `type` (text/file), `body` / `s3_url`, `created_at` | **the crux table — sharded by conversation so a whole chat is co-located and read in order; `seq_no` gives per-conversation ordering, `message_id` gives idempotency** |
| **Presence** (Redis) | `presence:{user_id}` | `gateway_id`, `last_heartbeat` + **TTL** | live routing map + online/offline signal; ephemeral |
| **Sync cursor** (Redis/KV) | `cursor:{user_id}:{conversation_id}` | `last_delivered_seq`, `last_read_seq` | drives delivered/read receipts and reconnect gap-sync |
| **Conversations / groups** | `conversation_id` | `type` (1:1/group), `member_ids[]`, metadata | member expansion for fan-out |
| **Media** | object key in S3 | `s3_url`, `size`, `content_type`, `conversation_id` (metadata on upload) | direct signed-URL upload; served via CDN |

**Why `conversation_id` is the shard key.** A user opening a chat reads *one conversation's* messages in order — co-locating them on one shard makes that a single-partition, already-sorted read. Sharding by `sender_id` (the mock's earlier answer) scatters a group's messages across shards and forces the in-memory cross-shard join the interviewer pushed back on. `seq_no` is a **per-conversation** counter, not a global clock — so ordering is correct without synchronized clocks across shards.

### 7. Design trade-offs

| Decision | Alternatives | Why this choice (and when to switch) |
|---|---|---|
| **WebSocket for all chat** | SSE; long-polling | Chat is bidirectional + low-latency; SSE is one-way and still holds a connection, so it buys nothing. **No reason to switch** for messaging |
| **Presence registry + per-gateway pub-sub** | Broadcast to all gateways; sticky LB only | Registry routes to the *exact* owning gateway — no broadcast storm. Broadcast only survives at tiny scale |
| **Shard messages by `conversation_id`** | By `sender_id`; by geography | Co-locates a conversation for ordered single-shard reads; sender/geo sharding forces cross-shard joins on group reads |
| **Persist-then-ack + sync cursor** | Fire-and-forget over Kafka | Kafka at-least-once covers the *pipeline*, not the *device*; the cursor is what makes last-mile + offline + failover correct |
| **Write fan-out (push) for small groups, read fan-out (pull) for large** | Push to everyone always | Pushing a huge channel to millions of mostly-idle members wastes the delivery tier; pull + presence-aware push scales |
| **Media: signed URL → compression → CDN** | Upload through app servers | Keeps 2.5 PB/day of bytes off the servers; CDN carries egress; Glacier for cold. **No reason to switch** |
| **NoSQL message store** | Relational | Write-heavy, append-mostly, partition-by-conversation fits wide-column/document; relational adds no value on this access pattern |

## Takeaways to drill

1. **A chat app is a connection-routing problem — lead with the presence registry.** Millions of persistent sockets mean the first question is *which gateway holds this user*, answered by a **`user_id → gateway_id` registry** + **per-gateway pub-sub**, not by "add more servers." Size the **concurrent-connection count**, not just QPS — it's the number that designs the system.
2. **Delivery = persist-then-ack + a per-recipient sync cursor.** "Kafka is at-least-once" is the pipeline guarantee, not the device guarantee. The **cursor** (`last_delivered_seq`) makes offline delivery, reconnect gap-sync, and gateway failover all the *same* recovery path. Draw it.
3. **Failover is the reconnect path — say so.** A gateway dies → clients auto-reconnect → re-register → sync from cursor. Because messages are persisted before ack, nothing is lost. This is exactly the question left as "I'm not sure" in the room.
4. **Order per conversation with a `seq_no`, dedup with a `message_id`.** Wall-clock ordering breaks across shards; a per-conversation sequence + idempotent `message_id` gives correct ordering and read receipts on top of at-least-once delivery.
5. **Pick the fan-out model out loud** — push for small groups, pull for large channels, hybrid with presence. It's the decision that sizes the delivery tier, and it went unnamed.
6. **Don't skip the read path** — CDN for media egress (2.5 PB/day can't hit origin), cache hot group membership. Caching/CDN depth is a recurring silent-senior box.
7. **Keep the good habits** — the sharding-key *evolution with a reason at each step* and the signed-URL/compression/Glacier file path were genuine strengths; that defended iteration is what lifted three axes. Bring the same push-to-the-solution to the connection layer.

→ Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
