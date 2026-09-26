# User Features — Rank display in chat and the tab list, one rank per player (Linear KNG-7, KNG-8)

**Status:** Implemented, tested in-game by the developer, and **merged to trunk** 2026-09-26: knk-web-api
`master` (merge `a102eea`), knk-plugin `main` (merge `f65ae2e`). Migrations
`20260926081602_AddPermissionGroupDisplayColors` and `20260926121530_PremiumRanksInheritDefault`.
knk-paper was never compiled in the cloud session (Paper's Maven repo is blocked there); the developer's
local build and in-game test are what verified it.
**Last updated:** 2026-09-26

Restores v1's chat line (title in chat, KNG-8) and per-tier colors in chat and the tab list (KNG-7), and
makes the Player manager keep each player on exactly one rank. The v1 research (legacy code, the
recovered `Donator` table) is on the two Linear issues; this note records what v3 does.

## 1. Summary

- **Ranks:** a player holds exactly one of **Default** (free) or **Noble / Royal / Dragon Blood**
  (premium, bought with real money, upgrading from Default). In the Player manager, picking a rank
  replaces the old one.
- **Chat:** `[OWNER]-{Title}- Name: msg`, `[STAFF]-{Title}- Name: msg`, `-{Noble Knight}- Name: msg`,
  `-{Knight}- Name: msg`, colored per rank.
- **Tab list / nametag:** owner, staff, one team per premium rank, default - each with its own color.
- **Colors live in the database** on `PermissionGroup`, as Minecraft `&` formatting codes, editable in
  the web app's FormWizard.
- **Changes show at once:** a staff change in the Player manager re-reads the player and redraws their
  tab list; a login always reads the player fresh from the API.

## 2. Data model (knk-web-api)

`PermissionGroup` gained three nullable `varchar(32)` fields:

| Field | Used for | Default | Noble | Royal | Dragon Blood |
|---|---|---|---|---|---|
| `ChatPrimaryColor` | title, tier name and username in chat | `&a` | `&e` | `&b` | `&c` |
| `ChatSecondaryColor` | the `-{ }-` brackets in chat | `&2` | `&6` | `&9` | `&4` |
| `NameColor` | tab-list / nametag (scoreboard team) color | `&7` | `&e` | `&b` | `&c` |

- These are v1's `Donator` table colors (read from the live NAS database on 2026-09-26) and v1's
  hardcoded scoreboard-team colors. Chat and name colors are separate fields on purpose: v1's Default
  already differed (green chat, gray name).
- **Format:** legacy `&` codes only, no text: colors `&0`-`&f`, formats `&k`-`&o`, reset `&r`, hex
  `&x&r&r&g&g&b&b`. The same format the FormWizard's "Minecraft text coloring" field setting previews
  and the plugin's `DisplayTextFormatter` renders. `MinecraftTextStyle` validates on create/update
  (accepts `§` for `&`, stores lower-case) and rejects anything else, e.g. `YELLOW` or `&eNoble`.
- `PermissionGroupService.UpdateAsync` copies fields by hand (not AutoMapper), so the new fields are
  copied there explicitly.
- **Inheritance:** Noble, Royal and Dragon Blood now have `ParentGroupId` = Default (migration
  `PremiumRanksInheritDefault`, only where no parent was set). Upgrading a player removes their Default
  membership, so this keeps whatever Default grants. Default has no grants yet.

**Resolution onto the user.** `UserDto`/`UserSummaryDto` (`GET /api/users/uuid|username`) carry
`chatPrimaryColor`, `chatSecondaryColor` and `nameColor`. Each comes from the user's active premium tier,
falling back field by field to the **Default** group's value (found by name, `UserService.DefaultGroupName`,
loaded once per request). A player without a premium tier therefore gets Default's colors whether or not
they hold the Default membership.

## 3. Chat (knk-plugin)

`PlayerListener.onChat` picks the rank and calls the Bukkit-free `chat/ChatLineFormat`:

| Who | Line | Colors | Title bold |
|---|---|---|---|
| Owner (`knk.mode.owner`) | `[OWNER]-{Title}- Name: msg` | fixed `ColorOptions.ownerformat`/`ownersubjects` | yes |
| Staff (`knk.mode.staff`) | `[STAFF]-{Title}- Name: msg` | fixed `ColorOptions.staffformat`/`staffsubjects` | yes |
| Premium | `-{Noble Title}- Name: msg` | brackets `chatSecondaryColor`, rest `chatPrimaryColor` | no (unless the codes say so) |
| Everyone else | `-{Title}- Name: msg` | Default's colors; `ColorOptions.defaultformat/defaultsubjects` if the API sends none | no |

- The message takes the name's **color** but not its formats, so a bold tier style doesn't bold every
  message. Color codes typed in the message still win.
- The `-{…}-` part is left out when there's nothing to put in it (summary not cached yet).
- The summary is read with `UserCache.getStale()`: no API call per message, and the title doesn't vanish
  when the 15-minute cache entry expires.
- `utils/LegacyStyles` turns the `&` codes into an Adventure `Style` (Bukkit-free).

## 4. Tab list / nametag (knk-plugin)

