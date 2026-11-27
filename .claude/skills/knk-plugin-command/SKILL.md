---
name: knk-plugin-command
description: Add or change an in-game command in knk-plugin, the Knights and Kings (K&K) Paper plugin. Use when asked to add a K&K command, a `/knk` subcommand, a command flag or argument, a permission node for a command, or a player-facing command message or config key. Covers plugin.yml, registration in KnKPlugin (registerTabCommand, the /knk subcommand registry), the command-label takeover when another plugin holds the label, in-house permission checks through KnkPermissible (CommandNodes, PermissionGatedCommand, PlayerCommandSupport, CommandPermissions), messages, config.yml keys with deploy notes, and the tests (knk-core unit, MockBukkit/Mockito command tests, a player scenario on a real Paper server) and docs.
---

# K&K plugin command

A recipe for one command in knk-plugin, built from the code on its `main`. Read knk-plugin `AGENTS.md` and `CLAUDE.md`
first (modules, Java 25 toolchain, `./gradlew build -x deployToDevServer`), the
[permission checks architecture](../../../docs/architecture/plugin-permission-checks.md) and the
[global instructions](../../../docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md) "Testing: automated first". Skeletons are
in [templates.md](templates.md). Paths below are under `knk-paper/src/main/java/net/knightsandkings/knk/paper/`
unless they name a module. A command that captures a location or region for a web form is a world task, not a new
command: see the [reuse catalogue](../../../docs/architecture/reusable-systems.md).

## 1. Decide before you write

1. **A standalone command or a `/knk` subcommand?** Player commands and staff commands players type often
   (`/fly`, `/heal`, `/pay`) are standalone. Admin and debug tools go under `/knk` (`/knk regions`, `/knk lootbox`),
   each gated on its own `knk.admin.<subcommand>` node.
2. **Which nodes?** One per form that needs a different right: `knk.<command>` for yourself, `knk.<command>.others`
   for another player, `knk.<command>.all` for everyone (`FlyCommand.NODE`, `NODE_OTHERS`). Staff and admin nodes
   start `knk.admin.` so `knk.admin.*` covers them. Check the [commands guide](../../../docs/guides/users/commands.md)
   for an existing node before inventing one.
3. **Does another plugin own the label?** WorldGuard, WorldEdit and Citizens enable before KnK (`depend`/`softdepend`)
   and keep a label they registered first (§ 4).
4. **Logic in knk-core or knk-paper?** Parsing, rules and calculations without Bukkit go in `knk-core` (unit-testable);
   the executor in `commands/` stays thin: parse, check, call, reply.

## 2. Files to touch

| What | Where | Copy from |
|---|---|---|
| Executor | `commands/<Name>Command.java` implementing `TabExecutor` | `FlyCommand.java` (self/others forms, on/off, completions) |
| plugin.yml command | `knk-paper/src/main/resources/plugin.yml` under `commands:` | the `fly:` entry: `description`, `usage`, `aliases` if any, **no** `permission:` |
| plugin.yml nodes | the same file under `permissions:` | `knk.fly` / `knk.fly.others`: `description` naming the issue, `default: op` |
| Registration | `KnKPlugin.java` | `registerTabCommand("fly", new FlyCommand(support))` in the player-commands block |
| Command nodes | `commands/support/CommandNodes.java` `ANY_OF` | `Map.entry("fly", List.of(FlyCommand.NODE, FlyCommand.NODE_OTHERS))` |
| `/knk` subcommand | `KnKPlugin.java`, `knkAdminCommand.registerSubcommand(metadata, execute, complete)` | `RegionsAdminCommand.metadata()` and its registration |
| Config | `knk-paper/src/main/resources/config.yml`, `config/KnkConfig.java`, `config/ConfigLoader.java` | the `metrics` block and `KnkConfig.MetricsConfig` |
| Domain logic | `knk-core/src/main/java/net/knightsandkings/knk/core/...` | `core/teleport/WarpTargets.java`, `core/util/NamedTargets.java` |

