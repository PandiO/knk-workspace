# Arena duels — design

**Status:** Design accepted by the developer (2026-10-21, rev. 5); **rev. 6 (2026-10-24, developer: battlegrounds, spectator areas and the lobby are arena areas, not child domains)**. Implemented on the `claude/arena-duels` branches (phases P0–P9), not merged or live-tested yet. Every question is decided (§13). Implementation is split into phase issues [KNG-209](https://linear.app/kngpandi/issue/KNG-209), [KNG-210](https://linear.app/kngpandi/issue/KNG-210), [KNG-213](https://linear.app/kngpandi/issue/KNG-213), [KNG-215](https://linear.app/kngpandi/issue/KNG-215), [KNG-217](https://linear.app/kngpandi/issue/KNG-217), [KNG-219](https://linear.app/kngpandi/issue/KNG-219), [KNG-220](https://linear.app/kngpandi/issue/KNG-220), [KNG-221](https://linear.app/kngpandi/issue/KNG-221), [KNG-222](https://linear.app/kngpandi/issue/KNG-222) ([plan](IMPLEMENTATION_PLAN.md)).
**Last updated:** 2026-10-25 (rev. 6, developer decision of 2026-10-24 on KNG-197: D12 and D16 revised, §4.1 `ArenaArea` + `ArenaAreaRegion` replace the battleground and spectator-area child domains and `Arena.LobbyLocationId`, §4.2 area fields, §8.2 the duel runtime's own access rule, §9.3 spectating by an `ARENA` teleport, §13.4; implementation in plan Phase 9). 2026-10-21 (rev. 5: duel restrictions decided, §10.3 / §13.3; phase issues filed). 2026-10-20 (rev. 4: kit modes vault before the lobby teleport and hold pending deliveries such as lootbox rolls, §8.4; never hold on a first flag, staff can revert a paid result at any time, §10.3. Rev. 3: open points O1–O6 decided; escalating review tiers for suspicious results, §10.3; siege kit mode split out as KNG-199. Rev. 2: developer answers; arenas as domains; per-arena settings in the web app; gear modes with kits and inventory drop; queue cap; spectator area as a warp domain; abuse prevention §10)
**Linear:** [KNG-197](https://linear.app/kngpandi/issue/KNG-197) (this design); related [KNG-49](https://linear.app/kngpandi/issue/KNG-49) (Arena/Battleground entities), [KNG-21](https://linear.app/kngpandi/issue/KNG-21) (currency ledger), [KNG-34](https://linear.app/kngpandi/issue/KNG-34) (statistics), [KNG-36](https://linear.app/kngpandi/issue/KNG-36) (NPC platform, for the later Arena NPC)
**Sources:** developer request and answers 2026-10-20; `knk-v1-archive` (`src/Arenas/{Duel,DuelInvite,DuelCommands,DuelEvents,Arena,ArenaCommands,ArenaMenuClick}.java`, `src/Menu/{Menu,DuelSetupClick}.java`, `src/Listeners/PlayerListener.java`, `src/Main/Main.java`); knk-plugin `main` `79be488`; knk-web-api `master` `2d71155`; specs [teleport](../teleport/DESIGN.md), [siege-minigame](../siege-minigame/DESIGN.md), [currency-payments](../currency-payments/DESIGN.md), [player-statistics](../player-statistics/DESIGN.md), [kits](../kits/DESIGN.md), [lootboxes](../lootboxes/DESIGN.md), [managed WorldGuard regions](../../architecture/managed-worldguard-regions.md), [domain access enforcement](../../architecture/domain-access-enforcement.md), [legacy inventory-menu screens](../legacy/inventory-menu-screens.md) §3.15.
**Plan:** [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)

---

## 1. Requested behaviour

From the developer (2026-10-20):

1. A player goes to the arena and proposes a duel to another player. If it is accepted, the two fight to the death.
2. Once a match is created (P1 invites, P2 accepts), both players are teleported to the **arena lobby** and the **warmup phase** starts. Teleports use the default teleport engine. If either player cannot complete the teleport, the match is cancelled.
3. Both players can put up **stakes**: coins, items and similar. They place them during the invitation phase, with a limited number of counter-offers (decided: §3 D1/D2).
4. When warmup starts, the server gets a **global announcement**. Spectators can spectate, and a spectator menu shows the stakes and the participants' stats.
5. When the match starts, both players are teleported to the **battleground**, and the fight starts after a **10 second countdown**.
6. PvP works for the duelists **during the battle phase only**. That includes inside towns and districts that deny PvP by default.

Added with the answers (2026-10-20):

7. **Settings are configurable in the web app**:
   - the turn limit
   - the inventory-on-death options
   - the fight time limit, including "no limit"
   - stake caps and eligibility
   - the visibility of duel results
8. **Arenas are API entities**, a child type of Structure/domain.
9. **Measures against value transfer** (alts, throwing a duel) are required.
10. **Inventory on death**: per arena, the admin allows *keep* and/or *drop*. When both are allowed, the inviter picks one in the proposal.
11. **Accepting** is refused while the invitee is in a minigame or in combat.
12. A configurable **queue cap per arena** (e.g. at most 3 duels waiting).
13. A **kit mode** to even the odds. The admin enables it and picks eligible kits per arena. The proposal then either names one kit for both, or says "kits only", and each duelist picks from the eligible kits.
14. An optional **spectator area** per arena. You can reach it on foot, from the arena's menu, or by warp. Warps go through the normal engine and keep its conditions (title, cost). *Rev. 6 (developer, 2026-10-24): on foot and from the arena menu / `/duels spectate`, by an engine teleport that checks the area's own title and gem conditions (§9.3); a `/warp` listing is a future improvement (§15, KNG-240).*
15. An Arena NPC that starts duels: later, recorded as a future update (§15).

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
| V1 | **Money minting**:<br>- the balance was checked per typed increment, not against the total<br>- `removeCoins` clamps to 0 while the pot is `coins*2` (currency bug L7)<br>- negative bets were accepted, crediting both players | `DuelSetupClick.java:254-261`, `PlayerListener.java:726-774`, `Main.java:945-955`, `User.java:1440-1451` | The API debits the full stake atomically. A stake is a positive bounded `long`. One stake-lock posting either takes both stakes or takes nothing (§7.1). |
| V2 | **Double payout and item duplication**: a quit in the 10 s after a kill ran `endDuel` again | `DuelEvents.java:96-108` | An explicit state machine. Settlement is idempotent on the server, keyed per match (§7.4). |
| V3 | **No refunds**: draws, timeouts, missing spawns, an offline player and crashes all lost the stakes | `Duel.java:70-89,339-375` | Every outcome that is not a win refunds the stakes (§7.5). Escrow survives a crash (§7.3). |
| V4 | **Stake items lost or stealable**:<br>- items were lost when the other player closed the menu<br>- clicks went uncancelled for players who had never opened `/menu`<br>- shift-click could push items onto the opponent's half | `DuelInvite.java:97-118`, `MenuClick.java:84`, `DuelSetupClick.java:69,188-230` | No shared inventory. Items never move during negotiation. They move once, at lock-in, on one main-thread tick (§6.5). |
| V5 | **Readiness scam**: Ready was not reset when the other side changed their offer | `DuelSetupClick.java` | Offers are immutable and versioned. An accept names the offer id it accepts (§6.3). |
| V6 | **Target never notified**: the invite check passed a `User` where a `Player` was expected; the 10 s expiry was hard-coded | `DuelInvite.java:24,59` | A clickable invite with expiry and stale-button protection (the `TeleportRequestBook` pattern). |
| V7 | **Fight integrity**:<br>- damage was allowed during the countdown<br>- non-player deaths were ignored<br>- a kill by a third player made the duel a draw<br>- players could walk out<br>- menu teleports skipped the duel check | `Duel.java:189-254`, `DuelEvents.java:59-86` | Damage is locked during the countdown. Any death is a loss. Duelists and outsiders can't hit each other. Battleground confinement. A `TeleportRestriction` (§8). |
| V8 | **Stuck states**: NPEs in queue prep, a `ConcurrentModificationException` in the ticker, a blocked queue when the winner was offline | `Duel.java:126,286-289`, `Main.java:1306-1327` | Per-battleground allocation with a capped per-arena queue instead of one global queue. A pure, tested core state machine (§5). |
| V9 | **Identity**: UUIDs were compared with `==`; `/test duel` minted a 50,000-coin pot from nothing | many; `Commands.java:468-472` | Ordinary hygiene. No debug mint. Staff tooling only cancels, refunds or releases a held payout. |

Worth borrowing from v1:
- the lobby-before-fight stage
- the action-bar countdown with click sounds and the `FIGHT!` title with a wither sound
- player cards (head, title, K/D, wealth)
- the payout fallback inventory → ender chest → claim
- the winner staying briefly before the exit teleport
- refusing `/spawn`, `/home`, `/warp` and menus while duelling
- a battleground that only its own duelists can enter (v3 does this without WG membership, §8.2)

### 2.2 v3 building blocks (current default branches)

| Need | Reuse | Gap |
|---|---|---|
| Arena as a domain | `Domain` (TPT base, table `domains`; region, `AllowEntry/AllowExit`, `Location`, warp fields) → `Structure` (`structures`; Street, HouseNumber, District) → `GateStructure` (`gate_structures`) is the precedent for a typed child | No Arena type. Arena regions are config-only (`regions.managed.extra-regions`, kinds `ARENA` 40 / `BATTLEGROUND` 50). |
| Spectator warp with conditions | A domain **is** a `/warp` destination when `TeleportEnabled` + `Location` + `AllowEntry`. `TeleportDestinationService` checks title bracket, premium tier, discovery and gem price (teleport DESIGN §3.7) | rev. 6: the stands are an area, not a domain; the spectate teleport gets its own title/gem check on the teleport fee path (§9.3) |
| Battleground entry | `DomainAccessHandler`, a WG session handler enforcing `knk-allow-entry/exit` from `Domain.AllowEntry/AllowExit` on walk, vehicle and teleport (domain-access DESIGN §1) | rev. 6: areas aren't domains; the duel runtime registers a session handler of its own on the same pattern (§8.2) |
| Lobby teleport with "cancel if it fails" | `TeleportService.start(TeleportPlan)` → `CompletableFuture<TeleportOutcome>` (`TELEPORTED/DENIED/CANCELLED/FAILED`); `check(plan)` pre-checks the guards; warmup is cancelled by movement, damage or quit | One subject per plan; no system or minigame `TeleportKind`. `TeleportKind.HUB` arrives with the unmerged KNG-182 branch. |
| Blocking other teleports while in a match | the `TeleportRestriction` interface (siege registers `SiegeTeleportRestriction`) | none |
| Match lifecycle | the siege pattern: Bukkit-free state machine in `core/siege` returning `SiegeEffect`s, a 1 s ticker in `SiegeService`, `SiegeMatchObserver` hooks, `SiegeResultSpool` | No shared minigame framework. Siege membership is hard-wired at about 12 touchpoints in `KnKPlugin` (§11). |
| PvP only for duelists | `SiegeCombatListener` un-cancels `EntityDamageByEntityEvent` at HIGHEST and never changes WG flags; `SiegeCombatRules.decide` | Potion and area effects blocked by WG `pvp deny` aren't covered by an un-cancel. WG's `DisallowedPVPEvent` isn't used anywhere yet. |
| Enchantment effects in safezones | `WorldGuardCombatSafezones` `combatExemption` BiPredicate (KNG-11) | Wired to siege only. |
| Coin stakes | `ICurrencyService.PostAsync` (multi-leg, idempotent `(scope,key)`, enlists in the caller's transaction), `ReverseAsync`, reason table `CurrencyReasons`, `TransferPolicyEvaluator`, admin-editable `CurrencyPolicy` (`MinSenderAccountAgeHours`, title, caps) | **No hold or escrow primitive**, no `DUEL_*` reasons, no `SYS_DUEL` account, no generic plugin spend endpoint (each feature exposes its own). Gems are non-transferable by decision. |
| Item stakes, kit loan | `SiegePlayerVault`: snapshot to YAML before the teleport, restore on end, quit or join, atomic temp-file + move | **No server-side item storage.** Only lootbox non-stackables have an identity (`ItemInstance`, PDC `knk_item_instance`), and ownership transfer of instances is not built. The vault is siege-specific. |
| Kits | `Kit` entity (armour, hand, shield, slot-indexed contents of `ItemBlueprint`s; access gating, cost, cooldown); plugin `kit/KitGrantPlacer` | No "loaned" kit that is taken back afterwards. |
| Invites | `TeleportRequestService` / `TeleportRequestBook`: id-stamped clickable `[Accept] [Deny]`, expiry sweep, cleared on quit, ignore-list, vanish-safe name resolution | Teleport-specific; copy or generalise. |
| Stake UI | plain Bukkit inventories (`SiegeEnchantMenu`, KNG-13 `OfflineStorageViews`); `AnvilCaptureManager` / `ChatCaptureManager` for amounts | The menu runtime cancels every click; deposit slots, shared inventories and click-type actions are unbuilt gaps G2–G4. |
| Arena and spectator menus | `MenuFeature` + API-seeded templates, `refreshOpenMenus`, `AutoRefreshTicks`; `SiegeMenuBridge`, `StatisticsMenuFeature`, `TargetUserView` | none |
| Stats | `StatisticsApi.getUserStatistics` (filtered by viewer); free-form context keys; projector-per-minigame pattern (`SiegeStatisticsProjector`); per-player `PlayerStatVisibility` | No duel context or projector. W/L/D are projection-only. Configurable metrics default to visibility **nobody**. |
| Match record | `SiegeMatch` + `SiegeMatchService`: `RunLockedAsync` row lock, idempotent by status, `[RequirePluginService]`, `abort-unfinished` at startup | No Duel entity. |
| Alt detection | — | The API stores no IP or device data, so linked accounts can't be detected (§10). |

## 3. Decisions

"Developer" rows were decided on 2026-10-20. "Proposed" rows are design choices that the developer's answers didn't contradict.

| ID | Decision | Status | Why |
|---|---|---|---|
| **D1** | **Stakes are negotiated in the invitation phase**, as immutable offers with a bounded number of turns (§6). There is no stake editing in warmup. | developer (option chosen from rev. 1) | The invitee sees what is at stake before saying yes. The warmup announcement and spectator menu show final stakes. Nobody is teleported for a duel that falls apart over stakes. Immutable offers remove v1's shared-inventory complexity (§6.4). |
| **D2** | **Turn limit = `Arena.MaxOffers`, set in the web app, default 3.** Offer 1 is the inviter's; each later offer is a counter by the other side; the last allowed offer can only be accepted or declined. | developer | `2` = "initial + one counter"; `4` = "two each, invitee last". |
| **D3** | **Stake items don't move during negotiation.** An offer *references* items in the owner's inventory. At lock-in, both players' items are checked and removed in one main-thread tick into a local escrow spool. | proposed | No dupe or steal surface while players negotiate and chat. The single tick removes the check-then-act race (V4). |
| **D4** | **Coins are debited at lock-in by the API**: one posting with two debit legs into `SYS_DUEL`, in the same DB transaction that creates the `DuelMatch` row. | proposed | All or nothing; no clamping (V1). No hold primitive is needed: the money really moves to a system account and back out at settlement. |
| **D5** | **Lock-in happens on acceptance, before teleporting.** "Match created" ⇔ stakes escrowed. A failed teleport cancels the match and refunds it. | proposed | Clear invariant. The announcement can name the stakes. |
| **D6** | **Lobby teleports go through the engine with a normal warmup** (new kind `ARENA`: player-style warmup and combat-tag guard, no cooldown, no charge). Both start together. If either outcome isn't `TELEPORTED`, the match is cancelled and refunded. | developer (requirement) | "Teleportation follows the default teleportation engine." |
| **D7** | **Battleground and exit teleports are system teleports** (kind `ARENA_SYSTEM`: instant, no cooldown, combat tag or charge; safe-spot checked; not audited as staff). A failed battleground move aborts with a refund. | proposed | The runtime must move players on schedule. |
| **D8** | **PvP is decided by the duel runtime, not by WG flags**: a HIGHEST un-cancel for the fighting pair, a deny for everyone else, and a `DisallowedPVPEvent` handler (§8.1). | developer (requirement) / proposed (mechanism) | Siege precedent. Works in no-PvP towns. Stops third-party interference (V7). |
| **D9** | **Gear modes** per match, chosen in the proposal from what the arena allows (§6.2):<br>- `OWN_GEAR_KEEP`: own gear, the inventory is kept on death<br>- `OWN_GEAR_DROP`: own gear, the loser's inventory goes to the winner<br>- `FIXED_KIT`: both use the kit the proposal names<br>- `KIT_CHOICE`: each duelist picks from the eligible kits<br><br>The arena's admin settings decide which modes the proposal may offer. | developer | Kits even the odds. Drop mode is the high-stakes variant. The admin controls both. |
| **D10** | **Any death in `FIGHT` loses**, whatever the cause. Quitting or disconnecting from `BATTLE_COUNTDOWN` on is a **forfeit**. Before that it **cancels** with a full refund. | developer (Q3: cancel) | A cancel never moves value between players (§10), so cancelling can't be abused for transfers. |
| **D11** | **Fight time limit `Arena.FightTimeLimitSeconds`**, set in the web app, default 300, `0` = no limit. At the limit the match is a **draw with full refund**. With no limit, players can agree a draw with `/duel draw`; staff can cancel. | developer (Q5) | Configurable. With no limit, an agreed draw and staff cancel stop a match that would otherwise never end. |
| **D12** | **Arenas are domains; their battlegrounds, spectator areas and lobby are not** (rev. 6, developer 2026-10-24):<br>- `Arena : Structure` stays a domain with normal domain behaviour (enter/leave message, discovery, `/navigate`, entry/exit flags, KNG-253 sub-regions)<br>- its **areas** are the arena's own sub-structure: `ArenaArea` (kind `BATTLEGROUND`, `SPECTATOR` or `LOBBY`) with 1..n `ArenaAreaRegion`s (§4.1)<br>- areas carry no domain behaviour: no enter/leave messages, discovery, navigation or `knk-allow-entry/exit` flags<br><br>Rev. 2–5 had `ArenaBattleground : Domain` and `ArenaSpectatorArea : Domain` (TPT child domains) and `Arena.LobbyLocationId`; rev. 6 replaces all three. | developer (Q2; revised 2026-10-24) | Domains carry global rules (enter/leave messaging, discovery, navigation, entry and exit flags) these areas must not have, and a child model of `Domain` for them was ambiguous. The arena keeps what a domain gives it. An area can be drawn from several regions (a round battleground, a ring of stands), and the duel runtime enforces access over the union of its regions (§8.2). |
| **D13** | **Concurrent matches, one per battleground; a capped queue per arena** (`Arena.MaxQueuedMatches`, default 3). | developer (queue cap) / proposed | `arena_2` has 8 battlegrounds. The cap stops a crowded lobby. |
| **D14** | **Staking needs eligibility.** The rules are an account-age minimum, a title minimum, and no freeze or transfer lock. They are per arena, defaulting to the `/pay` rules in `CurrencyPolicy`. They apply to anyone staking coins or items, and to both players in `OWN_GEAR_DROP`. **Gems can't be staked.** | developer (Q6: configurable) | A thrown duel is a disguised transfer. Gems are non-transferable by decision ([currency DESIGN](../currency-payments/DESIGN.md) line 603). |
| **D15** | **Arena fee: 5% of the coin pot on decisive results**, configurable 0–20%. None on draws, cancels or friendly duels. The fee is posted to a sink, not paid to anyone. | proposed (developer asked for a recommendation, Q7) | It is a coin sink for the economy, and it makes laundering coins through thrown duels cost money every time. Honest players only pay when there is a winner. |
| **D16** | **Area access is enforced by the duel runtime's own WorldGuard session rule** over the union of an area's regions (rev. 6, §8.2), not by WG membership and not by the domain-access handler. The managed policy gives battleground regions `pvp allow` + `entry allow`, and every area region `entry allow`; the runtime decides who may cross. | proposed (Q8, developer asked for a recommendation); mechanism revised 2026-10-24 (developer) | WG membership gives build rights in the region and stays in WG's region files after a crash. Areas are not domains any more (D12), so the domain-access handler and its exemptions port no longer apply to them. A session rule of the runtime's own covers walk, vehicle, glide, pearl and teleport the same way. |
| **D17** | **Duel W/L/D are visible to everyone by default.** Each player can change it through the normal statistics visibility setting. | developer (Q9) | A public competitive record, with the player in control. |
| **D18** | **Accept rules**: the invitee may accept from anywhere, except while in a minigame (siege, another duel or negotiation lock), combat-tagged, frozen or dead. | developer (Q10, confirmed O1) | The lobby teleport brings the invitee. |
| **D19** | **Spectating is physical and passive.** Spectators stand in the arena's spectator area (normal gamemode) and use a read-only menu. They walk in, or take an `ARENA` engine teleport from the arena menu or `/duels spectate` that checks the area's optional title and gem conditions (§9.3). Spectator betting is out of scope. | proposed; teleport path developer 2026-10-24 | Simple and safe. Betting is gambling with its own abuse model. |

## 4. Data model

### 4.1 The arena domain and its areas (API, form-configurable, `knk.admin.world`)

*Rev. 6 (developer, 2026-10-24).* Rev. 2–5 modelled battlegrounds and spectator areas as child domains (`ArenaBattleground : Domain`, `ArenaSpectatorArea : Domain`) and the lobby as `Arena.LobbyLocationId`. They are now **areas**: plain owned rows of the arena, each with its own WorldGuard regions and no domain behaviour.

```
Domain (domains)                                    ── KNG-253: + SubRegions 0..n (DomainSubRegion)
 └─ Structure (structures: StreetId, HouseNumber, DistrictId)
     └─ Arena (arenas)                              ── one row per arena; its WgRegionId (+ sub-regions) is the whole arena
          Key (unique)
          ExitLocationId?     (FK Location, Restrict)   null → the domain's own Location
          IsDuelEnabled
          … duel settings, §4.2
          Areas           0..n  ArenaArea
          EligibleKits    0..n  ArenaKit

ArenaArea (arena_areas)                             ── plain owned table, NOT a Domain
  Id, ArenaId (FK cascade)
  Kind        : BATTLEGROUND | SPECTATOR | LOBBY   (stored as a string)
  Key         (unique per arena, e.g. "bg1", "stands", "lobby")
  Name?       (label for menus and the boss bar; null → Key)
  SortOrder   (battleground allocation order; the first enabled spectator area is the spectate target)
  IsEnabled
  SpawnALocationId?, SpawnBLocationId?   (FK Location, Restrict)   BATTLEGROUND only
  ArrivalLocationId?                     (FK Location, Restrict)   SPECTATOR and LOBBY: where a teleport lands
  TeleportMinTitleBracketId?             (FK TitleBracket, SetNull) SPECTATOR only: minimum title to teleport there
  TeleportPriceGems?                     (int ≥ 0)                 SPECTATOR only: gem price of that teleport
  Regions     1..n  ArenaAreaRegion

ArenaAreaRegion (arena_area_regions)
  Id, ArenaAreaId (FK cascade)
  WgRegionId  (tempregion_worldtask_<n> until saved, then arena_<arenaId>_<kind>_<id>)
  WorldName
  CreatedAt

ArenaKit (arena_kits): ArenaId (FK cascade), KitId (FK Restrict), SequenceNumber; key (ArenaId, KitId)
DuelMatch.BattlegroundId → ArenaArea (SetNull)
```

- **Kinds:**

  | Kind | What it is | Per arena | Uses |
  |---|---|---|---|
  | `BATTLEGROUND` | a fighting area; one match at a time (D13) | 1..n (needed for a match, not for saving) | `SpawnA`/`SpawnB`, regions |
  | `SPECTATOR` | the stands | 0..n, normally one | `Arrival`, `TeleportMinTitleBracketId`, `TeleportPriceGems`, regions |
  | `LOBBY` | where duelists warm up (§5) | 0..1 (1 while duels are on) | `Arrival`, regions |

  Fields of another kind are cleared on save, so a form switched from spectator to battleground keeps no stale arrival point.
- **Regions.** An area has one or more WorldGuard regions; the area is their **union** (KNG-253's union containment is the pattern): walking from one part of a battleground into the other is neither leaving nor entering it (§8.2). Regions are drawn through world tasks (`ReagionCreate`, like a domain sub-region) or adopted with `select`, and **renamed on save** to `arena_<arenaId>_<kind>_<regionId>` (`kind` in lower case: `battleground`, `spectator`, `lobby`; `regionId` is the `ArenaAreaRegion` id, stable when another part is removed). A re-run of a region's world task replaces it in place (KNG-103).
- **Validation (API):**
  - an **enabled battleground** needs both spawns and at least one region; the last region of an enabled battleground can't be removed
  - **duels on** (`IsDuelEnabled`) needs an enabled `LOBBY` area with an arrival location; that area can't be disabled, emptied of its arrival or deleted while duels are on
  - at most one `LOBBY` area per arena; `Key` unique within the arena
  - spawns and arrival locations lie in the world of one of the area's regions (the arena's world while the area has none)
  - a region lies in the arena's world, and its id isn't used by any domain's main region, any domain sub-region or another area region in that world
  - `TeleportPriceGems` ≥ 0; the title bracket exists
- **Managed-region repair** (plugin, from the arenas list; areas are not in the domain lists):

  | Region | Kind | Parent region | Policy |
  |---|---|---|---|
  | `Arena` | `ARENA` | its District's region | as before |
  | `BATTLEGROUND` area region | `BATTLEGROUND` (floor 50) | the arena's main region | `pvp allow` + `entry allow` (ENFORCE) |
  | `SPECTATOR` area region | `SPECTATOR_AREA` (floor 40) | the arena's main region | `entry allow` (ENFORCE) |
  | `LOBBY` area region | `LOBBY` (new, floor 50) | the arena's main region | `entry allow` (ENFORCE) |

  `entry allow` everywhere: WorldGuard never refuses an area; the duel runtime decides (§8.2). Area regions get no `knk-allow-entry/exit`, `knk-domain-name` or `knk-domain-id`: the domain access sync clears them, so they count as no domain.
- **Orphans.** An area region that no arena lists any more (the row, its area or its arena was deleted) is an orphan, handled like a KNG-253 orphaned sub-region: after two arena refreshes without it, its parent link is removed and it gets `knk-orphaned-since`; the daily temp-region cleanup deletes it once that is older than the retention period (`regions.temp-retention.days`, 14) and a fresh `GET api/Arenas/areas/by-region/{id}` answers 404. Until then it can be adopted again with `select`.
- **Seed**: none (developer, 2026-10-21). Staff create `arena_2` in the Arena form and its areas in the area form, adopting v1's `arena_2,<part>-battleground` regions with `select` (renamed on save).
- **No discovery or navigation for areas.** The arena itself has both, as a structure. The `ArenaBattleground`/`ArenaSpectatorArea` discovery rule types and navigation types of rev. 2–5 are removed.

### 4.2 Duel settings on the Arena (web-app form, defaults in brackets)

| Group | Field | Default | Notes |
|---|---|---|---|
| General | `IsDuelEnabled` | true | needs an enabled `LOBBY` area with an arrival location (§4.1); a new arena is saved with it off until the lobby exists |
| | `MaxQueuedMatches` | 3 | matches that are accepted but not yet in a battleground (TRAVELLING + WARMUP + waiting) |
| Negotiation | `MaxOffers` | 3 | 1–6; D2 |
| | `OfferSeconds` | 60 | per turn |
| Stakes | `AllowCoinStakes`, `AllowItemStakes` | true, true | |
| | `MaxCoinStake` | 10,000 | per side |
| | `MaxItemStacks` | 9 | per side |
| | `MinStakeRatioPercent` | 50 | the smaller coin stake must be ≥ this % of the larger; 0 = off (§10) |
| | `FeePercent` | 5 | 0–20; D15 |
| Eligibility | `StakeMinAccountAgeHours` | null → `CurrencyPolicy.MinSenderAccountAgeHours` (48) | D14 |
| | `StakeMinTitleBracketId` | null → the `/pay` minimum (Peasant) | |
| Abuse limits | `MaxStakedDuelsPerPairPerDay` | 3 | §10 |
| | `PairCooldownMinutes` | 10 | between staked duels of the same two players |
| | `DailyCoinWinCap` | 25,000 | per player per day; 0 = off |
| Gear | `AllowOwnGearKeep` | true | |
| | `AllowOwnGearDrop` | false | |
| | `AllowFixedKit`, `AllowKitChoice` | false, false | need ≥ 1 `EligibleKits` |
| | `DefaultGearMode` | `OWN_GEAR_KEEP` | must be one of the allowed modes |
| | `EligibleKits` | — | `ArenaKit` list, ordered; the first is the default pick in `KIT_CHOICE` |
| Timing | `WarmupSeconds` | 30 | |
| | `CountdownSeconds` | 10 | the requirement says 10; editable |
| | `FightTimeLimitSeconds` | 300 | 0 = no limit; D11 |
| | `MaxWaitSeconds` | 180 | waiting for a free battleground, then cancel and refund |
| | `WinnerLingerSeconds` | 5 | |
| Announcements | `AnnounceMatches` | true | |
| | `AnnounceFriendly` | true | duels without stakes |

- **Area fields** (the `ArenaArea` form, §4.1):

  | Kind | Field | Default | Notes |
  |---|---|---|---|
  | all | `Kind`, `Key`, `Name`, `SortOrder`, `IsEnabled` | —, —, null, 0, false | turn a battleground on once both spawns and a region are set |
  | `BATTLEGROUND` | `SpawnALocationId`, `SpawnBLocationId` | null | where the challenger / opponent stand in the countdown |
  | `LOBBY` | `ArrivalLocationId` | null | the lobby teleport's destination (D6); replaces rev. 5's `Arena.LobbyLocationId` |
  | `SPECTATOR` | `ArrivalLocationId` | null | the spectate teleport's destination; without one the area is reached on foot only |
  | `SPECTATOR` | `TeleportMinTitleBracketId` | null (none) | minimum title for the spectate teleport (not for walking in) |
  | `SPECTATOR` | `TeleportPriceGems` | null (free) | gem price of the spectate teleport, charged through the teleport fee path |
  | — | `Regions` | — | `ArenaAreaRegion` list (owned, after the area's first save), drawn by world task |

- The API validates the settings. At least one gear mode must be allowed. A kit mode needs at least one eligible kit. `DefaultGearMode` must be allowed. `MinStakeRatioPercent` is 0–100.
- The detection thresholds and escalation rules of §10.3 are cross-arena (they follow players, not arenas). They live in one global `DuelPolicy` record, edited in the web app like `CurrencyPolicy`.
- The plugin reads the settings through a cache-first gateway and refreshes on change.
- Technical knobs stay in plugin `config.yml` (§12).

### 4.3 Match record (API, append-only history; not form-configurable)

```
DuelMatch (duel_matches)
  Id, PublicToken (uuid, used in plugin files and logs)
  ArenaId, BattlegroundId?             (null until allocated)
  ChallengerUserId, OpponentUserId
  GearMode, FixedKitId?, ChallengerKitId?, OpponentKitId?
  Status    : Created | InProgress | Completed | Cancelled | Aborted          (stored as string)
  EndReason : Win | Forfeit | TimeLimit | AgreedDraw | SimultaneousDeath       (Completed; all but the first two are draws)
            | TeleportFailed | PlayerLeftLobby | NoBattleground | AdminCancelled     (Cancelled)
            | ServerRestart | ApiOutage                                            (Aborted)
  WinnerUserId?
  ChallengerCoins, OpponentCoins, FeeCoins     (long, ≥ 0)
  StakeItemsJson, SpoilsItemsJson      (audit summaries: owner, material, amount, name, grade, instance id)
  StakeTransactionId?, SettlementTransactionId?
  Review    : None | Flagged | Held | Released | Voided     + ReviewTier, ReviewSignals, AlertId?, ReviewedByUserId?, ReviewedAt?
  FightTelemetryJson                   (duration, damage dealt/taken per side, hits, loser's attack attempts; §10)
  OfferCount
  CreatedAt, LockedAt, FightStartedAt?, EndedAt?
```

- Items are recorded for audit only. The authoritative item escrow is the plugin spool (§7.2), because the API can't store arbitrary `ItemStack`s.

### 4.4 Runtime (plugin, in memory)

- **`DuelOffer`**
  - `offerId`, `version`, `author`
  - `gearMode`, `fixedKitId?`
  - `stakeA` / `stakeB`, each `{coins, List<ItemRef>}`
  - `expiresAt`
- **`DuelNegotiation`**
  - `negotiationId`, inviter, invitee, `arenaId`
  - offers, `turn`
  - `state ∈ {AWAITING_RESPONSE, LOCKING, CLOSED}`
- **`DuelMatchRuntime`**
  - `matchToken`, API id, both players, arena/battleground, `DuelPhase`, deadlines
  - each duelist's chosen kit
  - the escrow handle, the vault handle (kit modes), the per-player restore snapshot
  - fight telemetry counters
- **`ItemRef`**
  - a copy of the `ItemStack` (amount included) plus the slot it came from, as a hint
  - matched at lock-in by `isSimilar` + amount

## 5. Lifecycle

```
       /duel <p>, or the arena menu (inviter inside an enabled arena, not in combat or a minigame)
                                   │
                         ┌─────────▼─────────┐  decline / expire / quit / last offer declined
                         │   NEGOTIATING     │──────────────────────────────► closed (nothing moved)
                         │ offer ⇄ counter   │
                         └─────────┬─────────┘
                                   │ accept(offerId)   (accept rules D18; arena queue not full)
                         ┌─────────▼─────────┐  items or coins missing / ineligible / limits / API refused
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
                         │ lobby, spectators,│
                         │ kit (§8.4);       │
                         │ waits for a free  │
                         │ battleground      │
                         └─────────┬─────────┘
                                   │ warmup over and battleground allocated
                         ┌─────────▼─────────┐  system teleport failed → ABORTED + refund
                         │ BATTLE_COUNTDOWN  │  quit → forfeit (opponent wins)
                         │ frozen,           │
                         │ damage locked     │
                         └─────────┬─────────┘
                                   │ "FIGHT!"
                         ┌─────────▼─────────┐  death → win; quit → forfeit; time limit / agreed → draw
                         │       FIGHT       │  outage / restart → abort (refund)
                         └─────────┬─────────┘
                         ┌─────────▼─────────┐
                         │      ENDING       │  settle (idempotent; may be held for review),
                         └───────────────────┘  kit returned, vault restored, exit teleports
```

### 5.1 Phase rules

| Phase | Duelists can | Duelists can't | Timing |
|---|---|---|---|
| NEGOTIATING | anything; chat; open the offer view | be in another negotiation, match or siege | `OfferSeconds` per turn |
| LOCKING | — (a few hundred ms) | teleport, drop items, open containers | API timeout 10 s → refused |
| TRAVELLING | move (moving cancels their own warmup, which cancels the match) | other teleports | engine warmup (5 s / 3 s) |
| WARMUP | walk in the lobby, chat, open the match menu, choose or swap a kit (`KIT_CHOICE`) | hit or be hit (§8), teleport out, join a siege, drop or store items; in kit modes, use kit consumables (eat, drink, throw) | `WarmupSeconds`, then wait for a battleground up to `MaxWaitSeconds` |
| BATTLE_COUNTDOWN | look around, manage inventory | move off their spawn block, deal or take damage, throw projectiles or pearls | `CountdownSeconds` |
| FIGHT | fight each other; offer an agreed draw | hit or be hit by anyone else, leave the battleground, teleport, drop items | `FightTimeLimitSeconds` (0 = none) |
| ENDING | winner lingers | fight | `WinnerLingerSeconds`, then exit |

- The battleground is allocated at the end of WARMUP, not at lock-in.
- Waiting matches see "Waiting for a free battleground (#2 in line)" on the boss bar.

### 5.2 Queue cap

- **What counts**: `Arena.MaxQueuedMatches` counts this arena's matches in TRAVELLING or WARMUP (accepted, not yet on a battleground).
- **When it is checked**:
  - when sending an invite: advisory. "The Arena is full (3/3 waiting), try again shortly."
  - at accept: binding, checked before lock-in. A full queue refuses the accept; nothing is taken.
- The arena menu shows the queue (`2/3 waiting, 5/8 battlegrounds busy`).

## 6. Invitation and stake negotiation

### 6.1 Entry points and commands

```
/arena [name]                open the arena menu (§9.3): live matches, queue, spectate, challenge a player
/duel <player>               open the proposal editor (inviter must be inside an arena)
/duel <player> quick         invite at once: no stakes, the arena's default gear mode
/duel accept <id>            accept the offer with that id (clickable)
/duel counter <id>           open the proposal editor pre-filled with that offer
/duel decline <id> | cancel  end the negotiation
/duel view <id>              open the read-only offer view
/duel kit                    (KIT_CHOICE, in warmup) choose your kit
/duel draw                   (FIGHT) offer or accept an agreed draw
/duel toggle                 refuse all duel invites (persisted per player)
/duels                       live matches across all arenas (spectator menu, §9.2)
/duel claim                  collect unclaimed winnings or returned items (§7.4)
/knk duel list | cancel <match> | refund <match> | review <match> release|void    staff
```

**Invite rules** (checked at invite, and again at accept where marked):
- **Inviter**:
  - is inside an enabled arena: its main region, one of its KNG-253 sub-regions or one of its areas' regions (rev. 6)
  - is not combat-tagged, in a minigame or frozen
  - has no other outgoing negotiation
- **Invitee**:
  - is online and visible
  - isn't ignoring the inviter and hasn't turned invites off
  - has at most 3 incoming negotiations
- **Accept rules** (D18), checked at accept: not in a minigame, combat-tagged, frozen or dead.
- **Pair and arena**: pair limits and the arena queue cap (§10, §5.2).
- **Teleport pre-check**: both players are checked with `TeleportService.check(ARENA plan)` at invite and at accept. The engine refuses combat-tagged players itself.
- A send cooldown applies, and there are no self-duels.

### 6.2 What a proposal contains

An offer is a **complete contract**:

| Part | Who may set it |
|---|---|
| Gear mode, one of the arena's allowed modes (§3 D9) | the author of each offer; a counter may change it |
| `FIXED_KIT` kit, one of the arena's eligible kits | the author |
| Coins per side (`AllowCoinStakes`) | the author, for both sides |
| Items per side (`AllowItemStakes`) | only the owner may **add** their items; the author may **remove** the other side's items |

- Offer #1 "own gear, drop on death; I stake my diamond sword, you stake 500 coins" can be expressed.
- "You stake your helmet" can't, until the opponent offers it themselves.
- An empty contract with `OWN_GEAR_KEEP` is a **friendly** duel: same flow, no escrow, no fee, no eligibility check.

### 6.3 Offer protocol

```
offer #1  inviter                                   → invitee: Accept | Counter | Decline
offer #2  invitee (counter)                         → inviter: Accept | Counter | Decline
offer #3  inviter (last when MaxOffers = 3)         → invitee: Accept | Decline
```

- Every offer gets a fresh `offerId`. Accept works only for the **current** offer, so a stale chat button can't accept an old one. This fixes V5.
- Each turn gets `OfferSeconds`. Expiry, a quit, death or joining a siege closes the negotiation. Nothing is held, so nothing needs refunding.
- Validation when an offer is sent (advisory) and at lock-in (binding):
  - coin bounds and `MinStakeRatioPercent`
  - each item present in its owner's inventory
  - the item blocklist (§7.6) and stack limits
  - eligibility (D14)
  - pair and daily limits (§10)
  - the gear mode allowed by the arena; the fixed kit still eligible
- Each failed check names the reason.

### 6.4 Proposal editor and offer view (UI)

- **The proposal editor** is a hand-rolled 54-slot Bukkit inventory with its own holder (like `SiegeEnchantMenu`). Every click is cancelled, so no item ever enters or leaves it.

  ```
  row 0   [your head card]  .  [GEAR MODE ▸ cycle]  [ARENA card]  [KIT ▸ pick]  .  [opponent head card]
  row 1-2 [your stake: up to 9 item icons]   |   [their stake: icons, click = remove]
  row 3   [your coins −100 −10 [amount] +10 +100]  |  [their coins −100 −10 [amount] +10 +100]
  row 4   [fee: 5% of the pot on a decisive result]   [eligibility / limit warnings]
  row 5   [Cancel]     [Type exact amount (anvil)]     [Send offer #n of max]
  ```

  - **Gear mode**: the button cycles through the arena's allowed modes, with each mode's meaning in its lore. Only modes the arena allows are shown, so an arena with one mode shows a fixed label.
  - **Kit**: shown only for `FIXED_KIT`. It opens a picker of the eligible kits with item previews.
  - **Items**: click an item in **your own** (bottom) inventory to add a copy-reference to your half. The item stays where it is and gets a "Staked in offer" lore line in the view. Click an icon in your half to remove it.
  - **Exact amounts**: entered with `AnvilCaptureManager`. Your balance is shown as a hint; the API decides at lock-in.
- **The offer view** is read-only, with the same layout plus `[Accept] [Counter] [Decline]`. The last allowed offer has no Counter.
- **Chat** carries the same actions, so a player can answer without opening anything:

  ```
  ⚔ Pandi challenges you to a duel at the Arena (offer 1/3, 60 s) — own gear, inventory DROPS on death
     You stake: 500 coins          Pandi stakes: Diamond Sword ★★★, 200 coins
     [View] [Accept] [Counter] [Decline]
  ```

- Drop mode is spelled out in capitals in the chat line and shown in red in the view, so nobody accepts it by accident.
- Players chat normally (or with `/msg`) between turns, because no menu is held open by the protocol.
- **No menu-runtime gaps G2–G4 are needed.**

### 6.5 Lock-in (on accept)

1. **Pre-checks** (main thread):
   - accept rules (D18) and the queue cap
   - `TeleportService.check` for both
   - each `ItemRef` still present (`isSimilar` + amount)
   - blocklist, gear mode and kit still valid
2. **Take items** (same tick):
   - write `duel-escrow/<matchToken>.yml` with both players' items (Paper `serializeItemsAsBytes`, temp file + atomic move, state `LOCKING`)
   - **then** remove the stacks from both inventories
   - a failed write removes nothing and refuses the accept
3. **API** (async): `POST api/DuelMatches` with both user ids, gear mode and kit, the coin amounts, the item audit summary, and `Idempotency-Key: duel-lock:<matchToken>`. In one DB transaction the API:
   - checks eligibility and the abuse limits (§10)
   - inserts `DuelMatch(Status=Created)`
   - posts `DUEL_STAKE` with two debit legs into `SYS_DUEL`
   - refuses with nothing posted if anything fails
4. **Back on the main thread**:
   - **Success**: spool state `ESCROWED` with the API id → TRAVELLING.
   - **Refused or failed**: the items go back (inventory → ender chest → claim), the negotiation closes with the API's reason.
   - **Timeout**: first `GET …/by-token/<matchToken>`. A create that did land is cancelled and refunded rather than leaked.

## 7. Escrow, settlement and refunds

### 7.1 Currency (API)

| Code | Kind / direction | System account | Notes |
|---|---|---|---|
| `DUEL_STAKE` | Spend / Debit | `SYS_DUEL` | two legs per match, `SourceType=DuelMatch`, `SourceRef=<id>` |
| `DUEL_PAYOUT` | Grant / Credit | `SYS_DUEL` | pot − fee to the winner |
| `DUEL_FEE` | Spend / Debit | `SYS_FEES` (as `TRANSFER_FEE`) | `FeePercent` of the pot, rounded down, decisive results only (D15). Phase 2 decides how the fee leaves `SYS_DUEL` against the ledger's leg rules: a system-to-system leg, or a fee posting inside the payout transaction. Either way, the invariant below holds |

- The reasons are added to `CurrencyReasons` in the same PR as the first call (`CurrencyReasons.cs:38-41`).
- **Refunds** use `ReverseAsync(stakeTx)` with key `reverse:<stakeTxId>`.
- **Reconcile invariant**: per closed match, Σ `SYS_DUEL` legs = 0. An open or held match holds exactly the sum of both stakes.

### 7.2 Items (plugin spool)

- `plugins/KnightsAndKings/duel-escrow/<matchToken>.yml` holds:
  - `state ∈ {LOCKING, ESCROWED, HELD, SETTLED, REFUNDED, CLAIM_PENDING}`
  - the API match id
  - both players' staked stacks
  - drop-mode spoils (§8.5)
  - per player, the stacks still owed
- It is written before every change, then moved atomically.
- `ItemInstance` ids keep their PDC tag. `OwnerUserId` isn't updated: instance ownership transfer isn't built ([lootboxes DESIGN](../lootboxes/DESIGN.md) lines 33-35). Settlement calls it once it exists (§15).

### 7.3 Crash and restart recovery

At plugin startup:

1. Call `POST api/DuelMatches/abort-unfinished`. Every `Created/InProgress` match becomes `Aborted (ServerRestart)` and is reversed. `Held` matches are left for staff.
2. Scan `duel-escrow/`. For each file, ask the API for the match status:
   - `Completed` with a winner → the items are owed to the winner
   - `Held` → kept
   - otherwise (or 404 for `LOCKING`) → each player is owed their own items
   - delivery happens on join
3. Kit vault snapshots and restore snapshots are applied on join (§8.4): loaned kit items are removed first, then the vault is restored, then held deliveries (lootbox rolls and other rewards) are handed over.

### 7.4 Settlement (win)

1. **Plugin**:
   - the phase moves to ENDING once, guarded by the state machine
   - write the result spool `duel-escrow/pending-results/<matchToken>.json`
   - call `POST api/DuelMatches/{id}/complete {winnerUserId, endReason, telemetry}`
2. **API**, inside `RunLockedAsync(id)`:
   - `Completed` → the stored result
   - `Cancelled/Aborted` → 409
   - otherwise evaluate the review rules (§10)
     - **tier 2 (held, §10.3)**: `Status=Completed`, `Review=Held`; no payout yet, the coins stay in `SYS_DUEL`
     - **tier 0 (clean) or tier 1 (flagged)**: in one transaction, `GrantAsync(winner, pot − fee, DUEL_PAYOUT, key duel-payout:<id>)` + the `DUEL_FEE` leg. A tier-1 result also raises its alert
   - the result says `paid` or `held`
3. **Plugin**:
   - `paid` → give the winner both sides' staked items, plus any drop-mode spoils (inventory → ender chest → `CLAIM_PENDING`)
   - `held` → keep the spool in `HELD`; both players are told the result is under review
   - an offline winner is paid on join
4. **The API is down at settlement**: the result spool is retried until the API accepts it.
   - Items are not paid out until the API has answered, because the API may hold the result for review.
   - The winner is told the payout follows when the server reconnects.

**Staff review** (web app "Duel reviews" page, or `/knk duel review`):
- **Release**: pay the winner as above.
- **Void**: refund both sides' stakes; spoils go back to the loser; no fee.

Each action is idempotent and recorded with the reviewer.

### 7.5 Refund (every outcome that is not a win)

- These go through `POST …/{id}/cancel {reason}`:
  - cancel: `TeleportFailed`, `PlayerLeftLobby`, `NoBattleground`, `AdminCancelled`
  - abort: `ServerRestart`, `ApiOutage`
  - draw: `TimeLimit`, `AgreedDraw`, `SimultaneousDeath`
- It reverses the stake once and sets `Cancelled`, `Aborted` or `Completed` with no winner. No fee is taken.
- The plugin gives each player their own items back. With an API outage, the items are returned at once and the coin reversal is spooled until the API is back.
- Staff `/knk duel refund <match>` uses the same endpoint.

### 7.6 Stake rules

- **Coins**:
  - `1 ≤ c ≤ MaxCoinStake`
  - the ratio rule
  - eligibility
- **Gems**: never.
- **Items**:
  - any item in the main inventory, armour or off-hand
  - at most `MaxItemStacks` per side
  - refused:
    - shulker boxes and bundles with contents
    - written books
    - loaned kit items (`knk_duel_loan`)
    - items the plugin holds for another feature (lootbox, siege vault)
    - the config blocklist (§12)
    - soulbound items, once soulbound is enforced

## 8. Combat, confinement, gear and safety

### 8.1 PvP rule (D8)

- `DuelCombatListener` handles `EntityDamageByEntityEvent` at **HIGHEST**. It resolves the real attacker: projectile shooter, tamed pet's owner, TNT and end-crystal source where known.
- Pure rules in `core/duel/DuelCombatRules.decide(attackerMatch, victimMatch, phase)`:

  | Case | Effect |
  |---|---|
  | Both are duelists of the **same** match, phase `FIGHT`, no `damageLocked` | `setCancelled(false)` (overrides town, district and hub denies) |
  | Same match, any other phase | cancelled |
  | One side is a match participant (LOCKING..ENDING) and the other isn't in that match | cancelled, both ways |
  | Neither is in a match | untouched |

- A `DisallowedPVPEvent` (WorldGuard) handler cancels the event for the same `FIGHT` pair. That covers potions, fire and other paths WG blocks.
- `WorldGuardCombatSafezones.combatExemption` becomes a composite of siege OR duel, so custom-enchantment effects work in battlegrounds (KNG-11).

### 8.2 Entering and leaving the arena's areas (D16, rev. 6)

Areas are not domains (D12), so `DomainAccessHandler` and P0's `DomainAccessExemptions` port don't see them. The duel runtime registers its **own WorldGuard session handler**, `ArenaAreaAccess`, next to `DomainAccessHandler` (same registration, same move types: walk, vehicle, glide, pearl, chorus fruit, teleport).

- **Union containment.** For every crossing the handler looks up which areas the origin and the destination lie in, over **all** regions of each area (KNG-253's union pattern). An area is *entered* when none of its regions contains the origin and one contains the destination, and *left* the other way round. Moving between two parts of one battleground is neither.
- **Rules:**

  | Area | Entering | Leaving |
  |---|---|---|
  | `BATTLEGROUND` | only the two duelists the battleground is allocated to, from the countdown teleport until the exit teleport; everyone else refused ("This battleground is reserved for a duel.") | refused for those duelists in `BATTLE_COUNTDOWN` and `FIGHT`; the runtime's own `ARENA_SYSTEM` exit teleport carries a one-shot pass |
  | `LOBBY` | while a match of this arena is in `WARMUP`, only duelists of this arena's matches; otherwise anyone | free |
  | `SPECTATOR` | free | free |

- **Staff** with `knk.region.bypass` (and WorldGuard's own region bypass) pass every rule, so they can still watch from inside. The combat rule (§8.1) keeps them out of the fight.
- **Memory only**: the allocation and the passes live in the runtime; a crash leaves nothing behind (the next start has no matches, so a free battleground refuses everyone again).
- **Managed policy**: battleground regions keep `pvp allow` (ENFORCE), which takes WG's own PvP checks out of the fighting pair's way, and every area region gets `entry allow`, so WorldGuard's own entry rule (or a v1 `entry deny` on an adopted region) never keeps a duelist out.
- **Known limit**: the rules act on crossings. A player already standing in the lobby when a warmup starts isn't moved out, and nobody can be standing on a battleground when it is allocated except staff, since entry is refused whenever no match holds it.
- **`DomainAccessExemptions`** (P0) stays in the plugin for other minigames; duels no longer register with it.
- **Why not WG membership (v1)**: members get build rights in the region and its children, the membership persists in WG's files after a crash, and it needs a startup sweep.

### 8.3 Other restrictions

- **Teleports**: `DuelTeleportRestriction` refuses every engine teleport other than the runtime's own, from LOCKING to ENDING. That includes `/spawn`, `/warp`, `/home`, `/tpa`, `/back`, `/hub` and menu teleports.
- **Commands**: a `DuelCommandFilter` allow-list in COUNTDOWN and FIGHT (default `/duel,/msg,/r,/staffchat`).
- **Inventory guards** from LOCKING to ENDING: no dropping items, no placing them in containers, frames or armour stands. Duelists can't pass items to an accomplice.
- **Countdown**: duelists are frozen to their spawn block (head rotation allowed), and damage is locked.

### 8.4 Gear modes at runtime (D9)

**Own-gear modes** keep the player's inventory in place, and only a small restore snapshot is taken:

| Mode | When the duelist arrives in the lobby | On death | At ENDING / abort / quit |
|---|---|---|---|
| `OWN_GEAR_KEEP` | snapshot health, food, saturation, effects | keepInventory, keepLevel, no drops | restore health, food, effects |
| `OWN_GEAR_DROP` | same snapshot | **loser**: inventory, armour and off-hand become *spoils* for the winner (§8.5); keepLevel | restore health, food, effects (the loser keeps only what wasn't taken) |

**Kit modes** (`FIXED_KIT`, `KIT_CHOICE`) swap the player's own gear for a loaned kit, and give it back afterwards (developer, 2026-10-20). This is the same model as the siege kit mode in [KNG-199](https://linear.app/kngpandi/issue/KNG-199):

1. **Before the lobby teleport** (in the engine's commit step, after the teleport warmup succeeded and just before the move), the **vault** scans and stores the full inventory, armour, off-hand, XP, health, food, saturation and effects to disk. The stake items were already taken at lock-in, so they aren't part of it. The inventory is then cleared. If the teleport itself then fails, the vault is restored on the spot and the match is cancelled as usual (D6).
2. **On arrival in the lobby**, the kit is granted through `KitGrantPlacer`, with no cost, cooldown or access check. The arena's eligible list is the only gate (developer, O4).
   - `FIXED_KIT`: the kit from the proposal.
   - `KIT_CHOICE`: the arena's first eligible kit as a placeholder. Picking another kit in WARMUP swaps it: the loaned items are removed and the new kit granted. The pick is locked at the countdown. If the player never picks, the placeholder stays (developer, O3).
   - Every granted stack gets PDC `knk_duel_loan=<matchToken>`.
3. **On death**: keepInventory (the kit), no drops.
4. **Restore**, on every way out:

   | Way out | Restore |
   |---|---|
   | ENDING (win, draw) | at the exit teleport |
   | cancel or abort in any phase | at once |
   | quit | inside `PlayerQuitEvent` (`restoreOnQuit`) |
   | API outage | when `HubOutageService` releases the player |
   | server crash | on the next join |

   Each time: remove every `knk_duel_loan` item, clear, restore the vault, delete the file.

- **Pending deliveries** (all gear modes): from LOCKING until the restore, the minigame registry's `holdsLootDrops` is true for both duelists.
  - **Lootbox rolls**: a lootbox reel that was already spinning when the duel started finishes as normal, but its item is held and delivered after the restore. This is the KNG-44 / `deliverLootboxItemsAfterSiege` pattern.
  - **Other item deliveries** (kit claims, rewards) are held the same way.
  - **Opening a new lootbox** during a match is refused.
  - In kit modes this keeps rewards out of the loaned inventory, where the restore would wipe them. In drop mode it keeps them out of the spoils.
- **Kits skip their own requirements in the arena** (developer, O4). A kit that normally needs, say, title 10 is granted to anyone duelling in an arena whose admin selected it. This doubles as a way to try out kits. The same rule applies to the siege kit mode.
- **No kit consumables in warmup**: kit consumables can't be used in WARMUP (eat, drink, throw), so the kit is intact when the fight starts.
- **The vault**: generalised from `SiegePlayerVault` into a shared `MinigamePlayerVault` (plan Phase 0). The file is always written before the inventory is cleared.
- **Loan safety**: a join sweep and the inventory guard remove any stray `knk_duel_loan` item. Loaned items can't be staked, dropped, stored or traded.

### 8.5 Spoils in drop mode

- On the loser's `PlayerDeathEvent` (HIGHEST), the event's drops are captured into the spool as *spoils owed to the winner*, and `event.getDrops()` is cleared. This happens in the same tick and the spool is written first.
- Spoils go to the winner by the same delivery chain as stakes, not as ground items. Ground drops could be lost in lava or the void, despawn, or be picked up by staff, and the spool makes them crash-safe.
- **A forfeit in drop mode** (quitting in COUNTDOWN or FIGHT): the quitter's inventory is taken as spoils at quit (developer, O2). Otherwise quitting would save a losing player's inventory.
- **Draws** in drop mode (time limit, agreed, simultaneous death): nobody loses anything.
- If the result is **held for review**, the spoils stay in the spool until release (to the winner) or void (back to the loser).

### 8.6 Death, respawn and restore

- **Death of a duelist in `FIGHT`**: handled per gear mode (§8.4). The death message goes to the arena and spectators only. `DuelService.handleDeath` records the loss.
- **Respawn**: the loser respawns at the arena exit. `BackDeathExclusion` keeps `/back` from returning them.
- **Winner**: topped up, lingers with a title, then an `ARENA_SYSTEM` teleport to the exit.
- **Two deaths on the same tick**: a draw with refund (`SimultaneousDeath`).
- **Agreed draw**: `/duel draw` by one duelist and then the other within 15 s.

### 8.7 Interaction with other systems

| System | Rule |
|---|---|
| Siege | `joinDenial` refuses players in a negotiation or match; siege members can't send or accept invites |
| Hub / API outage | `HubOutageService.releaseFromMinigame` becomes a composite (§11). An outage aborts the duel and refunds it (coins once the API is back); kit vaults are restored at once, then held deliveries |
| Combat tag | sending and accepting are refused while tagged; the lobby teleport respects it; ENDING clears both tags |
| Statistics | `StatisticsContextResolver` returns `duel` for match participants |
| Discovery, navigation, lootboxes | areas have no discovery or navigation (D12); for players the same exemptions as siege. Lootbox rolls and other item deliveries are held from LOCKING until the restore, and opening a lootbox during a match is refused (§8.4) |
| Scoreboard | duel sidebar for duelists and spectators; `ScoreboardUtil.setKeepOwnScoreboard` takes a composite predicate |
| Freeze / staff | a frozen duelist forfeits only if frozen in FIGHT; staff `/knk duel cancel` at any phase (refund) |

## 9. Announcements, spectating and the arena menu

### 9.1 Announcements

- **Warmup start**, broadcast to all players. It is clickable and uses a template (the `LootboxAnnouncer` pattern):

  ```
  ⚔ Duel at the Arena: Pandi vs Notch — kit duel (Knight) — stakes: 700 coins + 2 items   [Spectate] [Details]
  ```

- **Result**: "Pandi defeated Notch in 1:42 and won 665 coins + 2 items." A held result says "… pending review".
- Draws are announced; cancels only reach the duelists and spectators in the arena.
- `AnnounceMatches` / `AnnounceFriendly` per arena. A spam limiter allows one warmup broadcast per player per `announce.cooldown-seconds` (config).

### 9.2 Spectator menu (`/duels`, menu runtime, templates `duel_matches` + `duel_match_detail`)

- **List**: one row per live match (WARMUP → ENDING): both heads, arena and battleground, phase, timer, gear mode, stake summary.
- **Detail**:

  ```
  [Challenger card]          [VS / phase / timer / gear mode]          [Opponent card]
  kit (if any) · stake items (real icons) · coins       |  kit · stake items · coins
  stats: title, XP, playtime; duel W/L/D, pvp_kills (as visible to the viewer)
  [Go to the spectator area]                                            [Close]
  ```

  Stats come from `StatisticsApi.getUserStatistics(userId, viewerId)`. Duel W/L/D default to everyone (D17); other metrics follow each player's own settings.
- Auto-refresh every second; `refreshOpenMenus` on every phase change.

### 9.3 Spectator area and arena menu

*Rev. 6 (developer, 2026-10-24).*

- **The spectator area** is an arena area of kind `SPECTATOR` (§4.1). Players reach it:
  - **on foot**: free; its regions refuse nobody (§8.2)
  - **from `[Spectate]`** in the arena menu, the warmup announcement, the spectator menu's "Go to the spectator area" button and `/duels spectate <arena>`: an engine teleport of kind **`ARENA`** (player warmup, cancelled by movement or damage; no cooldown, no `/back` entry needed) to the area's `ArrivalLocation`
- **Conditions of the spectate teleport**, set per area: `TeleportMinTitleBracketId` (the player's title must be at least that bracket) and `TeleportPriceGems` (charged once the warmup succeeded, through the teleport fee path of knk-web-api, idempotent per attempt, refunded when the teleport doesn't happen). Both are checked by the API at the charge; a refusal names the reason and charges nothing. Staff with the teleport bypass nodes skip them, as for warps.
- Which area: the arena's first enabled `SPECTATOR` area (by `SortOrder`) with an arrival location. One without an arrival is reached on foot only ("walk to …"); an arena without a spectator area says so, and the button is disabled.
- **Not a `/warp` destination.** Listing the stands in `/warp` and the teleport menu through the destination engine is a future improvement ([KNG-240](https://linear.app/kngpandi/issue/KNG-240), §15); nothing duel-specific is added to the warp list now.
- Players standing in an arena's spectator area (any of its regions) see that arena's duel sidebar and a boss bar for the most recent match.
- Duelists can't hit spectators and spectators can't hit duelists (§8.1). Between spectators, the normal town rules apply.
- **The arena menu** (`/arena`, and later the Arena NPC, §15) shows:
  - arena info
  - live matches (opens the detail)
  - the queue (`2/3 waiting`) and battleground use
  - `[Spectate]`
  - `[Challenge a player]`, only inside the arena (its regions, its sub-regions or its areas): it opens a picker of online players, then the proposal editor
  - `[My claims]`
  - the arena's rules: allowed gear modes, fee, limits

## 10. Abuse prevention

**Threats**:
- value transfer between accounts (alt feeding, real-money trading) by throwing a staked duel or a drop-mode duel
- stats boosting by farming wins
- invite spam
- item duplication

### 10.1 Rules that make abuse impossible or pointless

| Measure | Effect |
|---|---|
| A cancel or draw never moves value | each side gets back exactly its own stake; no fee. Only a *decisive* result moves value, so only fights need watching |
| One-tick item take + spool; idempotent settlement | no dupes, no double payout (V2, V4) |
| Gems can't be staked | gems stay non-transferable |
| Loaned kit items are tagged and swept | kit gear can't leak into the economy |

### 10.2 Limits (per arena, web app; defaults in §4.2)

| Measure | Effect |
|---|---|
| Eligibility (D14) for anyone staking, and both players in drop mode: account age, title, no freeze or transfer lock | fresh alts can't take part in value-moving duels |
| `MaxCoinStake`, `MaxItemStacks` | bounds a single transfer |
| `MinStakeRatioPercent` (50%) | a one-sided coin pot ("I stake 10,000, you stake 0") isn't possible. Moving coins needs matching collateral on the receiving side |
| `FeePercent` (5%) | every laundering round costs money |
| `MaxStakedDuelsPerPairPerDay` (3), `PairCooldownMinutes` (10) | the same two accounts can't shuttle value repeatedly |
| `DailyCoinWinCap` (25,000) | one account can't absorb a large flow through duels in a day |

### 10.3 Detection and review

**Signals.** The plugin sends fight telemetry with every result: duration, damage dealt per side, hits, the loser's attack attempts, and in own-gear modes the loser's armour points and main-hand item at fight start. The API derives **signals** from it, plus the pair's and the winner's history:

| Signal | Meaning (thresholds in `DuelPolicy`) |
|---|---|
| S1 one-sided damage | the loser dealt < 10% of the winner's damage |
| S2 short fight | the fight lasted < 10 s |
| S3 unarmed loser | own-gear mode, the loser had no weapon and no armour |
| S4 passive loser | the loser made no attack attempts |
| S5 one-way pair | the same player won every one of the pair's last 3 value-moving duels |
| S6 funnel | the winner received value from ≥ 3 different opponents with young accounts (< 7 days) within 7 days |

**Escalation tiers** (developer, 2026-10-20). Only *value-moving* results are scored: those with coin or item stakes, or drop-mode spoils. Friendly duels never are.

| Tier | When | What happens |
|---|---|---|
| 0 clean | no signal | paid |
| 1 flagged ("semi-suspicious") | any signal | **paid**, `Review=Flagged`, and a `DUEL_FLAG` alert (severity Warning) in the currency alert pipeline: it shows on the web-app alerts page and as an in-game notice to online staff with the alerts node, the same as suspicious currency alerts |
| 2 held | the **same players** reach `EscalationFlagCount` (2) flags within `EscalationWindowDays` (7) | **held**: no payout until staff release or void it (§7.4); a `DUEL_HOLD` alert (severity High). While the hold is open, new value-moving invites between that pair (or to that beneficiary) are refused; friendly duels stay allowed |

- **"The same players"** counts two ways:
  - the same pair, in either direction
  - the same beneficiary (winner) across different opponents, which catches several alts feeding one main
- **Acknowledging** a tier-1 alert as a false positive removes that flag from the escalation count. Leaving it open, or voiding a held result, keeps it counting.
- **Never a hold on a first flag** (developer, 2026-10-20). However blatant it looks or however large the pot, a single flagged duel is paid and flagged at most.

**Reverting a paid result** (developer: staff can review and revert payouts at any time). On a paid result, from its alert or the duel history page, staff can:

| Action | Coins | Items | Fee |
|---|---|---|---|
| **Revert** (undo the result) | the payout is reversed with the ledger's staff reversal (`ReverseAsync`, `AllowPartial`). A reversal never takes a balance below zero; if the winner already spent coins, what is left is reversed and the shortfall recorded. The recovered coins go back to the **loser first**, up to their stake, then to the winner up to their own stake | stake items and spoils still undelivered (`CLAIM_PENDING`) go back to their original owners. Delivered items can't be pulled back automatically; staff can take them out with `/inventory` / `/enderchest` (KNG-13). The revert lists what is still missing | reversed |
| **Confiscate** (both accounts were in on it) | as Revert, but the recovered coins go to a sink instead of back to the players | undelivered items are destroyed and recorded | kept |

- Either action marks the match `Review=Voided` (DuelStatisticsProjector then stops counting it), counts as a confirmed flag for escalation, and is audited with the staff member and a required reason.
- For coins that can't be recovered, staff still have the existing currency tools: transfer lock, freeze, admin adjust.

**Staff tools.** The web app gets:
- a duel history page: matches, stakes, spoils, telemetry, signals and tiers
- Release / Void on held results
- Revert / Confiscate on paid results
- "clear escalation" for a pair or beneficiary
- **duel restrictions** (developer, 2026-10-21): bar a player, or one specific pair, from *value-moving* duels (coin or item stakes, drop mode) until an optional end date. Friendly duels stay allowed. Checked at invite, accept and lock-in (the API refuses `CreateAsync`), with the same refusal path as an open tier-2 hold. The player sees the reason and the end date. Stored as `DuelRestriction` (user, optional second user for a pair, expires at, reason, staff member); audited and shown on the player's staff profile. There is no all-duels scope: harassment and spam are covered by the ignore list, `/duel toggle` and freeze

In game, `/knk duel review` lists the same. Alerts use the existing acknowledge flow. All staff actions are audited.

**Anomaly detector.** These rules in `CurrencyAnomalyDetector` are extended:
- R3 (funnel) and R4 (ping-pong) treat `DUEL_PAYOUT` as a flow from the loser to the winner
- a new per-pair duel rule
- `DUEL_PAYOUT` is excluded from the R7 mint-rate rule, because it is funded by stakes, not minted

### 10.4 Other measures

| Measure | Effect |
|---|---|
| Stats boosting | W/L/D come only from the API projector. Leaderboards later cap wins against the same opponent per day (the `PlayerPvpKillPairDaily` pattern) |
| Invite spam | send cooldown, max incoming, the ignore list, `/duel toggle` |
| Known limit: alt detection | the API stores no IP or device data, so two accounts of one person are only caught by the behaviour rules above. Linking accounts by IP is a separate privacy decision (§15) |

## 11. Plugin-wide hooks: a minigame participation registry

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

**Proposal**: a `core/minigame/MinigameParticipation` port with:
- `participationOf(UUID)`
- `allowsCombat(attacker, victim)`
- `releaseForOutage(UUID)`
- `holdsLootDrops(UUID)`
- `keepsOwnScoreboard(UUID)`
- `teleportRefusal(UUID, kind)`

`MinigameRegistry` composes siege and duel. In the same no-behaviour-change refactor:
- `SiegePlayerVault` → `MinigamePlayerVault`
- a `DomainAccessExemptions` hook in `DomainAccessHandler` (rev. 6: kept for other minigames; the duel areas use their own session rule, §8.2)

It also helps the later minigames (KNG-72, KNG-50).

## 12. Plugin configuration (technical knobs only)

```yaml
duels:
  enabled: true
  invite:
    max-incoming: 3
    send-cooldown-seconds: 10
  agreed-draw-window-seconds: 15
  command-allow-list: [/duel, /msg, /r, /staffchat]
  item-blocklist: [WRITTEN_BOOK, BARRIER, COMMAND_BLOCK, STRUCTURE_VOID, DEBUG_STICK]
  refuse-filled-containers: true
  announce:
    cooldown-seconds: 120
  api-timeout-seconds: 10
```

Gameplay settings live on the Arena (§4.2) and are edited in the web app.

## 13. Decisions log and open points

### 13.1 Developer answers (2026-10-20)

| # | Question (rev. 1) | Answer | Where |
|---|---|---|---|
| Q1 | Turn limit | Configurable in the web app, default 3 | D2, §4.2 |
| Q2 | Arena entities | API entities, a child type of Structure/domain | D12, §4.1 |
| Q3 | Quit in warmup | Cancel; plus measures against value transfer | D10, §10 |
| Q4 | Loser's inventory | Configurable per arena (keep/drop); the inviter picks if both are allowed | D9, §8.4 |
| Q5 | Fight time limit | Configurable, including no limit | D11 |
| Q6 | Stake cap / eligibility | Configurable (eligibility = account age, title, no freeze/lock) | D14, §4.2 |
| Q7 | Arena fee | Asked for a recommendation → 5%, configurable | D15 |
| Q8 | Battleground entry | Asked for a recommendation → domain-access exemption (rev. 6: the duel runtime's own session rule, §13.4) | D16, §8.2 |
| Q9 | Public duel W/L/D | Yes, with per-player visibility | D17 |
| Q10 | Where the invitee accepts | Not while in a minigame or in combat | D18 |
| Q11 | Other entry points | Arena NPC later; recorded as a future update | §15 |
| — | Queue cap per arena | Added: `MaxQueuedMatches`, default 3 | D13, §5.2 |
| — | Kit mode | Added: `FIXED_KIT` / `KIT_CHOICE`, eligible kits per arena | D9, §8.4 |
| — | Spectator area | Added: optional domain; on foot, warp, arena menu | §9.3 |

### 13.2 Follow-up answers (2026-10-20)

| # | Point | Decision | Where |
|---|---|---|---|
| O1 | Where the invitee accepts | Anywhere, except while in a minigame or in combat (no arena-only option) | D18 |
| O2 | Forfeit in drop mode | The quitter's inventory goes to the opponent | §8.5 |
| O3 | `KIT_CHOICE` without a pick | The arena's first eligible kit | §8.4 |
| O4 | A kit's own requirements in the arena | Skipped: the admin's selection is the gate, and it doubles as a kit try-out. The developer also asked for a siege kit mode per lobby, switchable until the hub teleport, with joined players notified: [KNG-199](https://linear.app/kngpandi/issue/KNG-199) | §8.4 |
| O5 | Suspicious results | Escalation tiers: flag and alert first; hold once the same players keep getting flagged. Never hold on a first flag; staff can revert or confiscate a paid result at any time | §10.3 |
| O6 | Spectator areas per arena | 0..n, normally one | §4.1 |
| — | Kit-mode inventory handling (developer note) | Vault before the lobby teleport, kit on arrival, restore on every way out (API outage and quit included); pending lootbox rolls and other deliveries held until the restore | §8.4 |

### 13.3 Staff tools (developer, 2026-10-21)

| # | Point | Decision | Where |
|---|---|---|---|
| P1 | Duel restrictions vs the currency transfer lock | Build a small duel restriction: **stakes only** (value-moving duels), for a player or a pair, with an optional end date. No all-duels scope. The transfer lock stays the tool for abuse across the economy (it already blocks staking as well as `/pay`); freeze is for serious cases | §10.3 |

**When to use which:**

| Situation | Tool |
|---|---|
| A suspected alt pair, or a player farming value through duels | duel restriction (stakes only), with an expiry |
| Abuse across the economy (duels plus `/pay` and trading) | the existing currency transfer lock |
| Serious or confirmed cheating | freeze |

### 13.4 Arena areas instead of child domains (developer, 2026-10-24, rev. 6)

| # | Point | Decision | Where |
|---|---|---|---|
| R1 | Battlegrounds, spectator areas and the lobby as child domains | **Not domains.** Domains carry enter/leave messaging, discovery, navigation and entry/exit flags these areas must not have. They become the arena's own `ArenaArea` (kind `BATTLEGROUND`/`SPECTATOR`/`LOBBY`) with 1..n `ArenaAreaRegion`; replaces `ArenaBattleground`, `ArenaSpectatorArea` and `Arena.LobbyLocationId` | D12, §4.1, §4.2 |
| R2 | Regions of an area | Drawn through world tasks like domain regions, renamed on save to `arena_<arenaId>_<kind>_<n>`, KNG-253 / KNG-103 rename and orphan retention reused; managed kinds `BATTLEGROUND`, `SPECTATOR_AREA` and a new `LOBBY`, parent = the arena region, `pvp allow` on battlegrounds, `entry allow` everywhere | §4.1 |
| R3 | Who enforces access | The duel runtime, with its own WorldGuard session rule over the union of an area's regions: battleground entry for the allocated pair and `knk.region.bypass` staff only, exit refused in `BATTLE_COUNTDOWN`/`FIGHT` except the one-shot exit pass; spectator areas free on foot | D16, §8.2 |
| R4 | Spectator warp conditions | **Kept**, as optional fields on the spectator area (minimum title bracket, gem price), checked by the API when the `ARENA` teleport's warmup succeeded (nothing charged on a refusal); a `/warp` listing through the destination engine is a future improvement (KNG-240) | §9.3, §15 |
| R5 | Lobby rules | **Duelists-only during a warmup**: while a match is in `WARMUP` there, only duelists (and `knk.region.bypass` staff) may enter the lobby regions; open otherwise | §8.2 |
| R6 | The arena itself | Keeps normal domain behaviour (enter/leave message, discovery, `/navigate`); only its areas are quiet | D12 |
| — | Unchanged | Stake ratio by item value, staff-only review data, `SYS_CONFISCATED`, deaths and quits by phase, W/L/D visibility stay as decided and built (2026-10-21) | §10, report |

**Interpretations made when writing rev. 6** (reversible; also on KNG-197):
- `<n>` in the region name is the `ArenaAreaRegion` id, so names stay stable when another part is removed (KNG-253 Q-naming reasoning).
- At most one `LOBBY` area per arena; the lobby counts only when enabled and with an arrival location.
- The title condition is checked by the API at the charge (after the warmup), like a warp's; the price notice is shown before the warmup.
- Lobby entry during a warmup is allowed to any duelist of a running match of the same arena (so a second match's lobby teleport isn't refused by the first match's warmup).

## 14. Alternative considered: stakes in warmup

The developer chose invitation-phase stakes (D1). For the record:

| | Invitation-phase stakes (chosen) | Warmup stakes |
|---|---|---|
| Invitee knows the stakes before saying yes | yes | no; they may teleport for nothing |
| Announcement and spectator menu show final stakes | yes | only after a delay |
| Failed negotiation | nothing moved, nobody teleported | match cancelled after the teleport |
| Escrow timing | one lock-in at accept | a second lock-in at the end of warmup |

## 15. Future updates (file an issue when picked up)

- **Spectator areas in `/warp`**: list a spectator area as a warp destination through the navigation destination engine ([KNG-240](https://linear.app/kngpandi/issue/KNG-240)), with its title and gem conditions; until then spectating goes through the arena menu (§9.3).
- **Arena NPC**: an NPC (shared NPC platform, KNG-36) that opens the arena menu: challenge a player, spectate, rules. The v1 "Arena Owner" (`Traits/ArenaMaster.java`) is the precedent.
- **Spectator betting**: needs its own gambling and abuse design.
- **Team duels (2v2) and tournaments**: the vision notes a "duel/tournament for a title".
- **Ranked queue / matchmaking and an Elo rating**.
- **Sudden death** as an alternative to the time-limit draw.
- **Duel leaderboards**, with per-opponent caps.
- **`ItemInstance` ownership transfer** on payout (deferred in lootboxes).
- **Account linking by IP/device** for alt detection: a privacy decision first.
