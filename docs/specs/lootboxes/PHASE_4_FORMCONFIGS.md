# Lootboxes Phase 4 — FormConfigurations (reference payloads)

**Status:** Reference record, not a seeder — data, not code
**Last updated:** 2026-09-26

Per `IMPLEMENTATION_PLAN.md` Phase 4, the `LootboxType`, `LootboxSpecialEntry` and `LootboxSpawnArea` admin forms (and the four
join-entry sub-configurations they use) are FormConfiguration rows, the same approach as `specs/kits/PHASE_3_FORMCONFIGS.md`.
There is no FormConfiguration seeder, so every database needs them created from these payloads.

**Not yet in the developer's dev DB** (`knightsandkings_dev_v2`): the Phase 4 session had no access to it. The payloads were
POSTed to a local API (web-api `claude/lootboxes` @ `81f8071`, fresh MySQL 8 with both lootbox migrations and seeds): all seven
passed `FormConfigurationValidationService`, the M2M steps persisted with their join types and sub-configuration ids, and a
LootboxType PUT in the FormWizard's PascalCase shape (`GradeWeights[{GradeId, Weight}]`, `PoolEntries[{ItemBlueprintId, Mode,
WeightOverride}]`, `EnchantRolls[{EnchantmentDefinitionId, ChancePercent, MinLevel, MaxLevel, MinBoxStars, SortOrder}]`)
saved and changed the odds. Not driven through the FormWizard UI in a browser (none available); do that once on the dev DB
(checklist at the end).

## Order matters

Create the four join entries first, note their ids, and put them into the `subConfigurationId` placeholders of the parent forms:
`<GRADE_WEIGHT_ID>`, `<POOL_ENTRY_ID>`, `<ENCHANT_ROLL_ID>` (LootboxType) and `<AREA_TYPE_ID>` (LootboxSpawnArea).

## Design calls

- **PascalCase field names**, exactly the model property names. The join-entry sub-forms are case-sensitive (same as
  `KitContent`'s `ItemBlueprintId`); the M2M editor finds the picked entity as the join's first navigation that isn't the parent
  (`Grade`, `ItemBlueprint`, `EnchantmentDefinition`, `LootboxType`) and its `<Type>Id` field.
- **Join extra columns live in the sub-configuration** (`Weight`, `Mode`/`WeightOverride`/`GradeIdOverride`, the roll's
  chance/levels/order), like `KitContent`'s `SlotIndex`/`Quantity`.
- **Ranges are the API's job**: box stars 1-5, spread 0-9, chance 0-100, `1 ≤ MinLevel ≤ MaxLevel ≤ definition max`,
  per-million 0-1,000,000, interval ≥ 60, area name `[A-Za-z0-9_-]{1,32}` unique (409 `NameTaken`), one type per category
  (409). The form engine doesn't apply `Range` rules client-side; the descriptions state them.
- **`Mode`** is an `Enum` with an `enumValues` snapshot of `LootboxPoolMode` (the DTO takes the name as a string).
- **`DisplayMaterialRefId`** uses the `HybridMinecraftMaterialRefPicker`, like `ItemBlueprint.IconMaterialRefId`.
- **`WgRegionId`** is a `String` with the `WgRegionId` world task: *Send to Minecraft*, then either a WorldEdit selection
  (creates a region) or `select <region>` in chat to reuse an existing one (a town's or a domain's). There is no web-side
  picker of Domain regions: the FormWizard can't store a picked object's property, and the world task already lists and
  validates regions. Areas made in game (`/knk lootbox area create`) are ordinary rows and open in this same form.
- **`CreatedByUserId`** is not on the form: the in-game command sets it, the web form leaves it alone.
- **Settings singleton, odds, active boxes and drop log are not forms**: they live on `/admin/lootboxes` (web-app).


## 1. LootboxTypeGradeWeight (join entry)

```json
POST /api/FormConfigurations
{
  "entityTypeName": "LootboxTypeGradeWeight",
  "configurationName": "LootboxTypeGradeWeight - Join Entry",
  "description": "Join entry form for a box-grade weight override on a LootboxType (Box grades M2M step).",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Weight",
      "order": 0,
      "fields": [
        {
          "fieldName": "GradeId",
          "label": "Box grade",
          "description": "Only grades within the type's box stars (1-5) matter.",
          "fieldType": "Object",
          "objectType": "Grade",
          "isRequired": true,
          "isReadOnly": false,
          "order": 0
        },
        {
          "fieldName": "Weight",
          "label": "Weight",
          "description": "Relative weight of this box grade; replaces the grade's own drop chance for this type. 0 = this type never spawns as this grade.",
          "fieldType": "Decimal",
          "isRequired": true,
          "isReadOnly": false,
          "order": 1
        }
      ]
    }
  ]
}
```

## 2. LootboxPoolEntry (join entry)

```json
POST /api/FormConfigurations
{
  "entityTypeName": "LootboxPoolEntry",
  "configurationName": "LootboxPoolEntry - Join Entry",
  "description": "Join entry form for adding or removing an item from a LootboxType's pool (Pool M2M step).",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Pool entry",
      "order": 0,
      "fields": [
        {
          "fieldName": "ItemBlueprintId",
          "label": "Item",
          "fieldType": "Object",
          "objectType": "ItemBlueprint",
          "isRequired": true,
          "isReadOnly": false,
          "order": 0
        },
        {
          "fieldName": "Mode",
          "label": "Mode",
          "description": "Include adds an item from any category; Exclude removes one the category would give.",
          "fieldType": "Enum",
          "defaultValue": "Include",
          "isRequired": true,
          "isReadOnly": false,
          "order": 1,
          "settingsJson": "{\"enumValues\": [\"Include\", \"Exclude\"]}"
        },
        {
          "fieldName": "WeightOverride",
          "label": "Weight",
          "description": "Weight among the pool items of the same grade (empty = 1).",
          "fieldType": "Decimal",
          "isRequired": false,
          "isReadOnly": false,
          "order": 2
        },
        {
          "fieldName": "GradeIdOverride",
          "label": "Grade override",
          "description": "Needed for an item without a grade of its own; otherwise changes which grade it drops as.",
          "fieldType": "Object",
          "objectType": "Grade",
          "isRequired": false,
          "isReadOnly": false,
          "order": 3
        }
      ]
    }
  ]
}
```

## 3. LootboxEnchantRoll (join entry)

```json
POST /api/FormConfigurations
{
  "entityTypeName": "LootboxEnchantRoll",
  "configurationName": "LootboxEnchantRoll - Join Entry",
  "description": "Join entry form for one enchantment roll of a LootboxType (Enchant rolls M2M step).",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Enchant roll",
      "order": 0,
      "fields": [
        {
          "fieldName": "EnchantmentDefinitionId",
          "label": "Enchantment",
          "fieldType": "Object",
          "objectType": "EnchantmentDefinition",
          "isRequired": true,
          "isReadOnly": false,
          "order": 0
        },
        {
          "fieldName": "ChancePercent",
          "label": "Chance (%)",
          "description": "0-100, per item that can carry it.",
          "fieldType": "Decimal",
          "defaultValue": "25",
          "isRequired": true,
          "isReadOnly": false,
          "order": 1
        },
        {
          "fieldName": "MinLevel",
          "label": "Min level",
          "fieldType": "Integer",
          "defaultValue": "1",
          "isRequired": true,
          "isReadOnly": false,
          "order": 2
        },
        {
          "fieldName": "MaxLevel",
          "label": "Max level",
          "description": "At most the definition's max level. Vanilla levels are then capped by the item's grade.",
          "fieldType": "Integer",
          "defaultValue": "1",
          "isRequired": true,
          "isReadOnly": false,
          "order": 3
        },
        {
          "fieldName": "MinBoxStars",
          "label": "From box grade",
          "description": "Only boxes of at least this many stars (1-5) roll it.",
          "fieldType": "Integer",
          "defaultValue": "1",
          "isRequired": true,
          "isReadOnly": false,
          "order": 4
        },
        {
          "fieldName": "SortOrder",
          "label": "Order",
          "description": "Rolled in this order; a later roll that conflicts with an earlier hit is skipped.",
          "fieldType": "Integer",
          "defaultValue": "0",
          "isRequired": true,
          "isReadOnly": false,
          "order": 5
        }
      ]
    }
  ]
}
```

## 4. LootboxSpawnAreaType (join entry)

```json
POST /api/FormConfigurations
{
  "entityTypeName": "LootboxSpawnAreaType",
  "configurationName": "LootboxSpawnAreaType - Join Entry",
  "description": "Join entry form for a box type allowed in a LootboxSpawnArea (Allowed types M2M step).",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Type",
      "order": 0,
      "fields": [
        {
          "fieldName": "LootboxTypeId",
          "label": "Box type",
          "fieldType": "Object",
          "objectType": "LootboxType",
          "isRequired": true,
          "isReadOnly": false,
          "order": 0
        }
      ]
    }
  ]
}
```

## 5. LootboxType (basics → box grades → pool → enchant rolls)

```json
POST /api/FormConfigurations
{
  "entityTypeName": "LootboxType",
  "configurationName": "LootboxType - Default",
  "description": "Admin form for a lootbox type (one per item category): basics, box-grade weights, pool entries and enchantment rolls.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Basics",
      "order": 0,
      "fields": [
        {
          "fieldName": "Name",
          "label": "Name",
          "description": "Shown in game as '<grade> <name>', e.g. 'Legendary Weapons Lootbox'.",
          "fieldType": "String",
          "isRequired": true,
          "isReadOnly": false,
          "order": 0
        },
        {
          "fieldName": "CategoryId",
          "label": "Category",
          "description": "One type per category: the pool is every graded blueprint of it.",
          "fieldType": "Object",
          "objectType": "Category",
          "isRequired": true,
          "isReadOnly": false,
          "order": 1
        },
        {
          "fieldName": "IncludeSubcategories",
          "label": "Include subcategories",
          "fieldType": "Boolean",
          "defaultValue": "true",
          "isRequired": false,
          "isReadOnly": false,
          "order": 2
        },
        {
          "fieldName": "Enabled",
          "label": "Enabled",
          "description": "Only enabled types spawn.",
          "fieldType": "Boolean",
          "defaultValue": "false",
          "isRequired": false,
          "isReadOnly": false,
          "order": 3
        },
        {
          "fieldName": "SpawnWeight",
          "label": "Spawn weight",
          "description": "How often this type is picked among the types an area allows.",
          "fieldType": "Integer",
          "defaultValue": "10",
          "isRequired": true,
          "isReadOnly": false,
          "order": 4
        },
        {
          "fieldName": "MinBoxStars",
          "label": "Min box grade",
          "description": "1-5.",
          "fieldType": "Integer",
          "defaultValue": "1",
          "isRequired": true,
          "isReadOnly": false,
          "order": 5
        },
        {
          "fieldName": "MaxBoxStars",
          "label": "Max box grade",
          "description": "1-5 (no ★6+ boxes yet).",
          "fieldType": "Integer",
          "defaultValue": "5",
          "isRequired": true,
          "isReadOnly": false,
          "order": 6
        },
        {
          "fieldName": "ItemStarSpread",
          "label": "Item grade spread",
          "description": "A ★B box gives items of ★(B - spread) to ★B. 0-9.",
          "fieldType": "Integer",
          "defaultValue": "2",
          "isRequired": true,
          "isReadOnly": false,
          "order": 7
        },
        {
          "fieldName": "DisplayMaterialRefId",
          "label": "Box model",
          "description": "Item shown as the box. Empty = the category icon, else a chest.",
          "fieldType": "HybridMinecraftMaterialRefPicker",
          "isRequired": false,
          "isReadOnly": false,
          "order": 8
        },
        {
          "fieldName": "MaxClaimsPerPlayerPerDay",
          "label": "Daily limit for this type",
          "description": "Per player per UTC day, on top of the global limit. Empty = only the global one.",
          "fieldType": "Integer",
          "isRequired": false,
          "isReadOnly": false,
          "order": 9
        },
        {
          "fieldName": "AnnounceMinItemStars",
          "label": "Announce drops from item grade",
          "description": "Empty = the global setting.",
          "fieldType": "Integer",
          "isRequired": false,
          "isReadOnly": false,
          "order": 10
        }
      ]
    },
    {
      "stepName": "Box grades",
      "order": 1,
      "isManyToManyRelationship": true,
      "relatedEntityPropertyName": "GradeWeights",
      "joinEntityType": "LootboxTypeGradeWeight",
      "subConfigurationId": "<GRADE_WEIGHT_ID>",
      "fields": [
        {
          "fieldName": "GradeWeights",
          "label": "Box-grade weights (empty = the grades' drop chance)",
          "fieldType": "List",
          "objectType": "LootboxTypeGradeWeight",
          "isRequired": false,
          "isReadOnly": false,
          "order": 0
        }
      ]
    },
    {
      "stepName": "Pool",
      "order": 2,
      "isManyToManyRelationship": true,
      "relatedEntityPropertyName": "PoolEntries",
      "joinEntityType": "LootboxPoolEntry",
      "subConfigurationId": "<POOL_ENTRY_ID>",
      "fields": [
        {
          "fieldName": "PoolEntries",
          "label": "Pool entries (the category is the default pool)",
          "fieldType": "List",
          "objectType": "LootboxPoolEntry",
          "isRequired": false,
          "isReadOnly": false,
          "order": 0
        }
      ]
    },
    {
      "stepName": "Enchant rolls",
      "order": 3,
      "isManyToManyRelationship": true,
      "relatedEntityPropertyName": "EnchantRolls",
      "joinEntityType": "LootboxEnchantRoll",
      "subConfigurationId": "<ENCHANT_ROLL_ID>",
      "fields": [
        {
          "fieldName": "EnchantRolls",
          "label": "Enchantment rolls",
          "fieldType": "List",
          "objectType": "LootboxEnchantRoll",
          "isRequired": false,
          "isReadOnly": false,
          "order": 0
        }
      ]
    }
  ]
}
```

## 6. LootboxSpecialEntry

```json
POST /api/FormConfigurations
{
  "entityTypeName": "LootboxSpecialEntry",
  "configurationName": "LootboxSpecialEntry - Default",
  "description": "Admin form for a lootbox special (jackpot) entry. Saving it tags the blueprint 'Lootbox Special', which removes it from normal pools.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Special",
      "order": 0,
      "fields": [
        {
          "fieldName": "ItemBlueprintId",
          "label": "Item",
          "description": "Given as designed, with its default enchantments.",
          "fieldType": "Object",
          "objectType": "ItemBlueprint",
          "isRequired": true,
          "isReadOnly": false,
          "order": 0
        },
        {
          "fieldName": "LootboxTypeId",
          "label": "Box type",
          "description": "Empty = any box type.",
          "fieldType": "Object",
          "objectType": "LootboxType",
          "isRequired": false,
          "isReadOnly": false,
          "order": 1
        },
        {
          "fieldName": "ChancePerMillion",
          "label": "Chance per million",
          "description": "0-1,000,000. 2000 = 0.2%, 500 = 0.05%.",
          "fieldType": "Integer",
          "defaultValue": "2000",
          "isRequired": true,
          "isReadOnly": false,
          "order": 2
        },
        {
          "fieldName": "MinBoxStars",
          "label": "From box grade",
          "description": "1-5.",
          "fieldType": "Integer",
          "defaultValue": "5",
          "isRequired": true,
          "isReadOnly": false,
          "order": 3
        },
        {
          "fieldName": "Enabled",
          "label": "Enabled",
          "fieldType": "Boolean",
          "defaultValue": "true",
          "isRequired": false,
          "isReadOnly": false,
          "order": 4
        },
        {
          "fieldName": "SortOrder",
          "label": "Order",
          "description": "Specials are checked in this order; the first hit wins.",
          "fieldType": "Integer",
          "defaultValue": "0",
          "isRequired": true,
          "isReadOnly": false,
          "order": 5
        }
      ]
    }
  ]
}
```

## 7. LootboxSpawnArea (area → limits → allowed types)

```json
POST /api/FormConfigurations
{
  "entityTypeName": "LootboxSpawnArea",
  "configurationName": "LootboxSpawnArea - Default",
  "description": "Admin form for a lootbox spawn area: a WorldGuard region boxes may spawn in, and its limits.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Area",
      "order": 0,
      "fields": [
        {
          "fieldName": "Name",
          "label": "Name",
          "description": "Letters, digits, - and _ (max 32); used by /knk lootbox area.",
          "fieldType": "String",
          "isRequired": true,
          "isReadOnly": false,
          "order": 0
        },
        {
          "fieldName": "World",
          "label": "World",
          "fieldType": "String",
          "defaultValue": "world",
          "isRequired": true,
          "isReadOnly": false,
          "order": 1
        },
        {
          "fieldName": "WgRegionId",
          "label": "WorldGuard region",
          "description": "Send to Minecraft, then select an area with WorldEdit to create a region, or type 'select <region>' to use an existing one (e.g. a town's).",
          "fieldType": "String",
          "isRequired": true,
          "isReadOnly": false,
          "order": 2,
          "settingsJson": "{\"worldTask\": {\"enabled\": true, \"taskType\": \"WgRegionId\"}}"
        },
        {
          "fieldName": "Enabled",
          "label": "Enabled",
          "fieldType": "Boolean",
          "defaultValue": "false",
          "isRequired": false,
          "isReadOnly": false,
          "order": 3
        },
        {
          "fieldName": "ExcludedRegionIds",
          "label": "Excluded regions",
          "description": "Comma-separated WorldGuard region ids boxes must not spawn in (plots, structures).",
          "fieldType": "String",
          "isRequired": false,
          "isReadOnly": false,
          "order": 4
        }
      ]
    },
    {
      "stepName": "Limits",
      "order": 1,
      "fields": [
        {
          "fieldName": "MaxActive",
          "label": "Max active boxes",
          "fieldType": "Integer",
          "defaultValue": "3",
          "isRequired": true,
          "isReadOnly": false,
          "order": 0
        },
        {
          "fieldName": "SpawnIntervalSeconds",
          "label": "Spawn attempt every (seconds)",
          "description": "At least 60.",
          "fieldType": "Integer",
          "defaultValue": "600",
          "isRequired": true,
          "isReadOnly": false,
          "order": 1
        },
        {
          "fieldName": "SpawnChancePercent",
          "label": "Spawn chance (%)",
          "description": "Chance that an attempt spawns a box.",
          "fieldType": "Decimal",
          "defaultValue": "100",
          "isRequired": true,
          "isReadOnly": false,
          "order": 2
        },
        {
          "fieldName": "MinOnlinePlayers",
          "label": "Min players online",
          "fieldType": "Integer",
          "defaultValue": "3",
          "isRequired": true,
          "isReadOnly": false,
          "order": 3
        },
        {
          "fieldName": "MinDistanceFromPlayers",
          "label": "Min distance from players (blocks)",
          "fieldType": "Integer",
          "defaultValue": "24",
          "isRequired": true,
          "isReadOnly": false,
          "order": 4
        },
        {
          "fieldName": "LifetimeMinutes",
          "label": "Box lifetime (minutes)",
          "fieldType": "Integer",
          "defaultValue": "30",
          "isRequired": true,
          "isReadOnly": false,
          "order": 5
        }
      ]
    },
    {
      "stepName": "Allowed types",
      "order": 2,
      "isManyToManyRelationship": true,
      "relatedEntityPropertyName": "AllowedTypes",
      "joinEntityType": "LootboxSpawnAreaType",
      "subConfigurationId": "<AREA_TYPE_ID>",
      "fields": [
        {
          "fieldName": "AllowedTypes",
          "label": "Allowed box types (empty = every enabled type)",
          "fieldType": "List",
          "objectType": "LootboxSpawnAreaType",
          "isRequired": false,
          "isReadOnly": false,
          "order": 0
        }
      ]
    }
  ]
}
```

## Dev-DB checklist (developer, once)

1. POST 1-4, then 5-7 with the ids filled in.
2. `/admin/lootboxes` → Types → Edit Weapons: add a box-grade weight (★5 = 20), a pool entry (Include, weight 3) and change an
   enchant roll; save; Odds tab shows the new box-grade split and item weights; reopen the form: all rows pre-filled.
3. Specials → Edit Flaming Samurai → change the chance → Odds tab shows it.
4. Areas → New area: name `test_area`, *Send to Minecraft* on the region, `select <existing region>` in game; allowed types
   Weapons; save → the area appears in `/knk lootbox area list` after the runtime refresh.
