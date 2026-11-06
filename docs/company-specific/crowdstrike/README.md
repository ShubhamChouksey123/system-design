# CrowdStrike — System Design Prep Gaps

Company-specific gap analysis for CrowdStrike's **security-aware system design round** (Engineer III - Cloud, Falcon Fusion/SOAR team). Scope is **system design only** — DSA/coding-round prep is tracked in the sibling `data-structures-java-solution` repo, not here.

Source: CrowdStrike's system design round is reported as diverging from generic scaling prompts — it rewards **security-domain framing** (durability, audit trails, adversarial failure modes) over abstract architecture. Prompts are drawn from the Falcon platform's real ingestion/detection/response lifecycle.

## 📊 Progress Tracking

Track your overall progress: `2/11 items completed`

| Section | Progress |
|---|---|
| Concept gaps | `1/6` |
| Practice-prompt gaps | `1/5` |

## Checklist

### Concept gaps — not in `concepts/README.md`

- [x] **Write-ahead log (WAL) & durability-first ingestion** — "never lose a security event" framing; WAL, at-least-once delivery, idempotent consumers as the point of the design, not a one-line mention. → [`write-ahead-log-and-durable-ingestion.md`](../../../concepts/08-distributed-systems/write-ahead-log-and-durable-ingestion.md)
- [ ] **High-cardinality time-series ingestion & downsampling/rollup** — can't keep raw resolution forever at 100K events/sec; overlaps `docs/TODO.md`'s "Monitoring / observability platform" case study but is unwritten on the concept side.
- [ ] **Stream processing / real-time anomaly detection (CEP-style)** — sliding-window pattern matching over a live event stream; overlaps the existing `*(todo)*` **Batch vs Stream Processing** row but CrowdStrike's flavor is a rules/anomaly-detection engine specifically.
- [ ] **Multi-SLA / tiered rate limiting** — one limiter serving two traffic classes (bulk telemetry ingestion vs. low-latency threat-intel lookups) with different latency/throughput guarantees; existing **Rate Limiting** `*(todo)*` row + S07 only cover single-SLA limiting.
- [ ] **Audit trail / tamper-evident logging** — compliance-grade durability, distinct from `observability.md`'s operational logging.
- [ ] **Tenant/data isolation at scale** — multi-customer-environment isolation as its own concern, beyond `api-security.md`'s generic authN/authZ.

### Practice-prompt gaps — not in `practice/README.md` / `docs/TODO.md` backlog

- [ ] **Rate limiter serving two SLA classes** (telemetry ingestion vs. threat-intel lookups) — new variant; S07 only designed a single-SLA limiter. Crux: priority-queue-per-class + separate token-bucket configs per traffic type.
- [ ] **Real-time alerting engine for anomalous activity** (anomalous process execution / brute-force patterns in a live stream) — partially folded into the existing "Monitoring/observability platform" backlog row, but that row is infra-metrics-framed, not security-event-correlation-framed.
- [ ] **"VirusTotal-like" file-analysis pipeline** (upload → hash → dedup → blob storage → async malware-scan workflow → sharded results DB) — not covered; closest analog is S12 (transcoding pipeline) but the crux here is content-hash dedup + async scan/verdict fan-out, not transcoding.
- [ ] **SOAR connector / third-party integration design** ("integrate a new data source into Falcon Fusion," "optimize an existing connector's performance") — role-specific, not a classic case-study pattern; crux is per-connector rate/SLA isolation against a third-party API, auth-flow handling (OAuth2/OIDC/SAML per connector), and backpressure when the downstream platform throttles you.
- [x] *(Already backlog-covered)* **Log aggregation / telemetry-ingestion pipeline at extreme write volume** ("10,000 endpoints reporting 100,000 events/sec") — matched `docs/TODO.md`'s "Monitoring / observability platform (Datadog/New Relic style)" row; now scored as [`practice/17-session/README.md`](../../../practice/17-session/README.md) (⚠️ 6.5/10 — windowed streaming evaluation vs. periodic re-query against storage was the crux, named by the interviewer, not solved live). A privately-worked, real-internal-names version of the same ingestion shape also exists at `docs/new-relic/` (gitignored, not part of the public tracker).

## Notes

- Minor/lower-priority: dedup-at-scale for ingestion ties into the already-`*(todo)*` **Bloom Filters** concept row — not a new gap, just confirming relevance here too.
- CrowdStrike's reported durability checklist for *any* system design answer, regardless of prompt: mention **write-ahead logs**, **at-least-once delivery**, and **idempotent consumers** explicitly — this is reported as the single most commonly missed dimension by candidates from non-security backgrounds.
- Estimation-first discipline is reported as the biggest differentiator: spend the first ~5 minutes on throughput/storage/latency numbers before drawing any architecture.
