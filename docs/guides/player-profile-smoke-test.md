# Staff player profile: status strip, tabs, freeze/unfreeze, timeline, paged audit, player search (#119) — smoke test

**Status:** automated in CI; manual steps not run. Written 2026-11-08 for knk-web-app `claude/player-profile-119` (chain 3 link V3); **merged 2026-11-12** (knk-web-app `main` `1371951`, with V7); 21 of 26 steps automated 2026-11-14, 4 manual left ([#511](https://github.com/PandiO/knk-workspace/issues/511))
**Last updated:** 2026-11-14 (§ 2 step 3: the game's freeze lock in a knk-plugin unit test, plugin backfill #511); 2026-11-14 (steps marked `[automated]` with their test, backfill #511); 2026-11-13 (Staff holds `knk.freeze`/`knk.unfreeze`, #367: § 4 step 4); 2026-11-12 (merged with V7); 2026-11-08
**Issues:** [PandiO/knk-workspace#119](https://github.com/PandiO/knk-workspace/issues/119) (MOD-3 part 1, MOD-4, MOD-5 of
the [2026-10-08 assessment](../reports/2026-10-08-web-app-ux-assessment.md))

About 10 minutes for the manual steps left (in game, with realtime). Steps marked `[automated]` run in CI: the Playwright
specs in knk-web-app `e2e/` (CI job `e2e`, mocked API) and the Jest tests next to the page (CI job `build-and-test`); you
don't repeat them. **No API change, no migration, no setting.** The web-app branch contains chain 3's V2
(`claude/dashboard-export-205`), V1 and chain 2's X1, so test it on a build of `claude/player-profile-119`.

You need:
- **A** — the owner or an Admin account (holds `*` or `knk.admin.*`, `knk.freeze`, `knk.unfreeze`,
  `knk.admin.currency.history`).
- **S** — a staff account with `knk.admin.user.manage` but **without** `knk.freeze`, `knk.unfreeze`,
  `knk.admin.user.group` and `knk.kit.give` (a test account outside the Staff group: since #367 Staff holds
  `knk.freeze` and `knk.unfreeze`).
- **T** — a member of the Staff group (for § 4 step 4, #367).
- **P** — a test player who can join the game server, with some balance history.
- Realtime on (`Realtime:Enabled`) for steps 1.4 and 3.6; everything else works without it.

## 1. Status strip and tabs

1. [automated] Header with name, `User #`, the Online chip and Freeze; the strip's mode, premium, Frozen and flag
   chips: `e2e/player-profile.spec.ts`, `src/pages/admin/__tests__/PlayerProfilePage.v3.test.tsx`
2. [automated] Six tabs, Overview first without `?tab=`; Economy writes `?tab=economy` and survives a reload:
   `e2e/player-profile.spec.ts`
3. [automated] → and End move the focus and the open tab; the breadcrumb leads back to Player moderation:
   `e2e/player-profile.spec.ts`
4. *(Realtime on, manual: needs a real player joining the game server.)* Have **P** join and quit the game: the Online
   chip follows within a second or two. The page side (the chip follows `PresenceChanged`) is automated in
   `src/pages/admin/__tests__/PlayerProfilePage.test.tsx`.
5. [automated] At 390 px no tab scrolls the page sideways: `e2e/player-profile.spec.ts`

## 2. Freeze and unfreeze

1. [automated] Freeze opens "Freeze {P}?" with a Reason; an empty reason says "Enter a reason." and sends nothing:
   `e2e/player-profile.spec.ts`
2. [automated] With a reason: toast "{P} is frozen", the Frozen chip and the reason, the button turns into Unfreeze, the
   API gets the reason: `e2e/player-profile.spec.ts`
3. [automated] The game's lock on a frozen player: walking to another block is undone, chat and commands other than
   `/msg` and `/r` are refused with their message, self-made teleports and damage are cancelled, a player who isn't
   frozen keeps all of it: knk-plugin `AdminFreezeListenerTest`. *(Manual: needs the game.)* That the freeze from the
   web app reaches the online player at once (#179) and how the refusals read in a real client (simulated players,
   [#540](https://github.com/PandiO/knk-workspace/issues/540)).
4. [automated] The Moderation tab holds the same freeze card: `e2e/player-profile.spec.ts`
5. [automated] Unfreeze confirms without a reason field; toast "{P} is unfrozen", the chip goes:
   `e2e/player-profile.spec.ts` (that P can move again in game is step 3's check)
6. *(Realtime on, manual: an in-game command.)* Freeze P **in game** with `/freeze {P} <reason>` while the profile is
   open. Within a few seconds the profile shows Frozen with that reason; without realtime, after **Reload**. Unfreeze
   again. The page's re-read on the push is automated in `PlayerProfilePage.v3.test.tsx` ("live updates").

## 3. Activity: timeline and audit log

1. [automated] The timeline merges audit entries and balance changes ("+500 coins" with the reason) newest first, with
   the line about where it comes from: `e2e/player-profile.spec.ts`, `PlayerProfilePage.v3.test.tsx`
2. [automated] The **Economy** chip hides the coin lines and brings them back: `e2e/player-profile.spec.ts`
3. [automated] **Load older** pages back without duplicates: `PlayerProfilePage.v3.test.tsx`
4. [automated] The audit log pages on the server ("Showing 1 to 25 of N entries", Next) and the *Action* filter starts
   from page 1: `e2e/player-profile.spec.ts`
5. Note, nothing to check: an admin balance adjustment shows twice, as "Balances adjusted" and as "+n coins" (LV3-4).
6. [automated] The timeline and audit log reload by themselves when another staff member changes P (realtime push):
   `PlayerProfilePage.v3.test.tsx` ("live updates")

## 4. Without the nodes

1. [automated] Without `knk.freeze`: Freeze greyed out with "Requires knk.freeze": `e2e/player-profile.spec.ts`
2. [automated] Permissions (Assign, Save, remove) greyed out with "Requires knk.admin.user.group" / "Requires
   knk.admin.user.perm"; Grant on kits with "Requires knk.kit.give"; the payment lock without
   `knk.admin.currency.lock`: `e2e/player-profile.spec.ts`, `PlayerProfilePage.v3.test.tsx`
3. [automated] Without `knk.admin.currency.history` the timeline says "Balance changes need
   knk.admin.currency.history." and asks no balance history: `e2e/player-profile.spec.ts`
4. *(Manual: the Staff group's nodes come from the `SeedStaffFreezeNodes` seed on a real database, and the in-game
   commands need the game.)* *(#367)* Log in as **T** (Staff group) and open **P**: **Freeze** is enabled without a
   "Requires" hint. Freeze P with a reason, then Unfreeze: both succeed as in § 2. In game, T runs
   `/freeze {P} <reason>` and `/unfreeze {P}`: both work (P ranks below Staff; the plugin refuses an equal or higher rank).

## 5. Player search (Moderation → All players)

1. [automated] A dashless UUID says "Searching by UUID.", is searched with its dashes and Enter writes `?q=…`:
   `e2e/player-profile.spec.ts`, `src/pages/admin/__tests__/UserModerationPage.search.test.tsx`
2. [automated] Coins (and Username, Email) sort on the server, ascending then descending; the URL has
   `sort=coins&dir=desc` and the page: `e2e/player-profile.spec.ts`, `UserModerationPage.search.test.tsx`
3. [automated] Back from a profile brings the same search, sort and page back: `e2e/player-profile.spec.ts`
4. [automated] **Recently opened** lists the profiles you opened, newest first, and **Clear** empties it; each viewer has
   their own list: `e2e/player-profile.spec.ts`, `UserModerationPage.search.test.tsx`
5. [automated] **Last seen** says "Now" for online players: `e2e/player-profile.spec.ts`

## 6. Permissions tab: grant form on top, search, sortable columns (#407)

Added 2026-11-15 for knk-web-app `claude/profile-permissions-407`
([PandiO/knk-workspace#407](https://github.com/PandiO/knk-workspace/issues/407)). No API change, no migration, no
setting. Open **P**'s profile as **A**, tab **Permissions** (`/admin/users/<id>?tab=permissions`), Effective
Permissions.

1. [automated] The grant/deny form sits above the list; without a sort the list keeps the API's order and no header is
   marked sorted: `e2e/player-profile.spec.ts` ("the grant/deny form sits above the list …")
2. [automated] Save grants a node with the 1-day default expiry, clears the node field and the list refreshes:
   `e2e/player-profile.spec.ts`
3. [automated] A permanent deny needs **Clear** on the expiry, shows as Denied / Direct grant after the refresh, and the
   next grant starts from 1 day again: `e2e/player-profile.spec.ts`
4. [automated] Removing a direct grant refreshes the list; inherited rows say "Inherited" and have no remove button:
   `e2e/player-profile.spec.ts`
5. [automated] The search narrows the list as you type, by node and by source (a group's name, "direct" for direct
   grants), shows "n of N nodes", and says "No permissions match “…”." when nothing matches:
   `e2e/player-profile.spec.ts`, `src/pages/admin/playerProfile/__tests__/effectivePermissions.test.ts`
6. [automated] Node, Value and Source sort ascending, then descending, then back to the API's order, with the sort icon
   and `aria-sort`; a sort applies to the searched rows and stays after a change: `e2e/player-profile.spec.ts`,
   `effectivePermissions.test.ts`
7. [automated] Without `knk.admin.user.perm` the form and the remove buttons are greyed out with "Requires
   knk.admin.user.perm"; search and sort still work: `e2e/player-profile.spec.ts`
8. *(Manual: a real API and a real player's list; the suite mocks both.)* On a player with many nodes from several
   groups, grant `knk.test.profile` with the default expiry: the form is in view without scrolling, the new row appears
   with "Direct grant", and searching `knk.test` or the group's name finds what you expect. Remove the node again.
9. *(Manual: how it looks.)* At phone width and on a desktop, the search box, the sort arrows and the "Inherited" labels
   read well in both light and dark themes.

## Findings

_Fill in while testing: step, what happened, expected._
