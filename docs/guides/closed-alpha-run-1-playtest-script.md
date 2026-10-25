# Closed alpha run 1 — playtest script (invite, first join, player experience, siege)

**Status:** Draft v1 for the first friends session (2026-10-25). Not yet run. Fill in the findings log at the end
during the call; afterwards copy it to a dated file in `docs/reports/` (this guide stays a living document).
**Last updated:** 2026-10-25
**Audience:** the developer as host, 2–5 friends as testers, everyone on a Discord call.
**Builds on:** [alpha go-live](alpha-go-live.md) § 10–11 (the invite, kill switches) ·
[invitations smoke test](invitations-smoke-test.md) § 4 and § 9 (the gate and claim linking, alpha checks) ·
[Phase 9 report](../reports/2026-10-24-alpha-phase-9-invite-only.md) · [Stage 2 report](../reports/2026-10-24-alpha-api-4aeb794-and-plugin-stage-2.md)
(what runs on the NAS) · [siege DESIGN](../specs/siege-minigame/DESIGN.md) § 6–8 and § 11.1 ·
[siege playtest follow-ups smoke test](siege-playtest-2026-10-24-smoke-test.md) ·
[siege scenario authoring](authoring-a-siege-scenario.md) § 5 · [hub smoke test](../reports/2026-10-17-hub-smoke-test.md) ·
[siege navigation compass smoke test](siege-navigation-compass-smoke-test.md) § C–E.
**Report back:** PASS / FAIL / SKIP per step ID plus the findings log (§ 7). For a FAIL: the exact chat line, the
log line and what the tester did just before.

The developer's own smoke tests check that features work as designed. This session is different: it checks whether
**people who have never seen the game** get through the invite, the first join and a siege without the developer
explaining it. So the host observes more than they help, and "they got confused" is a finding, not a failure of the
tester.

---

## 1. How to run the session on Discord

- **One flow, one tester, one screen.** Parts A and B (invite, sign-up, first join) run **one friend at a time on
  screen share**, the others watch with their mics muted. Each friend's first attempt is the only real
  first-impression test you get from them. Start with the **least technical friend**: if they get through, everyone
  does.
- **Think aloud.** Ask the tester on screen to say what they expect *before* they click, and what they are looking
  for when they pause. Where they pause is the finding.
- **Hold back for a minute.** Don't help until the tester has been stuck for about 60 seconds. Note what they tried
  first. Then help, note the hint, and continue; the friend after them gets the same hint only if they get stuck in
  the same place.
- **Note-taker.** Keep the findings log (§ 7) open in a second window and write the step ID and a few words at the
  moment it happens; details go in after the call. If a friend is happy to, ask one of the watchers to note too.
- **Record** the screen share (Discord or OBS) with the testers' agreement. Timestamps make the log cheap to fill in.
- **Timebox.** A step that blocks play after one hint is a FAIL: write it down, give the workaround, move on. The
  session is for finding things, not for fixing them live. Don't open the IDE during the call unless the run cannot
  continue otherwise.
- **The host does not play match 1.** Watch from the console and the logs, and as a spectator in game. Play in match
  2 if the player count needs it.
- **Bug reports from friends** go in one Discord thread in three lines: *what I did — what I expected — what
  happened*, plus a screenshot. Tell them this in the briefing, and that the claim code and the invite link are never
  shown on a stream or pasted in chat.

Suggested timeline (about 2 h 45 min; stop at the blocker, not at the clock):

| When | Part | Minutes |
|---|---|---|
| 0:00 | Briefing (§ 2) | 10 |
| 0:10 | A — invitation and sign-up, one friend at a time | 20 |
| 0:30 | B — first join and linking, one friend at a time | 15 |
| 0:45 | C — player experience, navigation, menus (free-roam with tasks) | 25 |
| 1:10 | Break | 5 |
| 1:15 | D — siege match 1 (the happy path, observed) | 30 |
| 1:45 | E — siege match 2 (disruptions) | 30 |
| 2:15 | Debrief (§ 8) | 15–30 |

---

## 2. Briefing (read out at 0:00)

1. "This is a closed alpha: things will break, progress may be reset. That's the point of today."
2. Java Edition **26.3** at `play.knightsandkings.net`. Bedrock via the cross-play entrance works, but menus may
   close by themselves right after a click until the fix is live (P1 below); say so if someone is on Bedrock.
3. The flow: invite mail → sign up on the site → Cloudflare mails a one-time PIN (once per device per 30 days; this is
   the site's door lock, not the game's) → join the server → you get a code on the disconnect screen → enter it on the
   site → join again. "Yes, it's a few steps. Tell me which one felt like one too many."
