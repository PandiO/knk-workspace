# Command & Permission Scan — v1, v2, v3 (2026-09-23)

> **See also:** this doc inventories permission *nodes*. For the full functional command catalog (every command's
> syntax, arguments, and actual behavior, not just its permission node) see
> [COMMAND_CATALOG_V3.md](COMMAND_CATALOG_V3.md) (v3) and
> [docs/specs/legacy/commands-v1.md](../legacy/commands-v1.md) / [commands-v2.md](../legacy/commands-v2.md)
> (v1/v2), added 2026-09-25 to close that gap.

**Status:** Final — new scan, requested to fill the gap left by the legacy spec-mining pass.
**Method:** v1/v2 findings are carried forward verbatim from [`legacy-spec-mining`'s
`user-system.md`](../legacy/user-system.md) (already source-grounded — not re-derived here).
v3 findings are a direct, fresh read of `knk-plugin` `main` (`plugin.yml` + every
`hasPermission(...)` call site, plus per-subcommand `CommandMetadata` registration in
`KnkAdminCommand.java`), cross-checked against the unmerged `plugin-scan` branch's
`docs/reports/plugin-scan-2026-09-21.md` (which inventoried commands/listeners but not
permission granularity).

Scope: every player/admin-facing command and every permission node currently in the
codebase — not just user/rank-specific ones — since a v3 rank/permission system will need
to know the full node surface it's taking over.

---

## 1. v1 — ad hoc nodes, external PermissionsEx

No `plugin.yml` `permissions:` block; every node is a bare string checked via
`sender.hasPermission(...)`, granted entirely by an external PermissionsEx install (confirmed
by direct `Bukkit.dispatchCommand(sender, "pex group ...")` calls).

**Full `k&k.*` node inventory** (grep across `v1/src`):

```
k&k.arena, k&k.co-owner, k&k.coins, k&k.donator, k&k.enchant,
k&k.enderchest(.others), k&k.experience, k&k.fly, k&k.gamemode(.others),
k&k.gate(.info/.passthrough/.toggle), k&k.gems, k&k.ghosted, k&k.heal,
k&k.hideandseek, k&k.home, k&k.house, k&k.initiate, k&k.join.nolocation,
k&k.kills, k&k.lore, k&k.menu, k&k.owner, k&k.product, k&k.property,
k&k.propertycategory, k&k.ranks(.co-owner/.modify/.owner/.staff), k&k.reload,
k&k.rename, k&k.repair, k&k.resourceproperty, k&k.room, k&k.rooms,
k&k.shopkeeper, k&k.soulbound, k&k.spawn(.others), k&k.spawnpoint,
k&k.specialskill, k&k.staff, k&k.street, k&k.teleport.normal/.owner/.staff,
k&k.test, k&k.town, k&k.treasure, k&k.tutorial.others, k&k.weather
```

**Rank/permission-relevant commands:**

| Command | Gate | Behavior |
|---|---|---|
| `/user default\|staff\|builder\|co-owner\|owner\|save\|remove <player\|all>` | `k&k.ranks` (`.co-owner`/`.owner` for top two tiers) | Dispatches `pex user <n> group add/remove <group>` — direct in-plugin PermissionsEx group management |
| `/default` | `k&k.ranks.modify` | Narrower duplicate: reset to default group only |
| `/ownermode`, `/staffmode` | `k&k.owner`/`k&k.co-owner`, `k&k.staff` | Vanish-like toggle; state in static maps, not persisted |
| `/experience`, `/nexttitle` | (none found) | Title/XP progression display and admin adjustment |
| `/donator` | (implied by `k&k.donator`) | Set/view purchased rank, incl. temporary with restore |

Known bug carried from `user-system.md`: `UserCommands`'s `"save"` branch checks
`k&k.ranks.staff` but doesn't `return` on failure — the save runs regardless of the check.

## 2. v2 — same convention, more structure, no in-plugin group management

- `plugin.yml`: one top-level permission per Bukkit command (`k&k.user`, `k&k.enderchest`,
  `k&k.creation.stashed`, 20+ more). **No entries for `k&k.donator`, `k&k.ranks`, `k&k.title`,
  or `k&k.experience`** — consistent with the Title/Donator system being dropped in v2.
- Fine-grained ACF `@CommandPermission("k&k.user.list")`-style annotations at the
  subcommand-method level (`UserCommand.java`: `k&k.user`, `.list`, `.fetch`, `.save`,
  `.statistics`).
- No `permissions:` defaults block in `plugin.yml` at all — every grant is still fully
  external (unnamed permissions plugin, presumably still PermissionsEx).
- **v1's in-plugin group-management commands (`/user staff|owner|...`, `/default`) have no
  v2 equivalent whatsoever.** Group/rank assignment, if it happens, happens entirely outside
  KnK's control.
- Owner/staff-mode: `k&k.owner`/`k&k.staff` checks remain ad hoc at call sites, but the
  toggle itself was never rebuilt (three separate stale TODOs confirm this was a deliberate,
  never-executed intent to restore it).

