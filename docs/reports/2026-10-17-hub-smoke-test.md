# Hub smoke test and fixes
**Status:** Complete. Three runs; every finding fixed and confirmed live. Hub PRs not merged yet.
**Date:** 2026-10-17
**Issue:** [KNG-109](https://linear.app/kngpandi/issue/KNG-109) (KNG-113/114/116/118); hub [DESIGN §16](../specs/hub/DESIGN.md) on `claude/blissful-fermat-b7ihrz`
**Tested:** `claude/blissful-fermat-b7ihrz` in knk-plugin (`73024c7f`), knk-web-api (`f090cbc`), knk-web-app (`3b587fe`)
**Fixes:** `claude/fervent-ride-b536j6`, which is that branch plus one commit: knk-plugin `2d963e65`, knk-web-app `732e5cc`. No API change.

The steps follow the checklist in the [hub overnight handoff](../ai-agents/handoffs/2026-10-12-hub-overnight-session.md) on the hub branch, with the exemption boxes left out.

## Results

| Step | Result | Follow-up |
|---|---|---|
| A. No hub selected, Game Settings page | Pass | — |
| B. Flag, nested refusal, select, spawn list per world | Pass | B6: unflagging the selected hub was refused **without feedback**. Fixed (web app). |
| C. Joins: no group spawn, group spawn, logout spot, owner, staff mode (API up and down) | Pass | — |
| D. Hub rules: damage, building, storage, frames, drop/pickup, void, outside, bypass, Peaceful preset | Pass, except doors | D12: **doors, gates and trapdoors could not be opened** by a non-op although allowed. Fixed (plugin). A crafting table can be used: it is not storage, so the hub allows it by design. |
| E. Portal | Pass (API up) | API-down portal step in progress (5 min delay). |
| F. Fail closed | Pass | — |
| G21. Send to hub, `/spawn` refused | Pass | `/spawn` is also refused with the API up: "You are not allowed to leave Kardenna." This is the hub town's AllowExit, see below. |
| G22. Return offer | Pass | The hover **showed the world name and coordinates**. Removed (plugin). |
| G23. Leaving ends the offer | Pass | — |
| G24.1 Delay timing | Slower than set | A 30 s delay acted after 40-60 s. Cause and fix below. |
| G24.2 Timer across a server restart | In progress | — |
| G25. Kick | Pass | A group delay of 0 s kicked after 24 s. Same cause as G24.1. |
| G26-G28, H29-H31 | Pass | — |

## Causes and fixes

**D12 (doors).** WorldGuard, not the hub rules. The hub district sits inside a Town region. For non-members, WorldGuard falls back to region membership for doors (`use`) and storage (`chest-access`), so it refuses them unless the flag allows them. The seeded empty `deny-message` made the refusal silent. The new `HubWorldGuardListener` handles uses that the hub's rules allow: doors by default, and storage, NPCs and item frames when switched on. It marks the player's WorldGuard `UseBlockEvent`/`UseEntityEvent` as allowed at LOW priority. WorldGuard 7.0.10's region check runs at NORMAL and skips an allowed event. Refusals by other plugins (freeze, Siege) still apply, and the uses the hub refuses stay with `HubRulesListener`.

**G24.1 / G25 (delay).** `/knk health` probes the API directly, so it sees the loss at once. The outage clock started at the KNG-115 DOWN transition, which needs 3 failed probes 10 s apart (20-30 s). A DOWN transition now carries its first failed probe, and a new outage's timer starts there. A delay now counts from the loss of the API. Even a 0 s delay still waits for the DOWN to be confirmed (20-30 s with `failures-to-down: 3`, `probe-interval-seconds: 10`). The web app's delay hint says so.

**B6, G22.** The selected hub's remove button now explains to select another hub and save first. The return offer's hover says "Back to your spot from before the outage". The invalidation message no longer names the world.

## Open for the developer
1. **`/spawn` from the hub (G21).** Design decision 8 leaves `/spawn` unchanged, so the hub domain's AllowExit, and its Town's, decides it. The portal carries an exit pass, so exit deny means portal-only.
   - Recommendation: keep portal-only (exit deny). The portal checks the API, the account and the destination, and uses the group join spawn.
   - Making Kardenna the hub instead of Royal Palace changes where the hub rules and the outage "in the hub" check apply, not whether `/spawn` works.
   - If all of Kardenna is the hub area, select Kardenna. Today the town outside the palace has gameplay rules and is acted on in an outage.
2. **E (portal during an outage).** The portal refuses gameplay entry from the moment the outage is confirmed, whatever the delay (§13). The delay only postpones the action for players already in the game.

## Verified
- **Plugin:** core 2059, api-client 258, paper 1658, 0 failures. New tests cover the allowed-use rules, the backdated outage start and the first-failure transition.
- **Web app:** `tsc` clean; Game Settings tests 32/32.
- **Live retest needed:** D12 (doors as a non-op, chests still closed), G24.1/G25 timing, B6 message, G22 hover.

## Retest (run 2, same day)
On the hub branch fast-forwarded to `2d963e65` / `732e5cc`.

| Step | Result |
|---|---|
| R1 doors in the hub | Pass |
| R2 return offer hover | Pass, but two new findings, below |
| R3 unflag message | Pass |
| R4 30 s delay timing | Accepted |
| R5 0 s group delay | Accepted (seconds-level accuracy not needed) |
| E portal while the API is down | Covered by the developer's run, no finding |
| G24.2 timer across a restart | Pass |
| G21 `/spawn` from the hub | Decision: **portal only**. Hub-specific refusal text requested. |

**Findings and fixes** (knk-plugin `4a9bc44f` on `claude/fervent-ride-b536j6`; hub branch not moved yet):
- **An earlier outage's offer came back.** It reached players who were in the hub when the API went out, together with its "you left the hub" expiry message. They had stayed in the hub without using the offer of an earlier outage, and the record was kept for them. A new outage now ends the earlier offer of every online player in the hub. Offline players keep theirs, because they may not have seen it.
- **An unsafe spot blocked the return.** The return now looks for the nearest safe place within 5 blocks (it used to look within 1). If there is none, it uses the spawn of the structure, district or town the spot is in, innermost first. Without either, the offer is kept as before.
- **Hub exit wording.** A refusal to leave while standing in the hub now says "You can only leave the hub through its portal." This covers `/spawn`, `/warp`, and walking out of an exit-denied hub or its parent town. Without portals it says "You can't leave the hub this way."

Plugin tests: core 2059, api-client 258, paper 1661, 0 failures. Live retest pending.

## Retest (run 3, same day)
On the hub branch at knk-plugin `14930e9d` (the run 2 fixes plus the merge of `main`).

| Step | Result |
|---|---|
| 1. An earlier offer ends at a new outage (player stayed in the hub) | Pass |
| 2. An offline player keeps the offer and gets it on rejoin | Pass |
| 3. An unsafe spot: return to a safe place within 5 blocks | Pass |
| 4. An unsafe spot in a town/district: return to its spawn | Pass |
| 5. An unsafe spot outside any domain: the offer is kept | Pass |
| 6. `/spawn` and `/warp` from the hub: "You can only leave the hub through its portal." | Pass |

All findings from runs 1-3 are fixed and confirmed live. The hub PRs are ready for review, in merge order: knk-web-api #8, knk-web-app #6, knk-plugin #11 (hub branch at `14930e9d`; web app at `732e5cc`).

## Remaining live checks: accepted without a run
After the merge, the developer was given steps for the audit's live checks that had not been run. Siege was left out. The developer **accepted all of them without running them** (2026-10-17). They are recorded as accepted, not as tested.

| Section | Check |
|---|---|
| A | The same region ids at the same XYZ in both worlds: per-world AllowEntry, teleports between the copies, `/rg info -w`, `/knk regions repair`, a restart |
| B | Gates in both worlds: only the addressed gate animates, `/gate info here` picks the local gate, both at once, a restart |
| C | The portal during an outage: inside the 20-30 s detection window, after confirmation, a flapping API, recovery |
| D | The Do nothing and Send to world spawn outage actions (runs 1-3 tested only Send to hub and Kick) |
| E | A return offer refused because the spot's district now denies entry |
| F | A missing hub world with `create: false`: non-ops refused, ops allowed. The unload guard is covered by unit tests only. |
| Optional | A hub in the same world as the game |

Siege (a match during an outage, [KNG-117](https://linear.app/kngpandi/issue/KNG-117)) was also accepted without a run on 2026-10-17. The developer will test it live later.
