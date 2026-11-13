# API outage — smoke test

**Status:** KNG-171 passed (developer, 2026-10-17), merged 2026-10-17 ([knk-plugin #14](https://github.com/PandiO/knk-plugin/pull/14));
[#31](https://github.com/PandiO/knk-workspace/issues/31) siege startup retry: in review, not run yet (branch `claude/siege-startup-retry-31`)
**Last updated:** 2026-11-05
**Architecture:** [api-connectivity.md](../architecture/api-connectivity.md) (KNG-115 state and its subscribers) ·
[offline-security-cache.md](../architecture/offline-security-cache.md) (KNG-58/KNG-123 fallback; its § 8 has the
earlier outage checklists, both passed) ·
**Linear:** [KNG-171](https://linear.app/kngpandi/issue/KNG-171) · **GitHub:** [PandiO/knk-workspace#31](https://github.com/PandiO/knk-workspace/issues/31) (KNG-202)

Manual checks of how the game server behaves while knk-web-api is stopped. Run on the dev server. Use a non-op
account for every in-game step (ops pass every permission check) and a second player to message. Record each
run under **Findings** at the end.

## KNG-171 — commands answer without waiting while the API is DOWN

Build: knk-plugin branch `wt/kng-171` (`./gradlew :knk-paper:dev`). `config.yml` → `api.connectivity` needs no
change: `enabled: true` and `skip-api-while-down: true` are the defaults.

1. **Baseline, API up.** As the non-op player, run `/knk help`, `/msg <other> hi` and `/tpa <other>`. Note which
   `/knk` subcommands `/knk help` lists and that the replies come at once. Run `/knk health`: `API connectivity: UP`.
2. **Stop the API.** Stop knk-web-api. Run `/knk health` every few seconds until it shows `API connectivity: DOWN`
   (about 20-35 s with the default probe settings) and the extra line `reads skip the API until UP: answered from
   caches and the offline store`.
   Before DOWN the commands may still wait about 1 s: that is expected (the hysteresis hasn't confirmed the outage).
3. **While DOWN.** Run `/knk help`, `/msg <other> hi` and `/tpa <other>` again, also after more than 30 s (so the
   in-memory permission answers have expired and the offline store answers).
   - Expected: each replies without a noticeable delay.
   - Expected: the same permission outcomes as in step 1 (`/knk help` lists the same subcommands; a command that
     was refused is still refused).
   - Server log: one `API connectivity UP -> DOWN` warning, no `Permission check failed` warning per command and no
     `Retry attempt` lines.
4. **Start the API.** Start knk-web-api and wait until `/knk health` shows `UP` (about 10-15 s), without the extra
   line.
5. **A change applies again.** In the web app, take a node that `/knk help` showed in step 1 away from the player's
   groups (or grant one it lacked). Within the 30 s permission cache time (or at once after `/knk cache refresh`),
   `/knk help` shows the change.
6. **Switch off (optional).** Set `api.connectivity.skip-api-while-down: false`, restart the server, repeat steps 2-3:
   the commands wait about 1 s again, as before KNG-171, and `/knk health` says `reads call the API even while DOWN`.
   Set it back to `true`.

Pass: steps 3 and 5 as expected. A first-time player (never joined this server, or not within 30 days) still has no
non-op permissions during an outage; that is KNG-58's rule, not a failure here.

## #31 — siege startup work runs again when the API is back (realtime hub off)

Build: knk-plugin branch `claude/siege-startup-retry-31` (`./gradlew :knk-paper:dev`; it contains the R1 branch
`claude/realtime-erasure-184`). `config.yml`: `realtime.enabled: false` (the default) and `api.connectivity.enabled:
true` (the default). At least one siege lobby in the web app. Watch the server log and the API request log
(`POST api/siege-matches/abort-unfinished`, `POST api/siege-matches/restore-stale-gates`,
`GET api/SiegeLobbies/runtime-config`, `GET api/title-brackets`).

1. **API up at start (nothing changes).** Start the API, then the server. `/siege` lists the lobbies. The log has no
   `[Siege] Startup work still pending` line, and after the first probe (`API connectivity UNKNOWN -> UP`) the API log
   shows no second `abort-unfinished`, `restore-stale-gates` or `runtime-config` call.
2. **API down at start.** Stop the API, start the server, wait for "Done". Log: `Startup recovery: aborting unfinished
   matches failed`, `Gate recovery (restore-stale-gates) failed; … retried when the API is back`, `Runtime config
   unavailable (…); no lobbies started - retried when the API is back (or /siege admin reload)`, then `API connectivity
   UNKNOWN -> DOWN`. `/siege` shows no lobbies.
3. **Start the API.** Within about 10-15 s the log says `API connectivity DOWN -> UP` and, without `/siege admin
   reload`: the API log shows `abort-unfinished`, then `restore-stale-gates`, then `runtime-config` and `title-brackets`
   (in that order, each once); `/siege` lists the lobbies; a join denial shows the title (not a raw XP number). No
   `still pending` line.
4. **Not again.** Stop the API, wait for `DOWN`, start it, wait for `UP`: none of the four calls is made again.
5. **After a crash during a match.** With the API up, start a match on a scenario with gates; kill the server process
   mid-match (`kill -9`, no clean stop). Stop the API. Start the server, wait for "Done", start the API. On `UP`: the
   previous match is aborted (web app: the match shows `ServerRestart`), then the gates are restored (lockdown,
   pass-through and door states gone; the API log's `restore-stale-gates` comes after `abort-unfinished`), then the
   lobbies appear. A new match on that scenario locks its gates down again.
6. **Probe off (fallback).** Set `api.connectivity.enabled: false`, stop the API, start the server, start the API
   after "Done". Within about 30 s (fallback retry; then 1 min, 2 min, every 5 min while anything is left) the lobbies
   appear. While the API is still down the log has `[Siege] Startup work still pending (fallback retry after 30 s): …`
   at each try. Set it back to `true`.
7. **Hub on, no double run.** Set `realtime.enabled: true`, repeat steps 2-3. Both the `UP` transition and the hub
   reconnect ("siege startup work" in the resync) trigger, and each of the four calls is still made once.

Pass: steps 3, 4, 5 and 7 as expected. Not checked live (unit tests only): a match this run created before the API
came back is never aborted by the retry, and the gate restore waits while a lockdown of this run is active.

## Findings

- **2026-10-17, developer:** KNG-171 steps 1-5 pass. No findings.
