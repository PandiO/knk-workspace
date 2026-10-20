# Arena duels — draft design

**Status:** Draft for developer review. Nothing implemented. Proposed decisions are marked **(proposed)** in §3; the open questions in §13 need an answer before implementation issues are filed.
**Last updated:** 2026-10-20
**Linear:** [KNG-197](https://linear.app/kngpandi/issue/KNG-197) (this design); related [KNG-49](https://linear.app/kngpandi/issue/KNG-49) (Arena/Battleground entities), [KNG-21](https://linear.app/kngpandi/issue/KNG-21) (currency ledger), [KNG-34](https://linear.app/kngpandi/issue/KNG-34) (statistics)
**Sources:** developer request 2026-10-20; `knk-v1-archive` (`src/Arenas/{Duel,DuelInvite,DuelCommands,DuelEvents,Arena,ArenaCommands,ArenaMenuClick}.java`, `src/Menu/{Menu,DuelSetupClick}.java`, `src/Listeners/PlayerListener.java`, `src/Main/Main.java`); knk-plugin `main` `79be488`; knk-web-api `master` `2d71155`; specs [teleport](../teleport/DESIGN.md), [siege-minigame](../siege-minigame/DESIGN.md), [currency-payments](../currency-payments/DESIGN.md), [player-statistics](../player-statistics/DESIGN.md), [lootboxes](../lootboxes/DESIGN.md), [managed WorldGuard regions](../../architecture/managed-worldguard-regions.md), [legacy inventory-menu screens](../legacy/inventory-menu-screens.md) §3.15.
**Plan:** [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)

---

## 1. Requested behaviour

From the developer (2026-10-20):

1. A player goes to the arena and proposes a duel to another player. If it is accepted, the two fight to the death.
2. Once a match is created (P1 invites, P2 accepts), both players are teleported to the **arena lobby** and the **warmup phase** starts. Teleports use the default teleport engine. If either player cannot complete the teleport, the match is cancelled.
3. Both players can put up **stakes**: coins, items and similar. They place them either during the invitation phase or during warmup; *which one is undecided*.
   - The invitation phase lets the invitee judge whether the duel is worth accepting.
   - Its cost is a more complex back-and-forth stake GUI, with chat in between.
   - The developer suggested limiting counter-offers: either (a) the inviter's initial offer plus one counter, or (b) two offers each, alternating, with the invitee making the last one.
4. When warmup starts, the server gets a **global announcement**. Spectators can spectate, and a spectator menu shows the stakes and the participants' stats.
5. When the match starts, both players are teleported to the **battleground**, and the fight starts after a **10 second countdown**.
6. PvP works for the duelists **during the battle phase only**. That includes inside towns and districts that deny PvP by default.

## 2. What exists today, and what v1 taught us

### 2.1 v1 (the only precedent; v2 dropped duels)

v1 had `/duel <player>` (the inviter had to stand in an `arena_<id>` region) and an Arena-Owner NPC menu. After an accept, a **shared 54-slot setup inventory** opened. In it both players picked a type (coins, items or practice) and placed stakes. Coin bets were typed in chat. Then both players clicked Ready.

The duel flow after setup:

1. One global queue (`main.duelList`) ran one duel at a time, server-wide.
2. A 30 s "Catacombs" lobby prep.
3. The duelists were made WG members of `arena_<id>`.
4. A 5 s countdown at `player1`/`player2` spawns.
5. A 300 s fight, with a draw on timeout.

The battleground PvP came from region flags: `<arena>,<sub>-battleground` regions had `pvp allow` + `entry deny`.

The source shows the v1 flow is worth keeping but the implementation is not. Bugs verified in source:

| # | v1 defect | Where | v3 answer |
|---|---|---|---|
| V1 | **Money minting**:<br>- the balance was checked per typed increment, not against the total<br>- `removeCoins` clamps to 0 while the pot is `coins*2` (currency bug L7)<br>- negative bets were accepted, crediting both players | `DuelSetupClick.java:254-261`, `PlayerListener.java:726-774`, `Main.java:945-955`, `User.java:1440-1451` | The API debits the full stake atomically. A stake is a positive bounded `long`. One stake-lock posting either takes both stakes or takes nothing (§7.2). |
| V2 | **Double payout and item duplication**: a quit in the 10 s after a kill ran `endDuel` again | `DuelEvents.java:96-108` | An explicit state machine. Settlement is idempotent on the server, keyed per match (§7.4). |
| V3 | **No refunds**: draws, timeouts, missing spawns, an offline player and crashes all lost the stakes | `Duel.java:70-89,339-375` | Every outcome that is not a win refunds the stakes (§7.5). Escrow survives a crash (§7.3). |
| V4 | **Stake items lost or stealable**:<br>- items were lost when the other player closed the menu<br>- clicks went uncancelled for players who had never opened `/menu`<br>- shift-click could push items onto the opponent's half | `DuelInvite.java:97-118`, `MenuClick.java:84`, `DuelSetupClick.java:69,188-230` | No shared inventory. Items never move during negotiation. They move once, at lock-in, on one main-thread tick (§6.4). |
| V5 | **Readiness scam**: Ready was not reset when the other side changed their offer | `DuelSetupClick.java` | Offers are immutable and versioned. An accept names the offer id it accepts (§6.2). |
| V6 | **Target never notified**: the invite check passed a `User` where a `Player` was expected; the 10 s expiry was hard-coded | `DuelInvite.java:24,59` | A clickable invite with expiry and stale-button protection (the `TeleportRequestBook` pattern). |
| V7 | **Fight integrity**:<br>- damage was allowed during the countdown<br>- non-player deaths were ignored<br>- a kill by a third player made the duel a draw<br>- players could walk out<br>- menu teleports skipped the duel check | `Duel.java:189-254`, `DuelEvents.java:59-86` | Damage is locked during the countdown. Any death is a loss. Duelists and outsiders can't hit each other. Battleground confinement. A `TeleportRestriction` (§8). |
| V8 | **Stuck states**: NPEs in queue prep, a `ConcurrentModificationException` in the ticker, a blocked queue when the winner was offline | `Duel.java:126,286-289`, `Main.java:1306-1327` | Per-battleground allocation instead of one global queue. A pure, tested core state machine (§5). |
| V9 | **Identity**: UUIDs were compared with `==`; `/test duel` minted a 50,000-coin pot from nothing | many; `Commands.java:468-472` | Ordinary hygiene. No debug mint. Staff tooling only cancels or refunds. |

Worth borrowing from v1:
- the lobby-before-fight stage
- the action-bar countdown with click sounds and the `FIGHT!` title with a wither sound
- player cards (head, title, K/D, wealth)
- the payout fallback inventory → ender chest → claim
- the winner staying briefly before the exit teleport
- refusing `/spawn`, `/home`, `/warp` and menus while duelling
- temporary WG membership so that only duelists can enter a battleground (here scoped to the battle and cleaned up reliably)

### 2.2 v3 building blocks (current default branches)

| Need | Reuse | Gap |
|---|---|---|
| Lobby teleport with "cancel if it fails" | `TeleportService.start(TeleportPlan)` → `CompletableFuture<TeleportOutcome>` (`TELEPORTED/DENIED/CANCELLED/FAILED`); `check(plan)` pre-checks the guards; warmup is cancelled by movement, damage or quit | Handles one subject per plan; no system or minigame `TeleportKind`. `TeleportKind.HUB` arrives with the unmerged KNG-182 branch. |
| Blocking other teleports while in a match | the `TeleportRestriction` interface (siege registers `SiegeTeleportRestriction`) | none |
| Match lifecycle | the siege pattern: Bukkit-free state machine in `core/siege` returning `SiegeEffect`s, a 1 s ticker in `SiegeService`, `SiegeMatchObserver` hooks, `SiegeResultSpool` | No shared minigame framework. Siege membership is hard-wired at about 12 touchpoints in `KnKPlugin` (§10). |
| PvP only for duelists | `SiegeCombatListener` un-cancels `EntityDamageByEntityEvent` at HIGHEST and never changes WG flags; `SiegeCombatRules.decide` | Potion/area effects blocked by WG `pvp deny` are not covered by an un-cancel; WG's `DisallowedPVPEvent` is not used anywhere yet. |
| Enchantment effects in safezones | `WorldGuardCombatSafezones` `combatExemption` BiPredicate (KNG-11) | Wired to siege only. |
| Coin stakes | `ICurrencyService.PostAsync` (multi-leg, idempotent `(scope,key)`, enlists in the caller's transaction), `ReverseAsync`, reason table `CurrencyReasons`, `TransferPolicyEvaluator` | **No hold or escrow primitive**, no `DUEL_*` reasons, no `SYS_DUEL` account, no generic plugin spend endpoint (each feature exposes its own). Gems are non-transferable by decision. |
| Item stakes | `SiegePlayerVault`: snapshot to YAML before the teleport, restore on end, quit or join, atomic temp-file + move | **No server-side item storage.** Only lootbox non-stackables have an identity (`ItemInstance`, PDC `knk_item_instance`), and ownership transfer of instances is not built. |
| Invites | `TeleportRequestService` / `TeleportRequestBook`: id-stamped clickable `[Accept] [Deny]`, expiry sweep, cleared on quit, ignore-list, vanish-safe name resolution | Teleport-specific; copy or generalise. |
| Stake UI | plain Bukkit inventories (`SiegeEnchantMenu`, KNG-13 `OfflineStorageViews`); `AnvilCaptureManager` / `ChatCaptureManager` for amounts | The menu runtime cancels every click; deposit slots, shared inventories and click-type actions are unbuilt gaps G2–G4. |
| Spectator menu | `MenuFeature` + API-seeded templates, `refreshOpenMenus`, `AutoRefreshTicks`; `SiegeMenuBridge`, `StatisticsMenuFeature`, `TargetUserView` | none |
| Stats | `StatisticsApi.getUserStatistics` (filtered by viewer); free-form context keys; projector-per-minigame pattern (`SiegeStatisticsProjector`) | No duel context or projector; W/L/D are projection-only; configurable metrics default to visibility **nobody**. |
| Match record | `SiegeMatch` + `SiegeMatchService`: `RunLockedAsync` row lock, idempotent by status, `[RequirePluginService]`, `abort-unfinished` at startup | No Arena, Battleground or Duel entity. Arena regions are config-only (`regions.managed.extra-regions`, kinds `ARENA` 40 / `BATTLEGROUND` 50). |

## 3. Decisions (proposed)

| ID | Decision | Why |
|---|---|---|
| **D1** | **Stakes are negotiated in the invitation phase**, as immutable offers with a bounded number of turns (§6). There is no stake editing in warmup. | The invitee sees what is at stake before saying yes. The warmup announcement and spectator menu show final stakes. Nobody is teleported for a duel that falls apart over stakes. The GUI complexity the developer worried about comes from v1's *shared live inventory*; immutable offers remove it (§6.3). |
| **D2** | **Turn limit = `duels.stakes.max-offers`, default 3.** Offer 1 is the inviter's; each later offer is a counter by the other side; the last allowed offer can only be accepted or declined. | One protocol covers both developer variants: `2` is "initial + one counter" and `4` is "two each, invitee last". 3 lets the inviter answer a counter once. → Q1 |
| **D3** | **Stake items do not move during negotiation.** An offer *references* items in the owner's inventory. At lock-in, both players' items are checked and removed in one main-thread tick into a local escrow spool. | No dupe or steal surface while players negotiate and chat. The single tick removes the check-then-act race (V4). |
| **D4** | **Coins are debited at lock-in by the API**: one posting with two debit legs into `SYS_DUEL`, in the same DB transaction that creates the `DuelMatch` row. | All or nothing; no clamping (V1). The API is the only ledger. No hold primitive is needed, because the money is actually moved to a system account and moved out again at settlement. |
| **D5** | **Lock-in happens on acceptance, before teleporting.** "Match created" ⇔ stakes escrowed. A failed teleport cancels the match and refunds it. | Clear invariant. Stakes can't drift during the teleport warmup. The announcement can name the stakes. |
| **D6** | **Lobby teleports go through the engine with a normal warmup** (new kind `ARENA`: player-style warmup and combat-tag guard, no cooldown, no charge). Both start together; if either outcome ≠ `TELEPORTED`, the match is cancelled and refunded. | "Teleportation follows the default teleportation engine." A player who walks away during warmup has effectively declined. A player who already arrived stays in the lobby; no compensation teleport is needed, because the lobby is a normal safe area. |
| **D7** | **Battleground and exit teleports are system teleports** (kind `ARENA_SYSTEM`: no warmup, cooldown, combat tag or charge; still safe-spot checked; not audited as staff). A failure in the battleground move aborts the match with a refund. | The duel runtime must be able to move players on schedule. Siege bypasses the engine entirely; routing through the engine keeps the `/back` and arrival listeners consistent. |
| **D8** | **PvP is decided by the duel runtime, not by WG flags.** A HIGHEST listener un-cancels hits between the two duelists of the same match while the phase is `FIGHT`. Every hit between a match participant and anyone else is denied, both ways. WG's `DisallowedPVPEvent` is cancelled for the same pair, so potions and other WG-blocked PvP also work. | This is the siege's precedent ("never change WG flags", a v2 defect). It works in towns and districts that deny PvP. It stops third-party interference (V7). |
| **D9** | **Duelists keep their own inventory and XP on death** (keepInventory, keepLevel, no drops). Only the stakes change hands. Health, food and effects are restored after the match; durability and consumed items are not. | "Fight to the death" is the win condition, not an implicit all-inventory wager. Loot-on-death belongs to the vision's separate PvP arena (vision §7.5). → Q4 |
| **D10** | **Any death in `FIGHT` loses**, whatever the cause (player, fall, lava, void, mob). Quitting or disconnecting from `BATTLE_COUNTDOWN` on is a **forfeit**. Before that it **cancels** with a full refund. | Fixes V7 stalls. Players can't dodge a loss by quitting once the fight is set up; a disconnect in the lobby costs nobody anything. → Q3 |
| **D11** | **Fight time limit `duels.fight.max-seconds`, default 300**, then a **draw with a full refund**. A sudden-death variant is a follow-up. | "To the death" with a safety valve against stalemates (hiding, endless healing). → Q5 |
| **D12** | **Arenas and battlegrounds become API config entities** (`Arena`, `ArenaBattleground`, form-configurable, gated by `knk.admin.world`), referencing WG region ids and `Location`s. This answers the KNG-49 entity question for arenas. | Multiple arenas and battlegrounds, admin-editable without plugin config edits; matches `SiegeLobby` / `SiegeSpawnpoint`. → Q2 |
| **D13** | **Concurrent matches, one per battleground.** A match waits in the lobby until a battleground is free (warmup is extended with a queue position). | `arena_2` already has 8 battlegrounds; v1's single global queue was a bottleneck and a bug source (V8). |
| **D14** | **Coin stakes follow transfer eligibility.** Each staker must pass `TransferPolicyEvaluator.CheckEligibility` (account age, title, freeze/transfer lock). A per-player stake cap applies. **Gems can't be staked.** Duel postings are added to the anomaly rules. | A thrown duel is a disguised transfer to an alt. Gems are non-transferable by decision ([currency DESIGN](../currency-payments/DESIGN.md) line 603). → Q6 |
| **D15** | **Spectating is physical and passive**: spectators stand in the arena's spectator areas (normal gamemode) and use a read-only menu. Spectator betting is out of scope. | Simple and safe; no spectator gamemode clipping. Betting is gambling with its own abuse model. |

## 4. Concepts and data model

### 4.1 Arena configuration (API, form-configurable)

```
Arena                                   ArenaBattleground
  Id, Key (unique), Name                  Id, ArenaId (FK cascade), Key, Name
  WgRegionId        (arena_2)             WgRegionId          (arena_2,<sub>-battleground)
  LobbyLocationId   (FK Location)         SpawnALocationId    (FK Location)
  LobbyWgRegionId?  (confinement, opt.)   SpawnBLocationId    (FK Location)
  ExitLocationId    (FK Location)         SpectatorLocationId? (FK Location)
  DistrictId? / StreetId? (display)       IsEnabled, SortOrder
  IsEnabled
  WarmupSeconds?  (overrides config)
```

- Location FKs are `Restrict`, as on `SiegeSpawnpoint`.
- The managed-region policy keeps classifying the WG regions as `ARENA` / `BATTLEGROUND`. The entity replaces `regions.managed.extra-regions` as the source of the parent link (follow-up in KNG-49).
- The v1 arena (`arena_2`, 8 flagged battlegrounds) is seeded as the first arena.

### 4.2 Match record (API, append-only history; not form-configurable)

```
DuelMatch
  Id, PublicToken (uuid, used in plugin files and logs)
  ArenaId, BattlegroundId?             (null until allocated)
  ChallengerUserId, OpponentUserId
  Status    : Created | InProgress | Completed | Cancelled | Aborted          (stored as string)
  EndReason : Win | Forfeit | TimeLimit | SimultaneousDeath          (Completed; the last two have no winner = draw)
            | TeleportFailed | PlayerLeftLobby | NoBattleground | AdminCancelled     (Cancelled)
            | ServerRestart | ApiOutage                                            (Aborted)
  WinnerUserId?
  ChallengerCoins, OpponentCoins       (long, ≥ 0)
  StakeItemsJson                       (audit summary: owner, material, amount, name, instance id if any)
  StakeTransactionId?, SettlementTransactionId?
  OfferCount                           (how many offers it took)
  CreatedAt, LockedAt, FightStartedAt?, EndedAt?
```

- Items are recorded for audit only. The authoritative item escrow is the plugin spool (§7.3), because the API can't store arbitrary `ItemStack`s (§2.2).

### 4.3 Runtime (plugin, in memory)

- `DuelOffer`
  - `offerId`, `version`, `author`
  - `stakeA` / `stakeB`, each `{coins, List<ItemRef>}`
  - `expiresAt`
- `DuelNegotiation`
  - `negotiationId`, inviter, invitee, `arenaId`
  - a list of offers; `turn`
  - `state ∈ {AWAITING_RESPONSE, LOCKING, CLOSED}`
- `DuelMatchRuntime`
  - `matchToken`, API id, both players, arena/battleground, `DuelPhase`, deadlines
  - the escrow handle; the per-player restore snapshot
- `ItemRef`
  - a copy of the `ItemStack` (single stack, amount included) plus the slot it was picked from, as a hint only
  - matching at lock-in is by `isSimilar` + amount, never by slot alone

## 5. Lifecycle

```
                 /duel <p> (inviter inside an enabled arena region)
                                   │
                         ┌─────────▼─────────┐  decline / expire / quit / max offers declined
                         │   NEGOTIATING     │──────────────────────────────► closed (nothing moved)
                         │ offer ⇄ counter   │
                         └─────────┬─────────┘
                                   │ accept(offerId)
                         ┌─────────▼─────────┐  items or coins missing / ineligible / API refused
                         │     LOCKING       │──────────────────────────────► closed (items handed back)
                         │ items→spool, API  │
                         │ create+debit      │
                         └─────────┬─────────┘
                                   │ DuelMatch Created, stakes escrowed
                         ┌─────────▼─────────┐  either outcome ≠ TELEPORTED
                         │    TRAVELLING     │──────────────────────────────► CANCELLED + refund
                         │ 2× engine ARENA   │
                         └─────────┬─────────┘
                                   │ both TELEPORTED → global announcement
                         ┌─────────▼─────────┐  quit / API outage / restart / staff
                         │      WARMUP       │──────────────────────────────► CANCELLED/ABORTED + refund
                         │ lobby, spectators │
                         │ (+ wait for free  │
                         │   battleground)   │
                         └─────────┬─────────┘
                                   │ warmup over and battleground allocated
                         ┌─────────▼─────────┐  system teleport failed → ABORTED + refund
                         │ BATTLE_COUNTDOWN  │  quit → forfeit (opponent wins)
                         │ 10 s, frozen,     │
                         │ damage locked     │
                         └─────────┬─────────┘
                                   │ "FIGHT!"
                         ┌─────────▼─────────┐  death → win; quit → forfeit;
                         │       FIGHT       │  time limit → draw (refund); outage/restart → abort (refund)
                         └─────────┬─────────┘
                         ┌─────────▼─────────┐
                         │      ENDING       │  settle (idempotent), 5 s, exit teleports, restore, release
                         └───────────────────┘
```

### 5.1 Phase rules

| Phase | Duelists can | Duelists can't | Default timing |
|---|---|---|---|
| NEGOTIATING | anything; chat; open the offer view | be in another negotiation, match or siege | `offer-seconds` 60 per turn |
| LOCKING | — (a few hundred ms) | teleport, drop items, open containers | API timeout 10 s → treat as refused |
| TRAVELLING | move (moving cancels their own warmup = cancel the match) | other teleports | engine warmup (5 s / 3 s) |
| WARMUP | walk in the lobby, chat, inspect the match menu | hit or be hit (§8), teleport out, join siege, open stake/escrow items | `warmup-seconds` 30 (spectators gather) |
| BATTLE_COUNTDOWN | look around, manage inventory | move off their spawn block, deal or take damage, throw projectiles or pearls | 10 s (fixed by requirement; configurable) |
| FIGHT | fight each other | hit anyone else, be hit by anyone else, leave the battleground, teleport (pearl/chorus out is refused), drop items | `fight.max-seconds` 300 |
| ENDING | winner: stays `winner-linger-seconds` 5 | fight | then exit teleport |

- The battleground is allocated at the end of WARMUP, not at lock-in, so a short queue costs nothing.
- If none is free, the duelists see "Waiting for a free battleground (#2 in line)" on the boss bar.
- `max-wait-seconds` (default 180) then cancels with a refund (`NoBattleground`).

## 6. Invitation and stake negotiation

### 6.1 Commands

```
/duel <player>               open the stake editor for a new offer (inviter must be in an arena)
/duel <player> quick         send a no-stakes invite immediately
/duel accept <id>            accept the offer with that id (clickable)
/duel counter <id>           open the stake editor pre-filled with that offer
/duel decline <id> | cancel  end the negotiation
/duel view <id>              open the read-only offer view
/duels                       list live matches (spectator menu, §9)
/duel claim                  collect unclaimed winnings (§7.4)
/knk duel list|cancel <match>|refund <match>|arenas reload   staff
```

- Invite rules:
  - The invitee is any online, visible player who isn't ignoring the inviter, isn't in a siege, duel or negotiation, and isn't frozen.
  - At most one outgoing negotiation per player; at most `max-incoming` (3) incoming.
  - A send cooldown applies.
  - No self-duels.
- Pre-check both players with `TeleportService.check(ARENA plan)` before the invite is sent and again at accept. A player who couldn't teleport anyway gets the refusal immediately, not after the stakes are locked.

### 6.2 Offer protocol (D1/D2)

```
offer #1  inviter: {my stake, ask of invitee}        → invitee: Accept | Counter | Decline
offer #2  invitee: {my stake, ask of inviter}        → inviter: Accept | Counter | Decline
offer #3  inviter (last when max-offers = 3)         → invitee: Accept | Decline
```

- An offer is a **complete contract**: both halves `{coins, items}`.
- The author may set their own coins and items and the *other* side's coins. They may remove (not add) items from the other side's half. Only the owner can offer an item.
  - Offer #1 "I put up my diamond sword, you put up 500 coins" is expressible.
  - "You put up your helmet" is not, until the opponent offers it.
- Every offer gets a fresh `offerId`. `/duel accept <id>` only works for the **current** offer, so a stale chat button can't accept an old one (the `TeleportRequestBook` pattern). This removes v1's readiness scam (V5).
- Expiry: each turn gets `offer-seconds`. Expiry, a quit, death, or entering a siege closes the negotiation. Nothing is held, so nothing needs refunding.
- Validation when an offer is sent (advisory) and at lock-in (binding):
  - coins `0 ≤ c ≤ stake.max-coins`
  - each item present in the owner's inventory
  - item not on the blocklist (§7.6)
  - total item stacks ≤ `stake.max-item-stacks` (default 9 per side)
- An empty contract is a "friendly" duel: same flow, no escrow calls except creating the match row.

### 6.3 Stake editor and offer view (UI)

- **The stake editor** is a hand-rolled 54-slot Bukkit inventory with its own holder (like `SiegeEnchantMenu`). Every click is cancelled, so no item ever enters or leaves it.

  ```
  row 0   [your head card]  .  .  [ARENA card]  .  .  [opponent head card]
  row 1-2 [your stake: up to 9 item icons]   |   [their stake: icons, click = remove]
  row 3   [your coins −100 −10 [amount] +10 +100]  |  [their coins −100 −10 [amount] +10 +100]
  row 4   (filler)
  row 5   [Cancel]     [Type exact amount (anvil)]     [Send offer #n of max]
  ```

  - Clicking an item in **your own** (bottom) inventory adds a copy-reference of that stack to your half. The item stays where it is and is marked with a glint lore line ("Staked in offer").
  - Clicking an icon in your half removes it.
  - Exact amounts use `AnvilCaptureManager`. The balance is shown as a hint; the API is authoritative at lock-in.
- **The offer view** is read-only, has the same layout without the edit controls, and has `[Accept] [Counter] [Decline]` buttons.
- **Chat** carries the same actions, so a player can answer without opening anything:

  ```
  ⚔ Pandi challenges you to a duel at the Arena (offer 1/3, 60 s)
     You stake: 500 coins          Pandi stakes: Diamond Sword ★★★, 200 coins
     [View] [Accept] [Counter] [Decline]
  ```

- Players negotiate by chatting normally (or with `/msg`) between turns, because no menu is held open by the protocol. That resolves the "GUI vs. chat" tension the developer raised.
- **This needs no menu-runtime gaps G2–G4.** The editor is a self-contained plugin inventory. The spectator menu (§9) uses the normal menu runtime.

### 6.4 Lock-in (on accept)

1. **Pre-checks (main thread)**:
   - both players online, not in a siege or match, the inviter still in the arena world
   - `TeleportService.check` passes for both
   - each `ItemRef` is still present (`isSimilar` + amount)
   - no blocklisted items
2. **Take items (same tick)**:
   - write `duel-escrow/<matchToken>.yml` with both players' items (Paper `serializeItemsAsBytes`, temp file + atomic move, state `LOCKING`)
   - **then** remove the stacks from both inventories
   - if the file write fails, nothing is removed and the accept is refused
3. **API (async)**: `POST api/DuelMatches` with both user ids, the coin amounts, the item audit summary and `Idempotency-Key: duel-lock:<matchToken>`. In one DB transaction the API:
   - checks eligibility (D14)
   - inserts `DuelMatch(Status=Created)`
   - posts `DUEL_STAKE` with two debit legs into `SYS_DUEL`
   - refuses on `InsufficientFunds` or ineligibility, with nothing posted
4. **Back on main thread**:
   - **Success**: spool state `ESCROWED` with the API id; match runtime created → TRAVELLING.
   - **Refused or failed**:
     - give the items back (inventory, then ender chest, then the claim spool), delete the spool, close the negotiation with the API's reason
     - a timeout is treated as failed, but the plugin first calls `GET …/by-token/<matchToken>`: the create is idempotent, so a create that did land is cancelled and refunded rather than leaked

## 7. Escrow, settlement and refunds

### 7.1 Currency (API)

- **New reasons in `CurrencyReasons`**, added in the same PR as the first call (rule at `CurrencyReasons.cs:38-41`):

  | Code | Kind / direction | System account | Notes |
  |---|---|---|---|
  | `DUEL_STAKE` | Spend / Debit | `SYS_DUEL` | two legs per match, `SourceType=DuelMatch`, `SourceRef=<id>` |
  | `DUEL_PAYOUT` | Grant / Credit | `SYS_DUEL` | winner receives the pot (minus fee) |
  | `DUEL_FEE` *(optional, Q7)* | — | `SYS_DUEL` → sink | arena fee; default 0 |

- Refunds use `ReverseAsync(stakeTx)` with key `reverse:<stakeTxId>`, the teleport-refund pattern. Statistics then treat the refund as un-spending (player-statistics DESIGN §F).
- **Reconcile invariant**: per match, Σ `SYS_DUEL` legs = fee (0 by default) once the match is closed. An open match holds exactly the sum of both stakes.
- **Anomaly rules**:
  - Extend R3 (funnel) and R4 (ping-pong) to count `DUEL_PAYOUT` from the loser's stake as a flow loser → winner.
  - Add a per-pair rule: more than `n` staked duels between the same two accounts in 24 h gets flagged.

### 7.2 Items (plugin spool)

- `plugins/KnightsAndKings/duel-escrow/<matchToken>.yml` holds:
  - `state ∈ {LOCKING, ESCROWED, SETTLED_A, SETTLED_B, REFUNDED, CLAIM_PENDING}`
  - the API match id and both players' serialized stacks
  - for each player, the stacks still owed to them
- It is written before every change and moved atomically, like `SiegePlayerVault`.
- Items with an `ItemInstance` id keep their PDC tag. `ItemInstance.OwnerUserId` is **not** updated, because instance ownership transfer isn't built ([lootboxes DESIGN](../lootboxes/DESIGN.md) lines 33-35; `ItemInstance.cs:15-17`). Follow-up: when it is built, settlement calls it.

### 7.3 Crash and restart recovery

At plugin startup:

1. Call `POST api/DuelMatches/abort-unfinished` (plugin-only). Every `Created/InProgress` match becomes `Aborted (ServerRestart)` and its stake is reversed, idempotently. Any match not yet `Completed` is refunded: a restart mid-fight can't produce a fair winner (siege precedent).
2. Scan `duel-escrow/`. For each file:
   - ask the API for the match status; `Completed` with a winner → owe the items to the winner
   - otherwise (or 404 for a `LOCKING` file) → owe each player their own items
   - items are delivered on join (inventory, then ender chest, then `CLAIM_PENDING` for `/duel claim`)
3. Restore snapshots (§8.4) for players who were mid-match are applied on join.

### 7.4 Settlement (win)

1. **Plugin**:
   - the phase moves to ENDING once only, guarded by the state machine
   - write a result spool `duel-escrow/pending-results/<matchToken>.json` (the `SiegeResultSpool` pattern)
   - call `POST api/DuelMatches/{id}/complete {winnerUserId, endReason, fightSeconds, hits/damage summary}`
2. **API**, inside `RunLockedAsync(id)`:
   - `Completed` → return the stored result (idempotent)
   - `Cancelled/Aborted` → conflict
   - otherwise `GrantAsync(winner, pot − fee, DUEL_PAYOUT, key duel-payout:<id>)` and `Status=Completed`, all in one transaction
3. **Plugin**:
   - give the loser's staked items and the winner's own staked items to the winner (inventory, then ender chest, then `CLAIM_PENDING`)
   - delete the spool once everything is delivered
   - an offline winner gets them on join; v1 paid offline winners nothing
4. **The API is down at settlement**: the result spool is retried until the API accepts it.
   - The items are paid out locally right away, since the plugin owns the fight outcome.
   - The coins follow when the API accepts the spooled result.
   - The spool is safe to retry because `complete` is idempotent.

### 7.5 Refund (every outcome that is not a win)

- Cancel (`TeleportFailed`, `PlayerLeftLobby`, `NoBattleground`, `AdminCancelled`), abort (`ServerRestart`, `ApiOutage`) and draw (`TimeLimit`, `SimultaneousDeath`) all go through `POST …/{id}/cancel {reason}`. It reverses the stake transaction once and sets `Cancelled`, `Aborted`, or `Completed` with no winner (draw).
- The plugin then gives each player their own items back.
- **During an API outage** (`HubOutageService` releases minigame players):
  - items are returned locally at once
  - the cancel call is spooled and replayed when the API returns
  - the coins are reversed then
- Staff `/knk duel refund <match>` calls the same endpoint. There is no staff path that pays out.

### 7.6 Stake rules

- **Coins**:
  - `1 ≤ c ≤ stake.max-coins`, default 10,000 per side; open → Q6
  - eligibility per D14
  - the ledger limits (bounded `long`) apply
- **Gems**: never.
- **Items**:
  - any item in the player's main inventory, armour or off-hand
  - blocklist (`stake.item-blocklist`):
    - shulker boxes and bundles that have contents
    - written books
    - items with the soulbound flag (once that's enforced)
    - lootbox-held items
    - staff/kit-bound items
    - the barrier/debug materials
  - a maximum of `stake.max-item-stacks` per side

## 8. Combat, confinement and safety

### 8.1 PvP rule (D8)

- `DuelCombatListener` listens on `EntityDamageByEntityEvent` at **HIGHEST**. It resolves the real attacker (projectile shooter, tamed pet's owner, TNT and end-crystal source where known).
- The pure rules (`core/duel/DuelCombatRules.decide(attackerMatch, victimMatch, phase)`):

  | Case | Effect |
  |---|---|
  | Both are duelists of the **same** match, phase `FIGHT`, no `damageLocked` | `setCancelled(false)`, which overrides town/district/hub denies |
  | Same match, any other phase | cancelled |
  | One side is a match participant (any phase from LOCKING to ENDING) and the other isn't in that match | cancelled, both ways (no third-party interference; nobody hits a lobby duelist) |
  | Neither is in a match | untouched |

- A `DisallowedPVPEvent` (WorldGuard) handler cancels the event (i.e. allows the PvP) for the same `FIGHT` pair. That covers splash/lingering potions, fire and other paths WG blocks.
- `WorldGuardCombatSafezones.combatExemption` becomes a composite: siege OR duel. Custom-enchantment effects then work inside a battleground located in a no-PvP town (KNG-11).
- WG flags on the battleground stay as the managed policy sets them (`pvp allow`, `entry deny`). The listener's deny wins over `pvp allow` for anyone who isn't the fighting pair.

### 8.2 Entering the battleground (`entry deny`)

- The managed policy enforces `entry deny` on battlegrounds. That means WG refuses even system teleports of non-members.
- The runtime adds both duelists as **WG members of the battleground region** just before the countdown teleport. It removes them at ENDING and on every abort.
- At startup, the recovery step clears members from all battleground regions of enabled arenas. The managed-region repair doesn't touch members, so the duel feature owns this cleanup.
- This is v1's approach, scoped to one battleground and one match. → Q8 (alternative: drop `entry deny` and confine with a plugin listener instead).

### 8.3 Confinement

- **Battleground**:
  - in `FIGHT`, leaving the region (walking, pearl, chorus fruit, elytra, vehicle) is refused: a teleport is cancelled, a move is pushed back
  - an `ARENA_SYSTEM` teleport is the only way out
  - in `BATTLE_COUNTDOWN`, the player is frozen to their spawn block; head rotation is allowed
- **Teleports**: `DuelTeleportRestriction` refuses every engine teleport other than the runtime's own while the player is in LOCKING..ENDING, including `/spawn`, `/warp`, `/home`, `/tpa`, `/back`, `/hub` and menu teleports.
- **Commands**: a `DuelCommandFilter` allow-list in FIGHT and COUNTDOWN (default `/duel,/msg,/r,/staffchat`). Siege's `SiegeCommandFilter` is the pattern.
- **Inventory guards** from LOCKING to ENDING (like `SiegeInventoryGuardListener`): no dropping items, no placing them in containers, no item frames or armour stands. This keeps a duelist from passing items to an accomplice during warmup.

### 8.4 Death, respawn and restore

- **Snapshot**: when a duelist arrives in the lobby, the plugin snapshots their health, food, saturation, effects and fire ticks. Inventory is not snapshotted; keepInventory makes that unnecessary (D9).
- **Death of a duelist in `FIGHT`** (`PlayerDeathEvent` at HIGHEST): keepInventory, keepLevel, no drops or XP orbs, a custom death message (sent only to the arena and spectators), then `DuelService.handleDeath`, which records the loss.
- **Respawn**: the loser respawns at the arena exit. `BackDeathExclusion` keeps `/back` from returning them to the battleground.
- **Winner**: their health and food are topped up, they linger for 5 s with a title, then an `ARENA_SYSTEM` teleport takes them to the exit.
- **Restore**: both players get their pre-match health, food and effects back.
- **Two deaths on the same tick** (e.g. a shared explosion): the first death processed wins nothing. The match is a **draw with refund** (`SimultaneousDeath`).

### 8.5 Interaction with other systems

| System | Rule |
|---|---|
| Siege | `joinDenial` refuses players in a negotiation or match; invites to siege members are refused |
| Hub / API outage | `HubOutageService.releaseFromMinigame` becomes a composite (§10). A duel released for an outage is aborted and refunded |
| Combat tag | the lobby teleport respects it (engine guard); FIGHT hits tag both players as normal; ENDING clears both tags |
| Statistics | `StatisticsContextResolver` returns `duel` for match participants, so `pvp_kills@duel` and `deaths@duel` are separated from open-world |
| Discovery, navigation, lootbox drops | same exemptions as siege (no discovery rewards, no navigation HUD, lootbox items held until after the match) |
| Scoreboard | duelists and spectators see a duel sidebar (names, health, phase timer). `ScoreboardUtil.setKeepOwnScoreboard` must take a composite predicate |
| Freeze / staff | a frozen duelist forfeits only if frozen in FIGHT. Staff can `/knk duel cancel` at any phase (refund) |

## 9. Announcements and spectating

### 9.1 Announcements

- **Warmup start**, broadcast to all players. It is clickable and uses a `config.yml` template (the `LootboxAnnouncer` pattern):

  ```
  ⚔ Duel at the Arena: Pandi vs Notch — stakes: 700 coins + 2 items   [Spectate] [Details]
  ```

- **Result**: "Pandi defeated Notch in 1:42 and won 700 coins + 2 items." A draw is announced too; a cancel only reaches the two duelists and the spectators in the arena.
- **Friendly (no-stake) duels**: the broadcast is configurable via `announce.friendly`, default on.
- Global mute or "announcement preferences" don't exist yet. Without them a spam limiter applies: at most one warmup broadcast per player per `announce.cooldown-seconds` (120).

### 9.2 Spectator menu (`/duels`, menu runtime, API-seeded template `duel_matches` + `duel_match_detail`)

- **List**: one row per live match (WARMUP → ENDING) with both heads, arena/battleground, phase, the countdown/fight timer, and a stake summary.
- **Detail**:

  ```
  [Challenger card]          [VS / phase / timer]          [Opponent card]
  stake items (real item icons, lore shows name/grade)  | stake items
  coins staked                                          | coins staked
  stats: title, XP, playtime; duel W/L/D, pvp_kills (if visible to the viewer)
  [Teleport to spectator stand]                               [Close]
  ```

  - Stats come from `StatisticsApi.getUserStatistics(userId, viewerId)`, which already filters by the duelist's visibility settings. Configurable metrics default to *nobody*, so for most players the menu shows the always-public fields (title, XP, playtime, coins) until they opt in.
  - Duel W/L/D are projected server-side (§11); a visibility default of `everyone` for `wins/losses@duel` is proposed in Q9.
- The menu auto-refreshes once a second (`AutoRefreshTicks: 20`). `refreshOpenMenus` runs on every phase change.
- **"Teleport to spectator stand"** is an engine teleport (`WARP`-like player kind: normal warmup and cooldown) to the battleground's `SpectatorLocation`, or to the arena lobby if it has none. Spectators get no PvP protection beyond the normal town rules, but duelists can't hit them and they can't hit duelists (§8.1).
- Spectators see the duel sidebar and a boss bar for the match they are standing near (within the arena region).

## 10. Plugin-wide hooks: introduce a small minigame participation registry

Siege membership is hard-wired as single lambdas at about 12 places in `KnKPlugin` (approximate lines on `main` `79be488`):

| What | Line(s) |
|---|---|
| enchant safezone exemption | 898 |
| statistics context | 1328 |
| headshots | 1361 |
| discovery | 1406 |
| navigation | 1559 |
| outage release | 2635 |
| `/hub` refusal | 2672 |
| domain-access respawn exemption | 2776 |
| lootbox | 2965, 3080 |
| scoreboard | 3423 |
| teleport restriction / `/back` | 3430–3431 |

Adding duels as a second hard-wired lambda at each place would repeat that.

**Proposal**: a `core/minigame/MinigameParticipation` port with:
- `participationOf(UUID) → Optional<Participation{kind, matchRef, phase}>`
- `allowsCombat(attacker, victim)`
- `releaseForOutage(UUID)`
- `holdsLootDrops(UUID)`

`MinigameRegistry` composes the siege and duel implementations, and each touchpoint calls the registry. This is a no-behaviour-change refactor done before the duel runtime (plan Phase 0). It also helps the later minigames in KNG-72 and KNG-50.

## 11. Statistics

- **Context**: the `duel` context is plugin-reported for `pvp_kills`, `deaths`, damage and arrows (no schema change; any key matching the pattern is accepted).
- **Results**: `DuelStatisticsProjector` projects `wins` / `losses` / `draws` from `duel_matches` (the "a projector per minigame" rule):
  - `Forfeit` counts as a loss
  - `Cancelled/Aborted` count nothing
- Add `duel` to the projection-owned guard so the plugin can't post `wins@duel`.
- **Later** (separate issues): duel win streak, head-to-head record, a duel leaderboard (with the existing `PlayerPvpKillPairDaily` style anti-farming caps), and an Elo-style rating.

## 12. Configuration (plugin `config.yml`)

```yaml
duels:
  enabled: true
  invite:
    max-incoming: 3
    send-cooldown-seconds: 10
  stakes:
    max-offers: 3            # D2: 2 = invite + one counter, 4 = two each (invitee last)
    offer-seconds: 60
    max-coins: 10000
    max-item-stacks: 9
    item-blocklist: [WRITTEN_BOOK, BARRIER, COMMAND_BLOCK, STRUCTURE_VOID]
    refuse-filled-containers: true   # shulker boxes and bundles with contents
  warmup-seconds: 30
  max-wait-seconds: 180      # waiting for a free battleground
  countdown-seconds: 10
  fight:
    max-seconds: 300
  winner-linger-seconds: 5
  command-allow-list: [/duel, /msg, /r, /staffchat]
  announce:
    warmup: true
    result: true
    friendly: true
    cooldown-seconds: 120
```

Arena and battleground geometry and locations live in the API (D12), not in config.

## 13. Open questions for the developer

| # | Question | Proposed default |
|---|---|---|
| Q1 | Turn limit: 2 (invite + one counter), 3, or 4 (two each, invitee last)? | **3**, configurable |
| Q2 | Arena/Battleground as API entities (D12, closes the KNG-49 entity question for arenas), or keep them in plugin config for an MVP? | API entities |
| Q3 | Quitting in WARMUP: cancel with refund (D10), or a forfeit too? | Cancel + refund; revisit if players abuse it to "scout and leave" |
| Q4 | Loser's own inventory: keep (D9), or drop it for the winner (v1 behaviour, vision §7.5 "PvP arena with drops")? An arena-level option is possible | Keep; drops later as a separate arena *mode* |
| Q5 | Fight time limit: draw + refund at 5 min (D11), sudden death (glowing + escalating damage), or no limit? | Draw at 5 min; sudden death as a follow-up |
| Q6 | Coin stake cap and eligibility: apply the transfer rules (48 h account age, Peasant title, freeze/lock) and a 10k cap? Count stakes toward the daily transfer caps? | Eligibility yes, cap 10k, not counted toward daily caps |
| Q7 | An arena fee (coin sink) on staked duels? | None for MVP (`DUEL_FEE` reserved) |
| Q8 | Battleground entry: temporary WG membership (§8.2), or drop `entry deny` from the managed policy and confine by listener? | Temporary membership |
| Q9 | Make duel W/L/D visible to everyone by default (unlike other configurable metrics)? | Yes: it's a public competitive record |
| Q10 | Must the **invitee** also be in the arena to accept, or can they be anywhere (the lobby teleport brings them)? | Anywhere |
| Q11 | Where else can a duel start: an Arena NPC/menu (v1 "Arena Owner"), a player-profile button? | `/duel` + clickable player name first; NPC later with the NPC platform (KNG-36) |

## 14. Alternative considered: stakes in warmup

The developer's other option: invite and accept without stakes, teleport, then both players set stakes in the lobby before the countdown.

| | Invitation-phase stakes (chosen) | Warmup stakes |
|---|---|---|
| Invitee knows the stakes before saying yes | yes | no; they may teleport for nothing |
| Players can talk while negotiating | yes, menus close between turns | yes, and they stand next to each other |
| Announcement and spectator menu show final stakes | yes | only after a delay, or the stakes change on screen |
| What happens when negotiation fails | nothing moved, nobody teleported | match cancelled after the teleport; time wasted |
| Escrow timing | one lock-in at accept | a second lock-in at the end of warmup; the warmup has to wait for it |
| UI | editor + offer view | the same editor, inside a timer |

The same stake editor and lock-in code serve both options. If the developer prefers warmup stakes, the plan changes in two places only:
- the negotiation moves to after TRAVELLING
- lock-in moves to the end of WARMUP, with the match row created without stakes at accept

## 15. Out of scope / follow-ups (file when picked up)

- Spectator betting.
- Team duels (2v2) and tournaments. The vision notes a "duel/tournament for a title" (source notes); the match model keeps two participants for now.
- Ranked queue / matchmaking and Elo.
- Kits / "fair-fight" duels where both get the same arena kit (would reuse `SiegePlayerVault`-style snapshot + kit grant).
- Sudden death (Q5).
- Duel history page in the web app (the `GET api/DuelMatches` endpoints make it cheap).
- `ItemInstance` ownership transfer on payout (lootboxes deferred item).
