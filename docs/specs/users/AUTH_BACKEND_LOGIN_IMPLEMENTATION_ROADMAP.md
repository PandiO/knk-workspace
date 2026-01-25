# Auth Backend Login – Implementation Roadmap

**Status**: Planning  
**Created**: January 25, 2026

This roadmap completes the missing authentication endpoints expected by the web app (authClient.ts) and aligns with frontend-auth requirements. It follows the structure of USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md and the workflow in AI_FEATURE_IMPLEMENTATION_WORKFLOW.md.

---

## Phase 1: API Contract & Config

### Priority: CRITICAL – Enables service implementation

#### 1.1 Auth DTOs
- [ ] Add `Dtos/AuthDtos.cs` with:
  - `AuthLoginRequestDto { Email, Password, RememberMe }`
  - `AuthLoginResponseDto { AccessToken, RefreshToken?, ExpiresIn, User: UserDto }`
  - `AuthRefreshRequestDto { RefreshToken? }` (allow cookie fallback)
  - `AuthRefreshResponseDto { AccessToken, RefreshToken?, ExpiresIn }`
  - `AuthValidateTokenRequestDto { Token }` (optional)
  - `AuthValidateTokenResponseDto { Valid, ExpiresAt? }`
- [ ] Ensure no password hash ever returned; reuse `UserDto`.

**File**: `Dtos/AuthDtos.cs`

**Effort**: 45 minutes

---

#### 1.2 JWT Config
- [ ] Add `Security:Jwt:{Issuer, Audience, Secret, AccessTokenMinutes, RefreshTokenDays}` to `appsettings.json` and `appsettings.Development.json`.
- [ ] Document secure defaults (dev secrets placeholder; real secrets via env/config provider).

**Files**: `appsettings.json`, `appsettings.Development.json`

**Effort**: 20 minutes

---

## Phase 2: Token Service

### Priority: HIGH – Required for issuing tokens

#### 2.1 Token Interfaces & Service
- [ ] Create `Services/Interfaces/ITokenService.cs` with methods:
  - `GenerateAccessToken(User user, bool rememberMe)`
  - `GenerateRefreshToken(User user, bool rememberMe)`
  - `ValidateAccessToken(string token)` → principal/claims
  - `ValidateRefreshToken(string token)` → principal/claims
- [ ] Implement `Services/TokenService.cs` using JWT, config-driven expirations, HMAC-SHA256.
- [ ] Include claims: `sub` (userId), `email`, optional roles placeholder.

**Files**: `Services/Interfaces/ITokenService.cs`, `Services/TokenService.cs`

**Effort**: 1.5 hours

---

## Phase 3: Auth Service & Repository Support

### Priority: HIGH – Core auth logic

#### 3.1 Auth Service
- [ ] Add `Services/Interfaces/IAuthService.cs` with methods: `LoginAsync`, `RefreshAsync`, `LogoutAsync`, `GetCurrentUserAsync`.
- [ ] Implement `Services/AuthService.cs`:
  - Lookup user by email (case-insensitive) via `IUserRepository`.
  - Verify password via `IPasswordService` (bcrypt).
  - Enforce account state: reject inactive/soft-deleted; TODO email-verify-after-3-fails.
  - Issue access + refresh tokens via `ITokenService`; rotate refresh on refresh.
  - (Optional) Persist refresh tokens; if not implemented, add TODO + stub for future table.
  - Log success/failure events.

**Files**: `Services/Interfaces/IAuthService.cs`, `Services/AuthService.cs`

**Effort**: 2 hours

---

#### 3.2 Repository Extensions (optional if refresh persistence chosen)
- [ ] Add `IRefreshTokenRepository` with CRUD/revoke for refresh tokens.
- [ ] Implement `RefreshTokenRepository` (EF Core) with token storage (userId, tokenId/jti, expiresAt, revokedAt, replacedBy?).
- [ ] Migration for refresh token table if added.

**Files**: `Repositories/Interfaces/IRefreshTokenRepository.cs`, `Repositories/RefreshTokenRepository.cs`, `Migrations/*` (if created)

**Effort**: 1.5 hours (plus migration time)

---

## Phase 4: Controller & Middleware

### Priority: HIGH – Expose endpoints

#### 4.1 AuthController
- [ ] Add `Controllers/AuthController.cs` (route `api/auth`).
  - `POST login` → `AuthService.LoginAsync`; sets httpOnly secure refresh cookie when rememberMe; returns access token + user.
  - `POST refresh` → `AuthService.RefreshAsync`; rotates refresh; returns new access token; refresh cookie update.
  - `POST logout` → `AuthService.LogoutAsync`; revoke/clear refresh cookie; return 204.
  - `GET me` → `[Authorize]` return current user from `HttpContext.User` via `AuthService.GetCurrentUserAsync`.
  - `POST validate-token` (optional) → simple validity check.
- [ ] Standardize error responses: `401` invalid creds/expired token; `400` bad request; `409` token reuse (if tracked).

**File**: `Controllers/AuthController.cs`

**Effort**: 1.5 hours

---

#### 4.2 Program.cs Wiring
- [ ] Configure JWT bearer authentication (Issuer/Audience/Secret, clock skew minimal).
- [ ] Register `ITokenService`, `IAuthService`, and refresh repo (if used) in DI (`ServiceCollectionExtensions`).
- [ ] Add authentication/authorization middleware to pipeline.

**Files**: `Program.cs`, `DependencyInjection/ServiceCollectionExtensions.cs`

**Effort**: 45 minutes

