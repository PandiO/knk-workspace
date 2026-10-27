# Alpha test run 1 — package I: teleport, kits, items (2026-10-27)

**Status:** In review — pushed on `claude/alpha-run-1-teleport-items`: knk-plugin `9b25ee7` (from `main` `3550cbb`),
knk-web-api `cbd8074` (from `master` `4d7a806`); not merged, not deployed, not live-tested
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