## 3. v3 — current state (fresh scan, 2026-09-23)

### 3.1 `plugin.yml` — the entire declared permission surface

```yaml
commands:
  knk:      permission: knk.admin
  account:  permission: knk.account.use
  ce:       permission: customenchantments.command.use

permissions:
  knk.admin                              (default: op)
  knk.gate.open.*                        (default: false)
  knk.gate.close.*                       (default: false)
  knk.gate.passthrough.use               (default: false)
  knk.gate.passthrough.instant           (default: false)
  knk.gate.admin                         (default: op; children: the four above)
  knk.account.use                        (default: true)
  knk.account.create                     (default: true)
  knk.account.link                       (default: true)
  knk.account.admin                      (default: op — placeholder, "future view/modify
                                           other players' accounts", not yet used anywhere)
  customenchantments.command.use         (default: true)
  customenchantments.command.add         (default: op)
  customenchantments.command.remove      (default: op)
  customenchantments.command.info        (default: true)
  customenchantments.command.info.others (default: op)
  customenchantments.command.cooldown.clear         (default: op)
  customenchantments.command.cooldown.clear.others  (default: op)
  customenchantments.command.reload      (default: op)
```

That's the full node inventory. **No group/rank/inheritance concept exists** — every node is
a flat boolean, granted the vanilla Bukkit way (server `permissions.yml`, or an external
plugin if one is installed — none is declared as a `depend`/`softdepend`).

### 3.2 `/knk` subcommand permission granularity — new finding

Every `/knk` subcommand registered in `KnkAdminCommand.java` (`health`, `cache`, `towns`,
`town`, `districts`, `district`, `locations`, `location`, `enchantments`, `itemblueprints`,
`menu`, `streets`, `street`, `gate`) is gated behind the **same single node, `knk.admin`** —
with one exception: `tasks`/`task-claim`/`task-status` use a separate `knk.tasks` node that
**isn't declared anywhere in `plugin.yml`** (so it silently falls back to Bukkit's
default-false-for-undeclared-permission behavior unless granted directly). There is currently
no per-feature granularity within `/knk` at all — an admin either has all of it or none of it.

### 3.3 Confirmed legacy leftovers — not caught by the plugin-scan branch

Grepping every `hasPermission(...)` call site (not just `plugin.yml`) surfaces three
call sites still checking the **old `k&k.*` namespace**, dead relative to the current
`knk.*` convention since nothing grants `k&k.*` anymore:

| File : line | Node checked | Note |
|---|---|---|
| `PlayerListener.java:140` | `k&k.join.owner` | Join-flow bypass check |
| `PlayerListener.java:171` | `k&k.owner` | |
| `PlayerListener.java:190` | `k&k.owner` | |
| `ScoreboardUtil.java:51` | `k&k.*` | Old wildcard root, used to detect "is this an owner" |

These four call sites are the only surviving trace of rank/owner gating anywhere in v3 —
i.e. **the code still expects an owner concept to exist**, it's just checking a permission
namespace nothing populates anymore. Worth reconciling onto whatever the new rank/permission
model settles on, not left to bit-rot further.

### 3.4 Custom-enchantment per-item permissions

`EnchantmentCommandValidator` and `EnchantmentInteractListener` both check
`"customenchantments." + <enchantmentId>` dynamically — one permission node **per
enchantment definition**, not declared in `plugin.yml` (dynamically named, so it can't be).
Relevant precedent for the new system: v3 already has at least one place that needs
per-entity-instance permission nodes, not just static ones.

---

## 4. What this means for the new rank/permission system

- **Migration surface is small.** v3's entire current node count (≈18 static + N dynamic
  enchantment nodes) is tiny next to v1's ~45-node `k&k.*` inventory — there's no large
  existing grant table to migrate, since nothing currently uses groups at all.
- **The `k&k.*` leftovers in `PlayerListener`/`ScoreboardUtil` are the one piece of "existing
  behavior" the new system needs to consciously replace**, not just add to.
- **`knk.account.admin` is an already-reserved placeholder node** with no code behind it yet —
  worth deciding whether the new permission-holder model absorbs it or it stays a flat node.
- **No `depend`/`softdepend` on any permissions plugin exists in v3** — confirms the dependency
  was already effectively dropped in practice, even before vision §5.1 made it official policy.

## 5. Open items surfaced by this scan (not answered by vision.md or user-system.md)

1. Should `/knk`'s current flat `knk.admin`-for-everything model be broken into per-subcommand
   nodes as part of this work, or is that explicitly out of scope for the rank/permission
   system itself (a separate cleanup)?
2. Should the four `k&k.*` leftover call sites be migrated as part of this feature's rollout,
   or tracked as a separate small cleanup ticket?
3. Should dynamically-named per-enchantment nodes (`customenchantments.<id>`) be modeled as a
   first-class pattern in the new permission-holder system (e.g. wildcard/prefix matching), or
   left as a special case outside it?
