# Knights & Kings v1: permissions and WorldGuard settings by category

Status: historical v1 configuration inventory (not a v3 specification). Last updated: 2026-09-28.

Source: six supplied v1 server backup files (PermissionsEx permissions.yml, WorldGuard global config.yml, world-specific config.yml, regions.yml, customFlags.yml and blacklist.txt). Database credential values are omitted from this public report. This is a literal inventory of configured values; it does not assert the final in-game outcome when another plugin, overlapping region, bypass permission or plugin default intervenes. The world-specific WorldGuard config contains `{}`, so this world inherits the supplied global config.

## PermissionsEx ranks

The `Direct permissions` column lists literal nodes (including explicit `-node` denials). Effective nodes also include all ancestor groups; wildcard expansion and conflict precedence depend on PermissionsEx and the installed plugins. Group name casing is retained.

| Group | Inherits | Direct permissions | World-specific |
|---|---|---|---|
| Default | [] | `k&k.home`<br>`customenchantments.poison`<br>`customenchantments.freeze`<br>`customenchantments.blindness`<br>`customenchantments.confusion`<br>`customenchantments.strength`<br>`customenchantments.resistance`<br>`customenchantments.flash_chaos`<br>`k&k.spawn`<br>`k&k.menu`<br>`-worldguard.region.info.*`<br>`-minecraft.command.op`<br>`-bukkit.command.plugins`<br>`ab.kick.notify`<br>`ab.ban.notify`<br>`ab.tempban.notify`<br>`ab.ipban.notify`<br>`ab.tempipban.notify`<br>`ab.mute.notify`<br>`ab.tempmute.notify`<br>`ab.warn.notify`<br>`ab.tempwarn.notify`<br>`ab.warns.own` | {"world": {"permissions": []}} |
| Owner | ["Builder", "co-owner"] | `*`<br>`mv.bypass.gamemode.*`<br>`ab.kick.excempt`<br>`ab.ban.exempt`<br>`ab.ban.undo`<br>`ab.tempban.exempt`<br>`ab.ipban.exempt`<br>`ab.tempipban.exempt`<br>`ab.mute.exempt`<br>`ab.tempmute.exempt`<br>`ab.warn.exempt`<br>`ab.warn.undo`<br>`ab.tempwarn.exempt`<br>`worldguard.*`<br>`bukkit.command.plugins`<br>`litebans.*`<br>`litebans.exempt.ban`<br>`litebans.exempt`<br>`litebans.exempt.*`<br>`litebans.exempt.warn` | — |
| Noble | ["Default"] | `customenchantments.health_boost` | — |
| Royal | ["Noble"] | `k&k.enderchest`<br>`customenchantments.invisibility`<br>`customenchantments.wither` | — |
| DragonBlood | ["Royal"] | `customenchantments.chaos`<br>`customenchantments.armor_repair` | — |
| Builder | ["Default"] | `worldedit.*`<br>`k&k.gamemode`<br>`bukkit.command.gamemode`<br>`bukkit.command.gamemode.*`<br>`gamemode.*`<br>`worldguard.region.bypass.*` | {"MardiGrasSquid": {"permissions": ["user"]}} |
| staff | ["DragonBlood"] | `k&k.spawn.others`<br>`k&k.staff`<br>`k&k.tutorial.others`<br>`ab.kick.use`<br>`ab.ban.perma`<br>`ab.ban.temp`<br>`ab.ipban.perma`<br>`ab.ipban.temp`<br>`ab.mute.perma`<br>`ab.mute.temp`<br>`ab.mute.undo`<br>`ab.warn.perma`<br>`ab.warn.temp`<br>`ab.warns.other`<br>`ab.check`<br>`ab.check.ip`<br>`ab.changeReason`<br>`ab.banlist`<br>`ab.history`<br>`ab.help`<br>`litebans.tempban`<br>`litebans.tempmute`<br>`litebans.unmute`<br>`litebans.kick`<br>`litebans.warn`<br>`litebans.warnings`<br>`litebans.warnings.self`<br>`litebans.history`<br>`litebans.banlist`<br>`litebans.checkban`<br>`litebans.checkmute`<br>`litebans.mutechat.bypass`<br>`litebans.lockdown.bypass`<br>`litebans.notify.silent`<br>`litebans.notify.clearchat`<br>`litebans.notify.banned_join`<br>`litebans.notify.mute`<br>`litebans.notify.dupeip_join`<br>`litebans.json.hover_text`<br>`litebans.tabcomplete`<br>`litebans.notify.broadcast`<br>`litebans.notify.warned`<br>`litebans.notify.muted` | — |
| co-owner | ["head-staff"] | `worldedit.navigation.thru.command`<br>`worldedit.*`<br>`worldguard.*`<br>`coreprotect.*`<br>`k&k.treasure`<br>`k&k.co-owner`<br>`k&k.join.nolocation`<br>`k&k.enchant`<br>`k&k.gamemode`<br>`k&k.fly`<br>`k&k.inventory.*`<br>`k&k.rename`<br>`k&k.lore`<br>`k&k.spawn.others`<br>`k&k.weather`<br>`k&k.property`<br>`k&k.house`<br>`k&k.room`<br>`k&k.town`<br>`k&k.street`<br>`k&k.coins`<br>`k&k.gems`<br>`k&k.heal`<br>`k&k.ranks`<br>`k&k.shopkeeper`<br>`k&k.coins`<br>`k&k.gems`<br>`minecraft.command.tp`<br>`bukkit.command.heal`<br>`bukkit.command.reload`<br>`bukkit.command.restart`<br>`litebans.group.unlimited`<br>`litebans.cooldown.bypass`<br>`litebans.unban`<br>`litebans.unban.queue`<br>`litebans.prunehistory`<br>`litebans.staffrollback`<br>`litebans.iphistory`<br>`litebans.ipban`<br>`litebans.ipmute`<br>`litebans.lastuuid`<br>`litebans.geoip`<br>`litebans.dupeip`<br>`litebans.dupeip.viewip`<br>`litebans.ipreport`<br>`litebans.togglechat`<br>`litebans.lockdown`<br>`litebans.admin`<br>`litebans.notify`<br>`litebans.exempt`<br>`litebans.exempt.warn`<br>`litebans.exempt.mute`<br>`litebans.exempt.kick`<br>`litebans.exempt.dupeip_join`<br>`-litebans.excempt.ban`<br>`worldguard.region.bypass.world`<br>`k&k.enderchest.others`<br>`k&k.soulbound`<br>`k&k.ghosted`<br>`customenchantments.*` | — |
| head-staff | ["staff"] | `litebans.ban`<br>`litebans.cooldown.bypass.ban`<br>`litebans.cooldown.bypass.warn`<br>`litebans.mute`<br>`litebans.unwarn`<br>`litebans.staffhistory`<br>`litebans.togglechat.bypass`<br>`litebans.clearchat.bypass`<br>`litebans.clearchat`<br>`litebans.mutechat`<br>`spartan.*` | — |

