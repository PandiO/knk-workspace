# Closed alpha update: trunk heads (API `8df59b75`, web `b3b415d0`, plugin `c8232607`) — 2026-11-01

**Status:** Done. The alpha runs knk-web-api `master` `8df59b75`, knk-web-app `main` `b3b415d0` and knk-plugin `main`
`c8232607`. The content patch from the 1 Nov seed is still to come (§ 4)
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

## 4. Follow-ups

- **Content patch** from the 1 Nov seed (`knk-dev-db-seed` `seed/dev-export-2026-11-01` `4cc1263`): it needs a dump of
  `knightsandkings_alpha` taken now, because the alpha's own rows were never moved above the ledger's live range and
  `knk-deploy` can't read the database. The arena data and gate pass-through styles in that seed wait until
  `claude/arena-duels` and `claude/alpha-run-1-gates` are on trunk and deployed.
- `knk-release.sh` called `gradlew.bat` without `.\`; with `NoDefaultCurrentDirectoryInExePath` set (Claude Code sets it)
  cmd.exe refused it. Fixed in the same commit as this report.
