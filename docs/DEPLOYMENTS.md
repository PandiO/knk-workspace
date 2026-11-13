# Deployment log

**Status:** Current · **Last updated:** 2026-11-13 (first version: structure, back-fill of the knk-alpha deploys the dated reports record, PandiO/knk-workspace#303)
**Sources:** the dated deploy reports in [`reports/`](reports/) (cited per row), the component repos' git history and tags
**Related:** [changelog](CHANGELOG.md) (what was merged) · [closed-alpha deployment runbook § Every deploy](guides/closed-alpha-deployment-runbook.md#every-deploy-gate-tags-release-and-log) (how a deploy is recorded) · [NAS operations access § 7](guides/nas-ops-access.md#7-stage-b-delegated-changes-knk-deploy) (`knk-deploy`)

This log says which commit of each component runs where, with which data and configuration. The
[changelog](CHANGELOG.md) says what was merged into the default branches; this file says what was deployed. Add one row
per deploy, newest first, in the same change as the deploy's dated report (or, for a small deploy, instead of one).

## How to fill in a row

| Column | What goes in it |
|---|---|
| Date | UTC date of the deploy (time if there was more than one that day) |
| Env | `knk-alpha` (the NAS closed alpha) or `dev` (the developer's dev server) |
| API · Web · Plugin | The deployed commit (8 characters) of knk-web-api, knk-web-app and knk-plugin, with the release tag when there is one (`v0.2` = `1a2b3c4d`). `—` = unchanged by this deploy |
| Data | Seed commit (`knk-dev-db-seed`) or content patch applied; `—` = none |
| Migrations | Migrations applied and the total after, as `knk-ops db-summary` reports it |
| Config | Plugin `config.yml` keys merged by hand ([plugin configuration reference § 2](guides/admin/plugin-configuration.md)), API settings, Compose changes. "None merged" when new keys run on the jar's defaults |
| Scripts | One-time scripts run (`scripts/maintenance/…`) |
| Checked | Who checked what (the `knk-ops` checks, in game, in the browser) |
| Rollback | What undoes it: snapshot name, `ssh knk-deploy rollback`, the previous image or jar |
| Source | The dated report, or the GitHub Release of the deploy |

No secrets, LAN addresses or private hostnames in this file: knk-workspace is public
([maintenance guide § Addresses and hostnames](guides/developer/DOCUMENTATION_MAINTENANCE.md#addresses-and-hostnames)).

## knk-alpha

### Current state

**To be confirmed by the developer.** The last deploy on record is 2026-11-02. If nothing was deployed since, the
alpha runs:

| Component | Commit | Since | Source |
|---|---|---|---|
| knk-web-api | `8df59b75` (image `knk-web-api:alpha-8df59b75`), 102 migrations | 2026-11-01 | [2026-11-01 report](reports/2026-11-01-alpha-update-trunk-heads.md) |
| knk-web-app | `1c9524d0` (image `knk-web-app:alpha-1c9524d0`) | 2026-11-02 | [2026-11-02 report](reports/2026-11-02-alpha-web-image-permissions-fix.md) |
| knk-plugin | `c8232607` (jar `e92afe2f…`) | 2026-11-01 | [2026-11-01 report](reports/2026-11-01-alpha-update-trunk-heads.md) |
| Data | seed `4abf42c` (2026-10-24) + content patch `alpha-patch-20261101.sql` (from seed `4cc1263`) | 2026-11-01 | [seed import](reports/2026-10-24-alpha-seed-import.md), [2026-11-01 report § 4](reports/2026-11-01-alpha-update-trunk-heads.md#4-content-patch-from-the-1-nov-seed) |
| Compose | `2334937f…`; `ALLOW_FLIGHT: "TRUE"` still set unless removed since (2026-10-25 workaround) | 2026-11-02 | [2026-11-02 report](reports/2026-11-02-alpha-web-image-permissions-fix.md), [2026-10-25 report § 4](reports/2026-10-25-alpha-update-api-6f08383d-plugin-ee35fb1d.md#4-later-the-same-day-allow_flight-workaround-developer) |

None of these commits has a release tag: they predate the first tags (below). Run `ssh knk-deploy status` to confirm
the images, the live jar hash and the migration count, then replace "to be confirmed" with the date of that check.

### Deploys

Newest first. Rows before 2026-11-13 are back-filled from the dated reports; nothing else records those deploys.

| Date | API | Web | Plugin | Data | Migrations | Config | Scripts | Checked | Rollback | Source |
|---|---|---|---|---|---|---|---|---|---|---|
| 2026-11-02 | — | `1c9524d0` | — | — | — | Compose `97bfb08e…` → `2334937f…` (web image); `knk-deploy` program and web Dockerfile updated (#210) | — | Health by `deploy-web`; logo and landing slideshow by the developer in the browser; `/link` and `/join` fields pending | `ssh knk-deploy rollback` (back to `alpha-b3b415d0`, broken images) | [report](reports/2026-11-02-alpha-web-image-permissions-fix.md) |
| 2026-11-01 | `8df59b75` | `b3b415d0` | `c8232607` | Content patch `alpha-patch-20261101.sql` (`7799dd03…`) from seed `4cc1263` | 5 → **102** | None merged: 7 new `config.yml` keys run on the jar's defaults | — | `knk-ops` status, health, logs, secret scan, Compose; Minecraft startup log. Not checked in game or browser | `ssh knk-deploy rollback` ×3; DB: `knk-alpha-restore 20261101T153532Z-pre-api-8df59b75`; patch: `20261101T160706Z-pre-content-patch` | [report](reports/2026-11-01-alpha-update-trunk-heads.md) (first deploy through `knk-deploy`) |
| 2026-10-25 15:02Z | — | — | — | — | — | Compose `41f7b64a…` → `82def538…`: `ALLOW_FLIGHT: "TRUE"` (workaround, to be removed) | — | Developer | Compose backup `backups/20261025T150142Z/` | [report § 4](reports/2026-10-25-alpha-update-api-6f08383d-plugin-ee35fb1d.md#4-later-the-same-day-allow_flight-workaround-developer) |
| 2026-10-25 ~14:00Z | `6f08383d` | — | `ee35fb1d` | — | none (97) | `Seeding__IncludeExamples: "false"`; new `config.yml` keys none merged (defaults) | `scripts/maintenance/remove-seeded-examples.sql` | Developer: API log, row counts, plugin startup log | Compose backup from S-3 (image `alpha-fa28f7ea`); jar `backups/20261025T140211Z/`; snapshot `pre-6f08383d` | [report](reports/2026-10-25-alpha-update-api-6f08383d-plugin-ee35fb1d.md) |
| 2026-10-25 ~12:55Z | `fa28f7ea` | `0d612702` | — | — | 1 (`TrimDomainNames`) → **97**; see the gap note below | — | — | `knk-ops` health, DB summary, Compose, logs; onboarding endpoint | Compose from `backups/20261025T124007Z/`, `up -d --no-deps api web`; snapshot `20261025T124011Z-pre-fa28f7ea` | [report](reports/2026-10-25-invite-only-register-page.md) |
| 2026-10-24 evening | — | — | — | Seed `4abf42c` (dev export 2026-10-24) and a fresh copy of the dev world | none (95) | — | — | Developer; `/hub` works | Snapshot `20261024T215631Z-pre-seed` | [report](reports/2026-10-24-alpha-seed-import.md) |
| 2026-10-24 | — | — | — | — | — | Phase 9 invite-only switch-over: API registration, invitations, admission and Access-sync settings; plugin `admission:` section; `white-list=false`; `mailrelay` and `cfproxy` containers | — | Developer: smoke test "alpha" sections | Kill switches in [alpha go-live § 11.1](guides/alpha-go-live.md) | [report](reports/2026-10-24-alpha-phase-9-invite-only.md) |
| 2026-10-24 | `a38c8ee9` | `00e4af61` (first web) | — | — | 2 → **95** | Web service, tunnel and forwarded-headers settings (Phase 6) | — | `knk-ops` checks; security probe passed the same day | Pre-migrate dump `alpha-db-pre-a38c8ee9/20261024T150152Z/` | [report](reports/2026-10-24-alpha-phase-6-web-ingress.md), [probe](reports/2026-10-24-alpha-security-probe.md) |
| 2026-10-24 | `4aeb7947` | — | `d56e41da` (first plugin) | — | 11 → **93** | New `config.yml` keys none merged (defaults) | — | `knk-ops` checks; Minecraft startup log | Pre-migrate dump `alpha-db-pre-4aeb7947/20261024T104751Z/` | [report](reports/2026-10-24-alpha-api-4aeb794-and-plugin-stage-2.md) |
| 2026-10-22 | `be9f4e1a` | — | — | — (placeholder copy of dev) | 6 → **82** | KNG-64 API configuration | — | All `knk-ops` checks | Image `alpha-17ee730a` and the pre-migrate dump (`alpha-db-pre-…/knightsandkings_alpha-pre-migrate.sql.gz`) | [report](reports/2026-10-22-alpha-api-kng64-upgrade.md), runbook Phase 3b |
| 2026-10-11 | `17ee730a` (first API) | — | — | Placeholder copy of the dev database | **76** | — | — | Private acceptance (runbook Phase 3.3) | Clean baseline `alpha-db-clean/20261011-004122/` | [progress report](reports/2026-10-11-closed-alpha-infrastructure-progress.md), runbook Phase 3 |

**Gap in the record:** the 2026-10-25 snapshot before `fa28f7ea` already had 96 migrations, with `AddSiegeSkipSeconds`
(timestamp 2026-10-24 22:48) applied, while the seed import the evening before left 95. No report records that step.
The developer may know what it was; until then it stays unrecorded here.

## dev

The developer's dev server runs feature branches and `next` for smoke tests. Its deploys were not recorded before
2026-11-13. From now on, add a row when a smoke test or a developer test depends on what runs there (the smoke test's
report usually names the branch heads; link it).

| Date | API | Web | Plugin | Data | Migrations | Config | Scripts | Checked | Rollback | Source |
|---|---|---|---|---|---|---|---|---|---|---|

## Release tags

Release tags are numbered tags on trunk (global instructions, "Branches" rules 1 and 5), created through each
component repo's Release workflow; a deploy uses the tag. Tags that exist on 2026-11-13:

| Tag | knk-web-api | knk-web-app | knk-plugin | Deployed to knk-alpha |
|---|---|---|---|---|
| `v0.1` (2026-11-13, promotion of `next`) | `6d5e9c17` | `8da55ea7` | no tag (its `next` isn't promoted yet) | not on record |

Earlier alpha deploys are not tagged. How deploy tags and the per-deploy release on knk-workspace are named is an open
decision: [PandiO/knk-workspace#444](https://github.com/PandiO/knk-workspace/issues/444).

## Merged but not deployed

What is on trunk and not on the alpha: compare the current state above with the trunk heads, for example
`git log --first-parent --oneline 8df59b75..origin/master` in knk-web-api, and read the [changelog](CHANGELOG.md)
entries dated after the last deploy. On 2026-11-13 that was 19 first-parent commits in knk-web-api, 37 in knk-web-app
and 17 in knk-plugin.
