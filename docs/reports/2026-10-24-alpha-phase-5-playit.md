# Closed alpha Phase 5: playit.gg agent and `play.knightsandkings.net` — 2026-10-24

**Status:** Complete. Players join through `play.knightsandkings.net` (playit.gg Premium, regional tunnel Germany, ~27 ms from NL) with no router port-forward
**Last updated:** 2026-10-24
**Linear:** none yet. **To file:** creating an issue was refused on 2026-10-24 because the workspace has reached the free plan's issue limit (§ 7)
**Runbook:** [closed-alpha deployment runbook](../guides/closed-alpha-deployment-runbook.md) Phase 5 ·
[alpha go-live](../guides/alpha-go-live.md) § 5
**Build files:** [`scripts/alpha-playit/`](../../scripts/alpha-playit/)

The developer ran every NAS command in an SSH session and used the playit.gg and Cloudflare dashboards. Claude Code
(cloud session) wrote and checked each block and tested the agent image in a scratch Docker host first. The playit secret
key was typed at a hidden `read -rs` prompt on the NAS; it was never printed, logged or recorded.

## 1. Agent image and choices

Checked against the agent source (`playit-cloud/playit-agent` `v1.0.12`) and tested on 2026-10-24.

| Item | Result |
|---|---|
| Image | `ghcr.io/playit-cloud/playit-agent:1.0.12@sha256:5b7748d3e8564f1cac3d3a295a23640136fbf774c76a9509bd262d16b324b06b` (same digest on the NAS), 22 MB, Alpine |
| Secret handling | The image's `entrypoint.sh` runs `playitd --secret "$SECRET_KEY"`. That puts the key in the process list, which every host user can read with `ps`. Instead `playitd --secret-path /run/secrets/playit_secret` reads the raw hex key from a file (`daemon.rs` `parse_secret_file`) |
| Non-root | Under UID 2003 the default IPC socket `/run/playit/playitd.sock` can't be created (`Failed to bind to socket`). So: `--socket-path /tmp/playitd.sock`, `HOME=/tmp`, `tmpfs /tmp` (8 MB, 0700, owner 2003), `read_only: true` |
| Tunnel target by name | Agent 1.0.12 resolves a hostname as the tunnel's local address (`origin_lookup.rs` `OriginIp::Hostname`). So the tunnel points at `minecraft:25565` by Compose DNS |
| Network | `egress` only. That gives internet and `minecraft` (which is on `backend` and `egress`). The agent has no route to `api` or `mysql` |

## 2. What was changed on the NAS

| Item | Value |
|---|---|
| Secret | `secrets/playit_secret`: 64 hex characters, `2003:2003 600` |
| Service | `playit` / `knk-alpha-playit`: user `2003:2003`, `cap_drop: ALL`, `no-new-privileges`, read-only root, no ports, `restart: unless-stopped`, json-file logs 3 × 10 MB. Block [`compose.playit-service.yaml`](../../scripts/alpha-playit/compose.playit-service.yaml) `44905eb5…`, inserted at the end of `services:` |
| Compose | `e11281e8…` → **`90c1853b2141ccef4d78cc9bf1539738759d89c11f30db05b5cb6ce4982f790a`** (canonical `7e89c146…`), Portainer stack 42 identical; backups in `backups/20261024T121243Z/`. Only `playit` was started (`up -d --no-deps playit`). API, MySQL and Minecraft kept running |
| `knk-ops` | `compose` records `90c1853b…` (wrapper `85f6e5ea…`); `secret-files` expects `playit_secret` (wrapper `81c824eb…`). Both match `scripts/nas-ops/stage-a/SHA256SUMS` |

Agent start (12:16:47Z): `Starting playitd … secret_path=Some("/run/secrets/playit_secret") version=1.0.12`, then
`playit connected` (agent `41dc4e35-…`). Two ERROR lines (`failed to send initial ping … NetworkUnreachable`) came
1.4 s earlier. They're the IPv6 attempt: `egress` has no IPv6, and the IPv4 connection followed. They didn't repeat.
`tunnel_count=1` from 12:24:19Z. The key wasn't in the logs; the agent used 0.3 % CPU and 2.6 MiB.

## 3. Tunnel and latency

