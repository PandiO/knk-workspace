# Token efficiency chain — charter

**Status:** Running (2026-11-27): L0–L5 merged into `main` and `next`; L6–L8 next, coordinator 2 `session_01R1w2UuEXhepWcgm7ApQ7rs`
**Last updated:** 2026-11-27 (coordinator 1 hand-over at the L1–L5 phase boundary)
**Issues:** parent [PandiO/knk-workspace#987](https://github.com/PandiO/knk-workspace/issues/987); sub-issues per
link below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** `reports/<date>-token-efficiency-chain.md`, created by the coordinator at its first run.
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/` (knk-workspace).

## 0. Binding documents

1. [specs/ai-agent-workflow/TOKEN_EFFICIENCY_PLAN.md](../../specs/ai-agent-workflow/TOKEN_EFFICIENCY_PLAN.md),
   status Decided 2026-11-24. Bindings:
   1. § 2: targets.
   2. § 3: the phase per link.
   3. § 5: the developer's decisions — docs per chain, no fallback review, run as a chain, run log in the guide, and
      the hand-over at phase boundaries with a 300k ceiling.

   The plan is in `next` (PandiO/knk-workspace#1027, merge `b15366fb`).
2. [reports/2026-11-22-code-graph-mcp-trial.md](../../reports/2026-11-22-code-graph-mcp-trial.md) § 1b: the baseline
   numbers every rerun compares against.
3. The sub-issue text **and its comments** (decisions added later live there).

## 1. Links

All links are `tier:1` and change agent workflow files (`.claude/`, `docs/ai-agents/`, `AGENTS.md`, `CLAUDE.md`).
They therefore branch from knk-workspace **`main`** and open their pull request into `main`; after the merge,
`main` goes into `next` through a pull request (global instructions, "Branches" rule 11). The exception is L5's
catalogue page `docs/architecture/reusable-systems.md`: it is a feature doc and goes through `next` in its own pull
request. Flag: none for every link.

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L0 | #1019 | tier:1 | Phase 0: session token audit procedure (`docs/ai-agents/session-token-audit.md`) and one rerun on 3 recent links | knk-workspace | `claude/token-audit-1019` | `main` | none | now |
| L1 | #1020 | tier:1 | Phase 1: slim the session board; archive script flags finished rows; skills read only "In progress" | knk-workspace | `claude/token-board-1020` | `main` | none | L0 merged |
| L2 | #1021 | tier:1 | Phase 2: core global instructions + decision history, coordinator digest, shorter skill descriptions, orientation subagent trial | knk-workspace (+ component `AGENTS.md`/`CLAUDE.md` pointers if needed) | `claude/token-startup-1021` | `main` | none | L0 merged |
| L3 | #1026 | tier:1 | Phase 4: links and docs sessions stop watching finished PRs | knk-workspace | `claude/token-wakeups-1026` | `main` | none | L0 merged |
| L4 | #1024 | tier:1 | Phase 8: coordinator hand-over at phase boundaries (300k ceiling) and fewer wake-ups | knk-workspace | `claude/token-handover-1024` | `main` | none | L0 and L3 merged |
| L5 | #978 | tier:1 | Phase 6: reuse catalogue (via `next`), Reuse step in `knk-design`, coordinator check, global line, optional audit | knk-workspace | `claude/reuse-catalogue-978` | `main` (skills) and `next` (catalogue) | none | L0 merged |
| L6 | #1022 | tier:1 | Phase 3: environment setup script with dependency installs (developer approval prompt) and `scripts/link-setup.sh` | knk-workspace, cloud environment | `claude/token-setup-1022` | `main` | none | L1–L5 merged |
| L7 | #1023 | tier:1 | Phase 5: one docs session per chain, "Docs facts" in link report blocks | knk-workspace (+ component `AGENTS.md`/`CLAUDE.md`) | `claude/token-docs-1023` | `main` | none | L1–L5 merged |
| L8 | #1025 | tier:1 | Phase 9: `knk-smoke-run` skill, coordinator redirects, run log format | knk-workspace | `claude/smoke-run-1025` | `main` (skills) and `next` (guide format) | none | L1–L5 merged |

## 2. Gates

1. "L<n> merged": `git rev-list --count origin/<base>..origin/<branch>` is 0 for the link's branch, for every base
   it targets.
2. "L<n> done":
   1. L<n>'s block is in the progress report, with its Phase 0 numbers where the phase has a target.
   2. Its heads match `git ls-remote`.
   3. `main` was merged into `next` after it.
3. L6 needs the developer to approve the environment change in its approval prompt.
4. L5's optional audit and L7's rule change are reported in the daily digest for the developer's review.

Order and parallelism:
1. L0 first.
2. Then L1, L2, L3 and L5 in parallel, and L4 once L3 is merged. They all touch knk-workspace, so keep the edits
   mechanical: L1 touches the board, the archive script and the board-reading lines of the skills; L2 the global
   instructions and skill descriptions; L3 the PR-watching steps; L5 the design template and skill. Where two links
   change the same skill file, the second merges `main` in first (merge, never rebase).
3. Then L6, L7 and L8, one at a time, since each changes several skills.

## 3. Chain notes

1. This chain changes the coordinator and link skills that run it. A link's change applies to the next session
   started after its merge into `main`, never to a running one. After L4 merges, the coordinator itself hands over
   at the next phase boundary under the new rules.
2. Each link reruns the Phase 0 procedure only if its phase has a target in plan § 2. L0's own rerun is the
   baseline check.
3. Migrations: none.
4. Model for link sessions: `claude-opus-5-5`, passed explicitly to `create_session`.
