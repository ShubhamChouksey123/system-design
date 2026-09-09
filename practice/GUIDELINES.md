# Authoring Guidelines — `practice/`

Rules for every file created inside `practice/`. A practice folder logs a **mock interview** and turns it into a reusable study asset. Companion rules for the study notes live in [`concepts/GUIDELINES.md`](../concepts/GUIDELINES.md).

---

## 1. What a session folder is

Each mock is a folder `NN-session/` (zero-padded, ordered by when it happened) containing exactly two files:

| File | Role | Audience |
|---|---|---|
| `README.md` | The **analyzed write-up** — polished, standalone, reader-facing (public-repo asset). | A senior engineer prepping for interviews. |
| `script.md` | The **raw transcript** of the mock — the authentic log the README links to and is derived from. | Backing evidence; not edited for polish. |

Diagrams live in `NN-session/diagrams/` (§7). The `README.md` is the page people read; `script.md` is the receipt that proves it happened.

## 2. The `README.md` is two things at once

1. An **honest post-mortem** — what actually happened in the room, scored, with the gaps named plainly (no varnish; a low score is the *reason the page is worth reading*).
2. A **reference answer** — the "ideal design" section that shows how the problem *should* be solved, so the page teaches the topic even to a reader who never saw the transcript.

Write both. The post-mortem builds trust; the ideal design makes it useful.

## 3. Required structure (in this order)

Every session `README.md` MUST have these headings, in order:

```
# Session NN — <Problem> (<real-system> style) · <verdict emoji> <overall>/10
> intro blockquote — one honest paragraph: what this session shows + weakest areas
<snapshot table>                 Problem · Focus · Overall · Weakest areas · Full transcript
## The problem                   verbatim prompt (blockquote) + what it really tests
## Terminology                    optional — table of domain terms worth saying out loud in the room (see below)
## Requirements & estimation     what you produced — functional / non-functional / estimation + gaps; embed requirements diagram
## The design I produced         embed architecture diagram; bullet the components & flows
## Scorecard                     5-axis table vs the previous session, with Δ + a one-line note
## What lost points — and the fix   3-col table: what I missed | the senior answer | Study link
## What went well                the instincts that landed (keep morale + reinforce habits)
---
## The ideal design              the reference answer (§4) — this is the heart of the page
## Takeaways to drill            numbered, specific, drill-able lessons
> pointer line to ../README.md (tracker) + ../opening-ritual.md + ../answer-framework.md
```

The five scored axes are fixed: **Requirements Gathering · Design Skills · Problem-Solving · Scalability & Trade-offs · Communication**, plus **Overall**. Verdict thresholds: **✅ Pass ≥ 7 · ⚠️ Borderline 5.5–6.9 · ❌ Needs work < 5.5**.

**`## Terminology`** — add it whenever the problem has domain-specific vocabulary worth naming out loud in the room (a trading system's *order / order book / price-time priority*, a streaming platform's *GOP / rendition / manifest*). A two-column `Term | Meaning` table, placed right after `## The problem` and before `## Requirements & estimation`. Skip the section entirely on a problem with no real jargon (a CRUD-shaped app) rather than padding it out — it's optional, not a checklist item.

## 4. The **Ideal Design** section — mandatory contents

This is the reference answer and the reason the page has lasting value. It MUST be self-contained (a reader learns the solution here without the transcript) and MUST contain all of:

