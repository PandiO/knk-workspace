---
status: final
last_updated: 2026-09-21
---

# knk-plugin Codebase Scan — 2026-09-21

Read-only scan per `docs/guides/v3-codebase-scan-instructions.md` §3
(knk-plugin). No code changes were made. Findings below come from three
parallel read-only research passes over `/home/user/knk-plugin` (commands/
listeners/GUIs; REST client/data-access/storage; gate-siege feature parity
and legacy dependencies), cross-checked against `CLAUDE.md`, the plugin's
own root-level status docs, and `knk-workspace`'s
`docs/reports/LEGACY_VS_V2_GAP_ANALYSIS.md`. Per the ground rules in the
scan instructions, every claim below is either cited to a file:line or
explicitly marked as inference/unverified.

This is the first dated scan of this kind for knk-plugin — no prior
`plugin-scan-*.md` exists to diff against.

---

## 1. Feature inventory

### 1a. Commands

`plugin.yml` (`knk-paper/src/main/resources/plugin.yml:9-22`) declares
exactly three top-level Bukkit commands — `knk`, `account`, `ce` — each
dispatching to a large set of hand-rolled subcommands. All three are
wired up in `KnKPlugin.onEnable()`; no plugin.yml command lacks an
executor, and no declared executor is missing from plugin.yml.

**`/knk` subcommands** (registered in `KnkAdminCommand.java:96-279` via
`CommandRegistry`):

| Subcommand | Class : file | Feature | What it does |
|---|---|---|---|
| `health` | `HealthCommand.java:17` | Admin/debug | Async health check against the web API |
| `cache` | inline lambda, `KnkAdminCommand.java:104-112` | Admin/debug | Prints `CacheManager.getHealthSummary()` |
| `towns`/`town` | `TownsDebugCommand.java:29` | Towns | Read-only list/get via `TownsQueryApi` |
| `districts`/`district` | `DistrictsDebugCommand.java:29` | Districts | Read-only list/get |
| `locations` | `LocationsDebugCommand.java:18` | Locations | Read-only paginated list/get of `KnkLocation`s |
| `location` | `LocationDebugCommand.java:11` | Debug | `location here` prints invoking player's Bukkit location |
| `enchantments`/`enchantment` | `EnchantmentDefinitionsDebugCommand.java:37` | Enchantments | List/search definitions, apply to held item |
| `itemblueprints`/`itemblueprint` | `ItemBlueprintsDebugCommand.java:38` | Items/admin | List/search blueprints, give generated `ItemStack` |
| `streets`/`street` | `StreetsDebugCommand.java:28` | Streets | Read-only list/get |
| `tasks` | `KnkTaskListCommand.java:18` | World tasks | Lists `WorldTask`s by status |
| `task-claim` | `KnkTaskClaimCommand.java:22` | World tasks | Claims a task (id or link code), starts its handler |
| `task-status` | `KnkTaskStatusCommand.java:16` | World tasks | Reports task status by id/link code |
| `gate` | `GateCommand.java` (dispatch `:73-80`; admin sub-subs `:252-258`; door sub-subs `:121-122`) | Gates/siege | Player+admin gate control: open/close/info/list/passthrough; admin health/repair/tp/reload/active/invincible/override; door capture/redefine |
| `help` | `HelpSubcommand.java:11` | Meta | Lists permission-filtered `/knk` subcommands |

**`/account` subcommands** (`AccountCommandRegistry.java:35-54`):

| Subcommand | Class : file | Description |
|---|---|---|
| `status` (default, alias `view`) | `AccountCommand.java:17` | Shows cached account info (coins/gems/XP, link status) |
| `link` | `AccountLinkCommand.java:28` | Generates/consumes a link code to merge/link a web account |

`AccountCommandRegistry`'s own usage string (`:74`) and `plugin.yml:17`
both advertise a `create` subcommand — **no `create` entry is registered**
(`AccountCommandRegistry.java:45-54`). Account creation appears to happen
implicitly through `AccountLinkCommand`/`UserManager` join-time flow
instead. Flagged as a doc/behavior mismatch, not confirmed dead code —
worth a decision on whether `create` was removed intentionally or the
usage string is stale.

**`/ce` subcommands** (`EnchantmentCommandHandler.java:36-40`):
`add`, `remove`, `info`, `cooldown clear`, `reload` — see
`commands/enchantment/*.java`, each a small dedicated class.

