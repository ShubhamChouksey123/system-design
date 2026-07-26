# Back-of-the-Envelope Estimation — Worked Examples

> Companion to [back-of-the-envelope-estimation.md](./back-of-the-envelope-estimation.md).
> Each example follows the framework: **state assumptions → apply formula → conclude with an architectural takeaway.**

**Reminders you'll use throughout:**
- `1 day ≈ 86,400 s ≈ 10^5 s`
- `Peak ≈ 2 × Average`
- `1 byte = 8 bits` → network in bits/s, storage in bytes. `1 Gbps = 125 MB/s`.
- Storage powers: KB → MB → GB → TB → PB → **EB** (each ×1000).
- Replication factor **×3** is a common default.

> ⚠️ **Assumptions are illustrative.** Real companies' numbers differ; interviewers care that you *state* your assumptions and reason cleanly, not that you memorize the "true" figure.

---

## 1. Storage — Photo-Sharing App (1 million users)

### Assumptions
| Assumption | Value |
|---|---|
| Total users | 1,000,000 |
| Daily active (DAU) | 50% → 500,000 |
| Photos uploaded per DAU/day | 2 |
| Avg photo size (original + thumbnails) | 2 MB |
| Replication factor | ×3 |

### Math
```
Photos/day     = 500,000 DAU × 2            = 1,000,000 photos/day
Raw storage/day= 1,000,000 × 2 MB           = 2,000,000 MB = 2 TB/day
With ×3 replic = 2 TB × 3                    = 6 TB/day

Per year (raw) = 2 TB × 365                  ≈ 730 TB ≈ 0.73 PB/year
Per year (×3)  = 0.73 PB × 3                  ≈ 2.2 PB/year
```

### Takeaway
Even a "small" 1M-user app produces **~0.7 PB/year** of photos (~2 PB replicated). This immediately rules out a single disk/DB — you need **object/blob storage** (S3-style) plus a **CDN** for delivery. Metadata (who/when/caption) is tiny by comparison and lives in a regular DB.

---

## 2. Bandwidth — Video Streaming App (1 million DAU)

### Assumptions
| Assumption | Value |
|---|---|
| DAU | 1,000,000 |
| Avg watch time / user / day | 1 hour |
| Video bitrate (1080p) | 5 Mbps |

### Math (via total data, then average rate)
```
Data per user/day = 5 Mbps × 3,600 s = 18,000 Mb = 18,000 / 8 = 2,250 MB ≈ 2.25 GB
Total egress/day  = 1,000,000 × 2.25 GB ≈ 2.25 PB/day (outbound)

Average bandwidth = 2.25 PB / 86,400 s
                  = 2.25 × 10^15 B / 86,400
                  ≈ 2.6 × 10^10 B/s = 26 GB/s ≈ 208 Gbps
Peak (~2×)        ≈ 400+ Gbps
```
Cross-check via concurrency: `1M watch-hours/day ÷ 24 h ≈ 41,700 concurrent streams × 5 Mbps ≈ 208 Gbps`. ✅ Same answer.

### Takeaway
**~200 Gbps average, ~400+ Gbps peak** egress. No single origin server can serve this. You need a **CDN** to cache/serve video near users, **adaptive bitrate** (drop to 1–2 Mbps on poor networks to cut bandwidth), and egress cost becomes a top budget line.

---

## 3. Compute — Number of Servers (social media, 10 million DAU)

### Assumptions
| Assumption | Value |
|---|---|
| DAU | 10,000,000 |
| Requests / user / day (feed loads, likes, posts) | 50 |
| QPS one app server handles | 1,000 |
| Redundancy | ×2 headroom (peak + failover) |

### Math
```
Requests/day = 10,000,000 × 50            = 500,000,000 req/day
Average QPS  = 500M / 86,400              ≈ 5,800 QPS
Peak QPS     = 2 × 5,800                  ≈ 11,600 QPS

Servers (peak) = 11,600 / 1,000           ≈ 12 servers
With ×2 headroom for failover + spikes     ≈ 24 servers
```

### Takeaway
You need on the order of **~12 servers to handle peak, ~24 with redundancy** — a modest fleet behind a **load balancer**, not one giant box. The estimate also shows the sensitivity: if per-server QPS is really 500 (heavier requests), you double the fleet. Always state the per-server QPS assumption — it's the biggest lever.

