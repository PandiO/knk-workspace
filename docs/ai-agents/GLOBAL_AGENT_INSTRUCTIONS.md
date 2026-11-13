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
   Once the branch model below applies, the default branch is what is
   released and `next` is what is integrated but not yet accepted; say which
   one you describe.
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
issues for `[KNG-n]` to find the copy of a `KNG-n` reference; the copied
Linear issues are Canceled with a "Moved to GitHub: PandiO/knk-workspace#n"
comment. Issues closed before the move exist only in Linear; their links in
docs stay valid.

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
   close it as completed once merged (under the branch model below: once the
   developer promotes `next` to trunk; or as the developer decides) and drop
   the status label. Link the branch or PR in a comment.

Without GitHub issue access, list the items under "To file" in your tracker
row or handoff and tell the developer.

## Parallel sessions and branches

`knk-workspace/docs/ACTIVE_SESSIONS.md` is the live coordination board for
Claude Code and Codex alike, regardless of where repos are cloned.

1. Before edits, refresh it from the current workspace default branch and
   inspect overlapping feature and file claims. A claim blocks your work only
   when the other branch changes the same lines or the claim is active on the
   same area; then stop and coordinate. Additive edits elsewhere in a shared
   file may go ahead and are logged as a decision with its alternatives
   (developer decision 2026-11-12). Don't infer that an old timestamp makes a
   row free.
2. Claim the feature and specific repos/files with an owner, branch, status,
   start date and update date. Publish the claim before editing shared work.
   If the board is inaccessible or the claim cannot be published, avoid
   conflicting remote edits and disclose the limitation.
3. Check the existing standing branch per repo for this feature. Continue it
   when appropriate instead of forking a branch per phase or agent. For a new
   feature use one descriptive branch per affected repo (for example
   `codex/kng-32-agent-instructions`), based on that repo's `next` branch
   once the branch model below applies, until then on its current default
   branch; don't assume every repo uses `main`. A `claude/` branch is not
   exclusive to Claude, nor a `codex/` branch to Codex. Preserve another
   session's uncommitted work and coordinate before modifying its branch.
4. Keep claims scoped to the feature across repos, not merely to one repo.
   Update the row when pausing with branch/commit, verification and next
   steps. On completion move the row straight from the board into the
   current month's archive file `docs/reports/sessions-archive/<YYYY-MM>.md`
   (newest first; see its README), link issue/PRs and note unmerged work.
   Don't park it under "Recently completed": the script
   `scripts/sessions-archive/archive_sessions.py` only cleans up rows left
   there (developer decision 2026-11-12). Preserve concurrent rows on
   conflict, then reread before publishing a resolution.
5. Use PRs for review where appropriate. Do not merge or deploy merely
   because a patch or test passed; follow the feature's live validation and
   developer sign-off requirements. The standing exceptions are the merges the
   branch model below allows once its checks hold: a coordinator merging link
   pull requests into `next`, a session merging its own pull request into
   `next` outside a chain ("Branches" rule 3), and an agent-workflow-file pull
   request merged into the default branch by the session that opened it, or in
   a chain by the coordinator ("Branches" rule 11). Merging `next` into trunk (promotion) stays the developer's.

## Branches, releases and risk tiers

