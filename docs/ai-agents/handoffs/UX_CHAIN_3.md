# Web app screens on the new primitives, access model, small fixes (chain 3) — charter

**Status:** Started 2026-11-08 (developer's go on the coordinator's proposal)
**Last updated:** 2026-11-08
**Issues:** UX roadmap [#24](https://github.com/PandiO/knk-workspace/issues/24); per link below. Reference issues as
`PandiO/knk-workspace#n` in component repos.
**Predecessors:** [UX_REALTIME_CHAIN.md](UX_REALTIME_CHAIN.md) (chain 1) and [UX_CHAIN_2.md](UX_CHAIN_2.md) (chain 2).
Chain 1's §1–§5 and §7 (setup, read first, hard rules, blockers, per link, report block format) and chain 2's §1
notes (themes, case-unique file names, Siege Survival overlap, subagent worktrees) apply unchanged.
**Report:** [reports/2026-11-08-ux-chain-3.md](../../reports/2026-11-08-ux-chain-3.md).

The coordinator starts each link, checks it, keeps report, tracker and issues current and tells the developer what to
test and merge. Links push only to their feature branches; **the coordinator merges into a trunk only when the
developer asks**.

## 0. Links

Three lanes. Lane D is documentation only (no component repo) and runs beside the others. Inside a lane, links run one
after another; at most two component-repo links run at once and they share no component repo.

| Link | Issues | What | Repos | Feature branch | Gate |
|---|---|---|---|---|---|
| D1 | #280 | **Design document only:** dashboard access model (view / create / edit / delete / bulk delete / export; per area or type; `knk.admin.delete`, `knk.admin.delete.bulk`; groups; escalation guard; API, web app and realtime enforcement; migration of existing grants). Ends with numbered open questions for the developer. No code. | workspace | `claude/dashboard-access-model-280` | now |
| V1 | #266, #263, #258 | Entity setup scrolls sideways at phone width; `lint:colors` overrun on main; landing slideshow fades to black between images | web-app | `claude/web-fixes-266-263-258` | now |
| V2 | #205 (export only) | Export of selected rows / current search (all pages) as CSV with the table's columns; checkbox selection on the dashboard table without breaking row links. **Bulk delete waits for #280's approved design.** | web-app | `claude/dashboard-export-205` | V1 done |
| V3 | #119 | Player profile for staff: status strip, tabs, freeze/unfreeze with reason (`confirmWithReason`), per-player timeline, paged audit, better search | web-app (+API if needed) | `claude/player-profile-119` | V2 done |
| V4 | #26 | Settings pages: unit hints, help text, confirms on risky toggles; Lootbox settings tab, Currency policy and Roads onto `SettingsPage` | web-app | `claude/settings-pages-26` | V3 done |
| V5 | #188, #189 | Entity detail page: real Select / Unlink / Add (Remove unlinks, never deletes), then readability (values not as disabled inputs, related values as links, paged collections, readable errors) | web-app, API | `claude/entity-detail-188-189` | V4 done |
| V6 | #191, #44 | Wizard search-as-you-type relation picker; FeedbackModal "Show details" on the new Dialog | web-app (+API for #44) | `claude/picker-details-191-44` | V5 done |
| V7 | #71 | Form and Display builders: save in place, scaffold from metadata, duplicate, preview, explicit Publish | web-app (+API) | `claude/builders-71` | V6 done |
| P1 | #261 | Kits: "Grant" on the player profile records the claim but the items never reach the player | API, plugin | `claude/kit-grant-delivery-261` | now |
| P2 | #264 | Flaky `RealtimeClientTest.stopClosesAndNeverReconnects` | plugin | `claude/realtime-client-flaky-264` | P1 done |
| P3 | #269 | Temp regions of abandoned drafts cleaned up when the draft is cancelled/expires, not only after 14 days | API, plugin | `claude/temp-region-drafts-269` | P2 done |

| AM1 | #280 | Access model, API part 1: node constants, type→area registry, `knk.admin.delete` on every deletable type, owner-only `knk.admin.delete.bulk`, `knk.admin.export`, migration `SeedDashboardActionNodes` (backfill **without** the Staff group, developer 2026-11-08), `POST api/Dashboard/bulk-delete` and `/export`, metadata fields, live updates per area | API | `claude/dashboard-access-280` | developer's go (given 2026-11-08) and no other link changing knk-web-api |
| AM2 | #280 | Access model, API part 2: every read gated by area, lookup endpoints for pickers, pinned read-rules test | API | `claude/dashboard-access-280` | AM1 done |
| AM3 | #280, #205 | Access model in the web app: per-type access, dashboard for any area node, disabled actions with hints, hidden bulk Delete, export via endpoint, picker lookup mode; **#205 bulk delete** | web-app | `claude/dashboard-access-280` | V2 done and AM2 pushed |
| AM4 | #280 | Living docs, admin guide to the ranks, smoke test with role accounts, CHANGELOG | workspace | `claude/dashboard-access-280` | AM3 done |

Design: `docs/specs/dashboard-access-model/DESIGN.md` on `claude/dashboard-access-model-280` (decided 2026-11-08).
AM1–AM3 are deployed together, API first.

V5 and V6/V7 touch the API: they wait until no P-lane link changes knk-web-api at the same time (the coordinator
orders them).

**Stacking:** chain 2 is unmerged. **Every V link** branches from the trunk and first merges
`claude/realtime-web-live-183` (X1, contains W1–W4: Dialog, toast, `useConfirm`/`confirmWithReason`, `DataTable`,
`Field`, `SettingsPage`, route table) and then the previous V link's branch if it is unmerged. P links merge
`claude/lootbox-area-rename-34` (plugin; contains R1–R3) or the chain 2 API branches only when they change the same
files. Merge only; say it in the report block.

**Queue after this chain:** bulk delete (#205) once #280 is approved; #92 rebrand phases 2–4, #139 email verification,
#190 settings audit (developer decisions first); numbers still fixed as `12,345` on a few pages (#187 note).
