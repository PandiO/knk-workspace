# Plugin configuration reference (`config.yml`)

**Status:** Current · **Last updated:** 2026-11-14 (§ 4.20 `fair-chance`, PandiO/knk-workspace#476, on a branch; before that 2026-11-13: § 4.11 gates are discovered too; § 4.21 realtime push; § 4.26 the kit cache, PandiO/knk-workspace#300)
**Checked against:** knk-plugin `main` `121030f`; § 4.11, § 4.21 and § 4.26 against `57884e9`. Update this page in place whenever a `config.yml` key is added, renamed, removed or gets a new default.
**Source:** knk-plugin `knk-paper/src/main/resources/config.yml` (1,152 lines at `121030f`), read by
`knk-paper/.../paper/config/ConfigLoader.java`, `EnchantmentConfigManager.java` and `KnKPlugin.java`
**Related:** [production installation § 9.5](../production-installation.md#95-install-the-knightsandkings-plugin),
[closed-alpha deployment runbook](../closed-alpha-deployment-runbook.md),
[global instructions § Shipping a change](../../ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md#shipping-a-change-documentation),
[custom enchantment combat values](custom-enchantment-combat-values-admin-guide.md),
[gate structures admin guide](gate-structures-admin-guide.md)

This is the reference for every key in the Knights and Kings plugin's `config.yml`
(`plugins/KnightsAndKings/config.yml` on a server). For each key it gives the default, what the key does, safe
values, the issue that added it, and whether a restart or a reload command picks up a change.

Many settings are **not** in `config.yml`. They live in the web app and the API, and the plugin re-reads them on
its own: Game Settings (announcements, spawn, respawn, time, weather, and the chat token limits from #233), custom
enchantment combat values, lootbox areas and odds, siege lobbies and scenarios, road profiles, currency policy and
permission groups. This page only covers the file.

## 1. How the plugin reads `config.yml`

- **The file is written once.** `KnKPlugin.onEnable` calls `saveDefaultConfig()`, which writes the jar's built-in
  `config.yml` only when the server has none. After that the plugin never changes the file: a new build never adds
  its new keys, and it never removes keys it stopped reading. Merge new keys by hand at every deploy (§ 2).
- **A missing key uses the built-in default.** Where the code passes its own fallback (most keys), that is used.
  Otherwise Bukkit falls back to the jar's `config.yml`. The two are the same for every key checked for this
  reference except `custom-enchantments.messages.cmd-reload`, whose code fallback is shorter
  ([#307](https://github.com/PandiO/knk-workspace/issues/307)). So a server without a new key runs on the default, with no warning in the log. That is what goes
  wrong when a merge is skipped: you can't change the setting, and a message key shows the jar's text.
- **A key the plugin doesn't read is ignored.** An old block such as `gates.cleaving` (removed by #259) does no
  harm. Delete it when you merge, so nobody edits it expecting an effect.
- **Restart, reload or live.** The **Applies** column in § 4 says when a change takes effect:
  - **Restart:** read once at startup (most keys). Restart the server, never use `/reload` (the runbook rule).
  - **`/ce reload`:** the custom enchantment messages and death messages. The command (node
    `customenchantments.command.reload`) re-reads the whole file and refreshes the combat values from the API.
  - **`/knk lootbox reload`:** the `lootboxes` section. The command (node `knk.lootbox.admin.reload`) re-reads the
    whole file and the API's lootbox runtime config.
  - **Any reload:** a few keys are read again on every event: `join-refusal-notify.enabled`,
    `regions.global.protection` and `regions.effect-damage.enabled`. Either reload command makes the plugin re-read
    the file, so they change after `/ce reload` or `/knk lootbox reload` too.
- **Secrets.** `api.auth.api-key` (and `metrics.token`) are secrets. Keep the file `chmod 600`. Never paste them in
  an issue, a report or chat.
- **Colour codes.** Text uses `&` colour codes. `\n` starts a new line where the comment says so.

## 2. Merging config changes at a deploy

Do this at **every** plugin deploy to dev or alpha, also when the release notes list no config change.

1. **Get both files.** Extract the new jar's default and copy the server's live file:

   ```bash
   unzip -p KnightsAndKings.jar config.yml > jar-config.yml
   cp plugins/KnightsAndKings/config.yml server-config.yml          # on the alpha: the file in the stack's plugins/ folder
   ```

2. **List the differences** with [`scripts/plugin-config/config_diff.py`](../../../scripts/plugin-config/config_diff.py)
   (Python 3 with PyYAML; it runs on the developer PC too):

   ```bash
   python3 scripts/plugin-config/config_diff.py jar-config.yml server-config.yml
   ```

   It prints the keys missing on the server and the keys only on the server. Example: a file from before #259 gives
   one missing key (`custom-enchantments.messages.cmd-info-tuning-gate`) and three server-only keys
   (`gates.cleaving.*`). A file from plugin `d56e41da` (the alpha's 2026-10-24 build) gives 43 missing keys.
3. **Paste the missing keys** from `jar-config.yml` into the server file, **in the same section and with their
   comments**, so the next person can see what they do. Keep every local value (API URL, API key, server ids,
   admission mode, ports, worlds, region overrides).
4. **Delete the server-only keys** that the changelog lists as removed. If a key isn't in the changelog, check it
   for a typo first: a misspelt key is ignored too.
5. **Read the changelog's "Admin steps"** for the builds since the last deploy. They list changed defaults, which
   the script can't detect: the server keeps its old value on purpose. Adopt the new default where the entry says so.
6. **Check the YAML.** It must load (`python3 -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" server-config.yml`).
   Then copy it back (`chmod 600`), restart, and look for `Configuration loaded successfully` in the log.
7. **Record it** in the deploy report: build, keys added, keys removed and values changed. Leave out secrets.

A `/knk config diff` command that lists missing keys in game is proposed in
[PandiO/knk-workspace#308](https://github.com/PandiO/knk-workspace/issues/308).

### 2.1 Key changes since 2026-10-24

Newest first. Builds before this list: compare the files with the script.

| Merged | Issue | Added (+), removed (−) or changed | Applies |
|---|---|---|---|
| not merged (branch `claude/eager-cannon-h8dtum`) | [#476](https://github.com/PandiO/knk-workspace/issues/476) | + `custom-enchantments.fair-chance` (`enabled`, `min-bag-size`, `max-bag-size`) | Restart |
| 2026-11-10 | [#259](https://github.com/PandiO/knk-workspace/issues/259) | − `gates.cleaving` (`damage-bonus-per-level`, `charged-hit-multiplier`, `charged-cooldown-seconds`): no longer read. Cleaving's numbers are combat values in the web app now ([combat values guide](custom-enchantment-combat-values-admin-guide.md#1-where-to-edit)). Delete the block. + `custom-enchantments.messages.cmd-info-tuning-gate` | `/ce reload` |
| 2026-11-10 | [#233](https://github.com/PandiO/knk-workspace/issues/233) | No `config.yml` change. The chat token limits are on the web app's Game Settings page ([chat tokens guide](../chat-tokens.md)) | — |
| 2026-11-04 | [#178](https://github.com/PandiO/knk-workspace/issues/178), [#179](https://github.com/PandiO/knk-workspace/issues/179) | + `realtime` block (off by default) | Restart |
| 2026-11-04 | [#180](https://github.com/PandiO/knk-workspace/issues/180) | + `world-tasks.heartbeat-interval-seconds` | Restart |
| 2026-11-04 | [#222](https://github.com/PandiO/knk-workspace/issues/222) | + `custom-enchantments.death-messages` (`enabled`, `default`, `overrides`) | `/ce reload` |
| 2026-11-04 | [#223](https://github.com/PandiO/knk-workspace/issues/223) | + `custom-enchantments.messages.cmd-info-tuning-area`. The text of `gates.area-enchantment-radius-blocks` changed: Chaos and Flash Chaos gate damage is a combat value now, the radius stays here | `/ce reload` |
| 2026-11-03 | [#201](https://github.com/PandiO/knk-workspace/issues/201) | + `custom-enchantments.messages.cmd-info-tuning-effects` | `/ce reload` |
| 2026-11-03 | [#212](https://github.com/PandiO/knk-workspace/issues/212) | + `lore.max-width` | Restart |
| 2026-10-26 | [#151](https://github.com/PandiO/knk-workspace/issues/151) | + `custom-enchantments.tuning-refresh-minutes` (restart), `custom-enchantments.messages.cmd-info-tuning` (`/ce reload`) | See § 4.20 |
| 2026-10-26 | [#159](https://github.com/PandiO/knk-workspace/issues/159) | + `join-refusal-notify` | See § 4.5 |
| 2026-10-26 | [#160](https://github.com/PandiO/knk-workspace/issues/160) | + `menus.menu-item` | Restart |
| 2026-10-26 | [#161](https://github.com/PandiO/knk-workspace/issues/161) | + `crossplay.block-resync` | Restart |
| 2026-10-26 | [#162](https://github.com/PandiO/knk-workspace/issues/162) | + `regions.effect-damage` | See § 4.23 |
| 2026-10-26 | [#150](https://github.com/PandiO/knk-workspace/issues/150), [#154](https://github.com/PandiO/knk-workspace/issues/154) | + `siege.rejoin-window-seconds`, `gates.siege` | Restart |
| 2026-10-25 | QOL hotfix | + `regions.global` (`protection`, `crafting-blocks`) | See § 4.23 |
| 2026-10-24 | siege playtest 2026-10-24 | + `gates.fire-aspect.ignite-chance-per-level` | Restart |
| 2026-10-24 | Bedrock menus | + `menus.bedrock-transition-delay-ticks` | Restart |

## 3. Sections at a glance

| § | Section | What it covers |
|---|---|---|
| 4.1 | `api` | knk-web-api URL, API key, timeouts, connectivity probe |
| 4.2 | `region-http` | The plugin's own HTTP server the API calls back |
| 4.3 | `realtime` | SignalR channel to the API (off by default) |
| 4.4 | `metrics` | Prometheus `/metrics` endpoint (off by default) |
| 4.5 | `web`, `admission`, `join-refusal-notify`, `onboarding` | Web links, the invite-only gate, refused-join notices, first join |
| 4.6 | `account` | `/account` link codes and cooldowns |
| 4.7 | `world-tasks`, `player-notifications` | Polling and leases for world tasks and queued in-game moments |
| 4.8 | `private-messages` | `/msg`, `/reply`, social spy, PM log |
| 4.9 | `game-settings` | How the plugin follows the web app's Game Settings |
| 4.10 | `teleport` | Warmups, cooldowns, `/tpa`, `/warp`, `/back` |
| 4.11 | `discovery` | Domain discovery detection and effects |
| 4.12 | `statistics`, `telemetry`, `world-analytics` | Player statistics, diagnostic events, anonymous heatmaps |
| 4.13 | `siege` | Rejoin window |
| 4.14 | `lore`, `menus`, `crossplay` | Lore width, menus, the menu item, Bedrock ghost blocks |
| 4.15 | `navigation` | Road navigation and walk paths |
| 4.16 | `currency` | `/pay`, `/baltop`, `/transactions` |
| 4.17 | `gates` | Gate commands, sync, damage, fire, pass-through, animation |
| 4.18 | `messages` | Plugin prefix, account and currency messages |
| 4.19 | `enchant-books` | Grade level cap of enchantment books |
| 4.20 | `custom-enchantments` | Runtime settings, death messages, `/ce` messages |
| 4.21 | `lootboxes` | How this server places, shows and opens lootboxes |
| 4.22 | `worlds` | Extra worlds loaded at startup |
| 4.23 | `regions` | Region cleanup, global protection, effect damage, managed regions, entry/exit |
| 4.24 | `command-visibility` | What `/` suggests |
| 4.25 | `offline-cache` | Offline security cache |
| 4.26 | `cache` | API response cache per entity |

## 4. Key reference

Keys are written relative to the section heading (`auth.type` under `api` is `api.auth.type`). "Restart" means the
key is read at startup only (§ 1).

### 4.1 `api`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `base-url` | `"http://localhost:5294/api"` | knk-web-api base URL, **with** the `/api` suffix. Production: `http://127.0.0.1:5000/api` (loopback) | Restart | — |
| `debug-logging` | `false` | Logs every request and response (URL, latency, headers, body; the key and `Authorization` redacted). Noisy: only for a short debug session | Restart | — |
| `allow-untrusted-ssl` | `false` | Accepts self-signed certificates. Development only; keep `false` on any server that reaches the API over a network | Restart | KNG-64 |
| `auth.type` | `apikey` | `none`, `bearer` or `apikey`. The API refuses protected game-server calls without the key; `none` only works when the API sets `Security:AllowUnauthenticatedPluginCalls` (development) | Restart | KNG-22 |
| `auth.bearer-token` | `""` | Token for `type: bearer` | Restart | KNG-22 |
| `auth.api-key` | `""` | **Secret.** Must equal the API's `Security:PluginApiKey` (`Security__PluginApiKey`), e.g. `openssl rand -hex 32`. With `type: apikey` and an empty key the plugin refuses to start, on purpose. The region HTTP server (§ 4.2) also requires it | Restart | KNG-22 |
| `auth.api-key-header` | `"X-API-Key"` | Header name. Keep `X-API-Key`, which the API reads | Restart | KNG-22 |
| `timeouts.connect` / `.read` / `.write` | `10` / `10` / `10` | HTTP timeouts in seconds | Restart | — |
| `connectivity.enabled` | `true` | Probes the API's `GET /health/ready` (which checks MySQL too) and keeps one UP/DOWN state; `/knk health` shows it | Restart | KNG-115 |
| `connectivity.probe-interval-seconds` | `10` | Seconds between probes | Restart | KNG-115 |
| `connectivity.probe-timeout-seconds` | `5` | Whole-call timeout of a probe (the API's own database check gives up after 3 s) | Restart | KNG-115 |
| `connectivity.failures-to-down` | `3` | Consecutive failed probes before UP → DOWN | Restart | KNG-115 |
| `connectivity.successes-to-up` | `2` | Consecutive passing probes before DOWN → UP | Restart | KNG-115 |
| `connectivity.health-root-url` | `""` | API root that serves `/health/ready`. Empty = `base-url` without `/api` | Restart | KNG-115 |
| `connectivity.skip-api-while-down` | `true` | While DOWN, reads (permission checks, users, catalogues) make no API call and are answered from the caches, then the offline store (§ 4.25). Writes still go to the API. `false` = keep calling the API during an outage | Restart | KNG-171 |

### 4.2 `region-http`

knk-web-api calls the plugin back on this server for region renames and containment checks.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `bind-address` | `"127.0.0.1"` | Listen address. Loopback accepts only this host. Use the Docker host IP when the API runs in a container; never `0.0.0.0` on a public server | Restart | KNG-64 |
| `port` | `8081` | Listen port; the API's `MinecraftPlugin__BaseUrl` must use the same port | Restart | — |

### 4.3 `realtime`

One SignalR connection to the API's game hub ([design](../../specs/realtime-signalr/DESIGN.md),
[smoke test](../realtime-smoke-test.md)). Off by default: with `enabled: false` the plugin polls as before. Needs
`api.auth.type: apikey`.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `false` | Turns the channel on. When on, the plugin reports who is online and re-reads what the API changed after every (re)connect | Restart | #178 |
| `server-id` | `"localhost"` | This game server's id: sent to the hub (`X-Knk-Server-Id`) and **stored on world tasks claimed here, also with realtime off** (#180). Letters, digits, `.`, `_`, `-`, at most 64. Give every server sharing one API its own id | Restart | #178 |
| `hub-url` | `""` | Full hub URL. Empty = `api.base-url` without `/api` plus `hub-path`. The plugin talks to the API directly, not through nginx | Restart | #178 |
| `hub-path` | `"/api/hubs/game"` | Hub path used when `hub-url` is empty | Restart | #178 |
| `backoff-seconds` | `[1, 2, 5, 10, 30]` | Delays between reconnect attempts; the last repeats. No attempts while the connectivity probe says DOWN | Restart | #178 |
| `backoff-jitter` | `0.2` | Random spread of each delay (0.2 = ±20 %), so servers don't retry in step | Restart | #178 |
| `fallback-poll-multiplier` | `4` | While connected, re-syncs that the hub now pushes run this many times less often (social spy re-check 60 s → 4 min); the player notification poll stops while connected. `1` = no slowdown | Restart | #179 |

### 4.4 `metrics`

A Prometheus endpoint with TPS, tick time, players, chunks, JVM, CPU, memory and API-call timings
([performance metrics and capacity](../performance-metrics-and-capacity.md)). Off by default.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `false` | Starts the endpoint | Restart | KNG-232 |
| `bind-address` | `"127.0.0.1"` | Listen address. For Prometheus in another container use the Docker host or bridge IP **and** set `token`; never `0.0.0.0` on a public server | Restart | KNG-232 |
| `port` | `9225` | Listen port | Restart | KNG-232 |
| `token` | `""` | **Secret.** Bearer token the scraper sends. Required when `bind-address` isn't loopback; the plugin refuses to start otherwise | Restart | KNG-232 |
| `sample-seconds` | `5` | How often the main thread samples TPS, tick time, chunks and entities (1–60) | Restart | KNG-232 |

### 4.5 `web`, `admission`, `join-refusal-notify`, `onboarding`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `web.public-url` | `""` | Public web app URL without a trailing slash, e.g. `https://app.knightsandkings.net`. Used in player messages (`/account link`). Empty: lines with `{url}` are left out | Restart | KNG-64 |
| `admission.mode` | `whitelist` | Admission gate at pre-login ([invitations design § 5.2](../../specs/invitations/DESIGN.md)). `whitelist`: no gate, the vanilla whitelist decides (also the kill switch). `open`: no gate. `invite`: operators and admitted accounts get in, everyone else gets a claim code; switch the API's `Security:Registration:Mode` to `Invite` at the same time | Restart | KNG-214 |
| `admission.api-timeout-ms` | `3000` | How long pre-login waits for the API. On a timeout, players the offline cache knows get in and strangers are told to retry (fail-closed) | Restart | KNG-214 |
| `admission.link-url` | `""` | Where the claim code is entered. Empty = `{web.public-url}/link` | Restart | KNG-214 |
| `admission.kick` | (text) | Disconnect screen for a stranger. Placeholders `{url}`, `{code}` (`XXXX-XXXX`), `{minutes}` | Restart | KNG-214 |
| `admission.unavailable` | (text) | Disconnect screen when access can't be checked | Restart | KNG-214 |
| `admission.deactivated` | (text) | Disconnect screen for a deactivated account | Restart | KNG-214 |
| `admission.account-linked` | (text) | In-game notice after a Minecraft-to-web link (on the next join when offline). Placeholder `{maskedEmail}` | Restart | KNG-214 |
| `join-refusal-notify.enabled` | `true` | Online holders of `knk.notify.joinattempt` get a chat line with the reason when a join is refused (ban, whitelist, full, admission gate, missing world, hub) | Any reload | #159 |
| `join-refusal-notify.cooldown-seconds` | `60` | At most one line per player per this many seconds, so a client retrying in a loop doesn't flood chat. Read at startup, although the file's comment says both keys are read on every refusal ([#307](https://github.com/PandiO/knk-workspace/issues/307)) | Restart | #159 |
| `onboarding.first-join-welcome` | (list of 2 lines) | Sent instead of "Welcome back" on a player's first join. Placeholder `{player}` | Restart | KNG-128 |
| `onboarding.link-prompt` | (text) | Text before the link button on the first join and in the reminder | Restart | KNG-128 |
| `onboarding.link-button` / `.link-button-hover` | (text) | The clickable button (runs `/account link`) and its hover | Restart | KNG-128 |
| `onboarding.discovery-quiet-minutes` | `10` | Discovery announcements are held this long after a first join and then shown as one summary (0–60, `0` = off). Rewards are given right away | Restart | KNG-129 |
| `onboarding.discovery-settled-summary` | (text) | That summary. Placeholder `{count}` | Restart | KNG-129 |
| `onboarding.unlinked-reminder.enabled` / `.message` | `true` / (text) | Reminder at every later join of a player without a web account, followed by the button | Restart | KNG-129 |

### 4.6 `account`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `link-code-expiry-minutes` | `20` | How long an `/account link` code stays valid | Restart | — |
| `chat-capture-timeout-seconds` | `120` | Longest wait for a player's chat input in an account flow | Restart | — |
| `cooldowns.account-create-seconds` | `300` | Cooldown of `/account create` | Restart | — |
| `cooldowns.link-code-generate-seconds` | `60` | Cooldown of `/account link` (getting a code) | Restart | — |
| `cooldowns.link-code-consume-seconds` | `10` | Unused: codes are entered on the website. Kept so old files load | — | — |
| `cooldowns.cleanup-interval-minutes` | `5` | How often expired cooldowns are dropped from memory | Restart | — |

### 4.7 `world-tasks`, `player-notifications`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `world-tasks.headless-poll-interval-seconds` | `5` | How often the plugin asks the API for headless (player-less) world tasks | Restart | — |
| `world-tasks.headless-poll-max-interval-seconds` | `60` | The interval doubles up to this while none is found | Restart | — |
| `world-tasks.heartbeat-interval-seconds` | `60` | How often this server renews its claims (at least 10). The API hands a claim back after 3 minutes without one (`WorldTasks:LeaseMinutes`), so stay well below that | Restart | #180 |
| `player-notifications.poll-interval-seconds` | `2` | How often queued in-game moments (e.g. a promotion granted on the web) are fetched; skipped with no players online, stopped while `realtime` is connected | Restart | — |

### 4.8 `private-messages`

`/msg`, `/reply` and `/socialspy` ([design § 3.3.10](../../specs/private-messages/DESIGN.md)).

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `max-length` | `256` | Longer messages are cut off (only possible from the console) | Restart | — |
| `sound.enabled` / `.volume` / `.pitch` | `true` / `1.0` / `1.0` | Sound played to the recipient | Restart | — |
| `rate-limit.max-messages` / `.window-seconds` | `5` / `5` | At most this many messages per window per sender. Bypass: `knk.msg.bypass.ratelimit` | Restart | — |
| `rate-limit.duplicate-window-seconds` | `10` | The same text to the same player within this window counts as spam | Restart | — |
| `spy.refresh-seconds` | `60` | How often the social spy audience is re-checked (× `realtime.fallback-poll-multiplier` while connected) | Restart | — |
| `log.local-enabled` / `.local-retention-days` | `true` / `30` | Daily file `logs/private-messages-YYYY-MM-DD.log` in the plugin folder, kept this many days | Restart | — |
| `log.api-enabled` | `true` | Also logs to knk-web-api (30-day retention, read with `knk.pmlog.read`). Needs the API key. Waits in memory (up to 1,000) and in `private-messages-spool.jsonl` while the API is down | Restart | — |
| `log.flush-seconds` | `5` | Sent every this many seconds or every 50 messages | Restart | — |
| `log.filter-command-log` | `true` | Keeps `issued server command: /msg …` lines out of `latest.log` | Restart | — |
| `block-vanilla-commands` | `true` | Routes `/minecraft:msg`, `tell`, `w` through `/msg` and blocks `/teammsg`, `/tm`, `/me` for non-ops, so they can't bypass spy, the limit and the log | Restart | — |

### 4.9 `game-settings`

The settings themselves are edited on the web app's Game Settings page ([game settings guide](../game-settings.md));
these keys only tune how the plugin follows them.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `refresh-interval-seconds` | `30` | How often the settings are read (at least 5). `/knk cache refresh` reads them at once | Restart | KNG-52 |
| `runtime-sync-interval-seconds` | `30` | How often loaded worlds are checked; reported to the API when they change or every 10 minutes (at least 5). Needs the API key | Restart | KNG-52 |
| `server-id` | `"default"` | This server's id in that report; each server replaces only its own worlds. Give every server sharing one API its own id. Blank = `default` | Restart | KNG-118 |
| `backup-history-limit` | `48` | Earlier versions kept in `game-settings-backups/` (0 = none). The latest is always in `game-settings-cache.json` and used when the API is down at startup | Restart | KNG-52 |

### 4.10 `teleport`

Player teleports (`/tpa`, `/tpahere`, `/spawn`, `/warp`, `/back`). Staff teleports (`/tp`, `/tphere`, `/knk tp`)
are instant and skip all of this ([teleport design § 3.11](../../specs/teleport/DESIGN.md)).

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `warmup-seconds` | `5` | Wait before a teleport; moving a block or taking damage cancels it | Restart | — |
| `warmup-short-seconds` | `3` | Warmup for holders of `knk.teleport.warmup.short` (Noble tier and up) | Restart | — |
| `cooldown-seconds` | `30` | Before the same kind of teleport works again. A permission group's own cooldown (web app, KNG-41) replaces it | Restart | — |
| `combat-tag-seconds` | `10` | A PvP hit (dealt or taken) blocks player teleports this long | Restart | — |
| `safe-search-radius` | `3` | Blocks searched around an unsafe destination for a safe spot before refusing | Restart | — |
| `request.expire-seconds` | `30` | Time the target has to accept a `/tpa` or `/tpahere` | Restart | — |
| `request.cooldown-seconds` | `10` | Between two requests from one player (`knk.teleport.bypass.cooldown` skips it) | Restart | — |
| `request.max-incoming` | `5` | Pending requests per player; the oldest is dropped past this | Restart | — |
| `request.price-coins` | `0` | Coins a request costs (0 = free), charged by the API after the warmup and refunded on failure. A permission group can replace it (KNG-41) | Restart | — |
| `destinations.cache-seconds` | `60` | How long a player's `/warp` destination list is cached | Restart | — |
| `back.enabled` | `true` | `/back` to the latest death or teleport the player's nodes allow (KNG-42) | Restart | KNG-42 |
| `back.expire-seconds` | `300` | How long `/back` stays available after the death or teleport | Restart | KNG-42 |
| `back.expire-seconds-by-kind` | (not set) | Optional per-kind overrides: `death`, `warps`, `teleport`, `spawn` (commented example in the file) | Restart | KNG-42 |
| `back.price-coins` | `0` | Coins a player's own `/back` costs (`knk.teleport.bypass.cost` pays nothing) | Restart | KNG-42 |

### 4.11 `discovery`

The first entry into a Town, District, Structure or gate is recorded and rewarded once; the API decides the rewards and
caps ([design § 3.6](../../specs/domain-discovery/DESIGN.md), [economy admin guide § 5](economy-admin-guide.md#5-discoveries)).

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `true` | Detection on or off | Restart | KNG-20 |
| `batch-window-ticks` | `20` | How often entered regions are sent, one request per player | Restart | KNG-20 |
| `max-requests-per-minute` | `12` | Per player; the rest waits | Restart | KNG-20 |
| `excluded-game-modes` | `[CREATIVE, SPECTATOR]` | Game modes that discover nothing | Restart | KNG-20 |
| `exclude-siege-participants` | `true` | Siege lobby members discover nothing until restored after the match | Restart | KNG-20 |
| `spool-directory` / `replay-interval-seconds` | `discovery-spool` / `60` | Discoveries made while the API was down, one file per player, replayed this often and at the next join | Restart | KNG-20 |
| `effects.sound` / `.sound-volume` / `.sound-pitch` | `UI_TOAST_CHALLENGE_COMPLETE` / `0.8` / `1.0` | A Bukkit `Sound` name or a namespaced key | Restart | KNG-20 |
| `effects.particle` / `.particle-count` / `.particle-spread` | `HAPPY_VILLAGER` / `30` / `0.6` | A Bukkit `Particle` that needs no extra data | Restart | KNG-20 |
| `effects.town-firework` | `true` | Extra firework for a Town | Restart | KNG-20 |
| `effects.spacing-ticks` | `10` | Between the effects of several places found at once | Restart | KNG-20 |
| `messages.discovered` | (text) | One line per place. `{type}`, `{name}`, `{parent}` | Restart | KNG-20 |
| `messages.replay-summary` | (text) | Shown when spooled discoveries are granted later. `{count}` | Restart | KNG-20 |

### 4.12 `statistics`, `telemetry`, `world-analytics`

Player statistics ([plan § 5.1](../../specs/player-statistics/IMPLEMENTATION_PLAN.md)); `/stats settings` (the
privacy menu) works with either value of `enabled`.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `statistics.enabled` | `true` | `false` registers no statistics listener, task or `/afk` | Restart | KNG-34 |
| `statistics.flush-interval-seconds` | `60` | Batches sent this often | Restart | KNG-34 |
| `statistics.max-batch-entries` | `2000` | Entries per batch (the API takes at most 2,000) | Restart | KNG-34 |
| `statistics.spool-directory` / `.replay-interval-seconds` | `statistics-spool` / `60` | Undelivered batches on disk, replayed this often | Restart | KNG-34 |
| `statistics.excluded-game-modes` | `[CREATIVE, SPECTATOR]` | No combat, distance or fall statistics in these modes (playtime still counts) | Restart | KNG-34 |
| `statistics.afk.enabled` | `true` | `false`: every online second is active; no `/afk`, no automatic AFK, no marker | Restart | KNG-34 |
| `statistics.afk.idle-seconds` | `300` | Automatic AFK after this long without activity | Restart | KNG-34 |
| `statistics.afk.command-enabled` / `.tab-list-marker` / `.marker-text` | `true` / `true` / `"&7[AFK]"` | `/afk`, and the tab-list marker and its text | Restart | KNG-34 |
| `statistics.movement.enabled` / `.max-segment-blocks` | `true` / `10.0` | Distance per mode; a longer single move is a relocation, not travel | Restart | KNG-34 |
| `statistics.fall.enabled` | `true` | Highest survived fall | Restart | KNG-34 |
| `statistics.combat.enabled` | `true` | Kills, deaths, damage, arrows, headshots, open-world killstreaks | Restart | KNG-34 |
| `statistics.combat.count-custom-damage` | `false` | Plugin-dealt damage (Chaos procs) would be counted twice; leave off | Restart | KNG-34 |
| `statistics.combat.pve-excluded-spawn-reasons` | `[SPAWNER, SPAWNER_EGG, BREEDING, EGG, DISPENSE_EGG]` | Farmed creatures: killing them is no PvE kill | Restart | KNG-34 |
| `statistics.gates.enabled` / `.fire-attribution` | `true` / `true` | Credit gate-door damage to players, fire to whoever lit each block (gate HP works the same either way) | Restart | KNG-34 |
| `statistics.siege.report-departed-members` | `true` | Report members who left a match early with their stats (still no reward) | Restart | KNG-34 |
| `telemetry.enabled` | `true` | Diagnostic timeline only the owner reads in the web app. Never chat, command arguments, IPs or tokens | Restart | KNG-34 |
| `telemetry.max-buffer-events` | `5000` | Held between flushes; beyond this the oldest are dropped. Never spooled | Restart | KNG-34 |
| `telemetry.flush-interval-seconds` / `.config-poll-seconds` | `10` / `60` | Send interval; how often the owner's choices (enhanced players, test runs) are read | Restart | KNG-34 |
| `telemetry.enhanced-movement-sample-seconds` | `5` | Position sample interval for enhanced players | Restart | KNG-34 |
| `world-analytics.enabled` | `true` | Anonymous heatmaps, menu funnels and domain interactions for `/owner/analytics` | Restart | KNG-34 |
| `world-analytics.movement-sample-seconds` | `10` | One sample per online, non-AFK player this often (at least 10) | Restart | KNG-34 |
| `world-analytics.cell-size` | `16` | Heatmap cell edge in blocks | Restart | KNG-34 |
| `world-analytics.flush-interval-seconds` | `300` | Posted this often, never across the API's statistics midnight | Restart | KNG-34 |
| `world-analytics.movement` / `.menu-funnels` / `.domain-interactions` | `true` / `true` / `true` | Part switches | Restart | KNG-34 |
| `world-analytics.excluded-game-modes` | `[CREATIVE, SPECTATOR]` | Not sampled (spectators never are) | Restart | KNG-34 |
| `world-analytics.max-pending-batches` | `12` | Windows kept in memory while the API is unreachable | Restart | KNG-34 |

### 4.13 `siege`

Lobbies, scenarios and the siege configuration are edited in the web app.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `rejoin-window-seconds` | `300` | A member who disconnects at the hub or in a match keeps their place this long and counts as present at the end. `0` = a disconnect is a leave | Restart | #150 |

### 4.14 `lore`, `menus`, `crossplay`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `lore.max-width` | `40` | Lore lines wider than this many visible characters wrap between words, keeping their colour (blueprint items and every menu). At least 10 | Restart | #212 |
| `menus.bedrock-transition-delay-ticks` | `3` | Bedrock (Floodgate) players: a menu-to-menu click closes the menu first and opens the next this many ticks later, so Geyser's late close doesn't close the new one. `0` = off; at most 20. Java players are never delayed | Restart | Bedrock menus |
| `menus.menu-item.enabled` | `true` | An inventory item that opens `/menu`, for console and Bedrock players. It never drops, can't be stored or placed | Restart | #160 |
| `menus.menu-item.give-to` | `all` | `all`, or `bedrock` (Floodgate players only) | Restart | #160 |
| `menus.menu-item.give-on-join` / `.keep-on-death` | `true` / `true` | Put it back at every join when missing; give it back at respawn | Restart | #160 |
| `menus.menu-item.material` / `.name` / `.lore` | `NETHER_STAR` / (text) / (1 line) | Its look | Restart | #160 |
| `menus.menu-item.slot` | `8` | 0–8 hotbar (8 = right-most), 9–35 main inventory. A player's own item there is moved; with a full inventory nothing is given | Restart | #160 |
| `menus.menu-item.open-on` | `[RIGHT_CLICK, LEFT_CLICK, INVENTORY_CLICK]` | What opens the menu. `INVENTORY_CLICK` only works while `movable` is `false` | Restart | #160 |
| `menus.menu-item.droppable` / `.movable` | `false` / `false` | Allow dropping it (gone until the next join or respawn) or moving it in the own inventory | Restart | #160 |
| `crossplay.block-resync.enabled` | `true` | Bedrock ghost blocks: a refused break is sent to the player again while they keep swinging. Needs Floodgate | Restart | #161 |
| `crossplay.block-resync.all-players` | `false` | Also for Java players (only for testing) | Restart | #161 |
| `crossplay.block-resync.window-ticks` / `.interval-ticks` | `30` / `5` | Resend every interval while swinging, and once more this window after the last swing | Restart | #161 |

### 4.15 `navigation`

Road navigation ([design § 4](../../specs/navigation/DESIGN.md)); road materials live in the API's road profiles.
Every key has a default, and the defaults are tuned from live tests: change them only with a reason.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `true` | `/navigate` on or off | Restart | KNG-27 |
| `class-cost` | `{ Main: 0.9, Road: 1.0, Path: 1.15 }` | Routing cost per road class; lower is preferred | Restart | KNG-27 |
| `overlay-materials` | `[SNOW, "*_CARPET", "*_PRESSURE_PLATE", RAIL, POWERED_RAIL, LEAF_LITTER, PINK_PETALS]` | Thin blocks that may lie on a road; `*_SUFFIX` patterns allowed | Restart | KNG-27 |
| `seed-from-domains` | `true` | Domain locations within 8 blocks of a road seed the build | Restart | KNG-27 |
| `max-snap-distance` | `48` | A destination (and, without walk paths, the player) must be this close to a road; a closer target is walked to directly | Restart | KNG-27 |
| `snap-vertical-weight` / `destination-snap-vertical-weight` | `4` / `1` | How much a block of height counts when snapping the player / a destination | Restart | KNG-27 |
| `max-start-distance` | `96` | With walk paths: how far the player may be from a road | Restart | KNG-51 |
| `max-destination-distance` / `destination-walk-range` | `256` / `96` | With walk paths: how far a destination may be from a road, and within which range of the road's end the last leg is walked | Restart | KNG-51 |
| `trail-length` / `trail-period-ticks` / `trail-particle` / `trail-color` | `30` / `10` / `DUST` / `"#E8C66A"` | The particle trail | Restart | KNG-27 |
| `reroute-distance` / `reroute-after-ticks` | `8` / `40` | Reroute when the player strays this far for this long | Restart | KNG-27 |
| `arrive-distance` / `max-session-minutes` | `4` / `30` | Arrival distance; the longest navigation session | Restart | KNG-27 |
| `sprint-speed` | `5.6` | Blocks per second for the ETA | Restart | KNG-27 |
| `survey.sample-period-ticks` / `.cross-section-half-width` / `.breadcrumb-seed-spacing` | `4` / `7` / `32` | `/knk road survey` sampling | Restart | KNG-27 |
| `builder.tile-size` / `.tile-margin` / `.max-cells-per-tile` | `512` / `32` / `250000` | Graph build tiles | Restart | KNG-27 |
| `builder.snapshot-chunks-per-tick` | `4` | Chunks captured per tick on the main thread during a build (fewer under lag) | Restart | KNG-27 |
| `builder.junction-cluster-radius` / `.min-spur-length` / `.ambiguous-reach` | `3` / `4` / `3` | Junction merging, short spur removal, reach of ambiguous materials (cobblestone, planks) | Restart | KNG-27 |
| `builder.plaza-growth` | `2` | Cells a plaza reaches beyond its wide core | Restart | KNG-27 |
| `builder.locked-node-reach` | `8.0` | An admin-locked node absorbs rebuilt junctions and dead ends this close | Restart | KNG-27 |
| `builder.auto-plazas` | `true` | Wide road areas become plazas on their own; `false` = only designed plazas (`/knk road node plaza`) | Restart | KNG-27 |
| `builder.curated-tiles` | `true` | A rebuild of a built tile only proposes changes (`/knk road proposal`); `false` uploads directly (kill switch) | Restart | KNG-27 |
| `walk.enabled` | `true` | Walkable last-mile paths ([design § 9](../../specs/navigation/LAST_MILE_PATHFINDING.md)); `false` = straight lines (kill switch) | Restart | KNG-51 |
| `walk.max-expansions` / `.max-length-factor` / `.max-length` | `20000` / `1.75` / `144` | Search size and the longest path relative to the straight distance | Restart | KNG-51 |
| `walk.detour-allowance` / `.climb-allowance` | `48` / `5` | Blocks a path may always add; blocks per block of height | Restart | KNG-51 |
| `walk.max-drop` / `.drop-penalty` | `3` / `10` | Deepest drop (3 = no fall damage) and its extra cost per block | Restart | KNG-51 |
| `walk.capture-margin` / `.chunk-ttl-seconds` | `16` / `10` | Blocks captured around the box (loaded chunks only); how long a captured chunk is reused | Restart | KNG-51 |
| `walk.recompute-distance` / `.max-concurrent-searches` | `6` / `2` | Recompute after straying this far; searches at once, server-wide | Restart | KNG-51 |
| `walk.climbables` / `.wall-cost` | `[LADDER]` / `1.0` | Materials climbed like a ladder; extra cost beside a wall (0 = hug walls) | Restart | KNG-51 |

### 4.16 `currency`

The limits that matter (amounts, daily caps, who may send) are in the API's currency policy
([payments design § 3.6](../../specs/currency-payments/DESIGN.md)).

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `client-cooldown-seconds` | `3` | Pause between two `/pay` of one player before even asking the API | Restart | Currency phase 3 |
| `baltop-page-size` | `10` | Lines per `/baltop` page (at most 50) | Restart | Currency phase 3 |
| `transactions-page-size` | `8` | Lines per `/transactions` and `/knk user <player> history` page (at most 50) | Restart | Currency phase 3 |

### 4.17 `gates`

Gate mechanics are in the [gate structures admin guide](gate-structures-admin-guide.md). Under `gates:` the plugin
reads only the keys below. **`gates.cleaving` was removed by #259:** Cleaving's gate bonus, charged strike and
strike cooldown are combat values now (web app: Enchantment definitions → Cleaving → Combat values). Delete an old
block.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `here.radius` | `15` | `/gate toggle here`, `/gatedoor repair here`: doors within this many blocks | Restart | KNG-78 |
| `here.ambiguity` | `prompt` | Several in range: `prompt` lists them as clickable lines, `nearest` picks the closest | Restart | KNG-78 |
| `lookat.enabled` / `.max-distance` | `true` / `12` | Without a target, `/gate`/`/gatedoor` commands use the door you look at (then `here`) | Restart | KNG-79 |
| `state-sync-interval-seconds` | `120` | Safety-net push of every gate's state (also pushed after each animation and at shutdown). Also persists fire damage | Restart | — |
| `display-cleanup-interval-seconds` | `60` | Scan for orphaned or duplicate gate info displays | Restart | — |
| `safety.door-suffocation-damage` | `false` | Moving doors push entities out of the way; `true` adds vanilla suffocation damage on top (decision for review) | Restart | KNG-106 |
| `fire-duration-seconds` | `8` | How long a door block set alight burns | Restart | — |
| `fire-damage-per-tick` | `2.0` | HP damage per burning block per fire tick (several blocks stack) | Restart | — |
| `fire-tick-interval-seconds` | `1` | Seconds between fire ticks | Restart | — |
| `damage-cracks.enabled` | `true` | Vanilla breaking cracks in 10 stages that follow the gate's HP (visual only) | Restart | Gate damage visuals (2026-10-22) |
| `melee-damage.from-held-item` | `true` | A hit on a door does the held item's attack damage plus Sharpness (empty hand 1); `false` = a flat 10 | Restart | Gate damage visuals |
| `melee-damage.multiplier` | `1.0` | Scales that item damage | Restart | Gate damage visuals |
| `fire-aspect.ignite-chance-per-level` | `0.15` | Fire Aspect chance per level to set a hit door block alight (I 15 %, II 30 %). `0` = off. Defenders never burn their own gate | Restart | Siege playtest 2026-10-24 |
| `area-enchantment-radius-blocks` | `5.0` | Chaos and Flash Chaos hurt every gate with a door block within this many blocks of the user. Their gate **damage** is a combat value (#223) | Restart | #223 |
| `passthrough-instant-open-radius-blocks` | `1` | InstantOpen pass-through removes the door blocks this close to the player | Restart | — |
| `passthrough-instant-open-timeout-seconds` | `5` | They come back after this, if the player doesn't cross | Restart | — |
| `siege.defender-pass-through` | `true` | In a siege lockdown the owning alliance right-clicks to open and the gate closes by itself; `false` = right-clicks toggle | Restart | #154 |
| `siege.defender-pass-through-seconds` | `0` | How long it stays open; `0` = the gate's own pass-through duration | Restart | #154 |
| `rotationGapFill.rasterization-enabled` | `true` | Kill switch for filling diagonal-hinge rotation gates' sparse open footprint | Restart | — |
| `rotation.keyframes-enabled` | `true` | Drawbridge keyframes (KNG-193); `false` = the old per-block rotation | Restart | KNG-193 |
| `world-sync.health-check-interval-seconds` / `.health-check-batch-size` | `300` / `15` | Periodic re-check of a small batch of loaded gates against the database | Restart | — |

### 4.18 `messages`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `prefix` | `"&8[&6KnK&8] &r"` | Prefix of plugin messages | Restart | — |
| `account-created` / `account-linked` / `duplicate-account` | (text) | Account flow messages | Restart | — |
| `link-code-generated` | (text) | `/account link`. Placeholders `{code}`, `{minutes}`, `{url}`; lines with `{url}` are dropped while `web.public-url` is empty. Take the current default from the jar: an older file keeps its old text | Restart | KNG-208 |
| `link-code-entered-in-game` | (text) | `/account link <code>`: codes go on the website | Restart | KNG-208 |
| `invalid-link-code` | (text) | Invalid or expired code | Restart | — |
| `merge-complete` | (text) | `{coins}`, `{gems}`, `{exp}` | Restart | — |
| `currency.*` | `pay-sent`, `pay-received`, `pay-confirm`, `pay-insufficient`, `pay-cap`, `pay-new-account`, `pay-not-transferable`, `pay-self`, `pay-unknown`, `balance-self` | The most visible `/pay` and `/balance` texts. Any key left out uses the built-in text (`CurrencySettings.DEFAULT_MESSAGES`), so this list can be shorter | Restart | Currency phase 3 |

### 4.19 `enchant-books`

The v1 grade level cap (KNG-6, [GRADE_DROPCHANCE](../../specs/items/GRADE_DROPCHANCE.md)): an item of grade G takes
an enchantment only up to `maxLevel / divisor(G)`. The divisors are per-grade fields in the web app.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `grade-cap.enabled` | `true` | `false` = no cap | Restart | KNG-6 |
| `grade-cap.apply-to-custom` | `false` | v1 never capped custom enchantments; `true` caps them too | Restart | KNG-6 |
| `grade-cap.ungraded-stars` | `1` | Grade assumed for items without one (1 = most capped; 0 = uncapped) | Restart | KNG-6 |
| `grade-cap.bonus-level-chance` | `0.20` | Chance (0.0–1.0) of one bonus level, within the cap (v1's exact odds: 0.21) | Restart | KNG-6 |
| `grade-cap.grade-refresh-minutes` | `10` | How often the divisors are re-read from the API (at least 1) | Restart | KNG-6 |

### 4.20 `custom-enchantments`

Chance, cooldown, duration, level multiplier and the other numbers per enchantment are **combat values in the web
app** ([combat values guide](custom-enchantment-combat-values-admin-guide.md)). This section holds the runtime
switches and texts. The `messages` and `death-messages` keys are read every time they are used, so `/ce reload`
applies an edit; the other keys need a restart.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `disable-for-creative` | `false` | `true`: custom enchantments don't trigger in creative mode | Restart | — |
| `cooldown-message` | `"&c%seconds% seconds remaining"` | Shown when an ability is on cooldown. `%seconds%`; blank = this default | Restart | — |
| `tuning-refresh-minutes` | `5` | How often combat values are re-read from the API (at least 1; also at `/ce reload`). While the API is down the last values stay | Restart | #151 |
| `fair-chance.enabled` | `true` | On-hit chances (Poison, Wither, Freeze, Blindness, Confusion, Strength) are drawn from a marble bag per player and enchantment: hits and misses in the enchantment's ratio, drawn without putting back, refilled when empty. Same average, no long streaks. `false`: every hit is an independent roll, as before #476 | Restart | #476 |
| `fair-chance.min-bag-size` | `8` | Smallest bag (at least 1). The bag is the smallest size from here to `max-bag-size` in which the chance is a whole number of hits: 25 % = 2 hits in 8, 10 % = 1 in 10 | Restart | #476 |
| `fair-chance.max-bag-size` | `20` | Largest bag (at least `min-bag-size`). A chance that fits no size in whole hits (1 %, 33 %) uses this one and carries the fraction of a hit to the next bag. Larger = more room for streaks; `1` and `1` = independent rolls | Restart | #476 |
| `death-messages.enabled` | `true` | The death message of a player killed by Chaos or Flash Chaos names the ability, its user and item. Only a death inside the ability's own hit; other deaths keep vanilla's text; a siege match still shows none | `/ce reload` | #222 |
| `death-messages.default` | `"%victim% was killed with %enchantment% by %player% using %item%"` | The pattern. `%victim%`, `%player%` (the user), `%enchantment%`, `%item%` (shown like vanilla's `using [Sword]` with its hover; ` using %item%` is left out when unknown); `&` colour codes | `/ce reload` | #222 |
| `death-messages.overrides` | `{}` | Optional pattern per enchantment id, e.g. `chaos: "%victim% was blown apart by %player%'s %enchantment% using %item%"` (ids: `chaos`, `flash_chaos`) | `/ce reload` | #222 |
| `messages.cmd-help-header`, `cmd-unknown`, `cmd-no-permission`, `cmd-player-only`, `cmd-hand`, `cmd-hand-target`, `cmd-invalid-level` | (text) | `/ce` command texts | `/ce reload` | — |
| `messages.cmd-usage-add` / `-remove` / `-info` / `-cooldown` | (text) | Usage lines | `/ce reload` | — |
| `messages.cmd-unknown-enchantment`, `cmd-add-success`, `cmd-add-level`, `cmd-remove-success`, `cmd-player-not-found`, `cmd-clear` | (text) | Results. `%enchantment%`, `%lvl%`, `%player%` | `/ce reload` | — |
| `messages.cmd-reload` | (text) | `/ce reload` reply. Without the key the code's shorter `"&aPlugin configuration was reloaded."` is shown (#307) | `/ce reload` | — |
| `messages.cmd-info-header` / `cmd-info-line` / `cmd-info-none` | (text) | `/ce info`. Line: `%name%`, `%level%`, `%id%`, `%cooldown%` | `/ce reload` | — |
| `messages.cmd-info-tuning` | `"&8   chance %chance%%, duration %duration%s, cooldown %cooldownSetting%"` | `/ce info`: combat values at the item's level, under every enchantment | `/ce reload` | #151 |
| `messages.cmd-info-tuning-effects` | `"&8   effect level %effectLevel%, second effect %secondDuration%s"` | Only for an enchantment with an effect level or a second effect (Flash Chaos: Slowness level, Nausea) | `/ce reload` | #201 |
| `messages.cmd-info-tuning-gate` | `"&8   gate hits +%gateBonus%%, charged strike %strike%x, strike cooldown %strikeCooldown%"` | Only under Cleaving: gate bonus, charged strike multiplier and strike cooldown at the item's level. `%strikeCooldown%` is `Ns`, or `off` when the cooldown is 0 or turned off | `/ce reload` | #259 |
| `messages.cmd-info-tuning-area` | `"&8   area damage %areaDamage% within %damageRadius% blocks, gates %gateDamage%, knockback within %effectRadius% blocks"` | Only for Chaos and Flash Chaos: area damage, gate damage and radii at the item's level | `/ce reload` | #223 |
| `messages.ench-use` | `"&cYou cannot use %enchantment%."` | `/ce add` refusal when the sender may not use that enchantment | `/ce reload` | — |

In `config.yml` at `121030f` the `# PandiO/knk-workspace#223` comment sits above `cmd-info-tuning-gate`, not above
`cmd-info-tuning-area`. The keys are right; the comment move is tracked in
[#307](https://github.com/PandiO/knk-workspace/issues/307).

### 4.21 `lootboxes`

Areas, limits, odds, the daily cap and announcements are set in the web app (`/admin/lootboxes`,
[design § 3.4](../../specs/lootboxes/DESIGN.md)). This section is how this server places, shows and opens boxes.
Every key applies after `/knk lootbox reload`; a key left out uses the built-in default. Web-app changes arrive at the
next `runtime-refresh-seconds`, or at once with `realtime.enabled: true` ([economy admin guide § 4](economy-admin-guide.md#4-lootboxes)).

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `true` | Lootboxes on this server | `/knk lootbox reload` | Lootboxes |
| `server-id` | `"default"` | Sent with every spawn so the drop log shows the server | `/knk lootbox reload` | Lootboxes |
| `runtime-refresh-seconds` | `60` | Runtime config and active boxes re-read from the API | `/knk lootbox reload` | Lootboxes |
| `scheduler-tick-seconds` | `20` | How often each area is considered (its own interval still applies) | `/knk lootbox reload` | Lootboxes |
| `claim-max-distance` | `5` | Blocks between the player and the box | `/knk lootbox reload` | Lootboxes |
| `full-inventory` | `refuse` | `refuse` (no claim with a full inventory) or `drop-owned` (claim, drop leftovers owner-locked) | `/knk lootbox reload` | Lootboxes |
| `staff-mode-can-claim` | `false` | Players in `/staffmode` or `/ownermode` can't open boxes | `/knk lootbox reload` | Lootboxes |
| `surface.max-attempts-per-tick` | `4` | Random columns tried per area per try | `/knk lootbox reload` | Lootboxes |
| `surface.forbidden-ground` | `[WATER, LAVA, MAGMA_BLOCK, CACTUS, POWDER_SNOW]` | Never placed on these | `/knk lootbox reload` | Lootboxes |
| `display.model` | `token` | `token` (the token item) or `type` (the type's display material from the web app) | `/knk lootbox reload` | Lootboxes |
| `display.label` / `.rotate` | `true` / `true` | Floating label; rotation | `/knk lootbox reload` | Lootboxes |
| `display.particles-radius` | `15` | Gold particles and a chime every 4 s to players this close (0 = off) | `/knk lootbox reload` | Lootboxes |
| `display.grade-colors` | `"1"`–`"10"`: `&9 &9 &b &b &d &6 &6 &c &c &4` | Label colour per grade | `/knk lootbox reload` | Lootboxes |
| `token.material` | `ENDER_CHEST` | Material of token items. An item is a token only by its tag; pick something that isn't a fuel or crafting ingredient | `/knk lootbox reload` | Lootboxes |
| `opening.style` | `wheel` | `wheel` (a slowing reel) or `instant` | `/knk lootbox reload` | Lootboxes |
| `opening.reel-steps` / `.slowest-step-ticks` / `.show-result-ticks` | `32` / `8` / `50` | Reel length, last step delay, how long the result stays | `/knk lootbox reload` | Lootboxes |
| `opening.public-effects` | `true` | Particles and sounds others nearby see and hear | `/knk lootbox reload` | Lootboxes |

### 4.22 `worlds`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `load` | `[]` | Extra worlds loaded at startup, next to the gameplay world. Each entry: `name` (folder; letters, digits, `_`, `-`), `environment` (`normal`, `nether`, `the_end`), `generator` (`default`, `flat`, `void`; keep it the same), `create` (default `false`), `required` (default `true`: while missing, only operators may join). Example: `- { name: hub, environment: normal, generator: void, create: true, required: true }`. KnK never deletes or regenerates a world | Restart | KNG-114 |

### 4.23 `regions`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `temp-retention.days` | `14` | The daily cleanup deletes an unused `tempregion_worldtask_*` region and an orphaned domain sub-region this many days later (at least 1) | Restart | KNG-103, KNG-258 |
| `global.protection` | `true` | Where only WorldGuard's `__global__` applies, default players can't build, use crafting blocks or break decorations, and explosions break nothing. Doors, gates and storage stay usable. `knk.region.bypass` and ops pass | Any reload | QOL hotfix 2026-10-25 |
| `global.crafting-blocks` | (16 materials, `CRAFTING_TABLE` … `FLETCHING_TABLE`) | The blocked crafting blocks; empty = the built-in list | Restart | QOL hotfix 2026-10-25 |
| `effect-damage.enabled` | `true` | Players inside a domain take no damage from the causes below, unless the region flag `knk-effect-damage` is `allow`, or it is unset and `pvp` is `allow`. Siege members in a match keep the siege's rules | Any reload | #162 |
| `effect-damage.causes` | `[FIRE, FIRE_TICK, LAVA, CAMPFIRE, HOT_FLOOR, POISON, WITHER, MAGIC, DRAGON_BREATH, FREEZE]` | Bukkit `DamageCause` names; empty = this list | Restart | #162 |
| `managed.startup-repair.enabled` | `true` | Re-checks parent, priority and category flags of every Town, District, Structure and Gate region at startup ([managed regions](../../architecture/managed-worldguard-regions.md)) | Restart | — |
| `managed.startup-repair.delay-ticks` / `.attempts` / `.retry-delay-seconds` / `.page-size` | `100` / `3` / `30` / `100` | Wait for WorldGuard, retries while the API starts, rows per request | Restart | — |
| `managed.resource-production-block-break` | `false` | `true` lets anyone break any block in resource production regions (v1 limited it to logs). Leave off until a block filter exists | Restart | — |
| `managed.manage-global-region` | `false` | Apply v1's `__global__` flags. Changes what is buildable across the world | Restart | — |
| `managed.overrides` | `{}` | Per region id: `kind`, `priority`, `flags` (flags only set while absent). Kinds: `town`, `district`, `structure`, `house`, `property`, `resource_production`, `room`, `gate`, `arena`, `battleground` | Restart | — |
| `managed.extra-regions` | `[]` | Regions with no domain (arenas, battlegrounds) that still get a parent, priority and flags: `{ region, kind, parent }` | Restart | — |
| `access.sync.enabled` | `true` | Writes each domain's AllowEntry/AllowExit as WorldGuard flags, enforced also while the API is down (KNG-56) | Restart | KNG-56 |
| `access.sync.delay-ticks` / `.attempts` / `.retry-delay-seconds` | `100` / `3` / `30` | First sync after enable; retries | Restart | KNG-56 |
| `access.sync.interval-minutes` | `5` | Re-sync from the API (0 = only at startup, repair and new regions) | Restart | KNG-56 |
| `access.message-interval-ms` | `2000` | A player is told "You are not allowed to …" at most this often | Restart | KNG-56 |
| `access.chat-quiet-period-ms` | `10000` | The first refusal of an episode also goes to chat (0 = every one) | Restart | KNG-74 |
| `access.action-bar-hold-ms` | `3000` | The `/navigate` arrow isn't drawn over a refusal for this long | Restart | KNG-74 |
| `access.load-guard.enabled` / `.max-refusals-per-second` / `.window-seconds` / `.escalation-window-seconds` | `true` / `20` / `3` / `60` | A refusal rate no honest player reaches: first a teleport to spawn, then a kick if it repeats within the escalation window | Restart | — |

### 4.24 `command-visibility`

Only the `/` suggestions change; every command still checks its own permission. Ops see everything.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `hide-namespaced` | `true` | Hide every `plugin:command` form | Restart | KNG-107 |
| `hide-other-plugins-without-permission` | `true` | Hide other plugins' commands the player can't run or that declare no permission | Restart | KNG-107 |
| `always-show` | `[]` | Labels never hidden by the rule above, e.g. `[rules, discord]` | Restart | KNG-107 |

### 4.25 `offline-cache`

The last account, freeze, staff/owner mode and permission answers, kept in one file so they still apply after a
restart while the API is down. Used only when the API can't be asked; holds no email or balances.

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `enabled` | `true` | `false` logs a warning: permissions, freeze and modes don't survive an API outage | Restart | KNG-58 |
| `file` | `offline-security.json` | In the plugin folder | Restart | KNG-58 |
| `identity-max-age-days` | `30` | An account unconfirmed for longer is forgotten (at most 30: the GDPR erasure deadline) | Restart | KNG-58 |
| `permission-max-age-hours` | `72` | An older permission answer counts as "no" | Restart | KNG-58 |
| `verify-after-hours` | `6` | Hourly, accounts not confirmed for this long are re-checked (an erased account is deleted from the file) | Restart | KNG-58 |
| `flush-seconds` | `10` | How often changes are written | Restart | KNG-58 |

### 4.26 `cache`

| Key | Default | What it does, safe values | Applies | Added by |
|---|---|---|---|---|
| `ttl-seconds` | `60` | Global time-to-live of cached API responses. Used for most entities (see below) | Restart | — |
| `entities.<entity>.*` | see below | Per entity: `ttl-minutes` (or `ttl-seconds`), `max-ttl-minutes`, `default-policy` (`CACHE_ONLY`, `CACHE_FIRST`, `API_ONLY`, `API_THEN_CACHE_REFRESH`, `STALE_OK`), `allow-stale`, `retry-attempts`, `retry-backoff-ms` | Restart | — |
| `entities.permissions.resolve-from-effective-set` | `true` | Answer permission checks from each player's whole permission set (one call per player per `ttl-seconds`); `false` = one call per node | Restart | KNG-107 |
| `entities.permissions.effective-set-stale-seconds` | `90` | Help, Tab and `/` use the last set this long past its TTL while it reloads; running a command always waits for a fresh set | Restart | KNG-107 |

Entity defaults (`ttl` / `max-ttl`, all `CACHE_FIRST`, `allow-stale: true`, 3 retries, 100 ms backoff unless noted):
`users` 15/60 min; `towns`, `districts`, `domains`, `domainCatalog` 30/240 min; `structures`, `locations` 20/120 min;
`streets`, `minecraftMaterials` 60/480 min; `enchantments`, `itemBlueprints`, `kits`, `grades`, `tags`, `menus`
20/120 min; `siege` 30/240 min with 200 ms backoff; `health` 30/120 **s**, `API_ONLY`, no stale, 2 retries, 50 ms
(KNG-115: a cached "healthy" must not stand in for "reachable now"); `permissions` 30/120 **s**.

The file's own comment (KNG-262) says that for most entities `ttl-minutes` isn't used and the global
`ttl-seconds` applies; `itemBlueprints` does use its own TTL. A web-app edit shows in game after at most that TTL,
or at once after `/knk cache refresh`. Kits are not among the caches `/knk cache refresh` drops: a kit edit shows in the
kits menu after `ttl-seconds`, or at once with `realtime.enabled: true`; claims always read the API.

## 5. Maintaining this page

- A change that adds, renames or removes a key, or changes a default, updates § 2.1 and the section's table in the
  same PR, and lists the YAML to paste in the PR's deploy notes and the changelog's **Admin steps**
  ([documentation maintenance](../developer/DOCUMENTATION_MAINTENANCE.md)).
- Re-check the **Applies** column against the code when a key's reader moves: `ConfigLoader` and code that reads
  `getConfig()` once are Restart; `EnchantmentConfigManager` and `() -> getConfig()…` suppliers are reload-safe.
- Record the knk-plugin commit you checked in the header.

## Changes

1. 2026-11-10: first version, PandiO/knk-workspace#295; checked against knk-plugin `main` `121030f`
- 2026-11-14: § 2.1 and § 4.20 `custom-enchantments.fair-chance` (PandiO/knk-workspace#476), against knk-plugin `claude/eager-cannon-h8dtum` `a91d65e`; not merged
