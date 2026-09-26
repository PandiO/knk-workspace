# Siege Minigame — Inventory Menu Templates

**Status:** **Implemented** — merged into the default branches on 2026-09-26 and smoke-tested live. Part A
is a source-verified inventory of every legacy Siege menu; Part B's InventoryMenu engine extensions are
built and merged; Part C is the v3 template set, seeded create-only by knk-web-api
`Models/Menu/MenuTemplateSeed.Siege.cs` (`siege.overview`, `siege.information`, `siege.spawnpoint`).
Where the seeds differ from the original draft, Part C says so inline.
**Last updated:** 2026-09-26 (synced with the smoke-tested seeds: Dynamic heights, cooldown lobbies not
opened, remembered spawn choice)

Ref: `DESIGN.md` §10 (menus in the Siege design), `docs/specs/inventory-menu/` (engine),
`docs/specs/legacy/inventory-menus.md` (legacy engine bugs), gap report
`docs/reports/2026-09-25-siege-minigame-gap-analysis.md` §3 (defects referenced here as **N#**).

Sources, read in full: v2 `model/menu/main/{MainMenu,SiegeOverviewItem}.java`,
`model/menu/siege/{SiegeOverview,SiegeSelectItem,ObjectiveItem}.java`,
`model/menu/siege/information/{InformationOverview,JoinLeaveItem,ScenarioItem}.java`,
`model/menu/siege/spawnpoint/{SpawnpointOverview,SpawnpointItem}.java`,
`model/menu/{BackMenuItem,PageButton,TabNext,PlayerItem}.java`, `menu/preset/menu/siege/SiegeOverview.java`;
the runtime callers in `model/minigame/siege/Siege.java` (`updateMenus`, `startProgress`, `vote`,
`joinPlayer`, `leavePlayer`); v1 `src/Menu/Menu.java:5531-6228`, `src/Menu/EventsClick.java:56-240`.

---

## Part A — Legacy menus (as built)

### A.0 Colour legend

v2 lore mixes colours inline via `ColorOptions` (`util/ColorOptions.java`). The roles, used in every
table below:

| Role | Colour | Used for |
|---|---|---|
| `message` | GRAY | labels, body text |
| `messagesubjects` | GREEN | values, "Click to …" hints, titles |
| `error` | RED | negative values, denials, "Voted" |
| `coinStats` | YELLOW | menu titles, "Description" heading |
| `messageformat` | GOLD | "The goal:" block |
| `messageachievement` | AQUA | achievement-style lines |
| `stats` / `statsresults` | AQUA / GREEN | player-info label / value |
| `KAKColor` | BLUE | "Knights and Kings Menu" title |

In the tables, `GRAY:"Scenario: " + GREEN:<name>` means one lore line with two colour runs.

### A.1 Navigation graph

```
v2:  /menu ─► MainMenu ──(slot 14)──► SiegeOverview ──(siege row)──► InformationOverview
     /siege join <id> ───────────────────────────────────────────────► InformationOverview (no previous → "Exit")
     match start (+1 s) / PlayerRespawnEvent in match ─────────────────► SpawnpointOverview (no previous → "Exit")

v1:  Personal Menu ► Events ► SiegeOverview ─(click = join!)─► SiegeInformation
     (opening SiegeOverview while already in a siege jumps straight to that siege's Information)
     respawn in match ─► SiegeSpawnpointMenu
```

Live updates (v2): `Siege.updateMenus(reOpen)` runs every second from the matchmaking/progress/cooldown
tickers with `reOpen=false` (re-render the `SiegeSelectItem` in any open `SiegeOverview`, and slot 4 of
any open `InformationOverview`), and with `reOpen=true` on every phase change, join and leave (re-open
every viewer's `SiegeOverview`/`InformationOverview` from scratch).

### A.2 Main-menu entry — `SiegeOverviewItem` (v2 `MainMenu` slot 14)

`MainMenu`: title BLUE "Knights and Kings Menu", 27 slots (`getMenuSize(18)`), items: Exit @8,
`KitOverviewItem` @12, **`SiegeOverviewItem` @14**, debug "Overview of Caches" @22.

| Property | Value |
|---|---|
| Material / amount | `WHITE_BANNER` ×1 |
| Name | GREEN "Siege Minigame" |
| Lore | 1 GRAY "Click here to see" · 2 GRAY "and join active Siege games" · 3 "" · 4 YELLOW "Description" · 5 GRAY "Siege is a minigame where" · 6 GRAY "teams fight against eachother." · 7 GRAY "The defending team defends" · 8 GRAY "a main objective and multiple" · 9 GRAY "side objectives against the attackers," · 10 GOLD "The goal:" · 11 GOLD "-Attackers: Capture the objectives" · 12 GOLD "-Defenders: Defend the objectives" |
| Click (any type) | Open `SiegeOverview(owner=clicker, target=clicker, previous=MainMenu)` |
| Failure | Chat RED "Something went wrong while trying to open Siege overview. Please notify a Staff-member." |
| Conditions | None beyond `/menu`'s blanket `k&k.menu.menu` |

### A.3 `SiegeOverview` — list of sieges (v2 `model/menu/siege/SiegeOverview.java`)

Title YELLOW "Siege Minigame". Size `getMenuSize(max(9, siegeCount))` = `9 + 9·ceil(n/9)` (18 slots
for 0–9 sieges). `pageCapacity` 36. Content: every `Siege` in the cache.

| Slot | Item | Material | Name | Lore | Click → function | Shown when |
|---|---|---|---|---|---|---|
| 4 | Header (plain `MenuItem`) | `WHITE_BANNER` | GREEN "Siege" | GRAY "Check the status of" · GRAY "active sieges or join" · GRAY "a siege" · "" · GRAY "Current amount of sieges: " + GREEN `<count>` · GRAY "Players playing Siege: " + GREEN `<Σ members>` | none | always |
| 8 | `BackMenuItem` | `BARRIER` | RED "Back" (or "Exit" if no previous) | `%getBackPhrase%` → intended GRAY "Click here to go back to `<previous title>`" (**never substituted**, N11) | Close; reopen previous menu (or just close); sound `BACK_CLICK` | always |
| 13 | "No Sieges" | `BARRIER` | RED "No Sieges" | GRAY "There are currently no active Sieges." · GRAY "Please ask a Donator or member of staff to start one." | none | no sieges exist |
| 1 / 7 | `TabPrevious` / `TabNext` (`PageButton`) | `ARROW` | GREEN "%getPageDirection% page" | GRAY "Click to go to the %getPageDirection%" · GRAY "tab of " + GREEN "Sieges" · "" · GRAY "Current page: " + GREEN "%getCurrentPage%/%getLastPage%" | LEFT = own direction, RIGHT = opposite — **dead**: falls through to `Menu.nextPage()` fail-sound stub (N16) | > 36 sieges |
| 9… | `SiegeSelectItem` ×n (A.4, `clickable=true`) | by phase | | | open Information | one per siege, sorted matchmaking **last** (N5) |

### A.4 `SiegeSelectItem` — one siege row (v2 `model/menu/siege/SiegeSelectItem.java`)

Used in A.3 (`clickable=true`) and as the header of A.5 (`clickable=false`).

| Property | Value |
|---|---|
| Material | `WHITE_BANNER` in cooldown · `GREEN_BANNER` in matchmaking · `RED_BANNER` in progress |
| Amount | member count (min 1) — the stack size doubles as a player counter |
| Name | GRAY "Siege " + GREEN `<index+1 in unsorted cache list>` (N5) |
| Lore 1 | GRAY "Scenario: " + scenario name · RED "Not set" if none · GRAY "Voting.." if matchmaking with candidates and none drawn yet |
| Lore 2 | GRAY "Joined players: " + (RED "None" \| GREEN `<n>`) |
| Lore 3 | GRAY "Current stage: " + GREEN ("Cooldown" \| "Matchmaking" \| "In progress") |
| Lore 4–6 | " " · GRAY ("Time until matchmaking starts:" \| "Time until game starts:" \| "Time until game ends:") · GRAY `%timeformat_get{Cooldown,Matchmaking,Progress}Seconds%` (**raw codeword in-game**, N11) |
| Lore 7 | " " |
| Lore 8 | matchmaking && clickable: GREEN "Click to join!" · not matchmaking: RED "Can't join match!" + RED "Wait for matchmaking to start" |
| Click (any type) | `clickable` → open `InformationOverview(clicker, clicker, previous=this menu, siege)`. **Does not join**, despite the "Click to join!" lore |
| Failure | Chat RED "Something went wrong while trying to open Siege Information overview. Please notify a Staff-member." + `FAIL_CLICK` sound |
| Conditions | None at click time; the Information menu itself rejects cooldown |
| Author TODOs | "Should make the time update itself"; "Make specific stages for the Siege" (phase flags) |

### A.5 `InformationOverview` — one siege's lobby (v2 `…/information/InformationOverview.java`)

Title YELLOW "Siege Information". Size `getMenuSize(18 + members)`. `pageCapacity` 27. Previous =
`SiegeOverview`, or none when opened by `/siege join` (Back becomes "Exit").

**Phase COOLDOWN:** menu is not built — reopens the viewer's previous menu and sends RED "Can't view
information. Siege is in cooldown!".

**Phase MATCHMAKING:**

| Slot | Item | Material | Name | Lore | Click → function | Conditions / notes |
|---|---|---|---|---|---|---|
| 4 | `SiegeSelectItem` (`clickable=false`) | by phase | as A.4 | as A.4 minus "Click to join!" | none | refreshed every second |
| 8 | `BackMenuItem` | `BARRIER` | RED "Back"/"Exit" | `%getBackPhrase%` | back/close | |
| 14 | `JoinLeaveItem` | joined: `SPRUCE_DOOR` · not: `GREEN_CONCRETE` | joined: RED "Click to leave" · not: GREEN "Click to join" | GRAY "You have joined this Siege" \| GRAY "You are not participating in this Siege" | toggles `siege.leavePlayer` / `siege.joinPlayer`, then `updateMenus(true)` (reopens every viewer) | Join refused unless `joinable`; after the scenario is drawn (last 25 s) also refused at `playersMax` ("Maximum amount of players has been reached"); generic refusal RED "Can't join Siege."; success GREEN "You joined a Siege" + broadcast "Player X joined the Siege!" to members. Leave: teleports back to join location (if already in hub), strips votes, RED "You left a Siege". No title gate (v1 had one) |
| 12 | Vote summary | `COMPASS` | GRAY "Voting for scenario.." | per candidate: "" · GRAY "Scenario: " + GREEN `<name>`; then RED "Join the Siege to vote" if not participating | none | only while candidates exist and none drawn; after the draw the item is created with no name/material (blank) |
| 10, 9 | `ScenarioItem` per candidate (first at 10, second at 9 — reversed) | `MAP` | GREEN `<scenario name>` | GRAY "Town: " + GREEN `<town>` · GRAY "Districts: " + GREEN `[d1, d2]` · "" · GRAY "Min. players: " + GREEN `%getPlayersMin%` · GRAY "Max. players: " + GREEN `%getPlayersMax%` · "" · GRAY "Amount of objectives: " + GREEN `%getObjectiveAmount%` · GRAY "Objectives with gate: " + GREEN `%getGateObjectiveAmount%` · "" · GRAY "Amount of votes: " + GREEN `%getVoteAmount%`; if viewer participating: "" + (RED "Voted" \| GREEN "Click to vote") | Not a member → RED "You must join the Siege before you can vote." · already voted this → `vote(null)` (clears **all** votes incl. random) → **NPE** (N17) · else `vote(scenario)` (moves vote, clears random vote); then re-renders slots 9–11 for all viewers | amount = vote count (min 1) |
| 11 | "Random" | `MAP` | DARK_PURPLE "Random" | GRAY "A random map will" · GRAY "be chosen" · "" · GRAY "Amount of votes: " + GREEN `%getRandomVoteAmount%`; if participating: "" + (RED "Voted" \| GREEN "Click to vote") | **none — no action attached** (N2) | |
| 18–26 | Filler | `BLACK_STAINED_GLASS_PANE` | " " | — | — | raw `inventory.setItem`, not menu items |
| 22 | "Joined Players" | `SKELETON_SKULL` | GREEN "Joined Players" | GRAY "Joined players: " + (GREEN if >1 else RED) `%getMemberAmount%` | none | amount = member count (min 1) |
| 18 / 26 | `TabPrevious` / `TabNext` | `ARROW` | as A.3, subject "Joined players" | as A.3 | dead (N16) | > 27 members |
| 27… | `PlayerItem` per member, sorted by cash ascending | `PLAYER_HEAD` (member's skin) | GREEN "%username%'s " + GRAY "information" | AQUA "Username: " + GREEN "%username%" + GOLD "(" + YELLOW "Donator" + GOLD ")" (hardcoded "Donator" for everyone) · AQUA "Cash: " + GREEN "%cash%" | none | ~10 more stat lines commented out (title, gender, XP, gems, houses, properties, kills, deaths) |

**Phase IN PROGRESS:** only slot 4 + Back are built — the "Team/Objective related items" block is an
empty comment inside the matchmaking branch (N6).

### A.6 `SpawnpointOverview` — respawn picker (v2 `…/spawnpoint/SpawnpointOverview.java`)

Opened for every member 1 s after match start (`Siege.startProgress`), and on `PlayerRespawnEvent` in
a match when the team has more than one spawn option (`PlayerListener.respawn`, after respawning the
player at their `currentSpawnpoint`). Title GREEN "Choose a place to spawn". Size
`getMenuSize(spawnpoints + heldObjectives)`. `pageCapacity` 36. No previous → "Exit". Closing the menu
= stay at the default respawn point.

| Slot | Item | Material | Name | Lore | Click → function | Conditions |
|---|---|---|---|---|---|---|
| 8 | `BackMenuItem` | `BARRIER` | RED "Exit" | `%getBackPhrase%` | close | |
| 1 / 7 | Tabs | `ARROW` | subject "Spawnpoints" | as A.3 | dead (N16) | > 36 options |
| 9… (held objectives first) | `ObjectiveItem` | `LEGACY_BANNER` with the objective's live banner patterns (capture-progress gradient) | GRAY `<objective name>` | not contested: GREEN "Click to spawn here" · contested: RED "Can't spawn here" + RED "Objective is being captured!" | re-checks: siege/team resolved and team still **holds** it; contested → RED "This objective is being captured!" + re-render; else `member.spawn(objective)`: teleport within 3 blocks of the objective, action bar GRAY "You have spawned at `<name>`" — **does not** reset health/food | "contested" = `calculateCapturePoints() > 0` right now (full player scan per render and per click, N7) |
| …then team spawnpoints | `SpawnpointItem` | `GREEN_CONCRETE` | GRAY "Spawnpoint `<name>`" | GREEN "Click to spawn here" | re-checks the spawnpoint belongs to the clicker's team; `member.spawn(spawnpoint)`: teleport within 3 blocks, full health, food 20, action bar GRAY "You have spawned" | |

### A.7 Orphaned v2 rewrite — `menu/preset/menu/siege/SiegeOverview.java`

Single commit `514367d "Begun adding Siege overview menu"` (2022-11-14), unreachable. Same texts as
A.2/A.3 rebuilt on the flexbox `menu/` framework: a static `getMenuOpenButton()` (A.2's item,
`Position.ABSOLUTE`, start slot 4, LEFT-click → `MenuOpenCommand(SiegeOverview)`), and a
`DisplayableListFormattedMenuSection<Siege>` of height 3 whose header uses `$repo.getCache.getList.size$`
/ `$repo.getUsersPlaying$` variables, plus a `Priority.LOW` "No Sieges" barrier at slot 13. It is the
direct ancestor of the v3 engine's design (definition/instance split, `$…$` getter chains), which is
why Part C reuses its structure.

### A.8 v1 differences worth keeping

| v1 feature | Where | Keep in v3? |
|---|---|---|
| Overview row shows "Skilled match: Skilled/Regular" and title-gated join lines ("Allowed titles: X till Y" / "higher than X") | `Menu.openSiegeOverview` | **Yes** as a `MinTitleBracketId` entry gate on the scenario (DESIGN §3.3, §6.2); "skilled match" title *ranges* not ported (open question in DESIGN §13) |
| Opening Overview while in a siege jumps straight to your siege's Information | same | **Yes** (`siege.entry` resolves this) |
| Overview click **joins** immediately | `EventsClick.onSiegeOverviewClick` | **No** — join stays an explicit button (N15) |
| Information, in progress: "Your team: X" on the header, siege banner in team colour | `Menu.openSiegeInformation` | **Yes** |
| Information, in progress: Main objective @9, side objectives @10+ with "Held by", "Captured: X%", "Captured by" and live banner gradient | same | **Yes** — this is exactly what v2 never finished (N6) |
| Information, in progress: "Change spawnpoint" button @3 | same (dead, N14) | **Yes, working** — opens the spawn picker |
| Information: long "Description for objectives" help text on an objective-info banner @6 | same | **Yes**, as a static help item |
| Participant heads with the viewer's own head glowing; "Average title" on the players item | same | **Yes** (glow = `HIGHLIGHT`); average title optional |
| Spawnpoint menu not opened when the team has exactly one option; menu closes after a successful spawn | `Menu.openSiegeSpawnpointMenu`, `EventsClick.onSiegeRespawnClick` | **Yes** |

---

## Part B — InventoryMenu engine extensions required first

The v3 engine (`docs/specs/inventory-menu/IMPLEMENTATION_PLAN.md` Phases 1–8) could not express these
menus (gap report §4). Built as **InventoryMenu Phase 9 — domain integration**, a prerequisite of Siege
implementation Phase 8 (`IMPLEMENTATION_PLAN.md`); merged with the siege work *(updated 2026-09-26)*. Each is generic — Kits' future menu needs the
same set.

| # | Extension | Why Siege needs it | Sketch |
|---|---|---|---|
| E1 | **Menu context parameters** | "Information for lobby 3" | `menu.open` accepts `ctx.*` params (`{"key":"siege.information","ctx.lobbyId":"3"}`); `MenuSession` nav stack stores `(key, ctx)`; `$ctx.lobbyId$` resolvable; back navigation restores both |
| E2 | **Feature-registered variable roots** | `$siege…$`, `$siegeViewer…$` | A `MenuVariableProviderRegistry`: a feature registers `root → (declaredType, (player, ctx) → value)`. `MenuVariableContext` becomes the default provider for `player`. The validator reads declared types from the registry, so providers must register before `MenuDefinitionValidationRunner` runs |
| E3 | **Row templates for content sources** | Persisted display for siege/candidate/player/objective/spawn rows (today rows are Java-mapped, e.g. `ItemBlueprintMenuMapper`) | A content source may return plain row objects; the section's single `MenuItemTemplate` flagged `IsRowTemplate` renders each row with root `$row$`. `$…$` interpolation also applies to `ActionBinding.ParamsJson`, `ConditionBinding.ParamsJson` and `ContentSourceParamsJson` values |
| E4 | **Live repaint** | Countdowns, capture %, vote counts | `MenuTemplate.AutoRefreshTicks` (nullable): re-render open instances every N ticks, respecting each binding's `RefreshPolicy`; plus `MenuService.refreshOpenMenus(Predicate<OpenMenuContext>)` for event-driven refresh (join/leave/vote/phase change) |
| E5 | **Render-time conditions** | Items that exist only in one phase (join button, vote items, objective status) | `ConditionBinding.Phase` = `Click` (today's behaviour, default) \| `Render` (a denying render condition hides the item) |
| E6 | **Item-meta bindings** | Phase-coloured banners, stack size = player count, objective banner gradients, player heads | New `VariableBinding.TargetProperty` values: `Material` (resolves to a `MinecraftMaterialRef` namespace key), `Amount`, `BannerPatterns`, `SkullOwner`, `DisplayMode` |
| E7 | **Inline colour** | Legacy lore mixes grey labels with green values in one line | Translate `&`-codes in resolved `Name`/`Lore` text (today only whole-line `ChatColorName`/`ChatColorDescription`) |
| E8 | **Lore line omission / expansion** | Optional lines ("Voted", "Join the Siege to vote") | A `Lore` binding resolving to `null` is dropped; one resolving to a `List<String>` expands into several lines |
| E9 | **`menu.back` action** + engine roots | Back button, pager labels | `menu.back` pops the `MenuSession` nav stack (`goBack()` exists, no action uses it) and closes when the stack is empty. Two engine-owned E2 roots: `$menu$` (`getBackLabel` → "Back"/"Exit", `getBackHint` → "Click here to go back to <title>"/"Click here to close this menu" — v2's intended `%getBackPhrase%`) and `$section$` (`getPage`, `getPageCount` for the clicked/rendered section) |

Siege itself registers (DESIGN §10.2): variable roots `siege`, `siegeViewer`, `siegeServer`; content
sources `siege.lobbies`, `siege.vote-candidates`, `siege.body` (phase-aware members/objectives),
`siege.spawn-options`; actions `siege.join`, `siege.leave`, `siege.vote`, `siege.vote.random`,
`siege.spawn`, `siege.open-own`; conditions `siege.phase`, `siege.participating`,
`siege.join-eligible`, `siege.vote-open`, `siege.spawn-available`, `siege.lobbies-empty`,
`siege.lobby-open` (added 2026-09-26).

---

## Part C — Proposed v3 templates

Notation: `Name`/`Lore` are `VariableBinding`s (`TargetProperty`, `Expression`, `RefreshPolicy`); lore
lines are listed in `SortOrder`. `S` = `Static`, `D` = `OnDirty`, `T20` = `Ttl` 20 ticks. Every slot
number is an **absolute inventory slot** — that is how the engine interprets `SlotOverride`
(`RuntimeMenuItem`; confirmed by the Phase 9 session 2026-09-25), not section-local. Colours use `&`-codes (E7): `&7` GRAY, `&a` GREEN,
`&c` RED, `&e` YELLOW, `&6` GOLD, `&5` DARK_PURPLE, `&b` AQUA. All view getters named here are
defined in DESIGN §10.3. *(Updated 2026-09-26, as built: lore that depends on the row kind uses one
list getter — `$row.getLines$`, `$row.getStatusLines$` — instead of per-line bindings. Seeds are
create-only: delete the three `siege.*` templates to pick up a changed seed.)*

### C.1 `siege.entry` — main-menu button (an item, placed in whatever root menu template exists)

| Field | Value |
|---|---|
| Material | `WHITE_BANNER` |
| Name | `&aSiege Minigame` (S) |
| Lore | `&7Click here to see` · `&7and join active Siege games` · `` · `&eDescription` · `&7Siege is a minigame where` · `&7teams fight against each other.` · `&7The defending team defends` · `&7a main objective and multiple` · `&7side objectives against the attackers.` · `&6The goal:` · `&6- Attackers: capture the objectives` · `&6- Defenders: defend the objectives` (all S); then `$siegeServer.getEntryHintLine$` (T20 — "&aYou are in Siege N — click to open it" or null, E8) |
| Action | `siege.open-own` (opens the viewer's own siege Information if participating — v1 behaviour — else `menu.open {key: siege.overview}`) |
| Permissions | `VisibilityPermission`/`ActionPermission`: `knk.siege.play` (DESIGN §11) |

*(Updated 2026-09-26, as built:)* `siege.entry` is the hub's existing Siege tile in the content menu seed.
It opens `siege.overview` behind `menu-available` and has **no** `siege.open-own` action, no entry-hint
lore line and no permission binding. `siege.open-own` and `$siegeServer.getEntryHintLine$` exist (the
hint is on the overview header) but aren't on the tile; `/siege` and `/siege menu` open your own
Information instead.

### C.2 `siege.overview` — Dynamic height (max 5, `MinHeight` 2), `AutoRefreshTicks` 20

*(Updated 2026-09-26, smoke test: was a fixed Height 5; the menu now shrinks to the header + the lobby
rows in use.)*

| Section | Kind | DisplaySlot | W×H | Overflow | Content |
|---|---|---|---|---|---|
| `Header` | StaticButtons | 0 | 9×1 | Hide | pinned items |
| `Sieges` | ContentGrid | 9 | 9×4 | Scroll | `ContentSourceId = siege.lobbies`; its last row (slots 36–44) holds pinned pager + filler, slots 9–35 auto content (capacity 27) |

**Header items**

| Slot | Material | Name | Lore | Action | Conditions |
|---|---|---|---|---|---|
| 4 | `WHITE_BANNER` | `&aSiege` | `&7Check the status of` · `&7active sieges or join` · `&7a siege` · `` · `&7Active sieges: &a$siegeServer.getLobbyCount$` (T20) · `&7Players playing Siege: &a$siegeServer.getPlayingCount$` (T20) | — | — |
| 8 | `BARRIER` | `&c$menu.getBackLabel$` | `&7$menu.getBackHint$` | `menu.back` | — |

**`Sieges` row template** (`IsRowTemplate`, root `$row$` = `SiegeLobbyMenuView`)

| Field | Binding |
|---|---|
| Material (E6) | `$row.getBannerMaterial$` — `WHITE_BANNER` cooldown/idle · `GREEN_BANNER` matchmaking · `RED_BANNER` in progress · `ORANGE_BANNER` ending (D) |
| Amount (E6) | `$row.getMemberCountOrOne$` (T20) |
| Name | `&7$row.getName$` (S) — the lobby's configured name replaces "Siege N" (fixes N5 label mismatch) |
| Lore | `&7Scenario: $row.getScenarioLabel$` · `&7Joined players: $row.getMemberCountLabel$` · `&7Current stage: &a$row.getPhaseLabel$` · `$row.getEntryRequirementLine$` (null unless the next scenario has a title gate) · `` · `&7$row.getTimerLabel$` · `&a$row.getTimeRemaining$` · `` · `$row.getJoinHintLines$` (List: `&aClick to view and join!` \| `&cCan't join match!`+`&cWait for matchmaking to start` \| `&cYou don't meet the entry requirement`) — all T20 |
| Action | `menu.open {key: siege.information, ctx.lobbyId: $row.getLobbyId$}` |
| Click condition | `siege.lobby-open {lobbyId: $row.getLobbyId$}` — a lobby in cooldown or disabled is listed but doesn't open *(added 2026-09-26, smoke test)* |
| Sort | content source orders matchmaking → in progress → cooldown (fixes N5) |

**Pinned in `Sieges`** (slots 36–44): `36` Prev (`ARROW`, `&aPrevious page`, lore `&7Page $section.getPage$/$section.getPageCount$`, `menu.page.prev`) · `44` Next (`menu.page.next`). ~~`37–43` `BLACK_STAINED_GLASS_PANE` " "~~ — no filler panes; the engine's default gray background (`GRAY_STAINED_GLASS_PANE`) fills empty slots *(updated 2026-09-26)*. Empty state: when the source returns no rows, a pinned `BARRIER` at slot 22 `&cNo Sieges` / `&7There are currently no active Sieges.` / `&7Sieges start automatically — check back soon.` with render condition `siege.lobbies-empty` (the v2 "ask a Donator" line is obsolete: lobbies self-start).

### C.3 `siege.information` — Dynamic height (max 6, `MinHeight` 3), `AutoRefreshTicks` 20, requires `ctx.lobbyId`

~~Opening in COOLDOWN is allowed in v3 (shows the countdown and the next rotation) instead of v2's
bounce-back.~~ *(Updated 2026-09-26, smoke test: a lobby in cooldown or disabled is **not** opened —
`siege.lobby-open` on the overview row; `/siege` and `/siege menu` refuse too. Height was a fixed 6.)* Every phase-specific item carries a **Render** condition `siege.phase {lobbyId: $ctx.lobbyId$, phases: …}` (E5).

| Section | Kind | DisplaySlot | W×H | Content |
|---|---|---|---|---|
| `Header` | StaticButtons | 0 | 9×1 | pinned |
| `Votes` | ContentGrid | 9 | 4×1 | `siege.vote-candidates {lobbyId: $ctx.lobbyId$}` — up to 3 candidates + Random (`SiegeLobby.VoteCandidateCount` is capped at 3 for this reason) |
| `Actions` | StaticButtons | 13 | 5×1 | pinned join/leave |
| `Divider` | StaticButtons | 18 | 9×1 | pinned filler + players/teams summary |
| `Body` | ContentGrid | 27 | 9×3 | phase-dependent content source (below) |

**Header (row 0)**

| Slot | Material | Name | Lore | Action | Conditions |
|---|---|---|---|---|---|
| 2 | `COMPASS` | `&aChange spawnpoint` | `&7Click to choose where you` · `&7respawn when killed` · `` · `&7Current: &a$siegeViewer.getCurrentSpawnName$` | `menu.open {key: siege.spawnpoint}` | Render: phase `IN_PROGRESS` + `siege.participating` (fixes N14) |
| 4 | `$siege.getBannerMaterial$` (in progress + participating: the viewer's team banner via `BannerPatterns` = `$siegeViewer.getTeamBannerPatterns$`) | `&7$siege.getName$` | as C.2 row lore (T20) + `$siegeViewer.getTeamLine$` (`&7Your team: <colour><name>` or null) | — | — |
| 6 | `COMPASS` | `&7Objective information` | static help text restored from v1 (`&6How to play` · `&7Objectives are marked by a banner.` · `&7Stand inside an objective's circle` · `&7to capture (attackers) or defend it.` · `&7Capturing a "&aWin&7" objective ends the game.` · `&7Held objectives are extra spawnpoints.` · `&7Selected gates can be opened and closed` · `&7by the team that owns them.` · `$siege.getRecaptureLine$` (`&7Captured objectives can be retaken.` or null — DESIGN D5) · `&7Enchantment books appear near objectives;` · `&7click one onto an item to apply it.` · `&8Siege enchantments are removed afterwards.`) + `&7Objectives: &a$siege.getObjectiveCount$` · `&7Objectives with a gate: &a$siege.getGateObjectiveCount$` | — | Render: scenario known (drawn, or phase ≥ HUB) |
| 8 | `BARRIER` | `&c$menu.getBackLabel$` | `&7$menu.getBackHint$` | `menu.back` | — |

**Actions (row 1, slots 13–17)** — pinned at slot 14 (v2's position):

| Material | Name | Lore | Action | Conditions |
|---|---|---|---|---|
| not joined: `GREEN_CONCRETE` / joined: `SPRUCE_DOOR` (E6 `$siegeViewer.getJoinLeaveMaterial$`) | `$siegeViewer.getJoinLeaveName$` (`&aClick to join` \| `&cClick to leave`) | `&7$siegeViewer.getParticipationLine$` · `$siegeViewer.getJoinDenialLine$` (null, or a red reason: full / title gate / already in another siege / not joinable) | not joined: `siege.join {lobbyId: $ctx.lobbyId$}` · joined: `siege.leave {lobbyId}` behind `menu.confirm.doubleclick` | Render: phase `MATCHMAKING`. Click (join): `siege.join-eligible` |

**`Votes` row template** (section rendered only while `siege.vote-open`; E5 applies to the row template) (`$row$` = `SiegeVoteOptionView`; the source yields the N candidates **plus** a
synthetic "Random" row when the lobby allows random votes — fixes N2)

| Field | Binding |
|---|---|
| Material | `$row.getMaterial$` (`MAP` scenario, `MAP` + `DARK_PURPLE` name for Random) |
| Amount | `$row.getVoteCountOrOne$` |
| DisplayMode (E6) | `$row.getDisplayMode$` → `HIGHLIGHT` when the viewer voted for it (replaces v2's commented-out blink) |
| Name | `$row.getTitle$` (`&a<scenario>` \| `&5Random`) |
| Lore | scenario: `&7Town: &a$row.getTownName$` · `&7Districts: &a$row.getDistrictNames$` · `` · `&7Players: &a$row.getPlayersMin$&7–&a$row.getPlayersMax$` · `$row.getEntryRequirementLine$` · `` · `&7Objectives: &a$row.getObjectiveCount$` · `&7Objectives with a gate: &a$row.getGateObjectiveCount$` · `` · `&7Votes: &a$row.getVoteCount$` · `$row.getVoteHintLines$` ("" + `&cVoted — click to remove` \| `&aClick to vote` \| `&cJoin the Siege to vote`). Random: `&7A random scenario will` · `&7be chosen` · `` · `&7Votes: &a$row.getVoteCount$` · `$row.getVoteHintLines$` |
| Action | scenario row: `siege.vote {lobbyId: $ctx.lobbyId$, scenarioId: $row.getScenarioId$}` (clicking your current vote removes it — without v2's NPE, N17) · random row: `siege.vote.random {lobbyId}` |
| Click conditions | `siege.participating {expected: true}` (deny message "You must join the Siege before you can vote."), `siege.vote-open` |

**Divider (row 2)**: slots 18–26 `BLACK_STAINED_GLASS_PANE`; slot 22 `SKELETON_SKULL`, amount
`$siege.getMemberCountOrOne$`, name `&aJoined players`, lore `&7Joined players: $siege.getMemberCountLabel$` ·
`&7Min. players: &a$siege.getPlayersMin$` · `&7Max. players: &a$siege.getPlayersMax$` (null until a
scenario is drawn) · `$siege.getTeamSummaryLines$` (E8 list, after the team split: one line per team,
`<colour><team>&7: &a<n> &7players, &a<m> &7objectives held`) — N-team friendly without indexed getters,
which `$…$` getter chains don't support.

**Body (rows 3–5)** — **one** section fed by a **phase-aware** source. Sections can't carry
conditions, and the layout validator rejects sections that share slots, so the original "one section
per phase" layout isn't buildable (Phase 9 finding). `ContentSourceId = siege.body {lobbyId: $ctx.lobbyId$}`
returns member rows in `MATCHMAKING`/`HUB` and objective rows in `IN_PROGRESS`/`ENDING`, all as
`SiegeBodyRowView`. The single row template binds only to getters that switch on the row kind:

| Field | Member row (matchmaking/hub) | Objective row (in progress/ending) |
|---|---|---|
| Material `$row.getMaterial$` | `PLAYER_HEAD` | `WHITE_BANNER` |
| `SkullOwner` `$row.getSkullOwner$` | member UUID | null |
| `BannerPatterns` `$row.getBannerPatterns$` | null | live capture gradient |
| `DisplayMode` `$row.getDisplayMode$` | `HIGHLIGHT` for the viewer (v1 glow) | `HIGHLIGHT` while contested |
| Name `$row.getTitle$` | `&a<name>` | `&7<objective>` + `&7(&aWin&7)` for instant-victory |
| Lore `$row.getLines$` (E8 list) | `&bTitle: &a<title>` · `&bRank: &a<rank>` (premium tier name, "-" when none; replaces hardcoded "Donator") · team line after the split | `&7Held by: <holder>` · `` · `&7Captured: <n>%` · captured-by line (last capturer; with recapture enabled also `&7Captures: &a<n>`) · contested line. *(As built: no gate Open/Closed/Destroyed line — the menu snapshot has no gate state; the objective banner is the holder team's banner, not the live gradient.)* |
| Click | — | — (spawning only via the spawn picker) |

In `COOLDOWN` the source returns an empty page.

Pinned pager in Body: none by default (27 capacity); if the member list exceeds it, the Body's last row
(slots 45–53) holds a pinned Prev (45) / Next (53) + filler, as in C.2 (capacity 18).

### C.4 `siege.spawnpoint` — respawn picker, Height 3, `AutoRefreshTicks` 20

Opened by the runtime at match start and by C.3's "Change spawnpoint", only if the team has ≥ 2 options
(v1 rule). After a respawn it opens only while the member has no stored choice. *(Updated 2026-09-26,
smoke test: the choice is remembered — ignoring the picker at match start stores the team default, so it
doesn't reopen on every death; a captured objective resets its choosers to the team default with a chat
hint to `/siege menu`.)* No `ctx` needed — resolves the viewer's own match.

| Section | Kind | DisplaySlot | W×H | Content |
|---|---|---|---|---|
| `Header` | StaticButtons | 0 | 9×1 | slot 4: `COMPASS` `&aChoose a place to spawn`, lore `&7Current: &a$siegeViewer.getCurrentSpawnName$` · `&7Close this menu to keep it.`; slot 8: `BARRIER` `&cClose` → `menu.close` |
| `Options` | ContentGrid | 9 | 9×2 | `siege.spawn-options` (held objectives first, then team spawnpoints — v2 order); pinned pager at slots 18/26 only if > 16 options |

**`Options` row template** (`$row$` = `SpawnOptionView`)

| Field | Binding |
|---|---|
| Material | `$row.getMaterial$` — objective: `WHITE_BANNER` + `BannerPatterns` `$row.getBannerPatterns$` (fixes `LEGACY_BANNER`); spawnpoint: `GREEN_CONCRETE` |
| DisplayMode | `$row.getDisplayMode$` — `DISABLED` while contested, `HIGHLIGHT` if it is the current choice |
| Name | objective: `&7$row.getName$` · spawnpoint: `&7Spawnpoint $row.getName$` |
| Lore | `$row.getStatusLines$` — `&aClick to spawn here` \| `&cCan't spawn here` + `&cObjective is being captured!` \| `&aCurrent spawnpoint` |
| Action | `siege.spawn {kind: $row.getKind$, id: $row.getId$}` then `menu.close` |
| Click conditions | `siege.spawn-available {kind, id}` — re-checks at click time: still in progress, still your team's, objective still held and not contested (deny: "This objective is being captured!" / "Your team no longer holds this objective.") |

Behaviour change vs v2 (DESIGN §6.6): choosing an option sets the member's **current spawnpoint**; the
teleport happens immediately only when the picker was opened by a respawn or match start — from C.3
("Change spawnpoint") it just updates where you respawn next time. Objective spawns restore health/food
like spawnpoint spawns (v2 inconsistency).

### C.5 Parity & fixes summary

| Legacy item | v3 location | Fixed legacy defects |
|---|---|---|
| A.2 entry | C.1 | adds "jump to own siege" (v1) |
| A.3 overview + A.4 rows | C.2 | N5 ordering/labels, N11 raw placeholders, N16 dead paging |
| A.5 join/leave | C.3 `Actions` (slot 14) | explicit eligibility + denial reason; title gate |
| A.5 vote items + Random | C.3 `Votes` | N1 (draw logic), N2 random vote, N17 un-vote NPE |
| A.5 joined players | C.3 Body (matchmaking) | hardcoded "Donator", N16 |
| (missing in v2) in-progress info | C.3 slot 2/6 + Body (in progress) | N6, N14 |
| A.6 spawn picker | C.4 | `LEGACY_BANNER`, contested check at click time, N16 |
| A.7 orphaned rewrite | superseded by C.2 | — |
