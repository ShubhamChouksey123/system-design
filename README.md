# System Design Interview Preparation — Notes, Cheat Sheets & Mock Interviews

> **Depth-first system design notes + scored mock-interview logs** for **Senior Software Engineer** interviews at product-based / FAANG-style companies. Built for *understanding and revision*, not memorization.

A free, open **system design interview preparation** resource: concise concept notes, revision cheat sheets, back-of-the-envelope estimation, and **real mock-interview transcripts with scorecards**. Written for the **senior engineering bar** — every concept ties a design decision to its architectural consequence, and every mock is scored so you can see *what actually loses points in the room* and fix it.

**Keywords:** system design interview questions · senior software engineer · scalability · consistent hashing · load balancing · caching · databases & sharding · Kafka · API design · distributed systems.

## Contents

- [What makes this different](#what-makes-this-different)
- [Topics covered](#topics-covered)
- [Mock interviews](#-mock-interviews--practice-log-)
- [How to use these](#how-to-use-these)
- [Status](#status)
- [Source & credit](#source--credit)

## What makes this different

- 🎯 **Senior-depth concept notes** — not "what is a load balancer" but *which* choice, *why*, and *what it trades*. Tables and one-paragraph summaries over prose walls.
- 🎤 **Scored mock-interview transcripts** — each mock includes the problem, the design produced, a **/10 five-axis scorecard**, and consolidated feedback aggregating recurring weak spots across sessions. Almost nobody publishes this.
- 🔁 **Revision-first format** — every concept ends with a quick-revision summary; diagrams where a picture argues better than prose.
- ✅ **Verified, not vibes** — facts checked against primary sources (RFCs, specs), not repeated from blogs.

## Topics covered

Nine ordered sections — the **[full concept index & progress tracker is here →](./concepts/README.md)**. Each doc goes *what it is / why it's asked → reference tables → worked example or diagram → one-paragraph summary*.

| Section | Concepts include |
|---|---|
| **00 · Interview Framework** | how to run a system design interview, in-the-room checklist |
| **01 · Estimation** | back-of-the-envelope: QPS, storage, bandwidth, worked examples |
| **02 · Foundations** | cloud, scalability, monolith vs microservices |
| **03 · Networking & Delivery** | load balancing, **consistent hashing**, CDN |
| **04 · APIs** | HTTP, REST, gRPC, GraphQL, webhooks, OAuth 2.0 / JWT / SAML, API security |
| **05 · Databases & Storage** | SQL vs NoSQL, replication, **sharding/partitioning**, object storage, full-text search, OLTP vs OLAP |
| **06 · Caching** | cache strategies, eviction (LRU/LFU/TTL), **Redis & Memcached** |
| **07 · Messaging & Events** | message queues, **Apache Kafka**, event-driven architecture |
| **08 · Distributed Systems** | single point of failure, consistency, consensus *(in progress)* |

## 🎤 Mock interviews — [practice log →](./practice/README.md)

Real system-design mock interviews, each in a `NN-session/` folder with the full transcript, the interviewer's **scorecard** (Requirements · Design · Problem-Solving · Scale & Trade-offs · Communication), and per-session tips. The tracker rolls them into **consolidated tips by axis** and **recurring action items** — turning weak spots into a study plan. Includes the [8-step answer framework](./practice/answer-framework.md) to run in the room.

Example — *Session 01: design a URL shortener (bit.ly / TinyURL)* → scored 5.9/10, with a breakdown of exactly which fundamentals (base62 keys, HTTP 3xx redirects, consistent hashing) cost points.

## How to use these

1. **Learn** — read a concept top-to-bottom once for understanding.
2. **Revise** — before an interview, reread just the cheat-sheet / one-paragraph summary sections.
3. **Practice** — attempt the practice problems before peeking at the solution sketches.
4. **Rehearse** — dry-run the [answer framework](./practice/answer-framework.md) and the [in-the-room checklist](./concepts/00-framework/system-design-interview-framework.md) before a mock.
5. **Reflect** — log each mock in the [practice tracker](./practice/README.md) and promote repeated feedback into the recurring-themes list.

## Status

**Actively developed** — concepts are written and studied *depth-first* before mock practice ramps up. Live counts (written / read / revised) are in the [progress tracker](./concepts/README.md#-progress-tracking). ⭐ Star the repo to follow along.

## Source & credit

Distilled and expanded from *System Design Interview – An Insider's Guide* by **Alex Xu** — a genuinely excellent book worth buying. These are **original notes, examples, and diagrams** inspired by its chapters; the book's own text and figures are not reproduced here.
