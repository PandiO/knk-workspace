# Siege Minigame — Design

**Status:** Draft — seven decisions made with the developer over two rounds (§0); remaining open questions in §13.
**Last updated:** 2026-09-26 (§7.2: capture constants tuned in the first live playtest)

Ref: `docs/vision/vision.md` §3.2–3.4, §7.1–7.4, §10. Evidence base:
`docs/reports/2026-09-25-siege-minigame-gap-analysis.md` (capability matrix, newly verified legacy
defects **N1–N17**), `docs/specs/legacy/siege-minigame.md` (v1/v2 model + known bugs), legacy
command/event catalogs, `MENU_TEMPLATES.md` (menus), `IMPLEMENTATION_PLAN.md` (phasing).
Precedents followed: `docs/specs/kits/DESIGN.md` (branch `claude/kits` — FormWizard-only CRUD, one
service path per operation, server-side re-validation), `docs/specs/user-features/` (permission
model, `TitleBracket`), `docs/specs/gate-structure-animation/` (gate runtime, overrides).

## 0. Decisions taken with the developer (2026-09-25)

| # | Question | Decision |
|---|---|---|
| D1 | How do matches come into existence? | **Configurable lobby.** A persisted `SiegeLobby` (web-app CRUD) holds timings and a scenario rotation, with a mode: `Continuous` (v1-style self-cycling) or `Scheduled` (fixed day/time cadence, vision §3.4). MVP ships `Continuous`; `Scheduled` is a later phase on the same entity. |
| D2 | What do players fight with? | **Own gear + restore** (v2 behaviour). The full player state is snapshotted when sent to the hub and restored when leaving the match — losses are undone, anything gained is wiped. No team kits. |
| D3 | How do gates behave? | **Admin-selected gates only.** A scenario lists the gates that take part. Selected gates are active, damageable and **opened/closed by their owning team**. A selected gate may be flagged as (part of) an objective: still damageable, and capturing it transfers open/close control to the capturing team, **defaulting to open** on capture. All other gates in the scenario's town/districts are forced **open** for the match and cannot be controlled or damaged. Pre-siege gate states are restored after. Siege players vs. everyone else: see D6 (§8.5). |
| D4 | Clan scope | **Minimal `Clan` is in this plan** (vision §3.2 fields incl. full multi-layer banner and `DefaultForTown`). Scenario teams either reference a Clan or define an ad-hoc identity. |
| D5 | Objective recapture (round 2) | **Per-scenario boolean `AllowRecapture`, default `false`** (legacy: captured is final). When on, a captured objective can be taken back (§7.3). |
| D6 | Scenario-area lockdown (round 2) | **On.** Tied to the siege/non-siege gate separation: **ideally non-members see every affected gate in its pre-lockdown state**; where their view can't match the physical state, **gates that were open before the lockdown get temporary pass-through for non-members** for the match (§8.5). Per-player gate view is now **in scope** (was deferred). |
| D7 | Enchant-book drops (round 2) | **Keep them** (v2 mechanic). Enchantments applied during the siege are **removed after the siege**, so every item's pre-siege state is restored exactly (§9.4). |

## 1. Scope

**In scope (MVP):** Clan + banner model; Scenario/Team/Spawnpoint/Objective/ScenarioGate model and
FormWizard authoring; `SiegeLobby` (Continuous); global `SiegeConfiguration`; full match loop in the
plugin (matchmaking, vote, hub, team split, match, capture, win, rewards, cooldown); N-team/alliance
support; gate integration per D3; scenario-area lockdown with a per-player gate view for non-members
(D6); optional objective recapture (D5); own-gear snapshot/restore with crash safety; enchant-book
drops with post-siege enchantment stripping (D7); combat/death/respawn rules; scoreboard/tab list;
`/siege` commands; match history + server-side reward payout; menu templates **documented**
(implementation blocked on InventoryMenu engine extensions, `MENU_TEMPLATES.md` Part B — delegated
2026-09-25 to its own session, branch `claude/inventorymenus`).

**Out of scope / later:** `Scheduled` lobby mode (Phase 10); clancastle ownership / `controlledBy` on
structures (vision §2.6, §3.3); pre-siege missions; siege vehicles; web-app live match monitor
(Phase 10).

## 2. What already exists (short — see the gap report for detail)

- `Town`/`District`/`Location` entities and FormConfigs; `LocationInsideRegionValidator` and
  `RegionContainmentValidator` field-validation rules.
- `GateStructure`/`GateDoor` with health, destroy/respawn (`HealthSystem`), structure-level cascading
  overrides (`PATCH /api/GateStructures/{id}/overrides`), and **siege placeholders**: `CurrentSiegeId`
  (commented "FK to Siege (future)"), `IsSiegeObjective`, `AnimateDuringSiege`,
  `HealthDisplayMode.SIEGE_ONLY`, `GateInfoDisplayMode.SIEGE_ONLY`. Custom events
  `GateDoorDamageEvent`, `GateDoorInteractEvent`, `GateDoorIgniteEvent`.
- `User.Coins`, `User.Gems`, `User.ExperiencePoints`; `TitleBracket` resolution; permission groups/
  grants with in-house `KnkPermissible`; `AuditLogService`.
- WorldTask `LocationSelection` handler (in-game point capture into a web-app form); FormWizard
  owned-child List fields (`settingsJson.ownedChildCollection`, proven by `GateStructure → GateDoor`,
  gate QoL 5.11) and M2M join editing with join fields.
- InventoryMenu engine Phases 1–8 (templates in DB, action/condition/content-source registries).
- **Nothing** siege-specific otherwise; no `Clan`; no PvP listener; death/respawn handlers are stubs.

## 3. Domain model (knk-web-api)

New folder `Models/Siege/` (plus `Models/Clan/`). All admin-authored entities get
`[FormConfigurableEntity]`; runtime/history entities do not (append-only, `AuditLogEntry`/`KitClaim`
convention). Delete rules follow vision §9.2's standing rule generalised: **never cascade into shared
world/catalog rows** (`Town`, `District`, `Location` used elsewhere, `GateStructure`, `Clan`,
`TitleBracket`, `User`) — `Restrict`; owned children cascade from their owner.

### 3.1 `BannerDesign` + `BannerLayer` (shared, reusable)

Vision §3.2 requires a banner that "mirrors Minecraft's real banner data structure directly".

```csharp
[FormConfigurableEntity("BannerDesign")]
public class BannerDesign
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;          // "Cinix crown", for pickers
    public BannerDyeColor BaseColor { get; set; }        // enum mirroring org.bukkit.DyeColor (16 values)
    [RelatedEntityField(typeof(BannerLayer))]
    public ICollection<BannerLayer> Layers { get; set; } = new List<BannerLayer>(); // owned, cascade
}

public class BannerLayer
{
    public int Id { get; set; }
    public int BannerDesignId { get; set; }
    public int SortOrder { get; set; }                   // explicit order, bottom → top
    public string PatternKey { get; set; } = null!;      // Bukkit PatternType key, e.g. "minecraft:stripe_top"
    public BannerDyeColor Color { get; set; }
}
```

