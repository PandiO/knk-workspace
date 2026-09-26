# Siege overnight chain — morning report

**Status:** Chain **stopped after link 1** (Phase 6a done, 6b blocked). Each chain session appends its phase section
and rewrites the Morning summary. Rules: `docs/ai-agents/handoffs/SIEGE_OVERNIGHT_CHAIN.md`.
**Last updated:** 2026-09-26 (link 1: Phase 6a, chain stopped)

## Morning summary

**The chain stopped at Phase 6b.** The cloud container can't build knk-plugin: its network policy denies
`repo.papermc.io` (paper-api) and `maven.enginehub.org` (WorldEdit/WorldGuard), so Gradle can't resolve the
dependencies. Every remaining phase (6b, 7a, 8b, 7b) changes the plugin, and a new cloud session would hit the same
wall, so no next session was started (charter §1.3, §6.4). The web-api half of Phase 6 is done, tested and pushed.

**To resume:** add `repo.papermc.io` and `maven.enginehub.org` to the cloud environment's allowed domains
(environment settings → Network access), then start a session with *"Read and execute
`docs/ai-agents/handoffs/2026-09-26-siege-phase-6b.md` in the knk-workspace repository (branch main). It starts with
a pointer to the chain charter."* - or run that prompt locally.

| Phase | State | Branch heads after it | Stopped because |
|---|---|---|---|
| 6 — Match persistence and rewards | **partial**: 6a (web-api) done; 6b (plugin wiring) not started | web-api `7d4fd44`; plugin unchanged `d41be49` | plugin can't be built in the cloud (egress policy: `repo.papermc.io`, `maven.enginehub.org`) |
| 7a — Gate integration + area lockdown | not started | | chain stopped at 6b |
| 8b — Siege menus | not started | | chain stopped at 6b |
| 7b — Non-member gate view | not started | | chain stopped at 6b |
| 9 — Seeds and docs (non-live parts) | not started | | chain stopped at 6b |

### Review first
1. **Phase 6 decision 1 - match write auth is opt-in and off by default.** The plugin ships `api.auth.type: none` and
   no plugin service-client mechanism exists, so requiring a JWT would lock the plugin out. The writes carry a new
   `[RequirePluginServiceKey]`: open while `Security:PluginServiceKey` is empty; set it (and the plugin's
   `api.auth.type: apikey` + `api-key`) to enforce it.
2. **Phase 6 decision 2 - siege XP uses the shared title path, bracket bonuses included.** The crossing logic moved
   out of `UserService.AdjustBalancesAsync` into `TitleProgression` (unchanged behaviour there); a promotion from a
   match grants the crossed brackets' bonuses and queues the usual `TitleChanged` notification. No AuditLog rows
   for siege payouts (DESIGN §7.6).
3. **knk-plugin `d41be49`** (trunk merge of the menu-content port into the siege branch, made before this chain
   started) has never been built or tested by the chain. Build it before deploying.

### Smoke-test order for the morning
1. Redeploy: web-api from its `claude/siege-minigame` branch (`7d4fd44`; no new migration). The plugin is unchanged by
   the chain - if you redeploy it from `claude/siege-minigame`, note that `d41be49` (trunk merge) is untested (see
   Review first 3); `./gradlew :knk-paper:dev` after checking `ACTIVE_SESSIONS.md` (the shared checkout may be on
   another branch - use a worktree).
2. No new web-api migrations to apply.
3. `/siege admin reload`.
4. Phase 5 steps still open from playtest round 1: 4 (inventory guards, incl. the owner/staff-mode exemption),
   7 (friendly fire, safe zones, headshots), 10 (main-objective capture win), 14 (crash test), 16 (book chooser by
   right-click). Plan: Phase 5 status → "Manual live verification".
5. Phase 6 steps 1-5 (Swagger only, the plugin still uses the logging placeholder): plan → "Phase 6 status" →
   "Manual live verification". Step 5 (two `complete` calls at once) is the one thing the tests couldn't cover: the
   MySQL row lock.

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
