# Siege Phase 3 — authored FormConfigurations (reference payloads)

**Status:** Reference record, not a seeder — data, not code
**Last updated:** 2026-09-25

The siege authoring forms (Phase 3 of `IMPLEMENTATION_PLAN.md`) and the Phase 1 leftovers were authored **live** with `POST /api/FormConfigurations` against the shared dev DB (`knightsandkings_dev_v2`, via the API on port 5099), the Items precedent (`docs/specs/items/PHASE_2_FORMCONFIGS.md`). A FormConfiguration is rows in `FormConfigurations`/`FormSteps`/`FormFields`, so it exists only in that database. This file holds the exact payloads so the forms can be rebuilt in another database.

Backup taken first: `C:\Users\Pandi\Documents\Werk\db-backups\knightsandkings_dev_v2_before_siege_phase3_20260925_193756.sql`.

## Ids in the dev DB

| Id | Entity | Configuration |
|---|---|---|
| 23 | `BannerLayer` | BannerLayer - Default |
| 24 | `BannerDesign` | BannerDesign - Default |
| 25 | `Clan` | Clan - Default |
| 26 | `SiegeScenarioDistrict` | SiegeScenarioDistrict - Join Entry |
| 27 | `SiegeScenarioGate` | SiegeScenarioGate - Join Entry |
| 28 | `SiegeLobbyScenario` | SiegeLobbyScenario - Join Entry |
| 29 | `SiegeSpawnpoint` | SiegeSpawnpoint - Default |
| 30 | `SiegeTeam` | SiegeTeam - Default |
| 31 | `SiegeObjective` | SiegeObjective - Default |
| 32 | `SiegeScenario` | SiegeScenario - Default |
| 33 | `SiegeLobby` | SiegeLobby - Default |
| 9 (changed) | `GateStructure` | Gate Structure Configuration — `IsSiegeObjective` removed (below) |

Every configuration passed `GET /api/field-validation-rules/health-check/configuration/{id}` with no issues.

## Recreating them elsewhere

1. The web-app and web-api code from `claude/siege-minigame` must be deployed first: the payloads use settings the older wizard ignores, and the pickers need the Phase 3 search filters.
2. `POST /api/FormConfigurations` each payload below **in the order listed** (join entries and children before the parents). Every body also needs `"isReusable": false, "isLinkedToSource": false, "hasCompatibilityIssues": false, "validations": [], "displayConditionGroups": []` on each field and `"isReusable": false, "isLinkedToSource": false, "hasCompatibilityIssues": false, "childFormSteps": [], "conditions": [], "displayConditionGroups": []` on each step (left out below for readability; `settingsJson` is shown as the string the API stores).
3. In `SiegeScenario` and `SiegeLobby`, replace each `subConfigurationId` with the id the matching join entry got in step 2. Unlike the Items precedent no create-then-PUT is needed: the join entries exist before the parent, so the id goes straight into the POST.
4. Apply the GateStructure change at the end of this file.

## Conventions these payloads rely on

- **Field names are the C# property names** (`SiegeScenarioId`, `GateStructureId`), not camelCase: the owned-child prefill, the join-entry mapping and `normalizeFormSubmission` look fields up by metadata name (Items Phase 2 note). The API binds the PascalCase payload case-insensitively.
- **Owned-child parent links are read-only** (`SiegeTeam.SiegeScenarioId`, `SiegeSpawnpoint.SiegeTeamId`, `SiegeObjective.SiegeScenarioId`, `BannerLayer.BannerDesignId`): `ChildFormModal` pre-fills them from the parent the admin is editing, and the children are only ever created from there (their create endpoints are nested under the parent).
- **`settingsJson` keys** (web-app, see the Phase 3 status block in `IMPLEMENTATION_PLAN.md`):
  - `{"ownedChildCollection": true}` — List field of an owned child (cards + Create New + Edit instance).
  - `{"pickerFilters": {"<filter>": "<value or {token}>"}, "pickerFiltersMissingMessage": "..."}` — the Select-instance picker searches with these filters. `{parent.X}` = field X of the record the child/join form was opened from (`{parent.id}` its id, -1 while unsaved), `{X}` = this form's own field, trailing `?` = optional. An unresolved required token blocks the picker with the message.
  - `{"enumValues": [...], "enumValuesSubset": true}` — keep the authored subset instead of every live enum value (OPEN/CLOSED gate states; `Continuous` lobby mode).
  - `{"displayPanel": "siegeScenarioReadiness"}` — render the readiness panel instead of an input (on the read-only, not-required `Id` field, which exists on every entity and never changes the payload).
  - `{"worldTask": {"enabled": true, "taskType": "LocationSelection"}}` — "Send to Minecraft" capture.
  - String fields with `enumValues` render as a dropdown (`ChatColor`, `PatternKey`). **Don't give a free-text String field a `defaultValue` or `placeholder`**: `FieldRenderers.getEnumValues` falls back to splitting those on commas and would turn the field into a one-option dropdown (pre-existing behaviour).

