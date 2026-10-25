# Invite-only onboarding — the Cloudflare step in every flow, the register page in Invite mode, claim codes typed as link codes

**Status:** **Merged 2026-10-25** at the developer's request, to be tested directly on the closed alpha (no dev run):
knk-web-api `master` `fa28f7ea`, knk-web-app `main` `0d612702`. **Not deployed yet**: the developer runs the NAS steps in
"Alpha deploy and rollback" below, then a tester checks the fixes.
**Last updated:** 2026-10-25 (scope extended the same day with the handoff: the Cloudflare one-time code step, mails,
missing-session detection)
**Linear:** no issue of its own — creating one was refused (free-tier issue limit); recorded as a comment on
[KNG-218](https://linear.app/kngpandi/issue/KNG-218) (2026-10-25). **To file** when the limit allows: "Invite-only
onboarding: the Cloudflare step was skipped by the in-app navigation (Network error), the generic register page
dead-ends in Invite mode, a claim code typed as a link code is rejected without guidance" (KNG-205 family; related
[KNG-212](https://linear.app/kngpandi/issue/KNG-212), [KNG-214](https://linear.app/kngpandi/issue/KNG-214),
[KNG-216](https://linear.app/kngpandi/issue/KNG-216)).
**Handoff:** `docs/ai-agents/handoffs/2026-10-25-invite-only-register-page-prompt.md` (on knk-workspace branch
`claude/closed-alpha-readiness-p89505`, extended version `3b541b1`; its status line should read "Done 2026-10-25, see this
report" once that branch and this one meet on `main`) · **Found on:** the alpha with the first two real testers,
2026-10-25 ([crossplay report § 6](2026-10-24-alpha-crossplay-trial.md), same branch).
**Docs updated with this work:** [smoke test](../guides/invitations-smoke-test.md) § 3 step 11, § 4 step 16, § 7 steps 6–8;
[account identity and admission](../architecture/account-identity-and-admission.md) § 4 and § 7;
[alpha go-live](../guides/alpha-go-live.md) § 6.1 (bypass row) and § 10 (tester text); [DESIGN § 5.8](../specs/invitations/DESIGN.md)
(bypass list, as-built note); the [player account guide](../guides/users/PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md); [CHANGELOG](../CHANGELOG.md) (Unreleased).

## Branches and commits

| Repo | Branch | Base | Head |
|---|---|---|---|
| knk-web-api | `claude/invite-only-register-page` | `master` `1aba1ee` | `b110991` (`4a1c96b` registration-info, superseded by `b110991` onboarding-info) |
| knk-web-app | `claude/invite-only-register-page` | `main` `4a9537e` | `a4e3052` (`f50e74b` the register page, then the Cloudflare step) |
| knk-workspace | `claude/ecstatic-babbage-7r9f1w` | `main` `d89d1ba` | this report, docs above, tracker row |

## Alpha deploy and rollback (the developer runs these on the NAS)

**What ships.** Building from the trunk heads brings this fix plus what was merged after the running images
(`knk-web-api:alpha-a38c8ee9`, `knk-web-app:alpha-00e4af61`): the siege skip-seconds settings and the domain-name trim
(API and web), merged 2026-10-24 and run on dev. **Two migrations** come with them; this fix adds none:

| Migration | What it does | Effect on a rollback |
|---|---|---|
| `20261024120000_TrimDomainNames` | `UPDATE domains` trims spaces at the ends of names | data only; the old image reads trimmed names fine |
| `20261024224826_AddSiegeSkipSeconds` | two `int NOT NULL` columns on `siege_configurations`, with DB defaults 31 and 60 | additive; the old image doesn't map them and its inserts get the defaults |

So **a rollback is an image swap, no database restore**. The dump in step 1 is only for the unexpected.

**Deploy** (same procedure as the 2026-10-24 updates: [go-live § 3](../guides/alpha-go-live.md), `scripts/alpha-api/README.md`,
`scripts/alpha-web/README.md`; host `compose.yaml` authoritative, never "Update the stack"):

1. **Back up.** Copy the host `compose.yaml` to `backups/<TS>/`. Take a dated dump of `knightsandkings_alpha`
   (`alpha-db-pre-fa28f7ea/<TS>/`, as `alpha-db-pre-4aeb7947`). **Keep the old images** — don't prune: `alpha-a38c8ee9`
   and `alpha-00e4af61` are the rollback.
2. **Sources.** On the PC: `git archive -c core.autocrlf=false --prefix=source/` of knk-web-api `fa28f7ea` and
   knk-web-app `0d612702` into `deployment-sources/knk-web-api/fa28f7ea/` and `deployment-sources/knk-web-app/0d612702/`, unpack
   into `/srv/docker/build/knk-web-api/fa28f7ea/` and `/srv/docker/build/knk-web-app/0d612702/` next to the unchanged build files.
3. **Build** `knk-web-api:alpha-fa28f7ea`, `knk-web-api-migrator:alpha-fa28f7ea` (target `migrator`) and
   `knk-web-app:alpha-0d612702` (legacy builder, as before).
4. **API.** Stop `api`; run the `fa28f7ea` migrator once as in the 4aeb7947 run → exactly the 2 migrations above, 97 in total
   (`knk-ops db-summary`). Set the `api` image line to `alpha-fa28f7ea` (the repo block `scripts/alpha-api/compose.api-service.yaml`
   already says so), copy to Portainer stack 42's file, `docker compose up -d --no-deps api`. Check `knk-ops api-health` 200/200.
5. **Web.** Set the `web` image line to `alpha-0d612702`, `docker compose up -d --no-deps web`.
6. **Cloudflare dashboard:** add `/api/Auth/onboarding-info` to the "KnK sign-up (bypass)" application's paths
   ([go-live § 6.1](../guides/alpha-go-live.md)). Without it the invite, join and link pages show no Cloudflare guidance
   (nothing breaks).
7. **Quick check** in a private window before the tester: `https://app.knightsandkings.net/api/Auth/onboarding-info` →
   `{"registrationMode":"Invite","accessGate":true,"publicBaseUrl":"https://app.knightsandkings.net"}` without a Cloudflare
   login (proves the bypass); `/auth/register` opens on "Sign up with your invitation"; the login page's "Create an
   account" points to `/join`. Then update `RECORDED_SHA` in `scripts/nas-ops/stage-a/ops/compose` and its NAS copy.

**Tester check:** smoke test § 7 steps 6–7 (fresh browser: invite → sign-up → Cloudflare page → 6-digit code →
`/account/link` with no "Network error" → linked; cookie gone → the banner), § 3 step 11 and § 4 step 16. A new personal
invite mail shows the Cloudflare step (§ 7 step 8).

**Rollback** (minutes; only if something breaks):
1. Set the `api` image line back to `alpha-a38c8ee9` and the `web` line back to `alpha-00e4af61` in the host `compose.yaml`
   (or restore the step 1 copy), copy to stack 42, `docker compose up -d --no-deps api web`.
2. No migration down and no restore: both migrations are compatible with the old image (table above). Restore the
   step 1 dump only if data is found damaged.
3. The bypass path may stay: the old API answers it with 404 and the old pages never call it.
4. Code: `git revert -m 1 fa28f7ea` on knk-web-api `master` and `git revert -m 1 0d612702` on knk-web-app `main`, so the trunks
   match what runs; then the fix goes back to its branch for another round.

## What was wrong (2026-10-25, both testers)

**The Cloudflare step was skipped.** After sign-up on `/invite` or `/join` the "PIN" panel's **Continue** was an in-app
`navigate('/account/link')`. No document request reached Cloudflare, so its login never appeared and no PIN was
mailed; every API call from the page then died on Cloudflare's redirect to its login (CORS hides it: a network
error). The testers saw "Linking failed. Check the code…" and, logging in again, "Network error", until they found
Cloudflare's page by hand. The panel's text ("Cloudflare emails you a PIN") suggested the mail came by itself; it
doesn't — Cloudflare asks for the email first. The invitation mail didn't mention the step at all.

**The register page dead-ended.** New Bedrock player → claim code on the disconnect screen → opened his invite link → clicked **Log in** on the invite
page → **Create an account** on the login page → the generic `/auth/register` (link-code form only). In
`Security__Registration__Mode=Invite` that form can't succeed for a newcomer and has no field for an invitation or a
claim code. He typed the claim code (`XXXX-XXXX`) into the link-code field → "invalid link code" → thought the code was
used up (it wasn't: 15 minutes, re-shown on every rejoin).

## What changed

**knk-web-api** (`Controllers/AuthController.cs`, `Dtos/AuthDtos.cs`, `Services/Email/EmailTemplateRenderer.cs`, templates, tests)
- `GET api/Auth/onboarding-info` → `{ registrationMode, accessGate, publicBaseUrl }` (`accessGate` =
  `CloudflareAccess:SyncEnabled`, `publicBaseUrl` as the mails resolve it), `[AllowAnonymous]`, per-IP **auth** rate
  limit as the handoff asks. Nothing else, no emails; the invitable groups and limits stay on the staff-only
  `GET api/Invitations/options`. (The first commit's `registration-info` with only the mode is superseded.)
  `EndpointAccessRulesTests.AnonymousAllowList` lists it; `Api/AuthOnboardingInfoTests` covers modes, gate, URL, shape.
- **Mail templates can hold conditional blocks:** `{{#name}}…{{/name}}` (kept when truthy) and `{{^name}}…{{/name}}`;
  the renderer adds `accessGate` from the setting to every model (a model's own value wins). The **invitation** mail
  lists the journey (password → Cloudflare asks for your email and mails a 6-digit code → join, enter the code);
  **welcome**, **finish-linking** and **password-reset** get one Cloudflare line. With the sync off none of them mention
  Cloudflare (tests `OnboardingMails_ExplainTheCloudflareStep_OnlyWithTheAccessGate`, `Sections_KeepOrDropTheirBlock…`).
- **Cloudflare bypass:** the new path must be added (deploy note); documented in go-live § 6.1, DESIGN § 5.8, architecture § 7.

**knk-web-app — the Cloudflare step (handoff A–D)**
- `hooks/useOnboardingInfo.ts` (+ `utils/onboardingInfoCache.ts`): asks `onboarding-info` once per page load, caches it,
  a failure is not cached and reads as "unknown" (mode as `LinkCode`, no Cloudflare step — on a page behind Access a
  failure means the player already has a session). The service-call layer reads the cache through an import-free module.
- `components/auth/InviteSignupForm.tsx` done step (after `/invite`, `/join`, and a claim sign-up): numbered steps —
  Cloudflare protects the site; on the next screen it asks for your email, enter **{email}**; Cloudflare emails a 6-digit
  code (from noreply@notify.cloudflare.com, check spam); you're in for 30 days, next link Minecraft. The button
  **Continue to Cloudflare sign-in** is `window.location.assign('/account/link')` (`utils/navigation.fullPageLoad`),
  never `navigate()`.
- `services/cloudflareAccess.ts` + `services/serviceCall.ts`: a request that fails without a response (a `TypeError`
  from fetch) while `accessGate` is on triggers one probe, `GET /api/Health` with `redirect: 'manual'`; an
  `opaqueredirect` (or a redirect to `*.cloudflareaccess.com`) means "no Cloudflare session": the error becomes a
  `CloudflareSessionError` (`code: 'CloudflareSession'`, the one wording), `components/CloudflareSessionBanner.tsx`
  shows "Your Cloudflare sign-in has expired or isn't active on this device" with **Sign in with Cloudflare** (a page
  reload), the generic "Can't reach the server" toast is skipped, `apiRefusalReason` and `describeLoginError` pass the
  wording through so `/account/link`, `/link` and the login form show it instead of "Linking failed"/"Network error".
  One verdict is reused for 10 s; nothing retries; the app session stays.
- `components/auth/OnboardingJourney.tsx` on `/invite` and `/join` ("What happens next": sign up → Cloudflare's email +
  code → join and enter the server's code); `/link` (logged out, verified) lists the order invitation → sign-up →
  Cloudflare → join again; `/account/link` says the claim code is re-shown within 15 minutes and renewed after, Java or
  Bedrock; the login page notes "First time on this device? Cloudflare asks for your email…". All Cloudflare text only
  with `accessGate`; with the defaults the app looks as before.
- Not touched: the plugin's disconnect-screen text (`admission.link-url`, default `{web.public-url}/link` — matches the
  `/link` page; knk-plugin wasn't part of this session), Cloudflare Access itself, the claim-code lifetime, admission.

**knk-web-app — the register page and claim codes (handoff F, first commit `f50e74b`)**
- `components/auth/RegisterForm.tsx`: under Invite/Open the form opens on **Sign up with your invitation** — one
  field: an invitation code → `/join?code=…`; the server's `XXXX-XXXX` code → `/link?code=…`; 8 plain characters →
  the link-code step, filled in. The link-code step sits behind **Already playing and got a code from `/account link`?**
  (with a way back). In every mode a claim code typed **with its dash** into the link-code field is recognised
  (`looksLikeClaimCode`: link codes have no dash) and the button becomes **Continue with this code** → `/link?code=`;
  a refused 8-character code that *could* be a claim code (no I, L, O, U — Crockford) gets the hint "Is this the code
  the server showed you…" with a link to `/link` and the 15-minute note. `pages/auth/RegisterPage.tsx` adapts its
  subtitle.
- `components/auth/LoginForm.tsx`: **Create an account** → `signupPath(mode)`: `/auth/register` under LinkCode or
  unknown; otherwise `/invite` when a personal invitation is kept for the tab, `/link` when a verified claim code is
  kept, else `/join`; plus a one-line "invite-only" note.
- `pages/auth/InvitePage.tsx` + new `utils/pendingInvite.ts`: a valid personal token is kept in `sessionStorage`
  (`knk.pendingInvite`, until the invite expires, a day at most), `/invite` without a token resumes it, it is cleared
  after sign-up or when the invite is invalid. Wording: "New here? Sign up with this invitation…"; the form's footer
  says "This creates a **new** account. Already have an account? Log in" and **Log in** carries `returnTo=/invite`
  (`InviteSignupForm.loginReturnTo`; `/join?code=…` on the join page).
- `pages/auth/LinkPage.tsx`: `?code=XXXX-XXXX` fills the code in and checks it at once; the code leaves the address
  bar (`replaceState`, as the invite page does with its token). Refusals end with the 15-minute note.
- `pages/account/AccountLinkPage.tsx`: the field keeps one dash while typing (`normalizeLinkCodeInput`); a `XXXX-XXXX`
  entry is treated as a claim code (look-alikes folded O→0, I/L→1 like the API, "Recognised as the code from the
  server's disconnect screen"); a claim refusal (typed with the dash, or the kept code from `/link`) ends with the
  15-minute note. An `/account link` code is sent unchanged, as before.
- `components/auth/InviteSignupForm.tsx`: an `InvalidClaimCode` refusal ends with the 15-minute note.
- `utils/claimCode.ts`: `looksLikeClaimCode`, `couldBeClaimCode`, `CLAIM_CODE_STAYS_VALID`.

**Kept as is:** the claim-code lifetime, the API's admission and registration logic, the `/join` + claim flow
(`RegisterWithInviteAndClaimAsync`) which the new paths reuse, Bedrock specifics (nothing depends on the `BE_` prefix).

## Tests

- knk-web-api: `dotnet test --filter "AuthOnboardingInfoTests|EndpointAccessRulesTests|EmailTemplateRendererTests|
  EmailComposerAndThrottleTests|EmailDispatcherTests|RegistrationAndLoginTests|InviteRegistrationTests|AccountSecurityTests"`
  → 104 passed.
- knk-web-app: `npm run test:ci` → 193 suites, 1214 tests passed (head `a4e3052`); `npm run build` OK. The `CI=true`
  build (ESLint warnings as errors) fails on pre-existing warnings in untouched files (`PagedEntityTable`, `PathBuilder`,
  `SearchableDropdown`, …) — the same on `main` `4a9537e`; none in the files of this branch. New/extended: `cloudflareAccess.test` (probe verdicts, memo, gate off ⇒ no probe), `serviceCall.cloudflare.test`
  (TypeError + opaque redirect ⇒ `CloudflareSession`; gate off or API down ⇒ plain network error),
  `CloudflareSessionBanner.test`, `OnboardingJourney.test`, InvitePage/JoinPage (done step text, **full page load**, journey
  with/without the step), LinkPage (order list), AccountLinkPage (lifetime note), LoginForm (gate note, Cloudflare wording),
  `apiRefusalReason` (Cloudflare code), `useOnboardingInfo` (caching, defaults, unknown), plus the register-page tests of
  the first commit (RegisterForm Invite-mode block, LoginForm link targets, InvitePage keep/resume/forget, LinkPage
  `?code=`, AccountLinkPage dashed claim code, `pendingInvite`, `signupPath`).
- The pre-existing `tsc --noEmit` errors in `categoryTree.test.ts` and `sessionPinnedRows.test.ts` are unrelated
  (same 11 errors on `main`).

## Still to verify live (on the alpha, by the developer's choice)

**The Cloudflare step needs the alpha (or a dev Access setup):** smoke test § 7 steps 6–8 — fresh private window, invite
mail → sign-up → the done panel → **Continue to Cloudflare sign-in** → Cloudflare's page (email, 6-digit code) →
`/account/link` with no "Network error" → linked; delete the `CF_Authorization` cookie and submit a code → the banner, not
"Linking failed"; the mails carry the step with the sync on and not with it off. Add the bypass path first.

Smoke test § 3 step 11 and § 4 step 16, in short: with `Mode=Invite`, every route from the invite page, `/link`, the
login page and `/auth/register` ends in a working invite sign-up; the personal-invite round trip through **Log in** →
**Create an account** lands back on the same invitation; a claim code typed with its dash into either link-code field
is routed to the claim flow; the refusal texts mention the 15 minutes. Then the same `Mode=LinkCode` sanity check
(everything as before). Deploy: build the API image before the web image.

## Open points / decisions for the developer

- **Rate limit:** `onboarding-info` is under the auth policy as the handoff asks (10/min per IP, shared with login and
  register). A player's onboarding spends 2–4 of those in a minute (each full page load asks once). If that ever bites,
  the lookup policy (20/min) is one attribute away.
- **The probe URL:** `GET /api/Health` (anonymous, `HealthController`). Behind the bypass? No — and it must not be: the
  probe relies on Cloudflare redirecting it. Fine as long as `/api/Health` stays behind *Allow testers*.
- **Pending invitation in `sessionStorage`**: the token is single-use, bound to an email and already removed from the
  address bar; keeping it per tab is the same treatment the claim code gets (`knk.pendingClaim`). If that is not wanted,
  `InvitePage` can stop saving it and the login page then falls back to `/join`.
- A logged-in user who lands on `/invite` is still sent to `/account` (unchanged): an existing account doesn't need the
  invitation.
