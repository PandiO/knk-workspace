# Web app UI/UX assessment — 2026-10-08

Status: complete (expert review). Findings are open; follow-up issues still need to be created.
Last updated: 2026-10-08
Linear: [KNG-63](https://linear.app/kngpandi/issue/KNG-63/web-app-uiux-assessment-admin-staff-player-and-marketing-flows)
Evidence base: knk-web-app `main` @ `84943ff`, knk-web-api `master` @ `1805cf9` (+ migration
`UniquePermissionGrantHolderNode` applied), seed `PandiO/knk-dev-db-seed` (`knk_uiux_seed.sql.gz`, exported 2026-10-07).
Screenshots: [`assets/2026-10-08-web-app-ux/`](assets/2026-10-08-web-app-ux/)

This is an **expert review** (a heuristic evaluation, a code review and a run of the real app). It is **not** a usability
test. It shows where admins, staff and players are *likely* to struggle and where the code is
provably broken or insecure. Before investing in the bigger redesign items, confirm the top UX items with 3–5 short sessions with real users
(see §13).

---

## 0. How to read this

**Severity**

| Level | Meaning |
|---|---|
| **Critical** | Security or data-loss issue that anyone can exploit today, or that blocks a core task outright. Fix before the API or app is reachable by the public. |
| **High** | Hurts a core task for the main audience, a security weakness that needs an extra condition, or a silent failure. |
| **Medium** | Real friction, inconsistency or a gap with a workaround. |
| **Low** | Polish, consistency, minor a11y. |

**Evidence tags:** ✅ **live** = reproduced against the running app or API in this session. 📄 **code** = established by
reading the code (path:line given). ❓ = plausible from code, but not yet reproduced. A check to run is listed.

Paths without a repo prefix are in `knk-web-app/src/`. `api/` means `knk-web-api/`.

**Audiences** (developer input, 2026-10-07): **admins** (main users today: settings, entity CRUD, FormWizard
builders, players, tuning, insights), **staff** (support, which is not built yet, and accounts), **players**
(account, progression, learning, blog; later web gameplay) and **marketing** (show what the game is, features, blog,
changelog, events, attract players and collaborators).

---

## 1. Executive summary

The web app works as an **admin console built by and for its developer**. Several pages are well built
(Lootboxes, Siege configuration, currency policy and reversal, transactions). Four structural problems dominate:

1. **The API is mostly unauthenticated.** About 160 of about 290 write endpoints and most reads have no authorization attribute
   and there is no fallback policy. Live: an anonymous caller rewrote Game Settings, created and deleted a Category, and
   downloaded every user's email. A moderator can grant themselves `*`. Refresh tokens work as access tokens, and
   logout revokes nothing. **This must be fixed before anything is exposed publicly, including the marketing site.**
2. **Errors are often invisible.** The global error channel is never rendered (`App.tsx:37-70`), and Game Settings
   silently turns a load failure into an editable page of defaults. Admins can't tell when something failed.
3. **Admin CRUD takes too many clicks and lacks basic affordances** (this confirms the developer's complaint). No state is kept in
   the URL, the list has no "New" button, the wizard forces stepping through every step to edit one field, builders exit on
   every save, and there's no preview. There are no toasts, breadcrumbs, page titles, 404 page, unsaved-changes guard or undo.
   Editing one field takes 8+ clicks today; it could take 4.
4. **There is no public site or player area yet.** Anonymous visitors get a generic "share your photos" hero that
   downloads **65 MB**, has a "React App" title and no server IP. Players land on the admin entity browser (with
   edit and delete icons) after login. Nothing matches the brand guide: the font is Segoe UI instead of Lato, the colour is blue instead of red and orange, and
   the favicon is the React logo.

**Top 12 actions** (details and IDs below):

| # | Action | Fixes | Severity | Effort |
|---|---|---|---|---|
| 1 | API: fallback auth policy + permission attributes on every write; lock down `GET /api/Users*` | SEC-1, SEC-2, SEC-3 | Critical | M |
| 2 | API: block self-escalation, use the finer `user.perm`/`user.group` nodes | SEC-4 | Critical | S |
| 3 | Reject refresh tokens as bearer; persist + revoke refresh tokens; token version bump on password/email change | SEC-5, SEC-6 | High | M |
| 4 | Stop auto-linking web accounts to players by Minecraft username; link codes only | SEC-7 | High | S–M |
| 5 | Remove request/response console logging (passwords in console) | SEC-9 | High | S |
| 6 | Render a real toast/error region; fix Game Settings load-failure | X-1, SET-1 | High | S–M |
| 7 | `StaffRoute` on `/dashboard`, `/forms*`, `/display*`; role-based landing + honour deep link after login | NAV-1, SEC-8 | High | S |
| 8 | List state in URL + return to origin after create/edit (KNG-60); "New X" on the list | CRUD-1, CRUD-2 | High | M |
| 9 | Wizard: step tabs + Save on every step in edit mode, Cancel, sticky bottom actions, `0` bug | CRUD-5..8 | High | M |
| 10 | Builders: save in place, generate from metadata, preview | CRUD-11..13 | High | M–L |
| 11 | Confirm dialog with danger variant and required reason for all destructive/rights-changing actions | MOD-2, X-3 | High | M |
| 12 | Landing quick fixes: real title/meta/favicon, server IP + copy, compress images (65 MB to <2 MB) | MKT-1..3 | High | S |

---

## 2. Method and environment

- **Environment:** MySQL 8.0 seeded from `knk-dev-db-seed`; API `dotnet run` (Development, `AllowUnauthenticatedPluginCalls=false`,
  so the plugin bypass is **off** and the auth results below match a production config); app `npm start` on :3000.
- **Accounts:** `admin` (id 29, Owner mode) and `__dominic14__` (id 30, Default group, non-staff). The seed's shared dev
  password isn't documented, so a local test password was set **in the local copy only**.
- **Screenshot tour:** 3 roles (anonymous, player, admin) × 2 viewports (1440×900, 390×844) × 21 routes, with console
  errors and API status per page.
- **Targeted live checks:** API authorization probes (writes used non-existent IDs, or a throwaway record that was then deleted),
  token and logout behaviour, enumeration, lockout, self-escalation, console logging, computed font, landing payload,
  logout on touch and keyboard, number-field `0`, Game Settings load failure, forced table error.
- **Code review:** five parallel passes (auth/security; admin CRUD/Forms/Display; settings + player management;
  player/marketing/IA/cross-cutting; brand guide). Their file:line evidence was spot-checked.
- **Not covered:** the Road admin page (only on the unmerged `claude/road-navigation` branch), the plugin's in-game
  UX, real-user testing, and a production build/bundle analysis.

Environment issues found along the way are in §15.

---

## 3. Auth and security

### 3.1 Security findings

**SEC-1 — Critical — Most API controllers accept anonymous reads and writes.** ✅ live, 📄 code
- `api/Program.cs:149-159` defines only a placeholder `RequireAdmin` policy. There is no `FallbackPolicy` and no global
  `[Authorize]` filter, so every action without an attribute is public.
- A heuristic scan of `[Http*]` actions (class or action attribute present = guarded) found **166 of 289 write actions
  and 143 of 183 reads unguarded**. Six of those are intentional public auth endpoints. Affected controllers include:
  - GameSettings
  - FormConfigurations, FormSteps, FormFields, DisplayConfigurations (incl. `publish`), DisplaySections, DisplayFields,
    EntityTypeConfiguration, FieldValidationRules
  - Domains, Towns, Districts, Structures, Streets, Locations, GateStructures, GateDoors
  - WorldTasks, Workflows, Categories, Clans, BannerDesigns, Tags, Grades, ItemBlueprints, EnchantmentDefinitions,
    MenuTemplates, Minecraft*Refs
  - `Regions/rename`, `TestDisplay/cleanup` (deletes every display config with "Test" in its name)
  - `FormSubmissionProgress/user?userId=` (anyone's drafts)
- Live:
  - anonymous **and** player `PUT /api/GameSettings` → **200**
  - anonymous `POST /api/Categories` → **201**, then `DELETE` → **204**
  - anonymous and player `DELETE` on Locations, Towns and FormConfigurations with an unknown id → **404**, not 401/403.
    Only "not found" stopped them.
- Impact: anyone who can reach the API can, without logging in:
  - rewrite the server-wide join message, MOTD and spawn/respawn rules
  - delete towns, domains, gates and regions
  - break the form/display configs the admin UI runs on
- Fix:
  1. A fallback policy requiring an authenticated user or the plugin key, with explicit `[AllowAnonymous]` on login,
     refresh, forgot/reset, register, health and chosen reference data.
  2. `[RequireServiceOrPermission]` on every write. For example `knk.admin.config` for GameSettings and the
     Form/Display configs; the existing domain nodes for world entities.
  3. Delete `TestDisplayController` and `WeatherForecastController`.
  4. A test that enumerates every action (`IActionDescriptorCollectionProvider`) and fails on an anonymous write that
     isn't on an allow-list.
- Note: the web app's `StaffRoute.tsx` comment says the API is the real boundary. That is true for currency,
  lootbox, discovery and moderation only. The currency design doc already flagged this pattern
  (`docs/specs/currency-payments/DESIGN.md` A1); KNG-22 fixed only currency and user admin.

**SEC-2 — Critical — The full user directory, with emails, is public.** ✅ live
- Anonymous `GET /api/Users` returns every user with:
  - `email`, `uuid`
  - `isOnline`, `lastSeenAt`
  - `isFrozen`, `frozenReason`
  - balances and personal multipliers

  No password hashes are included.
- Also anonymous:
  - `GET /api/Users/{id}`, `POST /api/Users/search`
  - `GET /api/Users/{id}/permissions/effective` (shows who is staff)
  - `GET /api/PermissionGrants` (every grant, including `knk.*`)
- Impact: a ready-made phishing and credential-stuffing list, and a privacy (GDPR) exposure.
- Fix:
  - Require `knk.admin.user.manage` (or service) on these endpoints.
  - Give players and the plugin a reduced DTO without email.
  - Answer `permissions/check` only for the caller's own id, staff or the plugin.

**SEC-3 — High — Game Settings write is unauthenticated** (part of SEC-1, listed separately because the UI implies it is
staff-only). ✅ live. `api/Controllers/GameSettingsController.cs:28, :44`.

**SEC-4 — Critical — Moderators can grant themselves anything.** ✅ live
- With only `knk.admin.user.manage`, user 30 called `POST /api/Users/30/grants {"node":"*"}` → **200**, permanent, no
  expiry.
- `api/Controllers/UsersController.cs:80,108,133,160,191` gate group, node and mode changes on `ManageUsers` only. The finer
  nodes `knk.admin.user.group` / `knk.admin.user.perm` exist but aren't used. No self-target or "above my own rank"
  check exists.
- Assigning a premium tier also silently issues lootbox tokens (`api/Services/UserPermissionGroupService.cs:96,118`).
- Fix:
  - Use the finer nodes.
  - Forbid self-escalation and granting nodes or groups the actor doesn't hold.
  - Require a reason and write it to the audit log.

**SEC-5 — High — A refresh token is accepted as an access token.** ✅ live
- Calling `GET /api/Auth/me` with the refresh token as Bearer → **200**.
- Refresh tokens share key, issuer and audience with access tokens (`api/Services/TokenService.cs:82-110`), and bearer
  validation never checks `token_type` (`api/Program.cs:70-83`).
- Refresh tokens last 7 or 30 days and are also returned in the JSON body, so the HttpOnly cookie protects nothing.
- Fix:
  - Reject `token_type=refresh` in `OnTokenValidated`, or use a separate audience or key.
  - Stop returning `refreshToken` in the body.

**SEC-6 — High — Sessions can't be revoked.** ✅ live
- After `POST /api/Auth/logout` (204), the same refresh token still refreshes (**200**) and the access token still works
  (**200**).
- `api/Services/AuthService.cs:146-152` logout is a TODO.
- Password reset and change (`:370-377`, `:201-234`) don't invalidate tokens. There is no rotation.
- Impact: resetting your password after a compromise doesn't lock the attacker out for up to 30 days.
- Fix:
  - Persist hashed refresh tokens with rotation and reuse detection.
  - Add a `TokenVersion`/security stamp, checked on validate and bumped on password change, email change,
    deactivation and freeze.
  - Offer "Sign out everywhere".
  - ❓ Also check whether a deactivated staff member's live token still passes `RequirePermission`.
    `PermissionResolutionService` doesn't check `IsActive`.

**SEC-7 — High — Anyone can pre-register a Minecraft username, and the real player gets attached to that web account.** 📄 code
- Registration takes a Minecraft username without proof (`components/auth/FormStep2.tsx`, `RegisterForm.tsx:166-168`).
- On first join the plugin finds the pre-registered account by username and the API attaches the joining UUID to it
  (`knk-plugin/.../UserManager.java:188,207`, `api/Controllers/UsersController.cs:399-411`).
- Impact: account takeover of new players, or of names freed by a rename.
- Fix:
  - Never link by username. A UUID is attached only through a link code (game → web).
  - Show the name as "unverified" until linked.

**SEC-8 — High — Players can open the admin entity tools.** ✅ live
- `/dashboard`, `/forms*` and `/display/*` are `ProtectedRoute`, not `StaffRoute` (`App.tsx:141-163, 253-257`).
- A Default-group player sees the full entity browser with edit and delete icons
  ([screenshot 04](assets/2026-10-08-web-app-ux/04-player-sees-entity-dashboard.jpg)). Combined with SEC-1, those
  actions work.
- Fix: wrap these routes in `StaffRoute`, plus SEC-1.

**SEC-9 — High — Passwords and tokens are written to the browser console.** ✅ live
- During login the password appeared in the console.
- `services/serviceCall.ts:112-113` logs every URL and the full request params (Authorization header and JSON body).
- `apiClients/objectManager.ts:23` logs every response, including token responses.
- There are 83 `console.log` calls in non-test source.
- Fix:
  - Remove these logs, or gate them behind development mode with redaction.
  - Add an ESLint `no-console` rule for `services/` and `apiClients/`.

**SEC-10 — High — Email can be changed with just a session, and no email verification exists.** 📄 code
- `api/Services/AuthService.cs:236-252`: no current-password check and no format validation. `EmailVerified` is never set to
  true anywhere.
- Takeover chain: borrowed session → change email → "forgot password" → permanent ownership.
- Fix:
  - Require the current password.
  - Confirm the new address.
  - Notify the old address.
  - Verify the email at registration.

**SEC-11 — High — Secrets and an internal DB host are committed.** 📄 code (values not reproduced here)
- `api/appsettings.json` contains a LAN DB connection string with a password, and JWT secrets in both appsettings files.
- Startup checks only that the secret exists and is at least 32 characters.
- Fix:
  - Rotate the DB password and move it to user-secrets/env.
  - Fail startup outside Development on a missing or known secret.
  - Consider purging the values from git history.

**SEC-12 — Medium — No brute-force protection.** ✅ live
- 20 rapid failed logins → 20 × 401, with no delay or lockout.
- There is no `AddRateLimiter`. `check-duplicate`, `validate-link-code` (which returns an email), `link-account` and
  `reset-password` are unthrottled.
- Fix: the built-in rate limiter per IP and per account, plus progressive delay or lockout.

**SEC-13 — Medium — Account enumeration.** ✅ live
- `GET /api/Users/check-duplicate?email=` returns `{"available":false,"conflictingUserId":29}`, which maps email to
  internal id, anonymously, with the email in the URL.
- Login on an inactive account returns "Account is inactive or deleted." **before** checking the password.
- An unknown email skips bcrypt, so it answers faster (timing difference). 📄
- Fix:
  - Check the password first and return the same message either way.
  - Run a dummy bcrypt for unknown emails.
  - Drop `conflictingUserId` from the response.
  - Rate-limit `check-duplicate` and make it a POST.

**SEC-14 — Medium — "Remember me" is on by default; tokens live in localStorage; there is no CSP.** ✅ live
- The checkbox is pre-ticked ("Keeps you logged in for 30 days",
  [screenshot 03](assets/2026-10-08-web-app-ux/03-login.jpg)). After login the token is in `localStorage`
  (`knk.accessToken`). Registration forces remember-me (`services/authService.ts:36`).
- There is no CSP or security headers. No `dangerouslySetInnerHTML` was found (good).
- ❓ With remember-me unticked, the refresh cookie still persists for 7 days and `ProtectedRoute` refreshes silently
  (`AuthController.cs:214-221`, `authService.ts:58`). Check: log in unticked, close the browser, reopen `/account`.
- Fix:
  - Default remember-me off.
  - Session cookie when unticked.
  - Longer term, keep the access token in memory only.
  - Add a CSP and the standard headers.

**SEC-15 — Medium — Dev reset tokens are exposed if a Development API is reachable.** ✅ live
- `forgot-password` returns `debugResetToken` in Development (`appsettings.Development.json` `PasswordResetExposeTokenInDevelopment=true`).
- Default bind is `0.0.0.0:5000`.
- Fix: never run Development on a shared or LAN host, default the flag off, and stop logging reset URLs.

**SEC-16 — Low.** 📄
- DB inner exceptions and stack traces are returned to clients (`api/Controllers/TownsController.cs:90`, `DistrictsController.cs:90`,
  `LocationsController.cs:89`, `FieldValidationRulesController.cs`, `TestDisplayController.cs:211`). There is no global ProblemDetails handler.
- The `RequireAdmin` policy can never pass (no role claim is issued), so `AdminClientsController` is unreachable.
- `link-account` can't succeed: it passes `""` as the current password after consuming the code (`UsersController.cs:1331`).
- A failed logout leaves the token in storage (`authService.ts:42-45`).
- The API URL is hard-coded to `http://localhost:5294/api` and CORS allows only localhost, so the app isn't deployable as-is.

### 3.2 Auth flow UX

**AUTH-1 — High — Three screens give three different linking instructions.** 📄
- Register step 3 says "use `/account link <code>` on the server".
- `RegisterSuccessPage` says to generate a code on the Account page and type it in game.
- `AccountManagementPage.tsx:384-389` says the opposite: run `/account link` in game and paste the code on the web.
- The registration link code is discarded, and the success page is unreachable (`RegisterPage.tsx:11` goes to `/account`).
- Fix: pick game → web (this also fixes SEC-7), use the same text on every screen, and show the next step after sign-up.

**AUTH-2 — Medium — Login ignores the page you came from.** ✅ live
- Login always goes to `/dashboard` (`LoginPage.tsx:12,17`, `LoginForm.tsx:118`). `ProtectedRoute` sets `state.from`, but
  nothing reads it.
- A staff member opening `/admin/users/42` from Discord loses the link.
- Fix: return to `from` (same-origin only), otherwise a landing page that fits the role (NAV-1).

**AUTH-3 — Medium — Session expiry is silent and misleading.** 📄
- There is no 401 interceptor or silent refresh. After 30 idle minutes an admin opening a staff page sees "Staff only – needs
  `knk.admin.user.manage`" instead of "session expired" (`hooks/useStaffAccess.ts:57`).
- Fix: one fetch wrapper that refreshes once on 401, then redirects to `/auth/login?returnTo=…` with a banner. Separate
  "denied" from "error" in `usePermission`.

**AUTH-4 — Medium — Registration errors and double submit.** 📄
- API errors (`{error:"DuplicateEmail"}`) are never mapped to a field or step (`RegisterForm.tsx:194` reads `code`).
- About 4 seconds after success the button is clickable again, so a second submit is possible.
- The "Creating..." label is invisible (`bg-primary-light text-primary-light`, `:318`).

**AUTH-5 — Medium — The account page isn't built as forms.** 📄
- No `<form>`, so Enter does nothing.
- Labels aren't linked to inputs.
- The password fields have no `autoComplete`.
- There is no strength meter, so password rules differ from registration (server-side `Auth/update` checks length only:
  `api/Services/AuthService.cs:224-227`).
- There is no logout button on the page.

**AUTH-6 — Low.**
- No autofocus on the first field.
- The register show-password toggle has `tabIndex=-1` (not keyboard-reachable).
- Login → register is a full-reload `<a href>`.
- The "This form is keyboard accessible…" text is noise.
- Email-only login, although players think in Minecraft names. Clarify the label.
- The reset page doesn't check the token on load.
- Auth pages have no logo or home link and sit in a double frame ([screenshot 03](assets/2026-10-08-web-app-ux/03-login.jpg)).

**Done well:**
- Password reset: hashed, single-use, 30-min tokens with a generic response and a cooldown.
- BCrypt with a range-checked work factor.
- Plugin key: constant-time compare, fails closed, loud dev-bypass warning, `X-Acting-User-Id` honoured only with the key.
- Explicit CORS allow-list.
- The login form has `aria-live`, correct `autocomplete` and is disabled while in flight.
- No XSS sinks.
- `StaffRoute` separates checking, denied and allowed.

---

## 4. Navigation and information architecture

**NAV-1 — High — Every role lands on the admin entity dashboard after login.** ✅ live (see SEC-8)
- Players get a page that isn't in their own nav. The nav header reads "Dashboard" on every page
  (`components/Navigation.tsx:224`).

**NAV-2 — High — Logout can't be reached on touch or keyboard.** ✅ live
- The account menu opens on `onMouseEnter`, and clicking the icon navigates to `/account` (`Navigation.tsx:263-268`).
- On an iPhone viewport, tapping the icon went to `/account` and no Logout appeared
  ([screenshot 10](assets/2026-10-08-web-app-ux/10-phone-account-tap-no-logout.jpg)). Tabbing through the page never reached
  Logout.
- Fix: open the menu on click, with `aria-expanded`, Escape and focus moved into it. Add Logout to the account page.

**NAV-3 — Medium — No 404.** ✅ live. Unknown URLs render a blank page under the nav
([screenshot 11](assets/2026-10-08-web-app-ux/11-unknown-route-blank.jpg)). No `path="*"` in `App.tsx`.

**NAV-4 — High (marketing) / Medium (admin) — Every page title is "React App".** ✅ live. No `document.title`
anywhere (`public/index.html:27`). Multi-tab admin work and browser history are unreadable.

**NAV-5 — Medium — The admin IA is flat and partly hidden.**
- Seven ungrouped top-level links.
- The Economy pages (policy, alerts, balance log) can only be reached through buttons inside Moderation.
- Moderation is `exact`, so it isn't highlighted on `/admin/users/:id` or `/admin/economy/*`.
- No breadcrumbs.
- Nav labels don't match page titles ("Game Settings" opens "Game Manager Settings"; "Siege Settings" opens "Siege configuration").

**NAV-6 — Medium — View state isn't in the URL anywhere.** 📄 Dashboard type, lootbox tab, moderation tab, table page,
search and filters are all `useState` (`ObjectDashboard.tsx:17`, `LootboxesPage.tsx:35`, `UserModerationPage.tsx:31`,
`PagedEntityTable.tsx:159-167`). Refresh, Back and shared links reset the view.

**NAV-7 — Low.** 📄
- `navigate()` is called twice in a row in the Create New handler (`Navigation.tsx:127-128,335-337`) ❓ two history entries.
- Two `<h1>`s per page.
- The Create New menu's arrow keys never work (the menu never gets focus).
- Logged-in users are redirected away from `/auth/login`, but `/auth/register`, `/auth/forgot-password` and
  `/auth/reset-password` still render for them (✅ live).

**Target IA (proposal).** Use three layout routes with one route-meta table that drives the nav, `document.title`,
breadcrumbs and guards:

```
PUBLIC SITE   (PublicLayout: brand header + footer, dark, mobile-first)
  /  /play (how to join: IP, version, rules)  /game/* (features)  /news  /changelog  /events  /about
  /auth/*
PLAYER AREA   (/me, PlayerLayout: tabs on mobile)
  /me (overview)  /me/progress  /me/wallet  /me/settings      later: /play/* web game extensions
ADMIN CONSOLE (/admin, AdminLayout: grouped sidebar + breadcrumbs, desktop-first, lazy-loaded)
  World data: /admin/data/:type (today's /dashboard), /admin/forms, display configs
  Gameplay:   game settings, siege, lootboxes, discovery
  Players:    users, users/:id          Economy: ledger, transactions, alerts, policy
  Content (future): posts, changelog, events, slideshow media
```

- Keep redirects from today's routes so bookmarks keep working.
- `docs/specs/users/frontend-auth/LANDING_PAGE_NAVIGATION_ARCHITECTURE.md` (Jan 2026) deliberately hides navigation before
  login. Update it if this proposal is accepted.

---

## 5. Admin core flows: entity CRUD, Forms and Display

### 5.1 Click counts (current vs proposed)

| Task | Today | Clicks | Proposed | Clicks |
|---|---|---|---|---|
| List type X | Nav Dashboard → scan unsorted sidebar → X | 2 | `/admin/data/:type` deep link, remembered last type, sidebar search (KNG-61) | 1 (0 when returning) |
| Create X | Create New → pick X from 19 unsorted → Next×2 → Submit → modal Continue → lands on Dashboard showing the **first** type → re-select X | **7** | "New X" in the list toolbar → form → Save (+ Save & new) → toast, back on list X with the row highlighted | **2–4** |
| Create X without a default form config | …→ yellow "No default configuration" banner → Use on a config row → … | 8+ | Fall back to the only or first config, as edit already does | 2–4 |
| Edit one field on step 3 | Dashboard → X → pencil → step 1 → Next → Next → Submit → Continue → wrong type → re-find row | **8+** | Pencil → clickable step tabs, Save on every step → back to list X, same page | **4** |
| Edit from the detail view | Not possible: no actions for the viewed entity | — | Page header with Edit / Delete / Back | +1 |
| Delete 10 X | 10 × (trash, Delete, Close) | 30+ | Select all → Delete selected → confirm | 4 |
| New form config (10 fields) | Forms → X → Create Form → + step → (Add Field → pick → Save Field)×10 → Save → forced exit | **~35** | Generate from entity metadata → remove/reorder → Save (stays in builder) | **~6–8** |
| Iterate on a form config | Edit → change → Save → forced back to Forms → Use → step through → ⋮ → Edit … | ~8/cycle | Save in place + Preview drawer | ~2/cycle |
| New display config | + section → (Add Field → modal → save)×n → untick Draft → Save → (Publish) → Dashboard → row to see it | ~3n+10 | Scaffold from metadata + live preview against a sample entity; Publish as the primary save | ~n+4 |

### 5.2 Lists and tables (`ObjectDashboard`, `PagedEntityTable`, `ObjectTypeExplorer`)

**CRUD-1 — High — List state is lost on every round trip** (overlaps KNG-60). 📄
- The type, page, search and sort are all `useState`.
- The wizard sends `navigate('/dashboard', {state:{entityTypeName}})` (`pages/FormWizardPage.tsx:836`), but
  `ObjectDashboard` never reads it.
- Fix: put type, page, query, sort and direction in the URL, and return to `?returnTo=` / `state.from`. **M**

**CRUD-2 — High — No "New" action on the list.** 📄
- No `toolbarActions` are passed (`ObjectDashboard.tsx:180-224`). The empty state is just "No results found".
- Create only exists in the global Create New menu, which is a different hard-coded list of 19 types
  (`config/objectConfigs.tsx:1111-1131`) that doesn't match the metadata-driven sidebar.
- Fix: a "New {Type}" button in the toolbar and the empty state, and build the nav menu from metadata, sorted and searchable. **S**

**CRUD-3 — Medium — List readability.** ✅ live
- The default type is "Location", whose rows all read "Location" ([screenshot 04](assets/2026-10-08-web-app-ux/04-player-sees-entity-dashboard.jpg)).
- Raw CamelCase type names (`ItemBlueprintDefaultEnchantment`) in one ungrouped list.
- The count only shows when there is more than one page.
- Page size is fixed at 10.
- No filter UI, although the API accepts filters.
- The whole table is replaced by a spinner on every keystroke.
- Fix:
  - Group and humanise the type names.
  - Always show "N results".
  - A 10/25/50/100 page-size selector.
  - Filter chips for enum, boolean and relation columns.
  - Keep the previous rows dimmed while loading.

**CRUD-4 — Medium — Tables aren't links or keyboard-accessible; no bulk actions.** 📄
- Rows navigate on `<tr onClick>` (`PagedEntityTable.tsx:712-720`): no Ctrl/middle-click, no focus.
- Sort is on the `<th>` with no `aria-sort`.
- Icon buttons have only `title` and use low-contrast `text-gray-400`.
- Selection mode exists but is unused on admin lists.
- Rows are keyed by index.
- On phones the type sidebar is hidden with no toggle, so you can't switch type
  ([screenshot 05](assets/2026-10-08-web-app-ux/05-dashboard-phone.jpg)).

### 5.3 FormWizard

**CRUD-5 — High — Edit mode forces a walk through every step; steps can't be clicked.** 📄
- The step indicator is numbers only, with no names and no click (`components/FormWizard/FormWizard.tsx:2637-2664`).
- Submit only appears on the last step.
- Every Next also writes a server draft.
- Fix: named step tabs, jump to any step, Save enabled on every step in edit mode (validating all visible steps), and a
  single-page layout for short configs. **M**

**CRUD-6 — High — No Cancel, no unsaved-changes guard, actions only at the top.** ✅ live / 📄
- Previous / Save Draft / Next sit in the header above the fields
  ([screenshot 07](assets/2026-10-08-web-app-ux/07-formwizard-grade-create.jpg)).
- There is no `<form>`, so Enter does nothing.
- No Cancel.
- No `beforeunload` or route blocker anywhere in `src/`.
- Child form modals close on a backdrop click.
- Fix: a sticky bottom action bar with Cancel (back to origin), `<form onSubmit>`, `useBlocker` + `beforeunload`. **S–M**

**CRUD-7 — High — Number fields can't hold `0`.** ✅ live
- Typing `0` into Grade → Stars cleared the field.
- `value={value || ''}` in `components/FormWizard/FieldRenderers.tsx:689,724,767,795`.
- This affects weights, multipliers and odds entities.
- Fix: `value ?? ''`. **S**

**CRUD-8 — High — Validation runs only on submit; Next can silently do nothing.** 📄
- `onBlur` discards the result (`FormWizard.tsx:2880`). The rules loop is an empty placeholder (`:2314-2322`).
- No error summary or focus on the first error.
- A failed step-completion condition goes to the invisible error channel (`:2465`, see X-1), so **Next does nothing with no
  message**.
- Every non-nullable boolean becomes "required" (`FormConfigBuilder/FieldEditor.tsx:285`, KNG-53).

**CRUD-9 — Medium — Relation picking is heavy.** 📄 "Select instance" expands a full `PagedEntityTable` inline
(`FieldRenderers.tsx:1094-1128`). Fix: a searchable combobox (typeahead, top 10) with "Browse…" as a fallback.

**CRUD-10 — Medium — Drafts are shared and noisy; success lands in two different places.** 📄
- `userId = '1'` is hard-coded (`pages/FormWizardPage.tsx:120`), so every admin sees and resumes the same drafts.
- Abandoned wizards pile up.
- Saved Progress shows only "Step N".
- Success: a modal with a 3 s auto-redirect to `/dashboard` (wrong type), while Close leaves you on the Forms page.
- Single-line fields like *Name* render as a resizable multi-line textarea.

### 5.4 Form and Display configuration builders

**CRUD-11 — High — Save always exits the builder** (`FormConfigBuilder.tsx:450-459`, `DisplayConfigBuilder.tsx:446-447`). 📄
Fix: Save stays in place with a toast, plus a separate *Save & close*.

**CRUD-12 — High — No scaffolding from metadata.** 📄
- New configs start empty. Each field takes Add Field → modal → pick → Save Field.
- There is no "add all", no multi-select and no "Duplicate configuration".
- Labels are raw field names (`parentCategoryId`).
- Fix: "Generate from entity" (one step, all writable fields, humanised labels).

**CRUD-13 — High — No preview.** 📄
- To see a display config you go Dashboard → type → row.
- New display configs default to draft (`DisplayConfigBuilder.tsx:26`), and drafts are never used for the detail view,
  so a newly built display doesn't show anywhere.
- Fix: a live preview pane (form: read-only wizard from the draft; display: render against a chosen entity id) and an
  explicit Publish.

**CRUD-14 — Medium.** 📄
- Config validation errors appear at the top while Save is at the bottom.
- Field-editor errors use `alert()`.
- Step and field deletes have no confirm or undo.
- "Make default" is a two-request client sequence with `window.confirm` in three places (KNG-40).
- Config delete asks twice (`FormConfigurationTable.tsx:42` + `FormWizardPage.tsx:502`).
- The builders' only entry point is Forms → type ([screenshot 06](assets/2026-10-08-web-app-ux/06-forms-page-empty.jpg): the page
  opens empty with "Select an entity from the sidebar").

### 5.5 Detail view (DisplayWizard)

**CRUD-15 — High — No actions for the viewed entity, and some broken actions.** 📄
- Root sections get no Edit or Delete (`ActionButtons.tsx:306` returns null without `entityType`).
- No entity name, Back or breadcrumb.
- `DisplayWizardPage.tsx:14,20` navigates to `/form/...` (the real route is `/forms/...`), which gives a blank page.
- *Select / Unlink / Add* are `console.log` TODOs (`:22-33`) that render and do nothing.

**CRUD-16 — High — "Remove" on a collection item deletes the related entity.** 📄 `DisplayWizard.tsx:164-238` calls
the delete function for the target type. Removing a town from a district's list would delete the town. Fix: Remove =
unlink. Delete is a separate, labelled danger action showing the entity's name.

**CRUD-17 — Medium.**
- Values render as grey boxes that look like disabled inputs.
- Related values are text, not links.
- Collections have no count or paging.
- Errors show as raw "Error: {message}".
- Hot edit uses `alert()` and has no Enter/Esc.

**Done well:**
- Inline child creation without leaving the parent form.
- Conditional fields and steps.
- Field defaults.
- Explicit drafts with resume.
- Debounced server search and three-state sort.
- Configurable default columns with keyboard drag.
- Builder drag-and-drop with step, field and section templates.
- `ConfigurationHealthPanel`.
- An entity delete modal with category-specific recovery ("View children / Reassign parent").

---

## 6. Settings and tuning

**SET-1 — High — A Game Settings load failure becomes an editable, saveable page of defaults.** ✅ live
- With `GET /api/GameSettings` forced to 503, the page rendered normally with defaults, *Save Settings* was enabled, and
  **no error was visible** ([screenshot 08](assets/2026-10-08-web-app-ux/08-game-settings-after-load-failure.jpg)).
- `pages/admin/GameSettingsPage.tsx:158-161` substitutes `buildDefaultSettings()`. The error keys
  `ErrorMessage.GameSettings.*` don't exist in `utils/languages/en-en.json`, and the toast channel isn't rendered (X-1).
- One click overwrites the MOTD, announcements, spawns and group overrides.
- Fix: a blocking error with Retry; never render a saveable form on load failure. **S**

**SET-2 — High — Lowering data retention permanently deletes history, with no confirm.** 📄
- `components/admin/DataRetentionCard.tsx:44-66`: 365 → 3 deletes the audit log at the next daily cleanup.
- The card has its own Save inside a page that already has a Save.
- Fix: a confirm stating what will be deleted (type-to-confirm), and move it to a "Data & privacy" section gated on
  `knk.admin.config`.

**SET-3 — High — No audit trail, author, concurrency check or revert for tuning changes.** 📄
- Only CurrencyPolicy audits changes and handles a 409 (`CurrencyPolicyPage.tsx:197-213`). GameSettings, Siege, Lootbox,
  Retention and Discovery rules don't.
- "Last saved {date}" shows no author.
- GameSettings `PUT` is last-writer-wins.
- Nothing offers reset-to-default or history.
- Fix: an API-side audit entry with a before/after diff plus an `updatedAt` concurrency token; a shared "Change history"
  drawer; "Reset to default" per section.

**SET-4 — Medium — No dirty indicator or unsaved guard on most pages.**
- Reload discards edits without asking (Game Settings, Siege, Lootbox).
- Switching lootbox tabs unmounts the Settings tab and loses edits.
- Siege's pattern (amber changed fields, "Save (n)", send only changed fields) is the best one in the app and should
  become the template.

**SET-5 — Medium — Unclear units and meanings.**
- "Locked Time (ticks)" has no range or clock hint.
- Weather weights have no percentages.
- "Drop chance per second (‰)" has no "= x%".
- Magic values ("11 = never", "6 or more = off").
- "Sender title bracket id" is a raw ID field.
- Basis points have no live percentage.
- Ranges are enforced only by a 400 from the API.
- Fix: a `<UnitHint>` that shows the derived value; an explicit Off toggle instead of magic values; pickers instead of IDs;
  client-side min/max.

**SET-6 — Medium — Risky toggles take one click.** Payments kill switch, Lootboxes enabled, the per-type Enabled pill (live
immediately), token rule delete. Fix: confirm, and a red "Payments are OFF" banner across the economy and moderation pages
while off.

**SET-7 — Medium — Four different save and feedback models.**
- Game Settings: page Save, no success message, invisible error.
- Siege and Lootbox: inline banners.
- Policy: "Saved." per currency.
- Discovery rules: the row just closes.
- Fix: one `SettingsPage` shell (sticky header with title, last saved by and when, dirty count, Save/Discard, section
  cards, inline result).

**SET-8 — Medium — Missing tuning surfaces.**
- Global salary multiplier: an API exists, no UI.
- Per-player multipliers: an API exists, but the card is read-only.
- Kit and shop prices only exist inside generic FormWizard entities.
- Fix: an "Economy settings" page (salary, signup grant, kit/shop prices, discovery coins) with per-title effective numbers,
  like the discovery preview.

**SET-9 — Medium (High against the "concise insights" goal) — No dashboards, KPIs or charts.**
- There is no charting library. `/dashboard` is an entity list.
- Admins can't answer:
  - coins minted vs sunk this week
  - actual vs expected lootbox drops
  - siege participation
  - active players
- Fix: an Admin overview page with KPI tiles (players online and 7-day active, minted vs sunk over 24h and 7d, open
  alerts, undelivered claims, payments on/off), a sparkline per currency, and actual-vs-expected odds per lootbox type.
  This needs aggregate endpoints. **L**

**SET-10 — Medium — Logs have no totals, export or shareable filters, and use inconsistent time zones.**
- The balance log filters by local midnight; the drop log filters by UTC day. Neither table labels the time zone.
- Reason and source codes are free text.
- No net or sum row.
- No CSV export.
- Filters aren't in the URL.

**SET-11 — Low.**
- Lootbox announcement templates have no preview (reuse `MinecraftLegacyPreview`).
- Odds would read better as "1 in N".
- Number and date formats are inconsistent.
- Text fields and dropdowns on Game Settings have almost no visible border
  ([screenshot 08](assets/2026-10-08-web-app-ux/08-game-settings-after-load-failure.jpg)).
- Button icons render *above* the label: `.btn` lacks `inline-flex items-center` (`index.css:39-42`), ✅ live.

**Done well:**
- Siege config: changed-field highlight and changed-fields-only save.
- Currency policy: optimistic concurrency with a clear message, and every change is audited.
- Discovery: live per-title reward preview of unsaved edits, plus a cascade prompt.
- Lootbox types: empty-pool warnings, and an odds tab that explains itself ([screenshot 13](assets/2026-10-08-web-app-ux/13-lootboxes.jpg)).
- Currency alerts: severity summary and a reconciliation run.
- Drop log: rich filters.

---

## 7. Player and staff management, support

**MOD-1 — Critical — Self-escalation** — see SEC-4.

**MOD-2 — High — Profile actions have no confirm or reason, and errors are generic.** 📄
- Remove group: an icon-only ✕ with no aria-label and no confirm (`pages/admin/PlayerProfilePage.tsx:207-219,588`).
- Revoke node, grant/deny node, grant kit (bypasses cost and cooldown) and mode change all take one click with no reason.
- Errors drop the API's 400/403 message ("Could not assign this group.").
- Compare: balance adjust (category + note of 10+ characters + idempotency key), payment lock (reason) and reversal (note)
  already do this well.
- Fix: one `ConfirmActionDialog` (effect summary, required reason sent to audit, danger styling) for every write that
  changes rights or items; `clientErrorMessage` everywhere; a success toast.

**MOD-3 — High — There is no support workflow.** 📄
- Answering "I lost my items or coins" today means: Moderation → profile → balance history + the last 20 audit entries
  (no paging) → Lootboxes → Drop log, search the name again → compensate.
- Missing:
  - staff notes and tickets
  - one per-player timeline (ledger + claims + kits + audit)
  - items and inventory on the profile
  - freeze/unfreeze (an API exists, no UI; `IsFrozen` isn't shown)
  - deactivate/delete (an API exists, no UI)
  - online/last-seen
  - view-as-player
- Fix:
  - Phase 1 (M): a status strip in the profile header (online, frozen, payments locked, premium) with Freeze/Unfreeze
    (reason required); a lootbox claims and items panel linking to filtered logs; paged audit.
  - Phase 2 (L): staff notes, a support case object linked to ledger and claim IDs, and read-only view-as.

**MOD-4 — Medium — The profile is one 7,500 px page of 13 equal-weight cards** ✅ live
([screenshot 09](assets/2026-10-08-web-app-ux/09-player-profile-full-length.jpg)). Fix: a header status strip, tabs
(Overview / Economy / Permissions / Items & kits / Activity / Moderation) and an Actions menu. "Back" uses `navigate(-1)`
(`:346,:370`), which breaks when the page is opened from a link.

**MOD-5 — Medium — Search and list usability.**
- Rows are `<tr onClick>`: not links, no keyboard.
- No frozen, locked or last-seen columns.
- "Online" only works combined with a group filter.
- UUID search is a substring match ❓ dashless vs dashed.
- The moderation tables have no `overflow-x-auto` and scroll the whole page sideways on phones (✅ live, 530 px wide at
  390; [screenshot 12](assets/2026-10-08-web-app-ux/12-moderation-phone-overflow.jpg)).

**MOD-6 — Medium — Page gating doesn't match what the API requires.**
- Siege is gated on `user.manage` but saving needs `knk.siege.admin.manage`, so a moderator sees an editable form and only
  gets an error on save.
- The Retention card and Kit Grant are shown to all staff but need `knk.admin.config` / `knk.kit.give`.
- The Economy pages are unreachable for a finance-only role (no nav link).
- Fix: gate each route and nav item on the node its API needs; read-only mode with an explanation when the node is
  missing.

**Done well:**
- Currency safeguards: idempotency, the `expectedCurrent` check, an XP-promotion warning.
- The reversal flow, with a graceful 409.
- Private messages load on opt-in and every view is audited.
- Direct node grants expire after 1 day by default (KNG-59).
- Group-inherited nodes explain why they can't be removed.

---

## 8. Player pages

**PLY-1 — Medium — The account page mixes settings and stats.**
- Coins and gems are unformatted; XP is missing.
- It shows the raw Minecraft **UUID**, not the name or a skin head.
- `emailVerified` isn't shown.
- The "link your account" call to action is at the bottom, although linking unlocks everything.
- Balances come from the cached auth user and can go stale.
- Fix: split into Overview (MC name + head, formatted balances, discoveries summary, last activity; an onboarding card
  first when unlinked) and Settings.

**PLY-2 — Low–Medium — Transactions are good, but show developer details.** A "Reference" column (`publicId`) and raw UTC
ISO times. Fix: local time + relative dates, and move the reference into a details popover with Copy (useful for support).

**PLY-3 — Medium (strategic) — "See my progression" and "learn the game" barely exist.**
- Only balances, the ledger and discoveries are available.
- Missing: level and occupation, town/district and properties, clan, siege history, achievements, lootbox history, timeline,
  how to play, rules, map, news, changelog.
- Fix: a `/me/progress` hub with one card per system; public `/game/*` guides; `/news` + `/changelog` backed by an API
  Post entity edited under `/admin/content`. This is where the future web gameplay (`/play/*`) plugs in.

**PLY-4 — Low.** The "Staff only" page shows raw permission nodes to players
([screenshot 14](assets/2026-10-08-web-app-ux/14-staff-only-gate.jpg)). Show "This page is for staff" and keep the node in a
tooltip for staff.

**Done well:**
- Transactions: labelled filter, scrolling table, all three states, in-game guidance (`/pay`).
- Discoveries: `role="progressbar"`, a friendly empty state, disabled types hidden from players.
- Numbered link steps.

---

## 9. Marketing and public surface

**MKT-1 — High — The landing page downloads 65 MB.** ✅ live
- Measured on a phone viewport: **64.8 MB, 9 images**.
- `public/images/1-9.jpg` are 6832×3840 JPEGs of 3.6–8.9 MB each, all mounted as CSS backgrounds at once
  (`components/Slideshow.tsx:74-91`).
- Fix: WebP/AVIF at about 1920 px with `srcset` (about 200–400 KB each); render only the current and next slide. **S**

**MKT-2 — High — No value proposition; template copy.** ✅ live
- "Welcome to Our Community — Share your most beautiful moments… Submit your photos…"
  ([screenshot 01](assets/2026-10-08-web-app-ux/01-landing-desktop.jpg),
  [02](assets/2026-10-08-web-app-ux/02-landing-phone.jpg)). The upload feature is unreachable (`LandingPage.tsx:58,119-125`,
  a fake `setTimeout`).
- No server address anywhere in the app.
- The dark navy headline over a dark photo has poor contrast; the caption ("Cinix from north west Gate") is nearly
  invisible.
- Slide titles are "Cinix" six times, plus a typo ("Forrest").
- Logged-in users get no call to action.
- Below the hero is an empty grey band.
- Fix: a hero headline like "Knights & Kings — a medieval-fantasy MMO on Minecraft", one line on clans, sieges and
  progression, the server IP with a Copy button, "Create account" / "How to play". Feature sections, latest news, next
  event, footer (Discord, socials). Source the copy from `docs/vision/vision.md`.

**MKT-3 — High — SEO and share basics are Create React App boilerplate.** 📄
- Title "React App", description "Web site created using create-react-app", manifest "Create React App Sample", React-atom
  favicons.
- No OpenGraph/Twitter tags or sitemap.
- Client-only rendering, so crawlers see an empty `#root`.
- Fix: short term (S), real meta, OG image and manifest. Medium term, prerender the public routes or build the public site
  with a static generator that shares the tokens. A blog, changelog and events need SSG/SSR to be indexable.

**MKT-4 — Medium.**
- The slideshow prev/next buttons are never visible (`group-hover` with no `group` ancestor).
- The full-screen text overlay likely blocks the dots.
- It auto-advances every 6 s with no pause and no `prefers-reduced-motion`.
- The `<h1>` is a fixed `text-5xl` on phones.
- Logged-out visitors get no header, logo link or login entry point outside `/` (`App.tsx:121`).

**MKT-5 — Low.** `RegisterSuccessPage` can't be reached; registration success waits about 4 s across two timers.

---

## 10. Cross-cutting

**X-1 — High — The global error and notification channel is never rendered.** 📄
- `App.tsx:37-70` pushes `ErrorView`s into a `useRef` array that the JSX never displays. About 44–48
  `logging.errorHandler.next` call sites are invisible to users, e.g.:
  - table load failures (`PagedEntityTable.tsx:325`)
  - Game Settings save failures
  - wizard step conditions
- `en-en.json` defines only three message groups, so most keys would show as raw strings anyway.
- (Some components also show their own inline errors; the forced table 500 in the live check showed one.)
- Fix: a toast region (`aria-live="polite"`) subscribed to `errorHandler`, a generic fallback for unknown keys, and success
  toasts instead of blocking modals. **S–M**

**X-2 — Medium — Feedback patterns are inconsistent.**
- `FeedbackModal` (14 files), about 19 `window.confirm`/`alert` calls, inline errors, the dead toast channel.
- Success uses blocking modals.
- The destructive Delete confirm uses the `info` style with a blue button.
- Fix: success → toast; recoverable error → inline/toast; destructive → `ConfirmDialog` with a danger variant; remove
  `alert`/`confirm`.

**X-3 — Medium — Modal accessibility.** 12 hand-rolled overlays. Only 2 have `role="dialog"`; none has `aria-modal`, a focus
trap, initial focus or Escape. Backdrops close forms. Fix: one Dialog primitive (headless library, or Fluent's Dialog).

**X-4 — Medium — No error boundary.** Any render error white-screens the whole app. Add one per layout.

**X-5 — Medium — Form labels are often not tied to inputs.** 221 `<label>`s, about 53 with `htmlFor` (some wrap their
input). Examples: the account page and moderation filters. Fix: a shared `<Field>` with `useId`.

**X-6 — Medium — Fluent UI is effectively unused, and it overrides the font.** ✅ live
- The computed font is **Segoe UI** (the Fluent provider's `--fontFamilyBase`). The Inter loaded from Google Fonts is
  never applied.
- `FluentProvider` (`index.tsx:13`) is the only Fluent import; the UI is Tailwind + lucide.
- Decide on one: (a) **recommended:** Tailwind + a small shared component set + headless primitives (Dialog, Menu, Tabs,
  Combobox), and remove Fluent; or (b) adopt Fluent v9 properly with a brand theme. Also correct `knk-web-app/CLAUDE.md`,
  which says both are in use.

**X-7 — Medium — Responsive layout.**
- Stacked padding (wrapper `p-8` + page + card) leaves about 72 px per side at 375 px.
- The dashboard is a fixed 30/70 split with no breakpoint.
- 3 admin pages scroll sideways on phones (✅ live: Lootboxes 843 px, Users 530 px, Discovery 488 px at 390 px).
- The admin console can stay desktop-first; the public site and player area must be mobile-first.

**X-8 — Low–Medium — Contrast and undefined tokens.**
- `text-gray-400` (about 2.5:1) is used 109× on meaningful small text.
- `bg-primary-dark` / `hover:bg-primary-dark` and `btn-tertiary` are undefined, so there are no hover states and *Save Draft*
  is unstyled.

**X-9 — Low — Visual consistency.**
- Six `h1` sizes, three corner-radius styles.
- gray vs slate palettes.
- Four page background layers.
- Three pagination styles; two tab implementations (moderation tabs lack ARIA).
- Page container widths from `max-w-4xl` to `7xl`.
- Fix: `PageHeader`, `Card`, `DataTable` (pagination + URL filters), `ConfirmDialog`, `StatusBadge`, and `format*` helpers.

**X-10 — Low–Medium — Date and number formatting.** Numbers are forced to `en-US`, dates use browser locale in about 25
places, raw UTC ISO strings appear on Transactions, and `parseUtc` (for API dates without `Z`) is used on one page only.
❓ Times may shift by the UTC offset elsewhere. Fix: a shared `format.ts` with one locale policy.

**X-11 — Medium — No code splitting.** Every page is imported statically, so anonymous visitors download the whole admin
console (about 48k lines of TS/TSX). Use `React.lazy` per layout. CRA is deprecated; a Vite migration (L) would make
splitting and SSG easier.

**X-12 — Low — Dead code.**
- `pages/admin/EntityTypeConfigurationPage.tsx` (unrouted).
- `ObjectView.tsx`, `DynamicForm.tsx`.
- `ImageUploadModal` (unreachable), `LinkCodeDisplay`, `hooks/useAuth.ts`, `useAutoLogin.ts`.
- `App.css`, `logo.svg`.
- `src/prompts/*.md` (132 KB of notes inside `src/`).
- `GET /api/Locations/GetAll` is called by Game Settings and returns 404 (✅ live).

---

## 11. Brand alignment

The brand guide (`docs/vision/brand/huisstijlhandboek.pdf`, "Styleguide 2020", 12 pages) and the app share
**nothing** today. The developer has asked for the rebrand to be a separate effort. This section is its starting
brief.

### 11.1 What the guide specifies

**Logo** (p1–3)
- Lettering mark "Knights & Kings" on a **shield**; the dots on the i's are small crowns.
- Variants: shield + wordmark with and without cracks, and wordmark only.
- Stated rules:
  - Scale the elements together.
  - Use the **no-crack** variant at small sizes.
- No clear space, minimum size or don'ts are given.

**Colour** (p5, exact)

| Role | Pantone | RGB | HEX |
|---|---|---|---|
| Main: orange | 144 C | 242,145,0 | **#F29100** |
| Main: dark red | 1795 C | 190,22,34 | **#BE1622** |
| Main: black | Black | 0,0,0 | **#000000** |
| Support: charcoal | — | 53,53,53 | **#353535** |
| Support: white | — | 255,255,255 | **#FFFFFF** |

- Black is the intended backdrop "for more contrast" (p2).
- A red→orange horizontal gradient is used for banners (p10).
- The guide's CMYK values are internally inconsistent (#353535 is labelled as pure black). Check before printing.

**Type** (p2, p4)
- Headings: **Enchanted Land** (calligraphic; a commercial licence is required, so buy the *webfont* licence).
- Body: **Lato** Regular/Medium/SemiBold. Google Fonts' Lato has no 500/600, so self-host **Lato 2.0** (OFL).

**Not covered:** imagery, icons, tone of voice, grid, UI guidance, type scale, semantic colours.

**Source files:** the vector logo, font files and licence are likely in the SMB "Knights & Kings Huisstijl" folder /
"Huisstijl 2.zip" (`docs/reports/2026-09-15-smb-share-inventory.md:121-122,176-177`).

### 11.2 Gap table

| Element | Guide | App now | Gap |
|---|---|---|---|
| Name / title / meta | Knights & Kings | "React App", CRA description and manifest | High (trivial) |
| Favicon / PWA icons | Shield (no-crack) | React atom | High |
| Shell logo | Shield + wordmark | Hot-linked from Dropbox (`Navigation.tsx:217-220`), `alt="Logo"`, next to the title "Dashboard" | High |
| Primary colour | Red / orange | Tailwind blue `#2563eb` (`tailwind.config.js:7-10`), 427 `primary` usages | High (cheap: one token) |
| Neutrals | Black / #353535 / white | 1,844 `gray-*` + 40 `slate-*` | Medium |
| Backdrop | Black | Light only, no dark mode | Medium |
| Heading font | Enchanted Land | None | High (licence) |
| Body font | Lato | Configured Inter, **renders Segoe UI** (✅ live) | High |
| CTA colour | Red / orange | Green "Create Account", blue buttons | Medium |
| Copy tone | Medieval-fantasy MMO | "Share your photos" | Medium |
| Imagery | — | In-game screenshots (fit the tone) at 65 MB | Low (brand) / High (performance) |

### 11.3 Token layer (makes the rebrand cheap)

Brand primitives feed semantic CSS variables (light and dark), which Tailwind and a Fluent `BrandVariants` theme
both read. Keeping the Tailwind key `primary` means the 427 existing usages switch with **zero component edits**.

```css
/* src/styles/tokens.css */
:root {
  --knk-orange: 242 145 0;  --knk-red: 190 22 34;  --knk-charcoal: 53 53 53;
  --color-bg: 245 245 245;  --color-surface: 255 255 255;  --color-fg: 53 53 53;
  --color-brand: var(--knk-red);  --color-brand-hover: 164 24 31;  --color-on-brand: 255 255 255;
  --font-display: 'Enchanted Land', 'Lato', Georgia, serif;
  --font-body: 'Lato', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
}
:root[data-theme='dark'] {           /* public site: black backdrop, orange carries text */
  --color-bg: 0 0 0;  --color-surface: 53 53 53;  --color-fg: 255 255 255;
  --color-brand: var(--knk-orange);  --color-on-brand: 0 0 0;
}
```

```js
// tailwind.config.js (extend)
const v = (n) => `rgb(var(${n}) / <alpha-value>)`;
colors: { primary: { DEFAULT: v('--color-brand'), light: v('--color-brand-hover') },
          surface: v('--color-surface'), fg: v('--color-fg') },
fontFamily: { sans: ['var(--font-body)'], display: ['var(--font-display)'] },
backgroundImage: { 'brand-gradient': 'linear-gradient(90deg,#BE1622 0%,#F29100 100%)' },
```

If Fluent stays:
- Use a 16-step `BrandVariants` ramp anchored at step 80 = `#BE1622`:
  `10 #260a09 … 70 #a4181f, 80 #be1622, 90 #e23538, 100 #fc5652, 110 #fd7169 … 160 #ffedeb`. Verify it in the Fluent
  Theme Designer.
- Set `fontFamilyBase` to Lato. This also fixes the Segoe UI override.

### 11.4 Contrast rules that follow from the palette (WCAG 2.x)

| Pair | Ratio | Use |
|---|---|---|
| Red #BE1622 on white / white on red | 6.31 | ✅ AA: links, focus, primary buttons on light |
| Red on black | 3.33 | Large text / UI only |
| Red on #353535 | 1.94 | ❌ decorative only. Use tint #FD7169 (4.52) for red text on dark |
| Orange #F29100 on white / white on orange | 2.38 | ❌ never. Orange buttons need **black** text (8.83) |
| Orange on black / on #353535 | 8.83 / 5.16 | ✅ orange carries text on dark |
| White on #353535 | 12.27 | ✅ |

- Brand red sits close to error red (#dc2626), so errors must always carry an icon and text, never colour alone.
- Text on the gradient must sit over the red end.

### 11.5 Rebrand plan

| Phase | Scope | Effort |
|---|---|---|
| 0. Inputs | Get logo, fonts and licence from the SMB folder; buy the Enchanted Land webfont licence; decide light admin + dark public (recommended) | 0.5–1 d + licence lead time |
| 1. Tokens | tokens.css, Tailwind, (Fluent theme), self-hosted Lato 2.0, remove Inter/Segoe override, real title/meta/manifest/favicons, self-hosted logo | 1.5–2.5 d |
| 2. Shell, landing, auth | Dark brand nav, new landing (IA §4), dark auth pages, compressed images, theme toggle | 3–5 d |
| 3. Admin | Codemod gray/slate → semantic tokens, danger ≠ brand red, tables/badges/forms | 5–8 d |
| 4. QA | axe/Lighthouse contrast on both themes, focus-ring check | 1–2 d |

Total: about **11–18 developer-days** plus the licence. Phases 0–1 alone remove every High brand gap except the heading font.

---

## 12. Roadmap and suggested follow-up issues

Ordered by risk, then by value per effort. Each line is a candidate Linear issue; IDs refer to the findings above.

**Phase 0 — Security hotfix (before any public hosting, including the marketing site)**
1. API authorization sweep: fallback policy, permission attributes on every write, anonymous-write test (SEC-1, SEC-3). **M**
2. Lock down user, permission and grant reads; reduced DTO without email (SEC-2). **S**
3. Block self-escalation; finer nodes for group/grant/mode; reason → audit (SEC-4, MOD-2 API half). **S**
4. Token hardening: refresh ≠ bearer, persisted + rotated refresh tokens, revoke on logout, token version bump on
   password/email change and deactivation (SEC-5, SEC-6). **M**
5. Link by code only; no username auto-link (SEC-7, AUTH-1). **S–M**
6. Remove console logging of requests and responses (SEC-9). **S**
7. Email change requires the password + confirmation + notice; email verification (SEC-10). **M**
8. Rotate and remove committed secrets; fail-fast on placeholder secrets (SEC-11). **S**
9. Rate limiting + uniform login errors + `check-duplicate` hardening (SEC-12, SEC-13). **S–M**

**Phase 1 — Quick wins (each S)**
- `StaffRoute` on the admin entity routes; role-based landing; honour `from` after login (SEC-8, NAV-1, AUTH-2).
- Render a toast region for `errorHandler`; Game Settings load-failure guard (X-1, SET-1).
- Retention lowering confirm (SET-2).
- `value ?? ''` (CRUD-7); fix `/form/` routes, hide TODO actions; Remove = unlink (CRUD-15, CRUD-16).
- Account menu on click + Logout on the account page (NAV-2).
- 404 route, `document.title` per route, error boundary (NAV-3, NAV-4, X-4).
- `.btn` flex fix, define `primary-dark` / `btn-tertiary`, visible input borders, `text-gray-400` → 500 (SET-11, X-8).
- Landing: real meta/favicon, server IP + copy, compressed images (MKT-1, MKT-3 short term).
- Default remember-me off (SEC-14).

**Phase 2 — Admin foundation (M each)**
- Layout routes + route-meta table + grouped admin sidebar + breadcrumbs (NAV-5, target IA).
- URL state for lists and tabs; return to origin (CRUD-1 / KNG-60, NAV-6); "New X" + metadata-driven create menu (CRUD-2).
- Wizard: named clickable steps, Save on every step in edit mode, sticky footer, Cancel, dirty guard, blur validation +
  error summary (CRUD-5, CRUD-6, CRUD-8).
- Builders: save in place, generate from metadata, duplicate, preview, explicit Publish (CRUD-11..14).
- Detail page header with Edit/Delete/Back; readable display layout (CRUD-15, CRUD-17).
- Shared kit: `ConfirmDialog` (danger + reason), `Dialog`, toast, `DataTable`, `SettingsPage` shell, `format.ts`
  (X-2, X-3, X-9, X-10, SET-7, MOD-2 UI half).
- Settings: audit + concurrency + history + reset-to-default (SET-3); unit hints (SET-5); page gating by node (MOD-6).
- Decide Fluent vs Tailwind + headless (X-6).

**Phase 3 — Staff, support and insights (M–L)**
- Profile status strip, tabs, freeze/unfreeze, per-player timeline, paged audit (MOD-3, MOD-4).
- Staff notes and support cases (MOD-3 phase 2).
- Admin overview: KPI tiles and odds actual-vs-expected (SET-9); economy settings page (SET-8); log totals, export and URL
  filters (SET-10).

**Phase 4 — Players and marketing (M–L)**
- Public site with dark-first brand, how to play, `/game/*` guides; prerender or SSG (MKT-2..4).
- Player area `/me` with overview, progress hub, wallet, settings (PLY-1..3).
- Content: Post / changelog / event entities + `/admin/content` editor + `/news` `/changelog` `/events`.
- Later: `/play/*` web gameplay extensions built on the player area.

**Rebrand track (parallel, separate effort):** §11.5 phases 0–4. Phase 1 (tokens) is best done right after the shared
component kit in Phase 2, so new components are built on tokens from the start.

**Existing issues this report touches:** KNG-60 (CRUD-1), KNG-61 (CRUD-3), KNG-53 (CRUD-8), KNG-40 (X-2/CRUD-14),
KNG-39 (profile panels, MOD-4).

---

## 13. Validate with real users

Run 3–5 short sessions per group (20–30 min, think-aloud, screen-shared). Note where people hesitate, backtrack or give up.

**Admins / staff**
1. "Change the leave announcement to yellow and save it." Do they know it saved?
2. "Create a new Grade with 0 stars, then fix its name." (CRUD-7, CRUD-5)
3. "Build a form for Tag with all fields and try it out." (CRUD-12, CRUD-13)
4. "A player says they lost 500 coins yesterday. Find out what happened." (MOD-3)
5. "Make the Armor lootbox drop ★5 items twice as often, and check the new odds." (SET-5, SET-9)

**Players / visitors**
1. From the home page: "How would you start playing on this server?" (MKT-2)
2. "Link your Minecraft account." (AUTH-1)
3. "How many coins did you earn last week, and what from?" (PLY-1, PLY-2)
4. On a phone: "Log out." (NAV-2)

---

## 14. Open questions for the developer

1. Is the API reachable from outside your LAN today (port-forward, tunnel, hosted)? If yes, Phase 0 items 1–3 are urgent.
2. Which roles exist or are planned (Owner / Admin / Moderator / Support / Finance)? This decides how SEC-4 and MOD-6
   should split nodes.
3. Public site: inside this CRA app (with prerendering), or a separate static site sharing tokens? (MKT-3)
4. Public content language: English only, or Dutch too? (Decide before writing content pages.)
5. Fluent UI: drop it (recommended) or adopt it properly? (X-6)
6. Enchanted Land webfont licence: buy, or use the SVG wordmark + Lato for headings until then? (§11)
7. Light admin + dark public (recommended), or dark everywhere? (§11.5)

---

## 15. Environment notes from this run

- `knk-dev-db-seed/seed.sh` loads `knk_dev_seed.sql.gz`, but the file in the repo is `knk_uiux_seed.sql.gz`, so the script
  fails as written.
- The seed repo is **public** and contains real Minecraft usernames and UUIDs and a shared bcrypt hash (emails are
  anonymised). Consider making it private, and document the shared dev password somewhere private (e.g. environment
  variables) so the next run doesn't need to override it.
- The environment setup script didn't run in this session (the session was resumed, so setup was skipped); MySQL 8 and
  .NET 8 were installed by hand.
- The seed is ahead of API `master`: it includes the road-navigation migrations from the unmerged branch.
  `UniquePermissionGrantHolderNode` was missing and was applied.
- `knkwebapi_v2.sln` references `tests/…` but the folder is `Tests/`, so `dotnet build` of the solution fails on Linux; build
  the `.csproj`.
- knk-web-app `package-lock.json` is out of sync with `package.json` (`yaml@2.9.1` missing), so `npm ci` fails; used
  `npm install` and restored the lockfile.
- The session branches `claude/ui-ux-assessment-discussion-66vc2l` in knk-web-app and knk-web-api were cut from
  `claude/road-navigation`, not from the default branch. This assessment used `main`/`master` and made no commits there.
