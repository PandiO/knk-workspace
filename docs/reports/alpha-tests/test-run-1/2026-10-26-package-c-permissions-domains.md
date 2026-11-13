# Alpha test run 1 — package C: permissions and domains (2026-10-26)

**Status:** In review — pushed on `claude/alpha-run-1-permissions` in knk-plugin `352cdd7c` (from `main` `ee35fb1d`) and
knk-web-api `e8af7ca` (from `master` `6f08383`); not merged, not deployed, not live-tested
**Last updated:** 2026-10-26
**Issues:** [PandiO/knk-workspace#158](https://github.com/PandiO/knk-workspace/issues/158),
[#157](https://github.com/PandiO/knk-workspace/issues/157), [#162](https://github.com/PandiO/knk-workspace/issues/162),
[#159](https://github.com/PandiO/knk-workspace/issues/159) (all P1); parent [#149](https://github.com/PandiO/knk-workspace/issues/149)
**Handoff:** [2026-10-25-alpha-run-1-p0-p1.md](../../../ai-agents/handoffs/2026-10-25-alpha-run-1-p0-p1.md) § 1 package C ·
**Findings:** [test-run-1-findings.md](test-run-1-findings.md) ·
**Scan:** [2026-10-26-command-permission-scan.md](../../2026-10-26-command-permission-scan.md)

Claude Code (subagent in the coordinator session, after the package's own cloud session was refused `add_repo`)
traced the four issues against the default branches and fixed them in knk-plugin, with the rank seeds in knk-web-api.
No issue had a P0; they were done in the handoff's order, #158, #157, #162, #159.

## 1. What the code did, and what changed

| Issue | Found on the default branch | Change |
|---|---|---|
| #158 command permission audit | The in-house permission system never reaches Bukkit's permissions, so (a) vanilla `/gamemode` is op only, (b) every Bukkit-only check ignores rank grants: menu item permissions and the `permission-node` condition, the Player manager's reads and freeze buttons, gate block breaking, InstantOpen pass-through, and the custom-enchantment nodes; (c) `/knk item` sat on the `knk.admin` umbrella; (d) `knk.tasks`, `knk.fly`, `knk.enderchest.open`, `knk.inventory.*`, `knk.hub.bypass` and package A's `knk.siege.admin.join` had no rank; knk-web-api seeded no `knk.siege.*` node. Full inventory: [scan report](../../2026-10-26-command-permission-scan.md). | knk-plugin `dc9e2679`: new `/gamemode <mode> [player]` (`/gm`, nodes `knk.gamemode.<mode>` + `.others`); `/knk item` node `knk.admin.item`; `MenuPermissions` and in-house checks in the Player manager and gates; `CommandNodesTest` checks every gated command's nodes are declared. knk-web-api `e8af7ca`: migration `SeedCommandPermissionNodes` (§ 3). The custom-enchantment checks are **not** changed (decision needed, and `/ce` is on package B's branch): **to file**, see § 4. |
| #157 container bypass | Storage in towns and other domains is refused by WorldGuard to non-members (`chest-access`, falling back to `build`); ops pass through WorldGuard's own bypass. No KnK rule involved. Staff/owner mode was already exempt in the same way elsewhere (`SiegeInventoryGuardListener`: active mode ≠ NONE). | knk-plugin `03c69926`: `ContainerAccessBypass` + `ContainerAccessWorldGuardListener` mark WorldGuard's use event on storage (blocks with an inventory, storage minecarts, chest boats) allowed before WorldGuard's check for players in staff or owner mode and holders of the new `knk.region.bypass.containers` (seeded for Moderator and Admin, **not** Staff). The `HubWorldGuardListener` pattern. Siege and hub rules are untouched. |
| #162 effect damage in domains | No such rule. Players took fire, lava, poison, wither etc. everywhere; only PvP and custom-enchantment hits were stopped in Town/District safezones (KNG-11). | knk-plugin `799611ad`: `DomainEffectDamage` (core rule) + `DomainEffectDamageListener`: in any domain, the causes in `regions.effect-damage.causes` (default FIRE, FIRE_TICK, LAVA, CAMPFIRE, HOT_FLOOR, POISON, WITHER, MAGIC, DRAGON_BREATH, FREEZE) don't hurt players, and a burning player is put out. New WorldGuard flag `knk-effect-damage` (`allow`/`deny`) decides when set; unset, `pvp allow` at the spot (battlegrounds, a town opened for PvP) keeps effect damage. Siege members (lobby at the hub or in a match) keep the siege's rules, gate fire included. Switch `regions.effect-damage.enabled`. |
| #159 join-refusal notice | Refusals were only logged. Refusing checks: vanilla ban/whitelist/full (Paper's login validation), the admission gate (LOWEST), the world readiness check (LOW), the hub (HIGH). | knk-plugin `352cdd7c`: `JoinRefusalNotifier`: online holders of `knk.notify.joinattempt` (seeded for Staff) get `[Join] <name> tried to join and was refused: <reason> (<detail>)`. The KnK checks record their reason first (`JoinRefusalReasons`), so the admission gate's disconnect screen, which holds the claim code, is never shown; vanilla refusals are classified from the ban lists (with the ban reason), IP bans, whitelist and player limit; another plugin's refusal shows its disconnect text. One notice per player per `join-refusal-notify.cooldown-seconds` (60). |

## 2. Decisions taken here (reversible; please review)

- **Rank defaults for the new and unseeded nodes** (§ 3): `/gamemode` survival + spectator for Staff, other players
  for Moderator, every mode (creative, adventure) for Admin; `/fly` Staff, `/fly <player>` Moderator; inventory and
  ender chest viewing Moderator, `/inventory clear` Admin; `knk.tasks` and the item nodes Staff; `knk.hub.bypass`
  Admin; refused-join notices Staff.
- **Effect damage:** LAVA, MAGIC and FREEZE count as effect damage; `pvp allow` keeps effect damage where the new
  flag is unset; every domain type counts (not only Town/District as for the PvP safezone); players only.
- **Container bypass** covers every block with an inventory (also furnaces, brewing stands, hoppers, lecterns), not
  only chests; the general Staff rank only passes in staff mode.
- `/gamemode` takes over the bare label like `/tp`; vanilla stays at `/minecraft:gamemode`.

## 3. Rank seeds (knk-web-api `SeedCommandPermissionNodes`)

Staff tier (→ Staff, and Moderator/Admin unless inherited): `knk.tasks`, `knk.admin.item`, `knk.admin.itemblueprints`,
`knk.gamemode.survival`, `knk.gamemode.spectator`, `knk.fly`, `knk.notify.joinattempt`. Moderator tier:
`knk.region.bypass.containers`, `knk.gamemode.others`, `knk.fly.others`, `knk.enderchest.open`, `knk.inventory.open`.
Admin: `knk.gamemode.*`, `knk.siege.admin.join`, `knk.hub.bypass`, `knk.inventory.clear`. Back-filled where missing
(kept by Down): `knk.siege.play` Default, `knk.siege.skip` Noble, `knk.siege.admin.list|control|reload|manage` and
`knk.siege.bypass.commands` Staff. A group that is missing, or already decides the node itself or through its parent
chain (grant, deny or covering wildcard), is skipped. On a copy of the alpha seed (MySQL 8.0): 16 rows (7 Staff,
5 Moderator, 4 Admin), nothing on a second run, Down back to the original 104 grants.

## 4. Not done / to file

- **To file (sub-issue of #149; creating issues was refused in this session):** "Custom enchantments: support
  enchantments and `/ce` subcommands are op-only". `EnchantmentInteractListener` only activates a SUPPORT
  enchantment (chaos, flash chaos, health boost, armor repair, resistance, invisibility) when
  `player.hasPermission("customenchantments.<id>")` — Bukkit only and undeclared, so op only as far as the code shows
  (verify with a non-op account). The `/ce` subcommand nodes are Bukkit-only too. Needs a decision on whether the
  per-enchantment nodes stay a gate; scan F6.
- `/heal`, `/feed`, the `/back` kinds and the `knk.gate.*` nodes still have no rank (design call, scan § 5).
- Other vanilla commands stay op-only (scan F11).

## 5. Tests

| Repo | Default branch | `claude/alpha-run-1-permissions` |
|---|---|---|
| knk-plugin `./gradlew build -x deployToDevServer` (JDK 25) | core 2312, api-client 280 (2 skipped), paper 2140 (18 skipped); 0 failures | core 2319, api-client 280, paper 2169; 0 failures |
| knk-web-api `dotnet test` | 3296 passed, 4 failed, 87 skipped | 3305 passed, the same 4 failed, 88 skipped (+1 requires-mysql test) |

The 4 API reds are the known ones on `master` (`ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`,
`FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`,
`PathResolutionServiceTests.ValidatePathAsync_AllowsValidV1Paths` ×2). The new requires-mysql test
(`SeedCommandPermissionNodesMySqlTests`) passed against a local MySQL 8.0; the migration was also run on a copy of the
alpha seed.

**Merging:** the plugin branch merges without conflicts with package A (`claude/alpha-run-1-siege`) and B
(`claude/alpha-run-1-enchantments`), also all three together; `plugin.yml`, `config.yml` and `KnKPlugin.java` are
changed by all of them in different places. The API branch merges cleanly with B; its migration is data only (no model
snapshot change) and sorts after B's `20261026115127_AddEnchantmentCombatValues`. In knk-workspace the findings report's
"Last updated" line and `ACTIVE_SESSIONS.md` rows are touched by every package (trivial conflicts). Package D's branch
was not on the remote when this was written.

## 6. Live checklist for test run 2

Deploy both branches (the API migration seeds the ranks), then with a **non-op** account in each group:

1. **#158** As Staff: `/gamemode spectator`, `/gm s` work; `/gamemode creative` says no permission; `/gamemode s <other>`
   refused. As Moderator: `/gamemode s <other>` works. As Admin: `/gamemode creative`. `/minecraft:gamemode` still
   needs op. Tab completion shows only your modes.
2. **#158** As Staff: `/knk item rename &6Test`, `/knk itemblueprints list`, `/knk itemblueprints give <id>`,
   `/knk tasks` work. The `/menu` hub shows the Player manager tile, the list fills, freeze/unfreeze work.
3. **#158** A non-op given `knk.gate.admin` (from an admin account: `/knk user <them> perm grant knk.gate.admin 10m`) can break
   gate blocks; without it they can't.
4. **#157** In a town: a Default player can't open a chest or barrel; a Staff member out of staff mode can't; the same
   Staff member in `/staffmode` can; a Moderator and an Admin can without a mode; owner mode can. A chest minecart
   behaves the same. Siege and hub rules are unchanged.
5. **#162** In a town or district: stand in fire, in lava, drink/throw a poison or harming potion, stand on magma —
   no damage, fire goes out. `/rg flag <town region> knk-effect-damage allow` → damage again; `deny` → none even with
   `pvp allow`. In a battleground (pvp allow), fire hurts. In a siege match, gate fire and enchantment effects still
   hurt. Outside every domain nothing changed.
6. **#159** As Staff online: have a non-admitted account try to join (invite mode) → "[Join] X tried to join and was
   refused: invite-only ..." without any code; `/ban X griefing` then join → "banned (griefing)"; turn the whitelist
   on with someone not on it → "not on the whitelist". Reconnect spam gives one line per 60 s. A Default player sees
   nothing.
