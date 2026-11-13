# WgRegionId WorldTask Requirements (from legacy CreationStageRegion)

**Status:** Implemented (requirements for the `WgRegionId` world task, built as `WgRegionIdTaskHandler` in knk-plugin; kept as the requirement record) · **Last updated:** 2026-11-13 (moved into knk-workspace, PandiO/knk-workspace#304)

_Moved from `knk-plugin/spec/WG_REGION_ID_WORLD_TASK_REQUIREMENTS.md` at `b8aa582f7a` ([source](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/spec/WG_REGION_ID_WORLD_TASK_REQUIREMENTS.md)). The text below is unchanged apart from links; it was not rewritten._


## Purpose
- Recreate the legacy CreationStageRegion flow inside the WorldTask system so players can define a WorldGuard region as task output for the `WgRegionId` field.
- Preserve validation (must have a selection; optional parent region containment), region creation, and cleanup semantics.

## Legacy behavior (CreationStageRegion)
- Stage intent: let a player define a WorldGuard region for a creatable entity using a WorldEdit polygonal selection.
- Startup UX: when the stage starts, the player is given the WorldEdit wand tool and a CUI selection is dispatched; player is shown tips about `//sel poly`.
- Input trigger: player types `save` in chat while in the stage.
- Validation: a WorldEdit selection must exist; if a required parent region is configured, every corner of the polygon (min/max Y) must be inside that parent region; otherwise the command errors.
- Region creation: uses the creatable’s `createWGRegion(selection, tempId, priority, flags)`; registers the new region in WorldGuard with id `tempregion_creationstage_<stageId>` and records it as the stage result.
- Session cleanup: removes the WorldEdit session after saving to avoid stale selections.
- Result: a `ProtectedRegion` (or null when unset); `getResultString()` is "Region set" or "Not set".
- Cleanup on creation abort: if the created region is not linked to a Dominion, it is removed from WorldGuard; warns if a Dominion is linked but the id still has the temp prefix.

## Player flow to mirror in WorldTask
1) Task starts: notify player they need to define a WorldGuard region; equip wand and enable CUI selection, including a tip to use polygon selection.
2) Player selects a region with WorldEdit (polygonal selection expected).
3) Player confirms with a specific action (legacy used chat command `save`; WorldTask may prefer an interaction prompt/button or a chat keyword to keep parity).
4) Plugin validates selection exists; if a parent region is required, ensure full containment.
5) Plugin creates the WorldGuard region via the creatable/adapter with a temp id and configured flags/priority, then persists/registers it.
6) Task completes and returns structured output containing the region id (and optionally metadata) to the WorldTasks API.
7) If the task is cancelled/undone and the region is unused, remove the temp region.

## Required interactions and messaging
- Start message: explain goal (claim/create a WG region), remind how to select, include task id.
- Equip tool: set the WorldEdit wand on start and dispatch CUI selection so visual markers show.
- Confirmation trigger: accept a clear command such as `save` (chat) or a context action; must be easy to perform while selecting.
- Success message: acknowledge region saved, include region id.
- Error states: no selection, selection outside required parent region, WorldGuard/WorldEdit errors, API completion failure.

## Validation rules
- Selection required; reject completion if no selection exists.
- If a required parent region is configured by the task payload, ensure polygon containment (min and max Y for all vertices).
- Region id: use temp prefix `tempregion_creationstage_` + task/stage identifier to avoid collisions; strip/replace quotes in ids when serializing.
- Preserve WorldGuard flags/priority provided by the creatable/source entity; do not invent new defaults.

## Data to return in WorldTask output
- fieldName: `WgRegionId`.
- regionId: created WG region id.
- claimedAt/createdAt: timestamp (ms) for traceability.
- Optional: parentRegionId if validation used; world name; selection bounds (if contract allows).

## Side effects and cleanup expectations
- Register the region in WorldGuard immediately on save.
- Clear WorldEdit session after saving to avoid reusing the selection.
- On cancellation/cleanup when no owning entity attaches the region, remove the temp region (with child removal strategy similar to legacy).

## Notes for implementation in WorldTask handler
- Extend or adapt [knk-paper/src/main/java/net/knightsandkings/knk/paper/tasks/WgRegionIdTaskHandler.java](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/knk-paper/src/main/java/net/knightsandkings/knk/paper/tasks/WgRegionIdTaskHandler.java) to handle selection-based creation, not only region entry.
- Ensure Bukkit scheduling is used for player messaging, WorldEdit session changes, and WorldGuard mutations (run on main thread).
- Use the existing WorldTasks API client to report completion; avoid new API shapes—reuse the `complete(taskId, outputJson)` flow with the payload above.
- Keep the optional required-region constraint to support nested regions (town inside parent region, etc.).

## Nice-to-Have Features
### Configurable WorldEdit Selection Type
Allow the player to choose and switch between different WorldEdit selection types (polygonal, cubic, cylindrical, ellipsoid, etc.) during the task.
- **Command**: e.g., `//sel <type>` or task-specific `set-selection-type <type>`.
- **Benefit**: Users with complex regions may prefer different shapes; avoids forcing everyone to use polygonal.
- **UX**: On task start, display available selection types and current choice; let player change type at any time before confirmation.
- **Implementation**: Pass allowed selection types via task payload; listen for player commands and apply WorldEdit's `RegionSelector` dynamically.

### Task Pause/Resume
Allow the player to suspend the task mid-way and resume it later, preserving the current WorldEdit selection state.
- **Benefit**: Player can step away without losing progress; useful for complex selections or when interrupted.
- **Mechanism**: Similar to legacy Creation's `pause`/`resume` flow—store the task state (selection, player id, task id) and re-attach when resumed.
- **Storage**: Cache or persist the WorldEdit selection in a temporary store; restore the selection when resuming.
- **UX**: 
  - New command such as `suspend` or `pause` to put the task on hold.
  - Message confirming suspension and instructions to resume (e.g., `/worldtask resume <taskId>`).
  - On resume, restore the WorldEdit selection and send a summary of current state.
- **Edge cases**: 
  - Task timeout (if not resumed within a limit, auto-cancel and cleanup).
  - Player logout/login: preserve selection across sessions if configured.

## Open questions
- How does a WorldTask convey the required parent region and desired WG flags/priority? (Expect this from task input payload.)
- Should the temp region id be renamed during final entity creation, or left as temp? (Legacy kept temp when linked.)
- What is the preferred confirmation trigger in the WorldTask UX: chat `save`, item click, or GUI button?

## Implementation Decisions
- **Parent region & WG flags/priority**: The parent domain region id should be expected from the task input poayload.
- **Temp region id renaming**: The temp region id should be renamed to `domain_{id}` after the entity has been succesfully created.
- **Confirmation trigger (chat/item/GUI)**: For now the confirmation trigger should be a chat prompt by the player (something like `save`). In the future, this should be optionally replaced by a GUI. The GUI should be a minecraft inventory menu, for which the framework and feature will be implemnented in the future.
