# Closed alpha test run 2 — preparation

**Status:** Draft for the developer; date not set
**Last updated:** 2026-11-03 (folder renamed `27-10-2026/` → `test-run-2/`; process guide linked)
**Issues:** parent [PandiO/knk-workspace#149](https://github.com/PandiO/knk-workspace/issues/149) (run 1 findings);
new findings go under a new parent issue "Closed alpha test run 2 (<date>): findings"
**Checklist:** [test-run-2-checklist.md](test-run-2-checklist.md) (the steps; this file is the session plan around them)
**Previous run:** [test run 1 findings](../25-10-2026/test-run-1-findings.md)
**Process:** [closed alpha test runs](../../../guides/closed-alpha-test-runs.md) (numbering, layout, triage; agreed by the developer 2026-11-03)

What to set up before test run 2, how to run the session, which decisions to take with the testers and what to ask
them. Defaults below are taken from the package reports and the developer's decisions of 2026-10-25/27; check them
against the current trunks before the run.

## 1. Scope

**In the run (needs several players, so not covered by the developer's solo checks):**

| Area | Issues | Checklist |
|---|---|---|
| Siege match: rejoin, `/siege join <player>`, loser rewards, defender pass-through (A) | #150, #152, #153, #154 | § 2 |
| Console and navigation: menu item, ghost blocks, Northern Gate route (D) | #160, #161, #176 | § 3 |
| Siege rewards (E): gate damage, captures, participation | #165, #166 | § 4a |
| Siege results (F): scoreboard on mid-match join, result message, results log, post-match phase, final countdown | #163, #164, #174, #198, #199 | § 4a |

**Regression only (already accepted by the developer; testers play normally and report anything odd):** enchantment
values and freeze (B: #151, #155, #156), permissions and domains (C: #157–#159, #162), effects (G: #169, #170),
teleport, kits, items (I: #171, #172, #175), custom enchantment permissions (#193).

**Only if merged and deployed before the run:** #211 (Invisibility hides the player fully), #212 (lore wrap). Add their
checks to the checklist when they are.

**New features, separate block (checklist § 4b, added 2026-11-03):** siege pre-game gate view for non-members
(#213, parts #214–#217) and gate pass-through styles (#167), on the `claude/siege-pregame-gate-view` feature branches
in all three repos. They are merged to trunk only after this block passes.

**Out of scope:** client-only gate blocks (#168, skipped), arrows (#173, skipped). The realtime chain (#178–#182)
unless merged and deployed; if it is, test it in a separate block, not mixed into the run 1 retests.

## 2. Before the run (go / no-go)

The alpha runs knk-web-api `master` `8df59b75`, knk-web-app `main` `b3b415d0` (web later `alpha-1c9524d0`, #210) and
knk-plugin `main` `c8232607` ([update report 2026-11-01](../../2026-11-01-alpha-update-trunk-heads.md)). Anything
merged since needs a deploy (and a dated update report) or must be left out of scope.

- [ ] **§ 4b feature branches** (#213, #167): the three `claude/siege-pregame-gate-view` heads deployed together
  (knk-plugin `231da73f`, knk-web-api `32c0773`, knk-web-app `8f518aa` as of 2026-11-03). This includes their trunk
  merges, and adds the `AddGatePassThroughStyles` migration and GateDoor seed v4. `knk-release.sh` refuses non-trunk
  commits, so the deploy route needs a developer decision first. Without it, § 4b is out of scope.
- [ ] **Freeze builds.** Record the API, web and plugin commits in the checklist's results header. No deploys during
  the session; hotfixes go after the debrief.
- [ ] **Snapshot** the database and world before the session (`knk-deploy`), so a broken match or economy can be reset.
- [ ] **Siege scenario:** **SiegeScenario – Default (seed v2)** imported and set as default (checklist § 4a). Reward
  defaults from E apply to existing scenarios: gate damage 10 coins / 1 XP per 100 HP, participation 25 coins / 3 XP
  at 75 % active time.
- [ ] **Plugin config:** `web.public-url` = the API's `App:PublicBaseUrl`, otherwise #164/#174 links are missing.
  New keys take the jar's defaults (menu item, block resync, defender pass-through, effect-damage rules on).
- [ ] **`ALLOW_FLIGHT` removed** from the alpha's `minecraft` service (#155 step B5 was accepted; confirm it holds on
  the alpha, not only on dev).
- [ ] **Permissions:** `customenchantments.use.*` granted to Default (#193), otherwise only ops can use abilities.
- [ ] **Accounts:** every tester on a non-op account with the rank they will play as (mostly Default). One admin as
  game master; at least one console/Bedrock player (D); ideally one tester who did not play run 1, for fresh eyes.
- [ ] **Known issues list** shared with the testers (open run 1 items they will still see, see § 6), so they don't
  spend time re-reporting them.
- [ ] **Logs:** server log and API log kept for the session window (timestamps help match reports to log lines).
- [ ] **Feedback channel** ready: one place (e.g. a Discord thread) plus the report template in § 6.

## 3. Session plan

About 2 to 2.5 hours. Times are guidance.

| Block | Time | What | Checklist |
|---|---|---|---|
| Briefing | 10 min | Goal of the run, what changed since run 1 (short list), known issues, how to report, roles | — |
| Console block | 15 min | Console player: menu item every way (tap, trigger, inventory), ghost blocks; Java players: menu item doesn't get in the way | § 3 |
| Siege match 1 (happy path) | 25 min | Full match with scripted moments: one kick + rejoin within 5 min, an admin `/siege join` of a late player, defenders using pass-through, gate damage and captures; watch the last-15-seconds countdown, the post-match phase and the result message hover | §§ 2, 4a |
| Siege match 2 (edge cases) | 25 min | A player stays out > 5 min (no rejoin, no rewards), one player idles most of the match (participation < 75 %), a team empties by quits (match ends), a late joiner checks the scoreboard format (#163), `/siege leave` during post-match | §§ 2, 4a |
| Navigation | 10 min | Attackers on the island: compass to Northern Gate with the gate closed, then open/broken; South Gate from the south spawn | § 3 |
| Free play | 20–30 min | Exploratory: towns, kits, enchantments, menus, web app results pages. No script | — |
| Debrief | 15–20 min | Tester questions (§ 5), then the decisions in § 4 that need tester input | — |

**Roles:** game master (admin: starts matches, kicks, `/siege join`, watches the console), note-taker (fills the
checklist live with works / fails / skipped and timestamps), testers (assigned teams; the scripted moments are given
to named testers beforehand so the match doesn't stall).

## 4. Decisions to discuss

"Tester input" = ask the testers in the debrief; "Developer" = decide yourself, testers' experience in the run is
input. Current defaults are what the trunks do now.

| # | Topic | Current default | Question | Who |
|---|---|---|---|---|
| D1 | Loser rewards (#153) | Losers get only holding and capture rewards; 0 if they took nothing. #166's participation reward now covers everyone who played 75 % | Is losing still rewarding enough with the participation reward? Close #153 in favour of #166, or add a loser reward? | Tester input |
| D2 | Participation reward (#166) | 25 coins / 3 XP for ≥ 75 % active (non-AFK) time; time away after a disconnect counts as inactive | Is 75 % fair? Should a disconnect + rejoin within the window still count as active time? | Tester input |
| D3 | Gate damage and capture rewards (#165) | 10 coins / 1 XP per full 100 HP of gate damage; captures paid per distinct capture | Do the amounts feel right next to the win reward? Does gate damage reward the right play style (attackers only)? | Tester input |
| D4 | Rejoin window (#150) | 5 minutes, then back to the pre-siege spot without rewards | Long enough for a crash/reconnect, short enough to stop abuse? | Tester input |
| D5 | Match pacing (#198, #199) | Post-match phase 30 s in the lobby; countdown in the last 15 s | Is 30 s enough to read the results? Is the countdown helpful or noisy? | Tester input |
| D6 | Result message and history (#164, #174) | Short chat summary, full stats on hover; `/siege history` and web pages; other players see stats per the statistics visibility settings, anonymous visitors none | Do testers find the hover and the web page? Are they fine with others seeing their kills/deaths? | Tester input |
| D7 | Freeze balance (#156) | Freeze 10/15/20 % per level, 1.5–3 s, 20 s per-attacker cooldown | Is freeze still dominant? Open options: freeze as a right-click ability, a short immunity after being frozen, configurable Chaos/Flash Chaos damage | Tester input, then developer |
| D8 | Flash Chaos durations (#201) and name tags (#169) | Only Flash Chaos hides name tags (developer: keep so); durations fixed | Too long / too short? | Tester input |
| D9 | Defender pass-through (#154) and styles (#167) | Defenders: animated open, auto close after the pass-through time | Is the timing right? Which pass-through style would players want outside sieges (animated, snap, walk-path, teleport)? Unblocks #167 | Tester input, then developer |
| D10 | Menu item (#160) | Nether star in the right-most hotbar slot for everyone | Is it in the way for Java players? Java opt-out, or console players only? | Tester input |
| D11 | Domain rules (#157, #162) | Containers in domains closed to players (by design); no effect damage in domains unless flagged | Do players understand why a chest won't open? Is the refusal message clear? | Tester input |
| D12 | Skipped items (#168, #173) | Skipped | Do testers still notice arrows disappearing? Re-prioritise or keep skipped | Tester input |
| D13 | Rank defaults (#158, package C § 2) | `/gamemode`, `/fly`, inventory viewing, container bypass per Staff/Moderator/Admin tier; `/heal`, `/feed`, `/back`, `knk.gate.*` have no rank yet | Staff-only topic; settle with the staff testers, not the whole group | Developer (+ staff) |
| D14 | Next run | — | Date, length, group size, which features go into run 3 | Developer + testers |

Keep the debrief to the five or six most important rows; send the rest as a short written survey afterwards.

## 5. Questions for the testers

Ask in the debrief or as a short form right after the session (answers while it is fresh). Keep it under ten
minutes.

**Scores (1–5):**
1. How much fun was the siege match?
2. How fair did the match feel (teams, gates, enchantments)?
3. How clear was it what to do and where to go (objectives, compass, scoreboard)?
4. How clear were the result and rewards at the end?

**Open:**
5. What was the most frustrating moment?
6. What was the best moment?
7. Was anything confusing or unexplained (messages, menus, commands)?
8. Did you notice lag, rubber-banding or blocks that came back (especially console players)?
9. Anything from run 1 you expected to be fixed and still saw?
10. What should we add or change first?

**Platform:** Java or console (which device); first alpha session or not.

## 6. Reporting and triage

**Report template** (one message per finding):

```
What I did:
What I expected:
What happened:
Where (coordinates / lobby / menu) and when (time):
Java or console:
Screenshot or clip (if any):
```

- Priorities as in run 1: **P0** breaks a match or can be exploited · **P1** fix before the next run · **P2** later in
  the alpha · **P3** backlog.
- Triage within a day after the run: findings into `test-run-2-findings.md` (same shape as the run 1 findings),
  each item a GitHub issue under the run 2 parent issue, duplicates linked to the existing issue instead.
- A failing checklist step updates its issue (comment with what happened, label back from `status:in-review`).
- **Known issues to share before the run:** #211 (Invisibility shows armour) and #212 (lore lines run wide) unless
  merged, #167/#168/#173 (not done), #121 (per-entity cache TTL ignored, data can lag up to 60 s).

## 7. After the run

1. Fill the checklist's § 5 results (works / fails / skipped per step) with the tested commits.
2. Close the issues whose steps all passed; leave failing ones open with a comment.
3. Write the findings report and file the issues (§ 6).
4. Update the decisions in § 4 with what was decided, and copy each decision to its issue.
5. Short retro (10 min, developer + optional testers): what to keep, change and drop in the test process.
