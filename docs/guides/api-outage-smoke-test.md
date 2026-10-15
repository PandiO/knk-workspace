# API outage — smoke test

**Status:** To test (KNG-171 section written 2026-10-15; not run yet)
**Last updated:** 2026-10-15
**Architecture:** [api-connectivity.md](../architecture/api-connectivity.md) (KNG-115 state and its subscribers) ·
[offline-security-cache.md](../architecture/offline-security-cache.md) (KNG-58/KNG-123 fallback; its § 8 has the
earlier outage checklists, both passed) ·
**Linear:** [KNG-171](https://linear.app/kngpandi/issue/KNG-171)

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

## Findings

_None yet._
