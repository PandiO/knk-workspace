# Knights & Kings — Game Vision

> Working vision document. Sections are tagged where relevant:
> **[MVP]** — required for the near-term Open Beta milestone (Siege minigame + core essentials production-ready).
> **[Long-term]** — part of the full vision, not required for MVP.
> **[OPEN]** — genuinely undecided; see the Open Questions appendix at the end.

## Document Scope: Two Horizons

This project has two distinct planning horizons that should not be conflated:

- **MVP / Open Beta [MVP]**: 1–2 kingdoms. Goal is getting the Siege minigame and other essential systems production-ready for a real open beta.
- **Long-term vision [Long-term]**: the full multi-kingdom (5–7 realm) seasonal clan-conquest game described below. This is the destination, not the starting point — most of this document describes that destination, with MVP-relevant items called out explicitly.

> **Note on legacy-version comparisons:** v2 was primarily a ground-up architecture and code-quality rewrite (database layer, package structure, leaner methods, general best practices) — not a feature triage. It deliberately focused on foundations first (districts/towns, items, user features/stats, Siege) and simply didn't get to reimplementing everything v1 had. **Default assumption throughout this document: a v1 feature missing from v2 is "not yet ported," not "dropped."** Where that's genuinely ambiguous, it's flagged as a question rather than assumed removed.

---

## 1. Core Concept

Knights & Kings is a persistent medieval-fantasy MMO server. Players are free to progress however they choose — adventuring and exploration, PvP, town life and chores, or climbing the occupation system — with multiple paths to leveling up, building wealth, and improving item quality. There is no single required playstyle.

The long-term destination for every player, whether they pursue it directly or not, is the clan layer: join a clan, rise through its ranks, and take part in **seasonal clan wars** — a recurring, world-spanning conquest cycle that determines who controls the game world until the next season resets it.

---

## 2. World Structure

### 2.1 Hierarchy

`Kingdom → Province → Town → District → Street (cross-cutting) → Structure`

- **Kingdom, Province, Town, District** are all fundamentally the same kind of thing: a region of the game world, each nested inside the one above it.
- **Structures** (Shop, House, Warehouse, Gate, Keep, Resource-Property, Tavern, Non-functional, …) are the concrete, ownable/interactable objects placed within a District.
- Every part of the game world belongs to at least one of these entities — there is no truly unowned land (see Territory, below).

### 2.2 Districts

Districts are fundamentally **neighborhoods** — subdivisions of a Town — not primarily a wealth-tier mechanism. "Wealth tier" is a *downstream effect*, not a separate system: a district reads as wealthy or poor as a byproduct of several independent factors layered together — entry requirements (player level, minimum coin/gem balance, clan, premium rank), average housing price, and the grade/rarity of commodities sold there.

**Access-gating** is a deliberate design pillar, modeled directly on how recent *Assassin's Creed* titles (Origins, Valhalla, Odyssey, Shadows) gate regions: entry to a Kingdom/Province/Town/District can be restricted outright, or made effectively impractical (very strong NPCs/opponents), based on player progression metrics — coin/gem balance, level, occupation and its level, equipment, clan, premium rank, etc.

**District containment [MVP-relevant]:** a District must be physically contained within its parent Town's region. This was enforced in the legacy v1 codebase and dropped in v2 (an unintentional regression) — v3 should restore real spatial containment, since access-gating only makes sense if a District corresponds to an actual place.

### 2.3 Territory (wilderness ownership — scoped entity)

Town regions should be kept strictly to the **settled/commerce footprint** — the part that actually contains Districts — not the surrounding fields, forests, and wilderness. To reconcile that with wanting every part of the world to belong to *someone*, Territory is a first-class entity in its own right, with its own gating, control, and resource dimensions:

