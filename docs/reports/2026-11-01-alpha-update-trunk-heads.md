# Closed alpha update: trunk heads (API `8df59b75`, web `b3b415d0`, plugin `c8232607`) — 2026-11-01

**Status:** Done. The alpha runs knk-web-api `master` `8df59b75`, knk-web-app `main` `b3b415d0` and knk-plugin `main`
`c8232607`, and has the 1 Nov seed's content changes (§ 4)
**Last updated:** 2026-11-01
**Linear:** none (free plan issue limit)
**Procedure:** [NAS ops access § 7](../guides/nas-ops-access.md) (`knk-deploy`, Stage B), the first update done through it

Claude Code (desktop session on the developer PC) ran every step through `scripts/nas-ops/stage-b/pc/knk-release.sh` and
`ssh knk-deploy`, after the developer's go-ahead for this deploy.

## 1. What changed

| Part | Before | After | Brings |
|---|---|---|---|
| API | `alpha-6f08383d` | `alpha-8df59b75` | alpha run 1 packages B (enchantment combat values, freeze), C (permissions and domains), F with E (siege results and rewards), I (teleport, kits, items); form wizard edit mode (#186) |
| Web | `alpha-0d612702` | `alpha-b3b415d0` | dashboard hub, header and explorer, claim-code fields, route gates, styling quick wins, siege result pages and reward fields, form wizard edit mode and leave guard |
| Plugin | `ee35fb1d` (jar `103586e8…`) | `c8232607` (jar `e92afe2f…`) | alpha run 1 packages A (siege match), B, C, console and navigation, F, G (effects), I; custom enchantments use rank permissions (#193) |

Migrations: 97 → **102** (`AddEnchantmentCombatValues`, `SeedCommandPermissionNodes`,
`AddSiegeGateDamageAndParticipationRewards`, `AddSiegePostMatchSeconds`, `SeedTeleportAllAndItemMoreNodes`). API source
archive `835cdcd3…`, web `55cba772…`.

## 2. Steps

| Time (UTC) | Command | Result |
|---|---|---|
| 15:35 | `deploy-api 8df59b75…` | snapshot `20261101T153532Z-pre-api-8df59b75`, migrator ran the 5 migrations, API healthy; startup seeders: enchantments updated 12, abilities updated 5, nothing created |
| ~15:40 | `deploy-web b3b415d0…` | healthy |
| 15:45 | `deploy-plugin c8232607…` | snapshot `20261101T154518Z-pre-plugin-c8232607`, jar backup `/var/lib/knk-deploy/backups/20261101T154535Z-plugin-c8232607`, Minecraft restarted, 0 errors in the startup log |

Plugin config: none of the new `config.yml` keys (`join-refusal-notify`, `siege.rejoin-window-seconds`, `menus.menu-item`,
`crossplay.block-resync`, `gates.siege.defender-pass-through*`, `custom-enchantments.tuning-refresh-minutes`,
`regions.effect-damage`) are in the alpha's `config.yml`; they take the jar's defaults, so the menu item, block resync,
defender pass-through and effect-damage rules are **on**. Not changed.

## 3. Checks

| Check | Result |
|---|---|
| `status` | all services running; API, web, Minecraft, MySQL, mail relay, cfproxy healthy; 102 migrations |
| `api-health` / `log-errors` | 200/200; 0 error, critical or exception lines (API warnings are the usual startup ones) |
| `secret-scan` | clean |
| `compose` | `97bfb08e…`, `matches_recorded: true`, Portainer copy identical |
| Minecraft log | `Enabling KnightsAndKings`, `admission.mode=invite`, `Done (2.4s)`; one warning that gate door 2 (Keep Stair House) has sheared reference points, which is its stored data, not this deploy |

Not checked: in game and in the browser.

**Rollback:** `ssh knk-deploy rollback` undoes the last change (the plugin jar), then again for the web and API images.
The 5 migrations stay in the database; to undo them, `sudo knk-alpha-restore 20261101T153532Z-pre-api-8df59b75`.

## 4. Content patch from the 1 Nov seed

Seed `knk-dev-db-seed` `seed/dev-export-2026-11-01` `4cc1263`. `make_patch.py` couldn't be used: it matches rows by id
and assumes the alpha's own rows sit above 1,000,000, but the ledger floors were never recorded and the alpha has its
own low-id rows (startup seeders, play). Instead: the developer dumped `knightsandkings_alpha` after the deploy
(15:54 UTC, `9f444a63…`, 144 tables), and Claude Code compared it column by column with the new seed and with seed
`4abf42c` (what the alpha was loaded from) to tell dev changes from the alpha's own.

| Change | Rows |
|---|---|
| EnchantmentDefinition form v2 (`a4975cf7…`, "Combat values" step, #151) becomes the default; v1 (Id 25) `IsDefault` 0 | form 43, steps 114–115, fields 354–365, display condition groups and conditions 31–32 |
| Blindness (`EnchantmentDefinitions` 7) `ProcChancePercent` 20 → 10, a dev setting (trunk default 20) | 1 |
| Default rank (holder 5) `customenchantments.use.*`: everyone may use the SUPPORT enchantments (#193; the permission scan's F6 decision, made on dev) | 1 grant |

Left alone: the alpha's own values (world weather CLEAR, gate door state and health, game settings timestamps and
runtime worlds), accounts and player data, the 20 other new grants (the migrations brought them, one id further on
than dev), and the arena menus, Arena discovery rule and gate pass-through styles (not on trunk; their tables and
columns aren't on the alpha).

The patch (`alpha-patch-20261101.sql` `7799dd03…`, 23 guarded statements, one transaction, migration check) and a
rollback-only dry run (`3a4692e6…`) were checked offline against the dump's foreign and unique keys; Docker Desktop
didn't start, so there was no test load. The developer took snapshot **`20261101T160706Z-pre-content-patch`**, ran the
dry run (all 8 checks as expected, nothing skipped) and the patch (nothing skipped). Then `restart api` (healthy;
canonical seed updated 0 enchantments, so the 10 % stays) and `restart minecraft` (KnightsAndKings enabled, invite
mode, no errors). Row counts after: FormConfigurations 43, FormSteps 115, FormFields 365, DisplayConditionGroups and
DisplayConditions 32, permission_grants 126, users 7; logs clean, secret scan clean.

Rollback: `sudo knk-alpha-restore 20261101T160706Z-pre-content-patch db` (or delete the rows above by id).

## 5. Follow-ups

- Run the seed repo's one-time live-ids step on the alpha (`tools/ledger.py live-sql`, API stopped) and record the
  floors in the ledger, so the next patch can come from `make_patch.py` instead of a dump comparison.
- Arena data and gate pass-through styles: a second patch once `claude/arena-duels` and `claude/alpha-run-1-gates` are
  on trunk and deployed.
- Not checked in game: the v2 form in the web app, a non-staff player using a SUPPORT enchantment, Blindness at 10 %.
- `knk-release.sh` called `gradlew.bat` without `.\`; with `NoDefaultCurrentDirectoryInExePath` set (Claude Code sets it)
  cmd.exe refused it. Fixed in the same commit as this report.
