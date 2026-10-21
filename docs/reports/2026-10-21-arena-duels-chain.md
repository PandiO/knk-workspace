# Arena duels chain — progress report

**Status:** In progress (P0, P1, P2, P3 and P7 pushed).
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
| knk-web-api | `claude/arena-duels` | `a8a26c3` | follow-up after the developer's decision (KNG-197, 2026-10-21): `POST api/Arenas/legacy-seed` and its service, DTO and test code removed |
| knk-web-app | `claude/arena-duels` (from `main` `e30c815`) | `7fa594b` | arena API clients and entity mapping, dashboard configs, tests |
| knk-plugin | `claude/arena-duels` (on `d00826c5`) | `02bca4e0` | `ArenasApi` + client, `ArenasDataAccess`, managed-region kinds and policy, navigation/discovery labels, tests |
| knk-workspace | `main` | `9408888` | tracker row |
| knk-workspace | `claude/arena-duels` | this commit | this section; `architecture/managed-worldguard-regions.md` §3–§8 |

### Tests

- **knk-web-api** (`dotnet test`, .NET 8 SDK): baseline on `master` `2d71155`: 2697 passed, 4 failed, 73 skipped. After P1 (`6507641`): 2748 passed, 4 failed, 73 skipped — the **same 4 known reds**; after the seed removal (`a8a26c3`): 2746 passed, the same 4 failed, 73 skipped (`PathResolutionServiceTests` ×2, `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`, `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`). Note: `dotnet build` at the repo root fails on Linux because `knkwebapi_v2.sln` names `tests\…` (lower case); build `knkwebapi_v2.csproj` instead.
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
  - writes (`knk.admin.world` or the plugin): `POST`, `PUT {id}`, `DELETE {id}`, the same under `battlegrounds/` and `spectator-areas/`
  - **P2**: the eligibility overrides are `StakeMinAccountAgeHours` / `StakeMinTitleBracketId` (null = the `/pay` rule); the abuse limits are `MaxStakedDuelsPerPairPerDay`, `PairCooldownMinutes`, `DailyCoinWinCap`, `MinStakeRatioPercent`, `FeePercent`, `MaxCoinStake`, `MaxItemStacks`.
- Discovery rule types `Arena`, `ArenaSpectatorArea` (on, Structure values) and `ArenaBattleground` (off), seeded by `AddArenas`; navigation types `Arena`, `ArenaSpectatorArea`.

**knk-plugin**
- `knk-core` `core/domain/arenas/`: `KnkArena` (all settings; `allows(DuelGearMode)`, `usableBattlegrounds()` = enabled with both spawns, `defaultKit()`, `exitOrDomainLocation()`; nested `KnkArena.DuelGearMode`), `KnkArenaBattleground` (`isUsable()`), `KnkArenaSpectatorArea`, `KnkArenaKit`.
- Port `core/ports/api/ArenasApi.getAll()`; client `ArenasApiImpl` (`KnkApiClient.getArenasApi()`).
- **Gateway `core/dataaccess/ArenasDataAccess`** (`KnKPlugin.getArenasDataAccess()`, config `cache.entities.arenas`, TTL 15 min, CACHE_FIRST, stale allowed): `getAllAsync([policy])`, `getByKeyAsync(key)`, `refreshAsync()` (API first, keeps the last copy on failure), offline `cachedArenas()`, `cachedByKey`, `cachedById`, `cachedBattlegroundByRegion(world, regionId)`, `invalidateAll()`. **P4**: call `refreshAsync()` before a negotiation reads its arena and keep the arena the match locked in with; P6's menus can read `getAllAsync()`.
- `ManagedRegionKind.SPECTATOR_AREA` (floor 40, no flags); `fromDomainType` maps `Arena`/`ArenaBattleground`/`ArenaSpectatorArea`; `ManagedRegionSpecSource` and `ManagedRegionsBootstrap` take an optional `ArenasApi`.

**knk-web-app**: `apiClients/arenaClient.ts` (`ArenaClient`, `ArenaBattlegroundClient`, `ArenaSpectatorAreaClient`), `types/dtos/arena/ArenaDtos.ts`, entity types `arena`, `arenabattleground`, `arenaspectatorarea` in `entityApiMapping` and `objectConfigs`.

### Deviations and interpretations (reversible; also a comment on KNG-197)

