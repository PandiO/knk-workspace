# Town streets from districts chain — charter

**Status:** Running (2026-11-14)
**Last updated:** 2026-11-14
**Issues:** parent [PandiO/knk-workspace#409](https://github.com/PandiO/knk-workspace/issues/409); sub-issues per
link below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** [reports/2026-11-14-town-streets-chain.md](../../reports/2026-11-14-town-streets-chain.md)
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/`, tests
`.claude/skills/knk-test-writer/` (knk-workspace `main`).

## 0. Binding documents

1. Developer decision 2026-11-13 (on #409 and the coordinator prompt): `Town.Streets` = the distinct streets of the
   town's districts, read-only; drop the separate `TownStreet` link table (today knk-web-api `Models/Town.cs`,
   `Properties/KnKDbContext.cs` ~1625, `Mapping/TownMappingProfile.cs`, `Dtos/TownDtos.cs` `TownStreetDto`,
   `Services/RelationshipService.cs` `"Town.Streets"` link/unlink).
2. The issue text of #409 (Problem, Change, Acceptance).
3. The L1 design note once the developer approves it (binds L2 and L3).
4. Global instructions "Testing: automated first" (developer decision 2026-11-14, knk-workspace `main` `aa4208b3`) and
   the knk-test-writer skill.
5. The sub-issue text **and its comments** (the orphan-row decision lands on #515).

## 1. Links

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | [#514](https://github.com/PandiO/knk-workspace/issues/514) | tier:3 | Design note (read path and query cost, removal of the link route and metadata relationship, read-only web section with a hint, form/display configuration seeds referencing `Town.Streets`, plugin readers of `town.streets`, migration with `Down` and the fate of `TownStreet` rows) and a read-only SQL check for `TownStreet` rows whose street is in none of the town's districts. | knk-workspace (component repos read only) | `claude/town-streets-409` | `next` | none (design) | now |
| L2 | [#515](https://github.com/PandiO/knk-workspace/issues/515) | tier:3 | API: derived list, migration dropping `TownStreet` with a `Down`, link route and relationship removed, seeds; web app: read-only Streets section; plugin only if a reader needs it; tests (xUnit, Playwright e2e, Jest). | knk-web-api, knk-web-app, knk-workspace (essential docs); knk-plugin only if L1 says so | `claude/town-streets-409` | `next` | none (see § 3.2) | L1 merged into `next`, the developer approved the note and recorded the orphan-row decision on #515 |
| L3 | [#516](https://github.com/PandiO/knk-workspace/issues/516) | tier:1 | Smoke tests (dashboard access smoke test § 2.2 step 2 and § 8 step 9b to `District/{district}/streets`; #409 section with manual steps only), changelog admin steps (backup, migration). | knk-workspace | `claude/town-streets-409` | `next` | none | L2 merged into `next` |

## 2. Gates

1. "L<n> merged into `next`": `git rev-list --count origin/next..origin/claude/town-streets-409` is 0 in every repo
   L<n> changed.
2. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed.
3. Developer gates: the approval of the L1 note and the per-row decision on the SQL check's result (dev and alpha
   databases), asked by the coordinator with AskUserQuestion and recorded as a comment on #515.

Order: strictly L1 → L2 → L3 (each depends on the previous one).

## 3. Chain notes

1. **Overlaps.** No "In progress" row on 2026-11-14 claims `Town`, `TownStreet` or the town detail page. The chain 3
   row lists `Services/RelationshipService.cs` (V5, merged 2026-11-12, no open work); L2 keeps to the `Town.Streets`
   entry there.
2. **No flag (tier:3).** A derived read-only list and a dropped table cannot sensibly sit behind a config flag: the
   schema change is all-or-nothing. Safety comes instead from the L1 data check and the developer's decision before
   the drop, a database backup in the admin steps, and a migration `Down` that recreates the table.
3. **Migrations:** only L2 adds one (drop `TownStreet`, with `Down`).
4. **Automated tests:** every link prompt names the knk-test-writer skill; L2 brings xUnit tests for the derived list
   and the refused link, a Playwright e2e spec for the read-only section, and runs the suites in its baseline and
   before its PR.
5. **Model for link sessions:** `claude-opus-5-5` (the coordinator's own), passed explicitly to `create_session`.
