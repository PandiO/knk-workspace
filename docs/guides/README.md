# Guides

Use [documentation maintenance](developer/DOCUMENTATION_MAINTENANCE.md) when a feature changes. The [feature register](../FEATURE_REGISTER.md) says whether the underlying feature is on trunk and whether it has been tested live. A guide can describe a workflow accurately at the time it was written yet still predate later changes; check its date and feature plan.

## Developers and operators

| Guide | Use | Coverage note |
|---|---|---|
| [Documentation maintenance](developer/DOCUMENTATION_MAINTENANCE.md) | What to update at implementation, merge and live test | Current project-wide process |
| [Production installation](production-installation.md) | Set up a production host: MySQL, API, web app, Paper server, secrets, seed data, CI/CD plan, first-run checklist | **Draft v1 (2026-10-07), KNG-64 security update 2026-10-08**; DB/API/seed/nginx steps rehearsed in a scratch environment, Paper and CI/CD untested. Re-check its § 2 gaps and the seed table manifest after each trunk merge |
| [Closed-alpha deployment runbook](closed-alpha-deployment-runbook.md) | The NAS rollout in phases: backups, Portainer, alpha MySQL, API image, Minecraft (main + hub), playit.gg, web ingress, backup automation | **In progress (2026-10-11)**; phases 0–3 done on the NAS, phase 3b (KNG-64 API upgrade) and 4 next |
| [Performance metrics, capacity and NAS-vs-cloud](performance-metrics-and-capacity.md) | Diagnose the container RAM ceiling, collect TPS/MSPT/heap/CPU history (Prometheus, cAdvisor, JFR, spark), run load steps, build scaling curves and acceptance thresholds, decide NAS vs cloud VM | **Draft v1 (2026-10-22)**, [KNG-232](https://linear.app/kngpandi/issue/KNG-232); the plugin/API metric endpoints it uses are unmerged, not yet run on the NAS |
| [Closed alpha go-live](alpha-go-live.md) | The KNG-64 layer on that runbook: required builds, API upgrade and migrations, API/plugin config, nginx + Cloudflare Access, first admin, security probe, go-live checklist, tester invite | **v2, aligned with the runbook 2026-10-11**; not yet followed end to end |
| [NAS operations access](nas-ops-access.md) | Read-only `ssh knk-nas-ops <op>` checks of the alpha stack for agents on the developer PC: security model, files and hashes, revocation, Stage B (deploy) design | **Stage A installed and verified 2026-10-18**; Stage B not installed |
| [Closed alpha hardening smoke test](alpha-hardening-smoke-test.md) | Manual checks of the KNG-64 branches on the dev server: secrets setup, probe, plugin wiring, registration and login, sessions, roles, landing, seed export | **Passed 2026-10-11** (run 1); phone login and seed import not run |
| [Domain sub-regions smoke test](domain-subregions-smoke-test.md) | Manual checks of domain sub-regions on the dev server: garrison with a cylindrical tower, one domain for messages/access/discovery, flag mirror, door in the tower, orphan and purge, save rules | **Passed 2026-10-23** (developer); merged to trunk ([KNG-259](https://linear.app/kngpandi/issue/KNG-259)) |
| [Form validation smoke test](form-validation-result-log-smoke-test.md) | Manual checks of KNG-186 (step completion conditions run, `isActive` round-trips, export/import) and KNG-269 (one validate-batch per step, results answered from the log with "checked … ago" and Re-check, miss on changed input/rule/region, TTL, plugin down not stored, create mode, readiness live) | **To test (2026-10-24)**; combined test branch `claude/kng-186-269-form-validation` in knk-web-api and knk-web-app (merges the KNG-186 and KNG-269 branches), not merged to trunk |
| [API outage smoke test](api-outage-smoke-test.md) | Manual checks of the game server with knk-web-api stopped: KNG-171 (commands answer at once while the connectivity state is DOWN, permission outcomes unchanged, changes apply after UP) | **To test (2026-10-15)**; written for knk-plugin branch `wt/kng-171`, not merged. Earlier outage checklists (KNG-58, KNG-123, passed) stay in [offline-security-cache.md](../architecture/offline-security-cache.md) § 8 |
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
| [Game Settings](game-settings.md) | Join/leave messages, join spawn, respawn, per-world game mode/time/weather/spawn, per-group overrides, MOTD, weather confirmation ([KNG-52](https://linear.app/kngpandi/issue/KNG-52)) | Current 2026-10-10: describes trunk (merged, live-tested) |
| [Minecraft catalogue](admin/minecraft-catalogue-admin-guide.md) | Server scan of items and blocks, icons and overrides, picker settings (`categoryFilter`), audit and merge, upgrading another environment ([KNG-200](https://linear.app/kngpandi/issue/KNG-200)) | Current 2026-10-22: describes trunk (merged, live-tested) |
| [Domain sub-regions](admin/domain-subregions-admin-guide.md) | Give a domain extra WorldGuard regions (a garrison's round tower): adding, what is copied from the main region, removing and orphans ([KNG-253](https://linear.app/kngpandi/issue/KNG-253)) | Current 2026-10-23: describes trunk (merged, live-tested) |

The player and admin guides do **not yet cover all V3 features**. In particular, current guides need dedicated or refreshed instructions for currency, discoveries, lootboxes, kits, menus, ranks and staff moderation. Feature owners should add or update those guides with their next relevant merge, using the minimums in [documentation maintenance](developer/DOCUMENTATION_MAINTENANCE.md). Future statistics, friends and NPC modes need guides as part of their implementations, not before behavior is decided.
