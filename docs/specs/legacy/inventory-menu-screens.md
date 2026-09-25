# Legacy inventory menus — screen & item catalogue (v1/v2), allocated to v3 features

**Status:** Complete source-mining pass (v1 all 27 `src/Menu/*` files + menu code outside it; v2 every
non-engine `model/menu/**` and `menu/preset/**` screen). Siege player screens are referenced, not
repeated (already in `docs/specs/siege-minigame/MENU_TEMPLATES.md` Part A).
**Last updated:** 2026-09-25 (ports #1, #3–#7 and engine gap G1 implemented on `claude/menu-content`, not
merged/live-verified — see [../inventory-menu/CONTENT_PORT_PLAN.md](../inventory-menu/CONTENT_PORT_PLAN.md))

Ref: [inventory-menus.md](inventory-menus.md) (the legacy menu *framework*, its 11 engine bugs),
[../inventory-menu/IMPLEMENTATION_PLAN.md](../inventory-menu/IMPLEMENTATION_PLAN.md) (the v3 engine,
Phases 1–9 implemented), [../siege-minigame/MENU_TEMPLATES.md](../siege-minigame/MENU_TEMPLATES.md)
(the one feature already ported: legacy Part A → v3 templates Part C),
[commands-v1.md](commands-v1.md) / [events-v1.md](events-v1.md) (the command and listener side of the
same features).

## Why this doc exists

