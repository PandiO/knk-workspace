# Item identity — Admin Guide

**Status:** Current · **Last updated:** 2026-11-19 (first version, item identity #141, docs PandiO/knk-workspace#796)
**Checked against:** knk-web-api `next` `7d213fd6`, knk-plugin `next` `2ef256e7` (not released; the plugin part is
off by default; the manual steps of the [smoke test § 0](../production-storage-transport-smoke-test.md#0-item-identity-141-api-and-plugin-tier3)
have not been run live yet)
**Related:** [production DESIGN § 8](../../specs/production-storage-transport/DESIGN.md#8-item-identity-note-9) (the
rules), [item identity architecture](../../architecture/item-identity.md) (API contract, resolver, tests),
[plugin configuration § 4.30](plugin-configuration.md#430-items), [Minecraft catalogue](minecraft-catalogue-admin-guide.md)
(the scan that generates shadows), [economy admin guide](economy-admin-guide.md) (kits and lootboxes that hand out
blueprint items)

Item identity makes every item a player obtains count as one **item blueprint**. Production, storage and shops (later
phases of [#22](https://github.com/PandiO/knk-workspace/issues/22)) count stock per blueprint, so a plain oak log a
player chopped must be "the Oak Log blueprint", not just `minecraft:oak_log`. Players see no difference: items look and
stack exactly as in vanilla. This guide is for staff who curate blueprints and for admins who switch it on.

## 1. What you need

1. **Node** `knk.admin.content` for everything in this guide that changes data (the report, generating shadows,
   moving a match). The Staff group holds it.
2. **knk-web-api** with migration `AddItemIdentity` applied ([production installation § 5.3](../production-installation.md#53-apply-the-migrations)).
3. **A completed Minecraft catalogue scan** of the game server's version (web app: **Admin → Minecraft catalogue**,
   **Scan server**). Without a scan there are no materials, so there is nothing to match.
4. **A REST client or Swagger** (`/swagger` on the API) signed in as staff. There is no web app page for item identity
   yet ([#792](https://github.com/PandiO/knk-workspace/issues/792)); the blueprints themselves are edited in the web
   app as usual.
5. For the game server part: knk-plugin from `next` with the `items.identity` keys in `config.yml` (§ 5).

## 2. How an item gets its blueprint

The game server reads three things, in this order, and stops at the first that answers:

1. **Instance tag** (`knightsandkings:knk_item_instance`): a unique item, for example a rolled lootbox item. Its
   blueprint is the instance's.
2. **Blueprint tag** (`knightsandkings:knk_blueprint`): an item a blueprint made that looks different from the plain
   vanilla item (a display name, lore, enchantments the blueprint sets).
3. **Vanilla match**: a plain item with no tag. Its material (`minecraft:oak_log`) points to exactly one blueprint.

An untagged item with a custom name, custom lore or another plugin's data is **left alone**: it keeps its name and
behaviour, it is not converted, and it is counted as unresolved (§ 6). A renamed bread is not "Phoenix Bread".

**The plain vanilla item never carries a tag.** A blueprint whose items look exactly like the vanilla item (every
generated shadow, and any curated blueprint without a display name or lore) builds the plain item without a tag. A
plain item that still has a stale tag (from an older build, or a blueprint edited to plain since) loses the tag when a
player picks it up or obtains it another way, and joins the plain stack. That is why tagged and untagged stacks of the
same item never sit side by side.

## 3. Vanilla shadows and the "Uncurated" category

Every obtainable material has exactly one blueprint. For materials nobody has made a blueprint for, the API creates a
**vanilla shadow**:

1. **When:** after every completed catalogue scan, and when you call `POST api/ItemIdentity/shadows/generate`.
2. **What:** a blueprint named after the material (for example "Oak Log"), with an empty display name and no lore, the
   material as its icon, its stack size, and the description "Generated vanilla shadow of minecraft:oak_log. Curate
   it, or move the vanilla match to a curated blueprint." It holds the material's vanilla match.
3. **Where:** the top-level category **Uncurated**, created by the first run that needs it. Any blueprint in that
   category is counted as a shadow; a blueprint in any other category is counted as curated.
4. **Not for:** items a survival player can't obtain: air, barrier, bedrock, light, structure void, command blocks
   and the command block minecart, structure and jigsaw blocks, the debug stick, the knowledge book, test blocks, end
   portal frame, reinforced deepslate, budding amethyst, petrified oak slab, spawner, trial spawner, vault, farmland,
   dirt path, frogspawn, and every spawn egg. A shadow for some other creative-only item is harmless; you may delete it.
5. **Never destructive:** generation only adds. It does not change or remove a blueprint or a match, so running it
   again creates only what is missing.

## 4. Curating

### 4.1 Curate a shadow in place

Use this when the shadow is the right blueprint and only needs a proper home or name.

1. In the web app, open the shadow in the item blueprint list (category **Uncurated**).
2. Edit it: move it to a real category, adjust the name and description. The material's match stays on it; the edit
   form has no vanilla match field and can't clear it.
3. **Keep the display name and lore empty** if plain items in the world should keep stacking with the items this
   blueprint hands out. Giving it a display name makes items built from it (kits, lootboxes,
   `/knk itemblueprints give`) differ from the vanilla item: they get a blueprint tag and no longer stack with logs a
   player chopped. Plain logs still resolve to this blueprint through the match.

Once it is out of **Uncurated**, the report counts it under `curatedMatches` and the material map sends
`"shadow": false` for it.

### 4.2 Move a vanilla match to another blueprint

Use this when a curated blueprint should be the one a plain item resolves to (for example a "Bread" blueprint you made
yourself, while the generated "Bread" shadow holds the match).

1. Find the material's catalogue id: `POST api/MinecraftMaterialRefs/search` or `GET api/MinecraftMaterialRefs`, or the
   blueprint's `vanillaMaterialMatchRefId` in `GET api/ItemBlueprints/<shadow id>`.
2. Call `PUT api/ItemIdentity/matches/<material id>` with `{ "itemBlueprintId": <curated blueprint id> }`.
3. Read the answer:
    1. `previousBlueprintId`: the blueprint that held the match (the shadow). It keeps existing, now without a match;
       delete it in the web app if nothing uses it.
    2. `releasedMaterialRefId`: a blueprint holds at most one match, so if your curated blueprint matched another
       material before, that material is now **unmatched**. Run `POST api/ItemIdentity/shadows/generate` to give it a
       shadow again, or move it on purpose.
4. `{ "itemBlueprintId": null }` clears the match; the material is unmatched until the next generation run.
5. The game server picks the change up at its next map refresh (`items.identity.map-refresh-minutes`, 10 by default).

### 4.3 Delete a shadow

Deleting a shadow leaves its material unmatched; the next scan or generation run creates a new shadow for it. To get
rid of a shadow for good, move the match to a curated blueprint first (§ 4.2).

## 5. Switching it on in game

Both keys are `false` by default, and then nothing of item identity runs: items are built and handled as before. The
full key table is in [plugin configuration § 4.30](plugin-configuration.md#430-items).

```yaml
items:
  identity:
    enabled: false           # material map, blueprint tags on items that differ from vanilla, counts
    convert-on-obtain: false # the conversion hooks; needs enabled
    map-refresh-minutes: 10
    report-interval-minutes: 10
```

1. Make sure the scan and shadow generation are done (§ 6: `unmatchedMaterials` empty).
2. Merge the block into `config.yml` (`saveDefaultConfig()` never adds new keys), set `enabled: true`, restart.
   The log shows `[ItemIdentity] enabled; conversion hooks off` and `[ItemIdentity] material map: <n> materials with a
   blueprint`.
3. Set `convert-on-obtain: true` and restart to turn on the hooks: pickup (players), block drops, mob drops, fishing,
   crafting, villager and wandering trader trades, and the first open of a container block since the server started.
4. To switch off, set both to `false` and restart. Items already tagged keep their tag; nothing else changes.

The hooks only read the cached map, never the API, and the only change they make to an item is removing a stale
blueprint tag from an otherwise plain item.

## 6. Reading the report

`GET api/ItemIdentity/report?days=7` (1 to 90 days, default 7):

1. `obtainableMaterials`, `matchedMaterials`, `shadowMatches`, `curatedMatches`: coverage. After a scan
   `matchedMaterials` should equal `obtainableMaterials`.
2. `unmatchedMaterials`: obtainable materials without a blueprint. Expected only right after you moved or cleared a
   match, or when the post-scan generation failed (the API log says "generating the vanilla shadow blueprints
   failed"). Fix: `POST api/ItemIdentity/shadows/generate`.
3. `conversions`: what the game server counted per hook (`pickup`, `block_drop`, `entity_death`, `fishing`, `craft`,
   `trade`, `container_open`) and outcome (`vanilla_match`, `blueprint_tag`, `instance_tag`, `normalized` for a
   removed stale tag, `unresolved_<reason>`).
4. `topUnresolved`: the 50 material and reason pairs most often left alone. `unresolved_custom_name` and
   `unresolved_custom_lore` are renamed or other plugins' items; `unresolved_other_data` is another plugin's data;
   `unresolved_no_match` means a material without a blueprint (generate shadows).

The game server also writes `[ItemIdentity] conversions since the last report: …` to its log every
`report-interval-minutes`, and `[ItemIdentity] left alone (<outcome>): <material> from <hook>` once per reason and
material.

## 7. Safe test procedure

Run it on a test server first; [smoke test § 0](../production-storage-transport-smoke-test.md#0-item-identity-141-api-and-plugin-tier3)
has every step in full.

1. Scan, then check the report: `unmatchedMaterials` empty.
2. `POST api/ItemIdentity/shadows/generate` twice: `created: 0` both times.
3. Turn on `enabled` and `convert-on-obtain` with `report-interval-minutes: 1`; chop a log, kill a cow, craft
   something; after a minute the report lists the hooks with `vanilla_match`.
4. Claim a kit and open a lootbox: both deliver as before.

## 8. Effects on existing data

1. The migration adds one nullable column with a unique index (`item_blueprints.VanillaMaterialMatchRefId`) and one
   new table (`item_conversion_stats`). Existing blueprints get no match; the first scan or generation run creates
   shadows only for materials no blueprint matches, so it does **not** link your existing curated blueprints to their
   materials. Move those matches yourself (§ 4.2) where a curated blueprint should be the canonical one.
2. Items handed out **before** `enabled` was on carry no blueprint tag. A customised one (for example a named Phoenix
   Bread from a kit) is then read as a renamed item: it is left alone, counted `unresolved_custom_name`, and doesn't
   stack with new tagged copies. Follow-up: [#791](https://github.com/PandiO/knk-workspace/issues/791).

## 9. Troubleshooting

| What you see | Likely cause | What to do |
|---|---|---|
| 403 on the report, generate or a match | The account lacks `knk.admin.content` | Use a Staff account |
| 404 on `PUT api/ItemIdentity/matches/<id>` | Wrong material id or blueprint id | Look the ids up again (§ 4.2) |
| 409 `ConcurrentGeneration` | Two generation runs at the same time (for example a scan finished while you called generate) | Run generate again |
| `unmatchedMaterials` not empty after a scan | Generation after the scan failed (API log) or a match was moved or cleared | `POST api/ItemIdentity/shadows/generate` |
| No `[ItemIdentity]` line at start | `items.identity.enabled` is `false` or missing in `config.yml` | Merge the block, set it, restart |
| `material map refresh failed, keeping the previous one` | API down or plugin key wrong | Fix the API connection; the server keeps the last map |
| Report shows no conversions | `convert-on-obtain` off, or the map was never loaded (nothing is counted until it is) | Turn it on, check the map line in the log |
| A kit item doesn't stack with an older copy | The older copy was handed out before `enabled` was on | Known limit, [#791](https://github.com/PandiO/knk-workspace/issues/791) |
