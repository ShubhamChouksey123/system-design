# Deployment & Rollback Strategies — blue-green, canary, rolling

---

Shipping new code is itself a **reliability event** — the deploy mechanism decides how big the blast radius is when the new version is bad, and the rollback plan decides how fast you recover. This is the release-engineering half of [resilience patterns](./resilience-patterns.md) (a bad deploy is a self-inflicted failure) and leans on [observability](./observability.md) — you can't gate a rollout on metrics you don't have.

## 1. The core trade-off — blast radius vs. speed vs. cost

Every strategy trades three things: **how many users see a bad version before you notice**, **how fast you can undo it**, and **how much extra infrastructure it costs**.

| Strategy | Downtime | Blast radius on a bad release | Rollback speed | Infra cost |
|---|---|---|---|---|
| **Recreate** (stop old, start new) | Yes — full outage during swap | 100% | Redeploy old version (slow) | Lowest — 1 environment |
| **Rolling** | None (if healthy) | Partial — grows as the rollout proceeds | Slow — must roll *back* instance-by-instance | Low — same fleet, briefly ×1.1–1.5 |
| **Blue-Green** | None | 100% once switched (but switch is instant) | **Instant** — flip the router back | High — 2 full environments |
| **Canary** | None | **Smallest** — capped at the canary % | Fast — pull the canary out of rotation | Medium — small extra capacity |
| **Feature flag** | None | Configurable — 0% to a targeted cohort to 100% | **Instant** — flip the flag, no deploy | Lowest — one flag service, no extra fleet |
| **A/B test** | None | Both variants **stay live by design**, not a rollout | Instant — stop the experiment, route all to control | Low-medium — experimentation platform + analytics |
| **Shadow (dark traffic)** | None | **Zero** — the new version's output is discarded | Instant — stop mirroring | Medium-high — duplicates load, serves no traffic |

## 2. Rolling deployment

