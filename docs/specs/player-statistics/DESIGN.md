# Player statistics — working design

**Status:** Finalized 2026-10-03 by chain link 1 — the "Finalized design (link 1)" section below is binding for implementation together with [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md). Developer decisions D1-D13 and "Agreed" paragraphs are the developer's; link-1 defaults are numbered `L1-n` and flagged for review in the progress report. Evidence: [source audit](../../reports/2026-10-03-player-statistics-source-audit.md).
**Last updated:** 2026-10-10 (trunk alignment D21-D23)
**Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34/design-player-statistics-provenance-and-world-analytics), [KNG-14](https://linear.app/kngpandi/issue/KNG-14/gameplay-statistics-counters-v2-userstatistics-for-user-statistics), [KNG-23](https://linear.app/kngpandi/issue/KNG-23)

This living note records decisions from the developer conversation. It does not assert that all described fields are already stored or displayed in V3. Precedence: (1) "Developer decisions 2026-10-03", (2) the "Finalized design (link 1)" section, (3) the older discussion sections further down, which are kept as rationale. Where an older section still says "open" or "to be decided", section (2) settles it.

## Developer decisions 2026-10-03 (binding)

Answers given by the developer to the open questions, in the order asked. The developer handed KNG-34 over to a Claude Code implementation chain (one feature branch per repo, `claude/kind-dijkstra-y9d279`) and will test once the whole feature is implemented.

| # | Question | Decision |
|---|---|---|
| D1 | Draws, aborted matches, leaving early | **Draws are recorded as draws**, separate from wins and losses. **Leaving a match early counts as a loss.** Aborted matches (server/admin abort, no result): not a win, loss or draw — chain default, flagged for review. |
| D2 | Killstreak | **Build the killstreak mechanic** needed for "highest killstreak". |
| D3 | Highest fall | Only falls the player **survives**. |
| D4 | Logins | Every successful join counts, **reconnects included**. |
| D5 | Periods | Daily/weekly/monthly use the **server timezone** for now; weeks start on **Monday**. A per-player timezone setting is a future extension — keep the period boundary computation behind one function so it can take a player timezone later. |
| D6 | Backfill | **No backfill**: lifetime totals start when instrumentation starts. Only facts V3 already stores authoritatively (e.g. the existing ledger, Siege match history, discoveries, first join if stored) are used as-is; nothing is reconstructed. |
| D7 | Leaderboards | Developer: "whatever you recommend; not too much to include it now". **Included now** — see "Leaderboards (recommendation adopted 2026-10-03)" below. |
| D8 | Per-game-mode visibility | **Yes**: visibility can be set per game context for statistics broken down by context, in addition to the metric-level setting. |
| D9 | Title corrections / non-XP title changes | **Every title change is caused by XP, period.** Title history is derived from XP changes; there is no separate administrative title-change path to model. |
| D10 | Movement heatmaps | Can be a follow-up, but **high priority** — scheduled as the last implementation link of this chain. |
| D11 | Menu funnels, world/domain interaction analytics | Same as D10 — last link of the chain. |
| D12 | Diagnostic timeline access and deletion | **Only the owner** can see it. Use **dedicated permission nodes** that are not granted to regular staff. On a player's data-deletion request, **delete within the GDPR-mandated timeframe** (GDPR Art. 12(3): without undue delay and at the latest within one month of the request). |
| D13 | XP provenance (KNG-23) | **Record XP changes in the existing coin/gem ledger** rather than building a separate XP log. Chain-start scan (2026-10-03): knk-web-api `Enums/Currency.cs` already has `Experience = 2` and every known XP write path posts through `ICurrencyService`; link 1/2 verify full coverage and close any gap. |
| — | AFK mode | Not answered. Chain default: link 1 analyses V1/V2 AFK behaviour; implement automatic inactivity detection (5 minutes, configurable) plus an explicit AFK toggle only if V1 had one, keeping the rule configurable and flagged for review. |

### Review follow-up decisions 2026-10-03 (binding)

Given by the developer on the chain's "decisions to review" after all seven links were done. Implemented the same day on
`claude/kind-dijkstra-y9d279` (knk-web-api `00409c2`, `fdf9c13`; knk-web-app `089039f`).

| # | Topic | Decision |
|---|---|---|
| D14 | GDPR deletion trigger | Deletion happens **only when the player or staff initiate it** — never automatically for inactive players. **Players request on the web app** and confirm through an **email link**; a **5-day grace period** follows the confirmation, during which the player can cancel; only then does the deletion run. **Staff file the same request for a player without the email confirmation** (grace period still applies). §F.14. |
| D15 | Scope of "delete" | "If a player decides to delete, that should really mean all is deleted": besides the statistics scope, also delete **private-message logs, link codes, permission grants, group memberships and audit rows about the player**. Ledger and Siege match rows stay on the anonymous account (they are other players' history and accounting records). The UUID is cleared, so a returning player starts a fresh account. |
| D16 | Rebuild after erasure (L6-6) | **Rebuilds skip erased accounts**: an erased account never gets statistics again. |
| D17 | Ledger backfill (L2-12) | Agreed: past activity in the existing ledger is projected (economy, XP, title history). |
| D18 | "Everyone" visibility (L1-3) | "Everyone" means **everyone with a player account** (any signed-in viewer); signed-out visitors keep seeing only the always-public fields. Unchanged from L1-3. |
| D19 | Staff statistics view (L1-20) | Agreed: `knk.admin.statistics.view` sees all of a player's statistics. |
| D20 | Economy buckets (L1-5/L1-6) | **Include every way of gaining or losing** coins, gems and XP in earned/spent/xp_gained: transfers, staff adjustments, signup grant, merges and premium top-ups too. §F.5. |
| — | Others | Time zone `Europe/Amsterdam` is the server zone (confirmed); retention defaults §F.15 agreed; Siege leaver payload (L4-2) and AFK salary (L1-2) accepted for now. |

### Trunk alignment decisions 2026-10-10 (binding)

After merging the trunks into the feature branches (progress report, "Trunk merge 2026-10-10"), the developer chose
three of the suggested alignment changes. Implemented on knk-web-api `claude/kind-dijkstra-y9d279` (`9c3a11a`,
`dc352d4`, `66c01cb`).

| # | Topic | Decision |
|---|---|---|
| D21 | Discovery counts | Count only domains whose discovery type is enabled (after per-domain overrides), like the player's `/discoveries` total since trunk `e2d16d1`: discovery counts, the named-discoveries list and the discoveries leaderboard (shared helper `DiscoveryEnabledDomains`). Deleted domains don't count; Total = Towns + Districts + Structures. |
| D22 | Staff groups | Seed `knk.admin.statistics.view` into **Moderator** and **Admin**, and `knk.admin.privacy.request` into **Admin** (migration `SeedStatisticsStaffNodes`, after KNG-80's group seed). Owner nodes stay unseeded. |
| D23 | Road-builder names | Data deletion clears the player's name from `road_tile_proposals.CreatedBy` (KNG-27); the proposals stay. Reported as `road_tile_proposals.created_by`. |

Deferred until after the smoke test and merge: the other suggestions (road-tile read failures in diagnostics,
navigation/domain-access telemetry, renamed world-task regions in world analytics, async command correlation).

### Leaderboards (recommendation adopted 2026-10-03)

- **Periods:** weekly, monthly and lifetime (D5 boundaries). No rewards in this scope.
- **Metrics:** only metrics that are hard to farm and meaningful: active playtime (never AFK time), XP gained, PvP kills, PvE kills, wins per minigame, objectives captured, gate-door damage, distance per mode, discoveries count, highest killstreak. Not ranked: deaths, damage received, logins (farmable by reconnecting), AFK time. Current coin/gem balances are left to `/baltop` (KNG-21), not duplicated.
- **Eligibility:** an always-public metric always ranks. A configurable metric ranks a player only when that metric (and, for a per-context board, that context — D8) is set to **everyone**. Friends-only and nobody never appear. Changing visibility removes the player at the next refresh.
- **Ties:** equal values share a rank (1, 1, 3); display order among ties by who reached the value first.
- **Refresh:** precomputed snapshots on a bounded interval (default 5 minutes, configurable), never computed from raw history on a menu open. Top 10 shown plus the viewer's own position.
- **Abuse guardrails (reversible defaults, flagged):** repeat PvP kills of the same victim count toward leaderboards at most 3 times per victim per day (still counted in the player's own statistics); the owner can exclude a player from leaderboards.

## Finalized design (link 1, 2026-10-03)

Source-grounded completion of the decisions above. Every item traces to the [source audit](../../reports/2026-10-03-player-statistics-source-audit.md)
(cited there by file:line). Data shapes, routes, class names and config keys live in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md);
this section fixes **what** is recorded and shown. Link-1 defaults are marked **L1-n** (the full list with reasons is §F.16).

### F.0 Principles

1. **One source of truth per fact.** Authoritative stores stay authoritative: the currency ledger (coins, gems, XP; D13),
   Siege match tables (match outcomes, in-match kills/deaths/streak/captures), discoveries. KNG-34 adds **read models**
   (daily rows, lifetime totals, title changes) that are *projected* from those stores by idempotent background projectors
   with a rebuild path, never counted a second time by the plugin.
2. **New facts** (sessions, AFK, combat outside the match tables, damage, arrows, headshots, gate damage, distance, falls)
   are recorded by the plugin, buffered in memory, flushed in batches off the main thread, spooled on failure and ingested
   idempotently (batch id).
3. **Calendar views derive from daily rows**; lifetime totals are kept alongside for cheap reads and leaderboards.
4. **Visibility is enforced in the API** for every read (web, plugin, leaderboard). Friends-only fails closed until KNG-35.
5. Every hook has a kill switch whose `false` reproduces today's behaviour.

### F.1 Metric catalogue

Metric keys are stable identifiers (API catalogue `StatisticsCatalog`, plugin `StatisticsMetric`). **Context** is the
game context at the moment the fact happened: `open_world` (default), `siege`; future `arena`, `dungeon`,
`siege_survival` are added as new context keys without schema change. "Contextual" metrics are stored and viewable per
context plus a total across contexts; non-contextual metrics are stored with an empty context.

Aggregation: **sum** (counters, durations, distances) or **max** (records). Periods (§F.10): day, week, month,
lifetime for every metric; for max metrics a period shows the highest value reached within that period.

| Metric key(s) | Player-facing name | Definition | Source | Ctx | Visibility | Leaderboard |
|---|---|---|---|---|---|---|
| `first_joined` (derived) | First joined the server | Earliest Minecraft join across the player's merged identities (§F.3) | profile + `users.CreatedAt` | — | always public | no |
| `active_playtime` | Active playtime | Online seconds not classified AFK (§F.2) | plugin sessions | — | always public | **yes** |
| `afk_time` | AFK time | Online seconds classified AFK | plugin sessions | — | always public | no |
| `logins` | Logins | Successful joins (`UserDataLoadedEvent` with a user id), reconnects included (D4) | plugin sessions | — | `logins` | no (farmable) |
| `pvp_kills` | Player kills | Kills of another player (the victim's killer is the player) | plugin; **siege: match tables** | yes | `pvp_kills` | **yes** (per context + total; repeat-victim cap §F.11) |
| `pve_kills` | Creature kills | Kills of non-player living entities, excluding armour stands and the spawn reasons in §F.7 | plugin | yes | `pve_kills` | **yes** (per context + total) |
| `deaths` | Deaths | All deaths of the player | plugin; **siege: match tables** | stored per ctx, **shown as total only** | `deaths` | no |
| `deaths_by_cause.player` / `.mob` / `.environment` | — (internal) | Cause classification of every death, all contexts (§F.7) | plugin | yes | internal (never returned to players) | no |
| `damage_dealt.player` / `.mob` | Damage dealt to players / to creatures | Effective damage dealt, capped at the victim's remaining health+absorption (L1-9) | plugin | yes | `damage_dealt` | no |
| `damage_received.player` / `.mob` | Damage received from players / from creatures | Final damage received from an entity (player or projectile shooter / mob) | plugin | yes | `damage_received` | no |
| `gate_damage` | Gate-door damage | Effective gate HP lost credited to the player, incl. attributed fire (§F.8) | plugin | yes | `gate_damage` | **yes** (total) |
| `arrows_fired` | Arrows fired | Arrows shot by bow/crossbow (`EntityShootBowEvent`, arrow projectiles; tridents excluded) | plugin | yes | `arrows_fired` | no |
| `headshots` | Headshots | Projectile hits on a player satisfying `SiegeCombatRules.isHeadshot` where the context applies a headshot multiplier (today: Siege lobbies with multiplier > 1) | plugin | yes | `headshots` | no |
| `highest_killstreak` (max) | Highest killstreak | Most PvP kills without dying (§F.7) | plugin (open world); **siege: match tables** | yes | `highest_killstreak` | **yes** (per context + overall max) |
| `wins` / `losses` / `draws` | Wins / losses / draws | Match results per minigame (§F.6) | **match tables** | yes | `wins` / `losses` / `draws` | `wins` **yes** (per minigame) |
| `objectives_captured` | Objectives captured | Objective captures credited to the player | **match tables** (siege) | yes | `objectives_captured` | **yes** (per context) |
| `distance.foot` / `.flying` / `.vehicle` | Distance on foot / flying / in a vehicle | Horizontal+vertical Euclidean distance of eligible movement segments (§F.9); swimming counts as foot | plugin | — | `distance.foot` / `distance.flying` / `distance.vehicle` | **yes** (per mode) |
| `distance.swim` | — (internal) | Subset of foot distance spent swimming, kept for later reclassification | plugin | — | internal | no |
| `highest_fall` (max) | Highest survived fall | Fall distance (blocks, 1 decimal) of a fall that dealt damage and that the player survived (D3) | plugin | — | `highest_fall` | no |
| `xp_gained` | XP gained | Positive XP from earning reason codes, net of their reversals (§F.5) | **ledger projection** | — | always public (XP is public) — L1-21 | **yes** |
| `coins_earned` / `coins_spent` / `gems_earned` / `gems_spent` | Economy: earned / spent | Ledger legs classified per §F.5 | **ledger projection** | — | one setting: `economy` | no (balances stay on `/baltop`) |
| `discoveries` (derived) | Discoveries | Count of `user_domain_discoveries` (with Town/District/Structure breakdown) | discoveries table | — | `discoveries.counts` | **yes** |
| discovery list (derived) | Discovered places | Named discoveries with timestamps | discoveries table | — | `discoveries.list` | no |
| title history (derived) | Title history | Chronological promotions/demotions with from/to title and time; no reason shown | **projected from XP ledger legs** (D9) | — | `title_history` | no |

**Visibility setting keys** (the values players choose; default **nobody**): `logins`, `pvp_kills`, `pve_kills`,
`deaths`, `damage_dealt`, `damage_received`, `gate_damage`, `arrows_fired`, `headshots`, `highest_killstreak`, `wins`,
`losses`, `draws`, `objectives_captured`, `distance.foot`, `distance.flying`, `distance.vehicle`, `highest_fall`,
`economy`, `discoveries.counts`, `discoveries.list`, `title_history`. **Contextual settings** (per-context overrides
allowed, D8): `pvp_kills`, `pve_kills`, `damage_dealt`, `damage_received`, `gate_damage`, `arrows_fired`, `headshots`,
`highest_killstreak`, `wins`, `losses`, `draws`, `objectives_captured`.

**Menu groups** (for the group action): *Activity* (`logins`), *Combat* (`pvp_kills`, `pve_kills`, `deaths`,
`damage_dealt`, `damage_received`, `arrows_fired`, `headshots`, `highest_killstreak`), *Minigames* (`wins`, `losses`,
`draws`, `objectives_captured`, `gate_damage`), *Exploration* (`distance.*`, `highest_fall`, `discoveries.counts`,
`discoveries.list`), *Progression* (`title_history`, `economy`).

**Parked** (not recorded): V1 blocks broken, fish caught, bandit kills (dead or broken in V1, audit §3).

### F.2 AFK rule (L1-1)

V1 had an explicit `/afk` toggle plus auto-AFK after 300 s; V2 had nothing (audit §4). V3:

- **Automatic:** a player becomes AFK after `statistics.afk.idle-seconds` (default **300**) without an activity signal.
- **Explicit:** `/afk` toggles AFK immediately (kill switch `statistics.afk.command-enabled`).
- **Activity signals** (reset the idle timer and end AFK, also manual AFK): a change of look direction (yaw or pitch ≥ 1°),
  horizontal movement **while not in a vehicle and not in water/bubble columns**, chat, a command, block break/place,
  interaction with a block or entity, an inventory click, attacking, toggling sneak/sprint.
- **Not activity** (anti-AFK-pool): movement while in a vehicle, in water, pushed by pistons or flowing water, taking
  damage (unlike V1), teleports.
- **Retroactive classification:** the idle window that leads to AFK is AFK time. Seconds since the last activity are held
  as *pending* until classified — activity within the threshold turns them into active time, reaching the threshold turns
  them into AFK time. On quit, pending time counts as active (the player was not yet AFK). Manual `/afk` classifies
  from the moment of the command.
- **Effects:** a private message on entering/leaving AFK and a tab-list marker (`statistics.afk.tab-list-marker`, text
  `statistics.afk.marker-text`, default `&7[AFK]`, appended to the player-list name and restored afterwards). **Not**
  carried over from V1: Siege removal, Zz armour stands, shopkeeper upsell, kicks.
- **Statistics while AFK:** distance is not counted; combat and other facts still count (they are real events).
- **Salary is unchanged (L1-2).** The API pays "hours since last payout", so an AFK rule for salary needs an API contract
  change; recorded as a follow-up for the developer, not built in this chain.
- Disconnect/crash: the plugin flushes accrued time every flush interval (default 60 s); a crash loses at most one
  interval. The API closes sessions with no heartbeat for `Statistics:SessionTimeoutMinutes` (default 5) at their last
  heartbeat (end reason `Timeout`); server stop ends sessions with reason `ServerStop`.

### F.3 Sessions, logins, first join (L1-15)

- A **session** starts at `UserDataLoadedEvent` with a known user id and ends at quit/server stop; reconnects start a new
  session and count as a login (D4). Joins whose user id is unknown (API down) are tracked under the UUID and resolved
  later, as discovery does.
- Durations are sent as `[from, to)` intervals classified active/AFK; the API splits them across day boundaries with the
  period function (§F.10), so midnight-spanning sessions are allocated correctly.
- **First joined** = the earliest of: `users.CreatedAt` for accounts with `AccountCreatedVia = MinecraftServer` (the
  account is auto-created on the first Minecraft join — an existing authoritative fact, D6), and the first recorded
  session; computed across the player's merged identities. Web-first accounts get a first-join value from their first
  session after instrumentation (their link time was never stored — not reconstructed). Never joined → no value.

### F.4 Visibility (L1-3, L1-4)

- Values: **nobody** (default, also when no row exists), **friends** (fails closed — treated as nobody until KNG-35
  supplies relationships), **everyone**.
- **Viewer classes:** the player themselves and staff holding `knk.admin.statistics.view` see everything they can read
  today (staff moderation view; L1-20); a **signed-in viewer** (web JWT, or the plugin acting for an online player via
  `X-Acting-User-Id`) sees always-public fields plus every metric whose effective visibility is *everyone*; an
  **anonymous** web visitor sees only the always-public fields (L1-3).
- **Per-context precedence (D8):** a context-level row, if present, decides that context; otherwise the metric-level row
  decides; otherwise nobody. A **total across contexts** is visible only when the metric-level value and every
  context-level override are *everyone* (otherwise a hidden context would leak through the total).
- **Group action:** a bulk update of the currently listed settings in a group to one value, previewed as
  `metric: current → proposed`, confirmed, applied as **one atomic update** with optimistic concurrency (each change
  carries the expected current value; any mismatch rejects the whole update). Metric-level rows only; existing
  context overrides are listed in the preview and left untouched. New metrics default to nobody.
- The same stored values are used by Minecraft reads, web reads and leaderboard eligibility.

### F.5 Economy and XP from the ledger (L1-5, L1-6; revised by D20)

**D20 (2026-10-03): every gain counts as earned and every loss as spent**, whatever the reason code — gameplay rewards
and costs, `/pay` transfers (received = earned, sent = spent), staff grants/takes/sets, the signup grant, account merges
(`MERGE_CARRYOVER` earned, `MERGE_FORFEIT` spent) and premium top-ups. The sign of the user leg decides.

- **Reversals** are corrections, not new gains or losses: a `REVERSAL` stays in the bucket of the original transaction it
  ultimately undoes (a reversed grant lowers *earned*, a reversed spend lowers *spent*, a reversal of a reversal raises it
  again), on the reversal's date. The projector follows the reversal chain to know its depth.
- `xp_gained` = every XP gain (staff XP grants included), net of reversed gains. XP losses are no statistic.
- Because merged accounts are summed when read (L1-16), a merge shows up as the forfeit (spent) of the secondary plus the
  carryover (earned) of the primary.
- Periods are allocated by the transaction's `CreatedAt`.

### F.6 Match results (D1, L1-7, L1-8)

From `siege_matches` / `siege_match_participants` / `siege_teams` (Siege is the only minigame today; the projector is
written per minigame so Arena/Dungeons add a projector, not columns):

- **Completed, `WinningAllianceGroup` set:** participant present at the end (`LeftAt` null or `LeftAt == EndedAt`) whose
  team's `AllianceGroup` equals the winner → **win**, otherwise → **loss**.
- **Completed, `WinningAllianceGroup` null:** present participants → **draw**.
- **Left early** (`LeftAt < EndedAt`) → **loss** (D1), whatever the outcome.
- **Aborted:** no win, loss or draw (D1 chain default); in-match kills/deaths/captures of aborted matches are still
  counted (they happened).
- Team row deleted (`SiegeTeamId` null): no result for that participant (logged).
- A player who left and rejoined keeps the left marker (API behaviour) → counted as a loss; flagged.
- In-match `Kills` → `pvp_kills@siege`, `Deaths` → `deaths@siege`, `HighestKillStreak` → `highest_killstreak@siege`
  (max), `Captures` → `objectives_captured@siege`. All projected onto the **day the match ended**.
- The plugin does **not** send `pvp_kills`/`deaths`/`highest_killstreak` for a kill/death where the victim is a member of a
  running Siege match (the roster counts them); the API rejects plugin entries for these projection-owned
  (metric, context) pairs as a second guard.
- **Leaver gap fix (link 4):** the plugin reports departed members' kills/deaths/streak/captures in the completion
  payload so their stats are not lost; the API keeps their `LeftAt`, so rewards are unchanged (present-at-end only).

### F.7 Combat attribution (D2, L1-9 … L1-11)

- **Kill credit:** `Player#getKiller()` for player victims and `LivingEntity#getKiller()` for creatures (Bukkit's
  last-player-damager rule). Self-kills give no kill.
- **Death cause:** killer present → `player`; else last damage by an entity (mob or a mob's projectile) → `mob`; else
  `environment` (fall, lava, drowning, void, fire, …).
- **PvE exclusions** (`statistics.combat.pve-excluded-spawn-reasons`, default `SPAWNER`, `SPAWNER_EGG`, `BREEDING`,
  `EGG`, `DISPENSE_EGG`): farmed creatures are not counted (L1-10).
- **Damage:** observed at MONITOR with `ignoreCancelled`; dealt damage uses `getFinalDamage()` capped at the victim's
  health+absorption before the hit; synthetic `CUSTOM` damage events (Chaos enchant procs) are **not** counted by default
  (`statistics.combat.count-custom-damage: false`) to avoid double counting (L1-9). Precise values are stored; only the
  displayed total is rounded.
- **Killstreak mechanic (D2):** open world — consecutive PvP kills without dying, reset on any death and on quit (L1-11),
  recorded as the running max; Siege — the existing per-match roster streak, projected from the match tables.
  Streak announcements are unchanged (Siege) / not added (open world).

### F.8 Gate-door damage (L1-12)

- Counted value = **effective HP lost** (`old - max(0, old - amount)`), capped by remaining HP; never raw attack strength.
- **Direct damage:** credited to the attacking player (a projectile's shooter; a `TNTPrimed`'s source player for
  explosions; otherwise unattributed).
- **Fire:** each burning block records its igniter (player UUID + user id at ignition); a fire tick's effective loss is
  split over the burning blocks and credited per igniter; unattributed blocks' share is credited to nobody. Re-igniting a
  burning block hands it to the newest igniter; an igniter who logged off is still credited.
- Context: `siege` when the gate is locked down by a running match, else `open_world`; non-Siege gates count too.
- Gate HP outcomes are identical to today (the hook only reads the computed loss).
- Not in scope: gates destroyed count, repair/regeneration attribution.

### F.9 Distance and falls (L1-13)

- A segment is the movement of one `PlayerMoveEvent` (same world, not a teleport, length ≤
  `statistics.movement.max-segment-blocks`, default 10). Mode at the time of movement: in a vehicle (boat, minecart,
  mount) → `vehicle`; gliding with elytra or flying → `flying`; otherwise `foot` (swimming also adds to internal
  `distance.swim`). Spectator/creative and AFK players are excluded.
- **Highest fall:** fall damage observed at MONITOR; recorded when health after the damage stays above 0 (survived, D3);
  value = fall distance in blocks rounded to one decimal.

### F.10 Periods and rounding (D5, L1-14)

- One function computes period boundaries from a UTC instant and a time zone: day; week starting **Monday**; calendar
  month. Default zone `Statistics:TimeZone = "Europe/Amsterdam"` (V1's zone; the server's zone per D5); the function takes
  an optional player time zone later.
- Durations crossing a boundary are split proportionally to the boundary; events are allocated by their occurrence time.
- Late events are accepted up to `Statistics:LateEventToleranceDays` (default 7) old; older entries are rejected (counted
  in the response) — spool replays stay within this window in normal operation.
- Display rounding (API presentation contract): damage and gate damage → whole points, half away from zero, applied to the
  final total only; distance → whole blocks (floor); fall → one decimal; durations → whole seconds (formatted h/m in UIs).

### F.11 Leaderboards (D7 details)

- Boards: `active_playtime`, `xp_gained`, `pvp_kills` (total, per context), `pve_kills` (total, per context),
  `wins@<minigame>`, `objectives_captured@<context>`, `gate_damage`, `distance.foot`, `distance.flying`,
  `distance.vehicle`, `discoveries`, `highest_killstreak` (overall, per context). Periods: weekly, monthly, lifetime.
- **Eligibility:** always-public metrics always rank; configurable metrics rank only when effectively *everyone* (§F.4,
  per-context for per-context boards; the total-board rule for totals). Owner exclusions and inactive (merged/deleted)
  accounts never rank; merged secondary identities count toward their primary.
- **Repeat-victim cap:** `pvp_kills` boards count at most **3 kills per victim per killer per day**; personal statistics
  count all kills.
- **Ties:** competition ranking (1, 1, 3); among ties, earlier `reachedAt` first.
- **Refresh:** snapshots every `Leaderboards:RefreshSeconds` (default 300); top 10 shown plus the viewer's own position.

### F.12 Diagnostic event contract (link 6)

Envelope (versioned, one JSON object per event):

| Field | Rule |
|---|---|
| `eventId` | UUID generated at the source; the dedupe key |
| `name`, `schemaVersion` | e.g. `siege.match_join`, `1`; name = `<family>.<event>`, lower snake case |
| `occurredAt` | UTC, millisecond precision |
| `serverName`, `serverSeq` | Source instance + monotonically increasing per-instance sequence (ordering within a source) |
| `source` | `plugin` or `api` |
| `pluginVersion` / `apiVersion` | release identifiers |
| `userId`, `sessionKey`, `testRunId`, `matchId`, `correlationId` | optional links; `correlationId` joins a plugin action to its API calls (`X-Correlation-Id` header) |
| `feature`, `action`, `outcome`, `reasonCode` | outcome ∈ `succeeded`, `denied`, `failed`, `info`; `reasonCode` is a stable code, never free text |
| `objectType`, `objectId` | the object acted on (e.g. `siege_lobby`, `12`) |
| `payload` | **allowlisted** keys per event name; scalar values only, ≤ 16 keys, strings ≤ 128 chars |
| `level` | `baseline` or `enhanced` |

**Never stored:** chat or private-message text, command arguments, IPs, tokens/keys, raw HTTP bodies, inventories,
free-form exception messages (only exception type + stable code).

**Baseline families (all players, low frequency):** `session.join`, `session.leave`, `session.afk_changed`;
`menu.opened`, `menu.action` (action type id + outcome); `command.result` (command label + outcome, no arguments);
`siege.lobby_join_attempt`, `siege.vote_cast`, `siege.team_assignment`, `siege.match_join`, `siege.match_leave`,
`siege.match_phase`, `siege.objective_captured`, `siege.gate_destroyed`; `discovery.granted`; `currency.posting`
(API side: ledger `PublicId`, reason code — no amounts duplicated); `api.call_failed` (plugin: route template, status,
exception type); `telemetry.dropped` (counts of dropped events).
**Enhanced families (test runs / named cohorts only):** `movement.sample` (position every 5 s), `menu.click` (slot,
item key), `combat.hit` (attacker/victim ids, cause, rounded damage), `gate.hit`.
Ingestion is bounded: the plugin buffers ≤ 5,000 events and drops oldest with a `telemetry.dropped` summary; the API
writes through a bounded queue and drops with a metric when full. Telemetry is not spooled (diagnostics must never
back up gameplay; L1-23).

### F.13 Owner-only access (D12, L1-17)

Dedicated nodes under the `knk.owner.` prefix, **not granted by any seed or migration** (the developer grants them to
themselves with the existing grant endpoint):

| Node | Allows |
|---|---|
| `knk.owner.telemetry.view` | Diagnostic timeline search and event details |
| `knk.owner.telemetry.manage` | Test runs, enhanced-mode targets |
| `knk.owner.privacy.manage` | GDPR deletion requests and execution |
| `knk.owner.analytics.view` | World analytics (heatmaps, menu funnels, domain interactions) |
| `knk.owner.leaderboard.manage` | Leaderboard exclusions |

Because `*` and `knk.*` grants match `knk.owner.*` in the API's wildcard resolver, owner endpoints require an **exact
grant** of the node (the resolver's matched node must equal the node); wildcards never unlock owner data. Every
timeline read is recorded in the audit log. Staff node (not owner-only): `knk.admin.statistics.view`.

### F.14 GDPR deletion (D12, D14-D16; L1-18 superseded)

**Who starts it (D14):** only the player or staff — nothing is deleted without a request (no removal of inactive players).

| Route | How | Confirmation |
|---|---|---|
| Player, web app account page | `POST api/data-deletion/me` → email with a link to `/account/delete-data/confirm?token=…` (valid `Privacy:ConfirmationHours`, 24) → `POST api/data-deletion/confirm` | Email link (proves the mailbox); the page needs an explicit click so mail scanners can't confirm |
| Staff (`knk.admin.privacy.request`), player profile | `POST api/data-deletion/users/{id}` (optional note, never shown to the player) | None; the player is emailed when the account has an address |
| Owner (`knk.owner.privacy.manage`), owner privacy page | `POST api/privacy/deletion-requests` | None |

- A confirmed (or staff/owner-filed) request is **scheduled `Privacy:GraceDays` (5) later**. Until then the player
  (`POST api/data-deletion/me/cancel`) or staff (`…/users/{id}/cancel`) can cancel it. Statuses: AwaitingConfirmation →
  Pending (scheduled) → Completed, or Cancelled / Expired (link not used in time). Asking again while unconfirmed sends a
  fresh link (old link stops working; one email per `ResendCooldownSeconds`).
- An hourly job expires unused links and executes scheduled requests whose grace period is over
  (`Privacy:AutoExecuteEnabled`; when false, the owner executes by hand). Execution before `ScheduledAt` is refused
  (`GracePeriod`). Legal deadline `DueAt` = confirmation + `Privacy:DeletionDueDays` (30; GDPR Art. 12(3)).
- **Deleted** (player and every account merged into them): all KNG-34 data — sessions, daily rows, lifetime totals,
  visibility settings, statistics profile incl. leaderboard exclusion, title-change history, PvP kill pairs as killer
  **or** victim, leaderboard snapshot entries, diagnostic events and enhanced targets — plus discoveries and (D15)
  **private-message logs** sent or received, **link codes**, **permission grants**, **group memberships** and **audit
  rows about the player** (rows the player wrote as staff about others stay: they are those players' history). (D23)
  The player's name is cleared from road-builder proposals (`road_tile_proposals.CreatedBy`).
- **Pseudonymized:** the `users` row (username → `deleted-<id>`; email, UUID, password hash, gender, chat prefix/suffix
  cleared; inactive; reason "GDPR erasure"). A returning player gets a fresh account.
- **Kept:** ledger rows (accounting; immutable by trigger) and Siege match rows (other players' history), on the
  anonymous account; anonymous world-analytics aggregates. **Erased accounts never get statistics again (D16):** the
  statistics write path drops them, so neither new ledger legs nor a rebuild re-create rows.
- The request keeps only counts of what was removed; its note is cleared on execution.

### F.15 Retention defaults (L1-19)

| Data | Default | Config |
|---|---|---|
| Lifetime totals, title history, statistics profile | Kept until GDPR deletion | — |
| Daily statistic rows | 730 days (lifetime totals remain) | `Statistics:DailyRetentionDays` |
| Sessions | 365 days | `Statistics:SessionRetentionDays` |
| Ingestion batch ids | 30 days | `Statistics:BatchRetentionDays` |
| PvP kill pairs (leaderboard cap) | 62 days | `Statistics:KillPairRetentionDays` |
| Leaderboard snapshots | current + 400 days of period-final snapshots | `Leaderboards:SnapshotRetentionDays` |
| Diagnostic events — baseline / enhanced | 90 / 14 days | `DiagnosticTelemetry:BaselineRetentionDays` / `EnhancedRetentionDays` |
| World analytics aggregates (anonymous) | 180 days | `WorldAnalytics:RetentionDays` |

Volumes are to be measured in the alpha (events per player-minute, rows per day) and retention adjusted then.

### F.16 Link-1 decisions flagged for review

| # | Decision (reversible default) | Why |
|---|---|---|
| L1-1 | AFK = `/afk` toggle + auto after 300 s; signals/anti-pool rules §F.2; idle window retroactively AFK; tab marker; no Siege removal | V1 had both; V1's signals were noisy; retroactive keeps active playtime honest for leaderboards |
| L1-2 | Salary not gated by AFK | Needs an API contract change; outside statistics scope |
| L1-3 | Anonymous web visitors see only always-public fields; "everyone" = any signed-in viewer | Most privacy-protective reading of "everyone" |
| L1-4 | Context override beats metric-level value; totals need all contexts public | Predictable; prevents leaks through totals |
| L1-5 | ~~Economy buckets §F.5 (transfers, admin, signup, merge, premium excluded)~~ — superseded by D20 | Earned/spent should reflect gameplay |
| L1-6 | ~~`xp_gained` = earned-bucket XP only~~ — superseded by D20 (every XP gain) | Admin grants would make the board meaningless |
| L1-7 | Unreported participants count as present; left-and-rejoined counts as a loss; Siege stats dated on match end | Follows the API's existing markers |
| L1-8 | Siege outcome/kill/death/streak/capture stats projected from match tables; plugin skips them | One source of truth |
| L1-9 | Damage dealt capped at victim health; `CUSTOM` damage excluded | Avoid overkill inflation and double counting |
| L1-10 | PvE kills exclude spawner/egg/breeding creatures | Anti-farming |
| L1-11 | Open-world streak resets on death and quit | Prevents logout-protected streaks |
| L1-12 | Fire: newest igniter wins; offline igniter still credited; TNT credited to its source | Deterministic, no double counting |
| L1-13 | Movement segment ≤ 10 blocks; AFK/creative/spectator excluded | Rejects teleports/corrections and idle pools |
| L1-14 | Time zone `Europe/Amsterdam` | V1's zone; server zone per D5 |
| L1-15 | First join from Minecraft-created accounts' `CreatedAt`, else first session | Uses an existing authoritative fact (D6) |
| L1-16 | Merged identities are summed (possible simultaneous sessions not de-overlapped) | Rare; sessions table allows a later fix |
| L1-17 | Owner nodes require an exact grant | Wildcards match `knk.owner.*` |
| L1-18 | ~~GDPR scope §F.14 incl. user pseudonymization and auto-execution 3 days before due~~ — superseded by D14-D16 | Deadline guarantee; ledger immutable |
| L1-19 | Retention defaults §F.15 | To be tuned after alpha measurement |
| L1-20 | Staff with `knk.admin.statistics.view` see all of a player's statistics (not diagnostics) | Moderation use; diagnostics stay owner-only |
| L1-21 | `xp_gained` is always public; `title_history` is configurable | XP is already public; history is private by the agreed rule |
| L1-22 | Siege projection moved from link 4 to link 2 (API-only work) | Charter §0 re-cut |
| L1-23 | Telemetry is buffered and dropped (with counts), never spooled | Diagnostics must not back up gameplay |

## Agreed player-facing direction

1. Design the statistics players can view first. Reuse their underlying data for later debugging, testing, balancing and world analytics where appropriate; staff access and retention may differ from player presentation.
2. Visibility is decided **per data item**, not through one private/public switch for the entire profile. Username, current title, coins, gems, experience, first server join, active playtime and AFK time are public to other players and cannot be hidden through the optional-statistic controls. Other statistics default to **private** and a player may choose **nobody, friends, or everyone** for each configurable item. The friends choice depends on KNG-35's relationship design; until that relationship can be verified, it must not reveal data to anyone.
3. Display **First joined the server** as the earliest recorded Minecraft server-join timestamp. On account linking or merging, use the oldest first-join timestamp among the involved Minecraft identities. A web account's creation timestamp alone does not count. An account that has never joined has no first-join value. Whether historical records permit a complete backfill needs verification.
4. Maintain two non-overlapping duration counters, both public: **active playtime** and **AFK time**. Their sum is total online time. AFK duration is not included in active playtime.
5. **Provisional AFK rule:** after five minutes without meaningful activity, classify the player as AFK. The exact activity signals, whether the initial five idle minutes are assigned retroactively to AFK, behavior on disconnect and crash, and anti-idle abuse rules remain open. Do not treat five minutes as the final contract for an AFK feature.

## Player settings and account identity

**Agreed:** persist statistics and visibility settings against the canonical player/User identity from the first Minecraft join, independently of whether web login exists. Linking a web account grants access to that existing history, not a new set of counters. The web account is optional and can offer richer profile charts, sharing and settings; aggregated analytics should not depend on web-account adoption. Account merges must reconcile source histories and overlapping sessions explicitly rather than blindly summing counters; keep the earliest Minecraft join as decided above.

**Agreed primary settings surface:** a player-accessible **Minecraft InventoryMenu** for visibility choices, including Minecraft-only players. V1 had an AFK/settings-style menu with little working functionality; inspect its actual behavior before porting. The V3 plugin already has a `MenuFeature` registry, `profile.main` content provider and registered menu actions/conditions, so design this as a feature-specific menu/action backed by the same server-side User preferences used by the optional web settings page. The backend must enforce visibility on every read surface; hiding a menu item alone is insufficient. Exact menu navigation, API contract, settings persistence and concurrency behavior still need design. A friends-only setting must fail closed until KNG-35 can resolve friends reliably.

## Visibility settings: per metric with group actions

**Agreed:** every configurable player-facing statistic has its own visibility value: nobody (default), friends or everyone. The in-game InventoryMenu also offers a group-level convenience action to set all currently listed metrics in that group to any of the three values: nobody, friends or everyone. Treat this as a **bulk update to the currently listed individual settings**, not a permanent override that silently changes future metrics. A player can change any individual setting afterward. Newly introduced metrics stay private by default until explicitly changed. **Mandatory group-change confirmation:** before applying a group action, show the exact affected counters with each current visibility → proposed visibility, then require the player to confirm. Apply the confirmed changes as one atomic update so a partial failure cannot leave an unexpected mixed state. Unchanged counters need not be written, but the preview should make the full scope understandable. Always-public identity/balance/playtime fields are outside these group actions; friends-only stays closed until KNG-35 supplies relationships. The backend stores and enforces the effective per-metric values consistently for Minecraft and web reads.

## AFK feature dependency

**Resolved by link 1:** see §F.2 (V1/V2 analysis in the source audit §4).

V1 had a dedicated AFK mode that the developer wants to reimplement. Its V1/V2 behavior has **not yet been analyzed** and there is no separate AFK feature plan. Before implementing the classification or counters, inspect the legacy code and decide how explicit AFK mode, automatic inactivity detection and manual return to activity interact. The five-minute rule above is a temporary statistics-design default and may change to follow that feature.

## Combat and activity breakdown

**Agreed:** kill metrics must be inspectable by game context/minigame, not just as one undifferentiated counter. Siege, future Arena and Dungeons should each have their own breakdown; the model must permit new modes without adding a hard-coded column for every one. Record the context when an event happens (including match identity where relevant) so an event is counted once even if the player moves or an area overlaps a minigame. Siege match history is an existing source for its own match statistics; reconcile it rather than writing a second independent Siege kill count. **Agreed:** player kills (PvP) and creature/monster kills (PvE) are separate metrics; each can be broken down by game context and by day/week/month/lifetime. Never add PvE kills to a PvP-kills leaderboard or present their sum as an unlabeled 'kills' figure. **Agreed death recording:** classify each death internally as caused by another player, a creature/mob or the environment (including falls/lava), and preserve its game context. **Player-facing first release:** show only an overall deaths total, with the agreed privacy choice and daily/weekly/monthly/lifetime views; do not expose cause or minigame death breakdowns yet. Their possible later value is an open product decision. Do not equate an internal breakdown with permission to publish it. The default private/friends/everyone setting should apply to each configurable statistic; finer per-mode visibility is still an open UI decision.

## Title history

**Agreed player-facing feature:** a chronological title-change log on the profile, recording both promotion to a higher title and demotion to a lower one. Store the previous title, resulting title and effective timestamp for every change, so a player can see progress and setbacks rather than an incorrectly monotonic 'promotions' count. The current title remains always public under the base-profile rule; the history is a separate configurable statistic, private by default under the general visibility rule. **Agreed first release:** show no reason in the player-facing title log. A title transition normally follows a change in XP; identifying and presenting the upstream gameplay cause (such as a monster kill, Siege result or penalty) adds complexity and is not required for this feature. Keep source/initiator detail in the XP ledger where available for auditing and analysis, without building a causal chain into every displayed title event. How to handle title corrections, non-XP administrative changes and how much legacy history can be backfilled still need source analysis and product decisions. Do not fabricate past changes from the current title alone.

## Damage statistics

**Agreed:** players can view rounded totals for damage dealt and damage received, with damage involving players and damage involving non-player creatures/mobs kept separate. Break each down by game context and by day/week/month/lifetime. Preserve precise source values for calculations and analysis. Round only the final player-facing total to whole damage points, never each hit or burn tick; define a consistent rounding function in the API/presentation contract. Attribution remains to be specified. Visibility follows the configurable private/friends/everyone rule rather than becoming one of the always-public base fields.

**Gate-door damage:** show a separate player-facing counter for damage actually applied to gate doors with hit points, especially during Siege. Count effective HP lost, capped by the door's remaining HP, rather than raw attack strength or attempted hits; do not include it in damage dealt to players or creatures. Record the actor, affected gate/door, game context and match where applicable so the figure can be reconciled with gate state and analyzed later. **Agreed continuous damage:** when a player deliberately ignites a door (for example with a flaming projectile or flint and steel, and Fire Aspect if supported), count subsequent effective burn HP loss toward that player's gate-damage total, including after the initiating hit. Store an attribution owner per burning block/ignition so simultaneous fires from several players can be credited without double counting; if the initiator is genuinely unknown, leave the damage unattributed rather than guessing. Refresh/re-ignition and offline-player behavior require explicit implementation rules. Current plugin source (2026-09-29): `GateDoorIgniteEvent` carries `causingEntity`, but `GateFireSystem.igniteBlock` drops it and `CachedGateDoor.burningBlocks` stores only block position → expiry; `tick` applies combined damage per gate. Thus attribution is **new work**, not existing behavior. The ignite enum currently names flaming projectile, fire charge and flint and steel; verify Fire Aspect detection separately. Define attribution for explosions, indirect attacks, regeneration/repairs and non-Siege gates in the detailed design. Gate damage inherits the daily/weekly/monthly/lifetime views and configurable visibility. A separate count of gates destroyed is out of the first player-facing scope; reconsider only if the developer later finds it useful.

## Time periods

**Agreed:** chosen player-facing counters should have lifetime, daily, weekly and monthly views, including per-game-context breakdowns where applicable. Weekly and monthly views should use clear calendar periods, with exact timezone and week start decided in the technical design. These views should derive from the same recorded facts or consistently reconciled aggregates so their definitions cannot drift. A session spanning period boundaries must allocate playtime and AFK duration correctly. Define late-event correction, aggregation/retention and whether lifetime totals include pre-instrumentation history later. V2's `UserStatisticsDaily` is evidence for the requirement, not an implementation to copy without checking its persistence behavior.

**Potential extension, not yet specified:** weekly/monthly leaderboards could reward activity and give players reasons to return. Decide which metrics are suitable, visibility eligibility, tie rules, period reset, rewards (if any), anti-farming safeguards and whether a player who hides a statistic may appear on its leaderboard. Do not assume every private statistic is rankable or public.

## Exploration distance

**Agreed:** record three separate player-facing distance counters: on foot, flying and in a vehicle. Teleports are excluded from distance traveled. All three can be viewed by day/week/month/lifetime and follow per-statistic visibility. Compute distance from eligible movement segments classified at the time of movement; reject teleports, world changes and server correction jumps so a large coordinate delta is not treated as travel. Record source context efficiently without persisting every position update. **Agreed provisional grouping:** swimming distance is included under the player-facing 'on foot' counter for now, rather than a fourth counter. The underlying movement mode may still be retained internally for later reclassification. **Agreed:** Elytra travel is included in the 'flying' distance counter. Exact movement thresholds, vehicle subtypes and whether AFK automated movement counts are still open.

## Discoveries: reuse existing views

The web app already has a **Discoveries** panel on the player moderation profile (`PlayerDiscoveriesPanel`): staff with `knk.admin.discovery` can inspect progress by Town/District/Structure and page through named discoveries with timestamps and rewards, including a reset action. A logged-in player also has `MyDiscoveriesSection` on their own account page with progress by type and the ten most recent named discoveries. Reuse the existing discovery source and UI concepts when shaping player statistics; do not create a second independently maintained discoveries list or confuse the staff moderation panel with a player-facing public profile.

**Agreed visibility:** discovery counts and the list of named discovered places have separate player-controlled visibility settings, each defaulting to nobody with friends/everyone choices under the general rule above. A single visibility setting controls all discovery counts together, including the Town/District/Structure breakdown; the named-discoveries list has its own separate setting. Current other-player discovery reads require staff permission, so sharing either kind of data needs a dedicated read path with per-statistic authorization. Staff reset remains staff-only regardless of player visibility. Do not expose either to other players until the access rule is designed and enforced by the API.

## Economy totals

**Agreed player-facing:** show coins and gems earned and spent, separately, for day/week/month/lifetime. Do not add a separate net-change statistic in the initial player view. Use the existing ledger as source and derive period aggregates efficiently; validate profile and leaderboard query load before implementation. One configurable visibility setting controls this earned/spent economic-statistics section as a group, default private; current coins and gems balances remain always public outside that setting. Confirm the ledger's historical coverage and whether every balance adjustment can be correctly categorized as earned or spent before making completeness claims.

## Additional player-facing legacy statistics

**Agreed from V2 review:** record and show wins and losses per minigame (including Siege) by day/week/month/lifetime. Reuse stored match results where available and avoid parallel sources of truth. Draws, aborted matches, premature departure and match completion time need explicit counting rules before implementation. Show objectives captured per game context; show arrows fired and headshots; show highest killstreak, contingent on designing and implementing a killstreak mechanic; and show highest fall. The source and definition of highest fall (including whether it means a survived fall) must be checked against legacy behavior before naming the UI value. Record/show login counts by day/week/month/lifetime, with a definition of successful join and reconnect counting still to decide. For these optional player-facing statistics, default to private with nobody/friends/everyone visibility unless a more specific group choice is agreed. Period handling for objective, arrows, headshots, killstreak and highest-fall records should be specified later; do not assume a lifetime record adds across days. **Parked:** V1 block-breaking and fish-caught counters are outside the current player-facing scope, pending later reconsideration.

## Legacy player-facing candidate audit — still to decide

**Resolved by link 1:** field-level audit in the [source audit](../../reports/2026-10-03-player-statistics-source-audit.md) §2-§3; the resulting catalogue is §F.1.

The current conversation does **not** exhaust the V1/V2 field inventory. V2 `UserStatistics` included logins; minigame/Siege wins and losses; objectives captured; arrows fired and headshots; highest killstreak; highest fall; and kill/death splits alongside the combat, gate, distance and economy counters already discussed. V1 additionally had today/lifetime block-breaking and fish-caught counters that V2 dropped. Review each candidate for player value, current V3 source availability, definition, visibility and periodicity; legacy presence does not imply automatic V3 implementation. Reconcile Siege match results rather than duplicating its counters, and determine whether a highest-ever record belongs in daily/weekly/monthly views. V1/V2 inventory remains provisional until source-level field and call-site audit is complete.

## Diagnostic and balance telemetry — proposed design

**Developer goal:** a permanent staff-only diagnostics and game-balance capability, first exercised intensively in a closed alpha with known testers and written test steps. Staff should be able to reconstruct a player's relevant sequence of actions and outcomes without repeatedly requesting screenshots or a full account from that player. The closed alpha is an initial use case, not the lifetime scope of this capability. Player-facing statistics use some of the same domain facts, but aggregate counters alone do not explain a failed operation.

### Three complementary layers

1. **Structured domain-event timeline:** durable, queryable records for significant actions and outcomes. Examples: successful join/leave, domain enter/leave/discovery, menu opened/selected/result, command or feature action/result, Siege join/start/team/objective/gate/finish/abort, and XP/currency mutation references. Capture denied and failed actions as well as successful ones. Reuse the existing economic ledger and Siege match facts by linking to their IDs rather than duplicating amounts or independently incrementing counters. An event is not necessarily a separate database transaction for every low-level call.
2. **Operational logs/traces:** correlate plugin → API → database activity and exception details to the initiating event or operation. These may have a different storage backend and shorter retention than durable domain events. Errors should remain diagnosable even when successful trace traffic is sampled.
3. **Aggregates for balancing:** derive per-scenario, team, mode, period and cohort measures from reliable match/domain facts: win rate, duration, participation, objective/gate activity, damage and reward distributions. Define denominators, aborted matches, eligibility and version changes so comparisons are interpretable. Use movement samples separately if heatmaps become a priority.

### Proposed event contract

**Finalized:** §F.12 (envelope and families) and §F.13 (owner-only access).

A versioned event name and schema; event timestamp in UTC plus stable server ordering/sequence where needed; canonical player ID, session ID, optional test-run ID, match ID and operation/correlation ID; plugin/API release version; feature/context and object IDs; attempted action, outcome (succeeded/denied/failed) and stable reason/error code; a minimal allowlisted payload of state changes or references to authoritative records. Store enough to answer “what happened, in which order, to which object, and why did it fail?” Avoid storing full chat text, credentials, tokens, IPs, raw HTTP bodies, complete inventories or freeform exception contents in broadly queryable player timelines. Exact fields and redaction rules must be designed per event family. Preserve causality across asynchronous work rather than assuming wall-clock timestamps alone impose total order.

### Detail, access and lifetime

**Agreed direction:** keep a baseline set of low-frequency, meaningful events for every player so later bug reports remain diagnosable. Add a configurable enhanced diagnostic mode for named test runs or player cohorts with more detail and potentially bounded movement samples; the baseline remains active independently of that mode. Exact event families and detailed-mode triggers still need approval. Never persist every position/tick by default. Use buffered/asynchronous ingestion with bounds, backpressure and explicit handling of dropped diagnostics so gameplay does not wait on analytics writes. Define a staff-only search/timeline UI by player, time window, session, test run and match; show linked failures and source records, with access auditing. Pick retention separately for detailed events, technical traces and aggregates after measuring volume and considering privacy; no arbitrary retention duration is approved yet. Measure events per player-minute, peak throughput, queue lag, storage growth, search latency and failure behavior in alpha, then adjust production detail and sampling.

### Siege event catalogue: lobby and participation (proposal)

| Event | When emitted | Minimal diagnostic fields | Enhanced closed-alpha fields |
|---|---|---|---|
| `siege.lobby_join_attempt` / outcome | A player requests to enter a lobby; include successful and denied outcomes | player/session ID, lobby ID, timestamp, outcome and stable reason code | relevant eligibility/capacity/team-assignment inputs; no raw player inventory |
| `siege.vote_cast` / outcome | A scenario vote is accepted or rejected | lobby ID, scenario ID, player ID, outcome | previous/replacement choice and applicable vote-state version |
| `siege.team_assignment` | Team assigned or changed | player ID, lobby/match ID, team ID, assignment cause | candidate team sizes/balancing inputs when troubleshooting |
| `siege.match_join` / `siege.match_leave` | Player begins or ends participation | match ID, player ID, team ID, timestamp, leave cause | reconnect/teleport/inventory-restore state references |
| `siege.match_phase` | Match moves from lobby to countdown, active, cooldown/completed/aborted | match ID, old/new phase, cause | relevant timer and scenario configuration version |

These names are provisional and must be reconciled with actual Siege state transitions and the authoritative match model. Use one operation ID to link an attempt to its outcome and associated plugin/API trace, without claiming success before persistence/transition completes. Suppress duplicate records on retries, represent unexpected server shutdown and disconnect distinctly, and store only IDs/versioned configuration references where the authoritative source already exists. High-frequency countdown ticks do not need individual durable events.

### First vertical slice

Use one Siege test session as an acceptance scenario: tester joins, opens relevant menu, enters lobby, joins a team, acts on objective/gate, receives reward, match ends; deliberately trigger one denied action and one plugin/API failure. Staff must locate the session and see the ordered action/result timeline with match and correlation links, then navigate to technical error details. This is a proposal for design validation, not a claim that this instrumentation or UI is already implemented.

## Performance guardrail

**Developer constraint:** statistics and later leaderboards must remain efficient at the intended player scale. Do not issue one database write for every tick or persist four separate event streams for daily/weekly/monthly/lifetime views. Candidate architecture: record durable low-frequency domain facts where needed, batch or aggregate high-frequency counters, and derive calendar views from daily aggregates (with a correction/rebuild path). Index only the leaderboard queries actually selected; refresh rankings asynchronously or on a bounded interval rather than recalculating across all raw history on every menu open. Movement/heatmap telemetry needs separate sampling and retention. Before choosing storage and flush frequency, measure expected concurrent players, events per second, write latency, database size, menu/query latency and catch-up behavior after crashes. These are design constraints, not measured performance claims.

## Candidate player-facing groups — not yet approved field by field

**Superseded by §F.1** (catalogue and menu groups); kept as history.

- Activity: active playtime, AFK time, first server join and possibly active days.
- Progression: current title/XP and promotion history.
- Economy: current balances and earned/spent summaries derived from the existing currency/XP ledger, without duplicating that ledger.
- Combat: selected lifetime and periodic counters from V2 `UserStatistics`/`UserStatisticsDaily` (KNG-14).
- Siege: per-match history and aggregates from `SiegeMatchParticipant`.
- Exploration: discoveries and, if selected, distance traveled.

For each candidate, decide its exact definition, source, period, visibility, aggregation and backfill. Then design operational events, sampling and retention separately. The existing `/user statistics` command (KNG-9) and currency ledger (KNG-21) are inputs, not a complete statistics system.
