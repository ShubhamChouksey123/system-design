# Non-Functional Requirements — the System Design Vocabulary

---

**Functional requirements** say *what* the system does ("shorten a URL", "post a tweet"). **Non-functional requirements (NFRs)** — the **"-ilities"** — say *how well* it must do it, and they drive almost every architecture decision. Interviewers probe these terms precisely, and several are routinely confused. This doc is the shared vocabulary; each term links to its deep dive.

## 1. The vocabulary at a glance

| Term | One-line definition | Measured / expressed as | Deep dive |
|---|---|---|---|
| **Availability** | % of time the system is **up and serving** | "nines" — `uptime ÷ (uptime + downtime)` | [SPOF & HA](../08-distributed-systems/single-point-of-failure.md) |
| **Reliability** | it works **correctly** — right answer, no data loss | MTBF, error rate, data-loss probability | [observability / SLO](../09-reliability-and-operations/observability.md) |
| **Fault tolerance** | keeps working **despite** component failures | survives *N* node / AZ / region failures | [SPOF](../08-distributed-systems/single-point-of-failure.md) |
| **Resilience** | **recovers** from failure and degrades gracefully | MTTR, fallback behavior under fault | [resilience patterns](../09-reliability-and-operations/resilience-patterns.md) |
| **Scalability** | handles **more load** by adding resources | load ceiling; cost curve vs load | [scalability](./basics.md) · [LB](../03-networking-and-delivery/load-balancing-and-consistent-hashing.md) |
| **Performance** | how **fast** at a given load — latency + throughput | see the two rows below | [caching](../06-caching/caching.md) |
| **Latency** | time to serve **one** request | response time, **p50 / p95 / p99** (ms) | [estimation](../01-envelope-estimation/back-of-the-envelope-estimation.md) |
| **Throughput** | **how many** requests per unit time | QPS / RPS, MB/s, events/s | [estimation](../01-envelope-estimation/back-of-the-envelope-estimation.md) |
| **Consistency** | do all readers see the **same, latest** data? | strong / eventual / causal; staleness window | [consistency models](../08-distributed-systems/consistency-models.md) |

## 2. The distinctions interviewers probe

The confusable ones — being crisp here signals seniority:

| Confusion | The distinction |
|---|---|
| **Availability vs Reliability** | Available = **responds**; Reliable = **responds correctly**. A system can be up but returning wrong/stale data (available, not reliable) — or correct whenever up but often down (reliable, not available). |
| **Fault tolerance vs Resilience** | Fault tolerance = **masks** a failure so users never notice (redundant replica takes over). Resilience = **recovers** from failures that *do* land (retries, circuit breakers, graceful degradation, fast MTTR). |
| **Latency vs Throughput** | Latency = **speed of one** request; throughput = **volume per second**. Independent: a batch pipeline has high throughput *and* high latency; adding a queue can raise throughput while *raising* latency. |
| **Performance vs Scalability** | Performance = fast **at today's load**; scalability = **stays** fast as load grows 10×/100×. A design can be fast for one user yet fall over at scale. |
| **Consistency** | Its **own axis** (not a reliability sub-type) — the [CAP](../08-distributed-systems/consistency-models.md) trade-off: under a network partition you choose consistency **or** availability. |

## 3. Availability — the "nines"

Availability is stated as **nines**; each nine is ~10× less downtime:

| Availability | Downtime / year | Downtime / month | Typical use |
|---|---|---|---|
| **99%** ("two nines") | ~3.65 days | ~7.2 h | internal / best-effort |
| **99.9%** ("three nines") | ~8.76 h | ~43 min | standard web service |
| **99.99%** ("four nines") | ~52 min | ~4.3 min | serious production SLA |
| **99.999%** ("five nines") | ~5.26 min | ~26 s | telecom / critical infra |

You buy nines with **redundancy** (no [SPOF](../08-distributed-systems/single-point-of-failure.md)), **failover**, and **multi-AZ / multi-region** — each nine costs exponentially more, so match it to the business, don't chase 100%.

## 4. They trade off against each other

NFRs **fight**; naming the tension is the senior move:

- **Consistency ↔ Availability** — CAP: partitions force a choice (strong consistency *or* stay available with stale reads).
- **Latency ↔ Consistency / Durability** — synchronous replication and quorum reads add latency; async is faster but risks staleness/loss.
- **Performance ↔ Cost** — caches, replicas, and CDNs buy speed and availability with money and added complexity.
- **Throughput ↔ Latency** — batching and queues lift throughput but delay the individual request.

## 5. In the interview

- **Elicit them in the scoping phase** — before designing, pin the **target availability (nines)**, **latency budget (p95/p99)**, expected **throughput (QPS)**, and the **consistency** the domain needs (a bank ≠ a "likes" counter).
- **Quantify** — "three nines and p99 < 200 ms at 10k QPS", not "highly available and fast". This maps onto the [answer framework](../../practice/answer-framework.md) non-functional-requirements step.
- **Tie every number to a decision** — a latency budget justifies a cache/CDN; a throughput number sizes the fleet; a consistency choice picks the database.

## 6. One-Paragraph Summary (for quick revision)

**Non-functional requirements** — the **"-ilities"** — define *how well* a system must behave and drive its architecture. **Availability** (it responds — measured in **nines**) is distinct from **Reliability** (it responds *correctly*) and from **Fault tolerance** (it **masks** failures via redundancy) and **Resilience** (it **recovers** — retries, circuit breakers, low MTTR). **Scalability** is staying fast as load grows (vs **Performance**, being fast at today's load), and Performance itself splits into **Latency** (speed of one request, tracked as **p95/p99**) and **Throughput** (requests/sec — independent of latency). **Consistency** is its own axis — the **CAP** trade-off of strong vs eventual. These properties **trade off** (consistency ↔ availability, latency ↔ durability, performance ↔ cost), so in an interview **quantify them up front** — target nines, a p99 latency budget, peak QPS, and the consistency the domain needs — and tie each number to a concrete design decision.
