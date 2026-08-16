# Object / Blob Storage

---

Where you put **large, unstructured files** — images, video, backups, logs, ML datasets — instead of cramming them into a database. Objects are served over HTTP and pair naturally with a [CDN](../03-networking-and-delivery/cdn.md); the database keeps only a **URL/key** pointing at them, not the bytes.

## 1. Block vs file vs object storage

| Type | Unit | Accessed as | Good for | Real-world examples                                                                                                                                        |
|---|---|---|---|------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Block** | fixed-size blocks | a raw disk (attach + format) | databases, low-latency I/O | AWS EBS, SAN                                                                                                                                               |
| **File** | files in a tree | a mounted filesystem (paths, POSIX) | shared drives, home dirs | NFS, SMB, AWS EFS                                                                                                                                          |
| **Object** | whole object + metadata | an **HTTP API** (GET/PUT by key) | blobs, static assets, backups | **AWS S3** (de-facto standard), GCS (Google Cloud storage) , Azure Blob; **Cloudflare R2 / Backblaze B2** (no egress fees); **MinIO / Ceph** (self-hosted) |

**Object storage trades filesystem features (rename, partial edit, directories) for near-infinite scale, durability, and a simple HTTP interface.**

**Block vs object — the contrast interviewers ask for:**

| | **Block** (e.g. AWS EBS) | **Object** (e.g. AWS S3) |
|---|---|---|
| Update model | **modify individual blocks** in place | **replace the whole object** (no partial edit) |
| Latency | **microseconds** | **milliseconds** |
| Scale | limited (per-volume cap, e.g. 64 TB) | **effectively unlimited** |
| Boot an OS? | ✅ yes | ❌ no |
| Cost per GB | higher | **lower** |

## 2. How object storage works

- An **object** = the **data (blob)** + **metadata** (content-type, tags) + a unique **key** (its name). One object ranges from **0 bytes to ~5 TB** (S3).
- Objects live in a **bucket** — a **flat namespace**, not a real directory tree. `photos/2024/cat.jpg` is just a key; the `/`s are cosmetic.
- Access is by **HTTP**: `PUT` to upload, `GET` to download, `DELETE` to remove — addressed by URL, no mount needed.
- Objects are **immutable**: you replace the whole object, you don't edit it in place (no appending a byte to a 4 GB file).
- **Massively durable & available** — providers replicate across data centers and advertise **~11 nines (99.999999999%)** durability.

## 3. Why not just store files in the database?

Storing large blobs as `BLOB` columns bloats the DB, slows backups, and wastes expensive DB storage/cache on bytes that never get queried. Instead:

- **Put the blob in object storage; store its URL/key in the DB row.** The DB stays small and fast; the file scales independently.
- Object storage is **cheap** (pennies/GB), **elastically unlimited** (no capacity planning), and **serves directly** to clients (often via CDN), offloading your servers.

**Rough cost feel:** ~1 TB for a month runs about **$80 on block (EBS gp3)** vs **~$24 on object (S3 Standard)** — object is roughly **70% cheaper** for static data, the trade being higher latency and no in-place edits.

## 4. Key features you should name

| Feature | What it does |
|---|---|
| **Storage classes / tiering** | hot → cold → archive at falling price (S3 Standard → Infrequent Access → **Glacier**); **Intelligent-Tiering** auto-moves objects when the access pattern is unknown |
| **Lifecycle policies** | auto-move or delete objects by age (e.g. archive after 30 days) |
| **Versioning** | keep old versions; recover from overwrite/delete |
| **Presigned URLs** | time-limited URL letting a client upload/download **directly**, without your server proxying bytes |
| **CDN integration** | front the bucket with a CDN to cache objects at the edge |
| **Encryption** | server-side encryption at rest (SSE), plus TLS in transit |

## 5. When to use — and when not

- **Use for:** user uploads (images/video), static website assets, backups & archives, data-lake / big-data files, logs, ML training sets.
- **Don't use for:** anything needing **low-latency random reads/writes**, in-place edits, transactions, or a real filesystem — that's **block** (databases) or **file** storage.
- **Latency note:** first-byte latency is higher than a local disk; great for throughput and scale, not for a database's working set.

## 6. One-Paragraph Summary (for quick revision)

**Object (blob) storage** holds large **unstructured files** as immutable **objects** (data + metadata + a **key**) in a flat **bucket** namespace, accessed over a simple **HTTP** API (`GET`/`PUT`) rather than a mounted filesystem — the trade for giving up rename/partial-edit/directories is **near-infinite scale, ~11-nines durability, and low cost**. Contrast it with **block** storage (raw disks for databases, low latency) and **file** storage (POSIX trees). The canonical system-design pattern: **store the blob in object storage and keep only its URL/key in the database**, so the DB stays lean and files scale (and serve via **CDN**) independently. Know the features interviewers expect — **storage classes/tiering** (S3 Standard → Glacier), **lifecycle** rules, **versioning**, and **presigned URLs** for direct client upload/download — and the players: **AWS S3** (the standard), GCS, Azure Blob, plus S3-compatible **R2/MinIO**. Use it for uploads, static assets, backups, and data lakes; avoid it for low-latency, transactional, or in-place-edit workloads.
