# Town streets from districts — design note

**Status:** Approved 2026-11-14 (defaults), implemented in L2 · **Last updated:** 2026-11-15

**Developer decisions (2026-11-14, on [#515](https://github.com/PandiO/knk-workspace/issues/515)):** all six
recommended defaults of § 8 approved; orphan `TownStreet` rows are all dropped with the table (no per-row linking, the
pre-migration backup is the way back). L2 built it as written (knk-web-api and knk-web-app branches
`claude/town-streets-409`).

**Issue:** [PandiO/knk-workspace#409](https://github.com/PandiO/knk-workspace/issues/409), link L1
[#514](https://github.com/PandiO/knk-workspace/issues/514); implementation L2
[#515](https://github.com/PandiO/knk-workspace/issues/515), smoke tests L3
[#516](https://github.com/PandiO/knk-workspace/issues/516).
**Charter:** [handoffs/TOWN_STREETS_CHAIN.md](https://github.com/PandiO/knk-workspace/blob/main/docs/ai-agents/handoffs/TOWN_STREETS_CHAIN.md) (on `main`).
**Data check:** [scripts/maintenance/town-street-orphans-409.sql](../../../scripts/maintenance/town-street-orphans-409.sql).
**Read on:** knk-web-api `next` `b9ce7f05`, knk-web-app `next` `8918eba0`, knk-plugin `next` `a760c4a4` (2026-11-14).

Developer decision 2026-11-13: `Town.Streets` is the distinct streets of the town's districts, read-only, and the
separate `TownStreet` link table is dropped. This note says how L2 builds that. Why here: the note is about the Town
entity of the towns domain, so it sits next to [SPEC_TOWNS.md](SPEC_TOWNS.md) in `docs/specs/towns/` rather than in a
new folder; the world model has no living architecture doc of its own, and
[web-api-architecture.md](../../architecture/web-api-architecture.md) is updated by L2 only where it names `TownStreet`
(§ 9).

## 1. Today

1. **Model.** `Models/Town.cs` has `Streets` (`[NavigationPair]`, `[RelatedEntityField(typeof(Street))]`) and
   `Districts`. `Properties/KnKDbContext.cs` ~1621 maps `Town.Streets` as a skip navigation through the hidden join
   table `TownStreet(StreetId, TownId)` (PK both, index `IX_TownStreet_TownId`, both FKs cascade; from
   `20251223135917_InitialCreate`). `Street` has no navigation back to towns.
2. **The real link.** `District.Streets` ↔ `Street.Districts` through `DistrictStreet(DistrictId, StreetId)`;
   `District.TownId` is required (`districts.TownId`). Town, District and Structure are TPT children of `domains`
   (names live in `domains.Name`).
3. **DTO.** `TownDto.streetIds` and `TownDto.streets` (`TownStreetDto { id, name }`) are filled from `Town.Streets` in
   `Mapping/TownMappingProfile.cs`; on create and update the mapping ignores `Streets` (the input fields already do
   nothing).
4. **Who loads `Town.Streets`:**
   1. `Repositories/TownRepository.cs` `GetByIdAsync`: `.Include(t => t.Streets)` (with `Location`, `Districts`,
      `SubRegions`). It serves `GET api/Towns/{id}` and, tracked, `TownService.UpdateAsync` and `DeleteAsync`.
   2. `GetAllAsync` (`GET api/Towns`) includes only `Location`, so its `TownDto.streets` is always empty today;
      `SearchAsync` returns `TownListDto` (no streets).
   3. `Services/RelationshipService.cs`: `RelationshipCatalog.Supported["Town.Streets"] = (true, true)`; the catalog is
      built from the EF model, so `Town.Streets` shows in metadata `relationships` as `storage: "many"`, and
      `POST api/Relationships/Town/{id}/streets/link|unlink` inserts or deletes `TownStreet` rows.
   4. `Services/MetadataService.cs` lists `Streets` as a field of Town by reflection (`IsRelatedEntity`,
      `RelatedEntityType: "Street"`).
   5. `Services/PathResolutionService.cs` validates paths such as `Town.Streets[0].Name` by reflection; only a test
      (`DependencyResolutionHealthCheckTests`, mocked) uses that path. `PlaceholderResolutionService` loads placeholder
      paths with string `Include(...)`.
   6. `Services/FormTemplateValidationService.cs` names `Town.Streets` only in a doc comment.
   7. No seeder: `Data/FormConfigurationSeeds/Town.json` has no Streets field (the word appears only in the
      `RoadAccessOverride` help text) and `Data/DisplayConfigurationSeeds/` has no Town file.
   8. knk-workspace `scripts/seed/seed-tables.sh` exports `TownStreet` in `WORLD_TABLES`.
5. **Tests that use `Town.Streets` as the example of a link table:** knk-web-api
   `Services/RelationshipServiceTests.cs` (`Streets_AddAndUnlink_OnATown_TheStreetStays`, the catalog listing line
   `"Town.Streets Many Street link=True unlink=True"`), `Api/RelationshipsControllerTests.cs` (gate test on
   `town/Streets`); knk-web-app `src/apiClients/__tests__/relationshipClient.test.ts` and
   `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx` (Town `streets` with `storage:
   'many'`).

## 2. Read path

1. **Model.** `Town.Streets` stays on the class as a read-only computed collection, so metadata, display
   configurations and path validation keep seeing it:

   ```csharp
   /// #409: the distinct streets of this town's districts; read-only, changed on the district.
   [NotMapped]
   [RelatedEntityField(typeof(Street))]
   public IReadOnlyList<Street> Streets => Districts
       .SelectMany(d => d.Streets)
       .GroupBy(s => s.Id).Select(g => g.First())
       .OrderBy(s => s.Name, StringComparer.OrdinalIgnoreCase).ThenBy(s => s.Id)
       .ToList();
   ```

   `[NavigationPair]` goes (it names an editable pair). The `HasMany(t => t.Streets)...UsingEntity("TownStreet")`
   block in `KnKDbContext` goes.
2. **Ordering.** By name (case-insensitive), then id, so the list is stable; today's order is whatever the join
   table returns.
3. **Mapping.** `TownMappingProfile` keeps `streetIds` and `streets` (same JSON shape, `TownStreetDto` unchanged) and
   maps them from the computed `Streets`. The DTO → entity map keeps ignoring them (output only). No API client
   changes shape.
4. **Detail (`GET api/Towns/{id}`).** A new read method `TownRepository.GetDetailAsync(id)`:
   `AsNoTracking()`, `Include(Location)`, `Include(SubRegions)`, `Include(Districts).ThenInclude(d => d.Streets)`,
   `AsSplitQuery()` (as `SiegeMatchRepository` does), so a town with many districts, streets and sub-regions does not
   multiply rows in one join. Cost: one query per collection (about 4 small queries), no N+1 (lazy loading is off in
   the API). `TownService.GetByIdAsync` uses it.
5. **Update and delete.** `GetByIdAsync` (tracked) stays for `UpdateAsync` / `DeleteAsync` and loses the
   `Streets` include; it does not add the district streets, because `_context.Towns.Update(town)` marks every
   loaded entity modified and would write every district street row back on each town save.
6. **List (`GET api/Towns`) and paged search.** Unchanged: the list never loaded streets (empty `streets`, as
   today) and search returns `TownListDto`. Loading streets for every town on the list is not needed by any caller
   (§ 5) and would cost two extra queries per page.
7. **Following district changes.** The list is computed on every read, so linking or unlinking a street on a district
   (`District/{id}/streets`, `Street/{id}/districts`) or moving a district shows on the town at once. Nothing to keep
   in sync, no cache in the API.
8. **Other readers.**
   1. `MetadataService`: `Streets` stays a Town field (`IsRelatedEntity`, `Street`), so display configurations can
      still show it.
   2. `PathResolutionService`: `Town.Streets[0].Name` stays valid (reflection).
   3. `PlaceholderResolutionService`: a placeholder path through `Town.Streets` would ask EF for
      `Include("…Streets")` on a not-mapped property and fail. L2 rewrites a `Streets` segment on a Town to
      `Districts.Streets` when it builds include paths (a small alias map `DerivedIncludes` next to the include
      builder), with an xUnit test. The SQL check § 3 lists stored rules that use such a path; on 2026-11-14 the seeds
      have none.
   4. EF LINQ on `t.Streets` (a `Where` or `Select` on the property in a query) would no longer translate; on `next`
      only tests do that (§ 1.5). L2 greps for it again.

## 3. Removing the link

1. **Catalog entry.** `RelationshipCatalog` gets a small list of derived relationships next to `Supported`:

   ```csharp
   /// Read-only collections computed from other links (#409): shown on the page, changed elsewhere.
   public static readonly IReadOnlyDictionary<string, (string RelatedType, string Reason)> Derived = …
   {
       ["Town.Streets"] = ("Street", "Streets are managed on the district: open a district to add or remove them."),
   };
   ```

   `Build` adds a descriptor for each entry with `Storage = Derived` (new enum value, DTO `storage: "derived"`),
   `IsCollection = true`, `CanLink = CanUnlink = false`, `LinkReason = UnlinkReason = Reason`, `Nodes` = the owner's
   change nodes. `["Town.Streets"] = (true, true)` leaves `Supported`.
2. **Metadata.** Town's `relationships` keeps a `streets` entry, now `{ storage: "derived", canLink: false,
   canUnlink: false, linkReason, unlinkReason }`. That is the generic "read-only relationship" flag the web app needs
   (§ 4), and the hint text has one source.
3. **Route.** `POST api/Relationships/Town/{id}/streets/link` and `/unlink`: the gate attribute finds the
   relationship, checks the nodes (403 without them, as for any relationship), then `LinkAsync` / `UnlinkAsync`
   refuse with **400 `RelationshipNotEditable`** and the reason ("Streets are managed on the district: …"), the code
   the web app already handles. Nothing is written. A plugin caller still gets 403 ("Links are changed from the web
   app.").
4. **Why a refusal and not 404.** Dropping the navigation from the catalog would give 404 `UnknownRelationship` for
   free, but metadata would then lose the entry and the web app would need a per-type special case for the hint.
   With the derived entry the reason travels with the metadata and the route says why.

## 4. Web app

1. **Where.** The town detail page is `DisplayWizard` (`/display/Town/{id}`) with a stored display configuration; the
   Streets section is a collection section with `relatedEntityPropertyName: "Streets"`. `DisplaySection.tsx` finds the
   relationship (`detailPage.ts` `findRelationship`) and passes it to `ActionButtons.tsx` and `CollectionSection.tsx`;
   the relationship client (`src/apiClients/relationshipClient.ts`) does the link calls.
2. **Change, generic.** `RelationshipMetadataDto.storage` gains `'derived'`
   (`src/types/dtos/metadata/MetadataModels.ts`). A small helper `isDerived(relationship)` in `detailPage.ts`. When
   the section's relationship is derived:
   1. no Add…, Unlink (section and item level), Create New and Delete buttons, whatever the stored configuration's
      `show…Button` flags say (Create New would create a street with no district; Delete would delete the street
      from every district);
   2. View and Edit of a street stay (they open the street);
   3. a visible hint under the section header, the relationship's `linkReason` ("Streets are managed on the district:
      open a district to add or remove them."), as a plain `<p>` with `data-testid="derived-hint"`, not as the greyed
      button hint.
3. **Why a flag and not a Town special case.** The page already takes everything from metadata; a `derived` storage
   works for any later computed collection and keeps the text in the API.
4. **Config builder.** `src/utils/configBuilder/scaffold.ts` may keep scaffolding a Streets section for Town (it is
   still a field); no change needed.
5. **Town DTO type.** `src/types/dtos/town/TownDto.ts` keeps `streetIds`; the create DTO's `streetIds` is dropped
   (the API ignored it already). L2 checks no form sends it.

## 5. Plugin

knk-plugin `next` reads `town.streets` only for display; nothing in navigation, the destination engine or roads reads
it (they use the road network's own street list, `RoadNetworkMetaDto.streets`):

1. `knk-api-client/src/main/java/net/knightsandkings/knk/api/dto/TownDto.java` (`streetIds`, `streets`) and
   `TownStreetDto`;
2. `knk-api-client/src/main/java/net/knightsandkings/knk/api/mapper/TownsMapper.java` `mapDetail` (with
   `TownsMapperTest`);
3. `knk-core/src/main/java/net/knightsandkings/knk/core/domain/towns/TownDetail.java` (`streetIds`, `streets`,
   `TownStreet`);
4. `knk-paper/src/main/java/net/knightsandkings/knk/paper/commands/TownsDebugCommand.java` lines 191–193 (prints the
   streets of a town).

The JSON shape stays, so the plugin needs **no change**; the debug command shows the derived list after L2. No plugin
tests.

## 6. Data: configurations, the check and the migration

1. **Seeds and stored configurations.** No API seeder references `Town.Streets` (§ 1.4.7). Stored configurations in a
   database can (the knk-dev-db-seed carries the dev and alpha display configurations; L1 has no access to it):
   1. a Town display section on `Streets`: keeps working (the DTO still has `streets`); the buttons go by § 4.2. No
      data change.
   2. a Town form field `Streets` / `StreetIds` or a form step on `Streets`: the API ignores it already; L2 changes no
      data, the developer removes such a field in the form builder if the check finds one (admin step in the
      changelog).
   3. a validation rule or placeholder path through `Town.Streets`: handled by § 2.8.3.
   4. knk-workspace `scripts/seed/seed-tables.sh`: L2 removes `TownStreet` from `WORLD_TABLES` (the export would fail
      on the missing table); the next seed rebuild drops the table's rows.
2. **The check.** [scripts/maintenance/town-street-orphans-409.sql](../../../scripts/maintenance/town-street-orphans-409.sql),
   SELECT only. Three result sets: (1) orphan `TownStreet` rows (the street is in none of the town's districts) with
   town id and name, street id and name, the districts the street is linked to in any town and the town's own
   districts; (2) counts: all `TownStreet` rows, orphans, rows the districts already cover, derived town–street pairs
   and the pairs that will newly show on a town page; (3) Town form and display configurations, drafts and
   validation rules that name `Streets` / `Town.Streets`. Run:
   1. dev: `mysql -u<user> -p <dev database> < scripts/maintenance/town-street-orphans-409.sql`, or phpMyAdmin's SQL
      tab;
   2. alpha (closed alpha NAS): copy the file into the `knk-alpha-mysql` container (or paste it into phpMyAdmin) and
      run `mysql -uroot -p knightsandkings_alpha < town-street-orphans-409.sql`; read only, so no backup is needed for
      the check itself;
   3. paste the three result sets (or "no rows") on #515 for the decision.
   Tried on MariaDB 10.11 against a hand-made schema with the same table and column names (orphans, a street linked
   only in another town, nested display sections); not yet run on MySQL 9.6 or real data.
3. **The migration (L2, one, `dotnet ef migrations add DropTownStreet`).**
   1. `Up`: `DropTable("TownStreet")` (its FKs and index go with it). The model snapshot loses the `TownStreet`
      entity.
   2. `Down`: recreates `TownStreet` exactly as `InitialCreate` made it (columns `StreetId`, `TownId` int, PK
      `PK_TownStreet (StreetId, TownId)`, index `IX_TownStreet_TownId`, FKs `FK_TownStreet_streets_StreetId` and
      `FK_TownStreet_towns_TownId`, cascade) and **refills it from the districts**:
      `INSERT INTO TownStreet (StreetId, TownId) SELECT DISTINCT ds.StreetId, d.TownId FROM DistrictStreet ds JOIN
      districts d ON d.Id = ds.DistrictId;`
      Why refill: after a rollback the old code reads `Town.Streets` from the table again, and a refilled table makes
      it show what the new code showed, instead of empty Streets sections. Orphan rows dropped by `Up` cannot come
      back from `Down`; the backup taken before the migration (L3's admin step) is the way back for them.
   3. **Existing rows.** Rows the districts cover are redundant and go with the table. Orphan rows go too, unless the
      developer decides per row (on #515, from the check's result on dev and alpha) to link the street to a district
      of that town first; that is done in the web app (District detail page → Streets → Add…) before the migration
      runs, not by the migration. The migration does not refuse to run when orphans remain (a data rule is not a
      migration's job; the check and the decision come first).

## 7. Tests L2 writes (knk-test-writer § 2)

1. **xUnit, knk-web-api `Tests/knkwebapi_v2.Tests/`** (`dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`):
   1. `Services/TownStreetsDerivedTests.cs` (new; in-memory context as the neighbouring service tests): a town's
      `TownDto.streets` / `streetIds` from `TownService.GetByIdAsync` are the streets of its districts; a street in two
      districts of the town shows once; a street of another town's district does not show; ordered by name then id; a
      town without districts has an empty list.
   2. same file: after `RelationshipService.LinkAsync("District", d, "streets", s)` (and after an unlink) the town's
      list follows; after a district moves to another town, its streets move with it.
   3. same file: `TownService.UpdateAsync` writes no street or district rows (change tracker shows only the town
      modified).
   4. `Services/RelationshipServiceTests.cs`: replace `Streets_AddAndUnlink_OnATown_TheStreetStays` with
      `Streets_OnATown_AreDerived_LinkAndUnlinkRefused` (400 `RelationshipNotEditable` with the district reason,
      nothing written); update the catalog listing line to `Town.Streets Derived Street link=False unlink=False`;
      keep a link-table example on `District.Streets`.
   5. `Api/RelationshipsControllerTests.cs`: `POST api/Relationships/Town/{id}/streets/link` answers 400
      `RelationshipNotEditable` for staff with the nodes and 403 without them.
   6. `Services/MetadataService…` (existing metadata tests or a new `MetadataTownStreetsTests.cs`): Town's
      `relationships` has `streets` with `storage: "derived"`, `canLink`/`canUnlink` false and the reason; `fields`
      still has `Streets` as a related `Street` collection.
   7. `Services/PlaceholderResolutionServiceTests.cs`: a placeholder through `Town.Streets` resolves (include path
      rewritten to `Districts.Streets`).
   8. `Migrations/DropTownStreetMigrationTests.cs` (operations, like `AddInvitationsMigrationTests`): `Up` drops
      `TownStreet`; `Down` creates it with the PK, index and both FKs and runs the refill SQL.
   9. `MySql/DropTownStreetMySqlTests.cs` (needs `KNK_TEST_MYSQL`, skipped otherwise): `Down` after `Up` on a database
      with districts and streets refills `TownStreet` with the derived pairs.
2. **Jest, knk-web-app next to the code** (`npm run test:ci`):
   1. `src/components/DisplayWizard/__tests__/ActionButtons.test.tsx`: a derived relationship renders no Add…, Unlink,
      Create New or Delete even with all `show…Button` flags on; View/Edit stay.
   2. `src/components/DisplayWizard/__tests__/DisplayWizard.relationships.test.tsx` and
      `src/apiClients/__tests__/relationshipClient.test.ts`: move the link-table example from Town `streets` to
      District `streets`; add a Town `streets` derived case showing the hint.
   3. `detailPage.ts` `isDerived`: a unit test in `src/components/DisplayWizard/__tests__/`.
3. **Playwright e2e, knk-web-app `e2e/town-detail.spec.ts`** (new; `npm run typecheck:e2e`, `npm run test:e2e`, CI job
   `e2e`): with the mocked API (metadata with the derived `streets`, a Town display configuration with a Streets
   section, `Towns/4` with two streets) the town page lists the streets, shows no Add… or Unlink button and shows the
   hint "Streets are managed on the district"; typed fixtures in `e2e/fixtures/`.
4. **Plugin:** none (no reader changes, § 5).
5. **Manual only (L3's guide):** running the check and the migration on the alpha with real data; the dashboard access
   smoke test steps move to `District/{district}/streets` (L3).

## 8. Open questions for the developer

1. **Orphan rows.** Per row of the check's result on dev and alpha: link the street to a district of that town, or
   let it go with the table? Recommended default: let it go (the issue says the table was not maintained), unless you
   name rows to keep; reversible until the migration runs (and from the backup after).
2. **Link route answer.** 400 `RelationshipNotEditable` with the district reason (§ 3), or 404 `UnknownRelationship`?
   Recommended default: 400 with the reason; switching to 404 is removing one catalog entry.
3. **`Down` refill.** Refill `TownStreet` from the districts on rollback (§ 6.3.2), or recreate it empty? Recommended
   default: refill; an empty table is the one-line alternative.
4. **Buttons on a derived section.** Hide Create New and Delete as well as Add… and Unlink (§ 4.2)? Recommended
   default: hide all four, keep View/Edit; reversible in one helper.
5. **Hint wording.** "Streets are managed on the district: open a district to add or remove them." Recommended
   default: this text (one string in the API catalog).
6. **List endpoint.** Keep `GET api/Towns` without streets (as today, § 2.6)? Recommended default: keep; adding them
   is one `ThenInclude` if a caller needs them.

## 9. Docs impact (for L2 and the docs session)

1. [web-api-architecture.md](../../architecture/web-api-architecture.md): line 51 (join tables: drop `TownStreet`),
   § on relationships (~227–247: `Many` example becomes `DistrictStreet`, add `Derived`, "town and district streets"
   becomes "district streets; a town's streets are derived").
2. [API_CONTRACT_TOWNS.md](../api/API_CONTRACT_TOWNS.md): `TownDto.streets` / `streetIds` are read-only, derived from
   the districts.
3. `scripts/seed/seed-tables.sh`: `TownStreet` out of `WORLD_TABLES` (L2, § 6.1.4).
4. [dashboard-access-smoke-test.md](../../guides/dashboard-access-smoke-test.md) § 2.2 step 2 and § 8 step 9b (L3).
5. Changelog entry with the admin steps (backup, run the check, decide, migrate) (L2/L3).
6. This note: status to "Approved" with the developer's answers, then "Implemented" after L2.
