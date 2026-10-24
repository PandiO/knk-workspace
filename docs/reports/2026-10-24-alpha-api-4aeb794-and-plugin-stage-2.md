# Alpha API update to `4aeb794` and Minecraft Stage 2 (KnK plugin) — 2026-10-23/24

**Status:** Complete. NAS API `knk-web-api:alpha-4aeb7947` (93 migrations); `knk-alpha-minecraft` runs the KnK jar from knk-plugin `main` `d56e41da`. `/hub` waits for a hub selection in the seed
**Last updated:** 2026-10-24
**Linear:**
- [KNG-275](https://linear.app/kngpandi/issue/KNG-275) (API update);
- [KNG-225](https://linear.app/kngpandi/issue/KNG-225) (Minecraft container, Stage 2);
- found in passing: [KNG-264](https://linear.app/kngpandi/issue/KNG-264); one more is "To file" (§ 7).

**Runbook:** [closed-alpha deployment runbook](../guides/closed-alpha-deployment-runbook.md) Phase 3b (procedure) and Phase 4 ·
[alpha go-live](../guides/alpha-go-live.md) § 4–5
**Previous reports:**
- [2026-10-22 Phase 3b](2026-10-22-alpha-api-kng64-upgrade.md);
- [2026-10-21 Minecraft Stage 1](2026-10-21-minecraft-container.md).

The developer ran every NAS command in an SSH session and the `knk-ops` checks from the PC. Claude Code (cloud session)
wrote and checked each block and rehearsed the API update in a scratch Docker host first. No secret values were printed
or recorded. The database is still the **placeholder** copy of dev.

## 1. Decision (developer, 2026-10-24)

Stage 2 was first prepared with plugin `main` `69c93885` against API `be9f4e1a`. The developer then asked to deploy the
**latest trunks**, because important features had been merged:
- knk-web-api `master` `4aeb79472d79…` (KNG-205 invitations, email outbox and admission; KNG-200/250 catalogue; KNG-253
  sub-regions; KNG-234 compass; KNG-268/270/273 gates);
- knk-plugin `main` `d56e41da6033…` (KNG-205 admission gate at pre-login; KNG-253; KNG-234; KNG-266/262/230/231; gate
  fixes).

The plugin's admission gate needs the new API, so the API was updated first as a routine update (KNG-275). The
procedure was the runbook Phase 3b steps.

## 2. Findings before the update

| Item | Result |
|---|---|
| Migrations | 11 new, 82 → 93: `LinkCodePurpose`, `MinecraftCatalogEntryFields`, `AddEmailOutbox`, `AddInvitations`, `SeedInvitationStaffNode`, `SeedAlphaTesterGroup`, `AddNavigationCompassSettings`, `AddSiegeNavigationItem`, `MinecraftCatalogConstraints`, `MinecraftEnchantmentCatalogFields`, `DomainSubRegions` |
| `MinecraftCatalogConstraints` | Refuses (SIGNAL 45000) while block refs are unlinked, unkeyed or duplicated. The alpha DB had 0 `minecraftblockrefs` rows, so it passed |
| **Email transport** | Since KNG-206 the API **refuses to start outside Development with the Log transport** unless `Email__AllowLogTransport=true`. The Phase 3b setting `Email__Provider=Log` would have stopped the new API. New: `Email__Transport=Log` + `Email__AllowLogTransport=true`, the alpha's opt-in until the KNG-211 relay (KNG-205 design § 4.2). Reset and invite mails then go to the API log, bodies included |
| New settings | `App__PublicBaseUrl=https://app.knightsandkings.net` (invitation, reset and admission links). `Security:Registration:Mode` stays at the default `LinkCode`, and `admission.mode` stays at the default `whitelist`; the switch to invite-only is KNG-218 |
| Plugin `config.yml` | New keys since the KNG-182 branch: `metrics:` (KNG-232, off), gate visuals, `admission:`, `regions.temp-retention`. The live file doesn't have them, so the code defaults apply |
| Plugin API calls | `d56e41da` and `4aeb794` were merged together (KNG-205) |

## 3. Rehearsal (scratch Docker host, 2026-10-24)

The upgrade path was rehearsed on MySQL 9.6.0 (same digest):
1. A fresh database was migrated to 82 with the `be9f4e1a` migrator, then the `be9f4e1a` API started once.
2. The `4aeb7947` migrator applied 11 migrations, giving 93 migrations, 143 tables and the `Alpha Tester` group.
3. With the old email settings the API stopped (`Refusing to start: the mail transport is Log…`).
4. With the new settings it was healthy:
   - 68 log lines, only the four known warnings;
   - Host `evil.example` → 400;
   - anonymous `/api/users`, `/api/Invitations`, `/api/MinecraftCatalog/audit` → 401;
   - idempotent restart; no secret values in the logs.

## 4. API update on the NAS (KNG-275)

| Item | Value |
|---|---|
| Archive | `deployment-sources/knk-web-api/4aeb7947/knk-web-api-4aeb7947.tar.gz`, SHA-256 `091de43e947aa26f162a286bec85728a2a396c553631e0848ceeb28048c62903` (same on PC and NAS) |
| Build context | `/srv/docker/build/knk-web-api/4aeb7947/`; build files unchanged from Phase 3b (`Dockerfile` `80e9caeb…`, `migrator-entrypoint.sh` `eddc16ad…`, `appsettings.Production.json` `eb2cf586…`, `docker-entrypoint.sh` `e872df91…`); logs `build-20261024T103025Z-{runtime,migrator}.log` (`3b0dc63e…`, `0980546c…`) |
| Runtime image | `knk-web-api:alpha-4aeb7947`, `sha256:a6fd60334c337955a20c93c370ac1702c815b003a884233825d42b42784e37fb`, 269,712,464 bytes, `2002:2002` |
| Migrator image | `knk-web-api-migrator:alpha-4aeb7947`, `sha256:bf546334076d0d3f5f09b832776152657dd7c7918466e44ff5e44d6362d39ce2`, 1,632,575,657 bytes |
| Compose | `2af121b6…` → **`e11281e88e1d19c31ca85052227ca962d4194986930425fb156fdf3e646d3cae`** (canonical `4d4cc3dd…`), Portainer stack 42 identical. Diff: the image line, and `Email__Provider` replaced by `Email__Transport`, `Email__AllowLogTransport`, `App__PublicBaseUrl` (block `scripts/alpha-api/compose.api-service.yaml` `b7ccaadc…`). Backups in `backups/20261024T104751Z/` |
| Pre-migrate dump | `alpha-db-pre-4aeb7947/20261024T104751Z/knightsandkings_alpha-pre-migrate.sql.gz` `dc448b815110b82eb7cc7dc7975faca139c335e73e8ec2f3fda2dac4afdbf162` (137 tables, API stopped). **Rollback source** |
| Migration | rc 0, exactly the 11 migrations, `Done.`, no fail/exception lines; log `backups/20261024T104751Z/migrate-4aeb7947.log` |
| Clean baseline | `alpha-db-clean/20261024T…Z-4aeb7947/knightsandkings_alpha-clean.sql.gz` `ba6f6c099f93627fc60ca5ea2198396f9210eb0b0aaf86df90ca3e9013e8b7b3` (143 tables, 93 migrations) |
| `knk-ops compose` wrapper | records `e11281e8…`; installed hash `63c6bbca…` = `scripts/nas-ops/stage-a/SHA256SUMS` |

Acceptance:
- first start healthy after ~15 s, 68 log lines, only the four known warnings; restart healthy after 7 s, every seeder
  at 0 creates;
- `containers`: `alpha-4aeb7947` / `a6fd6033…`, `2002:2002`, no ports, backend only;
- `api-health` 200/200;
- `db-summary`: 143 tables, 4 triggers, 93 migrations (latest `20261023054051_DomainSubRegions`), 9 users / 2 active,
  0 clashes, 9 permission groups (incl. Alpha Tester), invitations / email outbox / sub-regions empty;
- `secret-scan` clean; `log-errors` 0/0/0;
- `compose` `matches_recorded: true`, `files_identical: true`;
- `secret-files` unchanged from Phase 3b.

The developer restarted the whole stack at about 10:47Z, before this update. That is why MySQL and Minecraft show that
start time.

## 5. Minecraft Stage 2 (KNG-225)

| Item | Value |
|---|---|
| Jar | knk-plugin `d56e41da6033e787414c401655576a20108e0b58`, `.\gradlew.bat :knk-paper:shadowJar` in a clean worktree on the developer PC (JDK 25; 41 deprecation warnings, rc 0), SHA-256 `7bc85e7d734592e0e6324b867c47371d54ee9c0dfb42db15f76ebbbd2ca5794e` |
| Release folder | `/srv/docker/stacks/knk-alpha/releases/plugin/d56e41da/` (root, 700): `KnightsAndKings.jar`, `SOURCE.txt` (`55816c5d…`), `SHA256SUMS` |
| Live jar | `minecraft-data/plugins/KnightsAndKings.jar`, `2001:2001 644`. The plugin folders were 777 (from the copy) and are now 755 / files 644 |
| Backups before the jar | DB: the baseline above. World: `alpha-pre-plugin/20261024T…Z/minecraft-data.tar` `76334ba03e73859fd99f5f5b41e922cda25b5862657a9a83d387cb4bde15a0bc`, 7,722,414,080 bytes (taken with `save-off`, then `save-all flush`, then `save-on`) |
| Whitelist | `MrBedue`, `__pandi__`, `__dominic14__` (from the 2026-10-22 load check) |

### Startup and checks

| Check | Result |
|---|---|
| Startup | `Done (12.256s)`; KnightsAndKings v0.1.0 enabled, `Configuration loaded successfully`, metrics off; 0 ERROR/SEVERE |
| Worlds | `[KnK Worlds] knk_hub: loaded (normal)` |
| API | `http://api:5000/api`, API-key authentication; `API connectivity UNKNOWN -> UP (healthy)`; `rcon-cli knk health`: UP; the API logged no 401/403 for the plugin |
| Region callbacks | `RegionHttpServer listening on 0:0:0:0:0:0:0:0:8081 (X-API-Key required)`; from the API container, `http://minecraft:8081/` without a key → **401**, so the path works and the key is enforced |
| Admission | `[KnK Admission] admission.mode=whitelist` |
| Regions | Managed-region repair checked 11, changed 0. Domain world backfill (KNG-111): 11 domains given a world. Region access sync: 11 regions updated, 13 cleared. That's the first write into the copied worlds; the tar above is the rollback |
| Warnings | One KnK WARN: gate door "Keep Stair House" (ID 12) has **sheared reference points** (the KNG-132 loader check) in the dev data. Gate startup sync: 5 gates skipped (the log line was cut off, so the reason isn't confirmed). `[KnK Offline]` deleted the cached data of 2 accounts that are tombstoned in the alpha DB |
| `plugins/update/` swap (runbook § 4.3) | The same jar was copied to `plugins/update/KnightsAndKings.jar`, then `save-all flush` and `docker restart -t 120`. Healthy after ~35 s; live jar inode 15344835 → 15344825, mtime 11:00:26Z, update folder empty, hash unchanged; `Done (11.865s)`, 0 ERROR/SEVERE. **Paper swaps the jar on start.** Because of KNG-264 the version is always `0.1.0`, so a swap is confirmed by hash, not by the log |
| Load | `tps`: 20.0 / 20.0 / 20.0 |
| In game (developer, 2026-10-24) | `__pandi__` joined at the last position, as expected for an Admin; `/knk health` showed the API UP; domain enter messages work; main-world builds intact; hub build intact (reached with `/execute in minecraft:knk_hub run tp …` in spectator); after `docker restart` the position was kept |
| `/hub` | **"The hub isn't available right now."** The placeholder DB has no hub selected: `game_settings.HubSettingsJson` is NULL and no domain has `IsHub = 1`, because the dev copy predates `AddHubSettings`. Not a deployment fault; it waits for the seed (§ 7). Joining players aren't placed in the hub either, for the same reason |

Not tested:
- a new, unlinked player creating an alpha account (optional);
- a NAS reboot with the jar (Stage 1 showed `systemctl restart docker` brings the stack back).

## 6. Runbook Phase 4 acceptance

| Item | State |
|---|---|
| Stable tick rate, both worlds loaded | yes (TPS 20, `knk_hub` loaded) |
| Hub and main builds intact | yes |
| Plugin reaches only the alpha API and DB | yes (`api:5000`, API-key auth, no 401/403) |
| `__pandi__` joins as the retained account | yes |
| Unknown player creates/links an alpha account | not tested |
| Restart keeps worlds and account state | yes |
| Memory/CPU next to Frigate | Stage 1 load check (2026-10-22) |
| `rcon-cli` from Portainer and over SSH; no published port | yes (Stage 1); `rcon-cli` used throughout |
| Autostart after a NAS/Docker restart | yes (Stage 1) |
| One `plugins/update/` swap | yes (§ 5) |
| `/hub` and hub admission | waits for a hub selection in the seed |

## 7. Open

- **To file in Linear** (creating an issue was refused on 2026-10-24: the workspace has reached the free plan's issue
  limit): "Closed alpha: approved seed data set replaces the placeholder `knightsandkings_alpha` (cleaned DB + matching
  world copy, hub selected)". It needs:
  - a hub selection (`HubSettingsJson`, an `IsHub` domain);
  - gate door 12 fixed;
  - a check of the 5 skipped gates;
  - the procedure: empty DB → migrator → seed import → first start → baseline, with the world copy taken at the same
    moment.

  The text is also on KNG-225.
- [KNG-264](https://linear.app/kngpandi/issue/KNG-264): stamp the plugin version with the commit.
- [KNG-228](https://linear.app/kngpandi/issue/KNG-228): `knk-ops` doesn't cover `knk-alpha-minecraft` yet.
- [KNG-242](https://linear.app/kngpandi/issue/KNG-242): MySQL accounts / `root@%`.
- Reset and invite mails go to the API log until KNG-211 (mail relay). `secret-scan` doesn't treat a reset link as a
  secret.
- Next: Phase 5 (playit.gg) and Phase 6 (web app, ingress), KNG-218 (switch to invite-only).
