# Siege overnight implementation chain — charter

**Status:** Active from 2026-09-26 (evening). Written for Claude Code cloud sessions with no memory of earlier work.
**Last updated:** 2026-09-26

The developer is asleep. A chain of Claude Code cloud sessions implements the remaining siege phases one after
another, each documenting and pushing its work, then hands over to a fresh session for the next phase. In the
morning the developer smoke-tests everything on the live dev server. Your job is to get as far as possible
**without** doing anything the developer can't easily review or undo.

- **Phase order:** 6 → 7a → 8b → 7b → 9 (non-live parts only). Stop after Phase 9. Never start Phase 10.
- **Plan:** `docs/specs/siege-minigame/IMPLEMENTATION_PLAN.md`; decisions: `DESIGN.md`; menus: `MENU_TEMPLATES.md`.
- **Morning report (shared, append-only per phase):** `docs/reports/2026-09-26-siege-overnight-chain.md`.
- **Handoff prompts:** this folder, `docs/ai-agents/handoffs/<date>-siege-phase-<n>.md`.

## 1. Setup (every session, before anything else)

1. You run in a clone of **knk-workspace** (`github.com/PandiO/knk-workspace`, branch `main`). The component repos
   are separate GitHub repos, ignored by the workspace (`Repository/*`). Clone the ones your phase needs into
   `Repository/<name>` and check out the standing branch:
   - `github.com/PandiO/knk-plugin` → `claude/siege-minigame`
   - `github.com/PandiO/knk-web-api` → `claude/siege-minigame`
   - `github.com/PandiO/knk-web-app` → `claude/siege-minigame` (only if your phase needs the web app)
2. **Check push access** before changing anything: `git push --dry-run origin claude/siege-minigame` in each repo you
   will change, and `git push --dry-run origin main` in the workspace. A failure is an absolute blocker (§4).
3. **Toolchains:** Java 21 (the plugin's Gradle wrapper downloads Gradle and Paper; network is fine), .NET 8 SDK for
   knk-web-api (`net8.0`), Node only for the web app. If one is missing, try installing it (e.g. Microsoft's
   `dotnet-install.sh --channel 8.0` into `$HOME/.dotnet`). If you can't, you can't verify that repo: blocker for
   any phase that must change it.
4. **Builds:** plugin: `./gradlew build -x deployToDevServer` from `Repository/knk-plugin` (a plain `build` also
   tries to copy the jar to the developer's Windows dev server path from `gradle.properties`). Web-api:
   `dotnet build` and `dotnet test` (test project under `tests/`).
5. **Record baselines before you change anything** (test counts per module, the names of failing web-api tests).

## 2. Read first

1. `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`, root `CLAUDE.md`, each cloned repo's `CLAUDE.md` (knk-plugin's
   "no gui/menus package" line is stale; `paper/menu/` exists).
2. `docs/ACTIVE_SESSIONS.md`: anything "In progress" that overlaps your files?
3. The plan: §0, **your phase**, and the **Phase 4 and Phase 5 status blocks** (decisions, "What Phase N must
   wire", playtest fixes), plus the status blocks of phases this chain already finished.
4. `DESIGN.md`: the sections your phase names, plus §5 (authority split, threading: one sync 1 s ticker, never
   block on HTTP) and §12 (legacy defects you must not reintroduce).
5. The morning report so far (what earlier links did, decided and flagged).
6. Your handoff prompt's phase-specific reading list.

## 3. Hard rules (never break these)

- **Branches:** work only on `claude/siege-minigame` in each component repo and on `main` in the workspace. Never
  merge into `main`/`master` of a component repo. Merging `origin/main` (plugin, web-app) or `origin/master`
  (web-api) **into** `claude/siege-minigame` before a phase is allowed (plan §0) when the conflicts are mechanical;
  otherwise it's a blocker. Never force-push, rewrite pushed history or delete branches.
- **Data and servers:** never apply migrations to a real database, never connect to the developer's dev DB
  (LAN, unreachable from the cloud anyway), never deploy to a Minecraft server. Migrations are checked by the
  web-api's GitHub Actions "Migrations (fresh DB)" workflow, which runs on every push.
- **Other sessions:** don't touch `claude/menu-content` (the InventoryMenu content-port session) or any file another
  "In progress" row claims. Don't change GitHub settings, secrets or workflows.
- **Scope:** only what your phase needs. Keep `core/siege/` free of Bukkit/Paper imports. Pure logic goes in knk-core
  with JUnit tests.
- **Files:** write Java/C# sources with your file-writing tool, not shell heredocs (quoting broke earlier sessions).
- **Commits** end with the attribution trailer your environment gives you. Commit in logical chunks and push after
  each part, so the branch is always resumable.
- **`ACTIVE_SESSIONS.md`:** stage only your own edit (build the blob from `git show HEAD:docs/ACTIVE_SESSIONS.md`
  plus your change, `git hash-object -w`, `git update-index --cacheinfo`). On a merge conflict keep both sides' rows
  and check that no `<<<<<<<`/`=======`/`>>>>>>>` line and no `\r` survives. Other sessions push to workspace
  `main` too: `git fetch` + merge before every push.

## 4. Absolute blockers (stop the whole chain)

Stop, write why in the morning report (§7) and in `ACTIVE_SESSIONS.md`, push, and don't start another session when:

1. You can't clone or push a repo your phase must change.
2. A module you changed doesn't build, or its tests fail, and you can't fix it; or a baseline test you didn't touch
   starts failing and you can't explain it.
3. The fresh-DB migrations workflow fails on your pushed migration and you can't fix it. (If you can't read CI
   results at all, that is **not** a blocker: flag it for the morning.)
4. The phase needs a decision that is expensive to undo and DESIGN/the plan don't settle it (a data-model shape
   beyond DESIGN, removing/renaming existing public API or endpoints, anything security-sensitive such as who may
   call a write endpoint beyond what DESIGN says), **and** no reversible default exists. Prefer a reversible
   default, flagged; stop only when there is none.
