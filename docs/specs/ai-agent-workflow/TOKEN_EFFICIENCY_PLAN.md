# Agent token efficiency and reuse: plan

**Status:** Proposed — waiting for the developer's approval · **Last updated:** 2026-11-22
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
| Merges into `next` with a code review | at least 4 recent sessions without one (Codex usage limit) | every merge |

The −20 % is an estimate: Phases 1–4 add up to roughly that. If Phase 0's reruns show less, revise the target, not the
measurement.

## 3. Phases

Each phase is one `tier:1` sub-issue of #987. Phases 1–5 and 7 change agent workflow files, so each goes to
knk-workspace `main` through its own pull request, then `main` → `next` (global instructions, "Branches" rule 11).
Order is by measured gain per effort. Phases 1, 2, 4 and 6 don't depend on each other and can run in parallel.

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
2. One docs session per chain, or per week, takes every open `documentation` issue of that chain. That changes
   "Shipping a change", item 3 at merge ("start a new session right away"), so it needs the developer's decision.
   The deploy gate (player and admin guides before a tester run) stays as it is.

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

### Phase 7: A review for every merge into `next`

Facts: at least 4 recent session summaries say Codex was skipped for its usage limit or did not review.

1. When Codex is at its usage limit, the merging session runs the `code-review` skill (low effort) on the pull
   request's diff in a subagent, and handles its findings like Codex findings.
2. The report block and digest list which review ran.

This adds tokens: about one subagent per skipped review. It is the one phase that trades tokens for accuracy; drop it
if the developer prefers the current rule.

## 4. Reopening the code knowledge graph (#977)

Reopen #977 if a Phase 0 rerun shows any of these:

- code reading above 25 % of the re-read tokens;
- a link's report or a review that shows a wrong or missed cross-language link (web app ↔ API ↔ plugin) that a graph
  would have found;
- the reuse catalogue failing because agents can't find reuse candidates in the code.

The trial is ready to resume: candidates vetted, tools chosen (codebase-memory-mcp and codegraph), and the baseline,
ground truth and recipe are in the report.

## 5. Open questions for the developer

1. Approve the plan and the order (Phase 0 first; then 1, 2, 4 and 6 in parallel; then 3, 5 and 7)?
2. Phase 5 changes the "start a docs session right away" rule. Batch per chain, per week, or keep it as it is?
3. Phase 7 spends tokens on a fallback review. Yes or no?
4. Who runs it: one session per phase, or one small chain under a coordinator?
