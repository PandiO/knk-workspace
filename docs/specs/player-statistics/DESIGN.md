# Player statistics — working design

**Status:** Draft decisions only; not an implementation plan. KNG-34 remains in Backlog and is sequenced after KNG-33.
**Last updated:** 2026-09-29
**Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34/design-player-statistics-provenance-and-world-analytics), [KNG-14](https://linear.app/kngpandi/issue/KNG-14/gameplay-statistics-counters-v2-userstatistics-for-user-statistics)

This living note records decisions from the developer conversation. It does not assert that all described fields are already stored or displayed in V3. Source-grounded design, V1/V2 comparison, architecture, acceptance criteria and implementation phases are still to come. KNG-33's feature register should be reconciled before the full design.

## Agreed player-facing direction

1. Design the statistics players can view first. Reuse their underlying data for later debugging, testing, balancing and world analytics where appropriate; staff access and retention may differ from player presentation.
2. Visibility is decided **per data item**, not through one private/public switch for the entire profile. Username, current title, coins, gems and experience are intended to be public to other players.
3. Display **First joined the server** as the earliest recorded Minecraft server-join timestamp. On account linking or merging, use the oldest first-join timestamp among the involved Minecraft identities. A web account's creation timestamp alone does not count. An account that has never joined has no first-join value. Whether historical records permit a complete backfill needs verification.
4. Maintain two non-overlapping duration counters, both public: **active playtime** and **AFK time**. Their sum is total online time. AFK duration is not included in active playtime.
5. **Provisional AFK rule:** after five minutes without meaningful activity, classify the player as AFK. The exact activity signals, whether the initial five idle minutes are assigned retroactively to AFK, behavior on disconnect and crash, and anti-idle abuse rules remain open. Do not treat five minutes as the final contract for an AFK feature.

## AFK feature dependency

V1 had a dedicated AFK mode that the developer wants to reimplement. Its V1/V2 behavior has **not yet been analyzed** and there is no separate AFK feature plan. Before implementing the classification or counters, inspect the legacy code and decide how explicit AFK mode, automatic inactivity detection and manual return to activity interact. The five-minute rule above is a temporary statistics-design default and may change to follow that feature.

## Candidate player-facing groups — not yet approved field by field

- Activity: active playtime, AFK time, first server join and possibly active days.
- Progression: current title/XP and promotion history.
- Economy: current balances and earned/spent summaries derived from the existing currency/XP ledger, without duplicating that ledger.
- Combat: selected lifetime and periodic counters from V2 `UserStatistics`/`UserStatisticsDaily` (KNG-14).
- Siege: per-match history and aggregates from `SiegeMatchParticipant`.
- Exploration: discoveries and, if selected, distance traveled.

For each candidate, decide its exact definition, source, period, visibility, aggregation and backfill. Then design operational events, sampling and retention separately. The existing `/user statistics` command (KNG-9) and currency ledger (KNG-21) are inputs, not a complete statistics system.
