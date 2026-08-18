# Consistency Models — strong, eventual, causal, quorum

---

Once data is **replicated** across nodes, "consistency" means: *when I read, do I see the latest write?* The answer is a **spectrum**, not yes/no — and where you sit on it trades **correctness against latency and availability**. This is the deep dive on the [CAP theorem](../05-databases-and-storage/databases-fundamentals.md) choice and the [quorum](../05-databases-and-storage/databases-scaling.md) knob; it's the root cause of the replication-lag miss in [session 01](../../practice/01-session/README.md).

## 1. Why consistency is a spectrum

A write lands on one replica; other replicas catch up over the network (**replication lag**). Between the write and full propagation, a read from a lagging replica sees **stale data**. The consistency model is the **contract** for what staleness is allowed. Stronger guarantees need more coordination → **higher latency**, and (per CAP) **less availability** during a partition.

## 2. The main models (strong → weak)

| Model | Guarantee | Cost |
|---|---|---|
| **Linearizable (strong)** | every read sees the **latest** committed write, as if one copy | highest latency, needs coordination |
| **Sequential** | all nodes see operations in the **same order** (not necessarily real-time) | slightly cheaper than linearizable |
| **Causal** | operations that are **cause-and-effect** related are seen in order; unrelated ones may differ | mid — no global clock needed |
| **Eventual** | if writes stop, replicas **eventually** converge; reads may be stale meanwhile | cheapest, most available |

**Strong vs eventual is the axis interviewers probe:** strong = simple to reason about, but slower and less available (**CP**); eventual = fast and always-on, but the app must tolerate stale reads (**AP**).

## 3. Quorum — tuning consistency with N/R/W

Instead of "strong or nothing," systems like **DynamoDB / Cassandra** let you **tune** it per query. With **N** replicas, **W** = nodes a write must ack, **R** = nodes a read must query:

- **`W + R > N` → strong-ish consistency** (read and write sets overlap, so a read hits ≥1 up-to-date node).
- **`W + R ≤ N` → faster but possibly stale.**
- Examples: `N=3`: `W=3,R=1` (fast reads, slow writes), `W=1,R=3` (fast writes), `W=2,R=2` (balanced, quorum).

This makes consistency a **per-operation dial**, not a fixed property.

## 4. Client-centric (session) guarantees — the practical ones

Full linearizability is often overkill; users just need their **own** experience to be sane. These weaker guarantees fix the common bugs:

- **Read-your-writes** — after you post a comment, *you* always see it (even if others don't yet). Fixes the exact session-01 problem: "created a short URL but the read replica hasn't caught up." Mitigation: route a user's reads to the primary (or the replica that has their write) for a short window.
- **Monotonic reads** — you never see time go **backward** (a value you saw doesn't disappear on the next read). Pin a client to one replica.
- **Monotonic writes** — a client's writes apply **in order**.

## 5. Real-world systems

| System | Consistency |
|---|---|
| **Google Spanner** | **strong / linearizable** globally (TrueTime atomic clocks) |
| **PostgreSQL / MySQL (single primary)** | strong on the primary; replicas eventually consistent |
| **Cassandra** | **tunable** per query (`ONE`, `QUORUM`, `ALL`) |
| **Redis (async replication)** | eventual (replica may lag / lose last writes on failover) |
| **AWS DynamoDB** | eventual by default, **strongly-consistent read** option (per request) |
| **AWS S3** | **strong read-after-write** for objects (since 2020 — was eventual, a classic interview note) |
| **AWS Aurora / RDS** | strong on the writer; **read replicas** eventually consistent (replica lag) |
| **AWS ElastiCache (Redis)** | eventual (async replication to replica nodes) |
| **AWS Keyspaces** | managed Cassandra — **tunable** consistency per request |

## 6. When to use what

- **Strong / linearizable** → money, inventory, unique usernames, anything where a stale read is *wrong* (bank balance, "seat already booked").
- **Eventual** → likes, view counts, feeds, DNS, caches — stale-for-seconds is fine and availability/latency matter more.
- **Causal** → comment threads, chat (a reply must not appear before the message it answers).
- **Read-your-writes / monotonic** → almost always worth adding for UX, cheaply, without going fully strong.

## 7. One-Paragraph Summary (for quick revision)

Consistency in a replicated system is a **spectrum** set by how much staleness a read may see, trading **correctness vs latency/availability**. **Linearizable (strong)** reads always return the latest write but need coordination (slow, **CP**); **eventual** lets replicas converge over time (fast, always-on, **AP**) but exposes stale reads; **causal** preserves cause-and-effect order without a global clock. **Quorum** systems (DynamoDB, Cassandra) make it a **dial** — with N replicas, `W + R > N` gives strong-ish reads, less gives speed. In practice you rarely need full linearizability; **client-centric guarantees** — **read-your-writes** (see your own post immediately — the fix for replication-lag UX bugs) and **monotonic reads** (time never goes backward) — solve most problems cheaply. Choose **strong** for money/inventory/uniqueness, **eventual** for likes/feeds/caches, and **causal** for chat/threads. Real systems span the range: **Spanner** (strong via TrueTime), **Cassandra/DynamoDB** (tunable/eventual), single-primary SQL (strong on primary, lagging replicas).