4. Keep your mail open; the invite mail, the PIN mail and the "account linked" mail all come within seconds.
5. Never share the claim code or the invite link; staff never ask for it.
6. Bug reports: the Discord thread, three lines plus a screenshot.
7. During a siege only a few commands work (`/siege`, `/msg`, `/r`, `/menu`); that's intended. There's no rejoin
   into a running match after a disconnect; that's intended too (for now).

---

## 3. Pre-flight (host, before the call; 60–90 min)

| ID | Do | Done when |
|---|---|---|
| P1 | **Decide what runs today.** The NAS runs knk-plugin `main` `d56e41da` and the KNG-205 API (Stage 2 report). Merged to the trunks since, **not yet deployed**: the siege playtest follow-ups (plugin `75d619b`, API `1aba1ee` with migration `AddSiegeSkipSeconds`, web app `4a9537e`: spawn picker at the team split, siege menus shrink, `/siege skip` settings, siege teleports out of the server hub), the menu validation retry (plugin `ad5786c`, not live-tested) and the Bedrock menu transitions (plugin `262c1095`, waiting for this check). **Recommendation:** if you have ~90 min before the call, deploy the three trunk heads in the runbook order (back up → migrator → API → web app → plugin, [go-live § 11](alpha-go-live.md)); match 1 reads much better with the spawn picker at the split and with members moved out of the server hub. If not, run with what's there and mark D5/D4 as "known" in the log rather than as new findings | You know which build each expectation below applies to; write it at the top of the findings log |
| P2 | **Snapshot.** `knk-alpha-snapshot pre-run-1` (world + DB), as before the mail relay switch. Keep the Phase 9 kill switches to hand: gate → `admission.mode: whitelist` + whitelist on; `Security__Registration__Mode=LinkCode`; `CloudflareAccess__SyncEnabled=false`; stop the playit agent (game) or `cloudflared` (web) | Snapshot listed; the kill-switch commands are in a text file you can paste |
| P3 | **Hub or no hub.** On the alpha `/hub` said "The hub isn't available right now" on 2026-10-24: the placeholder database has no hub selected (`HubSettingsJson` NULL, no `IsHub` domain), so joining players land at the **join spawn from Game Settings**, not in the hub. Either import the approved seed with a hub selected first, or accept that today's run skips the hub steps (B4, C7, E9). Check: `/hub` as `__pandi__` | You know where a new player lands, and you've stood there: is it obvious where to go? |
| P4 | **Siege lobby and scenario.** Web app → `/forms/siegelobby`: the lobby is **Enabled**, has a rotation, **matchmaking 120 s** and **cooldown 60 s** for today (defaults are 300/900, too long for a test evening); voting 1–2 candidates. The scenario's readiness says **Ready**; `PlayersMin` ≤ the number of people in the call (and ≥ the team count), `PlayersMax` ≥ it; match length Min/Max around 8–12 min; no `MinTitleBracketId` (your friends have no title). The defender team has **2 spawnpoints** or a `SpawnWhenHeld` objective so the picker has something to show. The gates on the Gates step are the ones you want under siege control; Siege Settings → non-member gate view as intended. Then in game `/siege admin reload`, `/siege admin list` → lobby listed, N scenarios ready | `/siege admin list` shows the lobby with ≥ 1 ready scenario; the numbers fit the head count |
| P5 | **Gates on the alpha data.** Stage 2 logged gate door 12 (**Keep Stair House**) with sheared reference points and **5 gates skipped** at startup sync. If the scenario uses any of them, fix or swap them now; a gate that doesn't animate mid-siege is a confusing failure for testers | The scenario's gates all open/close for you before the call |
| P6 | **Accounts.** Delete or deactivate the leftovers from Phase 9 if you want a clean tester list: the `+t2` account (linked to `__dominic14__`), the `+t4` account (unlinked), `alpha-probe`. Keep `__dominic14__` as your own "plain tester" view if you can run a second client | `/admin/invitations` shows only the accounts you expect |
| P7 | **Invites.** `/admin/invitations` → one **personal invite per friend**, group **Alpha Tester** (a personal invite verifies the address and feeds the Access list; a shared code doesn't verify anything). Do this **30 min before the call**, then check `/admin/email` → every invite **Sent** and `/admin/invitations` → *Access sync: last OK · N on the list* (press Refresh; the line doesn't update by itself). Mind the mail limit: 3 mails per address per hour, 3 resends a day; a friend who needs a resend and then gets the linked mail is already at 3 | Every friend confirms "I have the mail" before Part A |
| P8 | **Tools open during the call:** `rcon-cli` (`tps`, `/siege admin list`, `list`); the Minecraft log with `grep -E 'ERROR|SEVERE|\[Siege\]|Teleport of|Refused|InventoryMenu startup validation|KnK Admission'`; the API log; Portainer's stats for `minecraft` and `api`; `/admin/email`; `/admin/invitations`; the findings log (§ 7). Performance metrics ([guide](performance-metrics-and-capacity.md)) are off and untested live, so don't turn them on today: note `tps` and the Portainer memory of the `minecraft` container at the start, during match 1 and at the end, with the player count | All open; the first `tps` line is in the log |
| P9 | **Your own walk-through.** With `__dominic14__` (or any never-joined account) do A1–B3 once end to end on the alpha, today. Phase 9 § 9 left two alpha checks for "when a new tester joins": the expired claim code and the gate-off kill switch; both passed on dev, so only run them if a friend's code expires by itself | The flow works for you from mail to the first-join welcome |

