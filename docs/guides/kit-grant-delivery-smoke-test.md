# Kit "Grant" from the web app reaches the player in game (#261) — smoke test

**Status:** Ready for the developer's run; API part on `master` since 2026-11-12, plugin part merged into `next` 2026-11-13 from `claude/plugin-chains-into-next` (knk-plugin `next` `745fcf6`); not deployed; 7 of 14 steps automated in CI (tagged, 6 of them partly: the delivery rules are knk-plugin unit tests, the hand-over to a real player waits for simulated players, [#540](https://github.com/PandiO/knk-workspace/issues/540)); every step can still be run by hand; manual steps not run
**Last updated:** 2026-11-15 (every step in full again, covered steps tagged `[automated: …]` or `[partly automated: …]`, developer decision 2026-11-15, #511); 2026-11-14 (steps marked `[automated]` where a knk-plugin or API test covers them, plugin backfill [#511](https://github.com/PandiO/knk-workspace/issues/511)); 2026-11-13 (setup: builds from `master` and `claude/plugin-chains-into-next`); 2026-11-08 (written with the fix)
**Issue:** [PandiO/knk-workspace#261](https://github.com/PandiO/knk-workspace/issues/261); design
[specs/kits/DESIGN.md](../specs/kits/DESIGN.md) §4.6, §4.7
**Chain:** [UX_CHAIN_3.md](../ai-agents/handoffs/UX_CHAIN_3.md) link P1; report
[2026-11-08-ux-chain-3.md](../reports/2026-11-08-ux-chain-3.md).

Record each step in **Findings** at the end (works / doesn't / accepted). About 20 minutes for a full manual run;
the tags save little here, since the player's part of every tagged step is still by hand.

Steps tagged `[automated: …]` or `[partly automated: …; by hand: …]` run in CI (knk-plugin `KitGrantDeliveryTest`,
`KitGrantFlowTest`; the API's xUnit tests). What is left by hand needs a player in game: items landing in a real inventory, the chat line, a join and a siege.
These are no plugin scenario yet, because scenarios have no players ([#540](https://github.com/PandiO/knk-workspace/issues/540)).

## What changed

"Grant" on the player profile (`POST api/Kits/{id}/give` from a logged-in web user) now writes the claim as a
**pending delivery** (`kit_claims.DeliveryRequestedAt`) and queues a `KitDeliveryPending` player notification. The
plugin hands the items over with the same placement as `/kit give` (`KitGrantPlacer`):

- **online** — within a second over the realtime hub, or within one notification poll (2 s) with `realtime.enabled`
  off;
- **offline** — about 5 s after their next join (read from the claim rows, no notification needed);
- **in a siege** — held back, handed over after the siege gave the player's own inventory back.

The plugin takes each delivery at the API (`POST api/Kits/deliveries/{claimId}/delivered`, one conditional update)
**before** it places the items, so a grant is handed over at most once, whatever races (push, poll, join, two
servers). `/kit give` in game is unchanged: it places the items itself and leaves nothing pending.

## 0. Setup

1. API: knk-web-api `main` (the API part, migration `AddKitClaimDelivery`, merged 2026-11-12) or `next`. Plugin:
   knk-plugin `claude/plugin-chains-into-next`, or `next` once it is merged. The web app is unchanged: use `main`.
2. API: `dotnet ef database update` (one additive migration, `AddKitClaimDelivery`: two nullable `datetime` columns on
   `kit_claims`), then `dotnet run`.
3. Plugin: `./gradlew :knk-paper:dev`, restart the dev server. No new config keys.
4. Web app: `npm start`. You need a staff account with `knk.kit.give` and a player **A** with a linked Minecraft
   account; a kit **K** with a helmet and a few slot items (any existing kit works).
5. SQL, to watch the rows:
   `SELECT Id, KitId, UserId, ClaimedAt, DeliveryRequestedAt, DeliveredAt FROM kit_claims ORDER BY Id DESC LIMIT 5;`

## 1. Online player, realtime on (`realtime.enabled: true`)

1. A is online. Web: `/admin/users/<A>` → Kits → **Grant** on K.
2. [partly automated: knk-plugin `KitGrantDeliveryTest` (the delivery rules for an online player: each pending kit is taken at the API before its items are placed, a delivery taken elsewhere is never placed again, a failed take places nothing and goes on with the next, items that can't be resolved stay pending: `anOnlinePlayerGetsEachPendingKit_AfterItWasTaken`, `aDeliveryTakenElsewhere_IsNeverPlacedAgain`, `aFailedTake_PlacesNothing_AndGoesOnWithTheNextOne`, `itemsThatCantBeResolved_AreNotTaken_SoTheyStayPending`); by hand: a real player and inventory, the chat line (simulated players, [#540](https://github.com/PandiO/knk-workspace/issues/540))] In game, within about a second: A gets K's items (helmet on, slot items in their slots, the rest merged or
   displaced as with `/kit give`) and the chat line *A staff member gave you the "K" kit.*
3. SQL: the new row has `DeliveryRequestedAt` and `DeliveredAt` set. Server log: `Kit claim <id> ("K") delivered to A`.
4. The profile's "Recent activity" shows the `KitGranted` entry as before.

## 2. Online player, realtime off

1. Set `realtime.enabled: false`, restart the server. Repeat step 1.1.
2. A gets the items within about 2 s (the notification poll). SQL as in 1.3.

## 3. Offline player

1. [partly automated: knk-plugin `KitGrantDeliveryTest` (`aPlayerWhoLeftBeforeTheTake_KeepsTheDeliveryPending`, `aPlayerWithoutACachedAccount_IsSkipped`: the delivery stays pending for the next join); by hand: the logout and the two grants from the web] A logs out. Grant K twice from the web (two rows with `DeliveredAt` NULL).
2. A joins. About 5 s later both kits arrive, one chat line each, in the order granted. SQL: both rows delivered.
3. A logs out and in again: nothing more arrives (no second hand-over).

## 4. Never twice

1. [partly automated: knk-plugin `KitGrantDeliveryTest` (`aCallDuringARun_RunsOnceMoreAfterIt_NeverTwiceAtOnce`: calls never run twice at once); by hand: the reload, restart or API stop race] With A online, grant K, then right away `/reload confirm` or restart the server before the items arrive (or stop the
   API between the grant and the delivery and start it again). Whatever happens, A ends up with **one** copy of K's
   items per grant, never two. SQL: `DeliveredAt` set once.
2. [automated: knk-web-api `Tests/knkwebapi_v2.Tests/Services/KitGrantDeliveryTests.cs` (`MarkDelivered_TakenBefore_IsAlreadyDelivered`, `MarkDelivered_NothingToTake_IsNotFound`, `Controller_MarkDelivered_MapsTheOutcome`: 409 `AlreadyDelivered`, 404)] Optional, two terminals: `curl -X POST -H "X-API-Key: <key>" "<api>/api/Kits/deliveries/<claimId>/delivered?userId=<A>"`
   on an already delivered claim → `409 {"code":"AlreadyDelivered"}`; on an unknown one → `404`.

## 5. In a siege

1. [partly automated: knk-plugin `KitGrantDeliveryTest` (`inASiege_NothingIsReadOrTaken`); by hand: a real siege (#540)] A joins a siege lobby and waits in the hub (or plays a match). Grant K from the web: nothing arrives during the
   siege (SQL: `DeliveredAt` stays NULL).
2. [partly automated: knk-plugin `KitGrantDeliveryTest` (`aSiegeEnteredWhileTheTakeIsInFlight_KeepsTheKit_AndPlacesItAfterTheSiege`: a kit taken while the player entered a siege is kept and placed after it); by hand: a real siege ending (#540)] The siege ends and gives A's own inventory back: about a second later K arrives.

## 6. In game `/kit give` is unchanged

1. [partly automated: knk-plugin `KitGrantFlowTest` (`giveNamesTheSenderAsTheActor`, `successfulClaimPlacesAndConfirms`); by hand: the command run by a staff player (#540)] Staff in game: `/kit give A K`. A gets the items once, as before; SQL: the new row has `DeliveryRequestedAt` NULL (no
   pending delivery, nothing arrives a second time on the next join).

## Known limits (flags LP1-k in the report)

- A delivery is taken before its items are placed: a server crash in that instant, or A logging out in the same
  instant, loses that one hand-over (the log says which claim; grant it again). Same as any item placed right before
  a crash.
- The web app still says only "granted"; it doesn't say "Delivered in game" or "will be delivered on the next join"
  (the response now carries `deliveryPending: true` and `claimId` for that follow-up).
- A grant still starts the kit's cooldown for the player's own `/kit get`, as it did before.

## Findings

| Step | Result | Note |
|---|---|---|
| 1 | | |
| 2 | | |
| 3 | | |
| 4 | | |
| 5 | | |
| 6 | | |