5. Another "In progress" session claims files you must change.
6. The previous phase's status block says its code exit criteria aren't met.

Everything else is **not** a blocker: pick the most reasonable default consistent with DESIGN and the existing code,
record it as a flagged decision, and keep going. Missing live verification is expected, not a blocker.

## 5. Per phase

1. Claim: add an "In progress" row to `ACTIVE_SESSIONS.md` (commit only your row, push).
2. `git fetch`; merge trunk into `claude/siege-minigame` where it moved (§3).
3. Implement, test (unit tests for all pure logic), commit per logical part, push.
4. Write a **"Phase N status"** block under the phase in the plan, in the style of the Phase 4/5 blocks: commits;
   classes/packages; what's done; test counts vs baseline; flagged decisions (numbered, each cheap to change or
   not); doc/code discrepancies; the **manual live-verification checklist** (numbered steps); what later phases must
   wire; follow-ups. Update the plan header's Status and Last updated lines.
5. Move your row to "Recently completed" with commits and a one-paragraph summary.
6. Append your phase section to the morning report and refresh its "Morning summary" (§7).
7. Push the workspace. Then hand over (§6).

If a phase turns out too big, split it into parts at commit boundaries (like 5a/5b/5c) and finish at a boundary.

## 6. Handoff

1. Write the next phase's prompt to `docs/ai-agents/handoffs/<date>-siege-phase-<next>.md` using the template (§8):
   what you left (commits, wiring points, open flags), phase-specific pointers, known risks. Commit and push.
2. **Start the next session** if your tools can: e.g. the Agent tool with `isolation: "remote"`, `RemoteTrigger`, or
   the `schedule` skill for a one-time run. Give it exactly: *"Read and execute
   `docs/ai-agents/handoffs/<file>` in the knk-workspace repository (branch main). It starts with a pointer to the
   chain charter."* Record in the morning report how you started it.
3. **If you can't start one,** continue with the next phase yourself in this session (your context is summarized
   automatically as it grows): re-read the handoff file you just wrote and the charter, then go on.
4. Start at most **one** next session, and never one for a phase the morning report already marks done or in
   progress. Stop after Phase 9, or at an absolute blocker.

## 7. Morning report

`docs/reports/2026-09-26-siege-overnight-chain.md`. Each session appends its phase section and rewrites the
**Morning summary** at the top:
- per phase: done / partial (which parts) / not started; where the chain stopped and why;
- the few decisions to review first (ranked);
- **one combined smoke-test order** for the morning: redeploy the plugin from `claude/siege-minigame` (web-api from
  its branch), apply new migrations to the dev DB (the developer does this), then Phase 5's remaining steps, then each
  new phase's checklist in plan order.

Each phase section: commits per repo; test results vs baseline; flagged decisions (review-first ones marked);
discrepancies; a short live checklist pointing at the plan's full one; risks.

