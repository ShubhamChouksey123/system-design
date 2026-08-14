# Authoring Guidelines — `concepts/`

Rules for every file created inside `concepts/`. Keep docs short, focused, and revision-friendly.

---

## 1. File size — **concept docs < 120 lines**

A **concept doc** (a topic you read top-to-bottom to learn it) MUST be **under 120 lines**. Short docs are easier to revise before an interview and force tight, high-signal writing.

- If a topic needs more, **split it into companion files** in the same folder (e.g. `basics.md` + `load-balancing-and-consistent-hashing.md`), each under the cap.
- Prefer **tables and code blocks** over prose paragraphs — they carry more information per line.
- Cut throat-clearing and repetition; every line should earn its place.

> Check before saving: `wc -l concepts/**/your-file.md` → concept docs must be `< 120`.

**Exempt from the cap — reference & example docs.** Files you *dip into* rather than read start-to-finish are exempt, because their length scales with an intentional list of independent items, not with padding:
- **Worked-examples docs** — each example is self-contained; keep them **fully descriptive** (assumptions table → math → takeaway). More examples = more lines, and that's fine.
- **Dense reference docs** — big lookup tables (e.g. the estimation reference tables).

The exemption is not a license to pad: each *item* stays tight, and unrelated topics still go in separate files (§2).

## 2. One concept per file

A file covers a single, coherent topic. If you're using "and" to join two unrelated ideas, that's two files. Companion files share a concept folder and are linked from the index as `↳` sub-rows.

## 3. Naming & placement

- Each concept is a **folder**: `NN-topic/` (zero-padded number sets order; `00-` for foundational).
- Files *inside* use descriptive kebab-case **without** the number prefix — e.g. `back-of-the-envelope-estimation.md`.
- Add every new file to the index at [`concepts/README.md`](./README.md) (with `↳` sub-rows for companions).

## 4. Required structure

Concepts are **numbered so readers go in order.** Do **not** add `Reference`, `Goal`, or `Prerequisite` header blocks — a reader going in order has already covered the prerequisites, and the title states the topic. Start with the `# Title` and go straight into the content.

**Concept doc:**
1. `# Title`, then the content (a `---` divider under the title is fine).
2. Numbered sections: *what it is / why it's asked* → core reference tables → a worked example → cheat sheet or in-the-room checklist → tips (Do/Don't) → practice problems (`<details>` for solutions, where useful).
3. A **one-paragraph revision summary** to close.

**Worked-examples doc:** each example is `assumptions table → step-by-step math (code block) → **Takeaway** tying the number to an architectural decision`. End with a cross-example "patterns" section.

## 5. Estimation conventions (reuse so numbers stay consistent)

- `1 day ≈ 86,400 s ≈ 10^5 s`; `Peak ≈ 2 × Average`; replication factor `×3` default.
- Network in **bits**/s, storage in **bytes**; `1 byte = 8 bits`, `1 Gbps = 125 MB/s`. Mind lowercase `b` vs uppercase `B`.
- Round aggressively; label units at every step.
- State that assumptions are **illustrative** — the skill is reasoning, not memorizing "true" numbers.

## 6. Editorial stance

- Audience: a senior engineer prepping for interviews.
- **Every number must tie to an architectural consequence** (shard vs single DB, CDN vs origin, blob store vs filesystem). A figure with no decision attached is incomplete.
- **Name real-world examples / technologies.** Every concept should point to concrete systems that implement it — e.g. message queue → *Apache Kafka, RabbitMQ, AWS SQS/SNS*; load balancer → *NGINX, HAProxy, AWS ELB/ALB*. A short table (`Technology | Type | Notes`) is ideal. It grounds the abstraction in tools interviewers expect you to name.
- **Cross-link** related concepts with relative paths.
- Source is *System Design Interview* by Alex Xu — write from the relevant chapter (no in-file citation needed); the PDF is not readable in-repo, so flag figures the user may want to verify.

## 7. Markdown formatting (so it renders)

Block elements need a **blank line before and after** them, or many renderers (incl. GitHub) treat them as plain text:
- **Tables** — must have a blank line before the header row. A table glued to the preceding prose line silently fails to render as a table. (Most common mistake.)
- **Code fences** (```` ``` ````), **lists**, and **headings** — same rule: blank line before and after.
- Keep table rows contiguous — no blank line *between* rows.

## 8. Diagrams (Excalidraw)

Add a diagram when a picture argues the concept better than prose (flows, fan-outs, hub-and-spoke, before/after). Diagrams are **optional** — only when they add real clarity — but they make the resource easier to grasp. See [`cdn.md`](./03-networking-and-delivery/cdn.md) for a live example.

**How to make one** (uses the [`excalidraw-diagram`](../.claude/skills/excalidraw-diagram/SKILL.md) skill):
1. Author a `.excalidraw` JSON file in a **`diagrams/`** subfolder next to the doc, e.g. `03-networking-and-delivery/diagrams/cdn.excalidraw`.
2. Render it to PNG (network needed → run with the sandbox disabled):
   `cd .claude/skills/excalidraw-diagram/references && uv run python render_excalidraw.py <path>.excalidraw`
3. **View the PNG and iterate** (render → view → fix) until it's clean — this loop is mandatory.
4. Embed it near the top of the doc: `![plain alt text](./diagrams/name.png)`.

**Rules:**
- Make the diagram **argue** — the shape mirrors the concept (fan-out, timeline, convergence), not just labeled boxes. Follow the skill's methodology.
- **Alt text must be plain** — no parentheses/brackets, they break Markdown image rendering.
- **Commit both** the `.excalidraw` source (editable) and the `.png` (renders on GitHub).

## 9. Before you save — checklist

```
□ Under 120 lines — concept docs only (reference/example docs exempt, §1)
□ Single coherent concept (split if not)
□ No Reference / Goal / Prerequisite header block (ordering covers prerequisites)
□ Ends with a one-paragraph revision summary
□ Tables/code blocks preferred over prose
□ Blank line before & after every table, list, and code block (§7)
□ Every number ties to a decision
□ Names real-world examples / technologies (e.g. Kafka, SQS, NGINX)
□ Diagram (if any): argues the concept, plain alt text, source + PNG committed (§8)
□ Added a row to concepts/README.md
□ Relative cross-links resolve
```

---

> **Note:** the estimation **concept** doc (`back-of-the-envelope-estimation.md`, 262 lines) still exceeds the cap and is a **split candidate** — divide into the concept doc + a reference-tables companion when next touched. The estimation **worked-examples** doc is intentionally long and **exempt** per §1.
