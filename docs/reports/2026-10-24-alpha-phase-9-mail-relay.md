# Closed alpha Phase 9 E0: mail relay `mailrelay` (KNG-211) — 2026-10-24

**Status:** Live. The alpha API sends real mail through the stack's own Postfix relay to Gmail
**Last updated:** 2026-10-24
**Linear:** [KNG-211](https://linear.app/kngpandi/issue/KNG-211) (E0), part of [KNG-218](https://linear.app/kngpandi/issue/KNG-218) (Phase 9)
**Runbook:** [closed-alpha deployment runbook](../guides/closed-alpha-deployment-runbook.md) Phase 9 ·
[alpha go-live](../guides/alpha-go-live.md) § 4 · **Build files:** [`scripts/alpha-mail/`](../../scripts/alpha-mail/README.md)

The developer ran every NAS command in an SSH session. Claude Code (cloud session) wrote the blocks and rehearsed them in
a scratch Docker host first. The Gmail app password was typed at a hidden `read -rs` prompt on the NAS; it was never
printed, logged or recorded.

## 1. Design

| Item | Value |
|---|---|
| Image | `boky/postfix:v5.1.0@sha256:aafc772384232497bed875e1eb66b4d3e54ba1ebc86e2e185a6dc1dbc48182ef` (same digest on the NAS) |
| Relay | `[smtp.gmail.com]:587`, user `knightsandkingsmc@gmail.com`, password from `RELAYHOST_PASSWORD_FILE`; `smtp_tls_security_level=encrypt` |
| Accepts | clients from `172.31.250.16/28` only (`POSTFIX_mynetworks`), senders `@gmail.com` only; IPv4 only |
| Hardening | `cap_drop: ALL` + CHOWN, DAC_OVERRIDE, FOWNER, SETUID, SETGID, NET_BIND_SERVICE, KILL; `no-new-privileges`; no ports; json-file logs 3 × 10 MB. Postfix runs as root and drops to its own users, so no fixed UID |
| Networks | new `mail` (internal, `172.31.250.16/28`: api, mailrelay; later `cfproxy`) and `mail-egress` (internet: mailrelay). This replaces the earlier plan (`backend` + `mail-egress`): the relay can't reach MySQL |
| API | joins `mail`; `Email__Transport=Smtp`, `SmtpHost=mailrelay`, `SmtpPort=587`, `UseStartTls=false`, `SmtpUsername` empty, `FromAddress=knightsandkingsmc@gmail.com`; `Email__AllowLogTransport` removed. Same image `alpha-a38c8ee9`, no migration |
| Secret | `secrets/gmail_app_password`: a Gmail app password (16 letters), `root:root 600` |

Scratch rehearsal (same block, API `a38c8ee9`): relay healthy; `@gmail.com` sender from `mail` → `250 queued`; other sender
→ `554 Access denied`; client outside `mynetworks` → `554 Client host rejected`; the API's forgot-password mail reached
`mailrelay:587`.

## 2. What was changed on the NAS

| Item | Value |
|---|---|
| Snapshot | `knk-alpha-snapshot pre-mailrelay` (world 3.0 GB) before the switch |
| Compose | `32367622…` → **`00659fef998f83f4b01eb30b5594275615e90f5d94a26650e4cce5a4b65077d6`**, Portainer stack 42 identical; backup in `backups/<TS>/`. The diff removed only the three Log-transport lines; everything else was additions |
| Start | `up -d --no-deps mailrelay api`: networks `knk-alpha_mail` and `knk-alpha_mail-egress` created; both `healthy`. API on `backend`, `webapi`, `mail` (`172.31.250.18`); mailrelay on `mail` (`172.31.250.19`) and `mail-egress`. No ports |
| Logs | API: 0 refuse/key lines. Relay: the image's notice that it upgrades `hash:` maps to `lmdb:`, and two Postfix warnings that `postqueue`/`postdrop` aren't set-gid. Those two are only used for mail submitted inside the container (the `sendmail` command); the API uses SMTP, so they don't matter. Secret in logs: 0 |
| `knk-ops` | `secret-files` expects `gmail_app_password` (wrapper `8b41b0a2…`); `compose` records `00659fef…` (wrapper `2937b76b…`). Both match `scripts/nas-ops/stage-a/SHA256SUMS` |

## 3. Tests

| Test | Result |
|---|---|
| `/admin/email` → *Send test mail to me* | arrived |
| Forgot password | the mail arrived; the link starts with `https://app.knightsandkings.net` |
| Relay log | `TLS connection established to smtp.gmail.com`, `status=sent (250 2.0.0 OK …)` |
| Relay stopped, forgot password | the page gave the generic answer; the API logged a failed attempt with a next try (outbox retry) |
| Relay started again | the queued mail is retried by the outbox backoff; delivery was still pending when this report was written |
| `ssh knk-nas-ops compose` / `secret-files` | `matches_recorded: true`; 8 files incl. `gmail_app_password` `root:root 600`, `missing: []` |

## 4. Notes

- Gmail sends as `knightsandkingsmc@gmail.com` whatever the From. Free Gmail allows about 500 recipients a day, far
  above the alpha's needs (the API's hourly throttle stays below it).
- The app password stops working if the Google account password changes or 2-Step Verification is turned off.
  Then mail stays in the outbox (`/admin/email` shows the failures) until a new app password is in the secret file and
  the relay is restarted (`up -d --no-deps --force-recreate mailrelay`).
- Emergency fallback: `Email__Transport=Log` with `Email__AllowLogTransport=true` (links go to the API log).

## 5. Next

Phase 9 step 2, KNG-216: `cfproxy` on `mail` + `mail-egress`, the Cloudflare list `knk-api-testers`, the policy, the API
token, the bypass application and the `CloudflareAccess__*` settings (go-live § 6.1).