**Confirmed dead command class:** `WorldGuardManagementCommand.java:13`
(a `wgm rename <old> <new>` subcommand) is never instantiated or
registered anywhere — no `/knk` subcommand entry, no dynamic
`CommandMap.register()` pattern exists anywhere in the codebase. Its
region-rename functionality is actually exposed through
`RegionHttpServer`/`WgRegionIdTaskHandler`'s HTTP callback path instead
(`KnKPlugin.java:295-301`). High confidence — this is a genuine orphan,
not "appears unused."

### 1b. Listeners / event handlers

All 14 `Listener` implementations live under
`knk-paper/.../paper/listeners/` (confirmed: no `Listener` implementations
exist elsewhere in any of the three modules). All 14 are registered
somewhere in `onEnable` — 3 via the `registerEvents()` helper
(`KnKPlugin.java:514-522`), 4 via `EnchantmentBootstrap.initialize()`, the
rest inline. None are orphaned.

| Class : file | Event(s) | What it does |
|---|---|---|
| `ChatCaptureListener.java:15` | `AsyncPlayerChatEvent` (:28, LOWEST) | Routes captured chat (e.g. link-code entry) to `ChatCaptureManager`, cancels broadcast |
| `EnchantmentCombatListener.java:17` | `EntityDamageByEntityEvent` (:33) | Runs custom-enchantment melee-hit effects |
| `EnchantmentEnchantTableListener.java:13` | `PrepareItemEnchantEvent` (:20), `EnchantItemEvent` (:27) | Blocks vanilla enchanting of items already carrying a custom enchantment |
| `EnchantmentInteractListener.java:25` | `PlayerInteractEvent` (:50) | Right-click "SUPPORT"-type enchantment effects, cooldowns, permissions |
| `FreezeMovementListener.java:10` | `PlayerMoveEvent` (:18, HIGHEST) | Snaps frozen players back to their prior position |
| `GateDamageConsequenceListener.java:19` | `GateDoorDamageEvent` (:36), `GateDoorIgniteEvent` (:46) | Applies per-cause damage via `HealthSystem`, starts burn via `GateFireSystem` |
| `GateEventListener.java:38` | `BlockBreakEvent`, `EntityExplodeEvent`, `BlockExplodeEvent`, `ProjectileHitEvent`, `BlockIgniteEvent`, `PlayerInteractEvent` | Detects hits/interactions on gate blocks, translates to custom gate events, protects gate blocks from vanilla destruction |
| `GatePassThroughConsequenceListener.java:22` | `GateDoorInteractEvent` (:32) | Resolves pass-through mode on right-click of a closed gate, dispatches to `GatePassThroughService` |
| `PlayerListener.java:51` | Login/join/leave/command/chat/death/respawn/pickup (8 handlers) | Legacy join/leave/chat/death handling — see caveats below |
| `RegionTaskEventListener.java:13` | `OnRegionEnterEvent` (:24) | Forwards to `WgRegionIdTaskHandler.onRegionEnter` |
| `UserAccountListener.java:34` | `PlayerJoinEvent` (:64, HIGH), `PlayerQuitEvent` (:104, MONITOR) | Syncs account data via `UserManager`, welcome/balance messages, duplicate-account/email-link prompts |
| `WorldGuardRegionListener.java:22` | `PlayerMoveEvent`, `PlayerTeleportEvent`, `PlayerJoinEvent`, `PlayerQuitEvent` | Delegates region enter/leave transitions to `WorldGuardRegionTracker` |
| `WorldTaskChatListener.java:17` | `AsyncPlayerChatEvent` (:40) | Routes chat to whichever world-task handler is active for that player |
| `WorldTaskLocationSelectionListener.java:13` | `PlayerInteractEvent` (:21) | Routes right-clicks to the active location-selection world-task handler |

**Stub / suspicious listener behavior found:**

1. **`PlayerListener.onPlayerRespawn` — confirmed stub**
   (`listeners/PlayerListener.java:237-257`): fetches the default town
   async, then a `TODO`/commented-out `e.setRespawnLocation()` means the
   handler fires but never actually changes the respawn point.
