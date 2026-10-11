# Knights & Kings changelog

This is a human-readable record of capabilities merged into the V3 default branches. It is not a complete commit log or a promise that code has been deployed to a public server. See [the feature register](FEATURE_REGISTER.md) for design, branch and live-verification status. Entries before this changelog was established on **2026-09-28** are a selective backfill from merge records and feature plans; linked plans describe the precise live-test coverage.

## Unreleased — on feature branches, not merged

- Nothing pending here at the moment.

## 2026-10-11

- **New players get the first-join kits** ([KNG-81](https://linear.app/kngpandi/issue/KNG-81), plugin half; knk-plugin
  `main` `0ee516aa`). A player the server has never seen now receives every kit marked "Grant on first join" a moment
  after joining, exactly once. A relog grants nothing more, and an existing account never gets them. Three causes,
  all fixed: `KnKPlugin` built two caches, and the join listener read the one that never held the new account; the
  account created at pre-login was not marked as new; and the plugin misread the API's create response
  (`{user, linkCode}`), so creating the account failed before it was cached. That last one was already broken
  before. Live-tested 2026-10-11.
- **API connectivity: one up/down view of the API** ([KNG-115](https://linear.app/kngpandi/issue/KNG-115)): live-tested
  by the developer and merged. knk-web-api `master` `17ee730`, knk-plugin `main` `b5eee6e`.
  - The API's `GET /health/ready` now checks MySQL: 503 `unhealthy` when the database is down (never a 500), 200
    otherwise. A database outage is logged once when it starts and once when it ends.
  - The plugin probes `/health/ready` at the API root every 10 s (5 s timeout, never cached). It keeps one state:
    DOWN after 3 failed probes, UP after 2 passing ones. Each change fires `ApiConnectivityChangedEvent` on the main
    thread and is logged. `/knk health` shows the state, how long it has held and the last probe. Settings:
    `config.yml` → `api.connectivity`.
  - Nothing reacts to the event yet; offline security (KNG-58), hub outage actions (KNG-109/114) and Siege
    containment (KNG-117) will subscribe. See [architecture](architecture/api-connectivity.md).
- Players in owner mode or staff mode no longer show in the multiplayer server list ([KNG-127](https://linear.app/kngpandi/issue/KNG-127);
  knk-plugin `main` `ac2855a`). They were already hidden in game and in the tab list; the server list still counted them
  and showed their names when hovering over the player count. Now they are left out of both, and the Game Settings MOTD's
  `{online}` shows the same lowered count. The list has no viewer, so they are hidden there from staff too. Not yet
  checked in game.
- **Player statistics, leaderboards, owner diagnostics, GDPR deletion and world analytics** ([KNG-34](https://linear.app/kngpandi/issue/KNG-34),
  with [KNG-14](https://linear.app/kngpandi/issue/KNG-14)): merged after a live smoke test of all 27 steps
  ([guide and findings](guides/player-statistics-smoke-test.md)). knk-web-api `master` `34b8f9b`, knk-plugin `main`
  `aa5df70a`, knk-web-app `main` `5f40f93`. Six migrations (`AddPlayerStatistics` … `SeedStatisticsStaffNodes`).
  - **Statistics:** logins, active and AFK time (`/afk`, auto-AFK with an `[AFK]` tab marker in the group color), distance
    on foot, flying and in vehicles (mounts included), highest fall, PvP/PvE kills, deaths, damage, killstreaks, Siege
    results, coins/gems/XP earned and spent from the ledger (all past activity imported), title history, discoveries.
    Spooled to disk while the API is down.
  - **Privacy:** every statistic has its own visibility (Nobody by default, Friends, Everyone), set in game
    (`/stats settings`, a clearer group menu) or on `/account`, with a preview before group changes and a check for
    changes made elsewhere meanwhile.
  - **Read surfaces:** Profile → Statistics, `/stats [player]`, `/leaderboard` (`/lb <board> [period]` opens the board
    menu), web `/account`, `/players/<name>`, `/leaderboards` and a staff panel. Boards rank only statistics shown to
    everyone, cap repeat kills of the same victim at 3 a day, and support owner exclusions.
  - **Owner tools:** `/owner/telemetry` (diagnostic events, test runs, enhanced mode, player timeline), `/owner/privacy`
    (GDPR deletion: player requests with an email link, staff requests, 5-day grace period, erasure),
    `/owner/analytics` (movement heatmaps, menu funnels including Escape closes, domain entries/exits). Owner nodes
    `knk.owner.*`; wildcards unlock only analytics and leaderboard exclusions (D24). Moderators and Admins get
    `knk.admin.statistics.view`, Admins also `knk.admin.privacy.request`.
  - Kill switches in the plugin and API config. Follow-ups: [KNG-125](https://linear.app/kngpandi/issue/KNG-125)
    (menu item blinker), [KNG-126](https://linear.app/kngpandi/issue/KNG-126) (Reverse button feedback, trunk).

## 2026-10-10

- Gate teleports land somewhere safe, and gate doors no longer hurt players ([KNG-105](https://linear.app/kngpandi/issue/KNG-105),
  [KNG-106](https://linear.app/kngpandi/issue/KNG-106); knk-plugin `main` `8457657`). `/gatedoor tp` puts you on the
  ground next to the door, in front of or behind it, never inside its blocks or its opening, and refuses when there is
  no safe spot within 4 blocks. `/gate tp` uses the gate's spawn point (its Location) when set, else a safe spot by its
  first door, and says which. A closing or opening door (including a drawbridge's swing) now moves players, mobs,
  dropped items and vehicles with their riders out of its way before its blocks land, to solid ground on their own
  side when there is room; before, the collision check looked the wrong way while a door closed, and the push sent
  people behind a door through it. Anyone found inside door blocks (after a teleport, on join) is moved out, and door
  blocks cause no suffocation damage (`gates.safety.door-suffocation-damage: false`). Live-tested 2026-10-10.
- The first-join kit grant now runs once per player ([KNG-81](https://linear.app/kngpandi/issue/KNG-81), API half;
  knk-web-api `master` `d5293fd`, migration `AddUserFirstJoinKitsGrantedAt`). A repeated or simultaneous
  grant-first-join call (a quick relog) no longer adds a second kit claim or second lootbox tokens; players already
  holding a first-join kit are marked as granted. Live-tested against the API 2026-10-10. The game server does not
  trigger the grant yet: the plugin half (one `CacheManager` in `KnKPlugin`) is still open.
- Walk paths get through tall buildings ([KNG-108](https://linear.app/kngpandi/issue/KNG-108); knk-plugin `main`
  `a388c70`). A walk path may now be 5 blocks longer for every block of height between the player and where they are
  going, so the way down a tower's spiral stair (the Keep Tower Roof: 168 blocks for 29 of height) is found. From
  such a roof the player gets the full path to the road instead of "Having trouble determining the route - guiding
  you to the nearest road.", and a destination on a roof gets a full path up. Setting:
  `navigation.walk.climb-allowance` (5; 0 = as before). A server `config.yml` needs no change. Known gap, not new: a
  player shut in within 8 blocks of a road is not told so ([KNG-124](https://linear.app/kngpandi/issue/KNG-124)).
- The game server now knows the domain of every region it preloads ([KNG-122](https://linear.app/kngpandi/issue/KNG-122);
  knk-plugin `main` `68022ce3`). The API answers a region lookup with at most one town, district and structure, so
  preloading several districts at once (when the road network loads, after `/knk cache refresh`, or for the regions at
  a spot) kept only one of them. The others were looked up later, one at a time, blocking routes for up to 3 seconds,
  and an overlapping second district could go unnoticed. The server now asks about each region on its own, a few at a
  time. The API and the web app are unchanged.
- A required yes/no (Boolean) field left unticked no longer blocks **Next** in FormWizard forms
  ([KNG-53](https://linear.app/kngpandi/issue/KNG-53); knk-web-app `main` `955fa20`). The KNG-26 fix only covered a
  brand-new form; resumed drafts saved before it and edit forms whose record had no value still held an empty value
  behind the unticked box. Every way a form is filled in now treats an unticked box as `false`. Also fixed: a saved
  `false` in a child/join form (e.g. a siege gate's Damageable) showed ticked when the field's default is on.
  Live-tested 2026-10-10.
- Domain forms accept an empty nullable field again ([KNG-119](https://linear.app/kngpandi/issue/KNG-119); knk-web-api
  `master` `a9e68f0` with migration `ClearPlaceholderFormFieldDefaults`). Editing a Town, District, Structure or
  GateStructure with **Road Access Override** (or Navigation Default Override, or another optional number, yes/no
  or choice field) left empty failed: entity metadata gave such fields the made-up default value "default", the
  Form Builder saved it on the field, and the form submitted it for the empty value. Metadata now reports no default
  for them, and the migration removes the saved "default" from existing form fields (text fields are left alone).
  An empty override follows the domain type again. The web app is unchanged.
- Navigation takes a road that a no-entry region covers only in part ([KNG-110](https://linear.app/kngpandi/issue/KNG-110),
  finding P4; knk-plugin `main` `4b9ddca4`). A region now blocks a road only where it covers the road's whole width:
  one free block beside it is enough, and the trail moves onto the free part, so the region's border does not push
  the player back. A region over the whole width blocks as before; for a player who may not leave a region, a stretch
  whose middle is in it still counts as inside. New: a region a player may enter but not leave blocks the way to a
  destination outside it ("You could not leave X again"), so navigation no longer leads players into it on the way
  somewhere else; a destination inside it is still reached. `/knk road status` counts the road pieces with such gaps.
  No new settings; the API and the web app are unchanged.
- Game Settings are applied in game ([KNG-52](https://linear.app/kngpandi/issue/KNG-52); knk-web-api `master`
  `8cce48d` with migration `AddGameSettingsMotdAndGroupOverrides`, knk-plugin `main` `973aa68b`, knk-web-app `main`
  `12c1d60`).
  - **What the page controls:**
    - the join and leave messages (`{player}`, `{group}`, `{title}`);
    - where regular players arrive on join (also the `/spawn` destination);
    - the server-list MOTD;
    - per world: the default game mode on join, a time lock, the weather rule (Normal, Constant, Blocked,
      Weighted) and the spawn point.
  - **Respawn per world:** synced with the join spawn, the world spawn (beds and anchors ignored), the server's
    choice (beds count), a chosen spot or the nearest town.
  - **Permission groups** can override the join and leave message, the spawn (a chosen spot, or "where they
    logged out" like owners) and the respawn. A player's groups count in the teleport-fee order (highest Weight
    first, each followed by its parents).
  - **Behaviour changes:**
    - **The hard-coded "respawn in town 4" is gone.** Respawn follows the page; choose Town 4 there to keep it.
    - Saving the page now needs `knk.admin.config`.
    - A staff `/weather` in a world with a weather rule asks for confirmation first.
    - The plugin keeps working from `plugins/KnightsAndKings/game-settings-cache.json` while the API is down.
  - **Spawn picker:** redesigned (a card for the chosen spot, a grouped searchable list with type chips). It now
    lists Structures, which were missing because the web app called a Locations route that doesn't exist.

- Navigation reaches destinations further off-road ([KNG-75](https://linear.app/kngpandi/issue/KNG-75) step 2;
  knk-plugin `main` `8f2b7c30`). A destination may now be up to 256 blocks from a road (was 48). Within 96 blocks of
  where the road ends, the last stretch is a walk path; further out, the player is told "No conventional path to X
  found." and the HUD arrow and distance point the way until they are within 96 blocks, when a walk path takes over.
  Walk paths may now be up to 144 blocks long (was 96), and walks of up to 96 blocks, also to the road at the start,
  no longer fall back to a straight line for lack of captured terrain. Settings: `navigation.max-destination-distance`,
  `navigation.destination-walk-range`, `navigation.walk.max-length` (a server `config.yml` that spells out
  `max-length: 96` keeps the old cap - change it to 144). With walk paths off, nothing changes. KNG-75 is complete;
  follow-ups [KNG-108](https://linear.app/kngpandi/issue/KNG-108) (tall buildings) and KNG-36 (longer walks).

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
- Location retention is merged ([KNG-80](https://linear.app/kngpandi/issue/KNG-80); knk-web-api `master` `c397585`,
  knk-web-app `main` `d10e3dd`, knk-plugin `main` `68a5310`). A weekly check (Sunday 04:00 server time, configurable,
  plus "Run check now") flags Locations that still have the default name and that nothing uses, read from the database
  model rather than a hand-kept list, after a 7-day grace period. Staff review them under Player moderation → Orphaned
  Locations and keep or delete each one; nothing is deleted automatically, and a delete re-checks first. Kept Locations
  come back after 6 months or when they change. Online staff get one digest per run with something new;
  `/knk location orphans` and `/knk location tp <id>` work in game. New Moderator and Admin permission groups carry the
  new `knk.admin.location.*` nodes. Live-tested 2026-10-09
  ([smoke test](guides/location-retention-smoke-test.md), findings F1-F3 fixed). Follow-up: KNG-107.
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