`PatternKey` is a string (validated against a static list mirrored from Bukkit's registry) rather than
an enum, because Mojang adds pattern types between versions. Max 16 layers (client render limit);
warn above 6 (survival loom limit). Used by `Clan`, ad-hoc `SiegeTeam`s, and generated at runtime for
objective progress banners.

### 3.2 `Clan` (minimal, vision §3.2)

```csharp
[FormConfigurableEntity("Clan")]
public class Clan
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public bool IsNpc { get; set; }                       // baseline crown/garrison clan
    public string ChatColor { get; set; } = "WHITE";      // Bukkit ChatColor name (same convention as MenuItemTemplate.ChatColorName)
    [RelatedEntityField(typeof(BannerDesign))] public int BannerDesignId { get; set; }  // Restrict
    [RelatedEntityField(typeof(Town))] public int? DefaultForTownId { get; set; }       // unique when set; Restrict
}
```

No membership, ranks, diplomacy or ownership yet — those are long-term (vision §3.1, §3.6, §2.6).
`DefaultForTownId` is unique: a town has at most one default clan.

### 3.3 `SiegeScenario` — the map/mode

```csharp
[FormConfigurableEntity("SiegeScenario")]
public class SiegeScenario
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    [RelatedEntityField(typeof(Town))] public int TownId { get; set; }                    // Restrict
    [RelatedEntityField(typeof(District))] public ICollection<SiegeScenarioDistrict> Districts { get; set; } // M2M join
    [RelatedEntityField(typeof(Location))] public int HubLocationId { get; set; }          // world-bound
    public int PlayersMin { get; set; } = 2;
    public int PlayersMax { get; set; } = 50;
    [RelatedEntityField(typeof(TitleBracket))] public int? MinTitleBracketId { get; set; } // v1 entryTitle, Kits precedent
    // Match length (v2 formula as defaults): clamp(ceil(members × PerPlayer), Min, Max)
    public int MatchDurationMinSeconds { get; set; } = 300;
    public int MatchDurationPerPlayerSeconds { get; set; } = 75;
    public int MatchDurationMaxSeconds { get; set; } = 1800;
    // Rewards (v2 SiegeScenario/MGScenario fields)
    public int CoinRewardWin { get; set; } = 100;  public int ExpRewardWin { get; set; } = 10;  public int GemRewardWin { get; set; } = 1;
    public int CoinRewardHolding { get; set; } = 50; public int ExpRewardHolding { get; set; } = 5;
    public int CoinRewardCapture { get; set; } = 50; public int ExpRewardCapture { get; set; } = 5;
    public bool LockdownScenarioArea { get; set; } = true;   // §8.5, D6
    public bool AllowRecapture { get; set; } = false;        // §7.3, D5
    public bool EnchantDropsEnabled { get; set; } = true;    // §9.4, D7
    // Owned children (ownedChildCollection List fields)
    public ICollection<SiegeTeam> Teams { get; set; }             // cascade
    public ICollection<SiegeObjective> Objectives { get; set; }   // cascade
    public ICollection<SiegeScenarioGate> Gates { get; set; }     // M2M join with fields, cascade join rows only
}
```

A scenario is **authored in several saves** (owned children can only be created after the parent has an
id — gate QoL 5.11 constraint), so it can be incomplete. `GET /api/siege-scenarios/{id}/readiness`
returns the §3.9 validation result; only **ready** scenarios are eligible for lobby rotation. No
`IsPlayable` column — readiness is computed, never stale.

### 3.4 `SiegeTeam` — owned by a scenario

```csharp
[FormConfigurableEntity("SiegeTeam")]
public class SiegeTeam
{
    public int Id { get; set; }
    public int SiegeScenarioId { get; set; }
    public int SortOrder { get; set; }
    public SiegeTeamRole Role { get; set; }               // Defender | Attacker
    public int AllianceGroup { get; set; }                // teams sharing a value are allies; all others enemies
    // Identity: Clan-sourced OR ad-hoc (vision §7.3)
    [RelatedEntityField(typeof(Clan))] public int? ClanId { get; set; }                  // Restrict
    public string? Name { get; set; }                     // ad-hoc, or override of the clan's name
    public string? ChatColor { get; set; }
    [RelatedEntityField(typeof(BannerDesign))] public int? BannerDesignId { get; set; }
    public string? StartMessage { get; set; }             // v2 per-team action-bar message
    public ICollection<SiegeSpawnpoint> Spawnpoints { get; set; }   // owned, cascade
}
```

- **Identity resolution:** each of name/colour/banner = the team's own value if set, else the Clan's.
  With `ClanId` null all three are required (ad-hoc team). This is vision §7.3's "two team sources
  feeding the same selection step": ad-hoc identity lives only on this scenario's row, never as a
  reusable Clan.
- **Default suggestion:** the form's Clan picker should list `Clan.DefaultForTownId == scenario.TownId`
  first (verification item in `IMPLEMENTATION_PLAN.md` Phase 3 — the FormWizard may need a filtered
  picker).
- **`AllianceGroup` replaces v2's `siege_team_allies`/`siege_team_enemies` M2M tables.** One integer
  covers every configuration vision §7.1 names (e.g. defender = 1, two rival attacker teams = 2 and 3)
  with a single form field, and makes "ally/enemy" symmetric by construction (v2's two independent
  lists could disagree).
- `Role` drives defaults only (initial objective holder, timeout fallback, UI wording); scoring is
  holder-relative (§7), which is what fixes v2's hardcoded `"cinixians"` bug at the root.

### 3.5 `SiegeSpawnpoint` — owned by a team

`Id`, `SiegeTeamId`, `SortOrder` (0 = default spawn), `Name`, `LocationId` (world-bound, captured
in-game), `SafeZoneRadius` (default 4 — v2 made it per-point; v1 hardcoded 4).

### 3.6 `SiegeObjective` — owned by a scenario

```csharp
[FormConfigurableEntity("SiegeObjective")]
public class SiegeObjective
{
    public int Id { get; set; }
    public int SiegeScenarioId { get; set; }
    public int SortOrder { get; set; }
    public string Name { get; set; } = null!;
    [RelatedEntityField(typeof(Location))] public int? LocationId { get; set; }          // capture point; world-bound
    [RelatedEntityField(typeof(GateStructure))] public int? GateStructureId { get; set; } // D3: must be one of the scenario's selected gates
    public int CapturePoints { get; set; } = 500;
    public double CaptureRadius { get; set; } = 2.5;
    public bool InstantVictory { get; set; }
    [RelatedEntityField(typeof(SiegeTeam))] public int? InitialHolderTeamId { get; set; } // null → first Defender team
    public bool SpawnWhenHeld { get; set; } = true;          // vision §7.2 "held objectives double as spawnpoints"
    public GateDoorOpenState GateStateOnCapture { get; set; } = GateDoorOpenState.OPEN; // D3 "default to open"
}
```

- Location rule: `LocationId` is required unless `GateStructureId` is set, in which case the gate
  structure's own `Location` is the default capture point. This fixes v2's contradiction (legacy bug:
  `gate` was `optional = false` while location-only objectives were supported).
- "Main" vs "side" objective is simply `InstantVictory` true/false (vision §7.2 recommendation).

### 3.7 `SiegeScenarioGate` — the admin-selected gates (D3)

M2M join between `SiegeScenario` and `GateStructure`, edited with the existing M2M editor's join fields:

| Field | Default | Meaning |
|---|---|---|
| `GateStructureId` | — | Restrict |
| `InitialOwnerTeamId` | null → first Defender team | Team (and its alliance) that may open/close it |
| `InitialState` | `CLOSED` | State forced at match start |
| `Damageable` | `true` | Enemies of the owner can damage/destroy it (destroyed gates stay destroyed until the match ends) |

A gate is an objective gate when some `SiegeObjective.GateStructureId` references it (validation: it
must also appear here). Ownership of a non-objective gate never changes during a match.

### 3.8 `SiegeLobby` (D1) and `SiegeConfiguration`

```csharp
[FormConfigurableEntity("SiegeLobby")]
public class SiegeLobby
{
    public int Id { get; set; }
    public string Name { get; set; } = null!;        // shown in menus ("Siege — Cinix")
    public string Key { get; set; } = null!;         // /siege join <key>; unique, lowercase
    public bool IsEnabled { get; set; }
    public SiegeLobbyMode Mode { get; set; } = SiegeLobbyMode.Continuous;  // Scheduled: Phase 10
    public int MatchmakingSeconds { get; set; } = 300;
    public int CooldownSeconds { get; set; } = 900;
    public int VoteCandidateCount { get; set; } = 2;  // 1–3 (menu layout cap, MENU_TEMPLATES C.3)
    public bool AllowRandomVote { get; set; } = true;
    public string? ScheduleJson { get; set; }         // reserved for Scheduled mode; null for Continuous
    public ICollection<SiegeLobbyScenario> Rotation { get; set; }  // M2M join with Weight (default 1)
}
```

Several enabled lobbies may run concurrently (v2 supported a list; v1 a singleton). Runtime locks
(§5.5) stop two lobbies from running the same scenario, or two scenarios in the same town, at once.

`SiegeConfiguration` is a singleton (`Id = "global"`, same pattern as `SalaryConfiguration`/
`GameSettings`) holding every legacy literal as a tunable: capture constants (§7.2), side-capture
reduction fraction (0.4), matchmaking timeline offsets (vote close 30 s, draw 25 s, hub 15 s, team
split 10 s), matchmaking announcement marks (`290,60,30,15`), kill-streak announce thresholds
(`5,10,15`; streak > 3), headshot multiplier (1.5 — v2 value; 1.0 disables), allowed-commands list
(`/siege`, `/msg`, `/r`, `/staffchat`, `/menu`), the spawn-picker/respawn delay (20 ticks), and the
enchant-drop tunables (§9.4: chance per second, 30‰ in v2; allowed enchantment keys; level range 1–2;
max books alive per match).

### 3.9 Scenario validation (server-side, `SiegeScenarioService`)

Checked on save where possible and in full by the readiness endpoint:
- ≥ 2 teams; ≥ 2 distinct `AllianceGroup`s; ≥ 1 `Defender`; every team has ≥ 1 spawnpoint; ad-hoc
  teams have name + colour + banner.
- `PlayersMin` ≥ team count; `PlayersMax` ≥ `PlayersMin`; duration Min ≤ Max.
- Every district belongs to `TownId`; hub, spawnpoint and objective locations lie inside the town
  region (reuse `LocationInsideRegionValidator`/`RegionContainmentValidator` rules).
- ≥ 1 objective; every objective has a capture location (own or its gate's); an objective's gate is in
  `Gates`; holder/owner team ids belong to this scenario.
- Selected gates belong to the scenario's town/districts.
- Warning (not error): no `InstantVictory` objective — the match can then only end on time (§7.5).

### 3.10 Match history & runtime persistence (new — neither legacy version persisted matches)

| Entity | Purpose |
|---|---|
| `SiegeMatch` | `Id`, `SiegeLobbyId`, `SiegeScenarioId`, `Status` (`Created`/`InProgress`/`Completed`/`Aborted`), `CreatedAt`/`StartedAt`/`EndedAt`, `EndReason` (`InstantVictory`/`TimeExpired`/`TeamEliminated`/`NotEnoughPlayers`/`AdminStopped`/`ServerRestart`), `WinningAllianceGroup` (nullable = draw/aborted) |
| `SiegeMatchParticipant` | `SiegeMatchId`, `UserId`, `SiegeTeamId`, `JoinedAt`, `LeftAt`, `Kills`, `Deaths`, `HighestKillStreak`, `Captures`, `CoinsAwarded`/`ExpAwarded`/`GemsAwarded` |
| `SiegeMatchObjectiveResult` | `SiegeMatchId`, `SiegeObjectiveId`, `FinalHolderTeamId`, `CapturedByUserId`, `CapturedAt` |
| `SiegeMatchGateSnapshot` | `SiegeMatchId`, `GateStructureId`, `SnapshotJson` (structure overrides + per-door open state/health/destroyed) — the crash-safe restore source for §8.4 |

`GateStructure.CurrentSiegeId` becomes a real FK to `SiegeMatch.Id` (nullable, `SetNull`). These rows
make rewards idempotent (§7.6), gate restore crash-safe (§8.4), and give per-player siege stats
(kills/deaths/captures) without the general statistics system that doesn't exist in v3 yet.

## 4. Authoring (web app, FormWizard only)

Same hierarchy as Kits `DESIGN.md` §4.0: **every create/edit/delete goes through the FormWizard**;
in-game `/siege admin manage` only points at the web-app route. Scenario authoring is spatial, so
point capture uses the existing **"Send to Minecraft" WorldTask** (`LocationSelection`) — the admin
stands on the spot and confirms, exactly as `GateDoor`/`Location` fields work today.

| Form | Steps (fields) |
|---|---|
| `BannerDesign` | General (Name, BaseColor) · Layers (owned list: SortOrder, PatternKey dropdown, Color) |
| `Clan` | General (Name, IsNpc, ChatColor) · Identity (BannerDesign picker, DefaultForTown picker) |
| `SiegeScenario` | 1 General (Name, Description, Town, Districts M2M) · 2 Hub & entry (HubLocation world-bound, PlayersMin/Max, MinTitleBracket, LockdownScenarioArea) · 3 Match length · 4 Rewards · 5 Teams (owned list → `SiegeTeam` form) · 6 Gates (M2M `SiegeScenarioGate` with join fields) · 7 Objectives (owned list → `SiegeObjective` form) · 8 Readiness (read-only panel calling the readiness endpoint) |
| `SiegeTeam` (child) | Identity (Role, AllianceGroup, Clan picker, Name/ChatColor/BannerDesign overrides, StartMessage) · Spawnpoints (owned list → `SiegeSpawnpoint` form: Name, Location world-bound, SafeZoneRadius, SortOrder) |
| `SiegeObjective` (child) | General (Name, InstantVictory, InitialHolderTeam, SpawnWhenHeld) · Capture point (Gate picker **or** Location world-bound, CapturePoints, CaptureRadius) · Gate behaviour (GateStateOnCapture, shown only with a gate) |
| `SiegeLobby` | General (Name, Key, IsEnabled, Mode) · Timings · Voting · Rotation (M2M `SiegeLobbyScenario`: scenario + Weight) |
| `SiegeConfiguration` | Singleton form (like `SalaryConfiguration`) |

Ordering constraint: Teams (step 5) must exist before Gates/Objectives can reference them as
owner/holder, so those steps show a hint until at least one team is saved. Two-level owned nesting
(Scenario → Team → Spawnpoint) has not been exercised in the FormWizard before — an explicit
verification item (`IMPLEMENTATION_PLAN.md` Phase 3).

## 5. Runtime architecture (knk-plugin)

### 5.1 Authority split

- **Plugin is authoritative for live match state** (phase, members, votes, teams, capture points,
  kills). It runs at game-tick granularity and must never block on HTTP.
- **API is authoritative for configuration and results**: lobbies/scenarios are fetched (cache-first,
  `DataAccessExecutor`), frozen for the duration of a match, and refreshed between matches; match
  lifecycle checkpoints are written via `SiegeMatchesApi` (§11). Rewards are computed and granted
  **server-side** (§7.6).
- A server restart ends any running match (`EndReason = ServerRestart`, no rewards) — §8.4/§9.3 cover
  the cleanup.

### 5.2 Module layout (follows the existing `core/` Bukkit-free vs `paper/` split)

| Module | Package | Contents |
|---|---|---|
| `knk-core` | `core/domain/siege/` | Immutable records mirroring the DTOs (`KnkSiegeScenario`, `KnkSiegeTeam`, …) |
| `knk-core` | `core/siege/` | **Bukkit-free, unit-tested logic:** `SiegePhase`, `SiegeLobbyStateMachine` (tick-driven timeline), `VoteTally`, `TeamPartitioner`, `AllianceResolver`, `CaptureCalculator`, `ObjectiveState`, `WinResolver`, `MatchDurationCalculator`, `SiegeRuntimeLocks` |
| `knk-core` | `core/ports/api/` | `SiegeScenariosQueryApi`, `SiegeLobbiesQueryApi`, `SiegeMatchesCommandApi`, `ClansQueryApi` |
| `knk-api-client` | `dto/`, `mapper/`, `impl/` | DTOs + mappers + HTTP impls (Kits/Items pattern) |
| `knk-paper` | `paper/siege/` | `SiegeService` (owns lobby runtimes, main-thread ticker), `SiegeWorldPresenter` (banners, particle circles, percent `TextDisplay`s), `SiegeGateController` (§8), `SiegePlayerVault` (§9), `SiegeScoreboardPresenter`, `SiegeMenuBridge` (menu registries, §10) |
| `knk-paper` | `paper/listeners/` | `SiegeCombatListener`, `SiegeDeathRespawnListener`, `SiegeGateListener`, `SiegeCommandFilterListener`, `SiegeInventoryGuardListener`, `SiegeSessionListener` (quit/join/teleport/region entry) |
| `knk-paper` | `paper/commands/` | `SiegeCommand` (player + admin subcommands) |

### 5.3 Threading

One **synchronous** 1-second ticker (`runTaskTimer`) drives every lobby and every objective's capture
step. This removes v2's biggest structural defect (matchmaking, cooldown, capture and particle tasks all
ran `runTaskTimerAsynchronously` while touching Bukkit state). The work per tick is small (distance
checks between each objective and that match's members only). HTTP calls use `CompletableFuture`s and
hop back to the main thread for any consequence, the same pattern the plugin already uses for join
loading (ACTIVE_SESSIONS 2026-09-25 join-hang fix).

### 5.4 Phase model

Replaces v2's five independent booleans (`matchmaking`/`progress`/`inHub`/`cooldown`/`finished`, which
its own TODO asked to replace):

```
DISABLED ─enable─► MATCHMAKING ──T-0──► IN_PROGRESS ──win/timeout/elimination──► ENDING ──► COOLDOWN ──T-0──► MATCHMAKING …
                    │  (voting until T-30, draw at T-25,                                        ▲
                    │   HUB sub-phase from T-15: teleport + snapshot, team split at T-10)       │
                    └── not enough players at draw / no ready scenario ─────────────────────────┘
```

`HUB` is modelled as a sub-state of the last 15 s of matchmaking (joining closes at T-15, as v2
effectively did).

### 5.5 Runtime locks

A scenario, and every gate it touches, can be in `HUB`/`IN_PROGRESS` for at most one lobby. Candidate
selection skips locked scenarios. A player can be a member of at most one lobby at a time.

## 6. Match lifecycle rules

### 6.1 Bootstrap
On plugin enable: fetch enabled `Continuous` lobbies and start each in `MATCHMAKING` after a short
delay (v1/v2 used 2 s). Disabled or failing lobbies (no ready scenario) stay `DISABLED` and log once —
never v2's hardcoded `"TestSiege"`.

### 6.2 Matchmaking and joining
- Announcements to online players at the configured marks (v2: 290/60/30/15 s), including the join
  command, and to members at vote close ("teleported to the hub in 15 seconds" — fixes N8).
- Join allowed while `MATCHMAKING` and before `HUB`, if: not in another lobby; `knk.siege.play`; the
  scenario's `MinTitleBracketId` is met — checked against the *drawn* scenario after T-25, and before
  the draw against the lowest requirement among the candidates (a player may join and be removed at the
  draw with a message if the drawn scenario excludes them); capacity: before the draw, the max of the
  candidates' `PlayersMax`; after the draw, the drawn scenario's (latest joiners over capacity are
  removed at the draw with a message).
- Leaving before the hub has no side effects beyond dropping votes.

### 6.3 Voting and draw (fixes N1, N2, N17)
- Candidates: `VoteCandidateCount` ready, unlocked scenarios drawn from the rotation by weight.
- One vote per member: a scenario **or** Random. Voting for your current choice removes it.
- Draw at T-25: highest vote count wins; ties are broken randomly (v1 behaviour); if Random votes
  **strictly exceed** the best scenario's votes, pick a random ready scenario from the rotation excluding
  the candidates (v2 behaviour, kept); no votes at all → random among candidates.
- If members < drawn `PlayersMin` at the draw: announce, return to `COOLDOWN`, record nothing (no
  `SiegeMatch` row yet). Otherwise create the `SiegeMatch` (`Created`).

### 6.4 Hub and team split
- T-15: snapshot + teleport every member to the hub (§9); joining closes.
- T-10: split into the scenario's N teams. **Snake draft by title bracket** (highest first, alternating
  direction per round) — v1 sorted by title before dealing, v2 shuffled; this keeps shuffling's fairness
  for equal brackets while spreading veterans. Replaces v2's `Partition.ofSize`, which throws when there
  are fewer chunks than teams (e.g. 4 players / 3 teams → chunk size 2 → only 2 partitions →
  `partition.get(2)` out of range).

