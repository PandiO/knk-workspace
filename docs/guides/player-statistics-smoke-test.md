# Player statistics (KNG-34) — smoke test

**Status:** Not run yet — branches ready 2026-10-10 ([KNG-34](https://linear.app/kngpandi/issue/KNG-34))
**Last updated:** 2026-10-10 (written for the first run)
**Design:** [specs/player-statistics/DESIGN.md](../specs/player-statistics/DESIGN.md) (decisions D1-D23, §F) ·
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
   `./gradlew :knk-paper:dev`; run `scripts/reset-content-menus.ps1` (new menus `statistics.visibility`,
   `statistics.main`, `statistics.leaderboards`, `statistics.leaderboard` and profile tiles 5 and 6 are seeded
   create-only); restart. Expected: "Player statistics started", "Diagnostic telemetry started", "World analytics
   started …", no menu validation errors. `config.yml` blocks `statistics:`, `telemetry:`, `world-analytics:` default to on.
4. **Web app:** `npm install`, `npm start` (or build). No new dependencies.
5. **Grants.** Give **your own user** these nodes **directly** (player profile → Effective Permissions → grant, or
   `POST api/users/{id}/grants`): `knk.owner.telemetry.view`, `knk.owner.telemetry.manage`, `knk.owner.privacy.manage`,
   `knk.owner.analytics.view`, `knk.owner.leaderboard.manage`. Wildcards (`*`, `knk.*`) deliberately don't unlock them.
   Check the seed (D22): group **Moderator** has `knk.admin.statistics.view`; **Admin** has it plus
   `knk.admin.privacy.request`.
6. Web nav (as you): Diagnostics, Data deletion and World analytics appear. As an account with only `knk.*`: none of
   the three, and opening `/owner/telemetry` says "Owner only".

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

| # | Step | Result | Notes / fix |
|---|---|---|---|
| | | | |
