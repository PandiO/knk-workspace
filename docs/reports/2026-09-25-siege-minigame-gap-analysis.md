# Siege Minigame — Requirements & Gap Analysis

**Date:** 2026-09-25
**Status:** Point-in-time report (not a living doc — a re-run is a new dated file)
**Feeds:** [`docs/specs/siege-minigame/DESIGN.md`](../specs/siege-minigame/DESIGN.md),
[`IMPLEMENTATION_PLAN.md`](../specs/siege-minigame/IMPLEMENTATION_PLAN.md),
[`MENU_TEMPLATES.md`](../specs/siege-minigame/MENU_TEMPLATES.md)

## Method

Synthesised from, in authority order (`docs/README.md`):

1. `docs/vision/vision.md` §3.2–3.4, §7.1–7.4, §9.2, §10 (Siege is the named MVP/Open-Beta driver).
2. Legacy spec mining: `docs/specs/legacy/siege-minigame.md`, `inventory-menus.md`, `kits.md`,
   `commands-v1.md` §`/siege` `/scenario`, `commands-v2.md` §5, `events-v2.md` (`EntityListener.onDamage`,
   `PlayerListener.onDeath/respawn/onPickup`).
3. v3 catalogs: `docs/specs/user-features/COMMAND_CATALOG_V3.md`, `EVENT_CATALOG_V3.md`.
4. Earlier reports: `IMPLEMENTATION_STATUS_AUDIT.md`, `LEGACY_VS_V2_GAP_ANALYSIS.md` (both 2026-09-10 —
   partly stale: inventory menus, items, users, gates have shipped since).
5. **Direct source reads** (this pass), not only docs:
   - `knk-v2-archive` (branch `2025/01/Hibernate-update`; siege files differ from `main` only by the
     mechanical Java 21/`jakarta` migration — verified with `git diff -w main`): every class under
     `model/minigame/**`, `model/menu/siege/**`, `model/menu/main/**`, `menu/preset/menu/siege/**`.
   - `knk-v1-archive`: `Menu.openSiegeOverview/openSiegeInformation/openSiegeSpawnpointMenu`,
     `EventsClick.onSiegeOverviewClick/onSiegeInformationClick/onSiegeRespawnClick`.
   - v3 (`knk-web-api`/`knk-plugin`/`knk-web-app`, all on `claude/user-management`; kits read from
     `origin/claude/kits`): `Models/`, `Models/Menu/*`, `GateStructure*`, plugin `menu/`, `gates/`,
     `listeners/`, `tasks/`.

## 1. What Siege must be (requirements synthesis)

| # | Requirement | Source | Notes |
|---|---|---|---|
| R1 | **Scenario** = persisted, admin-configured map/mode (town + districts, teams, spawnpoints, objectives, initial holders); **Siege** = live match running on one | vision §7.1 | Same split in v1/v2 |
| R2 | N sides supported (default 2: attackers/defenders; e.g. 2 rival attacker teams vs 1 defender) | vision §7.1 | v2 had allies/enemies scaffolding; scoring was hardcoded |
| R3 | Objectives with per-objective `instantVictory`; side objectives weaken instant-victory objectives on capture | vision §7.2, v2 | v2 generalisation of v1 "Main Objective" |
| R4 | Held objectives double as spawnpoints for the holding team | vision §7.2, v2 `SpawnpointOverview` | "carry forward as-is" |
| R5 | Team identity from a minimal **Clan** (name, chat colour, full multi-layer banner, `defaultForTown`), or an ad-hoc scenario-only team — admin picks per team | vision §3.2, §7.3 | New for v3 |
| R6 | Build approach: v1's working functionality on v2's architecture | vision §7.4 | |
| R7 | Admin CRUD through the web-app FormWizard, not in-game wizards | developer brief, Kits precedent | v1 had a 13-stage chat wizard; v2 had edit-only |
| R8 | Player UI through the v3 InventoryMenu engine; legacy Siege menus documented as templates (not implemented yet) | vision §10, developer brief | |
| R9 | Match lifecycle: matchmaking → vote → hub → team split → match → rewards → cooldown | v1/v2 | v1 self-sustaining; v2 manual |
| R10 | Rewards: win / holding / individual-capture, coins + XP (+ gems on win) | v1/v2 | v2 never actually granted XP (see §3) |
| R11 | Gates integrate as objectives/obstacles | vision §7.2, gate spec Feature 4, `GateStructure` siege fields | Semantics re-decided with the developer 2026-09-25 (DESIGN §7) |
| R12 | Attack cadence on fixed day/time (pre-siege missions etc.) | vision §3.4 | Long-term; SCHEDULED lobby mode reserves the hook |

