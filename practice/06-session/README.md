# Session 06 — MVP Social Networking App (startup, cost-constrained) · ⚠️ 6.5/10

> A scored, analyzed system-design mock. The prompt's whole point was **constraint**: build a social MVP for a startup that must *ship fast and cheap*. This played to my strength — I aligned every decision to that constraint (**monolith over microservices, one DB, minimal components**) and articulated a clean **scaling path** (vertical → read replica → service split) and the **monolith→microservices trade-offs** well. What held it to Lean Hire is the *same universal pair I keep missing* — **no data model** (interviewer-flagged, now 5 of 6 sessions) and **estimation that stopped at user counts** (no read QPS / storage / bandwidth) — plus a **shallow feed** (no pagination, no follow graph, no cache-invalidation story) and a **diagram that read ambiguously** (the interviewer twice thought I had a second "read database").

| | |
|---|---|
| **Problem** | Design an MVP social networking app for a resource-limited startup — profiles, posts, basic interactions — keeping infrastructure cost low |
| **Focus** | Cost-constrained MVP: pragmatic scoping, monolith-first, a defensible scaling path |
| **Overall** | **6.5 / 10** — ⚠️ Borderline (Lean Hire) — flat vs S05's 6.5 |
| **Weakest areas** | Design (6.0), Problem-Solving (6.0), Communication (6.0) |
| **Full transcript** | [`script.md`](./script.md) (raw interview log) |

## The problem

> Design a **minimum viable product for a social networking app** for a **startup with limited resources**. Focus on **core features** — user profiles, posts, and basic interactions — while **keeping infrastructure costs low**.

The constraint *is* the question. Unlike a "design Twitter at scale" prompt, here the graded skill is **judgment under a cost/time budget**: scope ruthlessly, pick the simplest architecture that works at MVP scale, and — critically — *know exactly when and how you'd evolve it*. The trap is over-engineering (sharding, microservices, fan-out-on-write for 1k users); the second trap is under-thinking the one hard part a social app always has — **the feed** — and hand-waving "show all posts, latest first" without naming pagination or a follow graph.

## Requirements & estimation

- **Functional** — profile creation; post creation (text + image); view another user's profile; view another user's posts.
  - **Out of scope (stated):** likes & comments — reasonable MVP cut.
- **Non-functional** — **fast to ship · low resource use · reuse existing SDKs/libraries.** Correctly translated "less resources" into an *architectural* choice: **monolith, not microservices** — fewer deployments, less infra, quicker to ship.
- **Estimation** — 10k total users · **1k DAU** (1%) · **~2 posts/user/day ≈ 2k posts/day**.
  - **Gap:** the numbers stopped at users/posts. No **read QPS** (feed opens/day), no **storage** sizing (2k images/day → S3), no **bandwidth** — so the cache/CDN/S3 choices were justified by instinct, not by a number. (Estimation-depth miss, recurring: S01/S04/S05.)

![Requirements canvas — problem statement for an MVP social app; functional requirements listing profile creation, post creation, view others profile, view others posts; a good-to-have out-of-scope block for likes and comments; non-functional requirements of less time to ship, use less resources, use existing SDKs and libraries; and an estimations block giving 10k total users, 1k daily active users, and 2 posts per user per day](./diagrams/requirements.png)

## The design I produced

![Architecture canvas — a User client sends POST /profile, POST /post, GET /profile by id, GET /post by id, GET /posts, GET /profiles through an API Gateway that does authentication, plus a separate GET /image request into a CDN. The gateway forwards to a single Backend Service handling user, profile, and feed. The backend writes to one Database and reads through a Cache, with a dashed cache-miss arrow from the Cache to the Database. The backend also writes post images to AWS S3, and the CDN falls back to S3 on a cache miss](./diagrams/architecture.png)

- **Clients & edge:** single **User** client → **API Gateway** (authentication; **no rate limiting** — consciously deferred as non-MVP) → backend. Image reads go through a **CDN**.
- **Single Backend Service** — one deployable handling **user + profile + feed**, justified explicitly by the cost/ship-speed constraint (monolith over microservices).
- **Write flow** (`POST /post`): gateway authenticates → backend writes **title + description to the Database** and the **image to AWS S3**, storing the **image URL** in the DB.
- **Read flow** (`GET /posts`): backend returns **all posts sorted latest-first**; image URLs resolve through the **CDN**. Reads are served from a **cache**; on a **cache miss**, query the DB and **warm the cache** on the way back.
- **One database for reads and writes** — no read replica in the MVP (deliberate cost call); a **cache** fronts it for fast reads.
- **Scaling path (when asked):** vertical scale first → **read replica** once a single hot table's read throughput saturates → **decompose the monolith** (separate feed vs profile services) when the backend becomes the bottleneck / SPOF.
- **Security (when asked):** on a compromised session, **null the token** and force re-login; store tokens in the **DB for persistence + cache for fast per-request lookups**.

