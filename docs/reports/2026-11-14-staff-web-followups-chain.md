# Staff web app follow-ups chain — progress report

**Status:** Running (2026-11-14) · **Last updated:** 2026-11-15

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
| L2 Group grants panel | #50 | Merged into next (2026-11-15) | api `00b8060`, app `28c0d47`, ws `da034e05`; next: api `dcbb1f82`, app `42781025`, ws `685a4677` | knk-web-api#32, knk-web-app#35, knk-workspace#560 | green on the code PRs; Codex at its usage limit | subagent (coordinator skill § 4.1.4: two component repos) | automated first, `main` `aa4208b3` (unchanged at start) |
| L3 Profile Permissions tab | #407 | Done, in review (2026-11-15) | app `567f15d`, ws `c5de65d5` | knk-web-app#37, knk-workspace#569 | green on knk-web-app#37; Codex at its usage limit | create_session session_01R1w2Uu4cu227Le97QQaG5U | automated first, `main` `aa4208b3` (unchanged) |

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

12. **L2 check and merge (2026-11-15).** Chosen: merge knk-web-api#32, knk-web-app#35, knk-workspace#560 into `next` with merge commits, because every § 6 check held: heads match, the API branch contains `next`, the web-app and workspace branches were 2 and 4 commits behind but merge cleanly (a removed debug spec; town streets docs), CI green on both code PRs (incl. `fresh-database` for the migration), no review threads, Codex at its usage limit (rule 4, noted on each PR), scope inside #50 plus the developer's audit decision, automated proof (31 xUnit, Jest, 11 Playwright tests). The migration `AddAuditLogSubject` is additive (nullable columns, index, `TargetUserId` nullable); its Down maps null targets to 0, documented. Alternatives: (a) send L2 back to merge `next` first: the missing commits touch no file L2 changed; `next` CI covers the merge result.
13. **L3 route and recheck.** Chosen: `create_session` (knk-web-app only besides knk-workspace), after rechecking: no rule change since `aa4208b3` (only coordinator skill `ffbc7176`), #387 still open, no open knk-web-app PRs, the only other web-app claim (#535) is on `EmailLogPage`/`InvitationsPage`. Alternatives: (a) subagent: not needed for one component repo, and a session can ask the developer.

14. **L3 check (2026-11-15): code merged, guides sent back.** knk-web-app#37 merged into `next` (`b2589eb4`): CI green on the PR, the 5 commits it lacked (#535, #290) don't touch `DataTable` or its files, scope inside #407 (the Expires column left out because `EffectivePermissionEntryDto` has no expiry, #568 filed: accepted as a logged decision), Codex at its usage limit. `next` CI green in both repos at heads containing L2. knk-workspace#569 held back: the test rule changed on `main` at 09:38 (`4effca89`, developer decision 2026-11-15: smoke guides keep every step in full, automated steps tagged), after L3 read `aa4208b3`. I merged `next` into the branch (CHANGELOG, kept both) and sent L3 back to rewrite its § 6 and this chain's merged § 8.6 (L1) and § 8.7 (L2) in the new format. Rule versions: L1 and L2 `aa4208b3`; L3 code `aa4208b3`, guides `4effca89`. Alternatives: (a) merge #569 and leave the three sections to a later backfill: the rule applies to every guide at once; (b) rewrite them myself: links write docs, the coordinator does bookkeeping.

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

### 4.2 L2 — Edit a permission group's own grants in the web app (#50)

