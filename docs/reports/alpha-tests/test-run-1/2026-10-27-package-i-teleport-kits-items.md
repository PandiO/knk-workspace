# Alpha test run 1 — package I: teleport, kits, items (2026-10-27)

**Status:** In review (round 2b 2026-10-27: knk-plugin `060d38d`) — pushed on `claude/alpha-run-1-teleport-items`: knk-plugin `aa185fa` (round 2; round 1 `9b25ee7`,
from `main` `3550cbb`), knk-web-api `cbd8074` (from `master` `4d7a806`, unchanged in round 2); not merged, not deployed;
round 1 smoke-tested on dev 2026-10-27 (§ 6), round 2 not live-tested
**Last updated:** 2026-10-27
**Issues:** [PandiO/knk-workspace#171](https://github.com/PandiO/knk-workspace/issues/171) (P2),
[#172](https://github.com/PandiO/knk-workspace/issues/172) (P2), [#175](https://github.com/PandiO/knk-workspace/issues/175) (P3);
parent [#149](https://github.com/PandiO/knk-workspace/issues/149)
**Handoff:** [2026-10-27-alpha-run-1-p2-p3.md](../../../ai-agents/handoffs/2026-10-27-alpha-run-1-p2-p3.md) § 1 (decisions) ·
**Findings:** [test-run-1-findings.md](test-run-1-findings.md) (6.1, 9.1, 10.1)

Claude Code (subagent of the coordinator session) built the three issues against the current default branches.

## 1. What changed

| Issue | Before (default branch) | Change |
|---|---|---|
| #171 teleport `all` | `/hub`, `/spawn`, `/tp`, `/tphere` moved one player; the actor had to **outrank** them (`RankHierarchy.actorOutranks`); no exemption. | `/hub all`, `/spawn all`, `/tp all <player>`, `/tphere all` (each `[-s]`), nodes `knk.teleport.all.hub\|spawn\|tp\|tphere`. Eligible: online, actor's rank or lower (highest active group weight), not exempt, not in staff/owner mode, never the actor (nor the `/tp all` target). Reply "Teleported n of m players …" plus who wasn't moved. Moving another player now needs the **same rank or lower** (`RankHierarchy.actorAtLeast`, `UserAdminService.withRankCheck(…, sameRankAllowed)`) for `/tp`, `/tphere`, `/spawn`, `/hub`, `/warp` and `/back` on someone; `/freeze`, `/inventory`, `/enderchest`, `/knk user` stay strictly lower. Exempt nodes `knk.teleport.exempt.hub\|spawn\|tp\|tphere` and `.*`; staff and owner mode exempt by default. New `teleport/TeleportExemptions`. |
| #172 kits tooltip | "Other contents:" was one lore line with every item. | Wrapped at 40 visible characters (label counted; items never split, one wider than the line cut with "…"), at most 6 lines, the last "… and N more" when items are left out (`KitMenuRow.otherContentLines`). |
| #175 `/knk item more` | — | Fills the held stack to its max, or gives another full stack in an empty slot ("no room" otherwise). Node `knk.admin.item.more` (plus `knk.admin.item` for `/knk item`). Items with `knightsandkings:knk_item_instance` get one **new ItemInstance per copy** from the new API endpoint `POST api/ItemInstances/{id}/clone` (`RequirePluginService`; copies blueprint, grade, enchantments, custom name and flags; `Origin = Admin`, `OriginRef = clone:<id>`; owner = the admin; audited `ItemInstanceCloned`), each copy a single item. Nothing is given when minting fails. New port `ItemInstancesApi` + client. |

Rank seeds (knk-web-api, data-only migration `20261027200000_SeedTeleportAllAndItemMoreNodes`, package C's
parent-chain/wildcard rule): `knk.teleport.all.*` (four nodes) → Moderator and Admin; `knk.admin.item.more` → Admin (on the
alpha covered by `knk.admin.*` already). No exemption node is seeded.

## 2. Decisions taken here (review)

1. **Override:** the console and `knk.admin.user.manage.all` still move an exempt player (node or staff/owner mode) they
   name on a single-player teleport, but the `all` forms **never** move an exempt player, whoever runs them.
2. **`all` rank check** runs quietly per player (no "higher rank" message per skipped player); an account that can't be
   resolved is skipped. The console and `manage.all` pass the rank rule (not the exemption).
3. **`/spawn all`** sends each player to their own spawn (group spawn override, else the server spawn), like `/spawn <player>`.
4. **Exemptions** apply to the four types only; `/warp <d> <player>` and `/back <player>` get the new rank rule but no
   exempt node (not in the issue).
5. **Seeds:** `all` nodes Moderator + Admin, not general Staff (conservative).
6. **Instance items in `/knk item more`:** copies are single items (an instance id makes items unstackable); the count is
   what the stack lacks from its max size, or one max-size stack's worth when full (= one copy for the usual max-1
   instance item), limited by empty slots. The API refuses a source whose blueprint is now stackable (409). The copies'
   owner is the admin running the command; `IsSoulbound`/`IsGhosted` are copied as stored (no soulbound model exists).
7. **AuditAction 60** (`ItemInstanceCloned`) leaves 43–59 for the other P2/P3 packages; the column stores names, so the
   number doesn't reach the database.

## 3. Tests

- knk-plugin (`gradle build -x deployToDevServer`, JDK 25 toolchain): **core 2378 / api-client 284 / paper 2267, 0 failures**
  (baseline `main` `3550cbb`: 2378 / 282 / 2223; skipped 0 / 2 / 18 unchanged). New: `TeleportExemptionsTest`,
  `RankHierarchyTest`, `ItemMoreCommandTest`, `ItemInstancesApiImplTest`; extended `StaffTeleportCommandTest`,
  `HubTeleportCommandTest`, `SpawnCommandTest`, `UserAdminServiceTest`, `KitMenuRowTest`, `KitsMenuFeatureTest`.
- knk-web-api: NuGet is blocked here, so the tests weren't compiled or run. GitHub "Migrations (fresh DB)" on `cbd8074`:
  **success** (build, all migrations up, model snapshot unchanged, all down, up again). New/changed tests for the
  developer to run: `ItemInstanceServiceTests` (CloneAsync ×3), `ItemInstancesControllerTests`,
  `SeedTeleportAllAndItemMoreNodesTests`, `LootboxControllersAuthTests` (Clone allowed as plugin-only),
  `EndpointAccessRulesTests` (the new write has `RequirePluginService`).

## 4. Live checklist (test run 2)

Deploy both branches (the API migration seeds the ranks). Use non-op accounts of different ranks.

- [ ] Moderator `/tphere <Moderator>` works (same rank); `/tphere <Admin>` refused "higher rank".
- [ ] Moderator `/tphere all`: every lower/same-rank online player arrives; a staff-mode player, an owner-mode player and
      a player granted `knk.teleport.exempt.tphere` stay; reply lists the count and "Not moved".
- [ ] `/tp all <player>` moves everyone eligible to that player (who stays put); `/hub all`, `/spawn all` likewise; `-s` sends no message.
- [ ] Staff without `knk.teleport.all.*`: `all` refused and not tab-completed.
- [ ] `/tp <exempt> <x>` refused; same from the console (or with `knk.admin.user.manage.all`) moves them.
- [ ] Kits menu: hover "War set cursed" — contents wrap over several short lines, "… and N more" for a long kit.
- [ ] `/knk item more` with 10 bread → 64; again → second stack; full inventory → "no room".
- [ ] `/knk item more` on a lootbox instance item → one copy with a different id (`/knk lootbox` admin lookup or
      `GET api/ItemInstances/{id}`); the source keeps its id; audit log shows `ItemInstanceCloned`.

## 5. Not done / follow-ups

Nothing filed: no out-of-scope bug found. Open review points are § 2.1, 2.5 and 2.6.

## 6. Round 2 (2026-10-27)

**Input:** the developer's smoke test run 1 on dev ([#175 comment](https://github.com/PandiO/knk-workspace/issues/175)):
fill, second stack, no room, instance copy and refusal without the node all work. Change asked: an optional amount,
`/knk item more <amount>`; on a max-stack-1 item blueprint item `/knk item more 64` gives 64 of it, regardless of its max
stack size. Without an amount the round-1 behaviour stays.

**Change** (knk-plugin `aa185fa`, `ItemMoreCommand`, `KnkAdminCommand`, `ItemCommand`, `plugin.yml`; no API change):

| Case | `/knk item more <amount>` |
|---|---|
| Plain item (no instance id; this includes item-blueprint items such as a max-1 sword) | Exactly `amount` more, built as stacks of the item's max size (64 → 64 single swords; 150 bread → 64 + 64 + 22) and added like a pickup: matching stacks are topped up first, then empty slots. The held stack is never changed itself. |
| Item with `knk_item_instance` | `amount` new instances minted in **one** `POST api/ItemInstances/{id}/clone` call (`count`), one single item per copy and empty slot — limited to the empty slots (≤ 36), so the API's existing `count` limit of 64 always suffices. |
| Not enough room | What fits is given; the rest is **not** given (nothing dropped) and the reply says so ("Gave you 8 of 20; your inventory had no room for 12 more (not given)"). Instance items: only as many instances as there are empty slots are minted ("room for 5 of 64; the rest is not made"); no room at all → refused, nothing minted. |
| Bad amount (`0`, negative, text, > 2304, extra args) | Usage `/knk item more [amount 1-2304]`, nothing given. |
| Tab completion | `more` then `1`, `8`, `16`, `32`, `64` (after `knk.admin.item` is listed, as before). |

**Decisions (review):**
1. **Upper bound 2304** (36 storage slots × 64), a constant, not a config key: more can never fit in a player inventory
   (armour/offhand slots aren't filled), so a larger amount only means "not given". Easy to turn into a config key later.
2. **Overflow is not given, not dropped.** The round-1 no-amount path refused when full; dropping thousands of items at
   the feet on a typo is worse than a clear count. (The one remaining drop is round 1's race: instance copies minted for
   free slots that filled up while the API answered drop at the feet, so a minted id is never lost.)
3. **No API change.** Instance copies are single items, so one run can never need more than 36 instances; round 1's
   `count` 1..64 on the clone endpoint covers it in one call — no batch endpoint, no new access rule, no migration.
4. **An amount always means "this many more"**, also for a held stack below its max (10 bread + `64` → 74 bread across
   two stacks), rather than "fill to `amount`".

**Tests:** knk-plugin `gradle build -x deployToDevServer` (JDK 25 toolchain): **core 2378 / api-client 284 / paper 2274,
0 failures** (round 1: 2378 / 284 / 2267; skipped 0 / 2 / 18 unchanged). `ItemMoreCommandTest` 8 → 15: max-1 item ×64,
spread over stacks, partial fit, no room, bad amounts, instance amount in one call, instance amount limited to free
slots. `KnkAdminCommand` tab completion and dispatch have no unit harness; they are on the live checklist. knk-web-api
unchanged (`cbd8074`, "Migrations (fresh DB)" green in round 1).

**Re-test (smoke test run 2):**
- [ ] Hold a max-stack-1 item-blueprint item: `/knk item more 64` → 64 of it (one per slot as far as there is room); reply "Gave you 64 more", or "Gave you n of 64 … not given" with fewer free slots.
- [ ] Hold 10 bread: `/knk item more 150` → 160 bread in total (stacks topped up, then 64s); `/knk item more` without amount still fills to 64.
- [ ] Nearly full inventory: `/knk item more 500` on bread → reply gives the count not given; nothing on the ground.
- [ ] Instance item (lootbox): `/knk item more 5` → 5 copies with 5 new ids in one go; with 2 free slots → 2 copies, "room for 2 of 5"; audit log one `ItemInstanceCloned` with 5 (or 2) ids.
- [ ] `/knk item more 0`, `abc`, `9999` → usage, nothing given; tab after `/knk item more ` offers 1/8/16/32/64.

## 7. Round 2b (2026-10-27, developer decision after review)

The developer confirmed round 2's choices with one change: **the amount has no upper limit**. `/knk item more <amount>`
gives that many more and adds them until the inventory is full; nothing is ever dropped. knk-plugin `060d38d`:

- `parseAmount` accepts any whole number from 1 up (larger than `Integer.MAX_VALUE` is capped there); `0`, negatives,
  decimals, text and extra arguments still show the usage `Usage: /knk item more [amount]`. The 2304 constant is gone.
- Plain items: the inventory's room for the item (empty storage slots × max stack size plus free space on similar
  stacks) is computed first, and only that many are built and added, so a huge amount stays cheap. The reply counts
  what wasn't given ("Gave you n of N; your inventory had no room for m more (not given).").
- Instance items: unchanged (one copy per free slot, minted in one call). Round 1's last drop is removed: copies minted
  for slots that filled up while the API answered are **not dropped**; their ids are logged and the reply says how many
  weren't given (those minted instances exist in the database without an item in game).
- Tests: `ItemMoreCommandTest` 15 → 18 (no upper limit, huge amount builds only what fits, minted copies not dropped;
  the max-1 test now expects 36 single items in an empty inventory). Plugin: core 2378 / api-client 284 / paper 2277,
  0 failures. No API change.

