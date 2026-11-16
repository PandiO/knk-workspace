# knk-plugin-command templates

Skeletons cut down from knk-plugin `main`. Replace `Widget`/`widget`, keep the shape, and check the real file when in
doubt.

## 1. Executor

From `commands/FlyCommand.java`:

```java
/**
 * {@code /widget [player]} - <what it does> (PandiO/knk-workspace#<n>).
 * Permissions resolve through {@code KnkPermissible}, not Bukkit's permission tree - hence no
 * {@code permission:} on the plugin.yml command entry.
 */
public class WidgetCommand implements TabExecutor {

    public static final String NODE = "knk.widget";
    public static final String NODE_OTHERS = "knk.widget.others";

    private final PlayerCommandSupport support;

    public WidgetCommand(PlayerCommandSupport support) {
        this.support = support;
    }

    @Override
    public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
        if (args.length > 1) {
            sendUsage(sender);
            return true;
        }
        Player target = args.length == 0 ? support.requirePlayer(sender)
            : support.requireOnlinePlayer(sender, args[0], null);
        if (target == null) {
            return true; // the support class already told the sender why
        }
        boolean self = PlayerCommandSupport.isSelf(sender, target);
        support.whenAllowed(sender, self ? NODE : NODE_OTHERS, () -> apply(sender, target, self));
        return true;
    }

    private void apply(CommandSender sender, Player target, boolean self) {
        if (!target.isOnline()) {
            sender.sendMessage(ChatColor.RED + target.getName() + " went offline.");
            return;
        }
        // ... the effect ...
        sender.sendMessage(ChatColor.GRAY + "Done for " + ChatColor.WHITE + target.getName() + ChatColor.GRAY + ".");
    }

    private void sendUsage(CommandSender sender) {
        sender.sendMessage(ChatColor.YELLOW + (support.holds(sender, NODE_OTHERS) ? "Usage: /widget [player]" : "Usage: /widget"));
    }

    @Override
    public List<String> onTabComplete(CommandSender sender, Command command, String alias, String[] args) {
        return args.length == 1 && support.holds(sender, NODE_OTHERS)
            ? support.completePlayers(sender, args[0]) : List.of();
    }
}
```

## 2. plugin.yml

```yaml
commands:
  widget:
    description: "<one line for /knk help>"
    usage: "/widget [player]"

permissions:
  knk.widget:
    description: <what it allows> with /widget (PandiO/knk-workspace#<n>).
    default: op

  knk.widget.others:
    description: <what it allows> for an online player with /widget <player> (PandiO/knk-workspace#<n>).
    default: op
```

## 3. Registration and gating

```java
// KnKPlugin, next to registerTabCommand("fly", ...)
registerTabCommand("widget", new net.knightsandkings.knk.paper.commands.WidgetCommand(support));

// commands/support/CommandNodes.ANY_OF
Map.entry("widget", List.of(WidgetCommand.NODE, WidgetCommand.NODE_OTHERS)),
```

A `/knk` subcommand instead:

```java
knkAdminCommand.registerSubcommand(
    new net.knightsandkings.knk.paper.commands.CommandMetadata(
        "widget", "<description>", "/knk widget <list|reset> [name]", "knk.admin.widget",
        List.of("/knk widget list", "/knk widget reset north")),
    widgetAdmin::execute,
    widgetAdmin::tabComplete);
```

## 4. Command test (Mockito)

From `knk-paper/src/test/.../commands/PlayerUtilityCommandsTest.java`:

```java
class WidgetCommandTest {
    private final KnkPermissible permissible = mock(KnkPermissible.class);
    private final Set<String> granted = new HashSet<>();
    private final Player alice = player("Alice");
    private final PlayerCommandSupport support = new PlayerCommandSupport(permissible, Runnable::run,
            name -> "alice".equalsIgnoreCase(name) ? alice : null, () -> List.of(alice), () -> List.of("Alice"));

    WidgetCommandTest() {
        // The cached answer tab completion and usage read.
        when(permissible.hasPermission(any(Player.class), anyString()))
                .thenAnswer(inv -> granted.contains(inv.<String>getArgument(1)));
        // The real answer whenAllowed waits for.
        when(permissible.checkAsync(any(), anyString())).thenAnswer(inv ->
                CompletableFuture.completedFuture(PermissionDecision.of(granted.contains(inv.<String>getArgument(1)))));
    }

    @Test
    void withoutTheNodeNothingHappens() { /* run onCommand, verify no effect and the refusal */ }

    @Test
    void theOthersFormChecksTheOthersNode() { /* granted.add(NODE) only; /widget Bob is refused */ }

    @Test
    void anUnreachableApiSaysSoInsteadOfNoPermission() { /* PermissionDecision.UNAVAILABLE → UNAVAILABLE_MESSAGE */ }
}
```

`player(name)` in the real test mocks `getName`, `getUniqueId` and `isOnline`; copy it.

## 5. Player scenario

From `scenario/scenarios/PlayerHealNeedsGrantScenario.java` (scenario guide § 5):

```java
public final class PlayerWidgetNeedsGrantScenario implements Scenario<ScenarioScene> {
    @Override public String name() { return "player-widget-needs-grant"; }
    @Override public String description() { return "/widget is refused without knk.widget and works with it"; }

    @Override
    public void define(ScenarioPlan plan, ScenarioScene scene) {
        ScenarioPlayer refused = scene.player("ScnNoWidget", p -> p.account(scene.fakeId(1)));
        ScenarioPlayer granted = scene.player("ScnWidget", p -> p.account(scene.fakeId(2)).grant("knk.widget"));
        plan.act("both join", () -> { refused.join(); granted.join(); })
            .await("both are online", 200, () -> refused.online() && granted.online())
            .act("the refused player types /widget", () -> refused.command("widget"))
            .await("they are refused", 60, () -> refused.received("You don't have permission to use this command."))
            .act("the granted player types /widget", () -> granted.command("widget"))
            .await("they see the result", 60, () -> granted.received("Done for"));
    }
}
```

Register it in `scenario/PaperScenarios.registry()` and raise `MIN_SCENARIOS` in `.github/workflows/paper-boot.yml`.
