# Siege Survival implementation chain — charter

**Status:** Ready to start (2026-11-03). No link has run yet.
**Last updated:** 2026-11-03
**Issues:** [PandiO/knk-workspace#41](https://github.com/PandiO/knk-workspace/issues/41) (KNG-50, Siege Survival), [#146](https://github.com/PandiO/knk-workspace/issues/146) (NPC behavior). Reference issues as `PandiO/knk-workspace#n` in component repos.
**Binding documents:**
- [specs/siege-survival/DESIGN.md](../../specs/siege-survival/DESIGN.md) (design complete for v1, decisions S01–S68);
- [specs/siege-survival/IMPLEMENTATION_PLAN.md](../../specs/siege-survival/IMPLEMENTATION_PLAN.md), **§2a links and merge gates**;
- [reports/2026-11-03-siege-survival-implementation-checks.md](../../reports/2026-11-03-siege-survival-implementation-checks.md) (file:line evidence, risks, live tests);
- [specs/gate-structure-animation/DECISIONS.md](../../specs/gate-structure-animation/DECISIONS.md) Decision 6 (animated rebuild, link G1);
- [specs/npc-platform/DESIGN.md](../../specs/npc-platform/DESIGN.md) §5b (attack rate and speed, link S2).
**Progress report:** `docs/reports/2026-11-03-siege-survival-chain.md` (the coordinator creates it at its first run and keeps it current).

A **coordinator** session runs the links of IMPLEMENTATION_PLAN §2a in order. It starts each link in a fresh session (fallback: a subagent), checks the result, keeps the progress report, the tracker and the issues current, and starts the next link when its gate is open. Each link implements its scope, tests, documents, pushes its feature branch and reports. **Nobody in the chain merges into a trunk, deploys or opens PRs** unless the developer asks in their own words; the developer tests each link from its live checklist (if any) and merges.

## 0. Repository and clone permission (explicit developer authorization)

The developer (Pandi) explicitly authorizes the coordinator **and every session or subagent it creates** to attach and clone these repositories, without asking again:

| Repository | Access | Use |
|---|---|---|
| `PandiO/knk-workspace` | push | docs, tracker, progress report |
| `PandiO/knk-web-api` | push | API |
| `PandiO/knk-web-app` | push | web app |
| `PandiO/knk-plugin` | push | plugin |
| `PandiO/knk-dev-db-seed` | read | seed values, checks |
| `PandiO/knk-v1-archive`, `PandiO/knk-v2-archive` | read | legacy reference only |

Attach a missing repository with `add_repo` (owner `PandiO`, the access above), clone it to `/home/user/<repo>` and register it with `register_repo_root`. Every prompt the coordinator writes for a sub-session **must repeat this section verbatim**, so the authorization carries to that session and to the sessions it creates. If an attach still needs an in-session approval, use the subagent fallback in the coordinator's own session and record it in the report.

## 1. Links and gates

The link table, scopes and gates are in IMPLEMENTATION_PLAN §2a (S1, S2, G1, S3–S9). Before starting a link, the coordinator checks its gate against the actual trunks (`git rev-list --count <default>..origin/<branch>` must be 0 for each branch the gate names), not against the tracker. Closed gate: start the next link whose gate is open; if none, stop and list the merges that would open a gate in "Waiting for the developer".

Order: **S1 and S2 first** (no gate, no live test). G1, S3 and S4 as soon as their gates open. S5 only after S1–S4 are on `claude/siege-survival`. S6–S8 are batched for one live checklist where possible. S9 waits for the web building blocks or a developer waiver.

## 2. Setup (every link, before anything else)

1. **Repos:** see §0. Default branches: `master` for knk-web-api, `main` for the others.
2. **Branches:** `claude/siege-survival` in each repo the link changes (G1: `claude/gate-animated-rebuild`). Create from the current default branch if missing, otherwise check out, pull, and **merge** (never rebase) `origin/<default>` at the start and before the final push. Never start from another feature's unmerged branch. A non-mechanical conflict is a blocker.
   - **knk-workspace:** feature docs (spec status, guides, smoke tests) go on the workspace branch of the same name. **Chain bookkeeping goes on workspace `main`:** the progress report, this charter, `docs/ACTIVE_SESSIONS.md`. Commit only those files on top of `origin/main` and push `HEAD:main`; on a tracker conflict keep both sides' rows.
   - Never push to another feature's branch, never force-push, never delete branches, never merge into a trunk.
3. **Push check** before changing anything: `git push --dry-run origin <branch>` in every repo the link changes. A failure is a blocker.
4. **Toolchains:** .NET 8 (`sudo apt-get install -y dotnet-sdk-8.0` if missing); Node 22 (`npx npm@11` for dependency changes only); plugin links need **JDK 25** (`openjdk-25-jdk-headless`, else a Temurin 25 tarball from `api.adoptium.net` into `/opt/jdk-25`, passed with `-Porg.gradle.java.installations.paths=/opt/jdk-25`) and Gradle on JDK 21.
5. **Builds and tests** — record the baseline before changing anything and compare at the end:

   | Repo | Commands |
   |---|---|
   | API | `dotnet build`, `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` |
   | Web app | `npm ci`, `npm run test:ci`, `CI=true npm run build`, `npx tsc --noEmit` |
   | Plugin | `./gradlew build -x deployToDevServer` |

   Known reds on the API trunk: #99 (4 tests) and the nl-NL/timing reds named in ACTIVE_SESSIONS; a failure that is also red on the base is recorded, not a blocker.

## 3. Read first (targeted)

1. `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`; `AGENTS.md`/`CLAUDE.md` of every repo you change.
2. `docs/ACTIVE_SESSIONS.md` on `origin/main`: another "In progress" row on the same files? Then stop and flag it.
3. The binding documents' sections for your link; the implementation checks report sections it names; the progress report's earlier link blocks ("Notes for later links").

## 4. Hard rules

- **Scope:** only your link. Anything else you find: a comment on #41/#146 or a new issue, plus a line in the report's follow-up list. Don't fix it.
- **Design is binding.** Decisions S01–S68 are confirmed; values marked proposed stay configurable defaults. A real conflict between design and code is a blocker with a short proposal, not a silent change.
- **Core links (S1, S2)** add new files under `knk-core/.../core/survival/` and `core/npc/` only, Bukkit-free, with unit tests; they change no existing Siege, gate, realtime or statistics file.
- **Behaviour-neutral for existing modes:** ordinary PvP Siege, world gates and other features behave as before unless the design says otherwise (G1 changes every gate rebuild by design; S3 keeps PvP capture identical with weight 1).
- **Migrations** only in S4 and later, and only after the gates in §2a are open; one migration per link at most, additive.
- **Plugin tests:** never build a `Location` around an inline `mock(World.class)` (see knk-plugin CLAUDE.md).
- Commit messages and docs never name the AI model.

## 5. Blockers

Stop the link, push what is green on the feature branch, write the blocker in the report (what, evidence, proposal) and in the tracker row, and tell the coordinator. The coordinator then starts another open link or stops.

## 6. Report back (each link)

Append a block to the progress report: scope done, commits per repo, tests (baseline → result), deviations with reasons, flags for the developer (`S1-1`, `S1-2`, …), live checklist location (integration links), notes for later links. Update the tracker row and add a short comment on #41 (with the GitHub footer). Keep "Waiting for the developer" at the top of the report current: links in review, the checklist to run, and the merges that open the next gate.
