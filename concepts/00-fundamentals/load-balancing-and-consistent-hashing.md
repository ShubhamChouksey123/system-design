# Load Balancing & Consistent Hashing

> **Reference:** *System Design Interview* by Alex Xu — load balancing (Ch 1), consistent hashing (Ch 5).
> **Goal:** The two core techniques for distributing work across machines — **load balancing** spreads *requests* across stateless servers; **consistent hashing** spreads *data/keys* across stateful nodes with minimal reshuffling when the fleet changes.
> **Prerequisite:** [horizontal scaling](./basics.md#3-scalability) — both exist because you scaled *out*.

---

## Part A — Load Balancing

A **load balancer (LB)** sits between clients and a pool of servers and distributes requests across them — the piece that makes **horizontal scaling** work. Why:
- **Spread load** so no server is overwhelmed.
- **High availability** — a server fails its health check → LB stops routing to it; users never notice.
- **Elasticity** — add/remove servers with no downtime (rolling deploys).
- **Hides the fleet** — clients see one endpoint, not individual servers.

**Types:**
| Type | Operates at | Routes on | Notes |
|---|---|---|---|
| **L4 (transport)** | TCP/UDP | IP + port | Fast, protocol-agnostic; can't see HTTP |
| **L7 (application)** | HTTP/HTTPS | URL, headers, cookies | Content routing, TLS termination |
| **DNS** | DNS resolution | Different IPs | Coarse geo/round-robin; no health awareness |

Software LBs (NGINX, HAProxy, cloud ELB/ALB) are the norm today.

**Algorithms:**
| Algorithm | Picks | Best when |
|---|---|---|
| **Round robin** | Next in rotation | Servers roughly equal |
| **Weighted round robin** | Biased by capacity | Servers differ in size |
| **Least connections** | Fewest active conns | Uneven request durations |
| **Least response time** | Fastest responder | Latency-sensitive |
| **IP / URL hash** | Hash of client/key | Same client → same server |

**Health checks:** LB pings each server (`GET /health`), drops unhealthy ones from rotation, re-adds on recovery. The LB itself must be **redundant** (active–passive with floating IP, or active–active) — never a single point of failure.

**Prefer stateless:** in-memory session state forces **sticky sessions** (same user → same server), which unbalances load and breaks when that server dies. Instead keep servers **stateless** with session state in a shared store (Redis/DB) — any server serves any request.

> **Takeaway:** an LB turns "N servers" into one highly-available, elastic endpoint — if the servers are stateless. It distributes **requests**; it doesn't decide where **data** lives. That's the next problem.

---

## Part B — Consistent Hashing

**The problem:** route cache keys with **modulo hashing** `node = hash(key) % N` and it works — until `N` changes. Add/remove one node and the modulus shifts, so **almost every key remaps**: a **cache-miss storm** (all traffic falls through to the DB), or moving nearly all the data for a database.

```
4 → 5 nodes with hash(key) % N:  ~80% of keys move.   ❌
```

**The idea — a hash ring:** map both **servers** and **keys** onto one circular hash space (`0 … 2^32-1`). A key belongs to the **first server clockwise** from its position.

```
        ┌───── S1 ─────┐
   keyA │    (ring)     │ keyB
        S3 ──────────── S2   → key goes clockwise to next server
```

**Why it's better:** adding/removing a node moves only the keys between it and its neighbor — roughly **`K/N`** keys, not all of them.

```
Add/remove a node with consistent hashing:  ~1/N of keys move.   ✅
```

**Virtual nodes (essential):** with few servers, random ring placement creates uneven arcs → **hotspots**. Give each physical server **many virtual nodes** scattered around the ring; load evens out, and a removed server's keys spread across many others.

**Used by:** distributed caches (Memcached, Redis sharding), databases (**DynamoDB**, **Cassandra**), CDNs.

| Pros | Cons |
|---|---|
| Minimal key movement on resize (`~K/N`) | More complex than modulo |
| Avoids cache-miss storms | Needs virtual nodes to balance |
| Smoothly handles nodes joining/leaving | Uneven if poorly configured |

> **Takeaway:** consistent hashing **partitions data across stateful nodes** so a resize reshuffles a small fraction of keys — the standard answer to *"how do you scale a distributed cache/DB?"* (a [session-01](../../practice/README.md) gap).

---

## Load Balancing vs Consistent Hashing

| | **Load balancing** | **Consistent hashing** |
|---|---|---|
| Distributes | **Requests** | **Data / keys** |
| Across | Stateless app servers | Stateful nodes (cache, DB) |
| Goal | Even load, high availability | Minimal reshuffling on resize |
| Algorithm | Round robin, least connections | Hash ring + virtual nodes |

Complementary: the LB spreads traffic across the stateless tier; consistent hashing decides which cache/DB node owns each key behind it.

---

## One-Paragraph Summary

A **load balancer** fronts a server pool and spreads **requests** across it (round robin, least connections, IP hash…), drops unhealthy servers via health checks, and must itself be redundant — making horizontal scaling and HA work, *if* servers are **stateless** (session in a shared store, not sticky sessions). **Consistent hashing** distributes **data/keys** across stateful nodes: naive `hash(key) % N` remaps nearly all keys when `N` changes (cache-miss storm), while a **hash ring** (key → next server clockwise) moves only ~`K/N` keys on resize, with **virtual nodes** for balance. LB distributes requests; consistent hashing distributes data.
