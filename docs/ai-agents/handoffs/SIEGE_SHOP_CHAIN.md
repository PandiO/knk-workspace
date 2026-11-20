# Siege shop chain — charter

**Status:** Ready to start (2026-11-20)
**Last updated:** 2026-11-20 (drafted by the design session; the coordinator completes it at its first run)
**Issues:** parent [PandiO/knk-workspace#611](https://github.com/PandiO/knk-workspace/issues/611) (with
[#356](https://github.com/PandiO/knk-workspace/issues/356), built by L1, and
[#859](https://github.com/PandiO/knk-workspace/issues/859), parent of L5–L6); sub-issues per link below. Reference
issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** _(the coordinator creates it at its first run)_
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/` (knk-workspace).

## 0. Binding documents

1. [specs/siege-shop/DESIGN.md](../../specs/siege-shop/DESIGN.md) on `next`, status Decided 2026-11-20 (decisions
   P01–P27; open questions answered in § 12; acceptance A01–A31 in § 10; phases in § 11).
2. [specs/siege-minigame/SIEGE_WEAPONS.md](../../specs/siege-minigame/SIEGE_WEAPONS.md) W13, W14, W20, W31–W34, W50,
   W60, W61, W67 (economy rules this builds on); [specs/siege-survival/DESIGN.md](../../specs/siege-survival/DESIGN.md)
   § 8 (Survival's ledger and purchase points).
3. [guides/siege-shop-smoke-test.md](../../guides/siege-shop-smoke-test.md) on `next`, draft; each link updates its
   section.
4. The sub-issue text **and its comments** (decisions added later live there).

## 1. Links

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | #866 | tier:3 | Shared `MatchLedger` moved into `core/siege/economy` (same API), siege points earning in PvP with assists and streaks, per-player board, `/siege points`, `/siege pay`, settings columns, participant totals | knk-plugin, knk-web-api | `claude/siege-shop-l1` | `next` | `siege.points.enabled`, default off | now |
| L2 | #867 | tier:2 | Shop categories, entries and scenario overrides, effective catalogue endpoint, form seeds, catalogue seeds, web app forms; potion blueprint check | knk-web-api, knk-web-app | `claude/siege-shop-l2` | `next` | none (data only) | L1 merged into `next` (shares knk-web-api) |
| L3 | #868 | tier:3 | Shop menus and item purchases with brakes, `ShopPurchaseHandler` port for siege weapons #784, Survival hook, telemetry | knk-plugin | `claude/siege-shop-l3` | `next` | `siege.shop.enabled`, default off | L1 and L2 merged into `next` |
| L4 | #869 | tier:2 | Weapon unlock purchase with coins and title level, main-menu Siege unlocks, web app profile panel | knk-web-api, knk-plugin, knk-web-app | `claude/siege-shop-l4` | `next` | none | L2 merged; L3 and L5 merged (repo overlap) |
| L5 | #870 | tier:2 | `GameSettings.MenuItem` section and the game settings Menu item card | knk-web-api, knk-web-app | `claude/siege-shop-l5` | `next` | none | L2 merged into `next` (shares both repos) |
| L6 | #871 | tier:2 | Menu item from the API in the plugin: clicks, situations, `config.yml` fallback, siege overrides | knk-plugin | `claude/siege-shop-l6` | `next` | none | L3 and L5 merged into `next` |

## 2. Gates

1. "L<n> merged into `next`": `git rev-list --count origin/next..origin/claude/siege-shop-l<n>` is 0 in every repo
   L<n> changed.
2. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed.
3. No developer gate inside the chain. The developer's smoke tests of § 1 and § 3 of the guide are wanted before
   siege weapons L3 (#784) relies on the shop; the weapons coordinator checks that, not this chain.

Order and parallelism: at most one link per component repo at a time. L1 → L2 → then L3 (knk-plugin) and L5
(knk-web-api, knk-web-app) together → then L4 and L6 (L6 is plugin-only and may run alongside L4 only if L4 has
finished its plugin part; otherwise one after the other).

## 3. Chain notes

1. **Siege weapons chain (#354)** is paused waiting for this chain (its L3 #784 needs L1–L3 here plus #614). Both
   touch knk-plugin `siege/` and knk-web-api `Models/Siege/`; never run a link of each in the same repo at the same
   time. Tell the weapons coordinator when L3 is merged; #784 implements the `SiegeWeaponPurchaseHandler` against L3's
   port.
2. **Siege Survival (#41)**: its branches are unmerged. L1 copies `MatchLedger` with the **same public API** (P11) so
   their merge only changes imports; comment on #41 when L1 merges. Survival's `/siege shop` in range of a purchase
   point becomes `/siege buy` (P21) and its transfer switch column is added on its branch at the merge (§ 9.2 of the
   spec).
3. Existing PvP behaviour stays unchanged with `siege.points.enabled` and `siege.shop.enabled` off; L1's per-player
   scoreboard split (P18) must look the same as today with the flag off.
4. Migrations: L1, L2, L4 and L5 may each add one additive migration; L3 and L6 none.
5. Model for link sessions: _(the coordinator sets it)_.
