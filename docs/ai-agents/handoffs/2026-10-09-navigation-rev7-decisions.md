# Handoff: road navigation after the live test — Linear updates, rev. 7 decisions, C6

**Status:** Ready, 2026-10-09. Prompt for a Claude Code session **on the developer's machine** (knk-workspace with the
component repos under `Repository/`, dev DB, dev server), **with Linear access**.
**Linear:** [KNG-27](https://linear.app/kngpandi/issue/KNG-27), [KNG-51](https://linear.app/kngpandi/issue/KNG-51);
related KNG-73, KNG-74, KNG-75, KNG-76.
**Last updated:** 2026-10-09

---

Read `AGENTS.md`, `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` and `docs/ACTIVE_SESSIONS.md` first. The relevant row is
"Navigation live test (KNG-27 / KNG-51) — local debug session". Update it when you start, taking it over, and when you
pause.

Then read:
1. `docs/specs/navigation/REV7_PROPOSAL.md`, the whole of it. It is the subject of the decisions.
2. `docs/guides/road-navigation-smoke-test.md`, the header and "Phase 4 / KNG-51 live test (2026-10-07)" (runs 1-9,
   findings N1-N14).
3. `docs/specs/navigation/DESIGN.md` §6.7 (the last paragraphs: live tags, start/goal sides, N10-N14).

## State (2026-10-09, 14:30)

**Road navigation (KNG-27) and walkable paths (KNG-51) are merged and live-tested.**

| Repo | Default branch | Standing branch | Notes |
|---|---|---|---|
| knk-plugin | `main` `fd869aa` | `claude/navigation-walkable-path` `10b9a16` | Trunk has everything. Since then it also has KNG-74 (`a608aa7`, merge `fd869aa`, another session). The standing branch is 4 merge commits behind; merge `origin/main` into it before new work. |
| knk-web-api | `master` `4c570fa` | `claude/road-navigation` `fa234f7` | No navigation changes since the 2026-10-08 merge. |
| knk-web-app | `main` `b51eba0` | `claude/road-navigation` `48120ed` | Same. |
| knk-workspace | `main` `7fc079e` (or later) | `claude/road-curated-tiles-nsrorb` | Docs. The rev. 7 proposal is on `main`. |

**Merges:**
- 2026-10-08: plugin `f9026cb`, API `4c570fa`, web app `b51eba0`.
- 2026-10-09: follow-ups N10-N14, plugin `0baccce`.

**Deployed on the dev server:** plugin `9391780` plus the diagnostics removal (`10b9a16`), if the developer
redeployed. The API runs from `Repository/knk-web-api` (VS debugger, `bin/Debug`).

**Live test:** everything passed except **C6 (siege)**, which the developer will run later:
- a locked gate counts as passable for non-members;
- joining a lobby ends navigation;
- `/navigate` is refused in a lobby.

Record the C6 result in the smoke-test guide when it comes in.

**Another session:** a separate cloud session works on **KNG-73** (default destination per domain type, with per-domain
overrides) on `claude/kng-73-road-navigation-n92vlm` in all three component repos. Its tracker row lists its files
(API `DomainNavigationDefault` / `NavigationSettingsController`, plugin `NavTarget` / `NavigationDestinations`, web-app
`DomainNavigationDefaultsCard`). Rev. 7 Part C (§4) proposes one more per-type column next to KNG-73's settings. Check
its status and branches before touching those files, and coordinate through the tracker.

## Task 1 — Linear (do first)

Linear was disconnected in the previous session, so these updates are pending. Post them, adjusting the wording if
the issue state has moved on:
- **KNG-27:** comment:

  > Merged to trunk 2026-10-08 (plugin `f9026cb`, API `4c570fa`, web app `b51eba0`); live-test follow-ups N10-N14
  > merged 2026-10-09 (plugin `0baccce`). Smoke-test guide: runs 1-9, findings N1-N14. Only the siege check C6 is
  > open. Follow-ups: KNG-73, KNG-74 (done), KNG-75, KNG-76; rev. 7 proposal `docs/specs/navigation/REV7_PROPOSAL.md`.

  Keep it In Progress until C6 passes, unless the developer says otherwise.
- **KNG-51:** comment:

  > Merged with KNG-27. Partial paths, wall cost, detour allowance, "No conventional path", and the road fallback for
  > unreachable nearby targets are all live-tested.

  Move it to Done if the developer agrees.
- **Create** an issue for the rev. 7 proposal: title "Road navigation rev. 7: routing view cut at gates and access
  borders, entrances, which access rules apply to roads", team KngPandi, label Feature. Summarise the three parts and
  link the proposal file. Make it related to KNG-27, KNG-73, KNG-75 and KNG-36. If Parts A, B and C should be separate
  issues, ask the developer.
- **Check KNG-74** (done by another session) and **KNG-73** (in progress elsewhere). Don't change them; just know their
  state.

## Task 2 — rev. 7 decisions with the developer

Ask D1-D5 from `REV7_PROPOSAL.md` §7, briefly, with the recommendations:
- **D1:** Part A (the routing view) and then removing the per-part patches. Recommended.
- **D2:** entrances on structures only, or on all domains. Recommended: structures only.
- **D3:** Part C defaults per type. Open point: does a plain Structure (keep, tower) count for roads?
- **D4:** Part C's setting next to KNG-73's per-type settings. Recommended. Agree this with the KNG-73 session, or the
  developer, before that work merges.
- **D5:** region border sampling every 2 blocks, or refine to 1 block near a border.

Record the answers in `REV7_PROPOSAL.md` (the status line, plus a decisions block in §7) and in the Linear issue.
Then plan the work as the proposal's §5 orders it (Part C, then A, then B), or as the developer decides.

## Task 3 — implementation (only after the decisions)

Work on the standing branches; merge `origin/main` / `origin/master` into them first.
- **Part A** is knk-core plus `LiveEdgeTags` (knk-paper `roads/`). There is no API or web-app change.
- **Part C** touches the API and the web app (one more column in KNG-73's settings) and `DomainAvailability`.
- **Part B** needs a migration (`EntranceLocationId`). Get a go-ahead each time.

Keep one commit per fix, each with tests. Check every new test fails without its fix: the previous session found a bug
(N10's per-id cache) that a fake in the test had hidden.

## Rules (from the developer and earlier sessions)

**Builds:**
- Plugin: `./gradlew build --offline -x deployToDevServer`. A plain `build` deploys to the dev server. Deploy on purpose
  with `./gradlew :knk-paper:dev`.
- Test summary: count the XML results under `*/build/test-results/test/`. `-q` hides test output.
- web-api: build and test with `--artifacts-path <scratch>`, since the debugger holds `bin/Debug`. Known failures:
  8 on master (time-dependent currency/activity tests, FormWizard path tests) plus
  `RoadNetworkServiceTests.Validation_GeometryFarFromItsNode`.
- web-app: a dev server (`npm start`) runs from `Repository/knk-web-app`; switching branches there hot-reloads it.
  Known failing suites: 5 on main plus `RoadsAdminPage › deletes a profile after confirmation`.

**Data:**
- The dev DB is read-only unless the developer approves a write. Back up first. Migrations need a go-ahead each
  time. Never run the road reset script.

**Process:**
- Before deleting a worktree, delete its `node_modules` junction first, and check nothing runs from it.
- Live tests: the server log (`MinecraftServer/Servers/DEV_SERVER_1.21.10/logs/latest.log`, older ones `.log.gz`) shows
  commands and restarts. Check the deployed jar's time against the restart before concluding a fix failed (run 6: most
  tests ran on the old jar). For a hard case, temporary INFO diagnostics (`1fae2af`, reverted in `10b9a16`) were what
  found the cause.
- Keep messages to the developer short; they test between other work.