## BannerLayer — id 23

Phase 1 leftover. Owned child of BannerDesign (created from its Layers step).

```json
POST /api/FormConfigurations
{
  "entityTypeName": "BannerLayer",
  "configurationName": "BannerLayer - Default",
  "description": "One layer of a banner design. Created from the banner's Layers step (owned child).",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Layer",
      "order": 0,
      "description": "Layers render bottom to top; at most 16 (more than 6 can't be made in a survival loom).",
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "BannerDesignId", "label": "Banner design", "fieldType": "Object", "objectType": "BannerDesign", "isRequired": true, "isReadOnly": true, "order": 0, "description": "The banner this layer belongs to (filled in from the banner you are editing)."},
        {"fieldName": "PatternKey", "label": "Pattern", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 1, "settingsJson": "{\"enumValues\": [\"minecraft:base\", \"minecraft:square_bottom_left\", \"minecraft:square_bottom_right\", \"minecraft:square_top_left\", \"minecraft:square_top_right\", \"minecraft:stripe_bottom\", \"minecraft:stripe_top\", \"minecraft:stripe_left\", \"minecraft:stripe_right\", \"minecraft:stripe_center\", \"minecraft:stripe_middle\", \"minecraft:stripe_downright\", \"minecraft:stripe_downleft\", \"minecraft:small_stripes\", \"minecraft:cross\", \"minecraft:straight_cross\", \"minecraft:triangle_bottom\", \"minecraft:triangle_top\", \"minecraft:triangles_bottom\", \"minecraft:triangles_top\", \"minecraft:diagonal_left\", \"minecraft:diagonal_up_right\", \"minecraft:diagonal_up_left\", \"minecraft:diagonal_right\", \"minecraft:circle\", \"minecraft:rhombus\", \"minecraft:half_vertical\", \"minecraft:half_horizontal\", \"minecraft:half_vertical_right\", \"minecraft:half_horizontal_bottom\", \"minecraft:border\", \"minecraft:curly_border\", \"minecraft:gradient\", \"minecraft:gradient_up\", \"minecraft:bricks\", \"minecraft:globe\", \"minecraft:creeper\", \"minecraft:skull\", \"minecraft:flower\", \"minecraft:mojang\", \"minecraft:piglin\", \"minecraft:flow\", \"minecraft:guster\"]}", "description": "Bukkit banner pattern."},
        {"fieldName": "Color", "label": "Colour", "fieldType": "Enum", "isRequired": true, "isReadOnly": false, "order": 2, "defaultValue": "BLACK", "settingsJson": "{\"enumValues\": [\"WHITE\", \"ORANGE\", \"MAGENTA\", \"LIGHT_BLUE\", \"YELLOW\", \"LIME\", \"PINK\", \"GRAY\", \"LIGHT_GRAY\", \"CYAN\", \"PURPLE\", \"BLUE\", \"BROWN\", \"GREEN\", \"RED\", \"BLACK\"]}"},
        {"fieldName": "SortOrder", "label": "Order", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 3, "description": "Bottom to top. Leave empty to put it on top of the existing layers."}
      ]
    }
  ]
}
```

## BannerDesign — id 24

Phase 1 leftover. `Layers` is the owned-child List (GateStructure -> GateDoor precedent).

