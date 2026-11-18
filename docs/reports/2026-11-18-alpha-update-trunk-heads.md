# Closed alpha update: trunk heads (API `bcdb4d07`, web `909e708`, plugin `187f97ec`) and the 18 Nov content — 2026-11-18

**Status:** Done, except two web-app steps the developer still has to do (§ 6)
**Last updated:** 2026-11-18
**Procedure:** [NAS ops access § 7](../guides/nas-ops-access.md) (`knk-deploy`); the content patch as in the
[2026-11-01 report § 4](2026-11-01-alpha-update-trunk-heads.md#4-content-patch-from-the-1-nov-seed)

Claude Code (desktop session on the developer PC) ran the deploys and config change through `knk-release.sh` and
`ssh knk-deploy`, each after the developer's go-ahead. The developer ran the SQL on the NAS and drew the lootbox region.

## 1. What changed

| Part | Before | After |
|---|---|---|
| API | `alpha-8df59b75`, 102 migrations | `alpha-bcdb4d07` (knk-web-api `main`), **118** migrations |
| Web | `alpha-1c9524d0` | `alpha-909e7089` (knk-web-app `main` `909e708`) |
| Plugin | `c8232607` (jar `e92afe2f…`) | `187f97ec` (knk-plugin `main`, jar `4324274a…`) |
| Plugin config | `aa15bfbf…` (redacted hash) | trunk `config.yml` with the alpha's values (`be493faa…` uploaded, file hash `7714f139…` → `eeb0833b…`) |
| Compose | `2334937f…` | `7ea502cf…` (API image) → `7404fbf6…` (web image) |
| Data | seed `4abf42c` + patch of 1 Nov | + content patch `alpha-patch-20261118.sql` (`2af6725e…`) from seed `2aeae98` + two location updates |

Migrations applied: `AddWorldTaskHardening` through `SeedStaffKickBanNodes` (16). Startup: the canonical seed filled
the new combat values of chaos, flash_chaos and cleaving ("Enchantments updated: 3"), nothing else created.

## 2. Seed

knk-dev-db-seed `seed/dev-export-2026-11-18` `2aeae98`, fast-forwarded to `main`. Built from a mysqldump of the dev
database (123 migrations; trunk has 118), joined into phpMyAdmin's layout by the new `tools/mysqldump_to_pma.py`.
5300 rows / 87 tables; `check_seed.py` against `main` finds one item, a `nodeId: 0` placeholder in a rejected road
proposal's JSON. **Not test-loaded**: Docker Desktop did not start. The workbook has a new Locations sheet (loose named
points were dropped before). Developer decisions: location 2's rename and move on dev is intended; the new MrBedue
(Id 20) is kept, the erased accounts 11–19 and `__dominic14__` are not. The Town form's step names
"General informationn" / "Region and accesss" (test edits on dev) were corrected in the export.

## 3. Plugin config

Base: trunk `config.yml`, so the 103 keys new since `c8232607` come with their comments. Kept from the alpha: API URL
and key (token), region-http bind address, web URL, invite mode, `worlds.load`, back-teleport price 100, the four
`navigation.builder` values, `command-visibility.always-show: [spark]` (the alpha's file had `command-visibility`
twice; now once). Developer decision: **`realtime.enabled: true`, `server-id: "knk-alpha"`**; metrics and NPC
navigation stay off (no scraper; no Citizens on the alpha). Left out: the ~30 dev keys that exist only on `next`, and
the alpha's `teleport.back.expire-seconds-by-kind.warps` (no longer in the jar). Backup on the NAS:
`/var/lib/knk-deploy/backups/20261118T175338Z-config-knk`.

## 4. Content patch

Built from the dev exports of 1 and 18 Nov and the alpha dump of 1 Nov. The alpha had dev's ids and values for every
table touched except `item_blueprints` (dev 153/154 = alpha 135/136, found by name). Snapshot
**`20261118T181553Z-pre-content-patch-20261118`**.

| Change | Result |
|---|---|
| Locations 52–57 (new named points) | inserted |
| Locations 2 (Residential District spawn, renamed and moved) and 13 (South Gate spawn) | skipped by the patch (see below), then updated by hand: 1 row each |
| Cinixian Shield / Raider Shield: banner base colour and 10 banner layers | done |
| Lootbox area Throneroom-attic, Weapons Lootbox | **Id 3**, region `lootbox_area_3` (drawn in game by the developer) |
| Street 6 Old Road; Residential District off Wearway and Kardenna end | done |
| Road graph of tiles 3 and 6 (−9/+10 edges, −3/+4 nodes, 16 updates) | done; plugin loads 85 nodes, 54 edges from 4 tiles in `world_KNK-DEV`, as dev |
| Grants: Default `knk.chat.token.*`; Staff `knk.chat.tokens.bypass`, `knk.kick`, `knk.ban` | already there (migrations) |
| FormFields 110/167 world-task settings; Town form step condition "Allow entry" | done |

Left alone: accounts and player data, game settings (weather), gate door states, map outlines (`next` only),
arenas and pass-through styles (feature branches), enchantment combat values (the API's startup sets them).

**Two generator bugs, fixed in `make_alpha_patch.py`** (local, in the seed worktree's `build/`):
1. The dry run selected its results after `ROLLBACK`; `_patch_skipped` is an InnoDB temporary table, so the list was
   always empty. Its only lasting trace: the rolled-back insert used up area Id 2. The results now come before
   `COMMIT`/`ROLLBACK`. The 1 Nov dry run had the same layout, so its "nothing skipped" was not proof either.
2. `locations.Yaw` and `Pitch` are single-precision `FLOAT`; `<=>` against a double literal never matches, so the
   guards for locations 2 and 13 failed although the alpha still had the 1 Nov values. Float columns are now compared
   within 0.001.

After the patch: `restart api` (healthy, canonical seed 0 updates), `restart minecraft` (healthy, realtime connected).

## 5. Checks

| Check | Result |
|---|---|
| `api-health` | 200 / 200 |
| `log-errors` | API and MySQL: 0 error, critical, exception lines |
| `secret-scan` | clean |
| `compose` | `7404fbf6…`, `matches_recorded: true`, Portainer copy identical |
| Minecraft log | `KnightsAndKings 0.1.0+187f97ec` enabled, invite mode, 0 startup errors; realtime connected as `knk-alpha` (API: "5 presence rows corrected" on first connect); the known Keep Stair House sheared-reference warning |

Not checked: in game (shields' banners, new locations, `/navigate` on the new road, lootbox spawns in the attic, web
kick/ban) and in the browser.

## 6. Open

1. **Developer, alpha web app:** delete form "ItemBlueprint - Default (seed v1)" (Id 27), import the bundled
   `ItemBlueprint.json` as default (the import refuses while 27 exists: same GUID), import the bundled
   `EnchantmentDefinition.json` (seed v5) as default.
2. **Developer:** export "Town Display" on dev, import it on the alpha.
3. World builds made on dev since the 24 Oct world copy (e.g. the outpost at location 54) are not in the alpha world.
4. Still open from 1 Nov: the live-ids floors in the seed ledger.

## Rollback

`ssh knk-deploy rollback` undoes the last change (the config), again for the plugin jar, the web image and the API
image. Database: `sudo knk-alpha-restore 20261118T181553Z-pre-content-patch-20261118 db` (before the patch) or
`20261118T173255Z-pre-api-bcdb4d07` (before the migrations).
