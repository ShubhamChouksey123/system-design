# A Framework for System Design Interviews

> **Reference:** *System Design Interview – An Insider's Guide* by Alex Xu, Chapter 3.
> **Goal:** A repeatable 4-step process to drive any system design interview — so you spend your energy on the design, not on figuring out what to do next.

---

## 1. What the Interview Actually Tests

A system design interview is **not** about producing a single perfect design. There is no one right answer. It is a *simulation of real-world problem solving* where you and the interviewer collaborate on an open-ended problem.

Interviewers are evaluating:
- Your **design skills** and how you reason about trade-offs.
- Your ability to **defend** your choices — and to **respond to feedback** constructively.
- Whether you can **collaborate** and think out loud, treating the interviewer as a teammate.

**Red flags interviewers watch for:**
- **Over-engineering** — gold-plating a design while ignoring cost/complexity (a known weakness, not a strength).
- **Narrow mindset** — refusing to consider alternatives; tunnel vision on one approach.
- **Stubbornness** — dismissing feedback instead of engaging with it.
- **Working in silence** — designing without communicating, so the interviewer can't follow or help.

---

## 2. The 4-Step Process (the core of this chapter)

Time budgets assume a typical **45-minute** interview.

```
Step 1  Understand the problem & establish scope     ~3–10 min
Step 2  Propose high-level design & get buy-in       ~10–15 min
Step 3  Design deep dive                             ~10–25 min
Step 4  Wrap up                                      ~3–5 min
```

### Step 1 — Understand the problem and establish design scope

**The #1 mistake is jumping to a solution.** Slow down. Think deeply and ask questions to nail down requirements and assumptions. Answering the wrong problem is an automatic fail.

When you ask a question, the interviewer either answers it or asks you to state your own assumption. If it's an assumption, **write it down** — you'll need it later.

Questions worth asking (adapt per problem):
- What **specific features** are we building?
- How many **users**? What's the expected **scale**, and how fast will it grow (3 months / 6 months / 1 year)?
- What's the **tech stack**? Are there existing services we can leverage to simplify the design?
- What are the **read vs. write** patterns and volume?

> **Example (news feed):** Is it mobile, web, or both? What are the most important features? Is the feed sorted chronologically or by ranking/relevance? How many friends can a user have? What is the traffic volume (DAU)? Can the feed contain media (images, video)?

### Step 2 — Propose high-level design and get buy-in

Aim for an **initial blueprint** and actively solicit feedback. Treat the interviewer as a teammate.

- **Draw box diagrams** of the key building blocks: clients, API servers, data stores, cache, CDN, message queue, etc.
- Do **back-of-the-envelope calculations** to check the blueprint fits the scale constraints. Think out loud and confirm with the interviewer whether estimation is expected. *(See the [envelope estimation](../01-envelope-estimation/back-of-the-envelope-estimation.md) concept.)*
- Walk through **a few concrete use cases**. This surfaces edge cases and helps shape the design.
- Whether to include **API endpoints and a DB schema** here depends on the problem's size — ask, or state that you'll add them.

> **Example (news feed):** the design splits into two flows — **feed publishing** (a user posts; it's written and fanned out to friends) and **news feed building** (aggregating friends' posts in reverse-chronological/ranked order).

### Step 3 — Design deep dive

By now you and the interviewer should have: agreed on overall goals and feature scope, sketched a high-level blueprint, and gotten feedback on it. Now go deep.

- **Together, prioritize** which components to drill into. Design the **most critical / most interesting** parts first.
- Dive into specifics: e.g., for a URL shortener → the **hash function**; for a chat system → **latency reduction** and **online/offline presence**.
- Discuss **performance characteristics, bottlenecks, and edge cases**.
- **Watch the clock.** Don't get carried away with unnecessary detail on one component — that signals poor prioritization and burns time you need elsewhere.

### Step 4 — Wrap up

A few minutes to tie it off. Useful discussion points:
- **Identify bottlenecks** and discuss potential improvements. There's always more to refine.
- Give a **recap** of your design — especially valuable if you offered several solutions.
- **Error / failure cases**: server failure, network loss, and how the system degrades or recovers.
- **Operational concerns**: monitoring metrics, error logs, and how you'd roll the system out.
- **The next scale curve**: how the design handles the next order of magnitude (e.g., 1M → 10M users).
- **Further refinements** you'd make with more time.

---

## 3. Dos and Don'ts (from the chapter)

**Do:**
- Always ask for clarification. Don't assume your assumption is correct.
- Understand the requirements of the problem before designing.
- Remember there is neither the right answer nor the best answer — only trade-offs.
- Communicate. Let the interviewer know what you are thinking.
- Suggest multiple approaches when you can.
- After agreeing on the blueprint, go component by component, most critical first.
- Bounce ideas off the interviewer — a good one works with you as a teammate.
- Never give up.

**Don't:**
- Don't be unprepared for common questions.
- Don't jump to a solution before clarifying requirements and assumptions.
- Don't go deep on a single component too early — high-level first, then drill down.
- Don't hesitate to ask for hints if you're stuck.
- Don't design in silence.
- Don't assume you're done when you present the design — ask for feedback early and often.

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
    □ Agree on which components to detail
    □ Detail the critical component(s): data model, algorithm, scaling
    □ Call out bottlenecks & edge cases; keep an eye on time

□ STEP 4 — Wrap up
    □ Recap the design
    □ Bottlenecks + how to handle the next 10× of scale
    □ Failure modes, monitoring, rollout
```

---

## 5. One-Paragraph Summary (for quick revision)

The system design interview is a collaborative simulation, not a quest for one perfect answer — interviewers reward clear reasoning, trade-off awareness, and communication, and penalize over-engineering, narrow-mindedness, and silence. Drive every interview with the **4-step process**: (1) **understand & scope** the problem by asking clarifying questions and writing down assumptions — never jump to a solution; (2) **propose a high-level design** with box diagrams, sanity-check it with back-of-the-envelope math, and get buy-in; (3) **deep-dive** the most critical components you've prioritized together, watching the clock; (4) **wrap up** with a recap, bottlenecks, failure modes, operations, and the next scale curve. Keep the interviewer in the loop the entire time.
