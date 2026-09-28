Read docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md first and follow it; it overrides anything below.

Implement road navigation **Phase 5 — knk-web-app: admin pages** from docs/specs/navigation/IMPLEMENTATION_PLAN.md
(the "Phase 5 — knk-web-app: admin pages" section: `RoadDtos.ts`, `roadClient.ts`, `/admin/roads` route + nav,
`RoadsAdminPage` with `RoadProfilesCard` / `RoadTilesCard` / `RoadEdgesCard`, `StreetRoadPanel` registered as
`streetRoad`, jest + RTL tests), end to end (code, tests, commits, push to `claude/road-navigation`, plan status block,
progress report, handoff), as **link 8** of the chain. Phase 5 is "M"; no split expected.

**The web app is buildable in the cloud** — unlike the plugin phases you can run everything: `npm ci`, then
`npm run test:ci` on the clean branch **before your first change** (plan §0.4: the trunk failure count is not
documented — record it as your baseline), then again after. `CI=true npm run build` fails on pre-existing ESLint
warnings; don't fix those, just add no new warnings in the files you touch.

State you start from:
- **Phase 1 is done** (link 1): knk-web-api `claude/road-navigation` `77e0a29` (cut from `master` `ccc8c02`). The API
  contract you code against is the plan's "1.5 Controllers" route table and the "Phase 1 status → What later phases
  must wire → Phase 5 (web app)" note: `POST api/road-edges/search` filters `world`, `tileId`, `streetId`,
  `unlabelled`, `stale` (strings, `"true"`), `sortBy` `id | length | streetId | tileId`; `PUT api/road-edges/{id}`
  with `propagate: true` returns every changed edge id (`RoadEdgeUpdateResultDto {edge, changedEdgeIds}`); node edits
  lock the node unless `locked: false`; errors are `{ "error": "ValidationFailed" | "NotFound" | "Conflict",
  "message" }`; GETs are anonymous, writes need `knk.admin.road` (`StaffPermissions.RoadManage`) or the plugin's
  service key. DTO shapes: `W/Dtos/RoadDtos.cs` in knk-web-api (read-only clone: `GIT_LFS_SKIP_SMUDGE=1 git clone
  --depth 1 --branch claude/road-navigation https://github.com/PandiO/knk-web-api /home/user/pandio/knk-web-api`);
  `GET api/Streets/{id}/road` for the street panel; `GET api/road-network/meta?world=` for profiles + street names +
  components; `GET api/road-tiles?world=` for the tile overview.
- **Phases 2a-2e and 3 are done** (links 2-7): knk-plugin `claude/road-navigation` **`96f4c62`** (trunk `main` still
  `eb1d68c`). Phase 3's knk-paper code is **not compiled** (cloud network) — irrelevant to you except for two things it
  fixes for the web app: (1) profiles learned in game are created as class `Road`, cost 1.0, no scope, enabled — the
  profile editor is where the developer changes class/cost/scope (Phase 3 decision 16); (2) `StatsJson` stays opaque
  (never show or edit it; send `stats: null` on a profile PUT to keep it — 2e decision 3).
- **knk-web-app:** `claude/road-navigation` does **not** exist yet — create it from `origin/main` and push with `-u`
  (charter §1.2). The clone may land at `/home/user/knk-web-app` (add it with `add_repo`, push access). Measure the
  `npm run test:ci` baseline on the clean checkout first.
- **Workspace `main`** carries the progress report `docs/reports/2026-09-27-road-navigation-chain.md` (append your
  Phase 5 section, refresh the summary table — the 5 row is "in progress (link 8)") and the tracker row in
  `docs/ACTIVE_SESSIONS.md` (already names Phase 5 in progress with the file list; update as you go).

