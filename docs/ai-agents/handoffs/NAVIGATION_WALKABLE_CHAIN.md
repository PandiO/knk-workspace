# Navigation walkable-path chain — charter

**Status:** Finished 2026-10-02 (links 1-4 done; outcome, live checklist and merge order in the progress report). Kept as the record of how the chain ran.
**Last updated:** 2026-10-02
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27) (reconcile/close out), [KNG-51](https://linear.app/kngpandi/issue/KNG-51) (implement)

A chain of **four** Claude Code sessions ("links"). Each link implements **one phase**, tests it, documents it, pushes it,
writes the handoff for the next link and hands over to a **fresh context**. The developer tests later; **live testing is
never a reason to stop** — write the checklist and go on. Do nothing the developer can't easily review or undo.

| Link | Phase | Repo(s) |
|---|---|---|
| 1 | **KNG-27 reconciliation** — verify the §5.5 fix plan (items 1-6) against what is actually on the navigation branches, record it, close small gaps | knk-workspace (+ knk-plugin read/run) |
| 2 | **KNG-51 Phase A** — `knk-core roads/walk/`: `WalkGrid`, `WalkSearch`, `CellAccess`, `MovementProfile`, rules, tests | knk-plugin |
| 3 | **KNG-51 Phase B** — knk-paper: `WalkSnapshotService` (capture, cache), cell access adapters (gates, domains, doors), ladder/door cell capture | knk-plugin |
| 4 | **KNG-51 Phase C** — `DirectLeg` refactor, walk path in direct mode, `TrailRenderer.drawPath`, config, messages, kill switch; final write-up | knk-plugin |

**Not in this chain:** KNG-51 Phase D (routed start/end legs — waits for the developer's live test), the live test of
decision §11-5, any siege change, merging into trunk.

- **Design (binding):** `docs/specs/navigation/LAST_MILE_PATHFINDING.md` — all §11 decisions are the developer's.
  **Parent design / plan:** `docs/specs/navigation/DESIGN.md`, `IMPLEMENTATION_PLAN.md` (§0 rules, §2 reuse map, §5.5).
- **Progress report (append per link):** `docs/reports/2026-10-02-navigation-walkable-chain.md` (link 1 creates it, §7).
- **Handoff prompts:** this folder, `docs/ai-agents/handoffs/2026-10-02-navigation-walkable-link-<n>.md`.

## 1. Setup (every link, before anything else)

1. **Repos.** Workspace `github.com/PandiO/knk-workspace` (`main`) and `github.com/PandiO/knk-plugin`; they may be checked
   out already (`/home/user/<repo>`). If missing, add it with `add_repo` (push access) or `git clone`.
   `knk-web-app` / `knk-web-api` only if a gap in link 1 requires a change there (§3).
2. **Branch — developer's explicit instruction: ONE feature branch, `claude/navigation-walkable-path`**, in every
   component repo you change, even if your environment suggests another name. Workspace docs go straight to **`main`**
   (no feature branch there).
   - **Create it (link 1, or the first link that needs the repo):** `git fetch`, then branch from
     `origin/claude/road-navigation` (the navigation feature branch; knk-plugin trunk `main` is already contained in it),
     `git merge origin/<trunk>` (trunk: knk-plugin/knk-web-app `main`, knk-web-api `master`; mechanical conflicts only),
     push with `-u`. If it exists, check it out and pull.
   - **Every link, at the start and again before the final push:** `git fetch` and merge `origin/claude/road-navigation`
     and trunk into `claude/navigation-walkable-path`. **The developer commits to `claude/road-navigation` while
     testing**; their fixes must flow in. A conflict that isn't mechanical is an absolute blocker (§4).
   - **Never push to `claude/road-navigation`** (or `claude/road-navigation-smoke-test-bugs-*`), never merge into trunk.
3. **Push check** before changing anything: `git push --dry-run origin claude/navigation-walkable-path` per code repo,
   `git push --dry-run origin main` in the workspace. Failure = absolute blocker.
4. **Toolchain (plugin):** Java 21; `~/.gradle/gradle.properties` with `org.gradle.workers.max=2`,
   `systemProp.org.gradle.internal.repository.max.tentatives=6`, `systemProp.org.gradle.internal.repository.initial.backoff=1500`
   (avoids Maven Central 429s); `--offline` after the first build. Network check: `curl -s -o /dev/null -w "%{http_code}\n"
   https://repo.papermc.io/repository/maven-public/` and `https://maven.enginehub.org/repo/` (both allowed for cloud
   sessions). If they fail, knk-paper can't compile: mark knk-paper code "**not compiled**" — not a blocker.
5. **Builds/tests:** `./gradlew build -x deployToDevServer` (plain `build` copies the jar to the developer's Windows dev
   server path). **Record the module test counts before changing anything** (baseline) and compare at the end.

## 2. Read first (targeted — don't re-explore the codebase)

1. `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`, `knk-plugin/CLAUDE.md` (+ its `AGENTS.md`).
2. `docs/ACTIVE_SESSIONS.md` — does another "In progress" row claim files you need? (The developer was committing to
   `claude/road-navigation` on 2026-10-02; if a row or fresh commits there overlap your files, coordinate, see §4.5.)
3. `LAST_MILE_PATHFINDING.md` (all of it, every link) and your handoff file.
4. The progress report so far.

## 3. Hard rules

- **Scope:** only your link. **Reuse:** `IMPLEMENTATION_PLAN.md` §2 and `LAST_MILE_PATHFINDING.md` §2 are binding — extract
  from `SpanGrid`/`PassabilityRules`/`CompactSurfaceGrid` instead of copying; an extraction keeps behaviour, gets its own
  commit, and the existing tests are its proof.
- **Siege and data:** never change siege behaviour; never touch a real database or the developer's servers.
- **Direct-mode behaviour already shipped on the navigation branch must not change** except where the design says so;
  `navigation.walk.enabled: false` must reproduce today's behaviour exactly.
- **Files:** write sources with your file tools, not shell heredocs. **Commits** in logical chunks with the attribution
  trailer from your environment, **push after each chunk**. Keep build/test output short (tail/grep) — it costs context.
- **`ACTIVE_SESSIONS.md`:** other sessions push to workspace `main` too — `git fetch` + merge before every push; on
  conflict keep both sides' rows; no conflict markers may survive.
- **Link 1 may fix** a small, clearly-scoped gap in a §5.5 item (≤ ~1 focused commit each, with a test); a larger one is
  written up for the developer, not fixed. No new features.
- Never force-push, rewrite pushed history or delete branches.

## 4. Absolute blockers (stop the chain)

Stop, write why in the progress report and `ACTIVE_SESSIONS.md`, push, start no further link when:

1. You can't clone or push a repo your link must change.
2. A module you changed doesn't build or its tests fail and you can't fix it; or a baseline test you didn't touch starts
   failing and you can't explain it. (knk-paper not compilable because of the network is **not** this case.)
3. A merge of `origin/claude/road-navigation` or trunk into the feature branch has non-mechanical conflicts.
4. The link needs an expensive-to-undo decision that the design doesn't settle and no reversible default exists.
5. Another "In progress" row claims files you must change.
6. The previous link's status says its exit criteria aren't met.

**Never a blocker:** live testing, design details left open (take the most reversible default consistent with the design,
flag it as a numbered decision), knk-paper not compilable in the cloud.

## 5. Per link

1. Claim: update the chain's "In progress" row in `ACTIVE_SESSIONS.md` (link number, files); push. Linear (if the tools
   exist): link 1 comments on KNG-27; link 2 sets KNG-51 to *In Progress*; every link adds a short comment.
2. Setup (§1): fetch, merge `claude/road-navigation` + trunk, record baselines.
3. Implement the link exactly as the design's phase table / its §N sections describe; unit tests for all pure logic.
4. Append a **"Link N status"** block to the progress report (commits, classes, reuse rows applied, test counts vs
   baseline, numbered decisions, discrepancies, developer live checklist, what the next link must wire) and, for KNG-51
   links, a short "Phase X status" note under the design's §10 table. Update the design's Status/Last-updated.
5. Merge `claude/road-navigation` + trunk once more, push the feature branch, update the tracker row, push the workspace.
6. Hand over (§6).

### Link specifics

- **Link 1:** for each §5.5 item 1-6, find the commit(s) on `claude/road-navigation` (items 2-4: knk-plugin `6a73945`;
  5: `9f66fea`; 6: `ef556e2` and knk-web-api `8523ec8`/`c029186`; 1: knk-web-app `6414e18`; the developer added more
  KNG-27 fixes after) and check: code present as the plan describes, tests exist and pass, plan "Verify" step status
  (code-verified vs needs live). Then: append a "§5.5 status" block to `IMPLEMENTATION_PLAN.md`, add cross-references in
  `docs/guides/road-navigation-smoke-test.md` where findings were fixed, update the KNG-27 tracker rows (the 2026-10-01
  "paused" row is stale), create the progress report and the **baseline test counts** for links 2-4, create the feature
  branch in knk-plugin. List anything not done (item 6's residual cases need the developer's live check). Write link 2's
  handoff.
- **Link 2 (Phase A):** design §3-§6 core parts, §4 rules (incl. ladders, doors-as-conditional-cells, drop penalty 10),
  §5 search, §12 fixtures. Pure Bukkit-free; record the 96×96 open-field timing. `SpanGrid` delegates to the extracted
  `WalkGrid`, behaviour unchanged.
- **Link 3 (Phase B):** design §6 (cell access: gates via `GateAvailability` logic, denied regions, door cells checked by
  **WorldGuard `USE`/`INTERACT` and the KnK domain rules**), §8 (capture, `TickBudget`, TTL cache, loaded chunks only),
  ladder/door cell capture, verify the "permissive `roadFloor`" capture. Check off-thread safety of region `contains`.
- **Link 4 (Phase C):** design §7, §9, §10 Phase C. Final write-up: summary for the developer, combined live checklist
  incl. decision §11-5 (fallback vs partial path) and the §12 in-game matrix, how to merge (branch → trunk order) and
  which branches to delete afterwards.

## 6. Handoff — fresh context for every link

1. Write the next link's prompt to `docs/ai-agents/handoffs/2026-10-02-navigation-walkable-link-<n+1>.md` using §8: what
   you left (branch heads, test counts, wiring points, open flags), phase pointers, risks. Commit and push.
2. **Start the next link in a fresh context**, first option that works:
   1. **New session** — with the Claude Code Remote `create_session` tool, in the same environment, model
      `claude-opus-5-5`, prompt: *"Read and execute `docs/ai-agents/handoffs/<file>` in the knk-workspace repository
      (branch main). It starts with a pointer to the chain charter."* (set `source_url` to the knk-workspace repo if asked.)
   2. **Fresh subagent** — otherwise: one general-purpose subagent (Agent tool, foreground) with exactly that sentence; read
      only its summary and the progress report afterwards, then repeat for the next link. You are then a coordinator.
   3. **Same session** — if neither exists: re-read this charter and the handoff, then continue.
   Record in the progress report which option you used.
3. Start **at most one** next link, never one the report marks done or in progress. After link 4 (or at a blocker) stop.

## 7. Progress report

`docs/reports/2026-10-02-navigation-walkable-chain.md` (never overwritten, only appended). Link 1 creates it:

```
# Navigation walkable-path chain — progress report

**Status:** <running | finished | stopped: reason>
**Last updated:** <date> (link <k>)

## Summary for the developer
- Link table: link | state | branch heads | details
- Review first: the few flagged decisions worth a look, ranked.
- Test when you have time: pull `claude/navigation-walkable-path` in knk-plugin; `./gradlew build -x deployToDevServer`;
  `./gradlew :knk-paper:dev`; then the live checklist.

## Link <N> — <title>
Commits; tests vs baseline; flagged decisions; discrepancies; short live checklist; risks; how the next link was started.
```

## 8. Handoff prompt template

```
Read docs/ai-agents/handoffs/NAVIGATION_WALKABLE_CHAIN.md first and follow it; it overrides anything below.

Implement link <k> — <title> end to end (code, tests, commits, push to claude/navigation-walkable-path, progress report,
handoff) as link <k> of the chain.

State you start from: <branch heads per repo, test baselines/counts, what earlier links left>.
What earlier links say this link must wire: <class/method names>.
Phase-specific reading: <design sections, files>.
Open flags that affect this link: <list>.
Known risks: <list>.
Next after you: link <k+1> (or: last link — stop after the write-up).
```

## 9. Facts at chain start (2026-10-02, ~19:00 UTC)

- **Heads:** knk-plugin `origin/claude/road-navigation` `075ae94` (trunk `main` `27b4236` is contained in it; the branch is 58
  commits ahead); knk-web-app `6414e18` (trunk `main` `ba0c77d`, contained); knk-web-api `c029186` (trunk `master` `29b6c5d`
  has 19 commits the branch lacks). `claude/road-navigation-smoke-test-bugs-fagl4i` is identical to `claude/road-navigation`
  in all three repos. Nothing of KNG-27 is merged to trunk yet.
- **Already on `claude/road-navigation`:** the whole §5.5 fix plan (items 1-6) per commit messages written by a Claude
  session on 2026-10-02 (session `session_017D6f672qgZJ5LqpJLfFjQS`), plus the developer's own smoke-test fixes
  (`/knk road node prune|unprune`, floor-block recording, Boundary-node fix, two-arm junction join) up to 18:00 CEST.
  Workspace docs did **not** record any of it at chain start — link 1 fixes that.
- **Direct mode today:** straight-line trail in `NavigationService.startDirect`/`tickDirect`, own recheck
  `recheckDirect` (message `directRecalculating`), `arrivedAtRouteEnd` → direct for the last leg; `TrailRenderer.drawLeg`
  draws straight legs. KNG-51 replaces the straight line with a walkable path (design §7).
- **Developer availability:** tests after work hours; nothing in this chain waits for them.
