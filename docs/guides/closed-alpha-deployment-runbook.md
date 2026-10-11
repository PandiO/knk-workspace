# Closed-alpha deployment runbook

**Status:** In progress — phases 0–2 complete; phase 3 (API image) is next
**Last updated:** 2026-10-11
**Progress report:** [2026-10-11 closed-alpha infrastructure progress](../reports/2026-10-11-closed-alpha-infrastructure-progress.md)
**Handoff:** [2026-10-11 closed-alpha infrastructure](../ai-agents/handoffs/2026-10-11-closed-alpha-infrastructure.md)

This is the ordered rollout plan for the first NAS-hosted closed alpha. Keep
each phase independently reversible and record the observed result before
continuing.

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

## Phase 3 — build and privately start the API (next)

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

Do not claim this phase complete until the image exists and inspection output
has been saved.

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

## Phase 4 — prepare the Minecraft service

Do not start from the staging directories. Create a separate live data path,
then copy the verified sources into it while preserving staging as rollback.

Initial runtime:

- `itzg/minecraft-server` Java 21 digest recorded in the progress report;
- Paper 1.21.10;
- `MEMORY=4G`, container memory limit approximately 5 GiB;
- main gameplay world as the primary level;
- nether and end beside it;
- converted hub as a distinct world directory;
- no dev-only AutoPluginLoader;
- no published RCON or web-RCON ports;
- Minecraft port not router-forwarded if playit is used.

Before booting both worlds, KNG-114 must implement/verify the KnK-owned
existing-world loader. Required properties:

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

Private acceptance before ingress:

- server reaches a stable tick rate with both worlds loaded;
- hub and main builds are intact;
- plugin reaches the alpha API and only the alpha database;
- `__pandi__` joins as the retained account;
- an unknown player creates/links an alpha account rather than touching dev;
- restart preserves both worlds and account state;
- memory/CPU remain acceptable alongside Frigate.

## Phase 5 — playit.gg and Minecraft DNS

- Run the playit agent as its own Compose service, not an ad-hoc
  `docker run` command.
- Store its secret key in a protected secret file.
- Route only Minecraft TCP to the Minecraft service/port.
- Do not tunnel MySQL, RCON, Portainer, Docker, or the API through playit.
- In GoDaddy DNS, point `play.knightsandkings.net` to the hostname assigned by
  playit according to playit's Minecraft custom-domain instructions.
- If playit assigns a non-default public port, use the required SRV record or
  request an allocation compatible with standard Java clients.

Acceptance: a test player outside the LAN connects using
`play.knightsandkings.net`; no router port-forward is required; scans from the
internet cannot reach NAS MySQL/RCON/Portainer.

## Phase 6 — web app and HTTP ingress

- Package the exact web-app revision after the API is stable.
- Prefer serving the web app and proxying `/api` to `api:5000` under the same
  public origin. This avoids broad CORS configuration.
- Route the web application through Cloudflare Tunnel/nginx at the selected
  public hostname (the earlier working name was `knk.oldenzeelit.nl`; confirm
  the final production name before publishing).
- Apply Cloudflare Access to admin-only surfaces where practical, but do not
  use it as a substitute for application authorization.
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

## Phase 8 — later version upgrade

After the 1.21.10 alpha stack is stable, clone it and evaluate Paper 26.2 with
the required Java 25 runtime. Do not upgrade the only alpha copy in place.
Compile and test all plugins, inspect Paper conversion output, and validate
both worlds before scheduling a cutover.
