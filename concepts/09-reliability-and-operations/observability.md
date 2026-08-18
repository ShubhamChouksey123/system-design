# Observability — logs, metrics, tracing, SLOs

---

**Monitoring** tells you *when* something is wrong; **observability** lets you ask *why* without shipping new code. You get it by emitting telemetry — the **MELT** signals: **Metrics, Events, Logs, Traces** — and defining **SLOs** so "healthy" is a number, not a feeling. It's the operational half of the [resilience patterns](./resilience-patterns.md) (you must **monitor breaker state**) and how [failover](../08-distributed-systems/single-point-of-failure.md) gets detected.

## 1. MELT — the four telemetry signals

| Signal | What it is | Answers | Cost / cardinality |
|---|---|---|---|
| **Metrics** | numeric **aggregates** over time (counters, gauges, histograms) | "what's the *rate / p99 / error %* right now?" | cheap, but **high-cardinality labels explode** storage |
| **Events** | discrete **notable state changes** — deploys, config/flag flips, autoscaling, restarts | "*what changed* right before the graph moved?" | low volume; correlate with metric shifts |
| **Logs** | timestamped, discrete **records** (ideally **structured** JSON) | "what exactly happened for *this* request?" | high volume — sample/retain selectively |
| **Traces** | one request's path **across services**, span by span | "*where* in the call chain did the latency/error come from?" | medium; usually **sampled** |

