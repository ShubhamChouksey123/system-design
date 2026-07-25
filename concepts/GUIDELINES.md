# Authoring Guidelines — `concepts/`

Rules for every file created inside `concepts/`. Keep docs short, focused, and revision-friendly.

---

## 1. File size — hard cap **< 120 lines**

Every concept file MUST be **under 120 lines**. Short docs are easier to revise before an interview and force tight, high-signal writing.

- If a topic needs more, **split it into companion files** in the same folder (e.g. `basics.md` + `load-balancing-and-consistent-hashing.md`), each under the cap.
- Prefer **tables and code blocks** over prose paragraphs — they carry more information per line.
- Cut throat-clearing and repetition; every line should earn its place.

> Check before saving: `wc -l concepts/**/your-file.md` → must be `< 120`.

## 2. One concept per file

A file covers a single, coherent topic. If you're using "and" to join two unrelated ideas, that's two files. Companion files share a concept folder and are linked from the index as `↳` sub-rows.

## 3. Naming & placement

- Each concept is a **folder**: `NN-topic/` (zero-padded number sets order; `00-` for foundational).
- Files *inside* use descriptive kebab-case **without** the number prefix — e.g. `back-of-the-envelope-estimation.md`.
- Add every new file to the index at [`concepts/README.md`](./README.md) (with `↳` sub-rows for companions).

## 4. Required structure

**Concept doc:**
1. `>` blockquote header — cite the book chapter + a one-line goal.
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
- **Cross-link** related concepts with relative paths.
- Source is *System Design Interview* by Alex Xu — write from the referenced chapter; the PDF is not readable in-repo, so flag figures the user may want to verify.

## 7. Before you save — checklist

```
□ Under 120 lines (wc -l)
□ Single coherent concept (split if not)
□ Blockquote header (chapter + goal) present
□ Ends with a one-paragraph revision summary
□ Tables/code blocks preferred over prose
□ Every number ties to a decision
□ Added a row to concepts/README.md
□ Relative cross-links resolve
```

---

> **Note:** files created before this rule exceed 120 lines (`basics.md`, both estimation docs, the framework doc). They're **split candidates** — refactor into companions when next touched; don't grow them further.