---

## Phase 5: Validation, Logging, Testing

### Priority: MEDIUM – Quality & safety

#### 5.1 Validation & Policies
- [ ] Add basic throttle/lockout TODO (email verification after 3 failed logins per frontend docs).
- [ ] Enforce `IsActive`/`DeletedAt` guards in login.
- [ ] Ensure passwords validated via existing `PasswordService` rules.

**File**: `Services/AuthService.cs` (validation block)

**Effort**: 30 minutes

---

#### 5.2 Tests
- [ ] Unit tests for `AuthService` (happy path, bad password, inactive user, refresh flow).
- [ ] Integration tests for `AuthController` endpoints (`login`, `refresh`, `me`).
- [ ] Add test helpers for JWT config if needed.

**Files**: `Tests/Services/AuthServiceTests.cs`, `Tests/Controllers/AuthControllerTests.cs` (paths per test project)

**Effort**: 2 hours

---

## Phase 6: Frontend Contract & Client Wiring

### Priority: HIGH – Unblocks UI integration

#### 6.1 DTO/Type Alignment
- [ ] Add/confirm frontend auth DTO types matching backend contract:
  - `AuthLoginRequestDto`, `AuthLoginResponseDto` (accessToken, refreshToken?, expiresIn, user)
  - `AuthRefreshRequestDto`, `AuthRefreshResponseDto`
  - `AuthValidateTokenRequestDto` (optional), `AuthValidateTokenResponseDto`
- [ ] Ensure `UserDto` shape matches backend (EmailVerified, AccountCreatedVia, balances).

**Files**: `Repository/knk-web-app/src/types/dtos/auth/AuthDtos.ts`, `.../UserDtos.ts`

**Effort**: 45 minutes

---

#### 6.2 authClient Updates
- [ ] Point `authClient` endpoints to new backend routes:
  - `POST /api/auth/login`, `POST /api/auth/logout`, `POST /api/auth/refresh`, `GET /api/auth/me`.
- [ ] Remove/disable any temporary stubs; ensure `link-code`, `merge`, `update` still point to UsersController routes if applicable.
- [ ] Standardize error handling to match backend error envelope `{ error, message }`.

**File**: `Repository/knk-web-app/src/apiClients/authClient.ts`

**Effort**: 45 minutes

---

#### 6.3 Token Handling & Services
- [ ] Implement/update `tokenService` to store access token in memory (or storage) and rely on httpOnly refresh cookie set by backend.
- [ ] Update `authService` to: login → store access token; refresh → replace token; logout → clear token; `me` → fetch user and hydrate state.
- [ ] Ensure `rememberMe` flag passes through to login request.

**Files**: `Repository/knk-web-app/src/services/tokenService.ts`, `.../authService.ts`

**Effort**: 1 hour

---

## Phase 7: Frontend UX Flows & Guards

### Priority: MEDIUM – End-user experience

#### 7.1 Auth Hooks & State
- [ ] Update/create `useAuth` and `useAutoLogin` hooks to use new endpoints and token handling.
- [ ] Add loading/error states for login/auto-login and token refresh failures (auto-logout on 401/expired refresh).

**Files**: `Repository/knk-web-app/src/hooks/useAuth.ts`, `.../useAutoLogin.ts`

**Effort**: 1 hour

---

#### 7.2 UI Wiring
- [ ] Update `LoginPage`/`LoginForm` to call `authService.login` with rememberMe and display backend error messages.
- [ ] Ensure `ProtectedRoute` redirects to login on missing/expired token and tries silent refresh once.
- [ ] Update navigation/header to show logout button wired to `authService.logout` and clear local auth state.

**Files**: `Repository/knk-web-app/src/pages/auth/LoginPage.tsx`, `.../components/auth/LoginForm.tsx`, `.../components/ProtectedRoute.tsx`, `.../components/Navigation.tsx`

**Effort**: 1.5 hours

---

## Phase 8: Frontend Validation & Testing

### Priority: MEDIUM – Reliability

#### 8.1 Frontend Tests
- [ ] Add/adjust tests for auth service/hooks (happy path login, bad credentials, refresh failure → logout).
- [ ] Add component tests for `LoginForm` error states and remember-me submission.
- [ ] Add routing guard tests for `ProtectedRoute` (redirects when unauthenticated, allows when token valid or refresh succeeds).

**Files**: `Repository/knk-web-app/src/services/__tests__/authService.test.ts`, `.../hooks/__tests__/useAuth.test.ts`, `.../components/auth/__tests__/LoginForm.test.tsx`, `.../components/__tests__/ProtectedRoute.test.tsx`

**Effort**: 2 hours

---

## Definition of Done
- Auth DTOs present and mapped; no password hash leakage.
- JWT config in place; TokenService issues and validates tokens with correct expirations.
- AuthService handles login/refresh/logout/me with password verification and account-state checks.
- AuthController exposes `/api/auth/login|refresh|logout|me` (and optional validate-token) with consistent error responses.
- JWT authentication wired in middleware; DI registrations complete.
- Tests passing for service and controller happy/negative paths.
- Optional: refresh-token persistence documented or implemented.

## Open Questions / TODOs
- Refresh token storage: implement DB-backed repo now or stub with TODO? (recommend DB for revoke/rotation).
- Lockout/verification policy after failed logins: implement now or defer? (frontend docs note email verification after 3 failed logins).
- Roles/claims model: currently minimal (userId/email); expand later if needed.
- Cookie settings per environment (Secure, SameSite, Domain) to match deployment.
