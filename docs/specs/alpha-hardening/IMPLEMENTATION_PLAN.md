# Closed alpha hardening — implementation plan

**Status:** **Implemented and verified locally, awaiting developer review and live test.** PRs: knk-web-api
[#4](https://github.com/PandiO/knk-web-api/pull/4), knk-web-app [#2](https://github.com/PandiO/knk-web-app/pull/2),
knk-plugin [#7](https://github.com/PandiO/knk-plugin/pull/7) (branch `claude/ui-ux-assessment-discussion-66vc2l`;
nothing merged). Verification: [2026-10-08 report](../../reports/2026-10-08-alpha-hardening-verification.md). The
deviations agreed during implementation are listed in the PR descriptions (for example `RequireServiceOrPermissionForWrites`,
the 30 s refresh grace window, web-first registration living in `Auth/register`, the CORS defaults in the Development file).
**Last updated:** 2026-10-08
**Linear:** [KNG-64](https://linear.app/kngpandi/issue/KNG-64) (parent), KNG-65 to KNG-70 (work packages, § 11)
**Sources:**
- [UI/UX assessment](../../reports/2026-10-08-web-app-ux-assessment.md) §§ 3, 12: the findings this plan fixes.
- [Production installation guide](../../guides/production-installation.md) § 2: the deploy gaps G1–G14.
- Code read at knk-web-api `master` `1805cf9`, knk-web-app `main` `84943ff`, knk-plugin `main` `c7d5a1e`.

**Goal:** the API and web app can be reached from the internet for a **closed alpha with a select group of players**,
starting after the weekend of 2026-10-10. This plan lists every change needed for that, and for each one says
**what** changes, **where** (file and symbol), **how it is tested**, and **who verifies it live**.

**Branches:** one branch per repo, `claude/ui-ux-assessment-discussion-66vc2l`, cut from the current default branch
(`master` for knk-web-api, `main` for the other two). Each repo gets one PR. Nothing merges until the developer has run
the live checks in § 9.

---

## 1. Scope

**In scope (alpha blockers)**

- The API authorizes **every** request: a logged-in user or the game server, with explicit rules on every write.
- Player data (emails, permissions) is no longer public. Staff can't escalate their own rights.
- Sessions can be ended: logout, password reset, password change and email change actually revoke tokens.
- Signup proves ownership of the Minecraft account. Players can log in with their Minecraft name **or** email.
- Brute-force and enumeration protection on the auth endpoints.
- Deploy settings: configurable API URL, same-origin cookie, CORS and forwarded headers from config, no committed
  secrets, Production-only error handling.
- The minimum UX for alpha players (§ 7, WP9).

**Out of scope (tracked separately)**

- The wider UX roadmap (assessment §12 phases 2–4).
- The rebrand.
- SignalR (KNG-57).
- The cleanup analysis execution (separate report).
- Email verification: deferred, see D8.

---

## 2. Decisions

These are the developer-approved direction (2026-10-08) and the reversible defaults chosen while planning. The
defaults marked *(default)* need review.

| # | Decision | Why |
|---|---|---|
| D1 | **Registration requires a code from the game server** ("game → web"). The player joins, runs `/account link`, enters the code on the web register page, then sets an email and password. The username is the verified Minecraft name, never typed. | Nobody can claim someone else's Minecraft name (assessment SEC-7). |
| D2 | **Web-first registration (no code) is off**: `Security:Registration:AllowWebFirst=false`. *(default)* | Alpha players play Minecraft anyway. It can be turned on later for marketing sign-ups, as web-only accounts without a Minecraft name. |
| D3 | **Login accepts email or Minecraft username** (case-insensitive). The request field `login` is new; `email` is still accepted. | Developer request. Players think in Minecraft names. |
| D4 | **Refresh tokens are opaque, stored hashed, rotated on every use, and revoked by family.** Reusing a rotated token revokes the whole family. The access token stays a JWT (30 min). | Logout and theft detection (SEC-5, SEC-6). |
| D5 | **`users.TokenVersion`** is carried in every access token as `tv` and checked on each request. It is bumped on password change or reset, email change, deactivation, and "sign out everywhere". | Instant revocation of every session of one user. |
| D6 | **Default-deny for MVC endpoints.** Every action needs the plugin key or a logged-in user unless it has `[AllowAnonymous]`. Every **write** also needs an explicit rule attribute. A write without one is refused at runtime, and a test lists offenders. | Closes SEC-1 and stays closed for new endpoints. |
| D7 | **Two new permission nodes:** `knk.admin.content` (definitions: items, forms/displays, menus, reference data) and `knk.admin.world` (domains, towns, gates, locations, world tasks, workflows). Both are matched by `knk.admin.*` and `*`. | The generic CRUD controllers had no node. These match the roles agreed on 2026-10-08 (Owner, Admin, Moderator, Support, Finance; § 8). |
| D8 | **Email verification is deferred** until after the alpha. Changing your email requires your current password, and the old address gets a notice (when SMTP is configured). | Under D1 the email isn't the identity anchor. Verification needs mail flows and UI. |
| D9 | **Secrets leave the repo.** Dev uses `dotnet user-secrets` (the csproj already has a `UserSecretsId`). Production uses an env file. The API refuses to start outside Development with a missing or placeholder JWT secret. | SEC-11. |
| D10 | **Alpha hosting: the NAS behind Cloudflare Tunnel, with Cloudflare Access in front of the web app.** The web app and API share one origin, `app.knightsandkings.net` (`/api/*` is the API). Move to a VPS (the production guide) before an open beta. *(default, see § 3)* | No open router ports for HTTP, free TLS, and an allow-list of testers as a second wall. |
| D11 | **Fluent UI is removed** from the web app (developer decision, 2026-10-08). It is done in the cleanup work, not in this plan. | Barely used, and it overrides the font. |

---

## 3. Alpha hosting recommendation

**Recommendation: host the closed alpha on the NAS, expose it through a Cloudflare Tunnel, and put Cloudflare Access in front.
Plan the move to a VPS before an open beta.**

```
Player browser ──HTTPS──► Cloudflare edge (TLS, WAF, rate limits, Access allow-list)
                                 │  outbound-only tunnel (no open HTTP ports on the router)
                                 ▼
NAS ── cloudflared ──► web (Caddy/nginx container) ── /        → web app static build
                                                   └─ /api/*  → knk-web-api :5000
                       knk-web-api ──► MySQL (LAN or same NAS, never exposed)
Paper server ──LAN──► knk-web-api :5000 (X-API-Key, no tunnel, no Access)
Minecraft clients ──TCP 25565──► router port-forward ──► Paper   (unchanged; Cloudflare Tunnel can't carry vanilla MC)
```

| | NAS + Cloudflare Tunnel (alpha) | Public VPS (beta and later) |
|---|---|---|
| Cost | already owned; Cloudflare free plan | about €15–40/month |
| Exposure | no inbound HTTP ports; TLS and DDoS filtering at Cloudflare; the home IP stays hidden for web traffic | the server is directly on the internet; needs firewall and fail2ban (guide § 3) |
| Closed-alpha gate | **Cloudflare Access**: testers log in with an email one-time PIN before they even reach the app (free up to 50 users) | the whitelist only |
| Risks | the NAS holds personal data, so isolate it (Docker network, no NAS admin UI through the tunnel, a separate least-privilege user); home upload bandwidth; the Minecraft port still exposes the home IP | uptime and backups are your job, as on the NAS |
| Effort | about 1–2 h: install `cloudflared` as a container, point DNS, create an Access application | the production guide, about 1 day |

**DNS and names** (domain `knightsandkings.net`):

| Name | Points to | Access |
|---|---|---|
| `app.knightsandkings.net` | Tunnel → web container (SPA + `/api/*`) | Cloudflare Access allow-list during the alpha |
| `play.knightsandkings.net` (or `mc.`) | your home IP, DNS-only (grey cloud), port 25565 | Minecraft whitelist |
| `knightsandkings.net` | later the public static site (Astro on Cloudflare Pages) | public |

**Cloudflare Access details:**
- The SPA and `/api/*` share the hostname. The `CF_Authorization` cookie is first-party, so every API call passes Access
  automatically.
- The plugin reaches the API over the LAN, **not** through the tunnel, so Access never blocks it.
- Add a **bypass** policy for `/api/health` only if an external uptime monitor needs it.

**This is defense in depth, not a replacement.** The API must be safe on its own (WP1–WP7), because Access is removed for the open
beta.

The step-by-step setup is in [guides/alpha-go-live.md](../../guides/alpha-go-live.md).

---

## 4. Work packages: knk-web-api

All paths are relative to the knk-web-api root.

### WP1 — Authorization baseline (default-deny)

**1.1 Global caller filter.** Add `Attributes/DefaultCallerRequiredFilter.cs` (an `IAsyncAuthorizationFilter`) and
register it globally in `Program.cs` (`AddControllers(o => o.Filters.Add<DefaultCallerRequiredFilter>())`). It does three things:
1. When the endpoint metadata contains `IAllowAnonymous`, it passes.
2. When `HttpContext.GetKnkCaller()` is neither the plugin service nor a web user, it returns 401 (`PluginServiceAuth.Unauthorized`).
3. On a **non-GET** action with none of `RequirePermission`, `RequireServiceOrPermission`, `RequirePluginService`,
   `RequireServiceSelfOrPermission`, `Authorize` or `AllowAnonymous`, it returns 403
   `{"error":"Forbidden","message":"This endpoint has no access rule."}` and logs an error naming the action.

Minimal APIs (`MapHealthChecks`) are unaffected.

**1.2 Public endpoints (`[AllowAnonymous]`):**
- `AuthController`: `login`, `refresh`, `logout`, `forgot-password`, `reset-password`, `validate-token`, and the new `register`.
- `HealthController` and `HealthCheckController`.
- `UsersController`: `validate-link-code` (changed in WP5) and `check-duplicate` (changed in WP6).

**1.3 Write rules per controller.** New constants go in `Attributes/RequirePermissionAttribute.cs` → `StaffPermissions`:
`ManageContent = "knk.admin.content"` and `ManageWorld = "knk.admin.world"`. Reads (GET) without an attribute stay
"any logged-in user or the plugin" through 1.1, except where this table says otherwise.

| Controller(s) | Writes | Reads (if stricter than "logged in") |
|---|---|---|
| BannerDesigns, BannerLayers, Categories, Tags, Grades, ItemBlueprints, EnchantmentDefinitions, MinecraftBlockRefs, MinecraftEnchantmentRefs, MinecraftMaterialRefs, MenuTemplates, Clans | `[RequireServiceOrPermission(ManageContent)]` on the class | — |
| FormConfigurations, FormSteps, FormFields, DisplayConfigurations, DisplaySections, DisplayFields, EntityTypeConfiguration, FieldValidationRules | `[RequireServiceOrPermission(ManageContent)]` | — |
| FormSubmissionProgress | `[RequirePermission(ManageContent)]` (class: reads and writes; these are staff drafts) | same |
| Domains, Towns, Districts, Structures, Streets, Locations, GateStructures (the open write), GateDoors, WorldTasks, Workflows | `[RequireServiceOrPermission(ManageWorld)]` | — |
| Regions (the open write: `rename`) | `[RequireServiceOrPermission(ManageRegions)]` | — |
| GameSettings (`PUT`, `PUT runtime-worlds`) | `[RequireServiceOrPermission(ServerConfig)]` | — |
| TitleBrackets | `[RequireServiceOrPermission(CurrencyPolicy)]` | — |
| PermissionHolders | `[RequireServiceOrPermission(UserPermissions)]` | `[RequireServiceOrPermission(ManageUsers)]` |
| PermissionGrants, PermissionGroups, UserPermissionGroups | the one open write each → `UserPermissions` / `UserGroups` | GET → `[RequireServiceOrPermission(ManageUsers)]` |
| PlayerNotifications | `[RequirePluginService]` | `[RequirePluginService]` |
| Kits, SiegeLobbies, SiegeScenarios, SiegeTeams (one open write each) | the node the rest of that controller already uses | — |
| AdminClients | replace the never-passing `[Authorize(Policy="RequireAdmin")]` with `[RequirePermission(ServerConfig)]`; delete the `RequireAdmin` policy | — |
| TestDisplay, WeatherForecast | **delete the controllers** | — |
| Users | see WP2 and WP3 | see WP2 |

**1.4 Test.** Add `Tests/.../Security/EndpointAccessRulesTests.cs`. It enumerates actions through reflection over `ControllerBase`
types and asserts that every non-GET action carries a rule attribute or `[AllowAnonymous]`. The allow-list is in the test.
It also asserts that `TestDisplayController` and `WeatherForecastController` don't exist.

### WP2 — User data lockdown

`Controllers/UsersController.cs`:

| Endpoint | New rule |
|---|---|
| `GET /api/Users` (GetAll) | `[RequireServiceOrPermission(ManageUsers)]` |
| `GET /api/Users/{id}` | `[RequireServiceSelfOrPermission(ManageUsers, "id")]` |
| `POST /api/Users/search` | `[RequireServiceOrPermission(ManageUsers)]` |
| `GET {id}/permissions/check`, `GET {id}/permissions/effective` | `[RequireServiceSelfOrPermission(ManageUsers, "id")]`. The web app's staff check calls these for the logged-in user (self). |
| `GET uuid/{uuid}`, `GET username/{username}` | logged-in or plugin (fallback). **The response DTO must not contain `email`**: check `UserSummaryDto` and remove the field, or map to a public summary for non-staff callers. |
| `POST /api/Users` (Create) | `[RequireServiceOrPermission(ManageUsers)]`. Web registration moves to `POST /api/Auth/register` (WP5). |
| `POST link-account` | **remove** (broken: `UsersController.cs:1331` passes `""` as the current password; replaced by WP5). Remove the web client method `authClient.ts:81` and the plugin client method `UserAccountApiImpl.java:106` if it has no callers. |

### WP3 — Permission escalation guard

1. Add `Services/PermissionEscalationGuard.cs` (`IPermissionEscalationGuard`) with:
   - `CanGrantNodeAsync(actorId, targetHolderId, node)`:
     - Refuse when actor = target, unless the actor holds `*`.
     - Refuse when the actor doesn't hold `node`. Use `CheckAsync(actor, node)` with the value as granted; for `*` the actor
       must hold `*`.
     - A **deny** grant (`value=false`) requires the actor to hold the node too.
   - `CanAssignGroupAsync(actorId, targetUserId, groupId)`: the same self rule. The actor must hold **every** node the group grants.
   - The plugin service bypasses the guard. The in-game staff checks happen in the plugin, and the actor is `X-Acting-User-Id`.
2. Use it in:
   - `UsersController` `AssignGroup`, `RemoveGroup`, `GrantNode`, `RevokeNode`.
   - `PermissionGrantsController` writes.
   - `UserPermissionGroupsController` writes.
   A refusal is 403 `{"error":"EscalationRefused","message":"You can't grant a permission you don't have."}` (or the self
   variant).
3. Use the finer nodes: groups → add `[RequirePermission(UserGroups)]`; grants and revokes → add
   `[RequirePermission(UserPermissions)]`. Keep the existing `ManageUsers` attribute, since both must pass.
4. Tests:
   - A moderator with only `knk.admin.user.manage` + `knk.admin.user.perm` can't grant `*` or `knk.admin.config` to anyone.
   - The moderator can't grant to themselves.
   - The owner (`*`) can do both.

### WP4 — Tokens and sessions

1. **Migration `AddRefreshTokensAndTokenVersion`:**
   - Table `refresh_tokens`: `Id` bigint PK, `UserId` FK, `TokenHash` char(64) unique, `FamilyId` char(32), `CreatedAt`,
     `ExpiresAt`, `RevokedAt` NULL, `ReplacedByHash` NULL, `RememberMe` bool, `CreatedByIp` varchar(64) NULL,
     `UserAgent` varchar(256) NULL. Index on (`UserId`, `RevokedAt`).
   - Column `users.TokenVersion int NOT NULL DEFAULT 0`.
   - Model `Models/RefreshToken.cs`, `DbSet` in `Properties/KnKDbContext.cs`, repository `Repositories/RefreshTokenRepository.cs`.
2. **`Services/TokenService.cs`:**
   - The refresh token becomes 32 random bytes, base64url. Only `SHA256(token)` is stored.
   - Access-token claims gain `tv` (TokenVersion) and `sid` (FamilyId).
   - Remove the JWT refresh-token generation.
3. **`Program.cs` JwtBearer `Events.OnTokenValidated`:**
   - Reject a principal that has a `token_type` claim. Refresh JWTs issued before this deploy can no longer be used as
     bearer tokens.
   - Load `(TokenVersion, IsActive, DeletedAt)` through `IUserSessionStateCache`, an in-memory cache with a 60 s TTL that is
     invalidated on bump.
   - Reject the request when `tv` doesn't match or the user is inactive or deleted.
4. **`Services/AuthService.cs`:**
   - `RefreshAsync`:
     - Look up the token by hash.
     - Not found → 401.
     - Revoked → revoke the whole family (reuse detected; log a warning with the user id), then 401.
     - Expired → 401.
     - Otherwise rotate: mark it revoked with `ReplacedByHash` and issue a new token in the same family.
   - `LogoutAsync`: revoke the family of the presented token.
   - New `RevokeAllSessionsAsync(userId, reason)`: bump `TokenVersion`, revoke all of the user's refresh tokens, invalidate
     the cache. Call it from:
     - password change (`UpdateUserAsync`, `UsersController.ChangePassword`)
     - `ResetPasswordAsync`
     - email change
     - user deactivate/delete
     - a new `POST /api/Auth/logout-all` (`[Authorize]`)
5. **`Controllers/AuthController.cs`:**
   - Stop returning `refreshToken` in the JSON body (set it to null; the cookie carries it).
   - Cookie: `HttpOnly`, `Secure` outside Development, `SameSite` from `Security:RefreshCookie:SameSite` (default `Lax`),
     `Path=/api/Auth`.
   - With `rememberMe=false`: **no `Expires`** (a session cookie) and a server-side lifetime of
     `Security:Jwt:SessionRefreshHours` (default 12).
   - With `rememberMe=true`: `RefreshTokenDays` (default 30).
   - The refresh endpoint ignores `refreshToken` in the body outside Development.
6. **Cleanup:** a daily job (reuse the existing hosted cleanup service) deletes refresh tokens 7 days after they expire or are revoked.
7. **Tests:**
   - Refresh-as-bearer → 401.
   - Rotation: an old token gives 401 and revokes the family.
   - Logout revokes.
   - Password change → the old access token gives 401.
   - Deactivated user → the old access token gives 401.

### WP5 — Registration, login by username, account linking

1. **`POST /api/Auth/register`** (`[AllowAnonymous]`, rate-limited) with body `{ linkCode, email, password, passwordConfirmation }`:
   1. Validate the link code (`UserService.ValidateLinkCodeAsync`). It must belong to a **Minecraft account** (UUID set).
   2. That account must not already have a password. If it does → 409 `AlreadyRegistered` ("This Minecraft account already has a
      web login. Log in or reset your password.").
   3. Email format, the duplicate check (409 `DuplicateEmail`) and the shared password policy
      (`PasswordService.ValidatePasswordAsync`).
   4. Consume the code, set the email and password hash, and set `AccountCreatedVia` unchanged.
   5. Respond like login: access token plus refresh cookie, so the player is logged in right away (`rememberMe=false`).
2. **Web-first registration** (`POST /api/Users` without a UUID, from a non-staff caller) → 403
   `{"error":"RegistrationNeedsCode","message":"Join the server and run /account link to get your registration code."}`
   when `Security:Registration:AllowWebFirst` is false.
3. **Username squatting fix:** in `UsersController.Create`, remove the "pre-registered account: link by setting UUID" block
   (`UsersController.cs:393-412`). When the plugin creates a user whose username belongs to a **web-only** account (UUID
   null), it releases the name first: rename the web-only account to `unclaimed-<id>` and write an audit entry
   `UsernameReleased`. Then it creates the Minecraft account normally. A real player can never be attached to someone
   else's pre-registered web account again.
4. **`validate-link-code`:**
   - Returns only `{ isValid, username }`, with no id and no email.
   - **No longer consumes** the code. Check `UserService.ValidateLinkCodeAsync` and add a read-only `PeekLinkCodeAsync` if needed.
   - Rate-limited (WP6).
5. **Login by username:**
   - `AuthLoginRequestDto` gains `login` (string). `email` stays as a fallback.
   - `AuthService.LoginAsync(identifier, …)`: if the identifier contains `@`, look it up by email; otherwise by username
     (case-insensitive, `UserRepository.GetByUsernameAsync` with `ToLower` comparison).
   - Accounts without a password hash fail with the generic message.
6. **`link-minecraft-account`** (logged-in web-only account links a Minecraft account by code): keep it. Add rate limiting.
   It is only reachable for legacy web-only accounts while D2 is off.
7. **Tests:**
   - register OK
   - register with a bad or expired code
   - register on an already-registered account → 409
   - plugin create with a squatted username releases the name
   - login by username and by email
   - web-first create → 403

### WP6 — Account security

1. **Uniform login failures** (`AuthService.LoginAsync`):
   - Verify the password **before** the active check. Inactive or deleted accounts get the same `Invalid credentials.`.
   - For an unknown identifier, run a dummy `BCrypt.Verify` against a fixed hash to equalise timing.
2. **Lockout:**
   - New `Services/LoginAttemptLimiter.cs` (IMemoryCache): after `Security:Lockout:MaxFailures` (5) failures for one account
     within `WindowMinutes` (15), lock it for `LockMinutes` (15).
   - While locked, return 429 `{"error":"TooManyAttempts","message":"Too many attempts. Try again in N minutes."}`.
     Logins aren't checked while locked.
   - A success resets the counter.
3. **Rate limiting** (built-in `Microsoft.AspNetCore.RateLimiting`, partitioned by client IP after forwarded headers, WP7):
   - policy `auth`: 10 requests/min for `login`, `register`, `refresh`, `forgot-password`, `reset-password`, `validate-token`.
   - policy `lookup`: 20 requests/min for `validate-link-code`, `check-duplicate`, `link-minecraft-account`.
   - Rejections return 429 with `Retry-After`. Limits come from config `RateLimiting:*`.
4. **`check-duplicate`:** anonymous callers get only `{ available }` (no `conflictingUserId`); staff and the plugin keep the id.
   Prefer `POST` in the web app. The `GET` stays for the plugin.
5. **Email change** (`AuthService.UpdateUserAsync`):
   - Requires `CurrentPassword`, validates the format and checks duplicates.
   - Calls `RevokeAllSessionsAsync` afterwards. The response carries a fresh access token, so the current tab stays logged in.
   - Sends a notice to the **old** address through the existing mail delivery service, best-effort and logged.
6. **One password policy** for `Auth/update`, `Users/{id}/change-password`, reset and register: `PasswordService.ValidatePasswordAsync`.
7. **Forgot-password:**
   - Reset mail goes through a background queue, so SMTP failure doesn't change the response (SEC-13).
   - `debugResetToken` is only returned when Development **and** the caller is loopback.

### WP7 — API deployment settings

1. **Secrets out of git (D9):**
   - `appsettings.json` keeps keys with **empty** values: `ConnectionStrings:MySqlDbConnection`, `Security:Jwt:Secret`,
     `Email:SmtpPassword`.
   - `appsettings.Development.json` keeps no secrets either.
   - Startup (`Program.cs`): outside Development, fail fast when the JWT secret is empty, shorter than 32 characters, or equal to
     a value that was ever committed. The check compares a SHA-256 of the value against a short list in code. Fail fast too when
     the connection string is empty.
   - In Development, print a one-line hint: `dotnet user-secrets set "ConnectionStrings:MySqlDbConnection" "…"`.
   - **The developer rotates the dev DB password** (it was in git), and sets user-secrets on each dev machine.
2. **CORS:** `Cors:AllowedOrigins` (string array). The default is the current localhost list. Production behind the same origin
   needs none.
3. **Forwarded headers:**
   - `ForwardedHeaders:Enabled` (default false).
   - When enabled, `UseForwardedHeaders` with `X-Forwarded-For` and `X-Forwarded-Proto`. `KnownProxies` come from
     `ForwardedHeaders:KnownProxies` (default `127.0.0.1`, `::1`); add the Docker network if cloudflared or nginx runs in a
     container.
   - With Cloudflare, also map `CF-Connecting-IP` (`ForwardedHeaders:ForwardedForHeaderName=CF-Connecting-IP`).
4. **Errors:**
   - Outside Development: `UseExceptionHandler` with ProblemDetails `{type,title,status,traceId}` and no exception text.
   - Replace the controller code that returns `ex.InnerException?.Message` or `ex.Message` on 500
     (`TownsController.cs:90`, `DistrictsController.cs:90`, `LocationsController.cs:89`,
     `FieldValidationRulesController.cs` ×5, `FormSubmissionProgressController.cs:85`, `RegionsController.cs:63`) with a
     generic message plus a logged error.
5. **Plugin region calls:** `Services/RegionService.cs` sends `X-API-Key: Security:PluginApiKey` to `MinecraftPlugin:BaseUrl`
   (matches WP10.1).
6. **`appsettings.json` default `Urls`:** `http://127.0.0.1:5000`, so it is loopback only unless overridden. Today the fallback
   in `Program.cs:44-46` is `0.0.0.0:5000`. Change that fallback.
7. **Docs:** update `CLAUDE.md` (dev secrets setup, new nodes, the default-deny rule) and the production guide (§ 10).

---

## 5. Work packages: knk-web-app

Paths are relative to `knk-web-app/src/`.

### WP8 — Security and configuration

1. **No secrets in the console:**
   - Remove the request and response logging in `services/serviceCall.ts:112-113` and `apiClients/objectManager.ts:23`, and the
     email logging in `components/auth/LoginForm.tsx`.
   - Keep error logging, but redact the `Authorization` header and bodies.
   - Add an ESLint `no-console` rule (warn) for `services/`, `apiClients/` and `components/auth/` in the `eslintConfig` block of
     `package.json`.
2. **API base URL (G1):**
   - `config/appConfig.ts` reads `process.env.REACT_APP_API_BASE_URL`.
   - The default is `/api` in production builds and `http://localhost:5294/api` in development (`process.env.NODE_ENV`).
3. **Auth client:**
   - `services/authService.ts` and `apiClients/authClient.ts`: login sends `{ login, password, rememberMe }`.
   - Register calls `POST Auth/register`.
   - Remove `linkAccount` (`link-account`).
   - All auth calls use `credentials: 'include'`. Check `serviceCall.ts` fetch options.
   - Stop reading or storing a `refreshToken` from response bodies.
4. **Session expiry (AUTH-3):**
   - One wrapper in `serviceCall.ts`: on 401 from a non-auth endpoint, call `Auth/refresh` once. The call is single-flight:
     concurrent 401s wait for the same refresh.
   - Then retry the request. If the refresh fails, clear the session and redirect to `/auth/login?returnTo=<path>&reason=expired`,
     which shows a "Your session expired" banner.
   - `hooks/useStaffAccess.ts`: tell "denied" (403) apart from "error or 401". Don't show "Staff only" for an expired session.
5. **Remember me:**
   - Unchecked by default (`LoginForm.tsx`).
   - Registration no longer forces it (`authService.ts:36`).
   - The access token goes in `sessionStorage` unless remember-me is checked (unchanged).
6. **Logout:** clear local state in a `finally`, even when the API call fails (`authService.ts:42-45`).

### WP9 — Alpha UX minimum

1. **Staff-only routes:** `/dashboard`, `/forms`, `/forms/:entityName`, `/forms/:entityName/edit/:entityId`,
   `/display/:entityName/:id` and the builders use `StaffRoute` with `node="knk.admin.content"` (`App.tsx`). The nav shows
   Dashboard/Forms/Create New only to holders of that node (`components/Navigation.tsx`).
2. **Landing after login:**
   - Go to `returnTo` or `location.state.from` when present. Only accept same-origin paths starting with `/`.
   - Otherwise staff with `knk.admin.content` go to `/dashboard`, and everyone else goes to `/account`
     (`pages/auth/LoginPage.tsx`, `components/auth/LoginForm.tsx`).
   - A logged-in user who opens `/auth/register` is redirected to `/account`.
3. **Login form:** the label reads "Email or Minecraft name", with `autocomplete="username"` and `type="text"`.
4. **Registration (D1):** replace the 3-step form with:
   1. **Code.** The help text says: "Join `<server address>`, type `/account link`, and enter the 8-character code".
      `POST validate-link-code` then shows "This code belongs to **<MinecraftName>**".
   2. **Email and password**, with the strength meter and confirmation.
   3. **Done.** The player is logged in and lands on `/account`.
   Remove the Minecraft-username field and the unreachable `RegisterSuccessPage` route. Show a field-level error for
   `DuplicateEmail` and `AlreadyRegistered`.
5. **Account linking text:** one direction everywhere (game → web). `AccountManagementPage.tsx` keeps "paste a code from
   `/account link`" only for web-only (legacy) accounts and says nothing contradictory. Remove the `handleGenerateLinkCode` alias.
6. **Logout:**
   - The account menu opens on **click** (not hover), with `aria-haspopup`, `aria-expanded`, Escape and outside-click close, and
     focus moved into the menu (`Navigation.tsx:263-268`).
   - The account icon no longer navigates by itself.
   - Add a **Log out** button on `AccountManagementPage`.
7. **Identity basics:**
   - `public/index.html`: title "Knights & Kings", a real description, `theme-color #000000`.
   - `public/manifest.json`: names "Knights & Kings".
   - Favicon and `logo192/512` generated from the K&K shield logo (self-hosted under `public/`, replacing the Dropbox hotlink
     in `Navigation.tsx:218`).
   - `document.title` per page via a small `usePageTitle` hook on the main pages.
8. **Landing page:**
   - Replace the template copy: "Knights & Kings — a medieval-fantasy MMO on Minecraft", one line on towns, sieges and
     progression, and a "Closed alpha" badge.
   - **Server address** with a Copy button, from `REACT_APP_MC_SERVER_ADDRESS` (default `play.knightsandkings.net`).
   - "How to join" in three steps: join the server, `/account link`, register.
   - Remove the fake photo-upload modal.
   - Recompress `public/images/1-9.jpg` to ≤1920 px wide (about 250 KB each) and render only the current and next slide.
9. **404 route:** `path="*"` → a simple Not Found page with links home and to the account page.

---

## 6. Work package: knk-plugin

### WP10 — Game-server hardening

1. **`paper/http/RegionHttpServer.java`:**
   - Bind to `region-http.bind-address` (new config, default `127.0.0.1`) instead of all interfaces.
   - If `api.auth.api-key` is set, require `X-API-Key` to match (constant-time compare); otherwise answer 401.
   - Log the bind address at startup.
2. **`config.yml`:** `allow-untrusted-ssl: false` (G8). Add `region-http.bind-address: "127.0.0.1"` and
   `web.public-url: ""` (for messages).
3. **`/account link` (`commands/AccountLinkCommand.java`):**
   - **Stop logging the generated code** (`plugin.getLogger().info("Link code generated for …: CODE")`). The code is a
     credential.
   - The success message tells the player where to use it: "Go to `{url}/auth/register` (new) or your Account page and enter
     `{code}`" (`{url}` from `web.public-url`). Add a `messages.link-code-generated` default with `{url}`.
4. **First join (`user/UserManager.java`):** no code change is required. The API now releases a squatted username (WP5.3).
   Keep the existing `getByUsername` path.
5. **Client cleanup:** remove `UserAccountApi.linkAccount` (`/Users/link-account`) if it is unused (WP2).
6. **Tests:**
   - `RegionHttpServer` refuses without the key and binds to the configured address (unit-level: the handler auth check).
   - `./gradlew test` is green.

---

## 7. Configuration reference (new or changed keys)

**API (`appsettings.json` defaults; production values go in the env file, `__` for `:`)**

| Key | Default | Production (alpha) |
|---|---|---|
| `Urls` | `http://127.0.0.1:5000` | `http://0.0.0.0:5000` inside the container (published only to the Docker network) |
| `Security:Jwt:Secret` | *(empty)* | `openssl rand -base64 48` |
| `Security:Jwt:AccessTokenMinutes` | 30 | 30 |
| `Security:Jwt:RefreshTokenDays` | 30 | 30 |
| `Security:Jwt:SessionRefreshHours` | 12 | 12 |
| `Security:RefreshCookie:SameSite` | `Lax` | `Lax` (same origin) |
| `Security:Registration:AllowWebFirst` | false | false |
| `Security:Lockout:MaxFailures` / `WindowMinutes` / `LockMinutes` | 5 / 15 / 15 | same |
| `RateLimiting:Auth:PermitPerMinute` / `RateLimiting:Lookup:PermitPerMinute` | 10 / 20 | same |
| `Cors:AllowedOrigins` | localhost list | *(empty: same origin)* |
| `ForwardedHeaders:Enabled` | false | **true** |
| `ForwardedHeaders:KnownProxies` | `127.0.0.1;::1` | plus the web container's Docker IP or network |
| `ForwardedHeaders:ForwardedForHeaderName` | `X-Forwarded-For` | `CF-Connecting-IP` behind Cloudflare |
| `ConnectionStrings:MySqlDbConnection` | *(empty)* | the `knk_app` user (guide § 4.3) |
| `Security:PluginApiKey` | *(empty)* | `openssl rand -hex 32`, identical in the plugin |

**Web app (build time)**

| Variable | Default | Alpha |
|---|---|---|
| `REACT_APP_API_BASE_URL` | dev `http://localhost:5294/api`, prod `/api` | `/api` |
| `REACT_APP_MC_SERVER_ADDRESS` | `play.knightsandkings.net` | your Minecraft address |

**Plugin (`config.yml`)**

| Key | Default | Alpha |
|---|---|---|
| `api.allow-untrusted-ssl` | **false** | false |
| `api.auth.api-key` | "" | the API's `Security:PluginApiKey` |
| `region-http.bind-address` | `127.0.0.1` | `127.0.0.1` (or the Docker host IP if the API container must reach it) |
| `web.public-url` | "" | `https://app.knightsandkings.net` |

---

## 8. Roles (approved 2026-10-08)

These are permission **groups** created in the web app, not code. Suggested nodes for the alpha:

| Role | Nodes |
|---|---|
| Owner | `*` (you, plus an emergency second owner in the vault) |
| Admin | `knk.admin.*` |
| Moderator | `knk.admin.user.manage`, `knk.admin.user.group`, `knk.freeze`, `knk.unfreeze`, `knk.pmlog.read`, plus the in-game moderation nodes |
| Support | `knk.admin.user.manage`, `knk.admin.currency.history`, `knk.kit.give` |
| Finance | `knk.admin.currency.*` |

WP3 makes this safe: a Moderator can only hand out nodes they hold themselves, and never to themselves.

---

## 9. Verification

**Automated (each PR):**
- API: `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` (with the same 4 pre-existing failures as `master` at most).
- Web: `npm run test:ci` and `CI=false npm run build`.
- Plugin: `./gradlew test`.

**Probe script:** [`scripts/security/alpha-probe.sh`](../../../scripts/security/alpha-probe.sh) `<base-url>` runs the
assessment's live checks against a running API. Every line must say `PASS`:
- anonymous `GET /api/Users` → 401
- anonymous `PUT /api/GameSettings` → 401
- anonymous `POST /api/Categories` → 401
- `check-duplicate` exposes no id
- `validate-link-code` exposes no email
- a refresh token is not accepted as bearer (needs `--player` credentials)
- logout revokes
- 12 bad logins → 429
- `/api/health` → 200

**Live checks by the developer (dev server, then the alpha host):**
1. The plugin starts with the API key set, `/knk health` is OK, and the cache refreshes.
2. A new Minecraft player joins → `/account link` → registers on the web with the code → lands on `/account` logged in.
3. Log in with the Minecraft name, then log out on a phone.
4. A moderator test account can't grant `*`. The owner can.
5. Change the password in browser B → browser A is logged out on its next request.
6. Region checks from the web app (FormWizard world fields) still work with the key on `RegionHttpServer`.
7. The probe script passes against `https://app.knightsandkings.net` (with an Access service token, or from inside the LAN).

---

## 10. Rollout and rollback

1. Merge the API PR → run `dotnet ef database update` (new migration) → deploy the API.
   - **All existing sessions end.** Old refresh JWTs no longer work, so everyone logs in once.
   - Set the plugin key in **both** places before deploying.
2. Merge the plugin PR → update `config.yml` (`region-http.bind-address`, `web.public-url`) → restart Paper.
3. Merge the web PR → build with `REACT_APP_API_BASE_URL=/api` → deploy.
4. Run the probe script and the live checks.

**Rollback:** revert the API image. The migration only adds a table and a column, so the old API runs on the new schema
(expand-only). Web and plugin roll back independently.

---

## 11. Linear

| WP | Issue |
|---|---|
| Parent | [KNG-64](https://linear.app/kngpandi/issue/KNG-64) |
| WP1–WP3 (authorization, user data, escalation) | [KNG-65](https://linear.app/kngpandi/issue/KNG-65) |
| WP4 (sessions) | [KNG-66](https://linear.app/kngpandi/issue/KNG-66) |
| WP5–WP6 (signup, login, abuse protection) | [KNG-67](https://linear.app/kngpandi/issue/KNG-67) |
| WP7 + hosting guide | [KNG-68](https://linear.app/kngpandi/issue/KNG-68) |
| WP8–WP9 (web app) | [KNG-69](https://linear.app/kngpandi/issue/KNG-69) |
| WP10 (plugin) | [KNG-70](https://linear.app/kngpandi/issue/KNG-70) |
| Related: web app cleanup (D11) | [KNG-71](https://linear.app/kngpandi/issue/KNG-71) |
| Related: realtime channel | [KNG-57](https://linear.app/kngpandi/issue/KNG-57) (SignalR recommendation comment, 2026-10-08) |

---

## 12. After the alpha (not in this plan)

- Email verification (D8).
- Turn on web-first sign-up for marketing, as web-only accounts.
- Move to a VPS (production guide).
- Content-Security-Policy header (needs a CSP-clean build: inline scripts and styles).
- An in-memory access token instead of `localStorage` for "remember me".
- SignalR realtime channel (KNG-57): see the recommendation comment on that issue.