### 6.5 Match start
Lock scenario → gate lockdown (§8.2) → activate objectives (banner block, capture circle particles
visible to members only, floating percentage `TextDisplay`) and spawn safe-zone rings → teleport each
member to their team's `SortOrder = 0` spawnpoint → per-team scoreboards/tab list → open the spawn
picker for members whose team has ≥ 2 options → team `StartMessage` on the action bar 2 s later →
`SiegeMatch` → `InProgress` (with participants and team assignments).

Match length = `clamp(ceil(members × PerPlayerSeconds), MinSeconds, MaxSeconds)` using the member count
at start (v2 formula, now configurable per scenario).

### 6.6 Death, respawn, spawn choice
- In a match: `keepInventory` + `keepLevel`, no item/XP drops, no vanilla death message (required by D2
  — drops would otherwise duplicate on restore). Killer credit: kill, streak; announce to the killer's
  team at 5/10/15 kills and at streaks > 3 (fixing N12's wrong number); victim +1 death; tab-list suffix
  `[K/D]`.
- Respawn at the member's **current spawn choice** (a team spawnpoint, or a held objective with
  `SpawnWhenHeld`); if that objective has since been lost, fall back to spawnpoint `SortOrder = 0`.
  Respawn restores health/food for both kinds (v2 only did it for spawnpoints).
