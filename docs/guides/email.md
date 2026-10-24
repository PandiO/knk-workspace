# Email — admin guide

**Status:** Current for knk-web-api `master` and knk-web-app `main` since the KNG-206 merge on 2026-10-24 (smoke-tested on
dev with the Pickup transport, [invitations smoke test § 1](invitations-smoke-test.md)); not yet live on the alpha.
**Last updated:** 2026-10-21 (written by invitations chain link 2)
**Linear:** [KNG-206](https://linear.app/kngpandi/issue/KNG-206) (engine), [KNG-211](https://linear.app/kngpandi/issue/KNG-211) (relay on the alpha)
**Design:** [invitations DESIGN § 4](../specs/invitations/DESIGN.md), [IMPLEMENTATION_PLAN § 3](../specs/invitations/IMPLEMENTATION_PLAN.md)

The API sends every mail through one engine: password resets, the "your email was changed" notice, the data-deletion
mails and, later, invitations and welcome mails. This guide says how it works, how to configure it, how to check that
it works, and what to do when it doesn't.

## 1. How it works

```
AuthService / PrivacyEmailService / UsersController …
        │  IEmailComposer.QueueAsync(kind, to, model, dedupeKey, expiresAt?)
        ▼
  email_outbox (MySQL)  ◄── same DbContext, same transaction as the change
        │
  EmailDispatcher (every 5 s, or at once when something is queued)
        ▼
  Smtp (MailKit) │ Log │ Pickup (.eml files)
```

- **Persistent.** A queued mail is a row in `email_outbox`. A restart doesn't lose it; the dispatcher picks it up again.
- **Retries.** A failed send is retried after 1 min, 5 min, 15 min, 1 h and 4 h. After 6 attempts the mail is
  **Failed** and shows on `/admin/email`.
- **Expiring mails.** A mail that carries a link with a token (reset, data-deletion confirm) expires with the token. A
  reset mail that couldn't go out within 30 minutes becomes **Expired** and is never sent with a dead link.
- **No tokens kept.** Once a mail is Sent, Expired or Suppressed, its content is deleted; only the metadata stays. A
  Failed mail keeps its content only when it carried no token, so staff can retry it. Rows are deleted after 90 days.
- **Throttle.** Per recipient at most 3 mails an hour of one kind class (e.g. password resets) and 6 in total; across
  everyone at most `Email:DailyCap` (300) in 24 hours. A mail over a limit is stored as **Suppressed** (no content) and
  logged. Reaching the daily cap logs an error once a day.
- **Templates.** Each kind has an HTML and a text part inside one layout (logo, "You get this mail because …", the
  support line). They are embedded in the API (`Services/Email/Templates/`); changing a text means a new API build.
- **Headers.** `From: <FromName> <FromAddress>`, `Reply-To` when set, `Auto-Submitted: auto-generated`, and a
  `Message-ID` on the sender's domain.

| Status | Meaning |
|---|---|
| Pending | Waiting for its first or next attempt |
| Sent | The mail server accepted it |
| Failed | 6 attempts failed; Retry is offered when the content was kept |
| Expired | Its link expired before it could be sent |
| Suppressed | Over the throttle or the daily cap; never sent |

## 2. Settings

All under `Email:` (environment `Email__…`) unless noted.

| Setting | Default | Notes |
|---|---|---|
| `Transport` | empty | `Smtp`, `Log` or `Pickup`. Empty: `Provider` is used. |
| `Provider` | `Smtp` in `appsettings.json` (`Log` in Development) | The setting before KNG-206; still read as the fallback, so `Email__Provider=Log` keeps working. |
| `AllowLogTransport` | `false` | Outside Development the API **refuses to start** with the Log transport unless this is `true`, because Log writes reset links to the log. |
| `SmtpHost` / `SmtpPort` | `smtp.gmail.com` / `587` | Port 465 always uses TLS on connect. |
| `UseStartTls` | `true` | STARTTLS when the server offers it; `false` for the internal hop to the relay. |
| `SmtpUsername` | Gmail address | **Empty: no SMTP authentication** (the relay). Set: `SmtpPassword` is required, or every send fails with a message naming `Email:SmtpPassword`. |
| `SmtpPassword` | empty | Secret: env or user-secrets only, never in a settings file. |
| `FromAddress` / `FromName` | Gmail address / `Knights & Kings` | Decision E3 later: `no-reply@knightsandkings.net`. |
| `ReplyToAddress` | empty | Decision E3: `support@knightsandkings.net` once that mailbox is monitored. |
| `PickupDirectory` | `mail-pickup` | Folder for the Pickup transport. |
| `DailyCap` | `300` | Mails per 24 hours across everyone. |
| `MaxAttempts` | `6` | Attempts before Failed. |
| `App:PublicBaseUrl` | empty | The web app's address for links in mails. Empty: `Privacy:FrontendBaseUrl` / `Security:PasswordResetFrontendBaseUrl`, then `http://localhost:3000`. |

### Transports

- **Smtp** — real mail through an SMTP server (MailKit).
- **Log** — writes kind, masked recipient and subject to the API log, plus the text part with its links in
  Development or with `AllowLogTransport=true` (so staff can hand a reset link to a tester while there is no relay).
  Outside Development the API only starts with Log when `AllowLogTransport=true`.
- **Pickup** — writes each mail as an `.eml` file to `PickupDirectory`; open it in any mail client. For dev and tests.

### Development

`appsettings.Development.json` uses `Provider=Log`: reset links appear in the console. To see the real mails, set
`Email__Transport=Pickup` and open the `.eml` files in `mail-pickup/` (ignored by git).

## 3. The alpha: relay container (decision E2)

The alpha API sits on the `backend` network without internet access. Mail leaves through a small Postfix relay
(`mailrelay`, image `boky/postfix`) on `backend` and an egress network; the relay holds the Gmail app password, the API
holds no SMTP secret. Setting up the relay is KNG-211 (E0); the steps are in
[IMPLEMENTATION_PLAN § 2](../specs/invitations/IMPLEMENTATION_PLAN.md) and the [go-live guide § 4](alpha-go-live.md).

API env with the relay:

```ini
Email__Transport=Smtp
Email__SmtpHost=mailrelay
Email__SmtpPort=587
Email__UseStartTls=false
Email__SmtpUsername=
Email__FromAddress=knightsandkingsmc@gmail.com
App__PublicBaseUrl=https://<web-host>
```

**Until the relay works**, the alpha keeps `Email__Provider=Log` and must add `Email__AllowLogTransport=true`, or an API
build with this engine won't start. Remove it once mail goes out.

## 4. Provider and DNS (later, before the beta)

Gmail is a stop-gap: it sends from a gmail.com address, has daily limits and can't be authenticated for our domain.
Before the beta (decisions E1, E3):

1. Open a Resend or Postmark account (check the free tier at sign-up).
2. Add the provider's DNS records for `knightsandkings.net`: SPF (`include:` the provider), the DKIM CNAMEs, and DMARC
   starting at `v=DMARC1; p=none; rua=mailto:<reports address>`. Tighten to `p=quarantine` once the reports are clean.
   Add a custom return-path or bounce subdomain if the provider offers one.
3. Point the relay's `RELAYHOST` and credentials at the provider. The API settings don't change.
4. Set `Email__FromAddress=no-reply@knightsandkings.net` and `Email__ReplyToAddress=support@knightsandkings.net`
   after the `support@` mailbox or forwarding exists.

## 5. The admin page: `/admin/email`

Staff with `knk.admin.config` see **Mail** in the navigation. The page shows:

- the transport in use (with a warning for Log) and the mails of the last 24 hours against the daily cap;
- the log, newest first: created, status, kind, masked recipient, attempts and last error; filters by status and kind;
- **Retry** on a Failed mail that kept its content (one with a link can't be retried; the player asks again);
- **Send test mail to me** — queues a test mail to your own account's address. It shows as Sent once the mail server
  accepted it.

The API behind it is `GET api/EmailOutbox`, `POST api/EmailOutbox/test` and `POST api/EmailOutbox/{id}/retry`.

## 6. Smoke steps

Run on dev (or the alpha after a deploy). Use a tester account whose mailbox you can read.

1. **Test mail.** `/admin/email` → *Send test mail to me*. Within a few seconds the row is **Sent** and the mail
   arrives (check spam). With `Transport=Log` the row is Sent and the API log has the line instead.
2. **Reset mail.** Log out → *Forgot password* for the tester → the mail arrives with a working link → reset → old
   sessions end. The row is a Sent `PasswordReset` with no content left.
3. **Email-change notice.** Change the tester's email on the account page → the **old** address gets "Your Knights &
   Kings email was changed". Then change it back from the staff user page (`update-email`) → the old address gets it
   again (new in KNG-206).
4. **Privacy confirm.** As the tester, request data deletion on the account page → the confirm mail arrives. Cancel
   the request afterwards.
5. **Relay down.** Stop the relay (`docker stop mailrelay`) → *Forgot password* still answers the usual message → the
   row stays **Pending** with attempts 1, 2 … and a last error → start the relay within the retry window → the row
   becomes **Sent**. (A reset mail older than 30 minutes becomes **Expired** instead — that is correct.)
6. **Throttle.** Ask four resets for the same address within an hour, waiting out the 60-second forgot-password
   cooldown between them → the fourth row is **Suppressed** ("3 password-reset mails to this address in the last hour")
   and no fourth mail arrives.

## 7. Troubleshooting

| Symptom | Cause and fix |
|---|---|
| API won't start: "the mail transport is Log … AllowLogTransport" | Production with `Provider`/`Transport=Log`. Configure SMTP, or set `Email__AllowLogTransport=true` on purpose. |
| Rows stay Pending, last error `SocketException` / connection refused | The SMTP host isn't reachable: relay stopped, wrong `SmtpHost`/port, or no network path. The dispatcher retries; fix and wait, or Retry once Failed. |
| Last error names `Email:SmtpPassword` | `SmtpUsername` is set without a password. For the relay, clear `Email__SmtpUsername`; for direct Gmail, set the app password. |
| Last error `AuthenticationException` | Wrong credentials, or the server wants TLS: check `UseStartTls` and the port. |
| Last error "Email:FromAddress is not set" | Set `Email__FromAddress`. |
| Rows are Sent but nothing arrives | The relay or provider accepted it: check spam, the relay's log (`docker logs mailrelay`) and the provider's activity page. With Gmail, check the sender account for blocks. |
| Rows are Suppressed | The throttle or the daily cap (see the last error). Expected for repeated requests; raise `Email__DailyCap` only for a real need. |
| Links in mails point to localhost | Set `App__PublicBaseUrl`. |
| Row Expired | It couldn't be sent before its link expired; the player asks again. Look at why sending was stuck. |
