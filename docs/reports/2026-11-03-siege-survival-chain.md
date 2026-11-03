# Siege Survival implementation chain — progress report

**Status:** S1 and S2 in review (pushed 2026-11-03, knk-plugin `claude/siege-survival` `b5f86586`, core only, no live test); chain paused — G1, S3 and S4 wait for merges (see "Waiting for the developer")
**Last updated:** 2026-11-03 (coordinator: S1/S2 verified, chain paused)
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

- **S1 and S2 are in review, nothing to live-test.** Both are core-only (knk-core, Bukkit-free, unit tests): knk-plugin
  `claude/siege-survival` `b5f86586` (S1 commits `7c460647`, `a0425700`, `ba074b8c`; S2 commits `662689bc`, `8517d844`,
  `8cf2761e`; S1 merged S2 before its push). Coordinator verification build on `b5f86586`: knk-core 2433 → 2595 tests
  (0 failed), knk-api-client 288 (2 skipped) and knk-paper 2385 (18 skipped) unchanged, build green; scope check: only
  `core/survival/`, `core/npc/` and the two guard entries, no `org.bukkit` reference, no dependency between the two
  packages. The developer can read the two blocks' flags and either merge the branch into plugin `main` now (no
  behaviour change for existing modes: new packages only) or leave it in review until S3–S5 join it.
- **Chain paused (2026-11-03):** no further link has an open gate. S5 needs S3 and S4 on the branch first; everything
  else waits for the merges below.
