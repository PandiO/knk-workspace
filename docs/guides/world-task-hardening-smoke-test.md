# World-task hardening and tasks anchored to the draft (#180) — smoke test

**Status:** Run by the developer 2026-11-04 on the `claude/realtime-signalr` builds (which contain this branch): all
steps work or accepted. Merged into the default branches 2026-11-04 (with the realtime branch)
**Last updated:** 2026-11-09 (§7 temp regions of abandoned drafts, PandiO/knk-workspace#269, feature branch
`claude/temp-region-drafts-269`, not merged, not run yet); 2026-11-04 (findings of the developer's run; merged)
**Issue:** [PandiO/knk-workspace#180](https://github.com/PandiO/knk-workspace/issues/180) (WT1 of #66); design
[realtime-signalr/DESIGN.md](../specs/realtime-signalr/DESIGN.md) §8.2, §8.7; reference
[specs/world-tasks/README.md § Lifecycle](../specs/world-tasks/README.md#lifecycle-and-endpoints-pandioknk-workspace180)
**Chain:** [UX_REALTIME_CHAIN.md](../ai-agents/handoffs/UX_REALTIME_CHAIN.md) link 7; report
[2026-10-26-ux-realtime-chain.md](../reports/2026-10-26-ux-realtime-chain.md).

Record each step in **Findings** at the end (works / doesn't / accepted).

## 0. Setup

1. Check out `claude/world-task-hardening` in all three component repos. **API, plugin and web app go together**: the
   API now refuses a headless scan that wasn't claimed first and a claim/complete from the web, which the old plugin
   relies on.
2. API: `dotnet ef database update` (one additive migration, `AddWorldTaskHardening`), then `dotnet run`. To test expiry
   without waiting 30 minutes, start it with `WorldTasks__PendingTtlMinutes=2` (all `WorldTasks` settings are optional;
   defaults: Pending 30 min, lease 3 min, sweep every 30 s, abandoned sessions after 7 days).
3. Plugin: `./gradlew :knk-paper:dev`, restart the dev server. Optional in `config.yml`:
   `world-tasks.heartbeat-interval-seconds` (60) and `realtime.server-id` (`localhost`; the realtime branch adds the block).
4. Web app: `npm start`. You need an admin with `knk.admin.content` + `knk.admin.world`, a linked Minecraft account
   with `knk.tasks` (player A) and a second player B with `knk.tasks` but **not** op (ops get `knk.tasks.any` by default).
5. Keep a SQL client open:
   `SELECT Id, FieldName, TaskType, Status, LinkCode, ClaimedByMinecraftUsername, ClaimedByServerId, ClaimedByUuid, ExpiresAt, LeaseUntil, ReleaseCount, FormSubmissionProgressId, AppliedAt, ErrorMessage FROM world_tasks ORDER BY Id DESC LIMIT 8;`
   `SELECT Id, Status, WorkflowSessionId, UpdatedAt FROM FormSubmissionProgresses ORDER BY Id DESC LIMIT 5;`

## 1. Task code and claim

1. New Town → step with Location → **Send to Minecraft**. The card says **Task code**, the command is `/knk task <code>`,
   and it says when the code expires. SQL: `ExpiresAt` = now + 30 min, `CreatedByUserId` = the admin.
2. In game (A): `/knk task <code in lower case>` → claimed, the Location prompts appear; `cancel`/`discard` are
   explained. Web: "Claimed by A on localhost" (server and player are stored now; SQL `ClaimedByUuid` set).
3. B: `/knk task <same code>` → "Task is not available (status: InProgress)". B: `/knk task-claim <code>` (alias) same.
4. B: `/knk task <task id>` → refused ("Claim tasks with their task code…", needs `knk.tasks.any`). An op can claim by id.
5. A: type `save` → web fills the field, "Task completed". The code no longer finds anything:
   `/knk task <code>` → "No open task has this task code".

## 2. Handing back, discarding, quitting, restarts

1. New task, A claims it, types `cancel` → in game "handed back; its task code works again". Web: the code card is back
   with "handed back in game". SQL: Pending, `ReleaseCount` 1, claim columns empty, new `ExpiresAt`. B can claim it now.
2. B types `discard` → web shows **Task cancelled** with **Start again**; SQL Cancelled.
3. New task, A claims, A quits the game → web shows the code again (Pending).
4. New task, A claims, **stop** the server normally → Pending again at once (released on disable).
5. New task, A claims, **kill** the server process (no clean stop), start it again → released at startup (log
   "Handed back 1 world task(s)…"); if the API wasn't reachable then, the sweep releases it 3 minutes after the last
   heartbeat.
6. While a task is claimed and alive, wait 4 minutes: still InProgress (heartbeat every 60 s renews `LeaseUntil`).

## 3. Cancel from the web, expiry

1. A claims a Region task (Town → WgRegionId), selects and doesn't save. Web: **Cancel task** → web shows Task cancelled.
   Within a minute in game: "Task <id> was cancelled in the web app.", the selection/WorldEdit session ends. If A typed
   `save` meanwhile: the API refuses the completion, the temp region is removed.
2. A Pending task, **Cancel task** on the code card → cancelled; the code stops working.
3. With `WorldTasks__PendingTtlMinutes=2`: create a task, don't claim it, wait ~2.5 min → **Task expired** with
   **Start again**; polling stops (network tab quiet); `/knk task <code>` → no open task.
4. **Start again** → the Send to Minecraft button is back; a new task gets a new code.

## 4. Tasks anchored to the draft

1. New form (no Save Draft yet) → **Send to Minecraft**: a draft appears (Saved Progress / SQL, status InProgress,
   `WorkflowSessionId` set), no message pops up; the task row has `FormSubmissionProgressId`.
2. Go to the next step and back: the field still shows the same task (code or claim).
3. Reload the tab, open the draft from Saved Progress: same workflow session (network: no new `POST api/Workflows`),
   the field shows the same task code.
4. Close the tab with the task Pending; A claims and completes it in game; open the draft again → the field is filled
   ("Task completed"), the draft is saved with the value and SQL `AppliedAt` is set. Reload again → no second apply.
5. **Capture again** after a result, then Send again → the previous field task is not reused; with an open task,
   Send again (after Start again) cancels the old one (SQL: "Replaced by task #n").
6. With an open task, leave the form (Cancel, a nav link → Leave form) → SQL Cancelled ("Left the form in the web
   app."). A reload does **not** cancel it (step 4.3).
7. Child form (e.g. GateStructure → New door → a door field with a Location task): same as 4.1 for the child's own
   draft; closing the child form cancels its open task.

## 5. Task types and scans

1. Form builder → a field → "Requires in-game action": the type defaults to **LocationSelection**; the list has only
   LocationSelection, ReagionCreate, RegionClaim, ItemScan, KitScan, GateBlockScan, GateOpenedBlockScan. A field that
   already has e.g. VerifyLocation shows it as "(no handler in game)" with a warning.
2. Claim a task of such a type → in game "no handler for task type 'VerifyLocation'… marked as failed"; web shows
   Task Failed with that reason and Try Again.
3. Gate door → block scan: it runs as before; SQL shows it claimed (`ClaimedByServerId`, no player) before it completes.
4. Item scan and kit scan (`/knk itemscan claim <code>`, `/knk kitscan claim <code>`) work as before; with nothing in
   hand the task goes back to Pending instead of staying InProgress.

## 6. Abandoned sessions (sweep)

1. Pick a workflow session with no draft and no Completed task, back-date it:
   `UPDATE workflow_sessions SET CreatedAt = NOW() - INTERVAL 8 DAY, UpdatedAt = NULL WHERE Id = <id>;`
   `UPDATE world_tasks SET CreatedAt = NOW() - INTERVAL 8 DAY, UpdatedAt = NULL WHERE WorkflowSessionId = <id>;`
   Within 30 s the session and its tasks are gone (API log "World task sweep: … abandoned session(s) removed").
2. The same for a session that has a draft or a Completed task: it stays.

## 7. Temp regions of abandoned drafts (#269, feature branch `claude/temp-region-drafts-269`, not merged)

About 30 minutes. What it checks: a region a form's region task drew (`tempregion_worldtask_<n>`) is removed within
minutes when its draft is deleted or its task closes without a result, never when something uses it or it was renamed,
and the 14-day cleanup is untouched. Design: [managed-worldguard-regions.md §7 "Abandoned drafts"](../architecture/managed-worldguard-regions.md#abandoned-drafts-temp-regions-released-early-pandioknk-workspace269-feature-branch-claudetemp-region-drafts-269-not-merged).

0. **Setup.** Check out `claude/temp-region-drafts-269` in knk-web-api and knk-plugin (they contain the unmerged
   `claude/dashboard-access-280`, `claude/lootbox-area-rename-34` and, on the plugin, `claude/kit-grant-delivery-261`).
   API first: `dotnet ef database update` (additive migration `AddTempRegionReleases`, one new table; the branch also
   carries the earlier links' migrations), start it with `WorldTasks__TempRegionReleaseGraceMinutes=1` so you don't
   wait 5 minutes per step. Plugin: in `config.yml` set `regions.temp-retention.release-interval-minutes: 1` (default 5),
   `./gradlew :knk-paper:dev`, restart. The server log shows "Temp regions of abandoned drafts are removed every 1
   minutes…". Keep a SQL client open:
   `SELECT Id, WorldTaskId, RegionId, World, ServerId, Reason, RequestedAt FROM temp_region_releases ORDER BY Id DESC LIMIT 8;`
   Each step: wait up to 3 minutes (1 grace + 1 pass + the first pass 2 minutes after a restart).
1. **Draft deleted.** New Town (or Lootbox spawn area), fill the Region step with "Send to Minecraft", draw a selection
   in game and `save`. `/rg info tempregion_worldtask_<n>` shows it. Save the draft and leave the form (the wizard's
   Cancel). Nothing happens: leaving keeps the draft (wait one pass; the region stays). Open Saved Progress and delete
   the draft. A row `DraftDeleted` with the task id, world and server appears; within minutes the server log says
   `Removed temp region <world>/tempregion_worldtask_<n> (its draft was deleted; no domain or lootbox area uses it)`,
   `/rg info` finds no region, and the row is gone.
2. **Renamed regions are never touched.** Draw a region in a new Lootbox spawn area form and **submit** it: the region
   becomes `lootbox_area_<id>` (R3). Delete that (completed) draft from Saved Progress if it is listed, or any draft of
   a domain you saved with a drawn region. The release is settled as missing (row gone, no "Removed" line);
   `lootbox_area_<id>` / `domain_<id>` is still there.
3. **A region another draft names is kept.** Draw a region in draft A (Town, `save` in game), note
   `tempregion_worldtask_<n>`. In draft B (another Town) run the Region step and type `select tempregion_worldtask_<n>`
   in game; save draft B. Delete draft A: the row appears and **stays** (draft B names the region), the region stays.
   Delete draft B: within minutes A's region is removed (B's own task picked an existing region, so B releases nothing).
4. **Draft deleted while the task runs.** Start a Region step, claim it in game but don't `save`. Delete the draft in
   Saved Progress: the row appears and waits (the task is InProgress). Now `save` in game (the task completes for the
   deleted draft). After the grace minute the region is removed. (Flag LP3-3: the task is not cancelled.)
5. **Cancelled from the web.** Start a Region step, claim it in game, then "Cancel task" in the web app. #180 already
   stops the handler; a `TaskCancelled` row appears and is settled within minutes (nothing drawn, so no "Removed" line).
   Cancel a task nobody claimed: no row.
6. **Unreachable checks keep the region.** Repeat step 1 but stop the API right after deleting the draft (before the
   pass). The server logs nothing removed; start the API again and the next pass removes it. With
   `release-interval-minutes: 0` and a restart, no pass runs and step 1 leaves the region (the 14-day cleanup decides).
7. **Backstop unchanged.** `/knk regions temp` lists the remaining temp regions as before (too recent / in use / …);
   the daily cleanup's log line is unchanged. Afterwards set `release-interval-minutes` back to 5 (or remove the line)
   and drop the API override.

## Findings

| Step | Result | Notes |
|---|---|---|
| 0 | Done | Developer, 2026-11-04 |
| 1 | Works | |
| 2 | Works | |
| 3 | Works | |
| 4 | Accepted | |
| 5 | Works | |
| 6 | Accepted | |
| 7.0–7.7 | not run | #269, feature branch |