Replace instances **a few at a time**: stop N old, start N new, wait for health checks to pass, repeat until the fleet is fully on the new version. Standard default (Kubernetes' native `RollingUpdate`).

- Tunable via **`maxUnavailable`** (how many can be down at once) and **`maxSurge`** (how many extra can run during the rollout) — the two knobs that trade rollout speed against capacity headroom.
- **Gate every step on health checks**, not a timer — an unhealthy new instance must stop the rollout, not be counted as "done."
- **Weakness:** old and new versions **run side-by-side** for the whole rollout, so both must be able to talk to the same downstream (DB schema, message format) at once — see §7.
- **Weakness:** rolling *back* is just a rolling deploy of the old version — no faster than rolling forward.

## 3. Blue-Green deployment

Run **two full, identical environments** — Blue (live) and Green (idle, holding the new version). Deploy fully to Green, test it in isolation, then **flip the router/load balancer** to send all traffic to Green in one atomic switch. Blue stays warm as the instant rollback target.

- **Rollback = flip the router back.** No redeploy, no waiting — this is the fastest rollback of any strategy.
- **Cost:** doubles running infrastructure for the cutover window (or permanently, if kept warm on standby).
- **The switch must be atomic** — DNS-based switches can take minutes to propagate (TTL) and leave some users on each side; a load-balancer target-group swap (e.g. **AWS ALB**, **AWS CodeDeploy**'s blue/green mode) is instant and the safer default.
- Same schema/protocol constraint as rolling — both environments may briefly receive live traffic and, during a DB-backed migration, might share one database (§7).

## 4. Canary deployment

Route a **small percentage** of real traffic (e.g. 1% → 5% → 25% → 100%) to the new version while the rest stays on the old one, **watching error rate / latency / business metrics** at each stage before promoting further.

- **Smallest blast radius by design** — a bad release only ever hurts the canary slice, and that slice is capped.
- **Needs automated analysis to be worth it**: compare the canary's metrics against the baseline (not just "did it crash") and **auto-rollback** (pull the canary from rotation) if it regresses — this is what tools like **Argo Rollouts** and **Flagger** automate.
- **Traffic splitting mechanism matters**: a service mesh (**Istio**, **Linkerd**) or an API gateway can split by *percentage* or by *header/user-cohort* (route internal users to canary first) — a load balancer with weighted target groups (**AWS ALB / CodeDeploy canary**) gets you percentage-only.
- Slower to reach 100% than blue-green by design — the staged ramp *is* the safety mechanism.

## 5. A/B testing

Split traffic between two (or more) variants **on purpose, for a sustained period**, to measure a business or product metric — not to de-risk a release. This is canary's traffic-splitting mechanism reused for a **different intent**: canary asks "is the new version safe?" and shrinks back to one version once it's proven; A/B asks "which version performs better?" and *keeps both running* until the experiment has enough data to answer.

- **Sticky bucketing is mandatory** — the same user must see the same variant on every visit (hash `user_id` to a bucket), or the comparison is meaningless and the UX is incoherent.
- **Needs a large enough sample and a fixed duration** to reach statistical significance — stopping early on a promising-looking delta is a classic false-positive trap ("peeking").
- **Guardrail metrics** — track error rate/latency alongside the business metric being tested, so a "winning" variant that's secretly slower or broken doesn't get promoted anyway.
- Often layered **on top of** a feature flag (§7) — the flag controls exposure, an experimentation platform (**Optimizely**, **Statsig**, **AWS CloudWatch Evidently**) handles bucketing and significance testing.

## 6. Shadow deployment (dark traffic)

**Mirror** a copy of live production requests to the new version **without ever returning its response to the user** — the old version's response is the only one that reaches them. This gets you real production load and data for validation with **zero user-facing risk**, even smaller than canary's capped-but-nonzero exposure.

- **Best for backend/read-path changes** — a new ranking algorithm, a rewritten query path, a service migration — where you want to diff the shadow's output/latency against the live response before ever exposing it.
- **Wrong tool for side-effecting writes**: mirroring a `POST` that charges a card or sends an email means the shadow silently double-executes it — either make the shadowed path read-only, or fence writes behind a dry-run flag.
- **Can't validate anything user-perceivable** — a UI change or anything where the response content itself matters needs canary/A-B, not shadow, since nobody ever sees the shadow's output.
- Native support: **Istio's** `mirror` traffic policy, **Argo Rollouts**' analysis step — both duplicate the request at the mesh/ingress layer with no application change needed.

## 7. Feature flag deployment

Decouple **shipping code** from **releasing behavior**: deploy the new code path behind a flag, defaulted **off**, to every instance — then turn it on gradually (by percentage, by cohort, or for internal users first) via a **config change, not a redeploy**. This is what makes canary/A-B traffic splits controllable at the *feature* level instead of the *instance* level.

| Flag type | Purpose |
|---|---|
| **Release flag** | Hide an incomplete feature merged to trunk (enables trunk-based development — merge daily, release later) |
| **Ops flag** | A manual kill switch for a risky operational path (e.g. disable a non-critical write to shed load) |
| **Experiment flag** | Drives an A/B test's variant assignment (§5) — unlike the others, long-lived by design, not removed after a rollout |

- **The fastest rollback in this entire doc**: flip the flag, no deploy, no router change — propagates in seconds through the flag SDK's streaming/polling update.
- **The debt this creates**: a flag left in the code after full rollout is dead weight and a combinatorial testing liability — every flag needs an **owner and a removal date**, not just a launch date.
- Real systems: **LaunchDarkly**, **Unleash**, **AWS AppConfig**, **Split.io** — evaluate flags client-side or via a lightweight SDK call, typically cached locally so flag checks don't add request latency.

## 8. The constraint every strategy shares — backward compatibility

Rolling, canary, and (briefly) blue-green all have **two versions of the code live at once**, often against **one shared database**. If v2 writes a row shape v1 can't read, rolling back v1 (or just leaving it running mid-rollout) breaks it — the deploy strategy didn't fail, the *migration* did. This is the **expand-contract** pattern: add the new column/field as nullable and *dual-write* it (expand) → deploy the code that reads it → only once every instance is on the new version, remove the old field (contract). Full treatment (the three-phase expand → migrate → contract sequence, plus backward-compatible API changes) lives in [Testing & Migration Strategies](./testing-and-migration-strategies.md) — the deploy strategy only works if the migration underneath it is compatible with both versions running together.

## 9. Rollback strategies

| Mechanism | How fast | When to reach for it |
|---|---|---|
| **Re-deploy previous version** | Minutes (rolling) / instant (blue-green router flip) | The code itself is bad |
| **Feature flag kill switch** | Seconds, no deploy at all | The *feature* is bad but the surrounding release is fine — decouples "ship the code" from "turn on the behavior" |
| **Database migration rollback** | Often can't be instant | Only safe if the migration followed expand-contract (§7); rolling back a *destructive* migration (dropped column) can lose data |
| **Traffic shift back to canary/blue baseline** | Instant | Metrics regressed during a canary/blue-green rollout, before full promotion |

**The feature flag is the most underrated rollback tool** — it turns "redeploy to undo" into "flip a config value," and it's the only mechanism on this list that doesn't require touching infrastructure at all.

## 10. Real-world implementations

| Tool | Strategy support |
|---|---|
| **Kubernetes** (native) | Rolling update out of the box (`maxUnavailable`/`maxSurge`); Recreate as an explicit option |
| **Argo Rollouts / Flagger** | Canary and blue-green on top of Kubernetes, with automated metric analysis and auto-rollback |
| **AWS CodeDeploy** | Blue/green (EC2, ECS, Lambda) and canary/linear traffic shifting, integrated with **AWS CloudWatch** alarms for auto-rollback |
| **Istio / Linkerd** (service mesh) | Fine-grained traffic splitting for canary — by percentage or by request header/cohort |
| **Spinnaker** | Multi-cloud CD pipelines orchestrating any of the above stages |
| **LaunchDarkly / Unleash / AWS AppConfig** | Feature-flag platforms — the kill-switch rollback mechanism, decoupled from deploys |
| **Optimizely / Statsig / AWS CloudWatch Evidently** | Experimentation platforms — sticky bucketing, guardrail metrics, and statistical significance for A/B tests |

## 11. Do / Don't

- **Do** gate every rollout stage on **automated health/metric checks**, never a fixed sleep timer.
- **Do** keep the previous version's environment warm (blue-green) or the previous image cached (rolling) so rollback doesn't mean a cold rebuild.
- **Do** pair any risky deploy with a **feature flag**, so the fastest rollback never requires touching infra at all.
- **Don't** ship a schema change that breaks the *previous* version — assume both versions run simultaneously during any non-recreate strategy.
- **Don't** treat "canary showed no errors after 2 minutes" as sufficient — regressions in latency/business metrics often show up only under sustained real load.
- **Don't** confuse a DNS-based blue-green switch with an instant one — TTLs mean some users stay on the old side for minutes.
- **Don't** let a feature flag outlive its rollout (give every flag an owner + removal date), and don't call an early A/B delta a winner before the planned sample size — both are the same mistake: declaring done before the data says so.

## 12. One-Paragraph Summary (for quick revision)

Every deployment strategy trades **blast radius**, **rollback speed**, and **infra cost**. **Rolling** replaces instances a few at a time (`maxUnavailable`/`maxSurge`), is cheap, but rolls back no faster than it rolled forward. **Blue-green** runs two full environments and flips a router atomically — the **fastest rollback** (just flip back) at **double the infra cost**. **Canary** ramps a small traffic percentage while watching metrics, giving the **smallest blast radius** but requiring automated analysis to be worth it (**Argo Rollouts**, **Flagger**). **Shadow deployment** mirrors real traffic to the new version but discards its response, giving **zero user-facing risk** — smaller than canary's — at the cost of duplicated load and no coverage for anything user-visible or side-effecting. A **feature flag** decouples shipping code from releasing behavior entirely — ship dark, flip on later via config, no redeploy — making it the **fastest rollback of all** (seconds, no infra touched) at the cost of flag debt if left uncleaned. **A/B testing** reuses canary's traffic-split mechanism for a different purpose: not de-risking a release, but *measuring* which of two long-lived variants performs better, with sticky bucketing and guardrail metrics guarding against a false-positive "win." All strategies except a clean recreate run **two code versions live at once**, which only works if the underlying data migration follows **expand-contract** — add-and-dual-write before removing the old shape. In practice: **Kubernetes** rolling by default, **Argo Rollouts/Flagger** or **AWS CodeDeploy** for canary/blue-green with **AWS CloudWatch**-gated auto-rollback, **LaunchDarkly/Unleash** for the flag layer, and **Optimizely/Statsig** for experimentation on top.
