# Player statistics (KNG-34) — smoke test

**Status:** Run 1 in progress 2026-10-10 — setup and steps 5-10 pass (findings 1, 3-5 fixed, D24); next step 11 ([KNG-34](https://linear.app/kngpandi/issue/KNG-34))
**Last updated:** 2026-10-10 (run 1: setup, steps 5-10, findings 1-5)
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
| 3 | 9 | fail → fixed | With `[AFK]` in the tab list, and after leaving AFK, the name was plain white instead of the group color: the client skips scoreboard-team formatting (KNG-7 colors) for a custom tab-list name, and leaving AFK put back Paper's plain name as a custom name. knk-plugin `83227095`: the marked name carries the team prefix/color/suffix; leaving clears the custom name. Live re-check pending. |
| — | 10 | partly | Finding 3 re-checked live after the restart: group color kept with `[AFK]` and after leaving (pass). Survival only — creative and spectator are excluded by design (the dev world defaults to CREATIVE; the first swim/horse attempts were in creative and rightly not counted). `__pandi__` walk + swim: foot 76.1 → 187.4, `distance.swim` 65.6; MrBedue elytra: flying 129.2, foot 87.4. Boat, minecart and the fall skipped for now; teleport checks (part B) to do. |
| 4 | 10 | fail → fixed | Riding a horse in survival added no distance: the listener skipped every rider `PlayerMoveEvent` and waited for a `VehicleMoveEvent`, but Paper 1.21.10 fires that only from boat and minecart ticks (checked in the server jar: `ServerGamePacketListenerImpl.handleMoveVehicle` fires only the rider's `PlayerMoveEvent`). knk-plugin `3c6903a5`: a mount's distance comes from the rider's move; `VehicleMoveEvent` counts only boats and minecarts (no double count). Re-checked live: horse (and boat) riding → `distance.vehicle` 245.5, no double count (pass). |
| — | 10 | pass | Part B (snapshot first, then no walking): `/tp`, `/tphere`, `/back`, `/kill` + respawn and quit/rejoin (join spawn) added no distance at all. The `/kill` added no death either — `__pandi__` had switched to creative at 22:16 (excluded mode, by design); a survival death at 19:59 had counted (`deaths@open_world`, cause environment). Fall and the KNG-56 domain refusal not tried. |
| 5 | 10 | fail → fixed | Seen in `telemetry_events` while checking part B: some `command.result` events had `UserId` NULL though they carried `__pandi__`'s session key (`/tp` at 20:20:12 NULL, `/back` 2 s later 1). The emitter took the id from the plugin's user cache, whose entries expire while the player is online; the player timeline (filtered by user id) would miss those events, and enhanced mode could lapse. knk-plugin `9543bd8e`: the id is remembered from `UserDataLoadedEvent` until `session.leave`. Re-check in step 19. |
| 2 | 8 | trunk follow-up | Not KNG-34 (page unchanged from trunk `main`): on `/admin/economy/transactions/<id>` the **Reverse** button stays disabled until the reason has ≥ 10 characters, with no visible cue — clicking does nothing and sends no request. The developer asked for it to be updated: show that the button is disabled and why (e.g. a live "n/10 characters" hint, a message on click). |
