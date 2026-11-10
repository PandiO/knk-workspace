# Alpha test run 1 — package B: enchantments and freeze (2026-10-26)

**Status:** In review — pushed on `claude/alpha-run-1-enchantments`: knk-web-api `0ecbe53` (from `master` `6f08383`),
knk-web-app `de93b69` (from `main` `0d61270`), knk-plugin `fcb2e08a` (from `main` `ee35fb1d`); not merged, not deployed,
not live-tested
**Last updated:** 2026-10-26
**Issues:** [PandiO/knk-workspace#151](https://github.com/PandiO/knk-workspace/issues/151) (P0),
[#156](https://github.com/PandiO/knk-workspace/issues/156), [#155](https://github.com/PandiO/knk-workspace/issues/155);
parent [#149](https://github.com/PandiO/knk-workspace/issues/149)
**Handoff:** [2026-10-25-alpha-run-1-p0-p1.md](../../../ai-agents/handoffs/2026-10-25-alpha-run-1-p0-p1.md) § 1 package B ·
**Findings:** [test-run-1-findings.md](test-run-1-findings.md) · **Admin guide:**
[custom enchantment combat values](../../../guides/admin/custom-enchantment-combat-values-admin-guide.md)

Claude Code (subagent of the coordinator session, after the package session was refused `add_repo`) traced the three
issues against the default branches and fixed them in knk-web-api, knk-web-app and knk-plugin. knk-dev-db-seed needed
no change: the seed loads and the new migration applies on top of it.

## 1. What the code did, and what changed

| Issue | Found on the default branch | Change |
|---|---|---|
| #151 admin-configurable values (P0) | The plugin's chances, durations and cooldowns were constants: `AttackEnchantmentEffect` subclasses (`0.15` per level, `level × 60` ticks), `EnchantmentRegistry.cooldownMs`. The API's `AbilityDefinition.RuntimeConfigJson` described them but nothing read it, and the startup seed overwrote it on every start. No cooldown at all on the on-hit effects, so freeze could chain. | **API** `a9dd303`: six nullable columns on `EnchantmentDefinition` (`ProcChancePercent`, `ProcChancePerLevelPercent`, `CooldownEnabled`, `CooldownSeconds`, `EffectDurationSeconds`, `LevelMultiplier`; migration `AddEnchantmentCombatValues`), on the read/create/update DTOs, range checks (400), an update writes only the values the request contained. Form seed `EnchantmentDefinition - Default (seed v2)` with a "Combat values" step for custom enchantments. **Web app** `de93b69`: DTO types (the admin is the generic form). **Plugin** `1e4e72f9`: `EnchantmentTuningTable` (built-in values + admin overrides, keys matched like the API's `MatchKey`, clamped), effects read chance/duration per hit and `ExecutorImpl` the cooldown (per attacker, per enchantment); `EnchantmentTuningRefresh` loads `GET /EnchantmentDefinitions` at startup, every `custom-enchantments.tuning-refresh-minutes` (5) and on `/ce reload`, keeping the last values on failure; `/ce info` shows the values in effect. Until #156 the built-in values were the old behaviour. |
| #156 weaker defaults, freeze with cooldown | Before: on-hit effects 15/30/45 %, level × 3 s (wither × 2 s), no cooldown; blindness on every hit for 3/6/9 s. | **API** `0ecbe53`: `CanonicalCatalog` entries carry `CombatDefaults`; the startup seed writes them into empty columns only (admin values stay; a cleared field returns to the default at the next start). **Plugin** `fcb2e08a`: the same numbers as built-in values. Poison/Wither/Confusion 10/15/20 %, half the level-I duration more per level, 8 s cooldown; Blindness 20/30/40 %, 2/3/4 s, 10 s; **Freeze 10/15/20 %, 1.5/2.25/3 s, then a 20 s cooldown per attacker**; Strength and the right-click abilities unchanged. Table: admin guide § 3. |
| #155 frozen players kicked for flying | Both freezes (`FreezeMovementListener` for the enchantment, `AdminFreezeListener` for `/freeze`) hold a player by setting the move back to `from`, also in mid-air; nothing allowed flight, so the server kicked them. | **Plugin** `c059eccb`: `FreezeFlightLedger` (core) + `FreezeFlightGuard` (listener): while a player is frozen by either, flight is allowed for that player only; their own setting comes back when the last freeze ends, on quit (before the save) and on plugin disable; a frozen player's flight toggle is cancelled. Not switched off when another feature already did (siege preparation) or in creative/spectator. `FrozenPlayerTracker` and `AdminFreezeManager` report freeze start/end; a freeze also ends on quit. |

Fixed in passing (same files, noted in #155): an older freeze's timer could end a newer freeze of the same player
(`FrozenPlayerTracker` removed the pending task in `isFrozen` without cancelling it), and a creature frozen twice kept its
AI switched off after the freeze.

Known limits (written down in the issues):

- Freeze stays an on-hit chance with a cooldown, not a right-click ability: #156 said "consider"; a right-click
  trigger is a gameplay change for the developer to decide (#156 comment).
- The cooldown is per attacker. Several attackers with Freeze can still freeze one victim in turns; a per-victim
  immunity window would be a new rule (suggested in the #156 comment, not built).
- Potion strength (amplifiers) and the area damage of Chaos (40) / Flash Chaos (60) are not among the configurable
  values (#151 asked for chance, cooldown, duration, multiplier); #156 comment.
- Cleaving keeps its numbers in `config.yml` (`gates.cleaving`).
- A staff `/fly on` given to a frozen player who couldn't fly before is taken away when the freeze ends (#155).

## 2. Tests

| Repo | Default branch | `claude/alpha-run-1-enchantments` |
|---|---|---|
| knk-plugin `./gradlew test` (JDK 25) | `ee35fb1d`: core 2312, api-client 280 (2 skipped), paper 2140 (18 skipped), 0 failures | `fcb2e08a`: core 2331, api-client 282 (2 skipped), paper 2155 (18 skipped), 0 failures; `./gradlew build -x deployToDevServer` green |
| knk-web-api `dotnet test` | `6f08383`: 3296 passed, 4 failed, 87 skipped | `0ecbe53`: 3330 passed, the same 4 failed, 87 skipped |
| knk-web-app `npm run test:ci`, `npm run build` | — | `de93b69`: 193 suites, 1214 tests passed; build compiles (warnings only) |

The 4 API reds are the known ones (`ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`,
`PathResolutionServiceTests` ×2, `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_…`).
Web app: `npm ci` refuses on `main` (lock file misses `yaml@2.9.1`), so dependencies were installed with
`npm install --package-lock=false`; `CI=true npm run build` fails on `main`'s existing lint warnings, none in the changed
file.

Against MySQL: knk-dev-db-seed loaded (`seed.sh`), `dotnet ef database update` applied `AddEnchantmentCombatValues`, the
API started on it and filled the defaults into the 12 canonical custom enchantments (Cleaving left empty),
`GET /api/EnchantmentDefinitions` with the plugin key returned them, and the seed v2 import dry run passed next to the
seed's v1.

## 3. Live checklist for test run 2

Deploy: API (migration runs), plugin jar, then in the web app import the form seed `EnchantmentDefinition` (v2) and make
it the default.

1. Web app → edit Freeze: step "Combat values" shows 10 / 5 / cooldown on / 20 / 1.5 / 0.5. A vanilla enchantment doesn't
   show the step.
2. In game, `/ce info` with a Freeze III weapon: `chance 20%, duration 3s, cooldown 20s`.
3. Hit a player with Freeze until it procs: frozen for about 3 s; no further freeze from you for 20 s.
4. Freeze a player who is jumping or falling: they hang in the air and are **not kicked**; double-tapping space doesn't
   let them fly; after the freeze they fall and can't fly. Same with `/freeze` + `/unfreeze`.
5. Set Freeze's chance to 100 and cooldown off in the web app, `/ce reload` (or wait 5 min): every hit freezes; set it
   back.
6. Blindness no longer on every hit; Poison/Wither shorter.
7. Frozen player logs out and back in: not frozen (enchantment), can't fly; staff-frozen player stays frozen and isn't
   kicked.
8. Then remove `ALLOW_FLIGHT: "TRUE"` from the alpha's `minecraft` service (knk-deploy procedure,
   `docs/guides/nas-ops-access.md`), restart, and repeat step 4 — #155 is done only after this.

## 4. Next steps

Developer: review the defaults (§ 1 / admin guide § 3) and the open questions in #156, run the checklist, merge the
three branches (no conflict with package A's plugin branch: `git merge-tree` clean), deploy, remove `ALLOW_FLIGHT`.
