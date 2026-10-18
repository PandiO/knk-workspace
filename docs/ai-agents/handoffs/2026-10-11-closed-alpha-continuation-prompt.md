# New-session prompt: continue the closed-alpha NAS deployment

**Originally created:** 2026-10-11

**Last verified and rewritten:** 2026-10-12

**Status:** Ready to copy into a fresh session

**Working branch:** `codex/closed-alpha-infrastructure-handoff`

**Canonical handoff:** [closed-alpha infrastructure](2026-10-11-closed-alpha-infrastructure.md)

The earlier copy of this prompt is obsolete. It described building the
`17ee730a` API and, in one circulated version, a disposable preflight stack.
That API has already been built, corrected, privately deployed, and accepted.
Do not repeat that work or create a parallel preflight stack.

```text
Continue the Knights & Kings NAS closed-alpha deployment using branch:

codex/closed-alpha-infrastructure-handoff

Before taking action, read these files completely:

- AGENTS.md
- docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md
- docs/ACTIVE_SESSIONS.md
- docs/ai-agents/handoffs/2026-10-11-closed-alpha-infrastructure.md
- docs/reports/2026-10-11-closed-alpha-infrastructure-progress.md
- docs/guides/closed-alpha-deployment-runbook.md
- docs/guides/alpha-go-live.md
- docs/guides/production-installation.md, especially the container/migrator
  sections referenced by alpha-go-live

Refresh knk-workspace, knk-web-api, knk-web-app, and knk-plugin and compare
the current default branches, open work recorded in docs/ACTIVE_SESSIONS.md,
and live NAS state with the durable documents. Do not assume a planned,
previously reported, or branch-local step has completed. Do not overlap or
replace another active session's claimed work. Update the tracker and durable
documentation as the deployment progresses.

Give NAS commands as commands for an already-open persistent SSH session.
Clearly label Windows PowerShell commands. Use stop conditions and request
only concise, non-secret output. Never print the MySQL passwords, plugin API
key, JWT secret, or any derived connection string/token containing them.

Current accepted live state to VERIFY, not assume
-------------------------------------------------

**Developer correction (2026-10-12; newer than the older runbook/report):**
the authored seed/content set is not ready, and the current NAS
`knightsandkings_alpha` database is a disposable infrastructure placeholder,
not relevant final alpha data. Preserve its diagnostic backups, but do not
carry its rows forward, migrate it as if it were authoritative, or call a dump
of it the final alpha baseline. Build deployable artifacts independently. When
the approved seed is ready, initialize a fresh final database in the then-
current migrations -> seed import -> first API start order. Any use of the
placeholder for a migration/deployment rehearsal requires an explicit user
choice.

- Portainer's authoritative knk-alpha stack is stack 42. The host Compose is
  /srv/docker/stacks/knk-alpha/compose.yaml. At the last acceptance, its raw
  SHA-256 was
  b4c501eedee03404f6829390dc9eb1d3b3eeb0dd0886136081cce5276a4e298c
  and it canonically matched Portainer.
- knk-alpha-mysql is healthy and private on knk-alpha_backend, has no host
  port, runs MySQL 9.6.0, and contains the disposable placeholder database
  knightsandkings_alpha. Its last accepted container ID began 01a611461c12.
- knk-alpha-api is healthy and private on knk-alpha_backend with no host-port
  binding. It currently uses the accepted but pre-KNG-64 image
  knk-web-api:alpha-17ee730a, image ID
  sha256:61c7e1f6bd451748e3bf6c1cc65f9a49fe5e1b12bdce2bf273c91f8bbea46251,
  as UID:GID 1000:1000.
- The current API's /health/live and /health/ready returned 200. A controlled
  restart returned healthy in about 10 seconds with the same API container,
  no secret leak, no error/critical lines, and idempotent seeders.
- The accepted database evidence was 136 base tables, 4 triggers, 76 EF
  migrations, 9 users, and 2 active users (admin and __pandi__). The recorded
  transient/activity tables were empty. Canonical seed counts were:
  AbilityDefinitions 12, EnchantmentDefinitions 26, item_blueprints 154,
  kits 2, lootbox_types 9, menu_templates 27, siege_lobbies 3.
- Protected files are under /srv/docker/stacks/knk-alpha/secrets/. Preserve
  the existing MySQL app-password, root/schema credential, plugin API-key, and
  JWT-secret files without displaying them. Use the schema credential for a
  migration only when initializing the final database or during an explicitly
  approved disposable rehearsal.
- The original clean alpha dump remains the rollback source; its SHA-256 is
  dd877d5587982d2a31e5b0ec003cec92d47960cfed969f57bdf600b979ed975f.
- The old MySQL-only Compose is preserved at
  /srv/docker/stacks/knk-alpha/compose.mysql-only.pre-api.20261011T151034Z.yaml.
- The rejected UID-collision API image is retained only as
  knk-web-api:alpha-17ee730a-uid1654-failed. Never deploy it.
- No Minecraft, playit, nginx, web-app, or Cloudflare alpha service has been
  accepted or exposed yet.

Immediate next milestone: Phase 3b artifact build
-------------------------------------------------

The deployed 17ee730a API predates KNG-64. It is safe only because it remains
private. Do not expose it and do not connect the Minecraft plugin to it.

PR #9 merged on 2026-10-12. The exact accepted knk-web-api `master` merge is
`07fda99e6f8243e71cc45491990b1dd1d02ca686` and contains package-fix commit
`25b4776`. Refresh before building and stop if `master` has changed unexpectedly.
Never deploy directly from the feature branch. Record the full source revision,
source-archive hash, Dockerfile hash, image ID, labels, and base-image digests.
The SDK build should emit no NU190x warning; record and stop on any advisory.

Use runbook Phase 3b and alpha-go-live sections 3-4 for artifact construction.
Their older carry-forward database instructions are superseded here:

1. The live containers, private networking, host-port bindings,
   Compose/Portainer equivalence, protected secret metadata, health, logs and
   placeholder DB counts were re-verified on 2026-10-12. Do not display secret
   contents when rechecking them.
2. A protected pre-change placeholder dump was created at
   `alpha-db-pre-kng64/20261012-183351/`, SHA-256
   `58dbdbf1388fcde35ea0a895e7a4ea84fba8ce3fc5ad2a24acb89c5b37fe2293`.
   Preserve it and all earlier backups as diagnostics, not final seed data.
3. The placeholder's holder-ID clash was repaired before the developer
   correction was restated: Staff moved from 29 to 39 with all 54 grants,
   `admin` stayed at 29, and clashes/orphans are zero. Do not spend more work
   preparing this placeholder for production.

For historical context only, the obsolete carry-forward procedure checked:

   SELECT u.Id, u.Username, g.Name
   FROM users u
   JOIN permission_groups g ON g.Id = u.Id;

   Do not repeat this cleanup on the disposable placeholder.
4. Produce and verify a source archive from the exact accepted master commit.
   Build knk-web-api:alpha-<sha> with the proven deployment-only multi-stage
   Dockerfile. Preserve the KNK_RUNTIME_UID/KNK_RUNTIME_GID fix; do not use
   APP_UID/APP_GID because the .NET base image defines APP_UID=1654.
5. From the same source revision, build the one-off migrator target/image.
   Do not run it against the current placeholder unless the user explicitly
   chooses a disposable rehearsal. Never grant schema rights permanently to
   knk_alpha_app.
6. At this pinned revision, the migrator contains
   20261008083025_AddRefreshTokensAndTokenVersion and
   20261010121436_AddDomainWorldName. Do not apply them to the placeholder by
   default. When the approved seed is ready, refresh trunk again and derive
   the final expected migration history from that accepted revision rather
   than assuming the historical count of 78.
7. Configure the replacement API with the existing secret-file wrapper and:
   - AllowedHosts=<web-host>;api;localhost
   - Security__PasswordResetFrontendBaseUrl=https://<web-host>
   - Security__PasswordResetExposeTokenInDevelopment=false
   - Security__Registration__AllowWebFirst=false
   - Security__RefreshCookie__SameSite=Lax
   - Security__AllowUnauthenticatedPluginCalls=false
   - ForwardedHeaders__Enabled=true and only the nginx network/subnet trusted
   - MinecraftPlugin__BaseUrl=http://minecraft:8081
   - Email__Provider=Log while the API has no egress
   - Telemetry__Enabled=false
   - no CORS origins because the SPA and /api use one origin
8. The web hostname is still an explicit user decision: either
   app.knightsandkings.net or the older knk.oldenzeelit.nl. Do not guess. Ask
   before finalizing AllowedHosts, password-reset URL, plugin web.public-url,
   web build, Cloudflare hostname, or Access policy.
9. Switch the private stack to the new API only after the final database is
   initialized, or as part of an explicitly approved disposable rehearsal.
   Re-run Phase 3 acceptance: live/ready health, image/user/network/port
   identity, logs, controlled restart, migration/schema/user/activity/seed
   counts, secret-leak checks, and MySQL continuity. Run the private security
   probe scripts/security/alpha-probe.sh. Take and checksum a new clean
   post-migration baseline only after all checks pass.

Minecraft and multiworld coordination after Phase 3b
----------------------------------------------------

- The user reports that branch claude/blissful-fermat-b7ihrz is active and
  implementing the simple KnK-owned world loader. The tracker snapshot may be
  stale and the branch was not on the remote at last refresh. Check with the
  user/current session and inspect the exact pushed/merged revision before
  doing anything. Do not duplicate, overwrite, or prematurely deploy that
  work.
- The accepted hub archive was copied to the dev server and the user reports
  it works there. That does not yet prove full loader acceptance. Require a
  full restart auto-load test, fail-closed behavior when the hub is missing,
  main world remaining primary, deterministic main/hub transition, and no
  UUID/chunk/world-identity errors. Record the evidence.
- Main archive:
  /home/ubuntunas/docker-backups/minecraft/main/20261011-015543/knk-main-snapshot-20261011-015543.tar.gz
  SHA-256 82b0afca0327f5e499250b7a030783e1c4fe365d0f56f4d5e29f47144533b150
- Hub archive:
  /home/ubuntunas/docker-backups/minecraft/hub/20261011-014433/knk_hub-paper-1.21.10-20261011-014433.tar.gz
  SHA-256 43944a03d673d2b6b8e92dfb2f016b389ca414baa135b600519e072f6ccb9cc4
- Verified staging is /srv/docker/staging/knk-alpha-20261011/ with
  knk-main-snapshot-20261011-015543/ and knk_hub/. Never boot directly from
  staging. Create a separate live data path and preserve staging as rollback.
- Package the exact accepted plugin revision and record the JAR checksum.
  Configure api.base-url=http://api:5000/api, API-key authentication,
  region-http.bind-address=0.0.0.0 without publishing port 8081, and
  web.public-url=https://<web-host>. The API reaches the plugin at
  http://minecraft:8081.
- Minecraft needs both the internal backend network and an egress-capable
  network for Mojang session services. Use online-mode=true, white-list=true,
  and enforce-whitelist=true. Do not publish NAS ports.
- Privately validate both worlds, tick health, the exact plugin/API/database
  path, account behavior, clean shutdown/restart, memory/CPU, backups, and
  absence of cross-environment writes before adding playit or another service.

Decisions and safety boundaries to preserve
-------------------------------------------

- No Multiverse Core. KnK owns the minimal multiworld lifecycle and transition
  implementation.
- Paper 1.21.10 and Java 21 for the first deployment. Paper 26.2 and Java 25
  are a later cloned-environment upgrade, never an in-place first deployment.
- One Minecraft server loads the main and hub worlds concurrently.
- playit.gg is only for Minecraft. The intended Minecraft hostname is
  play.knightsandkings.net via GoDaddy DNS.
- Cloudflare Tunnel/nginx is only for the web app and API.
- Alpha MySQL remains private; development MySQL remains LAN-only.
- Initial Minecraft heap is 1-4 GiB with an approximately 5 GiB container
  limit because the NAS also runs Frigate and other services.
- Do not expose the API or web app, start Minecraft, add playit, change public
  DNS/Cloudflare, alter the database without the required backup/validation,
  delete backups, remove the retired Portainer state, or remove diagnostic
  artifacts before the corresponding acceptance gate passes.
- Keep changes incremental and reversible. Verify the live result after each
  mutation and stop on an unexpected container recreation, image mismatch,
  port binding, migration count, database count, secret exposure, or log
  error.
```
