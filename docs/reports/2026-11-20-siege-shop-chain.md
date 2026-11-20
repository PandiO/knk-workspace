# Siege shop chain — progress report

**Status:** Running (2026-11-20) · **Last updated:** 2026-11-20

**Issue:** [PandiO/knk-workspace#611](https://github.com/PandiO/knk-workspace/issues/611) (with
[#356](https://github.com/PandiO/knk-workspace/issues/356) and [#859](https://github.com/PandiO/knk-workspace/issues/859)),
links [#866](https://github.com/PandiO/knk-workspace/issues/866) (L1), [#867](https://github.com/PandiO/knk-workspace/issues/867) (L2),
[#868](https://github.com/PandiO/knk-workspace/issues/868) (L3), [#869](https://github.com/PandiO/knk-workspace/issues/869) (L4),
[#870](https://github.com/PandiO/knk-workspace/issues/870) (L5), [#871](https://github.com/PandiO/knk-workspace/issues/871) (L6).
**Charter:** [handoffs/SIEGE_SHOP_CHAIN.md](../ai-agents/handoffs/SIEGE_SHOP_CHAIN.md).
**Coordinator:** the Siege weapons chain coordinator (session_01R1w2UuyXat2GBcJjHG3RRV) runs this chain too, on the
developer's instruction of 2026-11-20; its own report is [2026-11-19-siege-weapons-chain.md](2026-11-19-siege-weapons-chain.md).

## 1. Waiting for the developer

1. Nothing for this chain yet. (Siege weapons L3 #784 also needs #614, the schematic pipeline, which has no design;
   see the weapons report § 1.)

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Shared ledger, siege points earning | #866 | Running | `claude/siege-shop-l1`: (not pushed yet) | — | — | subagent of the coordinator (two component repos), started 2026-11-20 |
| L2 Shop catalogue (API, web app) | #867 | Not started (gate: L1 merged, shares knk-web-api) | — | — | — | — |
| L3 Shop in the plugin | #868 | Not started (gate: L1, L2 merged) | — | — | — | — |
| L4 Weapon unlocks | #869 | Not started (gate: L2, L3, L5 merged) | — | — | — | — |
| L5 Menu item settings (API, web app) | #870 | Not started (gate: L2 merged) | — | — | — | — |
| L6 Menu item in the plugin | #871 | Not started (gate: L3, L5 merged) | — | — | — | — |

## 3. Coordinator decisions

1. **Who coordinates.** Chosen: the Siege weapons coordinator runs this chain from the same session, because the
   developer said on 2026-11-20 "The design for #611 and #356 is finished. You can start implementation of the
   relevant phases ... plan the implementation phases ... and start if you consider ready", no shop coordinator
   exists (board and branches checked 2026-11-20), and the weapons chain waits for this one. The charter's phases
   and links are used as written. Alternatives: (a) a separate coordinator session through the manager, slower and
   the developer asked this session; (b) fold the shop links into the weapons charter, rejected (two parents, two
   smoke guides).
2. **Rule set.** Chosen: the `next` branch model (CI on `main` of knk-web-api and knk-web-app, unchanged since
   2026-11-19). Bases on 2026-11-20: API `next` see the first commit of this report, plugin and web app likewise.
   Alternatives: none (the old rules apply only without CI).
3. **Link model.** Chosen: the coordinator's model for every link, set explicitly. Alternatives: a smaller model for
   tier:2 links, rejected for consistency.
4. **Route.** Chosen: subagents of the coordinator for every multi-repo link (L1, L2, L4, L5) per skill § 4.1.4.2;
   L3 and L6 (plugin only) may go `create_session`, decided when they start. Alternatives: `create_session` with
   `add_repo` for all, refused once by the Auto-mode classifier (#511).
5. **Order.** Chosen: L1 now; L2 after L1 (both change knk-web-api, one link per component repo); then L3 (plugin) and
   L5 (API, web app) together; then L4; then L6. The spec allows L2, L4 and L5 in parallel with L1, but they share
   knk-web-api with L1, and two migrations in flight in one chain would only add regenerations. Alternatives:
   (a) L5 in parallel with L1, rejected (both carry an API migration); (b) L2 first, rejected (charter order, and L1
   is the critical path for weapons L3).
6. **Overlap at L1 start (board fetched 2026-11-20).** Production (#22) runs L12 #679 on knk-plugin
   (`production` packages, `/knk production`, own `KnKPlugin`/`config.yml` blocks) and L14 #79 on knk-web-api (one
   migration). Chosen: not a blocker (different packages and entities); L1 keeps its `KnKPlugin`, `config.yml` and
   `KnKDbContext` edits in their own blocks, merges `origin/next` before the PR and generates its migration last
   (whoever merges second regenerates); the Production coordinator is told. Siege Survival (#41) is unmerged with no
   link running: L1 copies `MatchLedger` with the same public API (P11) and comments on #41 at merge. Alternatives:
   wait for Production's links, rejected (mechanical conflicts only).

## 4. Link blocks

_(Each link appends its block here when it finishes.)_
