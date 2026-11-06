# Siege Survival implementation chain — progress report

**Status:** S1, S2, S3 and S4 (+ migration) in review; **S5 running** (phase 2 runtime slice, the first live checkpoint; started 2026-11-06); G1 waits for #167 and #213
**Last updated:** 2026-11-06 (coordinator: S3 verified, S5 started)
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

- **S3 is in review (2026-11-06), regression checklist ready:** knk-plugin `claude/siege-survival` `6b80638e`. Coordinator
  verification build: knk-core 2638 → 2663, knk-paper 2504 → 2535, knk-api-client 330 unchanged, 0 failures; scope check: 20 new
  files, 15 existing files edited, shared-file hunks exactly as S3 listed (`SiegeGateController.java` 3 additive, `KnKPlugin.java`
  5 small), nothing in the gate pass-through/view, api-client, `core/survival` or `core/npc` files. **The one-match PvP regression
  checklist** (6 steps, one sitting) is in the S3 block; it can be run together with S5's live checkpoint on the same deploy.
  Flags S3-1 … S3-15 (S3-1 staff vanish does not reveal ghosts; S3-11 rebuilt doors start OPEN at the last frame) need no decision
  before S5. Follow-ups filed: [#267](https://github.com/PandiO/knk-workspace/issues/267) (gate damage per cause as config keys),
  [#268](https://github.com/PandiO/knk-workspace/issues/268) (NPC team as last capturer in the siege menus).
- **S5 started 2026-11-06** (session_01R1w2UuecHgiqgXCbskAjGT): the runtime slice on the plugin branch plus the live checklist
  `docs/guides/siege-survival-smoke-test.md` (workspace branch `claude/siege-survival`), written so one sitting covers deploy
  (API `f87457b` with the migration + seeds, plugin jar), authoring a minimal castle scenario without the web app, one wave, a
  breach, a capture, the ghost rules, a team-wipe end, and the S3 PvP regression steps.
- **2026-11-06 — continuing on the feature branch (developer's request).** The developer asked to keep implementing instead
  of waiting for #167/#213/arena-duels. What changed: (1) **the `AddSiegeSurvivalPhase1` migration is on the API branch**
  (coordinator; 18 `siege_survival_*` tables, 35 indexes, nothing else; `has-pending-model-changes` clean; tests 3779/0/88).
  Its parent is the current `master` head, so **if #167 merges first, merging `master` into `claude/siege-survival` conflicts in
  the model snapshot: resolve by `dotnet ef migrations remove` + `add` on the merged branch** (a 10-minute step, no database has
  the migration yet). (2) **S3 started** on the plugin branch although #213 and arena-duels are unmerged: the only shared
  files are `SiegeGateController.java` (#213) and `KnKPlugin.java` (both); S3 keeps its hunks there small and additive and
  lists them, so the later merge is mechanical. (3) S5 follows S3 on the same branch; the chain's live checkpoint (one wave, a
  breach, a capture) then needs the API branch deployed with its migration — nothing from these branches is deployed, so
  the linear-migration rule holds in production. Merging #167 and #213 is still the cleanest way to reduce conflict work.
- **S4 is in review (2026-11-05), nothing to live-test:** knk-web-api `claude/siege-survival` `043bd2a` and knk-plugin
  `claude/siege-survival` `699d1889`. Coordinator verification: API 3659 → 3779 passed (0 failed, 88 skipped, baseline run on
  `master` `2e3dfeb`); plugin build green (knk-api-client 321 → 330, knk-core 2638 and knk-paper 2504 unchanged). Scope check: 45
  new API files, 4 existing files edited (`KnKDbContext.cs`, DI, seeds README, one seed test), `Migrations/` untouched; plugin
  only `knk-api-client` (+ `KnkApiClient` wiring). Flags S4-1 … S4-18 (modelling choices and balance placeholder defaults) in the
  S4 block; none needs a decision before S5, but S4-7 (profile defaults) and S4-8 (near-players slider default 0) are worth a
  look. Follow-up filed: [#265](https://github.com/PandiO/knk-workspace/issues/265) (survival scenarios in the lobby runtime
  config, survival flag on `SiegeRuntimeScenarioDto`).
- **What opens the next step:** merge **#167** `claude/alpha-run-1-gates` (clean in all three repos). Then the coordinator adds the
  one additive migration `AddSiegeSurvivalPhase1` on the API branch (checklist in the S4 block, Deviations). **S3** needs #213 and
  the arena-duels decision; **S5** needs S3; **S7** has its plan gate (S4) open, but its API half (match-scoped Mystery Box roll
  endpoint, one roll/one delivery rows) needs a migration (same #167 wait) and its plugin half attaches to the survival match
  runtime that S5 builds, so the coordinator holds S7 until S5 exists unless the developer says otherwise. **G1** needs #167,
  #213 (and realtime, merged).
- **2026-11-05 gate re-check** (plugin `main` `33122cf4`, API `master` `2e3dfeb`, web app `main` `a7b231d`): #180
  `claude/world-task-hardening` and `claude/realtime-signalr` are **merged** in all repos (0 ahead). Still open: #167
  `claude/alpha-run-1-gates` (1 commit per repo, in review since 2026-10-27; **trial merge into every trunk: 0 conflicts**),
  #213 `claude/siege-pregame-gate-view` (plugin 5 ahead / 25 behind, conflicts with plugin `main` in `knk-paper/build.gradle.kts`
  and `KnKPlugin.java`; API and web app stack on #167), `claude/arena-duels` (plugin 23 ahead / 71 behind). So **G1 and S3 stay
  closed**; **S4's gate is half open** (#180 yes, #167 no).
- **S4 started 2026-11-05 at the developer's request** ("start the next link") with one coordinator deviation: **no migration in
  S4**. The S4 gate exists to keep the EF migration chain linear behind #167's `20261027150000_AddGatePassThroughStyles`; S4
  therefore adds entities, DbContext mapping, DTOs, services, controllers, readiness, form seeds and api-client DTOs, and the
  one additive migration (`dotnet ef migrations add AddSiegeSurvivalPhase1`) is a small coordinator step **right after #167
  merges**. Until then a database has no survival tables (API tests use the InMemory provider). **Merging #167 is now the one
  merge that unblocks the chain's next steps** (S4 migration, then S5 once S3 is done); #213 and the arena-duels decision open S3 and G1.
- **Branch update 2026-11-05:** `origin/main` merged into knk-plugin `claude/siege-survival` (`34c7bf70`; one conflict in
  `ArchitectureGuardTest` — main added `"realtime"` to the Bukkit-free packages, both entries kept). Build green: knk-core 2638,
  knk-api-client 321 (2 skipped), knk-paper 2504 (18 skipped), 0 failures.
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

Re-check 2026-11-05 (plugin `main` `33122cf4`, API `master` `2e3dfeb`, web app `main` `a7b231d`): `claude/world-task-hardening` 0/0/0 ahead
(merged), `claude/realtime-signalr` 0/0/0 ahead (merged), `claude/alpha-run-1-gates` still 1/1/1 ahead (trial merge clean in all
three), `claude/siege-pregame-gate-view` plugin 5 ahead (`231da73f`), API 2 (`32c0773`), web app 4 (`8f518aa`), `claude/arena-duels`
unchanged. `claude/siege-survival` plugin `34c7bf70` (8 ahead, 0 behind after the update).

## Summary

Status values: `ready` (gate open), `waiting: <gate>`, `in progress`, `in review` (pushed, waiting for the developer's
test), `merged`, `blocked: <reason>`.

| Link | Scope (plan §2a) | Repos / branch | Status | Started | Heads (plugin / api / web-app / workspace) | Tests vs baseline |
|---|---|---|---|---|---|---|
| S1 | Survival core logic (waves, kills, round delay, stuck rules, end conditions, scaling presets, monster mix, specials, repair maths, spawn selection, rewards, Mystery Box pick) | plugin `claude/siege-survival`, `knk-core/.../core/survival/` only | in review | create_session session_01R1w2UvKtghxZowkQBTRYqG, 2026-11-03 | plugin `b5f86586` (merge of S1 + S2's `8cf2761e`) / — / — / workspace `main` (this report; bookkeeping applied by the coordinator from S1's patch) | knk-core 2433 → 2595 (S1 +101, S2 +61), 0 failed; api-client 288 and paper 2385 unchanged |
| S2 | NPC platform §5b core: combat and speed profiles, modifier pipeline by source, clamping with a report | plugin `claude/siege-survival`, `knk-core/.../core/npc/` only | in review | create_session session_01R1w2UxEVJTzDXBdKWkGihy, 2026-11-03 | plugin `8cf2761e` / — / — / — | core 2433 → 2494 (+61, 0 failures); api-client 288, paper 2385 unchanged |
| G1 | Animated rebuild for all destroyed gates (gate Decision 6), size-aware evacuation | API, plugin, web app `claude/gate-animated-rebuild` | waiting: #167, #213, realtime merged | — | — | — |
| S3 | Siege prerequisites: visibility arbiter, NPC gate-damage cause, weighted capture presence, mob kills out of PvE statistics | plugin `claude/siege-survival` | in review (pushed 2026-11-06; started on the developer's request although #213 and arena-duels are unmerged; shared files `SiegeGateController.java` (3 additive hunks), `KnKPlugin.java` (5 small hunks), listed in the S3 block) | create_session session_01R1w2UuxjTGuarBTYzmFpVi, 2026-11-06 | plugin `6b80638e` / — / — / workspace `main` (S3 block, patch) | core 2638 → 2663, paper 2504 → 2535, api-client 330 unchanged; 0 failures (JDK 25) |
| S4 | Phase 1 contracts/config: API entities (no migration yet), DTOs, services, readiness, form seeds; api-client DTOs | API, plugin api-client `claude/siege-survival` | in review (migration deferred until #167 merges; plugin commit as a patch, see the S4 block) | create_session session_01R1w2UwPn7oGLNgHm17vf7C, 2026-11-05 | plugin `699d1889` (`3d5cb1bd` applied by the coordinator) / api `043bd2a` / — / workspace `main` (S4 block, patch) | API 3659 → 3779 passed, 0 failed, 88 skipped; api-client 321 → 330, 0 failed, 2 skipped; core 2638 / paper 2504 unchanged, build green (coordinator, `699d1889`) |
| S5 | Phase 2 runtime slice (mob spawning and goals, §5b adapters, ghost state, waves, end conditions) + live checklist | plugin `claude/siege-survival`; workspace `claude/siege-survival` (checklist) | in progress | create_session session_01R1w2UuecHgiqgXCbskAjGT, 2026-11-06 | — | — |
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
- 2026-11-05: developer asked to update the branch and start the next link. Branch updated (`34c7bf70`, green). Gate re-check
  above; S4 started as session_01R1w2UwPn7oGLNgHm17vf7C with the migration deferred (decision and reasons under "Waiting for the
  developer"). #167 is a clean merge everywhere and is the merge to do next.
- 2026-11-05 (S4 done): the S4 session could attach neither knk-plugin nor knk-workspace (permission classifier), so its api-client
  commit and this bookkeeping came as `send_message` patches (sha256-checked, `git am`, pushed by the coordinator); the API push
  worked from the session. Pattern for later links: give the link's `source_url` the repo it pushes most to, and expect patches
  for the others. Follow-up #265 filed; S7 held until S5 (reasoning under "Waiting for the developer").
- 2026-11-06: developer: "Can't we continue implementation on the feature branch?" — yes: S3 started (session
  session_01R1w2UuxjTGuarBTYzmFpVi) with overlap guidance, and the coordinator generated the migration
  `20261106071958_AddSiegeSurvivalPhase1` on the API branch (design time, `Database__MySqlServerVersion=8.0.36`, dummy
  connection string; `dotnet-ef` 9.0.10 as in CI). Verified: Up() = 18 CreateTable + 35 CreateIndex, Down() = 18 DropTable, no
  operation on an existing table; the snapshot diff is additions and reordering only (0 removed lines not re-added).
- 2026-11-06 (S3 done, S5 started): S3's bookkeeping came as a checksum-verified patch (workspace attach refused again); the
  plugin push worked from the session. S5 is the first link with a live checklist; the developer runs S3's regression steps
  and S5's checkpoint in one sitting on the same deploy (API branch with the migration, plugin jar).
- Next coordinator run: re-run the gate check; start G1 (`claude/gate-animated-rebuild`, from the trunks) as soon as #167,
  #213 and realtime are merged, S4 as soon as #167 and #180 are merged, S3 as soon as realtime, #213 and the arena-duels
  decision are in; then S5 (first live checkpoint), S6–S8 batched into one checklist, S9 last.

## Link blocks

(Each link appends its block here: scope done, commits per repo, tests baseline → result, deviations, flags, checklist
location, notes for later links.)

## Link S3 — Siege prerequisites (2026-11-06)

Session session_01R1w2UuxjTGuarBTYzmFpVi (started by the coordinator on the developer's request, with #213 and
arena-duels unmerged). knk-plugin `claude/siege-survival`, base `699d1889` (S1, S2, S4; `main` `33122cf4` merged), head
**`6b80638e`**. knk-workspace could be attached read-only only (the `add_repo` push attach was refused by the permission
classifier), so this block came as a patch. Scope: plan §2a row S3 / phase 0 items "visibility arbiter", "team-based siege
gate damage for NPCs", "weighted, actor-aware capture presence", "mob kills out of ordinary PvE statistics". Behaviour-neutral
for ordinary PvP Siege, world gates, the invisibility enchantment and spectators: nothing changes until a Survival runtime
(S5) marks a ghost or registers a match actor; proven by the unchanged existing tests plus the regression tests below.

### Scope done

**A. One visibility arbiter.** `knk-core/.../core/visibility/` (Bukkit-free, added to `ArchitectureGuardTest`):
`PlayerVisibilityRules.decide(targetIsGhost, viewerOnGhostTeam, targetVanished)` → `VISIBLE | HIDDEN | HIDDEN_UNLESS_STAFF`,
in this order: (1) a **ghost** is `HIDDEN` from every viewer its `GhostTeam` doesn't include — wins over everything, no
permission reveals it; (2) a vanished (owner/staff mode) target is `HIDDEN_UNLESS_STAFF` (hide now, show when the viewer's
staff/owner check resolves true — the pre-S3 `ModeService` rule); (3) otherwise `VISIBLE`. `GhostTeam(key, Predicate<UUID>
membership)` is the team whose living and ghost members see the ghost (equality by key). Paper adapter
`paper/visibility/PlayerVisibilityArbiter`: the **only** caller of `hidePlayer`/`showPlayer`; `markGhost(player, team)`
(hides from outsiders, applies infinite particle-less Invisibility for the siege boards' see-friendly-invisibles, refreshes),
`clearGhost(player)` (removes it, refreshes), `isGhost`, `ghostTeamOf`, `ghosts()`, `forget`, `apply(viewer, target)`,
`refreshVisibilityOf/For`. `ModeService` owns the arbiter (`visibility()` getter) and routes `refreshVisibilityOf`,
`refreshVisibilityFor`, `applyMode` and `forget` through it; its old `applyVisibility` is gone, so the un-hide the checks
report §2 found (join, permission change) can't happen. Spectators, `InvisibleEquipment` (equipment packets) and
`SiegeWorldPresenter` (display entities) never called `hidePlayer` and are untouched.

**B. NPC gate damage with a team-based check.** `GateDoorDamageEvent.Cause.NPC_MELEE` (additive);
`GateDamageConsequenceListener` amount 10 for it (the caller passes the factored damage anyway). New package
`paper/siege/npc/`: `MatchActor(entityId, lobbyId, teamId, captureWeight)`; `MatchActorRegistry` (register/unregister/clear
per lobby, `actorOf(Entity)` incl. a projectile's shooter, `isActor`, persistent-data tag `<plugin>:match_actor` =
`"<lobbyId>:<teamId>"` read back by `tagOf` for the leftover sweep, `presences(lobbyId, center, radius)` = living actors in
range as weighted `Presence`s, pruning dead/gone ones); `NpcGateDamage.hit(mob, block[, multiplier])` → `NOT_AN_ACTOR |
NOT_A_DOOR | REFUSED | CANCELLED | HIT`, damage `10 × multiplier` (the difficulty's gate damage factor, default 1), through
`GateDoorHitService.handleDamage(door, mob, block, NPC_MELEE, damage)` — the same per-door `HealthSystem` path as a
player, only while the door is CLOSED. `SiegeGateController.mayDamage(Entity, int)` (additive overload) resolves a player or
a projectile's player shooter as before and a registered actor of **the lockdown's own lobby** by team through the existing
`SiegeGatePlan.canDamage` (enemy of the current owner; never the own alliance's gate; other lobbies' actors and untagged mobs
stay refused); `setMatchActors(Function<Entity, Optional<MatchActor>>)`. `SiegeGateListener` hands the causing entity to
that overload (its player-only `attacker()` helper removed). `HealthSystem.repairToFull(door)` (heal a standing door to max,
cracks/display/persist/state listeners, returns the HP restored, does not open or close) and `rebuildForClosing(door)`
(destroyed → standing, active, full health, **OPEN at the last frame**, no blocks placed, no broadcast, persisted; the
caller's `gateManager.closeGate(id)` then rebuilds it through the normal closing animation).

**C. Weighted, actor-aware capture presence.** `core/siege/SiegeActorKind { PLAYER, NPC }`.
`ObjectiveState.Presence(actorId, teamId, distance, kind, weight)` with the old 3-arg constructor (= PLAYER, weight 1),
`Presence.npc(entityId, teamId, distance, weight)`, `playerId()` (null for an NPC), `contributes()` (weight > 0).
`CaptureCalculator.attackPressure(double)/defensePressure(double)/delta(double, double, iv)`: the same formula with the weight
sum in place of the head count, `A1 + (w − 1)·A2` floored at 0, the delta truncated towards zero — whole-number weights give
exactly the int formula. `ObjectiveState.step` sums weights per side (head counts stay in `StepResult` for feedback); the
capturer is the closest contributing attacker, which may be an NPC: `CaptureEvent` gained `capturerKind` and
`capturerActorId`; `capturerId` is **null** for an NPC capture, `rewardEligible` false (8-arg constructor kept).
`CaptureActivityTracker` lists players only in `actors`, the NPC team still in `actorTeamIds`. `SiegeService`:
`setActorPresence(ActorPresenceSource)` adds the lobby's actors (`MatchActorRegistry::presences`) to each objective's
presence, `setPresenceExclusion(Predicate<UUID>)` for ghosts (DESIGN §3b: no capture contribution), and the null-capturer
paths (`roster.recordCapture` skipped, announcement names the NPC team, result rows without a user). Side-capture reduction
untouched (S51 is S5's setting).

**D. Mob kills out of ordinary PvE statistics.** `core/statistics/CreatureClass { ORDINARY, MATCH_NPC }`;
`CombatStatisticsRules.countsPveKill(spawnReason, excluded, creature)` (never for a match NPC) and
`countsCreatureDamage(creature)`; `DeathCauseClassifier.LastDamager.MATCH_NPC` → `Cause.MATCH_NPC` with no metric
(`recorded()` false). `CombatStatisticsListener` takes a `Predicate<Entity> matchNpc` (4-arg constructor; the 3-arg one =
none): no PvE kill for a match NPC, no `damage_dealt.mob` / `damage_received.mob` with one (also behind its projectile), no
`deaths_by_cause.*` for a death to one; `DEATHS` and the Siege roster projection are as before.

**E. Wiring (`KnKPlugin`, 5 small hunks, see below):** `matchActors = new MatchActorRegistry(this)` after the siege
service; `siegeService.setActorPresence(matchActors::presences)`; `siegeGates.setMatchActors(matchActors::actorOf)`; the
statistics listener's predicate `entity -> matchActors != null && matchActors.isActor(entity)`; `getMatchActors()`.

### Commits (knk-plugin `claude/siege-survival`)

`c4b7b2da` core: weighted capture presence + match-NPC statistics classification · `392f17d1` visibility arbiter (core
rule, Paper adapter, `ModeService` delegation) · `8d4908ba` NPC gate damage (`NPC_MELEE`, `siege/npc`, controller
overload, `HealthSystem` repair methods) · `9c373a0e` actors in `SiegeService` presence, statistics exclusion, `KnKPlugin`
wiring · `6b80638e` presence exclusion hook for ghosts. Head `6b80638e`.

### Tests (`./gradlew build -x deployToDevServer`, JDK 25 toolchain)

| Module | Baseline (`699d1889`) | Result (`6b80638e`) |
|---|---|---|
| knk-core | 2638, 0 failed | 2663 (+25: `WeightedCapturePresenceTest`, `MatchNpcStatisticsTest`, `PlayerVisibilityRulesTest`), 0 failed |
| knk-api-client | 330, 0 failed, 2 skipped | 330, 0 failed, 2 skipped (unchanged) |
| knk-paper | 2504, 0 failed, 18 skipped | 2535 (+31: `PlayerVisibilityArbiterTest`, `MatchActorRegistryTest`, `NpcGateDamageTest`, `SiegeGateControllerNpcDamageTest`, `HealthSystemRepairTest`, `CombatStatisticsMatchNpcTest`), 0 failed, 18 skipped |

Every pre-existing test runs unchanged (`CaptureCalculatorTest`, `ObjectiveCaptureTest`, `HolderRelativeScoringTest`,
`CaptureActivityTrackerTest`, `SiegeGatePlanTest`, `GateDamageConsequenceListenerTest`, `CombatStatisticsListenerTest`,
`OfflineFreezeAndModeTest`, …); the only edited test file is `ArchitectureGuardTest` (+`"visibility"`).

### Deviations

- `HealthSystem.repairToFull` does **not** close an open door (report §7 wrote "then closeGate if the door is open"): a heal
  entry point shouldn't move doors; S6 closes after the heal where S49 wants it (one call, `gateManager.closeGate(id)`).
- The ghost's translucency (vanilla Invisibility, infinite, no particles/icon) is applied by `markGhost` and removed by
  `clearGhost` rather than left to S5, so one place owns the whole ghost look; S5 can pass no-op effect functions through the
  package-private constructor if it wants to own it (flag S3-3).
- `SiegeService.setPresenceExclusion` (ghosts out of capture presence) is a small addition beyond the four items: the report
  §8 asks the actor-aware presence model to "exclude ghosts", and S5 has no other hook into the private presence scan.

### Hunks in the shared files (for the #213 / arena-duels merges)

`SiegeGateController.java` (3 hunks, all additive): imports `MatchActor`, `Entity`, `Projectile`, `java.util.function.Function`;
after `mayDamage(Player, int)` a new block: field `matchActors` (default `Optional.empty()`), `setMatchActors(...)`,
`mayDamage(Entity, int)`. No existing line changed.
`KnKPlugin.java` (5 hunks): field `matchActors` after `siegeGates` (~l. 318); the `CombatStatisticsListener` constructor
call gets a 4th argument (~l. 1581, the one existing line that changed: the closing `), this);` moved to the new argument
line); two lines after `siegeService.setHistoryApi(...)` (~l. 4076); one line after the `SiegeGateListener` registration
(~l. 4145); `getMatchActors()` after `getSiegeGates()` (~l. 4189). `git diff 699d1889..6b80638e -- <file>` shows them.

### Flags for the developer (interpretations and defaults)

- **S3-1** Staff/owner vanish permission does **not** reveal a ghost: the ghost reason wins; staff see ghosts only as
  teammates. (Alternative: staff see everything — one line in `PlayerVisibilityRules`.)
- **S3-2** A ghost who is also in owner/staff mode stays hidden from teammates without the staff node (vanish still applies
  within the team); teammates with it see them.
- **S3-3** Translucency = infinite Invisibility effect without particles; `clearGhost` removes *any* Invisibility, so a
  ghost whose invisibility-enchantment ability was running loses it at the respawn (edge case, accepted).
- **S3-4** `hidePlayer` side effects accepted as in report §2: a ghost leaves outsiders' tab list, and `/msg`, `/tpa`,
  `/pay` lookups (`VisiblePlayers.canSee`) treat them as offline for outsiders.
- **S3-5** Weighted delta truncated towards zero (a fraction of a point is dropped, never carried); a lone actor lighter
  than one player presses `A1 + (w − 1)·A2`, floored at 0; weight 0 = present but not counted, not contesting.
- **S3-6** An NPC capture credits nobody: `capturerId` null, no reward, announcement "<NPC team> captured <objective>!",
  the result's objective row has no capturer user, telemetry `player` null (already null-safe).
- **S3-7** Capture feedback (`Started`/`Ongoing`) names players only; the NPC team appears in `actorTeamIds` (so a retake
  announcement still works when the NPC team held the objective before).
- **S3-8** NPC gate hit = 10 HP (a player's left click) × the caller's factor; refused unless the door is CLOSED, active,
  standing (as for players); `NpcGateDamage.Outcome` tells the caller why.
- **S3-9** An actor damages only gates of the lockdown of its own lobby; other lobbies' actors and untagged mobs are
  refused as before; a mob's projectile resolves to the mob.
- **S3-10** NPC gate damage is credited to nobody (`SiegeGateDamageSink`, `GateDamageStatisticsSink` stay player-only):
  Survival's door telemetry is S5/S8's.
- **S3-11** `rebuildForClosing` leaves the door OPEN at frame `animationDurationTicks` with no blocks; the first closing
  steps vacate empty cells. **Live check for S6:** a destroyed door rebuilt this way closes cleanly with a player and a
  large mob in the doorway (G1's return animation then replaces the look).
- **S3-12** Statistics exclusion covers PvE kills, mob damage dealt/received and the death cause; `DEATHS` still counts an
  open-world death to a match NPC (Survival members are in a running match, where `DEATHS` is already left to the roster).
- **S3-13** Tag `<plugin>:match_actor` = `"<lobbyId>:<teamId>"` (string); the registry is in-memory, the tag is for S5's
  startup sweep (`tagOf`).
- **S3-14** `presences()` forgets dead, invalid or missing actors on the way; `captureWeight` must be finite and ≥ 0.
- **S3-15** `ModeService` keeps its public constructor; the arbiter is built inside it (`PlayerVisibilityArbiter.bukkit`),
  so `KnKPlugin`'s mode wiring is unchanged.

### Follow-ups found (not fixed; the coordinator files issues)

- Report §2's remaining ghost mechanics are S5's, not S3's: `setInvulnerable(true)` and re-applying it after
  `JoinLoadingGuard` (which toggles invulnerability on join), `EntityTargetLivingEntityEvent` safety net,
  `ProjectileHitEvent` cancel, team collision rule NEVER, hunger/pickup/interaction cancels, adventure mode, armour vault.
- `GateDamageConsequenceListener.DAMAGE_BY_CAUSE` is still a hard-coded map (10 for every cause); a config key per cause
  would let the NPC base damage be tuned without a build (today the difficulty factor covers it).
- `SiegeMenuSnapshots` shows "?" as the last capturer of an NPC-captured objective; a team name would read better (S9/UX).

### Notes for later links

- **S5 (runtime):** ghosts: `plugin.getModeService().visibility()` (or keep the `ModeService` reference) →
  `markGhost(player, new GhostTeam("siege:" + lobbyId + ":" + teamId, id -> roster.teamOf(id).orElse(-1) == teamId))` on
  death, `clearGhost(player)` at the intermission respawn, match end and restore; also call
  `siegeService.setPresenceExclusion(id -> arbiter.isGhost(id))` once at startup so ghosts never count in capture. Actors:
  `plugin.getMatchActors().register(mob, lobbyId, npcTeamId, difficulty.captureContribution)` after spawning,
  `unregister(uuid)` on death/removal, `clear(lobbyId)` at match end; capture presence and gate damage then work with no
  further wiring. Gate breach: `new NpcGateDamage(new GateDoorHitService(gateManager), plugin.getMatchActors()).hit(mob,
  block, difficulty.gateDamageFactor)` on the breach goal's timer (`GateDoorHitService` is a stateless wrapper; the stand
  point is `core/siege/SiegeGateApproach`). Leftover sweep at startup: remove living mobs with `tagOf(entity).isPresent()`.
  NPC targeting of ghosts: `arbiter.isGhost(uuid)` is the hard-eligibility check.
- **S6 (repairs):** damaged standing door → `healthSystem.repairToFull(door)` then `gateManager.closeGate(door.getId())` if
  open (S49); destroyed door → `healthSystem.rebuildForClosing(door)` then `gateManager.closeGate(door.getId())`, and listen
  with a `GateStateListener` for the real CLOSED (a jam leaves CLOSING).
- **S8 (results):** `CaptureEvent.capturedByNpc()` / `capturerActorId` tell NPC captures apart in the result spool.

### Regression checklist for the developer (one ordinary PvP siege match, one sitting)

1. Start a PvP siege with two teams; one player in staff mode before the start: they are hidden from non-staff and shown to
   staff, exactly as before; `/mode` off shows them again; a relog keeps the mode.
2. Stand in an objective's ring with 1 attacker vs 0, 1 and 2 defenders: the capture bar moves at the familiar rates (5
   points/s alone; 7 − 6 = 1 with two attackers against one defender); the capture announcement names the player.
3. Hit a locked enemy gate with a sword and an arrow: damage lands and shows in the match's gate-damage reward; hit your own
   team's gate: refused; let a zombie hit a locked gate: nothing happens (as before).
4. Kill a wild zombie and die to one during the match: `pve_kills` and `deaths_by_cause.mob` unchanged from before.
5. Use the invisibility enchantment ability once: teammates see the body, the other team nothing; tab list unchanged.
6. After the match: gates restored, boards restored, no "Gate restored" broadcast change, no error in the log mentioning
   `visibility`, `MatchActor` or `NPC`.

### To file (no GitHub issue access from this session)

- The three follow-ups above (S5 ghost mechanics are covered by #41 already; the damage-map config key and the menu
  capturer name are new).

## Link S4 — phase 1 contracts/config (2026-11-05)

**Session:** `session_01R1w2UwPn7oGLNgHm17vf7C` (create_session). **Repos:** knk-web-api `claude/siege-survival`
(created from `master` `2e3dfeb`), **head pushed `043bd2a`**; knk-plugin `claude/siege-survival` from `34c7bf70`:
commit `3d5cb1bd` delivered as a patch (see Deviations), applied and pushed by the coordinator as **head `699d1889`**. **Issue:**
PandiO/knk-workspace#41. **Status:** in review (API pushed; plugin patch applied and pushed by the coordinator; this bookkeeping as a patch).
**No migration** (coordinator decision): a database has no survival tables until the follow-up migration.

### Scope done

**API entities (new files under `Models/Siege/Survival/`, enums in `Enums/SiegeSurvivalEnums.cs`, one "Siege Survival
phase 1" block in `Properties/KnKDbContext.cs`; tables `siege_survival_*`, string enums, delete rules as the Siege block):**

- `SiegeSurvivalSettings` 1:1 with `SiegeScenario` (unique `SiegeScenarioId`, cascade): `Enabled`, `MinPlayers` (1),
  `HumanTeamId`/`NpcTeamId` (SetNull; null = first Defender / first Attacker), `EquipmentMode`
  (`OwnInventory`/`Kits`/`MatchProgression`), selected kits (join `SurvivalSettingsKit`, Kit Restrict), `DefaultKitId`,
  `BaselineLoadoutKitId` (a Kit; null = empty inventory), `IntermissionMillis` (10000), `EndWhenAllObjectivesCaptured`
  (false), `FavorNearPlayersPercent` (0) + `NearZoneCount` (1), stuck settings (`StuckAfterMillis` 30000,
  `LastEnemiesCount` 3, `RespawnLimit` 2, `RoundBackstopMillis` 300000 / null = off, `MeaningfulDistance` 1.0), kill
  rewards (`CoinsPerKill`/`XpPerKill` null = capture reward ÷ 10, `MatchCurrencyPerKill` 70, `KillBonusMultiplier` 1.1).
- `SurvivalLobbySettings` 1:1 with `SiegeLobby` (cascade): `AllCapturedOverride` `Inherit`/`On`/`Off`.
- `SurvivalDifficultyProfile` (n per scenario, `IsDefault`): count curve (`CountPreset`, `CountBase`, `CountStep`,
  `CountMultiplier`, `CountSwitchRound`), stat curve (`StatPreset`, `StatStep`, `StatMultiplier`, `StatSwitchRound`; b = 1),
  five weights, `PerPlayerFactor` + `PerPlayerAppliesToStats`, `MaxAlive`, `StatCap`, `CountCap`, `RepairRatePerSecond`,
  `GateDamageFactor`, `CaptureContributionWeight`, `SpawnIntervalMillis`, `AggroRadius`/`LeashDistance` (null = plugin).
- `SurvivalMonsterType` (scenario mix: `EntityType` upper-case key, `Weight`, `UnlockRound`); `SurvivalSpecialWaveProfile`
  (`Key`, `Name`, `CountOverride`, `CountMultiplier`, `Additive`) with `SurvivalSpecialWaveMonsterType`;
  `SurvivalSpecialWaveEntry` (`Kind` `Recurring` interval/start wave/priority or `Explicit` wave; profile of the same scenario).
- `SurvivalSpawnZone` (`Weight`, `AnchorLocationId`, `AreaRadius`, `PrerequisitePolicy` `All`/`Any` + join
  `SurvivalSpawnZoneObjective`, `MinWave`/`MaxWave`, `ForNormalWaves`/`ForSpecialWaves`, `LaneAutoReroute`) with
  `SurvivalSpawnZonePoint` (`Kind` `Spawn`/`Lane`, ordered, Location Restrict).
- `SurvivalTargetOverride` (exactly one of `SiegeObjectiveId`/`GateStructureId`, `Mode` `Standard`/`Allow`/`Deny`, one per
  target; cascades with the target).
- `SurvivalPurchasePoint` (location, `InteractionRange`) with `SurvivalPurchaseOffer` (blueprint, `Quantity`, `Price`);
  `SurvivalMysteryBoxPool` (`Variant` `Items`/`EnchantedBooks`) with `SurvivalMysteryBoxEntry` (`ItemBlueprintId` or
  `EnchantmentDefinitionId` + `EnchantmentLevel`, `ChancePercent` decimal(5,2)) and `SurvivalMysteryBoxEntryEnchantment`
  (independent chance per enchantment); `SurvivalMysteryBoxPoint` (location, pool Restrict, `BlockType`
  `minecraft:end_portal_frame`, `RollPrice` 1000, `ClaimTimeoutMillis` 10000).

**Endpoints** (`Controllers/SiegeSurvivalController.cs`, `Controllers/SurvivalChildControllers.cs`; writes need
`knk.siege.admin.manage` like the Siege scenario endpoints, reads are "logged in or the game server"; `EndpointAccessRulesTests`
green, allow-list unchanged):

- `GET api/SiegeSurvival/scenarios` (= `api/siege-survival/scenarios`): scenarios with survival settings.
- `GET|PUT|DELETE api/SiegeSurvival/scenarios/{id}/settings` (PUT creates or replaces), `GET|PUT|DELETE
  api/SiegeSurvival/lobbies/{id}/settings`.
- **`GET api/siege-survival/scenarios/{id}/configuration?lobbyId=&difficultyProfileId=`** — the complete frozen
  configuration (every default resolved: teams, kill rewards, the lobby's all-captured override, objective capture
  locations, target overrides per objective/gate, the chosen or default difficulty, spawnzones with points, special
  waves, purchase points, Mystery Box points with their pools and basis-point chances) **plus a `readiness` section**;
  404 = no survival settings (an ordinary PvP scenario).
- `GET api/siege-survival/scenarios/{id}/readiness?lobbyId=&difficultyProfileId=`; `GET api/SiegeSurvival/scenarios/{id}/preview?difficultyProfileId=&fromRound=&toRound=&players=` (§11 per-round count and stat multipliers).
- Child collections, each `api/Survival<Entity>` with `GET by-parent/{parentId}`, `GET {id}`, `POST` (parent id in the body),
  `PUT {id}`, `DELETE {id}` (class-level `RequireServiceOrPermissionForWrites`): `SurvivalDifficultyProfiles`,
  `SurvivalMonsterTypes`, `SurvivalSpecialWaveProfiles`, `SurvivalSpecialWaveMonsterTypes`, `SurvivalSpecialWaveEntries`,
  `SurvivalSpawnZones`, `SurvivalSpawnZonePoints`, `SurvivalTargetOverrides`, `SurvivalPurchasePoints`,
  `SurvivalPurchaseOffers`, `SurvivalMysteryBoxPools` (409 when a box point uses the pool), `SurvivalMysteryBoxEntries`,
  `SurvivalMysteryBoxPoints`.

**Readiness** (`Services/SiegeSurvivalReadiness.cs`, pure; shared by the readiness endpoint and the configuration): the Siege
structural rules (`SiegeScenarioReadiness.EvaluateStructure`, minus the `NO_INSTANT_VICTORY_OBJECTIVE` warning) plus
S1's codes `end.wipe-only`, `end.all-captured-unreachable`, `scaling.count-base`, `scaling.count-cap`,
`scaling.count-flat`, `scaling.stat-flat`, `scaling.walking-speed-hard-cap`, `scaling.walking-speed-fast`, `mix.empty`,
`mix.none-in-round-1`, `mix.duplicate`, `special.unknown-profile`, `special.explicit-conflict`,
`special.recurring-priority`, `spawn.no-initial-zone`, `spawn.unknown-objective`, `box.empty`, `box.chance-range`,
`box.variant`, `box.unknown-blueprint`, `box.unknown-enchantment`, `box.duplicate-enchantment`, `box.total`, and API-only
`settings.*`, `team.*`, `kits.*`, `loadout.unknown-kit`, `profile.*`, `scaling.multiplier`, `scaling.switch-round`,
`scaling.stat-cap`, `scaling.repair-rate`, `special.entry-invalid`, `spawn.zone-unusable`, `spawn.wave-range`,
`spawn.lane-single-point`, `target.*`, `shop.*`, `box.pool-unknown`, `box.pool-unused`. Errors vs warnings as S1's
`ReadinessIssue`.

**Contracts (DTO only, `Dtos/SiegeSurvivalDtos.cs`):** `SurvivalMatchResultDto` (match/lobby/scenario/profile ids, the
configuration's `generatedAt`, `endReason` = `SurvivalEndReason` `TeamWipe`…`TechnicalLimit`, reached and completed wave,
earned/system kills, per-player statistics with exact accruals and settled integers, a settlement block with
`settlesRewards` and the ledger key) and `SurvivalMatchCheckpointDto` (substate, wave, alive/queued, NPC-held objectives,
active zones, door repair work, players' ghost/kit/balance/pending roll). No endpoint accepts them yet (S8).

**Form seeds:** 18 files in `Data/FormConfigurationSeeds/` (one per entity, `SurvivalSettingsKit.join` and
`SurvivalSpawnZoneObjective.join` as join entries), README table and note; all pass the dry run, import and the
required-field check (`FormConfigurationSeedFilesTests`, two join rows added to its by-design list). No existing seed changed.

**knk-plugin `knk-api-client`:** `dto/SiegeSurvivalDtos.java` (records mirroring the read DTOs, enums as strings,
unknown fields ignored), `impl/SiegeSurvivalQueryApiImpl.java` (`listScenarios()`, `getConfiguration(scenarioId, lobbyId,
difficultyProfileId)` with 404 → null, `getReadiness(...)`, `getPreview(...)`), exposed as
`KnkApiClient.getSiegeSurvivalQueryApi()`; tests `SiegeSurvivalDtosTest`, `SiegeSurvivalQueryApiImplTest`. knk-core and
knk-paper untouched.

### Commits

- knk-web-api `claude/siege-survival`: `f2a0aa6` entities and EF mapping · `12de40c` DTOs, service, readiness, frozen
  configuration, controllers · `043bd2a` form seeds and tests (head, pushed).
- knk-plugin `claude/siege-survival`: `3d5cb1bd` api-client DTOs and query client (patch; applied by the coordinator, head `699d1889`).

### Tests (baseline → result)

| Repo / module | Baseline | Result |
|---|---|---|
| knk-web-api (`dotnet test`) | 3659 passed, 0 failed, 88 skipped (`2e3dfeb`) | 3779 passed, 0 failed, 88 skipped (`043bd2a`); `dotnet build` 0 errors |
| knk-api-client | 321, 0 failed, 2 skipped (`34c7bf70`) | 330, 0 failed, 2 skipped (`3d5cb1bd` here; `699d1889` coordinator) |
| knk-core | 2638, 0 failed (`34c7bf70`) | 2638, 0 failed (coordinator build of `699d1889`) (unchanged) |
| knk-paper | 2504 (18 skipped), 0 failed (`34c7bf70`) | 2504 (18 skipped), 0 failed (coordinator build of `699d1889`) (unchanged) |

Full plugin build (`./gradlew build -x deployToDevServer`, JDK 25 toolchain): green on the coordinator's build of `699d1889` (knk-core 2638, knk-api-client 330, knk-paper 2504, 0 failures); this session's own full build of `3d5cb1bd` passed knk-core and knk-api-client and was still compiling knk-paper when the block was written.

### Deviations

- **No migration** (coordinator decision for this link). Follow-up, right after `claude/alpha-run-1-gates` (#167) merges
  into `master`: on `claude/siege-survival` merge `origin/master`, then `dotnet ef migrations add AddSiegeSurvivalPhase1`
  and check: (a) the migration only **adds** 18 `siege_survival_*` tables and their indexes/FKs (no change to any existing
  table or column; `KnKDbContextModelSnapshot` otherwise identical), (b) its parent is #167's
  `20261027150000_AddGatePassThroughStyles`, (c) the unique indexes `siege_survival_settings(SiegeScenarioId)`,
  `siege_survival_lobby_settings(SiegeLobbyId)`, `(SiegeScenarioId, EntityType)`, `(SiegeScenarioId, Key)`,
  `(SiegeScenarioId, SiegeObjectiveId)`, `(SiegeScenarioId, GateStructureId)` are there, (d) `ON DELETE` clauses match
  `SiegeSurvivalDeleteBehaviourTests.ExpectedDeleteRules`, (e) `dotnet ef database update` on a dev copy, then import
  the 18 seeds. Until then the forms import but saving a survival row fails (no table).
- **Plugin push denied.** `add_repo` for knk-plugin and knk-workspace was refused by the session's permission classifier;
  the clones work read-only through the git proxy but `git push` is denied ("not in this session's authorized repository
  set"). The api-client commit `3d5cb1bd` is exported as `s4-plugin.patch` and this bookkeeping as `s4-workspace.patch`
  (both sent to the coordinator with `send_message`); the coordinator applies them (`git am`) and pushes. The API push
  worked (`043bd2a`).
- **Existing files edited** (all outside the #167/#213 claim set): `Properties/KnKDbContext.cs` (DbSets + one block),
  `DependencyInjection/ServiceCollectionExtensions.cs` (two registrations), `Data/FormConfigurationSeeds/README.md`
  (table rows + note), `Tests/.../FormConfigurationSeedFilesTests.cs` (two join rows in `NotOnFormByDesign`); plugin:
  `KnkApiClient.java` (field, construction, getter). Not touched: `SiegeDtos.cs`, `SiegeConfiguration.cs`,
  `SiegeMatchesController.cs`, every Siege seed, every GateDoor*/GateStructure* file, `Migrations/`, the snapshot.
- **To file (coordinator):** the short comment on PandiO/knk-workspace#41 (link S4 pushed, heads, test counts, "migration
  deferred until #167 merges", link to this block) — the GitHub tools of this session are scoped to `PandiO/knk-web-api`.

### Flags for the developer (modelling choices, defaults, tolerances)

- **S4-1** Survival settings are a separate 1:1 row (`SiegeSurvivalSettings`), not columns on `SiegeScenario`: a scenario
  without a row is an ordinary PvP siege and nothing survival-related applies; the survival children hang off the scenario
  itself, so deleting/recreating the settings keeps them. Same for the lobby override (`SurvivalLobbySettings` 1:1 with
  `SiegeLobby`): could become a `SiegeLobby` column later (then the lobby DTO/seed change too).
- **S4-2** Enum names are PascalCase like the Siege enums (`OwnInventory`, `EnchantedBooks`, `Inherit`/`On`/`Off`,
  `TeamWipe`…); the plugin maps them to S1's upper-snake constants. Stored as strings.
- **S4-3** Recapture: the frozen configuration reuses `SiegeScenario.AllowRecapture` (no second flag).
- **S4-4** Minimum players: a survival `MinPlayers` (default 1, S37) next to the scenario's PvP `PlayersMin`; readiness still
  applies the Siege rule `PLAYERS_MIN_BELOW_TEAM_COUNT` to the scenario's own `PlayersMin` (so a survival scenario keeps
  `PlayersMin` ≥ 2 for the lobby runtime-config, and the plugin uses `minPlayers` from the survival configuration).
- **S4-5** Human/NPC teams: explicit `HumanTeamId`/`NpcTeamId`, defaults first Defender / first Attacker; readiness
  `team.*`. The NPC team is an ordinary `SiegeTeam` row (the Siege readiness still wants a spawnpoint on it; see follow-ups).
- **S4-6** Difficulty: several `SurvivalDifficultyProfile` rows per scenario, one `IsDefault` (marking one clears the
  others; the first created is the default); the configuration takes `difficultyProfileId` or uses the default.
- **S4-7** Profile defaults (balance placeholders, all configurable): count linear b = 6, a = 2; stat linear step 0.1,
  m = 1.1, s = 9; weights health 1, walking speed 0.3, melee 1, ranged 1, attack speed 0.5; p = 0.25 (count only);
  max alive 40; stat cap 8; count cap 0 = unlimited; repair rate 50/s (the design's illustrative value); gate damage
  factor 1; capture weight 1; spawn interval 500 ms; aggro/leash null = the plugin's built-in values (no invented
  constants).
- **S4-8** `FavorNearPlayersPercent` defaults to **0** (zone weight only) with `NearZoneCount` 1 — the design names 65 %
  only as an example; set it per scenario.
- **S4-9** Kill rewards: `CoinsPerKill`/`XpPerKill` null = the scenario's `CoinRewardCapture`/`ExpRewardCapture` ÷ 10
  resolved in the configuration (dev seed 300/30 → 30/3; the test data 50/5 → 5/0.5), decimals kept exact.
- **S4-10** Walking-speed checks are **warnings**, not errors (S1 has the hard cap as an error): the NPC platform clamps
  at runtime, so the configuration is playable; the warning tells the admin the growth is cut off. Base speeds per type
  come from a small lookup (`SurvivalScaling.VanillaWalkingSpeed`: zombie 0.23, spider 0.3, default 0.25).
- **S4-11** Mystery Box chances are stored as percent at 0.01 % precision (`decimal(5,2)`), rejected finer; the
  configuration sends both `chancePercent` and `chanceBasisPoints`; "exactly 100 %" is the integer check on basis points
  (S1-15). Pools are scenario-owned (not a global catalogue) and Restrict while a box point uses them.
- **S4-12** `MatchProgression`'s baseline loadout is a **Kit** reference (null = empty inventory); kits mode needs ≥ 1
  selected kit and a default among them (readiness, not save-time: authoring happens in several saves).
- **S4-13** Special waves: profile + schedule entries as in S1 (`Recurring` interval/start wave/priority, `Explicit`
  wave); an entry's profile must belong to the same scenario; `StartWave` null = the interval. Priorities: lowest wins.
- **S4-14** Spawnzones: a zone is "usable" with ≥ 1 `Spawn` point or an `AreaRadius`; "initial" = no prerequisite, first
  wave 1, normal waves on; lane points are the ordered `Lane` points of the same zone; a one-point lane warns.
- **S4-15** Target overrides cascade with their objective/gate (a deleted target takes its override along) and the unique
  index allows one override per target per scenario.
- **S4-16** Purchase offers are blueprint + quantity + price (no stock, no per-player limit in v1).
- **S4-17** The `NO_INSTANT_VICTORY_OBJECTIVE` Siege warning is dropped from survival readiness (replaced by
  `end.wipe-only`); every Siege **error** still applies.
- **S4-18** The preview endpoint ports S1's maths (`SurvivalScaling`): count floored, never below 1, cap last; stats
  `1 + w·(curve − 1)`, per-player factor only when enabled, never below 0, stat cap last; at most 500 rounds per call.

### Follow-ups found (not fixed; the coordinator files issues)

- `SiegeLobbyService.GetRuntimeConfigAsync` lists a survival scenario only when it passes the **PvP** structural rules,
  so the NPC team needs a (meaningless) spawnpoint and `PlayersMin` ≥ 2; S5/S9 should either let the plugin read
  survival scenarios from the survival configuration directly or teach runtime-config the survival readiness.
- `SiegeRuntimeScenarioDto` has no "survival" flag (untouched `SiegeDtos.cs`); the plugin learns it from
  `GET api/siege-survival/scenarios` or a 404 on the configuration. A flag can be added once #167/#213 are merged.
- `SurvivalChildController` lists reload each row for its navigations (one query per row); fine for authoring lists,
  a projection would be better once the lists grow.
- The web app has no routes for the new `api/Survival*` controllers yet (S9).
- The `AddSiegeSurvivalPhase1` migration (coordinator step above).

### Notes for later links

- **S5 (runtime):** per match, `KnkApiClient.getSiegeSurvivalQueryApi().getConfiguration(scenarioId, lobbyId, null)`
  (or the chosen `difficultyProfileId`) **once at match start** and keep the `ConfigurationDto` as the frozen
  configuration; `null` = not a survival scenario; check `readiness().isReady()` before starting. Map:
  `stuck` → `StuckSettings` (`roundBackstopMillis` null → `withoutBackstop()`), `endConditions.allCapturedEnabled`
  → `EndConditionSettings` (or pass `scenarioAllCaptured` + `lobbyOverride`), `difficulty.countCurve`/`statCurve`
  → `ScalingCurve` (`asStatCurve()`), `statWeights` → `StatWeights`, `perPlayer` → `PerPlayerScaling`, `maxAlive`,
  `statCap`, `countCap` → `WaveScalingSettings`; `monsterTypes` → `MonsterType` list (ids are the upper-case entity
  type keys); `specialWaves.profiles/entries` → `SpecialWaveProfile`/`SpecialWaveEntry` (keys are the profile ids);
  `spawn.zones` → `SpawnZone` (ids as strings, `prerequisiteObjectiveIds` as strings, anchor → `SurvivalPoint`) and
  `spawn.favorNearPlayersPercent`/`nearZoneCount` → `SpawnZoneSelector`; `killRewards` → `KillRewardSettings`;
  `mysteryBoxPoints[].pool` → `MysteryBoxPool` (entries with `chanceBasisPoints`); `intermissionMillis`,
  `allowRecapture`, `minPlayers`, `humanTeamId`/`npcTeamId`, `objectives[].targetOverride`/`gates[].targetOverride`.
- **S7 (economy, Mystery Box):** expected match-scoped roll endpoint shape (not built): `POST
  api/siege-survival/matches/{matchId}/mystery-box/{pointId}/roll` with body `{ rollId (idempotency), userId }`,
  answer `{ rollId, entry (the picked SurvivalMysteryBoxEntryDto), rolledEnchantments[], reel[] (passing items, real
  odds), charged, balanceAfter }`, plus `POST .../roll/{rollId}/claim` and `.../forfeit`; the pool and price come
  from the frozen configuration, the API only charges once per `rollId` and records one delivery.
- **S8 (results):** `SurvivalMatchResultDto` / `SurvivalMatchCheckpointDto` are the contracts to accept (a
  `POST api/siege-survival/matches/{id}/result` that settles the per-kill rewards through the existing ledger with
  key `siege-match:{id}`); persistence tables are S8's migration.
- **S9 (authoring):** forms exist for every survival entity (18 seeds, names above); the web app needs routes for the
  `api/Survival*` child controllers (`by-parent/{id}`, POST with the parent id) and for
  `api/SiegeSurvival/scenarios/{id}/settings|readiness|preview` and `lobbies/{id}/settings`; the preview endpoint feeds
  the §11 per-round table. Readiness codes map 1:1 to S1's strings.
- **Coordinator:** the migration step above; apply `s4-plugin.patch` on knk-plugin `claude/siege-survival`
  (`git am`), push; apply `s4-workspace.patch` on workspace `main`; post the #41 comment.

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