### Inheritance and anomalies

- `Default` includes: (no inherited groups).
- `Owner` includes: `co-owner`, `head-staff`, `DragonBlood`, `Noble`, `Default`, `Royal`, `staff`, `Builder`.
- `Noble` includes: `Default`.
- `Royal` includes: `Default`, `Noble`.
- `DragonBlood` includes: `Noble`, `Default`, `Royal`.
- `Builder` includes: `Default`.
- `staff` includes: `Noble`, `Default`, `Royal`, `DragonBlood`.
- `co-owner` includes: `Noble`, `head-staff`, `DragonBlood`, `Default`, `Royal`, `staff`.
- `head-staff` includes: `Noble`, `DragonBlood`, `Default`, `Royal`, `staff`.
- The user assignments include both `Default` and lowercase `default`, but only `Default` is defined in this file. The `default` assignments cannot be resolved from this backup. The user-specific `*` for `__pandi__` applies in `world`.
- Literal spelling retained, including `ab.kick.excempt` and `-litebans.excempt.ban`; check whether the intended plugins recognize these nodes. Duplicate `k&k.coins` and `k&k.gems` appear in `co-owner`.

## Global WorldGuard configuration

| Setting | Configured value |
|---|---|
| `regions.uuid-migration.perform-on-next-start` | `False` |
| `regions.uuid-migration.keep-names-that-lack-uuids` | `True` |
| `regions.use-creature-spawn-event` | `True` |
| `regions.sql.use` | `False` |
| `regions.sql.dsn` | `jdbc:mysql://localhost/worldguard` |
| `regions.sql.username` | `worldguard` |
| `regions.sql.password` | [omitted from public report] |
| `regions.sql.table-prefix` | `` |
| `regions.enable` | `True` |
| `regions.invincibility-removes-mobs` | `False` |
| `regions.nether-portal-protection` | `False` |
| `regions.fake-player-build-override` | `True` |
| `regions.explosion-flags-block-entity-damage` | `True` |
| `regions.high-frequency-flags` | `False` |
| `regions.protect-against-liquid-flow` | `False` |
| `regions.wand` | `334` |
| `regions.max-claim-volume` | `30000` |
| `regions.claim-only-inside-existing-regions` | `False` |
| `regions.max-region-count-per-player.default` | `7` |
| `auto-invincible` | `False` |
| `auto-invincible-group` | `False` |
| `auto-no-drowning-group` | `False` |
| `use-player-move-event` | `True` |
| `use-player-teleports` | `True` |
| `security.deop-everyone-on-join` | `False` |
| `security.block-in-game-op-command` | `True` |
| `summary-on-start` | `True` |
| `op-permissions` | `True` |
| `build-permission-nodes.enable` | `False` |
| `build-permission-nodes.deny-message` | `&eSorry, but you are not permitted to do that here.` |
| `event-handling.block-entity-spawns-with-untraceable-cause` | `False` |
| `event-handling.interaction-whitelist` | `[]` |
| `event-handling.emit-block-use-at-feet` | `[]` |
| `protection.item-durability` | `True` |
| `protection.remove-infinite-stacks` | `False` |
| `protection.disable-xp-orb-drops` | `False` |
| `protection.disable-obsidian-generators` | `False` |
| `gameplay.block-potions` | `[]` |
| `gameplay.block-potions-overly-reliably` | `False` |
| `simulation.sponge.enable` | `False` |
| `simulation.sponge.radius` | `3` |
| `simulation.sponge.redstone` | `False` |
| `default.pumpkin-scuba` | `False` |
| `default.disable-health-regain` | `False` |
| `physics.no-physics-gravel` | `False` |
| `physics.no-physics-sand` | `False` |
| `physics.vine-like-rope-ladders` | `False` |
| `physics.allow-portal-anywhere` | `False` |
| `physics.disable-water-damage-blocks` | `[]` |
| `ignition.block-tnt` | `False` |
| `ignition.block-tnt-block-damage` | `True` |
| `ignition.block-lighter` | `False` |
| `fire.disable-lava-fire-spread` | `True` |
| `fire.disable-all-fire-spread` | `False` |
| `fire.disable-fire-spread-blocks` | `[]` |
| `fire.lava-spread-blocks` | `[]` |
| `mobs.block-creeper-explosions` | `False` |
| `mobs.block-creeper-block-damage` | `True` |
| `mobs.block-wither-explosions` | `False` |
| `mobs.block-wither-block-damage` | `True` |
| `mobs.block-wither-skull-explosions` | `False` |
| `mobs.block-wither-skull-block-damage` | `True` |
| `mobs.block-enderdragon-block-damage` | `False` |
| `mobs.block-enderdragon-portal-creation` | `False` |
| `mobs.block-fireball-explosions` | `False` |
| `mobs.block-fireball-block-damage` | `True` |
| `mobs.anti-wolf-dumbness` | `False` |
| `mobs.allow-tamed-spawns` | `True` |
| `mobs.disable-enderman-griefing` | `True` |
| `mobs.disable-snowman-trails` | `False` |
| `mobs.block-painting-destroy` | `False` |
| `mobs.block-item-frame-destroy` | `False` |
| `mobs.block-plugin-spawning` | `True` |
| `mobs.block-above-ground-slimes` | `False` |
| `mobs.block-other-explosions` | `False` |
| `mobs.block-zombie-door-destruction` | `False` |
| `mobs.block-creature-spawn` | `[]` |
| `player-damage.disable-fall-damage` | `False` |
| `player-damage.disable-lava-damage` | `False` |
| `player-damage.disable-fire-damage` | `False` |
| `player-damage.disable-lightning-damage` | `False` |
| `player-damage.disable-drowning-damage` | `False` |
| `player-damage.disable-suffocation-damage` | `False` |
| `player-damage.disable-contact-damage` | `False` |
| `player-damage.teleport-on-suffocation` | `False` |
| `player-damage.disable-void-damage` | `False` |
| `player-damage.teleport-on-void-falling` | `False` |
| `player-damage.disable-explosion-damage` | `False` |
| `player-damage.disable-mob-damage` | `False` |
| `player-damage.disable-death-messages` | `False` |
| `chest-protection.enable` | `False` |
| `chest-protection.disable-off-check` | `False` |
| `crops.disable-creature-trampling` | `True` |
| `crops.disable-player-trampling` | `True` |
| `weather.prevent-lightning-strike-blocks` | `[]` |
| `weather.disable-lightning-strike-fire` | `False` |
| `weather.disable-thunderstorm` | `False` |
| `weather.disable-weather` | `False` |
| `weather.disable-pig-zombification` | `False` |
| `weather.disable-powered-creepers` | `False` |
| `weather.always-raining` | `False` |
| `weather.always-thundering` | `False` |
| `dynamics.disable-mushroom-spread` | `False` |
| `dynamics.disable-ice-melting` | `False` |
| `dynamics.disable-snow-melting` | `False` |
| `dynamics.disable-snow-formation` | `False` |
| `dynamics.disable-ice-formation` | `False` |
| `dynamics.disable-leaf-decay` | `False` |
| `dynamics.disable-grass-growth` | `False` |
| `dynamics.disable-mycelium-spread` | `False` |
| `dynamics.disable-vine-growth` | `False` |
| `dynamics.disable-soil-dehydration` | `True` |
| `dynamics.snow-fall-blocks` | `[]` |
| `blacklist.use-as-whitelist` | `False` |
| `blacklist.logging.console.enable` | `True` |
| `blacklist.logging.database.enable` | `False` |
| `blacklist.logging.database.dsn` | `jdbc:mysql://localhost:3306/minecraft` |
| `blacklist.logging.database.user` | `root` |
| `blacklist.logging.database.pass` | [omitted from public report] |
| `blacklist.logging.database.table` | `blacklist_events` |
| `blacklist.logging.file.enable` | `False` |
| `blacklist.logging.file.path` | `worldguard/logs/%Y-%m-%d.log` |
| `blacklist.logging.file.open-files` | `10` |