## 8. Handoff prompt template

```
Read docs/ai-agents/handoffs/SIEGE_OVERNIGHT_CHAIN.md first and follow it; it overrides anything below.

Implement siege Phase <N> — <title> from docs/specs/siege-minigame/IMPLEMENTATION_PLAN.md, end to end (code,
tests, commits, push, docs, morning report, handoff), as link <k> of the overnight chain.

State you start from: <branch heads per repo, test baselines, what the previous phase left>.
What the previous phases say Phase <N> must wire: <list, with class/method names>.
Phase-specific reading: <files/sections>.
Open flags that affect this phase: <list>.
Known risks: <list>.
Next in the chain after you: Phase <M> (or: you are the last link; stop after the write-up).
```

## 9. Facts at chain start (2026-09-26)

- **Branch heads:** knk-plugin `claude/siege-minigame` `1a8704c`; knk-web-api `claude/siege-minigame` `a25b8f8`;
  knk-web-app `claude/siege-minigame` `9a6f347`; workspace `main` (this commit).
- **Plugin test baselines at `1a8704c`:** knk-core 694, knk-api-client 38 (2 env-gated skipped), knk-paper 259 (14
  skipped). **Web-api on the siege branch:** 633 tests with 5 known pre-existing failures that `master` has too (see
  the Kits rows in `ACTIVE_SESSIONS.md`); compare failures by name.
- **Phase 5 is code-complete and partly live-verified** (playtest round 1: steps 1–6, 8, 9, 11–13, 15 passed; 4, 7,
  10, 14, 16 open). The match API is `LoggingSiegeMatchesCommandApi` (Phase 6 swaps it); call sites are in
  `SiegeService` (see the Phase 5 status block, "What Phase 6 must wire").
- **Capture tuning (developer decision):** dev DB `SiegeConfiguration` A1 10, A2 2, IV A2 10, D 6/3/6 (DESIGN §7.2).
  Seeded defaults still 5/2/5 — Phase 9 aligns the web-api seed/model defaults; leave
  `KnkSiegeConfiguration.legacyDefaults()` (a legacy reference for tests) alone.
- **Title-bracket overlap:** siege added `TitleBracketsQueryApi` (`KnkTitleBracket`, `getAll()`,
  `GET /TitleBrackets`); `claude/menu-content` adds classes with the same names (`TitleBracket`, `listAll()`,
  `GET /title-brackets`). Don't resolve it on the siege branch unless trunk already contains menu-content's version
  when you merge trunk; then adapt siege to theirs and delete siege's duplicates.
- **Phase 6:** rewards server-side and idempotent (DESIGN §7.6); write endpoints accept only the plugin's service
  client (§11.2) — reuse whatever mechanism the plugin already uses for other plugin-only writes; if none is clear,
  follow the existing admin-auth pattern and flag it.
- **Phase 7:** gate hooks go through `SiegeMatchObserver` (`matchStarted`, `objectiveCaptured`, `matchEnded`);
  `matchStarted` runs **after** the spawn teleports — add a "before start" hook if the lockdown must come first
  (DESIGN §6.5). Gate listeners find the lobby via `SiegeRuntimeLocks.lobbyHoldingGate`. Read
  `docs/specs/gate-structure-animation/PHASE_STATUS.md` and `GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md` first.
  7b is the riskiest part (per-player block views); keep the `PassThroughOnly` degrade switch working.
- **Phase 8b:** register a `SiegeMenuFeature` in `KnKPlugin`'s `menuFeatures` list (before
  `MenuDefinitionValidationRunner`); create-only seeds per the `MenuTemplateSeed` convention; follow the InventoryMenu
  plan's Phase 9 findings; views need public zero-arg getters; the `lobbyChanged` observer is the `refreshOpenMenus`
  hook; `SiegeService.offerSpawnPicker` opens `siege.spawnpoint`; keep the chat fallbacks. The developer was told 8b
  wires into the existing menu system easily. Avoid editing InventoryMenu engine classes (the menu-content session
  works there); if you must, keep it minimal and flag it.
- **Phase 9 (non-live parts only):** seed/model defaults (incl. the capture tuning), one disabled example lobby,
  docs (`docs/vision/vision.md` §7 status lines, `docs/specs/README.md`, a `docs/guides/` admin how-to "Authoring a
  siege scenario"). Playtesting and balancing are the developer's.
