# Arena duels chain — progress report

**Status:** P0–P7 pushed and In Review; P8 prepared the live test (guide, checklist, merge plan) and waits for the developer. Chain summary at the end.
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

---

## P4 — duel runtime ([KNG-217](https://linear.app/kngpandi/issue/KNG-217))

**Session:** Claude Code cloud session, 2026-10-21. **Status:** pushed, KNG-217 In Review. Not deployed, not live-tested. Started after P0 (`e3814cef`), P2 (`2be401b5`) and P3 (`36195de3`) had pushed; P7's `d0332108` was merged in on the way. KNG-182 has not merged into knk-plugin `main` (still `79be4882`), so `claude/mc-26.2-upgrade` stays the base.

### Commits

| Repo | Branch | Commit | What |
|---|---|---|---|
| knk-plugin | `claude/arena-duels` | `01b5d6a0` | teleport kinds `ARENA` / `ARENA_SYSTEM`, `TeleportPlan.beforeMove`, `DuelEscrowSpool`, `DuelPendingResults`, `DuelRecovery`, siege join refusal hook, tests |
| knk-plugin | `claude/arena-duels` | `0c175f03` | `DuelService` and the rest of `paper/duel/`, the duel listeners, `KnKPlugin` wiring, `config.yml` `duels:`, navigation wording, tests |
| knk-plugin | `claude/arena-duels` | `6fe453b1` | merge of P7's `d0332108` (no conflicts; build re-run green) |
| knk-plugin | `claude/arena-duels` | `bccd338d` | lootbox hold/refusal messages name duels |
| knk-plugin | `claude/arena-duels` | `089bd357` | BATTLE_COUNTDOWN reports `PLAYING` (P7's request, below) |
| knk-workspace | `main` | `8c3c95b` | tracker row |
| knk-workspace | `claude/arena-duels` | this commit | this section |

### Tests

- Toolchain: Temurin JDK 25.0.4 via `-Porg.gradle.java.installations.paths`, Gradle 8.14.3 on JDK 21, Paper 26.3. Maven Central answered 429 on the first run (a log4j jar); a plain re-run downloaded it. No mirror or init script was used.
- Baseline (P0–P3 head `1e17f985`, clean worktree): knk-core 2312, knk-api-client 275 (2 skipped), knk-paper 1887 (18 skipped), 0 failures.
- After P4 (`089bd357`, P7 merged): `./gradlew build -x deployToDevServer` BUILD SUCCESSFUL. **knk-core 2314, knk-api-client 275 (2 skipped), knk-paper 1955 (18 skipped), 0 failures.** No known reds. New: 2 core (teleport kinds), 66 paper (59 under `paper/duel/`, 7 teleport-engine).
- Mocked `World`s are fields everywhere (`DuelHarness.world`, CLAUDE.md rule). The duel tests run a real `DuelService` with a real vault, spool, pending results and recovery around fakes (`DuelHarness`).

| Plan test | Test |
|---|---|
| combat listener matrix | `DuelListenersTest`: fighting pair un-cancelled (also by arrow), same match outside FIGHT cancelled (warmup, countdown), duelist ↔ outsider cancelled both ways, no duelist untouched, an admin-frozen duelist never un-cancelled, the registry's safezone exemption, WorldGuard's PvP block lifted for the pair only, telemetry |
| escrow: crash in LOCKING → items back | `DuelEscrowSpoolTest.aCrashInLockingGivesEachPlayerTheirOwnItems`, `DuelRecoveryTest.startupReplays…` (no record → refund) |
| escrow: ESCROWED + Aborted → back | `escrowedThenAbortedGivesTheItemsBack`, `DuelRecoveryTest.startupReplays…` |
| escrow: Completed → winner | `aCompletedMatchPaysTheWinnerBothStakesAndTheSpoils`, `DuelServiceTest.aWinIsPaidToTheWinnerOnlyAfterTheMatchReleasedThem` |
| escrow: HELD → kept, then release/void | `aHeldResultKeepsEverythingUntilReleased`, `aVoidedHeldResultRefundsAndGivesTheSpoilsBackToTheLoser`, `DuelRecoveryTest.aHeldFileIsSettledOnceStaffReleasedOrVoidedIt` (release, and void with `Destroy`), `DuelServiceTest.aHeldResultKeepsTheStakes…` |
| kit loan: identical after fight / failed lobby teleport / quit / outage / crash; no loan survives | `DuelKitLoanTest` (one test each, slot-for-slot identity of the very same stacks, no tagged item anywhere), plus the KIT_CHOICE swap and countdown lock, consumables in warmup |
| lootbox reel finishing mid-match | `DuelLootboxHoldTest` (the real `LootboxOpening` on the registry: held mid-fight, not handed over while the winner lingers, once after the restore, never into the kit) |
| drop spoils written before the drops are cleared | `DuelEscrowSpoolTest.spoilsAreOnDiskBeforeTheCallerClearsTheDrops`, `DuelServiceTest.dropModeTakesTheLosersDrops…`, `aForfeitInDropModeTakesTheQuittersInventory` |
| lobby teleports together; either fails → cancel + refund | `DuelServiceTest.ifEitherLobbyTeleportFailsTheMatchIsCancelledAndBothAreRefunded` (the other warmup is stopped; `cancel(TeleportFailed)`) |
| teleport kinds | `TeleportServiceTest` (arena warmup without cooldown, combat-tag guard, system move instant + safe spot + not audited + guards still asked, `beforeMove` after the warmup / refusing / skipped on a cancelled warmup), `WarmupPolicyTest` |
| others | quit before the countdown cancels / in the fight forfeits, outage aborts and spools the refund, refused and incomplete lock-ins take nothing, the siege refusal, the teleport restriction, battleground entry/confinement/exit pass, the countdown freeze, the command filter, the drop guard, a keep-mode death, an agreed draw, the registry stages |

### What P5 and P6 build on (service API)

Everything is in knk-paper `net.knightsandkings.knk.paper.duel`. `KnKPlugin.getDuelService()` returns the runtime (null when `duels.enabled: false` or it couldn't start). Main thread only; futures complete on the main thread.

**Negotiation (P5)**
- `offers()`: P3's `DuelOfferBook` (invite, counter, decline, cancel, `setInvitesDisabled`, queries). P5 calls it directly for everything **except accept**.
- `stakeItems()`: `DuelStakeItems`. The editor registers each offered stack with `register(owner, stack, slot, value)` and puts the returned `StakeItem` (a `refId`) into the contract. `value` is the stack's coin value for the ratio rule: the blueprint's `BasePriceMin` × amount, 0 when unknown. P5 has to look it up (the item instance → blueprint); the offer book's `itemValue` reads it from here. `forget(owner)` happens on quit.
- `inviteRefusal(Player)`: the D18 rules (already in a duel or locking, another minigame, combat tag, frozen, dead, duels off), for invite and accept. **Not checked here:** "inviter inside an enabled arena" and the ignore list (P5).
- `accept(Player, offerId)` → `CompletableFuture<LockOutcome(ok, message, match)>`. It runs the whole DESIGN §6.5 lock-in: accept rules, the binding queue cap (`ArenaQueue.admit`), the engine check for both lobby teleports, item presence (`isSimilar` + amount, the registered slot first) and `DuelItems.stakeRefusal`, the spool written before anything is taken, then `POST api/DuelMatches` (timeout `duels.api-timeout-seconds`; on a timeout it reads `by-token` and cancels a create that landed). On success the lobby teleports start for both players. A refusal closes the negotiation (`DuelObserver.lockRefused`), and the message is the API's player message where there is one.
- Arenas: `accept` reads the arena from `ArenasDataAccess.cachedById`. P5 should `refreshAsync()` when an invite is made (P1's advice) and pass that arena's `DuelArenas.settingsOf(arena)` to `offers().invite(...)`.

**In a match (P5/P6)**
- `chooseKit(Player, kitId)` → `KitChoice` (`/duel kit`, the KIT_CHOICE picker); `offerDraw(Player)` → `DrawOffer` (`/duel draw`); `cancel(token)` (staff `/knk duel cancel`: any phase but LOCKING, refund); `refreshEscrow(token)` (after `/knk duel review <match> release|void` or a web-app review: settles the held spool file from the API and delivers); `claim(Player)` → `Delivery` (`/duel claim`); `pendingClaims(uuid)`.
- Queries: `matchOf(uuid)`, `match(token)`, `matches()`, `phaseOf(uuid)`, `queueOf(arenaId)` (P3's `ArenaQueue`: `queuedCount`, `allocator().busyCount()/totalCount()` for "2/3 waiting, 5/8 busy"), `queuePosition(match)` ("#2 in line"), `now()` (the tick to pass to `match.secondsRemaining(now)` for the boss bar), `isParticipating(uuid)`, `isOnBattleground(uuid)`.
- `DuelMatch` (read-only): `token`, `matchId`, `arena`, `settings`, `contract` (stakes for the announcement and the detail menu), `phase`, `gearMode`, `playerOf/nameOf/userIdOf(side)`, `sideOf(uuid)`, `kitOf(side)`, `hasPickedKit(side)`, `battleground`, `secondsRemaining(now)`, `isWaitingForBattleground`, `result`, `settlement`, `drawOfferExpiresAt(side, now)`.
- **`addObserver(DuelObserver)`**, all on the main thread: `negotiationsClosed(List<Closed>)` (decline, expiry, quit, superseded, lock refused), `lockRefused(negotiation, message)`, `phaseChanged`, `warmupStarted(match, seconds)` (P6's warmup broadcast), `kitChosen`, `fightStarted`, `drawOffered(match, side, expiresAtTick)`, `matchEnded(match, result)`, `settled(match, PAID|HELD|REFUNDED, or null while the API is unreachable)` (P6's result / "pending review" announcement), `released(match)`.
- P4 sends only plain chat lines to the two duelists (warmup, get ready, FIGHT title, result, draw offer, held, payout follows, claims). P5/P6 can replace them; they live in `DuelService` and `DuelTexts`.

**Plumbing**
- `DuelParticipation` (registry id `duel`): LOCKING/TRAVELLING/WARMUP = `STAGING`, BATTLE_COUNTDOWN/FIGHT = `PLAYING` (the `duel` statistics context), ENDING = `FINISHING`. `holdsLootDrops` runs from LOCKING until that player's gear is back. Combat (enchant safezone), outage release and resume, `teleportRefusal` (`DuelTeleportRestriction`: everything but `ARENA`/`ARENA_SYSTEM`, staff passes with **`knk.admin.duel`**, a node P5 registers). `keepsOwnScoreboard` keeps the default (STAGING/PLAYING); P6 can override it.
- `DuelBattlegroundAccess`, registered in `DomainAccessExemptions`: entry for the allocated pair from the countdown teleport, confinement in COUNTDOWN/FIGHT, `passExit` before the exit teleport, `revoke` on every end path.
- Teleports: `TeleportKind.ARENA` / `ARENA_SYSTEM`, `TeleportPlan.arena(subject, destination, label, beforeMove)` / `arenaSystem(subject, location, label)`, `TeleportPlan.BeforeMove` and `withBeforeMove` (also for KNG-199).
- Kit loans (`DuelKitLoans.Paper`) read the kit with `KitsQueryApi.getById` and place it with `KitGrantPlacer`. There is no claim (no cost, cooldown or access check), and every stack is tagged `knightsandkings:knk_duel_loan=<token>` (`DuelItems.LOAN_KEY`). This is general enough for the siege kit mode (KNG-199).
- Files: `duel-escrow/<token>.yml`, `duel-escrow/pending-results/<token>.yml`, `duel-vault/<uuid>.yml`.
- Config `duels:` (DESIGN §12, plus `result-retry-seconds` 30 and `held-refresh-seconds` 300).
- `SiegeService.setOtherMinigameRefusal(fn)` is used by both `join` and `joinDenial`. A duelist gets "You are in a duel.", a negotiator "You are negotiating a duel…".

### DisallowedPVPEvent check

`com.sk89q.worldguard.bukkit.protection.events.DisallowedPVPEvent` is present in `worldguard-bukkit-7.0.20`, the build the KNG-182 branch compiles against (checked with `javap`: `getAttacker()`, `getDefender()`, `getCause()`, `Cancellable`). `DuelWorldGuardPvpListener` handles it at HIGHEST and cancels it (lets the hit through) for the fighting pair only. The WorldGuard Bukkit jar isn't on the test classpath, so the decision lives in `DuelService.liftsWorldGuardPvpBlock` and is tested there.

### Deviations and interpretations (reversible; also a comment on KNG-197)

1. **Pending results are `pending-results/<token>.yml`**, not `.json` (DESIGN §7.4), to match the escrow and vault files (Bukkit YAML). The content is the same.
2. **A non-decisive end refunds the items at once** (draws, cancels, aborts), without waiting for the API's answer: nothing can move between the players, and §7.5 already says so for an outage. Decisive results wait for the API (it may hold them).
3. **A lock-in that timed out but did land** is cancelled with `ApiOutage` (→ Aborted), because no end reason names "lock-in lost". Its refund is spooled like any result.
4. **BATTLE_COUNTDOWN reports `PLAYING`** (P7's report asks for it; P0 suggested `STAGING`). Damage is locked in the countdown, so only a countdown forfeit-by-death lands in the `duel` context.
5. **A death in the countdown, in drop mode, gives spoils.** It is a forfeit (P3 interpretation 3), so it is treated like a forfeiting quit (O2).
6. **Staff teleports of a duelist pass with `knk.admin.duel`.** §8.3 says every engine teleport is refused; the siege guard has the same staff bypass. Remove the node to make it absolute.
7. **The command filter reuses the siege matcher**, so `/siege`, `/siegemenu` and `/sgm` stay allowed for duelists. The siege refuses them anyway. Owner/staff-mode players and holders of `knk.admin.duel` skip the filter; owner/staff mode also skips the inventory guards (siege precedent, the same dupe caveat).
8. **After a crash or a quit, the join restore sends the duelist back to where they stood before the lobby teleport** (the vault's location, outside the engine like the siege vault). The normal end paths send them to the arena exit.
9. **An outage or a shutdown restores in place** with no exit teleport: the outage action (or the restart) moves the player anyway.
10. **"Kit consumables" means every consumable in WARMUP in kit modes.** The inventory holds only the kit then (projectiles too). In the countdown, projectiles and pearls are blocked in every mode (§5.1).
11. **A loser of a finished match gets their gear back right after the respawn** (at the exit). The winner gets theirs at the end of the linger. §8.4 says "at the exit teleport" for both; the loser is already at the exit.
12. **Navigation and lootbox messages now say "siege or a duel"** (P0's open point). The enum names (`Exclusion.SIEGE`, `IN_SIEGE`) are unchanged.
13. **`MinigamePlayerVault`'s test constructor is public**, so the duel tests run on the real vault. This is the only edit to a P0 file.

### Left for later phases / found in passing

- P5: the item valuation for `DuelStakeItems.register(…, value)` (instance → blueprint → `BasePriceMin`), the arena-membership and ignore-list invite rules, the `/duel` commands (claim, toggle persistence, kit, draw), `knk.duel`/`knk.admin.duel` in plugin.yml, `/knk duel cancel|review`.
- P6: the death message "to the arena and spectators" (P4 sends no vanilla death message), announcements, the scoreboard override, and the menus reading `matches()` / `queueOf`.
- `KitGrantPlacer.place` still drops overflow on the ground. That can't happen after the kit-mode clear, but the loan sweep wouldn't see a dropped stack. Comment on KNG-199.
- `deliverLootboxItemsAfterSiege` (KnKPlugin) is now also the duel's after-restore hook; only the name is siege-specific.

### Live checks for P8

Setup: P1's `arena_2` with a lobby, an exit, one or more enabled battlegrounds with spawns, duels on, and two eligible kits. P2's migration applied. P5's commands, or a temporary call of `getDuelService().offers().invite(…)` + `accept(…)`.

1. **Staked own-gear (keep) duel**: both lobby teleports start together (5 s warmup, no cooldown afterwards, `/spawn` still free). The stakes leave the inventories at accept and `duel-escrow/<token>.yml` shows `ESCROWED`. Warmup → "Waiting for a battleground" → both at their spawns, frozen (looking around works), the command allow-list applies → FIGHT. The winner gets both stakes after the linger at the exit, the loser respawns at the exit, and the file is gone.
2. **Moving during the lobby warmup** cancels both teleports: `TeleportFailed`, everything back, coins refunded on the staff ledger.
3. **PvP**: a fight inside a `pvp deny` town or district battleground works for the pair (including splash potions: the `DisallowedPVPEvent` path); a third player can't hit either duelist and vice versa; custom enchantments trigger in the fight.
4. **Entry/exit**: an outsider can't walk, pearl or ride into the battleground; a duelist can't leave it in the countdown or the fight (walk, pearl, chorus fruit, elytra, boat); the exit teleport at the end works.
5. **Teleports and commands**: `/spawn`, `/warp`, `/home`, `/tpa` to a duelist, `/back` and `/hub` are refused for duelists from the accept on; staff `/tp` with `knk.admin.duel` passes.
6. **FIXED_KIT**: the own inventory is cleared and stored as you arrive (`duel-vault/<uuid>.yml`), the kit is granted with no cost/cooldown even if its title requirement isn't met, food can't be eaten in the warmup, kit items can't be dropped or stored. After the fight the inventory is identical and no kit item is left anywhere (inventory, armour, off-hand, ender chest).
7. **KIT_CHOICE**: the placeholder is the first eligible kit; a pick swaps it; a pick in the countdown is refused; no pick → the placeholder fights.
8. **Kit mode, quit mid-fight**: your own inventory is back at once (the opponent wins by forfeit); rejoin → you are back where you were before the duel, and the vault file is gone.
9. **Kit mode, crash** (`kill -9` during the warmup): on rejoin the kit is swept, your inventory is back, and you are at your pre-duel spot. Startup log: `abort-unfinished` refunded the coins.
10. **OWN_GEAR_DROP**: the loser's inventory isn't dropped on the ground; the winner receives it with the stakes after the linger; a draw (`/duel draw` both, or the time limit) takes nothing; a forfeiting quit hands the quitter's inventory to the winner.
11. **Full inventory**: the payout goes to the ender chest, then waits for `/duel claim`.
12. **API outage mid-fight**: the outage action aborts the duel; gear and items come back at once; the coin refund arrives when the API is back (`pending-results/` empties).
13. **Held result** (P2 live check 4's second thrown fight): both are told "pending staff review", the items stay in `HELD`; after a release (web app) the winner gets them within `held-refresh-seconds` or on rejoin; after a void each side gets their own back.
14. **Lootbox**: a reel finishing mid-match says "kept safe" and arrives after the restore, not in the kit; opening a lootbox during a duel is refused.
15. **Siege**: a duelist or negotiator can't join a siege ("You are in a duel." / "You are negotiating a duel…").

---

## P5 — negotiation UI and commands ([KNG-219](https://linear.app/kngpandi/issue/KNG-219))

**Session:** Claude Code cloud session, 2026-10-21. **Status:** pushed, KNG-219 In Review. Not deployed, not live-tested. Started after P4 (`089bd357`, KNG-217 In Review). KNG-182 has not merged into knk-plugin `main` (still `79be4882`), so `claude/mc-26.2-upgrade` stays the base. No P6 commits were on the branch when this phase pushed.

### Commits

| Repo | Branch | Commit | What |
|---|---|---|---|
| knk-plugin | `claude/arena-duels` | `4cb1aa80` | `paper/duel/ui/` (editor, offer view, kit picker, chat, controller, toggles, kit previews), `/duel`, `/arena`, `/knk duel`, `DuelMenuListener`, plugin.yml + `CommandNodes`, `KnKPlugin` wiring, tests |
| knk-plugin | `claude/arena-duels` | `ea7ecb4e` | KNG-224 reference in the ratio workaround |
| knk-plugin | `claude/arena-duels` | `d1016f42` | `/duels` and `DuelMenuPort` (agreed with the P6 session) |
| knk-workspace | `main` | `1410ccf` | tracker row |
| knk-workspace | `claude/arena-duels` | this commit | this section |

### Tests

- Toolchain: Temurin JDK 25.0.4 via `-Porg.gradle.java.installations.paths`, Gradle 8.14.3 on JDK 21, Paper 26.3. Maven Central answered 429 on the first runs (dependency downloads); plain re-runs got through. No mirror or init script.
- Baseline (P4 head `089bd357`, clean): knk-core 2314, knk-api-client 275 (2 skipped), knk-paper 1955 (18 skipped), 0 failures.
- After P5: `./gradlew build -x deployToDevServer` BUILD SUCCESSFUL. **knk-core 2314, knk-api-client 275 (2 skipped), knk-paper 1987 (18 skipped)**, 0 failures, no known reds (re-run at `d1016f42`). New: 32 knk-paper tests (`DuelNegotiationUiTest` 20, `DuelCommandsTest` 3, `ProposalDraftTest` 6, `DuelChatTest` 3). knk-core unchanged.
- The UI tests run P5 on P4's real runtime (`DuelHarness`) through `DuelUiHarness`: a fake `DuelGui` whose inventories are maps, tracked open inventories, a typed anvil answer, and chat/button capture. Mocked `World`s stay in fields (P4's harness).

| Plan test | Test |
|---|---|
| editor click handling | `DuelNegotiationUiTest`: `aClickOnYourOwnInventoryStakesAReferenceAndNothingMoves` (no `setItem` on the player inventory, same stack twice refused, icon click removes), `everyClickAndDragInADuelMenuIsCancelled` (every `ClickType`, top and bottom, and a drag, through `DuelMenuListener`), `theCoinButtonsAndTheAnvilSetBothSidesWithinTheArenasMaximum`, `theKitButtonOpensThePickerForAFixedKitDuel`, `theFeeAndTheApisEligibilityWarningsAreShown`, `aLoanedOrBlockedItemIsRefusedWhenClicked` |
| lock-in with a moved item → refused, nothing taken | `anItemMovedAwayBeforeLockInIsRefusedAndNothingIsTaken` (no escrow file, the other side untouched, negotiation closed, told once); `anItemMovedToAnotherSlotIsStillTakenAtLockIn` |
| API refused → items returned | `anApiRefusalHandsTheItemsBack` (both sides' items back in the inventories, the API's message once) |
| a gear mode the arena doesn't allow can't be selected | `theGearModeButtonCyclesOnlyThroughTheModesTheArenaAllows`, `anArenaWithOneGearModeShowsAFixedLabel`, `theOfferBookRefusesAGearModeTheArenaDoesntAllow`, `ProposalDraftTest.theGearModeIsAlwaysOneTheArenaAllows` |
| others | id-stamped buttons and the design's chat line, drop mode in capitals, no Counter on the last offer (chat and view), a stale button, the 10 s expiry warning once, the offer view's Accept, the invite rules (self, toggle persisted, offline, outside an arena), KIT_CHOICE prompt/pick/opponent's pick/lock at the countdown, `/duel` routing, `/knk duel list|cancel` and the review node |

### What was built (for P6 and P8)

All in knk-paper. Package `net.knightsandkings.knk.paper.duel.ui` unless noted.

- **`DuelNegotiationUi`** (a `DuelObserver`): the invite rules the runtime leaves to the UI, then the editor or a quick invite; `counter`, `accept` (→ `DuelService.accept`, P4's lock-in), `decline`, `cancel`, `view`, `kit`, `draw`, `toggle`, `claim`; the 1 s `tick()` for the expiry warning; chat on expiry, quit and superseded negotiations; the KIT_CHOICE prompt on `warmupStarted`, the opponent's pick on `kitChosen`, closing the picker when the countdown starts. Invite rules:
  - inviter inside an enabled arena's region (`arenaAt`: the cached arenas' `WgRegionId` among WorldGuard's regions at the player, same world)
  - P4's `inviteRefusal`
  - invitee online and visible, not ignoring the inviter (`IgnoreService`), invites on; "is in a duel" when matched
  - the offer book's rules up front (outgoing invite, pair, cooldown, max incoming)
  - the advisory queue cap ("The arena is full (3/3 waiting)…")
  - the arena refreshed (`ArenasDataAccess.refreshAsync`, P1's advice), then `TeleportService.check` for both lobby teleports (the `ARENA` plan, through `DuelTeleporter.checkLobby`)
- **`ProposalDraft`**: the editor's contract. It holds only the arena's allowed gear modes, and the `FIXED_KIT` kit is one of the eligible kits (the first by default). Items are own-inventory references (`DuelStakeItems.register`, with the slot as a hint). The author may remove the other side's items. Coins stay within 0..`MaxCoinStake` per side. It also holds the fee and the advisory violations.
- **`DuelProposalEditor`**: the 54-slot editor with its own holder (layout in the class javadoc). The API's advisory `POST check` runs on open and after every change, one call in flight per editor, and shows eligibility, limits, balance and ratio refusals plus the API's fee.
- **`DuelOfferView`**: read-only, with Accept / Counter / Decline for the receiver. There is no Counter on the last offer, and the author sees no buttons.
- **`DuelKitPicker`**: the `FIXED_KIT` pick for a draft, and the warmup pick (`/duel kit`) showing the opponent's pick. **`DuelKitPreviews`** resolves a kit's items once, the way the kit loan does (`KitGrantPlacer.resolveAsync`, no claim).
- **`DuelChat`**:
  - the offer line in DESIGN §6.4's format, with `[View] [Accept] [Counter] [Decline]` running `/duel <action> <offerId>`
  - drop mode in red capitals ("OWN GEAR, THE LOSER'S INVENTORY DROPS TO THE WINNER")
  - the expiry warning at 10 s (`EXPIRY_WARNING_SECONDS`)
  - the kit prompt
- **`DuelGui`**: the Paper inventories and icons behind an interface (`DuelGui.paper()`).
- **`DuelInviteToggles`**: `/duel toggle`, persisted in `plugins/KnightsAndKings/duel-toggles.yml` and set on the offer book at startup and on join.
- **Commands** (`paper/commands/`):
  - `DuelCommand`: the `/duel` tree. Subcommand names win over player names.
  - `ArenaCommand`: `/arena [name]`. It opens P6's `arena_main` through the `DuelMenuPort` first; with no port, or when the open returns false, it answers in chat (queue, live duels, `[Challenge a player]`, `[My claims]`).
  - `DuelsCommand`: `/duels` (P6's `duel_matches`), `/duels view <token>` (`duel_match_detail`) and `/duels spectate <arenaId>` (the spectator warp). These are the forms P6's announcement buttons run. Without a port it lists the live duels in chat.
  - **`DuelMenuPort`** (`duel/ui/`): `openMatches`, `openMatch`, `openArena`, `spectate`. **P6: `DuelMenus implements DuelMenuPort`, then `KnKPlugin.setDuelMenuPort(duelMenus)` in `initializeDuelPresentation()`** (agreed with the P6 session by message, 2026-10-21).
  - `DuelAdminCommand`: `/knk duel list | cancel <match> | refund <match> | review <match> release|void [reason]`. `<match>` is the API id or the token's first 8 characters.
- **Nodes** (plugin.yml):
  - `knk.duel`, default true, for `/duel`, `/duels` and `/arena` through `CommandNodes`
  - `knk.admin.duel`, for `/knk duel` and P4's staff teleport and command bypass
  - `knk.admin.duel.review`, for `review`
  - both admin nodes are children of `knk.admin`
- **`DuelMenuListener`** (`paper/listeners/`): cancels every click and drag in the three menus, at LOWEST and again at HIGHEST. It also handles close, join and quit.
- **Changes to P4 files**:
  - `DuelService.escrowEntries()` (staff list and review)
  - a lock-in refused before the match record (full queue, no kit) now tells both players "Duel not started: …", like the other refusals. `lockRefused` now always means "both were told", and the UI relies on that.
- **Wiring**: `KnKPlugin.initializeDuelUi()` right after `initializeDuels()`. The `/knk duel` registration is in `registerCommands()`, and `closeAll()` runs on disable. `/duel` and `/arena` are registered even when duels are off, and then they say so.

### Deviations and interpretations (reversible; also a comment on KNG-197)

1. **Stake ratio with items is left to the API ([KNG-224](https://linear.app/kngpandi/issue/KNG-224)).** The plugin can't value staked items: `KnkItemBlueprint` has no base price, and there is no instance → blueprint lookup. P3's offer book would value items at 0 and refuse DESIGN §6.2's own example "my sword, your 500 coins" at send time.
   - The offer book gets the arena settings with the ratio set to 0 (`DuelNegotiationUi.bookSettings`).
   - The editor still warns locally when only coins are staked, and shows the API's check, which values items.
   - Lock-in (API) is binding.
   - Side effect: `DuelNegotiation.settings()` and `DuelMatch.settings()` report ratio 0.
2. **Editor layout.** DESIGN §6.4's sketch doesn't fit 9 columns with both sides' coin buttons. The editor shows 12 stake slots per side (rows 1–3, a divider column). Each side gets `−100 −10 +10 +100` in row 4. The amounts with the anvil, and Cancel/Send, are in row 5. Fee and warnings are in row 0. A side with more than 12 stacks (`MaxItemStacks` > 12) shows only the first 12.
3. **Every API refusal is advisory in the editor.** The check result is shown, but sending isn't blocked. The offer book's own rules do block. This follows §6.3: advisory at send, binding at lock-in.
4. **`/duel cancel [id]`**: without an id it withdraws your own outgoing invite, or your only negotiation. Both players are told.
5. **`/knk duel refund <match>`** works on running matches, the same as `cancel`. It goes through P4's `cancel(token)` → the API's cancel endpoint with `AdminCancelled`. A finished, paid result is reverted in the web app (P7), and a held one is reviewed with `review`.
6. **`/knk duel review`** works in game only, because it needs the staff member's user id for `X-Acting-User-Id`. After the API answers it calls `DuelService.refreshEscrow`, so online players get their items at once.
7. **Kit previews** list the kit's resolved items by name, at most 12 lines. They load on first use, and when a KIT_CHOICE match starts travelling.

### Open questions

- None for the developer. KNG-224 needs a small API/DTO decision when it is picked up.

### Live checks for P8

Setup: P4's setup (P1's `arena_2` with a lobby, an exit, battlegrounds with spawns, duels on, two eligible kits; P2's migration). Two players A and B inside `arena_2`'s region.

1. **`/duel B` outside the arena** → "Stand inside an arena to challenge a player."; inside → the editor opens. `/duel B` while B has `/duel toggle` on, or ignores A → "That player doesn't accept duel invites." (the toggle survives a restart).
2. **Editor clicks**: shift-click, number keys, double-click and drag in the editor or on your own inventory never move an item. A click on your sword adds it to your half with "Staked in this offer", and the sword stays in your inventory. Clicking the icon removes it. B's items can't be added by A.
3. **Coins**: the −/+ buttons for both sides, the anvil for an exact amount (capped at `MaxCoinStake`), and your balance shown as a hint.
4. **Gear mode**: the button cycles only through the arena's allowed modes (set two of them in the web app). With one mode, the label is fixed. `FIXED_KIT` shows the kit button and the picker with item previews.
5. **Warnings**: a coin stake 10,000 vs 0 at ratio 50 → a local warning. A pair on cooldown, a new account or too few coins → the API's message in the warnings icon. The fee shows 5% of the pot.
6. **Send** → B gets the chat line with the arena, "offer 1/3, 60 s", both stakes and `[View] [Accept] [Counter] [Decline]`. Drop mode reads in red capitals. A gets "Duel offer 1/3 sent".
7. **Counter** from chat → B's editor, pre-filled. Send → A gets offer 2/3. A's counter → offer 3/3 without `[Counter]` (chat and view). Clicking an old `[Accept]` → "That offer is no longer current."
8. **Expiry**: leave an offer unanswered. At 10 s the receiver gets "… expires in 10 s" with the buttons once, then both get the expiry lines.
9. **Accept with a moved item**: A stakes a sword and B waits. A drops the sword, then B accepts → "Duel not started: A no longer has every staked item." Nothing is taken from B, and there is no `duel-escrow/` file.
10. **API refusal**: a pair on cooldown (P2) → the accept is refused with the API's message, and both players' items come back at once.
11. **KIT_CHOICE**: the kit prompt in the warmup (clickable kits, `[Menu]`). `/duel kit Archer` → "You will fight with Archer", and the opponent sees "A picked Archer". The picker shows the opponent's pick. At the countdown the picker closes: "The kits are locked".
12. **`/duel draw`** outside the fight → "You can offer a draw only during the fight". `/duel claim` with a full inventory after a win (P4 check 11).
13. **`/arena`** in the arena → P6's arena menu (or, without it, the chat summary: queue, live duels, buttons). `/arena arena_2` from elsewhere. Tab completion lists arenas. `/duels` → the live-matches menu; an announcement's [Details] (`/duels view <token>`) and [Spectate] (`/duels spectate <id>`) open the detail and start the spectator warp.
14. **Staff**: `/knk duel list` shows running matches (token, #id, phase, coins) and held or unclaimed escrow. `/knk duel cancel <token>` refunds a running duel. `/knk duel review <id> release` without `knk.admin.duel.review` is refused; with it, the winner gets the items at once.
15. **Permissions**: a group without `knk.duel` gets "no permission" for `/duel` and `/arena`, and neither command is in its tab list.

---

## P6 — announcements, menus and spectating ([KNG-220](https://linear.app/kngpandi/issue/KNG-220))

**Session:** Claude Code cloud session, 2026-10-21. **Status:** pushed, KNG-220 In Review. Not deployed, not live-tested. Started after P4 (`089bd357`, KNG-217 In Review), next to P5. P5's `4cb1aa80`, `ea7ecb4e` and `d1016f42` were merged on the way; the `KnKPlugin` conflict was only adjacent additions (both kept). KNG-182 has not merged into knk-plugin `main` (still `79be4882`), and knk-web-api `master` is still `2d71155`, so there was no trunk to merge.

### Commits

| Repo | Branch | Commit | What |
|---|---|---|---|
| knk-web-api | `claude/arena-duels` | `7872831` | `MenuTemplateSeed.Duel.cs` (`duel_matches`, `duel_match_detail`, `arena_main`, `duel_challenge`), registered in the canonical list and the content-seed export, `MenuTemplateDuelSeedTests` |
| knk-plugin | `claude/arena-duels` | `0d62c543` | `knk-core` `core/duel/view/`, `DuelAnnouncer`, `DuelHud`, `DuelSnapshots`, `DuelSpectators`, `DuelMenuData`, `DuelMenuFeature`, `DuelMenus`, `KnKPlugin` wiring, `config.yml` `duels.announce.templates`, `content-seeds.json`, tests |
| knk-plugin | `claude/arena-duels` | `a6fdd17c` | merge of P5 (`d1016f42`); `DuelMenus implements DuelMenuPort`, `setDuelMenuPort(duelMenus)` |
| knk-plugin | `claude/arena-duels` | `d8897a79` | bounded statistics cache in `DuelMenuFeature` |
| knk-workspace | `main` | `0ba77b4` | tracker row |
| knk-workspace | `claude/arena-duels` | this commit | this section |

### Tests

- **knk-plugin** (`./gradlew build -x deployToDevServer`, Temurin JDK 25.0.4 via `-Porg.gradle.java.installations.paths`, Paper 26.3). Maven Central answered 429 on the first runs; a re-run with fewer workers downloaded everything. No mirror was used.
  - Baseline (P4 head `089bd357`, clean worktree): knk-core 2314, knk-api-client 275 (2 skipped), knk-paper 1955 (18 skipped), 0 failures.
  - After P6 with P5 merged (`d8897a79`): BUILD SUCCESSFUL. **knk-core 2338, knk-api-client 275 (2 skipped), knk-paper 2013 (18 skipped), 0 failures.** No known reds. New: 24 core (`core/duel/view`), 26 paper (`DuelMenuFeatureTest` 14, `DuelPresentationTest` 12); the rest of the paper growth is P5's.
  - Mocked `World`s are fields (CLAUDE.md rule). The presentation tests run the real P4 `DuelService` through `DuelHarness`.
- **knk-web-api** (`dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`, .NET 8 SDK). P7 measured 2861 passed / the 4 known reds on the same head (`dc704f3`). After P6 (`7872831`): **2873 passed, 4 failed, 73 skipped.** The 4 are the known reds: `PathResolutionServiceTests` ×2, `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`, `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`. New: 12 (`MenuTemplateDuelSeedTests` 8, the content-seed theory +4).
- `content-seeds.json` was regenerated with `KNK_MENU_CONTENT_SEED_EXPORT=… dotnet test --filter MenuTemplate`. Only the four duel templates were added; the existing entries are unchanged.

| Plan test | Test |
|---|---|
| the pure views | knk-core `DuelViewsTest` (two heads per listed match, the waiting line, the detail tile and the "over" state, side cards with only the stats the API returned, stake tiles, the arena menu's rules/queue/claims/spectate/challenge states, challenge rows, the sidebar with the viewer's own duel first and the 15-line cap, the boss bar per phase, which match a spectator follows) |
| the announcer cooldown | knk-core `DuelAnnouncementsTest.oneWarmupBroadcastPerPlayerPerCooldown` / `aZeroCooldownNeverLimits`; knk-paper `DuelPresentationTest.theSpamCooldownAllowsOneWarmupBroadcastPerPlayer` (real runtime) |
| spectating through the menu enforces the warp conditions | knk-paper `DuelMenuFeatureTest` with the real `WarpCommand` and teleport engine: `spectatingStartsTheSpectatorAreasWarp_WarmupThenChargeThenTeleport` (warmup, then the 10-gem charge, then the teleport), `theWarpsConditionsApply_ALockedSpectatorAreaIsRefused` (TitleTooLow: refused, nothing charged), `withoutTheWarpNodeNothingHappens`, `theDetailsSpectateButtonFindsTheArenaByTheMatchToken`, `anAreaWithoutAWarpIsReachedOnFoot_AndAnArenaWithoutOneSaysSo` |
| others | the seeded menus validate against the registered feature (contract test over `content-seeds.json`); real stake stacks; side cards read as the viewer, cached 10 s; `/duel <name>` only inside the arena, invalid names refused; the openers and the repaint of open duel menus only; the announcer around the real P4 runtime (buttons, toggles, paid and held results, draws, cancels and the death line only to the arena); the sidebar/boss bar for duelists and a spectator, the registry keeping their board, the old board back on leaving |

### What later phases (and P8) build on

**knk-web-api**: `MenuTemplateSeed.DuelMatchesMenuKey` / `DuelMatchDetailMenuKey` / `ArenaMainMenuKey` / `DuelChallengeMenuKey`. Create-only like every menu seed; staff edit them through the menu CRUD API.

**knk-core `core/duel/view/`** (Bukkit-free): `DuelMatchSnapshot` (a read-only copy of a running match), `DuelViewText`, `DuelAnnouncements` (templates, `arenaAnnounces`, `Cooldown`), `DuelHudView` (`sidebar`, `bossBar`, `followed`, `QueueInfo`), the menu views `DuelMatchRowView`, `DuelMatchDetailView`, `DuelSideCardView`, `DuelStakeRowView`, `ArenaMenuView`, `DuelChallengeRowView`, `DuelServerView`, and the shared ids in `DuelMenuIds`.

**knk-paper**
- `duel/DuelAnnouncer` (a `DuelObserver`): the warmup broadcast with `[Spectate]` (`/duels spectate <arenaId>`, only when the arena has a spectator area with a warp) and `[Details]` (`/duels view <token>`), both served by P5's `/duels`; the result after the API's answer; draws; cancels, aborts and the death line only to the duelists and the players in the spectator area. Templates: `config.yml` `duels.announce.templates` (commented out; the defaults are in `DuelAnnouncements`).
- `duel/DuelHud`: per-viewer sidebar and boss bar, refreshed every second and on every phase change. `DuelService.setDuelBoardViewers` / `showsDuelBoard`, asked by `DuelParticipation.keepsOwnScoreboard`, so `ScoreboardUtil`'s registry predicate keeps the board of spectators too.
- `duel/DuelSpectators`: who stands in an arena's spectator area or its own region (WorldGuard ids at the player's position).
- `menu/content/DuelMenuFeature`: roots `duelMatch` (`ctx.token`), `arena` (`ctx.arena`: the id; empty = the arena the player stands in or watches from, else the first), `duels`; row sources `duel.matches` (`arenaId` narrows), `duel.match-side`, `duel.stakes`, `duel.challenge-candidates`; actions `duel.spectate` (`arenaId` or `token`), `duel.challenge` (`name`), `duel.claim`; conditions `duel.matches-empty`, `duel.in-arena`. `DuelMenuFeature.spectate(player, arenaId)` is the one spectate path: the arena's first spectator area with `TeleportEnabled`, through `WarpCommand.warpTo`.
- `menu/content/DuelMenus implements DuelMenuPort` (P5's interface), registered with `KnKPlugin.setDuelMenuPort` in `initializeDuelPresentation()`; it repaints open duel menus on phase changes, settlements and releases.
- Small edits to P4 files: `DuelMatch.stakeStacksOf(side)` and `fightStartTick()`, the two `DuelService` methods above, `DuelParticipation.keepsOwnScoreboard`.

### Deviations and interpretations (reversible; also a comment on KNG-197)

1. **A fourth template, `duel_challenge`**: the picker of online players behind `[Challenge a player]` (DESIGN §9.3). A pick runs `/duel <name>`, so P5's invite rules and proposal editor apply.
2. **"Both heads"** in `duel_matches` are two rows per match (challenger, then opponent) in a grid eight wide, so a pair never splits across lines; either head opens the detail.
3. **`AnnounceMatches` is the arena's switch; `AnnounceFriendly` also covers duels without stakes.** Results and draws use the same toggles and no cooldown. The spam cooldown limits only the warmup broadcast (§9.1). When the arena doesn't announce, results and draws go to the duelists and the spectator area instead.
4. **The result of a value-moving duel is announced after the API's answer**, so a held result says "pending review" (tier 2). A friendly duel is announced at once. While the API can't be reached the line says "(payout follows)". A refunded decisive result names no winnings.
5. **The death line goes to the arena** (duelists and spectator area, DESIGN §8.6), which P4 left to P6. The duelists also keep P4's own chat lines, so they see their result twice (theirs and the broadcast).
6. **Spectators see the sidebar only while their arena has a live match** (WARMUP → ENDING); duelists from the lock-in to the release. Each viewer gets their own board, so like the siege board the shared tab-list team colours and the health-below-name objective aren't shown while viewing; the old board comes back when they stop.
7. **A spectator's boss bar follows the newest match on a battleground, else the newest live one** ("the most recent match").
8. **Spectating uses the arena's first spectator area with `TeleportEnabled`.** One without a warp gets "walk to …", and an arena without an area says so. The spectate button is disabled then.
9. **`[My claims]` calls `DuelService.claim` directly**, with its own message (stacks to inventory / ender chest / still owed), refused during a match.
10. **Observer failures are contained**: `DuelHud` and `DuelAnnouncer` catch their own `RuntimeException`s and `LinkageError`s. P4's `DuelService.notify` catches only `RuntimeException`, so an `Error` from an observer (found here: `Criteria.DUMMY` without a server, in a test) breaks the lock-in it was called from. Noted on KNG-217.

### Found in passing / left out

- `DuelService.notify` (P4) catches only `RuntimeException`: a `LinkageError` in any observer stops the step that notified it (a lock-in stays incomplete). Comment on KNG-217.
- No hub tile for `/duels` or `/arena`: the hub menu isn't in P6's scope. Comment on KNG-222 (P8 decides whether the guide asks for one).

### Live checks for P8

Setup: P1's `arena_2` with a lobby, an exit, enabled battlegrounds and a spectator area with `TeleportEnabled` (and, for check 8, a title requirement or gem price on that warp); P5's commands; two duelists and a third player.

1. **Seeds**: after the API restarts, `GET api/MenuTemplates/by-key/duel_matches` (and `duel_match_detail`, `arena_main`, `duel_challenge`) exist; the plugin's startup menu validation doesn't block them.
2. **Warmup broadcast**: when both duelists reach the lobby, everyone gets "⚔ Duel at arena_2: A vs B - own gear - stakes: …  [Spectate] [Details]". Hovering shows what each does. [Details] opens the match detail; [Spectate] starts the stands' warp.
3. **Spam cooldown**: the same duelists start another duel within 120 s → no second broadcast. After `duels.announce.cooldown-seconds` it is broadcast again.
4. **Toggles**: with `AnnounceFriendly` off, a duel without stakes isn't broadcast but a staked one is. With `AnnounceMatches` off nothing is broadcast; results go only to the duelists and the stands.
5. **Result**: "A defeated B in 1:42 and won 665 coins + 2 items." after the payout (the pot less the fee). A held result (P2's tier 2) says "(pending review)". A forfeit says "won by forfeit". A draw ("drew at arena_2 (agreed draw)") is broadcast. A staff `/knk duel cancel` reaches only the duelists and the stands. "B was defeated by A." reaches only the duelists and the stands.
6. **Sidebar and boss bar (duelists)**: from the accept on, a sidebar shows "Your duel: vs B", the stage and timer, gear and stakes, then the arena's other live duels and "Queue: 1/3 waiting", "Battlegrounds: 1/8 busy". The boss bar shows the warmup countdown, "Waiting for a free battleground (#2 in line)" when the arena is full, "Get ready: 7", the fight timer (or "no time limit"), then "A won!". Both go away at the exit and the normal board is back.
7. **Spectators**: in the stands during a live duel you get the arena's sidebar and the boss bar of the newest fight. Walking out removes both. A rank or premium change (which resets everyone's scoreboard) leaves the duel board alone.
8. **Spectating with conditions**: [Spectate] (chat, arena menu or the detail's "Go to the spectator area") runs the warp: a 5 s warmup, the gem price charged after it, the title/premium/discovery lock refused with its reason and nothing charged. The stands are also reachable on foot and by `/warp`.
9. **`/duels`**: two heads per live duel, refreshed every second, with "No duels right now" when empty. A head opens the detail: both cards (title, XP, playtime, duel W/L/D; PvP kills only if the player shows them, so hide them in the statistics settings and check), kits, coins, and the real stake items with their names and enchantments.
10. **`/arena`**: info, rules (gear modes, offers, stake limits, fee, ratio, pair limit, daily cap, timings), queue, live duels here, Spectate (disabled without a warp), Challenge a player (disabled outside the arena; a click from outside says "Stand inside the arena…"), My claims (highlighted when something waits; a click collects it). The challenge picker lists online players, those in a duel greyed out; a pick opens P5's proposal editor.

---

## P8 — guide, smoke-test checklist, merge plan ([KNG-222](https://linear.app/kngpandi/issue/KNG-222))

**Session:** Claude Code cloud session, 2026-10-21. **Status:** prepared; KNG-222 In Review, waiting for the developer's live test. Nothing merged, deployed or live-tested.

### Checks before starting

- KNG-209, 210, 213, 215, 217, 219, 220 and 221 are all **In Review** with commits on `claude/arena-duels` (checked in Linear and with `git log`). None missing.
- `git push --dry-run` on `claude/arena-duels` in all four repos: up to date, push allowed.
- **Trunks:** knk-web-api `master` is still `2d71155`, knk-web-app `main` still `e30c815`: already in the branches, nothing to merge. knk-workspace `main` had moved (tracker commits): merged into `claude/arena-duels` (`Merge origin/main into claude/arena-duels (arena duels P8)`). **knk-plugin: KNG-182 has not landed** (`main` is still `79be4882`; `claude/mc-26.2-upgrade` `88497649` is not in it), so `claude/mc-26.2-upgrade` stays the plugin base; it has no new commits either.

### Commits

| Repo | Branch | Commit | What |
|---|---|---|---|
| knk-plugin | `claude/arena-duels` | `0f6dd1ca` | `CLAUDE.md` "Structure" names `core/minigame/`, `minigame/`, `DomainAccessExemptions` and the duel packages (P0's docs leftover, comment on KNG-222). No code |
| knk-workspace | `main` | `a05f1b7` | tracker row |
| knk-workspace | `claude/arena-duels` | merge of `main`, then this commit | new [`guides/arena-duels.md`](../guides/arena-duels.md) and [`guides/arena-duels-smoke-test.md`](../guides/arena-duels-smoke-test.md); `FEATURE_REGISTER.md` row, `specs/README.md`, `guides/README.md`, `architecture/managed-worldguard-regions.md` (§5, §9), `architecture/domain-access-enforcement.md` (§3.1 exemptions, respawn row), teleport `DESIGN.md` (§3.4.5 `ARENA` / `ARENA_SYSTEM`, `beforeMove`); this section and the chain summary |

knk-web-api and knk-web-app: no P8 commits (no trunk change to merge).

### Tests (full build on every branch head)

| Repo | Head | Command | Result |
|---|---|---|---|
| knk-plugin | `d8897a79` (code; `0f6dd1ca` adds only `CLAUDE.md`) | `./gradlew build -x deployToDevServer`, Temurin JDK 25.0.4 toolchain, Gradle 8.14.3 on JDK 21 | **BUILD SUCCESSFUL: knk-core 2338, knk-api-client 275 (2 skipped), knk-paper 2013 (18 skipped), 0 failures.** Same as P6. The first run failed on Maven Central HTTP 429 (dependency download, not a test); the re-run used a session-local init script pointing at Google's Maven Central mirror (nothing committed) |
| knk-web-api | `7872831` | `dotnet build knkwebapi_v2.csproj`, `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` | **2873 passed, 4 failed, 73 skipped.** The 4 are the known reds: `PathResolutionServiceTests` ×2, `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`, `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`. Same as P6 |
| knk-web-app | `6afaa8b` | `npx -y npm@11 ci`, `npm run test:ci` | **160 suites / 965 tests, all green.** Same as P7 |

### Docs

- **Guide** [`guides/arena-duels.md`](../guides/arena-duels.md): admin setup (permissions, deploy and seeds, the arena form step by step, battlegrounds, the spectator area and its warp, turning it on, the hub-tile gap), reviews (signals, tiers, release/void/revert/confiscate, clear escalation), duel restrictions, the review policy, staff commands and files, a player how-to (challenge, answer, what happens at accept, results, watching, statistics), troubleshooting.
- **Smoke test** [`guides/arena-duels-smoke-test.md`](../guides/arena-duels-smoke-test.md): put next to the other smoke tests in `guides/` rather than in `reports/` (they are filled in during the test). Setup (deploy heads, migrations, seeds, grants, creating `arena_2` and its battlegrounds and spectator area in the forms, locations, region check), plan steps 1–15 with every phase live check sorted into its step and tagged (`P4·6` = P4's check 6), §S the P0 siege regression, §X the three checks that fit no step, and a findings table. All 6 + 5 + 9 + 12 + 13 + 15 + 15 + 10 phase checks (P3, P0, P1, P2, P7, P4, P5, P6) are in it.
- **Living docs** updated as listed in the commits table. The register row is `complete` / `branch` / `pending`.
- **CHANGELOG** entry prepared below; it is added at the merge, not now (only shipped work goes into a dated entry).

### Merge plan (after the developer's sign-off)

**Dependency:** the plugin branch is built on KNG-182 (`claude/mc-26.2-upgrade`, Minecraft 26.3 / Java 25). It can't merge into knk-plugin `main` before KNG-182 does: merging it would bring all of KNG-182 with it.

**Order:**
1. **knk-web-api** `claude/arena-duels` → `master` (merge commit, no squash; "merged directly, no PR" as for KNG-193, or a PR if the developer prefers). It is additive: two migrations (`AddArenas`, `AddDuelMatches`), new endpoints, create-only menu seeds. The current plugin on `main` doesn't call any of it, so it is safe on its own.
2. **knk-web-app** `claude/arena-duels` → `main`. Additive (arena forms' API clients, staff duel pages, alert rule codes). Needs the API from step 1.
3. **knk-plugin**: first **KNG-182** (`claude/mc-26.2-upgrade`) → `main`, by its own sign-off. Then merge the new `origin/main` into `claude/arena-duels`, re-run `./gradlew build -x deployToDevServer`, and merge `claude/arena-duels` → `main`. If KNG-182 has already landed by the sign-off, only the second part remains.
4. **knk-workspace** `claude/arena-duels` → `main`, after the last code merge: the docs, with the "on `claude/arena-duels`, not merged" notes in the guide, register, specs README, teleport DESIGN, managed-regions and domain-access docs changed to the trunk commits, the register row set to `trunk` and its verification to `live` (or `mixed` for unchecked steps), and the CHANGELOG entry added.

If KNG-182 is still waiting at sign-off: steps 1, 2 and 4 can go ahead; then the CHANGELOG entry waits for step 3 (players can't duel before the plugin ships), and the register says `mixed`.

Before each merge: fetch, check the trunk tip, merge the trunk into the branch again if it moved, re-run that repo's build and tests.

**Commits that merge** (all on `claude/arena-duels`; trunk-merge commits not listed):

| Repo | From base | Commits |
|---|---|---|
| knk-web-api | `master` `2d71155` | `1f65a12`, `05a9049`, `6507641`, `a8a26c3` (P1); `53f42cf`, `d208a74` (merge), `a0da408` (P2); `dc704f3` (P7); `7872831` (P6) |
| knk-web-app | `main` `e30c815` | `7fa594b` (P1); `6afaa8b` (P7) |
| knk-plugin | `claude/mc-26.2-upgrade` `88497649` (KNG-182) | `1f5ebdfa`, `36195de3` (P3); `e3814cef`, `d00826c5` (P0 + merge); `02bca4e0` (P1); `1e17f985`, `2be401b5` (P2); `d0332108` (P7); `01b5d6a0`, `0c175f03`, `6fe453b1`, `bccd338d`, `089bd357` (P4); `4cb1aa80`, `ea7ecb4e`, `d1016f42` (P5); `0d62c543`, `a6fdd17c`, `d8897a79` (P6); `0f6dd1ca` (P8 docs) |
| knk-workspace | `main` | the P0–P8 report sections, `managed-worldguard-regions.md`, the siege, currency and player-statistics DESIGN edits, and the P8 docs (see each section) |

**After the merge:** add the CHANGELOG entry; set KNG-209, 210, 213, 215, 217, 219, 220, 221 and 222 to Done; move the P0–P8 tracker rows to "Recently completed" with the trunk commits.

### CHANGELOG entry (draft, for the merge date)

```markdown
- **Arena duels: challenge a player, agree on stakes, fight on a battleground**
  ([KNG-197](https://linear.app/kngpandi/issue/KNG-197), phases KNG-209–KNG-222; knk-web-api `master` `<merge>`,
  knk-web-app `main` `<merge>`, knk-plugin `main` `<merge>`, merged directly, no PR).
  Inside an arena, `/duel <player>` opens an offer: gear mode (own gear and keep it, own gear where the loser's
  inventory goes to the winner, a fixed kit, or each player's choice of kit), and coins and items for each side.
  Players counter up to the arena's offer limit, then accept. Both stakes are taken at once and held until the
  result; the winner gets the pot less a 5% fee, and a draw or cancel gives everyone their own back. Both players
  teleport to the arena lobby for a warmup, then fight on a free battleground after a 10 s countdown: PvP works
  there even in a no-PvP town, nobody else can join in, and nobody can leave or teleport until the end. Every
  duel is announced with [Spectate] and [Details]; `/duels` lists live duels, `/arena` shows the arena, its queue
  and rules, and the stands are a normal warp. Duel wins, losses and draws are public by default.
  Staff set up arenas, battlegrounds, spectator areas, eligible kits and every duel setting in the web app; results
  that look thrown are flagged, and repeated ones held for review on the new Duels pages (release, void, revert,
  confiscate, stakes-only restrictions, review policy). Admin: migrations `AddArenas` and `AddDuelMatches`; create
  `arena_2` in the Arena form ([guide](guides/arena-duels.md)). Requires Minecraft 26.3 (KNG-182).
  Live-tested by the developer (<date>, [smoke test](guides/arena-duels-smoke-test.md)); <known limits>.
```

Known limits to name in it, unless fixed first: the stake ratio values items only in the API (KNG-224); no duel leaderboards yet; no hub tile.

### Open questions and leftovers (also in the chain summary)

- P6 asked P8 whether the guide should ask for a **hub tile**: the guide says there is none and how to add one (§2.6). It is a developer choice; no issue filed.
- P0's request that `domain-access-enforcement.md` mention the exemptions port, and that the plugin `CLAUDE.md` name the new packages: done.

### Live checks

The whole [smoke-test checklist](../guides/arena-duels-smoke-test.md). P8 adds none of its own.

---

## Chain summary (P0–P8)

**State on 2026-10-21:** every phase is pushed and In Review; P8 prepared the live test. Nothing is merged, deployed or live-tested. The developer runs the [smoke test](../guides/arena-duels-smoke-test.md) on the dev server (Minecraft 26.3, from the KNG-182 branch) and signs off; then P8 merges per the plan above.

### Commits per repo (branch `claude/arena-duels`)

| Repo | Base | Head | Phases |
|---|---|---|---|
| knk-web-api | `master` `2d71155` | `7872831` | P1, P2, P7, P6 (9 commits, one of them a merge) |
| knk-web-app | `main` `e30c815` | `6afaa8b` | P1, P7 (2 commits) |
| knk-plugin | `claude/mc-26.2-upgrade` `88497649` (KNG-182) | `0f6dd1ca` | P3, P0, P1, P2, P7, P4, P5, P6, P8 (20 commits, four of them merges) |
| knk-workspace | `main` | this commit | report sections, living docs, guide, checklist |

Per-commit detail: the merge plan's table above and each phase's section.

### Tests at the P8 heads

knk-plugin: core 2338, api-client 275 (2 skipped), paper 2013 (18 skipped), 0 failures. knk-web-api: 2873 passed, the 4 known reds, 73 skipped. knk-web-app: 160 suites / 965 tests green.

### Merge order

knk-web-api → knk-web-app → (KNG-182 into knk-plugin `main`, then `main` into the duel branch) knk-plugin → knk-workspace docs + CHANGELOG. Details in the P8 merge plan.

### Combined live checklist

[`guides/arena-duels-smoke-test.md`](../guides/arena-duels-smoke-test.md): setup, plan steps 1–15 with every phase's live checks, the siege regression (P0), and the extras.

### Developer decisions (KNG-197)

Taken during the chain, all recorded as comments on [KNG-197](https://linear.app/kngpandi/issue/KNG-197):

| Date | Decision | Where it lives |
|---|---|---|
| 2026-10-21 | **Item value in the stake ratio** = the item instance's `ItemBlueprint` base price (`BasePriceMin` × amount; no instance or blueprint = 0); the ratio compares coins + item value per side | P3 `36195de3`, P2 `a0da408`; the plugin can't value items yet, so the API's check at lock-in is binding ([KNG-224](https://linear.app/kngpandi/issue/KNG-224)) |
| 2026-10-21 | **Battlegrounds keep `entry allow` + `pvp allow`**; `knk-allow-entry deny` through the domain-access handler is the only entry guard | P1 `02bca4e0`; managed-regions §5 |
| 2026-10-21 | **No `arena_2` migration or seed**; staff create arenas in the forms | P1 `a8a26c3` (endpoint removed); checklist §0.2 |
| 2026-10-21 | **Deaths and quits by phase as built**: a death before the countdown cancels, a death in the countdown forfeits, both quitting on one tick cancels, a death plus the other's quit on one tick is decided by the death | P3 |
| 2026-10-21 | **Match review data is staff-only**: `reviewSignals`, `reviewDetails`, `reviewTier` only for `knk.admin.duel.review` or the plugin key; others see the plain review state and result. Announcements stay public with the arena toggles | **being applied by the P2 session on knk-web-api `claude/arena-duels`; not on the branch when P8 pushed** (P8 checked `origin/claude/arena-duels`: still `7872831`). Guide §3.1, checklist P2·10 |
| 2026-10-21 | **Confiscated coins go to a new `SYS_CONFISCATED` account**, not `SYS_FEES` | **same P2 follow-up, not on the branch yet.** Guide §3.2, checklist P2·7 / P7·8 |
| 2026-10-21 | **Duel W/L/D visibility as built**: a metric-level "Wins: Nobody" also hides duel wins; the player can re-show them per context | P7, no change |

The two P2 follow-ups change the API and its tests after P8's test run. **Before the merge, fetch knk-web-api `origin/claude/arena-duels` again and re-run the build and tests on the new head**, and use that head in the checklist's §0.1 table and the merge plan's commit list. If the commit hasn't landed when the merge step comes, say so; the coordinator handles it.

### Open questions for the developer

1. **Hub tile** (P6) for `/duels` or `/arena`: wanted? A small seed change. (P2's two questions and P7's are answered above.)

### Follow-ups filed or recorded

- [KNG-199](https://linear.app/kngpandi/issue/KNG-199): siege kit mode (reuses P0's vault and P4's kit loan; `KitGrantPlacer` overflow note there).
- [KNG-223](https://linear.app/kngpandi/issue/KNG-223): `dotnet build` at the knk-web-api root fails on Linux (lower-case `tests\` in the `.sln`). Filed by P7.
- [KNG-224](https://linear.app/kngpandi/issue/KNG-224): the plugin can't value staked items for the stake ratio (the API's check at lock-in is binding). Filed by P5.
- Comment on KNG-217: `DuelService.notify` catches only `RuntimeException`, so an `Error` from an observer stops the step that notified it (P6). Worth fixing before or soon after the merge.
- Comment on KNG-213: a staff ledger reversal of a duel's stake or payout outside the duel flow makes the duel's later cancel or revert answer 409 `AlreadyReversed`.
- Comment on KNG-221: the match detail shows ledger transaction ids as numbers (the transaction page is keyed by `publicId`).
- Comment on KNG-222: the hub tile (open question 4).

