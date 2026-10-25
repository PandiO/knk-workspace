# knk-alpha API build files (KNG-227, runbook Phase 3b)

Deployment-only files for the NAS `knk-alpha` API. They are copied into
`/srv/docker/build/knk-web-api/<sha>/` next to `source/`, which is a `git archive` of knk-web-api:

| File | Use |
|---|---|
| `Dockerfile` | Targets `runtime` (default, runs as `KNK_RUNTIME_UID`/`GID`, default 2002) and `migrator` (SDK + `dotnet-ef` 9.0.10, one-off `dotnet ef database update`). Base images pinned by digest, as in Phase 3.1 |
| `migrator-entrypoint.sh` | Reads `mysql_root_password` and `jwt_secret` from `/run/secrets/` and runs the migration. The app's startup checks need a JWT secret even at design time. Root until KNG-242 adds a migrator account |
| `compose.api-service.yaml` | The `api` service block of the stack's `compose.yaml` for this build (it replaces the old block between `  api:` and `  minecraft:`) |
| `appsettings.Production.json` | Mounted read-only at `/app/appsettings.Production.json`. It sets log levels (finding A5). Environment variables can't do this: the `/bin/sh` entrypoint drops variable names that contain dots, such as `Logging__LogLevel__Microsoft.EntityFrameworkCore` |

The runtime entrypoint (`docker-entrypoint.sh`, secret files → configuration) is the one accepted in Phase 3.1. It is
copied unchanged from `/srv/docker/build/knk-web-api/17ee730a/`.

Rehearsed on 2026-10-22 in a scratch Docker host against an empty MySQL 9.6.0 (same digest):
- both targets build;
- the migrator applies all 82 migrations (137 base tables, 4 triggers);
- the API becomes healthy as `2002:2002` with `cap_drop: ALL`;
- `Host: 127.0.0.1`/`api`/`app.knightsandkings.net` return 200 and any other host returns 400;
- anonymous `/api/users` returns 401;
- a restart reports zero seed creates;
- the logs contain no secret values.

Report: `docs/reports/2026-10-22-alpha-api-kng64-upgrade.md`.

Deployed builds:
- `be9f4e1a` on 2026-10-22 (KNG-227);
- `4aeb7947` on 2026-10-24 (KNG-275), [report](../../docs/reports/2026-10-24-alpha-api-4aeb794-and-plugin-stage-2.md).
  From this build the API refuses the Log mail transport outside Development, so the Compose block sets
  `Email__Transport=Log` with `Email__AllowLogTransport=true` until the mail relay (KNG-211) exists.
- `fa28f7ea` on 2026-10-25 (invite-only onboarding, `GET api/Auth/onboarding-info`), [report](../../docs/reports/2026-10-25-invite-only-register-page.md).
- `6f08383d` on 2026-10-25 (`Seeding__IncludeExamples=false`, example rows removed once), [report](../../docs/reports/2026-10-25-alpha-update-api-6f08383d-plugin-ee35fb1d.md).
  The stack folder is root-only: run compose as `sudo bash -c "cd /srv/docker/stacks/knk-alpha && docker compose …"`.
- Phase 9 E0 (KNG-211, 2026-10-24): same image, mail through `mailrelay` (`Email__Transport=Smtp`, network `mail`,
  [`scripts/alpha-mail/`](../alpha-mail/README.md)).

For each update:
1. Rehearse it with the previous migrator first, then the new one.
2. Change `compose.api-service.yaml`.
3. After the switch, update `RECORDED_SHA` in `scripts/nas-ops/stage-a/ops/compose` and its NAS copy.
