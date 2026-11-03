# Siege Survival implementation chain — progress report

**Status:** Chain running — S1 and S2 started 2026-11-03; G1, S3 and S4 wait for merges (see "Waiting for the developer")
**Last updated:** 2026-11-03 (S2 pushed)
**Charter:** [SIEGE_SURVIVAL_CHAIN.md](../ai-agents/handoffs/SIEGE_SURVIVAL_CHAIN.md) · **Coordinator prompt:**
[2026-11-03-siege-survival-coordinator-prompt.md](../ai-agents/handoffs/2026-11-03-siege-survival-coordinator-prompt.md) ·
**Plan:** [IMPLEMENTATION_PLAN.md §2a](../specs/siege-survival/IMPLEMENTATION_PLAN.md#2a-delivery-order-and-merge-gates-2026-11-03) ·
**Design:** [DESIGN.md](../specs/siege-survival/DESIGN.md) (S01–S68)
**Issues:** [PandiO/knk-workspace#41](https://github.com/PandiO/knk-workspace/issues/41) (KNG-50), [#146](https://github.com/PandiO/knk-workspace/issues/146) (NPC behavior)
**Base at start (2026-11-03):** knk-plugin `main` `306937f5`, knk-web-api `master` `38e6abc`, knk-web-app `main` `b770597`,
knk-workspace `main` `84a5a63` (re-check: later merges on the trunks happen; each link records its own base).

## Waiting for the developer

(The coordinator keeps this list current: links in review with their checklist location, merges that open the next gate,
flagged decisions.)

- **Nothing to test yet.** S1 and S2 are core-only links (knk-core, Bukkit-free, unit tests) with no live checklist.
- **Merges that open the next gates**, in the suggested order (each branch is ahead of its trunk, see the gate check below):
  1. #167 `claude/alpha-run-1-gates` (plugin, API, web app) — with #180 it opens **S4**; with #213 and realtime it opens **G1**.
  2. #213 `claude/siege-pregame-gate-view` (plugin only) — needed by **G1** and **S3**.
  3. #180 `claude/world-task-hardening` (plugin, API, web app) — with #167 it opens **S4** (migrations).
  4. `claude/realtime-signalr` (plugin, API, web app; contains link 7 = `claude/world-task-hardening`; `realtime.enabled`
     off by default — check which link 10 changes act with the flag off before merging without the SignalR checklists) —
     needed by **G1** and **S3** (`GateManager`, gate services, Siege files).
  5. Arena-duels decision: merge `claude/arena-duels` or catch it up with `main` (plugin is 23 ahead / 40 behind) —
     needed by **S3**.
  6. Web building blocks (#95 `claude/design-tokens…`, #39 rest `claude/entity-lists-url-state`, #33, #187, #30) or a
     developer waiver — needed by **S9** (last link; also depends on S1–S8).
- **Flags needing a decision:** S2-1 … S2-8 (defaults chosen in link S2: floors, caps, resolution order, jitter flag, override keys; see the S2 block).

## Gate check (coordinator, 2026-11-03)

`git rev-list --count <default>..origin/<branch>` on the actual trunks (plugin `main` `306937f5`, API `master` `38e6abc`,
web app `main` `b770597`). A gate is open only when every branch it names is at 0 in every repo.

| Branch | plugin ahead / behind | API ahead / behind | web app ahead / behind | Gate for |
|---|---|---|---|---|
| `claude/alpha-run-1-gates` (#167) | 1 / 25 (`e7c5a93c`) | 1 / 10 (`87f6ab0`) | 1 / 23 (`0af1dbf`) | G1, S4 |
| `claude/siege-pregame-gate-view` (#213) | 1 / 7 (`81aa1723`) | — | — | G1, S3 |
| `claude/world-task-hardening` (#180) | 3 / 7 (`21de734e`) | 2 / 2 (`115c418`) | 1 / 10 (`d7a0896`) | S4 |
| `claude/realtime-signalr` | 12 / 7 (`eb22a655`) | 10 / 2 (`e769c4c`) | 3 / 8 (`c7a3e85`) | G1, S3 |
| `claude/arena-duels` | 23 / 40 (`ca533e43`) | 15 / 17 (`b220af1`) | 5 / 46 (`7f4c418`) | S3 |
| `claude/siege-survival` | not created yet | not created yet | not created yet | — |
| `claude/gate-animated-rebuild` | not created yet | not created yet | not created yet | — |

Result: **G1, S3 and S4 are closed**; S1 and S2 (no gate) start now. The heads match the ones recorded in plan §2a.

## Summary

Status values: `ready` (gate open), `waiting: <gate>`, `in progress`, `in review` (pushed, waiting for the developer's
test), `merged`, `blocked: <reason>`.

| Link | Scope (plan §2a) | Repos / branch | Status | Started | Heads (plugin / api / web-app / workspace) | Tests vs baseline |
|---|---|---|---|---|---|---|
| S1 | Survival core logic (waves, kills, round delay, stuck rules, end conditions, scaling presets, monster mix, specials, repair maths, spawn selection, rewards, Mystery Box pick) | plugin `claude/siege-survival`, `knk-core/.../core/survival/` only | in progress | create_session session_01R1w2UvKtghxZowkQBTRYqG, 2026-11-03 | — | — |
| S2 | NPC platform §5b core: combat and speed profiles, modifier pipeline by source, clamping with a report | plugin `claude/siege-survival`, `knk-core/.../core/npc/` only | in review | create_session session_01R1w2UxEVJTzDXBdKWkGihy, 2026-11-03 | plugin `8cf2761e` / — / — / — | core 2433 → 2494 (+61, 0 failures); api-client 288, paper 2385 unchanged |
| G1 | Animated rebuild for all destroyed gates (gate Decision 6), size-aware evacuation | API, plugin, web app `claude/gate-animated-rebuild` | waiting: #167, #213, realtime merged | — | — | — |
| S3 | Siege prerequisites: visibility arbiter, NPC gate-damage cause, weighted capture presence, mob kills out of PvE statistics | plugin `claude/siege-survival` | waiting: realtime, #213 merged; arena-duels merged or caught up | — | — | — |
| S4 | Phase 1 contracts/config: entities, migrations, DTOs, form seeds, readiness; api-client DTOs | API, plugin api-client `claude/siege-survival` | waiting: #167, #180 merged | — | — | — |
| S5 | Phase 2 runtime slice (mob spawning and goals, §5b adapters, ghost state, waves, end conditions) | plugin `claude/siege-survival` | waiting: S1–S4 on the branch | — | — | — |
| S6 | Phase 3 repairs and frontier (sneak repair input, provisional) | plugin `claude/siege-survival` | waiting: G1 merged | — | — | — |
| S7 | Phase 4 equipment modes, economy, Mystery Box | API, plugin `claude/siege-survival` | waiting: S4 | — | — | — |
| S8 | Phase 5 specials, results, recovery, per-kill settlement | API, plugin `claude/siege-survival` | waiting: S7 | — | — | — |
| S9 | Phase 6 authoring, UX, telemetry | web app, API, plugin `claude/siege-survival` | waiting: web building blocks (#95, #33, #187, #30, #39) or waiver; S1–S8 | — | — | — |

## Coordinator notes

- 2026-11-03: chain started. Gate check above; S1 and S2 started in parallel (separate packages). S2 merges S1's pushed
  work into `claude/siege-survival` before its final push. Both links may add their package name to
  `knk-core/src/test/.../core/ArchitectureGuardTest.java` `BUKKIT_FREE_PACKAGES` (S1 `"survival"` after `"catalog"`,
  S2 `"npc"` before `"roads"`) so the guard covers the new packages; no other existing file is touched.
- Toolchain note for plugin links: `openjdk-25-jdk-headless` installs from apt on the cloud image (Ubuntu 24.04);
  Gradle 8.14 runs on the image's JDK 21 and finds the toolchain with
  `-Porg.gradle.java.installations.paths=/usr/lib/jvm/java-25-openjdk-amd64`.

## Link blocks

(Each link appends its block here: scope done, commits per repo, tests baseline → result, deviations, flags, checklist
location, notes for later links.)

## Link S2 — NPC platform §5b core (2026-11-03)

**Status:** in review (pushed; core-only, no live checklist). **Branch:** knk-plugin `claude/siege-survival` (created from
`main` `306937f5`), head `8cf2761e`. **Issues:** PandiO/knk-workspace#146, #41.

**Scope done** — new package `knk-core/src/main/java/net/knightsandkings/knk/core/npc/` (Bukkit-free, guarded) and tests
under `knk-core/src/test/java/.../core/npc/`:

- `npc/NpcStat` — the six stats (`melee-cooldown-ticks`, `melee-damage`, `ranged-cooldown-ticks`, `ranged-draw-ticks`,
  `projectile-damage`, `movement-speed`) plus `NpcStat.named(id)` for a consumer's own stat on the same pipeline.
- `npc/Bound`, `StatBounds`, `ClampReport`, `ResolvedStat` — named limits (floor, ceiling, optional advisory comfort limit),
  the clamp report (stat, from, to, bound, applied) and the per-stat result (base, unclamped, value, reports).
- `npc/profile/CombatProfile` — melee cooldown, melee damage, ranged cooldown, draw, projectile damage, per-target overrides
  (`TargetOverride` keyed by `TargetTypes` strings: player, objective, gate, …), per-stat bounds; `forTarget(type)`.
- `npc/profile/SpeedProfile` — base speed, comfort limit, hard cap, string-keyed terrain/movement-profile factors.
- `npc/profile/VanillaProfiles` — code defaults per vanilla type (`zombie`, `skeleton`, `creeper`, `spider`, `default`).
- `npc/profile/ProfileOverrides` — flat `profileId → (key → value)` override model (no YAML; `Number`/`String` values,
  `"vanilla"` resets a damage field, `based-on` creates a new profile); bad keys/values are rejected with a reason, never thrown.
- `npc/profile/ProfileRegistry` — effective profiles (defaults + overrides), unknown ids fall back to `default`; immutable,
  swapped on reload.
- `npc/modifier/StatModifier`, `ModifierOp`, `ModifierSet`, `ActorModifiers` — ADD/MULTIPLY modifiers keyed by source
  (`survival:round`, `survival:per-player`, `effect:slowness`, …), one per (source, stat); per-actor set with a revision
  counter; registry by actor UUID with `putAll(actors, mods)` and `removeSource(source)`.
- `npc/resolve/StatResolver`, `ResolvedCombat`, `ResolvedSpeed`, `VanillaBases` — the resolver (order below), the five
  combat stats and the speed as one result each, and the live engine damages an adapter passes for vanilla damage.
- `npc/cooldown/CooldownTracker`, `CooldownJitter` — "ready at tick" per actor and channel (`melee`, `ranged`, any string)
  with injected ticks; jitter flag off by default.
- `npc/NpcStatPipeline` — the facade: `resolveCombat(actor, profileId, targetType, bases)`, `resolveSpeed(actor,
  profileId, factorKeys)`, `resolveNamed(...)`, `tryMelee` / `tryShot`, `modifiers()`, `cooldowns()`, `reloadProfiles()`,
  `revision(actor)`, `forget(actor)`.
- `ArchitectureGuardTest`: `"npc"` added to `BUKKIT_FREE_PACKAGES` before `"roads"` (the only existing file changed).

**Commits** (knk-plugin `claude/siege-survival`): `662689bc` stats, bounds, profiles · `8517d844` modifier pipeline,
resolver, cooldowns, facade · `8cf2761e` tests and guard entry.

**Tests** (`./gradlew build -x deployToDevServer`, JDK 25 toolchain): baseline → result — knk-core 2433 → 2494
(+61, 0 failures), knk-api-client 288 (2 skipped) → 288, knk-paper 2385 (18 skipped) → 2385; build green.
(Maven Central answered 429 through the proxy on the first baseline attempts; cleared on retry.)

**Deviations:** none from the design. Damage values are not fixed by the code defaults: the checks report gives no
damage numbers, so every vanilla profile leaves `meleeDamage` / `projectileDamage` empty ("vanilla") and the adapter
supplies the live engine value (`ATTACK_DAMAGE`, arrow damage) as the base through `VanillaBases`; the pipeline scales and
clamps it. Health is not in the pipeline (stays an attribute set by the adapter, as agreed).

**Flags for the developer (defaults chosen in S2, all configurable):**
- S2-1 Melee cooldown floor **10 ticks** (`melee-cooldown-floor`), per §5b and checks §4; default 20.
- S2-2 Ranged cooldown floor **20 ticks** (`ranged-cooldown-floor`, the vanilla Hard minimum); default 40. Draw floor
  **1 tick**, default 20, and a cross-stat rule caps the draw at the resolved ranged cooldown
  (`ranged-draw-within-cooldown`, reported). Damage floors 0, no ceilings by default (config may add them).
- S2-3 Resolution order: `(base + Σ additions) × Π multipliers`; tick stats are rounded (half to even) to whole ticks
  before bounds; then floor, ceiling, comfort advisory. For speed the terrain factors multiply the base before the
  additions. A non-finite result falls back to the floor (or 0) and is reported under `non-finite-value`.
- S2-4 Speed defaults: zombie 0.23, skeleton/creeper 0.25, spider 0.3, `default` = zombie; comfort limit **0.4**
  (advisory report, not a clamp) and hard cap **0.5** (clamp), per profile, to be measured live (checks §10).
- S2-5 Unknown profile ids resolve to the `default` profile (vanilla timings, zombie speed) instead of failing, so a new
  mob type works before it is configured.
- S2-6 Override model keys (`combat.*`, `speed.*`, `combat.targets.<type>.<field>`, `combat.bounds.<stat>.floor|ceiling`,
  `speed.factors.<key>`, `based-on`) — proposed config.yml shape for the link that wires config; rejected entries are
  returned as a list for a startup warning. Config location is still open in the design.
- S2-7 Cooldown jitter: a `CooldownJitter(enabled, maxFraction)` flag, **off by default**, fraction 0.1; when on it only
  lengthens a cooldown by up to the fraction (never shortens, so the floors hold).
- S2-8 Actor id is `java.util.UUID` (entity UUID; works for vanilla mobs and Citizens NPCs).

**Follow-ups found (not fixed):**
- Vanilla melee/projectile damage per type is not recorded anywhere in the docs; the live bases cover it, but a table
  (zombie 3, skeleton melee 2, spider 2, arrow by power) in the checks report would let config override with numbers.
- Config wiring (reading `npc.profiles` from config.yml into `ProfileOverrides`, a reload command, logging the rejected
  list) is not part of S2 or S5 in plan §2a; needs an owner (S5 or a small link).

**Notes for later links:**
- S5 adapters: hold one `NpcStatPipeline` (built from `ProfileRegistry.vanilla()` or `withOverrides(...)`). In the
  custom attack goal, per attack: `ResolvedCombat c = pipeline.resolveCombat(mob.getUniqueId(), profileId, targetType,
  VanillaBases.melee(mob attack damage))`, then `if (pipeline.tryMelee(id, currentTick, c)) { swing; attack with
  c.meleeDamageValue() }`; the ranged goal uses `c.drawTicks()`, `pipeline.tryShot(...)` and sets the arrow damage to
  `resolveCombat(..., VanillaBases.projectile(arrowDamage)).projectileDamageValue()` in the shoot event. Speed: on spawn
  and whenever `pipeline.revision(id)` changed, `ResolvedSpeed s = pipeline.resolveSpeed(id, profileId, factorKeys)` and
  apply an `AttributeModifier` (or set the base) to `s.value()`; log `s.reports()` / `c.reports()` once per revision
  (`ClampReport.describe()`). Call `pipeline.forget(id)` on death/despawn. The profile id is the lower-cased entity type
  name unless the consumer assigns one.
- Survival (S5/S8): at round start compute the per-stat multipliers (DESIGN §7, S54/S55) and put them with
  `pipeline.modifiers().putAll(liveEnemies, List.of(StatModifier.multiply("survival:round", NpcStat.MELEE_DAMAGE, m),
  ... MOVEMENT_SPEED ..., MELEE_COOLDOWN with 1/attackSpeedMultiplier, ...))` and likewise `"survival:per-player"`; new
  spawns get the same list via `forActor(id).putAll(...)`. The stat cap of S29 is a modifier the consumer caps itself;
  the platform's floors/caps still apply after it. Never touch health through the pipeline.
