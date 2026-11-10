# Alpha test run 1 — package E: siege rewards (2026-10-27)

**Status:** In review. Pushed on `claude/alpha-run-1-rewards`: knk-plugin `3461708` (from `main` `3550cbb`),
knk-web-api `16a47f5` (from `master` `4d7a806`), knk-web-app `ead3b39` (from `main` `c3c0c9f`). Not merged, not
deployed, not live-tested
**Last updated:** 2026-10-27
**Issues:** [PandiO/knk-workspace#165](https://github.com/PandiO/knk-workspace/issues/165) (gate damage and capture
rewards), [#166](https://github.com/PandiO/knk-workspace/issues/166) (participation reward); parent
[#149](https://github.com/PandiO/knk-workspace/issues/149)
**Handoff:** [2026-10-27-alpha-run-1-p2-p3.md](../../../ai-agents/handoffs/2026-10-27-alpha-run-1-p2-p3.md) § 1 ·
**Findings:** [test-run-1-findings.md](test-run-1-findings.md) (2.2, 2.3) · **Design:**
[siege DESIGN.md § 7.6](../../../specs/siege-minigame/DESIGN.md#76-rewards-server-side-idempotent--fixes-n3n4n13)

Claude Code (background subagent of the P2/P3 coordinator session) implemented both issues as the developer decided
on 2026-10-27. Package F (#163/#164/#198/#199/#174) branches from these heads.

## 1. What the code did, and what changed

| Issue | Found on the default branches | Change |
|---|---|---|
| #165 gate damage | Gate HP loss already reached a `GateDamageSink` (KNG-34 statistics: direct hits and per-igniter fire shares), but only into player statistics, and only with `statistics.gates.enabled`. `complete` carried kills, deaths, streak and captures. Captures were already paid once per distinct objective. | **Plugin:** `SiegeGateDamageSink` credits the effective loss to the member behind it (player, projectile shooter, TNT source; fire per igniter, always tracked) in their running match, only for gates that match's lockdown holds (`SiegeGateController.lobbyIdOf`). `CompositeGateDamageSink` puts it next to the statistics sink (fire shares only to sinks that track fire). The total is kept per member in the new `SiegeMatchContributions` (on `SiegeMatch`) and survives a leave and rejoin. **API:** `gateDamage` in the participant result, stored as whole HP on `SiegeMatchParticipant.GateDamage`; per full `GateDamageRewardStep` HP (default 100) `CoinRewardGateDamage`/`ExpRewardGateDamage` (10 / 1). Captures unchanged. |
| #166 participation | No base reward. The statistics AFK tracker (`AfkTracker`, fed by `AfkActivityListener`) knows when a player went AFK (automatic AFK retroactively from the last activity). The match had no per-member time. | **Plugin:** every siege tick each member is observed with `StatisticsService.afkSince`; `SiegeMatchContributions` keeps active intervals and the member's match window (first join to the end or their leave; time away within the rejoin window stays in it). `complete` reports `activeSeconds` and `matchSeconds`. Without statistics every present second is active. **API:** `CoinRewardParticipation`/`ExpRewardParticipation` (25 / 3) when `activeSeconds ≥ ParticipationMinActivePercent` (75) % of `matchSeconds`; a missing match time pays only at 0 %. Leavers get nothing; no daily cap. |
| both | The scenario's reward fields were edited on the scenario FormWizard's Rewards step (form seed v1). | Six new `SiegeScenario` columns and three new participant columns (migration `AddSiegeGateDamageAndParticipationRewards`, existing scenarios get the defaults). Scenario read/upsert/runtime DTOs carry them; validation: amounts ≥ 0, step ≥ 1, percent 0–100. The reward DTO returns `gateDamage`, `gateDamageSteps`, `participation`, `activeSeconds`, `matchSeconds`; a repeat `complete` rebuilds them from the stored rows (idempotent as before). Form seed **SiegeScenario v2** adds the six fields to the Rewards step. In game the grey reward detail line also names "N gate damage" and "taking part" (the message rework is package F). knk-web-app: only `SiegeScenarioDto` (the wizard is data-driven). |

### Decisions taken here (review)

- **Reward shape for gate damage:** coins/XP per full step of N HP, with N per scenario (default 100 HP: a door has
  500 HP by default, so a door's worth is 5 steps). Whole HP only; leftovers below a step pay nothing.
- **Defaults** (applied to existing scenarios by the migration): gate damage 10 coins / 1 XP per 100 HP;
  participation 25 coins / 3 XP at 75 %. Set any amount to 0 to turn it off per scenario.
- **Match window** starts at the member's first join of the match (start, rejoin, admin join) and ends at the match
  end, or at their last leave for a leaver. A disconnected member's time away counts as not active, so a long
  disconnect can cost the participation reward even after a rejoin.
- **AFK source:** the statistics AFK tracker. With `statistics.enabled: false` or `statistics.afk.enabled: false`
  everyone present counts as active (no AFK signal exists then).
- **Gate damage** counts what the gate actually lost (after the siege rules refused defenders' hits and area gates).
  Damage to a match's gates by a member of another lobby isn't counted.
- **Robustness:** the API clamps `activeSeconds` to `matchSeconds` instead of refusing the completion (a 4xx is
  final for the plugin and would lose everyone's rewards); negative or NaN figures are still refused.

## 2. Tests

| Repo | Default branch (baseline) | `claude/alpha-run-1-rewards` |
|---|---|---|
| knk-plugin `gradle build -x deployToDevServer` (JDK 25 toolchain) | `3550cbb`: core 2378, api-client 282 (2 skipped), paper 2223 (18 skipped), 0 failures | `3461708`: core 2387, api-client 283 (2 skipped), paper 2227 (18 skipped), 0 failures; build green. GitHub Actions "Build" on the branch: success |
| knk-web-api `dotnet test` | **not run**: this sandbox can't reach NuGet (api.nuget.org and every mirror tried: proxy 403), so restore fails | **not run** (same). Syntax-checked with the SDK's Roslyn (14 changed files, 0 diagnostics). GitHub Actions "Migrations (fresh DB)" on `16a47f5`: success — the project **builds**, every migration applies to an empty MySQL 8, `has-pending-model-changes` finds none (hand-written snapshot/Designer match the model), down to 0 and up again |
| knk-web-app `npm run test:ci` (npm 11) | `c3c0c9f`: 205 suites, 1323 tests, all passed | `ead3b39`: 205 suites, 1323 tests, all passed; `npm run build` compiles (with warnings); `tsc --noEmit`: 9 errors, all in test files, same as the baseline |

New tests: `SiegeMatchContributionsTest` (core: active/AFK intervals, retroactive automatic AFK, rejoin, leaver, late
joiner, gate damage), `SiegeResultSpoolTest` (round trip with the new figures, an older spool file reads as 0),
`SiegeMatchesCommandApiImplTest` (payload and reward mapping), `CompositeGateDamageSinkTest` (paper). API (written,
**not run here**): `SiegeRewardCalculatorTests` (steps, configurable step, 75 % boundary, 0 %, leavers, all kinds add
up, negative amounts), `SiegeMatchServiceTests` (pay and store, idempotent repeat, leaver, clamp/validation),
`SiegeScenarioServiceTests` (store/defaults, validation).

**The developer (or CI with tests) must run `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` on
`16a47f5` before merging** (baseline on `master`: 4 known reds per the handoff). The `FormConfigurationSeedFilesTests`
cover the new seed v2 and its dependants.

Toolchain notes for this sandbox: the Gradle wrapper download and Maven Central are blocked too; the plugin was built
with the local Gradle 8.14.3 and a session-only init script that routes Maven Central and the plugin portal through
PaperMC's `maven-public` proxy (no repo file changed). The web app was installed with `CYPRESS_INSTALL_BINARY=0`.

## 3. Live checklist for test run 2

Before: apply the migration; import the seed **SiegeScenario - Default (seed v2)** (Import / seeds) and make it the
default; deploy the plugin with `statistics.enabled` and `statistics.afk.enabled` on (both default on).

1. Scenario wizard, Rewards step: the six new fields show with their defaults; save a change and reopen.
2. Attacker hits a closed, damageable selected gate (sword, arrows, TNT, a Fire Aspect fire) for well over 100 HP;
   at the end the reward detail line shows "N gate damage" and coins/XP go up by 10 / 1 per 100 HP. The match row
   (`GET api/siege-matches/{id}`) shows `gateDamage` on the participant.
3. A defender hitting their own gate, and anyone hitting an area gate, gets no gate damage.
4. A member who plays actively gets "taking part" (+25 coins / +3 XP); one who goes AFK (`/afk`, or idle past
   `statistics.afk.idle-seconds`) for more than a quarter of the match doesn't.
5. Disconnect and rejoin within the window: the time away counts as not active; the gate damage from before the
   disconnect still counts.
6. A member who `/siege leave`s gets nothing (as before), but their `gateDamage`/seconds are stored.
7. Captures still pay once per distinct objective (recapture ping-pong doesn't add).
8. Set a scenario's participation percent to 0: everyone still there at the end gets the participation reward.

## 4. Follow-ups and flags

- **API tests not run** in this session (see § 2). CI proved the build and migrations.
- Seed note: `SiegeObjective`/`SiegeSpawnpoint` seed files now point their location rules at v2's Town field. A
  database that imported them already keeps its copies, whose rules read v1's Town field: keep v1 or repoint those
  rules before deleting v1 (README in `Data/FormConfigurationSeeds`).
- Filed [#200](https://github.com/PandiO/knk-workspace/issues/200) (sub-issue of #149): knk-web-app `CI=true npm run
  build` fails on a pre-existing unused-argument lint warning, and `tsc` reports 9 pre-existing errors in test files.
- The plugin's `KnkSiegeRewards` (display-only, unused at runtime) does not carry the new amounts; nothing reads it.
