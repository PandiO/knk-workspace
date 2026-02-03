# World Task Feature Integration Summary

**Date**: January 18, 2026  
**Commit Reference**: 324fc4b - feat(workflow): add multi-step wizard UI with Minecraft task monitoring  
**Status**: ✅ Integrated & Cleaned Up

## Overview

The Minecraft World Task feature allows form fields to trigger interactive tasks in a Minecraft server, enabling users to create/select world-bound entities (e.g., WorldGuard regions, locations) while filling out web forms. The completed task result automatically populates the corresponding form field.

## Architecture

### Key Components

#### 1. **FormWizard.tsx** (Main Integration Point)
Location: `src/components/FormWizard/FormWizard.tsx`

**Responsibilities:**
- Renders form fields using `FieldRenderer` component
- For each field, checks for world task configuration in `field.settingsJson`
- If world tasks are enabled and `workflowSessionId` is provided, renders `WorldTaskCta` component
- Handles field value updates and form progression

**Key Method:**
```typescript
const parseWorldTaskSettings = (settingsJson?: string): { enabled?: boolean; taskType?: string } => {
    if (!settingsJson) return {};
    try {
        const parsed = JSON.parse(settingsJson);
        if (parsed && typeof parsed === 'object' && parsed.worldTask) {
            return {
                enabled: !!parsed.worldTask.enabled,
                taskType: parsed.worldTask.taskType
            };
        }
    } catch {}
    return {};
};
```

#### 2. **WorldTaskCta.tsx** (Call-to-Action Component)
Location: `src/components/Workflow/WorldTaskCta.tsx`

**Responsibilities:**
- Renders "Send to Minecraft" button for world-bound fields
- Creates `WorldTask` via API when user clicks button
- Polls task status every 3 seconds
- Displays claim code for Minecraft players
- Shows task progress (Pending → InProgress → Completed/Failed)
- Automatically notifies parent when task completes

**Key Features:**
- Task claim code display with copy-to-clipboard
- Player claim status display
- Auto-polling with cleanup on unmount
- Automatic step completion notification via `workflowClient.completeStep()`

#### 3. **WorldBoundFieldRenderer.tsx** (Unused - Legacy Component)
Location: `src/components/Workflow/WorldBoundFieldRenderer.tsx`

**Note**: This component was created during initial implementation but is **not used** in the FormWizard pipeline. The `WorldTaskCta` component supersedes this with better integration. It remains in the codebase as reference but is not actively used.

#### 4. **FieldRenderer.tsx** (Field-Level Rendering)
Location: `src/components/FormWizard/FieldRenderers.tsx`

**Responsibilities:**
- Renders individual form fields based on `FieldType` enum
- Supports standard types: String, Integer, Boolean, DateTime, Decimal, Enum, Object, List
- Supports Minecraft pickers: HybridMinecraftMaterialRefPicker, HybridMinecraftEnchantmentRefPicker
- Does **not** directly handle world tasks (delegated to FormWizard level)

### Field Configuration (settingsJson)

To enable world tasks on a form field, configure `settingsJson` with:

```json
{
  "worldTask": {
    "enabled": true,
    "taskType": "RegionCreate"
  }
}
```

**Supported Task Types:**
- `RegionCreate` / `ReagionCreate` (handles typo variant) → outputs `regionId`
- `LocationCapture` → outputs `locationId`
- `StructureCapture` → outputs `structureId`
- Custom types prefixed with `Verify${fieldName}`

### Data Flow

```
FormWizardPage
  ↓
FormWizard (receives workflowSessionId, userId, entityName)
  ↓
FieldRenderer (renders field based on FieldType)
  ↓
+ WorldTaskCta (if world task enabled + workflowSessionId active)
  ├─ User clicks "Send to Minecraft"
  ├─ Creates WorldTask via worldTaskClient.create()
  ├─ Polls worldTaskClient.getById() every 3s
  ├─ Minecraft player claims task (via claim code in game)
  ├─ Plugin completes task with result in outputJson
  ├─ FormWizard detects task.status === 'Completed'
  ├─ Extracts result value using TASK_OUTPUT_FIELD_MAP
  ├─ Updates form field value via onChange callback
  └─ Triggers workflowClient.completeStep() to advance workflow
```

### Integration Points