- **Merges that open the next gates**, in the suggested order (each branch is ahead of its trunk, see the gate check below):
  1. #167 `claude/alpha-run-1-gates` (plugin, API, web app) — with #180 it opens **S4**; with #213 and realtime it opens **G1**.
  2. #213 `claude/siege-pregame-gate-view` (plugin only) — needed by **G1** and **S3**.
  3. #180 `claude/world-task-hardening` (plugin, API, web app) — with #167 it opens **S4** (migrations).
  4. `claude/realtime-signalr` (plugin, API, web app; contains link 7 = `claude/world-task-hardening`; `realtime.enabled`
     off by default — check which link 10 changes act with the flag off before merging without the SignalR checklists) —
     needed by **G1** and **S3** (`GateManager`, gate services, Siege files). **Flag-off check done (coordinator,
     2026-11-03, read-only audit of plugin `8fa35148..eb22a655` and API `a27f61e..e769c4c`):** the plugin flag is
     `realtime.enabled: false` (`knk-paper/src/main/resources/config.yml`, `paper/realtime/RealtimeSettings`); with it off
     `RealtimeService.start()` only logs and never connects. **The API has no enable flag** (`Realtime` options are
     capacity, presence grace and allowed server ids; hubs are mapped unconditionally since link 4). Link 10 changes that
     still act with the flag off: the EF `RealtimeEntityChangeInterceptor` runs on every `SaveChanges` (CPU/alloc only,
     try/catch, no DB writes; a "Realtime queue full" warning is possible during bulk writes with nobody subscribed);
     `GateDoorService.Clear*BlockSnapshotsAsync` does one extra read; the plugin installs `GateRealtimeSync`/config-sync
     hooks that are no-ops while disconnected, `SiegeGateController.roundReleased` schedules a main-thread hook call, and
     the throttled timers keep their intervals. Everything else (entity-change router, cache invalidation, gate reloads,
     `ReportWorlds`, startup-work resync) is inert. No migration, no new endpoint, no new config key in link 10; the branch
     contains link 7 in all three repos (its migration ships with this merge). Caveat: the web app's `RealtimeProvider`
     (link 8) still opens `/api/hubs/web` for logged-in users, so "flag off" is plugin-only. Smallest non-SignalR check
     set before merging flag-off: API tests; one ordinary entity save and one bulk write watching the API log for
     "realtime entity changes failed" / "Realtime queue full"; plugin tests and one dev-server start with the flag off
     ("Realtime channel disabled" log line, timers still fire) plus one siege round start/end; link 7's own checklist.
  5. Arena-duels decision: merge `claude/arena-duels` or catch it up with `main` (plugin is 23 ahead / 40 behind) —
     needed by **S3**.
  6. Web building blocks (#95 `claude/design-tokens…`, #39 rest `claude/entity-lists-url-state`, #33, #187, #30) or a
     developer waiver — needed by **S9** (last link; also depends on S1–S8).
- **Flags needing a decision:** S1-6 (round 1 with per-player stat scaling on), S1-9 (special-wave count override vs
  per-player scaling), S1-10 (near-players slider at 100 %), S1-14 (transfers to ghosts rejected) — see the S1 block; the
  rest of S1-1 … S1-19 and S2-1 … S2-8 (floors, caps, resolution order, jitter flag, override keys; see the S2 block) are
  defaults and tolerances to confirm.

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
| S1 | Survival core logic (waves, kills, round delay, stuck rules, end conditions, scaling presets, monster mix, specials, repair maths, spawn selection, rewards, Mystery Box pick) | plugin `claude/siege-survival`, `knk-core/.../core/survival/` only | in review | create_session session_01R1w2UvKtghxZowkQBTRYqG, 2026-11-03 | plugin `b5f86586` (merge of S1 + S2's `8cf2761e`) / — / — / workspace `main` (this report; bookkeeping applied by the coordinator from S1's patch) | knk-core 2433 → 2595 (S1 +101, S2 +61), 0 failed; api-client 288 and paper 2385 unchanged |
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

- 2026-11-03 (chain pause): S1 and S2 checked and in review; follow-ups filed as [#219](https://github.com/PandiO/knk-workspace/issues/219)
  (wire `npc.profiles` config into `ProfileOverrides`, from S2) and [#220](https://github.com/PandiO/knk-workspace/issues/220)
  (shared double-weighted picker, from S1); S2's vanilla-damage-table note is a comment on #146. S1's workspace bookkeeping
  (its block, Summary row, tracker status) came in as a patch (the link session could attach knk-workspace read-only but not
  push) and was applied by the coordinator; the #41 comment for S1 was posted by the coordinator. Baseline Maven Central
  downloads hit HTTP 429 through the proxy several times; `--max-workers=1` with
  `-Dorg.gradle.internal.repository.max.tentatives=12 -Dorg.gradle.internal.repository.initial.backoff=4000` got through.
- Next coordinator run: re-run the gate check; start G1 (`claude/gate-animated-rebuild`, from the trunks) as soon as #167,
  #213 and realtime are merged, S4 as soon as #167 and #180 are merged, S3 as soon as realtime, #213 and the arena-duels
  decision are in; then S5 (first live checkpoint), S6–S8 batched into one checklist, S9 last.

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

## Link S1 — survival core (2026-11-03)

**Session:** `session_01R1w2UvKtghxZowkQBTRYqG` (create_session). **Repo:** knk-plugin `claude/siege-survival`, created from
`main` `306937f5`; link S2 pushed first, its three commits were merged (not rebased) before the final push.
**Head pushed:** `b5f86586` (merge of S1 + S2). **Base of S1's work:** `306937f5`.

### Scope done

Package `knk-core/src/main/java/net/knightsandkings/knk/core/survival/` (Bukkit-free, pure Java 25; time passed in as
milliseconds, randomness as `java.util.random.RandomGenerator`), tests under `knk-core/src/test/.../core/survival/`:

- `survival/` — `SurvivalSubstate` (PREPARING, WAVE_ACTIVE, INTERMISSION, ENDING: design names only; the Siege enums are
  untouched), `SurvivalPoint` (a Bukkit-free position), `ReadinessIssue` (error/warning with a stable code).
- `survival/wave/` — `PlannedEnemy` (match-unique id, round, monster type, special flag); `KillCause` (PLAYER earned;
  SYSTEM, ENVIRONMENT, NPC not); `RoundSpawnQueue` (planned queue, alive set, max-alive pacing, round complete only when
  the queue is exhausted AND nothing is alive, earned vs system kills, cancel remaining spawns, last-planned-spawn time);
  `WaveRecord` (reached vs completed: wipe in wave 10 = reached 10 / completed 9); `Intermission` (S27, default 10 s);
  `SurvivalRounds` (the substate lifecycle; `deathsCountTowardWipe()` only in WAVE_ACTIVE, S41).
- `survival/stuck/` — `StuckSettings` (N 30 s, K 3, R 2, T 5 min or off, meaningful distance 1.0 block);
  `ProgressSample`; `StuckMonitor` (per-enemy stuck detection → `StuckDecision.Respawn` of the same planned enemy,
  respawn-limit → `SystemKill`, last-enemies glow + direct pursuit flagged once, round backstop fired once);
  `StuckEvent` + `StuckTelemetrySink` (STUCK_RESPAWN, GLOW, RESPAWN_LIMIT_KILL, BACKSTOP_KILL with enemy id, round, last
  position, target, respawn count).
- `survival/end/` — `SurvivalEndReason` (TEAM_WIPE, INSTA_LOSE_OBJECTIVE_CAPTURED, ALL_OBJECTIVES_CAPTURED,
  NO_PLAYERS_LEFT, ADMIN_ABORT, SERVER_RESTART, TECHNICAL_LIMIT; `settlesRewards()`); `AllCapturedOverride`
  (INHERIT/ON/OFF resolved lobby → scenario, S46); `EndConditionSettings`; `SurvivalObjective`; `EndConditionSnapshot`;
  `EndConditionEvaluator` (precedence S47, leavers are not players S37, readiness warning `end.wipe-only`).
- `survival/scaling/` — `ScalingPreset`, `ScalingCurve` (the §7 formulas; `asStatCurve()` forces b = 1), `ScaledStat`
  (health, walking speed, melee damage, ranged damage, attack speed), `StatWeights` (S54), `PerPlayerScaling` (S55),
  `WaveScalingSettings` (+ readiness), `WaveScaling` (count floor ≥ 1 with cap; `1 + w·(curve(r) − 1)`, optional
  per-player factor, stat cap last), `RoundPreview` (editor preview per round), `WalkingSpeedLimit` (0.4 recommended /
  0.5 hard cap effective speed, checks report §10).
- `survival/spawn/` — `MonsterType` (weight, unlock round), `MonsterMix` (S56, readiness), `SpecialWaveEntry`
  (Recurring/Explicit), `SpecialWaveProfile` (replacing by default, additive explicit), `SpecialWaveSchedule`
  (explicit beats recurring; conflicting recurring entries need unique priorities), `WavePopulationPlanner`,
  `EnemyIdSequence`, `PrerequisitePolicy` (ALL/ANY), `SpawnZone`, `SpawnFrontier` (ownership-driven; latched without
  recapture; re-evaluated with recapture, S63), `SpawnZoneSelector` (favor-near-players slider S50; nearest-zone pick
  for stuck respawns; readiness), `WeightedPick` (package-private double-weighted copy, no shared file changed).
- `survival/repair/` — `DoorRepairWork` (`P(t+dt) = min(target, P + r·n·dt)`, ETA, hold with zero contributors,
  completion consumed once, damaged standing doors with the missing health recomputed live S49, carry-over on
  destruction mid-repair, full-health doors not repairable, stop + invalidate only on objective loss S48),
  `RepairCompletion` (REBUILD_DESTROYED_DOOR / RESTORE_DAMAGED_DOOR).
- `survival/economy/` — `KillRewardSettings` (30 / 3 / 70 / ×1.1; `fromCaptureRewards(÷10)`), `EnemyKill`,
  `KillReward`, `KillRewardCalculator`, `PermanentRewardAccrual` (exact tenths, rounded down once at settlement,
  leavers forfeit), `MatchLedger` + `LedgerResult` (balances from 0, atomic transfers, fixed-price charges, idempotent
  by retry id, no overdraft, same match only, ghosts on neither side).
- `survival/mysterybox/` — `BasisPoints` (percent ↔ bp, 0.01 % precision), `MysteryBoxVariant`, `MysteryBoxEntry`
  (ItemEntry with independent `EnchantmentChance`s / BookEntry), `MysteryBoxPool` (validation "exactly 100 %" as an
  integer check, references, variant; deterministic `pick`), `MysteryBoxRoll`, `MysteryBoxSettings` (1000, 10 s).
- `knk-core/src/test/.../core/ArchitectureGuardTest.java`: `"survival"` added after `"catalog"` (S2's `"npc"` merged
  cleanly before `"roads"`).

### Commits (knk-plugin `claude/siege-survival`)

- `7c460647` wave queue, kill accounting, intermission, stuck rules, end conditions, guard entry
- `a0425700` scaling presets, monster mix, special waves, spawnzone selection
- `ba074b8c` repair-work maths, per-kill rewards, match ledger, Mystery Box pool
- `b5f86586` merge of `origin/claude/siege-survival` (S2's `662689bc`, `8517d844`, `8cf2761e`)

### Tests (`./gradlew build -x deployToDevServer`, JDK 25 toolchain)

| Module | Baseline (`306937f5`) | Result (`b5f86586`, S1 + S2) |
|---|---|---|
| knk-core | 2433, 0 failed, 0 skipped | 2595, 0 failed, 0 skipped (S1 adds 101 tests in 17 classes; the rest are S2's) |
| knk-api-client | 288, 0 failed, 2 skipped | 288, 0 failed, 2 skipped (unchanged) |
| knk-paper | 2385, 0 failed, 18 skipped | 2385, 0 failed, 18 skipped (unchanged) |

### Deviations

- **Workspace report-back could not be pushed from the link session.** `add_repo` for knk-workspace was refused by the
  session's permission classifier; the clone worked read-only through the git proxy, but `git push` to
  `PandiO/knk-workspace` is denied ("not in this session's authorized repository set"). This block, the Summary row
  and the tracker row were committed locally on `main` on top of `origin/main` `4fbd1a6` and exported as a patch
  (`0001-*.patch` in the session's scratchpad, see the final message); the coordinator applies/pushes it.
- **To file (coordinator):** the short comment on PandiO/knk-workspace#41 (link S1 pushed, head, test counts, link to
  this block) — the GitHub tools of this session are scoped to `PandiO/knk-plugin` only.
- The baseline build ran with three trivial new main files already present (`package-info`, `SurvivalSubstate`,
  `SurvivalPoint`, no tests); the counts equal the branch head's.
- Design S65 (sneak repair input), §5b adapters, the Paper side of ghost state and everything with a world are out of
  S1 by plan; nothing was built for them.

### Flags for the developer (interpretations, defaults, tolerances)

- **S1-1** Stuck "meaningful reduction of the distance" = at least `meaningfulDistance` blocks closer than the best
  distance since the baseline (default 1.0, `StuckSettings`). Also configurable; not a design value.
- **S1-2** A target change is *not* progress for the stuck check: it only resets the distance baseline, so an enemy
  flipping targets while stuck stays stuck. Damage dealt/taken and a meaningful distance reduction are progress;
  "navigation blocked" never is.
- **S1-3** Glow and direct pursuit are one flag (`StuckMonitor.isGlowing`/`pursuesDirectly`), set once per enemy and
  only cleared when the enemy dies; the GLOW telemetry event fires once per enemy.
- **S1-4** `StuckMonitor` is per round (one per `RoundSpawnQueue`); the backstop fires at most once per round and
  system-kills everything alive at that moment.
- **S1-5** End conditions are evaluated on state after each change: any insta-lose objective NPC-held ends the game;
  "all captured" = every objective NPC-held at evaluation (so with recapture, a retaken objective means "not all").
  NO_PLAYERS_LEFT is checked before the wipe (nothing to settle); all-captured with zero objectives never ends and
  readiness warns (`end.all-captured-unreachable`).
- **S1-6** Per-player scaling of the stats (S55, optional, default off) multiplies on top of the curve, so with it on
  and 2+ players the round-1 multiplier is `1 + p·(players − 1)`, not 1. The curve part is exactly 1 in round 1 for
  every preset (b forced to 1). If round 1 must stay vanilla regardless, S5 should skip the per-player factor in round 1.
- **S1-7** Stat cap is applied last (after weight and per-player factor); a negative multiplier is clamped at 0; the
  count is floored and never below 1 even for a shrinking curve; count cap 0 / max alive 0 = unlimited.
- **S1-8** Special-wave priority: the *lowest* value wins among conflicting recurring entries (priority 1 beats 2).
  "Every n" = waves n, 2n, 3n… (`Recurring.every`); a general entry is interval + start wave. Conflict = the two
  entries can hit a common wave (offsets agree modulo gcd of the intervals). Two explicit entries for one wave with
  different profiles fail readiness; with the same profile they are tolerated.
- **S1-9** `SpecialWaveProfile`: an empty mix means "the scenario's normal mix"; count = `countOverride` if set, else
  `floor(normalCount × countMultiplier)`, never below 1. An explicit `countOverride` ignores per-player scaling (the
  design does not say). Additive profiles are appended after the normal composition in the spawn order.
- **S1-10** Near-players slider: the "nearest active zones" are the `nearZoneCount` (default 1) active zones closest
  to any living player; the slider's share goes to that set, the rest to the other active zones, each drawn by zone
  weight. With no living player position (all ghosts) or no "other" zones it is weight only. At 100 % the far zones
  get no spawns while they are far (they stay active and re-enter the near set as players move); if the developer
  wants a hard "never exclusive", cap the slider in the editor (e.g. 90 %).
- **S1-11** Spawn frontier: without recapture, an activated zone stays active (latched); with recapture, initial zones
  (no prerequisite) never deactivate. The frontier has no door input at all, so a breach cannot activate anything.
- **S1-12** Repair: regaining the objective (recapture) starts a new cycle from zero. A damaged-door completion sets
  the model to full health immediately (the adapter applies it to the door); a destroyed-door completion waits for
  `rebuildComplete()` (no second completion until then). Repair rate `r` is a constructor value per door (the
  difficulty profile supplies it).
- **S1-13** Match currency per kill is a whole amount rounded down per credit (70 × 1.1 = 77; a configured 75 × 1.1 =
  82). Coins and XP stay exact (`BigDecimal`) and are rounded down once per player at settlement (3 headshot kills =
  9.9 XP → 9).
- **S1-14** Ledger: transfers to a ghost are rejected (`RECIPIENT_IS_GHOST`, reading S20's "receive-and-use" strictly);
  a retry with the same id and the same request replays the first accepted result; a rejected request may be retried
  with the same id; the same id with a different request is `RETRY_ID_CONFLICT`; leaving drops the balance; after
  `end()` only reads remain. The ledger knows ghosts through `setGhost`, which the adapter keeps current.
- **S1-15** Mystery Box chances are integer basis points (1 % = 100 bp): "exactly 100 %" is `total == 10000`.
  Percent inputs are accepted at 0.01 % precision and rejected otherwise (so a pool cannot drift); an entry needs at
  least 0.01 %. Enchantment chances per item entry are independent hits (1..10000 bp, need not add up), duplicate
  enchantment ids per entry fail. The pick is one weighted draw; reel decoys are further picks with the same odds.
- **S1-16** `KillRewardSettings.fromCaptureRewards` divides exactly (305 → 30.5 coins); defaults 30 / 3 / 70 / 1.1.
- **S1-17** Intermission default 10 000 ms; `remainingSecondsCeil` for the countdown.
- **S1-18** `WalkingSpeedLimit` (0.4 recommended, 0.5 hard cap effective speed) is a readiness helper only; the NPC
  platform (S2) clamps at runtime.
- **S1-19** Readiness codes are stable strings (`end.*`, `scaling.*`, `mix.*`, `special.*`, `spawn.*`, `box.*`);
  S4/S9 can map them to messages.

### Follow-ups found (not fixed; the coordinator files issues)

- A shared double-weighted picker in `core/util` would replace `survival/spawn/WeightedPick` (and `siege/WeightedPicker`'s
  int weights) once the shared-file freeze of the chain is over.
- The design leaves open whether an explicit special-wave `countOverride` scales with players (S1-9) and whether
  round 1 stays vanilla with per-player stat scaling on (S1-6).
- `LootboxReel.plan` takes `Weighted<T>(value, double weight)`: `MysteryBoxEntry.basisPoints()` can feed it directly
  for the in-world reel (S7); no adapter needed in core.

### Notes for later links

- **S5 (runtime):** per round: `WavePopulationPlanner.plan(round, playersAtRoundStart, ids, random)` →
  `SurvivalRounds.startWave(planned, maxAlive)`; spawn loop: `queue.nextSpawn(now)` while `canSpawn()`, zone via
  `SpawnZoneSelector.select(frontier.activeZones(), livingPlayerPositions, random)`; on death
  `queue.recordDeath(id, cause)` + `StuckMonitor.forget(id)`; reward: `KillRewardCalculator.reward(EnemyKill)` →
  `MatchLedger.credit` + `PermanentRewardAccrual.add`; stuck: one `StuckMonitor` per round, `track` on every spawn and
  respawn, `report` per check (e.g. every 20 ticks), `lastEnemies(queue.isQueueExhausted(), queue.aliveIds(), now)`,
  `backstop(queue.lastPlannedSpawnMillis() as OptionalLong, queue.aliveIds(), now)` → `recordDeath(id, SYSTEM)`;
  respawn zone via `selectNearestPlayers`; after each change `EndConditionEvaluator.evaluate(snapshot)` →
  `rounds.end()`, `ledger.end()`, and `accrual.settle(members)` only when `reason.settlesRewards()`;
  `rounds.completeWaveIfDone(now)` / `intermissionOver(now)` drive the break; ownership changes →
  `SpawnFrontier.update(npcHeld)` and `DoorRepairWork.objectiveOwnershipChanged`.
- **S2's pipeline:** `WaveScaling.statMultipliers(round, players)` gives `Map<ScaledStat, Double>` (HEALTH,
  WALKING_SPEED, MELEE_DAMAGE, RANGED_DAMAGE, ATTACK_SPEED), round 1 = 1.0. S5 feeds them as the `survival:round`
  source; if S2 wants the per-player part as its own `survival:per-player` source, keep `PerPlayerScaling.applyToStats`
  off in `WaveScalingSettings` and pass `PerPlayerScaling.multiplier(players)` separately. Attack speed and walking
  speed stay multipliers here; S2 owns cooldown bounds and the speed clamp.
- **S6 (repairs):** one `DoorRepairWork` per door (`maxHealth`, difficulty `rate`, current health); each tick
  `advance(validRepairers, dtSeconds)`; `doorHealthChanged` on damage, `doorDestroyed`, `rebuildComplete` after the
  animated rebuild; `etaSeconds(n)` / `fraction()` for the boss bar.
- **S7 (economy, Mystery Box):** `MatchLedger.charge(new ChargeRequest(rollId, matchId, player, price, "mystery-box"))`
  before the roll (the roll id is the retry id); `MysteryBoxPool.validate(blueprintExists, enchantmentExists)` in
  readiness; `pick(random)` for the result and the reel's passing items; `MysteryBoxSettings.claimTimeoutMillis`.
- **S8 (results, settlement):** `WaveRecord` (reached/completed), `SurvivalEndReason`, `PermanentRewardAccrual.settle`,
  `RoundSpawnQueue.earnedKills()/systemKills()`, `StuckEvent` log via a `StuckTelemetrySink`.
- **S4/S9 (contracts, authoring):** the settings records to map from the API: `StuckSettings`, `EndConditionSettings`
  + `AllCapturedOverride`, `WaveScalingSettings` (two `ScalingCurve`s, `StatWeights`, `PerPlayerScaling`, max alive,
  stat cap, count cap), `MonsterType` list, `SpecialWaveEntry`/`SpecialWaveProfile`, `SpawnZone`, `KillRewardSettings`,
  `MysteryBoxSettings`, `MysteryBoxPool`, intermission millis, slider + near-zone count, recapture flag, repair rate.
  `WaveScaling.preview(from, to, players)` is the editor's per-round preview (§11).
