# Closed alpha test run 2 — checklist (planned)

**Status:** Planned; date not set. Carries over the steps the developer's pre-checks of 2026-10-27 left for the tester run.
**Preparation:** [test-run-2-preparation.md](test-run-2-preparation.md) (agenda, decisions and tester questions)
**Last updated:** 2026-11-03 (§ 4b added: siege pre-game gate view #213 and gate pass-through styles #167, on feature branches); 2026-11-03 (renumbered from "run 3" to run 2: the 2026-10-27 check was a developer pre-check, not a tester run; preparation doc linked); 2026-11-02 (#193 accepted, § 4 and § 5); 2026-11-01 (G and I tested, § 5; packages F, G, I and #193 merged; § 4 now part of the run, § 4a added)
**Issues:** parent [PandiO/knk-workspace#149](https://github.com/PandiO/knk-workspace/issues/149)
**Previous run:** [test run 1 findings](../test-run-1/test-run-1-findings.md) · fixes in the
[alpha run 1 handoff](../../../ai-agents/handoffs/2026-10-25-alpha-run-1-p0-p1.md) (packages A–D, merged 2026-10-26)

## 1. Developer pre-checks (2026-10-27)

Not a tester run: the developer checked packages A–D alone before the next closed-alpha session. This
section was first titled "Test run 2 results", which pushed the next tester run to "run 3"; since only test run 1
has been held with testers, the next one is test run 2 (renumbered 2026-11-03).

Run on the trunk builds with packages A–D merged (knk-plugin `main` `3550cbbe`, knk-web-api `master` `4d7a806`,
knk-web-app `main` `6b02bb0`). Results as reported by the developer.

| Step | Issue | Result |
|---|---|---|
| A — Siege match (all steps) | #150, #152, #153, #154 | Skipped; moved to test run 2 (§ 2) |
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
| D — Console and navigation (all steps) | #160, #161, #176 | Not tested; moved to test run 2 (§ 3) |

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

## 4. Custom enchantment permissions (#193)

[#193](https://github.com/PandiO/knk-workspace/issues/193) is merged (knk-plugin `main` `c8232607`, 2026-11-01). **All steps accepted by
the developer on 2026-11-02; #193 closed.** Grant `customenchantments.use.*` to the Default rank; without it only ops
can use abilities.

- [ ] A non-op Default player with `customenchantments.use.*` can use each ability on right-click: chaos,
  flash_chaos, health_boost, armor_repair, resistance, invisibility. Without the grant: nothing happens.
- [ ] A grant of one node (e.g. `customenchantments.chaos`) unlocks only that ability; denying
  `customenchantments.use.chaos` next to `use.*` blocks only chaos.
- [ ] An op without grants can still use everything, including `/ce add/remove/reload`. A Default player with
  `use.*` can't run `/ce add` or `/ce reload` and doesn't see them in tab completion.
- [ ] `/ce info <player>` is refused without `customenchantments.command.info.others` and works with it.

## 4a. P2/P3 packages F, G and I (merged 2026-11-01)

Merged into knk-plugin `main` `c8232607`, knk-web-api `master` `22a28ab`, knk-web-app `main` `b20101a`. Package H
(gates, #167) is no longer on hold: it is tested in § 4b, on the feature branches. Setup and every step: the
[P2/P3 smoke test guide](../../../guides/alpha-run-1-p2-p3-smoke-test.md) §§ 1–8 (skip § 0.2, the merge is done, and
§ 9, gates). Before the run:

- Deploy the trunks; the API runs `AddSiegeGateDamageAndParticipationRewards`, `AddSiegePostMatchSeconds` and
  `SeedTeleportAllAndItemMoreNodes`. E's reward defaults then apply to every existing scenario.
- Web app: import **SiegeScenario – Default (seed v2)** and make it the default (keep v1 until imported
  SiegeObjective/SiegeSpawnpoint copies are repointed, see the seed README).
- Plugin `config.yml`: set `web.public-url` to the API's `App:PublicBaseUrl` (#174 links).

| Area | Issues |
|---|---|
| Siege rewards (E) | #165, #166 |
| Siege results (F) | #163, #164, #174, #198, #199 |
| Effects (G) | #169, #170 |
| Teleport, kits, items (I) | #171, #172, #175 |

## 4b. Gates: siege pre-game view (#213) and pass-through styles (#167) — feature branches

New features, a separate block (not run 1 retests). **Not on trunk:** branch `claude/siege-pregame-gate-view` in all
three repos (knk-plugin `231da73f`, knk-web-api `32c0773`, knk-web-app `8f518aa` on 2026-11-03; each = trunk + #213 +
#167). They merge to trunk only after this block passes (developer decision 2026-11-03: trunk stays live-tested).
Design: [siege DESIGN § 8.5](../../../specs/siege-minigame/DESIGN.md) and plan Phase 11; issues #213 (parts #214–#217)
and #167.

**Before the run**

- [ ] All three branches deployed together, and their commits recorded in § 5. `knk-release.sh` only takes trunk
  commits, so this needs the deploy route decided for this run.
- [ ] API migration `AddGatePassThroughStyles` applied (it only adds columns). The **GateDoor seed v4** imported
  (P2/P3 smoke test guide § 9).
- [ ] Minecraft log: `Enabling KnightsAndKings` and **no** `PacketEvents could not load/start` warning (if there is
  one, step 15 fails; everything else still works).
- [ ] `SiegeConfiguration.NonMemberGateView` = `PreLockdownView` (default).
- [ ] A scenario with districts and four gates:
  - **G1**: an area gate (not selected), **closed** before the match, pass-through allowed.
  - **G2**: an area gate, **open** before the match.
  - **G3**: a selected siege gate, **closed** before the match and at the start.
  - **G4**: a selected siege gate, **open** before the match, closed by its defenders during the match.
  - Optional **G5**: a drawbridge (rotation) door, closed before the match.
- [ ] Roles:
  - **A**: match member, defender of G3/G4.
  - **B**: non-member without `knk.gate.passthrough.use`.
  - **C**: non-member with `knk.gate.passthrough.use`.
  - **D**: a console/Bedrock non-member.
  - The game master runs the match and the `/siege join` step.

**Siege pre-game view (#213)**

| # | Step | Expected | Issue | Result |
|---|---|---|---|---|
| 1 | Start the match; at the hub lockdown the area gates open for real | A sees G1 and G2 open. B and C see G1 **closed** (a short flicker during the animation is fine) and G2 open | #214 | |
| 2 | A walks through G1 | Works (really open) | #214 | |
| 3 | Defenders close G4 | A sees G4 closed; B and C see G4 **open** | #214 | |
| 4 | B walks into G1 | Stopped by the gate, no rubber-banding for a normal client | #215 | |
| 5 | B tries to get past G1: sprint-jump, elytra, riptide trident | Never on the other side; at most a short "This gate is closed outside the siege." | #215 | |
| 6 | B rides a horse, then a boat or minecart, through G1 | B is put off and back on their side; the vehicle stops | #215 | |
| 7 | B throws an ender pearl through G1; eats chorus fruit next to it | A teleport that would cross the gate is cancelled | #215 | |
| 8 | B right-clicks G1 | "This gate is closed."; nothing opens | #216 | |
| 9 | B digs at a G1 block until it disappears on their screen, then walks into the gap | Still stopped; the block is back within about a second | #214, #215 | |
| 10 | B walks into G4 (looks open, really closed) | Carried across (teleport), at most once a second | #214 | |
| 11 | B right-clicks G3 (closed before and now) | "This gate is closed." | #216 | |
| 12 | C right-clicks G1 | G1 opens **for C only**, instantly; A and B see no change; C walks through; after the door's pass-through time it is closed for C again | #216 | |
| 13 | C stands in G1's doorway when that time runs out | Not stuck; can step out either side | #216 | |
| 14 | C right-clicks G3 (really closed) | Carried across (teleport) | #216 | |
| 15 | A, B and C read G1's hover | A: siege hover (OPEN, health, INVINCIBLE where it applies). B and C: **pre-game** hover (CLOSED, pre-match health, no siege-only lines) | #217 | |
| 16 | An attacker damages a selected gate | A's hover health drops; B's stays at the pre-match value | #217 | |
| 17 | Game master: `/siege join B` | Within about half a second B sees the real gates, is no longer stopped and gets the siege hover | #214, #217 | |
| 18 | A leaves the match while standing behind G1 | A is restored and teleported to the pre-siege spot, not stranded | #213 | |
| 19 | D repeats 1, 4, 5 and 15 | Same as Java; note if D is snapped back noticeably more often | #213 | |
| 20 | A non-member in `/staffmode` (or spectator) walks through G1 | Allowed (exempt), still sees G1 closed | #215 | |
| 21 | G5, if set up: B looks at it | Shown closed and upright; never a bridge deck over a gap that isn't really there | #214 | |
| 22 | End the match | Gates back to their pre-game state; about 5 s later B and C see the real blocks, are no longer stopped, hovers normal | #213 | |
| 23 | Between matches: `NonMemberGateView` = `PassThroughOnly`, `/siege admin reload`, run a short match | No fake blocks, B sees the real gates (G1 open) but is **still stopped** at G1; C's right-click still opens it for C; live hover for everyone | #213 | |

Console during all of it: no `[Siege] Non-member gate view pass failed` warnings.

**Gate pass-through styles (#167)**: steps 1–7 of the
[P2/P3 smoke test guide § 9](../../../guides/alpha-run-1-p2-p3-smoke-test.md) on gates outside a siege, then:

| # | Step | Expected | Issue | Result |
|---|---|---|---|---|
| 24 | In a running match, A (defender) right-clicks G3 with `/gate passthrough snap` set | Still the animated open + automatic close (#154), whatever A's style | #167 | |
| 25 | C (prefers snap or animated) repeats step 12 | Still the instant per-player opening (it changes only C's view, so it is never animated) | #167, #216 | |

## 4c. Staff web app: dashboard access and bulk delete (#280, #205) — merged untested

Accepted by the developer 2026-11-13 without a live test and merged (knk-web-app `main` `e02ee79`, knk-web-api
`master` `45043a7`). Run the [dashboard access smoke test](../../../guides/dashboard-access-smoke-test.md) on the
deployed alpha: API § 1–7 and web app § 8, with the role accounts of its § 0 (owner, Admin, Staff, content-only,
world-only, player). Before the deploy check that the Admin group holds `knk.admin.*` and the plugin runs with
`api.auth.type: apikey` (CHANGELOG 2026-11-12 Admin steps). A developer/staff block; testers are not needed.

| Step | Result |
|---|---|
| API § 1–7 | |
| Web app § 8 (22 steps) | |

## 5. Results

### 2026-11-01 (developer, on knk-plugin `main` `c8232607`, knk-web-api `master` `22a28ab`)

| Step (P2/P3 smoke test guide) | Issue | Result |
|---|---|---|
| § 6.1 Blindness hides name tags | #169 | Works |
| § 6.2 milk, overlap, death | #169 | Accepted |
| § 6.3 siege variant | #169 | Accepted |
| § 6.4 Flash Chaos keeps tags | #169 | Works |
| § 6.5 Invisibility hides the user's tag | #169 | Works. Follow-up: hide the player fully (armour too), staying in the tab list → #211 |
| § 6.6 Invisibility in a siege | #169 | Works |
| § 6.7 staff freeze bar | #170 | Works |
| § 7.1–7.3 rank rule, `all` forms | #171 | Works |
| § 7.4–7.6 without node, exempt, strictly-lower | #171 | Accepted |
| § 8.1 kits tooltip | #172 | Works. Follow-up: other lore lines (rank-rule line) still wide; general lore wrap → #212 |
| § 8.2–8.9 `/knk item more` | #175 | Works |

Closed as completed: #169, #170, #171, #172, #175.

### 2026-11-02 (developer)

§ 4 custom enchantment permissions (#193): all steps accepted; #193 closed as completed.

Still to test: §§ 2–3 (A, D) and the E/F steps of § 4a
(#163, #164, #165, #166, #174, #198, #199).

Fill in during the run: per step works / fails (with what happened) / skipped. New findings get a GitHub issue under
#149 or a new parent issue for test run 2.
