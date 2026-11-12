# Realtime channel (SignalR) — smoke test

**Status:** All sections run by the developer (WT2 2026-11-04; WT2 follow-ups, S1, S2, S3 2026-11-05) and merged into the
default branches; S1–S3 issues closed 2026-11-05. `realtime.enabled` stays `false` by default. § S4 (#183) is on the
feature branch `claude/realtime-web-live-183`, not run yet
**Last updated:** 2026-11-06 (§ S4 step 9: `Realtime:WebLiveUpdatesEnabled` switch, #183, feature branch); 2026-11-05 (§ S4, #183, feature branch); 2026-11-05 (S1, S2, S3 findings; S2 steps 5 and 7 corrected); 2026-11-05 (§ WT2 follow-ups: findings, merged); 2026-11-04 (§ WT2 follow-ups #239/#240, feature branch); 2026-11-04 (WT2 findings; merged); 2026-11-02 (§ S3, #182); 2026-11-02 (§ WT2, #181)
**Design:** [specs/realtime-signalr/DESIGN.md](../specs/realtime-signalr/DESIGN.md) (§4–§5, as built: §4.6) ·
[IMPLEMENTATION_PLAN.md](../specs/realtime-signalr/IMPLEMENTATION_PLAN.md) ·
**Issues:** [PandiO/knk-workspace#178](https://github.com/PandiO/knk-workspace/issues/178) (S1),
[#179](https://github.com/PandiO/knk-workspace/issues/179) (S2), [#181](https://github.com/PandiO/knk-workspace/issues/181) (WT2),
[#182](https://github.com/PandiO/knk-workspace/issues/182) (S3), [#183](https://github.com/PandiO/knk-workspace/issues/183) (S4), parent
[#66](https://github.com/PandiO/knk-workspace/issues/66)

Manual checks of the realtime channel between knk-web-api and the game server, one section per phase. Run on the dev
server with a non-op account and a second player where a step says so. Record each run under **Findings** at the end.
`realtime.enabled` stays `false` everywhere else until the section of that phase passed (DESIGN §12 Q15).

## S1 — foundation: connect, reconnect, resync, presence (#178)

**Builds:** knk-web-api and knk-plugin on `claude/realtime-signalr` (`dotnet run`; `./gradlew :knk-paper:dev`).
**API:** no new setting; the defaults are section `Realtime` in `appsettings.json` (grace 60 s). Keep
`Security:PluginApiKey` set (the hub refuses the plugin without it).
**Plugin `config.yml`:** a config from an older build has no `realtime:` block (the plugin only adds missing keys on
a fresh file). Add it:

```yaml
realtime:
  enabled: true
  server-id: "dev-1"
  hub-url: ""          # empty: api.base-url without /api + /api/hubs/game
```

1. **Off changes nothing.** First start the plugin with `realtime.enabled: false`. The log says
   `Realtime channel disabled (realtime.enabled: false); polls and TTLs as before`; `/knk health` shows
   `realtime: off`; the API log has no `Game server ... connected` line. Everything else behaves as on `main`.
2. **Connect.** Set `enabled: true`, restart the server. Plugin log, in this order:
   `Realtime channel: connecting to http://…/api/hubs/game as server 'dev-1'`,
   `Realtime: connected to the game hub`, `Realtime resync after connect: 5 step(s)` (4 when lootboxes are off; S2 added
   "online users" and "player notifications"). API log:
   `Game server dev-1 connected to the realtime hub (…)` and `Game server dev-1 roster: N online; … corrected`.
   `/knk health` shows `realtime: connected as 'dev-1' for …s, connects 1, messages 1, resyncs 1, gaps 0`
   (the one message is the `Welcome`).
3. **Presence follows join and quit.** With the player online, the player profile / moderation list in the web app
   shows them online. Quit: within a second they show offline (`LastSeenAt` moves). Join again: online.
4. **API restart.** Stop the API. Plugin log: `Realtime: connection to the game hub closed (…)`, then one
   `connect … failed` per attempt (about 1 s, 2 s, 5 s, 10 s, then every 30 s), until the connectivity probe says
   DOWN: then no more attempts. Start the API. When `/knk health` shows UP again, the plugin connects at once:
   `Realtime: connected to the game hub (reconnect)`, `Realtime resync after reconnect: 5 step(s)`.
5. **Presence after a crash (reconcile).** With a player online, kill the game server (no clean stop) and restart
   the API while the server is down. In the database (or the moderation list) the player is still `IsOnline`.
   Start the game server without that player joining: after the first roster the API log says `… presence row(s)
   corrected` and the player shows offline.
6. **Grace period.** With a player online, stop the game server cleanly and leave it down. The player stays online
   for about 60 s, then the API log says `Game server dev-1 did not reconnect within 60s: 1 player(s) marked
   offline`. Start the server again within 60 s instead: nothing is marked offline.
7. **Resync runs the existing refresh paths.** Change a game setting or a warp in the web app, then restart the API
   (step 4): after the reconnect the change is in game without `/knk cache refresh`.
8. **World-task server id.** Claim a world task in game (`/knk task-claim <code>`): the task's `ClaimedByServerId`
   (API `GET /api/WorldTasks/{id}`) is `dev-1`. With the `realtime:` block removed it is `localhost` as before.
9. **No waiting.** With the API stopped, players join, chat and run commands as before (no lag spike when a
   reconnect attempt runs: the client has its own thread).
10. **Wrong key or id.** Set `api.auth.api-key` to a wrong value: the plugin logs `connect to the game hub failed
    (… 401 …)` and keeps retrying with backoff; the rest of the plugin behaves as with any wrong key. Set
    `server-id: "has spaces"`: the plugin falls back to `localhost` (config validation).

Optional, with `metrics.enabled: true` (KNG-232): `curl` the plugin's `/metrics` and find `knk_realtime_state{state="connected"} 1`,
`knk_realtime_connects_total`, `knk_realtime_messages_total{type="Welcome"}`.

## S2 — user state pushed to the game server (#179)

**Builds and config:** as S1 (same branch, `realtime.enabled: true`). Optional new key, default 4:
`realtime.fallback-poll-multiplier: 4`. **API:** nothing new. **People:** player **P** (non-op, online in game), staff
member **S** logged in to the web app with the user/permission/currency/moderation nodes. Goal for every change below:
**visible in game in under 2 s** (DESIGN R1). With `/knk health` the `messages` count goes up by one per event.

1. **Rank.** S gives P a premium rank (player profile → Ranks). In game at once: the tab list prefix and footer, the
   chat prefix. Remove it again: back to Default at once. The tab-list team colour is
   right without a rejoin (the #76 display symptom).
2. **Group node edit.** S adds a node P can feel to a group P is in (e.g. `knk.mode.staff` to P's group, or a command
   node): within 2 s P can use it (the command shows in the "/" list, `/staffmode` works). Remove the grant: refused
   within 2 s. If P was in staff mode, they leave it (visible again, action bar).
3. **Direct grant.** The same with a node granted to P directly (player profile → Permissions), then revoked.
4. **Offline answers (#76).** Grant P a node and let P use it once. Revoke it in the web app (pushed). Stop the API so
   the plugin reports DOWN, then let P use the node again: refused. (Before #179 the remembered answer allowed it for
   up to 72 h of outage.) Start the API again.
5. **Group fan-out.** With P and a second player Q online, Q not in the group: edit the group's chat colour or a node.
   Use the **Default group or a premium tier**: only their colours are drawn (#260; a Staff group's colours never are).
   P is redrawn at once; Q is untouched (no API calls for Q in the API log).
6. **Balances.** S adds 100 coins to P (player profile → Balances): P's profile menu and `/balance` show it at once.
   Add enough XP for the next title: the promotion effect and the tab-list footer (title, prestige) change within 2 s.
   A `/pay` between two players and a lootbox or salary reward also update the cached balance (one
   `UserBalancesChanged` per player).
7. **Freeze.** S freezes P with a reason (no button in the web app yet, #119: call `PUT /api/Users/{id}/freeze` with
   `{"reason": "…"}` and `PUT /api/Users/{id}/unfreeze`, e.g. from Swagger): P gets "You have been frozen: {reason}" at once and can't
   move. Unfreeze: "You have been unfrozen." at once. Then `/freeze P test` in game: the message shows **once** (the
   event echo changes nothing).
8. **Active mode.** For a staff member with `knk.mode.staff` online, set Staff mode in the web app: vanished at once
   (action bar). Set None: visible at once. For a player without the node: they stay visible and the stored mode goes
   back to None (plugin log `... doesn't hold knk.mode.staff; staying visible`).
9. **Other user fields.** Change P's personal multipliers or gate pass-through method in the web app: no visible
   effect except that the next gate use / salary payout uses the new value without a rejoin.
10. **Notifications pushed.** With P online: an XP change in the web app that crosses a title shows the promotion
    effect within 1 s; while the hub is connected the plugin no longer calls `GET /api/PlayerNotifications/pending`
    every 2 s (API request metrics, or a request log at Information). With P offline: `/pay P 10` from another player; when P joins, the payment message shows at once.
11. **Hub down = as before.** Set `realtime.enabled: false` and restart: a rank change shows within the 2 s poll, a
    grant after up to 30 s, a freeze only on rejoin (today's behaviour). Set it back to `true`.
12. **Resync re-reads online players.** With P online (frozen, or in a mode), restart the API. After
    `Realtime resync after reconnect: 5 step(s)` P's tab list, freeze state and mode still match the web app, and a
    notification queued while the plugin was disconnected shows (the drain). Lost events between two connections are
    covered by unit tests (`UserStateSyncTest`, gap → resync).

Measure 1, 2, 6, 7 and 8 with a stopwatch or the log timestamps (`at` in the envelope; plugin log at FINE) and
record the times under **Findings**.

## WT2 — world tasks over SignalR (#181)

**Builds:** knk-web-api, knk-plugin **and knk-web-app** on `claude/realtime-signalr` (the branch contains the world-task
hardening of #180 too: run its migration `AddWorldTaskHardening` after a backup, and read its smoke test
`world-task-hardening-smoke-test.md` on `claude/world-task-hardening` first). Plugin `realtime.enabled: true` as in S1.
**API:** optional `WorldTasks:OfferTimeoutSeconds` (default 120). **Proxy:** the browser connects to `/api/hubs/web`
(dev: the API directly; alpha: `scripts/alpha-web/nginx.conf` `location /api/hubs/`). **People:** admin **A** (web app
with `knk.admin.world`, a linked Minecraft account, `knk.tasks` in game) and admin **B** (`knk.tasks`, online in game).
Use a form with a Location or region field (e.g. a new Town).

1. **Web hub connects.** Log in to the web app as A. Browser dev tools → Network → WS: `/api/hubs/web?id=…` is open
   (with `access_token` in the query string; the API request log stays quiet about it at Warning). Log out: it closes.
2. **Send to Minecraft = auto-claim.** A is online in game, holds no task. In the form press **Send to Minecraft**.
   Within a second: the panel says "Sent to you in game…" with the task code folded away ("Or use task code …"); in
   game A gets "Task from the web app: Town › Location", "✓ Task claimed. Type 'cancel' to hand it back." and the
   handler's prompts; the panel shows "Claimed by A" without waiting for a poll. Finish it in game: the field fills
   within a second.
3. **Offline = task code.** A leaves the game. Send to Minecraft: the yellow task code block shows at once (no "Sent
   to" line); `/knk task <code>` after joining works as before.
4. **Busy: Queue.** A online and holding a task (step 2 without finishing). In a second form field press **Send to
   Minecraft**: the panel asks "You already have a task open in game." naming the field and the form, with Queue /
   Hand off… / Replace / Cancel. **Cancel** sends nothing. **Queue**: "Queued: it is sent to you in game when your
   current task ends." (the code stays visible). Finish the first task: the queued one is offered and claimed at once.
5. **Busy: Replace.** As 4, choose **Replace**: in game the first task stops with "Task N was handed back: the web app
   sent you task #M instead." and the new one starts. The first form's panel shows its task code again ("handed back").
6. **Hand off to… + Accept.** B online. Press **Hand off to…**: B is listed (A is not). Pick B: the panel says "Sent to
   B in game, waiting for Accept or Decline (2 min)…"; B sees "A sent you a task from the web app: …" and
   `[Accept] [Decline]`. B clicks **[Accept]**: claimed and started; the panel shows "Claimed by B".
7. **Decline and timeout.** Hand off again; B clicks **[Decline]**: the panel says "B declined it in game" and expands
   the code. Hand off again and let 2 minutes pass: B gets "The offer … timed out.", the panel "No answer from B".
   Clicking [Accept] afterwards says there is no open offer.
8. **Code beats the offer.** Hand off to B, then A types `/knk task <code>` (unfold it): A has the task, B's offer line
   is withdrawn ("The offer of … is no longer open: Claimed by A with the task code.").
9. **Cancel in the web app stops it at once.** While A runs a task, press **Cancel task** in the panel: in game the
   handler stops within a second with "… was cancelled in the web app." (before #181: on the next heartbeat, up to 60 s).
10. **In-game cancel / quit.** A types `cancel` during a task: the panel shows the task code again (not offered again).
    Start another, then A quits mid-task and rejoins: the task is offered (auto-claim) again on join.
11. **Server restart.** While A holds a task, restart the game server: on reconnect the task is handed back and, with
    A online again, offered again.
12. **Scans start at once.** Start a gate block scan or a catalogue scan (Admin → Minecraft catalogue → Scan server):
    the plugin log shows the claim within a second (not after the 5–60 s poll). The catalogue page updates the scan's
    status as soon as it changes (no 3 s poll in the network tab; one `GET scans/{id}` per change, plus a 15 s
    safety net).
13. **Hub down = as before.** Stop the API's hub for the browser (or block `/api/hubs/` in the proxy): the panel polls
    every 2 s, "Hand off to…" is hidden, "Send to Minecraft" sends without the busy question. Set the plugin to
    `realtime.enabled: false`: nobody is online, every task shows its code, exactly as on the #180 branch.

Record the times of 2, 6 and 9 under **Findings**.

## WT2 follow-ups — offer permission and Send again (#239, #240)

**Builds:** knk-web-api, knk-plugin and knk-web-app `claude/world-task-offer-followups` (merged 2026-11-05; no migration, no new
setting). Plugin `realtime.enabled: true`. **People:** admin A as in WT2; player B in the Staff group, **not op**, with
no Bukkit grant of `knk.tasks` (the node comes only from the group in the web app).

1. **Hand off to a non-op staff member.** As WT2 step 6: B is listed; pick B. B gets "A sent you a task from the web
   app: …" with `[Accept] [Decline]`; Accept claims and starts it. (Before #239: the panel said "B declined" at once.)
2. **Refused in game.** A non-op admin with `knk.admin.world` but **without** `knk.tasks`, online in game, presses
   Send to Minecraft: in chat "The web app tried to send you a task (…), but you don't have world-task access in game
   (knk.tasks)"; the panel says "You don't have world-task access in game (knk.tasks). Use the task code, or hand it
   off." (not "could not be sent").
3. **Non-op admin, auto-claim.** If A is op, repeat WT2 step 2 with a non-op admin: the task is claimed in game.
4. **Send again after an in-game cancel.** A starts a task (auto-claim) and types `cancel`. The yellow card shows the
   `/knk task <code>` command with a copy button (no separate "Task code:" box), **Send again** and **Hand off to…**.
   Send again: A gets the same task again at once ("Task from the web app: …"), same task code.
5. **Send again while busy.** A holds another task; on a waiting task press Send again: the Queue / Hand off /
   Replace / Cancel question appears; Queue queues this task, Replace hands the other one back.
6. **Send again while offline.** A leaves the game; Send again: "You're not online in game. Join the server and press
   Send again, or use the task code." Nothing is sent.
7. **Hand off a waiting task.** After a Decline or timeout (WT2 step 7), press Hand off to… on the card and pick B
   again: the same task is offered (Accept/Decline).
8. **No hub.** Block `/api/hubs/`: the card shows the command only, no Send again / Hand off.

## S3 — config and entity changes pushed to the game server (#182)

**Builds and config:** knk-web-api and knk-plugin on `claude/realtime-signalr` (as WT2: the branch contains #180's
migration), `realtime.enabled: true`. **API and plugin:** no new setting, no migration. **People:** staff member **S**
in the web app (`knk.admin.world`, `knk.admin.content`, siege/lootbox/game settings pages), player **P** online in game.
Goal: **in effect on the running server within about 2 s** of Save (the 500 ms merge window included). Plugin log at
INFO shows `Realtime: reloaded gate structure …`; `/knk health` `messages` goes up per event.

1. **Off changes nothing.** With `realtime.enabled: false` edit a gate's door name and a district's AllowEntry: nothing
   happens until `/gate reload` / the 5 min access sync, exactly as before. The plugin still reports its worlds over REST
   (`PUT api/GameSettings/runtime-worlds` in the API log every 10 min). Set it back to `true`.
2. **Gate edit.** S changes a gate door's animation duration or a gate's health display override and saves: the plugin
   log shows `reloaded gate structure N (k door(s))` within 2 s and the next open/close uses the new value. Add a door:
   it works without `/gate reload`. Delete a door: it no longer opens (`/gate list` doesn't show it). Delete a gate
   structure (one no siege uses): `removed from the cache`.
3. **Gate edit during a siege match (Q12).** Start a siege match whose scenario holds gate **G**. Edit G in the web app:
   the log says `edited in the web app during a siege match; applied after the match` and G keeps its lockdown. Edit a
   gate outside the scenario: reloaded at once. End the match: after the gates are restored G is reloaded with the edit.
4. **Domain access.** S sets AllowEntry off on a district: within 2 s P can't walk in (the WorldGuard flag is set; no
   5 min wait, no `/knk regions repair`). Back on: P walks in. Add a sub-region to a town: its flags follow at once.
5. **Game and hub settings.** Change the join announcement or a world's time lock in Game Settings: in effect within
   2 s (log `Applied game settings`). Mark another domain as hub-eligible: the hub settings re-read follow.
6. **Siege config.** Change a lobby's cooldown or a scenario's player limit: `/siege` shows it at once for lobbies
   between matches; a lobby in a match takes it at its next cooldown (log `new configuration applies at its next
   cooldown`).
7. **Lootbox config.** Change a lootbox type's weight or a spawn area's max active boxes: the runtime re-reads at once
   (no 60 s wait); boxes already in the world stay.
8. **Teleport and navigation.** Turn a town's warp on or change its price: `/warp` (and the warp menu) shows it at
   once. Change the navigation compass name or a type default: the next `/navigate` uses it.
9. **Roads.** Approve a road tile in the road review page (or change a profile): the plugin re-reads that world's tiles
   within 2 s instead of after the 10 min tile timer.
10. **Telemetry config.** As the owner, add an enhanced telemetry target for P: the plugin's config poll runs at once
    (P's enhanced sampling starts without the 60 s wait).
11. **Cached entities.** Rename an item blueprint, a kit or a menu template, or change a grade: the next use in game
    (give, kit claim, menu open, enchant-book cap) shows the new value without `/knk cache refresh`. Edit P's user in
    the dashboard (e.g. their gender or username): P is re-read and redrawn at once. A catalogue maintenance run that
    touches many materials sends one event (the whole material cache is dropped once).
12. **Worlds over the hub.** Load or unload a world (e.g. `/mv load`): the API's Game Settings page lists it at once;
    the API log shows no REST `runtime-worlds` call while connected. Stop the hub (API restart): the next report goes
    over REST again.
13. **Startup-only siege work (#31).** Stop the API, start the game server, wait for "Done" (log: `Runtime config
    unavailable … no lobbies started`), then start the API. When the plugin reconnects to the hub the resync runs
    "siege startup work": the lobbies appear in `/siege` without `/siege admin reload`, title brackets show on join
    denials, gates a crash left locked are restored, and the previous run's unfinished matches are aborted (API
    `SiegeMatches` with `ServerRestart`). A second reconnect runs none of them again. With `realtime.enabled: false` the
    old behaviour stays (`/siege admin reload` needed; #31 stays open for that path).
14. **Slower safety nets.** With the hub connected the 5 min domain access sync, the 30 s game settings re-read and the
    60 s lootbox refresh run 4× less often (API request log); with the hub down they are back at their intervals.

Record the times of 2, 4, 5 and 8 under **Findings**.

## S4 — live updates in the web app (#183)

**Builds:** knk-web-api and knk-web-app on `claude/realtime-web-live-183` (the web-app branch contains the admin IA
branch `claude/admin-ia-30`, W1–W4). **API:** no migration; optional settings `Realtime:WebPermissionCacheSeconds`
(default 30) and `Realtime:WebLiveUpdatesEnabled` (default `true`; step 9). **Plugin:** none; the web part works with the plugin's `realtime.enabled` on or off (presence then comes
from the REST join/quit calls). **People:** staff **A** and **B** in two browsers (or a normal and a private window),
both with `knk.admin.content` and `knk.admin.user.manage`; a third account **C** with `knk.admin.content` only; player
**P** who can join the game server. Design: [DESIGN §6.9](../specs/realtime-signalr/DESIGN.md).

1. **Dashboard refresh.** A and B open `/dashboard/Town` (or any type both can edit). B edits a town's description
   and saves. Within about 1 s A's table shows the new text without a spinner or a page jump, and above the table
   "Updated by B at hh:mm". B's own dashboard shows no such line for B's own save. Create and delete a town in B: A's
   table follows (the row appears/disappears; page, search and sort stay).
2. **Other types stay quiet.** B saves a street while A shows towns: A's table is not re-read (browser network tab:
   no `Towns/search`). A Town saved by B also refreshes A's **Domain** list if A shows that type.
3. **Detail page.** A opens a town's detail page; B edits it: A's values change in place with "Updated by B at …".
   B deletes it: A sees "This Town was deleted by B." with **Back** (to the dashboard type); the stale values stay
   readable.
4. **Moderation list online badge.** A opens Player moderation (All players). P joins the game: within about 1 s P's
   row turns **Online**; P quits: **Offline**. The list is not reordered and no rows are added or removed. On "By group
   / online", run a search, then let P join or quit: the badge follows; tick "Currently online only" without Search,
   then restart the API: after the hub reconnects the list is read again with the filter of the last Search.
5. **Profile badge.** A opens P's profile (`/admin/users/{id}`): "Offline · last seen …" or "Online" next to Reload.
   P joins / quits: the badge changes without Reload. An account without a Minecraft UUID shows no badge.
6. **Permission gating.** C (content only) keeps the dashboard updates of step 1 but receives no `PresenceChanged`
   (browser devtools → Network → the `hubs/web` WebSocket → Messages: no `PresenceChanged` frames while P joins and
   quits) and no `EntityChanged` for `User` (edit a user's name as A). Take `knk.admin.content` away from C (or its
   group) while C's dashboard is open: within 30 s C stops getting `EntityChanged` (REST answers 403 at once). A
   player without staff nodes gets neither event.
7. **Hub down = as before.** Stop the API for a minute with A's dashboard open: nothing breaks; after it is back the
   hub reconnects and the table is read again once (quietly). In a build whose proxy doesn't forward `/api/hubs/web`
   (or with the hub blocked in devtools) the pages behave as before: Reload and Back show changes.
8. **Bursts.** With A on the Minecraft materials dashboard, run a catalogue scan or maintenance run that changes many
   materials: A's table is re-read once (one `search` request after the burst), not once per row.

9. **Switched off (decision 2026-11-06 on LX1-10).** Set `Realtime__WebLiveUpdatesEnabled=false` on the API and
   restart it (a change of `Realtime:WebLiveUpdatesEnabled` in its appsettings file applies without a restart).
   Repeat step 1 and P joining in step 4: A's table and badges don't change by themselves (the `hubs/web` WebSocket
   stays connected but carries no `EntityChanged` or `PresenceChanged` frames); Reload shows the changes. P's profile
   still opens with the right Online / "Offline · last seen …" badge (the profile summary's `presence`), it just
   doesn't follow live. The game server still gets its own events (e.g. a gate or town edit is applied in game as in
   S3). Set it back to `true` (or remove it) and restart: step 1 works again.

Record under **Findings**: the delay of steps 1, 4 and 5, and the results of steps 6 and 9.

## Findings

### WT2 — developer, 2026-11-04

Builds: `claude/realtime-signalr` in knk-web-api (`e769c4c`), knk-plugin (`eb22a655`) and knk-web-app (`c7a3e85`),
plugin `realtime.enabled: true`. Setup notes: the dev server's existing `config.yml` had no `realtime:` block (add it by
hand, see S1); the web app needs `npm install` after checkout (new `@microsoft/signalr`), else the hub never connects.

| Step | Result | Notes |
|---|---|---|
| 1 | Works | After `npm install` |
| 2 | Works | A passes the in-game `knk.tasks` check (op or a Bukkit grant); see step 6 |
| 3 | Works | |
| 4 | Works | |
| 5 | Works | |
| 6 | Accepted, **bug** | B (Staff group, not op) got no Accept/Decline line; the panel said at once that B declined. The plugin checks `knk.tasks` with Bukkit only (`WorldTaskRealtimeSync.onOffered`), which doesn't see group grants made in the API, answers `no-permission` silently, and the API records that as Declined. Auto-claim (step 2) has the same check, so a non-op admin gets the task code instead. Follow-up issue (see the #181 comment) |
| 7 | Accepted | |
| 8 | Accepted | |
| 9 | Works | |
| 10 | Works | Wish: a **Send again** button wherever the panel falls back to the task code (handed back, quit, declined, timed out, offline), instead of Cancel task + a new task; and drop the separate "Task code:" block, keep only the copyable `/knk task <code>` command. Follow-up issue (see the #181 comment) |
| 11 | Accepted | |
| 12 | Accepted | |
| 13 | Accepted | |

Times for steps 2, 6 and 9 were not recorded.

### WT2 follow-ups (#239, #240) — developer, 2026-11-05

Builds: `claude/world-task-offer-followups` in knk-web-api (`daf09cc`), knk-plugin (`d0655e28`) and knk-web-app
(`16659be`). Result: **all steps work** (1–8). Merged into the default branches the same day: knk-web-api `master`
`453729e`, knk-plugin `main` `33122cf4`, knk-web-app `main` `4d0c6ed`.

### S1, S2, S3 — developer, 2026-11-05

On the default branches (merged 2026-11-04 and 2026-11-05).

| Section | Step | Result | Notes |
|---|---|---|---|
| S1 | 1, 2 | Works | |
| S1 | 3 | Works (stored and shown); no live update | The `/admin/users` table doesn't update presence by itself: the web hub sends no presence events yet. That is S4, [#183](https://github.com/PandiO/knk-workspace/issues/183) |
| S1 | 4–10 | Accepted | |
| S2 | 1, 2, 3, 6, 8 | Works | |
| S2 | 4, 9–12 | Accepted | |
| S2 | 5 | Accepted (developer, 2026-11-05) | Edited the **Staff** group's chat, bracket and tab-list colours: no change in game at all. Not the push: only a premium tier's or the Default group's colours are ever drawn ([#260](https://github.com/PandiO/knk-workspace/issues/260)). Re-check with one of those |
| S2 | 7 | Accepted (developer, 2026-11-05) | No freeze button in the web app ([#119](https://github.com/PandiO/knk-workspace/issues/119)); re-check through the API as the step now says |
| S2 | — | Found in passing | A kit **Grant** on the player profile never delivers the items in game ([#261](https://github.com/PandiO/knk-workspace/issues/261)) |
| S3 | 2, 5 | Works | Gate structure edit and world settings checked live |
| S3 | others | Accepted | |

#178 (S1), #179 (S2) and #182 (S3) closed. #260 decided 2026-11-05: group colours by precedence (hierarchy, then weight).
