# Town streets from districts chain — progress report

**Status:** Running (2026-11-14) · **Last updated:** 2026-11-15

**Issue:** [PandiO/knk-workspace#409](https://github.com/PandiO/knk-workspace/issues/409), links
[#514](https://github.com/PandiO/knk-workspace/issues/514) (L1),
[#515](https://github.com/PandiO/knk-workspace/issues/515) (L2),
[#516](https://github.com/PandiO/knk-workspace/issues/516) (L3).
**Charter:** [handoffs/TOWN_STREETS_CHAIN.md](../ai-agents/handoffs/TOWN_STREETS_CHAIN.md).

## 1. Waiting for the developer

All three links are merged into `next` (2026-11-15): knk-web-api `de741909`, knk-web-app `d3d7152b`, knk-workspace
`a49c0f84`. CI on `next` green (API build-and-test and fresh-database migrations, web-app build-and-test and e2e).
Guide: [town streets smoke test](../guides/town-streets-smoke-test.md). In test order:

1. **Deploy (dev, then alpha):** back up the database; deploy the API and the web app **together** (an old web app
   against the new API would offer Add…/Unlink that the API refuses); apply the migration `DropTownStreet` (dev:
   `dotnet ef database update`; alpha: the migrator image as in the runbook). It drops `TownStreet` with all its rows
   (your decision 2026-11-14).
2. **Town page:** open a real town with several districts: its Streets section lists exactly the distinct streets of
   its districts, shows the hint "Streets are managed on the district: open a district to add or remove them." and
   has no Add…, Unlink, Create New or Delete; View/Edit of a street still open the street.
3. **District page:** on one of its districts, Add… a street and check the town's Streets shows it; Unlink it again
   and check it disappears from the town.
4. **Dashboard access smoke test § 2.2 step 2** (manual): world-only account, link/unlink on
   `District/{district}/streets` → 403 "Changing links of District requires knk.admin.world and knk.admin.content."
5. Optional: remove a Town form field on `Streets`/`StreetIds` in the form builder (the API ignores it). Rollback only
   if needed: `dotnet ef database update SeedStaffFreezeNodes` refills `TownStreet` from the districts; rows no
   district covered come back only from the backup.
6. **Review the agent decisions:** block 4.1 § 5 (design defaults, approved), block 4.2 § 5 — in particular
   `UpdateTownAsync` only calls `Update()` for a detached town (a town save writes only changed town fields), and
   `Street.Town` removed from the relationship catalog with the table.
7. **Promotion of `next`** in knk-web-api, knk-web-app and knk-workspace when the test passes; #409, #514, #515, #516
   stay open (`status:in-review`) until then.
8. **Docs:** #559 (Docs: Town streets from districts, absorbs #555) has a docs session running
   (session_01R1w2UtA8zbwLFcDY1RR18R). It holds the admin guide items, which gate a deploy to alpha.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started | Test rule |
|---|---|---|---|---|---|---|---|
| L1 Design note and data check | #514 | Merged into next 2026-11-14 (knk-workspace `2d4418d2`, PR #525); #514 stays `status:in-review` until the developer promotes `next` | knk-workspace `claude/town-streets-409` `a24dcd2b` | [#525](https://github.com/PandiO/knk-workspace/pull/525) | n/a (docs) | create_session session_01R1w2UsgcJBhVZofGWWe6wN (`source_revision` `main`) | automated first, `main` `aa4208b3` |
| L2 Implementation | #515 | Merged into next 2026-11-15 (knk-web-api `de741909`, knk-web-app `d3d7152b`, knk-workspace `66c7c910`); #515 stays `status:in-review` until the developer promotes `next` | knk-web-api `claude/town-streets-409` `f26d966`; knk-web-app `1a7c2a7` (corrected 2026-11-15); knk-workspace `87ee436e` | [api#31](https://github.com/PandiO/knk-web-api/pull/31), [app#33](https://github.com/PandiO/knk-web-app/pull/33), [ws#554](https://github.com/PandiO/knk-workspace/pull/554) | api runs 43695899575 / 43695899524 green; app runs 43696786714 / 43696786710 green | subagent of the coordinator (knk-coordinator § 4.1.4: two component repos besides knk-workspace) | automated first, `main` `aa4208b3` |
| L3 Smoke tests and changelog | #516 | Merged into next 2026-11-15 (knk-workspace `a49c0f84`, PR #556); #516 stays `status:in-review` until the developer promotes `next` | knk-workspace `claude/town-streets-409` `2db5a064` | [#556](https://github.com/PandiO/knk-workspace/pull/556) | n/a (docs) | create_session session_01R1w2UtELGKcTZrWFhqdpxa (`source_revision` `main`) | automated first, `main` `aa4208b3` |

## 3. Coordinator decisions

1. **Rule set in force.** Chosen: the `next` branch model (links base on and target `next`, the coordinator merges a
   passed link into `next` with a merge commit), because the skill § 1.3 check passed on 2026-11-14:
   `.github/workflows/ci.yml` is on knk-web-api `origin/main` and knk-web-app `origin/main`. Alternatives: (a) the
   old rules (nobody in the chain merges), only if the check had failed.
2. **Heads at the first run (2026-11-14).** `next`: knk-web-api `b9ce7f05`, knk-web-app `8918eba0`, knk-plugin
   `a760c4a4`, knk-workspace `511b494d`; knk-workspace `main` `aa4208b3`.
3. **Testing rule version.** Chosen: "Testing: automated first" with the knk-test-writer skill, as merged on
   knk-workspace `main` in `aa4208b3` (PR #512, 2026-11-14), applied from L1 on, because the developer's instruction
   of 2026-11-14 says to apply it as soon as it lands and it landed before the first link. Alternatives: (a) the
   interim rule (unit tests plus an e2e spec per changed page), now superseded.
4. **Links and tiers.** Chosen: three sub-issues as the developer's prompt splits them: L1 #514 tier:3, L2 #515
   tier:3, L3 #516 tier:1 + `documentation`, because L3 changes docs only. Alternatives: (a) L3 tier:3 like the
   parent; (b) fold L3 into L2 (essential docs ship with L2 anyway; L3 keeps the smoke-test move separate as asked).
5. **No feature flag for tier:3 work.** Chosen: no flag, with the data check, backup step and migration `Down` as the
   safety net (charter § 3.2), because a dropped table and a derived read-only property cannot be switched off by
   configuration. Alternatives: (a) keep `TownStreet` and only hide the link behind a flag, dropping the table in a
   later release (two migrations, contradicts the developer's "drop the table"); (b) a flag that switches the DTO
   between stored and derived lists (keeps the drift problem alive).
6. **Overlap check.** No "In progress" row claims `Town`, `TownStreet` or the town detail page; chain 3's V5 claim on
   `RelationshipService.cs` is merged and idle. Chosen: no blocker; L2 keeps to the `Town.Streets` entry.
   Alternatives: (a) wait for chain 3 to close its row (it has no open work on that file).
7. **Developer gate after L1.** Chosen: the coordinator asks the developer with AskUserQuestion once L1's note and
   SQL are on the branch, and records the answer on #515, because a link session's question may go unseen.
   Alternatives: (a) the L1 link asks itself.
8. **Overlap with the #511 test backfill** (row added 2026-11-14, branch `claude/test-backfill-511`): it marks
   automated steps in `docs/guides/*smoke-test*.md`, possibly `dashboard-access-smoke-test.md`, which L3 edits
   (§ 2.2 step 2, § 8 step 9b). Chosen: not a blocker; L3 keeps to those two steps and merges `origin/next` first, so
   any conflict stays mechanical. Alternatives: (a) wait for #511 to finish before L3; (b) ask #511 to make the edit.

9. **L1 checked and merged (2026-11-14).** § 6 checks held: block 4.1 and row present, head `a24dcd2b` matched,
   docs-only scope (note, SQL, specs index, changelog), decisions logged. The branch was 30 commits behind `next` with a
   changelog conflict; I merged `origin/next` into it (`b48a0d61`, both entries kept) and merged PR #525 with a merge
   commit (`2d4418d2`). Codex skipped for its usage limit (noted on the PR). No CI in knk-workspace.
10. **Developer gate after L1.** Asked with AskUserQuestion: the note is approved with all six defaults, and all
    orphan `TownStreet` rows are dropped with the table without running the check first (backup is the way back).
    Recorded on #515.
11. **L2 route: subagent from the start.** Chosen because the coordinator skill on `main` (since 2026-11-14,
    § 4.1.4) says a link needing two or more repositories besides knk-workspace goes the subagent route, after Auto
    mode's classifier refused an `add_repo` in another chain. Alternatives: (a) `create_session` and fall back on a
    refusal (costs a failed session).
12. **Test rule for L2:** unchanged, "automated first" `aa4208b3`; knk-workspace `main` had no changes to the global
    instructions, the skills' testing parts or `web-app-testing.md` since. #421's scenario framework is now in
    knk-plugin `next`, but L2 does not change the plugin (L1 note § 5).
13. **L2 check: sent back once, then merged (2026-11-15).** First check: API PR #31 and workspace PR #554 passed;
    web-app PR #33 was textually clean but knk-web-app `next` had gained `e2e/entity-detail.spec.ts` (#511 backfill)
    that used Town streets as the link-table example (Unlink on `Town/1/streets`), behaviour L2 removes. Chosen: send
    it back to the L2 agent to merge `origin/next` and move those cases to a District, because a clean textual merge
    would have left a spec testing removed behaviour against a mock that misstates the API. Alternatives: (a) merge and
    file a follow-up (`next` would carry a misleading spec); (b) fix it myself (coordinators don't implement). After
    the fix (head `1a7c2a7`, CI green, 0 behind `next` in all three repos) I merged the three PRs together with merge
    commits (API `de741909`, web app `d3d7152b`, workspace `66c7c910`), API and web app back to back so `next` never
    has one without the other. Codex skipped on all three for its usage limit (noted on each PR). The L2 agent flagged
    `e2e/zz-e.spec.ts` in knk-web-app `next` (a leftover debug spec from #511, asserts nothing) on #511.
14. **L3 route:** `create_session`, knk-workspace only, so the § 4.1.4 subagent rule does not apply.
15. **L3 checked and merged (2026-11-15).** § 6 held: docs only, 0 behind `next`, § 2.2 step 2 and § 8 step 9b moved
    to District streets, new guide with `[automated]` lines for L2's tests, block 4.3 and row present. Codex skipped
    for its usage limit. Merged with a merge commit (`a49c0f84`).
16. **Developer request: remove `e2e/zz-e.spec.ts`** (2026-11-15). Done as knk-web-app PR #34 into `next` (branch
    `claude/remove-zz-e-spec`), merged after CI.
17. **End of chain.** `documentation` sub-issue #559 (absorbs #555), docs session started with `create_session`
    (session_01R1w2UtA8zbwLFcDY1RR18R). #409 stays open until the developer promotes `next` (branch model). Tracker row
    set to "In review".

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — Design note and TownStreet data check (#514)

1. **Scope done.**
    1. knk-workspace `docs/specs/towns/DESIGN_TOWN_STREETS.md` (Proposed): read path and query cost, every current
       reader of `Town.Streets`, removal of the link as a `derived` relationship, the read-only web section with the
       hint, configurations and seeds, plugin readers, migration `DropTownStreet` with a refilling `Down`, tests per
       behaviour and suite, six open questions with defaults, docs impact.
    2. knk-workspace `scripts/maintenance/town-street-orphans-409.sql`: SELECT only; orphan rows with names, counts,
       Town configurations naming Streets.
    3. `docs/specs/README.md` index line; `docs/CHANGELOG.md` Unreleased docs-only line.
2. **Commits and heads.** knk-workspace `claude/town-streets-409` at `a24dcd2b` (2 commits, base `next` at
   `39899f4b`). Component repos read only at `next`: knk-web-api `b9ce7f05`, knk-web-app `8918eba0`, knk-plugin
   `a760c4a4`.
3. **PRs.** [knk-workspace#525](https://github.com/PandiO/knk-workspace/pull/525), base `next`. Not merged. Codex did
   not review (usage limit reached; said so on the PR).
4. **Tests, baseline → result.**
    1. knk-workspace: docs only; links in the note resolve (the charter by URL, it is on `main` only). The SQL check ran
       on MariaDB 10.11 against a hand-made schema with the EF table and column names and fixture rows; all three
       result sets as expected. Not run on MySQL 9.6 or real data.
    2. Known reds: none (no suites run, docs only).
5. **Decisions (DESIGN § 4.3).**
    1. *Where the computed list lives.* Chosen: a `[NotMapped]` read-only `Town.Streets` on the model (keeps
       `[RelatedEntityField]`, drops `[NavigationPair]`), because metadata fields, display configurations and path
       validation keep working. Alternatives: (a) compute only in `TownMappingProfile` (metadata loses `Streets`,
       stored display sections and `Town.Streets[0].Name` paths break); (b) a SQL view mapped as a keyless entity
       (more schema for a list EF can compute).
    2. *Link route afterwards.* Chosen: a `derived` relationship storage in `RelationshipCatalog` (metadata keeps the
       entry, `canLink`/`canUnlink` false) and a 400 `RelationshipNotEditable` refusal with the reason, because the
       hint then has one source and the web app needs no Town special case. Alternatives: (a) drop the navigation
       from the catalog, 404 `UnknownRelationship` (simpler API, per-type hint in the web app); (b) a new error code
       `RelationshipDerived` (more surface for the same message).
    3. *Migration `Down`.* Chosen: recreate `TownStreet` as `InitialCreate` did and refill it from
       `DistrictStreet`/`districts`, because rolled-back code then shows what the new code showed. Alternatives: (a)
       recreate empty (Streets sections empty after a rollback); (b) keep a copy table of the dropped rows (a data
       backup in the schema; the pre-migration backup covers that).
    4. *Detail query.* Chosen: a new `GetDetailAsync` with `AsNoTracking` + `AsSplitQuery` for `GET api/Towns/{id}`,
       the tracked `GetByIdAsync` without streets for update/delete, because `Towns.Update` would write every loaded
       district street back. Alternatives: (a) add `ThenInclude(Streets)` to `GetByIdAsync` (extra writes on save);
       (b) one single query (row multiplication across sub-regions, districts and streets).
    5. *Buttons on a derived section.* Chosen: hide Add…, Unlink, Create New and Delete; keep View/Edit; show the
       hint as text. Alternatives: (a) show them greyed out with the reason (the issue asks for no button); (b) hide
       only Add…/Unlink (Create New makes a street with no district, Delete removes it from every district).
    6. *Note location.* Chosen: `docs/specs/towns/DESIGN_TOWN_STREETS.md`, next to `SPEC_TOWNS.md`, because the towns
       domain folder exists and no living world-model architecture doc does. Alternatives: (a) new
       `docs/specs/town-streets/DESIGN.md` (a folder for one note); (b) a section of `web-api-architecture.md` (the
       note also covers web app, plugin and data).
    7. *Changelog.* Chosen: one Unreleased docs-only line, because the script is something the developer runs on the
       alpha. Alternatives: (a) no line until L2.
6. **Out of scope, noted.** `RelationshipCatalog.Supported` has `["Street.Town"] = (true, true)` although `Street` has
   no `Town` navigation (dead entry, harmless); not filed, L2 may drop it while editing that dictionary if the
   coordinator agrees. Stored configurations in the knk-dev-db-seed were not read (no access); the SQL check § 3 lists
   them per database.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Approve the note or answer its open questions (§ 8: orphan rows, 400 vs 404, `Down` refill, buttons, hint
       wording, list endpoint).
    2. Run `scripts/maintenance/town-street-orphans-409.sql` on the dev and alpha databases (read only, note § 6.2)
       and decide per orphan row: link the street to a district of that town, or let it go; record on #515.
    3. Optionally comment `@codex review` on #525 when the Codex limit resets.
9. **Notes for later links.**
    1. L2: the note § 7 lists each test with its file; existing tests that use Town `streets` as the link-table example
       (API `RelationshipServiceTests`, `RelationshipsControllerTests`; web app `relationshipClient.test.ts`,
       `DisplayWizard.relationships.test.tsx`) move to `District.Streets`.
    2. L2: `PlaceholderResolutionService` builds string `Include` paths; a path through `Town.Streets` needs the
       `Districts.Streets` rewrite (note § 2.8.3).
    3. L2: remove `TownStreet` from `scripts/seed/seed-tables.sh` `WORLD_TABLES`; update `web-api-architecture.md` and
       `API_CONTRACT_TOWNS.md` (note § 9).
    4. Plugin: no change needed (note § 5).

### 4.2 L2 — Implementation: derived Town.Streets, DropTownStreet, read-only section (#515)

1. **Scope done.**
    1. knk-web-api: `Town.Streets` is a `[NotMapped]` read-only list (distinct streets of the districts, by name then id),
       with no `[NavigationPair]` and no `TownStreet` `UsingEntity`. `TownRepository.GetDetailAsync` (no tracking, split query) serves
       `GET api/Towns/{id}`. The tracked `GetByIdAsync` has no streets include and `UpdateTownAsync` skips `Update()` for a tracked
       town. `RelationshipCatalog.Derived` / `RelationshipStorage.Derived`
       (`storage: "derived"`): link and unlink answer 400 `RelationshipNotEditable` with the reason after the node gate.
       `Town.Streets` and `Street.Town` leave `Supported`. `PlaceholderResolutionService.DerivedIncludes` turns
       `Town.Streets` into `Districts.Streets`. Migration `DropTownStreet`: `Up` drops the table; `Down` recreates it as
       `InitialCreate` did and refills it from `DistrictStreet`/`districts`.
    2. knk-web-app: `storage: 'derived'`, `detailPage.isDerived`. A derived section has no Add…, Unlink, Create New or
       Delete, keeps View/Edit and shows `<p data-testid="derived-hint">` from `linkReason`. `TownCreateDto.streetIds` is
       dropped (no sender); `TownDto.streets` is typed.
    3. knk-workspace (`claude/town-streets-409`): `seed-tables.sh` without `TownStreet`; `web-api-architecture.md` § 4
       and § 5.3; `API_CONTRACT_TOWNS.md`; note status "Approved 2026-11-14 (defaults), implemented in L2"; the CHANGELOG
       Unreleased entry (replaces L1's line) with the admin steps.
2. **Commits and heads.** knk-web-api `claude/town-streets-409` at `f26d966` (1 commit, base `next` `2425f181`);
   knk-web-app at `9d578bb` (1 commit, base `next` `8918eba0`); knk-workspace at `87ee436e` (1 commit on L1's branch
   after a fast-forward to `next` `4a97fd3b`).
3. **PRs.** [knk-web-api#31](https://github.com/PandiO/knk-web-api/pull/31) (`Closes #515`),
   [knk-web-app#33](https://github.com/PandiO/knk-web-app/pull/33),
   [knk-workspace#554](https://github.com/PandiO/knk-workspace/pull/554), base `next`. Not merged. Codex skipped for its
   usage limit on all three (said so on each PR); no findings to handle.
4. **Tests, baseline → result.**
    1. knk-web-api: build 0 errors → 0; xUnit 4114 passed / 97 skipped → 4138 passed / 98 skipped, 0 failed. New:
       `TownStreetsDerivedTests` (7), `MetadataTownStreetsTests` (2), `DropTownStreetMigrationTests` (3),
       `DropTownStreetMySqlTests` (1, skipped in the suite without `KNK_TEST_MYSQL`; passed locally on MySQL 8.0.46),
       derived cases in `RelationshipServiceTests` (+2, the link-table example moved to `District.Streets`),
       `RelationshipsControllerTests` (+1) and `PlaceholderResolutionServiceTests` (+9). CI `build-and-test` and
       `fresh-database` green (runs 43695899575, 43695899524).
    2. knk-web-app: Jest 299 suites / 2569 → 300 / 2577 (+3 ActionButtons, +2 DisplayWizard derived, +2
       `detailPage.isDerived`, +1 relationshipClient); `tsc` ok → ok; `typecheck:e2e` ok → ok; Playwright 11 → 14 (new
       `e2e/town-detail.spec.ts`, strict mocks, typed fixtures `e2e/fixtures/towns.ts`); build compiled → compiled. CI
       `build-and-test` and `e2e` green (runs 43695923371, 43695923370).
    3. knk-workspace: docs only; new links resolve, `bash -n seed-tables.sh` ok.
    4. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Town save writes.* Chosen: `UpdateTownAsync` calls `Towns.Update` only for a detached town, so a tracked town
       saves only what changed (note § 7.1.3 asks for "no street or district rows"). Alternatives: (a) keep `Update()`
       and assert only that no street is written (districts would still be written back with the same values);
       (b) drop the `Districts` include from the tracked `GetByIdAsync` (touches what other readers of that load get).
    2. *`Street.Town` in `Supported`.* Chosen: removed. It was the other side of the `TownStreet` skip navigation (the
       catalog test listed it), not dead before this link, and it is dead once the table goes; the catalog test checks
       that every `Supported` + `Derived` entry exists in the model. Alternatives: (a) keep it and file an issue (a
       dead entry left behind).
    3. *Where the derived descriptors come from.* Chosen: `Build` adds one descriptor per `Derived` entry after the EF
       navigations, with the owner's change nodes. Alternatives: (a) reflect on `[NotMapped]` + `[RelatedEntityField]`
       (would make any future computed property silently read-only without a reviewed reason).
    4. *Include rewrite.* Chosen: `RewriteDerivedIncludes` walks the CLR types from the root, so `Town.Streets` is
       rewritten at any depth (`District.Town.Streets` → `District.Town.Districts.Streets`). Alternatives: (a) rewrite only a
       root-level `Streets` on Town (misses Layer 2 paths).
    5. *Hint placement.* Chosen: under the section header (next to the description), in `DisplaySection`; the
       collection's "Unlink: …" item hint is suppressed for a derived relationship. Alternatives: (a) in `ActionButtons`
       (it renders nothing once every button is hidden).
    6. *Jest link-table page.* Chosen: `DisplayWizard.relationships.test.tsx` now renders a District (Streets `many`,
       Structures as the required-parent example) plus a Town derived block. Alternatives: (a) keep the Town page with
       `storage: 'many'` (no longer what the API sends).
    7. *e2e realtime.* Chosen: the spec answers `POST hubs/web/negotiate` with 404 itself, so `strictApi` can be on.
       Alternatives: (a) add it to the shared `mockSession` (changes every spec; left for #511-style backfills).
    8. *`TownDto.streets` in the web-app type.* Chosen: added (`TownStreetDto`), read-only, so the e2e fixture is
       typed. Alternatives: (a) a fixture-local type (a DTO change would not break `typecheck:e2e`).
6. **Out of scope, noted.** None filed. `mockSession` in knk-web-app e2e does not mock the realtime negotiate call, so
   a strict spec must mock it itself (seen while writing the spec; harmless).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Back up the database, deploy API and web app together, apply `DropTownStreet` (all `TownStreet` rows go;
       rollback `dotnet ef database update SeedStaffFreezeNodes` refills from the districts; orphans only from the
       backup). Changelog entry on the branch has the steps.
    2. Optionally comment `@codex review` on the three PRs when the Codex limit resets.
    3. Manual check that no suite covers: run the migration on dev and alpha with real data, then open a town with
       several districts and compare its Streets section with the districts' streets.
9. **Notes for later links.**
    1. L3: the dashboard access smoke test § 2.2 step 2 and § 8 step 9b move to `District/{district}/streets`. The
       read-only town section and the refused link are automated: `e2e/town-detail.spec.ts`;
       `RelationshipsControllerTests.TownStreets_AreDerived_400WithTheReason_ForStaffWithTheNodes_403Without`;
       `TownStreetsDerivedTests`.
    2. L3: the CHANGELOG entry already has the admin steps; L3 only adds the smoke-test link to step 6.
10. **Correction 2026-11-15 (coordinator check, knk-web-app PR #33 sent back).**
    1. `next` brought `e2e/entity-detail.spec.ts` (#511 backfill), which used Town streets as the link-table example. I merged
       `origin/next` `9a29623` into the branch (`10903f5`, no rebase) and committed `1a7c2a7`:
       1. pagination, empty state, Unlink, Add…, Delete and both node gates moved to `/display/District/1`
          (`storage: 'many'`, `Relationships/District/1/streets/*`, fixture `mockDistrictDetail`);
       2. rename, errors, 390 px and no-access stay on Town;
       3. a new case checks that Town streets are read-only with the hint;
       4. the shared `dashboardAccess.ts` metadata sends Town `streets` as `derived`.
    2. Results: Jest 302 / 2603 passed, `tsc` and `typecheck:e2e` ok, Playwright 100 passed, build ok. CI green
       (runs 43696786710, 43696786714). New knk-web-app head `1a7c2a7`. Codex asked again with `@codex review`.
    3. Noted on #511: `e2e/zz-e.spec.ts` on `next` looks like a leftover debug spec (no assertions, `waitForTimeout`).


### 4.3 L3 — Smoke tests and changelog (#516)

1. **Scope done.**
    1. `docs/guides/dashboard-access-smoke-test.md` § 2.2 step 2 (still manual) and § 8 step 9b (still `[automated]`) use
       `District/{district}/streets`; step 2 notes the 400 `RelationshipNotEditable` for town streets, 9b names the moved
       e2e case (District 1 "Old Quarter").
    2. New `docs/guides/town-streets-smoke-test.md`: manual deploy and migration on dev and alpha, a look at a real
       town's Streets, optional Town form clean-up, rollback; `[automated]` lines naming `e2e/town-detail.spec.ts`,
       the `entity-detail.spec.ts` derived case, `DisplayWizard.relationships.test.tsx`, `TownStreetsDerivedTests`,
       `RelationshipsControllerTests.TownStreets_AreDerived_400WithTheReason_ForStaffWithTheNodes_403Without`,
       `MetadataTownStreetsTests`, `DropTownStreetMigrationTests`, `DropTownStreetMySqlTests`,
       `PlaceholderResolutionServiceTests` (two town-streets tests). Status "automated in CI; manual steps not run".
    3. `docs/CHANGELOG.md` admin step 6 links the guide; `docs/guides/README.md` index row.
2. **Commits and heads.** knk-workspace `claude/town-streets-409` at `2db5a064` (1 commit; the branch fast-forwarded to
   `next` `66c7c91` first, so no merge commit was needed).
3. **PRs.** [knk-workspace#556](https://github.com/PandiO/knk-workspace/pull/556), base `next`, `Closes #516`. Not
   merged. No CI in knk-workspace.
4. **Tests, baseline → result.** Docs only; the new links resolve; test names checked on knk-web-api `next` `de74190`
   and knk-web-app `next` `d3d7152`. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Where the #409 section lives.* Chosen: a new `docs/guides/town-streets-smoke-test.md`, because the manual steps
       are a deploy, a migration on two databases and a rollback, which do not fit a page guide. Alternatives: (a) a
       § 6 in `entity-detail-smoke-test.md` (that guide still describes town streets as editable, see #555, and has no
       deploy steps); (b) a section in the dashboard access guide (about access, not data).
    2. *§ 2.2 step 2 stays manual.* Chosen: `[ ]` kept, because the API gate tests (`RelationshipsControllerTests`) still
       call the filter with `Town`/`streets` and no API test sends a District link as world-only. Alternatives: (a) mark
       it `[automated]` with `TheAreaNodeWithoutContent_Is403` (claims District coverage the test does not have).
    3. *Dashboard guide header.* Chosen: no status-line change, because other sessions edit that header and the steps
       carry the #409 note themselves. Alternatives: (a) a dated clause in the status line (likely conflict).
6. **Out of scope, filed.** [#555](https://github.com/PandiO/knk-workspace/issues/555): the entity detail smoke test
   still uses Town streets as its link example and lists a town's streets as changeable.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Run the manual steps of the town streets smoke test: back up, deploy API and web app together, apply
       `DropTownStreet` on dev then alpha, open a real town with several districts and compare its Streets with the
       districts' streets (hint, no Add…/Unlink); optionally remove Town form `Streets`/`StreetIds` fields; rollback
       only if needed.
    2. Codex: see PR #556.
