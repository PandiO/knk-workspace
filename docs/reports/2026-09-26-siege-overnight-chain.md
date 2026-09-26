# Siege overnight chain — morning report

**Status:** Finished. Link 1 ran every phase itself (6, 6b, 7a, 8b, 7b, 9 non-live) after the developer said to
continue past the plugin build blocker; Phase 10 not started, no next session launched. knk-paper code from 6b on is
**uncompiled**. Rules: `docs/ai-agents/handoffs/SIEGE_OVERNIGHT_CHAIN.md`.
**Last updated:** 2026-09-26 (link 1: final summary, Phase 9 done)

## Morning summary

**Build knk-paper first.** The cloud container can't reach `repo.papermc.io` or `maven.enginehub.org`, so nothing
under `knk-paper/` written tonight has been compiled (6b, 7a, 8b, 7b: roughly a dozen new classes plus edits to
`KnKPlugin`, `SiegeService`, `SiegeCommand`, `plugin.yml`). The rest is tested: knk-web-api
**718/723** (baseline 671/676, the same 5 known failures, +47 new), and knk-core **632** / knk-api-client **53**
(scratch build against Maven Central, all green). To let future cloud sessions build the plugin, allow those two
hosts in the environment's Network access settings.

| Phase | State | Branch heads after it | Details |
|---|---|---|---|
| 6 — Match persistence and rewards | done (web-api tested) | web-api `7d4fd44` | Phase 6 section |
| 6b — Plugin match recording | done (core/api-client tested; knk-paper uncompiled) | plugin `378f8a1` | Phase 6b section |
| 7a — Gate integration + area lockdown | done (web-api + core tested; knk-paper uncompiled) | web-api `07e0a5f`; plugin `16a1436` | Phase 7a section |
| 8b — Siege menus | done (web-api + core/api-client tested incl. seed contract test; knk-paper uncompiled) | web-api `78945ca`; plugin `0522e44` | Phase 8b section |
| 7b — Non-member gate view | done (knk-paper only, uncompiled, untested) | plugin `d475195` | Phase 7b section |
| 9 — Seeds and docs (non-live parts) | done (web-api tested) | web-api `ee29768`; workspace `af3576a` | Phase 9 section |

**Commits.** knk-web-api 7 (`b86d692`, `82b78a4`, `7d4fd44`, `9328c4e`, `07e0a5f`, `78945ca`, `ee29768`); knk-plugin 8
(`14ca0c8`, `a150719`, `378f8a1`, `b69b786`, `16a1436`, `901c599`, `0522e44`, `d475195`); knk-web-app none; workspace
docs/status commits on `main`. All on `claude/siege-minigame`; nothing merged, **no migrations** (none were needed),
nothing deployed.

**Review first (ranked; each is cheap to change):**
1. **Plugin write endpoints are open by default** (6 ★1): `[RequirePluginServiceKey]` only enforces when
   `Security:PluginServiceKey` is set; the plugin ships `api.auth.type: none`.
2. **Gate lockdown starts at the hub (T-15), not at round start** (7a ★1).
3. **A failed `createMatch` (after retries) runs the round unrecorded**, members told, no rewards (6b ★1).
4. **Siege XP uses the shared title path** with bracket bonuses and a TitleChanged notification (6 ★2).
5. **Right-click opens/closes locked gates for the owner alliance; `AnimateDuringSiege` is ignored** (7a ★3, ★2).
6. **Non-member view re-sends fakes every 5 ticks** (brief flicker while gates animate); pass-through by right-click,
   refused while the area is locked down (7b ★1-3). Fallback without code: `NonMemberGateView = PassThroughOnly`.
7. **Siege hub tile unchanged** (8b ★1); objective banners = holder team banner (8b 3).
8. **Capture defaults on the model are now 10/2/10 (D 6/3/6); `legacyDefaults()` stays 5/2/5** (9 decision 1).

