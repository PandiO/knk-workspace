# Player statistics chain — progress report

**Status:** running
**Last updated:** 2026-10-03 (link 1 done)
**Charter:** `docs/ai-agents/handoffs/PLAYER_STATISTICS_CHAIN.md` · **Linear:** [KNG-34](https://linear.app/kngpandi/issue/KNG-34)

## Summary for the developer

Branch in all four repos: `claude/kind-dijkstra-y9d279` (nothing merged to any trunk).

| Link | Phase | State | Heads | Details |
|---|---|---|---|---|
| 1 | Design completion + implementation plan | **done** | knk-workspace (see Link 1 block) | [audit](2026-10-03-player-statistics-source-audit.md), [DESIGN §F](../specs/player-statistics/DESIGN.md), [plan](../specs/player-statistics/IMPLEMENTATION_PLAN.md) |
| 2 | API foundation (+ Siege projection, moved from link 4) | pending | — | — |
| 3 | Plugin foundation | pending | — | — |
| 4 | Combat and minigames | pending | — | — |
| 5 | Read surfaces + leaderboards | pending | — | — |
| 6 | Diagnostic telemetry + privacy | pending | — | — |
| 7 | World analytics + final write-up | pending | — | — |

**Review first:** (ranked; each link appends)
1. **L1-18 GDPR scope** — deletion pseudonymizes the `users` row and auto-executes 3 days before the 30-day due date
   (DESIGN §F.14). Irreversible for the player once executed; ledger and Siege rows are kept.
2. **L1-1 AFK rule** — `/afk` + auto-AFK after 300 s, retroactive idle window, anti-pool signals, tab marker, no Siege
   removal (§F.2). **L1-2:** salary still pays AFK players (needs an API contract change if you want otherwise).
3. **L1-3 "everyone" visibility** — anonymous web visitors see only always-public fields (§F.4).
4. **L1-5/L1-6 economy buckets** — `/pay` transfers, admin adjustments, signup grant, merges and premium top-ups are
   neither earned nor spent; `xp_gained` uses earned XP only (§F.5).
5. **L1-17 owner nodes** — `knk.owner.*` require an exact grant (wildcards never unlock owner data); grant them to
   yourself with `POST api/users/{id}/grants` (§F.13).

**Test when you have time:** (filled in by link 7 — build/deploy steps and the combined live checklist.)

## Chain start — coordinator session (2026-10-03)

- The developer answered the open questions (DESIGN.md "Developer decisions 2026-10-03", D1-D13), handed KNG-34 over
  to Claude Code, asked for the whole feature on one feature branch with a chain of fresh sessions, one phase each,
  and said not to wait for their testing.
- Created `claude/kind-dijkstra-y9d279` from trunk in knk-plugin (`main` `27b4236`), knk-web-api (`master`
  `ae0b3ad`) and knk-web-app (`main` `fc66101`); in knk-workspace from `main` with the earlier draft branch
  `codex/kng-34-player-statistics-design` (`4f5618a`, draft [PandiO/knk-workspace#4](https://github.com/PandiO/knk-workspace/pull/4)) merged
  in, so the draft design continues on this branch. PR #4 was left open and untouched (the developer may close it).
- Recorded D1-D13 and the adopted leaderboard recommendation in DESIGN.md; wrote the charter and link 1's handoff.
- AFK: not answered by the developer; link 1 analyses V1 and takes a reversible default (charter, DESIGN.md).
- Overlap noted: a Codex session ("Sequential backlog fixes", tracker row on `main` 2026-10-03) is changing knk-plugin
  Siege combat, item lore and command completion and knk-web-app form-wizard code, pushing to trunk. Links merge trunk
  at start and end; link 4 builds its combat hooks around their changes.
- Link 1 started as a **new session** (`create_session`, option 1): `session_015g7iripYBsgLJUPKZivR5s`, source
  knk-workspace `claude/kind-dijkstra-y9d279`, tag `kng-34-player-statistics-chain`.

## Link 1 — Design completion + implementation plan (2026-10-03)

Session `session_015g7iripYBsgLJUPKZivR5s` (started by the coordinator via `create_session`). Docs only.

- **Commits (knk-workspace `claude/kind-dijkstra-y9d279`):** `4eb179b` source audit + finalized DESIGN §F, `b76ee7e`
  implementation plan + feature register + specs hub + charter re-cut, plus this report/handoff commit. Tracker on
  `main`: `6a08f18` (link 1 in progress) and the link-1-done update. Code repos untouched (read-only at knk-web-api
  `ae0b3ad`, knk-plugin `db474e4`, knk-web-app `fc66101`; legacy `knk-v1-archive` `4117e7e`, `knk-v2-archive` `400e5c8`).
- **Tests vs baseline:** n/a (no builds in link 1). Static counts for reference: API 1,299 test attributes; plugin
  `@Test` knk-core 880 / knk-api-client 141 / knk-paper 1030.
- **Delivered:** [source audit](2026-10-03-player-statistics-source-audit.md); DESIGN.md §F (catalogue, AFK, sessions,
  visibility, economy buckets, match rules, combat/gate/distance attribution, periods/rounding, leaderboards, event
  contract, owner nodes, GDPR, retention); [IMPLEMENTATION_PLAN.md](../specs/player-statistics/IMPLEMENTATION_PLAN.md);
  feature register rows (statistics, telemetry, XP provenance) and specs hub; Linear: KNG-34 set to *In Progress*,
  comments on KNG-34, KNG-14 and KNG-23 (reconciliation).
- **Flagged decisions:** L1-1 … L1-23, table in DESIGN §F.16 (top five in "Review first").
- **Re-cut (charter §0):** Siege match projection moved from link 4 to link 2 (API-only, pure logic; link 4 keeps the
  plugin leaver fix and reconciliation tests). Still 7 links; every charter item is placed.
- **Discrepancies with the design / snapshot:** plugin trunk moved to `db474e4` (KNG-28); Siege leavers' stats are lost
  today (plugin drops them — fixed in link 4); per-match killstreak already exists (D2 extended to open world);
  `HealthSystem` returns void (link 4 changes it to return the effective loss); `*`/`knk.*` grants match `knk.owner.*`
  (→ exact-grant attribute); `Telemetry` config section is taken by OpenTelemetry (→ `DiagnosticTelemetry`); permission
  check and several user GETs are anonymous on trunk (not changed by this chain); V1 stored users in MySQL, not flat files;
  no first-join field (derived per L1-15).
- **Live checklist:** none for link 1.
- **Risks:** see plan §9 (Siege/gate files under concurrent change, create-only menu seed, MySQL-only upserts).
- **What link 2 must wire:** plan §1.1, §2, §3.1, §4 (link-2 rows), §6 (`RequireOwnerPermission`), §8 Link 2 acceptance
  criteria 1-10.
- **How link 2 was started:** see the next line (appended after the attempt).

