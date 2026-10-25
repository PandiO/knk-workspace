# Closed alpha update: API `6f08383d` (examples off) and plugin `ee35fb1d` — 2026-10-25

**Status:** Done. The alpha runs knk-web-api `master` `6f08383d`, knk-web-app `main` `0d612702` (unchanged) and
knk-plugin `main` `ee35fb1d`; the seeders' example rows are gone and stay gone
**Last updated:** 2026-10-25
**Linear:** none (free plan issue limit). **To file:** this deploy, with the `Seeding:IncludeExamples` work
**Procedure:** [alpha go-live § 3 and § 4.2](../guides/alpha-go-live.md), `scripts/alpha-api/README.md`; plugin as in
[Stage 2](2026-10-24-alpha-api-4aeb794-and-plugin-stage-2.md) § 5

The developer ran every command; Claude Code (cloud session) wrote the blocks and rebuilt both source archives from
the same commits to check their hashes.

## 1. Builds

| Item | Value |
|---|---|
| API source | knk-web-api `6f08383d37cbfef950c9696777d00f9d3091a202` (merge of `claude/seeding-include-examples`), archive `cea0254c06db153c51f32e94634528ad9e262de688aa231807f3f7f8cefd18e7` (identical when rebuilt independently), 97 migrations = the database's, **no migrator run** |
| API image | `knk-web-api:alpha-6f08383d` `sha256:e5a73274b57e…`, `2002:2002`, rev `6f08383d`; build files copied unchanged from `/srv/docker/build/knk-web-api/fa28f7ea/` |
| Workspace files | `alpha-6f08383d-files.tar` `71df0a49…` (= `50508ac`): `scripts/maintenance/remove-seeded-examples.sql` `15a96f36…`, `scripts/alpha-api/compose.api-service.yaml` `e9162008…` |
| Plugin | knk-plugin `ee35fb1d5be8ee914322a0fe01edcb53351832ed`, `.\gradlew.bat :knk-paper:shadowJar` in a clean worktree on the developer PC, `KnightsAndKings.jar` `103586e8d50b3f92ccef892154e1e5925d02b6bf26e074e394f8dddb04467799`; release folder `releases/plugin/ee35fb1d/` (`SOURCE.txt`, `SHA256SUMS`) |

The plugin catches up 17 commits since `d56e41da`: delayed menu switches for Bedrock (Floodgate) players
(`menus.bedrock-transition-delay-ticks: 3`), siege playtest follow-ups (Fire Aspect on gates, Cleaving), menu startup
validation retries, WorldGuard's global region protected (`global.protection: true`: outside every region a default
player can't build, use crafting blocks or touch decorations), invincible gates refuse ignition. The live
`config.yml` has none of the new keys, so the defaults above apply.

## 2. Steps and results

| Step | Result |
|---|---|
| Snapshot | `knk-alpha-snapshot pre-6f08383d` (Compose `73c6cd9a…` before) |
| Compose | `image` `alpha-fa28f7ea` → `alpha-6f08383d` and `Seeding__IncludeExamples: "false"` after `Security__Registration__Mode`; `73c6cd9a…` → **`41f7b64aabb1b3aa1fa145ea7b61d503e3e9ca27b92d9a64b764a0170173db16`**, Portainer stack 42 identical, `knk-ops compose` updated |
| API | healthy; env `Seeding__IncludeExamples=false`; log `ItemBlueprint example catalog seed skipped`, `SiegeLobby seed skipped`; no fail/crit |
| Cleanup (`remove-seeded-examples.sql`, MySQL 9.6, as root) | 9 `example.*` menus, the `example` siege lobby and the 18 trade-good blueprints deleted with their own rows; tag `Test` **kept** (`KEEP: item blueprint mighty mace` — a real seed blueprint uses it) |
| Counts | menus 18, item blueprints **149**, siege lobbies 1, tags 8; unchanged after an API restart |
| Plugin | backup `backups/20261025T140211Z/KnightsAndKings-before.jar`; `plugins/update/` swap, `save-all flush`, restart: `Enabling KnightsAndKings`, `admission.mode=invite`, API `UP`, Geyser `Done`, `Done (15.813s)`, 0 ERROR/SEVERE after the start |

**Slip, recorded so it isn't repeated:** the first run of the cleanup came before the new Compose file was installed
(S-3's second half hadn't run), and `docker compose restart api` restarted the *old* container, which seeded the
examples again (27 / 165 / 2 / 8). After installing the Compose file (`up -d --no-deps api`) the cleanup was run a
second time and held. `restart` never picks up a Compose change; `up -d` does. Two command blocks also used
`sha256sum -c … || exit` with an unfilled placeholder, which closed the SSH session (nothing had changed yet); the
blocks now use `if … then … else echo STOP; fi`.

The 149 blueprints are the seed's 140 plus the real items the newer seeders add (enchantment books incl. Cleaving
and others); the cleanup found no other examples.

Plugin log lines between 15:00:35 and 15:01:20 (`Failed to connect to api`, `UnknownHostException`, road/telemetry
warnings) fall on the API restart of the cleanup check and are transient. At 14:59:21 the gate refused a new player
(`squeezedan`) with a claim code, as designed.

## 3. Rollback

- API: restore `backups/<TS>/compose.yaml` from the S-3 backup (image `alpha-fa28f7ea`, no seeding line), copy to
  stack 42, `up -d --no-deps api`, `RECORDED_SHA` back to `73c6cd9a…`. The old image seeds the examples again; the
  rows can be removed with the same script.
- Plugin: `backups/20261025T140211Z/KnightsAndKings-before.jar` → `plugins/update/KnightsAndKings.jar`
  (`2001:2001`), `save-all flush`, restart.
- Data: snapshot `…-pre-6f08383d`.

## 4. Later the same day: `ALLOW_FLIGHT` workaround (developer)

15:02Z: the developer added `ALLOW_FLIGHT: "TRUE"` to the `minecraft` environment (itzg → `allow-flight=true` in
`server.properties`) because players were kicked for "flying" by mistake; a real fix gets its own issue. Compose
`41f7b64a…` → **`82def53828bc3f8ad45fdbbe0c89cdd282724fd1e4fd10604ccd05e7c086eeba`** (backup
`backups/20261025T150142Z/`, Portainer identical); the `knk-ops compose` wrapper records it. Side effect to keep in
mind: with flight allowed, Paper no longer kicks real fly hacks either — remove the line when the fix ships.
