# Siege weapons chain — progress report

**Status:** Running (2026-11-19) · **Last updated:** 2026-11-19

**Issue:** [PandiO/knk-workspace#354](https://github.com/PandiO/knk-workspace/issues/354), links
[#782](https://github.com/PandiO/knk-workspace/issues/782) (L1), [#783](https://github.com/PandiO/knk-workspace/issues/783) (L2),
[#784](https://github.com/PandiO/knk-workspace/issues/784) (L3), [#785](https://github.com/PandiO/knk-workspace/issues/785) (L4),
[#786](https://github.com/PandiO/knk-workspace/issues/786) (L5), [#787](https://github.com/PandiO/knk-workspace/issues/787) (L6),
[#788](https://github.com/PandiO/knk-workspace/issues/788) (L7), [#789](https://github.com/PandiO/knk-workspace/issues/789) (L8),
[#790](https://github.com/PandiO/knk-workspace/issues/790) (L9).
**Charter:** [handoffs/SIEGE_WEAPONS_CHAIN.md](../ai-agents/handoffs/SIEGE_WEAPONS_CHAIN.md).

## 1. Waiting for the developer

1. Nothing yet. Known ahead: L3 needs siege points (#356), the siege shop (#611) and the schematic and snapshot
   pipeline (#614) merged into `next`; on 2026-11-19 all three are open issues without a design or chain. When L2 is
   merged and that gate is still closed, the coordinator reports it as a blocker for L3 and asks whether to schedule
   designs for them through the manager. L9 needs the siege tactical map (#613); L7's ground fire needs siege fire (#615).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Entities, API, form seeds, unlocks | #782 | Merged into next (2026-11-19: API `e940aef1`, web app `24c8a988`, workspace `80f6ff72`) | API `d65e7c9`, web app `6138dc9`, workspace `f6ce0304` (`claude/siege-weapons-l1`) | [api#52](https://github.com/PandiO/knk-web-api/pull/52), [app#56](https://github.com/PandiO/knk-web-app/pull/56), [ws#794](https://github.com/PandiO/knk-workspace/pull/794) | green | subagent of the coordinator (decision 3: two component repos), started 2026-11-19 |
| L2 Spots through world tasks | #783 | Running | `claude/siege-weapons-l2`: (not pushed yet) | — | — | subagent of the coordinator (two component repos, as decision 3), started 2026-11-19 |
| L3 Buying, placement, paste, restore | #784 | Not started (gates: L2; #356, #611, #614) | — | — | — | — |
| L4 Damage, wreck, cooldown, statistics | #785 | Not started | — | — | — | — |
| L5 Ballista direct fire | #786 | Not started | — | — | — | — |
| L6 Trebuchet and catapult in game | #787 | Not started | — | — | — | — |
| L7 Ammo effects | #788 | Not started (#615 for ground fire only) | — | — | — | — |
| L8 Page credential and API relay | #789 | Not started | — | — | — | — |
| L9 Targeting mode on the map page | #790 | Not started (gates: L8; #613) | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from `next`, PRs target `next`, the coordinator merges
   with a merge commit), because `.github/workflows/ci.yml` is on `origin/main` of both knk-web-api and knk-web-app
   (checked 2026-11-19; `next` heads: API `935fe8cc`, web app `3432e6ef`, workspace `87eacf42`). Alternatives:
   (a) old rules (default branch, developer merges), which apply only while CI is missing; (b) stacking links on each
   other's unmerged branches, which the charter does not allow.
2. **Link model.** Chosen: every link session runs on the coordinator's model (set explicitly in `create_session`),
   because the charter leaves it to the coordinator and every link but L2 is tier:3. Alternatives: (a) a smaller model
   for L2 (tier:2), rejected for consistency of the chain; (b) leave it implicit, which the skill forbids.
3. **L1 route.** Chosen: subagent of this coordinator session (variant B), because L1 needs two repositories besides
   knk-workspace (knk-web-api and knk-web-app) and the skill (§ 4.1.4.2) sends such links the subagent route from the
   start, after the Auto-mode classifier refused a multi-repo attach on #511. Alternatives: (a) `create_session` with
   two `add_repo` calls, likely but not certain to be approved; (b) split L1 into an API and a web-app session,
   which the charter does not plan.
4. **Overlap, L1 vs Production chain (#22) L0 #141.** L0 adds one additive migration and `ItemBlueprint` changes in
   knk-web-api from `next`; its branch was not pushed yet on 2026-11-19. Both chains change `Migrations/` (model
   snapshot) and may touch `Properties/KnKDbContext.cs`. Chosen: not a blocker (different entities and lines); L1
   keeps its `KnKDbContext` edits in its own block, merges the latest `origin/next` first, generates its migration
   last and regenerates it if another migration lands in `next` before its merge; the Production coordinator is told
   that L1 carries a migration. Alternatives: (a) wait for L0 to merge first, which serialises two chains for a
   mechanical conflict; (b) ask Production to wait, which changes another chain's plan (developer's call).
5. **Overlap, L1 vs Siege Survival (#41) `claude/siege-survival`.** That API branch (11 commits not in `next`, no link
   running) adds a large block to `KnKDbContext` and new `Models/Siege/Survival/*`. L1 changes `SiegeScenario`,
   `SiegeTeam` and adds new `Models/Siege/` files. Chosen: not a blocker (claim not active, additive edits); L1 adds
   its properties and `KnKDbContext` configuration in separate blocks, without reformatting neighbouring lines.
   Alternatives: (a) put the weapons entities in their own `Models/Siege/Weapons/` folder only (still allowed if the
   link prefers); (b) block until Survival merges, rejected because it has no date.
6. **Overlap, L1 vs dashboard table fields (#608).** That row claims `src/config/objectConfigs.tsx` in knk-web-app but
   waits for the developer's design OK. Chosen: not a blocker; L1 adds its own object config entries without touching
   the permissiongrant entry. Alternatives: (a) wait, rejected (not active).

7. **Replies from other coordinators (2026-11-19), notes for later links.** Chosen: carry these into the link
   prompts, because they keep later merges mechanical. Alternatives: (a) ignore them and resolve conflicts at merge
   time, rejected (avoidable conflicts).
   1. Production (#22): L0 #141 adds a migration now; whichever chain merges second regenerates its migration. Siege
      ammo or shop items (#611) resolve items with L0's resolver (instance tag, blueprint tag, vanilla match), no
      parallel lookup. Production messages before each API link with a migration.
   2. NPC follow-ups (#358): plugin links that add scenarios get a mechanical conflict in `MIN_SCENARIOS`
      (`.github/workflows/paper-boot.yml`) and `PaperScenariosTest`; keep both lists and count the real total. Tell
      that coordinator before a plugin link starts if it adds scenarios or touches `KnKPlugin`'s NPC wiring.
   3. Destination engine (#25): L5 #747 will delete `MatchNavigationScope`, `NavigationEligibility`,
      `EndReason.SIEGE` and the `navigation.destination-engine` key; weapons links must not read those, and use the
      engine's siege scopes (`core/navigation/destinations`, `InitialScopes`) if they need navigation.
   4. Off-road (#698): no shared tick-budget convention; keep per-tick work bounded and wrap it in
      `PluginMetrics.timed(name, ...)` (L6 projectiles and preview arcs). Budgets in `specs/navigation-offroad/DESIGN.md`
      § 9.3.

8. **L1 merged into `next` without a Codex review.** Chosen: merge, because every other check of skill § 6 held
   (heads match, branches contain `next`, CI green on API and web app, scope matches #782, 47 new API tests, a new
   Playwright spec) and the Codex connector said on all three PRs, also after a fresh `@codex review`, that its
   usage limit is reached (developer decision 2026-11-14). Alternatives: (a) wait for the limit to reset, which holds
   up L2 for an unknown time; (b) rerun the review later on `next`, still possible. Two `origin/next` merge commits
   of L1 (API `0a4d7eb`, workspace `f6ce0304`) lack the trailers; left as they are (no force-push).
9. **L2 route.** Chosen: subagent (knk-plugin and knk-web-api, two component repos; as decision 3). Board checked
   2026-11-19: no active claim on the plugin's `tasks/` handlers or `siege/` packages; Siege Survival's unmerged
   plugin branch and the shared plugin files handled as in decision 7. Alternatives: as decision 3.

10. **knk-web-api `next` CI after the L1 merge.** `e940aef1` first went red on one MySQL test unrelated to siege
    weapons (`DiscoveryLedgerMySqlTests.TitleCrossing_PostsTheXpOnceAndAppliesTheBonusOnce`, `Assert.NotNull`), which
    passed twice on the same code in the PR; Production's merge `7d213fd6` just before had one red in the unit job.
    Chosen: rerun the failed job once (run 44503774980, attempt 2: green 2026-11-19 10:46) and record the test as
    flaky, not a blocker. Alternatives: (a) treat `next` as red and revert, rejected (green on rerun, test outside
    this chain); (b) file an issue for the flaky test, left to the manager's health section.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — Entities, API, form seeds, unlocks (#782)

1. **Scope done.**
    1. knk-web-api: entities `SiegeWeaponTemplate`, `SiegeAmmoType`, join `SiegeWeaponTemplateAmmoType`, `SiegeWeaponSpot` (owned by scenario and team), `UserSiegeWeaponUnlock` in `Models/Siege/Weapons/`; `SiegeTeam.ActiveWeaponSpots`, `SiegeScenario.FriendlyFire`, `SiegeScenario.WeaponSpotCooldownOverrideSeconds` (own line groups); `SiegeWeaponService`/`SiegeWeaponRepository` with the save rules; controllers `SiegeWeaponTemplates`, `SiegeAmmoTypes`, `SiegeWeaponSpots` (incl. `GET/POST api/SiegeScenarios/{id}/weapon-spots`), `UserSiegeWeaponUnlocks` (incl. `by-user/{userId}`), writes on `knk.siege.admin.manage` (+ `knk.admin.content` via the change rule, deletes + `knk.admin.delete`); dashboard registry and lookups; own `KnKDbContext` block; additive migration `AddSiegeWeapons`; form seeds for the four entities and the join, in-place step/field in `SiegeScenario.json`/`SiegeTeam.json`.
    2. knk-web-app: DTO types, four clients, `Controllers` enums, `entityApiMapping` cases, dashboard columns (no `objectConfigs` entries; #608's permissiongrant entry untouched).
    3. knk-workspace (`next`): smoke-test § 1 updated and tagged (2 of 11 automated, 8 partly), changelog "Unreleased" entry, spec status, dashboard access guide Siege row.
2. **Commits and heads.** knk-web-api `claude/siege-weapons-l1` at `d65e7c9` (5 commits incl. a merge of `origin/next` `7d213fd` (AddItemIdentity, #141) and the regenerated migration `20261119100022_AddSiegeWeapons` on top of it); knk-web-app at `6138dc9` (2 commits, base `next` at `3432e6e`); knk-workspace at `f6ce0304` (2 commits incl. a merge of `origin/next`; CHANGELOG conflict resolved by keeping both entries).
3. **PRs.** https://github.com/PandiO/knk-web-api/pull/52 (Closes #782), https://github.com/PandiO/knk-web-app/pull/56, https://github.com/PandiO/knk-workspace/pull/794, base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` 4451 passed, 1 failed, 100 skipped (MySQL, no `KNK_TEST_MYSQL`); result 4499 passed, 0 failed, 100 skipped (47 new); after merging `next` 7d213fd: 4532 passed, 0 failed, 103 skipped. CI green on `d65e7c9` (build-and-test, mysql-tests, fresh-database: runs 44501976157, 44501976137).
    2. knk-web-app: Jest 2767 → 2773; Playwright 198 → 204; `tsc --noEmit`, `typecheck:e2e`, `CI=true npm run build` clean before and after. CI green on `6138dc9` (build-and-test, e2e: runs 44500790545, 44500790451).
    3. Known reds (also red on the base): `RealtimeHubTests.WebHub_AcceptsTheAccessTokenQueryString` failed once in the baseline and passed on the branch: flaky, not caused by this link.
    4. Codex: at its usage limit (also on the `@codex review` after the merge pushes) for code reviews on all three PRs (its review "failed", then the usage-limit comment); continued without it, noted on each PR. No inline findings.
5. **Decisions (DESIGN § 4.3).**
    1. *Active weapon spots default.* Chosen: `SiegeTeam.ActiveWeaponSpots` is an int, default 0 (none), because existing scenarios then have no usable spot and play exactly as before. Alternatives: (a) nullable with null = all spots active, an extra meaning for the plugin to handle; (b) default 1, which would switch spots on for every existing team.
    2. *Schematic references.* Chosen: `ArmedSchematicId`, `FiredSchematicId`, `WreckSchematicId` as nullable ints without a foreign key and not on the form, because the #614 pipeline has no table yet and its metadata entity will have an int id. Alternatives: (a) string file keys, which would need a conversion when #614 lands; (b) leave them out, which the sub-issue asks to keep nullable instead.
    3. *Kind-specific fields.* Chosen: the indirect-only fields (spread, ranging step, flight time, arc height) and the direct-only cone are non-null with the spec's proposal defaults, checked only for their kind, and the seeded form shows them per kind, because the plugin then never handles nulls. Alternatives: (a) nullable per kind, more null handling for every later link.
    4. *Defaults the spec leaves open.* Chosen: max health 300, build 60 s, reload 20 s, max range 100, arc height 20, match price 200, unlock price 1000, spot cooldown 120; ammo damage 10, structure damage 100, radius 2, knockback 1, price 10; all configuration tuned in the alpha (§ 15.2). Alternatives: (a) no defaults (required fields), more typing for every row.
    5. *Spot ownership and deletes.* Chosen: a spot cascades from its scenario and from its team (deleting a team removes its spots), because W44 gives every spot an owning team. Alternatives: (a) SetNull on the team, which leaves ownerless spots; (b) Restrict, which blocks deleting a team.
    6. *Size class in phase 1.* Chosen: bounds, facing and size class are typed in the form (bounds all six or none, min ≤ max); the derivation from the footprint and facing (W70) stays with the phase 2 world task (#783). Alternatives: (a) derive in the API now, which would put the facing rule in two places before L2 designs it.
    7. *Who grants unlocks.* Chosen: staff with `knk.siege.admin.manage` grant and revoke them in the web app, and the plugin key may write them, because buying an unlock with coins is in no phase's scope; filed as #795. Alternatives: (a) build the coin purchase here, which touches the currency ledger and goes beyond L1's data-only scope.
    8. *Delete protections.* Chosen: users (soft-deleted) and templates a player unlocked are Restrict (409 "players have unlocked"), and an ammo type a template allows can't be deleted (409 naming the templates), because unlocks were paid with coins and removing ammo should be a deliberate step. Alternatives: (a) cascade, which silently removes paid unlocks or template ammo.
    9. *Unique names.* Chosen: template and ammo type names are unique (case-insensitive check, unique index), because players pick them by name in the shop and on the page. Alternatives: (a) no uniqueness.
    10. *Scenario and team seeds.* Chosen: the new step and fields were added to `SiegeScenario.json` and `SiegeTeam.json` in place, without a new configuration GUID (the NavigationItem precedent), because the objective and spawnpoint seeds' rules depend on the scenario configuration's Town field GUID. Alternatives: (a) new seed versions with new GUIDs, which would break those rule dependencies.
    11. *Spot routes.* Chosen: `GET/POST api/SiegeScenarios/{id}/weapon-spots` are served by `SiegeWeaponSpotsController` with absolute routes, so `SiegeScenariosController` stays untouched (Siege Survival overlap). Alternatives: (a) add them to `SiegeScenariosController` next to objectives.
    12. *Field names.* Chosen: `ArmorPiercing` (Minecraft API spelling), `EffectLevel` for the poison level, `ProjectileBlock` and `ParticleTrail` as material and particle names, `ArcHeight` in blocks. Alternatives: (a) one JSON "look" field, harder to validate and edit in the form.
6. **Out of scope, noted.** #795 filed: buying a weapon type unlock with coins (W32) is in no phase's scope; staff grants and plugin-key writes exist.
7. **Blockers.** None. Note: the two `origin/next` merge commits carry git's default message without the co-author/session trailers; they are pushed and not rewritten (no force-push).
8. **At merge / what the developer must do.**
    1. Apply the migration `AddSiegeWeapons` (additive: five tables, three defaulted columns).
    2. Import the seeds `SiegeAmmoType`, `SiegeWeaponTemplateAmmoType.join`, `SiegeWeaponTemplate`, `SiegeWeaponSpot`, `UserSiegeWeaponUnlock` (make default); on a DB that imported `SiegeScenario`/`SiegeTeam` before, add the "Siege weapons" step and "Active weapon spots" field by hand in the form designer.
    3. Run smoke-test § 1 (tier:3); decide where #795 goes.
    4. At the merge into `next`: move the changelog entry; the docs follow-ups (API notes, production installation migration list, register row, admin guide) go into the `Docs:` sub-issue.
9. **Notes for later links.**
    1. L2: spots are created through `POST api/SiegeScenarios/{id}/weapon-spots` (`siegeTeamId`, `name`, `facing` North/East/South/West, `sizeClass`, `minX..maxZ` all six or none, `wgRegionId`); the API does not derive the size class yet (W70 is L2's); the seeded `SiegeWeaponSpot` form has no world task field yet.
    2. L3: unlock check via `GET api/UserSiegeWeaponUnlocks/by-user/{userId}` (plugin key passes `[DashboardReads]`); the runtime-config payload (`api/siege-lobbies/runtime-config`) does not carry templates, spots, `ActiveWeaponSpots` or `FriendlyFire` yet; add them there. Schematic ids are plain nullable ints without a foreign key; #614 adds the key.
    3. Any API link with a migration: merge `origin/next` and regenerate on top of `AddSiegeWeapons` (generated with `Database__MySqlServerVersion=8.0.36` and a dummy connection string, no MySQL needed).
