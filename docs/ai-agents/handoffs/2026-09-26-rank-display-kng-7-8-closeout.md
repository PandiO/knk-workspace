# Handoff — rank display in chat/tab list + one rank per player: closed out (Linear KNG-7, KNG-8)

**Status:** Done. Implemented, tested in-game by the developer, and merged to trunk.
**Last updated:** 2026-09-26

The full description is [`docs/specs/user-features/RANK_DISPLAY.md`](../../specs/user-features/RANK_DISPLAY.md).

## What shipped

- Chat shows v1's `-{Title}-` segment and per-rank colors: `[OWNER]/[STAFF]-{Title}- Name`,
  `-{Noble Title}- Name`, `-{Title}- Name`.
- Tab list / nametag colored per rank (owner, staff, one team per premium rank, default).
- `PermissionGroup.ChatPrimaryColor/ChatSecondaryColor/NameColor` as `&` codes, seeded with v1's colors
  for Default/Noble/Royal/Dragon Blood, editable in the FormWizard.
- The Player manager keeps each player on exactly one rank (Default or a premium rank), with a confirmed
  switch; the premium ranks inherit from Default.
- Staff changes and logins now refresh the player's cached data, so chat and the tab list update at once.
- Confirm/Cancel buttons appear without re-opening the menu (all menus).

## Where it is

| Repo | Trunk |
|---|---|
| knk-web-api `master` | merge `a102eea`: `c5ed257`, `6cfe6f5`, `4aea79d`, `6cdd50a`, `14d6f04` (+ `5722ab7` master merged in). Migrations `20260926081602_AddPermissionGroupDisplayColors`, `20260926121530_PremiumRanksInheritDefault` |
| knk-plugin `main` | merge `f65ae2e`: `fef6476`, `1a8d062`, `e75d804`, `a9cdfde`, `3542797`, `6f61958`, `3bf2f04`, `8f9f85a` (+ `5f43d98` main merged in) |
| knk-workspace `main` | the spec above, this handoff, `user-features/IMPLEMENTATION_PLAN.md` §5, `inventory-menu/CONTENT_PORT_PLAN.md` CP8, `ACTIVE_SESSIONS.md` |
| knk-web-app | no changes |

## After pulling trunk

- **knk-web-api:** `dotnet ef database update`. If you already applied the two migrations from the feature
  branch, EF skips them; `AddGradeDropChanceAndEnchantCap` (KNG-6) sits between them by timestamp and is
  applied normally. The migration IDs were kept on purpose, since they were already applied locally.
- **knk-plugin:** build `main` once (`./gradlew :knk-paper:build`). The merge with KNG-9/10/11/13 was
  conflict-free and knk-core/knk-api-client tests pass in a Maven-Central-only build, but knk-paper
  couldn't be compiled in the cloud.
- **Menu text (optional):** `scripts/reset-content-menus.ps1` to get the groups menu's new header text.
- **Web app (once):** add the three color fields to the PermissionGroup FormConfiguration with "Enable
  Minecraft text coloring" (spec §7).

## Feature branches: safe to delete (developer action)

Everything on these branches is on trunk. The cloud session can't delete branches (the git proxy refuses),
so please delete them on GitHub's Branches page or locally:

```sh
# knk-plugin and knk-web-api:
git push origin --delete claude/kng-7-8-chat-tier-title
# knk-workspace only (its one extra commit, c5ec6a6, is an ACTIVE_SESSIONS row superseded on main):
git push origin --delete claude/new-session-st3t83
```

Last commits, in case one needs restoring: `claude/kng-7-8-chat-tier-title` — knk-plugin `5f43d98`,
knk-web-api `5722ab7`; `claude/new-session-st3t83` (knk-workspace) `c5ec6a6`.

## Open follow-ups

See spec §10: live refresh for web-app rank changes and mid-session expiry; optional web-app list columns
and preview; API-side one-rank enforcement if wanted.
