# Game Settings — Implementation Plan

**Status:** **Code-complete, merged with trunk on the branches, pushed; not merged to trunk, not live-tested** (2026-10-09). knk-plugin `claude/kng-52-game-settings` `734eaf50`; knk-web-api `claude/kng-52-game-settings` `8ef1282` (migration **not applied**); knk-web-app: round 2 `055ac28` is already on `main`. Next: the developer applies the migration and runs the live smoke test (§3, §4), then merges API → plugin.
**Last updated:** 2026-10-09
**Linear:** [KNG-52](https://linear.app/kngpandi/issue/KNG-52)
**Sources:** [DESIGN.md](DESIGN.md) (behavior, decisions D1–D17, open questions); stash `19-08-26: Workable: GameSettings feature` in knk-plugin.

**Branches:** one branch per repo, `claude/kng-52-game-settings`, pushed to `origin` on 2026-10-09. knk-plugin has
`main` `68a5310b` merged in (`734eaf50`); knk-web-api has `master` `c397585` merged in (`002edc0`) plus the KNG-80 fix
`8ef1282`. knk-web-app has no branch left to merge: `055ac28` reached `main` through the merge of `d17d7dd`. Until the API
branch ships, the live page sends `motd`/`groupOverrides` to an API that ignores them.
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

### Trunk merge (2026-10-09)

Merge commits, no rebase. Trunk had gained KNG-41/42 (teleport fees, cooldowns, `/back`), KNG-73/92/104 navigation,
KNG-56 domain access, KNG-77/78/79 gates and KNG-80 location retention since the branches were cut.

**knk-plugin `734eaf50`** (`main` `68a5310b`), three conflicts, each resolved by keeping both sides:
- `SpawnCommand`: `/spawn` resolves the player's group spawn (KNG-52) **and** charges the group's `/spawn` fee unless
  the player holds `knk.teleport.bypass.cost` (KNG-41).
- `SpawnDestinationResolver`: `resolveReference` (KNG-52) next to the shared `DomainLocationResolver` (navigation R20).
- `KnkApiClient`: both `GameSettingsCommandApi` and `DomainAccessRulesApi`.
- Merged without conflict: `KnKPlugin` (both `spawnCommand.setCharges` and `setPlayerSpawn` are wired), `config.yml`,
  `PlayerListener` (trunk only dropped `onItemPickup`), `UsersMapper`.

**knk-web-api `002edc0`** (`master` `c397585`), no textual conflict. `dotnet ef migrations has-pending-model-changes`:
none, so the merged snapshot is consistent. Migration `20261005132808_AddGameSettingsMotdAndGroupOverrides` now sorts
before four trunk migrations the dev DB already has (`UniquePermissionGrantHolderNode`, `AddDomainNavigationDefaults`,
`AddLocationRetention`, `SeedLocationRetentionStaffGroups`). `dotnet ef database update` still applies it, because it
is missing from `__EFMigrationsHistory`.

**knk-web-api `8ef1282`** (semantic fix): KNG-80's orphan check (`GameSettingsLocationReferenceSource`) scanned the
join spawn, default respawn and per-world settings, but not KNG-52's `GroupOverridesJson`. A Location picked only as
a group's spawn or respawn would have been reported as orphaned. The fix adds the column, with the test
`Run_SkipsLocationsNamedInGroupOverrides`.

## 2. Tests run

| Suite | Result |
|---|---|
| **2026-10-09, after the trunk merge:** knk-plugin `./gradlew build -x deployToDevServer` | BUILD SUCCESSFUL. core 1821, api-client 219 (2 skipped), paper 1391 (17 skipped), no failures. |
| **2026-10-09:** knk-web-api `dotnet build` + full `dotnet test` | Build 0 errors. 2023 tests: 1960 passed, 54 skipped, **9 failed**. Untouched `master` `c397585` gives the **same 9** (2008 tests): `CurrencyWriteGuardTests.NoCodeOutsideTheLedgerAssignsABalance`, `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`, 2× `CurrencyAnomalyDetectorTests` (MintRate, Velocity), `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`, 2× `PathResolutionServiceTests.ValidatePathAsync_AllowsValidV1Paths` (`Town.Name`, `Town.WgRegionId`), `RoadNetworkServiceTests.Validation_GeometryFarFromItsNode`, `TransferPolicyEvaluatorTests.DailySendCap_CountsTheLast24Hours_AndReportsWhatIsLeft`. |
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

Checked against the merged branches on 2026-10-09. Ready-made worktrees: `Repository/_worktrees/knk-web-api-kng52`
and `Repository/_worktrees/knk-plugin-kng52` (both on `claude/kng-52-game-settings`).

0. **Database:** the API branch adds migration `20261005132808_AddGameSettingsMotdAndGroupOverrides` (2 columns on
   `game_settings`: `Motd`, `GroupOverridesJson`). Back up the dev DB first (`mysqldump` from Workbench into
   `Documents/Werk/db-backups/`), then run this from the API branch:
   ```
   cd Repository/_worktrees/knk-web-api-kng52
   dotnet ef database update
   ```
   It sorts before four trunk migrations the dev DB already has; EF applies it anyway because it is missing from
   the history. Until it's applied, the branch's API fails on every Game Settings call.
1. **API and key:** run the branch's API. Writes now need the plugin key: on the API, set `Security:PluginApiKey`
   (appsettings or `Security__PluginApiKey`). In the dev server's `plugins/KnightsAndKings/config.yml`, set
   `api.auth.type: apikey` and `api.auth.api-key` to the same value. The other route is
   `Security:AllowUnauthenticatedPluginCalls: true` (Development only) with `type: none`, but then step 10's 401 check
   can't be done.
2. **Web user:** Save Settings now needs `knk.admin.config` (else 403). The Data Retention card on the same page
   already needs it. The web app needs no deploy: the page is on `main`.
3. **Keep the old town-4 respawn (D2):** right after deploying, open **Per-World Minecraft Settings** for the main
   world. Under **Respawn after dying in this world**, pick *A chosen spot (separate)* (API mode
   `ConfiguredReference`), then Town #4 in the picker. *Nearest town* is the more legacy-like alternative. Until
   then, regular players respawn at their bed or the world spawn.
4. **Plugin:** deploy with `./gradlew :knk-paper:dev` once ACTIVE_SESSIONS shows the dev server is free (or
   `build -x deployToDevServer` and copy the jar). The `game-settings:` block in `config.yml` is optional; defaults
   apply without it.
5. **Test accounts:** a regular account (no `knk.mode.owner`/`knk.mode.staff`, no `knk.teleport.bypass.*`), and a
   staff account with `knk.admin.cache` for `/knk cache refresh`.

## 4. Live smoke test (not done yet)

Use the regular account unless noted. The plugin re-reads the settings every 30 s
(`game-settings.refresh-interval-seconds`), so wait about 30 s after each Save. Or run `/knk cache refresh` as staff;
it answers `Refreshed: …, game settings, spawn destination, …`. A change to a player's permission groups reaches the
plugin when the player rejoins.

1. **Boot:** the log shows `Game settings initialized (refresh every 30s …)`, then
   `[KnK GameSettings] Applied game settings (last edit …)`. **Minecraft Worlds Overview** lists the loaded worlds.
2. **Announcements:** set **Join Announcement** to `&6{player} has arrived` and rejoin: the broadcast uses it. An
   empty **Leave Announcement** means no quit broadcast. A vanished staff member still joins and leaves silently.
3. **Join spawn:** set **Join Spawn Mode** to *A chosen spot (Location, Town, District or Structure)* and pick a Town.
   Rejoin: you arrive at the town's spawn, the same spot `/spawn` uses. Switch back to *The main world's spawn*:
   you arrive at the main world's spawn.
   - *Trunk (KNG-41/42):* `/spawn` still runs the warmup and the cooldown (the group's **/spawn cooldown (s)** if it
     has one, else `teleport.cooldown-seconds`). If your group has a **/spawn price**, it is announced during the
     warmup and charged on arrival. Then `/back` (needs `knk.teleport.back.spawn`) returns you to where you stood
     before `/spawn`. The join teleport itself leaves no `/back` place.
4. **Game mode:** set the main world's **Default GameMode** to ADVENTURE and rejoin: you see "Loading your
   account…", then stay in ADVENTURE, not SURVIVAL. An owner-mode account is unchanged.
5. **Respawn** (**Respawn after dying in this world**):
   - *A chosen spot (separate)* → Town #4: die, you respawn at town 4.
   - *Nearest town*: die inside another town, you respawn in it.
   - Set **Max nearest-town distance** below the nearest town's distance and untick *Use the world spawn (unticked:
     the server decides)*: you respawn at your bed or the world spawn.
   - *Server decides (bed / anchor, else world spawn)*: your bed is respected.
   - A staff account is never redirected, and leaving the End is not redirected.
   - In a siege match, the siege spawn still wins.
   - *Trunk (KNG-56):* if the chosen spot is inside a domain whose **AllowEntry** refuses the player, they respawn at
     the world spawn instead, with "… You respawned elsewhere."
   - *Trunk (KNG-42):* `/back` with `knk.teleport.back` still returns you to where you died.
