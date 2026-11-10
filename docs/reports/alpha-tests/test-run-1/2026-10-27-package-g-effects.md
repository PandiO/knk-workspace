# Alpha test run 1 — package G: effects (2026-10-27)

**Status:** In review (round 2) — pushed on `claude/alpha-run-1-effects`: knk-plugin `9bc2b31` (round 1 `911eb2a`,
from `main` `3550cbb`); not merged, not deployed; round 1 smoke-tested on dev 2026-10-27, round 2 not live-tested
**Last updated:** 2026-10-27 (round 2 appended, § 5)
**Issues:** [PandiO/knk-workspace#169](https://github.com/PandiO/knk-workspace/issues/169),
[#170](https://github.com/PandiO/knk-workspace/issues/170) (both P2); parent [#149](https://github.com/PandiO/knk-workspace/issues/149)
**Handoff:** [2026-10-27-alpha-run-1-p2-p3.md](../../../ai-agents/handoffs/2026-10-27-alpha-run-1-p2-p3.md) § 1 ·
**Findings:** [test-run-1-findings.md](test-run-1-findings.md) (4.4, 4.6)

Claude Code (background subagent of the coordinator session) checked both issues against knk-plugin `main` `3550cbb`
and implemented them in knk-plugin only; knk-web-api and knk-web-app needed no change. Living docs:
[admin guide § 5](../../../guides/admin/custom-enchantment-combat-values-admin-guide.md) and the custom-enchantments row
of `FEATURE_REGISTER.md`.

## 1. What the code did, and what changed

| Issue | Found on the default branch | Change |
|---|---|---|
| #169 name tags during flash/chaos | `FlashChaosEffect` gives players in 5 blocks Slowness (100 ticks) and Nausea (250 ticks), nothing that hides names. `ChaosEffect` only damages and knocks back; it has no blinding debuff. Name tags are a team option (`NAME_TAG_VISIBILITY`); the shared rank board (`ScoreboardUtil`, teams `default`/`owner`/`staff`/`tier_<id>`) and the siege boards (`SiegeScoreboardPresenter`, one board per siege team, teams `siege_<id>`) both use teams, and a player can be in one team per board only. | **Per-viewer mirror board** (`enchantment/display/NameTagBlackout`). The flash_chaos victim is shown a private copy of the board they have (rank or siege team board): the same teams with colour, prefix, suffix, friendly-fire/invisibles/collision/death-message options and members, plus the objectives on display slots (sidebar lines with their custom names, below-name health), but every team's name tag set to `NEVER` and a catch-all team `knk_blackout` for online players on no team. Duration = the nausea (250 ticks). Nobody is re-teamed and nobody else's view changes. The copy is re-synced from the real board every second (the siege clock keeps ticking) and the real board comes back on the end, on death, quit and plugin disable. Overlapping flashes extend one blackout to the latest end (core `ViewerBlackoutLedger`). Board owners now set/read a player's board through `utils/ViewerScoreboards` (`ScoreboardUtil.setScoreboard`, `SiegeScoreboardPresenter.show/restore`): while a blackout runs, a board they set lands **behind** the copy and is what the player gets back, and the board they remember is the real one, not the copy. So a match start/end during a blackout ends with the right board. |
| #170 boss bars | No bar for any effect. `FrozenPlayerTracker` kept `frozenUntilMillis` but had no accessor; `AdminFreezeManager` (staff `/freeze`) has no duration and a freeze hook (#155). `NavigationHud` keeps its own Adventure bar per player. | `enchantment/display/EffectBossBars` (bookkeeping in core `TimedEffectBoard`): one Adventure boss bar per timed debuff, `<Effect> · 4s` (`m:ss` from a minute), progress = remaining / full, refreshed every 5 ticks. Sources: Poison, Wither, Freeze (`Frozen`), Blindness, Confusion (`Nausea`), and Flash Chaos's Slowness and Nausea on its victims. A potion bar reads the player's potion effect every refresh (milk ends it, a longer copy from elsewhere becomes the new full bar); the freeze bar reads the new `FrozenPlayerTracker.remainingMillis`. The same effect again restarts its bar. Staff `/freeze` shows a static full `Frozen` bar through the `AdminFreezeManager` hook (also on a join while still frozen). Timed bars go on death (the staff bar stays), every bar on quit and plugin disable. Own bars, so `NavigationHud`'s bar is untouched. Effects reach the display through `EffectDisplay`, set on every effect by `ExecutorImpl.setEffectDisplay`; durations still come from the #151/#156 combat values (unchanged). |

### Why a mirror board for #169

Options weighed (handoff § 1: victim's view only, siege and rank teams intact):

- **Re-team the victim's targets into a hidden team**: changes every viewer's view and breaks the one-team-per-board
  rule for the siege/rank teams. Rejected.
- **Per-viewer packets** (fake team packets, or `Player.hideEntity`): Paper has no API to send a team packet to one
  player without NMS/ProtocolLib (neither is a dependency), and `hideEntity` hides the whole player, not the tag — the
  victim could then not see or hit their attackers. Rejected.
- **Temporary per-viewer board that mirrors the current one** (chosen): plain Bukkit API, the victim's own team colours,
  sidebar and health stay, other players are unaffected, and the only shared change is routing the two board owners
  through `ViewerScoreboards` (identical behaviour without a blackout). Cost: one extra board per blinded player for
  12.5 s and a 1 s sync; a team or objective change on the real board reaches the copy within a second.

Edge cases covered: quit and death (board back, ledger cleared), overlapping flashes (one blackout, latest end), match
start or end during the blackout (board swap lands behind the copy), plugin disable (`showAll`, overlay cleared), a sync
error (blackout ends early, real board back, warning logged).

## 2. Tests

| Repo | Default branch `main` `3550cbb` | `claude/alpha-run-1-effects` `911eb2a` |
|---|---|---|
| knk-plugin `build -x deployToDevServer` (JDK 25 toolchain) | core 2378, api-client 282 (2 skipped), paper 2223 (18 skipped), 0 failures | core 2387, api-client 282 (2 skipped), paper 2238 (18 skipped), 0 failures; build green |

New tests: `TimedEffectBoardTest`, `ViewerBlackoutLedgerTest` (core); `NameTagBlackoutTest` (with small in-memory
scoreboard fakes: mirror contents, real board untouched, overlap/expiry, death/quit, siege board swap during a blackout
and the sidebar following it, disable), `EffectBossBarsTest` (one bar per effect, countdown, restart, milk/early
unfreeze, run-out, staff freeze vs. death/quit, longer copy, creatures, disable) in paper; `EnchantmentBootstrapTest`
extended. Nothing was run against a server or client.

Build environment note: this container could not reach `services.gradle.org`, Maven Central or the Gradle plugin portal,
so the build ran with a local Gradle 8.14.3 (the wrapper's version) and a throw-away init script (not committed) that
resolves everything through `repo.papermc.io/repository/maven-public`. The project's build files are unchanged.

## 3. Live checklist (test run 2)

1. Flash Chaos near another player (survival, outside a safezone): the victim gets Slowness and Nausea bars counting
   down, and no name tags of anyone for ~12.5 s; the user and bystanders still see all name tags. Afterwards the
   victim's tags, tab colours and below-name health are as before.
2. Same in a siege match: the victim keeps the siege sidebar (timer ticking, objectives) and team colours during the
   blackout; afterwards the siege board is back (not the rank board). Let a match end during a blackout: the rank board
   comes back.
3. Second Flash Chaos on the same victim mid-blackout: the blackout lasts until the second one ends. Victim dies or
   logs out during the blackout: tags back on respawn/rejoin.
4. Poison/Wither/Freeze/Blindness/Confusion hits: one bar each with name and seconds; the same effect again restarts its
   bar; milk removes potion bars; death removes all timed bars.
5. Staff `/freeze <player>`: static `Frozen` bar until `/unfreeze`; still there after a relog while frozen. Combined with
   a navigation route: both bars visible.

## 4. Flags for the developer

- **Chaos (plain)** has no blinding effect today, so only **Flash Chaos** hides name tags. If plain Chaos should too,
  say so (one line in `ChaosEffect`, with a duration to choose).
- Flash Chaos's own Slowness (5 s) and Nausea (12.5 s) are hard-coded (`FlashChaosEffect.SLOWNESS_TICKS`/`NAUSEA_TICKS`),
  not part of the #151 combat values (its tuning row has no duration). The blackout follows the nausea. Noted on #169.
- Package F ([#163](https://github.com/PandiO/knk-workspace/issues/163)) reworks the siege/default boards: it must keep
  setting and reading player boards through `ViewerScoreboards` (not `Player.setScoreboard` directly), or a board change
  during a blackout is lost. Noted on #163.
- Package E had not pushed `claude/alpha-run-1-rewards` when this branch was finished, so no merge check against it.
  This branch touches `KnKPlugin.java` (freeze hook, enchantment init, `onDisable`), `ScoreboardUtil` and
  `SiegeScoreboardPresenter`.

## 5. Round 2 (2026-10-27)

After the developer's smoke test run 1 on dev (2026-10-27: blackout, overlap, death/relog, siege variant and the effect
bars accepted), the developer asked for three changes, posted on #169 and #170. Implemented on the same branch:
knk-plugin `911eb2a` → `9bc2b31`. Sections 1–4 above describe round 1 and are kept as they were.

### 5.1 What changed

| Ask | Change |
|---|---|
| #169: hide name tags only when an ability applies **blindness**, in the victim's view, for the blindness duration; remove it from Flash Chaos | `BlindnessEffect` now calls `display().hideNameTags(target, duration)` with its combat-value duration; `FlashChaosEffect` no longer does (its Slowness/Nausea and their bars stay). Same mechanism as round 1 (`NameTagBlackout` mirror board, `ViewerBlackoutLedger`, `ViewerScoreboards`); overlapping hits extend one blackout. New: the blackout also ends as soon as the victim has no Blindness any more (milk), checked on the 1 s tick (`NameTagBlackout.hide(viewer, ticks, stillApplies)`). |
| #169: while **invisibility** is granted, the invoker's own name tag is hidden from others | See 5.2. `InvisibilityEffect` calls `display().invisible(player, duration)` → `EffectBossBars` → new `InvisibleNameTag`; the shared rank teams are registered with "see friendly invisibles" off (`ScoreboardUtil.setTeams`/`teamFor`). |
| #170: staff `/freeze` bar is **red** and reads `Frozen by <player> for: <reason>` | `EffectBossBars.staffFreezeLabel(frozenBy, reason)`; bar colour and text red for the staff freeze only (the enchantment freeze stays blue/aqua). `AdminFreezeManager` records who froze in memory (`freeze(uuid, reason, frozenBy)`, `frozenBy(uuid)`, `rememberFreezer` for an offline target); `UserAdminService.setFrozen` passes the staff member's name (`freezerName`). The freeze hook in `KnKPlugin` builds the label. No API change. |

### 5.2 Invisible player's name tag: what vanilla does and the approach

**Vanilla.** The client doesn't draw an invisible player's name tag (nor their body), except for a spectator and for a
viewer on the **same team of the viewer's own scoreboard** when that team has "can see friendly invisibles" on — then
the viewer sees a see-through body *and* the name tag. A newly registered Bukkit team has that option **on**.

- **Shared rank board** (`ScoreboardUtil`): every player is on one of `default`, `owner`, `staff`, `tier_<id>` and none
  of them turned the option off. So before round 2, an invisible player's name tag (and ghost body) was visible to
  everyone of the same rank — usually most of the server, since ordinary players share `default`. That is the leak the
  developer saw.
- **Siege boards** (`SiegeScoreboardPresenter`): on the board of team X, only team X has the option on. So an invisible
  player is seen (ghost body + tag) by their own siege team and fully hidden from every other team.

**Choice.** Rank teams are colour groups, not allies, so the option is now **off** on every rank team of the shared
board: registered that way in `setTeams`/`teamFor`, and `InvisibleNameTag` also switches it off on the invoker's team of
the shared board when the ability fires (covers a team registered elsewhere, e.g. package F's `<team>.siege` twins on
`claude/alpha-run-1-results`). Vanilla then hides the tag for exactly as long as the invisibility lasts and shows it
again when it ends — also on milk, death, quit or plugin disable, without any state of ours to undo.
**Siege teammates still see their invisible teammate** (developer flag below): that is the siege board's deliberate
team-awareness, and hiding the tag from teammates only would need the tag hidden while the ghost body stays, which the
team options can't express without moving the invoker to another team (breaking one-team-per-board).

**Not done, on purpose:** no re-teaming, no temporary `NAME_TAG_VISIBILITY` change on a shared team (it would hide the
tags of every other member of that team for everyone), no board swaps, no packets. `ViewerScoreboards` is unchanged
(its `set`/`current` are untouched, as package F's merge needs).

Side effect: same-rank players also no longer see the see-through body of *any* invisible player (potions included).

### 5.3 Tests

| Repo | Round 1 `911eb2a` | Round 2 `9bc2b31` |
|---|---|---|
| knk-plugin `build -x deployToDevServer` (JDK 25 toolchain, local Gradle 8.14.3 + throw-away mirror init script, build files unchanged) | core 2387, api-client 282 (2 skipped), paper 2238 (18 skipped), 0 failures | core 2387, api-client 282 (2 skipped), paper 2253 (18 skipped), 0 failures; build green |

New/extended in paper: `InvisibleNameTagTest` (only the invoker's shared-board team changes, nobody moves, no board
set; missing team/board harmless), `AdminFreezeManagerFreezerTest` (freezer known to the hook, unfreeze/console clears
it, kept through a quit, offline remember/forget), `NameTagBlackoutTest` (blackout ends when the blindness is gone; an
overlap with/without the check), `EffectBossBarsTest` (red `Frozen by Admin for: griefing`, `staff` fallback, no reason,
long reason cut, invisibility forwarded for players only; round-1 assertions updated from `Frozen` to
`Frozen by staff`), `OfflineFreezeAndModeTest` (freezer kept on relog with the same freeze, dropped for another one),
`UserAdminServiceTest` (online/offline freezer recorded, console unknown, vanished staff not named). Nothing was run
against a server or client.

### 5.4 Flags for the developer

- **Siege teammates still see an invisible teammate** (ghost body and name tag); only other teams don't. Say if
  teammates should not see the tag either (that needs a different trade-off; see 5.2).
- **Rank teams no longer show invisible same-rank players** at all (no ghost body either), for every invisibility
  source, not only the ability.
- **Freezer `staff`** when unknown: console, a **vanished** freezer (so the bar doesn't reveal them), a web-app freeze,
  or a freeze from before a server restart (only the reason is persisted). A relog on the same server run keeps the
  name. The API stores `FrozenByUserId` but no DTO returns it; exposing it would make the name survive a restart (small
  API/DTO change, not done).
- **No reason**: the bar reads `Frozen by <staff>` (no ` for:`). `/freeze` always requires a reason; the Player manager
  uses `Frozen by a member of staff`, so that freeze reads `Frozen by Admin for: Frozen by a member of staff`. Reasons
  over 60 characters are cut with `…`.
- A blackout from blindness now also ends when the blindness is cured (milk), which round 1 didn't do for Flash Chaos.
- Merge overlap: `ScoreboardUtil` is also changed by package F (`claude/alpha-run-1-results`, siege tag twins) in a
  different hunk; `UserAdminService` by `claude/alpha-run-1-teleport-items` in other methods; `KnKPlugin` by several
  packages.

### 5.5 Live checklist (re-test)

1. Blindness hit on another player: the victim sees no name tags for the blindness duration and has a `Blindness` bar;
   attacker and bystanders still see all tags. Tags return when it ends; milk brings them back at once.
2. A second blindness mid-blackout extends it; death or relog during it brings tags back. In a siege match the sidebar
   keeps ticking during it and the siege board is back afterwards.
3. Flash Chaos: Slowness and Nausea bars, **no** name-tag hiding.
4. Invisibility ability: no other player (same rank or not) sees the user's name tag while invisible; it is back when it
   ends, after milk and after death. In a siege match, teammates still see the user (see-through), the other team not.
5. Staff `/freeze <player> <reason>`: red `Frozen by <you> for: <reason>`; from the console `Frozen by staff for: …`;
   still the same after a relog; after a server restart while frozen `Frozen by staff for: …`. `/unfreeze` removes it.

