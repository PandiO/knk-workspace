# InventoryMenu — Content Port Plan (hub, Kits, Profile, Items, Premium, Player manager)

**Status:** In progress — CP1–CP4 shipped on `claude/menu-content` (see the CPn status blocks). Phases are numbered CP1–CP8 (content port) to keep them apart from the engine plan's Phases 1–9, which this document cites as "engine Phase N".
**Last updated:** 2026-09-25

Ref: [../legacy/inventory-menu-screens.md](../legacy/inventory-menu-screens.md) (the legacy screen
catalogue this plan ports from; its §7 records the decisions below),
[IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) (the engine — Phases 1–8 on trunk, engine Phase 9 E1–E9 on
`claude/inventorymenus`), [../siege-minigame/MENU_TEMPLATES.md](../siege-minigame/MENU_TEMPLATES.md)
(the worked example of a legacy → v3 menu port), [../kits/DESIGN.md](../kits/DESIGN.md) §7,
[../user-features/DESIGN.md](../user-features/DESIGN.md), [../user-management/DESIGN.md](../user-management/DESIGN.md).

## 0. Scope and decisions

Owner decisions (2026-09-25) this plan implements:

- The v3 hub **grows from v2's sparse main menu**; one tile per feature as it is ported. v1's
  Personal Menu is a source of ideas, not a layout to rebuild.
- **Port order** (catalogue §7): #1 Hub, #2 Siege tile (screens themselves are Siege Phase 8b),
  #3 Kits overview, #4 Profile & titles, #5 Item catalogue, #6 Premium tiers (read-only, from
  today's data), #7 Player manager.
- The Player manager **keeps v1's adjustable steps** (+ / value / − per field, clicking the value
  cycles the step) → engine gap **G1** is built in this plan.
- **Kick and ban** use Paper's built-in `/kick` and `/ban`, run as the clicking staff member.
- **Staff actions are audit-logged under the staff member who clicked** — needs an actor-attribution
  change in knk-web-api, which also fixes the existing `/knk user` command.
- Houses/properties/shops are **shelved**; no engine gap other than G1 is built.

**In scope:** menu templates (web-api seeds), plugin `MenuFeature`s, the few read endpoints and
api-client calls those need, engine G1, actor attribution, a player `/menu` command.

**Out of scope:** Siege's own menus (Siege Phase 8b), everything shelved or deferred in catalogue §7
(Gem-shop, Teleport, Enchantment UI, gate/siege admin tools, friends, quests, skills, minigames),
engine gaps G2–G7, a FormConfig authoring UI for templates, trunk merges, applying anything to the
shared dev database.

## 1. Branching and baseline

- One standing branch per repo, `claude/menu-content`:
  - **knk-web-api**: from `origin/master`, then `git merge origin/claude/inventorymenus` (engine Phase 9
    schema/API + `example.domain` seeds).
  - **knk-plugin**: from `origin/main`, then `git merge origin/claude/inventorymenus` (engine Phase 9
    engine extensions, `MenuFeature`, `ExampleDomainMenuFeature`).
  - **knk-web-app**: no changes expected. Don't create a branch unless a change turns out to be
    needed (none is planned).
- Why this base: trunk already has engine Phases 1–8 and Kits; only engine Phase 9 (feature roots, row
  templates, render conditions, `ctx`, `menu.back`, auto-refresh) is off-trunk, and every screen here
  needs it. `claude/siege-minigame` also carries engine Phase 9 plus unfinished Siege work — don't branch
  from it. Both branches carry the same engine Phase 9 commits, so they merge cleanly later.
- engine Phase 9 is **not live-verified**. This branch inherits that status; the owner verifies engine Phase 9 and
  this plan's screens live together before any trunk merge (§11).
- Baseline before CP1: web-api `dotnet build` + `dotnet test` (5 known pre-existing failures on
  master: `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`,
  `FormSubmissionProgressRepositoryTests.DeleteCompletedOlderThanAsync_…`,
  `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_…`,
  `PathResolutionServiceTests.ValidatePathAsync_AllowsValidV1Paths` ×2); plugin
  `./gradlew test shadowJar`. Record the numbers in the CP1 status.

## 2. Conventions for every phase

- **Templates** are create-only seeds in knk-web-api: a new partial file
  `Models/Menu/MenuTemplateSeed.Content.cs` yielding `MenuTemplate`s, wired into
  `MenuTemplateSeed.SeedCanonicalAsync` like the engine Phase 9 `DomainIntegrationTemplates()`. Because seeds
  are create-only by `Key`, **a template must be complete when first seeded** — adding a tile to an
  already-seeded hub later requires a CRUD-API edit. §4's `menu-available` condition exists so the
  hub can ship every planned tile up front.
