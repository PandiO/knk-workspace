# Weekly docs drift check — 2026-11-22

**Date:** 2026-11-22 · **Run by:** scheduled Claude Code session (weekly docs check, PandiO/knk-workspace#292)
**Window:** merges and direct commits to the default branches from 2026-11-15 to 2026-11-22
**Checked against:** knk-web-api `main` `75b84343`, knk-web-app `main` `31a6896d`, knk-plugin `main` `2411d785`;
knk-workspace `main` `4796bd17` and `next` (feature docs live on `next` under the branch model)

## 1. Summary

1. **Gaps found:** 2.
   - The release of 2026-11-19 (overview map; API and web app `v0.4`, plugin `v0.3`) has no CHANGELOG section. The § 5.3 migration list still calls its migration unreleased, and the release-tag table doesn't have it. Filed as **#998**.
   - Plugin configuration reference § 2.1 still marks five plugin `v0.2` keys (2026-11-15) as not on trunk. Added to the existing **#630** as a comment.
2. **Debt cap: exceeded.** 33 open `documentation` issues (cap: five). None is older than two weeks; the oldest are 12 days old (#293, #303, #304, #316).
3. **Docs sessions started: none.** This run had no `create_session` tool (step 6 of the routine), so it could not start sessions for the oldest unworked issues. See § 5.

## 2. Merges checked

The knk-web-api default branch is `main` (renamed from `master` 2026-11-14), not `master` as the routine prompt says.

| Date | Repos (PRs) | Change | Changelog | Config / settings / migrations | Issue | Register / guides index |
|---|---|---|---|---|---|---|
| 2026-11-19 | API, web app, plugin ("Promote the overview map to main (#732)"; API #45–#48, web app #50–#53, #55, #59, plugin #76, #77, #79, #93) | Overview map promoted to trunk alone; tags API `v0.4`, web app `v0.4`, plugin `v0.3` | **Gap:** entries for each link (L1–L9, F1, F2) with Admin steps exist, but they are still under "Unreleased", and there is no release section → #998 | Plugin `map.reporting.enabled` / `interval-ticks`: plugin configuration reference § 4.29 and § 2.1 ("on trunk (knk-plugin v0.3)") OK. API `Map:*`, `Map:LivePlayers:*`, `Map:GateCommands:*`, `RateLimiting:Map:*`: production installation § 4.3 OK. Migration `AddMapRegionOutlines`: **gap**, production installation § 5.3 still lists it under "Waiting in `next` (not released)" → #998. `DEPLOYMENTS.md` release-tag table ends at v0.3 → #998 | #732 closed (11 of 11 sub-issues done); docs sub-issue #766 closed; screenshots follow-up #857 open | Register row: trunk, live-tested 2026-11-19 (on `next`) OK; guides index rows for player and admin guides and smoke test OK |
| 2026-11-16 | API #43 | MySQL tests in CI (#419) | Entry present | CI workflow only; `ci.md` updated | #419 closed | n/a |
| 2026-11-16 | API #39, web app #46, plugin #53 | GitHub Actions moved off Node.js 20 (#426) | Entry present | CI only | #426 closed | n/a |
| 2026-11-16 | API #41, web app #48, plugin #55 | Agent files refresh (`AGENTS.md`/`CLAUDE.md`) | Agent workflow entries 2026-11-16 present | none | n/a | n/a |
| 2026-11-16 | plugin #59 | paper-boot log check flake (#586) | Entry present | test tooling only | #586 closed | n/a |
| 2026-11-15 | API #38, web app #45 (v0.3); plugin #44 (v0.2, `f8f7fb2e`) | Promotions of `next` | v0.3 section present (docs check #577). Plugin `v0.2` section missing: already tracked in #630 | **Gap:** plugin configuration reference § 2.1 still says #574, #485 "in review, not in `next` yet" and #522, #521, #421 "in `next`, not on trunk yet" → comment on #630 | v0.3 features closed at promotion | v0.3 rows updated by #577 |

knk-workspace `main` in the window has board and chain bookkeeping only. The agent workflow changes of 2026-11-16 (#416, #417) have their changelog entries. The seed (knk-dev-db-seed) was not touched by any merge, so it was not attached.

## 3. Gaps and issues filed

1. **#998** (new): the release of 2026-11-19 (API and web app `v0.4`, plugin `v0.3`) needs:
   - a `## v0.4 — 2026-11-19` CHANGELOG section with Admin steps for the whole release, with the overview map entries moved out of "Unreleased";
   - production installation § 5.3: `AddMapRegionOutlines` moved out of the waiting list;
   - `DEPLOYMENTS.md`: the new tags, and a fix for the "plugin not in this release" wording of v0.3, which clashes with the plugin's own `v0.3` tag.
2. **#630** (comment): plugin configuration reference § 2.1 rows of the plugin `v0.2` keys (#574, #485, #522, #521, #421) are added to its scope. Ten CHANGELOG entries on `next` still say "on the trunk when the developer promotes `next`".

## 4. Open `documentation` issues

33 open, including #998 filed today. "Session" means a docs session has worked on the issue (from the sessions board and the 2026-11 archive). "Filed only" means the issue was filed by a feature or docs session and has not been worked on since.

| Issue | Title (short) | Age (days) | Session |
|---|---|---|---|
| #998 | Release v0.4 / plugin v0.3 docs | 0 | filed today |
| #996 | guidance-v2 default in navigation guides | 0 | **in progress** (on the board) |
| #974 | landmark and production area drawn regions | 0 | filed only (2 comments) |
| #972 | display stalls live check and screenshots | 1 | filed only (needs live server) |
| #931 | town logistics P9 at promotion | 1 | filed only (waits for promotion) |
| #925 | player harvesting P8 at promotion | 1 | filed only (waits for promotion) |
| #917 | item delivery P7 at promotion | 1 | filed only (waits for promotion) |
| #910 | siege shop guides live check | 1 | filed only (needs live server) |
| #905 | terminals P6 at promotion | 2 | filed only (waits for promotion) |
| #892 | transport P5 at promotion | 2 | filed only (waits for promotion) |
| #884 | yield areas P4 at promotion | 2 | filed only (waits for promotion) |
| #857 | overview map screenshots | 2 | filed only (needs the developer's shots) |
| #843 | production engine P3 at promotion | 3 | filed only (waits for promotion) |
| #832 | production world P2 at promotion | 3 | filed only (waits for promotion) |
| #728 | plugin-scenarios § 1 remaining scenarios | 4 | filed only |
| #727 | `npc.navigation` config.yml comments after C1/E1 | 4 | filed only |
| #660 | NPC Phase 4c verified status | 6 | filed only (waits for the developer's smoke tests) |
| #630 | CHANGELOG v0.1/v0.2 and release markers | 7 | filed only |
| #590 | NPC Phase 4b verified status | 7 | filed only (waits for the developer's tests) |
| #551 | Role permissions L5 essential docs | 7 | filed only |
| #475 | economy guides live check | 8 | filed only (needs live server) |
| #474 | ranks/chat and moderation guides live check | 8 | filed only (needs live server) |
| #473 | account and invitations screenshots | 8 | filed only (needs live server) |
| #472 | navigation and teleports in-game check | 8 | filed only (needs live server) |
| #453 | CHANGELOG entries alpha run 1 packages E, F, G, I | 9 | filed only |
| #443 | move knk-web-api `Prompts/*.md` into knk-workspace | 9 | filed only |
| #433 | header clean-up and local paths | 9 | filed only |
| #428 | CHANGELOG entry Siege gate approach on compass (#176) | 9 | filed only |
| #347 | staff web app guide, smoke-run corrections and screenshots | 10 | session (desk part done, PR #435; live part open) |
| #316 | in-game commands reference live check | 12 | session (desk part done, PRs #434, #439; live part open) |
| #304 | move component-repo docs into knk-workspace | 12 | session (`status:in-review`, waits for promotion of `next`) |
| #303 | deployment log and deploy tags | 12 | session (PR #446; waits for the developer) |
| #293 | player and admin guide coverage (umbrella) | 12 | session (umbrella; waits for #316) |

**Debt cap: exceeded.** The cap is more than five open `documentation` issues, or one older than two weeks; there are 33. None is older than 14 days yet, but #293, #303, #304 and #316 reach 14 days on 2026-11-24. About half wait on something outside a docs session: a promotion of `next` (8 "at promotion" issues), a live server or screenshots (8), or the developer's tests (2). The desk-only backlog that a docs session can close today is #630, #998, #453, #428, #443, #433, #551, #727 and #728.

## 5. Docs sessions

Step 6 asks for docs sessions on at most two of the oldest open issues that no session is working on: #428 and #433 (9 days, filed only, desk-only). This session's tool set had no `create_session` (only GitHub and PR-subscription tools), so it **started no sessions** and did not comment on those issues.

Recommended next sessions, oldest desk-only first:
1. #428 together with #453 (both CHANGELOG backfills).
2. #630 together with #998 (both release sections and markers; one session can do them in one pass).

## 6. Notes for the routine

1. The prompt names knk-web-api's default branch `master`; it has been `main` since 2026-11-14.
2. Feature docs (CHANGELOG, register, guides) are updated on knk-workspace `next`, so the check reads them from `next`, not from `main`.
3. The run needs `create_session` (and `add_repo`) to do steps 6 and the seed check; they were not available this time.
