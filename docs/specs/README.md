# KNK Requirements & Specs Hub

Central home for requirements, specifications, and implementation roadmaps across KNK services (web API, web app, and Minecraft plugin). Keep new cross-cutting docs here so they are discoverable by all teams and AI assistants.

## Structure
- arena-duels/: player-vs-player arena duels — invite with stake offers, escrow, lobby warmup, spectator menu, battleground PvP (Linear KNG-197; draft design 2026-10-20, not implemented)
- npc-platform/: shared NPC traits, behavior and tutorial guide; agreed requirements and open investigations (KNG-36)
- project-overview/: portfolio-level summaries and source pointers (CHANGES, implementation roadmap, source map)
- users/: user/account management specs and requirements (including linking, merge, password rules)
- towns/: towns/world feature specs and hybrid create/edit flow notes
- api/: API contract snapshots and backlog for REST endpoints
- items/: item catalog (`ItemBlueprint`) design/implementation
- kits/: Kit (equipment loadout) design, implementation plan, and legacy-DB seed data
- enchantment-books/: permanent enchantment books outside siege (Linear KNG-5)
- game-settings/: global Game Settings - announcements, join spawn, respawn policy, per-world game mode/time/weather/spawn, applied by the plugin (Linear KNG-52)
- navigation/: road network (survey-learned road profiles, auto-detected junctions on every level) and `/navigate` guidance with live gate/entry availability (Linear KNG-27)
- production-storage-transport/: the resource-economy backbone: storages (domain/player/clan), production kinds with yield areas, transport orders (simulated, then NPC/courier), town logistics (V2 port, design draft rev. 2, 2026-10-09)
- siege-survival/: cooperative endless NPC-wave defense, gate repair, spawnzone progression and match equipment/economy (Linear KNG-50, child of KNG-37; design only)
- user-features/: rank/permission/title/salary architecture
- user-management/: tailored admin module built on top of user-features
- player-statistics/: KNG-34 player statistics, leaderboards, owner-only diagnostics and world analytics — finalized design + implementation plan (implemented by the chain on `claude/kind-dijkstra-y9d279`, all links done 2026-10-03, not merged)
- legacy/: legacy reference notes kept for historical context
- reconcile/: reconciliation guides for aligning legacy data with v2

## Key documents
- Arena duels (KNG-197; draft design + plan rev. 2 2026-10-20, developer answers folded in, not implemented): [arena-duels/DESIGN.md](arena-duels/DESIGN.md), [arena-duels/IMPLEMENTATION_PLAN.md](arena-duels/IMPLEMENTATION_PLAN.md)

- Dev environment (KNG-163, proposal 2026-10-12): [dev-environment/DEV_DB_REMOTE_ACCESS.md](dev-environment/DEV_DB_REMOTE_ACCESS.md) — NAS dev database for cloud sessions over Cloudflare Tunnel + Access, scheduled backups, versioned DB environments and the deploy pipeline. Decisions E1-E4 made 2026-10-12.

- Form wizard (2026-10-11, analysis + proposed design, not implemented): [form-configurations/FORM_WIZARD_SESSION_CONCEPTS.md](form-configurations/FORM_WIZARD_SESSION_CONCEPTS.md) (List "Create New" children never saved, pickers showing entities made in this form session, Edit instance seeding; KNG-133..136, KNG-162) and [form-configurations/DEFAULT_FORM_SEEDS.md](form-configurations/DEFAULT_FORM_SEEDS.md) (FormConfiguration export/import, agent-authored default forms and their authoring guide; KNG-137..139). Decided 2026-10-11 (D1 = A, S1 = A); D2 default in KNG-162. Implemented by the [form wizard chain](../ai-agents/handoffs/FORM_WIZARD_CHAIN.md).

- Player statistics (KNG-34; design finalized 2026-10-03, implemented by chain links 2-7 on `claude/kind-dijkstra-y9d279`, done 2026-10-03, not merged): [player-statistics/DESIGN.md](player-statistics/DESIGN.md) (binding §F "Finalized design"), [player-statistics/IMPLEMENTATION_PLAN.md](player-statistics/IMPLEMENTATION_PLAN.md); evidence [../reports/2026-10-03-player-statistics-source-audit.md](../reports/2026-10-03-player-statistics-source-audit.md). Reconciles KNG-14 (counters) and KNG-23 (provenance = existing ledger).

