# QOL & Bugfix Backlog

Running list of small bugs and quality-of-life improvements found while using the web app, web API, and plugin. Each item is written with enough context (repro steps, affected files, root cause, evidence) that it can be picked up and implemented by an agent or developer at any time without needing to re-investigate from scratch.

Status legend: `Open` (needs decision or implementation) · `Ready` (solution agreed, ready to implement) · `In Progress` · `Done`

**Items 4–7** (all GateStructure-related) have a combined implementation plan with ordering rationale and phase breakdowns: [GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md](../specs/gate-structure-animation/GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md).

---

## 1. FormSubmissionProgress delete fails with FK constraint error (500)

- **Status**: Ready — solution decided (2026-09-11 planning meeting), not yet implemented
- **Area**: knk-web-api (backend), knk-web-app (frontend surfaces the error)
- **Reported**: 2026-09-10
- **Entity context observed**: Town, progress id `12`
- **Decision**: Option A — cascade delete descendant progress rows (same descendant-walk pattern as `DeleteCompletedOlderThanAsync`). Before deleting, warn the user with the affected child count and require confirmation (via item 2's shared `useConfirm()` mechanism) rather than deleting silently.

### Symptom
Deleting a saved form-submission progress ("Town" entity) from the Form Wizard page fails. The DELETE request returns HTTP 500, and the raw EF Core/MySQL exception is surfaced to the browser console instead of a friendly error.

### Repro steps
1. Navigate to `/forms/Town` (or any entity with saved, in-progress form submissions that have child progress records).
2. In the "Saved Progress" list, click delete on a progress entry that has at least one child progress (a progress whose `ParentProgressId` points at it — e.g. created via the parent→child entity creation flow, see `parentEntityTypeName`/`parentEntityId`/`relationshipFieldName` handling in `FormWizardPage.tsx`).
3. Confirm the delete dialog.
4. Request fails with HTTP 500.

### Evidence
Chrome DevTools console (`[ServiceCall] HTTP 500 error for FormSubmissionProgress/12`):
```
Microsoft.EntityFrameworkCore.DbUpdateException: An error occurred while saving the entity changes. See the inner exception for details.
 ---> MySqlConnector.MySqlException (0x80004005): Cannot delete or update a parent row: a foreign key constraint fails
 (`knightsandkings_dev_v2`.`FormSubmissionProgresses`, CONSTRAINT `FK_FormSubmissionProgresses_FormSubmissionProgresses_ParentProg~`
 FOREIGN KEY (`ParentProgressId`) REFERENCES `FormSubmission...`)
```
Full stack trace shows the call chain:
`FormSubmissionProgressController.Delete` → `FormSubmissionProgressService.DeleteAsync` → `FormSubmissionProgressRepository.DeleteAsync`.

Request: `DELETE http://localhost:5294/api/FormSubmissionProgress/12`, initiated from the browser at `http://localhost:3000/forms/Town`.

### Affected files
- Frontend trigger: [FormWizardPage.tsx:475-498](../Repository/knk-web-app/src/pages/FormWizardPage.tsx#L475-L498) — `handleDeleteProgress`, calls `formSubmissionClient.delete(progress.id!)` and shows a generic "Delete failed" feedback modal on any error.
- Controller: [FormSubmissionProgressController.cs:109](../Repository/knk-web-api/Controllers/FormSubmissionProgressController.cs#L109) — `Delete(int id)`.
- Service: [FormSubmissionProgressService.cs:157](../Repository/knk-web-api/Services/FormSubmissionProgressService.cs#L157) — `DeleteAsync(int id)`, no cascade/child handling, no try/catch around FK failures.
- Repository: [FormSubmissionProgressRepository.cs:66-74](../Repository/knk-web-api/Repositories/FormSubmissionProgressRepository.cs#L66-L74) — `DeleteAsync(int id)` does a naive single-row `Remove` + `SaveChangesAsync`, with no awareness of child rows referencing it via `ParentProgressId`.

### Root cause
`FormSubmissionProgresses.ParentProgressId` is a self-referencing FK with `Restrict` delete behavior (no cascade). `FormSubmissionProgressRepository.DeleteAsync` only removes the single targeted row, so if any other progress row has `ParentProgressId` pointing at it, MySQL rejects the delete and EF Core surfaces the raw `DbUpdateException`/`MySqlException` up through the stack, uncaught, resulting in a 500 with a leaked internal error message.

Note there is already a precedent for cascade-safe deletion in the same repository: [`DeleteCompletedOlderThanAsync`](../Repository/knk-web-api/Repositories/FormSubmissionProgressRepository.cs#L93-L169) walks the parent/child tree and deletes deepest descendants first specifically because of this same `Restrict` FK behavior. The single-record `DeleteAsync` path was never updated to do the same.

### Clarification: what "children" means for cascade delete
`ParentProgressId` is a **self-reference within the `FormSubmissionProgresses` table only** (see [FormSubmissionProgress.cs:53,117-118](../Repository/knk-web-api/Models/FormSubmissionProgress.cs#L53)). `EntityId` on the model is a loose `int?` with no DB foreign key to `Towns`/`Shops`/etc. — there is no cascade path from `FormSubmissionProgress` into any production entity table.

The self-referencing FK only links wizard draft/step-state rows to other wizard draft/step-state rows, via the nested sub-form flow (e.g. filling out a Shop form, clicking "Create New Domain" mid-way, which spawns a child progress row with `ParentProgressId` = the Shop progress's id — see the doc comment on the model, lines 16-24).

Consequence: even if a child progress is `Status = "Completed"` and its `EntityId` now points at an already-created Town/Domain/etc., deleting that progress row **does not delete the Town/Domain row** — those live in separate tables with no FK back to `FormSubmissionProgress`. So under **Option A**, "cascade delete children" always means deleting other rows in `FormSubmissionProgresses` (saved wizard drafts/state) — it can never delete a production entity like a Town. Worst case, it deletes the record that a sub-form was ever filled out, not anything the sub-form produced.

### Proposed solution (decided: Option A)
When deleting a progress, first find and delete all descendant progress rows (same descendant-walk pattern as `DeleteCompletedOlderThanAsync`), then delete the target row. Before doing so, the frontend must warn the user with the descendant count (e.g. "This will also delete 3 related draft(s). Continue?") via the shared `useConfirm()` mechanism from item 2, rather than deleting silently — the count needs a small new read (count descendants) exposed by the API for the confirmation step, or returned ahead of the delete call.

Regardless, the API should not let a raw `DbUpdateException`/`MySqlException` reach the client as an unhandled 500 — at minimum it should be caught and translated into a proper `4xx` response with a user-readable message.

**Options considered and rejected**: Option B (block with a 409 and let the user choose) was rejected as more round-trips than needed given the decision to warn-and-cascade directly. Option C (change the FK to `Cascade` at the DB level) was rejected because it removes the safety net the retention-cleanup job relies on (`Restrict` + intentional descendant walk).

### Resolved questions (2026-09-11 planning meeting)
1. ~~Which option?~~ → Option A, cascade delete.
2. ~~Silent or warn-first?~~ → Warn with a descendant count first, then cascade on confirm.
3. Still open: is there a case where a child progress should survive its parent's deletion (e.g. by nulling `ParentProgressId` instead of deleting the child)? Unlikely given the parent→child form creation flow, but worth a sanity check during implementation — if in doubt, cascade-delete is the decided default.

### Acceptance criteria (refine once implemented)
- Deleting a progress that has child progress records no longer returns an unhandled 500.
- The user is shown the descendant count and must confirm before the cascade delete proceeds.
- The frontend shows an accurate, specific message reflecting what happened (deleted successfully / error).
- Existing retention cleanup (`DeleteCompletedOlderThanAsync`) continues to work unchanged.

---

## 2. Native `window.confirm()` used instead of the styled FeedbackModal

- **Status**: Ready — solution decided, not yet implemented
- **Area**: knk-web-app (frontend only)
- **Reported**: 2026-09-10
- **Decision**: Build a shared, reusable `useConfirm()` hook/context wrapping `FeedbackModal` (promise-based `confirm({ title, message, continueLabel, status }): Promise<boolean>`), mounted once near the app root, and migrate all 10 call sites below to use it instead of `window.confirm()`/bare `confirm()`. Do **not** duplicate the local `feedbackModal` state pattern into each of the 6 files that currently lack it. Confirmation dialogs get an explicit **"Cancel"** button label (not "Close") for clarity on destructive actions — decided 2026-09-11.
- **Scope note**: `DisplayWizardPage.tsx`'s missing `'unlink'`/`'remove'` confirmations are explicitly **out of scope** for this item — filed separately as item 3 below, since that's "add missing behavior," not "swap one confirmation UI for another."

### Symptom
Several delete/overwrite confirmations across the admin/builder UI use the browser's native `window.confirm()` dialog instead of the app's styled [`FeedbackModal`](../Repository/knk-web-app/src/components/FeedbackModal.tsx) component. This is visually inconsistent with the rest of the app (unstyled OS dialog, no branding, blocks the JS thread synchronously) and was called out while working on item 1 above (`handleDeleteProgress` in `FormWizardPage.tsx`).

### Full inventory of call sites (found via repo-wide search for `window.confirm(` and bare `confirm(`)
| # | File | Line | Handler | Confirm text |
|---|------|------|---------|---------------|
| 1 | [FormWizardPage.tsx](../Repository/knk-web-app/src/pages/FormWizardPage.tsx#L425) | 425 | `handleSetDefault` | "There is already a default configuration for ... Do you want to change the default to ...?" |
| 2 | [FormWizardPage.tsx](../Repository/knk-web-app/src/pages/FormWizardPage.tsx#L476) | 476 | `handleDeleteProgress` (item 1's method) | "Are you sure you want to delete this saved progress?" |
| 3 | [FormWizardPage.tsx](../Repository/knk-web-app/src/pages/FormWizardPage.tsx#L502) | 502 | `handleFormConfigDelete` | "Are you sure you want to delete this form configuration?" |
| 4 | [FormWizardPage.tsx](../Repository/knk-web-app/src/pages/FormWizardPage.tsx#L535) | 535 | `handleDisplaySetDefault` | "There is already a default display configuration for ... Change default to ...?" |
| 5 | [admin/EntityTypeConfigurationPage.tsx](../Repository/knk-web-app/src/pages/admin/EntityTypeConfigurationPage.tsx#L151) | 151 | delete handler (uses bare `confirm(`, no `window.` prefix) | "Are you sure you want to delete this configuration?" |
| 6 | [DisplayConfigBuilder/DisplayConfigBuilder.tsx](../Repository/knk-web-app/src/components/DisplayConfigBuilder/DisplayConfigBuilder.tsx#L413) | 413 | set-default handler | "There is already a default configuration for ... Do you want to change the default to ...?" |
| 7 | [FormConfigBuilder/FieldEditor.tsx](../Repository/knk-web-app/src/components/FormConfigBuilder/FieldEditor.tsx#L436) | 436 | delete validation rule | "Delete this validation rule?" |
| 8 | [FormConfigBuilder/FormConfigBuilder.tsx](../Repository/knk-web-app/src/components/FormConfigBuilder/FormConfigBuilder.tsx#L423) | 423 | set-default handler | "There is already a default configuration for ... Do you want to change the default to ...?" |
| 9 | [FormWizard/DisplayConfigurationTable.tsx](../Repository/knk-web-app/src/components/FormWizard/DisplayConfigurationTable.tsx#L42) | 42 | row delete handler | 'Are you sure you want to delete "..."?' |
| 10 | [FormWizard/FormConfigurationTable.tsx](../Repository/knk-web-app/src/components/FormWizard/FormConfigurationTable.tsx#L42) | 42 | row delete handler | 'Are you sure you want to delete "..."?' |

**Correction on the reported locations**: [DisplayWizardPage.tsx](../Repository/knk-web-app/src/pages/DisplayWizardPage.tsx) does **not** currently call `window.confirm()` anywhere. Its `handleActionClick` has TODO stubs for the `'unlink'` and `'remove'` action types (lines 26-29, 34-37) that just `console.log(...)` — no confirmation dialog exists yet for those at all. This may be what was remembered as a "known location," but it's a different gap (missing confirmation entirely, not a wrong-component confirmation) — see Open Question 4.

### Root cause
Ad-hoc use of the browser-native, synchronous `window.confirm()` API in individual handlers, rather than routing through the app's `FeedbackModal` component, which was designed for styled success/error/info messaging with an `onContinue`/`onClose` callback pattern rather than as a drop-in promise-based confirm dialog.

### Complexity note
This is not a small find-and-replace: **7 of the 10 call sites live in files that have no existing modal/feedback state at all** (`admin/EntityTypeConfigurationPage.tsx`, `DisplayConfigBuilder.tsx`, `FieldEditor.tsx`, `FormConfigBuilder.tsx`, `FormWizard/DisplayConfigurationTable.tsx`, `FormWizard/FormConfigurationTable.tsx`). Only `FormWizardPage.tsx` already has `feedbackModal` state and a rendered `<FeedbackModal />` (added for item 1's success/error toasts), which is why call sites 1-4 are the easiest to convert. `FeedbackModal` itself is also not shaped as a `confirm(): Promise<boolean>` — it's an open/close-callback component, so `if (!window.confirm(x)) return;` can't be swapped 1:1; each call site's control flow needs to move the "proceed" logic into an `onContinue` callback.

### Proposed solution (decided)
Extract a small reusable confirmation mechanism built on top of `FeedbackModal` (a `useConfirm()` hook or a `ConfirmModal` context/provider mounted once near the app root) that exposes something like `confirm({ title, message, continueLabel, status }): Promise<boolean>`. This avoids duplicating modal state/JSX across the 6 files that currently have none, and lets every call site become a small `if (!(await confirm({...}))) return;`-shaped change without a full boilerplate rewrite per file. `FormWizardPage.tsx`'s 4 call sites (which already have local `feedbackModal` state for success/error toasts) should be migrated to the shared hook too, for consistency — not left on the local pattern.

### Resolved questions (2026-09-11 planning meeting)
1. ~~Close-as-Cancel vs explicit "Cancel" label?~~ → Explicit "Cancel" label for confirm-flavored usage (see Decision above).

### Explicitly out of scope
- Adding confirmation to `DisplayWizardPage.tsx`'s `'unlink'`/`'remove'` TODO stubs — filed separately as **item 3** below.

### Acceptance criteria (draft — refine once solution is chosen)
- No remaining calls to `window.confirm()`/bare `confirm()` in `knk-web-app/src` for the 10 call sites listed above.
- Every converted confirmation visually matches `FeedbackModal`'s existing styling (no regression in destructive-action safety — user must still explicitly confirm before delete/overwrite proceeds).
- No behavior change to what each action actually does on confirm — only the confirmation UI changes.

---

## 3. DisplayWizardPage `unlink`/`remove` actions have no confirmation (or implementation) at all

- **Status**: Open — core behavior decided, still needs backend-support scoping (see Open Questions)
- **Area**: knk-web-app (frontend only)
- **Reported**: 2026-09-10
- **Split off from**: item 2 (found while auditing `window.confirm()` usage; this is a related but distinct gap)
- **Decision (2026-09-11)**: `unlink` clears the relationship field on the parent entity only (the related entity itself is left intact). `remove` deletes the related entity outright. These are two distinct, meaningfully different actions — not synonyms for the same "sever the link" behavior.

### Symptom
In [DisplayWizardPage.tsx](../Repository/knk-web-app/src/pages/DisplayWizardPage.tsx#L11-L39), `handleActionClick` has fully stubbed-out cases for `'select'`, `'unlink'`, `'add'`, and `'remove'` `DisplayAction` types — each just does `console.log(...)` (lines 23-24, 27-28, 31-32, 35-36) with a `// TODO: Implement ... modal/confirmation` comment. Only `'edit'`, `'view'`, and `'create'` are actually wired up (they navigate to a route). This means clicking any unlink/remove/select/add action in the display view currently does nothing visible to the user except a console log — no confirmation dialog, no actual unlink/remove behavior, no modal.

### Affected code
```tsx
// DisplayWizardPage.tsx:11-39
const handleActionClick = (action: DisplayAction) => {
    switch (action.type) {
      case 'edit': navigate(`/form/${action.entityType}/${action.entityId}`); break;
      case 'view': navigate(`/display/${action.entityType}/${action.entityId}`); break;
      case 'create': navigate(`/form/${action.entityType}/new`); break;
      case 'select':  // TODO: Implement select modal
      case 'unlink':  // TODO: Implement unlink confirmation
      case 'add':     // TODO: Implement add modal
      case 'remove':  // TODO: Implement remove confirmation
        console.log(...); break;
    }
};
```

### Root cause
Not a bug/regression — this is unfinished work. The `edit`/`view`/`create` actions were implemented; `select`/`unlink`/`add`/`remove` were left as placeholders.

### Proposed solution direction
Once implemented, `unlink` and `remove` should use the shared `useConfirm()` mechanism from item 2 (so this naturally lands after item 2 is done) rather than introducing another one-off `window.confirm()`. `select` and `add` are a different shape of problem (they need an actual picker/creation modal, not just a confirmation) and may warrant their own follow-up item.

### Resolved questions (2026-09-11 planning meeting)
2. ~~What should `unlink` do?~~ → Clear the relationship field on the parent entity only (see Decision above).
3. ~~What should `remove` do?~~ → Delete the related entity outright (see Decision above).

### Still open
1. Should this item be scoped to just `unlink`/`remove` (the confirmation-shaped gaps, natural follow-on to item 2), with `select`/`add` (picker/creation modal) split into yet another item? Or should all four be tracked together here?
4. Any existing API endpoints already support these operations (relationship-clear on the parent, entity delete), or would this require new backend work too? Given `remove` now means a full entity delete, check whether the target entity types have delete endpoints with the same FK/cascade considerations as item 1 (e.g. a related entity that itself has child records).

### Acceptance criteria (draft — refine once scoped)
- Clicking unlink/remove in the display view shows a proper confirmation (via the item 2 shared mechanism) before doing anything destructive.
- The action actually performs the intended operation (not just a console log) and the UI reflects the result (e.g. via `FeedbackModal` success/error, consistent with the rest of the app).

---

## 4. GateStructure edit form fails to save after scanning `OpenedBlockSnapshots` (and latently `BlockSnapshots`)

- **Status**: ✅ Done (2026-09-12) — see [GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md](../specs/gate-structure-animation/GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md) Item 4
- **Area**: knk-web-app (frontend — root cause) / knk-web-api (backend — confirms the field is write-ignored anyway)
- **Reported**: 2026-09-10
- **Entity context observed**: GateStructure id `14` ("Northern Gate")
- **Decision**: Fix generically in [normalizeFormSubmission.ts](../Repository/knk-web-app/src/utils/forms/normalizeFormSubmission.ts#L279) so any current/future `GateBlockScan`-family field is covered automatically, rather than hardcoding a GateStructure-specific exclusion. Cover **both** `blockSnapshots` and `openedBlockSnapshots` in the same change (not just `openedBlockSnapshots`), since both are confirmed to share the identical bug via the same `WorldBoundFieldRenderer.tsx` code path.

### Symptom
Editing an existing Gate Structure and saving fails after a block scan has populated the "opened block snapshots" field (the separately-scanned fully-open shape, see [ROTATION_GAP_FILL_DESIGN.md](../specs/gate-structure-animation/ROTATION_GAP_FILL_DESIGN.md)). The `PUT /api/GateStructures/{id}` request returns a 400 with two validation errors.

### Repro steps
1. Open the Gate Structure edit form for a `DRAWBRIDGE`/rotation-type gate (or any gate configured with the "opened block scan" field/step).
2. Run the in-game block scan for the opened/open-state shape (creates a `GateOpenedBlockScan` world task).
3. Once the scan completes, the form field shows "Previously scanned: N blocks (Success)".
4. Save/submit the form.
5. Request fails with HTTP 400.

### Evidence
Response body:
```json
{
    "gateStructureDto": ["The gateStructureDto field is required."],
    "$.OpenedBlockSnapshots": [
        "The JSON value could not be converted to System.Collections.Generic.List`1[knkwebapi_v2.Dtos.GateOpenedBlockSnapshotDto]. Path: $.OpenedBlockSnapshots | LineNumber: 0 | BytePositionInLine: 2133."
    ]
}
```
Relevant fragment of the submitted payload (`PUT /api/GateStructures/14`):
```json
"OpenedBlockSnapshots": { "status": "Success", "blockCount": 32, "scannedAt": "2026-09-10T21:46:22.380Z" }
```

### Root cause (fully confirmed by reading both frontend and backend source)
This is **one bug with two visible symptoms**, not two separate problems:

1. **Frontend produces the wrong shape for this field.** [WorldBoundFieldRenderer.tsx:219-230](../Repository/knk-web-app/src/components/Workflow/WorldBoundFieldRenderer.tsx#L219-L230) extracts the result of a completed `GateBlockScan`/`GateOpenedBlockScan` world task and — by design, per the comment at lines 222-223 ("snapshots are already persisted server-side; the field only needs a small summary so 'already scanned' state survives a saved/resumed draft") — stores a lightweight summary object `{ status, blockCount, scannedAt }` as the field's value, instead of the actual list of block snapshots. This summary is useful for the UI (shown again at [line 715-720](../Repository/knk-web-app/src/components/Workflow/WorldBoundFieldRenderer.tsx#L715-L720): "Previously scanned: N blocks").
2. **Nothing strips this summary back out before submission.** `FormWizard.tsx`'s submit path ([flattenAllStepsData → normalizeFormSubmission → onComplete](../Repository/knk-web-app/src/components/FormWizard/FormWizard.tsx#L1719-L1758)) passes this field's value straight through into the entity payload keyed by its field name (`OpenedBlockSnapshots`), with no awareness that `GateBlockScan`/`GateOpenedBlockScan`-type fields hold a UI-only summary rather than real submittable data. `handleComplete` in [FormWizardPage.tsx:763-851](../Repository/knk-web-app/src/pages/FormWizardPage.tsx#L763-L851) then sends that payload as-is to the entity API.
3. **Backend rejects it at JSON deserialization time.** [GateStructureDto.OpenedBlockSnapshots](../Repository/knk-web-api/Dtos/GateStructureDtos.cs#L838-L839) is typed `List<GateOpenedBlockSnapshotDto>?`. A JSON object (not an array) can't deserialize into that type, so `System.Text.Json` throws during model binding — this produces the `$.OpenedBlockSnapshots` conversion error.
4. **The "gateStructureDto is required" error is a side effect of #3, not a separate issue.** Because the whole request body fails to deserialize, [`Update(int id, [FromBody] GateStructureDto gateStructureDto)`](../Repository/knk-web-api/Controllers/GateStructuresController.cs#L127-L128) never gets a bound object — `gateStructureDto` stays null, which trips ASP.NET Core's implicit "required" check on the action parameter, adding the second error message. Fixing #1/#2 makes both messages disappear together.

### Important confirming detail: the backend never uses this field for writes anyway
Checked [GateStructureMappingProfile.cs:290-291](../Repository/knk-web-api/Mapping/GateStructureMappingProfile.cs#L290-L291) — the `GateStructureDto → GateStructure` mapping (used by both `CreateAsync` and `UpdateAsync`) explicitly does `.ForMember(dest => dest.BlockSnapshots, opt => opt.Ignore())` and `.ForMember(dest => dest.OpenedBlockSnapshots, opt => opt.Ignore())`. **Whatever is sent for these two fields on create/update is silently discarded by AutoMapper.** Real snapshot persistence happens exclusively through the dedicated `AddBlockSnapshotsAsync`/`AddOpenedBlockSnapshotsAsync` service methods (called elsewhere, presumably by the world-task completion flow when the scan finishes in-game), not through the generic entity `PUT`. This means the frontend was never able to usefully "save" scan data through this form field to begin with — sending it in the entity payload is, and always was, pointless. This confirms it's safe to simply not send these fields on entity create/update at all.

### Related latent risk
`BlockSnapshots` (the closed-state scan, `GateBlockScan` task type) is handled by the **exact same code path** in `WorldBoundFieldRenderer.tsx` (both task types are grouped together as `GATE_BLOCK_SCAN_TASK_TYPES`, per the comment at lines 50-57). It stores the identical `{ status, blockCount, scannedAt }` summary shape and will hit the identical deserialization failure the next time someone re-edits a gate after running the closed-state block scan and its field value is present in form state at submit time. This wasn't reported yet, likely just because that particular repro hasn't been hit, not because the code differs. Any fix should cover both fields.

### Proposed solution (decided)
Strip `blockSnapshots`/`openedBlockSnapshots` (or more generally, any field backed by a `GateBlockScan`/`GateOpenedBlockScan`-type field renderer) out of the entity payload before it's sent to the API, inside [normalizeFormSubmission.ts](../Repository/knk-web-app/src/utils/forms/normalizeFormSubmission.ts#L279). Since the backend ignores these fields on write regardless (confirmed above via the `Ignore()` mappings), omitting them from the payload has no functional downside — the UI summary itself already fully serves its "already scanned" display purpose from local form state without ever needing to round-trip through the entity API. Both fields are covered in the same change, not just `openedBlockSnapshots`.

### Open question for the reporter
1. Confirm understanding: is it correct that the actual scanned block data is *only* ever written to the DB via the world-task completion flow (calling `AddBlockSnapshotsAsync`/`AddOpenedBlockSnapshotsAsync` directly), and the entity form's `PUT`/`POST` was never meant to carry this data? This assumption underpins the "safe to just omit" decision above.

### Acceptance criteria (draft — refine once fix location is chosen)
- Editing and saving a Gate Structure after running either block scan no longer produces a 400/validation error.
- The "Previously scanned: N blocks (status)" UI summary continues to work exactly as before (draft resume, display) — only the final entity submission payload changes.
- No regression to the dedicated snapshot endpoints (`AddBlockSnapshotsAsync`/`AddOpenedBlockSnapshotsAsync` and their callers).

---

## 5. Support for multiple gate doors per gate structure

- **Status**: ✅ Complete (2026-09-13) except for one deliberately deferred piece - building entity 14's real second (lateral/vertical) door, blocked on real in-game geometry rather than any remaining code work. See [GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md](../specs/gate-structure-animation/GATESTRUCTURE_QOL_IMPLEMENTATION_PLAN.md) Item 5 for full details, including a live-dev-server-verified concurrency bug fix found along the way.
- **Area**: knk-plugin (gate structure entity system)
- **Reported**: 2026-09-11
- **Entity context observed**: GateStructure id `14` ("Northern Gate", see item 4)
- **Sequencing decision**: Build this item (the `GateDoor` entity) **before** starting item 6 (region-geometry work), so polygon/region data lands directly on the new per-door model instead of requiring a second migration later.
- **State model decision**: Each `GateDoor` tracks its own open/closed/jammed/health/destroyed state independently (this is the default — e.g. entity 14's drawbridge and lateral door open/close on separate triggers). However, `GateStructure` needs a **cascading force-state operation** that overrides all of its child doors' states at once, for two concrete cases:
  1. An in-game command or web-app action (permission-gated) that forces a structure-wide state change, cascading to every `GateDoor` on it.
  2. The future **Siege** minigame: when a `GateStructure` is used as a capturable objective, capturing it must destroy (or otherwise force-transition) all of its `GateDoor`s as one structure-level event, not door-by-door.
  This means the state machine design isn't purely per-door — it needs an explicit `GateStructure`-level override path that's designed in from the start, not retrofitted later for Siege.
- **Migration decision**: Automatic — existing single-door `GateStructure` rows (e.g. entity 14 today) get wrapped into one default `GateDoor` row by a migration script. No manual admin re-authoring required; existing gates keep working unchanged after the migration.

### Current limitation
A gate structure entity currently supports only **one** movable gate door.

### Desired improvement
A single gate structure should be able to define **multiple independent moving gate doors**, each with its own full set of configuration fields:
- Anchor point
- Reference point 1
- Reference point 2
- Access point
- Any other fields currently required per-door

### Example use case — Entity ID 14
This existing gate structure should have **two** gate doors:
1. **Drawbridge gate** — on the front of the structure.
2. **Lateral (vertical) door** — on the inside of the gate, moving up/down.

Currently the entity can only represent one of these. The data model and animation logic need to be restructured so a gate structure holds a *list* of gate doors, each independently configured and animated.

### Proposed solution direction: new entity `GateDoor`
Supporting multiple doors requires introducing a new entity (working name: `GateDoor`) to hold the per-door data, including:
- **State fields**: opened / closed / jammed state, health, destroyed state
- **Respawn behavior**: respawn boolean (whether the door respawns after destruction), respawn rate
- **Block region data**: gate door blocksnapshot region (used for the region-based scanning described in item 6), blocksnapshot collection (if still required after item 6's improvements are implemented)
- **Info hover display**: info hover display location, plus the associated info display hover settings

Each `GateDoor` instance belonging to a `GateStructure` should support **individual CRUD operations** — doors can be added, edited, or removed independently of one another and of the parent gate structure.

### Resolved questions (2026-09-11 planning meeting)
1. ~~Per-door or shared state?~~ → Per-door, plus a structure-level cascading override (see State model decision above).
3. ~~Migration path?~~ → Automatic wrap (see Migration decision above).

### Still open
2. How does this interact with item 4's `blockSnapshots`/`openedBlockSnapshots` payload-stripping fix — does the per-door block region data introduced here replace those fields, or sit alongside them?
4. Concrete design for the `GateStructure` → all-`GateDoor`s force-state cascade: is it a single method/event (`GateStructure.forceState(newState)`) that iterates child doors, or does each door subscribe to structure-level events? Needs enough design rigor to support the future Siege capture-destroys-all-doors case without rework.
5. Permission model for the in-game command / web-app button that triggers a structure-wide forced state change — new permission node(s) needed?

### Acceptance criteria (draft — refine once scoped)
- A `GateStructure` can hold a list of `GateDoor` records, each independently configured (anchor/ref1/ref2/access point, state, respawn, block region, hover display) and independently state-tracked.
- Each `GateDoor` supports create/read/update/delete independent of its parent structure and of other doors on the same structure.
- `GateStructure` supports a cascading force-state operation affecting all child `GateDoor`s at once, usable both by an admin-triggered command/button and (later) by the Siege minigame's capture event.
- Entity 14 can be reconfigured to have both a drawbridge door and a lateral door, animating independently, while still able to be forced into a single state (e.g. all-destroyed) as one structure-level action.
- A migration automatically wraps existing single-door `GateStructure` rows into one default `GateDoor` each, with no behavior change for existing gates.

---

## 6. Non-rectangular gate door shapes via WorldGuard regions

- **Status**: Ready for detailed design — capture approach and scope decided 2026-09-11; FLOOD_FILL confirmed non-viable by live test 2026-09-12; blocked only on item 5 landing first (sequencing decision, see item 5)
- **Area**: knk-plugin (gate structure entity system)
- **Reported**: 2026-09-11
- **Assessment**: See [WORLDGUARD_REGION_FEASIBILITY.md](../specs/gate-structure-animation/WORLDGUARD_REGION_FEASIBILITY.md) (2026-09-11, updated 2026-09-12 with the FLOOD_FILL test result) for the full codebase-grounded feasibility assessment. Summary below.
- **Decision**: WorldEdit-only capture (Option 2), with polygon/cuboid vertices persisted in KnK's own DB. **Additional requirement from the planning meeting**: the stored region must be re-loadable back into a WorldEdit session for editing (round-trip, not one-way capture-only) — an admin needs to be able to pull up an existing gate door's region and redraw/adjust it with WorldEdit tooling, not just define it once. Rotation-type (DRAWBRIDGE) gates **are in scope for v1** — Mechanism 1's rotation rasterizer (`rasterizeRotationFrame`) will need to be generalized for polygon footprints as part of this item, not deferred. Gate door geometry regions stay independent of the existing WG-backed access-control regions (`RegionClosedId`/`RegionOpenedId`) — confirmed, no unification.

### Current limitation
The block-scanning system (e.g. in the "sliding grid" type gate) uses the anchor point, reference point 1, and reference point 2 to calculate/scan the physical blocks that make up the gate door in its **closed** position. This approach only supports **rectangular** gate door shapes.

### Desired improvement
Replace the three-point rectangular scan with a **WorldGuard region** as the definition of the gate door's block area. This region could be:
- A rectangular region (as today), or
- A **polygon region**

This lets the admin define the gate door shape freely (rectangular, polygonal, or otherwise), and the system scans all blocks inside that region to capture the gate door's moving parts — the same way it does today with the three-point method, just generalized.

The same approach should apply to the **open** state: if the shape/dimensions differ between open and closed states, that open-state region is captured the same way. The animation between the two states is then calculated/interpolated from the two captured block sets.

### Feasibility assessment — complete
Full write-up: [WORLDGUARD_REGION_FEASIBILITY.md](../specs/gate-structure-animation/WORLDGUARD_REGION_FEASIBILITY.md). Key findings:

- **This isn't a new-dependency decision.** `knk-plugin` already has a hard `depend` on WorldGuard and a `softdepend` on WorldEdit (`knk-paper/src/main/resources/plugin.yml`), and WorldGuard already backs the plugin's core territory model (`RegionDomainResolver`, `WorldGuardRegionTracker`). There's also an existing, complete, tested pipeline for "draw a WorldEdit selection → persist as a WorldGuard region" (`WgRegionIdTaskHandler`), currently used for district/town regions — the exact mechanism this item would need, already built.
- **A non-rectangular mode may already exist.** `GeometryDefinitionMode.FLOOD_FILL` (`GateBlockScanTaskHandler.java`) already produces non-rectangular block sets via material-boundary BFS, live and unit-tested. **Before scoping any new work, confirm whether the reported use case is already served by `FLOOD_FILL`** — this could close the item outright.
- **Animation is mostly already shape-agnostic.** Per-block position math (`GateFrameCalculator.calculateBlockPosition`) and open/closed-state pairing (`GateBlockPairing`, a nearest-neighbor matcher already tolerant of mismatched block counts) don't assume rectangular, scan-order-paired geometry. Two rectangle-specific choke points remain regardless of which capture option is chosen: `GateFrameCalculator.isWithinGeometryBounds` (box-shaped clip check) and Mechanism 1's rotation gap-fill `rasterizeRotationFrame` (rectangle-specific rasterization for rotating/DRAWBRIDGE-type gates — the single biggest effort driver in this item).
- **Recommendation**: Option 2 (WorldEdit-only capture, with polygon/cuboid vertices persisted in KnK's own DB rather than WorldGuard's region store) as the default direction — it keeps gate geometry decoupled from the unrelated, already-existing `RegionClosedId`/`RegionOpenedId` access-control regions while still reusing WorldEdit's hardened selection/containment code. Option 1 (full WorldGuard region, reusing `WgRegionIdTaskHandler`'s pattern near-verbatim) is a solid fallback if Option 2's new persistence work proves costlier than expected. Option 3 (fully custom) is **not recommended** — highest effort and reliability risk, for a portability benefit that's largely moot given WorldGuard's already-permanent role in the plugin.

### Resolved questions (2026-09-11 planning meeting; #1 confirmed by live test 2026-09-12)
1. ~~Does `FLOOD_FILL` already solve the reported use case?~~ → **No — confirmed by direct test.** Bypassed the form entirely: temporarily flipped entity 14 to `FLOOD_FILL` via the API, triggered the real headless `GateBlockScan` task against the live drawbridge, and tried four seed/material-whitelist combinations (unfiltered plane-constrained scan, whitelisted to the door's actual material, widened whitelist, and reseeded from the rectangle's interior). Every attempt found at most 2-3 mutually-adjacent blocks of matching material — the door's construction (mixed full blocks/slabs/stairs) doesn't have the face-to-face contiguity BFS flood fill requires, no matter the material set. Entity 14 was restored to its original config afterward. Full detail in the assessment doc §3. This closes the "maybe no new work needed" question — region-based capture is confirmed necessary.
2. ~~Should geometry regions ever unify with access-control regions?~~ → No, keep independent (see Decision above).
3. ~~Is rotation-type polygon support required for v1?~~ → Yes, included in v1 (see Decision above) — this raises the effort estimate for Mechanism 1's rasterizer generalization from "optional follow-up" to "required for this item."
4. ~~Sequence relative to item 5?~~ → Item 5 (`GateDoor` entity) ships first; this item's region data lands on `GateDoor` directly.

### Still open
5. Concrete design for round-trip region editing: how does the plugin re-hydrate a stored polygon/cuboid vertex list into an active WorldEdit `LocalSession` so an admin can redraw it? (`WgRegionIdTaskHandler`'s existing region-rename flow is the closest precedent to adapt, even though it operates on WG regions rather than WE-only sessions.)

### Acceptance criteria (draft — refine during detailed design)
- Admins can define a gate door's block region (open and closed state) as an arbitrary polygon or cuboid via WorldEdit selection, for both rotating and non-rotating gate types.
- An existing gate door's stored region can be reloaded into WorldEdit for editing, not just captured once.
- Animation (including Mechanism 1's rotation rasterization) interpolates correctly between arbitrary-shaped open/closed block sets.
- Lands on the `GateDoor` entity from item 5, not the legacy single-door `GateStructure` fields.

---

## 7. Snow layer handling during gate door animation

- **Status**: Ready — solution decided 2026-09-11, not yet implemented
- **Area**: knk-plugin (gate structure animation task)
- **Reported**: 2026-09-11
- **Entity context observed**: GateStructure id `14` (drawbridge)
- **Decision**: Snow layers are silently removed (no item drop) — consistent with how door blocks themselves move without dropping items. Check is presence/absence only; no need to track or preserve exact snow layer height (1-8).

### Symptom
Snow layers on top of gate door blocks are not accounted for during animation, causing two related bugs:
1. **Snow sitting on an open horizontal gate door**: when a gate door is open and horizontal (e.g. a drawbridge lying flat), snow can accumulate on top of the gate door blocks.
2. **Floating snow on close**: when the gate door then closes while covered in snow, the gate door blocks are removed/moved without removing the snow layer above them — leaving the snow layer floating in mid-air ("hovering" snow) since it has no support block beneath it anymore.

### Repro steps (entity 14, drawbridge)
1. Gate opens → drawbridge is horizontal → let snow accumulate on top of the door blocks (naturally, in-game).
2. Gate closes → door blocks move away → snow layer remains behind, hovering with nothing underneath it.

### Proposed solution
In the animation task, add a check that:
- Detects a snow layer on the current gate door block positions, **and**
- Detects a snow layer on the position where a gate door block is about to be placed during the animation step,

and **removes the snow** in either case before/as the block move happens, so no hovering snow layers are left behind.

### Resolved questions (2026-09-11 planning meeting)
1. ~~Track/restore removed snow, or discard?~~ → Silent removal, no item drop.
2. ~~Account for snow layer height?~~ → No, presence/absence check is sufficient.

### Acceptance criteria
- Snow on top of an open horizontal gate door no longer causes floating/hovering snow blocks after the gate closes.
- Fix applies generically to all gate door animation steps (not just entity 14/drawbridge), including both the "blocks currently at" and "blocks about to be placed at" positions during each animation tick.

---

## 8. InventoryMenu pagination and search/filter are command-only, not real in-GUI controls

- **Status**: Open — needs research, explicitly not decided yet (user request 2026-09-22)
- **Area**: knk-plugin (InventoryMenu engine, `knk-paper/.../paper/menu/`, `knk-paper/.../paper/commands/MenuDebugCommand.java`)
- **Reported**: 2026-09-22, by the developer directly (not discovered during use — flagged proactively while reviewing InventoryMenu Phase 5)
- **Related docs**: `docs/specs/inventory-menu/{IMPLEMENTATION_PLAN.md,DESIGN_REVIEW.md}`; see the InventoryMenu Phase 2 and Phase 5 entries in `ACTIVE_SESSIONS.md`'s "Recently completed" table for full implementation detail

### Symptom
Two InventoryMenu capabilities that should eventually be normal in-GUI interactions are currently only reachable via chat commands:
- **Pagination** (Phase 2): advancing a section's page requires typing `/knk menu page next|prev <sectionName>` in chat. There is no clickable next/previous-page item inside the menu itself.
- **Search/filter** (Phase 5): starting a search or setting a filter facet requires `/knk menu search <sectionName> [clear]` / `/knk menu filter <sectionName> <facetKey> [clear]`, which then prompts a chat-based text capture for the actual query/value.

The developer does **not** want commands to remain the main or only way to trigger these — they should be triggerable from inside the menu itself (e.g. a clickable pagination arrow item, a clickable search/filter button), with commands at most a secondary/debug path, not the primary UX.

### Root cause (why it's built this way today, not a bug)
This was an explicit, documented scope boundary in both phases, not an oversight:
- `RuntimeMenuSection.resolveSlots` and `MenuSession`'s per-section page/content-query state are fully built and working — the *engine* underneath both features is real and functional.
- What's missing is **click-driven** invocation. Clicking is currently a dead end for this: `MenuClickListener` identifies the clicked item and checks permissions, but Phase 6 ("Conditional actions") is what wires an actual `ActionRegistry` so a click can *do* something, and Phase 7 ("Preset section/item library") is what turns `MenuSectionKind.SEARCH_BAR`/`FILTER_BAR` (and a pagination-arrow item) into real, clickable, reusable components. Both phases still lay ahead per `IMPLEMENTATION_PLAN.md`'s phasing.
- The `/knk menu ...` commands were built as a **dev harness** specifically to exercise/verify the engine on a live server before Phase 6/7 exist (see `MenuDebugCommand`'s own class-level javadoc, which says this explicitly) — not as the intended permanent player-facing interaction model. That intent apparently wasn't communicated clearly enough; this item makes it explicit and trackable.

### Open questions (for the research agent to investigate, not for whoever wrote this item to have guessed at)
1. What's the right Bukkit-native in-GUI control for pagination arrows and a search/filter trigger — a plain clickable `MenuItem` (glass pane / arrow icon) wired through Phase 6's `ActionRegistry` once it exists, given `RuntimeMenuItem.slotOverride()` already supports pinning a nav item to a fixed slot outside pagination? Confirm this is sufficient before assuming anything more exotic (a scrollable/draggable widget, hotbar-based paging, etc.) is needed.
2. For search/filter specifically: even with a clickable trigger *item*, Minecraft still has no native in-inventory text-input widget. Phase 5's `ChatCaptureManager`-based chat capture (confirmed reused rather than an anvil GUI, see the Phase 5 `ACTIVE_SESSIONS.md` entry's open question 3) already accounts for "click closes the GUI, then chat captures the query, then the menu reopens" — research whether that's still the right *text-input* mechanism once the *trigger* becomes a real click instead of a command, or whether an anvil-GUI-style capture (which keeps a inventory-like screen open the whole time, no jarring close/reopen) is worth reconsidering now that the trigger itself is changing. This is a genuine re-open of DESIGN_REVIEW.md §2.1's original anvil-GUI suggestion, not a foregone conclusion either way.
3. Sequencing: does this get folded into Phase 6 (click → action wiring) and Phase 7 (preset components) as originally planned, or does it warrant being pulled forward as its own small phase once Phase 6 lands `ActionRegistry`, given the developer's stated priority that command-only isn't acceptable as a resting state? Flag a recommendation rather than deciding unilaterally — this affects phase ordering the developer may want to weigh in on.
4. Should the existing `/knk menu ...` commands be kept permanently as a secondary/admin/debug path (useful for headless testing, support, or when a menu's UI is broken) once real in-GUI controls exist, or retired once they're redundant? Lean toward keeping them (cheap, already built, useful for #1's live-testing loop) unless research finds a reason not to — but confirm rather than assume.

### Acceptance criteria
- Not yet defined — this item is a research request, not a ready-to-implement spec. Acceptance criteria should be added once the research agent's findings are reviewed and a direction is chosen.

---

<!-- Add new items below using the same structure: Status / Area / Reported date / Symptom / Repro steps / Evidence / Affected files / Root cause / Proposed solution / Open questions / Acceptance criteria -->
