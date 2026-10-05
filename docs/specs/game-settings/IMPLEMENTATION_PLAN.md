# Game Settings — Implementation Plan

**Status:** **Code-complete on branch, not merged, not live-tested** (2026-10-05). knk-plugin `claude/kng-52-game-settings` `e55a077`; knk-web-api `claude/kng-52-game-settings` `c8f7f01`; knk-web-app: no change (page on trunk since 2026-08-21). Next: the developer's live smoke test (§4), then merge.
**Last updated:** 2026-10-05
**Linear:** [KNG-52](https://linear.app/kngpandi/issue/KNG-52)
**Sources:** [DESIGN.md](DESIGN.md) (behavior, decisions D1–D12, open questions); stash `19-08-26: Workable: GameSettings feature` in knk-plugin.

**Branches:** one branch per repo, `claude/kng-52-game-settings`. knk-plugin is based on `main` `5c85a3d` and
knk-web-api on `master` `099f936`. Both are local only: not pushed, no PR.
**Build notes:** use `./gradlew build --offline -x deployToDevServer` in knk-plugin, because a plain `build`
deploys to the dev server. knk-web-api tests live in `Tests/knkwebapi_v2.Tests/`. Stage that path with a capital
`T`; git's index spells it that way.

---

## 1. What was built

### knk-web-api (`c8f7f01`)
- `GameSettingsController`: both `PUT`s carry `[RequireServiceOrPermission(StaffPermissions.ServerConfig)]`
  (`knk.admin.config`). `GET` stays open.
- `GameSettingsService.UpdateRuntimeWorldsAsync` moves `UpdatedAt` only when a new world block was added.
  `GameSettingsRepository.UpsertAsync` takes `UpdatedAt` from the service instead of always setting now.
- New `Tests/.../Services/GameSettingsServiceTests.cs` (6 tests): default block for a new world, repeated report
  keeps `UpdatedAt`, admin world settings survive a report, both writes need the node, read stays open.
- No migration.

### knk-plugin core + api-client (`7b52750`)
- Domain (`core/domain/settings`): `KnkGameSettings` extended. The 2-argument constructor `/spawn` uses is kept.
  New `KnkWorldSettings`, `KnkWeatherSettings`, `KnkWeather`, `KnkRespawnPolicy`, `KnkWorldRuntime`.
- Port `GameSettingsCommandApi` (`reportRuntimeWorlds`). The api-client implementation is `GameSettingsCommandApiImpl`,
  and `KnkApiClient.getGameSettingsCommandApi()` exposes it.
- `GameSettingsDto` covers the full read, all fields lenient. The new `GameSettingsMapper` is shared by the
  query and command clients.
- Bukkit-free rules in `core/settings`: `Announcements`, `WeatherRules`, `RespawnPlanner`.
- `SpawnPointResolver.resolveReference(...)` is now public (uncached; same fallbacks as `/spawn`).

### knk-plugin paper (`e55a077`)
- `settings/GameSettingsManager`: refresh loop, reference and town resolution, apply time/weather/spawn, the
  loaded-worlds report, and the join, respawn and game-mode answers.
- `settings/GameSettingsStore`: offline cache + change history. `settings/GameSettingsConfig`: the `game-settings:` block.
- `listeners/GameSettingsWorldListener`: weather and thunder events, world load and unload.
- `PlayerListener`:
  - join/quit messages come from the settings;
  - the join teleport goes to the server spawn, in the world's game mode;
  - respawn follows the policy. The `TownsDataAccess` parameter and the town-4 code are gone.
- `JoinLoadingGuard`: optional `Function<Player, GameMode>` for the mode handed back after the hold.
- `SpawnDestinationResolver.resolveReference(...)`. `KnKPlugin.initializeGameSettings()` runs after
  `initializeTeleports()` and before `registerEvents`. It registers the `/knk cache refresh` hook
  "game settings" and stops the manager on disable.
- `config.yml`: `game-settings:` block.

## 2. Tests run (2026-10-05, Windows dev machine)

| Suite | Result |
|---|---|
| knk-web-api `dotnet test --filter GameSettings` | 6 passed |
| knk-plugin `./gradlew build --offline -x deployToDevServer` | BUILD SUCCESSFUL. knk-core 1223 tests, 0 failures. knk-api-client 149 (2 skipped). knk-paper 1026 (14 skipped). The skip counts match trunk. |
| New plugin tests | `WeatherRulesTest`, `RespawnPlannerTest`, `GameSettingsModelTest`, 2 new `SpawnPointResolverTest` cases, `GameSettingsCommandApiImplTest` (full read + PUT body/auth/401), `GameSettingsStoreTest` (Gson round trip, history limit, broken file, config clamps), `GameSettingsWorldListenerTest`, 2 new `JoinLoadingGuardTest` cases |

The full knk-web-api suite was **not** run (filtered run only), and nothing was deployed or tried in game. The
Bukkit-side `GameSettingsManager` (world writes, scheduler, WorldGuard containment) has no unit tests. It is
covered by the live checklist below.

## 3. Developer to-do before the smoke test

1. **API:** run the `claude/kng-52-game-settings` API build. There is no migration. The plugin must send its key:
   the dev `Security:PluginApiKey` must be set and the plugin's `api.auth.type: apikey`, unless
   `Security:AllowUnauthenticatedPluginCalls` is on in Development.
2. **Web user:** Save on the Game Settings page now needs `knk.admin.config`. Check that your account's group holds it; the Data Retention card on the same page already needs it.
3. **Keep the old respawn (D2):** before or right after deploying, set the main world's respawn policy to
   *Configured Reference → Town #4* (or *Nearest Town*). Until then, regular players respawn at their bed or the
   world spawn instead of town 4.
4. **Plugin:** build with `./gradlew :knk-paper:dev` (deploys), or with `build -x deployToDevServer` and copy
   the jar. The `game-settings:` block is optional; defaults apply without it.

## 4. Live smoke test (not done yet)

Use a regular test account (no `knk.mode.owner`/`staff`) unless noted. Wait about 30 s after each Save, or run
`/knk cache refresh`.

1. **Boot:** the log shows `Game settings initialized`, then `[KnK GameSettings] Applied game settings (...)`. The
   Game Settings page lists the loaded worlds with a recent "last updated" for runtime worlds.
2. **Announcements:** change the join text to `&6{player} has arrived`, rejoin: the broadcast uses it. Blank leave
   text → no quit broadcast. A vanished staff member still joins and leaves silently.
3. **Join spawn:** set *Custom Reference → a Town*, rejoin: you arrive at the town's spawn, the same spot `/spawn`
   uses. Switch back to *World Spawn*: you arrive at the main world's spawn.
4. **Game mode:** set the main world's default to ADVENTURE, rejoin: "Loading your account…" then you are left
   in ADVENTURE, not SURVIVAL. Owner-mode account: unchanged.
5. **Respawn:** *Configured Reference → Town #4*: die → respawn at town 4. *Nearest Town*: die near and inside
   another town → respawn there. Set a max distance smaller than the nearest town and fallback off: respawn at
   bed or world spawn. *World Spawn*: a bed is respected. A staff account is never redirected. Leaving the End
   is not redirected. In a siege match the siege spawn still wins.
6. **Time lock:** lock at 6000. The time stops at noon, `/time set night` is corrected within 30 s. Unlock: the
   cycle runs again, also after a restart in between.
7. **Weather:** *Constant RAIN* → rain within 30 s, sleeping doesn't clear it. *Blocked THUNDER* →
   `/weather thunder` works, then reverts within 30 s. *Weighted 0/0/100*: the next natural change turns into
   thunder. A full natural cycle is slow; `/weather clear` followed by waiting is not a natural change.
8. **World spawn:** set a world spawn reference for the main world: a new player and the server-decided
   respawn use it.
9. **API down:** stop the API and restart the server. The log says "Using the cached settings…" and the
   announcements and spawn behave as configured. Start the API: "Game settings read again".
10. **Auth:** with the plugin key removed, the report logs one warning ("Could not report the loaded worlds…").
    An anonymous `PUT /api/GameSettings` returns 401.

Record results under a "Smoke test" heading here and in KNG-52.

## 5. Merge

After the smoke test: merge `claude/kng-52-game-settings` into knk-web-api `master` and knk-plugin `main`.
They can go in either order, but the plugin's world report needs the API's auth to be on, or the dev opt-out
on. Then:
- update the [feature register](../../FEATURE_REGISTER.md) row (Merge `trunk`, Verification) and add a
  [CHANGELOG](../../CHANGELOG.md) entry, including the town-4 respawn note;
- drop the knk-plugin stash `19-08-26: Workable: GameSettings feature`;
- move the ACTIVE_SESSIONS row to Recently completed;
- close KNG-52 or file the DESIGN §8 follow-ups.
