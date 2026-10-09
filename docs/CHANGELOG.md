# Knights & Kings changelog

This is a human-readable record of capabilities merged into the V3 default branches. It is not a complete commit log or a promise that code has been deployed to a public server. See [the feature register](FEATURE_REGISTER.md) for design, branch and live-verification status. Entries before this changelog was established on **2026-09-28** are a selective backfill from merge records and feature plans; linked plans describe the precise live-test coverage.

## 2026-10-09

- A navigating player off the road gets a walk path to it ([KNG-75](https://linear.app/kngpandi/issue/KNG-75) step 1;
  knk-plugin `main` `c4141f90`). The trail shows the way to where the route starts (stairs, ladders, doors the
  player may open) instead of a straight line, and the road guidance starts once the player reaches the road; no
  "You left the road" on the way there. The player may now start up to 96 blocks from a road (was 48), measured in
  plain 3D, so a tower roof above a road works; height still decides which road (a bridge over a road). Shut in:
  "No conventional path to the road found."; a way too long to work out (a tall spiral stair): "Having trouble
  determining the route - guiding you to the nearest road." with the part of the path found. Setting:
  `navigation.max-start-distance`. With walk paths off, nothing changes. Follow-up for tall buildings:
  [KNG-108](https://linear.app/kngpandi/issue/KNG-108).
- Gate commands get two layers ([KNG-77](https://linear.app/kngpandi/issue/KNG-77),
  [KNG-78](https://linear.app/kngpandi/issue/KNG-78), [KNG-79](https://linear.app/kngpandi/issue/KNG-79);
  knk-plugin `main` `5b1cc8b`, knk-web-api `master` `6192af0`):
  - `/gate` (`/knk gate`) acts on a whole gate and all its doors; `/gatedoor` (`/knk gatedoor`) acts on one door.
  - Both have open, close and **toggle**.
  - `here` picks the gate or door within 15 blocks, with a clickable choice when several are in range.
  - With no target, open, close, toggle, info and repair use the gate you are looking at, including an open one.
  - Per-id permissions now mean structure ids (`knk.gate.*`); door nodes are `knk.gatedoor.*`.
  - "here" is a reserved gate and door name.
  - See [architecture/gate-commands.md](architecture/gate-commands.md).
- The web app's entity navigator (left sidebar on the Dashboard and Forms pages) can be searched (display name or
  internal name) and sorted A–Z/Z–A ([KNG-61](https://linear.app/kngpandi/issue/KNG-61); knk-web-app `main`
  `ce47817`). On the Dashboard, types with a published default display configuration are listed under "Entities".
  The rest are in a collapsed "Without display configuration" group, and the Dashboard opens on the first
  "Entities" type. The sort direction and the group's open/closed state are remembered per page. Narrow-screen
  layout: [KNG-94](https://linear.app/kngpandi/issue/KNG-94).
- A navigation destination high above a road is no longer "too far from any road"
  ([KNG-75](https://linear.app/kngpandi/issue/KNG-75), finding N15; knk-plugin `main` `9f466a9f`). Destinations
  are measured to the nearest road in plain 3D; the player's own position still counts height ×4, so a player on
  a bridge keeps snapping to the bridge. A tower roof 28 blocks above a road is reached by road, then a walk path up.
  Setting: `navigation.destination-snap-vertical-weight` (default 1).
- Resetting a player's discovery on their moderation profile now asks in the app's own dialog instead of the
  browser's `confirm` ([KNG-40](https://linear.app/kngpandi/issue/KNG-40); knk-web-app `main` `6d23238`). After
  the reset the row leaves the list at once and a green line confirms it. The other `window.confirm` prompts are
  [KNG-82](https://linear.app/kngpandi/issue/KNG-82).
- Domain access refusals are also said in chat ([KNG-74](https://linear.app/kngpandi/issue/KNG-74); knk-plugin
  `main` `fd869aa`). The first "You are not allowed to enter/leave X." of a refusal episode goes to chat as well as
  the action bar. An episode is the first refusal after 10 s without one, or a different refusal. The `/navigate`
  arrow keeps off the action bar for about 3 s after a refusal, so the message can be read. Settings:
  `regions.access.chat-quiet-period-ms` and `action-bar-hold-ms`.
- Road navigation fixes from the live test, merged to knk-plugin `main`
  ([KNG-27](https://linear.app/kngpandi/issue/KNG-27), [KNG-51](https://linear.app/kngpandi/issue/KNG-51)):
  - a gate closing behind the player no longer blocks the route; the route is judged by the part of each road still
    ahead;
  - a nearby destination the walk path cannot reach is tried by road ("following the roads instead");
  - a destination on the open side of a closed gate is reached;
  - with no open route, the player is guided as close to the destination as the open roads go.

## 2026-10-08

- Road navigation is merged ([KNG-27](https://linear.app/kngpandi/issue/KNG-27); knk-plugin `main` `f9026cb`,
  knk-web-api `master` `4c570fa`, knk-web-app `main` `b51eba0`). The road graph is built per tile from the world's
  road materials, with curated tiles that only propose changes after their first build, admin tools (`/knk road …`) and
  a web-app road admin page. `/navigate` (`/nav`) guides players along the roads with a particle trail and a HUD to a
  Location, Town, District, Structure (gates included, also as `gate:`), street or named road node. It respects gate
  state, pass-through rights, domain entry/exit rules and sieges, and re-routes on live changes. Design:
  [navigation](specs/navigation/DESIGN.md).
- Walkable last-mile paths ([KNG-51](https://linear.app/kngpandi/issue/KNG-51)): near a target, and after the road
  ends, the trail follows a path a player can walk (stairs, ladders, doors they may open, no regions they may not
  enter) instead of a straight line. Without one it says "No conventional path to X found."
  ([last-mile design](specs/navigation/LAST_MILE_PATHFINDING.md)).
- Live-tested on the dev server 2026-10-07/08 ([smoke-test guide](guides/road-navigation-smoke-test.md), findings
  N1-N12). Still open: the siege check (C6). Follow-ups: KNG-73, KNG-74, KNG-75, KNG-76.

## 2026-10-06

- PermissionGrant forms can now search for and pick a holder (a user or a permission group) in the web app: the web-app half of the PermissionHolder lookup is merged ([KNG-38](https://linear.app/kngpandi/issue/KNG-38), knk-web-app `main` `24b60ac`), completing the API half from 2026-10-04.

## 2026-10-05

- The lootbox opening reel's passing items now carry real enchantments ([KNG-54](https://linear.app/kngpandi/issue/KNG-54)), rolled from the box's own enchant rolls and shown with the grade the box gives them, so the winner is no longer the only enchanted item on the reel ([lootboxes design §3.9](specs/lootboxes/DESIGN.md)).
- Blueprint item descriptions without a colour of their own now render dark gray instead of vanilla purple lore (this fixes Flaming Samurai).
- Every route that spawns an item from a blueprint (lootbox delivery and reel, kits, `/knk itemblueprints give`) now builds it through one `BlueprintItemAssembler` entry point, and `/ce add` shares the custom-enchantment lore pipeline with `/ce remove`; see the [item render pipeline](architecture/item-render-pipeline.md). knk-plugin `main` `74607a9`.
- Fixed `/ce remove` leaving a stray blank line at the top of an item's lore after removing its last custom enchantment; removal now shares the same lore re-compose as applying one (knk-plugin `main` `e55e87f`).

## 2026-10-04

- Held a lootbox opening-reel item that comes up while the player is in a siege until their own inventory is restored, instead of losing it with the siege inventory ([KNG-44](https://linear.app/kngpandi/issue/KNG-44), [plan](specs/lootboxes/IMPLEMENTATION_PLAN.md)).
- Replaced the lootbox admin Types tab's ~14 per-type odds requests with one staff-only batch endpoint, `GET api/LootboxTypes/odds` ([KNG-45](https://linear.app/kngpandi/issue/KNG-45), [plan](specs/lootboxes/IMPLEMENTATION_PLAN.md)).
- Completed the plugin command-completion sweep with permission-filtered subcommands, vanish-aware player names, cached offline names where supported, fixed-value suggestions and explicit suppression of Bukkit's fallback suggestions ([KNG-30](https://linear.app/kngpandi/issue/KNG-30)).
- Fixed non-op staff access to `/freeze`, `/unfreeze`, `/staffchat` and `/knk` through the in-house permission model, and corrected the `/minecraft:tell`/`w` secure-chat mismatch ([KNG-24](https://linear.app/kngpandi/issue/KNG-24), [KNG-25](https://linear.app/kngpandi/issue/KNG-25)).
- Ensured siege members enter matches in survival so spawn-safe-zone damage denial is observable, and completed stable item-lore section spacing plus coherent lootbox special-description coloring ([KNG-28](https://linear.app/kngpandi/issue/KNG-28), [KNG-29](https://linear.app/kngpandi/issue/KNG-29)).
- Corrected untouched PermissionGroup premium-tier fields to submit `false` rather than `null` ([KNG-26](https://linear.app/kngpandi/issue/KNG-26)).
- Added the API half of the polymorphic PermissionHolder lookup used by PermissionGrant forms ([KNG-38](https://linear.app/kngpandi/issue/KNG-38)); its web-app half remains on the feature branch and is not yet part of the default-branch UI.

## 2026-10-02

- Added the maintained V1 → V2 → V3 [feature register](FEATURE_REGISTER.md), documented feature and guide updates at merge, and established this changelog ([KNG-33](https://linear.app/kngpandi/issue/KNG-33), [PR #5](https://github.com/PandiO/knk-workspace/pull/5)).

## 2026-09-29 — Backfilled from documented trunk merges

- Added managed WorldGuard-region ownership, priority and category-flag policy with idempotent startup repair. The live in-game smoke test remains tracked by [KNG-46](https://linear.app/kngpandi/issue/KNG-46) ([architecture](architecture/managed-worldguard-regions.md)).
- Modernized the shared AI-agent workflow and portable repository entrypoints ([KNG-32](https://linear.app/kngpandi/issue/KNG-32)).

## 2026-09-28 — Backfilled from documented trunk merges

- Completed the teleport feature merge, including requests, spawn/warps and ignore integration ([KNG-17](https://linear.app/kngpandi/issue/KNG-17), [design](specs/teleport/DESIGN.md)). Housing-linked `/home` remains separate scope.

## 2026-09-27 — Backfilled from documented trunk merges

- Added a permanent coin/gem transaction ledger and secure player payments, balance commands and administration ([KNG-21](https://linear.app/kngpandi/issue/KNG-21), [design](specs/currency-payments/DESIGN.md)).
- Added first-entry Town, District and Structure discoveries, rewards and a Discoveries menu ([KNG-20](https://linear.app/kngpandi/issue/KNG-20), [plan](specs/domain-discovery/IMPLEMENTATION_PLAN.md)).
- Expanded private messages with ignore, social-spy controls and moderation history ([KNG-18](https://linear.app/kngpandi/issue/KNG-18)). Its secure-chat follow-up was later completed in [KNG-25](https://linear.app/kngpandi/issue/KNG-25).
- Added world lootboxes, token pickups and an opening reel ([KNG-19](https://linear.app/kngpandi/issue/KNG-19)). The second live retest and remaining decisions are tracked in [KNG-31](https://linear.app/kngpandi/issue/KNG-31).

## 2026-09-26 — Backfilled from documented trunk merges

- Merged the Siege MVP: configurable scenarios, teams, objectives, live matches and player menus, following two live smoke-test rounds. Scheduled lobbies are later scope ([siege plan](specs/siege-minigame/IMPLEMENTATION_PLAN.md)).
- Added title and premium-tier display in game chat/tab list ([KNG-7](https://linear.app/kngpandi/issue/KNG-7), [KNG-8](https://linear.app/kngpandi/issue/KNG-8)).
- Ported general enchantment books and grade-based application limits ([KNG-5](https://linear.app/kngpandi/issue/KNG-5), [KNG-6](https://linear.app/kngpandi/issue/KNG-6)).
- Corrected hourly title salary and join-time payouts ([KNG-16](https://linear.app/kngpandi/issue/KNG-16)).

## 2026-09-25 — Backfilled from documented trunk merges

- Merged the persisted kit system, grant commands and kit authoring workflow. First-join grant remained to be confirmed live in the [kit plan](specs/kits/IMPLEMENTATION_PLAN.md).

For older implementation detail, consult [feature plans](specs/README.md), [dated reports](reports/) and the repository histories. Do not interpret the first date of a branch or issue as a release date.