```json
POST /api/FormConfigurations
{
  "entityTypeName": "BannerDesign",
  "configurationName": "BannerDesign - Default",
  "description": "A reusable banner: base colour plus ordered pattern layers (clans, ad-hoc siege teams).",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "General",
      "order": 0,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "Name", "label": "Name", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 0},
        {"fieldName": "BaseColor", "label": "Base colour", "fieldType": "Enum", "isRequired": true, "isReadOnly": false, "order": 1, "defaultValue": "WHITE", "settingsJson": "{\"enumValues\": [\"WHITE\", \"ORANGE\", \"MAGENTA\", \"LIGHT_BLUE\", \"YELLOW\", \"LIME\", \"PINK\", \"GRAY\", \"LIGHT_GRAY\", \"CYAN\", \"PURPLE\", \"BLUE\", \"BROWN\", \"GREEN\", \"RED\", \"BLACK\"]}"}
      ]
    },
    {
      "stepName": "Layers",
      "order": 1,
      "description": "Save the banner first (Submit), then open it again to add layers.",
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "Layers", "label": "Layers", "fieldType": "List", "objectType": "BannerLayer", "elementType": "Object", "isRequired": false, "isReadOnly": false, "order": 0, "settingsJson": "{\"ownedChildCollection\": true}"}
      ]
    }
  ]
}
```

## Clan — id 25

Phase 1 leftover.

```json
POST /api/FormConfigurations
{
  "entityTypeName": "Clan",
  "configurationName": "Clan - Default",
  "description": "A minimal clan identity: name, chat colour, banner, default town.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "General",
      "order": 0,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "Name", "label": "Name", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 0},
        {"fieldName": "IsNpc", "label": "NPC clan", "fieldType": "Boolean", "isRequired": false, "isReadOnly": false, "order": 1, "defaultValue": "false", "description": "A baseline crown/garrison clan rather than a player clan."},
        {"fieldName": "ChatColor", "label": "Chat colour", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 2, "defaultValue": "WHITE", "settingsJson": "{\"enumValues\": [\"BLACK\", \"DARK_BLUE\", \"DARK_GREEN\", \"DARK_AQUA\", \"DARK_RED\", \"DARK_PURPLE\", \"GOLD\", \"GRAY\", \"DARK_GRAY\", \"BLUE\", \"GREEN\", \"AQUA\", \"RED\", \"LIGHT_PURPLE\", \"YELLOW\", \"WHITE\"]}"}
      ]
    },
    {
      "stepName": "Identity",
      "order": 1,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "BannerDesignId", "label": "Banner", "fieldType": "Object", "objectType": "BannerDesign", "isRequired": true, "isReadOnly": false, "order": 0},
        {"fieldName": "DefaultForTownId", "label": "Default clan for town", "fieldType": "Object", "objectType": "Town", "isRequired": false, "isReadOnly": false, "order": 1, "description": "Optional. A town has at most one default clan; siege teams in that town list it first."}
      ]
    }
  ]
}
```

## SiegeScenarioDistrict — id 26

Join entry for the scenario's Districts step - create before SiegeScenario.

```json
POST /api/FormConfigurations
{
  "entityTypeName": "SiegeScenarioDistrict",
  "configurationName": "SiegeScenarioDistrict - Join Entry",
  "description": "Join entry for adding a district to a siege scenario (the scenario's Districts step).",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "District",
      "order": 0,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "DistrictId", "label": "District", "fieldType": "Object", "objectType": "District", "isRequired": true, "isReadOnly": false, "order": 0, "settingsJson": "{\"pickerFilters\": {\"townId\": \"{parent.TownId?}\"}}", "description": "Lists the districts of the scenario's town (pick the town on the General step first)."}
      ]
    }
  ]
}
```

## SiegeScenarioGate — id 27

Join entry for the scenario's Gates step (three join fields) - create before SiegeScenario.

