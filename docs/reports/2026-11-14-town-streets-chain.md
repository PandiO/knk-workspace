# Town streets from districts chain — progress report

**Status:** Running (2026-11-14) · **Last updated:** 2026-11-14

**Issue:** [PandiO/knk-workspace#409](https://github.com/PandiO/knk-workspace/issues/409), links
[#514](https://github.com/PandiO/knk-workspace/issues/514) (L1),
[#515](https://github.com/PandiO/knk-workspace/issues/515) (L2),
[#516](https://github.com/PandiO/knk-workspace/issues/516) (L3).
**Charter:** [handoffs/TOWN_STREETS_CHAIN.md](../ai-agents/handoffs/TOWN_STREETS_CHAIN.md).

## 1. Waiting for the developer

1. After L1: approve the design note and decide what happens to each orphan `TownStreet` row (run the SQL check on
   the dev and alpha databases). The coordinator will ask.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started | Test rule |
|---|---|---|---|---|---|---|---|
| L1 Design note and data check | #514 | In review | knk-workspace `claude/town-streets-409` `a24dcd2b` | [#525](https://github.com/PandiO/knk-workspace/pull/525) | n/a (docs) | create_session session_01R1w2UsgcJBhVZofGWWe6wN (`source_revision` `main`) | automated first, `main` `aa4208b3` |
| L2 Implementation | #515 | Not started | — | — | — | — | — |
| L3 Smoke tests and changelog | #516 | Not started | — | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set in force.** Chosen: the `next` branch model (links base on and target `next`, the coordinator merges a
   passed link into `next` with a merge commit), because the skill § 1.3 check passed on 2026-11-14:
   `.github/workflows/ci.yml` is on knk-web-api `origin/main` and knk-web-app `origin/main`. Alternatives: (a) the
   old rules (nobody in the chain merges), only if the check had failed.
2. **Heads at the first run (2026-11-14).** `next`: knk-web-api `b9ce7f05`, knk-web-app `8918eba0`, knk-plugin
   `a760c4a4`, knk-workspace `511b494d`; knk-workspace `main` `aa4208b3`.
3. **Testing rule version.** Chosen: "Testing: automated first" with the knk-test-writer skill, as merged on
   knk-workspace `main` in `aa4208b3` (PR #512, 2026-11-14), applied from L1 on, because the developer's instruction
   of 2026-11-14 says to apply it as soon as it lands and it landed before the first link. Alternatives: (a) the
   interim rule (unit tests plus an e2e spec per changed page), now superseded.
4. **Links and tiers.** Chosen: three sub-issues as the developer's prompt splits them: L1 #514 tier:3, L2 #515
   tier:3, L3 #516 tier:1 + `documentation`, because L3 changes docs only. Alternatives: (a) L3 tier:3 like the
   parent; (b) fold L3 into L2 (essential docs ship with L2 anyway; L3 keeps the smoke-test move separate as asked).
5. **No feature flag for tier:3 work.** Chosen: no flag, with the data check, backup step and migration `Down` as the
   safety net (charter § 3.2), because a dropped table and a derived read-only property cannot be switched off by
   configuration. Alternatives: (a) keep `TownStreet` and only hide the link behind a flag, dropping the table in a
   later release (two migrations, contradicts the developer's "drop the table"); (b) a flag that switches the DTO
   between stored and derived lists (keeps the drift problem alive).
6. **Overlap check.** No "In progress" row claims `Town`, `TownStreet` or the town detail page; chain 3's V5 claim on
   `RelationshipService.cs` is merged and idle. Chosen: no blocker; L2 keeps to the `Town.Streets` entry.
   Alternatives: (a) wait for chain 3 to close its row (it has no open work on that file).
7. **Developer gate after L1.** Chosen: the coordinator asks the developer with AskUserQuestion once L1's note and
   SQL are on the branch, and records the answer on #515, because a link session's question may go unseen.
   Alternatives: (a) the L1 link asks itself.
8. **Overlap with the #511 test backfill** (row added 2026-11-14, branch `claude/test-backfill-511`): it marks
   automated steps in `docs/guides/*smoke-test*.md`, possibly `dashboard-access-smoke-test.md`, which L3 edits
   (§ 2.2 step 2, § 8 step 9b). Chosen: not a blocker; L3 keeps to those two steps and merges `origin/next` first, so
   any conflict stays mechanical. Alternatives: (a) wait for #511 to finish before L3; (b) ask #511 to make the edit.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — Design note and TownStreet data check (#514)

1. **Scope done.**
    1. knk-workspace `docs/specs/towns/DESIGN_TOWN_STREETS.md` (Proposed): read path and query cost, every current
       reader of `Town.Streets`, removal of the link as a `derived` relationship, the read-only web section with the
       hint, configurations and seeds, plugin readers, migration `DropTownStreet` with a refilling `Down`, tests per
       behaviour and suite, six open questions with defaults, docs impact.
    2. knk-workspace `scripts/maintenance/town-street-orphans-409.sql`: SELECT only; orphan rows with names, counts,
       Town configurations naming Streets.
    3. `docs/specs/README.md` index line; `docs/CHANGELOG.md` Unreleased docs-only line.
2. **Commits and heads.** knk-workspace `claude/town-streets-409` at `a24dcd2b` (2 commits, base `next` at
   `39899f4b`). Component repos read only at `next`: knk-web-api `b9ce7f05`, knk-web-app `8918eba0`, knk-plugin
   `a760c4a4`.
3. **PRs.** [knk-workspace#525](https://github.com/PandiO/knk-workspace/pull/525), base `next`. Not merged. Codex did
   not review (usage limit reached; said so on the PR).
4. **Tests, baseline → result.**
    1. knk-workspace: docs only; links in the note resolve (the charter by URL, it is on `main` only). The SQL check ran
       on MariaDB 10.11 against a hand-made schema with the EF table and column names and fixture rows; all three
       result sets as expected. Not run on MySQL 9.6 or real data.
    2. Known reds: none (no suites run, docs only).
5. **Decisions (DESIGN § 4.3).**
    1. *Where the computed list lives.* Chosen: a `[NotMapped]` read-only `Town.Streets` on the model (keeps
       `[RelatedEntityField]`, drops `[NavigationPair]`), because metadata fields, display configurations and path
       validation keep working. Alternatives: (a) compute only in `TownMappingProfile` (metadata loses `Streets`,
       stored display sections and `Town.Streets[0].Name` paths break); (b) a SQL view mapped as a keyless entity
       (more schema for a list EF can compute).
    2. *Link route afterwards.* Chosen: a `derived` relationship storage in `RelationshipCatalog` (metadata keeps the
       entry, `canLink`/`canUnlink` false) and a 400 `RelationshipNotEditable` refusal with the reason, because the
       hint then has one source and the web app needs no Town special case. Alternatives: (a) drop the navigation
       from the catalog, 404 `UnknownRelationship` (simpler API, per-type hint in the web app); (b) a new error code
       `RelationshipDerived` (more surface for the same message).
    3. *Migration `Down`.* Chosen: recreate `TownStreet` as `InitialCreate` did and refill it from
       `DistrictStreet`/`districts`, because rolled-back code then shows what the new code showed. Alternatives: (a)
       recreate empty (Streets sections empty after a rollback); (b) keep a copy table of the dropped rows (a data
       backup in the schema; the pre-migration backup covers that).
    4. *Detail query.* Chosen: a new `GetDetailAsync` with `AsNoTracking` + `AsSplitQuery` for `GET api/Towns/{id}`,
       the tracked `GetByIdAsync` without streets for update/delete, because `Towns.Update` would write every loaded
       district street back. Alternatives: (a) add `ThenInclude(Streets)` to `GetByIdAsync` (extra writes on save);
       (b) one single query (row multiplication across sub-regions, districts and streets).
    5. *Buttons on a derived section.* Chosen: hide Add…, Unlink, Create New and Delete; keep View/Edit; show the
       hint as text. Alternatives: (a) show them greyed out with the reason (the issue asks for no button); (b) hide
       only Add…/Unlink (Create New makes a street with no district, Delete removes it from every district).
    6. *Note location.* Chosen: `docs/specs/towns/DESIGN_TOWN_STREETS.md`, next to `SPEC_TOWNS.md`, because the towns
       domain folder exists and no living world-model architecture doc does. Alternatives: (a) new
       `docs/specs/town-streets/DESIGN.md` (a folder for one note); (b) a section of `web-api-architecture.md` (the
       note also covers web app, plugin and data).
    7. *Changelog.* Chosen: one Unreleased docs-only line, because the script is something the developer runs on the
       alpha. Alternatives: (a) no line until L2.
6. **Out of scope, noted.** `RelationshipCatalog.Supported` has `["Street.Town"] = (true, true)` although `Street` has
   no `Town` navigation (dead entry, harmless); not filed, L2 may drop it while editing that dictionary if the
   coordinator agrees. Stored configurations in the knk-dev-db-seed were not read (no access); the SQL check § 3 lists
   them per database.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Approve the note or answer its open questions (§ 8: orphan rows, 400 vs 404, `Down` refill, buttons, hint
       wording, list endpoint).
    2. Run `scripts/maintenance/town-street-orphans-409.sql` on the dev and alpha databases (read only, note § 6.2)
       and decide per orphan row: link the street to a district of that town, or let it go; record on #515.
    3. Optionally comment `@codex review` on #525 when the Codex limit resets.
9. **Notes for later links.**
    1. L2: the note § 7 lists each test with its file; existing tests that use Town `streets` as the link-table example
       (API `RelationshipServiceTests`, `RelationshipsControllerTests`; web app `relationshipClient.test.ts`,
       `DisplayWizard.relationships.test.tsx`) move to `District.Streets`.
    2. L2: `PlaceholderResolutionService` builds string `Include` paths; a path through `Town.Streets` needs the
       `Districts.Streets` rewrite (note § 2.8.3).
    3. L2: remove `TownStreet` from `scripts/seed/seed-tables.sh` `WORLD_TABLES`; update `web-api-architecture.md` and
       `API_CONTRACT_TOWNS.md` (note § 9).
    4. Plugin: no change needed (note § 5).
