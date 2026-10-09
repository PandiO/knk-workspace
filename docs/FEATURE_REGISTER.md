# Knights & Kings feature register

**Status:** Active · **Last updated:** 2026-10-09 · **First reconciled:** 2026-09-28 · [KNG-33](https://linear.app/kngpandi/issue/KNG-33)

This is the index of intended gameplay and shipped surfaces, not a substitute for a feature's design, code, or issue. V1's wider gameplay and V2's stronger data model are both inputs to V3. An absent V2 port is **not** a decision to drop a V1 feature. The [vision](vision/vision.md) decides intent; a [feature spec](specs/README.md) decides detailed behavior; the actual default branches decide whether code has shipped.

**Evidence baseline (checked 2026-09-30):** `knk-workspace/main` `4757fbb`, `knk-plugin/main` `27b4236`, `knk-web-api/master` `29b6c5d`, and `knk-web-app/main` `b9a3c43`. Legacy columns use the dated scans linked below. Later default-branch commits or Linear decisions supersede this snapshot and must update the affected rows.

**Targeted refresh (2026-10-04):** the moderation/private-message rows were rechecked after plugin
`main` merge `1a69ec3`; KNG-24, KNG-25 and KNG-28 are merged and Done. KNG-26/29/30 are also Done
on their stated default branches. KNG-38 is Done with its API half on `master` at merge `300aa4c`;
its web-app half followed on `main` at merge `24b60ac` (2026-10-06), so KNG-38 is fully merged.

## Reading and updating the register

- **Legacy:** `live` means the mining report identifies reachable behavior; `partial` includes stubs or bugs; `dead` means commented or unregistered code. `—` means no identified precedent, **not** proof of absence. V1/V2 source is archived; mining reports are dated snapshots.
- **Design:** `spec` = dedicated V3 design or plan; `vision` = direction only; `open` = no settled design; `n/a` = maintenance work. A spec's header can be stale: read decisions and follow-ups.
- **Implementation:** `complete` = the documented scope is code-complete; `partial` = some required behavior exists; `none` = no V3 implementation identified. This says what was built, independently of where it is merged.
- **Merge:** `trunk` = the stated implementation is on all required default branches; `branch` = it exists only on a feature branch; `mixed` = only some required components or behavior are on trunk; `—` = nothing is ready to merge. A branch is never counted as shipped.
- **Verification:** `live` = a documented live game or admin check; `pending` = no complete documented live check; `mixed` = part tested. Code status does not imply release readiness. Consult each feature's plan for the test scope.
- **Next:** `maintain`, `finish`, `design`, `decide`, or `later`. A Linear issue can be Done while remaining follow-ups have their own issues; the register tracks the whole feature.

For each changed row, include its source, spec or issue and the date of the evidence in the change or PR. Check current `main` (workspace, plugin, app) and `master` (API), plus the feature plan and Linear, before changing `branch` to `trunk`. At merge, update this register, relevant guides, and [CHANGELOG.md](CHANGELOG.md) using the [documentation maintenance guide](guides/developer/DOCUMENTATION_MAINTENANCE.md). Keep uncertain claims explicit. This inventory groups behavior by player-facing capability; it does not imply one issue or one release per row.

### World, travel and settlement

| Feature | V1 | V2 | V3 design | Implementation | Merge | Verification | Next / source |
|---|---|---|---|---|---|---|---|
| Towns, districts, structures, streets, locations; CRUD/regions | live | modeled | spec | complete | trunk | mixed | maintain; [towns](specs/towns/), [world tasks](specs/world-tasks/) |
| Kingdom/province hierarchy and wilderness Territory | partial | partial | vision | partial | mixed | pending | design; [vision §2](vision/vision.md#2-world-structure) |
| District containment and domain access rules | live | partial | vision | partial | mixed | mixed | finish; [vision §2.2](vision/vision.md#22-districts), [KNG-12](https://linear.app/kngpandi/issue/KNG-12); enforcement [doc](architecture/domain-access-enforcement.md) (KNG-56, KNG-74 refusal in chat merged and live-tested 2026-10-09) |
| Managed WorldGuard region ownership, priorities and category flags | live | partial | spec | complete | trunk | pending | live-test [KNG-46](https://linear.app/kngpandi/issue/KNG-46); [architecture](architecture/managed-worldguard-regions.md) |
| Gates: animation, damage, control and siege integration | live | partial | spec | complete | trunk | mixed | maintain; [gate specs](specs/gate-structure-animation/). 2026-10-08: [command layers `/gate`/`/gatedoor`, toggle, `here`, look-at](architecture/gate-commands.md) (KNG-77/78/79) on branch, not live-tested |
| Global world settings, deliberate join/spawn/weather/time rules | partial | partial | vision | partial | mixed | pending | design; [vision §2.7](vision/vision.md#27-game-world-settings) |
| Teleport, requests, spawn, warps and homes | live | partial | spec | complete | trunk | mixed | maintain [KNG-17](https://linear.app/kngpandi/issue/KNG-17); [design](specs/teleport/DESIGN.md). Housing-linked `/home` is separate. |
| Street graph and guided road navigation (incl. walkable last-mile paths) | — | — | spec | complete | trunk | mixed | finish: siege check C6, [KNG-73](https://linear.app/kngpandi/issue/KNG-73), [KNG-74](https://linear.app/kngpandi/issue/KNG-74), [KNG-75](https://linear.app/kngpandi/issue/KNG-75) (N15 destination-snap fix merged and live-tested 2026-10-09), [KNG-76](https://linear.app/kngpandi/issue/KNG-76); merged 2026-10-08 ([KNG-27](https://linear.app/kngpandi/issue/KNG-27), [KNG-51](https://linear.app/kngpandi/issue/KNG-51)); [plan](specs/navigation/IMPLEMENTATION_PLAN.md), [smoke test](guides/road-navigation-smoke-test.md) |
| Houses, rooms, property sales, rent, home ownership | live | partial | vision | none | — | pending | design after ownership decision; [legacy menus](specs/legacy/inventory-menu-screens.md), [vision §4](vision/vision.md#4-economy--professions) |
| Shops, shopkeepers, coupons, gem shop and player buying/selling | live | partial | vision | partial | mixed | pending | design with property economy; [legacy menus](specs/legacy/inventory-menu-screens.md), [items](specs/items/IMPLEMENTATION_PLAN.md) |
| Resource gathering, production structures and town economy | live | partial | vision | partial | mixed | pending | design integrated economy; [v1 events](specs/legacy/events-v1.md), [gap audit](reports/LEGACY_VS_V2_GAP_ANALYSIS.md) |
| Warehouses, storage and transport orders | partial | partial | vision | none | — | pending | design after production and ownership; [gap audit](reports/LEGACY_VS_V2_GAP_ANALYSIS.md) |

### Players, items and social systems

| Feature | V1 | V2 | V3 design | Implementation | Merge | Verification | Next / source |
|---|---|---|---|---|---|---|---|
| Accounts, web authentication and in-game linking | partial | partial | spec | complete | trunk | mixed | maintain; [users](specs/users/), [player guide](guides/users/PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md) |
| Permissions, ranks, premium tiers, owner/staff mode | live | partial | spec | complete | trunk | mixed | maintain; [user features](specs/user-features/), [KNG-7](https://linear.app/kngpandi/issue/KNG-7) |
| Titles, XP, progression rewards and salary | live | partial | spec | complete | trunk | live | maintain; [user features](specs/user-features/), [KNG-16](https://linear.app/kngpandi/issue/KNG-16) |
| Player management, moderation, freeze, staff chat and audit | partial | partial | spec | partial | mixed | mixed | maintain; KNG-24/KNG-26 completed; inventory-menu permission gaps remain; [user management](specs/user-management/) |
| Personal gameplay statistics, shareable profile and histories | partial | partial | open | partial | mixed | pending | design [KNG-34](https://linear.app/kngpandi/issue/KNG-34) with [KNG-14](https://linear.app/kngpandi/issue/KNG-14); [legacy user system](specs/legacy/user-system.md) |
| World activity telemetry, traversal heatmaps, interactions | — | partial | open | none | — | pending | design in [KNG-34](https://linear.app/kngpandi/issue/KNG-34); include retention, privacy and performance decisions |
| Coin/gem payments, balances and persistent transaction ledger | live | partial | spec | complete | trunk | live | maintain; [currency design](specs/currency-payments/DESIGN.md), [KNG-21](https://linear.app/kngpandi/issue/KNG-21) |
| XP and other numeric-property provenance and auditing | partial | partial | open | partial | mixed | pending | design [KNG-34](https://linear.app/kngpandi/issue/KNG-34) as extension of ledger/audit; [KNG-23](https://linear.app/kngpandi/issue/KNG-23) is marked duplicate, not proof of complete XP coverage |
| Item blueprints, grades, tags, origins, custom enchantments | live | partial | spec | complete | trunk | mixed | maintain; [items](specs/items/), [render pipeline](architecture/item-render-pipeline.md) (single assembler path + dark-gray descriptions merged and live-tested 2026-10-05), [KNG-5](https://linear.app/kngpandi/issue/KNG-5) |
| Item instances, ownership transfer, soulbound/ghosted, age bonuses | live | partial | spec | partial | mixed | mixed | finish instance lifecycle; [vision §9.1](vision/vision.md#91-items), [instance model](https://github.com/PandiO/knk-web-api/blob/master/Models/Item/ItemInstance.cs) |
| Kits, claims, first-join and premium purchases | partial | partial | spec | complete | trunk | mixed | finish first-join live check; [kit plan](specs/kits/IMPLEMENTATION_PLAN.md) |
| Lootboxes, rarity and world pickups | live | — | spec | complete | trunk | mixed | retest and decide [KNG-31](https://linear.app/kngpandi/issue/KNG-31) (follow-ups KNG-44 siege reel item hold and KNG-45 batch odds merged 2026-10-04, accepted without a live check; reel decoy enchantments live-tested and merged 2026-10-05); [plan](specs/lootboxes/IMPLEMENTATION_PLAN.md) |
| Inventory menu engine and initial hub/content | live | partial | spec | complete | trunk | mixed | maintain; [engine](specs/inventory-menu/IMPLEMENTATION_PLAN.md), [content](specs/inventory-menu/CONTENT_PORT_PLAN.md) |
| Remaining legacy menus: property, shops, friends, quests, skills, support | live | partial | open | none | — | pending | design per owning feature; [screen allocation](specs/legacy/inventory-menu-screens.md) |
| Private messages, reply, ignore and social spy | live | partial | spec | complete | trunk | mixed | maintain; KNG-25 completed; [design](specs/private-messages/DESIGN.md) |
| Friends, requests, mutual relationships and social visibility | live | — | open | none | — | pending | design [KNG-35](https://linear.app/kngpandi/issue/KNG-35) after statistics; [v1 commands](specs/legacy/commands-v1.md), [legacy menus](specs/legacy/inventory-menu-screens.md) |
| Skills, skill points, active/passive abilities and professions | partial | partial | vision | partial | mixed | pending | design; distinguish reachable v1 handlers from commented code; [v1 events](specs/legacy/events-v1.md), [vision §4.2](vision/vision.md#42-professions-open--list-not-final) |

### Combat, NPCs and world activities

| Feature | V1 | V2 | V3 design | Implementation | Merge | Verification | Next / source |
|---|---|---|---|---|---|---|---|
| Siege scenarios, teams, objectives and live matches | live | partial | spec | complete | trunk | live | maintain MVP; scheduled lobbies later; [siege plan](specs/siege-minigame/IMPLEMENTATION_PLAN.md) |
| Siege survival: NPC waves, gate repair and match economy | — | — | spec | none | — | pending | implement [KNG-50](https://linear.app/kngpandi/issue/KNG-50); [design](specs/siege-survival/DESIGN.md), [plan](specs/siege-survival/IMPLEMENTATION_PLAN.md) |
| Minimal clan and town team identity | — | partial | spec | complete | trunk | mixed | maintain; [vision §3.2](vision/vision.md#32-minimal-clan--default-team-identity-mvp), [siege design](specs/siege-minigame/DESIGN.md) |
| Clan conquest, clancastles, diplomacy and seasons | partial | partial | vision | partial | mixed | pending | design later; [vision §3](vision/vision.md#3-clan-conquest--seasons-long-term-with-mvp-relevant-subset) |
| Programmable NPCs, traits and entity behavior | live (Citizens integration) | partial | vision | none | — | pending | design shared NPC platform [KNG-36](https://linear.app/kngpandi/issue/KNG-36), inventory legacy integrations first; [vision §6–7](vision/vision.md#6-law-crime--safety) |
| NPC pathfinding over roads, structures and dynamic gates | partial | partial | open | none | — | pending | design in [KNG-36](https://linear.app/kngpandi/issue/KNG-36) after road graph and NPC requirements; [navigation](specs/navigation/DESIGN.md) covers **player guidance**, not NPC movement |
| Vendors, guards, bandits, bosses, companions and pets | partial | partial | vision | none | — | pending | design capabilities on shared NPC platform; [vision §6](vision/vision.md#6-law-crime--safety), [§9](vision/vision.md#9-equipment--magic) |
| Dungeons and configurable wave survival | — | — | vision | none | — | pending | design [KNG-37](https://linear.app/kngpandi/issue/KNG-37) after NPC platform; [vision §7.5](vision/vision.md#75-other-combat-systems-long-term) |
| Arena, duels, Hide and Seek, fishing, treasure and lottery | partial | partial | vision | none | — | pending | decide each activity's scope; [v1 commands](specs/legacy/commands-v1.md), [v1 events](specs/legacy/events-v1.md) |
| Domain discovery and one-time entry rewards | live | partial | spec | complete | trunk | mixed | maintain [KNG-20](https://linear.app/kngpandi/issue/KNG-20); [plan](specs/domain-discovery/IMPLEMENTATION_PLAN.md) |
| Voting, currency/skill-point pickups and other ambient rewards | live | — | open | none | — | pending | decide sources and anti-abuse controls; [v1 economy events](specs/legacy/events-v1.md) |
| Quests, assignments, tutorials and narrative | partial | partial | vision | none | — | pending | design after higher-priority systems; [vision §8](vision/vision.md#8-narrative--quests-deprioritized), [legacy menus](specs/legacy/inventory-menu-screens.md) |
| Law, justice, safezones and bandit encounters | partial | partial | vision | partial | mixed | pending | design justice and encounters; fix [KNG-12](https://linear.app/kngpandi/issue/KNG-12); [vision §6](vision/vision.md#6-law-crime--safety) |

## Current sequence and open decisions

1. Maintain this register and the documentation/changelog workflow ([KNG-33](https://linear.app/kngpandi/issue/KNG-33)); reconcile changes at every feature merge.
2. Design statistics and observability ([KNG-34](https://linear.app/kngpandi/issue/KNG-34)): player-facing records **and** operational and balancing telemetry. Existing `UserStatistics`, audit log and currency ledger are starting points, not a complete solution. Specify event schema, attribution, sampling, retention, access, consent and privacy, heatmap aggregation, export and abuse safeguards before collecting detailed movement trails.
3. Design friends and social relationships ([KNG-35](https://linear.app/kngpandi/issue/KNG-35)): discovery, requests, permissions and visibility, interactions with ignore and vanish, and public or private statistics sharing.
4. Design the shared NPC platform ([KNG-36](https://linear.app/kngpandi/issue/KNG-36)) and dungeon wave survival ([KNG-37](https://linear.app/kngpandi/issue/KNG-37)). Siege survival now has its own accepted design and implementation plan in [KNG-50](https://linear.app/kngpandi/issue/KNG-50).
5. Continue the property and economy, skills, item-lifecycle, remaining activities and long-term conquest designs. Vision §8 deliberately puts storyline and quests later.

**Source boundaries:** The [legacy specs index](specs/legacy/README.md) lists the v1/v2 code-mining reports. [LEGACY_VS_V2_GAP_ANALYSIS](reports/LEGACY_VS_V2_GAP_ANALYSIS.md) and [IMPLEMENTATION_STATUS_AUDIT](reports/IMPLEMENTATION_STATUS_AUDIT.md) were written on 2026-09-10 and are historical snapshots; later trunk merges override their status claims. The [legacy events report](specs/legacy/events-v1.md) contains commented handlers, unreachable commands and an internally corrected live-handler tally; treat it as evidence to inspect, not a list of features to blindly port. [ACTIVE_SESSIONS.md](ACTIVE_SESSIONS.md) and Linear track current work, while current code and recorded tests determine implementation and verification.