1. **Scope done.**
    1. knk-web-api: generic audit subject (developer decision 2026-11-15): `Models/AuditLogEntry.cs` nullable
       `SubjectType`/`SubjectId`, `TargetUserId` nullable, `Enums/AuditSubjectTypes.cs`, one additive migration
       `AddAuditLogSubject` (`20261115092735`, index `SubjectType, SubjectId, Timestamp`). `PermissionGrantService`
       audits a group's grant changes once per change with the group as subject (`AuditLogService.RecordForSubjectAsync`;
       node, before/after value and expiry); user-holder audits unchanged. `GET api/audit-log` takes
       `subjectType`/`subjectId` (`AuditLogController`, repository, service). New `GET api/PermissionGroups/{id}/member-count`
       (`RequireServiceOrPermission(knk.admin.user.manage)`): active members of the group and of every inheriting group,
       each player once. `PrivacyRepository` erasure skips null targets. Writes stay on the by-node routes and the
       escalation guard.
    2. knk-web-app: `src/components/admin/permissionGroups/GroupPermissionsPanel.tsx` on the group's detail page
       (`DisplayWizardPage.tsx`, permissiongroup only): own nodes (Granted/Denied, expiry), member count, grant/deny form
       with an empty expiry by default, Edit / change Granted-Denied / Remove per row, blast-radius confirmation on flips
       and removals, History list (audit log by subject), read-only with "Requires knk.admin.user.perm".
       `PermissionGrantClient.getForHolder` (searchPaged on `holderId`), `upsertByNode`, `revokeByNode`;
       `PermissionGroupClient.getMemberCount`; `userManagementClient.getAuditLog` subject filter; `AuditLogEntryDto`
       `targetUserId: number | null`, `subjectType`, `subjectId`. None of PR #17's files touched; no e2e helper changed.
    3. knk-workspace: `docs/CHANGELOG.md` entry (admin steps: the migration); `docs/guides/dashboard-access-smoke-test.md`
       § 8.7 (8 automated lines, 4 manual steps), nothing else in the guide.
2. **Commits and heads.** knk-web-api `claude/group-grants-50` at `00b8060` (3 commits incl. a merge of `next` `de74190`,
   base `next` at `2425f18`); knk-web-app at `28c0d47` (2 commits incl. a merge of `next` `d3d7152`, base `next` at
   `9a29623`); knk-workspace at `da034e05` (1 commit, base `next` at `66c7c910`).
3. **PRs.** https://github.com/PandiO/knk-web-api/pull/32, https://github.com/PandiO/knk-web-app/pull/35,
   https://github.com/PandiO/knk-workspace/pull/560 (`Closes #50`), base `next`. Not merged. **Codex:** at its usage
   limit on all three (no findings to handle); said so on each PR.
