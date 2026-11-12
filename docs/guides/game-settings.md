# Game Settings — admin guide

**Status:** Current. Describes trunk since the KNG-52 merge of 2026-10-10 (see the [plan](../specs/game-settings/IMPLEMENTATION_PLAN.md)); the page header, units and help (§ Before you start, § Hub) describe knk-web-app `main` `1371951` (merged 2026-11-12, not live-tested).
**Last updated:** 2026-11-12 (settings header with unsaved changes, Discard and Save (n); units and one line of help per field; Hub section; reached through Admin → Settings — #339, #342, #340); 2026-10-26 (route gated on `knk.admin.config`, #185, branch `claude/route-gates-185`, not merged); 2026-10-15 (`game-settings.server-id`, KNG-118, branch `wt/kng-118`, not merged)

The Game Settings page sets server-wide rules for joining, respawning, each world's game mode, time,
weather and spawn point, and the server-list MOTD. It also sets exceptions per permission group. The plugin picks up a saved change within about 30 seconds. To apply it at once, run
`/knk cache refresh` in game. The full rules are in [the design](../specs/game-settings/DESIGN.md).

## Before you start

- Open the web app → **Admin** → **Settings** → **Game settings** (`/admin/game-settings`; on a wide screen also in the
  admin sidebar). You need a staff account whose group holds `knk.admin.config` (or `knk.admin.*` / `*`); without it
  the page isn't listed and its address says "Staff only" (#185). See the
  [staff web app guide](admin/staff-web-app-guide.md) for the admin pages in general.
- The page lists the **Minecraft worlds** the server reported. A world appears there, with a settings block, once
  the plugin has reported it. That takes up to 30 s after the server or a world starts.
- The **header** stays at the top while you scroll: "Last saved …" (when), "n unsaved changes", **Reload**,
  **Discard** and **Save (n)**. Sections and worlds you changed are marked *Changed*. **Save (n)** stores everything on
  the page at once; a success message appears at the bottom, a refusal stays in the header with your changes kept.
  **Discard** goes back to the saved values and **Reload** reads them again from the server; both ask first when you
  have changes. Leaving the page with unsaved changes asks "Leave without saving?" (**Stay** keeps them); closing
  or reloading the tab gets the browser's question. The data-retention card still saves on its own.
- Every field has one line of help and, where it has one, its **unit** next to the input, with what the typed value
  means: **Locked Time** in ticks shows the clock time (6000 "= 12:00 (noon)"), the hub's intervals in ticks show
  seconds (20 ticks "1 s").

## Settings and what players see

| Setting | In game |
|---|---|
| **Join / Leave Announcement** | The line everyone sees when a player joins or leaves. `{player}` is replaced by the name, `{group}` by the player's group and `{title}` (or `{titlename}`) by their title, e.g. `- {group} {title} {player} joined the server.`; an empty group or title leaves no double space. `&` colour codes work, several per line, for example `&6{player} &7has arrived`. Hex colours are written `&x&f&f&a&a&0&0`. Leave it **empty** for no message. Staff who are vanished never trigger it. |
| **Server List MOTD** | The two lines under the server's name in the Minecraft server list. Same colour codes; `{online}` and `{max}` show the player counts. Empty = the server's own motd. |
| **Join Spawn** | Where regular players arrive on join, also the `/spawn` destination. *The main world's spawn* = that world's spawn point. *A chosen spot (Location, Town, District or Structure)* = a Location, or a Town/District/Structure's own spawn Location. If that thing is moved later, the new spot is used. |
| **Default GameMode** (per world) | The mode a regular player has after joining into this world. Players with owner mode keep their own. |
| **Keep fixed world time / Locked Time** (per world) | Stops day and night at the given tick: 0 = sunrise, 6000 = noon, 12000 = sunset, 18000 = midnight; the help line under the field shows the clock time of the value you typed. `/time set` is undone within 30 s. Unticking it starts the cycle again. |
| **Weather Behavior** (per world) | *Normal* = vanilla. *Constant* = always the forced weather; sleeping won't clear it. *Blocked* = the ticked kinds never start by themselves. *Weighted* = whenever the weather would change by itself, clear/rain/thunder is picked by the weights. A staff `/weather` first asks for confirmation (it names the rule and says whether it will be undone); click **[Change anyway]** or type it again within 15 s. *Constant* and *Blocked* restore the rule within 30 s. |
| **World Spawn Reference** (per world) | Moves the world's own spawn point. That spot is used by new players, compasses and the default respawn. |
| **Respawn** (per world, for deaths in that world) | *Same as the join spawn (synced)* = where the player would join and where `/spawn` takes them. *World spawn (beds and anchors ignored)* = always the world spawn (the main world's for a nether or End death). *Server decides (bed / anchor, else world spawn)* = not redirected, like staff and owners. *A chosen spot (separate)* = always that spot. *Nearest town* = the town the player died in, else the nearest town in that world. *Max nearest-town distance* limits how far the town may be (empty = any). **If no spot is found**: use the world spawn (ticked) or let the server decide (unticked). A group can replace this per group (below). Staff, owner-mode players and siege matches are not affected. |

## Hub

The **Hub** card sets an optional hub: with a hub selected, every joining player arrives at the hub spawn, also while
the API is down, and the hub's rules apply inside its region. Without a hub, players join as before.

- **Hub-eligible domains:** only a flagged town, district or structure can be the hub (**Flag as hub**). A flagged
  domain may not contain or sit inside another flagged one. Flags are saved at once, not with Save (n). To remove the
  selected hub's flag, first pick another hub (or **No hub**) and save.
- **Selected hub**, **Hub spawn** (must be in the hub's world, or saving is refused) and **Portal regions**
  (WorldGuard region ids in the hub's world, comma-separated; walking into one takes the player to their group's join
  spawn, else the default join spawn, only while the API is up).
- **When the API is lost:** *Send to the hub* (default), *Do nothing*, *Kick*, or *Send to the spawn of the world they
  are in*, after **Delay (seconds)** counted from the first failed health check. The server confirms an outage only
  after a few failed checks (about 20–30 s), so even 0 acts only then. Staff and owner-mode players are never moved.
- **Rules inside the hub:** ticks for damage, building, items, doors, NPCs, storage and item frames; players always
  keep their own inventory. **Healing**, **Feeding** and **Saturation** are an amount every *n* **ticks**, with the
  interval in seconds next to it (20 ticks = 1 s). The defaults match vanilla Peaceful (1 health and 1 saturation every
  20 ticks, 1 food every 10 ticks); 0 turns one off, and they are skipped in a world that is already Peaceful.

## Picking a spawn point

Every spawn or respawn field shows the chosen spot as a card: its type, name, parent (e.g. *Cinix › Residential
District*) and coordinates. Click the card, **Change** or **Choose a spawn point** to open the list; × clears it.
The list opens with every Town, District, Structure and Location, grouped by type. You can pick a Location, or the
default spawn point of a Town, District or Structure. Search by:
- **id**: `12` or `#12`;
- **name**;
- **parent**: a district's town, or a structure's district and town. For example, `kardenna` finds Kardenna and
  every district and structure in it.

Every word must match, so `docks lounge` narrows it down. The chips **All / Towns / Districts / Structures /
Locations** limit the list to one kind. Arrow keys and Enter work too; Escape closes the list. **+ New Location…** at
the bottom opens the Form Wizard. If a chosen spot was deleted, the card warns that its saved coordinates are used.

## Permission group overrides

The **Permission Group Overrides** card gives a group its own:
- **join message** and **leave message** (`{group}` shows the group's name, `{title}` the player's title; empty = its members join or leave silently);
- **spawn**: a chosen spot, which also changes where `/spawn` takes them, or **where they logged out** (no join teleport, like owners; `/spawn` still goes to the server spawn);
- **respawn**, in every world, replacing the world's setting.

Add a group, then tick only what it should change; everything else stays as set above.

A player in several groups gets each setting from the first group in the card's list that sets it. The card shows
that order (#1, #2, ...):
1. The group with the higher **Weight** comes first, followed by the groups it inherits from. This is the same
   order as teleport fees and cooldowns, so a player's spawn and their `/spawn` price come from the same group.
2. So a child group (Admin) only wins over its parent (Staff) when its Weight is higher.

Staff and owner-mode players are never redirected on respawn, and owner-mode players are not moved on join.

## Recommended starting setup

Before Game Settings, every regular player respawned in **town 4**. To keep that, set the main world's
respawn to *A chosen spot* → Town 4. *Nearest town* is the more legacy-like alternative.

## Checking it worked

- Server log: `[KnK GameSettings] Applied game settings (last edit …)` after each change. Warnings start with the
  same prefix. Examples: the API can't be reached, or a world spawn reference points into another world.
- If the API is down, the server keeps the last settings it had. That includes across a restart, from
  `plugins/KnightsAndKings/game-settings-cache.json`. Earlier versions are kept in `game-settings-backups/`.

## Server config (`config.yml`)

`game-settings.refresh-interval-seconds` (default 30), `runtime-sync-interval-seconds` (30) and
`backup-history-limit` (48). These only tune how the plugin follows the page; the rules themselves are set on
the web app.

`game-settings.server-id` (default `default`, KNG-118) names this game server in its loaded-worlds report. Each server's
report replaces only its own worlds, so give every game server that shares one API its own id. A server that stops
reporting drops off the list 30 minutes after its last report. See
[multiworld follow-ups §2](../architecture/multiworld-follow-ups.md#2-runtime-worlds-per-game-server-a9).
