# Invitations, admission and the Cloudflare Access sync — admin guide

**Status:** Current · **Last updated:** 2026-11-13 (first version, PandiO/knk-workspace#299)
**Checked against:** knk-web-api `master` `75b5a00`, knk-web-app `main` `3ba747d`, knk-plugin `main` `57884e9`; the alpha runs invite-only since 2026-10-24 ([switch-over report](../../reports/2026-10-24-alpha-phase-9-invite-only.md))
**Related:** [account player guide](../users/account-player-guide.md) (what players see), [email guide](../email.md), [invitations smoke test](../invitations-smoke-test.md), [alpha go-live § 4.1, § 5.1, § 6.1, § 11.1](../alpha-go-live.md), [plugin configuration § 4.5](plugin-configuration.md#45-web-admission-join-refusal-notify-onboarding), [design](../../specs/invitations/DESIGN.md), [architecture](../../architecture/account-identity-and-admission.md)

The closed alpha is invite-only. Staff issue **invitations**; an invitation creates a web account; the game server's
**admission gate** lets in only Minecraft accounts that belong to an admitted account; and the API keeps a
**Cloudflare Access** email list in step with who may open the website. This guide is for staff who issue invitations
and for the admin who runs the switches. How players sign up and link is in the
[account player guide](../users/account-player-guide.md); this guide doesn't repeat it.

## Contents

1. [Who can do what](#1-who-can-do-what)
2. [The switches](#2-the-switches)
3. [Issuing invitations](#3-issuing-invitations)
4. [Managing invitations](#4-managing-invitations)
5. [Mails](#5-mails)
6. [Admission and the Access card](#6-admission-and-the-access-card)
7. [The Cloudflare Access sync](#7-the-cloudflare-access-sync)
8. [Kill switches](#8-kill-switches)
9. [Safe test procedure](#9-safe-test-procedure)
10. [Troubleshooting](#10-troubleshooting)

## 1. Who can do what

| Task | Where | Node |
|---|---|---|
| Create, resend, rotate, pause, resume, revoke invitations; see redemptions and the Access sync line | **Admin → Players → Invitations** (`/admin/invitations`) | `knk.admin.invites` (the **Admin** group has it, migration `SeedInvitationStaffNode`) |
| See the mail log, retry, send a test mail | **Mail log** (`/admin/email`) | `knk.admin.config` ([email guide § 5](../email.md#5-the-admin-page-adminemail)) |
| **Admit** a player, **Detach web login**, deactivate an account | Player profile (`/admin/users/<id>`) → **Moderation** tab → **Access** card; the user form | `knk.admin.user.manage` |
| Change the switches (§ 2) | API settings, plugin `config.yml`, Cloudflare dashboard | Host access (the developer) |

Without the node, a page shows the "staff only" or "Requires …" screen and has no link in the admin sidebar.

## 2. The switches

All four are off by default, which keeps the old whitelist-and-link-code behaviour. On the alpha all four are on
since 2026-10-24.

| Where | Setting | Default (off) | Invite-only (on) | Applies |
|---|---|---|---|---|
| API | `Security__Registration__Mode` | `LinkCode` | `Invite` | Recreate the API |
| Plugin `config.yml` | `admission.mode` | `whitelist` | `invite` | **Server restart** (`/knk reload` doesn't switch it) |
| `server.properties` | `white-list` | `true` | `false` (on the alpha: Compose `ENABLE_WHITELIST`/`ENFORCE_WHITELIST: "FALSE"`, or the image turns it back on at every start) | Server restart |
| API | `CloudflareAccess__SyncEnabled` | `false` | `true`, with the other `CloudflareAccess__*` settings (§ 7) | Recreate the API |

What each mode means:

1. **`Mode=LinkCode`:** new web accounts only come from an `/account link` code; invitation sign-ups are refused
   ("Sign-up with an invitation isn't open yet…", `InvitesDisabled`). `/admin/invitations` shows a yellow warning
   but lets you create invitations ahead of the switch.
2. **`Mode=Invite`:** an invitation creates a web account. An `/account link` code alone works only for an admitted
   (grandfathered) Minecraft account. `Open` is reserved and behaves like `Invite`.
3. **`admission.mode: invite`** (only stops anyone while the API is in `Invite`): at pre-login the plugin asks the API
   whether the UUID belongs to an admitted account. Operators bypass the gate. Everyone else gets the disconnect
   screen with a **claim code**. `whitelist`: no gate, the vanilla whitelist decides. `open`: no gate.

Other settings, with their defaults (change only for a reason):

| Setting | Default | What it does |
|---|---|---|
| `Invitations__DefaultExpiryDays` / `MaxExpiryDays` | `7` / `30` | Expiry offered on the form; the maximum for both kinds (no "never") |
| `Invitations__SharedDefaultMaxUses` / `SharedMaxUsesCap` | `5` / `50` | Uses of a shared code |
| `Invitations__InvitableGroups` | `["Alpha Tester"]` | The only groups an invitation may grant. Never add a staff group |
| `Invitations__ResendPerDay` | `3` | Resends of one personal invite in 24 hours |
| `Invitations__MaxEmailsPerRequest` | `100` | Addresses per "Create invites" |
| `Admission__ClaimCodeMinutes` | `15` | Life of a claim code from the disconnect screen |
| `Admission__FinishLinkingReminderDays` | `2` | One reminder mail to an invited account still unlinked after this many days (`0` = off) |
| `Security__LinkCodeExpirationMinutes` | `20` | Life of an `/account link` code |
| `Security__LinkAttempts__*` | 5 failures / 15 min → 15 min lock | Wrong link and claim codes per account |
| `RateLimiting__Auth__PermitPerMinute` | `10` | Per IP: invitation checks, sign-up, login, reset requests. Claim-code checks on `/link` allow 20 a minute |
| Plugin `admission.api-timeout-ms` | `3000` | How long pre-login waits for the API before the outage rule (§ 6) |
| Plugin `admission.link-url` | `""` | Where the claim code is entered; empty = `{web.public-url}/link` |
| Plugin `admission.kick` / `unavailable` / `deactivated` / `account-linked` | (texts) | The disconnect screens and the in-game "now linked" notice ([plugin configuration § 4.5](plugin-configuration.md#45-web-admission-join-refusal-notify-onboarding)) |

The API settings with their alpha values are in [alpha go-live § 4.1](../alpha-go-live.md#41-after-the-invite-only-switch-over-kng-205);
the plugin section in [§ 5.1](../alpha-go-live.md#51-after-the-switch-over-the-admission-gate-instead-of-the-whitelist-kng-214).

## 3. Issuing invitations

Open **Invitations**. The page has two tabs. Both create forms show the server defaults as placeholders.

### Personal invites

For one person, one email address, one use.

1. Tab **Personal invites**. **Email addresses (one per line)**: one or more addresses (commas and semicolons work
   too).
2. **Expires after (days)**: empty = 7, at most 30.
3. **Group on sign-up**: **No group** or an invitable group (**Alpha Tester**). You can only hand out a group your
   own rank allows.
4. **Note (for staff, not mailed)**: who it is for, why.
5. **Send the invitation email**: on by default. Off: you only get the links, to send yourself.
6. **Create invites**.

The result panel lists each address: **Copy link for …** and the mail status ("Mail pending", "Mail sent", or "Mail
held back by the throttle - send the link yourself"), or **Skipped** with the reason: not a valid email address, an
account already uses this address, or listed twice. **Copy what you need now: links and codes are not shown again.**
The list keeps only the last characters of each code (`…AB12`).

A new personal invite for an address revokes that address's earlier active invite.

### Shared codes

For a group (a Discord channel, a stream), with a use cap.

1. Tab **Shared codes**. **Label** (required): where the code goes, so a leaked code can be traced, for example
   `Discord #announcements 21 Oct`.
2. **Max uses**: empty = 5, at most 50. **Expires after (days)**: empty = 7, at most 30. **Group on sign-up** as above.
3. **Create code**. Copy the code (`KNK-XXXXX-XXXXX`) or the link (`/join?code=…`) now.

A shared-code sign-up types its own email, so that address is not verified (PandiO/knk-workspace#139).

### What a sign-up gets

The account is created with a generated `web-…` username, **admitted** (it may play once linked), in the **Default**
group plus the invitation's group. The starting balance (`SIGNUP_GRANT`) comes when the Minecraft account is linked,
not at sign-up. The invite's use count goes up; the audit log records `InvitationCreated`, `InvitationRedeemed`,
`MinecraftLinked` and (on the Access card) `PlayerAdmitted`.

## 4. Managing invitations

The list shows per invitation: email or label, status, uses (`n / max`), expiry, group, and who created it. Filter by
**Status**.

| Status | Meaning |
|---|---|
| Active | Can be used |
| Paused | A shared code staff paused |
| Exhausted | All uses taken |
| Expired | Past its expiry |
| Revoked | Stopped for good |

A status shows the strongest reason: Revoked over Exhausted over Expired over Paused.

| Action | For | What it does |
|---|---|---|
| **Resend** | Personal, not Revoked or Exhausted (also Expired) | Mails a **new** link and restarts the expiry at the default (7 days). The old link stops working. At most 3 resends in 24 hours ("resent 3 times in the last 24 hours") |
| **Rotate** | Shared, not Revoked | A new code replaces this one; uses so far are kept. The old code and link stop working at once. The expiry stays: rotating an **Expired** code leaves it expired (PandiO/knk-workspace#450); create a new code instead |
| **Pause** / **Resume** | Shared, Active / Paused | Nobody can sign up with it until resumed |
| **Revoke** | Any, not Revoked | Stops it for good. Accounts already created with it stay |
| **Redemptions** | Any with uses | Who signed up with it: name once linked, masked email, **Linked** or **Not linked yet**, when |

Every action asks for confirmation. A player using a revoked, expired, used-up or made-up code or link sees the same
"This invitation is invalid or has expired" message: the site never says why. A revoked personal invite's address
leaves the Cloudflare list (§ 7).

## 5. Mails

All mails go through the mail engine ([email guide](../email.md)); watch them on `/admin/email`.

| Kind | When | Notes |
|---|---|---|
| `Invitation` | A personal invite is created or resent with mail on | The link, the expiry, the inviter's name; with the Access sync on, the Cloudflare step too. At most 3 invitation mails per address an hour: the 4th is **Suppressed** |
| `Welcome` | An invitation sign-up | What to do next (join, code, link) |
| `MinecraftLinked` | A Minecraft account is linked to the web account | To the account's address, so the owner hears of every link |
| `FinishLinking` | An invited account is still unlinked after 2 days | Once per account |
| `PasswordReset`, `EmailChanged` | Player actions | See the [player guide](../users/account-player-guide.md#forgot-your-password) |

With the Access sync on, Invitation, Welcome, FinishLinking and PasswordReset carry a line about Cloudflare's email
and 6-digit code; with it off, no mail mentions Cloudflare.

## 6. Admission and the Access card

### Who gets in (`admission.mode: invite`)

1. An **operator**: always, without asking the API.
2. A Minecraft account that belongs to an **admitted** account: in. Every account that existed when the feature was
   deployed was admitted then (grandfathered); an invitation sign-up is admitted; staff can **Admit**.
3. A **deactivated** account: "This account is deactivated."
4. Anyone else: the disconnect screen with a claim code (`XXXX-XXXX`, 15 minutes, the same code on a rejoin within
   that time). No user row is created; the server log says `Refused <name> (<uuid>): admission.kick` and never the
   code. Holders of `knk.notify.joinattempt` get a chat line with the reason (`join-refusal-notify`).
5. **API down or too slow** (`admission.api-timeout-ms`): players the server's offline cache knows get in after a
   few seconds; strangers get "Can't check your access right now" (fail closed). `/knk health` shows the API state.

The gate follows a Minecraft name change: an admitted player who renamed gets the new name on the account at the next
join.

### The Access card

Player profile → **Moderation** tab → **Access**: **Admission** (Admitted / Not admitted), **Minecraft** (Linked /
Not linked), **Web login** (the email or None).

1. **Admit** (only while "Not admitted"): the player can join without an invitation from now on. Recorded in the
   audit log ("Admitted by staff"). Use it for a person you let in without an invitation, or a reactivated account.
2. **Detach web login** (a linked account with a web login): removes the email and password from the account and
   ends every session. The Minecraft account and its data stay; the owner registers again with `/account link`. Use
   it when a player gave a code away and someone else's web login is now on their Minecraft account.

**Deactivating** an account has no button of its own: untick **Is active** in the staff user form (it also ends the
account's web sessions). The player then gets "This account is deactivated" at the gate and can't log in.

### A web account linked to the wrong Minecraft account

Players can't unlink or switch ("Changing it is a staff action."). Detach the web login from the Minecraft account,
then the right owner registers with `/account link`.

## 7. The Cloudflare Access sync

The alpha website sits behind Cloudflare Access. With the sync on, the API owns one Zero Trust email list and keeps it
equal to who may open the site. The Cloudflare setup itself (list, policy, token, bypass application, proxy) is in
[alpha go-live § 6.1](../alpha-go-live.md#61-cloudflare-access-sync-and-the-sign-up-bypass-kng-216).

### Who is on the list

1. The addresses of personal invites that can still be used (not revoked, not used up, not expired).
2. The email of every active, non-deleted account that is admitted or came in through an invitation. Frozen players
   stay on: freezing is an in-game sanction.

Everything else on the list is **removed**, so nobody edits the list by hand while the sync is on. Staff get in
through the policy's separate staff include, which the sync never touches.

### When it runs

Every 5 minutes (`CloudflareAccess__ReconcileMinutes`), and within seconds after a change: a new, resent or revoked
invite, a sign-up (inline, waiting at most 5 seconds before the account is created anyway), an email change, a
deactivation or reactivation, a merge.

### The status line on `/admin/invitations`

1. "Access sync: off. Add new players to the Cloudflare Access list by hand."
2. "Access sync: last OK 12:04 · 0 pending · 7 on the list" (green).
3. "Access sync: failing · … · n pending" (red) with the last error.

It is read when the page loads; press **Refresh** to update it.

### Settings

`CloudflareAccess__SyncEnabled`, `AccountId`, `ListId` (a list of type "User email addresses"), `ApiToken` (secret:
environment only, never in a settings file; the token needs Zero Trust edit permission), `ProxyUrl` (the API container
has no internet of its own; on the alpha `http://cfproxy:8888`), `ReconcileMinutes` (5), `InlineAddTimeoutSeconds`
(5), `MaxRemovalsPerRun` (25). An enabled sync with a missing setting logs one start-up error naming the setting and
makes no calls.

**Safety valve:** a run that would remove more than `MaxRemovalsPerRun` addresses removes none and reports "n removals
held back". Check the desired set (who is admitted, which invites are live) before raising the limit and restarting.

### Pages that skip Cloudflare

The sign-up pages and their API calls must open without the Access login, or a newcomer can't start. On the alpha a
**bypass application** lists `/invite`, `/invite/*`, `/join*`, `/link*`, the static files and
`/api/Invitations/check`, `/api/Admission/claim/check`, `/api/Auth/register` and `/api/Auth/onboarding-info`.
Deleting the bypass application closes sign-up (§ 8).

## 8. Kill switches

Run each from the [smoke test § 6](../invitations-smoke-test.md#6-kill-switches-plan--8) when you need it; undo in the
reverse order. No migration needs undoing; the tables stay unused while a switch is off.

| Switch | How | Effect |
|---|---|---|
| Gate off | `admission.mode: whitelist`, **restart** the server, and whitelist on (on the alpha: the Compose whitelist variables back to `"TRUE"`) | Strangers get "You are not whitelisted"; no claim codes, no admission requests |
| Sign-up off | `Security__Registration__Mode=LinkCode`, recreate the API | Invitation sign-ups refused ("Sign-up with an invitation isn't open yet…"); `/account link` registration works as before |
| Access sync off | `CloudflareAccess__SyncEnabled=false`, recreate the API | No Cloudflare calls; "Access sync: off"; the list stays as it was, staff edit it by hand |
| Sign-up pages closed | Delete the Cloudflare bypass application | `/invite` and `/join` ask for the Access login |

Rolling back the whole feature: gate first, then sign-up, then the sync ([alpha go-live § 11.1](../alpha-go-live.md#111-switch-over-to-invite-only-kng-218)).

## 9. Safe test procedure

1. On dev, follow the [invitations smoke test](../invitations-smoke-test.md): § 3 (invitations), § 4 (gate and claim
   linking), § 6 (kill switches), § 7 (Access sync; needs a Cloudflare test account). It needs a Minecraft account
   that has never joined.
2. On the alpha, test with your own address aliases and a second Minecraft account. Revoke test invites afterwards;
   a test account you leave behind keeps an Access list entry (deactivate it to take it off).
3. Before a tester run, check the Access sync line is green and `/admin/email` → **Send test mail to me** arrives.

Not yet run on the alpha (passed on dev): an expired claim code and the gate-off kill switch
([switch-over report § 9](../../reports/2026-10-24-alpha-phase-9-invite-only.md#9-alpha-checks-switch-over-step-5-smoke-test--9)).

## 10. Troubleshooting

| Symptom | Cause and fix |
|---|---|
| Yellow "Sign-up with invitations is off on this server (Security:Registration:Mode is LinkCode)" | The API runs in `LinkCode`. Expected before the switch-over; otherwise set `Mode=Invite` |
| No **Invitations** link in the sidebar | No `knk.admin.invites` |
| "Mail held back by the throttle" | More than 3 invitation mails to that address within an hour. Copy the link and send it yourself, or wait |
| "This invitation was resent 3 times in the last 24 hours" | Resend limit; wait, or create a new personal invite (that revokes this one) |
| Group missing from **Group on sign-up**, or "This group can't be granted by an invitation" | Only `Invitations:InvitableGroups` (Alpha Tester) may be granted |
| "You can't hand out this group" | The group ranks above what your own rank may grant |
| A player with a valid shared code gets "invalid or has expired" | Code paused, used up, rotated (the old code is dead) or expired. Check its status; Rotate doesn't revive an expired code (PandiO/knk-workspace#450) |
| A newly invited player can't open the site at all | Their address isn't on the Access list yet (sync line red or pending), or the bypass application is missing. Check the line, press **Refresh** |
| Access sync red, error mentions 403 | The API token's permission doesn't cover Zero Trust lists |
| Access sync red, connection errors | The proxy (`cfproxy` on the alpha) is down. Sign-ups still work (≤ 5 s slower); the next run catches up once it is back |
| "n removals held back" | The safety valve (§ 7). Find out why so many addresses would go before raising `MaxRemovalsPerRun` |
| Every new player gets "Can't check your access right now" | The API is down or slower than `admission.api-timeout-ms`; check `/knk health` and the API |
| Bedrock players always get "Can't check your access right now" | The API only accepts `A–Z a–z 0–9 _` names: Floodgate's `username-prefix` must not be `.` (the alpha uses `BE_`) |
| A player linked the wrong Minecraft account, or a code was given away | **Detach web login** (§ 6) |
| A stranger got in although the gate is on | Check `admission.mode` (needs a restart after a change), the API's `Mode` (the gate only stops anyone in `Invite`), and whether the player is an operator |

## Changes

1. 2026-11-13: first version (PandiO/knk-workspace#299).