Relevant global consequences: WorldGuard regions are enabled; SQL region storage is disabled. Global config does not disable fall, explosion, mob, lava, fire or drowning damage. Creeper, wither, wither-skull and fireball **block** damage is blocked, while their explosion switches remain unblocked. TNT block damage is blocked. Lava fire spread, enderman griefing, player/creature crop trampling and soil dehydration are disabled. These settings can be overridden by region flags or other plugins.

## WorldGuard region flags by category

This section groups the 298 regions by their base-region type. The flags below are **explicitly configured** values; absent flags are not equivalent to `allow`. Child regions generally have empty flag sets and inherit from their parent, subject to overlapping regions and priorities. Town-specific greetings and messages vary by town.

| Category | Regions | Shared base-region flags | Exceptions and child regions |
|---|---:|---|---|
| Town | 5 bases, 68 children | `damage-animals: allow`; `entity-item-frame-destroy: deny`; `mob-spawning: deny`; `pvp: deny`; empty `deny-message`; town-specific `greeting`, `farewell`, `entry-deny-message` | `town_18`, `town_15`, `town_16`, and `town_12` set `entry: allow`; `town_14` has no explicit `entry` flag. All children have no explicit flags. |
| House | 29 bases, 61 children | `entry: deny`; `entry-deny-message: ''`; `feed-amount: 20`; `feed-delay: 1` | `house_9` also has `deny-message: ''`. All children have no explicit flags. |
| Property | 36 bases, 17 children | `entry: allow`; `entry-deny-message: ''` | 22 bases also have `deny-message: ''`. `property_45`, `property_46`, and `property_47` set `block-break: allow`. `property_47` additionally sets `allow-blocks: LOG;` for a wood farming resource production structure. All children have no explicit flags. |
| Arena | 1 base, 50 children | `arena_2` has `entry: allow`; `entry-deny-message: ''` | Eight `-battleground` children explicitly set `entry: deny` and `pvp: allow`; the other 42 children have no explicit flags. |
| Room | 22 bases, 8 children | `entry: deny`; `entry-deny-message: ''`; `feed-amount: 20`; `feed-delay: 1` | 17 bases additionally have `deny-message: ''`; five do not. All children have no explicit flags. |
| Global | 1 | `build: deny`; `damage-animals: allow`; `pvp: allow`; `deny-message: ''` | Region name: `__global__`. |

