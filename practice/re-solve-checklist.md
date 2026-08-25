# Re-Solve Checklist — Turn Known Gaps Into Points

---

> This is **not** the [Opening Ritual](./opening-ritual.md) (the general drill you run before *every* mock). This is the card for a **deliberate re-attempt** of a problem you've already scored — where you know exactly which gaps cost you and the only job is to *convert them*. The proof this works: **S03 was a re-solve of S02** and moved the verdict from ❌ Fail to ⚠️ Lean Hire. A re-solve is the fastest points on the board because the failure modes are already named.

Pick a problem you've scored below 7 — **[S07 rate limiter](./07-session/README.md)** or **[S04 auction](./04-session/README.md)** are the current targets — and run it again against the three gates below. You pass the re-solve only if all three are green.

---

## 1. The two universal gates (miss these and the score caps ~6.5)

These are the misses that recur on **every** problem, read-heavy or write-heavy. They are habits, not knowledge — so they're free once drilled. See [How to Improve](./README.md#how-to-improve).

| Gate | What "pass" looks like | The failure I keep repeating |
|---|---|---|
| **G1 · Estimation → one decision-forcing number** | Before touching the diagram, compute **one** number that changes the architecture and *say the decision out loud*: "≈500 MB of counters → fits in one Redis node's RAM, so no counter sharding for storage — only for throughput." | I estimate QPS and stop, or skip estimation entirely. A number with no decision attached scores nothing. **Missed in all 7 sessions.** |
| **G2 · Draw the crux data model** | Draw the **one store the whole problem turns on** — its schema, its key, and *why that key*. For the rate limiter that's the counter (`key = client_id:window`, value, TTL); for the auction it's the bid row + the guard column. | I describe the schema verbally or leave the diagram at boxes-and-arrows. **Missed 5 of 7 sessions.** An undrawn model is an unmade decision. |

**Drill:** open with G1 in the first 3 minutes; close with G2 before you say "I'm done." If either isn't on the whiteboard, you haven't finished.

---

## 2. The concurrency reflex — name **AND** solve

The sharper finding across S02 / S03 / S04 / S07: I can *name* the write-path hazard ("there's a race on the counter", "two bids could collide") but stall before reaching the **primitive that fixes it**. Naming the problem is worth ~1 point; solving it is worth ~3. See [Concurrency Control](../concepts/08-distributed-systems/concurrency-control.md).

**The reflex, in order:**

1. **Locate the shared mutable state.** Where do two concurrent requests touch the same row/counter/balance?
2. **Name the hazard** — lost update / double-spend / boundary burst.
3. **Reach for the primitive — do not stop at "we lock it":**

| Hazard | The primitive to say | Not this |
|---|---|---|
| Shared counter under load (rate limiter, likes, stock) | **Atomic `INCR` / Lua script in the store** — the read-modify-write happens *inside* Redis, never in the app | App reads, adds 1, writes back (lost updates under contention) |
| Conditional decrement (inventory, seats, budget) | **Atomic compare-and-set** — `UPDATE … SET qty=qty-1 WHERE qty>0` and check rows-affected | "Check then update" in two statements |
| One entity, ordered writes (auction bid, account balance) | **Single-writer-per-partition** (route by key to one owner) or **optimistic version/CAS** | A global mutex across the fleet |
| Idempotent retries | **Idempotency key** dedup at the write | Assuming the client won't retry |

If I say the hazard but not the row in the right-hand column, the re-solve **fails** on Problem-Solving.

---

## 3. Bring the canonical toolkit — know it cold before you enter

A re-solve means the domain is known, so the standard answers should be *rehearsed*, not improvised. Fill the relevant card from memory **before** starting the clock.

**Rate limiter (S07):**

| Algorithm | One-line trade-off | Default? |
|---|---|---|
| Fixed window | Cheapest; ~2× burst at the boundary | no |
| Sliding-window log | Exact; memory-heavy (one entry per request) | no |
| **Sliding-window counter** | Approximate, cheap — smooths the boundary burst | **the pragmatic pick** |
| **Token bucket** | Allows controlled bursts; industry default (Stripe / AWS / Cloudflare) | **the interview default** |
| Leaky bucket | Smooths output to a fixed rate | when you must pace downstream |

Plus: counters are **ephemeral** (Redis + TTL, *off* any durable DB on the hot path) · rules live in a **config store** (per client/tier/endpoint) · **429 + `Retry-After`** · hot-key mitigation (local pre-aggregate or dedicated shard) · **fail-open vs fail-closed** stated as a business choice.

**Auction / bidding (S04):**

- Bid write guarded by **atomic conditional update** (`WHERE amount > current_high`) or single-writer-per-item.
- Read path (current price, watchers) is cache-friendly; the **write path is the whole problem** — don't spend the budget on the read path.
- Closing the auction = a **scheduled/exactly-once** action; say how you avoid double-close.

If I can't fill the card cold, I'm not ready to re-solve — I'm ready to re-read the concept first.

---

## 4. Keep the diagram alive — redraw on every pivot

The Communication score has been **flat at ~6 for six sessions**, and the cause is a static diagram. Every time a decision changes the design (add a shard, split a service, introduce the config store), **redraw it on the board** and narrate the change. A diagram that doesn't move as the design moves reads as a candidate who stopped thinking.

---

## 5. Post-mock gate — score yourself on the exact misses

Don't score the whole rubric; score only what recurs. Green on all five = the re-solve converted.

- [ ] **G1** — stated one estimation number *and the decision it forced*.
- [ ] **G2** — drew the crux store's schema + key + why-that-key.
- [ ] **Concurrency** — named the hazard **and** the fixing primitive (from §2's right column).
- [ ] **Toolkit** — offered the canonical algorithm/guard with its trade-off, not an improvised one.
- [ ] **Live diagram** — redrew at least once on a pivot.

Then log the re-solve as a new session per [GUIDELINES](./GUIDELINES.md) and update the [tracker](./README.md).

---

## One-Paragraph Summary

A re-solve is the highest-yield mock because the failure modes are already named — the S02→S03 re-attempt turned a Fail into a Lean Hire. Run the target problem against three gates: **(G1)** open with one estimation number *and the decision it forces*, **(G2)** close by drawing the crux store's schema and key, and **(§2)** on the write path, name the hazard *and* reach the primitive that fixes it — atomic `INCR`/Lua for shared counters, compare-and-set for conditional decrements, single-writer or CAS for ordered writes. Bring the canonical toolkit for the domain rehearsed cold, keep the diagram redrawn on every pivot, and self-score only on those recurring misses. Green on all of them is the whole definition of a successful re-solve.
