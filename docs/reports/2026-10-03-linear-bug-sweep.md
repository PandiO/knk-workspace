# Linear bug sweep — open `Bug` issues

**Status:** done on a branch: code and unit tests pass, nothing merged. Live checks and merge are the developer's.
**Last updated:** 2026-10-03
**Linear:** [KNG-24](https://linear.app/kngpandi/issue/KNG-24), [KNG-25](https://linear.app/kngpandi/issue/KNG-25), [KNG-26](https://linear.app/kngpandi/issue/KNG-26), [KNG-28](https://linear.app/kngpandi/issue/KNG-28)
**Branch:** knk-plugin `claude/backlog-bugs`, head `9fcdd7f`, cut from `main` `ee7824c`. No other repo changed.

Every Linear issue labelled `Bug` that wasn't Done on 2026-10-03, fixed one phase at a time with at least one commit per bug. Done issues (KNG-15, KNG-16, KNG-22) were left alone.

## Summary

| Bug | State | Commits (knk-plugin `claude/backlog-bugs`) | Needs live |
|---|---|---|---|
| KNG-26 PermissionGroup form sends `null` isPremiumTier | **Already on trunk** before this sweep (Codex session): web-api `master` `ae0b3ad`, web-app `main` `fc66101` | none | Create a group with the checkbox untouched |
| KNG-28 no "spawn area" message when a defender hits an attacker | **Likely cause fixed** | `da1f02b` | Re-run the issue's steps with the same accounts |
| KNG-24 non-op staff can't use /freeze, /unfreeze, /staffchat, `/knk …` | **Fixed** | `ed6a92f`, `89a0b3b`, `0211f80` | Acceptance list below |
| KNG-25 `/minecraft:tell`, `/minecraft:w` break secure chat | **Fixed (needs a real client to confirm)** | `9fcdd7f` | Two-account matrix below |

Gradle `build -x deployToDevServer` on `9fcdd7f`: knk-core 1189, knk-api-client 144 (2 skipped), knk-paper 1009 (14 skipped). All green.

## KNG-28 — siege spawn-area message (`da1f02b`)

An earlier investigation (branch `claude/kng-28-siege-safezone-message`, now on trunk as `db474e4`) showed the siege rules are symmetric between roles. It suspected the attacker account couldn't be damaged at all, and named the `JoinLoadingGuard` leak, which trunk has since fixed.

New finding: `SiegeService.onSendToHub` snapshots the player's game mode in the vault but never changes it. A member who joined in **creative** stays in creative for the whole match. Paper raises no damage event for a hit on a creative player. So `SiegeCombatListener` never runs and the damager gets no message. That fits the report exactly: the mirrored hit (on the other account) did show the message.

Fix: right after a successful vault snapshot, members are switched to survival with flight off (`SiegeService.prepareForMatch`). The vault already restores the game mode after the match. Flight permission (`allowFlight`) isn't in the snapshot, so a survival player who used `/fly` turns it on again afterwards.

**Not changed (open decisions):**
- An op who types `/gamemode creative` mid-match still becomes immune.
- Non-player/non-projectile damage still skips the siege rules (lingering clouds, wolves, TNT, effect-only splash potions), as noted in the earlier investigation.

**Live check:**
1. Join a lobby with the attacker account in creative.
2. Confirm it is in survival at the hub.
3. Repeat the defender → attacker-in-safe-zone hit: the defender should see "You can't hurt players inside their spawn area!".

## KNG-24 — in-house permission gates

- **`ed6a92f`**:
  - `/freeze`, `/unfreeze` and `/staffchat` lose their plugin.yml `permission:` entries. A new `PermissionGatedCommand` checks the node through `CommandPermissions`.
  - `CommandPermissions` accepts a Bukkit grant or a `KnkPermissible` grant. Ops and the console always pass. A player without the node gets "You don't have permission to use this command."; when the API is down they get "can't be checked right now".
  - `GatedCommandVisibilityListener` (`PlayerCommandSendEvent`) hides those commands, plain and `knightsandkings:` forms, from players lacking the node. It re-sends the list once when the cold-cache answer at join was wrong.
  - `/staffchat` asks each recipient the same way, so in-house holders receive broadcasts.
- **`89a0b3b`**:
  - `/knk` subcommand metadata nodes go through `CommandPermissions` (in-house grants and wildcards such as `knk.*` / `knk.admin.*` pass).
  - `/knk` and `/knk help` warm every node first so the listing shows in-house grants.
  - Argument completion needs the subcommand's node.
- **`0211f80`**:
  - The per-action checks inside `/knk user` (`UserAdminService`: `knk.admin.user.<property>`, the XP-raise trio, the live `manage.all` rank bypass) and `/knk gate` (`knk.gate.admin/open/close`) accept in-house grants.
  - `/knk` warms those nodes before running the subcommand.
  - The shared `UserAdminService` change also covers `/freeze`'s rank check and the Player manager's property edits.

**Decisions taken (reversible, please review):**
- `/account`, `/ce`, `/menu` and `/discoveries` keep `permission:` in plugin.yml. Their nodes are `default: true`, so everyone already passes. Moving them to in-house checks would need `Default`-group grants first.
- plugin.yml defaults are unchanged. Every `default: false` `knk.admin.*` node is a child of `knk.admin` (`default: op`), so ops pass Bukkit already. In-house holders now pass through `KnkPermissible`.
- Cache-only checks (`has`) fail closed until the cache is warm. They're used for help listings, completion and the client command list. Command execution always waits for a live answer, or is warmed first.

**Not covered (follow-ups):**
- Inventory-menu permission checks still call Bukkit `hasPermission`: `UserManagerMenuFeature`'s `knk.admin.user.manage`, `manage.all`, the freeze tiles, and `MenuConditionHandlers`. A non-op staff member with in-house grants may not see the Player manager tiles.
- So do `EnchantmentInteractListener`, `EnchantmentCommandValidator`, the `ce` subcommands and the gate listeners (`GateEventListener`, `GatePassThroughConsequenceListener`).
- Per-gate `knk.gate.open.<id>` nodes can't be warmed up front. The wildcard nodes are.

**Live check (issue acceptance):**
1. Non-op staff in a group granting `knk.freeze`/`knk.unfreeze` freezes and unfreezes someone.
2. A player without the node gets the clean message, and `/freeze` is not suggested to them.
3. Same for `/staffchat` with `knk.staffchat`: an in-house holder also *receives* it.
4. Re-run KNG-18 smoke steps G1–G3.
5. The op-less owner holding in-house `knk.*` can use `/knk user <p> history`, `/knk towns`, etc.

## KNG-25 — `/minecraft:tell` / `/minecraft:w` (`9fcdd7f`)

The plugin's `/msg` takes `tell` and `w` as aliases, so on the server the vanilla redirects `minecraft:tell` / `minecraft:w` resolve to the unsigned plugin command. The client still signs the `message` argument. Paper rejects the mismatch while decoding the packet, before any Bukkit command event, which is why the existing `VanillaMessagingBlockListener` rewrite couldn't help.

New `ShadowedVanillaCommandListener` (always registered):
- leaves `minecraft:tell` and `minecraft:w` out of the client command tree, so the client sends them unsigned, which is what the server expects;
- routes ops' versions to `/minecraft:msg`, so `@a` keeps working.

`/minecraft:msg`, `/tell` and `/w` are unchanged.

**Live check (two accounts, op and non-op):**
- Run `/minecraft:tell`, `/minecraft:w`, `/minecraft:msg`, `/tell` and `/w`.
- Each should deliver with no "Signed command mismatch" in the console and no chat lockout.
- `@a` should still work for ops.
- Expected side effect: the client shows `/minecraft:tell` and `/minecraft:w` as unknown (red) while typing, but sending them works.

## Overlap with unmerged `codex/kng-30-command-completion-sweep` (`52ce855`)

A trial merge into `claude/backlog-bugs` has two textual conflicts. Both resolve cleanly, and knk-paper tests pass on the result (1011 tests, 14 skipped). The trial wasn't kept.
- `KnKPlugin.java` freeze/staffchat registration: keep `registerGatedCommand(...)` and pass KNG-30's `visiblePlayers` into the `FreezeCommand(userAdminService, true|false, visiblePlayers)` constructors.
- `KnkAdminCommand.onTabComplete`: keep KNG-30's alias resolution and add the permission check:
  - `enteredRoot` → `registry.get(enteredRoot)`;
  - empty list if it's missing or `!commandPermissions.has(...)`;
  - `root` = the metadata name.
- Behaviour note: `/staffchat` has no completer. `PermissionGatedCommand` returns `null` for holders (Bukkit's default player names), while KNG-30 suppresses that default for completer-less commands. If KNG-30 merges first, consider returning `List.of()` there.

## Merging

The branch only touches knk-plugin. Merge it to `main` after the live checks (order relative to KNG-30 doesn't matter; see the resolution above). Then move KNG-24, KNG-25 and KNG-28 to Done, and KNG-26 once its live check passes.
