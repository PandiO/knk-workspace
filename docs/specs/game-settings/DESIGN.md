# Game Settings — Design

**Status:** Implemented on branch `claude/kng-52-game-settings` (knk-plugin, knk-web-api); the web-app page and API have been on trunk since 2026-08-21. Not merged, not live-tested. Decisions D1–D3 need the developer's review.
**Last updated:** 2026-10-05
**Linear:** [KNG-52](https://linear.app/kngpandi/issue/KNG-52)
**Sources:** knk-web-api `master` `099f936` (`Controllers/GameSettingsController.cs`, `Services/GameSettingsService.cs`, `Dtos/GameSettingsDtos.cs`, `Models/GameSettings.cs`, commit `285baf3` of 2026-08-19); knk-web-app `main` `3953658` (`src/pages/admin/GameSettingsPage.tsx`, commits `f3206c5`/`21e84c9` of 2026-08-21); knk-plugin `main` `5c85a3d` and the shelved stash `19-08-26: Workable: GameSettings feature` (base `961597e`); [vision §2.7](../../vision/vision.md#27-game-world-settings); [teleport DESIGN §3.6](../teleport/DESIGN.md) (`/spawn`).
**Plan and status:** [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md). **Admin how-to:** [guides/game-settings.md](../../guides/game-settings.md).

Game Settings are the server-wide rules an admin sets on the web app instead of in config files or code: what the
server says when someone joins or leaves, where players arrive and respawn, and each world's game mode, time,
weather and spawn point. This is the vision's §2.7 "game world settings" direction. It replaces hard-coded
defaults such as "teleport every joining player to world 0's spawn" and "respawn everyone in town 4".

---

## 1. Components

| Part | Where | What it does |
|---|---|---|
| Admin page | knk-web-app `/admin/game-settings` (`GameSettingsPage.tsx`, staff only) | Edits the settings and shows the worlds the plugin reported. The same page also hosts the Data Retention card (private messages, KNG-18), which is a separate API resource. |
| Storage + API | knk-web-api `GameSettings` (one row, `Id = "global"`; nested parts stored as JSON columns) | `GET /api/GameSettings` (open), `PUT /api/GameSettings` (edit), `PUT /api/GameSettings/runtime-worlds` (plugin report). The first GET creates the row with defaults. |
| Applying it | knk-plugin `paper/settings/GameSettingsManager` (+ `core/settings/*` rules, `listeners/GameSettingsWorldListener`, `listeners/PlayerListener`) | Reads the settings in the background, applies them on the main thread, reports loaded worlds. |
| `/spawn` | knk-plugin `teleport/SpawnDestinationResolver` (KNG-17) | The join teleport and every other settings reference resolve through the same resolver. |

### 1.1 Data model (API `GameSettingsReadDto`)

| Field | Meaning | Edited on the page |
|---|---|---|
| `joinAnnouncement`, `leaveAnnouncement` | `&`-coded text; `{player}` = player name | yes |
| `joinSpawnMode` | `WorldSpawn` or `CustomReference` | yes |
| `joinSpawnReference` | a `LocationReference` (below) | yes, in `CustomReference` mode |
| `defaultRespawnPolicy` | respawn policy for a world without its own block | **no** (API default only; see §8) |
| `worldSettings[]` | one block per world: `worldName`, `defaultGameMode`, `lockTime`, `lockedTime`, `weather`, `worldSpawnReference`, `respawnPolicy` | yes |
| `runtimeWorlds[]`, `runtimeWorldsLastUpdatedAt` | the loaded worlds, as last reported by the plugin | read-only list |
| `updatedAt` | last change to the settings (since KNG-52 a plugin report alone no longer moves it) | shown |

A **LocationReference** is `{sourceType: Location|Town|District|Structure, sourceId, displayLabel, location}`, where
`location` is a snapshot of the coordinates when the admin picked it. A **respawn policy** is
`{mode: WorldSpawn|ConfiguredReference|NearestTown, locationReference, maxNearestTownDistance, useWorldSpawnFallback}`.
**Weather** is `{mode: Normal|Constant|Blocked|Weighted, forcedWeather, blockedWeatherTypes[], clearWeight, rainWeight, thunderWeight}`.

---

## 2. Reading and refreshing

- The plugin reads `GET /api/GameSettings` at startup and every `game-settings.refresh-interval-seconds` (default 30 s).
  An admin's change therefore reaches the server within about 30 seconds. `/knk cache refresh` reads it at once.
- Every player-facing decision (join, respawn, weather events) reads values that were fetched and resolved
  beforehand. **No event waits on the API.** If the API is down, the last known settings stay in force.
- References (a town's spawn can move) and the town list for nearest-town respawn are re-read every 5 minutes,
  and immediately when the settings change.

---

## 3. Behavior

### 3.1 Join and leave announcements

The join and quit broadcasts use the configured text with `{player}` filled in and `&` colour codes applied.
A **blank** text means *no broadcast*. Until the settings have been read once (no cache file, API down) the API's
own defaults are used: `&a{player} joined the server.` / `&e{player} left the server.`. A vanished staff member
still joins and leaves silently (`ModeListener`, HIGHEST priority, clears the message). The personal welcome-back
message is unchanged (`UserAccountListener`).

### 3.2 Join spawn, and how references resolve

Players without `knk.mode.owner` are teleported on join to the **server spawn** — the same destination as
`/spawn` ([teleport §3.6](../teleport/DESIGN.md)):

- `joinSpawnMode = CustomReference` → the reference's current location: a Location by id, or the Town/District/
  Structure's own Location. If the lookup fails, the snapshot saved with the reference is used. If there is no
  snapshot, the main world's spawn is used.
- `WorldSpawn` → the main world's spawn point. This is the first world. Its spawn point can itself be set per world (§3.6).

The destination is resolved in the background and cached (5 minutes, dropped on change and by `/knk cache refresh`).
If a player joins in the first seconds after a restart, before it resolves, they go to the reference's snapshot
or the main world's spawn instead. Every other reference (world spawns, respawn spots) resolves the same way
through `SpawnPointResolver.resolveReference`.

### 3.3 Respawn

On a **death** respawn of a player without `knk.mode.owner`/`knk.mode.staff`, the plugin applies the respawn policy
of the world they **died in**. That is the world's own block, else `defaultRespawnPolicy`.

| Mode | Where the player respawns |
|---|---|
| `WorldSpawn` | Not overridden: the server decides (bed or respawn anchor, else the world's spawn). **D1** |
| `ConfiguredReference` | The reference's resolved location (§3.2) |
| `NearestTown` | A town in the death world. If the player died inside a town's WorldGuard region, that town is used, even beyond the maximum distance. Otherwise the town whose spawn is horizontally nearest, within `maxNearestTownDistance` (empty or 0 = any distance). Towns without a spawn Location are skipped. |

When `ConfiguredReference` or `NearestTown` finds nothing: if `useWorldSpawnFallback` is on, the player respawns at
the death world's spawn. If it is off, the server decides as in `WorldSpawn`.

The following keep their existing behavior:
- Respawns that are not deaths (leaving the End) are never touched.
- Staff and owner-mode players respawn normally.
- Siege match members are placed by `SiegeDeathRespawnListener`, which runs later at HIGHEST and wins.

**D2:** this replaces trunk's hard-coded "respawn regular players at town 4". To keep that behavior, set the main
world's respawn policy to `ConfiguredReference` → Town #4 (see the plan's developer to-do).

### 3.4 Default game mode

On join, a regular player is put in the **destination world's** `defaultGameMode` (SURVIVAL when unset or unknown),
then the account-loading hold (`JoinLoadingGuard`) puts them in ADVENTURE. When the account has loaded, the hold
hands back that same world default; before KNG-52 it always handed back SURVIVAL. Owner-mode players are untouched.
**D3:** the mode is applied on join only, not when a player changes world (siege and staff modes set their own modes).

### 3.5 Weather

Per world. The rule steers only the server's own changes: the natural weather cycle and sleeping through a storm.
A staff `/weather` and other plugins pass. `Constant` and `Blocked` then restore the rule at the next refresh
(within 30 s).

| Mode | Behavior |
|---|---|
| `Normal` | Vanilla. |
| `Constant` | Natural or sleep changes away from `forcedWeather` (no value = clear) are cancelled. At each refresh the world is switched to it if needed. |
| `Blocked` | Natural or sleep changes *into* a blocked kind are cancelled. At each refresh a world in a blocked kind is switched to the first allowed one (clear → rain → thunder). Blocking all three kinds is ignored. |
| `Weighted` | Each natural rain start or stop is cancelled. On the next tick a new weather is picked by `clear/rain/thunderWeight`, with a vanilla-like duration. The separate natural thunder toggles are cancelled, so only the picks set thunder. Sleeping can still clear a storm. All weights 0 = vanilla. A weather with weight 0 is switched away from at refresh. |

Clear/rain/thunder are judged from the world's storm and thunder flags. A thunder flag without rain counts as clear,
because nothing is visible.

### 3.6 Per-world time lock and spawn point; the loaded-worlds report

- **Time lock:** `lockTime` stops the day/night cycle (`doDaylightCycle=false`) and holds the time at `lockedTime`
  (ticks 0–23999; 6000 = noon, 18000 = midnight). Each refresh corrects a time changed by `/time`. The world
  remembers in its persistent data that the plugin locked it. Unlocking, even after a restart, turns the cycle
  back on. A world whose cycle an admin stopped by hand with `/gamerule` is never switched back on.
- **World spawn point:** `worldSpawnReference` moves the world's own spawn point there. That affects compasses,
  new players, the server-decided respawn and the main world's role as join spawn. A reference in another world
  is ignored, with one warning.
- **Loaded-worlds report:** every `runtime-sync-interval-seconds` (default 30 s), and on world load or unload, the
  plugin compares its loaded worlds (name, folder, environment, player count, primary flag) with its last
  report. It sends `PUT /api/GameSettings/runtime-worlds` only when something changed, or every 10 minutes. The
  API adds a default block for a world it has not seen yet, so the page shows a block for every world.

### 3.7 Offline copy

Each time the settings change, the plugin writes them to `plugins/KnightsAndKings/game-settings-cache.json` and
starts with that copy when the API is unreachable at boot. The version being replaced is kept in
`game-settings-backups/` (newest `backup-history-limit`, default 48). That folder is a local trail of what was
changed on the page. It is not a backup of the database.

---

## 4. Configuration (`config.yml`)

```yaml
game-settings:
  refresh-interval-seconds: 30        # min 5
  runtime-sync-interval-seconds: 30   # min 5; reports only on change (or every 10 min)
  backup-history-limit: 48            # 0 = keep no history
```

The block is optional; an older config.yml gets these defaults. The report needs the plugin API key
(`api.auth.type: apikey`, `Security:PluginApiKey` on the API), like every other plugin write.

## 5. API contract and permissions

| Endpoint | Caller | Auth (since KNG-52) |
|---|---|---|
| `GET /api/GameSettings` | web app, plugin | open, like the other configuration singletons |
| `PUT /api/GameSettings` | web app (Save Settings) | `RequireServiceOrPermission(knk.admin.config)`: plugin key or a web user holding `knk.admin.config` |
| `PUT /api/GameSettings/runtime-worlds` | plugin | same |

Before KNG-52 both writes were anonymous. A staff web user without `knk.admin.config` now gets 403 on Save. The
Data Retention card on the same page already needed that node.

## 6. Interactions with other features

| Feature | Interaction |
|---|---|
| Teleport `/spawn` (KNG-17) | Same destination and resolver as the join teleport. |
| Join-loading hold (`JoinLoadingGuard`) | Hands back the world's default game mode instead of SURVIVAL. |
| Vanish / staff modes (`ModeListener`) | Vanished joins/quits stay silent; staff/owner skip the join teleport (owner) and the respawn override (both). |
| Siege | `SiegeDeathRespawnListener` (HIGHEST) overrides the respawn for match members. A rejoining member is restored by `SiegeSessionListener` one tick after the join teleport. |
| Managed WorldGuard regions | Nearest-town respawn reads the towns' own regions (`Town.WgRegionId`) for "died inside a town". |
| Kits (first-join kit), salary, discovery | Unchanged; they run on join independently. |

---

## 7. Decisions (2026-10-05, Claude Code session — reversible; D1–D3 need review)

| # | Decision | Why |
|---|---|---|
| D1 **review** | `WorldSpawn` respawn mode means "the server decides" (bed/anchor respected), not "force the world spawn". | The page calls it world spawn, and vanilla already falls back to the world spawn. Forcing it would silently disable beds and anchors. The stash forced it. |
| D2 **review** | The hard-coded town-4 respawn is removed; the same behavior is a setting (`ConfiguredReference` → Town #4). | The settings feature exists to replace such defaults (vision §2.7). Until configured, regular players respawn like staff do. |
| D3 **review** | Default game mode on join (and after the loading hold) only, not on world change. | A world-change rule would fight siege (SURVIVAL on entry) and staff modes. Easy to add once those are mapped. |
| D4 | Weather rules steer only natural and sleep changes; `Constant`/`Blocked` re-apply at refresh. | Staff can still use `/weather` to test. Avoids fighting other plugins' changes. |
| D5 | `Weighted` re-rolls at each natural rain change, on the next tick. | The stash called `setStorm` inside `WeatherChangeEvent` (re-entrant, and overridden by the event). |
| D6 | Time lock ownership is stored in the world's persistent data. | The stash set `doDaylightCycle=true` on every unlocked world every 30 s, overriding manual gamerules. |
| D7 | Blank announcement = no broadcast; missing = API default. | Lets an admin turn the broadcast off without a separate switch. |
| D8 | Join spawn = `/spawn` destination, resolved in the background. | One source of truth with teleport. Join must not block on HTTP. |
| D9 | Nearest town: death world only, horizontal distance, inside-a-town wins regardless of max distance. | Town spawns sit at very different heights. Dying inside a town should not send you to another one. |
| D10 | World reports only on change or every 10 min, and the API no longer bumps `UpdatedAt` for a report. | 2 DB writes a minute for nothing, and a meaningless "last updated" on the page. |
| D11 | Version history written on change only. The stash's `backup-interval-minutes` is gone. | The stash wrote an identical copy every 5 minutes. |
| D12 | Both API writes require the plugin key or `knk.admin.config`. | They were anonymous. Same policy as the other config singletons. |

## 8. Open questions and follow-ups

1. **`defaultRespawnPolicy` is not editable on the page.** Since the API adds a block for every reported world, it
   is effectively unused. Decide: add a "default" block to the page, or drop the field.
2. **Game mode on world change** (D3), once siege and staff-mode interactions are mapped.
3. **Join hub world:** `JoinLoadingGuard`'s comment anticipates a dedicated join-hub world for this feature. The
   current settings can already express it (a `CustomReference` join spawn in a hub world, plus that world's
   game mode/time/weather). A real hub flow (choose a destination) is not designed.
4. **Placeholders:** only `{player}`. A rank-coloured name (`ChatLineFormat`) would need a second placeholder.
5. **Page hint:** the page doesn't say that a blank announcement disables it.
6. **Concurrent edits:** a plugin report rewrites `WorldSettingsJson` (read-modify-write). An admin save that
   lands between its read and write could be lost. This is rare (reports now only on change), but a row
   version would close it.
7. **Paper 1.21.11+** renames the `doDaylightCycle` game rule. Revisit `applyTime` when the server is upgraded.

## 9. History — the 2026-08-19 stash

The API and web-app halves were merged in August 2026. The plugin half was shelved untested as knk-plugin stash
`19-08-26: Workable: GameSettings feature` (23 files, base `961597e`). By 2026-10-05 it was 317 commits behind
`main` and could not be applied as-is:

- KNG-17 had added a read-only `GameSettingsQueryApi`/`GameSettingsDto`/`KnkGameSettings` for `/spawn`. The stash
  added a second, parallel model with the same DTO class name.
- `PlayerListener`, `KnkConfig`, `KnKPlugin` had changed completely: kits, presence, ranks, `knk.mode.*` gates,
  `JoinLoadingGuard`, siege.
- It had defects: re-entrant weather changes, forced `doDaylightCycle`, an N+1 town fetch every 30 s starting at
  page 0, `OffsetDateTime` parsing of offset-less API timestamps, and a backup copy written every 5 minutes.

KNG-52 kept the stash's scope and settings but re-implemented it on trunk's model, as described above. The stash
itself is left in place; drop it once the branch is merged.
