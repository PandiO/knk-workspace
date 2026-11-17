---
name: knk-docs-session
description: Run a Knights and Kings (K&K) docs session, the documentation follow-up of a merged feature. Use when your prompt says you run a docs session or names a `documentation` issue (`Docs: <feature>`), when the weekly docs check starts one, or when asked to write the remaining guides, register rows, site/wiki pages or screenshots of a merged K&K change. Covers setup (clone the merged code, tracker row), working through the docs impact list against the merged code and test results, code that disagrees with the plan, the branch from knk-workspace `next` (or `main`), merging its own docs PR into `next` after the checks and Codex findings (or the Codex usage-limit rule), agent workflow files via their own PR into `main`, the smoke-guide format, closing the issue and archiving the tracker row.
---

# K&K docs session

You write the docs a merged feature still needs, from its `documentation` issue (`Docs: <feature>`, labelled
`documentation` and `tier:1`). The implementing session shipped the essential docs (docs impact list, deploy notes,
changelog entry, status) and started you with the [starter prompt](../../../docs/ai-agents/docs-session-prompt.md):
the docs issue, the feature issue, the merged commits and PRs. Binding, in this order: the developer's own messages,
your prompt, the [global agent instructions](../../../docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md) ("Branches" rules
3, 4 and 11, "Shipping a change") and [documentation maintenance](../../../docs/guides/developer/DOCUMENTATION_MAINTENANCE.md).
If your prompt says something different from this skill, the prompt wins.

## 1. Setup

1. **Repos.** knk-workspace is attached. The code repos are public: clone what you need read-only with
   `git clone --depth 1 -b <branch> https://github.com/PandiO/<repo>` at the branch your prompt names (`next`, or
   `main` before the branch model applies or for a release); check out the named commit when you need the exact state.
   Attach a private repo (knk-dev-db-seed) with `add_repo` (access read) only when your prompt asks for it.
2. **Read first.** `AGENTS.md`, the global instructions, the maintenance guide, the "In progress" table of
   `docs/ACTIVE_SESSIONS.md` read fresh (`git fetch origin`, then `git show origin/main:docs/ACTIVE_SESSIONS.md`),
   the docs issue **with its comments**, the feature issue, the merged PRs
   (their "Docs impact" and "Testing" sections) and the smoke-test guide with its results.
3. **Debt cap.** List the open `documentation` issues. More than five, or one older than two weeks: say so in your
   final message, so the developer can plan the next docs session.
4. **Tracker row.** Add a row for the docs issue to "In progress" on knk-workspace `main` (a detached worktree on
   `origin/main`, one commit, push `HEAD:main`; on a conflict fetch, rebase and keep both rows). Set the docs issue to
   `status:in-progress`.
5. **Base and branch** on knk-workspace (§ 3.1): `claude/docs-<docs issue>` from `origin/next` when the code is in
   `next`, else from `origin/main`. Run `git push --dry-run origin claude/docs-<docs issue>` before changing
   anything; a failure is a blocker (§ 5).

## 2. Writing the docs

1. **Work through the docs impact list** in the issue, item by item, against the merged code and the smoke-test
   results, not the plan. Typical items: player guide, admin guide, developer guide or architecture doc, the feature
   register row (implementation and verification columns), the row in the guides index `docs/guides/README.md`,
   site/wiki pages, screenshots.
2. **Guide minimums** (maintenance guide § Guide minimums):
    1. Player: who can use it, how to reach it, an example command or menu path, costs, cooldowns and rewards, what a
       denial or error means, what other players see. English, in the terms the current UI uses.
    2. Admin: prerequisites, permissions, config and form steps, world setup, a safe test procedure, effects on
       existing data, likely failures. Point to the player guide instead of repeating it.
    3. Developer: architecture and ownership, schema/API/permission contracts, configuration and migration, setup,
       tests and recovery, source links and limitations.
3. **Code wins over the plan.** When the code disagrees with the issue, the plan or the smoke test, document what the
   code does and file a `bug` or decision issue for the difference. Never document unmerged or unverified behaviour
   as shipped; keep intended, implemented and verified apart.
