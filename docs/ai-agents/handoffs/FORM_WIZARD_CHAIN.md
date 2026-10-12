# Form wizard chain — charter

**Status:** Running. Links 1-2 done (coordinator subagents); link 3 on as coordinator-started sessions (§6).
**Last updated:** 2026-10-12 (§6: from link 3, links are sessions started by the coordinator with `add_repo` in the prompt)
**Linear:** [KNG-133](https://linear.app/kngpandi/issue/KNG-133), [KNG-134](https://linear.app/kngpandi/issue/KNG-134),
[KNG-135](https://linear.app/kngpandi/issue/KNG-135), [KNG-164](https://linear.app/kngpandi/issue/KNG-164), [KNG-137](https://linear.app/kngpandi/issue/KNG-137),
[KNG-136](https://linear.app/kngpandi/issue/KNG-136), [KNG-162](https://linear.app/kngpandi/issue/KNG-162),
[KNG-138](https://linear.app/kngpandi/issue/KNG-138), [KNG-139](https://linear.app/kngpandi/issue/KNG-139)

A chain of **seven** Claude Code sessions ("links"). Each link picks up **one Linear issue** (link 3 two small ones),
implements it, tests it, documents it, pushes it and writes the handoff for the next link; the coordinator then starts
the next link in a **fresh context** (§6). Developer's instruction (2026-10-11): "form a chain of sessions, each session picks up a Linear
issue, completes, documents and pushes and hands off to a new session." Don't wait for the developer to test: write
the live checklist and go on. Do nothing the developer can't easily review or undo.

| Link | Issue(s) | What | Repo(s) |
|---|---|---|---|
| 1 | KNG-133 (bug, High) | Save a List "Create New" child when its form completes; `normalizeFormSubmission` fails loudly instead of dropping id-less objects | knk-web-app |
| 2 | KNG-134 (bug, High) | Edit instance seeds the child form from the values the parent holds (world-task Location, in-session edits, id-less list items, keep ids on Replace via Minecraft) | knk-web-app |
| 3 | KNG-135 + KNG-137 + KNG-164 | List relationships load in edit mode (`XIds`/`Xs`, `StreetDto.DistrictIds` on read); wizard shows step names, keeps them in edit mode, renders Boolean descriptions; required List fields reject an empty list and `minSelection`/`canCreate` get real columns (added by the coordinator 2026-10-12, found by link 1) | knk-web-app, knk-web-api |
| 4 | KNG-136 | Form session registry; pickers pin entities created in this form session ("New") | knk-web-app |
| 5 | KNG-162 | Cancel / delete-draft prompt: keep or delete what child forms saved; provenance `CreatedEntitiesJson` | knk-web-app, knk-web-api |
| 6 | KNG-138 | FormConfiguration export/import (portable JSON), bundled seeds endpoints, web-app buttons | knk-web-api, knk-web-app |
| 7 | KNG-139 + final write-up | Seed files for GateStructure/GateDoor and the siege set (then the domain family if time allows); chain summary, merge order, live checklist | knk-web-api (`Data/FormConfigurationSeeds/`), knk-workspace |

**Not in this chain:** merging into any trunk, opening PRs (the developer hasn't asked for them), deploying, touching
the developer's servers or databases, Linear issues other than the ones above (comments only on related ones).

- **Design (binding):** [FORM_WIZARD_SESSION_CONCEPTS.md](../../specs/form-configurations/FORM_WIZARD_SESSION_CONCEPTS.md)
  (links 1-5) and [DEFAULT_FORM_SEEDS.md](../../specs/form-configurations/DEFAULT_FORM_SEEDS.md) (links 3, 6, 7).
  Developer decisions 2026-10-11: **D1 = A** (child forms save their entity as soon as they complete), **S1 = A**
  (export/import + seed files imported on request, no startup seeder). D2 (abandonment, KNG-162) is a reversible
  default the developer may still override.
- **Linear issue text** is the acceptance list for each link.
- **Progress report (append per link):** `docs/reports/2026-10-11-form-wizard-chain.md`.
- **Handoff prompts:** this folder, `docs/ai-agents/handoffs/2026-10-11-form-wizard-link-<n>.md`.

## 0. Rules for changing the plan

A link may move a leftover item to the next link (record it in the table above and in the report). The chain stays
at **≤ 7 links** (session nesting is limited to 8 levels, the coordinator is level 0). The last link may only leave
items over as a written follow-up list (and Linear comments).

## 1. Setup (every link, before anything else)

1. **Repos.** `github.com/PandiO/knk-workspace`, `knk-web-app`, `knk-web-api`, `knk-plugin`. They may be checked out
   already (`/home/user/<repo>`); if missing, add with `add_repo` (access `push`) and clone. knk-plugin is read-only
   for this chain unless a link finds it must change (record why).
2. **Branch — ONE feature branch `claude/jolly-archimedes-urhio9` in every repo you change, including
   knk-workspace**, even if your environment suggests another name. It exists in all four repos. Check it out and
   pull. Trunks: knk-web-app `main`, knk-web-api `master`, knk-plugin `main`, knk-workspace `main`.
   - **At the start and again before the final push:** `git fetch` and merge `origin/<trunk>` into the feature branch
     in every repo you change. A conflict that isn't mechanical is an absolute blocker (§4).
   - **Do not merge other feature branches.** Two unmerged branches change `FormWizard.tsx` too: KNG-120
     (`claude/admiring-mendel-ne39j1`, adds `utils/forms/sharedFieldSync.ts`) and KNG-132
     (`claude/loving-johnson-dlshrc`, gate geometry step validation). If they reach trunk while the chain runs, the
     trunk merge brings them in. To keep conflicts small, put new logic in **new modules** (`src/utils/forms/…`,
     `src/hooks/…`, `src/contexts/…`) and keep edits inside `FormWizard.tsx` to thin call sites.
   - **Only `docs/ACTIVE_SESSIONS.md` is updated on workspace `main`** (the board must be on the default branch):
     `git fetch`, commit the tracker change alone on top of `origin/main` (e.g. in a separate worktree or by
     checking out `origin/main` detached), push `HEAD:main`; on conflict keep both sides' rows. Everything else —
     specs, handoffs, report — goes on the feature branch.
   - Never push to another branch, never merge into a trunk, never force-push or rewrite pushed history, never delete
     branches.
3. **Push check** before changing anything: `git push --dry-run origin claude/jolly-archimedes-urhio9` per repo you'll
   change. Failure = absolute blocker.
4. **Toolchains** (present in the coordinator's environment on 2026-10-11): Node 22 (`/opt/node22`), .NET 8.0.131,
   Java 21. If .NET is missing: `sudo apt-get install -y dotnet-sdk-8.0`. Web app: `npm ci` (the lock file needs
   npm 11 for *changes*: `npx npm@11 …`; don't change dependencies unless the issue needs it).
5. **Builds/tests.** App: `npm run test:ci`, `npm run build`. API: `dotnet build` and
   `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`. Plugin (only if changed):
   `./gradlew build -x deployToDevServer`. **Record test counts before changing anything** (baseline) and compare at
   the end. Known red on trunk at 2026-10-11: web app 5 failed / 654 passed, API 4 failed / 2550 passed (verify; a
   failure also red on trunk is recorded, not a blocker). Keep build output short (tail/grep) — it costs context.

## 2. Read first (targeted — don't re-explore the codebase)

1. `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`, and `AGENTS.md`/`CLAUDE.md` of each repo you change.
2. `docs/ACTIVE_SESSIONS.md` on `origin/main`: does another "In progress" row claim files you must change? (§4.5)
3. The design doc for your link (all of it), your Linear issue, your handoff file.
4. The progress report so far.

## 3. Hard rules

- **Scope:** only your link's issue(s). Found something else? Record it in the report's follow-up list (and a Linear
  comment on the closest issue); don't fix it.
- **No silent data loss:** any path that can't send a value must say so to the admin (KNG-133's rule applies to all
  later links).
- **Migrations** (links 5, 6 if needed): additive only (new nullable/defaulted columns or tables), never drop or rewrite
  data. Run `dotnet ef migrations add` so the model snapshot stays consistent.
- **API access rules:** every new write endpoint needs an explicit access rule (`knk.admin.content` for form
  configuration endpoints, `knk.admin.world` for world-model entities); `EndpointAccessRulesTests` must stay green.
- **Tests:** unit tests for all pure logic; UI tests next to the existing `FormWizard.*.ui.test.tsx` files. Never
  build a plugin `Location` around an inline `mock(World.class)` (knk-plugin `CLAUDE.md`).
- **Files:** write sources with your file tools. **Commits** in logical chunks with the attribution trailer from your
  environment (no model names in commit messages or code), **push after each chunk**.

## 4. Absolute blockers (stop the chain)

Stop, write why in the progress report and the tracker row, push, start no further link when:

1. You can't clone or push a repo your link must change.
2. A module you changed doesn't build or its tests fail and you can't fix it; or a baseline test you didn't touch starts
   failing and you can't explain it (a failure also red on trunk is recorded, not a blocker).
3. A trunk merge into the feature branch has non-mechanical conflicts.
4. The link needs an expensive-to-undo decision the design doesn't settle and no reversible default exists.
5. Another "In progress" row claims files you must change **and** its branch has unmerged changes to them that you
   can't build around (new modules first; stop only if impossible). KNG-120 and KNG-132 are known and handled by §1.2.
6. The previous link's report block says its exit criteria aren't met.

**Never a blocker:** live testing (write the checklist), details the design leaves open (take the most reversible
default consistent with the design, flag it as `L<k>-<n>` in the report).

## 5. Per link

1. **Claim:** add/update the chain's "In progress" row in `ACTIVE_SESSIONS.md` on `main` (link number, issue, repos,
   files); push. Linear: set your issue(s) to *In Progress*.
2. Setup (§1): fetch, merge trunk, record baselines.
3. Implement the issue as its Linear text and the design doc describe; tests.
4. **Document:** append a "Link N" block to the progress report (§7); update the design doc's §5 status line for your
   issue; update `docs/architecture/web-app-architecture.md` (or `web-api-architecture.md`) if you changed how the
   form engine works; add your entry to `docs/CHANGELOG.md` under "Unreleased — on feature branches, not merged".
5. Merge trunk once more, push every changed repo's feature branch, update the tracker row, push.
6. Linear: comment on your issue (commits per repo, tests, live checklist, flagged decisions) and set it to
   *In Review*.
7. Hand over (§6).

### Link specifics

- **Link 1 (KNG-133):** under D1-A, `handleOpenChildForm` marks a non-owned List "Create New" as persist-on-complete
  (Location stays embedded). `normalizeFormSubmission` returns/throws a clear error for an id-less object in a
  non-embedded relationship (Object or List) and the wizard shows it instead of submitting. Confirm the many-to-many
  path already saves. Check how the Street's Districts minimum is validated so a dropped item can't pass it.
- **Link 2 (KNG-134):** spec §3.4. Also verify the inherited `worldTaskHint` "first field" binding (spec §2.3) and fix
  it if confirmed.
- **Link 3 (KNG-135 + KNG-137 + KNG-164):** spec §3.5 and seeds spec §2.3; KNG-164's Linear text (additive `FormField` columns, step validation for required/min List). API: list every DTO whose `*Ids` is not filled on read
  and fix those used by List fields; record the list in the report.
- **Link 4 (KNG-136):** spec §3.2-3.3. New `src/contexts/FormSessionContext.tsx` (+ hook). `PagedEntityTable` gets its
  first tests.
- **Link 5 (KNG-162):** spec §4 D2. The "in use" check for delete should use the API (FK/reference errors become a
  "skipped: in use" result, not a 500). The prompt uses the existing FeedbackModal/useConfirm pattern.
- **Link 6 (KNG-138):** seeds spec §3. Add `configurationGuid` to the export format (the DTO lacks it). Round-trip
  tests on an in-memory/test DB using a config shaped like `siege-minigame/PHASE_3_FORMCONFIGS.md`.
- **Link 7 (KNG-139 + write-up):** seeds spec §4-5. Seed files for GateStructure + GateDoor (derive from
  `GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md` §5.10-5.11 and the models; no dev-DB export is available — say so in the
  report) and the siege set (convert `PHASE_3_FORMCONFIGS.md`); each must pass the link-6 dry-run in a test. Domain
  family if time allows, otherwise a follow-up list. Then the **final summary** in the report: what was built per
  issue, decisions to review (ranked), combined live checklist, merge order (API → web app; migrations first; note
  KNG-120/KNG-132 interplay), and move the tracker row to "Recently completed" (nothing merged).

## 6. Handoff — fresh context for every link

**How links are started (changed twice on 2026-10-12).** A session's repositories are fixed when it starts, and
`create_session` attaches only **one** repository (`source_url`). Link 1's first attempt was started that way with
knk-workspace only; its handoff *file* told it to `add_repo` the others, and the permission check refused that
(`[Permission Grant]`), so the git proxy answered 403. Links 1 and 2 then ran as subagents of the coordinator.
A test the same day showed that a new session **can** attach the other repos with push when the instruction is in
its **prompt** (the developer's request relayed by the coordinator), not in a file. So from link 3 on:

- The **coordinator** session (`session_01SZ9c7pGMwGfvHR3dHAmWgQ`, environment "Default Correct") starts each link
  with `create_session`: `source_url` knk-workspace, `source_revision` `claude/jolly-archimedes-urhio9`, model
  `claude-opus-5-5`, title "Form wizard chain — link <n> (KNG-…)". The **prompt itself** says: the developer asked
  for this chain and for each link to attach `PandiO/knk-web-app`, `PandiO/knk-web-api` and `PandiO/knk-plugin` with
  `add_repo` (access `push`), clone them into `/home/user/<repo>`, and `git push --dry-run` the feature branch
  before changing anything; then read and execute the handoff file.
- If `add_repo` is refused or a dry-run push fails, the link stops at once (charter §4.1) and writes that in the
  progress report; the coordinator then runs that link as a subagent instead (Agent tool, Opus, high effort), which
  shares the coordinator's repos.
- A link **does not start the next link** (an agent-written `add_repo` request is more likely to be refused). It
  ends after steps 1-2 below. The coordinator notices completion through its own check-ins (`send_later`) and
  `get_session`, reads the progress report, and starts the next link.
- `create_session` has no effort setting: session links run at the environment's default effort. Subagent links run
  at high effort.

1. Write the next link's prompt to `docs/ai-agents/handoffs/2026-10-11-form-wizard-link-<n+1>.md` using §8: branch
   heads, test counts, what you left for the next link, open flags, risks. Commit and push (feature branch).
2. End with a short summary as your final message (heads per repo, test counts, status, blockers). The coordinator
   starts **at most one** next link, never one the report
   marks done or in progress, and stops after link 7 or at a blocker. Record in the progress report how each link
   was started.

## 7. Progress report

`docs/reports/2026-10-11-form-wizard-chain.md` (append-only; the Summary block at the top is the one part each link
updates in place).

```
## Link <N> — <issue>: <title>
Commits per repo (heads); tests vs baseline; flagged decisions L<N>-<n>; discrepancies with the design; live
checklist; risks; what the next link must know; how the next link was started.
```

## 8. Handoff prompt template

```
Read docs/ai-agents/handoffs/FORM_WIZARD_CHAIN.md first (branch claude/jolly-archimedes-urhio9) and follow it;
it overrides anything below.

Implement link <k> — <issue>: <title> end to end (code, tests, docs, commits, push to claude/jolly-archimedes-urhio9,
progress report, Linear, handoff) as link <k> of the chain.

State you start from: <branch heads per repo, test baselines/counts, what earlier links left>.
What earlier links left for this link: <modules, helpers, call sites>.
Link-specific reading: <spec sections, files>.
Open flags that affect this link: <list>.
Known risks: <list>.
Next after you: link <k+1> (or: last link — stop after the write-up).
```
