# knk-alpha mail relay (Phase 9 E0, KNG-211)

The API sends its mail (invites, password resets, the `/admin/email` test mail) through the outbox to `mailrelay:587`
without login or TLS. `mailrelay` (Postfix, `boky/postfix:v5.1.0`) relays it to `smtp.gmail.com:587` with STARTTLS
required and the Gmail account `knightsandkingsmc@gmail.com`. Settings: [email guide](../../docs/guides/email.md),
[alpha go-live](../../docs/guides/alpha-go-live.md) § 4.

| File | Use |
|---|---|
| `compose.mailrelay-service.yaml` | The service `mailrelay`, inserted before `volumes:`. Image pinned by digest; `cap_drop: ALL` plus the seven capabilities Postfix needs to drop to its own users; no ports |
| `compose.mail-networks.yaml` | The networks `mail` (internal, `172.31.250.16/28`: api, mailrelay) and `mail-egress` (internet for mailrelay), appended at the end of `networks:` |

The `api` block (`scripts/alpha-api/compose.api-service.yaml`) joins `mail` and switches to `Email__Transport=Smtp`
(`Email__AllowLogTransport` removed).

Secret: `secrets/gmail_app_password`, `root:root 600`, a Gmail **app password** (Google account → Security →
2-Step Verification → App passwords), never the account password. The image reads it with `RELAYHOST_PASSWORD_FILE` at
start and writes it into `/etc/postfix/sasl_passwd` (root 600) inside the container.

Postfix accepts only:
- clients from `172.31.250.16/28` (`POSTFIX_mynetworks`);
- senders `@gmail.com` (`ALLOWED_SENDER_DOMAINS`); Gmail rewrites any other From anyway.

Rehearsed on 2026-10-24 in a scratch Docker host with the same block and API `a38c8ee9`:
- the relay is `healthy`; sender `@gmail.com` from the `mail` network → `250 Ok: queued`;
- another sender domain → `554 … Access denied`; a client outside `mynetworks` → `554 Client host rejected`;
- the API's forgot-password mail reached the relay over `mailrelay:587` (the scratch host has no route to Gmail, so
  delivery itself is tested on the NAS).

If the relay is down, the API keeps the mail in the outbox and retries; the forgot-password answer stays generic.
