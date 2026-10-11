# Handoff: NAS closed-alpha infrastructure

**Date:** 2026-10-11
**Status:** Paused for the night; database complete, API image build is the next command sequence
**Branch:** `codex/closed-alpha-infrastructure-handoff`
**Related issues:** KNG-109, KNG-114, KNG-115
**Progress report:** [`2026-10-11-closed-alpha-infrastructure-progress.md`](../../reports/2026-10-11-closed-alpha-infrastructure-progress.md)
**Runbook:** [`closed-alpha-deployment-runbook.md`](../../guides/closed-alpha-deployment-runbook.md)

## Resume point

The `knk-alpha` MySQL container is healthy and its cleaned database baseline
is backed up. Only `__pandi__` and `admin` remain usable. Main and hub world
archives are verified and staged. The API source archive for merged
`knk-web-api` commit `17ee730a` is uploaded and verified.

The API image is **not built yet**. An earlier command used obsolete commit
path `83fa80b3`; source extraction and Dockerfile creation failed, and Docker
correctly refused the missing build context. The .NET SDK/runtime base images
were pulled successfully. Resume using:

```text
/home/ubuntunas/docker-backups/deployment-sources/knk-web-api/17ee730a/
knk-web-api-17ee730a.tar.gz
```

Do not repeat the failed `83fa80b3` path. An empty build directory for it may
exist and is harmless.

## Verified current state

- NAS SSH commands should be written as commands for the already-open,
  persistent NAS session. Label Windows PowerShell commands explicitly.
- Portainer authoritative instance: Compose-managed `portainer`, volume
  `portainer_data`, host HTTPS port 9444, accessible through
  `portainer.pyth`; stack editing works.
- Retired instance: `portainer-retired-core`, stopped, restart `no`, volume
  `core_portainer_data`.
- Alpha stack path: `/srv/docker/stacks/knk-alpha`.
- Alpha MySQL: `knk-alpha-mysql`, no host port, healthy, database
  `knightsandkings_alpha`, app user `knk_alpha_app`.
- Secrets exist as protected files under
  `/srv/docker/stacks/knk-alpha/secrets/`; never display them.
- Clean alpha dump SHA-256:
  `dd877d5587982d2a31e5b0ec003cec92d47960cfed969f57bdf600b979ed975f`.
- Main archive SHA-256:
  `82b0afca0327f5e499250b7a030783e1c4fe365d0f56f4d5e29f47144533b150`.
- Hub archive SHA-256:
  `43944a03d673d2b6b8e92dfb2f016b389ca414baa135b600519e072f6ccb9cc4`.
- API source archive directory uses short commit `17ee730a`; the operator
  verified its companion checksum and confirmed the commit is on
  `origin/master`.
- Pulled .NET base digests are in the progress report.
- No API, Minecraft, playit, or web-app alpha service has been started.

## Immediate continuation checklist

1. Re-read the report and runbook; inspect current Docker/Portainer state.
2. Read the actual `.sha256` file for the API archive and verify it again.
3. Extract it into `/srv/docker/build/knk-web-api/17ee730a/`; confirm
   `source/knkwebapi_v2.csproj` exists before writing build files.
4. Create the multi-stage .NET 8 Dockerfile and `.dockerignore` in that
   extracted build snapshot.
5. Build and tag `knk-web-api:alpha-17ee730a`; record image inspection output.
6. Stop and report if the build fails. Do not silently switch source commits
   or deploy an unlabelled image.
7. Add only the API service to `knk-alpha`, with private networking and file
   secrets. Do not publish it yet.
8. Verify `/health/live`, `/health/ready`, logs, restart, and DB counts.
9. Back up the database again if API startup seeds change it.
10. Only then proceed to the KnK-owned multiworld loader and Minecraft service.

## Decisions to preserve

- No Multiverse Core; KnK owns minimal multiworld lifecycle/transition logic.
- First deployment remains Paper 1.21.10 / Java 21. Paper 26.2 / Java 25 is a
  later cloned-environment upgrade.
- One Minecraft server, two concurrent worlds: main gameplay plus hub.
- playit.gg is for Minecraft only; public name is intended to be
  `play.knightsandkings.net` via GoDaddy DNS.
- Cloudflare Tunnel/nginx is for the web/API only.
- Alpha MySQL stays private; dev MySQL stays LAN-only.
- Initial Minecraft heap target 1–4 GiB with an approximately 5 GiB container
  limit because Frigate and other services share a 16 GiB host.
- Keep existing backups and retired Portainer state until restore tests and a
  retention decision are complete.

## Prompt for a new session

Copy the following prompt into a new session:

> Continue the Knights & Kings NAS closed-alpha deployment from the durable
> handoff in `knk-workspace/docs/ai-agents/handoffs/2026-10-11-closed-alpha-infrastructure.md`.
> Also read `docs/reports/2026-10-11-closed-alpha-infrastructure-progress.md`,
> `docs/guides/closed-alpha-deployment-runbook.md`, the repository `AGENTS.md`,
> `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`, and the current
> `docs/ACTIVE_SESSIONS.md` before acting. Refresh all repositories and verify
> live state instead of trusting old branch names. The immediate next task is
> to build the API image from the already uploaded and verified source archive
> at `/home/ubuntunas/docker-backups/deployment-sources/knk-web-api/17ee730a/knk-web-api-17ee730a.tar.gz`.
> The previous `83fa80b3` extraction/build did not happen; only the .NET base
> images were pulled. Verify the archive checksum, extract it to
> `/srv/docker/build/knk-web-api/17ee730a/`, confirm the project file exists,
> create the deployment-only multi-stage Dockerfile, build/tag
> `knk-web-api:alpha-17ee730a`, and record the final image ID/labels/digests.
> Then add the API privately to the existing `knk-alpha` stack using the
> protected MySQL app password, plugin API key, and JWT secret files without
> printing their values. Do not expose the API, start Minecraft, alter the
> clean database baseline, delete backups, or remove retired Portainer state
> until the relevant validation step passes. Give NAS commands as commands for
> an already-open persistent SSH session and clearly label any Windows
> PowerShell commands. Preserve these decisions: no Multiverse Core; Paper
> 1.21.10/Java 21 first; one server with main+hub; playit only for Minecraft at
> `play.knightsandkings.net`; Cloudflare/nginx only for web/API; MySQL private.
