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
| L1 PermissionGrant table | #408 | Not started | — | — | — | — | automated first, `main` `aa4208b3` |
| L2 Group grants panel | #50 | Not started (gate: L1 merged) | — | — | — | — | — |
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

## 4. Link blocks

_(Each link appends its block here when it finishes.)_
