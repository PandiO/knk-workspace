# Navigation destination engine — smoke test

**Status:** Draft from the design (2026-11-18); § 1 updated by the P1 link (9 of 11 steps automated, tagged), § 2 by
the P2 link (12 of 13 steps automated, tagged), § 3 by the P3 link (20 of 22 steps automated, tagged), § 4 by the P4
link (16 of 18 steps automated, tagged); no manual steps run. Later sections are not yet automated (their links tag them).
**Last updated:** 2026-11-20 (§ 4.0 item 4: the `knk.navigate` seed and `default: false`, #845); 2026-11-18 (§ 4 updated to the P4 code, steps tagged, #62); 2026-11-18 (§ 3 updated to the P3 code, steps tagged, #69); 2026-11-18 (§ 2 updated to the P2 code, steps tagged, #103); 2026-11-18 (§ 1 updated to the P1 code, steps tagged, #96); 2026-11-18 (design approved: tiers confirmed, phase 4b is #747); 2026-11-18 (draft from the design refresh, phases 1, 2, 3, 4, 4b and 5)
**Design:** [specs/navigation-destination-engine/DESIGN.md](../specs/navigation-destination-engine/DESIGN.md) · **Issue:**
[PandiO/knk-workspace#25](https://github.com/PandiO/knk-workspace/issues/25)

The engine decides which places a player may navigate to. Phases 1 and 2 change nothing a player sees; phases 3 and 4
are behind `navigation.destination-engine` (default `false`), and with it off navigation must behave exactly as
before. Phase 4b removes the flag. Acceptance ids (A01…) are in DESIGN § 13; sections are sized by the phase's tier
(approved 2026-11-18, DESIGN § 10).

Accounts and data used throughout:

1. **Player:** an ordinary account with `knk.navigate` (default), not staff.
2. **Staff:** an account that can switch owner or staff mode and freeze players (`/knk mode staff`).
3. **Bypass:** an ordinary account given `knk.navigate.any` (not granted by default).
4. **Dev world:** the world with the road network, at least one town with a spawn Location, one district without a
   spawn Location (region only), one named street and one Location target; a second world with a domain of its own.
5. **Siege:** a siege scenario with two teams, at least one capture objective behind a closed gate (#176), and the
   navigation compass enabled for sieges in the web app's compass settings.

## 1. Phase 1: pure engine in knk-core (#96, tier:2)

*Updated by the P1 link (2026-11-18) to what was built: knk-plugin `claude/navigation-destination-engine`, package
`net.knightsandkings.knk.core.navigation.destinations`. 9 of 11 steps automated in CI (tagged); every step can
still be run by hand; manual steps not run. Full manual run about 25 minutes; the untagged steps (10 and 11) about
10 minutes.*

Nothing is wired in this phase: the engine is code and tests only, with no config key and no migration. The manual
check is that nothing changed. The tagged steps are knk-core JUnit tests (`./gradlew :knk-core:test`, part of CI's
build); to run one by hand, read the test named in its tag and check the stated result in its assertions.

### 1.0 Preconditions

1. Deployed: plugin build from `next` with phase 1 merged.
2. Settings: none new.
3. Accounts and data: Player, Staff; the dev world; the siege scenario.

### 1.1 Steps

1. [automated: `InitialScopesTest.theTableIsWalkedInTheDesignsOrder`, `DestinationEngineTest` scope tests] Read the
   scope table in `InitialScopes`. **Expected:** scopes in the order account loading 110, frozen 110, bypass 100, no
   permission 80, siege match 60, siege match with the compass off 55, siege lobby 50, world 10; the first that
   applies decides the whole list and lower scopes are not asked (A01).
2. [automated: `InitialScopesTest` loading and frozen tests, `ReasonTest.theInitialTableHasTheDesignsCodesAndTodaysTexts`]
   Check the loading and frozen scopes for a plain player, in owner mode, in staff mode and with `knk.navigate.any`.
   **Expected:** an empty list with code `loading` and "Your account is still loading - try again in a moment.", or
   code `frozen` and "You can't navigate while frozen.", in every mode (A02, E9).
3. [automated: `InitialScopesTest` bypass tests, `LandmarkLikeProviderTest.theBypassListsLandmarksEvenInAMatch`] Check
   owner mode, staff mode and `knk.navigate.any`, also inside a running match. **Expected:** the bypass scope lists
   every world provider and the match provider (A03, E5, E6).
4. [automated: `InitialScopesTest` no-permission tests] Check a player without `knk.navigate`. **Expected:** an empty
   list with code `no-permission` and "You don't have permission to use /navigate." (A04).
5. [automated: `InitialScopesTest.aMatchWithoutDestinationsListsNothingWithTodaysText`,
   `withTheCompassOffAMatchMemberGetsTheReason`, `aMatchListIsRebuiltOnEveryCallNotCached`] Check a member of a running
   match with the compass on, with the compass off, and with an empty match list. **Expected:** only the match's
   objectives and team spawn in the compass's order; with the compass off (item disabled or off for sieges) an empty
   list with code `siege-compass-off`; an empty match list with code `siege-match-empty`; both with today's text "This
   match has no destinations to navigate to."; the match list is built again on every call, not cached (A05, E15, E18).
6. [automated: `InitialScopesTest.aLobbyMemberWithoutARunningMatchGetsTheSiegeReason`,
   `aHubProviderWithDestinationsReplacesTheLobbyReason`] Check a lobby member without a running match, without and
   with a hub provider. **Expected:** an empty list with code `siege-lobby` and "You can't navigate while you are in a
   siege."; a hub provider with places in the player's world lists them instead (A06, E10).
7. [automated: `DestinationEngineTest` resolving and completion tests, `InitialScopesTest` match resolution tests]
   Resolve `Kardenna`, `town:Kardenna`, `town:#1`, an ambiguous `Market` and a misspelt name, in the world and in a
   match. **Expected:** found, found, found, a choice of `district:Market` and `town:Market`, suggestions; in a match
   the same forms work on objectives (`objective:Keep Gate`) (A07).
8. [automated: `InitialScopesTest.anotherWorldIsHiddenFromCompletionButResolvesToItsMessage`,
   `LandmarkLikeProviderTest.aLandmarkInAnotherWorldIsNotCompletedButResolvesApart`] Complete and resolve a town and a
   landmark in another world. **Expected:** not offered in completion; resolving gives the other-world answer (A08,
   E11).
9. [automated: `ArchitectureGuardTest.onlyTheDestinationEngineConstructsAllowedDestination`,
   `InitialScopesTest` and `DestinationEngineTest` re-validation tests, `LandmarkLikeProviderTest`] Check the handle
   and re-validation, and the landmark-like provider in the World scope. **Expected:** only the engine package
   constructs `AllowedDestination`; a session's destination is found by key after re-ordering and after a rename,
   stays when an objective changes kind, and ends with the scope's reason (or code `no-longer-listed`) when it drops
   out; a landmark (key `landmark:<id>`, type word `landmark`, detail `in <domain>`, a point with an optional arrival
   radius or a region) is listed in the world, hidden in a match, the lobby, loading, frozen and without permission,
   and listed for the bypass (A09, E3, E4, E16, § 3.2).
10. As Player, `/navigate` a town, a street and a Location target, and press Tab after `/navigate ` and after a few
    letters. **Expected:** the same routes, messages and suggestions as before the update. (Manual: checks that
    nothing is wired; needs a server and a player.)
11. As Player in a running siege match, right-click the compass a few times and type `/navigate ` with Tab.
    **Expected:** the same objectives and team spawn as before, in the same order; other places are refused with the
    same message. (Manual: checks that nothing is wired; needs a server, a siege and a player.)

## 2. Phase 2: navigation model and offline snapshot (#103, tier:2)

*Updated by the P2 link (2026-11-18) to what was built: knk-web-api `claude/navigation-destination-engine` (the
domain search's `location`), knk-plugin `claude/navigation-destination-engine` (package
`net.knightsandkings.knk.core.navigation.model`, runtime `net.knightsandkings.knk.paper.navigation.model`). 12 of 13
steps automated in CI (tagged); every step can still be run by hand; manual steps not run. Full manual run about
35 minutes; the untagged step 13 about 5 minutes.*

Nothing a player sees changes in this phase: the plugin builds, refreshes and saves the model, but nothing reads it
before phase 3. The tagged steps are API xUnit tests (`dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`)
and plugin JUnit tests (`./gradlew test`), both part of CI; to run one by hand, read the test named in its tag and
check the stated result in its assertions, or do the manual form written in the step.

### 2.0 Preconditions

1. Deployed: knk-web-api from `next` with phase 2 (the domain search's `location`); plugin build from `next` with
   phase 2. Either can be deployed first: an older API makes the plugin look Locations up one by one (step 11).
2. Settings: `navigation.destinations.stale-after-days: 14` under `navigation:` in `config.yml` (the default; a
   missing key means 14).
3. Accounts and data: Staff; the dev world with a town that has a spawn Location, a district without one, a domain
   whose road access is "Ignored", and a Location target.
4. The snapshot file is `plugins/KnightsAndKings/offline/navigation-model.json` (the plugin's data folder).

### 2.1 Steps

1. [automated: `DomainSearchLocationTests.TheSearchCarriesTheLocationOrNull`,
   `TheRepositoryLoadsEachDomainsLocation`, `TheJsonAlwaysHasTheLocationKeyAndKeepsTheOtherFields`] As Staff with an
   API client, run the domain search (`POST api/Domains/search` with `{"pageNumber":1,"pageSize":50}`).
   **Expected:** each domain carries `location` (id, name, x, y, z, yaw, pitch, world) when it has one and
   `"location": null` when it has none; `id`, `name`, `description`, `wgRegionId`, `worldName`, `parentDomainId`,
   `parentDomain`, `domainType`, `navigationDefault` and `roadAccess` are unchanged. (A10, E12)
2. [automated: `DomainCatalogMapperTest.theLocationAndWorldAreCarriedThrough`,
   `anExplicitNullMeansTheDomainHasNoLocation`, `anOlderApiWithoutTheFieldLeavesTheLocationUnknown`] Check how the
   plugin reads the search. **Expected:** a `location` object becomes the domain's place; `"location": null` means
   "no Location"; a search without the key (an older API) leaves the place unknown for the fallback of step 11. (A10)
3. [automated: `NavigationModelRuntimeTest.theFirstStartWritesTheSnapshotAfterTheBackgroundRefresh`,
   `NavigationModelSnapshotTest.schemaOneHasEverySectionAndAnEmptyLandmarksList`, `theFileHoldsNoPlayerData`] Delete
   the snapshot file if there is one, start the server with the API up and wait a minute. **Expected:** the log has
   "No navigation model snapshot yet" and then "Navigation model loaded: N domain(s), M Location(s)"; the file exists
   with `"schema" : 1`, `asOf`, `domains` (each with its spawn, region, world, `navigationDefault` and `roadAccess`),
   `locations`, `compass` and an empty `landmarks` list, and no player names or UUIDs. (A11, E16, E19)
4. [automated: `NavigationModelSnapshotTest.theWriteIsAtomicAndReplacesTheOldFile`,
   `NavigationModelRefresherTest.theSnapshotIsWrittenOffTheCallingThreadAfterAChange`,
   `anUnchangedModelIsNotWrittenAgainUntilItsFileIsADayBehind`] Watch the file's modification time for a few minutes
   without changing anything in the web app. **Expected:** it is not rewritten every minute (only after a change, or
   once a day to keep its `asOf` current); no `navigation-model.json.tmp` is left in the folder. (A11)
5. [automated: `NavigationModelRefresherTest.afterARestartWithTheApiDownTheSameModelIsServed`,
   `NavigationModelRuntimeTest.theSnapshotIsLoadedAtStartUpBeforeTheApiAnswers`] Stop the web API, restart the game
   server, then as Player `/navigate` the town by name. **Expected:** the log has "Navigation model snapshot loaded
   from …: N domain(s), M Location(s), as of <time>, fresh (<age> old)" and then "Navigation model refresh failed,
   keeping the last model"; `/navigate` still behaves as today (the engine reads the model from phase 3 on, § 3.3
   step 1). (A12, E1)
6. [automated: `NavigationModelSnapshotTest.aCorruptFileIsIgnoredNeverThrown`, `aNewerSchemaIsIgnored`,
   `NavigationModelRefresherTest.aCorruptSnapshotIsIgnoredAndTheNextGoodRefreshWritesANewOne`,
   `NavigationModelRuntimeTest.aBrokenSnapshotDoesNotStopTheStart`] Stop the server, replace the file's content with
   `{ broken`, start again with the API up. **Expected:** a warning "Ignoring the navigation model snapshot …
   (CORRUPT: …); the next good refresh writes a new one", the plugin starts normally, and within a minute the file is
   valid again. The same with `"schema": 2` gives "(NEWER_SCHEMA: schema 2 …)". (A13)
7. [automated: `ModelFreshnessTest.withoutAnyModelTheListIsLimitedWithTheDesignsText`] With no snapshot and the API
   down, the model's freshness is "limited (no snapshot)" with the text "Some places aren't available while the web
   API is down.". **Expected:** as stated; players see it from phase 3 on (§ 3.3 step 2). (A13)
8. [automated: `NavigationModelRefresherTest.aRefreshReplacesTheModelSoRenamesAndDeletionsPropagate`] With the API
   up, rename the town in the web app and delete a test structure, then wait for the next refresh (about a minute).
   **Expected:** the snapshot holds the new name and not the old one, and the deleted structure is gone. (A14)
9. [automated: `ModelFreshnessTest.aModelOlderThanTheLimitGetsTheMayBeOutOfDateNote`,
   `theLimitIsConfigurableButAtLeastADay`, `NavigationModelConfigTest`] Stop the API, set the file's `asOf` to 15
   days ago, restart. **Expected:** the start-up log line says "stale (15 days old)"; the lists get "The list of
   places may be out of date (last updated 15 days ago)." from phase 3 on; `stale-after-days: 30` makes it "fresh";
   0 counts as 1. (A15, E12)
10. [automated: `NavigationModelRuntimeTest.theRoadAccessAnswersAreTheCataloguesAnswers`,
    `NavigationModelTest.onlyAnExplicitIgnoredLiftsTheRuleOffTheRoads`,
    `regionsOfIgnoredDomainsAreAnsweredInAnyCase`] Compare the model's road-access answers with today's catalogue
    for the same API data. **Expected:** the same answer for every domain id and region (the "Ignored" domain and its
    region in any case: yes; others and unknown ones: no). Routes use them from phase 3 on (A21). (E19)
11. [automated: `NavigationModelRefresherTest.withAnOlderApiPlacesAreLookedUpAFewPerTickAndTheSnapshotWaitsForThem`,
    `placesFoundByTheFallbackAreKeptByTheNextRefresh`, `aFailedLookupIsTriedAgainAfterTheNextRefreshAndDoesNotHoldUpTheSnapshot`,
    `withTheNewApiNothingIsLookedUp`, `NavigationModelRuntimeTest.theFallbackLooksUpTownsDistrictsAndStructuresThroughTheResolver`]
    Run the phase 2 plugin against an API without the change. **Expected:** the log says "… N domain place(s) to look
    up one by one (the API's search sends no Locations)"; two places a second are looked up; the snapshot is written
    once they are done; a later refresh keeps them; `/knk cache refresh` looks them up again. Against the new API
    nothing is looked up. (§ 7.2)
12. [automated: `NavigationModelUnreadTest.onlyTheModelPackagesAndTheStartUpWiringUseTheModel`] Check that nothing
    reads the model. **Expected:** only `KnKPlugin` (start and stop) names the model's packages. (A16 groundwork)
13. As Player, `/navigate` a town, a street and a Location target, press Tab after `/navigate `, and right-click the
    navigation compass outside a siege. **Expected:** the same routes, messages, suggestions and compass behaviour as
    before the update. (Manual: checks that nothing is wired; needs a server and a player.)

## 3. Phase 3: switch-over behind the flag (#69, tier:3)

*Updated by the P3 link (2026-11-18) to what was built: knk-plugin `claude/navigation-destination-engine`, providers
in `net.knightsandkings.knk.core.navigation.engine` (`CatalogueProvider`, `SiegeMatchProvider`, `CompassTargets`),
plugin adapters in `net.knightsandkings.knk.paper.navigation.engine` (`PlayerNavigationEngine`, `RoadAccessAnswers`,
`DestinationEngineConfig`) and the engine branches of `NavigateCommand`, `NavigationCompassService` and
`NavigationService`. 20 of 22 steps automated in CI (tagged); every step can still be run by hand, and the developer
runs this section and § 4 live with the flag on before phase 4b (charter gate of L5). Full manual run about 60
minutes; the untagged steps (§ 3.2 step 6, § 3.3 step 1) about 15 minutes.*

With `navigation.destination-engine: true` the command, its tab completion and the compass ask the engine for the
player's list (one list per player, built from the navigation model of § 2 and the road network), and
`NavigationService` starts a session only from the engine's handle. What does not change yet: the refusals while the
account is loading, while frozen and in a siege lobby keep coming from today's checks as well (same texts; phase 4
moves them into the scopes and re-checks running routes), and `/navigate` still needs `knk.navigate`. The tagged steps
are knk-core JUnit tests and knk-paper MockBukkit/Mockito tests (`./gradlew test`, part of CI's build) against the real
engine with fake providers; to run one by hand, read the test named in its tag and check the stated result in its
assertions, or do the manual form written in the step.

### 3.0 Preconditions

1. Deployed: plugin build from `next` with phases 1 to 3; knk-web-api from `next` with phase 2 (the domain search's
   `location`, § 2.0).
2. Settings: for § 3.1 `navigation.destination-engine: false` under `navigation:` in `config.yml` (or the key
   missing). For § 3.2 to § 3.4 set it to `true` and **restart** the server: the key is read at start-up only;
   `/knk reload` does not switch it. With it on, the start-up log has "[Navigation] Destination engine on
   (navigation.destination-engine): /navigate, completion, the compass and road access use the navigation model".
3. Accounts and data: Player, Staff, Bypass (granted `knk.navigate.any` through the in-house permission system; the
   node is not granted by default, not even to operators); the dev world and the second world; the siege scenario.
4. Compass settings in the web app: general targets switched on, with at least a street and a town listed, for
   example `Main Street` and `<town> spawn`, and one line that names nothing (`Nowhere`).
5. Before § 3.2, start the server once with the API up so `plugins/KnightsAndKings/offline/navigation-model.json`
   exists (§ 2.1 step 3).

### 3.1 Flag off

1. [automated: `DestinationEngineConfigTest.theShippedConfigHasTheKeySwitchedOff`, `aMissingKeyOrConfigMeansOff`]
   Start the server with the key `false` or missing. **Expected:** no "Destination engine on" line in the log; the
   shipped `config.yml` has `destination-engine: false` under `navigation:`. (A16, E17)
2. [automated: the unchanged `NavigateCommandTest` and `NavigationCompassServiceTest`,
   `NavigateCommandEngineTest.withTheFlagOffTheEngineIsNotUsed`, `NavigationCompassEngineTest.withTheFlagOffTheEngineIsNotUsed`,
   `NavigationServiceHandleTest.withTheFlagOffTheRawEntryWorksAsToday`] As Player, repeat § 1.1 steps 10 and 11
   (`/navigate` a town, a street and a Location target, Tab after `/navigate ` and after a few letters; in a running
   siege match right-click the compass and type `/navigate ` with Tab). **Expected:** exactly today's routes, messages,
   suggestions and compass behaviour. (A16)
3. [automated: `RoadAccessAnswersTest.withTheFlagOffTheCatalogueAnswersAndTheModelIsNotAsked`,
   `withTheFlagOffAndNoCatalogueEveryRuleIsKept`] As Player, walk a route that passes a domain whose road access is
   "Ignored". **Expected:** the route uses its roads as before (the answers come from today's catalogue). (A16, E19)

### 3.2 Flag on, outside a siege

1. [automated: `NavigateCommandEngineTest.aNameStartsASessionFromAHandleNeverFromARawDestination`,
   `typeNameIdAndTheModeWordsWork`, `aDomainAskedForWithAModeItLacksGoesToTheOtherAsToday`,
   `HandleDestinationsTest.everyDomainShapeAndModeGoesWhereItGoesToday`,
   `CatalogueProviderTest.namesResolveAsTodayTypeNameIdAmbiguityAndSuggestions`] As Player, `/navigate <town>`,
   `/navigate <town> spawn`, `/navigate <district> region`, `/navigate town:#<id of the town>`,
   `/navigate street:<name>` and `/navigate location:<name>`. **Expected:** the same routes as with the flag off; each
   starts at once (the place is in the model, nothing is looked up when you press Enter); a district that has only a
   region and is asked for with `spawn` is led to its region, as today. (A17)
2. [automated: `NavigateCommandEngineTest.completionOffersStopAndTheListsNamesButNotAnotherWorld`,
   `completionOffersTheModeWordsAfterACompleteName`, `CatalogueProviderTest.anotherWorldsPlaceIsNotCompletedButResolvesApart`,
   `theOrderIsTodaysCatalogueOrder`] As Player, press Tab after `/navigate `, after the first letters of the town,
   after `town:`, and after the full town name and a space. **Expected:** `stop` and the names (domains, then
   Locations, streets and road points); the town; `town:<name>` for every town; `spawn` and `region`. Places of the
   second world are not suggested. (A17, A08)
3. [automated: `NavigateCommandEngineTest.aPlaceInAnotherWorldGetsTodaysMessage`, `ResolveKeyTest.aKeyOfAnotherWorldIsAnsweredApart`]
   As Player, `/navigate <domain of the second world>`. **Expected:** "<name> is in another world." as today. (A08,
   E11)
4. [automated: `NavigateCommandEngineTest.aMisspeltNameIsUnknownWithDidYouMean`, `aSharedNameOffersTheTypeNameChoices`,
   `aDomainWithoutAnyPlaceHasNoLocation`] As Player, type a misspelt town name (`/navigate Kardena`), a name two
   domains share, and a domain without a Location or region. **Expected:** "unknown destination" and a "did you mean"
   line; the `type:name` choices to click; "<name> has no Location" as today. (A07)
5. [automated: `NavigationCompassEngineTest.outsideASiegeItCyclesTheConfiguredTargetsThatAreListed`,
   `withTheGeneralSwitchOffItHasNoDestinationsHere`, `CompassTargetsTest.theLinesAreKeptInTheirOrderWithTheirModeWords`,
   `unknownAmbiguousAndOtherWorldLinesAreLeftOut`] As Player outside a siege, right-click the compass a few times;
   then switch the compass's general targets off in the web app, wait about a minute (the model's refresh) and
   right-click again. **Expected:** "Compass 1/2: Main Street", then "Compass 2/2: <town>" with a route to its spawn
   (the `Nowhere` line is skipped); with the general targets off "The navigation compass has no destinations here."
   while `/navigate <town>` still works. (A19)
6. As Staff, `/knk road why <town>`; afterwards search the server log for "A raw destination". **Expected:** the
   explanation as today (it does not go through the list); no "A raw destination (…) was refused" warning anywhere
   in this section's run (only engine handles started sessions). (A20) (Manual: `explain` is unchanged and the log
   check needs the live run; the refusal itself is automated in
   `NavigationServiceHandleTest.withTheFlagOnTheRawEntryRefusesAndTheHandleStillWorks`.)
7. [automated: `RoadAccessAnswersTest.withTheFlagOnTheModelAnswersAndTheCatalogueIsNotAsked`,
   `withTheFlagOnTheListenerRunsOnlyWhenTheIgnoredRegionsChange`, `NavigationModelRuntimeTest.theRoadAccessAnswersAreTheCataloguesAnswers`]
   As Player, walk a route that passes a domain whose road access is "Ignored"; then set another domain on a road to
   "Ignored" in the web app and wait about a minute. **Expected:** the route uses the first domain's roads as before;
   after the change routes use the second domain's roads too (the live road tags recut once). (A21, E19)

### 3.3 Flag on, API down

1. Stop the web API, restart the game server, then as Player `/navigate <town>`, right-click the compass outside a
   siege, and walk past the "Ignored" domain of § 3.2 step 7. **Expected:** the log has "Navigation model snapshot
   loaded from …"; the town is found and routed from the snapshot; the compass cycles the general targets of § 3.0
   item 4 (the saved settings, not the defaults, which have no general targets); the "Ignored" domain's roads are
   still used. (A12, A17, A19, A21) (Manual: needs a restart with the API stopped.)
2. [automated: `CatalogueProviderTest.withoutAModelOnlyTheNetworkIsOffered`,
   `NavigateCommandEngineTest.aNameNotFoundWhileTheModelIsLimitedCarriesTheNote`,
   `ModelFreshnessTest.withoutAnyModelTheListIsLimitedWithTheDesignsText`] Stop the server, delete
   `navigation-model.json`, start with the API still down, then press Tab after `/navigate ` and run
   `/navigate <town>` and `/navigate <street>`; right-click the compass outside a siege. **Expected:** streets and
   named road points are offered, towns are not; `/navigate <town>` says "unknown destination" and then "Some places
   aren't available while the web API is down."; the street is routed; the compass says "The navigation compass has
   no destinations here." (without a model it has only the default settings, with no general targets). (A13)
3. [automated: `ModelFreshnessTest.aModelOlderThanTheLimitGetsTheMayBeOutOfDateNote`,
   `NavigationCompassEngineTest.withNothingListedWhileTheModelIsLimitedItAddsTheNote`] Stop the server, set the
   snapshot's `asOf` to 15 days ago, start with the API down, then `/navigate Kardena` (a misspelt name). **Expected:**
   "unknown destination", "did you mean" and "The list of places may be out of date (last updated 15 days ago)."; the
   note also follows the compass's "has no destinations here" when none of its targets is listed. (A15)

### 3.4 Flag on, in a siege match

1. [automated: `NavigateCommandEngineTest.inAMatchCompletionOffersOnlyTheMatchsDestinationsAndStop`] As Player in a
   running match, press Tab after `/navigate `, and after the first word of a two-word objective name and a space.
   **Expected:** only `stop`, the first words of the match's objectives and the team spawn; then the next word of that
   name, without `spawn` or `region`. (A18)
2. [automated: `NavigateCommandEngineTest.inAMatchTypeNameAndTheStartOfANameWork`,
   `inAMatchTheStartOfExactlyOneNamePicksIt`, `inAMatchAWholeNameEndingInSpawnIsTheTeamSpawn`,
   `SiegeMatchProviderTest.theEngineListsThemInTheCompassOrderAndTypeNameWorksInTheMatch`] As Player,
   `/navigate objective:<name>`, `/navigate objective:#<id>`, `/navigate <start of an objective name>` and
   `/navigate <the team spawn's name>`. **Expected:** each starts a route to that objective or the spawn; `type:name`
   and `type:#id` are new in a match (§ 3.1 of the design). (A18, A07)
3. [automated: `NavigateCommandEngineTest.inAMatchATownIsRefusedNamingTheMatchsDestinations`,
   `inAMatchTheStartOfSeveralNamesIsAChoice`] As Player, `/navigate <town>`, then `/navigate <start shared by two
   objectives>`. **Expected:** "\"<town>\" is not part of this match. You can navigate to: …" with the match's
   destinations to click; "Several destinations start with …" with the choices. (A18)
4. [automated: `SiegeMatchProviderTest.anObjectiveToCaptureBehindAClosedGateLeadsToTheGate`,
   `defendersAreNotSentToAGate`] As Player of the attacking team, select the objective behind the closed gate with
   the compass (and with `/navigate objective:<its name>`). **Expected:** the route leads to the gate, not the capture
   point (#176); for a defender it leads to the objective. (A18)
5. [automated: `NavigationCompassEngineTest.inAMatchTheCompassCyclesTheMatchsListInItsOrder`,
   `SiegeMatchProviderTest.theCandidatesAreTheCompassTargetsInTheirOrder`] As Player, right-click the compass through
   the whole list. **Expected:** the same order and details as with the flag off ("Compass 1/3: <objective>
   (capture, …)", the team spawn last), then the first again. (A18, A19)
6. [automated: `NavigateCommandEngineTest.withTheCompassOffForSiegesAMatchHasNoDestinations`,
   `NavigationCompassEngineTest.withTheCompassOffForSiegesItSaysSo`, `EngineReasonsTest`] Switch the compass off for
   sieges in the web app, wait about a minute, then `/navigate <objective>` and right-click the compass. **Expected:**
   `/navigate` says "This match has no destinations to navigate to."; the compass says "The navigation compass is
   switched off during sieges.". (A05, A19, E15)
7. [automated: `NavigateCommandEngineTest.theBypassListsEverythingInAMatch`, `staffModeIsTheBypassToo`,
   `NavigationCompassEngineTest.forTheBypassInAMatchItCyclesTheMatchNotTheWorld`] As Bypass in the match,
   `/navigate <town>` and right-click the compass; then as Staff in staff mode the same. **Expected:** a route to the
   town starts (the bypass lists everything); the compass still cycles the match's destinations. (A03)
8. [automated: `NavigationCompassEngineTest.aResumeResolvesTheStoredKeyAgain`,
   `aDestinationThatLeftTheListIsNotResumed`, `ResolveKeyTest.aKeyThatIsNotListedGetsNoHandle`] As Player, select an
   objective with the compass, shift-right-click to stop, shift-right-click again; then select an objective the other
   team then captures for good, stop, and shift-right-click. **Expected:** the first resume continues to the same
   objective; once it is no longer listed the resume says "Right-click the compass to pick a destination." (A19)
9. [automated: `NavigateCommandEngineTest.aFrozenPlayerOrALobbyMemberGetsTodaysWords`,
   `NavigationCompassEngineTest.inTheLobbyItWaitsForTheMatch`, `forTheBypassInTheLobbyItStillWaitsForTheMatch`] As
   Player in the siege lobby before the match, `/navigate <town>` and right-click the compass. **Expected:**
   `/navigate`: "You can't navigate while you are in a siege."; the compass: "The navigation compass works once the
   siege match has started.". (A06, E15; ending running routes is § 4.2)

## 4. Phase 4: hard blocks as scopes and live re-validation (#62, tier:3)

*Updated by the P4 link (2026-11-18) to what was built: knk-plugin `claude/navigation-destination-engine`, the
re-validation in `NavigationService` (`setRevalidator`, `revalidateSoon`, the 2-second re-check),
`PlayerNavigationEngine.revalidate`, `EndReason.DESTINATION_NOT_ALLOWED`, the mode listener of `ModeService` and the
triggers wired in `KnKPlugin.startDestinationEngine`. 16 of 18 steps automated in CI (tagged); every step can still be
run by hand, and the developer runs this section and § 3 live with the flag on before phase 4b (charter gate of L5).
Full manual run about 45 minutes; the untagged steps (§ 4.1 step 1, § 4.3 step 3) about 10 minutes.*

With `navigation.destination-engine: true` the hard blocks are the engine's scopes: loading (110), frozen (110, also
for owner/staff mode and `knk.navigate.any`, E9), no permission (80) and the siege lobby (50) refuse with today's
texts, and the route start no longer asks the old `NavigationEligibility`. A running route keeps the handle it was
started from and is checked against the player's list again every 2 seconds and at once (on the next server tick)
when a siege objective is captured, the match ends, the lobby changes, a round is released, the player's owner/staff
mode changes, a freeze starts or ends, or the navigation model is refreshed with a change. When its destination is no
longer listed, or the player now falls into a scope that lists nothing, the route ends with that scope's reason as the
message (end reason `DESTINATION_NOT_ALLOWED`; "you joined a siege" (`SIEGE`) is not used with the flag on). With the
flag off nothing of this runs: routes end in a siege lobby as before. The tagged steps are knk-paper MockBukkit/Mockito
tests (`./gradlew test`, part of CI's build) against the real engine with fake providers, and knk-core JUnit tests of
the scope table; to run one by hand, read the test named in its tag and check the stated result in its assertions, or
do the manual form written in the step.

### 4.0 Preconditions

1. Deployed: plugin build from `next` with phases 1 to 4; knk-web-api from `next` with phase 2.
2. Settings: `navigation.destination-engine: true` under `navigation:` in `config.yml`, then **restart** (read at
   start-up only); the start-up log has "[Navigation] Destination engine on (navigation.destination-engine)". For
   § 4.4 set it back to `false` and restart.
3. Accounts and data: Player, a second ordinary account (Opponent) for the other siege team, Staff (can switch staff
   mode and freeze), a second staff account of higher rank (Senior Staff, can freeze Staff), Bypass (granted
   `knk.navigate.any` through the in-house permission system); the dev world with a town reachable by road; the
   siege scenario with at least two objectives, the compass switched on for sieges.
4. The in-house permission system can take `knk.navigate` away from Player's group and give it back
   ([#845](https://github.com/PandiO/knk-workspace/issues/845)): knk-web-api has the seed migration
   `SeedNavigateDefaultNode` applied (the Default group holds `knk.navigate`) and the plugin build has `knk.navigate`
   as `default: false` in `plugin.yml`, so Bukkit no longer answers yes for every player. "Take it away" means a deny
   of `knk.navigate` on Player's group (or Player's account) in the in-house permission system, then the permission
   cache refreshed; "give it back" means removing that deny. With the older plugin (`default: true`) the deny is
   never asked and § 4.1 step 4 and § 4.2 step 3 cannot pass.

### 4.1 Refusals come from the scopes (A22)

1. As Player right after joining (while the account is still loading), `/navigate <town>`. **Expected:** "Your
   account is still loading - try again in a moment.". (A22) (Manual: the loading window is a second or two on a
   live join; the scope and its text are automated in `InitialScopesTest` and
   `NavigateCommandEngineTest.aFrozenPlayerOrALobbyMemberGetsTodaysWords` covers the same path for frozen.)
2. [automated: `NavigateCommandEngineTest.aFrozenPlayerOrALobbyMemberGetsTodaysWords`,
   `InitialScopesTest.aFrozenPlayerGetsTheFrozenReason`] As Staff, freeze Player; as Player `/navigate <town>`.
   **Expected:** "You can't navigate while frozen.". (A22)
3. [automated: `InitialScopesTest.frozenBeatsTheBypass`,
   `NavigationServiceRevalidationTest.freezeStillEndsAStaffSession`] As Staff in staff mode, have Senior Staff freeze
   you, then `/navigate <town>`. **Expected:** "You can't navigate while frozen.", as for anyone (E9). (A02, A25)
4. [automated: `NavigateCommandEngineTest.withoutTheNodeTheNoPermissionScopeRefusesWithTodaysWords`,
   `NavigationCompassEngineTest.withoutTheNodeTheCompassKeepsItsNoPermissionWords`] Take `knk.navigate` away from
   Player's group; as Player `/navigate <town>`, press Tab after `/navigate `, and right-click the compass.
   **Expected:** "You don't have permission to use /navigate."; Tab offers nothing but `stop`; the compass says its
   own no-permission line as today. Give the node back afterwards. (A22, A04)
5. [automated: `NavigateCommandEngineTest.theBypassNodeAloneIsEnoughWithTheEngine`,
   `NavigationCompassEngineTest.theBypassNodeAloneIsEnoughForTheCompass`,
   `CommandNodesTest.navigateIsOpenToTheDestinationEngineBypassNodeToo`] Take `knk.navigate` away from Bypass too
   (keep `knk.navigate.any`); as Bypass `/navigate <town>`. **Expected:** the route starts (the bypass sits above
   the permission scope, E5); `/navigate` is offered in Bypass's "/" suggestions. Give the node back afterwards. (A03)
6. [automated: `NavigateCommandEngineTest.aFrozenPlayerOrALobbyMemberGetsTodaysWords`,
   `NavigationCompassEngineTest.inTheLobbyItWaitsForTheMatch`] As Player in a siege lobby before the match,
   `/navigate <town>` and right-click the compass. **Expected:** `/navigate`: "You can't navigate while you are in a
   siege."; the compass: "The navigation compass works once the siege match has started.". (A22, A06)

### 4.2 Running routes are re-checked (A23, A24, A26)

1. [automated: `NavigationServiceRevalidationTest.aFreezeChangeEndsTheSessionAtOnceWithTheFrozenReason`] As Player,
   `/navigate <town>`; while walking, have Staff freeze you. **Expected:** the route ends at once (the trail and the
   boss bar go) with "You can't navigate while frozen.". Unfreeze afterwards. (A23, A24)
2. [automated: `NavigationServiceRevalidationTest.joiningALobbyEndsTheSessionWithTheLobbysReasonNeverSiege`,
   `theRecheckNeverEndsWithSiegeWithTheFlagOn`] As Player, `/navigate <town>`, then join a siege lobby. **Expected:**
   the route ends at once with "You can't navigate while you are in a siege." (not "Navigation to … ended - you joined
   a siege."). (A23, A24, A26)
3. [automated: `NavigationServiceRevalidationTest.theTwoSecondRecheckEndsASessionWhosePermissionWasTakenAway`] As
   Player, `/navigate <town>`; while walking, take `knk.navigate` away from Player's group. **Expected:** within
   about 2 seconds the route ends with "You don't have permission to use /navigate.". Give the node back
   afterwards. (A23)
4. [automated: `NavigationServiceRevalidationTest.anObjectiveDroppedOnCaptureEndsTheSessionAtOnce`,
   `aReleasedRoundReChecksAtOnce`] As Player in a running match, select an objective to capture with the compass (or
   `/navigate objective:<name>`); let Opponent's team capture it for good so it is no longer listed for you.
   **Expected:** at the capture the route ends at once with "<objective> is no longer part of this match.". (A23,
   A24)
5. [automated: `NavigationServiceRevalidationTest.anObjectiveThatChangesKindButStaysListedKeepsTheSession`,
   `aLobbyChangeDuringTheMatchKeepsTheMatchSession`] As Player, navigate to an objective that stays listed after a
   capture (it flips from "capture" to "defend" for your team), then let someone in the lobby vote or leave.
   **Expected:** the route keeps going through the capture and the lobby change. (A25)
6. [automated: `NavigationServiceRevalidationTest.theMatchEndingEndsTheSessionWithTheScopeThePlayerIsInNow`] As
   Player, navigate to an objective, then let the match end (time runs out or a team wins). **Expected:** at the end the
   route ends at once with the reason of the scope you are in now: back at the hub as a lobby member, "You can't
   navigate while you are in a siege.". (A24)
7. [automated: `NavigationServiceRevalidationTest.aDomainRemovedByAModelRefreshEndsTheSession`,
   `aCandidateStillListedKeepsTheSessionAfterATrigger`] As Player, `/navigate <town B>` (a test town); in the web app
   delete town B (or move it to the other world), then wait about a minute for the model's refresh. **Expected:** at
   the refresh the route ends with "<town B> is no longer part of the world."; a route to another town that is still
   listed keeps going. (A23, A24)

### 4.3 Owner/staff mode and freeze (A25, E9)

1. [automated: `NavigationServiceRevalidationTest.switchingStaffModeOffInAMatchEndsATownSessionAtOnce`,
   `ModeServiceListenerTest.everyChangeIsHeardOnceAndARepeatIsNot`] As Staff in a running match with staff mode on,
   `/navigate <town>`; then switch staff mode off. **Expected:** the route starts (the bypass lists the world in a
   match); after switching off it ends at once with "<town> is no longer part of this match.". (A25, A03)
2. [automated: `NavigationServiceRevalidationTest.switchingStaffModeOnAppliesTheBypassAndTheSessionKeepsGoing`,
   `freezeStillEndsAStaffSession`, `freezeStillEndsABypassNodeSession`] As Staff with staff mode on, `/navigate
   <town>`; have Senior Staff freeze you; then unfreeze, `/navigate <town>` again and as Bypass do the same freeze.
   **Expected:** each frozen route ends at once with "You can't navigate while frozen." (freeze sits above the bypass,
   E9). (A25)
3. As Staff with staff mode on, run `/knk road why <town> --as <Player>` while Player is frozen. **Expected:** the
   explanation as before (the diagnostic path does not go through the list, § 6). (A20) (Manual: `explain` is
   unchanged and only reads; nothing of P4 runs there.)

### 4.4 Flag off: today's endings (A16)

1. [automated: `NavigationServiceRevalidationTest.withTheFlagOffAJoinedLobbyEndsTheSessionWithSiegeAsToday`,
   `withTheFlagOffTheRecheckEndsALobbyMemberWithSiegeAsToday`] With `navigation.destination-engine: false` (restart),
   as Player `/navigate <town>`, then join a siege lobby. **Expected:** the route ends with "Navigation to <town>
   ended - you joined a siege." as today. (A16)
2. [automated: `NavigationServiceRevalidationTest.withTheFlagOffAFreezeDoesNotEndARunningSessionAndTriggersDoNothing`,
   `NavigateCommandEngineTest.withTheFlagOffTheCommandStillChecksTheNodeItself`,
   `NavigationServiceHandleTest.theRawEntryStillAsksTheOldEligibilityWithTheFlagOff`] With the flag off, as Player
   `/navigate <town>` and have Staff freeze you while walking; then `/navigate <town>` while frozen; as Bypass without
   `knk.navigate`, `/navigate <town>`. **Expected:** as today: the running route keeps going after the freeze, the
   new one is refused with "You can't navigate while frozen.", and Bypass is told "You don't have permission to use
   /navigate." (the bypass node means nothing without the engine). (A16)

## 5. Phase 4b: removal of the old paths and the flag (#747, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 5.0 Preconditions

1. Deployed: plugin build from `next` with phase 4b; the developer has run § 3 and § 4 with the flag on.
2. Settings: `navigation.destination-engine` removed from `config.yml` (the deploy notes say so).
3. Accounts and data: as in § 3.

### 5.1 Steps

1. Start the server without the flag. **Expected:** no warning about an unknown or missing key; navigation uses the
   engine. (A27)
2. Repeat § 3.2 steps 1, 2 and 5, § 3.4 steps 1, 3 and 5, and § 4.1 steps 5 and 6. **Expected:** as written there.
   (A28)

## 6. Phase 5: arena duels provider and scope (#55, tier:2)

*Draft from the design (2026-11-18); written in full when the arena duels work is merged and the phase is scheduled.*

### 6.0 Preconditions

1. Deployed: plugin build from `next` with phase 5 and the arena duels work.
2. Settings: arena duels enabled.
3. Accounts and data: two Players in a duel.

### 6.1 Steps

1. As a Player in a running duel, Tab after `/navigate ` and `/navigate <town>`. **Expected:** only the duel's places
   are offered; the town is refused with the duel's reason. (A29)
2. As a Player queued or in the duel's lobby, `/navigate <town>`. **Expected:** refused with the duel's reason. (A29)
3. After the duel, `/navigate <town>`. **Expected:** a route starts as usual. (A29)
