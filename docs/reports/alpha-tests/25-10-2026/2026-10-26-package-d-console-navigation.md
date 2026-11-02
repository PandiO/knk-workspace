# Alpha test run 1 — package D: console and navigation (2026-10-26)

**Status:** In review — pushed on `claude/alpha-run-1-console-nav`: knk-plugin `ddc74e2c` (from `main` `ee35fb1d`);
not merged, not deployed, not live-tested
**Last updated:** 2026-10-26
**Issues:** [PandiO/knk-workspace#160](https://github.com/PandiO/knk-workspace/issues/160),
[#161](https://github.com/PandiO/knk-workspace/issues/161), [#176](https://github.com/PandiO/knk-workspace/issues/176)
(all P1, no P0 in this package); parent [#149](https://github.com/PandiO/knk-workspace/issues/149)
**Handoff:** [2026-10-25-alpha-run-1-p0-p1.md](../../../ai-agents/handoffs/2026-10-25-alpha-run-1-p0-p1.md) § 1 package D ·
**Findings:** [test-run-1-findings.md](test-run-1-findings.md) (7.1, 8.1, 13.1)

Claude Code (subagent of the coordinator session, after the package session was refused `add_repo`) traced the three
issues against knk-plugin `main` `ee35fb1d` and fixed them in knk-plugin only. knk-web-api and knk-web-app needed no
change. #176 was traced with the alpha's data from knk-dev-db-seed (the database the alpha was loaded from on
2026-10-24): road graph, siege scenario, gate doors.

## 1. What the code did, and what changed

| Issue | Found on the default branch | Change |
|---|---|---|
| #160 menu item for `/menu` | `/menu` existed (`MenuCommand`, `knk.menu`), no item for it. Nothing in the plugin marks an item as "not a game item" (no soulbound handling to reuse; the navigation compass is a plain item matched by name). | `003cce95`: **menu item** under `menus.menu-item`: `enabled`, `give-to` (`all` / `bedrock`), `give-on-join`, `keep-on-death`, `material` (`NETHER_STAR`), `name`, `lore`, `slot` (8), `open-on` (`RIGHT_CLICK`, `LEFT_CLICK`, `INVENTORY_CLICK`), `droppable`, `movable` (both false). The item is tagged (`knightsandkings:menu_opener` + a fingerprint of material/name/lore), so the look can change and old items are replaced at the next join. A click runs `/menu` itself (permission and command rules included). It never lands on the ground (death drops, item spawns and pickups), never goes into a chest, the crafting grid, an item frame or an armour stand, can't be placed, and the kit scan skips it; a player's own item in the slot moves to a free slot, a full inventory gets nothing. Siege vault snapshots keep it like any item. From the open inventory the menu opens a tick later (Bedrock: `bedrock-transition-delay-ticks`). Core `MenuOpenerSettings`/`MenuOpenerPlacement`, paper `menu/opener/`. |
| #161 console block breaks client-only | None of the break-cancelling listeners resent anything (as the earlier read-only note said), but Paper itself sends a block update when it cancels a break. The cause is on the Geyser side (traced in Geyser's source, `master`): Geyser's `BlockBreakHandler` removes the block on the Bedrock client at 65 % of its own mining estimate and only then tells the server; on Spigot/Paper it does not roll a predicted block back when the server acknowledges the action (`WorldCache.markPositionInSequence` only on other platforms). A break refused at its **start** (cancelled left-click / `BlockDamageEvent`) gets its one block update before the client finishes, so the block stays gone for that player. Doors have a confirmed Geyser bug of their own ([GeyserMC/Geyser#5746](https://github.com/GeyserMC/Geyser/issues/5746)). No Geyser, Floodgate or MCXboxBroadcast setting changes this (§ 4). | `cb659fd1`: `crossplay/BedrockBlockResync` (core `BlockResyncWatch`): any refused break by a Floodgate player - cancelled `BlockBreakEvent` or `BlockDamageEvent`, or a left-click on a block whose use was denied, from any plugin - is watched; the real block (plus a door's / tall plant's other half, a bed's other end) is sent to that player again the next tick, every `interval-ticks` (5) while they keep swinging, and once more `window-ticks` (30) after the last swing. Config `crossplay.block-resync` (`enabled`, `all-players` for testing with Java). |
| #176 northern gate route sends attackers to the crane | Alpha data: the **Northern Gate** objective (gate structure 8) has its capture point at (1386.3, 52, -588.2) - on the gatehouse between the Outer Gate (1375..1378, -585..-588) and the Inner Gate, 8 blocks above the road (y 44). An attacker on the island (around road nodes 44/54/69, North Spawn 1324, -622) is within `max-snap-distance` (48) of it, so `/navigate` uses **direct mode**: a walk search to that point. With the gate closed there is no way in, and the walk search's partial path ends at the reachable cell nearest in a straight line to the gatehouse top - a tall structure outside the walls, the crane. (By road the existing rule should hold: edge E24 through both doors is tagged live and the route stops at the gate.) | `ddc74e2c`: the compass (and `/navigate` in a match, same list) now gives a member heading for an objective **to capture** the gate instead, while a closed, standing door of the objective's gate is between their team's nearest spawn and the capture point (core `SiegeGateApproach`, paper `navigation/SiegeGateApproaches`): 1.5 blocks in front of the door on their side, at its foot - beyond the far end of its open position if that lies on their side (a lowered drawbridge over a moat). Open or destroyed doors don't count: with the outer door down the capture point (between the doors) is the destination again. Defenders and objectives without a gate are unchanged. `GateManager.openFootprint` added. |

## 2. Tests

| Repo | Default branch | `claude/alpha-run-1-console-nav` |
|---|---|---|
| knk-plugin `./gradlew test build -x deployToDevServer` (JDK 25) | `ee35fb1d`: core 2312, api-client 280 (2 skipped), paper 2140 (18 skipped), 0 failures (package B's run) | `ddc74e2c`: core 2341, api-client 280 (2 skipped), paper 2179 (18 skipped), 0 failures; build green |

New tests: `MenuOpenerPlacementTest`, `MenuOpenerSettingsTest`, `BlockResyncWatchTest`, `SiegeGateApproachTest` (with
the alpha seed's Northern Gate geometry) in core; `MenuOpenerServiceTest`, `MenuOpenerListenerTest`,
`MenuOpenerConfigTest` (also checks the shipped `config.yml`), `BedrockBlockResyncTest`, `SiegeGateApproachesTest` and two
cases in `NavigationCompassServiceTest` in paper. Nothing was run against a server or a Bedrock client.

Merges: `git merge` of packages A (`claude/alpha-run-1-siege` `f75dea61`), B (`claude/alpha-run-1-enchantments`
`fcb2e08a`) and C (`claude/alpha-run-1-permissions` `352cdd7c`, still in progress) on top of this branch, in that order:
no conflicts. All four branches add to `config.yml` and `KnKPlugin.java`, A and C to `plugin.yml` (D does not touch
`plugin.yml`); re-check C's final head before merging.

## 3. Live checklist for test run 2

Deploy the plugin jar (knk-deploy, `docs/guides/nas-ops-access.md`). The alpha's own `config.yml` has neither new
section; the defaults apply (menu item on for everyone, resync on for Bedrock players). To change them, add the
sections from the jar's `config.yml` through `config-apply knk`. Check the log for `Menu item on (NETHER_STAR in slot 8,
for ALL players)` and `Bedrock block resync on (Bedrock players, ...)`; `Floodgate detected` must appear too, otherwise
nobody counts as Bedrock.

**#160 menu item** (Java and a console player)

1. Join: a nether star "Menu" in the right-most hotbar slot; an item you had there moved to a free slot.
2. Right-click in the air, left-click, and click it in the opened inventory: each opens the menu once. On console try
   every way (tap, trigger, inventory) and note which ones work - Bedrock may not send some of them.
3. Right-click a door or chest holding it: the door/chest works, no menu. Sneak + right-click: the menu.
4. Try to drop it, move it, shift-click it into a chest, put it in the crafting grid, an item frame, an armour stand,
   place it: nothing happens. Die: it is not on the ground, it is back after respawn.
5. A full inventory at join: no star, nothing of yours lost.
6. After a siege match: one star, not two.

**#161 ghost blocks** (console player)

7. Try to break blocks where it's not allowed (outside regions, hub, a gate block, a WorldGuard region, a door): the
   block comes back within a quarter second of breaking and you can't walk through it. Hold the button on a hard
   block for several seconds: same.
8. Break blocks where it is allowed: they break normally, no flicker.

**#176 navigation** (siege match on the alpha scenario, gates closed)

9. Attacker on the island: compass to **Northern Gate**: the trail leads to the outer gate's foot on the island side,
   not to the crane. Note your start position and the chat lines if not.
10. Open or break the outer gate, click again: the capture point on the gatehouse (or the inner door if it stands in
    the way). Defender: the capture point, as before.
11. Same for the **South Gate** objective from the south spawn.

## 4. Geyser, Floodgate and MCXboxBroadcast (for the developer, no NAS change made)

The NAS configs belong to the Bedrock crossplay trial row (PandiO/knk-workspace#43); nothing was changed there.

- **Ghost blocks (#161):** no setting in Geyser 2.12's `config.yml`, Floodgate or MCXboxBroadcast controls how a refused
  break is set right - the fix is the plugin's resync. MCXboxBroadcast only announces the session and is not involved.
  When the 26.60 builds are swapped in after 2026-10-27, take the newest Geyser build too (its block-breaking code is
  still changing; the door bug GeyserMC/Geyser#5746 is open). If ghost blocks remain with the resync on, collect
  `/geyser dump` and the block/position and report it upstream; `crossplay.block-resync.all-players: true` lets a Java
  client show whether the resync fires at all.
- **Menu item (#160):** no Geyser setting needed. Floodgate must stay enabled for `give-to: bedrock` and for the Bedrock
  delay; with `username-prefix: "BE_"` unchanged nothing else depends on it.

## 5. Next steps

Developer: run the checklist (§ 3), merge `claude/alpha-run-1-console-nav` with the other package branches, deploy.
Open points written down in the issues: #160 - which clicks a console sends (step 2), the default audience (`all` vs.
`bedrock`); #161 - whether the resync window needs tuning; #176 - the walk search's partial path still ends at the
nearest cell in a straight line for any other unreachable point (not changed here).
