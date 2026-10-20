# Arena duels — Implementation Plan

**Status:** Draft. Not started; waits on the developer's answers to [DESIGN §13](DESIGN.md#13-open-questions-for-the-developer). Implementation issues get filed per phase once the decisions are taken.
**Last updated:** 2026-10-20
**Linear:** [KNG-197](https://linear.app/kngpandi/issue/KNG-197) (design). Phase issues: to be filed.
**Sources:** [DESIGN.md](DESIGN.md) (behaviour, decisions D1–D15, open questions Q1–Q11).

**Branches:** one standing branch per repo once implementation starts:
- `claude/kng-197-arena-duels` in knk-workspace (exists; docs only)
- `claude/arena-duels` in knk-web-api (from `master`) and knk-plugin (from `main`)

The **knk-plugin branch must start after the KNG-182 (Minecraft 26.3) branch `claude/mc-26.2-upgrade` merges**. That branch changes `TeleportKind` (adds `HUB`) and the WorldGuard version, and Phase 3 touches both. If duels start first, base the plugin branch on `claude/mc-26.2-upgrade` and merge `main` once it lands.
**Build notes:** knk-plugin `./gradlew build -x deployToDevServer`; knk-web-api `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`.

---

## Phase overview

| Phase | Repo(s) | What | Depends on | Size |
|---|---|---|---|---|
| 0 | plugin | `MinigameParticipation` registry; migrate the siege touchpoints (no behaviour change) | KNG-182 merged | S–M |
| 1 | api, app (forms only) | `Arena`, `ArenaBattleground` config entities, form configs, seed `arena_2` | Q2 | M |
| 2 | api | `DuelMatch` + service + endpoints; currency reasons and `SYS_DUEL`; eligibility; abort-unfinished; anomaly rules | Phase 1, Q6/Q7 | M–L |
| 3 | core + plugin | Pure core: offer book, state machine, combat rules, battleground allocator; plugin runtime: ticker, teleport kinds, restrictions, combat/death/quit listeners, WG membership, escrow spool + recovery | Phases 0–2 | L |
| 4 | plugin | Stake editor, offer view, chat offers, `/duel` commands | Phase 3 | M |
| 5 | api (seed) + plugin | Announcements, boss bar / sidebar, `/duels` spectator menu, spectator teleport | Phase 3 | M |
| 6 | api | Statistics: `duel` context, `DuelStatisticsProjector`, visibility default | Phase 2, Q9 | S |
| 7 | all | Dev-server smoke test, docs (guide, register, changelog), merge | 1–6 | M |

Phases 1–2 (API) and 0 (plugin refactor) can run in parallel. Phases 4–6 can run in parallel after Phase 3.

---

## Phase 0 — Minigame participation registry (plugin)

**Goal:** one place where features ask "is this player in a minigame, and what does that allow?". Today siege is wired as a single lambda at each touchpoint (DESIGN §10).

- `knk-core/.../core/minigame/`:
  - `MinigameParticipation` port: `participationOf(UUID)`, `allowsCombat(UUID attacker, UUID victim)`, `releaseForOutage(UUID)`, `holdsLootDrops(UUID)`, `keepsOwnScoreboard(UUID)`, `teleportRefusal(UUID, TeleportKind)`
  - `MinigameRegistry` composite with first-match semantics
- `SiegeService` gets a `SiegeParticipation` adapter.
- Replace each siege lambda in `KnKPlugin` with a registry call:

  | Touchpoint | Line(s) |
  |---|---|
  | enchant safezone exemption | 898 |
  | statistics context | 1328 |
  | headshots | 1361 |
  | discovery | 1406 |
  | navigation | 1559 |
  | outage | 2635 |
  | `/hub` | 2672 |
  | domain-access respawn | 2776 |
  | lootbox | 2965, 3080 |
  | scoreboard | 3423 |
  | teleport restriction + `BackDeathExclusion` | 3430–3431 |

- `ScoreboardUtil.setKeepOwnScoreboard` and `HubOutageService` take the registry.
- **Tests:** composite semantics; existing siege tests unchanged and green.
- **Live check:** a siege round still behaves the same (outage release, `/hub` refusal, safezone enchant effects).

## Phase 1 — Arena configuration (API)

- **Models:**
  - `Models/Arena/Arena.cs` and `ArenaBattleground.cs` (DESIGN §4.1), `[FormConfigurableEntity]`
  - Location FKs `Restrict`; battleground → arena `Cascade`
  - unique `Arena.Key`, unique `(ArenaId, Key)`
- Migration `AddArenas`.
- **Code layers:**
  - DTOs, AutoMapper profile, repository, service, `ArenasController`
  - GET for the plugin and logged-in users; writes `[RequireServiceOrPermission(StaffPermissions.ManageWorld)]` (`knk.admin.world`)
  - add the write endpoints to `EndpointAccessRulesTests`
- Default `FormConfiguration`s for both entities (KNG-139 pattern) so staff can edit them in the web app.
- **Seed** `arena_2` with its 8 flagged battlegrounds. Region ids come from the 2026-09-28 v1 WG inventory report. Locations are left for staff to set in-game with `/knk location`.
- **Plugin read side:** an `ArenasApi` port + api-client implementation + cache-first gateway in `DataAccessFactory`.
- **Managed regions:** the reconciler takes arena and battleground region ids from the entities (in addition to `extra-regions`). Update `docs/architecture/managed-worldguard-regions.md` §3/§8 and comment on KNG-49.
- **Tests:**
  - API: CRUD, access rules, FK restrict
  - plugin: mapping and cache

## Phase 2 — Match record and stake ledger (API)

- **Models:**
  - `Models/Duel/DuelMatch.cs` (DESIGN §4.2)
  - `Enums/DuelEnums.cs` (`DuelMatchStatus`, `DuelEndReason`, stored as strings)
  - migration `AddDuelMatches`
  - unique `PublicToken`
- **Currency:**
  - add `DUEL_STAKE`, `DUEL_PAYOUT` and the reserved `DUEL_FEE` to `CurrencyReasons`
  - add the `SYS_DUEL` system account
  - extend the reconcile invariant
- **`DuelMatchService`** (copy the `SiegeMatchService` shape):

  | Method | Behaviour |
  |---|---|
  | `CreateAsync` | One transaction: eligibility via `TransferPolicyEvaluator.CheckEligibility` for each non-zero staker. Then an insert plus a `PostAsync` with two debit legs, key `duel-lock:<token>`. Idempotent on `(PublicToken)`. |
  | `StartFightAsync(id, battlegroundId)` | Created → InProgress; idempotent. |
  | `CompleteAsync(id, winner, reason, summary)` | Under `RunLockedAsync`: Completed → stored result; Cancelled/Aborted → 409; else `GrantAsync` with key `duel-payout:<id>`. |
  | `CancelAsync(id, reason)` | `ReverseAsync(stakeTx)` with key `reverse:<txId>`. Status set to Cancelled / Aborted / Completed-draw by reason. Idempotent. |
  | `AbortUnfinishedAsync()` | Startup cleanup. |
  | `GetByTokenAsync` | Used by the plugin's timeout recovery. |

- **`DuelMatchesController`**:
  - every write `[RequirePluginService]`; `GET /` and `GET /{id}` for logged-in users
  - add to `EndpointAccessRulesTests`
- **Anomaly detector:**
  - R3/R4 consider `DUEL_PAYOUT` funded by the opponent's stake
  - new per-pair rate rule (DESIGN §7.1)
- **Tests:**
  - all-or-nothing stake (one side broke → nothing posted, no row)
  - gem refusal
  - eligibility refusal
  - idempotent create/complete/cancel
  - cancel after complete → 409
  - complete after cancel → 409
  - Σ `SYS_DUEL` = 0 after cancel and after complete
  - abort-unfinished refunds
- **Plugin side:** a `DuelMatchesApi` port + api-client implementation with `Idempotency-Key` headers.

## Phase 3 — Core rules and duel runtime (core + plugin)

**knk-core (`core/duel/`, Bukkit-free, unit-tested):**
- `DuelOfferBook`: negotiations, offer ids/versions, the turn order and `max-offers`, expiry, the incoming/outgoing limits, the cooldown, and forget-on-quit. Generalised from `TeleportRequestBook`.
- `StakeContract` and its validation: bounds, the "only the owner adds items" rule, the blocklist, and stack limits.
- `DuelPhase` and `DuelStateMachine`: `tick(now)`, `onTeleportOutcome`, `onDeath`, `onQuit`, `onOutage`, `cancel(reason)`. These return `DuelEffect`s (the `SiegeEffect` pattern). The machine also guards that each match ends exactly once.
- `DuelCombatRules.decide` (DESIGN §8.1 table).
- `BattlegroundAllocator`: free/busy per battleground and a FIFO wait list.
- `DuelEscrowState` transitions (spool states, DESIGN §7.2).

**knk-paper (`paper/duel/`):**
- **Service and teleports:**
  - `DuelService`: a 1 s ticker that applies effects and reports to the API asynchronously; it never blocks on HTTP.
  - `TeleportKind.ARENA` (player warmup, no cooldown or charge) and `ARENA_SYSTEM` (instant, safe-spot, no audit). Update `WarmupPolicy` and the `TeleportService` kind branches.
  - The lobby teleport runs `allOf` over two futures.
- **Restrictions and filters:**
  - `DuelTeleportRestriction` (all other teleports refused from LOCKING to ENDING)
  - `DuelCommandFilterListener`
  - `DuelInventoryGuardListener`
- **Combat:**
  - `DuelCombatListener` (HIGHEST un-cancel and deny)
  - `DuelWorldGuardPvpListener` (`DisallowedPVPEvent`)
  - registered in `MinigameRegistry` for the safezone exemption
- **Death, respawn, quit and movement:**
  - `DuelDeathRespawnListener` (keepInventory, exit respawn, `/back` exclusion)
  - `DuelSessionListener` (quit → cancel or forfeit by phase; join → restore and deliver owed items)
  - countdown freeze and battleground confinement (move, pearl/chorus, vehicle)
- **Battleground membership:** `BattlegroundMembership` adds and removes the WG members, with a startup sweep.
- **Escrow:**
  - `DuelEscrowSpool`: per-match YAML, atomic writes, the item delivery chain inventory → ender chest → `CLAIM_PENDING`
  - `pending-results/` replay
  - startup recovery (DESIGN §7.3)
- **Registration:** `DuelParticipation` is registered in `MinigameRegistry`. Siege `joinDenial` refuses duelists.
- **Config:** the `duels:` block (DESIGN §12).
- **Tests:**
  - **Core:** every phase transition and the abort path at each phase; the turn limit for `max-offers` 2/3/4; that a stale offer id can't be accepted; the end-once guard (death + quit on the same tick → one result); a simultaneous death is a draw.
  - **Plugin:**
    - the combat listener matrix
    - the escrow spool round-trip: crash in LOCKING → items back; crash in ESCROWED → items back after the API says Aborted; Completed → winner
    - the lock-in check that items are still present
  - **Test hygiene:** keep a mocked `World` in a field (CLAUDE.md rule).

## Phase 4 — Negotiation UI and commands (plugin)

- `/duel` command tree (DESIGN §6.1). Register it in `plugin.yml` and `CommandNodes`. The permission is `knk.duel` (default true); the staff command is `/knk duel …` with `knk.admin.duel`.
- `DuelStakeEditor`: a hand-rolled 54-slot inventory with its own holder and every click cancelled. You add items by clicking stacks in your own bottom inventory. It has coin +/- buttons and anvil input for an exact amount (`AnvilCaptureManager`).
- `DuelOfferView`: the same layout, read-only, with Accept / Counter / Decline.
- Chat offer notices: clickable and id-stamped, with an expiry warning at 10 s. A reminder is sent when the turn passes to the other player.
- The lock-in sequence (DESIGN §6.4): main-thread item take, spool write, async API create, then compensation on refusal or timeout.
- **Tests:** editor click handling (bottom-inventory add, top remove, every click cancelled); lock-in with a moved item → refused, nothing taken; API refused → items returned.

## Phase 5 — Announcements and spectating (API seed + plugin)

- `DuelAnnouncer`: config templates and a cooldown; clickable `[Spectate] [Details]`.
- Duel sidebar and boss bar for duelists and nearby spectators. The scoreboard predicate goes through the registry.
- Menu templates `duel_matches` and `duel_match_detail`, seeded in knk-web-api (`MenuTemplateSeed`).
- `DuelMenuFeature`: variable roots for a match and its stakes, a row source for live matches, and actions for opening the detail and teleporting to the spectator stand. It is built like `SiegeMenuFeature` / `StatisticsMenuFeature`, and runs `refreshOpenMenus` on every phase change.
- The spectator teleport is an engine `WARP`-style player teleport to `SpectatorLocation`.
- **Tests:** the menu views (pure); the announcer cooldown.

## Phase 6 — Statistics (API)

- Plugin: `StatisticsContextResolver` returns `duel` for participants (through the registry).
- API: `DuelStatisticsProjector`, which projects wins/losses/draws from `duel_matches`. A forfeit is a loss; cancelled and aborted matches count nothing.
  - Register it in `StatisticsProjectionService`.
  - Add `duel` to the projection-owned guard.
- Visibility default for `wins/losses/draws@duel` per Q9.
- **Tests:** the projector, and refusing plugin-posted `wins@duel`.

## Phase 7 — Smoke test, docs, merge

**Dev-server smoke test.** Two accounts, plus a third as spectator. The arena sits in a town with `pvp deny`.

1. **Negotiation:**
   - invite, counter and accept at `max-offers` 3
   - a stale button can't accept
   - expiry
   - decline
2. **Lock-in:**
   - one player broke → refused, nothing taken
   - an item moved away before accept → refused
   - both stakes taken, ledger shows `DUEL_STAKE` ×2
3. **Lobby teleport:** one player moves during warmup → match cancelled, refund visible in `/balance` history.
4. **Warmup:** the global announcement, the spectator menu shows stakes and stats, `/spawn` and `/hub` refused, duelists can't hit or be hit.
5. **Countdown:** frozen, no damage, 10 s titles and sounds.
6. **Fight:**
   - PvP works inside the no-PvP town, potions included
   - spectators can't interfere
   - custom enchantments fire
   - pearling out is refused
7. **Death:** winner paid coins and items, the loser keeps their inventory, both restored, both at the exit.
8. **Forfeit:** a quit in the fight → the opponent wins; on rejoin the quitter is at the exit.
9. **Draw:** a time limit set to 30 s → draw, full refund.
10. **Crash:** `kill -9` mid-fight → on restart both are refunded and items are delivered on join.
11. **Outage:** API stopped mid-warmup → items returned at once, coins refunded when the API is back.
12. **Concurrency:** two matches at once on two battlegrounds; a third waits in the lobby.
13. **Stats:** duel W/L show up for a player who has made them visible.

**Docs:**
- a new guide `docs/guides/arena-duels.md` (admin setup: arena, battlegrounds, locations, config; the player how-to)
- the register row
- `specs/README.md`
- `CHANGELOG.md` at merge
- `managed-worldguard-regions.md` (arena source)
- teleport DESIGN (new kinds)

**Merge:** after the developer's live sign-off, per the global workflow.

---

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| WG `entry deny` blocks system teleports in ways that differ from v1 | Verify early in Phase 3 on the dev server; Q8 alternative ready |
| Un-cancelling at HIGHEST misses PvP paths (potions, fire, explosions) | `DisallowedPVPEvent` handler; smoke-test step 6 covers potions |
| Thrown duels to move coins to alts | eligibility, a stake cap, per-pair anomaly rule, staff refund/reversal |
| Item duplication through the escrow | items never move during negotiation; one-tick take after the spool write; idempotent delivery tracked per stack in the spool |
| Siege regressions from the Phase 0 refactor | no-behaviour-change PR with the existing siege tests, plus a short siege live check |
| Plugin branch collides with the KNG-182 upgrade | start the plugin phases after it merges (see Branches) |
