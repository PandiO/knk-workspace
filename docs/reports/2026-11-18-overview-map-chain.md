# Overview map chain — progress report

**Status:** Running (2026-11-18) · **Last updated:** 2026-11-18

**Issue:** [PandiO/knk-workspace#732](https://github.com/PandiO/knk-workspace/issues/732), links
[#735](https://github.com/PandiO/knk-workspace/issues/735) (L1), [#736](https://github.com/PandiO/knk-workspace/issues/736) (L2),
[#737](https://github.com/PandiO/knk-workspace/issues/737) (L3), [#738](https://github.com/PandiO/knk-workspace/issues/738) (L4),
[#739](https://github.com/PandiO/knk-workspace/issues/739) (L5), [#740](https://github.com/PandiO/knk-workspace/issues/740) (L6),
[#741](https://github.com/PandiO/knk-workspace/issues/741) (L7), [#742](https://github.com/PandiO/knk-workspace/issues/742) (L8),
[#743](https://github.com/PandiO/knk-workspace/issues/743) (L9)
**Charter:** [handoffs/OVERVIEW_MAP_CHAIN.md](../ai-agents/handoffs/OVERVIEW_MAP_CHAIN.md).
**Spec:** [specs/in-game-maps/OVERVIEW_MAP_DESIGN.md](https://github.com/PandiO/knk-workspace/blob/next/docs/specs/in-game-maps/OVERVIEW_MAP_DESIGN.md)
on `next` (Decided 2026-11-18, O01–O33, O08 superseded by O31); smoke guide
[guides/overview-map-smoke-test.md](https://github.com/PandiO/knk-workspace/blob/next/docs/guides/overview-map-smoke-test.md) on `next`.

## 1. Waiting for the developer

1. **L1 (#735) smoke test (tier:3):** L1 is in `next` (knk-web-api `562f504`, knk-plugin `7f4bdd3a`). Deploy the API
   from `next` and apply the migration `AddMapRegionOutlines` (additive); deploy the plugin from `next`, paste
   `map:` / `reporting:` / `enabled: true` into `config.yml` (needs `realtime.enabled: true`) and follow smoke guide § 1
   (manual parts of steps 1–7). Optional: `@codex review` on knk-web-api#45, knk-plugin#76, knk-workspace#749 (Codex
   was at its usage limit).
2. **L2 (#736) smoke test (tier:3):** L2 is in `next` (knk-web-api `612ad62`). With the API from `next`, set
   `Map__Enabled=true` and follow smoke guide § 2 (new settings with defaults in production-installation § 4.3; no
   migration). Optional: `@codex review` on knk-web-api#46 and knk-workspace#751 (Codex at its limit / failed).
3. Known gates ahead (not blockers now):
   1. L3 (#737): the BlueMap scripting spike (spec § 9.6); if BlueMap's web app does not accept runtime marker sets
      and click listeners from a script, L3 stops and you decide the fallback.
   2. L3: the deploy notes (move the `bluemap-test` container into the `knk-alpha` Compose stack, Nginx `/bluemap/`)
      and the full-world render (about 20 hours) are yours to apply on the NAS; L3's live smoke steps wait for that.
   3. L5 (#739) is not merged into `next` before your live check of the L4 visibility steps (smoke § 4.1 steps 2, 3
      and 5), recorded on #738.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Region outlines | #735 | Merged into `next` 2026-11-18 (knk-web-api `562f504`, knk-plugin `7f4bdd3a`, knk-workspace `ac4b620f`); waiting for the developer's smoke test § 1 | `claude/overview-map-outlines`: knk-web-api `253a6ee`, knk-plugin `cf3a975a`, knk-workspace `e6e815dd` (from `next`) | [knk-web-api#45](https://github.com/PandiO/knk-web-api/pull/45), [knk-plugin#76](https://github.com/PandiO/knk-plugin/pull/76), [knk-workspace#749](https://github.com/PandiO/knk-workspace/pull/749) | API green; plugin build and paper-boot green | create_session session_01R1w2UuqJyStWv2zia5FTQg (2026-11-18, decision 3) |
| L2 Public map API | #736 | Merged into `next` 2026-11-18 (knk-web-api `612ad62`, knk-workspace `55d01897`); waiting for the developer's smoke test § 2 | `claude/overview-map-public-api`: knk-web-api `3a014f8`, knk-workspace `fcde4be8` (from `next`) | [knk-web-api#46](https://github.com/PandiO/knk-web-api/pull/46), [knk-workspace#751](https://github.com/PandiO/knk-workspace/pull/751) | API green on `3a014f8` (build-and-test, mysql-tests, fresh-database); knk-workspace no CI | create_session session_01R1w2UvvpPXaMVExy9eZZpL (2026-11-18) |
| L3 `/map` page | #737 | Running (spike first, spec § 9.6) | `claude/overview-map-page`: knk-web-app, knk-workspace (from `next`) | – | – | create_session session_01R1w2UtuNmGWaJ6a65D2YeS (2026-11-18) |
| L4 Live players backend | #738 | Running | `claude/overview-map-players-api`: knk-plugin, knk-web-api, knk-workspace (from `next`) | – | – | create_session session_01R1w2UwcYKiPMueCHWqsys4 (2026-11-18) |
| L5 Live players layer | #739 | Not started (gate: L3 and L4 merged, developer's L4 check) | – | – | – | – |
| L6 Staff details | #740 | Not started (gate: L3 merged into `next`) | – | – | – | – |
| L7 Gate commands backend | #741 | Not started (gate: L2 merged into `next`) | – | – | – | – |
| L8 Gate command buttons | #742 | Not started (gate: L3 and L7 merged into `next`) | – | – | – | – |
| L9 Player context panel | #743 | Not started (gate: L5 merged into `next`) | – | – | – | – |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from `next`, PRs target `next`, the coordinator merges
   into `next`), because on 2026-11-18 `.github/workflows/ci.yml` exists on `origin/main` of both knk-web-api and
   knk-web-app (skill § 1.3). Bases at the first run: knk-plugin `next` `1f414d08`, knk-web-api `next` `8ec54e1`,
   knk-web-app `next` `e7c9265`, knk-workspace `next` `afc4e09b`. Alternatives: (a) the old rules (default branch, the
   developer merges): not applicable once CI runs on both default branches.
2. **Overlap check for L1** (sessions board read from `origin/main` `145fadbb`, 2026-11-18). Chosen: no blocking
   overlap; L1 starts now. No "In progress" row has a running link in L1's areas: the off-road navigation chain (#698)
   has no link running and works in `core/roads/`, `core/navigation/`; the NPC follow-ups chain (#358) and chain 3
   follow-ups (#564) are in review, already merged into `next` (their region work, `TempRegionRetentionTask`,
   `WgRegionIdTaskHandler`, is in L1's base); the dashboard tables row (#608) waits for the developer's OK before
   building. Shared files L1 will touch additively: knk-plugin `KnKPlugin.java` (wiring), `config.yml` (new `map:`
   block), `plugin.yml` only if needed, the managed-region reconciler and `WorldGuardRegionRenamer` (one call each to
   report outlines); knk-web-api `Properties/KnKDbContext.cs` (one `DbSet` and its configuration), the game hub (one
   method), DI registration. L1 is told to keep to new files plus these additive hooks. The siege weapons design
   (#354 / #613) will reuse L3's bridge script later; that is not a file overlap now. Alternatives: (a) wait for the
   in-review chains to be promoted: no reason, their changes are already in `next`; (b) treat the shared hot files
   as a block: not needed, the edits are additive (developer decision 2026-11-12).
3. **Route for L1.** Chosen: `create_session` (knk-workspace source, Auto mode, same model as the coordinator), as the
   developer asked in the coordinator prompt; fallback a subagent of this coordinator with the same prompt (variant B)
   if the link's `add_repo` for knk-plugin or knk-web-api is refused or its dry run fails. Alternatives: (a) a subagent
   from the start, which skill § 4.1.4.2 suggests for links needing two repositories besides knk-workspace: the
   developer's own instruction takes precedence (skill § 1.1); (b) a session without Auto mode: it would ask the
   developer before other tool calls.

4. **L1 check and merge (2026-11-18).** Chosen: merge knk-web-api#45, knk-plugin#76 and knk-workspace#749 into `next`
   with merge commits (API first, the schema), because every check in skill § 6 held: heads matched, branches
   contained `next`, scope limited to the sub-issue (new files plus additive hooks), CI green on both code PRs
   (API build-and-test, mysql-tests, fresh-database; plugin build, paper-boot), tests above baseline, flag off by
   default, decisions logged, smoke § 1 tagged, #735 `status:in-review`. Codex was at its usage limit on all three PRs
   (noted on each; developer decision 2026-11-14). Alternatives: (a) wait for a Codex review after the limit resets:
   the rule says merge without it; (b) merge the API PR alone first: no benefit, the plugin side is off by default.
5. **Route for L2.** Chosen: `create_session` (one repository besides knk-workspace), as for L1, whose attach
   worked. Alternatives: (a) a subagent: only the fallback.

6. **L2 check and merge (2026-11-18).** Chosen: merge knk-web-api#46 and knk-workspace#751 into `next` with merge
   commits: every skill § 6 check held (heads matched, branch contained `next`, scope API-only plus docs, CI green
   build-and-test / mysql-tests / fresh-database, tests 4294 → 4333 with 0 failed, O32 field sets pinned by tests,
   `Map:Enabled` off by default, decisions logged, smoke § 2 tagged, #736 in review). Codex at its limit on #46 and
   failed on #751, noted on both. CI on `next` after L1: knk-web-api green; knk-plugin build green, paper-boot still
   running at merge time (L2 does not touch the plugin). Alternatives: (a) wait for the plugin's paper-boot on `next`
   before merging an API-only PR: no dependency between them.
7. **L3 and L4 in parallel.** Chosen: start both now, as the charter allows (L3 knk-web-app, L4 knk-plugin +
   knk-web-api; one link per component repo). Shared only knk-workspace (`CHANGELOG.md`, smoke guide § 3 / § 4, this
   report): each link keeps to its own entry, section, row and block. Route for both: `create_session`; L4 needs two
   repositories besides knk-workspace, where skill § 4.1.4.2 suggests a subagent, but L1's identical two-repo attach
   worked in this chain, and a subagent would block this coordinator's session for hours. Fallback: rerun as a
   subagent on a refused attach. Alternatives: (a) L4 as a subagent from the start; (b) run L3 and L4 one after the
   other: slower with no file overlap to justify it.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — Region outlines: plugin reports, API table `map_region_outlines` (#735)

1. **Scope done.**
    1. knk-web-api: model `MapRegionOutline`, table `map_region_outlines` (migration `AddMapRegionOutlines`, additive:
       one table, unique (WorldName, WgRegionId), index on DomainId, FK to `domains` SET NULL); `Services/Map/`
       `MapRegionOutlineService` (upsert by world and lower-case region id, removals, domain link through
       `Domain.WgRegionId` or `domain_sub_regions`, validation) and `MapOutlinePoints`; contracts
       `Realtime/Contracts/MapContracts.cs`; game hub method `ReportRegionOutlines` (one method); one `DbSet` and its
       configuration; one DI line.
    2. knk-plugin: knk-core `map/` (`RegionOutlinePort`, `RegionOutline`, `RegionRef`, `OutlinePoint`,
       `MapReportSender`, `MapReportingService`); knk-paper `map/` (`RegionOutlineAdapter` on WorldGuard,
       `MapReporting` wiring). Additive hooks: `ManagedRegionRepairService.setAfterRun`,
       `ManagedRegionsBootstrap.afterRepair`, `WgRegionIdTaskHandler.setRenameListener` (called after a successful
       rename), one resync hook in `KnKPlugin.initializeRealtime`, wiring in `KnKPlugin` next to the managed regions;
       `config.yml` `map.reporting.enabled: false`.
    3. knk-workspace: smoke guide § 1 (7 steps, all partly automated, tagged), plugin configuration reference § 4.29
       with § 2.1 and § 3 rows, changelog entry under "Unreleased", spec status line and § 6.1.1 stored shape.
2. **Commits and heads.** knk-web-api `claude/overview-map-outlines` at `253a6ee` (1 commit, base `next` at
   `8ec54e1`); knk-plugin `claude/overview-map-outlines` at `cf3a975a` (2 commits, base `next` at `1f414d08`);
   knk-workspace `claude/overview-map-outlines` at `e6e815dd` (1 commit, base `next` at `b1581488`). All up to date
   with `origin/next` at the time of the PRs.
3. **PRs.** [knk-web-api#45](https://github.com/PandiO/knk-web-api/pull/45),
   [knk-plugin#76](https://github.com/PandiO/knk-plugin/pull/76),
   [knk-workspace#749](https://github.com/PandiO/knk-workspace/pull/749) (`Closes #735`; the others `Part of`), base
   `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` 4277 passed, 100 skipped (MySQL, no `KNK_TEST_MYSQL`), 0 failed; branch 4294
       passed, 100 skipped, 0 failed (+17: `MapRegionOutlineServiceTests` 11, `AddMapRegionOutlinesTests` 4,
       `RealtimeHubTests` 2). CI on `253a6ee`: build-and-test, mysql-tests (migration on real MySQL) and
       fresh-database green.
    2. knk-plugin: baseline on `next` knk-core 3138, knk-api-client 344 (2 skipped), knk-paper 2953 (18 skipped), 0
       failed; branch 3151 / 344 (2 skipped) / 2957 (18 skipped), 0 failed (+17: `MapReportingServiceTest` 10,
       `ManagedRegionRepairServiceTest` 3, `RegionOutlineAdapterTest` 4). CI on `cf3a975a`: build green; paper-boot
       green (completed 2026-11-18 10:35 UTC).
    3. Known reds (also red on the base): none.
    4. Environment: Maven Central answered about 20 % of requests with 404 through this container's proxy, and Gradle
       caches the misses. Local plugin builds used the build's own repositories plus a scratchpad file repository of
       the reported-missing artifacts fetched from the same Maven Central URLs (local init script, not committed).
       The workspace's fast-check hook (plain Gradle) keeps failing on two cached Guava-dependency jars for that
       reason; GitHub CI is unaffected.
    5. Codex: at its usage limit on all three PRs (noted on each PR); no review, no findings handled.
5. **Decisions (DESIGN § 4.3).**
    1. *Hub argument shape.* Chosen: one object `{ outlines: [...], removed: [{wgRegionId, worldName}] }`, so a rename
       stores the new region and deletes the old name in one message. Alternatives: (a) a bare list (spec wording
       `ReportRegionOutlines(list)`): a rename would leave the temp name's row behind; (b) a second hub method for
       removals: one more access surface for no gain.
    2. *Domain link.* Chosen: the API resolves a nullable `DomainId` when it stores the row (main region or
       sub-region, a domain without a world matches any world), FK SET NULL; the plugin sends only world and region
       id. Alternatives: (a) the plugin sends the domain id: the repair's specs carry no id, and the API is the
       authority; (b) no link column: L2 would have to join on strings every time.
    3. *Rename hook location.* Chosen: `WgRegionIdTaskHandler.renameRegionInternal` after a successful
       `WorldGuardRegionRenamer.rename` (a listener setter, like the existing finalizers), because the renamer is a
       stateless static utility and the caller knows the world and the replaced region. Alternatives: (a) a static
       listener in `WorldGuardRegionRenamer` (the charter note's wording): global state in a pure helper; (b) the
       existing `RegionFinalizer` lambda: it gets neither the old name nor sub-region renames.
    4. *Startup hook location.* Chosen: an after-run listener on `ManagedRegionRepairService` (the repair that drives
       the reconciler), so startup and `/knk regions repair` both report. Alternatives: (a) inside
       `ManagedRegionReconciler`: it is also called per region on creation and knows nothing of "all domains".
    5. *Hub not connected yet.* Chosen: remember the last domain region set and resend it on every hub (re)connect
       through the realtime resync hooks. Alternatives: (a) queue failed messages: stale shapes; (b) report only at
       startup: lost when the repair finishes before the hub connects, or the API restarts.
    6. *Message size.* Chosen: split reports at about 24,000 characters (API keeps SignalR's 32 KB receive default);
       outlines over 1000 points are skipped and logged. Alternatives: (a) raise the API's
       `MaximumReceiveMessageSize`: a global hub change outside L1's additive scope.
    7. *Config keys.* Chosen: only `map.reporting.enabled` now. Alternatives: (a) also
       `map.reporting.interval-ticks` (O27): it is L4's player-report interval and nothing in L1 reads it.
    8. *Coordinates.* Chosen: WorldGuard's points as given (block coordinates, inclusive; a cuboid's four corners).
       Alternatives: (a) +1 on max edges for exact block borders: a rendering choice for L2/L3.
6. **Out of scope, noted.** [#750](https://github.com/PandiO/knk-workspace/issues/750): existing domain sub-regions
   are reported only when renamed, not at startup (the repair never sees sub-regions).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply the migration `AddMapRegionOutlines` (additive) with the API from `next`.
    2. To try it: paste into the plugin's `config.yml` (needs `realtime.enabled: true`), then smoke guide § 1:
       ```yaml
       map:
         reporting:
           enabled: true
       ```
    3. Optional: `@codex review` on the three PRs once the Codex limit resets.
9. **Notes for later links.**
    1. L2 reads `map_region_outlines`: `WgRegionId` (lower case), `WorldName`, `PointsJson` as `[[x,z],...]` (parse
       with `knkwebapi_v2.Services.Map.MapOutlinePoints.Parse`), `MinY`, `MaxY`, `DomainId` (nullable hint; the
       domain's own `WgRegionId` stays the authority), `UpdatedAt`. A domain's shape is its main region row plus its
       sub-region rows with the same `DomainId` (#750 for older sub-regions). Rows without a domain (stale or
       non-domain regions) should be ignored. The marker version (spec § 6.2.2) is L2's; L1 publishes no
       `EntityChanged` for outlines.
    2. L4 adds `map.reporting.interval-ticks` and the player report to `MapReportingService` (same class, spec § 7.1)
       and can reuse `MapReporting` for the wiring and `MapReportSender` for the hub.
    3. Hand edits to a region (`/rg redefine`) are reported at the next repair, not at once.

### 4.2 L2 — Public map API: config, markers, panel DTOs, `map` rate limit, access tests (#736)

1. **Scope done.**
    1. knk-web-api: `Controllers/MapController.cs` (`api/Map`, all `[AllowAnonymous]`: `config`, `markers`,
       `towns/{id}`, `districts/{id}`, `structures/{id}` with gate doors), the `[MapEnabled]` resource filter (404 before
       the action while `Map:Enabled` is off); `Dtos/MapDtos.cs` (O32 allow-list DTOs); `Services/Map/MapPublicService.cs`
       (`IMapPublicService`, `MapMarkerCache` singleton, `MapGeometry.Centroid`); `Configuration/MapOptions.cs`. Additive
       edits: the `map` policy in `RateLimitingSetup.cs`, three DI lines, `Map` and `RateLimiting:Map` in
       `appsettings.json`, five routes in `EndpointAccessRulesTests.AnonymousAllowList` and `ReadAccessRulesTests`
       (`P`). No migration.
    2. knk-workspace: smoke guide § 2 (7 steps: 2 automated, 5 partly automated, tagged), production installation
       § 4.3 (`Map__*`, `RateLimiting__Map__PermitPerMinute`), changelog entry, spec status line and § 6.2.8 as built.
2. **Commits and heads.** knk-web-api `claude/overview-map-public-api` at `3a014f8` (1 commit, base `next` at
   `562f504`); knk-workspace `claude/overview-map-public-api` at `fcde4be8` (1 commit, base `next` at `ac4b620f`). Both
   up to date with `origin/next` at the time of the PRs.
3. **PRs.** [knk-web-api#46](https://github.com/PandiO/knk-web-api/pull/46) (`Part of #736`),
   [knk-workspace#751](https://github.com/PandiO/knk-workspace/pull/751) (`Closes #736`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` 4294 passed, 100 skipped (MySQL, no `KNK_TEST_MYSQL`), 0 failed; branch 4333
       passed, 100 skipped, 0 failed (+39: `MapPublicServiceTests` 16, `MapPublicDtoFieldTests` 18,
       `MapControllerPipelineTests` 5; the two access tests extended). A03 and A06 run through the real controller,
       the real default-deny filter and the real rate limiter on a test server; A04 and A05 on an in-memory database,
       A05 also by reflection on every `Map*Dto`. Seen failing once: removing `[MapEnabled]` and adding a `wgRegionId`
       field each fail the tests (A06's 120 comes from the shipped `appsettings.json`, which the test host loads).
    2. Known reds: none.
    3. Codex: at its usage limit on knk-web-api#46 and failed on knk-workspace#751 (noted on both PRs); no review, no
       findings handled.
5. **Decisions (DESIGN § 4.3).**
    1. *Marker version.* Chosen: a short SHA-256 of the marker content; the built set is reused for
       `Map:Markers:CacheSeconds` (30 s), so a changed domain or outline gets a new version within that time.
       Alternatives: (a) bump on `EntityChanged` from the save interceptor: outline writes publish none (L1) and it
       hooks a shared file; (b) the newest `UpdatedAt`: misses domain renames.
    2. *Outline points (L1 note 5.8).* Chosen: served as stored (block coordinates, inclusive); the bridge draws them
       through the block centres (+0.5); a centroid pin already has +0.5. Alternatives: (a) +1 on max edges in the
       API: only right for cuboids, wrong for polygons.
    3. *Centroid pin height.* Chosen: `y: null`, the bridge picks the height. Alternatives: (a) `MaxY` or the middle
       of the range: a region up to the build limit puts the pin in the sky.
    4. *Domain shape.* Chosen: the main region row by the domain's own `WgRegionId` (any case, in its world when set),
       then rows linked by `DomainId` whose region id is still one of the domain's sub-regions; unlinked and stale rows
       ignored. The centroid uses the main region (else the first sub-region). Alternatives: (a) every row with the
       `DomainId`: a domain moved to another region would keep its old shape.
    5. *Door state.* Chosen: `openState` string of the effective state (`open`, `closed`, `opening`, `closing`,
       `jammed`; structure overrides applied), `isDestroyed` effective too. Alternatives: (a) a bool: loses jammed and
       the moving states.
    6. *Ids in public panels.* Chosen: none beyond the entity's own (district and town by name, no door ids), as the
       smoke draft says. Markers carry `townId` / `districtId` for the town toggle. Alternatives: (a) door ids for gate
       commands: L7/L8 read them from a staff route.
    7. *Under siege.* Chosen: `CurrentSiegeId` set and its match `Created` or `InProgress` (the rule of
       `SiegeMatchGateService`). Alternatives: (a) `CurrentSiegeId` alone: a stale pointer would show a siege.
    8. *Later parts in config.* Chosen: `livePlayers {enabled, pollIntervalMs}` and `gateCommands {enabled}` present
       and always off; no `Map:LivePlayers` / `Map:GateCommands` keys read yet. Alternatives: (a) read those flags now:
       turning one on before its phase exists would send the page to routes that answer 404; (b) leave the fields out:
       the spec lists enabled parts and the polling interval in § 6.2.1.
    9. *Disabled response.* Chosen: a resource filter on the controller returns 404 before model binding or the
       service (nothing is read). Alternatives: (a) remove the routes at startup: a settings reload would need a
       restart.
    10. *Layering.* Chosen: one service on `KnKDbContext`, like L1's `MapRegionOutlineService`. Alternatives: (a)
        repositories for read-only projections: more files, no reuse.
6. **Out of scope, noted.** None new. #750 (older sub-regions not reported) still limits district shapes.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing to keep it off. To try it: `Map__Enabled=true` in `/etc/knk/api.env`, then smoke guide § 2.
    2. Optional: `@codex review` on both PRs once the Codex limit resets.
9. **Notes for later links.**
    1. L3: `GET api/Map/config` then `GET api/Map/markers`; reload markers when `markerVersion` changes. Label distance
       `null` = every zoom. Draw outline points +0.5; a centroid pin has `y: null`. Districts carry `townId`,
       structures `townId` and `districtId`. Panels: `towns/{id}`, `districts/{id}`, `structures/{id}` (404 for an
       unknown id or another type). Door `openState` is lower case.
    2. L4: add `GET api/Map/players` to `MapController` (it inherits the `map` limit and the `[MapEnabled]` 404), set
       `config.livePlayers` from `Map:LivePlayers:*` in `MapPublicService.GetConfigAsync`, pin the route in both access
       tests and add its DTOs to `MapPublicDtoFieldTests.Pinned` (the test fails for an unpinned `Map*Dto`). Arena pins
       and `Map:Labels:Arena` are ready in config.
    3. L7: set `config.gateCommands.enabled` from `Map:GateCommands:Enabled`; the public panel has no door ids.
