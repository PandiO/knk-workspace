# Shield banner patterns and armour trims on blueprints and instances — smoke test

**Status:** Not run yet. Branches `claude/shield-banner-trim-232` in knk-web-api, knk-plugin and knk-web-app (2026-11-04), not merged
**Last updated:** 2026-11-04
**Issue:** [PandiO/knk-workspace#232](https://github.com/PandiO/knk-workspace/issues/232)
**Architecture:** [item render pipeline § 2c](../architecture/item-render-pipeline.md#2c-shield-banner-patterns-and-armour-trims-232)

Manual checks on the **dev** stack (dev API, web app and Paper server) of the one thing the unit tests cannot cover:
Bukkit's banner and trim registries only exist on a running server, so applying a pattern or a trim to a real item is
checked here. Record each run under **Findings** at the end, with the commits you tested.

## 0. Setup

1. **knk-web-api** on `claude/shield-banner-trim-232`: run it once; the migration `AddItemShieldBannerAndArmorTrim`
   applies on start-up (two new tables `item_blueprint_banner_layers` / `item_instance_banner_layers`, three nullable
   columns on `item_blueprints` and on `item_instances`). `dotnet test` on the branch: expect green (the session ran the
   full suite; see the PR description for the count).
2. **knk-web-app** on `claude/shield-banner-trim-232` (`npx npm@11 ci`, `npm start`). Web app, **Import / seeds**:
   re-import **ItemBlueprint – Default (seed v1)** (the seed file gained four fields on the "Item in game" step:
   Shield base colour, Shield banner pattern, Armour trim pattern, Armour trim material) and keep it the default.
   Without the re-import the form has no fields for the look and a scan silently keeps nothing of it.
3. **knk-plugin** on `claude/shield-banner-trim-232`: `./gradlew :knk-paper:dev`, restart the dev server.
4. In game, as an op: a shield with a loom pattern of **at least three layers** (loom: shield + banner with layers, or
   `/give @s minecraft:shield[base_color=red,banner_patterns=[{pattern:"minecraft:stripe_top",color:"yellow"},{pattern:"minecraft:cross",color:"white"},{pattern:"minecraft:border",color:"black"}]]`),
   a **plain shield**, and a **netherite chestplate with a trim**
   (`/give @s minecraft:netherite_chestplate[trim={pattern:"minecraft:silence",material:"minecraft:gold"}]`).

## 1. Shield: scan → save → build (blueprint round trip)

1. Web app, Item blueprints, **Create**. Hold the patterned shield, use **Send to Minecraft** on Display name, claim
   the task in game. Expect: Material `minecraft:shield`, **Shield base colour** `RED`, **Shield banner pattern**
   three rows in loom order (stripe top yellow, cross white, border black; row 1 is the bottom layer), the trim fields
   empty.
2. Save the blueprint. Reopen it: the base colour and the three layers in the same order. (`GET /api/ItemBlueprints/{id}`
   shows `shieldBannerBaseColor` and `shieldBannerLayers` in that order.)
3. In game: `/knk itemblueprints give <id> <you>`. Hold the given shield next to the original: same base colour, same
   layers, same order (compare in the loom preview or with F3+H tooltips).
4. Rescan the **given** shield into a new blueprint (step 1 again): the same fields come out; nothing is doubled or
   reordered.

## 2. Shield: edited by hand

1. Edit the blueprint from § 1: move a layer with the arrows, change one colour, add a fourth layer, save, reopen:
   the list is exactly what you left. Give the item: it shows the edited pattern.
2. Remove all layers and clear the base colour, save, give: a plain shield. Reopen: base colour empty, "No pattern
   layers".
3. Hold the plain shield and rescan it into the blueprint from § 1 (which has a pattern): the scan asks whether to
   keep the form's **Shield banner** or take the scan's `(none)`. Choose the scan: the pattern is cleared.

## 3. Armour trim

1. Create a blueprint by scanning the trimmed netherite chestplate: **Armour trim pattern** `minecraft:silence`,
   **Armour trim material** `minecraft:gold`. Save, reopen, give: the given chestplate carries the trim (visible on
   the armour and in the tooltip).
2. Type `wayfinder` / `amethyst` by hand (no `minecraft:` prefix), save: stored as `minecraft:wayfinder` /
   `minecraft:amethyst`; the given item has that trim.
3. Type a pattern with no material and save: the API refuses with "An armour trim needs both a pattern and a
   material"; nothing is saved. Type `paisley` as the pattern: refused, the message lists the known patterns.

## 4. Item instance (lootbox drop and clone)

1. Put the § 1 shield blueprint (max stack size 1, graded) into a lootbox pool, claim a box with it. The dropped
   shield shows the pattern. Web app, Lootboxes, drop log, open the instance: **Shield banner** row
   `RED | stripe_top:YELLOW, cross:WHITE, border:BLACK`. The API's claim result (`pending` or the redeem reply)
   carries `shieldBannerBaseColor`, `shieldBannerLayers`, `armorTrimPattern`, `armorTrimMaterial`.
2. Change the blueprint's pattern in the web app, then make the plugin redeliver the instance (relog with the
   confirmation blocked, or open a second box with a replayed idempotency key): the instance keeps the look it was
   **minted** with, not the blueprint's new one.
3. Hold the dropped shield and `/knk item more 1`: the copy has its own instance id and the same pattern; its
   instance detail shows the same Shield banner row.

## 5. Nothing else changed

1. A sword blueprint (no look) scans, saves and builds as before: no `shieldBanner`/`armorTrim` in the scan, empty
   look fields, no error.
2. Kits and the items catalogue still hand out and preview items; an existing blueprint without a look opens with
   the four fields empty.
3. Kit scan (`KitScan`) of a kit holding the patterned shield creates/finds the blueprint with the pattern.

## Findings

| Date | Tester | knk-web-api | knk-plugin | knk-web-app | Result |
|---|---|---|---|---|---|
| | | | | | |
