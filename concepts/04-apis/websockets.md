# WebSockets — Deep Dive

---

Companion to [Real-Time Communication](./realtime-communication.md), which compares WebSockets with polling and SSE. This file covers **how the protocol works and how to scale the connection tier**.

## 1. What it is & why it's asked

**What it is**

- A **persistent, full-duplex** channel over a single TCP connection.
- Starts as an HTTP request, then **upgrades** to the WebSocket protocol.
- Either side can send at any time — no request/response, no per-message HTTP headers.
- Low latency and low overhead per message, so it suits frequent small updates.

**Why it's asked**

- It's the standard answer for **bidirectional real-time** features: chat, live location, collaborative editing, trading, live notifications.
- Interviewers want to see you pick it **over polling or SSE** for the right reason (two-way, frequent, low-latency).
- The real test is the **stateful connection tier**: each socket pins state to one server, so scaling, routing, deploys and reconnects need deliberate design.
- It's a recurring building block in "design chat / food delivery / ride sharing / live scores" questions.

## 2. The protocol

```
Client                                   Server
  | GET /ws  Upgrade: websocket           |
  | Sec-WebSocket-Key: <random>        -> |
  | <- 101 Switching Protocols            |
  | <- Sec-WebSocket-Accept: <hash(key)>  |
  |===== full-duplex frames (ws/wss) =====|
  | ping  ->            <- pong           |   heartbeat
  | close frame (code) -> <- close frame  |
```

| Point | Detail |
|---|---|
| Handshake | Plain HTTP/1.1 `Upgrade` → `101`; after that it is **not HTTP** (frames, not requests) |
| Frames | Small header (2–14 B) + payload; text or binary; **ping/pong** and **close** are control frames |
| Transport | `ws://` (plain) · **`wss://`** (TLS — always use in production; also gets through proxies) |
| Over HTTP/2 | Possible (RFC 8441) but most deployments still use HTTP/1.1 upgrade |
| Subprotocols | `Sec-WebSocket-Protocol` negotiates the message format (JSON, Protobuf, STOMP, MQTT-over-WS) |

## 3. Why the connection tier is hard

A WebSocket is **long-lived server state**: the server holds a socket, buffers and (often) user context per connection. That breaks the "any server can serve any request" assumption of stateless HTTP.

| Concern | Consequence |
|---|---|
| Capacity | A tuned server holds **~50K–100K+ idle connections** (file descriptors, ~10–50 KB memory each). 180K connections → ~4–8 gateways, sized by memory and by message rate, not CPU |
| Load balancing | Use an **L4 LB** or an L7 LB with WebSocket support; raise idle timeouts; balance by **least connections** (round-robin skews as connections live for hours) |
| Deploys | Restarting a gateway drops all its sockets → **drain gradually** and expect a reconnect storm |
| Dead peers | TCP may not notice a vanished client for minutes → **heartbeat** (ping every 20–30 s, drop after missed pongs) |
| Slow consumers | A client that can't read fills the server buffer → **bound the queue** and drop or disconnect |

## 4. Reaching the right socket — presence and fan-out

The service that produces a message (chat, location, order update) is usually **not** the gateway holding the recipient's socket. Keep the connection tier thin and route to it:

| Piece | Role |
|---|---|
| **Presence registry** (Redis: `user:42 → gateway-A`) | Which gateway holds this user's socket; written on connect, removed on disconnect, **TTL refreshed by heartbeat** so a crashed gateway's entries expire |
| **Pub/sub backplane** (Redis pub/sub, Kafka) | Each gateway subscribes to its own channel; a producer publishes to the target gateway (or to a topic the gateway consumes) |
| **Sticky routing** | Not required if you have the registry + backplane; only needed when per-connection state lives in the gateway's memory |
| **Fan-out to many** (group chat, live match) | Publish once to a topic; each gateway delivers to its local subscribers — avoids N point-to-point sends |

```
producer -> lookup presence(user) -> publish to gateway-A channel -> gateway-A -> socket
```

## 5. Reliability: reconnect, resume, ordering

- **Reconnect with exponential backoff + jitter** — otherwise a gateway restart makes every client retry at the same instant (thundering herd).
- **Resume, don't restart:** client sends the `last_event_id` it saw; server replays from a short buffer or the durable log. WebSocket gives **no delivery guarantee** — a message sent just as the socket dies is lost.
- **Durability lives elsewhere:** write messages to the DB / Kafka first, then push over the socket. If the user is offline, fall back to [push notifications](./realtime-communication.md) and sync on next open.
- **Ordering:** per-connection order is preserved by TCP; across servers add a sequence number per conversation.
- **Idempotent handling:** retries and replays mean the client may see an event twice — dedupe by message id.

## 6. Security

| Risk | Mitigation |
|---|---|
| Unauthenticated socket | Authenticate in the handshake (cookie or short-lived token in a query param / first message) — browsers can't set custom headers on `new WebSocket()` |
| Cross-site hijacking | Validate the **`Origin`** header; use SameSite cookies or tokens, not ambient credentials alone |
| Token expiry on a long-lived socket | Re-auth periodically or close with a code so the client reconnects with a fresh token |
| Abuse / flooding | Per-connection **message rate limit** and max frame size; cap connections per user |
| Plaintext | `wss://` only |

## 7. Technologies

| Technology | Type | Notes |
|---|---|---|
| **Socket.IO** | Library | Adds rooms, auto-reconnect, long-polling fallback; **not** wire-compatible with raw WS |
| **NGINX / HAProxy / AWS ALB** | LB / proxy | Support the Upgrade; raise idle/read timeouts |
| **AWS API Gateway WebSocket** | Managed | Gateway holds the sockets, invokes Lambda per message; ~2 h max connection |
| **AWS AppSync / Pusher / Ably** | Managed pub/sub | Offload the connection tier entirely |
| **Redis pub/sub, Kafka** | Backplane | Cross-gateway delivery; Redis pub/sub is fire-and-forget, Kafka is replayable |
| **MQTT** | Alternative | Lightweight pub/sub for mobile and IoT, with QoS levels |

## 8. When *not* to use it

- One-directional server → client updates → **SSE** is simpler (auto-reconnect, plain HTTP).
- Infrequent updates (every ≥ 30 s) → polling or push notifications cost less than holding a socket open.
- Clients behind hostile proxies that strip Upgrade → fall back to long polling (Socket.IO does this).

Worked use: [Session 20 — Food delivery](../../practice/20-session/README.md) (~180K driver and buyer sockets, presence registry, throttled location pushes).

## 9. One-Paragraph Summary (for quick revision)

A **WebSocket** starts as an HTTP `Upgrade` (`101 Switching Protocols`) and becomes a persistent, **full-duplex** frame channel (`wss://` in production, **ping/pong** heartbeats to catch dead peers). Its difficulty is the **stateful connection tier**: one server holds ~50K–100K sockets, so you balance by least connections, drain on deploy, and bound per-client buffers. Because the producer is rarely the gateway holding the socket, keep a **presence registry** (user → gateway, TTL by heartbeat) and a **pub/sub backplane** (Redis, Kafka) to route messages, and publish once per topic for fan-out. Delivery is **not guaranteed**: persist first, reconnect with **backoff + jitter**, resume from a `last_event_id`, dedupe by message id, and fall back to push notifications when offline. Authenticate in the handshake, check `Origin`, rate-limit messages. Prefer **SSE** for one-way streams and polling for rare updates.
