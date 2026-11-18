# Navigation destination engine chain — progress report

**Status:** Running (2026-11-18) · **Last updated:** 2026-11-18

**Issue:** [PandiO/knk-workspace#25](https://github.com/PandiO/knk-workspace/issues/25), links
[#96](https://github.com/PandiO/knk-workspace/issues/96) (L1),
[#103](https://github.com/PandiO/knk-workspace/issues/103) (L2),
[#69](https://github.com/PandiO/knk-workspace/issues/69) (L3),
[#62](https://github.com/PandiO/knk-workspace/issues/62) (L4),
[#747](https://github.com/PandiO/knk-workspace/issues/747) (L5),
[#55](https://github.com/PandiO/knk-workspace/issues/55) (L6).
**Charter:** [handoffs/DESTINATION_ENGINE_CHAIN.md](../ai-agents/handoffs/DESTINATION_ENGINE_CHAIN.md).
**Coordinator:** session_01R1w2UvZSm3y5hAXB8VfYuv (cloud).

## 1. Waiting for the developer

1. Nothing yet. Later: the live test of smoke § 3 and § 4 with `navigation.destination-engine: true` once L3 and L4
   are in `next` (gate of L5), and the timing of L6 (arena duels, asked on #25 before it starts).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 P1 pure engine in knk-core | #96 | Running | `claude/navigation-destination-engine`: knk-plugin `ea368a8b` (start) | — | — | create_session session_01R1w2Uw3gPf2REJMYZEGE6a |
| L2 P2 model, snapshot, domain search Location | #103 | Not started | — | — | — | — |
| L3 P3 switch-over behind the flag | #69 | Not started | — | — | — | — |
| L4 P4 hard blocks as scopes, live re-validation | #62 | Not started | — | — | — | — |
| L5 phase 4b removal of old paths and the flag | #747 | Not started | — | — | — | — |
| L6 P5 arena duels provider and scope | #55 | Not started | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from or merge in `next`, PRs target `next`, the
   coordinator merges into `next`), because `.github/workflows/ci.yml` is on `origin/main` of both knk-web-api and
   knk-web-app (checked 2026-11-18). Alternatives: (a) old rules (developer merges) — not applicable once CI runs.
2. **Gate of L1.** Open: DESIGN on knk-workspace `next` has status "Decided 2026-11-18"; knk-plugin
   `claude/navigation-destination-engine` is at `ea368a8b` as the charter says (1 commit ahead of `next` `7f4bdd3a`,
   369 behind). Alternatives: none.
3. **Overlap check before L1 (charter § 2.2, § 2.3).** Board read fresh from `origin/main` 2026-11-18. Chosen: start
   L1 now. The off-road chain (#698) has no link running (its row: "Waiting for the developer", L8 waits for #96, #103,
   #69), and L1 only changes knk-core destination-engine code. The overview map chain (#732) has L3/L4 running in
   knk-plugin map reporting, not navigation; no shared lines. The NPC navigation follow-ups chain (#358) is in review
   with no link running. Order agreed by message with the off-road coordinator (session_01R1w2UuBBnWjqekMFxEMefN).
   Alternatives: (a) wait for the off-road live tests — not needed, no off-road link runs; (b) run L1 as a subagent —
   not needed, L1 needs only knk-plugin besides knk-workspace.
4. **Route for L1.** Chosen: create_session with variant A of the permissions block, because L1 needs one repository
   besides knk-workspace (SKILL § 4.1.4 item 2). Alternatives: (a) subagent (variant B) — the fallback if `add_repo` is
   refused.
5. **Parallel L2 API part.** Chosen: not yet; L2 starts as one link (API and plugin) after L1 is merged, because
   knk-web-api work is small (a DTO field and an `Include`) and one link per issue keeps the check simple.
   Alternatives: (a) start the knk-web-api part now as a separate session, which the charter allows — revisit if L1
   runs long.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_
