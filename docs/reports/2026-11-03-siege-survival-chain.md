# Siege Survival implementation chain — progress report

**Status:** Chain running — S1 and S2 started 2026-11-03; G1, S3 and S4 wait for merges (see "Waiting for the developer")
**Last updated:** 2026-11-03
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
- **Flags needing a decision:** none yet (links add `S1-n`, `S2-n`, … in their blocks).

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
| S1 | Survival core logic (waves, kills, round delay, stuck rules, end conditions, scaling presets, monster mix, specials, repair maths, spawn selection, rewards, Mystery Box pick) | plugin `claude/siege-survival`, `knk-core/.../core/survival/` only | in progress | 2026-11-03 | — | — |
| S2 | NPC platform §5b core: combat and speed profiles, modifier pipeline by source, clamping with a report | plugin `claude/siege-survival`, `knk-core/.../core/npc/` only | in progress | 2026-11-03 | — | — |
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
