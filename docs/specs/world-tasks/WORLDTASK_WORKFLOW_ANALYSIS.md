# WorldTask Workflow Analysis & Improvements

## Problem Summary

When completing a WorldTask (e.g., RegionCreate) in the hybrid form workflow:
1. ✅ Task completes successfully in Minecraft
2. ✅ Web app polls and receives completed task with `outputJson`
3. ❌ Form field does NOT auto-populate with extracted data
4. ❌ Only task status tag updates; no user feedback about field population
5. ❌ User is left wondering if something failed

## Root Causes

### 1. **Field Extraction Logic is Implicit**
**File:** [WorldBoundFieldRenderer.tsx](WorldBoundFieldRenderer.tsx#L45-L55)
```typescript
// Current approach
const extractedValue = output.regionId || output.value || output.result;
```
- Uses multiple fallback attempts without clear specification
- No mapping between task type and expected output field
- Assumes `regionId` exists but spec shows it should be more generic

### 2. **No Step Completion Signal After Task Completion**
**File:** [WorldBoundFieldRenderer.tsx](WorldBoundFieldRenderer.tsx#L39-L56)
- When task completes and field is populated via `onChange()`, nothing tells the form/workflow that the step should auto-complete
- Contrast with `WorldTaskCta.tsx` which calls `workflowClient.completeStep()` after task completes

### 3. **Weak Component State Management**
- No flag to prevent re-polling after extraction
- No clear signal that task-to-field binding was successful
- Missing visual feedback that field was auto-populated

### 4. **Decoupled Task Lifecycle**
- TaskId is set but task result extraction happens silently
- No callback or event emitted when extraction succeeds
- Parent component (FormWizard) doesn't know field was auto-populated

## Test Case Flow

From your logs, the successful path shows:
```
1. Admin opens District form (formConfigId=13)
2. Admin enters Name "WorldTaskTest 18-01-26"
3. Admin selects Location (Cinix)
4. Admin reaches WgRegionId field → clicks "Send to Minecraft"
5. Task created: id=14, linkCode="WXRTMT"
6. Admin goes to Minecraft, runs: /knk task claim WXRTMT
7. Task state: Pending → InProgress → Completed
8. outputJson contains: {"fieldName":"WgRegionId","regionId":"tempregion_worldtask_14",...}
9. Web app polls and receives completed task
10. ❌ But WgRegionId field remains empty
11. ❌ Only status tag changes to "Completed"
12. Admin completes step manually
```

## Expected Behavior (Post-Fix)

```
9. Web app polls and receives completed task
10. ✅ Component extracts regionId from outputJson
11. ✅ Component calls onChange(extractedValue)
12. ✅ Form field is populated visually
13. ✅ Component shows confirmation: "✓ Field auto-populated"
14. ✅ Component calls onCompletion callback
15. ✅ Parent FormWizard can optionally auto-advance step
```

## Implementation Strategy

### Phase 1: Fix Field Extraction & Completion
1. **Add explicit task-type → output-field mapping**
   - `RegionCreate` → extract `regionId`
   - `LocationCapture` → extract `locationId`
   - etc.

2. **Add completion callback to WorldBoundFieldRenderer**
   - On successful extraction, call parent callback
   - Allow parent to auto-complete step if desired

3. **Add extraction success flag**
   - Prevent re-polling after successful extraction
   - Show visual confirmation

### Phase 2: Sync with WorldTaskCta Pattern
- Both components should follow same polling + completion flow
- Ensure consistent feedback to parent about task state changes

### Phase 3: Backend Validation (Optional)
- Consider returning `extractedFieldName` in WorldTaskDto
- Allow backend to specify which field to populate
- Add validation that outputJson contains expected fields

## Files to Modify

1. **[WorldBoundFieldRenderer.tsx](WorldBoundFieldRenderer.tsx)** (Primary)
   - Fix extraction logic with task-type mapping
   - Add extraction success flag
   - Add completion callback
   - Improve feedback UI

2. **[WorldTaskCta.tsx](WorldTaskCta.tsx)** (Reference)
   - Already has `onCompleted` callback
   - Consider extracting common logic to hook

3. **[FormWizard.tsx](FormWizard.tsx)** (Integration)
   - Pass completion callbacks to field renderers
   - Handle auto-advance on task completion (optional)

## Code Changes Summary

| Component | Change | Priority |
|-----------|--------|----------|
| WorldBoundFieldRenderer | Add task-type mapping for field extraction | HIGH |
| WorldBoundFieldRenderer | Add `extractionSucceeded` state flag | HIGH |
| WorldBoundFieldRenderer | Add `onExtracted` callback | HIGH |
| WorldBoundFieldRenderer | Improve completion UI (checkmark, success message) | MEDIUM |
| WorldBoundFieldRenderer | Stop polling after extraction | MEDIUM |
| FormWizard | Accept & pass task completion callbacks | MEDIUM |
| WorldTaskCta | Extract common polling logic (future) | LOW |

