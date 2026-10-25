# NAS operations access for agents (`knk-ops`)

**Status:** Stage A (read-only checks) installed on the NAS and verified 2026-10-18 · Stage B (`knk-deploy`, delegated changes) built, tested and **installed 2026-10-25**
**Last updated:** 2026-10-25 (§ 7 Stage B rebuilt for delegated changes)
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
| `containers` | for `knk-alpha-api` and `knk-alpha-mysql`: present, status, health, start time, restart count, image and ID, runtime user, restart policy, port bindings, networks, privileged, read-only root fs, dropped/added capabilities, security options, log driver | both running + healthy, `port_bindings: {}`, network `knk-alpha_backend` only, API user **`2002:2002`** (image **`alpha-4aeb7947`**) |
| `network` | `knk-alpha_backend`: driver, scope, internal, attachable, IPv6, IPAM, attached container names | internal, two containers |
| `secret-files` | the stack's `secrets/` directory and files: name, type, owner, uid/gid, mode, non-empty; `missing`, `unexpected`, `all_private` | dir **`root:root 700`**; **five** files (incl. `rcon_password`, KNG-225), mode 600; API secrets **2002**, `mysql_root_password` **root**, `rcon_password` **2001**; `all_private: true` |
| `api-health` | HTTP codes of `/health/live` and `/health/ready` (requested inside the API container), container health, `healthy` | `200` / `200`, `healthy: true` |
| `compose` | sha256 of the host `compose.yaml` and of Portainer stack 42's copy, hashes of their normalised form (`docker compose config --no-interpolate`), `matches_recorded`, `files_identical`, `canonical_equal` | `matches_recorded: true` (recorded **`e11281e8…`** since 2026-10-24, update `RECORDED_SHA` after every Compose change), **`files_identical: true`** |
| `db-summary` | schema object counts, EF migration count and latest migration, users total/active, holder-ID clash count, MySQL account names, row count per table (fixed, read-only SQL) | **143** tables, 4 triggers, **93** migrations (2026-10-24), 9 users / 2 active, 0 clashes |
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

## 7. Stage B: delegated changes (`knk-deploy`)

**Status:** built and tested 2026-10-25 (72 end-to-end checks after the hardening of the same evening on a mock stack:
[`scripts/nas-ops/stage-b/tests/`](../../scripts/nas-ops/stage-b/tests/test_knk_deploy.py)); **installed on the NAS
2026-10-25** (files match `SHA256SUMS` of `1f23251`; key `SHA256:P6YDRiBC9wxhevkpJnd2aDjcKKUaox4De2Cw0rC732E`
`knk-deploy@pc`, `from="192.168.50.208"`; `_files` copied from the `6f08383d`/`0d612702` build folders). PC test:
`status` ok, `status; id` denied, `restart mysql` refused, `config-get knk` shows the plugin key as a token.
Archive the files with `git -c core.autocrlf=false archive` on Windows, or the line endings change. Hardening update `a6d59a6` (`knk-deploy` `1f1aad31…`, dispatcher unchanged `e6f9c1e9…`) installed the same evening; the previous program is kept as `/var/lib/knk-deploy/knk-deploy.before-a6d59a6`.
Developer decisions 2026-10-25: Claude Code sessions on the PC may update the alpha to **trunk** builds and change its
Compose and plugin configs, **asking the developer before every change** (Claude Code `ask` rules); the NAS gets
**no GitHub access** — the PC builds and uploads. This replaces the 2026-10-18 design (no arguments, approval files).

```text
Claude Code on the developer PC (LAN)
  -> scripts/nas-ops/stage-b/pc/knk-release.sh api|web|plugin [commit]   checks the commit is on trunk, archives or
                                                                          builds it, uploads it (stdin)
  -> ssh knk-deploy <command> ...         own ed25519 key, from the PC's LAN address only, Claude asks first
  -> sshd, account knk-deploy             ForceCommand, no TTY/forwarding/sftp, MaxSessions 1
  -> /usr/local/libexec/knk-deploy/dispatch     ≤ 4 words of [a-z0-9.-], known verbs only, timeout per verb
  -> sudo -n /usr/local/libexec/knk-deploy/knk-deploy <words>   root, validates the grammar again, one at a time
```

### 7.1 Commands

| Command | Does |
|---|---|
| `status` | containers (state, health, image), Compose hash, live plugin jar hash, migrations in the DB, last 5 snapshots, the inbox, the last change |
| `compose-get` · `config-get NAME` · `logs SERVICE [MINUTES]` | read the Compose file, a plugin config, or a container log (≤ 400 lines); secret values appear as `<<secret:NAME>>` |
| `upload api-src\|web-src\|plugin-jar COMMIT < file` | store a `git archive --prefix=source/` (`.tar.gz`, only `source/` paths) or the KnK jar (must contain `plugin.yml` `name: KnightsAndKings`) |
| `upload compose\|config-NAME SHA256 < file` | store a new Compose file or config; the content must hash to the named SHA-256 |
| `deploy-api COMMIT` | build `knk-web-api:alpha-<c8>` + migrator from NAS-owned build files (`/srv/docker/build/knk-web-api/_files`) and the upload; refuse a build with fewer migrations than the DB; snapshot; with new migrations stop `api` and run the migrator; switch the `image` line; health; roll back the Compose file if unhealthy (the DB keeps applied migrations — the message names the restore command) |
| `deploy-web COMMIT` | the same for `knk-web-app:alpha-<c8>` (`_files`: Dockerfile, nginx.conf, .dockerignore) |
| `deploy-plugin COMMIT` | `releases/plugin/<c8>/`, snapshot, back up the live jar, `plugins/update/` swap, `save-all flush`, restart; checks the live jar hash and `Enabling KnightsAndKings`; rolls back the jar otherwise |
| `compose-apply SHA256` | policy check (§ 7.2), install with backup + Portainer copy + `knk-ops` hash, `up -d --no-deps` of the changed services (`save-all flush` first for Minecraft), health, automatic rollback |
| `config-apply NAME SHA256` | NAME ∈ `knk`, `geyser`, `floodgate`, `mcxboxbroadcast`, `paper-global`; tokens back to secret values, owner/mode kept, backup, Minecraft restart, plugin check, automatic rollback |
| `snapshot LABEL` · `restart SERVICE` · `rollback` | `knk-alpha-snapshot LABEL`; restart one service (not MySQL); undo the last change (Compose, jar or config — never the database) |

