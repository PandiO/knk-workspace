# NAS operations access for agents (`knk-ops`)

**Status:** Stage A (read-only checks) installed on the NAS and verified 2026-10-18 · Stage B (deploy) designed, **not installed**
**Last updated:** 2026-10-22
**Sources:** wrapper sources and checksums in [`scripts/nas-ops/stage-a/`](../../scripts/nas-ops/stage-a/) ·
session report [2026-10-18 NAS ops access and alpha check](../reports/2026-10-18-nas-ops-access-and-alpha-check.md) ·
[closed-alpha deployment runbook](closed-alpha-deployment-runbook.md)

## 1. What this is

A Claude Code session running on the **developer's PC on the home LAN** can
run nine fixed, read-only checks of the `knk-alpha` stack on the NAS:

```text
ssh knk-nas-ops <operation>
```

Each call returns one JSON object. Nothing else is possible through this
access: no shell, no Docker commands, no file access, no arguments, no
secret values. Cloud sessions (Codex or Claude Code on the web) have **no**
access to the NAS through this route. The earlier plan to give Codex cloud
environments access (Tailscale, then a Cloudflare Access gateway) was dropped
on 2026-10-18, and Tailscale was removed from the NAS.

The design is deliberately boring: an SSH forced command, one root-owned
dispatcher with an exact allowlist, and root-owned wrappers that sudo allows
only by exact path with no arguments.

```text
Claude Code on the developer PC (LAN)
  -> ssh knk-nas-ops <op>                 dedicated ed25519 key, IdentitiesOnly, BatchMode
  -> sshd, account knk-ops                key only, from the PC's reserved LAN address only,
                                          ForceCommand, no TTY/forwarding/sftp, MaxSessions 1
  -> /usr/local/libexec/knk-ops/dispatch  exact allowlist; anything else:
                                          {"ok":false,"error":"denied"}, exit 64, logged (length + hash only)
  -> sudo -n /usr/local/libexec/knk-ops/ops/<op>   sudo rule with "" (no arguments), env_reset, fixed PATH
  -> JSON on stdout
```

## 2. Operations

| Operation | Returns | Healthy alpha (2026-10-18; 2026-10-22 changes in **bold**) |
|---|---|---|
| `ping` | host name, time (runs without sudo) | `ok: true` |
| `containers` | for `knk-alpha-api` and `knk-alpha-mysql`: present, status, health, start time, restart count, image and ID, runtime user, restart policy, port bindings, networks, privileged, read-only root fs, dropped/added capabilities, security options, log driver | both running + healthy, `port_bindings: {}`, network `knk-alpha_backend` only, API user **`2002:2002`** (image **`alpha-be9f4e1a`**) |
| `network` | `knk-alpha_backend`: driver, scope, internal, attachable, IPv6, IPAM, attached container names | internal, two containers |
| `secret-files` | the stack's `secrets/` directory and files: name, type, owner, uid/gid, mode, non-empty; `missing`, `unexpected`, `all_private` | dir **`root:root 700`**; **five** files (incl. `rcon_password`, KNG-225), mode 600; API secrets **2002**, `mysql_root_password` **root**, `rcon_password` **2001**; `all_private: true` |
| `api-health` | HTTP codes of `/health/live` and `/health/ready` (requested inside the API container), container health, `healthy` | `200` / `200`, `healthy: true` |
| `compose` | sha256 of the host `compose.yaml` and of Portainer stack 42's copy, hashes of their normalised form (`docker compose config --no-interpolate`), `matches_recorded`, `files_identical`, `canonical_equal` | `matches_recorded: true` (recorded **`2af121b6…`**, update `RECORDED_SHA` after every Compose change), **`files_identical: true`** |
| `db-summary` | schema object counts, EF migration count and latest migration, users total/active, holder-ID clash count, MySQL account names, row count per table (fixed, read-only SQL) | **137** tables, 4 triggers, **82** migrations, 9 users / 2 active, 0 clashes |
| `secret-scan` | for each secret **name** `clean`/`HIT` over the last 200,000 log lines of both containers, plus password-style and JWT-style text indicators, and `verdict` | `verdict: clean` |
| `log-errors` | per container: lines scanned and counts of error/critical/exception/warning lines in the last 24 h (at most 200,000 lines) | all zero |

The "healthy" column describes the **placeholder** alpha database (copied
from dev; see the [handoff](../ai-agents/handoffs/2026-10-11-closed-alpha-infrastructure.md)).
Expect different counts once the real alpha database is created from the
approved seed set.

### For agents using it

