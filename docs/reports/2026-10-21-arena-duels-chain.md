# Arena duels chain — progress report

**Status:** In progress (wave 1).
**Last updated:** 2026-10-21
**Linear:** [KNG-197](https://linear.app/kngpandi/issue/KNG-197) (design) and its phase issues.
**Charter:** [ARENA_DUELS_CHAIN.md](../ai-agents/handoffs/ARENA_DUELS_CHAIN.md). **Design:** [DESIGN.md](../specs/arena-duels/DESIGN.md), [IMPLEMENTATION_PLAN.md](../specs/arena-duels/IMPLEMENTATION_PLAN.md).

Every phase session appends one section (charter §1.9). Sections are in the order they were written, not in phase order.

---

## P3 — pure core rules ([KNG-215](https://linear.app/kngpandi/issue/KNG-215))

**Session:** Claude Code cloud session, 2026-10-21. **Status:** pushed, KNG-215 In Review.

### Commits

| Repo | Branch | Commit | What |
|---|---|---|---|
| knk-plugin | `claude/arena-duels` (created by this session from `origin/claude/mc-26.2-upgrade` `88497649`) | `1f5ebdfa` | `core/duel/` (21 main files, 8 test files); files added only |
| knk-plugin | `claude/arena-duels` | `36195de3` | follow-up: stake ratio by item value (developer decision, see interpretation 1); only `core/duel` files changed |
| knk-workspace | `main` | `0f87b4c` | tracker row |
| knk-workspace | `claude/arena-duels` (created by this session from `main`) | this report | this section |

### Tests

- Toolchain: OpenJDK 25.0.4 (KNG-182 toolchain), Gradle 8.14.3, Paper API `26.3.build.205-stable`.
- Baseline before the change: knk-core 2168 tests, 0 failures.
- New: 114 tests in `core/duel`, all green (offer book 22, validator 12, state machine 48, combat rules 15, queue/allocator 9, escrow 7, Bukkit-free guard 1).
- Full `./gradlew build -x deployToDevServer`: BUILD SUCCESSFUL — knk-core 2282 (2168 + 114), knk-api-client 264 (2 skipped), knk-paper 1870 (18 skipped), 0 failures, no known reds. (A first run failed only on a transient Maven Central HTTP 429 while downloading gson; the re-run was green.)
- Follow-up `36195de3` (stake ratio by item value), after merging P0 and P1: 118 tests in `core/duel` (the collateral test replaced by four value tests, plus one offer-book test). Full build green: knk-core 2312, knk-api-client 267 (2 skipped), knk-paper 1887 (18 skipped), 0 failures. (Two runs failed first on Maven Central HTTP 429 downloads, not on tests.)

The plan's Phase 3 test list, and where it is covered:

| Plan test | Test |
|---|---|
| every transition and the abort path at each phase | `DuelStateMachineTest.theWholeLifecycle`, `abortAtEachPhaseRefundsOnce` (LOCKING..FIGHT × staff/outage/restart), `lockRefused`, `aFailedLobbyTeleportCancels`, `aFailedBattlegroundTeleportCancelsAndLeavesTheBattleground`, `noBattlegroundCancels` |
| `MaxOffers` 1/2/3/4 | `DuelOfferBookTest.maxOffersBoundsTheTurns` |
| a stale offer id refused | `DuelOfferBookTest.aStaleOfferIdIsRefused` |
| death + quit on the same tick → one result | `deathAndQuitOfOnePlayerOnTheSameTickGiveOneResult`, `aDeathAndTheOtherPlayersQuitOnTheSameTick`, `bothQuitOnTheSameTickCancels` |
| simultaneous death → draw | `aSimultaneousDeathIsADraw`, `deathsOnDifferentTicksAreNotADraw` |
| agreed draw needs both players inside the window | `anAgreedDrawNeedsBothInsideTheWindow`, `anAgreedDrawOutsideTheWindowIsANewOffer`, `theSameSideTwiceIsNoDraw` |
| queue cap and wait timeout | `ArenaQueueTest.theCapRefusesTheFourthAccept`, `theWaitTimesOutAfterMaxWaitSeconds` |
| kit default at the deadline | `theKitDefaultsToTheFirstEligibleKitAtTheDeadline` |

### Public API of `core/duel` (for P4, P5, P6)

Package `net.knightsandkings.knk.core.duel` in `knk-core`. Bukkit-free (guarded by `DuelPackageBukkitFreeTest`), clock-free, main thread only.

**Time.** Everything takes `long nowTick`, the server tick (`Bukkit.getCurrentTick()`). `DuelTicks.PER_SECOND = 20`, `ofSeconds(s)`, `secondsUntil(deadline, now)`. Ticks (not seconds) are what makes "the same tick" decidable (simultaneous death).

**Value types**

| Type | Shape |
|---|---|
| `DuelSide` | `CHALLENGER` (inviter), `OPPONENT`; `other()` |
| `GearMode` | `OWN_GEAR_KEEP`, `OWN_GEAR_DROP`, `FIXED_KIT`, `KIT_CHOICE`; `isKitMode()`, `dropsInventory()` |
| `DuelArenaSettings` | record of the DESIGN §4.2 fields the rules read (`arenaId`, `maxOffers`, `offerSeconds`, `allowCoinStakes`, `allowItemStakes`, `maxCoinStake`, `maxItemStacks`, `minStakeRatioPercent`, `feePercent`, `allowedGearModes`, `defaultGearMode`, `eligibleKitIds`, `warmupSeconds`, `countdownSeconds`, `fightTimeLimitSeconds`, `maxWaitSeconds`, `winnerLingerSeconds`, `maxQueuedMatches`); `defaults(arenaId)`, `allows(mode)`, `isKitEligible(id)`, `defaultKitId()`, `feeFor(pot)`, `timings(agreedDrawWindowSeconds)`. **P4 maps it from P1's arena gateway DTO.** |
| `DuelTimings` | record: warmup, countdown, fight limit (0 = none), linger, agreed-draw window (config `duels.agreed-draw-window-seconds`, 15) |
| `StakeItem` | `(refId, material, amount)`: a reference; P4 keeps the real `ItemStack` copy under `refId` (unique per owner per negotiation) and matches it at lock-in |
| `Stake` | `(coins, List<StakeItem>)`; `NONE`, `coins(c)`, `isEmpty()` |
| `StakeContract` | `(gearMode, fixedKitId, challenger, opponent)`; `quick(settings)`, `stakeOf(side)`, `hasStakes()`, `isValueMoving()`, `isFriendly()`, `potCoins()` |
| `StakeViolation` | `(code, side, detail)`; codes `GEAR_MODE_NOT_ALLOWED`, `FIXED_KIT_MISSING`, `FIXED_KIT_NOT_ELIGIBLE`, `KIT_NOT_EXPECTED`, `NO_ELIGIBLE_KITS`, `COINS_NOT_ALLOWED`, `ITEMS_NOT_ALLOWED`, `NEGATIVE_COINS`, `COINS_OVER_MAX`, `STAKE_RATIO` (detail = the minimum stake value, coins + item value), `TOO_MANY_STACKS`, `ITEM_BLOCKED` (detail = material), `DUPLICATE_ITEM`, `ITEM_ADDED_BY_OTHER_SIDE` |
| `DuelEndReason` | `WIN`, `FORFEIT`, `TIME_LIMIT`, `AGREED_DRAW`, `SIMULTANEOUS_DEATH`, `TELEPORT_FAILED`, `PLAYER_LEFT_LOBBY`, `NO_BATTLEGROUND`, `ADMIN_CANCELLED`, `SERVER_RESTART`, `API_OUTAGE`, `LOCK_REFUSED`; `status()` (COMPLETED / CANCELLED / ABORTED / NOT_CREATED), `isDecisive()`, `isDraw()`, `apiName()` (PascalCase for P2's API, null for `LOCK_REFUSED`) |
| `DuelResult` | `(reason, winner)`; `win(side, reason)`, `noWinner(reason)`, `loser()`, `isDecisive()` |
| `DuelPhase` | `LOCKING`, `TRAVELLING`, `WARMUP`, `BATTLE_COUNTDOWN`, `FIGHT`, `ENDING`, `CLOSED`; `isParticipating()` (LOCKING..ENDING: combat rule, teleport restriction, guards, held deliveries), `quitForfeits()`, `onBattleground()`, `countsAsQueued()` |

**`StakeContractValidator`** (static)
- `validate(contract, settings, blocked, ToLongFunction<StakeItem> itemValue)` → `List<StakeViolation>`; the 3-argument `validate(contract, settings, blocked)` values items at 0 (`NO_ITEM_VALUE`)
- `itemValue` returns a whole stack's coin value. **P4 supplies the base price of the item instance's `ItemBlueprint`: `BasePriceMin` × amount, and 0 for an item without an instance or blueprint** (developer, 2026-10-21)
- `validateItemOwnership(previous, next, author)`; `validateOffer(previous, next, author, settings, blocked, itemValue)` = both
- `stakeValue(stake, itemValue)` (coins + item value; for the editor's display), `minimumMatchingStake(larger, ratioPercent)` (for the editor's hint)
- Not here (P4 / the API): item presence (`isSimilar` + amount), eligibility (D14), pair/daily limits, holds and restrictions.

**`DuelOfferBook`** (one per server)
- `new DuelOfferBook(maxIncoming, sendCooldownSeconds, Predicate<StakeItem> blocked, ToLongFunction<StakeItem> itemValue)` (the 3-argument form values items at 0); constants `DEFAULT_MAX_INCOMING = 3`, `DEFAULT_SEND_COOLDOWN_SECONDS = 10`
- `invite(inviter, invitee, settings, contract, now)`, `counter(author, offerId, contract, now)`, `accept(player, offerId, now)`, `decline(player, offerId, now)`, `cancel(player, negotiationId)` → `Outcome(status, negotiation, offer, violations, cooldownSeconds)`
- `Status`: `OK`, `SELF_INVITE`, `INVITES_DISABLED`, `ALREADY_INVITING`, `PAIR_ALREADY_NEGOTIATING`, `TOO_MANY_INCOMING`, `ON_COOLDOWN`, `PLAYER_BUSY`, `UNKNOWN_NEGOTIATION`, `STALE_OFFER`, `NOT_YOUR_TURN`, `OFFER_EXPIRED`, `NO_COUNTERS_LEFT`, `INVALID_CONTRACT`, `NOT_AWAITING_RESPONSE`
- `accept` moves the negotiation to `LOCKING`; P4 then calls `lockSucceeded(negotiationId)` → `List<Closed>` (the players' other negotiations, `SUPERSEDED`) or `lockFailed(negotiationId)` → `Closed`
- `tick(now)` → expired `List<Closed>`; `forget(player)` on quit/death/siege join → `List<Closed>` (a `LOCKING` one is left to the lock-in)
- `setInvitesDisabled(player, bool)`, `invitesDisabled(player)` — **P4/P5 persist the toggle and set it on join**
- Queries: `negotiation(id)`, `byCurrentOfferId(offerId)`, `outgoingOf`, `incomingOf`, `negotiationsOf`, `isNegotiating`, `isLocking`, `cooldownSeconds`
- `DuelNegotiation` (read-only view): `negotiationId()`, `inviter()`, `invitee()`, `arenaId()`, `settings()`, `state()` (`AWAITING_RESPONSE`/`LOCKING`/`CLOSED`), `offers()`, `currentOffer()`, `offerCount()`, `playerOf(side)`, `sideOf(uuid)`, `awaitedPlayer()`
- `DuelOffer`: `offerId()` (fresh per offer, for the chat buttons), `number()` (n of max), `author()`, `receiver()`, `contract()`, `expiresAtTick()`, `last()` / `canBeCountered()` (no Counter button on the last offer)
- `CloseReason`: `DECLINED`, `CANCELLED`, `EXPIRED`, `PLAYER_GONE`, `LOCKED`, `LOCK_REFUSED`, `SUPERSEDED`

**`DuelStateMachine`** (one per match)
- `new DuelStateMachine(timings, gearMode, fixedKitId, eligibleKitIds)` or `forContract(contract, settings, agreedDrawWindowSeconds)`
- Inputs, each returning `List<DuelEffect>`: `lockSucceeded(now)`, `lockFailed(now)`, `travelCompleted(now)`, `travelFailed(now)`, `battlegroundAssigned(bgId, now)` (empty = not waiting: release the battleground), `noBattleground(now)`, `battlegroundTeleportFailed(now)`, `onDeath(side, now)`, `onQuit(side, now)`, `abort(reason, now)`, `advance(now)`
- `chooseKit(side, kitId)` → `KitChoiceOutcome(KitChoice: CHOSEN / NOT_KIT_CHOICE / NOT_IN_WARMUP / NOT_ELIGIBLE, effects)`
- `offerDraw(side, now)` → `DrawOutcome(DrawOffer: OFFERED / AGREED / NOT_IN_FIGHT, effects)`
- Queries: `phase()`, `gearMode()`, `result()`, `phaseAtEnd()`, `ended()`, `battlegroundId()`, `isWaitingForBattleground()`, `kitOf(side)`, `hasPickedKit(side)`, `damageLocked()`, `secondsRemaining(now)` (boss bar), `drawOfferExpiresAt(side, now)`
- **P4 must call `advance(now)` on the tick after any `onDeath`/`onQuit` in COUNTDOWN/FIGHT** (e.g. `runTask` next tick), as well as from the 1 s ticker: losses are decided only once a later tick arrives.

**`DuelEffect`** (sealed; apply in order): `PhaseChanged(from, to)`, `StartLobbyTeleports()`, `WarmupStarted(warmupSeconds)`, `GrantKit(side, kitId, placeholder)`, `SwapKit(side, fromKitId, toKitId)`, `AwaitBattleground()` (→ `ArenaQueue.readyForBattleground`), `KitsLocked(challengerKitId, opponentKitId)`, `EnterBattleground(battlegroundId, countdownSeconds)`, `FightStarted(timeLimitSeconds)`, `DrawOffered(side, expiresAtTick)`, `MatchEnded(result, phaseAtEnd)` (settle or refund via the API, then `DuelEscrowPlan`), `Release(fromBattleground)` (restore gear, revoke exemption, exit teleport; after the linger for a completed match, at once for a cancel/abort).

**`DuelCombatRules`**
- `decide(Combatant attacker, Combatant victim)` → `NOT_DUEL` / `ALLOW` / `DENY_NOT_FIGHTING` / `DENY_OUTSIDE_MATCH`; `Outcome.denied()`
- `Combatant(matchToken, phase, damageLocked)` or `Combatant.of(token, machine)`; pass `null` for a player in no match
- `overrideWorldGuardPvpBlock(attacker, victim)` for the `DisallowedPVPEvent` handler

**`BattlegroundAllocator` + `ArenaQueue`** (one pair per arena)
- `new BattlegroundAllocator(enabledIdsInSortOrder)`; `setBattlegrounds`, `allocate(token)`, `release(token)`, `battlegroundOf`, `matchOn`, `hasFree`, `freeCount`, `busyCount`, `totalCount`
- `new ArenaQueue(allocator, maxQueuedMatches, maxWaitSeconds)`; `configure(...)` on settings refresh
- `hasRoom()` (advisory at invite), `admit(token)` (binding at accept, before lock-in), `readyForBattleground(token, now)`, `advance(now)` → `Update(assigned: List<Assignment(token, bgId)>, timedOut: List<token>)` (→ `battlegroundAssigned` / `noBattleground`), `remove(token)` (match ended before a battleground), `releaseBattleground(token)` (match over), `positionOf(token)` ("#2 in line"), `queuedCount()`, `maxQueuedMatches()`

**Escrow**
- `DuelEscrowState`: `LOCKING`, `ESCROWED`, `HELD`, `SETTLED`, `REFUNDED`, `CLAIM_PENDING`; `canMoveTo(next)`, `allowedNext()`, `isFinal()` — the spool checks this before every write
- `DuelEscrowPlan(challengerStakeTo, opponentStakeTo, spoilsTo, next)`: `forResult(result, Decision PAID/HELD/VOIDED, spoilsFrom)`, `forRecovery(apiStatus, winner, held, spoilsFrom)` (DESIGN §7.3), `refund(spoilsFrom)`, `payWinner(side)`, `hold()`, `keepsEverything()`. A null recipient means "stays in escrow". Coins stay the API's.

### Deviations and interpretations (all reversible; also a comment on KNG-197)

1. **Stake ratio with items — decided by the developer (2026-10-21, KNG-197), follow-up commit `36195de3`.** DESIGN §10.2 says "I stake 10,000, you stake 0" is impossible, while §6.2's example "I stake my diamond sword, you stake 500 coins" must be expressible. The first version waived the ratio when the smaller side staked items ("collateral"); the developer replaced that. **Now** each side's stake value is its coins plus the coin value of its items, and the smaller value must be at least `MinStakeRatioPercent` of the larger. An item's value is the base price of its item instance's `ItemBlueprint`, "for lack of better options currently". The reversible default is `BasePriceMin` × amount, and an item that is not an `ItemInstance` with a blueprint is worth 0. The caller supplies the valuation (`ToLongFunction<StakeItem>`); P2 applies the same rule in the API at lock-in.
2. **Same-tick losses.** Plan: "death + quit on the same tick → one result". Chosen: the same player dying and quitting → one loss (WIN for the other); one dies and the other quits on the same tick → the death decides it (the quitter is paid on join); both die → `SIMULTANEOUS_DEATH` draw; both quit on the same tick → cancelled as `PLAYER_LEFT_LOBBY` (refund), since neither can claim the win.
3. **Deaths outside FIGHT.** DESIGN only says "any death in FIGHT loses". Chosen: a death before the countdown cancels like a quit (`PLAYER_LEFT_LOBBY`, refund); a death during the countdown (damage is locked, so only `/kill`, void or similar) is a `FORFEIT`, the same as quitting then (D10).
4. **Failed battleground teleport** ends as `Cancelled / TeleportFailed`. The lifecycle diagram (§5) says "ABORTED + refund", but §4.3 lists `TeleportFailed` under Cancelled and `Aborted` only for ServerRestart/ApiOutage. Either way it refunds.
5. **`LOCK_REFUSED`** is an extra end reason with no API counterpart (`apiName()` null): lock-in refused, no match record.
6. **The queue counts LOCKING matches** as well as TRAVELLING/WARMUP, because `admit` at accept is the binding cap check (§5.2) and a lock-in in flight must hold its place.
7. **Kit modes without stakes are friendly** (`isFriendly()`): only `OWN_GEAR_DROP` moves value without a stake (D14).
8. **Bukkit-free guard** is a package-local test (`DuelPackageBukkitFreeTest`) instead of a new entry in `ArchitectureGuardTest`, so this phase only adds files.

### What P4 needs to know

- Map P1's arena DTO to `DuelArenaSettings` (its constructor validates the same rules as the API).
- One `ArenaQueue` + `BattlegroundAllocator` per arena; call `queue.advance(now)` from the 1 s ticker and route `Assignment`s / `timedOut` to the matches' state machines.
- Call `machine.advance(now)` on the tick after `onDeath` / `onQuit` (see above).
- Spoils capture is P4's (death event, spool first); `DuelEscrowPlan.forResult(..., spoilsFrom)` routes them afterwards.

### Live checks for P8

None of P3 is visible on its own; these behaviours come through P4/P5 and are worth one look each:
- an old chat **[Accept]** button after a counter says the offer is no longer current
- with `MaxOffers = 3`, offer #3 has no **[Counter]**
- both duelists killed on the same tick (e.g. one TNT) → a draw with refund
- `/duel draw` by one side, then the other within 15 s → draw; after 15 s → only a new offer
- a fourth accepted match with `MaxQueuedMatches = 3` is refused before anything is taken
- `KIT_CHOICE` without a pick → both fight with the first eligible kit

### Open questions

- None. Deviation 1 was decided by the developer on 2026-10-21 (item value from the blueprint's base price), and the developer kept interpretations 2–3 as built.

---

## P0 — shared minigame hooks ([KNG-209](https://linear.app/kngpandi/issue/KNG-209))

**Session:** Claude Code cloud session, 2026-10-21. **Status:** pushed, KNG-209 In Review. A refactor with no behaviour change for siege.

### Commits

| Repo | Branch | Commit | What |
|---|---|---|---|
| knk-plugin | `claude/arena-duels` | `e3814cef` | the P0 change (registry, siege adapter, vault, exemptions, tests) |
| knk-plugin | `claude/arena-duels` | `d00826c5` | merge of P3's `1f5ebdfa` (no conflicts; tests re-run green after it) |
| knk-workspace | `main` | `140825b` | tracker row |
| knk-workspace | `claude/arena-duels` | this commit | this section; siege `DESIGN.md` §9.1 and the class table name the shared vault |

KNG-182 has not merged into knk-plugin `main` yet (`main` is still `79be4882`), so `claude/mc-26.2-upgrade` (`88497649`) stays the base.

### Tests

- Toolchain: Temurin JDK 25.0.4 as the Gradle toolchain (Gradle 8.14.3 itself runs on JDK 21), Paper API 26.3.
- Baseline on `88497649` (clean worktree): knk-core 2168, knk-api-client 264 (2 skipped), knk-paper 1870 (18 skipped), 0 failures.
- After P0 (before merging P3): knk-core 2180, knk-api-client 264, knk-paper 1887, 0 failures. After the P3 merge: knk-core 2294, knk-api-client 264, knk-paper 1887, 0 failures; `./gradlew build -x deployToDevServer` BUILD SUCCESSFUL. No known reds.
- Every existing siege test is unchanged and green (`SiegeTeleportRestrictionTest`, `SiegeSafeZoneTest`, `SiegeMatchPreparationTest`, the lootbox/statistics/discovery siege cases, …). Three existing tests changed only their fixtures for new signatures: `HubOutageServiceTest` and `HubPortalListenerTest` pass a registry; `DiscoveryEligibilityTest` replaced its siege-service hook test with the same assertions through the registry and `SiegeParticipation`.

| Plan test | Test |
|---|---|
| registry composition | `MinigameRegistryTest` (empty registry = the old null checks; stage-driven questions; per-minigame answers; outage release asks all; resume isolates failures; unique ids; port defaults), `SiegeParticipationTest` (stages equal `isMatchActive` / `blocksDiscovery` / `runningMatchOf` for every phase; combat, headshots, outage), `MinigameTeleportRestrictionTest` (the registry guard in a real `TeleportService` refuses what the siege guard did; `/back` exclusion; bypass node) |
| vault round-trip, including old siege files | `MinigamePlayerVaultTest` (snapshot → restore, restore from file after a restart, a hand-written `SiegePlayerVault` version-1 file restores, quit then join, dead at the end, unwritable directory, one directory per minigame) |
| handler with and without exemptions | `DomainAccessExemptionsTest` (core rule) and `DomainAccessServiceTest` (`anEmptyExemptionRegistryChangesNothing`, `anEntryExemptionLetsThatPlayerInOnFootAndByTeleportAndConfinementKeepsThemIn`) |

### What later phases build on (P1, P3, P4, KNG-199)

**`knk-core` `net.knightsandkings.knk.core.minigame`** (Bukkit-free, in `ArchitectureGuardTest`):
- `MinigameParticipation` (port): `id()` (lower case; also the statistics context and the noun in "You are in a duel."), `participationOf(UUID)`, and defaults P4 overrides as needed: `allowsCombat(attacker, victim)` (UUIDs), `headshotMultiplier`, `releaseForOutage(UUID)` (default true), `resumeAfterOutage()`, `holdsLootDrops(UUID)`, `keepsOwnScoreboard(UUID)`, `excludesBackOnDeath(UUID)` (these three default to "stage is away"), `teleportRefusal(MinigameTeleportAttempt)`, `teleportBypassNodes()`.
- `Participation(playerId, minigame, matchToken, stage)`, `Stage` = `QUEUED` (still in the open world; only navigation excludes) / `STAGING` (taken away, gear held, not fighting) / `PLAYING` (statistics go to the minigame's context) / `FINISHING` (waiting to be restored). `isAway()` = STAGING|PLAYING; `hasLeftOpenWorld()` = not QUEUED. **Suggested duel mapping for P4:** LOCKING and TRAVELLING/WARMUP/BATTLE_COUNTDOWN → STAGING, FIGHT → PLAYING, ENDING → FINISHING; override `holdsLootDrops` (DESIGN §8.4: LOCKING until the restore) where the default differs.
- `MinigameTeleportAttempt(subject, subjectName, kind, movesSelf, visited, visitedName, authority)`.
- `MinigameRegistry`: `register` / `unregister` / `find(id)`; `participationOf`, `isMember`, `hasLeftOpenWorld`, `isAway`, `statisticsContextOf`, `hubRefusal`, and the composed hooks. **P4 registers `DuelService` (or an adapter) with `KnKPlugin.getMinigames().register(...)`.**

**`knk-paper`:**
- `paper/minigame/MinigameTeleportRestriction` — registered once (after `initializeSiege`), so a minigame registered later is guarded automatically; `backDeathExclusion()`. `attemptOf(TeleportCheck)`.
- `paper/minigame/MinigamePlayerVault(minigame, directory, teleporter, logger)`: `snapshot(player, matchToken, instanceId)` → false when the file can't be written, `has`/`hasFile`, `peek`, `matchTokenOf`, `restore`, `restoreOnQuit`, `restoreOnJoin`, `takePendingRespawn`, `returnLocation`, `setAfterRestore`. One instance per minigame and directory (P4: e.g. `duel-vault/`; KNG-199: siege's own `siege-vault/`). The teleporter must bypass the teleport engine (siege uses `SiegeBukkit::teleport`).
- `paper/siege/SiegeParticipation` (id `siege`).
- `ScoreboardUtil.setMinigames(registry)`; `HubOutageService` takes the registry (release on outage actions, `resumeAfterOutage` on recovery).
- **`DomainAccessExemptions`** (`knk-core` `core/regions/access/`): `exemptFromEntry(UUID, regionId)`, `confinement(UUID, regionId)` → message; `DomainAccessExemptions.Registry` (`register`/`unregister`). `RegionAccessRules.evaluate(playerId, entered, exited, exemptions)`; `DomainAccessService.setExemptions(...)`. **P4 registers its provider with `KnKPlugin.getDomainAccessExemptions().register(...)`**; it applies to WorldGuard crossings (walk, glide, ride, pearl, teleport), the teleport engine's preview and the join/respawn check. `exemptWhile` (existing) still skips judging the runtime's own moves; P4's "one-shot pass" for the exit teleport can use it or clear the confinement first.

### Deviations and interpretations (reversible; also a comment on KNG-197)

1. **The port has more than DESIGN §11's six methods**: the headshot multiplier, the outage resume and the `/back` exclusion were separate siege lambdas too, so they became port methods with neutral defaults. `teleportRefusal` takes a `MinigameTeleportAttempt` instead of `(UUID, kind)`, because the siege guard's messages depend on who asks (self, staff, a `/tpa` to a member) and on the bypass node.
2. **Membership is one shared stage** instead of each hook asking its own siege method. `SiegeParticipationTest` proves the stages equal the old predicates for every siege phase.
3. **Exemptions are asked by `DomainAccessService` (through `RegionAccessRules`)**, which `DomainAccessHandler` calls for every crossing; that way the teleport preview and the join/respawn check see them too.
4. **`/hub`'s message comes from the minigame id**: "You are in a siege." is unchanged; a duelist will get "You are in a duel.".
5. **A failing `resumeAfterOutage` is now logged per minigame** instead of escaping the connectivity callback (failure path only).
6. **`MinigamePlayerVault` writes two extra keys** (`minigame`, `instanceId`); an old file's `lobbyId` is read as the instance id. The version stays 1, so a rollback still reads new files.

### Left for later phases (filed as Linear comments)

- Navigation's and discovery's exclusion is still called `SIEGE`, and navigation tells the player "you joined a siege"; with duelists in the registry that wording is wrong → comment on KNG-217 (P4). The config key `discovery.exclude-siege-participants` now covers every registered minigame.
- knk-plugin `CLAUDE.md` "Structure" could name `core/minigame/` and `paper/minigame/`; left for P8's docs pass (KNG-222 comment).

### Live checks for P8 (siege regression)

One siege round on the dev server:
1. **Outage release**: with a siege at the hub or in progress, take the API down until the outage action fires → the round is aborted ("…lost its connection…"), members get their things back and are moved; when the API returns, the lobby restarts matchmaking.
2. **`/hub` refusal**: a member at the siege hub, in the match and during ENDING/COOLDOWN gets "You are in a siege."; a member still in matchmaking may use `/hub`.
3. **Safezone enchant effects**: in a siege fought inside a town (PvP-safe region), custom enchantments (e.g. a lifesteal or fire effect) still trigger on enemy hits; a hit inside a team's own spawn area is still refused.
4. **Vault restore after a quit**: quit mid-match → inventory, XP and effects are back at once; rejoin → teleported to the pre-match spot; `plugins/KnightsAndKings/siege-vault/<uuid>.yml` is gone afterwards. Also: a vault file left from before this branch (if one exists on the dev server) restores on join.
5. Quick extras: `/spawn` as a member is refused with the siege message; a match death gives no `/back`; the match scoreboard survives an hourly salary/rank refresh; lootbox tokens earned during the siege arrive after the restore.

---

## P1 — Arena domain types and duel settings ([KNG-210](https://linear.app/kngpandi/issue/KNG-210))

**Session:** Claude Code cloud session, 2026-10-21. **Status:** pushed, KNG-210 In Review. Not deployed, not live-tested. The API and web-app parts were done first; the plugin part after P0 had pushed (`e3814cef`, merged with P3 as `d00826c5`), on top of that head.

### Commits

| Repo | Branch | Commit | What |
|---|---|---|---|
| knk-web-api | `claude/arena-duels` (from `master` `2d71155`) | `1f65a12` | entities, migration `AddArenas`, validation, `ArenasController`, finalizer/discovery/navigation plumbing, form seeds, tests |
| knk-web-api | `claude/arena-duels` | `05a9049` | the arena read also carries its own `location` (the plugin's exit fallback) |
| knk-web-api | `claude/arena-duels` | `6507641` | `KitService` refuses to delete a kit an arena offers (names the arena) instead of failing on the FK |
| knk-web-app | `claude/arena-duels` (from `main` `e30c815`) | `7fa594b` | arena API clients and entity mapping, dashboard configs, tests |
| knk-plugin | `claude/arena-duels` (on `d00826c5`) | `02bca4e0` | `ArenasApi` + client, `ArenasDataAccess`, managed-region kinds and policy, navigation/discovery labels, tests |
| knk-workspace | `main` | `9408888` | tracker row |
| knk-workspace | `claude/arena-duels` | this commit | this section; `architecture/managed-worldguard-regions.md` §3–§8 |

### Tests

- **knk-web-api** (`dotnet test`, .NET 8 SDK): baseline on `master` `2d71155`: 2697 passed, 4 failed, 73 skipped. After P1 (`6507641`): 2748 passed, 4 failed, 73 skipped — the **same 4 known reds** (`PathResolutionServiceTests` ×2, `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`, `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`). Note: `dotnet build` at the repo root fails on Linux because `knkwebapi_v2.sln` names `tests\…` (lower case); build `knkwebapi_v2.csproj` instead.
- **knk-web-app** (`npx -y npm@11 ci`, `npm run test:ci`): 156/156 suites, 944 tests (baseline 154 / 938); `tsc --noEmit` only the 3 errors `main` already has (`sessionPinnedRows.test.ts`).
- **knk-plugin** (`./gradlew build -x deployToDevServer`, Temurin JDK 25.0.4 toolchain via `-Porg.gradle.java.installations.paths`, Paper 26.3): BUILD SUCCESSFUL; knk-core 2308, knk-api-client 267 (2 skipped), knk-paper 1887 (18 skipped), 0 failures.

| Plan test | Test |
|---|---|
| API CRUD, defaults | `ArenaServiceTests` (create stores every §4.2 default; null keeps a value on update; by-key read with children; duplicate key; battleground/spectator-area CRUD; delete removes the children's `domains` rows too) |
| API validation | `ArenaServiceTests` (MaxOffers 1–6, FeePercent 0–20, ratio 0–100, time limit ≥ 0 with 0 allowed, ≥ 1 gear mode, kit modes need a kit, default mode allowed, unknown mode, lobby required while duels are on, lobby/spawns in the domain's world, missing references, duplicate kit, enabled battleground needs both spawns) |
| access rules | `EndpointAccessRulesTests.ArenaWrites_NeedManageWorld_AndReadsOnlyACaller` (+ the reflection test over every write) |
| FK restrict | `ArenaServiceTests.DeleteRule` (model ON DELETE for every arena FK), `KitServiceTests.Delete_IsRefused_WhileAnArenaOffersTheKit` |
| finalizer parents | `ArenaServiceTests.TempRegions_AreRenamedWithTheirTypeAndParent` (District → Arena → battleground / spectator area) |
| form seeds | `FormConfigurationSeedFilesTests` (all seeds dry-run and import; arena join and region rules resolve) |
| plugin mapping, policy, cache | `ManagedRegionPolicyTest` (kinds from domain types; battleground without `entry deny`; spectator area plain), `DomainRegionSpecsTest.arenaChildrenHangUnderTheArenaRegion`, `ArenasDataAccessTest`, `ArenaMapperTest` (the API's JSON), `KnkArenaTest`, `NavigationDestinationsTest` |
| web app forms | `FormWizard.arenaForm.ui.test.tsx` (steps render with defaults; a saved arena's kits load in order and submit with `SequenceNumber`), `entityApiMapping.arena.test.ts` |

### What later phases build on (P2, P4, P5, P6)

**knk-web-api**
- Entities (`Models/Arena/`): `Arena : Structure` (table `arenas`; `Key` unique; `LobbyLocationId?`, `ExitLocationId?`; every §4.2 setting; `DefaultGearMode` = `Enums/DuelGearMode` stored as a string), `ArenaBattleground : Domain` (`arena_battlegrounds`; `ArenaId`, `Key` unique per arena, `SortOrder`, `IsEnabled`, `SpawnALocationId?`, `SpawnBLocationId?`, `AllowEntry` false by default), `ArenaSpectatorArea : Domain` (`arena_spectator_areas`; `ArenaId`), `ArenaKit` (`arena_kits`; key `(ArenaId, KitId)`, `SequenceNumber`). DbSets `Arenas`, `ArenaBattlegrounds`, `ArenaSpectatorAreas`, `ArenaKits`.
- `IArenaService` / `ArenaService` (`ValidateSettings` is public static for reuse), `IArenaRepository`.
- Endpoints (`ArenasController`, `api/Arenas`):
  - reads (plugin key or any login): `GET` (all arenas, full: settings, `location`/`lobbyLocation`/`exitLocation`, `eligibleKits` in order with `kitName`, `battlegrounds` in `sortOrder` with `spawnALocation`/`spawnBLocation`, `spectatorAreas` with `location`), `GET {id}`, `GET by-key/{key}`, `GET {arenaId}/battlegrounds`, `GET battlegrounds?arenaId=`, `GET battlegrounds/{id}`, `GET {arenaId}/spectator-areas`, `GET spectator-areas?arenaId=`, `GET spectator-areas/{id}`, `POST search`, `POST battlegrounds/search`, `POST spectator-areas/search`
  - writes (`knk.admin.world` or the plugin): `POST`, `PUT {id}`, `DELETE {id}`, the same under `battlegrounds/` and `spectator-areas/`, and `POST legacy-seed`
  - **P2**: the eligibility overrides are `StakeMinAccountAgeHours` / `StakeMinTitleBracketId` (null = the `/pay` rule); the abuse limits are `MaxStakedDuelsPerPairPerDay`, `PairCooldownMinutes`, `DailyCoinWinCap`, `MinStakeRatioPercent`, `FeePercent`, `MaxCoinStake`, `MaxItemStacks`.
- Discovery rule types `Arena`, `ArenaSpectatorArea` (on, Structure values) and `ArenaBattleground` (off), seeded by `AddArenas`; navigation types `Arena`, `ArenaSpectatorArea`.

**knk-plugin**
- `knk-core` `core/domain/arenas/`: `KnkArena` (all settings; `allows(DuelGearMode)`, `usableBattlegrounds()` = enabled with both spawns, `defaultKit()`, `exitOrDomainLocation()`; nested `KnkArena.DuelGearMode`), `KnkArenaBattleground` (`isUsable()`), `KnkArenaSpectatorArea`, `KnkArenaKit`.
- Port `core/ports/api/ArenasApi.getAll()`; client `ArenasApiImpl` (`KnkApiClient.getArenasApi()`).
- **Gateway `core/dataaccess/ArenasDataAccess`** (`KnKPlugin.getArenasDataAccess()`, config `cache.entities.arenas`, TTL 15 min, CACHE_FIRST, stale allowed): `getAllAsync([policy])`, `getByKeyAsync(key)`, `refreshAsync()` (API first, keeps the last copy on failure), offline `cachedArenas()`, `cachedByKey`, `cachedById`, `cachedBattlegroundByRegion(world, regionId)`, `invalidateAll()`. **P4**: call `refreshAsync()` before a negotiation reads its arena and keep the arena the match locked in with; P6's menus can read `getAllAsync()`.
- `ManagedRegionKind.SPECTATOR_AREA` (floor 40, no flags); `fromDomainType` maps `Arena`/`ArenaBattleground`/`ArenaSpectatorArea`; `ManagedRegionSpecSource` and `ManagedRegionsBootstrap` take an optional `ArenasApi`.

**knk-web-app**: `apiClients/arenaClient.ts` (`ArenaClient`, `ArenaBattlegroundClient`, `ArenaSpectatorAreaClient`), `types/dtos/arena/ArenaDtos.ts`, entity types `arena`, `arenabattleground`, `arenaspectatorarea` in `entityApiMapping` and `objectConfigs`.

### Deviations and interpretations (reversible; also a comment on KNG-197)

1. **Lobby and spawns are nullable.** DESIGN §4.1 draws them as required FKs, but the seed can't know them ("set by staff"). Instead: an arena with `IsDuelEnabled` needs a lobby, an enabled battleground needs both spawns; the seed creates the arena with duels off and the battlegrounds disabled.
2. **`ArenaKit.SortOrder` is named `SequenceNumber`**, the name the FormWizard's many-to-many editor already keeps equal to the row order and offers drag-to-reorder for. The API uses the list order.
3. **The Arena form has eight steps**: the six of the plan, plus "Eligible kits" (a step is either many-to-many or plain fields) and "Battlegrounds and spectator areas" (owned child lists, added after the arena is saved, like a gate's doors). General also holds the place, region and locations.
4. **The `arena_2` seed is an endpoint, not a migration**: an Arena is a Structure and needs a District and Street the staff choose, and the inventory report counts the 8 flagged battlegrounds but doesn't list their ids (v1 named them `arena_2,<part>-battleground`). `POST api/Arenas/legacy-seed` `{districtId, streetId, worldName?, battlegroundRegionIds:[…]}` creates `arena_2` (duels off) and one disabled battleground per region, and completes an existing one without duplicating.
5. **`BATTLEGROUND` enforces `entry allow`** instead of only dropping `entry deny`: WorldGuard's own `entry deny` would keep the exempted duelists out, and dropping the rule would leave v1's explicit `entry deny` on the 8 regions. `knk-allow-entry` (AllowEntry=false) is the guard now.
6. **Discovery and navigation are off for battlegrounds by type**, not by a per-domain override in the seed: `ArenaBattleground` gets a disabled discovery rule and is not a navigable type (the plugin's `/navigate` ignores it), so every battleground is covered, not only seeded ones. Arena and spectator areas have their own discovery rules (Structure values) and are navigable as structures.
7. **A new managed kind `SPECTATOR_AREA`** (floor 40, no flags) for "plain child".
8. **`POST …/search` needs only a caller** (the plugin or a login), like the GETs; `StructuresController` puts search under the write rule.
9. **A null eligibility override on update clears it** (null = the `/pay` rule, the default); every other null setting keeps its value.

### Found in passing / left out

- `KitService.DeleteAsync` failed on the new `arena_kits` FK with a database error; fixed in P1 (refuses with the arena's name).
- An `extra-regions` battleground with no domain row now gets `entry allow` without a `knk-allow-entry deny`: seed first (documented in `managed-worldguard-regions.md` §5). The config default is `extra-regions: []`.

### Live checks for P8

1. Apply migration `AddArenas`; `discovery_reward_rules` has `Arena`, `ArenaSpectatorArea` (on) and `ArenaBattleground` (off).
2. Import the seeds in order `ArenaKit.join`, `Arena`, `ArenaBattleground`, `ArenaSpectatorArea` (web app "Import / seeds").
3. `/rg list` in the arena world: note `arena_2`'s 8 `-battleground` children; `POST api/Arenas/legacy-seed` with the district, street and those ids → `arena_2` + 8 disabled battlegrounds; a second call creates nothing.
4. Restart (or `/knk regions repair`): `arena_2` priority 40 under its district, the 8 battlegrounds priority 50 under `arena_2` with `pvp allow` and `entry allow`; `/rg info` shows `knk-allow-entry deny` on each battleground after the access sync.
5. As a normal player: walking, pearling or riding into a battleground is refused (domain-access message); staff with `knk.region.bypass` can enter.
6. Web app: open `arena_2` in the Arena form; set lobby/exit (Send to Minecraft), turn duels on, change `MaxOffers` to 2 and save; refused saves: no gear mode, a kit mode without kits, `MaxOffers` 7, fee 21. Add two eligible kits and drag their order; it sticks after reload. Deleting one of those kits in the kit list is refused with the arena's name.
7. Battleground form: set spawn A/B, enable; a spawn in another world is refused. Spectator-area form: create one with a temp region (Send to Minecraft) → renamed `domain_<id>` under `arena_2`, priority 50, no flags; set its warp (`TeleportEnabled`, a title or price) and see it in `/warp`.
8. `/navigate` lists the arena and the spectator area, not the battlegrounds; walking into the arena gives the "arena" discovery message, a battleground gives none.
9. Plugin: `GET api/Arenas` is read once and cached (`[Arenas]` in the log only on a miss); with the API stopped, `ArenasDataAccess.cachedArenas()` still serves the last copy (P4 exercises this).
