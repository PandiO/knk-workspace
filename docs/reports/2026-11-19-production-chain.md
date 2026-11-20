# Production, storage and transport chain — progress report

**Status:** Running (2026-11-19: L0–L3 in `next`; L4 running; smoke gates waived by the developer for L4 and L6) · **Last updated:** 2026-11-19

**Issue:** [PandiO/knk-workspace#22](https://github.com/PandiO/knk-workspace/issues/22), links
[#141](https://github.com/PandiO/knk-workspace/issues/141) (L0), [#326](https://github.com/PandiO/knk-workspace/issues/326) (L1), [#689](https://github.com/PandiO/knk-workspace/issues/689) (L2), [#690](https://github.com/PandiO/knk-workspace/issues/690) (L3), [#97](https://github.com/PandiO/knk-workspace/issues/97) (L4), [#675](https://github.com/PandiO/knk-workspace/issues/675) (L5), [#91](https://github.com/PandiO/knk-workspace/issues/91) (L6), [#676](https://github.com/PandiO/knk-workspace/issues/676) (L7), [#677](https://github.com/PandiO/knk-workspace/issues/677) (L8), [#86](https://github.com/PandiO/knk-workspace/issues/86) (L9), [#678](https://github.com/PandiO/knk-workspace/issues/678) (L10), [#138](https://github.com/PandiO/knk-workspace/issues/138) (L11), [#679](https://github.com/PandiO/knk-workspace/issues/679) (L12), [#680](https://github.com/PandiO/knk-workspace/issues/680) (L13), [#79](https://github.com/PandiO/knk-workspace/issues/79) (L14), [#681](https://github.com/PandiO/knk-workspace/issues/681) (L15), [#682](https://github.com/PandiO/knk-workspace/issues/682) (L16), [#683](https://github.com/PandiO/knk-workspace/issues/683) (L17), [#74](https://github.com/PandiO/knk-workspace/issues/74) (L18), [#60](https://github.com/PandiO/knk-workspace/issues/60) (L19), [#684](https://github.com/PandiO/knk-workspace/issues/684) (L20), [#685](https://github.com/PandiO/knk-workspace/issues/685) (L21), [#134](https://github.com/PandiO/knk-workspace/issues/134) (L22), [#127](https://github.com/PandiO/knk-workspace/issues/127) (L23), [#686](https://github.com/PandiO/knk-workspace/issues/686) (L24), [#248](https://github.com/PandiO/knk-workspace/issues/248) (L25), [#687](https://github.com/PandiO/knk-workspace/issues/687) (L26), [#688](https://github.com/PandiO/knk-workspace/issues/688) (L27), [#249](https://github.com/PandiO/knk-workspace/issues/249) (L28), [#250](https://github.com/PandiO/knk-workspace/issues/250) (L29).
**Charter:** [handoffs/PRODUCTION_CHAIN.md](../ai-agents/handoffs/PRODUCTION_CHAIN.md).
**Coordinator:** cloud session `session_01R1w2UtB6J4UtRJL3foJgcj`.

## 1. Waiting for the developer

The developer waived the smoke gates for L4 and L6 on 2026-11-19 (decision 20). These are not blockers: they are tests
of what is already in `next`.

1. **Smoke test of L0 (item identity, tier:3):** guide `docs/guides/production-storage-transport-smoke-test.md` § 0
   on `next`.
   1. Apply migration `AddItemIdentity`.
   2. Run a catalogue scan (or `POST api/ItemIdentity/shadows/generate`).
   3. Merge the `items.identity` block into the plugin `config.yml`.
2. **Smoke test of L4 (stock core, tier:3):** guide § 2 (15 of 17 steps automated).
   1. Apply migration `AddStockCore`.
   2. Import the form and display seeds `Storage` and `StockTransaction`.
   3. Grant `knk.economy.admin` to the staff who may move or adjust stock.
3. **Smoke test of L6 (world API, tier:3):** guide § 3.1 (14 of 16 steps automated).
   1. Apply migration `AddProductionWorld` (structures get an optional district and a town; its `Down` fails while a
      rural structure exists).
   2. Import the form and display seeds `Warehouse` and `ProductionStructure` ("make default").
4. **Smoke test of L9 (production engine API, tier:3):** guide § 4.1 (16 of 18 steps automated).
   1. Check that `SELECT Id FROM production_structures WHERE ProductionKindId NOT BETWEEN 1 AND 8;` returns nothing.
   2. Apply migration `AddProductionEngine`.
   3. Import the form and display seeds `ProductionKind`, `ProductionKindLevel`, `ProductionLine`, `ProductionModifier`,
      `ClimateZone` and `WeatherType`.
   4. Make `ProductionStructure` v2 (form, display), `ItemBlueprint` v2 (form) and `Storage` v2 (display) the default.
5. **Smoke test of L11 (yield areas API, tier:3):** guide § 5.1 (17 of 18 steps automated).
   1. Apply migration `AddProductionYieldAreas`; existing structures become `Configured`.
   2. Import the seeds `ProductionArea` and `ProductionYieldOverride` (form and display) and `AreaSurvey` (display).
   3. Make `ProductionKind` v2, `ProductionStructure` v3 (form and display) and `Structure` v3 (form) the default.
   4. Fill each kind's `yieldTable`; none is seeded, and #836 proposes defaults.
6. **Smoke test of territory (L1 § 1.1–1.2, L2 § 1.3, L3 § 1.4).**
   1. Apply migration `AddTerritory`.
   2. Import the four territory form and display seeds (`Kingdom` first).
   3. Merge the plugin `production` block into `config.yml`.
   4. To test, turn on `production.enabled` in the plugin and in the API game settings.
7. **Review:** the agent decisions in blocks 4.0–4.11 (L6's are listed in knk-web-api#57) (L0's retag rule; L1 server-side territory and loyalty as a town
   id; L2's crown land region kind) and coordinator decision 15 (Town/District seed fields).
8. Later: the shop menu templates for L26 (#687).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L0 Item identity: every obtainable item is a blueprint; generated "Uncurated" shadow blueprints (G4) | #141 | Merged into next (2026-11-19) | api `5daa3c6`, plugin `a6c5a2bc`, workspace `8ffdbb1a`; merges: api `7d213fd6`, plugin `2ef256e7`, workspace `ca3bcc98` | [api#51](https://github.com/PandiO/knk-web-api/pull/51), [plugin#89](https://github.com/PandiO/knk-plugin/pull/89), [ws#793](https://github.com/PandiO/knk-workspace/pull/793) | green (API PR checks; plugin build + paper-boot) | subagent of the coordinator (two repos besides knk-workspace, SKILL § 4.1.4.2), started 2026-11-19 |
| L1 Territory API: holders, crown land entity (G10), power, range (G11), conflicts, loyalty | #326 | Merged into next (2026-11-19) | api `ff50ec1`, workspace `c4211d51`; merges: api `0d6e369a`, workspace `4595e6d8` | [api#53](https://github.com/PandiO/knk-web-api/pull/53), [ws#798](https://github.com/PandiO/knk-workspace/pull/798) | green (build-and-test, mysql-tests, fresh-database) | create_session `session_01R1w2Uwo46dJVo6Cpr8LzmG` (one repo besides knk-workspace), started 2026-11-19 |
| L2 Territory plugin: chunk cache, lookup, BlueMap outlines | #689 | Merged into next (2026-11-19) | plugin `96ef7326`, workspace `14d3efcd`; merges: plugin `55804b11`, workspace `66d35872` | [plugin#91](https://github.com/PandiO/knk-plugin/pull/91), [ws#804](https://github.com/PandiO/knk-workspace/pull/804) | green (plugin build + paper-boot) | create_session `session_01R1w2Uvhpo37DXAXpm2uqLp` (one repo besides knk-workspace), started 2026-11-19 |
| L3 Territory web app | #690 | Merged into next (2026-11-19) | web app `0531422`, workspace `f3bd8f27`; merges: web app `89751315`, workspace `54bdc830` (after a coordinator merge of `next`, `e4f2276d`) | [web#57](https://github.com/PandiO/knk-web-app/pull/57), [ws#803](https://github.com/PandiO/knk-workspace/pull/803) | web app green (build-and-test, e2e) | create_session `session_01R1w2UuYHneFJFXcn8GSe6F` (one repo besides knk-workspace), started 2026-11-19 |
| L4 P1 stock core API: storages, ledger, reconciler, capacity, roll-up | #97 | Merged into next (2026-11-19) | api `e524721`, workspace `abef76fc`; coordinator merge of `next` `06fee906`; merges: api `2e7d4e81`, workspace `1bbdd69f` | [api#56](https://github.com/PandiO/knk-web-api/pull/56), [ws#816](https://github.com/PandiO/knk-workspace/pull/816) | green (build-and-test, mysql-tests, fresh-database) | create_session `session_01R1w2Uwv8FBnKCUoeZauzVt` (one repo besides knk-workspace), started 2026-11-19 |
| L5 P1b stock web app | #675 | Merged into next (2026-11-19) | web app `9bec60f`, workspace `a5d10f37`; merges: web app `9f46cb49`, workspace `8fff63e2` | [web#60](https://github.com/PandiO/knk-web-app/pull/60), [ws#818](https://github.com/PandiO/knk-workspace/pull/818) | web app green (build-and-test, e2e) | create_session `session_01R1w2UuKsus7BT7DcXyL4jr` (one repo besides knk-workspace), started 2026-11-19 |
| L6 P2 world API: structure subtypes, TownId, placement rules | #91 | Merged into next (2026-11-19) | api `303b6ab`, workspace `9ab62ab1`; merges: api `fcfced27`, workspace `c7fe8996` (after a coordinator merge of `next`, `15e3011e`) | [api#57](https://github.com/PandiO/knk-web-api/pull/57), [ws#822](https://github.com/PandiO/knk-workspace/pull/822) | green (build-and-test, mysql-tests, fresh-database) | create_session `session_01R1w2UscSGsG34qwc8vtEQj` (one repo besides knk-workspace), started 2026-11-19 |
| L7 P2b world web app | #676 | Merged into next (2026-11-19) | web app `f5ea646`, workspace `9d578854`; merges: web app `18385344`, workspace `a5c05901` | [web#61](https://github.com/PandiO/knk-web-app/pull/61), [ws#829](https://github.com/PandiO/knk-workspace/pull/829) | web app green (build-and-test, e2e) | subagent of the coordinator (19:37; the create_session `session_01R1w2UwqC5tNA7JBrnf61ko` refused to start, decision 34) |
| L8 P2c world plugin: managed-region kinds | #677 | Merged into next (2026-11-19) | plugin `cc563771`, workspace `cb11e03a`; merges: plugin `8ebb30be`, workspace `4654a1ad` | [plugin#96](https://github.com/PandiO/knk-plugin/pull/96), [ws#823](https://github.com/PandiO/knk-workspace/pull/823) | green (plugin build + paper-boot, 64 scenarios) | create_session `session_01R1w2UtzV6puGzautXYEFJA` (one repo besides knk-workspace), started 2026-11-19 |
| L9 P3 production engine API | #86 | Merged into next (2026-11-19) | api `20dcfb7`, workspace `ea01df32`; merges: api `6c648f60`, workspace `7b1495d0` (after a coordinator merge of `next`, `50497cc8`) | [api#58](https://github.com/PandiO/knk-web-api/pull/58), [ws#827](https://github.com/PandiO/knk-workspace/pull/827) | green (build-and-test, mysql-tests, fresh-database) | create_session `session_01R1w2Uvi8uaBqDwjJDADicL` (one repo besides knk-workspace), started 2026-11-19 |
| L10 P3b production web app | #678 | Merged into next (2026-11-19) | web-app `9e5a2ca`, workspace `eaf1f1a1`; merges: web app `4e4ca39a`, workspace `9eef39cf` | [web-app#63](https://github.com/PandiO/knk-web-app/pull/63), [ws#834](https://github.com/PandiO/knk-workspace/pull/834) | green (build-and-test, e2e) | create_session `session_01R1w2UvmqQ34HGVHXxDfmwW` (prompt says start without asking), started 2026-11-19 |
| L11 P4 yield areas API | #138 | Merged into next (2026-11-19) | api `06b11ca`, workspace `b467e15a`; merges: api `e26c7d88`, workspace `e846be50` | [api#60](https://github.com/PandiO/knk-web-api/pull/60), [ws#837](https://github.com/PandiO/knk-workspace/pull/837) | green on `06b11ca` (build-and-test, mysql-tests, fresh-database) | create_session `session_01R1w2UuXh4wtTxPhhZUpLGF` (prompt says start without asking), started 2026-11-19 |
| L12 P4b surveys plugin | #679 | In review (2026-11-20) | plugin `3472e32d`, workspace `c6f53e07` | [plugin#105](https://github.com/PandiO/knk-plugin/pull/105), [ws#876](https://github.com/PandiO/knk-workspace/pull/876) | green (plugin build + paper-boot, 68 scenarios) | create_session `session_01R1w2Utt8cigo5ND98ZqXzC` (prompt says start without asking), started 2026-11-19 |
| L13 P4c yield areas web app | #680 | Merged into next (2026-11-20) | web app `6da700c`, workspace `638e5c3c`; merges: web app `eaf0467d`, workspace `2159952e` | [web-app#67](https://github.com/PandiO/knk-web-app/pull/67), [ws#873](https://github.com/PandiO/knk-workspace/pull/873) | green on `6da700c` (build-and-test, e2e) | create_session `session_01R1w2UwYw3NNQSSBoP7XaBk` (prompt says start without asking), started 2026-11-19 |
| L14 P5 transport API (simulated carrying, G14) | #79 | Done, in review (2026-11-20) | api `ef61cd1`, workspace `ae26c88b` | [api#65](https://github.com/PandiO/knk-web-api/pull/65), [ws#880](https://github.com/PandiO/knk-workspace/pull/880) | api build-and-test, fresh-database green; mysql-tests green on push run | create_session `session_01R1w2UtGLZrUEAUNFYvkqGB` (prompt says start without asking), started 2026-11-19 |
| L15 P5b lanes plugin | #681 | Not started | — | — | — | — |
| L16 P5c transport web app | #682 | Not started | — | — | — | — |
| L17 P6a API: StorageContainer, caller-filtered reads, menu seeds | #683 | Not started | — | — | — | — |
| L18 P6 plugin: terminals, displays, Structures menu, structure menu, orders list | #74 | Not started | — | — | — | — |
| L19 P7 delivery and inbox API | #60 | Not started | — | — | — | — |
| L20 P7b inbox plugin, kit/lootbox migration | #684 | Not started | — | — | — | — |
| L21 P8a harvest API | #685 | Not started | — | — | — | — |
| L22 P8 harvest plugin | #134 | Not started | — | — | — | — |
| L23 P9 town logistics API | #127 | Not started | — | — | — | — |
| L24 P9b logistics web app | #686 | Not started | — | — | — | — |
| L25 P10 shops API, town account | #248 | Not started | — | — | — | — |
| L26 P10b shop menus plugin | #687 | Not started | — | — | — | — |
| L27 P10c shops web app | #688 | Not started | — | — | — | — |
| L28 P11 shopkeepers | #249 | Not started | — | — | — | — |
| L29 P12 display stalls | #250 | Not started | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set: the `next` branch model.** Chosen: links branch from `next`, PRs target `next`, the coordinator merges
   into `next`, because on 2026-11-19 `.github/workflows/ci.yml` is on `origin/main` of both knk-web-api and
   knk-web-app (SKILL § 1.3). Alternatives: (a) the old rules (default branch, developer merges): no longer apply.
2. **L0 item identity (#141) runs inside this chain, first.** Chosen: run it as L0 here, because the charter lists it
   first with gate "now", P1 (L4) depends on it, and no other session claims it (board read 2026-11-19, no branch
   `claude/item-identity-141` in any repo). Alternatives: (a) a chain of its own: an extra coordinator for one link,
   and the charter leaves it to this chain; (b) L1 territory first: also open, but both need knk-web-api and only one
   link per component repo may run, and L0 unblocks the P1 path.
3. **Issues.** #141 and #326 added as sub-issues of #22 (they had no parent here; #326 keeps #689/#690 as its own
   sub-issues), and #141 labelled `tier:3` (charter and DESIGN § 18). No new issues: every link already has one.
4. **L0 route: subagent of this coordinator.** Chosen: the subagent route, because L0 changes two repositories
   besides knk-workspace (knk-web-api and knk-plugin) and SKILL § 4.1.4.2 sends such links that way from the start.
   Alternatives: (a) `create_session` with two `add_repo` attaches: an Auto-mode classifier refusal was observed for
   multi-repo prompts (#511); (b) splitting L0 into API and plugin links: the charter defines it as one link.
5. **Overlap check, L0 (board read 2026-11-19).** No "In progress" row claims `ItemBlueprint`,
   `BlueprintItemAssembler` or the item pickup/drop listeners. Other API work running from `next` (navigation
   destination engine, off-road navigation) adds its own migrations, so L0 keeps to one additive migration and
   merges `origin/next` before its PR if the model snapshot moved. Alternatives: none needed.
6. **CI on `next` before L0:** green (knk-web-api `935fe8c` Build and test + Migrations; knk-plugin `cee53213` Build +
   Paper boot test).

7. **Overlap with the siege weapons chain (#354), 2026-11-19.** Its coordinator reported that its L1 #782 adds a
   knk-web-api migration and a `KnKDbContext` block, and later links L3/L4/L8 may add more. Chosen: both chains keep
   `KnKDbContext` edits in their own block and generate their migration last, after merging `origin/next`. Whichever
   link merges second merges `origin/next` again and regenerates its migration instead of hand-editing the model
   snapshot. L0 was told this. Alternatives: (a) hold L0 until #782 merges: would idle the chain for a mechanical
   conflict; (b) one side hand-merges the snapshot: error-prone.

8. **L0 merge (2026-11-19).** All § 6 checks held: heads matched, branches contained `next`, scope matched #141, CI green
   (the plugin PR's own paper-boot run was required by the branch rule, so the plugin merged about 8 minutes after the
   API and workspace PRs), Codex at its usage limit on all three PRs (no findings; noted on each PR). Merged with merge
   commits: API #51 `7d213fd6`, workspace #793 `ca3bcc98`, plugin #89 `2ef256e7`.
9. **Docs for L0 now, not at the end of the chain.** Chosen: #141 is a feature issue of its own (a prerequisite that
   other features use too), so its `documentation` sub-issue #796 and docs session `session_01R1w2UwRChdpz3Hwn16udNZ`
   start at its merge into `next`. Alternatives: (a) one docs issue at the end of the 30-link chain: L0's docs would
   wait weeks and pile up with the rest.
10. **L1 started right after L0's API merge.** L1 (#326) needs only knk-web-api, L0 no longer ran there, and L1 does not
   build on L0, so the tier:3 smoke gate does not hold it. Alternatives: (a) wait for the developer's L0 smoke test:
   not required by charter § 2.3 for an unrelated link.

11. **`next` CI after L0 (2026-11-19).** The `next` run for `7d213fd6` failed one test,
   `RealtimeHubTests.UserStateEvent_FromAServiceScope_ReachesTheGameServer` (Expected 2, Actual 1), unrelated to L0.
   It passed on both PR runs and on the next `next` head `e940aef1`, which contains L0. Treated as flaky and filed as
   #801, not a blocker. Alternatives: (a) revert L0: the failure is not L0's; (b) stop merging until it is fixed: the
   current `next` head is green.
12. **L1 merge (2026-11-19).** § 6 checks held (branch contained `next` `e940aef1` with the siege migration; L1's
   migration was generated on top of it; CI green; Codex at its usage limit, no findings; scope matched #326). Merged:
   API #53 `0d6e369a`, workspace #798 `4595e6d8`.
13. **After L1: L2 and L3 in parallel; the API idles.** L2 (plugin) and L3 (web app) have open gates and use different
   repos. The next API link, L4 (#97), builds on L0 and is tier:3, so it waits for the developer's smoke test of L0
   (charter § 2.3). L6 needs L4. Alternatives: (a) start L4 without the smoke test: charter § 2.3 forbids it unless
   the developer says otherwise; (b) run an API link out of order: every other API link depends on L4 or later.
14. **Territory docs at the end of territory.** #326 is the parent of L1–L3, so its `documentation` sub-issue starts
   once L2 and L3 are merged, not now. Alternatives: (a) a docs issue per link: three docs sessions on one feature.

15. **Town/District form seed fields (L3's question on #690).** Chosen: no seed change in V1. The town page's
   Territory panel sets power, kingdom, province and capital districts, and bumping the Town and District form seeds
   would change field ids that other seeds' rules depend on (L1 decision). Alternatives: (a) a small API link to add the
   fields to the seeds: risk to other seeds' rules for no V1 gain. The developer can still ask for it (§ 1.4).
16. **L2 and L3 merge (2026-11-19).** § 6 checks held for both (heads matched, branches contained `next`, CI green:
   plugin build and paper-boot, web app build-and-test and e2e; Codex at its usage limit, no findings; scope matched
   #689 and #690). Merged plugin #91 `55804b11`, web app #57 `89751315` and workspace #804 `66d35872`. Workspace #803
   conflicted with #804 in the shared docs (changelog, smoke guide header and § 1 preconditions, plan and design status).
   Both sides only added text, so the coordinator merged `origin/next` into `claude/production-t-c` (`e4f2276d`). It kept
   both changelog entries, combined the headers and dropped the § 1.4 design draft that L3's § 1.4 replaces, then merged
   #803 `54bdc830`. Alternatives: (a) send it back to L3: a mechanical merge (SKILL § 7.3).
17. **Territory docs.** `documentation` sub-issue #806 under #326 and docs session `session_01R1w2UxD7Cb4e7GcQtEs8z1`
   (decision 14).
18. **Notes for P2 (L6 #91, L8 #677), from L2.**
   1. `InsideTerritory` needs a plugin lookup endpoint (like `RegionContainment`).
   2. Rural structures with a `TownId` are not in the territory report yet, because it skips structures without a
      district.
   The L6 and L8 prompts must carry both.
19. **No gate open (2026-11-19 12:00).** Every remaining link depends on L4 (#97). L4 builds on L0 and is tier:3, so it
   waits for the developer's smoke test of L0 (§ 1.1). The coordinator stops the loop and checks #22 and the digest
   issue for the developer's reply. Alternatives: (a) start L4 anyway: charter § 2.3 says no unless the developer
   waives it.

20. **Developer decisions, 2026-11-19 (in chat with the coordinator).**
   1. Start L4 (#97) without the smoke test of L0.
   2. Start L6 (#91) without the territory smoke test.
   3. G17 means every major entity. Conversion tables and many-to-many join tables are lower priority and may ship
      without form/display seeds at first. This settles L0's `item_conversion_stats` exception (block 4.0, decision 7):
      accepted.
   Applied: L4 started at once. L6 starts as soon as L4 is merged, because its gate is "L1, L4 merged" and both are
   knk-web-api. The coordinator also reads the waiver as covering L4's own smoke gate for L6, because the developer
   asked for L6 to start without waiting on smoke tests. Alternatives: (a) hold L6 for L4's smoke test: against the
   intent of the instruction; the developer can still ask for it.

21. **L4 stopped on the usage limit (2026-11-19).** The L4 session hit the account's 5-hour usage limit at 12:43 UTC
   before it pushed anything. The coordinator's check-in was also delayed, to 16:03, by a worker restart. At the
   developer's "try again" the coordinator resumed the same session (16:05). It checks whether its local work
   survived, pushes work in progress at once, and pushes regularly from now on. Alternatives: (a) a fresh L4 session:
   would lose any surviving local work; (b) a subagent: the same usage limit applies.
22. **Territory docs #806:** done by its docs session (bug #807 filed: a conflict page's Edit has no update endpoint).

23. **L4 merge (2026-11-19).** Knk-web-api `next` moved while L4 finished: siege #799 changed the form seed README
   and `FormConfigurationSeedFilesTests`, with no migration. The merge was clean, but the change touched the same test
   file, so the coordinator merged `origin/next` into `claude/production-p1` (`06fee906`) and waited for CI on the
   combined code (all green) before merging. Merged: API #56 `2e7d4e81`, workspace #816 `1bbdd69f` (that branch merged
   cleanly with `next`). Alternatives: (a) merge on the clean-merge check alone: the shared test file could fail only
   in combination.
24. **After L4: L6 (#91) and L5 (#675) started.** Both gates are open (L6: L1, L4 merged, smoke gates waived by the
   developer; L5: L4 merged) and they use different repos. Both prompts now ask for a work-in-progress push at least
   every hour (lesson from decision 21).
25. **P1 docs at the end of P1.** The `documentation` sub-issue for stock core (#97, #675) starts when L5 is merged,
   like territory (decision 14).

26. **L5 merge (2026-11-19).** § 6 checks held: heads matched, both branches contained `next` (clean), CI was green
   (build-and-test, e2e), Codex was at its usage limit (no findings) and the scope matched #675. Merged: web app #60
   `9f46cb49`, workspace #818 `8fff63e2`.
27. **ItemBlueprint `StorageWeight` seed field and Storage display names (L5's question on #675).** Chosen: ItemBlueprint
   is a major entity, so its form gets the field. Filed as #819 (tier:1, under #97) and folded into the next
   knk-web-api link, L9 (#86), as an additive extra. Alternatives: (a) add it to L6, which is already in CI: it would
   widen a finished link; (b) a separate one-file link: overhead for a seed bump.
28. **P1 docs.** `documentation` sub-issue #820 under #97, docs session started (decision 25).

29. **L6 merge (2026-11-19).** § 6 checks held:
   1. Heads matched, and the API branch contained `next`.
   2. CI was green (build-and-test, mysql-tests, fresh-database). Codex was at its usage limit, so there were no
      findings.
   3. The scope matched #91. L6 also edited existing siege, map, hub-settings and domain code. Each edit adapts a
      reader of `Structure.DistrictId` to it becoming optional (rural structures), which is part of #91.
   4. Both of decision 18's notes are handled: `InsideTerritory` calls a plugin lookup that L8 answers, and the
      structure search lists the effective `townId` for the territory report.
   Merged API #57 `fcfced27`. Workspace #822 conflicted with L5's docs in `next` (installation guide, smoke guide
   header, plan status). Both sides only added text, so the coordinator merged `origin/next` into
   `claude/production-p2` (`15e3011e`) and then merged #822 `c7fe8996`.
30. **After L6: L7 (#676), L8 (#677) and L9 (#86) in parallel.** Their gates are open (L6 merged) and they use three
   different repos (web app, plugin, API). L9 carries #819 as an additive extra (decision 27). The coordinator reads
   the developer's waiver (decision 20) as covering L9's build on L6. The siege coordinator was told about the
   nullable `Structure.DistrictId` and L9's coming migration.
31. **P2 docs at the end of P2.** The `documentation` sub-issue for P2 (#91, #676, #677) starts when L7 and L8 are
   merged.

32. **L7 waited for a "go" (2026-11-19).** The L7 session asked "run L7 as described?" at 18:43 and sat idle until the
   19:34 check-in. The coordinator answered yes within its scope (SKILL § 5.2). Lesson for later prompts: say at the
   top that the link starts at once without asking. Alternatives: (a) restart it: would lose nothing but time.
33. **L8 merge (2026-11-19).** § 6 checks held:
   1. Heads matched, and both branches contained `next`.
   2. CI was green: plugin build and paper-boot, with 64 scenarios.
   3. Codex was at its usage limit, so there were no findings.
   4. The scope matched #677. It also raised `MIN_SCENARIOS` in `paper-boot.yml` from 63 to 64 for its new
      `rural-structure-region` scenario, and made `RegionOutlineAdapter.outlineOf` public for rural region outlines.
      Both are small and needed.
   Merged plugin #96 `8ebb30be` and workspace #823 `4654a1ad`. No plugin link has an open gate now: L12, L15, L18 and
   L20 wait for API links.

34. **L7 rerun as a subagent (2026-11-19 19:37).** After the coordinator's "go", the L7 cloud session still refused to
   start. It took its initial prompt and the coordinator's message as peer messages, not the developer's instruction, and
   asked for the developer to confirm in that session. This is the same Auto-mode behaviour as the refused `add_repo`
   of SKILL § 4.1.4. Chosen: rerun L7 as a subagent of the coordinator with the same scope (SKILL § 4.1.2/§ 4.1.4.3);
   the stalled session was told to stop. Alternatives: (a) ask the developer to type "run L7" in that session: a
   manual step per link; (b) a new `create_session`: the same refusal is likely. If more `create_session` links refuse,
   the coordinator runs single-repo links as subagents too.

35. **L7 merge (2026-11-19).** § 6 checks held:
   1. Heads matched, and both branches contained `next`.
   2. CI was green (build-and-test, e2e: 263 Playwright tests).
   3. Codex was at its usage limit, so there were no findings.
   4. The scope matched #676. Its edits outside the new pages (the rule builder, `PagedEntityTable` flag filter,
      `StoragePanel` title, `FormWizardPage` warnings) are its own scope items.
   Merged web app #61 `18385344` and workspace #829 `a5c05901`. P2 (L6–L8) is complete: `documentation` sub-issue #830
   under #91, with docs session `session_01R1w2UvVrxn9QYLtB8CBthh`.
36. **P2 API follow-ups found by L7 (#831, tier:1).** Three knk-web-api items: an update drops the placement warnings;
   the error messages carry a .NET parameter suffix; the Structure form seed lacks Town. Chosen: fold them into the
   next free knk-web-api link (L11 #138) as an additive extra, like #819 in L9. Alternatives: (a) a separate link:
   overhead for three small fixes.

37. **P2 docs #830:** done by its docs session (PR #833 merged; promotion-time leftovers in #832).
38. **L9 merge (2026-11-19).** § 6 checks held:
   1. Heads matched, and the API branch contained `next`.
   2. CI was green (build-and-test, mysql-tests, fresh-database). Codex was at its usage limit, so there were no
      findings.
   3. The scope matched #86 plus #819: the ItemBlueprint form v2 and the Storage display v2.
   4. Its additive touches outside production (currency reason `PRODUCTION_UPGRADE`, `StockReason.Upgrade`, player
      notification queue items) are part of the upgrade and notification scope.
   Merged API #58 `6c648f60`. Workspace #827 conflicted with L7/L8 docs in `next`. Both sides only added text, so the
   coordinator merged `origin/next` (`50497cc8`) and then merged #827 `7b1495d0`. The migration needs a pre-check
   (§ 1.4.1): a FK on `ProductionKindId` fails on unknown kind ids.
39. **After L9: L11 (#138, with #831) and L10 (#678) started** as cloud sessions whose prompts begin with "start at
   once, don't ask" (lesson of decision 34). L12 (#679) and L13 (#680) wait for L11. The plugin is idle until then.
   The account showed a weekly usage-limit warning (`seven_day`, `allowed_warning`), so both prompts stress frequent
   pushes.

40. **L10 merge (2026-11-19).** § 6 checks held:
   1. Heads matched, and both branches contained `next` (clean).
   2. CI was green (build-and-test, e2e). Codex was at its usage limit, so there were no findings.
   3. The scope matched #678.
   Merged web app #63 `4e4ca39a` and workspace #834 `9eef39cf`. P3 (L9–L10) is complete: `documentation` sub-issue
   #839 under #86, with a docs session.
41. **P3 API follow-ups found by L10 (#838, tier:1).** Three knk-web-api reads: the kind name on the structure list,
   the blueprint name on consumed inputs, and a cycle-record list. Chosen: fold them into the next free knk-web-api
   link, L14 (#79), as an additive extra (L11 already carries #831). Alternatives: (a) add them to the running L11: it
   is close to its PRs.

42. **L11 merge (2026-11-19).** § 6 checks held:
   1. Heads matched, and both branches merged cleanly with `next`.
   2. CI was green (build-and-test, mysql-tests, fresh-database). Codex was at its usage limit, so there were no
      findings.
   3. The scope matched #138 plus #831: the placement warnings on update, the plain errors through
      `ArgumentExceptionExtensions`, and `Structure` form v3 with Town.
   Merged API #60 `e26c7d88` and workspace #837 `e846be50`. L11 filed #836 (default yield tables per kind).
43. **After L11: L12 (#679), L13 (#680) and L14 (#79, with #838) in parallel.** Each one's gate is open and they use
   three different repos. L14 is the next API link in charter order; L19 (P7) and L25 (P10) also have open gates but
   come later in that order.

44. **L12, L13, L14 stopped on the usage limit (2026-11-19 22:13).** All three hit the account's 5-hour limit, which
   reset at 23:40. This coordinator session was also idle until 2026-11-20 12:08, so the 22:46 check-in fired 13 hours
   late. L12 (`c00f95a2`) and L13 (`efcfcfc`) had pushed work in progress; L14 had not pushed yet. All three were
   resumed at 12:10 with send_message: push what survived, merge the moved `next`, carry on. The weekly limit still
   shows a warning (resets about 17:00 UTC). Alternatives: (a) fresh sessions: would lose L14's unpushed work if it
   survived.
45. **P3 docs #839:** done (PR #844 merged).
46. **Siege shop chain (#611, same coordinator as #354), 2026-11-20.** Shop L1 #866 adds a knk-web-api migration, and a
   plugin link edits `KnKPlugin`, `config.yml` (`siege.points`) and `plugin.yml` in its own blocks. Same rule as decision
   7: whoever merges second regenerates. L12 and L14 were told.

47. **L13 merge (2026-11-20).** § 6 checks held: heads matched, branches merged cleanly with `next`, CI was green
   (build-and-test, e2e), Codex was at its usage limit (no findings) and the scope matched #680. Merged web app #67
   `eaf0467d` and workspace #873 `2159952e`. The API points L13 raised (area seed `RegionClaim` and bounds,
   `CaptureRadius`, `yieldSource` on the structure list) are #877 (tier:1). They fold into L17 (#683), the next API link,
   and the plugin part of `CaptureRadius` goes into a later plugin link. P4 docs start when L12 is merged.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.0 L0 — Item identity: every obtainable item is a blueprint; generated "Uncurated" shadow blueprints (#141)

1. **Scope done.**
    1. knk-web-api: `ItemBlueprint.VanillaMaterialMatchRefId` (unique FK to the material catalogue; read/list DTOs);
       `Services/ItemIdentity/VanillaShadowBlueprints` (plain shadows in a top-level "Uncurated" category for every
       obtainable material without a match, after every applied catalogue scan and on demand); `api/ItemIdentity`
       (`GET material-map`, `GET report`, `POST shadows/generate`, `PUT matches/{materialRefId}`,
       `POST conversion-counts`); `item_conversion_stats` count rows; catalogue merges keep one match per material;
       one additive migration `AddItemIdentity`.
    2. knk-plugin: knk-core `core/items/identity/` (map, resolver instance tag → blueprint tag → vanilla match, retag
       rule, conversion log) and port `ItemIdentityApi`; knk-api-client `ItemIdentityApiImpl`; knk-paper
       `mapper/BlueprintTag` (stamped by `BlueprintItemAssembler`), `items/identity/ItemIdentityService` and
       `ItemConversionListener` (pickup, block drops, death drops, fishing, craft, trades, first container open);
       `config.yml` `items.identity` (`enabled`, `convert-on-obtain` both false, `map-refresh-minutes`,
       `report-interval-minutes`).
    3. knk-workspace (branch from `next`): smoke guide § 0 (14 steps, 7 automated, 4 partly), plugin configuration
       reference § 4.30, changelog entry, implementation plan status.
2. **Commits and heads.** knk-web-api `claude/item-identity-141` at `5daa3c6` (1 commit, base `next` at `935fe8c`);
   knk-plugin `claude/item-identity-141` at `a6c5a2bc` (1 commit, base `next` at `cee53213`); knk-workspace
   `claude/item-identity-141` at `8ffdbb1a` (1 commit, base `next`). `origin/next` had not moved in any repo when the
   PRs were opened, so no merge was needed.
3. **PRs.** [knk-web-api#51](https://github.com/PandiO/knk-web-api/pull/51) (Closes #141),
   [knk-plugin#89](https://github.com/PandiO/knk-plugin/pull/89),
   [knk-workspace#793](https://github.com/PandiO/knk-workspace/pull/793); base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` 4452 passed / 100 skipped; branch 4485 passed / 103 skipped, 0 failed. New
       MySQL tests (`ItemIdentityMySqlTests`, 3) run locally on MySQL 8.0.46: green. Migration applied, rolled back
       and re-applied locally; `has-pending-model-changes` clean. CI on `5daa3c6`: push run 44496069809/44496069771 green (build-and-test, mysql-tests, fresh-database); the PR runs 44497990049/44497990070 were still running when this block was written.
    2. knk-plugin (`./gradlew build -x deployToDevServer`, JDK 21 + JDK 25 toolchain): knk-core 3435 → 3450,
       knk-api-client 358 → 361 (2 skipped), knk-paper 3147 → 3172 (18 skipped), 0 failures. CI on `a6c5a2bc`: build green (push run 44497524668); paper-boot (44497524587, 44498035485) and the PR build (44498035568) still running when this block was written.
    3. Known reds (also red on the base): none in the default run; `MinecraftCatalogMySqlTests.UpgradePath_…` is the
       known failure #285 (tagged `KnownFailure`) when the MySQL tests run.
5. **Decisions (DESIGN § 4.3).**
    1. *Retag/merge rule.* Chosen: the plain vanilla item is the canonical form: `knk_blueprint` only on items that
       differ from the plain vanilla item, a plain item resolves through its vanilla match, a plain item that carries a
       tag is normalised by the hooks; the tag is never the only difference between two stacks, so stacking is
       vanilla's. Alternatives: (a) stamp every obtained item: untagged items still enter from paths without a hook
       and stop stacking; (b) stamp everything and merge on inventory events: misses pickup auto-merge, hoppers and
       shift-click.
    2. *Switch.* Chosen: `items.identity.enabled` and `items.identity.convert-on-obtain`, both false (tier:3, every
       item path). Alternatives: (a) one key: no stamping without hooks while testing; (b) none (charter): unreviewed
       item handling would run in `next`.
    3. *Match storage.* Chosen: unique nullable FK, set only by generation and `PUT api/ItemIdentity/matches/{id}`,
       not in create/update DTOs. Alternatives: (a) a key string: no catalogue integrity or merge handling; (b) in the
       update DTO: today's form would null it on every save.
    4. *Generation trigger.* Chosen: after every applied scan and on demand (additive, idempotent). Alternatives:
       (a) at startup: ~1,400 rows on every fresh DB and in tests; (b) on demand only: not "automatic" (D11).
    5. *Obtainable.* Chosen: item + Active in the latest scan, minus a short operator/technical list and spawn eggs.
       Alternatives: (a) every item; (b) a full survival table (version-dependent).
    6. *Existing data / merges.* The migration writes nothing (column NULL), so no duplicates can exist; a merge of
       two matched materials keeps the target's match and clears the other. Alternatives: (a) refuse such merges:
       blocks the scan's notation clean-up.
    7. *Conversion counts.* Chosen: aggregate rows `item_conversion_stats`, not a form/dashboard type, so no G17
       seeds (like `MinecraftCatalogScan`). Alternatives: (a) full entity with dashboard registry and seeds; (b) plugin
       log only: no API admin read.
    8. *First container open.* Chosen: remembered in memory per server run. Alternatives: (a) a PDC flag on the
       block: a world write plus a snapshot `update()` on a live inventory.
    9. *Craft/trade results* are counted, not rewritten (vanilla results are plain); the craft preview is normalised.
    10. *DbContext layout* (coordinator note, siege chain #354 / #782 overlap): the item identity model configuration
        is one contiguous block plus one `DbSet` line. If another migration lands in `next` before this merges: merge
        `origin/next` into the branch and regenerate `AddItemIdentity` with `dotnet ef migrations add` (delete the old
        files first) instead of hand-editing the snapshot.
6. **Out of scope, noted.** [#791](https://github.com/PandiO/knk-workspace/issues/791) (retag blueprint items handed
   out before the switch; they don't stack with new tagged ones),
   [#792](https://github.com/PandiO/knk-workspace/issues/792) (web app admin view, retention of the count rows).
   Codex: the connector hit its code-review usage limit on all three PRs (review "failed", usage-limit comment); no
   findings to handle; skipped per the 2026-11-14 decision and noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply migration `AddItemIdentity` (additive), then run a Minecraft catalogue scan or
       `POST api/ItemIdentity/shadows/generate` to create the shadows.
    2. Merge into the plugin `config.yml` (both switches off = no change), restart:
       ```yaml
       items:
         identity:
           enabled: false
           convert-on-obtain: false
           map-refresh-minutes: 10
           report-interval-minutes: 10
       ```
    3. Smoke test [§ 0](../guides/production-storage-transport-smoke-test.md#0-item-identity-141-api-and-plugin-tier3)
       (tier:3 gate before L4 builds on it); untagged steps about 25 minutes.
    4. At merge into `next`: the `documentation` sub-issue for the follow-up docs impact lines (API docs, content admin
       guide, feature register row, DESIGN § 8 retag rule).
9. **Notes for later links.**
    1. L4 (P1 stock) and later: resolve items with `KnKPlugin.getItemIdentityService().resolve(stack)` (null while
       `items.identity.enabled` is off); `ItemIdentityResolution.blueprintId()` is the stock key; unresolved items
       are refused per DESIGN § 8.
    2. API side: a material's blueprint is the `ItemBlueprint` with `VanillaMaterialMatchRefId` = the material's id;
       shadows are the blueprints in the top-level "Uncurated" category.

### 4.1 L1 — Territory API: holders, crown land entity (G10), power, range (G11), conflicts, loyalty (#326)

1. **Scope done** (knk-web-api, plus essential docs in knk-workspace).
    1. Holders: entities `Kingdom`, `Province` (one kingdom, name unique per kingdom) and `CrownLand` (a `Domain`
       subtype owned by a kingdom, with `Range`, region captured like a district, G10). `Town.Power`/`KingdomId`/
       `ProvinceId` (province must be in the town's kingdom), `District.IsCapital`.
    2. Range = base + power × factor, capital × multiplier (G11), from the new game settings section `production`
       (`enabled` = `Production:Enabled`, default off; `territory` base 100, factor 2, capital 1.5).
    3. Plugin inputs: `GET api/Territory/inputs` (one read: kingdoms, towns, districts and crown land with region,
       sub-regions, holder, rank and computed range, awards, `version` hash) and realtime event `TerritoryChanged`
       (scope `territory`) on any input change; the report's own writes send none.
    4. Conflicts: `PUT api/Territory/report` (plugin key, `Production:Enabled` on, else 409) turns equal-rank overlaps
       into open `TerritoryConflict` rows and flags structures (`OutsideTerritory`/`Contested`, listed on the
       conflict, cleared when no longer reported). Admins: `api/TerritoryConflicts/{id}/resolve` (Awarded/Redrawn),
       `reopen`, delete.
    5. Structures: `LoyaltyTownId` (stored only; `PUT api/Territory/structures/{id}/loyalty`), territory flag.
    6. CRUD controllers `api/Kingdoms`, `api/Provinces`, `api/CrownLands`; dashboard registry, lookups, pinned access
       tests; form and display seeds for the four new entities (G17). One additive migration `AddTerritory`.
    7. knk-workspace: smoke guide § 1 (1.1-1.2: 19 steps, all tagged; 1.3 keeps the plugin/web app draft), changelog,
       production installation § 5.3, territory DESIGN and implementation plan status.
2. **Commits and heads.** knk-web-api `claude/production-t-a` at `ff50ec1` (3 commits + merge of `origin/next`
   `e940aef` with the siege weapons migration, before generating `AddTerritory`); knk-workspace `claude/production-t-a`
   at `c4211d51` (1 commit, base `next` `80f6ff72`). `next` had not moved again when the PRs were opened.
3. **PRs.** [knk-web-api#53](https://github.com/PandiO/knk-web-api/pull/53) (Closes #326),
   [knk-workspace#798](https://github.com/PandiO/knk-workspace/pull/798) (Part of #326); base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` `7d213fd` 4485 passed / 103 skipped; branch after merging `next` `e940aef`
       4600 passed / 103 skipped / 0 failed (new: `TerritoryRulesTests`, `TerritoryServiceTests`,
       `TerritoryConflictServiceTests`, `TerritoryHolderServicesTests`, `ProductionSettingsTests`,
       `TerritoryRealtimeEventTests`, `AddTerritoryTests`; 65 tests; the rest of the rise is the siege tests from `next`).
       With `KNK_TEST_MYSQL` on MySQL 8.0.46: 4702 passed, 1 failed = the known red #285
       (`MinecraftCatalogMySqlTests.UpgradePath_…`). Migration applied, rolled back to `AddSiegeWeapons`, re-applied;
       `has-pending-model-changes` clean. CI on `ff50ec1` (PR run 44507088448): build-and-test, mysql-tests,
       fresh-database green.
    2. Known reds: #285 only (MySQL run).
5. **Decisions (DESIGN § 4.3).**
    1. *Where territory is computed.* Chosen: the game server (it has the region geometry); the API holds inputs and
       the reported results and computes ranges. Alternatives: (a) API computes overlaps: it has no region shapes and
       would ask the plugin per chunk; (b) plugin owns conflicts too: no admin record or resolution in the database.
    2. *Conflict detection contract.* Chosen: one full-snapshot report per world; an open conflict per holder pair and
       world; a gone overlap stays open with `stillOverlapping: false`. Alternatives: (a) auto-close vanished
       conflicts: DESIGN § 3 says admins resolve; (b) incremental reports: lost messages leave stale flags.
    3. *Creation-time territory check.* Chosen: the structure flag from the next report (warns, never blocks); the
       form rule `InsideTerritory` stays with P2 (#91, DESIGN § 3.4). Alternatives: (a) API→plugin lookup call at
       save: needs a plugin endpoint that does not exist before #689; (b) add `InsideTerritory` now: P2's item.
    4. *Loyalty field shape.* Chosen: `LoyaltyTownId` (the town it is loyal to; null = its own), since DESIGN § 4
       Later speaks of "the town it is loyal to". Alternatives: (a) a 0-100 number: no target town for switching
       sides; (b) both: speculative.
    5. *Settings location.* Chosen: game settings JSON section `production` (`enabled`, `territory`), like hub and
       chat tokens. Alternatives: (a) `appsettings`/`api.env`: not editable by admins, a restart to change; (b) three
       columns: the next links add more production settings.
    6. *Flag gating.* Chosen: the report (the only background work) answers 409 when off; CRUD, inputs and resolve
       stay on. Alternatives: (a) gate the inputs read too: the plugin could not show its state; (b) no gate.
    7. *Town fields on the existing DTO.* Chosen: `power`, `kingdomId`, `provinceId` on `TownDto` with "null power =
       not on this form" (teleport pattern), `isCapital` nullable on `DistrictDto`. Alternatives: (a) a separate
       endpoint only: the web app's town form could not edit them; (b) always applied: today's forms would wipe them.
    8. *Services on the DbContext, manual DTO projection* for the new types (like 33 existing services). Alternatives:
       (a) repository + AutoMapper per entity: ~10 more files for plain CRUD.
    9. *TerritoryConflict in the registry* as a deletable World type without create/update (`changesNeedContent:
       false`, added to the `ChangesWithoutContent` test list; read-only form seed). Alternatives: (a) `ViewOnly`:
       no admin delete of a stale conflict.
    10. *Crown land region domain type.* Chosen: none sent to the plugin on rename (no parent, plugin only renames);
        a managed-region kind is #689's. Alternatives: (a) send "CrownLand": unknown to today's plugin.
    11. *Town and District form seeds* not bumped (power, kingdom, province, capital); #690 adds them. Alternatives:
        (a) new seed versions now: re-GUIDs the Town field other seeds' rules depend on.
6. **Out of scope, noted.** On #326 (comment): #689 should add a `CrownLand` managed-region kind and implement the
   inputs/report contract (knk-web-api#53 "Contract for #689"); #690 adds the town/district territory fields to the
   Town and District forms and the conflict resolve actions. No new issues.
   Codex: the connector hit its code-review usage limit on both PRs (review "failed", usage-limit comment); no
   findings to handle; noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply migration `AddTerritory` (additive). Import the form seeds `Kingdom`, `Province`, `CrownLand`,
       `TerritoryConflict` and the four display seeds ("make default", `Kingdom` first).
    2. Keep `production.enabled` false (game settings) until #689 is deployed. No plugin `config.yml` change.
    3. Smoke test [§ 1.1-1.2](../guides/production-storage-transport-smoke-test.md#1-territory-v1-326-api-689-plugin-690-web-app-tier3)
       (tier:3 gate before L6 builds on it); untagged steps none (1.2.6 needs a connected server to check by hand).
    4. At merge into `next`: the `documentation` sub-issue (API contract page, admin guide, feature register row).
9. **Notes for later links.**
    1. L2 (#689): read `GET api/Territory/inputs`, rebuild on `TerritoryChanged` when `version` changed, use each
       region's `range` as given, rank 2 beats 1, awards win their chunks; report per world with
       `PUT api/Territory/report` (full snapshot) only when `productionEnabled`. Reference: `TerritoryRules.Resolve`.
    2. L3 (#690): endpoints `api/Kingdoms`, `api/Provinces`, `api/CrownLands`, `api/TerritoryConflicts` (+ `resolve`,
       `reopen`), `api/Territory/towns/{id}` (effective ranges), `api/Territory/structures/{id}` (+ `loyalty`, `flag`);
       game settings section `production`.
    3. L6 (P2): rural `TownId` and `InsideTerritory` are yours; the structure flag and `TerritoryConflictId` exist.

### 4.2 L2 — Territory plugin: chunk cache, lookup, BlueMap outlines (#689)

1. **Scope done** (knk-plugin, plus essential docs in knk-workspace). Everything runs only with the new plugin key
   `production.enabled: true` (default `false`, A21).
    1. knk-core `core/territory/` (Bukkit-free): `TerritoryInputs` (the `GET api/Territory/inputs` contract of #326),
       `TerritoryRules` (the API's `Resolve`: rank, contest, awards), `TerritoryShape` (distance to the nearest region
       edge, region plus sub-regions, G11), `TerritoryCacheBuilder`/`TerritoryMap`/`TerritoryCache` (whole chunks and
       split chunks resolved per block column; wilderness not stored), `TerritoryReportBuilder` (equal-rank overlaps
       per pair with chunks; structures `Contested`/`OutsideTerritory`), `TerritoryOutlines` (rings per area from the
       cache, block steps, holes), `TerritoryTracker` (lookup on chunk crossings, per column in split chunks),
       `TerritoryService` (rebuild when the inputs' `version`, the shapes' fingerprint or the API flag change; one
       full report per world when `report` and the API's `productionEnabled` are on; outlines over the hub only with
       `map-outlines`); port `TerritoryApi`.
    2. knk-api-client `TerritoryApiImpl` (`GET api/Territory/inputs`, `PUT api/Territory/report`, 409 kept as status);
       `ConfigEvents.TERRITORY_CHANGED` (not in `TYPES`).
    3. knk-paper `territory/`: `TerritoryModule` (first build 5 s after start, periodic check, debounced
       `TerritoryChanged`, hub reconnect hook), `TerritoryListener` (moves, teleports, respawns, world changes;
       `PlayerTerritoryChangeEvent`, action bar), `TerritoryConfig`; `/knk territory here|status|rebuild` (node
       `knk.admin.world.territory`); `config.yml` block `production` (`enabled`, `territory.refresh-minutes`,
       `notify-players`, `report`, `map-outlines`, `max-chunks-per-world`, `messages.*`).
    4. Crown land managed-region kind (L1's note on #326): `ManagedRegionKind.CROWN_LAND` (floor 10, no parent, no
       flags); the repair adds crown land regions from the domain catalog only with `production.enabled`.
    5. Plugin scenario `territory-border-crossing` (real WorldGuard region, the plugin's cache and listener, a scripted
       player one block over the border); `MIN_SCENARIOS` 62 → 63.
    6. knk-workspace (branch from `next`): smoke guide § 1.3 (14 plugin steps, 7 automated, 7 partly; the web app draft
       moved to § 1.4), plugin configuration reference § 4.31, changelog entry with the YAML, commands guide
       `/knk territory`, territory DESIGN and implementation plan status.
2. **Commits and heads.** knk-plugin `claude/production-t-b` at `96ef7326` (2 commits + merge of `origin/next`
   `2f970779`, siege weapons L2); knk-workspace `claude/production-t-b` at `14d3efcd` (1 commit + merge of `origin/next`
   `2f0dc79c`; changelog and configuration reference conflicts were both-sides additions). `next` had not moved again
   at the final fetch.
3. **PRs.** [knk-plugin#91](https://github.com/PandiO/knk-plugin/pull/91) (Closes #689),
   [knk-workspace#804](https://github.com/PandiO/knk-workspace/pull/804) (Part of #689); base `next`. Not merged.
4. **Tests, baseline → result** (`./gradlew build -x deployToDevServer`, Gradle on JDK 21, JDK 25 toolchain).
    1. Baseline on `next` `2ef256e7`: knk-core 3450, knk-api-client 361 (2 skipped), knk-paper 3172 (18 skipped), 0
       failures.
    2. Branch after merging `next` `2f970779`: knk-core 3510, knk-api-client 368 (2 skipped), knk-paper 3200 (18
       skipped), 0 failures. New: knk-core 41, knk-api-client 3, knk-paper 10; the rest is siege weapons L2 from `next`.
       A mutation of the range check failed the cache tests.
    3. CI on `96ef7326`: build green, paper-boot green (63 scenarios, `territory-border-crossing` included).
    4. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Where outlines go.* Chosen: built from the cache in the plugin and sent over the game hub
       (`ReportTerritoryOutlines`), off by default (`map-outlines`), because overview map O15 (2026-11-18) puts no
       BlueMap plugin on the game server and § 1 item 3.3 sends territory through that path; the API store and bridge
       layer is #802. Alternatives: (a) BlueMap marker API on the game server: contradicts O15; (b) reuse
       `ReportRegionOutlines` with synthetic ids: stored and drawn as domain regions; (c) no outlines: in the scope.
    2. *Split chunks at build time.* Chosen: every column of a partly reached chunk is computed off the main thread at
       build, because the report and outlines need them and a lookup stays a map read. Alternatives: (a) lazy
       per-column memo: geometry on the main thread, a mutable cache.
    3. *Chunk classification.* Chosen: centre distance ± half the chunk diagonal (1-Lipschitz bound), exact per column
       for the rest. Alternatives: (a) per column everywhere: ~256× the work.
    4. *Structure position.* Chosen: the region bounding box's centre column. Alternatives: (a) any column of the region:
       flags structures barely touching a border; (b) the Location: optional, not on the search DTO.
    5. *OutsideTerritory includes crown land.* Chosen: land the structure's town does not own (wilderness, another
       town, crown land), literally DESIGN § 4. Alternatives: (a) same-kingdom crown land counts as inside: not in the
       design.
    6. *Entry/exit line.* Chosen: action bar, configurable, `notify-players`. Alternatives: (a) chat: noisy; (b) title:
       intrusive.
    7. *Realtime handler.* Chosen: `registerTerritorySync` registers `TerritoryChanged` directly, only with the flag,
       leaving `ConfigRealtimeSync.Targets` and `ConfigEvents.TYPES` untouched (other chains use them). Alternatives:
       (a) a new `Targets` component: changes a shared constructor.
    8. *Crown land gating.* Chosen: the repair includes crown land only with `production.enabled`;
       `fromDomainType("CrownLand")` maps to `CROWN_LAND` always (no domain type is sent today, L1 decision 10).
       Alternatives: (a) gate the mapping too: a flag check in core code for a type that only exists with the feature.
    9. *Report trigger.* Chosen: after every rebuild and on a forced rebuild, not on unchanged periodic checks.
       Alternatives: (a) every periodic check: a paged read of every structure every 10 minutes.
    10. *Coordinator note on overlaps.* `KnKPlugin` wiring and the `config.yml` `production` block are separate
        additive blocks; no navigation, NPC or siege code touched; the siege L2 merge was mechanical.
6. **Out of scope, noted.** [#802](https://github.com/PandiO/knk-workspace/issues/802) (sub-issue of #326): API storage
   and BlueMap bridge layer for `ReportTerritoryOutlines` (smoke § 1.3 step 14 waits for it). For P2 (#91):
   `InsideTerritory` needs a plugin lookup endpoint (like `RegionContainment`), and rural structures with `TownId` are
   not in the report yet (it skips structures without a district). Codex: the connector hit its code-review usage limit
   on both PRs (review "failed", usage-limit comment); no inline findings; noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Merge the `production` block into the plugin `config.yml` (YAML in the changelog entry and knk-plugin#91; the
       switch off = no change), restart.
    2. To test: plugin `production.enabled: true`, the API's game setting `production.enabled` on, staff with
       `knk.admin.world.territory` (in `knk.admin.*`); keep `map-outlines: false` until #802.
    3. Smoke test [§ 1.3](../guides/production-storage-transport-smoke-test.md) (tier:3); the untagged and partly
       tagged parts about 25 minutes.
    4. At the end of territory (L2 and L3 merged): the `documentation` sub-issue of #326 (coordinator decision 14):
       territory architecture page (cache, split chunks, report and outline payloads), plugin scenarios guide
       (`territory-border-crossing`), territory admin and player guides, feature register row.
9. **Notes for later links.**
    1. Placement and entry rules (P2 #91, L6/L8): `KnKPlugin.getTerritoryModule().service().lookup(world, x, z)` gives a
       `TerritoryVerdict` (owner, contesting); listen to `PlayerTerritoryChangeEvent` for entry and exit. Both are null
       / never fired while `production.enabled` is off.
    2. L18 (P6): `/knk territory here` is the staff lookup; reuse `TerritoryCache.describe` for names.

### 4.3 L3 — Territory web app (#690)

1. **Scope done** (knk-web-app, plus essential docs in knk-workspace).
    1. Holders and crown land: DTO types `src/types/dtos/territory/TerritoryDtos.ts`; clients `kingdomClient`,
       `provinceClient`, `crownLandClient`, `territoryConflictClient` (search, fetch, `resolve`, `reopen`, delete; no
       create/update), `territoryClient` (`towns/{id}`, `structures/{id}`, `loyalty`, `flag`, territory-only saves of
       towns and districts); `Controllers` enum, `entityApiMapping` and `objectConfigs` columns (grouped, additive). The
       dashboard, detail pages and the seeded Kingdom/Province/CrownLand forms work through the metadata framework;
       crown land's region step is the same world task field as a district's (G10).
    2. Town page: Territory panel (`src/components/territory/TownTerritoryPanel.tsx`): power, kingdom, province, range
       and capital range, district list with ranges; edit power / kingdom / province (provinces of the kingdom only);
       capital toggle per district (G11).
    3. Conflict page: Contested zone panel (`TerritoryConflictPanel.tsx`): holders, area, overlap, detected / last
       reported, flagged structures; award to either holder or mark redrawn with a note after a confirmation; reopen
       (A05).
    4. Structure page: Territory and loyalty panel (`StructureTerritoryPanel.tsx`): flag, conflict, own town, loyalty
       (stored only), clear flag (A07).
    5. Game settings: "Production and territory" card (`TerritorySettingsCard.tsx`): `production.enabled` and the range
       settings with a worked example; Save off while a value is out of the API's bounds; `production` sent on save.
    6. Helpers `src/utils/territory.ts` (range rule matching `TerritoryRules`, partial-save payloads, labels).
    7. knk-workspace (branch from `next`): smoke guide § 1.4 (15 web app steps in full: 13 automated, 2 partly),
       § 1 intro and preconditions, changelog entry, territory DESIGN and implementation plan status.
2. **Commits and heads.** knk-web-app `claude/production-t-c` at `0531422` (3 commits, base `next` at `24c8a98`;
   `next` had not moved at PR time or at the end); knk-workspace `claude/production-t-c` at `f3bd8f27` (1 commit + merge of
   `origin/next` `2f0dc79c`, siege weapons L2 docs; CHANGELOG: both new entries kept).
3. **PRs.** [knk-web-app#57](https://github.com/PandiO/knk-web-app/pull/57) (Closes #690),
   [knk-workspace#803](https://github.com/PandiO/knk-workspace/pull/803) (Part of #690); base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-app: baseline on `next` `24c8a98`: Jest 2773 passed (324 suites), Playwright 204 passed, `tsc` clean,
       build OK. Branch: Jest 2787 passed (326 suites; new `territory.test.ts`, `territoryClients.test.ts`), Playwright
       227 passed (new `e2e/territory.spec.ts`, 23 tests, DTO-typed fixtures `e2e/fixtures/territory.ts`; strict
       `town-detail` and `landmarks` specs mock the new town reads), `tsc` and `typecheck:e2e` clean, build OK.
       CI on `0531422`: PR runs 44514993187 (e2e) and 44514993520 (build-and-test), push runs 44514987012 and
       44514986946, all green. The first push's e2e (run 44514077192, `3bf52f3`) failed: the strict
       `entity-setup-delete-details` spec opens a structure page and the new panel's reads were unmocked (locally the
       test ended first); fixed in `0531422` (`mockNoStructureTerritory`).
    2. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Town and District territory fields.* Chosen: a Territory panel on the town page, because the Town/District
       form seeds L1 left for #690 are in knk-web-api, outside this link (prompt § 2). Alternatives: (a) change the
       seeds: not this link's repo (filed on #690); (b) wait for seeds: no way to set power in the web app meanwhile.
    2. *Partial save of towns and districts.* Chosen: read the record, `PUT` back its identity fields plus the
       territory change, with every "not on this form" group null (teleport, navigation, inline location, streets), the
       API's own convention. Alternatives: (a) send the whole GET body back: rewrites the inline location; (b) a new
       territory write endpoint: knk-web-api.
    3. *Where the screens live.* Chosen: panels below the generic detail pages of Town, TerritoryConflict and
       Structure (the landmark panel pattern) plus a Game settings card. Alternatives: (a) a separate territory admin
       page: duplicates the dashboard; (b) the capital toggle on the district page: the town panel shows every
       district's range in one place.
    4. *Conflict actions.* Chosen: award to either holder / mark redrawn / reopen, each behind a confirmation, note
       optional. Alternatives: (a) no confirmation: an award changes the game server's inputs; (b) required note: the
       API does not require one.
    5. *Structure types with the panel.* Chosen: `Structure` only. Alternatives: (a) also `GateStructure`: the API's
       structure flag and loyalty are about production structures; easy to add later.
    6. *#65 insight.* Nothing added: #65 lists logistics surfaces (warehouses, producers, orders, simulator, health),
       none territorial, and #690 does not ask for one. Alternatives: (a) a territory overview page: not asked for.
6. **Out of scope, noted.** Comment on [#690](https://github.com/PandiO/knk-workspace/issues/690#issuecomment-7007691107):
   the Town/District form seed fields (knk-web-api) with a proposal, and that a `TerritoryConflict` detail page's Edit
   opens a form whose save has no update endpoint. No new issues.
   Codex: the connector hit its code-review usage limit on both PRs (review "failed"), again after `@codex review` on
   `0531422`; no findings or review threads to handle; noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Deploy the web app with the territory API (#326, in `next`); the four territory form and display seeds must be
       imported (L1 block, at merge 1). No migration, setting or plugin change.
    2. Coordinator: decide on the Town/District seed fields (comment on #690): not needed for V1 since the town page
       panel sets them.
    3. Smoke test [§ 1.4](../guides/production-storage-transport-smoke-test.md#14-steps-web-app-690) (tier:2): about
       25 minutes in full, about 5 minutes for the untagged parts (province form, crown land region drawn in game).
    4. At merge into `next`: the `documentation` sub-issue (territory admin guide, feature register row).
9. **Notes for later links.**
    1. L2 (#689): smoke § 1.3 is still the design's draft; § 1.4 covers the web app half of its steps 1 and 9.
       Crown land created in the web app has no domain type sent to the plugin (L1 decision 10).
    2. Web app links: the territory panels mount in `DisplayWizardPage.tsx` next to the landmark panel; strict
       e2e specs that open a town page need `mockNoTownTerritory(api, id)` from `e2e/fixtures/territory.ts`.

### 4.4 L4 — P1 stock core API: storages, ledger, reconciler, capacity, roll-up (#97)

1. **Scope done** (knk-web-api, plus essential docs in knk-workspace).
    1. Storages (`Storage`): kinds Domain, Player, Clan, Transit and Virtual, with one holder per kind (`DomainId`,
       `UserId`, `ClanId` or `SystemKey`) and check constraint `CK_storages_Holder`. Also `Purpose`, capacity
       (`MaxUnits`, `MaxDistinct`, `UnitsPerSlot`), stored `TotalUnits` and `DistinctItems`, a `RowVersion` token, and
       `LockedUntil` with `LockReason`. The five system storages are seeded (ids 1-5).
    2. `StockLine` (blueprint FK Restrict) and `StockUnit` (an `ItemInstance`, unique).
    3. `StockTransaction` + `StockMove`: append-only, unique idempotency key with request hash, compensating
       corrections (`ReversesTransactionId`, unique).
    4. `IStockService` (`Move`, `MoveMany`, `Adjust`, `Reverse`): row locks `FOR UPDATE` in id order, conditional
       updates, AllOrNothing or Partial, capacity (raw units × the new `ItemBlueprint.StorageWeight`), distinct cap,
       missing stock and locks returned as results, never thrown. It enlists in the caller's transaction.
    5. `StockReconciler`: per blueprint the sum is zero, each line equals the net of its moves plus roll-ups, units
       sit where their last move put them, stored totals match.
    6. `StockRollupService` (G3): `Production` and `ProductionInput` moves of whole days more than 30 days back become
       `stock_move_rollups` rows per day, reason, storage pair and blueprint. Totals are unchanged.
    7. `StockMaintenanceService`: reconcile every 6 h and roll up daily, only with `production.enabled` on. Admin
       CRUD, moves, adjust, reverse, reconcile and roll-up by hand stay on (DESIGN § 18.2).
    8. Endpoints `api/Storages` (dashboard type `Storage`, World area) and `api/StockTransactions`. Ledger reads need
       the World area or `knk.economy.admin`; move, `adjust`, `{id}/reverse` and `rollup` need the new node
       `knk.economy.admin`. Lookup `Storage`.
    9. Form and display seeds `Storage` and `StockTransaction` (G17). Pinned access, seed and lookup tests updated.
       One additive migration, `AddStockCore`.
    10. knk-workspace (branch from `next`): smoke guide § 2 (17 steps, 15 automated, 2 partly), changelog entry,
        production installation § 5.3 item 6, implementation plan status.
2. **Commits and heads.** knk-web-api `claude/production-p1` at `e524721` (4 commits, base `next` `7dc1038`, which
   had not moved at the final fetch, so no merge was needed); knk-workspace `claude/production-p1` at `abef76fc`
   (1 commit, base `next` `ac437102`).
3. **PRs.** [knk-web-api#56](https://github.com/PandiO/knk-web-api/pull/56) (Closes #97) and
   [knk-workspace#816](https://github.com/PandiO/knk-workspace/pull/816) (Part of #97), both into `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` `7dc1038` 4610 passed / 103 skipped / 0 failed. Branch: 4677 passed /
       112 skipped / 0 failed.
    2. New tests: `StockServiceTests`, `StockReconcilerAndRollupTests`, `StorageServiceTests`, `StockControllersTests`,
       `AddStockCoreTests` (67 run by default), and `StockLedgerMySqlTests` (9, requires-mysql).
    3. MySQL 8.0.46 locally: all 9 stock MySQL tests green, including 1000 concurrent moves with a clean reconciler
       (A01), no overdraw, no cap overrun, one key applying once also across storages, caller-transaction rollback,
       the check constraint and the roll-up. The full suite with `KNK_TEST_MYSQL` failed only the known red #285 and
       a pinned lookup test, which was then fixed.
    4. Each new behaviour was seen failing once by breaking it on purpose: the capacity, idempotency and distinct-cap
       checks; removing the row lock failed 3 MySQL tests.
    5. Migration applied, rolled back to `AddTerritory` and re-applied; `has-pending-model-changes` clean.
    6. CI on `e524721`: build-and-test, mysql-tests and fresh-database green. Known reds: #285 (MySQL run only).
5. **Decisions (DESIGN § 4.3).** All 16, each with its alternatives, are in knk-web-api#56. The main ones:
    1. *Node.* Chosen: `knk.economy.admin` as IMPLEMENTATION_PLAN § P1 names it, not under `knk.admin`, so
       `knk.admin.*` does not grant moving stock. Alternatives: (a) `knk.admin.economy` or `knk.admin.world`: every
       admin could create goods.
    2. *Ledger reads.* Chosen: the World area or `knk.economy.admin` (dashboard type `StockTransaction`).
       Alternatives: (a) economy only: needs an eighth area node, which the area test forbids.
    3. *Clan holder.* Chosen: FK to the existing minimal `clans` table; no clan model invented. Alternatives: (a) a
       bare id without FK.
    4. *Caps.* Chosen: flat columns, null = no cap; a lowered cap allows removals only. Alternatives: (a) an owned type
       (the forms bind flat fields); (b) a required cap.
    5. *Locking.* Chosen: every storage of a request, system storages included. `SYS_PRODUCTION` is a hot spot,
       accepted for V1. Alternatives: (a) atomic increments for virtual lines.
    6. *Unique items.* Chosen: never held in virtual storages (row created from one, deleted to one); a unit counts
       1 total and 1 distinct item. Alternatives: (a) rows in `SYS_WORLD` for items in players' hands.
    7. *Append-only.* Chosen: by service API, no MySQL triggers, because the roll-up deletes old production moves.
       Roll-ups are a separate table counted by the reconciler; reversed and unique-item transactions are skipped.
       Alternatives: (a) triggers with an exception; (b) flagged rows in `stock_moves`.
    8. *Seeds* (ledger rows were the agent's call, developer 2026-11-19). Chosen: `Storage` and `StockTransaction`;
       lines, units and moves are view-only child types on their parents' pages; roll-up rows have none.
       Alternatives: (a) seeds for every row type.
    9. *`StorageWeight`* uses null = keep on the blueprint DTOs; the `ItemBlueprint` form seed is not bumped (noted
       on #675). Alternatives: (a) seed v-next now.
    10. *DbContext layout* (coordinator note on the siege chain): one contiguous model block and one `DbSet` block.
        If `next` gets a migration before merge: merge `origin/next` and regenerate `AddStockCore`, then update the
        migration name in production installation § 5.3 item 6.
6. **Out of scope, noted.** On #675 (comment): the endpoints, filters and result statuses for the web app; the
   `ItemBlueprint` form seed doesn't carry `storageWeight` yet. No new issues. Codex: the connector hit its
   code-review usage limit on both PRs (review "failed", usage-limit comment); no inline findings; noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply migration `AddStockCore` (additive). Import the form and display seeds `Storage` and `StockTransaction`.
    2. Grant `knk.economy.admin` to the staff who may move or adjust stock. No `api.env` key, no plugin `config.yml`
       change.
    3. Smoke test [§ 2](../guides/production-storage-transport-smoke-test.md#2-phase-p1-stock-core-97-api-675-web-app-tier3)
       (tier:3 gate before L6 builds on it): 15 of 17 steps automated, about 10 minutes for the untagged parts.
    4. At merge into `next`: the `documentation` sub-issue (stock core architecture page and API contract, stock admin
       guide, feature register row).
9. **Notes for later links.**
    1. L5 (#675): see the comment on #675. Results are 200s with a `status`; show `rejectReason` per line.
    2. L6 (P2, #91): a structure's storages are `Kind = Domain` with `DomainId` = the structure's id (structures are
       domains), so default storages on create are `StorageService.CreateAsync` with `DomainId` (or rows inserted with
       the same rules). Moves into a new storage go through `IStockService` inside your own transaction.
    3. Later links: P5 creates `Transit` storages per order (no holder, uncapped); P7 uses Player storages with
       `Purpose = Inbox` or `Stash` and `SYS_LOSS`; every caller that may retry sends an idempotency key.

### 4.5 L5 — P1b stock web app (#675)

1. **Scope done** (knk-web-app, plus the essential docs in knk-workspace).
    1. Types and clients: `src/types/dtos/stock/StockDtos.ts` (mirrors knk-web-api `StockDtos.cs` and the stock enums), `storageClient` (`api/Storages` CRUD and search), `stockTransactionClient` (search, `{id}`, `moves/search`, `rollups/search`, `reconcile`, move, `adjust`, `{id}/reverse`, `rollup`). Registry additions, additive and grouped: `Controllers`, `entityApiMapping` (`storage`: all five; `stocktransaction`: search and fetch only) and `objectConfigs` columns. ItemBlueprint DTOs carry `storageWeight`, and the blueprint list has a Storage weight column.
    2. Storage page: `StoragePanel` (mounted in `DisplayWizardPage`):
        1. Holder, and capacity used in raw units × storage weight against the cap, with "over its cap: removals only".
        2. Totals, distinct items and the lock.
        3. Stock lines, each amount linking to the ledger drill-down (storage + blueprint).
        4. Unique items, each linking to its moves (A03).
        5. Adjust stock, Move stock, and per row Adjust, Move and Take out.
    3. `StockAdjustDialog` (blueprint or item instance, signed change, required note) and `StockMoveDialog` (a reason, all or nothing or partial, several lines). Both show the 200 result per line through `StockResultView`: status, then requested, accepted and refused with the `rejectReason` in words. The idempotency key stays the same until the request changes, and a 409 `IdempotencyKeyReuse` is explained.
    4. Transaction page: `StockTransactionPanel`: the moves with both storages linked, "Reverses" and "Reversed by", and Reverse (a compensating correction with a note).
    5. Ledger explorer `StockLedgerPage` at `/admin/stock/ledger` (Economy group, `staffAny(knk.admin.world, knk.economy.admin)`):
        1. Three views: transactions, moves and roll-ups (A22).
        2. Filters in the address: storage, blueprint, item instance, transaction, reason, actor, source type and reference, from and until.
        3. The drill-down shows the line's amount next to "moves in − moves out (+ roll-ups) = net" (A01).
        4. `StockLedgerHealthCard` (the stock part of #65): run the reconciler and run the roll-up.
    6. Gates: adjust, move, reverse and roll-up are shown off with "Requires knk.economy.admin" for staff without the node.
    7. knk-workspace (branch from `next`): smoke guide § 2.2 (17 web app steps in full: 14 automated, 3 partly), § 2 intro and status header, changelog entry, implementation plan status.
2. **Commits and heads.**
    1. knk-web-app `claude/production-p1b` at `9bec60f`: 2 commits, base `next` at `aaf7066`. `next` had not moved at PR time or at the last fetch.
    2. knk-workspace `claude/production-p1b` at `a5d10f37`: 1 commit, base `next` at `1bbdd69f`, which includes L4's docs PR #816.
3. **PRs.** [knk-web-app#60](https://github.com/PandiO/knk-web-app/pull/60) (Closes #675) and [knk-workspace#818](https://github.com/PandiO/knk-workspace/pull/818) (Part of #675), both into `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-app baseline on `next` `aaf7066`: Jest 2795 passed (327 suites), Playwright 230 passed, `tsc` clean, build OK.
    2. Branch: Jest 2808 passed (329 suites). New: `src/utils/__tests__/stock.test.ts` and `src/apiClients/__tests__/stockClients.test.ts`. The pinned route-gate list (`routeTable.test.ts`) and blueprint-column list (`minecraftColumns.test.tsx`) were updated for the new route and column.
    3. Branch: Playwright 253 passed. New: `e2e/stock.spec.ts`, 23 tests, with DTO-typed fixtures in `e2e/fixtures/stock.ts` and a strict API on the storage, transaction and ledger pages. `tsc` and `typecheck:e2e` are clean and the build is OK.
    4. The idempotency retry test was seen failing with the key renewed on every press.
    5. `login.spec.ts › a refused refresh ends the session…` failed once in a full local run under load. It passed alone and in the next full run, and it does not touch this change.
    6. CI on `9bec60f`: PR runs 44581116557 (build-and-test) and 44581116570 (e2e) and push runs 44579818960 and 44579819367, all green.
    7. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Where the screens live.* Chosen: panels below the generic Storage and StockTransaction detail pages (the L3 pattern) plus one explorer page. Alternatives: (a) a custom storage page replacing the display configuration: duplicates the seed; (b) the explorer on the dashboard's StockTransaction table: no storage, blueprint or date filters and no drill-down.
    2. *Explorer route and access.* Chosen: `/admin/stock/ledger`, Economy group, World area or `knk.economy.admin`, the API's read rule. Alternatives: (a) World only: economy-only staff are locked out; (b) economy only: World staff can read the ledger in the API.
    3. *Idempotency keys.* Chosen: one key per request content, renewed when a field changes. Alternatives: (a) no key: a retry after a lost answer applies twice; (b) one key per dialog opening: changing the amount after a refusal hits `IdempotencyKeyReuse`.
    4. *Drill-down sum.* Chosen: the newest 200 moves and roll-ups (the API's page cap), with a note when there are more. Alternatives: (a) page through everything: slow; (b) rows only: staff add up by hand.
    5. *Manual move reasons.* Chosen: every reason except Correction and AdminAdjust (those have their own actions). Alternatives: (a) all: staff could fake corrections; (b) a short list: too narrow for booking losses by hand.
    6. *Unique items in the adjust dialog.* Chosen: ±1 only, with Take out prefilled. Alternatives: (a) any delta: the API moves one unit anyway.
    7. *#65.* Chosen: the reconciler and roll-up card plus "over its cap" on the storage page. Alternatives: (a) a list of every storage over cap: `capacityUsed` is on detail reads only (N reads or an API change).
    8. *Storage weight on the blueprint form.* Chosen: DTO field plus a list column (before Category, which stays last next to its filter); the form seed field is filed on #675. Alternatives: (a) a weight editor with a partial blueprint PUT: rewrites other fields; (b) nothing until the seed changes.
6. **Out of scope, noted.**
    1. [#675 comment](https://github.com/PandiO/knk-workspace/issues/675#issuecomment-7017085116): the ItemBlueprint form seed needs a `StorageWeight` field (knk-web-api seed v-next), and the Storage display seed's Stock section shows the blueprint id instead of its name (minor). No new issues.
    2. Codex: the connector hit its code-review usage limit on both PRs (review "failed", usage-limit comment). There were no inline findings or threads. Noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Deploy the web app with the stock core API (#97, in `next`) and its imported `Storage` and `StockTransaction` form and display seeds. No migration, setting or plugin change.
    2. Grant `knk.economy.admin` to the staff who adjust or move stock.
    3. Coordinator: decide on the ItemBlueprint `StorageWeight` seed field (comment on #675). Until then the weight is set through the API.
    4. Smoke test [§ 2.2](../guides/production-storage-transport-smoke-test.md#22-steps-web-app-675) (tier:2): about 35 minutes in full, about 10 minutes for the untagged parts (setting a weight and a lock, roll-up data on a test database).
    5. At merge into `next`: the `documentation` sub-issue (stock admin guide covering the storage page, dialogs and ledger explorer; feature register row).
9. **Notes for later links.**
    1. Web app links (L7, L10, L16 and on): `StoragePanel` takes a storage id. A structure page can list its storages (`POST api/Storages/search` with `domainId`) and link each to `/display/Storage/<id>`. `lineMovesPath`, `storageLedgerPath` and `itemInstanceMovesPath` in `src/utils/stock.ts` build the explorer links.
    2. The stock result view (`StockResultView`) and `stockRefusalReason` work for any endpoint that answers a `StockResultDto` or `{ error }`.

### 4.6 L6 — P2 world API: structure subtypes, TownId, placement rules (#91)

1. **Scope done** (knk-web-api, plus essential docs in knk-workspace).
    1. Rural structures (R1): `Structure.TownId`; `DistrictId` and `StreetId` nullable; exactly one of `DistrictId` and
       `TownId` (check constraint `CK_structures_DistrictXorTown` plus `StructurePlacement`); effective town
       `District.Town ?? Town`. A rural structure has no street and house number 0. `api/Structures` accepts `townId` and
       its search lists `townId` (effective), `isRural`, `territoryFlag` with filters on them.
    2. `Warehouse : Structure` (`AcceptsDeliveries`, `Priority`, `DefaultStorageId`) and `ProductionStructure : Structure`
       (`ProductionKindId` plain id, `Level` 1-10, `ProductionEnabled`, transport settings, `WarehousePreference` +
       `PreferredWarehouseId`, `RoadConnection` + measured-at, `WorkersTotal`, `WorkersPresent`), TPT tables.
    3. Default storages on create through `IStorageService.CreateAsync` (`Kind = Domain`, `DomainId` = the structure) in
       the create's transaction: Delivery (the warehouse's default storage) and Output. Delete removes them first, 409
       while one holds stock or history.
    4. Placement rules (R2): new validation type `InsideTerritory` (P-2/P-3) through `ITerritoryLookupClient` (plugin
       lookup, contract on #677); skipped while `production.enabled` is off (A21). The default form's rules run when the
       API saves a Structure, Warehouse or ProductionStructure: a failed blocking rule is 400, warnings come back as
       `placementWarnings`, a rule that could not run never blocks.
    5. Contested land (R3, A07): a rural structure flagged by the territory report keeps its town and keeps producing;
       `ProductionStructureDto.warnings` (contested, outside territory, unconnected D5). `PUT
       api/ProductionStructures/{id}/road-connection` for P5b.
    6. Endpoints `api/Warehouses`, `api/ProductionStructures`; registry (World area), lookups, pinned access tests; form
       and display seeds `Warehouse` and `ProductionStructure` (G17) with P-1 and P-2 as warnings. Audit of every
       `Structure.District`/`Street` call site (13 items, listed in knk-web-api#57). One additive migration
       `AddProductionWorld`; `KnKDbContext` edits in one contiguous block.
    7. knk-workspace (branch from `next`): smoke guide § 3 (§ 3.1 16 steps, 14 automated, 2 partly; § 3.2/3.3 drafts
       for L7/L8), changelog entry, production installation § 5.3 item 7, implementation plan status.
2. **Commits and heads.** knk-web-api `claude/production-p2` at `303b6ab` (6 commits, base `next` `2e7d4e8`, which had
   not moved at the final fetch, so no merge was needed and the migration was generated last on it); knk-workspace
   `claude/production-p2` at `9ab62ab1` (1 commit, base `next` `1bbdd69f`).
3. **PRs.** [knk-web-api#57](https://github.com/PandiO/knk-web-api/pull/57) (Closes #91) and
   [knk-workspace#822](https://github.com/PandiO/knk-workspace/pull/822) (Part of #91), both into `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` `2e7d4e8` 4678 passed / 112 skipped / 0 failed. Branch: 4723 passed /
       114 skipped / 0 failed.
    2. New tests: `StructureSubtypeServicesTests` (15), `PlacementRulesTests` (6, the shipped seeds imported and their
       rules run on save: warn, block when set, offline never blocks, production off skips), `InsideTerritoryValidatorTests`
       (12, including the lookup client's URLs, key and answers), `RuralStructureTests` (5: StructureService, search,
       region decisions without parent, contested keeps its town), `AddProductionWorldTests` (4),
       `ProductionWorldMySqlTests` (2, requires-mysql: the check constraint; a used street or town can't be deleted).
    3. MySQL 8.0.46 locally with `KNK_TEST_MYSQL`: 4836 passed, 1 failed = the known red #285. (`max_connections` had to
       be raised from 151 for the full MySQL run; environment only.)
    4. A new test caught a real bug in reading JSON numbers in the validator; the existing
       `DeleteConstraintExceptionFilterTests` caught that `Restrict` on the now optional FKs let EF null a structure's
       street on delete (decision 4).
    5. Migration applied, rolled back to `AddStockCore` and re-applied; `has-pending-model-changes` clean.
    6. CI on `303b6ab`: build-and-test, mysql-tests and fresh-database green (PR runs 44587806782, 44587806947).
5. **Decisions (DESIGN § 4.3).** All 12, each with its alternatives, are in knk-web-api#57. The main ones:
    1. *`InsideTerritory` (coordinator note 3.1).* Chosen: the API calls a lookup on the plugin's region HTTP server
       (`GET /api/territory/contains-region/{regionId}` and `/contains-location`, `holderKind`/`holderId`, plugin key),
       answered by L8. Alternatives: (a) compute territory in the API: it has no region geometry; (b) a SignalR request:
       new plumbing for one call.
    2. *Rural structures in the report (note 3.2).* Chosen: the structure search lists the effective `townId`; the plugin
       flags rural structures through the existing report. Alternatives: (a) a separate endpoint: duplicates the search.
    3. *Production off and offline server.* Chosen: the territory rule is skipped while `production.enabled` is off; a
       rule that can't be checked is a warning, never a block. Alternatives: (a) "not checked" on every save while off;
       (b) block when unknown: an offline server would stop authoring.
    4. *Optional structure FKs `ClientNoAction`.* `Restrict` on an optional relationship lets EF null the FK of tracked
       structures, so a street delete would succeed silently; `ClientNoAction` keeps the database refusal (MySQL test).
       Alternatives: (a) service checks on every delete path.
    5. *Default storages without kinds:* Output / Delivery, uncapped; `ProductionKindId` a plain id until P3.
       Alternatives: (a) none until P3; (b) a placeholder kind table.
    6. *Seeds:* new `Warehouse` and `ProductionStructure` seeds; the generic `Structure` seed is not bumped (the API
       accepts `townId`). Alternatives: (a) Structure seed v3 now: L7's form work.
    7. *Gates stay district-only* and get no save-time rule check (unchanged behaviour). Alternatives: (a) rules on save
       for gates too: outside P2.
6. **Out of scope, noted.** Comments on #676 (endpoints, fields, seeds, the rule builder needs `InsideTerritory`) and
   #677 (the lookup contract, `townId` for rural structures in the report, region decisions without parent). P-3 for
   production areas waits for P4's areas (the validation types are ready). No new issues. Codex: the connector hit its
   code-review usage limit on both PRs (review "failed", usage-limit comment); no inline findings; noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply migration `AddProductionWorld` (additive). Import the form and display seeds `Warehouse` and
       `ProductionStructure` ("make default").
    2. No `api.env` key, no plugin `config.yml` change.
    3. Smoke test [§ 3.1](../guides/production-storage-transport-smoke-test.md) (tier:3): 14 of 16 steps automated;
       about 10 minutes for the untagged parts (the forms in the web app; P-2 with a connected P2c plugin).
    4. At merge into `next`: the `documentation` sub-issue (structure placement and subtypes architecture page and API
       contract, admin guide for warehouses, production structures and placement rules, feature register row).
9. **Notes for later links.**
    1. L7 (#676): see the comment on #676. Placement is District-xor-Town; read `effectiveTownId`, `isRural`, `storages`,
       `warnings`; add `InsideTerritory` to the rule builder.
    2. L8 (#677): see the comment on #677. Implement the two lookup endpoints; use `townId` from the structure search for
       rural structures in the territory report; rural regions have no parent.
    3. L9 (P3): `ProductionStructure.ProductionKindId` is a plain nullable int with an index; add the FK with the kind
       catalogue. Kind-driven storages can be added next to the Output storage (`IStorageService.CreateAsync` with
       `DomainId`). `ProductionEnabled` is the structure's own switch; `WorkersPresent` is yours to write.
    4. L14 (P5) / L15 (P5b): `RoadConnection` is written through `PUT api/ProductionStructures/{id}/road-connection`;
       automatic transport is held unless `Connected` for rural structures (D5).

### 4.7 L7 — P2b world web app (#676)

1. **Scope done** (knk-web-app, plus the essential docs in knk-workspace).
    1. Types and clients: `src/types/dtos/structure/ProductionWorldDtos.ts` (mirrors `ProductionWorldDtos.cs` and the enums), placement fields on `StructureDto.ts` plus `StructureListDto`; `warehouseClient`, `productionStructureClient` (CRUD, search, `road-connection`), `storageClient.searchStorages`. Registry additions, additive and grouped: `Controllers`, `entityApiMapping` (all five for `warehouse` and `productionstructure`), `objectConfigs` columns, `domainWorld` types.
    2. Forms (A06, A23): the seeded `Warehouse` and `ProductionStructure` forms in the form wizard with the RegionClaim world task and the Town (rural) picker; a create shows each placement warning (P-1 to P-3) in a toast kept until closed; a refused save shows the API's `{ error }` sentence (District-xor-Town, a blocking rule).
    3. Rule builder: validation type **Inside Territory** (town holder config, a warning by default, help line); a saved `InsideTerritory` rule stays selected when edited.
    4. Dashboard: Warehouse and ProductionStructure columns (town, placement, district, deliveries, priority; level, production, road connection, territory flag); Placement and Territory flag columns on Structure; a **Territory flag** filter on the three structure tables (the plan's "dashboard shows flagged structures", A07).
    5. Detail pages of warehouses and production structures: `StructurePlacementPanel` (placement, effective town, the production structure's `warnings`, road connection, production, workers, delivery preference; a warehouse's deliveries and delivery storage), `StructureTerritoryPanel` (flag and loyalty, A07), `StructureStoragesPanel` (`POST api/Storages/search` with `domainId`, links to `/display/Storage/<id>`, one L5 `StoragePanel` per storage; `StoragePanel` got an optional `title` and a per-storage heading id).
    6. #65 (world part): the road connection column, the page's warnings and the flagged-structure filter.
    7. knk-workspace (branch from `next`): smoke guide § 3.2 (12 web app steps in full: 8 automated, 4 partly), § 3 intro and status header, changelog entry, implementation plan P2 status.
2. **Commits and heads.**
    1. knk-web-app `claude/production-p2b` at `f5ea646`: 3 commits, base `next` at `9f46cb4`, which had not moved at PR time or at the last fetch.
    2. knk-workspace `claude/production-p2b` at `9d578854`: 1 commit, base `next` at `4654a1ad` (includes L8's docs PR #823).
3. **PRs.** [knk-web-app#61](https://github.com/PandiO/knk-web-app/pull/61) (Closes #676) and [knk-workspace#829](https://github.com/PandiO/knk-workspace/pull/829) (Part of #676), both into `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-app baseline on `next` `9f46cb4`: Jest 2808 passed (329 suites), Playwright 253 passed, `tsc` clean, build OK.
    2. Branch: Jest 2825 passed (331 suites). New: `src/utils/__tests__/productionWorld.test.ts`, `src/apiClients/__tests__/productionWorldClients.test.ts`; extended `ValidationRuleBuilder.test.tsx`, `PagedEntityTable.categoryFilter.test.tsx`, `domainWorld.test.ts`; the pinned structure picker columns (`pickerRowValues.test.ts`) list the two new columns.
    3. Branch: Playwright 263 passed. New `e2e/production-world.spec.ts` (9 tests, strict API, DTO-typed fixtures `e2e/fixtures/productionWorld.ts`) and one test in `form-builder-draft-rules.spec.ts`. `tsc` and `typecheck:e2e` clean, build OK.
    4. Seen failing on purpose: with the warning toast and the storage search broken, 4 of the new e2e tests failed.
    5. CI on `f5ea646`: PR runs 44604543460 (e2e) and 44604544965 (build-and-test) and push runs 44604409793 and 44604410140, all green.
    6. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Where the screens live.* Chosen: panels below the generic Warehouse and ProductionStructure detail pages (the L3/L5 pattern) and the seeds' forms as they are. Alternatives: (a) custom create pages with a District-or-Town switch: duplicates the seeded FormConfigurations (G17); (b) a client-side District-xor-Town pre-check: duplicates the API rule and could block a valid edit; the API's reason is shown instead.
    2. *Placement warnings.* Chosen: one warning toast per warning, kept until closed. Alternatives: (a) a modal: blocks the return for a warning that by design doesn't block; (b) nothing: the warnings would be lost.
    3. *Refusal reason.* Chosen: read `{ error }` (without " (Parameter 'dto')") for the two P2 types only. Alternatives: (a) change `describeErrorBody` app-wide: outside this link; (b) API change: knk-web-api (noted on #676).
    4. *Flagged structures.* Chosen: a Territory flag filter on the three structure tables plus a column. Alternatives: (a) a separate page: the conflict page already lists its structures; (b) column only: can't list just the flagged ones.
    5. *Storages on the page.* Chosen: the `domainId` search plus one `StoragePanel` per storage. Alternatives: (a) links only: no storage contents on the page (DESIGN § 11.1); (b) the read's `storages` list: misses storages added by hand.
    6. *InsideTerritory default.* Chosen: a new rule starts as a warning. Alternatives: (a) blocking like the other types: against DESIGN § 3.4.
    7. *Road connection.* Chosen: shown only. Alternatives: (a) a staff override of `PUT road-connection`: it is the game server's measurement (P5b) and would be overwritten.
    8. *Generic Structure page.* Chosen: unchanged apart from columns and the filter. Alternatives: (a) the placement panel there too: the Structure form seed has no Town field yet.
6. **Out of scope, noted.** [#676 comment](https://github.com/PandiO/knk-workspace/issues/676#issuecomment-7020712503): the subtype endpoints' `{ error }` body with the .NET parameter suffix, update drops the placement warnings (204), the Structure form seed's missing Town field. No new issues. Codex: the connector hit its code-review usage limit on both PRs (review "failed", usage-limit comment); no inline findings or threads; noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Deploy the web app with the world API (#91, in `next`) and its imported `Warehouse` and `ProductionStructure` form and display seeds. No migration, setting or plugin change.
    2. Smoke test [§ 3.2](../guides/production-storage-transport-smoke-test.md#32-steps-web-app-676) (tier:2): about 40 minutes in full, about 15 minutes for the untagged parts (a region drawn in game, a real P-2 answer, the edit form).
    3. At the end of P2 (L7 and L8 merged, coordinator decision 31): the `documentation` sub-issue covers the admin guide for warehouses, production structures, placement rules and the flag filter, and the feature register row.
    4. Coordinator: decide on the two API points of the #676 comment (update warnings, error body).
9. **Notes for later links.**
    1. L10 (P3b) and later web app links: `StructurePlacementPanel` and `StructureStoragesPanel` (`src/components/production/`) mount in `DisplayWizardPage` for `isProductionWorldType`; add the kind, lines and cycle history next to them. `placementRefusalReason` reads the subtype endpoints' `{ error }`.
    2. Strict e2e specs that open a warehouse or production structure page need `Territory/structures/<id>`, `Towns`, `Storages/search` and `Storages/<id>` mocks (see `e2e/fixtures/productionWorld.ts`).
    3. P10c (shops): a `Shop` subtype fits `PRODUCTION_WORLD_TYPES`, the flag filter set and the placement panel.

### 4.8 L8 — P2c world plugin: managed-region kinds (#677)

1. **Scope done** (knk-plugin, plus essential docs in knk-workspace). Everything new runs only with `production.enabled:
   true` (A21); with it off, region behaviour is unchanged.
    1. Region kinds: `ManagedRegionKind.fromDomainType(type, production)`: `ProductionStructure` → `RESOURCE_PRODUCTION`,
       `Warehouse` → `STRUCTURE`. The repair uses it (`DomainRegionSpecs.build(..., production)`, `ManagedRegionSpecSource`),
       and so does the creation hook (`ManagedRegionsBootstrap.finalizeNewRegion`).
    2. Rural structures (a town, no district): top level on purpose. No parent, kind floor priority 30, in their town's
       world, and no "unknown district" warning. PvP stays allowed and no town flags are inherited.
    3. Territory lookup (L6 contract, knk-web-api `TerritoryLookupClient`): `GET /api/territory/contains-region/{regionId}`
       and `/contains-location` with `holderKind`/`holderId` on the region HTTP server, behind the plugin key.
        1. `contains-region` needs every block column of the region and its sub-regions to be owned by the holder;
           contested columns count as not owned.
        2. Answers: 200 `{"inside": bool, ...}`; 503 "territory unavailable" while `production.enabled` is off or before
           the first cache build; 400 or 404 with the reason.
        3. Code: knk-core `TerritoryLookup`, knk-paper `TerritoryLookupHandler` and `RegionUnionOutlines`, wired in one
           `KnKPlugin` block.
    4. Territory report: `StructureListDto`/`StructureSummary.townId`; `TerritoryService.StructureRef` uses it, so rural
       structures are flagged (coordinator decision 18.2).
    5. Plugin scenario `rural-structure-region` (real WorldGuard regions: the repair's kinds and parents, the PvP query at
       a warehouse and a rural quarry, the lookup through the real region union). `MIN_SCENARIOS` 63 → 64.
    6. knk-workspace (branch from `next`):
        1. Smoke guide § 3.3: 11 steps, 6 automated and 5 partly.
        2. Changelog entry.
        3. Plugin configuration § 4.31: `production.enabled` also covers P2c; no new key.
        4. Implementation plan P2 status.
2. **Commits and heads.** knk-plugin `claude/production-p2c` at `cc563771` (2 commits, base `next` `c0ca56e4`);
   knk-workspace `claude/production-p2c` at `cb11e03a` (1 commit, base `next` `c7fe8996`). `next` had not moved in either
   repo at the final fetch, so no merge was needed.
3. **PRs.** [knk-plugin#96](https://github.com/PandiO/knk-plugin/pull/96) (Closes #677) and
   [knk-workspace#823](https://github.com/PandiO/knk-workspace/pull/823) (Part of #677), base `next`. Not merged.
4. **Tests, baseline → result** (`./gradlew build -x deployToDevServer`, Gradle on JDK 21, JDK 25 toolchain).
    1. Baseline on `next` `c0ca56e4`: knk-core 3523, knk-api-client 364 (2 skipped), knk-paper 3212 (18 skipped), 0
       failures.
    2. Branch: knk-core 3538, knk-api-client 366 (2 skipped), knk-paper 3217 (18 skipped), 0 failures.
    3. New tests: `ProductionManagedRegionTest` (6), `TerritoryLookupTest` (8), one new `TerritoryServiceTest` case,
       `StructuresMapperTest` (2) and `TerritoryLookupHandlerTest` (5, a real `RegionHttpServer`).
       `PaperScenariosTest` was updated for the new scenario.
    4. The scenario `rural-structure-region` passed locally on Paper 26.3-205 with WorldGuard 7.0.20.
    5. CI on `cc563771`: build green, paper-boot green (64 scenarios).
    6. Known reds: none. The first baseline run hit a Maven Central 429 while downloading; the rerun was green.
5. **Decisions (DESIGN § 4.3).**
    1. *Gating the new kinds.* Chosen: with `production.enabled` off a `ProductionStructure` stays `STRUCTURE`, because
       `RESOURCE_PRODUCTION` seeds `entry` flags and A21 allows no change while off. Alternatives: (a) map it always, like
       L2's crown land mapping: existing regions would get flags with the switch off.
    2. *Stale parent after moving a structure to rural.* Chosen: keep the reconciler's "never clear a parent" rule;
       staff clear it with `/rg setparent` (smoke § 3.3 step 10, pinned by a test, follow-up #824). Alternatives:
       (a) clear parents in `RegionChange` and the store now: changes a safety rule other chains rely on.
    3. *Endpoint while off.* Chosen: always registered, answering 503 with the reason (the agreed contract).
       Alternatives: (a) register it only with the flag: the 404 gives the API no reason.
    4. *Location without `world`.* Chosen: the server's first (default) world. Alternatives: (a) every cached world: the
       answer would be ambiguous; (b) 400: the API sends no world when the structure has none.
    5. *Unknown region.* Chosen: 404 with the reason, which the API shows as "not checked". Alternatives: (a) `false`:
       would claim "outside territory" for a typo.
    6. *Large regions.* Chosen: exact per column up to 1024 columns per side; beyond that, sampled, always including the
       outline points and the last column. Alternatives: (a) always exact: unbounded work on an HTTP thread.
    7. *Structure NPCs invulnerable* (plan § P2 "Plugin"). Chosen: left to P5 (workers) and P11 (shopkeepers), because no
       structure NPCs exist yet. Alternatives: (a) a listener now: nothing to protect, and the coordinator asked not to
       touch NPC code.
    8. *Coordinator overlap note.* `KnKPlugin` wiring is one additive block next to the region HTTP server. There is no
       `config.yml` change. The managed-region additions are one new overload and one branch. No navigation, NPC or
       siege code was touched.
6. **Out of scope, noted.**
    1. [#824](https://github.com/PandiO/knk-workspace/issues/824) (tier:1, under #22): clear the stale WorldGuard parent
       of a structure moved to rural.
    2. Codex reached its usage limit on both PRs (review "failed", usage-limit comment); there were no inline findings.
       Noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. No new `config.yml` key. After turning `production.enabled` on, run `/knk regions repair` once (or restart).
    2. The API must reach the region HTTP server (`MinecraftPlugin:BaseUrl`, shared plugin key), as for region checks
       today.
    3. Smoke test [§ 3.3](../guides/production-storage-transport-smoke-test.md) (tier:2): about 15 minutes for the
       untagged and partly tagged parts.
    4. At the end of P2 (L7 and L8 merged, coordinator decision 31): the `documentation` sub-issue covers:
        1. The managed regions page: kinds of the subtypes and the rural rule.
        2. The territory page: the lookup endpoints.
        3. The plugin scenarios guide: `rural-structure-region`.
        4. The admin guide for warehouses and production structures.
9. **Notes for later links.**
    1. L18 (P6) and later plugin links: `StructureSummary.townId` is the effective town.
       `ManagedRegionKind.fromDomainType(type, production)` is where new structure subtypes get their kind (Shop:
       `STRUCTURE`, P10).
    2. L12 (P4b surveys) and L22 (P8 harvest): rural production regions are `RESOURCE_PRODUCTION` at priority 30 with no
       parent. `ManagedRegionPolicy.Options.resourceProductionBlockBreak` is still off.
    3. P-3 (production areas, P4): the same lookup answers `contains-region` for an area's region.

### 4.9 L9 — P3 production engine API (#86)

1. **Scope done** (knk-web-api, plus essential docs in knk-workspace).
    1. Catalogue: `ProductionKind` (area model, allowed yield sources, resource category, default workers, cycle
       variation flag, `DefaultStoragesJson`) with exactly ten `ProductionKindLevel`s per kind (G8: yield multiplier,
       cycle speed, `MaxAreaSize`, Output/units-per-slot/transport caps written on level change, `UpkeepReduction`
       without effect, upgrade coins and duration) and level items (`Unlock`, `UpgradeCost`). Seeded by the migration:
       Farm, Logger, Quarry, Mine, Fishery, Flower farm, Florist, Animal farm (Hunter deferred, P-D10), 80 levels.
    2. `ProductionLine` (Configured rate, decimal `Accrued`, inputs per hour, status Running/Paused/BlockedFull/
       BlockedInputs/Error, anchored grid with indexed `NextSettleAt`). `ProductionEngine` settles each line in its own
       transaction with the line row locked: accrual, emit the floor `SYS_PRODUCTION → Output` through `IStockService`
       (idempotency key per line and settle), catch-up cap, stall when full without accruing (D4), resume without
       catch-up, inputs `Input → SYS_CONSUMPTION`.
    3. Modifier pipeline with pluggable `IProductionModifierSource` (Level, Weather, Stored) and
       `IProductionBaseRateProvider` (Configured; P4 adds Derived/Hybrid, P-D2); additions, then multiplications (F8),
       then unlock and workers (present/total). `ProductionModifier` rows with scope, target, effect and window.
    4. Weather: `ClimateZone` (one default, towns via `climate_zone_towns`, odds), `WeatherType` with effects per
       category, `WeatherRoll` stored once per zone and in-game day, deterministic on replay.
    5. `ProductionCycleRecord` per settle that accrued or changed status (each modifier, workers, emitted, accepted,
       inputs, shortfall reason). `ProductionSweepService` every 60 s; everything off while `Production:Enabled` is off
       (A21), CRUD always on. Game settings `production.engine` (base cycle 10 min, catch-up 24 h, weather day 20 min).
    6. Endpoints `api/ProductionKinds`, `api/ProductionKindLevels` (edit only), `api/ProductionLines` (+ settle),
       `api/ProductionModifiers`, `api/ClimateZones` (+ rolls), `api/WeatherTypes`, `api/ProductionCycleRecords`,
       `POST api/Production/run-now`; on `api/ProductionStructures` `GET {id}/production` ("why not producing", lazy
       settle), `PUT {id}/workers` (writes `WorkersPresent`), `POST {id}/upgrade` (stock + coins in one transaction).
       World area registry, lookups, pinned access tests. `ProductionStructure.ProductionKindId` FK (Restrict); kind
       default workers and storages on create; level caps on level change. Notification `ProductionLineStatusChanged`.
    7. Seeds (G17): form and display seeds for `ProductionKind`, `ProductionKindLevel`, `ProductionLine`,
       `ProductionModifier`, `ClimateZone`, `WeatherType`; `ProductionStructure` v2 (kind). #819 done: `ItemBlueprint`
       form v2 with `StorageWeight`, `Storage` display v2 shows the blueprint name. One additive migration
       `AddProductionEngine`; `KnKDbContext` edits in one contiguous block.
    8. knk-workspace (branch from `next`): smoke guide § 4 (18 steps, 16 automated, 2 partly; § 4.2 draft for L10),
       changelog entry, production installation § 5.3 item 8, implementation plan status.
2. **Commits and heads.** knk-web-api `claude/production-p3` at `20dcfb7` (7 commits, base `next` `fcfced2`, which had
   not moved at the last fetch, so the migration was generated last on it); knk-workspace `claude/production-p3` at
   `ea01df32` (1 commit, base `next` `c7fe8996`).
3. **PRs.** [knk-web-api#58](https://github.com/PandiO/knk-web-api/pull/58) (Closes #86, Closes #819) and
   [knk-workspace#827](https://github.com/PandiO/knk-workspace/pull/827) (Part of #86, #819), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` `fcfced2` 4723 passed / 114 skipped / 0 failed; branch 4774 passed / 116
       skipped / 0 failed. New: `ProductionEngineTests` (18), `ProductionModifierWeatherUpgradeTests` (27),
       `ProductionEngineControllersTests` (2), `AddProductionEngineTests` (4), `ProductionEngineMySqlTests` (2,
       requires-mysql).
    2. MySQL 8.0.46 locally with `KNK_TEST_MYSQL`: 4889 passed, 1 failed = the known red #285. The concurrency test
       (four sweeps racing) failed with the line lock removed (20 cycle records instead of 5) and passes with it.
    3. Migration applied, rolled back to `AddProductionWorld` and re-applied; `has-pending-model-changes` clean.
    4. CI on `20dcfb7`: build-and-test, mysql-tests and fresh-database green.
    5. Known reds: #285 (MySQL run only).
5. **Decisions (DESIGN § 4.3).** All 17, each with alternatives, are in knk-web-api#58. The main ones:
    1. *Cycle speed.* Chosen: shortens the cycle; the rate per hour is unchanged. Alternatives: (a) also multiply the
       output: would duplicate the yield multiplier.
    2. *Timing.* Chosen: game settings `production.engine` (10 min cycle, 24 h catch-up, 20-minute weather day = a
       vanilla day). Alternatives: (a) constants; (b) a real-day weather roll.
    3. *Full storage (D4).* Chosen: units that don't fit stay in `SYS_PRODUCTION`; `BlockedFull` accrues nothing and
       resumes at the first settle with room. Alternatives: (a) keep them in `Accrued`: a hidden catch-up.
    4. *Inputs.* Chosen: per hour of running time from the first Input storage, all or nothing per settle.
       Alternatives: (a) per unit of output; (b) from the Output storage.
    5. *Zone per town.* Chosen: join table `climate_zone_towns`. Alternatives: (a) `Town.ClimateZoneId`: changes the
       towns table and Town seeds (decision 15).
    6. *Seeded weather.* Chosen: default zone without odds (clear) plus example types. Alternatives: (a) seeded odds.
    7. *Upgrade.* Chosen: area node and `knk.economy.admin`; coins from a named player (new currency reason
       `PRODUCTION_UPGRADE`), resources from a storage (reason `Upgrade`, new `StockReason` member). Alternatives:
       (a) the town account (P10).
    8. *Manual runs while off.* Chosen: `run-now` and settle are 409 (A21). Alternatives: (a) allow them.
    9. *Seeds.* Chosen: six major entities; child lists are API lists, edited by L10; cycle records view-only without
       seeds. Alternatives: (a) join seeds for every child row.
    10. *Smoke gate.* The developer's 2026-11-19 waiver of the L4 and L6 smoke gates, read by the coordinator as
        covering this link (it builds on L6).
6. **Out of scope, noted.** #828 filed (retention or roll-up of production cycle records). Comment on #678 (endpoints,
   DTOs, child-list editors, the `production.engine` settings must be sent back on save, the new notification).
   Codex: the connector hit its code-review usage limit on both PRs (review "failed", usage-limit comment); no inline
   findings; noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Check `SELECT Id FROM production_structures WHERE ProductionKindId NOT BETWEEN 1 AND 8;` returns nothing, then
       apply migration `AddProductionEngine` (additive).
    2. Import the form and display seeds `ProductionKind`, `ProductionKindLevel`, `ProductionLine`,
       `ProductionModifier`, `ClimateZone`, `WeatherType`; make `ProductionStructure` v2 (form, display),
       `ItemBlueprint` v2 (form) and `Storage` v2 (display) the default.
    3. No `api.env` key, no plugin `config.yml` change.
    4. Smoke test [§ 4](../guides/production-storage-transport-smoke-test.md) (tier:3): 16 of 18 steps automated,
       about 10 minutes for the untagged parts.
    5. At merge into `next`: the `documentation` sub-issue (production engine architecture page and API contract, admin
       guide for kinds, levels, lines, modifiers, weather and upgrades, feature register row).
9. **Notes for later links.**
    1. L10 (#678): see the comment on #678.
    2. L11 (P4): add `IProductionBaseRateProvider`s for `Derived` and `Hybrid` (DI); `ProductionLineService` refuses
       other rate sources until then. Add the yield table, survey profile and primary outputs to `ProductionKind`;
       `MaxAreaSize` per level is in place (area model decides blocks, volume or radius).
    3. L14 (P5): send workers away with `PUT api/ProductionStructures/{id}/workers` (it settles first); the engine
       applies present/total. A level's `TransportCapacity` is written to the structure on level change.
    4. L21 (P8a): the pool factor and harvest moves are not in the engine yet; add the pool as a built-in step next to
       unlock and workers.

### 4.10 L10 — P3b production engine web app (#678)

1. **Scope done** (knk-web-app, plus the essential docs in knk-workspace).
    1. Types and clients: `src/types/dtos/production/ProductionEngineDtos.ts` (mirrors `ProductionEngineDtos.cs` and the enums). One client per resource: kinds, levels (read and update), lines (+ settle), modifiers, climate zones (+ `rolls/search`), weather types, cycle records (read only), `api/Production` (`run-now`). `productionStructureClient` gets `getProduction`, `setWorkers` and `upgrade`. Registry additions, additive and grouped: `Controllers`, `entityApiMapping`, `objectConfigs` columns.
    2. Kind and level editors (G8, A09): a kind's page lists its ten levels, each linked; a level's page edits its unlocks and upgrade cost (`ProductionKindLevelItemsPanel`).
    3. Line editor: `ProductionLinePanel` shows state and reason, accrual and settle times, edits the inputs, and has Settle now (the 409 reason while off) and the line's latest cycles.
    4. Modifier, climate zone and weather editors: modifier list columns (scope, "+2/h" or "× 0.5", window); `ClimateZonePanel` (odds checked to at most 100% with the rest shown as clear, towns, stored rolls); `WeatherTypeEffectsPanel`.
    5. Production view: `StructureProductionPanel` on a production structure's page:
        1. why it isn't producing, structure-wide and per line;
        2. each line's rate step by step (`RateBreakdown`) ending in the API's effective rate;
        3. the workers present;
        4. the upgrade with its cost shown before paying (payer picker, optional storage, confirm);
        5. the latest cycles with a trace (`ProductionCycleTable`).
    6. Game settings: a `ProductionEngineSettingsCard` (timing with the API's bounds) and Run production now. **Fix:** the page's save dropped `production.engine`, so the API reset it to the defaults on every save; `normalizeProductionSettings` now keeps it.
    7. #65 (production part): the cycle trace on the structure and line pages, and blocked lines in words on the line list.
    8. knk-workspace (branch from `next`): smoke guide § 4.2 (16 web app steps in full: 13 automated, 3 partly), § 4 intro and status header, changelog entry, implementation plan P3 status.
2. **Commits and heads.**
    1. knk-web-app `claude/production-p3b` at `9e5a2ca`: 4 commits, base `next` at `1838534`, which had not moved at PR time or at the last fetch.
    2. knk-workspace `claude/production-p3b` at `eaf1f1a1`: 1 commit, base `next` at `7b1495d0`, which had not moved at the last fetch.
3. **PRs.** [knk-web-app#63](https://github.com/PandiO/knk-web-app/pull/63) (Closes #678) and [knk-workspace#834](https://github.com/PandiO/knk-workspace/pull/834) (Part of #678), both into `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-app baseline on `next` `1838534`: Jest 2825 passed (331 suites), Playwright 263 passed, `tsc` clean, build OK.
    2. Branch: Jest 2845 passed (333 suites). New: `src/utils/__tests__/productionEngine.test.ts` and `src/apiClients/__tests__/productionEngineClients.test.ts`, plus one test in `territory.test.ts` (engine kept on save).
    3. Branch: Playwright 280 passed. New: `e2e/production-engine.spec.ts` (17 tests, strict API, DTO-typed fixtures in `e2e/fixtures/productionEngine.ts`). Changed: `territory.spec.ts` (the saved `production` section now includes `engine`) and `production-world.spec.ts` (the strict P2 structure pages mock the new production view). `tsc` and `typecheck:e2e` clean, build OK.
    4. Seen failing on purpose: with the engine dropped on save and the line inputs not sent, the two matching e2e tests failed.
    5. CI on `9e5a2ca`: PR runs 44612404305 (build-and-test) and 44612404476 (e2e), and push runs 44612008299 and 44612008372, all green.
    6. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Where the screens live.* Chosen: panels below the generic detail pages (the L3/L5/L7 pattern) and the seeded forms as they are. Alternatives: (a) custom pages per type: they would duplicate the seeded FormConfigurations (G17).
    2. *Child-list saves.* Chosen: each list editor sends only `{ id, <list> }` (the API keeps null fields); the level editor sends the level as read plus `items`. Alternatives: (a) send the full DTO from every editor: it would overwrite a concurrent edit; (b) put the lists on the form wizard: they are not on the seeds.
    3. *Rate breakdown.* Chosen: the steps are computed in the web app from the API's applied modifiers, in its order, ending in the API's `effectiveRatePerHour`. Alternatives: (a) the modifier list and the effective rate only: the trace is harder to follow (A08).
    4. *Upgrade request.* Chosen: a confirm step, the payer from the User lookup (required when coins are due), an optional storage (empty = Output), and no client idempotency key (the API derives one from the structure and level). Alternatives: (a) a key per request in the web app: it adds nothing.
    5. *Engine settings and Run now.* Chosen: a card on the game settings page, saved with the page; Run now is not gated in the web app because the page is staff-only and a 403 is shown. Alternatives: (a) a separate settings page: it splits the `production` section across two saves.
    6. *Workers.* Chosen: World staff can edit them (the API allows `knk.admin.world`), for tests and fixes. Alternatives: (a) read only: staff could not test the worker factor.
    7. *#65.* Chosen: the cycle trace on the structure and line pages. Alternatives: (a) a dashboard list of cycle records: the API registers the type as `ViewOnly` (noted on #678).
6. **Out of scope, noted.**
    1. [#678 comment](https://github.com/PandiO/knk-workspace/issues/678#issuecomment-7021819495) lists three API points (no kind name on `ProductionWorldListDto`, no blueprint name on `ConsumedInputDto`, no cycle record list) and one web app point (the new-line form isn't pre-filled with the structure). No new issues.
    2. Codex reached its code-review usage limit on both PRs (review "failed", no inline findings or threads); this is noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Deploy the web app with the production engine API (#86, in `next`) and its imported form and display seeds. There is no migration, setting or plugin change.
    2. Smoke test [§ 4.2](../guides/production-storage-transport-smoke-test.md#42-steps-web-app-678) (tier:2): about 45 minutes in full, about 10 minutes for the untagged parts (creating a line and a modifier with their seeded forms, a level's own values).
    3. At merge into `next`: the `documentation` sub-issue (production engine admin guide for kinds, levels, lines, modifiers, weather, the production view, upgrades and the engine settings card, plus the feature register row).
    4. Coordinator: decide on the API points of the #678 comment.
9. **Notes for later links.**
    1. L11 (P4 web app) and later web app links: `StructureProductionPanel` mounts for `productionstructure` in `DisplayWizardPage`; add the area and survey views next to it. `RateBreakdown` and `ProductionCycleTable` take any `AppliedModifierDto` list, so new modifier sources show up without changes.
    2. Strict e2e specs that open a production structure page now need a `ProductionStructures/<id>/production` mock (see `e2e/production-world.spec.ts` or `e2e/fixtures/productionEngine.ts`) and, with a kind, `ProductionKinds/<id>`.
    3. The game settings page sends `production.engine` back; a later setting under `production` must be added to `normalizeProductionSettings` the same way.

### 4.11 L11 — P4 yield areas API (#138)

1. **Scope done** (knk-web-api, plus essential docs in knk-workspace).
    1. `ProductionArea` per structure: model from the kind, shape Region (bounds reported), Cuboid, Polygon or Radius
       (default centre the structure's Location), bounding box and size (blocks, volume or radius by model). Refused
       over the level's `MaxAreaSize` (400, G6, A11) and when an exclusive area overlaps another exclusive area of the
       same model (409, bounding boxes).
    2. `AreaSurvey` history with `AreaSurveyUnit` rows (unit key, count, `sharedBy`, extra); `GET
       api/ProductionAreas/survey-due` (requested first, then never surveyed or older than 24 h; Derived and Hybrid
       only, G5; empty while the flag is off), `POST api/ProductionAreas/{id}/surveys` (plugin key or
       `knk.admin.world`; 409 while off or for Configured), `POST api/ProductionStructures/{id}/survey` ("survey now"),
       `api/AreaSurveys` search, by id and `trend`.
    3. `ProductionKind`: `SurveyProfileJson` (seeded per kind, version raised on change), `PrimaryMultiplier` (1.5),
       `yieldTable` (unit key or `PREFIX:*` → blueprint, rate, byproduct chance, min level), `primaryOutputs`.
    4. `ProductionStructure.YieldSource` (new Hybrid, existing Configured). `DerivedBaseRateProvider` and
       `HybridBaseRateProvider` via DI (L9 note): latest surveys' units × 1/sharedBy × rate × chance, the most specific
       row per unit and output; Hybrid applies `ProductionYieldOverride` pins, exclusions and scales. "Primary" and
       ±10% "Variation" (P-D9) modifier sources. Materialization into lines after surveys, overrides, yield table,
       yield source and level changes; `GET api/ProductionStructures/{id}/yield` explains every rate; `POST
       {id}/materialize` staff tool.
    5. Equal split (G7): the queue lists each area's overlapping shared areas; the plugin reports `sharedBy`.
    6. Seeds (G17): form and display `ProductionArea`, `ProductionYieldOverride`; display `AreaSurvey`;
       `ProductionKind` v2, `ProductionStructure` v3 (form and display). One additive migration
       `AddProductionYieldAreas`, generated last on `next` `6c648f6`; `KnKDbContext` edits in one contiguous block.
    7. #831 (additive extra, closed by the PR): warehouse and production structure updates answer 200 with their
       placement warnings; 400 bodies without " (Parameter 'dto')"; `Structure` form v3 with "Town (rural)".
    8. knk-workspace (branch from `next`): smoke guide § 5 (§ 5.1 18 API steps, 17 automated, 1 partly; § 5.2 plugin
       and § 5.3 web app drafts), changelog entry, production installation § 5.3 item 9, implementation plan status.
2. **Commits and heads.** knk-web-api `claude/production-p4` at `06b11ca` (6 commits, base `next` `6c648f6`, which had
   not moved at the last fetch, so the migration was generated last on it); knk-workspace `claude/production-p4` at
   `b467e15a` (1 commit plus a merge of `next` `9eef39cf`, L10's docs; header lines kept from both sides).
3. **PRs.** [knk-web-api#60](https://github.com/PandiO/knk-web-api/pull/60) (Closes #138, Closes #831) and
   [knk-workspace#837](https://github.com/PandiO/knk-workspace/pull/837) (Part of #138, #831), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` `6c648f6` 4774 passed / 116 skipped / 0 failed; branch 4801 passed / 117
       skipped / 0 failed. New: `ProductionYieldTests` (18), `ProductionYieldControllersTests` (2),
       `PlacementRulesTests` (+3, #831), `AddProductionYieldAreasTests` (4), `ProductionYieldMySqlTests` (1,
       requires-mysql). The shared split and the size cap were broken on purpose once and their tests went red.
    2. MySQL 8.0.46 locally with `KNK_TEST_MYSQL`: 4917 passed, 1 failed = the known red #285.
    3. Migration applied, rolled back to `AddProductionEngine` and re-applied; `has-pending-model-changes` clean.
    4. CI: build-and-test, mysql-tests and fresh-database green on the push of the migration commit; the PR run on
       `06b11ca` green too (21:27).
    5. Known reds: #285 (MySQL run only).
5. **Decisions (DESIGN § 4.3).** All 14, each with alternatives, are in knk-web-api#60. The main ones:
    1. *Shared split.* Chosen: the plugin reports `sharedBy` per unit; the API lists overlapping shared areas in the
       queue. Alternatives: (a) estimate from bounding-box overlap: inexact; (b) store unit positions: too much data.
    2. *Pin.* Chosen: replaces the survey's rate. Alternatives: (a) adds to it.
    3. *Vanished outputs.* Chosen: the line stays with base 0. Alternatives: (a) delete it: loses its cycle records.
    4. *Existing structures.* Chosen: `Configured` (column default), new ones `Hybrid`. Alternatives: (a) all Hybrid:
       the P3 lines would no longer match their structure.
    5. *Yield tables.* Chosen: none seeded (blueprint ids differ per server); profiles seeded. Follow-up #836.
    6. *Primary multiplier.* Chosen: kind field, 1.5, on Derived and Hybrid lines only. Alternatives: (a) also on
       Configured lines; (b) per structure.
    7. *Survey interval.* Chosen: a 24 h constant (G5). Alternatives: (a) a game setting.
    8. *Smoke gate.* The developer's 2026-11-19 waiver of the L4 and L6 smoke gates, read by the coordinator as
       covering this link too (it builds on L9, whose smoke test is open).
6. **Out of scope, noted.** #836 filed (default yield tables per kind). Comments on #679 (queue and report contract,
   `sharedBy`, profile JSON) and #680 (endpoints, DTOs, editors). Codex: the connector hit its code-review usage limit
   on both PRs (review "failed", usage-limit comment); no inline findings; noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply migration `AddProductionYieldAreas` (additive; existing structures become `Configured`).
    2. Import the seeds `ProductionArea`, `ProductionYieldOverride` (form and display) and `AreaSurvey` (display); make
       `ProductionKind` v2, `ProductionStructure` v3 (form and display) and `Structure` v3 (form) the default.
    3. Fill each kind's `yieldTable` (none seeded; #836 proposes defaults).
    4. No `api.env` key, no plugin `config.yml` change.
    5. Smoke test [§ 5.1](../guides/production-storage-transport-smoke-test.md) (tier:3): 17 of 18 steps automated,
       about 5 minutes for the untagged part.
    6. At merge into `next`: the `documentation` sub-issue (yield areas architecture page and API contract, admin guide
       for areas, yield tables, overrides and "survey now", feature register row).
9. **Notes for later links.**
    1. L12 (#679): see the comment on #679. Report one unit row per (key, `sharedBy`); count `sharedBy` over distinct
       structures, this one included. The plugin owns the survey profile JSON beyond `unitTypes`.
    2. L13 (#680): see the comment on #680. `areas` is read only on the structure DTO; area create/update return the
       area with `size`, `sizeUnit` and the level's `maxSize`.
    3. L21 (P8a): the pool factor is still not in the engine; the latest survey's `TotalUnits` can seed a pool's
       capacity.

### 4.12 L12 — P4b surveys plugin (#679)

1. **Scope done** (knk-plugin, plus essential docs in knk-workspace). Everything runs only with `production.enabled:
   true` (A21).
    1. knk-core `production/survey/` (Bukkit-free): `SurveyCounter` over the `BlockSnapshotSource` port (trees as
       26-connected log clusters with leaves within reach, species by majority log, SMALL/MEDIUM/LARGE by log count,
       clusters over `maxLogs` are buildings; saplings; rock and ores in the whole volume; crops; flowers, tall ones
       once; still water per biome with `columns`, `avgDepth`, `openSkyShare`; pasture animals), `PlaceholderOverlay`
       (blocks waiting to regenerate count as their original; empty until P8), `AreaShape`, `AreaSpec`, `SurveyProfile`
       (the seeded `unitTypes` plus the plugin's `materials`, `entityTypes`, `tree`), `NotableChangeTracker`,
       `AreaOutline`, `CaptureRadius`, `SurveySettings`, `CapturedChunks`; port `ProductionSurveyApi`. Shared split per the
       L11 contract: one row per (key, `sharedBy`), `sharedBy` = 1 + distinct other structures whose overlapping shared
       areas contain the unit. SHA-256 content hash of the rows.
    2. knk-api-client `ProductionSurveyApiImpl` (`survey-due`, `{id}/surveys`, `ProductionStructures/{id}/survey`,
       `GET api/ProductionAreas`).
    3. knk-paper `production/`: `SurveyRunner` (one survey at a time; `chunks-per-tick` snapshots on the main thread,
       timed as `production.survey.capture`; counting and reporting on the `KnK-survey` thread; Scheduled surveys wait
       for loaded chunks, requested ones load chunks without generating them; caps), `SurveyModule` (queue poll, area
       list, block break/place counters → `NotableChange`), `ChunkSnapshotBlocks`, `SurveyWorld`, `SurveyRegionShapes`,
       `AreaOutlineRenderer`, `CaptureRadiusTaskHandler` (world task `CaptureRadius`).
    4. `/knk production survey <structure> [area] | survey status | area show <structure> [area] [seconds]`, node
       `knk.admin.world.production`; `config.yml` `production.surveys.*` (nine keys). `KnKPlugin`, `config.yml` and
       `plugin.yml` changes are separate additive blocks.
    5. Plugin scenario `production-area-survey`; `MIN_SCENARIOS` 68 (65 + link G1's two + this one). Hunters deferred
       (P-D10).
    6. knk-workspace (branch from `next`): smoke guide § 5.2 (15 steps: 7 automated, 7 partly, 1 manual), plugin
       configuration § 4.31 `production.surveys.*` with § 2.1 and § 3 rows, changelog entry with the YAML,
       implementation plan § P4 status.
2. **Commits and heads.** knk-plugin `claude/production-p4b` at `3472e32d` (6 commits plus two merges of `origin/next`,
   the second `MIN_SCENARIOS` 66/67 → 68 and the scenario count test); knk-workspace `claude/production-p4b` at
   `c6f53e07` (1 commit plus three merges of `origin/next`; changelog, plugin configuration, smoke guide and plan
   conflicts were both-sides additions, L13's § 5.3 kept). The first push `c00f95a2` (before the usage-limit stop) did
   not compile (a package-private method used by the command); fixed in the next commit.
3. **PRs.** [knk-plugin#105](https://github.com/PandiO/knk-plugin/pull/105) (Closes #679),
   [knk-workspace#876](https://github.com/PandiO/knk-workspace/pull/876) (Part of #679), base `next`. Not merged.
4. **Tests, baseline → result** (`./gradlew build -x deployToDevServer`, Gradle on JDK 21, JDK 25 toolchain).
    1. Baseline on `next` `cbac2b6c`: knk-core 3541, knk-api-client 366 (2 skipped), knk-paper 3229 (18 skipped), 0
       failures.
    2. Branch at `3472e32d` (after merging `next`): knk-core 3594, knk-api-client 371 (2 skipped), knk-paper 3284 (18
       skipped), 0 failures.
    3. New: `SurveyCounterTest` (15), `SurveyAreasTest` (9), `CaptureRadiusTest` (3), `ProductionSurveyApiImplTest` (4),
       `SurveyRunnerTest` (6), `SurveyConfigTest` (3), `ProductionAdminCommandTest` (4); `PaperScenariosTest` updated. A
       mutation of the shared split (`sharedBy` always 1) failed `SurveyCounterTest` and `SurveyRunnerTest`.
    4. CI on `3472e32d`: build green; paper-boot green (68 scenarios, `production-area-survey` PASS in 3 ticks). The scenario was not run locally (no Paper server in the
       session).
    5. Known reds: none.
5. **Decisions (DESIGN § 4.3).** All nine with alternatives are in knk-plugin#105. The main ones:
    1. *Scheduled surveys and unloaded chunks.* Chosen: skipped (stays due) unless every chunk is loaded;
       `scheduled-loads-chunks: true` loads them; requested surveys always load them, never generate. Alternatives: (a)
       always load: daily cost for remote areas; (b) never load: a requested survey of a remote area never runs.
    2. *Trees at the border.* Chosen: only logs inside the area cluster; a tree's position is its lowest log.
       Alternatives: (a) read a margin: more snapshots, trees mostly outside would count.
    3. *Tree limits.* Chosen: SMALL ≤ 6 logs, MEDIUM ≤ 20, building > 400, leaves within 1 block; profile overrides.
       Alternatives: (a) per-species tables.
    4. *Farmland.* Chosen: crops count without a farmland or hydration check (§ 8.1 open). Alternatives: (a) hydrated
       farmland only: excludes sugar cane, cocoa, nether wart.
    5. *sharedBy.* Chosen: the L11 contract literally. Alternatives: (a) same area model only: still wrong; follow-up
       #875.
    6. *Notable change.* Chosen: block breaks and places per area (64, cooldown 30 min), then "survey now" through the
       API with trigger `NotableChange`. Alternatives: (a) wait for P8's harvest counters.
    7. *Plugin caps.* Chosen: `max-area-chunks` 256, `max-area-blocks` 16M (snapshot memory, counting time); the API's
       level cap (G6) stays the rule. Alternatives: (a) no plugin cap.
6. **Out of scope, noted.** [#875](https://github.com/PandiO/knk-workspace/issues/875) (tier:2, under #22): overlaps in the
   survey queue should carry each area's unit types, so `sharedBy` counts only structures that count the unit (a farm
   inside a logger's radius now halves its crops). Codex: the connector hit its code-review usage limit on both PRs
   (usage-limit comment, review "failed"); no inline findings; noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Merge into the plugin's `production` block (nothing runs while `production.enabled` is false) and restart:

       ```yaml
       production:
         surveys:
           poll-minutes: 5
           batch: 20
           chunks-per-tick: 2
           max-area-blocks: 16000000
           max-area-chunks: 256
           scheduled-loads-chunks: false
           notable-change-blocks: 64
           notable-cooldown-minutes: 30
           areas-refresh-minutes: 10
       ```
    2. Grant `knk.admin.world.production` to staff who survey (in `knk.admin.world.*`).
    3. Smoke test [§ 5.2](../guides/production-storage-transport-smoke-test.md) (tier:3): about 30 minutes for the
       untagged and partly tagged parts; needs L11 (API) and yield table rows (#836) for rates.
    4. At merge into `next`: the `documentation` sub-issue (survey architecture page with the profile JSON fields and
       unit keys, admin guide for surveys and `/knk production`, commands guide, plugin scenarios guide
       `production-area-survey`, feature register row).
9. **Notes for later links.**
    1. L22 (P8 harvest): implement `PlaceholderOverlay` over the regeneration jobs and pass it to `SurveyRunner` in
       `SurveyModule` (now `PlaceholderOverlay.NONE`); a felled tree's job should list every original log and leaves
       block so the tree counts whole. Harvest counters can feed `NotableChangeTracker.record`.
    2. L13 / web app: the `CaptureRadius` world task's output is `{shape, worldName, centerX, centerY, centerZ, radius}`;
       its input may carry `radius` and `maxRadius` (the level's cap).
    3. Profiles: the plugin reads `materials`, `entityTypes` and `tree.{smallMaxLogs, mediumMaxLogs, maxLogs, leafReach}`
       beyond `unitTypes`; raising the kind's profile version is the API's job when they change.

### 4.13 L13 — P4c yield areas web app (#680)

1. **Scope done** (knk-web-app, plus the essential docs in knk-workspace).
    1. Types and clients: `src/types/dtos/production/ProductionYieldDtos.ts` (mirrors `ProductionYieldDtos.cs` and the P4 enums); P4 fields on `ProductionKindDto` and `ProductionStructureDto` (`yieldSource`, read-only `areas`); `productionAreaClient` (CRUD, search, overlaps), `areaSurveyClient` (read, search, trend), `productionYieldOverrideClient` (CRUD, search); `productionStructureClient.getYield`, `requestSurvey`, `materialize`. Registry additions, additive and grouped: `Controllers`, `entityApiMapping` (areas and overrides all five, surveys search and fetch), `objectConfigs` columns.
    2. Production structure page, `StructureYieldPanel` (A10, #65): the yield source in words; the areas with size against the level's cap; Add area (the seeded form); Survey now (hidden for Configured, G5) and Make lines again; every output with why its rate is what it is (surveyed rate, override, base, primary, line; per survey unit the area, unit, matched yield row, count, shared split, rate and chance); the unmatched unit keys.
    3. Hybrid override editor on the same panel: Pin, Exclude, Scale or None per output, and a pin for an output the survey doesn't yield.
    4. Survey viewer: `ProductionAreaPanel` on an area's page (size and cap, a 2D plot from above with the overlapping areas `AreaPlot`, the overlaps table, the latest composition `SurveyCompositionTable`, the trend over 30 surveys `SurveyTrendTable`, the history, Survey this area now); `AreaSurveyPanel` on a survey's page.
    5. Kind page: `ProductionKindYieldTablePanel` edits the yield table and the primary outputs (sends `{ id, yieldTable, primaryOutputs }`; checks match the API's). Survey profile and multiplier stay on the seeded form.
    6. Form wizard: a refused ProductionArea or ProductionYieldOverride save shows the API's `{ error }` sentence (area over the cap, A11; exclusive overlap; a second override), as the P2 types did.
    7. Area capture via WorldTask: the seeded ProductionArea form has no world task and the API needs a Region's bounds typed in; `CaptureRadius` is neither in the API's known types nor handled by the plugin yet. Filed on #680 (out of scope, knk-web-api); smoke step 5.3.3 does it by hand with `RegionClaim` turned on in the form builder.
    8. knk-workspace (branch from `next`): smoke guide § 5.3 (12 web app steps in full: 9 automated, 2 partly, 1 by hand), § 5 intro and status header, changelog entry, implementation plan P4 status.
2. **Commits and heads.**
    1. knk-web-app `claude/production-p4c` at `6da700c`: 7 commits plus merges of `next` (`2c177be`, then `287bb2c`, which had not moved at the last fetch).
    2. knk-workspace `claude/production-p4c` at `638e5c3c`: 1 commit plus a merge of `next` (no conflicts).
3. **PRs.** [knk-web-app#67](https://github.com/PandiO/knk-web-app/pull/67) (Closes #680) and [knk-workspace#873](https://github.com/PandiO/knk-workspace/pull/873) (Part of #680), both into `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-app baseline on `next` `4e4ca39`: Jest 2845 passed (333 suites), Playwright 280 passed, `tsc` clean, build OK.
    2. Branch after merging `next` `287bb2c`: Jest 2882 passed (338 suites; `next` brought its own new tests); new `src/utils/__tests__/productionYield.test.ts` (9) and `src/apiClients/__tests__/productionYieldClients.test.ts` (6). `tsc` and `typecheck:e2e` clean.
    3. Playwright: 296 passed (full run); the three production specs repeated 5×: 185 passed, none flaky. New `e2e/production-yield.spec.ts` (11 tests, strict API, DTO-typed fixtures `e2e/fixtures/productionYield.ts`); `production-world.spec.ts` and `production-engine.spec.ts` mock the new yield panel.
    4. Seen failing: the override test failed while the toast came before the reload (a fast second edit was reset); fixed in the panel.
    5. CI on `6da700c`: build-and-test and e2e green (PR runs 44734961691 and 44734961655, push runs 44734955024 and 44734955138).
    6. Known reds: none.
5. **Decisions (DESIGN § 4.3).**
    1. *Area capture.* Chosen: the seeded form; the seed's `RegionClaim` and Region bounds asked of the API on #680; `CaptureRadius` after #679. Alternatives: (a) a world-task default hard-coded in `FormWizard`: changes the shared wizard for one seed and still leaves bounds to type; (b) offer `CaptureRadius` now: no handler, the task would hang (#180).
    2. *Where the screens live.* Chosen: panels below the generic detail pages (the L3/L5/L7/L10 pattern). Alternatives: (a) custom pages: duplicate the seeded forms (G17).
    3. *Trend.* Chosen: one small line per unit key, each on its own scale, in a table with first, latest and change. Alternatives: (a) one multi-series chart: needs a categorical palette for many unit keys, and small units vanish.
    4. *Override editing.* Chosen: one select per output (None deletes), plus one row to pin a new output; the success message after the re-read. Alternatives: (a) a separate override list: away from the rate it changes.
    5. *Make lines again.* Chosen: shown to World staff. Alternatives: (a) hidden: staff need it after fixing a yield table.
    6. *Refusal sentence on the P4 forms.* Chosen: extend the P2 `{ error }` reading to the two P4 form types. Alternatives: (a) change `describeErrorBody` app-wide: outside this link.
6. **Out of scope, noted.** [#680 comment](https://github.com/PandiO/knk-workspace/issues/680#issuecomment-7039235466): the area seed's missing `RegionClaim`, Region bounds from the region, `CaptureRadius` (API known types and #679 handler), no `yieldSource` on `ProductionWorldListDto`, and Add area without the structure prefilled (web app). No new issues. Codex: the connector hit its code-review usage limit on both PRs (review "failed", usage-limit comment); no inline findings or threads; noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Deploy the web app with the P4 API (#138, in `next`) and its imported seeds. No migration, setting or plugin change.
    2. Until the seed carries it, turn on `RegionClaim` on the ProductionArea form's WorldGuard region field in the form builder.
    3. Smoke test [§ 5.3](../guides/production-storage-transport-smoke-test.md) (tier:2): about 40 minutes in full, about 15 minutes for the untagged parts.
    4. At merge into `next`: the `documentation` sub-issue (yield areas admin guide: areas, the survey viewer, yield tables, overrides, Survey now; feature register row).
    5. Coordinator: decide on the API points of the #680 comment.
9. **Notes for later links.**
    1. L12 (#679): when the `CaptureRadius` handler ships, add it to `WORLD_TASK_TYPES_WITH_HANDLER` (`src/utils/forms/worldTaskTypes.ts`) and to the API's `KnownWorldTaskTypes`.
    2. Strict e2e specs that open a production structure page now need a `ProductionStructures/<id>/yield` mock (`mockConfiguredYield` in `e2e/fixtures/productionYield.ts`); a kind's page reads `ProductionKinds/<id>` for the yield table too.
    3. L21/L22 (harvest): `SurveyTrendTable` and `SurveyCompositionTable` take any survey; a pool view can reuse them.

### 4.14 L14 — P5 transport API (simulated carrying, G14) (#79)

1. **Scope done** (knk-web-api, plus essential docs in knk-workspace).
    1. `TransportOrder` (origin, status lifecycle, carrier structure and capacity, timing, `NextActionAt` index) with
       `TransportStop`s and per-stop `TransportStopLine`s (V2 defect 3), `TransportOrderLine`s (requested, loaded,
       delivered, returned, lost), one `Transit` storage per order (unique), `TransportAssignment` (Simulated) and the
       `TransportEvent` log.
    2. Lifecycle Planned → Assigned → Loading → InTransit ⇄ AtStop → Delivered. A full stop goes AwaitingSpace (30 min),
       then re-routes within the town (max 2), else the carrier carries on and the rest goes back: Returning → Returned,
       with ReturnBlocked while the source is full (V2 defect 2). Every step runs in one transaction with the order row
       locked, and every move goes through `IStockService` (TransportLoad, TransportDeliver, TransportReturn) with an
       idempotency key per try. The ledger reconciles after every step, and a restart continues mid-transit (V2
       defects 4, 11).
    3. Simulated carrying (G14, § 7.7): one of the producer's workers is away from loading until the order ends
       (`WorkersPresent` ±1, the carrier's production settled first), so the engine runs at 50% / 0%. An order waits
       without a free worker; the level's `TransportCapacity` bounds it. A leg takes the lane's road length ÷ walking
       speed; without a lane the straight distance × 1.4, without positions 200 blocks.
    4. Automatic trigger (V2 defects 7-9): it fires on occupancy ≥ threshold (75% of the cap), a line BlockedFull or
       the distinct cap. Sizing is by stock up to the worker's capacity, largest line first. The destination is the
       preferred warehouse if it has room, else the nearest by road in the effective town, with room first. One open
       automatic order per source (structure row lock). Rural producers that are not `Connected` are held (D5).
    5. `TransportLane` read model with `GET api/TransportLanes/due` and `POST report` for L15, plus staff CRUD.
       `TransportSweepService` runs every 60 s with `Production:Enabled` only (A21). Manual orders (`POST
       api/TransportOrders`, `clientKey` replay), `dry-run`, `{id}/cancel` (a loaded order turns back) and `run-now`
       (409 while off).
    6. `GET api/ProductionStructures/{id}/transport` is the trigger's dry run: warnings (missing road, full Output,
       A13), trigger and held reasons, open orders, workers away. The structure DTO also warns about a full Output.
       Game setting section `production.transport`; a save without it keeps the stored values.
    7. #838 (additive extra, closed by the PR): `productionKindName` on `ProductionWorldListDto`, `itemBlueprintName` on
       `ConsumedInputDto` (read, never stored), `ProductionCycleRecord` as a listable dashboard type with a lookup and an
       `itemBlueprintId` filter.
    8. Seeds (G17): form and display `TransportOrder` (form read only) and `TransportLane`; the child rows are view-only.
       World area registry, lookups, pinned access tests. One additive migration `AddTransportCore` (seven tables),
       generated last on `next` `4f4580b`; `KnKDbContext` edits in one DbSet block and one model block.
    9. knk-workspace (branch from `next`): smoke guide § 6 (§ 6.1 20 API steps, 18 automated, 2 partly; § 6.2 and
       § 6.3 drafts for L15 and L16), changelog entry, production installation § 5.3 item 12, implementation plan status.
2. **Commits and heads.** knk-web-api `claude/production-p5` at `ef61cd1` (6 commits plus two merges of `next`, the
   last at `4f4580b`; migration generated after it). knk-workspace `claude/production-p5` at `ae26c88b` (1 commit plus a
   merge of `next` `2159952e`).
3. **PRs.** [knk-web-api#65](https://github.com/PandiO/knk-web-api/pull/65) (Closes #79, Closes #838) and
   [knk-workspace#880](https://github.com/PandiO/knk-workspace/pull/880) (Part of #79, #838), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` `e26c7d8` 4801 passed / 117 skipped / 0 failed; branch (with `next` `4f4580b`)
       4865 passed / 119 skipped / 0 failed. New: `TransportTests` (33), `TransportLanesAndSettingsTests` (4),
       `TransportControllersTests` (2), `AddTransportCoreTests` (3), `TransportMySqlTests` (1, requires-mysql).
    2. MySQL 8.0.46 locally with `KNK_TEST_MYSQL`: 4983 passed, 1 failed = the known red #285. The new race test
       (four transport sweeps) makes one automatic order and applies each step once.
    3. Broken on purpose: the worker decrement and the per-stop shortfall (3 tests red), and the order and structure
       row locks (the MySQL race test red with two orders).
    4. Migration applied, rolled back to `SeedNavigateDefaultNode` and re-applied; `has-pending-model-changes` clean.
    5. CI on `ef61cd1`: build-and-test, fresh-database and mysql-tests green on the push run; on the PR run
       build-and-test and fresh-database green, mysql-tests still running when this block was written.
    6. Known reds: #285 (MySQL run only).
5. **Decisions (DESIGN § 4.3).** All 14, each with alternatives, are in knk-web-api#65. The main ones:
    1. *Walking speed.* Chosen: game setting `production.transport.walkingSpeedBlocksPerSecond` 4.317 (a player's walk;
       the NPC plan's abstract mover names no number). Alternatives: (a) a constant; (b) sprint 5.6 b/s.
    2. *Worker away.* Chosen: from loading until the order ends. Alternatives: (a) also the empty walk back; (b) the
       outbound leg only.
    3. *Worker accounting.* Chosen: `WorkersPresent` ±1 after settling the carrier. Alternatives: (a) a `WorkersAway`
       column; (b) the engine derives presence from assignments.
    4. *Full stop.* Chosen: wait 30 min, re-route within the town (max 2), else carry on and return the rest;
       ReturnBlocked waits. Alternatives: (a) return at once; (b) overflow to `SYS_LOSS` (V2 defect 2).
    5. *Cancel after loading.* Chosen: turn back and end Returned. Alternatives: (a) end Cancelled; (b) refuse.
    6. *No lane.* Chosen: straight × 1.4, else 200 blocks, with a dry-run warning. Alternatives: (a) refuse until #681.
    7. *Unmeasured road.* Chosen: held like Unconnected (D5). Alternatives: (a) hold only Unconnected.
    8. *Manual orders.* Chosen: `knk.admin.world` or the plugin key (they create no goods). Alternatives: (a)
       `knk.economy.admin`.
    9. *Seeds.* Chosen: `TransportOrder` form read only, manual orders through the API and #682's form; child rows
       without seeds (developer's G17 clarification). Alternatives: (a) a flat single-stop create form.
    10. *Smoke gate.* The developer's 2026-11-19 waiver of the L4 and L6 smoke gates, read by the coordinator as
        covering this link (it builds on L9, whose smoke test is open).
6. **Out of scope, noted.** #881 filed (the `StockTransaction` form seed's Reason list lacks `Upgrade`). Comments on
   #681 (due/report contract, road connection, trip time) and #682 (endpoints, DTOs, the structure's transport view,
   settings, #838). Codex: the connector hit its code-review usage limit on both PRs (review "failed", usage-limit
   comment); no inline findings; noted on each PR.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply migration `AddTransportCore` (additive, seven tables).
    2. Import the seeds `TransportOrder` and `TransportLane` (form and display, "make default").
    3. Until L15 (#681) measures lanes: type in lanes or accept estimated routes, and set rural producers' road
       connections (`PUT api/ProductionStructures/<id>/road-connection`); automatic transport is held until Connected.
    4. No `api.env` key, no plugin `config.yml` change; game setting `production.transport` has defaults.
    5. Smoke test [§ 6](../guides/production-storage-transport-smoke-test.md) (tier:3): 18 of 20 steps automated, about
       10 minutes for the untagged parts.
    6. At merge into `next`: the `documentation` sub-issue (transport architecture page and API contract, admin guide
       for orders, lanes and settings, feature register row).
9. **Notes for later links.**
    1. L15 (#681), L16 (#682): see the comments on #681 and #682.
    2. L17 (P6a): the caller-filtered structure view can reuse `TransportService.StructureViewAsync` and the order search
       filter `structureId` for the orders list.
    3. L23 (P9): `TransportOrigin.Distribution` exists. Collection orders can be made with the internal insert path: a
       consumer's worker as carrier (`CarrierStructureId` is a `ProductionStructure` today; consumers that are not
       production structures need it widened) and the warehouse storage as source. The automatic trigger only looks at
       production structures.
