# Session 12 — Video Streaming Platform (YouTube style) · ✅ 7.2/10

> A scored, analyzed system-design mock — and the first **brand-new hard-crux problem that didn't fall apart on first contact.** Every prior "new problem right after a strong session" (S04 after S03, S07 after S06, S08 after S07, S10 after S09) dropped **2.0+ points** as the drilled scaffolding met a fresh core it hadn't seen. This time, a first-ever encounter with the video-streaming domain landed at **✅ 7.2 (Pass)** — only **▼0.3** off [S11](../11-session/README.md)'s 7.5, on a completely different problem. The transcoding pipeline was genuinely designed — **GOP chunking → a DAG-based per-type workflow → parallel transcode workers with heartbeat-based failure detection and reassignment** — not just named, and estimation numbers actually **decided** the design (0.6 PB/day forces a CDN; the storage curve justifies S3 Glacier tiering). A live self-correction (misspoke "1 billion," caught and fixed the math unprompted) was a good sign, too. What's still missing is the senior-plus layer the interviewer named directly: **failure handling in the pipeline** (no dead-letter queue / retry policy / alerting), **CDN eviction and cache-invalidation policy** left at a bare view-count threshold, **metadata consistency** during multi-rendition updates, and a **missing monitoring/observability layer** — plus scalability discussion that was **reactive**, arriving only when the interviewer asked.

| | |
|---|---|
| **Problem** | Design a video streaming platform like YouTube — millions of uploads, fast processing, global low-latency streaming |
| **Focus** | The transcoding pipeline (chunking + DAG-based parallel workflows) and the CDN-vs-direct-serve split for popular vs non-popular videos |
| **Overall** | **7.2 / 10** — ✅ **Pass** — down only 0.3 from S11's 7.5, on a brand-new problem *(the first fresh hard-crux session that didn't regress sharply — a break from the S04 / S07 / S08 / S10 pattern)* |
| **Strongest areas** | Design Skills, Communication (7.5 each) — Requirements, Problem-Solving, Scale & Trade-offs all tied at 7.0 |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |

## The problem

> Design a **video streaming platform** like YouTube that can handle **millions of video uploads**, provide **fast video processing**, and serve content **globally with minimal latency**.