```json
POST /api/FormConfigurations
{
  "entityTypeName": "SiegeScenarioGate",
  "configurationName": "SiegeScenarioGate - Join Entry",
  "description": "Join entry for selecting a gate in a siege scenario (the scenario's Gates step).",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Gate",
      "order": 0,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "GateStructureId", "label": "Gate", "fieldType": "Object", "objectType": "GateStructure", "isRequired": true, "isReadOnly": false, "order": 0, "settingsJson": "{\"pickerFilters\": {\"townId\": \"{parent.TownId?}\"}}", "description": "Lists the gates in the scenario's town. It must lie in one of the scenario's districts, if any are selected."},
        {"fieldName": "InitialOwnerTeamId", "label": "Owner team at match start", "fieldType": "Object", "objectType": "SiegeTeam", "isRequired": false, "isReadOnly": false, "order": 1, "settingsJson": "{\"pickerFilters\": {\"siegeScenarioId\": \"{parent.id}\"}, \"pickerFiltersMissingMessage\": \"Save the scenario and add its teams first - leave empty for the first Defender team.\"}", "description": "The team (and its allies) that may open and close it. Leave empty for the first Defender team."},
        {"fieldName": "InitialState", "label": "State at match start", "fieldType": "Enum", "isRequired": true, "isReadOnly": false, "order": 2, "defaultValue": "CLOSED", "settingsJson": "{\"enumValues\": [\"CLOSED\", \"OPEN\"], \"enumValuesSubset\": true}"},
        {"fieldName": "Damageable", "label": "Damageable", "fieldType": "Boolean", "isRequired": false, "isReadOnly": false, "order": 3, "defaultValue": "true", "description": "Enemies of the owner can damage and destroy it (destroyed gates stay destroyed until the match ends)."}
      ]
    }
  ]
}
```

## SiegeLobbyScenario — id 28

Join entry for the lobby's Rotation step - create before SiegeLobby.

```json
POST /api/FormConfigurations
{
  "entityTypeName": "SiegeLobbyScenario",
  "configurationName": "SiegeLobbyScenario - Join Entry",
  "description": "Join entry for adding a scenario to a siege lobby's rotation.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Scenario",
      "order": 0,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "SiegeScenarioId", "label": "Scenario", "fieldType": "Object", "objectType": "SiegeScenario", "isRequired": true, "isReadOnly": false, "order": 0, "description": "Only ready scenarios are played; an unready one may sit in the rotation and is skipped."},
        {"fieldName": "Weight", "label": "Weight", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 1, "defaultValue": "1", "description": "Relative chance of being drawn (1 or more)."}
      ]
    }
  ]
}
```

## SiegeSpawnpoint — id 29

Owned child of SiegeTeam.

```json
POST /api/FormConfigurations
{
  "entityTypeName": "SiegeSpawnpoint",
  "configurationName": "SiegeSpawnpoint - Default",
  "description": "A spawnpoint of a siege team. Created from the team's Spawnpoints step (owned child).",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Spawnpoint",
      "order": 0,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "SiegeTeamId", "label": "Team", "fieldType": "Object", "objectType": "SiegeTeam", "isRequired": true, "isReadOnly": true, "order": 0, "description": "The team this spawnpoint belongs to (filled in from the team you are editing)."},
        {"fieldName": "Name", "label": "Name", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 1},
        {"fieldName": "SortOrder", "label": "Order", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 2, "description": "0 = the team's default spawn. Leave empty to add it after the existing ones."},
        {"fieldName": "SafeZoneRadius", "label": "Safe-zone radius", "fieldType": "Decimal", "isRequired": true, "isReadOnly": false, "order": 3, "defaultValue": "4", "description": "Blocks around the spawn where the team can't be attacked (0-64)."}
      ]
    },
    {
      "stepName": "Location",
      "order": 1,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "LocationId", "label": "Location", "fieldType": "Object", "objectType": "Location", "isRequired": true, "isReadOnly": false, "order": 0, "settingsJson": "{\"worldTask\": {\"enabled\": true, \"taskType\": \"LocationSelection\"}}", "description": "Stand on the spot in-game and use Send to Minecraft. It must lie inside the town's region."}
      ]
    }
  ]
}
```

## SiegeTeam — id 30

Owned child of SiegeScenario; owns Spawnpoints (the two-level nesting).

