# Arena duels — Implementation Plan

**Status:** Accepted (developer, 2026-10-21). Not started. All design questions are decided ([DESIGN §13](DESIGN.md#13-decisions-log-and-open-points)); every phase has a Linear issue (table below).
**Last updated:** 2026-10-21 (the knk-plugin branch forks from the KNG-182 branch). 2026-10-21 (rev. 5: duel restrictions in Phase 2/7; phase issues filed). 2026-10-20 (rev. 4: kit vault before the lobby teleport, held deliveries, revert/confiscate; rev. 3: review tiers, `DuelPolicy`, KNG-199 link)
**Linear:** [KNG-197](https://linear.app/kngpandi/issue/KNG-197) (design, parent). Phase issues P0 [KNG-209](https://linear.app/kngpandi/issue/KNG-209), P1 [KNG-210](https://linear.app/kngpandi/issue/KNG-210), P2 [KNG-213](https://linear.app/kngpandi/issue/KNG-213), P3 [KNG-215](https://linear.app/kngpandi/issue/KNG-215), P4 [KNG-217](https://linear.app/kngpandi/issue/KNG-217), P5 [KNG-219](https://linear.app/kngpandi/issue/KNG-219), P6 [KNG-220](https://linear.app/kngpandi/issue/KNG-220), P7 [KNG-221](https://linear.app/kngpandi/issue/KNG-221), P8 [KNG-222](https://linear.app/kngpandi/issue/KNG-222). Related: [KNG-199](https://linear.app/kngpandi/issue/KNG-199) (siege kit mode, reuses the Phase 0 vault and the Phase 4 kit loan), [KNG-182](https://linear.app/kngpandi/issue/KNG-182) (the plugin phases fork from its branch).
**Session handoff:** [ARENA_DUELS_CHAIN.md](../../ai-agents/handoffs/ARENA_DUELS_CHAIN.md) (rules, waves, a coordinator prompt and one prompt per phase).
**Sources:** [DESIGN.md](DESIGN.md) (behaviour, decisions D1–D19, follow-up answers O1–O6).

**Branches:** one standing branch per repo once implementation starts:

| Repo | Branch | Base |
|---|---|---|
| knk-workspace | `claude/kng-197-arena-duels` (exists; docs) | — |
| knk-web-api | `claude/arena-duels` | `master` |
| knk-web-app | `claude/arena-duels` | `main` |
| knk-plugin | `claude/arena-duels` | `claude/mc-26.2-upgrade` (KNG-182), until it merges |

- **The knk-plugin branch forks from the KNG-182 (Minecraft 26.3) branch `claude/mc-26.2-upgrade`** (head `88497649` on 2026-10-21). The developer says the upgrade went smoothly and is only waiting to be merged (2026-10-21). That branch changes `TeleportKind` (adds `HUB`) and the WorldGuard version, which Phases 0 and 4 build on.
- **Once KNG-182 merges into `main`**, merge `main` into `claude/arena-duels`; never rebase. From then on `main` is the base.
- **Build and test** with the KNG-182 toolchain (Java 25, Paper 26.3).

**Build notes:**
- knk-plugin: `./gradlew build -x deployToDevServer`
- knk-web-api: `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`
- knk-web-app: `npm run test:ci`

---

## Phase overview

| Phase | Linear | Repo(s) | What | Depends on | Size |
|---|---|---|---|---|---|
| 0 | [KNG-209](https://linear.app/kngpandi/issue/KNG-209) | plugin | Shared hooks: `MinigameRegistry`, `MinigamePlayerVault` (from `SiegePlayerVault`), `DomainAccessExemptions`; siege migrated, no behaviour change | fork from the KNG-182 branch | M |
| 1 | [KNG-210](https://linear.app/kngpandi/issue/KNG-210) | api, app | Arena domain types (`Arena : Structure`, `ArenaBattleground`, `ArenaSpectatorArea`, `ArenaKit`), duel settings, validation, form configurations, region-kind mapping, `arena_2` seed | — | M–L |
| 2 | [KNG-213](https://linear.app/kngpandi/issue/KNG-213) | api | `DuelMatch`, service and endpoints; currency reasons; eligibility and abuse limits; `DuelPolicy`, signals and escalation tiers through the currency alert pipeline; abort-unfinished; anomaly rules | Phase 1 | L |
| 3 | [KNG-215](https://linear.app/kngpandi/issue/KNG-215) | core | Pure rules: offer book, contract validation, state machine, combat rules, battleground allocator and queue, escrow states, review-agnostic settlement effects | — (parallel with 1–2) | M |
| 4 | [KNG-217](https://linear.app/kngpandi/issue/KNG-217) | plugin | Duel runtime: ticker, teleport kinds, restrictions, combat/death/quit listeners, battleground exemption and confinement, escrow spool and recovery, gear modes (kit loan, drop spoils) | 0, 2, 3 | L |
| 5 | [KNG-219](https://linear.app/kngpandi/issue/KNG-219) | plugin | Proposal editor, offer view, chat offers, `/duel` and `/arena` commands, kit picker | 4 | M |
| 6 | [KNG-220](https://linear.app/kngpandi/issue/KNG-220) | api (seed) + plugin | Announcements, sidebar and boss bar, `/duels` and `/arena` menus, spectator-area hooks | 4 | M |
| 7 | [KNG-221](https://linear.app/kngpandi/issue/KNG-221) | api, app | Statistics (`duel` context, projector, visibility default); web-app duel history and review page | 2 | M |
| 8 | [KNG-222](https://linear.app/kngpandi/issue/KNG-222) | all | Dev-server smoke test, docs, merge | 1–7 | M |

Phases 0, 1 and 3 can run in parallel. Phases 5–7 can run in parallel after 4 (7 after 2).

---

## Phase 0 — Shared hooks (plugin, no behaviour change)

**Linear:** [KNG-209](https://linear.app/kngpandi/issue/KNG-209)

- **Minigame registry**:
  - `knk-core/.../core/minigame/MinigameParticipation` port (DESIGN §11) + `MinigameRegistry` composite
  - `SiegeParticipation` adapter
  - every siege lambda in `KnKPlugin` replaced by a registry call:

    | Touchpoint | Line(s) |
    |---|---|
    | safezone | 898 |
    | statistics context | 1328 |
    | headshots | 1361 |
    | discovery | 1406 |
    | navigation | 1559 |
    | outage | 2635 |
    | `/hub` | 2672 |
    | domain-access respawn | 2776 |
    | lootbox | 2965, 3080 |
    | scoreboard | 3423 |
    | teleport restriction, `BackDeathExclusion` | 3430–3431 |

  - `ScoreboardUtil.setKeepOwnScoreboard` and `HubOutageService` take the registry
- **`MinigamePlayerVault`**:
  - extract `SiegePlayerVault`'s snapshot, restore, quit and join logic into a vault keyed by `(minigame, matchToken)`
  - siege keeps its file location (`siege-vault/`), so existing files still restore
- **`DomainAccessExemptions`**: an entry/exit exemption and confinement port consulted by `DomainAccessHandler` before refusing or allowing a crossing. It is empty by default.
- **Tests**:
  - registry composition
  - vault round-trip, including old siege files
  - handler with and without exemptions
  - all existing siege tests stay green
- **Live check**: one siege round (outage release, `/hub` refusal, safezone enchant effects, vault restore after a quit).

## Phase 1 — Arena domain types and settings (API + web app)

**Linear:** [KNG-210](https://linear.app/kngpandi/issue/KNG-210)

- **Models (TPT, like `GateStructure`)**:
  - `Models/Arena/Arena.cs : Structure` (table `arenas`) with lobby/exit locations and the duel settings (DESIGN §4.2)
  - `ArenaBattleground.cs : Domain` (`arena_battlegrounds`; `ArenaId` cascade, spawn A/B `Restrict`, `AllowEntry` default false)
  - `ArenaSpectatorArea.cs : Domain` (`arena_spectator_areas`)
  - `ArenaKit` join (`arena_kits`, `KitId` `Restrict`)
  - migration `AddArenas`
- **Validation (service)**:
  - at least one gear mode allowed
  - a kit mode needs at least one eligible kit
  - `DefaultGearMode` must be allowed
  - ranges: `MaxOffers` 1–6, `FeePercent` 0–20, `MinStakeRatioPercent` 0–100, `FightTimeLimitSeconds` ≥ 0
  - a battleground's spawns must lie in its own world
- **Code layers**:
  - DTOs, AutoMapper, repositories, services
  - `ArenasController` (+ battlegrounds, spectator areas)
  - GET for plugin and logged-in users; writes `[RequireServiceOrPermission(StaffPermissions.ManageWorld)]`
  - `EndpointAccessRulesTests` updated
- **Domain plumbing**:
  - `IDomainRegionNameFinalizer` handles the three types, with the right parents (District → Arena → children)
  - `DomainNavigationDefault` / discovery defaults: battlegrounds off
- **Default `FormConfiguration`s** (KNG-139 pattern):
  - Arena in steps: General, Negotiation & stakes, Eligibility & abuse limits, Gear & kits, Timing & queue, Announcements
  - Battleground form
  - Spectator-area form (reuses the domain warp fields)
- **Seed** `arena_2` + 8 battlegrounds (region ids from `reports/2026-09-28-v1-permissions-worldguard-inventory.md`). Staff fill in district/street and locations.
- **Plugin read side**:
  - `ArenasApi` port + api-client implementation
  - cache-first gateway in `DataAccessFactory`
  - region-kind mapping for the managed-region repair (Arena → `ARENA`, battleground → `BATTLEGROUND`, spectator area → plain child)
  - `BATTLEGROUND` policy without `entry deny` (DESIGN §8.2)
- **Docs**: update `managed-worldguard-regions.md` §3/§5/§8 and comment on KNG-49.
- **Tests**:
  - API: CRUD, validation, access rules, FK restrict, finalizer parents
  - plugin: mapping, policy change, cache
  - web app: the forms render (form-config snapshot)

## Phase 2 — Match record, stake ledger, abuse limits (API)

**Linear:** [KNG-213](https://linear.app/kngpandi/issue/KNG-213)

- **Model and enums**:
  - `Models/Duel/DuelMatch.cs` (DESIGN §4.3)
  - `Enums/DuelEnums.cs` (`DuelMatchStatus`, `DuelEndReason`, `DuelGearMode`, `DuelReviewState`, strings)
  - migration `AddDuelMatches`, unique `PublicToken`
- **Currency**:
  - `DUEL_STAKE`, `DUEL_PAYOUT`, `DUEL_FEE`
  - `SYS_DUEL`
  - settle how the fee leaves `SYS_DUEL` against the ledger's leg rules (DESIGN §7.1)
  - reconcile invariant Σ `SYS_DUEL` = 0 per closed match
- **`DuelEligibility`**:
  - reuse `TransferPolicyEvaluator.CheckEligibility` with the arena's overrides (account age, title), always with the freeze and transfer-lock checks
  - pair-per-day, pair cooldown, daily coin-win cap, stake ratio
  - gems refused
- **`DuelMatchService`** (shape of `SiegeMatchService`):

  | Method | Behaviour |
  |---|---|
  | `CreateAsync` | eligibility + limits; insert + two-leg `DUEL_STAKE` posting, key `duel-lock:<token>`; idempotent on token |
  | `StartFightAsync(id, battlegroundId)` | idempotent |
  | `CompleteAsync(id, winner, reason, telemetry)` | `RunLockedAsync`. Derives signals S1–S6 and the tier (`DuelReviewRules`, pure, thresholds from `DuelPolicy`; DESIGN §10.3). Tier 2 holds; tier 0/1 pays (`duel-payout:<id>`) and takes the fee; tier 1/2 raise a `DUEL_FLAG` / `DUEL_HOLD` `CurrencyAlert`. Returns `paid` / `held` |
  | `CancelAsync(id, reason)` | reverse once; cancel, abort or draw status by reason |
  | `ReleaseAsync(id, staff)` / `VoidAsync(id, staff)` | held → paid / refunded; audited |
  | `RevertAsync(id, staff, reason, confiscate)` | paid → reversed (DESIGN §10.3); returns what was recovered and what is still missing; the plugin is told to return or destroy undelivered items |
  | `AbortUnfinishedAsync()` | |
  | `GetByTokenAsync` | |

- **`DuelMatchesController`**:
  - writes `[RequirePluginService]`
  - review actions `[RequirePermission(StaffPermissions.…)]` (new node `knk.admin.duel.review`, matched by `knk.admin.*`)
  - GETs for logged-in users
  - `EndpointAccessRulesTests` updated
- **`DuelPolicy`** singleton (web-app editable, like `CurrencyPolicy`): signal thresholds, `EscalationFlagCount`, `EscalationWindowDays`, the funnel rule. A first flag never holds (developer). Escalation counts exclude flags whose alert was acknowledged as a false positive. While a hold is open, value-moving invites for that pair or beneficiary are refused (checked in `CreateAsync`). **`DuelRestriction`** (DESIGN §10.3, P1): stakes-only scope, for a player or a pair, optional `ExpiresAt`, reason and staff member. `CreateAsync` refuses a value-moving duel when either player (or the pair) has an active restriction, through the same path as an open hold. Staff create/lift endpoints `[RequirePermission(knk.admin.duel.review)]`; audited.
- **Alerts**: tier 1 and tier 2 go through `ICurrencyAlertService` with new rule codes, so the web alerts page, the acknowledge flow and the in-game `CurrencyAlertNotifier` show them unchanged.
- **Anomaly detector**:
  - R3 and R4 take `DUEL_PAYOUT` as a flow from loser to winner
  - a per-pair duel rule
  - `DUEL_PAYOUT` excluded from R7
- **Tests**:
  - all-or-nothing stake
  - gem refusal
  - each eligibility and limit refusal
  - the ratio rule
  - each signal; tier 0/1/2; a first flag never holds; acknowledged flags don't count; escalation by pair and by beneficiary; invites refused while a hold is open
  - revert and confiscate on a paid result: partial reversal when coins were spent, the loser refunded first, the fee reversed (revert only), `Review=Voided`, audited
  - idempotent create/complete/cancel/release/void
  - 409 paths
  - fee rounding
  - Σ `SYS_DUEL` = 0 after every end path
  - held → release/void
  - abort-unfinished leaves held matches alone
- **Plugin side**: `DuelMatchesApi` port + api-client implementation with `Idempotency-Key` headers.

## Phase 3 — Core rules (knk-core, Bukkit-free)

**Linear:** [KNG-215](https://linear.app/kngpandi/issue/KNG-215)

- **`core/duel/` classes**:

  | Class | Responsibility |
  |---|---|
  | `DuelOfferBook` | negotiations, offer ids and versions, turn order and `MaxOffers`, expiry, incoming/outgoing limits, cooldown, `/duel toggle`, forget on quit |
  | `StakeContract` + validation | gear mode allowed, fixed kit eligible, coin bounds and ratio, "only the owner adds items", stack limits, blocklist predicate |
  | `DuelPhase`, `DuelStateMachine` | returns `DuelEffect`s; end-once guard; agreed-draw window; time limit 0 = none; kit-choice deadline |
  | `DuelCombatRules.decide` | DESIGN §8.1 |
  | `BattlegroundAllocator` + `ArenaQueue` | free/busy, FIFO, `MaxQueuedMatches`, `MaxWaitSeconds` |
  | `DuelEscrowState` | including `HELD` and spoils |

- **Tests**:
  - every transition and the abort path at each phase
  - `MaxOffers` 1/2/3/4
  - a stale offer id refused
  - death + quit on the same tick → one result
  - simultaneous death → draw
  - agreed draw needs both players inside the window
  - queue cap and wait timeout
  - kit default at the deadline

## Phase 4 — Duel runtime (plugin)

**Linear:** [KNG-217](https://linear.app/kngpandi/issue/KNG-217)

- **Service and teleports**:
  - `DuelService`: 1 s ticker that applies effects and reports to the API asynchronously; it never blocks on HTTP
  - `DuelParticipation` in the registry
  - `TeleportKind.ARENA` (player warmup, no cooldown or charge) and `ARENA_SYSTEM` (instant, safe-spot, no audit); update `WarmupPolicy` and the `TeleportService` kind branches
  - the lobby teleport runs `allOf` over two futures
- **Restrictions and filters**: `DuelTeleportRestriction`, `DuelCommandFilterListener`, `DuelInventoryGuardListener`.
- **Combat**:
  - `DuelCombatListener` (HIGHEST)
  - `DuelWorldGuardPvpListener` (`DisallowedPVPEvent`)
  - the registry combat exemption
- **Battleground access**:
  - `DuelBattlegroundAccess` registers exemptions and confinement in `DomainAccessExemptions` (entry for the allocated pair, exit refused in COUNTDOWN/FIGHT, a one-shot pass for the exit teleport)
  - the countdown freeze
- **Gear modes** (DESIGN §8.4–8.5):
  - snapshot and restore of health, food and effects
  - kit loan: the vault is written in the lobby teleport's commit step (a pre-commit hook on `TeleportPlan`) and restored at once if the move fails. The kit is granted on arrival (`KIT_CHOICE`: placeholder, swapped on pick, locked at the countdown) through `KitGrantPlacer` with the `knk_duel_loan` PDC tag. Restore on ENDING, cancel/abort, quit, outage and join after a crash; the loan sweep on join and at end
  - kit consumables blocked in WARMUP
  - pending deliveries: `holdsLootDrops` from LOCKING until the restore. A spinning lootbox reel's item and other item deliveries are held and handed over after the restore; opening a lootbox during a match is refused
  - drop-mode spoils captured in the death event; forfeit spoils at quit (O2)
  - kit grants skip the kit's own access check (O4)
- **Death, respawn and quit**: `DuelDeathRespawnListener` and `DuelSessionListener` (quit = cancel or forfeit by phase; join = restore and deliver what's owed).
- **Escrow**:
  - `DuelEscrowSpool`: per-match YAML, atomic writes, the delivery chain inventory → ender chest → `CLAIM_PENDING`, and the `HELD` state
  - `pending-results/` replay
  - startup recovery (DESIGN §7.3)
- **Siege**: `joinDenial` refuses duelists.
- **Tests**:
  - the combat listener matrix
  - escrow round-trips:
    - crash in LOCKING → items back
    - ESCROWED + Aborted → back
    - Completed → winner
    - HELD → kept, then release/void
  - kit loan: the inventory comes back identical after a fight, a failed lobby teleport, a quit, an API outage and a crash; no loaned item survives
  - a lootbox reel finishing mid-match: its item is delivered after the restore, never into the kit or the spoils
  - drop spoils written to the spool before the drops are cleared
  - **test hygiene**: keep a mocked `World` in a field (CLAUDE.md rule)

## Phase 5 — Negotiation UI and commands (plugin)

**Linear:** [KNG-219](https://linear.app/kngpandi/issue/KNG-219)

- **Commands**:
  - `/duel` tree and `/arena` (DESIGN §6.1)
  - registered in `plugin.yml` and `CommandNodes`
  - `knk.duel` (default true); staff `/knk duel …` with `knk.admin.duel`
- **`DuelProposalEditor`**:
  - hand-rolled 54-slot inventory with its own holder; every click cancelled
  - gear-mode cycle limited to the arena's allowed modes
  - kit picker for `FIXED_KIT`
  - items added by clicking stacks in your own bottom inventory
  - coin +/- buttons and anvil input
  - fee, eligibility and limit warnings
- **`DuelOfferView`**: read-only, with Accept / Counter / Decline.
- **Chat offer notices**: clickable, id-stamped, a 10 s expiry warning; drop mode in capitals.
- **`KIT_CHOICE` picker in warmup** (menu + chat prompt), with the opponent's pick shown.
- **The lock-in sequence** (DESIGN §6.5).
- **Tests**:
  - editor click handling
  - lock-in with a moved item → refused, nothing taken
  - API refused → items returned
  - a gear mode the arena doesn't allow can't be selected

## Phase 6 — Announcements, menus, spectating (API seed + plugin)

**Linear:** [KNG-220](https://linear.app/kngpandi/issue/KNG-220)

- **`DuelAnnouncer`**: templates, cooldown, `[Spectate] [Details]`; held results say "pending review".
- **Duel sidebar and boss bar**: for duelists and for players inside the arena's spectator area.
- **Menu templates**, seeded in knk-web-api (`MenuTemplateSeed`):
  - `duel_matches`
  - `duel_match_detail`
  - `arena_main`: info, live matches, queue, `[Spectate]`, `[Challenge a player]`, `[My claims]`, rules
- **`DuelMenuFeature`**:
  - variable roots for arena, match and stakes; row sources for live matches and online players
  - actions: open detail, spectate, challenge
  - the "spectate" action starts the spectator area's **warp**, so the teleport engine and the domain's warp conditions apply
  - `refreshOpenMenus` on phase changes
- **Tests**: the pure views; the announcer cooldown; the spectate action uses the warp path (conditions enforced).

## Phase 7 — Statistics and web-app pages (API + app)

**Linear:** [KNG-221](https://linear.app/kngpandi/issue/KNG-221)

- **Statistics (API)**:
  - `DuelStatisticsProjector`: wins, losses and draws from `duel_matches`; a forfeit is a loss; cancelled and aborted count nothing; held matches count once decided
  - registered in `StatisticsProjectionService`
  - `duel` in the projection-owned guard
  - visibility default `everyone` for `wins/losses/draws@duel` (D17); players change it in the normal statistics settings
- **Statistics (plugin)**: `StatisticsContextResolver` returns `duel` through the registry.
- **Web app**:
  - "Duels" admin page: history with filters (arena, player, status, review), match detail (stakes, spoils, telemetry, flags)
  - Release / Void on held matches, Revert / Confiscate on paid ones, clear escalation, duel restrictions per player or pair (`knk.admin.duel.review`)
  - `DuelPolicy` settings page
  - duel alerts appear on the existing currency alerts page (new rule codes only)
- **Tests**: the projector; plugin-posted `wins@duel` refused; web-app page tests (`npm run test:ci`).

## Phase 8 — Smoke test, docs, merge

**Linear:** [KNG-222](https://linear.app/kngpandi/issue/KNG-222)

**Dev-server smoke test.** Two accounts plus a spectator. The arena is in a town with `pvp deny`.

1. **Settings**: the Arena form saves and validates; change `MaxOffers` to 2 and see it apply in-game.
2. **Negotiation**: invite, counter, accept at `MaxOffers` 3; a stale button can't accept; expiry; decline; `/duel toggle`.
3. **Refusals**: accepting while combat-tagged, or while in a siege lobby, is refused.
4. **Lock-in**:
   - one player broke → refused, nothing taken
   - the ratio rule
   - an item moved away → refused
   - both stakes taken; the ledger shows `DUEL_STAKE` ×2
5. **Queue cap**: fill the arena to `MaxQueuedMatches` → the next accept is refused.
6. **Lobby teleport**: a player moves during warmup → cancelled, refund visible in the history.
7. **Warmup**:
   - the announcement
   - the spectator menu shows stakes, kit and stats
   - `/spawn` and `/hub` refused
   - duelists can't hit or be hit
   - kit choice
8. **Spectator area**: reached on foot, via `/warp`, and via the arena menu; a title or price condition on the warp is enforced.
9. **Countdown**: frozen, no damage, 10 s titles and sounds; the kit is loaned and the inventory vaulted.
10. **Fight**:
    - PvP works inside the no-PvP town, potions included
    - spectators can't interfere
    - custom enchantments fire
    - pearling out is refused
    - a non-duelist can't walk in
11. **Results, each mode**:
    - keep: the loser keeps their gear
    - drop: the winner receives the loser's inventory through the claim chain
    - kit: both inventories come back identical; no loaned item left
    - fee taken (5%)
12. **Forfeit, draws, time limit**:
    - a quit during the fight → the opponent wins (and in drop mode gets the quitter's inventory)
    - agreed draw
    - time limit 30 s → draw and full refund
    - time limit 0 → no limit
13. **Review**:
    - one thrown fight → paid, flagged; the alert shows in the web app and in game for staff
    - a second flagged result between the same players → held; a new staked invite between them is refused
    - release in the web app → paid; void on another → refunded
    - acknowledging a flag as a false positive stops it from counting
14. **Recovery**:
    - crash: `kill -9` mid-fight → restart refunds; items and vault restored on join
    - outage: API stopped mid-warmup → items back at once, coins refunded when the API returns
15. **Concurrency and stats**: two matches on two battlegrounds plus one waiting; duel W/L visible by default, and hidden after the player changes visibility.

**Docs**:
- a new guide `docs/guides/arena-duels.md` (admin setup: arena domain, battlegrounds, spectator area and warp, settings, kits; player how-to)
- the register row
- `specs/README.md`
- `CHANGELOG.md` at merge
- `managed-worldguard-regions.md`, `domain-access-enforcement.md` (exemptions)
- teleport DESIGN (new kinds)

**Merge**: after the developer's live sign-off, per the global workflow.

---

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| `DomainAccessHandler` exemption misses an entry path (vehicle, elytra, pearl) | the handler already covers these for domains; smoke-test step 10 tries each |
| Un-cancelling at HIGHEST misses PvP paths | `DisallowedPVPEvent` handler + `pvp allow` on battlegrounds; smoke test covers potions |
| Thrown duels to move value | eligibility, caps, ratio rule, fee, pair and daily limits, telemetry flags, review hold, anomaly rules (DESIGN §10) |
| Item duplication or loss through escrow, spoils or the kit vault | items never move during negotiation; the spool is written before every change; idempotent delivery tracked per stack; loaned items tagged and swept |
| Siege regressions from Phase 0 | a no-behaviour-change PR with the existing siege tests + a short siege live check |
| A large Arena form | form steps per settings group; sensible defaults so a new arena works untouched |
| Plugin branch drifts from the KNG-182 upgrade | fork from `claude/mc-26.2-upgrade`; merge `main` once KNG-182 lands |
