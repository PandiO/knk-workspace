# Navigation and teleports — admin guide

**Status:** Current · **Last updated:** 2026-11-13 (new guide: road network setup, upkeep and reset, Road network page, warps, spawn and hub, group fees, rank perks, staff teleports and exemptions, PandiO/knk-workspace#298)
**Checked against:** knk-plugin `main` `57884e9`, knk-web-api `master` `75b5a00`, knk-web-app `main` `3ba747d` (desk check); `next` only for what § 7 names
**Related:** [player guide](../users/navigation-and-teleports-player-guide.md) (what players see; not repeated here), [commands](../users/commands.md) (§ Teleporting players, `/knk road`), [plugin configuration](plugin-configuration.md) § 4.10 `teleport` and § 4.15 `navigation`, [Game Settings](../game-settings.md), [staff web app guide § 9](staff-web-app-guide.md#9-settings-pages), [road navigation design](../../specs/navigation/DESIGN.md) § 5 and § 7, [teleport design](../../specs/teleport/DESIGN.md)

For staff who set up the road network that `/navigate` uses, open places as teleport destinations, set spawn and
teleport prices, and move players.

## 1. Permissions and prerequisites

| Node | Gives | Rank on the seed data |
|---|---|---|
| `knk.admin.road` | `/knk road …` in game and the web app's **Road network** page | Staff |
| `knk.navigate` | `/navigate` (default on for everyone; see PandiO/knk-workspace#311: it can't be taken away from a rank yet) | Everyone |
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

## 3. Teleports

### 3.1 Spawn and hub

`/spawn` and the join teleport go to the **Join Spawn** of the Game Settings page (a Location, or a town, district or
structure's spawn), else the main world's spawn. A permission group can have its own spawn there. `/hub` goes to the
hub spawn of the Hub card; without a usable hub it refuses. See [Game Settings](../game-settings.md); changes reach the
game within 30 seconds, or at once with `/knk cache refresh`.

### 3.2 Warps (teleport destinations)

Any Town, District or Structure can be a destination. On its form in the web app (dashboard → the record → Edit), the
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
3. **Entrances** as a destination mode (PandiO/knk-workspace#110), sub-regions in routes (#140), a negative cache for
   regions without a domain (#317), player homes (decision #447).

## Sources

1. Code: knk-plugin `roads/RoadAdminCommand`, `navigation/`, `teleport/TeleportExemptions`, `commands/`,
   `plugin.yml`, `config.yml`; knk-web-api `Models/Domain.cs`, `Models/PermissionGroup.cs`,
   `Services/TeleportGroupPolicy.cs`; knk-web-app `pages/admin/RoadsAdminPage.tsx`, `components/admin/roads/`.
2. [Road navigation design](../../specs/navigation/DESIGN.md) (§ 5, § 6.7, § 7) and
   [plan](../../specs/navigation/IMPLEMENTATION_PLAN.md); [teleport design](../../specs/teleport/DESIGN.md) and
   [plan](../../specs/teleport/IMPLEMENTATION_PLAN.md).
3. [Road navigation smoke test](../road-navigation-smoke-test.md); the Road network page notes of the #337–#345 docs
   session (comment on PandiO/knk-workspace#298).
