# Siege shop chain — progress report

**Status:** In review (all links in `next`, 2026-11-21) · **Last updated:** 2026-11-21

**Issue:** [PandiO/knk-workspace#611](https://github.com/PandiO/knk-workspace/issues/611) (with
[#356](https://github.com/PandiO/knk-workspace/issues/356) and [#859](https://github.com/PandiO/knk-workspace/issues/859)),
links [#866](https://github.com/PandiO/knk-workspace/issues/866) (L1), [#867](https://github.com/PandiO/knk-workspace/issues/867) (L2),
[#868](https://github.com/PandiO/knk-workspace/issues/868) (L3), [#869](https://github.com/PandiO/knk-workspace/issues/869) (L4),
[#870](https://github.com/PandiO/knk-workspace/issues/870) (L5), [#871](https://github.com/PandiO/knk-workspace/issues/871) (L6).
**Charter:** [handoffs/SIEGE_SHOP_CHAIN.md](../ai-agents/handoffs/SIEGE_SHOP_CHAIN.md).
**Coordinator:** the Siege weapons chain coordinator (session_01R1w2UuyXat2GBcJjHG3RRV) runs this chain too, on the
developer's instruction of 2026-11-20; its own report is [2026-11-19-siege-weapons-chain.md](2026-11-19-siege-weapons-chain.md).

## 1. Waiting for the developer

1. **Test in `next`** (smoke guide `docs/guides/siege-shop-smoke-test.md`): § 1 siege points (tier:3), § 2 catalogue
   (tier:2), § 3 shop in the plugin (tier:3), § 4 weapon unlocks (tier:2), § 5 menu item settings (tier:2; § 5.2
   step 8 waits for Siege Survival #41).
2. **Deploy steps:** migrations `AddSiegePointsEarning`, `AddSiegeShopCatalogue`, `AddMenuItemSettings`,
   `AddSiegeWeaponUnlockMinTitle`; restart the API once (catalogue and menu seeds); import the form seeds
   `SiegeShopCategory`, `SiegeShopEntry`, `SiegeScenarioShopOverride`, "SiegeWeaponTemplate - Default (seed v2)" (and add
   the new step/field by hand where `SiegeScenario` or `ItemBlueprint` forms were imported before); deploy the plugin
   before the API (L3); turn on `siege.points.enabled` and `siege.shop.enabled` together.
3. **Agent decisions to review:** § 4.1–4.6 of this report (each with alternatives).
4. **Docs:** #908, docs session session_01R1w2UvhedVnDCJtzAaf4xa (player and admin guide items gate deploys).
5. Siege weapons L3 #784 still needs #614 (schematic pipeline, no design); see the weapons report § 1.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Shared ledger, siege points earning | #866 | Merged into `next` 2026-11-20 (knk-web-api `9a3132dc`, knk-plugin `91e3ddb8`, knk-workspace `1e38c7ec`) | `claude/siege-shop-l1`: knk-plugin `b6fa74ec`, knk-web-api `4da6780`, knk-workspace `8a215193` | [knk-plugin#107](https://github.com/PandiO/knk-plugin/pull/107), [knk-web-api#64](https://github.com/PandiO/knk-web-api/pull/64), [knk-workspace#879](https://github.com/PandiO/knk-workspace/pull/879) | green (plugin build + paper-boot; API build-and-test, mysql-tests, fresh-database) | subagent of the coordinator (two component repos), started 2026-11-20 |
| L2 Shop catalogue (API, web app) | #867 | Merged into `next` 2026-11-20 (knk-web-api `aff345dd`, knk-web-app `6f494154`, knk-workspace `ea361394`) | `claude/siege-shop-l2`: knk-web-api `1bed630a`, knk-web-app `77791388`, knk-workspace `a31db5c7` | [knk-web-api#66](https://github.com/PandiO/knk-web-api/pull/66), [knk-web-app#69](https://github.com/PandiO/knk-web-app/pull/69), [knk-workspace#888](https://github.com/PandiO/knk-workspace/pull/888) | green (API build-and-test, mysql-tests, fresh-database; web app build-and-test, e2e) | subagent of the coordinator (two component repos), started 2026-11-20 |
| L3 Shop in the plugin | #868 | Merged into `next` 2026-11-20 (knk-plugin `c7e2ad4b`, knk-web-api `57277cdc`, knk-workspace `094495c4`) | `claude/siege-shop-l3`: knk-plugin `0620fd51`, knk-web-api `34a684d`, knk-workspace `87aefbbf` | [knk-plugin#109](https://github.com/PandiO/knk-plugin/pull/109), [knk-web-api#69](https://github.com/PandiO/knk-web-api/pull/69), [knk-workspace#896](https://github.com/PandiO/knk-workspace/pull/896) | green (plugin build + paper-boot pull-request run; push run of paper-boot failed once in `npc-road-goal-dead-end` (UNLOADED, not L3), rerun started; API build-and-test, mysql-tests, fresh-database) | subagent of the coordinator (decision 8), started 2026-11-20 |
| L4 Weapon unlocks | #869 | Merged into `next` 2026-11-20/21 (knk-web-api `fc1a5143`, knk-plugin `02a99b62`, knk-web-app `acff2134`, knk-workspace `28bd67f2`) | `claude/siege-shop-l4`: knk-web-api `3c2b1ba5`, knk-plugin `ab9bab6e`, knk-web-app `af584a77`, knk-workspace `66e22850` | [knk-plugin#111](https://github.com/PandiO/knk-plugin/pull/111), [knk-web-api#71](https://github.com/PandiO/knk-web-api/pull/71), [knk-web-app#71](https://github.com/PandiO/knk-web-app/pull/71), [knk-workspace#902](https://github.com/PandiO/knk-workspace/pull/902) | green | subagent of the coordinator (three component repos), started 2026-11-20 |
| L5 Menu item settings (API, web app) | #870 | Merged into `next` 2026-11-20 (knk-web-api `af21a10e`, knk-web-app `14ef5d05`, knk-workspace `a59eda2d`) | `claude/siege-shop-l5`: knk-web-api `478d1d61`, knk-web-app `9fa2b791`, knk-workspace `7ec5fa9f` | [knk-web-api#68](https://github.com/PandiO/knk-web-api/pull/68), [knk-web-app#70](https://github.com/PandiO/knk-web-app/pull/70), [knk-workspace#894](https://github.com/PandiO/knk-workspace/pull/894) | web app green; API green in the pull-request run, push run's mysql-tests red only in flaky #805 (rerun once) | subagent of the coordinator, started 2026-11-20 |
| L6 Menu item in the plugin | #871 | Merged into `next` 2026-11-21 (knk-plugin `ec02a64a`, knk-workspace `cf90aefd`) | `claude/siege-shop-l6`: knk-plugin `6f16b31c`, knk-workspace `dbc0789e` | [knk-plugin#112](https://github.com/PandiO/knk-plugin/pull/112), [knk-workspace#907](https://github.com/PandiO/knk-workspace/pull/907) | green (plugin build + paper-boot; workspace build); Codex at its usage limit | subagent of the coordinator, started 2026-11-21 |

## 3. Coordinator decisions

1. **Who coordinates.** Chosen: the Siege weapons coordinator runs this chain from the same session, because the
   developer said on 2026-11-20 "The design for #611 and #356 is finished. You can start implementation of the
   relevant phases ... plan the implementation phases ... and start if you consider ready", no shop coordinator
   exists (board and branches checked 2026-11-20), and the weapons chain waits for this one. The charter's phases
   and links are used as written. Alternatives: (a) a separate coordinator session through the manager, slower and
   the developer asked this session; (b) fold the shop links into the weapons charter, rejected (two parents, two
   smoke guides).
2. **Rule set.** Chosen: the `next` branch model (CI on `main` of knk-web-api and knk-web-app, unchanged since
   2026-11-19). Bases at the first run: API `next` `5e16ea0`, web app `287bb2c`, plugin `c7e36e6e`, workspace `5e4fb7b7`.
   Alternatives: none (the old rules apply only without CI).
3. **Link model.** Chosen: the coordinator's model for every link, set explicitly. Alternatives: a smaller model for
   tier:2 links, rejected for consistency.
4. **Route.** Chosen: subagents of the coordinator for every multi-repo link (L1, L2, L4, L5) per skill § 4.1.4.2;
   L3 and L6 (plugin only) may go `create_session`, decided when they start. Alternatives: `create_session` with
   `add_repo` for all, refused once by the Auto-mode classifier (#511).
5. **Order.** Chosen: L1 now; L2 after L1 (both change knk-web-api, one link per component repo); then L3 (plugin) and
   L5 (API, web app) together; then L4; then L6. The spec allows L2, L4 and L5 in parallel with L1, but they share
   knk-web-api with L1, and two migrations in flight in one chain would only add regenerations. Alternatives:
   (a) L5 in parallel with L1, rejected (both carry an API migration); (b) L2 first, rejected (charter order, and L1
   is the critical path for weapons L3).
6. **Overlap at L1 start (board fetched 2026-11-20).** Production (#22) runs L12 #679 on knk-plugin
   (`production` packages, `/knk production`, own `KnKPlugin`/`config.yml` blocks) and L14 #79 on knk-web-api (one
   migration). Chosen: not a blocker (different packages and entities); L1 keeps its `KnKPlugin`, `config.yml` and
   `KnKDbContext` edits in their own blocks, merges `origin/next` before the PR and generates its migration last
   (whoever merges second regenerates); the Production coordinator is told. Siege Survival (#41) is unmerged with no
   link running: L1 copies `MatchLedger` with the same public API (P11) and comments on #41 at merge. Alternatives:
   wait for Production's links, rejected (mechanical conflicts only).
7. 2026-11-20: L1 merged into `next` after the § 6 checks (heads matched, 0 behind `next`, migration `20261120131558_AddSiegePointsEarning` on top of `AddTransportCore`, CI green, Codex at its usage limit). L2 #867 started as a subagent; #878 (siege settings page earn fields) rides along in L2 because both touch knk-web-app. Production told about the migration.
8. 2026-11-20: L2 merged into `next` after the § 6 checks (heads matched, 0 behind, migration `20261120183543_AddSiegeShopCatalogue` after `AddSiegePointsEarning`, CI green, Codex at its usage limit; #878 closed by knk-web-app#69). Production told. L2's seven agent decisions (§ 4.2) wait for the developer's review; none blocks L3.
9. 2026-11-20: L3 #868 and L5 #870 started together. Route for L3 (plugin only): a subagent, not `create_session`. Chosen because this session already has every repo attached and two parallel subagents are checked the same way; alternative `create_session` with `add_repo`, whose attach the Auto-mode classifier refused once (#511).
10. 2026-11-20: L5 merged into `next` (API `af21a10e`, migration `20261120193455_AddMenuItemSettings` after Production's `AddStorageContainers`; web app `14ef5d05`; workspace `a59eda2d`). The API push run's mysql-tests failed twice only in the flaky #805 test, and the branch rule refused the merge; the coordinator reran the job (green) and merged. The PR run was green.
11. 2026-11-20: L3 merged into `next` (plugin `c7e2ad4b`, API `57277cdc`, workspace `094495c4`). L3 also changed knk-web-api (menu seeds and telemetry entry, no migration), which the scope did not list: accepted, because the spec puts the menus in API seeds (§ 7.2.3). The plugin's push-run paper-boot failed once in the flaky NPC scenario `npc-road-goal-dead-end` and passed on rerun. Merged L5's workspace PR first; L3's smoke-guide header conflict was then resolved by the L3 agent (both sides kept). Deploy order: plugin before the API (L3 decision 2).
12. 2026-11-20: L4 #869 started (subagent, knk-web-api + knk-plugin + knk-web-app), covering #795. It adds the Minigames → Siege unlocks main-menu entry, which Production L18 #74 also touches; both coordinators told each other and the link keeps its menu in its own seed block. Weapons chain: shop L1–L3 are now in `next`, so weapons L3 #784 waits only for #614.
13. 2026-11-21: L4 merged into `next` (API `fc1a5143` with migration `20261120231505_AddSiegeWeaponUnlockMinTitle`, closes #795; web app `acff2134`; workspace `28bd67f2`; plugin `02a99b62`). Plugin `next` had moved to Production L18 (`8e672ba6`, regenerated `content-seeds.json`); `git merge-tree` with L4 was clean, so no regeneration was needed. L4 put the Siege unlocks button in `siege.overview` instead of a new main-menu entry (L4 decision 1), so it did not overlap Production L18. Production told about the migration and about L6.
14. 2026-11-21: L6 #871 started (subagent, plugin only, same route as L3). Production confirmed L18 does not touch the menu item path. L6 also fixes L3's locked-weapon text to name the real path (/menu → Siege Minigame → Siege unlocks); a one-string change, in scope because L6 is the last plugin link.
15. 2026-11-21: L6 merged into `next` (plugin `ec02a64a`; workspace `cf90aefd` after the link merged `next` again for a changelog conflict). All six links are in `next`; chain status In review. Docs sub-issue #908 and docs session session_01R1w2UvhedVnDCJtzAaf4xa started per "Shipping a change". The feature issues (#611, #356, #859) close when the developer promotes `next`.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — Shared ledger and siege points (#866)

1. **Scope done.**
    1. knk-plugin knk-core: `MatchLedger`, `LedgerResult` and `MatchLedgerTest` copied from `claude/siege-survival` (`ba074b8c`) into `core/siege/economy/` with the same public API (P11); new `SiegePointsSettings` (on `KnkSiegeConfiguration`), `SiegePointsEarnCalculator` (kill × capped streak, assist, death, gate damage, capture progress both directions, capture, active trickle), `AssistTracker`, `SiegePointsEconomy` (totals, `credit` hook for #612, transfers behind the switch, `charge` for L3), `SiegePointsText`; `ParticipantResult` gains nullable `siegePointsEarned/Spent` (also in the result spool).
    2. knk-plugin knk-api-client: the 13 `SiegeConfiguration` fields in the runtime config (defaults when an older API omits them); the two totals in the complete payload, omitted when null.
    3. knk-plugin knk-paper: `siege/points/` (`SiegePointsService` observer, `SiegePointsDamageListener` MONITOR for assists, `SiegePointsTelemetry` `siege.points_earned`); `SiegeMatchObserver` default hooks `memberDied`, `gateDamaged` fired from `SiegeService`; `SiegeService.ResultExtras` for the result totals; `SiegeScoreboardPresenter` per-player boards only with a `PersonalLine`; `SiegeCommand` `/siege points`, `/siege pay`; `KnKPlugin.initializeSiegePoints()` in its own block; `config.yml` `siege.points.enabled: false`; `plugin.yml` usage string.
    4. knk-web-api: `SiegeConfiguration` earn columns and `PointTransfersEnabled` (DTOs, partial update, validation), `SiegeMatchParticipant.SiegePointsEarned/Spent` (complete, participant DTO), telemetry catalog `siege.points_earned`, migration `20261120123323_AddSiegePointsEarning` (additive; existing config row gets the design defaults).
    5. knk-workspace (branch, PR into `next`): smoke guide § 1 rewritten and tagged (17 of 19 steps automated or partly), changelog Unreleased entry, plugin configuration § 4.13 and § 2.1 rows.
2. **Commits and heads.** knk-plugin `claude/siege-shop-l1` at `419c1a30` (4 commits incl. a merge of `next` `3da2dffc`; base `next` `c7e36e6e`); knk-web-api `claude/siege-shop-l1` at `91f4b19` (2 commits incl. a merge of `next` `4f4580b`; base `5e16ea0`); knk-workspace `claude/siege-shop-l1` at `7eb975d2` (2 commits, base `next` `2159952e`).
3. **PRs.** [knk-plugin#107](https://github.com/PandiO/knk-plugin/pull/107) (Closes #866), [knk-web-api#64](https://github.com/PandiO/knk-web-api/pull/64), [knk-workspace#879](https://github.com/PandiO/knk-workspace/pull/879) (both Part of #866), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin: baseline on `next` 7192 tests, 20 skipped, 0 failed; result after merging `next` 7258 tests, 20 skipped, 0 failed (53 new). CI build and paper-boot green on `419c1a30` (runs 44738065902, 44738066033).
    2. knk-web-api: baseline 4826 passed, 117 skipped (MySQL), 0 failed; result after merging `next` 4845 passed, 118 skipped, 0 failed (15 new). CI build-and-test, mysql-tests and fresh-database green on `91f4b19` (runs 44738119124, 44738119015).
    3. Known reds: none. Codex: usage limit on all three PRs (noted on each PR), no review.
    4. Flag off proven by `SiegeScoreboardPresenterPointsTest` (per-team boards, same lines), `SiegeCommandPointsTest`, `SiegeMatchesCommandApiImplTest.complete_sendsSiegePointsOnlyWhenTheyWereCounted_866`.
5. **Decisions (DESIGN § 4.3).**
    1. *Per-player boards only with the flag on.* Chosen: flag off keeps today's per-team boards, so P18 cannot change anything while off. Alternatives: (a) always split with identical lines, more boards and N² tab updates for nothing.
    2. *Trickle activity (P17).* Chosen: active = dealt damage or killed, damaged a gate, stood in a capture radius, or walked 10+ blocks in the interval, never while statistics-AFK (AFK starts after 300 s idle, so "not AFK" alone pays a player at spawn). Alternatives: (a) contributions' active time only; (b) a move listener, per-event cost.
    3. *Telemetry shape (P27).* Chosen: `siege.points_earned` (catalog names allow one dot, so not `siege.points.earned`), multiplier key `factor` (the catalog refuses keys containing "ip"), gate damage and capture progress summed per player per minute. Alternatives: (a) one event per credit, up to one per player per second.
    4. *Result screen.* Chosen: a chat line with earned/spent at match end plus the API totals, not new fields in `SiegeResultMessage`. Alternatives: (a) extend the result hover (shared class).
    5. *Earned/spent.* Chosen: Survival's `MatchEconomy` meaning (earned = play + transfers in, spent = charges + transfers out). Alternatives: (a) play only, would differ from Survival's result row.
    6. *Assists on environment deaths.* Chosen: pay assists also when there is no killing player. Alternatives: (a) only with a killer.
    7. *Leaving.* Chosen: any leave during the match (also a quit with a rejoin slot) drops the balance, as the roster already drops stats; totals stay for the result. Alternatives: (a) keep the balance through a rejoin, needs state the roster doesn't keep.
    8. *Migration defaults.* Chosen: the existing `SiegeConfiguration` row gets the § 5.2 defaults in the migration (precedent `AddSiegePostMatchSeconds`). Alternatives: (a) EF's 0 defaults, would make the streak cap invalid.
    9. *No paper-boot scenario.* Chosen: unit, MockBukkit/Mockito and API tests plus tagged smoke steps; a scripted PvP match with kills isn't in the scenario framework. `MIN_SCENARIOS` untouched.
6. **Out of scope, noted.** #878 filed (web app siege settings page fields; L2 or L5 could take it). Comment on #41 (ledger moved, public API unchanged; `SiegeCommand` `pay` case collision and the Survival transfer column at its merge).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply knk-web-api migration `AddSiegePointsEarning` before turning the flag on.
    2. To try it: plugin `config.yml` `siege:` → `points:` → `enabled: true`, restart; edit amounts or `pointTransfersEnabled` with `PUT api/SiegeConfiguration` until #878.
    3. Smoke test § 1 of `docs/guides/siege-shop-smoke-test.md` (steps 18–19 and the by-hand parts are manual).
9. **Notes for later links.**
    1. L3 (#868): charge through `SiegePointsEconomy.charge(chargeId, player, price, product)` from `SiegePointsService.economyOf(match)`; `spent` is counted there. Purchase telemetry needs its own catalog line (keys must not contain "ip", "key", etc.).
    2. L2/L5: #878 (siege settings page fields) fits either.
    3. Whoever merges a knk-web-api migration after L1 regenerates theirs (or L1 regenerates if it merges second).
10. **2026-11-20, update after the coordinator's check.** `origin/next` merged into all three branches (merge commits with trailers). knk-web-api: `AddSiegePointsEarning` regenerated on top of Production's `AddTransportCore` (now `20261120131558_AddSiegePointsEarning`, Up/Down unchanged, existing settings row still gets the § 5.2 defaults; L17 #683 had not landed in `next`). knk-workspace: CHANGELOG and plugin-configuration conflicts resolved by keeping both sides. New heads: knk-plugin `b6fa74ec`, knk-web-api `4da6780`, knk-workspace `8a215193`, each 0 behind `next`. Tests: plugin 7303 tests, 20 skipped, 0 failed; API 4879 passed, 119 skipped, 0 failed. CI green: API build-and-test, mysql-tests, fresh-database; plugin build and paper-boot (the push run of paper-boot failed once in the NPC scenario `npc-road-goal-dead-end`, chunk UNLOADED, not touched by L1; it passed on rerun and in the pull-request run of the same head). Codex still at its usage limit after `@codex review`.

### 4.2 L2 — Shop catalogue (#867)

1. **Scope done.**
    1. knk-web-api: `SiegeShopCategory` (seeded `siege-weapons`, `consumables`, `magic` with `HasData`), `SiegeShopEntry` (game mode, optional scenario for scenario-only entries, category, kind `Item` with blueprint and quantity or `SiegeWeapon` with template, display name, icon, price and the § 5.4 brake fields, order, enabled), `SiegeScenarioShopOverride` (hidden plus nullable price, quantity, cap, cooldown, steps, order; unique per scenario and entry); CRUD under `knk.siege.admin.manage` (overrides under `api/SiegeScenarios/{id}/shop-overrides`), `GET api/SiegeShop/catalogue?mode=&scenarioId=` (§ 5.3, weapon price from `MatchPrice`), dashboard registry, lookups, pinned access tests, form seeds (and a "Siege shop" step on the scenario form, `PotionType` on the blueprint form), `ItemBlueprint.PotionType` (DESIGN § 9.4: no potion field existed), startup seed `SiegeShopSeed` (§ 12.2), migration `20261120183543_AddSiegeShopCatalogue` (additive: three tables, the categories, one nullable column), generated last on top of `next` `9a3132d`.
    2. knk-web-app: shop DTO types, clients (category, entry, override, catalogue), `entityApiMapping`, dashboard columns, scenario DTO lists, `potionType`; #878: "Siege points" section on the Siege settings page with L1's 13 fields, help texts and API ranges.
    3. knk-workspace (branch, PR into `next`): smoke guide § 2 rewritten and tagged (11 of 14 steps automated or partly), changelog Unreleased entry.
2. **Commits and heads.** knk-web-api `claude/siege-shop-l2` at `1bed630a` (2 commits, base `next` `9a3132dc`); knk-web-app at `77791388` (1 commit, base `next` `eaf0467`); knk-workspace at `a31db5c7` (1 commit on `next` `35e95fbb`). All 0 behind `next` at hand-back.
3. **PRs.** [knk-web-api#66](https://github.com/PandiO/knk-web-api/pull/66) (Closes #867), [knk-web-app#69](https://github.com/PandiO/knk-web-app/pull/69) (Part of #867, Closes #878), [knk-workspace#888](https://github.com/PandiO/knk-workspace/pull/888) (Part of #867), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: 4879 passed, 119 skipped (MySQL), 0 failed → 4936 passed, 119 skipped, 0 failed (57 new). A14, A15, A16 tests seen failing against a broken rule.
    2. knk-web-app: Jest 338 suites / 2882 tests → 339 / 2889; tsc, `typecheck:e2e`, build clean; Playwright 296 → 303 passed.
    3. CI: green on all heads: knk-web-api build-and-test, mysql-tests, fresh-database; knk-web-app build-and-test, e2e (pull-request and push runs).
    4. Known reds: none. Codex: usage limit on all three PRs (noted on each), no review.
5. **Decisions (DESIGN § 4.3).**
    1. *Default entries as a startup seed.* Chosen: categories in the migration, entries in `SiegeShopSeed` per mode only while that mode has no default entry, because entries point at blueprints whose ids exist only at runtime and admin edits must not be overwritten. Alternatives: (a) all in the migration, blueprints and material refs can't be made there; (b) re-seed missing rows each start, fights deletions.
    2. *Weapon entries.* Chosen: one PvP entry per weapon template existing when the seed runs (none on a fresh database; admins add them later). Alternatives: (a) seed three templates, changes the weapon data beyond the spec.
    3. *Potion field.* Chosen: one nullable `PotionType` registry key (strong_/long_ variants are keys; drink/splash from the material); null clears like the trim. Alternatives: (a) effect, level and duration fields, more than vanilla potions need.
    4. *Override routes.* Chosen: created and listed under the scenario like weapon spots. Alternatives: (a) a flat POST with the scenario in the body.
    5. *Catalogue read rule.* Chosen: `SiegeShopEntry` read nodes or the plugin key, pinned in `PluginReads`. Alternatives: (a) any signed-in user.
    6. *Weapon flag (§ 5.3.4).* Chosen: the API always lists weapon entries; the plugin drops them while `siege.weapons.enabled` is off. Alternatives: (a) a query flag, the API can't see the plugin config.
    7. *Rules the spec left open.* Chosen: weapon entries quantity 1; cooldown step or max need a base cooldown; overrides only on default entries, one per scenario and entry; a category in use can't be deleted. Alternatives: (a) accept and ignore such values silently.
    8. *Scenario-only entries on the scenario form.* Chosen: a second owned list "Scenario-only entries" next to "Shop overrides" (§ 4.4.2 "add a scenario-only entry"). Alternatives: (a) only from the entries dashboard with the scenario picked.
6. **Out of scope, noted.** None filed.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply migration `AddSiegeShopCatalogue`; restart the API once (seed).
    2. Import form seeds `SiegeShopCategory`, `SiegeShopEntry`, `SiegeScenarioShopOverride`; add the "Siege shop" step and "Potion type" field by hand where `SiegeScenario`/`ItemBlueprint` were imported before.
    3. Smoke test § 2 of `docs/guides/siege-shop-smoke-test.md` (steps 9 and the wizard parts of 5, 7, 10, 11 are manual).
9. **Notes for later links.**
    1. L3 (#868): read `GET api/SiegeShop/catalogue?mode=Siege|SiegeSurvival&scenarioId=` once per match (already in `ReadAccessRulesTests.PluginReads`); `price` is resolved, override fields applied, `source` tells Default/Overridden/Scenario; drop `SiegeWeapon` entries while `siege.weapons.enabled` is off; growth factor null means 1.5.
    2. L3: `BlueprintItemAssembler` must apply `ItemBlueprint.potionType` (`minecraft:strong_healing`) to potion meta; the plugin DTO doesn't read it yet.
    3. A fresh database has no weapon entries (no templates); the weapons chain or admins add them.

### 4.3 L3 — Shop in the plugin (#868)

1. **Scope done.**
    1. knk-plugin knk-core `core/siege/shop/`: `ShopCatalogue` (frozen per match, empty categories dropped, `withoutWeapons()`), `ShopBrakes` (§ 5.4 price and cooldown steps with the four curves, maxima, cap; missing growth factor = 1.5), `ShopPurchaseService` (§ 5.5 check order, charge id `shop:{matchId}:{player}:{entryId}:{n}`, reversal `:reversal`), the `ShopPurchaseHandler` port with `ShopPurchaseTicket` for #784, `SiegePointsShopWallet` (L1's `SiegePointsEconomy`, new `reverseCharge`), menu views and ids; port `SiegeShopApi`.
    2. knk-plugin knk-api-client: `SiegeShopApiImpl` (catalogue, weapon unlocks by user, plugin key); `ItemBlueprintReadDto.potionType` and mapper.
    3. knk-plugin knk-paper `siege/shop/`: `SiegeShopService` (catalogue read once at match start, two retries; weapons dropped while `siege.weapons.enabled` is off; items built once; unlocks per member; `registerHandler` for #784; `addMatchSource` Survival hook), `ItemPurchaseHandler`, `SiegeShopMenuFeature` (always registered), `SiegeShopTelemetry` (`siege.shop_purchase`); `/siege shop`; `KnkItemBlueprint.potionType` applied in `ItemBlueprintBukkitMapper`; `KnKPlugin.initializeSiegeShop()` in its own block; `config.yml` `siege.shop.enabled: false`; `plugin.yml` usage.
    4. knk-web-api (not in the charter's repo list, see decision 1): menu seeds `siege.shop`, `siege.shop.category` and the Shop button in `siege.information` (`AddSiegeShopButtonAsync` adds it once to older databases), telemetry catalog line `siege.shop_purchase`; no migration.
    5. knk-workspace (branch, PR into `next`): smoke guide § 3 rewritten (19 steps, 16 tagged), changelog Unreleased entry with the YAML, plugin configuration § 4.13 and § 2.1 rows.
2. **Commits and heads.** knk-plugin `claude/siege-shop-l3` at `0620fd51` (3 commits incl. a merge of `next` `7116f1a5`; base `91e3ddb8`); knk-web-api at `34a684d` (2 commits incl. a merge of `next`, `MenuTemplateSeed.cs` conflict with Production's hub tile repair resolved keeping both; base `aff345d`); knk-workspace at `87aefbbf` (2 commits incl. a merge of `next`, CHANGELOG conflict resolved keeping both). All 0 behind `next` at hand-back.
3. **PRs.** [knk-plugin#109](https://github.com/PandiO/knk-plugin/pull/109) (Closes #868), [knk-web-api#69](https://github.com/PandiO/knk-web-api/pull/69), [knk-workspace#896](https://github.com/PandiO/knk-workspace/pull/896) (both Part of #868), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin: baseline on `next` `91e3ddb8` 7303 tests, 20 skipped, 0 failed; result after merging `next` 7374 tests, 20 skipped, 0 failed (41 new, 30 from `next`).
    2. knk-web-api: 4936 passed, 119 skipped (MySQL), 0 failed → 4942 passed (6 new); after merging `next` 4975 passed, 119 skipped, 0 failed.
    3. Flag off proven by `SiegeShopMenuFeatureTest.withTheShopOffTheButtonIsHiddenAndTheActionsSaySo`, `SiegeCommandShopTest.withTheShopOffTheSubcommandIsHiddenAndSaysSo`, the seed contract test and `MenuTemplateSiegeSeedTests.Information_HasAShopButton_ShownOnlyWhileTheViewerCanUseAShop_868` (no other header item moved).
    4. Known reds: none. CI green on all heads (plugin build and paper-boot pull-request run on `0620fd51`; the push run of paper-boot failed once in the known flaky NPC scenario `npc-road-goal-dead-end`, chunk UNLOADED, not touched by L3, rerun started; API build-and-test, mysql-tests, fresh-database). Codex at its usage limit on all three PRs (noted on each).
5. **Decisions (DESIGN § 4.3).**
    1. *knk-web-api change in a plugin-only link.* Chosen: a small API PR (menu seeds and one telemetry catalog line, no migration), because DESIGN § 7.2.3 puts the menus in `MenuTemplateSeed.Siege`, the menus are API data, and the catalog drops unknown events. Alternatives: (a) plugin-side fallback menus, not how siege menus work; (b) defer to a follow-up, leaves A17 and A11 unbuilt. L5 runs on knk-web-api at the same time but touches `GameSettings`, not these files.
    2. *Balance not in the title.* Chosen: a header item with "Siege points: N", because the menu engine's titles are fixed text. Alternatives: (a) extend the engine with title variables, a shared engine change.
    3. *Shop button condition.* Chosen: a new `siege.shop-available` render condition, registered always, false with the flag off. Alternatives: (a) reuse `siege.phase` + `siege.participating`, would show the button with the shop off.
    4. *Existing databases.* Chosen: `AddSiegeShopButtonAsync` adds the button once when no item runs `siege.shop.open` and slot 0 is free. Alternatives: (a) an admin step by hand; (b) no repair. Note: an admin who deletes the button gets it back at the next start; hide it by editing its condition instead.
    5. *Deploy order.* The plugin must be deployed before the API seeds (an older plugin would block `siege.information` at validation); in the changelog, PRs and smoke guide.
    6. *Shop needs siege points.* Chosen: `siege.shop.enabled` without `siege.points.enabled` logs a warning and stays off. Alternatives: (a) a shop with a zero balance.
    7. *Weapon entries before #784.* Chosen: listed (with `siege.weapons.enabled`), locked ones show "Locked: unlock it in /menu → Minigames → Siege unlocks." (A26, unlocks read per member at match start via `UserSiegeWeaponUnlocks/by-user`), unlocked ones refuse "Siege weapons can't be bought yet." until #784 registers its handler. Alternatives: (a) hide all weapon entries until #784, A26 untestable.
    8. *Catalogue fetch failure.* Chosen: two retries 5 s apart, then no shop for that match ("isn't available") and one warning. Alternatives: (a) retry for the whole match, risks a mid-match catalogue.
    9. *Buyer alive.* Chosen: dead or spectator members are refused ("only while you are alive"). Alternatives: (a) allow buying on the death screen.
    10. *Retry id after a reversal.* Chosen: the next charge of the same purchase number gets `:again<k>`, so the ledger does not replay the reversed charge. Alternatives: (a) the plain id, would give the item for free on replay.
    11. *Survival hook.* Chosen: `SiegeShopService.addMatchSource(playerId -> Optional<ShopPurchaseService>)`; Survival supplies its wallet adapter and membership at its merge (comment on #41). Alternatives: (a) a Survival-specific interface in this link, would guess at unmerged code.
    12. *Not built: the Give points button (`siege.points.give`).* Filed #895; `/siege pay` covers transfers.
    13. *Main menu untouched* (coordinator note, Production L18 #74 runs on knk-plugin): the shop is reached only from `/siege shop` and the Shop button in `siege.information`.
    14. *No paper-boot scenario.* A scripted match with purchases is not in the scenario framework; `MIN_SCENARIOS` untouched.
6. **Out of scope, noted.** #895 (Give points button). Comment on #41 (`/siege buy` rename and the match-source hook).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Deploy the plugin before knk-web-api#69; restart the API once (menu seeds, Shop button).
    2. `config.yml` under `siege:`: `points: enabled: true` and `shop: enabled: true` (Restart).
    3. Smoke test § 3 of `docs/guides/siege-shop-smoke-test.md` (steps 12, 17–19 and the by-hand parts are manual).
9. **Notes for later links.**
    1. #784: implement `ShopPurchaseHandler` for `SIEGE_WEAPON` (`checkDelivery` for spot checks, `fulfil` opens the spot picker and returns `Started`, then `ticket.charge()` after the placement checks, `ticket.reverse()` if the paste fails) and call `SiegeShopService.registerHandler` (get it from `KnKPlugin`'s `siegeShop` field).
    2. L4 (#869): after an unlock purchase the shop reads unlocks only at match start (and on rejoin); unlocks are refused during a match anyway (A28). `SiegeShopApi.unlockedWeaponTemplates` exists for reuse.
    3. L6 (#871): the menu item's `siege.match` shift-right action can open `siege.shop` (or run `siege shop`, which gives the loading/unavailable messages).

### 4.4 L5 — Menu item settings (#870)

1. **Scope done.**
    1. knk-web-api: `GameSettings.MenuItemSettingsJson` and the `menuItem` section of `GET`/`PUT api/GameSettings` (`MenuItemSettingsDto`, `MenuItemActionDto`; null on update keeps it): enabled, give to all/bedrock, give on join, keep on death, material, name, lore, slot, droppable, movable, `clicks` (click type → action) and `overrides` (situation → partial clicks). `Services/MenuItemSettings.cs` holds the fixed lists (clicks `LEFT_CLICK`, `RIGHT_CLICK`, `SHIFT_LEFT_CLICK`, `SHIFT_RIGHT_CLICK`, `INVENTORY_CLICK`; actions `OpenMenu`, `RunCommand`, `None`; situations `siege.survival.match`, `siege.match`, `siege.hub`, most specific first), the seeded defaults and validation with `menuItem.…` reasons. A save sends `GameSettingsChanged` (existing realtime map). Migration `20261120193455_AddMenuItemSettings` (additive: one nullable longtext column), regenerated last on `next` `a2865d7` after Production's `AddStorageContainers`. Access unchanged (no new endpoint).
    2. knk-web-app: Menu item card on the game settings page (`MenuItemCard.tsx`, `utils/menuItemSettings.ts`): look fields with the colour preview, click table (Open menu with a key picker, Run command, Nothing), situation overrides with "Use default", Remove and Add override, inline checks that keep Save off, one change group.
    3. knk-workspace (branch, PR into `next`): smoke guide § 5 rewritten: § 5.1 seven steps for phase 5a, all tagged; § 5.2 in-game draft kept for #871. Changelog Unreleased entry.
2. **Commits and heads.** knk-web-api `claude/siege-shop-l5` at `478d1d61` (3 commits incl. a merge of `next` `a2865d7`; base `aff345dd`); knk-web-app at `9fa2b791` (2 commits incl. a merge of `next` `5ad5029`, conflict in `canSave` resolved by keeping both checks; base `6f494154`); knk-workspace at `7ec5fa9f` (2 commits incl. a merge of `next` `3dc4267c`; base `ea361394`). All 0 behind `next` at hand-back.
3. **PRs.** [knk-web-api#68](https://github.com/PandiO/knk-web-api/pull/68) (Closes #870), [knk-web-app#70](https://github.com/PandiO/knk-web-app/pull/70), [knk-workspace#894](https://github.com/PandiO/knk-workspace/pull/894) (both Part of #870), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: 4936 passed, 119 skipped (MySQL), 0 failed → 4959 passed, 119 skipped, 0 failed (23 new); after merging `next`: 4992 passed, 119 skipped, 0 failed.
    2. knk-web-app: Jest 339 suites / 2889 tests → 340 / 2894; tsc, `typecheck:e2e`, build clean; Playwright 303 → 309 passed (6 new in `menu-item-settings.spec.ts`); after merging `next`: Jest 342 / 2906, Playwright 325 passed.
    3. CI: first heads green everywhere (API build-and-test, mysql-tests, fresh-database; web app build-and-test, e2e). Merge heads: web app green; API green in one run, the other run's build-and-test failed in `RealtimeHubTests.WebHub_WithBearer_JoinsTheUserGroup_AndReceivesPublishedMessages` (10 s timeout, not touched by L5, passed in the parallel run and locally) and mysql-tests in the known flaky `DiscoveryLedgerMySqlTests.TitleCrossing_PostsTheXpOnceAndAppliesTheBonusOnce` (#805); rerun once: build-and-test green, mysql-tests failed again in the same #805 test only. Every check is green in at least one run of `478d1d61` (pull-request run 44804108996 all green).
    4. Codex: usage limit on all three PRs (noted on each), no review; `@codex review` posted again after the merges.
5. **Decisions (DESIGN § 4.3).**
    1. *Seeds as read defaults.* Chosen: a null column reads as `MenuItemSettings.Defaults()`. Alternatives: (a) the migration writes the JSON, duplicates the defaults and misses databases without a row; (b) a startup seed, more code for the same result.
    2. *Shift clicks in the default table.* Chosen: shift-left and shift-right open `main` too, because today a shift-click is a plain click to the plugin ("as today"). Alternatives: (a) leave them unset per the literal § 4.3.4 list, a shift-click outside a match would stop opening the menu; (b) an implicit shift → plain fallback in the plugin, a hidden rule.
    3. *Shape.* Chosen: dictionaries as § 6.1.8 words it (`clicks` click → action, `overrides` situation → partial clicks), JSON keys as written (`LEFT_CLICK`, `siege.match`). Alternatives: (a) lists of rows, more duplicate checks.
    4. *Menu key check.* Chosen: format only. Alternatives: (a) must exist as a `MenuTemplate`, would refuse the seeded `siege.shop` until L3 lands.
    5. *Run command.* Chosen: any one-line player command, leading slash dropped. Alternatives: (a) an allow-list, too narrow.
    6. *Empty overrides.* Chosen: dropped on save. Alternatives: (a) kept, no behaviour difference.
    7. *Menu key picker.* Chosen: a datalist of `main`, `siege.information`, `siege.shop`, `siege.overview` plus free text. Alternatives: (a) a new `api/MenuTemplates` client, more scope and still missing code-only menus.
6. **Out of scope, noted.** None filed.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply migration `AddMenuItemSettings`. Nothing changes in game until L6 #871.
    2. Smoke test § 5.1 of `docs/guides/siege-shop-smoke-test.md` (all steps tagged; step 6 needs a connected game server to see the event).
9. **Notes for later links.**
    1. L6 (#871): read `menuItem` from `GET api/GameSettings` (always present, defaults when unset) and reload it on `GameSettingsChanged` (scope `Game`). Situation order to check: `MenuItemSettings.Situations` (survival match, match, hub). A click missing from an override uses `clicks`; a click missing from `clicks` does nothing. `RunCommand` text has no slash. `giveTo` is lower case `all`/`bedrock`; material is upper case without `minecraft:`. `INVENTORY_CLICK` only while `movable` is false (card hint says so).
    2. L6: the `siege.information` key needs the lobby context the plugin already adds for `/siege menu`; `siege.shop` exists once L3 is merged.
    3. L4 (#869) and L6: L5's migration is the latest of this chain in knk-web-api; whoever merges after Production's next migration regenerates.

### 4.5 L4 — Weapon unlocks (#869)

1. **Scope done.**
    1. knk-web-api: `POST api/SiegeWeaponUnlocks/purchase` `{ templateId, userId? }` (plugin key for the named player; a signed-in web user only for themselves, 403 otherwise): under the player's row lock it checks unlocked already (200 `alreadyUnlocked`, nothing charged), title level (409 `NeedsTitle`), coins (409 `InsufficientFunds`), then spends `SIEGE_UNLOCK` (new reason, to `SYS_SIEGE`) with key `siege-unlock:{templateId}:{userId}` and writes the `UserSiegeWeaponUnlock` row in the same transaction (the kit pattern, `KitService.PurchaseKitAsync`); a free type unlocks without a posting. `GET api/SiegeWeaponUnlocks/mine` (`[Authorize]`) and `by-user/{userId}` (plugin key): every template with price, minimum title, state, coins and title. `SiegeWeaponTemplate.UnlockMinTitleLevel` (TitleBracket id, nullable, Restrict FK), DTOs, validation, form seed SiegeWeaponTemplate v2. Menu seed `siege.unlocks` (`MenuTemplateSeed.SiegeUnlocks.cs`) and its Siege unlocks button in `siege.overview`'s header (`AddSiegeUnlocksButtonAsync` once for older databases). Migration `20261120231505_AddSiegeWeaponUnlockMinTitle` generated last on `next` `57277cdc` after `AddMenuItemSettings`. #795's proposal is met (check before charging, atomic, plugin key); the knk-web-api PR closes it.
    2. knk-plugin: knk-core `core/siege/unlocks/` (row and header views, ids, texts, results), port `SiegeWeaponUnlocksApi`; knk-api-client `SiegeWeaponUnlocksApiImpl`; knk-paper `siege/unlocks/SiegeUnlocksMenuFeature` (root `siegeUnlocks`, rows `siege.unlocks`, action `siege.unlocks.buy` refused during a running match, condition `siege.unlocks.purchase-pending`), one additive hunk in `KnKPlugin`; `siege-seeds.json` regenerated; `content-seeds.json` untouched.
    3. knk-web-app: `MySiegeUnlocksSection` on the account page (list, confirm, one request per double click, refusal reason), `siegeWeaponUnlockClient`, DTOs, `Controllers.SiegeWeaponUnlocks`, template DTO fields; `e2e/siege-unlocks.spec.ts`.
    4. knk-workspace (branch, PR into `next`): smoke guide § 4 rewritten (9 steps, 8 tagged), changelog Unreleased entry.
2. **Commits and heads.** knk-web-api `claude/siege-shop-l4` at `3c2b1ba5` (3 commits; base `57277cdc`); knk-plugin at `ab9bab6e` (1 commit; base `c7e2ad4b`); knk-web-app at `af584a77` (1 commit; base `14ef5d0`); knk-workspace at `66e22850` (1 commit; base `094495c4`). All 0 behind `next` at hand-back.
3. **PRs.** [knk-plugin#111](https://github.com/PandiO/knk-plugin/pull/111) (Closes #869), [knk-web-api#71](https://github.com/PandiO/knk-web-api/pull/71) (Closes #795, Part of #869), [knk-web-app#71](https://github.com/PandiO/knk-web-app/pull/71), [knk-workspace#902](https://github.com/PandiO/knk-workspace/pull/902) (Part of #869), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: 4998 passed, 119 skipped (MySQL), 0 failed → 5019 passed, 119 skipped, 0 failed (21 new).
    2. knk-plugin: 7374 tests, 20 skipped, 0 failed → 7391, 20 skipped, 0 failed (17 new).
    3. knk-web-app: Jest 342 / 2906 → 342 / 2906; tsc, `typecheck:e2e`, build clean; Playwright 324 passed + 1 known flaky (`data-table.spec.ts` header sort) → 330 passed (5 new).
    4. CI: see the PRs all checks green on every head: knk-web-api build-and-test, mysql-tests, fresh-database; knk-plugin build and paper-boot (pull-request run; the push run was still running at hand-back); knk-web-app build-and-test, e2e. Codex at its usage limit on all four PRs (noted on each), no findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *Where the menu hangs.* Chosen: a Siege unlocks button in `siege.overview`, the menu the main menu's Siege Minigame tile (the only minigames tile) opens, so the path is /menu → Siege Minigame → Siege unlocks and the hub seed (shared with Production L18) is untouched. Alternatives: (a) a new hub tile, a hunk in `MenuTemplateSeed.Content.cs` and `content-seeds.json` next to L18's; (b) a new "Minigames" menu between hub and siege, renames the tile players know.
    2. *What "title level" stores.* Chosen: the TitleBracket id (v1's title levels, ids 0–18 in XP order) with a Restrict FK, checked as XP ≥ that bracket's minimum like `Kit.MinTitleBracketId`; 0 or empty = none. Alternatives: (a) a 1-based rank without FK, breaks silently when brackets change; (b) a minimum XP number, not a title.
    3. *A28 in the API.* Chosen: the game server refuses during a running match (`SiegeService.runningMatchOf`); the API does not, because it has no reliable live-match state per player and an unlock bought mid-match is read only at the next start. Alternatives: (a) refuse when the user has a participant row in an `InProgress` match, a crashed match would block unlocks for good.
    4. *Repeat purchase.* Chosen: 200 with `alreadyUnlocked` and nothing charged. Alternatives: (a) 409, a double click would show an error after a success.
    5. *A revoked unlock bought again.* Chosen: the spec's once-ever key means the ledger replays the first spend, so a player whose unlock staff deleted gets it back without paying twice. Alternatives: (a) a new key per purchase, charges twice for one type.
    6. *Rate limit.* Chosen: none, like the kit purchase (the per-IP policies would put every player behind the game server's IP; the key makes repeats harmless). Alternatives: (a) `LookupPolicy`, throttles the whole server.
    7. *Plugin read.* Chosen: a new `GET api/SiegeWeaponUnlocks/by-user/{userId}` (plugin key) with the same overview shape as `mine`, so title and states are computed once in the API. Alternatives: (a) compose templates, unlocks and the title in the plugin, duplicates the title rule.
    8. *Rows that can't be unlocked.* Chosen: their click goes straight to `siege.unlocks.buy`, which answers with the API's reason (title, coins, already unlocked) or the match refusal; only unlockable rows ask to confirm. Alternatives: (a) no action on those rows, a click says nothing.
6. **Out of scope, noted.** L3's locked-weapon text says "/menu → Minigames → Siege unlocks" while the hub tile is named "Siege Minigame"; left as the spec words it.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply migration `AddSiegeWeaponUnlockMinTitle`; restart the API once (menu seeds). No deploy order (the button hides until the plugin validated the menu); no `config.yml` keys.
    2. Import the form seed **SiegeWeaponTemplate - Default (seed v2)** and make it the default; set the minimum titles.
    3. Smoke test § 4 of `docs/guides/siege-shop-smoke-test.md` (step 9 manual, the by-hand parts of 1, 3 and 6).
9. **Notes for later links.**
    1. L6 (#871): the menu item can open `siege.unlocks` outside a match; the knk-plugin change in `KnKPlugin` is one line block after `SiegeShopMenuFeature`.
    2. #784: unlocks still come from `SiegeShopApi.unlockedWeaponTemplates` at match start; nothing to change.

### 4.6 L6 — Menu item in the plugin (#871)

1. **Scope done.**
    1. knk-plugin knk-core `core/menu/opener/`: `MenuItemAction` (`OpenMenu`, `RunCommand`, `None`; slash dropped), `MenuItemSituations` (registers `siege.survival.match`, `siege.match`, `siege.hub`, most specific first; features provide the checks; a name without a check never applies), `MenuItemActionResolver` (situation + click → action from the settings in memory, no API call on a click; § 5.7), `MenuItemApiSettings` (API section → settings, unknown clicks/actions/situations warned and left out); `MenuOpenerSettings` gains the click table, overrides and the shift-clicks (the file's `open-on` keeps today's rule); `KnkMenuItemSettings` in `KnkGameSettings` (plain strings, cache-safe).
    2. knk-plugin knk-api-client: `GameSettingsDto.menuItem` and its mapping.
    3. knk-plugin knk-paper: `MenuItemSettingsSync` (`config.yml` until the API answers, then every API answer, applied to online players without a restart), `MenuItemActionRunner` (`main` → `/menu`, `siege.information` → `/siege`, `siege.shop` → `/siege shop`, other keys open the template), listener shift-clicks, `MenuOpenerService.applyLive`/`click`/`run`, `GameSettingsManager.setMenuItemListener` (API answers only), `SiegeMenuItemSituations` (`siege.match` running match, `siege.hub` lobby phase `HUB`/`POST_MATCH`), three additive `KnKPlugin` hunks, a `config.yml` comment. L3's locked-weapon text now "Locked: unlock it in /menu → Siege Minigame → Siege unlocks." (coordinator note 7; one string and its tests).
    4. knk-workspace (branch, PR into `next`): smoke guide § 5.2 rewritten (12 steps, 11 tagged; step 8 Survival skipped until #41), §§ 3–4 locked text, changelog Unreleased entry, plugin configuration § 4.14 and § 2.1 row.
2. **Commits and heads.** knk-plugin `claude/siege-shop-l6` at `6f16b31c` (1 commit; base `next` `02a99b62`, 0 behind); knk-workspace at `15f6eaa8` (2 commits incl. a merge of `next` `ccd3ac34`, `plugin-configuration.md` header and § 2.1 conflict resolved keeping both; base `next`, 0 behind).
3. **PRs.** [knk-plugin#112](https://github.com/PandiO/knk-plugin/pull/112) (Closes #871), [knk-workspace#907](https://github.com/PandiO/knk-workspace/pull/907) (Part of #871), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`: baseline on `next` `02a99b62` 7446 tests, 20 skipped, 0 failed → 7489, 20 skipped, 0 failed (43 new).
    2. A29: `GameSettingsMenuItemMapperTest`, `MenuItemApiSettingsTest`, `GameSettingsManagerMenuItemTest.everyApiAnswerPassesTheSectionOn_A29`, `MenuItemSettingsSyncTest.*_A29`, `MenuOpenerServiceTest.live*`, `GameSettingsStoreTest.roundTripsTheMenuItemSection_871`. A30: `MenuItemActionResolverTest.*_A30`, `MenuOpenerListenerTest.inAMatch…_A30`, `MenuItemActionRunnerTest`, `SiegeMenuItemSituationsTest`. A31 (API down at startup = exactly as today from `config.yml`): `MenuItemSettingsSyncTest.withTheApiDownAtStartup…_A31`, `GameSettingsManagerMenuItemTest.withTheApiDownAtStartupTheCachedSectionIsNotUsed…_A31` (MockBukkit), `MenuOpenerListenerTest.withTheConfigFileSettings…_A31`, `MenuItemActionResolverTest.theConfigFileSettingsNeverAskForASituation_A31`; the #160 tests unchanged in behaviour.
    3. CI: green on `6f16b31c` (knk-plugin build and paper-boot, pull-request and push runs); knk-workspace build green on `15f6eaa8`.
    4. Codex: usage limit on both PRs (noted on each), no findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *Cache vs fallback.* Chosen: the menu item takes only live API answers; a start with the API down uses `config.yml` even when the game settings cache has a `menuItem` section (charter: "exactly as today from the config.yml keys"); after the API answered, an outage keeps the last API settings. Alternatives: (a) use the cached section, contradicts P26 and the charter.
    2. *Live changes.* Chosen: a new look replaces the item in place, off/audience removes it, a new slot or a first give waits for the next join or respawn (§ 9.7). Alternatives: (a) the full join placement for everyone, moves items mid-fight; (b) nothing until rejoin, fails A29.
    3. *Opening siege menus.* Chosen: `siege.information` and `siege.shop` open through `/siege` and `/siege shop` (lobby context, their own refusals, chat fallback; L3 note 9.3). Alternatives: (a) open the template by key, no lobby context.
    4. *`siege.hub`.* Chosen: lobby phase `HUB` or `POST_MATCH` (both at the scenario hub). Alternatives: (a) `HUB` only, the result screen falls back to the main menu; (b) also `MATCHMAKING`, players aren't at the hub yet.
    5. *Shift-clicks from `config.yml`.* Chosen: a shift-click follows the plain click unless `open-on` lists `SHIFT_*` itself; no new keys. Alternatives: (a) new keys, outside "no new keys".
    6. *Survival hook.* Chosen: the name is registered and `MenuItemSituations.provide` is the port; Survival adds one line at its merge (comment on #41). Alternatives: (a) guess Survival's match state now, unmerged code.
    7. *Unknown values from a newer API.* Chosen: warn once per answer and leave the click/situation out, the rest applies. Alternatives: (a) reject the whole section, one typo would drop every change.
6. **Out of scope, noted.** Comment on #41 (provide `siege.survival.match`). Player guide and game settings admin text: docs follow-up. No paper-boot scenario (no in-world behaviour beyond clicks; `MIN_SCENARIOS` untouched).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Deploy the plugin with knk-web-api carrying #870 (`menuItem` in `GET api/GameSettings`); no `config.yml` keys, no migration.
    2. Smoke test § 5.2 of `docs/guides/siege-shop-smoke-test.md` (step 12 manual, step 8 after #41, the by-hand parts of the others).
9. **Notes for later links.**
    1. #41 (Siege Survival merge): `menuItemSituations.provide(MenuItemSituations.SIEGE_SURVIVAL_MATCH, …)` next to `SiegeMenuItemSituations.register` in `KnKPlugin`.
    2. Later features add their situation names with `MenuItemSituations.provide` and to knk-web-api `MenuItemSettings.Situations`.
