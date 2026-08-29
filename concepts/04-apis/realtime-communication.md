# Real-Time Communication

---

Plain [HTTP](./http.md) is request–response — the client must ask; the server can't **push**. For live features (chat, notifications, feeds, dashboards, presence) you need one of four techniques to get server data to the client promptly. (For server→**server** push on an event, see [webhooks](./webhooks.md).)

## 1. The four options at a glance

| Technique                    | Direction | Connection | Latency | Cost / notes |
|------------------------------|---|---|---|---|
| **Short polling**            | client pulls repeatedly | new request each time | poll interval | simplest; wasteful — most polls return nothing |
| **Long polling**             | client pulls, server holds | request held open until data | near real-time | no new protocol; many hanging connections |
| **SSE (Server-Sent Events)** | **server → client** stream | one long-lived HTTP conn | real-time | one-way only; auto-reconnect; text only |
| **WebSocket**                | **full-duplex** (both ways) | one persistent TCP conn (`ws://`) | real-time | richest; needs its own protocol + infra |

## 2. Short polling

Client requests on a fixed interval (e.g. every 5 s); server replies immediately with data or nothing.

- **Pros:** trivial, stateless, works everywhere. **Cons:** wasteful (mostly empty responses), latency bounded by the interval, load scales with clients × frequency.
- **Use:** low-frequency, non-urgent updates (a status that changes rarely).

## 3. Long polling

Client sends a request; the server **holds it open** until data is available (or a timeout), then responds — the client immediately re-requests.

- **Pros:** near real-time without a new protocol; works through proxies/firewalls. **Cons:** each message = a full request cycle; many **held-open connections** consume server resources; ordering/reconnect logic needed.
- **Use:** a fallback for real-time when WebSockets/SSE aren't available (older chat systems).

## 4. Server-Sent Events (SSE)

A single long-lived HTTP response the server streams events over (`Content-Type: text/event-stream`); the browser's **`EventSource`** auto-reconnects.

- **Pros:** simple, over plain HTTP/HTTPS, **built-in auto-reconnect** + event IDs, efficient one-way push. **Cons:** **server → client only**, text-only, limited concurrent connections per browser on HTTP/1.1.
- **Use:** live feeds, notifications, stock tickers, progress/log streaming — anything one-directional.

## 5. WebSockets

A persistent, **full-duplex** connection: an HTTP request **Upgrades** to the `ws://`/`wss://` protocol, then both sides send messages anytime over one TCP connection.

- **Pros:** true two-way, low overhead per message, low latency. **Cons:** not plain HTTP (needs WebSocket-aware LBs/proxies), stateful connections complicate scaling (sticky routing / a pub-sub backplane like Redis), you handle reconnect/heartbeats.
- **Use:** chat, multiplayer games, collaborative editing, live trading — anything needing **bidirectional** real-time. Libraries: **Socket.IO**, native WS.

## 6. Push notifications (when the client is *disconnected*)

The four techniques above all assume the client is **connected and awake**. But a mobile app is usually backgrounded, asleep, or offline — its WebSocket is gone. To reach it, you don't hold your own connection; you hand the message to the **platform push service**, which owns a single OS-level channel to every device.

| Platform | Managed service |
|---|---|
| Android · Web · (iOS via relay) | **Google FCM** (Firebase Cloud Messaging) |
| Apple (iOS/macOS) | **APNs** (Apple Push Notification service) |
| AWS-side fan-out to FCM/APNs/SMS/email | **AWS SNS** (routes to the above; one API, many endpoints) |

- **How it works:** your server calls the managed service (FCM/APNs, or **SNS** as a cross-platform front door) with a device token + payload; the provider wakes the device and delivers the notification.
- **Complement, not alternative:** a chat app uses **WebSocket while foregrounded** and **FCM/APNs to wake the device otherwise** — same message, two delivery paths depending on whether the client is connected.
- **Best-effort, not guaranteed:** notifications can be dropped, delayed, or coalesced. Treat them as a *nudge* — the authoritative message still **syncs from your store on reconnect** (persist-then-ack + a per-recipient cursor). **Dedupe by message id** since the nudge and the synced copy can both arrive.

## 7. When to use which

- **Short polling** — cheap, infrequent, don't-care-about-latency updates.
- **Long polling** — near real-time fallback when you can't use SSE/WS.
- **SSE** — **one-way** server push (notifications, feeds); simplest real-time.
- **WebSockets** — **two-way** interaction (chat, games, collaboration).
- **Push notifications (FCM / APNs / SNS)** — reach a **disconnected** device (backgrounded/asleep/offline); wake it, then sync the real data.

Rule of thumb: **one-way → SSE, two-way → WebSockets**, poll only when neither is warranted — and **push notifications to reach a client that isn't connected at all**.

## 8. One-Paragraph Summary (for quick revision)

HTTP can't push, so real-time features pick from four options. **Short polling** re-requests on an interval — simplest but wasteful and latency-bound. **Long polling** holds the request open until data arrives — near real-time with no new protocol, but ties up connections. **SSE** streams events one-way (server → client) over a single long-lived HTTP connection with built-in auto-reconnect — ideal for notifications and live feeds. **WebSockets** upgrade to a persistent **full-duplex** connection for true two-way messaging — chat, games, collaboration — at the cost of WebSocket-aware infra and harder (stateful) scaling that usually needs sticky routing plus a Redis pub-sub backplane. When the client is **disconnected** (mobile app asleep/backgrounded), none of these apply — you hand the message to a managed **push service** (**Google FCM**, **APNs**, or **AWS SNS** as a cross-platform front door) that wakes the device, treating the notification as a best-effort nudge while the real message syncs from your store on reconnect. Rule of thumb: **one-way → SSE, two-way → WebSockets, otherwise poll — and push notifications to reach a client that isn't connected.**
