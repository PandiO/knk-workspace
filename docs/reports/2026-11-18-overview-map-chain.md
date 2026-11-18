# Overview map chain — progress report

**Status:** Running (2026-11-18) · **Last updated:** 2026-11-18

**Issue:** [PandiO/knk-workspace#732](https://github.com/PandiO/knk-workspace/issues/732), links
[#735](https://github.com/PandiO/knk-workspace/issues/735) (L1), [#736](https://github.com/PandiO/knk-workspace/issues/736) (L2),
[#737](https://github.com/PandiO/knk-workspace/issues/737) (L3), [#738](https://github.com/PandiO/knk-workspace/issues/738) (L4),
[#739](https://github.com/PandiO/knk-workspace/issues/739) (L5), [#740](https://github.com/PandiO/knk-workspace/issues/740) (L6),
[#741](https://github.com/PandiO/knk-workspace/issues/741) (L7), [#742](https://github.com/PandiO/knk-workspace/issues/742) (L8),
[#743](https://github.com/PandiO/knk-workspace/issues/743) (L9)
**Charter:** [handoffs/OVERVIEW_MAP_CHAIN.md](../ai-agents/handoffs/OVERVIEW_MAP_CHAIN.md).
**Spec:** [specs/in-game-maps/OVERVIEW_MAP_DESIGN.md](https://github.com/PandiO/knk-workspace/blob/next/docs/specs/in-game-maps/OVERVIEW_MAP_DESIGN.md)
on `next` (Decided 2026-11-18, O01–O33, O08 superseded by O31); smoke guide
[guides/overview-map-smoke-test.md](https://github.com/PandiO/knk-workspace/blob/next/docs/guides/overview-map-smoke-test.md) on `next`.

## 1. Waiting for the developer

1. Nothing yet. Known gates ahead (not blockers now):
   1. L3 (#737): the BlueMap scripting spike (spec § 9.6); if BlueMap's web app does not accept runtime marker sets
      and click listeners from a script, L3 stops and you decide the fallback.
   2. L3: the deploy notes (move the `bluemap-test` container into the `knk-alpha` Compose stack, Nginx `/bluemap/`)
      and the full-world render (about 20 hours) are yours to apply on the NAS; L3's live smoke steps wait for that.
   3. L5 (#739) is not merged into `next` before your live check of the L4 visibility steps (smoke § 4.1 steps 2, 3
      and 5), recorded on #738.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Region outlines | #735 | Running | `claude/overview-map-outlines`: knk-plugin, knk-web-api (from `next`) | – | – | create_session (see decision 3) |
| L2 Public map API | #736 | Not started (gate: L1 merged into `next`) | – | – | – | – |
| L3 `/map` page | #737 | Not started (gate: L2 merged into `next`) | – | – | – | – |
| L4 Live players backend | #738 | Not started (gate: L2 merged into `next`) | – | – | – | – |
| L5 Live players layer | #739 | Not started (gate: L3 and L4 merged, developer's L4 check) | – | – | – | – |
| L6 Staff details | #740 | Not started (gate: L3 merged into `next`) | – | – | – | – |
| L7 Gate commands backend | #741 | Not started (gate: L2 merged into `next`) | – | – | – | – |
| L8 Gate command buttons | #742 | Not started (gate: L3 and L7 merged into `next`) | – | – | – | – |
| L9 Player context panel | #743 | Not started (gate: L5 merged into `next`) | – | – | – | – |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from `next`, PRs target `next`, the coordinator merges
   into `next`), because on 2026-11-18 `.github/workflows/ci.yml` exists on `origin/main` of both knk-web-api and
   knk-web-app (skill § 1.3). Bases at the first run: knk-plugin `next` `1f414d08`, knk-web-api `next` `8ec54e1`,
   knk-web-app `next` `e7c9265`, knk-workspace `next` `afc4e09b`. Alternatives: (a) the old rules (default branch, the
   developer merges): not applicable once CI runs on both default branches.
2. **Overlap check for L1** (sessions board read from `origin/main` `145fadbb`, 2026-11-18). Chosen: no blocking
   overlap; L1 starts now. No "In progress" row has a running link in L1's areas: the off-road navigation chain (#698)
   has no link running and works in `core/roads/`, `core/navigation/`; the NPC follow-ups chain (#358) and chain 3
   follow-ups (#564) are in review, already merged into `next` (their region work, `TempRegionRetentionTask`,
   `WgRegionIdTaskHandler`, is in L1's base); the dashboard tables row (#608) waits for the developer's OK before
   building. Shared files L1 will touch additively: knk-plugin `KnKPlugin.java` (wiring), `config.yml` (new `map:`
   block), `plugin.yml` only if needed, the managed-region reconciler and `WorldGuardRegionRenamer` (one call each to
   report outlines); knk-web-api `Properties/KnKDbContext.cs` (one `DbSet` and its configuration), the game hub (one
   method), DI registration. L1 is told to keep to new files plus these additive hooks. The siege weapons design
   (#354 / #613) will reuse L3's bridge script later; that is not a file overlap now. Alternatives: (a) wait for the
   in-review chains to be promoted: no reason, their changes are already in `next`; (b) treat the shared hot files
   as a block: not needed, the edits are additive (developer decision 2026-11-12).
3. **Route for L1.** Chosen: `create_session` (knk-workspace source, Auto mode, same model as the coordinator), as the
   developer asked in the coordinator prompt; fallback a subagent of this coordinator with the same prompt (variant B)
   if the link's `add_repo` for knk-plugin or knk-web-api is refused or its dry run fails. Alternatives: (a) a subagent
   from the start, which skill § 4.1.4.2 suggests for links needing two repositories besides knk-workspace: the
   developer's own instruction takes precedence (skill § 1.1); (b) a session without Auto mode: it would ask the
   developer before other tool calls.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_
