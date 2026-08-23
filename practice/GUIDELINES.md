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
| **Design trade-offs** | The senior signal: for each major decision, **the choice → the alternatives → why this one** (and when you'd switch). Split consistency per path (CP write / AP read) where it applies. |

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

- **Ideal-design diagram → Mermaid** (`.mmd`). Author the `.mmd`, then render at **3× scale** so it stays crisp: `npx -y @mermaid-js/mermaid-cli@11 -i name.mmd -o name.png -b white -s 3` (run with the sandbox disabled — the renderer needs network). Embed the PNG: `![plain alt text](./diagrams/name.png)`.
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
□ Snapshot table + scorecard use the five fixed axes + Overall; verdict emoji matches the threshold
□ Scores match the mock exactly (no rounding up); Δ vs previous session shown
□ Every lost-point row has a concrete fix + a Study cross-link into concepts/
□ Ideal Design section is self-contained and has ALL of §4:
    framing · ideal estimation · functional + non-functional reqs · Mermaid diagram · schema · trade-offs
□ Ideal-design diagram is Mermaid (.mmd) rendered to a same-named .png at 3× (§7)
□ Every number ties to a decision (§6)
□ Diagram alt text is plain (no parentheses/brackets); every box is wired
□ AWS products prefixed with "AWS"
□ Blank line before & after every table, list, and code block (§9)
□ practice/README.md updated: row + blurb + related-concepts tag + aggregated tips/action-items (§8)
□ mkdocs.yml updated: README in nav, script.md in not_in_nav (§8)
□ All relative cross-links resolve
```
