# InventoryMenu — Content Port Plan (hub, Kits, Profile, Items, Premium, Player manager)

**Status:** CP1–CP6 and CP8 implemented on `claude/menu-content` (not merged, not live-verified); CP7's
plugin half shipped, its server half **stopped on an owner question** (see CP7 status). Wrap-up done.
Owner follow-up notes (2026-09-26) implemented, see "Follow-up 2026-09-26" before §12. on `claude/menu-content` (see the CPn status blocks). Phases are numbered CP1–CP8 (content port) to keep them apart from the engine plan's Phases 1–9, which this document cites as "engine Phase N".
**Last updated:** 2026-09-26

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

**Permission model note (resolved in CP8, no action needed):** the menu engine checks
`visibilityPermission`/`actionPermission`/`permission-node` with Bukkit's `Player.hasPermission`
(ops, plugin.yml defaults), not `KnkPermissible` (web-app groups/grants). That matches `/knk user`
itself, whose `knk.admin.user.*` checks are plain Bukkit nodes too (its own javadoc says so), so the
Player manager's tile and actions behave exactly like the command. Features whose commands use
`KnkPermissible` (`/kit`) keep that check inside their shared code path (`KitGrantFlow`), not in
template permissions. If the owner ever wants web-app group grants to drive menu visibility, the
engine's permission checks would need to go through `KnkPermissible` — a separate decision.

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

### CP5 status — shipped 2026-09-25 (not live-verified)

**Shipped:**
- knk-web-api `a112a4d`: `premium.tiers` seed (Height 3): header 4 GOLD_BLOCK with
  `$premium.getTierLine$`, 8 Back; `Tiers` grid 9–17 over `premium.tiers` (pager 18/26). Read-only.
  **No DTO/mapper change:** the plugin reads `GET /api/PermissionGroups`, which returns the full
  `PermissionGroupDto` — `salaryMultiplier` is already on it (and on `PermissionGroupListDto`), and
  `PermissionGroup` has no description to add.
- knk-plugin `79d5560`: `PermissionGroupSummary.salaryMultiplier` (+ `PermissionGroupListItemDto`;
  the old 4-arg constructor stays, defaulting to 1.0); knk-core `dataaccess/CachedList` (the TTL-list
  logic from CP3, now shared) backing `TitleBracketsDataAccess` and new `PermissionGroupsDataAccess`
  (2 min); knk-paper `PremiumMenuFeature` (row source `premium.tiers` → `PremiumTierRow`: premium
  groups by weight, `getName`, `getSalaryMultiplierText`, `getLoreLines`, `getMaterial`,
  `getDisplayMode` = HIGHLIGHT for the viewer's tier; root `premium` → `PremiumView`) and
  `FreshViewers` (the CP3 fresh-viewer read, now shared by Profile and Premium).

**Tests after CP5:** web-api **479/484** (same 5; +2). Plugin knk-core 515, api-client **31** (+1),
knk-paper **293** (+4), 0 failures.

**Judgment calls:**
- Tier icons reuse v1's tier blocks by rank among premium tiers (IRON, GOLD, DIAMOND, REDSTONE, then
  EMERALD, NETHERITE) — purely cosmetic, no data behind it.
- "Description lines" = the salary multiplier plus, on the viewer's own tier, "Your current tier" and
  its expiry ("Until yyyy-MM-dd" UTC, or "Permanent"). Nothing about perks/prices is invented; v1's
  "benefits of lower ranks are included" copy was left out because v3 group inheritance isn't verified
  to work that way for premium tiers.

**Not verified:** in-game rendering; which groups are flagged `IsPremiumTier` in the dev DB.

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

### CP6 status — shipped 2026-09-25 (not live-verified)

**Shipped (knk-plugin `a119941`; no web-api change):**
- knk-core `MenuSession`: state map with `getState`, `setState` (null unsets), `setStateIfAbsent`,
  `cycleState(key, values)`, `stateSnapshot`.
- knk-core `MenuStateView` + reserved engine root **`state`** (`MenuVariableProviderRegistry.ROOT_STATE`,
  in `ENGINE_ROOTS` and the declared engine types). `VariableResolver`: on a `MenuStateView` every
  remaining hop is joined into one dotted key (`$state.pm.coinStep$` → key `pm.coinStep`), `""` when
  unset. `MenuDefinitionValidator`: hops after `state` are a `String` key lookup (nothing after it is
  checked); `state` is always declared.
