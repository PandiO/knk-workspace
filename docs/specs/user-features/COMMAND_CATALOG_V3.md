# v3 Command Functional Catalog — `knk-plugin` (2026-09-25)

> Companion to [COMMAND_PERMISSION_SCAN.md](COMMAND_PERMISSION_SCAN.md) (the permission-node inventory this doc
> deliberately reuses rather than re-deriving) and to [docs/specs/legacy/commands-v1.md](../legacy/commands-v1.md) /
> [commands-v2.md](../legacy/commands-v2.md) (the same style of catalog for the two prior codebases). Together the
> three docs are the full command-history record for the project — read them when drafting a v3 feature design or
> implementation plan for any area that had a predecessor command, so prior behavior/bugs/permission gaps are known
> rather than silently reinvented or repeated. For the passive/reactive half of the behavior surface (Bukkit event
> listeners, not commands), see [EVENT_CATALOG_V3.md](EVENT_CATALOG_V3.md) and its v1/v2 siblings
> [events-v1.md](../legacy/events-v1.md) / [events-v2.md](../legacy/events-v2.md).

**Status:** Draft — fresh, source-grounded read of `knk-plugin` `main` at
`Repository/knk-plugin` (checked out under the main repo checkout, not the
worktree this scan ran from — the worktree's `Repository/` is empty/untracked).
**Method:** Every file under
`knk-paper/src/main/java/net/knightsandkings/knk/paper/commands/**` (30
non-test `.java` files, 8 test files, matching the ~38 total the task
description cited) plus `knk-paper/src/main/resources/plugin.yml` was read in
full. Every command/subcommand's method body was read (not just its
signature/name) to describe actual behavior — queries, mutations, side
effects. `plugin.yml` wiring was cross-checked against
`KnKPlugin.java` (`getCommand("...")`/`setExecutor` call sites) and
`EnchantmentBootstrap.java` to confirm what's actually reachable at runtime,
not just declared. Permission nodes are cited by file:line for each call site
found; the **static node inventory itself is not re-derived** — see
`docs/specs/user-features/COMMAND_PERMISSION_SCAN.md` (2026-09-23, already
accurate) for the full `plugin.yml` permission tree and `k&k.*` legacy
leftovers. Anything not directly observed in source is marked **NOT FOUND**
with the search tried, rather than guessed at.

All line numbers refer to
`knk-paper/src/main/java/net/knightsandkings/knk/paper/commands/**` unless a
different path is given.

---

## 0. Command entry points (Bukkit-registered) and dispatch infrastructure

`plugin.yml` (`knk-paper/src/main/resources/plugin.yml:11-45`) declares four
top-level Bukkit commands: `knk`, `account`, `ownermode` (alias `om`),
`staffmode` (alias `sm`), and `ce` (alias `customench`). All five are wired in
`KnKPlugin.java`:

| Bukkit command | Executor class | Wired at |
|---|---|---|
| `/knk` | `KnkAdminCommand` | `KnKPlugin.java:718-746` |
| `/account` | `AccountCommandRegistry` | `KnKPlugin.java:752-765` (approx.) |
| `/ownermode`, `/staffmode` | `ModeCommand` (one instance per mode) | `KnKPlugin.java:767-776` (`registerModeCommand`) |
| `/ce` | `EnchantmentCommandHandler` | `knk-paper/src/main/java/net/knightsandkings/knk/paper/bootstrap/EnchantmentBootstrap.java:32-66` |

