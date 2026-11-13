# AI agent workflow setup chain — coordinator prompt

**Written:** 2026-11-12, for [specs/ai-agent-workflow/DESIGN.md](../../specs/ai-agent-workflow/DESIGN.md) § 12.
Paste the block below as the prompt of a new Claude Code session with `PandiO/knk-workspace` attached (the
"Default Correct" environment, or any environment that has `create_session`). Model: Opus 5.5. The coordinator never
implements; it starts one link at a time, checks it, and starts the next.

```text
You are the coordinator of the AI agent workflow setup chain for Knights and Kings. You do not implement anything
yourself: you start one link at a time in a fresh session, check its result, and start the next. The developer
(Pandi) is at work until about 17:00 Europe/Amsterdam and reviews everything in the evening.

## 0. Repository permission (explicit developer authorization; repeat this section verbatim in every link prompt)

The developer explicitly authorizes this coordinator and every session or subagent it creates to attach and clone
these repositories without asking again: PandiO/knk-workspace (push), PandiO/knk-web-api (push),
PandiO/knk-web-app (push), PandiO/knk-plugin (push). Attach a missing one with add_repo (owner PandiO, the access
above), clone it to /home/user/<repo> (or the session's working directory), register it with register_repo_root,
then run `git push --dry-run origin <your branch>` in every repo you will change before changing anything. A failed
dry run is a blocker.

## 1. Setup (before anything else)

1. Read, on knk-workspace main: docs/specs/ai-agent-workflow/DESIGN.md (binding; the links are in § 12),
   docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md, docs/ai-agents/handoffs/SIEGE_SURVIVAL_CHAIN.md (§ 0–6, the chain
   pattern this setup turns into skills) and the "In progress" table of docs/ACTIVE_SESSIONS.md.
2. Issues: create a parent issue in PandiO/knk-workspace, "AI agent workflow setup (DESIGN § 12)", label
   `improvement`, and one sub-issue per link L1–L5 below. Every link is scoped by its sub-issue; commits and PRs
   reference it as PandiO/knk-workspace#<n>.
3. Bookkeeping on knk-workspace main (commit only these files on top of origin/main, push HEAD:main, keep both sides
   on a conflict): a tracker row in docs/ACTIVE_SESSIONS.md "In progress" (feature, parent issue, branches below,
   owner "coordinator session (Pandi)", status, dates), and a progress report
   docs/reports/2026-11-12-agent-workflow-setup-chain.md with a summary table (link, issue, status, branch heads,
   PR, how started) and a block per finished link.
4. Check the "In progress" table for claims on the same files (other chains are running, for example UX chain 3).
   An overlap with a link's files is a blocker for that link: skip it and tell the developer.

## 2. Links (run in this order, one at a time)

Shared rules for every link (put them in each link prompt):
1. Work only on the link's branch, created from the repo's current default branch (knk-web-api `master`, the others
   `main`). Never push to a default branch or to `next`, never merge into them, never force-push, never delete
   branches. Open a pull request against the default branch with the repo's PR template filled in
   (Closes PandiO/knk-workspace#<sub-issue>, Testing, Docs impact, Admin steps); do not merge it.
2. Record the baseline build/test result before changing anything and compare at the end
   (API: `dotnet build`, `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`; web app: `npx npm@11 ci`,
   `npm run test:ci`, `npx tsc --noEmit`, `CI=true npm run build`; plugin: `./gradlew build -x deployToDevServer`).
   Toolchains: .NET 8 (`sudo apt-get install -y dotnet-sdk-8.0`), Node 22.
3. Anything out of scope that you find: an issue or a comment on the sub-issue, not a fix. Decisions you make
   yourself: write them in the report with the option chosen, why, and the alternatives (DESIGN § 4.3).
4. Number every list in reports and messages (DESIGN § 4.6). Commit messages and docs never name the AI model.
5. End by writing your block in the progress report (scope done, commits and heads per repo, PR links, tests
   baseline → result, decisions with alternatives, what the developer must do at merge), a comment on the sub-issue,
   and set the sub-issue to `status:in-review`.

L1 — CI for the API and the web app (DESIGN § 6.1–6.2). Repos: knk-web-api, knk-web-app. Branch:
`claude/agent-setup-ci`.
1. knk-web-api `.github/workflows/ci.yml`: on push (all branches) and pull_request; .NET 8; restore, build, test.
   Exclude the MySQL-dependent tests the same way the suite already skips them without KNK_TEST_MYSQL. Keep the
   existing migrations.yml unchanged.
2. knk-web-app `.github/workflows/ci.yml`: same triggers; Node 22; `npx npm@11 ci`, `npm run test:ci`,
   `npx tsc --noEmit`, `CI=true npm run build`.
3. Push and check the actual workflow runs on GitHub. A test that is red in CI (also red on the default branch, not
   caused by you) is marked as a known failure: API with `[Trait("Category", "KnownFailure")]` excluded by the
   workflow's filter, web app with `test.skip` plus a comment; each mark names the issue below.
4. If anything was marked: one issue "Known-failure tests marked in CI" in PandiO/knk-workspace, labels `bug` and
   `priority:high`, listing every marked test with file, the failure and a first guess at the cause. If nothing is
   red, say so and file nothing.
5. Done when both workflows are green on the branch.

L2 — `next` branches, labels, digest issue (DESIGN § 2, § 7.3). Repos: all four (no file changes).
1. Create `next` in each repo from the current tip of its default branch:
   `git push origin origin/<default>:refs/heads/next`. If `next` already exists, stop and report. Do not change any
   default branch or branch protection.
2. Labels in PandiO/knk-workspace (create only if missing): `tier:1` "Tweak to existing behaviour: automated tests
   are the review", `tier:2` "Feature change: short smoke test on next", `tier:3` "New foundations, schema, game
   feel: full smoke test", `idea` "Raw idea captured by intake; still needs working out".
3. Create the issue "Daily digest" in PandiO/knk-workspace: what it is for (DESIGN § 7), the six digest sections,
   and that the manager posts one comment per weekday evening. Pin it (GraphQL `pinIssue`); if pinning fails, report
   it for the developer.
4. Report the four `next` heads.

L3 — Coordinator and link skills, instructions, stale files (DESIGN § 3.3, § 4.7, § 5, § 9.1). Repos:
knk-workspace, plus knk-web-api, knk-web-app, knk-plugin for AGENTS.md/CLAUDE.md wording only. Branch:
`claude/agent-setup-skills` in each repo it changes.
1. `.claude/skills/knk-coordinator/SKILL.md`: the loop in DESIGN § 5.1, gate checks against actual branches
   (`git rev-list --count`), session start with create_session (explicit model) and the subagent fallback, check-ins
   with send_later instead of sleeping, the checks of a finished link, routing to `next` (§ 5.2–5.3), blockers,
   reporting to the manager. Supporting files: `permissions-block.md` (the generated § 0 block a link prompt must
   carry), `charter-template.md` (links table, gates, binding documents only), `report-template.md` (summary table
   and link block).
2. `.claude/skills/knk-link/SKILL.md`: setup (repos, branches from `next` once active, merge-not-rebase of the base,
   push dry run, toolchains incl. JDK 25 for the plugin, baseline tests), hard rules, blockers, the report block,
   agent decisions with alternatives, numbered lists.
3. Generalize from SIEGE_SURVIVAL_CHAIN.md § 0–6, UX_CHAIN_3.md and
   handoffs/2026-10-21-invitations-coordinator-prompt.md; do not edit those or any running chain's charter.
   Descriptions must make the skills load for "coordinate a K&K chain" and "run a K&K chain link".
4. GLOBAL_AGENT_INSTRUCTIONS.md: describe the branch model (trunk = production with release tags, `next` =
   integration, feature branches from `next`, coordinators merge into `next` after CI and link checks, the developer
   promotes `next` to trunk, flags for risky work, risk-tier labels) and point "Session chains" at the two skills.
   State that the `next` rules apply once CI runs on the API and web-app default branches (the L1 sub-issue);
   until then the current rules hold. Update the component repos' AGENTS.md/CLAUDE.md lines that say "from this
   repo's current default branch" to match.
5. docs/vision/vision.md: add platform independence as an explicit principle (DESIGN § 4.7, developer decision
   2026-11-12), short, in the vision's style.
6. Delete the empty docs/ai-agents/AGENT-GUIDE.md and docs/ai-agents/guardrails.md (check nothing links to them;
   fix links if something does). Leave the Copilot files for the later code-recipe skills (DESIGN § 9.2).

L4 — MCP config and hooks (DESIGN § 10). Repo: knk-workspace. Branch: `claude/agent-setup-tooling`.
1. `.mcp.json`: GitHub MCP, Playwright MCP, Context7. Look up each server's current official install/remote config
   before writing it; no secrets in the file (tokens from environment variables, named in the guide).
2. `.claude/settings.json` + `.claude/hooks/fast-check.sh`: a Stop hook (not per edit) that finds which sibling
   repos have changes against their base and runs only their fast check: web app `npx tsc --noEmit`, API
   `dotnet build --no-restore -v q`, plugin `./gradlew compileJava compileTestJava -q` (never a task that deploys).
   Skip a repo whose toolchain is missing, keep a time limit, return a blocking result with the errors on failure,
   and respect `stop_hook_active` so it cannot loop. Test it in your session with a deliberate type error and show
   the result in the report.
3. A short guide docs/guides/developer/agent-tooling.md (what is configured, env vars, how to turn a hook off) and
   its row in docs/guides/README.md.

L5 — Sessions board archive (DESIGN § 8). Repo: knk-workspace. Branch: `claude/agent-setup-sessions-archive`.
1. `scripts/sessions-archive/archive_sessions.py`: moves every "Recently completed" entry of docs/ACTIVE_SESSIONS.md
   verbatim into docs/reports/sessions-archive/YYYY-MM.md by the entry's date (append, newest first, never
   rewrite an existing archive entry) and leaves the "In progress" table untouched. It verifies that every non-blank
   line of the original board appears exactly once across the new board and the archive files, and aborts without
   writing if not. Idempotent.
2. Run it on the branch; add a docs/reports/sessions-archive/README.md index and, in the board's "How to use"
   notes, a link to it plus the rule that finished rows go to the current month's archive file and that rows stay
   short (feature, issue, branch, repos, main areas). Report the size before and after.
3. In the PR's Admin steps: at merge, do not merge the generated files from the branch; check out fresh main, run
   the script, commit, push (the board changes all day).

## 3. Running the chain

1. Start a link with create_session: source_url https://github.com/PandiO/knk-workspace, model claude-opus-5-5,
   title "Agent setup — L<n> (<issue>)", and a prompt made of: section 0 above verbatim, the shared rules, the link's
   scope verbatim, its sub-issue number, and "Read docs/specs/ai-agent-workflow/DESIGN.md and
   docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md first." Record "create_session <id>" in the report's summary row.
2. If create_session is unavailable or the link is refused add_repo or fails its dry run, run that link once as a
   subagent (Agent tool, model opus) with the same prompt minus the add_repo sentence.
3. Never run two links at once. After starting one, end your turn and use send_later for a check-in about every
   45 minutes until it finishes; do not poll with sleep.
4. Checking a finished link: compare the heads in its report block with `git ls-remote`, check its PR exists and CI
   on it is green where CI exists, tests at or above baseline, decisions logged, sub-issue in review. If it holds,
   start the next link. If it left exit criteria unmet, retry once as a subagent; if that fails too, mark it blocked
   and continue with the next link that does not depend on it (L2–L5 do not depend on L1).
5. Do the developer-facing work yourself only for bookkeeping (issues, report, tracker); never write a link's files.

## 4. Finish

When all links are done or blocked:
1. Post one comment on the parent issue and give the developer one final message, numbered:
   1. per link: PR link, status, decisions to review;
   2. merge order for tonight: L1 (CI) → L3 → L4 → L5 (re-run the script on fresh main) and then bring `next` up to
      the new trunk tips (`git merge` the default branch into `next`) so it carries CI and the skills;
   3. the developer's own step: turn off GitHub Actions email notifications;
   4. anything blocked, with what you need from the developer.
2. Leave the tracker row "In review" (not completed) until the developer merges.
```