- Game Settings (KNG-52; merged and live-tested 2026-10-10): [game-settings/DESIGN.md](game-settings/DESIGN.md), [game-settings/IMPLEMENTATION_PLAN.md](game-settings/IMPLEMENTATION_PLAN.md); admin how-to [../guides/game-settings.md](../guides/game-settings.md)
- Shared NPC platform (KNG-36, working design; not implemented): [npc-platform/DESIGN.md](npc-platform/DESIGN.md). Tutorial lifecycle, movement profile, access and gate pass-through investigations.
- Production, storage, transport and distribution (draft rev. 2 2026-10-09, not implemented; Linear KNG-83): [production-storage-transport/DESIGN.md](production-storage-transport/DESIGN.md), [PRODUCTION_KINDS.md](production-storage-transport/PRODUCTION_KINDS.md), [TOWN_LOGISTICS.md](production-storage-transport/TOWN_LOGISTICS.md), [IMPLEMENTATION_PLAN.md](production-storage-transport/IMPLEMENTATION_PLAN.md); evidence in [../reports/2026-10-09-v2-production-storage-transport-scan.md](../reports/2026-10-09-v2-production-storage-transport-scan.md).
- Siege survival / Defend the Castle (KNG-50, design recorded 2026-09-30; not implemented): [siege-survival/DESIGN.md](siege-survival/DESIGN.md), [siege-survival/IMPLEMENTATION_PLAN.md](siege-survival/IMPLEMENTATION_PLAN.md). Both inventory variants and Mystery Box are first-release scope; permanent reward amounts await progression targets.
- User domain: [docs/specs/users/SPEC_USER.md](docs/specs/users/SPEC_USER.md), [docs/specs/users/SPEC_USER_ACCOUNT_MANAGEMENT.md](docs/specs/users/SPEC_USER_ACCOUNT_MANAGEMENT.md), [docs/specs/users/REQUIREMENTS_USER.md](docs/specs/users/REQUIREMENTS_USER.md), [docs/specs/users/USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md](docs/specs/users/USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md), [docs/specs/users/USER_ACCOUNT_MANAGEMENT_QUICK_REFERENCE.md](docs/specs/users/USER_ACCOUNT_MANAGEMENT_QUICK_REFERENCE.md)
- Towns domain: [docs/specs/towns/SPEC_TOWNS.md](docs/specs/towns/SPEC_TOWNS.md), [docs/specs/towns/CREATE_FLOW_SPLIT_TOWNS.md](docs/specs/towns/CREATE_FLOW_SPLIT_TOWNS.md), [docs/specs/towns/LOGIC_CANDIDATES_TOWNS.md](docs/specs/towns/LOGIC_CANDIDATES_TOWNS.md), [docs/specs/towns/REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md](docs/specs/towns/REQUIREMENTS_HYBRID_CREATE_EDIT_FLOW.md)
- Portfolio overview: [docs/specs/project-overview/IMPLEMENTATION_ROADMAP.md](docs/specs/project-overview/IMPLEMENTATION_ROADMAP.md), [docs/specs/project-overview/CHANGES_SUMMARY.md](docs/specs/project-overview/CHANGES_SUMMARY.md), [docs/specs/project-overview/SOURCES_LOCATION.md](docs/specs/project-overview/SOURCES_LOCATION.md)
- API contract snapshots: [docs/specs/api/README.md](docs/specs/api/README.md) (includes swagger export and contract notes)
- Items domain: [docs/specs/items/IMPLEMENTATION_PLAN.md](docs/specs/items/IMPLEMENTATION_PLAN.md)
- Item grades (10-tier scale, DropChance, enchant-book level cap; KNG-6): [items/GRADE_DROPCHANCE.md](items/GRADE_DROPCHANCE.md)
- Enchantment books (KNG-5): [enchantment-books/ENCHANTMENT_BOOK_APPLICATION.md](enchantment-books/ENCHANTMENT_BOOK_APPLICATION.md)
- Road navigation (KNG-27, decided design rev. 4, built in parallel with siege): [navigation/DESIGN.md](navigation/DESIGN.md), [navigation/IMPLEMENTATION_PLAN.md](navigation/IMPLEMENTATION_PLAN.md) (agent handoff), [navigation/REV6_PROPOSAL.md](navigation/REV6_PROPOSAL.md) (rev. 6, accepted in principle: curated tiles first — plan §5.7 — then open areas first), [navigation/REV7_PROPOSAL.md](navigation/REV7_PROPOSAL.md) (rev. 7, proposed 2026-10-09: routing view cut at gates and access borders, entrances for structures, which access rules apply to roads); research in [../reports/2026-09-27-road-navigation-research.md](../reports/2026-09-27-road-navigation-research.md) and [../reports/2026-09-27-open-world-navigation-research.md](../reports/2026-09-27-open-world-navigation-research.md) (how Rockstar/Ubisoft do it)
- Kits domain: [docs/specs/kits/DESIGN.md](docs/specs/kits/DESIGN.md), [docs/specs/kits/IMPLEMENTATION_PLAN.md](docs/specs/kits/IMPLEMENTATION_PLAN.md), [docs/specs/kits/SEED_DATA.md](docs/specs/kits/SEED_DATA.md)
- User features (rank/permissions/title/salary): [docs/specs/user-features/DESIGN.md](docs/specs/user-features/DESIGN.md), [docs/specs/user-features/IMPLEMENTATION_PLAN.md](docs/specs/user-features/IMPLEMENTATION_PLAN.md)
- User management (admin module): [docs/specs/user-management/DESIGN.md](docs/specs/user-management/DESIGN.md), [docs/specs/user-management/IMPLEMENTATION_PLAN.md](docs/specs/user-management/IMPLEMENTATION_PLAN.md)
- Reconciliation: [docs/specs/reconcile/README.md](docs/specs/reconcile/README.md)
- Legacy reference: [docs/specs/legacy/README.md](docs/specs/legacy/README.md)
- Siege minigame (MVP driver, vision §7): [siege-minigame/DESIGN.md](siege-minigame/DESIGN.md),
  [siege-minigame/IMPLEMENTATION_PLAN.md](siege-minigame/IMPLEMENTATION_PLAN.md),
  [siege-minigame/MENU_TEMPLATES.md](siege-minigame/MENU_TEMPLATES.md) (legacy siege menus inventoried
  item-by-item + proposed v3 templates, built in Phase 8b); evidence in
  [../reports/2026-09-25-siege-minigame-gap-analysis.md](../reports/2026-09-25-siege-minigame-gap-analysis.md).
  **Status (2026-09-26):** MVP phases 1–9 done, smoke-tested live and merged into the default branches; Phase 10
  (scheduled lobbies) post-MVP. Admin how-to:
  [../guides/authoring-a-siege-scenario.md](../guides/authoring-a-siege-scenario.md)
- Command catalogs (every Minecraft command across all three codebases — syntax, permissions,
  behavior, feature allocation): [docs/specs/legacy/commands-v1.md](docs/specs/legacy/commands-v1.md),
  [docs/specs/legacy/commands-v2.md](docs/specs/legacy/commands-v2.md),
  [docs/specs/user-features/COMMAND_CATALOG_V3.md](docs/specs/user-features/COMMAND_CATALOG_V3.md)
- Event-listener catalogs (every Bukkit/Spigot event handler across all three codebases — the
  passive/reactive behavior commands don't cover): [docs/specs/legacy/events-v1.md](docs/specs/legacy/events-v1.md),
  [docs/specs/legacy/events-v2.md](docs/specs/legacy/events-v2.md),
  [docs/specs/user-features/EVENT_CATALOG_V3.md](docs/specs/user-features/EVENT_CATALOG_V3.md)

## Conventions
- Keep feature requirements and roadmaps grouped by domain folder above.
- When adding a new feature, create a subfolder under docs/specs that matches the domain and add a short entry in this README.
- Cross-link related docs (API contracts, UI flows, in-game flows) so teams can navigate quickly.
- Leave module-local implementation notes near the code, but keep cross-cutting requirements here.
