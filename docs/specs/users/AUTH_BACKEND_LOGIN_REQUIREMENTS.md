# Backend Login & Session – Requirements and Implementation Roadmap

**Purpose:** Fill the missing auth endpoints that the web app (authClient.ts) expects but the API does not yet expose. Derived from `frontend-auth` docs and `USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md`.

## Current Gap
- Frontend expects `/api/auth/{login, logout, refresh, me}`.
- Backend has no `AuthController` and no login/session endpoints; only user CRUD/link-code/change-password/merge in `UsersController`.
- No token issuance/validation or session lifecycle implemented.

## Functional Requirements (Backend)
- **Login (POST /api/auth/login)**
  - Input: `email`, `password`, `rememberMe` (bool).
  - Behavior: verify credentials via bcrypt hash; reject inactive/soft-deleted users; throttle failed attempts (basic counter or TODO).
  - Output: `{ accessToken, refreshToken?, expiresIn, user }`.
  - Errors: `401` invalid credentials; `423` if locked (optional), `400` bad request.
- **Refresh (POST /api/auth/refresh)**
  - Input: `refreshToken` (httpOnly cookie if available per frontend decision: secure httpOnly, 30d when rememberMe).
  - Behavior: validate refresh token, issue new access token; rotate refresh token (invalidate old).
  - Output: `{ accessToken, refreshToken?, expiresIn }`.
  - Errors: `401` invalid/expired; `409` reuse-detected (optional hardening).
- **Logout (POST /api/auth/logout)**
  - Input: optional refresh token (cookie).
  - Behavior: invalidate refresh token (delete/mark revoked); clear cookie; no-op if already invalid.
  - Output: `204`.
- **Me (GET /api/auth/me)**
  - Authenticated; returns current user DTO (no password hash).
- **(Optional) Validate Token (POST /api/auth/validate-token)**
  - Simple validity check for access token; mirrors frontend quick-start mention.

## Non-Functional / Policy
- **Token format:** JWT access tokens; include `sub`=userId, `email`, `roles?`, `exp`.
- **Expiry:** access token short-lived (e.g., 15–30 min); refresh token long-lived (30d when rememberMe else session-length ~1d).
- **Storage:** httpOnly secure cookie for refresh token (per frontend auth quick start); access token returned in body for in-memory use.
- **Password hashing:** use existing `PasswordService` (bcrypt, rounds from config).
- **Account state:** block login if `IsActive == false` or `DeletedAt != null`; optionally require `EmailVerified` after 3 failed logins (future/ TODO).
- **Auditing:** log successful/failed logins and refresh/ logout events (at least info-level).

## DTOs (API Layer)
- **AuthLoginRequestDto**: `email`, `password`, `rememberMe` (bool).
- **AuthLoginResponseDto**: `accessToken`, `refreshToken?`, `expiresIn`, `user: UserDto`.
- **AuthRefreshRequestDto**: `refreshToken?` (allow cookie fallback).
- **AuthRefreshResponseDto**: `accessToken`, `refreshToken?`, `expiresIn`.
- **AuthMeResponseDto**: `user: UserDto`.
- **AuthValidateTokenRequestDto** (optional): `token`.
- **AuthValidateTokenResponseDto**: `valid` (bool), `expiresAt?`.

## Service Layer Requirements
Add `IAuthService` / `AuthService`:
- `Task<(bool ok, AuthLoginResponseDto? result, string? error)> LoginAsync(string email, string password, bool rememberMe)`.
- `Task<(bool ok, AuthRefreshResponseDto? result, string? error)> RefreshAsync(string refreshToken)`.
- `Task LogoutAsync(string refreshToken)` (idempotent).
- `Task<UserDto?> GetCurrentUserAsync(int userId)`.
- Internals:
  - Validate password via `IPasswordService.VerifyPasswordAsync`.
  - Use `IUserRepository.GetByEmailAsync` (case-insensitive) + `PasswordHash`.
  - Generate JWT via new `ITokenService` (if not present); include `rememberMe` to set expirations.
  - Refresh token persistence (table or in-memory cache) — if table not present, add TODO note.

## Repository Requirements
- Reuse `IUserRepository.GetByEmailAsync`, `IsEmailTakenAsync`, `UpdatePasswordHashAsync` (already planned).
- If implementing persistent refresh tokens, add `IRefreshTokenRepository` with CRUD + revoke; else document TODO stub.

## Controller Contract
Add `AuthController` (route `api/auth`):
- `POST login` → `AuthService.LoginAsync`
- `POST refresh` → `AuthService.RefreshAsync`
- `POST logout` → `AuthService.LogoutAsync`
- `GET me` → `[Authorize]` returns user from `HttpContext.User` → `AuthService.GetCurrentUserAsync`
- Optional: `POST validate-token`

## Middleware / Config
- Add JWT bearer auth configuration in `Program.cs`: issuer/audience/secret from `appsettings` (`Security:Jwt:{Issuer,Audience,Secret,AccessTokenMinutes,RefreshTokenDays}`).
- Register `AuthService`, `TokenService` (if new), and refresh token store (if added).
- Add `[Authorize]` to protected controllers/routes once tokens are enforced (future pass).

## Implementation Roadmap (Incremental)
1) **DTOs & Mapping** (API contract)  
   - Add Auth DTOs to `Dtos/AuthDtos.cs` (new) + mapping profile if needed.
2) **Token Service**  
   - Implement `ITokenService`/`TokenService` for JWT create/validate; config-driven expirations; claims building.
3) **Service Layer**  
   - Add `IAuthService`/`AuthService` using `IUserRepository` + `IPasswordService` + `ITokenService`.
4) **Controller**  
   - Add `AuthController` with `login/refresh/logout/me` endpoints; wire cookies for refresh token when `rememberMe` true.
5) **Infrastructure**  
   - Configure JWT bearer auth in `Program.cs`; add authentication/authorization middleware.
   - (Optional) Add refresh token persistence store + revoke/rotation.
6) **Validation & Errors**  
   - Normalize errors: `Unauthorized` for bad creds; `BadRequest` for malformed requests; `Conflict` for token reuse (if tracked).
7) **Testing**  
   - Unit tests for `AuthService` (happy/invalid creds/locked/inactive/refresh flows).  
   - Controller integration tests for `login/refresh/me`.

## Open Questions / TODOs
- Do we persist refresh tokens (DB table) or use stateless approach? (frontend expects refresh; choose DB-backed for revoke/rotation).
- Account lockout threshold and cooldown? (spec references email verification after 3 failed logins — not yet implemented).
- Roles/claims model? (not specified; start minimal: userId/email only).
- Cookie settings per environment (Secure/SameSite/Domain) to align with frontend deployment.