## Scorecard

| Axis | S05 | **S06** | Δ |
|---|:--:|:--:|:--:|
| Requirements Gathering | 7.0 | **7.0** | — |
| Design Skills | 7.0 | **6.0** | ▼ 1.0 |
| Problem-Solving | 6.0 | **6.0** | — |
| Scalability & Trade-offs | 7.0 | **7.0** | — |
| Communication | 6.0 | **6.0** | — |
| **Overall** | 6.5 | **6.5** | — |

> Same score as S05, different shape. **Scale held at 7.0** — the scaling-path narrative (vertical → replica → service split) and the monolith trade-off discussion are now a genuine strength. **Design slipped to 6.0**: no data model *again*, a feed with no pagination or follow graph, no cache-invalidation story, and a diagram whose "Database + Cache" cluster read as a phantom second database. The constraint framing was excellent; the depth underneath it was thin.

## What lost points — and the fix

| What I missed in the room | The answer a senior would give | Study |
|---|---|---|
| **No data model / schema** (recurring: S01, S02, S04, S05, **S06** — interviewer-flagged) | Draw the tables: `users`, `profiles`, `posts` (author_id, text, image_url, created_at), and **`follows` (follower_id, followee_id)** — the crux table that makes it a *social* app, not a blog wall. | [Databases](../../concepts/05-databases-and-storage/databases-fundamentals.md) |
| **Feed = "all posts, latest first"** — no pagination, so it breaks the moment post volume grows | Paginate with a **cursor / keyset** (`WHERE created_at < :cursor ORDER BY created_at DESC LIMIT n`), never `OFFSET` at scale. State the feed model explicitly (see next row). | [Databases](../../concepts/05-databases-and-storage/databases-fundamentals.md) |
| **No follow graph** — "view others' posts" was global, so it isn't really a feed | A social feed needs a **follow relationship** + a **fan-out choice**: **pull (fan-out-on-read)** — query posts from people you follow — is right for an MVP; name **push (fan-out-on-write)** as the growth path when reads dominate. | [Caching](../../concepts/06-caching/caching.md) |
| **No cache-invalidation story** — interviewer asked twice | On a new/edited post, **invalidate (or append to) the author's + followers' cached feeds**; use a **short TTL** as the self-healing backstop. A cache without an invalidation rule serves stale feeds. | [Caching](../../concepts/06-caching/caching.md) |
| **Estimation stopped at user counts** — no read QPS, storage, or bandwidth | Size the reads and bytes: ~1k DAU × ~10 feed-opens ≈ tiny QPS; 2k images/day × ~1–2 MB ≈ **~3 GB/day → S3, not the DB**; that's *why* S3 + CDN + one small DB is correct. The numbers should **justify the simple design**, not just exist. | [Estimation](../../concepts/01-envelope-estimation/back-of-the-envelope-estimation.md) |
| **Authorization left at authN only** | Add **authZ**: can user A edit user B's post? Enforce **ownership checks** (`post.author_id == caller`) in the backend, plus **input validation** on writes — not just a valid token. | [AuthN & AuthZ](../../concepts/04-apis/authentication-and-authorization.md) |
| **Diagram read ambiguously** — the Database + Cache cluster looked like a second "read database" (interviewer flagged it) | Separate **write vs read flows**, label the single DB as `primary`, and draw the cache *inline on the read path* (`backend → cache → miss → DB`) so there's no phantom store. | [Consistency Models](../../concepts/08-distributed-systems/consistency-models.md) |

## What went well

The cost-consciousness and the scaling narrative were real strengths — this is the progress signal for constraint-driven problems:

