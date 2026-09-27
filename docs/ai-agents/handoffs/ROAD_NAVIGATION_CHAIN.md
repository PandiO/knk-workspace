# Road navigation implementation chain — charter

**Status:** Ready to start (written 2026-09-27). For Claude Code sessions with no memory of earlier work.
**Last updated:** 2026-09-27
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27)

A chain of Claude Code sessions implements road navigation phase by phase. Each link implements **one phase**,
tests it, documents it, pushes it, writes the handoff for the next phase and hands over to a **fresh context**.
The developer tests later (evenings); **live testing is never a reason to stop** — write the checklist and go on.
Your job is to get as far as possible without doing anything the developer can't easily review or undo.

- **Phase order:** 1 → 2a → 2b → 2c → 2d → 2e → 3 → 5 → 4. Phase 4 only if KNG-17 (teleport) is on trunk (§4.7);
  otherwise the chain ends after Phase 5.
- **Plan (the how):** `docs/specs/navigation/IMPLEMENTATION_PLAN.md` — §0 rules, §1 deviations, §2 reuse map, phases.
  **Design (the what):** `docs/specs/navigation/DESIGN.md`. The plan wins where they disagree.
- **Progress report (shared, append per phase):** `docs/reports/2026-09-27-road-navigation-chain.md` (link 1
  creates it from the template in §7).
- **Handoff prompts:** this folder, `docs/ai-agents/handoffs/<date>-road-navigation-phase-<n>.md`.

## 1. Setup (every link, before anything else)

1. **Repos.** You need the workspace (`github.com/PandiO/knk-workspace`, branch `main`) and the component repos your
   phase touches: `github.com/PandiO/knk-web-api`, `knk-plugin`, `knk-web-app`. They may already be checked out (e.g.
   `/home/user/<repo>` or `Repository/<repo>` inside the workspace). If one is missing, add it to your session (the
   `add_repo` tool with push access, if your environment has it) or `git clone` it.
2. **Branch — developer's explicit instruction:** in every component repo use **one** feature branch,
   **`claude/road-navigation`**, even if your environment suggests a different branch name. If it doesn't exist on the
   remote yet, create it from trunk (`knk-web-api` `origin/master`; `knk-plugin` and `knk-web-app` `origin/main`)
   and push it with `-u`. If it exists, check it out and pull. Workspace docs go to **`main`** of knk-workspace
   (also the developer's explicit instruction).
3. **Push access check** before changing anything: `git push --dry-run origin claude/road-navigation` in each repo
   you'll change, `git push --dry-run origin main` in the workspace. Failure = absolute blocker (§4.1).
4. **Toolchains.** Java 21 for the plugin (the Gradle wrapper downloads Gradle + deps), .NET 8 SDK for knk-web-api
   (install with Microsoft's `dotnet-install.sh --channel 8.0` into `$HOME/.dotnet` if missing), Node for the web app.
5. **Network check (plugin phases):** `curl -s -o /dev/null -w "%{http_code}\n" https://repo.papermc.io/repository/maven-public/`
   and the same for `https://maven.enginehub.org/repo/`. The developer allowed both hosts for cloud sessions. If they
   still fail, knk-paper can't compile here: use the scratch-build fallback in plan §0.4, mark knk-paper code
   "**not compiled**" in the status — **not a blocker**.
6. **Builds/tests:** plugin `./gradlew build -x deployToDevServer` (plain `build` copies the jar to the developer's
   Windows dev-server path); web-api `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`; web-app
   `npm run test:ci`.
7. **Record baselines** of every module you'll change *before* changing it (plan §0.4: web-api 5 known failures by
   name; web-app count measured on the clean branch).

## 2. Read first (targeted — the plan already has file/line references; don't re-explore the codebase)

1. `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`, each touched repo's `CLAUDE.md` (knk-plugin's "no menus package" and
   "no polling" lines are stale).