Every change lands in `/var/lib/knk-deploy/deploy.log` (JSON lines, no secret values) and syslog (`journalctl -t
knk-deploy`); backups in `/var/lib/knk-deploy/backups/<time>-<what>/`.

### 7.2 What can't be done through it

- No shell, no free command, no path, no Docker flag from the caller; no access to `secrets/`; MySQL only through the
  migrator of a built trunk image. Database restores stay manual (`knk-alpha-restore`).
- **Compose policy** (against the running file, on `docker compose config` output): no removed services; no
  `privileged`, host network/PID/IPC/userns, devices, sysctls, `build`, extra hosts; no `include:`/`extends:` (they
  read other files); no new capabilities, ports or `external` networks; `cap_drop: ALL`, `no-new-privileges` and
  `read_only` can't be dropped; a new service needs a non-root user, `cap_drop: ALL` and `no-new-privileges`; no
  switch to root; `command`/`entrypoint`/`working_dir` of an existing service may change only for `api` and `web`; a
  changed or new image must be a local `knk-*` build or pinned `@sha256:` (no tag-only third-party images), and every
  image change is listed in the result (`image_changes`); bind mounts only from paths the file already uses or under `config/`, `minecraft-data`, `releases/` —
  never `docker.sock`, `/etc`, `/root`, `/home`, `/var/lib/docker`, `/`; a service may not gain a secret file it
  didn't mount before; an internal network can't become external and a service without internet can't gain it.
- Secret values never leave the NAS: reads replace them with `<<secret:NAME>>`, applies put them back; an unknown
  token is refused. New or rotated secrets stay a developer step (`read -rs`).
- Trunk-only is enforced on the PC (`knk-release.sh` checks `merge-base --is-ancestor` against `origin/master|main`),
  not on the NAS, which has no GitHub access. The Claude Code `ask` rules make the developer confirm each change.

### 7.3 For agents using it

- Read first (`status`, `compose-get`, `config-get`, `logs` — allowed without asking). Build and upload only through
  `knk-release.sh`; never upload a non-trunk commit, and say which commit and what it changes before each change.
- One change at a time; after each, `status` plus Stage A `api-health`/`log-errors`. A `refused` is final: explain it,
  don't try variations. On `failed` the tool has rolled back; report, don't retry blindly.
- Record each change in a dated report and the tracker, as before (the NAS log is not the record).

### 7.4 Install (developer)

Sources: [`scripts/nas-ops/stage-b/`](../../scripts/nas-ops/stage-b/) (`SHA256SUMS`). NAS files, all `root:root`:

| NAS path | Mode | Source |
|---|---|---|
| `/usr/local/libexec/knk-deploy/dispatch` | 0755 | `stage-b/dispatch` |
| `/usr/local/libexec/knk-deploy/knk-deploy` | 0755 | `stage-b/knk-deploy` |
| `/etc/ssh/sshd_config.d/61-knk-deploy.conf` | 0644 | `stage-b/61-knk-deploy.conf` |
| `/etc/sudoers.d/knk-deploy` | 0440 | `stage-b/knk-deploy.sudoers` |
| `/etc/ssh/knk-deploy/authorized_keys` | 0644 | `restrict,from="192.168.50.208",command="/usr/local/libexec/knk-deploy/dispatch" ssh-ed25519 … knk-deploy@pc` |
| `/var/lib/knk-deploy/` | 0700 | state, inbox, backups, log |
| `/srv/docker/build/knk-web-api/_files/`, `/srv/docker/build/knk-web-app/_files/` | 0700 | the current build files (copied from the last build folders) |

Account `knk-deploy`: system account, password locked, shell `/bin/sh`, home `/var/lib/knk-deploy-home` (empty,
root-owned), not in `docker` or `sudo`. PC: key `~/.ssh/knk-deploy_ed25519`, `~/.ssh/config` host `knk-deploy`
(`HostName 192.168.50.119`, `User knk-deploy`, `IdentitiesOnly yes`, `BatchMode yes`), Claude Code `ask` rules for
`upload`, `deploy-*`, `compose-apply`, `config-apply`, `snapshot`, `restart`, `rollback` and `knk-release.sh`; `allow`
for `status`, `compose-get`, `config-get`, `logs`.

**Revoke:** `sudo truncate -s 0 /etc/ssh/knk-deploy/authorized_keys` (logins stop), or remove
`/etc/sudoers.d/knk-deploy` (nothing runs). **Remove:** as § 6 with `knk-deploy` paths. Stage A is independent of it.

## 8. Limitations

- Only the `knk-alpha` stack is covered. The dev database and the future
  Minecraft service have no operations yet.
- `db-summary` currently connects as MySQL `root` (over `127.0.0.1` inside the
  container) until a read-only account exists.
- Docker's log size limit may keep less than 24 hours of API logs, which
  limits `secret-scan` and `log-errors`.
- Works only from the developer PC on the LAN.