### Interpretation notes

- The town `entry-deny-message` text contains rank requirements, but the text itself is not proof that WorldGuard enforced a rank check. Four towns explicitly allow entry; `town_14` leaves its entry flag unset.
- `property_47` was a resource production structure for farming wood. Its `allow-blocks: LOG;` also appears in the supplied custom-flags file. The exact interaction between that custom flag and `block-break: allow` depends on the v1 custom-flags plugin.
- At the global region level PvP is allowed and building is denied. Towns explicitly deny PvP, while battleground regions explicitly allow it; region overlap and priority determine which applies at a given location.
- The world-specific WorldGuard configuration is `{}`, so the supplied global WorldGuard settings apply to this world unless overridden elsewhere.

## Blacklist contents

```text
#
# WorldGuard blacklist
#
# The blacklist lets you block actions, blocks, and items from being used.
# You choose a set of "items to affect" and a list of "actions to perform."
#
###############################################################################
#
# Example to block some ore mining and placement:
# [coalore,goldore,ironore]
# on-break=deny,log,kick
# on-place=deny,tell
#
# Events that you can detect:
# - on-break (when a block of this type is about to be broken)
# - on-destroy-with (the item/block held by the user while destroying)
# - on-place (a block is being placed)
# - on-use (an item like flint and steel or a bucket is being used)
# - on-interact (when a block in used (doors, chests, etc.))
# - on-drop (an item is being dropped from the player's inventory)
# - on-acquire (an item enters a player's inventory via some method)
# - on-dispense (a dispenser is about to dispense an item)
#
# Actions (for events):
# - deny (deny completely, used blacklist mode)
# - allow (used in whitelist mode)
# - notify (notify admins with the 'worldguard.notify' permission)
# - log (log to console/file/database)
# - tell (tell a player that that's not allowed)
# - kick (kick player)
# - ban (ban player)
#
# Options:
# - ignore-groups (comma-separated list of groups to not affect)
# - ignore-perms (comma-separated list of permissions to not affect - make up
#   your very own permissions!)
# - comment (message for yourself that is printed with 'log' and 'notify')
# - message (optional message to show the user instead; %s is the item name)
#
###############################################################################
#
# For more information, see:
# http://wiki.sk89q.com/wiki/WorldGuard/Blacklist
#
###############################################################################
#
# Some examples follow.
# REMEMBER: If a line has # in front, it will be ignored.
#

# Deny lava buckets
#[lavabucket]
#ignore-perms=my.own.madeup.permission
#ignore-groups=admins,mods
#on-use=deny,tell

# Deny some ore
#[coalore,goldore,ironore]
#ignore-groups=admins,mods
#on-break=notify,deny,log

# Some funky data value tests
#[wood:0;>=2]
#ignore-groups=admins,mods
#on-break=notify,deny,log
```
