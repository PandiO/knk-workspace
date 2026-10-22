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
