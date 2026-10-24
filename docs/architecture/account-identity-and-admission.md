# Account identity and admission — who an account is, how it is created, who may play

**Status:** Describes the **invite-only design as merged to every trunk on 2026-10-24** (knk-web-api, knk-web-app,
knk-plugin; invitations chain links 1–7, smoke-tested on dev). **Off by default until the alpha switch-over**
([alpha go-live § 11.1](../guides/alpha-go-live.md)); until then the live behaviour is "Before the feature" below. Living document: update it in place when the
code changes.
**Last updated:** 2026-10-21 (written by invitations chain link 7, KNG-218)
**Linear:** [KNG-205](https://linear.app/kngpandi/issue/KNG-205) (parent), [KNG-206](https://linear.app/kngpandi/issue/KNG-206),
[KNG-207](https://linear.app/kngpandi/issue/KNG-207), [KNG-208](https://linear.app/kngpandi/issue/KNG-208),
[KNG-212](https://linear.app/kngpandi/issue/KNG-212), [KNG-214](https://linear.app/kngpandi/issue/KNG-214),
[KNG-216](https://linear.app/kngpandi/issue/KNG-216), [KNG-218](https://linear.app/kngpandi/issue/KNG-218)
**Design (binding, decisions § 8):** [invitations DESIGN.md](../specs/invitations/DESIGN.md) ·
**Plan and as-built notes:** [IMPLEMENTATION_PLAN.md](../specs/invitations/IMPLEMENTATION_PLAN.md) ·
**Operations:** [alpha go-live § 4–6.1, § 11.1](../guides/alpha-go-live.md), [email guide](../guides/email.md),
[smoke test](../guides/invitations-smoke-test.md) · **Players:** [account guide](../guides/users/PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md)
**Related:** [offline-security-cache.md](offline-security-cache.md) (the gate's outage fallback),
[api-connectivity.md](api-connectivity.md), [web-api-architecture.md](web-api-architecture.md)

---

## 1. The picture

```
                      invite mail / shared code                       Mojang session server
                                │                                             │ online-mode=true
 Browser ──► Cloudflare Access ─┤ bypass: /invite /join /link + 3 anon API calls│
             (API-owned email   │                                             ▼
              list + staff)     ▼                                Paper: AsyncPlayerPreLoginEvent
                         knk-web-app ──► knk-web-api ◄── GET api/Admission/{uuid} (plugin key)
                                          │   │   │                  │
                       email_outbox ◄─────┘   │   └──► cfproxy ──► api.cloudflare.com (Zero Trust list)
                       EmailDispatcher ──► mailrelay ──► Gmail / provider
                                              │
                                     MySQL: users, invitations, invitation_redemptions, linkcodes
```

Four gates stand between a stranger and the game, each with its own switch:

| Gate | Where | Switch (default = today's behaviour) |
|---|---|---|
| Cloudflare Access | edge, whole web host | `CloudflareAccess:SyncEnabled` (false: hand-made list) |
| Registration | API `AuthService.RegisterAsync` | `Security:Registration:Mode` (`LinkCode`) |
| Admission | plugin pre-login + API `AdmissionService` | `admission.mode` in `config.yml` (`whitelist`) |
| Vanilla whitelist | Paper | `white-list` in `server.properties` (true on the alpha) |

## 2. Identity anchor

- **The Minecraft UUID is the identity.** With `online-mode=true`, `AsyncPlayerPreLoginEvent` fires only after Mojang
  confirmed the client owns the account, so the UUID there is genuine (DESIGN § 5.1). A name typed on a web form proves
  nothing and never links anything (SEC-7, KNG-67).
- **One `users` row per person.** It may hold a Minecraft identity (`Uuid`, `Username` = the Mojang name), a web login
  (`Email`, `PasswordHash`), or both.
- **Web shells.** An account created on the web before it has a UUID is a *shell*: `Username` is `web-` + 10 Crockford
  characters, which can't be a Minecraft name (`-` is not allowed), so nobody can squat a name. The UI shows the email
  until a Minecraft account is linked.
- **Admission flags on `users`:** `AdmittedAt` (may play; set by the grandfathering backfill, an invite redemption, a
  claim link or staff *Admit*), `InvitedViaInvitationId`, `InvitedByUserId`, `EmailVerifiedAt` (set when the email
  came through an invite mail).
- **Name follows Mojang.** On an admitted join the API moves `Username` to the current Mojang name when no other account
  holds it (L4-3).

## 3. Code kinds

All short-lived codes live in `linkcodes`, told apart by `Purpose` (`LinkCodePurpose`, migration `LinkCodePurpose`):

| Purpose | Made by | Shape | Lifetime | Bound to | Used for |
|---|---|---|---|---|---|
| `Link` (0) | `/account link` in game | 8 chars, `A–Z0–9`, typed case-insensitively | 20 min (`Security:LinkCodeExpirationMinutes`) | the account (`UserId`) | register a web login on an existing Minecraft account; or, entered on `/account/link`, the fold (§ 5) |
| `PasswordReset` (1) | *Forgot password* | 64-char token, stored hashed | 30 min (`Security:PasswordResetTokenExpirationMinutes`) | the account | the reset link in the mail |
| `Claim` (2) | the admission gate | `XXXX-XXXX`, Crockford base32, look-alikes folded (O→0, I/L→1) | 15 min (`Admission:ClaimCodeMinutes`), one active per UUID, re-shown | `MinecraftUuid` + `MinecraftName`, no account | link a Mojang-verified UUID to an invited web account |

Invitations are **not** link codes. They live in `invitations` and store only a SHA-256 hash (`CodeHash`) and a 4-char
hint, shown once (decision I5):

| Kind | Code | Rules |
|---|---|---|
| Personal | 43-char base64url token in the link `/invite/<token>` | bound to one email (locked on the form), single use, 7 days default / 30 max, resend ≤ 3 per 24 h (each resend rotates the token) |
| Shared | `KNK-XXXXX-XXXXX` (Crockford), link `/join?code=…` | label, use cap (default 5, max 50), expiry required, pause/resume/rotate |

Both may grant a group from `Invitations:InvitableGroups` (default `["Alpha Tester"]`, seeded by the
`SeedAlphaTesterGroup` migration: weight 1, parent `Default`, no nodes). Staff groups never: the escalation guard runs
when the invite is created. A use is taken with one conditional `UPDATE … SET UseCount = UseCount + 1 WHERE … UseCount <
MaxUses AND RevokedAt IS NULL AND PausedAt IS NULL AND ExpiresAt > now`, so two sign-ups can't both take the last use.

Hygiene for all of them: codes are generated with `RandomNumberGenerator.GetInt32` (unbiased), an hourly
`LinkCodeCleanupService` expires lapsed codes and deletes finished ones after 7 days, and a per-account limiter
(`Security:LinkAttempts`, 5 per 15 min) answers 429 on code guessing. No code or token is logged outside Development.

## 4. Registration (`Security:Registration:Mode`)

`AuthService.RegisterAsync` (`POST api/Auth/register`, anonymous, `auth` rate limit):

| Mode | Invite fields | `linkCode` | `claimCode` |
|---|---|---|---|
| `LinkCode` (default) | 403 `InvitesDisabled` | as before KNG-205: web login on the code's account | 403 `InvitesDisabled` |
| `Invite` | check → personal: email must match (then verified); shared: email typed → `RedeemAsync` in one transaction: take a use, create the admitted shell with Default + the invite's group, redemption row, audit, Welcome mail | only for an **admitted** account, else 403 `InviteRequired` | together with an invite: the claim is validated first, then redeem + link in one transaction (§ 5 case A) |
| `Open` | behaves like `Invite` (L3-1) | | |

Without an invite and without a code under `Invite`: 403 `InviteRequired`. The plugin's `POST api/Users` under `Invite`
refuses a UUID without an admitted account (403 `NotAdmitted`, operators included, L4-5), so refused strangers never
get a row.

## 5. Linking cases

`UserService.LinkMinecraftAccountAsync`, from `/account/link` (logged in) or register-with-`claimCode`. Order: limiter →
validate the code (non-consuming) → resolve the Minecraft identity (link code: its owner's UUID; claim code:
`MinecraftUuid`) → refusals → spend the code → link.

| Case | Situation | What happens |
|---|---|---|
| A | The web account has no UUID; no account has this UUID (normal web-first) | Set `Uuid`, `Username` (the verified name; a web-only squatter is renamed `unclaimed-<id>`), `AdmittedAt ??= now`, SIGNUP_GRANT once (`signup:{id}`). Claim codes only, and only to an **admitted** web account (L4-1). |
| B — fold | The web account has no UUID; a Minecraft-only account has it | The Minecraft account stays primary (decision I7, KNG-207): `MergeWithForfeitAsync` (ledger), the shell soft-deleted with `Email` **and** `PasswordHash` cleared, its sessions revoked; the Minecraft account receives the login, `EmailVerifiedAt`, invite fields, `AdmittedAt` and the invite's group. A new session for the survivor. |
| Refuse | The UUID's account already has a web login | 409 `AlreadyRegistered` ("…log in with it, or use Forgot password") |
| Refuse | The caller already has another UUID | 409 `AlreadyLinked`; changing it is staff *Detach web login* |

Every new link audits `MinecraftLinked`, mails `MinecraftLinked` and queues the in-game `AccountLinked` notice ("…linked
to the web account st***@…. Not you? Tell staff right away.", L4-2). An invited account still unlinked after 2 days gets
one `FinishLinking` mail (L4-9).

Staff actions on the player profile's **Access** card (`knk.admin.user.manage`): *Admit* (sets `AdmittedAt`) and *Detach
web login* (clears the login from a linked account, ends its sessions).

## 6. Admission (who may join)

**Plugin** (`knk-paper` `admission/AdmissionListener`, `AsyncPlayerPreLoginEvent` at `LOWEST`; Bukkit-free rules in
`knk-core` `admission/AdmissionPolicy`):

| `admission.mode` | Behaviour |
|---|---|
| `whitelist` (default, also for a missing section or an unknown value) | no check; the vanilla whitelist decides |
| `open` | no check |
| `invite` | operators pass without an API call; everyone else: `GET api/Admission/{uuid}?name=` within `api-timeout-ms` (3 s) |

**API** (`AdmissionService.CheckAsync`, `[RequirePluginService]`): mode ≠ `Invite` → admitted; deactivated or deleted
→ `Deactivated`; admitted account → admitted; anyone else → a claim code → `NotAdmitted` + `code` + `expiresAt`.

**Plugin verdicts:** admitted → join (account creation and first-join kits as before); `NotAdmitted` → disconnect
(`KICK_WHITELIST`) with the claim code and the `/link` URL (`admission.link-url`, else `{web.public-url}/link`);
`Deactivated` → "This account is deactivated"; API timeout or error → a UUID the offline security store knows (≤ 30 days)
gets in, a stranger gets "Can't check your access right now". The log never holds the code.

**Order on Paper 26.3:** the gate runs at pre-login; the vanilla whitelist, ban and full-server checks run later, in
`PlayerConnectionValidateLoginEvent`. So the whitelist still works as the kill switch, and a banned stranger sees the
claim code rather than the ban screen (L5-4). `PlayerListener.onValidateLogin` returns early for a refused login, so no
`users` row is made.

**Grandfathering:** the `AddInvitations` migration sets `AdmittedAt = CreatedAt` for every active, non-deleted account,
so today's players keep joining. Under `LinkCode`, `UserService.CreateAsync` admits every new plugin account as before.

## 7. Cloudflare Access sync

Decision I8: Access stays, and the API keeps its allow-list (DESIGN § 5.8).

- **Two Access applications on the web host.** *Allow testers* (whole host; include = the API-owned Zero Trust email
  list `knk-api-testers` + a hand-made staff *Emails* rule; 30-day session) and a **bypass** application for only the
  sign-up paths (`/invite*`, `/join*`, `/link*`, the SPA's static files, `api/Invitations/check`,
  `api/Admission/claim/check`, `api/Auth/register`).
- **Desired set:** lower-cased emails of personal invites not revoked, not used up and not expired; plus active,
  non-deleted users with an email and (`AdmittedAt` or `InvitedViaInvitationId`). Frozen players stay in.
- **Reconcile** (`CloudflareAccessSync` singleton, run by `CloudflareAccessSyncService` at start, every
  `ReconcileMinutes` = 5, and 2 s after a wake-up): desired set → list → add missing → remove extra. The **whole list is
  the API's** (L6-2). More than `MaxRemovalsPerRun` (25) removals → none are made and the admin line turns red.
- **Wake-ups:** personal invite create/resend/revoke; email changes, deactivation, deletion, merge, detach (all through
  `UserService.RevokeSessionsAsync`); reactivation and *Admit*. Privacy erasure and unused expiry are caught by the
  5-minute run.
- **Inline add:** every successful registration adds the address with a 5 s timeout and answers `accessGate: true`
  while the sync is on; the sign-up form then shows the Cloudflare PIN step.
- **Egress:** only the named `cloudflare` HttpClient uses `ProxyUrl` (`cfproxy`, tinyproxy allowing
  `api.cloudflare.com:443` only). The token (Account → Zero Trust → Edit) is env-only.
- **Status:** `GET api/Invitations/access-sync` (`knk.admin.invites`) → the line on `/admin/invitations`.
- **Ceiling:** the free Zero Trust plan's **50 seats** (staff included), well below the list's 1,000 entries.

## 8. Mail flow

```
service (inside its transaction) ──► IEmailComposer.QueueAsync(kind, to, model, dedupeKey, expiresAt?, userId?)
     dedupe (unique DedupeKey) → render template (HTML + text) → throttle → email_outbox row → signal
EmailDispatcher (every 5 s or on signal): Pending rows due → transport → Sent | retry 1/5/15/60/240 min → Failed
     transports: Smtp (MailKit; auth only with a username) | Log (links only in Development or AllowLogTransport) | Pickup (.eml)
```

- **Kinds** (`EmailKinds`): PasswordReset, EmailChanged, privacy confirm/notice, Invitation, Welcome, MinecraftLinked,
  FinishLinking, EmailVerification, Test. Throttle: 3 per hour per address and class, 6 per hour per address,
  `DailyCap` 300 per 24 h; a throttled mail is a **Suppressed** row.
- **Tokens:** a row with `ExpiresAt` (reset, invite, privacy confirm) becomes Expired instead of being sent late, and
  loses its body once Sent, Expired or Failed. Rows are deleted after 90 days.
- **Out of the NAS:** the API sends to the `mailrelay` container (KNG-211, E0), which holds the Gmail (later provider)
  credentials; the API itself has no internet.
- **Staff view:** `/admin/email` (`knk.admin.config`): rows, filters, Retry, *Send test mail to me*.
- Start-up guard: outside Development, the Log transport needs `Email:AllowLogTransport=true`.

## 9. Switches and failure modes (summary)

| Situation | Effect | Fix / switch |
|---|---|---|
| API down, gate on | known players in after ≤ 3 s, strangers "can't check" | start the API; or `admission.mode: whitelist` + whitelist on |
| Cloudflare token wrong / proxy down | sign-ups work, the invitee waits at the PIN page; red admin line | fix the token/proxy; the next run catches up |
| Desired set wrong (bug, bad `ListId`) | ≤ 25 removals pass, more are held back | check, then raise `MaxRemovalsPerRun` once |
| Relay down | mails stay Pending, retried; reset mails expire after 30 min | start the relay |
| Abuse of sign-up | `Mode=LinkCode`; delete the bypass application | |

The switch-over order and commands: [alpha go-live § 11.1](../guides/alpha-go-live.md).

## Before the feature (trunk, until the merge)

On trunk today: anyone with a whitelisted Minecraft account joins; the plugin creates the account on first join;
`/account link` gives a code to register a web login (KNG-67); mail is `System.Net.Mail` through
`AccountMailQueue` (or the Log provider); the Cloudflare Access list is edited by hand; web-first sign-up is off
(`AllowWebFirst=false`).
