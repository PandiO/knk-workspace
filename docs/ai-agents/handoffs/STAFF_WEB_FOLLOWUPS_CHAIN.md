# Staff web app follow-ups chain — charter

**Status:** Done (2026-11-15): L1–L3 merged into `next`, docs #576
**Last updated:** 2026-11-15 (chain done); 2026-11-14 (first version, coordinator)
**Issues:** parent [PandiO/knk-workspace#517](https://github.com/PandiO/knk-workspace/issues/517); sub-issues per
link below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** [reports/2026-11-14-staff-web-followups-chain.md](../../reports/2026-11-14-staff-web-followups-chain.md)
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/`, tests
`.claude/skills/knk-test-writer/` (knk-workspace).

## 0. Binding documents

1. [specs/dashboard-access-model/DESIGN.md](../../specs/dashboard-access-model/DESIGN.md), status Implemented
   (decided 2026-11-08, § 7): read gating per area (§ 5.2 of the web-api architecture), "Requires <node>" refusals
   (decision 11), no one changes a group ranked at or above their own (§ 4.4).
2. [guides/dashboard-access-smoke-test.md](../../guides/dashboard-access-smoke-test.md) (L1, L2: § 5 granting, § 7 read
   gating, § 8 web app) and [guides/player-profile-smoke-test.md](../../guides/player-profile-smoke-test.md) (L3).
3. [Global agent instructions](../GLOBAL_AGENT_INSTRUCTIONS.md) "Testing: automated first" and the knk-test-writer
   skill (landed on `main` 2026-11-14, PR #512, `aa4208b3`).
4. [PandiO/knk-workspace#387](https://github.com/PandiO/knk-workspace/issues/387) (role and permission design): **not
   merged** at the chain start (design session on `design/387-role-permissions`). Until it merges, today's nodes hold
   (`knk.admin.user.perm` writes grants, `knk.admin.user.manage` reads users). If it merges during the chain, the
   coordinator rechecks who holds `knk.admin.user.perm` before starting the next link.
5. The sub-issue text **and its comments** (decisions added later live there).

## 1. Links

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | #408 | tier:1 | The dashboard PermissionGrant table loads: `PermissionGrantClient` (one file per resource: `searchPaged`, `getById`, delete if offered), `permissiongrant` in `src/utils/entityApiMapping.ts`; align the read gates of `POST api/PermissionGrants/search` (`knk.admin.user.perm`) and `GET` (`knk.admin.user.manage`), or have the table show the "Requires …" refusal cleanly. Generic-form create/edit of grants stays off unless #50 says otherwise. | knk-web-app, knk-web-api (only if the gate is aligned there), knk-workspace (docs) | `claude/permission-grant-table-408` | `next` | none | now |
| L2 | #50 | tier:2 | Edit a permission group's own grants in the web app: Permissions panel (node, Granted/Denied, expiry; grant/deny form, per-row remove), no default expiry, blast-radius confirmation ("affects N players", inheriting groups included), read-only or hidden without `knk.admin.user.perm`; writes through the by-node routes; a small API read endpoint if the search does not fit. Settle the open decisions (group-level audit, plugin freshness) with the developer before coding. | knk-web-app, knk-web-api, knk-workspace (docs) | `claude/group-grants-50` | `next` | none (tier 2, additive admin panel) | L1 merged into `next` |
| L3 | #407 | tier:1 | Player profile Permissions tab: grant/deny form above the list, search box (node and source), sortable columns with indicator and `aria-sort`; 1-day default expiry and `knk.admin.user.perm` gating kept. | knk-web-app, knk-workspace (docs) | `claude/profile-permissions-407` | `next` | none | L2 merged into `next` (one knk-web-app link at a time) |

## 2. Gates

1. "L<n> merged into `next`": `git rev-list --count origin/next..origin/<branch>` is 0 in every repo L<n> changed.
2. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed
   (knk-coordinator § 6, automated proof included).
3. L2's decisions (audit, plugin freshness) are asked by the link with AskUserQuestion before coding and recorded on
   #50.

Order and parallelism: strictly L1 → L2 → L3. Every link changes knk-web-app, and only one knk-web-app link runs at a
time; L2 also shares L1's client.

## 3. Chain notes

1. **Overlap:** knk-web-app PR #17 (`claude/dashboard-table-actions-404-406`, #404–#406, into `next`, open) changes
   `PagedEntityTable.tsx`, `DataTable.tsx`, `ObjectDashboard/*`, `ContextMenu.tsx`. Links keep out of those files; L1
   needs only `entityApiMapping.ts` and a new client (plus tests). If a link must touch `PagedEntityTable.tsx`, it
   keeps to separate lines and says so in its block. L3's `PlayerProfilePage.tsx` is not in PR #17.
2. **#387 design session** (`design/387-role-permissions`, docs only): no file overlap.
3. **Tests (rule version):** every link follows "Testing: automated first" as of knk-workspace `main` `aa4208b3`
   (knk-test-writer skill): a Playwright spec in knk-web-app `e2e/` per changed page or flow (mocked API), Jest client
   tests, API xUnit tests for any API change; suites run in the baseline and before the PR. The coordinator re-reads
   the rule files before each link and passes on any newer version.
4. Migrations: none expected. L2 may add one only if the developer picks a new audit action that needs it (additive).
5. Model for link sessions: `claude-opus-5-5` (passed explicitly to `create_session`).
