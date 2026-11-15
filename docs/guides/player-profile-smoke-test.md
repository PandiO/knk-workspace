# Staff player profile: status strip, tabs, freeze/unfreeze, timeline, paged audit, player search (#119) — smoke test

**Status:** 24 of 26 steps automated in CI (tagged, 4 of them partly; [#511](https://github.com/PandiO/knk-workspace/issues/511), 2026-11-14); every step can still be run by hand; manual steps not run. Written 2026-11-08 for knk-web-app `claude/player-profile-119` (chain 3 link V3); **merged 2026-11-12** (knk-web-app `main` `1371951`, with V7)
**Last updated:** 2026-11-15 (every step in full again, covered steps tagged `[automated: …]` or `[partly automated: …]`, developer decision 2026-11-15, #511); 2026-11-14 (§ 2 step 3: the game's freeze lock in a knk-plugin unit test, plugin backfill #511); 2026-11-14 (steps marked `[automated]` with their test, backfill #511); 2026-11-13 (Staff holds `knk.freeze`/`knk.unfreeze`, #367: § 4 step 4); 2026-11-12 (merged with V7); 2026-11-08
**Issues:** [PandiO/knk-workspace#119](https://github.com/PandiO/knk-workspace/issues/119) (MOD-3 part 1, MOD-4, MOD-5 of
the [2026-10-08 assessment](../reports/2026-10-08-web-app-ux-assessment.md))

About 25 minutes for a full manual run, about 10 for the untagged steps and the by-hand parts (in game, with realtime).
Steps tagged `[automated: …]` run in CI: the Playwright specs in knk-web-app `e2e/` (CI job `e2e`, mocked API) and the
Jest tests next to the page (CI job `build-and-test`): skip them or run them by hand. **No API change, no migration, no setting.** The web-app branch contains chain 3's V2
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

1. [automated: `e2e/player-profile.spec.ts`, `src/pages/admin/__tests__/PlayerProfilePage.v3.test.tsx`] As **A**, open Moderation → **P**. The header shows P's name, `User #`, UUID and email, then a row of chips: Online or
   "Offline · last seen …", the mode when P is in Staff/Owner mode, the premium tier with its end date, and flags where
   they apply (Deactivated, Not admitted, Minecraft-only, Email not verified). **Freeze** and **Reload** are on the right.
2. [automated: `e2e/player-profile.spec.ts`] Below the header there are six tabs: Overview, Economy, Permissions, Moderation, Activity, Privacy. Overview is open;
   the address has no `?tab=`. Click **Economy**: the address ends in `?tab=economy` and the page shows Payments, Adjust
   balance, Salary, Kits and Balance history. Reload the browser: Economy is still open.
3. [automated: `e2e/player-profile.spec.ts`] Click the Economy tab, then press **→** and **End** on the keyboard: the focus and the open tab move along. The
   breadcrumb above the page (Players & support › Player moderation › Player profile) leads back to Moderation.
4. [partly automated: `src/pages/admin/__tests__/PlayerProfilePage.test.tsx` (the chip follows `PresenceChanged`); by hand: a real player joining and quitting the game server] *(Realtime on)* Have **P** join and quit the game: the Online chip follows within a second or two.
5. [automated: `e2e/player-profile.spec.ts`] At **phone width** (390 px, or the browser's device mode) the page doesn't scroll sideways on any tab; the tab row
   scrolls on its own.

## 2. Freeze and unfreeze

1. [automated: `e2e/player-profile.spec.ts`] As **A**, click **Freeze**. A red dialog "Freeze {P}?" explains what freezing does and asks a **Reason**. Click
   Freeze with an empty reason: "Enter a reason." and nothing happens.
2. [automated: `e2e/player-profile.spec.ts` (also that the API gets the reason)] Type a reason (e.g. "Smoke test #119") and click **Freeze**. A toast "{P} is frozen" appears; the strip shows a red
   **Frozen** chip and a banner "Frozen since {time} by {A} · Reason: Smoke test #119"; the button is now **Unfreeze**.
3. [partly automated: knk-plugin `AdminFreezeListenerTest` (the game's lock on a frozen player, and a player who isn't frozen keeps all of it); by hand: that the freeze from the web app reaches the online player at once (#179) and how the refusals read in a real client (simulated players, [#540](https://github.com/PandiO/knk-workspace/issues/540))] In game, **P** can't move (walking to another block is undone), chat or use commands other than `/msg` and `/r`
   (each refusal with its message); teleports P makes and damage are cancelled (at once, #179).
4. [automated: `e2e/player-profile.spec.ts`] Open the **Moderation** tab: the Freeze card says the same, with Unfreeze.
5. [partly automated: `e2e/player-profile.spec.ts`; by hand: P can move again in game (step 3's check)] Click **Unfreeze**: a confirm without a reason field (the API doesn't store an unfreeze reason yet). Confirm: toast
   "{P} is unfrozen", the chip and banner go, P can move again in game.
6. [partly automated: `PlayerProfilePage.v3.test.tsx` ("live updates": the page re-reads on the push); by hand: the in-game `/freeze` command] Freeze P **in game** with `/freeze {P} <reason>` while the profile is open. *(Realtime on)* Within a few seconds the
   profile shows Frozen with that reason; without realtime, after **Reload**. Unfreeze again.

## 3. Activity: timeline and audit log

1. [automated: `e2e/player-profile.spec.ts`, `PlayerProfilePage.v3.test.tsx`] Open **Activity**. **Timeline** lists P's history newest first: the freeze and unfreeze from step 2, group and grant
   changes, kit grants, and (A holds `knk.admin.currency.history`) every balance change, e.g. "+500 coins" with the
   reason, before → after and the transaction id. The line under the heading says "From the audit log and the balance
   history. Game sessions are not in it yet."
2. [automated: `e2e/player-profile.spec.ts`] Click the **Economy** chip: the coin lines and balance adjustments disappear; click it again to bring them back.
3. [automated: `PlayerProfilePage.v3.test.tsx`] Click **Load older** until it disappears; the dates keep going down, no row shows twice.
4. [automated: `e2e/player-profile.spec.ts`] **Audit log** below: a table with When, Action, By, Details and a pager ("Showing 1 to 25 of N entries") when P has
   more than 25 entries. Next/Previous page through them. Pick **Player frozen** in *Action*: only the freezes show,
   from page 1.
5. Note, nothing to check: an admin balance adjustment shows twice, as "Balances adjusted" and as "+n coins" (LV3-4).
6. [automated: `PlayerProfilePage.v3.test.tsx` ("live updates")] *(Realtime on)* Keep the Activity tab open and, from another browser as a second staff account, assign P a group:
   the timeline and audit log reload by themselves.

## 4. Without the nodes

1. [automated: `e2e/player-profile.spec.ts`] Log in as **S** and open **P**. **Freeze** is greyed out with "Requires knk.freeze" next to it (hover shows it too).
2. [automated: `e2e/player-profile.spec.ts`, `PlayerProfilePage.v3.test.tsx`] **Permissions**: Assign, Save and the remove buttons are greyed out with "Requires knk.admin.user.group" /
   "Requires knk.admin.user.perm". **Economy**: Grant on the kits is greyed out with "Requires knk.kit.give"; without
   `knk.admin.currency.lock` the payment lock is greyed out with its hint.
3. [automated: `e2e/player-profile.spec.ts`] **Activity**: the timeline says "Balance changes need knk.admin.currency.history." when S lacks that node, and shows
   only audit entries.
4. *(Manual: the Staff group's nodes come from the `SeedStaffFreezeNodes` seed on a real database, and the in-game commands need the game.)* *(#367, after `SeedStaffFreezeNodes`)* Log in as **T** (Staff group) and open **P**: **Freeze** is enabled without a
   "Requires" hint. Freeze P with a reason, then Unfreeze: both succeed as in § 2. In game, T runs
   `/freeze {P} <reason>` and `/unfreeze {P}`: both work (P ranks below Staff; the plugin refuses an equal or higher rank).

## 5. Player search (Moderation → All players)

1. [automated: `e2e/player-profile.spec.ts`, `src/pages/admin/__tests__/UserModerationPage.search.test.tsx`] Copy P's UUID, remove the dashes, paste it in the search box: under the box "Searching by UUID."; press Enter: P is
   found. The address now has `?q=…`.
2. [automated: `e2e/player-profile.spec.ts`, `UserModerationPage.search.test.tsx`] Click the **Coins** header: sorted by coins ascending, again: descending (the arrow shows it). **Username** and
   **Email** sort too. The address has `sort=coins&dir=desc`. Go to page 2.
3. [automated: `e2e/player-profile.spec.ts`] Open a player, then the browser's **Back**: the same search, sort and page come back.
4. [automated: `e2e/player-profile.spec.ts`, `UserModerationPage.search.test.tsx`] Above the search, **Recently opened:** lists the profiles you opened last (newest first, links). **Clear** empties
   it. Log in as another account in the same browser: that account has its own list.
5. [automated: `e2e/player-profile.spec.ts`] The new **Last seen** column shows "Now" for online players.

## 6. Permissions tab: grant form on top, search, sortable columns (#407)

**Status:** 10 of 12 steps automated in CI (tagged); every step can still be run by hand; manual steps not run. A full
manual run takes about 15 minutes, the untagged steps (11, 12) about 5. Added 2026-11-15 for knk-web-app
`claude/profile-permissions-407` ([PandiO/knk-workspace#407](https://github.com/PandiO/knk-workspace/issues/407),
merged into `next` 2026-11-15, knk-web-app#37). No API change, no migration, no setting. Log in as **A**, open **P**'s
profile, tab **Permissions** (`/admin/users/<id>?tab=permissions`), card Effective Permissions.

1. [automated: `e2e/player-profile.spec.ts`] The grant/deny form (Grant/deny node, Value, Expires, **Save**) sits above
   the list. The list shows P's nodes in the order the API gives them, and none of the Node, Value and Source headers
   shows an up or down arrow (`aria-sort="none"`).
2. [automated: `e2e/player-profile.spec.ts`] Type `knk.test.profile`, leave Value on Grant and Expires on its default (a
   day from now, label "(clear for permanent)"), **Save**. The node field empties, the expiry goes back to a day ahead,
   and the list reloads with `knk.test.profile`, Granted, Direct grant. In the network tab `POST api/Users/<id>/grants`
   carries an `expiresAt` about 24 hours ahead.
3. [automated: `e2e/player-profile.spec.ts`] Type `knk.test.deny`, choose Deny, click **Clear** next to the expiry: the
   label says "(permanent)". **Save**: the row shows Denied and Direct grant, the request carries `expiresAt: null`, and
   the expiry field is back to a day ahead for the next grant.
4. [automated: `e2e/player-profile.spec.ts`] On `knk.test.profile` press × ("Remove direct grant of knk.test.profile"):
   after the reload the row is gone (`DELETE api/Users/<id>/grants?node=knk.test.profile`). Rows a group gives say
   "Inherited" and have no ×. Remove `knk.test.deny` the same way.
5. [automated: `e2e/player-profile.spec.ts`, `src/pages/admin/playerProfile/__tests__/effectivePermissions.test.ts`]
   Type part of a node in the search box (for example `GATE`; case doesn't matter): only the matching rows stay, and
   "n of N nodes" shows next to the box.
6. [automated: `e2e/player-profile.spec.ts`, `effectivePermissions.test.ts`] Type the name of one of P's groups (for
   example `staff`): the rows that group gives stay. Type `direct`: only the direct grants stay.
7. [automated: `e2e/player-profile.spec.ts`, `effectivePermissions.test.ts`] Type text no node or source has: the table
   says "No permissions match “…”." and "0 of N nodes" shows. Empty the box: every row comes back in the API's order.
8. [automated: `e2e/player-profile.spec.ts`, `effectivePermissions.test.ts`] Click **Node**: A to Z with an up arrow
   (`aria-sort="ascending"`). Click again: Z to A with a down arrow (`descending`). Click a third time: the API's order,
   no arrow. Do the same on **Value** (Denied before Granted ascending, ties by node) and **Source** (by the name shown,
   "Direct grant" sorted among the group names, ties by node).
9. [automated: `e2e/player-profile.spec.ts`] Sort Node descending, search `direct`, then grant a new node with the form:
   the new row appears in its sorted place among the searched rows and the Node header stays descending. Remove it
   again.
10. [automated: `e2e/player-profile.spec.ts`] Log in as **S** (no `knk.admin.user.perm`) and open the same tab: Grant/deny
    node, Value, Expires and **Save** are greyed out with "Requires knk.admin.user.perm" next to Save, and each × is
    greyed out. Search and sorting still work, and nothing is sent.
11. Manual (a real API and a real player's list; the suite mocks both): on a player with many nodes from several groups,
    grant `knk.test.profile` with the default expiry. The form is in view without scrolling, the new row appears with
    "Direct grant", and searching `knk.test` or the group's name finds what you expect. Remove the node again.
12. Manual (how it looks): at phone width and on a desktop, the search box, the sort arrows and the "Inherited" labels
    read well in both light and dark themes.

## Findings

_Fill in while testing: step, what happened, expected._
