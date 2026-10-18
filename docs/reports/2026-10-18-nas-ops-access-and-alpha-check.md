# NAS ops access and alpha stack check — 2026-10-17/18

**Status:** Complete — Stage A agent access installed and verified; Stage B designed only
**Last updated:** 2026-10-18
**Guide:** [NAS operations access for agents](../guides/nas-ops-access.md)
**Related:** [closed-alpha deployment runbook](../guides/closed-alpha-deployment-runbook.md),
[closed-alpha infrastructure handoff](../ai-agents/handoffs/2026-10-11-closed-alpha-infrastructure.md)

A dated record of one operator session (developer at the NAS console over SSH,
Claude Code in a cloud session writing and reviewing every command). Nothing
in the `knk-alpha` stack, its containers or its database was changed.

## 1. Decisions

- **Agent access to the NAS is LAN-only, from the developer's PC.** The plan
  to let Codex managed cloud environments reach the NAS was dropped: the
  Codex environment exposed no private TCP route even with a Tailscale key,
  and a Cloudflare Access HTTPS gateway was more surface than needed. The
  Tailscale installation and its tailnet were removed.
- **Stage A = nine read-only operations** behind an SSH forced command and
  exact no-argument sudo rules ([guide](../guides/nas-ops-access.md)).
- **Stage B (deploy) stays disabled** until the prerequisites in § 4 are done
  and the design is reviewed again.

## 2. Host changes relevant to the alpha

Changes to the shared NAS that affect how the alpha is reached or operated
(the personal-infrastructure details are kept in the operator's private notes):

- Public HTTP(S) now enters **only** through the Cloudflare Tunnel; the NAS
  has no router port forwards. The runbook's Phase 6 ingress plan relies on
  exactly that.
- Admin accounts are no longer in the `docker` group; every Docker command
  needs `sudo`.
- Tailscale and unused host packages (certbot, a never-used host nginx) were
  removed; nginx keeps running in Docker.
- New system account `knk-ops`, sshd drop-in `60-knk-ops.conf`, sudoers file
  `knk-ops` and the scripts under `/usr/local/libexec/knk-ops/`
  (sources: [`scripts/nas-ops/stage-a/`](../../scripts/nas-ops/stage-a/)).

## 3. Verification evidence

### Access controls

| Test | Result |
|---|---|
| `sshd -T -C` for `knk-ops` vs other users (same OpenSSH 9.6p1 build) | `Match` applies to `knk-ops` only; other users unchanged |
| `ping` from the PC | JSON, rc 0, logged with the PC's address |
| No command, `ping; id`, `/bin/bash`, `network extra`, full wrapper path, `sudo -n /bin/sh`, `docker ps`, `cat` of a secret, `secret-scan; id` | `{"ok":false,"error":"denied"}`, rc 64; journal shows length + hash only |
| TTY, `-W` stdio forward, `-R` remote forward, sftp, password login, login from another source address | refused (rc 255 / `Permission denied (publickey)`) |
| On the NAS as `knk-ops`: sudo with an extra argument, root shell, `docker`, `-E`, reading a secret via sudo or directly, plain `docker ps` | all refused |
| sudo log | only `COMMAND=/usr/local/libexec/knk-ops/ops/<op>` as root, no arguments |
| All nine operations from the PC | rc 0, `ok: true` |

All twelve installed files matched the hashes in
`scripts/nas-ops/stage-a/SHA256SUMS`.

### Alpha stack snapshot (2026-10-18, via the new operations)

- `compose.yaml` still has the recorded sha256 `b4c501ee…e298c`; Portainer
  stack 42 is byte-different but canonically equal.
- `knk-alpha-api`: image `knk-web-api:alpha-17ee730a` (ID `61c7e1f6bd45`),
  user `1000:1000`, healthy, `knk-alpha_backend` only, no port bindings,
  `ASPNETCORE_ENVIRONMENT=Production`, `Security__AllowUnauthenticatedPluginCalls=false`.
- `knk-alpha-mysql`: MySQL 9.6.0 at the recorded digest, healthy, no port
  bindings, log driver `local`.
- `/health/live` and `/health/ready`: 200 / 200.
- Database (placeholder copied from dev): 136 base tables, 0 views,
  4 triggers, 76 migrations (latest `20261010170000_SeedStatisticsStaffNodes`),
  9 users / 2 active, **0 holder-ID clashes** (the 2026-10-12 repair holds).
  MySQL accounts: `knk_alpha_app@%`, `root@%`, `root@localhost`.
- `secret-scan`: clean for all four secrets and both indicators.
- `log-errors` (24 h): 0 error/critical/exception/warning lines in both
  containers; the API wrote 186,482 lines in that window.

## 4. Findings for the alpha (open)

| # | Finding | Why it matters | Proposed fix |
|---|---|---|---|
| A1 | The secret files are owned by UID 1000, which is both the NAS admin account and the API's runtime user. | The admin login can read every alpha secret without sudo, and a container breakout would land as that account. | Build the API image with a dedicated UID that has no host account; give the secret files to it. Stage B prerequisite. |
| A2 | `/srv/docker/stacks/knk-alpha/` is owned by the admin account. | That account can replace the root-owned `compose.yaml`. | Make the stack directory root-owned. Stage B prerequisite. |
| A3 | `root@%` exists; the healthcheck and `db-summary` use root over `127.0.0.1`. | Root login is possible from any container on the backend network (only the API today). | Add a read-only account for checks, then restrict root. |
| A4 | `compose.api.pending.yaml` is an identical leftover. | Confusing during a deploy. | Archive it into a dated backup folder. |
| A5 | The API logs ~186,000 lines a day (EF/request information logs). | Docker's bounded logs may hold less than 24 h, weakening `secret-scan`/`log-errors`; noise. | Lower the log level in the Phase 3b build configuration. |
| A6 | Portainer stack 42 and the host `compose.yaml` both define the stack. | A host-side deploy (Stage B) would leave Portainer's copy stale. | Decide which one is authoritative before Stage B. |

## 5. Next steps

1. Developer: apply the corrected Claude Code permission rules on the PC and
   use Manual mode for NAS work; retest the four Claude Code checks.
2. Resolve A1–A6 together with runbook Phase 3b (KNG-64 API build), which is
   itself waiting for the approved seed/content set.
3. Review the Stage B design in the guide once the real alpha database exists.
