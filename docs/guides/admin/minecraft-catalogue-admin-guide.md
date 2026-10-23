# Minecraft Catalogue — Admin Guide

**Status:** Living document — update in place as the code changes
**Last updated:** 2026-10-23 (KNG-250 merged: knk-web-api `master` `a1f8838`, knk-web-app `main` `f9ee73c`, knk-plugin `main` `c7806b87`; KNG-200 merged 2026-10-22)
**Companion docs:** `docs/specs/minecraft-catalog/IMPLEMENTATION_PLAN.md` (design, decisions D1-D12, contract)

The Minecraft catalogue is the list of materials (items and blocks) and enchantments the web app offers in its pickers, for
example the icon of an item blueprint, a category, a gate or a lootbox type. Since KNG-200 the running
Minecraft server is the source: a scan reads its registry, and the database holds the result. There is no
built-in list any more, so a new database stays empty until its first scan.

## Scanning the server

1. Start the Minecraft server with knk-plugin. The plugin needs the API key the API expects
   (`api.auth.api-key` = `Security:PluginApiKey`).
2. In the web app, open **Admin → Minecraft catalogue** (`/admin/minecraft-catalog`; needs
   `knk.admin.content`) and click **Scan server**.
3. The plugin picks the scan up within about a minute. It is a headless WorldTask, `MinecraftCatalogScan`.
   The page refreshes the status every 3 seconds until the scan is Completed or Failed.

Scan again after every Minecraft upgrade. A scan:

- adds new keys and updates existing ones, which keep their id, so blueprints, menus, gates and lootboxes
  stay linked;
- merges rows that only differ in notation (`STONE`, `oak_planks` → `minecraft:…`), repointing everything
  that referenced them;
- deletes rows the server doesn't know and nothing references;
- marks rows the server doesn't know but something still references as **Missing**. Pickers hide them; the
  page lists them under "Needs attention".

Only one scan runs at a time. A scan without an answer from the server times out after 15 minutes, and
**Cancel** stops one earlier. A scan the plugin couldn't send shows the server's error.

## Icons

During a scan the API looks up a picture for every entry:

1. **PrismarineJS minecraft-assets**, at the server's version or the nearest lower one it has (in October
   2026 it goes up to 26.1).
2. **InventivetalentDev minecraft-assets** for keys Prismarine lacks, at the server's exact version.

Entries without a picture are listed under **Missing icons**, where you can set your own URL. That
**override** is never replaced by a scan; **Icon overrides** lists the ones set, where you can change or
clear them. Block items use a flat face texture (stairs show planks), not an inventory render.

Configuration (optional, defaults in code): section `MinecraftCatalog:Icons` in the API settings, with
`Enabled`, `PrismarineBaseUrl`, `PrismarineVersions`, `InventivetalentBaseUrl`, `InventivetalentFallback`,
`MaxConcurrentChecks` and `TimeoutSeconds`.

## Pickers

- The material picker in forms (field type `HybridMinecraftMaterialRefPicker`, component
  `MinecraftMaterialPicker`) shows **items** by default.
- The field's settings JSON can change that:

  | `categoryFilter` | Shows |
  |---|---|
  | `"BLOCK"` | blocks |
  | `"ANY"` | everything |
  | `"BANNER"` | banners |

- It searches name and key, sorts by name and shows the icon.
- The admin table of materials (`/dashboard` → MinecraftMaterialRef) shows every row, Missing ones
  included, with Kind and Status columns.

## Audit and merging

**Needs attention** on the catalogue page reads `GET api/MinecraftCatalog/audit`:

- keys that collide after normalisation, with **Merge into…** per row;
- invalid keys;
- Missing rows that are still referenced, with what references them;
- duplicate or unlinked block refs;
- materials without an icon.

A merge points every reference at the target and then deletes the source. **Run backfill** repeats the
startup backfill (normalising keys, filling names, linking block refs); it is safe to run twice.

## Enchantments

The same scan also reads the enchantments (KNG-250):

- **Vanilla** (and data-pack) enchantments come from the server's registry.
- **Custom** knk-plugin enchantments come from its EnchantmentRegistry, under the key `knk:<id>` (for
  example `knk:flash_chaos`).

The clean-up rules are the same as for materials:

- Old rows in another notation are merged. A custom key saved without namespace, such as `chaos`, goes
  into `knk:chaos`.
- Unknown rows nothing uses are deleted.
- Rows an enchantment definition still uses become **Missing**. They show under "Missing enchantments
  still used".

The scan also makes sure every enchantment has an **enchantment definition**, so the pickers of item
blueprints and lootbox enchant rolls offer every vanilla and custom enchantment. It links an existing
definition where one matches and creates one otherwise. It never deletes or renames a definition. One
exception: a vanilla definition that still has the level of its catalogue entry (as the seeds leave it)
takes the server's maximum level.

The enchantment picker in forms (field type `HybridMinecraftEnchantmentRefPicker`) shows vanilla and
custom together:

- Custom ones carry a badge.
- **All / Vanilla / Custom** narrows the list.
- `"originFilter": "custom"` (or `"vanilla"`) in the field's settings JSON sets the starting filter.
- Picking never creates anything any more.

Enchantments show the enchanted book icon. An icon URL set by hand on an enchantment is kept.

## Upgrading another environment

The two KNG-200 migrations are `MinecraftCatalogEntryFields` and `MinecraftCatalogConstraints`. The second
one only applies on clean data, and stops with "KNG-200: block refs not clean…" otherwise:

1. Run `dotnet ef database update`. The first migration applies; the second may refuse.
2. Start the API once. The backfill runs at startup.
3. Open the catalogue page and resolve anything under "Needs attention".
4. Run `dotnet ef database update` again.
5. Scan the server.

KNG-250 adds the migration `MinecraftEnchantmentCatalogFields` (columns only; existing enchantments
become Unverified until the first scan). Deploy the API and the plugin together and scan. An older
plugin's scan is still accepted but leaves enchantments alone.

## Not covered yet

- Block refs (specific block states) have no picker of their own:
  [KNG-251](https://linear.app/kngpandi/issue/KNG-251).