## 3. Permission checks (in-house, never plain Bukkit)

Bukkit's permission tree never sees in-house grants (groups, wildcards, the web app's grants), so:

1. **No `permission:` on the plugin.yml command.** It would refuse non-op staff and make Paper hide the command
   (KNG-24). The `permissions:` entries only document the nodes.
2. **Gate the whole command** by listing it in `CommandNodes.ANY_OF`: `registerTabCommand` then wraps the executor in
   `PermissionGatedCommand`, so a sender holding none of the nodes gets "You don't have permission to use this
   command." (not the usage), no completions, and the command leaves their "/" list (`GatedCommandVisibilityListener`)
   and `/knk help`. A command not listed is open to everyone (some form needs no node).
3. **Check each form's node in the executor** through `PlayerCommandSupport.whenAllowed(sender, node, action)`
   (player utility commands) or `CommandPermissions.whenAllowed` / `whenAnyAllowed`. These wait for a real answer from
   `KnkPermissible`, so a granted player is not refused on a cold cache, and they say "can't be checked right now"
   when the API is down. Ops and the console pass.
4. **Use the cached checks only where an answer is needed at once**: tab completion, usage text, listings
   (`PlayerCommandSupport.holds`, `CommandPermissions.has` / `hasForCompletion`). They fail closed on a cold cache.
5. **Acting on another player** who may outrank the sender: the `TargetRankCheck` used by `/enderchest`,
   `/inventory`, `/freeze` (same rank rule as `/knk user`).
6. **`/knk` subcommands:** `CommandMetadata(name, description, usage, permission, examples)`; `permission` is the
   subcommand's node, or `null` when each action checks its own (`/knk lootbox`) together with
   `setSubcommandVisibility`.
7. **Who gets the node by default** is a design decision. A default grant to a group (for example Staff) is an API
   data migration (`SeedCommandPermissionNodes` in knk-web-api); propose it in the PR instead of adding it unasked.

## 4. Command-label takeover (label clashes)