6. **Time lock:** lock at 6000. The time stops at noon, and `/time set night` is corrected within 30 s. Unlock: the
   cycle runs again, also after a restart in between.
7. **Weather:** *Constant* RAIN → rain within 30 s, and sleeping doesn't clear it. *Blocked* THUNDER → `/weather
   thunder` works, then reverts within 30 s. *Weighted* 0/0/100 → the next natural change turns into thunder. A full
   natural cycle is slow; `/weather clear` followed by waiting is not a natural change.
8. **World spawn:** set the main world's **World Spawn Point**. A new player and a *Server decides* respawn use it.
   So does the KNG-56 fallback: an account that loads inside a refused domain is moved to that world's spawn.
9. **API down:** stop the API and restart the server. The log says `[KnK GameSettings] Using the cached settings (last
   edit …) until the API answers`, read from `plugins/KnightsAndKings/game-settings-cache.json`. Announcements and
   spawn behave as configured. Start the API again: the log says `Game settings read again`.
10. **Auth:** remove the plugin key: the report logs one warning, `Could not report the loaded worlds (does the API
    accept the plugin key?)`. With `AllowUnauthenticatedPluginCalls` off, an anonymous `PUT /api/GameSettings`
    returns 401. A web user without `knk.admin.config` gets 403 on Save.

**Round 2:**

11. **Group join message:** in **Permission Group Overrides**, use **Add a group** for the test account's rank group,
    tick **Own join message** and enter `&6[{group}] &e{player}`. Rejoin: that message is used, with the group's name.
    - Give a higher-weight unrelated group a different message: the deeper group's message wins, else the heavier
      one's (DESIGN §3.8).
    - An empty group message: that player joins silently.
12. **Group spawn:** tick **Own spawn (join and /spawn)** and pick a Structure by typing its town's name into the
    picker's search. Rejoin and `/spawn`: you go to the structure's spawn. A player without the group still goes to
    the server spawn. `/spawn <player>` from staff sends the target to *their* group spawn (instant, free).
    - *Trunk (KNG-41):* the group spawn doesn't skip the fee or the cooldown: the price and cooldown of step 3 still
      apply. With `knk.teleport.bypass.cost` it is free.
    - *Trunk (teleport menu):* the menu's Spawn tile goes to the group spawn too.
13. **Synced respawn:**
    - Set the main world's respawn to *Same as the join spawn (synced)*: die, and you respawn where you join,
      including the group spawn.
    - Tick a group's **Own respawn (in every world; replaces the world's policy)** → *Nearest town*: its members
      respawn at the nearest town in every world.
14. **MOTD:** in **Server List MOTD**, enter `&6Knights and Kings` / `&e{online}/{max} online`. The server list shows
    two coloured lines with the counts. Empty it: the server.properties motd is back.
15. **API:**
    - Saving an override for a deleted group returns 400, and so does a three-line MOTD.
    - `GET /api/Users/uuid/{uuid}` lists `permissionGroups` in the card's order.
    - *Trunk (KNG-80):* a Location used only as a group spawn is not listed by the location-retention orphan check
      (`/knk location orphans` or the web app).

### Regressions to watch (trunk features that touch the same code)

- `/spawn` with no group spawn: same destination as before, fee and cooldown per group (KNG-41).
- `/back` kinds: death, warps, teleport, spawn (KNG-42); a siege death gives no `/back`.
- `/tpa`, `/warp` and the teleport menu: warmup, cooldown and price are unchanged.
- Kits on first join, salary and discovery rewards still run on join.
- Siege: a match member's respawn and rejoin go to the siege spawn.
- KNG-56 access: entry/exit refusals and the join-time check still fire after the KNG-52 join teleport.
- `/knk cache refresh` still lists all hooks, without errors.
- Vanilla item pickup: trunk removed the old "non-ops can't pick up items" handler. That is a trunk change, not KNG-52.

Record results under a "Smoke test" heading here and in KNG-52.

## 5. Merge

After the smoke test, merge `claude/kng-52-game-settings` in this order:
1. knk-web-api `master`, with the migration applied wherever that API runs. The plugin needs its new fields and auth.
2. knk-plugin `main`.

knk-web-app is already on `main` (`055ac28`). If trunk moves again before the merge, merge it into the branches
first. Both branches already carry trunk as of 2026-10-09, and the API snapshot is consistent. Then:
- update the [feature register](../../FEATURE_REGISTER.md) row (Merge `trunk`, Verification) and add a
  [CHANGELOG](../../CHANGELOG.md) entry, including the town-4 respawn note;
- drop the knk-plugin stash `19-08-26: Workable: GameSettings feature`;
- remove the worktrees `Repository/_worktrees/knk-{web-api,plugin,workspace}-kng52`;
- move the ACTIVE_SESSIONS row to Recently completed;
- close KNG-52 or file the DESIGN §8 follow-ups.
