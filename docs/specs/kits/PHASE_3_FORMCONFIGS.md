# Kits Phase 3 — authored FormConfigurations (reference payloads)

**Status:** Reference record, not a seeder — data, not code
**Last updated:** 2026-09-25

Per `IMPLEMENTATION_PLAN.md` §3, the `Kit` admin form and its `KitContent` join-entry
sub-configuration were authored **live**, via direct `POST` calls to `api/FormConfigurations`
against a running `knk-web-api` — the same approach as Items Phase 2
(`docs/specs/items/PHASE_2_FORMCONFIGS.md`). There is still no FormConfiguration seeder.

**Why this file exists:** a `FormConfiguration` is a row in the `FormConfigurations`/`FormSteps`/
`FormFields` tables, not code — it lives only in the database it was authored against. Unlike the
Items Phase 2 forms, these were authored directly in the developer's real dev DB
(`knightsandkings_dev_v2`), where they exist as:

| Id | Configuration | Entity |
|---|---|---|
| 34 | `KitContent - Join Entry` | `KitContent` |
| 35 | `Kit - Default` | `Kit` |

Any other database (prod, a fresh environment) needs them re-created from the payloads below —
substituting the `KitContent` configuration's new id into the `Kit` form's `subConfigurationId`.

## Order matters

`KitContent - Join Entry` must be created **first**: the `Kit` form's Contents step references it
by id via `subConfigurationId`. Because it already exists at that point, the `Kit` form is a single
`POST` with the id filled in — no create-then-`PUT` patch step (unlike `Category`/`CategoryTag` in
Items Phase 2).

## Design calls