```json
POST /api/FormConfigurations
{
  "entityTypeName": "SiegeTeam",
  "configurationName": "SiegeTeam - Default",
  "description": "A team of a siege scenario: role, alliance, identity (clan or ad-hoc) and spawnpoints. Created from the scenario's Teams step.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "Identity",
      "order": 0,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "SiegeScenarioId", "label": "Scenario", "fieldType": "Object", "objectType": "SiegeScenario", "isRequired": true, "isReadOnly": true, "order": 0, "description": "The scenario this team belongs to (filled in from the scenario you are editing)."},
        {"fieldName": "Role", "label": "Role", "fieldType": "Enum", "isRequired": true, "isReadOnly": false, "order": 1, "defaultValue": "Attacker", "settingsJson": "{\"enumValues\": [\"Defender\", \"Attacker\"]}", "description": "The first Defender team holds the objectives and owns the gates by default."},
        {"fieldName": "AllianceGroup", "label": "Alliance group", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 2, "defaultValue": "1", "description": "Teams with the same number are allies; every other team is an enemy. A scenario needs at least two groups."},
        {"fieldName": "ClanId", "label": "Clan", "fieldType": "Object", "objectType": "Clan", "isRequired": false, "isReadOnly": false, "order": 3, "settingsJson": "{\"pickerFilters\": {\"preferTownId\": \"{parent.TownId?}\"}}", "description": "Take name, colour and banner from a clan (the town's default clan is listed first). Leave empty for an ad-hoc team."},
        {"fieldName": "Name", "label": "Name", "fieldType": "String", "isRequired": false, "isReadOnly": false, "order": 4, "description": "Required without a clan; with a clan it overrides the clan's name."},
        {"fieldName": "ChatColor", "label": "Chat colour", "fieldType": "String", "isRequired": false, "isReadOnly": false, "order": 5, "settingsJson": "{\"enumValues\": [\"BLACK\", \"DARK_BLUE\", \"DARK_GREEN\", \"DARK_AQUA\", \"DARK_RED\", \"DARK_PURPLE\", \"GOLD\", \"GRAY\", \"DARK_GRAY\", \"BLUE\", \"GREEN\", \"AQUA\", \"RED\", \"LIGHT_PURPLE\", \"YELLOW\", \"WHITE\"]}", "description": "Required without a clan; with a clan it overrides the clan's colour."},
        {"fieldName": "BannerDesignId", "label": "Banner", "fieldType": "Object", "objectType": "BannerDesign", "isRequired": false, "isReadOnly": false, "order": 6, "description": "Required without a clan; with a clan it overrides the clan's banner."},
        {"fieldName": "StartMessage", "label": "Start message", "fieldType": "String", "isRequired": false, "isReadOnly": false, "order": 7, "description": "Optional action-bar message for this team when the match starts."},
        {"fieldName": "SortOrder", "label": "Order", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 8, "description": "Leave empty to add it after the existing teams."}
      ]
    },
    {
      "stepName": "Spawnpoints",
      "order": 1,
      "description": "Every team needs at least one spawnpoint. Save the team first (Submit), then Edit it again to add spawnpoints.",
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "Spawnpoints", "label": "Spawnpoints", "fieldType": "List", "objectType": "SiegeSpawnpoint", "elementType": "Object", "isRequired": false, "isReadOnly": false, "order": 0, "settingsJson": "{\"ownedChildCollection\": true}"}
      ]
    }
  ]
}
```

## SiegeObjective — id 31

Owned child of SiegeScenario. The "Gate behaviour" step is shown only when a gate is picked (step display condition on `GateStructureId`, referenced by `fieldGuid`; any UUID works as long as the two match).

