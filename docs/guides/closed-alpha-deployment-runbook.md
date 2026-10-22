# Closed-alpha deployment runbook

**Status:** In progress — phases 0–3 complete; phase 4 Stage 1 (Minecraft container without the KnK plugin, [KNG-225](https://linear.app/kngpandi/issue/KNG-225)) running since 2026-10-21 ([report](../reports/2026-10-21-minecraft-container.md)); phase 3b (API upgrade to the KNG-64 build, [KNG-227](https://linear.app/kngpandi/issue/KNG-227)) complete 2026-10-22 ([report](../reports/2026-10-22-alpha-api-kng64-upgrade.md)); phase 4 Stage 2 is next. Web hostname decided 2026-10-21: `app.knightsandkings.net`
**Last updated:** 2026-10-22
**Progress report:** [2026-10-11 closed-alpha infrastructure progress](../reports/2026-10-11-closed-alpha-infrastructure-progress.md)
**Handoff:** [2026-10-11 closed-alpha infrastructure](../ai-agents/handoffs/2026-10-11-closed-alpha-infrastructure.md)
**Security layer:** [closed alpha go-live (KNG-64)](alpha-go-live.md) — required builds, API/plugin configuration,
first admin, security probe and the go-live checklist on top of these phases

This is the ordered rollout plan for the first NAS-hosted closed alpha. Keep
each phase independently reversible and record the observed result before
continuing.

## Operations access and host state (2026-10-18)

- **Read-only checks for agents:** from the developer PC on the LAN, `ssh knk-nas-ops <op>`
  returns sanitized JSON for containers, network, secret files, API health, Compose hashes,
  database counts, a secret-in-logs scan and log error counts. Use these instead of ad-hoc
  `docker inspect`/`docker logs`. See [NAS operations access](nas-ops-access.md); its Stage B
  (deploy operations) is designed but not installed.
- **Ingress:** the NAS has no router port forwards. Public HTTP(S) reaches it only through the
  Cloudflare Tunnel, which Phase 6 relies on. Docker commands on the host need `sudo`.
- **Re-check and open findings:** the 2026-10-18 state and alpha findings A1–A6 (runtime UID and
  secret ownership, stack-directory ownership, `root@%`, leftover pending Compose file, API log
  volume, Portainer vs host Compose authority) are in the
  [2026-10-18 report](../reports/2026-10-18-nas-ops-access-and-alpha-check.md). Phase 3b resolved A1, A2, A4, A5
  and A6 on 2026-10-22; A3 (`root@%`) is open as [KNG-242](https://linear.app/kngpandi/issue/KNG-242).

## Phase 0 — protect existing infrastructure (complete)

- Back up the development MySQL logically and physically.
- Recover `knk-dev` Compose from the authoritative Portainer data.
- Back up both Portainer data volumes.
- Back up nginx configuration/certificates and the `core` stack Compose.
- Move nginx `portainer.pyth` to the editable Portainer instance.
- Convert authoritative Portainer to host-side Compose management.
- Retain the old Portainer stopped with restart disabled.
- Copy important backups and Compose files off the NAS.

Acceptance: Portainer survives restart, login works, and `knk-dev` remains
editable. Completed and operator-confirmed.

## Phase 1 — prepare immutable world sources (complete)

- Snapshot main gameplay, nether, end, server configuration, selected plugin
  jars, and plugin data.
- Convert and visually validate the historic hub on Paper 1.21.10.
- Archive/checksum both packages and copy them to the NAS.
- Extract verified copies into protected staging.

Acceptance: four expected `level.dat` files exist; important hub build is
intact. Completed and operator-confirmed.

## Phase 2 — create isolated alpha MySQL (complete)

- Create `knk-alpha` secrets and Compose stack.
- Run MySQL without a published host port on a private backend network.
- Dump/import `knightsandkings_dev_v2` into `knightsandkings_alpha`.
- Strip only dump-time trigger definers during import.
- Validate tables, migrations, triggers, and app-account access.
- Keep only `__pandi__` and `admin` usable; tombstone all other users.
- Clear transient development workflow/session data.
- Create the clean baseline dump and metadata.

Acceptance: healthy container, 136 tables, 4 triggers, 76 migrations, exactly
two active accounts, app account can connect, clean dump verifies. Complete.

## Phase 3 — build and privately start the API (complete)

### 3.1 Build the pinned image

Use the verified archive:

```text
/home/ubuntunas/docker-backups/deployment-sources/knk-web-api/17ee730a/
knk-web-api-17ee730a.tar.gz
```

Create the build context under:

```text
/srv/docker/build/knk-web-api/17ee730a/source
```

Build a multi-stage .NET 8 image tagged:

```text
knk-web-api:alpha-17ee730a
```

The runtime image must expose port 5000 and check
`http://127.0.0.1:5000/health/ready`. Record:

- final image ID and size;
- source revision label;
- source-archive SHA-256 label;
- SDK and ASP.NET base-image digests.

Accepted build evidence (2026-10-11):

- source archive SHA-256:
  `0a7a04ef8ce92f34ab8027d9cf2322b2005bb60d8e8c54f03d7e6d2820bc6ac7`;
- final image ID:
  `sha256:61c7e1f6bd451748e3bf6c1cc65f9a49fe5e1b12bdce2bf273c91f8bbea46251`;
- size: 259,134,752 bytes;
- runtime user: `1000:1000`;
- SDK digest:
  `sha256:ec9c0a0dc5f60adc2065762050638dd5ed5facfc53716d4580a42d86027c8e80`;
- ASP.NET digest:
  `sha256:a3cd573ac05cf88ca496e3309cb7f7c44aa16664352d1ee41eda93154f50cdbf`.

The .NET 8 runtime base defines `APP_UID=1654`; that name overrode the first
Dockerfile's same-named build argument. The corrected Dockerfile uses
`KNK_RUNTIME_UID`/`KNK_RUNTIME_GID`. The rejected image is retained under
`knk-web-api:alpha-17ee730a-uid1654-failed` for audit only.

### 3.2 Add API to `knk-alpha`

Add service `api` to the existing stack with:

- image `knk-web-api:alpha-17ee730a` (no `build:` in Portainer);
- private `backend` network;
- no published host port initially;
- dependency on healthy MySQL;
- `ASPNETCORE_URLS=http://+:5000`;
- `ASPNETCORE_ENVIRONMENT=Production`;
- `Database__MySqlServerVersion=9.6.0` to avoid runtime detection;
- connection string using Compose DNS name `mysql`, database
  `knightsandkings_alpha`, and account `knk_alpha_app`;
- plugin API key and JWT secret sourced from files under
  `/srv/docker/stacks/knk-alpha/secrets/`.

ASP.NET configuration does not automatically interpret arbitrary `_FILE`
environment variables. Use a reviewed entrypoint/wrapper that reads mounted
secret files and exports the real configuration variables, or add explicit
file-secret support in code. Do not paste secrets into Portainer's web editor
or committed Compose.

Recommended configuration keys:

```text
ConnectionStrings__MySqlDbConnection
Security__PluginApiKey
Security__Jwt__Secret
Database__MySqlServerVersion
```

The current app performs canonical seeding on startup and requires the
database to be reachable. It does not automatically apply pending EF
migrations; the imported database already matches the packaged revision, but
future upgrades need an explicit migration step.

### 3.3 Private acceptance

From inside the Docker network, verify:

- `/health/live` returns 200;
- `/health/ready` returns 200 and reports database healthy;
- container health becomes healthy;
- logs contain no secret values and no recurring startup/seed errors;
- database table and migration counts remain correct;
- API restart is idempotent.

Create a fresh database dump after any startup seed changes.

Acceptance completed 2026-10-11:

- API container healthy on private `knk-alpha_backend`, with
  `.HostConfig.PortBindings={}`;
- `/health/live` and `/health/ready` both returned 200, with database healthy;
- MySQL container was not recreated;
- 136 tables, 4 triggers, and 76 migrations remained unchanged;
- two active users remained `admin` and `__pandi__`;
- all recorded transient/activity tables stayed empty;
- all canonical seed counts stayed unchanged on first start and restart;
- no secret values and no error/critical/exception entries appeared in logs;
- controlled restart returned healthy in about 10 seconds.

No fresh database dump was required because every canonical seeder reported
zero creates, updates, and normalizations. Expected derived background jobs
did run. The original clean baseline dump remains the rollback source.

## Phase 3b — upgrade the API to the KNG-64 build (complete)

The accepted `17ee730a` image predated the KNG-64 merge (knk-web-api `30c5dc5`): no default-deny
API, refresh sessions, code-based signup, rate limits or permission-escalation guard. Steps, also the procedure for
later API updates with migrations:

1. Dump `knightsandkings_alpha` (new dated file, `--set-gtid-purged=OFF`; keep the clean baseline).
2. Run the holder-id clash check (`knk-ops db-summary` reports `holder_id_clashes`). The dev dump predates the dev DB's
   `admin`/Staff (id 29) repair; repair with `scripts/maintenance/repair-holder-id-clash.sql` if it returns a row.
3. Build `knk-web-api:alpha-<sha>` and `knk-web-api-migrator:alpha-<sha>` from one `git archive` of trunk with the
   build files in [`scripts/alpha-api/`](../../scripts/alpha-api/) (runtime UID 2002, migrator target). The NAS has
   no buildx: use the legacy builder without `--progress`.
4. Stop the API, dump again, and run the migrator once with a schema-rights account (root until KNG-242). It applies
   migrations whose timestamps can be older than the DB's newest one, so use `database update`, not
   `migrations script <from>`. Compare the migration count with the built source (`Migrations/` without designers).
5. Add the KNG-64 configuration, switch the image in the host `compose.yaml`, copy it to Portainer stack 42, recreate
   only `api`, and repeat the Phase 3.3 acceptance.
6. Take a new clean baseline dump.
7. Re-run the `knk-ops` checks. After a Compose change, update `RECORDED_SHA` in
   `scripts/nas-ops/stage-a/ops/compose` and its NAS copy.

**Result 2026-10-22** ([report](../reports/2026-10-22-alpha-api-kng64-upgrade.md), [KNG-227](https://linear.app/kngpandi/issue/KNG-227)):
- source `be9f4e1a`, archive SHA-256 `37916e02…c66a`;
- image `knk-web-api:alpha-be9f4e1a` (`0b47f0095495…`), healthy as `2002:2002`;
- 6 migrations applied, **82** in total (not 78: `master` gained four more after `07fda99e`), 137 tables;
- Compose `2af121b6…`, Portainer stack 42 identical;
- new clean baseline `alpha-db-clean/20261022T182711Z-kng64/` (`45ddfcae…`).

All `knk-ops` checks pass. A1, A2, A4, A5 and A6 are resolved; A3 is [KNG-242](https://linear.app/kngpandi/issue/KNG-242).

Exact commands and configuration: [alpha go-live § 3–4](alpha-go-live.md#3-upgrade-the-alpha-api-to-kng-64-runbook-phase-3b).

## Phase 4 — prepare the Minecraft service

> **Decision 2026-10-18 (developer, [KNG-182](https://linear.app/kngpandi/issue/KNG-182)):** the alpha starts on
> **Paper 26.3 / Java 25** (first 26.2; moved to 26.3 stable the same day), not 1.21.10; the former Phase 8 upgrade is folded into this phase. Consequences:
> - the plugin jar comes from knk-plugin `main` after KNG-182 (`claude/mc-26.2-upgrade`) merges; earlier `main`
>   builds target 1.21.10 only, and later ones run only on 26.3;
> - the staging sources stay 1.21.10 and are the rollback. Paper converts the **live copy** on its first start
>   (after a 30 s "World storage migration is required" warning), and converted worlds cannot be downgraded;
> - after conversion there is one `level.dat` (`<level>/level.dat`). Nether, end and the hub live under
>   `<level>/dimensions/minecraft/<name>/` (e.g. `knk_hub`): Paper imports and deletes the old `knk_hub/` folder
>   when the plugin first loads it, so check worlds in the new layout, not as separate folders;
> - every plugin jar needs a 26.3 build (the dev server moves to FastAsyncWorldEdit 2.16.1 and WorldGuard 7.0.20);
> - players need a Java Edition 26.3 client.

> **Decision 2026-10-21 (developer, [KNG-225](https://linear.app/kngpandi/issue/KNG-225)):** set the container up
> **now**, with a jar built from the KNG-182 branch (`claude/mc-26.2-upgrade`), and deliver later plugin builds
> (from `main` once KNG-182 merges) without rebuilding the container. The container needs a remote console and
> must start on its own after a NAS reboot. Session prompt:
> [2026-10-21 Minecraft container](../ai-agents/handoffs/2026-10-21-minecraft-container-prompt.md).
> Phase 3b ran on 2026-10-22, so the API is the KNG-64 build `be9f4e1a`. The database is still the placeholder, so
> a run against it is a **disposable rehearsal**, and the world copy is replaced when the approved seed is exported (worlds and
> world-coupled rows must come from the same moment, production guide § 7.4).

> **Status 2026-10-21 (paused after Stage 1):** `knk-alpha-minecraft` runs Paper 26.3 build 205 on the image pinned
> above, as UID 2001, with FAWE 2.16.1 and WorldGuard 7.0.20 and no KnK jar yet. Its worlds were copied from the
> converted dev server `DEV_SERVER_26.3`, not from staging, and the staging tree stays the rollback. Other choices:
> `mem_limit` 6 GiB, no ports, and the RCON console works. A `systemctl restart docker` saved the worlds and brought the
> stack back on its own. The host `compose.yaml` is authoritative and is copied to Portainer stack 42 (A6). Stage 2 (KnK
> plugin, update swap, private acceptance) waited for Phase 3b, which completed on 2026-10-22. Details:
> [2026-10-21 report](../reports/2026-10-21-minecraft-container.md).

### 4.1 Service definition

A `minecraft` service in the `knk-alpha` Compose file (`container_name: knk-alpha-minecraft`):

- image `itzg/minecraft-server` `java25` variant, **pinned by digest** (record it in a progress report);
- `TYPE=PAPER`, `VERSION=26.3`, `PAPER_BUILD=<pinned build>`, `EULA=TRUE`, so a restart never pulls a newer Paper;
- `MEMORY=4G`, `deploy.resources.limits.memory` about 5 GiB;
- `ONLINE_MODE=TRUE`, `ENABLE_WHITELIST=TRUE`, `ENFORCE_WHITELIST=TRUE`;
- `restart: unless-stopped` (autostart: Docker itself must be enabled at boot, `systemctl is-enabled docker`);
- `stop_grace_period: 2m`, so Paper saves both worlds when the NAS shuts down;
- the image's built-in health check (`mc-health`);
- volume: one host directory for `/data` (worlds, `plugins/`, configs) under the stack path, created as a **copy**
  of the verified staging sources;
- secrets: the RCON password as a file (`RCON_PASSWORD_FILE`), mode 600, never in Compose or Portainer;
- networks: `backend` (API at `http://api:5000/api`, region callbacks on `minecraft:8081`) plus an egress network
  for Mojang session servers and the Paper download;
- **no published ports**: not 25565 (playit reaches it over Docker DNS in Phase 5), not 25575, not 8081;
- no hard `depends_on` on the API: the plugin handles an API outage (KNG-115) and must not keep the server down.

### 4.2 Console

- RCON is on 25575 inside the container only. Console sessions:
  - Portainer → container `knk-alpha-minecraft` → *Console* → command `rcon-cli`;
  - or over SSH: `sudo docker exec -it knk-alpha-minecraft rcon-cli`.
- `stdin_open: true` and `tty: true` also allow `sudo docker attach knk-alpha-minecraft` (detach with Ctrl-P Ctrl-Q;
  Ctrl-C stops the server).
- From outside the LAN there is no console route yet. Exposing Portainer or a web RCON through the tunnel needs its
  own Access application and a decision; don't add one as a side effect.

### 4.3 Plugins and plugin updates

- Install the 26.3 builds of FastAsyncWorldEdit 2.16.1 and WorldGuard 7.0.20, and the KnK jar under the **fixed
  filename** `plugins/KnightsAndKings.jar` (the shadow jar's own name carries the version; a fixed name is what
  the update folder matches).
- Keep a release folder per build next to the stack (`releases/plugin/<commit>/` with the jar, its SHA-256 and the
  source commit), root-owned.
- **Update:** copy the approved jar to `plugins/update/KnightsAndKings.jar`, compare the live `config.yml` with the
  new jar's defaults, then restart at a quiet moment: `rcon-cli save-all flush`, then restart the container. Paper
  replaces the jar from `plugins/update/` on start ([Paper docs: updating](https://docs.papermc.io/paper/updating/)).
  Verify that swap once on the dev server before relying on it. Never `/reload`.
- **Rollback:** the previous release folder's jar goes through the same path.
- Later: a Stage B operation does the staging and restart from the approval file ([NAS ops access](nas-ops-access.md)
  § 7), and CI publishes the jar ([KNG-226](https://linear.app/kngpandi/issue/KNG-226)).

### 4.4 Runtime, world loader and plugin configuration


Do not start from the staging directories. Create a separate live data path,
then copy the verified sources into it while preserving staging as rollback.

Initial runtime:

- `itzg/minecraft-server` image with Java 25 (pin it and record its digest in the progress report);
- Paper 26.3;
- `MEMORY=4G`, container memory limit approximately 5 GiB;
- main gameplay world as the primary level;
- nether and end beside it;
- converted hub as a distinct world directory;
- no dev-only AutoPluginLoader;
- no published RCON or web-RCON ports;
- Minecraft port not router-forwarded if playit is used.

The KnK-owned existing-world loader (KNG-114, merged 2026-10-17) must show
these properties live during acceptance:

- load `knk_hub` on the main thread during startup;
- fail closed if the hub cannot load;
- preserve per-world identity in Domains, Locations, Districts,
  GateStructures, WorldGuard integration, caches, navigation, spawn, and
  recovery destinations;
- avoid hard-coded `Bukkit.getWorlds().get(0)` or primary-world assumptions;
- unload safely only during controlled shutdown, if unloading is needed at
  all.

Configure the plugin API root using Docker service DNS, not `localhost`:

```text
http://api:5000/api
```

The same plugin API key must be provided to the API and plugin without
printing it. Disable development-only unauthenticated calls and debug/trust
bypasses for the alpha.

KNG-64 plugin settings (a copied dev `config.yml` keeps its old values):
`api.auth.type: apikey`, `api.allow-untrusted-ssl: false`,
`region-http.bind-address: "0.0.0.0"` (inside the container; never publish
8081), `web.public-url: "https://app.knightsandkings.net"`. The API reaches the plugin
with `MinecraftPlugin__BaseUrl=http://minecraft:8081` (the service name).
The Minecraft container also needs an internet-capable network for Mojang
session servers, since `backend` is internal. Use `online-mode=true` and the
whitelist. See [alpha go-live § 5](alpha-go-live.md#5-minecraft-and-plugin-runbook-phases-45).

Private acceptance before ingress:

- server reaches a stable tick rate with both worlds loaded;
- hub and main builds are intact;
- plugin reaches the alpha API and only the alpha database;
- `__pandi__` joins as the retained account;
- an unknown player creates/links an alpha account rather than touching dev;
- restart preserves both worlds and account state;
- memory/CPU remain acceptable alongside Frigate.
- `rcon-cli` works from Portainer's console and over SSH; nothing listens on a published port;
- after a NAS reboot (or `sudo systemctl restart docker`) the server comes back healthy on its own;
- one jar swap through `plugins/update/` has been done and the startup log shows the new build.

## Phase 5 — playit.gg and Minecraft DNS

- Run the playit agent as its own Compose service, not an ad-hoc
  `docker run` command.
- Store its secret key in a protected secret file.
- Route only Minecraft TCP to the Minecraft service/port.
- Do not tunnel MySQL, RCON, Portainer, Docker, or the API through playit.
- In **Cloudflare DNS** (zone `knightsandkings.net`; GoDaddy is only the
  registrar), point `play.knightsandkings.net` to the address assigned by
  playit according to playit's Minecraft custom-domain instructions. The
  record must be **DNS only** (grey cloud): Cloudflare's free proxy does not
  carry Minecraft TCP.
- If playit assigns a non-default public port, use the required SRV record or
  request an allocation compatible with standard Java clients.

Acceptance: a test player outside the LAN connects using
`play.knightsandkings.net`; no router port-forward is required; scans from the
internet cannot reach NAS MySQL/RCON/Portainer.

## Phase 6 — web app and HTTP ingress

- Package the exact web-app revision after the API is stable.
- Prefer serving the web app and proxying `/api` to `api:5000` under the same
  public origin. This avoids broad CORS configuration.
- Route the web application through Cloudflare Tunnel/nginx at
  `app.knightsandkings.net` (developer decision 2026-10-21; `knk.oldenzeelit.nl`
  is not used). Zone settings and the WAF rule are per zone, so set them on
  `knightsandkings.net` ([alpha go-live § 6](alpha-go-live.md#6-web-app-and-ingress-runbook-phase-6)).
- Apply Cloudflare Access to the **whole** web host during the closed alpha
  (KNG-64 plan decision D10: invited emails only), but do not use it as a
  substitute for application authorization. The plugin calls the API over
  Docker DNS, so Access never stands in its way.
- nginx must share a network with `api`; set the API's `ForwardedHeaders`
  to trust only that network ([alpha go-live § 4, § 6](alpha-go-live.md#6-web-app-and-ingress-runbook-phase-6)).
- Rate-limit login, password reset, and account-link endpoints.

Acceptance: external alpha users can load the web app and authenticate; the
browser calls only the intended API origin; admin routes enforce KnK roles;
no internal management service is exposed.

## Phase 7 — backup automation and rehearsal

- Nightly logical dump of `knightsandkings_alpha`, with retention and
  checksum.
- Regular world backup using RCON `save-off`, `save-all flush`, archive, then
  `save-on`, or a tested equivalent supported by the server image.
- Back up Compose, plugin config, and encrypted secrets separately.
- Copy backups off the NAS and keep one offline/versioned copy.
- Test restoring MySQL and the Minecraft data into disposable containers.
- Record RPO/RTO and the last successful restore rehearsal.
- Accept a restored copy with the read-only `knk-ops` checks (`db-summary`, `secret-scan`,
  `log-errors`) as well as in-game checks.

## Phase 8 — later version upgrade (folded into Phase 4)

Superseded on 2026-10-18: the alpha starts on Paper 26.3 (see the decision in
Phase 4). The original rule still applies to any later Minecraft upgrade:
clone the stack, never upgrade the only alpha copy in place, compile and test
all plugins, inspect Paper's conversion output, and validate both worlds
before scheduling a cutover.
