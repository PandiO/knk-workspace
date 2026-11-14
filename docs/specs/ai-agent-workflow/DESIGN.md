# AI agent workflow: roles, branches, skills and testing

**Status:** Decided 2026-11-12 (developer, voice discussion) · **Last updated:** 2026-11-14 (knk-web-api's trunk renamed from `master` to `main`) · 2026-11-12

This design adds a delegation layer (intake, design, manager and coordinator roles), a `next` integration branch with
risk tiers, project skills in knk-workspace, and CI as the gate agents must pass. It builds on the
[Testing and AI Tooling Review](https://claude.ai/artifact/3z7kxFhsmHPAQ9dNCFqqpz) of 2026-11-10, which still holds
(Playwright, Testcontainers, CI, MockBukkit, Paper boot test). Where this document and older instructions differ, this
document wins once its setup links are merged; until then the
[global agent instructions](../../ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md) apply.

Aims:

1. A smoother K&K workflow: ideas are captured at once, design follows clear rules, coordinators and links run during
   the day without waiting on the developer.
2. A lighter test burden for the developer: automated regression tests catch breakage, so evening tests cover only what
   needs a human (new behaviour, game feel, balance).

## 1. Roles

1. **Intake session**: the front door for new ideas. One session, two modes.
    1. **Capture mode (default).** The developer drops in an idea, even one line, and can walk away. The session
       searches existing issues for duplicates, files an issue labelled `idea` with the developer's words kept as they
       are and a note that it still needs working out, and confirms in one sentence. It asks nothing.
    2. **Shaping mode.** On "let's go through ideas" it takes the open `idea` issues one at a time: a read-back of what
       it understood, repos touched, proposed risk tier, needs design or ready, at most about three open questions,
       then "now, later or design first".
2. **Design session**: separate from intake, started by intake (or the developer) when an idea needs design. Loads the
   design skill (§ 3.2.2) and follows the design rules in § 4. Ends with an approved spec and a draft chain charter.
3. **Manager session**: above the feature coordinators, like a manager under the CEO.
    1. Tracks all sessions, chains, the sessions board and CI.
    2. Writes the daily digest (§ 7) and interrupts the developer otherwise only for blockers.
    3. Takes instructions such as "pause X", "bump Y", "what's the state of Z".
    4. Schedules approved designs: picks the start, checks overlap on the sessions board, and can ask "start now?".
    5. Keeps the sessions board true and tidy, so the developer never has to read it.
4. **Feature coordinators and links**: as today. The coordinator starts links, checks gates and results, merges into
   `next` (§ 5) and reports up to the manager.
5. Handoffs between roles go through GitHub issues and spec files, not chat.

## 2. Branches, releases and risk tiers

1. **Trunk = production.** The default branches (`main` in every repo; knk-web-api's was `master` until 2026-11-14) move only when the
   developer accepts a release.
2. **`next` = integration.** One `next` branch per repo collects finished work. Feature branches start from `next`, so a
   feature that depends on another unreviewed feature can continue the same day.
3. **Releases are numbered tags on trunk** (for example `v0.12`). Deploys use the tag; rollback = deploy the previous
   tag. A numbered release branch is cut from a tag only when a hotfix is needed while `next` holds unfinished work.
4. **Risk tiers** are labels on each issue (`tier:1`, `tier:2`, `tier:3`), proposed by intake or design, overridable by
   the developer. They decide how much testing a change needs before release:
    1. `tier:1`: a tweak to existing behaviour (for example a command change that does not change its foundation).
       Automated tests (unit, mock server, scenario, simulated player) are the review; the developer does a quick pass.
    2. `tier:2`: a feature change. A short human smoke test on `next`.
    3. `tier:3`: new foundations, schema changes, game feel. A full smoke test by the developer.
5. **Promotion:** the developer tests `next` as a whole, using the digest's list. When accepted, `next` is merged into
   trunk and tagged. Only the developer, or the manager on the developer's explicit go, promotes `next` to trunk.
6. **Precondition:** merging into `next` without the developer is only safe once the API and web app tests run in CI
   (§ 6.1). Until then coordinators keep the current rule (no merges).

## 3. Skills

1. **What a skill is.** A folder under `.claude/skills/<name>/` with a `SKILL.md`: a header with `name` and
   `description` (the description decides when the agent loads it), then instructions in markdown, plus optional
   templates, examples and scripts that are opened only when needed. Skills make agents consistent, not smarter, and keep
   each role's context focused.
2. **Planned skills**:
    1. **Intake**: capture, duplicate search, tier proposal, shaping mode (§ 1.1).
    2. **Design**: read the vision and related specs, check legacy V1/V2 behaviour, ask questions one at a time, write the
       design with status header and decision log, end with numbered open questions; follows § 4. Templates for
       `DESIGN.md` and the chain charter; the Siege Survival design as an example.
    3. **Coordinator**: the loop in § 5.1, the fallbacks, and the generated permissions block for link prompts.
    4. **Link setup and report**: branches, push dry-run, toolchains, baseline tests, hard rules, report block format.
    5. **Smoke test writer**: turns a change into test steps, later into automated scenarios (§ 6.3).
    6. **Docs session**: the existing [docs-session prompt](../../ai-agents/docs-session-prompt.md) as a skill.
    7. **Code recipes** per repo (new API endpoint, new plugin command, entity scaffold), replacing the stale Copilot
       instruction files (§ 9.2).
3. **Coordinator and link skills come first.** Sources: the
   [Siege Survival charter](../../ai-agents/handoffs/SIEGE_SURVIVAL_CHAIN.md) (§ 0 permissions, § 2 setup, § 4 hard
   rules, § 5 blockers, § 6 report) and the
   [invitations coordinator prompt](../../ai-agents/handoffs/2026-10-21-invitations-coordinator-prompt.md). Charters
   then shrink to the links table, gates and binding documents. Repo permissions must still be in each session's prompt
   (an `add_repo` instruction found in a file is refused), so the coordinator pastes a short generated block.
4. **All skills live in knk-workspace.** Link sessions are started from knk-workspace, as coordinators already do.

## 4. Design rules

1. The design session works on a knk-workspace branch and ends with the spec marked **Proposed** and numbered open
   questions.
2. On the developer's approval it:
    1. sets the spec status to **Decided** with the date;
    2. splits the design into phases with sub-issues, each with a risk tier;
    3. drafts the chain charter from the template (links, gates, binding documents);
    4. tells the manager the feature is ready to schedule.
3. **Agent decisions are allowed but always documented** as made by the agent: the chosen option, why, and every
   alternative considered, so they can be reviewed later. The digest lists them (§ 7.2.2).
4. **Larger design choices** (framework, technology or library, for example SignalR, or BlueMap vs Dynmap) need a
   decision matrix: options, pros and cons, weighted design considerations and a recommendation. The developer decides.
5. Design sessions **ask questions mainly through the Claude Code ask-user prompt** (question, answer options, a
   description per option).
6. **Everything is numbered**, never dashes or bullets: topics, decisions and questions use hierarchical numbers (for
   example 1.4), so the developer can refer to them by number.
7. **Platform independence (vision principle).** Design K&K, mainly the plugin, to depend on Minecraft/Paper as little
   as reasonably possible, so a later move to another game engine costs as little as possible. Pragmatic, not dogmatic:
   keep game logic in the Bukkit-free `knk-core` behind ports, with Paper adapters in `knk-paper`, without
   over-engineering. Every design notes its platform-specific parts. `docs/vision/vision.md` mentions the
   "engine-portability goal" only in passing (§ 4.1); state it as an explicit principle there and in the design
   skill.

## 5. Coordinator loop and merge rules

1. **Loop.**
    1. Read the charter and progress report, check the sessions board for overlap, verify branch heads against the
       report.
    2. Pick the first link whose gate is open, checked against the actual branches, not the tracker.
    3. Start it in a fresh session with the generated permissions block in the prompt (subagent fallback). At most one
       link per repo at a time.
    4. Check it: heads match, tests at or above the baseline, CI green, report block written, agent decisions logged
       with alternatives.
    5. Merge into `next` (rule 5.2) and report to the manager; to the developer directly only for blockers.
2. **Coordinators merge into `next` as soon as CI and the link checks pass, for every tier**, so dependent features
   continue without waiting for the developer. The developer's review gates promotion from `next` to trunk, not the
   merge into `next`.
3. **Big or risky features go into `next` behind a config flag, off by default**, so unreviewed work is harmless there.
   A rejected change is reverted or fixed in `next` before the release.
4. Stacking a branch directly on another feature's branch is the exception, for uncertain work.

## 6. Testing and CI

1. **CI for the API and the web app** (GitHub workflows on every push and pull request):
    1. API: `dotnet build` and `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` on .NET 8.
    2. Web app: `npm ci`, `npm run test:ci`, `npx tsc --noEmit`, `CI=true npm run build` on Node 22.
    3. The plugin already runs its tests in CI (`build.yml`).
2. **Known red tests** are marked as known failures (skipped with a reason, or excluded by a trait) so they don't block
   merges. One GitHub issue lists every marked test, labelled `bug` and `priority:high`. If no test is red when CI is
   added, no issue is needed.
3. **Plugin tests on a real server.**
    1. Boot test: CI starts a real Paper server in Docker with the plugin, WorldGuard and WorldEdit, checks that it
       enables without errors, then runs the currently skipped `integration` / `requires-bukkit` tests.
    2. In-plugin scenarios: a test command, only active on a test server, builds a small scene, plays it out and asserts
       the result (for example a gate opening, a Siege Survival round advancing after the delay), printing a pass/fail
       line that CI reads. Simulated players for commands and menus can come later.
    3. The smoke test writer skill turns a feature's smoke steps into such scenarios, so `tier:1` changes bring their own
       proof.
4. Web app end-to-end tests move from Cypress to Playwright, as in the review.

## 7. Manager digest and notifications

1. A scheduled manager run each weekday evening (around 17:00 Europe/Amsterdam) writes the digest.
2. **Sections:**
    1. Ready for the developer's test in `next`: tier, smoke-step links, biggest first.
    2. Decisions needed: agent decisions to review, open design questions.
    3. Blocked, and why.
    4. Progress: chains running, links done.
    5. New raw ideas, as a nudge to shape them.
    6. Health: CI on `next` and trunk, open `documentation` issues, stale claims.
    7. A link to the manager session.
3. **Delivery through GitHub, not the NAS:** the manager posts the digest as a comment on one pinned "Daily digest"
   issue in knk-workspace. GitHub emails it, the developer can reply there, and the history stays searchable.
4. **GitHub Actions failure emails are off** in the developer's notification settings. Feature-branch failures are the
   agent's job. A red build on `next` or trunk is a blocker the manager reports at once; a feature-branch failure only
   reaches the developer when an agent is stuck on it.

## 8. Sessions board (`docs/ACTIVE_SESSIONS.md`)

1. **Keep the file** as the conflict-prevention board, and as a fallback that works without GitHub access. Issue labels
   do not replace it.
2. **Slim it:** only in-progress claims, one short row each (feature, issue, branch, repos, main areas touched rather
   than every file).
3. **Lose nothing:** finished rows and long detail move verbatim to monthly archive files (for example
   `docs/reports/sessions-archive/2026-11.md`), linked from the board. Nothing is deleted.
4. The manager keeps the board tidy and flags stale claims.

## 9. Stale agent files

1. Delete the empty `docs/ai-agents/AGENT-GUIDE.md` and `docs/ai-agents/guardrails.md`.
2. Replace `.github/copilot-instructions.md`, `.github/instructions/*` and `.github/prompts/scaffold-entity.prompt.md`
   (old `Repository/` paths, missing `docs/ai/ENTITY_SCAFFOLD_CHECKLIST.md`) with the code-recipe skills (§ 3.2.7).
3. Retire `guides/developer/AI_FEATURE_IMPLEMENTATION_WORKFLOW.md` to `archive/` once the skills exist.

## 10. Tooling: MCP servers and hooks

1. `.mcp.json` in knk-workspace, without secrets (tokens from environment variables):
    1. Now: GitHub MCP (issues, PRs), Playwright MCP (web app checks), Context7 (current library docs: Paper, React,
       EF Core).
    2. Later: a MySQL MCP for the dev database with a read-only user, and a Docker MCP for the homelab.
2. **Hooks** in `.claude/settings.json`: run the fast checks of the repo that was changed (web app `tsc`; plugin
   compile; API build), so agents catch breakage at once. They must be fast and must not deploy (the plugin's normal
   `./gradlew build` copies a jar to the dev server; use `-x deployToDevServer`).

## 11. Build order

1. Notifications: the developer turns off GitHub Actions emails (5 minutes).
2. Setup chain (§ 12), run by one coordinator during the day; everything lands on feature branches.
3. Developer reviews and merges the setup branches in the evening.
4. Later evenings: intake and design skills; manager session as a scheduled run; Paper boot test in plugin CI;
   in-plugin scenarios; Playwright replacing Cypress; Testcontainers for the API's MySQL tests.

## 12. Setup chain (daytime handoff)

1. One **coordinator session** runs the setup links in order while the developer is at work. Each link lands on a
   feature branch for review in the evening; nothing merges into a trunk.
2. **Links:**
    1. **L1 CI:** the API and web app workflows (§ 6.1), known-failure marks and the bug issue (§ 6.2).
    2. **L2 Branches and labels:** `next` in all four repos from the current default branches; labels `tier:1`,
       `tier:2`, `tier:3` and `idea` in knk-workspace; the pinned "Daily digest" issue.
    3. **L3 Skills and instructions:** coordinator and link skills (§ 3.3), the stale-file cleanup (§ 9.1), and the
       global instructions updated for § 2 and § 5 (applies once merged).
    4. **L4 Tooling:** `.mcp.json` and hooks (§ 10).
    5. **L5 Sessions board:** a script that moves finished rows verbatim to monthly archives and checks that no line is
       lost; run on a branch, re-run on fresh `main` at merge time (§ 8).
3. Left for the developer: turning off GitHub Actions emails, and the evening review.