`ScoreboardUtil.setScoreboard` puts each player on one team via `utils/TabListTeam`, in v1's order:
owner (DARK_PURPLE), staff (BLUE, a new team), `tier_<groupId>` (created on demand, colored by
`nameColor`), else `default` (Default's `nameColor`, GRAY if unset). A team takes only the 16 named
colors: a hex color maps to the nearest one and formats are ignored. The color is re-applied on each
join, so admin edits reach the team; a join with no cached summary leaves the `default` team's color as
it is. The footer lines (title, premium tier) are unchanged.

## 5. Keeping the display in sync

- **After a staff change** (Player manager or `/knk user`): `UserAdminService` re-reads the target from
  the API into the user cache (`UsersDataAccess.refreshAsync`) once the write succeeds - for group/rank
  changes and XP/title changes - and, if they're online, redraws their tab-list team and footer through a
  display hook wired in `KnKPlugin` to `ScoreboardUtil.setScoreboard`. A failed refresh doesn't fail the
  change.
- **On login:** `PlayerListener.onValidateLogin` reads with `FetchPolicy.API_THEN_CACHE_REFRESH` (was
  `STALE_OK`, which served any unexpired cache entry without asking the API, so a relog brought back the
  pre-change rank). The cache is still used when the API is down.

## 6. One rank per player (Player manager, `users.manager.groups`)

`user/PlayerRanks` defines the rank set: Default (by name, like the API) plus every `IsPremiumTier` group.

| Click | Result |
|---|---|
| A rank the player doesn't hold | chat prompt "Set Steve's rank to Royal (replaces Default)?", Confirm/Cancel appear; on Confirm `UserAdminService.setRank` adds the new rank, then removes every other active rank (Default included) |
| A premium rank they hold (seed's confirmed remove) | drops them back to Default (same switch) |
| Default when they hold it | refused: "Default is the base rank - pick another rank to replace it." |
| Any other group (Staff, …) | plain add / confirmed remove, unchanged |

- `setRank` adds first, then removes, so a failure part-way never leaves a player without a rank.
- The staff member sees "Set Steve's rank to Royal (was Default)."; the player sees "Your rank is now
  Royal!".
- Rows: Default is an IRON_BLOCK "Free rank", premium ranks GOLD_BLOCK "Premium rank", each with a
  click hint.
- The switch lives in the plugin (the seed binds rank rows to a plain "add"), so it works with the
  menu templates already in the database. The seed's header text was updated too; that text only
  reaches an existing database after `scripts/reset-content-menus.ps1`.
- **Confirm/Cancel now appear live.** `menu.confirm.request`/`accept`/`cancel` repaint the open menu
  (they didn't, so the buttons only showed after re-opening). This applies to every menu that uses them.
- **Not enforced elsewhere:** `/knk user <p> group add` and the web app can still give a player several
  ranks - deliberately, since that allows a temporary higher tier on top of a permanent one (v1's
  `DonatorTemp`). The displayed tier is then the highest-weight active one.

## 7. Admin how-to: editing the colors in the web app

The three fields appear in the FormConfigBuilder automatically (the API reflects `PermissionGroup`).
A saved FormConfiguration doesn't gain new fields by itself, so once:

1. Open the PermissionGroup form configuration in the FormConfigBuilder.
2. Add `ChatPrimaryColor`, `ChatSecondaryColor` and `NameColor`.
3. Tick **"Enable Minecraft text coloring"** on each.
4. Save.

Enter codes only, e.g. `&e` or `&6&l`. The field preview renders the field's own text, so a code-only
value previews as empty.

## 8. Decisions made during the work

1. **Default is DB-driven**, like the tiers: the `Default` `PermissionGroup` row existed
   (`SeedDefaultPermissionGroup`), so it got v1's colors instead of hardcoded constants.
2. **`&` codes, not color names** (developer suggestion): matches the FormWizard's Minecraft text
   coloring and allows bold/hex per tier.
3. **Staff** got a `[STAFF]` chat tag and a BLUE team (v1 had both; v3 had neither), using the
   `knk.mode.staff` node.
4. **Not rebuilt:** Co-Owner (no v3 rank or node) and v1's bold owner/staff names in the tab list (a
   team color can't be bold).
5. **One rank per player, including Default** (developer): the premium ranks inherit from Default so
   upgrading keeps Default's grants.

## 9. Tests

- knk-web-api: `PermissionGroupDisplayColorsTests` (code validation, create/update, tier DTO, resolution
  and Default fallback). Suite on `master` after the merge: 553/558, the same 5 pre-existing failures.
- knk-plugin: `ChatLineFormatTest`, `TabListTeamTest`, `LegacyStylesTest`, `UsersMapperDisplayColorsTest`,
  `PermissionGroupsQueryApiImplTest`, and new cases in `UserAdminServiceTest` (refresh + redraw, rank
  switch order, failures) and `UserManagerMenuFeatureTest` (switch prompt, confirm, Default rules, row
  text, live repaint). There were no tests for `onChat` before.

## 10. Follow-ups

- A rank changed from the **web app** while the player is online, or a temporary tier expiring
  mid-session, only shows after their next login (the API doesn't notify the plugin).
- The web app's `objectConfigs.tsx` PermissionGroup list columns don't show the colors (optional).
- The FormWizard preview could render code-only values against sample text.
- If one rank per player should hold everywhere, `UserPermissionGroupService` (API) would be the place
  to enforce it - today only the Player manager does.
