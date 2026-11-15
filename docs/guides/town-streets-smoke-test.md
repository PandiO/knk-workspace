# Town streets from districts (#409) — smoke test

**Status:** 7 of 12 steps automated in CI (tagged, 1 of them partly); every step can still be run by hand; manual steps not run. Written 2026-11-15 (L3 [#516](https://github.com/PandiO/knk-workspace/issues/516)) for knk-web-api and knk-web-app `next` (L2 merged: API `de74190`, web app `d3d7152`); not on the trunk until the developer promotes `next`.
**Last updated:** 2026-11-15 (every step in full again, covered steps tagged `[automated: …]` or `[partly automated: …]`, developer decision 2026-11-15, #511); 2026-11-15
**Issues:** [PandiO/knk-workspace#409](https://github.com/PandiO/knk-workspace/issues/409); design
[specs/towns/DESIGN_TOWN_STREETS.md](../specs/towns/DESIGN_TOWN_STREETS.md); changelog entry "Town streets come from
their districts" in [CHANGELOG.md](../CHANGELOG.md).

A town's streets are now the distinct streets of its districts, read-only; the `TownStreet` table is dropped by the
migration `DropTownStreet`. Streets are added to or removed from a town on a district's detail page. About 20 minutes
for a full manual run (most of it the deploy), about 10 for the untagged steps. Steps tagged `[automated: …]` run in CI
(knk-web-api xUnit, CI jobs `build-and-test` and `fresh-database`; knk-web-app Playwright, CI job `e2e`, and Jest, CI
job `build-and-test`): skip them or run them by hand.

You need: an Admin account, the dev database and then the alpha database (real data), a town with several districts
that have streets.

## 1. Deploy (steps 1–3 manual: real databases)

1. Back up the database before deploying: the migration drops `TownStreet` with **all** its rows, including streets
   no district of the town has (developer decision 2026-11-14 on #515). Those come back only from the backup.
2. Deploy the API and the web app together (the web app reads `storage: "derived"` from the metadata; an older web
   app would offer Add…/Unlink that the API refuses).
3. Apply `DropTownStreet` on dev (`dotnet ef database update`), then on the alpha with the migrator image (runbook
   [§ API updates with migrations](closed-alpha-deployment-runbook.md)). The migration runs without errors and
   `TownStreet` is gone.
4. [automated: knk-web-api `Tests/knkwebapi_v2.Tests/Migrations/DropTownStreetMigrationTests.cs`
   (`Up_DropsOnlyTheTownStreetTable`, `Down_RecreatesTheTable_AsInitialCreateMadeIt`,
   `Down_RefillsFromTheDistricts_AfterTheTableAndIndexExist`); on MySQL
   `Tests/knkwebapi_v2.Tests/MySql/DropTownStreetMySqlTests.cs`
   (`Down_RefillsTownStreetFromTheDistricts_AndUpDropsItAgain`, needs `KNK_TEST_MYSQL`, skipped in CI)] On the dev
   database after step 3: `SHOW TABLES LIKE 'TownStreet';` is empty and every other table is still there. Then
   `dotnet ef database update SeedStaffFreezeNodes` (the migration before): `TownStreet` is back with the columns and
   index `InitialCreate` made, filled with one row per town and street of its districts
   (`SELECT COUNT(*) FROM TownStreet;` matches the distinct streets of the districts per town). Apply
   `DropTownStreet` again: the table is gone again.

## 2. The town's Streets

1. [partly automated: knk-web-app `e2e/town-detail.spec.ts` ("lists the town's streets from its districts", "shows no
   Add…, Unlink, Create New or Delete on the streets", "says the streets are managed on the district"),
   `e2e/entity-detail.spec.ts` ("#409: a town's streets are read-only: no Add…, Unlink or Delete, and the hint"),
   `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx` ("derived relationships (#409)");
   by hand: real data, that the list matches the real districts' streets] As Admin, open a real town with several
   districts (Dashboard → Town → the town). Its **Streets** section lists exactly the streets of its districts (open
   each district to compare), each once, by name; it shows the hint "Streets are managed on the district: open a
   district to add or remove them." and no **Add…**, **Unlink**, **Create New** or **Delete**; View and Edit on a
   street still work.
2. [automated: knk-web-api `Tests/knkwebapi_v2.Tests/Services/TownStreetsDerivedTests.cs`] On the dev database: link a
   street that one district of the town has to a second district of the same town: the town's Streets still lists it
   once. Two streets with the same name are listed by name, then by id. Unlink a street from the only district of the
   town that has it: it leaves the town's list. Move a district to another town (the district's Edit page): its
   streets leave the first town's list and show on the other town. Edit the town and save it without other changes:
   the districts' streets are unchanged.
3. [automated: knk-web-api `Tests/knkwebapi_v2.Tests/Api/RelationshipsControllerTests.cs`
   (`TownStreets_AreDerived_400WithTheReason_ForStaffWithTheNodes_403Without`)] API: as staff with `knk.admin.world`
   and `knk.admin.content`, `POST api/Relationships/Town/{town}/streets/link` with `{ "relatedId": {street} }` and
   `POST api/Relationships/Town/{town}/streets/unlink` answer 400 `RelationshipNotEditable` with the reason (streets
   are managed on the district); as a web account without those nodes: 403.
4. [automated: knk-web-api `Tests/knkwebapi_v2.Tests/Services/MetadataTownStreetsTests.cs`] `GET api/Metadata/Town`
   as Admin: the `streets` relationship says `storage: "derived"` with the reason, and Town's related-street field is
   still listed.
5. [automated: knk-web-api `Tests/knkwebapi_v2.Tests/Services/PlaceholderResolutionServiceTests.cs`
   (`RewriteDerivedIncludes_LoadsTownStreetsThroughTheDistricts`,
   `ResolveLayer3Async_TownStreetsCount_LoadsThemThroughTheDistricts`)] A text with a placeholder through
   `Town.Streets` (for example `Town.Streets.Count` in a district's form or display) shows the number of the town's
   streets, loaded through its districts, the same number as the town's Streets section.
6. [automated: knk-web-app `e2e/entity-detail.spec.ts` (link-table cases on District 1 "Old Quarter"),
   `DisplayWizard.relationships.test.tsx` ("a district keeps its Add… and Unlink for the same streets, without the
   hint")] Open one of the town's districts: its **Streets** section has **Add…** and **Unlink**, without the hint.
   Add… a street, then open the town: the street is in its list. Unlink it on the district again: it leaves the town's
   list (unless another district of the town has it).

## 3. Optional clean-up (manual: stored configurations)

1. A Town form with a `Streets` / `StreetIds` field or step does nothing now (the API ignores it). Remove it in the form
   builder if you want; the read-only check `scripts/maintenance/town-street-orphans-409.sql` (result set 3) lists such
   configurations.

## 4. Rollback (manual: only if needed)

1. `dotnet ef database update SeedStaffFreezeNodes` (the migration before `DropTownStreet`) recreates `TownStreet`
   and refills it from the districts; then deploy the previous API and web app. Rows no district covered come back
   only from the backup of § 1.1. The refill itself is automated (§ 1.4).