4. **Smoke-test guides and checklists** you touch keep every step in full, and a step an automated suite covers
   starts with `[automated: <test>]` (or `[partly automated: <test>; by hand: …]`), as in
   [knk-test-writer § 4](../knk-test-writer/SKILL.md). When a guide step differs from what the code or the test showed,
   amend the step; don't shorten it to the manual part.
5. **Headers and addresses.** Living documents get `**Status:** … · **Last updated:** YYYY-MM-DD (reason)`; older
   history goes to `## Changes`. No private addresses, personal domains or secrets (maintenance guide § Addresses and
   hostnames).
6. **Consistency.** Search for the feature's old names and commands and correct current guides (leave dated reports
   and `docs/archive/` alone); check every relative link you add resolves.
7. **Scope.** Docs only. A code bug, a gap you can't close, a guide that needs a decision, screenshots that need a live
   server: file a new `documentation` (or `bug`) issue and name it in the closing comment. Don't change code.
8. **Commits** in logical chunks. Messages never name the AI model and end with
   `Co-Authored-By: Claude <noreply@anthropic.com>` and `Claude-Session: <your session URL>`.

## 3. Merging

1. **Two routes, by base.**
    1. Base `next` (the global branch model applies): take `next`'s updates by **merge**, never rebase, then open the
       docs PR into `next` and merge it yourself (§ 3.2), so the docs reach `main` with the feature's promotion
       ("Branches" rules 3 and 4; the docs issue counts as `tier:1`, developer decision 2026-11-13).
    2. Base `main` (before the branch model, or docs of a release already on trunk): rebase on `main` and merge into
       `main`.
2. **Before you merge:**
    1. The PR body follows [templates.md § 1](templates.md): the docs issue (`Closes PandiO/knk-workspace#<docs
       issue>`), the files, what differs from the plan and the issues filed.
    2. Checks pass on the head (knk-workspace has no CI; then your link check counts).
    3. **Codex findings:** once the "Codex Review Summary" shows the review for your head, read every inline finding,
       fix what is real and in scope, otherwise answer on the thread why not, and resolve the thread. After a push
       that changes the PR's content, comment `@codex review` and wait for that review. When Codex answers that its
       usage limit is reached, merge without it and say so on the PR (developer decision 2026-11-14).
    4. Merge with a merge commit.
3. **Agent workflow files** (`.claude/`, `.mcp.json`, `docs/ai-agents/`, `AGENTS.md`, `CLAUDE.md`) never go into the
   docs PR ("Branches" rule 11). Put them on their own branch from `main` with a PR into `main`, merge it after the
   same checks, then merge `main` into `next` through a PR from that branch and merge that too. A PR that mixes both
   is split.

## 4. Finishing

1. **Close the docs issue** as completed with the closing comment of [templates.md § 2](templates.md): PRs and merge
   commits, the files, issues filed, what is left over. Drop its status label.
2. **Archive the tracker row:** move it from "In progress" straight into
   `docs/reports/sessions-archive/<YYYY-MM>.md` (current month, newest first, the entry format of
   [templates.md § 3](templates.md)), not to "Recently completed". One commit on top of `origin/main`, push
   `HEAD:main`.
3. **Leftovers** become new `documentation` issues (`tier:1`), named in the closing comment and the archive entry.
4. **Final message**, numbered: PRs and merge commits, files, issues filed, leftovers, the debt-cap note (§ 1.3),
   what the developer must do.
5. **Writing rules:** number every list in comments, PR bodies and messages. Every GitHub comment, issue body and PR
   body ends with a line `---` and then `_Generated by [Claude Code](https://claude.ai/code)_`.

## 5. Blockers

1. Blockers: the dry-run push fails; a clone or a requested `add_repo` is refused; a merge conflict that is not
   mechanical; a P1 Codex finding you cannot fix; the docs need a decision only the developer can make and there is
   no reversible default.
2. On a blocker: push what you have to your branch, comment on the docs issue (what, evidence, proposal), leave the
   tracker row `status:blocked` with a one-line reason, and say it in your final message.
3. Never a blocker: a live check or a screenshot that needs a server (file a `documentation` issue), a detail the
   sources leave open (take the reversible default and name it, with the alternatives, in the closing comment).
