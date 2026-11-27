# Agent token efficiency and reuse: plan

**Status:** **Decided 2026-11-24** (developer) · **Last updated:** 2026-11-24 (approved, including the Phase 8 hand-over recommendation; phase sub-issues filed) · 2026-11-24 (§ 5 decisions: docs per chain, Phase 7 dropped, run by a chain, run log in the guide; Phase 8 hand-over recommendation) · 2026-11-24 (Phases 8 and 9: coordinator hand-over and wake-ups, smoke-run session) · 2026-11-22
**Issue:** PandiO/knk-workspace#987 (parent) · **Evidence:** [code-graph trial report](../../reports/2026-11-22-code-graph-mcp-trial.md)
§ 1 (baseline) and § 1b (12 real sessions) · **Related:** PandiO/knk-workspace#977 (code-graph trial, shelved),
PandiO/knk-workspace#978 (reuse catalogue)

## 1. Why

On 2026-11-22 we measured 12 finished cloud sessions from 19–21 November. For the 9 implementation links (medians):

- **Cost:** $17.85 per session, over 193 turns.
- **Context:** 87k tokens at the start, 494k at the end; about 57M cached tokens re-read per session.
- **Reading:** 36k tokens of instructions and plans, 73k of code.
- **First edit:** at turn 50, after 74k tokens of reading.

Every turn re-sends the whole context, so a token read early is paid again on every later turn. The start context
accounts for ~30 % of the re-read tokens, code reading for ~19 % and instructions and plans for ~10 % (estimates,
report § 1b).