2. **`PlayerListener.onItemPickup` — blanket cancel, no gate**
   (`listeners/PlayerListener.java:259-262`): unconditionally
   `e.setCancelled(true)` for every `PlayerPickupItemEvent` server-wide,
   with no config flag or comment explaining why. Not a no-op, but looks
   like leftover debug/WIP code — verify intent before touching.
3. **`OnRegionLeaveEvent` fired but never consumed** — `WorldGuardRegionTracker.java:396,432`
   both call `Bukkit.getPluginManager().callEvent(new OnRegionLeaveEvent(...))`,
   but a repo-wide grep for `OnRegionLeaveEvent` only turns up its own
   class definition and these two call sites — no `@EventHandler` anywhere
   consumes it (contrast `OnRegionEnterEvent`, which `RegionTaskEventListener`
   does consume). Confirmed dead signal — any planned region-leave
   world-task hook doesn't exist yet.
4. **`PlayerListener` vs `UserAccountListener` — duplicate join/quit
   handling, self-acknowledged.** Both register `PlayerJoinEvent`/
   `PlayerQuitEvent` handlers and both send separate welcome messages.
   `PlayerListener`'s own class Javadoc (`:45-50`) says: "Legacy player
   listener... User creation is now handled by UserAccountListener +
   UserManager. This listener only handles join greeting and
   teleportation" — the overlap is acknowledged in-code, but as of this
   scan a player still gets two separate join-time messages from two
   systems. Low-risk cleanup candidate.
5. `WorldTaskChatListener.java:52` has a
   `// TODO: Route to other task handlers as they are implemented` comment
   — not a stub, but documents the handler-routing list is known-incomplete.

### 1c. GUIs / menus — confirmed: none exist

Case-insensitive, repo-wide (all 3 modules, main + test) search for
`Menu`, `Gui`, `InventoryClickEvent`, `InventoryOpenEvent`,
`openInventory`, `InventoryHolder`, `createInventory` returned **zero
Java source matches**. This confirms `CLAUDE.md`'s existing claim. The
only hits anywhere are documentation:

- `spec/WG_REGION_ID_WORLD_TASK_REQUIREMENTS.md:80,85` — describes an
  inventory-menu confirmation UI as **future** work.
- `docs/MIGRATION_MODE_READONLY.md:40` — lists porting inventory-menu UI
  as out-of-scope/future.
- `knk-workspace/docs/specs/inventory-menu/REQUIREMENTS_INVENTORY_MENU.md`
  — a requirements/planning doc only ("Status: Analysis & Planning"),
  describing the legacy `Menu`/`MenuSection`/`MenuItem` system as a spec
  for future rebuild, not a record of anything built.
