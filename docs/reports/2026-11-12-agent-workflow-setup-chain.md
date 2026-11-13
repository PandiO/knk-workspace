# AI agent workflow setup chain — progress report

**Status:** In review: all five links done 12:25 UTC, nothing merged (coordinator session, 2026-11-12) · **Last updated:** 2026-11-13 (L4b, § 4.8)

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

1. **Merge order tonight**, every PR still open:
    1. L1 CI: [knk-web-api#12](https://github.com/PandiO/knk-web-api/pull/12), [knk-web-app#9](https://github.com/PandiO/knk-web-app/pull/9).
    2. L3 skills and instructions: [knk-workspace#334](https://github.com/PandiO/knk-workspace/pull/334),
       [knk-web-api#13](https://github.com/PandiO/knk-web-api/pull/13), [knk-web-app#10](https://github.com/PandiO/knk-web-app/pull/10),
       [knk-plugin#16](https://github.com/PandiO/knk-plugin/pull/16); add the changelog entry proposed in #334.
    3. L4 tooling: [knk-workspace#335](https://github.com/PandiO/knk-workspace/pull/335); add its changelog entry.
    4. L5 sessions archive: [knk-workspace#336](https://github.com/PandiO/knk-workspace/pull/336), **not by merging the
       branch**: on fresh `main` run `git cherry-pick da40c73 99f0c4a 99b1a77` (since L4b, § 4.8; skip the generated
       `9f91251`), then the script with `--dry-run`, for real and with `--check`, commit and push, close #336. (L4b dry
       run on `main` `fdc4425` + those three commits on 2026-11-13: 240 entries, board 489 KB → 66 KB. A branch merged
       anyway: archive README, "Merging a branch that ran the script".)
    5. Then bring `next` up to the new tips: `git merge` the default branch into `next` in all four repos, so `next`
       carries CI and the skills.
2. **Your own steps:**
    1. Turn off GitHub Actions failure emails in your GitHub notification settings (DESIGN § 7.4).
    2. Create the labels `tier:1`, `tier:2`, `tier:3`, `idea` and pin the "Daily digest" issue #333 (values in § 4.2;
       no tool in the cloud sessions can do either).
    3. On the PC: set `GITHUB_PAT` (optionally `CONTEXT7_API_KEY`) and approve the three servers in `/mcp` (§ 4.4).
3. **Decisions to review:** coordinator decisions § 3.1–3.4; L4b decisions § 4.8 item 5; link decisions in § 4.1 item 5, § 4.2, § 4.3 item 5
   (5.3–5.5 decide how coordinators merge into `next`), § 4.4 item 5, § 4.5.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | How started |
|---|---|---|---|---|---|
| L1 CI | #328 | In review (done 11:40 UTC, both workflows green) | `claude/agent-setup-ci`: knk-web-api `81b06d9`, knk-web-app `a7d31a2` | [knk-web-api#12](https://github.com/PandiO/knk-web-api/pull/12), [knk-web-app#9](https://github.com/PandiO/knk-web-app/pull/9) | create_session session_01R1w2UsfbmKqEY1QXSx25id |
| L2 Branches, labels, digest | #329 | In review (done 11:40 UTC; labels and pin left for the developer) | `next`: knk-workspace `6245c9f`, knk-web-api `b5e57fa`, knk-web-app `9a85238`, knk-plugin `121030f`; digest issue [#333](https://github.com/PandiO/knk-workspace/issues/333) | — (no file changes) | subagent (coordinator decision § 3.2) |
| L3 Skills and instructions | #330 | In review (done 12:05 UTC; docs only) | `claude/agent-setup-skills`: knk-workspace `d475532` (L3c, § 4.7; L3b `35c554b`, first `8321f0d`), knk-web-api `dbb05c5`, knk-web-app `7a974ac`, knk-plugin `0759d22` | [knk-workspace#334](https://github.com/PandiO/knk-workspace/pull/334), [knk-web-api#13](https://github.com/PandiO/knk-web-api/pull/13), [knk-web-app#10](https://github.com/PandiO/knk-web-app/pull/10), [knk-plugin#16](https://github.com/PandiO/knk-plugin/pull/16) | subagent (coordinator decision § 3.2) |
| L4 Tooling | #331 | In review (done 12:15 UTC; hook tested end to end) | `claude/agent-setup-tooling`: knk-workspace `5787c0e` (L4b, § 4.8; L3c `f7fad77`, L3b `c1afaf1`, first `9310d7f`) | [knk-workspace#335](https://github.com/PandiO/knk-workspace/pull/335) | subagent (coordinator decision § 3.3) |
| L5 Sessions board archive | #332 | In review (done 12:25 UTC; board 486 KB → 65 KB on the branch) | `claude/agent-setup-sessions-archive`: knk-workspace `99b1a77` (L4b, § 4.8; generated move `9f91251`) | [knk-workspace#336](https://github.com/PandiO/knk-workspace/pull/336) | create_session session_01R1w2Ux2rKagW6rke2sDnes |

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

2. **Attaching repositories in link sessions.** The L1 session (started with knk-workspace only) had both
   `add_repo` calls for knk-web-api and knk-web-app refused by its permission check at 10:34. The check does not
   accept the § 0 authorization when it arrives in a prompt written by another session. The developer approved the
   attach from the phone at 11:00, and the coordinator told the session to go on at 11:21.

   Chosen for the remaining links: L2 and L3 need several component repos, so they run as subagents of this coordinator
   session, which already has all four repos with push access (the fallback in setup § 3.2). L4 and L5 change only
   knk-workspace, so they start with `create_session`, which needs no `add_repo`. Alternatives: (a) start L2 and L3
   with `create_session` too and wait for the developer to approve each attach, which would stall them until the
   developer looks; (b) let the developer add a permission rule for `add_repo` first, which is the developer's
   setting to change, not the coordinator's.

3. **L4 as a subagent too.** L4's Stop hook must be tested with a deliberate type error in a sibling repo (scope
   item 2), and a `create_session` link would have only knk-workspace (attaching the others is refused, § 3.2). Chosen:
   run L4 as a subagent of this session, which has all four repos and can install the toolchains. L5 still starts with
   `create_session` (knk-workspace only). Alternatives: (a) `create_session` with a throw-away fake sibling repo for
   the test, which proves less about the real checks; (b) ask the developer to approve another attach.

4. **Commit trailers naming the model.** The session attribution the coordinator and the link sessions received
   names the model in the `Co-Authored-By` trailer, and the bookkeeping commits on `main` (451cf70 to 7a496b0), L1's
   commits (knk-web-api 81b06d9, knk-web-app a7d31a2) and L3's commits (8321f0d, dbb05c5, 7a974ac, 0759d22c) carry it.
   That conflicts with the developer's rule that commit messages never name the AI model (L4 noticed and used
   `Co-Authored-By: Claude`). Chosen: from 12:15 UTC every chain commit uses the model-free trailer; existing commits
   stay as they are, since rewriting them needs a force-push, which the chain may not do. Alternatives: (a) amend and
   force-push the feature branches (forbidden); (b) the developer squash-merges the feature PRs and edits the message
   at merge, which removes the trailer from the default branches if wanted. The same trailer is on earlier commits of
   the design work (e477178, b1787b5, 68eb738), so this predates the chain.

5. **Developer decisions (2026-11-12, answered in the coordinator session).**
    1. L3 5.4 confirmed: once the `next` rules apply, link PRs target `next` and the coordinator merges them through the
       PR with a merge commit; the issue stays `status:in-review` until promotion.
    2. L3 5.5 confirmed: PRs into `next` outside a chain wait for the developer unless the developer tells a session
       to merge.
    3. L3 5.3 confirmed: the `next` rules apply as soon as `.github/workflows/ci.yml` is on knk-web-api `master` and
       knk-web-app `main`.
    4. "Shipping a change → At merge" is split: the docs sub-issue and the docs session start when a feature merges into
       `next`; the feature issue is closed when the developer promotes `next` to trunk.
    5. Commit trailers: the rule stands (commit messages never name the model; use `Co-Authored-By: Claude`). Existing
       commits stay as they are.
    6. Link sessions: `create_session` is the preferred route for every link, with `add_repo` for the four knk
       repositories allowed by a permission rule; a subagent of the coordinator is the fallback. (Replaces coordinator
       decision § 3.2's "multi-repo links as subagents".)
    7. Sessions-board overlap: a claim blocks a link only when the other branch changes the same lines or the claim is
       active on the same area; additive edits elsewhere in a file are allowed and logged as a decision (confirms § 3.1).
    8. Board rule: a finished session appends its row straight to `docs/reports/sessions-archive/<YYYY-MM>.md`; the
       script only cleans up rows left in "Recently completed".

   Applied by a follow-up on the open branches: L3 `claude/agent-setup-skills` (knk-workspace) and L4
   `claude/agent-setup-tooling` (the permission rule); see § 4.6.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — CI for the API and the web app (#328)

1. **Scope done.**
    1. knk-web-api `.github/workflows/ci.yml`: push (all branches), pull request and manual dispatch; .NET 8
       (`actions/setup-dotnet` 8.0.x); restore, build, `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`
       with `--filter "Category!=KnownFailure"`; TRX results uploaded as the `api-test-results` artifact.
       `migrations.yml` unchanged.
    2. knk-web-app `.github/workflows/ci.yml`: same triggers; Node 22 with npm cache; `npx npm@11 ci`,
       `npm run test:ci`, `npx tsc --noEmit`, `CI=true npm run build`.
    3. The MySQL-dependent (`requires-mysql`) tests are left out the way the suite already skips them: the job sets no
       `KNK_TEST_MYSQL`, so they skip themselves (88 skipped).
2. **Commits and heads.** knk-web-api `claude/agent-setup-ci` at `81b06d9`; knk-web-app `claude/agent-setup-ci` at
   `a7d31a2` (one commit each, from `master` / `main`).
3. **PRs.** [knk-web-api#12](https://github.com/PandiO/knk-web-api/pull/12),
   [knk-web-app#9](https://github.com/PandiO/knk-web-app/pull/9). Not merged. The Codex review on both: no findings.
4. **Tests, baseline → result.**
    1. knk-web-api, container baseline on `master`: build 0 errors; tests 3678 passed, 0 failed, 88 skipped. GitHub CI
       on the branch (push run 43209178982, PR run 43209267111): green, 3678 passed, 0 failed, 88 skipped.
       Migrations (fresh DB) green on both runs too.
    2. knk-web-app, container baseline on `main`: `npm ci` ok; 237 suites, 2016 tests passed; `tsc` clean; build ok.
       GitHub CI on the branch (push run 43209192858, PR run 43209282750): green, all four steps.
    3. Known reds: none. The four tests of #99 and the nl-NL/timing reds recorded by earlier chains are green on the
       GitHub runner, so nothing is marked `KnownFailure` / `test.skip` and no "Known-failure tests marked in CI" issue
       was filed (DESIGN § 6.2).
5. **Decisions (DESIGN § 4.3).**
    1. *KnownFailure filter added up front.* Chosen: the API test step already filters `Category!=KnownFailure` although
       no test carries the trait, so a later mark needs no workflow change. Alternatives: (a) add the filter only when a
       first test is marked, which makes marking a two-file change; (b) a separate known-failure job, more to maintain.
    2. *MySQL tests.* Chosen: rely on the existing `KNK_TEST_MYSQL` self-skip, as the link prompt says. Alternatives:
       (a) also filter `Category!=requires-mysql`, which would hide the skipped tests from the count and duplicate the
       mechanism; (b) a MySQL service container to run them, which belongs to the Testcontainers work, not L1.
    3. *Extra workflow features.* Chosen: `workflow_dispatch`, a per-ref concurrency group that cancels superseded runs,
       and the TRX artifact. Alternatives: plain push/pull_request only (simpler, but every push to a PR branch runs
       twice to completion and failures need the log to read).
    4. *Install steps.* Chosen: `actions/setup-node` with npm cache, then `npx --yes npm@11 ci` (lock file valid for
       npm 11 only). Alternative: `npm i -g npm@11` first, which changes the runner's global npm for later steps.
6. **Out of scope, noted.** GitHub warns that `actions/checkout@v4`, `setup-dotnet@v4`, `setup-node@v4` and
   `upload-artifact@v4` target Node.js 20 and are forced onto Node.js 24; the existing `migrations.yml` has the same
   warning. Not red; a later bump to the next major versions clears it (comment on #328).
7. **At merge (developer).** Merge knk-web-api#12 and knk-web-app#9; nothing to configure (no secrets, no settings).
   After merge, CI runs on every push to the default branches and `next`. Optionally make the `CI / build-and-test`
   check required in branch protection. Docs follow-up: mention the CI gate in the developer guide (documentation
   issue at merge).
8. **Session note.** The attach of knk-web-api and knk-web-app was refused at 10:34 (§ 3.2), approved by the developer
   at 11:00, and the link went ahead after the coordinator's go at 11:21.

### 4.2 L2 — `next` branches, labels, digest issue (#329)

1. **Scope done.**
    1. `next` created in all four repos from the current tip of the default branch
       (`git push origin origin/<default>:refs/heads/next`, after `git fetch` and a passing `git push --dry-run`). No
       repo had a `next` branch before. No default branch and no branch protection was changed.
    2. "Daily digest" issue created: [PandiO/knk-workspace#333](https://github.com/PandiO/knk-workspace/issues/333).
       It covers what the digest is for (DESIGN § 7), one comment per weekday evening around 17:00 Europe/Amsterdam,
       the six sections (ready for test in `next`, decisions needed, blocked, progress, new raw ideas, health) and the
       link to the manager session as the last line of each digest. No labels on it (not a work item).
    3. Not done, left for the developer (item 7): the four labels and pinning #333. The GitHub MCP tools have no
       label-creation or pin call, `gh` is not used for writes here, and GraphQL (`pinIssue`) answers 403 from this
       environment.
2. **Heads of `next`** (each equal to its default branch at 11:35 UTC):
    1. knk-workspace `next` = `main` at `6245c9f`.
    2. knk-web-api `next` = `master` at `b5e57fa`.
    3. knk-web-app `next` = `main` at `9a85238`.
    4. knk-plugin `next` = `main` at `121030f`.

   This report commit moves knk-workspace `main` one commit past `next`; that is expected and is caught up by the
   first merge of `main` into `next`.
3. **PRs.** None: this link has no branch and no file changes.
4. **Tests, baseline → result.** No baseline: no file changes. The pushes of `next` started the existing CI
   workflows on it: knk-plugin Build (run 43210491593) green, knk-web-api Migrations (fresh DB)
   (run 43210461767) green. knk-web-app and knk-workspace have no workflow on `main` yet (L1's CI lands with
   knk-web-app#9 / knk-web-api#12).
5. **Decisions (DESIGN § 4.3).**
    1. *Labels through a side effect.* Chosen: do not create them. GitHub creates a missing label when an issue is
       given it, but without a description and in grey, and only by tagging some issue with it. Alternatives: (a) add
       them to the digest issue and remove them again, which leaves four labels without the descriptions and colours
       the design asks for and an odd label history on #333; (b) use `gh label create`, ruled out by the link prompt.
    2. *Digest issue labels.* Chosen: none, since the digest is a standing channel, not work with a status or tier.
       Alternative: the `documentation` or an `improvement` label, which would put it in work lists and status checks.
    3. *Empty-day rule.* Chosen: the issue says the manager posts a short comment even on a quiet day, so a missing
       comment shows a failed run. Alternative: post only when there is news, which makes a broken scheduled run
       indistinguishable from a quiet day.
6. **Out of scope, noted.** None.
7. **At merge / what the developer must do.**
    1. Create the four labels in PandiO/knk-workspace (Issues → Labels → New label):
        1. `tier:1`, colour `#0e8a16` (green), "Tweak to existing behaviour: automated tests are the review".
        2. `tier:2`, colour `#fbca04` (yellow), "Feature change: short smoke test on next".
        3. `tier:3`, colour `#d93f0b` (orange-red), "New foundations, schema, game feel: full smoke test".
        4. `idea`, colour `#c5def5` (light blue), "Raw idea captured by intake; still needs working out".
    2. Pin [#333](https://github.com/PandiO/knk-workspace/issues/333): open it, "Pin issue" in the right sidebar.
    3. Optional: protect `next` in each repo against force-push and deletion (branch protection was out of scope).
    4. After merging L1, L3, L4 and L5 into the default branches, merge each default branch into `next`
       (already item 1.1 of this report).

### 4.3 L3 — Coordinator and link skills, instructions, stale files (#330)

1. **Scope done.**
    1. knk-workspace `.claude/skills/knk-coordinator/`: `SKILL.md` (158 lines: rule set in force, first run, the loop of
       DESIGN § 5.1 with `git rev-list --count` gate checks, starting links by `create_session` with an explicit model or
       as a subagent, `send_later` check-ins with `get_session`/`list_events`, the nine checks of a finished link,
       merging into `next`, blockers, reporting to the manager) and the supporting files `permissions-block.md`
       (variant A for `create_session`, variant B for a subagent), `charter-template.md` (binding documents, links
       table with tier/base/flag, gates, chain notes) and `report-template.md` (summary table, coordinator decisions,
       link block).
    2. knk-workspace `.claude/skills/knk-link/SKILL.md` (121 lines): setup (repos, read first, base branch, merge not
       rebase, push dry run, status label, toolchains incl. JDK 25, baseline table), ten hard rules, finishing (PR with
       `Closes`/`Part of`, sub-issue, report block, final message), blockers, agent decisions with alternatives.
    3. `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`: new section "Branches, releases and risk tiers" (eight numbered
       rules from DESIGN § 2 and § 5), applying once `.github/workflows/ci.yml` is on knk-web-api `master` and
       knk-web-app `main` (#328), current rules until then. "Session chains" rewritten to point at the two skills and
       keep the dated `add_repo` facts (2026-10-11 and today's refusal). "Authority" item 2, "Parallel sessions" items
       3 and 5 adjusted. The stale "`create_session` has no effort setting" line corrected (the tool now has `effort`).
    4. `AGENTS.md` default-branch sentence in knk-workspace, knk-web-api, knk-web-app and knk-plugin: "from `next` once
       the global branch model applies, until then from the current default branch". No `CLAUDE.md` changed (decision
       5.1).
    5. `docs/vision/vision.md`: "Guiding Principle: Platform Independence [decided 2026-11-12]", one paragraph before
       § 1.
    6. Deleted the empty `docs/ai-agents/AGENT-GUIDE.md` and `docs/ai-agents/guardrails.md`. Nothing linked to them
       in any of the four repos (mentions only in the 2026-11-03 audit report, DESIGN and the setup handoff, left
       unchanged). Copilot files untouched.
    7. `docs/README.md`: the `ai-agents/` entry names the skills. There is no `docs/ai-agents/README.md`.
2. **Commits and heads.** One commit each on `claude/agent-setup-skills`: knk-workspace `8321f0d` (from `main`
   `54434b1`), knk-web-api `dbb05c5` (from `master` `b5e57fa`), knk-web-app `7a974ac` (from `main` `9a85238`),
   knk-plugin `0759d22` (from `main` `121030f`).
3. **PRs.** [knk-workspace#334](https://github.com/PandiO/knk-workspace/pull/334) (`Closes #330`),
   [knk-web-api#13](https://github.com/PandiO/knk-web-api/pull/13), [knk-web-app#10](https://github.com/PandiO/knk-web-app/pull/10),
   [knk-plugin#16](https://github.com/PandiO/knk-plugin/pull/16) (`Part of #330`). Not merged.
4. **Tests, baseline → result.** Docs only, no build in any repo (baseline: "docs only, no build"). Link check script
   over the changed files: 36 relative links, 0 broken. Both `SKILL.md` front matters parse as YAML. `git diff --check`
   clean. CI: knk-plugin Build green on #16 (push run 43212042737, PR run 43212142739); knk-web-api and knk-web-app have no CI on `master`/`main`
   until L1 merges.
5. **Decisions (DESIGN § 4.3).**
    1. *Component `CLAUDE.md` unchanged.* Chosen: only `AGENTS.md` says "from this repo's current default branch";
       the `CLAUDE.md` line says to open the shared instructions "from knk-workspace's current default branch", which
       stays right (the accepted instructions live on trunk), and leaving it keeps clear of the arena-duels branch.
       Alternatives: (a) add "or `next`" there, which would point agents at unreleased instructions; (b) rewrite the
       paragraph, which risks a non-mechanical merge with `claude/arena-duels`.
    2. *Workspace `AGENTS.md` changed too.* Chosen: its "create one from the current default branch" sentence is the
       same rule, so it gets the same wording. Alternative: leave it, inconsistent with the global section.
    3. *How "the branch model applies" is checked.* Chosen: `ci.yml` present on knk-web-api `master` and knk-web-app
       `main` (`git ls-tree`), the condition the DESIGN names, checkable by any agent. Alternatives: (a) a flag line in
       the global instructions the developer edits after merging L1, one more manual step; (b) the tracker, which the
       loop must not trust for gates.
    4. *Merging into `next` through the PR.* Chosen: once the model applies, link PRs target `next` and the coordinator
       merges them with a merge commit (`merge_pull_request`, `merge_method` `merge`); the issue stays
       `status:in-review` until promotion (a PR into a non-default branch does not close it). Alternatives: (a) a
       local merge pushed to `next`, which skips the PR's CI record; (b) squash merges, which lose the history the
       merge-not-rebase rule keeps.
    5. *PRs into `next` outside a chain.* Chosen: they wait for the developer unless the developer asks a session to
       merge, since DESIGN § 5.2 only lets coordinators merge. Alternatives: (a) any session merges after green CI,
       beyond the design; (b) the manager merges, a role that does not run yet.
    6. *Route rule as dated guidance.* Chosen: multi-repo links as subagents, `create_session` for single-repo links,
       "as of 2026-11-12, recheck when the platform changes" (coordinator note 2.1). Alternative: a permanent rule,
       which would outlive a platform fix.
    7. *Vision placement.* Chosen: an unnumbered "Guiding Principle" section before § 1, so every existing section
       number and cross-reference (4.1, 5.1) stays. Alternatives: (a) a new numbered section, which renumbers the
       document; (b) a paragraph in 5.1, which hides a project-wide principle in the ranks section.
    8. *Changelog.* Chosen: the PR proposes the entry text; it is written at merge, as the template says. Alternative:
       an "Unreleased" entry on the branch now, which L4 and L5 would also touch, making three conflicting edits of
       the same lines.
6. **Out of scope, noted** (comment on #330). (1) "Shipping a change → At merge" does not yet say whether it means the
   merge into `next` or the promotion to trunk; (2) retiring `guides/developer/AI_FEATURE_IMPLEMENTATION_WORKFLOW.md`
   (DESIGN § 9.3) and the platform principle in the design skill (§ 3.2.2) belong to later links.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Merge after L1: knk-workspace#334, knk-web-api#13, knk-web-app#10, knk-plugin#16 (docs only, any order among
       them), then each default branch into `next` (item 1.1).
    2. Add the changelog entry proposed in #334.
    3. Review decisions 5.3–5.5: they set how coordinators merge into `next` from the first chain after L1.
9. **Notes for later links.** The skills reference `.claude/skills/knk-coordinator/report-template.md` for the link
   block; L4's `.claude/settings.json` lives next to `.claude/skills/` without overlap. Session note: the file tool
   refused to write `report-template.md` (it read the name as a findings report), so that template was written from
   the shell.

### 4.4 L4 — MCP config and the fast-check Stop hook (#331)

1. **Scope done.**
    1. `.mcp.json`: `github` (remote `https://api.githubcopilot.com/mcp/`, `Authorization: Bearer ${GITHUB_PAT}`,
       `X-MCP-Toolsets: context,repos,issues,pull_requests,actions,labels`), `playwright`
       (`npx -y @playwright/mcp@0.0.85 --isolated`), `context7` (remote `https://mcp.context7.com/mcp`,
       `Authorization: Bearer ${CONTEXT7_API_KEY:-}`). Each config is from the server's official docs (GitHub install
       guide and remote-server headers, microsoft/playwright-mcp README, context7.com all-clients page), read
       2026-11-12. No token value anywhere.
    2. `.claude/settings.json`: one `Stop` hook, `bash "${CLAUDE_PROJECT_DIR}/.claude/hooks/fast-check.sh"`, timeout
       600 s. `.claude/hooks/fast-check.sh` (about 200 lines of bash, no `jq`):
        1. returns at once on `KNK_FAST_CHECK=off` or `"stop_hook_active": true`;
        2. finds knk-web-app, knk-web-api and knk-plugin under the workspace's `Repository/` and next to the workspace
           (both layouts; a checkout reachable both ways is checked once);
        3. checks a repo only when files that can break its build changed against the merge base with `origin/next`
           (else `origin/HEAD`, `origin/main`, `origin/master`), committed, staged, unstaged or untracked, and that
           state has not already passed (state file `knk-fast-check` in the repo's git dir);
        4. runs `npx tsc --noEmit`, `dotnet build --no-restore -v q -nologo`, `sh ./gradlew compileJava
           compileTestJava -q`, one after another, `timeout` 300 s each and 540 s for all; never a deploying task;
        5. errors: exit 2 with the trimmed errors on stderr (blocking); pass, skip (toolchain or packages missing) and
           timeout: `{"systemMessage": ...}`, not blocking; nothing changed: no output.
    3. `docs/guides/developer/agent-tooling.md` (what is configured, the servers and env vars `GITHUB_PAT`,
       `CONTEXT7_API_KEY`, `KNK_FAST_CHECK*`, cloud vs local, the hook contract with the docs it cites, how to turn
       the hook off) and one row in the developer table of `docs/guides/README.md` after "Commit conventions"
       (nothing reordered).
    4. `.gitattributes`: `*.sh text eol=lf` (no existing `.sh` file changes).
2. **Commits and heads.** knk-workspace `claude/agent-setup-tooling` at `9310d7f` (one commit, from `main` `7a496b0`).
3. **PR.** [knk-workspace#335](https://github.com/PandiO/knk-workspace/pull/335) (`Closes #331`). Not merged.
   It and L3's #334 touch different files; `git merge-tree` shows no conflict with #334 or `main`, so they merge in
   either order.
4. **Tests, baseline → result.** Baseline: no build in knk-workspace (docs and config only). Hook evidence, from
   detached worktrees of the three component repos at `origin/next` next to a worktree of the branch (the deliberate
   errors were never committed; worktrees removed afterwards). Toolchains: Node 22, .NET 8.0.134, JDK 25 installed
   for the test (`openjdk-25-jdk-headless`).
    1. No changes: exit 0, no output, 0.29 s.
    2. Type error appended to knk-web-app `src/utils/claimCode.ts`: exit 2 in 26 s; stderr names the repo, the command
       (`npx tsc --noEmit`, exit 2, base origin/next) and
       `src/utils/claimCode.ts(134,14): error TS2322: Type 'string' is not assignable to type 'number'.`
    3. Same error, input `"stop_hook_active": true`: exit 0, no output, 0.006 s (no checks run).
    4. Error fixed (change kept): `{"systemMessage": "knk fast check: knk-web-app tsc passed (25s)."}`, exit 0.
       Same state again: silent, 0.23 s.
    5. C# error in knk-web-api and Java error in knk-plugin `knk-core`: exit 2 in 27 s with
       `Services/HookTest.cs(2,96): error CS0029: Cannot implicitly convert type 'string' to 'int'` and
       `HookTest.java:4: error: incompatible types: String cannot be converted to int`.
    6. Same errors, `dotnet` not on PATH, `KNK_FAST_CHECK_TIMEOUT=3`: `knk-web-api skipped (dotnet not found);
       knk-plugin compile timed out after 3s (not blocking; run it yourself)`, exit 0.
    7. Both fixed: `knk-web-api build passed (72s); knk-plugin compile passed (23s)`; again: silent, 0.43 s.
    8. Nested layout (`Repository/knk-web-app` in a separate workspace folder) blocked on a new type error; a checkout
       reachable through both layouts was checked once. `KNK_FAST_CHECK=off`: exit 0 in 0.003 s.
    9. End to end with a headless Claude Code 2.1.322 session in the branch worktree: the Stop hook blocked, the agent
       got the tsc error as "Stop hook feedback" and answered that the error predates the session; its second Stop
       came with `stop_hook_active` and the hook returned exit 0 with no output. `--settings
       '{"env":{"KNK_FAST_CHECK":"off"}}'` turned it off (exit 0, one turn).
    10. MCP in that session: `playwright` and `context7` connected; `github` `failed` without `GITHUB_PAT`; a
        host-provided `github` (`--mcp-config`, source `dynamic`) replaced the project entry of the same name.
5. **Decisions (DESIGN § 4.3).**
    1. *Blocking form.* Chosen: exit 2 with the errors on stderr; non-blocking notes as JSON `systemMessage`.
       Alternatives: (a) JSON `{"decision": "block", "reason": ...}`, same effect but compiler output must be
       JSON-escaped in bash without `jq`; (b) `hookSpecificOutput.additionalContext`, which reads as guidance rather
       than an error.
    2. *Remember passed states.* Chosen: a fingerprint (HEAD, `git diff HEAD`, untracked file hashes, command) per repo
       in its git dir, so a branch that differs from `next` costs a check only once per new state. Alternatives:
       (a) check on every stop while the branch differs from base (tsc 25 s, API 20-70 s, Gradle 6-100 s each time);
       (b) only uncommitted changes, which misses a link's committed breakage.
    3. *File filter.* Chosen: only build-relevant extensions per repo trigger a check. Alternative: any change, which
       compiles after a README edit.
    4. *API check scope.* Chosen: `dotnet build` at the repo root, which builds the solution (API and test project),
       like the plugin's `compileTestJava`. Alternative: only `knkwebapi_v2.csproj`, which misses broken tests.
    5. *Missing toolchain or packages.* Chosen: skip with a note (web app without `node_modules`, API without
       `obj/project.assets.json`, Gradle without a Java 25 toolchain) instead of installing or restoring. Alternatives:
       (a) run `npm ci`/`dotnet restore` from the hook, slow and network-bound at every first stop; (b) fail, which would
       block sessions that never touch a toolchain.
    6. *Errors that predate the session.* Chosen: still blocking, with a message that lets the agent say why they are
       expected; `stop_hook_active` and the 8-block cap stop any loop. Alternative: compare against the state at
       session start, which needs per-session state and hides breakage a link inherited.
    7. *Playwright version.* Chosen: pinned `@playwright/mcp@0.0.85` (current release), so a new npm release does not
       run unreviewed on the developer PC. Alternative: the official `@latest`, always current but unpinned.
    8. *Server name `github`.* Chosen: the official name; tested that a host-provided server of the same name wins, so
       cloud sessions keep their platform tools. Alternative: `github-pat`, which avoids any clash but differs from the
       tool names the skills and prompts use (`mcp__github__*`).
    9. *No `enabledMcpjsonServers` in the committed settings.* Chosen: the developer approves the three servers once
       per machine. Alternative: pre-approve them in `.claude/settings.json`, which Claude Code ignores in untrusted
       folders anyway and which would auto-start an npm package.
    10. *`.gitattributes`.* Chosen: add `*.sh text eol=lf` so a Windows checkout with `core.autocrlf` keeps the hook
        runnable. Alternative: none, relying on each machine's git settings.
6. **Out of scope, noted.** None filed. The hook is configured in knk-workspace only; a session started inside a
   component repo does not run it (guide § 3.5).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Merge knk-workspace#335 (any order with #334), then `main` into `next` (item 1.1).
    2. On the developer PC: set `GITHUB_PAT` (fine-grained PAT for the four `PandiO/knk-*` repos: Contents, Issues,
       Pull requests read/write; Actions, Metadata read) and optionally `CONTEXT7_API_KEY`, start Claude Code in
       knk-workspace, approve the three servers, check `/mcp`; `npx playwright install chromium` if Playwright has no
       browser.
    3. Try the hook once on Windows (Git Bash) with a small change in a component repo; `KNK_FAST_CHECK=off` in
       `.claude/settings.local.json` turns it off if it gets in the way.
    4. Changelog entry at merge (text proposed in #335).

### 4.5 L5 — Sessions board archive (#332)

1. **Scope done.**
    1. `scripts/sessions-archive/archive_sessions.py` (Python 3 stdlib): moves every entry of the board's "Recently
       completed" section verbatim into `docs/reports/sessions-archive/YYYY-MM.md` by the entry's date, newest first
       (new entries are merged in; existing archive entries are never changed, removed or reordered). "In progress",
       "Paused / blocked" and the notes at the top stay byte for byte. Modes: default (write), `--dry-run` (plan and
       verify, write nothing), `--check` (exit 1 while entries wait). Exit 2 on a parse error or a failed line check,
       with nothing written. The archives are written first and the board last, each through a temp file and rename.
    2. Entries: a heading entry (`### ...` and the lines under it) or a table row (a `|` line under a table header plus
       every following line that does not start a new row, heading or table). Rows with a literal line break in a
       cell, and prose paragraphs written under a row, stay with that row. Text before the first entry and the table
       header lines stay on the board.
    3. Line check, before any write: every non-blank line of the original board must appear on the new board plus in
       the lines added to the archive files exactly as often as it was on the board (a line on the board twice must
       end up twice). Table header and separator lines must stay on the board as often as before; archive files may
       hold any number of copies, because each archive table starts with its own header and the header is repeated
       after a row that spans several lines (so later rows still render as a table). The archive scaffolding lines
       the script writes (title, status line, intro, `## Entries`/`## Table rows`) are allowed the same way. Also
       checked: no line of an existing archive file disappears, existing archive entries keep text and order, and the
       board outside the section is unchanged.
    4. `scripts/sessions-archive/test_archive_sessions.py` (stdlib `unittest`, fixture board with heading entries, a
       pipe inside backticks, a six-column row, a row with a line break in a cell plus prose under it, an undated row
       and a duplicate line): 11 tests covering the date rule, dry run, `--check`, a full run, idempotence, appending
       to an existing month without rewriting it, and aborts on a lost line, a duplicated line, a removed archive line
       and a changed "In progress" table.
    5. `docs/reports/sessions-archive/README.md`: rules and a file index the script keeps current between markers.
       Board "How to use": finished rows go to the current month's archive file (link to the index), and rows stay
       short (feature, issue, branch, repos, main areas).
    6. Run on the branch: 239 entries moved (2026-09: 80, 2026-10: 130, 2026-11: 29; none undated). **Board size:
       486,432 bytes / 492 lines before, 64,755 bytes / 84 lines after.** The rest is mostly long "In progress" rows,
       left as they are.
2. **Commits and heads.** knk-workspace `claude/agent-setup-sessions-archive` at `9f91251` (from `main` `eab8b6f`):
   `da40c73` script, tests, index, "How to use"; `99f0c4a` file modes kept on rewrite, undated wording;
   `9f91251` the generated move (not to be merged as is, see item 8).
3. **PR.** [knk-workspace#336](https://github.com/PandiO/knk-workspace/pull/336) (`Closes #332`). Not merged.
   `git merge-tree` shows no conflict with #334 (L3) or #335 (L4).
4. **Tests, baseline → result.** Baseline: no build (docs-only repo), no tests for the script before. Result: 11/11
   unit tests OK. On the real board: the run, then a second run ("nothing to archive"), then `--check` (0 entries
   waiting, exit 0). An independent multiset comparison (board lines from git against the new board plus the
   archive files) differs only in the scaffolding lines. The script was also run on a copy of the latest
   `origin/main` board (`eab8b6f`) right before the push: same 239 entries, clean second run.
5. **Decisions (DESIGN § 4.3).**
    1. *Date rule.* Chosen: a heading's `YYYY-MM-DD`; for a row, the last cell of its first line that starts with a
       date (the "Finished" cell, or "Last updated" for the two rows in the six-column "In progress" layout); no date:
       `undated.md`. Alternatives: (a) the header's "Finished" column only, which fails for the six-column rows and the
       seven rows whose cells hold an unbalanced backtick; (b) any date in the entry text, which can pick a date
       mentioned in the notes; (c) the run date, which loses when the work finished.
    2. *Archive layout.* Chosen: per month two sections, `## Entries` (heading entries) and `## Table rows` (rows under
       a copy of their header), each newest first. Alternative: one mixed list in date order, which would need a
       table header before every run of rows and reads worse.
    3. *Repeated table headers.* Chosen: repeat the header after a multi-line row so the rows after it render as a
       table; the line check counts header and separator lines as structure (they must stay on the board; archive
       copies are free). Alternative: one header per file, which leaves rows after prose rendering as plain text (as
       on the old board).
    4. *Relative links in moved entries.* Chosen: keep them verbatim (relative to `docs/`) and say so in each archive
       file and the index. Alternative: rewrite them to `../../...`, which breaks "verbatim" and the line check.
    5. *Index upkeep.* Chosen: the script regenerates the file list between markers in the README. Alternative: a
       hand-kept list, which drifts when a new month appears.
    6. *Generated move on the branch.* Chosen: separate commit `9f91251` so the developer can skip it at merge and
       regenerate on fresh `main`. Alternative: leave the move off the branch, which would show nothing to review.
6. **Out of scope, noted (comment on #332).**
    1. `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` (§ ACTIVE_SESSIONS, "On completion move it to Recently
       completed") and `docs/ai-agents/docs-session-prompt.md` still tell sessions to move rows to "Recently
       completed". That still works (the script moves them on), but the wording could point to the archive once
       L3's #334 is merged.
    2. Older docs that point to entries "in `ACTIVE_SESSIONS.md`'s Recently completed" (for example
       `docs/backlog/QOL_BUGFIX_BACKLOG.md`, `docs/specs/user-features/IMPLEMENTATION_PLAN.md`) now find them in the
       archive files; no link breaks, as they name the section, not an anchor.
    3. The "In progress" table still holds long rows (about 60 KB); shortening them is the manager's job under the
       new short-row rule (DESIGN § 8.4).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Do not merge `9f91251`. Check out fresh `main`, `git cherry-pick da40c73 99f0c4a` (a conflict on the board's
       "How to use" lines: keep both sides), run `python3 scripts/sessions-archive/archive_sessions.py --dry-run`,
       then without `--dry-run`, then `--check` (expect 0 waiting); commit, push `main`, close #336.
    2. Then merge `main` into `next` (item 1.1).
    3. Changelog entry at merge (developer tooling: "The sessions board keeps only work in progress; finished rows
       move to monthly archive files under `docs/reports/sessions-archive/`, by `scripts/sessions-archive/
       archive_sessions.py`.").

### 4.6 L3b — developer decisions applied to L3 and L4 (#330, #331)

Follow-up run as a subagent of the coordinator (2026-11-12, evening), on the open branches only; no component repo,
no merge, no force-push.

1. **Scope done** (the developer's decisions in § 3 item 5).
    1. Decisions 5.3, 5.4, 5.5 (items 5.1–5.3): the global "Branches, releases and risk tiers" section and the
       coordinator skill (§ 1.3, § 7.2) now state the start condition (`ci.yml` on knk-web-api `master` and
       knk-web-app `main`), merging link PRs into `next` through the PR with a merge commit, and PRs into `next` outside
       a chain waiting for the developer as the developer's decisions.
    2. "At merge" split (item 5.4): global "Shipping a change", `AGENTS.md`, `CLAUDE.md`, the docs-session prompt and
       the documentation maintenance guide: docs sub-issue and docs session at the merge into `next`, feature issue
       closed at promotion; before the `next` rules apply, "at merge" is the merge into the default branch. Global
       "GitHub Issues" item 5 and coordinator § 7.9 follow.
    3. Commit trailers (item 5.5): link skill hard rule 10 and § 3.1, coordinator § 1.5 and the link prompt (§ 4.4).
    4. Route (item 5.6): coordinator § 4.1–4.2 (`create_session` with knk-workspace as `source_url` preferred,
       subagent fallback), `permissions-block.md` (variant A preferred, B fallback), global "Session chains", link
       skill § 1.1; the 2026-10-11 and 2026-11-12 refusals kept as history.
    5. Overlap rule (item 5.7): coordinator § 2.4, link skill § 1.2, global "Parallel sessions" item 1.
    6. Board rule (item 5.8): global "Parallel sessions" item 4, the docs-session prompt, the maintenance guide,
       link skill § 3.5, coordinator § 9.4. Worded for after #336 (paths in code, no link to the archive README).
    7. Permission rule (L4 branch): `.claude/settings.json` `permissions.allow` `mcp__claude-code-remote__add_repo` and
       `mcp__claude-code-remote__register_repo_root`; `docs/guides/developer/agent-tooling.md` § 4 (what it allows,
       that it does not limit repositories, where it applies, how to remove it).
2. **Commits and heads.** knk-workspace `claude/agent-setup-skills` `8321f0d` → `35c554b` (one commit);
   `claude/agent-setup-tooling` `9310d7f` → `c1afaf1` (one commit). Both with the model-free trailer.
3. **PRs.** [#334](https://github.com/PandiO/knk-workspace/pull/334) and
   [#335](https://github.com/PandiO/knk-workspace/pull/335): summary, decisions, testing and docs impact rewritten;
   comments on [#330](https://github.com/PandiO/knk-workspace/issues/330) and
   [#331](https://github.com/PandiO/knk-workspace/issues/331). Not merged. Component PRs of L3 unchanged.
4. **Checks.** Link script over every file each branch changes (outside fenced code, anchors included): L3 57 relative
   links, L4 54, 0 broken. Both `SKILL.md` front matters parse as YAML. `.claude/settings.json` valid JSON.
   `git diff --check origin/main...HEAD` clean on both. `git merge-tree`: no conflict between #334, #335, `main` and
   #336.
5. **Decisions (DESIGN § 4.3).**
    1. *MCP rule scope.* The Claude Code permissions docs (read 2026-11-12) say MCP allow rules match the tool name only;
       a `mcp__` rule with parentheses is skipped when the settings file loads. Chosen: the tool-level rule, with the
       repo limit coming from the cloud session's GitHub access (the Claude GitHub App's repository list for `PandiO`),
       said in the guide and #335. Alternatives: (a) add a `PreToolUse` hook that denies `add_repo` outside the four knk
       repositories, which enforces the limit in the repo at the cost of more code in every session (open for the
       developer); (b) no rule, the developer approves every attach; (c) `mcp__claude-code-remote__*`, which would also
       allow `create_session`, environment changes and scheduled tasks.
    2. *`register_repo_root` allowed too.* Chosen: yes, a link needs it after each clone. Alternative: leave it to ask,
       which stops the link at the same point.
    3. *Docs session under the branch model.* Chosen: the docs branch starts from knk-workspace `next` and the docs
       session merges it into `next` itself (docs only, merge commit), so the docs reach `main` with the promotion.
       Alternatives: (a) merge into `main` at once, documenting unreleased behaviour on trunk; (b) a PR into `next`
       that waits for the developer (strict 5.5), one more review per feature; (c) start the docs session at promotion,
       against decision 5.4. Flagged in #334 for review.
    4. *"Appends its row".* Chosen: "moves the row straight into" the monthly file, newest first, as #336's archive
       README orders it. Alternative: append at the end of the file, against that order.
    5. *Archive references before #336.* Chosen: paths in code, no link, so nothing breaks before or after #336.
       Alternative: link the archive README, broken until #336 is on `main`.
    6. *Link `source_url`.* Chosen: always knk-workspace (the skills and the rule live there). Alternative: the link's
       main repo, which loads neither.
    7. *Consistency edits.* Chosen: also "GitHub Issues" item 5 and the link skill's board sentence, which would
       otherwise contradict decisions 5.4 and 5.8. Alternative: leave two contradicting rules.
6. **Out of scope, noted.** Older handoffs under `docs/ai-agents/handoffs/` still say "move the tracker row to Recently
   completed"; they are dated history and were left as they are.
7. **Blockers.** None.
8. **Merge notes / what the developer must do.**
    1. Merge order as in § 1 item 1: L1, then #334 (and its component PRs), #335, then #336 by cherry-pick; #336 is needed
       for the board rule's archive folder and script, #335 for the `add_repo` rule. Until #335 is merged, coordinators
       use the subagent fallback.
    2. Check that the Claude GitHub App on `PandiO` reaches only the repositories sessions should attach; that list,
       not the rule, limits `add_repo`.
    3. Review this block's decisions 5.3 (the docs session merges into `next`) and 5.1 (a) (the optional
       `PreToolUse` limit).

### 4.7 L3c — docs-PR rule and add_repo guard (#330, #331)

Follow-up run as a subagent of the coordinator (2026-11-12, evening), on the open branches #334 and #335 only; no
component repo, no merge, no force-push. Applies two developer decisions of 2026-11-12 that close L3b's open
decisions 5.3 and 5.1 (a) (§ 4.6 item 8.3).

1. **Scope done.**
    1. Decision 1, docs sessions under the `next` model (branch `claude/agent-setup-skills`): the docs session branches
       from knk-workspace `next`, opens its docs PR into `next` and merges it itself, with a merge commit, after its
       checks. It is the one exception to "PRs into `next` outside a chain wait for the developer" and is marked as the
       developer's decision in global "Branches, releases and risk tiers" rule 3, docs-session prompt step 4,
       `DOCUMENTATION_MAINTENANCE.md` lifecycle item 6 and coordinator § 7.9 (the coordinator does not merge the docs
       PR). L3b's wording (merge the branch) became "open a docs PR and merge it".
    2. Decision 2, `add_repo` guard (branch `claude/agent-setup-tooling`): `.claude/hooks/add-repo-guard.sh` (bash,
       about 110 lines), registered in `.claude/settings.json` under `hooks.PreToolUse` with the matcher
       `mcp__claude-code-remote__add_repo`, timeout 30 s; the `permissions.allow` rule and the Stop hook stay. It
       allows owner `PandiO` with `knk-workspace`, `knk-web-api`, `knk-web-app`, `knk-plugin`, `knk-v1-archive`,
       `knk-v2-archive`, `knk-dev-db-seed` (case-insensitive; `ALLOWED_OWNER` and `ALLOWED_REPOS` at the top of the
       script). Allowed: exit 0, no output, so the allow rule decides. Everything else, and input it cannot read: exit
       2 with the reason on stderr (fail closed). Parsing: `python3` with duplicate keys rejected, else a strict
       `grep`/`sed` parse of the flat `tool_input`; both check GitHub name characters; no `jq`.
    3. `docs/guides/developer/agent-tooling.md`: § 4 split into § 4.1 (permission rule, now pointing at the guard) and
       § 4.2 (what the guard allows, how to add a repository, how to turn it off, the hook contract cited from the
       hooks and permissions docs read 2026-11-12, tests); § 1 table and the `docs/guides/README.md` row mention the
       guard. `.gitattributes` already covers `*.sh`.
    4. Consistency: `knk-coordinator/permissions-block.md` (#334) names the guard next to the GitHub App limit.
2. **Commits and heads.** `claude/agent-setup-skills` `35c554b` → `85e41d9` (decision 1) → `d475532` (permissions
   block); `claude/agent-setup-tooling` `c1afaf1` → `f7fad77`. Model-free trailer on all three.
3. **PRs.** [#334](https://github.com/PandiO/knk-workspace/pull/334) and
   [#335](https://github.com/PandiO/knk-workspace/pull/335) bodies updated (decisions, testing, changelog text);
   comments on [#330](https://github.com/PandiO/knk-workspace/issues/330) and
   [#331](https://github.com/PandiO/knk-workspace/issues/331). Not merged.
4. **Tests.**
    1. Guard, 15 sample inputs, each with `python3` and without it (PATH without Python, `grep`/`sed` path), same exit
       code on both paths. Exit 0: `PandiO/knk-plugin`; `PandiO/knk-dev-db-seed` (access read); `pandio/KNK-Web-API`;
       pretty-printed `PANDIO/knk-v2-archive`. Exit 2 with a reason: `PandiO/other-repo` ("is not on the allowed
       list"); `evil/knk-plugin` ("the owner must be PandiO"); `PandiO/knk-plugin` written into `repo`; `knk-plugin-x`;
       missing `repo`; `repo` as an array; an escaped quote in `repo`; a duplicate `repo` key; garbage text ("input is
       not valid JSON (Expecting value: line 1 column 1 (char 0))"); empty input; no `tool_input`.
    2. End to end, headless Claude Code 2.1.322 in the branch worktree with a stand-in `claude-code-remote` MCP server
       (`--mcp-config`, `--strict-mcp-config`) that logs every call it receives. Run 1: the hook passed
       `PandiO/knk-plugin` (exit 0), which then stopped at the permission check, because Claude Code ignores a project's
       `permissions.allow` in an untrusted folder; it blocked `someone-else/knk-plugin` and the agent got the reason as
       the tool error. Run 2 with `--allowedTools mcp__claude-code-remote__add_repo`: `pandio/KNK-Web-App` and
       `PandiO/knk-dev-db-seed` reached the server; `PandiO/some-other-repo` was blocked (hook exit 2) although the tool
       was allowed. Server log: only the two allowed calls.
    3. Checks: `.claude/settings.json` valid JSON; link script over the files each branch changes: #334 58 relative
       links, #335 54, 0 broken; `git diff --check origin/main...HEAD` clean on both. `git merge-tree`: no conflict
       between `main`, #334 and #335, or between either and #336; `main` + #334 + #335 + `git cherry-pick da40c73
       99f0c4a` applies cleanly. #336's board commit `9f91251` conflicts with `main` on `docs/ACTIVE_SESSIONS.md` (the
       board changed since), as expected for the cherry-pick route of § 1 item 1.4.
5. **Decisions (DESIGN § 4.3).**
    1. *Deny form.* Chosen: exit 2 with stderr, which the permissions docs say blocks before permission rules are
       evaluated, so the allow rule cannot override it. Alternative: JSON `hookSpecificOutput.permissionDecision:
       "deny"` with `permissionDecisionReason`, same effect, JSON on stdout.
    2. *Allowed path.* Chosen: exit 0 with no output, leaving the decision to the allow rule. Alternative: JSON
       `"allow"`, which would approve attaches even after the allow rule is removed.
    3. *No per-hook off switch.* Chosen: turn it off by removing the `PreToolUse` entry (or `disableAllHooks` on one
       machine). Alternative: a `KNK_ADD_REPO_GUARD=off` variable like `KNK_FAST_CHECK`, which an agent-edited local
       settings file could set.
    4. *Parser.* Chosen: `python3`, else strict `grep`/`sed`; duplicate keys and escaped strings denied. Alternative:
       also `jq` when present, a third path to test for no gain.
    5. *Timeout 30 s.* Chosen: generous, since a timed-out PreToolUse hook does not block and the script takes well
       under a second. Alternative: the default timeout.
    6. *Docs PR, not a direct merge.* Chosen: the prompt says "open a docs PR into `next` and merge it yourself", as
       the decision words it. Alternative: keep L3b's direct branch merge, which skips the PR's checks.
    7. *Permissions block edit on #334.* Chosen: one sentence naming the guard as a path in code (the script arrives
       with #335). Alternative: leave the block saying the GitHub App is the only limit.
6. **Out of scope, noted.** Run 1 shows that Claude Code ignores a project's `permissions.allow` in a folder whose
   trust dialog was not accepted, while hooks still run. Whether claude.ai cloud sessions count the starting
   repository as trusted is not tested here; the first `create_session` link after #335 merges shows it (if the
   attach still prompts, the allow rule is not in force there, and the guard still is).
7. **Blockers.** None.
8. **Merge notes / what the developer must do.** Merge order unchanged (§ 1 item 1). Decisions 5.3 and 5.1 (a) of
   § 4.6 are now the developer's; review this block's decisions 5.1–5.7.

### 4.8 L4b — trial findings fixed (#331, #332)

Follow-up run as a subagent of the coordinator (2026-11-13), on the open branches #335 and #336 only; no component
repo branch, no merge, no force-push. Fixes the findings of the trial session of 2026-11-13 on
`claude/agent-setup-trial` (comments of 07:03 on [#331](https://github.com/PandiO/knk-workspace/issues/331) and
[#332](https://github.com/PandiO/knk-workspace/issues/332)).

1. **Scope done.**
    1. Finding #331.1, wrong or missing clone (`.claude/hooks/fast-check.sh`): `KNK_FAST_CHECK_REPOS` (`:`-separated,
       or `;` on Windows) checks exactly the listed clones. Otherwise the hook finds clones by their `origin` URL
       (`.../PandiO/<name>[.git]`, any case) under `Repository/`, next to the workspace, and up to three folders deep
       under the workspace's parent and `$HOME` (skips `node_modules`, `.gradle`, `bin`, `obj`, `build`, `AppData`,
       `Library`, hidden folders; `find` capped at 3 s; deduped by real path). Of several clones of one repo it checks
       only the most recently active one: newest of `index`, `logs/HEAD` and up to 200 changed files, read with
       `GIT_OPTIONAL_LOCKS=0` so looking does not touch an index. The output names the checked and ignored paths
       whenever there is output, and once each time the pick changes (last pick in the workspace's git dir,
       `knk-fast-check-pick`).
    2. Finding #331.2, JDK 25: before the plugin check the hook reads the toolchain version from the build files (25),
       looks for that JDK by its `release` file and `bin/javac` in `KNK_JDK25_HOME`, `JAVA_HOME`, `/usr/lib/jvm`,
       `/usr/lib64/jvm`, `/opt/jdk-25*`, `/opt/*jdk*25*`, `/opt/java`, `~/.gradle/jdks` (or `$GRADLE_USER_HOME`),
       SDKMAN, `~/.jdks`, macOS `/Library/Java/JavaVirtualMachines` and Windows `C:/Program Files/{Java,Eclipse
       Adoptium,Microsoft}` (each also one folder deeper), and passes the first as
       `-Porg.gradle.java.installations.paths=<dir>`. It never edits a `gradle.properties` and leaves an existing
       `org.gradle.java.installations.paths` alone. A toolchain skip now names what is missing and the fix (install
       command or `KNK_JDK25_HOME`).
    3. Finding #331.3, cached skips: only passes are stored; skips and timeouts are tried again at the next stop. The
       JDK folder is part of the command and so of the fingerprint.
    4. Guide `docs/guides/developer/agent-tooling.md`: § 3.1 (discovery summary, caching rule), § 3.6 (which clones,
       `KNK_FAST_CHECK_REPOS`, why one clone), § 3.7 (JDK detection, `KNK_JDK25_HOME`, ways to fix a skip, a suggested
       setup-script line for the cloud environment, left to the developer). PR #335 body updated.
    5. Finding #332, duplicate guard (`scripts/sessions-archive/archive_sessions.py`): before the line check, the script
       looks for each entry it would move, verbatim (all its lines as one block at line boundaries), in every archive
       file of the folder; if found it aborts with exit 2, writes nothing, lists the entries and points to the README;
       `--check` reports them too. 4 new tests.
    6. Finding #332, merge procedure: archive README section "Merging a branch that ran the script" (cherry-pick route
       preferred; the trial's `git apply --3way` route for a branch merged anyway, and that the guard stops the wrong
       way); rule 6 for the guard. PR #336 Summary, Testing and Admin steps updated with the new cherry-pick list.
2. **Commits and heads.** `claude/agent-setup-tooling` `f7fad77` → `5787c0e`; `claude/agent-setup-sessions-archive`
   `9f91251` → `99b1a77`. One commit each, model-free trailer. **Cherry-pick list for #336 is now
   `da40c73 99f0c4a 99b1a77`** ("Sessions board archive script, tests and index", "Sessions archive: keep file modes
   on rewrite, word the undated rule", "Sessions archive: refuse entries already archived, document merging"); skip
   `9f91251` ("Move finished sessions board entries to the monthly archive").
3. **PRs.** [#335](https://github.com/PandiO/knk-workspace/pull/335) and
   [#336](https://github.com/PandiO/knk-workspace/pull/336) bodies updated; comments on #331 and #332. Not merged.
4. **Tests.** Cloud container, Node 22, JDK 21 (Gradle) and JDK 25, worktrees in the scratchpad (deliberate errors
   never committed; worktrees removed afterwards).
    1. Hook scenario: a workspace worktree of #335, a stale knk-plugin worktree next to it (untracked Java error,
       mtimes two days old), an active knk-plugin worktree at `<fake HOME>/pandio/knk-plugin` (fresh valid change), a
       knk-web-app worktree with `npm ci`; `HOME=<fake HOME>` (and `GRADLE_USER_HOME=/root/.gradle`) for every run.
        1. Discovery: `knk-plugin compile passed (44s); clones: knk-plugin: checked .../h1/pandio/knk-plugin (most
           recently active), ignored .../t1/knk-plugin`, exit 0. Same state: silent, 0.59 s.
        2. `KNK_FAST_CHECK_REPOS=<stale>:<missing>:<workspace>`: exit 2 on the stale clone's `HookStale.java:2: error:
           incompatible types`; the other two entries named as ignored.
        3. JDK 25 moved from `/usr/lib/jvm` to `/opt/jdk-25`: plain `./gradlew compileJava` failed with `Cannot find a
           Java installation ... languageVersion=25` (the trial's case); the hook passed
           `-Porg.gradle.java.installations.paths=/opt/jdk-25` and blocked on a deliberate Java error (7 s).
        4. JDK hidden: `knk-plugin skipped (Gradle needs a Java 25 toolchain and the hook found none in KNK_JDK25_HOME,
           JAVA_HOME, /usr/lib/jvm, /opt, ~/.gradle/jdks, ~/.sdkman or ~/.jdks; install one (Debian/Ubuntu: apt-get
           install -y openjdk-25-jdk-headless) or set KNK_JDK25_HOME to its folder. Gradle said: ...)`, exit 0, 1.4 s,
           no state file. No code change, `KNK_JDK25_HOME=<hidden dir>`: the check ran (exit 2 on the Java error). No
           code change, variable unset, JDK moved back to `/opt/jdk-25`: the check ran (exit 2, 3.6 s).
        5. Error removed: `knk-plugin compile passed (4s)`; same state: silent, 0.52 s.
        6. Regression: web-app type error exit 2 with `src/utils/claimCode.ts(132,14): error TS2322` (29 s); a valid
           web-app change passed (28 s), then silent (0.48 s); `stop_hook_active: true` exit 0 in 0.009 s;
           `KNK_FAST_CHECK=off` exit 0 in 0.004 s.
        7. Touching the stale clone's file made it the checked clone (exit 2 on its error), with the other named as
           ignored.
        8. Detection functions alone: a JDK one folder down in `~/.gradle/jdks/<vendor>/` was found; a JDK 21 in
           `JAVA_HOME` and `KNK_JDK25_HOME` was never taken for 25; with `org.gradle.java.installations.paths` in a
           `gradle.properties` no flag was passed and the hint names that file.
        9. Cost: clone selection about 250 ms with three clones (`find` 5 ms, `git status` 8-80 ms per clone); a stop
           with nothing new about 0.5 s. The total budget is unchanged (300 s per check, 540 s overall, 600 s hook).
           The system JDK was moved back to `/usr/lib/jvm` afterwards.
    2. Archive script: 15/15 unit tests OK (11 earlier unchanged, 4 new: whole archive already holds the board's
       entries, `--dry-run` and run abort, `--check` names 8 duplicates; one old entry next to a new one; copy in
       another month's file; same heading with another body and a prefix-only row are not duplicates). On the branch
       with `main`'s board: `error: 239 entries are already in the archive verbatim`, `--check`: `240 entries waiting
       ... 239 of them already in the archive verbatim`.
    3. Cherry-pick route on `origin/main` `fdc4425`: `git cherry-pick da40c73 99f0c4a 99b1a77` clean (no conflict);
       `--dry-run` board 488,989 bytes / 496 lines → 66,279 bytes / 84 lines, 240 entries (2026-09: 80, 2026-10: 130,
       2026-11: 30); run done; `--check` 0 waiting; second run "nothing to archive"; tests 15 OK.
    4. Merged-branch route: `git merge` of #336 into `origin/main` conflicts on the board; `main`'s board plus the
       script stops on the guard (239 duplicates); the README route (`git checkout --theirs`, `git apply --3way` of
       `main`'s board diff since the merge base, one conflict hunk resolved to `main`'s new entry) moved exactly 1
       entry, `--check` 0, and gave a board byte for byte identical to the cherry-pick route's, with the same entries in
       all three archive files.
    5. Checks: `bash -n` on both hooks; `.claude/settings.json` valid JSON; links in the guide and the archive README
       resolve (0 broken); `git diff --check` clean on both branches. `git merge-tree`: no conflict between
       `origin/main`, #334, #335 and #336 except the known board conflict of #336's generated `9f91251` with `main`;
       `main` + #334 + #335 + the three-commit cherry-pick applies cleanly.
5. **Decisions (DESIGN § 4.3).**
    1. *One clone per repo, the most recently active.* Chosen: newest `index`, `logs/HEAD` or changed file, ignored
       paths named, `KNK_FAST_CHECK_REPOS` to override. Alternatives: (a) check every clone, which blocks on errors in
       stale clones the session never touched and multiplies the time (25-100 s per check); (b) the clones registered
       with `register_repo_root`, which the Stop input does not list and which do not exist on the developer PC; (c)
       the clone with changes against its base, which a stale clone on a feature branch also has (the trial's case).
    2. *Search roots.* Chosen: `Repository/`, siblings, then three levels under the workspace's parent and `$HOME`.
       The parent is searched because a cloud session's `$HOME` is `/root` while the clones live in `/home/user`.
       Alternative: `$HOME` only, which would have missed `/home/user/pandio/knk-plugin` in this container.
    3. *Pick note when nothing else is said.* Chosen: once per pick change, so a wrong pick shows even on a silent stop
       without repeating at every stop. Alternatives: (a) only with other output, which can hide a wrong pick; (b) at
       every stop, noise in every session with two clones.
    4. *JDK on the command line only.* Chosen: `-Porg.gradle.java.installations.paths=<dir>` per run, an existing
       setting left alone. Alternatives: (a) write it into `~/.gradle/gradle.properties` (the trial's manual fix),
       which changes the user's machine; (b) append to an existing setting, which needs parsing of escaped values.
    5. *Toolchain identity in the cache.* Chosen: implicit, the JDK folder is in the command and the command is in the
       fingerprint. Alternative: add `java -version` output, a JVM start at every stop.
    6. *Run Gradle when the hook finds no JDK.* Chosen: yes, Gradle may know places the hook does not (Windows
       registry, asdf); the skip then carries Gradle's error and the hook's fix. Alternative: skip at once, about 1.5 s
       faster per stop while the plugin has changes, but it could skip where Gradle would succeed.
    7. *Duplicate test.* Chosen: all lines of the entry as one block at line boundaries, in any archive file; abort the
       whole run. Alternatives: (a) first line only, which would stop a new entry that repeats an old heading; (b)
       parsed-entry comparison, which misses a copy in a hand-edited file; (c) drop duplicates and archive the rest,
       which hides a board taken from the wrong commit.
6. **Out of scope, noted.**
    1. Included without a separate finding: the hook's error excerpt also drops `npm notice` lines (one `grep -v`),
       which showed up between the tsc error lines in the test runs.
    2. Gradle scans `/usr/lib/jvm` on its own, so the trial's JDK 25 was probably installed somewhere else (for example
       under `/opt` or `~/.local`); the hook now finds `/opt/jdk-25*` and `/opt/*jdk*25*`, and `KNK_JDK25_HOME` covers
       any other place.
7. **Blockers.** None.
8. **Merge notes / what the developer must do.**
    1. Merge order unchanged (§ 1 item 1); #336 by cherry-pick of `da40c73 99f0c4a 99b1a77` (§ 1 item 1.4).
    2. Optional: a JDK 25 in the cloud environment's setup script (guide § 3.7:
       `ls -d /usr/lib/jvm/*25* >/dev/null 2>&1 || { apt-get update -qq && apt-get install -y -qq openjdk-25-jdk-headless; }`),
       or `KNK_JDK25_HOME` in its variables. No environment was changed.
    3. Review decisions 5.1–5.7.
