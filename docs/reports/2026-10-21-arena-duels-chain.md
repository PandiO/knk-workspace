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
| knk-workspace | `main` | `0f87b4c` | tracker row |
| knk-workspace | `claude/arena-duels` (created by this session from `main`) | this report | this section |

### Tests

- Toolchain: OpenJDK 25.0.4 (KNG-182 toolchain), Gradle 8.14.3, Paper API `26.3.build.205-stable`.
- Baseline before the change: knk-core 2168 tests, 0 failures.
- New: 114 tests in `core/duel`, all green (offer book 22, validator 12, state machine 48, combat rules 15, queue/allocator 9, escrow 7, Bukkit-free guard 1).
- Full `./gradlew build -x deployToDevServer`: BUILD SUCCESSFUL — knk-core 2282 (2168 + 114), knk-api-client 264 (2 skipped), knk-paper 1870 (18 skipped), 0 failures, no known reds. (A first run failed only on a transient Maven Central HTTP 429 while downloading gson; the re-run was green.)

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
| `StakeViolation` | `(code, side, detail)`; codes `GEAR_MODE_NOT_ALLOWED`, `FIXED_KIT_MISSING`, `FIXED_KIT_NOT_ELIGIBLE`, `KIT_NOT_EXPECTED`, `NO_ELIGIBLE_KITS`, `COINS_NOT_ALLOWED`, `ITEMS_NOT_ALLOWED`, `NEGATIVE_COINS`, `COINS_OVER_MAX`, `STAKE_RATIO` (detail = minimum), `TOO_MANY_STACKS`, `ITEM_BLOCKED` (detail = material), `DUPLICATE_ITEM`, `ITEM_ADDED_BY_OTHER_SIDE` |
| `DuelEndReason` | `WIN`, `FORFEIT`, `TIME_LIMIT`, `AGREED_DRAW`, `SIMULTANEOUS_DEATH`, `TELEPORT_FAILED`, `PLAYER_LEFT_LOBBY`, `NO_BATTLEGROUND`, `ADMIN_CANCELLED`, `SERVER_RESTART`, `API_OUTAGE`, `LOCK_REFUSED`; `status()` (COMPLETED / CANCELLED / ABORTED / NOT_CREATED), `isDecisive()`, `isDraw()`, `apiName()` (PascalCase for P2's API, null for `LOCK_REFUSED`) |
| `DuelResult` | `(reason, winner)`; `win(side, reason)`, `noWinner(reason)`, `loser()`, `isDecisive()` |
| `DuelPhase` | `LOCKING`, `TRAVELLING`, `WARMUP`, `BATTLE_COUNTDOWN`, `FIGHT`, `ENDING`, `CLOSED`; `isParticipating()` (LOCKING..ENDING: combat rule, teleport restriction, guards, held deliveries), `quitForfeits()`, `onBattleground()`, `countsAsQueued()` |

**`StakeContractValidator`** (static)
- `validate(contract, settings, blockedPredicate)` → `List<StakeViolation>`
- `validateItemOwnership(previous, next, author)`; `validateOffer(previous, next, author, settings, blocked)` = both
- `minimumMatchingStake(larger, ratioPercent)` (for the editor's hint)
- Not here (P4 / the API): item presence (`isSimilar` + amount), eligibility (D14), pair/daily limits, holds and restrictions.

**`DuelOfferBook`** (one per server)
- `new DuelOfferBook(maxIncoming, sendCooldownSeconds, Predicate<StakeItem> blocked)`; constants `DEFAULT_MAX_INCOMING = 3`, `DEFAULT_SEND_COOLDOWN_SECONDS = 10`
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

1. **Stake ratio with items.** DESIGN §10.2 says "I stake 10,000, you stake 0" is impossible, while §6.2's example "I stake my diamond sword, you stake 500 coins" must be expressible. The validator refuses a coin stake below `MinStakeRatioPercent` of the other side's **unless the side with fewer coins stakes items** (its collateral). P2's API applies its own ratio check at lock-in; it should use the same rule or the plugin's advisory check and the API will disagree.
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

- Deviation 1 (ratio with item collateral) should be confirmed by the developer and mirrored in P2's API check.
