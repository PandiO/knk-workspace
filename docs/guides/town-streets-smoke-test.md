# Town streets from districts (#409) — smoke test

**Status:** automated in CI; manual steps not run. Written 2026-11-15 (L3 [#516](https://github.com/PandiO/knk-workspace/issues/516)) for knk-web-api and knk-web-app `next` (L2 merged: API `de74190`, web app `d3d7152`); not on the trunk until the developer promotes `next`.
**Last updated:** 2026-11-15
**Issues:** [PandiO/knk-workspace#409](https://github.com/PandiO/knk-workspace/issues/409); design
[specs/towns/DESIGN_TOWN_STREETS.md](../specs/towns/DESIGN_TOWN_STREETS.md); changelog entry "Town streets come from
their districts" in [CHANGELOG.md](../CHANGELOG.md).

A town's streets are now the distinct streets of its districts, read-only; the `TownStreet` table is dropped by the
migration `DropTownStreet`. Streets are added to or removed from a town on a district's detail page. About 10 minutes
for the manual steps. Steps marked `[automated]` run in CI (knk-web-api xUnit, CI jobs `build-and-test` and
`fresh-database`; knk-web-app Playwright, CI job `e2e`, and Jest, CI job `build-and-test`); you don't repeat them.

You need: an Admin account, the dev database and then the alpha database (real data), a town with several districts
that have streets.

## 1. Deploy (manual: real databases)

1. Back up the database before deploying: the migration drops `TownStreet` with **all** its rows, including streets
   no district of the town has (developer decision 2026-11-14 on #515). Those come back only from the backup.
2. Deploy the API and the web app together (the web app reads `storage: "derived"` from the metadata; an older web
   app would offer Add…/Unlink that the API refuses).
3. Apply `DropTownStreet` on dev (`dotnet ef database update`), then on the alpha with the migrator image (runbook
   [§ API updates with migrations](closed-alpha-deployment-runbook.md)). The migration runs without errors and
   `TownStreet` is gone.
4. [automated] `Up` drops only `TownStreet`; `Down` recreates it as `InitialCreate` did and refills it from the
   districts: knk-web-api `DropTownStreetMigrationTests` (`Up_DropsOnlyTheTownStreetTable`,
   `Down_RecreatesTheTable_AsInitialCreateMadeIt`, `Down_RefillsFromTheDistricts_AfterTheTableAndIndexExist`); on MySQL
   `DropTownStreetMySqlTests.Down_RefillsTownStreetFromTheDistricts_AndUpDropsItAgain` (needs `KNK_TEST_MYSQL`, skipped
   in CI).

## 2. The town's Streets (manual: real data, a look)

1. As Admin, open a real town with several districts (Dashboard → Town → the town). Its **Streets** section lists
   exactly the streets of its districts (open each district to compare), each once, by name; it shows the hint
   "Streets are managed on the district: open a district to add or remove them." and no **Add…**, **Unlink**,
   **Create New** or **Delete**; View and Edit on a street still work.
2. [automated] Streets read-only with the hint, no Add…/Unlink/Create New/Delete: knk-web-app
   `e2e/town-detail.spec.ts` ("lists the town's streets from its districts", "shows no Add…, Unlink, Create New or
   Delete on the streets", "says the streets are managed on the district"); `e2e/entity-detail.spec.ts` ("#409: a
   town's streets are read-only: no Add…, Unlink or Delete, and the hint");
   `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx` ("derived relationships (#409)").
3. [automated] The list is distinct, ordered by name then id, follows a street linked to or unlinked from a district
   and a district moving to another town; saving a town writes only the town: knk-web-api `TownStreetsDerivedTests`.
4. [automated] `POST api/Relationships/Town/{town}/streets/link` and `/unlink`: 400 `RelationshipNotEditable` with the
   reason for staff with the nodes, 403 without: knk-web-api
   `RelationshipsControllerTests.TownStreets_AreDerived_400WithTheReason_ForStaffWithTheNodes_403Without`.
5. [automated] Metadata lists Town `streets` as `storage: "derived"` with the reason and keeps the related-street field:
   knk-web-api `MetadataTownStreetsTests`.
6. [automated] Placeholders through `Town.Streets` (for example `Town.Streets.Count` on a district) load through the
   districts: knk-web-api `PlaceholderResolutionServiceTests` (`RewriteDerivedIncludes_LoadsTownStreetsThroughTheDistricts`,
   `ResolveLayer3Async_TownStreetsCount_LoadsThemThroughTheDistricts`).
7. [automated] A district keeps Add… and Unlink for its streets: knk-web-app `e2e/entity-detail.spec.ts` (link-table
   cases on District 1 "Old Quarter"), `DisplayWizard.relationships.test.tsx` ("a district keeps its Add… and Unlink
   for the same streets, without the hint").

## 3. Optional clean-up (manual: stored configurations)

1. A Town form with a `Streets` / `StreetIds` field or step does nothing now (the API ignores it). Remove it in the form
   builder if you want; the read-only check `scripts/maintenance/town-street-orphans-409.sql` (result set 3) lists such
   configurations.

## 4. Rollback (manual: only if needed)

1. `dotnet ef database update SeedStaffFreezeNodes` (the migration before `DropTownStreet`) recreates `TownStreet`
   and refills it from the districts; then deploy the previous API and web app. Rows no district covered come back
   only from the backup of § 1.1. The refill itself is automated (§ 1.4).
