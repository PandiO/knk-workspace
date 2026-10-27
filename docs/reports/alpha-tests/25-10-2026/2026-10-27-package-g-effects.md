# Alpha test run 1 — package G: effects (2026-10-27)

**Status:** In review — pushed on `claude/alpha-run-1-effects`: knk-plugin `911eb2a` (from `main` `3550cbb`);
not merged, not deployed, not live-tested
**Last updated:** 2026-10-27
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
