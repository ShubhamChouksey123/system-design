# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A **content repository**, not a software project. It holds Markdown study resources for **System Design interview preparation** aimed at Senior Software Engineer roles at product-based companies. There is **no build, lint, test, or run step** — deliverables are `.md` files read in a Markdown viewer. "Running" a change means previewing the Markdown.

All concepts are distilled from *System Design Interview – An Insider's Guide* by **Alex Xu**. The book PDF exists at `docs/SystemDesignInterview.pdf` but is a **binary whose text cannot be read**, and it is **gitignored** (copyright). Write from established knowledge of the referenced chapter; offer to have the user cross-check specific figures against their own copy when precision matters.

## Repository map

```
README.md            landing page → points into concepts/ and practice/ (no concept table)
concepts/            the study resources
  README.md          the single concept index (add every new concept here)
  NN-topic/          one folder per concept (00-fundamentals/, 01-envelope-estimation/, 02-framework/)
practice/            mock-interview log & prep playbook
  README.md          progress tracker (scored session table + recurring themes)
  answer-framework.md the 8-step answer playbook to run in the room
  NN-session/        one folder per mock (script.md = transcript + scorecard + tips)
docs/                book PDF (gitignored)
tmp.md               user's scratchpad / prompt buffer (gitignored — not a deliverable)
```

The user **reorganizes freely** (renames/moves folders, flattens directories, relocates the index). **Always re-inspect the tree from the repo root before adding or linking files** — never assume the last-known layout.

### The concept index
`concepts/README.md` is the **single** concept index — add a row (with `↳` sub-rows for companions) for every new concept, using links relative to `concepts/` (e.g. `./01-envelope-estimation/...`). The root `README.md` is a thin landing page that links *into* `concepts/` and `practice/`; it does **not** duplicate the concept table, so leave it alone when adding concepts. Verify links resolve after any move.

### Naming
Each concept is a **folder**, not a loose file, prefixed with a zero-padded number that sets order (`01-...`, `02-...`). Files *inside* a folder use descriptive kebab-case names **without** the number prefix — e.g. `concepts/01-envelope-estimation/back-of-the-envelope-estimation.md` and its companion `back-of-the-envelope-examples.md`.

## Document conventions (match these when adding content)

**Authoring rules live in [`concepts/GUIDELINES.md`](concepts/GUIDELINES.md)** — read it before creating a concept file. Key rule: **concept docs must be < 120 lines** (`wc -l` to check); split into companion files when a topic runs long. **Worked-examples and dense reference docs are exempt** — keep examples fully descriptive. The conventions below summarize the rest.

**Concept doc** (templates: `concepts/01-envelope-estimation/back-of-the-envelope-estimation.md`, `concepts/02-framework/system-design-interview-framework.md`): start with the `# Title` and go straight into content — **no `Reference`/`Goal`/`Prerequisite` header block** (concepts are numbered, so reading in order covers prerequisites). Then numbered sections progressing from *what it is / why interviewers ask* → core reference tables/framework → a worked example → cheat sheet or in-the-room checklist → interview tips (Do/Don't) → practice problems (with a `<details>` collapsible for solution sketches, where applicable) → a one-paragraph revision summary.

**Worked-examples doc** (template: `concepts/01-envelope-estimation/back-of-the-envelope-examples.md`): each example is `assumptions table → step-by-step math (in a code block) → **Takeaway** tying the number to an architectural decision`. End with a cross-example "patterns" section.

**Estimation conventions** — reuse across files so numbers stay consistent:
- `1 day ≈ 86,400 s ≈ 10^5 s`; `Peak ≈ 2 × Average`; replication factor `×3` default.
- Bandwidth: network in bits/s, storage in bytes; `1 byte = 8 bits`, `1 Gbps = 125 MB/s`. Mind lowercase `b` (bit) vs uppercase `B` (byte).
- Round aggressively and label units at every step.
- Assumptions are **illustrative** — the skill taught is stating assumptions and reasoning, not memorizing "true" figures.

## The two framework docs (don't conflate them)
- `concepts/02-framework/...` — the **behavioral** process: *how* to run the interview (4 phases: scope → high-level → deep dive → wrap, plus collaboration Dos/Don'ts). Chapter 3 of the book.
- `practice/answer-framework.md` — the **content** playbook: *what* to cover in an answer (8 steps: functional/non-functional reqs → estimation → architecture → walkthrough → data model → trade-offs → testing/monitoring). Maps its 8 steps onto the other doc's 4 phases.

## Practice tracker conventions (`practice/`)
- Each mock is `NN-session/` containing `script.md` (bundles transcript + the platform scorecard + tips).
- `practice/README.md` is the progress tracker: a **session table scored /10 across five axes** (Requirements, Design, Problem-Solving, Scale & Trade-offs, Communication + Overall) with verdict thresholds (✅ ≥7 · ⚠️ 5.5–6.9 · ❌ <5.5), followed by **Consolidated Tips grouped by axis (weakest first)** with `[S01]`-style session tags, **Recurring Action Items**, and a **How to Improve** diagnosis. When logging a new session, add the row and promote any repeated feedback into the recurring sections — that aggregation is the point.

## Editorial stance

Audience is a senior engineer prepping for interviews. Every estimate/number must connect to an architectural consequence (shard vs. single DB, CDN vs. origin, blob store vs. filesystem) — a figure with no decision attached is incomplete. Prefer tables, code blocks for math, and short revision-friendly summaries over prose walls. Cross-link related concepts with relative paths.

## Git

Repo is git-initialized; author is configured locally (not `--global`). `docs/*.pdf` and `tmp.md` are gitignored — do not commit them. Commit/push only when the user asks.