- **Keys:** `main` (hub), `kits.overview`, `profile.main`, `items.catalog`, `premium.tiers`,
  `users.manager`, `users.manager.edit`, `users.manager.groups`, `users.manager.titles`.
- **Plugin features:** one `MenuFeature` per feature in a new package `knk-paper/.../paper/menu/content/`
  (`HubMenuFeature`, `KitsMenuFeature`, `ProfileMenuFeature`, `ItemsCatalogMenuFeature` if needed,
  `PremiumMenuFeature`, `UserManagerMenuFeature`), added to `KnKPlugin`'s `menuFeatures` list next to
  `ExampleDomainMenuFeature`. Registration after validation throws (engine Phase 9 J11).
- **Threading:** providers, row sources and conditions are called on the main thread (engine Phase 9 §9.0).
  Anything that needs the web-api returns an incomplete future from the row source's fetch, never a
  blocking call. Actions call the async `*Api` ports and hop back to the main thread before touching
  Bukkit (`Bukkit.getScheduler().runTask`), as `KitCommand` does.
- **Views/rows:** public classes with public zero-arg getters (reflection); `List<String>` getters for
  multi-line lore (E8); `SlotOverride` is absolute (engine Phase 9 J16); rows implement `MenuRowKey` where a
  stable id exists (J4).
- **One code path per mutation** (Kits `DESIGN.md` §7, catalogue P8): a menu action and the matching
  command call the same shared method. Where the logic currently lives inside a command class, extract
  it (named per phase below) and make the command use the extraction too.
- **Tests per phase:** web-api — extend the engine Phase 9 pattern (`MenuTemplateServicePhase9Tests`): seed
  into EF InMemory twice (create-only) and round-trip every new template through the mapping profile
  and `MenuTemplateService.CreateAsync`. Plugin — unit tests for each feature's rows/actions/conditions
  in knk-core/knk-paper, plus a `seedExpressionsValidateAgainstTheRegisteredTypes`-style test (see
  `MenuPhase9PaperTest`) proving every `$…$` chain in the new seeds validates against the registered
  types.
- **Colours:** `&`-codes in names/lore (E7). Good = `&a`, bad = `&c`, label = `&7`, value = `&f`.
- **Docs per phase:** add a "CPn status" block under that phase in this file (what shipped,
  commits, test counts, judgment calls, anything not verified); update `ACTIVE_SESSIONS.md`.

## 3. CP1 — Hub (`main`) and `/menu`

**Legacy source:** v2 `MainMenu` (catalogue §4.1); tile ideas from v1 Personal Menu (§3.1).

**Plugin:**
- Player command `/menu` → `MenuService.openMenu(player, "main", empty ctx)` (opened from outside a
  menu → fresh stack, Back reads "Exit", engine Phase 9 J2). Permission `knk.menu`, default true, declared
  in `plugin.yml`. Register the way `/kit` is registered (`registerSimpleCommand`).
- New engine condition **`menu-available`** in `MenuConditionHandlers`: params `{"key": "…"}`; allows
  when a template with that key is registered **and** passed startup validation. Used as a Render
  condition so a hub tile appears once its target menu exists (Siege's `siege.overview` arrives with
  Siege 8b; nothing in this plan edits the hub again).
- `HubMenuFeature` registers nothing beyond what the tiles need (the viewer's own head uses the
  engine `player` root).

**Template `main`** (Height 3, 27 slots):

| Slot | Item | Action | Conditions / permissions |
|---|---|---|---|
| 4 | Viewer's head (`SkullOwner` = `$player.getName$`), name `&f$player.getName$`, lore "Click to view your profile" | `menu.open {key: profile.main}` | Render `menu-available profile.main` |
| 8 | BARRIER `$menu.getBackLabel$` / `$menu.getBackHint$` | `menu.back` | — |
| 10 | ARMOR_STAND "Kits" — "See all kits and claim one" | `menu.open {key: kits.overview}` | Render `menu-available kits.overview` |
| 12 | Siege banner "Sieges" — MENU_TEMPLATES C.1 copy | `menu.open {key: siege.overview}` | Render `menu-available siege.overview` |
| 14 | DIAMOND_SWORD "Item catalogue" | `menu.open {key: items.catalog}` | Render `menu-available items.catalog` |
| 16 | GOLD_BLOCK "Premium tiers" | `menu.open {key: premium.tiers}` | Render `menu-available premium.tiers` |
| 22 | player-head "Player manager" (staff) | `menu.open {key: users.manager}` | `visibilityPermission` + `actionPermission` `knk.admin.user.manage` (new node, §10) and Render `menu-available users.manager` |

