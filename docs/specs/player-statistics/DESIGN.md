# Player statistics — working design

**Status:** Draft decisions only; not an implementation plan. KNG-34 remains in Backlog and is sequenced after KNG-33.
**Last updated:** 2026-09-29
**Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34/design-player-statistics-provenance-and-world-analytics), [KNG-14](https://linear.app/kngpandi/issue/KNG-14/gameplay-statistics-counters-v2-userstatistics-for-user-statistics)

This living note records decisions from the developer conversation. It does not assert that all described fields are already stored or displayed in V3. Source-grounded design, V1/V2 comparison, architecture, acceptance criteria and implementation phases are still to come. KNG-33's feature register should be reconciled before the full design.

## Agreed player-facing direction

1. Design the statistics players can view first. Reuse their underlying data for later debugging, testing, balancing and world analytics where appropriate; staff access and retention may differ from player presentation.
2. Visibility is decided **per data item**, not through one private/public switch for the entire profile. Username, current title, coins, gems, experience, first server join, active playtime and AFK time are public to other players and cannot be hidden through the optional-statistic controls. Other statistics default to **private** and a player may choose **nobody, friends, or everyone** for each configurable item. The friends choice depends on KNG-35's relationship design; until that relationship can be verified, it must not reveal data to anyone.
3. Display **First joined the server** as the earliest recorded Minecraft server-join timestamp. On account linking or merging, use the oldest first-join timestamp among the involved Minecraft identities. A web account's creation timestamp alone does not count. An account that has never joined has no first-join value. Whether historical records permit a complete backfill needs verification.
4. Maintain two non-overlapping duration counters, both public: **active playtime** and **AFK time**. Their sum is total online time. AFK duration is not included in active playtime.
5. **Provisional AFK rule:** after five minutes without meaningful activity, classify the player as AFK. The exact activity signals, whether the initial five idle minutes are assigned retroactively to AFK, behavior on disconnect and crash, and anti-idle abuse rules remain open. Do not treat five minutes as the final contract for an AFK feature.

## Player settings and account identity

**Agreed:** persist statistics and visibility settings against the canonical player/User identity from the first Minecraft join, independently of whether web login exists. Linking a web account grants access to that existing history, not a new set of counters. The web account is optional and can offer richer profile charts, sharing and settings; aggregated analytics should not depend on web-account adoption. Account merges must reconcile source histories and overlapping sessions explicitly rather than blindly summing counters; keep the earliest Minecraft join as decided above.

**Agreed primary settings surface:** a player-accessible **Minecraft InventoryMenu** for visibility choices, including Minecraft-only players. V1 had an AFK/settings-style menu with little working functionality; inspect its actual behavior before porting. The V3 plugin already has a `MenuFeature` registry, `profile.main` content provider and registered menu actions/conditions, so design this as a feature-specific menu/action backed by the same server-side User preferences used by the optional web settings page. The backend must enforce visibility on every read surface; hiding a menu item alone is insufficient. Exact menu navigation, API contract, settings persistence and concurrency behavior still need design. A friends-only setting must fail closed until KNG-35 can resolve friends reliably.

## AFK feature dependency

V1 had a dedicated AFK mode that the developer wants to reimplement. Its V1/V2 behavior has **not yet been analyzed** and there is no separate AFK feature plan. Before implementing the classification or counters, inspect the legacy code and decide how explicit AFK mode, automatic inactivity detection and manual return to activity interact. The five-minute rule above is a temporary statistics-design default and may change to follow that feature.

## Combat and activity breakdown

**Agreed:** kills and deaths must be inspectable by game context/minigame, not just as one undifferentiated counter. Siege, future Arena and Dungeons should each have their own breakdown; the model must permit new modes without adding a hard-coded column for every one. A lifetime overall total may be derived from mutually exclusive context buckets, with explicit labels for ordinary world activity. Record the context when an event happens (including match identity where relevant) so an event is counted once even if the player moves or an area overlaps a minigame. Siege match history is an existing source for its own match statistics; reconcile it rather than writing a second independent Siege kill count. Exact PvP/PvE/environmental-death semantics and whether creature kills belong in the same total remain undecided. The default private/friends/everyone setting should apply to each configurable statistic; finer per-mode visibility is still an open UI decision.

## Time periods

**Agreed:** chosen player-facing counters should have lifetime, daily, weekly and monthly views, including per-game-context breakdowns where applicable. Weekly and monthly views should use clear calendar periods, with exact timezone and week start decided in the technical design. These views should derive from the same recorded facts or consistently reconciled aggregates so their definitions cannot drift. A session spanning period boundaries must allocate playtime and AFK duration correctly. Define late-event correction, aggregation/retention and whether lifetime totals include pre-instrumentation history later. V2's `UserStatisticsDaily` is evidence for the requirement, not an implementation to copy without checking its persistence behavior.

**Potential extension, not yet specified:** weekly/monthly leaderboards could reward activity and give players reasons to return. Decide which metrics are suitable, visibility eligibility, tie rules, period reset, rewards (if any), anti-farming safeguards and whether a player who hides a statistic may appear on its leaderboard. Do not assume every private statistic is rankable or public.

## Candidate player-facing groups — not yet approved field by field

- Activity: active playtime, AFK time, first server join and possibly active days.
- Progression: current title/XP and promotion history.
- Economy: current balances and earned/spent summaries derived from the existing currency/XP ledger, without duplicating that ledger.
- Combat: selected lifetime and periodic counters from V2 `UserStatistics`/`UserStatisticsDaily` (KNG-14).
- Siege: per-match history and aggregates from `SiegeMatchParticipant`.
- Exploration: discoveries and, if selected, distance traveled.

For each candidate, decide its exact definition, source, period, visibility, aggregation and backfill. Then design operational events, sampling and retention separately. The existing `/user statistics` command (KNG-9) and currency ledger (KNG-21) are inputs, not a complete statistics system.