Complementary in an incident: a **metric** alerts you (error rate up), an **event** often names the cause (a deploy at 14:02), a **trace** localizes it (service C's DB call), and **logs** explain it (the exact query + stack trace).

## 2. Metrics — the RED and USE methods

Two standard checklists for *which* metrics to emit:

| Method | For | The three signals |
|---|---|---|
| **RED** | request-driven **services** | **R**ate, **E**rrors, **D**uration (latency) |
| **USE** | **resources** (CPU, disk, pool) | **U**tilization, **S**aturation, **E**rrors |

Google's **Four Golden Signals** (SRE book) overlap: **latency, traffic, errors, saturation**. Always track latency as **percentiles (p50/p95/p99)**, never averages — an average hides the tail that actually hurts users.

## 3. What to monitor — the key signals

Instrument **top-down**, from user-facing symptoms to the resources beneath — and watch **latency + error rate at *every* hop** so you can tell "we're slow" from "our dependency is slow":

| Layer | Watch | Why it matters |
|---|---|---|
| **Service (RED)** | request **rate**, **error rate**, **latency** p50/p95/p99 | the user-facing health of *this* service |
| **Downstream dependencies** | each dependency's **error rate + latency**, timeout / retry counts, **circuit-breaker state** | localizes *whose* fault a slowdown is — ties to [resilience patterns](./resilience-patterns.md) |
| **Database** | query latency, **slow-query count**, connection-pool saturation, **replication lag**, lock waits, disk | the DB is the usual bottleneck and a common [SPOF](../08-distributed-systems/single-point-of-failure.md) |
| **Cache** | **hit / miss ratio**, eviction rate, latency, memory used | a falling **hit ratio** silently dumps load onto the DB |
| **Host / infra (USE)** | CPU, memory, disk I/O & free space, network, saturation | resource exhaustion behind the symptoms |
| **Queue / async** | **queue depth / consumer lag** (e.g. Kafka), processing time, dead-letter size | backlog means consumers can't keep up |
| **Business / KPI** | signups, checkouts, **payment success rate** | catches breakage that infra metrics miss |

## 4. Distributed tracing — how it works

A **trace** is a tree of **spans**; each service call is a span carrying a shared **trace ID** and its **parent span ID**. Context is propagated by injecting these IDs into outbound request headers (the **W3C Trace Context** `traceparent` header), so the trace stitches together across process boundaries.

- **Sampling** keeps cost sane — head-based (decide up front, e.g. 1%) or tail-based (keep all *slow/errored* traces).
- Essential in **microservices**: with a fan-out across dozens of services, a trace is the only way to see the full request path and find the slow hop.

## 5. SLI / SLO / SLA / error budget

The vocabulary that turns reliability into a **contract with a number**:

| Term | Meaning | Example |
|---|---|---|
| **SLI** (indicator) | a **measured** signal of health | % of requests < 300 ms; success rate |
| **SLO** (objective) | the **internal target** for an SLI | 99.9% of requests succeed over 30 days |
| **SLA** (agreement) | an **external, contractual** promise (+ penalty) | 99.5% uptime or customer gets credits |
| **Error budget** | `100% − SLO` — the **allowed** unreliability | 99.9% → **0.1%** ≈ 43 min/month of "down" |

The **error budget** is the key idea: it's a **shared currency** between dev and ops. Budget left → ship features fast; budget spent → freeze releases and fix reliability. Set SLOs **below** the SLA (headroom), and don't chase 100% — each extra "nine" costs exponentially more.

## 6. Real-world tooling

| Layer | Tools |
|---|---|
| **Metrics** | **Prometheus** (pull-based, de-facto standard) + **Grafana** (dashboards); **AWS CloudWatch**, Datadog |
| **Logs** | **ELK / Elastic Stack** (Elasticsearch + Logstash + Kibana), **Grafana Loki**, **AWS CloudWatch Logs**, Splunk |
| **Traces** | **Jaeger**, **Zipkin**, **AWS X-Ray**, Grafana Tempo |
| **Standard / SDK** | **OpenTelemetry (OTel)** — vendor-neutral APIs + collector for all three pillars; the industry-converging standard |
| **All-in-one SaaS** | **Datadog**, **New Relic**, **Grafana Cloud**, **Honeycomb** |

**Trend:** instrument once with **OpenTelemetry**, export anywhere — avoids lock-in to a single backend.

## 7. Alerting — the last mile

- **Alert on symptoms, not causes** — page on "checkout error rate > 1%" (user-facing SLO burn), not "CPU 80%" (may be harmless).
- **Burn-rate alerts:** fire when the error budget is being consumed too fast — catches real trouble without paging on every blip.
- **Fight alert fatigue:** every page must be **actionable**; noisy alerts get ignored and the real one is missed. Route to **on-call** (PagerDuty / Opsgenie) with a runbook.

## 8. When & how to apply — and pitfalls

- **Instrument from day one:** structured logs with a **request/trace ID**, RED metrics per service, tracing on cross-service calls.
- **Pitfalls:** averages hiding the p99 tail; **high-cardinality** metric labels (user ID as a label) blowing up storage; logging **PII / secrets**; alerting on causes → fatigue; SLOs no one enforces (no error-budget policy).

## 9. One-Paragraph Summary (for quick revision)

**Observability** is the ability to ask *why* a system misbehaves from its outputs, built on the **MELT** signals: **Metrics** (cheap numeric aggregates — *rate/error/latency now*, via **RED** for services and **USE** for resources, always as **percentiles** not averages), **Events** (discrete state changes like deploys/config flips that *explain* a graph moving), **Logs** (structured records — *what happened for this request*), and **Traces** (one request's path across services via a propagated **trace ID** — *where* the latency/error is). Monitor **latency and error rate at every hop** — your service *and* each downstream dependency — plus **database health** (slow queries, replication lag, pool saturation), **cache hit/miss ratio**, host **USE**, and queue lag. Reliability is made a number with **SLIs** (measured signals), **SLOs** (internal targets), **SLAs** (external contracts), and the **error budget** (`100% − SLO`) that governs whether teams ship features or freeze to fix reliability. Instrument with **OpenTelemetry** and export to **Prometheus + Grafana** (metrics), **ELK / Loki** (logs), and **Jaeger / AWS X-Ray** (traces); or **AWS CloudWatch** / Datadog. **Alert on user-facing symptoms and budget burn rate**, keep every page actionable, and never log secrets or explode metric cardinality.