```json
POST /api/FormConfigurations
{
  "entityTypeName": "SiegeObjective",
  "configurationName": "SiegeObjective - Default",
  "description": "A capture objective of a siege scenario. Created from the scenario's Objectives step.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "General",
      "order": 0,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "SiegeScenarioId", "label": "Scenario", "fieldType": "Object", "objectType": "SiegeScenario", "isRequired": true, "isReadOnly": true, "order": 0, "description": "The scenario this objective belongs to (filled in from the scenario you are editing)."},
        {"fieldName": "Name", "label": "Name", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 1},
        {"fieldName": "InstantVictory", "label": "Instant victory", "fieldType": "Boolean", "isRequired": false, "isReadOnly": false, "order": 2, "defaultValue": "false", "description": "Capturing it ends the match (a main objective). Otherwise it is a side objective."},
        {"fieldName": "InitialHolderTeamId", "label": "Held by at match start", "fieldType": "Object", "objectType": "SiegeTeam", "isRequired": false, "isReadOnly": false, "order": 3, "settingsJson": "{\"pickerFilters\": {\"siegeScenarioId\": \"{SiegeScenarioId}\"}}", "description": "Leave empty for the first Defender team."},
        {"fieldName": "SpawnWhenHeld", "label": "Spawnpoint when held", "fieldType": "Boolean", "isRequired": false, "isReadOnly": false, "order": 4, "defaultValue": "true", "description": "The holding team may spawn here."},
        {"fieldName": "SortOrder", "label": "Order", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 5, "description": "Leave empty to add it after the existing objectives."}
      ]
    },
    {
      "stepName": "Capture point",
      "order": 1,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "GateStructureId", "label": "Gate", "fieldType": "Object", "objectType": "GateStructure", "isRequired": false, "isReadOnly": false, "order": 0, "settingsJson": "{\"pickerFilters\": {\"siegeScenarioId\": \"{SiegeScenarioId}\"}}", "fieldGuid": "1518749a-dbeb-4115-9142-fac723833696", "description": "Optional: capturing this objective captures the gate. Only gates already SAVED in the scenario's Gates step are listed."},
        {"fieldName": "LocationId", "label": "Capture location", "fieldType": "Object", "objectType": "Location", "isRequired": false, "isReadOnly": false, "order": 1, "settingsJson": "{\"worldTask\": {\"enabled\": true, \"taskType\": \"LocationSelection\"}}", "description": "Stand on the spot in-game and use Send to Minecraft. Required without a gate; with a gate it defaults to the gate's own location."},
        {"fieldName": "CapturePoints", "label": "Capture points", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 2, "defaultValue": "500"},
        {"fieldName": "CaptureRadius", "label": "Capture radius", "fieldType": "Decimal", "isRequired": true, "isReadOnly": false, "order": 3, "defaultValue": "2.5", "description": "Blocks (above 0, at most 32)."}
      ]
    },
    {
      "stepName": "Gate behaviour",
      "order": 2,
      "description": "What happens to the objective's gate when the objective is captured.",
      "isManyToManyRelationship": false,
      "displayConditionGroups": [{"targetType": "FormStep", "innerLogic": "And", "combineWithPreviousLogic": "And", "order": 0, "isActive": true, "conditions": [{"sourceFieldGuid": "1518749a-dbeb-4115-9142-fac723833696", "operator": "IsNotEmpty", "valueJson": "null", "order": 0}]}],
      "fields": [
        {"fieldName": "GateStateOnCapture", "label": "Gate state on capture", "fieldType": "Enum", "isRequired": true, "isReadOnly": false, "order": 0, "defaultValue": "OPEN", "settingsJson": "{\"enumValues\": [\"OPEN\", \"CLOSED\"], \"enumValuesSubset\": true}"}
      ]
    }
  ]
}
```

## SiegeScenario — id 32

References the District/Gate join entries by `subConfigurationId` (26/27 in the dev DB). Nine steps; the last is the read-only readiness panel.

