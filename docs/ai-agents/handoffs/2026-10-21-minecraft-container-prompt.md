# New-session prompt: Minecraft container for the closed alpha (KNG-225)

**Created:** 2026-10-21
**Status:** Ready to copy into a fresh session
**Issue:** [KNG-225](https://linear.app/kngpandi/issue/KNG-225) (related: [KNG-182](https://linear.app/kngpandi/issue/KNG-182), [KNG-114](https://linear.app/kngpandi/issue/KNG-114), [KNG-64](https://linear.app/kngpandi/issue/KNG-64))
**Runbook:** [closed-alpha deployment runbook](../../guides/closed-alpha-deployment-runbook.md) Phase 4 (§ 4.1–4.4)
**Security layer:** [alpha go-live](../../guides/alpha-go-live.md) § 5
**Written from:** knk-workspace `main` `0524d21` plus branch `claude/closed-alpha-readiness-p89505`; knk-plugin `main`
`79be4882`, KNG-182 branch `claude/mc-26.2-upgrade` `88497649`; knk-web-api `master` `2d71155`. NAS state from the
2026-10-18 `knk-ops` snapshot, not re-checked live.

Run this session from the developer's PC on the LAN (Claude Code with the read-only `knk-ops` access) or anywhere
the developer can paste commands into the NAS. The session itself has no NAS access beyond `knk-ops`; it writes
commands, the developer runs them.

```text
Set up the Minecraft service of the Knights & Kings closed-alpha stack on the NAS (Linear KNG-225).

Read completely before acting:
- knk-workspace AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md, docs/ACTIVE_SESSIONS.md
- docs/guides/closed-alpha-deployment-runbook.md (Phase 4 in full, plus the 2026-10-18 host-state section)
- docs/guides/alpha-go-live.md § 5
- docs/guides/nas-ops-access.md (what the read-only knk-ops checks can and can't do)
- docs/reports/2026-10-11-closed-alpha-infrastructure-progress.md § 3 (world sources, staging, image notes)
- docs/reports/2026-10-18-nas-ops-access-and-alpha-check.md (findings A1–A6)
- docs/guides/minecraft-26.3-upgrade-smoke-test.md (what Paper 26.3 does to worlds)

Then refresh knk-workspace, knk-plugin and knk-web-api and check: is KNG-182 merged into knk-plugin main yet?
Has runbook Phase 3b (the KNG-64 API) run? Is anyone else claiming the knk-alpha stack in ACTIVE_SESSIONS.md?
Claim KNG-225 in the tracker, set the Linear issue to In Progress, and use the standing branch
claude/closed-alpha-readiness-p89505 in knk-workspace for doc and report changes.

Working rules
- Give NAS commands for an already-open SSH session, in small blocks with a stop condition and only concise,
  non-secret output requested back. Docker needs sudo on the NAS. Label any Windows PowerShell command.
- Never print or ask for secret values (MySQL passwords, plugin API key, JWT secret, RCON password).
- Never boot from /srv/docker/staging/knk-alpha-20261011/: copy into a new live path. Paper 26.3 converts worlds
  one way; staging plus the archives are the rollback.
- Publish no ports. No router forwards. playit.gg is Phase 5, not this session.
- Back up the host compose.yaml (dated copy) before editing it. Decide with the developer whether Portainer stack 42
  or the host file is authoritative (finding A6) before the first change, and keep the other one in step.

Target (runbook § 4.1–4.3)
- Service minecraft, container_name knk-alpha-minecraft, image itzg/minecraft-server java25 variant pinned by digest.
- TYPE=PAPER, VERSION=26.3, PAPER_BUILD pinned, EULA=TRUE, MEMORY=4G, memory limit about 5 GiB,
  LEVEL=world_KNK-DEV (keep the dev level name: Domains store their world name, KNG-111),
  ONLINE_MODE=TRUE, ENABLE_WHITELIST=TRUE, ENFORCE_WHITELIST=TRUE.
- Autostart: restart unless-stopped, stop_grace_period 2m, image health check; confirm Docker is enabled at boot.
- Console: RCON inside the container only, RCON_PASSWORD_FILE from a new mode-600 secret file; stdin_open and tty.
  Console = rcon-cli via Portainer's container console, or sudo docker exec -it knk-alpha-minecraft rcon-cli.
- Networks: knk-alpha_backend plus a new egress network (Mojang session servers, Paper download). No depends_on on
  the API.
- /data = a new host directory under /srv/docker/stacks/knk-alpha/ holding a copy of the staged main world
  (world_KNK-DEV with nether/end), knk_hub next to it, and the snapshot's plugin data
  (plugins/WorldGuard/worlds/ must stay with the world it belongs to).
- Plugins: replace the 1.21.10 jars with the 26.3 builds of FastAsyncWorldEdit 2.16.1 and WorldGuard 7.0.20 (the
  same builds as the dev server DEV_SERVER_26.3); drop AutoPluginLoader. The KnK jar is always installed as
  plugins/KnightsAndKings.jar. Keep releases/plugin/<commit>/ (jar, SHA-256, commit) root-owned beside the stack.

Order of work
1. Preflight with knk-ops (containers, network, secret-files, compose) and disk space for a ~7 GiB world copy.
2. Stage 1, no KnK plugin: create the live copy, the RCON secret, the service and the egress network; start it.
   Expect the one-time 26.3 world conversion (a 30 s "World storage migration is required" warning). Check: the
   main world loads, rcon-cli works both ways, health is healthy, no published ports, CPU/memory next to Frigate.
   Then reboot test: sudo systemctl restart docker (or a NAS reboot the developer schedules) and confirm it comes
   back on its own.
3. Stage 2, KnK plugin. Only after Phase 3b has run, or after the developer explicitly chooses a disposable
   rehearsal against the pre-KNG-64 17ee730a API on the placeholder database (the infrastructure handoff says not
   to connect the plugin to that API otherwise; record the choice).
   - Build the jar from the newest accepted revision: knk-plugin main if KNG-182 has merged, otherwise
     claude/mc-26.2-upgrade. JDK 25 toolchain: ./gradlew :knk-paper:shadowJar -x deployToDevServer
     (CI runs Gradle on Java 21 with the 25 toolchain, see .github/workflows/build.yml). Record commit + SHA-256.
   - Copy it to releases/plugin/<commit>/ and install as plugins/KnightsAndKings.jar.
   - Set config.yml per alpha go-live § 5: api.base-url http://api:5000/api, auth type apikey with the plugin key
     from the existing secret (via a reviewed mechanism that doesn't print it), allow-untrusted-ssl false,
     region-http 0.0.0.0:8081 (never published), web.public-url https://app.knightsandkings.net.
     The API needs MinecraftPlugin__BaseUrl=http://minecraft:8081 (part of Phase 3b config).
   - Restart. Check: RegionHttpServer line, /knk health UP, no 401/403 in the API log, knk_hub imported into
     world_KNK-DEV/dimensions/minecraft/knk_hub/, hub loads on start and fails closed when missing (KNG-114).
4. Update path: build a second jar (any later commit, or the same commit rebuilt), put it in
   plugins/update/KnightsAndKings.jar, rcon-cli save-all flush, restart the container, and confirm from the
   startup log that the new build loaded and plugins/update/ is empty. If Paper 26.3 doesn't swap it, stop and
   report; don't fall back to replacing the jar of a running server.
5. Acceptance: runbook Phase 4 "Private acceptance" list, every item, with evidence.

Finish
- Write a dated report docs/reports/2026-10-<dd>-minecraft-container.md: image digest, Paper build, jar commit +
  SHA-256, Compose hash before/after, live data path, what passed, what didn't.
- Update the runbook Phase 4 status in place, the tracker row, and KNG-225 (In Review until the developer has
  joined and played; Done when they say so). File anything found in passing as a Linear issue.
- Next step for the developer: runbook Phase 5 (playit.gg; play.knightsandkings.net as a DNS-only record in
  Cloudflare DNS).
```

## Notes for the developer

- **What "remote console" means here:** a console from anywhere on the LAN (Portainer or SSH). Off-LAN access
  needs either your SSH route or a new Access-protected web console, which is a separate decision.
- **Plugin updates after this session:** build or download the jar, put it in `releases/plugin/<commit>/`, copy it
  to `plugins/update/KnightsAndKings.jar`, then `save-all flush` and restart (runbook § 4.3). Stage B operations
  (`nas-ops-access.md` § 7) and CI artifacts (KNG-226) automate this later.
