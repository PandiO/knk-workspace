# Navigation and teleports — admin guide

**Status:** Current · **Last updated:** 2026-11-25 (§ 1 route mode node row; § 2.6 the other off-road keys; § 2.7 new: route modes and a permission group's default route mode with its deploy steps, in `next`, PandiO/knk-workspace#707, #852, docs #1033); 2026-11-22 (§ 3.2 and § 7: landmarks as warps and `/navigate` places, on `next`, PandiO/knk-workspace#976, docs #1008); 2026-11-22 (§ 2.6: `navigation.guidance-v2` is on by default and is the kill switch of the walk-trail quality pass, PandiO/knk-workspace#996, #990); 2026-11-20 (§ 1: `knk.navigate` is `default: false` and seeded to Default, `knk.navigate.any` row, PandiO/knk-workspace#845); 2026-11-18 (§ 1: the route mode nodes `knk.navigate.mode.<word>`, PandiO/knk-workspace#707); 2026-11-13 (new guide: road network setup, upkeep and reset, Road network page, warps, spawn and hub, group fees, rank perks, staff teleports and exemptions, PandiO/knk-workspace#298)
**Checked against:** knk-plugin `main` `57884e9`, knk-web-api `master` `75b5a00`, knk-web-app `main` `3ba747d` (desk check); `next` only for what § 7 names
**Related:** [player guide](../users/navigation-and-teleports-player-guide.md) (what players see; not repeated here), [commands](../users/commands.md) (§ Teleporting players, `/knk road`), [plugin configuration](plugin-configuration.md) § 4.10 `teleport` and § 4.15 `navigation`, [Game Settings](../game-settings.md), [staff web app guide § 9](staff-web-app-guide.md#9-settings-pages), [road navigation design](../../specs/navigation/DESIGN.md) § 5 and § 7, [teleport design](../../specs/teleport/DESIGN.md)

For staff who set up the road network that `/navigate` uses, open places as teleport destinations, set spawn and
teleport prices, and move players.

## 1. Permissions and prerequisites

| Node | Gives | Rank on the seed data |
|---|---|---|
| `knk.admin.road` | `/knk road …` in game and the web app's **Road network** page | Staff |
| `knk.navigate` | `/navigate` and the navigation compass. Given to everyone through the Default group by the knk-web-api seed `SeedNavigateDefaultNode`; `plugin.yml` declares it `default: false` (PandiO/knk-workspace#845, PandiO/knk-plugin#106), so a deny on a rank or player in the in-house system takes `/navigate` away. Before #845 it was `default: true` and could not be taken away (#311) | Everyone (Default) |
| `knk.navigate.any` | With `navigation.destination-engine` on: `/navigate` to any place in the world, past the siege and permission scopes (frozen still refuses). `plugin.yml` declares it `default: false` | none yet (the staff rank(s) are the developer's call, open on PandiO/knk-workspace#845) |
| `knk.navigate.mode.shortest`, `.mode.efficient`, `.mode.preferred` | The route mode words of `/navigate <place> <word>` (in `next`, PandiO/knk-workspace#707; § 2.7): `shortest` length only, `efficient` road class and walking costs without the road weights, `preferred` typed explicitly (the same route as no word). `/navigate` without a word needs none of them, and neither does a group's default route mode (§ 2.7). `plugin.yml` declares them `default: op` | none (no seed; grant them per group or player while the developer decides who gets them) |
| `knk.teleport.spawn`, `.warp`, `.request` | `/spawn`, `/warp`/`/warps`, `/tpa` | Everyone |
| `knk.teleport.request.here`, `knk.teleport.back` (+ `.back.warps\|teleport\|spawn\|all`) | `/tpahere`, `/back` and the kinds of place `/back` remembers | Dragon Blood (`/back` kinds: as staff grant them) |
| `knk.teleport.warmup.short`, `.bypass.warmup\|cooldown\|combat\|cost\|requirements` | Rank perks: 3 s warmup, no warmup, no cooldown, teleport in combat, free, ignore warp requirements | Noble and up for the short warmup; the rest staff |
| `knk.teleport.staff`, `.staff.others`, `.staff.silent`, `.staff.back.others` | Staff teleports (§ 4) | Staff; `.back.others` ops only |
| `knk.teleport.all.tp\|tphere\|spawn\|hub` | The `all` forms | Moderator |
| `knk.teleport.exempt.<hub\|spawn\|tp\|tphere>`, `.exempt.*` | Not moved by others' teleports of that kind | none by default |
| `knk.admin.config` | Game Settings (spawn, hub) | see [Game Settings](../game-settings.md) |

Ranks get nodes from the seed data for now; one player gets one with `/knk user <player> perm grant <node>`. The exact
rank columns and how premium ranks inherit: [commands § How access works](../users/commands.md#how-access-works).

You need: the web app and API running, WorldGuard regions on the towns, districts and structures, and gate
structures set up where roads pass gates ([gate structures admin guide](gate-structures-admin-guide.md)). Plugin
settings are in `config.yml` under `teleport:` and `navigation:`; new keys must be merged by hand on dev and alpha at
each deploy ([plugin configuration § 2](plugin-configuration.md)).

## 2. The road network

`/navigate` routes over a graph of the roads that the plugin **builds from the blocks in the world**: you teach it
what roads look like, it finds junctions and dead ends by itself, and you fix what it got wrong. Nothing asks for
coordinates. The terms:

- **Road profile:** a road style (surface, edge, accent and overlay materials, a class `Main`/`Road`/`Path` and a
  width). Only blocks of an enabled profile count as road.
- **Tile:** a 512 × 512 square of a world, the unit of building and storage.
- **Node:** a junction, a dead end, a tile border, or an **anchor** you place. A **named** node is a `/navigate`
  destination.
- **Edge / stretch:** the road between two nodes, with its street, class, cost and flags. The web app calls them
  stretches.
- **Street:** the name players see in turn instructions. Stretches get it from the Structures along them; you name the
  rest.

### 2.1 First setup of an area

1. **Teach the road styles** (in game, about 5 minutes per style): `/knk road survey start [profile]`, walk the road
   for a few minutes, `/knk road survey stop`. Review the proposed profile in chat, then `/knk road survey save [name]`,
   `merge <profile>` or `discard`. Repeat for each style: main street, country road, forest path, and each kingdom's
   look.
2. **Build:** `/knk road build radius <blocks>` around the town (or `here`, `tile <x> <z> [world]`, `all`). Domain spawn
   points within 8 blocks of a road, survey paths and seeds (`/knk road seed add [note]`) start the search. `/knk road
   build status` shows the queue, `cancel` stops it.
3. **Read the build summary:** nodes and edges, levels, lost nodes, street conflicts, suspected leaks (road spilling
   into a plaza or a field), gaps and survey coverage misses, each with a clickable teleport.
4. **Look at it:** `/knk road show [radius] [all]` draws nodes and edges as particles (by street; unlabelled grey,
   stale orange, closed red); `hide` stops it. `all` shows every level, not just yours.
5. **Fix:**
   - a gap (wooden bridge, ford, grass path, ladder): add the material to a profile (`/knk road profile role <profile>
     <material> <Surface|Edge|Accent|Overlay>`, or in the web app), or walk the stretch with `/knk road record start`,
     `stop [street]`;
   - a junction found twice or missed: `/knk road node merge <keepId> <mergeId>`, `node anchor [name]`; move one with
     `node move <id>` (to where you stand);
   - a square: `/knk road node plaza <radius> [id]` makes one junction of it (`unplaza` undoes);
   - a road routes must not use: `/knk road edge set <id|here> nogps` or `close` (`open` undoes); `oneway`, `cost <x>`
     tune it; `edge prune <id|here>` and `node prune` remove a wrong piece for good (`unprune` undoes);
   - names: `/knk road node name <name>` makes a destination; `/knk road street <street> [edgeId] [--continue]`
     labels a stretch, `--continue` carries the label through straight junctions.

Edited, merged and recorded nodes are **locked**: a rebuild keeps them (and absorbs rebuilt junctions within 8
blocks).

### 2.2 Keeping it up to date

- Placing or breaking road blocks marks the tile **dirty**; routing keeps the old graph until you run `/knk road build
  dirty`.
- A tile that has been built once is **curated**: a rebuild doesn't replace it but makes a **proposal**. `/knk road
  proposal` lists it (the tile you stand in, or `@x,z`), `/knk road show` draws it (added green, removed red, changed
  yellow); `proposal accept <all|n…|kind>` / `reject …` merge or refuse items, `rejected` and `unreject` manage the
  refused list. `/knk road tile uncurate` lets one tile's next build write straight through. `/knk road edge confirm
  <id|here>` keeps a stretch a build lost.
- `/knk road tiles` lists tiles, their builder version and what waits for review; `/knk road status` shows nodes,
  edges and tiles per world, profiles, dirty tiles and the build queue.
- Street names change in the web app only (§ 2.3); the game picks them up within a minute.

### 2.3 The Road network page (web app)

**Admin → World → Road network** (`/admin/roads`, `knk.admin.road`). Everything in the world (surveys, builds, the
overlay) is `/knk road`; this page is for naming, profiles, tuning and overviews. It has three parts:

1. **Overview** with a world picker: road profiles (create, edit, enable, delete), tiles (dirty and warning filters,
   the build warnings, "show edges" of a tile) and **Stretches**: filter by street, unlabelled or stale; edit a
   stretch's street (or create one; "Continue along the road"), profile, cost multiplier and flags, and save it with
   its own **Save stretch #n**. **Rename** opens the Street form.
2. **Navigation defaults**, per domain type (Town, District, Structure, gate structure): where `/navigate` leads without
   `spawn`/`region` (**Spawn** or **Region**), and the **entry rule on roads**: *Applies* (routes respect the place's
   entry and exit rules) or *Ignored* (routes pass through, for houses and shops along a street; the rule still holds
   at the border). One place overrides its type on its own form ("Navigation Default Override", "Road Access
   Override").
3. **Navigation compass**: which item is the siege navigation compass ([compass design](../../specs/navigation-compass/DESIGN.md)).

Navigation defaults and the compass save together with the page header's **Save (n)**: a choice no longer saves on
change, and anything the API refuses is named. Profiles and stretches keep their own Save and aren't counted in the
header. One save for all road settings and "who saved last" need an API change (PandiO/knk-workspace#190). The header
itself: [staff web app guide § 9](staff-web-app-guide.md#9-settings-pages).

### 2.4 Checking a route

`/knk road why <destination> [--as <player>]` prints the route for you, or as that player would get it, with every
blocked gate and domain on the way (`edge #10139 blocks 31-34` = a piece of a stored stretch). `/knk road goto <x>
<y> <z> [world]` teleports you to a spot from a summary. Gates block when closed, closing, opening or jammed; a domain blocks
when its entry is closed, its exit is closed (the route leaves it), or the player could enter but not leave again. A
domain rule change reaches routes within about a minute; `/knk cache refresh` makes it immediate.

### 2.5 Starting over: the reset script

[`road-navigation-reset.sql`](../road-navigation-reset.sql) deletes **all** road data (stretches, nodes, tiles, seeds,
surveys and every profile) and keeps streets. Use it only on dev, or for a rebuild you have decided on:

1. Back up: `mysqldump <db> road_profiles road_surveys road_tiles road_seeds road_nodes road_edges > roads-backup.sql`.
2. Stop the Minecraft server (at least: no build, survey or record while it runs).
3. Run the script against the API database. It prints the row counts first and runs in one transaction. A commented
   `INSERT` at the end puts the bootstrap "Default road" profile back.
4. Delete the plugin's tile cache, `plugins/KnightsAndKings/roads/`; otherwise the plugin serves the old tiles from
   disk.
5. Start the server: `/knk road status` shows 0 nodes, edges and tiles. Start again at § 2.1.

To keep learned profiles, save them first (the dump above), or restore them afterwards the way
[`road-navigation-restore-profiles-2026-10-01.sql`](../road-navigation-restore-profiles-2026-10-01.sql) did once.

### 2.6 Settings

`navigation.*` in `config.yml`: on/off, class costs, the 48 / 96 / 256-block limits, trail look, reroute and arrival
distances, session length, builder and walk-path settings (`walk.enabled: false` is the kill switch back to straight
lines). See [plugin configuration § 4.15](plugin-configuration.md); all need a restart.

**`navigation.guidance-v2` (on by default since 2026-11-22, #990).** The flag switches the off-road trail-quality
pass that players see on walked stretches (what it looks like: [player guide § 2.3](../users/navigation-and-teleports-player-guide.md#23-off-the-road)).
With it on, walk paths keep `walk.wall-clearance` (0.8) from walls, the walk trail has curved corners (`walk.curve`),
its particles sit on fixed anchors `trail-leg-spacing` (2.0) blocks apart, the route cursor follows a player who walks
back, and a walk leg stays while the player is within `walk.recompute-distance` (6) of it. NPC movement is not
affected.

1. **Kill switch:** `guidance-v2: false` and a restart bring back the old trail exactly (walk paths, search and
   trail as before the pass). Use it if players report odd walk trails; tell the developer which place.
2. **Which value a server has:** the plugin never adds keys to an existing `config.yml`. A server whose file has no
   `guidance-v2` line gets it **on**. A file that was merged since #710 (2026-11-17) has `guidance-v2: false` written
   in and **keeps it off** until you change the line to `true`. Check with a look at the file; no command shows it.
3. **Test:** with the flag on, `/navigate` to a place that needs a walked stretch (a room upstairs), walk it and step
   back along it: the particles stay on their spots, the trail follows you back. Steps: [off-road smoke test § 16](../navigation-offroad-smoke-test.md).
4. `walk.enabled: false` is a different switch (no walked stretches at all); it is unaffected.

**The other off-road keys** (off-road chain, PandiO/knk-workspace#698, in `next`): each is off or at today's behaviour
by default, needs a restart and is described in [plugin configuration § 4.15](plugin-configuration.md#415-navigation).
How they work inside: [off-road navigation architecture](../../architecture/offroad-navigation.md).

1. `walk-links` (off): a route may leave the road for a walked shortcut between two road junctions, such as across a
   courtyard; with it the road-first rule (`road-first-share`, `road-first-max-ratio`) sends a near target over the
   road when the road carries most of the way. Accepted by the developer without a live test (off-road smoke § 3).
2. `road-goal-reachable` (off): a destination off the road gets the road point from which it can really be walked to
   (up to `road-goal-candidates` points searched, scored road plus `road-goal-walk-weight` × walk), instead of the
   nearest road point in a straight line. Each choice writes one INFO line with every candidate's lengths.
   `road-to-its-end` (off) keeps a followed road route when the road network is swapped near the destination.
   Live-tested 2026-11-20 (off-road smoke § 13, § 14).
3. `plaza-lines` (off): the road trail crosses a plaza along a rounded line from road to road instead of the sharp
   bend at the plaza node. Only the drawn trail changes. `/knk road plazaline` shows the lines to staff whatever the key
   says. Live-tested 2026-11-21 (off-road smoke § 10.2).
4. `landmarks` (off) and `preference-max` (4.0): landmarks in `/navigate` (also needs `destination-engine: true`) and
   their preference weights on walk legs in the `preferred` route mode; see the [landmarks admin guide](landmarks-admin-guide.md).
5. `walk.max-chunks-per-request` (64): keep it; raise it on a test server only, for measurements.

### 2.7 Route modes and a group's default route mode

`/navigate <place> [shortest|efficient|preferred]` picks how the route is chosen (off-road phase 4, PandiO/knk-workspace#707;
what players read: [player guide § 2.8](../users/navigation-and-teleports-player-guide.md#28-route-modes)):

| Mode | Road edges cost | Walked legs cost |
|---|---|---|
| `shortest` | their length | the blocks walked; doors, water, drops and ladders stay passable at no extra cost |
| `efficient` | length × the road class's `class-cost` | the walk costs of `navigation.walk` (stairs, ladders, doors, water, drops, walls) |
| `preferred` (default) | `efficient` × the road profile's and the edge's cost multiplier (the Road network page) | as `efficient`, × the landmark preference weights with `navigation.landmarks: true` |

`preferred` is the route `/navigate` always took: without a word and without a group default the route is exactly
today's. NPC routes always use `preferred`. No `config.yml` key is added.

**Who may type a word.** Each word needs its node `knk.navigate.mode.<word>` (§ 1); there is no seed, so only
operators have them until you grant them. Grant a node to a group in its **Permissions** panel or to one player with
`/knk user <player> perm grant knk.navigate.mode.shortest` ([ranks admin guide § 3](ranks-permissions-moderation-admin-guide.md#3-giving-someone-a-group-a-rank-or-a-node)).
A player without the node who types the word gets "You don't have permission to use this command."; Tab offers only
the words they hold.

**A group's default route mode** (L7b, PandiO/knk-workspace#852, in `next`): the mode `/navigate` takes for the group's
members when they type no word.

1. **Set it:** **Dashboard → Permission group** → the group → **Edit**, step **Group**, field **Default route mode**:
   **Shortest**, **Efficient**, **Preferred** or **None (default: Preferred)**. Save. Needs `knk.admin.user.perm` and a
   group ranked below your own, as every group edit. The dashboard's **Default route** column shows the value ("-" for
   none).
2. **Which default wins:** of the player's active groups that set one, the group with the highest weight (on a tie, the
   lower group id). No group sets one: `preferred`, as before.
3. **No node needed:** a group default needs no `knk.navigate.mode.*` node; a typed word still needs its node and always
   beats the default.
4. **When it applies in game:** the plugin caches each player's default and fills the cache in the background (when the
   player types `/navigate` or presses Tab), so the very first `/navigate` after a join or a change can still run in
   `preferred`; the next one uses the default. A group edit or a membership change (in the web app or in game, over
   realtime) clears the cache; without an event the cache is refilled after 10 minutes. Without the API nothing is
   cached and every route is `preferred`.
5. **Not applied:** in a siege match on the old path (with `navigation.destination-engine` off), where mode words are not
   read either.

**Deploy** (knk-web-api first, then the web app, then the plugin; the plugin reads either spelling, so the order only
matters for the form):

1. Apply the migrations `20261120101407_AddPermissionGroupDefaultRouteMode` (adds the nullable column
   `permission_groups.DefaultRouteMode`) and `20261121144143_NormalizePermissionGroupDefaultRouteMode` (renames stored
   lowercase words to the enum names `Shortest`, `Efficient`, `Preferred`), in that order ([production installation
   § 5.3](../production-installation.md) items 10 and 19).
2. A fresh import of the `PermissionGroup` form seed has the field. A database that imported the seed earlier: add the
   field in the form designer to step **Group**, field name `DefaultRouteMode`, type **Enum**, settings JSON
   `{"enumValues": ["Shortest", "Efficient", "Preferred"], "emptyOptionLabel": "None (default: Preferred)"}`. A field
   added by hand as a String field before 2026-11-21: change its type to **Enum** and its settings to these, or the
   form can't be published. The values must be the enum names: an edit pre-selects the stored name.
3. No `config.yml` change; restart the plugin after its deploy.

**Safe test:** on the dev server, set **Efficient** on a test group with one member, have that member `/navigate` to a
place twice (the first may still be `preferred`), then type `/navigate <place> shortest` without the node: refused.
Full steps: [off-road smoke test § 5](../navigation-offroad-smoke-test.md#5-phase-4-route-modes-707-tier2) and
[§ 15](../navigation-offroad-smoke-test.md#15-l7b-default-route-mode-per-permission-group-852-tier3).

## 3. Teleports

### 3.1 Spawn and hub

`/spawn` and the join teleport go to the **Join Spawn** of the Game Settings page (a Location, or a town, district or
structure's spawn), else the main world's spawn. A permission group can have its own spawn there. `/hub` goes to the
hub spawn of the Hub card; without a usable hub it refuses. See [Game Settings](../game-settings.md); changes reach the
game within 30 seconds, or at once with `/knk cache refresh`.

### 3.2 Warps (teleport destinations)

Any Town, District or Structure can be a destination, and on `next` a Landmark too (its form's **Warp destination**
step, `/warp landmark:<name>`; [landmarks admin guide § 3.4](landmarks-admin-guide.md#34-warp-destination-own-region)). On its form in the web app (dashboard → the record → Edit), the
teleport fields are:

| Field | Effect |
|---|---|
| `TeleportEnabled` | Listed in `/warps`, the teleport menu and `/warp` tab completion. Needs a Location and an open entry (AllowEntry). |
| `TeleportPriceGems` | Gems per teleport (0 = free). Taken after the warmup, refunded if the teleport fails. |
| `TeleportMinTitleBracket` | The title a player needs. |
| `TeleportMinPremiumGroup` | The lowest premium tier (a premium group) a player needs. |
| `TeleportRequiresDiscovery` | The player must have discovered the place first. |

The field labels on the form come from its form configuration, so they may read differently. The plugin caches each
player's list for 60 seconds (`teleport.destinations.cache-seconds`); `/knk cache refresh` clears it. Holders of
`knk.teleport.bypass.requirements` / `.bypass.cost` ignore the locks / the price; staff sending a player with
`/warp <place> <player>` ignore both.

### 3.3 Prices and cooldowns per rank

A permission group's form has a **Teleport** step with three blocks: `/tpa` (also `/tpahere`, paid by the asker),
`/warp` (also the teleport menu) and `/spawn` (also `/hub`). Each has a price mode and a cooldown (s):

1. **None:** this group sets nothing; the next group decides.
2. **Multiplier** (`/tpa`, `/warp` only): a factor on the default price (`teleport.request.price-coins`, or the
   destination's gems); 0 = free.
3. **Fixed:** coins, gems and/or XP instead of the default. XP can lower the player's title.

A player in several groups gets price and cooldown, each on its own, from the first group that sets it, in the same
order as the [Game Settings group overrides](../game-settings.md#permission-group-overrides), so a player's spawn and
their `/spawn` price come from the same group. Nothing set anywhere: the `config.yml` defaults (free requests, the destination's gems, a free
`/spawn`, 30 s cooldown). Reference: [KNG41_FORMCONFIGS.md](../../specs/teleport/KNG41_FORMCONFIGS.md).

### 3.4 `/back`

On by default (`teleport.back.enabled`), 5 minutes per place (`back.expire-seconds`, per kind with
`back.expire-seconds-by-kind`), free unless `back.price-coins` is set. Which places a rank's `/back` remembers is the
`knk.teleport.back.*` nodes (§ 1). `/back <player> [-s]` sends a player back to their latest place.

### 3.5 Moving players (staff teleports)

The commands are in [commands § Teleporting players](../users/commands.md#teleporting-players). In short: instant, no
cost, cooldown or combat check; only players of your rank or lower; `-s` (with `knk.teleport.staff.silent`) skips the
message, and vanished staff are always silent; region and siege rules still apply. Every staff teleport is logged on
the server and in the player's profile in the web app ("Teleported by staff").

**`all` forms and exemptions** (alpha run 1, PandiO/knk-workspace#171): `/spawn all`, `/hub all`, `/tphere all` and
`/tp all <player>` move every online player of your rank or lower, apart from you, players in staff or owner mode and
players exempt from that kind. Grant `knk.teleport.exempt.<kind>` (or `.exempt.*`) to a rank or player who must not be
moved: streamers, staff on duty, a builder in the middle of work. Exempt players can't be moved one by one either,
except by the console or a holder of `knk.admin.user.manage.all` (the owner); the `all` forms never move them.

## 4. A safe test

On the dev server, with a staff account and a second player account:

1. `/knk road status`: the world has nodes and edges. `/navigate <a named town>` from a road: trail, boss bar, a turn
   instruction, arrival.
2. Close a gate on that route (or set `AllowEntry` off on a district the route crosses): "… recalculating." and a
   route around, or the partial-route message. `/knk road why <town> --as <player>` names the block.
3. Enable one town as a warp at 10 gems; as the player: `/warps`, `/warp <town>`, move during the warmup (no gems
   taken), then let it finish (gems taken, "You paid …").
4. `/tpa` between the two accounts, accept, deny, let one expire.
5. Grant the player `knk.teleport.exempt.spawn`, run `/spawn all`: the player stays.

The full checklists: [road navigation smoke test](../road-navigation-smoke-test.md) and the teleport plan's smoke tests
([plan](../../specs/teleport/IMPLEMENTATION_PLAN.md)).

## 5. When something goes wrong

| Symptom | Likely cause |
|---|---|
| "No road network is loaded for <world> yet." | No tiles built in that world, or the plugin can't reach the API at startup. `/knk road status`. |
| A road is missing from routes | Its material is in no enabled profile, the tile is dirty or never built, or a stretch is `nogps`/`close`d. `/knk road show` there. |
| Routes cut through a field or plaza | A leak: an ambiguous material (cobblestone, planks) spread; check the build summary's leak warnings and the profile's ambiguous flags. |
| A rebuild changed nothing | The tile is curated: see `/knk road proposal`. |
| After a reset the old roads are back | The tile cache `plugins/KnightsAndKings/roads/` wasn't deleted. |
| A town is missing from `/warps` | `TeleportEnabled` off, no Location, entry closed, or the 60 s cache: `/knk cache refresh`. |
| "Teleporting isn't available right now." | The game can't reach the API (fees, destinations and group policies need it; PandiO/knk-workspace#35). |
| Staff teleports move a frozen player | Known (PandiO/knk-workspace#309). |

## 6. Effects on existing data

- Builds and accepted proposals replace the stored graph of a tile; locked and named nodes, manual street labels and
  confirmed stretches are kept. The reset script deletes everything except streets.
- Turning a warp off removes it from lists at once for new lookups (60 s cache); it doesn't refund earlier payments.
- Teleport payments show as balance changes (`teleport.*`) in the player's transactions.

## 7. Not shipped yet

1. **NPC navigation** (Citizens adapter, PandiO/knk-workspace#358, phases #359–#361 and #377): in `next`, not yet
   released. It reuses the road network for NPC routes (`/knk npc nav`); nothing changes for players or for § 2.
2. **Navigation destination engine** (PandiO/knk-workspace#25): design only.
3. **Landmarks** (PandiO/knk-workspace#976, #708): in `next`, not yet released. Named places for `/navigate`, warps
   and discovery, made as domains: [landmarks admin guide](landmarks-admin-guide.md).
4. **Entrances** as a destination mode (PandiO/knk-workspace#110), sub-regions in routes (#140), a negative cache for
   regions without a domain (#317), player homes (decision #447).

## Sources

1. Code: knk-plugin `roads/RoadAdminCommand`, `navigation/`, `teleport/TeleportExemptions`, `commands/`,
   `plugin.yml`, `config.yml`; knk-web-api `Models/Domain.cs`, `Models/PermissionGroup.cs`,
   `Services/TeleportGroupPolicy.cs`; knk-web-app `pages/admin/RoadsAdminPage.tsx`, `components/admin/roads/`.
2. [Road navigation design](../../specs/navigation/DESIGN.md) (§ 5, § 6.7, § 7) and
   [plan](../../specs/navigation/IMPLEMENTATION_PLAN.md); [teleport design](../../specs/teleport/DESIGN.md) and
   [plan](../../specs/teleport/IMPLEMENTATION_PLAN.md); [off-road navigation design](../../specs/navigation-offroad/DESIGN.md)
   § 5.4 (route modes).
3. [Road navigation smoke test](../road-navigation-smoke-test.md); the Road network page notes of the #337–#345 docs
   session (comment on PandiO/knk-workspace#298).
4. § 2.6 off-road keys and § 2.7 (docs #1033): knk-plugin `next` `2c5d5846` (`roads/route/RouteMode`,
   `GroupRouteModeResolver`, `navigation/NavigateCommand`, `GroupRouteModeDefaults`, `config.yml`, `plugin.yml`),
   knk-web-api `next` `e06fd5c0` (`Models/PermissionGroup.cs`, `Enums/NavigationEnums.cs`, the two migrations, the
   `PermissionGroup` form seed), knk-web-app `next` `8be9e24c` (`config/objectConfigs.tsx`); the
   [off-road chain report](../../reports/2026-11-17-navigation-offroad-chain.md) for the live-test results.