- After respawn (delay from `SiegeConfiguration`), open the spawn picker when the team has ≥ 2 options
  (v1 rule). Picking an option there teleports immediately **and** becomes the new current choice;
  picking from the Information menu's "Change spawnpoint" only sets the choice. Contested objectives
  (§7.2) can't be picked; checked at click time.

### 6.7 Combat rules (`SiegeCombatListener`, `EntityDamageByEntityEvent` at `HIGHEST`)
Resolve the real attacker (projectile shooter). Then:
- Both members of the same running match: allowed only between **different alliance groups**, and
  denied (cancel + warning sound) when either is inside their own team's spawnpoint safe zone (v2
  rule). The listener un-cancels allowed hits so region PvP flags don't interfere — **no WorldGuard PVP
  flag mutation** (v2 toggled the town region's PVP flag, which leaks to non-players and sticks after a
  crash).
- Member ↔ non-member: always denied.
- Headshot multiplier applies to projectile hits between enemies (configurable; v2's geometry check is
  ported with a null-safe shooter resolution, fixing the NPE in `events-v2.md`).

### 6.8 Leaving, quitting, elimination
- `/siege leave` or disconnect during `HUB`/`IN_PROGRESS`: member removed, votes dropped, participant
  `LeftAt` set, state restored (§9); no rewards.
