# Dashboard, form wizard and realtime chain — charter

**Status:** Ready to start (2026-10-26). No link has run yet.
**Last updated:** 2026-10-26
**Issues:** UX roadmap [#24](https://github.com/PandiO/knk-workspace/issues/24), dashboard hub
[#177](https://github.com/PandiO/knk-workspace/issues/177), SignalR [#66](https://github.com/PandiO/knk-workspace/issues/66);
per link in the table below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Binding documents:**
- [2026-10-25-ux-dashboard-signalr-plan.md](2026-10-25-ux-dashboard-signalr-plan.md) — order and the developer's
  decisions (§7a, both rounds of 2026-10-26);
- [2026-10-24-dashboard-crud-hub-proposal.md](2026-10-24-dashboard-crud-hub-proposal.md) — dashboard hub design and its
  decisions 1–4;
- [specs/realtime-signalr/DESIGN.md](../../specs/realtime-signalr/DESIGN.md) (decisions §12) and
  [IMPLEMENTATION_PLAN.md](../../specs/realtime-signalr/IMPLEMENTATION_PLAN.md);
- [reports/2026-10-25-web-app-ux-reevaluation.md](../../reports/2026-10-25-web-app-ux-reevaluation.md),
  [2026-10-25-realtime-sync-inventory.md](../../reports/2026-10-25-realtime-sync-inventory.md),
  [2026-10-25-world-tasks-as-is.md](../../reports/2026-10-25-world-tasks-as-is.md) — evidence with file:line;
- the GitHub issue text **and its comments** (decisions were added as comments on 2026-10-26).
**Progress report:** [reports/2026-10-26-ux-realtime-chain.md](../../reports/2026-10-26-ux-realtime-chain.md)
**Coordinator prompt:** [2026-10-26-ux-realtime-coordinator-prompt.md](2026-10-26-ux-realtime-coordinator-prompt.md)

A **coordinator** session starts each **link** in a fresh session (fallback: a subagent), checks its result, keeps the
report, tracker and issues current, and starts the next link when its gate is open. Each link implements its issues,
tests, documents, pushes its feature branches, and reports. **Nobody in the chain merges into a trunk, deploys or
opens PRs**; the developer tests each link from its live checklist and merges. Links whose base is an unmerged branch
of another feature wait (gate column).

## 0. Links

| Link | Issues | What | Repos | Feature branch | Gate (may start when…) |
|---|---|---|---|---|---|
| 1 | #177 (link 1), #58 | Dashboard type in the URL (`/dashboard/:entityName`, last viewed type), `returnTo` on Edit/New, Submit/Cancel return to it, table refresh on return, **submit pending state** (await `onComplete`, re-entrancy guard), **entity saved before the draft is marked Completed**, **minimal success toast** on `ToastRegion` replacing the 3 s success modal | web-app, workspace | `claude/kng-60-dashboard-hub` | now |
| 2 | #185, #38, #192 | Quick wins, **one branch per issue**: route gates for Game Settings / Siege settings; button styles (`primary-dark`, `btn-tertiary`, `.btn inline-flex`, input borders); claim-code fields that show the separator themselves (one constant, dash until the testers decide) | web-app (+ API/plugin only if #192 needs it) | `claude/route-gates-185`, `claude/styling-quick-wins-38`, `claude/claim-code-field-192` | link 1 done |
| 3 | #177 (link 2), #81, #39 (CRUD-2 menu only) | "New {Type}" + ⚙ on the dashboard header and in the empty state; open form hides the explorer, breadcrumb trail (`{label,to}[]`); flat explorer with "no display configuration" marker, View disabled; nav "Forms" → "Entity setup" (+ living docs); detail page header (#81); metadata-driven Create New menu (fixes `itemType`, the double `navigate()`); User row Edit → player profile | web-app, workspace | `claude/kng-60-dashboard-hub` | link 1 done |
| 4 | #178 (S1) | SignalR foundation (DESIGN §4–§5): two hubs, envelope, `IRealtimePublisher`, `PresenceRegistry`, plugin `RealtimeClient` with reconnect + resync, `realtime.*` config (off by default), `realtime.server-id`, nginx/production docs | API, plugin, workspace | `claude/realtime-signalr` | link 1 done; **runs at the same time as link 3** (developer decision: S1 while A2 is built) |
| 5 | #64 (FormWizard part), #109, #186 | First remove the debug block/console logs in `FormWizard.tsx`; then sticky footer with Cancel, dirty flag, `useBlocker` + `beforeunload`, blur validation + error summary, Save on any step in edit mode, single-line input; drafts and workflow sessions owned by the caller (API from the JWT) + cleanup script for user-1 rows | web-app, API, workspace | `claude/form-wizard-edit-mode` | link 1 and link 3 **merged** into web-app `main` (same files) |
| 6 | #179 (S2) | User-state push (DESIGN §6.1): `UserPermissionsChanged` (also drops offline-store answers, #76), `PermissionGroupChanged`, `UserBalancesChanged`, `UserFrozenChanged`, `UserModeChanged`, `UserChanged`, hub-backed notification queue, re-syncs ×4 slower while connected | API, plugin | `claude/realtime-signalr` | link 4 done |
| 7 | #180 (WT1) | World-task hardening + tasks anchored to the draft (DESIGN §8.2, §8.7): state machine, cancel/release/heartbeat/open, task code (checked, unique, renamed, id claims only with `knk.tasks.any`), sweep (expiry 30 min, lease 3 min, sessions without draft 7 days), plugin/web hygiene, world-tasks docs corrected | API, plugin, web-app, workspace | `claude/world-task-hardening` | link 5 **merged** (#186 ownership, `FormWizard.tsx`) |
| 8 | #181 (WT2) | World tasks over SignalR (DESIGN §8.3–§8.6): "Send to Minecraft" = auto-claim, "Hand off to…" (Accept/Decline 2 min), busy check (Queue / Hand off / Replace = release / Cancel), queue delivery, presence endpoints, web `RealtimeProvider`, live task status, catalog scan push | API, plugin, web-app | `claude/realtime-signalr` | links 6 done and link 7 **merged** |
| 9 | #39 (rest), #177 follow-up | `PagedEntityTable` controlled mode (page/search/sort in the URL; keep the wizard pickers working), tab in the URL on lootbox/moderation, rows as links, `aria-sort`; dashboard "Drafts (n)" chip and "New with: {config}" | web-app | `claude/entity-lists-url-state` | link 3 **merged** (and link 5 merged if it touched the same files) |
| 10 | #182 (S3) | Config and entity push (DESIGN §6.2–§6.4): `EntityChanged` via interceptor behind one `IRealtimeEventSink` (option A, sent after commit; explicit calls for bulk paths), gates (after the match), domain access, game/siege/lootbox/teleport/navigation settings, `ReportWorlds`, startup-only siege work on (re)connect | API, plugin | `claude/realtime-signalr` | link 8 done |

**Queue after link 10** (not in this chain; the coordinator proposes the next chain to the developer): #33 feedback
primitives, #71 builders, #30 admin IA, #95 tokens + the #92 Light/Dark/System toggle, #184 erasure push, #183 web live
updates, #119, #26, #187–#191, #139. The think-aloud (#83) is run by the developer after link 3 is live.

**Not in this chain:** merging, deploying, PRs (unless the developer asks), NAS work, Linear (read-only archive).

## 1. Setup (every link, before anything else)

1. **Repos:** `PandiO/knk-workspace`, `knk-web-api`, `knk-web-app`, `knk-plugin` under `/home/user/<repo>`. A missing
   repo is attached with `add_repo` (access `push`) **only because the link's prompt asks for it** (§6), then cloned.
2. **Branches:** the link's feature branch(es) from §0 in every repo it changes, created from the repo's current
   default branch if they don't exist (`master` for knk-web-api, `main` for the others), otherwise checked out and
   pulled. A later link of the same feature **continues** the branch. Merge (never rebase) `origin/<default>` into it at
   the start and before the final push. A non-mechanical conflict is a blocker (§4).
   - **knk-workspace:** feature docs (specs status, living architecture/guides that describe the new behaviour) go on
     the workspace branch of the same name, merged by the developer together with the code. **Chain bookkeeping goes
     on workspace `main`:** the progress report, this charter, `docs/ACTIVE_SESSIONS.md`. Commit only those files on top
     of `origin/main` and push `HEAD:main`; on a conflict keep both sides' rows.
   - Never push to another branch, never force-push, never delete branches, never merge into a trunk.
3. **Push check** before changing anything: `git push --dry-run origin <branch>` in every repo the link will change
   (create the branch locally first). A failure is a blocker.
4. **Toolchains:** .NET 8 (`sudo apt-get install -y dotnet-sdk-8.0` if missing); Node 22 (npm 11 via `npx npm@11` for
   dependency changes only); plugin links need a **JDK 25** (`openjdk-25-jdk-headless`, else a Temurin 25 tarball from
   `api.adoptium.net` into `/opt/jdk-25`, passed with `-Porg.gradle.java.installations.paths=/opt/jdk-25`).
5. **Builds and tests** (keep output short):

   | Repo | Commands |
   |---|---|
   | API | `dotnet build`, `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` |
   | Web app | `npm ci`, `npm run test:ci`, `npm run build`, `npx tsc --noEmit` (2 known errors: #63) |
   | Plugin | `./gradlew build -x deployToDevServer` |

   Record the counts **before** changing anything (baseline) and compare at the end. Known reds on the API trunk: #99
   (and the nl-NL/timing reds named in ACTIVE_SESSIONS); a failure that is also red on the base is recorded, not a
   blocker. `[MySqlFact]` tests need `KNK_TEST_MYSQL`; write them where useful, say when they were skipped.

## 2. Read first (targeted)

1. `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`; `AGENTS.md`/`CLAUDE.md` of every repo you change.
2. `docs/ACTIVE_SESSIONS.md` on `origin/main`: another "In progress" row on the same files? (§4.5)
3. Your issues **with comments** (`mcp__github__issue_read`, owner `PandiO`, repo `knk-workspace`), the binding
   documents' sections for your link, and the report's earlier blocks for your feature ("Notes for later links").

## 3. Hard rules

- **Scope:** only your link's issues. Anything else you find: a comment on the closest issue, or a new issue (global
  instructions), plus a line in the report's follow-up list. Don't fix it.
- **Behaviour-neutral where the design says so:** `realtime.enabled` defaults to false; with it off, behaviour equals
  today's. UI changes are intended behaviour changes and need no switch.
- **Migrations:** additive (nullable/defaulted columns, new tables); created with `dotnet ef migrations add`. Data
  cleanups (#186) are a SQL script in `scripts/maintenance/` run by the developer after a backup, never a migration.
- **API access rules:** every new endpoint gets an explicit rule; new anonymous endpoints go on the
  `EndpointAccessRulesTests` allow-list; staff/plugin routes in `RequireServiceOrPermissionAttributeTests.ProtectedRoutes`.
- **Secrets:** none in code, settings, logs or fixtures; task codes and claim codes are not logged outside Development.
- **Tests:** unit tests for all logic; UI tests next to the existing ones; plugin tests never build a `Location` around
  an inline `mock(World.class)`.
- **Commits:** logical chunks with your environment's attribution trailer; no model names in commits, code or docs;
  push after each chunk.
- **Issues:** `status:in-progress` on your issues when you start; at the end swap it for `status:in-review` (or keep
  in-progress when a later link finishes the issue, e.g. #177 after link 1, #39 after link 3) and comment: branch heads
  per repo, tests vs baseline, the live checklist, flagged decisions. The coordinator closes issues once merged.

## 4. Blockers (stop this link; the coordinator decides)

1. A repo can't be cloned or pushed, or `add_repo` is refused.
2. A changed module doesn't build or its tests fail and you can't fix it; an untouched baseline test starts failing
   and you can't explain it.
3. A base merge has non-mechanical conflicts.
4. An expensive-to-undo decision the binding documents don't settle, with no reversible default.
5. Another "In progress" row claims files you must change and its unmerged branch conflicts with your change.
6. Plugin links: no JDK 25.

**Never a blocker:** live testing (write the checklist); details the documents leave open (take the most reversible
default and flag it `L<n>-<k>` in the report).

## 5. Per link

1. **Claim:** update the chain row in `ACTIVE_SESSIONS.md` on `main` (link, issues, repos, branch, files); issue labels.
2. **Setup** (§1), baselines.
3. **Implement** with tests, following the binding documents.
4. **Document:** the report block (§7); status lines of the plan/design you implement; living docs your change makes
   stale (on the feature branch); `docs/CHANGELOG.md` under "Unreleased — on feature branches, not merged" (feature
   branch); a smoke-test section for the developer in `docs/guides/` when the change needs a live check.
5. **Push** every changed repo; update the tracker row; issue comments and labels (§3).
6. **Finish** with a short message: heads per repo, tests vs baseline, status, flags, blockers. **Do not start
   another link.**

## 6. How links are started (coordinator)

- `create_session` with `source_url https://github.com/PandiO/knk-workspace`, `source_revision main`, the
  coordinator's own model (from `get_session`, `session_context.model`), title
  `UX/realtime chain — link <n> (<issues>)`, and the prompt from §8.
- An `add_repo` instruction is only honoured when it is in the session's **prompt** (form wizard chain, 2026-10-11).
- **Fallback:** if `create_session` fails, or the link reports that `add_repo` was refused or a dry-run push failed, the
  coordinator runs that link as a **subagent** (Agent tool, general-purpose, high effort) with the same prompt minus the
  `add_repo` sentence — a subagent shares the coordinator's repositories.
- At most **two** links at once, and only when they share no **component** repo (knk-web-api, knk-web-app, knk-plugin;
  knk-workspace bookkeeping on `main` doesn't count, its conflicts are resolved by keeping both sides). Example: link 3
  with link 4. Never two links on the same feature branch at once.

## 7. Progress report

[reports/2026-10-26-ux-realtime-chain.md](../../reports/2026-10-26-ux-realtime-chain.md): Summary table at the top
(updated in place by links and coordinator), then append-only blocks:

```
## Link <N> — <issues>: <title>
Started: create_session <id> | subagent; dates. Commits per repo (heads); tests vs baseline; flagged decisions L<N>-<k>;
deviations from the plan/design (and why); live checklist for the developer; deploy notes (settings, migrations,
scripts); follow-ups filed (issue numbers); notes for later links.
```

## 8. Link prompt (the coordinator fills in `<n>`, `<issues>`, `<repos>`)

```
The developer asked for the dashboard, form wizard and realtime implementation chain (PandiO/knk-workspace#24, #177,
#66) and for each link to attach the repositories it changes with add_repo (access push): <repos>. Attach them, clone
each into /home/user/<repo>, check out or create this link's feature branch(es) from the charter's link table, and run
`git push --dry-run origin <branch>` in every repo this link will change before changing anything. Do that first.

Then read docs/ai-agents/handoffs/UX_REALTIME_CHAIN.md in knk-workspace (branch main) and follow it; it overrides
anything below. Implement link <n> (<issues>) end to end as the charter's link table, the binding documents and the
issues (with their comments) describe: code, tests, docs, commits and pushes to the feature branch(es), the progress
report block and Summary row on knk-workspace main, the tracker row, and the issue labels and comments. Do not start
another link; finish with a short summary.
```
