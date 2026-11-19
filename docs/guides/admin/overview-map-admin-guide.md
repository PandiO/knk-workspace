# Overview map — Admin and Staff Guide

**Status:** Current · **Last updated:** 2026-11-19 (§ 6: "Open profile" disabled with a tooltip without `knk.admin.user.manage`, #809; troubleshooting: Escape inside the map, #757; fix link F2, in review for `next`); 2026-11-18 (first version, the overview map chain #732, docs PandiO/knk-workspace#766)
**Checked against:** knk-web-api `next` `6094276`, knk-plugin `next` `3e04ba8f`, knk-web-app `next` `eff6ed9` (not
released; every part is off by default; the [smoke test](../overview-map-smoke-test.md) has not been run live yet)
**Related:** [player guide](../users/overview-map-player-guide.md) (what everyone sees),
[design](../../specs/in-game-maps/OVERVIEW_MAP_DESIGN.md), [plugin configuration § 4.29](plugin-configuration.md#429-map),
[production installation § 4.3](../production-installation.md#43-api-configuration-file--etcknkapienv),
[closed-alpha runbook Phase 10](../closed-alpha-deployment-runbook.md#phase-10--overview-map-bluemap-in-the-stack-737)

The web app's `/map` page shows BlueMap's 3D render of the world with Knights and Kings pins on top: towns, districts,
structures, live players and siege pins. Everyone sees the public part described in the
[player guide](../users/overview-map-player-guide.md). This guide covers turning the map on and what staff see on top
of it: details, gate commands and moderation. Each staff part follows the viewer's own node; the API checks the same
node on every request.

## 1. Before you start

1. **Components.** The API and the plugin from `next` (commits above), and the web app from `next`. The migration
   `AddMapRegionOutlines` (one new table, `map_region_outlines`; additive) must be applied.
2. **The game hub.** Outlines, live players and gate commands all travel over the realtime game hub, so the plugin
   needs `realtime.enabled: true` and must be connected (API log: `Game server <id> connected to the realtime hub`).
3. **BlueMap.** The 3D view comes from a BlueMap render of a copy of the world, served by the stack's own nginx under
   `/bluemap/` with the bridge script the web app ships (`/bluemap-bridge/bridge.js`). Setup, version pin (v5.29) and
   the full-world render: [closed-alpha runbook Phase 10](../closed-alpha-deployment-runbook.md#phase-10--overview-map-bluemap-in-the-stack-737).
   The render is a snapshot: re-render after building work you want on the map. Pins, outlines and players are live
   and need no re-render.
4. **Data.** A domain gets a pin from its spawn location, else from the centre of its region outline. A domain with
   neither is left out, with one API log line per start: `Overview map: domain <id> (<name>) has no spawn location and
   no region outline`.

## 2. Turning the map on

Every switch is off by default; with all of them off nothing changes anywhere. API keys go in the API's environment
file (`/etc/knk/api.env`, [production installation § 4.3](../production-installation.md#43-api-configuration-file--etcknkapienv));
restart the API after a change. Plugin keys go in `config.yml` ([§ 4.29](plugin-configuration.md#429-map)); an
existing server file doesn't get new keys by itself, so paste the block and restart the server.

| What | Where | Key | Needs |
|---|---|---|---|
| Region outlines reported by the game server | plugin | `map.reporting.enabled: true` | `realtime.enabled: true` |
| The `/map` page, nav entry and anonymous `api/Map` routes | API | `Map__Enabled=true` | BlueMap served under `/bluemap/` |
| Live players and siege pins | API + plugin | `Map__LivePlayers__Enabled=true` and `map.reporting.enabled: true` | `Map__Enabled=true` |
| Gate command buttons | API | `Map__GateCommands__Enabled=true` | the game server on the hub |
| Staff details | none | node `knk.admin.world` | `Map__Enabled=true` |
| Moderation panel | none | the moderation nodes (§ 5) | the live players layer |

```yaml
map:
  reporting:
    enabled: true
    interval-ticks: 40       # live player report interval (40 ticks = 2 s; 10..1200)
```

1. **Order.** Plugin reporting first (the outlines arrive after the startup repair), then `Map__Enabled=true`, then the
   live players and gate commands when you want them. Turning a key off again hides that part at once (after the API
   restart; reload `/map`).
2. **Other API keys** have defaults that are fine to keep: `RateLimiting__Map__PermitPerMinute` (120 per client IP for
   every map route together), `Map__Labels__{Town,District,Structure,Arena}__MaxDistance` (0 = always, 1500, 600, 1500
   blocks of camera distance), `Map__Flash__Count` / `Map__Flash__DurationMs` (3 × 400 ms), `Map__Markers__CacheSeconds`
   (30), `Map__LivePlayers__PollIntervalMs` (2000), `Map__LivePlayers__LabelCacheSeconds` (60),
   `Map__GateCommands__TimeoutSeconds` (5).
3. **Check.** `GET api/Map/config` without a token answers 200 with `enabled: true` and the
   `livePlayers.enabled` / `gateCommands.enabled` you set; with `Map__Enabled=false` every `api/Map` route answers 404.
   The plugin logs `[KnK Map] Map reporting on: region outlines and live players are sent to the API over the game
   hub` and `[KnK Map] Region outlines (domain regions): <n> outline(s), …` after the startup repair.
4. **Optional player heads.** Without anything extra every player has BlueMap's default head. `heads=` in BlueMap's
   `webapp.conf` draws each player's own head from a skin service; every viewer's browser then asks that third-party
   service, so only use it when the developer picked one (runbook Phase 10 step 3).

## 3. Outlines and what keeps them current

1. With `map.reporting.enabled: true` the game server sends the outline of every Town, District, Structure and Gate
   region (points, min and max Y):
   1. after every managed-region repair (server start and `/knk regions repair`);
   2. right after a world task's Region step renames or redraws a domain's region (the old name is removed);
   3. again on every reconnect of the game hub (an API restart refills the table).
2. **A hand edit** with `/rg redefine` is not reported on its own: run `/knk regions repair` afterwards.
3. **Sub-regions** (expansion regions, `domain_<id>_sub_<n>`) are reported when a world task draws or renames them,
   but not by the startup repair: a sub-region drawn before reporting was on is missing from the map until its step is
   re-run ([#750](https://github.com/PandiO/knk-workspace/issues/750)).
4. The API keeps the outlines in `map_region_outlines`, so the map keeps them while the game server is down. Only the
   plugin's game hub connection can write them. Architecture:
   [managed WorldGuard regions § 7 "Overview map outlines"](../../architecture/managed-worldguard-regions.md#overview-map-outlines-pandioknk-workspace735-in-next).
5. Changes (a rename, a new outline) reach open map pages within about 90 seconds (the 30 s marker cache and the
   page's 60 s check) without a reload.

## 4. Staff details (`knk.admin.world`)

1. A viewer holding `knk.admin.world` who clicks a town, district or structure sees a **Details** section under the
   public part: the type's default display configuration in a compact, read-only form (no heading, lists collapsed
   with their count, related records as links, no buttons or pencils), and **Open full page** to
   `/display/<type>/<id>` (Back returns to `/map`). Changes are made there, never on the map.
2. A gate shows the gate's own display (`GateStructure`).
3. **Towns and districts have no seeded default display configuration.** Until you create one in the display builder
   and make it the default, their Details section shows a one-line message instead; the public part stays. `Structure`
   and `GateStructure` are seeded.
4. Viewers without the node see the public panel only, and their browser asks for no display configuration.

## 5. Gate commands from the map (`knk.gate.admin`)

1. With `Map__GateCommands__Enabled=true`, a viewer holding `knk.gate.admin` who clicks a gate sees **Gate commands**
   under the public "Doors": a **Whole gate** row and one row per door (name, state, "Destroyed"), each with **Open**,
   **Close**, **Toggle** and **Repair**. `knk.admin.world` alone is not enough.
2. **What happens.** The API sends the command to the game server over the game hub and waits up to 5 s. The game
   server runs the same gate operations as `/gate`: the door moves with its normal animation and the state is saved
   when it ends; Repair works as `/gate repair` (full health, not destroyed). Inactive doors are skipped, a destroyed
   door doesn't open, a door already in the asked state counts as done, a moving door doesn't toggle.
3. **The result** shows under the buttons: "Done: …" with the game server's message, a refusal with its reason,
   "no game server connected" or a time-out. The panel then reads the gate again. A time-out means the API stopped
   waiting; the game server may still have run the command, so look at the door before you send it again.
4. **Siege lock.** While a siege match runs on the gate the buttons are disabled with "Gate is in a running siege"
   (the API answers 409, and the game server checks its own siege lockdown too). If the match starts while the panel
   is open, the next click gives the same text and disables the buttons.
5. **Audit.** Every command is written to the audit log as `GateCommandSent` with your user, the action, the door and
   the result (`done`, `refused`, `siege`, `no-game-server`, `timeout`), also the refused ones.
6. Without the node, without a login or with the setting off there are no buttons and no requests. In game the gate
   commands and nodes stay as in the [gate structures admin guide](gate-structures-admin-guide.md).

## 6. Moderation from the map

1. A logged-in viewer holding any of `knk.freeze`, `knk.unfreeze`, `knk.kick`, `knk.ban` or `knk.admin.user.manage`
   who clicks a player gets a **Moderation** section under the name card. Each action shows only with its own node:

   | Node | Shows |
   |---|---|
   | `knk.freeze` | **Freeze…** (asks a reason) |
   | `knk.unfreeze` | **Unfreeze**, in place of Freeze, while the player is frozen ("Frozen. Reason: …") |
   | `knk.kick` | **Kick…** (optional reason) |
   | `knk.ban` | **Ban…** (required reason; permanent, lift with `/pardon <name>` in game) |
   | any of them | **Open profile** (`/admin/users/<id>`): a link with `knk.admin.user.manage`, otherwise greyed out with a tooltip |

2. The dialogs, endpoints, toasts, rules and audit entries are the player profile's own
   ([ranks, permissions and moderation § 5](ranks-permissions-moderation-admin-guide.md#5-moderation-tools)). The API's
   own rules still decide, for example the escalation guard on a kick or ban of a player who ranks at or above you;
   kick and ban need the game server on the hub.
3. **"Open profile" needs `knk.admin.user.manage`.** The profile page itself needs that node. A moderator without it
   (for example kick-only) sees "Open profile" greyed out, with a tooltip on hover, keyboard focus or tap: "You need
   access to player profiles (knk.admin.user.manage) to open this." It goes nowhere; grant the node to make it a
   link ([#809](https://github.com/PandiO/knk-workspace/issues/809)).
4. A player without a web account shows "<name> has no account in the web app yet, so there is nothing to moderate
   here."
5. Everyone else gets only the name card; anonymous viewers make no extra request at all.

## 7. Hidden players and who sees them

1. Players in staff mode or owner mode, and players in a running siege match, never reach anonymous or plain
   logged-in viewers, not even in the API's response. A siege match shows as one pin, "[Siege] <count> players", the
   same for everyone.
2. A viewer holding `knk.mode.staff` or `knk.mode.owner` sees them anyway, tagged **Staff mode**, **Owner mode** or
   **Siege**. Who holds these nodes: [ranks, permissions and moderation § 8](ranks-permissions-moderation-admin-guide.md#8-nodes-in-this-guide).
3. The owner-mode case has only been checked by the automated tests so far; the live check of smoke § 4.1 step 3 is
   still open.

## 8. A safe test

Run the [overview map smoke test](../overview-map-smoke-test.md) on dev, section by section, with the accounts it
lists (anonymous, a player, world staff, a gate admin, a kick moderator, a staff viewer). For the gate commands use a
test gate away from any siege scenario, and lift the test ban with `/pardon`. Turning the map on changes no existing
data; the only new table is `map_region_outlines`, which the plugin refills by itself.

## 9. Troubleshooting

| What you see | Likely cause | What to do |
|---|---|---|
| No "Map" entry, `/map` says "The map is not available." | `Map__Enabled` is off, or the API wasn't restarted | Set it and restart the API; reload the web app |
| The frame is empty or refuses to load | BlueMap isn't served under `/bluemap/`, or `X-Frame-Options` isn't `SAMEORIGIN` there | Runbook Phase 10 steps 6–8 |
| No pins at all | No outlines stored and no spawn locations; or `map.reporting.enabled` / `realtime.enabled` off | Check the plugin log for `[KnK Map]` and the `map_region_outlines` table; `/knk regions repair` |
| A domain has no pin | No spawn location and no outline | Set its location or draw its region; see the API log line in § 1 |
| A sub-region is missing from an outline | [#750](https://github.com/PandiO/knk-workspace/issues/750) | Re-run that sub-region's step |
| Pins on the wrong map, or none for a world | `worlds=<map id>:<world>` in `webapp.conf` doesn't match the pins' world | Runbook Phase 10 step 3 |
| No players | `Map__LivePlayers__Enabled` off, `map.reporting.enabled` off, or the game server isn't on the hub | Plugin log `[KnK Map] Live player report every 40 ticks`; `GET api/Map/players` |
| Gate buttons answer "no game server connected" | The plugin isn't connected to the hub | Check `realtime.enabled` and the API log; restart the game server |
| Gate buttons time out | The game server didn't answer within 5 s | Look at the door in game before repeating |
| "Details" shows a one-line message | The type has no default display configuration | Create one in the display builder (§ 4 item 3) |
| "Open profile" is greyed out | The viewer lacks `knk.admin.user.manage` (the tooltip says so) | Grant it, or use the map's own buttons |
| Escape doesn't close the panel right after a click in the map | The browser still has the old bridge script (before #757) | Reload the page without cache; check that `/bluemap-bridge/bridge.js` sends `escapePressed` |
| 429 answers | More than 120 map requests a minute from one IP | Raise `RateLimiting__Map__PermitPerMinute` if real users share an IP |

## Changes

1. 2026-11-19: § 6: "Open profile" disabled with a tooltip without `knk.admin.user.manage` (#809); § 9: the Escape row (#757); fix link F2
2. 2026-11-18: first version (the overview map chain #732, links L1–L9; docs PandiO/knk-workspace#766)