- **MVP judgment** — every choice (monolith, single DB, minimal components, deferred rate limiting) was tied back to the *ship-fast/low-cost* constraint. That discipline is exactly what the prompt tested.
- **Monolith-first, defended** — chose a monolith *and* articulated the microservices trade-offs cleanly (extra deployments, service-to-service network latency vs. local calls, operational + infra overhead).
- **A concrete scaling path** — vertical scaling → read replica (once one hot table's read throughput saturates) → service decomposition when the backend turns into a SPOF. Sequenced, with the trigger for each step.
- **Cache-aside understood** — lazy-load, warm on miss; and the session-token design (DB for persistence, cache for fast per-request reads) was a sound instinct.

---

## The ideal design

**The crux:** at 1k DAU an MVP social app is a **CRUD-plus-cache problem, and estimation's job is to *prove* the simple design is correct** — the only place real design judgment is required is the **feed**, where you must name the **fan-out trade-off you're deferring** (pull now, push later) and put a **follow graph** behind it. Get those two right and "keep it cheap" becomes a defensible position, not a hand-wave.

### 1. Ideal estimation (the numbers that justify staying simple)

Here estimation is used *in reverse* — not to justify sharding, but to prove you **don't need it yet**, and to name the headroom before each next step.

| Quantity | Assumption | Result | Decision it forces |
|---|---|---|---|
| Users / DAU | 10k total · 1% active | **1k DAU** | single small instance is plenty |
| Writes (posts) | 1k DAU × 2/day ÷ 10⁵ s | **~0.02 writes/s** | one primary DB, no write scaling |
| Reads (feed) | 1k DAU × ~10 opens/day, peak 2× | **~0.2–0.5 reads/s** | a cache is a *nicety*, not yet a necessity |
| Image storage | 2k images/day × ~1.5 MB | **~3 GB/day (~1 TB/yr)** | **AWS S3, never the DB**; CDN for cheap egress |
| Text storage | 2k posts/day × ~300 B | **~0.6 MB/day** | trivial — fits one DB for years |

> The takeaway said out loud: **the numbers prove the monolith + one DB is correct, not lazy.** State the headroom too — "a single DB handles this for years; I add a **read replica** when one hot table's read QPS saturates, and **shard / decompose** only past ~100× this load." That turns "keep it cheap" into an *engineered* decision.

### 2. Requirements — the ideal cut

- **Functional (in scope):** create/edit **profile**; create **post** (text + image); **follow / unfollow**; view a **profile**; view a **feed** (posts from people you follow, paginated).
- **Argued *into* scope:** a **follow graph**. "Social" without one is a global bulletin board — one `follows` table is the difference, and it's cheap. **Out:** likes, comments, DMs, notifications, search.
- **Non-functional (ranked):** **time-to-ship + low cost** (monolith, managed services, existing SDKs) → **availability** for reads → **security** (authN + ownership authZ). Scale is *explicitly deferred* — with the §1 numbers proving the headroom, not ignored.

### 3. Ideal architecture

The design is deliberately small. The one thing drawn carefully is the **read path** (cache-aside in front of one primary) vs the **write path** (DB + object store), plus a **dashed growth path** to a read replica — the evolution named, not built.

![Ideal MVP social-app architecture as a Mermaid flowchart. A single client sends writes (POST posts and POST profile) and reads (GET feed and GET profile) through an API gateway doing authentication and authorization, into one monolith backend containing profile, post, and feed modules. On the write path the backend writes text and metadata to a single SQL primary database, puts images to AWS S3 via a pre-signed URL, records follow and unfollow rows in the same database, and invalidates the feed and profile entries in a Redis cache. On the read path the backend reads through the Redis cache which falls through to the primary database on a miss and warms it, while image reads go through a CDN that falls back to S3 on a miss. A dashed growth path shows a read replica added off the primary database only when one hot table saturates](./diagrams/ideal-design.png)

| Layer | Component | Store |
|---|---|---|
| Edge | API Gateway (authN + authZ), **CDN** for image reads | — |
| Application | **Monolith backend** — Profile · Post · Feed modules (one deployable) | — |
| Write path | write post text/metadata + `follows`; put image to object store | **SQL primary** + **AWS S3** |
| Read path | feed / profile via **cache-aside**, image via CDN | **Redis cache** → SQL primary; CDN → S3 |
| Growth (deferred) | **read replica** added when one hot table's read QPS saturates | SQL replica |

### 4. The feed — the one component worth real depth

For a social app, the feed *is* the domain-defining component. Even in an MVP you must name the model and the trade-off:

- **Follow graph:** a `follows(follower_id, followee_id)` table. The feed query is "latest posts by the people I follow."
- **Fan-out on read (pull) — the MVP choice:** at feed-open time, `SELECT … FROM posts WHERE author_id IN (my followees) ORDER BY created_at DESC LIMIT n`. **Writes stay O(1)** (one row), reads do the work. Perfect when writes are cheap and the user base is small — exactly §1's numbers.
- **Fan-out on write (push) — the growth path:** on each post, pre-compute and push the post id into each follower's materialized feed (a cache/list). **Reads become O(1)**, writes get expensive — worth it only when reads vastly dominate, and it needs the **celebrity/hot-key** exception (don't fan out a 1M-follower account; merge their posts at read time).
- **Pagination:** always **cursor/keyset** (`created_at < :cursor`), never `OFFSET` — offset scans degrade linearly as the feed grows.

