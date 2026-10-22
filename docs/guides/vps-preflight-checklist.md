# VPS pre-flight checklist — what you provide before the agent starts

**Status:** Draft v1 (2026-10-22) — written for review, not yet used
**Last updated:** 2026-10-22
**Linear:** [KNG-241](https://linear.app/kngpandi/issue/KNG-241)
**Plan:** [VPS bootstrap runbook](vps-bootstrap-runbook.md) · **Prompt:** [kickoff prompt](../ai-agents/handoffs/2026-10-22-vps-bootstrap-kickoff-prompt.md)

Everything here is something only you can do or decide. Tick the boxes and write the answers in the "Record" blocks
(or copy this file to your notes); the agent reads your answers from the kickoff prompt. **Never write a secret value in
this file or in a chat message.** Items marked ⛔ block the agent; items marked ⏳ can arrive later (the agent stops at a
hold point and waits).

## A. Decisions to record

- [ ] ⛔ **A1. Build refs.** Which commits does the VPS run? Pick one:
  - **Trunk heads** (`knk-web-api` `master`, `knk-web-app` `main`, `knk-plugin` `main` ≥ `857d4b1e`) — the invitations
    feature is not on the alpha; the gate stays the whitelist until it is merged and deployed (a later upgrade, runbook § 16).
  - **The invitations branch** `claude/player-signup-invitation-flow-f4v7ul` (as of 2026-10-21: web-api `8f489b9`, web-app
    `eeea86f`, plugin `90b01850`, which sits on KNG-182). Choose this only after your dev smoke test
    ([invitations-smoke-test](https://github.com/PandiO/knk-workspace/blob/claude/player-signup-invitation-flow-f4v7ul/docs/guides/invitations-smoke-test.md)
    § 0–8) has passed. The merge order in the chain's final summary applies.

  Record: `api = ______  app = ______  plugin = ______` (full SHAs; the agent refuses a ref that moved).
- [ ] ⛔ **A2. Host names.** Web app + API: `app.knightsandkings.net`? Minecraft: `play.knightsandkings.net`? Record: ______ / ______
- [ ] ⛔ **A3. ACME contact address** for Let's Encrypt (expiry notices): ______
- [ ] **A4. Minecraft starting values:** view distance 10, simulation distance 6, `MEMORY=6G` (runbook § 3). Change? ______
- [ ] **A5. Whitelisted testers** until the invite switch-over (Minecraft names): ______
- [ ] **A6. First admin:** the Minecraft account you will register as at go-live: ______
- [ ] **A7. Off-site backups:** NAS pull (default) or object storage? ______
- [ ] **A8. Reboot policy:** automatic security updates only, **no automatic reboots** (default). OK? ______

## B. Order the server (⛔)

- [ ] OVH account has 2FA enabled.
- [ ] Order **VPS-4**, **Ubuntu 24.04 LTS**, **Western-EU datacenter** (Gravelines or Frankfurt for NL testers; take what the
  order page offers), your SSH **public key** attached at order time, **monthly billing** if offered.
  At checkout confirm: price incl. VAT, region, vCPU/RAM/disk, anti-DDoS, and which CPU generation OVH states (record it).
  Record: `IP = ______  region = ______  vCPU/RAM = ______  CPU = ______`
- [ ] You can `ssh` to the server with your key as the OS user OVH created.
- [ ] **Cancel-if-slow note:** monthly billing keeps the exit cheap if the V9 tick baseline is worse than the NAS.

## C. DNS (⛔ for HTTPS, ⏳ for Minecraft)

Where is the `knightsandkings.net` zone hosted (GoDaddy or Cloudflare)? ______. Records to create, TTL 300, **IPv4 only
(no AAAA)**:

- [ ] ⛔ `app.knightsandkings.net` **A** → the VPS IP (Caddy cannot get a certificate before this resolves). If
  `app.…` currently points at the Cloudflare Tunnel, replace that record; the NAS web path goes offline at that moment,
  which is intended.
- [ ] ⏳ `play.knightsandkings.net` **A** → the VPS IP — only at go-live (runbook V10), not earlier.
- [ ] `dig +short app.knightsandkings.net` from your PC returns the VPS IP.

## D. Access for the agent (⛔)

- [ ] **Agent SSH key:** on your PC, `ssh-keygen -t ed25519 -C knk-agent-setup -f ~/.ssh/knk-agent-setup`. The public half goes into
  `knk-agent`'s `authorized_keys` (runbook V0). Use this key only for this job; delete it at teardown. **No agent forwarding.**
- [ ] **Your admin key:** the public key for the permanent `knk-admin` account (runbook V1): ______
- [ ] **GitHub token for the clones:** a *fine-grained personal access token*, **Contents: read-only**, restricted to
  `PandiO/knk-workspace`, `knk-web-api`, `knk-web-app`, `knk-plugin`, **expiry 7 days**. Place it on the VPS yourself
  (`/home/knk-agent/.config/knk/github_token`, mode 600). Never paste it into the chat.
- [ ] **Claude Code on the VPS:** installed for `knk-agent` and logged in (runbook V0). You know how to revoke that session
  in your Claude account settings.
- [ ] **Permission mode:** you will start Claude Code in a mode that does not prompt for every command. The "stop and
  ask" list in the runbook is then enforced by the prompt, not by the tool; the box holds no personal data, and it
  has no GitHub write access, DNS access or Cloudflare token. Accepted? ______

## E. Files only you can produce

- [ ] ⏳ **The DB seed** (`seed.sql` + `manifest.txt`) from the dev DB with `scripts/seed/export-seed.sh`
  ([production guide § 7.5](production-installation.md#75-export-on-your-pc-against-the-dev-db)). **Its
  `schema_version` must be known:** the importer refuses a database whose latest migration differs, and the agent
  migrates to exactly that version first (runbook V8). Record `schema_version = ______`
  (it must be **at or below** the latest migration of the build in A1; if the seed is newer than the build, the build
  must be updated first).
- [ ] ⛔ **World packages:** the main gameplay world and the converted hub as `.tar.gz` with a `.sha256` each (the Phase 1
  archives on the NAS). Copy them to the VPS under `/srv/knk/minecraft/staging/incoming/` from your PC or the NAS
  (`scp`/`rsync` from the NAS works because it connects outward). Record sizes: ______
- [ ] ⛔ **Plugin manifest:** the third-party jars the 26.3 server needs, as a list of `name, version, download URL,
  SHA-256` (from `DEV_SERVER_26.3/plugins/`, e.g. FastAsyncWorldEdit 2.16.1 and WorldGuard 7.0.20). The agent downloads
  and verifies them; it does not guess.
- [ ] ⛔ **Plugin `config.yml` decisions:** the KNG-64 settings in [alpha go-live § 5](alpha-go-live.md#5-minecraft-and-plugin-runbook-phases-45)
  apply as written, with `api.base-url: http://api:5000/api`, `web.public-url: https://app.knightsandkings.net`. Anything
  that differs from the dev server's file? ______
- [ ] ⛔ **Minecraft EULA:** you read <https://aka.ms/MinecraftEULA> and will set `EULA=TRUE` yourself when the agent asks
  (V6). The agent never accepts it for you.
- [ ] ⛔ **Gmail app password** for the mail relay (Google Account → Security → 2-Step Verification → App passwords,
  sender `knightsandkingsmc@gmail.com`): you create it and write it into `/etc/knk/mailrelay.env` (the agent tells
  you the exact variable names, taken from the relay image's docs). The agent only checks the file exists with mode 600.

## F. Timeline suggestion (the weekend of 2026-10-24/25)

| When | Who | What |
|---|---|---|
| Thursday/Friday | you | Sections A–D done; server ordered; DNS for `app.` live; world/plugin files copied |
| Friday evening | you → agent | Runbook V0, paste the kickoff prompt; check in for decisions |
| Overnight | agent | V1–V7: hardened host, builds, stack up, scratch rehearsal, backups restored once |
| Saturday | you | Read `PROGRESS.md`; deliver the seed → **H1** |
| Saturday | agent | V8–V9 |
| Saturday/Sunday | you | **H2** go-live; add `play.` A record; admin bootstrap; invite switch-over; **H3** teardown; then the first invites |

The one hard blocker is the seed (section E). Everything before H1 needs only the world files and plugin manifest.

## G. Before you send any tester invite

- [ ] `nmap -p 22,80,443,3306,5000,8081,25565,25575 <vps-ip>` from your PC: only 22, 80, 443, 25565 open.
- [ ] `scripts/security/alpha-probe.sh` against `https://app.knightsandkings.net`: `ALL CHECKS PASSED`.
- [ ] A restore rehearsal was recorded in `PROGRESS.md` (DB and worlds).
- [ ] The NAS `knk-alpha` stack is stopped (not deleted).
- [ ] Teardown (runbook V11) done, including revoking the GitHub token and re-creating the Gmail app password.