2. `docs/ACTIVE_SESSIONS.md` — any "In progress" row claiming files you need?
3. The plan: §0, §1, §2, **your phase**, and the **status blocks of every phase already done** (decisions, wiring notes).
4. The DESIGN sections your phase names.
5. The progress report so far, and your handoff file.

## 3. Hard rules

- **Branches:** only `claude/road-navigation` in component repos, `main` in the workspace. **Never merge into
  trunk** (`master`/`main` of a component repo) — the developer merges after testing. Merging trunk **into**
  `claude/road-navigation` is allowed when conflicts are mechanical. Never force-push, rewrite pushed history or
  delete branches.
- **Data and servers:** never apply migrations to a real database, never connect to the developer's dev DB, never
  deploy to a Minecraft server. The web-api's "Migrations (fresh DB)" GitHub workflow checks migrations on push.
- **Siege:** never change siege behaviour; only the four mechanical edits plan §0.2 allows.
- **Reuse:** plan §2 is binding — no second copy of anything listed there; extractions keep behaviour and get their
  own commits.
- **Scope:** only your phase. Don't start Phase 6 items.
- **Files:** write Java/C#/TS sources with your file-writing/editing tools, not shell heredocs.
- **Commits** in logical chunks, attribution trailer from your environment, **push after each chunk** so the branch is
  always resumable. Keep build/test output short when reading it (tail, grep for errors) — it costs context.
- **`ACTIVE_SESSIONS.md`:** other sessions push to workspace `main` too — `git fetch` + merge before every push; on
  conflict keep both sides' rows; no conflict markers or `\r` may survive.

## 4. Absolute blockers (stop the chain)

Stop, write why in the progress report and `ACTIVE_SESSIONS.md`, push, and start no further link when:

1. You can't clone or push a repo your phase must change.
2. A module you changed doesn't build or its tests fail and you can't fix it; or a baseline test you didn't touch
   starts failing and you can't explain it. (knk-paper not compilable because of the network is **not** this case.)
3. The fresh-DB migrations workflow fails on your migration and you can't fix it (not being able to *read* CI results
   is not a blocker — flag it).
4. The phase needs an expensive-to-undo decision that DESIGN/the plan don't settle and no reversible default exists.
5. Another "In progress" session claims files you must change.
6. The previous phase's status block says its exit criteria aren't met.
7. **Phase 4 only:** KNG-17 (teleport) isn't on trunk — `git -C <knk-plugin> ls-tree -r --name-only origin/main | grep
   core/teleport/WarpTargets` finds nothing. Then don't start Phase 4: write its handoff file for later, record
   "waiting for KNG-17" in the report and tracker, and end the chain normally.

**Never a blocker:** live/in-game testing by the developer (write the checklist, continue), design details the plan
leaves open (take the most reversible default consistent with DESIGN and the code, flag it as a numbered decision),
knk-paper not compilable in the cloud.

## 5. Per phase

1. Claim: "In progress" row in `ACTIVE_SESSIONS.md` (feature "Road navigation (KNG-27)", phase, files); push.
   If Linear tools are available: set KNG-27 to *In Progress* (first link only) and add a short comment per phase.
2. `git fetch`; merge trunk into `claude/road-navigation` where trunk moved.
3. Implement the phase exactly as the plan describes; unit tests for all pure logic; commit per logical part; push.
4. Append the **"Phase N status"** block under the phase in the plan (template plan §9): commits, classes, reuse rows
   applied, test counts vs baseline, numbered decisions to review, discrepancies, **developer live checklist**, what
   later phases must wire. Update the plan header's Status/Last updated.
5. Move your tracker row to "Recently completed" (commits + one paragraph), or keep it "In progress" naming the next
   phase if the chain continues.
6. Append your phase section to the progress report and refresh its **Summary for the developer** (§7).
7. Push the workspace. Then hand over (§6).

A phase that turns out too big may be split at commit boundaries (e.g. 3a/3b); finish at a boundary, document which
part is done, and hand the rest to the next link.

## 6. Handoff — fresh context for every phase

1. Write the next phase's prompt to `docs/ai-agents/handoffs/<date>-road-navigation-phase-<next>.md` with the template
   (§8): what you left (branch heads, test counts, wiring points, open flags), phase-specific pointers, risks.
   Commit and push.
2. **Start the next link in a fresh context**, first option that works:
   1. **New session** — if you have the Claude Code Remote `create_session` tool: create one in the same environment
      with the prompt: *"Read and execute `docs/ai-agents/handoffs/<file>` in the knk-workspace repository (branch
      main). It starts with a pointer to the chain charter."* (set `source_url` to the knk-workspace repo if it asks
      for one; the link clones what else it needs, §1.1).
   2. **Fresh subagent** — otherwise (e.g. running locally): launch one general-purpose subagent (Agent tool,
      foreground) whose prompt is exactly that same sentence; when it returns, read only its summary and the
      progress report, and repeat step 2 for the phase after it. You are then the coordinator: don't implement
      yourself, just chain subagents.
   3. **Same session** — if neither exists: re-read this charter and the handoff you just wrote, then continue (your
      context is summarised automatically as it grows).
   Record in the progress report which option you used.
3. Start **at most one** next link, never one for a phase the report marks done or in progress. Stop after the last
   phase (§ top) or at an absolute blocker.

## 7. Progress report

`docs/reports/2026-09-27-road-navigation-chain.md` (dated by chain start; reports are never overwritten, only
appended). Link 1 creates it with:

```
# Road navigation chain — progress report