| Sub-part | What it holds |
|---|---|
| **Framing sentence** | One line that names the *crux* of the problem (the hot key, the write-path invariant, the dominant cost) — everything else follows from it. |
| **Ideal estimation** | The numbers done right — DAU / concurrent users, read:write, QPS, **storage + bandwidth** — each tied to an architectural consequence (§6). Include even if the candidate skipped it in the room. |
| **Functional & non-functional requirements** | The ideal cut: the functional scope actually worth building, and the non-functional priorities (and which to trade away). |
| **Ideal architecture — Mermaid diagram** | A **Mermaid `.mmd`** diagram of the target design (§7), embedded as a PNG. Separate read vs write flows; label every edge with data + protocol. This is required, not optional. |
| **Component walk-through** | Short prose/bullets tracing the main flows (a plain-language "packed room" analogy is welcome — see S04). |
| **Database schema** | A table of the tables — `Table \| Fields \| Note` — with keys, the state machine (if any), and the **crux table** called out (e.g. `progress`, `orders`, `bids`). |
| **Storage choices — which engine for which store** | A schema names the tables; it doesn't say what they run on. For **every** store in the design (not just the crux one), name the **category** (relational / wide-column NoSQL / in-memory KV / graph / search index / object storage) **and why that category, not another**, tied to its access pattern — e.g. `user` → relational (small structured rows, key lookups); a presence registry or feed cache → in-memory KV with TTL (ephemeral, ranked); a message store → wide-column NoSQL (high-volume ordered writes under one partition key). "We'll use a database" / "we'll cache it" with no named engine is incomplete — see [S13](./13-session/README.md#storage-choices--which-engine-for-which-store) for the worked example. |
| **Design trade-offs** | The senior signal: for each major decision, **the choice → the alternatives → why this one** (and when you'd switch). Split consistency per path (CP write / AP read) where it applies. |
| **Logging, Monitoring & Alerts** | **Name the concrete signals, not the word "monitoring."** A short list of specific, alertable metrics for *this* design — e.g. **DLQ depth**, **cache hit ratio**, **consumer lag**, **error rate per dependency**, **circuit-breaker-open duration**, **replication lag** — each paired with what triggers an alert. "Logging, monitoring, and alerts" as a bare requirement with no named signal is half-credit (see [S14](./14-session/README.md#what-lost-points--and-the-fix)); this sub-part is where it gets made concrete. |

An "architecture at a glance" `Layer \| Component \| Store` table is a good companion to the diagram but does not replace it.

## 5. Honesty & scoring conventions

- **Score exactly what the mock platform gave** — never round up to look better. The delta vs the previous session (▲/▼/—) is the progress signal; show it.
- **Name each gap once, concretely**, and attach the fix + a `Study` cross-link into `concepts/`. A gap with no linked concept is an incomplete entry.
- **Tag recurring misses** so the tracker can aggregate them (see §8). If a miss repeats, say "now N sessions running."
- **Diagrams are the artifact the interviewer reads** — critique the actual diagram (stale / cluttered / unconnected box), because delivery is a scored axis.

## 6. Estimation conventions (shared with `concepts/`)

Reuse the same figures so numbers stay consistent across the repo:

- `1 day ≈ 86,400 s ≈ 10^5 s`; `Peak ≈ 2 × Average`; replication factor `×3` default.
- Network in **bits**/s, storage in **bytes**; `1 byte = 8 bits`, `1 Gbps = 125 MB/s`. Mind lowercase `b` vs uppercase `B`.
- Round aggressively; label units at every step.
- **Every number ties to a decision** — shard vs single DB, CDN vs origin, blob store vs filesystem. A figure with no consequence attached is incomplete.
- Assumptions are **illustrative** — the skill is the reasoning, not "true" numbers.

## 7. Diagrams — Mermaid, in `diagrams/`

Session diagrams live in `NN-session/diagrams/`, and the **source is committed beside a same-named `.png`**.

- **Ideal-design diagram → Mermaid** (`.mmd`). Author the `.mmd`, then render at high scale so text stays sharp when zoomed: `npx -y @mermaid-js/mermaid-cli@11 -i name.mmd -o name.png -b white -s 5` (run with the sandbox disabled — the renderer needs network). Embed the PNG: `![plain alt text](./diagrams/name.png)`.
  - **Scale by density:** `-s 5` is the baseline. For a **wide or dense** diagram (many nodes, overlaid flows — e.g. a combined all-flows overview), use **`-s 6`** or higher; a small focused diagram (a handful of boxes) is fine at `-s 3`. Aim for a longest edge of **~4000+ px** so the text survives zooming — check the output with `file name.png` and bump the scale if it's smaller.
- **Requirements / as-drawn snapshots** may be the images captured from the mock canvas (e.g. `requirements.png`, `architecture.png`) — embed them as-is to show what actually happened.
- **Alt text must be plain** — no parentheses or brackets (they break Markdown image rendering); write a full descriptive sentence instead.
- Separate **read vs write flows**, color per journey, and **wire every box** — an unconnected component reads as "named but not understood."
- Full diagram rules mirror [`concepts/GUIDELINES.md` §8](../concepts/GUIDELINES.md); Excalidraw is allowed for free-form architecture, but the **ideal design's diagram should be Mermaid** so it stays diff-friendly and text-editable.

## 8. Update the tracker + nav (every new session)

A session isn't logged until the roll-ups are updated:

- **[`practice/README.md`](./README.md)** — add the session **row** to the Sessions table (all five axes + Overall + verdict), add its **write-up blurb**, extend the **Related concepts** line with the session tag, and **promote any repeated feedback** into *Consolidated Tips* (score histories + `[SNN]` tags, weakest axis first), *Recurring Action Items*, and *How to Improve*. **That aggregation is the whole point** of the tracker — a one-off note that isn't rolled up is lost.
- **`mkdocs.yml`** (repo root) — add the README under `nav:` (`"Session NN — <short name>": practice/NN-session/README.md`) and the transcript under `not_in_nav:` (`practice/NN-session/script.md`). CI runs `mkdocs build --strict`, so a broken relative link fails the build.

## 9. Markdown formatting (so it renders)

Block elements need a **blank line before and after**, or GitHub/MkDocs treat them as plain text:

- **Tables** — blank line before the header row (most common mistake); keep rows contiguous (no blank line *between* rows).
- **Code fences, lists, headings** — same blank-line rule.
- **Prefix AWS products with `AWS`** — `AWS S3`, `AWS DynamoDB`, `AWS ElastiCache` — never the bare name.
- **Cross-link** concepts with relative paths, and verify they resolve.

## 10. Before you save — checklist

```
□ Two files only: README.md (polished) + script.md (raw transcript)
□ All required headings present, in order (§3)
□ Terminology table added if the problem has real domain jargon worth naming (§3) — omitted, not left blank, otherwise
□ Snapshot table + scorecard use the five fixed axes + Overall; verdict emoji matches the threshold
□ Scores match the mock exactly (no rounding up); Δ vs previous session shown
□ Every lost-point row has a concrete fix + a Study cross-link into concepts/
□ Ideal Design section is self-contained and has ALL of §4:
    framing · ideal estimation · functional + non-functional reqs · Mermaid diagram · schema · storage choices (engine + why, per store) · trade-offs · logging/monitoring/alerts (named signals, not the bare word "monitoring")
□ Ideal-design diagram is Mermaid (.mmd) rendered to a same-named .png at ≥5× — ≥6× if wide/dense, ~4000+ px longest edge (§7)
□ Every number ties to a decision (§6)
□ Diagram alt text is plain (no parentheses/brackets); every box is wired
□ AWS products prefixed with "AWS"
□ Blank line before & after every table, list, and code block (§9)
□ practice/README.md updated: row + blurb + related-concepts tag + aggregated tips/action-items (§8)
□ mkdocs.yml updated: README in nav, script.md in not_in_nav (§8)
□ All relative cross-links resolve
```