- A team with zero members **forfeits**; if only one alliance group still has members, it wins
  immediately (`TeamEliminated`). If total members fall below `PlayersMin`, the match ends with
  `NotEnoughPlayers` and normal win resolution (v2 ended the match in this case too).
- No mid-match rejoin after a disconnect in MVP (§13 Q5).

### 6.9 Command filter
While in `HUB`/`IN_PROGRESS`, only `SiegeConfiguration.AllowedCommands` run (v2 declared the list but
never enforced it, N10). Bypass permission `knk.siege.bypass.commands` for staff.

## 7. Capture, win and reward rules

### 7.1 Objective state
Each objective has `Points` (starts at `CapturePoints`, reaches 0 = captured) and a `Holder` team
(`InitialHolderTeamId` or the first Defender team). **Defenders** of an objective = holder + its
alliance; **attackers** = every other alliance. This single rule generalises v1's hardcoded Team1/Team2
and fixes v2's `"cinixians"` literal.

### 7.2 Per-tick capture step (every second, living members within `CaptureRadius`)
`delta = attack − defend` where, with `a` attackers and `d` defenders present:
- `attack = a ≥ 1 ? A1 + (a−1)·A2 : 0`, `defend = d ≥ 1 ? D1 + (d−1)·D2 : 0`
- Legacy constants as defaults: `A1 = 5`, `A2 = 2` (`5` on instant-victory objectives), `D1 = 6`,
  `D2 = 3` (`6` on instant-victory objectives).
- `Points = clamp(Points − delta, 0, CapturePoints)`; defenders therefore restore points.
- **Contested** = at least one living attacker inside the radius (used by the spawn picker, the menu
  and the sidebar). v2 used "delta > 0", which ran a full player scan per menu render (N7).
Both legacy versions carry the author's note that this formula is "probably not working correctly";
making the constants tunables (not code) is the chosen mitigation, with balancing left to playtesting.

**Playtest tuning (developer decision, 2026-09-26, first live playtest on the dev server):** with the legacy
values a lone attacker needed 100 s for a 500-point objective and side objectives scaled weakly with more
attackers, which felt too slow. Considered: lowering a side objective's own `CapturePoints` (per objective,
leaves the main objective alone), a hard-coded side-objective multiplier (rejected: not a tunable), and raising
the shared attack values (chosen). Target: the main objective at 300 points (after a side capture) in about
30 s for one attacker and 15 s for two. **Values in use: `A1 = 10`, `A2 = 2` (side), `A2 = 10` (instant
victory); `D1 = 6`, `D2 = 3`/`6` unchanged.** (7.5 was considered for `A1`; the columns are integers.) Effect,
500 points undefended: main 50/25/17 s for 1/2/3 attackers, side 50/42/36 s; 300 points: main 30/15/10 s.
**Accepted trade-off:** defenders no longer stall equal numbers - 1 v 1 progresses (125 s) and on the main
objective each extra attacker (+10) outweighs each extra defender (+6), so 2 v 2 falls in about a minute.
Holding the main objective now needs more defenders than attackers. These are the dev DB's `SiegeConfiguration`
values; the seeded defaults (web-api) and `KnkSiegeConfiguration.legacyDefaults()` still carry the legacy
5/2/5 · 6/3/6, to be aligned in the Phase 9 seed/balancing pass.

### 7.3 Capture
At `Points = 0`: capturer = the closest living attacker in the radius (legacy rule); holder := the
capturer's team; announcements with sounds to the capturer's alliance ("X captured Y") and to everyone
else ("Lost objective Y"); objective gate → §8.3; participant `Captures + 1`. Then (D5):
- `AllowRecapture = false` (default, legacy): the objective is final and stops scoring.
- `AllowRecapture = true`: `Points` resets to `CapturePoints` with the new holder, and §7.2 continues —
  the former holder's alliance now attacks it. Instant-victory objectives are unaffected (their capture
  ends the match). Each capture writes its own `SiegeMatchObjectiveResult` history entry; the final
  holder is what counts at the end.

