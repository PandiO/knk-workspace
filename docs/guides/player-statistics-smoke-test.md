# Player statistics (KNG-34) — smoke test

**Status:** Passed and merged 2026-10-11 — run 1: all 27 steps pass after fixes (findings 1, 3-5, 8-12 fixed and live-checked, decision D24; trunk follow-ups 2 → KNG-126, 6-7 on `claude/reset-on-death`; blinker KNG-125). Merged: knk-web-api `master` `34b8f9b`, knk-plugin `main` `aa5df70a`, knk-web-app `main` `5f40f93` ([KNG-34](https://linear.app/kngpandi/issue/KNG-34))
**Last updated:** 2026-10-11 (merged)
**Design:** [specs/player-statistics/DESIGN.md](../specs/player-statistics/DESIGN.md) (decisions D1-D24, §F) ·
**Background:** [progress report](../reports/2026-10-03-player-statistics-chain.md) (per-link details, flagged decisions)

Run on the dev server with the branch `claude/kind-dijkstra-y9d279` checked out in knk-web-api, knk-plugin and
knk-web-app (trunks merged in 2026-10-10). Use a **non-op alt** for every permission and visibility step — ops pass
every in-game check. Record each step's result in **Findings** at the end (pass / fail + what you saw).

## 0. Setup

1. **Back up the dev database.** The ledger projector writes rows for all past ledger activity on first start (D17),
   and data deletion is irreversible.
2. **API:** `dotnet build`, then `dotnet ef database update`. Pending KNG-34 migrations (they sort before some trunk
   migrations; EF applies them anyway): `AddPlayerStatistics`, `AddLeaderboards`, `AddDiagnosticTelemetryAndPrivacy`,
   `AddWorldAnalytics`, `AddDataDeletionRequestFlow`, `SeedStatisticsStaffNodes`. Use the Development settings
   (`Email:Provider` `Log`: the data-deletion confirmation link is written to the API log instead of emailed). Start the
   API. Expected log lines: "Statistics projection started", "Leaderboard snapshots started: every 300s", "Diagnostic
   telemetry writer started: every 2s", "World analytics retention: removed 0 daily rows, 0 batch ids".
3. **Plugin:** `./gradlew build -x deployToDevServer` (records the test counts — baseline in the progress report), then
   `./gradlew :knk-paper:dev`; with the API running, run knk-web-api's `scripts/reset-content-menus.ps1` and restart
   the API (it deletes the seeded content menus, `profile.main` among them, so the API re-seeds them; new menus `statistics.visibility`,
   `statistics.main`, `statistics.leaderboards`, `statistics.leaderboard` and profile tiles 5 and 6 are seeded
   create-only); restart. Expected: "Player statistics started", "Diagnostic telemetry started", "World analytics
   started …", no menu validation errors. `config.yml` blocks `statistics:`, `telemetry:`, `world-analytics:` default to on.
4. **Web app:** `npm install`, `npm start` (or build). No new dependencies.
5. **Grants.** Give **your own user** these nodes **directly** (player profile → Effective Permissions → grant, or
   `POST api/users/{id}/grants`): `knk.owner.telemetry.view`, `knk.owner.telemetry.manage`, `knk.owner.privacy.manage`,
   `knk.owner.analytics.view`, `knk.owner.leaderboard.manage`. Wildcards (`*`, `knk.*`) deliberately don't unlock the
   telemetry and privacy nodes; they do unlock analytics and leaderboard (D24).
   Check the seed (D22): group **Moderator** has `knk.admin.statistics.view`; **Admin** has it plus
   `knk.admin.privacy.request`.
6. Web nav (as you): Diagnostics, Data deletion and World analytics appear. As an account with only `knk.*` (D24):
   World analytics appears and opens, Diagnostics and Data deletion don't appear, and opening `/owner/telemetry` or
   `/owner/privacy` says "Owner only".

## 1. Statistics capture

7. Join, wait a minute → web `/account` → Statistics (or `GET api/statistics/users/{id}`): logins +1, active time grows.
   Within a minute of the API's first start, past `xp_gained`, coins/gems earned/spent and title history appear (D17).
8. Earned/spent count every gain and loss (D20): `/pay` the alt 10 coins → your coins spent +10, the alt's earned +10; a
   staff coin grant counts as earned; a teleport fee as spent; a refund lowers spent again.
9. Idle 5 minutes → "You are now AFK" and `[AFK]` in the tab list; `/afk` toggles; AFK time grows instead of active
   time. Standing in a water stream or on a pressure plate keeps you AFK.
10. Walk, swim, fly with an elytra, ride a boat/minecart/horse → distance per mode; survive a ~10-block fall → highest
    fall. **Teleports don't count:** `/tp`, `/back`, joining at the join spawn (KNG-52) and respawning add no distance.
    Walking into a domain you may not enter (KNG-56) adds at most a block.
11. Combat: hit a player and a zombie (damage both ways); kill the alt twice, die once, kill again →
    `pvp_kills` +3, `deaths` +1, `highest_killstreak` 2. Spawner/bred mobs don't count as PvE kills; arrows count,
    tridents and fireworks don't.
12. Siege: headshots (multiplier > 1) count; kills/deaths/wins appear after the match ends, never twice; a gate hit plus
    fire by two players → `gate_damage` matches the HP lost and gate HP behaves exactly as before. Leave a match early →
    your participant row has `LeftAt`, no reward, `losses` +1.
13. Stop the API, play a minute → files appear in `plugins/KnightsAndKings/statistics-spool/`; start the API → replayed
    and deleted, nothing counted twice.

## 2. Privacy and read surfaces

14. `/stats settings` (and Profile → Statistics privacy): cycle a setting; a group action shows a preview → Confirm.
    Change the same setting on the web meanwhile → the menu says it changed elsewhere.
15. Profile → Statistics, `/stats`, `/stats <other>`: the alt sees only what you set to Everyone; title history shows.
    Tab-completing `/stats ` offers `settings` plus the players you can see (vanished staff hidden, KNG-30).
16. `/leaderboard` → a board → a head → that player; `/lb active_playtime monthly`. Kill the alt 5× in a day →
    `pvp_kills` +5 but the PvP board +3 (repeat-victim cap).
17. Web: `/account` Statistics and "Who may see my statistics"; `/players/<name>` and `/leaderboards` signed out (only
    always-public fields and boards) and signed in; the staff panel on `/admin/users/<id>` only with
    `knk.admin.statistics.view` (a Moderator alt sees it). Leaderboard exclusion via `PUT api/leaderboards/exclusions/{id}`.
18. **Discoveries (D21):** in Discovery settings switch one type off (e.g. Structure) → your statistics' discovery
    counts, the named list and the discoveries board leave that type out, and the total equals your `/discoveries`
    total. Switch it back on → counted again.

## 3. Diagnostics and data deletion (owner)

19. Join → a `session.join` event in `/owner/telemetry` within ~10 s. Vertical slice: start a test run and add an
    enhanced target, the alt joins, opens menus, gets refused by `/siege join`, plays a match with a reward → ordered
    events, the player timeline with the Siege row and the ledger posting, correlated events in the drawer.
20. **Player request** (throwaway account **with an email address**): `/account` → Delete my data → "Email me the
    confirmation link" → the link appears in the API log → open it → **Yes** → "deleted on <+5 days>". On `/account`
    the scheduled deletion shows; **Cancel deletion** works. Request again and confirm; leave it scheduled.
21. **Staff filing:** as an Admin alt (`knk.admin.privacy.request`), another throwaway's profile → Data deletion →
    Request data deletion… → File (no email step). The player's `/account` shows "requested by staff on your behalf";
    staff can cancel it.
22. `/owner/privacy`: both requests with source and status; Review & delete shows the counts (including
    `road_tile_proposals.created_by`, D23); **Delete now** is disabled during the grace period.
23. To see an erasure now: set `Privacy:GraceDays` to `0`, restart the API, file a staff request for a throwaway that
    has statistics, PMs, a rank and (optionally) a road-builder proposal in its name → within the hourly job (or Delete
    now) the account becomes `deleted-<id>`; statistics, PM logs, link codes, grants, group memberships, audit rows about
    it and its name on road proposals are gone; `POST api/statistics/rebuild` gives it nothing back. Set `GraceDays`
    back to 5.

## 4. World analytics (owner)

24. Walk a few minutes (not AFK) → after ≤ 5 min `/owner/analytics` shows your path (cell sizes 16/64); AFK or
    spectator → no new samples. Navigating with `/nav` draws its trail as before.
25. Profile → Statistics → back → close → funnel rows for `profile.main` and `statistics.main`. Note what "closed"
    counts (it may include the close Paper fires when one menu replaces another — L7-5).
26. Enter and leave a town/district/structure → entries/exits; discover a new domain → discoveries +1.

## 5. Kill switches

27. Plugin `statistics.enabled: false` → "Player statistics disabled", `/afk` says disabled; `telemetry.enabled: false`
    → no telemetry; `world-analytics.enabled: false` → "World analytics disabled". API `Statistics:Enabled=false` →
    statistics batches 503 (the plugin keeps spooling); `Leaderboards:Enabled=false` → boards keep their last snapshot;
    `Privacy:AutoExecuteEnabled=false` → scheduled deletions wait for the owner. Restore all switches.

## 6. Merge (only after every step passes and the developer agrees)

Order **knk-web-api → knk-plugin → knk-web-app → knk-workspace**: merge `origin/<trunk>` into
`claude/kind-dijkstra-y9d279` once more, rebuild/retest, then merge the branch into the trunk (knk-web-api `master`,
others `main`). Afterwards: move the CHANGELOG "Unreleased" KNG-34 entry to the merge date, set the three KNG-34
FEATURE_REGISTER rows to `trunk`/live-tested, update this guide's status, the tracker and Linear KNG-34.

## Findings

Run 1, 2026-10-10 (local session; worktrees `Repository/_worktrees/<repo>-kng34`). Trunks merged in first: knk-web-api
`09de0d0` (KNG-81), knk-plugin `557ad232` (KNG-108), knk-workspace `5483da7`; knk-web-app already current. DB backup
`db-backups/knightsandkings_dev_v2_2026-10-10_pre-KNG34-smoke.sql`.

| # | Step | Result | Notes / fix |
|---|---|---|---|
| — | 1 | pass | Backup taken before the migrations and the first API start. |
| — | 2 | pass | `has-pending-model-changes`: none. Exactly the six KNG-34 migrations were pending; the developer applied them. All four log lines; ledger projector cursor at 481 after the first start (D17). knk-web-api tests: 2375 passed / 9 failed / 73 skipped — the 4 known (`ClientActivityStore`, `FieldValidation`, `PathResolution` ×2), `CurrencyWriteGuard` (test build in a scratch artifacts path, which it can't find the csproj above), and 4 trunk tests that fail on this machine's comma-decimal number format (`TransferPolicyEvaluator` daily cap, `CurrencyAnomalyDetector` ×2, `RoadNetworkService` geometry) — not KNG-34's. KNG-34's own `StatisticsFormattingTests` failed the same way (test-only parsing); fixed in `7194412`. |
| — | 3 | pass | First compile after the trunk merges succeeded: knk-core 1994, knk-api-client 240 (2 skipped), knk-paper 1562 (18 skipped), 0 failures. The reset script is knk-web-api's (step text corrected); it removed 9 menus, the API re-seeded them plus the four statistics menus. Server log: the three "started" lines, "checked 27 menu(s), 0 blocked", no KnK warnings. |
| — | 4 | pass | Web app run from the worktree (`npm ci`). |
| — | 5 | pass | D22 seed confirmed in `permission_grants` (Moderator: statistics.view; Admin: statistics.view + privacy.request). Owner grants added on the web; the pages worked straight away (no new login needed). |
| 1 | 6 | fail → fixed | As `__pandi__` with only `knk.*`/`knk.admin.*`: the nav showed Diagnostics, Data deletion and World analytics, but each page said "Owner only" (nav counted wildcards, the API wanted an exact grant). The developer wanted `knk.*` to work, then chose a split: **D24** — wildcards unlock `knk.owner.analytics.view` and `knk.owner.leaderboard.manage`; telemetry and privacy keep the exact grant. knk-web-api `22c64e9` (`OwnerPermissions.ExactGrantOnly`), knk-web-app `edee8f6` (nav and owner routes use `matchedNode` for the exact-grant nodes). With all five grants: all three pages open (pass). Re-run with only `knk.*` for telemetry.view, privacy.manage and analytics.view: World analytics shown and opens, Diagnostics and Data deletion hidden, both URLs "Owner only" (pass). |
| — | 7 | pass | Join → session row (active 145 s), 3 stat batches in 2 min, logins 1, active time on `/account`. The D17 import was there before the join: coins/gems earned/spent, `xp_gained` and 13 Siege matches' results for all three players. Coins earned +3371 at the join = the salary payout (ledger #170), projected as earned. |
| — | 8 | pass | Alt MrBedue (id 3). `/pay` 20: your coins spent 10 → 30, his earned +20; salary on his join +6558 earned; staff grant `ADMIN_GRANT` +75000 earned (25,289,866 → 25,371,444, exact); teleport fee −1 gem → gems spent 145 → 146; reversal #175 of the fee → back to 145, earned unchanged (D20). |
| — | 9 | pass | Idle 5 min → "You are now AFK" and `[AFK]`; moving and `/afk` toggle; water stream and pressure plate keep you AFK. Session: active 433 s + AFK 819 s = the session length exactly (19:23:23-19:44:14; AFK also covers the idle minutes during step 8). |
| 3 | 9 | fail → fixed | With `[AFK]` in the tab list, and after leaving AFK, the name was plain white instead of the group color: the client skips scoreboard-team formatting (KNG-7 colors) for a custom tab-list name, and leaving AFK put back Paper's plain name as a custom name. knk-plugin `83227095`: the marked name carries the team prefix/color/suffix; leaving clears the custom name. Re-checked live after the restart (step 10 row): colour kept (pass). |
| — | 10 | partly | Finding 3 re-checked live after the restart: group color kept with `[AFK]` and after leaving (pass). Survival only — creative and spectator are excluded by design (the dev world defaults to CREATIVE; the first swim/horse attempts were in creative and rightly not counted). `__pandi__` walk + swim: foot 76.1 → 187.4, `distance.swim` 65.6; MrBedue elytra: flying 129.2, foot 87.4. Boat, minecart and the fall skipped for now; teleport checks (part B) to do. |
| 4 | 10 | fail → fixed | Riding a horse in survival added no distance: the listener skipped every rider `PlayerMoveEvent` and waited for a `VehicleMoveEvent`, but Paper 1.21.10 fires that only from boat and minecart ticks (checked in the server jar: `ServerGamePacketListenerImpl.handleMoveVehicle` fires only the rider's `PlayerMoveEvent`). knk-plugin `3c6903a5`: a mount's distance comes from the rider's move; `VehicleMoveEvent` counts only boats and minecarts (no double count). Re-checked live: horse (and boat) riding → `distance.vehicle` 245.5, no double count (pass). |
| — | 10 | pass | Part B (snapshot first, then no walking): `/tp`, `/tphere`, `/back`, `/kill` + respawn and quit/rejoin (join spawn) added no distance at all. The `/kill` added no death either — `__pandi__` had switched to creative at 22:16 (excluded mode, by design); a survival death at 19:59 had counted (`deaths@open_world`, cause environment). Fall and the KNG-56 domain refusal not tried. |
| 5 | 10 | fail → fixed | Seen in `telemetry_events` while checking part B: some `command.result` events had `UserId` NULL though they carried `__pandi__`'s session key (`/tp` at 20:20:12 NULL, `/back` 2 s later 1). The emitter took the id from the plugin's user cache, whose entries expire while the player is online; the player timeline (filtered by user id) would miss those events, and enhanced mode could lapse. knk-plugin `9543bd8e`: the id is remembered from `UserDataLoadedEvent` until `session.leave`. Re-check in step 19. |
| — | 11 | pass | Open world (`open_world` context). `__pandi__` killed MrBedue 3×, died to him, killed him again: `pvp_kills` 4, `highest_killstreak` 3 (reset by the death), `deaths` 1 → 2 (`deaths_by_cause.player` 1), `pvp_kills.ranked` 3 — the 4th kill of the same victim that day is over the repeat-victim cap (D7, step 16). MrBedue: deaths 5 (zombie → `deaths_by_cause.mob`, 4× player), `pvp_kills` 1. Zombie kill → `pve_kills` 1; damage dealt/received per player/mob recorded. MrBedue's received-from-player (103.5) exceeds `__pandi__`'s dealt-to-player (87.2) because hits while the attacker is in creative (22:29:50-22:30:03) count only for the victim — by design (excluded modes). Bow/spawner/trident PvE rules done by the developer, no remarks. |
| 6 | 11 | trunk follow-up | Not KNG-34 (`CombatTagListener`, teleport feature, unchanged on the branch): the teleport combat tag survives death — after dying shortly after a fight, player teleports still refuse with the combat message. The developer wants the combat status reset on death: clear the dead player's tag in `PlayerDeathEvent` (and add it to teleport DESIGN §3.4.3). Fixed on a separate trunk branch at the developer's request (knk-plugin `claude/reset-on-death` `4cc0e03a`, with finding 7) and merged 2026-10-11: knk-plugin `main` `c0ad2a9b` (unit-tested, not checked in game). |
| — | 12 | pass | Match 14 (time expired; MrBedue's side won): `__pandi__` 2 kills / 3 deaths / streak 2 / 1 capture, MrBedue 3 / 2 / 2. Projected once each at the match end (`statistics_projected_sources` siege_match 14 at 20:44:49, 15 at 20:46:49): `__pandi__` `pvp_kills@siege` 2 → 4, deaths 5 → 8, streak 2, objectives 3 → 4, losses 6 → 8 (14 + leaving 15), wins unchanged; MrBedue `pvp_kills` 1 → 4, deaths 2 → 4, wins 3 → 5. Headshots 3 each. Match 15: `__pandi__` left → `LeftAt` 20:46:35, no coins/XP/gems, loss +1; MrBedue rewarded normally. `gate_damage@siege` 240 for `__pandi__` only (MrBedue defended); the developer confirmed the gate lost 240 HP (`siege_match_gate_snapshots` is empty for every match, so not readable from the DB). The fire part (a second player with fire) was not tried. |
| — | 13 | pass | API stopped 22:54:55-22:57:17 (local). Two batches spooled (`f7595d37`: MrBedue's and `__dominic14__`'s quits during the outage; `3bada6b2`: a minute of `__pandi__`'s walking), retried and re-spooled while down. After the start both were replayed in the first flush (20:57:19 UTC) and the folder was empty 4 s after the API came up; each batch id is in `player_stat_batches` once, the quits got their real end times, foot 844.7 → 1399.3 with nothing doubled. Bonus: a survived fall → `highest_fall` 12.3 (the fall part of step 10). |
| — | 14 | pass | `/stats settings` and Profile → Statistics privacy open the menu; cycling a setting and a group action with preview → Confirm work (combat stored in `player_stat_visibility`). The "changed elsewhere" check failed at first → finding 8; re-check after the fix: preview, web change, Confirm → the yellow "changed elsewhere" message, the menu showed the web value, nothing overwritten (pass). |
| 8 | 14 | fail → fixed | Menu set Combat to Everyone, then the web set it to Friends while the menu stayed open, then a group action Nobody → Confirm in the menu: saved without the "changed elsewhere" message. The preview was built from the menu's old copy (Everyone), the repaint after the click re-read the settings (older than 5 s → new GET, Friends), and Confirm recomputed the changes from that read, so "expected" = Friends and the API's conflict check passed. knk-plugin `ca70602f`: the changes are remembered with the preview and sent as they are on Confirm. Re-checked live (pass). |
| 9 | 14 | UX, fixed | The developer found the privacy menu overwhelming and the open group unclear (only a glint). Agreed redesign: group names show the open one ("▶ Combat ◀", "Shown below"; others grey), the info item is named after the group, the header holds only the groups and Back, the three "Set all listed to …" actions moved to the bottom row (46-48; Confirm/Cancel 50/51), context rows only for overrides (per-game values on the website, hinted on the row). The menu title can't be dynamic (fixed when the inventory opens). knk-web-api `f91a52c`, knk-plugin `d84a09fb`; template re-seeded (old `statistics.visibility` deleted via the API, API restarted). The developer also wants the v1/v2 item blinker back — documented and postponed: [KNG-125](https://linear.app/kngpandi/issue/KNG-125), inventory-menu IMPLEMENTATION_PLAN "Follow-up: item blinker". Checked live: "fine" (pass). |
| — | 15 | pass | Finding 9's new layout checked live ("fine"). Own statistics and title history show; MrBedue's `/stats __pandi__` shows only Everyone settings plus the always-public fields; `/stats ` Tab offers `settings` and the visible players. |
| — | 16 | pass | PvP boards were empty until Combat was set to Everyone — by design (§F.11: configurable metrics rank only when Everyone; default Nobody). Snapshot 21:30 UTC, lifetime: `pvp_kills@open_world` `__pandi__` **3** (4 kills of MrBedue today, repeat-victim cap 3), MrBedue 1; `pvp_kills@siege` 4 / 4 both rank 1 (competition ties); `pvp_kills` 7 (3 + 4) / 5. `/leaderboard` → board → head → that player's statistics works. `/lb active_playtime monthly` answers in chat — as documented (`LeaderboardCommand`: a board argument prints the top 10 in chat; only plain `/lb` opens the menu); the developer was unsure what to expect — the developer chose the menu: finding 10. |
| 10 | 16 | change, fixed | Developer decision: `/lb <board> [period]` should open the board menu, not print to chat. knk-plugin `7ce1f2dc`: a player gets `statistics.leaderboard` on that board and period; the console, an unknown board and a server without menus keep the chat lines. Checked live: `/lb active_playtime monthly` opens the board menu on Monthly (pass). |
| — | 17 | pass | `/account` Statistics and "Who may see my statistics" match the menu. Signed out, `/players/__pandi__` shows only always-public fields (experience, coins, gems, active/AFK time, first joined, XP gained) and "Sign in to see the statistics this player shares with everyone" — by design (L1-3: "everyone" means signed-in viewers; the step text expected the Everyone values). Signed out `/leaderboards` only always-public boards; signed in also the PvP boards. Staff panel on `/admin/users/3` as `__pandi__` and as a Moderator alt. `PUT api/leaderboards/exclusions/3` → 204; from the next snapshot (21:49:41 UTC) MrBedue is on no board, always-public ones included. |
| — | 18 | pass | D21: switching the District discovery type off removed the District count (5 of 6 → not shown) from the statistics, and the total matched `/discoveries`; switched back on → counted again. MrBedue's leaderboard exclusion removed again (`DELETE`, back on the boards from 21:59:41 UTC). |
| — | 19 | pass | `session.join` within seconds; test run "Smoke 19" (#1) with MrBedue as enhanced target: menus, a refused `/siege join`, a full match with reward → ordered events, player timeline with the Siege row and the ledger posting, correlated events in the drawer. DB: 163 events in the run (117 `movement.sample`, 7 `menu.click` enhanced; `command.result`, `menu.*`, `siege.*`, `session.*` baseline) — every player event has its `UserId` (finding 5 re-checked live, pass); only `siege.match_phase` has none (a lobby event). |
| 11 | 19 | fail → fixed | The event drawer couldn't be closed and clipped under the nav: it was `fixed z-40`, the nav `fixed z-50`, so the nav covered its top and the close button. knk-web-app `28298b5`: a layer above the nav (z-60) with a backdrop; the X, a backdrop click and Escape close it. Re-checked live: the X, a backdrop click and Escape close it (pass). |
| — | 20 | pass | API run with `Email__Provider=Log` (the developer's user secrets set `Smtp`; the env var overrides them for this run only). Throwaway `smoke20` (#34): "Email me the confirmation link" → link in the API log → Yes → scheduled 5 days ahead (request #1, due date +30 days); Cancel deletion worked (#1 cancelled by the player); requested and confirmed again → #2 left scheduled for 2026-10-15. |
| — | 21 | pass | `__pandi__` (Admin, D22 `knk.admin.privacy.request`) filed for `smoke21` (#35) from its profile, no email step (#3, source staff); `/account` showed "requested by staff on your behalf"; staff cancelled it (#3) and filed again (#4, scheduled 2026-10-15). |
| — | 22 | pass | `/owner/privacy` lists both open requests with source and status; Review & delete shows the counts including `road_tile_proposals.created_by` (D23); Delete now is disabled during the grace period. Note: #2 and #4 auto-execute on 2026-10-15 if the API runs then (throwaway accounts). |
| — | 23 | pass | The developer chose the alt `__dominic14__` (#30) despite the advice to use a throwaway; fresh full backup first (`db-backups/knightsandkings_dev_v2_2026-10-11_pre-KNG34-erasure-step23.sql`). API run with `Privacy__GraceDays=0`; staff request → Delete now (#6): account `deleted-30` (no email/UUID, "GDPR erasure"); 184 rows deleted — statistics (27 daily, 16 totals, profile, session, 5 title changes), 41 PM logs, 2 link codes, 3 grants, 1 group membership, 71 audit rows about him, 8 discoveries, 2 telemetry events, 6 leaderboard entries. Left on purpose: the `PrivacyDeletionExecuted` audit row and the ledger/Siege match rows under the pseudonymized account (D14-D16). He had no road-builder proposals, so D23 stayed untested live (count 0). `POST api/statistics/rebuild` (ledger replayed to #542) gave him nothing back. API restarted with the normal 5-day grace period. |
| — | 24-26 | pass (closes → finding 12) | `/owner/analytics`: the walked route on the heatmap (cell sizes switch), no samples while AFK/spectator, `/nav` trail as before; menu funnel rows for `profile.main` and `statistics.main` (opens, back); domain entries/exits and a discovery. 33 analytics batches so far. Observation, no fix: batches report 2-10 "rejected" rows each — `UnknownRegion`, i.e. entries/exits of WorldGuard regions that are no domain, which the API drops by design (`DomainInteractionRecorder`: "the API keeps the regions that are domains"); counting them as rejected could read as data loss in monitoring. |
| 12 | 25 | fail → fixed | Menus closed with Escape (≥ 5 times) never showed as "closed" in the funnels: `MenuLifecycleListener` removed the open-menu context before `MenuService.onMenuInventoryClosed`, which reads the closed menu's key from it, so every close reached the observers (funnels and telemetry) without a key. knk-plugin `526c3777`: observers first, then the context; a test drives the real listener. Re-checked live: after the fix the first batch brought "closed" rows (`main` 3×, `profile.main`, `statistics.visibility`, … 1× each) (pass). |
| — | 27 | pass | Round A (plugin `config.yml` `statistics`/`telemetry`/`world-analytics` `enabled: false`, temporary block, then restored byte-for-byte): log "Player statistics disabled", "Diagnostic telemetry disabled", "World analytics disabled"; `/afk` says disabled; no batch of any kind after the restart. Round B (API env `Statistics__Enabled=false`, `Leaderboards__Enabled=false`, `Privacy__AutoExecuteEnabled=false`): log "Statistics projection disabled", "Leaderboard snapshots disabled", "GDPR deletion auto-execution disabled … only expiring confirmation links"; statistics batches answered 503 `StatisticsDisabled` and the plugin spooled 3; telemetry kept arriving; boards kept serving their last snapshot (23:01:22 UTC). All switches restored: the 3 spooled batches replayed once each within seconds. A due deletion waiting for the owner wasn't observed live (none was due). |
| 7 | 12 | trunk follow-up, fixed separately | Not KNG-34 (KNG-11 enchantments): a Freeze enchantment freeze survived death — after respawning the player still couldn't move until it ran out. Audit of all effects: the potion-based ones (blindness, nausea, slowness, poison, wither, resistance, strength, invisibility) are cleared by death in vanilla; Chaos/FlashChaos only knock back; HealthBoost's heal-over-time could still set the health of a dead player. knk-plugin `claude/reset-on-death` `4cc0e03a`: `FreezeMovementListener` unfreezes on any `EntityDeathEvent`, `HealthBoostEffect` stops when the player is dead, plus finding 6's combat tag. Merged 2026-10-11: knk-plugin `main` `c0ad2a9b` (unit-tested, not checked in game). |
| 2 | 8 | trunk follow-up | Not KNG-34 (page unchanged from trunk `main`): on `/admin/economy/transactions/<id>` the **Reverse** button stays disabled until the reason has ≥ 10 characters, with no visible cue — clicking does nothing and sends no request. The developer asked for it to be updated: show that the button is disabled and why (e.g. a live "n/10 characters" hint, a message on click). Linear [KNG-126](https://linear.app/kngpandi/issue/KNG-126). |