4. **Tests, baseline → result.** Test rule: "Testing: automated first", knk-workspace `main` `aa4208b3` (PR #512);
   checked `origin/main` at start (`1583de67`): the rule files had not changed since.
    1. knk-web-api: baseline `dotnet build` green, `dotnet test` on `next` `2425f18` 4114 passed / 97 skipped / 0
       failed, on `next` `de74190` (after #409) 4138 / 98 / 0; result 4169 / 98 / 0 (+31). New:
       `Services/GroupGrantAuditTests` (6), `Api/GroupGrantsPanelApiTests` (12), `Migrations/AddAuditLogSubjectMigrationTests`
       (4), `PermissionGrantServiceTests` (+4, the group test now expects the subject entry), `AuditLogServiceTests` (+4),
       `ReadAccessRulesTests` pin for `GetMemberCount`. 13 fail with the group audit or the inheritance walk broken.
       CI `build-and-test` and `fresh-database` green.
    2. knk-web-app: baseline on `next` `9a29623` `npm run test:ci` 301 suites / 2595 tests, `tsc` clean,
       `typecheck:e2e` clean, e2e 96 passed (`next` `d3d7152` adds 1 suite, 8 tests, 4 e2e); result 304 / 2615, clean,
       clean, CI build compiled, e2e 111 passed. New: Playwright `e2e/group-grants.spec.ts` (11, strict, fixtures
       `e2e/fixtures/groupGrants.ts`); Jest `permissionGrantClient.test.ts` (+3), `permissionGroupClient.test.ts` (1),
       `userManagementClient.test.ts` (+2), `groupPermissionsHelpers.test.ts` (6). The flip tests fail without the
       confirmations. CI `build-and-test` and `e2e` green.
    3. Known reds: none. MySQL tests skipped (no `KNK_TEST_MYSQL`).
5. **Decisions (DESIGN § 4.3).**
    1. *Where the panel lives.* Chosen: the group's detail page (`/display/PermissionGroup/{id}`, below the details),
       because it needs only the type's view node, like the grants it shows. Alternatives: (a) next to the edit form:
       the form wizard needs `knk.admin.content` (#371), which a ranks admin may lack; (b) a new page: one more route
       for one panel.
    2. *Audit actions.* Chosen: reuse GrantAdded/GrantUpdated/GrantRemoved with the subject, because the existing
       detail lines render them and the action already says what changed. Alternatives: (a) new values (e.g.
       GroupGrantAdded): duplicates the meaning; the subject already tells group from player.
    3. *SubjectType.* Chosen: a string column (max 64) with constants in `AuditSubjectTypes`, because a later subject
       (a clan, a treasury) then needs no migration. Alternatives: (a) an enum stored as string: a code change per
       subject anyway, same column; (b) an int enum: unreadable in the database.
    4. *Index.* Chosen: (`SubjectType`, `SubjectId`, `Timestamp`), because the History reads one subject newest first,
       like the existing (`TargetUserId`, `Timestamp`) index. Alternatives: (a) (`SubjectType`, `SubjectId`) only: a
       sort step per read.
    5. *Group removal details.* Chosen: a group's GrantRemoved also carries `expiresAt` (the decision asks for the
       expiry); player removals keep their old shape. Alternatives: (a) add it to player entries too: changes
       user-holder audits, which were to stay as they are.
    6. *When to confirm.* Chosen: on a Granted/Denied flip and a removal (row button or form), not on a new node or an
       expiry change, as #50 and the charter list. Alternatives: (a) confirm every save: friction on additive changes;
       (b) confirm expiry changes too: an expiry far ahead is harmless, one in the past is still visible as "expired".
    7. *Without `knk.admin.user.perm`.* Chosen: read-only, controls disabled with "Requires knk.admin.user.perm", because
       that is the #280 rule (decision 11: shown disabled, not hidden). Alternatives: (a) hide the panel: staff can't
       see what exists.
    8. *Member count.* Chosen: distinct active members of the group and all its descendants, plus the inheriting group
       count, in one endpoint on `knk.admin.user.manage`. Alternatives: (a) only direct members: undersells the blast
       radius (#50 asks for inheriting groups); (b) count in the web app: needs every membership.
    9. *Inherited nodes.* Chosen: not shown (optional in #50), because the profile's Effective Permissions already
       shows sources and the group's parent is one click away. Alternatives: (a) read the parent chain's grants per
       group: more calls and tests for an optional item; can follow later.
    10. *Migration after `next` moved.* Chosen: generate `AddAuditLogSubject` again after merging #409's
        `DropTownStreet`, so the designer model matches; the snapshot change stays the audit columns and index only.
        Alternatives: (a) keep the first migration: its designer still carried the dropped TownStreet table.
6. **Out of scope, noted.** #558 filed (plugin: members of inheriting groups and changes while realtime is down,
   developer decision 2 on #50); comment on #511 (`dotnet ef migrations add` without MySQL; regenerating a migration
   after `next` gains one).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Deploy: back up the database, deploy the API, run `dotnet ef database update` (one additive migration,
       `AddAuditLogSubject`; the API does not migrate on start), then the web app. No settings, no `config.yml` key, no
       plugin change. If #409's `DropTownStreet` is not applied yet, it runs first (earlier timestamp).
    2. Manual test steps (smoke test § 8.7):
        1. On a copy of the alpha database, `dotnet ef database update` applies `AddAuditLogSubject`; a known player's
           Audit log on the profile still lists the old entries.
        2. As the owner, grant `knk.test.group` on a test group with one member; on the member's profile, refresh:
           Effective Permissions lists it with the group as source. Deny it, then remove it, refreshing each time; the
           group's History lists the three changes with you as "By".
        3. With that member online, grant and remove a node they can try in game: it applies within seconds without a
           relog.
        4. With a staff rank ranked below a group, open that group and save a node: "You can only change groups ranked
           below your own."
    3. Covered by automated tests (no manual step): listing, grant, deny, permanent default, expiry change on the same
       row, flip and remove confirmations with the blast radius and Cancel, the uncounted case, API refusal shown,
       read-only without `perm`, nothing read without `manage`, member count with inheritance, audit entry per change
       with the group as subject, audit search by subject, player audits unchanged, erasure, migration shape
       (`e2e/group-grants.spec.ts`, Jest client and helper tests, `GroupGrantAuditTests`, `GroupGrantsPanelApiTests`,
       `PermissionGrantServiceTests`, `AuditLogServiceTests`, `AddAuditLogSubjectMigrationTests`).
    4. At merge: `documentation` sub-issue with: web-api architecture (the generic audit subject, built for later
       group-like subjects such as clans that run towns and their treasuries; the member-count endpoint and audit
       filters), dashboard access DESIGN Appendix A rows (`GET api/PermissionGroups/{id}/member-count`, audit-log
       subject filters), web-app architecture (group Permissions panel, by-node client writes), the admin guide to the
       ranks and the staff web app guide (editing a group's nodes, the confirmation, History), the feature register.
9. **Notes for later links.**
    1. L3 (#407): `AuditLogEntryDto.targetUserId` is `number | null` now; the profile's Permissions tab can keep using
       `userManagementClient.grantNode`/`revokeNode`; `GroupPermissionsPanel` shows one way to do a grant form with
       gates and a confirmation.
    2. `mockSession` already answers `hubs/` with 404, so strict specs need no extra negotiate mock.

### 4.3 L3 — Player profile Permissions tab: form on top, search, sortable columns (#407)

1. **Scope done.**
    1. knk-web-app: the Effective Permissions card is now its own component,
       `src/pages/admin/playerProfile/EffectivePermissionsCard.tsx`, and `PlayerProfilePage.tsx` loses its inline
       section, state and handlers (182 lines out). The grant/deny form sits above the list. A search box filters by
       node and source (a group's name, "direct") and shows "n of N nodes" and "No permissions match “…”.". Node, Value
       and Source sort through the shared `DataTable` (asc → desc → off, arrow, `aria-sort`); with no sort the API's
       order stays. The helpers are in `effectivePermissions.ts`. Unchanged: the 1-day default expiry, the
       `knk.admin.user.perm` gate, grant/deny/remove with the refresh, and the "Remove direct grant of …" labels. The
       group panel (#50), the PermissionGrant table (#408), `EmailLogPage`/`InvitationsPage` (#535) and every e2e helper
       line are untouched; `e2e/fixtures/players.ts` has new exports only (`mockProfilePermissions`, `directNode`,
       `groupNode`), and `e2e/player-profile.spec.ts` gets a new block plus its import lines.
    2. knk-workspace: a `docs/CHANGELOG.md` entry and the new `docs/guides/player-profile-smoke-test.md` § 6 (7
       automated lines, 2 manual steps); no other lines in the guide changed. `dashboard-access-smoke-test.md` § 5 is
       unchanged because granting works as before.
2. **Commits and heads.** knk-web-app `claude/profile-permissions-407` at `567f15d` (1 commit, base `next` at
   `4278102`); knk-workspace at `c5de65d5` (1 commit, base `next` at `685a4677`).
3. **PRs.** https://github.com/PandiO/knk-web-app/pull/37 (`Part of #407`), https://github.com/PandiO/knk-workspace/pull/569
   (`Closes #407`), base `next`. Not merged. **Codex:** at its usage limit on both (no findings to handle); said so on
   each PR.
4. **Tests, baseline → result.** Test rule: "Testing: automated first", knk-workspace `main` `aa4208b3` (PR #512); I
   checked `origin/main` at the start and the rule files (global instructions, knk-test-writer, knk-link,
   `web-app-testing.md`) had not changed since.
    1. knk-web-app: the baseline ran on `next` `4278102` in a clean worktree: `npm run test:ci` 304 suites / 2615
       tests, `tsc` clean, `typecheck:e2e` clean, e2e 109 passed + 1 flaky (`data-table.spec.ts` sort test, green on
       retry, not touched). Result: 305 / 2624, clean, clean, `CI=true npm run build` compiles, e2e 122 passed. New
       tests:
        1. Jest: `effectivePermissions.test.ts` (9).
        2. Playwright: 12 strict tests in `e2e/player-profile.spec.ts`. They cover the form above the list and the
           default order; Save with the 1-day default; a permanent deny via Clear; removing a direct grant (inherited
           rows have no remove); search by node, by source and the empty message; each column asc/desc/off with
           `aria-sort` (3 tests); a sort kept across search and refresh; read-only without `knk.admin.user.perm`.
        3. Mutation check: with the source match removed, the descending sort broken and a 2-day default expiry, 4
           Jest and 7 Playwright tests fail.
        4. CI `build-and-test` and `e2e` green on the PR.
    2. Known reds: none (the one flaky e2e test is on the base and passes on retry).
5. **Decisions (DESIGN § 4.3).**
    1. *Extraction.* Chosen: the whole card (form, search, list) as one component, because the form and the list share
       the gate and the refresh. Alternatives: (a) only the table: the form state would keep growing the page.
    2. *Table.* Chosen: the shared `DataTable` (compact, bordered), because it already has `aria-sort`, the icons and
       the keyboard handling. The headers now look like the app's other tables. Alternatives: (a) a hand-made table
       with sort buttons: it would duplicate `DataTable`.
    3. *Third click.* Chosen: asc → desc → off (`nextSort`), like every other `DataTable`, so the default order is one
       click away. Alternatives: (a) toggle asc/desc only: the default order would come back only on reload.
    4. *Value order.* Chosen: by the label (Denied before Granted ascending), ties by node. Alternatives: (a) Granted
       first: does not match the visible text.
    5. *Expires column.* Chosen: none, because `EffectivePermissionEntryDto` carries no expiry; filed #568.
       Alternatives: (a) fetch the direct grants' expiries through `PermissionGrantClient`: an extra call, and only the
       direct rows would get one; (b) an API change in this link: the charter scopes L3 to knk-web-app.
    6. *Search reach.* Chosen: node and the shown source text, case-insensitive and trimmed. Alternatives: (a) node
       only: #407 asks for source too; (b) also the Value: "grant" would match "Direct grant" anyway and confuse.
    7. *Where the tests live.* Chosen: a new strict block in the #511 `e2e/player-profile.spec.ts` plus new fixture
       exports, as the prompt prefers. Alternatives: (a) a new `e2e/profile-permissions.spec.ts`.
6. **Out of scope, noted.** #568 filed (an expiry on effective permissions: API and web app). On #511 I commented
   that a killed e2e run leaves `serve-build.mjs` on port 4173, and that the baseline should run in a worktree.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Deploy the web app (no API change, no migration, no setting, no `config.yml` key).
    2. Manual test steps (smoke test § 6):
        1. On a player with many nodes from several groups, grant `knk.test.profile` with the default expiry. Check
           that the form is in view without scrolling, the new row appears with "Direct grant", and searching
           `knk.test` or the group's name finds it. Remove the node again.
        2. At phone width and on a desktop, in light and dark themes, check that the search box, the sort arrows and
           the "Inherited" labels read well.
    3. Covered by automated tests (no manual step): the form position and default order, grant with the 1-day
       default, permanent deny, removal and refresh, search by node and source with the empty message, sorting of
       each column with `aria-sort`, and the read-only state without the node (`e2e/player-profile.spec.ts`,
       `effectivePermissions.test.ts`).
    4. At merge: a `documentation` sub-issue covering the web-app architecture (`EffectivePermissionsCard`), the staff
       web app guide (search and sort on the Permissions tab) and the feature register row.
9. **Notes for later links.** None (last link). `DataTable` with `density="compact"` and a client-side
   `sortEffectivePermissions`-style helper is a quick way to make a small in-card list sortable.
10. **Correction 2026-11-15 (after the coordinator's check).** Test rule version changed to `main` `4effca89` (developer
    decision 2026-11-15: smoke-test guides keep every step in full and tag the automated ones). On knk-workspace
    `claude/profile-permissions-407` (head `9b361028`, after the coordinator's merge of `next` at `51a98449`) I rewrote
    `player-profile-smoke-test.md` § 6 (10 of 12 steps tagged, 2 manual) and `dashboard-access-smoke-test.md` § 8.6
    (L1: 8 of 10 tagged, 2 manual) and § 8.7 (L2: 14 of 18 tagged, 4 manual; it gains the uncounted blast radius and
    the staff-only detail page, both already in `e2e/group-grants.spec.ts`). No other lines changed. The guide's top
    status line ("57 of 97 steps (§ 1–8)") now undercounts § 8.6–8.7 (+5 steps, +5 tagged) and was left for the
    coordinator. `@codex review` requested on knk-workspace#569. knk-web-app#37 merged into `next` by the coordinator.