```json
POST /api/FormConfigurations
{
  "entityTypeName": "SiegeScenario",
  "configurationName": "SiegeScenario - Default",
  "description": "A siege map/mode: town, districts, hub, entry rules, match length, rewards, teams, gates, objectives, readiness. Authored in several saves.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "General",
      "order": 0,
      "description": "A new scenario is saved when you Submit on the last step; teams, gates and objectives are added by editing it afterwards.",
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "Name", "label": "Name", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 0},
        {"fieldName": "Description", "label": "Description", "fieldType": "String", "isRequired": false, "isReadOnly": false, "order": 1},
        {"fieldName": "TownId", "label": "Town", "fieldType": "Object", "objectType": "Town", "isRequired": true, "isReadOnly": false, "order": 2, "description": "The town being besieged. Districts, gates and every captured point must belong to it."}
      ]
    },
    {
      "stepName": "Districts",
      "order": 1,
      "description": "The districts the siege takes place in (and that are locked down during a match). Add them with 'Create New Join Entry'.",
      "isManyToManyRelationship": true,
      "relatedEntityPropertyName": "Districts",
      "joinEntityType": "SiegeScenarioDistrict",
      "subConfigurationId": "26",
      "fields": [
        {"fieldName": "Districts", "label": "Districts", "fieldType": "List", "objectType": "SiegeScenarioDistrict", "isRequired": false, "isReadOnly": false, "order": 0}
      ]
    },
    {
      "stepName": "Hub & entry",
      "order": 2,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "HubLocationId", "label": "Hub location", "fieldType": "Object", "objectType": "Location", "isRequired": true, "isReadOnly": false, "order": 0, "settingsJson": "{\"worldTask\": {\"enabled\": true, \"taskType\": \"LocationSelection\"}}", "description": "Where players gather before the match. Stand on the spot in-game and use Send to Minecraft."},
        {"fieldName": "PlayersMin", "label": "Minimum players", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 1, "defaultValue": "2", "description": "At least the number of teams."},
        {"fieldName": "PlayersMax", "label": "Maximum players", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 2, "defaultValue": "50"},
        {"fieldName": "MinTitleBracketId", "label": "Minimum title", "fieldType": "Object", "objectType": "TitleBracket", "isRequired": false, "isReadOnly": false, "order": 3, "description": "Optional: players below this title can't join."},
        {"fieldName": "LockdownScenarioArea", "label": "Lock down the scenario area", "fieldType": "Boolean", "isRequired": false, "isReadOnly": false, "order": 4, "defaultValue": "true", "description": "Non-members can't enter the scenario's districts during a match."},
        {"fieldName": "AllowRecapture", "label": "Allow recapture", "fieldType": "Boolean", "isRequired": false, "isReadOnly": false, "order": 5, "defaultValue": "false", "description": "A captured objective can be taken back."},
        {"fieldName": "EnchantDropsEnabled", "label": "Enchant-book drops", "fieldType": "Boolean", "isRequired": false, "isReadOnly": false, "order": 6, "defaultValue": "true"}
      ]
    },
    {
      "stepName": "Match length",
      "order": 3,
      "description": "Match length = players × per-player seconds, clamped between the minimum and the maximum.",
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "MatchDurationMinSeconds", "label": "Minimum (seconds)", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 0, "defaultValue": "300"},
        {"fieldName": "MatchDurationPerPlayerSeconds", "label": "Per player (seconds)", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 1, "defaultValue": "75"},
        {"fieldName": "MatchDurationMaxSeconds", "label": "Maximum (seconds)", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 2, "defaultValue": "1800"}
      ]
    },
    {
      "stepName": "Rewards",
      "order": 4,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "CoinRewardWin", "label": "Coins for a win", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 0, "defaultValue": "100"},
        {"fieldName": "ExpRewardWin", "label": "XP for a win", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 1, "defaultValue": "10"},
        {"fieldName": "GemRewardWin", "label": "Gems for a win", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 2, "defaultValue": "1"},
        {"fieldName": "CoinRewardHolding", "label": "Coins for holding", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 3, "defaultValue": "50"},
        {"fieldName": "ExpRewardHolding", "label": "XP for holding", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 4, "defaultValue": "5"},
        {"fieldName": "CoinRewardCapture", "label": "Coins for a capture", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 5, "defaultValue": "50"},
        {"fieldName": "ExpRewardCapture", "label": "XP for a capture", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 6, "defaultValue": "5"}
      ]
    },
    {
      "stepName": "Teams",
      "order": 5,
      "description": "At least two teams in at least two alliance groups, one of them a Defender. Available once the scenario is saved; each team saves on its own.",
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "Teams", "label": "Teams", "fieldType": "List", "objectType": "SiegeTeam", "elementType": "Object", "isRequired": false, "isReadOnly": false, "order": 0, "settingsJson": "{\"ownedChildCollection\": true}"}
      ]
    },
    {
      "stepName": "Gates",
      "order": 6,
      "description": "Gates that take part in the siege. Add teams first to pick a gate's owner. Gates are saved when you Submit - Submit before adding an objective on a newly selected gate.",
      "isManyToManyRelationship": true,
      "relatedEntityPropertyName": "Gates",
      "joinEntityType": "SiegeScenarioGate",
      "subConfigurationId": "27",
      "fields": [
        {"fieldName": "Gates", "label": "Gates", "fieldType": "List", "objectType": "SiegeScenarioGate", "isRequired": false, "isReadOnly": false, "order": 0}
      ]
    },
    {
      "stepName": "Objectives",
      "order": 7,
      "description": "At least one objective. An objective on a gate needs that gate saved in the Gates step first. Each objective saves on its own.",
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "Objectives", "label": "Objectives", "fieldType": "List", "objectType": "SiegeObjective", "elementType": "Object", "isRequired": false, "isReadOnly": false, "order": 0, "settingsJson": "{\"ownedChildCollection\": true}"}
      ]
    },
    {
      "stepName": "Readiness",
      "order": 8,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "Id", "label": "Readiness", "fieldType": "Integer", "isRequired": false, "isReadOnly": true, "order": 0, "settingsJson": "{\"displayPanel\": \"siegeScenarioReadiness\"}", "description": "Only ready scenarios are played by a lobby."}
      ]
    }
  ]
}
```

