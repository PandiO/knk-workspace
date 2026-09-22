# Items Phase 2 — authored FormConfigurations (reference payloads)

**Status:** Reference record, not a seeder — data, not code
**Last updated:** 2026-09-22

Per `IMPLEMENTATION_PLAN.md` §7 item 2's resolved decision, Phase 2's four
`FormConfiguration`s (`Grade`, `Tag`, `Category`, `EnchantmentDefinition`) plus
the `CategoryTag` join-entry sub-configuration were authored **live**, via
direct `POST`/`PUT` calls to `api/FormConfigurations` against a real running
`knk-web-api` instance — deliberately not a seeder, per that decision.

**Why this file exists:** a `FormConfiguration` is a row in the
`FormConfigurations`/`FormSteps`/`FormFields` tables, not a line of code — it
lives only in whichever database the authoring session was pointed at. The
session that did this work used a local, session-scoped MySQL instance
(installed fresh in-sandbox, per this repo's own established convention for
sessions without network access to a shared dev DB) that does not persist
after the session ends. **These five `FormConfiguration`s do not exist in the
developer's real dev/prod database and need to be re-created there** — either
by re-running these exact payloads against the real API, or by hand-authoring
the equivalent shape via the `FormConfigBuilder` UI. This file exists so that
work doesn't have to be reverse-engineered from scratch.

## Order matters

`CategoryTag` (the join-entry sub-configuration) must be created **before**
`Category`, since `Category`'s `Tags` step references it by id via
`subConfigurationId`. The two-step process below reflects this.

## 1. Grade

```json
POST /api/FormConfigurations
{
  "entityTypeName": "Grade",
  "configurationName": "Grade - Default",
  "description": "Admin form for managing item Grades (name + star rating).",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "General Information",
      "order": 0,
      "fields": [
        { "fieldName": "name", "label": "Name", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 0 },
        { "fieldName": "stars", "label": "Stars", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 1 }
      ]
    }
  ]
}
```

## 2. Tag

```json
POST /api/FormConfigurations
{
  "entityTypeName": "Tag",
  "configurationName": "Tag - Default",
  "description": "Admin form for managing item/category Tags.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "General Information",
      "order": 0,
      "fields": [
        { "fieldName": "name", "label": "Name", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 0 }
      ]
    }
  ]
}
```

## 3. EnchantmentDefinition

`description` is required (`isRequired: true`) even though it reads as
optional prose — `EnchantmentDefinition.Description` is a non-nullable
`string` with no default on the model, and `FormTemplateValidationService`
correctly rejects a `FormConfiguration` that marks a non-nullable,
no-default field as not-required. `AbilityDefinition` is deliberately left
off this form per §4.2's own note (custom-ability authoring already has its
own tooling).