### 7.4 Side-capture pressure
Capturing a non-instant-victory objective reduces the `Points` of every **uncaptured** instant-victory
objective by `floor(IV.CapturePoints × SideCaptureReduction / nonInstantVictoryCount)`
(`SideCaptureReduction = 0.4`, the v1/v2 `orig/5*2`). With recapture enabled this applies **only to
an objective's first capture** in a match: no stacking from capture/recapture ping-pong, and no refund
when it's taken back.

### 7.5 Win resolution
1. Capturing an instant-victory objective ends the match: the capturer's **alliance** wins.
2. Time expiry: no IV objective was captured, so every IV objective is still with its initial holder →
   the alliance of those holders wins (normally the defenders — same outcome as v1/v2, without v2's
   name lookup). If IV holders span several alliances, the alliance holding the most objectives wins;
   still tied → the alliance containing a `Defender` team; otherwise a draw (no win reward).
3. No IV objective in the scenario → alliance holding the most objectives at expiry; ties as above.
4. Elimination (§6.8) → the remaining alliance wins. Admin stop / server restart → aborted, no winner,
   no rewards.

### 7.6 Rewards (server-side, idempotent — fixes N3/N4/N13)
`POST /api/siege-matches/{id}/complete` receives final participant stats and objective results; the
service computes and grants rewards in one transaction, marks the match `Completed`, and returns the
per-player breakdown for the in-game message. Repeat calls for a completed match return the stored
result without granting again. For each participant still in the match at the end:
- **Win:** `CoinRewardWin`, `ExpRewardWin`, `GemRewardWin` (gems were defined in v2 but never paid).
- **Holding:** per objective the participant's team holds at the end **and did not hold at the start**
  × `CoinRewardHolding`/`ExpRewardHolding` (generalises v2's attackers-only rule to any team).
- **Capture:** per objective the participant personally captured × `CoinRewardCapture`/`ExpRewardCapture`
  — at most once per participant per objective, so recapture ping-pong can't farm rewards.
- XP is added to `User.ExperiencePoints` (so title brackets advance through the existing
  `TitleService`); coins/gems to `User.Coins`/`User.Gems`. Amounts are stored on
  `SiegeMatchParticipant`. Not written to the admin `AuditLog` (not an admin action); the match rows
  are the audit trail.

## 8. Gates (D3)

### 8.1 Roles in a match

| Gate | Control (open/close) | Damage | On objective capture |
|---|---|---|---|
| Selected (`SiegeScenarioGate`), not an objective | Owner team's alliance only (via the existing gate interaction → `GateDoorInteractEvent`) | Enemies of the owner, if `Damageable` | — |
| Selected **and** referenced by an objective | Owner/holder alliance; ownership moves to the capturer's team | Same as above | Owner := capturer's team; forced to `GateStateOnCapture` (default `OPEN`) — again on every recapture when `AllowRecapture` |
| Any other gate in the scenario's town/districts | Nobody (forced `OPEN`) | Nobody (invincible) | — |

Pass-through is disabled on all affected gates for the match. `AnimateDuringSiege` is honoured for
every state change. Destroyed gates stay destroyed until the match ends (`CanRespawnOverride = false`).
An objective whose gate is destroyed before capture remains capturable at its capture point.

### 8.2 Lockdown at match start
For every affected gate structure: record a `SiegeMatchGateSnapshot` via the API (structure overrides +
each door's open state/health/destroyed), **then** set `CurrentSiegeId`, apply the structure-level
overrides through the existing `PATCH /overrides` path (`IsInvincibleOverride`,
`AllowPassThroughOverride = false`, `OpenedStateOverride`, `CanRespawnOverride = false`) and drive the
runtime state through `GateManager.forceGateState`. `HealthDisplayMode.SIEGE_ONLY` /
`GateInfoDisplayMode.SIEGE_ONLY` light up automatically via `CurrentSiegeId`.

### 8.3 During the match
`SiegeGateListener` handles `GateDoorInteractEvent` (control permission per §8.1, deny message
otherwise) and `GateDoorDamageEvent` (cancel unless an enemy of the current owner damages a
`Damageable` selected gate). Objective capture calls `SiegeGateController.transferOwnership(gate, team,
GateStateOnCapture)`.

### 8.4 Restore and crash safety
At match end: re-apply each snapshot (respawn destroyed doors, restore open state and health, clear the
overrides this match set, `CurrentSiegeId = null`) and delete the snapshot rows. On plugin enable, any
gate whose `CurrentSiegeId` points at a match not `InProgress` in this process is restored from its
snapshot rows, and that match is marked `Aborted/ServerRestart`. Snapshots are written **before** any
change, so a crash mid-lockdown is recoverable.

### 8.5 Scenario-area lockdown and the non-member gate view (D6)
**Lockdown (`LockdownScenarioArea`, default on):** while a match is in `HUB`/`IN_PROGRESS`, non-members
can't enter the scenario's districts, and are moved to the nearest exit at lockdown. Implemented with
the existing region enter/leave infrastructure (`OnRegionEnterEvent`, `Domain.AllowEntry` semantics)
scoped to the match, not by editing `AllowEntry` on the rows.

**Goal (developer, D6):** siege members see and are blocked by the siege gate states. **Everyone else
sees every affected gate exactly as it was before the lockdown.**

**Constraint:** gates are real blocks, and the server validates movement against real blocks for
everybody. So the *physical* world must hold the siege state, and a non-member's pre-lockdown state
can only be a **per-player view** plus movement handling wherever the view and the physics disagree.

**View mechanism** (`SiegeGateViewService`, Paper API only — no ProtocolLib):
- Each door's closed and opened block sets already exist (`GateBlockSnapshot` /
  `GateOpenedBlockSnapshot`, cached on `CachedGateDoor`). The pre-lockdown state comes from the
  `SiegeMatchGateSnapshot` (§8.2). Transient pre-states collapse to a resting state: `OPENING`→open,
  `CLOSING`/`JAMMED`→closed.
- For every affected door whose real state ≠ its pre-lockdown state, send the pre-lockdown block set
  with `Player.sendBlockChanges(…)` to **non-member** viewers within view distance. Re-send it:
  - on lockdown;
  - after every real change of that door, including each `GateAnimationTask` frame (server block
    updates overwrite client-side fakes);
  - on Paper's `PlayerChunkLoadEvent` for chunks holding affected doors;
  - on teleport, respawn and world change;
  - after a non-member's dig/interact on a faked block;
  - when membership changes (joiner → send real blocks; a member who leaves mid-match → send view blocks).
- Members get no fakes. At restore (§8.4) the real state equals the pre-lockdown state again, and real
  blocks are re-sent to every viewer to clear stale fakes.

**Where view ≠ physics:**

| Pre-lockdown | Real (siege) | Non-member sees | Handling |
|---|---|---|---|
| Closed | Open / destroyed (forced open, opened by owners, opened on capture) | Closed gate that the server would let them walk through | **Virtual collision:** cancel/push back non-member movement into the door's closed-state footprint, reusing the gate package's `CollisionPredictor`/`EntityPusher` geometry |
| **Open** | Closed | Open gateway that the server blocks (rubber-banding) | **Temporary pass-through (developer fallback):** non-members walking into it are carried across with the existing `GatePassThroughService` **`TELEPORT`** mode. It doesn't open the real door, unlike `DEFAULT`/`INSTANT_OPEN`, which would affect siege players and must not be used. The ordinary pass-through conditions are waived for the match, because the grant is "this gate was open before the siege". Lockdown still wins: it never carries a non-member *into* a locked-down district |
| Same | Same | Real state | Nothing to do |

Fake blocks don't affect projectiles, mobs or dropped items. That's accepted: non-members can't damage
members anyway (§6.7).

**Degrade switch:** `SiegeConfiguration.NonMemberGateView` = `PreLockdownView` (default, everything
above) | `PassThroughOnly` (no fake rendering: non-members see the siege state, plus the temporary
`TELEPORT` pass-through on gates that were open before the lockdown). `PassThroughOnly` is the
developer's stated minimum, for when the view proves unreliable on a live server (e.g. client desync
during animations).

