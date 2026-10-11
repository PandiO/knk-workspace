# New-session prompt: continue the closed-alpha NAS deployment

**Date:** 2026-10-11
**Status:** Ready to copy into a fresh session
**Canonical handoff:** [closed-alpha infrastructure](2026-10-11-closed-alpha-infrastructure.md)

```text
Continue the Knights & Kings NAS closed-alpha deployment from the durable
handoff in knk-workspace/docs/ai-agents/handoffs/2026-10-11-closed-alpha-infrastructure.md.
Also read docs/reports/2026-10-11-closed-alpha-infrastructure-progress.md,
docs/guides/closed-alpha-deployment-runbook.md, the repository AGENTS.md,
docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md, and the current
docs/ACTIVE_SESSIONS.md before acting. Refresh all repositories and verify live
state instead of trusting old branch names.

The immediate next task is to build the API image from the already uploaded
and verified source archive at:
/home/ubuntunas/docker-backups/deployment-sources/knk-web-api/17ee730a/knk-web-api-17ee730a.tar.gz

The previous 83fa80b3 extraction/build did not happen; only the .NET base
images were pulled. Verify the archive checksum, extract it to
/srv/docker/build/knk-web-api/17ee730a/, confirm source/knkwebapi_v2.csproj
exists, create the deployment-only multi-stage Dockerfile, build/tag
knk-web-api:alpha-17ee730a, and record the final image ID, labels, source hash,
and base-image digests.

Then add the API privately to the existing knk-alpha stack using the protected
MySQL app-password, plugin API-key, and JWT-secret files without printing their
values. Do not expose the API, start Minecraft, alter the clean database
baseline, delete backups, or remove retired Portainer state until the relevant
validation step passes.

Give NAS commands as commands for an already-open persistent SSH session and
clearly label any Windows PowerShell commands. Preserve these decisions:
- no Multiverse Core; KnK owns the minimal multiworld implementation;
- Paper 1.21.10 / Java 21 first; Paper 26.2 / Java 25 later on a clone;
- one Minecraft server with main and hub worlds loaded concurrently;
- playit.gg only for Minecraft, intended public name play.knightsandkings.net;
- Cloudflare Tunnel/nginx only for web/API;
- alpha MySQL private and dev MySQL LAN-only;
- initial Minecraft heap 1–4 GiB, about 5 GiB container limit.
```
