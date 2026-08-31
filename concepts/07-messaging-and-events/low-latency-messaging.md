# Low-Latency Messaging — UDP Multicast, Aeron & Ring Buffers

---

[Kafka](./apache-kafka.md) and [message queues](./message-queue.md) sit at the **durable, milliseconds** end of the spectrum: they persist every message and let many consumers replay it. But some systems — a stock exchange's price feed, an ad-bidding fabric, telemetry fan-out — need the **opposite trade-off**: get one event to thousands of listeners in **microseconds**, and it's fine if a stale tick is dropped. This doc covers the transport used there.

## 1. The core problem: one event, huge fan-out, no time

A matching engine produces a price change and it must reach **thousands of edge servers** (which each hold millions of client connections) almost instantly. The naive way — loop and send one copy per listener — is both slow and *unfair*: the last listener hears the news much later than the first.

```
  Unicast loop (naive)              Multicast (one send)
  sender → listener 1                          ┌─▶ listener 1
  sender → listener 2   (N syscalls, N copies) │   listener 2   (network duplicates,
  sender → listener 3                sender ──▶ ┤   listener 3    all at once)
  ...uneven, O(N) on the sender                └─▶ ...
```

## 2. Unicast vs multicast

| Mode | Who receives | Cost on sender | Use |
|---|---|---|---|
| **Unicast** | one specific host | one send **per** receiver | normal request/response, TCP |
| **Multicast** | every host that **joined a group** | **one** send, network copies it | one-to-many fan-out inside a data center |
| **Broadcast** | every host on the subnet | one send, floods all | rarely used; too noisy |

**Multicast** uses a special group address (IPv4 `224.0.0.0`–`239.255.255.255`); receivers "join" the group and the switch/router delivers a copy to each. One send → all listeners at the same instant. It works **only inside your own network** — the public internet doesn't route multicast — so it's an *internal bus*, not a client-facing transport.

## 3. Why UDP, not TCP

| | **TCP** | **UDP** |
|---|---|---|
| Connection | handshake, per-connection state | connectionless, fire-and-forget |
| Shape | one-to-one only | supports **multicast** one-to-many |
| Reliability | acks, retransmit, in-order | **none** — a lost packet is just gone |
| Head-of-line blocking | yes (one loss stalls the stream) | no |
| Latency | higher, with jitter | **lowest possible** |

For a huge-fan-out, latency-critical feed you want UDP's speed and multicast ability. The catch is UDP's **no reliability** — which is where Aeron comes in.

## 4. Aeron — reliable multicast without TCP's latency

**Aeron** is an open-source messaging library (from the LMAX team, same people as the Disruptor) built **on top of UDP** that adds back what you need at microsecond latency and **zero garbage**:

- **Reliable delivery** — detects loss via sequence numbers, retransmits from a send buffer (NAK-based), without TCP's per-connection cost.
- **Flow control & ordering** — keeps fast senders from drowning slow receivers.
- **Multicast or unicast** — same API; pick per deployment.

Rule of thumb: **raw UDP multicast** when an occasional dropped tick is acceptable (and clients resync from a snapshot); **Aeron** when you need "multicast speed *and* I won't silently lose data."

## 5. The producer side: ring buffer + conflation

The event source (e.g. a matching engine) must **never block** on distribution. The pattern:

- **Ring buffer (LMAX Disruptor)** — a pre-allocated, lock-free circular buffer. The producer writes an event and moves on (wait-free); a separate publisher thread reads and sends. No locks, no garbage-collection pauses (events are reused, not allocated).
- **Conflation** — if 50 updates for the same symbol arrive in 1 ms, collapse to the **latest** before sending. A human watching a browser can't see 50 ticks/ms; conflation slashes bandwidth and prevents a slow consumer from falling behind on stale data.
- **Per-key sequence numbers** — stamp each update so a receiver can detect a **gap** ("I missed #7") and resync from a snapshot.

## 6. Real-world technologies

| Technology | What it is | Notes |
|---|---|---|
| **Aeron** | reliable low-latency UDP messaging | HFT, exchanges; µs latency, zero-GC |
| **LMAX Disruptor** | lock-free ring buffer (in-process) | the producer→consumer handoff; single-writer |
| **IP multicast (UDP)** | network one-to-many primitive | the raw bus; internal only |
| **ZeroMQ / nanomsg** | brokerless messaging patterns | pub/sub incl. multicast; lower ceremony |
| **AWS** | multicast via **AWS Transit Gateway** | cloud multicast is limited vs on-prem |

For the **client-facing** last hop (edge servers → browsers), you still use [WebSocket / SSE](../04-apis/realtime-communication.md) — multicast stops at the edge tier.

## 7. When to use — Kafka vs in-memory multicast

| Need | Pick | Why |
|---|---|---|
| Durable, replayable, many independent consumers, ms is fine | **[Kafka](./apache-kafka.md)** | persisted log, consumer groups, replay by offset |
| Ephemeral, µs latency, one-to-thousands fan-out | **UDP multicast / Aeron** | network does the copying; no disk on the path |
| Both (e.g. a trading venue) | **tee the feed** | Kafka for settlement/audit/portfolio; multicast for the live price feed |

Routing a latency-critical live feed *through* Kafka inherits its broker fsync + poll latency (and worse tail latency) — acceptable for ms-tolerant retail screens, disqualifying for µs-critical algo consumers. When both audiences exist, emit once to each transport.

## 8. One-Paragraph Summary (for quick revision)

When one event must reach thousands of listeners in **microseconds** and dropping a stale update is acceptable, the durable-log model ([Kafka](./apache-kafka.md)) is too slow — you switch to **UDP multicast**, where the sender transmits **once** to a group address and the **network duplicates** the packet to every joined receiver at the same instant (unicast would loop and be O(N) and unfair). UDP gives the speed and one-to-many ability but **no reliability**, so **Aeron** layers NAK-based retransmit, flow control, and ordering on top at µs latency with **zero GC**. On the producer side a lock-free **ring buffer (LMAX Disruptor)** keeps the source from ever blocking, and **conflation + per-key sequence numbers** cut bandwidth and let receivers detect gaps and resync from a snapshot. Multicast is **internal-only** (the public internet doesn't route it), so the client-facing last hop stays [WebSocket/SSE](../04-apis/realtime-communication.md). Choose **Kafka** for durable, replayable, ms-tolerant consumers; **multicast/Aeron** for ephemeral µs fan-out; and **tee both** when a system (like a trading venue) has each kind of consumer.