| Step | Result |
|---|---|
| Free tunnel (Minecraft Java, local `minecraft:25565`) | Address `vivo-philippines.tun.ply.gg`, port 25565. A join from a phone hotspot (outside the LAN) worked. **Latency from NL: ping 139 ms, in game ~155 ms (peak 221 ms).** The traceroute shows the global anycast address `147.185.221.217` served from **Fremont, California** (AMS → LON → BOS → CHI → `core1.fmt2.he.net` → Developed Methods LLC) |
| Server side at the same time | TPS 20.0, MSPT avg 1.3–1.7 ms (max 24.5), Minecraft 4 % CPU, 4.9 / 6 GiB. Not the bottleneck |
| **Decision (developer):** playit Premium (~€3/month) | The existing tunnel was moved to the **Germany** region. Address unchanged, now `69.9.185.16` (`fra-eq8`). Ping 12–13 ms, in game **~28 ms** |
| Custom domain | A Cloudflare **CNAME** `play` → `vivo-philippines.tun.ply.gg` resolved correctly, but Minecraft answered "Can't connect to server". playit's Minecraft Java tunnels share an IP and port and route by the **hostname in the handshake**, so an unknown name isn't routed |
| Fix: playit external domain ([guide](https://playit.gg/support/external-domain-cloudflare/)) | CNAME removed; Cloudflare **NS** `play` → `ns1.playit-dns.com` (and `ns2`); in playit, *Domains → Add External Domain* `play.knightsandkings.net` and on the tunnel *Change domain* → it. That delegates only `play.knightsandkings.net` to playit's DNS; the rest of the zone (incl. `app.`) stays in Cloudflare. Premium includes 3 custom domains |
| Result | `Resolve-DnsName play.knightsandkings.net -Type NS` → `ns1`/`ns2.playit-dns.com`; a join through **`play.knightsandkings.net`** works, `/spark ping` **27 ms** |

## 4. Checks after the change

`knk-ops` (PC, 2026-10-24 ~13:00Z):
- `compose`: `matches_recorded: true`, `files_identical: true`;
- `secret-files`: 6 files incl. `playit_secret` `2003:2003 600`, `missing: []`, `unexpected: []`, `all_private: true`;
- `api-health` 200/200;
- `log-errors`: 0 errors, criticals or exceptions;
- `secret-scan`: clean.

`docker ps`: API, MySQL and Minecraft `healthy`, playit `Up`. The playit image has no health check.

## 5. Phase 5 acceptance

| Item | State |
|---|---|
| A player outside the LAN connects | yes: phone hotspot through the playit address (free tunnel); `play.knightsandkings.net` from the LAN goes through the same public path |
| No router port-forward | yes: the agent only dials out, and the NAS has none |
| Only Minecraft TCP is tunnelled | yes: one tunnel to `minecraft:25565`; the agent isn't on `backend` |
| Internet scan can't reach MySQL/RCON/Portainer | yes, later the same day (§ 8): all 13 ports closed/filtered from a phone hotspot; no IPv6 |

## 6. Decisions and settings to remember

- playit **Premium** is a monthly cost (developer, 2026-10-24). If it lapses, the tunnel falls back to the free route
  through the US, and the custom domain may stop working.
- **Proxy Protocol is on** since later the same day (§ 8): playit v2 + Paper `proxies.proxy-protocol: true` +
  `USES_PROXY_PROTOCOL=true` for the health check. Paper sees real player addresses.
- **The whitelist is the gate.** The server is public now: `online-mode=true`, the whitelist is enforced,
  `admission.mode=whitelist` until KNG-218.
- The developer noted the US routing as an extra reason for the VPS track ([KNG-241](https://linear.app/kngpandi/issue/KNG-241), measurement added
  there).

## 7. Open

- **To file in Linear:** "Closed alpha Phase 5: playit.gg agent and `play.knightsandkings.net`". It's this work, kept in
  the tracker until an issue can be created.
- [KNG-228](https://linear.app/kngpandi/issue/KNG-228): `knk-ops containers`/`secret-scan` don't cover
  `knk-alpha-playit` (or `knk-alpha-minecraft`) yet.
- The Proxy Protocol decision (§ 6).
- The external `nmap` scan (go-live § 9 D).

## 8. Addendum, later the same day: Proxy Protocol and external port scan

**Proxy Protocol on** (developer decision, 2026-10-24 ~13:35Z). Until then Paper saw every player as the playit
container's 172.x address, so IP bans, logs and Paper's per-IP limits couldn't tell players apart.

| Step | Result |
|---|---|
| Backups | `backups/20261024T133503Z/` (`compose.yaml`, stack 42 copy, `paper-global.yml`) |
| Paper | `minecraft-data/config/paper-global.yml`: `proxies.proxy-protocol: false` → `true` |
| Compose | `minecraft.environment` + `USES_PROXY_PROTOCOL: "true"`. The itzg image (`scripts/start-finalExec`) then gives `mc-health` `--use-proxy`, so the health check sends a PROXY header too; without it the container would report unhealthy. Compose `90c1853b…` → **`c4e17e5638cb665940b33e7058ef751541978d5a3daab0aaa2a6064020ef7905`**, Portainer identical; the `knk-ops compose` wrapper records it (wrapper `b661d942…`) |
| Restart | `save-all flush`, then `up -d --no-deps minecraft`: healthy after ~30 s, `Done (11.330s)`, API UP, 0 ERROR/SEVERE. Paper warns `Using HAProxy, please ensure the server port is adequately firewalled`. 25565 is reachable only on the stack's Docker networks (API, playit), no port is published, and the scan below confirms nothing is reachable from outside |
| playit | Tunnel → Proxy Protocol **v2** |
| Check | The login line shows the player's real public address (`[/x.x.3.254:…]`, the developer's phone hotspot), not 172.x |

From now on every Minecraft connection must arrive through playit. A direct LAN connection (like the temporary relay of
the 2026-10-22 load check) is rejected.

**External port scan** (go-live § 9 D, runbook Phase 5 acceptance). Done with macOS `nc -z -G 3 -w 3` from the
developer's MacBook on a phone hotspot; Homebrew `nmap` would have had to compile from source, so it was stopped.

| Check | Result |
|---|---|
| Vantage point | Hotspot IPv4 `178.230.x.x`, different from the home IPv4 `31.201.x.x` (the NAS's own `api.ipify.org` answer) |
| Control | `nc` against `portquiz.net:443` → OPEN, so open ports are detected |
| Home IPv4, TCP 22, 80, 443, 3306, 5000, 8080, 8081, 8443, 9000, 9443, 25565, 25575, 33060 | **all closed/filtered** |
| IPv6 | The NAS has no global IPv6 address and no IPv6 egress (`api6.ipify.org` empty), so there's nothing to scan |

Phase 5 acceptance is now complete. Open from § 7: only the Linear issue (to file) and
[KNG-228](https://linear.app/kngpandi/issue/KNG-228) (`knk-ops` coverage of the playit and Minecraft containers).