**Status:** <running | finished | stopped: reason>
**Last updated:** <date> (link <k>: Phase <N>)

## Summary for the developer
- Phase table: phase | state (done / partial / not started / waiting) | branch heads | details link
- Review first: the few flagged decisions worth a look, ranked.
- Test when you have time: one combined order — pull `claude/road-navigation` in each repo; build the plugin
  (`./gradlew build -x deployToDevServer`, fix compile errors first if any link marked knk-paper "not compiled");
  apply the new web-api migration to the dev DB (developer only); run the web-api; `./gradlew :knk-paper:dev`; then
  each phase's live checklist from the plan in phase order.

## Phase <N> — <title> (link <k>)
Commits per repo; tests vs baseline; flagged decisions; discrepancies; short live checklist (pointer to the plan's
full one); risks; how the next link was started.
```

## 8. Handoff prompt template

```
Read docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md first and follow it; it overrides anything below.

Implement road navigation Phase <N> — <title> from docs/specs/navigation/IMPLEMENTATION_PLAN.md, end to end (code,
tests, commits, push to claude/road-navigation, plan status block, progress report, handoff), as link <k> of the chain.

State you start from: <branch heads per repo, test baselines/counts, what earlier phases left>.
What earlier phases say Phase <N> must wire: <list with class/method names>.
Phase-specific reading: <plan sections, DESIGN sections, files>.
Open flags that affect this phase: <list>.
Known risks: <list>.
Next after you: Phase <M> (or: last link — stop after the write-up).
```

## 9. Facts at chain start (2026-09-27)

- **Trunk heads when the plan was verified:** knk-web-api `master` `acaee99`, knk-plugin `main` `ceed2f6`, knk-web-app
  `main` `46be4e9`. Trunk may have moved since — fetch; `claude/road-navigation` doesn't exist yet (link 1 creates it
  in the repos it touches; later links create it in theirs).
- **KNG-17 (teleport)** is on `origin/claude/teleport` in knk-plugin, **not on trunk** — Phase 4 waits for it (§4.7).
  Domain discovery, currency and private messages are already on trunk.
- **Siege** is being playtested in parallel on `claude/siege-minigame` branches; its code on trunk is what the plan
  references. Don't touch the siege branches.
- **Cloud network:** the developer allowed `repo.papermc.io` and `maven.enginehub.org` for cloud sessions
  (2026-09-27); verify per §1.5.
- **Developer availability:** tests after work hours; nothing in this chain waits for them.
