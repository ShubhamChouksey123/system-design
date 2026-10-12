# Testing & Migration Strategies — safe feature rollout, backward-compatible changes

---

[Deployment strategies](./deployment-and-rollback-strategies.md) control *how many users* see a bad change; this concept is about making sure the change **can't be bad in the first place** — caught before release by the right layer of testing, and incapable of breaking the *existing* feature because the API/schema change underneath it was rolled out compatibly. The two halves of "ensuring the existing feature doesn't break": **test pyramid** (catch it pre-deploy) and **expand-contract migration** (don't let the change be a breaking one at all).

## 1. The testing pyramid — what catches what, and how fast

| Layer | Tests | Speed | Catches |
|---|---|---|---|
| **Unit** | One function/class, dependencies mocked | Milliseconds, thousands run per CI push | Logic bugs in isolation |
| **Integration** | A service against a real DB/queue (often in a container) | Seconds | Wiring bugs — the code *and* its dependency disagree |
| **Contract** | A consumer's expectations of a provider's API, verified on both sides | Seconds | **The producer breaking a consumer it never talks to directly in the test** — the exact "existing feature broke" failure mode |
| **End-to-end** | The full deployed stack, real network calls | Minutes | Cross-service regressions unit/integration can't see |
| **Smoke / synthetic** | A handful of critical paths, run **after** deploy, on a schedule | Continuous | A bad release that passed every pre-deploy gate anyway |

**More tests at the bottom, fewer at the top** — E2E suites are slow and flaky at scale, so push as much coverage as possible down to unit/contract level and reserve E2E for the paths that truly need the whole stack.

## 2. Contract testing — the one layer that targets "did I break someone else"

A **consumer-driven contract** records what each consumer actually calls and expects from a provider's API — the consumer publishes its expectations, and the **provider's CI** replays them on every change, failing the build if a real consumer's expectation would break. This is what a unit test *can't* catch (it mocks the dependency) and what an E2E test catches *too late* (only after standing up everyone's services together).

- Tools: **Pact**, **Spring Cloud Contract**.
- Runs in **each side's own CI**, independently — no shared staging environment full of every microservice required.
- The direct fix for "I changed my API and something downstream broke" without needing a live integration environment to prove it.

## 3. Backward-compatible API changes

| Change | Safe? | Why |
|---|---|---|
| Add a new optional field/endpoint | ✅ Safe | Old clients ignore fields they don't know about (**Postel's Law** — be tolerant of unknown fields on the read side) |
| Add a required field | ❌ Breaking | Old clients never send it — every old request now fails validation |
| Rename or remove a field | ❌ Breaking | Old clients (or new clients reading old-shaped cached data) reference the old name |
| Change a field's type/meaning | ❌ Breaking | Silent — often passes validation but corrupts data downstream |

- **Additive-only** changes need no version bump — they're safe by construction.
- **Breaking changes need a version boundary** — URI (`/v2/orders`), header (`Accept-Version: 2`), or a field-level `deprecated` flag with a **sunset date** communicated *before* removal.
- Never remove a deprecated field/endpoint until telemetry shows **zero real traffic** still using it — a version bump doesn't retire old clients, it just gives you the option to.

## 4. Backward-compatible schema migrations — expand-contract in full

The migration that makes rolling/canary/blue-green deploys safe (see the [deployment doc](./deployment-and-rollback-strategies.md#8-the-constraint-every-strategy-shares--backward-compatibility)) is never a single `ALTER TABLE` — it's three phases, each one independently safe to deploy and roll back:

| Phase | What happens | Why it's safe |
|---|---|---|
| **1. Expand** | Add the new column/table as **nullable** (or with a default); deploy code that **dual-writes** — writes both the old and new shape | Old code paths are untouched; new code path is additive only |
| **2. Backfill + migrate reads** | A background job fills the new column for existing rows (batched, off-peak, rate-limited so it doesn't lock the table); once backfilled, deploy code that **reads from the new shape** | Both shapes are populated and consistent before anything depends on the new one exclusively |
| **3. Contract** | Once every instance is confirmed on the new code path (no old version left running), **stop writing the old shape**, then drop it | Nothing reads or writes the old column anymore — dropping it can't break a live request |

- **Never skip straight to a destructive change** (drop/rename a column in one step) — that's exactly what turns a routine deploy into an outage the moment any instance is still running the old code, or a rollback is needed.
- **A rollback mid-migration only works if you're still inside phase 1 or 2** — once phase 3 has dropped the old column, there is no old shape left to roll back to; this is *why* expand-contract keeps the destructive step last and separate.
- Large-table backfills need their own throttling story (batch size, replica lag budget) — treat the backfill job itself as a load-bearing piece of infra, not a one-off script.

## 5. Testing the rollout itself, not just the code

- **Shadow / dark traffic** and **canary** (deployment doc) are testing strategies as much as deployment ones — they're how you validate a change against *real* production load before it's fully live.
- **Smoke tests immediately post-deploy** — a small, fast suite hitting critical paths right after a rollout stage, gating automatic promotion/rollback before a human notices.
- **Synthetic monitoring** — the same smoke checks, run continuously in production (not just at deploy time) from outside the system, catching regressions a real deploy didn't even cause (an expired cert, a DNS change).

## 6. Real-world implementations

| Tool | Layer |
|---|---|
| **Pact / Spring Cloud Contract** | Consumer-driven contract testing |
| **Flyway / Liquibase** | Versioned, repeatable schema migrations — the expand-contract steps as tracked, ordered migration files |
| **Cypress / Playwright / Selenium** | End-to-end browser testing |
| **Postman / Newman** | API-level integration & smoke test suites, runnable in CI |
| **Datadog Synthetics / AWS CloudWatch Synthetics** | Continuous synthetic monitoring in production |

## 7. Do / Don't

- **Do** push coverage down the pyramid — a bug caught by a unit test is orders of magnitude cheaper than the same bug caught by an on-call engineer.
- **Do** treat a schema/API change as three separate, independently-deployable steps (expand → migrate → contract), never one.
- **Do** verify a deprecated field/endpoint has **zero traffic** (via telemetry) before removing it — a version bump is a courtesy, not an enforcement mechanism.
- **Don't** add a *required* field to an existing API — every old client breaks the moment the new validation deploys.
- **Don't** run a large backfill unthrottled — it competes with live traffic for the same table/replica capacity.
- **Don't** treat contract tests as optional "nice to have" — they're the one layer specifically aimed at the "did I break a consumer I never tested against" failure mode.

## 8. One-Paragraph Summary (for quick revision)

Making sure a change can't break the existing feature has two halves. **Testing**: push coverage down the pyramid (unit → integration → **contract** → E2E → post-deploy smoke/synthetic) — **contract testing** (Pact, Spring Cloud Contract) is the layer purpose-built for "did I break a consumer," verified independently on each side's CI without a shared staging environment. **Migration**: never ship a breaking schema/API change in one step — **expand** (additive, nullable, dual-write) → **backfill and migrate reads** (both shapes populated and consistent) → **contract** (stop writing and drop the old shape, only once nothing depends on it) — the same pattern that makes rolling/canary/blue-green deploys safe, because it guarantees old and new code can coexist at every phase except the last. API changes follow the same additive-first rule: new optional fields are safe by construction (Postel's Law), while required-field additions, renames, and type changes need a version boundary and a deprecation window with **verified zero traffic** before removal. In practice: **Flyway/Liquibase** for tracked migrations, **Pact** for contracts, **Cypress/Playwright** for E2E, and **Datadog/AWS CloudWatch Synthetics** for continuous post-deploy verification.
