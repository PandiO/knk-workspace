# Knights and Kings — Global Agent Instructions

Read this before starting any work on Knights and Kings, in any repo.

## What this project is

Knights and Kings is a long-running (~10 year), single-developer MMO-style
Minecraft game project. It has gone through three major revisions:
- V1: Bukkit plugin, WorldGuard/WorldEdit/Citizens, flat-file storage.
- V2: added MySQL + Hibernate + caching, user roles/stats, inventory menus,
  a work-in-progress siege minigame.
- V3 (current): split into three components sharing one MySQL database —
  `knk-web-app` (React + TypeScript), `knk-web-api` (ASP.NET Core),
  `knk-plugin` (Spigot/Paper Minecraft plugin).

Most features span all three V3 components, not just one.

## Current priority

Reach MVP for V3, with the siege minigame as the headline feature, at a
level of functionality comparable to what existed in V1/V2. When in doubt
about what to work on next, prioritize whatever moves toward that MVP over
polish or scope elsewhere.

## The human's availability — this matters a lot

The developer has a full-time job on weekdays. During work hours they can
only do brief check-ins: approving/steering something already in motion,
answering a quick question, unblocking a stuck session. They cannot do
focused design work, deep debugging, or large decisions during the work
week. Real deep work happens evenings and weekends.

**Practical implications for you as an agent:**
- Don't design yourself into a corner that requires a big synchronous
  decision from the human mid-week. If a task needs a significant judgment
  call, either make a reasonable default choice and clearly flag it for
  later review, or pause and queue the question rather than blocking.
- Prefer leaving a session in a clean, resumable state over leaving it
  half-finished with unclear next steps — the human may not return to it
  for days.
- Write status/handoff notes assuming the reader (human or another agent)
  has no memory of this session and may be picking it up a week later.

## Multi-session / parallel work conventions

Multiple Claude Code sessions are often running or paused simultaneously
across the three component repos, frequently on the same cross-cutting
feature. To avoid collisions and lost context:

1. **Before starting work**, check `knk-workspace/docs/ACTIVE_SESSIONS.md`
   for what's currently in flight and which files/areas are claimed.
2. **Claim your scope** by adding an entry there (feature, repos/files
   touched, session start time) before making changes.
3. **Prefer feature-level scoping over component-level scoping** — since
   most features touch all three repos, the unit of ownership is the
   feature, not "whichever repo I happen to be in."
4. **Update your entry when you pause or finish**, including a one-line
   status and pointer to relevant commits/branches — don't just stop.
5. If you discover another active/claimed session's scope overlaps with
   what you're about to do, stop and flag it rather than proceeding.

## Documentation conventions

`knk-workspace` is the canonical documentation repo, organized as:
`vision/`, `architecture/`, `guides/`, `ai-agents/`, `specs/`, `backlog/`,
`reports/`, `archive/`. Legacy repos are `knk-v1-archive` / `knk-v2-archive`
(`knk-` prefix, `-archive` suffix convention for retired code).

- Don't create new scattered docs outside this structure.
- If you write a report, scan, or audit output, it goes in `docs/reports/`
  with a dated filename; architecture and guide docs are living documents —
  update them in place rather than creating dated copies.
- If existing documentation looks stale or contradicts what you find in the
  code, don't silently trust the doc — flag the discrepancy.

## General working style

- Cite file paths and be specific; avoid vague summaries the human has to
  re-verify.
- Don't delete or restructure things speculatively — propose, flag, or ask,
  especially for anything destructive.
- Keep an eye out for legacy/dead code left over from V2, given the recent
  architecture shift — flag it rather than assuming it's still needed.