## 2. Capability matrix — legacy vs v3

Legend: ✅ exists/works · 🟡 partial/buggy · ❌ missing · — n/a

### 2.1 Domain & persistence

| Capability | v1 | v2 | v3 today | Gap for v3 |
|---|---|---|---|---|
| Scenario entity | ✅ raw JDBC | ✅ Hibernate `siege_scenario` | ❌ | Build (`SiegeScenario`) |
| Team entity | 🟡 2 hardcoded teams | ✅ `siege_team` + allies/enemies M2M | ❌ | Build, owned by scenario |
| Spawnpoint entity | ✅ | ✅ `safezoneRadius` per point | ❌ | Build, owned by team |
| Objective entity | ✅ Main + Side | ✅ `instantVictory`, optional gate | ❌ | Build, owned by scenario |
| Clan / default town team | ❌ | ❌ | ❌ | Build minimal `Clan` + `BannerDesign` (developer: in scope) |
| Match/result history | ❌ | ❌ (cache-only) | ❌ | Build `SiegeMatch` (new — needed for crash-safe gates + idempotent rewards) |
| Lobby / rotation config | ❌ hardcoded | ❌ hardcoded `"TestSiege"` | ❌ | Build `SiegeLobby` (developer: configurable lobby) |
| Global tunables (scoring constants, timeline) | ❌ literals | ❌ literals | ❌ | Build `SiegeConfiguration` singleton |
| Towns / districts / locations | ✅ | ✅ | ✅ `Town`, `District`, `Location` | none |
| Gates with health/destroy/respawn | 🟡 | 🟡 | ✅ `GateStructure`/`GateDoor`, `HealthSystem.destroyGate/respawnGate`, overrides `PATCH /overrides` | Wire siege control/ownership (DESIGN §7) |
| Gate siege hooks | — | 🟡 snapshot/restore | 🟡 fields only: `IsSiegeObjective`, `CurrentSiegeId` ("FK to Siege (future)"), `AnimateDuringSiege`, `HealthDisplayMode.SIEGE_ONLY` | FK target + behaviour |
| Title/level gating | ✅ `entryTitle`, skilled match | ❌ `@Transient` TODO | ✅ `TitleBracket` shipped (user-features) | Reuse `MinTitleBracketId` (Kits precedent) |
| Currency/XP | ✅ | 🟡 coins only credited | ✅ `User.Coins/Gems/ExperiencePoints` | Server-side reward grant |

### 2.2 Runtime (plugin)

| Capability | v1 | v2 | v3 today | Gap |
|---|---|---|---|---|
| Self-sustaining match loop | ✅ singleton | 🟡 manual `/siege new` | ❌ | Build lobby runtime |
| Explicit phase model | 🟡 flags | 🟡 5 booleans (own TODO asks for "specific stages") | ❌ | Phase enum |
| Main-thread safety | 🟡 | ❌ matchmaking/capture/cooldown tasks `runTaskTimerAsynchronously` touching Bukkit | — | Single sync ticker |
| Scenario vote (2 candidates + random) | ✅ | 🟡 lowest-voted wins; random vote dead | ❌ | Build, fixed |
| Team split | ✅ 2 teams | ✅ N partitions | ❌ | Build (N) |
| Capture scoring | ✅ correct for any 2 teams | ❌ hardcoded `"cinixians"` | ❌ | Build, holder-relative |
| Win resolution (IV capture / timeout → holder wins) | ✅ | ❌ hardcoded default winner | ❌ | Build |
| Scaled match duration | ❌ 900 s | ✅ 1.25 min/player, ≥5 min | ❌ | Build (configurable) |
| Safe zones, friendly-fire block | ? | ✅ `EntityListener.onDamage` | ❌ no PvP listener | Build `SiegeCombatListener` |
| Kill/death/streak tracking | ❌ | ✅ + tab-list suffix | ❌ `onPlayerDeath` is a stub | Build |
| Respawn at spawnpoint + picker menu | ✅ | ✅ | ❌ `onPlayerRespawn` is a no-op stub | Build |
| Sidebar scoreboard per team | ✅ 2 teams | ✅ N teams | 🟡 `ScoreboardUtil` exists (general) | Build siege sidebar |
| Inventory snapshot/restore | ✅ | ✅ in-memory | ❌ | Build (developer: own gear + restore), persist for crash safety |
| Allowed-commands list during match | ? | ❌ declared, never enforced | ❌ | Build filter |
| Enchant-book drops at objectives | ❌ | ✅ | ❌; v3 blanket-cancels item pickup for non-OPs (`PlayerListener.onItemPickup`) | Deferred — pointless with restore (DESIGN open Q) |
| Rewards payout | ✅ coins+exp | 🟡 coins only | ❌ | Server-side, idempotent |

