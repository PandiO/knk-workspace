# Alpha run 1 P2/P3 fixes — smoke test

**Status:** Run 1 on dev 2026-10-27 (§ 5–8 pass or accepted, changes asked for #169, #170, #175; § 1–4 wait for the next closed alpha test; § 9 on hold). Not merged
**Last updated:** 2026-10-27
**Issues:** parent [PandiO/knk-workspace#149](https://github.com/PandiO/knk-workspace/issues/149); #163, #164, #165,
#166, #169, #170, #171, #172, #174, #175, #198, #199 (§ 1–8); #167 (§ 9, on hold)
**Handoff:** [2026-10-27-alpha-run-1-p2-p3.md](../ai-agents/handoffs/2026-10-27-alpha-run-1-p2-p3.md) (decisions § 1,
coordinator summary with merge order) · **Package reports:** `docs/reports/alpha-tests/25-10-2026/2026-10-27-package-{e,f,g,h,i}-*.md`
on each package's knk-workspace branch

Manual checks of the P2/P3 fixes on the **dev** stack (dev API, web app and Paper server), before test run 2 on the
alpha. Each section names what to do and what you should see. Record each run under **Findings** at the end, with the
commits you tested.

## 0. Setup

**Branches** (heads as of 2026-10-27; none merged):

| Pkg | Branch | knk-plugin | knk-web-api | knk-web-app |
|---|---|---|---|---|
| E siege rewards | `claude/alpha-run-1-rewards` | `3461708` | `16a47f5` | `ead3b39` |
| F siege results (contains E) | `claude/alpha-run-1-results` | `61f1008` | `1972569` | `6917a0f` |
| G effects | `claude/alpha-run-1-effects` | `911eb2a` | — | — |
| I teleport, kits, items | `claude/alpha-run-1-teleport-items` | `9b25ee7` | `cbd8074` | — |
| H gates (on hold, § 9) | `claude/alpha-run-1-gates` | `e7c5a93` | `87f6ab0` | `0af1dbf` |

1. **API tests first.** None of the API branches has run `dotnet test` (no NuGet in the session that built them). On
   your machine, run `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` on F (`1972569`, contains E) and
   I (`cbd8074`). Expect only the 4 known reds from `master`.
2. **Build one combined dev stack** in a local test branch per repo (don't push it to a trunk):
   - knk-plugin from `main`: merge F, then G, then I. G conflicts in `SiegeScoreboardPresenter.java`: keep F's version
     and change F's two helpers to `setBoard` → `ViewerScoreboards.set(player, board)` and `boardOf` →
     `ViewerScoreboards.current(player)` (import `net.knightsandkings.knk.paper.utils.ViewerScoreboards`), drop G's
     `lastTabName` line. Build with `./gradlew build -x deployToDevServer` (the coordinator's trial of exactly this
     merge: core 2409 / api-client 288 / paper 2304, 0 failures), then `./gradlew :knk-paper:dev`.
   - knk-web-api from `master`: merge F, then I (clean). Run it; the migrations `AddSiegeGateDamageAndParticipationRewards`,
     `AddSiegePostMatchSeconds` and `SeedTeleportAllAndItemMoreNodes` apply on start-up.
   - knk-web-app from `main`: merge F (clean). (`npx npm@11 ci`, then `npm start`.)
   - Add H to all three only when you test § 9.
3. **Web app, Import / seeds:** import **SiegeScenario – Default (seed v2)** and make it the default. Keep v1 until
   imported SiegeObjective/SiegeSpawnpoint copies are repointed (seed README).
4. **Plugin `config.yml`:** set `web.public-url` to the same value as the API's `App:PublicBaseUrl` (e.g.
   `http://localhost:3000` on dev). Keep `statistics.enabled` and `statistics.afk.enabled` on (defaults).
5. **Accounts:** four non-op players, ideally as Admin, Moderator, Staff and Default (a Default alt is fine), plus the
   console. A siege scenario that starts with two players (`PlayersMin` 2) and has at least one damageable selected
   gate and one objective. Lower the match length on that scenario so a match takes a few minutes.

## 1. Siege rewards (E: #165, #166)

1. Web app, siege scenario wizard, **Rewards** step: six new fields (gate damage coins/XP, gate damage step, taking
   part coins/XP, minimum active %) with 10 / 1 / 100 / 25 / 3 / 75. Change one, save, reopen: the value stuck. Set it
   back.
2. Start a match with players A (attacker) and B (defender). A hits a closed selected gate for well over 100 HP: a mix
   of sword hits, arrows, and a Fire Aspect fire. B (defender) hits their own gate.
   **Expect** at the end: A's result shows "N gate damage" and +10 coins / +1 XP per full 100 HP; B gets no gate
   damage. `GET api/siege-matches/{id}` shows `gateDamage` on A's participant row.
3. In the same match, A stays active; B types `/afk` (or idles past `statistics.afk.idle-seconds`) for more than a
   quarter of the match. **Expect:** A gets "taking part" +25 coins / +3 XP, B doesn't.
4. New match: A deals some gate damage, disconnects, rejoins within the rejoin window. **Expect:** the earlier gate
   damage still counts; the time away counts as not active (a long absence can cost the participation reward).
5. A member `/siege leave`s mid-match. **Expect:** no rewards (as before).
6. Capture the same objective twice (ping-pong). **Expect:** the capture reward is paid once.
7. Set the scenario's minimum active % to 0, play a match with one AFK member. **Expect:** everyone still there at
   the end gets the participation reward. Set it back to 75.

## 2. Final countdown and post-match phase (F: #199, #198)

1. Let a match run to its time limit. **Expect** for the last 15 s: action bar "The siege ends in N seconds" with a
   tick each second, higher ticks and big titles for 5..1, the sidebar time in red.
2. At the end. **Expect:** members are teleported to the scenario hub with a Victory!/Defeat/Draw title and the return
   time; sidebar "Match over / Return in". Attacking each other gives "There is no fighting outside the running
   match."; items can't be dropped.
3. Wait. **Expect:** after 30 s everyone is back where they were before the siege, with their own inventory.
4. Next match, at the end A types `/siege leave`. **Expect:** A returns at once and keeps their result and rewards.
5. Next match, at the end B disconnects during the wait and rejoins after it. **Expect:** B is at their pre-siege spot
   with their own items.
6. Web app, siege settings: **After the match** = 0, play a match. **Expect:** everyone returns at once (old
   behaviour). Set it back to 30.

## 3. Result message (F: #164)

1. At a match end. **Expect** one line per player, e.g. `[Siege] Victory! 5 kills · 2 deaths · +120 coins, +12 XP
   [details] [match page]`.
2. Hover the line. **Expect:** lobby and outcome, end reason, team, kills, deaths, best streak, captures, gate
   damage, active of match time, and every reward kind (win, objectives gained, captures, gate damage steps, taking
   part, coins breakdown, gems, XP), zeros shown as 0. The amounts match § 1.
3. Stop the API just before a match ends, start it again within a minute. **Expect:** the line says the rewards are
   confirmed later, then a "Your rewards: …" line arrives.

## 4. Scoreboard and the `[Siege]` tag (F: #163, with G merged)

1. Start a match with A and B; C (not a member) is online. **Expect:**
   - C keeps the normal board and tab colours, and sees A and B as `Name [Siege]` in the tab list and over their heads.
   - A and B see the siege sidebar, their team colours and `[k/d]` in their tab list.
2. A disconnects and rejoins; an admin adds D with `/siege join D <lobby> <team>`. **Expect:** both get the siege
   board and team colours.
3. After the post-match return. **Expect:** the `[Siege]` tags are gone, everyone has the normal board.

## 5. Match history (F: #174)

1. Click `[match page]` in a result line. **Expect:** the web page `/siege/matches/<id>` opens.
2. Open it signed out. **Expect:** teams, players, outcome and objectives; players' numbers show "Hidden".
3. Sign in as A. **Expect:** A's own row in full; other players' numbers follow their statistics visibility
   settings (siege context).
4. Open A's public profile `/players/<A>`. **Expect:** a "Siege matches" table with the newest matches; Details opens
   the match page.
5. In game, A types `/siege history`. **Expect:** the last 5 matches, each with a working link.
6. Clear `web.public-url`, restart, `/siege history`. **Expect:** the list without links. Set it back.

## 6. Flash Chaos name tags and effect bars (G: #169, #170)

1. Outside a siege (survival, not in a safezone), A hits B with a Flash Chaos weapon. **Expect:**
   - B sees no name tags for about 12.5 s; A and C still see all tags.
   - B has Slowness and Nausea boss bars counting down.
   - Afterwards B's tags, tab colours and below-name health are back.
2. Hit B again with Flash Chaos mid-blackout. **Expect:** the blackout lasts until the second one ends.
3. Hit B with Flash Chaos, then kill B (or B logs out). **Expect:** tags back after respawn or rejoin.
4. In a siege match, A Flash-Chaoses B. **Expect:** B keeps the siege sidebar (timer ticking) and team colours, and
   the siege board is back afterwards. Hit B shortly before the match ends: after the return B has the normal board.
5. Hit B with Poison, Wither, Freeze, Blindness and Confusion enchantments in turn. **Expect:** one bar per effect,
   with the name and seconds left, counting down and gone when it ends. Two effects at once: two bars. The same
   effect again: its bar restarts, no second bar.
6. B drinks milk with potion bars showing. **Expect:** the potion bars go. B dies with bars showing: all timed bars go.
7. Staff `/freeze B`. **Expect:** a fixed "Frozen" bar until `/unfreeze B`; still there after B relogs while frozen.
   Start `/navigate` for B while frozen: both bars show.

## 7. Teleport `all` and the rank rule (I: #171)

Use the Admin, Moderator, Staff and Default accounts. Give Staff `/staffmode` on when a step asks.

1. Moderator `/tphere <another Moderator>`. **Expect:** works (same rank). Moderator `/tphere <Admin>`: refused
   "higher rank".
2. Moderator `/tphere all` with Staff in staff mode, a player with `knk.teleport.exempt.tphere`, and Default online.
   **Expect:** Default (and other same/lower rank players) arrive; the staff-mode player and the exempt player stay;
   the reply shows the count and "Not moved".
3. Moderator `/tp all <Default>`. **Expect:** everyone eligible goes to Default, who stays put. `/hub all` and
   `/spawn all`: everyone eligible goes to the hub / their own spawn. Add `-s`: no messages to the moved players.
4. Staff (no `knk.teleport.all.*`) types `/tphere all`. **Expect:** refused, and `all` isn't offered in tab completion.
5. Grant Default `knk.teleport.exempt.tp`. Moderator `/tp <Default> <someone>`: refused. From the console: works.
   Grant `knk.teleport.exempt.*` instead: the same for `/tphere`, `/hub`, `/spawn` on that player.
6. `/freeze`, `/inventory`, `/enderchest`, `/knk user` on a same-rank player. **Expect:** still refused (these keep
   the strictly-lower rule).

## 8. Kits tooltip and `/knk item more` (I: #172, #175)

1. Kits menu, hover "War set cursed". **Expect:** "Other contents" wraps over several short lines and the tooltip
   stays on screen. A kit with many items ends with "… and N more".
2. Admin holds 10 bread, `/knk item more`. **Expect:** 64 bread. Again: a second stack of 64. Fill the inventory,
   again: "no room", nothing lost.
3. Admin holds a lootbox item that carries an instance id, `/knk item more`. **Expect:** one copy with a new id (check
   with the `/knk lootbox` admin lookup or `GET api/ItemInstances/{id}`); the original keeps its id; the audit log shows
   `ItemInstanceCloned`.
4. Moderator (no `knk.admin.item.more`) tries it. **Expect:** refused.

## 9. Gate pass-through styles (H: #167) — on hold

Only after you've decided on #167; add H to the combined stack (all three repos, clean merges) and import the
**GateDoor seed v4**.

1. An existing door's form shows Animated, Walk-path and Teleport on, Snap off, default Animated; right-clicks behave
   as in run 1.
2. Set a door to Snap only, default Snap. With `/gate passthrough teleport`, right-click it. **Expect:** the door snaps
   open with no animation, stays open for the pass-through time, snaps shut; someone in the doorway is moved out.
3. `/gate passthrough snap` at a door that doesn't offer snap: the door's default style is used.
4. Make walk-path a door's default; a player without `knk.gate.passthrough.instant` gets another style the door offers.
5. `/gate override <gate> passteleport false` and `passdefault snap`: all the gate's doors follow; `/gate info` and
   `/gatedoor info` show it; `clear` restores the doors' own settings; the overrides survive a restart.
6. Siege: defenders still open their gate animated; non-members are still teleported through locked doors.
7. Web app: the User form offers Snap; the Gate Door config shows the style toggles.

## Findings

| Run | Date | Commits tested | Sections passed | Problems (issue ids) |
|---|---|---|---|---|
| 1 | 2026-10-27 | Developer, dev stack per § 0 (F, G, I) | § 5 all pass; § 6.1–6.3, 6.5 pass, 6.4 and 6.6 accepted; § 7.1–7.3 pass, 7.4–7.6 accepted; § 8.1–8.4 pass. **§ 1–4 not run** (siege match tests wait for the next closed alpha test); § 9 on hold | Changes asked: #169 hide name tags only for abilities that apply blindness (victim's view), not Flash Chaos; hide the invoker's tag while invisibility is granted. #170 staff freeze bar red, text "Frozen by <player>/staff for: <reason>". #175 optional amount (`/knk item more 64` mints 64 regardless of max stack size). New: ability-cooldown boss bars (#202) |
