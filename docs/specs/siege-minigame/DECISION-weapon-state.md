# Siege weapons — decision matrix: who owns weapon match state

**Status:** Decided 2026-11-19 (developer), option 1; log id W63 in [SIEGE_WEAPONS.md](SIEGE_WEAPONS.md) § 2.6.
**Last updated:** 2026-11-19 (first version and decision, design run on PandiO/knk-workspace#354)
**Question:** Which component is authoritative for a placed weapon's runtime state (HP, build progress, reload timer,
operator lease, spread) and each player's siege-point balance, and how does a fire command from the browser targeting
page (W26, W36, W42) reach it? It has to be settled before the implementation plan, because it decides the endpoints,
the realtime messages and where the atomic fire check (W36) lives.

## 1. Options

1. **Plugin authoritative, API relays.** The plugin holds all match state, as it already does for Siege matches
   (`SiegeService`, local checkpoint, W41). The page talks only to knk-web-api: the API checks the page credential
   (W64) and forwards each command (take lease, heartbeat, fire) to the plugin over the existing SignalR hub
   ([realtime-signalr](../realtime-signalr/DESIGN.md)); the plugin decides on the main thread and answers, and the API
   passes the result and state changes (reload, siege points, HP) back to the page over SignalR. In-game actions
   (ballista, W62 aiming) never leave the plugin.
2. **API authoritative.** Leases, reload timers and siege-point balances live in the API (database or memory). The
   plugin asks the API before every placement and shot, in game or from the page, and reports every kill, capture and
   damage event that earns points.
3. **Page talks to the plugin directly.** The plugin opens a public HTTP/WebSocket endpoint (like its local
   `RegionHttpServer` or the metrics server); the page sends commands straight to it and the plugin checks the tokens
   itself.

## 2. Considerations and weights

1. **Correctness and atomic fire** (25): at most one shot per reload, one lease per weapon, points never spent twice,
   even in a race between page and game.
2. **Latency and in-game feel** (20): an in-game shot (ballista, W62) must react at once; a page shot within a few
   hundred ms.
3. **Resilience to an API outage** (15): a match in progress should keep its weapons working in game when the API
   is down (W41's spirit).
4. **Security and exposure** (15): no new public surface on the game server; the page's credential is checked in one
   place.
5. **Platform independence** (10): game rules in Bukkit-free `knk-core`, not tied to Paper.
6. **Effort to build and maintain** (10).
7. **Fit with what exists** (5): Siege match state is already in the plugin; the API ↔ plugin SignalR hub exists.

## 3. Matrix

Score 1–5 per option; weighted total = sum of score × weight / 5, out of 100.

| Consideration | Weight | 1. Plugin, API relays | 2. API authoritative | 3. Page → plugin direct |
|---|---|---|---|---|
| Correctness and atomic fire | 25 | 5 | 4 | 5 |
| Latency and in-game feel | 20 | 4 | 2 | 5 |
| Resilience to API outage | 15 | 5 | 1 | 3 |
| Security and exposure | 15 | 5 | 5 | 1 |
| Platform independence | 10 | 4 | 5 | 3 |
| Effort | 10 | 4 | 2 | 3 |
| Fit | 5 | 5 | 2 | 2 |
| **Weighted total** | 100 | **92** | **62** | **71** |

## 4. Pros and cons

1. **Plugin authoritative, API relays.**
    1. Pros: (1) one owner of the state, so the atomic fire check is a single main-thread method; (2) in-game firing
       and earning points work during an API outage, only the page stops; (3) no new public surface; (4) matches how
       Siege matches already keep their state and checkpoint.
    2. Cons: (1) a page shot takes two hops (page → API → plugin) plus the answer; (2) the API needs a small
       request/response pattern over SignalR (correlation id, timeout) that the hub doesn't have yet; (3) the page shows
       "server unreachable" while the plugin is disconnected.
2. **API authoritative.**
    1. Pros: (1) state survives a plugin crash in the database; (2) the page needs no relay.
    2. Cons: (1) every in-game shot and every point-earning event becomes a REST round trip, which slows the ballista
       and kills weapons during an API outage; (2) state is split anyway (HP, kills, impact physics stay in the plugin);
       (3) the most new code.
3. **Page talks to the plugin directly.**
    1. Pros: (1) fewest hops, lowest latency; (2) no relay code in the API.
    2. Cons: (1) opens the game server to the internet, through the NAS and proxy setup; (2) token checks and web
       session matching (W29) are duplicated in the plugin; (3) the page needs two backends (API for the map and
       markers, plugin for commands).

## 5. Recommendation

**Option 1, plugin authoritative with the API as relay**, because it keeps the atomic rules in one place, keeps
in-game play independent of the API and adds no public surface. Reversible? Moderately: the rules live in `knk-core`
behind a port either way, so moving them to the API later costs the transport, not the logic. What would change it:
running several game servers that share one match (then the API would have to coordinate), or measured page latency
above about 500 ms.