**Smoke-test order (one pass, 2-3 accounts):**
1. Pull both `claude/siege-minigame` branches. knk-plugin: `./gradlew build -x deployToDevServer`. Fix any compile
   errors first (the untested trunk merge `d41be49` is underneath too). knk-paper tests: Phase 5 baseline 259.
2. knk-web-api: `dotnet run` (no migration to apply). Swagger: plan → "Phase 6 status" manual steps 1-5
   (`api/siege-matches` create/start/complete/history).
3. `./gradlew :knk-paper:dev`, start the dev server. Menus seeded and valid (8b step 1); the new disabled `example`
   lobby exists (Phase 9), and the dev DB's capture values are unchanged.
4. Play one full match on `test-cinix`: `/siege` opens the overview menu, vote/join through it (8b); at the hub
   the gates and area lock down (7a); owner alliance opens/closes gates, only enemies damage them; the spawn picker
   menu on respawn (8b); a non-member watches from outside (7b: pre-lockdown gates, collision, pass-through).
5. Match end: reward lines in chat, the match row + balances/XP in the DB (6b a), gates restored (7a), the
   non-member sees the real gates within ~5 s (7b).
6. Failure paths: API down at match end → spool file → replay on the API's return (6b b); kill the server
   mid-match → on start the spool replays, unfinished matches abort, gates restore (6b c, 7a crash step); `/siege
   admin stop` → row `Aborted`, no balances (6b d).
7. `NonMemberGateView = PassThroughOnly` + `/siege admin reload` between matches (7b step 6).
8. Optional: walk `docs/guides/authoring-a-siege-scenario.md` with a second scenario.

**Next link / blockers.** No next session started: Phase 9 is the charter's last link and Phase 10 is excluded. No
absolute blocker was hit after the developer's go-ahead; the only open blocker is the plugin build (above).

## Phase sections

### Phase 6 — Match persistence and rewards (link 1): partial, 6a done, 6b blocked

**Setup facts.** .NET 8 isn't preinstalled and `dotnet-install.sh` (builds.dotnet.microsoft.com) is blocked;
`apt-get install dotnet-sdk-8.0` from the Ubuntu archive works. Java 21 is present. The plugin build fails at
dependency resolution (403 from the egress proxy for `repo.papermc.io`; `maven.enginehub.org` is blocked too). I
briefly started building paper-api from PaperMC's GitHub source to work around it, then stopped that as routing
around the org policy; nothing from it was kept. Both siege branches had already absorbed trunk (web-api `6a480e6`,
plugin `d41be49`) before the chain started, so no trunk merge was needed.

**Commits.** knk-web-api `claude/siege-minigame`: `b86d692` (extract `TitleProgression`), `82b78a4` (match
service/controller/repository/DTOs, reward calculator, opt-in service key), `7d4fd44` (tests). knk-plugin: none.
Workspace: this report, the plan's "Phase 6 status" block, the Phase 6b handoff, `ACTIVE_SESSIONS.md`.

**Tests vs baseline.** knk-web-api: baseline 671/676 at `6a480e6` (not the charter's 633 - the menu-content merge added
tests), now **704/709**: 33 new, all green; the same 5 known failures by name (ClientActivityStore, 2× PathResolution
`Town.*`, FieldValidation ConditionalRequired, FormSubmissionProgressRepository). knk-plugin: no baseline could be
measured (build blocked). GitHub Actions "Migrations (fresh DB)" on `7d4fd44`: **success** (run 19; no new migration).

**What exists now (web-api).** `api/siege-matches` (+ `api/SiegeMatches`): create, start, participants/{userId}/left,
complete (rewards per DESIGN §7.6 in one transaction with a match row lock; a repeat call returns the stored result),
abort, abort-unfinished (startup recovery), GET history and GET {id}. Details, request shapes and 11 decisions:
plan → "Phase 6 status".

