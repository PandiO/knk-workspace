# Location retention — smoke test

**Status:** Passed 2026-10-09 (developer, dev server + web app), after the fixes for findings F1-F3 — [KNG-80](https://linear.app/kngpandi/issue/KNG-80)
**Last updated:** 2026-10-09 (first run and re-test)
**Design:** [architecture/location-retention.md](../architecture/location-retention.md)

Run this after changing the orphan check, the review panel, the digest or `/knk location`. Use a **non-op** alt for the
permission steps: ops pass every in-game check.

## 0. Setup

1. Deploy knk-web-api (`dotnet ef database update`, start), knk-web-app and the plugin (`./gradlew :knk-paper:dev`, restart).
   Expected: `locations.CreatedAt` (NULL on old rows); tables `location_orphans`, `location_retention_runs`,
   `location_retention_settings`; groups **Moderator** (50) and **Admin** (100) with their grants.
2. `/knk user <you> group add Admin`, `/knk user <alt> group add Moderator`.

## 1. Scheduler

3. About a minute after the API starts: `Location retention scheduler started: Weekly Sunday at 04:00 (<zone>), next run …,
   last run …`. When a slot is due (first deployment: last Sunday's), also `running the scheduled check for slot …` and
   `Location retention run N (scheduled): scanned …, orphans …`. Each slot runs once; a restart with nothing due only
   logs the startup line.

## 2. Web panel (Player moderation → Orphaned Locations)

4. Header: schedule, next run, last run with counts; "What counts as in use" lists the FKs.
5. Open list: only unnamed, unused Locations; nothing used by a town, gate, door, siege or game-settings spawn.
6. Schedule → grace period 0 → save. Create an unused Location named `Location`
   (`POST /api/Locations` `{"name":"Location","world":"<world>","x":100,"y":80,"z":100,"yaw":0,"pitch":0}`), **Run check now**:
   it appears Open, the run shows "1 new", online Admins get the digest. Run again: "0 new", no duplicate, no digest.

## 3. Teleport info

7. Two click-to-copy commands: `/knk location tp <id>` and `/tp <x> <y> <z> <world> <yaw> <pitch>` (KNK staff `/tp`,
   world-aware, no API lookup). "Copied" on click; over plain HTTP a selected field instead. Both teleport you, from any
   world.

## 4. Keep, re-flag, delete

8. Keep with a note: FeedbackModal, then under Kept with name, time, note. Run again: stays Kept.
9. Change the kept Location's X, run: Open again with "Kept before by … — note", digest again.
10. Delete with a note: red FeedbackModal, "Location N deleted.", under Deleted; `GET /api/Locations/N` → 404.
11. Flag one, rename it, Delete: "Not deleted: It has a custom name now …", item Resolved, Location kept.

## 5. In game

12. `/knk location here` unchanged. `/knk location orphans`: list with `[tp]` and "(kept before by …)".
13. `[tp]` teleports (audit entry in Recent Activity); silent while vanished; frozen / in a siege: guard message.
14. `/knk location tp 999999`: "doesn't exist". With all staff offline, flag a new one, join as Admin: digest once on join.

## 6. Permissions

15. Moderator (web): Keep and Teleport info, no Delete / Run check now / Schedule; direct delete call → 403.
16. Moderator (game): `/knk location ` + Tab offers `tp`, `orphans`; orphans and tp work; gets the digest.
17. Plain player: `/knk ` + Tab and `/knk help` don't list `location`; `/knk location tp 1` → no permission; panel →
    "Staff only"; no digest. Anonymous `GET /api/location-retention/orphans` → 401.
18. Set the grace period back to 7.

## Results

### 2026-10-09 — first run (developer)

All steps passed except:

| # | Finding | Fix |
|---|---|---|
| F1 | No scheduler log visible after a restart | Expected (one run per slot), but nothing showed the scheduler was alive: it now logs the schedule at startup and each scheduled check (knk-web-api `8ca9d9c`) |
| F2 | `/execute in minecraft:world_knk-dev …` → "unknown dimension" | Paper calls the main world `minecraft:overworld` whatever its folder is named, and the web app can't tell which world is the main one. Replaced by the KNK `/tp x y z <world> yaw pitch` (knk-web-app `6edf111`) |
| F3 | A player without nodes got `/knk location` tab suggestions | Regression from registering `/knk location` without a top-level node; it is now listed only to holders of one of its nodes, and completes only the actions they hold (knk-plugin `98b06f0`). The same leak in other `/knk` subcommands: [KNG-107](https://linear.app/kngpandi/issue/KNG-107) |

### 2026-10-09 — re-test (developer)

F1-F3 confirmed fixed; accepted for merge.