- Run only `ssh knk-nas-ops <operation>` with an operation from the table.
  Never try other commands, other SSH accounts, port forwarding or file
  copies, and never ask the developer to paste secret values.
- A `denied` answer is final. If a check is missing, describe the new
  read-only operation you need and let the developer decide (§ 5).
- `secret-scan` `HIT` means a secret value appeared in a log: stop, report
  the secret **name** only, and recommend rotating it.
- Counts from `log-errors` are text matches, not a diagnosis.

## 3. Security model

| Concern | Control |
|---|---|
| An agent mistake or prompt injection | Only nine named read-only operations exist. Every other request is refused by the NAS and logged without its text. |
| The PC key is copied | It works only from the PC's LAN address and only for these operations. Revocation is one command (§ 6). |
| Shell, tunnels, file transfer | `ForceCommand`, key option `restrict`, `PermitTTY no`, `DisableForwarding yes`, `PermitOpen/PermitListen none`; sftp/scp reach the dispatcher and are refused. |
| Privilege escalation via sudo | Exact paths with `""`; `env_reset`, `!setenv`, fixed `secure_path`. The account owns nothing it executes; dispatcher, wrappers, key file, sshd drop-in and sudo rule are root-owned. |
| Secrets leaking in output | Fixed `docker inspect --format` templates (no environment, no command lines, no mounts); counts, hashes and verdicts only; the MySQL password is read **inside** the container; secret values reach `grep` through a file descriptor, never as an argument; log copies live in a root-only tmpfs directory removed on exit. |
| Load on the live stack | One operation at a time (`flock`), `timeout` on every Docker call, MySQL `max_execution_time` and a read-only session for `db-summary`. |
| The developer's own accounts | The PC holds no key for the admin account, `ssh-agent` is disabled, sudo requires a password, and admin accounts are no longer in the `docker` group. |

Claude Code's own permission rules on the PC (allow the nine commands; deny
reading `~/.ssh`, other SSH targets and file copies; use **Manual** mode for
NAS work) are a second, weaker layer. Native Windows has no command sandbox,
so the NAS-side controls are what holds.

## 4. Files on the NAS

All `root:root`. The sources and `SHA256SUMS` are in
[`scripts/nas-ops/stage-a/`](../../scripts/nas-ops/stage-a/); the NAS copies
must match them byte for byte.

| NAS path | Mode | Source in this repo |
|---|---|---|
| `/usr/local/libexec/knk-ops/dispatch` | 0755 | `stage-a/dispatch` |
| `/usr/local/libexec/knk-ops/ops/<op>` (9 files) | 0755 | `stage-a/ops/` |
| `/etc/ssh/sshd_config.d/60-knk-ops.conf` | 0644 | `stage-a/60-knk-ops.conf` |
| `/etc/sudoers.d/knk-ops` | 0440 | `stage-a/knk-ops.sudoers` |
| `/etc/ssh/knk-ops/authorized_keys` | 0644 | one line: `restrict,from="<PC LAN address>",command="/usr/local/libexec/knk-ops/dispatch" ssh-ed25519 … knk-ops@<pc>` |
| `/var/lib/knk-ops/` (home, empty) | 0755 | — |

Account `knk-ops`: system account, password locked, shell `/bin/sh` (needed by
`ForceCommand`), member of its own group only.

Verify (NAS, read-only):

```bash
sha256sum /usr/local/libexec/knk-ops/dispatch /usr/local/libexec/knk-ops/ops/* /etc/ssh/sshd_config.d/60-knk-ops.conf
sudo sha256sum /etc/sudoers.d/knk-ops
id knk-ops; sudo -l -U knk-ops | tail -9
sudo journalctl -t knk-ops --since today --no-pager -o short-iso
```

## 5. Adding or changing an operation

1. Write the wrapper in `scripts/nas-ops/stage-a/ops/` following the existing
   ones: no input, fixed `PATH`, `set -u -o pipefail`, `umask 077`, JSON via
   `jq`, `timeout` on external calls, no secret values, no free-form log or
   inspect output. It must pass `shellcheck` and contain no tab characters
   (they break pasting into an SSH session).
2. Test it with a stubbed `docker` (including failure cases), then on the NAS
   as root **before** exposing it, and review the real output for anything
   sensitive.
3. Add it to the dispatcher allowlist and to the sudoers alias (check with
   `visudo -cf` before installing), update `SHA256SUMS` and § 2, and add the
   exact `Bash(ssh knk-nas-ops <op>)` allow rule on the PC.
4. Run the denial tests again (extra argument, chained command, shell,
   `docker`, reading a secret) and record the result in a dated report.