**Relation to the gate spec:** `REQUIREMENTS_GATE_ADVANCED_FEATURES.md` Feature 4 ("objective gates
open on capture and can be recaptured", 0.5× friendly-fire damage) is superseded for Siege by D3.
`GateStructure.IsSiegeObjective` becomes runtime-maintained (set at lockdown for objective gates,
cleared on restore) and is removed from the gate's admin form (`IMPLEMENTATION_PLAN.md` Phase 2).

## 9. Player state: own gear + restore (D2)

### 9.1 Snapshot
At the hub teleport (T-15), `SiegePlayerVault` captures: inventory storage, armour, off-hand, XP level
and progress, health, food, saturation, active potion effects, game mode, location. The player
**keeps their gear** for the match (nothing is cleared). The snapshot is kept in memory **and** written
to `plugins/KnK/siege-vault/<uuid>.dat` (Bukkit `ItemStack` serialization) before teleporting.

### 9.2 Restore
On match end, leave, or elimination: clear inventory → restore snapshot → teleport back → delete the
vault file. On quit mid-match: inventory is restored inside `PlayerQuitEvent` (still valid there);
the return location is applied on the next join. On join, a leftover vault file with no active
membership (crash, restart) triggers a full restore + teleport.

### 9.3 Duplication guards (required by restore semantics)
While in `HUB`/`IN_PROGRESS`, `SiegeInventoryGuardListener` denies: dropping items; placing items into
any non-player inventory (chests, barrels, shulkers, hoppers, ender chest, item frames, armour stands,
allays); placing shulker boxes or other storage blocks; and trading/crafting outputs that consume
snapshot items into persistent containers. Any of these would let own gear leave the player before the
restore gives it back. Item pickup is already blanket-cancelled for non-OPs in v3
(`PlayerListener.onItemPickup`); Siege additionally cancels it for all members, OPs included, during a
match — **with one exception: siege enchantment books dropped by the member's own match** (§9.4),
which a higher-priority siege handler un-cancels for members of that match only (v2 `onPickup` rule).
Non-members can never pick them up.

### 9.4 Enchant-book drops and post-siege stripping (D7)
**Drops (v2 `SiegeScenario.spawnEnchantments`, kept):** each second, with probability
`EnchantDropChance` (v2: 30‰), one book drops at a random point inside a random objective's capture
radius, if `EnchantDropsEnabled` and fewer than `MaxBooksAlive` are on the ground. Enchantment: random
from `AllowedEnchantmentKeys`, level from `LevelMin`–`LevelMax` (v2: "1 or 2 levels"). The book is
tagged in its `PersistentDataContainer` with `knk:siege_book = <matchId>` and tracked by the runtime.
Books still on the ground are removed at match end (v2 `resetDroppedItems`). v2's random-offset maths
cast the radius to `int` (`nextInt((int) 2.5)`), so books landed within 2 blocks of the centre; v3
samples uniformly in the real radius.

**Applying (no menu needed):** click a siege book held on the cursor onto a target item in your own
inventory (`InventoryClickEvent`). Validity follows vanilla rules (`Enchantment.canEnchantItem`,
conflicts, level cap = max(existing, book level)). The book is consumed. v2 used a
`PlayerEnchantMenu` item picker instead; a menu variant can come later with the other menus.

**Stripping (D7):** the restore (§9.2) already replaces the whole inventory with the pre-siege
snapshot, which removes every siege-applied enchantment and every book. Because the requirement is
explicit, there are two extra guards:
- Every siege application also records itself on the item (`knk:siege_enchants = [{matchId, key,
  previousLevel}]`).
- The restore path and a join-time sweep (a crash, or a failed restore) scan the player's inventory,
  ender chest, and cursor for siege markers without an active match. They revert each recorded
  enchantment to its `previousLevel` (removing it if there was none), remove the marker, and delete
  any stray siege books.
The §9.3 container guards mean marked items can't normally leave the player during a match; the sweep
is defence in depth, not the primary mechanism.

## 10. Menus

Full legacy inventory, engine prerequisites and v3 template drafts: **`MENU_TEMPLATES.md`**. Menus are
documented only. Implementation is blocked on InventoryMenu engine extensions E1–E9 and sequenced last
(`IMPLEMENTATION_PLAN.md` Phase 8).

### 10.1 Menu set
`siege.entry` (button), `siege.overview` (lobbies), `siege.information` (per lobby, per phase),
`siege.spawnpoint` (respawn picker).

### 10.2 Siege-registered menu handlers
Registered through the same registries as `MenuActionHandlers`/`MenuConditionHandlers`/
`MenuContentSourceHandlers`, **before** `MenuDefinitionValidationRunner` runs:
- Actions: `siege.join`, `siege.leave`, `siege.vote`, `siege.vote.random`, `siege.spawn`, `siege.open-own`.
- Conditions: `siege.phase`, `siege.participating`, `siege.join-eligible`, `siege.vote-open`,
  `siege.spawn-available`, `siege.lobbies-empty`.
- Content sources (row sources via `registerRows`): `siege.lobbies`, `siege.vote-candidates`,
  `siege.body` (phase-aware: members before the match, objectives during it), `siege.spawn-options`.
- Registration happens in a `MenuFeature` added to `KnKPlugin`'s feature list (InventoryMenu Phase 9);
  the registries lock before validation, so late registration throws. View/row classes need public
  zero-argument getters. Event-driven refresh:
  `refreshOpenMenus(ctx -> ctx.menuKey().startsWith("siege."))` on join, leave, vote and phase change.
Every menu action calls the **same `SiegeService` method** the matching command calls (Kits §4
"one implementation, multiple entry points"), so command and menu can't diverge (v1's stubbed
`/siege join` vs working menu join; v2's kit menu permission bypass).

### 10.3 View objects (read-only, for `$…$` getter chains)
`SiegeLobbyMenuView` (roots `siege`, `row` in `siege.lobbies`): `getLobbyId`, `getName`, `getPhase`,
`getPhaseLabel`, `getTimerLabel`, `getTimeRemaining`, `getScenarioLabel`, `getMemberCount`,
`getMemberCountOrOne`, `getMemberCountLabel`, `getPlayersMin`, `getPlayersMax`, `getObjectiveCount`,
`getGateObjectiveCount`, `getBannerMaterial`, `getEntryRequirementLine`, `getJoinHintLines`,
`getTeamSummaryLines`, `getRecaptureLine`. `SiegeViewerMenuView` (`siegeViewer`): `getTeamLine`, `getTeamBannerPatterns`,
`getJoinLeaveMaterial`, `getJoinLeaveName`, `getParticipationLine`, `getJoinDenialLine`,
`getCurrentSpawnName`. `SiegeServerMenuView` (`siegeServer`): `getLobbyCount`, `getPlayingCount`,
`getEntryHintLine`. Row views: `SiegeVoteOptionView`, `SiegeBodyRowView` (member or objective row, kind-switching
getters), `SpawnOptionView` (fields listed in `MENU_TEMPLATES.md` C.2–C.4). Views are built from the runtime on
the main thread and hold no Bukkit mutators.

## 11. Commands, permissions, API

### 11.1 In-game commands (`SiegeCommand`)

| Command | Permission | Behaviour |
|---|---|---|
| `/siege` | `knk.siege.play` | Opens `siege.overview` (or your own siege's Information), with a chat fallback list until menus ship |
| `/siege join <lobbyKey>` | `knk.siege.play` | `SiegeService.join` (§6.2) — same checks and denial texts as the menu |
| `/siege leave` | `knk.siege.play` | `SiegeService.leave` |
| `/siege info [lobbyKey]` | `knk.siege.play` | Status in chat; opens Information once menus ship |
| `/siege vote <scenario\|random>` | `knk.siege.play` | Chat-voting fallback until menus ship |
| `/siege spawn [option]` | `knk.siege.play` | Opens the spawn picker / sets the spawn choice |
| `/siege skip <lobbyKey>` | `knk.siege.skip` | Skips cooldown only (v1 donator perk; grantable to a premium group via the permission system) |
| `/siege admin list` | `knk.siege.admin.list` | All lobbies, phases, members |
| `/siege admin start\|stop <lobbyKey> [reason]` | `knk.siege.admin.control` | Start matchmaking now / abort (restore, no rewards) — replaces v2's always-throwing `/siege remove` |
| `/siege admin skip <lobbyKey>` | `knk.siege.admin.control` | v2 `skipStage` semantics, fixed (N9): cooldown → matchmaking; matchmaking → T-31 |
| `/siege admin kick <player>` | `knk.siege.admin.control` | Remove a member (restore applies) |
| `/siege admin reload` | `knk.siege.admin.reload` | Refresh lobby/scenario config for lobbies not in a match |
| `/siege admin manage …` | `knk.siege.admin.manage` | Pointer to the web-app forms (Kits `/kit manage` precedent) |

Plus `knk.siege.bypass.commands` (§6.9). All nodes go through the in-house permission system; no
Bukkit `plugin.yml` permission defaults beyond `knk.siege.play: true`.

### 11.2 API (knk-web-api)
Generic CRUD controllers (following the existing `…Controller` → `…Service` → `…Repository` →
AutoMapper pattern): `Clans`, `BannerDesigns`, `SiegeScenarios` (+ nested teams/spawnpoints/objectives
as owned children), `SiegeLobbies`, `SiegeConfiguration`. Plus:
- `GET /api/siege-scenarios/{id}/readiness`
- `GET /api/siege-lobbies/runtime-config` — enabled lobbies with rotations and fully-resolved ready
  scenarios (team identities resolved from Clans) in one payload for the plugin cache.
- `POST /api/siege-matches` (Created) · `POST /{id}/start` (participants, teams, gate snapshots) ·
  `POST /{id}/participants/{userId}/left` · `POST /{id}/complete` (stats, objective results → rewards)
  · `POST /{id}/abort` · `GET /{id}/gate-snapshots` · `GET /api/siege-matches?userId=&lobbyId=` (history).
- Match write endpoints accept only the plugin's service client (existing plugin-auth/admin-client
  mechanism); CRUD endpoints require admin auth like every other FormConfig entity.

## 12. Legacy defect disposition

| Legacy defect | Addressed by |
|---|---|
| v2 `"cinixians"` scoring + default winner | §7.1 holder-relative defenders/attackers, §7.5 |
| v2 no create path; v1 13-stage chat wizard | §4 FormWizard + WorldTask capture |
| v2 no bootstrap / `"TestSiege"` | §6.1 lobbies |
| v2 `/siege remove` always throws; `/siege edit` stub | §11.1 `/siege admin stop`; CRUD in web app |
| v2 `getGateName` inverted null check; gate FK `optional=false` vs location-only | §3.6 nullable gate + location rule |
| v2 async Bukkit mutation everywhere | §5.3 single sync ticker |
| v1 `/siege join` stub; v2 join paths diverge | §10.2 one service method per operation |
| v1 inconsistent table names | new schema, single migration |
| N1 lowest-voted wins · N2 random vote dead · N17 un-vote NPE | §6.3 |
| N3 XP never paid · N4 attackers-only holding · N13 null winner crash | §7.5, §7.6 |
| N5/N6/N11/N14/N16 menu defects | `MENU_TEMPLATES.md` C.5 |
| N8 "Hide and Seek hub" text · N9 skip NPE · N10 allowed commands unenforced · N12 streak number | §6.2, §11.1, §6.9, §6.6 |
| v2 `Partition` team split throws when teams > chunks | §6.4 snake draft |
| v2 `onDeath` NPE on non-PvP deaths; headshot shooter NPE | §6.6, §6.7 (null-safe killer/shooter) |
| v2 WorldGuard PVP flag toggled on the whole town | §6.7 KnK-owned combat rule |

## 13. Open questions

1. ~~Objective recapture~~ — **resolved (D5):** per-scenario `AllowRecapture`, default `false` (§7.3).
2. ~~Scenario-area lockdown~~ — **resolved (D6):** on, plus the non-member gate view with a
   temporary-pass-through fallback (§8.5).
3. ~~Enchant-book drops~~ — **resolved (D7):** kept; siege-applied enchantments are stripped after the
   siege (§9.4).
4. **"Skilled match" title ranges** (v1 `titleIDMin/Max`). MVP ports only a minimum bracket per
   scenario. Wanted as a lobby-level min/max bracket band?
5. **Rejoin after disconnect** mid-match (keep the slot for N seconds)? MVP: no.
6. **Team chat** during a match (not in either legacy version)?
7. **Siege stats in the player profile** (user-management composite view): add a "Siege" panel from
   `SiegeMatchParticipant` aggregates in a later phase?
8. **Clancastle ownership hook:** should a Clan's win in a scenario flagged as a "clancastle siege" set
   a future `Structure.ControlledByClanId`? Long-term (vision §3.3); the `SiegeMatch` result row is the
   hook either way.
