# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A **content repository**, not a software project. It holds Markdown study resources for **System Design interview preparation** aimed at Senior Software Engineer roles at product-based companies. There is **no build, lint, test, or run step** — deliverables are `.md` files read in a Markdown viewer. "Running" a change means previewing the Markdown.

All concepts are distilled from *System Design Interview – An Insider's Guide* by **Alex Xu**. The book PDF exists at `docs/SystemDesignInterview.pdf` but is a **binary whose text cannot be read**, and it is **gitignored** (copyright). Write from established knowledge of the referenced chapter; offer to have the user cross-check specific figures against their own copy when precision matters.

## Repository map

```
README.md            landing page → points into concepts/ and practice/ (no concept table)
concepts/            the study resources
  README.md          the single concept index + a "Useful material" external-links table
  GUIDELINES.md      authoring rules (line cap, structure, conventions, diagrams §8)
  NN-section/        ordered topic-section folder; holds one OR MORE sibling concept files:
                       00-framework/ · 01-envelope-estimation/ · 02-foundations/ ·
                       03-networking-and-delivery/ · 04-apis/ (11 files) ·
                       05-databases-and-storage/ · 06-caching/ ·
                       07-messaging-and-events/ · 08-distributed-systems/
    diagrams/        optional Excalidraw diagrams for that section (.excalidraw source + .png)
practice/            mock-interview log & prep playbook
  README.md          progress tracker (scored session table + recurring themes)
  answer-framework.md the 8-step answer playbook to run in the room
  NN-session/        one folder per mock (README.md = analyzed write-up + diagram; script.md = raw transcript)
docs/                book PDF (gitignored) + TODO.md (backlog)
.claude/skills/excalidraw-diagram/   diagram-rendering skill (render via uv; GUIDELINES §8)
tmp.md               user's scratchpad / prompt buffer (gitignored — not a deliverable)
```

The user **reorganizes freely** (renames/moves folders, flattens directories, relocates the index). **Always re-inspect the tree from the repo root before adding or linking files** — never assume the last-known layout.

### The concept index (also a progress tracker)
`concepts/README.md` is the **single** concept index **and** the study-progress tracker. Its table has `Section · Concept · Read · Revised · Last Revision` columns, and it lists **unwritten backlog concepts as unlinked rows marked `*(todo)*`** (mirroring `docs/TODO.md`). When you **write** a concept: convert its row from plain text to a link (or add a new row with `↳` for a companion), and **bump the `## 📊 Progress Tracking` counts** at the top (`Written X / 47` + %). `Read`/`Revised` checkboxes and `Last Revision` are the user's to fill — leave them as `☐`/`—`. The root `README.md` is a thin landing page into `concepts/` and `practice/`; it does **not** duplicate the table, so leave it alone. Verify links resolve after any move.

### Naming
Numbered folders (`00-`…`08-`) are **ordered topic sections** — each holds **sibling concept files** for that topic (e.g. `04-apis/` holds 11; `05-databases-and-storage/` holds 3). Files use descriptive kebab-case names **without** the number prefix (e.g. `apache-kafka.md`). **Reading order is the row order in `concepts/README.md`, not the filesystem.** Companion files (e.g. `back-of-the-envelope-examples.md`) sit beside their primary concept.

## Document conventions (match these when adding content)

**Authoring rules live in [`concepts/GUIDELINES.md`](concepts/GUIDELINES.md)** — read it before creating a concept file. Key rule: **concept docs must be < 120 lines** (`wc -l` to check); split into companion files when a topic runs long. **Worked-examples and dense reference docs are exempt** — keep examples fully descriptive. **Diagrams** (optional, when a picture argues better than prose) use the `excalidraw-diagram` skill: author a `.excalidraw` in a `diagrams/` subfolder, render to PNG (sandbox disabled — needs network), embed with plain alt text, commit both source + PNG (GUIDELINES §8). The conventions below summarize the rest.

**Concept doc:** start with the `# Title` (a `---` divider under it is fine) and go straight into content — **no `Reference`/`Goal`/`Prerequisite` header block** (concepts are numbered, so reading in order covers prerequisites). Use numbered sections built from **tables + short prose**, and **always close with a `## One-Paragraph Summary`**. Two depths exist:
- **Full concept** (templates: `back-of-the-envelope-estimation.md`, `system-design-interview-framework.md`): *what it is / why asked* → reference tables/framework → worked example → cheat sheet or in-the-room checklist → tips (Do/Don't) → practice problems (`<details>` for solutions) → summary.
- **Leaner reference concept** (most topic docs, e.g. `07-messaging-and-events/apache-kafka.md`, `05-databases-and-storage/databases-*`): what it is → a few tables → real-world examples/tech → when-to-use trade-offs → summary. Drop practice problems/tips when they don't fit.

**Worked-examples doc** (template: `concepts/01-envelope-estimation/back-of-the-envelope-examples.md`): each example is `assumptions table → step-by-step math (in a code block) → **Takeaway** tying the number to an architectural decision`. End with a cross-example "patterns" section.

**Estimation conventions** — reuse across files so numbers stay consistent:
- `1 day ≈ 86,400 s ≈ 10^5 s`; `Peak ≈ 2 × Average`; replication factor `×3` default.
- Bandwidth: network in bits/s, storage in bytes; `1 byte = 8 bits`, `1 Gbps = 125 MB/s`. Mind lowercase `b` (bit) vs uppercase `B` (byte).
- Round aggressively and label units at every step.
- Assumptions are **illustrative** — the skill taught is stating assumptions and reasoning, not memorizing "true" figures.

## The two framework docs (don't conflate them)
- `concepts/00-framework/...` — the **behavioral** process: *how* to run the interview (4 phases: scope → high-level → deep dive → wrap, plus collaboration Dos/Don'ts). Chapter 3 of the book.
- `practice/answer-framework.md` — the **content** playbook: *what* to cover in an answer (8 steps: functional/non-functional reqs → estimation → architecture → walkthrough → data model → trade-offs → testing/monitoring). Maps its 8 steps onto the other doc's 4 phases.

## Practice tracker conventions (`practice/`)
- Each mock is `NN-session/` containing a **`README.md`** — the polished, standalone **analyzed write-up** (problem → requirements → estimation → design **+ diagram** → scorecard → gap-by-gap "what lost points & the fix" table → takeaways) — backed by **`script.md`**, the raw transcript. The README is the reader-facing page (public-repo asset); `script.md` is the authentic log it links to. Diagrams go in `NN-session/diagrams/` (Mermaid `.mmd` + same-named `.png`, per GUIDELINES §8).
- `practice/README.md` is the progress tracker: a **session table scored /10 across five axes** (Requirements, Design, Problem-Solving, Scale & Trade-offs, Communication + Overall) with verdict thresholds (✅ ≥7 · ⚠️ 5.5–6.9 · ❌ <5.5), followed by **Consolidated Tips grouped by axis (weakest first)** with `[S01]`-style session tags, **Recurring Action Items**, and a **How to Improve** diagnosis. When logging a new session, add the row and promote any repeated feedback into the recurring sections — that aggregation is the point.

## Editorial stance

Audience is a senior engineer prepping for interviews. Every estimate/number must connect to an architectural consequence (shard vs. single DB, CDN vs. origin, blob store vs. filesystem) — a figure with no decision attached is incomplete. Prefer tables, code blocks for math, and short revision-friendly summaries over prose walls. Cross-link related concepts with relative paths.

## Git

Repo is git-initialized; author is configured locally (not `--global`). `docs/*.pdf` and `tmp.md` are gitignored — do not commit them. Commit/push only when the user asks.