## 6. Revocation, rotation and removal

- **Revoke now:** `sudo truncate -s 0 /etc/ssh/knk-ops/authorized_keys`
  (new logins stop immediately). Removing `/etc/sudoers.d/knk-ops` stops all
  privileged operations (`ping` keeps working).
- **Rotate:** generate a new ed25519 key on the PC, copy only its `.pub`,
  check the fingerprint on the NAS, rewrite the single `authorized_keys` line
  with the same `restrict,from=…,command=…` options, then replace the PC key
  files and test `ping`. Rotate on any suspicion, when the PC changes, and
  yearly.
- **Remove completely:**

  ```bash
  sudo rm -f /etc/sudoers.d/knk-ops && sudo visudo -c
  sudo rm -f /etc/ssh/sshd_config.d/60-knk-ops.conf && sudo sshd -t && sudo systemctl reload ssh
  sudo userdel knk-ops
  sudo rm -r /usr/local/libexec/knk-ops /etc/ssh/knk-ops /var/lib/knk-ops
  ```

## 7. Stage B (deploy): design, not installed

Goal: let an agent help run an alpha upgrade with the developer approving each
step, still without a shell or any caller-chosen input.

- **Separate account `knk-deploy`** with its own passphrase-protected (or
  hardware) key, its own `Match` block, dispatcher and sudoers file. The
  Stage A key can never reach it.
- **No arguments.** What may be deployed comes from a root-owned approval file
  that only the developer writes with `sudo` (image tag + image ID, migrator
  image ID, source commit and source-archive hash, hash of the Compose file to
  switch to). Operations read it; they take nothing from SSH.
- **Operations:**

  | Operation | Does |
  |---|---|
  | `backup-db` | dump `knightsandkings_alpha` + sha256 into a new timestamped, root-only folder; never deletes |
  | `verify-release` | check the approved image IDs exist and match; check source and Compose hashes |
  | `migrate` | run the approved migrator image once on `knk-alpha_backend` with a schema-rights account; refuses without a `backup-db` from the last hour |
  | `switch` | install the approved Compose file and recreate only the `api` service |
  | `health` | `api-health` + `log-errors` + `secret-scan` in one report |
  | `restart-api` | restart only `knk-alpha-api` |
  | `rollback` | switch back to the previous approved Compose/image (database restore stays a manual, human step) |
  | `mc-stage-plugin` | copy the approved plugin jar (path + SHA-256 in the approval file) to `plugins/update/KnightsAndKings.jar` after checking its hash ([KNG-225](https://linear.app/kngpandi/issue/KNG-225), runbook § 4.3) |
  | `mc-restart` | `rcon-cli save-all flush`, then restart only `knk-alpha-minecraft` |
  | `mc-health` | container state and health, restart count, the KnK plugin version line and `/knk health` result from the startup log |

  The Minecraft operations were added to the design on 2026-10-21. Until Stage B exists, the developer does the
  same steps by hand (runbook § 4.3). A read-only `mc-health` could also join Stage A first.

- Every run is logged like Stage A plus an append-only deployment log. On the
  PC these operations go in Claude Code's **ask** list, never allow.

**Prerequisites before Stage B is enabled** (details in the
[2026-10-18 report](../reports/2026-10-18-nas-ops-access-and-alpha-check.md) § 4):

1. ~~A dedicated runtime UID for the API, with the secret files owned by it.~~ Done 2026-10-22 (UID 2002, KNG-227).
2. ~~A root-owned `knk-alpha` stack directory.~~ Done 2026-10-22.
3. A read-only MySQL account for checks; limit `root@%`. Open: [KNG-242](https://linear.app/kngpandi/issue/KNG-242).
4. ~~Decide whether Portainer stack 42 or the host Compose file is authoritative.~~ Decided 2026-10-21: the host file; stack 42 is a copy.
5. ~~Archive the leftover `compose.api.pending.yaml`.~~ Done 2026-10-22 (`backups/20261011-archive/`).
6. ~~Lower the API's log volume (~186,000 lines/day).~~ Done 2026-10-22 (mounted `appsettings.Production.json`).
7. The real alpha database created from the approved seed set, and a passed restore rehearsal.

## 8. Limitations

- Only the `knk-alpha` stack is covered. The dev database and the future
  Minecraft service have no operations yet.
- `db-summary` currently connects as MySQL `root` (over `127.0.0.1` inside the
  container) until a read-only account exists.
- Docker's log size limit may keep less than 24 hours of API logs, which
  limits `secret-scan` and `log-errors`.
- Works only from the developer PC on the LAN.
