# Closed alpha: Bedrock crossplay trial (Geyser + Floodgate over NetherNet) — 2026-10-24

**Status:** Partly working. Bedrock on Windows joins the alpha and plays; consoles see the Friends-tab session but the
join fails on a known MCXboxBroadcast bug (fix expected with Bedrock 26.60, ~2026-10-27)
**Last updated:** 2026-10-25
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

## 5. Consoles via MCXboxBroadcast (2026-10-25)

| Step | Result |
|---|---|
| Extension | `MCXboxBroadcastExtension.jar` build 159 (`5220fca2…`, made for Bedrock 26.50) in `plugins/Geyser-Spigot/extensions/`; config `session.remote-address: 209.25.141.16`, `remote-port: 29517` (`auto` would look up the NAS's public IP via icanhazip.com and announce the home IP) |
| Sign-in | Device code at microsoft.com/link with the developer's dedicated alt account (`MrKnK8949`). The extension waits only ~5 minutes for the code (`Login timed out` twice). `cache.json` now holds the alt's sign-in: it's in `minecraft-data` and in every snapshot |
| PlayStation friend (NAT type 2, home Wi-Fi) | Friend added automatically; the session "Knights and Kings – Closed alpha's world" shows under *Worlds* (1/100); *Trust* → join → `Transferred … to target server` → Geyser: `could not connect over NetherNet: no network path … needs to reach UDP port 29517` → back to *Worlds*. Three attempts, same result |
| Capture on the `egress` bridge | Test packets from the developer's Mac on a phone hotspot reach `minecraft:29517` through playit (the tunnel passes UDP from outside). During the console join: **no UDP from the console at all**; Geyser sends six checks to the console's private address only. Signaling (plain HTTP): Geyser offers `172.27.0.3`/`172.23.0.2` (host, internal) and **`209.25.141.16 29517 typ srflx`** (correct); the console, after the transfer, offers only its host candidate `192.168.1.70` and never tries the public candidate |
| Cause | Known bug: [MCXboxBroadcast #402](https://github.com/MCXboxBroadcast/Broadcaster/issues/402) (open since 2026-10-05): joins through the broadcaster fail when the server uses NetherNet, direct joins work. The maintainer expects the fix in the 26.60 release; the RakNet workaround is useless once 26.60 drops RakNet. A donor-only preview build exists; not used on the alpha |
| Note | The Windows success (§ 3) went over the LAN: Geyser could reach the PC's private address directly. A direct join from another network is not proven yet, though Geyser's srflx candidate and the tunnel's UDP path are right |

Other notes: `TURN CreatePermission … 403` warnings come from the broadcaster's own ICE (Microsoft relays refuse its internal addresses) and are harmless; playit doesn't log UDP; `nethernet-debug` adds nothing to the console log (set back to `false`).

**Next:** after 2026-10-27, swap in the MCXboxBroadcast build for 26.60 (check the 26.60 Geyser build too) and retest with the PlayStation friend; one direct join from outside the home network (a friend's phone or PC). Meanwhile the session stays visible but joins fail; set `friend-sync.auto-friend: false` or remove the jar if that confuses testers.
