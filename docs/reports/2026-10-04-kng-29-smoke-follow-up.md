# KNG-29 smoke-test follow-up — 2026-10-04

Status: implemented, verified and pushed to the default branches where applicable.

## Outcome

- The KNG-30 plugin branch `codex/kng-30-command-completion-sweep` was explicitly updated from
  `origin/main`; it was already current. Commit `52ce855` descends from plugin `main` `ee7824c`.
- That branch already completes visible online players for
  `/knk itemblueprints give <item-id> <player>`. Item IDs intentionally remain free-form because the
  command has no bounded/cached blueprint catalogue suitable for synchronous completion.
- Flaming Samurai's seeded display description no longer embeds `&7`. Like ordinary ItemBlueprint
  descriptions, it now has no inline color override and therefore uses the normal lore-description
  color applied by Minecraft/Paper.
- API startup upgrades an existing Flaming Samurai only when its description exactly equals the old
  seeded `&7` text. Any administrator-authored description is preserved.

## Remote evidence

- knk-plugin KNG-30 feature branch: `codex/kng-30-command-completion-sweep` `52ce855` (unchanged,
  pushed, not merged).
- knk-plugin KNG-29 spacing fix: `main` `ee7824c` (already merged).
- knk-web-api lore-color follow-up: `master` `c0c2b22` (small QOL change pushed directly to the
  default branch).

No additional plugin merge was appropriate: merging the whole KNG-30 sweep would broaden this
KNG-29 follow-up, while the KNG-29 spacing code is already on `main`.

## Verification

`LootboxSeedTests` pass 13/13 on .NET 8. The regression coverage verifies all three relevant cases:

1. a fresh Flaming Samurai is created with the ordinary uncolored description;
2. the exact old seeded `&7` description is normalized on the next API startup;
3. a custom administrator description is not overwritten.

Only automated tests were run. Live verification remains with the developer as requested.

## Focused live check

1. Deploy/restart knk-web-api `master` at or after `c0c2b22`; startup runs `LootboxSeed` and upgrades
   the exact legacy description.
2. Generate or award Flaming Samurai through the lootbox flow and compare its description lines to
   an ordinary ItemBlueprint description. Both should use the same default dark-gray lore color.
3. On a plugin build from `codex/kng-30-command-completion-sweep`, enter
   `/knk itemblueprints give <valid-id> ` and press Tab. Visible online player names should appear;
   vanished players should remain hidden from viewers who cannot see them.

