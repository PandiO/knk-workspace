# Custom enchantments: from op-only to rank permissions

**Status:** In Review (pushed, not merged, not live-tested)
**Last updated:** 2026-10-26
**Issue:** [PandiO/knk-workspace#193](https://github.com/PandiO/knk-workspace/issues/193) (sub-issue of #149; scan finding F6)
**Branches:** knk-plugin `claude/custom-enchantment-permissions` `7dcbd883` (base `main` `ee35fb1`); knk-workspace
`claude/custom-enchantment-permissions` (this report, docs, tracker)

## What changed

Custom-enchantment checks were Bukkit-only on undeclared nodes, so only ops could use abilities. They now run
through `EnchantmentPermissions` (knk-paper `enchantment/`) on `CommandPermissions`: Bukkit/op first, then the
in-house rank model. Details: [plugin-permission-checks.md § 4](../architecture/plugin-permission-checks.md).

| Check | Before | After |
|---|---|---|
| SUPPORT abilities on right-click (`EnchantmentInteractListener`) | `hasPermission("customenchantments.<id>")`, op only | `customenchantments.<id>` or `customenchantments.use.<id>`, rank grants count |
| `/ce add <id>` per-enchantment check (`EnchantmentCommandValidator`) | same, op only | same as abilities |
| `/ce` subcommand nodes (`EnchantmentCommandHandler`) | Bukkit only | `CommandPermissions.whenAllowed` |
| `.cooldown.clear.others`, `.info.others` | Bukkit only; `.info.others` never enforced on execution | in-house too; `/ce info <player>` now enforces it |
| `/ce` tab completion | every subcommand listed | only the ones the player may use |

`plugin.yml` declares `customenchantments.use.*` and one `customenchantments.<id>` per enchantment (13), all
`default: op`. The group node is `customenchantments.use.*`, not `customenchantments.*`, because the in-house resolver
matches a trailing `*` on the prefix: `customenchantments.*` would also grant `/ce add`, `/ce reload` and the other
admin nodes.

## Not checked by any permission (unchanged)

ATTACK effects on hit (`EnchantmentCombatListener` → `ExecutorImpl.executeOnMeleeHit`), Cleaving's gate strike
(`GateCleaving`), enchant books and the enchanting table. Everyone can use these, with or without a grant; whether
they should be gated too is an open decision on #193.

## Tests

knk-plugin, JDK 25 (Temurin 25.0.5): `./gradlew test` green (knk-core 2312, knk-api-client 280 with 2 skipped,
knk-paper 2158 with 18 skipped, 0 failed); `./gradlew build -x deployToDevServer` green. New:
`EnchantmentPermissionsTest` (10, real resolver through the effective set: no grant, one-enchantment grant,
`use.*` incl. a future id, `use.*` doesn't grant `/ce` admin nodes, deny beats the group node, subcommand node grant,
op, Bukkit-only fallback, console), `EnchantmentInteractListenerPermissionTest` (5), `EnchantmentCommandHandlerTest`
(+3: rank grant runs `/ce cooldown clear`, refusal, tab completion filtered).

Trial merges onto the unmerged packages B (`claude/alpha-run-1-enchantments`) and C (`claude/alpha-run-1-permissions`)
merge without conflicts; shared files: `KnKPlugin.java`, `EnchantmentCommandHandler.java`, `InfoEnchantmentCommand.java`
(B) and `KnKPlugin.java`, `plugin.yml` (C).

## Live check (still to do)

See the checklist in the #193 implementation comment.
