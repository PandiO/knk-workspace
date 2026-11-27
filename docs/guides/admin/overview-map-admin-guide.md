# Overview map — Admin and Staff Guide

**Status:** Current · **Last updated:** 2026-11-20 (live-tested 2026-11-19 on dev and the alpha: § 2.1 the alpha's BlueMap settings, no static marker sets; § 3 sub-region outlines after the access sync, #750; § 7 `/ownermode` accepted; troubleshooting; screenshot placeholders; docs #767); 2026-11-19 (§ 6: "Open profile" disabled with a tooltip without `knk.admin.user.manage`, #809; troubleshooting: Escape inside the map, #757; fix link F2, in review for `next`); 2026-11-18 (first version, the overview map chain #732, docs PandiO/knk-workspace#766)
**Checked against:** knk-web-api `main` `75b84343` (v0.4), knk-plugin `main` `2411d785` (v0.3), knk-web-app `main`
`31a6896d` (v0.4); every part is off by default. Live-tested 2026-11-19: the [smoke test](../overview-map-smoke-test.md)
§§ 1–9 on dev, § 3 step 1 on the closed alpha (deployed there with `Map__Enabled=true` and
`map.reporting.enabled: true`)
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

1. **Components.** The API, the plugin and the web app from trunk (commits above). The migration
   `AddMapRegionOutlines` (one new table, `map_region_outlines`; additive) must be applied.
2. **The game hub.** Outlines, live players and gate commands all travel over the realtime game hub, so the plugin
   needs `realtime.enabled: true` and must be connected (API log: `Game server <id> connected to the realtime hub`).
3. **BlueMap.** The 3D view comes from a BlueMap render of a copy of the world, served by the stack's own nginx under
   `/bluemap/` with the bridge script the web app ships (`/bluemap-bridge/bridge.js`). Setup, version pin (v5.29) and
   the full-world render: [closed-alpha runbook Phase 10](../closed-alpha-deployment-runbook.md#phase-10--overview-map-bluemap-in-the-stack-737).
   The render is a snapshot: re-render after building work you want on the map. Pins, outlines and players are live
   and need no re-render. On the alpha the full-world render was skipped by the developer's decision; the map shows
   the area already rendered. The BlueMap settings the alpha uses are in § 2.1.
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
   service, so only use it when the developer picked one. The alpha uses Minotar (§ 2.1).

### 2.1 BlueMap settings on the closed alpha

Applied by the developer on 2026-11-19 and confirmed on the alpha after the promotion (smoke § 3 step 1). The paths
are in BlueMap's folder of the `knk-alpha` stack; keep a backup next to each file before you change it. The setup
steps themselves stay in [runbook Phase 10](../closed-alpha-deployment-runbook.md#phase-10--overview-map-bluemap-in-the-stack-737).

1. **Player heads from Minotar.** Append `&heads=https://minotar.net/helm/{uuid}/16` to the bridge script line in
   `config/webapp.conf`, so it reads
   `scripts: ["/bluemap-bridge/bridge.js?worlds=<map id>:<world>&heads=https://minotar.net/helm/{uuid}/16"]`, then
   write the web files again (`bluemap -g`). The URL must contain `{uuid}`; the bridge puts each player's UUID there and ignores a `heads=` without it. mc-heads.net was tried
   first and returned the default head (Steve) for the developer's account, also by name; Minotar shows the real
   skins. Every viewer's browser asks Minotar for the heads.
2. **Start position over Cinix.** `start-pos: { x: 1408, z: -522 }` in `config/maps/overworld.conf`. BlueMap writes
   it into the web files only at the next render, so until then also set `"startPos":[1408,-522]` in
   `web/maps/overworld/settings.json`; the next render rewrites that file from the config.
3. **No static marker sets.** The BlueMap spike's static `wg2bluemap` marker sets ("Towns" and "Districts", made by
   `scripts/bluemap/wg2bluemap.py`) were removed on 2026-11-19: the marker block in `config/maps/overworld.conf` is
   empty and `web/maps/overworld/live/markers.json` no longer has them. They showed as permanent district volumes
   that no map switch hides. Every outline on the map now comes from the bridge only (the flash and Show region,
   [player guide § 3](../users/overview-map-player-guide.md#3-towns-districts-and-buildings)); don't add static
   marker sets back.

## 3. Outlines and what keeps them current

1. With `map.reporting.enabled: true` the game server sends the outline of every Town, District, Structure and Gate
   region (points, min and max Y):
   1. after every managed-region repair (server start and `/knk regions repair`);
   2. right after a world task's Region step renames or redraws a domain's region (the old name is removed);
   3. again on every reconnect of the game hub (an API restart refills the table).
2. **A hand edit** with `/rg redefine` is not reported on its own: run `/knk regions repair` afterwards.
3. **Sub-regions** (expansion regions, `domain_<id>_sub_<n>`) are reported when a world task draws or renames them,
   and after every access sync, which runs at server start and on a hub reconnect
   ([#750](https://github.com/PandiO/knk-workspace/issues/750)). The plugin log then shows
   `[KnK Map] Region outlines (sub-regions): <n> outline(s), <n> removed, <n> not found, <n> too large, <n> message(s)`
   next to the `(domain regions)` line; both repeat on each hub reconnect. Known limit: a deleted sub-region is not
   reported as removed, so its outline stays on the map until that domain's next full outline report.
4. The API keeps the outlines in `map_region_outlines`, so the map keeps them while the game server is down. Only the
   plugin's game hub connection can write them. Architecture:
   [managed WorldGuard regions § 7 "Overview map outlines"](../../architecture/managed-worldguard-regions.md#overview-map-outlines-pandioknk-workspace735-on-trunk-since-knk-plugin-v03).
5. Changes (a rename, a new outline) reach open map pages within about 90 seconds (the 30 s marker cache and the
   page's 60 s check) without a reload.
6. **Labels and dots.** Each label fades out beyond its type's `Map__Labels__<Type>__MaxDistance` (§ 2 item 2), and
   since #825 (fix link F3) the dots of districts and structures fade with it; town and arena dots stay at every zoom.
   Grouping dots into clusters is still an idea ([#825](https://github.com/PandiO/knk-workspace/issues/825)).
   Regions are drawn like the spike's static markers since #826: a town is a flat surface with one outline and
   openings where its districts are, districts are see-through volumes without vertical edge lines and one outline
   along the top, heights clamped to y 20..120.

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

> **Screenshot to come:** `admin-staff-details.png` (a structure's panel for a `knk.admin.world` viewer: the public part, the compact Details section and Open full page). Shot list on [#767](https://github.com/PandiO/knk-workspace/issues/767).
<!-- ![a structure's panel for a `knk.admin.world` viewer: the public part, the compact Details section and Open full page](../images/overview-map/admin-staff-details.png) -->


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

> **Screenshot to come:** `admin-gate-commands.png` (a gate's panel for a `knk.gate.admin` viewer: Doors, then Gate commands with the Whole gate row, one row per door and a "Done: …" result). Shot list on [#767](https://github.com/PandiO/knk-workspace/issues/767).
<!-- ![a gate's panel for a `knk.gate.admin` viewer: Doors, then Gate commands with the Whole gate row, one row per door and a "Done: …" result](../images/overview-map/admin-gate-commands.png) -->


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
   Live-tested on dev 2026-11-19: freeze, kick and ban from the panel work, and a kick-only moderator sees the
   greyed-out "Open profile" with its tooltip.

4. A player without a web account shows "<name> has no account in the web app yet, so there is nothing to moderate
   here."
5. Everyone else gets only the name card; anonymous viewers make no extra request at all.

> **Screenshot to come:** `admin-moderation.png` (a player's card for a moderator with every node: the Moderation section with Freeze…, Kick…, Ban… and Open profile). Shot list on [#767](https://github.com/PandiO/knk-workspace/issues/767).
<!-- ![a player's card for a moderator with every node: the Moderation section with Freeze…, Kick…, Ban… and Open profile](../images/overview-map/admin-moderation.png) -->

> **Screenshot to come:** `admin-open-profile-disabled.png` (the same card for a kick-only moderator: Kick… and the greyed-out Open profile with its tooltip shown). Shot list on [#767](https://github.com/PandiO/knk-workspace/issues/767).
<!-- ![the same card for a kick-only moderator: Kick… and the greyed-out Open profile with its tooltip shown](../images/overview-map/admin-open-profile-disabled.png) -->

## 7. Hidden players and who sees them

1. Players in staff mode or owner mode, and players in a running siege match, never reach anonymous or plain
   logged-in viewers, not even in the API's response. A siege match shows as one pin, "[Siege] <count> players", the
   same for everyone.
2. A viewer holding `knk.mode.staff` or `knk.mode.owner` sees them anyway, tagged **Staff mode**, **Owner mode** or
   **Siege**. Who holds these nodes: [ranks, permissions and moderation § 8](ranks-permissions-moderation-admin-guide.md#8-nodes-in-this-guide).
3. Staff mode and siege matches were checked live (2026-11-18 on [#738](https://github.com/PandiO/knk-workspace/issues/738),
   and on dev 2026-11-19). The owner-mode case (`/ownermode`, tagged **Owner mode**) was not run live, because no
   second staff account was at hand; the developer accepted it on 2026-11-20. The API's automated tests cover it
   (`MapPlayersPipelineTests.StaffViewer_GetsHiddenPlayersTagged_RawBody`).

## 8. A safe test

Run the [overview map smoke test](../overview-map-smoke-test.md) on dev, section by section (the developer's run of
2026-11-19 passed §§ 1–9), with the accounts it
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
| A sub-region is missing from an outline | The access sync hasn't run since it was drawn, or reporting is off | Check the `[KnK Map] Region outlines (sub-regions)` log line; restart the game server or run that sub-region's step |
| A deleted sub-region still shows | Deletions of sub-regions aren't reported (known limit, § 3 item 3) | Run the domain's region step again, or `/knk regions repair` |
| Permanent district or town volumes that no switch hides | Static BlueMap marker sets (the spike's `wg2bluemap` "Towns"/"Districts") | Empty the marker block in `config/maps/overworld.conf` and remove them from `live/markers.json` (§ 2.1 item 3) |
| Every player has the default (Steve) head | No `heads=` on the bridge line, or the skin service doesn't know the skin | § 2.1 item 1; Minotar works where mc-heads.net returned Steve |
| The map opens far from the towns | `start-pos` not set, or `settings.json` not updated before the next render | § 2.1 item 2 |
| Pins on the wrong map, or none for a world | `worlds=<map id>:<world>` in `webapp.conf` doesn't match the pins' world | Runbook Phase 10 step 3 |
| No players | `Map__LivePlayers__Enabled` off, `map.reporting.enabled` off, or the game server isn't on the hub | Plugin log `[KnK Map] Live player report every 40 ticks`; `GET api/Map/players` |
| Gate buttons answer "no game server connected" | The plugin isn't connected to the hub | Check `realtime.enabled` and the API log; restart the game server |
| Gate buttons time out | The game server didn't answer within 5 s | Look at the door in game before repeating |
| "Details" shows a one-line message | The type has no default display configuration | Create one in the display builder (§ 4 item 3) |
| "Open profile" is greyed out | The viewer lacks `knk.admin.user.manage` (the tooltip says so) | Grant it, or use the map's own buttons |
| Escape doesn't close the panel right after a click in the map | The browser still has the old bridge script (before #757) | Reload the page without cache; check that `/bluemap-bridge/bridge.js` sends `escapePressed` |
| 429 answers | More than 120 map requests a minute from one IP | Raise `RateLimiting__Map__PermitPerMinute` if real users share an IP |

## Changes

1. 2026-11-20: live-tested 2026-11-19 on dev and the alpha (checked against trunk); § 2.1: the alpha's BlueMap
   settings (Minotar heads, start position over Cinix, no static marker sets); § 3 item 3 sub-regions after the access
   sync (#750), item 6 labels and dots (ideas #825, #826); § 6 live result; § 7 `/ownermode` accepted; § 9 new rows;
   screenshot placeholders (#767)
2. 2026-11-19: § 6: "Open profile" disabled with a tooltip without `knk.admin.user.manage` (#809); § 9: the Escape row (#757); fix link F2
3. 2026-11-18: first version (the overview map chain #732, links L1–L9; docs PandiO/knk-workspace#766)
