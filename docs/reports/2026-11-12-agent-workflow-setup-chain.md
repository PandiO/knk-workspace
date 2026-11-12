# AI agent workflow setup chain — progress report

**Status:** Running (coordinator session, 2026-11-12) · **Last updated:** 2026-11-12

**Issue:** [PandiO/knk-workspace#327](https://github.com/PandiO/knk-workspace/issues/327), links
[#328](https://github.com/PandiO/knk-workspace/issues/328) (L1),
[#329](https://github.com/PandiO/knk-workspace/issues/329) (L2),
[#330](https://github.com/PandiO/knk-workspace/issues/330) (L3),
[#331](https://github.com/PandiO/knk-workspace/issues/331) (L4),
[#332](https://github.com/PandiO/knk-workspace/issues/332) (L5).
**Binding document:** [specs/ai-agent-workflow/DESIGN.md](../specs/ai-agent-workflow/DESIGN.md) § 12.

A coordinator session runs links L1–L5 one at a time in fresh sessions (fallback: a subagent), checks each result and
starts the next. Every link ends on a feature branch with an open pull request; nothing is merged into a default branch
or into `next`.

## 1. Waiting for the developer

1. Evening review and merges, in this order: L1 (CI) → L3 → L4 → L5 (re-run the archive script on fresh main), then
   merge each default branch into `next`.
2. Turn off GitHub Actions failure emails in your GitHub notification settings (DESIGN § 7.4).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | How started |
|---|---|---|---|---|---|
| L1 CI | #328 | Not started | `claude/agent-setup-ci` (knk-web-api, knk-web-app) | — | — |
| L2 Branches, labels, digest | #329 | Not started | `next` in all four repos | — (no file changes) | — |
| L3 Skills and instructions | #330 | Not started | `claude/agent-setup-skills` (workspace + three component repos) | — | — |
| L4 Tooling | #331 | Not started | `claude/agent-setup-tooling` (knk-workspace) | — | — |
| L5 Sessions board archive | #332 | Not started | `claude/agent-setup-sessions-archive` (knk-workspace) | — | — |

## 3. Coordinator decisions

1. **Overlap check (setup § 1.4).** Two "In progress" rows name files the links touch:
    1. "Arena duels P8" (KNG-222, paused for a live test since 2026-10-25) claims knk-plugin `CLAUDE.md` (adds an
       arena-duels paragraph in the structure list) and `docs/guides/README.md` (adds the arena-duels guide row) on its
       unmerged `claude/arena-duels` branches.
    2. "Alpha performance metrics" (KNG-232) claims knk-web-api `CLAUDE.md` and `docs/guides/README.md`, but the row
       says it was merged on 2026-10-22.

   Chosen: not a blocker. L3 changes only the "from this repo's current default branch" sentence near the top of the
   component `AGENTS.md`/`CLAUDE.md` files, and L4 adds one row to the developer-guide table of `docs/guides/README.md`;
   neither touches the lines those branches add, so a later merge stays mechanical. The link prompts tell L3 and L4 to
   keep their edits to those lines. Alternatives: (a) skip L3 and L4 until the arena-duels branches merge, which would
   leave the skills and tooling for another day over a claim that only adds lines elsewhere in the files; (b) ask the
   developer first, who is unavailable until the evening.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_
