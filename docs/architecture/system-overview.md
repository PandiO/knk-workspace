# System overview

**Status:** Current · **Last updated:** 2026-11-22 (first version; describes the `main` branches of knk-web-app
`31a6896`, knk-web-api `75b8434` and knk-plugin `2411d78`)

A one-page map for people and agents to read first. The deeper documents are linked at the end.

## 1. The three codebases

| Repo | What it is | Stack | Size (tracked files) |
|---|---|---|---|
| `knk-web-app` | Staff and player website: dashboards, forms, profiles | React 18 + TypeScript, Create React App, Tailwind | ~880 `.ts`/`.tsx` |
| `knk-web-api` | The single source of truth: REST API, auth, permissions, realtime hub | ASP.NET Core .NET 8, EF Core (Pomelo MySQL), SignalR | ~1,590 `.cs` |
| `knk-plugin` | The Minecraft server plugin (Paper 26.3) | Java 25, Gradle multi-module | ~2,460 `.java` |

Also here: `knk-workspace` (all docs, issues, agent skills), `knk-dev-db-seed` (dev database seed),
`knk-v1-archive` / `knk-v2-archive` (read-only legacy code, not built).

## 2. How they connect

```
 browser ──REST (JWT bearer)──▶ knk-web-api ◀──REST (X-API-Key)── knk-plugin
    ▲                              │   │                              ▲
    └──── SignalR /api/hubs/web  ─┘   └── SignalR /api/hubs/game ───┘
                                   │
                                 MySQL
```

- **The web app and the plugin never talk to each other.** Everything goes through the API.
- **Web app → API.** One client class per resource in `src/apiClients/` (78 files), all extending
  `ObjectManager.invokeServiceCall(data, operation, controller, httpMethod)`. The URL is built at run time as
  `<baseUrl>/<controller>/<operation>`, where `controller` comes from the `Controllers` enum in
  `src/utils/enums.ts` (`Controllers.Towns = 'Towns'`) and `operation` is a string or id (`'search'`, `` `${id}` ``).
  So a web-app call names the API endpoint only through these two values, not a literal URL.
- **API routes.** 105 controllers in `Controllers/`, almost all `[Route("api/[controller]")]`, so
  `TownsController` serves `/api/Towns`. Controller → `Services/` → `Repositories/` → EF Core
  (`Properties/KnKDbContext.cs`), with DTOs in `Dtos/` mapped by AutoMapper profiles in `Mapping/`.
- **Plugin → API.** Ports (interfaces) in `knk-core/.../core/ports/api/`, implemented by `knk-api-client/.../api/impl/*ApiImpl`
  (OkHttp, extending `BaseApiImpl`) with literal path constants (`"/Towns/search"`). The Paper module reads them
  through cache-first gateways in `knk-paper/.../paper/dataaccess/DataAccessFactory`.
- **Realtime.** `knk-web-api/Realtime/` publishes entity changes (`RealtimeEntityChangeInterceptor`) to two hubs
  mapped in `RealtimeSetup.cs`: `WebHub` at `/api/hubs/web` (browsers, `src/realtime/`) and `GameServerHub` at `/api/hubs/game` (plugin,
  `knk-api-client/.../api/realtime/`). The plugin also polls `PlayerNotificationsController`.

## 3. Where things live

| Looking for | knk-web-app | knk-web-api | knk-plugin |
|---|---|---|---|
| Entry point | `src/index.tsx`, `src/App.tsx`, `src/routes/` | `Program.cs` | `knk-paper/.../paper/KnKPlugin.java` |
| Feature code | `src/pages/` (+ `admin/`, `auth/`), `src/components/` | `Controllers/`, `Services/`, `Repositories/` | `knk-core/.../core/<feature>/` (logic), `knk-paper/.../paper/<feature>/` (Bukkit) |
| Data shapes | `src/types/dtos/`, `src/types/domain/` | `Dtos/`, `Models/` (EF entities) | `knk-api-client/.../api/dto/` |
| Auth / permissions | `src/contexts/AuthContext.tsx`, `src/utils/tokenService.ts` | `Attributes/` (default-deny filter, `RequirePermission`), `Services/AuthService` | `knk-paper/.../paper/permissions/` |
| Schema changes | — | `Migrations/` | — |
| Config | `src/config/appConfig.ts` | `appsettings*.json` (no secrets, user-secrets) | `knk-paper/src/main/resources/config.yml`, `plugin.yml` |
| Tests | `src/**/__tests__` (Jest), `e2e/` (Playwright, mocked API) | `Tests/knkwebapi_v2.Tests/` (xUnit) | `src/test/` per module (JUnit, MockBukkit), `scenario/` |

Plugin Java packages are `net.knightsandkings.knk.{core,api,paper}`; `...` above stands for
`src/main/java/net/knightsandkings/knk`.

## 4. Conventions worth knowing before you search

- Names line up across repos: `TownsController` (API), `TownClient` + `Controllers.Towns` (web app),
  `TownsQueryApiImpl` + `TownsQueryApi` port (plugin), `TownDto` in all three.
- Every API write needs an explicit access rule or it answers 403 (default-deny, see knk-web-api `CLAUDE.md`).
- Plugin features are split: Bukkit-free logic in `knk-core`, Bukkit glue in `knk-paper`. Tests follow that split.
- Branches: `main` = released, `next` = integrated; feature branches start from `next` (global instructions).

## 5. Deeper documents

[Web API architecture](web-api-architecture.md) · [web-app architecture](web-app-architecture.md) ·
[plugin architecture](plugin-architecture.md) · [plugin API client pattern](plugin-api-client-pattern.md) ·
[API connectivity](api-connectivity.md) · [plugin cache system](plugin-cache-system.md) ·
[legacy code locations](legacy-codebase-locations.md)
