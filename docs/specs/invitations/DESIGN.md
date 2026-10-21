# Invite-only sign-up, email engine and web-first Minecraft linking — Design

**Status:** Decided 2026-10-21 (§ 8, all recommendations taken, except I8: Cloudflare Access stays, and the API keeps its allow-list in sync, § 5.8). In implementation on the feature branch through the invitations chain: L0 (§ 5.4), the email engine (§ 4.2), invitations (§ 3) the admission gate and linking, server and plugin (§ 5.2–5.5), and the Cloudflare Access sync (§ 5.8, mechanism verified) are built, not merged; see the as-built notes. The rollout (I3) is prepared — `Alpha Tester` seed, smoke test, switch-over steps — and the overview of the built system is the living [account identity and admission](../../architecture/account-identity-and-admission.md) doc.
**Last updated:** 2026-10-21 (link 7: status line, architecture doc link; link 6: § 5.8 Cloudflare verification and as-built; link 5: § 5.2 as-built and the Paper 26.3 check; link 4: § 5.5 as-built; link 3: § 3.3 as-built; link 2: § 4.2 as-built; decisions recorded; § 5.8 Access sync added; § 6 and § 7 aligned with the implementation plan)
**Implementation plan:** [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) (2026-10-21; work packages E0, E1, L0, I1, I2, A1, I3)
**Linear:** [KNG-205](https://linear.app/kngpandi/issue/KNG-205) (this design, parent), [KNG-206](https://linear.app/kngpandi/issue/KNG-206) (email engine, high priority), work packages [KNG-211](https://linear.app/kngpandi/issue/KNG-211) (E0), [KNG-212](https://linear.app/kngpandi/issue/KNG-212) (I1), [KNG-214](https://linear.app/kngpandi/issue/KNG-214) (I2), [KNG-216](https://linear.app/kngpandi/issue/KNG-216) (A1), [KNG-218](https://linear.app/kngpandi/issue/KNG-218) (I3), found while writing it: [KNG-207](https://linear.app/kngpandi/issue/KNG-207) (link merge bug), [KNG-208](https://linear.app/kngpandi/issue/KNG-208) (link-code hygiene); related [KNG-159](https://linear.app/kngpandi/issue/KNG-159) (email verification), [KNG-67](https://linear.app/kngpandi/issue/KNG-67) (code-based signup)
**Sources:**
- Code read on 2026-10-21 at knk-web-api `master` `2d71155`, knk-web-app `main` `e30c815`, knk-plugin `main` `79be488`.
- [Closed alpha hardening plan](../alpha-hardening/IMPLEMENTATION_PLAN.md) decisions D1 (code-based signup), D2 (web-first off), D8 (verification deferred) and D10 (Cloudflare Access).
- [Alpha go-live](../../guides/alpha-go-live.md) § 4 (`Email__Provider=Log`, no egress), § 5 (whitelist) and § 10 (manual tester invite).
- [Production installation](../../guides/production-installation.md) mail settings (Gmail SMTP).

---

## 1. Summary

The developer asked for three things for the closed alpha:
- admin-made invitation links, codes and emails;
- an email engine, which password reset needs too;
- web-first sign-up with Minecraft linking that can't be abused.

The recommendations, in short:

1. **There are two kinds of invite.**
   - A **personal invite** is bound to one email address. It is single-use and expires after 7 days by default, at most 30.
   - A **shared code** is meant for a Discord post or a friend group. It has a required use cap (default 5, at most 50), a required expiry (default 7 days, at most 30), and a label that says where it was posted.

   Both kinds can be revoked. Both store only a hash of the code, and both record who redeemed them. A redemption can add the new account to an "invitable" group such as *Alpha Tester*, but never to a staff group. This follows how GitHub, Auth0, Discord and Slack do invitations (§ 3.2).
2. **Unblock real mail this week, then build the engine.**
   - **This week:** the alpha only runs `Email__Provider=Log` because the API container has no internet. Give the mail a way out of the NAS, through an SMTP relay container or an egress network. Then the existing SMTP code sends reset mails today.
   - **The engine (KNG-206):**
     - a persistent outbox table, retries and a per-recipient throttle;
     - MailKit instead of `System.Net.Mail` (Microsoft recommends MailKit for new code);
     - HTML and text templates;
     - a transactional provider on `knightsandkings.net`, with SPF, DKIM and DMARC;
     - an admin "send test mail" action.

   Invites, reset, notices and privacy mails all go through it.
3. **Mojang's login stays the only proof of Minecraft ownership.** A web account never gets a Minecraft identity because someone *typed* a name. The new piece is an **admission gate in the plugin** that replaces the vanilla whitelist:
   - A player who isn't admitted is disconnected at pre-login with a screen like: *"Knights & Kings is invite-only. Enter code `K7QH-M2XA` at knightsandkings.net/link."*
   - That code is bound to the UUID that Mojang has just authenticated.
   - Entering it on the web, while logged into an invited account, links the two. The player rejoins and plays.

   This works the same way web-first or game-first, and it removes the manual whitelist. Cloudflare Access stays: the API adds invitees to its allow-list and removes them again (§ 5.8, decision I8). DiscordSRV's "require a linked account to play" uses the same pattern.
4. **Linking never moves gameplay data onto the web account.**
   - If no Minecraft account exists yet, which is the normal web-first case, linking just sets the UUID and name on the web account.
   - If one exists, the web credentials are folded into the Minecraft account, which stays the primary. Today's code does the reverse and looks broken ([KNG-207](https://linear.app/kngpandi/issue/KNG-207)).

Suggested order:
1. Real mail on the alpha (§ 4.6).
2. The email engine.
3. Invites, the admission gate and linking, shipped together.
4. Rollout: grandfather the current testers, turn on the Access sync and the public sign-up paths, turn off the whitelist, and swap the tester invite template.

---

## 2. Where we are today

| Area | Today | Where |
|---|---|---|
| Account creation | The plugin creates a Minecraft-only account for **every** new UUID at pre-login (`POST /api/Users`). Login is allowed even if the API fails. | knk-plugin `listeners/PlayerListener.java:115-162` |
| Web sign-up | `POST /api/Auth/register {linkCode, email, password}`. The code must come from `/account link` in game, and it adds email and password to the Minecraft account. Without a code: `RegistrationNeedsCode`. Even with `AllowWebFirst=true` it answers `WebFirstUnavailable`, so web-first isn't built at all. | knk-web-api `Services/AuthService.cs:249-325`, `Configuration/SecuritySettings.cs:86-90` |
| Link codes | 8 characters A-Z0-9, 20 min, game → web only, single use (an atomic `UPDATE … WHERE Status=Active`). Protected only by the per-IP rate limits (`auth` 10/min, `lookup` 20/min); there is no per-account attempt counter. | `Services/LinkCodeService.cs`, `Configuration/RateLimitingSetup.cs` |
| Linking an existing web account | `POST /api/Users/link-minecraft-account` merges with the **web account as primary**. Only balances move, and the UUID copy should hit the unique index ([KNG-207](https://linear.app/kngpandi/issue/KNG-207)). | `Services/UserService.cs:1158-1224` |
| Alpha gate | This lives outside the code: the Cloudflare Access email allow-list (D10), the vanilla whitelist (`enforce-whitelist=true`) and a hand-written tester mail (go-live § 10). The landing page says "open to invited testers only", but nothing checks it. | go-live § 5, § 10; web-app `LandingPage.tsx` |
| Mail | `Email:Provider` is `Log` or `Smtp`. Reset and email-change mails go through an **in-memory** queue (500 slots), so they are lost on restart. Privacy mails have their own SMTP code. Bodies are plain text inline in C#. On the NAS: `Log`, because the `backend` network has no egress; reset links are read from the API log and relayed by hand. | `Services/AccountMailQueue.cs`, `SmtpPasswordResetDeliveryService.cs`, `Services/Privacy/PrivacyEmailService.cs` |
| Email verification | `EmailVerified` exists but is never set to true (D8, [KNG-159](https://linear.app/kngpandi/issue/KNG-159)). | `Models/User.cs:83` |
| Invites | No concept anywhere. `LootboxTokenReason.Referral = 4` is a reserved hook. | `Enums/LootboxEnums.cs:47` |

---

## 3. Invitations

### 3.1 Two kinds

| | Personal invite | Shared code |
|---|---|---|
| Use | One named tester, by email or by a copied link | A post in Discord or a group chat, an event, a streamer's audience |
| Delivered as | An email from the system, or a link the admin copies | A code and link the admin copies |
| Bound to | One email address. The account is created with that address, and redeeming the emailed link proves the inbox, so `EmailVerifiedAt` is set. | Nothing. The redeemer types an email, which stays unverified until KNG-159. |
| Uses | Exactly 1 | 1–50, required |
| Example | `https://knightsandkings.net/invite/3q2-…` (43-character token) | `KNK-7QH4M-2XA9P`, or `https://knightsandkings.net/join?code=KNK-7QH4M-2XA9P` |

Both kinds are one table with a `Kind` column: a personal invite is a shared code with `MaxUses=1` and a bound email.

### 3.2 Rules and recommended defaults

What comparable systems do (from their public docs as of 2025–2026; worth re-checking before quoting anywhere):

| System | Expiry | Uses |
|---|---|---|
| GitHub organisation invites | 7 days | email- or user-bound, single use |
| Auth0 organisation invitations | 7 days by default, at most 30 | single use, email-bound |
| Discord invite links | 30 min to 7 days (default 7), or never | unlimited or 1/5/10/25/50/100 |
| Slack shareable links | expire after 30 days | up to 400 people |

Industry practice is short, email-bound, single-use invites for named people, and capped, expiring links for groups. Never-expiring, unlimited links are what leak.

| Rule | Personal | Shared | Notes |
|---|---|---|---|
| Expiry | default 7 days, admin picks 1–30 | default 7 days, 1–30, **required** | Caps live in config: `Invitations:MaxExpiryDays`. No "never" during the alpha. |
| Max uses | 1, fixed | default 5, 1–`Invitations:SharedMaxUsesCap` (50) | Counted at **account creation**, not at Minecraft link (§ 3.4). |
| Bound email | required | — | Normalised to lower case, the same as login. Refused if an account already uses it. |
| Label / note | optional | **required** ("Discord #announcements 21 Oct") | So a leaked code can be traced and revoked. |
| Group on redemption | optional, from `Invitations:InvitableGroups` | same | E.g. *Alpha Tester*. Checked with `PermissionEscalationGuard` at creation. Staff groups are never invitable. |
| Revoke | any time | any time, plus pause/resume | A revoked code answers the same "invalid or expired" as a wrong one. |
| Resend (personal) | rotates the token and restarts the expiry | — | The old link dies, so a stale mail can't be used. At most 3 resends a day per invite. |
| Who can create | `knk.admin.invites` (new node, matched by `knk.admin.*` and `*`) | same | Later perhaps players with a quota (§ 3.7). |
| Rate limits | redeem and check on the `auth` policy (10/min/IP) | same | Plus Cloudflare's WAF rule on `/api/Auth/`. |

### 3.3 Code and link formats

- **Personal link token:** 32 random bytes, base64url, 43 characters. Only `SHA-256(token)` is stored, the same way reset tokens and refresh tokens are. The web page reads it from `/invite/:token`, then removes it from the address bar (`history.replaceState`). Invite, reset and link pages send `Referrer-Policy: no-referrer`.
- **Shared code:** `KNK-` plus 10 characters from Crockford base32 (no I, L, O, U; 0/O and 1/I/L are read the same), shown as `KNK-XXXXX-XXXXX`. That is 50 bits, so about 10^15 possible codes; at 10 guesses a minute per IP, guessing is not a realistic attack. Only the hash is stored.
- **Show once.** The admin sees and copies the code or link at creation, and again after "rotate". This is the same model as API keys. Storing the codes reversibly so they can be shown again is possible, but it isn't needed: rotating a shared code costs one click. *(Decision I5.)*

**As built (link 3, 2026-10-21, KNG-212):** codes as above; the check also returns the bound address of a personal
invite to the holder of its token, so `/invite` can show it locked (the token was sent to that address). Pages with a
code in the URL add a `no-referrer` meta tag while open. See plan § 5.2a.

### 3.4 Lifecycle and counting

```
Active ──(UseCount = MaxUses)──► Exhausted
  │  └─(now > ExpiresAt)──► Expired
  └─(admin)──► Revoked            (Paused ⇄ Active for shared codes)
```

- A use is taken in **one statement** at account creation:
  `UPDATE invitations SET UseCount = UseCount + 1 WHERE Id = @id AND UseCount < MaxUses AND RevokedAt IS NULL AND ExpiresAt > @now`.
  Two people racing for the last slot can't both win. The pattern is the same as `LinkCodeRepository.TryMarkUsedAsync`.
- Each redemption writes an `invitation_redemptions` row (invite, new user, time). The user gets `InvitedViaInvitationId` and `InvitedByUserId`, so staff can see who brought whom.
- An account that is redeemed but never linked to Minecraft still exists. It can log in and see its account page, but it can't play until it links (§ 5). The admin list shows it as "redeemed, not linked". A reminder mail goes out after 2 days *(optional)*.

### 3.5 What a redemption grants

- A web account: email, password, and the invite's group if it has one.
- **Admission**: the right to link one Minecraft account and so get onto the server.

It does **not** grant a Minecraft identity. That only comes from the link step (§ 5).

### 3.6 Admin UX (`/admin/invitations`)

- **Create personal:** a textarea of email addresses (bulk, one per line), expiry, optional group, optional personal note for the mail, and "Send email" (default on) or "just give me the links". The result lists each address with a Copy-link button and the mail status.
- **Create shared:** label, max uses, expiry and group. The result shows the code and link with Copy buttons, once.
- **List:** filters for status and kind; columns for uses/max, expiry, created by and label. Row actions: Resend, Rotate, Pause and Revoke. The redemption drawer shows who used the invite and whether that account is linked yet.
- Built from the existing patterns:
  - `LocationRetentionPage.tsx` for the list with status pills and `FeedbackModal`;
  - `RoadProfilesCard.tsx` for the inline create form;
  - a `Controllers.Invitations` client on `ObjectManager`;
  - `StaffRoute node="knk.admin.invites"`;
  - a link from the `UserModerationPage` header.

### 3.7 Later: player referrals

This is not for the alpha. The same table can give trusted players a quota, for example 2 personal invites a month. The redemptions table already records who invited whom, which is what a referral reward needs (`LootboxTokenReason.Referral`, paid when the invitee reaches some playtime, never at sign-up, so alt-farming doesn't pay). Default quota: 0.

---

## 4. Email engine (KNG-206, high priority)

### 4.1 Gaps in what exists

1. **No way out of the NAS.** This is the only reason the alpha has no real mail.
2. **The queue is in memory.** A restart or a full queue loses mail silently.
3. **Two mailers.** Account mail and privacy mail each have their own SMTP code, and bodies are hard-coded plain text.
4. **`System.Net.Mail.SmtpClient`.** Microsoft marks it "not recommended for new development" and points to MailKit.
5. **No outbound throttle.** Forgot-password has a 60 s cooldown per email and IP. Invite resends will need one too, or the system can be used to mail-bomb an address.
6. **No admin check** that mail actually works, and no mail log.

### 4.2 Design

```
AuthService / InvitationService / PrivacyService …
        │  IEmailComposer.Queue(kind, to, model, expiresAt?)
        ▼
  email_outbox (MySQL)  ◄── one transaction with the business change
        │
  EmailDispatcher : BackgroundService (PeriodicTimer 5 s + wake-up signal)
        │  render template → IEmailTransport.SendAsync
        ▼
  SmtpTransport (MailKit) │ LogTransport (dev) │ PickupTransport (.eml files, tests)
```

**Outbox and dispatch**
- **Outbox row:**
  - `Kind`, `To`, `Subject`, `TextBody` and `HtmlBody`;
  - `Status`: Pending, Sent, Failed, Expired or Suppressed;
  - `Attempts`, `NextAttemptAt`, `ExpiresAt`, `LastError`, `SentAt` and `ProviderMessageId`;
  - `UserId?`;
  - a unique `DedupeKey`, e.g. `invite:{id}:{sendNo}`.
- **Written in the same transaction as the change that causes it.** An invite that commits always gets its mail, and a rolled-back one never does.
- **Retries:** after 1 min, 5 min, 15 min, 1 h and 4 h, then `Failed`, which shows in the admin mail log.
- **Expiring mail:** rows that carry a token get `ExpiresAt` equal to the token's expiry. A reset mail that couldn't go out within 30 minutes is dropped rather than sent with a dead link.
- **No tokens kept in the database:** once a row is `Sent` (or `Expired`/`Failed`), both bodies are set to null. Only the metadata stays, for 90 days through `RetentionPolicyService`. The `LogTransport` writes links to the log, so it is allowed only in Development, or with an explicit `Email:AllowLogTransport=true` (today's alpha setting).

**Templates and settings**
- **Templates:** one HTML layout (logo, footer and a plain-text twin), with one `.html`/`.txt` pair per mail kind as embedded resources. Rendering is a small `{{name}}` replacer that HTML-encodes every value, so there is no extra dependency. If the templates outgrow that, Fluid (Liquid) is a drop-in.
- **One public base URL:** `App:PublicBaseUrl` replaces `Security:PasswordResetFrontendBaseUrl` and `Privacy:FrontendBaseUrl`, which stay as fallbacks.

**Protection and admin tools**
- **Throttle:** at most 3 mails per hour per recipient and kind, and 6 in total per recipient per hour. Anything over that is marked `Suppressed` and logged. A daily global cap (`Email:DailyCap`, e.g. 300) protects the provider quota and raises a currency-alert-style staff notice when it is hit.
- **Admin:** `POST /api/EmailOutbox/test` sends a test mail to the caller (`knk.admin.config`). `/admin/email` shows the log (status, kind, masked recipient, error) with a Retry action, and never shows bodies.
- **Headers:** `From: Knights & Kings <no-reply@knightsandkings.net>`, a `Reply-To` support address, `Auto-Submitted: auto-generated`, and a `Message-ID` on our own domain.

**As built (KNG-206, invitations chain link 2, 2026-10-21; feature branch, not merged).** As above, except:
- A **Failed** row keeps its bodies when it carries no token (no `ExpiresAt`), so staff can Retry it; token-carrying
  rows lose them on Failed as well (reason: Retry would otherwise never work).
- The **daily cap** logs an error once a day and shows on `/admin/email`; the in-game staff notice needs a new player
  notification and plugin handler and is a follow-up.
- The **Log** transport logs links in Development or with `Email:AllowLogTransport=true`; outside Development the API
  refuses to start with Log unless that is set (the alpha's setting until its relay works).
- The composer's signature is `QueueAsync(kind, to, model, dedupeKey, expiresAt?, userId?)`; it saves the caller's
  `DbContext`, so the row commits with an open transaction.
- An extra `Test` kind serves the admin test mail. Admin guide: [email.md](../../guides/email.md).

### 4.3 Provider and domain

The current production guide sends through **Gmail SMTP** (`knightsandkingsmc@gmail.com`, app password). That works for an alpha, but:
- mail comes from a gmail.com address, not the project's domain;
- consumer Gmail has daily send limits and can lock the account for automated sending;
- it can't be authenticated for `knightsandkings.net`.

Recommendation: a **transactional email provider** that offers SMTP, so the code stays provider-neutral, plus domain authentication for `knightsandkings.net`:
- SPF `include:` for the provider;
- DKIM CNAMEs;
- DMARC starting at `p=none` with reports, tightened to `quarantine` once the reports are clean;
- a custom return-path or bounce subdomain if the provider supports one.

Since 2024, Gmail and Yahoo require SPF, DKIM and DMARC from bulk senders, and they help deliverability at any volume.

| Option | Fit for the alpha | Notes |
|---|---|---|
| Resend, Brevo, Postmark (dev tier) | good | Free tiers cover tens of testers. Postmark is known for transactional deliverability. Check current limits at sign-up. |
| Amazon SES | good, cheapest at scale | Needs an AWS account and a request to leave the sandbox. |
| Gmail SMTP (current) | stop-gap only | Fine for § 4.6. Move off it before the beta. |

*(Decision E1: which provider. Default: start with the existing Gmail account for the quick win, then move to Resend or Postmark with domain DNS during KNG-206.)*

### 4.4 Getting mail out of the NAS

The API sits on the internal `backend` Docker network on purpose (go-live § 4). There are two ways out:

- **(a) An SMTP relay container (recommended).**
  - A small Postfix relay, e.g. the widely used `boky/postfix` image, sits on both `backend` and an egress network.
  - The API sends to `mailrelay:587` without a password. The relay only accepts mail from the backend subnet and holds the provider credentials itself.
  - The API keeps having no internet access, and the SMTP secret leaves the API's env file.
  - Today's `SmtpPasswordResetDeliveryService` throws when no credentials are set, so the quick win needs either relay auth (SASL) or a one-line relaxation.
- **(b) Give the API an egress network.** One compose line, but the API can then reach anything on the internet. Acceptable for the alpha if (a) is too much work. Go-live § 4 already names this option.

*(Decision E2. Default: (a).)*

### 4.5 Mails

| Mail | Trigger | Expires with |
|---|---|---|
| Invitation | admin creates or resends a personal invite | the invite |
| Welcome + "link your Minecraft account" | invite redeemed | — |
| Minecraft account linked | link done | — |
| Finish linking (reminder, optional) | 2 days redeemed-not-linked | — |
| Password reset | forgot-password (exists) | token, 30 min |
| Email changed (to old address) | `Auth/update` (exists), plus staff `update-email`, which doesn't notify today | — |
| Email verification | KNG-159, for shared-code sign-ups and email changes | token |
| Privacy deletion confirm / scheduled | exists (KNG-34) | token |

### 4.6 Quick win (before the engine)

1. Pick the provider. Today's Gmail account works with no DNS changes.
2. Add the relay container (§ 4.4 a), or the egress network (b).
3. Set `Email__Provider=Smtp` and the host/port on the alpha. With the relay, keep the SMTP password in the relay's secret file.
4. Test: forgot-password → the mail arrives → reset → old sessions end. Then the email-change notice.
5. Update go-live § 4 and the runbook.

The in-memory queue still loses mail on a restart, so a user would just ask again. The engine fixes that.

---

## 5. Web-first accounts and Minecraft linking

### 5.1 Root of trust

With `online-mode=true`, the Minecraft server only lets a player in after **Mojang's session server** has confirmed that the client owns the account. `AsyncPlayerPreLoginEvent` runs **after** that check, so the UUID there is authenticated. Everything below relies on this one fact.

A name typed on a web form proves nothing. The 2026-10-08 assessment showed this as SEC-7, the reason KNG-67 removed linking by name.

**Requirements this places on the server setup:**
- `online-mode=true`.
- If a proxy (Velocity) is ever added, it must use modern forwarding with a secret, because otherwise anyone can spoof a UUID to the backend server.
- Bedrock players through Geyser/Floodgate get XUID-based UUIDs and a name prefix. They need their own decision ([Bedrock report](../../reports/2026-10-06-bedrock-console-access.md) § open decisions) and are out of scope here.

### 5.2 Recommended: an admission gate with a claim code on the disconnect screen

The vanilla whitelist is replaced by a plugin check at pre-login (`admission.mode: invite`):

```
Player connects ──► Mojang auth (online-mode) ──► AsyncPlayerPreLoginEvent (plugin, runs first)
                                                    │  GET /api/Admission/{uuid}?name=…   (plugin key)
                                 ┌──────────────────┴──────────────────┐
                           admitted: true                         admitted: false
                       (UUID linked to an invited              API returns a claim code bound to
                        or grandfathered account)              {uuid, name}: 8 chars, 15 min,
                                 │                              one active per UUID (re-shown, not re-made)
                           normal join                                 │
                                                       disallow(KICK_WHITELIST, message):
                                                       "Knights & Kings is invite-only.
                                                        Go to knightsandkings.net/link and enter
                                                        K7QH-M2XA  (valid 15 minutes).
                                                        Never give this code to anyone."
```

- **The claim code** uses Crockford base32 (32^8, about 10^12) shown as `XXXX-XXXX`, because a disconnect screen can't be copied and has to be typed. It is a `linkcodes` row with `Purpose=Claim`, `UserId = null`, `MinecraftUuid` and `MinecraftName` ([KNG-208](https://linear.app/kngpandi/issue/KNG-208) adds the `Purpose` column).
- **No user row for strangers.** `PlayerListener.onValidateLogin` skips account creation when the login result is no longer `ALLOWED`, so random connections don't fill the `users` table.
- **Operators bypass the gate**, the same rule as `HubAdmissionListener`.
- **API down:** admitted UUIDs from the plugin's disk-backed cache (the KNG-58 pattern) still get in. Unknown UUIDs get "Can't check your access right now, try again in a minute." That is fail-closed for strangers, where today the plugin lets everyone in.
- **Kill switch:** `admission.mode: whitelist` (the vanilla whitelist again) or `open`. Turning the vanilla whitelist back on also works as an emergency gate, because it is checked after pre-login.
- To verify while implementing: on Paper 26.3, `AsyncPlayerPreLoginEvent` fires before the whitelist check, and a custom message with a disallow result shows on the client as written.

**As built (link 5, 2026-10-21, KNG-214 plugin):** the gate is `AdmissionListener` at `LOWEST` on
`AsyncPlayerPreLoginEvent`, configured under `admission:` in the plugin's `config.yml` (`mode: whitelist` by default).
Checked against the Paper 26.3 API sources: the event fires after Mojang authentication (also in offline mode, hence
`online-mode=true`), and the vanilla whitelist, ban and full-server verdict now reaches plugins through
`PlayerConnectionValidateLoginEvent`, later in the login, so the whitelist is still checked after the gate and stays
the kill switch. A banned stranger therefore sees the claim code, not the ban screen (L5-4). "Known" during an outage
means an identity in the offline security store within its max age (30 days). The live checks of the order and of the
multi-line screen are in the [progress report](../../reports/2026-10-21-invitations-chain.md) "Link 5".

### 5.3 Flows

**Web-first (personal invite)**
1. The tester gets the invite mail → `/invite/<token>`. The email is filled in and locked; they choose a password and accept the alpha rules → logged in. `EmailVerifiedAt` is set, because the link came through the inbox.
2. They land on `/account/link` (onboarding): "Join `play.knightsandkings.net` with Java 26.3. You'll be stopped with a code on screen — enter it here."
3. They join → see the claim code → enter it on `/account/link`.
4. The API checks that the code is valid and unused, that the UUID isn't linked yet and that the web account has no UUID yet. It then sets `Uuid` and `Username` (the Mojang-verified name) on the web account and marks it admitted. Mails and notices: a "linked" mail, and an in-game message on the next join.
5. They rejoin → admitted → first-join welcome and kits as today.

**Web-first (shared code)**
- The same flow from `/join?code=…`, except the redeemer types the email, which stays unverified (KNG-159).

**Game-first**
1. The player joins → the disconnect screen shows a claim code.
2. They go to `/link` without an account. The page says: "Verified: Minecraft account **Steve**. To create your account you need an invitation." It offers an invite-code field, or "check your email for an invitation link".
3. With an invite: create the account, and the claim code is linked in the same step.
4. Without an invite: a plain "the alpha is invite-only" page, optionally with a contact link. The page keeps the claim code for its 15 minutes, so a player who gets an invite meanwhile doesn't have to rejoin.

**Existing players (grandfathered)**
- A migration marks every existing active Minecraft account as admitted. They keep joining as today.
- Those without a web account still register with `/account link` → `Auth/register {linkCode, email, password}`. That path stays, but it only works for **admitted** accounts, so it can't be used to sign up without an invite.

**Staff**
- "Admit player" on the player profile, for edge cases like a tester who can't use the web. It works on accounts that already exist (a past join) or through a claim code the player reads out to staff. Staff can never admit by typed name.

### 5.4 Linking rules

| Situation at link time | What happens |
|---|---|
| Web account has no UUID, and no account has this UUID (the normal web-first case) | Set `Uuid` and `Username` on the web account. No merge. |
| Web account has no UUID, but a Minecraft-only account has this UUID (it joined before invites, or a grandfathered player made a second web account) | **Fold** the web account into the Minecraft account, which stays the primary because it holds stats, groups, kits, balances and history. Copy the email, password hash, `EmailVerifiedAt`, invite fields and any invite group. Soft-delete the web shell, revoke its sessions and issue a session for the merged account. This fixes [KNG-207](https://linear.app/kngpandi/issue/KNG-207). |
| UUID already linked to an account with credentials | Refuse ("This Minecraft account already has a web account. Log in with it, or use Forgot password."). Never a silent merge. |
| Web account already has a different UUID | Refuse. Changing a linked Minecraft account is a staff action (unlink in the player profile, audited). |

**As built (link 1, 2026-10-21, KNG-207):** `UserService.LinkMinecraftAccountAsync` implements this table. The fold runs in one locked transaction: ledger merge, the shell saved with `Email` **and** `PasswordHash` cleared (unique index; no two rows hold a login), then the Minecraft account receives `Email`, `PasswordHash`, `LastPasswordChangeAt`, `LastEmailChangeAt` and `EmailVerified`. The invite fields follow in I1, where they are created. The code is spent before the fold. The endpoint answers with a session for the survivor (`accessToken` + refresh cookie). A code for the caller's own account is spent and changes nothing; a reset-token hash is not a link code.

**Name changes:** `Username` follows the Mojang name on join, as today. A web account can never pick a name, so squatting isn't possible: until linked, the UI shows the email, and the `Username` column holds an internal `web-<id>` placeholder that can't be typed as a Minecraft name, because `-` isn't allowed in Minecraft names.

### 5.5 Abuse cases

| Attack | Mitigation |
|---|---|
| Claim someone else's Minecraft name from the web | Impossible: the identity only comes from a claim or link code made for a Mojang-authenticated session. Typed names are never trusted. |
| Guess a claim or link code | 32^8 codes, 15–20 min lifetime, rate limits per IP (`lookup` 20/min) and **per account** (5 failed codes → 15 min block, new). With 1,000 IPs and 10 live codes, the odds of a hit within one code lifetime are a few in a million. Making attacker accounts to spread the per-account limit costs an invite each. A hit would only bind a stranger's account, which the stranger sees on the next join (next row). |
| Social engineering: "give me your code" | The code text says "never give this code to anyone; staff never ask for it". After a link: a mail to the account, and an in-game message on the next join: "Linked to web account j\*\*\*@gmail.com — not you? `/account report`". Staff can unlink. |
| Mass sign-ups with a leaked shared code | Use cap, expiry, label, pause/revoke and the redemption list. Each redemption still needs its own Mojang account to play. Optional Cloudflare Turnstile on `/join` for the public beta. |
| Personal invite forwarded | The account is still created with the invited address, so the forwarder decides. Resend rotates the token. |
| Invite enumeration | A wrong, expired, revoked or used code all answer the same 400 `InvalidInvite`. Rate limited. |
| Privilege through invites | Only groups in `InvitableGroups` can be granted, checked with `PermissionEscalationGuard` when the invite is created. |
| Mail-bombing through resend or forgot-password | The § 4.2 throttle and the resend limit. |
| Spoofed UUID | `online-mode=true`, and modern forwarding if a proxy is added (§ 5.1). |
| Stolen Mojang account | Out of our control. Staff unlink plus the existing session revocation. |

**As built (link 4, 2026-10-21, KNG-214 API + web app):** after every new link (claim or `/account link` code, case A
or B) the account gets the `MinecraftLinked` mail and an `AccountLinked` in-game notice with the address masked as
`st***@example.com` (the existing `EmailMask`, not `j***@`). The notice sits in the API's in-memory queue for 24 hours,
as every player notification does. Staff "Detach web login" and "Admit" are on the player profile; admitting through a
claim code read out to staff isn't built, because a game-first stranger has no account to open (follow-up). A claim
code only links to an admitted web account.

### 5.6 Alternatives considered

| Option | Verdict |
|---|---|
| Keep the vanilla whitelist and have admins add names | Works with no plugin change, but every web-first tester needs a manual step, and the admin types a name, which is exactly the trust-a-typed-name problem, only at staff level. Fine as a stop-gap if invites ship before the gate. |
| Invitee types their Minecraft name, the API adds it to the whitelist, and they link with `/account link` | Better than manual, and identity is still proven by the code. But anyone with an invite can whitelist any name, and the plugin would have to edit `whitelist.json`. The gate needs no name at all. |
| Web → game code (`/account link <code>` typed in game) | As secure as game → web, but D1 picked game → web and the disconnect screen makes this direction unnecessary. |
| "Sign in with Microsoft" (Xbox Live → Minecraft services API) | Proves ownership without joining, but needs an Azure app *and* Mojang's approval for Minecraft API access. Heavy for an alpha. Worth revisiting for the public site. |
| A limbo/hub world for unadmitted players instead of a disconnect | Friendlier (they can click a link in chat), but strangers would get onto the server. Possible later with the hub (KNG-109). |

### 5.7 The outside gates

- **Minecraft whitelist:** off once `admission.mode: invite` is live and smoke-tested, and kept as the kill switch.
- **Cloudflare Access (D10):** stays in front of the site. The API keeps its allow-list in sync, and a narrow bypass opens only the sign-up pages (decision I8, next section).
- **The tester invite template** (go-live § 10) becomes the system's invitation mail. It explains the Cloudflare one-time PIN step.

### 5.8 Cloudflare Access sync (decision I8)

The developer chose to keep Access (decided 2026-10-21) and asked for smooth onboarding. A whole-site allow-list conflicts with invites in two ways:
- an invitee can't open their invite link before their email is allowed;
- a shared-code or game-first sign-up has no email on record until the account is created.

Two pieces solve this.

**1. A public bypass, limited to the sign-up paths.**
- A second Access application on the same hostname covers only these paths, with a *Bypass* policy. Access applies the most specific path, so everything else stays behind the tester policy.
  - Pages: `/invite/*`, `/join*`, `/link*`.
  - The SPA's static files: `/static/*`, `/favicon.ico`, `/manifest.json`, `/logo*.png`. These are public build output anyway.
  - The anonymous API calls those pages make: `/api/Invitations/check`, `/api/Admission/claim/check`, `/api/Auth/register`.
- These endpoints are already anonymous and rate-limited in the API. The WAF rule on `/api/Auth/` stays.

**2. The API keeps the tester list in sync.**
- The Access policy *Allow testers* includes:
  - a list the API owns: a Zero Trust email list used through the policy's email-list selector, or, if that selector isn't available on the plan, an Access group that the API rewrites;
  - the existing hand-made emails for staff, which the API never touches.
- **When the API adds an email:**
  - a personal invite is created → its email is added right away, so the invitee can enter straight after signing up;
  - a shared code is redeemed, or a game-first player signs up → the new email is added during registration;
  - a user changes their email → the new address is added.
- **When the API removes an email** (removal decided 2026-10-21):
  - a personal invite is revoked, or expires unused;
  - the account is deactivated or deleted, including a merge, which soft-deletes the merged-away account;
  - the user's old address after an email change.

  Freezing a player is a temporary in-game sanction, so it doesn't remove their web access. Deactivation is the "ban".
- **Reconcile, don't only push events.** A `CloudflareAccessSyncService` (`BackgroundService`, every 5 minutes, plus an immediate run after a change):
  1. computes the desired set from the database: active personal invites, plus active, non-deleted accounts with an email that were invited or grandfathered;
  2. compares it with the list;
  3. adds what is missing and removes what is extra, but only in the API-owned list.

  Failures retry on the next run, and the admin invitations page shows "Access sync: last OK 12:04, 0 pending".
- **During registration** the API tries the add inline, with a 5 s timeout, so the invitee is usually allowed before the "Done" page. If that fails, the next reconcile run catches it.
- **What the invitee sees:**
  1. invite mail → sign-up page (no PIN);
  2. "Done" page: "Next, Cloudflare sends you a one-time PIN to open the site";
  3. PIN → `/account/link`.

  The Access session for the tester policy is set to 30 days (today 24 h), so the PIN step is rare after that.
- **Credentials and egress:**
  - A Cloudflare API token limited to the account's Zero Trust/Access edit permission, in the env file as `CloudflareAccess__ApiToken`.
  - The API has no internet on purpose (§ 4.4), and the mail relay only carries SMTP. Calls to `api.cloudflare.com` therefore go through a small forward-proxy container (Squid or tinyproxy) that allows only `api.cloudflare.com:443`. Only the API's named `cloudflare` HttpClient uses it.
- **Kill switch:** `CloudflareAccess:SyncEnabled=false` goes back to manual list editing. Deleting the bypass application closes sign-up again without touching the app.

**Verified 2026-10-21 (link 6, KNG-216), from Cloudflare's current docs:**
- **Mechanism: a Zero Trust email list.** Lists ("reusable lists") hold one type each; *User email addresses* is one of them, and the docs say lists can be used in "Gateway policies or Access policies". The Access policy API accepts an include rule `{"email_list": {"id": "<list id>"}}` (`EmailListRule`), and the dashboard shows it as the *Email list* selector. No plan restriction is documented for it (only *User Risk Score* is Enterprise-only), so the free Zero Trust plan should have it. **The Access group fallback is not needed and was not built.**
- **API used by the sync:** `GET accounts/{account_id}/gateway/lists/{list_id}/items?page=&per_page=` (≤ 1,000 per page, flat `result` array of `{value, description, created_at}`, `result_info.total_pages`) and `PATCH accounts/{account_id}/gateway/lists/{list_id}` with `{"append": [{"value", "description"}], "remove": ["<value>", …]}`.
- **Token permission:** an account API token for this account only with **Account → Zero Trust → Edit** (named *Zero Trust Write* in the permissions reference), which covers Gateway lists. The token does not need *Access: Apps and Policies*: the API never touches the policy. The developer adds the list to the policy once, by hand.
- **Limits:** 1,000 entries per list on Standard (and 5,000 on Enterprise), 100 lists per account, 1,000 emails per Access rule. The docs give no separate free-plan number; the alpha needs a few dozen. **The free Zero Trust plan has 50 seats**: every person who logs in through Access uses one, so the alpha's ceiling is about 50 people including staff, whatever the list size.
- **Live checks** (developer, [alpha go-live § 6.1](../../guides/alpha-go-live.md)): the *Email list* selector shows in the *Allow testers* policy on this account; the token reads the list (`GET …/items`); appending a value already in the list, and removing the list's last entry, are accepted. The sync tolerates the first (it only appends what's missing), and the developer seeds the list with one staff address so it's never empty.

**As built (link 6):** `CloudflareAccess:*` settings, `ZeroTrustEmailList` behind `ICloudflareAccessList`, `CloudflareAccessSync` (the singleton that holds the status and serialises every list change) and `CloudflareAccessSyncService` (reconcile loop). The whole list is the API's: it removes anything in it that isn't in the desired set, so nobody edits that list by hand. A safety valve (`MaxRemovalsPerRun`, 25) skips a run's removals when there are more than that, and shows it as the sync error, so a bad desired set can't empty the list. Sync off (the default) means no Cloudflare calls at all and no `accessGate` in the register response.

---

## 6. Data model and API sketch

**New tables (knk-web-api)**
- `invitations`:
  - `Id`, `Kind` (Personal/Shared), `CodeHash` (unique) and `CodeHint` (last 4);
  - `Email?`, `Label?`, `Note?` and `GrantGroupId?`;
  - `MaxUses` and `UseCount`;
  - `CreatedAt`, `CreatedByUserId`, `ExpiresAt`, `PausedAt?`, `RevokedAt?` and `RevokedByUserId?`;
  - `SendCount` and `LastSentAt?`.
- `invitation_redemptions`: `Id`, `InvitationId`, `UserId`, `RedeemedAt`.
- `email_outbox`: as in § 4.2.

**Changed tables**
- `users`: `InvitedViaInvitationId?`, `InvitedByUserId?`, `AdmittedAt?`, and `EmailVerifiedAt?` (KNG-159; it replaces the bool, or sits next to it).
- `linkcodes`: `Purpose` (Link / PasswordReset / Claim), `MinecraftUuid?` and `MinecraftName?`. Failed codes are counted per account in memory by an `ILinkAttemptLimiter`, the same way as the login lockout, so there is no column (plan § 4.1).

**Audit:** claim a new `AuditAction` range for the following (36 is unused, so start at 37):
- InvitationCreated, InvitationRevoked, InvitationRedeemed;
- MinecraftLinked, MinecraftUnlinked;
- PlayerAdmitted.

`AuditLogService.RecordAsync` needs a target user above 0, so creating and revoking an invite target the actor.

**Endpoints** (each write gets an access rule; anonymous ones go on the `EndpointAccessRulesTests` allow-list):

| Endpoint | Rule |
|---|---|
| `GET/POST /api/Invitations`, `POST {id}/resend`, `{id}/rotate`, `{id}/pause`, `{id}/revoke`, `GET {id}/redemptions` | `RequirePermission(knk.admin.invites)` |
| `POST /api/Invitations/check` `{token \| code}` → `{valid, kind, emailHint?, expiresAt}` | `AllowAnonymous`, `auth` rate limit |
| `POST /api/Auth/register` `{inviteToken \| inviteCode \| linkCode, claimCode?, email, password, passwordConfirmation}` | exists; extended. `linkCode` alone only for admitted accounts |
| `POST /api/Users/link-minecraft-account` `{code}` (link or claim code) | exists (`Authorize`); new rules from § 5.4 |
| `POST /api/Admission/claim/check` `{code}` → `{valid, minecraftName}` (for `/link` before login) | `AllowAnonymous`, `lookup` rate limit |
| `GET /api/Admission/{uuid}?name=` | `RequirePluginService` |
| `POST /api/Users/{id}/admit`, `/{id}/detach-web-login` (clears the web login; the Minecraft account and its data stay) | `RequirePermission(ManageUsers)` |
| `GET /api/EmailOutbox`, `POST /api/EmailOutbox/test`, `/{id}/retry` | `RequirePermission(ServerConfig)` |
| `GET /api/Invitations/access-sync` | `RequirePermission(knk.admin.invites)` |

**Config**
- `Invitations`:
  - `DefaultExpiryDays` = 7, `MaxExpiryDays` = 30;
  - `SharedDefaultMaxUses` = 5, `SharedMaxUsesCap` = 50;
  - `InvitableGroups` = ["Alpha Tester"], `ResendPerDay` = 3.
- `Security:Registration:Mode` = `LinkCode` (today) | `Invite` | `Open`. It replaces `AllowWebFirst`, which stays read as a fallback.
- `Email`: `Transport`, `DailyCap`, `AllowLogTransport`, plus the existing SMTP keys.
- `App:PublicBaseUrl`.
- `CloudflareAccess`: `SyncEnabled`, `AccountId`, `ListId` (or `GroupId`), `ApiToken` (secret), `ProxyUrl`, `ReconcileMinutes` = 5.

**Plugin config:** `admission.mode`, the `admission.kick-message` template (`{code}`, `{url}`, `{minutes}`) and `admission.fail-message`.

**Web app**
- `/invite/:token`, `/join`, `/link` and `/account/link` (onboarding).
- An "unlinked" banner.
- `/admin/invitations` and `/admin/email`.
- New landing-page "How to join" copy: invitation → account → join → enter the code.

---

## 7. Work packages and order

Steps, files, tests and merge order are in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).


| # | Package | Repos | Depends on | Issue |
|---|---|---|---|---|
| E0 | **Real mail on the alpha now:** relay container + Gmail, `Email__Provider=Smtp`, optional SMTP auth in the API, reset tested, go-live and runbook updated | api (small), NAS compose, workspace | — | KNG-211 |
| E1 | **Email engine:** outbox and dispatcher, MailKit transport, templates and layout, throttle and daily cap, test endpoint and mail log, migrate reset/notice/privacy mails, staff email change notifies the old address | api, web-app | E0 | KNG-206 |
| L0 | **Link hygiene:** `Purpose` column, unbiased generator, cleanup job, KNG-207 merge direction | api, plugin | — | KNG-207, KNG-208 |
| I1 | **Invitations:** tables, admin API and page, check/redeem, register with an invite, web-first shell accounts, invite mails, audit | api, web-app | E1 (for mail; copy-link works without it), L0 | KNG-212 |
| I2 | **Admission gate and claim codes:** `Admission` API, plugin pre-login listener and cache, `/link` pages, link rules (§ 5.4), linked notices (new `PlayerNotification` type `AccountLinked`) | api, plugin (branch from the KNG-182 Paper 26.3 branch), web-app | L0, I1 | KNG-214 |
| A1 | **Cloudflare Access sync:** API-owned list, reconcile service, inline add on registration, forward-proxy container, bypass application for the sign-up paths, sync status on the admin page | api, NAS, Cloudflare dashboard | I1 | KNG-216 |
| I3 | **Rollout:** migration that admits existing accounts and seeds the *Alpha Tester* group and `knk.admin.invites` for Admin; smoke-test guide; go-live § 5/§ 10 and the runbook; Access session 30 days; whitelist off | workspace, api migration, NAS | I1, I2, A1 | KNG-218 |
| later | Email verification (KNG-159), player referral quotas and rewards, Turnstile, provider bounce webhooks, Microsoft sign-in, Bedrock | — | — | KNG-159, new |

I1 and I2 should reach the alpha **together**. On its own, I1 creates web accounts that still need someone to whitelist a typed name.

I1, I2 and A1 reach the alpha together. The packages fit the session-chain model: E0 is ops with the developer, and E1, L0+I1, I2+A1 and I3 can each be one chain link.

---

## 8. Decisions (made 2026-10-21)

The developer answered every question in the Claude app on 2026-10-21. All recommendations were taken except I8, which keeps Cloudflare Access.

| # | Question | Decision |
|---|---|---|
| I1 | Both personal invites and shared codes in the alpha, or personal only? | **Both.** Shared codes default to 5 uses and 7 days, with a hard cap of 50. |
| I2 | Default and maximum expiry | **7 days default, 30 days max**, for both kinds. No "never". |
| I3 | Does every new account need an invite, including game-first players? | **Yes.** Existing accounts are grandfathered as admitted. The developer expects this to hold for at least the alpha test sessions, and maybe the beta. |
| I4 | Group granted on redemption | An optional *Alpha Tester* group, from an invitable allow-list. Staff groups never. |
| I5 | Codes shown once (hash only), or viewable again? | **Show once**, with rotate. |
| I6 | Replace the vanilla whitelist with the plugin admission gate and disconnect-screen claim code? | **Yes.** The whitelist stays as the kill switch. |
| I7 | Merge direction when a web shell links to an existing Minecraft account | **The Minecraft account stays primary** (fold the credentials in; KNG-207). |
| I8 | Cloudflare Access allow-list once invites are live | **Keep Access, and the API keeps the list in sync**: an API-owned list, a public bypass for the sign-up paths only, and automatic removal on revoke, unused expiry, deactivation or deletion (§ 5.8). *(Recommended was: drop it.)* |
| I9 | Player referrals in the alpha? | **No.** Design hook only, quota 0. |
| E1 | Mail provider | **Gmail now (E0)**, then Resend or Postmark with `knightsandkings.net` SPF/DKIM/DMARC in E1. |
| E2 | How mail leaves the NAS | **SMTP relay container (§ 4.4 a).** |
| E3 | Sender address | **`no-reply@knightsandkings.net`**, with `Reply-To: support@knightsandkings.net` (monitored). |

## 9. Not in scope

- Bedrock/Floodgate identity.
- Paid entitlements.
- Account deletion changes.
- Marketing sign-ups as web-only accounts without play access. `Registration:Mode=Open` leaves room for this.
- Email verification UI beyond what invites give for free (KNG-159).
