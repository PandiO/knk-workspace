# InventoryMenu — Content Port Plan (hub, Kits, Profile, Items, Premium, Player manager)

**Status:** Ready for implementation. No phase started. Phases are numbered CP1–CP8 (content port) to keep them apart from the engine plan's Phases 1–9, which this document cites as "engine Phase N".
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

## 6. CP4 — Item catalogue (`items.catalog`)

**Legacy source:** v1 List of items (§3.11).

Engine-only: reuse the existing `catalog.itemblueprints` content source and the engine Phase 5 search/filter
presets. Start from the `example.catalog` seed (`MenuTemplateSeed.cs`), give it the real key
`items.catalog`, a DIAMOND_SWORD header ("A list of all items in the game", total count), search
button, whichever filter facets the source actually supports (check `MenuContentSourceHandlers`
before adding any; the engine Phase 5 notes flag Category/Grade/Tag facets as blocked), pager, back.
Read-only — no click action on rows.

**Tests:** seed round-trip; validation.

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
