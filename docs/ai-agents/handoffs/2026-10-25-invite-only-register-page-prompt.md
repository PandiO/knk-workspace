# Handoff: the generic register page in invite-only mode, and claim codes typed as link codes

**Status:** Ready to start
**Last updated:** 2026-10-25
**Repos:** knk-web-app (main work), knk-web-api (only if a small public endpoint is needed); knk-workspace for docs
**Found on:** the closed alpha (2026-10-25), during the Bedrock crossplay trial
([report](../../reports/2026-10-24-alpha-crossplay-trial.md)); background:
[invitations DESIGN](../../specs/invitations/DESIGN.md), [account identity and admission](../../architecture/account-identity-and-admission.md),
[invitations smoke test](../../guides/invitations-smoke-test.md)

## Prompt

You work on Knights & Kings. Read `AGENTS.md` and `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` in knk-workspace, claim
the work in `docs/ACTIVE_SESSIONS.md`, then fix the following in knk-web-app (and knk-web-api only where stated).

**Situation.** The alpha runs `Security__Registration__Mode=Invite` (KNG-205/212/214, merged 2026-10-24). New players
sign up through an invitation: a personal invite link (`/invite/:token`), a shared code (`/join?code=`), or, game-first,
a claim code from the server's disconnect screen entered on `/link` (logged out) or `/account/link` (logged in). The
old link-code registration (`/account link` in game → `/auth/register` with an 8-character link code) only works for
grandfathered accounts and is otherwise refused in Invite mode (`InviteRequired`).

**What happened (a real tester, 2026-10-25).** A new Bedrock player got a claim code on the disconnect screen. He opened
his invite link, clicked **"Log in"** on the invite page, then **"Create an account"** on the login page
(`components/auth/LoginForm.tsx` → `/auth/register`). That is the generic `RegisterForm`: it only asks for a link code
and has no field for an invitation or a claim code, so in Invite mode there is no way to finish. He typed the claim code
(format `XXXX-XXXX`, Crockford base32, `utils`/`LinkCodeService.FormatClaimCode`) into the link-code field and got an
error. He then thought the code was used up; it wasn't (a claim code stays active for 15 minutes and the same code is
shown again on every rejoin until it expires — `LinkCodeService.CreateClaimCodeAsync`), but nothing told him that.

**Fix (knk-web-app):**
1. **Know the mode.** The register page needs the registration mode. `GET api/Invitations/options` has
   `registrationMode` but is staff-only. If no anonymous source exists, add a minimal anonymous endpoint in
   knk-web-api (e.g. `GET api/Auth/registration-info` → `{ mode: "LinkCode" | "Invite" | "Open" }`, no other data,
   covered by the existing auth rate limit) and add it to the Cloudflare bypass list only if `/auth/register` itself
   is meant to be public (today it is behind Access; the bypass covers `/invite*`, `/join*`, `/link*` and three API
   calls — see alpha go-live § 6.1; don't widen the bypass without saying so in the docs).
2. **`/auth/register` in Invite mode** must not dead-end:
   - offer an **invitation code** field (shared code, the same call `/join` uses) and accept a **claim code** too,
     reusing the `/join` + claim flow (`RegisterWithInviteAndClaimAsync` on the API side) instead of duplicating it —
     simplest is to send the user to `/join` (keeping any `code`/claim code in the URL) with a short explanation;
   - keep the link-code path for grandfathered players, worded as "Already playing and got a code from
     `/account link`?".
3. **Login page "Create an account"**: in Invite mode point to `/join` (and carry a pending claim code / invite token if
   the user arrived from `/invite/:token` or `/link`), not to the bare `/auth/register`. The invite page's own "Log in"
   link should return to the invite after login (redirect back), and say "Already have an account? Log in" vs
   "New here? Sign up with this invitation" so the user doesn't leave the invite flow.
4. **Claim code typed as a link code**: detect the claim-code format (`XXXX-XXXX` / 8 Crockford characters with a
   dash, vs. the link code's 8 A–Z0–9 characters) in `RegisterForm` and on `/account/link`, and route it to the
   claim flow (`/link?code=…` logged out, the claim path on `/account/link` logged in) with a clear message, instead of
   "invalid link code". Explain on every claim error that the same code stays valid for 15 minutes and that rejoining
   the server shows it again, or a new one after it expires.
5. Tests: RegisterForm (mode Invite: invite field / redirect to `/join`; claim-format detection), LoginForm link
   target per mode, InvitePage login round-trip. Run the app's test suite.

**Not in scope:** changing the claim-code lifetime or the API's admission logic; Bedrock specifics (the tester was on
Bedrock with the Floodgate prefix `BE_`, names up to 16 characters — nothing in this fix should depend on that).

**Done when:** in Invite mode a new player can't reach a sign-up form that can't succeed; every route from the invite
page, `/link`, the login page and `/auth/register` ends in a working invite sign-up; a claim code typed in a link-code
field is recognised; tests pass; the smoke test (`docs/guides/invitations-smoke-test.md` § 3–4) gets a step for these
paths; branch pushed and the tracker row updated.
