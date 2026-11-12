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
| L1 CI | #328 | In review (done 11:40 UTC, both workflows green) | `claude/agent-setup-ci`: knk-web-api `81b06d9`, knk-web-app `a7d31a2` | [knk-web-api#12](https://github.com/PandiO/knk-web-api/pull/12), [knk-web-app#9](https://github.com/PandiO/knk-web-app/pull/9) | create_session session_01R1w2UsfbmKqEY1QXSx25id |
| L2 Branches, labels, digest | #329 | In review (done 11:40 UTC; labels and pin left for the developer) | `next`: knk-workspace `6245c9f`, knk-web-api `b5e57fa`, knk-web-app `9a85238`, knk-plugin `121030f`; digest issue [#333](https://github.com/PandiO/knk-workspace/issues/333) | — (no file changes) | subagent (coordinator decision § 3.2) |
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
