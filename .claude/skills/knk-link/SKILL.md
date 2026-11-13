---
name: knk-link
description: Run one link of a Knights and Kings (K&K) session chain. Use when your prompt says you run a K&K chain link (a link of a chain, "L<n>", a chain charter or a coordinator that started you), or when asked to run a K&K chain link. Covers setup (repos, branch from `next` or the default branch, merge-not-rebase of the base, push dry run, toolchains including JDK 25 for the plugin, baseline tests), hard rules, blockers, the pull request, the report block with agent decisions and their alternatives, and numbered lists.
---

# K&K chain link

You run **one** link of a chain, scoped by one sub-issue in `PandiO/knk-workspace`. A coordinator started you and
checks your result; you never start another link. Binding, in this order: the developer's own messages, your prompt,
the chain charter (`docs/ai-agents/handoffs/<FEATURE>_CHAIN.md`), its binding documents, the
[global agent instructions](../../../docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md). If your prompt or charter says
something different from this skill, the prompt and charter win.

## 1. Setup (before changing anything)

1. **Repos.** Your prompt's § 0 permissions block names them.
    1. Started with `create_session` (the preferred route): attach each missing repo with `add_repo` (owner `PandiO`,
       the access named), clone it and register it with `register_repo_root`, because the prompt asks you to; a
       permission rule in knk-workspace `.claude/settings.json` allows both tools. An `add_repo` refusal is a blocker
       (§ 4); say so at once, the coordinator reruns you as a subagent (the fallback).
    2. Run as a subagent: the repos at `/home/user/<repo>` are the coordinator's checkouts. Do not switch branches or
       commit there; work in worktrees (`git worktree add -b <branch> <scratchpad>/<link>/<repo> origin/<base>`) and
       remove the worktrees, not the branches, at the end.
2. **Read first.** The global instructions; `AGENTS.md` and `CLAUDE.md` of every repo you change; the charter and the
   binding sections for your link; your sub-issue **with its comments**; earlier link blocks in the progress report
   ("Notes for later links"); the "In progress" table of `docs/ACTIVE_SESSIONS.md` on `origin/main`. Another row that
   claims your files: follow the coordinator's note. Without one, it blocks you only when its branch changes the same
   lines or the claim is active on the same area (stop and flag it, § 4); additive edits elsewhere in the file go ahead
   and are logged as an agent decision with alternatives (§ 5).
3. **Base branch.** Your prompt names it. Without one: `next` once the branch model applies (CI workflow
   `.github/workflows/ci.yml` on knk-web-api `master` and knk-web-app `main`), otherwise the repo's default branch
   (`master` for knk-web-api, `main` for the others). Never start from another feature's unmerged branch unless the
   charter stacks you on it.
4. **Branch.** The link's feature branch in every repo you change. Missing: create it from `origin/<base>`. Existing
   (a later link of the same feature): check it out, pull, and **merge** (never rebase) `origin/<base>` into it, at the
   start and again before the final push. A non-mechanical conflict is a blocker.
5. **Push check.** `git push --dry-run origin <branch>` in every repo you will change. A failure is a blocker.
6. **Status.** Set your sub-issue to `status:in-progress`.
7. **Toolchains** (install only what your repos need):
    1. .NET 8: `sudo apt-get install -y dotnet-sdk-8.0` if `dotnet --list-sdks` has no 8.0.
    2. Node 22; dependency changes in the web app with npm 11 only (`npx npm@11 ...`), the lock file is invalid for
       npm 10.
    3. Plugin: Gradle runs on JDK 21 and compiles with a **JDK 25** toolchain. Install `openjdk-25-jdk-headless`, else
       a Temurin 25 tarball from `api.adoptium.net` into `/opt/jdk-25`, passed with
       `-Porg.gradle.java.installations.paths=/opt/jdk-25`. No JDK 25 is a blocker.
8. **Baseline** on the unchanged branch, recorded before your first change (keep output short):

   | Repo | Commands |
   |---|---|
   | knk-web-api | `dotnet build`, `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` |
   | knk-web-app | `npx npm@11 ci`, `npm run test:ci`, `npx tsc --noEmit`, `CI=true npm run build` |
   | knk-plugin | `./gradlew build -x deployToDevServer` (a plain `./gradlew build` copies the jar to the dev server) |
   | knk-workspace | docs only: check that the markdown links you add resolve |

   A test that is also red on the base is a known red: record it, it is not a blocker. MySQL tests skip without
   `KNK_TEST_MYSQL`; say so when they were skipped.

## 2. Hard rules

1. **Scope:** only your sub-issue. Anything else you find (a bug in passing, a follow-up, a gap) gets a new issue or a
   comment on the issue that covers it, and a line in your report block. Do not fix it.
2. **Design is binding.** A real conflict between the binding documents and the code is a blocker with a short
   proposal, not a silent change. Details the documents leave open: take the most reversible default and log it as an
   agent decision (§ 5).
3. **Branches:** push only to your link's branch. Never push to a default branch or to `next`, never merge into them,
   never force-push, never delete branches. The exceptions are chain bookkeeping on knk-workspace `main` (§ 3.6) and changes to agent workflow
   files (`.claude/`, `.mcp.json`, `docs/ai-agents/`, `AGENTS.md`, `CLAUDE.md`), which go to the default branch by
   their own PR (global instructions, "Branches" rule 10).
