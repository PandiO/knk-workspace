# Staff web app follow-ups chain — progress report

**Status:** Running (2026-11-14) · **Last updated:** 2026-11-14

**Issue:** [PandiO/knk-workspace#517](https://github.com/PandiO/knk-workspace/issues/517), links
[#408](https://github.com/PandiO/knk-workspace/issues/408) (L1),
[#50](https://github.com/PandiO/knk-workspace/issues/50) (L2),
[#407](https://github.com/PandiO/knk-workspace/issues/407) (L3)
**Charter:** [handoffs/STAFF_WEB_FOLLOWUPS_CHAIN.md](../ai-agents/handoffs/STAFF_WEB_FOLLOWUPS_CHAIN.md).

## 1. Waiting for the developer

1. Nothing yet. L2 (#50) will ask the developer two questions inside the link before coding (group-level audit,
   plugin freshness).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started | Test rule |
|---|---|---|---|---|---|---|---|
| L1 PermissionGrant table | #408 | Merged into next (2026-11-14) | api `6e34af5`, app `110d5f2`, ws `b6547485`; next: api `2425f181`, app `9a29623a`, ws `aef2f99f` | knk-web-api#30, knk-web-app#29, knk-workspace#529 | green on the PRs; next running | create_session session_01R1w2Ut6UjJQM8QpXM4o6co | automated first, `main` `aa4208b3` (unchanged at start) |
| L2 Group grants panel | #50 | Running (2026-11-14) | — | — | — | subagent (coordinator skill § 4.1.4: two component repos) | automated first, `main` `aa4208b3` |
| L3 Profile Permissions tab | #407 | Not started (gate: L2 merged) | — | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from `next`, PRs into `next`, the coordinator merges),
   because `.github/workflows/ci.yml` is on `origin/main` of both knk-web-api and knk-web-app (checked 2026-11-14).
   Alternatives: (a) old rules, developer merges: does not apply once CI runs on both trunks.
2. **Test rule.** Chosen: "Testing: automated first" with the knk-test-writer skill, as landed on knk-workspace `main`
   in PR #512 (`aa4208b3`, 2026-11-14) before L1 starts; every link prompt names the skill. Alternatives: (a) the
   interim rule (unit tests plus one e2e spec per changed page): superseded the moment the rule landed.
3. **#387 status.** Chosen: links follow today's nodes, because #387 is a design-only session, not merged
   (`design/387-role-permissions`). Recheck before L2 and L3. Alternatives: (a) wait for #387: would stall two
   high-priority bugs for a design that may not change `knk.admin.user.perm`.
4. **Tier for #50.** Chosen: `tier:2` (added by the coordinator; the issue had none), because it adds an admin panel
   and possibly an API read endpoint, with a destructive action behind a confirmation, but no migration or game
   behaviour. Alternatives: (a) `tier:1`: undersells the blast radius of group writes; (b) `tier:3`: would need a
   flag for a staff-only panel. The developer may override.
5. **Order L1 → L2 → L3.** Chosen: sequential, because every link changes knk-web-app (one link per component repo)
   and L2 reuses L1's client. #407 last as the lowest priority. Alternatives: (a) L3 before L2: L2 is priority high.
6. **Overlap with knk-web-app PR #17 (#404–#406).** Chosen: not a blocker; links keep out of `PagedEntityTable.tsx`,
   `DataTable.tsx`, `ObjectDashboard/*` and `ContextMenu.tsx` (L1 needs `entityApiMapping.ts` and a new client), and
   keep to separate lines if they must touch one. Alternatives: (a) wait for PR #17 to merge: unnecessary for
   additive, non-overlapping edits; (b) stack on its branch: only for uncertain work (DESIGN § 5.4).
7. **Route.** Chosen: `create_session` (variant A) per link with model `claude-opus-5-5`, fallback a subagent.

8. **L1 check and merge (2026-11-14).** Chosen: merge after bringing `origin/next` into the L1 branches myself, because `next` moved during the link (#404–#406, #511 and town streets merged): knk-web-app merged cleanly (`110d5f2`), knk-workspace had a mechanical CHANGELOG conflict twice (both sides add entries; kept both, `9f6bf898`, `b6547485`). CI green on the PR heads (web app `build-and-test` and `e2e` after the merge), Codex at its usage limit on all three PRs (rule 4, noted on each), scope inside #408, decisions logged, automated proof present (Playwright, Jest, xUnit). Alternatives: (a) send L1 back to merge `next`: slower for a mechanical merge; (b) merge without bringing in `next`: the web-app PR's CI had not run against the new e2e helpers.
9. **Route for L2.** Chosen: a subagent of this coordinator from the start, because L2 needs knk-web-api and knk-web-app and the coordinator skill (`main` `ffbc7176`, § 4.1.4) sends links with two or more component repos that way (Auto mode's classifier can refuse `add_repo`). L3 (web app only) goes back to `create_session`. Alternatives: (a) `create_session` and fall back on a refusal: what the skill now advises against.
10. **Rule recheck before L2.** No change to "Testing: automated first", the knk-test-writer or knk-link skills or `web-app-testing.md` since `aa4208b3`; #421 (plugin scenarios) and #511 (backfill) are done and archived; #387 still open, not merged, so today's nodes hold for L2.

11. **L2 restarted after the developer's #50 decisions (2026-11-15).** L2's first subagent stopped before coding with "DECISIONS NEEDED" (no AskUserQuestion tool in a subagent); nothing was changed. I asked the developer: (1) audit: a generic audit subject (`SubjectType` + `SubjectId`, one additive migration, History list in the group panel), chosen with future clans that run towns and hold treasuries in mind; (2) plugin freshness: rely on the existing `PermissionGroupChanged` event (#179), plugin follow-up for inheriting groups. Recorded on #50. Then a new subagent with the same prompt plus the answers. Lesson: subagent links can't ask the developer; the coordinator asks before starting such a link. Alternatives: (a) `create_session` for L2 so the link could ask itself: against coordinator skill § 4.1.4 for two component repos.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — The dashboard PermissionGrant table loads (#408)

1. **Scope done.**
    1. knk-web-api: `Controllers/PermissionGrantsController.cs`: `POST search` on `knk.admin.user.manage` (was
       `knk.admin.user.perm`), like `GET` and `GET {id}`; writes unchanged. `Repositories/PermissionGrantRepository.cs`:
       sort by `id`, `holderId`, `value`, `expiresAt` or `node` (default), node and id as tie-breakers.
    2. knk-web-app: new `src/apiClients/permissionGrantClient.ts` (`searchPaged`, `getById`),
       `src/types/dtos/userManagement/PermissionGrantListDto.ts`, `Controllers.PermissionGrants`; `permissiongrant`
       search and fetch-by-id in `src/utils/entityApiMapping.ts` (no create/update/delete); table columns in
       `src/config/objectConfigs.tsx`. None of PR #17's files touched.
    3. knk-workspace: `docs/CHANGELOG.md` entry; `docs/guides/dashboard-access-smoke-test.md` § 8.6 (5 automated
       lines, 2 manual steps), nothing else in the guide.
2. **Commits and heads.** knk-web-api `claude/permission-grant-table-408` at `6e34af5` (1 commit, base `next` at
   `b9ce7f0`); knk-web-app at `e2ad8c1` (1 commit, base `next` at `8918eba`); knk-workspace at `74d85691` (1 commit,
   base `next` at `2fb10456`).
3. **PRs.** https://github.com/PandiO/knk-web-api/pull/30, https://github.com/PandiO/knk-web-app/pull/29,
   https://github.com/PandiO/knk-workspace/pull/529 (`Closes #408`), base `next`. Not merged. **Codex:** at its usage
   limit on all three (no findings to handle); said so on each PR.
4. **Tests, baseline → result.** Test rule: "Testing: automated first", knk-workspace `main` `aa4208b3` (PR #512);
   checked `origin/main` at start, the rule files had not changed since.
    1. knk-web-api: baseline on `next` `dotnet build` green, `dotnet test` 4094 passed / 97 skipped / 0 failed; result
       4114 / 97 / 0. New: `Security/PermissionGrantReadGateTests` (12), `Repositories/PermissionGrantRepositoryTests`
       (8 cases), both checked failing against the old gate and sort. CI `build-and-test` and `fresh-database` green.
    2. knk-web-app: baseline `npm run test:ci` 299 suites / 2569 tests, `tsc` clean, CI build compiled,
       `typecheck:e2e` clean, e2e 11 passed; result 300 / 2574, clean, compiled, clean, e2e 18 passed. New: Jest
       `permissionGrantClient.test.ts` (5), Playwright `e2e/permission-grants.spec.ts` (7, strict mocks, fixtures in
       the new `e2e/fixtures/permissionGrants.ts`); the table tests fail without the mapping. CI `build-and-test` and
       `e2e` green.
    3. Known reds: none. MySQL tests skipped (no `KNK_TEST_MYSQL`). Local e2e needs
       `PLAYWRIGHT_CHROMIUM_PATH=/opt/pw-browsers/chromium` in a cloud session (noted on #511).
5. **Decisions (DESIGN § 4.3).**
    1. *Read gate.* Chosen: put the search on `knk.admin.user.manage` in the API, because the type's view node in
       `DashboardAccess` is `manage`, full reads need the type's read nodes (§ 4.6.1), and `GET` already returns every
       grant to `manage`. Alternatives: (a) keep `perm` and show the refusal in the table: the type stays listed for
       `manage`-only viewers who can never open it (#369's bug); (b) make the type's view node `perm`: reads would need
       the write node, against § 4.6 and the `GET` routes.
    2. *Delete in the dashboard.* Chosen: none, because the API registers the type `ViewOnly` (no delete) and grants
       are removed through the by-node routes. Alternatives: (a) a client `delete` on `DELETE {id}`: the dashboard
       would not offer it anyway, and it would bypass #50's blast-radius confirmation.
    3. *Sorting.* Chosen: the API search sorts by the column asked, because #408's acceptance asks the table to sort
       and it sorted by node only. Alternatives: (a) mark only Node sortable: a table where four of five columns can't
       sort; (b) sort on the client: wrong across pages.
    4. *Generic form create/edit.* Chosen: stays off by leaving out create/update mappings. Alternatives: (a) hide
       New/Edit in the dashboard: touches `ObjectDashboard.tsx` (PR #17) and every view-only type; filed as #530.
6. **Out of scope, noted.** #530 (view-only types still offer New/Edit), #531 (refusal label "Permissiongrant" from a
   lower-case URL), comment on #369 (same fix fits PermissionGroups search), comment on #511 (hub negotiate not mocked
   by `mockSession`; Chromium path in cloud sessions).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Deploy the API and the web app together (no migration, no settings, no config keys).
    2. Manual test steps (smoke test § 8.6):
        1. As the owner on `next`, open Dashboard → Permission Grant: the rows match a known player's Permissions tab
           and the Staff group's grants, group rows read "Group #<id>", and sorting by Expires ascending puts
           never-expiring grants first.
        2. With a test rank holding `knk.admin.user.manage` but not `knk.admin.user.perm`, open the table: it loads,
           New and Edit are greyed out with "Requires knk.admin.user.perm".
    3. Covered by automated tests (no manual step): listing and columns, paging, sorting, search, the read gate per
       node, read without the write node, no table without the read node, the "Requires …" refusal
       (`e2e/permission-grants.spec.ts`, `permissionGrantClient.test.ts`, `PermissionGrantReadGateTests`,
       `PermissionGrantRepositoryTests`).
    4. At merge: `documentation` sub-issue with DESIGN Appendix A.8 rows, web-api architecture § 5.2, web-app
       architecture, admin guide to the ranks, staff web app guide, feature register.
9. **Notes for later links.**
    1. L2 (#50): `PermissionGrantClient` is read-only on purpose; add the group editor's writes on the by-node routes
       (`PUT`/`DELETE api/PermissionGrants/by-node`, `perm`), and reuse `searchPaged` with filter `holderId` for a
       group's grants (the API supports it).
    2. Strict e2e specs need `POST hubs/web/negotiate` mocked (see `e2e/permission-grants.spec.ts`).