---

## 4. Storage — All Tweets for 1 Year

### Assumptions (Twitter-scale, from the concept doc)
| Assumption | Value |
|---|---|
| DAU | 150,000,000 |
| Tweets / user / day | 2 |
| Text row size (id 64 B + text 140 B + metadata) | ~200 bytes |
| Tweets with media | 10% |
| Avg media size | 1 MB |
| Replication factor | ×3 |

### Math
```
Tweets/day       = 150M × 2 = 300M tweets/day

Text storage/day = 300M × 200 B = 60 GB/day
Text/year        = 60 GB × 365 ≈ 22 TB/year

Media/day        = 300M × 10% × 1 MB = 30 TB/day
Media/year       = 30 TB × 365 ≈ 11 PB/year

Total/year (raw) ≈ 22 TB + 11 PB ≈ 11 PB/year   (media dominates)
Total/year (×3)  ≈ 33 PB/year
```

### Takeaway
**Media dwarfs text by ~500×** (11 PB vs 22 TB). Store text/metadata in a sharded DB (cheap, ~22 TB is very manageable); push media to **blob storage + CDN**. When one component dominates an estimate, that's the one that drives the architecture — here, media storage.

---

## 5. Bandwidth — YouTube Video Streaming (global)

### Assumptions
| Assumption | Value |
|---|---|
| Watch time (YouTube's own public stat) | ~1 billion hours/day |
| Avg bitrate | 5 Mbps |

### Math
```
Data per watch-hour = 5 Mbps × 3,600 s = 18,000 Mb = 2,250 MB ≈ 2.25 GB
Total egress/day    = 1 × 10^9 hours × 2.25 GB ≈ 2.25 × 10^9 GB = 2.25 EB/day

Average bandwidth   = 2.25 EB / 86,400 s
                    = 2.25 × 10^18 B / 86,400
                    ≈ 2.6 × 10^13 B/s = 26 TB/s ≈ 208 Tbps
Peak (~2×)          ≈ 400+ Tbps
```

### Takeaway
**~200 Tbps average** — a *thousand times* Example 2's single-app scale. Impossible from centralized datacenters. This is why YouTube runs **Google Global Cache** nodes inside ISPs, aggressive **multi-resolution transcoding + adaptive bitrate**, and pre-positions popular content at the edge. At this scale, bandwidth *is* the architecture.

---

## 6. Storage — All Photos Uploaded to Facebook in 1 Year

### Assumptions
| Assumption | Value |
|---|---|
| DAU | 2,000,000,000 (2B) |
| Photos uploaded / DAU / day | 0.2 (1 in 5 users posts a photo) |
| Avg stored size (multiple resolutions per photo) | 2 MB |
| Replication factor | ×3 |

### Math
```
Photos/day      = 2B × 0.2 = 400,000,000 photos/day  (≈ matches FB's ~350M+/day)

Storage/day     = 400M × 2 MB = 800,000,000 MB = 800 TB/day ≈ 0.8 PB/day
Storage/year    = 0.8 PB × 365 ≈ 290 PB/year (raw)
Storage/year ×3 ≈ 870 PB/year ≈ ~0.9 EB/year
```

### Takeaway
**~290 PB/year raw, ~0.9 EB/year replicated** — exabyte scale. Requires a purpose-built **distributed blob store** (Facebook built *Haystack* exactly for this), tiered storage (hot vs. cold/"warm" storage like their *f4* system for rarely accessed photos), and heavy dedup/compression. The lever here is *photos-per-user-per-day* × *avg size* — halving either roughly halves the bill.

---

## Cross-Example Patterns (what interviewers want you to notice)

1. **One term usually dominates.** Media > text (Ex. 4); egress > everything for streaming (Ex. 2, 5). Find the dominant term and design around it.
2. **Scale changes the answer qualitatively.** 200 Gbps (Ex. 2) → load balancer + CDN. 200 Tbps (Ex. 5) → edge caches inside ISPs. Same formula, different architecture.
3. **Every estimate hinges on 1–2 assumptions.** Per-server QPS (Ex. 3), bitrate (Ex. 2/5), photos-per-user (Ex. 6). Call these out — they're where the interviewer probes.
4. **Always end with the decision.** The number is only useful because it forces a choice: shard vs. single DB, CDN vs. origin, blob store vs. filesystem.
