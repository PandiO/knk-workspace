# Overview map — smoke test

**Status:** Draft from the design (2026-11-18); no steps run. Steps not yet automated (the links tag them).
**Last updated:** 2026-11-18 (draft from the design, phases 1, 2, 3, 4a, 4b, 5, 6a, 6b, 7)
**Design:** [specs/in-game-maps/OVERVIEW_MAP_DESIGN.md](../specs/in-game-maps/OVERVIEW_MAP_DESIGN.md) · **Issue:**
[PandiO/knk-workspace#732](https://github.com/PandiO/knk-workspace/issues/732)

Accounts used throughout:

1. **Anonymous:** a private browser window, not logged in.
2. **Player:** a logged-in web account linked to a Minecraft player with no staff nodes.
3. **World staff:** holds `knk.admin.world` only.
4. **Gate admin:** holds `knk.gate.admin` only.
5. **Kick moderator:** holds `knk.kick` only.
6. **Staff viewer:** holds `knk.mode.staff`.

Test data: one town with at least two districts, a structure with a spawn location, a structure without one, and a
gate structure with two doors.

## 1. Phase 1: region outlines (#735, tier:3)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 1.0 Preconditions

1. Deployed: the API from `next` with the `map_region_outlines` migration applied, and the plugin build from `next`.
2. Settings: plugin `config.yml` `map.reporting.enabled: true`.
3. Data: the test town, its districts and the structures above, each with a WorldGuard region.

### 1.1 Steps

1. Start the game server and wait for the startup reconcile to finish. In the database, read `map_region_outlines`.
   **Expected:** one row per domain region id and world, with points, min Y and max Y. (A01)
2. Restart the game server. **Expected:** the same rows, updated in place with no duplicates. (A01)
3. In game, re-run the region step of one district so its region changes shape. **Expected:** that district's row has
   new points and a newer `UpdatedAt` within one reconcile. (A02)
4. Rename a `tempregion_worldtask_<n>` to `domain_<id>` through the world task flow. **Expected:** the row carries the
   new region id, and no row is left for the old id. (A02)
5. Set `map.reporting.enabled: false` and restart. Change a region. **Expected:** the row does not change. (flag)

## 2. Phase 2: public map API (#736, tier:3)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 2.0 Preconditions

1. Deployed: phase 1, and the API from `next`.
2. Settings: `Map:Enabled=true`.
3. Data: the phase 1 data with stored outlines.

### 2.1 Steps

1. With `Map:Enabled=false`, call `GET api/Map/config` and `GET api/Map/markers` without a token. **Expected:** 404
   for both. (A03)
2. With `Map:Enabled=true`, call `GET api/Map/markers` without a token. **Expected:** 200. The response has the town,
   its districts and the structures, each labelled with its name (not the region id). Structures add type and
   subtype. The structure with a spawn location has its pin there. The structure without one has its pin at the
   centre of its outline. (A04)
3. Call `GET api/Map/towns/{id}`, `GET api/Map/districts/{id}` and `GET api/Map/structures/{gateId}` without a token.
   **Expected:** only the O32 fields. Town: name, description, district count. District: name, description, town.
   Structure: name, description, type and subtype, district, town, street and house number. Gate: plus, per door,
   name, open/closed, destroyed and health. No region ids, owner data or internal ids beyond the entity's own.
   (A05)
4. Send 121 requests to `GET api/Map/markers` within one minute from one IP. **Expected:** the 121st answers 429.
   (A06)

## 3. Phase 3: map page (#737, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 3.0 Preconditions

1. Deployed: phase 2, the web app from `next`, and BlueMap tiles and web app under `/bluemap/` with the bridge script
   in `webapp.conf`. The render container is the existing NAS `bluemap-test`, migrated into the `knk-alpha` stack
   (spec § 3.1.10); `docker ps` shows it as a stack service, not a hand-started container.
2. Settings: `Map:Enabled=true`.

### 3.1 Steps

1. As **anonymous**, open the web app. **Expected:** a "Map" entry in the header. `/map` loads the 3D map without a
   login. Town labels show at every zoom. District and structure labels appear only when zoomed in. (A07)
2. Click the town pin. **Expected:** the town outline flashes three times and disappears. The panel shows the town's
   public fields. (A08)
3. Turn on "Show region" in the panel. **Expected:** the town outline and all its districts stay visible. Each
   district is labelled with its name, never a region id. Judge whether showing all districts at once works, and note
   your verdict for a follow-up (O30). (A08)
4. Click the gate structure. **Expected:** the panel lists each door with open/closed, destroyed and a health bar.
   (A09)
5. On a phone, repeat steps 2 and 4. **Expected:** the panel opens as a bottom sheet and the map stays usable. (A07)
6. With `Map:Enabled=false`, reload the web app. **Expected:** no "Map" entry. `/map` shows "not available". (A07)

## 4. Phase 4a: live players backend (#738, tier:3)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 4.0 Preconditions

1. Deployed: phase 2, the API and plugin from `next`.
2. Settings: `Map:LivePlayers:Enabled=true`. Plugin `map.reporting.enabled: true`, `map.reporting.interval-ticks: 40`.
3. Accounts: players A (no mode), B (a staff member who can enter staff mode) and C (owner); a siege scenario ready to
   start.

### 4.1 Steps

1. With player A online, call `GET api/Map/players` without a token. Move A 20 blocks and call it again after 2 s.
   **Expected:** A is listed with world and position, and the second response shows the new position. (A11)
2. B enters `/staffmode`. Call the endpoint without a token, then with the **player** token. **Expected:** B is absent
   from both response bodies (check the raw JSON). (A12)
3. Call it with the **staff viewer** token. **Expected:** B is listed with the tag "Staff mode". C in `/ownermode` is
   listed with "Owner mode". (A12)
4. A stays idle until the plugin marks them AFK, or uses `/afk`. **Expected:** the AFK tag appears within one interval.
   (A13)
5. Start a siege match with A in it. Call the endpoint without a token and with the **player** token. **Expected:** A
   is absent from both. One arena entry at the gate reads "[Siege] <count> players" for both callers. (A14)
6. Compare the label parts for C (owner), B (staff), a premium player and a default player with their in-game chat
   lines. **Expected:** the same bracket or title, name and colour codes. (A15)
7. A quits. **Expected:** A is gone within three intervals (6 s). (A16)
8. Watch the plugin's performance metrics for the reporting task during step 1 with 20 or more players online.
   **Expected:** no noticeable tick time. Note the number. (§ 9.1)

## 5. Phase 4b: live players layer (#739, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 5.0 Preconditions

1. Deployed: phases 3 and 4a, the web app from `next`.
2. Settings: as § 4.0.

### 5.1 Steps

1. As **anonymous**, open `/map` with player A online and walking. **Expected:** A's head and name label move along
   about every 2 s. (A11)
2. Look at labels for an owner, a staff member, a premium player and a default player. **Expected:** the same format
   and colours as their in-game chat lines. AFK shows as a tag. (A13, A15)
3. B is in staff mode. **Expected:** B is not on the map for anonymous or the **player** account. The **staff viewer**
   sees B as a normal player with the "Staff mode" tag. (A12)
4. During a siege match, look at the gate. **Expected:** the participants are not shown. One pin reads
   "[Siege] <count> players". (A14)
5. Click player A as **anonymous**. **Expected:** a name card with the label and tags only. (A11)

## 6. Phase 5: staff details (#740, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 6.0 Preconditions

1. Deployed: phase 3, the web app from `next`. Structures have a default display configuration.

### 6.1 Steps

1. As **world staff**, click a structure. **Expected:** a "Details" section under the public part shows the display
   configuration in compact form, with "Open full page" leading to `/display/Structure/<id>`. (A17)
2. As the **player** account, click the same structure. **Expected:** no "Details" section. The browser's network tab
   shows no display-configuration request. (A17)

## 7. Phase 6a: gate commands backend (#741, tier:3)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 7.0 Preconditions

1. Deployed: phase 2, the API and plugin from `next`, with the game server connected.
2. Settings: `Map:GateCommands:Enabled=true`.
3. Accounts: **gate admin**, **world staff**. The test gate's doors start closed. Stand next to the gate in game.

### 7.1 Steps

1. As **gate admin**, call `POST api/GateStructures/{id}/commands` `{action: "open", doorId: <door 1>}`.
   **Expected:** 200 with the result "done". Door 1 opens in game with its normal animation, and its stored state is
   open. (A18)
2. Repeat with `close`, `toggle`, and `open` without `doorId`. **Expected:** each acts as named, and the last one opens
   every door. (A18)
3. Damage door 1 in game, then send `repair`. **Expected:** health is back to full and the door is no longer destroyed.
   (A18)
4. Send a command as **world staff**. **Expected:** 403, and nothing changes. (A19)
5. Start a siege match on the gate and send `open` as **gate admin**. **Expected:** 409 "Gate is in a running
   siege", and nothing changes. (A19)
6. Stop the game server and send `open`. **Expected:** 503. (A19)
7. Send a `doorId` of another gate. **Expected:** 400. (A19)
8. Read the audit log. **Expected:** one entry per command with the user, the action, the door and the result. (A19)
9. With `Map:GateCommands:Enabled=false`, send a command. **Expected:** the endpoint refuses, and nothing changes.
   (flag)

## 8. Phase 6b: gate command buttons (#742, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 8.0 Preconditions

1. Deployed: phases 3 and 6a, the web app from `next`. Settings as § 7.0.

### 8.1 Steps

1. As **gate admin**, open `/map` and click the gate. **Expected:** Open, Close, Toggle and Repair per door and for the
   whole gate. (A18)
2. Click Open on door 1. **Expected:** the door opens in game, and the panel shows "open" after the result. (A18)
3. Start a siege on the gate. **Expected:** the buttons are disabled with "Gate is in a running siege". (A18)
4. As **world staff**, click the gate. **Expected:** no command buttons. (A18)

## 9. Phase 7: player moderation panel (#743, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 9.0 Preconditions

1. Deployed: phase 4b, the web app from `next`. Player A is online.
2. Accounts: **kick moderator**, the **player** account, and a staff member holding every moderation node.

### 9.1 Steps

1. As the **kick moderator**, click A on the map. **Expected:** the panel shows only Kick and "Open profile". (A20)
2. Click Kick. **Expected:** A is kicked in game, the same as from the moderation page. (A20)
3. As the staff member with every moderation node, click a player. **Expected:** Freeze, Unfreeze, Kick, Ban and
   "Open profile". Freeze works as on the moderation page. (A20)
4. As the **player** account, click A. **Expected:** only the name card. (A21)
