# Group chat and tab-list colours by precedence (#260) — smoke test

**Status:** Written 2026-11-05 for `claude/group-colours-260` (knk-web-api, knk-plugin); not merged, not run
**Last updated:** 2026-11-05
**Issue:** [PandiO/knk-workspace#260](https://github.com/PandiO/knk-workspace/issues/260); spec
[user-features/RANK_DISPLAY.md](../specs/user-features/RANK_DISPLAY.md) § 2

Record each step in **Findings** at the end (works / doesn't / accepted).

## 0. Setup

1. Check out `claude/group-colours-260` in knk-web-api and knk-plugin and deploy **both** (the plugin needs the API's
   new fields; no migration, no setting). Realtime on as before, so group edits show within ~2 s; with it off they
   show on rejoin.
2. People: **S** in the Staff group (holds `knk.mode.staff`, not op), **R** with a premium tier (e.g. Royal) and no
   staff node, **P** with only Default. Optional: S also holds a tier.
3. Note the current colours of the Default group, the tier and the Staff group (Permission groups → edit).

## 1. Staff group colours

1. Set the Staff group's Chat colour `&c`, Chat bracket colour `&4`, Tab-list colour `&c`; save.
   - S's tab-list name and name tag turn red.
   - S's chat line: `[STAFF]-{Title}- S: msg` with the tag, title and name red, the brackets dark red; the title stays
     bold.
   - R and P unchanged.
2. Clear the three fields again: S is back to the fixed staff look (blue tab list, the usual staff chat colours).
3. Set only the Staff group's Tab-list colour: S's name turns that colour, S's chat keeps the staff chat colours.

## 2. Tiers and Default (as before)

1. R: tab list and chat in the tier's colours, the tier name in the braces, as before #260.
2. P: the Default group's colours, as before.
3. Change the tier's Tab-list colour: R changes; P and S don't.

## 3. Precedence

1. Give S a premium tier too, Staff colours cleared: S now shows the **tier's** colours (the tier is the first group
   that sets them). Set the Staff group's colours: S shows Staff's (Staff outweighs the tier). This is the rule the
   developer chose (hierarchy, then weight); give the Staff group colours to keep staff on one look.
2. A group with a parent (e.g. Moderator → Helper): a player in Moderator gets Moderator's colours where it sets them
   and Helper's for the fields Moderator leaves empty, even when Helper has the higher weight.

## Findings

| Step | Result | Notes |
|---|---|---|
| 1 | | |
| 2 | | |
| 3 | | |
