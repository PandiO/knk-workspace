# Game Settings — Implementation Plan

**Status:** **Code-complete on branch, not merged, not live-tested** (2026-10-05, two rounds). knk-plugin `claude/kng-52-game-settings` `52ff497`; knk-web-api `claude/kng-52-game-settings` `e97125b` (new migration **not applied**); knk-web-app `claude/kng-52-game-settings` `055ac28`. Next: the developer applies the migration and runs the live smoke test (§4), then merge.
**Last updated:** 2026-10-05
**Linear:** [KNG-52](https://linear.app/kngpandi/issue/KNG-52)
**Sources:** [DESIGN.md](DESIGN.md) (behavior, decisions D1–D17, open questions); stash `19-08-26: Workable: GameSettings feature` in knk-plugin.

**Branches:** one branch per repo, `claude/kng-52-game-settings`. knk-plugin is based on `main` `5c85a3d`,
knk-web-api on `master` `099f936` and knk-web-app on `main` `3953658`. All are local only: not pushed, no PR.
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

### Round 2 (2026-10-05): group overrides, synced respawn, spawn picker, MOTD

These were requested by the developer the same day. The three decisions are in DESIGN D13–D15.

**knk-web-api `e97125b`:**
- `GameSettings.Motd` and `GroupOverridesJson`, with migration `20261005132808_AddGameSettingsMotdAndGroupOverrides`
  (2 columns, **not applied**).
- `PermissionGroupGameSettingsDto`, and `Services/PermissionGroupPrecedence.cs` (hierarchy, then weight, then id).
- Overrides are enriched and sorted on read, and validated on update. Omitting `motd`/`groupOverrides` keeps them.
- Respawn modes are validated, including the new `JoinSpawn`.
- `UserDto`/`UserSummaryDto.permissionGroups`: effective groups in precedence order, filled in
  `UserService.MapToUserDtoAsync` and by both user-summary endpoints.
- `GameSettingsServiceTests` grew to 14 tests.

**knk-plugin `52ff497`:**
- `UserSummary.permissionGroups` (`PermissionGroupRef`); the `with*` copies keep it.
- `KnkGameSettings.motd` and `groupOverrides` (`KnkGroupOverride`).
- `core/settings/GroupOverrides`; `Announcements` gains `{group}` and `renderMotd`.
- `RespawnPlanner` gains the `JOIN_SPAWN` plan.
- `GameSettingsManager`: group-aware join message, join spawn and respawn, the MOTD, and resolution of group
  references.
- `SpawnCommand.setPlayerSpawn` (a group's spawn for `/spawn`) and a new `GameSettingsMotdListener`.

**knk-web-app `055ac28`:**
- New `components/admin/gameSettings/`:
  - `GroupOverridesCard` (live precedence order);
  - `LocationReferencePicker` with `locationReferenceOptions` (search by id, name, parent domain);
  - `RespawnPolicyEditor` ("Same as the join spawn (synced)");
  - `MinecraftLegacyPreview` (moved, plus hex).
- `GameSettingsPage` uses them and adds the MOTD card.
- New jest test `gameSettingsComponents.test.tsx` (7 tests).

## 2. Tests run (2026-10-05, Windows dev machine)

| Suite | Result |
|---|---|
| Round 1: knk-web-api `dotnet test --filter GameSettings` | 6 passed |
| Round 2: knk-plugin `build -x deployToDevServer` | BUILD SUCCESSFUL. core 1232, api-client 151 (2 skipped), paper 1028 (14 skipped), no failures. New: `GroupOverridesTest`, a `JOIN_SPAWN` planner case, MOTD/group parsing, 2 `SpawnCommandTest` cases. |
| Round 2: knk-web-api `--filter GameSettings\|UserService\|UsersController` | 135 passed. `dotnet ef migrations add` produced only the 2 columns, so the snapshot has no unrelated drift. |
| Round 2: knk-web-app jest | New suite 7/7. Full run: 443 passed, 5 failed in 4 suites (`useEnrichedFormContext`, `FormWizard.m2mJoinPrefill`, `FormWizard.siegeGatesJoin`, `ManyToManyRelationshipEditor`). The same 4 suites fail on untouched `main` `3953658`. `tsc --noEmit`: only the pre-existing `src/utils/lootbox.ts` Set-iteration error. |
| knk-web-api full suite (round 1) | 1629 passed, 48 skipped, 8 failed. The same 8 fail on untouched `master` `099f936`: `ClientActivityStoreTests`, `TransferPolicyEvaluatorTests.DailySendCap…`, `FieldValidationServiceTests.ValidateConditionalRequired…`, `CurrencyWriteGuardTests`, 2× `CurrencyAnomalyDetectorTests`, 2× `PathResolutionServiceTests` (the earlier "5 known failures" baseline has grown) |
| Round 1: knk-plugin `./gradlew build --offline -x deployToDevServer` | BUILD SUCCESSFUL. knk-core 1223 tests, 0 failures. knk-api-client 149 (2 skipped). knk-paper 1026 (14 skipped). The skip counts match trunk. |
| Round 1: new plugin tests | `WeatherRulesTest`, `RespawnPlannerTest`, `GameSettingsModelTest`, 2 new `SpawnPointResolverTest` cases, `GameSettingsCommandApiImplTest` (full read + PUT body/auth/401), `GameSettingsStoreTest` (Gson round trip, history limit, broken file, config clamps), `GameSettingsWorldListenerTest`, 2 new `JoinLoadingGuardTest` cases |

Nothing was deployed or tried in game. The
Bukkit-side `GameSettingsManager` (world writes, scheduler, WorldGuard containment) has no unit tests. It is
covered by the live checklist below.

## 3. Developer to-do before the smoke test

0. **Database (round 2):** the API branch adds migration `AddGameSettingsMotdAndGroupOverrides`, which adds 2 columns
   to `game_settings`. Apply it to the dev DB with `dotnet ef database update` from the branch, after a backup.
   Until it's applied, the branch's API fails on any Game Settings call.
1. **API:** run the `claude/kng-52-game-settings` API build. The plugin must send its key:
   the dev `Security:PluginApiKey` must be set and the plugin's `api.auth.type: apikey`, unless
   `Security:AllowUnauthenticatedPluginCalls` is on in Development.
2. **Web user:** Save on the Game Settings page now needs `knk.admin.config`. Check that your account's group holds it; the Data Retention card on the same page already needs it.
3. **Keep the old respawn (D2):** before or right after deploying, set the main world's respawn policy to
   *A chosen spot (separate) → Town #4* (or *Nearest town*). Until then, regular players respawn at their bed or the
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
5. **Respawn:** *A chosen spot → Town #4*: die → respawn at town 4. *Nearest town*: die near and inside
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

**Round 2:**

11. **Group join message:**
    - Add an override for the test account's rank group with own join message `&6[{group}] &e{player}`.
      Rejoin: that message is used, with the group name.
    - Give a higher-weight unrelated group a different message: the deeper or heavier group's message wins
      (DESIGN §3.8).
    - An empty group message: that player joins silently.
12. **Group spawn:** give the group *Own spawn* → a Structure, found by searching its town's name in the picker.
    Rejoin and `/spawn`: you go to the structure's spawn. A player without the group still goes to the server spawn.
13. **Synced respawn:**
    - Set the main world's respawn to *Same as the join spawn*: die and respawn where you join, including the group
      spawn.
    - Give a group *Own respawn → Nearest town*: its members respawn at the nearest town in every world.
14. **MOTD:** set `&6Knights and Kings` / `&e{online}/{max} online`. The server list shows two coloured lines with
    the counts. Empty it: the server.properties motd is back.
15. **API:** saving an override for a deleted group returns 400. A three-line MOTD returns 400.
    `GET /api/Users/uuid/{uuid}` lists `permissionGroups` in the expected order.

Record results under a "Smoke test" heading here and in KNG-52.

## 5. Merge

After the smoke test, merge `claude/kng-52-game-settings` in this order:
1. knk-web-api `master`, with the migration applied wherever that API runs. The web page and the plugin need its
   new fields and auth.
2. knk-web-app `main`.
3. knk-plugin `main`.

If the navigation branch's API merges first, regenerate or hand-merge `KnKDbContextModelSnapshot.cs` (DESIGN §8). Then:
- update the [feature register](../../FEATURE_REGISTER.md) row (Merge `trunk`, Verification) and add a
  [CHANGELOG](../../CHANGELOG.md) entry, including the town-4 respawn note;
- drop the knk-plugin stash `19-08-26: Workable: GameSettings feature`;
- move the ACTIVE_SESSIONS row to Recently completed;
- close KNG-52 or file the DESIGN §8 follow-ups.
