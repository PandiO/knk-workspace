# Invisibility full hide (#211) and lore line wrap (#212) — 2026-11-02

**Status:** #211 in review (branch pushed, not merged, not deployed, not live-tested). #212 not re-implemented:
it already had an in-review branch from an earlier session today; verified here, see § 2
**Last updated:** 2026-11-02
**Issues:** [PandiO/knk-workspace#211](https://github.com/PandiO/knk-workspace/issues/211),
[#212](https://github.com/PandiO/knk-workspace/issues/212) (sub-issues of #149)
**Base:** knk-plugin `main` `c8232607` (core 2401 / api-client 288 / paper 2343)

## 1. #211 — the Invisibility ability hides armour and held items, tab entry kept

**Branch:** knk-plugin `claude/invisibility-full-hide` `3c5407e` (one commit on `c8232607`); knk-workspace
`claude/invisibility-full-hide` (admin guide § 5 note, this report).

**Choice: per-viewer equipment packets through the Paper API, no packet library.**

| Option | Tab entry | Verdict |
|---|---|---|
| `Player#hidePlayer` (owner/staff mode) | removed (player info remove packet) | no |
| `hideEntity` on a player | removed (same path) | no |
| `hidePlayer` + `listPlayer` | Paper's `listPlayer` only lists a player the viewer can see, so it can't put the entry back | no |
| Cancel `PlayerTrackEntityEvent` | kept | only works for viewers who start tracking later; also makes the user unhittable |
| **Vanilla Invisibility + `Player#sendEquipmentChange` with empty items per viewer** | **kept** | **chosen** |

Vanilla Invisibility already hides the body and the name tag (the tag on the rank board through #169's
`InvisibleNameTag`). The new `InvisibleEquipment` (`knk-paper/.../enchantment/display/`) sends every player tracking the
user empty head, chest, legs, feet, main hand and off hand, unless the viewer sees through the invisibility by the
client's own rule: a spectator, or the user's team on the viewer's own board with "can see friendly invisibles" on. The
siege boards set that only for the viewer's own siege team, so G's siege behaviour stays: teammates see a see-through
body with tag and equipment, the other team sees nothing. The user stays a normal entity, so hits and arrows work as
in vanilla.

The server resends the real equipment when it changes or when a viewer starts tracking the user, so the mask goes out
again one tick after `EntityEquipmentChangedEvent` and `PlayerTrackEntityEvent`, and every 10 ticks as a safety net.
A held item can show for about one tick after a hotbar switch.

**Ends:** Invisibility removed or cleared (expiry, milk, death, `/effect clear`) → the masked viewers get the real
equipment back; also on death and on plugin disable (`KnKPlugin.onDisable` → `revealAll`). On quit, and on disable,
the ability's Invisibility is removed so the player is visible to everyone after a relog or restart.

**Also changed:** the ability's potion is applied without swirl particles (HUD icon kept), since the swirls gave the
user away. Hits keep the vanilla behaviour.

**Known gap:** arrows stuck in the body are drawn from the entity's arrow count, which has no per-viewer Paper API;
they can still show (to check live). Not fixed here.

**Tests (full suites, `./gradlew test` and `./gradlew build -x deployToDevServer`, JDK 25 toolchain):**

| Module | main `c8232607` | `claude/invisibility-full-hide` |
|---|---|---|
| knk-core | 2401 | 2401 |
| knk-api-client | 288 (2 skipped) | 288 (2 skipped) |
| knk-paper | 2343 (18 skipped) | 2359 (18 skipped), 0 failures |

New: `InvisibleEquipmentTest` (15), `EffectBossBarsTest.invisibleHidesTheEquipmentForPlayersOnly`.

**Live check:**
1. Deploy the branch (`./gradlew :knk-paper:dev`). Two players of the same rank, the user in armour with a sword.
2. Use the Invisibility ability: the other player sees no body, armour, held item, name tag or swirls; the user is
   still in the other player's tab list and can still be hit.
3. Switch hotbar items and put armour on/off while invisible; walk out of range and back: nothing shows (at most a
   one-tick flash on a switch).
4. Drink milk: armour and items show again at once. Repeat and let it run out; repeat and die.
5. Repeat and relog: the user comes back visible, not invisible.
6. In a siege: a teammate still sees the user (see-through, tag, armour); a player of the other team sees nothing.
7. Check whether arrows stuck in the user's body still show (known gap).

## 2. #212 — lore line wrap: already in review, not redone

When this session started, #212 already had `status:in-review` and a full implementation by an earlier session the same
day: knk-plugin `claude/item-lore-212-40-0ud18o` `cb0cd70` (one commit on `c8232607`, bundled with #40, which needs the
inverse of the wrap), knk-workspace `claude/item-lore-212-40-0ud18o` `8169033`
([#212 comment](https://github.com/PandiO/knk-workspace/issues/212#issuecomment-6577087857)). It covers everything the
task asked for: a shared, tested `LoreWrap` in knk-core (visible characters, colour codes ignored, colour/format carried
to continuation lines, word boundaries, configurable `lore.max-width: 40`), used by the item render pipeline
(`ItemBlueprintBukkitMapper`), every menu's lore (`MenuItemBukkitMapper.applyLore`) and `KitMenuRow` (replacing #172's
own wrap). Writing a second implementation on `claude/lore-line-wrap` would have produced two competing branches over
the same files, so per the board's overlap rule this session verified that branch instead and created no
`claude/lore-line-wrap`.

**Verification here:** `./gradlew test` and `./gradlew build -x deployToDevServer` on `cb0cd70`: core 2424 / api-client 288
(2 skipped) / paper 2352 (18 skipped), 0 failures, build green: the same counts the #212 comment reports. Its
knk-plugin branch and `claude/invisibility-full-hide` merge without conflicts (`git merge-tree`).

## 3. For the developer

- #211: decide whether the swirl-particle change is wanted, and whether stuck arrows matter enough for an issue.
- #212: merge `claude/item-lore-212-40-0ud18o` (with #40) as the #212 branch, or say if it must be split from #40
  onto a separate `claude/lore-line-wrap`.
