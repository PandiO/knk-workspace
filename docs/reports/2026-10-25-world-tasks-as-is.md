# World tasks: how they work today (as-is analysis for the SignalR design)

**Status:** Report (research only, no code changed)
**Date:** 2026-10-25
**Issues:** [#66](https://github.com/PandiO/knk-workspace/issues/66) (KNG-57); read: #145 (KNG-249), #34 (KNG-246), #75, #28 (KNG-189), #57
**Code basis:** knk-web-api `master` @ `6f08383`, knk-plugin `main` @ `ee35fb1`, knk-web-app `main` @ `0d61270` (all 2026-10-25)
**Used by:** [realtime-signalr/DESIGN.md](../specs/realtime-signalr/DESIGN.md), [plan handoff](../ai-agents/handoffs/2026-10-25-ux-dashboard-signalr-plan.md)

Paths are relative to each repo root (`API:` = knk-web-api, `PLG:` = `knk-plugin/knk-paper/src/main/java/net/knightsandkings/knk/paper` unless the full path is given, `WEB:` = `knk-web-app/src`).
The specs in `docs/specs/world-tasks/` contradict the code in several places (§6 table); this report wins until they are corrected.


---

## 0. Short version

- **Nothing is pushed today.** The web app polls `GET /api/WorldTasks/{id}` every **2 s** while a task is open. The plugin polls `GET /api/WorldTasks/status/Pending`, but **only for headless tasks** (GateBlockScan, GateOpenedBlockScan, MinecraftCatalogScan): 5 s, backing off to 60 s. Player-driven tasks are never polled. They reach the game only when a player types `/knk task-claim <code>`.
- **The claim code (`WorldTask.LinkCode`)** is 6 chars from A-Z0-9, made with `System.Random`. It has **no unique index and no expiry**, is **never cleared** after a claim, and **the API never checks it on claim**. Anyone holding `knk.tasks` can also claim by numeric task id.
- **The state machine** is plain strings: `Pending → InProgress → Completed | Failed` (plus `Cancelled`, which only the catalogue scan sets). **There are no timeouts, heartbeats or expiry.** No transition back to Pending exists. Cancelling in game, quitting, a plugin restart, "Capture again" and abandoning the form all leave the task open for good (InProgress or Pending).
- **Identity:** the API can find the initiator: `WorldTask → WorkflowSession.UserId → User.Uuid`, with `User.IsOnline` and `LastSeenAt` set by the plugin on join and quit. But `WorkflowSession.UserId` comes from the request body, not the JWT. `IsOnline` is a single global flag with no server id or heartbeat, so it stays wrong after a crash. A claim records only a free-text `ClaimedByMinecraftUsername`, with no UUID or user id.
- **SignalR:** nothing exists yet. The API has no hub and the plugin has no client. KNG-57 (#66) scopes the work and asks whether the world-task poller polls the API or the plugin. Answer: the plugin and the web app both poll the API.

---

## 1. Data model

### 1.1 Entity `WorldTask` → table `world_tasks`

`API:Models/WorldTask.cs:5-45`, EF config `API:Properties/KnKDbContext.cs:2081-2117`.

| Field | Notes |
|---|---|
| `Id` int PK | Also used in the temporary WorldGuard region name `tempregion_worldtask_<Id>` (`API:Services/DomainRegionNameFinalizer.cs:56`, `PLG:tasks/WgRegionIdTaskHandler.java:49,281`) |
| `WorkflowSessionId` int FK, required | Cascade delete with the session (`KnKDbContext.cs:2114-2117`) |
| `StepNumber` int?, `StepKey` string?, `FieldName` string? | `CreateAsync` requires StepKey and FieldName. It takes FieldName from `inputJson.fieldName` when missing (`API:Services/WorldTaskService.cs:39-56`) |
| `TaskType` string(100), required | Free string, no enum (see 1.4) |
| `Status` string(50), default `"Pending"` | Comment says `Pending, InProgress, Completed, Failed, Cancelled` (`WorldTask.cs:19`) |
| `LinkCode` string? (max 50 in the snapshot) | The claim code. Comment says "6-10 chars, unique, nullable after claim" (`WorldTask.cs:21`). **None of that is enforced** (see 1.3) |
| `AssignedUserId` int? FK → User (Restrict) | Indexed. Accepted on create (`WorldTasksController.cs:56`) and filterable (`WorldTaskRepository.cs:82-85,114-119`). **The web app never sets it and nothing reads it for routing** |
| `ClaimedByServerId` string? | The plugin always sends `"localhost"` (hard-coded, `PLG:KnKPlugin.java:2008-2009`, "TODO: make this configurable") |
| `ClaimedByMinecraftUsername` string? | Free text from the plugin (`player.getName()`). No UUID or user id is stored |
| `InputJson`, `OutputJson`, `ErrorMessage` | Plus the obsolete `PayloadJson` (longtext), which is still written on create (`WorldTaskService.cs:66-70`) and by `UpdateStatusAsync` (`:133-136`) |
| `CreatedAt`, `ClaimedAt`, `UpdatedAt`, `CompletedAt` | No `ExpiresAt`, no heartbeat column |

**What the entity lacks:** a creator user id (only reachable through the session), a claimer UUID or user id, an expiry, a heartbeat, a target server or world, and a concurrency token. `WorkflowSession` has a `[Timestamp] RowVersion` (`API:Models/WorkflowSession.cs:29-30`); `WorldTask` does not.

Indexes in the model snapshot: only `AssignedUserId` and `(WorkflowSessionId, Status)` (`API:Migrations/KnKDbContextModelSnapshot.cs` ≈6589-6591). **No index on LinkCode.**

Read DTO `WorldTaskReadDto` (`API:Dtos/WorkflowDtos.cs:98-118`) has **no `entityType`**. The plugin DTO expects one (`knk-plugin/knk-api-client/.../dto/WorldTaskDto.java:13`), so the claim message's label is always just the field name (`PLG:commands/KnkTaskClaimCommand.java:97-98,138-148`).

### 1.2 Statuses and transitions (actual)

| Transition | Where | Guard |
|---|---|---|
| create → `Pending` | `WorldTaskService.CreateAsync` (`:31-77`); AutoMapper forces Pending (`API:Mapping/WorkflowMappingProfile.cs:49`) | — |
| `Pending → InProgress` | `ClaimAsync` (`:161-184`) | Status `InProgress` already → returns the task unchanged, **whoever is asking** ("idempotent", `:166-169`). Any other non-Pending status → `InvalidOperationException` → 400 |
| `* → Completed` | `CompleteAsync` (`:186-257`) | **No status guard.** It also completes a `Pending` (never claimed), `Failed` or `Cancelled` task. Already Completed → returned as is |
| `* → Failed` | `FailAsync` (`:259-269`) | **No guard at all**; it can turn a Completed task into Failed |
| `* → anything` | `UpdateStatusAsync` via `POST {id}/status` (`:129-159`) | Any string is accepted. On "Completed" it also completes the StepProgress |
| `Pending/InProgress → Cancelled` | Only `MinecraftCatalogScanService.FailAsync` (`API:Services/MinecraftCatalog/MinecraftCatalogScanService.cs:593-606`) | — |
| delete | `DELETE {id}` | — |

Side effects of completion:
- `GateBlockScan` / `GateOpenedBlockScan` replace the door's snapshots (`:209-234, 361-448`). If parsing or persisting fails, the task is saved as **Failed** and an `InvalidOperationException` is thrown. The controller catches only `KeyNotFoundException` (`WorldTasksController.cs:177-191`), so the plugin gets a **500** from the global handler (`API:Program.cs:271-281`).
- "Server-side re-validation" (`ValidateTaskOutputAsync`, `:549-609`) is a stub that always returns valid.
- A matching `StepProgress` is marked Completed through `GetOrCreateStepAsync`, which catches MySQL 1062 duplicate keys (`:309-341`). This is the same race as #75, mitigated here but not in the wizard's Next path.

No expiry, timeout, heartbeat or "release claim" exists anywhere. `IMPLEMENTATION_CHECKLIST.md:324` ("Task timeouts and auto-cleanup") is still unchecked.

### 1.3 Claim code generation, format and expiry

- `GenerateLinkCode()` (`WorldTaskService.cs:300-307`): a new `System.Random()` on each call, 6 chars from `A-Z0-9` (36^6 ≈ 2.2·10⁹). It is called once per create (`:72-73`).
- No uniqueness check, no unique index, no retry on collision.
- **No expiry.** The code stays on the row for good: it is not cleared on claim, completion or failure.
- `GetByLinkCodeAsync` is `FirstOrDefault(t => t.LinkCode == code)` with no status filter and no ordering (`API:Repositories/WorldTaskRepository.cs:23-28`). A collision with an old Completed task makes the new code unclaimable ("Task is not available (status: Completed)").
- Tasks the catalogue scan creates directly through EF get **no LinkCode** (`MinecraftCatalogScanService.cs:85-99`). Tasks the web app creates for headless gate scans **do** get one.
- Compare account link codes, which are a different entity (`API:Models/LinkCode.cs`): 8 chars, `RandomNumberGenerator`, 20-minute expiry, Active/Used/Expired.

**Naming collision:** "claim code" now also means the KNG-214 admission claim code (`LinkCodePurpose.Claim`, 8 Crockford base32 characters bound to a Mojang UUID, `LinkCode.cs:13,106-107`). #57 ("claim codes typed as link codes") is about **those**, not world-task codes. Pick different names in the SignalR design (for example "task code").

### 1.4 Who may claim

- **API:** controller-level `[RequireServiceOrPermissionForWrites("knk.admin.world")]` (`API:Controllers/WorldTasksController.cs:12`, node `API:Attributes/RequirePermissionAttribute.cs:103`). Every write, including claim, complete and fail, passes for the **plugin API key** or a web user holding `knk.admin.world`. Reads, and POSTs whose route ends in `search`, are open to any logged-in user (`API:Attributes/DefaultCallerRequiredFilter.cs:144-148`).
  - The controller comment "every write (incl. POST search)" (`:11`) is wrong; searches count as reads.
- **The API does no per-player check:** it trusts the plugin's `claimedByMinecraftUsername`. `ClaimTaskDto` has no linkCode (`API:Dtos/WorkflowDtos.cs:82-86`). The plugin sends one (`knk-api-client/.../impl/WorldTasksApiImpl.java:98-111`, "for verification on backend"), and the API drops it.
- **Plugin:** `/knk task-claim`, `/knk itemscan claim` and `/knk kitscan claim` all need `knk.tasks` (`PLG:commands/KnkAdminCommand.java:328-377`; `plugin.yml:537-539`, default op), checked through `CommandPermissions` (`PLG:commands/CommandRegistry.java:30-44`). There is no link between the claiming player and the web user who made the task.

### 1.5 Links to workflow session, step progress and form progress

- Every task belongs to a `WorkflowSession` (`UserId`, `FormConfigurationId`, `EntityTypeName`, `EntityId`, `Status`; `API:Models/WorkflowSession.cs`).
- The web app creates the session with `userId` **from the client** (`WEB:pages/FormWizardPage.tsx:318-323`; `API:Dtos/WorkflowDtos.cs:9`; `WorkflowService.StartSessionAsync` maps it as is, `API:Services/WorkflowService.cs:30-36`). `ChildFormModal` creates its own session when it has none (`WEB:components/FormWizard/ChildFormModal.tsx:134-162`).
- Completion marks the `StepProgress` (by StepKey) Completed (`WorldTaskService.cs:241-253`). `WorkflowService.FinalizeAsync` counts completed tasks (`WorkflowService.cs:134-160`); the outputs stay in `OutputJson`.
- **No link to `FormSubmissionProgress` (drafts).** Only the extracted value goes into the draft's field. The task id is not stored, so a resumed draft cannot reattach to a running task (the renderer state is in memory only, see section 4).
- Output is read back later on the server side: `DomainWorldResolver` and `DomainSubRegionService` read `worldName` from the OutputJson of the task named by a `tempregion_worldtask_<id>` region id (`API:Services/DomainWorldResolver.cs:195-210`, `API:Services/DomainSubRegionService.cs:146-155`). Region finalize/rename is a separate path: API → plugin `RegionHttpServer` (`PLG:KnKPlugin.java` ≈593-596, `API:Services/DomainRegionNameFinalizer.cs`). Lootbox areas are not finalized (#34).

### 1.6 Task types and handlers (full list)

Seeded FormConfiguration fields (`API:Data/FormConfigurationSeeds/*.json`, `settingsJson.worldTask`):

| taskType | Seeded on (entity.field) | Plugin handler and how it is resolved | Mode |
|---|---|---|---|
| `ReagionCreate` (sic) | Town, District, DomainSubRegion, GateStructure, LootboxSpawnArea `.WgRegionId` | No taskType registration. Falls back to the **field name** `WgRegionId` → `WgRegionIdTaskHandler` (`PLG:tasks/WorldTaskHandlerRegistry.java:61-64`) | player |
| `RegionClaim` | Structure.WgRegionId | Same field-name fallback → `WgRegionIdTaskHandler` | player |
| `LocationSelection` | Town/District/Structure.Location; GateStructure.LocationId; GateDoor Anchor/Ref1/Ref2/HingeAxis/Left+RightSeed/OpenAnchor/InfoDisplay; Siege Objective/Spawnpoint/Scenario hub | taskType `LocationSelection` → `LocationTaskHandler` (`KnKPlugin.java:563-565`) | player |
| `ItemScan` | ItemBlueprint.DefaultDisplayName | taskType → `ItemScanTaskHandler` (`:578-580`); completes at once from the item in hand | player (instant) |
| `KitScan` | Kit.Name | taskType → `KitScanTaskHandler` (`:588-590`); completes at once from the inventory | player (instant) |
| `GateBlockScan`, `GateOpenedBlockScan` | GateDoor.BlockSnapshots / OpenedBlockSnapshots | `HeadlessWorldTaskPoller` → `GateBlockScanTaskHandler` (`:606-607`) | headless |
| `MinecraftCatalogScan` | not a form; `POST api/MinecraftCatalog/scans` creates it (`MinecraftCatalogScanService.cs:78-99`) | headless → `MinecraftCatalogScanTaskHandler` (`:608-609`) | headless |
| `LocationCapture`, `VerifyLocation`, `VerifyStructure`, `VerifyPlacement`, `VerifyResource`, `VerifyBoundary`, `Custom` | Offered in the form builder (`WEB:components/FormConfigBuilder/FieldEditor.tsx:65-80`; turning the toggle on picks `VerifyLocation`, `:1132-1135`), not seeded | **No handler.** It works only if the field name happens to be `Location`/`WgRegionId`/`ItemScan`/`KitScan`. Otherwise the claim succeeds (task → InProgress) and the player sees "No handler registered" (`KnkTaskClaimCommand.java:111-114`), leaving the task **stuck InProgress** | — |

`GateDoorRegionCaptureHandler` is **not** a world task: it is a direct admin command routed through the chat listener (`PLG:listeners/WorldTaskChatListener.java:22-26`). Handler resolution is by taskType first, then the case-sensitive field name.

---

## 2. API endpoints and services

All are in `API:Controllers/WorldTasksController.cs`, route `api/WorldTasks`. Writes need the plugin key or `knk.admin.world`; reads need any logged-in user or the plugin.

| Endpoint | Lines | Called by |
|---|---|---|
| `POST /` create (`WorldTaskCreateDto`) → 201; 409 `GateScanNotReady`; 400 | 22-45 | **web app** (`WEB:apiClients/worldTaskClient.ts:25`, used by `WorldBoundFieldRenderer`) |
| `POST /from-field` | 59-89 | nobody |
| `GET /{id}` | 91-97 | **web app poll** every 2 s; plugin `/knk task-claim <number>` and `/knk task-status` |
| `GET /by-link-code/{code}` | 99-106 | **plugin** claim and status commands |
| `GET /status/{status}?serverId=` | 108-114 | **plugin** `HeadlessWorldTaskPoller` (`Pending`, no serverId); `/knk tasks [status]` |
| `GET /session/{id}`, `POST /user/{id}/search`, `POST /search` | 116-138 | nobody in the web app or plugin (client methods exist, `worldTaskClient.ts:42-52`) |
| `POST /{id}/status` | 143-156 | nobody (client method exists) |
| `POST /{id}/claim` (`claimedByServerId`, `claimedByMinecraftUsername`) | 159-175 | **plugin** `KnkTaskClaimCommand` |
| `POST /{id}/complete` (`outputJson`) | 178-191 | **plugin** handlers |
| `POST /{id}/fail` (`errorMessage`) | 194-207 | **plugin** headless handlers only. **No player handler ever calls fail** |
| `DELETE /{id}` | 209-214 | nobody |

There is no cancel, heartbeat, release, expire or list-for-player/server endpoint. The service is registered scoped (`API:DependencyInjection/ServiceCollectionExtensions.cs:229-230`).

---

## 3. Plugin side

### 3.1 How tasks reach the server

- **Player tasks are never discovered by the plugin.** They are fetched on demand when a player runs `/knk task-claim <code|id>`. No list is shown on join and nothing is offered.
- **Headless tasks:** `HeadlessWorldTaskPoller` (`PLG:tasks/HeadlessWorldTaskPoller.java`) calls `listByStatus("Pending")`. That returns **all** Pending tasks of every type, including player tasks with their InputJson (`:85-97`). It dispatches those a headless handler supports (`:107-129`). An `inFlightTaskIds` set stops re-dispatch within this JVM only.
  - **It never claims first**, so the task stays `Pending` while it runs. A second server would run it too.
  - Interval: `world-tasks.headless-poll-interval-seconds` (5), doubling to `headless-poll-max-interval-seconds` (60) while idle (`config.yml:162-170`, `:99-105`). Both the config and the class carry a TODO for SignalR.
- `PlayerNotificationPoller` (`player-notifications.poll-interval-seconds: 2`, `config.yml:206-210`) is the plugin's per-player channel from the API. Its handlers include rank changes, payments, account-linked and staff currency alerts. **World tasks don't use it.** It is the closest existing pattern for "offer task to player X".

### 3.2 Claim command and UX

`/knk task-claim <code|id>`. `/knk itemscan claim <code>` and `/knk kitscan claim <code>` are aliases (`KnkAdminCommand.java:336-371`). Implementation: `PLG:commands/KnkTaskClaimCommand.java:36-132`.

1. The sender must be a Player.
2. KNG-174 check: refuse if the player already holds an open task (`:49-54`, `WorldTaskHandlerRegistry.openTaskRefusal`, `:139-147`).
3. Digits only → `getById`, with a warning to use the code. Otherwise → `getByLinkCode`.
4. Status other than `"Pending"` → "Task is not available (status …) / Already claimed by …" (`:83-91`).
5. `claim(id, linkCode, "localhost", player.getName())`. On success: "✓ Successfully claimed task!", then `registry.startTask(player, taskType, fieldName, id, inputJson)` (`:94-115`).
6. Check-then-claim race: two players who fetch at the same time both see Pending. The API's "InProgress is idempotent" answer then returns **200 to the second claimer**, and both start handlers on the same task.

No items are given. All UX is chat; the per-type texts are in 3.3. Chat input is caught in `WorldTaskChatListener` on **`AsyncPlayerChatEvent`** (`PLG:listeners/WorldTaskChatListener.java:39-62`). Right-click goes through `WorldTaskLocationSelectionListener` (main thread).

### 3.3 Per-type handlers

- **`LocationTaskHandler`** (`PLG:tasks/LocationTaskHandler.java`).
  - State is a `HashMap<Player, TaskContext>` (`:41`).
  - Chat on start (`:76-88`): `save` / `save <name>` / right-click a block / `pause` / `resume` / `cancel`.
  - Validates against `inputJson.validationContext` in game; a blocking rule refuses (`:205-215`).
  - Completes with `{fieldName:"Location", name, x,y,z,yaw,pitch, World, capturedAt}` (`:293-316`). The key is **`World`** (capital W); the region handler uses `worldName`.
  - The HashMap is read and written from the async chat thread, and `player.getLocation()` is called off the main thread. This is a thread-safety risk.
- **`WgRegionIdTaskHandler`** (`PLG:tasks/WgRegionIdTaskHandler.java`).
  - Same map shape (`:56`). Parses `parentRegionId` and `priority` from input; flags are a TODO (`:118-136`). Turns on the WorldEdit CUI.
  - Chat: `//sel poly|cuboid` + `save`, or `select <existing>`, `pause`, `resume`, `cancel` (`:145-150, 200-224`).
  - Creates the region `tempregion_worldtask_<taskId>` in **`player.getWorld()`** (`:238, 281`). The world is wherever the player stands; nothing compares it with the domain's expected world in InputJson, beyond what the validation rules check.
  - Completes with `{fieldName:"WgRegionId", regionId, createdAt, worldName, parentRegionId?}` (`:432-445`). If complete fails, the temp region is deleted (`:456-463`).
- **`ItemScanTaskHandler` / `KitScanTaskHandler`**: read the item or inventory and call `complete` inside `startTask` (`ItemScanTaskHandler.java:49-60`, `KitScanTaskHandler.java:55-65`). There is no session.
- **Headless handlers**: `GateBlockScanTaskHandler` (`:72-95`; loads the door through `GateDoorsApi`; complete/fail at `:383-393`) and `MinecraftCatalogScanTaskHandler` (`:60-100`).

### 3.4 Results, timeouts, quit, restart and outages

- **Results:** `POST /{id}/complete` from an async executor (`WorldTasksApiImpl.java:114-129`). If it fails, the player sees "Failed to complete task: …". The handler state stays in place (location) so the player can type `save` again; the region handler deletes the region. There is no retry queue or spool.
- **Timeouts:** none on either side.
- **In-game `cancel`:** only removes the local map entry (and the region handler cleans up its temp region and WorldEdit session). **The API is not told** (`LocationTaskHandler.java:98-105`, `WgRegionIdTaskHandler.java:167-184`). The task stays **InProgress for good**, and the web app keeps showing "Waiting for task to complete in Minecraft..." with no recovery button.
- **Quit/disconnect:** nothing. `WorldTaskHandlerRegistry.cancelAllTasks` is never called (grep: only its definition, `:103-110`), and it would skip handlers registered only by taskType anyway. The map is keyed by the `Player` object, so a rejoining player gets a new object: the old context leaks and the task can't be resumed. The task stays InProgress.
- **Plugin restart or crash:** all handler state is in memory and is lost. Tasks stay InProgress.
- **API down:** the claim fails with "Failed to fetch/claim task: …". The headless poller logs and backs off. A `complete` that fails is not retried.
- **Multiple servers:** the server id is hard-coded `"localhost"`, the headless poller doesn't claim, and no world/server targeting exists. The `ListByStatus(serverId)` filter exists but nothing uses it.

---

## 4. Web app side

Component: `WEB:components/Workflow/WorldBoundFieldRenderer.tsx`. FormWizard renders it next to a field's normal renderer (`WEB:components/FormWizard/FormWizard.tsx:2823-2880, 2970-3010`).

- **When a field gets a panel:** its `settingsJson.worldTask.enabled` is set (`parseWorldTaskSettings`, `FormWizard.tsx:1036-1047`), *or* the child form inherits a `worldTaskHint` from the parent field onto the matching or first field (`:2834-2847`). In the inherited case the result is spread over the form's fields with `spreadTaskValueOntoFields` (KNG-134/167). #145 asks for the same spreading for a field-level task. The panel also needs a `workflowSessionId` and a field that isn't read-only.
- **Create:** clicking "Send to Minecraft" / "Replace via Minecraft" (or "Start scan" for headless) runs `handleCreateInMinecraft` (`:529-627`).
  - Player tasks: `inputJson = {fieldName, currentValue, allPlaceholders?, validationContext{formContextValues, resolvedDependencies, entityMetadata, validationRules(enriched with dependencyFieldValue), …}}`.
  - Gate scans: `{gateDoorId}`. A scan needs a saved door; without one the button is disabled with a hint (#28).
  - `stepNumber = currentStepIndex`, `stepKey = computeStepKey(...)`. `assignedUserId` is never sent.
- **Claim code display:** in the Pending state for non-headless tasks, a yellow card shows the code and a copyable `/knk task-claim <code>` (`:679-740`). Headless tasks show a "scan running, no in-game action needed" card instead (`~:720-744`).
- **Completion detection:** `setInterval` **every 2000 ms** on `worldTaskClient.getById(taskId)` (`:446-527`).
  - Stops on `completed`: `extractTaskResult` → `onChange(value)` (KitScan skips this) → `onTaskCompleted(task, value)`. `onTaskCompleted` fans out ItemScan and KitScan results in FormWizard (`FormWizard.tsx` ≈1341, `applyKitScanResult`).
  - Also stops on `failed`. It **keeps polling forever** while Pending or InProgress, until unmount. Network errors are only logged.
  - InProgress shows "Claimed by <name> on localhost".
- **Result → form fields** (`extractTaskResult`, `:271-364`):
  - Location: `{name, x,y,z,yaw,pitch, World}`; a capture without a world is refused (KNG-118). KNG-134 keeps an existing Location id on replace (`keepLocationIdOnReplace`).
  - Region: `regionId` via `TASK_OUTPUT_FIELD_MAP` (`ReagionCreate`, `WgRegionId`, …) or fallback keys.
  - ItemScan: displayName. GateBlockScan: summary `{status, blockCount, scannedAt}`.
- **Cancel behaviour:** the UI has **no cancel**.
  - "Capture again" and "Try Again" only reset local state (`handleRunAgain`, `:639-644`; `:828-836`). The old task stays Pending (its code still claimable) or InProgress.
  - Unmounting (step change, closing a modal, reload) stops polling; the server is not told.
  - Abandoning the wizard never deletes the session: `workflowClient.delete` exists (`WEB:apiClients/workflowClient.ts:46`) but nothing calls it.
  - After a reload the panel has forgotten the task, because the task id is not persisted.
- The statuses `accepted` (web) and `Claimed` (plugin `/knk tasks` colours, `KnkTaskListCommand.java:206-212`; tab completion `KnkAdminCommand.java:650`) never occur; the API uses `InProgress`.

---

## 5. Identity linking and presence

- **One row per person.** `User` holds both the web login (email/password) and `Uuid` (`API:Models/User.cs:22-26`). `Uuid` is null for a web-only account until linking. Linking runs through `LinkCode` purpose `Link` (`/account link` in game → code entered on the website) or the KNG-214 admission `Claim` flow (`API:Models/LinkCode.cs`). After linking, `User.Uuid` is the Minecraft identity.
- **Initiator → player:** `WorldTask.WorkflowSessionId → WorkflowSession.UserId → User.Uuid` (and the username). This works today, with one weakness: `WorkflowSession.UserId` comes from the request body (`FormWizardPage.tsx:318-319`), not the JWT. The SignalR version should take the creator from the authenticated caller and store it on the task.
- **Presence:** `User.IsOnline` and `User.LastSeenAt` (`User.cs:153-170`), set by `PUT /api/Users/{id}/presence` (`[RequirePluginService]`, `API:Controllers/UsersController.cs:724-741`; `API:Repositories/UserRepository.cs:191-199`). The plugin calls it fire-and-forget on join and quit (`PLG:listeners/PlayerListener.java:208-211, 335-338, 357-366`). Limits:
  - It is skipped if the user isn't cached yet at join (documented race).
  - No server id and no heartbeat; nothing resets it on startup or shutdown, so a crash leaves everyone "online".
  - The value can't say whether the player is on *this* server or in the right world.
  - Admin moderation lists can filter on it (`UserRepository.cs:211`).

  Good enough as a hint, not as truth. The plugin's own `Bukkit.getPlayer(uuid)` must be the final check before auto-claiming.
- **Claimer identity:** only a username string is stored. Nothing ties the claimer back to a `User`.

---

## 6. Verified pain points, bugs and gaps

1. **Tasks stuck InProgress for good** after an in-game cancel, quit, restart, an unknown task type, or a failed complete with no retry (3.4). No expiry, heartbeat, release or cancel endpoint exists, and the web app has no recovery for InProgress.
2. **Orphan Pending tasks with claimable codes** after "Capture again", "Try Again", abandoning the wizard or a reload (4). Nothing deletes or expires them, and they pile up in `/knk tasks`.
3. **Double claim:** the plugin checks then claims, and the API returns InProgress tasks with 200 to anyone (`WorldTaskService.cs:166-169`), so two players can run the same task. No row version or conditional UPDATE exists.
4. **The claim code is not checked:** the API ignores the code (`ClaimTaskDto` has none), and `/knk task-claim <id>` works with sequential ids for anyone with `knk.tasks`.
5. **LinkCode is not unique, never expires, never clears,** and comes from `System.Random`. A collision can make a code resolve to an old completed task (1.3).
6. **Complete/fail have no state guard:** they can complete a never-claimed task, or fail a completed one (`:186-269`). A gate-scan apply failure returns 500 instead of 400/409.
7. **Wrong world / multiple servers:** the region is created in `player.getWorld()`. The server id is always `"localhost"`. The headless poller doesn't claim, so N servers run N scans. Nothing routes a task to a server or world.
8. **Threading:** chat commands handled on `AsyncPlayerChatEvent` touch `HashMap`s and `player.getLocation()` off the main thread (`LocationTaskHandler`).
9. **Unbounded web polling** while Pending or InProgress (2 s per open panel, with no stop on InProgress or Pending). Every headless poll returns every Pending task with full InputJson (the validation context can be large).
10. **The creator is client-asserted** (`WorkflowSession.UserId` from the body); `AssignedUserId` is never used.
11. **Form-builder task types without handlers** (`VerifyLocation` is even the default when the toggle is turned on) end stuck InProgress.
12. **Server-side output validation is a stub** (`ValidateTaskOutputAsync` always returns valid); the plugin is the only validator. KNG-173 already notes this for Location.
13. **#34:** regions drawn through a lootbox-area task stay `tempregion_worldtask_*` and are deleted after 14 days.
14. **#75:** a `step_progress` duplicate-key race on Next. `WorldTaskService.GetOrCreateStepAsync` catches 1062; the wizard path does not.

### Docs that contradict the code

| Doc claim | Reality |
|---|---|
| LinkCode has a unique index, with collision detection and uniqueness enforced (`ARCHITECTURE.md:272,397`; `IMPLEMENTATION_CHECKLIST.md:10-11,67,261`; `REQUIREMENTS_WORLDTASK.md:9`) | No index of any kind, no collision check |
| "LinkCodes can only be used once"; "nullable after claim" (`REQUIREMENTS_WORLDTASK.md:183`; `WorldTask.cs:21` comment) | Never cleared, so it stays resolvable for good |
| Claim checks the LinkCode, with 400 on mismatch and 409 if already claimed (`API_CONTRACT.md:181-220`) | No code in the DTO, no 409; InProgress returns 200 to anyone |
| Command `/worldtask claim {code}` (`SPEC_WORLDTASK.md:112,243`; `REQUIREMENTS_WORLDTASK.md:14,86`; `ARCHITECTURE.md:192`; `IMPLEMENTATION_CHECKLIST.md:192`), `/wt <code>` (`LOCATION_HANDLER_INTEGRATION.md:189`) | `/knk task-claim <code\|id>`. The class javadoc says `/knk task claim` (`KnkTaskClaimCommand.java:15`), also wrong |
| Web polls every 3 s through `TaskStatusMonitor` / `WorldTaskCta` (`ARCHITECTURE.md:16,118-132,392`; `API_CONTRACT.md:552`; `HANDLER_ACTIVATION_GUIDE.md:244-261`; `LOCATION_HANDLER_INTEGRATION.md:88-90`; `IMPLEMENTATION_CHECKLIST.md:104,244`) | 2 s in `WorldBoundFieldRenderer`; those components don't exist |
| Plugin `claim(taskId, serverId, username)` (`SPEC_WORLDTASK.md:278`) | Takes 4 arguments including linkCode, which the API ignores |
| Claim "idempotent if re-claimed by same player" (`SPEC_WORLDTASK.md:210`; `REQUIREMENTS_WORLDTASK.md:17`) | Idempotent for **any** player |
| `Cancelled` is part of the form-task lifecycle (`ARCHITECTURE.md:307`; `API_CONTRACT.md:116`) | Only the catalogue scan sets it; the web app and plugin can't cancel |
| `WorldTasksController.cs:11` "every write (incl. POST search)" needs the node | POST search is treated as a read |
| #66 "WorldTask poller … verify the direction" | The plugin polls the API (headless only) and the web app polls the API (2 s). Player tasks are pulled by a command |
| `docs/architecture/web-api-architecture.md:80` (headless polling 5 s → 60 s) | Accurate |

---

## 7. SignalR proposal sketch (short)

**Principle:** REST stays the source of truth and the write path. SignalR carries notifications and offers that the receiver confirms through REST. Any missed message is recovered by a resync.

**Schema additions to `WorldTask`:**
- `CreatedByUserId`, taken from the JWT and not from the body.
- `OfferedToUserId` (null = code only), `OfferState` (None/Offered/Declined/TimedOut), `OfferedAt`.
- `ClaimedByUserId` and `ClaimedByUuid`.
- `ExpiresAt` (Pending TTL, e.g. 30 min) and `LastHeartbeatAt` (InProgress lease, e.g. 2 min).
- A `RowVersion`.
- A unique index on `LinkCode`, filtered to open tasks (or clear the code on claim), with codes generated by `RandomNumberGenerator`.

**Claim** becomes a conditional `UPDATE … WHERE Status='Pending'`. The loser gets 409. Keep returning 200 when the same `ClaimedByUuid` repeats the claim.

**Hubs:**
- `/hubs/game-server`: plugin API key. One group per real `serverId`, which should come from config instead of `"localhost"`.
- `/hubs/web`: JWT. Groups `user:{id}` and `task:{id}` (or `session:{id}`).

**Flow:**
1. `POST /WorldTasks` (unchanged). The API also computes the target:
   - Default target: the initiator, if `User.Uuid` is set and `IsOnline`.
   - Explicit target: `assignedUserId` (admin B) picked from an "online staff with `knk.admin.world`" list.
2. If there is a target, the API pushes `TaskOffered{taskId, targetUuid, taskType, fieldName, label, inputJsonRef}` to the game server(s). The plugin checks that `Bukkit.getPlayer(uuid)` is online, has no open task (KNG-174) and holds `knk.tasks`.
   - **Initiator:** auto-claim, calling `POST /{id}/claim` with the uuid, then `startTask`.
   - **Another admin:** show a clickable `[Accept] [Decline]` chat line instead of claiming silently. Accept → claim.
   - The plugin reports `OfferResult{taskId, accepted|declined|offline|busy}` (hub invoke, or REST `POST /{id}/offer-result`).
3. The API pushes to `task:{id}` / `user:{creator}` on the web hub: `TaskOffered`, `TaskOfferDeclined`/`TaskOfferTimedOut` (the UI then shows the code), `TaskClaimed{by}`, `TaskProgress` (optional: "selection saved", "validation blocked: …"), `TaskCompleted{outputJson}`, `TaskFailed{error}`, `TaskCancelled`, `TaskExpired`.
4. **Fallback (claim code):** always generate the code and show it from the start, collapsed while an offer is pending ("Sent to <player> in game… or use code ABC123"). If nobody accepts within N seconds, or the target is offline, expand it. `/knk task-claim <code>` keeps working, but by code only; drop the numeric-id path.
5. **Broadcast option** ("any online staff"): offer to every eligible online player as a clickable line; the first claim wins through the conditional UPDATE. Optional; the targeted offer covers the main case.

**New REST endpoints:**
- `POST /{id}/cancel`, called by the web app on Capture again, Try Again, unmount (best effort) and abandon, and by the plugin on in-game `cancel`, quit and disable. Also add a "release to Pending" option.
- `POST /{id}/heartbeat`, from the plugin every ~30 s for held tasks, or over the hub.
- `GET /WorldTasks/open?serverId=` for resync.
- A background sweeper that expires Pending past `ExpiresAt` and fails or releases InProgress past the heartbeat lease. It also cleans up orphan temp regions (ties into `TempRegionRetentionTask`).

**Reliability:**
- SignalR is at-most-once, so on every (re)connect:
  - The plugin calls `GET /open?serverId` and resolves each task: still held locally → heartbeat; held by nobody (restart) → cancel or release; offered to an online player → re-offer.
  - The web app re-fetches `GET /{id}` for its open task.
- Keep slow polling (e.g. 10-15 s) only while the hub is disconnected.
- Headless tasks: push `TaskCreated` to the game-server group. The plugin must **claim before executing**, which stops double scans; keep a 60 s poll as the safety net.
- Persist the task id in the draft field value, or look it up with `GET /session/{id}`, so a reload reattaches.

**Plugin hygiene to fix alongside:**
- Call the API on cancel, quit and disable.
- Key handler state by UUID in concurrent maps, and hop to the main thread for chat-driven actions.
- Make the server id configurable.
- Send `uuid` in the claim body.
