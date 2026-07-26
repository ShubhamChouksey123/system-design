# Monolithic vs Microservices

---

The **architectural style** question that opens many designs: build the system as one deployable unit, or as many small independent services?

## 1. The two styles

**Monolith** — the whole application (UI, business logic, data access) is built, deployed, and scaled as a **single unit**. One codebase, one process, usually one shared database.

**Microservices** — the application is split into **small, independent services**, each owning one business capability, its **own database**, and its own deploy cycle. They talk over the network (REST/gRPC/async [message queue](./message-queue.md)).

```
Monolith                         Microservices
┌───────────────┐                ┌─────┐  ┌─────┐  ┌─────┐
│ UI · Orders   │                │Order│  │User │  │Pay  │
│ Users · Pay   │  ── split ──▶  │ +DB │  │ +DB │  │ +DB │
│ (one DB)      │                └─────┘  └─────┘  └─────┘
└───────────────┘                    ↕ network (REST/gRPC/queue)
```

## 2. Trade-offs

| Dimension | Monolith | Microservices |
|---|---|---|
| **Complexity** | Simple to build/deploy early | Distributed-systems complexity |
| **Deployment** | One unit — all-or-nothing | Deploy services independently |
| **Scaling** | Scale the whole app together | Scale only the hot service |
| **Tech stack** | Usually one language/stack | Polyglot — pick per service |
| **Fault isolation** | One bug can take down all | A failure is contained to one service |
| **Data** | One shared DB (easy joins/txns) | DB per service (no cross-service joins) |
| **Team autonomy** | Teams contend on one codebase | Teams own & ship services independently |
| **Latency/ops** | In-process calls, simple ops | Network hops, needs heavy tooling |

## 3. Pros & cons

**Monolith** ✅ simple to develop/test/deploy, fast in-process calls, easy transactions · ❌ scales as one blob, one stack, risky big deploys, hard for large teams, grows into a "big ball of mud."

**Microservices** ✅ independent scaling & deploys, fault isolation, team autonomy, polyglot · ❌ distributed complexity, network latency, **data consistency across services is hard** (no cross-service transactions), needs strong DevOps (CI/CD, observability, service discovery).

## 4. Which to choose?

- **Start with a monolith** for a new product / small team / unclear domain — it's faster to build and you avoid distributed problems you don't yet have.
- **Move to microservices** when scaling pain is real: large teams stepping on each other, parts needing very different scale, or independent deploy cadence.
- A **well-modularized monolith** ("modular monolith") captures much of the benefit without the network cost — a common pragmatic middle ground.
- Famous path: many companies (Amazon, Netflix) **started monolith → extracted microservices** as they grew, rather than starting micro.

## 5. Cross-cutting concerns microservices add

Splitting introduces problems the monolith didn't have — know these: **API gateway** (single entry point), **service discovery**, **inter-service communication** (sync REST/gRPC vs async queues), **distributed transactions / saga pattern**, **distributed tracing & centralized logging**, and **independent data stores**.

## 6. One-Paragraph Summary (for quick revision)

A **monolith** ships the whole app as one unit with one shared database — simple to build, test, and deploy, with fast in-process calls and easy transactions, but it scales as a single blob, forces one tech stack, and gets painful for large teams. **Microservices** split the app into small, independently deployable services each owning its own database — enabling independent scaling, fault isolation, team autonomy, and polyglot stacks, at the cost of distributed-systems complexity, network latency, hard cross-service data consistency, and heavy DevOps needs (gateway, discovery, tracing, saga). **Start monolith** and extract services only when scaling or team pain justifies it; a **modular monolith** is often the pragmatic middle.
