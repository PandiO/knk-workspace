# Web app UX foundations and realtime follow-ups (chain 2) — charter

**Status:** Started 2026-11-05 (developer's go on the coordinator's proposal of 2026-11-02/05)
**Last updated:** 2026-11-05
**Issues:** UX roadmap [#24](https://github.com/PandiO/knk-workspace/issues/24), SignalR [#66](https://github.com/PandiO/knk-workspace/issues/66);
per link in the table below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Predecessor:** [UX_REALTIME_CHAIN.md](UX_REALTIME_CHAIN.md) (chain 1, every link merged by 2026-11-04). Its §1–§5 and
§7 (setup, read first, hard rules, blockers, per link, report block format) apply here unchanged, with the report and
link table below in place of chain 1's.
**Report:** [reports/2026-11-05-ux-chain-2.md](../../reports/2026-11-05-ux-chain-2.md).

The coordinator starts each link, checks the result, keeps the report, tracker and issues current and tells the
developer what to test and merge. Links push only to their feature branches; **the coordinator merges into a trunk only
when the developer asks**.

## 0. Links

Two lanes run side by side; they share no component repo. Inside a lane, links run one after another.

| Link | Issues | What | Repos | Feature branch | Gate (may start when…) |
|---|---|---|---|---|---|
| W1 | #197 | Remove "Entity setup" from the nav; reach it through the dashboard's ⚙ (and its URL); check nothing else is nav-only | web-app | `claude/nav-entity-setup-197` | now |
| W2 | #33 | Feedback primitives: general toast API, one accessible `Dialog` replacing the hand-rolled overlays, confirm with danger and required reason; on #95 tokens | web-app | `claude/feedback-primitives-33` | W1 done |
| W3 | #187 | Data and format primitives: `DataTable`/`Pager` (row links, `aria-sort`, reuse what #39 built in `PagedEntityTable`), `format.ts`, `Field` with tied labels, `SettingsPage` shell with dirty state | web-app | `claude/data-primitives-187` | W2 done |
| W4 | #30 | Admin information architecture: layout routes, one route-meta table (nav, gating, titles, breadcrumbs), grouped admin sidebar filtered by node permissions | web-app | `claude/admin-ia-30` | W3 done |
| R1 | #184 | Realtime S5: `AccountErased` push to the game server (kick, wipe local data), persisted erasure feed polled on reconnect, hourly verifier kept as backstop | API, plugin | `claude/realtime-erasure-184` | now |
| R2 | #31 (rest) | Siege startup-only work retried on API recovery when the hub is off (order: abort, restore, fetch config); link 10 covered only the hub reconnect | plugin | `claude/siege-startup-retry-31` | R1 done |
| R3 | #34 | Lootbox spawn areas drawn through the form's region task renamed to a lootbox-area name on submit and re-run, so the 14-day temp-region cleanup keeps them | API, plugin | `claude/lootbox-area-rename-34` | R2 done |
| X1 | #183 | Realtime S4: live updates in the web app (dashboard refresh on another admin's change, online badges on profile/moderation) | API, web-app | `claude/realtime-web-live-183` | W4 and R3 done |

**Stacking (the developer tests in the evenings, 2026-11-02):** a link branches from the current trunk. When an earlier
link of the same lane is still unmerged **and** this link changes the same files, merge that link's branch into this
one (merge only, no rebase) and say so in the report block; merging this branch later merges the earlier link too. W4
merges W1 if W1 is unmerged (both change the navigation).

**Queue after this chain** (needs the primitives merged, or a developer decision first): #119 player profile, #26
settings pages, #188 then #189 entity detail page, #191 relation picker, #71 builders; decisions first: #205 bulk
actions (which types, CSV columns), #92 rebrand phases 2–4, #190 settings audit, #139 email verification.

## 1. Notes on top of chain 1's rules

- **Trunk state 2026-11-05:** web-app `main` `f6b31c3` (all green: `test:ci`, `tsc` 0, `CI=true` build; a test fails on
  file names that differ only in case — Windows dev machines). API `master` and plugin `main` include chain 1 and the
  world-task follow-ups' base; #239/#240 are in review by another session (world tasks) — R-lane links must not touch
  those files without checking that row in `ACTIVE_SESSIONS.md`.
- **Themes:** every new web-app UI uses the #95 token classes (`npm run lint:colors` must not grow) and is checked in
  `current` and `brand` with the page background (#231, on by default) on and off.
- **Siege code (R2):** the Siege Survival chain (#41) is in progress on the plugin; check its row and branches before
  changing siege startup code (§4.5 of chain 1).
- **Started as:** a subagent of the coordinator (chain 1 showed new sessions stall on `add_repo` approval), working in
  its own worktrees under `/home/user/wt-<link>/`, never in `/home/user/knk-workspace`.