- knk-paper: `state` is put into the render scope (`MenuRenderer`) and the click scope
  (`MenuClickListener`), so it works in bindings and in interpolated action/condition/content-source
  params (`{"delta": "-$state.pm.coinStep$"}` → `"-100"`). Actions `menu.state.set {key, value}`
  (empty value unsets) and `menu.state.cycle {key, values}` (comma list, trimmed; unset or unknown →
  first value; wraps) — both mark the session dirty and repaint via `refreshOpenMenu`. `menu.open`
  applies every `state.<key>` param with `setStateIfAbsent` before opening.

**Tests after CP6:** knk-core **523** (+8 `MenuStateG1Test`), api-client 31, knk-paper **297**
(+4 `MenuStateActionsTest`), 0 failures. web-api unchanged (479/484).

**Judgment calls:**
- **Lifetime.** The plan says "cleared with the session (on quit and when the session ends)". A
  `MenuSession` lives from first menu until quit (closing the inventory keeps it), so "session ends"
  is taken as: the session is discarded on quit **and** its state is cleared by `openAsRoot` — i.e.
  every `/menu` (or any command-opened menu) starts with fresh state, while navigating inside menus
  and Back keep it (a staff member's chosen step survives moving between players' edit screens).
- **Dotted keys.** The placeholder grammar splits on `.`, so a namespaced key can't be a single hop;
  the resolver/validator treat everything after `state` as the key (rather than `ctx`'s single-hop
  rule).

**Not verified:** in-game repaint timing after a state change (next tick, via `refreshOpenMenus`).

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

### CP7 status — STOPPED on the server half (question for the owner); plugin half shipped

**Why it stopped.** The plan's premise — "the plugin authenticates with `X-API-Key`" and the rule
"**API-key caller only** → honour `X-Acting-User-Id`" — doesn't match the code:
- knk-web-api has **no API-key authentication**. `Program.cs` registers only the JWT bearer scheme;
  nothing anywhere reads `X-API-Key` (searched `*.cs`/`*.json`). The audited mutations the plugin calls
  carry no `[Authorize]` (`UsersController` balances/active-mode/freeze/unfreeze/payout,
  `UserPermissionGroupsController` upsert/delete, `PermissionGrantsController` by-node upsert/revoke),
  so the plugin's calls are simply **anonymous** requests; the actor is `GetUserIdFromClaims(User)` /
  `User.GetUserId()` → null.
- knk-plugin's `config.yml` ships `auth.type: none`; `apikey` only adds a header the API ignores.

So there is no "API-key caller" to recognise. Implementing the plan literally would mean honouring
`X-Acting-User-Id` for **any unauthenticated caller**, i.e. anyone who can reach the API could write
audit rows in any user's name — the opposite of what attribution is for. Picking an auth scheme for the
plugin is an owner decision, so nothing was built server-side.

**Options (owner decides):**
1. **Add real API-key auth for the plugin** (recommended): an `ApiKey` authentication scheme validating
   `X-API-Key` against a secret in config (e.g. `Security:PluginApiKey`), giving the plugin a principal
   with a `client=plugin` claim; `ActorResolver` then honours `X-Acting-User-Id` only for that principal
   (JWT callers keep `uid`, anonymous callers get null). Needs the key set in the plugin's
   `config.yml` (`auth.type: apikey`). Doesn't by itself lock the other endpoints — that is a separate
   hardening step.
2. **Trust the header from any non-JWT caller** until auth exists — cheap, matches today's "everything
   is anonymous" reality, but the audit actor becomes forgeable by anyone on the network.
3. **Plugin uses a JWT** (service account) and the API gets a "may act for" claim — bigger change.

