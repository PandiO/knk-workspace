# Invite-only register page — the generic register page in Invite mode, and claim codes typed as link codes

**Status:** Implemented and pushed 2026-10-25, **not merged, not live-tested**. Waiting for the developer's review and
the dev smoke test (steps below), then the alpha deploy of both images.
**Last updated:** 2026-10-25
**Linear:** no issue of its own — creating one was refused (free-tier issue limit); recorded as a comment on
[KNG-218](https://linear.app/kngpandi/issue/KNG-218) (2026-10-25). **To file** when the limit allows: "Invite mode: the
generic register page dead-ends (no invite/claim field), and a claim code typed as a link code is rejected without
guidance" (KNG-205 family; related [KNG-212](https://linear.app/kngpandi/issue/KNG-212),
[KNG-214](https://linear.app/kngpandi/issue/KNG-214)).
**Handoff:** `docs/ai-agents/handoffs/2026-10-25-invite-only-register-page-prompt.md` (on knk-workspace branch
`claude/closed-alpha-readiness-p89505`; its status line should read "Done 2026-10-25, see this report" once that branch
and this one meet on `main`) · **Found on:** the alpha Bedrock crossplay trial, 2026-10-24/25 (report on the same branch).
**Docs updated with this work:** [smoke test](../guides/invitations-smoke-test.md) § 3 step 11 and § 4 step 16,
[account identity and admission](../architecture/account-identity-and-admission.md) § 4 and § 7,
[alpha go-live](../guides/alpha-go-live.md) § 6.1, the [player account guide](../guides/users/PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md),
[CHANGELOG](../CHANGELOG.md) (Unreleased).

## Branches and commits

| Repo | Branch | Base | Head |
|---|---|---|---|
| knk-web-api | `claude/invite-only-register-page` | `master` `1aba1ee` | `4a1c96b` |
| knk-web-app | `claude/invite-only-register-page` | `main` `4a9537e` | `f50e74b` |
| knk-workspace | `claude/ecstatic-babbage-7r9f1w` | `main` `d89d1ba` | this report, docs above, tracker row |

Merge order: the API first (the web app calls the new endpoint; without it the pages fall back to today's behaviour).

## What was wrong (the tester's path, 2026-10-25)

New Bedrock player → claim code on the disconnect screen → opened his invite link → clicked **Log in** on the invite
page → **Create an account** on the login page → the generic `/auth/register` (link-code form only). In
`Security__Registration__Mode=Invite` that form can't succeed for a newcomer and has no field for an invitation or a
claim code. He typed the claim code (`XXXX-XXXX`) into the link-code field → "invalid link code" → thought the code was
used up (it wasn't: 15 minutes, re-shown on every rejoin).

## What changed

**knk-web-api** (`Controllers/AuthController.cs`, `Dtos/AuthDtos.cs`, tests)
- New `GET api/Auth/registration-info` → `{ "mode": "LinkCode" | "Invite" | "Open" }`, `[AllowAnonymous]`, per-IP
  **lookup** rate limit (20/min; the handoff said "the existing auth rate limit" — the lookup policy was chosen so a
  page load doesn't spend one of the 10 login/register attempts a minute). Nothing else is exposed; the invitable
  groups and limits stay on the staff-only `GET api/Invitations/options`.
- `EndpointAccessRulesTests.AnonymousAllowList` lists it; `Api/AuthRegistrationInfoTests` covers the three modes and
  that the DTO carries only the mode.
- **Cloudflare bypass unchanged** (go-live § 6.1): only `/auth/register` and `/auth/login` call it, and both stay
  behind *Allow testers*, so nothing was widened.

**knk-web-app**
- `hooks/useRegistrationMode.ts`: asks the API once per page load, caches the answer, a failure is not cached
  (unknown ⇒ the pages behave as under `LinkCode`). `apiClients/authClient.registrationInfo()`, `RegistrationInfoDto`.
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

- knk-web-api: `dotnet test --filter "AuthRegistrationInfoTests|EndpointAccessRulesTests"` → 19 passed.
- knk-web-app: `npm run test:ci` (whole suite) and `CI=true npm run build` (ESLint warnings are errors) — results in
  the tracker row; the auth suites alone: 10 suites, 84+ tests (RegisterForm Invite-mode block, LoginForm link targets
  per mode and per kept invite/claim, InvitePage keep/resume/forget, LinkPage `?code=`, AccountLinkPage dashed claim
  code and refusal text, `pendingInvite`, `useRegistrationMode` caching and `signupPath`).
- The pre-existing `tsc --noEmit` errors in `categoryTree.test.ts` and `sessionPinnedRows.test.ts` are unrelated
  (same 11 errors on `main`).

## Still to verify live (dev, then the alpha)

Smoke test § 3 step 11 and § 4 step 16, in short: with `Mode=Invite`, every route from the invite page, `/link`, the
login page and `/auth/register` ends in a working invite sign-up; the personal-invite round trip through **Log in** →
**Create an account** lands back on the same invitation; a claim code typed with its dash into either link-code field
is routed to the claim flow; the refusal texts mention the 15 minutes. Then the same `Mode=LinkCode` sanity check
(everything as before). Deploy: build the API image before the web image.

## Open points / decisions for the developer

- **Lookup vs auth rate limit** for `registration-info` (see above) — reversible, one attribute.
- **Pending invitation in `sessionStorage`**: the token is single-use, bound to an email and already removed from the
  address bar; keeping it per tab is the same treatment the claim code gets (`knk.pendingClaim`). If that is not wanted,
  `InvitePage` can stop saving it and the login page then falls back to `/join`.
- A logged-in user who lands on `/invite` is still sent to `/account` (unchanged): an existing account doesn't need the
  invitation.
