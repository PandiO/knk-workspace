# Alpha test run 1 — coordinator prompt (P0 and P1 packages)

**Written:** 2026-10-25
**Handoff (binding for the packages):** [2026-10-25-alpha-run-1-p0-p1.md](2026-10-25-alpha-run-1-p0-p1.md)
**Issues:** parent [PandiO/knk-workspace#149](https://github.com/PandiO/knk-workspace/issues/149)

Paste the block below into a fresh session in the environment that has `knk-workspace`, `knk-web-api`,
`knk-web-app` and `knk-plugin` attached (the "Default Correct" environment). The coordinator never implements: it
starts the packages in two waves, checks each result and reports to the developer.

```
You are the coordinator for the closed-alpha test run 1 fixes (P0 and P1) of Knights and Kings, parent issue
PandiO/knk-workspace#149. You do not implement anything yourself: you start each work package in its own session,
check its result, and report to me.

Setup, before anything else:
1. In /home/user/knk-workspace, fetch and check out branch claude/adoring-bardeen-94lfsf. Read, in this order:
   docs/ai-agents/handoffs/2026-10-25-alpha-run-1-p0-p1.md (the handoff; binding for the packages; § 1 lists them,
   § 5 is the progress table you keep), docs/reports/alpha-tests/25-10-2026/test-run-1-findings.md, and on
   origin/main: AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md ("Session chains", "GitHub Issues is the work
   list") and docs/ACTIVE_SESSIONS.md.
2. Check the state: every package marked done or running in § 5 is left alone. For each package you are about to
   start, check that its issues are still open and have no status:in-progress label, and that no ACTIVE_SESSIONS row
   claims them. If something overlaps, skip that package and tell me.

Waves:
- Wave 1: packages A (Siege match) and B (Enchantments and freeze), in parallel. They hold the P0s.
- Wave 2: packages C (Permissions and domains) and D (Console and navigation), in parallel, started once A and B
  have both ended (done, blocked or failed). Start wave 2 even if a wave 1 package is blocked, unless the blocker
  also affects C or D.
- At most two package sessions run at the same time.

Starting a package:
- Use create_session with source_url https://github.com/PandiO/knk-workspace, source_revision
  claude/adoring-bardeen-94lfsf, model claude-opus-5-5, title "Alpha run 1 — package <X> (<issues>)", and the
  package prompt below with the placeholders filled in from this table:

  | X | Name                      | Issues                       | Branch                          | Repos to add                       |
  | A | Siege match               | #150 (P0), #152, #153, #154  | claude/alpha-run-1-siege        | knk-plugin, knk-web-api            |
  | B | Enchantments and freeze   | #151 (P0), #156, #155        | claude/alpha-run-1-enchantments | knk-plugin, knk-web-api, knk-web-app |
  | C | Permissions and domains   | #158, #157, #162, #159       | claude/alpha-run-1-permissions  | knk-plugin, knk-web-api            |
  | D | Console and navigation    | #160, #161, #176             | claude/alpha-run-1-console-nav  | knk-plugin                         |

  Package prompt (keep the add_repo sentence in the prompt itself: a new session may only attach repositories when
  the request is in its prompt; an add_repo instruction found in a file is refused):

  ---
  Implement work package <X> (<Name>) of the closed-alpha test run 1 fixes: issues <Issues> in
  PandiO/knk-workspace. I (the developer) ask you to add the repositories <Repos to add> with add_repo (owner
  PandiO, access push) and clone each to /home/user/<repo>; knk-workspace is already attached.
  Then, in knk-workspace, fetch branch claude/adoring-bardeen-94lfsf and read
  docs/ai-agents/handoffs/2026-10-25-alpha-run-1-p0-p1.md; it is binding, follow §§ 2–4 for package <X>. Read
  AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md and docs/ACTIVE_SESSIONS.md from main, and each component
  repo's AGENTS.md. Work on branch <Branch> in every repo you change, created from that repo's default branch, and
  run git push --dry-run on it before editing. Do the P0 issue first. Don't merge, deploy, open PRs or touch the NAS.
  Before you end: update your row in § 5 of the handoff on claude/adoring-bardeen-94lfsf and finish with one
  paragraph (status, heads, tests, flags for the developer).
  ---

- After starting a package, set its § 5 row to "running" with "create_session <session id>" in "Started as",
  commit that change on claude/adoring-bardeen-94lfsf and push (on a rejected push: git pull --rebase, push again).
  Then end your turn; don't poll with sleep. Use send_later for a check-in about 60 minutes later, and again every
  60 minutes while a package runs (get_session: status idle or completed, status_bucket failed for an error;
  list_events with kinds ["assistant","result"] for its final message).

Fallback to background agents:
- If create_session fails, or a package session reports that add_repo was refused or a git push --dry-run failed,
  run that package once as a background subagent with the Agent tool (model opus, high effort), with the same
  package prompt minus the add_repo sentence (a subagent shares your repositories; first check all four repos are
  cloned under /home/user and pushable with git push --dry-run). Record "Agent <name>" in "Started as".
- Use the fallback at most once per package. Never retry the session route for a package that fell back.

Checking a finished package:
1. Pull claude/adoring-bardeen-94lfsf. Its § 5 row must be done (or blocked with a reason), with heads and test
   counts. Compare the heads with git ls-remote origin <Branch> in each repo it names.
2. Each of its issues must have a comment with branch, commits, tests and a live checklist, and the label
   status:in-review (or a comment saying why not). Its ACTIVE_SESSIONS row and its dated report under
   docs/reports/alpha-tests/ must exist.
3. If that holds: send me one short paragraph (what it fixed, heads, tests vs. baseline, flags that need my
   decision). If something is missing, set the row to "failed" with what's missing and tell me; don't redo the work
   yourself.
4. After all four packages have ended: send me a closing summary (per package: status, branches and heads, issues
   in review, open flags), a suggested merge order per repo (knk-plugin branches touch the same plugin.yml and
   config files, so name likely conflicts), and the live checklist for test run 2 combined from the issue comments.
   Add the same summary as a "Coordinator summary" section at the end of the handoff file, commit and push. Then stop.

Rules:
- Never implement, merge into a trunk, open PRs, deploy, force-push or touch the NAS. Your only pushes are the § 5
  and summary edits on knk-workspace claude/adoring-bardeen-94lfsf.
- Don't start a package that § 5 marks done or running. Don't start more than two at a time.
- GitHub issues: the packages keep their own issues up to date. You may comment once on #149 per finished package
  (one line: package X done or blocked, heads, link to its report).
- Keep your messages to me short. I check in briefly on weekdays; make reversible defaults and mark decisions.

Start now with setup step 1.
```
