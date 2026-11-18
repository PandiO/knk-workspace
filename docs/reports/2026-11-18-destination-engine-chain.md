# Navigation destination engine chain — progress report

**Status:** Running (2026-11-18) · **Last updated:** 2026-11-18

**Issue:** [PandiO/knk-workspace#25](https://github.com/PandiO/knk-workspace/issues/25), links
[#96](https://github.com/PandiO/knk-workspace/issues/96) (L1),
[#103](https://github.com/PandiO/knk-workspace/issues/103) (L2),
[#69](https://github.com/PandiO/knk-workspace/issues/69) (L3),
[#62](https://github.com/PandiO/knk-workspace/issues/62) (L4),
[#747](https://github.com/PandiO/knk-workspace/issues/747) (L5),
[#55](https://github.com/PandiO/knk-workspace/issues/55) (L6).
**Charter:** [handoffs/DESTINATION_ENGINE_CHAIN.md](../ai-agents/handoffs/DESTINATION_ENGINE_CHAIN.md).
**Coordinator:** session_01R1w2UvZSm3y5hAXB8VfYuv (cloud).

## 1. Waiting for the developer

1. **Live test of P3 and P4 (gate of L5, #747).** L1–L4 are in `next` (knk-plugin `3e04ba8f`, knk-web-api `6094276d`,
   knk-workspace `9db3df91`). Deploy API and plugin from `next`; in `config.yml` under `navigation:` set
   `destination-engine: true` (and `destinations.stale-after-days: 14`, optional); restart; grant `knk.navigate.any` to
   the Bypass test account; run smoke § 3 and § 4 (§ 4 needs the Opponent and Senior Staff accounts too); say on #25 or
   #62 that they passed (or what failed). Set the flag back to `false` afterwards if wanted.
2. **Timing of L6 (#55, arena duels provider).** Gate: L5 merged and the arena duels work (KNG-197) in `next`; I will ask
   on #25 before starting it.
3. **Out of scope from L3, to decide or file:** `/knk road` status showing the navigation model's age; a knk-web-api rank
   seed for `knk.navigate.any`.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 P1 pure engine in knk-core | #96 | Merged into next (2026-11-18) | `claude/navigation-destination-engine`: knk-plugin `64ca8815`, knk-workspace `7eb86cc3` | [knk-plugin#78](https://github.com/PandiO/knk-plugin/pull/78) (merge `1105ec15`), [knk-workspace#754](https://github.com/PandiO/knk-workspace/pull/754) (merge `732ba191`) | build + paper-boot green on the PR; Codex skipped (usage limit) | create_session session_01R1w2Uw3gPf2REJMYZEGE6a |
| L2 P2 model, snapshot, domain search Location | #103 | Merged into next (2026-11-18) | `claude/navigation-destination-engine`: knk-web-api `a49fba23`, knk-plugin `61fe656a`, knk-workspace `30894797` | [knk-web-api#49](https://github.com/PandiO/knk-web-api/pull/49) (merge `6094276d`), [knk-plugin#80](https://github.com/PandiO/knk-plugin/pull/80) (merge `2f1c783e`), [knk-workspace#760](https://github.com/PandiO/knk-workspace/pull/760) (merge `560dd839`) | API build-and-test, mysql-tests, fresh-database green; plugin build + paper-boot green; Codex skipped (usage limit) | subagent of the coordinator (two repos besides knk-workspace, SKILL § 4.1.4 item 2) |
| L3 P3 switch-over behind the flag | #69 | Merged into next (2026-11-18) | `claude/navigation-destination-engine`: knk-plugin `03ec14ce`, knk-workspace `9dda7c92` | [knk-plugin#81](https://github.com/PandiO/knk-plugin/pull/81) (merge `073fa4cf`), [knk-workspace#761](https://github.com/PandiO/knk-workspace/pull/761) (merge `d484361e`) | build + paper-boot green on the PR; Codex skipped (usage limit) | create_session session_01R1w2UvmCT8TsW9NNue38Vg |
| L4 P4 hard blocks as scopes, live re-validation | #62 | Merged into next (2026-11-18) | `claude/navigation-destination-engine`: knk-plugin `d38fb46c`, knk-workspace `0b1274d4` | [knk-plugin#82](https://github.com/PandiO/knk-plugin/pull/82) (merge `3e04ba8f`), [knk-workspace#762](https://github.com/PandiO/knk-workspace/pull/762) (merge `9db3df91`) | build + paper-boot green on the PR; Codex skipped (usage limit) | create_session session_01R1w2Ux1p4b4KMqSayuzntM |
| L5 phase 4b removal of old paths and the flag | #747 | Waiting: developer's live test of smoke § 3 and § 4 with the flag on (gate); off-road L10 step 2 #712 holds the plugin navigation slot since 17:45 | — | — | — | — |
| L6 P5 arena duels provider and scope | #55 | Not started | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from or merge in `next`, PRs target `next`, the
   coordinator merges into `next`), because `.github/workflows/ci.yml` is on `origin/main` of both knk-web-api and
   knk-web-app (checked 2026-11-18). Alternatives: (a) old rules (developer merges) — not applicable once CI runs.
2. **Gate of L1.** Open: DESIGN on knk-workspace `next` has status "Decided 2026-11-18"; knk-plugin
   `claude/navigation-destination-engine` is at `ea368a8b` as the charter says (1 commit ahead of `next` `7f4bdd3a`,
   369 behind). Alternatives: none.
3. **Overlap check before L1 (charter § 2.2, § 2.3).** Board read fresh from `origin/main` 2026-11-18. Chosen: start
   L1 now. The off-road chain (#698) has no link running (its row: "Waiting for the developer", L8 waits for #96, #103,
   #69), and L1 only changes knk-core destination-engine code. The overview map chain (#732) has L3/L4 running in
   knk-plugin map reporting, not navigation; no shared lines. The NPC navigation follow-ups chain (#358) is in review
   with no link running. Order agreed by message with the off-road coordinator (session_01R1w2UuBBnWjqekMFxEMefN).
   Alternatives: (a) wait for the off-road live tests — not needed, no off-road link runs; (b) run L1 as a subagent —
   not needed, L1 needs only knk-plugin besides knk-workspace.
4. **Route for L1.** Chosen: create_session with variant A of the permissions block, because L1 needs one repository
   besides knk-workspace (SKILL § 4.1.4 item 2). Alternatives: (a) subagent (variant B) — the fallback if `add_repo` is
   refused.
5. **Parallel L2 API part.** Chosen: not yet; L2 starts as one link (API and plugin) after L1 is merged, because
   knk-web-api work is small (a DTO field and an `Include`) and one link per issue keeps the check simple.
   Alternatives: (a) start the knk-web-api part now as a separate session, which the charter allows — revisit if L1
   runs long.

6. **L1 check (2026-11-18).** Chosen: merge knk-plugin#78 into `next` (merge `1105ec15`) after the § 6 checks: heads
   match, `next` moved by two overview-map commits during the link but `git merge-tree` showed no conflict and the
   files do not overlap, PR CI `build` and `paper-boot` green, scope only `core/navigation/destinations/` and
   `ArchitectureGuardTest`, knk-core 3 151 → 3 221 with 0 failures, decisions logged, Codex at its usage limit (rule 4
   exception, noted on the PR). knk-workspace#754 was sent back once for a missing changelog entry (the other chains'
   links ship one with the feature), then merged (`732ba191`). Alternatives: (a) merge #754 without the entry and add
   it at the end of the chain — rejected, the global rules ship the changelog entry with the feature; (b) write the
   entry myself — rejected, the coordinator does not implement and the link session was idle with full context.
7. **Order with the off-road chain (2026-11-18, by message with session_01R1w2UuBBnWjqekMFxEMefN).** Chosen: L1 then
   L2 run now; when an off-road link (L10 step 2 on #712 or L5 #705) becomes ready, it gets the window after L2 and
   before L3, and I hold L3 until it is merged into `next`. I tell that coordinator when L2 and when L3 are merged (L3
   opens its L8 #708). Alternatives: (a) run L1–L3 back to back first — delays off-road work that waits only on the
   developer; (b) let the off-road links go before L2 — neither was ready.
8. **Route for L2.** Chosen: a subagent of this session (variant B), because L2 changes two repositories besides
   knk-workspace (SKILL § 4.1.4 item 2). Scope follows the charter and DESIGN § 10 over the October text of #103:
   the providers reading the model (`CatalogueProvider`, `CompassTargetsProvider`) belong to L3. Alternatives: (a)
   create_session with two `add_repo` calls — refused attaches were seen with several repos; (b) split L2 into an API
   and a plugin session — the API part is small and one link per issue keeps the check simple.
9. **L2 check (2026-11-18).** Chosen: merge knk-web-api#49 and knk-plugin#80 into `next` after the § 6 checks: heads
   match, 0 behind `next`, no conflicts, CI green on both (API build-and-test, mysql-tests, fresh-database; plugin
   build, paper-boot), `next` CI green before the merge (paper-boot on `02aa110e`), scope as the sub-issue (API: DTO,
   mapping, `Include`, tests; plugin: new `core/navigation/model/` and `paper/navigation/model/`, additive lines in
   `KnKPlugin`, `config.yml`, the domain summary DTO/mapper/record), 11 decisions logged, Codex at its usage limit
   (noted on each PR), tests up in every suite with 0 failures. knk-workspace#760 conflicted with overview map L8's
   changelog entry after it merged; mechanical (both add an entry), so I merged `origin/next` into the branch keeping
   both entries (`30894797`, SKILL § 7.3) and merged it (`560dd839`). Alternatives: (a) send #760 back to the link —
   the subagent had finished and the conflict was two added entries; (b) wait for the overview map coordinator —
   nothing to agree.
10. **Window before L3.** Chosen: offer the off-road coordinator the window now (L2 merged), and start L3 if it
    declines or does not answer within about 30 minutes, as agreed in item 7. Alternatives: (a) start L3 at once —
    breaks the agreement; (b) wait for the off-road links without a limit — they wait for the developer, maybe until
    this evening.
11. **L3 start (2026-11-18).** The off-road coordinator declined the window (its links wait for the developer), so
    L3 started at once with create_session (knk-plugin only besides knk-workspace). Its prompt follows the charter and
    DESIGN § 10 over the October text of #69: nothing is deleted in L3 (that is L5, #747), everything new sits behind
    `navigation.destination-engine: false`, and the switch-over keeps out of the off-road guidance-v2 sections of
    `NavigationService`. Alternatives: (a) a subagent — not needed for one repository; (b) wait for `next` CI on the L2
    merge before starting — starting is not a merge; the CI is checked before L3 merges.
12. **L3 check (2026-11-18).** Chosen: merge knk-plugin#81 and knk-workspace#761 into `next` after the § 6 checks:
    heads match, 0 behind `next`, no conflicts, PR CI `build` and `paper-boot` green, `next` green before the merge,
    tier:3 behind `navigation.destination-engine: false`, no file deleted, the only removed lines in main code are the
    `NavigationService.navigate` eligibility block and tail moved unchanged into `refusedByEligibility`/`begin` and
    five `KnKPlugin` lines replaced by `RoadAccessAnswers` (same catalogue calls with the flag off); the off-road
    guidance-v2 sections untouched; 13 existing test verifications only disambiguated (`any(Destination.class)`);
    knk-core 3 290 → 3 316, knk-paper 2 981 → 3 036, 0 failures; 15 decisions logged; Codex at its usage limit.
    New node `knk.navigate.any` (`default: false`, E12). Out of scope, for the developer: `/knk road` status showing
    the model's age, and a knk-web-api rank seed for `knk.navigate.any` (listed on #25). Alternatives: (a) send back
    for a plugin scenario with the flag on — CI's server runs with the flag off and the link's MockBukkit tests run
    the real engine; the live form is smoke § 3, the developer's gate before L5.
13. **L4 vs off-road L8 (2026-11-18).** Proposed to the off-road coordinator: start L4 now, its L8 (#708) after L4 is
    merged, during the wait for the developer's live test before L5; or it takes the window first. It agreed (15:07): L4 runs now; L8's knk-web-api and knk-web-app parts
    run alongside (no shared repo with L4); L8's plugin part takes the slot after L4 is merged, before L5. L4 started
    at once. Alternatives: (a) L8 first — delays L4 and so the developer's live test of § 3 and § 4.
14. **L4 check (2026-11-18).** Chosen: merge knk-plugin#82 into `next` after the § 6 checks: head matches, 0 behind,
    no conflicts, PR CI `build` and `paper-boot` green, `next` green (build and paper-boot on `073fa4cf`), tier:3
    behind the flag, no file deleted; every removed line is guarded by the engine (`revalidator != null`, `engine.get()
    == null`) so the flag-off paths are today's, except the `CommandNodes` `navigate` entry, which now also accepts
    `knk.navigate.any` with the flag off — accepted, because nobody holds that new node by default and the player still
    gets today's no-permission message (link decision); off-road guidance-v2 sections untouched; knk-paper 3 036 →
    3 065, 0 failures; 12 decisions logged; Codex at its usage limit. knk-workspace#762 conflicted with overview map's
    players-layer changelog entry; mechanical, merged `origin/next` keeping both (`0b1274d4`) and merged (`9db3df91`).
    Alternatives: (a) send L4 back to tie the `CommandNodes` entry to the flag — more wiring for a node nobody holds,
    and L5 removes the flag anyway.
15. **After L4 (2026-11-18).** L5's gate is the developer's live test (§ 1 item 1), a blocker for L5 only. The off-road
    chain's L8 (#708) plugin part takes the knk-plugin navigation slot now (agreed in item 13); L5 does not start until
    it is merged into `next`, even once the live test passes. Alternatives: (a) hold the slot for L5 — L5 cannot start
    before the live test anyway.
16. **Off-road L8 merged (2026-11-18 16:46).** Its coordinator reports L8 (#708) merged into `next` (knk-plugin
    `5fd81466`, knk-web-api `935fe8cc` with the additive `AddLandmarks` migration, knk-web-app `3432e6ef`, knk-workspace
    `7722cc76`): a `LandmarkProvider` in the World scope and an arrival-cylinder check in `NavigationService`, behind
    `navigation.landmarks` and `navigation.destination-engine`. The plugin slot is free; L5 starts when the developer's
    live test passes, telling the off-road coordinator first (its L10 step 2 and L5 #705 also wait for the developer).
    L5's prompt must keep the landmark provider and arrival check while removing the flag. Alternatives: none.
17. **Check-in 18:01 (2026-11-18).** `next` CI green after L4 (`3e04ba8f`) and off-road L8 (`5fd81466`); no live-test
    result on #25 or #62 yet. The off-road chain took the plugin navigation slot at 17:45 for L10 step 2 (#712, plaza
    lines behind `navigation.plaza-lines`, its `NavigationService` plaza/trail sections, `TrailRenderer`, `PlazaCurve`);
    agreed, L5 waits for its merge as well as for the live test. Alternatives: (a) claim the slot for L5 — L5 cannot
    start before the live test.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — P1 pure engine in knk-core (#96)

1. **Scope done.**
    1. knk-plugin: the October P1 branch reused (E14); `origin/next` `7f4bdd3a` merged in (merge `295ea235`); the one
       conflict in `ArchitectureGuardTest` keeps both `onlyTheDestinationEngineConstructsAllowedDestination` and
       `sharedShapingPackageDoesNotUseNpcPackages`; nothing else conflicted.
    2. knk-plugin `core/navigation/destinations` (commit `64ca8815`), the deltas of DESIGN § 10.2.4: new `Reason(code,
       text)` on `Scope.Empty`, `Listed.reasonWhenEmpty`, `DestinationList`, `Resolution` and `Revalidation` (E15);
       codes `loading`, `frozen`, `no-permission`, `siege-compass-off`, `siege-match-empty`, `siege-lobby` and the
       engine's `no-longer-listed`; scope 55 with today's "This match has no destinations to navigate to."; scope 60
       empty gives the same text under `siege-match-empty`; `Place.Point.arrivalRadius` (E16) and the `landmark:<id>`
       key documented; no list cache (E18), documented and tested.
    3. New tests: `ReasonTest` (4), `LandmarkLikeProviderTest` (7, the § 3.2 provider: listed in World, hidden by every
       exclusive scope, listed for the bypass, other world resolved apart, rename keeps the session), arrival radius in
       `CandidateTest`, codes/texts/no-cache in `InitialScopesTest` and `DestinationEngineTest`.
    4. knk-workspace (`55c4fb13`): smoke guide § 1 rewritten to what was built, 9 of 11 steps tagged; DESIGN § 10.2
       item 7 (what was applied, for P3/P4).
    5. Nothing wired into the plugin: no behaviour change, no config key, no migration. No file outside
       `core/navigation/destinations/` and `ArchitectureGuardTest` changed in knk-plugin.
2. **Commits and heads.** knk-plugin `claude/navigation-destination-engine` at `64ca8815` (3 commits over `next`:
   `ea368a8b`, merge `295ea235`, `64ca8815`; base `next` at `7f4bdd3a`). knk-workspace
   `claude/navigation-destination-engine` at `55c4fb13` (1 commit, base `next` at the time of branching, 0 behind).
3. **PRs.** [PandiO/knk-plugin#78](https://github.com/PandiO/knk-plugin/pull/78) (`Closes PandiO/knk-workspace#96`),
   [PandiO/knk-workspace#754](https://github.com/PandiO/knk-workspace/pull/754) (`Part of`), both base `next`. Not
   merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer` (JDK 21 Gradle, JDK 25 toolchain): baseline on `next`
       `7f4bdd3a` knk-core 3 151, knk-api-client 344 (2 skipped), knk-paper 2 957 (18 skipped), 0 failures; branch
       knk-core 3 221 (+70: 69 engine tests, 1 architecture rule), knk-api-client 344 (2 skipped), knk-paper 2 957
       (18 skipped), 0 failures. PR CI: `build` green; `paper-boot` was still running when this block was written.
    2. Known reds: none.
    3. Codex: at its code-review usage limit on both PRs (its comment on #78 and #754); skipped under global
       "Branches" rule 4's usage-limit exception, said on both PRs. No findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *Compass item vs. siege switch (§ 10.2.4 item 2).* Chosen: one `Siege.compassEnabled`, documented as
       `item().enabled() && siegeEnabled()` and built by the P3 adapter, because the two only ever matter together.
       Alternatives: (a) a second `compassItemEnabled` field: more fields for the same rule.
    2. *Empty match list.* Chosen: scope 60 refuses with `siege-match-empty` and today's text, matching today's
       `/navigate`. Alternatives: (a) no reason, as in October: the adapter would invent the text; (b) reuse
       `siege-compass-off`: the compass words the cases differently.
    3. *Reason on the API.* Chosen: `Reason` replaces the `String` reason everywhere. Alternatives: (a) a parallel code
       field: two fields that can disagree.
    4. *Arrival radius.* Chosen: nullable `Double` on `Place.Point`, positive and finite, 4-argument constructor kept.
       Alternatives: (a) a separate `Place.Area`: every `Point` consumer needs a second case.
    5. *Cache (E18).* Chosen: no cache in P1; a model-backed cache belongs with the model (P2/P3). Alternatives: (a) a
       cache keyed by (scope, world, modelVersion) now: nothing model-backed exists yet to cache.
6. **Out of scope, noted.** None.
7. **Blockers.** None.
8. **At merge / what the developer must do.** Nothing beyond merging: no config key, no migration. Changelog entry and
   the `documentation` sub-issue at the merge into `next` (the coordinator's step). Smoke § 1 steps 10 and 11 (nothing
   changed) are manual.
9. **Notes for later links.**
    1. P3 adapters: switch on `Reason.code()`, not the text; the compass maps `siege-lobby` to "works once the siege
       match has started." and `siege-compass-off` to "switched off during sieges."; build `Siege.compassEnabled`
       from the item rule and `siegeEnabled`.
    2. `Revalidation.reason()` is a `Reason` too (`no-longer-listed` for a dropped key) for P4's
       `DESTINATION_NOT_ALLOWED`.
    3. Off-road L8 (#708): `LandmarkLikeProviderTest` is the contract; register the provider as one more World
       provider in `InitialScopes.create`, use `Place.Point(..., radius)` or `Place.Region`.
    4. Maven Central through the proxy: a Gradle init script putting `repo.papermc.io/repository/maven-public/` first
       (named repo moved to index 0) plus one `--refresh-dependencies` gave a clean build.

### 4.2 L2 — P2 navigation model, snapshot, domain search Location (#103)

1. **Scope done.**
    1. knk-web-api (`f74623f`): nullable `location` (`LocationDto`) on `DomainListDto`, mapped in
       `DomainMappingProfile`; `.Include(d => d.Location)` in `DomainRepository.SearchAsync`; the key is always
       written (`null` when none). No migration, no access rule change, no page-size cap.
    2. knk-plugin `knk-api-client`/`knk-core` (`14d4632b`): the search's `worldName` and `location` read;
       `KnkDomainSummary` carries `worldName`, `location`, `locationSent`.
    3. knk-plugin `core/navigation/model` (`11779766`): `NavigationModel` (domain places, Locations, compass settings,
       road-access answers E19, empty `landmarks` E16), `NavigationModelSnapshot` (schema 1, atomic write, corrupt or
       newer file ignored), `NavigationModelHolder` (volatile swap, content version), `NavigationModelRefresher`
       (refresh, paced fallback two a tick, save when complete and changed), `ModelFreshness` (limited, stale note),
       `PagedFetch`.
    4. knk-plugin `paper/navigation/model` (`adbe3a50`): `NavigationModelRuntime` (load at start-up with its age, 60 s
       refresh, 1 s fallback tick, own writer thread), `NavigationModelConfig`; new key
       `navigation.destinations.stale-after-days` (14). Shared files, additive lines only: `KnKPlugin` (field,
       `startNavigationModel`, cache refresh hook, stop in `onDisable`), `config.yml`, `DomainSummaryDto`,
       `DomainCatalogMapper`, `KnkDomainSummary`. Nothing reads the model (`NavigationModelUnreadTest`).
    5. knk-workspace (`cb21d359`): smoke § 2 rewritten (12 of 13 steps tagged), plugin configuration § 4.15 and
       § 2.1, changelog entry with admin steps, DESIGN § 10.3 item 5 (what P2 applied).
    6. Acceptance (DESIGN § 13): A10, A11, A13, A14, A15 ticked by tests; A12 ticked for the model (the player-facing
       part is P3's § 3.3); A21 groundwork (the answers equal today's, routes use them from P3).
2. **Commits and heads.** knk-web-api `claude/navigation-destination-engine` at `a49fba2` (`f74623f` + merge of
   `next` `0308377`). knk-plugin at `61fe656a` (`14d4632b`, `11779766`, `adbe3a50`, merge of `next` `02aa110e`).
   knk-workspace at `43a01a7c` (`cb21d359` + merge of `next` `b7820e99`, changelog conflict: both entries kept).
3. **PRs.** [PandiO/knk-web-api#49](https://github.com/PandiO/knk-web-api/pull/49) (`Part of`),
   [PandiO/knk-plugin#80](https://github.com/PandiO/knk-plugin/pull/80) (`Closes PandiO/knk-workspace#103`),
   [PandiO/knk-workspace#760](https://github.com/PandiO/knk-workspace/pull/760) (`Part of`), all base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api `dotnet test`: baseline `next` `f2f523c` 4 372 passed, 100 skipped (MySQL, `KNK_TEST_MYSQL` unset);
       branch with `next` `0308377` merged 4 409 passed (3 new, 34 from overview map L7), 100 skipped, 0 failed.
    2. knk-plugin `./gradlew build -x deployToDevServer`: baseline `next` `1105ec15` knk-core 3 231, knk-api-client
       344 (2 skipped), knk-paper 2 963 (18 skipped); branch before the second merge 3 275 (+44) / 348 (+4) / 2 972
       (+9); after merging `next` `02aa110e` 3 290 / 351 (2 skipped) / 2 981 (18 skipped); 0 failures.
    3. CI: knk-web-api#49 `build-and-test`, `mysql-tests`, `fresh-database` green; knk-plugin#80 `build` green,
       `paper-boot` green; knk-workspace#760 no checks.
    4. Known reds: none. Codex: at its usage limit on all three PRs (review "Failed", no inline findings); skipped under
       global "Branches" rule 4's usage-limit exception, said on each PR.
5. **Decisions (DESIGN § 4.3).**
    1. *Scope vs. the October text of #103.* Chosen: DESIGN § 10 and the charter; `CatalogueProvider` and
       `CompassTargetsProvider` reading the model belong to L3 (#69). Alternatives: (a) build them now: something would
       read the model before the flag exists.
    2. *Older API detection.* Chosen: the API always writes `location` (null included) and the plugin reads it as a raw
       JSON node, so a missing key means "older API" and only then the paced fallback runs. Alternatives: (a) fallback
       for every null Location: N lookups forever for domains that have none; (b) an API version header: more contract
       for a transitional case.
    3. *Refresh atomicity.* Chosen: domains, Locations and compass settings must all answer, else the model is kept.
       Alternatives: (a) partial updates per part: `asOf` would claim a freshness one part lacks.
    4. *Snapshot writes.* Chosen: when no place is queued and the content changed, or the file's `asOf` is over a day
       behind (so a restart's age is right to the day). Alternatives: (a) only on content change (§ 7.2 wording): the
       file's age would grow while the API keeps confirming it; (b) every refresh: a write a minute for nothing.
    5. *Fallback pace and scope.* Chosen: two lookups per one-second tick, Towns/Districts/Structures only (what
       `DomainLocationResolver` serves today), places found are carried over by later refreshes, `/knk cache refresh`
       looks them up again; a failed lookup waits for the next refresh. Alternatives: (a) a config key: a transitional
       mechanism, the charter names one key only; (b) re-check every place each round: constant API load with an old API.
    6. *Model version.* Chosen: a holder counter that moves only with the content (`asOf`-only refreshes keep it), for
       E18 caches. Alternatives: (a) a hash: same effect, less readable in logs.
    7. *File location.* Chosen: `<data folder>/offline/navigation-model.json` = `plugins/KnightsAndKings/...` (DESIGN
       says `plugins/KnK/`, shorthand). Alternatives: (a) a config key for the file like `offline-cache.file`: not asked.
    8. *Freshness.* Chosen: limited and stale both set `degraded` with their text (the L1 `DestinationList` doc).
       Alternatives: (a) stale as a note without `degraded`: two fields for one display.
    9. *Config key home.* Chosen: a separate `NavigationModelConfig` record, not a field on `NavigationConfig`
       (shared with the off-road chain). Alternatives: (a) extend `NavigationConfig`: touches every constructor call.
    10. *Realtime refresh.* Chosen: none; 60 s polling as today (§ 2.1 item 9 left it optional). Alternatives: (a)
        listen to `EntityChanged`: more wiring in shared realtime code for a model nothing reads yet.
    11. *Guard test.* Chosen: `NavigationModelUnreadTest` pins that only `KnKPlugin` names the model packages; P3 widens it.
        Alternatives: (a) a rule in `ArchitectureGuardTest`: a shared file.
6. **Out of scope, noted.** `/knk road` status showing the model's age (§ 7.3) is left to P3 with the other adapters;
   `docs/specs/api/swagger.json` follow-up for the docs session.
7. **Blockers.** None.
8. **At merge / what the developer must do.** Deploy knk-web-api and the plugin (either order); add
   `navigation.destinations.stale-after-days: 14` under `navigation:` (missing = 14). Smoke § 2 step 13 (nothing
   changed in game) is manual.
9. **Notes for later links.**
    1. P3: read `NavigationModelRuntime.holder()` (`KnKPlugin.navigationModel`); `holder().version()` is the
       `modelVersion`; `freshness().applyTo(list)` adds the limited/stale text; road access from
       `model.roadAccessIgnored`/`roadsIgnoreRegion` (E19), compass settings from `model.compass()`; widen
       `NavigationModelUnreadTest`; `holder().onChange` is the "model refresh" trigger of § 8.
    2. Off-road L8 (#708): fill `NavigationModel.landmarks` (`Landmark` has the § 6.3 fields) from the refresher's
       `Source` (add a part), no schema bump: `NavigationModelSnapshotTest.unknownPlacesAndLandmarksSurviveTheRoundTrip`.
    3. Gradle: the init script trick of L1 note 4 worked again.

### 4.3 L3 — P3 switch-over behind the flag (#69)

1. **Scope done.**
    1. knk-plugin `core/navigation/engine` (commit `bcef34e5`): `CatalogueProvider` (model domains and Locations,
       network streets and named nodes; keys `domain:<Type>:<id>`, `location:<id>`, `street:<id>`, `node:<id>`;
       today's order through priorities 0 to 3; model part built once per model, E18), `SiegeMatchProvider`
       (`SiegeCompassTargets` order as priority, #176 gate approach, rebuilt per call), `CompassTargets` (general
       targets as a filter of the World list); `DestinationEngine.resolveKey` (additive, the second place that mints a
       handle).
    2. knk-plugin `paper/navigation/engine` and `paper/navigation` (commit `03ec14ce`): `PlayerNavigationEngine`,
       `RoadAccessAnswers` (E19), `DestinationEngineConfig` (`navigation.destination-engine`, default `false`, read at
       start-up), `HandleDestinations`, `EngineReasons` (E15); the engine branches in the command, its completion, the
       compass and the service; `knk.navigate.any` in `plugin.yml` (`default: false`); the key in `config.yml`.
    3. Existing lines changed (coordinator note 4.1): `NavigationService.navigate(Player, Destination)`: handle-only
       guard first, the eligibility block moved into `refusedByEligibility` (same code), the tail from
       `String world = …` moved into `begin(Player, Destination)` (lines unchanged), new field `handleOnly`; no
       guidance-v2 section (shaped walk trails, cursor, anchored trails, plaza-line preview) touched. `NavigateCommand`:
       one `if (engine != null)` branch before the match check in `onCommand` and in `onTabComplete`.
       `NavigationCompassService`: one branch after the click cooldown in `use`, `forget` clears the key cursor too.
       `KnKPlugin`: the two road-access lambdas and the `onRoadAccessChanged` registration read `RoadAccessAnswers`
       (flag off: the same catalogue calls), the compass settings supplier, `startDestinationEngine` (flag on only).
       Tests: 13 `navigate(any(), any())` verifications in `NavigateCommandTest`/`NavigationCompassServiceTest` name
       `Destination.class` (the overload made them ambiguous; assertions unchanged); `NavigationModelUnreadTest`
       allows the engine packages. `TrailRenderer`, `core/roads/`, `core/navigation/shape/` untouched.
    4. knk-workspace (`9dda7c92`): smoke § 3 rewritten (20 of 22 steps tagged), plugin configuration § 2.1 and § 4.15,
       changelog entry, `plugin-permission-checks.md` § 4 and `commands.md` (`knk.navigate.any`), DESIGN § 10.4.
    5. Acceptance (DESIGN § 13), with the flag: A16 (flag off unchanged: config test, unchanged old suites, flag-off
       tests of the new classes), A17, A18, A19, A20, A21 ticked by tests; their live form is smoke § 3. A08 and A07
       now also through the plugin.
2. **Commits and heads.** knk-plugin `claude/navigation-destination-engine` at `03ec14ce` (2 commits over `next`
   `2f1c783e`, 0 behind). knk-workspace `claude/navigation-destination-engine` at `9dda7c92` (1 commit over `next`
   `560dd839`, 0 behind).
3. **PRs.** [PandiO/knk-plugin#81](https://github.com/PandiO/knk-plugin/pull/81) (`Closes PandiO/knk-workspace#69`),
   [PandiO/knk-workspace#761](https://github.com/PandiO/knk-workspace/pull/761) (`Part of`), both base `next`. Not
   merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer` (JDK 21 Gradle, JDK 25 toolchain): baseline `next` `2f1c783e`
       knk-core 3 290, knk-api-client 351 (2 skipped), knk-paper 2 981 (18 skipped), 0 failures; branch knk-core 3 316
       (+26), knk-api-client 351 (2 skipped), knk-paper 3 036 (+55, 18 skipped), 0 failures. New tests seen red once
       (engine branch and handle-only guard disabled: 18 of 28 failed). CI on `03ec14ce`: `build` and `paper-boot` green (runs 44317959844, 44317961322).
    2. Known reds: none.
    3. Codex: at its code-review usage limit on both PRs; skipped under global "Branches" rule 4's usage-limit
       exception, said on both PRs. No findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *Deletions.* Chosen: none (prompt item 3, DESIGN § 10 over the October text of #69); the old paths stay for
       phase 4b (#747). Alternatives: (a) delete as the issue text said: the flag-off path would be gone.
    2. *Context in P3.* Chosen: the context carries loading, frozen and lobby too, and the service's
       `NavigationEligibility` check also stays on the handle path (same texts), so P4 only removes the duplicate and
       adds re-validation. Alternatives: (a) leave loading/frozen out of the context until P4: a frozen staff member
       would get the bypass list and only the service would refuse; (b) drop the eligibility check now: that is P4.
    3. *Handle for a listed key.* Chosen: `DestinationEngine.resolveKey`, additive in the engine package.
       Alternatives: (a) re-resolve `type:#id` or the qualified name: breaks for candidates without an id or with
       shared names.
    4. *Compass targets.* Chosen: `CompassTargets`, a filter of the World list, not a `Provider` (DESIGN § 4.1
       notes). Alternatives: (a) a provider in the World scope: duplicates catalogue keys (first provider wins) and
       still needs the configured order.
    5. *Mode fallback.* Chosen: the adapter retries a domain's `NO_LOCATION` with the other mode word, as
       `locateDomain` falls back today. Alternatives: (a) answer "no Location": a change for `spawn` on region-only
       districts.
    6. *Match words.* Chosen: in a match an unknown name tries "the start of exactly one name" (today's match path),
       and a name ending in `spawn`/`region` is tried whole too (team spawns). Alternatives: (a) only the engine's
       exact names: today's prefix behaviour in a match would be lost.
    7. *Flag read.* Chosen: at start-up, restart to switch (deploy notes say so). Alternatives: (a) live with
       `/knk reload`: running sessions and the road tags would switch sources mid-run.
    8. *Raw entry with the flag on.* Chosen: refuses with a warning in the log (A20). Alternatives: (a) keep it open:
       E3 would not hold with the flag on.
    9. *Compass settings with the flag on.* Chosen: the model's, the live store's when no model exists yet.
       Alternatives: (a) always the store: smoke § 3.3 step 1 (saved settings after a restart) would fail.
    10. *Bypass in the compass.* Chosen: in a match the bypass compass cycles the match's destinations, in the lobby
        it waits for the match (today's compass), elsewhere the general targets. Alternatives: (a) cycle the whole
        bypass list: hundreds of entries on a right-click.
    11. *Degraded note.* Chosen: shown after a name not found and after the compass's "no destinations here".
        Alternatives: (a) on every answer: noise on every route start while the model is stale.
    12. *`knk.navigate.any` in `plugin.yml`.* Chosen: `default: false` (E12: not granted by default, not even to ops).
        Alternatives: (a) `default: op` as the command skill suggests: ops would bypass every scope.
    13. *Config record.* Chosen: `DestinationEngineConfig` read from `getConfig()`, as L2's `NavigationModelConfig`.
        Alternatives: (a) `KnkConfig`/`ConfigLoader`: touches the shared loader for a key that phase 4b removes.
    14. *Overload vs. tests.* Chosen: `navigate(Player, AllowedDestination)` as DESIGN § 6 names it, with
        `any(Destination.class)` in 13 existing verifications. Alternatives: (a) another method name: against § 6.
    15. *Scenario.* Chosen: no plugin scenario; MockBukkit/Mockito tests against the real engine. Alternatives: (a) a
        flag-on scenario: the flag is read at start-up and CI's server runs with it off.
6. **Out of scope, noted.** `/knk road` status showing the model's age (§ 7.3, left from L2) and a knk-web-api rank seed
   for `knk.navigate.any` (proposed on the PR, not added): for the coordinator to file or hand to L4/L5. The arrival
   radius of `Place.Point` is not used by `Destination` yet (the landmark link #708 adds it, DESIGN § 10.4 item 5).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Add under `navigation:` in the dev and alpha `config.yml` (missing = false):
       ```yaml
       navigation:
         destination-engine: false
       ```
    2. For the live test before L5: set it to `true`, restart, run smoke § 3 (and § 4 after L4); grant
       `knk.navigate.any` to the Bypass test account through the in-house permission system.
9. **Notes for later links.**
    1. L4 (#62): the context already has loading, frozen, permissions and the siege facts; remove
       `refusedByEligibility` from `navigate(Player, AllowedDestination)`, keep the handle on `Active` for
       `revalidate`; `holder().onChange` and the siege observer are the triggers; the command's `hasNode` check is the
       other duplicate.
    2. L5 (#747): delete the flag-off branches (the `engine == null` paths), `MatchNavigationScope`, the raw entry and
       `setHandleOnly`, `RoadAccessAnswers`' catalogue side; `EngineFixture` and the `*EngineTest` classes become the
       command and compass tests.
    3. Off-road L8 (#708): register the landmark provider in `KnKPlugin.startDestinationEngine` (the World list);
       `HandleDestinations` needs the arrival radius.
    4. Gradle: the init script of L1 note 4 worked again.

### 4.4 L4 — P4 hard blocks as scopes, live re-validation (#62)

1. **Scope done** (all behind `navigation.destination-engine: false`; nothing deleted, prompt item 2).
    1. knk-plugin (commit `d38fb46c`): `NavigationService` keeps the handle on `Active` and re-validates through
       `SessionRevalidator` (`PlayerNavigationEngine.revalidate`) every 40 ticks and at once on `revalidateSoon()`
       (run at the start of the next tick); a destination that left the list ends with the new
       `EndReason.DESTINATION_NOT_ALLOWED` and the scope's reason in `/navigate`'s words; `EndReason.SIEGE` is not
       used with the flag on. The handle path no longer asks `NavigationEligibility`. Triggers: the siege observer
       (`objectiveCaptured`, `matchEnded`, `lobbyChanged`, `roundReleased`), `ModeService.addModeListener` (new),
       the freeze hook, `NavigationModelHolder.onChange`. With the engine the command, its completion and the compass
       leave `knk.navigate` to the no-permission scope; `CommandNodes` lists `knk.navigate.any` for `navigate`
       (`plugin.yml` already declared it, L3).
    2. Existing lines changed (coordinator note 4.1): `NavigationService`: the eligibility block of
       `navigate(Player, AllowedDestination)` removed and its Javadoc rewritten; in `tick` the
       `if (deps.eligibility().inSiege(…))` line became the `else if` of the new revalidator branch; one line added at
       the start of `tickAll`, `lobbyChanged`, `objectiveCaptured`, `roundReleased` and `matchEnded`; no
       guidance-v2 section (shaped walk trails, cursor, anchored trails, plaza-line preview) touched.
       `NavigateCommand`: the two `hasNode` conditions (`onCommand`, `onTabComplete`) skip with the engine on.
       Compass (`NavigationCompassService.use`): the same for its `hasNode` condition. `KnKPlugin`: one block in the
       freeze hook (`revalidateSoon`), the revalidator and model/mode listeners in `startDestinationEngine`. Also
       `ModeService.applyMode` (listener call), `NavigationEffect.EndReason`, `NavigationMessages.ended`,
       `CommandNodes`. `TrailRenderer`, `core/roads/`, `core/navigation/shape/` untouched.
    3. knk-workspace (commit `ba4676dc`): smoke § 4 rewritten (16 of 18 steps tagged), DESIGN § 10.5 and § 13 A22–A26
       marked met, changelog entry, `plugin-permission-checks.md` § 4, `commands.md`.
    4. Acceptance (DESIGN § 13): A22, A23, A24, A25, A26 met by tests; A16 kept (flag-off pins). Live form: smoke § 4.
2. **Commits and heads.** knk-plugin `claude/navigation-destination-engine` at `d38fb46c` (1 commit over `next`
   `073fa4cf`, 0 behind). knk-workspace `claude/navigation-destination-engine` at `ba4676dc` (1 commit over `next`
   `d484361e`, 0 behind).
3. **PRs.** [PandiO/knk-plugin#82](https://github.com/PandiO/knk-plugin/pull/82) (`Closes PandiO/knk-workspace#62`),
   [PandiO/knk-workspace#762](https://github.com/PandiO/knk-workspace/pull/762) (`Part of`), both base `next`. Not
   merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer` (JDK 21 Gradle, JDK 25 toolchain): baseline `next` `073fa4cf`
       knk-core 3 316, knk-api-client 351 (2 skipped), knk-paper 3 036 (18 skipped), 0 failures; branch knk-core 3 316,
       knk-api-client 351 (2 skipped), knk-paper 3 065 (+29, 18 skipped), 0 failures. Red check: with the re-check
       disabled 12 of the 21 `NavigationServiceRevalidationTest` tests fail. CI on `d38fb46c`: `build` and `paper-boot` green (runs 44334679616, 44334679699).
    2. Known reds: none.
    3. Codex: at its code-review usage limit on both PRs; skipped under global "Branches" rule 4's usage-limit
       exception, said on both PRs. No findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *Old issue text vs DESIGN § 10.* Chosen: DESIGN § 10 and the charter: nothing deleted; with the flag on the
       engine path stops using `NavigationEligibility`, `EndReason.SIEGE` and the lobby ending, with it off they work
       as today; removal is L5 (#747). Alternatives: (a) delete as the October text of #62 says: the flag-off path
       and the developer's comparison would be gone before the live test.
    2. *When an immediate re-check runs.* Chosen: `revalidateSoon()` sets a volatile flag and the next tick runs the
       re-check on the main thread, so the siege state, the mode or the model has settled and callers on other
       threads (the freeze hook, the model refresh) are safe. Alternatives: (a) re-check inside the callback: during
       `matchEnded` the match may still be registered, and the freeze hook and model listener run off the main
       thread; (b) schedule a Bukkit task per trigger: same effect, not testable without a scheduler.
    3. *Message on the end.* Chosen: the scope's reason in `/navigate`'s words (`EngineReasons.forCommand`, the same
       line as a refusal), also for a route started with the compass; `no-longer-listed` reads "<name> is no longer
       part of this match." / "… of the world.". Alternatives: (a) "Navigation to X ended - <reason>": a new text
       per reason; (b) the compass's wording for compass routes: the session does not know which client started it.
    4. *Mode-change trigger.* Chosen: a listener list on `ModeService` told by `applyMode` on every change (all mode
       switches go through it). Alternatives: (a) a Bukkit event: a new event class for one listener; (b) hook
       `ModeCommand` only: misses realtime `UserModeChanged` and join restores.
    5. *Freeze trigger.* Chosen: one line in the existing freeze hook in `KnKPlugin` (it already hears every freeze
       start and end, any thread). Alternatives: (a) a listener list on `AdminFreezeManager`: a second hook for the
       same signal.
    6. *Re-check scope of a trigger.* Chosen: every running session is re-checked on any trigger (few sessions; the
       catalogue part is built once per model). Alternatives: (a) only the affected player: needs a player per
       trigger (the model refresh and siege events have none).
    7. *`knk.navigate` with the engine on.* Chosen: the command, its completion and the compass skip their own
       `hasNode` (L3 note 9.1: the other duplicate); the scope gives the same message; `CommandNodes` lets
       `knk.navigate.any` through the command gate. Alternatives: (a) keep the command's check: a `knk.navigate.any`
       holder without `knk.navigate` would be refused although the bypass sits above the permission scope (E5).
    8. *`CommandNodes` with the flag off.* Chosen: the entry lists both nodes regardless of the flag (it is static);
       a holder of only `knk.navigate.any` then passes the gate and sees `/navigate` in "/" suggestions with the flag
       off, and the command refuses with today's no-permission line. Alternatives: (a) flag-aware gate: touches the
       shared gate for a flag that L5 removes.
    9. *A failing re-check.* Chosen: logged, the session keeps going. Alternatives: (a) end it: a bug in a provider
       would end every route.
    10. *L3's test `theHardBlocksStillApplyToAHandle`.* Chosen: replaced by `sincePhaseFourTheOldEligibilityIsNotAskedOnTheHandlePath`
        plus a flag-off pin of the raw entry (`theRawEntryStillAsksTheOldEligibilityWithTheFlagOff`); it pinned the
        P3 state that this link changes by design. Alternatives: (a) keep it: contradicts DESIGN § 10.5 item 1.
    11. *Permission change trigger.* Chosen: none; the 2-second re-check sees it (§ 8 lists no permission trigger).
        Alternatives: (a) hook `forgetPermissionAnswers`: outside § 8.
    12. *Scenario.* Chosen: no plugin scenario; MockBukkit tests against the real engine (as L3: the flag is read at
        start-up and CI's server runs with it off). Alternatives: (a) a flag-on scenario: needs a second server
        config in `paper-boot`.
6. **Out of scope, noted.** Nothing new. Still open from L3: `/knk road` status showing the model's age; a
   knk-web-api rank seed for `knk.navigate.any`.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing to deploy beyond L3's key (no new key, migration or API change).
    2. The live test before L5: `navigation.destination-engine: true`, restart, smoke § 3 and § 4 (accounts: Player,
       Opponent, Staff, Senior Staff, Bypass with `knk.navigate.any`); say on #62 or #25 that they passed.
9. **Notes for later links.**
    1. L5 (#747): delete `NavigationEligibility` and its `Deps` field, the `else if (inSiege)` branch and the flag-off
       `lobbyChanged` ending, `EndReason.SIEGE` (and its message case), `refusedByEligibility` and the raw entry; the
       `engine.get() == null && !hasNode(...)` conditions become no check; `setRevalidator` can become constructor
       wiring; `NavigationServiceRevalidationTest`'s flag-off tests go.
    2. Off-road L8 (#708): a landmark session re-validates like any other (key `landmark:<id>`); nothing to add.
    3. Gradle: the papermc-first init script worked again (no 404s seen).
