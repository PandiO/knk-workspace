# Active Sessions

Live tracker of in-progress work across all four Knights and Kings repos
(`knk-workspace`, `knk-web-app`, `knk-web-api`, `knk-plugin`). Referenced by
`docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`.

**How to use this file:**
- Before starting work, check the table below for anything overlapping
  your intended scope. If something overlaps, stop and flag it rather than
  proceeding.
- Add a row when you start; scope by **feature**, not by repo, since most
  features span all three component repos.
- Update your row's Status/Last Updated whenever you pause, and move it to
  "Recently Completed" (below) when you finish, rather than deleting it
  outright — keeps a short trail of what just happened.
- This file will get concurrent edits from parallel sessions. That's
  expected — if you hit a merge conflict here, resolve it by keeping both
  rows rather than picking one; conflicts on this file are cheap to fix by
  hand.
- Keep entries short — this is a status board, not a design doc. Link out
  to the relevant branch, PR, or `docs/reports/` file instead of restating
  detail here.

## In progress

| Feature | Repos / files claimed | Owner (human / session) | Status | Started | Last updated |
|---|---|---|---|---|---|
| _(example)_ Siege minigame — capture point sync | web-api: `Services/SiegeService.cs`; plugin: `siege/` package | Claude Code session A | Implementing capture-point event handling | 2026-09-17 | 2026-09-17 |

## Recently completed

| Feature | Repos touched | Finished | Notes / link |
|---|---|---|---|
| _(example)_ Codebase scan — knk-plugin | knk-plugin (read-only), knk-workspace (docs) | 2026-09-17 | See `docs/reports/plugin-scan-2026-09-17.md` |
| Codebase scan — knk-web-api | knk-web-api (read-only); knk-workspace docs | 2026-09-18 | See `docs/reports/web-api-scan-2026-09-18.md`, `docs/architecture/web-api-architecture.md`, `docs/guides/web-api-reading-guide.md` |

## Paused / blocked

| Feature | Repos / files claimed | Blocked on | Last updated |
|---|---|---|---|
| _(none currently)_ | | | |
