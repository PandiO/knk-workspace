# Closed alpha: Bedrock crossplay trial (Geyser + Floodgate over NetherNet) — 2026-10-24

**Status:** In progress. Bedrock on Windows joins the alpha through playit, passes the admission gate and plays;
console access (MCXboxBroadcast) next
**Last updated:** 2026-10-24
**Linear:** none. **To file** (free plan issue limit)
**Background:** [Bedrock console access](2026-10-06-bedrock-console-access.md) (2026-10-06 research)

The developer ran every command and test. Claude Code (cloud session) did the research and wrote the blocks.

## 1. What changed since the 2026-10-06 research

- **Bedrock 26.60 (planned 2026-10-27) drops RakNet.** Clients connect only over **NetherNet**: HTTP signaling over
  TCP, then WebRTC over UDP. Geyser 2.12 supports it (`bedrock.transport: nethernet`, built-in signaling). The trial
  was built for NetherNet only.
- **playit.gg:** a **TCP+UDP** tunnel (one public port for both) carries signaling and gameplay. playit's own "Bedrock
  NetherNet" type is experimental; the plain "Minecraft Bedrock" type is RakNet.
- **The API's admission check accepts only `^[A-Za-z0-9_]{1,16}$` names.** Floodgate's default prefix `.` would make
  every Bedrock join fail the check, so the prefix is `BE_` (Floodgate warns it's long and could collide with a Java
  name; identity is by UUID, so a collision is cosmetic).

## 2. Setup

| Item | Value |
|---|---|
| Plugins | `Geyser-Spigot.jar` 2.12.0 b1270 (`6acaff23…`), `floodgate-spigot.jar` 2.2.5 b141 (`21570aff…`), from download.geysermc.org, hashes checked, `2001:2001 644` in `plugins/` |
| playit | Tunnel TCP+UDP, region Europe, public `209.25.141.16:29517` (`vivo-organizer.tun.ply.gg`), local `minecraft:29517`, Proxy Protocol off |
| Geyser `config.yml` | `bedrock.port: 29517`, `transport: nethernet`, `webrtc-port: 0` (same port), `signaling.mode: builtin`, `advertise-addresses: ["209.25.141.16:29517"]`, **`stun-discovery: false`** (it would announce the home IP, unreachable and a privacy leak), `java.auth-type: floodgate`, MOTD/server name "Knights and Kings"/"Closed alpha", **`advanced.java.use-haproxy-protocol: true`** (Paper has `proxies.proxy-protocol: true`; without the header Paper drops Geyser's connection silently and the client says "End of stream"), `use-direct-connection: true` |
| Floodgate `config.yml` | `username-prefix: "BE_"` |
| Compose | unchanged (Geyser listens inside the `minecraft` container; the playit agent reaches it over `egress`) |

Backups of both configs are in `backups/<TS>/` and `backups/geyser-config-<TS>.yml`.

## 3. Results (Windows Bedrock, developer)

- Add server `209.25.141.16` port `29517` → join → Xbox sign-in OK.
- First try: "End of stream" (Proxy Protocol, § 2) → fixed.
- Stranger → the KnK disconnect screen with a claim code; sign-up with an invite + link on `/account/link` → rejoin →
  plays.
- **Finding:** moving from one KnK inventory menu to the next, the slightest mouse movement cancels the next menu as
  it opens (Bedrock closes the form and the next open arrives in the middle of the close). Acceptable for now; a
  plugin-side fix (a short delay before opening the next menu for Floodgate players) is the likely remedy.
- Bedrock players appear with playit's address, not their own (no Proxy Protocol on the TCP+UDP tunnel): IP bans
  don't work for them in this trial.

## 4. Next

Consoles (Xbox, PlayStation, Switch) can't add a server address; Windows, Android and iOS can. For consoles:
MCXboxBroadcast extension build 159 with the developer's dedicated alt Microsoft account (risk accepted by the
developer, 2026-10-24), `session.remote-address/remote-port` set to the playit address.