### 2.3 Surfaces

| Surface | v1 | v2 | v3 today | Gap |
|---|---|---|---|---|
| Admin authoring | ✅ `/scenario create` 13-stage wizard | ❌ edit-only, no create | ✅ FormWizard + owned-child List fields + world-bound fields (proven by `GateStructure`→`GateDoor`) | FormConfigurations for new entities |
| In-game location capture | ✅ chat wizard | ✅ Creation stages | ✅ `LocationSelection` WorldTask handler | none |
| Player join/leave | 🟡 menu only (`/siege join` stub) | ✅ command + menu | ❌ | `/siege` command + menus |
| Admin live control (skip/stop) | ✅ `/siege skip` (donator-gated!) | 🟡 skip ok; remove always throws | ❌ | `/siege admin …` |
| Menu engine | ✅ god-class | 🟡 `%var%` never substituted | ✅ InventoryMenu Phases 1–8 | **Engine extensions** (§4) |
| Siege menus | ✅ overview/information/spawnpoint | 🟡 overview/information(matchmaking only)/spawnpoint | ❌ | Templates documented, not implemented (developer instruction) |

## 3. Newly verified legacy defects (not in `legacy/siege-minigame.md`)

Verified by direct source read this pass; all v2 paths relative to
`knk-v2-archive/src/main/java/net/knightsandkings/`.