#### FormWizardPage to FormWizard
```tsx
<FormWizard
  entityName={selectedTypeName}
  entityId={entityId}
  formConfigurationId={...}
  userId={userId}
  workflowSessionId={workflowSessionId}  // ← Enables world tasks
  onStepAdvanced={(args) => { /* handle step progression */ }}
  onComplete={(data, progress) => { /* handle form completion */ }}
/>
```

#### FormWizard Rendering Loop (Line ~750)
```tsx
orderedFields.map(field => {
  const { enabled, taskType } = parseWorldTaskSettings(field.settingsJson);
  const stepKey = computeStepKey(currentStep!, currentStepIndex);
  
  return (
    <div key={field.id}>
      {element /* FieldRenderer */}
      {enabled && workflowSessionId != null && (
        React.createElement(require('../Workflow/WorldTaskCta').WorldTaskCta, {
          workflowSessionId,
          userId: parseInt(userId || '0', 10) || 0,
          stepKey,
          fieldName: field.fieldName,
          value: currentStepData[field.fieldName],
          taskType,
          hint: worldTaskHint,
          onCompleted: () => { /* re-render if needed */ }
        })
      )}
    </div>
  );
})
```

## Usage Example: Town Creation Form

When creating a Town with world-bound fields:

1. **Step 1: General Information**
   - User enters name, description
   - No world tasks (business logic only)

2. **Step 2: Rules & Settings**
   - User sets allowEntry, allowExit flags
   - No world tasks

3. **Step 3: World Data**
   - Field: `WgRegionId` (with `worldTask: { enabled: true, taskType: "RegionCreate" }`)
     - User clicks "Send to Minecraft" button
     - Minecraft player claims code, creates WorldGuard region
     - Region ID automatically populates field
   - Field: `LocationId` (with `worldTask: { enabled: true, taskType: "LocationCapture" }`)
     - User clicks "Send to Minecraft" button
     - Minecraft player stands at desired location, confirms
     - Location ID automatically populates field

4. **Form Completion**
   - All steps completed, form data submitted to API
   - Town entity created with world-bound properties

## Removed Components

### TownCreateWizardPage.tsx (Deleted)
- **Reason**: Superseded by FormWizard integration
- **What it did**: Demonstrated world task workflow with hardcoded Town steps
- **Why removal is safe**: FormWizard now handles all workflow patterns generically via FormConfiguration
- **Removed from**: `src/App.tsx` route `/towns/create`

## Testing the Feature

### Prerequisites
1. FormConfiguration exists with world-bound fields configured
2. WorkflowSession created and passed to FormWizard component
3. Minecraft server plugin running and reachable

### Test Steps
1. Navigate to `/forms/Town` or entity form with world tasks
2. Fill out non-world-bound fields
3. On world-bound field, click "Send to Minecraft"
4. Join Minecraft server with configured user
5. Run command with claimed code: `/link-task <code>`
6. Complete task (e.g., create region, capture location)
7. Verify field value auto-populates in web form
8. Complete form submission

## Related Files

- **API Clients**: `src/apiClients/worldTaskClient.ts`, `src/apiClients/workflowClient.ts`
- **Types**: `src/types/dtos/workflow/WorkflowDtos.ts`
- **Configuration**: Form field `settingsJson` in FormConfiguration UI

## Future Enhancements

1. **Task Result Validation**
   - Add post-completion validation rules
   - Example: Verify captured location is within region

2. **Dependency Fields**
   - Support multi-field workflows
   - Example: Region task must complete before Location task

3. **Task Retry/Resume**
   - Allow resuming failed tasks
   - Support for task history/audit trail

4. **Offline Handling**
   - Queue tasks if Minecraft server is unavailable
   - Auto-retry on server reconnection

## Troubleshooting

### Task Not Appearing
- [ ] Verify `field.settingsJson` has `worldTask.enabled: true`
- [ ] Verify `workflowSessionId` is provided to FormWizard
- [ ] Check browser console for errors in `parseWorldTaskSettings`

### Task Stuck in "Pending"
- [ ] Verify Minecraft server is running and reachable
- [ ] Check Minecraft server logs for task claim failures
- [ ] Verify player has correct permissions

### Field Not Auto-Populating
- [ ] Verify task.status === 'Completed'
- [ ] Check task.outputJson for expected field name
- [ ] Verify TASK_OUTPUT_FIELD_MAP contains taskType mapping

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-18  
**Maintainer**: Copilot Implementation
