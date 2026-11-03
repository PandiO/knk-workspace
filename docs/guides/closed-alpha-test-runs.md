# Closed alpha test runs — how they are numbered, prepared, run and reported

**Status:** Current (developer agreed 2026-11-03)
**Last updated:** 2026-11-03
**Issues:** [PandiO/knk-workspace#149](https://github.com/PandiO/knk-workspace/issues/149) (run 1 findings)

How closed-alpha test runs with testers are numbered, where their documents live, what a preparation plan contains
and how findings are triaged. For agents and the developer. Feature smoke tests on dev (`docs/guides/*-smoke-test.md`)
are a different thing; see § 1.

## 1. Numbering: what counts as a test run

- A **test run** is a session on the alpha **with testers** (players other than the developer). Only these are
  numbered: test run 1, test run 2, …
- The developer's own checks of fixes, alone or with an agent, are **developer pre-checks** (on the alpha) or
  **smoke test runs** (on dev, in a smoke test guide). They are never numbered as test runs and don't move the
  next run's number. Record them in the next run's checklist under "Developer pre-checks (<date>)".
- Package "rounds" (round 2, round 2b) are review iterations of a fix branch, not runs.
- Why: the 2026-10-27 pre-check was first titled "Test run 2 results", which pushed the next tester run to "run 3"
  (fixed 2026-11-03).

## 2. Folder layout

One folder per test run under `docs/reports/alpha-tests/`, named `test-run-<n>/`. The run's date goes in each
document's header, not in the folder name, so the folder can be made before the date is set.

| File | When | Contents |
|---|---|---|
| `test-run-<n>-preparation.md` | Before the run | Scope, go / no-go list, session plan, decisions to discuss, tester questions (§ 3) |
| `test-run-<n>-checklist.md` | Before the run, filled during it | Developer pre-checks, then the steps per area with works / fails / skipped, and the tested commits |
| `test-run-<n>-findings.md` | Within a day after the run | Triaged findings, one GitHub issue each (§ 5) |
| `YYYY-MM-DD-package-<x>-<topic>.md` | While fixing | A fix package's report for run `<n>`'s findings |
| Screenshots, clips | Any time | Next to the document that links them |

Run 1's folder keeps its old name `25-10-2026/` (links in issues and handoffs). Like every report, these files are
dated and never replaced by a new run; a run's checklist and findings are updated only with that run's results.

## 3. The preparation plan

Make `test-run-<n>-preparation.md` (template: [test run 2 preparation](../reports/alpha-tests/test-run-2/test-run-2-preparation.md))
once the previous run's fixes are in review. It has these sections:

1. **Scope:** retests that need several players, regression-only areas (accepted by the developer, play normally),
   "only if merged and deployed" items, out of scope (on hold, skipped). New features go in their own block, not mixed
   into retests.
2. **Go / no-go list:** the exact API, web and plugin commits deployed (with the update report); a database and world
   snapshot; seeds and scenarios imported; config keys the fixes need; permissions granted to the tester ranks;
   tester accounts not op and on the rank they play as; at least one console/Bedrock player and ideally one new
   tester; the known-issues list; logs kept; one feedback channel.
3. **Session plan:** timed blocks (briefing, scripted blocks, free play, debrief) with the checklist sections they
   cover, and roles: game master (admin), note-taker, testers with assigned scripted moments (kicks, late joins, AFK,
   empty teams).
4. **Decisions to discuss:** one row per open decision with the current default, the question and who decides
   ("tester input" or "developer"). Collect them from the package reports' "Decisions taken here", the handoffs'
   open flags and in-review issues. Pick the five or six most important for the debrief; the rest go in the
   written survey.
5. **Tester questions:** the same four 1–5 scores every run (fun, fairness, clarity of what to do, clarity of results
   and rewards) so runs can be compared, a few open questions, and platform (Java / console, first session or not).
6. **Reporting and triage:** the report template, priorities and the known issues (§ 5).
7. **After the run:** the steps in § 6.

## 4. Running the session

- **No deploys during a session.** Hotfixes go in after the debrief, with an update report.
- Script the moments that rarely happen by themselves and give each to a named tester beforehand; keep a free-play
  block for what nobody planned.
- Ask testers what they felt and saw, not how to fix it; turn their experience into decisions afterwards.
- Collect the survey right after the session, while it is fresh (under ten minutes).

## 5. Findings and triage

- Report template: what I did, what I expected, what happened, where and when, Java or console, screenshot or clip.
- Priorities: **P0** breaks a match or can be exploited (`priority:urgent`) · **P1** fix before the next run
  (`priority:high`) · **P2** later in the alpha (`priority:medium`) · **P3** backlog (`priority:low`).
- Within a day: `test-run-<n>-findings.md` and a GitHub issue per finding under a parent issue
  "Closed alpha test run <n> (<date>): findings". Link duplicates to the existing issue instead of filing again.
- A failing checklist step gets a comment on its issue with what happened.
- **Exit bar** for the next run: no open P0 or P1 from the previous runs, unless the developer accepts one in the
  preparation plan.

## 6. After the run

1. Fill the checklist's results with the tested commits.
2. Close the issues whose steps all passed; leave failing ones open with a comment.
3. Write the findings and file the issues (§ 5).
4. Write the decisions taken into the preparation plan's decisions table and onto each issue.
5. A ten-minute retro on the test process itself; update this guide with what changes.
6. Create `test-run-<n+1>/` when the next run's preparation starts.