What earlier phases say Phase 5 must wire (plan "Phase 5" + the Phase 1 "→ Phase 5" note + reuse rows R34-R38):
- `F/types/dtos/road/RoadDtos.ts` (camelCase like the API — the C# `[JsonPropertyName]`s), `F/apiClients/roadClient.ts`
  (R35: singleton like `discoveryClient.ts`; `Controllers` enum entries `RoadProfiles = 'road-profiles'`, `RoadTiles =
  'road-tiles'`, `RoadEdges = 'road-edges'`, `RoadNetwork = 'road-network'` in `F/utils/enums.ts`; GET params only
  for keys you have — `undefined` is sent as the text "undefined").
- `ROAD_ADMIN_NODE = 'knk.admin.road'` next to the DTOs; route `/admin/roads` in `F/App.tsx` inside `StaffRoute
  node={ROAD_ADMIN_NODE}`; nav link + `nodeAccess` entry in `F/components/Navigation.tsx` (R34), lucide icon `Route`.
- `F/pages/admin/RoadsAdminPage.tsx` (thin: state, fetching, world selector) + `F/components/admin/roads/`:
  `RoadProfilesCard` (list/create/edit: name, class, cost, width, enabled, scope towns via `SearchableDropdown` over
  towns; materials table with a text input + `minecraftMaterialRefClient.getHybrid` suggestions (R38, D10), role
  select, ambiguous toggle, read-only shares; pure `roadProfileForm.ts` like `discoveryRuleForm.ts`), `RoadTilesCard`
  (x, z, version, built, dirty, counts, warnings expandable; filter dirty/warnings), `RoadEdgesCard` (server-paged
  `POST road-edges/search` with filters unlabelled/stale/street; inline edit of street (`SearchableDropdown` +
  `streetClient.searchPaged`, R37), cost, flags in the `DiscoveryOverridesCard` pattern; 4xx messages shown; **"Continue
  along the road"** checkbox default on → `propagate: true`, show how many stretches changed; **"Create street…"** →
  existing `streetClient.create`, then assign; **Rename** link → the existing Street edit form `/forms/street/edit/:id`).
- `F/components/roads/StreetRoadPanel.tsx` (like `SiegeReadinessPanel`) registered as `streetRoad` in
  `F/components/FormWizard/displayPanels.tsx` (R36); document in the status block how the developer adds it to the
  Street FormConfiguration (a field on `Id` with `settingsJson {"displayPanel":"streetRoad"}` — a dev-DB step).
- Tests (jest + RTL; `react-router-dom` virtual mock as in `DiscoveryAdminPage.test.tsx`): client URL/method tests,
  `roadProfileForm` parser, page renders + error state, edge inline edit save/cancel/4xx, panel loading/error.

Phase-specific reading: plan §0 (esp. 0.2, 0.4), §1 rows D5, D8, D10, D11, §2 rows R34-R38, "Phase 5" whole, the
Phase 1 status block's route table and "→ Phase 5" note, the Phase 3 status block's "→ 5" note; DESIGN §3 (data
model), §7 (admin tooling — the web-app paragraph and workflows D/E: street names stay editable in the web app).
knk-web-app: `F/pages/admin/DiscoveryAdminPage.tsx` + `F/components/admin/discovery/*` + `DiscoveryAdminPage.test.tsx`,
`F/apiClients/discoveryClient.ts`, `F/utils/enums.ts`, `F/App.tsx`, `F/components/Navigation.tsx`,
`F/components/SearchableDropdown.tsx`, `F/apiClients/streetClient.ts`, `F/apiClients/minecraftMaterialRefClient.ts`,
`F/components/FormWizard/displayPanels.tsx`, `F/components/siege/SiegeReadinessPanel.tsx`. knk-web-api (read-only):
`Dtos/RoadDtos.cs`, `Controllers/Road*Controller.cs`, `Controllers/StreetsController.cs` (`{id}/road`).

Open flags that affect this phase: none. Decisions to take alone (plan §0.2): table density and paging sizes, how the
world selector is populated (the tile list's worlds, else a text field), whether the edge table shows geometry (no —
just counts and a length), how warnings expand. Take the reversible default and number it.

Known risks:
- **Baseline:** the trunk `npm run test:ci` failure count is undocumented — measure it first and report "baseline +
  new tests" exactly; if the clean checkout fails to install or test, that is worth a note in the report, not a
  blocker (charter §4.2 applies only to modules you changed).
- **ESLint:** `CI=true npm run build` fails on pre-existing warnings; don't touch them.
- **Toolchain/layout:** Node is expected in the container; the workspace clone may be in detached HEAD — `git checkout
  main`, `git pull --ff-only origin main` before editing docs (other sessions push to `main`); `add_repo` (push
  access) is needed before the first push to knk-web-app. Long shell heredocs may stall — write files with the
  file-writing tool.
- **Scope:** web app only; nothing in knk-web-api or knk-plugin. Street renaming stays owned by the Street entity
  (link to its form; don't add road-specific name storage).
- **Size:** "M" — commit and push after each logical part (DTOs + client; route + nav + page shell; profiles card;
  tiles card; edges card; street panel; tests).

Next after you: **Phase 4** (`/navigate`, plan "Phase 4") **only if KNG-17 is on trunk** — check with
`git -C <knk-plugin> ls-tree -r --name-only origin/main | grep core/teleport/WarpTargets` (charter §4.7). If it is,
write `docs/ai-agents/handoffs/<date>-road-navigation-phase-4.md` and start link 9 per charter §6; Phase 4 must merge
trunk into `claude/road-navigation` first and wire the Phase 3 status block's "→ 4" note (`plugin.getRoadNetworkCache()`,
`getRegionTracker().regionIds()`, `GatePassThroughRules.canPass`, `ParticleDraw.polyline`, `NavigationConfig`
mappings). If KNG-17 is **not** on trunk, write the Phase 4 handoff for later, record "waiting for KNG-17" in the
report and tracker, mark the chain finished for now (charter §4.7) and start no further link.
