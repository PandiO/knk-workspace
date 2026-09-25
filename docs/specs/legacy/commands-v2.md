# v2 command catalog (Minecraft commands, ACF `BaseCommand` classes)

> Companion to [commands-v1.md](commands-v1.md) — same purpose (fill the command-inventory gap left by the original legacy-spec-mining pass), same citation convention. See that doc's header for the full rationale. For the passive/reactive half of v2's behavior (Bukkit event listeners), see [events-v2.md](events-v2.md).

Mined from `knk-v2-archive`, working tree as checked out under `Repository/knk-v2-archive` (read directly from the
main checkout, not the isolated agent worktree, since the three component repos live outside this git
worktree's history). Citation convention matches `docs/specs/legacy/user-system.md`: `v2:src/main/java/...:line`.

## Methodology

`grep`/`find` for `*Command*.java` under `v2/src/main/java` returns ~63 files, but only the 35 under
`net.knightsandkings.spigot.command.**` extend ACF's `co.aikar.commands.BaseCommand` and are actually
registered Bukkit/ACF player-facing commands (confirmed via `@CommandAlias` on the class and registration
through `plugin.yml`'s `commands:` block). The remaining ~28 files matching `*Command*.java` — everything
under `net.knightsandkings.command.**` (e.g. `TransportExecutionCommand`, `PersistCommand`,
`MenuOpenCommand`, `GenerationCommand` (the internal one, not `spigot.command.dominion.structure.GenerationCommand`))
— implement `net.knightsandkings.command.Command<T>` (`v2:src/main/java/net/knightsandkings/command/Command.java:20`,
`implements Callable<T>, Runnable`), an internal undo/redo "Command pattern" used for transactional
DAO/generation/transport operations. These are invoked from inside other code (including from a couple of the
real Bukkit commands below, e.g. `TestCommand`'s `transportpreperation` subcommand), not typed by a player at
the chat prompt, and are out of scope for a *Minecraft command* catalog — they're listed here once, by name,
so a future reader isn't left wondering why they were skipped, but they get no further treatment.

Every command class below was read in full (not excerpted) directly from
`v2:src/main/java/net/knightsandkings/spigot/command/**`. `plugin.yml` (`v2:src/main/resources/plugin.yml`)
was read in full for the top-level per-command permission node table; note that **the repo's working tree
currently contains three `plugin.yml` copies** (`src/main/resources/plugin.yml`, plus stale build outputs at
`bin/src/main/resources/plugin.yml` and `target/classes/plugin.yml`, both of which are older/partial versions
missing the `fly`/`gamemode`/`inventory`/`heal`/`feed` entries) — citations below are to the live
`src/main/resources/plugin.yml` only.

One methodology note on divergence from `user-system.md`: that doc's bug #9 (`Enderchest.opCheck`
dereferencing a null `target`) cites `v2:...Enderchest.java:78,88` for a live NPE. Reading the file now shows
that entire code path — including those two lines — is commented out, and the method instead unconditionally
sends "This command is currently not supported due to update errors from 1.16 to 1.21." This isn't a
contradiction: the lines still exist at those numbers inside the comment block, so the citation is accurate to
the text, but the bug is **not reachable at runtime** in the current tree — the whole feature was disabled,
not fixed. Recorded as its own finding below (§Users, `Enderchest.opCheck`) rather than repeating bug #9
verbatim, since "commented-out dead branch" and "reachable NPE" are materially different findings for a v3
design audience.

Legend: **Perm** = exact `@CommandPermission` string(s) checked (class-level, then method/subcommand-level if
overridden); "(none)" means no additional `@CommandPermission` beyond what's inherited from the class.

---

## 1. `users` domain

### `/user` (aliases `u`, `user`) — `net.knightsandkings.spigot.command.user.UserCommand`
Class perm: `k&k.user` (`v2:...UserCommand.java:24`). `plugin.yml` top-level: `user: permission: k&k.user`
(`v2:src/main/resources/plugin.yml:9-11`).

| Subcommand | Syntax | Perm | Goal |
|---|---|---|---|
| `list` (also `@Default`) | `/user` or `/user list` | `k&k.user.list` (`:34`) | Fetches caller's own `User`, then lists **every** `User` object in the repository (`RepositoryManager...getRepository(User.class,...).getList()`), printing each via `toString()`. No pagination. `v2:...UserCommand.java:31-64`. |
| `fetch\|f` | `/user fetch <username>` | `k&k.user.fetch` (`:68`) | **Stub/incomplete** — declares a `String username` param (with `@CommandCompletion("@usernames")`) but the method body never references `username` at all; it fetches only the caller's own `User` and does nothing further. Confirms `user-system.md` bug #10 still holds verbatim in the current tree. `v2:...UserCommand.java:66-79`. |
| `save\|s` | `/user save <onlineuser>` | `k&k.user.save` (`:83`) | Saves the resolved target `User` object to the DB via the repository, with try/catch success/failure messaging. `v2:...UserCommand.java:81-101`. |
| `statistics\|stats` | `/user statistics <userid>` | `k&k.user.statistics` (`:105`) | Resolves a `UserStatistics` object (ACF-parsed straight from the argument, so the completion `@userids` is actually keyed off `UserStatistics`, not `User`) and prints its `toString()` to the caller. `v2:...UserCommand.java:103-115`. |

### `/enderchest` (alias `ec`) — `net.knightsandkings.spigot.command.user.Enderchest`
Class perm: `k&k.enderchest` (`v2:...Enderchest.java:27,31`). `plugin.yml`: `enderchest: permission: k&k.enderchest`
(`:62-63`).

| Subcommand | Syntax | Perm | Goal |
|---|---|---|---|
| `@Default` | `/enderchest` | (none beyond class) | Opens the **caller's own** enderchest inventory. `v2:...Enderchest.java:40-44`. |
| `open\|o` | `/enderchest open <onlineuser>` | `k&k.enderchest.open` (`:48`) | Opens an **online** target player's live enderchest inventory (`target.getPlayer().getEnderChest()`) for the caller to view/edit; null-guards if the target has no live `Player` object. `v2:...Enderchest.java:46-58`. |
| `check\|c` | `/enderchest check <username>` | `k&k.enderchest.check` (`:62`) | **Disabled, not just incomplete.** The real offline-lookup logic (constructing a `GameProfile`/`EntityPlayer` via NMS to view an *offline* player's enderchest) is entirely commented out; the live method body only sends `"This command is currently not supported due to update errors from 1.16 to 1.21."` — a self-documented regression from a 1.16→1.21 Spigot API break, not the original `user-system.md`-cited NPE (see Methodology). `v2:...Enderchest.java:60-89`. |

---

## 2. `towns` domain (dominions, districts, towns, streets, gates, structures, storage, generation)

All of `DominionCommand`, `StructureCommand`, `TownCommand`, `DistrictCommand`, `StreetCommand`, `GateCommand`,
`StorageCommand` share one shape: `list`/`fetch`/`save`/`remove`/`edit`, backed by
`RepositoryManager.getInstance().getRepository(<Type>.class, <KeyClass>).*`. `edit` in every one of them just
kicks off a `Creation` "creation wizard" session (`new Creation(user, <object>)`) rather than editing anything
itself — the actual field-by-field edit flow lives in the `Creation`/menu system, out of scope here (see
`docs/specs/legacy/inventory-menus.md`). Per-command deltas from that shared shape are called out below;
otherwise treat `list`/`fetch`/`save`/`remove`/`edit` as "CRUD against the Dominion/Structure hierarchy,
gated one node per subcommand, `<basePerm>.<subcommand>`."

### `/dominion` — `net.knightsandkings.spigot.command.dominion.DominionCommand`
Class perm: `k&k.dominion` (`v2:...DominionCommand.java:42`). `plugin.yml`: `k&k.dominion` (`:18-19`).

| Subcommand | Syntax | Perm | Goal / notes |
|---|---|---|---|
| `list\|l` (`@Default`) | `/dominion` | `k&k.dominion.list` | Lists all `Dominion` objects. `v2:...DominionCommand.java:49-67`. |
| `fetch\|f` | `/dominion fetch <id> <method 1-4>` | `k&k.dominion.fetch` | **Debug/scratch command left in production code.** Takes a second `method` int (1-4) that switches between four different Hibernate query strategies for fetching one `Dominion` by id, with inline doc-comments recording that methods 2 and 4 (native SQL) **throw** (`MySQLSyntaxErrorException`/`SQLException`) and only 1 and 3 actually work, "Reason unknown" in both cases. `v2:...DominionCommand.java:69-147`. |
| `save\|s` | `/dominion save <onlinedominion>` | `k&k.dominion.save` | Standard save. `:171-191`. |
| `remove\|r` | `/dominion remove <id>` | `k&k.dominion.remove` | Standard delete. `:193-213`. |
| `edit\|e` | `/dominion edit <onlinedominion>` | `k&k.dominion.edit` | Starts `Creation` wizard. `:215-241`. |
| `resetflags` | `/dominion resetflags` | `k&k.dominion.resetflags` | Iterates **every** `Dominion` in the repository and calls `updateRegionFlags()` on each — a bulk WorldGuard-region-flag reset, admin/maintenance tool. `:243-259`. |
| `seed` | `/dominion seed` | `k&k.dominion.seed` | Runs `TestData.getInstance().populate()` to bulk-insert seed/test data; on exception, unwinds via `.unExecute()` on everything already run. Large blocks of alternate seeding strategies are commented out above it. Dev/test-only command shipped live. `:261-306`. |
| `townseed` | `/dominion townseed` | `k&k.dominion.seed` (same node as `seed`, not its own) | Narrower seed: inserts one `TestTown` via `PopulateObjectType`. Same dev/test-only character. `:308-357`. |
| `test\|t` | `/dominion test` | `k&k.dominion.test` | Fetches the `GenerationDAO` and dumps `getGenerationEntityList()` to the sender — a raw debug/introspection command. `:359-381`. |

### `/dominion` (again) — `net.knightsandkings.spigot.command.dominion.structure.StructureCommand`
**Class-level alias collision:** this class is *also* annotated `@CommandAlias("dominion")`
(`v2:...StructureCommand.java:27`), identical to `DominionCommand`'s alias. Two different `BaseCommand`
classes registering the same top-level alias is not a normal ACF pattern (ACF typically merges/overwrites
registrations under one alias); which one's `@Default`/subcommands actually win at runtime wasn't traced
further (would require tracing ACF's `CommandManager` registration order) — flagged as **unclear/likely a
copy-paste bug** (`StructureCommand` almost certainly meant to have no `@CommandAlias` of its own, or a
distinct one like `structure`, matching its own `k&k.structure` permission nodes below and its own
`plugin.yml`-declared `structure: permission: k&k.structure` entry, `:67-68`). Class perm annotation:
`k&k.dominion` (`v2:...StructureCommand.java:28`) — also copy-pasted from `DominionCommand` rather than using
`k&k.structure`.

| Subcommand | Syntax | Perm | Goal / notes |
|---|---|---|---|
| `list\|l` (`@Default`) | `/dominion` (or `/structure`, per above ambiguity) | `k&k.structure.list` | Lists all `Structure` objects. `:35-52`. |
| `fetch\|f` | `... fetch <id>` | `k&k.structure.fetch` | Standard fetch. `:54-75`. |
| `save\|s` | `... save <onlinestructure>` | `k&k.structure.save` | Standard save. `:99-119`. |
| `remove\|r` | `... remove <id>` | `k&k.structure.remove` | **Bug:** deletes through the wrong repository — `RepositoryManager...getRepository(Gate.class, Dominion.KEY_CLASS).deleteObject(structure)`, passing a `Structure` instance into a `Gate` repository's delete call, instead of `Structure.class`. Copy-paste artifact from `GateCommand`/similar. `v2:...StructureCommand.java:135`. |
| `edit\|e` | `... edit <onlinestructure>` | `k&k.structure.edit` | Starts `Creation` wizard. `:143-169`. |
| `resetflags` | `... resetflags` | `k&k.structure.resetflags` | Bulk `updateRegionFlags()` over all `Structure` objects, same pattern as `DominionCommand`. `:171-187`. |

### `/town` — `net.knightsandkings.spigot.command.dominion.town.TownCommand`
Class perm: `k&k.dominion.town` (`v2:...TownCommand.java:29`). `plugin.yml`: `town: permission: k&k.town`
(`:22-23`, confirmed correct) — **mismatch**: the in-code class-level annotation (`k&k.dominion.town`) does not match the
`plugin.yml` top-level node (`k&k.town`); Bukkit's own top-level command-permission gate uses the `plugin.yml`
value, while ACF's own class-level `@CommandPermission` is what actually fires per the annotation processor —
in practice this likely means the `plugin.yml` node is unused/inert since ACF handles gating itself, but it's
one more instance of the two permission mechanisms disagreeing on the string (also true for `district`/`tag`
below).

| Subcommand | Syntax | Perm | Goal / notes |
|---|---|---|---|
| `list\|l` (`@Default`) | `/town` | `k&k.dominion.town.list` | Lists all `Town` objects. `:37-54`. |
| `fetch\|f` | `/town fetch <id>` | `k&k.dominion.town.fetch` | Standard fetch. `:56-77`. |
| `save\|s` | `/town save <onlinetown>` | `k&k.dominion.town.save` | Standard save. `:79-99`. |
| `remove\|r` | `/town remove <id>` | `k&k.dominion.town.remove` | Standard delete. `:101-121`. |
| `edit\|e` | `/town edit <onlinetown>` | `k&k.dominion.town.edit` | Starts `Creation` wizard. `:123-149`. |
| `test` | `/town test` | `k&k.town.test` (note: **not** prefixed `k&k.dominion.town.test` like every sibling — inconsistent node) | Constructs a throwaway `TestTown` test object and saves it to cache then DB, printing progress messages; pure dev/debug command. `v2:...TownCommand.java:151-186`. |

### `/district` — `net.knightsandkings.spigot.command.dominion.district.DistrictCommand`
Class perm: `k&k.dominion.district` (`v2:...DistrictCommand.java:34`). `plugin.yml`: `district: permission: k&k.district`
(`:24-25`, confirmed correct) — same node-mismatch pattern as `/town`.

| Subcommand | Syntax | Perm | Goal / notes |
|---|---|---|---|
| `list\|l` (`@Default`) | `/district` | `k&k.dominion.district.list` | Lists all `District` objects. `:42-62`. |
| `fetch\|f` | `/district fetch <id>` | `k&k.dominion.district.fetch` | Standard fetch. `:64-88`. |
| `save\|s` | `/district save <onlinedistrict>` | `k&k.dominion.district.save` | Standard save. `:90-102`. |
| `remove\|r` | `/district remove <id>` | `k&k.dominion.district.remove` | Standard delete. `:104-124`. |
| `edit\|e` | `/district edit <onlinedistrict>` | `k&k.dominion.district.edit` | Starts `Creation` wizard. `:126-152`. |
| `test` | `/district test <id>` | (none — inherits class perm only) | Builds two `VariableString` template instances (menu-variable interpolation test harness, e.g. `"$district.getId$"`) but **never sends or prints either result to the sender** — constructs them and discards them. Dead/no-op debug command. `v2:...DistrictCommand.java:154-161`. |

### `/street` — `net.knightsandkings.spigot.command.dominion.StreetCommand`
Class perm: `k&k.street` (`v2:...StreetCommand.java:29`). `plugin.yml`: `street: permission: k&k.street` (`:56-57`) — matches, no mismatch here.

| Subcommand | Syntax | Perm | Goal / notes |
|---|---|---|---|
| `list\|l` (`@Default`) | `/street` | `k&k.street.list` | Lists all `Street` objects, with debug timing logs around the fetch. `:36-56`. |
| `fetch\|f` | `/street fetch <id>` | `k&k.street.fetch` | Standard fetch. `:58-73`. |
| `save\|s` | `/street save <onlinestreet>` | `k&k.street.save` | Standard save. `:97-109`. |
| `remove\|r` | `/street remove <id>` | `k&k.street.remove` | Standard delete. `:111-125`. |
| `edit\|e` | `/street edit <onlinestreet>` | `k&k.street.edit` | Starts `Creation` wizard. `:127-153`. |
| `seed` | `/street seed` | `k&k.street.seed` | **Empty stub** — method body is completely empty. `v2:...StreetCommand.java:155-160`. |

### `/gate` — `net.knightsandkings.spigot.command.dominion.structure.GateCommand`
Class perm: `k&k.dominion.structure.gate` (`v2:...GateCommand.java:35`). `plugin.yml`: `gate: permission: k&k.dominion.structure.gate`
(`:30-31`) — matches.

| Subcommand | Syntax | Perm | Goal / notes |
|---|---|---|---|
| `list\|l` (`@Default`) | `/gate` | `k&k.dominion.structure.gate.list` | Lists all `Gate` objects. `:45-75`. |
| `fetch\|f` | `/gate fetch <id>` | `k&k.dominion.structure.gate.fetch` | Standard fetch. `:77-98`. |
| `save\|s` | `/gate save <gate>` | `k&k.dominion.structure.gate.save` | Standard save. `:100-113`. |
| `remove\|r` | `/gate remove <id>` | `k&k.dominion.structure.gate.remove` | Standard delete. `:115-135`. |
| `edit\|e` | `/gate edit <gate>` | `k&k.dominion.structure.gate.edit` | Starts `Creation` wizard. `:137-163`. |
| `toggle` | `/gate toggle <gate>` | `k&k.dominion.structure.gate.toggle` | The one **real gameplay action** in this class: calls `gate.toggleOpened()` to open/close the physical gate structure. Everything else here is CRUD/admin. `v2:...GateCommand.java:165-183`. |

### `/storage` — `net.knightsandkings.spigot.command.dominion.structure.StorageCommand`
Class perm: `k&k.storage` (`v2:...StorageCommand.java:32`). `plugin.yml`: `storage: permission: k&k.storage` (`:52-53`).

| Subcommand | Syntax | Perm | Goal |
|---|---|---|---|
| `list\|l` (`@Default`) | `/storage` | `k&k.storage.list` | Lists all `Storage` objects. `:43-60`. |
| `fetch\|f` | `/storage fetch <id>` | `k&k.storage.fetch` | Standard fetch. `:62-76`. |
| `save\|s` | `/storage save <storage>` | `k&k.storage.save` | Standard save. `:78-91`. |
| `remove\|r` | `/storage remove <id>` | `k&k.storage.remove` | Standard delete. `:93-113`. |
| `edit\|e` | `/storage edit <storage>` | `k&k.storage.edit` | Starts `Creation` wizard. `:115-141`. |

### `/generation` — `net.knightsandkings.spigot.command.dominion.structure.GenerationCommand`
Class perm field `PERM = "k&k.generation"` (`v2:...GenerationCommand.java:19`), applied at class level via
`@CommandPermission(GenerationCommand.PERM)` (`:16`). **Not present in `plugin.yml`'s `commands:` block at
all** — no top-level Bukkit permission gate, only the ACF one.

| Subcommand | Syntax | Perm | Goal / notes |
|---|---|---|---|
| `updates\|u` | `/generation updates <sub\|unsub\|subscribe\|unsubscribe\|s\|u>` | **Bug:** `@CommandPermission(PERM + "updates")` → produces the literal string `"k&k.generationupdates"` (missing the `.` separator present in every sibling command's `basePerm + ".subcommand"` pattern) — an unreachable/orphan permission node nobody can sensibly be granted by name. `v2:...GenerationCommand.java:26`. | Toggles the calling player's membership in `GenerationCommandListener.subscribers` (a static `Set<UUID>`), i.e. opts them in/out of receiving live "generation object" progress updates (structure/dominion generation pipeline notifications). Console senders are rejected. `:29-45`. |

---

## 3. `items` / `kits` domain

### `/item` — `net.knightsandkings.spigot.command.item.ItemCommand`
Class perm: `k&k.item` (`v2:...ItemCommand.java:36`). `plugin.yml`: **no top-level `item:` entry exists** —
only `itemtype`/`kit` are declared (`:26,42`), so `/item` has no Bukkit-level gate at all, ACF-only.

| Subcommand | Syntax | Perm | Goal / notes |
|---|---|---|---|
| `list\|l` (`@Default`) | `/item` | `k&k.item.list` | Lists all `Item` objects, **then** (unconditionally, not guarded behind a flag) also opens an `ItemOverview` menu GUI for the caller — a "list" command with a side-effecting GUI open baked in. **Bug:** casts `sender` straight to `Player` (`(Player)sender`) with no `instanceof` check first, unlike every sibling command — will throw `ClassCastException` if run from console. `v2:...ItemCommand.java:51-79`. |
| `fetch\|f` | `/item fetch <id>` | `k&k.item.fetch` | Standard fetch. `:81-96`. |
| `save\|s` | `/item save <onlineitem>` | `k&k.item.save` | Standard save. `:98-117`. |
| `remove\|r` | `/item remove <id>` | `k&k.item.remove` | Standard delete. `:119-139`. |
| `edit\|e` | `/item edit <onlineitem>` | `k&k.item.edit` | Starts `Creation` wizard. `:141-167`. |
| `get\|g` | `/item get <onlineuser> <itemid> <amount 0-64>` | `k&k.item.edit` (reuses the *edit* node, not its own `.get`) | Admin item-give: calls `target.giveItem(item, amount)` to hand a specific `Item` to a specified online target in the given quantity. `v2:...ItemCommand.java:169-192`. |
| `rename\|rn` | `/item rename <name...>` | `k&k.item.rename` | Renames the `ItemStack` currently in the caller's main hand via `ItemMeta.setDisplayName`, translating `&` colour codes to `§`. Vararg name is joined with spaces and trimmed. `:194-219`. |

### `/itemtype` (alias `it`) — `net.knightsandkings.spigot.command.item.ItemtypeCommand`
Class perm: `k&k.itemtype` (`v2:...ItemtypeCommand.java:28`). `plugin.yml`: `itemtype: permission: k&k.itemtype`
(`:20-21`).

| Subcommand | Syntax | Perm | Goal |
|---|---|---|---|
| `add` | `/itemtype add <hand\|click\|cancel>` | `k&k.itemtype.add` | Three-way dispatch on the string arg: `hand` registers the `Material`+`data` of the item currently in the caller's hand as a new `Itemtype` row (no-op with an error message if that Material/data combo is already registered); `click` starts an interactive `RegisterSession` (right-click a block within 5 seconds to register its type); `cancel` looks up and deletes the caller's pending `RegisterSession`. `v2:...ItemtypeCommand.java:39-84`. |
| `place` | `/itemtype place <itemtypeid>` | `k&k.itemtype.place` | Starts a `RegisterSession` keyed to a specific existing `Itemtype`, letting the caller right-click to place/set a block of that type — inverse of the `add`/`click` flow. `:86-106`. |
| `test` | `/itemtype test` | `k&k.itemtype.test` | Pure debug command: prints `PatternType`/`DyeColor` enum introspection info (banner-pattern and dye-colour internals) to the caller. Not itemtype-related at all despite living in this class. `:108-123`. |

### `/kit` — `net.knightsandkings.spigot.command.item.KitCommand`
Class perm: `k&k.item.kit` (`v2:...KitCommand.java:27,30`). `plugin.yml`: `kit: permission: k&k.item.kit` (`:50-51`).

| Subcommand | Syntax | Perm | Goal / notes |
|---|---|---|---|
| `list\|l` (`@Default`) | `/kit` | `k&k.item.kit.list` | Lists all `Kit` objects. `:35-65`. |
| `fetch\|f` | `/kit fetch <id>` | `k&k.item.kit.fetch` | Standard fetch. `:67-88`. |
| `save\|s` | `/kit save <kitname>` | `k&k.item.kit.save` | Standard save. `:90-109`. |
| `remove\|r` | `/kit remove <id>` | `k&k.item.kit.remove` | Standard delete. `:111-131`. |
| `edit\|e` | `/kit edit <kitname>` | `k&k.item.kit.edit` | **Bug:** starts a `Creation` wizard but then saves the resulting `Creation` object into the **`RegisterSession` repository** instead of the `Creation` repository (`RepositoryManager...getRepository(RegisterSession.class, RegisterSession.KEY_CLASS).saveObject(creation, ...)`), a copy-paste artifact — the edit session is cached under the wrong key type entirely. `v2:...KitCommand.java:149`. Same exact bug pattern (and near-identical surrounding code) also appears in `MGObjectiveCommand.onEdit`, `MGScenarioCommand.onEdit`, `MGTeamCommand.onEdit`, `SiegeObjectiveCommand.onEdit`, `SiegeScenarioCommand.onEdit`, `SiegeTeamCommand.onEdit` — see §4/§5, all six repeat it verbatim, suggesting the `edit` subcommand was copy-pasted across all minigame/kit-adjacent commands from one buggy template while `Dominion`/`Structure`/`Town`/etc.'s `edit` (which correctly targets the `Creation` repo) escaped the copy. |
| `give\|g` | `/kit give <onlineuser> <kitname>` | `k&k.item.kit.give` | Calls `kit.assignKit(target)` to grant the named kit's contents to a specified online target. `:161-184`. |
| `get\|g` | `/kit get <kitname>` | `k&k.item.kit.get` | Same as `give` but self-targeted (`kit.assignKit(user)`, caller only). Note both `give` and `get` share the alias `g` in their `@Subcommand` strings, which is themselves distinct subcommand paths (`give|g` vs `get|g`) — ACF likely resolves the bare `g` alias to whichever is registered last; not traced further. `:186-205`. |
| `test` | `/kit test <number>` | `k&k.item.kit.test` | Pure debug: computes and prints `Math.log(number)`. Unrelated to kits. `:207-219`. |

---

## 4. `inventory-menus` domain

### `/menu` — `net.knightsandkings.spigot.command.menu.MenuCommand`
Class perm: `k&k.menu.menu` (`v2:...MenuCommand.java:37,40`). `plugin.yml`: `menu: permission: k&k.menu.menu` (`:48-49`).

| Subcommand | Syntax | Perm | Goal |
|---|---|---|---|
| `@Default` | `/menu` | (none beyond class) | Opens the caller's `MainMenu` (the root inventory-menu GUI), passing their `previousMenu` for back-navigation. This is the one non-static instance method (`onDefault`, not `static void`) among all commands surveyed — every other command in the codebase uses `static void` handler methods. `v2:...MenuCommand.java:48-65`. |
| `test` | `/menu test` | `k&k.menu.menu.test` | Debug/scratch command: deletes the caller's cached `MenuSession`, then constructs and opens a `MenuOpenCommand` targeting the (differently-namespaced) `net.knightsandkings.menu.preset.menu.MainMenu` class — a **second, parallel** main-menu implementation from the newer `menu.preset` package, distinct from `model.menu.main.MainMenu` used by `@Default`. **Latent NPE risk:** the final line unconditionally calls `dm.getId()` even though `dm` can be left `null` if the `try` block throws (caught generically and logged, but execution falls through to the `finally` and then to the `getId()` call regardless). `v2:...MenuCommand.java:67-101`. |

Console senders are allowed into `test` (guarded with an `instanceof Player` check before resolving `User`) but not into `@Default` (raw `Player player` parameter type, ACF rejects non-players automatically before the method body runs).

---

## 5. `siege-minigame` domain

`MiniGame`/`Siege` and their `Objective`/`Scenario`/`Team` sub-entities each get their own near-identical
CRUD command class (`list`/`fetch`/`save`/`remove`/`edit`), exactly mirroring the towns-domain shape. All six
"detail" classes (`MGObjectiveCommand`, `MGScenarioCommand`, `MGTeamCommand`, `SiegeObjectiveCommand`,
`SiegeScenarioCommand`, `SiegeTeamCommand`) share the `edit`-saves-to-wrong-repository bug documented under
`/kit edit` above — not repeated per-row below, just the syntax/perm table.

### `/minigame` — `net.knightsandkings.spigot.command.minigame.MiniGameCommand`
Class perm: `k&k.minigame.minigame` (`v2:...MiniGameCommand.java:31,34`). `plugin.yml`: `minigame: permission: k&k.minigame.minigame`
(`:44-45`).

| Subcommand | Syntax | Perm | Goal / notes |
|---|---|---|---|
| `list\|l` (`@Default`) | `/minigame` | `k&k.minigame.minigame.list` | Lists all `MiniGame` objects. `:43-73`. |
| `new\|n` | `/minigame new` | `k&k.minigame.minigame.new` | **Deliberate stub** — throws `UnsupportedOperationException("This command has not been configured yet.")` unconditionally after the user-lookup guard. `v2:...MiniGameCommand.java:75-86`. |
| `remove\|r` | `/minigame remove <miniGame>` | `k&k.minigame.minigame.remove` | Deletes from cache only (`SaveMode.ONLY_CACHE`), sends success messages either way, but then **unconditionally throws** `new Exception("This method does not contain any functionality to properly stop and remove a MiniGame...")` regardless of whether the delete succeeded — a self-documented incomplete implementation (missing in-progress-game teardown) that always surfaces as a command failure to ACF even on the "success" path. `v2:...MiniGameCommand.java:88-111`. |
| `edit\|e` | `/minigame edit <miniGame>` | `k&k.minigame.minigame.edit` | **Deliberate stub**, same as `new` — sends a "Starting Creation process..." message and then unconditionally throws `UnsupportedOperationException`; the real `Creation`-wizard call is commented out below it. `:113-141`. |

### `/siege` — `net.knightsandkings.spigot.command.minigame.siege.SiegeCommand`
**Class perm bug:** annotated `@CommandPermission(MiniGameCommand.basePerm)` (`v2:...SiegeCommand.java:29`) —
i.e. `k&k.minigame.minigame`, the *MiniGame* command's own permission, not this class's own `basePerm` field
(`"k&k.minigame.siege.siege"`, declared right below at `:32` but never actually referenced anywhere in the
class). `plugin.yml` independently declares `siege: permission: k&k.minigame.siege.siege` (`:46-47`) — so the
top-level Bukkit gate and the ACF class-level gate check **two different permission nodes** for the same
command; whoever holds `k&k.minigame.minigame` (granted for `/minigame`) can pass `/siege`'s ACF-level check
regardless of whether they hold the documented `k&k.minigame.siege.siege` node.

| Subcommand | Syntax | Perm | Goal |
|---|---|---|---|
| `list\|l` (`@Default`) | `/siege` | `k&k.minigame.siege.siege.list` | Lists all `Siege` objects from cache. `v2:...SiegeCommand.java:38-68`. |
| `new\|n` | `/siege new` | `k&k.minigame.siege.siege.new` | Unlike `MiniGameCommand.onNew`, this one is **implemented**: constructs a hardcoded `new Siege("TestSiege", "/siege join TestSiege")` and verifies/caches it. The old `throw new UnsupportedOperationException(...)` line is left commented out directly below, showing this was upgraded from stub to (test-data-only) working code. `:70-92`. |
| `remove\|r` | `/siege remove <siege>` | `k&k.minigame.siege.siege.remove` | Calls `siege.stopSiege()`, deletes from cache, messages either way, then **unconditionally throws**, same pattern as `MiniGameCommand.onRemove`. `:94-119`. |
| `edit\|e` | `/siege edit <siege>` | `k&k.minigame.siege.siege.edit` | **Deliberate stub**, same pattern as `MiniGameCommand.onEdit` — always throws `UnsupportedOperationException`. `:121-149`. |
| `join` | `/siege join <siege>` | `k&k.minigame.siege.siege.join` | Calls `siege.joinPlayer(user)`, then opens an `InformationOverview` menu (the Siege's info/lobby GUI) for the caller. `:151-173`. |
| `leave` | `/siege leave <siege>` | `k&k.minigame.siege.siege.leave` | Calls `siege.leavePlayer(user)`. The `InformationOverview overview` local variable is declared but the block that would construct/open it is commented out — leave doesn't reopen the info menu (asymmetric with `join`), though this looks like intentional UX (no need to show the lobby after leaving) rather than an obvious bug. `:175-197`. |
| `skip` | `/siege skip <siege>` | `k&k.minigame.siege.siege.skip` | Calls `siege.skipStage(player)` — admin/testing tool to force-advance the siege's current phase. `:199-212`. |

### `/minigameobjective` — `net.knightsandkings.spigot.command.minigame.MGObjectiveCommand`
Class perm: `k&k.minigame.objective` (`v2:...MGObjectiveCommand.java:34`). `plugin.yml`: matches (`:36-37`).
Subcommands: `list|l` (`@Default`, `.list`), `fetch|f <id>` (`.fetch`), `save|s <objective>` (`.save`),
`remove|r <id>` (`.remove`), `edit|e <objective>` (`.edit`, has the wrong-repository bug). Standard
list/fetch/save/remove/edit CRUD over `MGObjective` (a generic minigame objective/capture-point entity,
distinct from `SiegeObjective`). `v2:...MGObjectiveCommand.java:46-171`.

### `/minigamescenario` — `net.knightsandkings.spigot.command.minigame.MGScenarioCommand`
Class perm: `k&k.minigame.scenario` (`v2:...MGScenarioCommand.java:34`). `plugin.yml`: matches (`:38-39`).
Same list/fetch/save/remove/edit CRUD shape over `MGScenario`. `v2:...MGScenarioCommand.java:45-169`.

### `/minigameteam` — `net.knightsandkings.spigot.command.minigame.MGTeamCommand`
Class perm: `k&k.minigame.team` (`v2:...MGTeamCommand.java:34`). `plugin.yml`: matches (`:34-35`).
Same list/fetch/save/remove/edit CRUD shape over `MGTeam`. `v2:...MGTeamCommand.java:45-169`.

### `/siegeobjective` — `net.knightsandkings.spigot.command.minigame.siege.SiegeObjectiveCommand`
Class perm: `k&k.minigame.siege.objective` (`v2:...SiegeObjectiveCommand.java:34`). `plugin.yml`: matches (`:40-41`).
Same list/fetch/save/remove/edit CRUD shape over `SiegeObjective`. `v2:...SiegeObjectiveCommand.java:46-170`.

### `/siegescenario` — `net.knightsandkings.spigot.command.minigame.siege.SiegeScenarioCommand`
Class perm: `k&k.minigame.siege.scenario` (`v2:...SiegeScenarioCommand.java:34`). `plugin.yml`: matches (`:42-43`).
Same list/fetch/save/remove/edit CRUD shape over `SiegeScenario`. `v2:...SiegeScenarioCommand.java:46-170`.

### `/siegeteam` — `net.knightsandkings.spigot.command.minigame.siege.SiegeTeamCommand`
Class perm: `k&k.minigame.siege.siegeteam` (`v2:...SiegeTeamCommand.java:34`). `plugin.yml`: matches (`:32-33`).
Same list/fetch/save/remove/edit CRUD shape over `SiegeTeam`. `v2:...SiegeTeamCommand.java:45-169`.

---

## 6. `economy`/miscellaneous data domains — `category`/`tag`, `grade`

Not one of the task's named domains exactly; closest fit is `misc`/`other` (category/tag are a generic
labelling system used across multiple entity types, not economy-specific — grouped here rather than forced
into `economy`).

### `/category` — `net.knightsandkings.spigot.command.category.CategoryCommand`
Class perm: `k&k.category.category` (`v2:...CategoryCommand.java:33,36`). `plugin.yml`: `category: permission: k&k.category`
(`:28-29`) — node mismatch (`k&k.category` vs `k&k.category.category`), same class of issue as `/town`/`/district`.

| Subcommand | Syntax | Perm | Goal |
|---|---|---|---|
| `list\|l` (`@Default`) | `/category` | `k&k.category.category.list` | Lists all `Category` objects. `:45-75`. |
| `fetch\|f` | `/category fetch <id>` | `k&k.category.category.fetch` | Standard fetch; a commented-out user-lookup guard shows this used to require a resolved `User` and no longer does. `:77-97`. |
| `save\|s` | `/category save <onlinecategory>` | `k&k.category.category.save` | Standard save. `:99-118`. |
| `remove\|r` | `/category remove <id>` | `k&k.category.category.remove` | Standard delete. `:120-139`. |
| `edit\|e` | `/category edit <onlinecategory>` | `k&k.category.category.edit` | Starts `Creation` wizard. `:141-167`. |

### `/tag` — `net.knightsandkings.spigot.command.category.TagCommand`
Class perm: `k&k.category.tag` (`v2:...TagCommand.java:32`). `plugin.yml`: `tag: permission: k&k.tag`
(`:26-27`) — same node-mismatch pattern.

| Subcommand | Syntax | Perm | Goal |
|---|---|---|---|
| `list\|l` (`@Default`) | `/tag` | `k&k.category.tag.list` | Lists all `Tag` objects. `:43-60`. |
| `fetch\|f` | `/tag fetch <id>` | `k&k.category.tag.fetch` | Standard fetch. `:62-83`. |
| `save\|s` | `/tag save <onlinetag>` | `k&k.category.tag.save` | Standard save. `:85-104`. |
| `remove\|r` | `/tag remove <id>` | `k&k.category.tag.remove` | Standard delete. `:106-126`. |
| `edit\|e` | `/tag edit <onlinetag>` | `k&k.category.tag.edit` | Starts `Creation` wizard. `:128-154`. |

### `/grade` — `net.knightsandkings.spigot.command.GradeCommand`
Class perm: `k&k.grade` (`v2:...GradeCommand.java:32`). **Not in `plugin.yml` at all** — ACF-only gate.

| Subcommand | Syntax | Perm | Goal |
|---|---|---|---|
| `list\|l` (`@Default`) | `/grade` | `k&k.grade.list` | Lists all `Grade` objects. `:43-61`. |
| `fetch\|f` | `/grade fetch <id>` | `k&k.grade.fetch` | Standard fetch. `:63-77`. |
| `save\|s` | `/grade save <onlinegrade>` | `k&k.grade.save` | Standard save. `:79-92`. |
| `remove\|r` | `/grade remove <id>` | `k&k.grade.remove` | Standard delete. `:94-107`. |
| `edit\|e` | `/grade edit <onlinegrade>` | `k&k.grade.edit` | Starts `Creation` wizard. `:109-135`. |

`Grade` itself wasn't traced further (out of scope — this doc is commands only), but the command shape/gating
matches every other CRUD-entity command above.

---

## 7. `world-admin` domain

### `/fly` — `net.knightsandkings.spigot.command.Fly`
Class perm: `k&k.fly` (`v2:...Fly.java:24,28`). `plugin.yml`: `fly: permission: k&k.fly` (`:64-65`).

| Handler | Syntax | Perm | Goal |
|---|---|---|---|
| `@Default` | `/fly` | (none beyond class) | Toggles the caller's own `allowFlight` on/off. `v2:...Fly.java:37-47`. |
| (unnamed, `CommandSender, User`) | `/fly <onlineuser>` | `k&k.fly.others` | Toggles a specified online user's fly-mode; falls back to self-toggle if `target` resolves `null` and sender is a player. `:49-64`. |
| (unnamed, `CommandSender, boolean, User`) | `/fly <true\|false> <onlineuser>` | `k&k.fly.others` | Explicitly sets (not toggles) fly-mode on/off for self or a named target. `:66-83`. |

### `/gamemode` (alias `gm`) — `net.knightsandkings.spigot.command.Gamemode`
Class perm: `k&k.gamemode` (`v2:...Gamemode.java:20,24`). `plugin.yml`: `gamemode: permission: k&k.gamemode` (`:66-67`).

| Handler | Syntax | Perm | Goal |
|---|---|---|---|
| `@Default` | `/gamemode` | (none beyond class) | Toggles caller between `SURVIVAL` and `CREATIVE` only (no path to `ADVENTURE`/`SPECTATOR` from this overload). `v2:...Gamemode.java:30-41`. |
| (unnamed, `CommandSender, User`) | `/gamemode <onlineuser>` | `k&k.gamemode.others` | Same survival/creative toggle applied to a named online target. `:43-59`. |
| (unnamed, `CommandSender, User, String>`) | `/gamemode <onlineuser> <survival\|creative\|spectator>` | `k&k.gamemode.others` | Sets an explicit `GameMode` by name (via `GameMode.valueOf`) for self or target. **Dead null-check:** `GameMode.valueOf(gamemode)` throws `IllegalArgumentException` on a bad string rather than ever returning `null`, so the `if (gameMode == null)` guard right after it (`:65-68`) can never actually trigger — an invalid gamemode string will crash with an uncaught exception instead of the intended friendly error message. `v2:...Gamemode.java:61-86`. |

### `/heal` — `net.knightsandkings.spigot.command.Heal`
Class perm: `k&k.heal` (`v2:...Heal.java:21,24`). `plugin.yml`: `heal: permission: k&k.heal` (`:70-71`).

| Handler | Syntax | Perm | Goal |
|---|---|---|---|
| `@Default` | `/heal` | (none beyond class) | Sets caller's health to max. `v2:...Heal.java:30-41`. |
| (unnamed, `CommandSender, User`) | `/heal <onlineuser>` | `k&k.heal.others` | Heals a named online target to max health. `:43-59`. |
| `all` | `/heal all` | `k&k.heal.all` | Heals every online player to max, reports a count. `:61-71`. |

### `/feed` — `net.knightsandkings.spigot.command.Feed`
**Class-level copy-paste bug**: `ALIAS = "heal"` and `PERM = "k&k.heal"` (`v2:...Feed.java:23-24`) — both
identical to the `Heal` class's constants, **not** `"feed"`/`"k&k.feed"`. `plugin.yml` independently declares
`feed: permission: k&k.feed` (`:72-73`), so the top-level Bukkit command-permission gate checks `k&k.feed` as
documented, but every ACF-level `@CommandPermission` inside this class (class-level and both subcommand
overrides, which are built as `PERM + ".others"`/`PERM + ".all"`) actually resolves to `k&k.heal`/`k&k.heal.others`/`k&k.heal.all`
— identical nodes to the unrelated `Heal` command. Practical effect: anyone holding permission to use `/heal`
also implicitly clears ACF's gate for `/feed` (and its `others`/`all` variants), regardless of whether they
were ever granted a `k&k.feed*` node. Also note **`plugin.yml`'s own `commands:` block key is `feed:`**, so
Bukkit still routes the `/feed` command label correctly to this class — only the *permission strings checked
inside the class* are wrong, not the command routing itself.

| Handler | Syntax | Perm (as coded, not as intended) | Goal |
|---|---|---|---|
| `@Default` | `/feed` | (none beyond class = `k&k.heal`) | Sets caller's food level to 20 (max). `v2:...Feed.java:30-41`. |
| (unnamed, `CommandSender, User`) | `/feed <onlineuser>` | `k&k.heal.others` | Restores a named online target's food level to max. **Also has a typo** in its own success message to the target: `"foodlevell"` (`v2:...Feed.java:57`). `:43-59`. |
| `all` | `/feed all` | `k&k.heal.all` | Restores every online player's food level to max. `:61-71`. |

### `/inventory` (class alias literal `"Inventory"`) — `net.knightsandkings.spigot.command.Inventory`
Class perm: `k&k.inventory` (`v2:...Inventory.java:16,20`). `plugin.yml`: `inventory: permission: k&k.inventory` (`:68-69`).
**No `@Default`** — bare `/inventory` with no subcommand has no handler.

| Subcommand | Syntax | Perm | Goal / notes |
|---|---|---|---|
| `see\|s\|open\|o\|check\|c` | `/inventory <see\|open\|check> <username>` | `k&k.inventory.check` | **Disabled, same pattern as `Enderchest.opCheck`**: the real offline-player NMS lookup logic is entirely commented out; live body unconditionally sends `"This command is currently not supported due to update errors from 1.16 to 1.21."`. `v2:...Inventory.java:26-55`. |
| `clear\|c` | `/inventory clear <username>` | `k&k.inventory.clear` | **Also fully disabled** the same way — including a commented-out `"all"`-keyword branch (bulk-clear every online player's inventory, gated by a never-reachable `k&k.inventory.clear.online` node) and the per-player NMS offline lookup. Live body just sends the same "not supported" message. `v2:...Inventory.java:57-98`. |

### `/enchant` — `net.knightsandkings.spigot.command.Enchant`
Class perm: `k&k.enchant` (`v2:...Enchant.java:29,33`). `plugin.yml`: `enchant: permission: k&k.enchant` (`:60-61`).

| Handler | Syntax | Perm | Goal |
|---|---|---|---|
| `@Default` | `/enchant <enchantmentname> <level>` | (none beyond class, also redundantly re-declared at method level `:44`) | Applies the named enchantment at the given integer level to the item currently in the caller's main hand via `addUnsafeEnchantment` (bypasses vanilla level caps by design — "unsafe" API). Null-guards for no-item-in-hand and unresolvable enchantment name. `v2:...Enchant.java:42-68`. |

### `/cache` — `net.knightsandkings.spigot.command.CacheCommand`
Class perm: `k&k.cache` (`v2:...CacheCommand.java:25,28`). `plugin.yml`: `cache: permission: k&k.cache` (`:58-59`).

| Subcommand | Syntax | Perm | Goal |
|---|---|---|---|
| `list\|l` (`@Default`) | `/cache` | `k&k.cache.list` | Lists every registered `Cache` instance from `CacheManager`, printing each's `toString()` — introspection/debug tool for the DAL cache layer. **Minor logic slip:** if `caches` is empty, it sends the "no instances" message but does **not** `return` — execution falls through and still prints the "List of all Cache instances:" / "End of list." framing lines around an empty body. `v2:...CacheCommand.java:36-53`. |

### `/test` — `net.knightsandkings.spigot.command.TestCommand`
Class perm: `k&k.test` (`v2:...TestCommand.java:27,32`). **Not in `plugin.yml`.**

| Subcommand | Syntax | Perm | Goal |
|---|---|---|---|
| `transportpreperation` | `/test transportpreperation` | (none beyond class) | End-to-end manual smoke test of the transport-order pipeline: finds the most-recently-created `ProductionStructure`, runs `TransportPreperationCommand` to build a `TransportOrder`, saves it, reloads it as a DTO, runs `TransportExecutionCommand.execute()`, saves the executed result, then **immediately runs `.unExecute()`** to roll it back, then deletes the DAO-side record — i.e. it deliberately exercises and then fully undoes the entire flow every time it's run. Pure developer diagnostic command, not meant for normal play. `v2:...TestCommand.java:38-133`. |

There is a **second, separate** `TestCommand` class at `net.knightsandkings.spigot.command.TestCommand` vs. a
non-Bukkit `net.knightsandkings.command.TestCommand` (implements the internal `Command<T>` pattern, not
`BaseCommand` — out of scope per Methodology) and `net.knightsandkings.command.generation.HandleGenerationCommand`'s
sibling; only the Bukkit one is documented here.

### `/creation` (alias `crs`) — `net.knightsandkings.spigot.command.creation.CreationCommand`
Placed here rather than under a `towns`/`items` domain since it's the generic entity-creation-wizard front-end
used by every domain's `edit` subcommand above, not tied to one feature. Class perm: `k&k.creation`
(`v2:...CreationCommand.java:36`). `plugin.yml`: `creation: permission: k&k.creation` (`:12-14`).

| Subcommand | Syntax | Perm | Goal / notes |
|---|---|---|---|
| `objects` (`@Default`) | `/creation` | `k&k.creation.objects` | Lists the names of every registered `ICreatable` type (i.e. every entity type that has a `Creation` wizard defined for it). `v2:...CreationCommand.java:43-71`. |
| `list` | `/creation list <active\|stashed>` | **Typo/bug:** annotated `@CommandPermission("k&K.creation.list")` — capital `K` in the middle of the node (`v2:...CreationCommand.java:74`), inconsistent with every other `k&k.*` node in the codebase (all lowercase). Whether Bukkit's permission matching is case-sensitive determines whether this silently breaks the node for anyone granted the (correctly-cased) `k&k.creation.list` string; not resolved further here (case-sensitivity of `hasPermission` is standard-Bukkit behavior, effectively **exact-string** match, so this is very likely an unreachable node in practice). | Lists either in-progress (`FetchMode.ONLY_CACHE`) or stashed/saved (`FetchMode.ONLY_DAO`) `Creation` sessions, selected via the `active`/`stashed` string arg; throws `InvalidCommandArgument` for anything else. `:73-109`. |
| `new\|n` | `/creation new <creatableobject>` | `k&k.creation.new` | Starts a brand-new `Creation` wizard session for the named creatable type, run inside an async `BukkitRunnable` "to reduce server lag." `:111-156`. |
| `resume\|r` | `/creation resume <stashedcreation>` | `k&k.creation.resume` | Resumes a previously stashed `Creation` session (`creation.resume(user)`), then re-verifies it in the repository. `:158-185`. |
| `remove` | `/creation remove <creationid>` | `k&k.creation.remove` | Deletes a stashed `Creation` session by raw integer id (not resolved via ACF's custom-type parsing like every other `remove`, just a plain `int` with a `< 0` sanity guard). `:187-211`. |
| `test` | `/creation test` | `k&k.creation.test` | Debug command: prints the material of the item in the caller's hand, then opens a throwaway `PlayerInventoryOverview` GUI titled `"Test inv"`. `:213-236`. |

### `/stashedcreation` (alias `sc`) — `net.knightsandkings.spigot.command.creation.StashedCreationCommand`
Class perm: `k&k.creation.stashed` (`v2:...StashedCreationCommand.java:8`). `plugin.yml`: `stashedcreation: permission: k&k.creation.stashed`
(`:15-17`, description left blank in the YAML).

**Entirely a stub.** Every subcommand (`list`, `resume`, `remove`) is commented out in full — the class body
contains nothing but an empty constructor. The command is registered (both in `plugin.yml` and via
`@CommandAlias`) and has a working top-level permission gate, but has **zero live functionality**: typing
`/stashedcreation` or `/sc` with any argument does nothing (ACF would report "no such subcommand" or similar,
since none exist). `v2:...StashedCreationCommand.java:1-106`. The commented-out code shows the intended design
(list/resume/remove stashed `Creation` sessions, distinct from `CreationCommand`'s own `list stashed`/`resume`/
`remove`, which **are** live) — likely superseded by those live equivalents and left in as dead scaffolding
rather than deleted.

---

## v1 → v2 command comparison (brief — v1 side is being mined separately)

**v1 commands with no v2 equivalent at all** (checked against the full v1 `*Command*.java` listing under
`knk-v1-archive/src`):

- `AfkCommand`, `ArenaCommands`, `DuelCommands` — AFK/arena/duel minigames, dropped entirely from v2.
- `CoinCommands`, `GemCommands` — v1's coins/gems economy commands; v2's `User.cash` field has no dedicated
  command at all (no `/cash`, `/coins`, `/pay`, etc. anywhere in the v2 `spigot/command` tree).
- `DonatorCommands`, `ExperienceCommands`, `NextTitleCommands` — the entire Title/Donator/XP rank-progression
  system (see `user-system.md`), dropped in v2 along with its commands.
- `FridayLotteryCommands`, `HideAndSeekCommands`, `ShopkeeperCommands`, `TreasureCommands`, `TutorialCommands`,
  `VoteCommand` — assorted minigame/event features, dropped.
- `FriendCommands` — a social/friends-list system; no v2 `/friend` equivalent found.
- `HomeCommands`, `HouseCommands`, `PropertyCommands`, `PropertyCategoryCommands`, `RoomCommands`,
  `ResourceCommands` — the entire property/house/room system (`property` domain) has no v2 command surface;
  `docs/specs/` doesn't list a `property.md` sibling doc either, consistent with it not being carried forward.
- `KillCommands` — kill/death stat display; v2 tracks the equivalent counters on `UserStatistics` (see
  `user-system.md`) but exposes them only via `/user statistics`, not a dedicated `/kills`-style command.
- `SpecialSkillCommands` — the v1 skill-point system, dropped with Titles.
- `SpawnPointCommands`, `UsefulCommands/SpawnCommand` — `/spawn`, `/spawnpoint`; **no v2 equivalent** found
  anywhere in `spigot/command` (search terms tried: `spawn`, `Spawn` — only hits are inside `PlayerListener`'s
  join-flow town/world-spawn teleport logic, not a player-invocable command).
  the `k&k.reload`, `k&k.repair`, `k&k.weather` permission nodes from v1's `k&k.*` inventory have **no**
  corresponding v2 command class or `plugin.yml` entry either — `ReloadCommand`, `RepairCommand`,
  `WeatherChangeCommand` are all dropped.
- `PlayerTeleportCommand`, `FreezeCommands`, `StaffChatCommand`, `MessageCommands`, `PingCommand`,
  `PageCommand`, `DiscordCommand` — assorted admin/QoL utilities, dropped.
- `OwnerCommands` (`/ownermode`, `/staffmode`) — the vanish-like owner/staff toggle; confirmed already in
  `user-system.md` as never rebuilt in v2 (ad hoc `k&k.owner`/`k&k.staff` checks remain at call sites with no
  command to trigger the toggle).
- `UserCommands` (`/user default|staff|builder|co-owner|owner|save|remove`, in-plugin PermissionsEx group
  management) — v2's `/user` only has `list|fetch|save|statistics`; the entire rank-assignment half is gone
  (already documented in `user-system.md`).
- `RankCommands` (`/default`) — dropped along with the PermissionsEx integration.
- `commands/CreationCommand`, `commands/DistrictCommand`, `commands/StructureCommand`, `commands/TownCommand`,
  `commands/ViewMenuCommand` (v1's own early creation/dominion command set, in the `commands` package) —
  superseded by v2's `spigot.command.creation`/`spigot.command.dominion` packages; conceptually carried
  forward rather than dropped, but the classes themselves are new implementations, not ports.

**v2 commands with no v1 precedent** (new in v2):
- The entire `spigot.command.dominion.structure` package (`GateCommand`'s CRUD side beyond `toggle`,
  `StorageCommand`, `StructureCommand`, `GenerationCommand`'s subscribe/unsubscribe) — v1's `Gates` package
  only had `GateCommands` (toggle/info-style), not a generic Storage/Structure CRUD layer.
  v1 also has its own `Streets/StreetCommands.java` — a v1→v2 port exists there (unlike the dropped list
  above), just not detailed here per scope.
- `CategoryCommand`/`TagCommand` — v1 has no category/tag labelling system at all.
- The entire `minigame`/`siege` CRUD command family (`MGObjectiveCommand`, `MGScenarioCommand`,
  `MGTeamCommand`, `SiegeObjectiveCommand`, `SiegeScenarioCommand`, `SiegeTeamCommand`, `MiniGameCommand`) —
  v1's `Sieges` package only has `SiegeCommands`/`ScenarioCommands`, not this generic
  objective/scenario/team-per-minigame-type CRUD layer; v2's `/siege` itself is the closest direct successor
  to v1's `SiegeCommands`.
- `ItemtypeCommand`, `KitCommand`'s admin CRUD (`list`/`fetch`/`save`/`remove`/`edit` — v1 kits, if any existed,
  weren't found as a dedicated command class), `GradeCommand`, `CacheCommand`, `CreationCommand`/
  `StashedCreationCommand`'s generalized multi-entity wizard framework (v1's `commands/CreationCommand` is a
  narrower, non-generic predecessor).
- `Enchant`, `Inventory` (inspect/clear) — new utility commands; v1 had `UsefulCommands/EnchantmentCommand`
  (a v1→v2 port, name changed) but no inventory-inspection equivalent.

---

## Summary count

- **35** distinct `BaseCommand`-derived command classes read in full under `v2:src/main/java/net/knightsandkings/spigot/command/**`.
- **~120** distinct subcommand/overload handler methods across those 35 classes (exact count depends on how
  overloaded handlers sharing one `@Subcommand` string, e.g. `Fly`'s three `onFly` overloads, are counted).
- **17** top-level command aliases declared in `plugin.yml`'s `commands:` block (`v2:src/main/resources/plugin.yml:6-68`,
  counting each YAML key once), plus several ACF-registered aliases with **no** `plugin.yml` entry at all
  (`grade`, `generation`, `test`, `item` — confirmed by absence from the YAML keys list).
