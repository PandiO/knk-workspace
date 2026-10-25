# knk-alpha playit.gg agent (runbook Phase 5)

`compose.playit-service.yaml` is the `playit` service for the NAS `knk-alpha` stack's `compose.yaml`. It goes at the
end of `services:`.

| Choice | Why |
|---|---|
| `ghcr.io/playit-cloud/playit-agent:1.0.12` pinned by digest | The official agent. A new version is a reviewed change, like the other pins |
| `entrypoint: playitd --secret-path …` | The image's own entrypoint passes the key as `--secret <key>`, which shows in `ps` on the host. `--secret-path` reads the raw hex key (or a `playit.toml`) from the mounted file |
| `--socket-path /tmp/playitd.sock`, `HOME=/tmp`, `tmpfs /tmp` | As non-root the default `/run/playit/playitd.sock` can't be created; with `read_only: true` only `/tmp` is writable |
| `user: 2003:2003`, `cap_drop: ALL`, `no-new-privileges` | No host account. 2001 is Minecraft and 2002 the API |
| network `egress` only | Internet for the tunnel, plus `minecraft:25565` by service DNS (Minecraft is on `egress` too). Not on `backend`, so the agent can't reach the API or MySQL |
| no published ports | The agent dials out |

The tunnel is set up on the playit.gg dashboard: type Minecraft Java, local address `minecraft`, local port `25565`.
The agent resolves the hostname (`OriginIp::Hostname`, agent 1.0.12 `origin_lookup.rs`).

Tested on 2026-10-24 in a scratch Docker host without internet:
- the container starts as 2003 with a read-only root;
- it logs `secret_path=Some("/run/secrets/playit_secret")`;
- it stops with "Could not reach the playit API", as expected without internet. `restart: unless-stopped` retries;
- the key isn't in the logs.
