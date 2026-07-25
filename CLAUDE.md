# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A **content repository**, not a software project. It holds Markdown study resources for **System Design interview preparation** aimed at Senior Software Engineer roles at product-based companies. There is no build, lint, test, or run step — deliverables are `.md` files meant to be read in a Markdown viewer.

All concepts are distilled from *System Design Interview – An Insider's Guide* by **Alex Xu**. Write from established knowledge of the referenced chapter; there is no machine-readable copy of the book in the repo, so offer to have the user cross-check specific figures against their own copy when precision matters.

## Layout & workflow

- **Concept folders live at the repo root** — one folder per concept, e.g. `01-envelope-estimation/`, `02-framework/`.
- `README.md` (repo root) is the **index**. Every new concept MUST be added as a table row, with a `↳` sub-row for companion files (see existing entries). Its links point into each concept folder — keep them current whenever folders or files are renamed.
- The user **reorganizes freely** (renames folders/files, flattens directories, moves the index). Always re-inspect the tree from the repo root before adding or linking files — never assume the last-known layout.

### Naming
Each concept is a **folder**, not a loose file, prefixed with a zero-padded number that sets its order (`01-...`, `02-...`). Files *inside* a folder use descriptive kebab-case names **without** the number prefix — e.g. `01-envelope-estimation/back-of-the-envelope-estimation.md` and its companion `back-of-the-envelope-examples.md`.

## Document conventions (match these when adding content)

**Concept doc structure** (see `01-envelope-estimation/back-of-the-envelope-estimation.md` and `02-framework/system-design-interview-framework.md` as templates): a `>` blockquote header citing the book chapter + goal; numbered sections progressing from *what it is / why interviewers ask* → core reference tables/framework → a worked example → cheat sheet or in-the-room checklist → interview tips (Do/Don't) → practice problems (with a `<details>` collapsible for solution sketches, where applicable) → a one-paragraph revision summary.

**Worked-examples doc structure** (see `01-envelope-estimation/back-of-the-envelope-examples.md`): each example is `assumptions table → step-by-step math (in a code block) → **Takeaway** tying the number to an architectural decision`. End the file with a cross-example "patterns" section.

**Estimation conventions** — reuse these across files so numbers stay consistent:
- `1 day ≈ 86,400 s ≈ 10^5 s`; `Peak ≈ 2 × Average`; replication factor `×3` default.
- Bandwidth: network in bits/s, storage in bytes; `1 byte = 8 bits`, `1 Gbps = 125 MB/s`. Mind lowercase `b` (bit) vs uppercase `B` (byte).
- Round aggressively and label units at every step.
- State that assumptions are **illustrative** — the skill being taught is stating assumptions and reasoning, not memorizing "true" figures.

## Editorial stance

The audience is a senior engineer prepping for interviews. Every estimate/number should connect to an architectural consequence (shard vs. single DB, CDN vs. origin, blob store vs. filesystem) — a figure with no decision attached is incomplete. Prefer tables, code blocks for math, and short revision-friendly summaries over prose walls. Cross-link related concepts with relative paths.
