# Form wizard — entities created in a form session, and editing them again

**Status:** Design decided (2026-10-11): D1 = A (developer), D2 default chosen (reversible, developer may override).
Being implemented by the [form wizard chain](../../ai-agents/handoffs/FORM_WIZARD_CHAIN.md).
**Last updated:** 2026-10-12 (§5 items 1-3 status, KNG-133, KNG-134, KNG-135)
**Linear:** [KNG-133](https://linear.app/kngpandi/issue/KNG-133) (List "Create New" never saved),
[KNG-136](https://linear.app/kngpandi/issue/KNG-136) (pickers show entities made in this session),
[KNG-134](https://linear.app/kngpandi/issue/KNG-134) (Edit instance opens without its values),
[KNG-135](https://linear.app/kngpandi/issue/KNG-135) (List relationships load empty in edit mode),
[KNG-162](https://linear.app/kngpandi/issue/KNG-162) (cancelled main form: offer to delete what its child forms saved)
**Sources:** knk-web-app `main` `38854ba`, knk-web-api `master` `917537a`, knk-plugin `main` `1b3e06c2`. Paths
below are relative to `knk-web-app/src` unless prefixed `api/` or `plugin/`.
**Related:** [KNG-120](https://linear.app/kngpandi/issue/KNG-120) (same-property fields in sync, in progress in
`FormWizard.tsx`), [KNG-130](https://linear.app/kngpandi/issue/KNG-130)/[KNG-131](https://linear.app/kngpandi/issue/KNG-131)
(child-form Location fixes, merged), the seeding plan in [DEFAULT_FORM_SEEDS.md](DEFAULT_FORM_SEEDS.md).

## 1. What the developer reported

Scenario: create a **GateStructure**. From its Street field, **Create New** opens a Street child form. A Street needs
at least one District, so inside the Street form **Create New** opens a District child form (two levels deep).
Submit the District, then the Street; the Street shows in the GateStructure form.

1. The GateStructure's own District picker (a `PagedEntityTable` fed by the District search endpoint) does not list
   the District just made in the nested form. Wanted: pickers also show the entities created in this form session.
2. **Edit instance** on that Street opens the Street form with no District selected. The same happens with other
   entities: reopening a child form doesn't load its relationships.
3. A Location captured through a Minecraft world task, then **Edit instance** in the same session: the Location
   form opens without the captured values.

The developer's working assumption was that child-form "submits" are held until the root form is submitted. That is
only partly true, and the difference is the root cause of point 1 and most of point 2 (§2).

## 2. How it works today (verified in code)

### 2.1 Which child forms are saved immediately

`FormWizard.handleOpenChildForm` (`components/FormWizard/FormWizard.tsx:1793-1832`) decides per field:

```
shouldPersistIndependently = ownedChildCollection || (fieldType === Object && objectType !== 'Location')
```

When the child form completes, `handleChildFormComplete` (`FormWizard.tsx:1885-1993`):

| Field kind | Example | What happens on child completion |
|---|---|---|
| Single **Object** relationship (not Location) | GateStructure → Street | **Saved to the DB at once** (`createFn`/`updateFn`, :1928-1948); the field holds the returned DTO with its id |
| **List** marked `ownedChildCollection` | GateStructure → GateDoors | Saved at once, same path |
| **List**, not owned | Street → Districts | **Not saved.** The id-less form data goes into the field state (:1976-1980) |
| **Location** (Object) | Town/GateStructure → Location | Not saved. Embedded value; the API creates it with the parent |
| Many-to-many step | SiegeScenario → Districts | Saved at once by `ManyToManyRelationshipEditor.handleCreateRelatedEntity` (:377-449) |

There is no "concept" store, no temporary id scheme and no session-wide registry. The only React context in the app
is `AuthContext`. `parentContext` flows down to a child but nothing flows back except the completed value, and
`ChildFormModal` unmounts its nested wizard when it closes (`ChildFormModal.tsx:197`).

### 2.2 Why the District disappears (point 1, and point 2 for Street)

1. The District is created from the Street's **non-owned List** field, so it stays an id-less object in the Street
   form's state.
2. On the Street's completion, the payload goes through `normalizeFormSubmission`. `extractId`
   (`utils/forms/normalizeFormSubmission.ts:79-101`) returns `null` for an object without an id and
   `handleCollectionRelationship` (:478-512) filters it out, so `districtIds` is `[]`. The navigation array is
   dropped. The single-object branch (:451-468) drops id-less non-Location values the same way.
3. The Street is an Object field of the GateStructure, so it **is** saved at once
   (`api/Services/StreetService.cs:69-79` reads only `DistrictIds`). It is saved with no Districts.
4. **The District is never written to the database at all.** That is why the GateStructure's District picker can't
   find it, and why **Edit instance** on the Street (which re-reads Street id N from the DB) shows no District.

The client-side "at least one District" check passed because the id-less object counted as a selection; the API
received an empty list. This is silent data loss: nothing tells the admin the District was dropped.

If the developer's Street form uses a **many-to-many step** for Districts instead of a List field, the District is
saved immediately and this section does not apply; the dev-DB Street config should be checked when fixing.

### 2.3 Why Edit instance opens empty (points 2 and 3)

- **Id-less values open as Create New.** `handleOpenChildForm` passes only `entityId = String(existingInstance.id)`
  (`FormWizard.tsx:1795`), never the instance's values. A value without an id (a world-task Location, a List item
  from §2.2) therefore opens a blank **Create New** form (`ChildFormModal.tsx:207` titles it so). The only seeded
  value is the field linking back to the parent (`ChildFormModal.tsx:189-195`, `findParentLinkField`).
- **World-task Locations have no id.** `WorldBoundFieldRenderer.extractTaskResult`
  (`components/Workflow/WorldBoundFieldRenderer.tsx:313-327`) writes `{name, x, y, z, yaw, pitch, World}` from the
  plugin's output (`plugin/.../tasks/LocationTaskHandler.java:290-305`) into the field. Editing it hits the case
  above. "Replace via Minecraft" on an existing Location also replaces the value with an id-less one, so a later
  edit is blank and the save creates a new Location instead of updating the old one.
- **Edits made earlier in the session are lost on the next edit.** A persisted entity re-opened for edit is always
  re-read from the DB (`loadExistingEntityData`, `FormWizard.tsx:897-944`). After KNG-130 an edited Location lives
  only in the parent's state as `{...childData, id: 83}` (:1949-1953); a second **Edit instance** reloads id 83 from
  the DB and shows the old values.
- **List relationships of a persisted entity can load empty.** `resolveObjectFieldValueForEdit`
  (`utils/forms/objectFieldEditValue.ts:18-48`) maps FK vs navigation names for **Object** fields only. A **List**
  field gets the raw DTO property. `api/Mapping/StreetMappingProfile.cs:11-17` fills `Districts` on read but never
  `DistrictIds`, so a Street field authored as `DistrictIds` always loads `[]`. Other DTOs with input-only `*Ids`
  lists likely share this; audit them.
- **Id-less List items collide.** `ListField` keys selected items by `item.id` (`FieldRenderers.tsx:1311`), removes by
  id (:1196-1203, :1331) and finds the edit index with `items.findIndex(c => c.id === item.id)` (:1340). Two id-less
  items share `undefined`: React keys clash, remove drops both, edit always targets the first.
- **Picker selection is id-only.** `PagedEntityTable` matches selected rows by `id` (:284-292, :454, :486) and keys
  rows by array index (:713), so an id-less value can never show as selected.

To verify while fixing (medium-low confidence): when the parent field is world-task enabled, the child inherits
`worldTaskHint` (`FormWizard.tsx:1826`, :3009-3010). If the Location form has no world-task field of its own, the panel
binds to a same-named field or to the **first** field (:2793-2805), so a capture made inside the child could land in
`Name`.

### 2.4 Related findings, not in scope here

- `FormSubmissionProgressDto.ChildProgresses` exists (`api/Dtos/FormDtos.cs:204`) but the mapping always ignores it
  (`api/Mapping/FormMappingProfile.cs:275`) and there is no endpoint listing a progress's children. A wizard only has
  a `progressId` after Next or Save Draft (`FormWizard.tsx:2503`, :2608), so a child opened from the first step of a
  parent gets no `parentProgressId`. The progress tree can't be used to find what a session created.
- Entities saved at once during a root form that is then **cancelled** stay in the DB (true today for every Object
  field and owned collection). The session registry in §3 makes a "delete what this form created?" prompt possible;
  left as a follow-up.
- `api/Services/WorkflowService.ExtractLocationDataFromTaskOutput` reads `worldName` while the plugin sends `World`;
  the method has no callers, so it has no effect today.

## 3. Proposed design

### 3.1 Decision D1 — when is a child entity saved? (decided 2026-10-11: A)

| Option | What it means | Cost / risk |
|---|---|---|
| **A. Save on child completion, everywhere (proposed default)** | A List "Create New" child is saved when its form completes, exactly like Object fields and owned collections already are. Only embedded value objects (Location) stay unsaved until the parent saves. | Small change, matches existing behaviour and the GateDoor/world-sync design. Rows made during a cancelled root form remain (already the case today). |
| B. True concepts until the root submits | Every child stays a client-side concept with a temporary id; the root submit creates the graph deepest-first and swaps temp ids for real ones. | Large: dependency ordering, temp-id remapping across forms, partial-failure rollback with no cross-entity transaction, resuming a concept graph from drafts, and world-task side effects (regions, captures) that happen in Minecraft before any DB row exists. Reverses current Object-field behaviour. |

**Developer decision 2026-10-11: A** ("save the children asap"). It fixes the data loss immediately, and with A the District from the scenario is a real row
that the GateStructure's District picker already finds. Option B can be revisited if abandoned rows become a real
problem; the session registry below is the first step towards it either way.

Until KNG-133 lands, `normalizeFormSubmission` must **fail loudly** instead of dropping: an id-less object in a
non-embedded relationship field blocks submit with a message naming the field, rather than being filtered out.

### 3.2 Form session registry (KNG-136)

A `FormSessionProvider` (React context) created by the root wizard — `FormWizardPage`, or the first `FormWizard`
without `parentProgressId`/`parentContext` — and read with a `useFormSession()` hook by every nested `FormWizard`
(passed through `ChildFormModal`, so no prop drilling beyond what exists).

Each entry:

```ts
interface SessionEntity {
  key: string;              // stable client key: `${entityTypeName}:${id}` or `concept:<uuid>` for embedded values
  entityTypeName: string;   // "District"
  id?: number;              // set once saved (always, under D1-A, except embedded values)
  display: Record<string, unknown>; // the DTO / form values used for labels and columns
  origin: { formPath: string[]; fieldName: string }; // e.g. ["GateStructure", "Street"], "Districts"
  status: 'created' | 'updated';
}
```

Registered from `handleChildFormComplete` (after persist, or for embedded values) and from
`ManyToManyRelationshipEditor.handleCreateRelatedEntity`. The registry lives for the root form's lifetime; it is not
persisted in drafts in the first version (a resumed draft simply shows DB rows, which under D1-A include everything).

### 3.3 Pickers show this session's entities

`PagedEntityTable` gets an optional prop, e.g. `pinnedRows?: { key: string; row: T; badge?: string }[]`:

- Pinned rows render in a "Created in this form" section above the page results, with a **New** badge (reuse the
  hybrid-picker New/Existing badge styling, `PagedEntityTable.tsx:737-749`). Rows that are also in the current page
  are shown once (de-duplicated by id).
- They respect the search term (client-side match on the display label) and the field's `pickerFilters`. Simplest
  correct approach: re-run the same search query with the session ids added as a filter, so the server applies the
  same rules; fall back to client-side filtering where a search endpoint can't filter by id.
- Selection and row keys move from `id`/array index to a stable key (`id` when present, else the entry `key`).
- `ObjectField` and `ListField` (`FieldRenderers.tsx:1116-1126`, :1398-1408) pass the session entries for their
  `objectType`. The picker also refetches when the registry changes (`refreshKey`), so a row saved by a nested form
  appears without toggling the picker.

Scope: every relationship picker in the wizard, including many-to-many steps. Embedded Location values are not
offered for selection elsewhere (a Location belongs to one owner; see `architecture/location-retention.md`).

### 3.4 Edit instance seeds from what the form holds (KNG-134)

- `ChildFormState` gains `initialValues` (the instance as held by the parent) and `editingInMemory: boolean`.
  `handleOpenChildForm` passes the whole instance, not just its id.
- `ChildFormModal`/`FormWizard`: when an `entityId` is present, load from the DB **then overlay** the in-memory
  values the parent holds (keeps KNG-130 edits on a second edit). When there is no id, seed every field from the
  instance (`applyInitialFieldValuesToSteps` already maps by case-insensitive field name) and title the modal
  "Edit …". Relationship values are seeded in the shape the field renderer expects (objects with id + display
  fields), so pickers show them selected.
- `handleChildFormComplete` replaces the value in place (same list index) and keeps an existing id: an embedded
  Location edited before its parent is saved stays one Location.
- `WorldBoundFieldRenderer`: "Replace via Minecraft" on a value that has an id keeps that id, so the save updates the
  Location instead of creating a second one.
- `ListField`: stable client keys for id-less items (key, remove and edit index).

### 3.5 List relationships load in edit mode (KNG-135)

- web-app: extend `resolveObjectFieldValueForEdit` (or a sibling) to **List** fields: a field authored as `XIds`
  falls back to the DTO's `Xs` navigation array (mapping each to `{id, ...}`), and a field authored as `Xs` falls
  back to `XIds`.
- web-api: fill `DistrictIds` (and other input-only `*Ids`) on read where the DTO declares them, starting with
  `StreetMappingProfile`. List the DTOs audited in the PR.

## 4. Open decisions

| # | Question | Proposed default |
|---|---|---|
| D1 | Save List "Create New" children on completion (A) or build true concepts (B)? | **A — decided by the developer 2026-10-11** |
| D2 | What happens to child-saved entities when the main form is abandoned? | **Default chosen 2026-10-11 (KNG-162), reversible:** they are complete records and are never deleted automatically. On an explicit cancel of the main form, or when its draft is deleted from Saved Progress, the admin sees what the form created and picks **Keep** (default) or **Delete** (deepest-first through the normal delete endpoints; anything referenced elsewhere is skipped and reported). Silent abandonment deletes nothing; the KNG-43 90-day cleanup keeps removing only draft rows. The root progress records what was created under it (`CreatedEntitiesJson`, additive). |
| D3 | Persist the session registry in drafts so a resumed draft still pins its new rows? | Comes with KNG-162's `CreatedEntitiesJson`; not in KNG-136 |

## 5. Order of work and tests

1. **KNG-133** (bug, first): save List "Create New" children; fail loudly on id-less drops. Test: Street form with a
   new District saves `districtIds=[newId]`; normalize throws for id-less non-embedded objects.
   **Status 2026-10-12: implemented on `claude/jolly-archimedes-urhio9` (knk-web-app `8e44800`, `ff12c8f`), not
   merged, live test pending.** Every List child is saved on completion, a List of Locations included (the API takes
   List relationships as ids only, e.g. `GuardSpawnLocationIds`); a single Object Location stays embedded.
2. **KNG-134** (bug): edit seeding. Tests next to `FormWizard.locationChildEdit.ui.test.tsx`: edit a world-task
   Location (no id) shows the captured x/y/z; edit an edited Location twice keeps the first edit; replace via
   Minecraft keeps the id; two id-less list items edit/remove independently.
   **Status 2026-10-12: implemented on `claude/jolly-archimedes-urhio9` (knk-web-app `b75ce07`, `7b7199f`,
   `602db8e`), not merged, live test pending.** The in-memory overlay applies only to children that are not saved on
   completion (an embedded Location); children saved through their own API (L1-4) keep loading from the database.
   The §2.3 "first field" binding was confirmed and fixed by spreading an object result over the child's fields.
   `PagedEntityTable`'s id-only selection is left for KNG-136 (§3.3 stable keys).
3. **KNG-135** (bug): List edit load. Test `objectFieldEditValue` for `XIds`/`Xs` pairs; API test that a Street read
   returns `districtIds`.
   **Status 2026-10-12: implemented on `claude/jolly-archimedes-urhio9` (knk-web-app `ee214a4`, knk-web-api
   `7b01458`), not merged, live test pending.** `resolveObjectFieldValueForEdit` pairs List fields across `XIds`/`Xs`
   (also `-y`/`-ies`); the API fills `StreetDto.DistrictIds` and `TownDto.DistrictIds` on read. Audited DTOs with
   `*Ids` lists: `DistrictDto.StreetIds`, `TownDto.StreetIds`, `GateStructureDto.GuardSpawnLocationIds`,
   `RoadProfileDto.ScopeTownIds` were already filled; the others are request/result DTOs (list in the chain report).
   KNG-164 (same link): a required List rejects `[]`, `minSelection`/`maxSelection` are enforced and stored.
4. **KNG-136** (improvement): registry + pinned picker rows. `PagedEntityTable` has no tests of its own today; add
   them (pinned rows, de-duplication, stable keys), plus a two-level nesting UI test modelled on
   `FormWizard.siegeNesting.ui.test.tsx`.
5. **KNG-162** (improvement): cancel / delete-draft prompt and provenance (D2). After KNG-136.

All of them touch `FormWizard.tsx`; KNG-120 (`claude/admiring-mendel-ne39j1`) and KNG-132
(`claude/loving-johnson-dlshrc`) change it too and are unmerged. Live test in the web app: the exact
GateStructure → Street → District scenario from §1, and the world-task Location edit.
