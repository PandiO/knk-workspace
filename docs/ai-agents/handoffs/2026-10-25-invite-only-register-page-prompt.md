# Handoff: invite-only onboarding — the Cloudflare PIN step, the register page, claim codes

**Status:** Ready to start
**Last updated:** 2026-10-25 (scope extended: the Cloudflare one-time PIN step in every flow)
**Repos:** knk-web-app (main work), knk-web-api (one anonymous info endpoint, mail templates); knk-workspace for docs
**Found on:** the closed alpha, 2026-10-25, with the first two real testers (PlayStation via Geyser, Java on PC);
[crossplay report § 6](../../reports/2026-10-24-alpha-crossplay-trial.md). Background:
[invitations DESIGN § 5.8](../../specs/invitations/DESIGN.md) (decision I8: Cloudflare Access stays, the API keeps an
email list in sync, a bypass application opens only the sign-up paths), [alpha go-live § 6.1/§ 10](../../guides/alpha-go-live.md),
[account identity and admission](../../architecture/account-identity-and-admission.md),
[invitations smoke test](../../guides/invitations-smoke-test.md).

## Prompt

You work on Knights & Kings. Read `AGENTS.md` and `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` in knk-workspace, claim
the work in `docs/ACTIVE_SESSIONS.md`, then fix the onboarding problems below in knk-web-app, with small knk-web-api
changes where stated.

### How the alpha is set up (don't change this)

- `Security__Registration__Mode=Invite`. New players sign up with a personal invite (`/invite/:token`), a shared code
  (`/join?code=`), or game-first with a claim code from the server's disconnect screen (`/link` logged out,
  `/account/link` logged in). Link-code registration (`/account link` in game → `/auth/register`) is for grandfathered
  accounts only.
- **Cloudflare Access** guards the whole site `app.knightsandkings.net`. A bypass application opens only `/invite*`,
  `/join*`, `/link*`, the static files and three anonymous API calls (`/api/Invitations/check`,
  `/api/Admission/claim/check`, `/api/Auth/register`). Everything else — every other page *and* every other API call —
  needs a Cloudflare session. With `CloudflareAccess:SyncEnabled=true` the API puts the new account's email on the Access
  list at sign-up. The player then gets a Cloudflare session only by loading a protected URL **as a full page load**:
  Cloudflare shows its own login page, the player types their email there, Cloudflare emails a 6-digit one-time PIN
  (sender Cloudflare, not Knights & Kings), the player enters it, and the session lasts 30 days on that browser.
- The register response already carries `accessGate: true` when the sync is on (`AuthService`, `AuthDtos.AccessGate`);
  `InviteSignupForm` shows an "Your account is ready — Cloudflare emails you a PIN" step when it's set.

### What went wrong (2026-10-25, both testers)

1. After signing up on `/invite/:token` or `/join`, the PIN step's **Continue** calls `navigate(AFTER_SIGNUP_PATH)`
   (`pages/auth/InvitePage.tsx`, `JoinPage.tsx`) — an **in-app navigation**. No page load reaches Cloudflare, so the
   player never sees the Cloudflare login and never gets a PIN. Every API call from the page now goes to a protected
   path; Cloudflare answers with a redirect to its login, the browser blocks it (CORS) and axios reports a network
   error. The testers saw "Linking failed. Check the code, or join the server again for a new one."
   (`AccountLinkPage.tsx`, `LinkPage.tsx`) and, on logging in again, "Network error. Please try again"
   (`utils/authConstants.ts`). Both only worked after they found the Cloudflare PIN themselves.
2. The PIN step's text says "Cloudflare **emails you** a PIN", as if the mail came by itself. It doesn't: the player has
   to type their email on Cloudflare's page first. Nobody understood that the next screen would be Cloudflare's.
3. The invitation mail (`Services/Email/Templates/invitation.{html,txt}`) doesn't mention the Cloudflare step at all,
   nor what happens after sign-up (join the server, enter the code shown there).
4. A tester went invite page → **Log in** → **Create an account** (`components/auth/LoginForm.tsx` → `/auth/register`),
   the generic link-code form. In Invite mode it can't succeed, has no invitation or claim field, and calls a claim code
   (`XXXX-XXXX`, Crockford base32) typed into the link-code field simply invalid. He also thought the claim code was used
   up; it wasn't (one active claim code per Minecraft account, valid 15 minutes and shown again on every rejoin —
   `LinkCodeService.CreateClaimCodeAsync`), but nothing said so.

### Fix

**A. Know when the Cloudflare step applies (dynamic).**
- knk-web-api: add an anonymous `GET api/Auth/onboarding-info` → `{ "registrationMode": "LinkCode"|"Invite"|"Open",
  "accessGate": bool, "publicBaseUrl": "https://…" }` (`accessGate` = `CloudflareAccess:SyncEnabled`; nothing else, no
  emails, covered by the auth rate limit). Add it to the bypass list in docs (alpha go-live § 6.1 table, DESIGN § 5.8) —
  the developer adds it to the Cloudflare bypass application; say so in the PR/report.