Hidden tiles leave gaps (engine Phase 9 J7); that's accepted for the hub.

**Tests:** `menu-available` unit tests (registered+valid, missing, blocked-by-validation); hub seed
round-trip.

### CP1 status — shipped 2026-09-25 (not live-verified)

**Session environment (applies to every CP status below).** Cloud session, no server, no database.
The component repos were already checked out as siblings (`/home/user/knk-web-api`,
`/home/user/knk-plugin`) rather than under `Repository/`; same remotes, so no re-clone. Branch
`claude/menu-content` in both, from `origin/master` `e949ed2` / `origin/main` `f1a4701`, then
`git merge origin/claude/inventorymenus` (web-api `859b5fa`, plugin `3d93497`, no conflicts).
web-api also cherry-picks `aaddbd5` → `338c578` (`MenuTemplateServicePhase9Tests`, which only
exists on `claude/siege-minigame` — read, not touched). Tooling: the .NET 8 SDK came from Ubuntu's
archive (Microsoft's CDN is blocked); **repo.papermc.io and maven.enginehub.org are blocked**, so
`paper-api 1.21.10` was compiled from the PaperMC sources on raw.githubusercontent.com
(`ver/1.21.10`, only the ~1.8k classes the plugin reaches) and WorldEdit/WorldGuard were replaced by
hand-written compile stubs, served to Gradle from a scratch Maven repo through a per-run `-I` init
script. None of that is committed. Consequence: plugin tests run against real Paper API
signatures, but anything that only matters at runtime on a real server is unverified, and the
`shadowJar` built here is not a deployable artifact.

**Baseline (before CP1):** web-api `dotnet build` clean, `dotnet test` **463/468** (the 5 known
failures). Plugin `./gradlew test shadowJar`: knk-core **512**, knk-api-client **28**, knk-paper
**246** (14 skipped), 0 failures — identical to engine Phase 9's recorded numbers.

**Shipped:**
- knk-web-api `e266fff`: `Models/Menu/MenuTemplateSeed.Content.cs` (new partial, `ContentTemplates()`
  wired into `CanonicalTemplates()` after the Phase 9 demos) with the `main` hub exactly as the
  table above; `Tests/.../MenuTemplateContentSeedTests.cs` — seeds twice into EF InMemory,
  round-trips every content template through `MenuMappingProfile` + `MenuTemplateService.CreateAsync`,
  asserts the hub's tiles/conditions/permissions, and `ContentSeeds_ExportAsApiJson` (see below).
- knk-plugin `03f3397`: `/menu` (`commands/MenuCommand`, `knk.menu` default true, registered via
  `registerSimpleCommand`); engine condition `menu-available` (`MenuConditionHandlers`) backed by
  `MenuService.markValidated`/`isMenuAvailable` (set by `MenuDefinitionValidationRunner` when a menu
  passes every step; a later `blockMenu` wins); `menu/content/HubMenuFeature` (registers nothing,
  owns `HUB_KEY`) in `KnKPlugin`'s feature list; node `knk.admin.user.manage` (child of `knk.admin`,
  default false) declared now because the hub tile uses it.

