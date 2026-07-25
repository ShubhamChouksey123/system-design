# System Design Fundamentals — Basics

> **Reference:** Foundational primer; the scalability section draws on *System Design Interview* by Alex Xu, Chapter 1.
> **Goal:** Establish the shared vocabulary — cloud, APIs, scalability — that every later concept assumes.

---

## 1. Cloud Computing

The **cloud** is on-demand access to computing resources (servers, storage, DBs, networking) over the internet, rented from a provider (AWS, GCP, Azure) on a **pay-as-you-go** basis instead of owning hardware.

**How you connect:** target a **region** + **availability zone**, hit a service **endpoint** (URL), authenticate with **credentials** (API keys / IAM) — via one of:

| Method | What it is | Used for |
|---|---|---|
| **Web console** | Browser dashboard | Manual setup / inspection |
| **CLI** | `aws`, `gcloud` | Scripting, automation |
| **SDK** | Language libraries | Programmatic access from app code |
| **IaC** | Terraform / CloudFormation | Declarative, repeatable infra |

**Deployment models:** **Public** (shared, cheapest, elastic) · **Private** (dedicated, most control, costly) · **Hybrid** (sensitive data private, burst to public) · **Multi-cloud** (avoids lock-in, more complex).

**Service models:**
| Model | You manage | Example |
|---|---|---|
| **IaaS** | OS, runtime, app | EC2, Compute Engine |
| **PaaS** | App + data only | App Engine, Heroku |
| **SaaS** | Nothing — just use it | Gmail, Salesforce |

| Advantages | Disadvantages |
|---|---|
| No upfront cost; pay-as-you-go | Ongoing cost can exceed owning at steady scale |
| **Elastic** — scale on demand | **Vendor lock-in**; egress costs |
| Global reach → low latency | Less control over the stack |
| Managed services, HA & durability built in | Provider-dependent; compliance/residency limits |

> **Takeaway:** the cloud is *why* modern design assumes near-infinite, elastic capacity — you add servers/storage/regions on demand. That underpins horizontal scaling and estimation.

---

## 2. APIs, Requests & Responses

An **API** is a contract letting software talk to software — *what* operations exist and *how* to call them, hiding the internals. Services expose APIs so clients/other services use them without knowing the internals.

**Request–response model:** client–server over HTTP, **synchronous** by default — client sends a **request** (method + path + query + headers like `Authorization`/`Content-Type` + body), server returns a **response** (status code + headers + body).

| Method | Purpose | Idempotent? |
|---|---|---|
| `GET` | Read | Yes |
| `POST` | Create | No |
| `PUT` | Replace | Yes |
| `PATCH` | Partial update | No |
| `DELETE` | Remove | Yes |

| Status class | Meaning | Common codes |
|---|---|---|
| **2xx** | Success | `200 OK`, `201 Created`, `204 No Content` |
| **3xx** | Redirect | `301 Moved Permanently`, `302 Found` |
| **4xx** | Client error | `400`, `401`, `404`, `429 Too Many Requests` |
| **5xx** | Server error | `500`, `503 Service Unavailable` |

> **Interview note:** the right status code signals seniority — a URL-shortener redirect returns **301/302**, not 200; a rate-limited client gets **429**. (This gap showed up in [practice session 01](../../practice/README.md).)

**API styles:** **REST** (resources over HTTP verbs — public CRUD) · **gRPC** (binary RPC over HTTP/2 — fast internal calls) · **GraphQL** (client-shaped queries — avoid over/under-fetching).

> **Takeaway:** APIs are the seams of a system. Defining the API (`POST /urls {longUrl} → 201 {shortUrl}`) *first* forces clarity on each component before you wire them together.

---

## 3. Scalability

**Scalability** is handling **increased load** (more users/requests/data) by adding resources without degrading performance — keeping latency and availability steady as traffic grows 10× or 100×.

| | **Vertical (scale up)** | **Horizontal (scale out)** |
|---|---|---|
| **What** | Add CPU/RAM to one machine | Add machines behind a load balancer |
| **Analogy** | A bigger truck | More trucks |
| **Limit** | Hard hardware ceiling | Effectively unlimited |

**Vertical — pros/cons:** simple, no data-distribution complexity, no LB *vs.* hard ceiling, **single point of failure**, downtime to scale, cost grows non-linearly.

**Horizontal — pros/cons:** near-unlimited, **fault tolerant**, commodity hardware, rolling deploys *vs.* needs a **load balancer**, services must be **stateless**, data **partitioning/sharding** adds complexity.

**Which, when?** Start **vertical** while small; go **horizontal** at the single-machine ceiling or for HA. Horizontal is the default at interview scale — but forces two decisions: keep services **stateless**, and pick a **key-distribution strategy** (consistent hashing) for caches/DBs.

> **Takeaway:** "add more servers" is step one. Scaling out then demands load balancing, statelessness, and data partitioning — see [load balancing & consistent hashing](./load-balancing-and-consistent-hashing.md). Size the fleet with the [compute example](../01-envelope-estimation/back-of-the-envelope-examples.md) (`servers ≈ peak QPS ÷ per-server QPS`).

---

## 4. One-Paragraph Summary

The **cloud** provides elastic, pay-as-you-go computing (IaaS/PaaS/SaaS across public/private/hybrid), letting designs assume on-demand capacity. Systems talk over **APIs** in a request–response model — request (method + path + headers + body) → response (status code + body); picking the right method and status code (2xx/3xx/4xx/5xx) matters. **Scalability** means adding resources: **vertical** (bigger box — simple, capped, SPOF) or **horizontal** (more boxes — near-unlimited, fault-tolerant, but needs a load balancer, stateless services, partitioning). Start vertical, go horizontal at scale — scaling out is what makes every later distributed-systems concept necessary.
