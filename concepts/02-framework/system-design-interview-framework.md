# A Framework for System Design Interviews

> **Reference:** *System Design Interview* by Alex Xu, Chapter 3.
> **Goal:** A repeatable 4-step process to drive any system design interview — so you spend energy on the design, not on what to do next.

---

## 1. What the Interview Actually Tests

Not a single perfect design — there's no one right answer. It's a *simulation of real-world problem solving* where you and the interviewer collaborate on an open-ended problem. They evaluate:
- **Design skills** and how you reason about trade-offs.
- Ability to **defend** choices and **respond to feedback** constructively.
- Whether you **collaborate** and think out loud.

**Red flags:** **over-engineering** (ignoring cost/complexity) · **narrow mindset** (tunnel vision) · **stubbornness** (dismissing feedback) · **working in silence**.

---

## 2. The 4-Step Process

Time budgets assume a **45-minute** interview.

```
Step 1  Understand the problem & establish scope     ~3–10 min
Step 2  Propose high-level design & get buy-in       ~10–15 min
Step 3  Design deep dive                             ~10–25 min
Step 4  Wrap up                                      ~3–5 min
```

**Step 1 — Understand & scope.** The #1 mistake is jumping to a solution. Ask questions to nail requirements; answering the wrong problem is an automatic fail. **Write down every assumption.** Ask: what features? how many users / expected scale / growth? tech stack & reusable services? read vs. write patterns? *(News feed: mobile or web? chronological or ranked? DAU? media allowed?)*

**Step 2 — High-level design & buy-in.** Treat the interviewer as a teammate. **Draw box diagrams** (clients, API servers, data stores, cache, CDN, queue). Do **back-of-the-envelope** math to check the blueprint fits scale — see [envelope estimation](../01-envelope-estimation/back-of-the-envelope-estimation.md). Walk a few **concrete use cases** to surface edge cases. Add API endpoints / DB schema if the problem warrants.

**Step 3 — Deep dive.** With the blueprint agreed, **prioritize together** and detail the **most critical** components first (URL shortener → key generation; chat → latency + presence). Discuss performance, bottlenecks, edge cases. **Watch the clock** — over-detailing one box signals poor prioritization.

**Step 4 — Wrap up.** Recap the design; identify **bottlenecks** and improvements; discuss **failure cases** (server/network) and recovery; **operations** (monitoring, logs, rollout); the **next scale curve** (1M → 10M); refinements you'd make with more time.

---

## 3. Dos and Don'ts

**Do:** ask for clarification (don't assume); understand requirements first; remember it's trade-offs, not a "best" answer; communicate constantly; suggest multiple approaches; go critical-component-first after the blueprint; treat the interviewer as a teammate; never give up.

**Don't:** be unprepared for common questions; jump to a solution before clarifying; go deep on one component too early; hesitate to ask for hints; design in silence; assume you're done at first design — ask for feedback early and often.

---

## 4. In-the-Room Checklist (quick reference)

```
□ STEP 1 — Scope
    □ Restate the problem in one sentence
    □ List target features (confirm the 2–3 that matter)
    □ Get scale numbers: DAU, read:write ratio, growth
    □ Write down every assumption
□ STEP 2 — High-level design
    □ Draw boxes: client → LB → API servers → cache → DB → (CDN, queue)
    □ Back-of-the-envelope: QPS, storage, bandwidth
    □ Walk one end-to-end use case; get buy-in
□ STEP 3 — Deep dive
    □ Agree which components to detail
    □ Detail the critical one(s): data model, algorithm, scaling
    □ Call out bottlenecks & edge cases; watch time
□ STEP 4 — Wrap up
    □ Recap the design
    □ Bottlenecks + how to handle the next 10× of scale
    □ Failure modes, monitoring, rollout
```

---

## 5. One-Paragraph Summary (for quick revision)

The system design interview is a collaborative simulation, not a quest for one perfect answer — interviewers reward clear reasoning, trade-off awareness, and communication, and penalize over-engineering, narrow-mindedness, and silence. Drive it with the **4-step process**: (1) **scope** by asking questions and writing down assumptions — never jump to a solution; (2) **high-level design** with box diagrams, sanity-checked with back-of-the-envelope math, and get buy-in; (3) **deep-dive** the critical components you prioritized together, watching the clock; (4) **wrap up** with a recap, bottlenecks, failure modes, operations, and the next scale curve. Keep the interviewer in the loop throughout.
