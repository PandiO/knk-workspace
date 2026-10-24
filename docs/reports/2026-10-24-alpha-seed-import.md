# Closed alpha: approved seed data set and fresh world — 2026-10-24

**Status:** Done. The alpha runs on the approved seed (`knk-dev-db-seed` `4abf42c`) and a fresh copy of the dev world
**Last updated:** 2026-10-24
**Linear:** none. **To file** (free plan issue limit): "Approved seed data set replaces the placeholder" (hub selection,
gate door 12, skipped gates, world copy from the same moment)
**Runbook:** [closed-alpha deployment runbook](../guides/closed-alpha-deployment-runbook.md) · seed repo:
[PandiO/knk-dev-db-seed](https://github.com/PandiO/knk-dev-db-seed)

The developer ran every command (PC and NAS). Claude Code (cloud session) read the seed repo, test-loaded the seed into a
scratch MySQL 9.6 with API `a38c8ee9` (11 s, 144 tables, 95 migrations, 13 domains, 4 triggers, API healthy, game
settings load, `__pandi__` admitted), and wrote the blocks.

## 1. Sources

| Item | Value |
|---|---|
| Seed | `seed/knk_seed.sql` (`1b5dcbba…`) from `knk-dev-db-seed` `4abf42c`, built from the dev export of 2026-10-24 12:01; migration `20261023144845_AddFieldValidationRunLogs` (95, the same as API `a38c8ee9`, so no migrator run). Only `__pandi__` is kept (coins/gems/XP 0, first-join kits again); invitations, sessions, telemetry, siege history and other runtime tables are empty. `game_settings.HubSettingsJson` → domain 10 (District Royal Palace, `knk_hub`) |
| World | `DEV_SERVER_26.3` with the dev server stopped (`session.lock` free): `world_KNK-DEV` (7.1 GB, the dimensions incl. `knk_hub` inside it) and `plugins/WorldGuard/worlds`, packed with Windows `tar` (`knk-dev-worlds-20261024.tar.gz`, 2.8 GB, `f2530c9a…`). The dev `hub` world (20 MB, not used) was left out |
| Regions | `tools/apply_regions.py` dry run on the copy: **nothing to do** in both worlds; the dev server's region files already had the seed's names (`domain_5/6/13`, `domain_13_sub_1` present; `domain_35`, `domain_19` gone) |

## 2. Switch (2026-10-24 ~22:00 UTC)

1. Snapshot **`20261024T215631Z-pre-seed`** (144 tables, world 3.0 GB, Compose `1070b55c…`): the rollback, with
   `sudo knk-alpha-restore 20261024T215631Z-pre-seed all`.
2. `stop minecraft api`; `DROP`/`CREATE DATABASE knightsandkings_alpha` (utf8mb4, `utf8mb4_0900_ai_ci`), seed loaded as
   root: 144 tables, 95 migrations, 13 domains, users `__pandi__`. The `knk_alpha_app` grants survive the drop.
3. Worlds: old `world_KNK-DEV` and `plugins/WorldGuard/worlds` moved to `seed-20261024/old/`, the new ones in place,
   `session.lock` removed, owner `2001:2001`. **`players/` moved aside** (fresh inventories, matching the seed's zeroed
   economy).
4. KnK plugin state tied to the old database ids moved aside: `discovery-spool`, `game-settings-backups`,
   `hub-outage.json`, `offline-security.json`, `roads`, `siege-vault`, `statistics-spool`. `config.yml` and `logs`
   stay.
5. `start api` (healthy), `start minecraft` (healthy).

Old data is kept in `/srv/docker/stacks/knk-alpha/seed-20261024/` (root 700): the archives, `old/world_KNK-DEV`,
`old/wg-worlds`, `old/knk-state`, `old/players-dev`. Delete it once the first run is past.

## 3. Checks

| Check | Result |
|---|---|
| API | healthy, no fail/crit; `Cloudflare Access sync: 0 added, 4 removed, 1 in the list` (only `__pandi__`'s address; staff keep access through `Allow staff`) |
| Minecraft | `Done (11.855s)`, `admission.mode=invite`, `Applied game settings (… 5 world(s))`, API `UP`, 0 WARN/ERROR |
| Resolver | `warmCache` resolves `domain_13` (Keep Garrison); the two uncached names are gate helper regions without a domain (`gate_closed_2000131`, `gate_2000131_closed`) |
| In game (`__pandi__`) | `/hub` works (Kardenna / Royal Palace); domain messages at The Keep and Gate Keep; the gates incl. door 12 and the Keep Garrison; first-join kits once |
| Web | `/admin/invitations` sync green, 1 on the list |

## 4. Consequences and follow-ups

- Accounts other than `__pandi__` are gone: `admin`, `alpha-probe`, `MrBedue`, the `+t2`/`+t4` test accounts and all
  invites. MrBedue and `__dominic14__` are strangers again (invite + claim code). Recreate `alpha-probe` before the
  next security probe.
- Leftover temp regions from dev world tasks (`tempregion_worldtask_95`, `_96`) are in the copied world; the seed has no
  world tasks. Harmless; remove with `/rg remove` when convenient.
- Go-live checklist C: "a clean baseline dump" is now the `pre-seed` snapshot's successor; take
  `sudo knk-alpha-snapshot seed-baseline` before the first run.