**Decision (developer, 2026-11-22):** shelve the code knowledge graph (#977). It could save at most ~10 % per session
(by halving code reading), and plain grep answered all five baseline navigation questions correctly. The levers below
are larger and need no new tooling. Section 4 says when to reopen it.

## 2. Targets

Medians over the next implementation links after each phase, measured with the same recipe (Phase 0). Baseline in brackets.

| Metric | Baseline | Target |
|---|---|---|
| Instructions and plans read per link | 36k | ≤ 15k |
| First edit at turn | 50 | ≤ 25 |
| Turns after the work is done (check-ins, notifications) per link | not measured per link; 2 turns (11 % of cost) in docs P9, 5 in L21 | ≤ 1 |
| Session board size | 20.7k tokens | ≤ 4k |
| Re-read (cached) tokens per implementation link | 57M | −20 % |
| New specs with a "Reuse" section (#978) | 0 % | 100 % |
| Coordinator context at its largest | 883k (Production), 776k (NPC #358) | ≤ 300k (Phase 8) |
| Coordinator cost per chain | $119 (Production), $203 (NPC #358) | −50 % (Phase 8) |
| Smoke results, design and new ideas handled in a coordinator | 17 of the NPC coordinator's 29 developer turns | 0: redirected (Phase 9) |

The −20 % is an estimate: Phases 1–4 add up to roughly that. If Phase 0's reruns show less, revise the target, not the
measurement.

## 3. Phases

| Phase | Sub-issue | Tier | What | Order |
|---|---|---|---|---|
| 0 | PandiO/knk-workspace#1019 | tier:1 | Session token audit procedure | first |
| 1 | PandiO/knk-workspace#1020 | tier:1 | Slim the session board | after 0, parallel |
| 2 | PandiO/knk-workspace#1021 | tier:1 | Lighter start-up reading | after 0, parallel |
| 4 | PandiO/knk-workspace#1026 | tier:1 | Stop waking finished sessions | after 0, parallel |
| 6 | PandiO/knk-workspace#978 | tier:1 | Reuse catalogue and Reuse design step | after 0, parallel |
| 8 | PandiO/knk-workspace#1024 | tier:1 | Coordinator hand-over and fewer wake-ups | after 0, parallel (PR watching after 4) |
| 3 | PandiO/knk-workspace#1022 | tier:1 | Fewer set-up turns | after the parallel group |
| 5 | PandiO/knk-workspace#1023 | tier:1 | One docs session per chain | after the parallel group |
| 9 | PandiO/knk-workspace#1025 | tier:1 | Smoke-run session and redirects | after the parallel group |
| 7 | — | — | Fallback review | dropped 2026-11-24 |

No smoke-test guide: every phase is `tier:1` and changes agent workflow, not game behaviour. Each phase is checked by
a Phase 0 rerun against the targets in § 2.

Each phase is one `tier:1` sub-issue of #987. Phases 1–5, 8 and 9 change agent workflow files (Phase 7 is dropped), so each goes to
knk-workspace `main` through its own pull request, then `main` → `next` (global instructions, "Branches" rule 11).
Order is by measured gain per effort. Phases 1, 2, 4, 6 and 8 don't depend on each other and can run in parallel.

### Phase 0: Measurement procedure (do first, small)

- Move the layer-3 extraction recipe (the bucket definitions in report § 1b) into `docs/ai-agents/session-token-audit.md`
  with the fields and buckets as used on 2026-11-22.
- Rerun it on about 6 recent implementation links after each phase, and add the numbers to report § 1b, or to a new
  dated report once the trial report is closed.
- Cost: about 60k tokens per session read (about 735k for the 12 on 2026-11-22).
- Also record whether edits went through Edit or through Bash heredocs, with output tokens per edit. Most edits in
  the measured links were Bash rewrites (35 of 41 in L29); that is observed but its cost is not measured yet.

### Phase 1: Slim the session board (quick win)

Facts: `ACTIVE_SESSIONS.md` on `main` is 20.7k tokens; 31 of its 37 "In progress" rows already say merged, done or
closed; the link skill requires reading it fresh at the start of every link.

1. Move finished rows to `docs/reports/sessions-archive/2026-11.md` (and `2026-10.md` / `2026-09.md`), as the rules
   already intend. Extend `scripts/sessions-archive/archive_sessions.py` to flag "In progress" rows whose issue is
   closed or whose text says merged/done.
2. Cap each row at one line: issue, branch, repos, status. Details go in the linked report.
3. Give the link and coordinator skills a command that prints only the "In progress" table, not the whole file.
4. Let the manager run (step 6, "archives finished board rows") apply item 1 daily.

Target: board ≤ 4k tokens. Estimated saving: ~6 % of a link's re-read tokens.

### Phase 2: Lighter start-up reading

Facts, the mandated list for a link (tokens): global instructions 7.6k, board 20.7k (Phase 1), repo
`AGENTS.md`/`CLAUDE.md` 3–4k, link skill 3.1k, charter 2.1k, earlier link blocks of the progress report (10.5k in L24;
the Production chain report is 75k).

1. **Global instructions:** split them into a core file (rules an agent acts on, aim for ~3k tokens) and a dated
   `docs/ai-agents/decision-history.md` (who decided what when, "History, before the rule existed…" passages). Every
   rule keeps one line pointing at its decision.
2. **Notes for the next link:** the coordinator writes a ≤ 2k "Notes for later links" digest into the charter (or the
   link prompt) when it checks a finished link. Links read that digest, not the progress report.
3. **Skill descriptions** (~2k tokens, loaded in every session): shorten each to the trigger phrases. The bodies stay.
4. **Orientation subagent (try, then keep or drop):** a link starts a subagent that reads the list and returns a
   digest of ≤ 3k (rules that apply to this link, open decisions, files claimed). The reading then never enters the
   link's context. Run it on two links and keep it only if Phase 0 shows a saving and the links' report blocks are no
   worse.

Target: ≤ 15k read. Estimated saving: ~5–7 %.

### Phase 3: Fewer set-up turns

Facts: the first edit comes at turn 50 (42–60). The environment's setup script installs MySQL, .NET 8, JDK 25 and
dotnet-ef, but no `npm ci`, `dotnet restore` or Gradle dependencies; each link does those and its baseline tests as
separate turns.

1. **Environment setup script:** add dependency installs for every repo, run and checked in a session first
   (`npm ci` with npm 11 in knk-web-app, `dotnet restore` in knk-web-api, `./gradlew dependencies` or a `help` warm-up
   in knk-plugin).
2. **One link set-up script** (`scripts/link-setup.sh`): attach check, branch from `next` (merge, not rebase), push dry
   run and baseline tests per repo, printing one summary. The link skill's set-up becomes "run it, read the summary".

Target: first edit ≤ turn 25. Estimated saving: ~5 % (fewer turns at a growing context).

### Phase 4: Stop waking finished sessions

Facts: in docs session P9, two short turns after the work was done (a Codex check-in, a merge notification) cost
$0.69 of $6.43, re-reading 2.5M tokens. L21 had five such check-in turns.

1. A link unsubscribes from its pull requests once it has handed over to the coordinator. The coordinator watches
   them and does the merge check; it holds less context.
2. Docs and one-off sessions that merge their own pull request unsubscribe right after the merge and cancel their
   `send_later` check-ins in the same turn.

Target: ≤ 1 turn after the work is done.

### Phase 5: Batch the docs sessions

Facts: each docs session costs about $6 (2 measured: $5.82, $6.43), starts at the same 85k context and re-reads
23–42k tokens of code the implementing link already read. About 29 `documentation` issues are open. Docs sessions do
catch drift between code and plan (P9 filed #930), so they stay.

1. The link's report block gets a "Docs facts" list: behaviour, settings, endpoints and limits as built, with file
   references. The docs session starts from that list, not from the code.
2. **One docs session per chain** (developer decision 2026-11-24) takes every open `documentation` issue of that
   chain. It starts when the chain's last phase is merged into `next`, or earlier when a deploy gate needs a player or
   admin guide. This changes "Shipping a change", item 3 at merge ("start a new session right away"), in the global
   instructions, `AGENTS.md`/`CLAUDE.md`, `docs-session-prompt.md` and the `knk-docs-session` skill. The deploy gate
   (player and admin guides before a tester run) stays as it is. Why it saves: one start context (~85k) and one read of
   the chain's charter, report and guides per chain instead of per phase, with a warm cache across the phases' docs
   inside that one session. A cache does not carry over from the implementing link: it lives inside one session for
   at most an hour.

Target: fewer docs sessions per merged phase, ≤ 15k code read per docs session.

### Phase 6: Reuse of the form and world-task systems (#978)

Facts: no instruction or design-skill step points at FormWizard, FormConfiguration, DisplayConfiguration or world
tasks; their specs are 117 files, about 65k words; the roads plan opted out explicitly with no rule to test it
against; a heuristic flags 19 of 63 admin pages/components added since October.

Scope as in #978: the one-page reuse catalogue `docs/architecture/reusable-systems.md`, a required "Reuse" section in
the design template and skill, the coordinator check, one line in the global instructions, and the audit of the 19
components.

The catalogue also cuts reading: a ~2k page replaces searching 65k words of specs. Target: every new spec has a Reuse
section, and opt-outs appear in its decision log.

### Phase 7: A review for every merge into `next` — dropped

Facts: at least 4 recent session summaries say Codex was skipped for its usage limit or did not review.

1. When Codex is at its usage limit, the merging session runs the `code-review` skill (low effort) on the pull
   request's diff in a subagent, and handles its findings like Codex findings.
2. The report block and digest list which review ran.

This adds tokens: about one subagent per skipped review. **Dropped by the developer on 2026-11-24:** the current
rule stays (continue without Codex at its usage limit and say so on the pull request). Kept here as the record.

### Phase 8: Coordinators hand over to a fresh session and wake up less

Added 2026-11-24 after measuring two coordinators (same method as § 1, from their result events):

| | Production chain coordinator | NPC follow-ups coordinator (#358) |
|---|---|---|
| Cost | $119 | $203 |
| Turns | 822 | 929 |
| Context at its largest | 883k | 776k |
| Turns the developer started / automatic wake-ups | 4 / 69 | 29 / 118 |
| Cost of automatic wake-ups (notifications, check-ins) | $109 (91 %) | $147 (72 %) |

Each wake-up re-reads the whole context. After an idle hour the cache expires, and the next wake-up paid $4.50–6 only
to rebuild it. The NPC coordinator alone cost more than the 12 sessions in § 1 together ($177).

1. **Hand-over** (recommended 2026-11-24, see § 5): at every phase boundary, with 300k context as a hard ceiling.
   Above 300k the coordinator hands over at its next quiet moment (no link mid-merge). A wake-up after more than an
   hour idle with more than ~200k context is the cheapest moment, since the cache has expired and is rebuilt anyway.
   The coordinator brings the charter's links table and
   the progress report up to date, starts a fresh coordinator with the knk-coordinator start note, and ends itself.
   The new session reads the charter, the report's last link block and the open sub-issues. The board row and the
   parent issue name the new session.
2. **Wake-ups:**
   1. One `send_later` check-in per active link, timed under an hour apart while links run, so the cache doesn't
      expire. No check-ins while nothing runs.
   2. Batch notifications: a check-in handles every queued notification in one turn.
   3. PR watching follows Phase 4: the coordinator watches, links don't.
3. **Coordinator skill:** add both rules to `knk-coordinator` § 3 (the loop) and § 7, and say how the progress report
   carries over in the hand-over.

Target: context ≤ 300k, cost per chain −50 % (estimate: wake-ups at ~250k instead of 600–880k context).

### Phase 9: A smoke-run session, and redirects out of the coordinator

Facts: no skill covers the developer's own smoke runs. `knk-coordinator` only lists smoke steps in its reports, and
`docs/guides/closed-alpha-test-runs.md` only says to record developer pre-checks in the next run's checklist. So
results, fixes, ideas and design end up in the coordinator: in the NPC coordinator, 8 of the developer's 29 turns were
smoke results, 7 design and 2 new ideas, and smoke failures also arrived through its notifications.

1. **New skill `knk-smoke-run`**, one short session per test sitting, started from the daily digest's "ready to
   test" list or by the developer. It:
   1. presents the steps from `docs/guides/<feature>-smoke-test.md` (skipping the `[automated: …]` steps unless asked);
   2. records each step's result (works, fails or skipped) with the date and the tested commits in a "Run log"
      section of the feature's smoke-test guide (developer decision 2026-11-24). A run on the alpha before a tester
      run is still also listed in that run's checklist under "Developer pre-checks", as `closed-alpha-test-runs.md`
      asks;
   3. fixes a really small failure on the branch under test (global "GitHub Issues" rule 2) and adds its test;
   4. files every larger failure as a `bug` with steps to reproduce, as a sub-issue of the feature, for the
      coordinator to schedule;
   5. sends ideas to `knk-intake` capture mode (the developer's words, no questions), and labels follow-ups that need
      design "design first" without designing them;
   6. ends with one summary comment on the feature issue: results per step, issues filed, what the coordinator picks up.
2. **Redirects in `knk-coordinator`:**
   1. An idea the developer drops is captured by a small subagent with the intake skill, so it stays out of the
      coordinator's context; the coordinator confirms in one sentence.
   2. Test results and design requests get a one-line answer with a ready starter prompt for a smoke-run or design
      session (the developer chooses; the coordinator doesn't refuse).
   3. Failures filed by a smoke run are scheduled like other sub-issues.
3. **Design always in a design session**, even for small follow-ups. It starts at ~87k context instead of a
   coordinator's 600k+, and brings the spec, decision log and sub-issues with it.
4. **Global instructions:** one line naming the session types: intake, design, coordinator, link, smoke-run, docs and
   manager, and what goes where.

Target: no smoke results, design or new ideas handled inside a coordinator. One skill added (about 180 tokens of
description in every session).

## 4. Reopening the code knowledge graph (#977)

Reopen #977 if a Phase 0 rerun shows any of these:

- code reading above 25 % of the re-read tokens;
- a link's report or a review that shows a wrong or missed cross-language link (web app ↔ API ↔ plugin) that a graph
  would have found;
- the reuse catalogue failing because agents can't find reuse candidates in the code.

The trial is ready to resume: candidates vetted, tools chosen (codebase-memory-mcp and codegraph), and the baseline,
ground truth and recipe are in the report.

## 5. Decisions

Developer answers of 2026-11-24:

1. Phase 5: one docs session per chain (reason recorded in Phase 5: shared start context and reading, not a shared cache).
2. Phase 7: no fallback review; dropped.
3. Who runs it: a small chain under a coordinator. Charter to draft on approval.
4. Phase 9: smoke-run results go in a "Run log" section of the feature's smoke-test guide.
5. Phase 8, asked by the developer for a recommendation: hand over at every phase boundary, with 300k as a hard
   ceiling and a cold-cache wake-up above ~200k as the preferred moment. Approved by the developer 2026-11-24.

6. Approval: the developer approved the plan and the Phase 8 recommendation on 2026-11-24. Order: Phase 0 first;
   then 1, 2, 4, 6 and 8 in parallel; then 3, 5 and 9 (§ 3 table). No open questions remain.