Two crux problems hide under one prompt. First, the **transcoding pipeline**: a huge uploaded file has to become several resolutions and formats, fast and in parallel, without one slow step blocking the "video is live" promise — and without losing work if a worker dies mid-task. Second, **global low-latency delivery**: almost all bytes must leave a CDN edge, not the origin, which means deciding — dynamically, not by a fixed rule — which videos are worth caching there. This is the same shape as [S05's video pipeline](../05-session/README.md) (never fully explained back then) paired with the CDN discipline S05/S06/S08/S09 built up on the read side.

## Requirements & estimation

- **Functional** — upload a video; process it in **minimum time** before it's viewable; stream to **any user globally**; serve **multiple resolutions and formats** for different devices/bandwidth. A clean, product-shaped cut — but narrow: **no video deletion, search/discovery, or recommendations** were named, and the interviewer flagged the gap explicitly.
- **Non-functional** — smooth streaming with **minimum latency**, **high availability**, **fault-tolerant and resilient** processing, **secure upload**. Good coverage of the pipeline's reliability qualities.
- **Estimation, with a caught mistake** — 10M total users, 5M DAU (50%), uploaders = 10% of total. Said aloud as "1 billion," immediately caught and corrected to the actual **1M** — a good self-monitoring instinct under pressure, not a scoring loss. 1 video/person/day at 200 MB average → **0.2 PB/day raw uploads**, ×3 replication → **0.6 PB/day**, ×365 → **≈219 PB/year**. Watch time 1 hr/person/day → concurrent viewers ≈ 5M × 1/24 ≈ 208K, avg bitrate 5 Mbps → **≈1 Tbps total bandwidth**.
- **The numbers decided things** — unlike several earlier sessions where estimation was decoration, here the 0.6 PB/day and 1 Tbps figures directly produced "we have to use CDNs for that," and later fed into the S3 Glacier tiering call. A schema (`video_metadata`, `video_chunk`) was also sketched **during requirements**, not at the buzzer — the tracker's #2 recurring miss landed clean on a first encounter with a new problem.

![Requirements canvas for a video streaming platform. The problem is to design a video streaming platform like YouTube that can handle millions of video uploads, provide fast video processing, and serve content globally with minimal latency. Functional requirements list a user being able to upload a video, the video being processed in minimum time for viewing, any global user being able to stream the video, and the video being available in different resolutions and formats to support different devices and bandwidth. Non-functional requirements list smooth video streaming with minimum latency, high availability, fault-tolerant and resilient video processing, and secure video upload. The estimations block assumes 10 million total users, 5 million daily active users, 1 million people uploading video per day at 10 percent of total users, 1 video uploaded per person per day, an average video size of 200 megabytes, a total of 1 million videos uploaded per day, a total upload size per day of 0.2 petabytes, a total storage requirement per day of 0.6 petabytes after 3x replication, a total storage per year of 219 petabytes, a watch time of 1 hour per person per day, a total concurrent viewer count derived from 5 million times 1 over 24, an average bitrate of 5 megabits per second, and a total bandwidth of about 1 terabit per second. The schema block lists a video_metadata table with id, title, and description, and a video_chunk table with id, video_id, resolutions, format, from, to, status, and order.](./diagrams/requirements.png)

## The design produced

![Architecture canvas produced in the interview. A client connects through an API Gateway doing authentication, authorization, and rate limiting. For uploads, the client hits a Video Upload Service, which returns a signed upload URL with a video id, and the client posts the upload directly to AWS S3 using that signed URL. The Video Upload Service also informs a Video Metadata Service, which writes to a Video Metadata store writer database instance that replicates to a reader instance, with a cache in front of the metadata service that is invalidated on writes and falls back to the reader instance on a cache miss. When AWS S3 receives the completed upload, it emits an event into an Upload Event Queue backed by Kafka. A Video Pre-checks stage reads that queue, verifies the video is not tampered, and breaks it into small chunks called GOPs, groups of pictures. A DAG System then creates a per-video-type workflow for those chunks, and a Transcode Manager keeps track of tasks and available workers and assigns tasks to Transcode Workers, which perform encoding into resolutions like 480p, 720p, and 1080p and formats like MP4, plus thumbnail generation and chunk merging. An Upload Service then writes the final merged video back into AWS S3 and notifies the Video Metadata Service that the video is ready. For streaming, the client requests through the API Gateway to a Video Stream Service for non-popular videos, which reads from AWS S3 on a CDN cache miss, while popular videos are served directly from a CDN in front of AWS S3.](./diagrams/architecture.png)

- **API Gateway** — authN, authZ, rate limiting. Standard.
- **Video Upload Service** — issues a **signed, time-limited S3 URL**; the client uploads the raw file **directly to S3**, never through the app tier. The metadata service records a **pending** entry before the URL is handed back.
- **Video Metadata Service** — writer DB + read replica + cache, cache-invalidated on write. Kept slow-changing/read-heavy metadata off the hot pipeline path.
- **Processing pipeline (the crux, actually built)** — **S3 upload event → Kafka queue → pre-check worker** (tamper check, split into GOP chunks) **→ DAG system** (a per-video-type workflow — different treatment for shorts vs long-form) **→ Transcode Manager** (priority queue of tasks, tracks worker health, **detects a dead worker via missed heartbeat/progress polling and reassigns its task**) **→ Transcode Workers** (encode to 480p/720p/1080p, MP4, generate thumbnails, merge chunks) **→ Upload Service** writes the finished renditions back to S3 and flips the video to ready.
- **Streaming path** — client fetches a **manifest** from the Video Service, listing available resolutions/formats; the client itself picks a rendition based on measured bandwidth — correct **adaptive bitrate streaming**, even though the term was fumbled verbally before landing.
- **CDN vs direct-serve split** — videos past a **view-count threshold** are served from the CDN; everything else goes through a **Video Stream Service** reading from S3 (with the CDN populated on a miss) — avoiding an all-videos-in-CDN cost blowup.
- **Global distribution** — correctly chose **CDN edge caching** over cross-region S3 replication once pushed: a video popular in two regions gets cached at the edge in both, rather than every video's bytes being copied to every region up front.

## Scorecard

| Axis | S11 | **S12** | Δ |
|---|:--:|:--:|:--:|
| Requirements Gathering | 7.5 | **7.0** | ▼ 0.5 |
| Design Skills | 8.5 | **7.5** | ▼ 1.0 |
| Problem-Solving | 8.0 | **7.0** | ▼ 1.0 |
| Scalability & Trade-offs | 7.5 | **7.0** | ▼ 0.5 |
| Communication | 7.0 | **7.5** | ▲ 0.5 |
| **Overall** | 7.5 | **7.2** | ▼ 0.3 |

> **The milestone is the shape of the drop, not the drop itself.** Every previous "new hard problem right after a strong session" fell **2.0 or more** (S04 ▼1.1 off S03's pace, S07 dipping after S06, S08 ▼1.0 off S07, S10 ▼2.0 off S09). Here the same transition cost only **▼0.3**, and **Communication actually rose** — the diagram was well-wired and the walkthroughs, while occasionally rambling on wording (the "adaptive bitrate" fumble), were structurally clear and sequenced upload → process → stream. Design (7.5) and Problem-Solving (7.0) dipped modestly because the pipeline's *failure handling* and the CDN's *cache policy* stayed underspecified — not because the pipeline itself was unbuilt.

## What lost points — and the fix

| What I missed in the room | What a senior would say | Study |
|---|---|---|
| **Transcoding failure handling stopped at "reassign the task"** — no policy for a task that fails repeatedly | Retry **N times**, then route to a **dead-letter queue**; alert on DLQ age; support manual or automatic re-drive. The interviewer named this gap explicitly at the buzzer. | [Message Queue](../../concepts/07-messaging-and-events/message-queue.md) |
| **CDN promotion was a bare view-count threshold**, with no eviction/invalidation policy | State the **edge TTL / eviction rule** (LRU is the default) and — since popularity *decays* — a **continuously-updated popularity score**, not a one-way threshold that never demotes a cooled-off video. Also name **invalidation on re-upload/takedown**. | [CDN](../../concepts/03-networking-and-delivery/cdn.md) |
| **Metadata consistency during the pipeline never came up** — what does a viewer see while some renditions are ready and others aren't? | Put a **status state machine on each rendition** (`queued → processing → ready → failed`) and only publish a manifest entry for renditions that are `ready`; flip the video's own status to `live` only once the **minimum required rendition set** exists. | [Databases](../../concepts/05-databases-and-storage/databases-fundamentals.md) |
| **No monitoring/observability layer** — flagged directly by the interviewer | Name it proactively: transcode **queue depth**, **worker heartbeat misses**, **pipeline lag** (upload → live latency), **CDN hit ratio**. At this scale, these are first-class components, not an afterthought. | [Observability](../../concepts/09-reliability-and-operations/observability.md) |
| **Scalability discussion was reactive** — bottlenecks, the worker autoscaling signal, and the storage-growth trade-off all arrived only when the interviewer asked | Volunteer the two scaling axes before being prompted: the **transcoding fleet scales on queue depth**, the **metadata tier scales via read replicas + cache**. Proactivity is the recurring Pass → Strong-Pass lever the tracker keeps flagging. | [Answer Framework](../answer-framework.md) |

## What went well

- **A self-caught estimation error** — misspoke "1 billion," caught and corrected the math to 1M unprompted. Good number-sense under pressure, and it didn't cost a point.
- **Estimation actually decided the design** — the 0.6 PB/day and 1 Tbps figures directly produced "we need a CDN," and the storage curve later justified S3 Glacier tiering. The numbers were used, not decorative.
- **Schema drawn during requirements, not at the buzzer** — `video_metadata` / `video_chunk` appeared on the canvas before the architecture did. The tracker's #2 recurring miss landed clean on a *first encounter* with a brand-new problem.
- **Signed-URL direct-to-S3 upload** — the raw file never proxies through the app tier.
- **The transcoding pipeline was actually built**: GOP chunking, a DAG-based per-video-type workflow, a real worker pool with **heartbeat-based failure detection and reassignment** — this is the domain-defining component S05 could only name, and here it was designed end-to-end.
- **Adaptive bitrate streaming explained correctly** — manifest lists available renditions, client picks based on its own measured bandwidth.
- **Three real, distinct cost/latency trade-offs, mostly volunteered**: CDN-vs-direct-serve by popularity, S3 Standard-vs-Glacier tiering by access pattern, and **replication factor differentiated by creator popularity** (3x for popular creators' videos, 2x otherwise).
- **The cross-region call landed correctly** — chose CDN edge caching over S3 cross-region replication for global reads, a nuanced distinction several earlier sessions blurred.
- **A self-aware, specific close** — named the exact next thing to fix (recovery when the transcode pipeline exhausts retries) rather than a vague "I'd review everything."

---

## The ideal design

**The crux:** a huge binary upload has to become several playable renditions, reliably and in parallel, without letting one slow or failed step block the "video is live" promise on the write side — while the read side must push nearly all bytes through a CDN edge that decides, dynamically rather than by fixed rule, what's worth caching there.

### Ideal estimation (decision-tied)

| Number | Value | Decision it forces |
|---|---|---|
| Uploads/day | 1M videos × 200 MB avg | 0.2 PB/day raw → **must go straight to blob storage (S3)**, never a filesystem or a DB blob column |
| Storage w/ replication | 0.2 PB × 3 ≈ **0.6 PB/day**, ≈219 PB/year | Storage is the dominant cost → **tiered storage** (hot renditions on S3 Standard, cold on Glacier) is not optional |
| Concurrent viewers | 5M DAU × 1 hr/24 hr ≈ **208K concurrent** | Small relative to total users → origin can be thin; almost all serving capacity must be **CDN edge**, not origin |
| Egress bandwidth | 208K × 5 Mbps ≈ **1 Tbps** | 1 Tbps from origin is not viable at any reasonable cost → **CDN is mandatory**, not a nice-to-have |
| Read:write | streaming reads ≫ uploads | Classic read-heavy shape → cache metadata aggressively, replicate the metadata DB for reads |

### Functional & non-functional requirements (the ideal cut)

- **Functional** — upload (resumable, multi-part for large files); transcode to multiple ABR renditions; stream globally with adaptive bitrate; **basic discovery** (title/tag search); **view/like/comment counters**; **delete/takedown** a video (removes it from the manifest and eventually purges storage).
- **Non-functional** — durability of the **raw master file** (it's expensive to lose — can't regenerate for free); an **idempotent, resumable pipeline** (a crashed worker retries the same task safely); a **processing-latency SLA** (e.g. p95 < 10 min for a 10-minute video) — the "minimum time" requirement needs a number, not just the word "minimum"; eventual consistency is fine for view counters, never for the manifest.

### Ideal architecture

![Architecture diagram for the ideal video streaming platform. An uploader goes through an API Gateway to an Upload service, which writes a pending video row to a metadata writer store and returns a signed multi-part S3 URL; the uploader then PUTs the raw file directly into a raw S3 bucket. The bucket's upload-complete event feeds a Kafka ingest queue, which a pre-check worker reads to scan for tampering and split the file into GOP chunks, handing off to a DAG orchestrator that builds one workflow branch per rendition. A transcode manager keeps a priority queue of tasks, heartbeats a pool of autoscaled transcode workers, reassigns tasks on a missed heartbeat, and dead-letters a task after exhausting retries, feeding a dead-letter queue with alerting. Workers write finished rendition segments into a processed S3 bucket and mark each rendition ready in the metadata service, which flips the video to live only once the minimum rendition set is ready and writes to the metadata writer store, which replicates to a reader store and invalidates a metadata cache. A viewer requests a manifest through the API Gateway from the metadata service, reading from the cache with a fallback to the reader store on a miss. Viewers fetch segments from a CDN edge for hot videos, or from a streaming service reading the processed bucket for cold videos, which populates the CDN on a miss. A popularity job consumes a view-event Kafka stream through a counter aggregation service and a view-count cache, and uses the decaying popularity score to tune each video's CDN edge TTL rather than a fixed threshold. A monitoring and alerting component watches queue depth, CDN hit ratio, and pipeline health across the transcode manager, the ingest queue, and the CDN.](./diagrams/ideal-design.png)

- **Upload** — signed multi-part URL, direct-to-S3, a `pending` metadata row created first so a client can resume or query status mid-upload.
- **Ingest & transcode** — S3 event → Kafka → pre-check (integrity + malware scan, GOP chunking) → DAG orchestrator (one branch per rendition, run in parallel) → transcode manager (priority queue + heartbeats + **dead-letter after N retries**) → autoscaled worker pool. Each rendition is tracked independently so a failure in one resolution never blocks the others.
- **Publish** — the metadata service flips a video to `live` only once the **minimum required rendition set** is `ready` — the manifest only ever lists renditions that actually exist.
- **Read path** — CDN edge is the default; a streaming service reads S3 directly for cold videos and backfills the CDN on a miss. A **popularity job** computes a decaying score from the view-event stream and tunes each video's edge TTL continuously, instead of a one-way "popular" flag that never demotes a video that's gone cold.
- **View counting** — an AP path: events flow through Kafka into a counter-aggregation service and a cache, never blocking or gating a read.
- **Observability** — queue depth, worker heartbeat misses, pipeline lag (upload → live), and CDN hit ratio are first-class signals off every stage of the pipeline, not bolted on after.

### Database schema

| Table | Fields | Note |
|---|---|---|
| `video` | `video_id` (PK), `owner_id`, `title`, `description`, `tags`, `duration`, `status` (`uploading → processing → live → failed → deleted`), `created_at` | The publish gate — `status` only becomes `live` once the rendition set below satisfies the minimum |
| `video_rendition` | `video_id` (FK), `resolution`, `format`, `manifest_path`, `status` (`queued → processing → ready → failed`) | **The real crux table** — the manifest only ever surfaces rows where `status = ready` |
| `video_segment` | `video_id`, `rendition_id`, `seq_no`, `from_ts`, `to_ts`, `s3_path` | One row per HLS/DASH segment; `seq_no` orders the segments the manifest lists |
| `transcode_task` | `task_id`, `video_id`, `rendition`, `status`, `worker_id`, `attempts`, `dead_letter` (bool) | The retry/DLQ bookkeeping this session's pipeline lacked |
| `view_count` | `video_id`, `day_bucket`, `count` | Append + periodic rollup — an AP counter, never read on the hot streaming path |

### Design trade-offs

- **Chunk before transcoding, not after** — splitting the raw file into GOP-aligned chunks *before* handing work to the DAG lets many workers process **one video concurrently** and bounds the blast radius of a failed task to one chunk, not the whole file. The alternative (transcode the whole file per rendition, serially) means a 2-hour video blocks on one long-running job, and a crash restarts everything.
- **CDN promotion by decaying score, not a fixed threshold** — a view-count cutoff never *demotes* a video whose popularity has faded, silently wasting edge cache. A continuously recomputed score both promotes and demotes, keeping the CDN's footprint proportional to *current*, not historical, demand.
- **Tier storage by rendition, not by whole video** — even a cold video's most-requested rendition (commonly the mobile default) should stay on S3 Standard; only the rarely-hit high-resolution renditions move to Glacier. A binary hot/cold split on the whole video either over-pays for storage or adds latency to the rendition people actually watch.
- **Split consistency by path** — the manifest publish is **CP**: only flip to `live` once a quorum of required renditions exist, because showing a broken manifest is worse than a short delay. View counters are **AP**: approximate and eventually consistent, because blocking a play on an exact count is never worth it.
- **Differentiate replication by regenerability** — the **raw master** needs durable ×3 replication since re-uploading it costs the creator real effort. A **derived rendition** can always be re-run from the master + the DAG, so it can tolerate a lower replication factor and be re-derived on loss rather than paid for up front.

## Takeaways to drill

1. **This session broke the "first hard-crux problem regresses sharply" pattern** — S04, S07, S08, and S10 all fell 2.0+ points on their first encounter with a new hard problem right after a strong session; S12 held to **▼0.3**. That's evidence the drilled habits (estimation-that-decides, schema-upfront, proactive cost trade-offs) are becoming durable skills, not artifacts that only show up on a re-solve.
2. **Name the failure-handling policy the moment you introduce a pipeline** — retries, a dead-letter queue, and alerting are not an afterthought for *any* multi-stage async system; say the policy in the same breath as the happy path.
3. **Every "cache the popular ones" answer needs an eviction/promotion rule attached** — a fixed threshold is a starting point, not the answer; state TTL/LRU and how a cold-again item gets demoted.
4. **Volunteer the bottleneck and scaling-signal discussion before being asked** — this is the same proactivity lever flagged since S05/S06/S09/S10, and it's still the cheapest points on the table.
5. **Add "what's the monitoring story?" to the opening checklist** — this session is the first to lose points specifically for a missing observability layer; treat it as a standing requirement on any system operating at scale, not a bonus topic.

→ Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