---

## 4. Part A — invitation and sign-up (one friend at a time, on screen share)

Watch for: how long from "I open the mail" to "I'm logged in on the site"; where they read, where they guess; whether
they understand the Cloudflare page is part of the plan.

| ID | Who | Do | Expect |
|---|---|---|---|
| A1 | Tester | Open the invite mail, click the link | `/invite/<token>` opens **without** the Cloudflare login (the bypass application). The sign-up page shows; the invited address is fixed |
| A2 | Tester | Choose a username and password, sign up | The done page says Cloudflare will email a one-time PIN next. Note whether the tester reads that or clicks on |
| A3 | Host | `/admin/invitations` → Refresh | The invite is **Accepted**; *Access sync* count went up by one within seconds |
| A4 | Tester | Open `https://app.knightsandkings.net` | The Cloudflare Access login: email → PIN mail → PIN accepted → the site with the tester logged in, on `/account/link` with the "link your Minecraft account" banner. **Time this step** |
| A5 | Tester | Look around the site for one minute without instructions | Note what they click first and whether the account page, the server address and "How to join" are found without help |
| A6 | Host | `/admin/email` | Invite mail **Sent**; no failures; the relay log shows `status=sent` |
| A7 | Tester (one volunteer only) | Open the invite link a second time after signing up | The generic "invalid or has expired" page, nothing more. (Keep the revoked/expired checks of Phase 9 § 9 for a quiet moment; they passed on 2026-10-24) |

Repeat A1–A4 for each friend. After the first one, the others may run in parallel while you watch A3/A6 for each.

---

## 5. Part B — first join and linking (one friend at a time, on screen share)

