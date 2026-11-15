# `/heal` is K&K's on a server with WorldGuard (#580) — smoke test

**Status:** Written 2026-11-15 for knk-plugin `claude/heal-takeover-580` (pull request into `next`); 5 of 6 steps automated in CI (tagged, 1 of them partly; plugin scenario `player-heal-needs-grant` and knk-plugin `CommandLabelTakeoverTest`); every step can still be run by hand; manual steps not run
**Last updated:** 2026-11-15 (written with the fix)
**Issue:** [PandiO/knk-workspace#580](https://github.com/PandiO/knk-workspace/issues/580) (developer decision 2026-11-15: option 1, K&K takes the label over)
**Related:** [in-game commands § Players: game mode, flight, health, inventories](users/commands.md#players-game-mode-flight-health-inventories), [writing a plugin scenario § 1](developer/plugin-scenarios.md#1-a-scenario-in-under-30-lines)

About 10 minutes for a full manual run, 2 minutes for the untagged step only. Record each step as works / doesn't.

## What changed

WorldGuard has its own `/heal` and enables before K&K (K&K depends on it), so the plain `/heal` used to reach
WorldGuard's command: a player granted `knk.heal` in-house was refused with WorldGuard's "You don't have permission to
do that.", and an op was healed by WorldGuard. K&K now takes the plain `heal` label over at startup; WorldGuard's
command stays reachable as `/worldguard:heal`.

## Setup

A test server with WorldGuard and the K&K jar from the branch (or `next` once merged), the API running, an op account
and a second, non-op account with no rank that holds `knk.heal`.

## Steps

1. [partly automated: knk-plugin `CommandLabelTakeoverTest` checks the takeover and the line's text; by hand: the line in a real startup log] **Startup log.** Start the server. The K&K startup lines include
   `/heal now runs KnightsAndKings's command instead of WorldGuard's (PandiO/knk-workspace#580)` and no warning
   starting "These KnK command labels belong to another plugin".
2. [automated: plugin scenario `player-heal-needs-grant`] **Refused without the grant.** As the non-op player, take
   some damage (fall a few blocks) and type `/heal`. The answer is K&K's "You don't have permission to use this
   command." (not WorldGuard's "You don't have permission to do that."), and your health stays where it was.
3. [automated: plugin scenario `player-heal-needs-grant`] **Works with the in-house grant.** As the op, run
   `/knk user <non-op player> perm grant knk.heal`. Wait up to 30 seconds (the permission cache), then as the non-op
   player, hurt, type `/heal`: full health, fire out, and "Replenished <n> health.".
4. [automated: plugin scenario `player-heal-needs-grant`] **Ops.** As the op, take damage and type `/heal`: full
   health and K&K's "Replenished <n> health." (WorldGuard would say something else).
5. [automated: plugin scenario `player-heal-needs-grant`] **The namespaced form.** As the non-op player, hurt, type
   `/knightsandkings:heal`: healed again with the same message.
6. **WorldGuard's command and the "/" list** (by hand: tab completion and the client's command list need a real
   client). As the op, type `/worldguard:heal`: WorldGuard heals you with its own message. As the non-op player with
   the grant, type `/` and `/he` + Tab: `heal` is offered; after `/knk user <player> perm revoke knk.heal` and a
   rejoin it is gone from the list.

Afterwards revoke the grant again: `/knk user <non-op player> perm revoke knk.heal`.