`inventory-menus.md` documents how the legacy menu *engine* worked and failed, and says outright
(its open question 4) that the ~60 v1 screens were never catalogued. The v3 engine is now built
(`claude/inventorymenus`, merged into `claude/siege-minigame`; see the plan's Phase 9 status), so the
remaining work is **content**: rebuilding legacy screens as `MenuTemplate` seed data plus
feature-registered actions/conditions/variable roots/content sources, one feature at a time — the way
Siege did it. This doc is the input for that: every legacy screen, what each item showed and did, which
v3 feature it belongs to, and whether today's engine can express it.

## How to read this doc

- **Citations** follow the rest of `docs/specs/legacy/`: `v1:src/Path/File.java:line` and
  `v2:<path under src/main/java/net/knightsandkings/>:line`. v1 `Menu.java` = `v1:src/Menu/Menu.java`.
- **Slots** are absolute inventory slots (0 = top-left, 9 per row) — the same convention as the v3
  `SlotOverride` (Phase 9 J16).
- **Colours** are omitted unless they carry meaning. Legacy lore coloured values by role
  (`ColorOptions.stats` label / `statsresults` value / `error` red / `messageachievement` green); the v3
  equivalent is E7 inline `&`-codes, so a port only needs to know which lines were "good", "bad" or
  "neutral".
- **Filler:** almost every v1 screen ends with `fillEmptyMenu` (`Menu.java:1991-2008`): every empty
  slot becomes a named `" "` white glass pane; on the owner-mode Personal Menu, row 3 (slots 27–35) is
  blue instead, visually separating the admin row. Not repeated per screen below.
- **Engine fit** (per screen, and summarised in §1):
  - **Engine** — expressible with the implemented engine alone plus the feature's own variable root /
    row source: `menu.open` (+ `ctx.*`), `menu.back`, `menu.close`, `menu.page.*`, `menu.search.*`,
    `menu.filter.*`, `menu.confirm.*`, conditions `permission-node` / `value-equals` /
    `has-pending-confirmation`, bindings `Material` / `Amount` / `SkullOwner` / `BannerPatterns` /
    `DisplayMode`, `AutoRefreshTicks`.
  - **Feature action** — additionally needs a feature-registered action or condition (e.g.
    `kits.claim`, an affordability condition). This is the normal, intended pattern (Phase 9 E2/J11),
    not a gap.
  - **Engine gap** — needs a capability the engine does not have. The recurring ones are listed in
    §2.2 (G1–G7) and referenced by number.

---

## 1. Feature allocation (summary)

Every legacy screen, grouped by the v3 feature it belongs to. "No v3 spec yet" means the feature
exists in `docs/vision/vision.md` (section given) but has no `docs/specs/` folder; those screens have
nowhere to land until that feature is designed.

| v3 feature (spec folder) | Legacy screens allocated (§ in this doc) | Engine fit | Notes |
|---|---|---|---|
| **Kits** (`specs/kits`) | v2 Main-menu "Kits" tile, `KitOverview`, `KitSelectItem` (§4.1) | Feature action (`kits.claim` → `KitService.ClaimKitAsync`) | v1 had no kit menu. Kits `DESIGN.md` §7 already mandates the menu use the same service as `/kit get`. Template key `kits.overview` is already named in `MenuTemplatesDataAccess`'s javadoc. **Ported 2026-09-25 (port #3):** `kits.overview` — CONTENT_PORT_PLAN.md CP2. |
| **Siege minigame** (`specs/siege-minigame`) | Player: v1 Events → Siege overview/information/spawnpoint, v2 siege menus → **done** in `MENU_TEMPLATES.md`. Admin: v1 Siege manager, Scenario manager, Side-objective manager, SO gate picker, Siege spawnpoints manager (§3.10) | Player: see MENU_TEMPLATES. Admin: G1 (steppers), G5 (location edit mode) | Admin screens are **not** in MENU_TEMPLATES. Scenario/objective authoring is a better fit for the web-app FormConfig path; only the in-world tools (teleport to objective, test objective, set location) need an in-game menu. |
| **User features** (`specs/user-features`: titles/XP, premium tiers, owner-mode, salary) | Personal Menu tiles: Titles, Donator ("Current rank"), Financial, profile skull (§3.1); Title information (§3.3); Donator-ranks information → premium tiers (§3.4) | Engine (display) | Title/premium data now lives in v3 services; these are read-only screens. Donator info is 2017-era "find the armour set" content — premium tier perks need re-deciding (vision §5.3) before porting. **Ported 2026-09-25:** Profile & titles (`profile.main`, port #4, CP3) and Premium tiers (`premium.tiers`, port #6, CP5, from v3 data). |
| **User management** (`specs/user-management`) | Player Manager (online list), Edit-statistics editor (§3.14) | G1 (steppers, kept), feature actions | Port order #7 (§7): an in-game front end over the web-app module's existing services (shipped 2026-09-24); kick/ban via Paper's built-in commands. **Ported 2026-09-25 (port #7):** `users.manager*` — CP8; G1 built (CP6); audit actor pending CP7 server half. |
| **Items** (`specs/items`) | Support → List of items (§3.11); Gem-shop (§3.8); product item-info/purchase menu and coupon menu (§3.7); ShopItems manager, category overview, "Add a product" (§3.13); v2 `ItemOverview` (§4.4) | Engine for the catalogue (`catalog.itemblueprints` already exists); feature action for purchase | Gem-shop maps onto `ItemTemplate` purchase-currency (vision §9.1). Item purchase from a shop is coupled to the Structures/Economy question below. **Item catalogue ported 2026-09-25 (port #5):** `items.catalog` — CP4 (search only; the source has no filter facets). |
| **Custom enchantments** (`specs/custom-enchantments`) | v1 property "Enchant item with X" menu (§3.7.4); v2 `PlayerEnchantMenu` (§4.5) | G4 (menu shows the player's own inventory) | `SPEC_CUSTOM_ENCHANTMENTS.md:758` already lists an open task "Design Enchantment UI/inventory menu for easier selection". |
| **Gates** (`specs/gate-structure-animation`) | Gate Manager, Gate information editor, Gate material picker (§3.9) | G1 (health steppers), G6 (staged edits + save) | v3 gates are authored in the web-app (GateStructure FormConfig). The in-game editor only matters for in-world toggles (open/close, destroyed/intact, heal). |
| **Towns** (`specs/towns`) | Teleport-to-spawnpoints menu (§3.6); town filter on the structure lists (§3.2) | Feature action (teleport, gem charge) | v1 spawnpoints are gated by title and donator tier — maps onto vision §2.2 access-gating. v2 `TownOverview` exists but its only caller is commented out (§4.6). |
| **Structures** — houses, rooms, properties/shops, warehouses (**no v3 spec yet**; vision §2.5, §4.5) — **shelved 2026-09-25** | Owned houses, Owned properties, House/Property info, sale confirms, forced-sell menus, House/Property/Room lists (§3.2); Shopkeeper "Products of X", Sell menu (§3.7); v2 Storage/Chest/StorageAdd/ProductionStructure menus (§4.3) | G2 (deposit slots), G3 (click-type actions), feature actions | Largest block of v1 content (roughly a quarter of `Menu.java`). Blocked on the open structure-ownership design (vision §4.5 [OPEN]). |
| **Economy** (**no v3 spec yet**; vision §4) | Personal Menu owner-mode "Refresh item-amount / item-price" (§3.1); sell-to-shop pricing (§3.7.2) | Feature action | Bulk admin actions with no confirmation in v1. |
| **Social / friends** (**no v3 spec yet**) | Manage friends, Add friends, Friend requests, Friend-request option (§3.5) | Engine + feature actions | All v1 mutations were delegated to `/friends` and `/request` chat commands. |
| **Quests & assignments** (**no v3 spec yet**; vision §8, deprioritised) | Assignments sub-menu, Daily assignments, Quests, Achievements (stub), Quest deliver; shopkeeper quest item (§3.12) | G2 (quest deliver), feature actions | Achievements screen has no content at all (§3.12.4). |
| **Skills** (**no v3 spec yet**; user-features only ports the title→skill-point *grant*) | Personal skills menu (§3.1.2) | Feature actions | Strength/Speed/Health/AttackSpeed/Defense upgrades + random "special skill" roll. |
| **Onboarding & support** (**no v3 spec yet**) | Support, List of tutorials, Tutorial start prompt; FAQ ("Coming soon!"), Website link (§3.11) | Engine; tutorials need G7 | v1 tutorials were driven *by* menu clicks (§2.1 P10). |
| **Other minigames** — Hide and Seek, duels/arena (**no v3 spec yet**; vision §7.5, long-term) | Events list, Hide and Seek overview/information, HS admin screens, Arena, Duel invite, Duel setup (§3.10, §3.15) | Duel setup needs G2 + a shared inventory (G4) | HS player screens are structurally identical to Siege's and can reuse the Siege templates' approach. |
| **Form configurations / creation wizard** (`specs/form-configurations`) | v2 `CreationStageSelectMenu` (live, §4.2), `SelectMenu`, `CreationOverview` (stub), `PlayerInventoryOverview` ("Test inv") | Do not port | v3 authors entities in the web-app FormWizard; the in-game wizard is gone. |
| **Debug / developer tools** | v2 Main-menu "Overview of Caches" → Factories → Cache overview/detail; v2 preset Repository overview/details, DropdownTest, LoadingMenu (§4.7) | Do not port | Diagnostic browsers over the v2 ORM cache. |
| **InventoryMenu content (hub)** | v2 `MainMenu` (§4.1) as the starting point; v1 Personal Menu (§3.1) as a source of tile ideas | Engine | Decided 2026-09-25: grow from v2's sparse main menu, one tile per feature as it is ported. Each tile is allocated to its own feature above. **Ported 2026-09-25 (port #1):** `main` + `/menu` — CP1; tiles shown via `menu-available`. |
| **Dead / never implemented** | Personal Menu tiles Pets/Servants, Knowledge, Settings, Theft report (display-only); Owned-houses "Settings"; Player-editor "Next page"; `openQuestRequest` (no callers); v2 `ChestOverview` (fully commented out) | — | Decide keep/drop per feature; §6 lists them. |

---

## 2. Cross-cutting findings

### 2.1 Legacy patterns and their v3 equivalent

| # | Legacy pattern | Where | v3 equivalent |
|---|---|---|---|
| P1 | **Routing by display-name substring.** One global listener string-matches the inventory title, then the clicked item's stripped, lower-cased display name (`contains("social")`, `contains("houses")`). | `v1:src/Menu/MenuClick.java:88-296` and every `*Click` class | One `ActionBinding` per item. Removes a whole bug class: e.g. the profile skull's name "Social profile" also matches `contains("social")`, so clicking your own profile opened the friends manager (§6 B3). |
| P2 | **Identity round-tripped through text.** The id of the clicked house/property/room/gate/scenario is re-parsed from lore lines (`getMenuStructureID`, `Menu.java:1949-1989`; `Menus.getPropertyIDByInfoItem`, `v1:src/Handlers/Menus.java:163-190`), from a hidden `ChatColor.BLACK + id` suffix on a display name (`Menu.java:1895-1896`, `OwnedhousesClick.java:431`), or from the **inventory title** (item-info menu = product display name, `v1:src/Properties/ItemFrameAdd.java:296-300`). | everywhere | Row templates bind `$row$` per slot (E3) and navigation carries `ctx.*` params (E1). No text parsing. Every legacy "can't find the id" bug disappears (§6 B6, B8, B13, B14). |
| P3 | **Page state in lore.** The current page is read back from the Next/Previous button's lore (`HouselistClick.java:54`), page start indices are hardcoded 46/91/… (item 45 skipped), and v1 HS/Siege pass `page++` (post-increment) so paging never advances. | §3.2, §3.10 | Section paging on the base class (Phase 2) + `$section.getPage$` (E9). |
| P4 | **Filter by click-cycling.** Town filter (BUCKET → WATER_BUCKET + glow when active): click = next town in the town list, "All" → first town, last town → "All"; **Shift-left = reset**. Same for item categories in the item list. | `HouselistClick.java:62-104`, `SupportMenuClick` item list | `menu.filter.cycle` cycles an **author-supplied static list** of values — fine for categories, not for a dynamic town list (a town added later needs a template edit). Use `menu.filter.prompt` instead, or add a feature-side row source for filter values. The shift-left reset maps onto G3. |
| P5 | **Locked tiles that deep-link and highlight.** A BARRIER "Locked!" tile ("Reach the title X to unlock this slot! Click here for more information") opens Title information and *blinks* the relevant title (`OwnedhousesClick.java:171-219`); donator locks open Donator information. | owned houses/properties, assignments, quests | Render conditions (E5) choose Locked vs Empty; the deep link is `menu.open` with `ctx.highlight=<id>`, rendered as `DisplayMode` `HIGHLIGHT` on the matching row. There is no timed blink in v3; HIGHLIGHT is the stand-in. |
| P6 | **Affordability baked into lore.** "Available! Click here to buy!" / "Unavailable! You need N more coins" / "Current owner: X", checked only at render time. | house/property/room lists, gem-shop, item info, spawnpoints | Render condition for the lore variant + **Click-phase** condition for the purchase (Phase 6 closes the render→click staleness window). The engine has **no** affordability/ownership condition yet (`MenuConditionHandlers` javadoc: deliberately not built without an economy context), so each feature registers its own. |
| P7 | **Confirm dialogs.** Green clay Confirm / red clay Cancel (sale confirms, stop renting, friend-request accept/deny, coupon). | §3.2, §3.5, §3.7.3 | `menu.confirm.request/accept/cancel` or `menu.confirm.doubleclick` (engine). |
| P8 | **Menu actions delegate to chat commands.** Buying calls `Bukkit.dispatchCommand(p, "house buy <id>")`; friends use `/friends add`, `/request accept`; the player editor runs `/experience set`, `/coins add`, `/donator set`, `/kick`, `/ban`. | `HouselistClick.java:113`, `FriendManagerClick`, `PlayerManagerClick` | The v3 rule (Kits `DESIGN.md` §7, vision §9.2): the menu action and the command call the **same service method**; neither calls the other. |
| P9 | **Live countdowns.** HS/Siege stage countdowns re-rendered on a timer. | §3.10 | `AutoRefreshTicks` (E4) + `refreshOpenMenus` (engine). |
| P10 | **Menus drive tutorials.** When a `Tutorial` targets the player, specific clicks advance it (`"room tutorial"` stage 4 = click Houses, stage 5 = Rent a room, stage 6 = rent a room from the list; `"skills tutorial"` stage 4/5), and Back/Exit call `tutorial.previousStage()`. | `MenuClick.java:90-139`, `OwnedhousesClick.java:77-110`, `RoomlistClick.java:42-93`, `SkillMenuClick.java:56-86` | G7 — the engine publishes no "menu opened / item clicked" event a tutorial system could observe. |
| P11 | **Minigame guard.** Houses, properties, the structure lists and teleport are refused while `user.inMiniGame()`; `/menu` is refused while duelling. | `MenuClick.java:151-205`, `v1:src/Menu/MenuCommand.java` | A shared condition (e.g. `player.not-in-minigame`) on those tiles, Click phase. |
| P12 | **Punitive close handler.** Closing the forced "Choose a house/property to remove" menu *automatically strips ownership* of houses/properties until the player is back under their cap. | `OwnedhousesClick.java:297-348`, `OwnedpropertiesClick.java:205-256` | Do not port as a close side effect. A v3 design for "over the slot cap after demotion" belongs in the Structures feature, not in a menu's close event. |

### 2.2 Engine gaps found (content that the implemented engine cannot express)

These came out of the mining pass; none are needed by Kits or Siege, which is why the engine plan
didn't build them.

| # | Gap | Legacy screens that need it | Evidence in the v3 engine |
|---|---|---|---|
| G1 | **Numeric steppers with a per-session step size.** `+` / value / `−` columns, where clicking the value cycles the step (10→20→50→100 for gate health, `nextStep`, `v1:src/Menu/GateManagerClick.java` end of file; 250 for HS reward; per-field steps in the player editor). v1 stored the step *in the value item's lore*. | Gate editor, Scenario manager (min/max players), HS manager (reward), Player editor, v2 `StorageAddItem` (left/right = ±step, shift = change step) | No session-scoped scratch state an action can write and a binding can read. Workable today only as a feature-side per-player map exposed through a variable root. **Built 2026-09-25** (CONTENT_PORT_PLAN.md CP6): session state + `$state.<key>$` root + `menu.state.set`/`menu.state.cycle` + `menu.open state.*` defaults. |
| G2 | **Deposit slots** — slots the player may drop their own items into. | Sell menu (19–25), Quest deliver (19–25), Duel setup stake area, Coupon escrow (§3.7) | `MenuClickListener` cancels every click in a KnK menu ("Never allow taking, rearranging, or shift-clicking items into a KnK menu", `knk-paper/.../menu/MenuClickListener.java:99-100`), and there is no drag handling. |
| G3 | **Actions keyed by click type.** Right-click Back = leave the game; Shift-left = reset filter / full heal; left/right = +/−. v2 had this (`MenuItemAction` triggers by `ClickType`). | HS information (right-click leave), all filters, gate heal, v2 storage steppers, duel "Items" stake type | `ActionBinding` has no click-type field; only the built-in shift shortcuts for search and paging exist (`MenuClickListener.java:150-170`). |
| G4 | **Menus that show live, non-template items**: the player's own inventory, or one inventory shared by two players. | v2 `PlayerEnchantMenu` / `PlayerInventoryOverview`, v1 Duel setup (one `Inventory` object shown to both duellists) | Every rendered slot comes from a template item or a row source; sessions are per player. A row source over the player's inventory would cover the first case; the shared duel window is out of reach. |
| G5 | **Free-text / in-world input for arbitrary params.** v1 used chat capture ("Stand on the new location and type 'save'", duel coin bet typed in chat). | Scenario/side-objective/spawnpoint "Change location", gate rename (was "This function does not work yet"), duel coin bet | The anvil prompt exists only for search/filter (`menu.search.prompt`, `menu.filter.prompt`). |
| G6 | **Staged edits with an explicit Save.** v1 gate and scenario editors mutated the live object and only persisted on "Save changes"; unsaved edits silently stayed in memory. | Gate editor, Scenario manager | A feature concern, not strictly an engine gap — but the port needs an explicit decision (save-per-click vs draft + save). |
| G7 | **Menu lifecycle hooks** (opened, item clicked) for other systems to observe. | Tutorials (P10) | None published. |

### 2.3 Entry points (how each screen was reached, outside other menus)

| Entry | Opens | Source |
|---|---|---|
| `/menu` (perm `k&k.menu`; refused while duelling) | v1 Personal Menu | `v1:src/Menu/MenuCommand.java:40-75` |
| Right-click an item named gold "personal menu" | v1 Personal Menu | `MenuClick.java:445-478` |
| Right-click a Citizens **Shopkeeper** NPC | v1 "Products of <property>" | `v1:src/Traits/Shopkeeper.java:619`, `Shopkeeper_v2.java:370` |
| Right-click an **ArenaMaster** NPC | v1 Arena menu | `v1:src/Traits/ArenaMaster.java:140` |
| Right-click an item frame in an enchanter property | v1 "Enchant item with X" | `v1:src/Properties/ItemFrameAdd.java:140` |
| Opening a treasure chest | v1 random-loot container (not a button menu) | `v1:src/Treasure/TreasureEvents.java:84`, `Treasure.java:267-297` |
| First join / tutorial flow | v1 Tutorial start prompt | `v1:src/Tutorial/Tutorial.java:229,423,508` |
| Owning more houses/properties than the cap allows | v1 forced-sell menus | `v1:src/Users/User.java:2805,2850`, `offlineUser.java:3580,3640` |
| `/menu` (perm `k&k.menu.menu`) | v2 `MainMenu` | `v2:spigot/command/menu/MenuCommand.java` |
| `/item list` | v2 `ItemOverview` (after a chat list) | `v2:spigot/command/item/ItemCommand.java:71-74` |
| Right-click an enchanted book named after a vanilla enchantment key | v2 `PlayerEnchantMenu` | `v2:listeners/PlayerListener.java:245-252` |
| Creation wizard reaching a multi-select stage (auto after 15 ticks, or typing `open`) | v2 `CreationStageSelectMenu` | `v2:creation/CreationStageSelect.java:254-287` |
| `/menu test` | v2 preset `MainMenu` | see `inventory-menus.md` |

---

## 3. v1 screen catalogue

Grouped by allocated feature. Each screen: title, size, how it's reached, then its items.

### 3.1 Hub — Personal Menu (InventoryMenu content) — `Menu.java:151-254`, clicks `MenuClick.java:88-296`

Title "Personal menu"; 27 slots, 45 when the player's `ownermodus` flag is on. Slot constants at
`Menu.java:88-114`.

| Slot | Item | Shows | Click → | v3 feature |
|---|---|---|---|---|
| 0 | BED "Houses" | "Click here to see all owned houses" | Owned houses (§3.2) | Structures |
| 1 | COMPASS "Teleport to points on the map" | "Price will be paid in gems!" | Teleport menu (§3.6) | Towns |
| 2 | IRON_HELMET "Titles" | current title + salary; next title, next salary, XP needed; "You have the highest title available" at title ≥ 18 | Title information (§3.3) | User features |
| 3 | BANNER "Social" | "Add/remove/manage friends" | Manage friends (§3.5) | Social |
| 4 | player head "Social profile" (`Menus.getSocialProfile`) | username (+donator tag), title, gender, XP, coins, gems, houses, properties, kills, deaths | **also** Manage friends (B3) | User features |
| 5 | EMPTY_MAP "Assignments" | "See all your completed and current assignments" | Assignments sub-menu (§3.12) | Quests |
| 6 | EGG "Pets/Servants" | "List of all owned pets and/or servants" | **no handler** | Dead (vision §9.3 pets) |
| 7 | SIGN "Website" | — | close + chat link to the planetminecraft page | Onboarding |
| 8 | BARRIER "Exit" | — | close | Hub |
| 9 | ANVIL "Properties" | — | Owned properties (§3.2) | Structures |
| 10 | BOOK "Skills" | Strength/Speed/Health/Attack speed/Defense levels | Personal skills (§3.1.2) | Skills |
| 11 | chestplate by donator tier (leather/gold/diamond/chainmail) "Current rank: X" (`getDonatorItem`, `Menu.java:1918-1947`) | coin/XP/gem multiplier | Donator information (§3.4) | User features (premium) |
| 12 | DIAMOND "Gem-shop" | "Buy items with gems" | Gem-shop (§3.8) — silently does nothing when no gem products exist | Items |
| 13 | GOLD_INGOT "Financial" | coins, gems, salary, income | **no handler** (display only) | User features |
| 14 | BOOK "Knowledge" | "Latest discovered Knowledge:" followed by an always-empty line | **no handler** | Dead |
| 15 | CAKE "Events" | "Click here to view all active events!" | Events list (§3.10) | Other minigames / Siege |
| 16 | LEVER "Settings" | "Modify settings in the game" | **no handler** | Dead |
| 17 | REDSTONE_TORCH "Support" | tutorials, FAQ | Support (§3.11) | Onboarding |
| 22 | PAPER "Theft report" (only if the player was pick-pocketed since last open) | gendered "Mylord!/Mylady! we received a report that money has been stolen from you!" — shown **once** (removed from the map on render) | **no handler** | Skills (pickpocket) / notifications |
| 36 | player head "Player Manager" *(owner mode)* | — | Player Manager (§3.14) | User management |
| 37 | NAME_TAG "ShopItems Manager" *(owner mode)* | — | ShopItems manager (§3.13) | Items / Structures |
| 38 | IRON_SWORD "Refresh item-amount" *(owner mode)* | — | **immediately** re-rolls the daily stock of every property product, no confirmation (`MenuClick.java:236-246`) | Economy |
| 39 | GOLD_INGOT "Refresh item-price" *(owner mode)* | — | **immediately** re-rolls the weekly price of every property product (`MenuClick.java:247-257`) | Economy |
| 40 | FENCE "Gate Manager" *(owner mode)* | — | Gate Manager (§3.9) | Gates |
| 41 | CAKE "Event Manager" *(owner mode)* | — | Event Manager (§3.10) | Siege / other minigames |

Port notes: owner-mode tiles → `visibilityPermission` + `actionPermission` (Phase 4) rather than a
second menu size. Houses/Properties/Teleport tiles need the P11 minigame guard.

#### 3.1.2 Personal skills — `Menu.java:336-583`, clicks `SkillMenuClick.java:41-148` → **Skills**

Title "Personal skills", 45 slots. One row per skill: header in column 0 (0 Strength, 9 Speed,
18 Health, 27 AttackSpeed, 36 Defense, icons from `SkillMenuItems`), levels 1–7 in columns 1–7
(green clay = achieved, red clay = not; level 7 = glowing BOOK). 8 Back; 17 EMERALD "Your skillpoints: N";
26 NETHER_STAR "Your special skillpoints: N"; 35 "Purchase a second special skill with /buy" (only if a
special skill is owned); 44 glowing ENCHANTED_BOOK "Special Skill" describing the owned special skill
(ninja, assassin, pickpocket, juggernaut, forger, shotbow, avenger — texts at `Menu.java:256-334`).

Clicks: "<Skill> upgrade <n>" upgrades only if *n = current level + 1* and a skill point is available,
otherwise silently ignored. Clicking the "Special Skill" book **with no lore** (the "none" state) spends
a special point on a **random** special skill 1–7 (`SkillMenuClick.java:103-116`). Engine fit: feature
actions (`skills.upgrade`, `skills.roll-special`) + value-equals render conditions for achieved levels.

### 3.2 Structures — houses, rooms, properties

#### 3.2.1 Owned houses/rooms — `Menu.java:1203-1334`, clicks `OwnedhousesClick.java:59-222`

Title "Owned houses/rooms", 18 slots.

| Slot | Item | Shows | Click → |
|---|---|---|---|
| 0 | GOLD_INGOT Financial | coins, gems, salary, income | — |
| 1 | BED "Buy a new house" | + "All your house-slots are full! Promote to a higher title or buy a slot from the gem-shop" when owned ≥ max | House list (§3.2.4), or a chat refusal when full |
| 2 | BED "Rent a room" | + "You can't buy more rooms!" when renting one | Room list, or refusal |
| 4 | WORKBENCH "Houselist" | owned houses, max houses, max rooms 1 | — |
| 7 | LEVER "Settings" | "Modify settings of houses" | **no handler** |
| 8 | BARRIER Back | "Click here to go back to Personal menu" | Personal Menu |
| 10 | room: BONE "Empty (Room)!" or glowing BED "Roomnumber: N" (street, number, town, tavern, renting price, red "Inactivity longer than 7 days will remove you as owner", "Current spawnpoint!", "Click here to stop renting") | | Empty → Room list; room → Stop-renting confirm |
| 11–15 | slot caps: BARRIER "Locked!" (title 5, 10, 15, Royal, Dragon Blood; "Click here for more information") or BONE "Empty!" ("Click here to buy a house") | | Locked → Title/Donator info with highlight (P5); Empty → House list |
| 11+ | owned houses: BED "Housename: X" (street, number, town, price, "Current spawnpoint!", "Click to sell!") — written over the cap tiles | | House info (§3.2.2) |

Bugs: B4 (only one title slot ever unlocks), B5 (highlight hits the wrong title), B6.

#### 3.2.2 House info / Property info and their confirms — `OwnedhousesClick.java:382-442`, `OwnedpropertiesClick.java:289-326`

- **House info: X** (18): 0 Financial ("Finacial" typo), 8 Back ("your house list"), 9 player-head
  "Sell" ("You will receive <price/2> coins", "Tip: Remove all decorations before selling the house"),
  13 BED house card (price, "Level: X", "City: X" — literal X placeholders, never filled).
- **Property info: X** (18): same, plus 9 "Sell" warns "Your income will decrease with N", 12 PAPER
  "Income per 12 hours: N coins", 13 ANVIL card.
- **House sale / Property sale** (18): 4 BOOK "Confirmation" ("Are you sure you want to sell X? You will
  receive N coins"), 8 Back, 12 green clay Confirm, 14 red clay Cancel. Confirm → `sellHouse` /
  `sellProperty` (and clears the player's spawnpoint if it was that house). → engine confirm (P7).
- **Stop renting a room** (18): same shape; the room id rides in the display name
  ("Confirmation" + hidden black id, P2).
- These three were opened with `player.openInventory` instead of `user.openMenu`, so admin
  "spectate a player's menu" (see `inventory-menus.md`) never mirrored them.

#### 3.2.3 Owned properties — `Menu.java:1420-1496`, clicks `OwnedpropertiesClick.java:57-203`

Same layout as Owned houses without the room slot: 1 ANVIL "Buy a new property" (+ "slots full"),
4 WORKBENCH summary, 7 Settings (no handler), 8 Back, 11–15 cap tiles, owned properties from slot **10**
(ANVIL "Propertyname: X" — street, number, town, category, price, income, "Click to view") → Property info.

#### 3.2.4 House list / Property list / Room list — `Menu.java:587-1046`, clicks `HouselistClick`, `PropertylistClick`, `RoomlistClick`

Titles "House list", "Property list", "Room list"; size grows with the list (max 54).

| Slot | Item | Click → |
|---|---|---|
| 0 | Financial | — |
| 1 / 7 | ARROW Previous / Next page ("Current page: n" in lore) | page −1 / +1 (loses the town filter, B7) |
| 2 | Town filter: BUCKET "Town: All" or glowing WATER_BUCKET "Town: X" ("Click to change the active town", "Shift-Click to reset") | cycle towns / Shift-left reset (P4). Room list: never works (B9) |
| 4 | WORKBENCH header: houses — owned count; properties — total in town + owned; rooms — "The renting price will be paid per hour that you are online", "You can only rent 1 room!", current renting status | — |
| 8 | BARRIER Back — house/property lists say "personal menu" but go to Owned houses/properties; room list goes to Owned houses | as noted |
| 9+ | Row: house BED "House: X" / property ANVIL "Property: X" / room BED "Roomnumber: N" — street, number, town (+ category & income for properties, tavern for rooms), price, then "Available! Click here to buy!" / "Unavailable! You need N more coins" / "Unavailable! Current owner: X" | buy/rent via `dispatchCommand("house buy <id>" / "property buy <id>" / "room rent <id>")` (P8). House rows never react (B8). |

Property list only: a `blinkPropertyID` argument blinks one row — used when the shopkeeper's
"Information about X" opens the list to *show where that property is* (§3.7.1). v3: `ctx.highlight` +
HIGHLIGHT.

#### 3.2.5 Forced sell — `Menu.java:2879-2933`, clicks `OwnedhousesClick.java:350-379`, `OwnedpropertiesClick.java:258-287`

"Choose a house/property to remove" (9 slots), opened when the player owns more than their cap. Rows
from slot 3 ("Click to remove!"); click removes ownership with **no refund** and re-opens while still
over the cap. Filler reads "Select a house to remove". Bugs: B10 (every row lands on slot 3), P12
(closing the menu strips ownership automatically).

### 3.3 User features — Title information — `Menu.java:2229-2357`, clicks `TitleInfoClick.java` (Back only)

"Title-information", 36 slots. 0 own head (title, gender, XP, coins, gems, salary, income); 4
IRON_HELMET "Information about all titles" ("There are currently 18 titles"; XP sources: killing
bandits or players, selling items, assignments, arena, voting); 8 Back. Slots 9–26: one IRON_HELMET per
title (**title N is at slot 8 + N**), glowing when reached: other-gender name, salary, required XP,
promotion bonuses (coins/gems/XP), and unlocks — every title: +1 skill point; 5: house slot + property
slot (DIAMOND_HELMET); 10: + special skill point; 12: quest slot; 15: house, property, keep and
assignment slots. Engine fit: engine, with a `titles` row source; "highlight title N" deep links come
in via `ctx` (P5).

### 3.4 User features (premium) — Donator-ranks information — `Menu.java:2132-2227`

"Donator-ranks' information", 54 slots. 0 Financial, 4 EMPTY_MAP ("Ranks can be purchased with /buy!",
"All benefits from lower ranks are unlocked as well"), 8 Back. Four tier blocks laid out by the slot
lists at `Menu.java:118-128` (Default columns 0–1, Noble 2–3, Royal 4–5, Dragon Blood 6–8). Each block:
five "find the item to collect N gems" armour pieces + sword (Default 50/100 gems, Noble 80/130, Royal
120/150, Dragon Blood 200/250; "Collect the whole set to earn Noble for free"), a rank block
(IRON/GOLD/DIAMOND/REDSTONE_BLOCK, multiplier 1 / 1.1 / 1.2 / 1.5, price $10 / $15 / $25), and BOOK
perks: tournaments, spawnpoints (teleport delay 5 s vs 3 s), bodyguards (named NPC lists), items;
Dragon Blood also pets, back-command, teleport invites, "Mystical island". Glow = unlocked.
Display-only. Bugs: B11. Port only after vision §5.3 re-decides premium perks.

### 3.5 Social — friends — `Menu.java:2359-2629`, clicks `FriendManagerClick.java`

- **Manage friends** (size by friend count): 0 own "Social profile" head, 1 BOOK_AND_QUILL "Add new
  friends", 2 SIGN "You have new friendrequest(s)!" (only when > 0), 4 BANNER header ("add, delete or
  edit permissions of your friends" — no such feature exists), 8 Back; 9+ friend heads (donator tier,
  title, gender, XP, coins, gems, houses, properties, kills, deaths) with **no click action**.
- **Add friends** (size by online count): 0 "Social statistics" head (friends, open requests), 4
  header, 8 Back (friends manager); 9+ online players' heads + "Click here to add!" / "Request already
  sent!" / "This player already invited you!". Staff/op/owner-mode viewers see everyone; others don't
  see owners, ops or owner-mode players. Alone online → red clay "No players online!". Click →
  `/friends add <name>`. Bugs: B12.
- **Friend requests** (size by *online* count, not request count): header copy-pasted from Add friends;
  requester heads "Click here to accept/deny" → option menu.
- **Friend request from X** (9): 0 green clay Accept, 4 BARRIER Cancel, 8 red clay Deny →
  `/request accept|deny <name>`. The name is parsed from the inventory title (P2).

### 3.6 Towns — Teleport to spawnpoints — `Menu.java:2010-2130`, clicks `SpawnpointClick.java`

Size 18 + 9 per 9 spawnpoints (no guard above 45 spawnpoints). 0 Financial, 4 EMPTY_MAP "Information"
("Teleportation starts after 3 seconds", "The prices are paid in gems!"), 8 Back. 9+: COMPASS
"Location: <name>" coloured by the required donator tier, gem price, and "Available! Click here to
teleport" / "Locked! Reach title X to unlock" / "Locked! Donator-rank X or higher required!". Owner mode
bypasses every lock. Click (when lore line 1 isn't "Locked") → `spawnpoint.tryRegularTeleport` (charges
gems, delayed teleport) + close. Engine fit: feature action + render conditions; the title/tier gate is
vision §2.2 access-gating.

### 3.7 Structures / Items — shops, selling, purchasing

#### 3.7.1 Shopkeeper "Products of <property>" — `Menu.java:2632-2826`, clicks `ItemMenuClick.java:101-193`

Size by product count; opened by right-clicking the property's Citizens Shopkeeper NPC.

| Slot | Item | Shows | Click → |
|---|---|---|---|
| 0 | Financial | | — |
| 2 | EMPTY_MAP quest (only if the property has an active quest not assigned to someone else) — "New Quest!" / "Your current Quest" | name, description (5 words/line), rewards (coins/XP/gems), target property + address (Intimidate Rival) or warehouse (Deliver Package), progress (gathered/delivered x/y, Killed/Alive), "Click here to accept Quest!" / "Click here to deliver items!". Blinks for 10 s one second after opening when unassigned. | accept / "harvest first" / Quest deliver menu (§3.12.5) (Quests) |
| 3 | CHEST "Sell items to this <category>" | | Sell menu (§3.7.2) |
| 4 | ANVIL "Information about X" | address, price, income; + "You own this" / "Owned by: X" / "No owner — in /menu go to Properties > Buy a new Property to buy!" | Property list with this property blinking |
| 5 | EMPTY_MAP "Asignments" *(owner only)* | "(1) — It looks like one of the chests is full!" when a chest is full | `new Transport(user, property)` — starts the warehouse transport assignment (Quests/Economy) |
| 8 | BARRIER Exit | | close |
| 9+ | each product the property sells (`product.createPropertyItem`) | + Price, Stock, "Click here for more information" | Item info (§3.7.3) |

Identity: the property id is re-parsed from slot 4's lore on every click (P2).

#### 3.7.2 Sell items — `Menu.java:2828-2877`, clicks `ItemMenuClick.java:194-283, 521-624`

"Sell items to <property>", 36 slots. 0 Financial, 3 CHEST "Sell items" ("Price: 0", **live-updated**
10 ticks after every click/drag), 4 property info, 5 BOOK instructions ("Drag selected items from your
inventory to this menu, click the chest icon to sell; items that can't be sold are returned"), 8 Back.
**Slots 19–25 are left empty as a drop zone** (G2). Items the shop can't buy are ejected back with "You
can't sell items of this category to this shop!". "Sell items" sums `sellPrice × amount`, puts the sold
goods into the property's warehouse (`fillWarehouse`), pays coins, closes. Closing returns leftovers
(dropped on the ground when the inventory is full). Allocation: Structures (warehouse) + Economy.

#### 3.7.3 Item info (purchase) and coupon — `v1:src/Products/PropertyProduct.java:436-507`, clicks `ItemFrameAdd.java:272-360`, `CouponClick.java`

- **Item info** — title = the product's display name (P2), 9 slots: 0 Financial, 3 CHEST "Amount: 1"
  (click cycles the per-purchase amount, `ItemFrameAdd.setItemStep:687+`), 4 product, 5 NAME_TAG "This
  item costs: N" (stock, "may change per day", then "out of stock" / "Click here to buy" / "You have N
  coupons available" / "need N more coins"), 6 EMPTY_MAP description + category, 7 BOOK "Knowledge
  required for this item: /" (placeholder), 8 Exit. Only works while the player stands inside a property
  region. Buying fires a `PurchaseEvent`. Allocation: Items (purchase) inside a Structure (shop).
- **Use Item Coupon?** (9): 0 green clay "Buy with coupon", 2 the coupon (taken out of the player's
  inventory as **escrow** when the menu opens), 4 product, 6 NAME_TAG price/stock, 8 red clay Cancel
  (returns the coupon). Coupons are recognised by display name "item coupon" and a "Category: X" lore
  line. The escrow is released on Cancel, on close, or by `PurchaseEvent` after a coupon purchase
  (`v1:src/Handlers/PurchaseEvent.java:27`). Engine fit: G2 (escrow).

#### 3.7.4 Enchant item with <enchantment> — `ItemFrameAdd.java:473-600`, clicks `ItemFrameAdd.java:361-464` → **Custom enchantments**

27 slots, opened from an item frame in an enchanter property. 0 Financial ("Finacial"), 4
ENCHANTED_BOOK (add, or +1 level, and "Maximum chance of success is N" — derived from the property's
contribution level), 7 BOOK knowledge placeholder, 9 the player's held item, 13 ENCHANTMENT_TABLE
"<Left is your current item / Right is your future item>", 17 preview with the new enchantment. 20–24
NETHER_STAR tiers: Default (random chance in a range), Slightly increased, Increased, Extremely
increased, Super extreme (chance of +2 levels); prices +0 / 10 / 30 / 50 / 80 %; "Click here to buy" or
"You need N more coins". The click parses chance and price back out of the lore (P2). Bug: B13.

### 3.8 Items — Gem-shop — `Menu.java:3312-3387`, clicks `GemShopClick.java`

"Gem-shop", size by count. 0 Financial, 4 DIAMOND header, 8 Back. 9+: every gem product in category
"special": the product item + description (wrapped at 5 words — **only when longer than 5 words**;
shorter descriptions show just the "Description:" heading), "Price: N", "Click here to buy!" / "You need
N more gems!". Empty → blue panes "No special products available now!". Click: needs ≥ price gems and one
free inventory slot, then removes gems, gives the item. No confirmation. Bug: B15. v3: `ItemTemplate`s
with gem purchase currency (vision §9.1) through the catalogue source + a purchase action.

### 3.9 Gates — `Menu.java:3834-3945`, clicks `GateManagerClick.java`

- **Gate Manager** (owner; size by loaded gates): 4 FENCE header ("Tip: Activate Gates by entering the
  town they belong to", active count), 8 Back. 9+: one item per *currently loaded* gate (icon = the
  gate's material): ID, town, street, facing, health, Closed/Opened → Gate information.
- **Gate information** (27): 4 gate card; 7 BOOK_AND_QUILL "Save changes" (persists to the DB); 8 Back;
  steppers 9/10/11 max health (+ / GOLDEN_APPLE value "Steps: 10" / −) and 18/19/20 current health (+ /
  APPLE / −; Shift-left on + = full heal); clicking a value cycles its step 10→20→50→100 (G1); 13 SIGN
  rename ("This function does not work yet"); 16 LEVER open/close toggle (live); 22 material picker; 25
  LEVER destroyed/intact toggle (live). Everything except Save is an unsaved in-memory edit (G6).
- **Choose gate material**: every "resources" product whose material is a block; click sets it and
  returns to Gate information.

Allocation note: v3 gates are authored in the web-app; an in-game port only makes sense for the live
toggles.

### 3.10 Siege & other minigames — events

- **Events list** — `Menu.java:4639-4665` (18): 0 SIGN online players; 4 CAKE header (copy says "Event
  Manager", reused from the admin screen); 8 Back; 12 LEAVES Hide and Seek; 14 BANNER Siege (game
  description: "2 teams… The goal: Attackers capture the objectives, Defenders defend them").
- **Siege overview / information / spawnpoint (player)** — `Menu.java:5531-6228`, `EventsClick.java:63-237`:
  documented in `MENU_TEMPLATES.md` Part A (A.1, A.8) and ported in Part C. Not repeated here.
- **Hide and Seek overview (player)** — `Menu.java:4667-4788`, `EventsClick.java:238-270`: if already in
  a game, jumps straight to its information. 4 LEAVES summary (games, players), 8 Back; 9–17 BARRIER "No
  Hide and Seek" placeholders overwritten by games: LEAVES "Hide and Seek <id>" — location, joined
  players, stage, countdown, then "Click to join!" / "Can't join match! Allowed titles: higher than N" /
  "Wait for matchmaking to start". **Click joins immediately**.
- **Hide and Seek information (player)** — `Menu.java:4790-5103`, `EventsClick.java:271-377` (54): row 0
  black panes; 0 COMPASS scenario (town, entry title); 4 LEAVES game card (countdown, "Participating",
  "Your team: X" or the join line); 6 BANNER rules text; 8 Back ("To leave this game, Right-Click this
  button", G3). Matchmaking: 13 player-head "Joined players" (count, joined friends, average title), 9/17
  tabs over 36, heads from 18 (own head glowing). In progress: hiders 9–26 (tabs 1/7), seekers 36–53 (31
  header, tabs 27/35). Bugs: B15, B16.
- **Event Manager (admin)** — `Menu.java:3947-3961` (18): 0 online players, 4 CAKE, 8 Back, 12 Hide And
  Seek → HS manager overview, 14 Siege → Siege manager.
- **HS manager overview / HS manager / HS player (admin)** — `Menu.java:3963-4304`,
  `EventManagerClick.java:65-289`: game list; per game: reward stepper (step 250, G1), 12 "Send to hub"
  (all), 13 stage + countdown, 14 "Next stage" (cooldown → skip; matchmaking → 16 s left; progress → 2 s
  left), 15 location (cycles towns except "wilderness"; locked in progress), 16 BEACON auto-start toggle,
  row 18–26 black separator, 31 participants header, heads from 36; per player: switch role, kick,
  spectate (teleport to them), send to hub, hint seekers (street name near the hider). Bugs: B17, B18.
- **Siege manager (admin)** — `Menu.java:4306-4406`, `EventManagerClick.java:290-317`: 4 BANNER summary;
  9–17 active sieges ("Siege n", "Click here to edit" — **no click handler**); 18–26 black separator; 31
  "Scenario manager" header ("Create one with /scenario"); scenarios from 36 (name, town, min/max players,
  "Active in a siege", "Click to manage").
- **Scenario manager (admin)** — `Menu.java:4408-4493`, `EventManagerClick.java:318-440`: 0 DIAMOND_SWORD
  Test Scenario; 4 summary (id, town, entry title, team spawnpoints set?, main objective set?, side
  objective count, red "can't activate" warning); 6 Save changes; 7 LAVA_BUCKET Delete scenario; 8 Back;
  min/max players steppers in columns 9/18/27 and 11/20/29 (G1); 13 Change location (chat capture,
  G5); 22 Main Objective (teleport); 31 Test Main Objective; 24 Team 1 spawnpoints; 26 Team 2
  spawnpoints (unreachable, B19); 40 Side Objectives header; side objectives from 45. Bug: B18.
- **Side objective manager / Change Gate (admin)** — `Menu.java:4495-4595`: delete, gate (set/change,
  opens a picker of the scenario town's gates — which **replaces the global loaded-gate list** as a side
  effect, `Menu.java:4543`), change location, teleport, test. Change Gate's Back goes to the Personal
  Menu (B21).
- **Manage Siege Spawnpoints (admin)** — `Menu.java:4597-4637`: one 3-row column per spawnpoint (change
  location / teleport / delete). Bugs: B18, B20.

Allocation: Siege admin → Siege minigame (in-world tools only; authoring → web-app). Hide and Seek →
other minigames (no spec).

### 3.11 Onboarding & support — `Menu.java:3389-3397, 3649-3795`, clicks `SupportMenuClick.java`

- **Support** (27): 0 profile, 4 REDSTONE_TORCH header, 8 Back; 12 LEASH Tutorials; 13 BOOK_AND_QUILL
  FAQ ("Coming soon!", no handler); 14 DIAMOND_SWORD List of Items.
- **List of tutorials** (size by count + 9): 0 profile, 4 LEASH header, 8 Back; 10+ STRING "<name>
  Tutorial" (description, "Completed on <date>" or the gem/XP reward). The click strips the " Tutorial" suffix before the lookup (`v1:src/Tutorial/TutorialFile.java:56-76`).
- **Start Tutorial?** (27, no Back, no filler): 11 green clay Start Tutorial, 15 red clay Skip Tutorial.
- **List of existing Items** (Items feature) — `Menu.java:3723-3795`: 0 profile, 1/7 Previous/Next
  ("Page: n/N"), 2 category filter (P4), 4 DIAMOND_SWORD header (total items), 8 Back; 9+ products. Bug:
  B22. v3: the `catalog.itemblueprints` source + search/filter already cover this.

### 3.12 Quests & assignments — `Menu.java:3399-3832`, clicks `AssignmentClick.java`, `QuestMenuClick.java`

1. **Assignments** sub-menu (27): 0 profile, 4 MAP header, 8 Back; 11 Daily Assignments, 13 Quests, 15
   Achievements.
2. **Daily Assignments** (27): 0 profile, 4 header, 8 Back; slots 10–16 = the player's assignments
   (EMPTY_MAP: name, description, rewards, "Progress: x/y", visited towns for travel assignments;
   completed → MAP "Click here to claim reward!"; collected → WATCH "Completed!" with a countdown to the
   next day and "Refresh now for N Gems"). 13–16 are drawn as "Locked!" (title 15 / Noble / Royal / Dragon
   Blood) **unconditionally** (the conditional version is commented out, `Menu.java:3408-3428`) and only
   disappear if an assignment happens to sit there. Bugs: B23, B24.
3. **Quests** (27): 0 profile, 4 header, 8 Back; 10–15 accepted quests (description, shopkeeper property
   and address, rewards, progress per quest type; collected → MAP "Visit the property to collect
   reward!"); empty → COMPASS "No quest accepted! Quests can be offered to you by shopkeepers when you
   enter a property". 13 "Locked!" title 12 and 14–15 "Locked! unlock in the Gem-shop" are also drawn
   unconditionally. Bug: B25.
4. **Achievements** (54): 0 profile, 1 Previous, 2 "Filter: All", 4 BOOK header, 7 Next, 8 Back — **no
   achievement content is rendered anywhere**; the handler only supports Back. A stub.
5. **Deliver items for quest** (36): 0 profile, 3 CHEST "Deliver items" (delivered x/y), 4 MAP quest +
   drag instructions, 5 target property info, 8 Back; **19–25 drop zone** (G2). Wrong items are ejected
   ("This is not the requested item!").

### 3.13 Items / Structures (admin) — ShopItems manager — `Menu.java:1623-1916`, clicks `ItemMenuClick.java`

- **ShopItems Manager** (27): 0 WORKBENCH "Property stats" (count of properties per shop category — 12
  hardcoded categories), 8 Back, 9–20 product categories (Swords, Armor, Bows, Jewelery, Fish, Meat,
  Baked-goods, Vegetables, Furniture, Magic, Resources, Tools) → category overview. Bug: B26.
- **Overview (<category>)** — `ItemMenuClick.java:401-519`: property stats, 4 "Available <category>: N",
  8 Back; products with min/max price → "Add a <product>".
- **Add a <product>** — `Menu.java:1737-1916`: 0 stats (+ hidden product id), 1 CHEST "Click here to get
  this item" (+ hidden id; runs `/product get 64 <id>`), 4 product preview, 8 Back; 9+ every property of
  the matching shop category: items it already sells, "Click here to add item to this property" or "Already
  selling this item!" → `savePropertyProduct`.

v3: product↔shop assignment is data the web-app should own; not an in-game menu candidate.

### 3.14 User management — Player Manager — `Menu.java:1499-1621`, clicks `PlayerManagerClick.java`

- **Online-players Manager** (owner mode; size by online count): 0 own head "Current online crewmembers"
  (online count, staff / owner / owner-mode / op name lists), 8 Back; 9+ one head per online player
  ("<name>'s information": first join, title, XP, coins, gems, houses, properties, special skill, friends,
  "Click to edit statistics"). Bug: B27.
- **Edit <name> statistics** (54; `openPlayer`, `PlayerManagerClick.java:499+`): 1 BANNER "Title(n): X";
  6 ARROW "Next page" (no handler); 7 "Save changes" (only re-renders); 8 Back. Remove / value / add / max
  columns (slot lists at `PlayerManagerClick.java:60-90`) for XP, coins, gems, salary timer (reset to 1 h /
  pay now / instant payout), income timer (reset to 12 h / now / instant), kills, deaths, skill points,
  special skill points (G1); 13 IRON_BARDING Kick, 22 Ban; 50 donator title (click = remove), 51–53 set
  Noble / Royal / Dragon Blood. Promote/demote/max title = `/experience set <XP threshold>`. Every change
  is a chat command (P8).

### 3.15 Other minigames — arena & duels — `Menu.java:3016-3232`, clicks `DuelSetupClick.java`, `v1:src/Arenas/ArenaMenuClick.java`

- **Arena: <name>** (27, from the ArenaMaster NPC): 4 DIAMOND_AXE arena card, 8 Back, 12 player-head
  "Fight other players" → duel invite, 14 MONSTER_EGG "Fight gladiators" ("Coming soon!").
- **Choose a player to duel** (size by online count): 0 own head, 8 Back, 9+ other players' heads →
  `/duel <name>`; alone → "No players online!".
- **Choose duel-type and place bets!** (54) — **one Inventory shared by both duellists** (G4): 0 and 8
  both Back; 4 arena card; 45 / 53 the two players' heads; 46 / 52 Ready/Unready clay per player; 48 / 50
  "Duel type" per player (Coins → Practice → Coins; Shift-left → Items); free stake slots 10–12, 14–16,
  19–21, 23–25 (G2). Coin bets are typed in chat (G5). Each player may only click their own half; changes
  reset readiness; both Ready starts the duel.

---

## 4. v2 screen catalogue (non-siege)

v2 had one live menu tree (`model/menu`) and one mostly-unwired rewrite (`menu/preset`) — see
`inventory-menus.md`. Siege menus: `MENU_TEMPLATES.md` Part A.

### 4.1 Hub + Kits — `v2:model/menu/main/MainMenu.java:44-74`, `main/KitOverviewItem.java`, `kit/KitOverview.java`, `kit/KitSelectItem.java`

- **Knights and Kings Menu** (18): 8 Back (Exit when opened by command), 12 ARMOR_STAND "Kits" ("See a
  list of all available Kits and choose one to play with!") → Kits overview; 14 Siege entry (see
  MENU_TEMPLATES A.2); 22 CHEST "Overview of Caches" ("For debug purposes only", no permission gate) →
  Factories overview (§4.7).
- **Kits overview** (size by kit count): 4 ARMOR_STAND "Kits" ("Number of available kits: N", "Click a
  kit to equip it."); 8 Back; no kits → 13 BARRIER "No Kits available" ("ask a member of staff"); 9+ one
  item per kit (material = the kit's menu item): "Description: …", "-Contents" helmet / chestplate /
  leggings / boots / hand / shield, "-Other contents" comma list. 1/7 tabs when more than 36 kits. Click →
  `kit.assignKit(target)` with **no permission, cooldown or confirmation check** (already documented as
  `kits.md` bug #3). Bug: B28 (tabs never work).

v3 port (Kits): `kits.overview` template, row source over the claimable kits, `kits.claim` feature
action calling `KitService.ClaimKitAsync` (Kits `DESIGN.md` §7), Click-phase conditions for permission
and cooldown, and a row lore line for the cooldown/price state.

### 4.2 Creation wizard select stage — `v2:menu/preset/menu/creation/CreationStageSelectMenu.java` (**live**)

Opened automatically 15 ticks after a Creation wizard reaches a multi-select stage, or by typing `open`
(`v2:creation/CreationStageSelect.java:254-287`); typing `select …` throws "This method is not used".
Header BOOK = stage name + description; footer GREEN_CONCRETE "Confirm selection" (→ `processStage("save")`,
re-opens the menu on failure); one content row (height 1, **no paging**, so options beyond 9 are
unreachable) of options with "Click to select/deselect" and blink = selected. This is the only place the
`menu/preset` rewrite ran during normal play (correction C2). Allocation: Form configurations — **do
not port** (v3 authors entities in the web-app).

### 4.3 Structures — storage and production (debug-reachable only) — `v2:model/menu/dominion/structure/*`, `menu/preset/menu/dominion/structure/ProductionStructureMenu.java`

- **Storageoverview of X**: CHEST "Contents of storage", COMPARATOR "Expand storage clickTypeActions"
  (toggles a sub-section), a content group of stored items with "Amount: N", and "Add items to storage" —
  whose action body is **commented out**.
- **Add Items to X** (`StorageAddMenu`): selectable items with per-item amount steppers (left +step,
  right −step, shift = change step, `StorageAddItem.java:44-93`, G1 + G3), "Show/Hide Selected Items",
  GREEN_TERRACOTTA "Confirm add action" ("Currently adding: %getSelectedItemsSize% unique items",
  "Storage cap. after adding: …" — `%…%` placeholders, so bug #7 of `inventory-menus.md` means they showed
  literally).
- **Chestoverview of X** (`ChestOverview`): the whole class body is commented out.
- **ProductionStructureMenu** (preset): details of a production structure with "Click to show
  Storages" / "Click to show Productions" drop-downs.

Only reachable through the debug object browser (§4.7). Allocation: Structures (no spec) — treat as
design notes, not as content to port.

### 4.4 Items — `v2:model/menu/item/ItemOverview.java` (via `/item list`)

Scaffolding: section "TestHeader/Main" with an IRON_SWORD header whose left/right/shift clicks move and
resize the section (a layout test), a STONE "Expand Itemtypes" toggle over an Items sub-section, a
content group of Itemtypes, and a second section "Players" listing every registered user (not items).
Already described in `items.md`; nothing here to port — the v3 item catalogue replaces it.

### 4.5 Custom enchantments — `v2:model/menu/player/PlayerEnchantMenu.java` (+ `PlayerInventoryOverview`)

Right-clicking an enchanted book whose display name is a vanilla enchantment key opens "Click an item to
enchant": a 45-slot copy of the player's inventory contents (G4). Clicking an item adds the enchantment
(unsafe, +1 level), removes the book, closes. Bug: B29.

### 4.6 Towns — `v2:model/menu/dominion/town/TownOverview.java`

A `CachableOverview` of all towns. Its only caller is commented out (`v2:spigot/command/dominion/town/TownCommand.java:180`).
Dead.

### 4.7 Debug tools — do not port

- **Overview of Factories** (`main/FactoriesOverview.java`): one CHEST per ORM repository ("Cached
  objects: N") → **Cached objects of …** (`cache/CacheOverview.java`, a `CachableOverview`; the title uses
  the *repository* class name, not the object class) → **Details of X** (`CacheDetail`/`CachableDetail`,
  field-by-field reflection view; storages link to §4.3).
- Preset tree: **Overview of Repositories** / **<Type> Repository** (`RepositoryOverview`,
  `RepositoryDetails` — clicking *any* listed object opens `ProductionStructureMenu`, whatever its type),
  `DropdownTest`, `LoadingMenu` (the async open pipeline's loading screen).
- `CreationOverview` (`createMenu` returns null), `PlayerInventoryOverview` ("Test inv", `/creation`
  test command).

---

## 5. Corrections to `inventory-menus.md`

- **C1 — Kit pagination never worked.** `inventory-menus.md` says the Kit overview is "fully functional
  including pagination" because `CachableOverview`/`ContentGroup` back it. It doesn't: `KitOverview`
  extends the base `Menu` (`v2:model/menu/kit/KitOverview.java`), its tabs are `TabPrevious`/`TabNext`
  (`PageButton` subclasses), and on a plain `Menu` those call `Menu.prevPage()/nextPage()` — the no-op
  fail-sound stubs (`v2:model/menu/Menu.java:411-420`, that doc's bug #9). With more than 36 kits the rest
  were unreachable. `CachableOverview` backs the debug Cache/Town overviews, not Kits.
- **C2 — The `menu/preset` rewrite did run in normal play**, in one place: the Creation wizard's
  multi-select stage (§4.2). `inventory-menus.md` says it was reachable only through `/menu test`.

## 6. Bugs found in this pass

Numbering continues separately from `inventory-menus.md`'s 1–11. "Lesson" = what a v3 port must not
repeat.

| # | Bug | Source | Lesson for the port |
|---|---|---|---|
| B1 | Title highlight deep links are off by one: title N sits at slot 8 + N, but locked-tile clicks blink slot 14/19/24 (titles 6/11/16) for titles 5/10/15, 24 for title 15 from assignments, 21 for title 12 from quests. | `OwnedhousesClick.java:185-212`, `AssignmentClick` | Link by id (`ctx.highlight=<titleId>`), never by slot. |
| B2 | Quest "Locked!" click `Bukkit.broadcastMessage`s a debug line to **every player on the server**. | `AssignmentClick.onQuestClick` | — |
| B3 | Clicking your own profile head opens the friends manager (name "Social profile" matches `contains("social")`). | `MenuClick.java:221-225` | P1. |
| B4 | Slot caps: `if title ≥ 5 … else if ≥ 10 … else if ≥ 15` — only the first slot ever unlocks; the same `else if` on donator 2/3 means Dragon Blood doesn't unlock the Royal slot. | `Menu.java:1240-1256, 1449-1465` | Independent render conditions per tile. |
| B5 | Owned houses/properties draw the owned rows over the cap tiles (houses from slot 11, properties from slot 10), so tiles and rows collide. | `Menu.java:1258, 1467` | Separate sections for "slots" and "owned". |
| B6 | Unaffordable room rows have an extra first lore line, so the lore-parsing id lookup reads the wrong lines → `NumberFormatException` on click. | `Menu.java:1015-1024` + `getMenuStructureID` | P2. |
| B7 | Next/Previous on the structure lists drop the active town filter. | `HouselistClick.java:52-61` (+ property/room) | Filter state lives in the session (engine does this). |
| B8 | **House list rows never react**: rows are named "House: X" but the handler checks "Housename: ". Buying from the house list silently did nothing. | `Menu.java:664` vs `HouselistClick.java:105` | P1. |
| B9 | Room list town filter never works: the display name is lower-cased, then compared with `contains("Town: ")`. | `RoomlistClick.java:51, 112` | — |
| B10 | Forced-sell menus use `slot = slot++` (never increments), so every row lands on slot 3 — only the last house/property is visible. | `Menu.java:2901, 2927` | — |
| B11 | Donator info: Dragon Blood sets `royalPrice` instead of `dbPrice`; tiers aren't cumulative in the display although the header says lower-tier benefits are included; an owned tier's status line reuses the armour-collection text ("haven't found this item yet"). | `Menu.java:2152-2169` | — |
| B12 | Add friends: uses the *viewer's* UUID where the target's was meant, so existing friends are never filtered and "already invited you" never shows; when a target is hidden, the lore decoration is applied to `slot - 1` (the previous head, or the Back button); one unknown online player aborts the whole menu. | `Menu.java:2485-2545` | — |
| B13 | Enchant menu parses the "super extreme" price from lore line 3, which is only the price line in the affordable variant → exception when clicking it unaffordable. | `ItemFrameAdd.java:443-448` | P2. |
| B14 | Gem-shop click resolves the product by display name using the *regular*-product table while the menu lists the gem-product table. | `GemShopClick.java` | P2. |
| B15 | HS information in cooldown opens the overview, then keeps going and opens the information menu over it. | `Menu.java:4873-4877` | — |
| B16 | HS/Siege tab paging passes `page++` / `page--` (post-increment), so the page never changes. | `EventsClick.java:142-149, 340-372` | P3. |
| B17 | HS participant role display compares a `User` against a list of `Participant`s → always shows "Seeker". | `Menu.java:4274` | — |
| B18 | Admin list screens size themselves as fixed rows + `Main.getMenuSize(n)` (which already adds a header row: 0–9 → 18, 10–18 → 27, … `v1:src/Main/Main.java:1467-1496`). Past a threshold the total exceeds 54 and Bukkit refuses to create the inventory: HS manager and Siege manager at 19+ participants/scenarios (27 + 36), Scenario manager at 10+ side objectives (36 + 27). The spawnpoint manager's three-rows-per-spawnpoint layout also overlaps itself beyond 9 spawnpoints. | `Menu.java:4062, 4316, 4410, 4612` | Engine layout validation rejects over-54 menus at load time (reconciliation bug #8's guard). |
| B19 | Team 2 spawnpoint manager is unreachable: the item is named "Spawnpoint: Team 2" but the handler expects "spawnpoints team 2". | `Menu.java:4474` vs `EventManagerClick.java:374` | P1. |
| B20 | "Manage Siege Spawnpoints" is never routed by `MenuClick`, so its handler (`EventManagerClick.java:518-572`) is dead and clicks are **not cancelled** — items can be taken out of the menu. | `MenuClick.java` dispatch | Engine cancels every click (fixed by design). |
| B21 | Side-objective gate picker's Back opens the Personal Menu; side-objective manager's Back skips the scenario level. | `Menu.java:4557, 4501` | `menu.back`. |
| B22 | Item list page count uses `Math.round(size / 45)` (50 items → 1 page) and the hardcoded start indices skip item 45. | `Menu.java:3729-3759` | P3. |
| B23 | Assignment refresh maps slot 9→index 0, but assignments render from slot 10 → refreshing the **next** assignment; slot 16 throws when fewer than 8. | `AssignmentClick` `slotIndex` | Row identity (E3). |
| B24 | Assignment countdown formats remaining millis via `java.util.Date` (time-zone-shifted hours). | `Menu.java:3469-3488` | — |
| B25 | Quest lock tiles are drawn unconditionally and the "No quest accepted!" filler only replaces glass panes, so players can never see an unlocked empty quest slot. | `Menu.java:3540-3643` | Render conditions. |
| B26 | ShopItems manager category click compares the display name ("Swords") against the category name list; if the stored names are lower-case, nothing opens. *Unverified against DB data.* | `ItemMenuClick.ShopItemsManagerClick` | — |
| B27 | Player Manager: one online owner makes every non-owner click print "You can't modify this player!" (once per online owner); a co-owner's click on **anything** (even Back) opens the editor for every online player in turn. | `PlayerManagerClick.java:451-497` | — |
| B28 | = C1 (Kit tabs are no-ops). | `v2:model/menu/kit/KitOverview.java` | Paging on the base class (engine does this). |
| B29 | `PlayerEnchantMenu` enchants **every** stack equal to the clicked one, removes **every** matching book stack, and its max-level branch is unreachable (unlimited levels). | `v2:model/menu/player/PlayerEnchantMenu.java` | — |
| B30 | v1 `setMenuItemBlink` only records its repeating task when the player already has an entry in `Main.flashTask`, and nothing else ever puts one (`Main.java:286` declares it empty; the only `put` is inside that check, `Menu.java:2978-2986`), so `stopMenuItemBlink` reports "Couldn't find a flash-task" and the blink only ends when the slot empties. | `Menu.java:2935-3014` | — |

## 7. Open questions for the project owner

**Decided 2026-09-25:**

- **Structures (houses, rooms, properties, shops, warehouses) are shelved.** Their screens (§3.2,
  §3.7.1–3.7.3, §3.13, §4.3) stay here as reference only; nothing is ported until the Structures
  feature is designed.
- **The v3 hub grows from v2's sparse main menu** (§4.1: Kits, Sieges; the debug Caches tile is
  dropped), adding one tile per feature as that feature's menu is ported. v1's Personal Menu (§3.1) is
  a source of tile ideas, not a layout to rebuild.
- **Engine gaps are built on demand, not ahead of time.** Ports #1–#6 below need none of G1–G7.
  **G1** (numeric steppers with a per-session step size) is required by #7 Player manager, which keeps
  v1's adjustable steps, so it is built before or together with #7. After that: **G3** (click-type on
  `ActionBinding`) when a screen needs left/right/shift variants; **G4** (a row source over the
  player's own inventory) with the custom-enchantments UI. **G2, G5, G7** wait until a shelved or
  unspecified feature (structures, quests, duels, tutorials) comes back.

- **Port order** — implementation planned in [../inventory-menu/CONTENT_PORT_PLAN.md](../inventory-menu/CONTENT_PORT_PLAN.md) (also covers G1 and staff actor attribution). Grounded in which v3 backends exist on 2026-09-25 (Kits merged; user-features
  Phases 1–6 shipped; user-management shipped; `ItemBlueprint` catalogue exists but no pricing or gem
  currency; no v3 spawnpoint concept; custom enchantments still a draft). The engine itself lives on
  `claude/siege-minigame` until it merges to trunk.

  | # | v3 screen | Built from | v3 feature | Needs |
  |---|---|---|---|---|
  | 1 | Hub (`/menu`) | v2 `MainMenu` (§4.1): Kits + Sieges tiles and Exit; debug Caches tile dropped | InventoryMenu content | Engine only; tiles added per feature as it lands |
  | 2 | Siege tile + screens | `MENU_TEMPLATES.md` Part C | Siege | Siege Phase 8b (already planned) |
  | 3 | Kits overview | v2 `KitOverview` / `KitSelectItem` (§4.1) | Kits | `kits.claim` action → `KitService.ClaimKitAsync` (Kits `DESIGN.md` §7); Click-phase permission + cooldown conditions. Fixes B28 and `kits.md` bug #3 |
  | 4 | Profile & titles | v1 Title information (§3.3) + Personal Menu profile, Titles, Financial tiles (§3.1) | User features | Engine only (read-only); own title as HIGHLIGHT |
  | 5 | Item catalogue | v1 List of items (§3.11) | Items | Engine only (`catalog.itemblueprints` + search/filter); more useful once items have prices |
  | 6 | Premium tiers | v1 Donator-ranks information (§3.4), redesigned | User features | Vision §5.3 premium-perk decision; built from v3 tier data, not the 2017 content |
  | 7 | Player manager | v1 Online-players Manager + Edit statistics (§3.14) | User management | A plugin-side user-management `MenuFeature`: online-players row source, profile variables from the composite profile endpoint, actions calling the existing quick-action services (group membership, grant, owner/staff-mode toggle, balance adjustment — all audit-logged, attributed to the acting staff member). **Keeps v1's adjustable steps** (+ / value / − per field, clicking the value cycles the step size) → needs engine gap **G1**, built before or with this screen. Kick and ban run Paper's built-in `/kick` and `/ban` as the clicking staff member (so vanilla command permissions apply), behind a `menu.confirm.*` dialog |

  **Implementation status (2026-09-25):** #1 Hub, #3 Kits, #4 Profile & titles, #5 Item catalogue,
  #6 Premium tiers and #7 Player manager are implemented, with G1, on `claude/menu-content`
  (knk-web-api + knk-plugin) — not merged, not live-verified; #2 (Siege screens) remains Siege Phase 8b,
  and the hub already carries its tile (hidden until `siege.overview` validates). Staff actor
  attribution is only half done (plugin sends the actor; the API side awaits an auth decision) —
  CONTENT_PORT_PLAN.md CP7.

  Deferred until the feature exists: Gem-shop (pricing/gem currency), Teleport (spawnpoints),
  Enchantment menu (spec draft; needs G4), in-game gate/siege admin tools (open question 1), friends,
  quests, skills, Hide and Seek, duels, tutorials. Not ported: structures (shelved), ShopItems manager,
  creation wizard, v2 debug browsers, dead tiles.

**Still open:**

1. **Remaining in-game admin screens (Gate editor, Siege/Scenario manager, ShopItems manager).** The
   Player manager is in the port order (#7). For the rest, the web-app covers gate and scenario
   authoring: keep only the in-world tools (teleport to objective, test objective, gate open/close)
   in-game, or drop them?
2. **Dead tiles** (Pets/Servants, Knowledge, Settings, Financial, Theft report; Achievements screen;
   Arena "Fight gladiators"; FAQ): keep as v3 placeholders for planned features, or leave them out of the
   hub until each feature exists?
3. **Donator information** is 2017 content (armour-set collection, $ prices, bodyguards, Mystical
   island). Port as-is, or redesign it together with vision §5.3 premium tiers?