`CommandRegistry.java` and `CommandMetadata.java` are shared plumbing: a
`LinkedHashMap`-backed subcommand table with alias support
(`CommandRegistry.java:10-58`), used by both `KnkAdminCommand` (for `/knk`'s
subcommands) and `AccountCommandRegistry` (for `/account`'s). `SubcommandExecutor`
(`SubcommandExecutor.java`) is the functional-interface contract each
registered subcommand implements. `HelpSubcommand.java` renders `/knk help`
and `/knk help <command>` from whatever is currently registered in the
`CommandRegistry` (permission-filtered per viewer via
`CommandRegistry.listAvailable`, `CommandRegistry.java:46-50`).

**Dead/unwired code found:** `WorldGuardManagementCommand.java` (intended as
`/knk wgm rename <old> <new>` per its own usage string,
`WorldGuardManagementCommand.java:23`) is never registered anywhere —
grepping `knk-paper/src/main` for the class name and for `"wgm"` in
`KnKPlugin.java` and `plugin.yml` finds no `setExecutor`/`getCommand` call
site referencing it. It is unreachable in-game; the only description of its
purpose is its own class javadoc ("region renaming operations typically
called by the Web API," `WorldGuardManagementCommand.java:9-11`). No sender
permission check exists in the class at all.

---

## 1. `users` / `account` (identity & linking)

### `/account` (alias `/acc`) — `status` (default, also `view`)
- **File:** `AccountCommand.java:26-65`, dispatched from
  `AccountCommandRegistry.java:45-49,58-65`
- **Syntax:** `/account`, `/account status`, `/account view`
- **Arguments:** none
- **Permission:** `knk.account.use` — checked generically in
  `AccountCommandRegistry.onCommand` at `AccountCommandRegistry.java:80-83`
  (per-subcommand check against `CommandMetadata.permission()`, registered as
  `knk.account.use` for this subcommand at `AccountCommandRegistry.java:46`).
  Bukkit-level gate is also `knk.account.use` via `plugin.yml:25`.
- **Goal/function:** Player-only. Reads the player's cached account data
  (`UserManager.getCachedUser`, `AccountCommand.java:33`) and prints username,
  UUID, email-link status, coins, gems, experience
  (`AccountCommand.java:39-53`); if `hasDuplicateAccount()` is true, prints a
  duplicate-account warning pointing at `/account link`
  (`AccountCommand.java:59-62`). Pure read — no mutation, no API call (data
  comes from the already-populated join-time cache).
- **Feature allocation:** `users`/`account`
- **Status:** Finished, player-facing.

### `/account link [code]`
- **File:** `AccountLinkCommand.java:52-199`, dispatched from
  `AccountCommandRegistry.java:51-54`
- **Syntax:** `/account link` (generate a code) or `/account link <code>`
  (consume one)
- **Arguments:** optional `code` (string) — presence/absence branches the
  whole command (`AccountLinkCommand.java:66-74`)
- **Permission:** `knk.account.use` (same generic check as above,
  `AccountCommandRegistry.java:52,80-83`). Note `plugin.yml` also declares a
  narrower `knk.account.link` node (`plugin.yml:188-190`, default `true`) but
  **it is never referenced in `AccountLinkCommand.java` or
  `AccountCommandRegistry.java`** — grep for `account.link` in
  `knk-paper/src/main/java` finds only the `plugin.yml` declaration and this
  command's registration key ("link"), not a `hasPermission` call. The node
  is declared but unenforced by this command.
- **Goal/function:**
  - No-arg form (`generateLinkCode`, `AccountLinkCommand.java:79-122`):
    per-player cooldown-gated (`config.account().cooldowns().linkCodeGenerateSeconds()`,
    `AccountLinkCommand.java:81-87`), calls
    `userAccountApi.generateLinkCode(userData.userId())` and messages the
    player the formatted code + expiry minutes on success
    (`AccountLinkCommand.java:98-108`); resets the cooldown on API failure
    (`AccountLinkCommand.java:110-121`).
  - One-arg form (`consumeLinkCode`, `AccountLinkCommand.java:124-199`):
    separately cooldown-gated, validates the code via
    `userAccountApi.validateLinkCode(code)`
    (`AccountLinkCommand.java:138`), and on success **mutates the in-memory
    cached user** (`userManager.updateCachedUser`,
    `AccountLinkCommand.java:166-184`) with the linked email/username —
    does not re-fetch coins/gems/XP from the response, just carries over the
    existing cached values (`AccountLinkCommand.java:173-175`).
- **Feature allocation:** `users`/`account`
- **Status:** Finished, player-facing (generate + consume paths are both
  live and reachable).
- **Dead code found:** `AccountLinkCommand.startMergeFlow`
  (`AccountLinkCommand.java:201-236`) and `mergeAccounts`
  (`AccountLinkCommand.java:238-263`) implement a full duplicate-account
  merge flow via `ChatCaptureManager.startMergeFlow` — **but `startMergeFlow`
  is never called from anywhere in `AccountLinkCommand.java`** (grepped for
  `startMergeFlow(` within the file: only the method definition at line 201
  and the internal call to `chatCaptureManager.startMergeFlow` at line 213;
  no caller of the private `AccountLinkCommand.startMergeFlow` method
  itself exists). The merge UI/logic is fully implemented but currently
  unreachable — `AccountCommand.java:59-62` tells the player to run
  `/account link` to resolve a duplicate, but `/account link`'s own code path
  never triggers the merge flow it has sitting right next to it.

### `/account create` — declared, not implemented
- **NOT FOUND as a working command.** `plugin.yml:186-190` declares
  `knk.account.create` (default `true`, described as "Create account with
  email/password via /account create"), and both
  `AccountCommandRegistry.java:19` (class javadoc: "Handles subcommands:
  status, create, link") and its own usage string
  (`AccountCommandRegistry.java:74`: `/account [create|link|status]`)
  reference a `create` subcommand — but `AccountCommandRegistry`'s
  constructor only calls `registry.register(...)` twice, for `"status"`
  (`AccountCommandRegistry.java:45-49`) and `"link"`
  (`AccountCommandRegistry.java:51-54`). There is no `registry.register` call
  for `"create"` anywhere in the file, and no other class implements it
  (grepped `knk-paper/src/main/java` for a `create` subcommand tied to
  `/account`; nothing found). Running `/account create` today falls through
  to the "Unknown command" branch (`AccountCommandRegistry.java:72-76`).
- **Feature allocation:** `users`/`account`
- **Status:** Stub/placeholder — permission node and docs exist, command
  does not.

### `/ownermode` (alias `/om`) and `/staffmode` (alias `/sm`)
- **File:** `ModeCommand.java` (one instance each, parameterized by
  `ActiveMode`), wired at `KnKPlugin.java:767-776`
- **Syntax:** `/ownermode [on|enable|off|disable] [onquit|oq]` or
  `/ownermode help`; identical shape for `/staffmode`. Bare `/ownermode`
  toggles.
- **Arguments:** optional `on|enable|off|disable|help` (first arg), optional
  `onquit|oq` (second arg, only valid alongside on/off) — full parsing at
  `ModeCommand.java:58-87`. Tab-completion for both is implemented
  (`ModeCommand.java:184-197`).
- **Permission:** `knk.mode.owner` / `knk.mode.staff` — **not** a
  `plugin.yml permission:` (deliberately, per class javadoc,
  `ModeCommand.java:30-34`, to preserve per-subcommand-style routing before
  Bukkit's own tree would intercept it). Checked via
  `modeService.whenHasModePermission(player, mode, ...)`
  (`ModeCommand.java:91-101`), which resolves through `KnkPermissible`
  (op-bypass + REST-backed grant model per `plugin.yml:127-152`'s
  documentation comments for these two nodes) rather than
  `sender.hasPermission`.
- **Goal/function:** Toggles/sets the player's vanish-like owner/staff mode.
  `onquit` variant persists the target mode without applying it immediately
  (`ModeCommand.java:108-128`); the immediate variant applies via
  `modeService.applyMode` then persists async, warning the player if the
  persist fails (`ModeCommand.java:131-157`). This is a v1-parity restoration
  (v1 had the same toggle; v2 left it as dead TODOs per
  `COMMAND_PERMISSION_SCAN.md` §2) — vanish-like state, now actually
  persisted (unlike v1's static-map-only state).
- **Feature allocation:** `users`/`account` (rank/mode gating) — closest
  overlap is the rank/permission-system work referenced in
  `COMMAND_PERMISSION_SCAN.md`.
- **Status:** Finished, player-facing (for holders of the mode permission).

---

## 2. `towns` (towns, districts, streets, locations, gates)

All of the following (`towns`/`town`, `districts`/`district`,
`streets`/`street`, `locations`/`location`) are **read-only debug/inspection
tools** reachable only through `/knk`, each explicitly documented as
READ-ONLY in its own class javadoc where present.

### `/knk towns list [page] [size]`, `/knk town <id>`
- **File:** `TownsDebugCommand.java`, registered twice in
  `KnkAdminCommand.java:117-134` — once as `towns` (routes to `list`/`town`
  subcommands inside the class, `KnkAdminCommand.java:118-122`), once as
  `town` (a thin wrapper that injects `"town"` as `args[0]` so `/knk town <id>`
  reaches `TownsDebugCommand`'s `"town"` branch directly,
  `KnkAdminCommand.java:125-134`).
- **Permission:** `knk.admin.towns` for `towns` (`KnkAdminCommand.java:119`),
  `knk.admin.town` for `town` (`KnkAdminCommand.java:126`) — both checked
  generically in `KnkAdminCommand.onCommand`
  (`KnkAdminCommand.java:358-362`).
- **Goal/function:** `list` paginates `TownsQueryApi.search` (default
  page=1/size=5, clamped 1-100, `TownsDebugCommand.java:58-76`) and prints
  id/name/description/WG-region per town. `town <id>` fetches one town by ID
  via `TownsQueryApi.getById` and prints full detail including nested streets
  and districts (`TownsDebugCommand.java:146-244`). Both purely read; no
  mutation.
- **Feature allocation:** `towns`
- **Status:** Finished debug/admin tool (not player-facing).

### `/knk districts list [page] [size]`, `/knk district <id>`
- **File:** `DistrictsDebugCommand.java` — explicitly commented
  "READ-ONLY: no create/update/delete commands" (`DistrictsDebugCommand.java:26`).
  Registered the same dual way as towns (`KnkAdminCommand.java:137-154`).
- **Permission:** `knk.admin.districts` (`KnkAdminCommand.java:139`),
  `knk.admin.district` (`KnkAdminCommand.java:146`).
- **Goal/function:** Same list/get-by-id pattern against `DistrictsQueryApi`;
  `district <id>` detail view includes town, location, streets, and
  structures (`DistrictsDebugCommand.java:147-215`).
- **Feature allocation:** `towns`
- **Status:** Finished debug/admin tool.

### `/knk streets list [page] [size]`, `/knk street <id>`
- **File:** `StreetsDebugCommand.java` — "READ-ONLY: supports list and
  getById only" (`StreetsDebugCommand.java:20`). Registered dually
  (`KnkAdminCommand.java:262-279`).
- **Permission:** `knk.admin.streets` (`KnkAdminCommand.java:264`),
  `knk.admin.street` (`KnkAdminCommand.java:271`).
- **Goal/function:** List/get-by-id against `StreetsQueryApi`; detail view
  includes district IDs, nested district summaries (with WG region), and
  structures with house numbers (`StreetsDebugCommand.java:115-191`).
- **Feature allocation:** `towns`
- **Status:** Finished debug/admin tool.

### `/knk locations list <page> <size>`, `/knk locations <id>`
- **File:** `LocationsDebugCommand.java`. Registered once as `locations`
  (`KnkAdminCommand.java:157-162`) — a single subcommand handles both list
  and get-by-id internally based on `args[0]` (`LocationsDebugCommand.java:34-48`
  for list, `:50-64` for id lookup).
- **Permission:** `knk.admin.locations` (`KnkAdminCommand.java:159`).
- **Goal/function:** Paginated `LocationsQueryApi.search` or single
  `getById`, printing world/x/y/z(/yaw/pitch for single) per
  `KnkLocation` (`LocationsDebugCommand.java:67-86`).
- **Feature allocation:** `towns`
- **Status:** Finished debug/admin tool.

### `/knk location here`
- **File:** `LocationDebugCommand.java`, registered as `location`
  (`KnkAdminCommand.java:165-180`, which also enforces player-only and the
  literal `here` argument before delegating).
- **Permission:** `knk.admin.location` (`KnkAdminCommand.java:167`).
- **Goal/function:** Player-only. Converts the sender's current Bukkit
  location via `PaperLocationMapper.fromBukkit` and prints
  world/x/y/z/yaw/pitch (`LocationDebugCommand.java:18-31`). No API call, no
  persistence — a pure client-side readout, useful for grabbing coordinates
  to feed into other admin commands/the web app.
- **Feature allocation:** `towns`
- **Status:** Finished debug/admin tool.

### `/knk gate ...` — full subtree
- **File:** `GateCommand.java`, registered once as `gate` with **no
  metadata-level permission** (`null` in `KnkAdminCommand.java:319-324`) —
  every subaction below gates itself individually inside `GateCommand`, which
  the class javadoc calls out explicitly as the reason `/knk gate` isn't one
  of `knk.admin`'s children in `plugin.yml` (`plugin.yml:53-54`).
- **Domain model note (item 5):** a "gate" is now a `GateStructure` containing
  one or more independently-animating `GateDoor`s; selectors accept either a
  bare door id/name or `<gateStructure> <gateDoor>`
  (`GateCommand.java:32-39`, resolution logic `GateCommand.java:822-852`).

| Subcommand | Syntax | Permission (file:line) | Function |
|---|---|---|---|
| `open` | `/knk gate open <door\|id> \| <structure> <door>` | `knk.gate.open.<id>` or `knk.gate.open.*` (`GateCommand.java:298-299`) | Opens the resolved door via `GateManager.openGate`; refuses if not active or destroyed (`GateCommand.java:283-327`). |
| `close` | `/knk gate close <door\|id> \| <structure> <door>` | `knk.gate.close.<id>` or `knk.gate.close.*` (`GateCommand.java:347-348`) | Closes the resolved door via `GateManager.closeGate` (`GateCommand.java:332-370`). |
| `info` | `/knk gate info <door\|id> \| <structure> <door>` | none (public read) | Prints id/type/state/active/destroyed/health/invincible/blocks/motion/face-direction (`GateCommand.java:375-408`). |
| `list` | `/knk gate list` | none | Lists all cached gates sorted by id, with distance-from-sender when run by a player (`GateCommand.java:413-443`). |
| `passthrough` | `/knk gate passthrough <default\|instant\|teleport>` | player-only, no explicit permission check (`GateCommand.java:199-240`) | Sets the sender's own preferred `GatePassThroughMethod`; updates cache immediately, persists via `UsersCommandApi.setGatePassThroughMethodById` async (reload-on-failure pattern is a message only here, not an actual reload). |
| `door capture` | `/knk gate door capture <door\|id> \| <structure> <door> [closed\|opened]` | `knk.gate.admin` (`GateCommand.java:144`) | Player-only. Starts `GateDoorRegionCaptureHandler.startCapture` — a WorldEdit-selection-driven flow to define a door's open/closed region (`GateCommand.java:111-192`). |
| `door redefine` | same syntax, `redefine` | `knk.gate.admin` (`GateCommand.java:144`, shared check) | Same but re-edits an existing region (`startRedefine`). |
| `admin health` | `/knk gate admin health <door\|id> <amount>` | `knk.gate.admin` (`GateCommand.java:504`) | Sets a door's current health (clamped 0..max), persists via `GateDoorsApi.updateHealth` (`GateCommand.java:503-532`). |
| `admin repair` | `/knk gate admin repair <door\|id>` | `knk.gate.admin` (`GateCommand.java:538`) | Fully heals + un-destroys a door, persists health and state (`GateCommand.java:537-563`). |
| `admin tp` | `/knk gate admin tp <door\|id>` | `knk.gate.admin` (`GateCommand.java:569`) | Player-only. Teleports sender to the door's anchor point (`GateCommand.java:568-602`). |
| `admin reload` | `/knk gate admin reload` | `knk.gate.admin` (`GateCommand.java:454`) | Full gate reload from the API via `GateManager.reloadGates` (`GateCommand.java:453-473`). |
| `admin reload district <id>` | `/knk gate admin reload district <id>` | `knk.gate.admin` (same check, `GateCommand.java:454`) | Forces one district's gates to refresh via `DistrictGateLoader.forceReload` without a full-world reload (`GateCommand.java:445-497`); returns a friendly error if `districtGateLoader` isn't configured on this server. |
| `admin active` | `/knk gate admin active <door\|id>` | `knk.gate.admin` (`GateCommand.java:769`, via shared `findAdminGate` helper) | Toggles `isActive`, persists via `GateDoorsApi.updateOperationalSettings` (`GateCommand.java:604-614`). |
| `admin invincible` | `/knk gate admin invincible <door\|id>` | `knk.gate.admin` (same helper) | Toggles `isInvincible`, same persistence path (`GateCommand.java:616-626`). |
| `admin override` | `/knk gate admin override <structure> <field> <value\|clear>` (fields: `active`, `destroyed`, `invincible`, `canrespawn`, `openedstate`) | `knk.gate.admin` (`GateCommand.java:643`) | Structure-level cascading override — sets/clears a nullable override column so every child door's *effective* value reflects it without a per-door write; persists via `GateStructuresApi.updateOverrides` and mirrors onto the in-memory `CachedGateStructure` immediately (`GateCommand.java:628-749`). The `openedstate` case also actively drives every door in the structure through open/close via `GateManager` so the override takes real, immediate effect (`GateCommand.java:718-730`). |

- **Feature allocation:** maps to `docs/specs/gate-structure-animation/`
- **Status:** Finished, player+admin-facing feature (mix of public
  read/self-service commands and `knk.gate.admin`-gated mutation commands).
  The class javadoc references a specific implementation item ("Item 5") and
  named design decisions ("5.0-D", "5.0-B") from
  `docs/features/gate-structure-animation/GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md`,
  suggesting this command tree is actively evolving alongside that spec.

---

## 3. `items` / `item-blueprints`

### `/knk item rename <displayName>`
- **File:** `ItemCommand.java:75-97`, registered under `item`
  (`KnkAdminCommand.java:188-209`)
- **Permission:** `knk.admin` (flat, `KnkAdminCommand.java:194` — no
  finer-grained `knk.admin.item` node exists in `plugin.yml`, unlike most
  other `/knk` subcommands)
- **Goal/function:** Player-only, requires a held main-hand item. Rewrites
  the item's display name via `ItemMeta.setDisplayName`, formatted through
  `DisplayTextFormatter.translateToLegacy` (color-code translation) — direct
  client-side item mutation, no API call (`ItemCommand.java:75-97`).
- **Feature allocation:** `items`
- **Status:** Finished, admin-facing.

### `/knk item lore <add <text>|set <line> <text>|remove <line>>`
- **File:** `ItemCommand.java:99-180`
- **Permission:** `knk.admin` (same umbrella node as `item rename`)
- **Goal/function:** Player-only, held-item required. 1-based line numbering
  in the player-facing UI (`ItemCommand.java:30-31`). `add` appends;
  `set <line>` **inserts** at that 1-based position (shifting later lines
  down) rather than overwriting, explicitly by design
  (`ItemCommand.java:140-155`); `remove <line>` deletes with bounds-checking
  (`ItemCommand.java:156-170`). Direct `ItemMeta` mutation.
- **Feature allocation:** `items`
- **Status:** Finished, admin-facing.

### `/knk item enchantments <list|vanilla|search|apply>` (formerly standalone `/knk enchantments`)
- **File:** delegated from `ItemCommand.java:61` to
  `EnchantmentDefinitionsDebugCommand.java` (all subcommands live there).
  Merged in per a 2026-09-23 developer request documented at
  `KnkAdminCommand.java:182-185` — there is **no more standalone
  `/knk enchantments` command**; it is only reachable via `/knk item
  enchantments`. `HelpSubcommand.java:74` still checks
  `"enchantments".equalsIgnoreCase(meta.name())` to print extended
  enchantments-specific help — this is now **dead code**, since the
  registered command's `CommandMetadata.name()` is `"item"`, not
  `"enchantments"`, post-merge; that branch can never fire anymore.
- **Permission:** `knk.admin` (inherited from the parent `item` registration,
  `KnkAdminCommand.java:194` — `EnchantmentDefinitionsDebugCommand` itself
  performs no additional permission check of its own).
- **Subcommands** (all in `EnchantmentDefinitionsDebugCommand.java`):
  - `list [page] [size]` (`:91-105`) — paginated `EnchantmentDefinitionsDataAccess.listAsync`, prints id/key/displayName/maxLevel/type(custom|vanilla)/base namespace.
  - `search <id|key|displayName> <value> [page] [size]` (`:107-135`) — field-restricted search via `EnchantmentDefinitionsDataAccess.searchAsync`.
  - `vanilla [page] [size]` (`:317-349`) — lists all `minecraft:`-namespaced entries from the Bukkit `Registry.ENCHANTMENT`, client-side only, no API call.
  - `apply <id|vanillaName|customKey> [level]` (`:137-200`) — player-only, held-item required. Numeric target = KnK enchantment-definition id (fetched then dispatched to custom-or-vanilla application, `:351-383`); non-numeric target first tries to resolve as a **custom** KnK definition by key/display-name (`:202-263`, with an explicit no-fallback-guess design note at `:256-262` fixing a previous bug where an unmatched custom search silently picked an unrelated definition), then falls back to a **vanilla** Bukkit enchantment by key/name match (`:461-524`). Applies via `addUnsafeEnchantment` for vanilla/KnK-vanilla-backed defs, or via `EnchantmentRepository.applyEnchantment` (lore-based) for custom defs, with a lore-reordering pass so enchantment lines sort first (`:431-459`).
- **Feature allocation:** `custom-enchantments` (definition catalog side) /
  `items` (since it's now nested under item editing)
- **Status:** Finished, admin-facing debug tool. Actively restructured
  (merge from standalone command) as of 2026-09-23.

### `/knk itemblueprints list|search|get|give` (aliases `/knk itemblueprint`, `/knk ib`)
- **File:** `ItemBlueprintsDebugCommand.java`, registered as `itemblueprints`
  with alias `itemblueprint` (`KnkAdminCommand.java:217-233`); `ib` added by
  KNG-10 (PandiO/knk-plugin#1, pending merge as of 2026-09-26)
- **Permission:** `knk.admin.itemblueprints` (`KnkAdminCommand.java:222`)
- **Subcommands:**
  - `list [page] [size]` (`:92-106`) — paginated blueprint listing.
  - `search <id|name|displayName> <value> [page] [size]` (`:108-136`).
  - `get <id>` (alias `id`) (`:138-161`) — full blueprint detail.
  - `give <id> [player]` (`:163-292`) — the only **mutating** subcommand here:
    resolves the blueprint's icon material (via
    `MinecraftMaterialRefsDataAccess` if an `iconMaterialRefId` is set,
    `:370-383`), fetches all default-enchantment definitions in parallel
    (`:385-418`), maps the blueprint to a real `ItemStack` via
    `ItemBlueprintBukkitMapper.fromBlueprint`, applies each default
    enchantment (custom-lore or vanilla-unsafe as appropriate, skipping and
    reporting any that fail resolution/exceed max level,
    `:212-292`), then **adds the item to the target player's inventory**
    (dropping on the ground on overflow, `:279-281`). Console senders must
    specify a target player explicitly (`:182-188`).
- **Feature allocation:** `items`/`item-blueprints`
- **Status:** Finished, admin-facing (this is the only command tree that
  actually spawns real, enchanted items for a player from server-defined
  blueprints — relevant precedent for any future player-facing item-shop /
  reward feature).

---

## 4. `custom-enchantments` (`/ce` tree — separate from `/knk item enchantments`)

Dispatched via `EnchantmentCommandHandler.java` (root executor for `/ce`,
wired in `EnchantmentBootstrap.java:32-66`), which routes to per-subcommand
`EnchantmentSubcommand` implementations
(`EnchantmentCommandHandler.java:36-40`) and performs the permission check
generically before delegating (`EnchantmentCommandHandler.java:73-77`). This
is the **player-facing** enchantment tree (apply/remove/inspect enchantments
already on a held item, with cooldowns), distinct from `/knk item
enchantments`'s admin/debug catalog browsing and item-blueprint application.

### `/ce add <enchantment> <level>`
- **File:** `AddEnchantmentCommand.java`
- **Permission:** `customenchantments.command.add`
  (`AddEnchantmentCommand.java:36`), checked generically by the handler.
  **Additionally**, a second, dynamic per-enchantment check is performed
  inside the command itself: `customenchantments.<normalizedEnchantmentId>`
  via `EnchantmentCommandValidator.hasEnchantmentPermission`
  (`AddEnchantmentCommand.java:66`, validator at
  `EnchantmentCommandValidator.java:55-57`) — this is the dynamic
  per-enchantment node family `COMMAND_PERMISSION_SCAN.md` §3.4 already
  documents; confirmed here as specifically gating `/ce add`.
- **Goal/function:** Player-only, held-item required. Resolves the
  enchantment from `EnchantmentRegistry`, validates level ≤ enchantment's
  `maxLevel`, applies it via `EnchantmentRepository.applyEnchantment`
  (lore-based custom enchantment), then reorders lore so enchantment lines
  sort first (`AddEnchantmentCommand.java:40-135`).
- **Feature allocation:** `custom-enchantments`
- **Status:** Finished, player-facing (subject to holding both the root
  `.add` node and the specific enchantment's own node).

### `/ce remove <enchantment>`
- **File:** `RemoveEnchantmentCommand.java`
- **Permission:** `customenchantments.command.remove`
  (`RemoveEnchantmentCommand.java:36`) — **no** dynamic per-enchantment check
  here (unlike `add`); removal is gated only by the root node.
- **Goal/function:** Player-only, held-item required. Strips the named
  enchantment's lore lines via `EnchantmentRepository.removeEnchantment`
  (`RemoveEnchantmentCommand.java:40-82`).
- **Feature allocation:** `custom-enchantments`
- **Status:** Finished, player-facing.

### `/ce info [player]`
- **File:** `InfoEnchantmentCommand.java`
- **Permission:** `customenchantments.command.info`
  (`InfoEnchantmentCommand.java:43`) for the base command. `plugin.yml:212-214`
  additionally declares `customenchantments.command.info.others` for viewing
  another player's item — **but this node is never checked in
  `InfoEnchantmentCommand.execute`** (`InfoEnchantmentCommand.java:47-107`):
  passing a `[player]` argument goes straight to `Bukkit.getPlayerExact`
  with no permission gate on that branch. The node **is** referenced, but
  only inside `tabComplete` (`InfoEnchantmentCommand.java:110-120`), gating
  whether online-player names are suggested — it does not gate execution.
  This is a real enforcement gap: any holder of the base `.info` node can
  view any online player's held-item enchantments by name, regardless of
  whether they hold `.info.others`.
- **Goal/function:** Reads the target's held-item lore, parses custom
  enchantments via `EnchantmentRepository.getEnchantments`, and for each
  prints display name/level/id/remaining cooldown (via
  `CooldownManager.getRemainingCooldown`, `InfoEnchantmentCommand.java:71-104`).
  Pure read, no mutation.
- **Feature allocation:** `custom-enchantments`
- **Status:** Finished, player-facing, but with the permission-enforcement
  gap noted above (worth flagging for the v3 permission-system work, since
  `COMMAND_PERMISSION_SCAN.md` lists `.info.others` as an existing node
  without noting it's unenforced at the command level).

### `/ce cooldown clear [player]`
- **File:** `ClearCooldownCommand.java`, routed through a special two-level
  dispatch in `EnchantmentCommandHandler.onCommand`
  (`EnchantmentCommandHandler.java:54-61`: `args[0]=="cooldown"`,
  `args[1]=="clear"` → registry key `"cooldown-clear"`).
- **Permission:** `customenchantments.command.cooldown.clear`
  (`ClearCooldownCommand.java:34`) for clearing your own; **this one does
  correctly check** `customenchantments.command.cooldown.clear.others`
  before honoring an explicit `[player]` target
  (`ClearCooldownCommand.java:48-51`) — contrast with `/ce info` above,
  which declares but doesn't enforce its `.others` node.
- **Goal/function:** Clears all of the target's custom-enchantment cooldowns
  via `CooldownManager.clearCooldowns` (`ClearCooldownCommand.java:38-67`).
- **Feature allocation:** `custom-enchantments`
- **Status:** Finished, player-facing (self) / admin-facing (others).

### `/ce reload`
- **File:** `ReloadEnchantmentCommand.java`
- **Permission:** `customenchantments.command.reload`
  (`ReloadEnchantmentCommand.java:19`)
- **Goal/function:** Calls `EnchantmentConfigManager.reload()` — reloads the
  plugin's enchantment config/messages from disk (`ReloadEnchantmentCommand.java:22-27`).
- **Feature allocation:** `custom-enchantments` / `world-admin`
- **Status:** Finished, admin-facing ops tool.

### Supporting infra (not directly invocable)
- `EnchantmentCommandValidator.java` — shared held-item/player/level
  validation plus `hasEnchantmentPermission` (the dynamic-node check used by
  `add`).
- `EnchantmentSubcommand.java` — the interface each `/ce` subcommand
  implements (`name()`, `permission()`, `execute()`, optional
  `tabComplete()`).

---

## 5. `inventory-menus`

### `/knk menu open|page|search|filter|broken`
- **File:** `MenuDebugCommand.java`, registered as `menu` **only if
  `menuService != null`** (`KnkAdminCommand.java:238-259`) — conditionally
  wired.
- **Permission:** `knk.admin.menu` (`KnkAdminCommand.java:246`) for the
  registered-command gate; `broken` doesn't require player-only status and
  is reachable by any sender who passes that same gate
  (`MenuDebugCommand.java:42-45`).
- **Subcommands:**
  - `open <key>` — `MenuService.openMenu(player, key)` (`:59-64`).
  - `page next|prev <sectionName>` — `MenuService.nextPage`/`previousPage`
    (`:66-78`).
  - `search <sectionName> [clear]` — `MenuService.promptSearch` or
    `clearSearch` (`:79-90`).
  - `filter <sectionName> <facetKey> [clear]` — `MenuService.promptFilter`
    or `clearFilter` (`:91-103`).
  - `broken` — lists menus blocked at startup validation by
    `MenuDefinitionValidationRunner`, reading `MenuService.blockedMenus()`
    (`:114-127`); this is the only subcommand usable by non-player senders.
- **Goal/function:** Explicitly a **dev harness**, per its own extensive
  javadoc (`MenuDebugCommand.java:10-31`): "no real menu content exists yet
  to trigger this from" — the only way to open/exercise a menu
  (assembly/layout/pagination/search-filter/async-rendering) on a live
  server pending the InventoryMenu feature's real trigger points. As of
  IMPLEMENTATION_PLAN Phase 7 / QOL_BUGFIX_BACKLOG item 8 (per the same
  javadoc), real clickable Next/Previous/Search/Filter buttons now also
  exist inside `example.presets` going through the identical `MenuService`
  methods — this command is kept registered as an explicit "optional
  fallback," not the primary path, useful for scripting/macros and
  not-yet-buttoned sections.
- **Feature allocation:** `inventory-menus`
- **Status:** Debug/dev-only tool by explicit design, not a finished
  player-facing feature (no real menu content is wired to trigger it from
  yet, per the javadoc).

---

## 6. `world-tasks` (WorldTask claim/status system)

### `/knk tasks [status]`
- **File:** `KnkTaskListCommand.java`, registered as `tasks`
  (`KnkAdminCommand.java:282-287`)
- **Permission:** `knk.tasks` (`KnkAdminCommand.java:284`) — **not declared
  in `knk.admin`'s children list**, and declared separately in `plugin.yml`
  at `plugin.yml:123-125` with `default: op` (confirmed consistent with
  `COMMAND_PERMISSION_SCAN.md` §3.2's finding that `tasks`/`task-claim`/
  `task-status` are the one exception to the flat `knk.admin` gate).
- **Goal/function:** Lists `WorldTasksApi.listByStatus(status)` (default
  `"Pending"` if omitted), color-coded by status, showing link code
  prominently for Pending tasks (`KnkTaskListCommand.java:27-77`). Read-only.
- **Feature allocation:** `world-tasks`
- **Status:** Finished, admin-facing.

### `/knk task-claim <id|linkCode>` and `/knk itemscan claim <linkCode>`
- **File:** `KnkTaskClaimCommand.java`, registered as `task-claim`
  (`KnkAdminCommand.java:289-294`) and again — same handler instance,
  different entry point — as `itemscan claim <linkCode>`
  (`KnkAdminCommand.java:296-310`, explicitly documented as "a faster second
  way in ... both ultimately invoking the exact same claim/handler-dispatch
  logic," no duplicated business logic).
- **Permission:** `knk.tasks` for both entry points
  (`KnkAdminCommand.java:291,301`).
- **Goal/function:** Player-only. Resolves the task by numeric ID or link
  code (warns if using a numeric ID, recommending the link code "for better
  security," `KnkTaskClaimCommand.java:54-56`), verifies it's still
  `"Pending"`, calls `WorldTasksApi.claim(taskId, linkCode, serverId,
  playerName)`, then **dispatches to `WorldTaskHandlerRegistry.startTask`**
  to hand off to whatever per-task-type handler is registered (e.g. item
  scanning), warning if no handler exists for that task type
  (`KnkTaskClaimCommand.java:36-125`).
- **Feature allocation:** `world-tasks` (with the `itemscan` alias also
  touching `items` per `docs/specs/items/IMPLEMENTATION_PLAN.md §5.1`, cited
  in the code comment at `KnkAdminCommand.java:296-299`)
- **Status:** Finished, player-facing.

### `/knk task-status <id|linkCode>`
- **File:** `KnkTaskStatusCommand.java`, registered as `task-status`
  (`KnkAdminCommand.java:312-317`)
- **Permission:** `knk.tasks` (`KnkAdminCommand.java:314`)
- **Goal/function:** Resolves by ID or link code, prints full status detail:
  status (color-coded), entity type/field, link code, workflow session id,
  step number, claimed-by (username+server+timestamp), completed-at, error
  message, and truncated input/output JSON (`KnkTaskStatusCommand.java:26-107`).
  Read-only.
- **Feature allocation:** `world-tasks`
- **Status:** Finished, player-facing.

---

## 7. `world-admin` / `health` / `cache` (ops tooling)

### `/knk health`
- **File:** `HealthCommand.java`, registered as `health`
  (`KnkAdminCommand.java:99-103`)
- **Permission:** `knk.admin.health` (`KnkAdminCommand.java:101`)
- **Goal/function:** Async `HealthApi.getHealth()` call; reports healthy/
  unhealthy status + version, or a detailed error breakdown (HTTP status,
  URL, response body, or connection-exception class name) on failure
  (`HealthCommand.java:26-95`). Pure read/diagnostic.
- **Feature allocation:** `world-admin`/`health`
- **Status:** Finished, admin-facing.

### `/knk cache`
- **File:** inline lambda in `KnkAdminCommand.java:106-114` — **no dedicated
  class**, only registered if `cacheManager != null`.
- **Permission:** `knk.admin.cache` (`KnkAdminCommand.java:108`)
- **Goal/function:** Prints `CacheManager.getHealthSummary()` directly
  (color-translated). Read-only.
- **Feature allocation:** `world-admin`/`health`/`cache`
- **Status:** Finished, admin-facing.

### `/knk help [command]`
- **File:** `HelpSubcommand.java`, registered as `help`
  (`KnkAdminCommand.java:327-331`)
- **Permission:** none (`null` in metadata, `KnkAdminCommand.java:328`) —
  but the command list it prints is itself permission-filtered per viewer
  via `CommandRegistry.listAvailable` (`HelpSubcommand.java:28`,
  `CommandRegistry.java:46-50`).
- **Goal/function:** Lists all subcommands the sender can see, or full
  detail (description/usage/permission/examples) for one named subcommand
  (`HelpSubcommand.java:18-98`). See the dead-code note in §3 above re: its
  now-unreachable `"enchantments"`-specific extra-help branch
  (`HelpSubcommand.java:74-97`).
- **Feature allocation:** `world-admin` (meta/UX)
- **Status:** Finished, admin-facing, with one confirmed dead branch.

### `/knk wgm rename <oldRegionId> <newRegionId>` — unreachable
- Covered in §0 above. `WorldGuardManagementCommand.java` implements
  `WgRegionIdTaskHandler.renameRegion` dispatch but is never registered to
  any Bukkit command. **Dead code**, not currently a real command surface at
  all — included here per the task's instruction not to skip files, and
  because its stated purpose ("typically called by the Web API," per its own
  javadoc) makes it look like intended machinery for a feature that may not
  have finished being wired up, rather than abandoned cruft.
- **Feature allocation:** `world-admin` (WorldGuard region management)
- **Status:** Unwired / non-functional as a command today.

---

## 8. Cross-cutting findings for the v3 command catalog

1. **`/account create` is documented but not implemented.** Both the
   permission node (`knk.account.create`, `plugin.yml:184-186`) and two
   pieces of in-code documentation (`AccountCommandRegistry.java:19,74`)
   describe a `create` subcommand that does not exist in the registry
   (`AccountCommandRegistry.java:45-54` only registers `status`/`view` and
   `link`). Anyone designing v3 account-creation flows should treat this as
   greenfield, not "extend existing code."
2. **Account-merge flow is fully built but unreachable.**
   `AccountLinkCommand.startMergeFlow`/`mergeAccounts`
   (`AccountLinkCommand.java:201-263`) implement the entire chat-driven
   duplicate-account merge UX via `ChatCaptureManager`, but nothing calls
   `startMergeFlow`. `AccountCommand.java:59-62` tells players with a
   duplicate account to use `/account link` to resolve it, but that command's
   actual code path (`AccountLinkCommand.onCommand` →
   `generateLinkCode`/`consumeLinkCode`) never reaches the merge flow. This
   is likely either an in-progress feature or an accidental regression during
   a refactor — worth a direct question to whoever owns account linking.
3. **`/ce info [player]`'s `.others` permission is declared but not
   enforced** at the point that matters (command execution), only at
   tab-completion (`InfoEnchantmentCommand.java:47-120` vs. the correctly-
   enforced sibling `/ce cooldown clear [player]` in
   `ClearCooldownCommand.java:48-51`). This is a concrete example of exactly
   the kind of per-command permission-granularity gap the new rank/permission
   system (per `COMMAND_PERMISSION_SCAN.md` §5) will need to either fix or
   consciously carry forward.
4. **`/knk item enchantments` merge left dead help-text code behind.**
   `HelpSubcommand.java:74-97`'s extended help block keys off
   `meta.name().equalsIgnoreCase("enchantments")`, which can never match
   post-merge (the registered command is named `"item"`). Low-stakes but a
   real gap: `/knk help item` no longer shows the enchantments-specific
   subcommand/search-field/apply-notes detail that block used to provide.
5. **`WorldGuardManagementCommand` is unregistered dead code** (§0, §7) —
   either finish wiring it to a Bukkit command (its own usage string implies
   `/knk wgm rename ...`) or remove it; as-is it can't be reached in-game at
   all, despite being a complete, tested-looking implementation.
6. **`/knk gate` is the most actively-evolving command tree in the codebase**
   by comment density — javadocs throughout `GateCommand.java` reference
   specific, named implementation items and decisions ("Item 5," "decision
   5.0-D," "decision 5.0-B") from
   `docs/features/gate-structure-animation/GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md`,
   and its own admin-override subcommand explicitly calls out fields
   supported by the underlying model/API but not yet exposed at the command
   level (`GateCommand.java:636-640`) — a concrete "add a case here" hook for
   future work (e.g. a Siege capture-destroys-all-doors event, named
   directly in that same comment).

### `/menu` — the InventoryMenu hub (added 2026-09-25, content port CP1)
- **File:** `MenuCommand.java`, registered with `registerSimpleCommand("menu", …)` in `KnKPlugin`.
- **Permission:** `knk.menu` (plugin.yml, `default: true`) on the command itself.
- **Behaviour:** player-only; `MenuService.openMenu(player, "main", ctx = empty)` — opened from
  outside a menu, so navigation starts fresh and the hub's Back button reads "Exit". The hub shows one
  tile per ported feature (Profile, Kits, Sieges, Item catalogue, Premium tiers, Player manager),
  each only while its target menu passed startup validation (`menu-available`). Not live-verified.
  Details: `docs/specs/inventory-menu/CONTENT_PORT_PLAN.md` CP1.
- **Feature allocation:** `inventory-menus` (content port).
- **Status:** Implemented on `claude/menu-content`, not merged/live-verified.

---

## Appendix: full command inventory (flat list)

| Command | Domain | Status |
|---|---|---|
| `/account` (`status`/`view`) | users/account | Finished |
| `/account link [code]` | users/account | Finished (merge sub-flow dead) |
| `/account create` | users/account | **Not implemented** |
| `/ownermode`, `/staffmode` | users/account | Finished |
| `/knk health` | world-admin | Finished |
| `/knk cache` | world-admin | Finished |
| `/knk towns list`, `/knk town <id>` | towns | Finished (debug) |
| `/knk districts list`, `/knk district <id>` | towns | Finished (debug) |
| `/knk streets list`, `/knk street <id>` | towns | Finished (debug) |
| `/knk locations list`, `/knk locations <id>` | towns | Finished (debug) |
| `/knk location here` | towns | Finished (debug) |
| `/knk item rename` | items | Finished |
| `/knk item lore add\|set\|remove` | items | Finished |
| `/knk item enchantments list\|vanilla\|search\|apply` | custom-enchantments/items | Finished (debug) |
| `/knk itemblueprints list\|search\|get\|give` | items/item-blueprints | Finished |
| `/knk menu open\|page\|search\|filter\|broken` | inventory-menus | Dev harness |
| `/menu` | inventory-menus | Implemented on `claude/menu-content` (2026-09-25), not live-verified |
| `/knk streets`/`street` | towns | (listed above) |
| `/knk tasks [status]` | world-tasks | Finished (debug) |
| `/knk task-claim`, `/knk itemscan claim` | world-tasks | Finished |
| `/knk task-status` | world-tasks | Finished |
| `/knk gate open\|close\|info\|list\|passthrough` | gate-structure-animation | Finished |
| `/knk gate door capture\|redefine` | gate-structure-animation | Finished |
| `/knk gate admin health\|repair\|tp\|reload\|active\|invincible\|override` | gate-structure-animation | Finished |
| `/knk help [command]` | world-admin | Finished (1 dead branch) |
| `/knk wgm rename` | world-admin | **Unwired/dead** |
| `/ce add <ench> <lvl>` | custom-enchantments | Finished |
| `/ce remove <ench>` | custom-enchantments | Finished |
| `/ce info [player]` | custom-enchantments | Finished (permission gap) |
| `/ce cooldown clear [player]` | custom-enchantments | Finished |
| `/ce reload` | custom-enchantments | Finished |