- knk-web-app: a small hook/context (`useOnboardingInfo`) that loads it once, caches it, and tolerates failure (if the
  call fails on a page *behind* Access, the player already has a session — treat that as `accessGate: false` for display).
- Every Cloudflare text below shows **only when `accessGate` is true** (and invite texts only when the mode is Invite).
  With the defaults (LinkCode, sync off) the app looks exactly as today.

**B. The step after sign-up** (`InviteSignupForm` PIN step, used by `/invite` and `/join`; also after a claim sign-up):
- Numbered steps, e.g.:
  1. "Your account is ready. One more security step: this site is protected by Cloudflare."
  2. "On the next screen, Cloudflare asks for your email. Enter **{email}** (the one you just used)."
  3. "Cloudflare emails you a 6-digit code — from **Cloudflare** (noreply@notify.cloudflare.com), not from Knights & Kings.
     Check spam. Enter the code."
  4. "You're in, on this device for 30 days. Next: link your Minecraft account."
- The button does a **full page load** (`window.location.assign(AFTER_SIGNUP_PATH)`), never `navigate()`, so Cloudflare
  can intercept. Label it "Continue to Cloudflare sign-in".

**C. Recognise "no Cloudflare session" instead of "Network error".**
- In the shared API client (`services/serviceCall.ts` / the axios setup), when a request fails without a response
  (network/CORS) and `accessGate` is true, probe once with `fetch('/api/health', { redirect: 'manual', credentials: 'include' })`:
  an `opaqueredirect` (or a redirect to `*.cloudflareaccess.com`) means the Cloudflare session is missing or expired.
- Then show one clear, app-wide message instead of the page's own error: "Your Cloudflare sign-in has expired or isn't
  active on this device. [Sign in with Cloudflare]" — the button reloads the current URL (full page load). Use the same
  wording on `/account/link`, `/link`, the login form and any page. Don't log the user out of the app for it, and don't
  retry-loop.
- Login page: under the form, when `accessGate`, a short note "First time on this device? Cloudflare asks for your email
  and sends a 6-digit code first."

**D. Every flow gets its instructions** (only with `accessGate`/Invite as applicable):
- `/invite/:token` and `/join` (before the form): the three steps of the whole journey — sign up here → Cloudflare code
  by email → join `play.knightsandkings.net` (Java or Bedrock) and enter the code shown on screen at `/account/link`.
- `/link` (logged out, claim code verified): explain the order — invitation code → sign-up → Cloudflare step → linked.
- `/account/link`: what the claim code looks like, that it's valid 15 minutes and shown again on rejoin, and what to do
  when it expired (rejoin for a new one).
- Disconnect screen text is the plugin's (`admission` messages); only check that its URL (`/link`) matches.
- Password reset: the reset link opens a protected page — when `accessGate`, the reset mail says Cloudflare may ask for
  the email code first.
- Bedrock/console players use the same flow; their Minecraft name carries the `BE_` prefix — no special handling.

**E. Mails** (knk-web-api `Services/Email/Templates`, html + txt, only when `accessGate` — render a conditional block
from the dispatcher's model): invitation (journey steps incl. the Cloudflare code), welcome, finish-linking,
password-reset. Keep them short; the sender of the PIN is Cloudflare.

**F. The register page and claim codes in Invite mode** (`/auth/register`, `RegisterForm`):
- don't dead-end: offer an invitation-code field or send the user to `/join` (keeping any code/claim code in the URL)
  with a short explanation; keep the link-code path, worded "Already playing and got a code from `/account link`?";
- login page "Create an account" → `/join` in Invite mode (carry a pending claim code / invite token); the invite page's
  "Log in" returns to the invite after login and reads "Already have an account? Log in" vs "New here? Sign up with this
  invitation";
- detect the claim-code format in the link-code field (`RegisterForm`, `/account/link`) and route it to the claim flow
  with a clear message, not "invalid link code".

**G. Tests and docs.** Unit tests for the info hook, the PIN step (full-page navigation, text only with `accessGate`),
the Cloudflare-session detection (mock an opaque redirect), RegisterForm/LoginForm per mode, claim-format detection; API
tests for `onboarding-info` and the conditional mail blocks. Run both test suites. Update the invitations smoke test
(§ 3, § 4, § 7: a fresh browser goes invite → sign-up → Cloudflare page → PIN → `/account/link` without any "Network
error"), alpha go-live § 6.1 (bypass row for `onboarding-info`) and § 10 (tester invite text), the player account guide,
and the tracker.

**Not in scope:** changing Cloudflare Access itself, the claim-code lifetime, or the admission logic.

**Done when:** in a fresh browser on the alpha (Invite mode, sync on) a new player goes invite mail → sign-up →
Cloudflare email code → `/account/link` → linked, guided at every step, with no "Network error"; with the default
settings nothing about Cloudflare shows; no form in Invite mode is a dead end; tests pass; branches pushed with a short
deploy note (API build + web build, and the one bypass path the developer must add in Cloudflare).
