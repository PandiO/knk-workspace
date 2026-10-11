# Location retention — orphan detection, review panel, digest and teleport-to

**Status:** Implemented, **live-tested by the developer and merged to trunk 2026-10-09** (knk-web-api `master` `c397585`, knk-web-app `main` `d10e3dd`, knk-plugin `main` `68a5310`) — Linear [KNG-80](https://linear.app/kngpandi/issue/KNG-80); [smoke test](../guides/location-retention-smoke-test.md)
**Last updated:** 2026-10-09 (merged; smoke-test findings F1-F3: startup log, KNK `/tp` coordinate command, `/knk location` listing)
**Related:** [KNG-21](https://linear.app/kngpandi/issue/KNG-21) currency alerts (the pattern reused here), [KNG-17](https://linear.app/kngpandi/issue/KNG-17) teleport engine, [KNG-43](https://linear.app/kngpandi/issue/KNG-43) unfinished FormSubmission cleanup, [KNG-62](https://linear.app/kngpandi/issue/KNG-62) group nodes in the web app

## 1. What this is

`Location` rows pile up: a form or world task often saves a Location before the entity that uses it, and an abandoned
form leaves it behind. A scheduled check **flags** orphaned Locations; staff review each one in the web app and
**keep** or **delete** it. **Nothing is ever deleted automatically.**

## 2. Orphan definition

A Location is an orphan when all of these hold:

1. **Default name:** `Name` is the literal `Location`, null, or empty/whitespace (developer decision 2026-10-09).
   `Location` is what every creation path writes: `Location.Name`'s initializer (knk-web-api `Models/Location.cs`),
   the web app's location form default (`objectConfigs.tsx`) and world-task capture (`WorldBoundFieldRenderer.tsx`,
   the plugin's `LocationTaskHandler.resolveLocationName`). On MySQL the comparison follows the column collation, so
   `location` also counts as default.
2. **No foreign key references it**, derived from the **EF Core model metadata**
   (`Services/LocationRetention/LocationReferenceGraph.cs`): every FK whose principal is `Location`, declared on any
   entity type, including shared-type join entities of many-to-many skip navigations. As of 2026-10-09:
   `Domain.LocationId` (Town/District/Structure/GateStructure), the eight `GateDoor` point FKs,
   `SiegeScenario.HubLocationId`, `SiegeSpawnpoint.LocationId`, `SiegeObjective.LocationId` and the
   `gate_structure_guard_spawn_locations` join table. A new `LocationId` is covered the moment it is mapped;
   `LocationReferenceGraphTests` fails if any FK in the model (or a probe FK of each shape) is not honoured.
3. **No JSON/config reference names it** (`ILocationReferenceSource`):
   - Game settings: join spawn, default respawn, per-world spawn/respawn (`LocationReferenceDto` JSON with
     `sourceType: "Location"` + `sourceId`, or a snapshot `locationId`).
   - Unfinished FormWizard drafts (`FormSubmissionProgress` with status InProgress/Paused): any `…Location…` property
     holding an id or an object with an id.
4. **Older than the grace period** (default 7 days). `locations.CreatedAt` was added for this; rows that existed before
   the column have `NULL`, which counts as old.

The query is one set-based statement per batch: `NOT EXISTS` anti-joins built from the metadata, keyset batches of
500, read only.

**Does the plugin create Locations outside the web API?** No (checked 2026-10-09 on knk-plugin `main` `f9026cb`): the
api-client only reads Locations (`LocationsQueryApiImpl`: search and get), and world-task capture hands coordinates to
the web app, which creates the row. The grace period assumption holds.

## 3. Schedule and runs

- Default **weekly, Sunday 04:00 server time** (the API host's time zone, or `LocationRetention:TimeZoneId`), daily
  also possible, editable in the web panel. A slot missed while the API was down runs when it is back; the first
  deployment therefore runs shortly after startup (covering the latest Sunday slot).
- **Run check now** in the web panel (knk.admin.location.orphans.run). One run at a time.
- Every run is logged in `location_retention_runs`: trigger, who, start/end, candidates scanned, orphans found,
  new / already known / re-flagged / resolved, duration, error, digest time.
- The API log shows `Location retention scheduler started: <schedule>, next run …, last run …` once at startup, and
  `running the scheduled check for slot …` plus the run summary whenever a scheduled run happens. A restart with no
  slot due logs only the startup line (each slot runs once).

## 4. Review items and states

`location_orphans` holds one row per flagging, with a **snapshot** (world, x/y/z, yaw/pitch, name, the Location's
`CreatedAt`). The creator is not known: Locations have no creator column.

| State | Meaning |
|---|---|
| Open | Flagged, waiting for staff |
| Kept | Staff kept it (who, when, optional note). Not flagged again for **6 months** (configurable), or earlier when the Location's name, world or position differs from the snapshot. A re-flag opens a new item that shows the earlier Keep decision. |
| Deleted | Staff deleted it (who, when, note). The Location row is gone; this item, with its snapshot, is the audit record. |
| Resolved | It stopped being an orphan by itself (got a name or a relation, or was deleted elsewhere), or a delete was refused by the re-check. The reason is stored. |

**Delete** locks the Location row (`SELECT … FOR UPDATE`), re-checks every condition inside the same transaction and
either deletes the Location (item Deleted) or refuses (item Resolved, HTTP 409). Per item only; no bulk delete.

**Audit:** the user-management audit log (`AuditLogEntry`) requires a target player, which a Location delete does not
have, so the review item itself is the audit record, plus a warning-level log line. Mirroring it into the audit log
needs a non-player target there first.

## 5. Notifications

One `LocationOrphanDigest` player notification per run, **only when the run found something new** (new orphans or
re-flagged Kept items), through the same in-memory queue and `PlayerNotificationPoller` as the currency alerts. The
plugin's `LocationOrphanNotifier` sends one clickable line (runs `/knk location orphans`) to every online holder of
knk.admin.location.orphans.notify. When no holder is online, it keeps the latest digest and shows it to the next
holder who joins (lost on a plugin restart or after the API queue's 24 h; the items stay in the panel either way).

## 6. Surfaces

**knk-web-api** `api/location-retention`, each route with an explicit permission check (no anonymous access):

| Route | Check |
|---|---|
| `GET orphans?status=open\|kept\|deleted\|resolved\|all&page&pageSize` | RequireServiceOrPermission `knk.admin.location.orphans` |
| `POST orphans/{id}/keep` `{note}` | RequirePermission `knk.admin.location.orphans.keep` |
| `POST orphans/{id}/delete` `{note}` | RequirePermission `knk.admin.location.orphans.delete` |
| `GET status` (settings, last/next run, relations) | RequirePermission `knk.admin.location.orphans` |
| `POST run` | RequirePermission `knk.admin.location.orphans.run` |
| `PUT settings` | RequirePermission `knk.admin.location.retention` |
| `GET locations/{id}/teleport-target` | RequireServiceOrPermission `knk.admin.location.tp` |

**knk-web-app** Staff → Player moderation → **Orphaned Locations** (`/admin/locations/orphans`): status filter,
server-side paging, snapshot, earlier Keep decision, Keep/Delete with a note confirmed through `FeedbackModal`, teleport
commands with click-to-copy (`/knk location tp <id>`, and the KNK staff `/tp <x> <y> <z> <world> <yaw> <pitch>`, which is
world-aware and needs no API lookup) and a select-to-copy field when the Clipboard API is unavailable, the last run, the
schedule and Run check now. A vanilla `/execute in <dimension>` was dropped (smoke test F2): Paper calls the main world
`minecraft:overworld` whatever its folder is named, and the web app can't tell which world that is.

**knk-plugin** `/knk location here | tp <id> | orphans [page]`, each action checking its own node in game first.
`tp` is a STAFF teleport through the KNG-17 `TeleportService` (freeze/region/siege guards, audit-logged, silent while
vanished). `/knk location` has no top-level node, so `/knk help` and tab completion list it only to holders of one of its
nodes, and complete only the actions they hold (`CommandRegistry.setVisibility`, smoke test F3); the same for the other
`/knk` subcommands is [KNG-107](https://linear.app/kngpandi/issue/KNG-107).

## 7. Permission nodes

| Node | Grants |
|---|---|
| `knk.admin.location.orphans` | See the list, runs and settings (web, `/knk location orphans`) |
| `knk.admin.location.orphans.notify` | The in-game digest |
| `knk.admin.location.orphans.keep` | Keep |
| `knk.admin.location.orphans.delete` | Delete (higher privilege, separate on purpose) |
| `knk.admin.location.orphans.run` | Run check now |
| `knk.admin.location.retention` | Change schedule, grace period, Keep recheck period |
| `knk.admin.location.tp` | `/knk location tp`, and the teleport commands in the web panel |

All are children of `knk.admin` in plugin.yml, so ops and holders of `knk.admin.*` / `*` get them.

**Seeded staff groups** (migration `SeedLocationRetentionStaffGroups`, developer decision 2026-10-09): trunk had no
staff groups, so the migration creates **Moderator** (weight 50) and **Admin** (weight 100), above the premium tiers
(10–30), when no group of that name exists, and reuses an existing one otherwise. Moderator gets orphans, notify,
keep and tp; Admin gets all seven. Group nodes stay seed-only until KNG-62.

## 8. What was reused from the currency alerts (KNG-21 Phase 5)

Decision: **a separate review-item entity, not a new alert type and not an extracted shared base.**
`currency_alerts` is ledger-specific (rule codes R1–R9, transaction and user columns, the R1 kill switch) and only
knows acknowledged/not; review items need Open/Kept/Deleted/Resolved, a snapshot, a note and re-flagging. Extracting a
shared base would mean migrating live, live-tested ledger data for one second consumer. Reused as is: the player
notification queue and poller (new type), `RequirePermission`/`RequireServiceOrPermission` and the `StaffPermissions`
node layout, the `BackgroundService` + `PeriodicTimer` + scope-per-step scheduler shape, the one-run-at-a-time gate,
the web page layout and paging, and the in-game notifier shape (`CurrencyAlertNotifier`). Worth extracting once a
third alert-like feature appears.

## 9. Open items

1. Members for the new Moderator/Admin groups are assigned by hand (the migration adds no one).
2. Unmerged branches with their own migrations (e.g. KNG-66) need their model snapshot rebased on `master` now that
   `AddLocationRetention` and `SeedLocationRetentionStaffGroups` are merged.
3. Hide nodeless `/knk` subcommands from players without their nodes everywhere: [KNG-107](https://linear.app/kngpandi/issue/KNG-107).
4. Mirror deletes into the user audit log once it supports non-player targets (§4).