**Shipped anyway (knk-plugin `916a43e`) — independent of that answer:**
- `UsersCommandApi.withActor(int actorUserId)` (the plan's "scoped `withActor` wrapper" choice): returns
  an instance that sends `X-Acting-User-Id: <id>` on every request (`UsersCommandApiImpl.newRequest`
  override); the plain instance is unchanged. Chosen over a per-call overload because it keeps the 14
  port methods' signatures and lets a caller make one actor-bound instance per action.
- `/knk user` (`UserManagementCommand`): group/perm changes use the actor resolved by the existing rank
  check; balance changes resolve the sender's user id (cache-first `UsersDataAccess.getByUuidAsync`);
  console and unresolvable accounts use the plain API (never blocks the action).
- Until the server honours the header, audit rows keep a null actor — no behaviour change.

**Tests:** api-client **32** (+1 `UsersCommandApiActorTest`: header on every call of the actor instance,
absent on the plain one); knk-paper **299** (+2 `UserManagementCommandActorTest`); knk-core 523
(stub updated). web-api unchanged (479/484) — none of the plan's server tests exist yet.

**Also noted for the server half:** `POST /api/Users/{id}/salary/payout` → `SalaryService.PayOutAsync(id)`
takes no actor at all, so salary payouts need an actor parameter as well, not just the resolver swap.

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

### CP8 status — shipped 2026-09-25 (not live-verified; audit actor pending CP7's server half)

**Shipped:**
- knk-web-api `058dec5`: seeds `users.manager`, `users.manager.edit`, `users.manager.titles`,
  `users.manager.groups` — every section `VisibilityPermission knk.admin.user.manage` (the engine
  skips such a section entirely for a viewer without it).
  - `users.manager` (H6): header (online count via `usersManager`), grid 9–44 over `users.online`
    (row = head via `SkullOwner $row.getUuid$`, title/balances/tier/mode/frozen lore) → `menu.open
    {users.manager.edit, ctx.userId, ctx.name, state.pm.coinStep 100, gemStep 10, xpStep 100}`;
    pager 45/53.
  - `users.manager.edit` (H6): slot 0 = the target head (1×1 section over `users.target`, which also
    loads the target fresh + the viewer's rank over them); 8 Back; steppers coins 10/11/12, gems
    19/20/21, XP 28/29/30 (`−`/`+` = `users.adjust` with `delta` `-$state.pm.*Step$` / `$state.pm.*Step$`,
    `ActionPermission knk.admin.user.<field>`; the value item shows `$target.get…$` + "Step: N" and
    `menu.state.cycle`s coins `1,10,100,1000,10000`, gems `1,10,100,1000`, XP `10,100,1000,10000`);
    14 Title → `users.manager.titles`, 15 Groups → `users.manager.groups`, 16 mode toggle
    (`users.mode` to `$target.getNextMode$`), 23 salary payout, 24 freeze/unfreeze (one slot, two
    actions picked by Render `value-equals $target.getIsFrozen$`, Click `permission-node
    knk.freeze`/`knk.unfreeze`), 32 kick / 33 ban (`menu.confirm.request` → `users.kick`/`users.ban`),
    Confirm 48 / Cancel 50 (`users.pending`). Every mutating item has the Click condition
    `users.outranks-target {userId}`.
  - `users.manager.titles` (H4): brackets as seen by the target (`users.titles`), confirmed
    `users.set-title {userId, bracketId}`; pager 27/35, confirm 30/32.
  - `users.manager.groups` (H6): every group (`users.groups`), members HIGHLIGHT; `users.group add`
    directly, `remove` via confirmation.
    **Updated 2026-09-26 (KNG-7/KNG-8):** ranks (Default + premium tiers) are one per player - a rank
    click asks for confirmation and switches (`users.group` op `set-rank`, `UserAdminService.setRank`),
    removing a premium rank drops back to Default, Default can only be replaced. Other groups unchanged.
    Confirm/Cancel now repaint live (`menu.confirm.*` handlers). See
    [`../user-features/RANK_DISPLAY.md`](../user-features/RANK_DISPLAY.md) §6.
- knk-plugin `07a765f`: `user/UserAdminService` — extracted from `UserManagementCommand` (target
  resolution, `RankHierarchy.actorOutranks`, per-property `knk.admin.user.<property>`, balance "set" =
  computed delta, group/perm add/remove, `ModeService.refreshVisibilityFor`, result messages) and
  `FreezeCommand`; both commands are now thin callers (their messages are unchanged). Added for the
  menu: `adjustBalance` (signed step), `setTitle` (XP delta to the bracket minimum), `setMode`,
  `payOutSalary`, `kick`/`ban` (`staff.performCommand("kick <name> <reason>")` — runs as the staff
  member, vanilla permissions decide). Every mutation goes through `UsersCommandApi.withActor`
  (CP7 plugin half). `menu/content/UserManagerMenuFeature` (+ `TargetUserView`, `OnlinePlayerRow`,
  `GroupRow`, `TitleRow.getPickerDisplayMode`). `ModeService.persist(player, mode, api)` overload.
  New nodes `knk.admin.user.mode`, `knk.admin.user.salary` (children of `knk.admin`, default false).

**Tests after CP8:** web-api **486/491** (same 5; +7: four seed round-trips + three `UserManager…`
seed tests). Plugin knk-core 523, api-client 32, knk-paper **326** (+27: `UserAdminServiceTest` 12,
`UserManagementCommandTest` 4 — `/knk user` + `/freeze` delegate to the service, `UserManagerMenuFeatureTest`
13 incl. outranks condition, per-action permission gate, step interpolation incl. negation, kick/ban as
the viewer, and the seed contract for all four menus; the CP7 command-actor test moved into the
service test), 0 failures; `shadowJar` builds.

**Judgment calls:**
- **Freeze, mode, salary** were not part of `/knk user`. Freeze reuses `/freeze`'s logic (now in the
  service, so `/freeze` and the menu share it; the menu freezes with the fixed reason "Frozen by a
  member of staff"). Mode and salary are new staff abilities with new nodes; the mode toggle only
  switches NONE ↔ STAFF (OWNER → NONE) and refuses a mode the target doesn't hold the node for (they'd
  be vanished with no way to toggle it off); owner mode stays self-service (`/ownermode`).
- **Rank check** (`users.outranks-target`): conditions run on the main thread, so the answer is
  computed by the `users.target`/`titles`/`groups` fetch and cached per (viewer, target); before the
  first fetch the condition denies with "Still checking your rank". The service re-checks the rank
  itself for group/perm/freeze/mode/salary (as the commands did); balance/title steps rely on
  the menu condition, because `/knk user coins|gems|xp` never had a rank check and its behaviour was
  kept.
- **Target identity** travels as `ctx.userId` + `ctx.name`; the target is read fresh by name (like
  `/knk user`) and the id must match, so a renamed/other account never gets edited.
- **Online list** = online players with a cached knk account whom the viewer outranks (self excluded);
  one disabled row when there is nobody.
- **Confirmations** use `users.pending` (pending action type `users.*`) for the same reason as Kits'
  `kits.purchase-pending` (see CP2).
- Kick/ban reasons are fixed: "You were kicked/banned by a member of staff." (v1's exact wording wasn't
  available in this session).

**Not verified:** anything in-game; that Paper's `/kick`/`/ban` accept `performCommand` from a
player with the vanilla permission; audit rows showing the staff member (blocked on CP7's server
half — until then the actor is still null).

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

### Wrap-up status — 2026-09-25

**Branches (pushed, not merged):** knk-web-api `claude/menu-content` @ `058dec5`, knk-plugin
`claude/menu-content` @ `07a765f` (both = trunk + `origin/claude/inventorymenus` + this plan).
knk-web-app: untouched (no change was needed). knk-workspace docs on `claude/admiring-cray-qk9fey`.

**Final test numbers:** web-api `dotnet build` clean, `dotnet test` **486/491** — the same 5
pre-existing failures as `master`, +23 new tests. Plugin `./gradlew test shadowJar`: knk-core **523**
(+11), knk-api-client **32** (+4), knk-paper **326** (+80, 14 skipped as before), 0 failures (built
against a partial paper-api compiled from source — see CP1's environment note).

**Docs updated:** this file (CP1–CP8 status blocks); `docs/specs/legacy/inventory-menu-screens.md`
§1/§2.2/§7 (ports #1, #3–#7 and G1 marked implemented); `IMPLEMENTATION_PLAN.md` ("Engine additions
made by the content port"); `docs/specs/user-features/COMMAND_CATALOG_V3.md` (`/menu`);
`docs/guides/users/commands.md` (a v3 pointer only — that page is the stale v1 reference);
`docs/specs/user-management/DESIGN.md` §8 (in-game Player manager, actor attribution state);
`docs/ACTIVE_SESSIONS.md`.

**Open items for the owner:**
1. **CP7 server half** — how the plugin should authenticate so the API can trust
   `X-Acting-User-Id` (options in the CP7 status). Until then staff changes made in-game are still
   audit-logged with a null actor.
2. Optional engine follow-ups found on the way (not built, not required): clear a pending
   confirmation when a different menu opens (CP2); route engine permission checks through
   `KnkPermissible` if web-app group grants should drive menu visibility (CP1 note).
3. Siege 8b: the hub's Sieges tile is static C.1 copy; add `siege.open-own` / the "you are in Siege N"
   line by editing the seeded hub through the CRUD API if wanted (CP1).

**Manual in-game checklist (owner; this session had no server or database).** Deploy the plugin
branch (a real `./gradlew :knk-paper:dev` build — not the jar built here) and run the web-api branch.
Starting the API runs the create-only seeds, so the ten content templates (`main`, `kits.overview`,
`profile.main`, `items.catalog`, `premium.tiers`, `users.manager*`) are created in whatever database it
points at — needs the owner's go-ahead for the shared dev DB, together with engine Phase 9's migration
(`dotnet ef database update`). No new migration was added by this plan.
1. Engine Phase 9's own `example.domain` checklist first (IMPLEMENTATION_PLAN.md "Verification").
   Startup log: `InventoryMenu startup validation: checked N menu(s), 0 blocked` — none of the ten
   content menus may be blocked.
2. **`/menu`** as a non-op: Back reads "Exit"; tiles for Profile (own head), Kits, Item catalogue,
   Premium tiers; **no** Sieges tile (no `siege.overview`) and **no** Player-manager tile. As an op:
   the Player-manager tile at slot 22 appears. Every tile opens its menu and Back returns to the hub.
3. **Kits:** claimable kit → click claims, items placed, "Kit … claimed" message, the row turns
   DISABLED with "Available again in …" counting down each second; clicking a kit on cooldown does
   nothing (DISABLED); a kit the player lacks the node/title for shows the server's denial text in
   lore and chat is not spammed; a single-purchase premium kit → click → chat prompt + Confirm/Cancel
   appear (row 5) → Confirm buys it (gems taken), the row becomes claimable; Cancel says "Cancelled.";
   more than 36 kits page with 45/53; `/kit get <name>` still works and now shows denial messages as
   text; `/kit get` more than a minute after joining no longer says "account isn't loaded".
4. **Profile:** balances/XP match `/knk user <self> info`; title progress "Next: … - N XP to go" (or
   "Highest title reached"); the current title glows (HIGHLIGHT), passed ones normal, future ones
   greyed; a female account sees female title names; premium line shows tier + expiry.
5. **Item catalogue:** header count matches the number of item blueprints (appears after the first
   open at the latest); search via the sign (anvil prompt), shift-click clears; paging 45/53.
6. **Premium tiers:** only premium groups, ordered by weight, with salary multiplier; the viewer's
   tier glows and shows "Until …"/"Permanent"; header "Your tier: …" or "No premium tier".
7. **Player manager** (two accounts, staff outranking a normal player; a third of equal/higher rank):
   the online list only shows players you outrank; editor head shows title/balances/tier/mode;
   `−`/`+` change coins/gems/XP by the step; clicking the value cycles the step (and it survives Back
   → another player's editor, but resets after a fresh `/menu`); XP past a threshold shows the
   promotion effect to the target; Title picker → Confirm sets the title (XP = bracket minimum);
   Groups: highlighted memberships, click adds, removing asks for confirmation; Mode toggle
   Normal↔Staff (refused if the target lacks `knk.mode.staff`); Salary payout message; Freeze/Unfreeze
   toggle (and `/freeze`/`/unfreeze` still work); Kick and Ban ask for confirmation, then run Paper's
   `/kick`/`/ban` as you (denied if you lack the vanilla permission); a non-op without the nodes sees
   no Player-manager tile and gets permission messages for each action; acting on the equal/higher
   account is refused ("You can only manage players ranked below you").
8. **Audit log in the web-app:** after 7, entries exist for the changes — **the actor column will still
   be empty** until CP7's server half is decided and built; verify again then.

## Follow-up 2026-09-26 — owner notes on the menus

**Branches (pushed, not merged):** knk-web-api `claude/menu-content` @ `f7d0d09`, knk-plugin
`claude/menu-content` @ `78583c7`.

| # | Owner note | What was built |
|---|---|---|
| 1 | Menus shrink when there is little content (v2 minheight) | New `MenuTemplate.MinHeight` and `MenuSectionTemplate.MinHeight` (DTOs, validation: menu 1..Height, section 0..Height). `Growth = Dynamic` is implemented for the first time. After a render, `MenuRowCompactor` (knk-core) removes empty rows, bottom-most first, down to the menu's MinHeight, keeping a section's first MinHeight rows; rows below a removed one move up and the inventory is re-created at the new size. Static menus never change. The list menus (kits, profile, catalogue, premium, player manager, title and group pickers) are Dynamic. Confirm and Cancel moved into the header row (slots 2 and 6), so showing them never resizes a menu. The hub and the editor stay Static. |
| 2 | Default background on every menu | New `MenuTemplate.BackgroundMaterial` (a material name) next to the existing `BackgroundMaterialRefId`; the RefId wins. Empty slots are filled with that material, or `GRAY_STAINED_GLASS_PANE` when none is set (was `LIGHT_GRAY_STAINED_GLASS_PANE` until the 2026-09-26 siege smoke test). The filler has no name, no lore and no actions; it uses `setHideTooltip` (verified in game 2026-09-26, op and non-op). |
| 3 | Hide pagers on a single page | Pinned items whose actions are only `menu.page.next` or `menu.page.prev` are not drawn while the section has at most one page. |
| 4 | Quick stats on the head; clearer title ladder | New `$profile.getQuickStatsLines$` on the hub's centre head and on the profile head: title, "Title rank n/N", next title and XP needed, a progress bar, coins, gems, XP, prestige and premium tier. Title rows now show their state at a glance: lime pane with ✔ for reached, a glowing golden helmet with » « for the current title, a gray pane for titles ahead. Each row's stack Amount is its position on the ladder, and the lore adds "Title n of N". The progress item gets the rank line and the bar. |
| 5 | Catalogue shows items as granted; category filter | New plugin row source `items.catalog`, which replaces the engine's `catalog.itemblueprints` in this menu. Each blueprint is read in full by id and rendered with `ItemBlueprintBukkitMapper.fromBlueprint`, the same code a kit grant or `/knk itemblueprints give` uses; the template's lore lines are appended. The row template (PAPER + name) is only a fallback. New Category filter: `menu.filter.cycle` over `$itemsCatalog.getCategoryValues$`, a live list from `GET /api/Categories`, plus a clear button. The API's `ItemBlueprintRepository.SearchAsync` now honours the `Category` (name) and `CategoryId` filters, subcategories included. `menu.filter.cycle` now tells the player the active value in chat. |
| 6 | Owner edits everyone, online and offline, self included | New node `knk.admin.user.manage.all` (default op, child of `knk.admin`). Holders see every account in the Player manager, from a paged, searchable `UsersQueryApi.search` sorted by username; each row shows an online or offline marker and "(you)". Holders pass `users.outranks-target`, and `UserAdminService.withRankCheck` skips `RankHierarchy`, so `/knk user` edits by holders also skip it. Per-property `knk.admin.user.<property>` nodes still apply. Mode and kick still need the target online. Staff without the node keep the old list (online players they outrank), which can now also be searched. |

**Bug fixed on the way:** `ItemBlueprintsDataAccess.searchAsync` put the search's partial summaries
into the by-id cache. As a result a later `getByIdAsync` (kit grants, `/knk itemblueprints give`) could build an item without its
enchantments or lore. Search results are no longer cached by id.

**Migration:** `20260926001951_AddMenuDynamicHeightAndBackground` (web-api) adds
`menu_templates.MinHeight`, `menu_templates.BackgroundMaterial` and `menu_section_templates.MinHeight`.
It is generated only, **not applied**.

**Seeds are create-only.** A database that already holds the ten content templates keeps the old
versions. To see these changes there, delete those templates and restart the API, or edit them
through the CRUD API.

**Tests:** web-api 496/501 (the same 5 pre-existing failures; +10 new). Plugin: knk-core 528 (+5),
knk-api-client 33 (+1), knk-paper 335 (+9, 14 skipped); `shadowJar` builds. `content-seeds.json`
regenerated.

**Checklist additions (in game):**
- `/menu` as a normal player: the kits and catalogue menus are shorter when there are few entries,
  gaps are light gray panes with no tooltip, and there are no pager arrows on a single page.
- A premium-kit purchase shows Confirm and Cancel in the header, and the menu does not resize.
- The hub head's lore lists the quick stats. On the profile, reached, current and future titles are
  distinguishable without reading the lore.
- The catalogue items look exactly like `/knk itemblueprints give` output. The hopper cycles categories, with a chat line naming each one; the barrier clears the filter.
- As an op (`knk.admin.user.manage.all`): the Player manager lists offline players and yourself; the search works; editing an offline player's coins works; editing yourself works.

## 12. What the session must not do

- Don't apply migrations or seeds to any real database (none is reachable, and the shared dev DB
  needs the owner's go-ahead each time). New migrations: none are expected; if one becomes necessary,
  generate it and say so in the status block.
- Don't merge to `master`/`main`, don't touch `claude/siege-minigame`, don't edit Siege templates.
- Don't port anything the catalogue marks shelved/deferred, and don't build G2–G7.
- Stop and record a question in the CP status instead of guessing when a decision here turns out
  to be impossible or contradicts the code.