- **Field names are PascalCase, exactly as `IMPLEMENTATION_PLAN.md` §3 names them** (`HelmetId`,
  `SlotIndex`, ...). This matches the siege authoring forms and is what the web-app KitScan flow
  (`FormWizard.tsx` `applyKitScanResult`) looks up: `Helmet`/`HelmetId` etc. on any step, the step
  with `relatedEntityPropertyName === 'Contents'`, and `SlotIndex`/`Quantity` join fields. Top-level
  entity CRUD binds case-insensitively; the join-entry sub-form is case-sensitive, so `ItemBlueprintId`/
  `SlotIndex`/`Quantity` there **must** keep this exact casing (same reason as `CategoryTag`'s `TagId`).
- **Join extra columns live in the sub-configuration, not in `childFormSteps`.** `SlotIndex` and
  `Quantity` are fields of `KitContent - Join Entry`, the same pattern the existing
  `ItemBlueprintDefaultEnchantment - Join Entry` uses for `Level`. KitScan reads `childFormSteps`
  only to pick up the field-name casing and falls back to the literal names, so it works with this shape.
- **KitScan is bound to the `Name` field** (`settingsJson.worldTask.taskType = "KitScan"`), mirroring
  how ItemScan hangs off `ItemBlueprint.defaultDisplayName`. Without a bound field there is no
  "Send to Minecraft" button, and the Phase 7 scan flow can't be started from the form. The scan
  never writes into its own bound field.
- **`CostCurrency`** is an `Enum` field with a `settingsJson.enumValues` snapshot of `KitCostCurrency`;
  `withLiveEnumOptions` refreshes it from live metadata anyway.
- **`SlotIndex` 0-35 is enforced server-side, not in the form.** The form engine never applies
  `Range` validations client-side and the DB has no check constraint, so the range lives in
  `KitService.BuildContentsAsync` (web-api `e949ed2`, 2026-09-26): Create/Update reject any slot
  outside 0-35 with a 400 and the message shown in the wizard. The field description states the range.
- **`MinTitleBracketId` needs the siege branch.** The `TitleBracket` object picker relies on the
  read-only `TitleBracketsController` (web-api `c8ab607`) and `TitleBracketClient`/`entityApiMapping`
  entry (web-app `dbf2fb6`), which exist only on `claude/siege-minigame` as of 2026-09-25. On
  `master`/`main` that one picker can't search or load; everything else works. It needs no
  `TitleBracket` FormConfiguration of its own (the brackets are seeded, read-only reference data).

## 1. KitContent (join-entry sub-configuration — create this first)

```json
POST /api/FormConfigurations
{
  "entityTypeName": "KitContent",
  "configurationName": "KitContent - Join Entry",
  "description": "Join entry form for adding an item to a Kit inventory slot (Kit Contents M2M step).",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Slot",
      "order": 0,
      "fields": [
        { "fieldName": "ItemBlueprintId", "label": "Item", "fieldType": "Object", "objectType": "ItemBlueprint", "isRequired": true, "isReadOnly": false, "order": 0 },
        { "fieldName": "SlotIndex", "label": "Slot", "description": "Inventory slot 0-35: 0-8 is the hotbar (left to right), 9-35 the main inventory rows. Each slot holds at most one item.", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 1 },
        { "fieldName": "Quantity", "label": "Quantity", "description": "Stack size placed in this slot.", "fieldType": "Integer", "defaultValue": "1", "isRequired": true, "isReadOnly": false, "order": 2 }
      ]
    }
  ]
}
```

## 2. Kit (references KitContent's id from step 1 — `"34"` in the dev DB)

```json
POST /api/FormConfigurations
{
  "entityTypeName": "Kit",
  "configurationName": "Kit - Default",
  "description": "Admin form for managing Kits: equipment, slot contents, access conditions and cost.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "General Information",
      "order": 0,
      "fields": [
        { "fieldName": "Name", "label": "Name", "description": "Stand in-game wearing/holding the loadout and scan it to pre-fill the equipment slots and Contents below.", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 0, "settingsJson": "{\"worldTask\": {\"enabled\": true, \"taskType\": \"KitScan\"}}" },
        { "fieldName": "Description", "label": "Description", "fieldType": "String", "isRequired": false, "isReadOnly": false, "order": 1 },
        { "fieldName": "HelmetId", "label": "Helmet", "fieldType": "Object", "objectType": "ItemBlueprint", "isRequired": false, "isReadOnly": false, "order": 2 },
        { "fieldName": "ChestplateId", "label": "Chestplate", "fieldType": "Object", "objectType": "ItemBlueprint", "isRequired": false, "isReadOnly": false, "order": 3 },
        { "fieldName": "LeggingsId", "label": "Leggings", "fieldType": "Object", "objectType": "ItemBlueprint", "isRequired": false, "isReadOnly": false, "order": 4 },
        { "fieldName": "BootsId", "label": "Boots", "fieldType": "Object", "objectType": "ItemBlueprint", "isRequired": false, "isReadOnly": false, "order": 5 },
        { "fieldName": "ShieldId", "label": "Shield (off-hand)", "fieldType": "Object", "objectType": "ItemBlueprint", "isRequired": false, "isReadOnly": false, "order": 6 },
        { "fieldName": "HandId", "label": "Hand (main hand)", "fieldType": "Object", "objectType": "ItemBlueprint", "isRequired": false, "isReadOnly": false, "order": 7 },
        { "fieldName": "GrantOnFirstJoin", "label": "Grant on first join", "description": "Every brand-new player receives this kit automatically.", "fieldType": "Boolean", "defaultValue": "false", "isRequired": false, "isReadOnly": false, "order": 8 },
        { "fieldName": "CooldownSeconds", "label": "Cooldown (seconds)", "description": "0 = no cooldown (freely repeatable).", "fieldType": "Integer", "defaultValue": "0", "isRequired": true, "isReadOnly": false, "order": 9 }
      ]
    },
    {
      "stepName": "Contents",
      "order": 1,
      "isManyToManyRelationship": true,
      "relatedEntityPropertyName": "Contents",
      "joinEntityType": "KitContent",
      "subConfigurationId": "34",
      "fields": [
        { "fieldName": "Contents", "label": "Contents", "fieldType": "List", "objectType": "KitContent", "isRequired": false, "isReadOnly": false, "order": 0 }
      ]
    },
    {
      "stepName": "Access Conditions",
      "order": 2,
      "fields": [
        { "fieldName": "MinTitleBracketId", "label": "Minimum title", "description": "Optional: players below this title can't claim the kit.", "fieldType": "Object", "objectType": "TitleBracket", "isRequired": false, "isReadOnly": false, "order": 0 },
        { "fieldName": "RequiredPermissionGroupId", "label": "Required permission group", "description": "Optional: only members of this group (or a group inheriting from it) can claim the kit.", "fieldType": "Object", "objectType": "PermissionGroup", "isRequired": false, "isReadOnly": false, "order": 1 },
        { "fieldName": "RequiredPermissionNode", "label": "Required permission node", "description": "Optional permission node, e.g. knk.kit.archer.", "fieldType": "String", "isRequired": false, "isReadOnly": false, "order": 2 }
      ]
    },
    {
      "stepName": "Economy",
      "order": 3,
      "fields": [
        { "fieldName": "CostAmount", "label": "Cost per claim", "description": "Optional: charged on every successful claim.", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 0 },
        { "fieldName": "CostCurrency", "label": "Cost currency", "fieldType": "Enum", "isRequired": false, "isReadOnly": false, "order": 1, "settingsJson": "{\"enumValues\": [\"Coins\", \"Gems\"]}" },
        { "fieldName": "IsSinglePurchasePremium", "label": "Single-purchase premium kit", "description": "Bought once with Gems, then claimable indefinitely with no further cost or cooldown.", "fieldType": "Boolean", "defaultValue": "false", "isRequired": false, "isReadOnly": false, "order": 2 },
        { "fieldName": "PremiumPriceGems", "label": "Premium price (Gems)", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 3 }
      ]
    }
  ]
}
```

## Verification (2026-09-25, dev DB, API + web-app from `claude/siege-minigame`)

Driven through the real web-app (FormWizard) in a headless browser:

1. **Create:** throwaway kit "ZZ Claude Test Kit" with all six equipment pickers set, two Contents
   join entries (Arrow ×32 in slot 9, Wooden Bow ×1 in slot 10), a `TitleBracket` (Yeoman), a
   `PermissionGroup` (Noble), a permission node, cooldown 30 and cost 100 Coins. The saved `kits`/
   `kit_contents` rows matched every value.
2. **Edit** (`/forms/kit/edit/{id}`): every picker pre-filled (name + id), as did the scalars, the
   enum and both Contents rows. Changing only the cost and submitting left every FK and both Contents
   rows intact.
3. **Delete** (dashboard → Kit → Delete): the kit and its `kit_contents` rows were removed; the
   referenced `ItemBlueprint` rows were untouched (Restrict FK).

Cosmetic, not blocking: in edit mode the Contents rows are labelled `ItemBlueprint #24` rather than
by name. The row data is correct; the list only lacks the blueprint's display name.
