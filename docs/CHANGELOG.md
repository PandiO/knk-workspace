# Knights & Kings changelog

This is a human-readable record of capabilities merged into the V3 default branches. It is not a complete commit log or a promise that code has been deployed to a public server. See [the feature register](FEATURE_REGISTER.md) for design, branch and live-verification status. Entries before this changelog was established on **2026-09-28** are a selective backfill from merge records and feature plans; linked plans describe the precise live-test coverage.

## 2026-10-06

- PermissionGrant forms can now search for and pick a holder (a user or a permission group) in the web app: the web-app half of the PermissionHolder lookup is merged ([KNG-38](https://linear.app/kngpandi/issue/KNG-38), knk-web-app `main` `24b60ac`), completing the API half from 2026-10-04.

## 2026-10-05

- The lootbox opening reel's passing items now carry real enchantments ([KNG-54](https://linear.app/kngpandi/issue/KNG-54)), rolled from the box's own enchant rolls and shown with the grade the box gives them, so the winner is no longer the only enchanted item on the reel ([lootboxes design §3.9](specs/lootboxes/DESIGN.md)).
- Blueprint item descriptions without a colour of their own now render dark gray instead of vanilla purple lore (this fixes Flaming Samurai).
- Every route that spawns an item from a blueprint (lootbox delivery and reel, kits, `/knk itemblueprints give`) now builds it through one `BlueprintItemAssembler` entry point, and `/ce add` shares the custom-enchantment lore pipeline with `/ce remove`; see the [item render pipeline](architecture/item-render-pipeline.md). knk-plugin `main` `74607a9`.
- Fixed `/ce remove` leaving a stray blank line at the top of an item's lore after removing its last custom enchantment; removal now shares the same lore re-compose as applying one (knk-plugin `main` `e55e87f`).

## 2026-10-04

- Held a lootbox opening-reel item that comes up while the player is in a siege until their own inventory is restored, instead of losing it with the siege inventory ([KNG-44](https://linear.app/kngpandi/issue/KNG-44), [plan](specs/lootboxes/IMPLEMENTATION_PLAN.md)).
- Replaced the lootbox admin Types tab's ~14 per-type odds requests with one staff-only batch endpoint, `GET api/LootboxTypes/odds` ([KNG-45](https://linear.app/kngpandi/issue/KNG-45), [plan](specs/lootboxes/IMPLEMENTATION_PLAN.md)).
- Completed the plugin command-completion sweep with permission-filtered subcommands, vanish-aware player names, cached offline names where supported, fixed-value suggestions and explicit suppression of Bukkit's fallback suggestions ([KNG-30](https://linear.app/kngpandi/issue/KNG-30)).
- Fixed non-op staff access to `/freeze`, `/unfreeze`, `/staffchat` and `/knk` through the in-house permission model, and corrected the `/minecraft:tell`/`w` secure-chat mismatch ([KNG-24](https://linear.app/kngpandi/issue/KNG-24), [KNG-25](https://linear.app/kngpandi/issue/KNG-25)).
- Ensured siege members enter matches in survival so spawn-safe-zone damage denial is observable, and completed stable item-lore section spacing plus coherent lootbox special-description coloring ([KNG-28](https://linear.app/kngpandi/issue/KNG-28), [KNG-29](https://linear.app/kngpandi/issue/KNG-29)).
- Corrected untouched PermissionGroup premium-tier fields to submit `false` rather than `null` ([KNG-26](https://linear.app/kngpandi/issue/KNG-26)).
- Added the API half of the polymorphic PermissionHolder lookup used by PermissionGrant forms ([KNG-38](https://linear.app/kngpandi/issue/KNG-38)); its web-app half remains on the feature branch and is not yet part of the default-branch UI.

## 2026-10-02

- Added the maintained V1 → V2 → V3 [feature register](FEATURE_REGISTER.md), documented feature and guide updates at merge, and established this changelog ([KNG-33](https://linear.app/kngpandi/issue/KNG-33), [PR #5](https://github.com/PandiO/knk-workspace/pull/5)).

## 2026-09-29 — Backfilled from documented trunk merges

- Added managed WorldGuard-region ownership, priority and category-flag policy with idempotent startup repair. The live in-game smoke test remains tracked by [KNG-46](https://linear.app/kngpandi/issue/KNG-46) ([architecture](architecture/managed-worldguard-regions.md)).
- Modernized the shared AI-agent workflow and portable repository entrypoints ([KNG-32](https://linear.app/kngpandi/issue/KNG-32)).

## 2026-09-28 — Backfilled from documented trunk merges

- Completed the teleport feature merge, including requests, spawn/warps and ignore integration ([KNG-17](https://linear.app/kngpandi/issue/KNG-17), [design](specs/teleport/DESIGN.md)). Housing-linked `/home` remains separate scope.

## 2026-09-27 — Backfilled from documented trunk merges

- Added a permanent coin/gem transaction ledger and secure player payments, balance commands and administration ([KNG-21](https://linear.app/kngpandi/issue/KNG-21), [design](specs/currency-payments/DESIGN.md)).
- Added first-entry Town, District and Structure discoveries, rewards and a Discoveries menu ([KNG-20](https://linear.app/kngpandi/issue/KNG-20), [plan](specs/domain-discovery/IMPLEMENTATION_PLAN.md)).
- Expanded private messages with ignore, social-spy controls and moderation history ([KNG-18](https://linear.app/kngpandi/issue/KNG-18)). Its secure-chat follow-up was later completed in [KNG-25](https://linear.app/kngpandi/issue/KNG-25).
- Added world lootboxes, token pickups and an opening reel ([KNG-19](https://linear.app/kngpandi/issue/KNG-19)). The second live retest and remaining decisions are tracked in [KNG-31](https://linear.app/kngpandi/issue/KNG-31).

## 2026-09-26 — Backfilled from documented trunk merges

- Merged the Siege MVP: configurable scenarios, teams, objectives, live matches and player menus, following two live smoke-test rounds. Scheduled lobbies are later scope ([siege plan](specs/siege-minigame/IMPLEMENTATION_PLAN.md)).
- Added title and premium-tier display in game chat/tab list ([KNG-7](https://linear.app/kngpandi/issue/KNG-7), [KNG-8](https://linear.app/kngpandi/issue/KNG-8)).
- Ported general enchantment books and grade-based application limits ([KNG-5](https://linear.app/kngpandi/issue/KNG-5), [KNG-6](https://linear.app/kngpandi/issue/KNG-6)).
- Corrected hourly title salary and join-time payouts ([KNG-16](https://linear.app/kngpandi/issue/KNG-16)).

## 2026-09-25 — Backfilled from documented trunk merges

- Merged the persisted kit system, grant commands and kit authoring workflow. First-join grant remained to be confirmed live in the [kit plan](specs/kits/IMPLEMENTATION_PLAN.md).

For older implementation detail, consult [feature plans](specs/README.md), [dated reports](reports/) and the repository histories. Do not interpret the first date of a branch or issue as a release date.
