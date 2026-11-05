# Production, storage and transport rev. 3 — docs session prompt

**Created:** 2026-11-05. Paste the block below into a new Claude Code session (cloud) as its first message.
Documentation only; no code.

```text
You are updating the Knights and Kings design documents for the production, storage, transport, warehouse and shop feature (parent issue [KNG-83], now a GitHub issue in PandiO/knk-workspace). This is a documentation-only task in PandiO/knk-workspace. Do not touch the code repos.

REPOSITORY PERMISSION (explicit authorization from the developer, Pandi):
You may attach and clone PandiO/knk-workspace (push) without asking again. Read-only: PandiO/knk-plugin, PandiO/knk-web-api, PandiO/knk-web-app, PandiO/knk-v1-archive (only if you need to check an existing class or menu name). Attach with add_repo, clone, then call register_repo_root.

START:
1. Clone knk-workspace. Read AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md and docs/ACTIVE_SESSIONS.md. Add an "In progress" row for this task (feature: "Production/storage/transport design rev. 3", docs only). Check for overlap: the NPC behavior model work (#234, PR #235, branch claude/npc-behavior-model) also edits docs/specs/npc-platform/DESIGN.md — do not edit the same sections; add your NPC lifecycle text as its own section and flag any overlap in your report.
2. Read the authoritative input: docs/specs/production-storage-transport/DECISIONS_2026-11-05.md (developer-approved decisions from a voice design review). Then read DESIGN.md, PRODUCTION_KINDS.md, TOWN_LOGISTICS.md and IMPLEMENTATION_PLAN.md in the same folder (rev. 2, 2026-10-09).

DO:
A. Revise the four documents to rev. 3 so they match the decision record. Keep each file's header format (title, status, last updated, revision history) and add a "Rev. 3 (2026-11-05)" entry that links the decision record. Specifically:
   - DESIGN.md: principle clarifications (§2: harvest moves, partial moves, deliberate SYS_LOSS losses, in-game runtime management later); capacity model (§4.4: raw units, container slots × UnitsPerSlot, ItemBlueprint.StorageWeight default 1, drop StackSlots); inbox (§4.6: hard cap, premium raises it, overflow to SYS_LOSS, near-cap warnings, 30-day expiry); transport (§7: simulated only in V1, robbery off; producer workers carry orders; unconnected producer wording; NPC transporter design incl. virtual movement; town carrier pool for hire as Later); shops (§10); decisions table (§14) updated per the record's §9.
   - PRODUCTION_KINDS.md: replace the fixed multiplier list in §4.2 with the modifier pipeline (scope, target, effect, active window; trace per modifier); V1 sources = level + weather; custom weather with climate zones and daily stored rolls; level effects incl. upkeep field without effect; producer workers (default 2) and worker-availability scaling; harvesting worker's share and net-positive pool math (§6); Later list (painted fertility map, technologies, seasons, staffing, exhaustion, events, neighbour bonuses, upkeep, war disruption, per-player weather).
   - TOWN_LOGISTICS.md: reserve-and-collect distribution with consumer workers, no warehouse workers in V1; V1 rule subset vs Later rules; planner and governance confirmations; warehouse throughput as Later; player sales now through shops.
   - IMPLEMENTATION_PLAN.md: fold the record's §10 into the phases (P1, P3, P5, P6, P7, P8, P9), add new phases for Shops (static catalogue first, then restocking, processing, player selling — same update), Shopkeepers and Display stalls, and note that the garrison/guard NPC work ships in the same test phase. Mark every item V1 or Later. Update the smoke test outline.
B. Create docs/specs/shops/DESIGN.md (Draft) from the record's §6 and §7: shop kinds, storages, buying from players with accepted categories, StockUnit resale, interim pricing (base price × tax × level; 50% buy-back; static catalogue price wins), shop levels, shopkeeper NPC (human/villager, stored spawn, stays in place and looks at players by default, optional roam, greeting with cooldown, right-click menu with info header + paged catalogue), display stalls (registered spots, Paper item display entities, admin pins + system fill, right-click = item info menu, shift-right-click = quick buy, every purchase confirmed). Note that the developer will supply V1 inventory menu templates. Link it from DESIGN.md §10 and from docs/specs/README.md.
C. docs/specs/npc-platform/DESIGN.md: add an "NPC lifecycle and reliability" section from the record's §8 (non-persistent entities, spawn on demand/despawn when no players near, one live entity per NPC id via PDC tag + registry, orphan sweep on chunk load, correct after crash/restart), listing shopkeepers, producer/consumer workers and carriers as consumers alongside guards.
D. docs/FEATURE_REGISTER.md: update the two production/warehouse rows (design rev. 3, decisions recorded) and add a Shops row.
E. Create GitHub issues in PandiO/knk-workspace (check for existing ones first; follow the existing [KNG-n] / label conventions) for: the Shops, Shopkeepers and Display stalls phases; and one "Later" backlog issue each for NPC caravans (mark as the next follow-up), town carrier pool for hire, warehouse throughput, painted fertility map, technologies modifier, and in-game runtime management. Group the remaining Later modifiers into one issue. Link them from IMPLEMENTATION_PLAN.md. If you cannot create issues, list them in your report instead.
F. CHANGELOG.md entry. Move your ACTIVE_SESSIONS row to "Recently completed".

RULES:
- Do not change any decision; if the record conflicts with itself or with another spec, keep the record's wording, and list the conflict in your report.
- Plain, short sentences; follow the existing style of these docs.
- knk-workspace never gets feature branches for docs: commit to main in small, logical commits (one per document group), fetch and rebase before each push.

REPORT BACK: files changed with a one-line summary each, issues created (numbers), any conflicts or open questions for the developer.
```