- `id`, `name` (optional flavor name, e.g. "Blackwood Territory")
- `province` — every Territory belongs to exactly one Province by default (its administrative parent)
- `claimedByTown` (optional) — a Town may carve out and claim a Territory from its Province for finer per-town control (e.g. tuning ambush probability near that specific town); unclaimed Territory simply inherits Province-level default behavior
- `controlledBy` **[Long-term]** — the clan (or NPC baseline) currently holding practical influence here. This is deliberately separate from `province`/`claimedByTown` above: administrative parentage and *who currently controls it* are different questions, the same distinction the broader ownership model (2.6) makes at the Town/District level
- `accessConditions` (optional) — reuses the District access-gating model (level/wealth/clan/premium-rank thresholds). Most wilderness stays open by default; a claimed territory (e.g. a clan's private hunting ground) can gate entry the same way a District can
- `resourceYield` **[Long-term]** — resource types + base yield rate, modifiable by whoever controls the territory (tech-tree bonuses, structures built within it) — this is the mechanism for the "extra dimensions to resource flows, trade, and influence" goal
- `region` (optional) — a drawn polygon is only needed for territories requiring precise gating or yield-location logic; most territories can rely on nearest-claim geometry with no drawn region at all
- `ambientEncounterProfile` — bandit ambush/camp spawn weighting (ties into Section 6)

**Scoping:** the parent/claim/region skeleton (`province`, `claimedByTown`, `region`, basic `accessConditions`) is cheap and worth building early — it's what makes "wilderness belongs to something" concretely true. The `controlledBy` and `resourceYield` layers are long-term, since they depend on the broader clan-control system (2.6) and shouldn't block anything near-term.

### 2.4 Streets

Streets are modeled on real-world street addressing: they exist primarily to give players and NPCs a navigable address and wayfinding system, **not** to own a region or to gate access. A Street can physically run through multiple Districts, Towns, Provinces, or even Kingdoms — it has no required parent region. (This is a deliberate departure from the legacy v1 model, where a Street belonged to exactly one Town.)

### 2.5 Structure types — decided architecture

Legacy split Structure subtypes inconsistently (partly a byproduct of the original developer's early experience with inheritance/interfaces). **Decided for v3:** a single `Structure` base class with one concrete subclass per functional type (Gate, Warehouse, Shop, House, Keep, Tavern, Resource-Property, Non-functional, …), using the same joined-table inheritance pattern already proven in the Dominion hierarchy (Town/District/Structure/Gate/Warehouse). Cross-cutting capabilities that don't fit the type hierarchy cleanly (e.g. "can be produced from," "can be owned") are interfaces layered on top, not additional inheritance depth — inheritance for type identity, interfaces/composition for behavior.

### 2.6 Ownership (`controlledBy`) [Long-term] [OPEN]

Kingdom/Province/Town/District are all meant to eventually carry a `controlledBy`/owner field — a new concept for v3, not present in either legacy codebase. Ownership derives from either a clan (NPC- or player-owned) or an individual, and ties closely into the clan-conquest system (Section 3). Needs further refinement beyond name, chat color, banner, and relations — parked as an open item, not a blocker for the rest of this document.

### 2.7 Game world settings

A global, admin-configurable game-world settings system — join/spawn location, weather settings, time settings, and similar server-wide rules — was already a confirmed work-in-progress direction, not fully built. Worth finishing for v3: it replaces ad hoc defaults like v2's current "teleport new players to whatever town happens to be first in an unordered list" with deliberate, configurable global rules instead.

---

## 3. Clan Conquest & Seasons [Long-term, with MVP-relevant subset]

### 3.1 Clan creation

A clan exists only if it holds control of at least one clanhouse/stronghold. Starting a clan is gated by both the clanhouse's cost **and** player level/stats — not cost alone.

### 3.2 Minimal Clan & default team identity [MVP]

Building the full long-term `controlledBy` ownership model (2.6) isn't required to get Siege working — a lightweight `Clan` entity covers everything the MVP needs, and doubles as the default siege team template:

- `id`, `name`
- `isNpc` (bool) — true for a baseline "crown/garrison" clan every Town starts with by default; false for real player clans
- `chatColorPrefix` — a Minecraft chat color applied as the clan's name prefix
- `banner` — mirrors Minecraft's real banner data structure directly (so it serializes straight to an in-game item): `baseColor` (DyeColor) + an ordered list of `{patternType, color}` pairs, matching vanilla's `BannerMeta`/`Pattern` API — full multi-layer pattern support, not a simplified stand-in
- `defaultForTown` (optional) — marks this clan as a specific Town's baseline/NPC-controlled clan

On the Structure side, only the minimum needed for Siege itself: each **clancastle** gets a `controlledBy: Clan` (nullable — falls back to its Town's `defaultForTown` NPC clan when no player clan has taken it yet). No Kingdom/Province/District-level ownership propagation is needed for MVP; that's long-term scope (2.6), out of bounds for a 1–2 kingdom beta.

Payoff: when a Scenario is configured for a Town's siege, the defending team's name/color/banner auto-populate from whichever clan currently controls that Town — this *is* the "default team per town" mechanic (see 7.3), built from the same minimal model rather than a separate system, and it also seeds some early world lore for free.

### 3.3 Territory and clancastles

Kingdom/Province/Town/District are all just regions; there is no ungoverned space (see Territory in Section 2.3 — the same ownership principle applies here at the conquest layer). The number of clancastles in a Town/District scales with that Town/District's size. Each clancastle can be captured from another clan or from NPCs via a small siege. A future possibility (not MVP): under the right conditions and resources, a clan could attempt to conquer an entire Town/District (multiple clancastles) in one large siege.

### 3.4 Attack cadence [MVP-relevant for Siege itself]

Attacks happen on a scheduled cadence (fixed day/time), so both attacking and defending sides get fair warning. This cadence structure is also what unlocks pre-siege mechanics: intelligence-gathering missions, sabotage missions, and strategy planning.

### 3.5 Season end and reset [OPEN]

A season ends when one clan controls every clancastle in the game world. Unresolved:
- What happens if a season runs unexpectedly long, or a tie/stalemate develops between clans?
- What resets vs. persists for clans and players between seasons?
- Candidate idea (not yet fleshed out): an F1-style pole/starting-position advantage for the next season based on the previous season's performance, plus individual player rewards based on individual contribution.

### 3.6 Small-clan viability and diplomacy

Multiple mechanics are intended to let smaller/newer clans remain relevant without being able to out-fight a dominant clan directly:
- Resource production, trade, and knowledge disruption/promotion missions, gated by player profession and skill level.
- A full inter-clan diplomacy system — alliances, enemy standing, merges — drawing heavy inspiration from *Civilization V*'s politics/international relations mechanics.
- By design, a clan that's simply too large for others to challenge should push smaller clans toward alliance or merger rather than direct confrontation.
- Explicit design intent: joining the conquest late in a season is not meant to be a winnable strategy for a small clan.

---

## 4. Economy & Professions

### 4.1 The scalability problem [OPEN — unsolved, high priority to think through]

The game world will always have a finite number of Kingdoms/Provinces/Towns/Districts/Structures, while the player base is expected to keep growing — this is especially acute for ownable houses, shops, and resource-production structures, and worse still for high-demand/"A-location" structures. Constraints on any solution: (a) actual players should be able to walk through and inhabit their homes in the shared world — not just own a database row, and (b) the solution must not compromise the stated goal of keeping the codebase portable to a future non-Minecraft engine (Unreal or custom).

Candidate directions (not mutually exclusive):
1. **Instance-per-tier housing.** A small number of house templates per district/tier; multiple owners each get an instanced, walkable copy of the interior (shared-world exterior/storefront, instanced interior) — similar to WoW-style garrisons. Solves supply for common housing while keeping homes walkable.
2. **Decouple storefront from production capacity for shops.** The physical shop *storefront* stays a single, scarce, siege-contestable asset in the shared world; the *production/stock capacity* becomes a separate, queueable ownable resource (EVE Online-style), which also cleanly resolves the stock/upgrade-level ownership conflict.
3. **Scarcity as a deliberate feature for the top tier only.** Apply full instancing to common-tier housing (needs to scale), but keep the highest-tier/citadel-core properties genuinely scarce and siege-contestable — turning them into an intentional prestige/conquest goal rather than a bottleneck, and tying naturally into the district wealth-tier concept (Section 2.2).

All three are engine-agnostic (world-management patterns, not Minecraft-specific), so none compromise the future engine-portability goal.

### 4.2 Professions [OPEN — list not final]

Currently: trader/banker, general, spy/thief, engineer, plus room for one more. Not a hard ceiling — open to additional professions later. The Engineer profession specifically gates construction of siege vehicles (catapult, ram, siege tower).

### 4.3 Town economy simulation [Long-term]

Town economies are intended to run semi-autonomously, distinguishing between **circumstances** (background events players cannot influence) and **events** (player-caused, players can influence). A technology tree unlocks automatically from population activity over time, sped up by universities/libraries, and can regress if no library exists to sustain it.

### 4.4 Economic balancing

Real medieval market data as a basis for item/resource values is a nice-to-have, not a requirement — **game balance takes priority over realism**.

### 4.5 Structure ownership model [OPEN]

Whether structures (particularly shops/resource-production) are single-owner or multi-owner is still undecided — directly related to the scalability problem in 4.1.

---

## 5. Player Progression & Social Status

### 5.1 Rank & permission architecture [decided]

Drop the external permissions-plugin dependency (PermissionsEx, in the legacy versions) for rank/tier concerns. Rank/Tier becomes a first-class, KnK-owned concept living directly on `User` — queryable, admin-configurable, with expiry support for temporary tiers — rather than delegated to an external plugin's group membership. This is foundational: item purchase gating, premium kits, district access-gating, and the premium-tier direction below all depend on rank being real, first-class data.

**Rationale:** minimizing dependence on external, Minecraft/Bukkit-ecosystem-specific plugins is a deliberate architectural principle here, not a one-off preference — it preserves freedom to fully customize behavior in-house, and matters specifically because a future migration off Minecraft entirely (e.g. to Unreal Engine or a custom engine) is a live possibility. Every system built as a thin wrapper around a Bukkit-ecosystem plugin is exactly the kind of thing that migration would have to rebuild from scratch; owning core systems like rank/permissions directly keeps that door open.

**Feature bar to match:** despite dropping the *dependency*, the in-house system should match PermissionsEx/LuckPerms-style tooling feature-for-feature, not just replicate a minimal subset — it's mature, well-liked software worth using as the direct model:
- Named permission groups, each with its own chat prefix and suffix (display-name formatting).
- Per-group permission sets that support explicit **exclusions** (denies), not just grants.
- Group **inheritance hierarchy**, where a group can inherit another group's full permission set but still override specific permissions via its own exclusions.
- **One unified "permission holder" model, not a groups-only system**: premium ranks and staff roles are just two instances of the same underlying concept (a set of permissions + inclusions/exclusions + a chat prefix/suffix) — they aren't separate mechanisms. Individual players sit on top of that same model: a player can have explicit permission grants and exclusions of their own, layered on top of whatever their group(s) already give them.

### 5.2 XP and titles

Experience points and noble titles remain **the same progression axis** — titles *are* player levels, not a separate achievement-unlocked system. Once a player reaches the highest title, XP continues climbing as a pure "veteran" prestige signal, visible to other players independent of title.

Demotion via experience deduction is possible — triggered by confirmed rule-breaking, crime, or other misconduct (ties into Section 6) — reusing the promotion/demotion pipeline in reverse. **[OPEN]** Flagged design tension: deducting a player's earned XP directly feels punitive in a way that sits uneasily, even though demoting a *title* for misconduct feels right. A future redesign might decouple "title" from "raw XP total" so title can be demoted independently without touching the underlying experience number. Keeping them coupled for now; worth revisiting.

### 5.3 Premium tiers

Rename "donor" tiers to **premium** tiers. Deliberate direction change from the original 2017 design (which explicitly avoided pay-to-win): the current preference is for premium tiers to grant real power/progress advantages rather than being purely cosmetic. This should be called out explicitly in any external-facing material as an intentional decision, not an oversight.

### 5.4 Salary system

Kept. Hourly payout per hour played, scaled by global, personal, and rank-based multipliers — all admin-configurable via the web app, with more customization desired here than v1 had. Offline-gap handling: if a player leaves and at least one hour has passed by the time they next join, a payout covering that gap is made on that next join, rather than silently lost.

**Account linking (underpins 5.3 and 5.4):** both premium tiers and the salary system assume a working connection between a player's in-game account and their web-app account. This connection is not new work — it's already extensively specced and largely built (web-API side: data model, DTOs, service layer, controllers, and tests complete; plugin side: link-code generation, duplicate-account handling, cache sync implemented), on the `UserFeatures` branch, not yet merged. Source of truth: `docs/specs/users/` and `docs/specs/plugin-auth/` in knk-workspace, not restated here.

### 5.5 Owner-mode / staff-mode

Confirmed essential, required for core staff functions. Rebuild for v3 — v2 never rebuilt this despite its own TODOs flagging it as still wanted.

### 5.6 In-game rank & group management

v1's in-plugin commands for moving players between server groups/ranks should be improved and rebuilt for v3, not left to an external plugin — consistent with 5.1's decision to bring rank/tier fully in-house.

### 5.7 Dropped ideas

A "random birth advantage" mechanic (starting conditions randomized at character creation) has been dropped — too complex and ambiguous to implement well.

---

## 6. Law, Crime & Safety

- Jail and justice system: jail time, fines, and execution for crimes and offences — including non-physical offences like spamming or swearing in chat. The jail/justice system needs further refinement but the core loop (jail → fine → execution on repeat offence) is confirmed.
- Law-enforcement buildings (outposts/garrisons) are upgradable in range/effectiveness, and can be disabled by winning a siege against them.
- Bandit ambush and bandit-camp spawn probability scales with time of day, biome, and **distance from law-enforcement buildings specifically** (not just general distance from town).

---

## 7. Combat, Siege & Minigames

> **Status (2026-09-26):** the v3 siege minigame (7.1–7.4) is **code complete through its MVP phases** on the
> `claude/siege-minigame` branches, not yet merged or playtested end to end: authoring in the web app, the plugin's
> match loop with chat fallbacks, match history and server-side rewards, gate lockdown and the non-member gate view,
> and siege menus. The plugin code from match recording on hasn't been compiled yet. What's left is playtesting and
> balancing, then Phase 10 (scheduled lobbies, post-MVP). Spec and per-phase status:
> [`docs/specs/siege-minigame/IMPLEMENTATION_PLAN.md`](../specs/siege-minigame/IMPLEMENTATION_PLAN.md); admin how-to:
> [`docs/guides/authoring-a-siege-scenario.md`](../guides/authoring-a-siege-scenario.md).

### 7.1 Scenario vs. Siege [MVP]

- **Scenario** = the persisted, admin-configurable "map and mode": number of sides (default 2: attackers/defenders, but can be more — e.g. two rival attacking teams vs. one defender), teams, per-team spawnpoints, objectives, and which side holds which objective at the start.
- **Siege** = the live match instance running on top of a chosen Scenario.

*Status: built as specified (N teams in alliance groups, readiness checks, weighted lobby rotation).*

### 7.2 Objectives [MVP]

Classic 2-team layout: the town hall (or equivalent) is the main objective and determines the winner when captured; town gates and other strategic points are side objectives, destroyed once captured. Held objectives double as spawnpoints for the team holding them — **already implemented** in the legacy v2 codebase (confirmed: the respawn menu merges a team's held objectives with its dedicated spawnpoints) and should be carried forward as-is.

Recommendation: adopt v2's generalization of "any objective can be flagged as game-ending" (an `instantVictory` flag per objective) rather than v1's hardcoded "only the Main Objective ends the match" — it's a strictly better version of the same mechanic.

*Status: built: per-objective `InstantVictory`, spawn-when-held, gate objectives; capture constants tuned from a first
playtest (DESIGN §7.2).*

### 7.3 Team identity [MVP]

Each Town has a default team identity for sieges, sourced directly from the minimal Clan model in 3.2: name, chat-color prefix, and a full multi-layer Minecraft banner (base color + ordered pattern list). This doubles as light world lore — a Town's identity persists even before any player clan has taken it. Not present in either legacy version; new work for v3.

**Scenario configuration flow — admin choice, not auto-populated.** When configuring a Scenario, the admin first selects the Town/Province/District the scenario takes place in. Once that's chosen, the subsequent team-configuration step offers the default Clan teams associated with that selected region as options — but the admin isn't required to use them. The admin may instead create an **ad-hoc, scenario-specific team** (name/color/banner defined fresh for that Scenario only). Ad-hoc teams are **not persisted** the way default Town/Clan teams are — they exist only as part of that one Scenario's configuration, not as reusable Clan records. So the data model needs two distinct team sources feeding the same Scenario-team-selection step: persisted default Clan teams (looked up by region) and one-off non-persisted Scenario-only teams — the admin picks per-team, per-scenario, which source to use.

Default ally/enemy standing between clans is a further, longer-term layer on top of this (ties to the diplomacy system in 3.6) — the name/color/banner template and the admin's default-vs-ad-hoc choice are the MVP-scope pieces.

*Status: built: `BannerDesign` + `Clan` (default clan per town) and ad-hoc scenario teams. Ally/enemy standing
between clans is not built (long-term).*

### 7.4 Build approach [MVP-relevant]

Architecturally, v2's Siege system is the more sophisticated of the two legacy versions (proper data model, N-team/alliance scaffolding, richer objective flags) but was never a finished, correctly-functioning minigame — its core scoring and win-resolution logic is hardcoded to one specific team name and would misbehave for any other matchup, and there's no working in-game flow to create new Scenarios/Objectives/Teams from scratch. v1's simpler system, by contrast, is a genuinely complete, self-sustaining, correctly-scoring minigame. **Direction for v3: rebuild v1's actually-working functionality on top of v2's more robust architecture**, rather than treating either version as sufficient on its own.

*Status: followed: v1's loop and scoring were rebuilt on the v3 stack (web-api owns data and rewards, the plugin
runs matches).*

### 7.5 Other combat systems [Long-term]

- Clan-warfare siege vehicles, gated behind the Engineer profession (Section 4.1).
- Separate PvP arena with randomized (not full-inventory) death drops.
- Premium-gated minigames: Hide and Seek, Defend the Castle.
- Dungeons (at least one confirmed concept location: under Keep Cinix).

---

## 8. Narrative & Quests [Deprioritized]

Storyline and narrative content is explicitly deprioritized — bottom of the feature priority list, addressed only after the higher-priority systems above are in place. When it is picked up:
- Per-town questlines, gated by profession level and title.
- Instanced quest scenarios (a snapshotted copy of a world location, so e.g. a mine collapse quest doesn't affect the shared world).
- Stated inspirations: GTA Online, RDR2.

Stated overall build order (unchanged): **bandit camps + dungeons + city guards → storyline → professions → clans → staffs.**

---

## 9. Equipment & Magic

### 9.1 Items

- Keep v2's `Item`/`Grade`/`Category`/`Origin` model as the foundation, split into two cooperating entity types (following the same joined-table inheritance pattern already decided for Structures, 2.5):
  - **`ItemTemplate`** — the catalog definition: name, category, grade, itemtype, origin, `basePriceMin`/`basePriceMax`, purchase-currency properties (coins/gems/both — premium-currency items live here as a property of the template, not a separate class), base drop amount, default loot/lore config. Relatively small row count.
  - **`ItemInstance`** — the live, owned copy spawned from a template: FK to its template, plus everything mutable per-copy (current enchantments, custom enchantments, soulbound/ghosted flags, `createdAt`, `ownerCount`). Expected to scale into the **millions**, not just tens of thousands — `createdAt`/`ownerCount` directly feed the item-age/owner-count passive bonus below.
  - **Persistence at that scale [OPEN, future]:** a relational MySQL store is fine to keep building on for now, but millions of mutable instance rows may eventually outgrow it. Not a near-term blocker — revisit the persistence strategy (sharding, a different datastore, or a hybrid approach) once real instance counts make it a concrete problem, not before.
  - Physical linkage uses the item's Bukkit `PersistentDataContainer` to store the `ItemInstance` id — the source of truth the plugin reads — while lore is regenerated display output (soulbound, ghosted, grade stars, origin, enchantments all rendered into lore for player visibility, same as today, just no longer scanned back out of lore as the source of truth).
  - Enchantments/custom enchantments are a normalized child table (`instance_id, enchantment_type, level`), not a JSON blob — keeps future marketplace filtering (e.g. "Sharpness III+") a plain indexed query.
  - **Template → instance field cascading [decided]:** template edits never auto-propagate to live instances. Editing a template field is just a template save. A separate, explicit "cascade to live instances" admin action exists per cosmetic/descriptive field (display name, description, lore boilerplate), which previews the affected count before confirming (e.g. "12,384 instances would update"). Crucially, each instance tracks a per-field override flag that flips on the moment a player personally customizes that field (e.g. renames their own item) — a cascade **always skips** instances with that field's override flag set, so bulk admin fixes (typo corrections, etc.) can never clobber a player's own customization. Mechanical state (grade, enchantments) is never cascaded — it's frozen onto the instance at spawn time regardless.
- **Personal item stash — monetization angle:** the delivery-fallback stash (below) doubles as a premium-tier hook — selling additional stash capacity/slots is a viable revenue lever, worth folding into the Section 5.2 premium-tier direction rather than treating the stash as purely a technical fallback.
- **Soulbound / Ghosted / Limited-time items**: resurrected for v3 (not dropped from v2 — see legacy-comparison note above), tracked as real instance-level state rather than v1's lore-string scanning.
- **Custom enchantments**: native to the v3 plugin (previously a separate plugin), still rendered in lore for consistency with vanilla enchantment display.
- **Loot boxes**: kept, grade-weighted, but the probability calculation should become more complex than v1's flat per-grade table — factoring in enchantments and soulbound/ghosted status as well as grade. Exact formula **[OPEN]** — deliberately deferred to dedicated loot/economy balancing work, not needed now.
- **Price range + sellability**: kept (`basePriceMin`/`basePriceMax` on `ItemTemplate`), feeding the supply-and-demand economy direction (Section 4).
- **Crafting restriction**: shelved as nice-to-have/low-priority — not dropped, just not a near-term focus.
- **Item purchase gating** (title/rank requirements to buy an item): intentionally deferred — couples tightly to merging v2's Resource-Property/Commodity/production-transport-order system with v1's Shops, which is its own Economy-section (Section 4) design pass rather than something to scope in isolation here.
- **Delivery fallback**: v2's stash approach (over v1's buggy ender-chest fallback) is preferred, but needs its "never actually drained" bug fixed, and should be manageable from the web app — consistent with the web app's role as a central hub for admins and players.

### 9.2 Kits

Build the full kit system on top of v2's more mature model (persisted `Kit` entity with a full equipment loadout + bonus contents list), not v1's hardcoded single starter-kit method. Key decisions:

- **Fix the cascade-delete bug first.** `Kit.contents`' `CascadeType.ALL` relationship to `Item`/`ItemTemplate` must not cascade deletes — deleting a Kit should never risk deleting Item rows still referenced elsewhere (shops, storages, other kits). This is also a standing rule going forward for **any** entity referencing shared Item/ItemTemplate rows in v3, not just Kit.
- **Unify "starter kit" into the general Kit system**, rather than keeping it a separate hardcoded first-join behavior. Every Kit gets admin-configurable: entry conditions (level/rank/title/etc., same gating model used elsewhere), a cooldown between re-claims, and an optional cost. A "first-time join kit" is just a Kit configured with a `grantOnFirstJoin` flag — not a separate code path.
- **Permission parity between command and menu grant paths** — both must enforce the exact same permission/condition/cooldown checks, with clear, user-friendly denial messaging in both surfaces (chat for commands, in-menu for the UI) when a claim is blocked.
- **Premium kits stay in scope**, in two forms: kits exclusively available to premium ranks (still subject to their own configured cooldown/cost/conditions), and single-purchase premium kits bought with real money (one-time, separate from the cooldown-based general-availability model).
- **Cooldown + claim tracking**: real, implemented — per-user last-claimed timestamp (for cooldown enforcement) and claim history (to enforce single-purchase premium kits). No longer freely repeatable with no tracking, as in both legacy versions.

### 9.3 Combat & progression items

- Weapon/armor star-grades cap available enchantment tiers.
- Enchant unlocks progress via a bookshelf skill-tree, gated behind a "read and write" quest.
- **Item age and total owner count grant passive stat bonuses** (attack%/defense%/speed%) — deliberately designed to discourage players from flipping/reselling items and to reward long-term ownership.
- Late-game elemental staffs (fire/ice/wind): one element per player, each with its own upgradable skill tree.
- Religions and shrines: faction-based buffs, with AFK-farming explicitly discouraged via debuffs.
- Pets: collectible, 3 free slots, additional slots via premium tiers.

---

## 10. Inventory & Menu Framework (Player UI)

The clickable inventory-menu system is the primary in-game UI surface for players — how they reach houses, properties, skills, social features, the gem-shop, and (via legacy precedent) most other player-facing systems that aren't a dedicated screen of their own. It is also a hard prerequisite for the Items and Siege-minigame MVP work, since both rely on it for their player-facing UI.

- **Status**: no v3 code exists yet — confirmed directly against `knk-plugin`'s `InventoryMenus` branch (still a single, unmerged planning commit). **The v1/v2 legacy menu system is still what's live.** What has changed since the last pass: the engine *architecture* is now decided, reconciled against the full legacy bug-mining findings, and actively being refined pre-implementation (see `docs/specs/inventory-menu/` and the reconciliation/design-review docs alongside it).
- **Engine decision**: v3 adopts the flexbox-style composite architecture originally built (but never wired to the live game) as v2's orphaned `menu/`+`command/menu/` tree — Menu → MenuSection → MenuItem composition, a definition/rendered-instance split, an explicit `MenuSession`, and align/position/growth/overflow/priority-driven layout. This directly mirrors the `ItemTemplate`/`ItemInstance` split already decided in §9.1 — the same architectural principle applied consistently. Neither v1's god-class nor v2's live `model/menu`/`Menu2`/`ContentGroup` tree carries forward as architecture; both are content sources to port, not engines to keep.
- **Reconciliation against known bugs**: the two structurally serious legacy bugs — v2's async off-thread `Inventory` mutation and the broken `%...%` variable-substitution regex — are fixed by this architecture's design (async rendering pattern; a properly escaped resolver). Three real design gaps were identified and are being closed before implementation: session cleanup on player quit (the new equivalent of v1's unbounded static-map growth bug), pagination/overflow living on the base class rather than being subclass-only (the same failure shape as v2's no-op `Menu.nextPage` stub), and permission-gating as a first-class item/section property (v2 had an accidentally-unguarded debug item for exactly this reason).
- **New capabilities being designed in** (not present in either legacy system or the original January draft): search, conditional menu-button actions (condition checked at click time, not just render time — closes a staleness window the old lore-color-based affordability checks were vulnerable to), structured content filters, and first-class permissions (visibility vs. action-execution as separate checks).
- **Templates are database-persisted, not hardcoded — authoring UI is a separate, later decision.** `Menu`/`MenuSection`/`MenuItem` exist as real backend entities from day one (no Java-constructed templates), loaded by the plugin through the existing data-access/cache layer. Authoring them via the `FormWizard`/`FormConfigBuilder` system (the same pattern `GateStructure` uses) is deferred to a future update rather than a day-one requirement — day one, templates are created directly (seed data / direct API), not through a generated admin form. See `docs/specs/inventory-menu/FORMCONFIG_INTEGRATION.md` for the full analysis, kept as forward-looking design for when that update happens.
- **Known remaining gap either way**: v1-era feature parity (houses, properties, titles, social, gem-shop, and other screens reachable from v1's Personal Menu) plus the two currently-live v2 screens (Kit and Siege overviews) are not yet ported to any v3 framework, and porting them is separate, not-yet-planned scope from the engine work above.
- An implementation plan (entities, phased build order) follows the same pattern as the Items plan (§9.1), once the design-review pass currently underway is settled.

---

## Appendix: Open Questions

Consolidated list of items flagged `[OPEN]` above, for future refinement:

1. **Season-end conditions** — tie/stalemate handling, what's "too long," and what resets vs. persists for clans/players between seasons (Section 3.4).
2. **The scalability problem** for finite ownable structures vs. a growing player base — three candidate directions proposed, none yet chosen (Section 4.1).
3. **Full profession list** beyond the current 4–5 (Section 4.2).
4. **Structure ownership model** — single-owner vs. multi-owner, tied to #2 (Section 4.5).
5. **Long-term ownership (`controlledBy`) refinement** for Kingdom/Province/Town/District — how it derives from clans vs. individuals, and how territory `controlledBy`/resource yield (2.3) integrates. The MVP-scope baseline (a minimal `Clan` model driving Town default team identity and clancastle control) is now defined in Section 3.2 and is not blocked by this.
6. **Loot-box probability formula** — should factor in grade, enchantments, and soulbound/ghosted status; exact calculation deliberately deferred to dedicated loot/economy balancing work (Section 9.1).
7. **`ItemInstance` persistence at scale** — millions of instances may eventually outgrow a relational MySQL store; not a near-term blocker, revisit once real numbers make it concrete (Section 9.1).
8. **Title/XP coupling for demotion** — deducting a player's earned XP to demote their title feels punitive in a way that sits uneasily; a future redesign may want to decouple title from raw XP total so title can be demoted independently. Kept coupled for now (Section 5.2).
