# Single Point of Failure (SPOF)

---

A **single point of failure** is any component whose failure takes the whole system down — one box, one link, or one dependency with no backup. Eliminating SPOFs is the core of designing for **high availability**. Related: [load balancing & consistent hashing](./load-balancing-and-consistent-hashing.md), [databases — scaling](./databases-scaling.md).

## 1. What & why

If a request path depends on a component that has **no redundancy**, that component is a SPOF: when it dies, everything behind it dies with it. Availability is a **product** across the chain — a single 90%-available link caps the whole system at ~90%, no matter how good the rest is. The fix is always the same idea: **remove the "single"** — add redundancy and automatic failover so no one instance is irreplaceable.

## 2. Common SPOFs and how to remove them

| SPOF | Fix |
|---|---|
| **Single app server** | Run **multiple stateless instances** behind a [load balancer](./load-balancing-and-consistent-hashing.md) |
| **The load balancer itself** | **Redundant LB pair** (active–passive w/ floating IP, or active–active) |
| **Single database** | **Replication** (leader + followers) with automatic **failover** |
| **Single cache node** | Cluster with replicas + sharding (Redis Cluster / Sentinel) |
| **One data center / AZ** | Deploy across **multiple AZs / regions** |
| **Single message broker** | Clustered, **partitioned + replicated** broker (Kafka) |
| **DNS / config / secrets service** | Redundant, cached, multi-provider |
| **A human / manual step** | Automate; no single required operator |

## 3. Techniques to avoid SPOFs

- **Redundancy** — run N ≥ 2 of everything; **N+1 / N+2** capacity so losing one node doesn't overload the rest.
- **Replication** — keep copies of data on multiple nodes (leader–follower, quorum).
- **Automatic failover** — detect death (**heartbeats / health checks**) and promote a standby (leader election, e.g. via [Zookeeper/Raft](./message-queue.md)) — no manual intervention.
- **Statelessness** — keep app servers stateless (session/state in a shared store) so any instance is interchangeable and replaceable.
- **Load balancing** — spread traffic and route away from unhealthy nodes.
- **Geographic distribution** — multiple AZs/regions to survive a datacenter outage.
- **Graceful degradation** — shed non-critical features (serve stale cache, disable recommendations) instead of a total outage.
- **Eliminate cascading failures** — timeouts, retries with backoff, **circuit breakers**, and **bulkheads** so one failing dependency doesn't sink the rest.

## 4. Active-passive vs active-active

- **Active–passive (failover):** standby sits idle and takes over when the primary fails. Simpler; brief failover gap; wasted idle capacity.
- **Active–active:** all nodes serve traffic; losing one just drops capacity. Better utilization + instant tolerance, but needs load balancing and careful state handling.

## 5. Watch out

Redundancy only helps if the backup is **truly independent**. Hidden shared dependencies still create a SPOF: replicas on the **same host/rack/AZ**, all nodes behind **one load balancer** or **one power/network**, or every service hitting **one config/auth service**. **Test failure** (chaos engineering — e.g. Netflix Chaos Monkey) to prove failover actually works before production does it for you.

## 6. One-Paragraph Summary (for quick revision)

A **single point of failure** is any component with no backup whose failure downs the whole system — availability multiplies across the chain, so one fragile link caps the total. Remove SPOFs by **removing the "single"**: run **redundant, stateless instances** behind a (redundant) **load balancer**, **replicate** data with **automatic failover** (heartbeats + leader election), and spread across **multiple AZs/regions**. Choose **active–passive** (simple, idle standby) or **active–active** (better utilization, instant tolerance). Guard against **cascading failures** with timeouts, retries, circuit breakers, and bulkheads, and **degrade gracefully** rather than fail hard. Redundancy only counts if the backup is **truly independent** — beware shared hosts, racks, LBs, or a single config/auth dependency — and **test failure** (chaos engineering) to confirm failover works.
