# Atlassian Karat Round — System Design Rapid Fire (P50)

Worked answers to **10** rapid-fire system design questions reported from Atlassian P50 (Senior) rounds, pulled from **2 independent confirmed sources** — questions 1–5 and 6–10 below have zero overlap. Source: [karat-p50-round.md](https://github.com/ShubhamChouksey123/data-structures-java-solution/blob/master/docs/company-specific/atlassian/karat-p50-round.md) in the DSA repo — primary reports: [Atlassian Interview Experience, P50 Senior](https://leetcode.com/discuss/post/6817408/atlassian-interview-experience-p50-senio-t1zu/) (Q1–5) and [Atlassian SSE Offer report](https://leetcode.com/discuss/post/6344788/atlassian-senior-software-engineer-offer-ywz3/) (Q6–10, its "Round 1 – Third Party / Scenario Questions").

## Format of the round

~20 minutes, 5 questions, **2–3 minutes each** — a crisp verbal pass, not a whiteboard session. Interviewers reportedly listen for specific terminology while you talk: **scalability, fault tolerance, availability, chunking, security, geo-availability**. The answers below follow a fixed micro-template so they fit the time box: restate the constraint → name the core tension → pick an approach and justify it with one keyword → stop. Both sourced sessions independently report this exact ~20-min/5-question shape, so the format itself is now corroborated twice, even though the specific questions asked clearly vary session to session.

---

## 1. Friend Count at Scale

**Prompt:** show a user's current friend count next to every post, at massive read-heavy scale (Facebook-clone).

**Constraint:** reads (post views) vastly outnumber writes (friend-adds) — a live join does not survive this ratio at scale.

**Tension:** live-join accuracy vs. read latency/scalability.

**Answer:** Maintain a **denormalized counter** per user (`friend_count` column, incremented/decremented atomically on friend add/remove) instead of computing it with a join at read time. Serve it from **Redis** (cache-aside, key = `user_id`), so the hot read path never touches the relational store. Update the counter via an atomic `INCR`/`DECR` plus an async write-behind to the DB — not a synchronous dual write. Shard by `user_id` so no single node owns all hot users; keep **read replicas** behind the cache for the rare miss. The count can lag by milliseconds — **eventual consistency** is the right trade here.

**Keywords to land:** caching, denormalization, sharding, eventual consistency.

---

## 2. Critique a Round-Robin Load Balancer

**Prompt:** a Google-Docs-like system assigns each document to a single server via round-robin — what breaks?

**Constraint:** round-robin balances *assignment count*, not *actual load*.

**Tension:** it has no feedback loop — once a document is assigned, the LB never revisits that decision even if the document's traffic explodes.

**Critique first (this is the actual skill being tested):**

- **Hotspots** — a document that goes viral (many concurrent editors) sits on one server regardless of load, while a neighbor server idles.
- **Capacity mismatch** — round-robin assumes all servers and all documents are equal; real traffic is power-law distributed, so this assumption breaks immediately.
- **Fault tolerance / SPOF** — one server owns every document pinned to it; that server going down takes all of them with it.

**Fix:** replace static round-robin with **consistent hashing** (stable document→server mapping that rebalances cheaply when servers are added/removed) layered with **least-loaded / dynamic routing** that factors in active-connection count or CPU, not just an assignment counter. For a genuinely hot document, let it escape single-server ownership via replication/multi-leader fan-out rather than trying to solve it purely at the LB layer.

**Keywords to land:** hotspot, consistent hashing, fault tolerance, dynamic/load-aware routing.

---

## 3. Consistency Models Across Three Systems

**Prompt:** choose strong vs. eventual consistency for (a) a low-latency video metadata API, (b) a web analytics/clickstream logging platform, (c) a banking system — justify each differently.

| System | Model | Why |
|---|---|---|
| (a) Video metadata API | **Eventual** | Title/view-count/thumbnail tolerate seconds of staleness; priority is low read latency at huge, geo-distributed scale (CDN-fronted reads). CAP: favor **availability** over consistency. |
| (b) Web analytics / clickstream | **Eventual** (even more aggressively) | Append-only, high-throughput, nobody reads a click the millisecond it lands. Batch/windowed aggregation is fine; at-least-once ingestion with downstream dedup is the standard pattern. |
| (c) Banking system | **Strong** | A stale balance read or a double-spend is a correctness bug with financial consequences. Needs ACID transactions / strong consistency (single-writer or quorum writes, synchronous replication) even at a latency cost. CAP: favor **consistency** over availability. |

**Keywords to land:** CAP trade-off, latency vs. correctness, append-only vs. transactional, staleness tolerance.

---

## 4. Multi-Stage Pipeline Throughput

**Prompt:** a pipeline has stages with capacities 10, 20, and 50 docs/second — what's the max throughput, and how would you optimize it?

**Answer:** Max sustained throughput = **min(10, 20, 50) = 10 docs/sec** — a pipeline's throughput is bounded by its **slowest/bottleneck stage**; faster stages idle or buffer waiting on the slow one.

**Optimization:** don't scale the whole pipeline — scale **only the bottleneck**. Add parallel workers for stage 1 (e.g. 3× workers ≈ 30 docs/sec there), fronted by a **queue** between stages so stage 1 fans out to multiple consumers without stage 2/3 needing to change. Re-measure after scaling — the bottleneck moves to whichever stage is now smallest (scale stage 1 to 30, and stage 2 at 20 becomes the new ceiling).

**Keywords to land:** bottleneck, horizontal scaling of the slow stage, queue-based decoupling/backpressure.

---

## 5. Product-Agnostic Tagging System

**Prompt:** design tagging across Jira/Confluence/Bitbucket — add/remove tags, view all content for a given tag, a popular-tags dashboard.

**Tension:** tags must point at heterogeneous entities (issue, page, repo) without each product baking in its own tag logic, and "all content for tag X" needs to be fast, not a cross-product scan.

**Answer:**

- Model entities product-agnostically with a composite key **`(entity_type, entity_id)`** so a tag doesn't care what it's attached to.
- Store the forward mapping `entity → tags` in the primary store, but build an **inverted index** `tag → [entity_ids]` (Elasticsearch or a wide-column store keyed by tag) so "show all content for tag X" is a direct lookup, not a scatter-gather across three products.
- For the **popular-tags dashboard**, don't compute it live — maintain a running counter per tag (incremented/decremented on tag add/remove) in a cached leaderboard (Redis sorted set, `ZINCRBY`) for **top-N aggregation**, rather than recomputing counts on every dashboard load.

**Keywords to land:** inverted index, cross-product entity modeling, top-N aggregation, caching.

---

## 6. Consistent Hashing Issues in Music Streaming Servers

**Prompt:** critique what goes wrong with consistent hashing for distributing load across music-streaming servers.

**Constraint:** load isn't uniform — some songs/artists are vastly more popular than others.

**Tension:** consistent hashing minimizes remapping on node add/remove, but it does nothing about *skew* — a popular key still lands on one node and can overload it.

**Critique first:**
- **Hot-key skew** — a viral song's stream requests all hash to the same node regardless of how "consistent" the hashing is; consistent hashing solves *rebalancing cost*, not *load uniformity*.
- **Non-zero remapping on churn** — adding/removing a node still remaps the keys in that node's arc, which for a popular key means a sudden full-load shift onto whichever node inherits it.

**Fix:** use **virtual nodes** (each physical server owns many points on the hash ring) to smooth distribution and shrink the blast radius of any one remap. For genuinely hot keys, add **replication** of that specific key/song across multiple nodes (read-replica fan-out) rather than relying on the hash ring alone to spread its load.

**Keywords to land:** consistent hashing, virtual nodes, hot-key skew, replication.

---

## 7. Pre-loaded Hints vs. Server-loaded Hints

**Prompt:** pros/cons of shipping hints bundled with the app vs. fetching them from the server at runtime.

**Constraint:** hints need to be both fast to show and able to change without forcing a client update.

**Tension:** latency/offline-availability (client-side) vs. freshness/control (server-side).

**Answer:** **Pre-loaded (bundled)** wins on latency and offline support — zero network round-trip, works with no connectivity — but freezes content until the next app release, and bloats the install size as hint volume grows. **Server-loaded** wins on freshness — update hints anytime, no release needed, supports personalization/A-B testing server-side — at the cost of a network dependency and latency on first load. **Middle ground:** ship a small default set pre-loaded for instant first-paint/offline fallback, then fetch and **cache with a TTL** server-side hints in the background for freshness without blocking the UI.

**Keywords to land:** latency, offline availability, freshness, caching with TTL.

---

## 8. Processing Files Larger Than RAM

**Prompt:** how do you process a file that doesn't fit in memory on a single machine?

**Constraint:** the file is bigger than available RAM — a naive "load it all, then process" approach OOMs.

**Tension:** correctness/simplicity of in-memory processing vs. the memory ceiling.

**Answer:** **Stream the file in chunks** rather than loading it whole — read, process, and discard each chunk, keeping only a bounded working set in memory. For something like sorting, use an **external merge sort**: sort fixed-size chunks that fit in memory, write each to disk, then merge the sorted chunks. **Memory-mapped files** (`mmap`) are a middle option — let the OS page data in/out instead of manually chunking. If this is a recurring, large-scale need rather than a one-off, distribute the file **across workers** (MapReduce-style: split, process in parallel, combine).

**Keywords to land:** streaming/chunking, external merge sort, memory-mapped files, distributed processing.

---

## 9. Sports News Classification Service (ML-based Bias Detection)

**Prompt:** design considerations for a service that classifies news content for bias using ML.

**Constraint:** this is unusually ML-flavored for a backend screen — the grading is almost certainly on the *systems* half, not the model itself.

**Tension:** real-time classification expectations vs. ML inference being inherently slower/costlier than a typical API call.

**Answer:** Treat the model as a black-box dependency behind an **async inference queue** — ingest articles, enqueue for classification, don't block the write path on inference latency. Serve the model behind its own scalable inference service (batch requests where possible to amortize GPU/CPU cost). Store classification results alongside the article so repeat reads are a cache hit, not a re-inference. Close the loop with a **feedback/retraining pipeline** (flagged misclassifications feed back into the training set) — naming this explicitly signals you're thinking about the system around the model, not just a single inference call.

**Keywords to land:** async processing, inference service, caching results, feedback loop.

---

## 10. Backend Considerations for Going Multi-Country

**Prompt:** what backend changes are needed when a production app expands beyond a single country?

**Constraint:** a single-region deployment assumption breaks the moment users and data span countries.

**Tension:** global consistency/simplicity vs. per-region latency, compliance, and locale correctness.

**Answer:** **Data residency/compliance** first — some countries (GDPR-style regulation) require user data to stay within region, which drives a **regional data-storage** design rather than one global DB. **Latency** next — deploy regionally (or front with a CDN for static/cacheable content) so users aren't round-tripping to a single distant region. **Locale/timezone handling** — don't bake in assumptions about date formats, currency, or a single timezone. Finally, **multi-region consistency trade-offs** — if data must sync across regions, that's an eventual-consistency / conflict-resolution problem, not a single-writer assumption anymore.

**Keywords to land:** data residency, regional deployment/CDN, locale handling, multi-region consistency.

---

## Drilling notes

- You get ~2–3 minutes each — barely enough for *one* structured answer. Rehearse the micro-template out loud with a timer, don't improvise a full design.
- For question 2's "critique X" shape specifically: **critique before proposing** — naming what's wrong is the graded skill, the fix is secondary.
- Consciously work 2–3 of the cue words (scalability, fault tolerance, availability, chunking, security, geo-availability) into each answer — reportedly a scoring signal independent of the idea itself.
