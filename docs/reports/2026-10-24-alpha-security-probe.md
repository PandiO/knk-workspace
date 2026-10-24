# Closed alpha security probe (go-live § 8) — 2026-10-24

**Status:** Passed. `alpha-probe.sh` ends with `ALL CHECKS PASSED` privately (29 checks) and through Cloudflare Access (30 checks)
**Last updated:** 2026-10-24
**Linear:** none (part of the go-live checklist § 9 E). **To file** (free plan issue limit): the User form finding in § 4
**Guide:** [alpha go-live](../guides/alpha-go-live.md) § 8 · **Script:** [`scripts/security/alpha-probe.sh`](../../scripts/security/alpha-probe.sh) (`a2504120…`)

Run against the NAS alpha: API `knk-web-api:alpha-a38c8ee9` behind `web` (nginx) and the `knk-alpha` tunnel, on the
placeholder database. The developer ran the commands; no password, token or service-token secret was printed. The
values were read with hidden `read -rs` prompts.

## 1. Setup

| Item | How |
|---|---|
| Non-staff test account `alpha-probe` | The web app's User form couldn't create it (§ 4). Created through the API instead: a throwaway container on `knk-alpha_backend` logged in as `__pandi__`, ran `POST /api/Users` (username, email, password + confirmation; staff need *Manage users*) and logged out again. Passwords went to the container on stdin, not as arguments. The account is in the default group only. It stays for later probes; the probe logs it out everywhere each run |
| Access service token | Zero Trust → Service Tokens: `knk-probe` (1 month). A policy `Probe service token` (Action **Service Auth**, Include Service Token `knk-probe`) added to the application `KnK alpha`. **It wasn't attached to the application at first**, so every request got Access's 302. A reusable policy has to be added to the application too. Without the token: 302; with it: `/api/health` 200 |
| Private run | `docker run --rm --network knk-alpha_backend --user 65534:65534 --cap-drop ALL --security-opt no-new-privileges:true -v …:/s:ro --entrypoint bash knk-web-api:alpha-a38c8ee9 /s/alpha-probe.sh http://api:5000 --player …`. The API image has bash and curl |
| Cloudflare run | Git Bash on the developer PC: `alpha-probe.sh https://app.knightsandkings.net --player … --cf-id … --cf-secret …` |

## 2. Results

**Private (`http://api:5000`), second run with the fixed script: ALL CHECKS PASSED (29).**
- **Anonymous (14):**
  - health is public;
  - users, a single user, permission grants and effective permissions need a login;
  - game-settings writes, content creation, world deletes and form-config deletes need a login;
  - web-first user creation is refused, and the test controller is gone;
  - `check-duplicate` exposes no user id, `validate-link-code` no email, and errors carry no exception text.
- **Player (14):**
  - login with name;
  - the refresh token isn't in the body, and it's set as an HttpOnly cookie;
  - the player can read their own profile, but can't list users, read another user, write game settings, create
    content or grant themselves `*`;
  - the refresh token isn't accepted as a bearer token;
  - logout works, and a refresh after logout is refused;
  - logout-all works, and the access token is dead afterwards.
- **Rate limit:** 429 after repeated failed logins.

**Through Cloudflare (`https://app.knightsandkings.net`, service token): ALL CHECKS PASSED (30).** The same checks plus
**"refresh cookie is Secure"** over HTTPS. It goes through every layer: Cloudflare WAF → Access (Service Auth) → tunnel →
nginx → API.

## 3. Probe script fixes (found in the first runs)

| First run | Cause | Fix (`5578d04`) |
|---|---|---|
| Private: `FAIL refresh token set as HttpOnly cookie`; "refresh token not accepted as bearer" and "refresh after logout refused" silently skipped | The API sets the refresh cookie `Secure` outside Development (`RefreshTokenCookie.cs`), and curl (like a browser) drops a `Secure` cookie received over plain `http://`. The API was right | Over http the script reads the token from the `Set-Cookie` header and checks HttpOnly there; logout sends the cookie explicitly; over https it also checks `Secure` |
| Cloudflare: 13 × `FAIL … got 302`, but 3 body-only checks "PASS" | The service token wasn't accepted (policy not attached); the three checks only looked at the body | The script stops at once on an Access redirect (exit 98) with a hint; body-only checks now need a real 2xx/4xx API answer |

The fixed script was checked against a scratch API over http: ALL CHECKS PASSED, including both checks the first
version had skipped.

## 4. Finding (to file in Linear)

**The web app's User form can't create a web account.** In the form wizard `/forms/User`, entering an email makes the
API demand `password` and `passwordConfirmation` (`UserService`: "Password is required when email is provided."), but
the form offers no password field. So staff can't create a web-only account in the UI; the API itself allows it with
*Manage users*. This is related to [KNG-248](https://linear.app/kngpandi/issue/KNG-248) (a User without an email can't be
edited). Workaround: create the account through the API (§ 1), or an invite once Phase 9 is live.

## 5. Follow-up

- Go-live checklist § 9 E: both runs pass.
- The service token `knk-probe` expires after a month. Renew it for a later probe, or delete it together with the
  `Probe service token` policy when it's no longer needed.
- Repeat the probe after each API update (the procedure in `scripts/alpha-api/README.md`), and after Phase 9, when
  sign-up and the bypass application change what's anonymous.
