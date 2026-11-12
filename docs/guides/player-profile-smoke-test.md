# Staff player profile: status strip, tabs, freeze/unfreeze, timeline, paged audit, player search (#119) — smoke test

**Status:** Written 2026-11-08 for knk-web-app `claude/player-profile-119` (chain 3 link V3); **merged 2026-11-12** (knk-web-app `main` `1371951`, with V7); not run by the developer
**Last updated:** 2026-11-12 (merged with V7); 2026-11-08
**Issues:** [PandiO/knk-workspace#119](https://github.com/PandiO/knk-workspace/issues/119) (MOD-3 part 1, MOD-4, MOD-5 of
the [2026-10-08 assessment](../reports/2026-10-08-web-app-ux-assessment.md))

About 25 minutes. **No API change, no migration, no setting.** The web-app branch contains chain 3's V2
(`claude/dashboard-export-205`), V1 and chain 2's X1, so test it on a build of `claude/player-profile-119`.

You need:
- **A** — the owner or an Admin account (holds `*` or `knk.admin.*`, `knk.freeze`, `knk.unfreeze`,
  `knk.admin.currency.history`).
- **S** — a staff account with `knk.admin.user.manage` but **without** `knk.freeze`, `knk.unfreeze`,
  `knk.admin.user.group` and `knk.kit.give` (a test account; take the nodes away for the test if Staff holds them).
- **P** — a test player who can join the game server, with some balance history.
- Realtime on (`Realtime:Enabled`) for steps 1.4 and 3.6; everything else works without it.

## 1. Status strip and tabs

1. As **A**, open Moderation → **P**. The header shows P's name, `User #`, UUID and email, then a row of chips: Online or
   "Offline · last seen …", the mode when P is in Staff/Owner mode, the premium tier with its end date, and flags where
   they apply (Deactivated, Not admitted, Minecraft-only, Email not verified). **Freeze** and **Reload** are on the right.
2. Below the header there are six tabs: Overview, Economy, Permissions, Moderation, Activity, Privacy. Overview is open;
   the address has no `?tab=`. Click **Economy**: the address ends in `?tab=economy` and the page shows Payments, Adjust
   balance, Salary, Kits and Balance history. Reload the browser: Economy is still open.
3. Click the Economy tab, then press **→** and **End** on the keyboard: the focus and the open tab move along. The
   breadcrumb above the page (Players & support › Player moderation › Player profile) leads back to Moderation.
4. *(Realtime on)* Have **P** join and quit the game: the Online chip follows within a second or two.
5. At **phone width** (390 px, or the browser's device mode) the page doesn't scroll sideways on any tab; the tab row
   scrolls on its own.

## 2. Freeze and unfreeze

1. As **A**, click **Freeze**. A red dialog "Freeze {P}?" explains what freezing does and asks a **Reason**. Click
   Freeze with an empty reason: "Enter a reason." and nothing happens.
2. Type a reason (e.g. "Smoke test #119") and click **Freeze**. A toast "{P} is frozen" appears; the strip shows a red
   **Frozen** chip and a banner "Frozen since {time} by {A} · Reason: Smoke test #119"; the button is now **Unfreeze**.
3. In game, **P** can't move, chat or use commands (at once, #179).
4. Open the **Moderation** tab: the Freeze card says the same, with Unfreeze.
5. Click **Unfreeze**: a confirm without a reason field (the API doesn't store an unfreeze reason yet). Confirm: toast
   "{P} is unfrozen", the chip and banner go, P can move again in game.
6. Freeze P **in game** with `/freeze {P} <reason>` while the profile is open. *(Realtime on)* Within a few seconds the
   profile shows Frozen with that reason; without realtime, after **Reload**. Unfreeze again.

## 3. Activity: timeline and audit log

1. Open **Activity**. **Timeline** lists P's history newest first: the freeze and unfreeze from step 2, group and grant
   changes, kit grants, and (A holds `knk.admin.currency.history`) every balance change, e.g. "+500 coins" with the
   reason, before → after and the transaction id. The line under the heading says "From the audit log and the balance
   history. Game sessions are not in it yet."
2. Click the **Economy** chip: the coin lines and balance adjustments disappear; click it again to bring them back.
3. Click **Load older** until it disappears; the dates keep going down, no row shows twice.
4. **Audit log** below: a table with When, Action, By, Details and a pager ("Showing 1 to 25 of N entries") when P has
   more than 25 entries. Next/Previous page through them. Pick **Player frozen** in *Action*: only the freezes show,
   from page 1.
5. An admin balance adjustment shows in the timeline twice — as "Balances adjusted" (audit log) and as "+n coins"
   (ledger). That is expected (LV3-4).
6. *(Realtime on)* Keep the Activity tab open and, from another browser as a second staff account, assign P a group:
   the timeline and audit log reload by themselves.

## 4. Without the nodes

1. Log in as **S** and open **P**. **Freeze** is greyed out with "Requires knk.freeze" next to it (hover shows it too).
2. **Permissions**: Assign, Save and the remove buttons are greyed out with "Requires knk.admin.user.group" /
   "Requires knk.admin.user.perm". **Economy**: Grant on the kits is greyed out with "Requires knk.kit.give"; without
   `knk.admin.currency.lock` the payment lock is greyed out with its hint.
3. **Activity**: the timeline says "Balance changes need knk.admin.currency.history." when S lacks that node, and shows
   only audit entries.

## 5. Player search (Moderation → All players)

1. Copy P's UUID, remove the dashes, paste it in the search box: under the box "Searching by UUID."; press Enter: P is
   found. The address now has `?q=…`.
2. Click the **Coins** header: sorted by coins ascending, again: descending (the arrow shows it). **Username** and
   **Email** sort too. The address has `sort=coins&dir=desc`. Go to page 2.
3. Open a player, then the browser's **Back**: the same search, sort and page come back.
4. Above the search, **Recently opened:** lists the profiles you opened last (newest first, links). **Clear** empties
   it. Log in as another account in the same browser: that account has its own list.
5. The new **Last seen** column shows "Now" for online players.

## Findings

_Fill in while testing: step, what happened, expected._