**Design call:** `MinecraftEnchantmentRefId` uses a plain `Object` picker
(`objectType: "MinecraftEnchantmentRef"`), not
`HybridMinecraftEnchantmentRefPicker`. Reasoning: `MinecraftEnchantmentRef`
rows are pre-seeded reference/catalog data (like `MinecraftMaterialRef`), not
something an admin needs to get-or-create from a bare namespace key while
filling this form — the plain `Object` picker is the well-tested, already-
proven path (same mechanism `Category.ParentCategoryId` uses). The Hybrid
picker's own submission path
(`normalizeFormSubmission.ts`'s `handleHybridMaterialField`) is *only* wired
for `HybridMinecraftMaterialRefPicker`, not the enchantment variant — using
it here would have hit an untested code path for no benefit, since there's
no get-or-create need for this field.

```json
POST /api/FormConfigurations
{
  "entityTypeName": "EnchantmentDefinition",
  "configurationName": "EnchantmentDefinition - Default",
  "description": "Admin form for managing EnchantmentDefinition catalog rows.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "General Information",
      "order": 0,
      "fields": [
        { "fieldName": "key", "label": "Key", "description": "Namespace key, e.g. minecraft:sharpness or knk:lifesteal", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 0 },
        { "fieldName": "displayName", "label": "Display Name", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 1 },
        { "fieldName": "description", "label": "Description", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 2 },
        { "fieldName": "isCustom", "label": "Is Custom", "fieldType": "Boolean", "isRequired": false, "isReadOnly": false, "order": 3 },
        { "fieldName": "maxLevel", "label": "Max Level", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 4 },
        { "fieldName": "minecraftEnchantmentRefId", "label": "Base Enchantment Reference", "description": "The vanilla Minecraft enchantment this definition wraps (leave empty for a fully custom enchantment).", "fieldType": "Object", "objectType": "MinecraftEnchantmentRef", "isRequired": false, "isReadOnly": false, "order": 5 }
      ]
    }
  ]
}
```

## 4. CategoryTag (join-entry sub-configuration — create this before step 5)

This is the form the "Create New Join Entry" button on `Category`'s `Tags`
step opens (`ManyToManyRelationshipEditor.tsx`'s `joinConfigId` mechanism) —
without it, that button never renders at all (`joinConfigId &&
onOpenJoinEntry` guard in the component). `CategoryTag` carries no columns
beyond its two FKs, so this join-entry form has exactly one field: the `Tag`
picker.

**Field-name casing matters here, unusually:** `TagId` (PascalCase), not
`tagId`. `FormWizard.tsx`'s `handleJoinEntryComplete`/
`normalizeFormSubmission.ts`'s `resolveJoinEntityMapping` both look up this
field by its *exact* metadata field name (`MetadataService` reflects real
C# property names verbatim, e.g. `FieldName = property.Name`), not the
camelCase JSON convention every top-level entity form DTO uses. Every other
field in this phase (`name`, `stars`, `minecraftEnchantmentRefId`, etc.) is
camelCase and works fine because top-level entity CRUD goes through
case-insensitive ASP.NET JSON binding; a join-entry sub-form field feeds a
different, case-sensitive code path instead. Get this wrong and the join
entry silently fails at submit time with "Join entry 1 in Tags is missing a
related entity selection" (see the engine bug note below for the other half
of why this was hard to diagnose).

```json
POST /api/FormConfigurations
{
  "entityTypeName": "CategoryTag",
  "configurationName": "CategoryTag - Join Entry",
  "description": "Join entry form for adding a Tag to a Category (Category Tags M2M step).",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Tag",
      "order": 0,
      "fields": [
        { "fieldName": "TagId", "label": "Tag", "fieldType": "Object", "objectType": "Tag", "isRequired": true, "isReadOnly": false, "order": 0 }
      ]
    }
  ]
}
```

## 5. Category (references CategoryTag's id from step 4)

`ParentCategoryId`/`IconMaterialRefId` are the two fields the plan named;
`Name` is also included since it's a required, non-nullable field on the
model with no default — omitting it would make the form permanently
unsubmittable, the same reasoning as `EnchantmentDefinition.Description`
above.

After creating this configuration, `PUT` it back with the `Tags` step's
`subConfigurationId` set to the id `CategoryTag - Join Entry` (step 4) was
created with (a `Category`+`CategoryTag` chicken-and-egg: `Category`'s own
config must exist first to get an id, so this is a two-request create-then-
patch, not a single atomic POST).

```json
POST /api/FormConfigurations
{
  "entityTypeName": "Category",
  "configurationName": "Category - Default",
  "description": "Admin form for managing item Categories, including their tags.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "General Information",
      "order": 0,
      "fields": [
        { "fieldName": "name", "label": "Name", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 0 },
        { "fieldName": "parentCategoryId", "label": "Parent Category", "fieldType": "Object", "objectType": "Category", "isRequired": false, "isReadOnly": false, "order": 1 },
        { "fieldName": "iconMaterialRefId", "label": "Icon Material", "fieldType": "HybridMinecraftMaterialRefPicker", "isRequired": false, "isReadOnly": false, "order": 2 }
      ]
    },
    {
      "stepName": "Tags",
      "order": 1,
      "isManyToManyRelationship": true,
      "relatedEntityPropertyName": "Tags",
      "joinEntityType": "CategoryTag",
      "fields": [
        { "fieldName": "Tags", "label": "Tags", "fieldType": "List", "objectType": "CategoryTag", "isRequired": false, "isReadOnly": false, "order": 0 }
      ]
    }
  ]
}
```

Then `GET /api/FormConfigurations/{categoryConfigId}`, set
`steps[<Tags step>].subConfigurationId` to the `CategoryTag` configuration's
id (as a string), and `PUT /api/FormConfigurations/{categoryConfigId}` with
the full body back.

## Engine bug fixed alongside this authoring (not a FormConfiguration issue)

While verifying step 5 end-to-end, submitting a join entry through the
`CategoryTag` sub-form always failed with *"Join entry 1 in Tags is missing
a related entity selection"*, even with the field-name casing above already
correct. Root cause, found via `FormWizard.tsx`'s own `debug(...)` console
tracing: `FormWizard`'s `entityName` prop is the **raw, lowercase
`:entityName` route segment** (`"category"`, from `/forms/category`), but
two places in `FormWizard.tsx` compare it *by exact string equality* against
real backend metadata's `relatedEntityType`, which `MetadataService` always
reports in real C# type casing (`"Category"`). The mismatch meant the "which
metadata field is the *other* side of this join" exclusion filter never
actually excluded the parent's own side, so the code sometimes resolved the
wrong FK field (`CategoryId` instead of `TagId`) when merging a join entry's
submitted data, or lost the ID entirely by the time `normalizeFormSubmission`
tried to serialize it.

Fixed in `knk-web-app/src/components/FormWizard/FormWizard.tsx` at both call
sites (the top-level `normalizeFormSubmission({ entityTypeName: ... })` call
and `handleJoinEntryComplete`'s `relatedNavigationField` lookup) by using the
already-loaded `config.entityTypeName` (correctly cased, from the fetched
`FormConfiguration`) instead of the raw route param, falling back to the
route param only if the config hasn't loaded yet. This is a **pre-existing
defect in shared engine code**, not something introduced by this phase's
FormConfiguration authoring — it was latent because no `FormConfiguration`
had ever exercised a plain (no-extra-column), bidirectional-metadata M2M
join through a nested join-entry sub-form before (`ItemBlueprint`'s own form,
which would have hit the same path for `DefaultEnchantments`, doesn't exist
yet — that's Phase 3). Confirmed via `git stash`/rerun that this fix causes
no regressions in the existing Jest suite (same 16 pre-existing failures,
same 220 passing, before and after).

**Anyone building `ItemBlueprint`'s own M2M steps in Phase 3 will hit the
same class of bug if `entityName` is ever compared against metadata
elsewhere in this file** — worth grepping `FormWizard.tsx` for other
`entityName` comparisons before assuming this fix was exhaustive; only the
two sites this phase's testing actually exercised were fixed.
