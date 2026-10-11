# Closed alpha hardening — verification run 2026-10-08

Status: all automated and live checks passed on the local stack; the live checks on the dev server and alpha host are still to do (plan § 9).
Last updated: 2026-10-08
Linear: [KNG-64](https://linear.app/kngpandi/issue/KNG-64) (KNG-65 to KNG-71)
Plan: [alpha hardening implementation plan](../specs/alpha-hardening/IMPLEMENTATION_PLAN.md)
Screenshots: [`assets/2026-10-08-alpha-hardening/`](assets/2026-10-08-alpha-hardening/)

## What was tested

Branch `claude/ui-ux-assessment-discussion-66vc2l` in each repo:

| Repo | Head | Base |
|---|---|---|
| knk-web-api | `499ed7c` (8 commits) | `master` `1805cf9` |
| knk-web-app | `7f9ada2` (11 commits: 8 alpha, 2 cleanup, 1 landing fix) | `main` `84943ff` |
| knk-plugin | `18e8dbd` (6 commits) | `main` `c7d5a1e` |

**Local stack:**
- MySQL 8.0 with the `knk-dev-db-seed` data, migrated to `20261008083025_AddRefreshTokensAndTokenVersion`.
- The API in Development mode with a test plugin key. The plugin bypass was off, and the JWT secret was generated per run.
- The web app dev server on :3000.

Test passwords and keys were set only in the local copy of the seed.

## Automated tests

| Repo | Before (default branch) | After |
|---|---|---|
| knk-web-api | 1738 total, 4 failed (pre-existing) | 1835 total, the same 4 failed (`ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`, `FieldValidationServiceTests…ConditionMet…`, `PathResolutionServiceTests.ValidatePathAsync_AllowsValidV1Paths` ×2); 97 new security tests |
| knk-web-app | 6 failed suites (pre-existing) | 4 failed suites / 5 tests: the same FormWizard + `useEnrichedFormContext` failures; 452 passing. `CI=false npm run build` OK, main bundle 280.6 → 266.5 kB gzip |
| knk-plugin | all green | all green (knk-core 1216, knk-api-client 160, knk-paper 1088) |

## Security probe — `scripts/security/alpha-probe.sh`

| Run | Result |
|---|---|
| Unpatched `master` API | **20 checks failed**, matching the assessment's findings: anonymous user list and writes, no lockout, the refresh token in the body, and so on |
| Patched API, `--player '__dominic14__:…'` (login by **Minecraft name**) | **ALL 29 CHECKS PASSED** |

The 29 checks cover:
- anonymous access to users, grants, effective permissions and every write type → 401
- no ids or emails in `check-duplicate` / `validate-link-code`
- no exception text in errors
- player login by name; refresh token only in an HttpOnly cookie
- the player reads only their own profile; 403 on the user list, other users, game settings, content and self-grant
- a refresh token is refused as bearer
- logout revokes refresh; `logout-all` kills the access token
- 429 after repeated failed logins

## Manual live checks (API, through curl with the plugin key or JWTs)

| Check | Result |
|---|---|
| Plugin key `GET /api/Users` / wrong key | 200 / 401 |
| **Username squatting:** a web-only account holds the name `admin` (no UUID), and a real player named `admin` joins (plugin `POST /api/Users` with UUID) | The first run **found a bug** (500 `InvalidCastException`, a TPT tracking clash). **Fixed in `499ed7c`.** Re-run: 201; the old account became `unclaimed-29`; audit entry `UsernameReleased` |
| **Escalation guard**, moderator with `knk.admin.user.manage` + `.perm` + `.group`: grant `*` to self | 403 `EscalationRefused` (own permissions) |
| … grant `*` / `knk.admin.config` to another user | 403 `EscalationRefused` |
| … grant a node the moderator doesn't hold (an expired grant) | 403 |
| … grant a node the moderator holds | 200 |
| … assign the Staff group (nodes the moderator lacks) | 403 `EscalationRefused` |

## Browser checks (Playwright, desktop 1440×900 and iPhone 13)

| Check | Result |
|---|---|
| Landing: title, server address + Copy, favicon | "Knights & Kings", `play.knightsandkings.net` with Copy, favicon OK ([01](assets/2026-10-08-alpha-hardening/01-landing-desktop.jpg), [02](assets/2026-10-08-alpha-hardening/02-landing-phone.jpg)) |
| Landing readability | **Found and fixed** (`7f9ada2`): headings were dark navy on the photo, and slideshow controls covered the content on phones |
| Login label and default | "Email or Minecraft name"; "Remember me" **unchecked** ([03](assets/2026-10-08-alpha-hardening/03-login.jpg)) |
| Deep link `/account/transactions` while logged out | → login → back on `/account/transactions` |
| Console during login | no password, no bearer token |
| Token storage without "remember me" | `sessionStorage` only |
| Player opens `/dashboard`, `/forms`, `/admin/game-settings` | "Staff only" ([07](assets/2026-10-08-alpha-hardening/07-player-blocked-from-dashboard.jpg)) |
| Unknown URL | Not Found page, title "Page not found · Knights & Kings" ([08](assets/2026-10-08-alpha-hardening/08-not-found.jpg)) |
| Phone: tap the account icon | the menu opens (`aria-expanded=true`) with **Log out**; logging out → `/auth/login`; `/account` afterwards → login ([06](assets/2026-10-08-alpha-hardening/06-phone-account-menu-logout.jpg)) |
| **Registration with a game code**: code generated with the plugin key for the Minecraft-only seed account `MrBedue` | "This code belongs to **MrBedue**" → email + password → logged in on `/account` ([04](assets/2026-10-08-alpha-hardening/04-register-code-belongs-to.jpg), [05](assets/2026-10-08-alpha-hardening/05-registered-lands-on-account.jpg)) |
| Body font after the Fluent removal | Inter (was Segoe UI) |

## Findings to act on before go-live

1. **Grant the new nodes to staff.** `/dashboard` and `/forms` (web) and every content/world write (API) now need
   `knk.admin.content` / `knk.admin.world`. The seed's `admin` account (only `knk.admin.user.manage`) correctly lands on
   `/account` now. Owners with `*` or `knk.*` are unaffected. Give the Admin role group `knk.admin.*` (plan § 8).
2. **Rotate the dev DB password** (committed before KNG-64), and set user-secrets on each dev machine (knk-web-api `CLAUDE.md`).
3. Deploy order and the one-time logout of everyone: plan § 10.

## Not covered here (developer live checks, plan § 9)

- The plugin against the patched API on the dev server: the key on `RegionHttpServer`, `/account link` with
  `web.public-url`, FormWizard world fields.
- Session expiry after 30 minutes (unit-tested; not waited out live).
- The Cloudflare Tunnel + Access setup ([alpha-go-live.md](../guides/alpha-go-live.md)).

## Follow-ups noticed (not blockers)

- The "Staff only" page shows the raw permission node to players (assessment PLY-4).
- The plugin's join-time duplicate check never sent a UUID to the API, so it always answered "no duplicate". This is
  pre-existing, and was found by the API work.
- The lockout, the session-state cache and the account mail queue are in memory: per instance, and cleared on restart.
  Fine for one alpha instance.
- Staff email changes (`Users/{id}/update-email`) don't notify the old address. `Auth/update` does.