| ID | Who | Do | Expect |
|---|---|---|---|
| B1 | Tester | Join `play.knightsandkings.net` | Disconnect screen with a claim code `XXXX-XXXX` and the `/link` address. Ask: is the text readable at their resolution, do they understand what to do? Rejoining shows the **same** code |
| B2 | Host | Minecraft log | One `[KnK Admission] Refused <name> (<uuid>): admission.kick` per attempt, **no code** in the log |
| B3 | Tester | On the site (`/account/link`), enter the code | "Linked" result, the starting balance, a "linked" mail; the banner is gone |
| B4 | Tester | Join again | They get in with the **first-join welcome**, the kits, and quiet minutes (no flood of discovery messages), plus the in-game notice "Your Minecraft account is now linked to the web account xx\*\*\*@…" — **not** "Welcome back". They land at the join spawn (or in the hub if P3 selected one; then: no damage, no building, doors open, the portal to the gameplay world works) |
| B5 | Host | Web app → the tester's player profile | Minecraft name and UUID linked; group **Alpha Tester** |
| B6 | Tester (one volunteer) | Type a wrong code once before the right one on B3 | "Invalid" message, then the right code works. (Five wrong ones lock for 15 min: don't let a friend burn their code on that; it passed on 2026-10-24) |
| B7 | Tester (if one is on Bedrock) | B1–B4 from the Bedrock entrance | Same flow; the `BE_`-prefixed name shows on the profile |

Players whose account existed before the switch-over (grandfathered) skip B1–B3 and just join.

---

## 6. Part C — player experience, navigation and menus (25 min, everyone at once)

Give the tasks one by one in the call; don't say which command does it. Note what they try.

| ID | Task given to the testers | Expect / watch for |
|---|---|---|
| C1 | "Open your menu" | `/menu` opens the main menu with its tiles. If tiles are missing, the server started while the API was down (the KNG-201 shape); the validation retry (P1) is meant to end that; log `InventoryMenu startup validation` lines |
| C2 | "Go two menus deep and come back" | Sub-menu and Back work; a **Bedrock** tester's next menu stays open after a click (with `262c1095` deployed; without it, the flash-close is the known finding) |
| C3 | "Walk to <a town or district you name>" | Domain discovery messages on the action bar, "You are now entering X" with clean names (no `[]`, no stray line breaks: the trimming fix is in the deployed API); whether they find the way at all |
| C4 | "Find out how to get directions" | `/navigate` (alias `/nav`) if the alpha data has a road network: destination list, trail/HUD, `/navigate stop`; the compass if outside-siege targets are set up (compass smoke test § C). If neither exists on the alpha, note it: it's a seed gap, not a bug |
| C5 | "Open a gate" | A gate they may use opens and closes with its animation; one they may not use refuses with a message, not silence (the WorldGuard `deny-message` finding from the hub smoke test) |
| C6 | "Send me a private message" | `/msg` works; whether they find it |
| C7 | (hub selected only) "Get to the game world and back to the hub" | The portal, `/hub`; `/spawn` is refused in the hub (by design: portal only) |
| C8 | "Find out how to join a siege, without asking me" | What they try: `/siege`, `/menu`, chat. The lobby overview from `/siege`; the matchmaking announcement in chat names the join command. Note whether they understood what a siege is from what the game showed them |
| C9 | "Look at your account from the site while in game" | `/account` in game and the account page agree (name, balance) |
| C10 | Host | TPS and container memory with everyone online (P8) |

---

## 7. Part D — siege match 1 (the happy path; host observes)

Start it with `/siege admin start <key>` if the lobby is in cooldown. With 120 s matchmaking the 290 s announcement
never fires; the 60/30/15 marks do. The timeline is T-30 vote close, T-25 draw, T-15 hub, T-10 team split, T-0 start.

| ID | Who | Do | Expect |
|---|---|---|---|
| D1 | All | Join from the chat announcement or `/siege` → overview → join (`/siege join <key>`) | Join confirmation; a running `/navigate` ends ("you joined a siege"); joining twice is refused with a reason |
| D2 | All | Vote: via the menu and via `/siege vote <scenario\|random>` | One vote each; voting for your current choice removes it; the Information menu shows the counts |
| D3 | All | Wait for T-30 / T-25 | "Voting closed", the drawn scenario announced, "teleported to the hub in 15 seconds". If members < `PlayersMin` at the draw: the lobby returns to cooldown with a message (then fix P4 and skip) |
| D4 | All | T-15 | Everyone is teleported to the scenario hub, "You are at the hub of …"; inventories snapshotted; the scenario's gates under lockdown; the siege compass handed out if configured. **Log:** no `[Siege] Teleport of … was refused`. A member standing in the server hub (hub selected) only makes it with the follow-ups deployed (P1); otherwise they silently stay behind: known |
| D5 | All | T-10 | "You are on team …" and the team colours; the **spawn picker** opens for members whose team has 2+ options (with the follow-ups deployed: at the split, in the hub; without: at the start instead). Pick → "You will start the siege at X and respawn there too" |
| D6 | All | T-0 | Teleport to the spawn choice; per-team scoreboard and tab list; the team's start message on the action bar; objectives visible (banner block, capture particles, floating percentage). Ask the testers: "Who is your enemy, where do you go?" **before** they move |
| D7 | Two testers on the same team | Hit each other | Denied. Enemy hits allowed; a hit inside a team's own spawn safe zone is denied with the warning sound; a non-member can't be hit by or hit a member |
| D8 | Attackers | Stand in an objective's capture circle | The percentage rises per second; the defenders inside slow it; the capture announcement; a `SpawnWhenHeld` objective then shows in the spawn picker |
| D9 | Anyone | Die once | No item or XP drops, no vanilla death message; respawn at the spawn choice with full health and food; killer gets kill credit, tab suffix `[K/D]`; streak announcements at 5/10/15 kills |
| D10 | Anyone | `/siege menu` (alias `/sgm`) | The Information menu: votes/join rows gone, objective rows, "Change spawnpoint" with "Current: X"; with the follow-ups the menu is 3 rows for 3 objectives (no empty rows) |
| D11 | Anyone | `/spawn`, `/navigate`, `/hub` during the match | Refused by the command filter; `/msg`, `/r`, `/menu`, `/siege` work |
| D12 | Attackers | Hit the scenario's gate door; the owning alliance opens and closes it | HP display drops per hit; only the owner alliance operates it; non-members walk through where the non-member gate view removes it. Fire Aspect / Cleaving (follow-ups) only if you handed those items out |
| D13 | All | Match end (time or instant-victory objective) | Winner announced; rewards to participants still present; everyone restored to their pre-T-15 location and inventory; gates restored; the lobby enters cooldown. Ask: "Did you understand why that team won?" |
| D14 | Host | Afterwards | `GET /api/siege-matches` lists the match with participants and teams; no ERROR/SEVERE in either log; `tps` during the match noted with the player count |

---

## 8. Part E — siege match 2 (disruptions)

`/siege admin skip <key>` takes the lobby from cooldown into matchmaking, and in matchmaking leaves 31 s. Tell the
testers beforehand which of them does what, so the others don't copy it.

| ID | Who | Do | Expect |
|---|---|---|---|
| E1 | Host | `/siege admin skip <key>` | Cooldown → matchmaking at once; in matchmaking: "the siege begins in 31 s" (with the follow-ups deployed, this is the `AdminSkipMatchmakingSeconds` setting) |
| E2 | One tester | Try to join after T-15 | Refused: joining is closed |
| E3 | One tester | `/siege leave` while in the hub | Removed, votes dropped, restored to where they were; no rewards later |
| E4 | One tester | Close the game mid-match (disconnect) | Removed from the match; no rejoin into it on reconnect; on reconnect they are at their pre-siege location with their own inventory. If their team is now empty, the other alliance wins at once (`TeamEliminated`); if the total drops below `PlayersMin`, the match ends with `NotEnoughPlayers` and normal win resolution |
| E5 | Anyone | Information → Change spawnpoint mid-match, then die | Respawn at the new choice |
| E6 | Host | `/siege admin kick <player>` | The player is removed and restored |
| E7 | Host | `/siege admin stop <key>` before the end (if E4 didn't already end it) | Everyone restored, no rewards, gates restored, cooldown. Then `/siege admin list` reads clean |
| E8 | Bedrock tester (if any) | The siege menus (overview, Information, spawn picker) | Stay open after a click (P1) |
| E9 | (hub selected only) One tester | Wait in the server hub at T-15 | Moved to the scenario hub like everyone else (follow-ups deployed); otherwise known |
| E10 | Host | Optional, after the call: restart the server with a match running | On the next start the gates are restored (`restore-stale-gates`) and the match is aborted in the history |

---

## 9. Findings log

Write the build line first (P1), then one row per finding as it happens. Severity: **blocks** (the tester cannot
continue), **hurts** (continues with help or a workaround), **cosmetic**. The "Help needed?" column is the UX
signal: a step the tester only passed because the host said something is a finding even when nothing broke.

```
Build: plugin <sha> · API <image> · web app <sha> · hub selected: yes/no · testers: N (Bedrock: n)

| # | Step | Tester | What they did | What they expected | What happened (exact chat / log line) | Severity | Help needed? | Time |
|---|------|--------|---------------|--------------------|----------------------------------------|----------|--------------|------|
| 1 | A4   | T1     |               |                    |                                        |          |              |      |
```

Numbers to write down once: time from invite mail to logged in on the site (A4) per tester; time from B1 to the
first-join welcome (B4); `tps` and container memory at P8, C10 and D14 with the player count.

---

## 10. Debrief (15–30 min, everyone)

Ask each tester in turn, before the others comment:

1. First impression in one sentence.
2. The most confusing moment. What were you looking for?
3. The sign-up and linking: would you have done it on your own, without me on the call? Which step would you drop?
4. The siege: did you know who the enemy was, where to go, and what to do to win? When did you first understand it?
5. What did you want to do that you couldn't?
6. Would you come back next weekend? What for?

Then: which three findings would you (the host) fix before run 2, and which flow do you want to retest.

---

## 11. After the session

1. Copy the findings log into `docs/reports/2026-10-25-closed-alpha-run-1.md` with the build line and the debrief
   answers; link it from this guide's status line.
2. Findings go to Linear where the free issue limit allows; otherwise list them in the report's "To file" section as
   the Stage 2 report did.
3. Update `docs/ACTIVE_SESSIONS.md` (this guide's row) and `docs/CHANGELOG.md` only for what was merged and deployed
   for the run, not for the findings themselves.
4. Leave the snapshot from P2 in place until run 2 is planned.