- `LEGACY_VS_V2_GAP_ANALYSIS.md` line 21 adds: *"The `InventoryMenus`
  branch on `knk-plugin` has exactly one commit ('Initial requirement
  assessment'), no code."* **Unverified in this session** — only the
  checked-out default branch was scanned; no `git branch -a` was run.
  Re-verify if branch history matters for planning.
- **Doc/reality mismatch found:** `.github/copilot-instructions.md:14`
  describes `knk-paper` as containing "commands, listeners, UI/inventory
  menus, config loading, bootstrap wiring" — this overstates what exists.
  `CLAUDE.md`'s equivalent claim is accurate; the GitHub Copilot
  instructions file is stale and should be corrected or flagged to the
  developer.

### 1d. REST integration with knk-web-api

Full architecture description is in `docs/architecture/plugin-architecture.md`.
Summary table of REST resource clients (`knk-api-client/.../impl/*ApiImpl.java`):

| Client | Resource | Verbs/endpoints |
|---|---|---|
| `HealthApiImpl` | Health | `GET /health` |
| `TownsQueryApiImpl` | Towns | `POST /Towns/search`, `GET /Towns/{id}` |
| `DistrictsQueryApiImpl` | Districts | `POST /Districts/search`, `GET /Districts/{id}` |
| `StructuresQueryApiImpl` | Structures | `POST /Structures/search`, `GET /Structures/{id}` |
| `StreetsQueryApiImpl` | Streets | `POST /Streets/search`, `GET /Streets/{id}` |
| `LocationsQueryApiImpl` | Locations | `POST /Locations/search`, `GET /Locations/{id}` |
| `EnchantmentDefinitionsQueryApiImpl` | Enchantment defs | `POST /EnchantmentDefinitions/search`, `GET .../{id}` |
| `ItemBlueprintsQueryApiImpl` | Item blueprints | `POST /ItemBlueprints/search`, `GET .../{id}` |
| `MinecraftMaterialRefsQueryApiImpl` | Material refs | `GET /MinecraftMaterialRefs/{id}` |
| `DomainsQueryApiImpl` | Domains | `GET /Domains/by-region/{wgRegionId}`, `POST /Domains/search-region-decisions` |
| `UsersQueryApiImpl` | Users (read) | `GET /users/{id}`, `/uuid/{uuid}`, `/username/{username}`, `POST /users/search` |
| `UsersCommandApiImpl` | Users (write) | `PUT /Users/{id}/coins`, `PUT /Users/{uuid}/coins`, `PUT .../gate-passthrough-method`, `POST /Users` |
| `UserAccountApiImpl` | Account lifecycle | `POST /Users`, `/check-duplicate`, `/generate-link-code`, `/validate-link-code/{code}`, `/link-account`, `/merge`, `PUT .../change-password`, `PUT .../update-email` |
| `WorldTasksApiImpl` | World tasks | `GET /WorldTasks/status/{status}`, `/by-link-code/{code}`, `/{id}`, `POST .../claim`, `/complete`, `/fail` |
| `GateStructuresApiImpl` | Gate structures | `GET /GateStructures`, `/{id}`, `?districtId=`, `PATCH /{id}/overrides` |
| `GateDoorsApiImpl` | Gate doors | `GET /GateStructures/{id}/doors`, `GET /GateDoors/{id}`, `PUT .../state`, `/operational-settings`, `/health`, `/region` |
| `RegionsCommandApiImpl` | Regions (outbound rename) | `POST /Regions/rename?oldRegionId=&newRegionId=` |

No `DELETE` verb is used anywhere in the client. Auth: static bearer token
from `config.yml` via `BearerAuthProvider`, no refresh/401-retry logic
(`api/auth/BearerAuthProvider.java`, full file, 25 lines).

Sync model is mixed: on-demand cache-first reads for most data; one
outbound poller (`HeadlessWorldTaskPoller`, self-flagged as tech debt
pending a push/SignalR replacement); periodic outbound push/sync tasks for
gate state; and one **inbound** channel — `RegionHttpServer` running an
HTTP server inside the plugin so `knk-web-api` can query WorldGuard/
WorldEdit region data the API side can't compute itself.

### 1e. Local storage — clean

No embedded DB, no `jdbc:` strings, no on-disk serialization
(`ObjectOutputStream`/`FileOutputStream`), no YAML/JSON used as a data
store, anywhere in the repo. `LocalEnchantmentRepositoryImpl` (despite the
name) is stateless — it parses in-memory item-lore strings. All persistent
domain data flows through the REST API. **V2→V3 storage migration is
complete** for every entity type the plugin touches — this is a clean
finding, no action needed.

---

## 2. V1/V2 → V3 feature-parity table

| Feature | V1/V2 had | V3 status | Evidence | Confidence |
|---|---|---|---|---|
| Gate open/close animation | Basic (`GateAnimationUtil`) | **Reimplemented, far broader** — rotation/vertical/lateral, rigid-transform blending, rasterized gap-fill, region-mode polygon geometry | `knk-core/.../gates/{GateFrameCalculator,RigidTransform,GateBlockPairing}.java`; gap-analysis line 37 | High |
| Gate health/damage/respawn/fire | Basic (`ContinuousGateDamageUtil`) | **Fully ported + extended** (fire DoT, pass-through, respawn scheduling) | `knk-paper/.../gates/{HealthSystem,GateFireSystem}.java`; workspace `PHASE_STATUS.md` Phase 10 | High |
| Siege minigame (capture/teams/objectives) | WIP in V2 per project brief | **Not started** — only inert `currentSiegeId`/`isSiegeObjective` fields, no siege service/logic anywhere | `CachedGateStructure.java:19-23,56-85`; repo-wide grep found no `siege/` package; gap-analysis line 17 ("Minigames... Zero trace") | High |
| In-game inventory/GUI menus | `Menu`/`MenuSection`/`MenuItem` framework | **Not started** | Zero code hits repo-wide (§1c above); `REQUIREMENTS_INVENTORY_MENU.md` is planning-only; gap-analysis line 21 (branch claim, unverified this session) | High (code); Medium (branch claim) |
| User accounts / balances | In-game-only accounts | **Fully ported, exceeds legacy** (web app + JWT + coins/gems/XP) | `PlayerUserData.java`, `UserManager.java`; gap-analysis "fully covered" section | High |
| Player statistics (logins, cash history) | `UserStatistics`/`UserStatisticsDaily` | **Not started** | No stats/analytics model found anywhere; gap-analysis line 25 | High |
| Player rank/title gating | `Grade.java`, `Town.requiredTitle` | **Not started** | No role/rank code found beyond Bukkit permission nodes; gap-analysis line 22 | High |
| Global/game-wide settings | Unclear if it existed even in V2 | **Not started** — only infra config exists (API, cache, gate timing) | `KnkConfig.java`, `config.yml`; no `GameSettings`/`GlobalSettings` class found | Medium (V1/V2 baseline itself unclear) |
| Storage/warehousing, transport/logistics, resource production | Full DAOs + commands | **Not started** | Gap-analysis lines 18-20 ("Zero trace"); not independently re-verified against V1/V2 source this session | High (per workspace doc) |
| Item kits | `model/item/kit/*` | **Not started** | Gap-analysis line 23 | Medium (relied on workspace doc) |
| WorldGuard/WorldEdit region handling | Tightly coupled (`WorldguardUtil`, `SelectionListener`) | **Reimplemented via WorldTask flow**, same libs, task-driven instead of listener-driven | `WgRegionIdTaskHandler.java`, `GateDoorRegionCaptureHandler.java`; gap-analysis line 36 | High |
| Citizens NPC integration | Used in V1 | **Fully removed** | Zero grep hits for "citizens" anywhere (build files + all Java sources) | High |
| Custom enchantments | Separate legacy addon jar | **Fully ported** | `config.yml` `custom-enchantments:` section, `knk-paper/.../enchantment/` package | Medium (only config/wiring verified in depth, not full enchantment package) |

**Reading this table for MVP planning:** gate structures/door
animation/health are the one feature area that is genuinely at or beyond
V1/V2 parity today. The siege minigame itself — the stated MVP headline
feature per `GLOBAL_AGENT_INSTRUCTIONS.md` — has **no implementation
started** beyond the gate substrate it will presumably build on
(inert `currentSiegeId`/`isSiegeObjective` fields are the only hook
points that exist). Treat "gate structures are done" and "siege minigame
is done" as two different claims; only the first is currently true.

---

## 3. Legacy / orphaned / hygiene findings

Ranked roughly by confidence that action is warranted.

### Confirmed, high confidence

1. **Stray committed compiled class file at repo root.**
   `net/knightsandkings/knk/api/client/KnkApiClient.class` is tracked in
   git (`git ls-files net/` confirms it, and it is **not** covered by
   `.gitignore`'s `**/build/`/`.gradle/` patterns — it sits at a bare
   `net/` path outside any build directory). This is a build artifact
   that was accidentally committed, not source. Recommend deleting it and
   confirming no tooling depends on its presence at that path.
2. **`WorldGuardManagementCommand.java`** — dead command class, never
   registered anywhere (§1a). High confidence, safe removal candidate
   once confirmed the developer doesn't have WIP plans for it.
3. **`OnRegionLeaveEvent` fired with no listener** (§1b item 3) — either
   finish the intended leave-hook or remove the dead event-firing code.

### Likely, needs a developer decision

4. **`PlayerListener.onPlayerRespawn` stub** (§1b item 1) — TODO'd,
   non-functional; either implement custom respawn-to-town or remove the
   handler until it's ready.
5. **`PlayerListener.onItemPickup` blanket cancel** (§1b item 2) — no
   comment or config gate explaining why all pickups are disabled
   server-wide; verify intent before any inventory/economy work touches
   this area.
6. **Duplicate join/quit welcome messaging** between `PlayerListener` and
   `UserAccountListener` (§1b item 4) — self-acknowledged in code
   comments, not yet cleaned up.
7. **`PaperGateControlAdapter.openGate/closeGate` are stubs**
   (`knk-paper/.../gates/PaperGateControlAdapter.java:29-51`, explicit
   `// TODO`) — wired into `SimpleRegionTransitionService` via
   `KnKPlugin.java:373` for a region-entry-triggers-gate concept separate
   from the main gate-structure-animation system. Low usage risk today
   since nothing exercises the region-transition path yet, but flag before
   anyone assumes "region entry opens gates" works.
8. **`WorldGuardIntegration.regionExists()` is dormant** — instantiated
   and passed through (`KnKPlugin.java:427`) but has no production call
   site (`GateAnimationTask.java` documents the WG region-sync role was
   "removed in item 6.2"). Not dead code (class is live-wired), but
   currently has zero runtime effect outside its own unit test.
9. **Duplicate `RegionTransitionService` class name** in `knk-core`:
   `regions/RegionTransitionService.java` vs
   `services/RegionTransitionService.java` + `services/iRegionTransitionService.java`.
   Needs a look to confirm which (if either) is dead.
10. **`knk-core`'s Gson dependency is close to dead weight** —
    `domain/validation/WorldTaskValidationRule.java` is the only user,
    and it only holds a `com.google.gson.JsonElement` field with zero
    real Gson API calls (no `Gson`, `JsonParser`, `.toJson()`). Jackson
    does the module's only actual parsing (`util/CoordinateParser.java`).
    Consider re-typing that one field to drop the dependency.
11. **`knk-paper` declares Jackson directly but never imports it** —
    0 files in `knk-paper` reference `com.fasterxml.jackson`; Jackson
    arrives transitively via `knk-api-client` and is shadow-relocated
    (`build.gradle.kts:51`). `knk-paper`'s own JSON handling (region/task
    payloads) uses Gson instead (5 files: `PlaceholderInterpolationUtil`,
    `GateRegionDataFormat`, `LocationTaskHandler`, `WgRegionIdTaskHandler`,
    `GateBlockScanTaskHandler`). The direct Jackson declaration in
    `knk-paper/build.gradle.kts` looks redundant, and it pins a different
    version (2.15.2) than `knk-api-client` (2.17.2) — a version-alignment
    smell even if not currently causing a runtime conflict.
