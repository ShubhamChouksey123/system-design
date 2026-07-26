# Back-of-the-Envelope Estimation

---

## 1. What It Is & Why Interviewers Ask

A **back-of-the-envelope estimation** is a rough calculation you do using a few assumptions and standard numbers to arrive at an order-of-magnitude answer (e.g., *"~3,500 tweets per second, ~55 PB of media over 5 years"*).

> Jeff Dean (Google Senior Fellow): *"Back-of-the-envelope calculations are estimates you create using a combination of thought experiments and common performance numbers to get a good feel for which designs will meet your requirements."*

**Interviewers use it to check whether you can:**
- Translate a vague product ("a Twitter clone") into concrete scale (QPS, storage, bandwidth).
- Decide **whether a design is even feasible** (Can it fit in memory? Do we need sharding? One server or a fleet?).
- Reason about **trade-offs with numbers**, not hand-waving.
- Communicate assumptions clearly and stay calm under quantitative pressure.

**What they are NOT judging:** perfect arithmetic. Being within an order of magnitude and *showing your reasoning* is what matters. State assumptions out loud, round aggressively, and keep the math clean.

---

## 2. The Three Building Blocks

Before any estimation, internalize these three reference tables. They are the "vocabulary" of estimation.

### 2.1 Powers of Two (data volume)

Data volume is expressed with powers of 2. Memorize this table — it converts byte-counts to human-readable magnitudes instantly.

| Power | Approx value | Full name | Short |
|------:|-------------:|-----------|-------|
| 2^10  | 1 Thousand   | 1 Kilobyte  | 1 KB |
| 2^20  | 1 Million    | 1 Megabyte  | 1 MB |
| 2^30  | 1 Billion    | 1 Gigabyte  | 1 GB |
| 2^40  | 1 Trillion   | 1 Terabyte  | 1 TB |
| 2^50  | 1 Quadrillion| 1 Petabyte  | 1 PB |

**Rule of thumb:** every 3 orders of magnitude in bytes = one step up (KB → MB → GB → TB → PB).

**Bytes → bits:** `1 byte = 8 bits`. This matters most for **bandwidth**, where network speeds are quoted in **bits** per second (bps) but data sizes are in **bytes**.

| Unit | Bits | Bytes |
|------|-----:|------:|
| 1 byte (B) | 8 bits | 1 B |
| 1 KB | 8 Kb (kilobits) | 1,024 B |
| 1 Kbps (network) | 1,000 bits/s | 125 B/s |
| 1 Mbps | 10^6 bits/s | 125 KB/s |
| 1 Gbps | 10^9 bits/s | 125 MB/s |

> **Watch the case:** lowercase `b` = **bit**, uppercase `B` = **byte**. So `1 Gbps` (gigabit/s) = `1 Gbps ÷ 8` = **125 MB/s** (megabytes/s). Mixing these up is one of the most common estimation mistakes — always divide network throughput by 8 to get bytes.

### 2.2 Latency Numbers Every Programmer Should Know

