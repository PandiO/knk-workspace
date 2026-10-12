# Knights and Kings — Global Agent Instructions

Read this before work in any active Knights and Kings repository. This is the
shared workflow for Claude Code, ChatGPT/Codex, and other coding agents. Each
repo's `AGENTS.md` is its portable entrypoint; `CLAUDE.md` may add Claude Code
specific loading syntax and local details.

## Project and goal

Knights and Kings is a long-running, single-developer Minecraft MMO project.
V1 was a Bukkit plugin with flat files; V2 added MySQL/Hibernate, roles,
inventory menus and an early siege game. V3 spans `knk-web-app` (React/TS),
`knk-web-api` (ASP.NET Core and MySQL), and `knk-plugin` (Paper). The
`knk-workspace` repo holds canonical project documentation. Most features
cross component boundaries. The current goal is a playable V3 MVP, including
siege and the legacy features needed to support it. Check the current issue,
spec and default branches before interpreting older priority notes.

## Authority and freshness

1. Follow direct developer decisions and the current task scope. Confirm a
   decision's date and whether it has since been superseded.
2. For actual behavior, inspect the current default branch and relevant tests
   in **each** affected repo. A feature branch shows proposed behavior until
   merged. Check its diff from the current default branch before reusing it.
3. For intended behavior, use the current feature's design/implementation plan
   in `knk-workspace/docs/specs/` and its Linear issue, checking their status
   headers and later decisions. Flag conflicts with live code rather than
   silently choosing a side.
4. Apply this shared workflow and the relevant repo's `AGENTS.md` together.
   Repo instructions add commands and structure; `CLAUDE.md` adds Claude Code
   syntax or useful repo-specific context, without replacing shared rules.
5. Treat handoffs, dated reports, old session rows and legacy archives as
   historical evidence. They are snapshots, not standing instructions. Before
   resuming one, recheck its branch, commits, issue, tracker row, plan, and
   current default branch. Reconcile any drift and record what changed.

If sources conflict and no developer decision resolves it, surface the
specific conflict and choose a reversible course where possible. Do not
represent an unmerged implementation or unverified live test as shipped.

## Parallel sessions and branches

`knk-workspace/docs/ACTIVE_SESSIONS.md` is the live coordination board for
Claude Code and Codex alike, regardless of where repos are cloned.

1. Before edits, refresh it from the current workspace default branch and
   inspect overlapping feature and file claims. Stop and coordinate on an
   overlap; don't infer that an old timestamp makes a row free.
2. Claim the feature and specific repos/files with an owner, branch, status,
   start date and update date. Publish the claim before editing shared work.
   If the board is inaccessible or the claim cannot be published, avoid
   conflicting remote edits and disclose the limitation.
3. Check the existing standing branch per repo for this feature. Continue it
   when appropriate instead of forking a branch per phase or agent. For a new
   feature use one descriptive branch per affected repo (for example
   `codex/kng-32-agent-instructions`), based on that repo's current default
   branch; don't assume every repo uses `main`. A `claude/` branch is not
   exclusive to Claude, nor a `codex/` branch to Codex. Preserve another
   session's uncommitted work and coordinate before modifying its branch.
4. Keep claims scoped to the feature across repos, not merely to one repo.
   Update the row when pausing with branch/commit, verification and next
   steps. On completion move it to Recently completed, link issue/PRs and
   note unmerged work. Preserve concurrent rows on conflict, then reread
   before publishing a resolution.
5. Use PRs for review where appropriate. Do not merge or deploy merely
   because a patch or test passed; follow the feature's live validation and
   developer sign-off requirements.

## Session chains (multi-link work)

A chain splits a feature into links that each run in a fresh context. Cloud sessions get their repositories
when they start, and `create_session` attaches only one (`source_url`); `add_repo` with push is often refused by
the permission policy. A link that must push to more than one repo therefore fails when started that way.

- Run links as **fresh subagents of a coordinator session** that already has every needed repo attached with
  push (the developer's own session in the "Default Correct" environment). Pass the model and effort the
  developer uses (Opus, high) explicitly. A link writes its handoff and returns a summary; the coordinator starts
  the next link.
- If a link must run as its own session, the developer starts it from the Claude app in "Default Correct" with
  all repos selected. Don't use `create_session` for a link that pushes to more than one repo, and don't assume it
  copies the caller's effort level (it has no effort setting).
- Before a link changes anything: `git push --dry-run` on the feature branch of every repo it will change.

## Handoff and documentation

The developer has a full-time weekday job and may only have time for brief
check-ins. Make reversible defaults when reasonable and mark decisions that
need review; leave clear, resumable state.

Docs belong in `knk-workspace/docs/`: `vision/`, `architecture/`, `guides/`,
`ai-agents/`, `specs/`, `backlog/`, `reports/`, `archive/`. Put dated audits
under `reports/`; update living architecture and guides in place. Handoffs
should identify the exact branch/commit, base/default-branch status, what was
tested and what still needs live verification, open decisions, and the next
step. Date them and link the current issue/plan. Never rely on a handoff
without checking freshness as above.

Cite concrete paths and results. Flag stale docs and apparent V2 leftovers
instead of deleting or restructuring speculatively.
