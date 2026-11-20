# Siege shop chain — progress report

**Status:** Running (2026-11-20) · **Last updated:** 2026-11-20

**Issue:** [PandiO/knk-workspace#611](https://github.com/PandiO/knk-workspace/issues/611) (with
[#356](https://github.com/PandiO/knk-workspace/issues/356) and [#859](https://github.com/PandiO/knk-workspace/issues/859)),
links [#866](https://github.com/PandiO/knk-workspace/issues/866) (L1), [#867](https://github.com/PandiO/knk-workspace/issues/867) (L2),
[#868](https://github.com/PandiO/knk-workspace/issues/868) (L3), [#869](https://github.com/PandiO/knk-workspace/issues/869) (L4),
[#870](https://github.com/PandiO/knk-workspace/issues/870) (L5), [#871](https://github.com/PandiO/knk-workspace/issues/871) (L6).
**Charter:** [handoffs/SIEGE_SHOP_CHAIN.md](../ai-agents/handoffs/SIEGE_SHOP_CHAIN.md).
**Coordinator:** the Siege weapons chain coordinator (session_01R1w2UuyXat2GBcJjHG3RRV) runs this chain too, on the
developer's instruction of 2026-11-20; its own report is [2026-11-19-siege-weapons-chain.md](2026-11-19-siege-weapons-chain.md).

## 1. Waiting for the developer

1. Nothing for this chain yet. (Siege weapons L3 #784 also needs #614, the schematic pipeline, which has no design;
   see the weapons report § 1.)

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Shared ledger, siege points earning | #866 | Merged into `next` 2026-11-20 (knk-web-api `9a3132dc`, knk-plugin `91e3ddb8`, knk-workspace `1e38c7ec`) | `claude/siege-shop-l1`: knk-plugin `b6fa74ec`, knk-web-api `4da6780`, knk-workspace `8a215193` | [knk-plugin#107](https://github.com/PandiO/knk-plugin/pull/107), [knk-web-api#64](https://github.com/PandiO/knk-web-api/pull/64), [knk-workspace#879](https://github.com/PandiO/knk-workspace/pull/879) | green (plugin build + paper-boot; API build-and-test, mysql-tests, fresh-database) | subagent of the coordinator (two component repos), started 2026-11-20 |
| L2 Shop catalogue (API, web app) | #867 | Merged into `next` 2026-11-20 (knk-web-api `aff345dd`, knk-web-app `6f494154`, knk-workspace `ea361394`) | `claude/siege-shop-l2`: knk-web-api `1bed630a`, knk-web-app `77791388`, knk-workspace `a31db5c7` | [knk-web-api#66](https://github.com/PandiO/knk-web-api/pull/66), [knk-web-app#69](https://github.com/PandiO/knk-web-app/pull/69), [knk-workspace#888](https://github.com/PandiO/knk-workspace/pull/888) | green (API build-and-test, mysql-tests, fresh-database; web app build-and-test, e2e) | subagent of the coordinator (two component repos), started 2026-11-20 |
| L3 Shop in the plugin | #868 | Running | `claude/siege-shop-l3` | — | — | subagent of the coordinator (decision 8), started 2026-11-20 |
| L4 Weapon unlocks | #869 | Not started (gate: L2, L3, L5 merged) | — | — | — | — |
| L5 Menu item settings (API, web app) | #870 | Running (parallel with L3) | `claude/siege-shop-l5` | — | — | subagent of the coordinator, started 2026-11-20 |
| L6 Menu item in the plugin | #871 | Not started (gate: L3, L5 merged) | — | — | — | — |

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
