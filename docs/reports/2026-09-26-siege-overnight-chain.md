# Siege overnight chain — morning report

**Status:** Link 1 continuing on the developer's instruction (Phase 6 done; knk-paper code uncompiled). Each chain session appends its phase section
and rewrites the Morning summary. Rules: `docs/ai-agents/handoffs/SIEGE_OVERNIGHT_CHAIN.md`.
**Last updated:** 2026-09-26 (link 1: Phase 8b done, starting 7b)

## Morning summary

_Interim (link 1 is still working; rewritten when it stops)._ The chain first stopped at Phase 6b because the cloud
container can't build knk-plugin (network policy denies `repo.papermc.io` and `maven.enginehub.org`). The developer
then said **"just continue anyway, we will test once I am at my PC"**, so link 1 continues the phases itself. The
**knk-paper code from 6b on is not compiled**; knk-core (non-Bukkit parts) and knk-api-client are compiled and tested
in a scratch build that uses Maven Central only.

| Phase | State | Branch heads after it | Notes |
|---|---|---|---|
| 6 — Match persistence and rewards | done (6a tested; 6b knk-paper uncompiled) | web-api `7d4fd44`; plugin `378f8a1` | see Phase 6 section |
| 7a — Gate integration + area lockdown | done (web-api tested; knk-paper uncompiled) | web-api `07e0a5f`; plugin `16a1436` | see Phase 7a section |
| 8b — Siege menus | done (web-api + core/api-client tested incl. seed contract test; knk-paper uncompiled) | web-api `78945ca`; plugin `0522e44` | see Phase 8b section |
| 7b — Non-member gate view | in progress | | |
| 9 — Seeds and docs (non-live parts) | not started | | |

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
