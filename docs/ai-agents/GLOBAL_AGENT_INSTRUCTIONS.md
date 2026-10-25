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
   in `knk-workspace/docs/specs/` and its GitHub issue, checking their status
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

## GitHub Issues is the work list

The issues of `PandiO/knk-workspace` are the one list of work to implement
(developer decisions 2026-10-15 and 2026-10-25). File every issue there, also
for work in the component repos, and reference it as
`PandiO/knk-workspace#123` (a bare `#123` resolves to the wrong repo from a
component repo's commit or PR).

Linear (team KNG) was the work list until 2026-10-25, when the free issue
limit made new issues impossible. It stays as a read-only archive: don't
create, edit or comment on Linear issues. Every open KNG issue was copied
with its id in the title, such as `[KNG-27] ...`, so search the GitHub
issues for `[KNG-n]` to find the copy of a `KNG-n` reference. Closed KNG
issues exist only in Linear; their links in docs stay valid.

Issue conventions:

- Type as a label: `bug`, `feature` or `improvement`; no type label for
  other tasks. (GitHub issue types need an organization account, so this
  user-owned repo can't store them.)
- Status: open without a status label = Backlog/Todo; `status:in-progress`;
  `status:in-review` (waiting for the developer's test); closed as completed
  = Done; closed as not planned = Canceled; closed as duplicate = Duplicate.
- Optional `priority:urgent|high|medium|low`. Phased work uses sub-issues
  under a parent issue.
- PRs in any repo close an issue with `Closes PandiO/knk-workspace#123`.

1. Implement only what an issue covers. Specs, handoffs, reports,
   `docs/backlog/`, code comments and chat are input, not a work list:
   anything found there that should be built gets an issue first. Scope a
   session, chain link, branch and tracker row by issue id.
2. The one exception: a really small bugfix or QOL tweak that is picked up
   and fixed straight away, typically during the developer's test run of a
   branch (a few lines, no schema or API contract change, no open decision).
   Fix it on the branch under test and note it in that issue or test report.
   If it isn't fixed in that sitting, it gets an issue.
3. When the developer mentions a bug, idea or request, in any session and on
   any topic, search the issues for it (open and closed; for older work
   also Linear, read-only). If no issue
   covers it, create one in that session (what was said, repro, where in the
   code, date) and give the developer its id. Never leave it only in chat, a
   handoff or a report.
4. Do the same for what you find yourself and leave out of scope: a bug
   found in passing, a follow-up, a known gap. File it or comment on the
   issue that covers it; a "found in passing" list in a report is not enough.
   Never describe a known gap in code or docs as intended behaviour without
   the issue id next to it.
5. Keep the issue's status true: `status:in-progress` when work starts,
   swap it for `status:in-review` while it waits for the developer's test,
   close it as completed once merged (or as the developer decides) and drop
   the status label. Link the branch or PR in a comment.

Without GitHub issue access, list the items under "To file" in your tracker
row or handoff and tell the developer.

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
when they start, and `create_session` attaches only one (`source_url`). Other repos must be attached by the new
session with `add_repo` (access `push`), and the permission check only allows that when the request is in the
session's **prompt** (the developer's request, relayed by the coordinator). An `add_repo` instruction found in a
repo file (a handoff doc) was refused, which blocked a link (form wizard chain, 2026-10-11).

- A **coordinator** session (the developer's session in the "Default Correct" environment, with every repo
  attached) starts each link. Put the `add_repo` + clone + `git push --dry-run` step **in the prompt**, then point
  at the handoff file. Links don't start the next link; the coordinator does, after checking the previous one.
- Fallback when `add_repo` is refused: the coordinator runs the link as a fresh subagent (Agent tool, explicit model
  and effort), which shares the coordinator's repos.
- `create_session` has no effort setting; session links run at the environment default. Pass the model explicitly.
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