## SiegeLobby — id 33

References the SiegeLobbyScenario join entry by `subConfigurationId` (28 in the dev DB).

```json
POST /api/FormConfigurations
{
  "entityTypeName": "SiegeLobby",
  "configurationName": "SiegeLobby - Default",
  "description": "A siege lobby players join (/siege join <key>): timings, voting and the scenario rotation.",
  "isDefault": true,
  "isActive": true,
  "steps": [
    {
      "stepName": "General",
      "order": 0,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "Name", "label": "Name", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 0, "description": "Shown in menus, e.g. \"Siege - Cinix\"."},
        {"fieldName": "Key", "label": "Key", "fieldType": "String", "isRequired": true, "isReadOnly": false, "order": 1, "description": "Used in /siege join <key>: lowercase letters, digits, - and _, unique."},
        {"fieldName": "IsEnabled", "label": "Enabled", "fieldType": "Boolean", "isRequired": false, "isReadOnly": false, "order": 2, "defaultValue": "false"},
        {"fieldName": "Mode", "label": "Mode", "fieldType": "Enum", "isRequired": true, "isReadOnly": false, "order": 3, "defaultValue": "Continuous", "settingsJson": "{\"enumValues\": [\"Continuous\"], \"enumValuesSubset\": true}", "description": "Scheduled lobbies come later (Phase 10)."}
      ]
    },
    {
      "stepName": "Timings",
      "order": 1,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "MatchmakingSeconds", "label": "Matchmaking (seconds)", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 0, "defaultValue": "300", "description": "At least 60."},
        {"fieldName": "CooldownSeconds", "label": "Cooldown between matches (seconds)", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 1, "defaultValue": "900"}
      ]
    },
    {
      "stepName": "Voting",
      "order": 2,
      "isManyToManyRelationship": false,
      "fields": [
        {"fieldName": "VoteCandidateCount", "label": "Scenarios to vote on", "fieldType": "Integer", "isRequired": true, "isReadOnly": false, "order": 0, "defaultValue": "2", "description": "1 to 3."},
        {"fieldName": "AllowRandomVote", "label": "Allow a 'random' vote", "fieldType": "Boolean", "isRequired": false, "isReadOnly": false, "order": 1, "defaultValue": "true"}
      ]
    },
    {
      "stepName": "Rotation",
      "order": 3,
      "description": "The scenarios this lobby draws from. Add them with 'Create New Join Entry'.",
      "isManyToManyRelationship": true,
      "relatedEntityPropertyName": "Rotation",
      "joinEntityType": "SiegeLobbyScenario",
      "subConfigurationId": "28",
      "fields": [
        {"fieldName": "Rotation", "label": "Rotation", "fieldType": "List", "objectType": "SiegeLobbyScenario", "isRequired": false, "isReadOnly": false, "order": 0}
      ]
    }
  ]
}
```

## GateStructure (id 9) — `IsSiegeObjective` removed from "Siege Behaviour"

DESIGN §8.5: `GateStructure.IsSiegeObjective` is runtime-maintained now (set at lockdown for objective gates, cleared on restore), so admins no longer edit it. `GET /api/FormConfigurations/9`, drop the `IsSiegeObjective` field (form field 92 in the dev DB) from the "Siege Behaviour" step's `fields` and its guid from that step's `fieldOrderJson`, then `PUT /api/FormConfigurations/9` with the whole body. Nothing referenced field 92 (no validation rules, display conditions or field validations); the other field ids were unchanged by the PUT. The step keeps `IsOverridable` and `AnimateDuringSiege`.