4. **Behaviour-neutral where the charter says so.** Big or risky work (normally `tier:3`) goes behind the charter's
   config flag, off by default, so it is harmless in `next`.
5. **Migrations:** only where the charter allows, at most one per link, additive, made with `dotnet ef migrations add`.
   Data cleanups are scripts the developer runs after a backup, never migrations.
6. **API:** every new endpoint gets an explicit access rule (see knk-web-api `CLAUDE.md`, default-deny).
7. **Secrets:** none in code, settings, fixtures, logs or docs.
8. **Tests:** unit tests for new logic, next to the existing ones. Plugin tests never build a `Location` around an
   inline `mock(World.class)`.
9. **Writing:** number every list in reports, PRs, comments and messages (DESIGN § 4.6), never dashes or bullets.
   Code and docs never name the AI model. Every GitHub comment, issue body and PR body ends with the line `---` and
   then `_Generated by [Claude Code](https://claude.ai/code)_`.
10. **Commit trailers:** commit messages end with `Co-Authored-By: Claude <noreply@anthropic.com>` plus the
    `Claude-Session: <session URL>` line, and never name the model, even when the platform's attribution reminder
    suggests a model-named trailer (developer rule, reconfirmed 2026-11-12).
11. **Docs:** the essential docs ship with your branch (global instructions, "Shipping a change"): the docs impact
    list, deploy notes (plugin `config.yml` keys with the YAML, API settings, migrations), spec and smoke-test status,
    and a smoke-test section in `docs/guides/` when the change needs a live check.

## 3. Finishing

1. **Commits** in logical chunks with the trailer of § 2.10; push after each chunk.
2. **Compare with the baseline:** rerun the same commands. Tests must be at or above the baseline apart from known
   reds; new tests are counted separately.
3. **Pull request** per changed repo, against your base (`next` or the default branch), with the repo's
   `.github/pull_request_template.md` filled in: Summary, Testing (baseline → result), Docs impact, Admin steps,
   Changelog. `Closes PandiO/knk-workspace#<sub-issue>` in exactly one PR (the main repo of the link, normally
   knk-workspace or the first one); `Part of PandiO/knk-workspace#<sub-issue>` in the others, so an early merge does
   not close the issue. Do not merge (the coordinator does). Check that CI on the PR goes green where CI exists; a red
   run you caused is yours to fix.
4. **Codex findings** (global "Branches" rule 4, developer decision 2026-11-13): once the ChatGPT Codex connector has
   reviewed the PR (its "Codex Review Summary" comment shows the review completed for your head commit), read every
   inline finding: fix what is real and in scope and push; otherwise answer on the finding's thread why not (not a bug,
   or out of scope with the issue you filed); resolve the thread. A P1 finding you cannot fix is a blocker. List the
   findings and what you did in your report block. Codex reviews only when a PR is opened or marked ready (or on a
   `@codex review` comment), not on every push: after any push that changes the PR's content (code or docs), comment
   `@codex review` and handle the new findings before you finish.
5. **Sub-issue:** a comment with branches, heads, PRs, tests vs baseline and decisions to review; swap
   `status:in-progress` for `status:in-review`.
6. **Report block** in the chain's progress report on knk-workspace `main`: append it under "## 4. Link blocks" in the
   format of the link block in `.claude/skills/knk-coordinator/report-template.md`, and update your summary row.
   Commit only that file on top of `origin/main` (a separate detached worktree) and push `HEAD:main`; on a conflict
   fetch, rebase that one commit and keep both sides. Do not edit the sessions board unless your prompt says so;
   when it does, a finished row moves straight into `docs/reports/sessions-archive/<YYYY-MM>.md` (current month,
   newest first), not to "Recently completed".
7. **Final message** to the coordinator, numbered: PR links, heads per repo, tests baseline → result, decisions,
   blockers, what the developer must do. Then stop; do not start another link.

## 4. Blockers

1. Blockers: `add_repo` refused; clone or dry-run push fails; a changed module does not build or its tests fail and
   you cannot fix it; an untouched test starts failing and you cannot explain it; a base merge conflicts
   non-mechanically; an expensive-to-undo decision the binding documents don't settle and that has no reversible
   default; another "In progress" claim conflicts with your files; a plugin link without JDK 25.
2. On a blocker: stop, push what is green to your branch, write the blocker in your report block (what, evidence,
   proposal), comment on the sub-issue, and tell the coordinator in your final message. The coordinator decides.
3. Never a blocker: a live test (write the checklist instead), details the documents leave open (reversible default,
   logged as a decision), steps your tools cannot do (as of 2026-11-12 the GitHub MCP tools cannot create labels or
   pin issues): list them under "What the developer must do".

## 5. Agent decisions

Every choice you make that the binding documents did not settle is logged as made by the agent (DESIGN § 4.3), in
your report block and, when it matters to the reviewer, in the PR:

1. *Topic.* Chosen: the option, and why.
2. Alternatives: every other option considered, each with why not, lettered (a), (b), ...

Larger choices (a framework, technology or library) are not yours: write a decision matrix (options, pros and cons,
weighted considerations, recommendation) and leave the decision to the developer (DESIGN § 4.4). The digest lists the
decisions for review, so keep them short and findable.