**Flagged decisions** (full list in the plan; ★ = review first): ★1 opt-in service key; ★2 shared title path with
bracket bonuses + notification; 3 no AuditLog; 4 retry/replay rules (no-op repeats, 409 on conflicting final
states); 5 complete accepted on a Created match, unreported participants closed at the end time; 6 last entry per
objective = end holder; 7 complete rejects abort reasons; 8 extra endpoints (`GET {id}`, `abort-unfinished`,
`status`/`limit`); 9 negative amounts → 0; 10 gates untouched (Phase 7); 11 validation.

**Discrepancies.** The web-api `.sln` points at `tests/` but the folder is `Tests/` (breaks `dotnet build` of the
solution on Linux; the repo `CLAUDE.md`'s test path is wrong there too). Charter §9's web-api baseline is stale.

**Live checklist (short).** Plan → "Phase 6 status" → "Manual live verification": steps 1-5 now (Swagger), 6 after
6b (a played match matches its rows and balances), 7 optional (service key).

**Risks.** The MySQL row lock (`SELECT … FOR UPDATE` under READ COMMITTED) is only exercised live. The plugin trunk
merge `d41be49` is unverified. 6b must replay the result spool **before** calling `abort-unfinished` on enable.

**Next link.** Not started: every remaining phase needs a plugin build, and the environment blocks it for any new
cloud session too. Handoff written for 6b: `docs/ai-agents/handoffs/2026-09-26-siege-phase-6b.md` (it first checks
the build and stops cleanly if it's still blocked; after 6b it hands over to 7a).

### Phase 6b — plugin wiring (link 1, continued on the developer's go-ahead)

**Commits.** knk-plugin `claude/siege-minigame`: `14ca0c8` (core: `SiegeMatchRecorder`, `SiegeResultSpool`, port +
records), `a150719` (api-client: `SiegeMatchesCommandApiImpl`), `378f8a1` (paper wiring). **knk-paper part not
compiled** - build it first.

**Tests.** Scratch build (real sources, Maven Central only; knk-core minus its 9 Bukkit-importing files): knk-core
606 → 622, knk-api-client 43 → 48 (2 skipped), all green. knk-paper: not run.

**Flagged decisions** (full list: plan → "Phase 6b status"): ★1 a failed `createMatch` (after retries) runs the
round unrecorded, members told; 2 unfinished-match recovery waits while the spool holds a result; 3 logging
placeholder and `ProvisionalRewardCalculator` kept but unused; 4-7 minor.

**Live checklist.** Plan → "Phase 6b status" → (a) play to the end, (b) API down → spool file → replay,
(c) kill mid-match → startup recovery, (d) admin stop → Aborted.

**Risks.** Uncompiled knk-paper edits (small: `KnKPlugin.initializeSiege`/`onDisable`, `SiegeService` reward lines,
`LoggingSiegeMatchesCommandApi.abortUnfinished`); the untested `d41be49` trunk merge underneath.

### Phase 7a — gate integration + area lockdown (link 1)

**Commits.** knk-web-api: `9328c4e` (gate-lockdown/-restore/restore-stale-gates/gate-snapshots endpoints,
runtime-config `areaGateStructureIds`, overrides endpoint permission), `07e0a5f` (tests). knk-plugin: `b69b786`
(core `SiegeGatePlan`, gate port/records, api-client impl), `16a1436` (paper: `SiegeGateController`,
`SiegeGateListener`, `SiegeAreaLockdown`(+listener), observer hooks, wiring). **knk-paper not compiled.**

**Tests.** web-api 710/715 (+6 new, same 5 known failures). Scratch build: knk-core 626 (+4), knk-api-client 50
(+2), all green. No migration.

**Flagged decisions** (full list: plan → "Phase 7a status"): ★1 gate lockdown at the hub (T-15), not T-0; ★2
AnimateDuringSiege not honoured (every change animates); ★3 right-click opens/closes for the owner alliance; 4 the
match proceeds if persisting the lockdown fails; 6 restore respawn/health write race; 8 area lockdown only with
districts, bounding-box exit point, plugin teleports exempt.

**Live checklist.** Plan → "Phase 7a status" → 7 steps (lockdown at hub, control, damage, capture hand-over, restore,
crash recovery, area lockdown).

**Risks.** Uncompiled and the largest knk-paper change so far (4 new classes); gate animation interplay (open/close
while animating); WorldGuard queries on every block-changing move while a lockdown is active.

### Phase 8b — siege menus (link 1)

**Commits.** knk-web-api: `78945ca` (`MenuTemplateSeed.Siege.cs`: `siege.overview`, `siege.information`,
`siege.spawnpoint`, + tests/export). knk-plugin: `901c599` (knk-core `core.siege.menu` views + ids; knk-api-client
`SiegeMenuSeedContractTest` with the exported `menu/siege-seeds.json`), `0522e44` (paper: `SiegeMenuFeature`,
`SiegeMenuSnapshots`, `SiegeMenuBridge`, `/siege` and the spawn picker open the menus). **knk-paper not compiled.**

**Tests.** web-api 716/721 (+6, same 5 known failures). Scratch build: knk-core 632 (+6), knk-api-client 53 (+3), all
green. The contract test runs the real menu validator over the exported seeds against the knk-core view classes
(checked to fail on a misspelled getter), so seed ↔ view drift is caught without a server.

**Flagged decisions** (plan → "Phase 8b status"): ★1 hub tile unchanged (already opens `siege.overview` once it
validates; the "open own siege" hint lives on the overview header); 2 list getters for kind-dependent lore, one
`siege.vote` action; 3 objective banners = holder team banner, no gate status; 4 "Rank" = premium tier; 5 no overview
filler panes.

**Live checklist.** Plan → "Phase 8b status" → 6 steps (seeds created/validated, overview, votes/join/leave, body,
spawn picker, `/siege`).

**Risks.** Uncompiled knk-paper glue (3 new classes + `SiegeService` additions); `lobbyChanged` repaints every open
siege menu on each change (cheap at MVP scale).

### Phase 7b — non-member gate view (link 1)

**Commits.** knk-plugin: `d475195` (`SiegeGateViewService`, `GateViewCells`, controller/listener/area-lockdown hooks,
wiring). No web-api change. **Not compiled, not tested** (no pure logic to unit-test; needs two players live).

**Flagged decisions** (plan → "Phase 7b status"): ★1 fakes re-sent on the next 5-tick pass after a real change (brief
flicker during animations, no gate-engine hooks); ★2 pass-through by right-click; 3 pass-through refused while the
area is locked (so it rarely applies - follow-up); 4 no chunk-load hook (range re-entry re-sends).

**Live checklist.** Plan → "Phase 7b status" → 6 steps (member + non-member side by side; `PassThroughOnly` switch).

**Risks.** The riskiest phase (charter): per-player block views under animation; if it misbehaves, set
`NonMemberGateView = PassThroughOnly` - the degrade path needs no code change.

### Phase 9 — seeds and docs, non-live parts (link 1)

**Commits.** knk-web-api: `ee29768` (`SiegeConfiguration` capture defaults A1 10 / IV A2 10; `SiegeLobbySeed`: a
create-only disabled `example` lobby, wired in `Program.cs`; tests). Workspace: `af3576a` (new
`docs/guides/authoring-a-siege-scenario.md`, `vision.md` §7 status lines, `specs/README.md`, plan "Phase 9 status").

**Tests.** web-api 718/723 (+2 new, 3 assertions moved 5 → 10; same 5 known failures). No migration: the defaults are
C# initializers only, so they reach a fresh DB's configuration row, not the dev DB's existing one.

**Flagged decisions** (plan → "Phase 9 status"): 1 only the two differing capture values changed,
`legacyDefaults()` untouched as the charter says; 2 the example lobby has no rotation (a seed can't know a scenario
id). Note: the seed is create-only by key, so deleting the `example` row brings it back on the next start. Rename
its key instead.

**Live checklist.** Dev DB: one new disabled `example` lobby at the next API start, nothing else changes. Playtesting
and balancing are the developer's.

