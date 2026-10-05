# Game Settings — admin guide

**Status:** Draft. It describes branch `claude/kng-52-game-settings`, which is not merged or live-tested (see the [plan](../specs/game-settings/IMPLEMENTATION_PLAN.md)).
**Last updated:** 2026-10-05

The Game Settings page sets server-wide rules for joining, respawning and each world's game mode, time,
weather and spawn point. The plugin picks up a saved change within about 30 seconds. To apply it at once, run
`/knk cache refresh` in game. The full rules are in [the design](../specs/game-settings/DESIGN.md).

## Before you start

- Open the web app → **Game Settings** (`/admin/game-settings`). You need a staff account whose group holds
  `knk.admin.config`; without it, Save fails with an error.
- The page lists the **Minecraft worlds** the server reported. A world appears there, with a settings block, once
  the plugin has reported it. That takes up to 30 s after the server or a world starts.
- **Save Settings** stores everything on the page at once. **Reload** discards unsaved edits.

## Settings and what players see

| Setting | In game |
|---|---|
| **Join / Leave Announcement** | The line everyone sees when a player joins or leaves. `{player}` is replaced by the name. `&` colour codes work, for example `&6{player} has arrived`. Leave it **empty** for no message. Staff who are vanished never trigger it. |
| **Join Spawn** | Where regular players arrive on join, also the `/spawn` destination. *World Spawn* = the main world's spawn point. *Custom Reference* = a Location, or a Town/District/Structure's own spawn Location. If that thing is moved later, the new spot is used. |
| **Default GameMode** (per world) | The mode a regular player has after joining into this world. Players with owner mode keep their own. |
| **Lock Time / Locked Time** (per world) | Stops day and night at the given tick: 0 = sunrise, 6000 = noon, 12000 = sunset, 18000 = midnight. `/time set` is undone within 30 s. Unticking it starts the cycle again. |
| **Weather Behavior** (per world) | *Normal* = vanilla. *Constant* = always the forced weather; sleeping won't clear it. *Blocked* = the ticked kinds never start by themselves. *Weighted* = whenever the weather would change by itself, clear/rain/thunder is picked by the weights. A staff `/weather` still works for testing; *Constant* and *Blocked* restore the rule within 30 s. |
| **World Spawn Reference** (per world) | Moves the world's own spawn point. That spot is used by new players, compasses and the default respawn. |
| **Respawn Policy** (per world, for deaths in that world) | *World Spawn* = the server decides: bed or respawn anchor, else the world spawn. *Configured Reference* = always the chosen spot. *Nearest Town* = the town the player died in, else the nearest town in that world. *Max Nearest-Town Distance* limits how far the town may be (empty = any). **Fallback To World Spawn**: if no spot is found, use the world spawn (ticked) or let the server decide (unticked). Staff, owner-mode players and siege matches are not affected. |

## Recommended starting setup

Before Game Settings, every regular player respawned in **town 4**. To keep that, set the main world's Respawn
Policy to *Configured Reference* → Town 4. *Nearest Town* is the more legacy-like alternative.

## Checking it worked

- Server log: `[KnK GameSettings] Applied game settings (last edit …)` after each change. Warnings start with the
  same prefix. Examples: the API can't be reached, or a world spawn reference points into another world.
- If the API is down, the server keeps the last settings it had. That includes across a restart, from
  `plugins/KnightsAndKings/game-settings-cache.json`. Earlier versions are kept in `game-settings-backups/`.

## Server config (`config.yml`)

`game-settings.refresh-interval-seconds` (default 30), `runtime-sync-interval-seconds` (30) and
`backup-history-limit` (48). These only tune how the plugin follows the page; the rules themselves are set on
the web app.
