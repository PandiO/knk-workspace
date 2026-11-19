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
3. **Smoke test of territory (L1 § 1.1–1.2, L2 § 1.3, L3 § 1.4).**
   1. Apply migration `AddTerritory`.
   2. Import the four territory form and display seeds (`Kingdom` first).
   3. Merge the plugin `production` block into `config.yml`.
   4. To test, turn on `production.enabled` in the plugin and in the API game settings.
4. **Review:** the agent decisions in blocks 4.0–4.4 (L0's retag rule; L1 server-side territory and loyalty as a town
   id; L2's crown land region kind) and coordinator decision 15 (Town/District seed fields).
5. Later: the shop menu templates for L26 (#687).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L0 Item identity: every obtainable item is a blueprint; generated "Uncurated" shadow blueprints (G4) | #141 | Merged into next (2026-11-19) | api `5daa3c6`, plugin `a6c5a2bc`, workspace `8ffdbb1a`; merges: api `7d213fd6`, plugin `2ef256e7`, workspace `ca3bcc98` | [api#51](https://github.com/PandiO/knk-web-api/pull/51), [plugin#89](https://github.com/PandiO/knk-plugin/pull/89), [ws#793](https://github.com/PandiO/knk-workspace/pull/793) | green (API PR checks; plugin build + paper-boot) | subagent of the coordinator (two repos besides knk-workspace, SKILL § 4.1.4.2), started 2026-11-19 |
| L1 Territory API: holders, crown land entity (G10), power, range (G11), conflicts, loyalty | #326 | Merged into next (2026-11-19) | api `ff50ec1`, workspace `c4211d51`; merges: api `0d6e369a`, workspace `4595e6d8` | [api#53](https://github.com/PandiO/knk-web-api/pull/53), [ws#798](https://github.com/PandiO/knk-workspace/pull/798) | green (build-and-test, mysql-tests, fresh-database) | create_session `session_01R1w2Uwo46dJVo6Cpr8LzmG` (one repo besides knk-workspace), started 2026-11-19 |
| L2 Territory plugin: chunk cache, lookup, BlueMap outlines | #689 | Merged into next (2026-11-19) | plugin `96ef7326`, workspace `14d3efcd`; merges: plugin `55804b11`, workspace `66d35872` | [plugin#91](https://github.com/PandiO/knk-plugin/pull/91), [ws#804](https://github.com/PandiO/knk-workspace/pull/804) | green (plugin build + paper-boot) | create_session `session_01R1w2Uvhpo37DXAXpm2uqLp` (one repo besides knk-workspace), started 2026-11-19 |
| L3 Territory web app | #690 | Merged into next (2026-11-19) | web app `0531422`, workspace `f3bd8f27`; merges: web app `89751315`, workspace `54bdc830` (after a coordinator merge of `next`, `e4f2276d`) | [web#57](https://github.com/PandiO/knk-web-app/pull/57), [ws#803](https://github.com/PandiO/knk-workspace/pull/803) | web app green (build-and-test, e2e) | create_session `session_01R1w2UuYHneFJFXcn8GSe6F` (one repo besides knk-workspace), started 2026-11-19 |
| L4 P1 stock core API: storages, ledger, reconciler, capacity, roll-up | #97 | Merged into next (2026-11-19) | api `e524721`, workspace `abef76fc`; coordinator merge of `next` `06fee906`; merges: api `2e7d4e81`, workspace `1bbdd69f` | [api#56](https://github.com/PandiO/knk-web-api/pull/56), [ws#816](https://github.com/PandiO/knk-workspace/pull/816) | green (build-and-test, mysql-tests, fresh-database) | create_session `session_01R1w2Uwv8FBnKCUoeZauzVt` (one repo besides knk-workspace), started 2026-11-19 |
| L5 P1b stock web app | #675 | Running | — | — | — | create_session `session_01R1w2UuKsus7BT7DcXyL4jr` (one repo besides knk-workspace), started 2026-11-19 |
| L6 P2 world API: structure subtypes, TownId, placement rules | #91 | Running | — | — | — | create_session `session_01R1w2UscSGsG34qwc8vtEQj` (one repo besides knk-workspace), started 2026-11-19 |
| L7 P2b world web app | #676 | Not started | — | — | — | — |
| L8 P2c world plugin: managed-region kinds | #677 | Not started | — | — | — | — |
| L9 P3 production engine API | #86 | Not started | — | — | — | — |
| L10 P3b production web app | #678 | Not started | — | — | — | — |
| L11 P4 yield areas API | #138 | Not started | — | — | — | — |
| L12 P4b surveys plugin | #679 | Not started | — | — | — | — |
| L13 P4c yield areas web app | #680 | Not started | — | — | — | — |
| L14 P5 transport API (simulated carrying, G14) | #79 | Not started | — | — | — | — |
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

