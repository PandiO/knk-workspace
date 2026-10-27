# Alpha test run 1 — package H: gate pass-through styles (2026-10-27)

**Status:** In review — pushed on `claude/alpha-run-1-gates`: knk-plugin `e7c5a93` (from `main` `3550cbb`),
knk-web-api `87f6ab0` (from `master` `4d7a806`), knk-web-app `0af1dbf` (from `main` `c3c0c9f`); not merged, not
deployed, not live-tested. knk-web-api **not built or tested here** (see Tests).
**Last updated:** 2026-10-27
**Issue:** [PandiO/knk-workspace#167](https://github.com/PandiO/knk-workspace/issues/167) (P2); parent
[#149](https://github.com/PandiO/knk-workspace/issues/149)
**Handoff:** [2026-10-27-alpha-run-1-p2-p3.md](../../../ai-agents/handoffs/2026-10-27-alpha-run-1-p2-p3.md) § 1 (#167) ·
**Findings:** [test-run-1-findings.md](test-run-1-findings.md) (3.2)

Claude Code (subagent of the coordinator session) implemented the coordinator default of handoff § 1, which is
marked **for the developer's review**: the developer gave no preference.

## 1. What was there

`GatePassThroughService.dispatch` (knk-plugin) supported three styles, chosen only by the player's
`User.GatePassThroughMethodDefault` (`/gate passthrough`): `DEFAULT` (animated open, auto-close after
`PassThroughDurationSeconds`), `INSTANT_OPEN` (walk-path: blocks in the player's way removed and put back; needs
`knk.gate.passthrough.instant`, otherwise silently `DEFAULT`) and `TELEPORT`. A door had no say in the style: only
`AllowPassThrough` and the duration (both structure-overridable). Snap (issue style b) did not exist.

## 2. What changed

**Rule** (`knk-core/.../gates/GatePassThroughStyles.resolve`): every door offers a set of styles plus a default style.
The player's preference is used when the door offers it (walk-path also needs the instant node or `knk.gate.admin`);
otherwise the door's default; if that is walk-path and the player may not use it, the first offered style of animated,
snap, teleport; else animated (the pre-#167 fallback). The door's default style always counts as offered.
`GatePassThroughRules.canPass` (who may pass at all, used by navigation) is unchanged.

| Repo | Change |
|---|---|
| knk-web-api | `GatePassThroughMethod.Snap = 3`. `GateDoor`: `AllowAnimatedPassThrough` (default true), `AllowSnapPassThrough` (false), `AllowWalkPathPassThrough` (true), `AllowTeleportPassThrough` (true), `DefaultPassThroughMethod` (string column, `Default`). `GateStructure`: a nullable `…Override` of each, set/cleared through the existing `PATCH api/GateStructures/{id}/overrides` (existing access rule; no new endpoint). DTOs, AutoMapper (left-out values keep the defaults; structure overrides ignored on the general write path as before). Migration `20261027150000_AddGatePassThroughStyles` (hand-written with its Designer, see Tests): existing doors get exactly the pre-#167 styles and the animated default. GateDoor form seed **v4** (new `configurationGuid`, derived GUIDs; README updated). Mapping tests. |
| knk-plugin | `GatePassThroughMethod.SNAP` (wire `Snap`). `CachedGateDoor`/`CachedGateStructure` hold the styles and overrides (`getEffectiveAllowedPassThroughMethods`, `getEffectiveDefaultPassThroughMethod`); `GateLoaderAdapter` maps them (a door from an API without the fields keeps the pre-#167 styles). Snap: `GateManager.snapGate(id, open)` starts OPENING/CLOSING with a start time one whole animation in the past, so `GateAnimationTask` finishes it on its next tick through its normal end path (entity evacuation, resting frame, state persist); `GatePassThroughService` opens it at once and the auto-close task snaps it shut. `GatePassThroughConsequenceListener.resolveMode` uses the new rule. Commands: `/gate passthrough snap`; `/gate override <structure> passanimated\|passsnap\|passwalkpath\|passteleport <true\|false\|clear>` and `passdefault <default\|snap\|instant\|teleport\|clear>`; `/gate info` lists them, `/gatedoor info` shows a door's effective styles. |
| knk-web-app | Gate Door object config: four style toggles and the default style; DTO types (`GateDoorDto`, `GateStructureDto`, overrides DTO); `GatePassThroughMethod` type gains `'Snap'`. The User form's pass-through enum reads its options live from the API metadata, so it offers Snap once the API is deployed; there is no separate player-facing web picker. |

Unchanged on purpose: the siege defender pass-through (#154, `SiegeGateController.openClosedGate`, animated) and the
non-member carry (`SiegeGateController`, teleport) don't go through the player/door style rule. Client-only blocks for
snap/walk-path (#168) are out of scope (skipped, handoff § 1).

## 3. Decisions to review (developer)

1. **The coordinator default itself** (handoff § 1): allowed set + default per door, player preference when offered.
2. **Storage**: four booleans plus one enum per door (and nullable per-style overrides on the structure), not a flags
   column — it fits the form system (no multi-select enum field) and the existing per-field override pattern.
3. **Migration defaults**: snap off on existing doors (it is new); animated, walk-path and teleport on, default animated
   → behaviour unchanged until a door is edited. A new door created without the fields gets the same.
4. **Fallback when walk-path is the door default but the player lacks the instant node**: first offered of animated,
   snap, teleport, else animated.
5. **Snap while the door animates**: a snap right-click on an OPENING/CLOSING door jumps it to open (someone else's
   animated pass-through is cut short). The animation task's open/close sound still plays once on a snap.
6. Structure-override editing is in game (`/gate override`) and via the API; the web app has the DTO but (as for the
   other overrides) no override UI.

## 4. Tests

| Repo | Baseline (default branch) | Branch |
|---|---|---|
| knk-plugin (`gradle build -x deployToDevServer`, local Gradle 8.14.3 + mirror init script) | BUILD SUCCESSFUL, 4883 tests, 0 failed, 20 skipped | BUILD SUCCESSFUL, 4895 tests (+12), 0 failed, 20 skipped |
| knk-web-app (`npm run test:ci`, npm 11) | 205 suites, 1323 tests passed | 205 suites, 1324 passed (+1) |
| knk-web-api (`dotnet test`) | **not run**: `api.nuget.org` is refused by this container's egress policy (403 on CONNECT), so `dotnet restore` fails | **not run** (same); the changed files pass a Roslyn syntax check only |

So the API change (incl. the hand-written migration Designer, copied from the updated model snapshot, and the two new
mapping tests) needs `dotnet build`/`dotnet test` on a machine with NuGet before merge; `dotnet ef migrations add` was
not available to generate the migration. The known 4 reds on master apply.

## 5. Live checklist for test run 2

1. Apply the migration; import GateDoor seed v4 and make it the default. An existing door's form shows Animated,
   Walk-path, Teleport on, Snap off, default Animated; right-clicks behave as in run 1.
2. Edit a door: only Snap on, default Snap. `/gate passthrough teleport`, right-click: the door snaps open (no
   animation), stays open for the pass-through time, snaps shut. A player standing in the doorway is moved out on close.
3. `/gate passthrough snap` at a door that doesn't offer snap: the door's default style is used.
4. Walk-path as door default for a player without `knk.gate.passthrough.instant`: they get another offered style.
5. `/gate override <gate> passteleport false` and `passdefault snap`: every door of the gate follows; `/gate info`
   lists the overrides, `/gatedoor info` the effective styles; `clear` restores the doors' own settings; a server restart
   (reload from the API) keeps them.
6. Siege: defenders still open their gate animated (#154); non-members are still teleported through locked doors.
7. Web app: User form offers Snap for a player's pass-through method; the Gate Door object config shows the toggles.
