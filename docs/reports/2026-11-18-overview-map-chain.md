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
3. **L3 (#737) NAS steps and smoke test (tier:2):** L3 is in `next` (knk-web-app `f551804d`). The BlueMap spike
   passed (v5.29, evidence on #737). On the NAS, apply closed-alpha runbook Phase 10 (move `bluemap-test` into the
   `knk-alpha` Compose stack, Nginx `/bluemap/`; knk-deploy, ask before each change), run the full-world render
   (about 20 hours), then set `Map__Enabled=true` and follow smoke guide § 3. Optional: `@codex review` on
   knk-web-app#50 (Codex at its limit).
4. Known gates ahead (not blockers now):
   1. L5 (#739) is not merged into `next` before your live check of the L4 visibility steps (smoke § 4.1 steps 2, 3
      and 5), recorded on #738.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Region outlines | #735 | Merged into `next` 2026-11-18 (knk-web-api `562f504`, knk-plugin `7f4bdd3a`, knk-workspace `ac4b620f`); waiting for the developer's smoke test § 1 | `claude/overview-map-outlines`: knk-web-api `253a6ee`, knk-plugin `cf3a975a`, knk-workspace `e6e815dd` (from `next`) | [knk-web-api#45](https://github.com/PandiO/knk-web-api/pull/45), [knk-plugin#76](https://github.com/PandiO/knk-plugin/pull/76), [knk-workspace#749](https://github.com/PandiO/knk-workspace/pull/749) | API green; plugin build and paper-boot green | create_session session_01R1w2UuqJyStWv2zia5FTQg (2026-11-18, decision 3) |
| L2 Public map API | #736 | Merged into `next` 2026-11-18 (knk-web-api `612ad62`, knk-workspace `55d01897`); waiting for the developer's smoke test § 2 | `claude/overview-map-public-api`: knk-web-api `3a014f8`, knk-workspace `fcde4be8` (from `next`) | [knk-web-api#46](https://github.com/PandiO/knk-web-api/pull/46), [knk-workspace#751](https://github.com/PandiO/knk-workspace/pull/751) | API green on `3a014f8` (build-and-test, mysql-tests, fresh-database); knk-workspace no CI | create_session session_01R1w2UvvpPXaMVExy9eZZpL (2026-11-18) |
| L3 `/map` page | #737 | Merged into `next` 2026-11-18 (knk-web-app `f551804d`, knk-workspace `0f0f8e7f`); waiting for the NAS deploy notes (runbook Phase 10), the full-world render and the developer's smoke test § 3 | `claude/overview-map-page`: knk-web-app `ee9a68d`, knk-workspace `23b028dc` (from `next`) | [knk-web-app#50](https://github.com/PandiO/knk-web-app/pull/50), [knk-workspace#753](https://github.com/PandiO/knk-workspace/pull/753) | web app green on `ee9a68d` (build-and-test, e2e); knk-workspace no CI | create_session session_01R1w2UtuNmGWaJ6a65D2YeS (2026-11-18) |
| L4 Live players backend | #738 | In review 2026-11-18 (PRs open, not merged; waiting for the developer's live check of smoke § 4.1 steps 2, 3 and 5 before L5's merge) | `claude/overview-map-players-api`: knk-web-api `a9ed3af`, knk-plugin `8b1efdcc`, knk-workspace `09982caa` (from `next`) | [knk-web-api#47](https://github.com/PandiO/knk-web-api/pull/47), [knk-plugin#77](https://github.com/PandiO/knk-plugin/pull/77), [knk-workspace#752](https://github.com/PandiO/knk-workspace/pull/752) | API green (build-and-test, mysql-tests, fresh-database); plugin build and paper-boot green | create_session session_01R1w2UwcYKiPMueCHWqsys4 (2026-11-18) |
| L5 Live players layer | #739 | Not started (gate: L3 and L4 merged, developer's L4 check) | – | – | – | – |
| L6 Staff details | #740 | Running | `claude/overview-map-staff-details`: knk-web-app, knk-workspace (from `next`) | – | – | subagent of the coordinator (2026-11-18; the create_session attempt session_01R1w2UuaEs6VbL7BVnR7ZTJ was refused the knk-web-app attach, decision 10) |
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

8. **L3 check and merge (2026-11-18).** Chosen: merge knk-web-app#50 and knk-workspace#753 into `next` with merge
   commits: every skill § 6 check held (heads matched, branch contained `next`, scope web app plus deploy notes and
   docs, nothing applied to the NAS, CI green build-and-test and e2e, Jest 2672 → 2699 and Playwright 149 → 160 with
   the real `bridge.js` in a fake BlueMap, spike evidence on #737, smoke § 3 tagged, #737 in review). Codex at its
   limit on #50, noted. Alternatives: (a) hold the merge until the NAS render exists: the live steps are the
   developer's test of `next`, not a merge gate.
9. **L6 started after L3.** Chosen: start L6 (#740, knk-web-app) now; L5 (needs L3, L4 and the developer's L4
   visibility check) cannot start yet, and L6's only gate is L3. Route `create_session` (one repository besides
   knk-workspace). Alternatives: (a) wait and run L5 first in charter order: L5's gate is closed.

10. **L6 rerun as a subagent.** The `create_session` link (session_01R1w2UuaEs6VbL7BVnR7ZTJ) was refused
    `add_repo` for knk-web-app by Auto mode's classifier ("[Unauthorized Access]") and stopped without changes.
    Chosen: rerun L6 as a subagent of this coordinator with the same prompt (variant B, worktrees under the
    coordinator's scratchpad), per skill § 4.1.4.3. Alternatives: (a) retry the attach in that session: the skill
    forbids it; (b) start a new session in a non-Auto mode: it would ask the developer before other tool calls.
    Lesson: the classifier is not consistent (L1–L4 attaches worked); later single-repo links still try
    `create_session` first.

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

### 4.3 L3 — `/map` page, BlueMap bridge, pins, flash and toggle, public panels, action registry (#737)

1. **Spike (spec § 9.6, charter gate 3): passed.** BlueMap **v5.29** (tag `v5.29`, commit `a61e143f`, 2026-10-10;
   image `ghcr.io/bluemap-minecraft/bluemap:v5.29@sha256:bb49bfde…301e`). Evidence from the web app source at that tag,
   posted on [#737](https://github.com/PandiO/knk-workspace/issues/737#issuecomment-6976627917): `BlueMapApp.load()`
   appends a `<script>` per `webapp.conf` `scripts` entry after the maps load; `main.js` exposes `window.bluemap` and
   `window.BlueMap` (with `MarkerSet`, `HtmlMarker`, `ExtrudeMarker`, …); `new BlueMap.MarkerSet(id)` added to
   `bluemap.mapViewer.markers` takes `updateMarkersFromData` at runtime; clicks reach `elementObject.onClick` (HTML/POI
   markers, `CSS2DRenderer.js`) and `onClick` (extrude, raycast); camera through `controlsManager` and the
   `bluemapCameraMoved` / `bluemapMapChanged` events; postMessage to the parent works from the script. One caveat
   found and handled: BlueMap's `NormalMarkerManager` reloads `live/markers.json` every 10 s and removes every root
   marker set that file doesn't list; the bridge wraps the root's `updateMarkerSetsFromData` to add its own set ids to
   the ignore list (tested).
2. **Scope done.**
    1. knk-web-app: `pages/map/MapPage.tsx` (public route `/map`); `components/map/`: `BlueMapFrame`,
       `bridgeProtocol.ts` (v1 envelopes, page-side origin/source/version guard), `mapMarkers.ts` (markers → bridge
       payload, +0.5), `MapPanel` (side panel, bottom sheet on phones), `mapActionRegistry.ts`,
       `defaultMapRegistrations.ts`, `widgets/` (town with "Show region", district, structure, `GateDoorsWidget`),
       `useMapAvailability`; `apiClients/mapClient.ts`, `types/dtos/map/MapDtos.ts`; `public/bluemap-bridge/bridge.js`.
       Additive edits: `routeTable.ts` (route `map`, `MAP_ROUTE_ID`), `Navigation.tsx` (one filter), `LandingPage.tsx`
       (one link), `App.tsx`, `utils/enums.ts`, `e2e/fixtures/auth.ts` (`mockSession` answers `Map/config` 404),
       `README.md` (`REACT_APP_BLUEMAP_URL`).
    2. knk-workspace: closed-alpha runbook **Phase 10** (deploy notes, not applied: `bluemap-test` → profile-gated
       `bluemap` render service, nginx serves `web/` under `/bluemap/`, `webapp.conf` bridge and
       `client-decompression`, version pin, rollback); `scripts/alpha-web/compose.bluemap-service.yaml` (new),
       `nginx.conf` `location /bluemap/` (checked with `nginx -t` and a scratch nginx), README row; smoke guide § 3
       (11 steps: 1 automated, 9 partly automated, 1 manual only, tagged); changelog entry; spec status and § 6.3.5 as
       built; production installation § 4.3 note.
3. **Commits and heads.** knk-web-app `claude/overview-map-page` at `ee9a68d` (2 commits, base `next` at `e7c9265`);
   knk-workspace `claude/overview-map-page` at `23b028dc` (1 commit, base `next` at `55d01897`). Both up to date with
   `origin/next` at the time of the PRs.
4. **PRs.** [knk-web-app#50](https://github.com/PandiO/knk-web-app/pull/50) (`Part of #737`),
   [knk-workspace#753](https://github.com/PandiO/knk-workspace/pull/753) (`Closes #737`), base `next`. Not merged.
5. **Tests, baseline → result.**
    1. knk-web-app: Jest baseline 308 suites / 2672 tests → 313 / 2699, all green (+27: `bridgeProtocol` 8,
       `mapMarkers` 5, `mapActionRegistry` 7 (A22), `GateDoorsWidget` 4, `useMapAvailability` 3; the `routeTable` pins
       updated for the new route). Playwright 149 → 160 passed (+11 in `e2e/overview-map.spec.ts`, A07–A10; 4 repeats
       green). The specs serve a fake BlueMap web app that loads the **real** `bridge.js` (map ids named like the NAS
       render, so the `?worlds=` mapping runs too). `tsc`, `typecheck:e2e`, `CI=true npm run build` clean. CI on `ee9a68d` green (build-and-test, e2e; push and pull_request runs).
    2. knk-workspace: docs only; links and anchors checked by hand.
    3. Known reds: none.
    4. Codex: at its usage limit on knk-web-app#50 (review failed for `ee9a68d`); noted on both PRs; no findings
       handled.
6. **Decisions (DESIGN § 4.3).**
    1. *Keeping the bridge's markers.* Chosen: wrap the root marker set's `updateMarkerSetsFromData` so BlueMap's
       10 s marker-file reload ignores the bridge's sets. Alternatives: (a) re-add the sets after each reload: pins
       blink every 10 s; (b) write our markers into BlueMap's `markers.json`: a writer on the NAS and no live updates.
    2. *Pin drawing.* Chosen: two HTML markers per pin, a dot always and the label with the API's `maxDistance`.
       Alternatives: (a) BlueMap POI markers: need an icon file and show the label BlueMap's way; (b) one HTML marker:
       the label distance would hide the pin as well.
    3. *World ↔ BlueMap map.* Chosen: `bridge.js?worlds=<mapId>:<world>` in `webapp.conf`; a map id equal to the world
       name needs none. Alternatives: (a) rename the NAS map config to the world name: moves the tile folder (re-render);
       (b) an API setting: a new key in another link's repo.
    4. *Hosting.* Chosen: nginx serves BlueMap's static `web/` (`client-decompression: true`, 204 for unrendered tiles);
       BlueMap runs as a profile-gated render job on the same folders. Alternatives: (a) keep BlueMap's own web server
       (`-w`) and proxy to it: a second long-running server, and the spec has nginx serve `web/`; (b) watch mode
       (`-u`): the world is a snapshot copy, nothing to watch.
    5. *Framing.* Chosen: `X-Frame-Options: SAMEORIGIN` on `/bluemap/` only; the site keeps `DENY`. Alternatives:
       (a) a CSP `frame-ancestors`: the site has no CSP yet.
    6. *Signed-out entry.* Chosen: a map link on the start page, because the signed-out site has no top bar; signed in
       the bar has "Map"; both only while the map is on. Alternatives: (a) show the bar signed out: changes the public
       site's layout.
    7. *Staff widgets and actions.* Chosen: hidden without their node (anonymous viewers never see them).
       Alternatives: (a) the #280 rule, disabled with "Requires <node>": staff buttons for every anonymous visitor.
    8. *Marker version check.* Chosen: `config` every 60 s, markers reloaded when `markerVersion` changes.
       Alternatives: (a) no re-check: rule 2 asks for the reload; (b) every 10 s: the API's cache is 30 s anyway.
    9. *Centroid pin height.* Chosen: BlueMap's `terrainHeightAt`, retried while tiles load, else Y 64. Alternatives:
       (a) the region's `maxY`: L2 rejected it (pins in the sky).
    10. *Toggle.* Chosen: towns only (O05), one at a time (bridge group `town-toggle`), kept when the panel closes.
        Alternatives: (a) a toggle per district: not in the design.
    11. *`setPlayers` now.* Chosen: the bridge already draws name labels and reports `playerClicked`, so L5 changes
        no bridge message. Alternatives: (a) leave it to L5: L5 would change the bridge script.
    12. *Other specs.* Chosen: `mockSession` answers `Map/config` with 404 (map off). Alternatives: (a) mock it in each
        spec: every strict spec would need it.
    13. *nginx.conf.* Chosen: edit `scripts/alpha-web/nginx.conf` directly (inert without the mount: 404).
        Alternatives: (a) a snippet in the docs only: easy to miss at the next image build.
7. **Out of scope, noted.** None new. Player guide and site pages: follow-up in the docs issue at merge.
8. **Blockers.** None.
9. **At merge / what the developer must do.**
    1. Nothing to keep it off (`Map__Enabled` stays false: no map anywhere in the web app).
    2. On the NAS (`knk-deploy`, ask before each change): closed-alpha runbook Phase 10, then the full-world render
       (about 20 h). Check the game world name for `?worlds=` (the NAS map id is `overworld`).
    3. Then `Map__Enabled=true` and smoke guide § 3 (the live steps wait for step 2).
    4. Optional: `@codex review` on both PRs once the Codex limit resets.
10. **Notes for later links.**
    1. L5: `setPlayers {players: [{uuid, label, world, x, y, z}]}` exists; the bridge draws `.knk-player` labels and
       posts `playerClicked {uuid}`, which `MapPage.onBridgeMessage` ignores today (wire it there). Add optional
       payload fields (tags, colours) rather than new meanings. `arena` is already a `MapEntityKind`; add arena pins in
       `mapMarkers.toBridgeMarkers` with `labels.arena`.
    2. L6: `mapActionRegistry.addWidget('structure', 'staff', { id, node: 'knk.admin.world', Component })` (and per
       kind); the panel checks nodes only for registered staff entries, so anonymous viewers make no permission calls.
    3. L8: `mapActionRegistry.addAction('structure', { id, label, node: 'knk.gate.admin', visible: d => d.gate !== null,
       run: async (d, ctx) => { …; ctx.reload(); } })`. `MapPanelContext` has no map config yet; add
       `gateCommands.enabled` to it if the buttons must follow the flag. Door ids are not in the public panel (L2).
    4. L9: add a `player` registration once `playerClicked` is wired (L5); `MapEntityKind` and `parseBridgeMessage`
       need the new kind only if players come through `markerClicked`.
    5. The bridge protocol v1 is frozen (O14): #613 adds message types or a new version.

### 4.4 L4 — Live players backend: plugin reports, per-audience snapshots, arena pins (#738)

1. **Scope done.**
    1. knk-web-api: game hub `ReportMapPlayers` (one method; `PlayerLeft` one line to drop the player);
       `Services/Map/MapPlayerRegistry` (latest report per player, three missed intervals, fail-closed unknown mode),
       `Services/Map/MapPlayerSnapshots` (three audience snapshots per tick, `MapPlayerLabels` as `ChatLineFormat`,
       label cache), `Services/Map/MapLivePlayerData` (labels from `IUserService.GetByUuidAsync` and the `knk.mode.*`
       rank, arena pins from running `SiegeMatch` rows at the objective gate's marker pin); `GET api/Map/players` on
       `MapController` (anonymous, `map` limit, `[MapEnabled]`, 404 while `Map:LivePlayers:Enabled` is off,
       `no-store`); `config.livePlayers` from `Map:LivePlayers:*`; DTOs `MapPlayersDto`, `MapPlayerDto`,
       `MapPlayerLabelDto`, `MapArenaDto`; settings `Map:LivePlayers:Enabled` (false), `PollIntervalMs` (2000),
       `LabelCacheSeconds` (60). Additive: three DI lines, `appsettings.json` `Map:LivePlayers`, the route in both
       access tests, the DTOs in `MapPublicDtoFieldTests.Pinned` (plus one reviewed name exception, `MapPlayerDto.uuid`).
       No migration.
    2. knk-plugin: knk-core `map/OnlinePlayerSnapshotPort`, `OnlinePlayerPosition`, the player report in
       `MapReportingService`; knk-paper `map/PaperOnlinePlayerSnapshot` and `MapReporting.startPlayerReports`
       (main-thread snapshot timed as `map.player_snapshot`, async send). Additive: `KnKPlugin` (suppliers in the
       existing `MapReporting.create` call, one start line after `initializeRealtime`), `SiegeService.runningMatchApiId`,
       `config.yml` `map.reporting.interval-ticks: 40`.
    3. knk-workspace: smoke guide § 4 (9 steps: 1 automated, 5 partly automated and tagged, steps 2, 3 and 5 full
       manual), plugin configuration § 4.29 and § 2.1 row, production installation § 4.3, changelog entry, spec status
       line, § 6.2.9 and § 7.4 as built.
2. **Commits and heads.** knk-web-api `claude/overview-map-players-api` at `a9ed3af` (1 commit, base `next` at
   `612ad62`); knk-plugin `claude/overview-map-players-api` at `8b1efdcc` (1 commit, base `next` at `7f4bdd3a`);
   knk-workspace `claude/overview-map-players-api` at `09982caa` (1 commit, base `next` at `55d01897`). All up to date
   with `origin/next` at the time of the PRs.
3. **PRs.** [knk-web-api#47](https://github.com/PandiO/knk-web-api/pull/47),
   [knk-plugin#77](https://github.com/PandiO/knk-plugin/pull/77) (both `Part of #738`),
   [knk-workspace#752](https://github.com/PandiO/knk-workspace/pull/752) (`Closes #738`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` 4333 passed, 100 skipped (MySQL, no `KNK_TEST_MYSQL`), 0 failed; branch 4372
       passed, 100 skipped, 0 failed (+39: `MapPlayersPipelineTests` 7, `MapPlayerSnapshotsTests` 10,
       `MapPlayerRegistryTests` 6, `MapPlayerLabelsTests` 5, `MapLivePlayerDataTests` 4, `RealtimeHubTests` 3,
       `MapPublicDtoFieldTests` 4). Each audience's raw response body is checked through the real controller,
       default-deny filter, JWT bearer and rate limiter (A12, A14). Seen failing: removing the visibility filter fails
       4 tests. CI on `a9ed3af`: build-and-test, mysql-tests and fresh-database green.
    2. knk-plugin: baseline on `next` knk-core 3151, knk-api-client 344 (2 skipped), knk-paper 2957 (18 skipped), 0
       failed; branch 3161 / 344 (2 skipped) / 2963 (18 skipped), 0 failed (+16: `MapReportingServicePlayersTest` 10,
       `PaperOnlinePlayerSnapshotTest` 6). CI on `8b1efdcc`: build green; paper-boot green (completed 2026-11-18 11:54 UTC).
    3. Known reds (also red on the base): none.
    4. Environment: Maven Central through this container's proxy again answered some requests with 404 (L1's note).
       Local plugin builds used a scratchpad retry mirror (a small local HTTP server retrying Central and the Gradle
       plugin portal, plus an init script; not committed). Baselines ran in a separate worktree of `origin/next`.
       MockBukkit's `waitAsyncTasksFinished` cancels repeating tasks, so the scheduler test polls for the async send.
    5. Codex: at its usage limit on all three PRs (noted on each PR); no review, no findings handled.
5. **Decisions (DESIGN § 4.3).**
    1. *Snapshot tick.* Chosen: built lazily on the first request after `PollIntervalMs` ran out, one build at a time
       (`SemaphoreSlim`), all three audiences in one build; requests answer from the stored set (O21). Alternatives: (a)
       a background timer building every tick: works while nobody watches; (b) filtering per request: O21 rules it out.
    2. *Audience check.* Chosen: `IPermissionReadCache.HoldsAnyAsync` with `knk.mode.staff` / `knk.mode.owner` (30 s
       cache, wildcards via the resolver); a missing or invalid token is anonymous. Alternatives: (a) uncached
       `CheckAnyAsync`: a database read per 2 s poll per viewer; (b) a JWT claim: tokens carry no nodes.
    3. *Logged-in snapshot.* Chosen: built separately with the same content as the anonymous one (O08 is superseded
       by O31, nothing differs today). Alternatives: (a) serve the anonymous object to logged-in viewers: the spec
       names three snapshots and a later difference would need a new code path.
    4. *Match players in the "may see hidden" snapshot.* Chosen: listed with a `minigame` tag (spec § 5 rule 8: left
       out of every snapshot except that one). Alternatives: (a) left out everywhere (the sub-issue's shorter wording):
       the spec rule is the binding one.
    5. *Unknown mode value.* Chosen: hidden (tag `hidden` for staff viewers). Alternatives: (a) treat as no mode: a
       future mode would leak to the public.
    6. *Label data.* Chosen: `IUserService.GetByUuidAsync` (title, tier, group colours with group ids, the data behind
       the chat line) and the rank by `knk.mode.owner` / `knk.mode.staff`, as `PlayerListener`; the plugin's fixed
       owner/staff/default colours mirrored as `&` codes; cached per player for `LabelCacheSeconds` (60). A UUID
       without an account gets its presence name in default colours. Alternatives: (a) the plugin sends the label: the
       spec puts label parts in the API (O23); (b) no cache: about five queries per player every tick.
    7. *Arena pin.* Chosen: one pin per running match (`SiegeMatch` created or in progress, as L2's "under siege") at
       the first objective gate (by `SortOrder`) with a marker pin, else the scenario's lowest gate id with one; no pin
       (logged once) otherwise; count = reported players with that match id. Tag "Siege", label
       "[Siege] n players" ("1 player" singular). Alternatives: (a) the objective's `Location`: siege objectives in
       use are gates and the markers already resolve gate pins; (b) the match's roster count: O24 says live
       participants.
    8. *Minigame id.* Chosen: two fields, `minigame` (`siege`) and `matchId` (the API's `SiegeMatch` id from
       `SiegeService.runningMatchApiId`; null until the API answered the start, then the player is still hidden but
       no pin is drawn). "In a running match" = lobby phase `IN_PROGRESS` and on the roster (`runningMatchOf`);
       hub-phase lobby members still show. Alternatives: (a) the match token: the API stores no token; (b) hide
       lobby members at the hub too: O13 speaks of a running match.
    9. *Report shape and size.* Chosen: `{intervalMs, players: [...]}`, positions to 0.1 block, yaw whole degrees,
       split below L1's 24,000-character budget (260 characters per player assumed); upsert per player in the API, so
       split messages need no "complete set" marker; one empty report when the server empties. Alternatives: (a)
       replace a server's set per message: a split report would drop players; (b) send every interval even when empty:
       needless traffic.
    10. *`interval-ticks` bounds.* Chosen: clamped to 10..1200 in the plugin, the API clamps the interval to
        0.5..60 s for the drop rule. Alternatives: (a) unbounded: 1 tick would report 20 times a second.
    11. *Hub flag check.* Chosen: the hub ignores reports while `Map:LivePlayers:Enabled` is off, so nothing is held.
        Alternatives: (a) keep them anyway: memory for a disabled feature.
    12. *Route wiring.* Chosen: the action resolves `MapPlayerSnapshots` and the options from request services, so
        `MapController`'s constructor (and L2's pipeline tests) stay unchanged. Alternatives: (a) constructor
        injection: L2's tests would need the new services registered.
    13. *uuid in a public DTO.* Chosen: `MapPlayerDto.uuid` (the head and L9's player panel need it; a Minecraft UUID is
        public), as a reviewed exception in `NoPublicMapDto_NamesARegionOwnerOrPermission`. Alternatives: (a) name
        only: heads by name break on renames and L9 needs a stable id.
6. **Out of scope, noted.** None new.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing to keep it off; no migration.
    2. The live check of smoke § 4.1 steps 2, 3 and 5 (visibility) on #738 before L5 is merged: API from `next` with
       `Map__Enabled=true` and `Map__LivePlayers__Enabled=true`; plugin `config.yml`:
       ```yaml
       map:
         reporting:
           enabled: true
           interval-ticks: 40
       ```
       (needs `realtime.enabled: true`), then smoke guide § 4.
9. **Notes for later links.**
    1. L5: poll `GET api/Map/players` every `config.livePlayers.pollIntervalMs` (only when `config.livePlayers.enabled`).
       Draw `players` by `uuid` (head) with `label` parts: `[rankTag]` in `bracketColor`/`textColor`, `-{braced}-`
       (bold when `bracedBold`), `name`; colours are the `&` code strings as the groups store them (the plugin
       parses the same strings with `LegacyStyles`). Tags: `afk`, `mode` (`staff`, `owner`, `hidden`), `minigame`
       (`Siege`) — the last two only reach staff viewers. `arenas[]` have `label`, `playerCount` and a `pin` like the
       markers (`y` may be null); label distance `config.labels.arena`. Send the JWT when logged in: it selects the
       audience. Responses are `no-store`.
    2. L7: `GameServerHub` now also has `ReportMapPlayers`; `MapController` has `GetPlayers`. `MapOptions` has a
       `LivePlayers` block; add `GateCommands` beside it.
    3. L9: `MapPlayerDto.uuid` is the player's Minecraft UUID (lower case), for the moderation panel.
