# Realtime channel (SignalR) — smoke test

**Status:** S1 to test (written 2026-10-26 for branch `claude/realtime-signalr`, not merged, not run)
**Last updated:** 2026-10-26
**Design:** [specs/realtime-signalr/DESIGN.md](../specs/realtime-signalr/DESIGN.md) (§4–§5, as built: §4.6) ·
[IMPLEMENTATION_PLAN.md](../specs/realtime-signalr/IMPLEMENTATION_PLAN.md) ·
**Issues:** [PandiO/knk-workspace#178](https://github.com/PandiO/knk-workspace/issues/178) (S1), parent
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
   `Realtime: connected to the game hub`, `Realtime resync after connect: 3 step(s)` (2 when lootboxes are off). API log:
   `Game server dev-1 connected to the realtime hub (…)` and `Game server dev-1 roster: N online; … corrected`.
   `/knk health` shows `realtime: connected as 'dev-1' for …s, connects 1, messages 1, resyncs 1, gaps 0`
   (the one message is the `Welcome`).
3. **Presence follows join and quit.** With the player online, the player profile / moderation list in the web app
   shows them online. Quit: within a second they show offline (`LastSeenAt` moves). Join again: online.
4. **API restart.** Stop the API. Plugin log: `Realtime: connection to the game hub closed (…)`, then one
   `connect … failed` per attempt (about 1 s, 2 s, 5 s, 10 s, then every 30 s), until the connectivity probe says
   DOWN: then no more attempts. Start the API. When `/knk health` shows UP again, the plugin connects at once:
   `Realtime: connected to the game hub (reconnect)`, `Realtime resync after reconnect: 3 step(s)`.
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

## Findings

_No run yet._
