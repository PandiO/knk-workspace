# KNG-41 — PermissionGroup FormConfiguration: Teleport step (reference payloads)

**Status:** Reference record, not a seeder — data, not code
**Last updated:** 2026-10-06
**Linear:** [KNG-41](https://linear.app/kngpandi/issue/KNG-41) — setup step 2 of the to-do in
[IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) § "KNG-41"

The 17 `Teleport*` columns that KNG-41 added to `permission_groups` (web-api `29fcfe1`, migration
`20261005121006_AddPermissionGroupTeleportSettings`) only become editable in the web app once the PermissionGroup
FormConfiguration has fields for them. A FormConfiguration is rows in `FormConfigurations`/`FormSteps`/`FormFields`
(plus `DisplayConditionGroups`/`DisplayConditions`), not code. These rows were authored **live** against the running
API (`knk-web-api` from `claude/kng-42-implementation-vud0q8` at `df57b47`), the same approach as
`docs/specs/kits/PHASE_3_FORMCONFIGS.md`. They exist only in the developer's dev DB (`knightsandkings_dev_v2`):

| What | Id | Notes |
|---|---|---|
| Configuration `PermissionGroup - Default` (default for `PermissionGroup`) | 22 | existed; first PUT changed only `stepOrderJson` |
| Step `General Information` | 54 | fields 213–219 unchanged; color fields **407–409** added by the fix PUT (see "Form-22 problems fixed") |
| Step `Game multipliers` | 88 | first PUT: unchanged. Fix PUT: duplicate field 320 (`SalaryMultiplier`) removed, 321–322 defaults `1`. Its display group is re-created on every save, same content — see Decisions |
| **Step `Teleport`** (new, last) | **106** | fields **390–406**; field display groups 300–310, re-created as 312–322 by the fix PUT |

Any other database needs the step re-created — see "Re-creating it in another database".

## Decisions

- **Method: one `PUT /api/FormConfigurations/22` of the full graph as `GET` returned it, plus the new step.** The
  repository's update (`FormConfigurationRepository.UpdateAsync`) merges by id: steps and fields sent with their id
  are updated in place, and new ones (no id) are inserted. The rows before and after were compared column by column:
  every column of steps 54/88 and fields 213–219/320–322 is identical. `POST /api/FormSteps` (standalone step create)
  was rejected. It doesn't touch `stepOrderJson`, and it can't resolve field display conditions, which only the
  configuration save resolves (second pass, by field GUID). No route adds one step to an existing configuration.
- **`stepOrderJson`** was `["<step 54>", null]`: step 88 was never in the order list and sorted last as "unranked".
  It is now `["<step 54>", "<step 88>", "<step 106>"]`. Listing 88 was required: with the `null` kept, the
  ranked Teleport step would have sorted *before* the unranked step 88. The order users see for 54/88 is unchanged.
  (Step 88's own `fieldOrderJson` is still `[null,null,null]`; left alone.)
- **Side effect, expected:** every configuration save clears and rebuilds all display-condition groups
  (`SyncDisplayConditionGroups`). That is why step 88's "show when Premium Tier = true" group got a new id
  (298 → 299; condition 298 → 299, same source field 215, operator, value). The FormConfigBuilder's own saves do the same.
- **Field shape:** PascalCase entity property names (like step 88 and the Kit form; step 54's camelCase names were
  left alone, binding is case-insensitive). None `isRequired`. The three `…PriceMode` fields are `Enum`,
  `enumType: "TeleportPriceMode"`, `defaultValue: "None"`, with a `settingsJson.enumValues` snapshot like Kit's
  `CostCurrency`. Kit's field has `enumType: null`. The validator only checks that the entity property is an enum,
  and `withLiveEnumOptions` refreshes the options from live metadata either way. Multipliers are `Decimal`,
  everything else `Integer`.
- **Display conditions: included.** Each `…PriceMultiplier` field shows only when its mode `Equals "Multiplier"`.
  The `…PriceCoins/Gems/Experience` fields show only when it `Equals "Fixed"`. Cooldowns and modes always show. Each
  condition points at the mode field just above it in the same step, as the validator requires. A hidden field is
  submitted as `null`. That matches the API: when a kind's `…PriceMode` is in the DTO,
  `PermissionGroupTeleportSettings.Apply` writes all of that kind's fields, and only the active mode's fields are
  used anyway. **They were checked with the wizard's own code, not in a rendered browser** (see Verification). If
  they misbehave in the real FormWizard, remove them: `PUT` the configuration again with
  `"displayConditionGroups": []` on those fields.

## Payload

`PUT /api/FormConfigurations/22`, body = the full `GET /api/FormConfigurations/22` response of 2026-10-06 (unchanged:
ids, GUIDs, `fieldOrderJson`, `settingsJson`, step 88's display group) with two edits:

1. `"stepOrderJson": "[\"b7bc466a-8c66-417d-b94e-68a064f0dbdc\", \"b3577b7b-ac13-4cbb-abc9-2819b464873a\", \"994fafc3-0600-481f-8191-f25a1dba79ed\"]"`
2. this object appended to `"steps"` (no ids, so the API inserts it; GUIDs chosen client-side so the conditions can
   reference the mode fields):

```json
{
  "stepGuid": "994fafc3-0600-481f-8191-f25a1dba79ed",
  "stepName": "Teleport",
  "description": "Teleport fees and cooldowns for members (KNG-41). The player's groups are checked from the highest Weight down, each followed by its parent groups. The first group that sets a value wins; price and cooldown are checked separately.",
  "order": 2,
  "isReusable": false,
  "fieldOrderJson": "[\"4e61635c-70f3-465a-8f10-f6ee477f3cc3\", \"99eaed3a-1841-45ec-a0f0-b6a77f7cc46c\", \"cd24b45d-8e6a-4edd-8139-f7aff5a4362f\", \"87c4eaca-754d-4d39-9d38-b07fe1167288\", \"b13c5195-aa7b-4459-b307-f43577cc3a84\", \"e7f3225c-290d-44b1-aca7-09ce949fff8b\", \"9422ee15-d7e6-4fd7-8958-9e64e0548956\", \"ff39117e-85ca-43f3-8407-85c613fca95e\", \"9f07e51f-d476-47ba-a50a-299092b25b42\", \"ac23b4dd-6279-40a1-bcb0-1e37c8e3225b\", \"6c4fcadf-9689-4f6a-b7f5-b14c0aeef96e\", \"a195d0ed-ea0e-487a-9d7c-31bb6c6f6951\", \"80b8923c-aa6d-4552-af85-9e02b9652a45\", \"bb6f7039-1cdd-4c23-88e0-4d86f3ea0bc7\", \"9f228a42-d98d-474a-b6b4-a48d88ed4662\", \"4da826f0-5e9e-4ad1-9cce-1cca0b86e2f6\", \"b518365f-05fe-471f-8c3f-62079df383ed\"]",
  "conditions": [],
  "displayConditionGroups": [],
  "childFormSteps": [],
  "fields": [
    {"fieldGuid": "4e61635c-70f3-465a-8f10-f6ee477f3cc3", "fieldName": "TeleportRequestPriceMode", "label": "/tpa price", "description": "None = teleport.request.price-coins; Fixed = the prices below; Multiplier = price-coins × the multiplier. Keep this field on the form: it is the switch that saves the /tpa fields.", "fieldType": "Enum", "isRequired": false, "isReadOnly": false, "order": 0, "displayConditionGroups": [], "enumType": "TeleportPriceMode", "defaultValue": "None", "settingsJson": "{\"enumValues\": [\"None\", \"Fixed\", \"Multiplier\"]}"},
    {"fieldGuid": "99eaed3a-1841-45ec-a0f0-b6a77f7cc46c", "fieldName": "TeleportRequestPriceMultiplier", "label": "/tpa multiplier", "description": "Multiplier mode only. 0.5 = half, 0 = free (0–1000).", "fieldType": "Decimal", "isRequired": false, "isReadOnly": false, "order": 1, "displayConditionGroups": [{"targetType": "FormField", "innerLogic": "And", "combineWithPreviousLogic": "And", "order": 0, "isActive": true, "conditions": [{"sourceFieldGuid": "4e61635c-70f3-465a-8f10-f6ee477f3cc3", "operator": "Equals", "valueJson": "\"Multiplier\"", "order": 0}]}]},
    {"fieldGuid": "cd24b45d-8e6a-4edd-8139-f7aff5a4362f", "fieldName": "TeleportRequestPriceCoins", "label": "/tpa coins", "description": "Fixed mode only.", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 2, "displayConditionGroups": [{"targetType": "FormField", "innerLogic": "And", "combineWithPreviousLogic": "And", "order": 0, "isActive": true, "conditions": [{"sourceFieldGuid": "4e61635c-70f3-465a-8f10-f6ee477f3cc3", "operator": "Equals", "valueJson": "\"Fixed\"", "order": 0}]}]},
    {"fieldGuid": "87c4eaca-754d-4d39-9d38-b07fe1167288", "fieldName": "TeleportRequestPriceGems", "label": "/tpa gems", "description": "Fixed mode only.", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 3, "displayConditionGroups": [{"targetType": "FormField", "innerLogic": "And", "combineWithPreviousLogic": "And", "order": 0, "isActive": true, "conditions": [{"sourceFieldGuid": "4e61635c-70f3-465a-8f10-f6ee477f3cc3", "operator": "Equals", "valueJson": "\"Fixed\"", "order": 0}]}]},
    {"fieldGuid": "b13c5195-aa7b-4459-b307-f43577cc3a84", "fieldName": "TeleportRequestPriceExperience", "label": "/tpa XP", "description": "Fixed mode only. May lower the player's title.", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 4, "displayConditionGroups": [{"targetType": "FormField", "innerLogic": "And", "combineWithPreviousLogic": "And", "order": 0, "isActive": true, "conditions": [{"sourceFieldGuid": "4e61635c-70f3-465a-8f10-f6ee477f3cc3", "operator": "Equals", "valueJson": "\"Fixed\"", "order": 0}]}]},
    {"fieldGuid": "e7f3225c-290d-44b1-aca7-09ce949fff8b", "fieldName": "TeleportRequestCooldownSeconds", "label": "/tpa cooldown (s)", "description": "Replaces teleport.cooldown-seconds for the player who moves; empty = not set (0–86400).", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 5, "displayConditionGroups": []},
    {"fieldGuid": "9422ee15-d7e6-4fd7-8958-9e64e0548956", "fieldName": "TeleportWarpPriceMode", "label": "/warp price", "description": "None = the destination's gem price; Fixed = replaces it with the prices below; Multiplier = the destination's gems × the multiplier. Keep this field on the form: it is the switch that saves the /warp fields.", "fieldType": "Enum", "isRequired": false, "isReadOnly": false, "order": 6, "displayConditionGroups": [], "enumType": "TeleportPriceMode", "defaultValue": "None", "settingsJson": "{\"enumValues\": [\"None\", \"Fixed\", \"Multiplier\"]}"},
    {"fieldGuid": "ff39117e-85ca-43f3-8407-85c613fca95e", "fieldName": "TeleportWarpPriceMultiplier", "label": "/warp multiplier", "description": "Multiplier mode only. Rounded half up.", "fieldType": "Decimal", "isRequired": false, "isReadOnly": false, "order": 7, "displayConditionGroups": [{"targetType": "FormField", "innerLogic": "And", "combineWithPreviousLogic": "And", "order": 0, "isActive": true, "conditions": [{"sourceFieldGuid": "9422ee15-d7e6-4fd7-8958-9e64e0548956", "operator": "Equals", "valueJson": "\"Multiplier\"", "order": 0}]}]},
    {"fieldGuid": "9f07e51f-d476-47ba-a50a-299092b25b42", "fieldName": "TeleportWarpPriceCoins", "label": "/warp coins", "description": "Fixed mode only.", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 8, "displayConditionGroups": [{"targetType": "FormField", "innerLogic": "And", "combineWithPreviousLogic": "And", "order": 0, "isActive": true, "conditions": [{"sourceFieldGuid": "9422ee15-d7e6-4fd7-8958-9e64e0548956", "operator": "Equals", "valueJson": "\"Fixed\"", "order": 0}]}]},
    {"fieldGuid": "ac23b4dd-6279-40a1-bcb0-1e37c8e3225b", "fieldName": "TeleportWarpPriceGems", "label": "/warp gems", "description": "Fixed mode only.", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 9, "displayConditionGroups": [{"targetType": "FormField", "innerLogic": "And", "combineWithPreviousLogic": "And", "order": 0, "isActive": true, "conditions": [{"sourceFieldGuid": "9422ee15-d7e6-4fd7-8958-9e64e0548956", "operator": "Equals", "valueJson": "\"Fixed\"", "order": 0}]}]},
    {"fieldGuid": "6c4fcadf-9689-4f6a-b7f5-b14c0aeef96e", "fieldName": "TeleportWarpPriceExperience", "label": "/warp XP", "description": "Fixed mode only. May lower the player's title.", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 10, "displayConditionGroups": [{"targetType": "FormField", "innerLogic": "And", "combineWithPreviousLogic": "And", "order": 0, "isActive": true, "conditions": [{"sourceFieldGuid": "9422ee15-d7e6-4fd7-8958-9e64e0548956", "operator": "Equals", "valueJson": "\"Fixed\"", "order": 0}]}]},
    {"fieldGuid": "a195d0ed-ea0e-487a-9d7c-31bb6c6f6951", "fieldName": "TeleportWarpCooldownSeconds", "label": "/warp cooldown (s)", "description": "Replaces teleport.cooldown-seconds; empty = not set.", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 11, "displayConditionGroups": []},
    {"fieldGuid": "80b8923c-aa6d-4552-af85-9e02b9652a45", "fieldName": "TeleportSpawnPriceMode", "label": "/spawn price", "description": "None = free; Fixed = the prices below. Multiplier is refused (/spawn has no default price). Keep this field on the form: it is the switch that saves the /spawn fields.", "fieldType": "Enum", "isRequired": false, "isReadOnly": false, "order": 12, "displayConditionGroups": [], "enumType": "TeleportPriceMode", "defaultValue": "None", "settingsJson": "{\"enumValues\": [\"None\", \"Fixed\", \"Multiplier\"]}"},
    {"fieldGuid": "bb6f7039-1cdd-4c23-88e0-4d86f3ea0bc7", "fieldName": "TeleportSpawnPriceCoins", "label": "/spawn coins", "description": "Fixed mode only.", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 13, "displayConditionGroups": [{"targetType": "FormField", "innerLogic": "And", "combineWithPreviousLogic": "And", "order": 0, "isActive": true, "conditions": [{"sourceFieldGuid": "80b8923c-aa6d-4552-af85-9e02b9652a45", "operator": "Equals", "valueJson": "\"Fixed\"", "order": 0}]}]},
    {"fieldGuid": "9f228a42-d98d-474a-b6b4-a48d88ed4662", "fieldName": "TeleportSpawnPriceGems", "label": "/spawn gems", "description": "Fixed mode only.", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 14, "displayConditionGroups": [{"targetType": "FormField", "innerLogic": "And", "combineWithPreviousLogic": "And", "order": 0, "isActive": true, "conditions": [{"sourceFieldGuid": "80b8923c-aa6d-4552-af85-9e02b9652a45", "operator": "Equals", "valueJson": "\"Fixed\"", "order": 0}]}]},
    {"fieldGuid": "4da826f0-5e9e-4ad1-9cce-1cca0b86e2f6", "fieldName": "TeleportSpawnPriceExperience", "label": "/spawn XP", "description": "Fixed mode only. May lower the player's title.", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 15, "displayConditionGroups": [{"targetType": "FormField", "innerLogic": "And", "combineWithPreviousLogic": "And", "order": 0, "isActive": true, "conditions": [{"sourceFieldGuid": "80b8923c-aa6d-4552-af85-9e02b9652a45", "operator": "Equals", "valueJson": "\"Fixed\"", "order": 0}]}]},
    {"fieldGuid": "b518365f-05fe-471f-8c3f-62079df383ed", "fieldName": "TeleportSpawnCooldownSeconds", "label": "/spawn cooldown (s)", "description": "Replaces teleport.cooldown-seconds; empty = not set.", "fieldType": "Integer", "isRequired": false, "isReadOnly": false, "order": 16, "displayConditionGroups": []}
  ]
}
```

Response: 200 with the saved configuration. Backups taken before the call (outside the repos):
`C:\Users\Pandi\Documents\Werk\db-backups\2026-10-06_kng41_form22_before.json` (the `GET`) and
`2026-10-06_kng41_forms_and_groups_before.sql` (mysqldump of the form tables, `permission_groups` and
`user_permission_groups`).

## Re-creating it in another database

1. Apply the migration. `GET /api/metadata/entities/PermissionGroup` must list the 17 `Teleport*` properties, with
   `TeleportPriceMode` enum values `None`, `Fixed`, `Multiplier`.
2. `GET /api/FormConfigurations/PermissionGroup` for the default PermissionGroup configuration; save the response.
3. **If it exists:** append the step object above to `steps`. Set `stepOrderJson` to the GUIDs of *all* existing
   steps in their current display order, followed by `994fafc3-…`. Replace any `null` entries with the real step
   GUIDs, as here. Then `PUT /api/FormConfigurations/{id}` with the whole body. The GUIDs can be reused as they
   are, since they are random. Compare the existing step/field rows before and after.
4. **If none exists:** `POST /api/FormConfigurations` with `entityTypeName: "PermissionGroup"`,
   `configurationName: "PermissionGroup - Default"`, `isDefault: true`, `isActive: true`, a first step with the
   group's scalar fields (Name, Weight, IsPremiumTier, SalaryMultiplier, GemBonusMultiplier, ExpBonusMultiplier,
   ChatPrefix, ChatSuffix, ChatPrimaryColor, ChatSecondaryColor, NameColor, ParentGroupId), then the step above.
5. Check the `GET` again: the Teleport step is last and has 17 fields; fields 2–5, 8–11 and 14–16 (1-based) carry one
   display group each.

## Verification (2026-10-06)

Done:
- Setup: the API runs from `df57b47` (contains `29fcfe1`). `__EFMigrationsHistory` has
  `20261005121006_AddPermissionGroupTeleportSettings`. `permission_groups` has the 17 columns. Metadata lists them,
  and the enum has the right values.
- Rows: the before/after comparison of every form-22 row is described under Decisions. The new rows have the
  expected type, enum type, default, `settingsJson` and conditions; the en dash in "0–1000" survived as UTF-8.
- **Wizard logic against the live configuration** (a throwaway Jest test in knk-web-app, deleted after the run,
  nothing committed). It ran `reconcileVisibility`, the wizard's step normalization/flattening and
  `normalizeFormSubmission` on the live `GET` of form 22 and Noble's live data:
  - loaded unchanged: Teleport shows the 3 modes + 3 cooldowns; the payload carries all three modes `"None"`,
    everything else `null`;
  - Warp → Multiplier, 0.5, Spawn cooldown 5: the multiplier field appears. Payload `TeleportWarpPriceMode:
    "Multiplier"`, `TeleportWarpPriceMultiplier: 0.5`, `TeleportSpawnCooldownSeconds: 5`, the rest `None`/`null`;
  - /tpa → Fixed with 10 coins, and a multiplier of 2 typed first: coins/gems/XP appear, the multiplier hides and
    is sent as `null`.

**Not done: the entity round trips of the task (plan step 5).** No web login was available for a headless browser.
The developer accepted skipping the browser. The plugin key could not be used from this session either, so these
were not sent: the PermissionGroup create/PUT, the membership and `GET /api/teleport-destinations/policy`. No
PermissionGroup or membership row was changed. These belong in the developer smoke test (plan § "KNG-41", step 3):

1. Edit a test group in `/forms/permissiongroup/edit/{id}`: Warp → Multiplier 0.5, Spawn cooldown 5.
   `GET /api/PermissionGroups/{id}` shows exactly those values, the other kinds `None`/`null`, and Name/Weight unchanged.
2. Edit again changing only the Name: the teleport values survive.
3. `curl -H "X-API-Key: <Security:PluginApiKey>" "http://localhost:<port>/api/teleport-destinations/policy?userId=<member>"`
   shows warp `Multiplier`/0.5 from that group, and spawn cooldown 5.
4. Spawn → Multiplier: the wizard shows the 400 "/spawn has no default price to multiply; use a fixed price."
5. Reset the group to `None`/empty. Check the dashboard PermissionGroup list and the player-profile group picker.

## Form-22 problems found on the way — fixed 2026-10-06

The simulation above also showed what the wizard sends for a Name-only edit. Two problems predated KNG-41 (by
reading the code and the simulated payload; never sent to the API). The developer asked for both to be fixed the
same day.

1. **A wizard edit cleared the group's chat colors.** `ChatPrimaryColor`, `ChatSecondaryColor` and `NameColor` were
   not on form 22, and the wizard sends only form fields. `PermissionGroupService.UpdateAsync` assigns all three
   from the DTO, so they became `null` (Noble has `&e`/`&6`/`&e`). **Fix (form data):** the three fields were added to
   step 54 (ids 407–409, `String`, optional, with the wizard's `minecraft-text-color` preview). The API was not
   changed to keep omitted colors, so clearing a color in the form still works.
2. **A wizard edit of a non-premium group failed.** Step 88 is shown only for Premium Tier, but the wizard's final
   submit flattened *every* field and gave hidden ones their `defaultValue`. Step 88's defaults were `"1,0"`, and
   it repeated `SalaryMultiplier` from step 54. The payload carried `"salaryMultiplier": 1` *and*
   `"SalaryMultiplier": "1,0"`. The API binds case-insensitively, the later key wins, `"1,0"` is not a decimal, and
   the controller answers a bare 400. For a premium group the duplicate silently overwrote a salary edit made in
   General Information. **Fixes:**
   - knk-web-app `d79b2e0` on `claude/kng-42-implementation-vud0q8` (pushed; reaches `main` with the KNG-41/42 merge): the final submit uses the new
     `flattenVisibleStepsData` (`utils/forms/formVisibility.ts`). Hidden steps and fields are left out entirely,
     as `reconcileVisibility` already documented. The other flatten callers (placeholders, parent context) still
     see every field. New unit tests are in `formVisibility.test.ts`; the form utils pass 67/67, and `tsc` is clean.
     Of the FormWizard suites, 9 pass. The 3 that fail (m2mJoinPrefill, siegeGatesJoin, ManyToMany editor UI)
     fail the same way without the change; see the build/test-repair row in `ACTIVE_SESSIONS.md`.
   - Form data, with the developer's go-ahead: field 320 (step 88 `SalaryMultiplier`) removed, because salary stays
     editable for every group in step 54. Fields 321/322 `defaultValue` `"1,0"` → `"1"`. Step 88 `fieldOrderJson`
     `[null,null,null]` → the two remaining GUIDs.
   - Omitted bonus multipliers are kept on update and default to 1.0 on create (existing API behaviour), so a
     non-premium group's stored bonuses are no longer touched.

**Fix payload:** `PUT /api/FormConfigurations/22`, body = the full `GET` taken just before (backup
`db-backups6-10-06_kng41_form22_before_fixes.json`) with these edits. In step 54, the three fields below were
appended and `fieldOrderJson` became
`[\"7e05d442-3725-43e8-a062-3a70d538fa46\", \"bbf20aea-fab7-43e7-8126-40aa42eb035f\", \"6a9b3447-a15b-4b33-8ef9-7ea7ed490ecb\", \"16f3a0df-4642-4ee4-ae27-79526af74100\", \"d40d90aa-88c5-40fa-a06d-bf7e70107b3c\", \"cf716108-e350-457c-bbfc-8737eb3713a5\", \"21a27ec6-9f01-4b7e-ada3-b9aa1d36d854\", \"08731952-464d-45a2-8b8c-687e133b6ca5\", \"2ae379e9-2ff2-46aa-a8a8-21231b39c6b4\", \"6caee713-e6b8-4745-9107-74a6a7d200e8\"]`.
In step 88, field 320 was dropped, 321/322 got `"defaultValue": "1"`, and `fieldOrderJson` became
`[\"129b529f-b36c-4a6a-9841-522c18356f5e\", \"4f2d409b-c137-4794-9ac6-33f454f8c13f\"]`.

```json
[
    {"fieldGuid": "08731952-464d-45a2-8b8c-687e133b6ca5", "fieldName": "chatPrimaryColor", "label": "Chat primary color", "description": "Main color of this group's chat messages: & codes only, e.g. &e. Empty = none.", "fieldType": "String", "isRequired": false, "isReadOnly": false, "order": 0, "settingsJson": "{\"minecraft-text-color\": {\"enabled\": true}}", "displayConditionGroups": []},
    {"fieldGuid": "2ae379e9-2ff2-46aa-a8a8-21231b39c6b4", "fieldName": "chatSecondaryColor", "label": "Chat secondary color", "description": "Second chat color (accents): & codes only, e.g. &6. Empty = none.", "fieldType": "String", "isRequired": false, "isReadOnly": false, "order": 0, "settingsJson": "{\"minecraft-text-color\": {\"enabled\": true}}", "displayConditionGroups": []},
    {"fieldGuid": "6caee713-e6b8-4745-9107-74a6a7d200e8", "fieldName": "nameColor", "label": "Name color", "description": "Color of the player's name in chat and the tab list: & codes only, e.g. &e. Empty = none.", "fieldType": "String", "isRequired": false, "isReadOnly": false, "order": 0, "settingsJson": "{\"minecraft-text-color\": {\"enabled\": true}}", "displayConditionGroups": []}
]
```

Checked afterwards: the rows match the intent; Teleport's 17 fields and conditions are intact. The wizard simulation
on the fixed form gives these payloads. A Name-only edit of Default (non-premium) sends no step-88 keys and its colors
`&a`/`&2`/`&7`. Noble sends its colors, one `salaryMultiplier` (1.1) and the two bonuses as numbers. Entity round
trips through the API are still part of the smoke test above.