> Naming pull-vs-push *and* why pull fits the MVP is the senior signal the session missed — it's the difference between "show all posts latest-first" and a feed that has a design behind it.

### 5. Caching & delivery

- **Cache-aside** for feed + profile reads; **invalidate on write** (a new/edited post drops the author's and followers' cached feed entries) with a **short TTL** backstop so a missed invalidation self-heals.
- **Images → S3 + CDN**: blobs never live in the DB; the CDN serves them cheaply near the user and offloads origin. Store only the **image URL** in the posts row.

### 6. Database schema (the still-missing artifact)

| Table | Fields | Note |
|---|---|---|
| users | id, email, password_hash, created_at | auth identity |
| profiles | user_id (PK/FK), display_name, bio, avatar_url | 1:1 with users (or fold into users for MVP) |
| posts | id, author_id, text, image_url, created_at | `created_at` indexed for feed ordering |
| **follows** | **(follower_id, followee_id)**, created_at | **the crux table — makes it a social graph** |
| sessions | token, user_id, expires_at | DB persistence + cached for fast per-request lookups |

### 7. Design trade-offs

The senior signal is naming the alternative and *why* you didn't take it — and, on a constraint problem, **when you'd switch**.

| Decision | Alternatives | Why this choice (and when to switch) |
|---|---|---|
| **Monolith backend** | Microservices | Cost + ship-speed at 1k DAU; one deployable, local calls. **Switch** when teams/scaling need independence or a module's load diverges |
| **Feed = fan-out on read (pull)** | Fan-out on write (push) | Writes are ~0.02/s and users are few — keep writes O(1), let reads do the work. **Switch** to push when reads dominate and followings grow (with a celebrity-account exception) |
| **Single primary DB** | Read replica / sharding now | §1 shows years of headroom. **Switch** to a replica when one hot table's read QPS saturates; shard only past ~100× |
| **Images → S3 + CDN** | Blobs in the DB / serve from app | Blobs bloat the DB and are costly to serve; S3 durability + CDN egress is cheap and standard |
| **Cache-aside + TTL** | Write-through / no cache | Simple, resilient to cache loss; TTL bounds staleness. At this QPS the cache is optional — add it when read latency matters |
| **Session token in DB + cache** | JWT (stateless) | DB is the source of truth so revocation (null the token) is instant; cache makes per-request checks fast. JWT trades instant revocation for statelessness |
| **Defer rate limiting** | Rate-limit at the gateway from day one | Non-MVP for a trusted-scale launch. **Add** at the gateway before public/anonymous exposure |

## Takeaways to drill

1. **Estimation and the schema are *still* the two universal misses (5–6 of 6 sessions).** This time the framing was strong but I again drew no data model and sized no reads/storage. Make both automatic: open with a capacity block, close by drawing the tables — even (especially) when the numbers *justify staying simple*.
2. **A social feed always needs a fan-out decision + a follow graph.** "All posts, latest first" isn't a feed. Name **pull vs push**, pick pull for an MVP, and draw the `follows` table — this is the domain-defining depth for social problems.
3. **Every cache needs an invalidation rule.** Pair "add a cache" with "invalidate on write, TTL as backstop" in the same breath — the interviewer asked twice because I stated the cache but not its consistency story.
4. **Use estimation to justify the simple design.** On a constraint problem, numbers that prove you *don't* need replicas/shards — plus the headroom before each next step — are worth as much as numbers that prove you do.
5. **authN ≠ authZ.** A valid token isn't authorization — add ownership checks (can A edit B's post?) and input validation. It's the silent senior box on every CRUD design.
6. **Draw write and read as separate flows.** The phantom "read database" came from a muddled cache/DB cluster. One labeled `primary`, the cache inline on the read path — no ambiguity.

→ Consolidated feedback across all sessions lives in the [practice tracker](../README.md). Rehearse with the [Opening Ritual](../opening-ritual.md) + [Answer Framework](../answer-framework.md) before the next mock.