Bukkit lets plugin commands win over vanilla ones (KnK's `/tp`, `/gamemode`), but not over a plugin that enabled first:
WorldGuard registers `/heal` in its `onEnable`, so KnK's `/heal` was only `/knightsandkings:heal`
(PandiO/knk-workspace#580). `commands/support/CommandLabelTakeover.java` fixes that:

1. Labels in `CommandLabelTakeover.TAKEN_OVER` (now `Set.of("heal")`) are pointed at KnK's command in the server's
   command map at enable and again on `ServerLoadEvent` (`KnKPlugin.takeOverCommandLabels`). The other plugin keeps its
   namespaced label (`/worldguard:heal`).
2. Every other plain label another plugin holds is logged as a startup warning (`clashes`), so a new clash shows in the
   log of the Paper boot test.
3. A new command whose label another plugin already uses: add the label to `TAKEN_OVER` only when the developer wants
   KnK's command to win (it was a developer decision for `heal`); otherwise pick another label or an alias. Say which in
   the PR.
4. Tests: `CommandLabelTakeoverTest` (MockBukkit, registration order as on a real server) and the scenario
   `player-heal-needs-grant`, which checks that the plain label reaches KnK next to WorldGuard.

## 5. Messages and config keys

1. **Messages** are built in the executor with `ChatColor` (`FlyCommand.apply`): red for refusals and errors, yellow
   for usage, gray with white names for results. Tell the target too when staff act on them. A message an admin may
   want to change goes in `config.yml` under `messages:` with `&` colour codes and `{placeholders}`, a comment that
   lists the placeholders, and a built-in default in code for a missing key (`CurrencySettings.DEFAULT_MESSAGES`,
   `LinkCodeMessage`).
2. **Config keys:** add the YAML with a comment to `config.yml`, a record (or field) in `KnkConfig` with `defaults()`,
   and the parsing in `ConfigLoader` with a safe default when the key is missing. Risky behaviour is off by default.
3. **Deploy notes:** the plugin calls `saveDefaultConfig()`, so an existing server's `config.yml` never gets new keys.
   Every added, renamed or removed key, or changed default, goes in the PR's Admin steps with the YAML to paste, the
   changelog entry and the [plugin configuration reference](../../../docs/guides/admin/plugin-configuration.md).

## 6. Steps

1. Branch per knk-link; JDK 21 for Gradle plus JDK 25 for the toolchain; baseline
   `./gradlew build -x deployToDevServer`.
2. Domain logic in `knk-core` with its unit tests first, when there is any.
3. The executor, then plugin.yml (command and nodes), then registration and `CommandNodes`.
4. Label check (§ 4), messages and config (§ 5).
5. Tests (§ 7), then rerun the baseline command and compare.
6. Docs (§ 8) and the PR (knk-link § 3).

## 7. Tests (automated first)

Use the [`knk-test-writer`](../knk-test-writer/SKILL.md) skill. For a command that is usually all three:

1. **knk-core JUnit** (`knk-core/src/test/`, `./gradlew :knk-core:test`) for parsing, rules and calculations.
2. **Command test** in `knk-paper/src/test/java/.../commands/` (`./gradlew :knk-paper:test`), Mockito around a mocked
   `KnkPermissible` (`PlayerUtilityCommandsTest`: argument forms, which node each form checks, refusals, offline
   targets, completions per node). Use MockBukkit (`MockBukkit.mock()` / `unmock()` in `@BeforeEach`/`@AfterEach`,
   `CommandLabelTakeoverTest`) when the code needs Bukkit statics or the command map. Never build a `Location` around an
   inline `mock(World.class)`; keep the mocked `World` in a field. Config keys: a `ConfigLoader<Feature>Test` that
   loads the bundled `config.yml` (`ConfigLoaderMetricsTest`: defaults, missing section, values read);
   `BundledResourcesTest` already checks that plugin.yml and config.yml parse.
3. **Player scenario** on a real Paper server for what a player types and sees, per the
   [scenario guide § 5](../../../docs/guides/developer/plugin-scenarios.md#5-players): a fake player without the node is
   refused, one granted the node gets the effect and the reply, an op passes (`PlayerHealNeedsGrantScenario`,
   `PlayerCommandNeedsGrantScenario` in `scenario/scenarios/`). Register it in `scenario/PaperScenarios.java` and raise
   `MIN_SCENARIOS` in `.github/workflows/paper-boot.yml`; CI job `paper-boot` runs it.
4. Manual only: game feel, a real client, Bedrock. Write those steps into the smoke-test guide (knk-test-writer § 4).

Run each new test once failing, then green.

## 8. Docs and PR

1. A command, node or message a player sees: [`guides/users/commands.md`](../../../docs/guides/users/commands.md),
   [`architecture/plugin-permission-checks.md`](../../../docs/architecture/plugin-permission-checks.md) when the check
   is unusual, and the player or admin guide of the feature.
2. Config keys: § 5.3.
3. The PR template's Docs impact and Admin steps (YAML to paste, nodes to grant), changelog entry in knk-workspace
   `docs/CHANGELOG.md`, Testing section per knk-test-writer § 5.

## 9. Checklist

1. plugin.yml command without `permission:`; nodes documented under `permissions:` with `default: op`.
2. Registered in `KnKPlugin`; gated in `CommandNodes` unless some form is open to all.
3. Each form checks its node with `whenAllowed`; completions and usage use the cached checks.
4. Label clash checked; takeover only on the developer's word.
5. Messages consistent; admin-editable ones in `config.yml` with defaults in code.
6. Config keys in `config.yml`, `KnkConfig`, `ConfigLoader`, a test, and the Admin steps with YAML.
7. Unit, command and scenario tests, each seen failing once.
8. Commands guide and changelog updated.
