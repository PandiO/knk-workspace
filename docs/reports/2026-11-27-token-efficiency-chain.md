# Token efficiency chain — progress report

**Status:** Running (2026-11-27) · **Last updated:** 2026-11-27 (L0, L3 merged; L1, L2, L4, L5 running)

**Issue:** [PandiO/knk-workspace#987](https://github.com/PandiO/knk-workspace/issues/987), links
[#1019](https://github.com/PandiO/knk-workspace/issues/1019) (L0),
[#1020](https://github.com/PandiO/knk-workspace/issues/1020) (L1),
[#1021](https://github.com/PandiO/knk-workspace/issues/1021) (L2),
[#1026](https://github.com/PandiO/knk-workspace/issues/1026) (L3),
[#1024](https://github.com/PandiO/knk-workspace/issues/1024) (L4),
[#978](https://github.com/PandiO/knk-workspace/issues/978) (L5),
[#1022](https://github.com/PandiO/knk-workspace/issues/1022) (L6),
[#1023](https://github.com/PandiO/knk-workspace/issues/1023) (L7),
[#1025](https://github.com/PandiO/knk-workspace/issues/1025) (L8).
**Charter:** [handoffs/TOKEN_EFFICIENCY_CHAIN.md](../ai-agents/handoffs/TOKEN_EFFICIENCY_CHAIN.md).

## 1. Waiting for the developer

1. Nothing yet. Known gate ahead: L6 (#1022) changes the cloud environment's setup script, which needs your approval
   in the environment approval prompt.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L0 session token audit procedure | #1019 | Merged into `main` (#1037, `39525374`) and `next` (#1038 `db35f876`; sync #1040 `b2e454f8`) | `claude/token-audit-1019`: `f6dba762`; `claude/token-audit-1019-next`: `c91e7539` | [#1037](https://github.com/PandiO/knk-workspace/pull/1037) (`main`), [#1038](https://github.com/PandiO/knk-workspace/pull/1038) (`next`) | none (docs; Codex at usage limit, skipped) | create_session `session_01R1w2UuT7VcXg1qRF2cqKDV` (§ 3.3) |
| L1 slim the session board | #1020 | In review (PR open, not merged) | `claude/token-board-1020`: `e18c07cf` (base `main`) | [#1047](https://github.com/PandiO/knk-workspace/pull/1047) (`main`) | none (docs and script) | create_session `session_01R1w2Uv7GQxAnY971aP5hiH` (§ 3.6) |
| L2 lighter start-up reading | #1021 | Running | — | — | — | create_session `session_01R1w2UtvxHHSbCHYZ2ZsheW` (§ 3.6) |
| L3 stop waking finished sessions | #1026 | Merged into `main` (#1041 `8ffae44e`) and `next` (sync #1042 `0c030da3`) | `claude/token-wakeups-1026`: `43d0efd1` (2 commits on `main`) | [#1041](https://github.com/PandiO/knk-workspace/pull/1041) (`main`) | none (docs) | create_session `session_01R1w2UuD4tw3yQ2N6mwMpQ9` (§ 3.6) |
| L4 coordinator hand-over, fewer wake-ups | #1024 | Running | — | — | — | create_session `session_01R1w2UwgB6mB8qcMtKmYSwt` (§ 3.6) |
| L5 reuse catalogue | #978 | In review (PRs open, not merged) | `claude/reuse-catalogue-978`: `be067817` (3 commits + merge of `main` `405c82e4`, base `main`); `claude/reuse-catalogue-978-next`: `a3096162` (1 commit on `next` `b2e454f8`) | [#1044](https://github.com/PandiO/knk-workspace/pull/1044) (`main`), [#1045](https://github.com/PandiO/knk-workspace/pull/1045) (`next`) | none (docs) | create_session `session_01R1w2UvxEiZju9gUZgBsVjt` (§ 3.6) |
| L6 fewer set-up turns | #1022 | Not started (gate: L1–L5 merged; developer approval) | — | — | — | — |
| L7 one docs session per chain | #1023 | Not started (gate: L1–L5 merged) | — | — | — | — |
| L8 smoke-run session | #1025 | Not started (gate: L1–L5 merged) | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model applies (`next` exists and carries merged chain work, among it this
   chain's plan, PandiO/knk-workspace#1027 merge `b15366fb`), with the charter's exception that every link changes
   agent workflow files and therefore branches from knk-workspace `main`, opens its PR into `main`, and I merge it
   into `main` and then `main` into `next` through a PR (skill § 7.10). The parts on feature-doc paths (L5's
   catalogue, L8's guide format, and any edit to the `next`-only evidence report) go into `next` in their own PR.
   Alternatives: (a) old rules, the developer merges everything — rejected, the charter and skill § 7.10 put these
   merges with the coordinator; (b) everything through `next` — rejected, "Branches" rule 11 keeps workflow files on
   `main` first.
2. **Overlap at first run.** Chosen: no overlap. Board read fresh from `origin/main` (`aa404246`) on 2026-11-27: no
   "In progress" row claims knk-workspace `.claude/`, `docs/ai-agents/`, `AGENTS.md`/`CLAUDE.md`, the board or the
   archive script (two old rows name component-repo `CLAUDE.md` files, which this chain does not touch).
   Alternatives: (a) treat those two rows as claims — rejected, other repos and finished work.
3. **Route for L0.** Chosen: `create_session` with knk-workspace as `source_url`; L0 needs no other repository, so
   no `add_repo` attach is at risk (skill § 4.1.4). Alternatives: (a) subagent — kept as the fallback.
4. **Binding documents live on `next` only.** The plan and the trial report are not on `main` (checked 2026-11-27).
   Chosen: link prompts tell links to read them from `origin/next`. Alternatives: (a) merge `next` into `main` first —
   rejected, never merge into trunk outside § 7.10.

5. **L0 check and merges (2026-11-27).** Chosen: merged #1037 into `main` and #1038 into `next` without a Codex review, because Codex replied at its usage limit on both PRs and every other § 6 check held (developer decision 2026-11-14; noted on both PRs). The `main` → `next` sync #1039 (head `main`) conflicted on the changelog's "Unreleased" list, which both sides add to; I closed it and merged `origin/next` into a sync branch `claude/token-sync-main-next-1019`, keeping both entries, and merged that as #1040. Alternatives: (a) wait for Codex — no date for the limit to lift, and the change is docs only; (b) resolve on `main` itself — would push a merge of `next` into the trunk.
6. **Route for L1, L2, L3, L5.** Chosen: `create_session` for all four, knk-workspace only. L5 reads the component repos, which are public, so it clones them read-only without `add_repo` (no attach for the classifier to refuse, skill § 4.1.4). Alternatives: (a) L5 as a subagent with the repos attached here — costs this coordinator context and needs no attach anyway.
7. **Shared files between the parallel links.** Chosen: each prompt lists every link's lines (L1 board and board-reading lines, L2 global split, descriptions and digest step, L3 watching steps, L5 design skill, one § 6 item, one global line). I merge in order of finish, and a later link merges `origin/main` in when its PR conflicts. L2 keeps the name `GLOBAL_AGENT_INSTRUCTIONS.md`, so the component pointers stay valid. Alternatives: (a) run them one at a time — the charter asks for parallel; (b) give L5's global line to L2 — couples two links.
8. **Acceptance items that need a later rerun** (L2's ≤ 15k, L3's ≤ 1 turn, L2's orientation-subagent trial). Chosen: the links measure what they can now, and I run the Phase 0 reruns on links that start after the merges (L6–L8 and the next chains), at the chain's end. Alternatives: (a) hold each link open until a rerun — it would block the chain on unrelated chains.
9. **L3 check and merge (2026-11-27).** Chosen: merged #1041 into `main` without a Codex review (usage limit again, noted on the PR), all other § 6 checks held; synced through branch `claude/token-sync-main-next-1026` (#1042, no conflict). L4's gate (L0 and L3 merged) checked with `rev-list` counts 0, and L4 started. Alternatives: (a) wait for Codex — no date for the limit.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.0 L0 — Session token audit procedure (#1019)

1. **Scope done.**
    1. knk-workspace `main` branch: new `docs/ai-agents/session-token-audit.md`, the § 1b recipe as six steps (accounting fields from result events, transcript walk, reading buckets, read before the first edit, edit fields, result row). It adds Edit-tool vs Bash edits, output tokens per edit, idle vs rework wake-ups and restarts, and records the § 1b and Phase 8 reference plus a second reference from this rerun. Changelog entry under Unreleased.
    2. knk-workspace `next` branch: new dated report `docs/reports/2026-11-27-session-token-audit.md` with the rerun on landmark-domain L1 #983, L2 #984 and L4 #986 (acceptance items 1 and 2).
2. **Commits and heads.** knk-workspace `claude/token-audit-1019` at `f6dba762` (4 commits, base `main`); `claude/token-audit-1019-next` at `c91e7539` (1 commit, base `next`).
3. **PRs.** [#1037](https://github.com/PandiO/knk-workspace/pull/1037) into `main` (`Closes #1019`), [#1038](https://github.com/PandiO/knk-workspace/pull/1038) into `next` (`Part of #1019`). Not merged.
4. **Tests, baseline → result.**
    1. knk-workspace: docs only. The links resolve on `next`; the procedure's links to the plan, the trial report and the new report are `next`-only paths, so they resolve on `main` after the `main` → `next` → trunk round.
    2. Rerun medians (3 links): $15.38, 187 turns (160 requests), 88k → 388k context, 40.9M re-read, 21k instructions, 74k code, 51k read before the first edit at turn 45, edits 2 Edit tool / 29 Bash, 4.9k / 1.1k output tokens per edit, idle wake-ups after done 2. Every § 1b field was reproduced. Baseline (§ 1b): $17.85, 193 turns, 87k → 494k, 57M, 36k, 73k, 74k at turn 50.
    3. Cost of the run (acceptance item 3): 365k subagent tokens (about 122k per link, twice the plan's 60k estimate) plus about 12k in this session.
    4. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Where the numbers go.* Chosen: a new dated report on `next` in its own branch and PR (prompt § 1 item 3 option), because reports are never overwritten and the plan allows a new dated report. Alternatives: (a) append to trial report § 1b on `next` — rewrites a closed, dated report.
    2. *Sessions measured.* Chosen: landmark-domain L1, L2 and L4 (2026-11-22), the most recent finished single-session implementation links. Alternatives: (a) siege shop links — older; (b) landmark L3 — split over two sessions by a network block; (c) six links — the issue asks for 3 and cost had to stay low.
    3. *Baseline for later links.* Chosen: compare each phase with both § 1b and this rerun, because the 2026-11-22 bucket boundaries were never written down and instructions read already differ (21k vs 36k) before any phase. Alternatives: (a) § 1b only — mixes a definition change with the phase effect; (b) replace § 1b — plan § 2 says revise targets, not measurements.
    4. *Output tokens per edit.* Chosen: allocation by visible characters, thinking left out, because the transcript's per-message `output_tokens` is a streaming snapshot. Alternatives: (a) read `stream_event` pages for exact usage — several times the pages; (b) share thinking by `thinking_duration_ms` — not reliably present.
    5. *Fixes from the rerun went into the procedure before the PR* (turns vs requests, restart detection, paging, worktree edits, bucket gaps, idle vs rework). Alternatives: (a) ship the first draft and file a follow-up — later links would measure with a known-wrong step.
6. **Out of scope, noted.** Plan § 4: code reading was about 25 % of re-reads in L4 by the rough § 1b estimate (median 22 %), right at the reopen line for #977. Reported here for the coordinator; no reopen proposed on one link.
7. **Blockers.** None.
8. **At merge / what the developer must do.** Nothing beyond merging #1037 into `main` (then `main` → `next`) and #1038 into `next`.
9. **Notes for later links.**
    1. Measure with `docs/ai-agents/session-token-audit.md`, one subagent per session, in parallel. Budget about 120k tokens per implementation link for the full recipe; step 1 alone (cost, turns, context, wake-ups) is about 6–8k per session and needs no subagent.
    2. Compare against both references in the procedure's § 4. Without a phase merged, three links already spread from $8 to $23, so use at least 3 links that started after your phase merged into `main`.
    3. L3 (Phase 4) target: count only **idle** wake-ups after the hand-over. L1's 8 post-hand-over results were mostly rework (base merges, conflicts).
    4. L4 (Phase 8): restarts (`process_turn_index` 0) rebuild the cache; L4 #986 paid $2.66 for one.

### 4.1 L1 — Slim the session board (#1020)

1. **Scope done.**
    1. `docs/ACTIVE_SESSIONS.md`: 86,163 → 11,139 bytes, about 20.7k → 2.7k tokens (bytes scaled by the plan's 86 KB = 20.7k ratio). The "In progress" table as the skills now read it: 9,474 bytes, about 2.3k tokens. 10 finished rows moved verbatim to `reports/sessions-archive/2026-11.md` with `--move`; the 29 others cut to one line of at most 400 characters (dates unchanged); "How to use" shortened.
    2. `scripts/sessions-archive/archive_sessions.py`: `--flag` (rows whose linked knk-workspace issues are all closed, via `--closed` or `--gh`; status saying merged/done/closed/deployed/installed with no in review/waiting/running/paused/blocked; rows over 400 characters or multi-line; `--board -` reads stdin) and `--move <lines>` (verbatim into the current month's file, same line check). Archive README rule 6.
    3. Skills: `knk-link` § 1.2, `knk-coordinator` § 2.1, `knk-design` step 2 read only the "In progress" table: `git show origin/main:docs/ACTIVE_SESSIONS.md | awk '/^## /{p=/^## In progress/} p'`. `knk-manager` § 7.1: `--flag --gh`, then `--move`, every run.
    4. `docs/CHANGELOG.md` Unreleased entry.
2. **Commits and heads.** knk-workspace `claude/token-board-1020` at `e18c07cf` (5 commits + 2 merges of `origin/main`, base `main`).
3. **PRs.** [#1047](https://github.com/PandiO/knk-workspace/pull/1047) into `main` (`Closes #1020`). Not merged.
4. **Tests, baseline → result.**
    1. `python3 -m unittest discover -s scripts/sessions-archive`: 15 → 25 passed (10 new).
    2. `--flag --gh` on the new board: no rows flagged; `--check`: 0 waiting; report links on the board resolve.
    3. Acceptance 1 (board ≤ 4k tokens) met on the branch; holds on `main` after the merge. The plan's ~6 % re-read saving needs a Phase 0 rerun on links started after the merge: the coordinator's, at the chain's end.
    4. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Finished-row rule.* Chosen: archive a row when every issue it names as its own is closed, or its status says merged/deployed/installed/done with nothing left for the developer, or a later row or merged branch supersedes it; keep every row that is running, paused, blocked or in review (merged but waiting for the developer's test), per the coordinator's note. Archived: web app chain 1 (#177 closed, superseded by chains 2–3), chain 2 (its open #184 now closed), #231 (closed), seed update (fast-forwarded to `main`), NAS Stage B (installed), startup seeders (merged and deployed), closed-alpha NAS continuation (merged and superseded by Phase 4), closed-alpha readiness (branch merged in `d51dd659`), the example row, legacy menu mining (spec on `main`). Alternatives: (a) archive every row whose issues are closed only: almost none, since issues close at promotion; (b) also archive old "In review" rows from October: against the coordinator's note.
    2. *Archive month.* Chosen: rows moved from "In progress" go to the month they were found finished (`--today`), here 2026-11.md as the prompt says, because the finish day is unknown. Alternatives: (a) month of "Last updated" (2026-09/10 files): the plan's reading, but contradicts the prompt.
    3. *Long text of kept rows.* Chosen: cut to one line without copying the old text anywhere; the detail is in the linked issues and reports and in git history. Alternatives: (a) archive a snapshot of each long row: doubles the archive and mixes live rows into it.
    4. *Issue state source.* Chosen: `--closed N,N` and `--gh` (open issues through the search API; an issue not open counts as closed); stdlib only, no token handling. Alternatives: (a) GitHub MCP from the script: not callable from Python; (b) REST per issue: one call per row.
    5. *Text flag scope.* Chosen: the Status cell and bold spans of the Feature cell only, with "in review/waiting/..." as a veto, so coordinator rows that list merged links are not flagged. Alternatives: (a) whole row: flags nearly every chain row.
    6. *Read command.* Chosen: an `awk` one-liner on `git show origin/main:...`, needing no checkout of the script (prompt § 2a.3). Alternatives: (a) a script mode: needs a checkout at the right commit; (b) `sed -n '/^## In progress/,/^## /p'`: also prints the next heading.
    7. *Row cap.* Chosen: 400 characters (`--max-row`), enough for issue, branch, repos, owner and status. Alternatives: (a) 300: forced dropping report links on chain rows.
6. **Out of scope, noted.**
    1. `knk-docs-session` § 1 and `knk-digest` § 3 still read the whole board; with the board at 11 KB this costs little. L3's/L7's files; not changed here.
    2. Board conflicts are likely at merge, since other sessions keep editing their rows: keep `main`'s new or changed rows, shortened to one line.
7. **Blockers.** None.
8. **What the developer must do.** Nothing beyond the coordinator's merge of #1047 into `main` and `main` → `next`.
9. **Notes for later links.**
    1. The manager run now flags and moves board rows daily (`--flag --gh`, then `--move`); rows over 400 characters show up in its output.
    2. L2: `knk-link` § 1.2's board line changed (the `awk` command); merge both sides.

### 4.3 L3 — Stop waking finished sessions (#1026)

1. **Scope done.**
    1. `knk-link` § 3.4 (don't wait for a late Codex review) and new § 3.8: at the hand-over, unsubscribe from every PR (also when never subscribed), cancel `send_later` check-ins, stop; rework comes from the coordinator by `send_message`; a stray notification gets no work and no reply.
    2. `knk-coordinator` new § 3.5 (subscribe to a handed-over link's PRs; old step 5 is now 6), new § 5.4 (hand Codex findings, base merges and conflicts back with `send_message`, or `SendMessage` to a subagent), § 6.10 (points to § 5.4), new § 7.11 (unsubscribe in the merge turn). Check-in cadence untouched, left to L4.
    3. `knk-docs-session` § 3.2 item 5 (unsubscribe and cancel check-ins in the merge turn) and § 4.4 (none left before the final message; same rule for one-off sessions that merge their own PR).
    4. `docs/CHANGELOG.md` Unreleased entry.
2. **Commits and heads.** knk-workspace `claude/token-wakeups-1026` at `43d0efd1` (2 commits, base `main`).
3. **PRs.** [#1041](https://github.com/PandiO/knk-workspace/pull/1041) into `main` (`Closes #1026`). Not merged.
4. **Tests, baseline → result.**
    1. Docs only, no CI. Section references added resolve inside the files.
    2. Measured now: the three skills grow by about 300 (link), 340 (coordinator) and 200 (docs session) tokens (characters / 4).
    3. Acceptance (≤ 1 idle turn after the work is done per link and docs session) needs a Phase 0 rerun on sessions started after this merge: the coordinator's, at the chain's end.
    4. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Unsubscribe unconditionally.* Chosen: the link and docs session call `unsubscribe_pr_activity` even when they never subscribed, because the platform can subscribe a session that opens a PR and the call is idempotent. Alternatives: (a) only when subscribed — the session can't always tell.
    2. *Order of the hand-over.* Chosen: the link unsubscribes before its final message, the coordinator subscribes when it reads that message, because a PR's events reach one session at a time. Alternatives: (a) coordinator subscribes when the PR opens — its call would succeed but deliver nothing while the link holds the PR.
    3. *Late Codex reviews.* Chosen: the link handles reviews already in at its hand-over and doesn't stay on for one that hasn't come; the coordinator sends later findings back. Alternatives: (a) link waits with check-ins — exactly the idle wake-ups Phase 4 removes.
    4. *One-off sessions.* Chosen: one sentence in `knk-docs-session` § 4.4, since one-off sessions have no skill and the global instructions are L2's file in this round. Alternatives: (a) a global line — collides with L2's split; left as a note below.
    5. *Measurement.* Chosen: token growth of the changed skills now, the rerun left to the coordinator (prompt § 1.5). Alternatives: (a) none possible inside the link.
6. **Blockers.** None.
7. **What the developer must do.** Nothing beyond the coordinator's merge of #1041 into `main` and `main` → `next`.
8. **Notes for later links.**
    1. L4: the coordinator now holds the PR subscriptions of handed-over links (§ 3.5, § 5.4, § 7.11); batch those PR events with your check-ins.
    2. L2 / L7: if one-off sessions get a rule in the global instructions, add "unsubscribe and cancel `send_later` in the merge turn" there too.

### 4.5 L5 — Reuse catalogue and reuse check (#978)

1. **Scope done.**
    1. knk-workspace `next` branch: new `docs/architecture/reusable-systems.md` (about 1,040 words), one short section per system: FormWizard and FormConfiguration; DisplayConfiguration, DisplayWizard and ObjectDashboard; RelationPicker, lookups, M2M editor and child forms; validation, step conditions and reusable steps; world tasks with WorldGuard regions; plugin and web app building blocks. Each: what it is for, required when, exception when, entry points per repo, current specs. Linked from `system-overview.md` § 5.
    2. knk-workspace `main` branch: `knk-design` § 2.4 (required read step) and § 4.8 (required Reuse section, opt-out is a decision log row); DESIGN template new § 4 "Reuse" (later sections renumbered 5–13); `knk-coordinator` § 6.12 (reuse check); one pointer each in `knk-link` § 2.6, `knk-api-endpoint`, `knk-entity-scaffold`, `knk-plugin-command`; global instructions "Authority and freshness" item 6; changelog entry.
    3. Audit (optional item 5): not done in the link; follow-up [#1043](https://github.com/PandiO/knk-workspace/issues/1043) (`improvement`, `tier:1`, sub-issue of #978) with the heuristic, the sorting rules and `RoadProfilesCard.tsx` as the confirmed first case. For the digest (charter § 2.4).
2. **Commits and heads.** `claude/reuse-catalogue-978` at `be067817` (base `main`, `origin/main` `405c82e4` merged in, one CHANGELOG conflict kept both sides); `claude/reuse-catalogue-978-next` at `a3096162` (base `next` `b2e454f8`).
3. **PRs.** [#1044](https://github.com/PandiO/knk-workspace/pull/1044) into `main` (`Closes #978`), [#1045](https://github.com/PandiO/knk-workspace/pull/1045) into `next` (`Part of #978`). Not merged. The `main` files link to a page that exists only on `next` until #1045 merges and `next` is promoted.
4. **Tests, baseline → result.**
    1. knk-workspace: docs only. Every relative link on the new page resolves on `next`; the pointers on `main` resolve once the page is there.
    2. Entry points checked against `next`: knk-web-app `8be9e24`, knk-web-api `e06fd5c`, knk-plugin `2c5d584` (read-only clones, nothing changed).
    3. Measurement now: the catalogue is about 1,040 words (roughly 1.5k tokens) against about 65k words in the form, validation and world-task specs it points into. The plan § 2 target (new specs with a Reuse section: 0 % → 100 %) can only be counted on specs written after #1044 merges; that count, and any Phase 0 rerun, is the coordinator's at the chain's end.
    4. Codex: at its usage limit on both PRs; finished without its review (developer decision 2026-11-14), noted on each PR.
    5. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Reuse section place in the template.* Chosen: its own § 4 after "Current state", visible and countable for the plan § 2 target. Alternatives: (a) a sub-item of § 3: easy to skip; (b) at the end: read after the design is shaped.
    2. *Which PR closes #978.* Chosen: #1044 into `main`, because only a merge into the default branch auto-closes. Alternatives: (a) #1045 into `next`: would not close on merge.
    3. *Audit.* Chosen: follow-up #1043, to keep the link's cost moderate (prompt § 2a.3); the 19-file list needs history the read-only depth-1 clones don't have. Alternatives: (a) audit in the link with full clones and a subagent: roughly 80–120k more tokens.
    4. *Measurement.* Chosen: report the catalogue's size now and leave the Reuse-section count and rerun to the coordinator (prompt § 1.5). Alternatives: (a) count the specs now: none is written after the change yet.
    5. *Relations rule.* Chosen: the catalogue says to store relations as a foreign key or join, not a JSON id list, from #978's roads finding. Alternatives: (a) leave it out: the roads case would still pass the check.
6. **Out of scope, noted.**
    1. There is no general auto-fill in the form system: only the ItemScan cross-field fill inside `FormWizard.tsx` (`applyItemScanResult`). The catalogue says so; no issue filed, as nobody has asked for one.
    2. Several specs under `form-validation/` and `world-tasks/` read as phase reports or "Historical"; the catalogue names the current ones only. Tidying them is #1023/docs work, not this link.
7. **Blockers.** None.
8. **At merge / what the developer must do.** Nothing beyond the merges: #1044 into `main` (then `main` → `next`) and #1045 into `next`. Review #1043 in the digest. L2: keep `GLOBAL_AGENT_INSTRUCTIONS.md` "Authority and freshness" item 6 in the core file if #1044 merges first.
9. **Notes for later links.**
    1. Design sessions after the merge must fill the template's § 4 "Reuse"; the coordinator's § 6.12 checks links against `docs/architecture/reusable-systems.md`.
    2. Template sections moved by one: "Open questions" is now § 13, "Phases" § 12.