12. **`/account create` advertised but not registered** (§1a) — usage
    string and plugin.yml both mention it, `AccountCommandRegistry` never
    registers it.
13. **`.github/copilot-instructions.md` overstates implemented scope**
    (§1c) — claims UI/inventory menus exist in `knk-paper`; they don't.
    `CLAUDE.md` is accurate; this file should be corrected.
14. **`GateStructuresApi`/`GateDoorsApi` interfaces misplaced** in
    `knk-api-client` instead of `knk-core/ports/api` (architecture doc has
    detail) — not "dead" but a consistency debt that will confuse anyone
    adding a 17th resource client and following the existing pattern.

### Explicitly NOT found (positive findings, no action needed)

- No embedded DB / flat-file data store anywhere (§1e).
- No Citizens NPC library references anywhere (build files or source).
- WorldGuard/WorldEdit are genuinely used (not leftover imports) in every
  class except `WorldGuardIntegration` noted above.
- No GUI/menu code anywhere (§1c) — this is a "not started" finding, not
  an orphaned-code finding, but recorded here since it was one of the
  things this scan was asked to check for.

---

## 4. Uncertain / needs follow-up

- Whether an `InventoryMenus` git branch with real content exists (the
  gap-analysis doc's claim of "one commit, no code" was not independently
  re-checked from this checkout — `git branch -a` was not run).
- Whether the `gate-structure-animation` branch work described as
  "unmerged" in `LEGACY_VS_V2_GAP_ANALYSIS.md` (line 37) has since merged
  — `ACTIVE_SESSIONS.md`'s "Recently completed" table suggests active,
  fairly recent (2026-09-20) live-verified work on that branch, but this
  scan did not check branch/merge state.
- Whether `PaperGateControlAdapter`'s stub `openGate`/`closeGate` are
  planned near-term work or genuinely abandoned — needs a developer call.
- Full `knk-paper/.../enchantment/` package was only lightly touched by
  this scan (config/wiring verified, not every effect class) — flagged in
  the parity table as Medium confidence.

---

## Methodology note

This scan intentionally prioritized breadth over exhaustive depth per the
scan instructions' time-boxing rule, given ~386 Java files across the
three modules. The gate-structure package (`gates/`, both modules) got the
closest reading since it's the most MVP-relevant area. Enchantments,
individual gate-animation task classes, and command validator/utility
classes were surveyed at a summary level rather than read in full.