1. **Lobby and spawns are nullable.** DESIGN §4.1 draws them as required FKs, so an arena or battleground can be saved before staff capture them ("set by staff"). Instead: an arena with `IsDuelEnabled` needs a lobby, an enabled battleground needs both spawns; until then staff save the arena with duels off and the battlegrounds disabled.
2. **`ArenaKit.SortOrder` is named `SequenceNumber`**, the name the FormWizard's many-to-many editor already keeps equal to the row order and offers drag-to-reorder for. The API uses the list order.
3. **The Arena form has eight steps**: the six of the plan, plus "Eligible kits" (a step is either many-to-many or plain fields) and "Battlegrounds and spectator areas" (owned child lists, added after the arena is saved, like a gate's doors). General also holds the place, region and locations.
4. **No `arena_2` seed** (developer decision on KNG-197, 2026-10-21: "no migration or seed is necessary"). P1 first shipped a `POST api/Arenas/legacy-seed` endpoint (the inventory report counts the 8 flagged battlegrounds but doesn't list their ids, and an Arena needs a District and Street the staff choose); it was removed in `a8a26c3`. Staff create `arena_2` and its battlegrounds in the forms, picking the existing regions (v1 named them `arena_2,<part>-battleground`). The battleground `entry allow` policy (interpretation 5) was kept by the same decision.
5. **`BATTLEGROUND` enforces `entry allow`** instead of only dropping `entry deny`: WorldGuard's own `entry deny` would keep the exempted duelists out, and dropping the rule would leave v1's explicit `entry deny` on the 8 regions. `knk-allow-entry` (AllowEntry=false) is the guard now.
6. **Discovery and navigation are off for battlegrounds by type**, not by per-domain overrides: `ArenaBattleground` gets a disabled discovery rule and is not a navigable type (the plugin's `/navigate` ignores it), so every battleground is covered. Arena and spectator areas have their own discovery rules (Structure values) and are navigable as structures.
7. **A new managed kind `SPECTATOR_AREA`** (floor 40, no flags) for "plain child".
8. **`POST …/search` needs only a caller** (the plugin or a login), like the GETs; `StructuresController` puts search under the write rule.
9. **A null eligibility override on update clears it** (null = the `/pay` rule, the default); every other null setting keeps its value.

### Found in passing / left out

- `KitService.DeleteAsync` failed on the new `arena_kits` FK with a database error; fixed in P1 (refuses with the arena's name).
- An `extra-regions` battleground with no domain row now gets `entry allow` without a `knk-allow-entry deny`: create the battleground domains first (documented in `managed-worldguard-regions.md` §5). The config default is `extra-regions: []`.

### Live checks for P8

1. Apply migration `AddArenas`; `discovery_reward_rules` has `Arena`, `ArenaSpectatorArea` (on) and `ArenaBattleground` (off).
2. Import the seeds in order `ArenaKit.join`, `Arena`, `ArenaBattleground`, `ArenaSpectatorArea` (web app "Import / seeds").
3. `/rg list` in the arena world: note `arena_2`'s 8 `-battleground` children. Create `arena_2` and its battlegrounds in the forms with the existing regions (type the region names; arena: its district and street, duels off until the lobby is set; battlegrounds: disabled until both spawns are set).
4. Restart (or `/knk regions repair`): `arena_2` priority 40 under its district, the 8 battlegrounds priority 50 under `arena_2` with `pvp allow` and `entry allow`; `/rg info` shows `knk-allow-entry deny` on each battleground after the access sync.
5. As a normal player: walking, pearling or riding into a battleground is refused (domain-access message); staff with `knk.region.bypass` can enter.
6. Web app: open `arena_2` in the Arena form; set lobby/exit (Send to Minecraft), turn duels on, change `MaxOffers` to 2 and save; refused saves: no gear mode, a kit mode without kits, `MaxOffers` 7, fee 21. Add two eligible kits and drag their order; it sticks after reload. Deleting one of those kits in the kit list is refused with the arena's name.
7. Battleground form: set spawn A/B, enable; a spawn in another world is refused. Spectator-area form: create one with a temp region (Send to Minecraft) → renamed `domain_<id>` under `arena_2`, priority 50, no flags; set its warp (`TeleportEnabled`, a title or price) and see it in `/warp`.
8. `/navigate` lists the arena and the spectator area, not the battlegrounds; walking into the arena gives the "arena" discovery message, a battleground gives none.
9. Plugin: `GET api/Arenas` is read once and cached (`[Arenas]` in the log only on a miss); with the API stopped, `ArenasDataAccess.cachedArenas()` still serves the last copy (P4 exercises this).

---

## P2 — match record, stake ledger, review tiers, restrictions ([KNG-213](https://linear.app/kngpandi/issue/KNG-213))

**Session:** Claude Code cloud session, 2026-10-21. **Status:** pushed, KNG-213 In Review. Not deployed, not live-tested. Started after P1 had pushed (knk-web-api `6507641`; P1's later `a8a26c3` merged in).

### Commits

| Repo | Branch | Commit | What |
|---|---|---|---|
| knk-web-api | `claude/arena-duels` | `53f42cf` | models, migration `AddDuelMatches`, ledger additions, `DuelMatchService`, `DuelMatchesController`, anomaly rules, tests |
| knk-web-api | `claude/arena-duels` | `d208a74` | merge of P1's `a8a26c3` (legacy-seed endpoint dropped); `master` had nothing new |
| knk-web-api | `claude/arena-duels` | `a0da408` | the stake ratio values items at their blueprint base price (developer decision, below) |
| knk-plugin | `claude/arena-duels` (on P1 `02bca4e0`; P3 `36195de3` merged in as `1e17f985`) | `2be401b5` | `DuelMatchesApi` port, `KnkDuelRecords`, `DuelRefusedException`, api-client implementation, test |
| knk-workspace | `main` | `d79b32e` | tracker row |
| knk-workspace | `claude/arena-duels` | this commit | this section; `specs/currency-payments/DESIGN.md` reason and alert tables |

### Tests

- **knk-web-api** (`dotnet test`, .NET 8 SDK; build `knkwebapi_v2.csproj`): baseline at P1 `6507641`: 2748 passed, 4 failed, 73 skipped. After P2 (`a0da408`): **2829 passed, 4 failed, 73 skipped** — the same 4 known reds (`PathResolutionServiceTests` ×2, `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`, `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`). `dotnet ef migrations has-pending-model-changes`: none.
- **knk-plugin** (`./gradlew build -x deployToDevServer`, Gradle on JDK 21 with the Temurin 25.0.4 toolchain via `-Porg.gradle.java.installations.paths`): BUILD SUCCESSFUL; knk-core 2312, knk-api-client 275 (2 skipped), knk-paper 1887 (18 skipped), 0 failures (P1 reported 2308 / 267 / 1887; +8 api-client tests are `DuelMatchesApiImplTest`, core grew with P3's `36195de3`). Maven Central answered 429 for one test-runtime jar in this container; a session-local Gradle init script pointed at Google's Maven Central mirror (nothing committed).

| Plan test | Test (knk-web-api unless noted) |
|---|---|
| all-or-nothing stake | `DuelMatchServiceTests.Create_IsAllOrNothing_WhenOneSideCantPay`, `Create_DebitsBothStakesInOnePosting_AndTheOpenMatchHoldsThePot` |
| gem refusal | `Gems_AreRefused` |
| each eligibility and limit refusal | `Eligibility_AccountAgeTitleLocksAndKillSwitch_AreRefused`, `DropMode_NeedsBothPlayersEligible_EvenWithoutStakes`, `ArenaGearKitAndItemRules_AreRefused`, `PairCooldown_AndPerDayLimit_AreRefused_UntilTheyPass`, `CancelledMatches_DontCountForThePairLimits`, `DailyCoinWinCap_CountsWhatAPlayerCouldWin`, `Check_ListsEveryRefusal_AndWritesNothing` |
| the ratio rule | `StakeRules_AreRefused` (theory), `StakeRatio_AtExactlyTheMinimum_Passes_AndZeroSwitchesItOff`, `StakeRatio_ValuesItemsAtTheirBlueprintsBasePrice` |
| each signal, tiers 0/1/2 | `DuelReviewRulesTests` (each of S1–S6 alone, boundaries, disabled signals, escalation), `OneFlaggedResult_IsPaidAndFlagged_WithADuelFlagAlert`, `OneWayPair_S5_…`, `Funnel_S6_…`, `Policy_ThresholdsDriveTheSignals`, `FriendlyDuels_AreNeverScored` |
| a first flag never holds | `AFirstFlagNeverHolds_HoweverLargeThePot`, `DuelReviewRulesTests.AFirstFlagNeverHolds_EvenIfThePolicySaysOne` |
| acknowledged flags don't count | `AnAcknowledgedFlag_IsAFalsePositive_AndDoesntCount`, `ClearEscalation_AcknowledgesThePairsOpenFlags` |
| escalation by pair and by beneficiary | `SecondFlagForThePair_IsHeld_…`, `Escalation_CountsByBeneficiary_AcrossDifferentOpponents`, `FlagsOutsideTheWindow_DontCount_…`, `ARevertedResult_CountsAsAConfirmedFlag_…` |
| invites refused while a hold is open | `SecondFlagForThePair_IsHeld_NothingIsPaid_AndNewStakedInvitesAreRefused` (pair, beneficiary, friendly allowed) |
| revert / confiscate | `Revert_WithSpentCoins_RecoversWhatIsLeft_RefundsTheLoserFirst_AndReversesTheFee`, `Revert_WithEverythingStillThere_…`, `Confiscate_SendsTheRecoveredCoinsToTheSink_AndKeepsTheFee`, `Revert_RefusesHeldAndUnpaidMatches_AndNeedsAReason` (Voided, audited, partial-reversal shortfall in the metadata) |
| idempotent create/complete/cancel/release/void | `Create_SameToken_…`, `Complete_IsIdempotent_…`, `Cancel_RefundsBothStakesOnce_WithNoFee` (theory over all 9 non-decisive reasons), `Release_PaysTheHeldResult_Once`, `Void_RefundsBothStakes_…`, `StartFight_IsIdempotent_…` |
| 409 paths | the same tests (WrongState, TokenReused, PolicyChanged), `DuelMatchesControllerTests.Refusals_MapToStatuses` |
| fee rounding | `Complete_PaysPotMinusFee_…` (1,999 → 99), `Check_…` (2,999 → 149) |
| Σ SYS_DUEL = 0 after every end path | asserted in the complete, cancel (×9), release, void, revert, confiscate and abort tests; `CurrencyReconciler` finds no mismatch after each |
| held → release/void | `Release_…`, `Void_…` |
| abort-unfinished leaves held matches alone | `AbortUnfinished_RefundsOpenMatches_AndLeavesHeldAndFinishedOnesAlone` |
| restrictions (player, pair, expiry) | `PlayerRestriction_…`, `PairRestriction_…`, `Restrictions_ValidateTheirInput` |
| ledger primitive | `CurrencyServiceTests.MoveBetweenSystemAccounts_…`, `SystemToSystemReasons_…`, `DuelReasons_FollowTheReasonTable` |
| anomaly detector | `CurrencyAnomalyDetectorDuelTests` (R3 and R4 with duel flows, R7 leaves `DUEL_PAYOUT` out, R10) |
| access rules | `EndpointAccessRulesTests.DuelMatchWrites_AreForTheGameServer_AndStaffActionsNeedTheReviewNode` (+ the reflection test over every write) |
| plugin client | knk-plugin `DuelMatchesApiImplTest` (paths, Idempotency-Key and X-Acting-User-Id headers, bodies, result and refusal mapping) |

These run on EF InMemory with the real ledger and alert service. The match-row lock (`SELECT … FOR UPDATE` in `DuelMatchService.RunLockedAsync`) and the users lock around lock-in only exist on MySQL; they are the siege/ledger pattern, but nothing here exercises them against a real database (live check 9).

### Fee choice (DESIGN §7.1)

**The fee leaves `SYS_DUEL` as a system-to-system move to `SYS_FEES`, in the payout's database transaction.** A paid result is two postings under the match lock: `DUEL_PAYOUT` (pot − fee, `SYS_DUEL` → winner) and `DUEL_FEE` (fee, `SYS_DUEL` → `SYS_FEES`, no user leg). The ledger got one primitive for this, `ICurrencyService.MoveBetweenSystemAccountsAsync(currency, amount, ctx)`, for reasons with the new direction `SystemToSystem` (`CurrencyReasonInfo.FromSystemAccount` names the source); `PostAsync`/`GrantAsync`/`SpendAsync` refuse those reasons, and `ReverseAsync` now mirrors a transaction without user legs leg by leg. Why not the alternatives:
- a fee leg inside the payout posting would give the payout two system accounts, and `ReverseAsync` refuses a partial reversal of such a posting, so a revert after the winner spent coins would fail;
- paying the whole pot and then debiting the fee from the winner works with the existing API, but shows the winner a fee they "paid" and can fail at the balance cap for the gross amount.

Per closed match: stake +pot, payout −(pot − fee), fee −fee → Σ `SYS_DUEL` = 0. A revert reverses the payout (`AllowPartial`) and the fee, then pays the pool back with `DUEL_REFUND` (loser first); a confiscation reverses the payout and moves what came back to `SYS_FEES` with `DUEL_CONFISCATION` (the fee stays). Both keep the invariant.

### Stake ratio with items (developer decision 2026-10-21, KNG-197)

`MinStakeRatioPercent` compares each side's **coins + item value**. An item is worth its `ItemInstance`'s `ItemBlueprint.BasePriceMin` × amount, rounded down (the reversible default; `BasePriceMax` is unused). An item without `instanceId`, or whose instance or blueprint is gone, is worth 0. **Contract:** the plugin sends `instanceId` on each stake item (the field already existed); the API prices it, so P3's `StakeContractValidator` and the API apply the same rule, and the API's check at lock-in is binding. The refusal's `details` carry `challengerValue` / `opponentValue`.

### Endpoint contract (P4 and P7 build on it)

`api/DuelMatches` (also `api/duel-matches`). JSON is camelCase, enums are strings (`"OWN_GEAR_DROP"`, `"AgreedDraw"`, `"InProgress"`), times are UTC ISO-8601. Refusals answer `{ code, message, details }`: **404** `MatchNotFound`/`ArenaNotFound`/`UserNotFound`/`RestrictionNotFound`, **409** `WrongState`/`TokenReused`/`PolicyChanged`, **400** `InvalidRequest`, **422** every rule (`DuelsDisabled`, `SelfDuel`, `GearModeNotAllowed`, `KitNotEligible`, `CoinStakesNotAllowed`, `ItemStakesNotAllowed`, `CoinStakeOutOfRange`, `TooManyItemStacks`, `StakeRatioTooLow`, `GemsNotStakeable`, `TransfersDisabled`, `NewAccountRestricted`, `AccountLocked`, `PairDailyLimit`, `PairCooldown`, `DailyWinCap`, `DuelRestricted`, `ReviewHoldOpen`, `InsufficientFunds`). Messages are written for players and name the player concerned; `DuelRestricted` carries the reason and end date.

| Call | Rule | Body → answer | Idempotency |
|---|---|---|---|
| `POST check` | plugin | the create body → `{ allowed, valueMoving, feeCoins, feePercent, refusals[{code,message,details}] }` (also checks balances) | read-only |
| `POST` (lock-in) | plugin | `{ publicToken (uuid), arenaId, challengerUserId, opponentUserId, gearMode, fixedKitId?, challengerCoins, opponentCoins, challengerGems/opponentGems (must be 0), stakeItems[{ownerUserId, material, amount, name?, grade?, instanceId?}], offerCount 1–6, lockedAt? }` → **201** match, or **200** the stored match for a repeated token | header `Idempotency-Key: duel-lock:<token>` (optional; any other value is 400); same token + different body → 409 `TokenReused` |
| `GET by-token/{token}` | caller | → match or 404 | — |
| `GET {id}`, `GET ?userId&arenaId&status&review&limit` | caller | → match / matches, newest first (≤ 200) | — |
| `POST {id}/start-fight` | plugin | `{ battlegroundId, challengerKitId?, opponentKitId?, startedAt? }` (kits only for `KIT_CHOICE`, must be eligible) → match `InProgress` | a repeat returns the match |
| `POST {id}/complete` | plugin | `{ winnerUserId, endReason: Win|Forfeit, telemetry?, spoilsItems?, endedAt? }` → result `{ match, settlement: Paid|Held, alreadyDone }` | same winner again → stored result; other winner, cancelled/aborted → 409 |
| `POST {id}/cancel` | plugin | `{ endReason, telemetry?, endedAt? }`: `TeleportFailed|PlayerLeftLobby|NoBattleground|AdminCancelled` → Cancelled, `ServerRestart|ApiOutage` → Aborted, `TimeLimit|AgreedDraw|SimultaneousDeath` → Completed without winner → `{ settlement: Refunded }` | any repeat → stored; a won match → 409 |
| `POST abort-unfinished` | plugin | `{ endReason: ServerRestart|ApiOutage }` → `{ abortedMatchIds }` (held results untouched) | — |
| `POST {id}/release` | `knk.admin.duel.review` or plugin | `{ reason? }` → `{ settlement: Paid }` | repeat → stored |
| `POST {id}/void` | same | `{ reason }` (required) → `{ settlement: Refunded }`, `undeliveredItems: ReturnToOwners` | repeat → stored |
| `POST {id}/revert`, `POST {id}/confiscate` | same | `{ reason }` (required) → result with `revert: { confiscated, payoutCoins, recoveredCoins, feeReversedCoins, returnedToLoserCoins, returnedToWinnerCoins, confiscatedCoins, missingCoins, undeliveredItems, transactionIds }` | repeat of the same action → stored; the other one → 409 |
| `POST escalation/clear` | same | `{ userId, otherUserId?, reason? }` (pair, or beneficiary) → `{ acknowledgedAlertIds }`; needs a staff member (web login or `X-Acting-User-Id`) | — |
| `GET policy` / `PUT policy` | caller / same | `DuelPolicyDto` (S1–S6 switches and thresholds, `escalationFlagCount` 2–20, `escalationWindowDays`, `updatedAt` = version) | PUT with an old `updatedAt` → 409 `PolicyChanged` |
| `GET restrictions?userId&activeOnly=true` | same | → restrictions (player as either side) | — |
| `POST restrictions` | same | `{ userId, otherUserId?, reason, expiresAt? }` → 201 | — |
| `POST restrictions/{id}/lift` | same | `{ reason? }` → restriction | lifting twice is a no-op |

The match (`DuelMatchDto`) carries: ids and usernames, `arenaKey`, `battlegroundKey`, `gearMode`, kit ids, `status`, `endReason`, `winnerUserId`, both coin stakes, `feePercent` (snapshotted at lock-in), `feeCoins`, `valueMoving`, `stakeItems`, `spoilsItems`, the four transaction ids, `review` (`None|Flagged|Held|Released|Voided`), `reviewTier`, `reviewSignals` (`["S1","S4"]`), `reviewDetails` (the numbers and escalation counts), `alertId`, `reviewedByUserId/At`, `reviewReason`, `revertResult`, **`undeliveredItems`** (`None|ReturnToOwners|Destroy`: what P4's spool does with `CLAIM_PENDING`/`HELD` stacks after a staff action), `telemetry`, `offerCount` and the timestamps.

**For P4** (the plugin's settlement rules, DESIGN §7.3–7.5): `Paid` → pay out items and spoils; `Held` → spool state `HELD`, tell both players; `Refunded` → each side gets its own items. On startup call `abort-unfinished`, then ask `by-token` for each spool file; a match with `review` `Voided` and `undeliveredItems` `ReturnToOwners`/`Destroy` settles the remaining stacks that way. The telemetry the review needs: `durationSeconds` (0 for a forfeit before the fight), per side `damageDealt`, `damageTaken`, `hits`, `attackAttempts`, and in own-gear modes `armorPoints` + `hadWeapon` (+ `mainHand`) at fight start (S3 needs both). The in-game `/knk duel review <match> release|void` sends `X-Acting-User-Id`.

**knk-plugin port** (`knk-core`): `core/ports/api/DuelMatchesApi` — `check`, `lock`, `findByToken`, `startFight`, `complete`, `cancel(matchId, token, DuelEndReason, Telemetry)`, `abortUnfinished`, `release`, `voidHeld`; records in `core/domain/duels/KnkDuelRecords` (`LockRequest`, `ItemSummary`, `Telemetry`/`SideTelemetry`, `Completion`, `FightStart`, `MatchRecord`, `Result`, `RevertSummary`, `CheckResult`, `Refusal`, enums `Status`, `Review`, `Settlement`, `UndeliveredItems`), using P3's `core.duel.GearMode` and `DuelEndReason.apiName()`. Refusals are `core/domain/duels/DuelRefusedException` (`code()`, `playerMessage()`, `find(throwable)`); network errors and 5xx stay `ApiException` (status −1/5xx) for P4's retry. Client: `knk-api-client` `DuelMatchesApiImpl`, `KnkApiClient.getDuelMatchesApi()`; keys `duel-lock:<token>`, `duel-start:<token>`, `duel-complete:<token>`, `duel-cancel:<token>`, `duel-release:<id>`, `duel-void:<id>`. Not wired into `KnKPlugin` (no runtime yet).

**For P7** (stats and web pages): history `GET api/DuelMatches?...`, the staff actions above, `GET/PUT policy`, restrictions. `review = Voided` means the result no longer counts (the projector skips it). Duel alerts are rule codes `DUEL_FLAG` (Medium) and `DUEL_HOLD` (High) plus the monitor's `R10` (Medium), on the existing alerts page; `details.matchId` links the match.

### Deviations and interpretations (reversible; also a comment on KNG-197)

1. **Fee mechanics**: a system-to-system `DUEL_FEE` and a new ledger primitive (above).
2. **Two more reasons** than the three named: `DUEL_REFUND` (a revert's pay-back from `SYS_DUEL`) and `DUEL_CONFISCATION` (`SYS_DUEL` → `SYS_FEES`). The confiscation sink is `SYS_FEES`, the same coin sink as the fee.
3. **`FeePercent` is stored on the match at lock-in**, so a later arena edit doesn't change the fee of a match the duelists already agreed to (D15).
4. **Locks apply to both duelists** of any value-moving duel (frozen, transfer-locked, deactivated), not only to stakers; the age/title rule applies to stakers and to both in drop mode (D14). The coin kill switch (`CurrencyPolicy.TransfersEnabled = false`, R1) refuses coin stakes; item-only stakes still work.
5. **Counting flags** (escalation): a `Voided` result always counts (confirmed); a `Flagged`, `Held` or `Released` one counts while its alert is not acknowledged; the window runs on `EndedAt`. Acknowledging = "false positive", since the alert flow has only acknowledge. `escalation/clear` acknowledges the open `DUEL_FLAG` alerts of the pair or beneficiary (no new table).
6. **An open hold blocks** value-moving duels of the held pair, and of the held result's winner with anyone, whichever count triggered it.
7. **Pair limits** count value-moving matches except Cancelled/Aborted; the cooldown runs from the previous match's end (an unfinished one blocks the pair until abort-unfinished). The **daily win cap** compares the last 24 h of won coins (the opponents' stakes, held results included, voided ones not) plus this duel's possible win.
8. **`GET restrictions` needs the review node** (or the plugin): it carries staff reasons. The other GETs are open to any logged-in user as the prompt says, which includes `reviewSignals`/`reviewDetails`; see the open questions.
9. **Staff actions accept the plugin too** (`RequireServiceOrPermission`), for `/knk duel review` (DESIGN §6.1), with `X-Acting-User-Id` as the auditor.
10. **`POST check`** is an extra read-only endpoint for the invite/accept pre-checks (DESIGN §6.1, §10.3 "checked at invite, accept and lock-in").
11. **`DUEL_FLAG` is severity Medium**: the design's "Warning" isn't a `CurrencyAlertSeverity`; Medium is between the Low notices and the High hold.
12. **Arenas, users and kits a match names can't be deleted while the match exists** (FK Restrict on arena and users, SetNull on kits and the battleground); deleting such an arena answers the generic delete-constraint 409.
13. The node `knk.admin.duel.review` is not seeded into any group (matched by `knk.admin.*`/`*`); its in-game `plugin.yml` entry belongs to P5's commands.

### Open questions for the developer

- Should players (any logged-in user) see a match's `reviewSignals` and `reviewDetails`, or should those be staff-only in the read? Today they follow "GETs for logged-in users".
- Confiscated coins go to `SYS_FEES`. A separate `SYS_CONFISCATED` account would keep the fee sink's total clean for reporting; say if you want it.

### Found in passing / left out

- The web app's alert filter dropdown (`knk-web-app src/types/dtos/currency/CurrencyDtos.ts` `CURRENCY_ALERT_RULES`) lists R1–R9 only; the new codes show on the page but can't be filtered. Comment on KNG-221 (P7 owns the web pages).
- A staff ledger reversal of a duel's stake or payout on the currency admin page (outside the duel flow) makes the duel's later cancel or revert answer 409 `AlreadyReversed`. Comment on KNG-213.

### Live checks for P8

1. Apply migration `AddDuelMatches`: tables `duel_matches`, `duel_policies` (one row, defaults), `duel_restrictions`.
2. Lock-in a staked duel (P4 runtime, or `POST api/DuelMatches` with `X-API-Key`): one `DUEL_STAKE` transaction with two legs on the staff ledger page; `SYS_DUEL` holds the pot.
3. Complete it: `DUEL_PAYOUT` (pot − fee) and `DUEL_FEE` (`SYS_DUEL` → `SYS_FEES`, no player line); "Run reconciliation" on the currency monitor page finds nothing.
4. A thrown fight (loser never swings, < 10 s): paid, `DUEL_FLAG` on the alerts page and in game for staff with the alerts node. A second one between the same two (either direction, or the same winner against someone else): `DUEL_HOLD`, nothing paid; a new staked lock-in between them is refused with `ReviewHoldOpen`; a friendly duel still works.
5. Acknowledge the first flag, play another thrown fight: flagged, not held.
6. Release a held result (paid) and void another (both stakes back, no fee); both are in the audit log with the staff member and reason.
7. Revert a paid result after the winner spent part of it: the winner ends at 0, the loser gets back what was recovered first, `missingCoins` is shown; confiscate another: the coins land in `SYS_FEES`, the fee stays.
8. Restrictions: a player restriction with an end date refuses staked duels (message shows reason and date), allows friendly ones, ends at the date; a pair restriction refuses only that pair; lifting works; audit entries for both players of a pair.
9. Concurrency on MySQL: two simultaneous `complete` calls (same winner) for one match → one payout; two lock-ins of the same token → one match.
10. A web staff member without `knk.admin.duel.review` gets 403 on release/void/revert/restrictions; one with `knk.admin.*` passes.
11. Three paid one-way duels between the same pair within 24 h → an `R10` alert on the next monitor cycle; `R7` doesn't fire for `DUEL_PAYOUT`.
12. Plugin startup: `abort-unfinished` refunds open matches and leaves held results.

---

## P7 — statistics and web-app pages ([KNG-221](https://linear.app/kngpandi/issue/KNG-221))

**Session:** Claude Code cloud session, 2026-10-21. **Status:** pushed, KNG-221 In Review. Not deployed, not live-tested. Started after P2 had pushed (knk-web-api `a0da408`, knk-plugin `1e17f985`). P4 (KNG-217) had **not** pushed, so the plugin part is the resolver hook only (below). Trunks had nothing new: `master` / `main` and the KNG-182 head `88497649` were already in every branch, and no other session pushed to `claude/arena-duels` meanwhile.

### Commits

| Repo | Branch | Commit | What |
|---|---|---|---|
| knk-web-api | `claude/arena-duels` | `dc704f3` | `DuelStatisticsProjector`, `duel` context and projection-owned guard, public-by-default duel W/L/D, rebuild `duel`, tests |
| knk-web-app | `claude/arena-duels` | `6afaa8b` | `/admin/duels` (history), `/admin/duels/:id` (match detail and staff actions), `/admin/duels/restrictions` + profile card, `/admin/duels/policy`, alert rule codes, tests |
| knk-plugin | `claude/arena-duels` | `d0332108` | `StatisticsContext.DUEL`, resolver test over the minigame registry |
| knk-workspace | `main` | `0276c48` | tracker row |
| knk-workspace | `claude/arena-duels` | this commit | this section; `specs/player-statistics/DESIGN.md` §F.1, §F.4, §F.6 (the `duel` context) |

### Tests

- **knk-web-api** (`dotnet build knkwebapi_v2.csproj`, then `dotnet test`; a plain `dotnet build` at the root fails on the `.sln`'s lower-case `tests\` path, filed as [KNG-223](https://linear.app/kngpandi/issue/KNG-223)): baseline at `a0da408` 2829 passed / 4 failed / 73 skipped; after P7 **2861 passed / 4 failed / 73 skipped**, the same 4 known reds as P2. No model change, no migration.
- **knk-plugin** (`./gradlew build -x deployToDevServer`, Temurin 25.0.4 toolchain, session-local Gradle init script pointing at Google's Maven Central mirror because Maven Central answered 429; nothing committed): BUILD SUCCESSFUL, knk-core 2312, knk-api-client 275 (2 skipped), knk-paper 1889 (18 skipped), 0 failures (P2: 2312 / 275 / 1887).
- **knk-web-app** (`CYPRESS_INSTALL_BINARY=0 npx npm@11 ci`, the Cypress binary download was cut off in this container; `npm run test:ci`): baseline 156 suites / 944 tests; after **160 suites / 965 tests**, all green. `npm run build` compiles; `tsc --noEmit` shows only the 3 known errors in `sessionPinnedRows.test.ts`.

| Plan test | Test |
|---|---|
| the projector | `DuelStatisticsProjectorTests`: win/loss, forfeit = loss, the three draw reasons, cancelled and aborted (all six reasons) count nothing, a decisive reason without a winner counts nothing, review states (`Counts`), `ProjectNext_CountsEachDecidedMatchOnce`, `AHeldResult_CountsOnceReleased_AndAVoidedHoldNever`, `ARevertedOrConfiscatedResult_IsTakenBackOutOnce`, `Rebuild_ReprojectsWhatCountsNow`, `RebuildService_AcceptsDuel`, `ProjectionCycle_RunsTheDuelProjector` |
| plugin-posted `wins@duel` refused | `PluginPostedDuelResults_AreRefused_ButDuelKillsAndDeathsAreAccepted` (wins/losses/draws → `NotPluginWritable`; `deaths@duel` and a `pvp_kills@duel` kill accepted); `StatisticsCatalogTests.IsPluginWritable` rows for `duel` |
| visibility default everyone | `Rules_DuelResultsArePublicByDefault_AndThePlayersChoiceWins`, `OtherPlayers_SeeDuelResults_UntilThePlayerHidesThem` (query as a signed-in viewer, the settings DTO, then an update through the normal settings) |
| no duel leaderboards | `Leaderboards_HaveNoDuelBoardsYet` |
| plugin context | knk-plugin `StatisticsContextResolverTest` (duel PLAYING → `duel`, STAGING → `open_world`, siege unchanged, no runtime → `open_world`) |
| web-app pages | `DuelHistoryPage.test` (4), `DuelMatchDetailPage.test` (7: detail, release, void needs a reason, revert shows recovered/missing, confiscate refusal, clear escalation pair/winner, friendly draw), `DuelPolicyPage.test` (3, incl. 409), `DuelRestrictionsPanel.test` (6, incl. pair + expiry, unknown name, lift, profile card, hidden without the node), `CurrencyAlertsPage.test` (+1: duel rule codes and the match link) |

### What later phases rely on

- **API**: `Services/Statistics/DuelStatisticsProjector` (registered in DI, `StatisticsProjectionService` step `duel`, `StatisticsRebuildService` projection `duel`; `POST api/statistics/rebuild {"projection":"duel"}`). `StatisticsCatalog.Duel = "duel"` is in `KnownContexts`; wins/losses/draws are projection-owned in `siege` and `duel`. Projected-source types `duel_match` and `duel_match_retracted`. `StatisticsCatalog.DefaultVisibility(setting, context)`; `LeaderboardCatalog.RankedContexts` (open world, siege) feeds the per-context kill and killstreak boards.
- **Plugin (for P4)**: nothing to wire. `StatisticsContextResolver.of(minigames)` already reads `MinigameRegistry.statisticsContextOf`, which returns the minigame's id for a `PLAYING` member. P4's duel `MinigameParticipation` must use **id `"duel"`** and report **`PLAYING` for COUNTDOWN and FIGHT** (lobby warmup = `STAGING`, so those stats stay `open_world`). `StatisticsContext.DUEL` is the constant.
- **Web app (for P8's guide)**: routes `/admin/duels`, `/admin/duels/:id`, `/admin/duels/restrictions`, `/admin/duels/policy`, all `StaffRoute node="knk.admin.duel.review"`; a "Duels" button on Player moderation; a "Duel restrictions" card on `/admin/users/:id`; `src/apiClients/duelMatchClient.ts`, `src/types/dtos/duels/DuelDtos.ts`.

### Deviations and interpretations (reversible; also a comment on KNG-197)

1. **Public by default = a per-context default.** Precedence: the player's `duel` override → their metric-level value (if they ever set one) → **everyone** for `wins`/`losses`/`draws@duel` → nobody. So a player who set "Wins" to Nobody hides duel wins too, and the cross-context total stays private unless the player makes it public. No rows are written for existing players.
2. **A voided result is taken back out.** The plan says voided matches count nothing; a paid result can be reverted days after it was counted, so the projector retracts it once (−1 on the day it was counted) instead of only skipping it. A held result is never counted until released.
3. **No duel leaderboards**: `duel` is a known context (labels, ordering), but the per-context kill/killstreak boards stay on open world and siege, and the wins boards on siege, until duel leaderboards get per-opponent caps (DESIGN §10.4, §15).
4. **Player lookup** on the staff pages uses the public `api/players/by-name`; a numeric id always works (inactive or merged accounts may not resolve by name).
5. **Alerts page**: besides the three rule codes in the filter, an alert whose `details.matchId` is set gets a "Duel #id" link. No other alert UI.
6. The match detail shows the ledger **transaction ids** as numbers: the transaction page is keyed by `publicId`, which `DuelMatchDto` doesn't carry (leftover, comment on KNG-221).

### Open questions for the developer

- Should an explicit metric-level "Wins: Nobody" (set before duels existed, or by the group action) also hide duel wins, as now, or should duel W/L/D stay public until the player changes the duel context itself?

### Live checks for P8

1. A paid staked duel (P4 runtime) → within one projection cycle (30 s) the winner has `wins@duel` +1 and the loser `losses@duel` +1 (web profile statistics or in-game statistics menu, "Duel" context). A forfeit counts the quitter's loss; a time-limit or agreed draw a draw for both; a cancel or a server-restart abort nothing.
2. A held result shows no W/L; after **Release** it counts; a voided hold never does.
3. **Revert** a paid result on `/admin/duels/:id` → the next cycle takes the win and the loss back out (lifetime and that day).
4. Another signed-in player sees the duel W/L/D on the public profile without any setting; after the player sets Wins → Duel to Nobody (web statistics settings or the in-game menu) the duel wins disappear; the wins total stays hidden throughout.
5. Kills and deaths during the fight are stored as `pvp_kills@duel` / `deaths@duel` (staff statistics panel), warmup kills as open world (needs P4's participation).
6. `/leaderboards` shows no duel board.
7. `POST api/statistics/rebuild {"projection":"duel"}` reproduces the same numbers.
8. `/admin/duels`: filters by arena, player name, status and review; a held match → Release (paid) and Void (reason required); a paid match → Revert after the winner spent part of it shows the recovered amount and "Still missing"; Confiscate shows coins to the sink; both are in the audit log with the reason.
9. Clear escalation (pair, then winner) → the pair's open `DUEL_FLAG` alerts show as acknowledged on the currency alerts page.
10. `/admin/duels/restrictions`: add a player restriction with an end date and a pair restriction by name; both show on each player's staff profile; lift one.
11. `/admin/duels/policy`: change a threshold and save; save again from a second tab opened before → the reload message.
12. Currency alerts page: the rule filter offers R10, Duel flagged, Duel held; a duel alert links its match.
13. A staff member without `knk.admin.duel.review` sees no Duels button, gets the no-access page on `/admin/duels`, and no restrictions card on profiles.