**Seed ↔ plugin contract test (convention for all later phases).** Rather than hand-copying `$…$`
chains into a Java test (the `MenuPhase9PaperTest` pattern), knk-web-api's
`ContentSeeds_ExportAsApiJson` writes every content template exactly as the API serves it
(mapping profile + the API's JSON options) to `knk-plugin/knk-paper/src/test/resources/menu/content-seeds.json`
when `KNK_MENU_CONTENT_SEED_EXPORT` is set; knk-paper's `ContentSeedFixture` loads that file through
the real api-client DTOs + `MenuTemplateMapper`, assembles it and runs every startup validation step
against `ContentFeatures.all()` (engine defaults + all content features). Regenerate the file whenever
a content seed changes. knk-paper gained a `testImplementation` on jackson-databind for this.

**Tests after CP1:** web-api **466/471** (same 5 failures; +3). Plugin knk-core 512, api-client 28,
knk-paper **252** (+6: `HubMenuFeatureTest` ×4, `MenuCommandTest` ×2), 0 failures; `shadowJar` builds.

**Judgment calls:**
- Siege tile: static `MENU_TEMPLATES.md` C.1 copy only. C.1's `$siegeServer.getEntryHintLine$` line,
  its `siege.open-own` action and its `knk.siege.play` permission need Siege 8b's root/action/node;
  referencing them now would get the whole hub blocked by startup validation. The tile opens
  `siege.overview` and appears once that menu validates. If Siege 8b wants C.1's extras, that is a
  CRUD-API edit of the seeded hub (create-only seeds) — flag for Siege 8b.
- `menu-available` only knows menus validated at startup; a template created through the CRUD API
  while the server runs stays hidden until the next restart validates it (same rule as opening it).
- Hub head tile: `SkullOwner = $player.getName$` as planned (E6 resolves an online player's profile).

**Question for the owner (not blocking, fail-closed):** the menu engine checks
`visibilityPermission`/`actionPermission`/`permission-node` with Bukkit's `Player.hasPermission`,
while the plugin's own commands (`/knk user`, `/kit`) use `KnkPermissible` (web-app groups/grants).
Nothing bridges the two, so a **non-op** staff member who holds `knk.admin.user.manage` only through
a KnK group will not see the Player manager tile (ops and Bukkit-level grants work). CP8 inherits
this for its `knk.admin.user.<property>` action permissions — the shared `UserAdminService` still
enforces the real check through `KnkPermissible`. Fixing it means routing the engine's permission
checks through `KnkPermissible` (a small engine change outside this plan's G1-only scope). Decide
whether to do that as a follow-up.

**Not verified:** nothing ran in-game; the hub seed was not applied to any database.

## 4. CP2 — Kits overview (`kits.overview`)

**Legacy source:** v2 `KitOverview` / `KitSelectItem` (catalogue §4.1). Fixes v2 bug B28 (paging
never worked) and `kits.md` bug #3 (menu claim skipped permission checks).

**Plugin:**
- Extract the claim flow from `KitCommand.handleGet` (`kitsCommandApi.claimAsync` → `KitGrantPlacer`
  resolve + place + result messages) and the purchase flow from `handlePurchase` into a shared
  `knk-paper/.../kit/KitGrantFlow` used by both the command and the menu.
- `KitsMenuFeature`:
  - Row source `kits.available` over `KitsQueryApi.getAvailableForUser(userId)` →
    `KitMenuRow` (`getKitId`, `getName`, `getLoreLines` [description wrapped, content summary,
    cost/cooldown/denial line], `getMaterial` [the hand item's blueprint material, else chestplate's,
    else `CHEST`], `getDisplayMode` [`DISABLED` when `!canClaim` and not purchasable],
    `getCooldownText`). Kit contents come from `KitsQueryApi.getById` (cache per render; don't fan
    out one call per row per tick — batch or cache by kit id).
  - Action `kits.claim {kitId}` → `KitGrantFlow.claim` (server-side `ClaimKitAsync` does all
    permission/cooldown/cost checks; show its denial text in chat and refresh the menu).
  - Action `kits.purchase {kitId}` → `KitGrantFlow.purchase`, always behind
    `menu.confirm.request` (it spends currency).
- **Template `kits.overview`** (Height 6): header 4 ARMOR_STAND "Kits" ("Click a kit to claim it"),
  8 back; content-grid section rows 1–4 with the `kits.available` row template (left-click action
  `kits.claim`, or `kits.purchase` via confirm when the row is a single-purchase premium kit —
  use two action bindings with `value-equals` Render conditions on `$row.getIsPurchase$`);
  pager on row 5 using `$section.getPage$/$section.getPageCount$`; empty state "No kits available
  right now". `AutoRefreshTicks` 20 so cooldown text counts down.

**Tests:** `KitGrantFlow` shared by command + menu (command behaviour unchanged — existing kit
command tests stay green); row mapping for each availability state; seed validation.

### CP2 status — shipped 2026-09-25 (not live-verified)

**Shipped:**
- knk-web-api `936ee16`: `kits.overview` seed (Height 6, AutoRefreshTicks 20). Header 4 ARMOR_STAND,
  8 Back; section `Kits` = content grid slots 9–44 over `kits.available`; pinned (absolute, J16) pager
  45/53 and Confirm 48 / Cancel 50. The row template carries two actions picked by action-level Render
  conditions on `$row.getIsPurchase$`: `kits.claim {kitId}` (false) and `menu.confirm.request
  {actionTypeId: kits.purchase, actionParamsJson: {kitId}, prompt: $row.getPurchasePrompt$}` (true).
  Cooldown line = `$row.getCooldownText$` with a `Ttl` 20 policy so it counts down.
- knk-plugin `0ea4158`: `kit/KitGrantFlow` — the single grant path (node check via `KnkPermissible`,
  claim/give/purchase API call, `KitGrantPlacer` resolve + place, feedback) used by `KitCommand`
  (now arg parsing + name lookup only) and by `menu/content/KitsMenuFeature`: row source
  `kits.available` → `KitMenuRow` (`getKitId`, `getName`, `getLoreLines`, `getMaterial`,
  `getDisplayMode`, `getCooldownText`, `getIsPurchase`, `getPurchasePrompt`; implements `MenuRowKey`),
  actions `kits.claim` / `kits.purchase`, condition `kits.purchase-pending`.

**Tests after CP2:** web-api **468/473** (same 5; +2: kits seed round-trip + `KitsOverview_…`).
Plugin knk-core 512, api-client 28, knk-paper **278** (+26: `KitMenuRowTest` 8, `KitsMenuFeatureTest`
7 incl. the seed contract, `KitGrantFlowTest` 7, `KitCommandTest` 4), 0 failures.

**Judgment calls:**
- **Caching / fan-out:** a render (every second under auto-refresh) must not hit the API per row. The
  viewer's availability list is cached in the feature for 5 s and dropped after their claim/purchase;
  kits (`KitsDataAccess.getByIdAsync`) and item blueprints / material refs go through the existing
  cache-first gateways, each id looked up once per fetch. The cooldown line is computed from
  `cooldownExpiresAt` at getter time, so it counts down between fetches.
- **Empty state:** the engine's built-in "No results found" marker only appears for an active
  search/filter, so `kits.available` returns one disabled BARRIER row "No kits available right now"
  instead. (Also used when the viewer's account isn't cached yet.)
- **Confirm/Cancel buttons use a feature condition, not `has-pending-confirmation`.** Finding: the
  engine keeps one pending confirmation per session and nothing clears it on navigation, so a
  confirmation requested in one menu (e.g. a Player-manager ban) and abandoned would show up — and
  could be accepted — behind the Confirm button of any other menu using the generic condition.
  `kits.purchase-pending` only allows a pending `kits.purchase`. CP8 does the same for `users.*`. An
  engine fix (clear the pending confirmation when a different menu opens) would be cleaner — owner
  decision, not built (not G1).
- **Kit name in chat** for menu actions comes from the viewer's cached availability (params carry only
  `kitId`, so no user text is spliced into the nested `actionParamsJson`).
- **Behaviour changes to `/kit`** (same grant semantics): a server denial (409 `ClaimDenied`/
  `PurchaseDenied`) now prints its `message` instead of `HTTP 409` + raw JSON; the user id is read from
  the stale user-cache entry like `KnkPermissible`/`ModeService` do — `KitCommand` used the fresh-only
  `getByUuid`, which (per `KnkPermissible`'s own note) stops resolving about a minute after join,
  i.e. "Your account isn't loaded yet" for every later `/kit get`. There were no pre-existing kit
  command tests; `KitCommandTest` now pins the delegation.

**Not verified:** in-game claim/purchase/cooldown/denial; Paper's rendering of the TTL line under
auto-refresh; whether the kit contents' material keys all resolve to real materials (unresolvable
ones fall back to PAPER with a one-time warning, E6).

## 5. CP3 — Profile & titles (`profile.main`)

**Legacy source:** v1 Title information (§3.3) + Personal Menu profile/Titles/Financial tiles (§3.1).

**knk-web-api:** read endpoint `GET /api/title-brackets` → ordered list (`id`, `maleName`,
`femaleName`, `minExperience`, `salary`, `coinBonus`, `gemBonus`, experience bonus if present) over
`TitleBracket`. Also expose the user's `gender` on the user read DTO the plugin already consumes if
it isn't there (needed to pick male/female title names). No migration.

**Plugin:** api-client `TitleBracketsQueryApi` + mapper + core port; cache (brackets rarely change).
`ProfileMenuFeature`:
- Root `profile` → `ProfileView` for the viewer from `UsersQueryApi.getByUuid` (coins, gems, XP,
  title name, prestige XP, premium tier name/expiry, next bracket name, XP to next bracket, "highest
  title reached" flag).
- Row source `titles.brackets` → `TitleRow` (`getName` by viewer gender, `getMinExperience`,
  `getSalary`, bonus lines, `getDisplayMode` = `HIGHLIGHT` for the viewer's current bracket,
  `NORMAL` for reached, `DISABLED` for not yet reached).

**Template `profile.main`** (Height 6): 0 viewer head (name, title, premium tier), 1 GOLD_INGOT
balances (coins, gems, XP; prestige XP when > 0), 2 IRON_HELMET title progress ("Next: X — N XP to
go" or "Highest title reached"), 8 back; rows 2–5 content-grid of `titles.brackets` (19 brackets fit
without paging but keep the pager for safety).

**Tests:** endpoint + DTO tests; `ProfileView`/`TitleRow` mapping (current/reached/not-reached, both
genders, highest bracket); seed validation.

### CP3 status — shipped 2026-09-25 (not live-verified)

**Shipped:**
- knk-web-api `f541ab6`: `Controllers/TitleBracketsController` — `GET /api/title-brackets` → ordered
  `TitleBracketDto` list (`id`, `maleName`, `femaleName`, `minExperience`, `salary`, `coinBonus`,
  `gemBonus`, `expBonus`) over `ITitleService.GetAllOrderedAsync`; `UserSummaryDto.Gender`
  (`"Male"`/`"Female"`/null) set by `GET /api/users/uuid/{uuid}` and `/username/{name}` and by the
  `User → UserSummaryDto` map. No migration, no model change. `profile.main` seed (Height 6): 0 head
  (title line, premium line), 1 GOLD_INGOT balances (coins, gems, XP, prestige when > 0), 2 IRON_HELMET
  progress ("Next: X - N XP to go" / "Highest title reached"), 4 BOOK title count, 8 Back; `Titles`
  grid 18–53 over `titles.brackets` with pager 45/53.
- knk-plugin `b4e7592`: knk-core `TitleBracket` (+ `nameFor(gender)`), port `TitleBracketsQueryApi`,
  `dataaccess/TitleBracketsDataAccess` (whole list cached 10 min, completed future while fresh, one
  shared in-flight request, stale list on failure — CP8 reuses it); `UserSummary.gender` (new last
  component; a telescoping constructor keeps every existing call site unchanged); api-client
  `TitleBracketsQueryApiImpl`/DTO/mapper, `UserSummaryDto.gender`; knk-paper
  `menu/content/ProfileMenuFeature` (root `profile` → `ProfileView`, row source `titles.brackets` →
  `TitleRow`, helper `TitleProgress`).

**Tests after CP3:** web-api **475/480** (same 5; +7: `TitleBracketsControllerTests` ×4,
`UsersControllerTests.GetUserSummaryByUuid_IncludesGender`, profile seed ×2). Plugin knk-core **515**
(+3), api-client **30** (+2), knk-paper **287** (+9), 0 failures.

**Judgment calls:**
- **Fresh read without blocking.** Providers run on the main thread and can't wait for HTTP, so the
  `titles.brackets` fetch (async, runs before bindings resolve — engine Phase 9 §9.0) also does the
  `UsersQueryApi.getByUuid` read and remembers it per viewer (LRU, 256 viewers); the `profile` root
  reads that, falling back to the cached user (stale entry) — never I/O. If the fresh read fails, the
  rows use the cached user too.
- **Current bracket** = the server's `titleBracketId` when it is in the list, else the highest bracket
  with `minExperience <= XP`. Gendered names follow the web-api rule (`Female` → female name, anything
  else incl. unset → male). Rows show the other-gender name as "Also known as …" (v1 showed both).
- **Route** is `api/title-brackets` as the plan says (kebab routes already exist: `api/audit-log`,
  `api/field-validation-rules`), not `api/[controller]`.

**Not verified:** in-game rendering/HIGHLIGHT glow; the live endpoint against the seeded
`title_brackets` data (only unit-tested with mocks); gender values in the dev DB.

## 6. CP4 — Item catalogue (`items.catalog`)

**Legacy source:** v1 List of items (§3.11).

Engine-only: reuse the existing `catalog.itemblueprints` content source and the engine Phase 5 search/filter
presets. Start from the `example.catalog` seed (`MenuTemplateSeed.cs`), give it the real key
`items.catalog`, a DIAMOND_SWORD header ("A list of all items in the game", total count), search
button, whichever filter facets the source actually supports (check `MenuContentSourceHandlers`
before adding any; the engine Phase 5 notes flag Category/Grade/Tag facets as blocked), pager, back.
Read-only — no click action on rows.

**Tests:** seed round-trip; validation.

### CP4 status — shipped 2026-09-25 (not live-verified)

**Shipped:**
- knk-web-api `480a80c`: `items.catalog` seed (Height 6), modelled on `example.catalog`: header 4
  DIAMOND_SWORD "Item catalogue" ("A list of all items in the game" + `$itemsCatalog.getTotalLine$`),
  8 Back; `Items` grid 9–44, `Searchable`, `catalog.itemblueprints`; pinned pager 45/53 and a search
  button 49 (`menu.search.prompt`; shift-click clears — engine behaviour). No row actions.
- knk-plugin `887fbbd`: `menu/content/ItemsCatalogMenuFeature` — root `itemsCatalog`
  (`ItemsCatalogView.getTotalLine/getTotalCount`).

**Tests after CP4:** web-api **477/482** (same 5; +2). Plugin knk-core 515, api-client 30, knk-paper
**289** (+2), 0 failures.

**Judgment calls:**
- **No filter facets.** `catalog.itemblueprints` forwards the section's filter values as
  `PagedQuery.filters`, but `ItemBlueprintRepository.SearchAsync` only applies the search term (it
  loads Category/Grade/Tags but never filters on them), so any filter button would silently do
  nothing. Adding Category/Grade/Tag filtering server-side is an Items task, not this plan's.
- **Total count needed a feature root** (the plan's "ItemsCatalogMenuFeature if needed"): the engine
  has no `$section$` total. The count is fetched in the background (a one-row page's `totalCount`) at
  enable and refreshed when older than 60 s on read; the line is omitted until the first answer.

**Not verified:** in-game search (anvil prompt) and paging over the real 18+ blueprints; material
resolution of catalogue icons.

## 7. CP5 — Premium tiers (`premium.tiers`)

**Legacy source:** v1 Donator-ranks information (§3.4) — **not** its 2017 content; built from today's
v3 data. Perk redesign (vision §5.3) later changes the data, not this screen.

**knk-web-api / api-client:** the plugin's `PermissionGroupSummary` has only id/name/weight/
isPremiumTier. Extend the list DTO + mapper with `salaryMultiplier` and a description if the model has
one (add nothing to the model). No migration.

**Plugin:** `PremiumMenuFeature`, row source `premium.tiers` → premium groups ordered by weight →
`PremiumTierRow` (`getName`, `getSalaryMultiplierText`, description lines, `getDisplayMode` =
`HIGHLIGHT` for the viewer's current tier). Root `premium` → viewer's tier name + expiry
(from `UserSummary.premiumTierName/premiumTierExpiresAt`).

**Template `premium.tiers`** (Height 3–4): header 4 GOLD_BLOCK ("Your tier: X, expires …" or "No
premium tier"), 8 back, row of tiers. Read-only.

## 8. CP6 — Engine G1: per-session menu state (steppers)

**Why:** the Player manager's +/value/− fields with a cyclable step (catalogue §2.2 G1).

**knk-core / knk-paper (generic, no feature code):**
- `MenuSession` gains a string→string state map, cleared with the session (on quit and when the
  session ends). Keys are namespaced by the template author (e.g. `pm.coinStep`).
- New reserved engine root **`state`** → `MenuStateView`, key lookup like `ctx` (E1): `$state.pm.coinStep$`
  → the value or `""`. Add `state` to `ENGINE_ROOTS` and teach the validator that hops after `state`
  are `String` key lookups.
- Actions **`menu.state.set {key, value}`** and **`menu.state.cycle {key, values}`** (comma list;
  unset → first value; wraps). Both mark the session dirty and re-render.
- Initial values: `menu.open` accepts `state.<key>` params the same way it accepts `ctx.<key>`
  (E1) and sets each key **only if unset**, so a template can declare its default step when it is
  opened.
- Feature actions read the step through normal param interpolation (`{"delta": "$state.pm.coinStep$"}`).

**Tests:** state set/cycle/wrap/unset, defaults via `menu.open`, cleared on quit, validator accepts
`$state.x$` and rejects nothing it shouldn't, interpolation into feature params.

## 9. CP7 — Actor attribution for plugin-originated staff actions

**Why:** the plugin authenticates with `X-API-Key`, so `GetUserIdFromClaims` finds no `uid` and every
in-game staff change is audit-logged with a null actor (`UsersController.cs`, `AuditLogService`).

**knk-web-api:**
- A single helper (e.g. `ActorResolver.ResolveActorUserId(HttpContext)`) replacing the controllers'
  `GetUserIdFromClaims(User)` calls on audited endpoints: JWT caller → `uid` claim (unchanged);
  **API-key caller only** → optional `X-Acting-User-Id` header, validated as an existing user id,
  else null. The header is ignored for JWT callers (a web user can't impersonate).
- Apply it to every audited mutation the plugin can reach: balances, group membership add/remove,
  permission grant/revoke, active mode, freeze/unfreeze, salary payout.

**Plugin / api-client:** a way to pass the acting user on `UsersCommandApi` calls (per-call overload
or a scoped `withActor(userId)` wrapper — pick one, document it) that sets the header. Use it in
`UserManagementCommand` (`/knk user`) — the acting player's user id — and in CP8.

**Tests:** header honoured for API-key auth, ignored for JWT, unknown id → null actor, audit row shows
the actor; api-client sends the header; `/knk user` passes it.

## 10. CP8 — Player manager (`users.manager*`)

**Legacy source:** v1 Online-players Manager + Edit statistics (§3.14). Kills, deaths, skill points,
salary-timer resets and v1 donator titles have no v3 equivalent and are dropped; premium tiers are
handled as group memberships.

**Plugin:**
- Extract the logic of `UserManagementCommand` (target resolution, `RankHierarchy.actorOutranks`,
  per-property `knk.admin.user.<property>` checks, balance "set" = computed delta, group/perm
  add/remove, `ModeService.refreshVisibilityFor` after grant changes, result messages) into a shared
  `knk-paper/.../user/UserAdminService`; the command becomes a thin caller. Every call passes the
  actor (CP7).
- `UserManagerMenuFeature`:
  - Row source `users.online` → online players the viewer may manage (`OnlinePlayerRow`: name, head,
    title, coins, gems, XP, premium tier, active mode, frozen flag).
  - Root `target` → `TargetUserView` for `$ctx.userId$` (fresh `UsersQueryApi` read, cached per
    render).
  - Click condition `users.outranks-target {userId}` (wraps `RankHierarchy`), used on every edit
    action; deny message "You can only manage players ranked below you".
  - Actions (each gated by its `knk.admin.user.<property>` node as `actionPermission`):
    `users.adjust {userId, field: coins|gems|xp, delta}` (delta = `$state.…$` or its negation),
    `users.set-title {userId, bracketId}` (XP delta to the bracket's `minExperience`),
    `users.group {userId, groupId, op: add|remove}`, `users.mode {userId, mode}`,
    `users.salary-payout {userId}`, `users.freeze {userId, op}`,
    `users.kick {userId}` / `users.ban {userId}` → the clicking player runs Paper's `/kick <name>
    <reason>` / `/ban <name> <reason>` (fixed reasons, as v1; vanilla command permissions decide),
    always behind `menu.confirm.request`.
- New permission node `knk.admin.user.manage` for opening the manager (hub tile + template).

**Templates:**
- `users.manager` (Height 6): header 4 "Online players" (count), 8 back; content-grid of
  `users.online` rows → `menu.open {key: users.manager.edit, ctx.userId: $row.getUserId$,
  state.pm.coinStep: 100, state.pm.gemStep: 10, state.pm.xpStep: 100}`.
- `users.manager.edit` (Height 6): 0 target head + summary; 8 back; stepper rows for coins, gems,
  XP: `−` (`users.adjust` with the negated step), value item showing the amount and "Step: N — click
  to change" (`menu.state.cycle` over e.g. coins `1,10,100,1000,10000`, gems `1,10,100,1000`, XP
  `10,100,1000,10000`), `+`; a "Title" item → `users.manager.titles`; "Groups" →
  `users.manager.groups`; mode toggle; salary payout; freeze/unfreeze; kick; ban.
- `users.manager.titles` (Height 3–4): title brackets as rows → `users.set-title` (confirm).
- `users.manager.groups` (Height 6): all permission groups as rows, member ones `HIGHLIGHT`; click →
  add/remove (confirm on remove).

**Tests:** `UserAdminService` shared by command + menu (existing command tests green); outranks
condition; each action's permission gate; step interpolation incl. negation; kick/ban dispatch runs as
the viewer; seed validation.

## 11. Wrap-up — docs and hand-off

- This file: every CP phase's status block.
- `docs/specs/legacy/inventory-menu-screens.md` §1/§7: mark #1, #3–#7 ported; G1 built.
- `docs/specs/inventory-menu/IMPLEMENTATION_PLAN.md`: note G1 (`state` root, `menu.state.*`,
  `menu-available`) as engine additions made by this plan.
- `docs/specs/user-features/COMMAND_CATALOG_V3.md` and `docs/guides/users/commands.md`: `/menu`.
- `docs/specs/user-management/`: note in-game Player manager + actor attribution.
- `docs/ACTIVE_SESSIONS.md`: move the row to Recently completed.
- **Manual in-game checklist for the owner** (the session has no server or database): engine Phase 9's own
  `example.domain` checklist first (IMPLEMENTATION_PLAN.md "Verification"), then per screen: `/menu`
  shows only the tiles whose menus exist; Kits claim/purchase/cooldown/denial; Profile highlights the
  current title and shows correct gendered names; catalogue search/paging; premium tier highlight;
  Player manager: rank-hierarchy denial, each stepper and step cycle, title/group/mode/salary/freeze,
  kick/ban confirmations, and the audit log in the web-app showing the staff member as actor.

## 12. What the session must not do

- Don't apply migrations or seeds to any real database (none is reachable, and the shared dev DB
  needs the owner's go-ahead each time). New migrations: none are expected; if one becomes necessary,
  generate it and say so in the status block.
- Don't merge to `master`/`main`, don't touch `claude/siege-minigame`, don't edit Siege templates.
- Don't port anything the catalogue marks shelved/deferred, and don't build G2–G7.
- Stop and record a question in the CP status instead of guessing when a decision here turns out
  to be impossible or contradicts the code.
