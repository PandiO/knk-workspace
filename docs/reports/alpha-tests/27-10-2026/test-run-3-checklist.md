# Closed alpha test run 3 — checklist (planned)

**Status:** Planned; date not set. Carries over the steps test run 2 left for later.
**Last updated:** 2026-10-27
**Issues:** parent [PandiO/knk-workspace#149](https://github.com/PandiO/knk-workspace/issues/149)
**Previous run:** [test run 1 findings](../25-10-2026/test-run-1-findings.md) · fixes in the
[alpha run 1 handoff](../../../ai-agents/handoffs/2026-10-25-alpha-run-1-p0-p1.md) (packages A–D, merged 2026-10-26)

## 1. Test run 2 results (2026-10-27)

Run on the trunk builds with packages A–D merged (knk-plugin `main` `3550cbbe`, knk-web-api `master` `4d7a806`,
knk-web-app `main` `6b02bb0`). Results as reported by the developer.

| Step | Issue | Result |
|---|---|---|
| A — Siege match (all steps) | #150, #152, #153, #154 | Skipped; moved to run 3 (§ 2) |
| B1 form shows the combat values | #151 | Works |
| B2 live values, `/ce reload`, default refill | #151 | Works |
| B3 weaker defaults | #156 | Works |
| B4 frozen players not kicked (`ALLOW_FLIGHT` still on) | #155 | Accepted |
| B5 remove `ALLOW_FLIGHT`, nobody kicked | #155 | Accepted |
| C1 `/gamemode` per rank | #158 | Works |
| C2 staff tools (`/knk item`, `/knk tasks`, Player manager) | #158 | Works |
| C3 containers in domains | #157 | Accepted |
| C4 no effect damage in domains | #162 | Works |
| C5 join-refusal notices | #159 | Works. Only holders of `knk.notify.joinattempt` get them; the node is seeded for Staff (and so Moderator and Admin) |
| D — Console and navigation (all steps) | #160, #161, #176 | Not tested; moved to run 3 (§ 3) |

## 2. Siege match (package A)

- [ ] **#150 rejoin:** in a match, `/kick A` (or A quits). A logs back in within 5 minutes: same team, team spawn,
  "Welcome back…", scoreboard, the alliance's labels and own gear. Play to the end: A gets the result and rewards, and
  A's kills from before the kick count.
- [ ] **#150 window and edges:** A stays out longer than 5 minutes: no rejoin, back to the pre-siege spot and
  inventory, no rewards. The same at the hub after the team split: A comes back to the hub on the same team. A quit
  that empties a team still ends the match.
- [ ] **#152 `/siege join`:** in matchmaking `/siege join B` puts B in the lobby. In a running match
  `/siege join B <lobby> <team>` puts B on that team at its spawn ("Added B to …"); without a team, the smallest team.
  A non-admin's `/siege join <name>` gets "no lobby" and no player names in tab completion. `/siege join <lobby>` still
  joins the sender.
- [ ] **#153 loser rewards:** a losing-team member's result screen and `/transactions` show only holding and capture
  rewards (0 if their team took nothing). This is the designed behaviour; decide whether to close #153 in favour of
  #166.
- [ ] **#154 defender pass-through:** a defender's right-click on a closed gate opens it animated and it closes by
  itself after the pass-through time; a right-click while open keeps it open longer; an attacker gets "This gate is
  held by the enemy."; a gate with initial state OPEN closes on a defender's right-click and the next right-click is a
  pass-through; a capture that forces the gate open during a pass-through leaves it open.

## 3. Console and navigation (package D)

- [ ] **#160 menu item:** on join a nether star is in the right-most hotbar slot (your item moved to a free slot).
  Right-click, left-click and a click in the open inventory each open the menu once; on console try every way (tap,
  trigger, inventory) and note which work.
- [ ] **#160 behaviour:** doors and chests still work while holding it; sneak + right-click opens the menu. It can't
  be dropped, moved, stored, crafted with, framed or placed. After death it isn't on the ground and is back after
  respawn. Full inventory on join: no star, nothing lost. After a siege match: exactly one star.
- [ ] **#161 ghost blocks (console player):** the log shows `Floodgate detected` and `Bedrock block resync on`.
  Refused breaks (outside regions, the hub, a gate block, a WorldGuard region, a door, holding on a hard block) come
  back within about a quarter second and can't be walked or looked through. Allowed breaks work without flicker.
- [ ] **#176 navigation (gates closed):** as an attacker on the island, the compass to Northern Gate leads to the
  outer gate's foot, not the crane. With the outer gate open or broken, it leads to the capture point (or the inner
  door). Defenders unchanged. Same check for South Gate from the south spawn.

## 4. When merged: custom enchantment permissions

Only if [#193](https://github.com/PandiO/knk-workspace/issues/193) (knk-plugin `claude/custom-enchantment-permissions`)
is merged and deployed before the run. Grant `customenchantments.use.*` to the Default rank first.

- [ ] A non-op Default player with `customenchantments.use.*` can use each ability on right-click: chaos,
  flash_chaos, health_boost, armor_repair, resistance, invisibility. Without the grant: nothing happens.
- [ ] A grant of one node (e.g. `customenchantments.chaos`) unlocks only that ability; denying
  `customenchantments.use.chaos` next to `use.*` blocks only chaos.
- [ ] An op without grants can still use everything, including `/ce add/remove/reload`. A Default player with
  `use.*` can't run `/ce add` or `/ce reload` and doesn't see them in tab completion.
- [ ] `/ce info <player>` is refused without `customenchantments.command.info.others` and works with it.

## 5. Results

Fill in during the run: per step works / fails (with what happened) / skipped. New findings get a GitHub issue under
#149 or a new parent issue for run 3.