Developer decision 2026-11-12, [AI agent workflow design](../specs/ai-agent-workflow/DESIGN.md) § 2 and § 5; the
start condition and the coordinator merge were confirmed by the developer the same day (setup chain, PandiO/knk-workspace#327); rules 3, 4, 10 and 11 were changed or added on 2026-11-13 (merging outside a chain, Codex findings, GitHub rulesets, agent workflow files to `main`).
**These rules apply as soon as CI runs on the API and web-app default branches** (PandiO/knk-workspace#328:
`.github/workflows/ci.yml` on knk-web-api `master` and knk-web-app `main`). Until then the current rules hold: feature
branches start from the default branch, pull requests target it, and only the developer merges.

1. **Trunk = production.** The default branches (`master` for knk-web-api, `main` for the others) move only when the
   developer accepts a release. Releases are numbered tags on trunk (for example `v0.12`); deploys use the tag and a
   rollback deploys the previous tag. A release branch is cut from a tag only for a hotfix while `next` holds
   unfinished work.
2. **`next` = integration.** Every repo has one `next` branch that collects finished work. Feature branches start from
   `next` and take its updates by merge, never rebase; their pull requests target `next`. A feature that depends on
   another unreleased feature can then continue the same day.
3. **Merging into `next`.** Coordinators merge link pull requests into `next` as soon as CI and their link checks
   pass, for every risk tier, through the pull request with a merge commit. **Outside a chain** (a one-off fix, a
   tweak, a docs session), the session that opened the pull request merges it into `next` itself, the same way, once
   all of these hold (developer decision 2026-11-13; it replaces the 2026-11-12 rule that such pull requests wait for
   the developer): CI is green on its head; every Codex finding is handled (rule 4); the issue carries a `tier:` label (a `documentation`
   issue counts as `tier:1` and gets that label when it is created);
   `tier:3` work is behind a flag that is off by default (rule 6); the essential docs ship with it (Shipping a change).
   The developer stays the gate at promotion (rule 5), not at the merge into `next`. A merge into `next` does not close
   the issue; it stays `status:in-review` until the developer promotes `next`.
4. **Codex review findings are handled before a merge into `next`** (developer decision 2026-11-13). The ChatGPT
   Codex connector app reviews every pull request and leaves inline findings (P1, P2, …). Before merging, the session
   that merges (link, coordinator or the session that opened the pull request) reads every finding. Codex reviews
   when a pull request is opened or marked ready, not on later pushes; after any push that changes the pull
   request's content (code or docs), comment `@codex review` and wait for that review before merging. For each finding, the session fixes what is real and in
   scope, or answers on the finding's thread why not (not a bug, or out of scope with the issue it filed), and resolves
   the thread. A P1 finding blocks the merge until it is fixed or
   the developer decides. Findings are listed in the link's report block.
5. **The developer promotes `next` to trunk** after testing `next` as a whole (the daily digest lists what to test):
   merge into trunk, then the release tag. Only the developer, or the manager session on the developer's explicit go,
   promotes. **Release tags** go through the "Release" workflow in knk-web-api, knk-web-app and knk-plugin
   (`.github/workflows/release.yml`), because cloud sessions cannot push tags (a tag push answers 403): run it with
   GitHub MCP `actions_run_trigger` (workflow `release.yml`, ref = the default branch, inputs `tag` such as `v0.2` and
   `sha` = the full 40-character trunk commit). It checks the input, then creates the tag and a GitHub release with
   generated notes. Sessions may run it as part of a promotion the developer asked for; the job runs in the GitHub
   environment `release`, so every run waits until the developer approves it on GitHub (developer decisions
   2026-11-13).
6. **Flags for risky work.** Big or risky features go into `next` behind a config flag that is off by default, so
   unreviewed work is harmless there. A rejected change is reverted or fixed in `next` before the release.
7. **Risk tiers** are labels on each issue, proposed by intake or design and overridable by the developer:
   `tier:1` a tweak to existing behaviour (automated tests are the review, the developer does a quick pass); `tier:2` a
   feature change (a short smoke test on `next`); `tier:3` new foundations, schema changes or game feel (a full smoke
   test by the developer).
8. Stacking a branch directly on another feature's unmerged branch is the exception, for uncertain work, and is
   stated in the chain charter.
9. Chain bookkeeping (progress reports, charters, `docs/ACTIVE_SESSIONS.md` and its archive files) stays on
   knk-workspace `main`, as before.
10. **GitHub rulesets** (set up by the developer 2026-11-13) enforce part of this. On knk-web-api, knk-web-app and
    knk-plugin, `master`/`main` and `next` need a pull request (no approvals required), the CI checks
    (`build-and-test` and `fresh-database` on the API, `build-and-test` on the web app, `build` on the plugin), every
    review conversation resolved (so Codex threads must be answered and resolved, rule 4), and a merge commit; they
    cannot be deleted or force-pushed. On knk-workspace, `main` and `next` are only protected against deletion and
    force pushes, so chain bookkeeping can still be pushed directly to `main` (rule 9); everything else still goes by
    pull request. Tags `v*` cannot be deleted or moved in any repo. Agents act on GitHub as the developer, so these
    rules guard against mistakes, not against agents; follow them as written rather than looking for a way around.
11. **Agent workflow files go straight to knk-workspace `main`** (developer decision 2026-11-13), because every new
    session starts from `main` and a rule that waits in `next` would not reach agents until the next promotion. These
    are `.claude/` (skills, hooks, settings), `.mcp.json`, `docs/ai-agents/`, `AGENTS.md` and `CLAUDE.md` in
    knk-workspace, and `AGENTS.md`/`CLAUDE.md` in the component repos. A change to them goes on its own branch from the
    repo's default branch with a pull request into that default branch; the session that opened it merges it with a
    merge commit once rule 3's checks hold (CI where it exists, Codex findings handled), then merges the default branch
    into `next` through a pull request, so `next` carries the same rules. In a chain, the link opens that pull request
    and the coordinator merges it the same way (coordinator skill § 7.10). Game code, feature docs and guides still go
    through `next`. A pull request that mixes both is split.

## Session chains (multi-link work)

A chain splits a feature into links that each run in a fresh context. A **coordinator** session starts each link,
checks it and starts the next; links never start links. Two project skills in knk-workspace hold the procedure
(Claude Code loads them from `.claude/skills/`; other agents read the `SKILL.md` files directly):

1. [`knk-coordinator`](../../.claude/skills/knk-coordinator/SKILL.md): the loop, gate checks against the actual
   branches, starting links (`create_session` or a subagent), `send_later` check-ins, the checks of a finished link,
   merging into `next`, blockers and reporting. Templates for the permissions block, the chain charter and the
   progress report are next to it.
2. [`knk-link`](../../.claude/skills/knk-link/SKILL.md): setup (repos, base branch, push dry run, toolchains,
   baseline tests), hard rules, blockers, the pull request and the report block with agent decisions.

A chain's charter keeps only its links table, gates and binding documents. Facts the skills rely on:

1. **Route (developer decision 2026-11-12):** `create_session` is the preferred route for every link. It attaches one
   repository (`source_url`, normally knk-workspace); the link session attaches the other knk repositories itself with
   `add_repo`, which knk-workspace's `.claude/settings.json` allows by a permission rule (PandiO/knk-workspace#331). A
   subagent of the coordinator, which shares the coordinator's attached repos, is the fallback when `create_session`
   is unavailable or an attach is still refused.
2. History, before the rule existed: the new session's permission check only allowed `add_repo` when the request was
   in the session's **prompt**; an `add_repo` instruction found in a repo file was refused (form wizard chain,
   2026-10-11). On 2026-11-12 even a request in the prompt was refused when another session wrote the prompt, and the
   developer had to approve the attach (setup chain, PandiO/knk-workspace#327). The coordinator still pastes the
   generated permissions block into every link prompt: it carries the authorization and the dry-run step.
3. Pass the model explicitly to `create_session`; pass `effort` only when the developer asked for a level.
4. Before a link changes anything: `git push --dry-run` on the feature branch of every repo it will change.

## Closed alpha test runs

Follow [closed alpha test runs](../guides/closed-alpha-test-runs.md) for anything about a run with testers. In
short:

- Only sessions **with testers** are numbered test runs. The developer's own checks are "developer pre-checks" or
  smoke test runs and never change the next run's number.
- Each run has `docs/reports/alpha-tests/test-run-<n>/` with `test-run-<n>-preparation.md`, `-checklist.md` and
  `-findings.md`; the date goes in the headers, not the folder name.
- When a fix package for a run leaves an open decision, a live check that needs several players, or a known issue,
  add it to the **next** run's preparation plan (scope, decisions table or known issues), not only to the package
  report or handoff.

## Shipping a change: documentation

Documentation is part of done (developer decisions 2026-11-03 and 2026-11-10, PandiO/knk-workspace#292). The
details are in [documentation maintenance](../guides/developer/DOCUMENTATION_MAINTENANCE.md). Essential docs ship
with the feature. The rest is written asynchronously, in a documentation issue and a separate session, so it never
slows a merge.

**Before merge (essential; the implementing session writes these on the feature branches):**

1. **Docs impact list** in the PR's "Docs impact" section. Draft it at `status:in-review` and correct it after the
   developer's test. It names every guide, spec, register row and site page the change affects and what changed in
   behaviour, so a later session can write those docs from it and the diff.
2. **Deploy notes** in the PR and the changelog entry, under "Admin steps":
   - Plugin `config.yml`: every added, renamed or removed key and every changed default, with the YAML to paste. The
     plugin only writes `config.yml` when a server has none (`saveDefaultConfig()`), so on dev and alpha new keys
     must be merged by hand at each deploy; until then they silently run on the jar's defaults.
   - API settings (`appsettings`, env vars, secrets), migrations, one-time scripts, ports, containers and seed changes.
   - Update the [plugin configuration reference](../guides/admin/plugin-configuration.md) (the key's table and
     § 2.1) and `guides/production-installation.md` when these change. Its § 2 is the merge checklist for every
     plugin deploy.
3. **Changelog entry** in `docs/CHANGELOG.md` at merge: start with one sentence a player understands, then the
   technical detail, links and "Admin steps".
4. **Status:** the spec/plan status, the smoke-test guide's status and the feature register row's merge column.

**At merge:** once the branch model above applies, "merge" here means the feature's merge into `next`: items 2
and 3 happen then, and item 1 waits until the developer promotes `next` to trunk (developer decision 2026-11-12).
Until the branch model applies it means the merge into the default branch, and all three happen then.

1. Close the feature issue as completed and drop its status label, as usual.
2. If the docs impact list has anything not done before merge, create one `documentation` sub-issue under the
   feature issue, titled `Docs: <feature>`, labelled `documentation` and `tier:1`. Copy the list into it, link the merged commits and PRs, and say which
   items are player/admin guides (these gate deploys, see below).
3. **Start a new session for it right away.** Use `create_session` (claude-code-remote) with `source_url`
   `https://github.com/PandiO/knk-workspace` and the prompt in
   [docs-session prompt](docs-session-prompt.md), filled in. Pass the model explicitly. If `create_session` is
   unavailable or refused, queue it with `spawn_task`. If that is unavailable too, give the developer the filled
   prompt in your final message. Note the session or the fallback in the documentation issue and the tracker row.
   Don't write those docs in the implementing session unless the developer asks: a separate session keeps the merge
   fast.

**Guardrails:**

- **Deploy gate:** before a deploy to knk-alpha or a tester run, list the open `documentation` issues for features
  in that deploy. Player and admin guide items must be closed first, or the developer explicitly accepts the gap in
  the run's preparation plan.
- **Weekly check:** a scheduled session reports open `documentation` issues and their age, files issues for merges
  without docs, and writes a dated report in `docs/reports/`.
- **Debt cap:** with more than five open `documentation` issues, or one older than two weeks, tell the developer at
  the start of your session, and suggest the next session be a docs session.

All documentation lives in `knk-workspace/docs/`. Component repos keep only their `README.md` (what it is and a quick
start), `AGENTS.md`, `CLAUDE.md` and `.github/`. Player-facing docs are in English.

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
