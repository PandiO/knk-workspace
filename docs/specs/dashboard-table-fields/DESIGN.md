# Dashboard table fields — related names in columns, search on them, search coverage shown

**Status:** **Proposed** (2026-11-15), waiting for the developer's OK before building. Issue
[PandiO/knk-workspace#608](https://github.com/PandiO/knk-workspace/issues/608), from the developer's smoke test of
[#408](https://github.com/PandiO/knk-workspace/issues/408) on `next`. Branch `claude/related-display-fields-608` in
knk-workspace (this doc, from `main`), knk-web-api and knk-web-app (code, from `next`, after the OK).
**Last updated:** 2026-11-15.

## 1. Problem

1. `/dashboard/PermissionGrant` shows the holder as "Group #8" or "User #12". The list DTO carries only `holderId` and
   `holderType`; the web app builds the text (`knk-web-app src/config/objectConfigs.tsx`, `permissiongrant`).
2. The search box matches the node only (`knk-web-api Repositories/PermissionGrantRepository.cs`, `SearchAsync`), so
   typing a group's name, or "Group #8", finds nothing.
3. Every table's search box says "Search..." (`components/PagedEntityTable/PagedEntityTable.tsx`). What a search
   covers is hand-written LINQ in each of the 31 repositories that read `SearchTerm`, and nothing tells the user which
   fields that is.
4. Other tables show a foreign id too: Category's Parent column shows `Name(5)`; LootboxSpecialEntry and GateDoor fall
   back to `#<id>` when the name is missing.

## 2. What already exists (checked for reuse)

1. **Access-model metadata (#280).** `GET api/Metadata/entities` returns `EntityMetadataDto` per type (fields, default
   columns, access flags). The `DashboardAccess` registry (`Attributes/DashboardAccess.cs`) holds each type's search
   delegate; it delegates to the type's own repository search. Reusable as the **place to publish** which fields a
   table's search covers (a new `searchFields` list on `EntityMetadataDto`). It holds no field-level search or display
   logic.
2. **Lookup labels (#280 AM2) and the relation picker / "Show what uses it" (#288, #289).** `DashboardLookups` names a
   record by id (`ILookupService`), one record at a time, after loading it through the type's service. Right for a
   picker or a list of 20 references; wrong for a table column: it runs per row after paging, so sorting and searching
   by the name across pages are impossible.
3. **PermissionHolder already resolves names in SQL.** `Repositories/PermissionHolderRepository.cs` unions `Users`
   (`Username`) and `PermissionGroups` (`Name`) as `{ Id, Name, HolderType }`. That is the polymorphic resolution we
   need; it only lives in the holder's own repository.
4. **The #408 sort mapping.** `PermissionGrantRepository.ApplySorting` maps the column key (`holderid`, `node`, ...) to
   a LINQ key with a stable tie-breaker. The new mechanism generalises this switch.
5. **Flat name fields on list DTOs** (`townName`, `categoryName`, `parentGroupName`, `gateStructureName`): the current
   per-type pattern. Display works; whether search and sort cover them differs per repository.

## 3. Options

| | Option | Display | Server paging, sort, search on the name | Reusable | Search coverage visible | Cost and risk |
|---|---|---|---|---|---|---|
| A | Per type, by hand: add `holderName` to the DTO, extend the repository's search and sort (as GateDoor does) | yes | yes | no, repeated per type | no | small; the gap in § 1.3 stays |
| B | Web app resolves ids with `api/Lookup/{type}/{id}` per row | yes | **no** (only the current page) | yes | no | one request per row; search by name impossible |
| C | API fills names after paging from `DashboardLookups` labels (#280/#289) | yes | **no** (in memory after paging) | yes | no | N+1 reads per page |
| D | **Table field sets:** per type, a short list of named fields, each one LINQ expression, used for the column value, the search and the sort, and published in the metadata | yes | yes (one SQL query) | yes | yes | small helper; types join one by one |
| E | Denormalised name column or SQL view for holders | yes | yes | no | no | migration, and renames must be kept in sync |
| F | String paths in metadata (`Holder.Name`) built with dynamic LINQ | yes | yes | yes | yes | new library; polymorphic holder needs a special case anyway; typos fail at runtime |

## 4. Recommendation: D, table field sets

1. **One declaration per type** (API, new `Repositories/TableFields/`):
   ```csharp
   // PermissionGrant: the holder's name through the TPT subtype, its kind as the table shows it, the node.
   public static readonly TableFieldSet<PermissionGrant> Fields = new(
       TableField.Text<PermissionGrant>("node", "node", g => g.Node),
       TableField.Text<PermissionGrant>("holderName", "holder name",
           g => g.Holder is User ? ((User)g.Holder).Username
              : g.Holder is PermissionGroup ? ((PermissionGroup)g.Holder).Name : null),
       TableField.Text<PermissionGrant>("holderType", "holder type",
           g => g.Holder is PermissionGroup ? "Group" : "User"));
   ```
   Each field has a key (the DTO property and the column's sort key), a label (for the placeholder) and an
   `Expression<Func<T, string?>>`. EF Core translates the TPT `is`/cast to the joins it already makes for `Holder`.
2. **Search:** `Fields.ApplySearch(query, term)` ORs `value != null && value.ToLower().Contains(term)` over the
   searchable fields, built once from the expressions, in the same SQL as the paging. Searching "Builders" finds every
   grant of the group Builders; "group" finds every group grant. Filters (`holderId`) stay as they are.
3. **Sort:** `Fields.ApplySort(query, sortBy, descending)` sorts by a field's expression when `sortBy` names one, else
   the repository's own switch runs (id, value, expiresAt stay there). The tie-breakers stay (node, then id).
4. **Display:** the list DTO gets the field as a property (`holderName`); the mapping reads it with the compiled
   expression from the loaded row (the repository already includes `Holder`, and EF materialises the concrete
   subtype), so the column, the sort and the search all use the same definition.
5. **Search coverage in metadata:** `EntityMetadataDto.searchFields` lists the labels of the searchable fields
   (`["node", "holder name", "holder type"]`), filled from a small registry of field sets by type name. The web app's
   `PagedEntityTable` shows them as the placeholder: "Search node, holder name or holder type…". A type without a
   field set keeps "Search…" (and `searchFields` is absent), so nothing changes for it.
6. **Web app columns:** the Holder column renders `holderName` with the kind, "Builders (group)" or "Steve (user)",
   and falls back to today's "Group #8" only when the name is missing; it sorts by `holderName`. A helper
   `relatedNameColumn(key, label, nameKey, idKey)` in `objectConfigs.tsx` gives other tables the same column with the
   `#<id>` fallback.
7. **Second table: Category.** Its Parent column shows `Name(5)` today. With a field set (`name`, `parentCategoryName`)
   the column shows the parent's name, sorts by it, and the search covers name and parent name ("Search name or
   parent category…").
8. **No schema change, no flag.** Additive: a DTO property, a metadata list, a placeholder text. Proposed tier:
   `tier:2` (automated tests plus a short manual look at the table).
9. **Other types join later**, one field set each, replacing their hand-written search when they do (follow-up issue,
   filed at merge): GateDoor, LootboxSpecialEntry, Structure, District and the rest of the 31 repositories.

## 5. Tests (phase 2)

1. API xUnit (in-memory, `Tests/.../Repositories/PermissionGrantRepositoryTests.cs` and a new `TableFieldSetTests.cs`):
   the list row carries the group name and the username; search by a group name returns all of that group's grants
   and no others; search by username; search by "group"; sort by `holderName` both ways; Category search by parent
   name and sort by it; metadata `searchFields` for PermissionGrant and Category, absent for a type without a set.
2. Playwright e2e on `/dashboard/permissiongrant` (mocked API): the Holder column shows "Builders (group)"; the
   placeholder names the covered fields; typing "Builders" sends `searchTerm: "Builders"` and shows that group's grants.
3. Smoke guide: new steps in `guides/dashboard-access-smoke-test.md` § 8.6, tagged as automated where a test covers
   them; CHANGELOG entries in all three repos' changes (workspace `docs/CHANGELOG.md`).

## 6. Decisions for the developer

1. **Approve option D** (table field sets) over A (per type by hand).
2. **Second table:** Category (recommended) or LootboxSpecialEntry / GateDoor.
3. **Search by id ("#8")**: not included by default, since the name is now shown. Say if a term like `#8` should also
   match the holder id.
4. **Holder label format:** "Builders (group)" / "Steve (user)" (recommended), or the name only with a separate Type
   column.
