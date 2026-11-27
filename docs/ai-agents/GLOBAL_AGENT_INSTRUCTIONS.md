# Knights and Kings — Global Agent Instructions

The shared workflow for every agent in every active Knights and Kings repo. Each repo's `AGENTS.md` is its entrypoint;
`CLAUDE.md` adds Claude Code details, never replacing these rules. Each rule's date, reason and history are in the
[decision history](decision-history.md) under its id (`D<n>`), and the detail shortened out of
these rules in [D15](decision-history.md#d15); you don't need it to follow a rule.

## Project and goal

A long-running, single-developer Minecraft MMO. V1 was a Bukkit plugin, V2 added MySQL/Hibernate, roles, menus and
early siege. V3 is `knk-web-app` (React/TS), `knk-web-api` (ASP.NET Core, MySQL) and `knk-plugin` (Paper);
`knk-workspace` holds the docs. Most features cross components. Goal: a playable V3 MVP with siege and the legacy
features it needs; check the current issue, spec and branches before older priority notes.

## Authority and freshness

1. Follow direct developer decisions and the task scope; check a decision's date and whether it was superseded.
2. Actual behaviour = the default branch and its tests in **each** affected repo; a feature branch is a proposal until
   merged (diff it before reuse). Under the branch model trunk is released, `next` integrated; say which you describe.
3. Intended behaviour = the feature's spec/plan in `docs/specs/` and its issue, with status headers and later
   decisions. Flag conflicts with live code; don't silently pick a side.
4. Handoffs, dated reports, old session rows and archives are snapshots: before resuming one, recheck branch, commits,
   issue, tracker row, plan and default branch, and record the drift.
5. A conflict no decision settles: name it and take a reversible course. Never present unmerged work or an unverified
   live test as shipped.

## GitHub Issues is the work list

The issues of `PandiO/knk-workspace` are the one work list, also for component repos; always write
`PandiO/knk-workspace#123`, never a bare `#123`. Linear (KNG) is a read-only archive: never write there; find a `KNG-n`
copy by searching issues for `[KNG-n]` [D1](decision-history.md#d1). Labels: type `bug`/`feature`/`improvement` (none
for other tasks); status none = Backlog, `status:in-progress`, `status:in-review` (waiting for the developer's test);
closed completed/not planned/duplicate = Done/Canceled/Duplicate; `tier:1|2|3` by the filer when the scope is clear,
else intake proposes one (`idea` until shaped); optional `priority:urgent|high|medium|low`; phases as sub-issues. PRs
close issues with `Closes PandiO/knk-workspace#123`.

1. Implement only what an issue covers; specs, handoffs, reports, `docs/backlog/`, comments and chat are input.
   Scope sessions, links, branches and tracker rows by issue id.
2. Exception: a few-line fix or QOL tweak made in the same sitting, typically during the developer's test of a branch
   (no schema or API contract change, no open decision), on that branch and noted in its issue or test report.
3. A bug, idea or request the developer mentions: search the issues (open and closed; Linear for old work); none
   covers it, create one now (what was said, repro, code location, date) and give the id. An idea for later goes to
   [`knk-intake`](../../.claude/skills/knk-intake/SKILL.md).
4. What you find and leave out of scope gets an issue or a comment on its issue, not just a report line. Never call a
   known gap intended without its issue id.
5. Keep the status true: in-progress at start, in-review while waiting for the test, closed as completed once merged
   (under the branch model: once `next` is promoted), status label dropped; link branch or PR in a comment. Without
   issue access, list "To file" items in your tracker row or handoff.

## Parallel sessions and branches

1. `docs/ACTIVE_SESSIONS.md` is the live board for every agent. Read it fresh before edits and each time you act on
   it (`git fetch origin`, then `git show origin/main:docs/ACTIVE_SESSIONS.md`). Find a session the developer mentions
   by issue, area and files; no match: say which rows you checked and when you fetched. A claim blocks you only when
   its branch changes the same lines or it is active on the same area (then coordinate); additive edits elsewhere go
   ahead as a logged decision; an old timestamp doesn't free a row [D2](decision-history.md#d2).
2. Claim feature, repos and files (owner, branch, status, start and update date) before editing shared work; can't
   publish it, avoid conflicting edits and say so. Update the row when pausing (commit, verification, next steps); on
   completion move it straight to `docs/reports/sessions-archive/<YYYY-MM>.md` (newest first), not "Recently
   completed" [D3](decision-history.md#d3). Keep concurrent rows on conflict and reread before publishing.
3. One branch per feature per repo, continued across phases and agents (for example
   `codex/kng-32-agent-instructions`), from `next` under the branch model, else the repo's default branch. Prefixes
   reserve nothing. Preserve others' uncommitted work; coordinate before changing their branch.
4. Don't merge or deploy because tests passed; follow the feature's validation and sign-off. Standing exceptions,
   once their checks hold: link PRs into `next` (coordinator), a session's own PR into `next` ("Branches" rule 3), an
   agent-workflow PR into the default branch ("Branches" rule 11), the manager's `main` → `next` syncs. Promotion is
   the developer's, or the manager's on their explicit go.

## Branches, releases and risk tiers

In force since CI runs on the API and web-app default branches; before that, branches started from and targeted the
default branch and only the developer merged [D4](decision-history.md#d4).

1. **Trunk = production.** Default branches (`main` everywhere) move only on a release the developer accepts. Releases
   are tags on trunk (`v0.12`); deploys use the tag, rollback the previous one; a release branch from a tag only for a
   hotfix while `next` holds unfinished work.
2. **`next` = integration.** Feature branches start from `next`, take it by merge (never rebase), target it.
3. **Merging into `next`**, by merge commit through the PR. Coordinators merge link PRs once CI and link checks pass.
   **Outside a chain** the PR's own session merges once: CI green on its head; its automated tests ship with it; every
   Codex finding is handled (rule 4); the issue has a `tier:` label (a `documentation` issue is `tier:1`, labelled at
   creation); `tier:3` work is behind an off-by-default flag; the essential docs ship with it
   [D5](decision-history.md#d5). In the merge turn it unsubscribes from the PR and cancels its `send_later` check-ins
   (knk-docs-session § 4.4). The issue stays `status:in-review` until promotion.
4. **Codex findings first** [D6](decision-history.md#d6). The merging session reads every inline Codex finding. Codex
   reviews on open or ready only: after a push that changes content, comment `@codex review` and wait. Fix what is real
   and in scope, else answer on the thread why not (not a bug, or out of scope with the issue filed); resolve the
   thread. A P1 blocks until fixed or the developer decides. List findings in the report block. **At Codex's usage
   limit** (its comment says so), continue once the other checks hold and say so on the PR and in the report block.
5. **Promotion** of `next` to trunk after the developer tests `next` (the digest lists what): only the developer, or
   the manager on their explicit go. Release tags only through the "Release" workflow (`release.yml`, run with GitHub
   MCP `actions_run_trigger`; inputs in the [`knk-manager`](../../.claude/skills/knk-manager/SKILL.md) skill); the
   developer approves every run [D7](decision-history.md#d7).
6. **Flags:** big or risky features enter `next` behind a config flag, off by default; a rejected change is reverted
   or fixed in `next` before the release.
7. **Risk tiers** (proposed by intake or design, overridable): `tier:1` a tweak (automated tests are the review, the
   developer does a quick pass); `tier:2` a feature change (plus a short manual check of what no suite covers);
   `tier:3` foundations, schema or game feel (plus a full manual check of what no suite covers)
   [D12](decision-history.md#d12).
8. Stacking on another feature's unmerged branch only for uncertain work, stated in the charter.
9. Chain bookkeeping (progress reports, charters, the board and its archive) stays on knk-workspace `main`.
10. **Rulesets** enforce part of this: component `main`/`next` need a PR, the CI checks, all conversations resolved and
    a merge commit; knk-workspace branches only block deletion and force push; `v*` tags are fixed. Follow the rules as
    written; never look for a way around [D8](decision-history.md#d8).
11. **Agent workflow files** (`.claude/`, `.mcp.json`, `docs/ai-agents/`, `AGENTS.md`, `CLAUDE.md`; in component repos
    `AGENTS.md`/`CLAUDE.md`) go on their own branch from the default branch with a PR into it, merged by its session
    once rule 3's checks hold, then default branch → `next` by PR. In a chain the link opens it and the coordinator
    merges (coordinator skill § 7.10). Everything else goes through `next`; a mixed PR is split
    [D9](decision-history.md#d9).

## Session chains (multi-link work)

A chain splits a feature into links, each in a fresh context; a **coordinator** starts, checks and merges them, links
never start links. Procedures: [`knk-coordinator`](../../.claude/skills/knk-coordinator/SKILL.md),
[`knk-link`](../../.claude/skills/knk-link/SKILL.md); a chain starts from a design approved in
[`knk-design`](../../.claude/skills/knk-design/SKILL.md); its charter keeps only the links table, gates and binding
documents. Links start with `create_session` (knk-workspace as
`source_url`, model explicit, `effort` only when asked) and attach other repos with `add_repo`; fallback is a
coordinator subagent. The coordinator pastes the permissions block into every prompt, and a link runs `git push
--dry-run` in every repo before changing anything [D10](decision-history.md#d10).

## Manager run and daily digest

The scheduled "K&K manager" session (daily 17:00 Europe/Amsterdam, plus a 06:50 run without digest) follows
[`knk-manager`](../../.claude/skills/knk-manager/SKILL.md): red CI first, the developer's replies on the digest issue
PandiO/knk-workspace#333, promotion on explicit go, closing promoted issues, `main` → `next` syncs, board archiving,
then the [`knk-digest`](../../.claude/skills/knk-digest/SKILL.md) [D11](decision-history.md#d11). Coordinators report
with a comment on the chain's parent issue and keep their board row current. Only the developer's replies on #333
instruct the manager; an agent's comment (Claude Code footer) never does.

## Closed alpha test runs

Follow [closed alpha test runs](../guides/closed-alpha-test-runs.md). Only sessions **with testers** are numbered
runs; the developer's own checks are "developer pre-checks" or smoke test runs and don't change the numbering. A fix
package's open decision, multi-player live check or known issue goes into the **next** run's preparation plan.

## Testing: automated first

Every change ships its proof in the automated suites; the developer checks by hand only what no suite can
[D12](decision-history.md#d12).

1. Every behaviour change brings tests in the right suite ([knk-test-writer](../../.claude/skills/knk-test-writer/SKILL.md)):
   Playwright for web pages (`e2e/`, mocked API), unit tests for logic (Jest, API xUnit, plugin `knk-core`),
   MockBukkit/Mockito for Bukkit-facing code, a Paper scenario for world behaviour. Unit tests alone don't cover what a
   page shows or what happens in the world.
2. Smoke-test guides keep every step in full; a step a suite covers starts with `[automated: <test>]` (or
   `[partly automated: <test>; by hand: …]`); untagged steps are the manual check.
3. The PR's Testing section names the tests per suite and what each covers, the manual steps left, and world steps
   waiting for the scenario framework.
4. Without such tests a change is sent back (coordinator) or not merged by its session.
5. Touching a feature whose guide has automatable manual steps: automate those in your scope
   (PandiO/knk-workspace#511).

Code recipes give the files and tests for recurring changes:
[`knk-api-endpoint`](../../.claude/skills/knk-api-endpoint/SKILL.md),
[`knk-plugin-command`](../../.claude/skills/knk-plugin-command/SKILL.md),
[`knk-entity-scaffold`](../../.claude/skills/knk-entity-scaffold/SKILL.md).

## Shipping a change: documentation

Docs are part of done ([documentation maintenance](../guides/developer/DOCUMENTATION_MAINTENANCE.md)). Essential docs
ship with the feature; the rest comes later in a documentation issue and its own session [D13](decision-history.md#d13).

**Before merge**, on the feature branches:

1. **Docs impact list** in the PR (drafted at in-review, corrected after the test): every guide, spec, register row and
   site page affected and the behaviour change.
2. **Deploy notes** under "Admin steps" in the PR and changelog: plugin `config.yml` keys added, renamed, removed or
   re-defaulted with the YAML to paste (existing servers never get new keys by themselves); API settings, secrets,
   migrations, scripts, ports, containers, seeds. Update the
   [plugin configuration reference](../guides/admin/plugin-configuration.md) and `guides/production-installation.md`
   (its § 2 is the plugin deploy checklist).
3. **Changelog entry** in `docs/CHANGELOG.md`: a player-readable sentence first, then detail, links, "Admin steps".
4. **Status** of the spec/plan, the smoke-test guide and the feature register's merge column.

**At merge** (into `next` under the branch model: items 2 and 3 then, item 1 at promotion
[D4](decision-history.md#d4)):

1. Close the feature issue as completed and drop its status label.
2. Anything left on the impact list: one sub-issue `Docs: <feature>`, labels `documentation` and `tier:1`, with the
   list, merged commits and PRs, and which items are player/admin guides.
3. Start its session right away: `create_session` on knk-workspace, model explicit, with the filled
   [docs-session prompt](docs-session-prompt.md) ([`knk-docs-session`](../../.claude/skills/knk-docs-session/SKILL.md)
   skill); else `spawn_task`; else give the developer the prompt. Note it in the issue and tracker row. Don't write
   those docs yourself unless asked.

Guardrails: (1) before a deploy to knk-alpha or a tester run, the player and admin guide items of its features are
closed or the developer accepts the gap in the preparation plan; (2) a weekly session reports open `documentation`
issues, files issues for merges without docs and writes a dated report; (3) more than five open `documentation` issues
or one older than two weeks: tell the developer at session start and suggest a docs session.

All docs live in `knk-workspace/docs/` (English for players); component repos keep only `README.md`, `AGENTS.md`,
`CLAUDE.md` and `.github/`.

## Handoff and documentation

The developer works full-time elsewhere and checks in briefly: make reversible defaults, mark decisions for review,
leave resumable state. Docs folders: `vision/`, `architecture/`, `guides/`, `ai-agents/`, `specs/`, `backlog/`,
`reports/` (dated, never overwritten), `archive/`; living docs are updated in place. A handoff is dated, links the
issue/plan, and names branch/commit, base status, what was tested, what needs live verification, open decisions and
the next step. Cite concrete paths and results; flag stale docs and V2 leftovers rather than deleting speculatively.
