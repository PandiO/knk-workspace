# Production, storage and transport chain — progress report

**Status:** Running (2026-11-19) · **Last updated:** 2026-11-19

**Issue:** [PandiO/knk-workspace#22](https://github.com/PandiO/knk-workspace/issues/22), links
[#141](https://github.com/PandiO/knk-workspace/issues/141) (L0), [#326](https://github.com/PandiO/knk-workspace/issues/326) (L1), [#689](https://github.com/PandiO/knk-workspace/issues/689) (L2), [#690](https://github.com/PandiO/knk-workspace/issues/690) (L3), [#97](https://github.com/PandiO/knk-workspace/issues/97) (L4), [#675](https://github.com/PandiO/knk-workspace/issues/675) (L5), [#91](https://github.com/PandiO/knk-workspace/issues/91) (L6), [#676](https://github.com/PandiO/knk-workspace/issues/676) (L7), [#677](https://github.com/PandiO/knk-workspace/issues/677) (L8), [#86](https://github.com/PandiO/knk-workspace/issues/86) (L9), [#678](https://github.com/PandiO/knk-workspace/issues/678) (L10), [#138](https://github.com/PandiO/knk-workspace/issues/138) (L11), [#679](https://github.com/PandiO/knk-workspace/issues/679) (L12), [#680](https://github.com/PandiO/knk-workspace/issues/680) (L13), [#79](https://github.com/PandiO/knk-workspace/issues/79) (L14), [#681](https://github.com/PandiO/knk-workspace/issues/681) (L15), [#682](https://github.com/PandiO/knk-workspace/issues/682) (L16), [#683](https://github.com/PandiO/knk-workspace/issues/683) (L17), [#74](https://github.com/PandiO/knk-workspace/issues/74) (L18), [#60](https://github.com/PandiO/knk-workspace/issues/60) (L19), [#684](https://github.com/PandiO/knk-workspace/issues/684) (L20), [#685](https://github.com/PandiO/knk-workspace/issues/685) (L21), [#134](https://github.com/PandiO/knk-workspace/issues/134) (L22), [#127](https://github.com/PandiO/knk-workspace/issues/127) (L23), [#686](https://github.com/PandiO/knk-workspace/issues/686) (L24), [#248](https://github.com/PandiO/knk-workspace/issues/248) (L25), [#687](https://github.com/PandiO/knk-workspace/issues/687) (L26), [#688](https://github.com/PandiO/knk-workspace/issues/688) (L27), [#249](https://github.com/PandiO/knk-workspace/issues/249) (L28), [#250](https://github.com/PandiO/knk-workspace/issues/250) (L29).
**Charter:** [handoffs/PRODUCTION_CHAIN.md](../ai-agents/handoffs/PRODUCTION_CHAIN.md).
**Coordinator:** cloud session `session_01R1w2UtB6J4UtRJL3foJgcj`.

## 1. Waiting for the developer

1. **Smoke test of L0 (item identity, tier:3):** guide `docs/guides/production-storage-transport-smoke-test.md` § 0 on
   `next` (14 steps, about 25 minutes for the untagged ones). Before it: apply migration `AddItemIdentity`, run a
   catalogue scan (or `POST api/ItemIdentity/shadows/generate`), merge the `items.identity` block into the plugin
   `config.yml` (both switches off by default). L4 (#97 stock core) builds on L0 and waits for this (charter § 2.3).
2. **Decision:** L0 stores conversion counts in `item_conversion_stats` without form/display seeds, an exception to
   G17 (L0 block, decision 7). Confirm or ask for seeds.
3. **Review:** L0 agent decisions (block 4.0 § 5), mainly the retag rule (plain vanilla items are never tagged) and
   the two plugin switches `items.identity.enabled` / `convert-on-obtain`.
4. **Smoke test of L1 (territory API, tier:3):** guide § 1.1–1.2 on `next`. Before it: apply migration `AddTerritory`,
   import the form seeds `Kingdom`, `Province`, `CrownLand`, `TerritoryConflict` and their display seeds (`Kingdom`
   first, "make default"). Keep `production.enabled` off until L2 is deployed. L6 (#91 P2 world API) builds on L1 and
   waits for this.
5. **Review:** L1 agent decisions (block 4.1), mainly: the game server computes territory and reports it; loyalty is a
   town id; the Town and District form seeds were not bumped (L3 adds the new fields to those forms).
6. Later: the shop menu templates for L26 (#687).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L0 Item identity: every obtainable item is a blueprint; generated "Uncurated" shadow blueprints (G4) | #141 | Merged into next (2026-11-19) | api `5daa3c6`, plugin `a6c5a2bc`, workspace `8ffdbb1a`; merges: api `7d213fd6`, plugin `2ef256e7`, workspace `ca3bcc98` | [api#51](https://github.com/PandiO/knk-web-api/pull/51), [plugin#89](https://github.com/PandiO/knk-plugin/pull/89), [ws#793](https://github.com/PandiO/knk-workspace/pull/793) | green (API PR checks; plugin build + paper-boot) | subagent of the coordinator (two repos besides knk-workspace, SKILL § 4.1.4.2), started 2026-11-19 |
| L1 Territory API: holders, crown land entity (G10), power, range (G11), conflicts, loyalty | #326 | Merged into next (2026-11-19) | api `ff50ec1`, workspace `c4211d51`; merges: api `0d6e369a`, workspace `4595e6d8` | [api#53](https://github.com/PandiO/knk-web-api/pull/53), [ws#798](https://github.com/PandiO/knk-workspace/pull/798) | green (build-and-test, mysql-tests, fresh-database) | create_session `session_01R1w2Uwo46dJVo6Cpr8LzmG` (one repo besides knk-workspace), started 2026-11-19 |
| L2 Territory plugin: chunk cache, lookup, BlueMap outlines | #689 | Running | — | — | — | create_session `session_01R1w2Uvhpo37DXAXpm2uqLp` (one repo besides knk-workspace), started 2026-11-19 |
| L3 Territory web app | #690 | Running | — | — | — | create_session `session_01R1w2UuYHneFJFXcn8GSe6F` (one repo besides knk-workspace), started 2026-11-19 |
| L4 P1 stock core API: storages, ledger, reconciler, capacity, roll-up | #97 | Not started | — | — | — | — |
| L5 P1b stock web app | #675 | Not started | — | — | — | — |
| L6 P2 world API: structure subtypes, TownId, placement rules | #91 | Not started | — | — | — | — |
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
