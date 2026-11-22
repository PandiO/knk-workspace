# Landmarks as a Domain subtype chain — progress report

**Status:** Running (2026-11-22) · **Last updated:** 2026-11-22

**Issue:** [PandiO/knk-workspace#976](https://github.com/PandiO/knk-workspace/issues/976), links
[#983](https://github.com/PandiO/knk-workspace/issues/983) (L1), [#984](https://github.com/PandiO/knk-workspace/issues/984) (L2),
[#985](https://github.com/PandiO/knk-workspace/issues/985) (L3), [#986](https://github.com/PandiO/knk-workspace/issues/986) (L4).
**Charter:** [handoffs/LANDMARK_DOMAIN_CHAIN.md](../ai-agents/handoffs/LANDMARK_DOMAIN_CHAIN.md).
**Coordinator:** session_01R1w2UtYX9XFbTVUFy6zJUb (cloud), started 2026-11-22 on the developer's go ("Start it now",
design session of 2026-11-22).

## 1. Waiting for the developer

Nothing.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 API model, migration, area kinds and parent (tier:3) | #983 | Running (started 2026-11-22) | `claude/landmark-domain`: knk-web-api (none yet); `claude/landmark-domain-l1`: knk-workspace (none yet) | none | none | create_session session_01R1w2Uv1A4MYoi62zFJTnwz, started 2026-11-22 16:32 UTC |
| L2 API lists, discovery, warps and realtime (tier:2) | #984 | Not started (gate: L1 merged into `next`) | `claude/landmark-domain-integration`: knk-web-api; `claude/landmark-domain-l2`: knk-workspace | none | none | (not started) |
| L3 Plugin (tier:2) | #985 | Not started (gate: L1 and L2 merged into `next`) | `claude/landmark-domain`: knk-plugin; `claude/landmark-domain-l3`: knk-workspace | none | none | (not started) |
| L4 Web app (tier:2) | #986 | Not started (gate: L1 and L2 merged into `next`) | `claude/landmark-domain`: knk-web-app; `claude/landmark-domain-l4`: knk-workspace | none | none | (not started) |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model, because `.github/workflows/ci.yml` is on `main` of knk-web-api and
   knk-web-app (checked 2026-11-22 after a fresh fetch). Links branch from `next`, their PRs target `next`, and the
   coordinator merges them into `next` once the checks of skill § 6 hold. Bases at the first run: knk-web-api `next`
   `4d9bea33` (CI green: Build and test, Migrations), knk-web-app `next` `ac28717e`, knk-plugin `next` `167bb56c`,
   knk-workspace `next` `0f7c3639`. Alternatives: none (the old rules apply only without CI on both default branches).
2. **Route and model.** Chosen: `create_session` for every link (skill § 4.1.1), with the coordinator's own model passed
   explicitly and no effort level (the developer asked for none), because each link changes one component repo plus
   knk-workspace, so it attaches a single repository (skill § 4.1.4.2). On a refused `add_repo` or a failed dry run the
   link is rerun as a subagent of the coordinator with the same prompt (variant B). Alternatives: (a) subagents from the
   start, which keeps the coordinator's context busy for the length of a tier:3 link and is meant for links with two or
   more component repos; (b) a smaller model for the tier:2 links, rejected for consistency across the chain.
3. **knk-workspace branch per link.** Chosen: the docs of each link (changelog entry, smoke-guide section, spec status)
   go on `claude/landmark-domain-l<n>` in knk-workspace, from `next`, with its own PR into `next`. The charter names the
   component-repo branches only, and one shared knk-workspace branch would have L3 and L4 pushing to the same branch
   while they run together. Alternatives: (a) `claude/landmark-domain` for every link in knk-workspace, rejected
   (concurrent pushes from L3 and L4, and a reused branch after L1's merge); (b) docs inside the component-repo PR,
   rejected (the smoke guide and changelog live in knk-workspace).
4. **#981 (CrownLand loop in `GetParentDomainDecisions`).** Chosen: L1 takes #981 over, as the charter allows (§ 3.1
   note 1): #981 is open, has no branch, PR, board row or comment (checked 2026-11-22), and LD23's parent walk replaces
   the code it fixes. L1 covers #981's tests (a `CrownLand` and a bare `Domain` mapped to `DomainRegionDecisionDto` and
   through `search-region-decisions` return without parents) and comments on #981 with its PR; #981 stays open until the
   developer promotes `next`, like the chain's issues. Alternatives: (a) a separate tier:1 fix first, rejected (it edits
   the same lines L1 replaces, so a conflict and the work twice); (b) leave #981 to the manager, rejected (two sessions
   on `DomainMappingProfile` at once).
5. **Overlaps at the start** (board fetched 2026-11-22, `origin/main` `60c127c0`).
    1. Off-road navigation chain #698: owns the landmark code of #708/#709, no link running, no API link queued. It does
       not block L1 or L2 (knk-web-api). For L3 (knk-plugin `core/navigation/` landmark classes) the coordinator checks
       its row and the navigation destination engine chain's row (#25, its L5 #747 is a knk-plugin navigation link
       waiting on a live test) before starting, and keeps one knk-plugin navigation link at a time across the three
       chains. Alternatives: (a) treat the #698 claim as a blocker for the whole chain, rejected (no running link, the
       code is merged into `next`); (b) ask the off-road coordinator to hand over the landmark files, not needed while
       it has no link.
    2. #945 landmark region path (`landmark_<id>`, merged into `next` via knk-web-api#77, board row archived
       2026-11-22): L1 removes it per LD14; #946 (production areas) keeps the generic owner lookup. No active claim.
    3. No other "In progress" row claims knk-web-api domain, landmark or region files; no knk-web-api PR is open.
6. **Order.** Chosen: L1 now; L2 once L1 is merged into `next` (same repo, one link per component repo); L3 and L4
   together once L2 is merged (they share no component repo; their knk-workspace branches differ, decision 3).
   Alternatives: (a) L4 in parallel with L2, rejected (the charter gates L4 on L2 for the list type and filter).
7. **Migration and flag exceptions for L1.** The knk-link skill allows only additive migrations and puts tier:3 work
   behind a flag; the charter overrides both for L1: its one migration is not additive (drops the landmark rows,
   LD10, dev DB only; charter § 3.3) and needs a working Down, and there is no flag (LD24, every landmark behaviour is
   off or neutral by default). The L1 prompt says so. Alternatives: none (charter and approved design).

## 4. Link blocks

_(Each link appends its block here when it finishes.)_
