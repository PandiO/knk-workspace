# Guides

Use [documentation maintenance](developer/DOCUMENTATION_MAINTENANCE.md) when a feature changes. The [feature register](../FEATURE_REGISTER.md) says whether the underlying feature is on trunk and whether it has been tested live. A guide can describe a workflow accurately at the time it was written yet still predate later changes; check its date and feature plan.

## Developers and operators

| Guide | Use | Coverage note |
|---|---|---|
| [Documentation maintenance](developer/DOCUMENTATION_MAINTENANCE.md) | What to update at implementation, merge and live test | Current project-wide process |
| [Production installation](production-installation.md) | Set up a production host: MySQL, API, web app, Paper server, secrets, seed data, CI/CD plan, first-run checklist | **Draft v1 (2026-10-07), KNG-64 security update 2026-10-08**; DB/API/seed/nginx steps rehearsed in a scratch environment, Paper and CI/CD untested. Re-check its § 2 gaps and the seed table manifest after each trunk merge |
| [Closed alpha go-live](alpha-go-live.md) | Host the closed alpha on the NAS behind Cloudflare Tunnel + Access: compose, nginx, tunnel, allow-list, plugin, first admin, go-live checklist, tester invite | **Draft v1 (2026-10-08)**; requires the KNG-64 hardening merged; not yet followed on the real NAS |
| [Code map](developer/CODEMAP.md) | Find component code | Verify paths against each current default branch |
| [Commit conventions](developer/GIT_COMMIT_CONVENTIONS.md) | Commit format | Current convention; branch rules live in `ACTIVE_SESSIONS.md` |
| [API reading](web-api-reading-guide.md) / [web app reading](web-app-reading-guide.md) | Orient a contributor | Refresh when architecture changes |
| [Siege scenario authoring](authoring-a-siege-scenario.md) | Configure a Siege scenario | Check current form rules and the [siege plan](../specs/siege-minigame/IMPLEMENTATION_PLAN.md) before live use |
| [Documentation audit](v3-documentation-audit-instructions.md) / [codebase scan](v3-codebase-scan-instructions.md) | Historical audit instructions | Reports are snapshots, not current feature status |
| [AI feature implementation workflow](developer/AI_FEATURE_IMPLEMENTATION_WORKFLOW.md) | Older phase template | Its `docs/features/` paths are superseded; read the current-path banner first |

## Players and admins

| Guide | Use | Coverage note |
|---|---|---|
| [Commands](users/commands.md) | In-game command reference | **Needs reconciliation** against current plugin command catalog before being treated as complete |
| [User manual](users/handleiding.md) | General player orientation | **Needs a V3 content review** before publication |
| [Account management](users/PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md) | Player account/linking flow | Compare with current auth implementation before publication |
| [Siege scenario authoring](authoring-a-siege-scenario.md) | Admin setup | Feature-specific guide exists; add deployment/config changes at merge |

The player and admin guides do **not yet cover all V3 features**. In particular, current guides need dedicated or refreshed instructions for currency, discoveries, lootboxes, kits, menus, ranks and staff moderation. Feature owners should add or update those guides with their next relevant merge, using the minimums in [documentation maintenance](developer/DOCUMENTATION_MAINTENANCE.md). Future statistics, friends and NPC modes need guides as part of their implementations, not before behavior is decided.