| # | Defect | Evidence | Severity |
|---|---|---|---|
| N1 | **Lowest-voted scenario wins.** `drawSiegeScenario` sorts ascending (`a1.votes - a2.votes`) then takes `list.get(0)`; its own log line calls that entry "Highest votes" | `model/minigame/siege/Siege.java` `drawSiegeScenario` | Clearly a bug |
| N2 | **Random vote is dead in v2.** The "Random" `MenuItem` (slot 11) has no action; `randomVotes.add` appears nowhere; the vote-count read `%getRandomVoteAmount%` is always 0. v1's equivalent worked (`EventsClick.java:153-158`) | `model/menu/siege/information/InformationOverview.java:117-137`; repo-wide grep | Clearly incomplete |
| N3 | **XP rewards never granted.** `setComplete` sums `totalExpReward` and prints it, but only calls `addCash`; `gemRewardWin` is never read at payout | `Siege.java` `setComplete` reward block | Clearly a bug |
| N4 | **Holding reward is hardwired to the single `attackers` team** (`scenario.getAttackers() == team`); in an N-team scenario every other attacking team earns nothing, and instant-victory objectives count towards the "Side Objectives" holding total | `Siege.java` `setComplete` reward block | Likely a bug (N-team model ignored) |
| N5 | **Overview lists joinable sieges last.** `setTargets` sorts with `Boolean.compare(s1.isMatchmaking(), s2.isMatchmaking())` (false before true), and each item's "Siege N" label is its index in the *unsorted* repository list, so labels don't match on-screen order | `model/menu/siege/SiegeOverview.java:112-113`, `SiegeSelectItem.java:86-87` | Likely a bug |
| N6 | **Information menu's in-progress section never written** — `/** Team/Objective related items */` sits *inside* the `isMatchmaking()` branch and is empty; there is no `isProgress()` branch at all, so during a match the menu shows only the header item + Back | `InformationOverview.java:67-177` | Incomplete (v1 had it) |
| N7 | `ObjectiveItem` "being captured" is recomputed by running the full `calculateCapturePoints()` scan per render/click (also async-thread code path) | `ObjectiveItem.java:48,88`, `SiegeObjective.isBeingCaptured` | Perf smell |
| N8 | Matchmaking warning says "teleported to the **Hide and Seek** hub" (copy-paste) | `Siege.java` `startMatchmaking` (30 s branch) | Cosmetic |
| N9 | `skipStage` NPEs on the `else` branch when `sender == null`; message says "already in matchmaking or progress" while in progress | `Siege.java` `skipStage` | Minor bug |
| N10 | `allowedCommands` list is declared on `MiniGame`/`Siege` but no listener enforces it | `MiniGame.java`, `events-v2.md` `onCommand` | Dead feature |
| N11 | Menu `%placeholder%` lore across every siege item (`%getPlayersMin%`, `%getVoteAmount%`, `%timeformat_…%`, `%username%`) never substituted (see `legacy/inventory-menus.md` bug #7) — v2 siege menus showed raw codewords | `util/MenuUtil.java:242` | Clearly a bug (already known, re-confirmed per-item) |
| N12 | `sendKillStreak` prints `kills`, not `killStreak` | `model/minigame/MGMember.java` `sendKillStreak` | Cosmetic |
| N13 | Timed-out matches in v2 crash reward messaging if no objective captured *and* no team named "cinixians" (`winners` null → `winners.getColor()`) | `Siege.java` `setComplete` | Clearly a bug (consequence of known bug) |
| N16 | **Pagination is dead in every v2 siege menu.** `SiegeOverview`, `InformationOverview` and `SpawnpointOverview` extend plain `Menu` (no `ButtonGroup`); their `TabPrevious`/`TabNext` fall through to `Menu.nextPage()/prevPage()`, which only play a fail sound. Content beyond one page is unreachable | `model/menu/PageButton.java:114-120` (no group set), `model/menu/Menu.java:411-421` | Clearly a bug (instance of `legacy/inventory-menus.md` bug #9) |
| N17 | **Un-voting throws.** Clicking a scenario you already voted for clears the vote, then (vote no longer present) calls `this.getBlink().stopFlash()`; `blink` is never assigned (every `setBlink` call is commented out) → `NullPointerException` after the state change | `model/menu/siege/information/ScenarioItem.java:105-109`, `model/menu/MenuItem.java:33,239` | Clearly a bug |
| N14 | v1 "Change spawnpoint" button in the information menu has no click branch in `onSiegeInformationClick` | `v1:src/Menu/Menu.java` (Info menu slot 3), `v1:src/Menu/EventsClick.java:95-169` | Dead button |
| N15 | v1 overview click joins immediately (no confirmation) and says "Successfully joined" even when `joinPlayer` refused | `v1:src/Menu/EventsClick.java:87-90` | Minor bug |

## 4. v3 prerequisite gaps outside the Siege feature itself

| Area | Finding | Needed for |
|---|---|---|
| InventoryMenu: variable roots | `MenuVariableContext.DECLARED_TYPES` = `{player}` only | Any siege lore (`$siege…$`, `$member…$`) |
| InventoryMenu: menu context params | `menu.open` takes only `key`; `MenuSession` nav stack stores keys only | Opening "information for siege X" |
| InventoryMenu: row templates | Content-source rows are mapped to items **in Java** (`ItemBlueprintMenuMapper`), not from a template | Persisted display for siege/scenario/player/spawnpoint rows |
| InventoryMenu: live repaint | No periodic re-render; `TTL` bindings only refresh when something else re-renders | Countdown timers, live capture % |
| InventoryMenu: domain conditions | Only `always`, `permission-node`, `has-pending-confirmation` | Phase/participation/vote gates |
| Plugin PvP | No player-vs-player damage listener exists (only `EnchantmentCombatListener`) | Friendly fire, safe zones |
| Plugin death/respawn | `onPlayerDeath` stub; `onPlayerRespawn` no-op (hardcoded town `4`, TODO) | Siege respawn |
| Plugin item pickup | Blanket cancel for non-OPs | Irrelevant unless enchant drops return |
| FormWizard | Inline *new* related-entity creation unsupported in M2M editor, **but** owned-child List fields (`ownedChildCollection`) support create/edit + world-task fields (gate QoL 5.11) | Scenario → Teams → Spawnpoints authoring; 2-level nesting needs verification |
| Gates | `PATCH /api/GateStructures/{id}/overrides` exists, permission model "still open" (gate QoL 5.3) | Siege gate lockdown/ownership |
| Clan | Absent everywhere | Default team identity |
| Kits | In progress (`claude/kits`, Phase 1–2 shipped) | **Not** a Siege dependency (developer chose own gear + restore) |

## 5. Bottom line

Nothing Siege-specific exists in v3 beyond four gate fields. The shortest path to a playable MVP:
**Clan/Banner → Scenario model + FormConfigs → Bukkit-free runtime core (phases, capture math,
win resolution) → Paper runtime (listeners, gates, inventory, scoreboard) → match persistence +
rewards → commands → menus (after the four InventoryMenu engine extensions)**. The design and phased
plan are in `docs/specs/siege-minigame/`.