These are the classic "Jeff Dean latency numbers" (Alex Xu's simplified 2020 values). Notice the units.

| Operation | Latency | In friendlier units |
|-----------|--------:|----------------------|
| L1 cache reference | 0.5 ns | |
| Branch mispredict | 5 ns | |
| L2 cache reference | 7 ns | |
| Mutex lock/unlock | 100 ns | |
| Main memory reference | 100 ns | |
| Compress 1 KB with Zippy | 10,000 ns | 10 µs |
| Send 2 KB over 1 Gbps network | 20,000 ns | 20 µs |
| Read 1 MB sequentially from memory | 250,000 ns | 250 µs |
| Round trip within same datacenter | 500,000 ns | 500 µs |
| Disk seek | 10,000,000 ns | 10 ms |
| Read 1 MB sequentially from network | 10,000,000 ns | 10 ms |
| Read 1 MB sequentially from disk | 30,000,000 ns | 30 ms |
| Send packet CA → Netherlands → CA | 150,000,000 ns | 150 ms |

**Unit ladder:** `1 ns = 10^-9 s` → `1 µs = 10^-6 s = 1,000 ns` → `1 ms = 10^-3 s = 1,000 µs`.

**Takeaways from these numbers (memorize the *lessons*, not the digits):**
- **Memory is fast, disk is slow.** Avoid disk seeks whenever possible.
- **Simple compression is fast.** Compress data *before* sending over the internet.
- **Cross-region is expensive.** Datacenters in different regions add ~100 ms+ round trips.
- A network round trip inside a DC (~0.5 ms) is ~20× faster than a disk seek (~10 ms).

### 2.3 Availability Numbers ("the nines")

**Availability** = percentage of time a system is operational. SLAs (Service Level Agreements) are stated in "nines."

| Availability | Downtime / day | Downtime / year |
|-------------:|---------------:|-----------------:|
| 99%       | 14.40 min | 3.65 days |
| 99.9%     | 1.44 min  | 8.77 hours |
| 99.99%    | 8.64 s    | 52.60 min |
| 99.999%   | 864 ms    | 5.26 min |
| 99.9999%  | 86.4 ms   | 31.56 s |

**Rule of thumb:** each extra nine ≈ **10× less downtime**. "Three nines" is a common baseline for internal services; "four/five nines" is what big consumer platforms target.

---

## 3. A Repeatable Estimation Framework

Do these in order. Announce each assumption to the interviewer as you go.

```
1. Clarify scope        → What exactly are we estimating? (whole product vs. one feature)
2. State assumptions    → DAU, actions/user/day, read:write ratio, avg payload size, retention
3. Estimate QPS         → traffic (average + peak)
4. Estimate Storage     → per-item size × items × retention period
5. Estimate Bandwidth   → QPS × payload size (ingress and egress)
6. Estimate Memory      → what fits in a cache? (e.g., 20% hot data, 80/20 rule)
7. Sanity check         → Does this need 1 server or 10,000? Fit in RAM or need a DB fleet?
```

### Core formulas

**QPS (Queries Per Second):**
```
Average QPS = (DAU × actions per user per day) / 86,400
            (there are 86,400 seconds in a day ≈ 10^5)
Peak QPS    ≈ 2 × Average QPS      (rule of thumb; adjust per product)
```

**Storage:**
```
Daily storage = writes per day × average size per write
Total storage = Daily storage × retention period (days) × replication factor
```

**Bandwidth:**
```
Bandwidth = QPS × average payload size    (bytes per second)
```

### Handy constants to memorize

| Quantity | Value | Rounded for mental math |
|----------|------:|-------------------------|
| Seconds in a day | 86,400 | **~10^5** |
| Seconds in a month | 2,592,000 | **~2.5 × 10^6** |
| Seconds in a year | 31,536,000 | **~3 × 10^7** |
| Days in a year | 365 | ~400 (over-estimate) |

> **Pro tip:** 1 million requests/day ≈ **~12 requests/second** (since 10^6 / 10^5 = 10, and 86,400 is slightly less than 10^5). This single conversion covers a surprising number of interview questions.

---

## 4. Worked Example: Twitter (from the book)

This is the exact example Alex Xu walks through. Follow the framework.

### Step 1 — Assumptions
- 300 million Monthly Active Users (MAU).
- 50% of users use Twitter daily → **DAU = 150 million**.
- Users post **2 tweets per day** on average.
- **10%** of tweets contain media (image/video).
- Data is stored for **5 years**.

### Step 2 — QPS estimation
```
Tweets per day     = 150M users × 2 tweets     = 300M tweets/day
Average QPS        = 300M / 86,400 s            ≈ 3,500 QPS
Peak QPS           = 2 × 3,500                  ≈ 7,000 QPS
```

### Step 3 — Media storage estimation
Assume average sizes:
- `tweet_id`: 64 bytes
- `text`: 140 bytes
- `media`: 1 MB (only 10% of tweets)

```
Media per day  = 150M users × 2 tweets × 10% × 1 MB
               = 30M MB/day
               = 30 TB/day
5-year media   = 30 TB × 365 days × 5 years
               ≈ 55 PB
```

### Step 4 — Sanity check / conclusions
- **~7,000 peak QPS** → clearly needs load balancing and multiple app servers, not a single box.
- **~55 PB over 5 years** → object storage (e.g., S3-style blob store) + CDN for media, not a single database.
- These numbers immediately justify: separate media storage, caching, horizontal scaling.

> Notice: the *value* of the estimate is that it forces architectural decisions. 55 PB tells you "distributed blob storage"; 7K QPS tells you "fleet of servers behind a load balancer."

---

## 5. Cheat Sheet — Numbers to Have Ready

**Time:**
- 1 day ≈ 10^5 seconds (86,400) · 1 month ≈ 2.5 × 10^6 s · 1 year ≈ 3 × 10^7 s
- 1 million/day ≈ 12/second

**Typical payload sizes (assumptions you can state):**
- Text message / tweet: ~100–300 bytes
- Metadata row (id, timestamps, fk's): ~100 bytes – 1 KB
- Photo: ~200 KB – 1 MB (thumbnail ~10–50 KB)
- Short video: ~1 – 10 MB
- Web page (HTML): ~100 KB – 2 MB

**Hardware ballparks (single commodity server):**
- RAM: 128 GB – 1 TB
- QPS a single well-tuned server handles: ~1,000 – 10,000 (very workload-dependent)
- A single DB can hold billions of rows but you shard well before petabytes.

**80/20 rule:** ~20% of data is "hot" and worth caching. Handy for memory/cache sizing.

---

## 6. Interview Tips & Common Pitfalls

**Do:**
- **Round aggressively.** Use 10^5 for a day, 400 for days-in-year, powers of 10. Clean numbers = fewer errors.
- **State every assumption out loud** and write it down. "I'll assume 100M DAU and 2 writes/user/day — reasonable?"
- **Show the formula before plugging in numbers.** The interviewer follows your logic, not just your answer.
- **Label units at every step** (QPS, TB, MB/day). Most mistakes are unit slips.
- **Connect the number to a decision.** An estimate with no architectural consequence is wasted.
- **Do reads and writes separately** — the read:write ratio (often 100:1 for social feeds) drives caching/replication.

**Don't:**
- Don't aim for precision. `3,472.22 QPS` is a red flag; `~3,500 QPS` is correct behavior.
- Don't get stuck on arithmetic. If you blank on `150M × 2`, say "~3 × 10^8" and move on.
- Don't forget **peak vs. average** traffic, **replication factor** (×3 is common), and **retention period** for storage.
- Don't ignore metadata/overhead when it dominates (e.g., indexes, protocol overhead).
- Don't confuse **bits vs. bytes** for bandwidth (1 Gbps = 125 MB/s).

---

## 7. Practice Problems

Try each using the Section 3 framework. Solutions sketched below.

1. **URL shortener** — 100M new URLs/day. Estimate write QPS, read QPS (assume 10:1 read:write), and storage for 10 years (assume 500 bytes/record).
2. **Chat app (WhatsApp-style)** — 500M DAU, 40 messages/user/day, avg message 100 bytes. Estimate message QPS and daily storage.
3. **Video platform (YouTube-style)** — 5M videos uploaded/day, avg 300 MB/video. Estimate daily and yearly storage (ignore replication, then add ×3).
4. **News feed read path** — 200M DAU each opening the app 5×/day. Estimate read QPS and peak read QPS.

<details>
<summary>Solution sketches</summary>

**1. URL shortener**
- Write QPS = 100M / 86,400 ≈ **1,160 QPS** (~1.2K). Peak ≈ 2.3K.
- Read QPS = 10 × write ≈ **11,600 QPS**. Peak ≈ 23K.
- Storage/day = 100M × 500 B = 50 GB/day → 10 yr = 50 GB × 365 × 10 ≈ **~180 TB**.

**2. Chat app**
- Messages/day = 500M × 40 = 20B messages/day.
- QPS = 20B / 86,400 ≈ **231,000 QPS** (~230K). Peak ≈ 460K → needs heavy sharding.
- Storage/day = 20B × 100 B = 2 TB/day (before replication).

**3. Video platform**
- Storage/day = 5M × 300 MB = 1.5 PB/day.
- Storage/year = 1.5 PB × 365 ≈ **~550 PB/year**; with ×3 replication ≈ **~1.6 EB/year**.

**4. News feed read path**
- Reads/day = 200M × 5 = 1B reads/day.
- Read QPS = 1B / 86,400 ≈ **11,600 QPS**. Peak ≈ **23K QPS**.
</details>

---

## 8. One-Paragraph Summary (for quick revision)

Back-of-the-envelope estimation turns a vague product into concrete scale using three reference tables (**powers of two** for data volume, **latency numbers** for performance intuition, **availability nines** for SLAs) and a fixed framework: *clarify scope → state assumptions → estimate QPS → storage → bandwidth → memory → sanity check*. Memorize `1 day ≈ 10^5 s`, `Peak QPS ≈ 2 × Average QPS`, and `1M/day ≈ 12/s`. Round aggressively, label units, state assumptions aloud, and always tie the number back to an architectural decision. The Twitter example (~7K peak QPS, ~55 PB media over 5 years) shows the point: estimates exist to justify design choices, not to be precise.
