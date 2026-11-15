# Chain 3 follow-ups chain — charter

**Status:** Done: all links merged into `next`, in review (2026-11-15)
**Last updated:** 2026-11-15 (chain end: L1–L7 in `next`, docs #597)
**Issues:** parent [PandiO/knk-workspace#564](https://github.com/PandiO/knk-workspace/issues/564); sub-issues per
link below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** [reports/2026-11-15-chain3-followups-chain.md](../../reports/2026-11-15-chain3-followups-chain.md)
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/`, tests
`.claude/skills/knk-test-writer/` (knk-workspace).

## 0. Binding documents

1. The developer's go of 2026-11-15 ("Yes, start that chain") with the scope per link quoted in § 1, and the decisions
   recorded on [#291](https://github.com/PandiO/knk-workspace/issues/291#issuecomment-6892538946) (rules and
   add-from-template into the draft) and [#288](https://github.com/PandiO/knk-workspace/issues/288#issuecomment-6892539185)
   (lookup applies narrowing filters).
2. [reports/2026-11-08-ux-chain-3.md](../../reports/2026-11-08-ux-chain-3.md): the P3 block (L1), V6 block (L2, L3, L5),
   V7 block (L4), V3 block (L6), their flags (LP3-k, LV6-k, LV7-k, LV3-k) and the AM1–AM3 blocks (access model).
3. [specs/dashboard-access-model/DESIGN.md](../../specs/dashboard-access-model/DESIGN.md), status Implemented: read
   gating per area, lookups (AM2 decision LAM2-7, changed for L5 by the developer's #288 decision), "Requires <node>"
   refusals.
4. Smoke-test guides: [relation-picker-and-delete-details-smoke-test.md](../../guides/relation-picker-and-delete-details-smoke-test.md)
   (L2, L3, L5), [form-display-builders-smoke-test.md](../../guides/form-display-builders-smoke-test.md) (L4),
   [player-profile-smoke-test.md](../../guides/player-profile-smoke-test.md) (L6).
5. [Global agent instructions](../GLOBAL_AGENT_INSTRUCTIONS.md) "Testing: automated first" and the knk-test-writer
   skill, as on `main` at the chain start (`d0a9baf9`).
6. [PandiO/knk-workspace#387](https://github.com/PandiO/knk-workspace/issues/387) (role and permission design, PR #553
   into `next`): **not merged** at the chain start. Links use today's nodes and say so; if #553 lands during the
   chain, the coordinator passes the new nodes to the next link.
7. The sub-issue text **and its comments**.

## 1. Links

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | #399 | tier:1 | `GET api/WorldTasks/temp-region-releases` answers 400 for a blank `serverId` (as `GET open` does); the 200 oldest blocked rows (`ScanLimit`) no longer starve later releases (page past waiting rows or order by last check). `Services/TempRegionReleaseService.cs` and its controller. | knk-web-api, knk-workspace (docs) | `claude/temp-region-releases-399` | `next` | none | now |
| L2 | #290 | tier:1 | Form wizard Object List field: the "Selected (n)" item cards stay readable at 390 px (name not cut to one letter beside "Edit instance" and ×; wrap or icon button). `components/FormWizard/FieldRenderers.tsx` `ListField`. | knk-web-app, knk-workspace (docs) | `claude/list-field-cards-290` | `next` | none | now (parallel with L1, different repo) |
| L3 | #289 | tier:1 | "Show what uses it" (V6 `GET api/EntityReferences/{type}/{id}/rows`, `FeedbackModal` details) also for a refused form configuration delete (Entity setup), `POST api/Dashboard/bulk-delete` per-row refusals and the cancelled-form / deleted-draft "skipped: in use". API only if the endpoint must cover non-dashboard references (form fields/steps, sessions). | knk-web-app, knk-web-api (only if needed), knk-workspace (docs) | `claude/show-what-uses-it-289` | `next` | none | L2 merged into `next` |
| L4 | #291 | tier:2 | Form builder (#71): field validation rules carried in the draft (keyed by field GUID) and applied on Publish; draft-only fields can get rules; the API's `add-from-template` endpoints (steps, fields, display equivalents) write into the draft, not the published rows (or are removed if no caller, logged). | knk-web-app, knk-web-api, knk-workspace (docs) | `claude/builder-draft-rules-291` | `next` | none (tier 2, staff-only builder) | L3 merged into `next`; L1 merged into `next` |
| L5 | #288 | tier:2 | Relation picker lookup mode: `POST api/Lookup/{type}/search` applies the narrowing `pickerFilters` the type's own search accepts (labels only); the picker stops refusing filtered fields in lookup mode. `Services/LookupService.cs`, `Dtos/LookupDtos.cs`, `utils/forms/relationPicker.ts`, `RelationPicker.tsx`. | knk-web-api, knk-web-app, knk-workspace (docs) | `claude/lookup-picker-filters-288` | `next` | none | L4 merged into `next` |
| L6 | #565 (part of #119) | tier:2 | Player profile API part: unfreeze reason, frozen state in `ProfileAccountDto`, game sessions endpoint + third timeline source, search filters / list fields / sort keys; kick and ban from the web (decisions on #565): new nodes `knk.kick`, `knk.ban` seeded on Staff, audited endpoints that publish realtime `PlayerKick` / `PlayerBan` (with reason), Kick/Ban buttons on the profile. | knk-web-api, knk-web-app, knk-workspace (docs) | `claude/player-profile-api-119` | `next` | none | L5 merged into `next` |
| L7 | #574 | tier:2 | knk-plugin handles L6's `PlayerKick` / `PlayerBan`: kick with reason; ban = Paper's ban list (permanent, reason, staff as source) plus kick if online; unban stays `/pardon`; idempotent handlers in the `UserStateSync` pattern. | knk-plugin, knk-workspace (docs) | `claude/web-kick-ban-574` | `next` | none | L6 merged into `next` |

## 2. Gates

1. "L<n> merged into `next`": `git rev-list --count origin/next..origin/<branch>` is 0 in every repo L<n> changed.
2. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed
   (knk-coordinator § 6, automated proof included).
3. L6 kick/ban: settled by the developer on 2026-11-15 (#565 comment): yes; ban like in-game `/ban` (Paper's ban list,
   permanent, unban by `/pardon`); nodes `knk.kick` and `knk.ban`, both seeded on Staff; plugin handler in L7.

Order and parallelism: at most one running link per component repo. L1 (knk-web-api) and L2 (knk-web-app) run
together; L3 after L2 (knk-web-app); L4, L5 and L6 each change both component repos and run one after another; L7
(knk-plugin) after L6.

## 3. Chain notes

1. **Overlaps at the start (2026-11-15):** no open PR in knk-web-api or knk-web-app. Staff web follow-ups chain (#517)
   L3 #407 is running in knk-web-app `pages/admin/PlayerProfilePage.tsx` (Permissions tab): L6 keeps to the timeline,
   freeze and search files and separate lines of `PlayerProfilePage.tsx`. #535 claims `EmailLogPage.tsx` /
   `InvitationsPage.tsx`: no link touches them. Town streets (#409) and the smoke-test fixes are in `next` or in
   review on other files. The coordinator rechecks the board before each link.
2. **Route:** L1–L3 by `create_session` (knk-workspace plus one component repo; L3 falls back to a subagent if it needs
   the API). L4–L6 need two component repos: subagents of the coordinator from the start (coordinator skill § 4.1.4).
   L7 (knk-plugin only) by `create_session`, JDK 25.
5. **Repository access:** knk-plugin is `read` for the chain, and `push` for L7 only (developer decision 2026-11-15,
   "Separate link L7").
3. Migrations: L6 adds one, additive: seed `knk.kick` and `knk.ban` on the Staff group (as `SeedStaffFreezeNodes`), and
   an index only if the sessions read needs one.
4. Model for link sessions: `claude-opus-5-5` (passed explicitly).
