# Alpha test run 1 — package A: siege match (2026-10-25)

**Status:** In review — pushed on knk-plugin `claude/alpha-run-1-siege` `f75dea6` (from `main` `ee35fb1d`); not merged,
not deployed, not live-tested
**Last updated:** 2026-10-25
**Issues:** [PandiO/knk-workspace#150](https://github.com/PandiO/knk-workspace/issues/150) (P0),
[#152](https://github.com/PandiO/knk-workspace/issues/152), [#153](https://github.com/PandiO/knk-workspace/issues/153),
[#154](https://github.com/PandiO/knk-workspace/issues/154); parent [#149](https://github.com/PandiO/knk-workspace/issues/149)
**Handoff:** [2026-10-25-alpha-run-1-p0-p1.md](../../../ai-agents/handoffs/2026-10-25-alpha-run-1-p0-p1.md) § 1 package A ·
**Findings:** [test-run-1-findings.md](test-run-1-findings.md)

Claude Code (cloud session) traced the four issues against the default branches (knk-plugin `main` `ee35fb1d`,
knk-web-api `master` `6f08383d`) and fixed three in knk-plugin. knk-web-api needed no change. Live checklists for test
run 2 are in each issue's comment and repeated below.

## 1. What the code did, and what changed

| Issue | Found on the default branch | Change (knk-plugin `f75dea6`) |
|---|---|---|
| #150 kicked member can't rejoin (P0) | Design gap, not a regression. A quit (a server kick fires `PlayerQuitEvent` too) removed the member at once, restored their vault, and sent `participantLeft` at once. `/siege join` refuses a lobby at the hub or in a match. DESIGN §6.8 / §13 Q5: "no mid-match rejoin in MVP". | The member's place is kept for `siege.rejoin-window-seconds` (default 300; `0` = old rule). Logging back in within the window puts them back on their team: vault re-snapshot that keeps the pre-siege return location, hub or team spawn, scoreboard and objective labels. `participantLeft` waits for the window to pass, so a returning member is present at the end (rewards) and their earlier stats are merged. New core `SiegeRejoinSlots`, `SiegeMatchRoster.add/smallestTeam`, observer hook `memberJoinedMatch`. |
| #152 `/siege join <username>` | Didn't exist. | `/siege join <player> [lobby] [team]`, node `knk.siege.admin.join` (plugin.yml, `default: false`). Matchmaking: an ordinary join for them. Hub or running match: added like a rejoin, on the given team, their kept team, or the smallest. A lobby key still means "I join". Tab completion: lobbies + online players not in a siege, then lobbies, then team names. |
| #153 losers get no rewards (verify) | Working as designed. `SiegeRewardCalculator` (knk-web-api) pays win + holding + capture to members present at the end; losers get only holding (objectives they gained) and capture rewards, so a losing team that took nothing gets 0 (DESIGN §7.6; test `TwoTeams_AttackersTakeBothObjectives…` asserts it). A member who left (or was kicked, before this fix) gets nothing by design. | None. Recommendation in the issue: close in favour of [#166](https://github.com/PandiO/knk-workspace/issues/166) (participation base reward). |
| #154 defenders toggle gates | Confirmed: `SiegeGateListener` + `SiegeGateController.control` toggle locked gates for the owner alliance (DESIGN §8.3); the gate's own pass-through is disabled for the siege. | Defender pass-through: a right-click opens the closed gate (animated) and it closes again by itself after the hold time (`gates.siege.defender-pass-through-seconds`, `0` = the doors' own pass-through time); another right-click while it is open extends it; a gate that stands open for another reason still closes on a right-click. `gates.siege.defender-pass-through: false` = the old toggle. New core `SiegeDefenderPassThrough`. |

Known limits (not fixed, written down in the issues):

- A disconnect still counts for the team-elimination and `PlayersMin` checks at the moment it happens; a quit that
  empties a team ends the match as before (#150).
- A member who comes back after the window, or whom an admin adds after their `participantLeft` was sent, keeps the
  API's left marker: they play on but get no rewards for that match (the API keeps the first `LeftAt`, KNG-34) (#150, #152).
- An admin join at the hub before the team split ignores the team argument; the split places the player (#152).
- `knk.siege.admin.join` has no rank seed; the permission audit is package C,
  [#158](https://github.com/PandiO/knk-workspace/issues/158) (comment there). Ops have it.

## 2. Tests

knk-plugin, `./gradlew test` (JDK 25 installed in the session for the toolchain):

| Module | `main` `ee35fb1d` | `claude/alpha-run-1-siege` `f75dea6` |
|---|---|---|
| knk-core | 2312 passed | 2323 passed (+11: `SiegeRejoinSlotsTest` 6, `SiegeDefenderPassThroughTest` 3, `SiegeMatchRosterTest` +2) |
| knk-api-client | 280, 2 skipped | 280, 2 skipped |
| knk-paper | 2140, 18 skipped | 2140, 18 skipped |

No reds on either. `./gradlew build -x deployToDevServer -x test` succeeds. `SiegeService`, the presenters and the
gate controller have no unit tests (Bukkit-bound, as before); their behaviour needs the live checks below.

## 3. Live checklist for test run 2

Deploy the branch's plugin jar (developer, knk-deploy procedure). Two accounts A and B on different teams, one admin.

**#150 rejoin**
1. Start a match. Kick A (`/kick A`) or let A quit; `/siege info` no longer lists A.
2. A logs back in within 5 minutes: A is back on the same team at their team spawn, sees "Welcome back…", the team
   scoreboard and their alliance's objective labels; the inventory is A's own gear.
3. Play to the end: A gets the result and rewards like the others; their kills from before the kick count in the
   result (with `statistics.siege.report-departed-members`, on by default).
4. A quits again and stays out > 5 minutes, then comes back: no rejoin; A is restored to their pre-siege spot and
   inventory. A gets no rewards for that match.
5. Repeat 1–2 at the hub (after the team split): A comes back to the hub on the same team.
6. A quits so that their team is empty: the match ends as before (known limit).

**#152 `/siege join <player>`**
1. During matchmaking: `/siege join B` — B is in the lobby as with their own join.
2. In a running match: `/siege join B <lobby> <team>` — B is put on that team at its spawn with scoreboard and
   labels; the admin gets "Added B to …".
3. `/siege join B` without team: B goes to the smallest team.
4. A non-admin typing `/siege join <name>` gets the normal "no lobby" answer; tab completion offers players only to
   admins.
5. `/siege join <lobby>` still joins the sender.

**#154 defender pass-through**
1. Defender right-clicks a closed selected gate: it opens animated and closes again after the gate's pass-through
   time.
2. Right-click again while it is open: it stays open longer (timer restarts).
3. An attacker right-clicking it: "This gate is held by the enemy."; it doesn't open.
4. A gate whose initial state is OPEN: a defender's right-click closes it; their next right-click is a pass-through.
5. An objective capture that forces its gate open during a pass-through: it stays open (no late close).
6. Optional: set `gates.siege.defender-pass-through: false` and restart: right-clicks toggle again.

## 4. Next steps

- Developer: live test with the checklist above, then merge `claude/alpha-run-1-siege` into knk-plugin `main` and
  deploy via knk-deploy. Close #153 (or keep it open for #166).
- Package C (#158): seed `knk.siege.admin.join` for admins.
