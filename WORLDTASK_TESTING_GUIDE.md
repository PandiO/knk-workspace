# WorldTask Field Population - Testing & Usage Guide

## Overview

The WorldTask feature has been enhanced to properly handle field auto-population when tasks complete in Minecraft. This guide explains what was fixed and how to test it.

---

## What Was Fixed

### Problem Statement
When an admin completed a WorldTask in Minecraft (e.g., creating a WorldGuard region), the web app would:
- ✅ Detect task completion
- ✅ Receive the result data (outputJson)
- ❌ **NOT populate the form field** with the result
- ❌ Show only status changes with no clear feedback

### Root Causes (Now Fixed)
1. **Implicit field extraction logic** → Now uses explicit task-type mapping
2. **No completion signal** → Added `onTaskCompleted` callback
3. **Continued polling after success** → Now stops after extraction
4. **Weak error handling** → Added user-facing error messages
5. **No extraction feedback** → Added visual confirmation UI

---

## Implementation Details

### 1. Task Output Field Mapping

The component now maintains a clear mapping of task types to their output fields:

```typescript
'RegionCreate' → expects 'regionId' in outputJson
'LocationCapture' → expects 'locationId' in outputJson
'StructureCapture' → expects 'structureId' in outputJson
```

**Why this matters:**
- Explicit and maintainable
- Easy to add new task types
- Prevents silent failures
- Handles typos (e.g., 'ReagionCreate')

### 2. Extraction Function

```typescript
function extractTaskResult(task: WorldTaskReadDto, taskType: string): any
```

**Extraction order:**
1. Look up expected field name from mapping
2. Return value if found in outputJson
3. Fall back to common field names (regionId, locationId, etc.)
4. Return null if no value found (triggers error UI)

### 3. State Lifecycle

```
Task Created (status: Pending)
    ↓
Polling starts → shows claim code
    ↓
Admin claims in Minecraft (status: InProgress)
    ↓
Polling continues → shows "waiting for completion"
    ↓
Task completes in Minecraft (status: Completed, outputJson populated)
    ↓
Extraction logic runs
    ↓
    ├─ Success → field populated, UI shows checkmark, polling stops ✅
    ├─ Extraction error → UI shows error message, allows retry ⚠️
    └─ Task failed → UI shows failure, allows retry ❌
```

### 4. UI Feedback States

#### Pending (Waiting for Minecraft)
```
🎮 Ready for Minecraft!

Claim Code:
WXRTMT

In Minecraft, type:
/knk task claim WXRTMT

💡 This code links your web session to your in-game actions
```

#### InProgress (Minecraft performing task)
```
Task Status: InProgress

Claimed by: __pandi__ on localhost

Waiting for task to complete in Minecraft...
```

#### Completed - Processing
```
⏳ Processing task result...
```

#### Completed - Success
```
✓ WgRegionId: tempregion_worldtask_14

✓ Auto-populated

✅ Task completed! Field has been auto-populated with the result.
```

#### Completed - Error
```
⚠️ Result Processing Error

Could not extract result from task output
```

#### Failed
```
❌ Task Failed

Error message from Minecraft

[Try Again button]
```

---

## Testing Steps

### Test 1: Basic RegionCreate Flow (District Form)

**Setup:**
- Have Minecraft server running with WorldGuard plugin
- Have web app running on http://localhost:3000

**Steps:**
1. Open http://localhost:3000 → Forms → District → Create New
2. Fill out fields:
   - Name: "Test District 1"
   - Location: Select a location from dropdown
3. Click Next/Continue to reach "Spawn Location" step
4. You should see:
   - "WgRegionId" field
   - "Send to Minecraft" button (green)
5. Click "Send to Minecraft"
6. **Observe:**
   - ✅ Green box appears with "🎮 Ready for Minecraft!"
   - ✅ Claim code displayed prominently (e.g., "WXRTMT")
   - ✅ Instructions: "/knk task claim WXRTMT"
7. Join Minecraft server and run:
   ```
   /knk task claim WXRTMT
   ```
8. **Observe:**
   - Status changes to "InProgress"
   - Shows "Claimed by: __pandi__"
   - Shows "Waiting for task to complete..."
9. Wait for plugin to complete task (should happen within 10 seconds)
10. **Key Test Point - OBSERVE:**
    - [ ] ✅ WgRegionId field becomes populated (shows: "✓ WgRegionId: tempregion_worldtask_14")
    - [ ] ✅ Green badge appears: "✓ Auto-populated"
    - [ ] ✅ Success message: "✅ Task completed! Field has been auto-populated"
    - [ ] ✅ No more polling happening (check Network tab - requests stop)
11. Can now click "Next" or "Complete" to finish form

**Expected Outcome:** ✅ PASS if all checkmarks are true

---

### Test 2: Error Recovery

**Setup:** Same as Test 1

**Modify step 9:**
- Let the plugin fail (e.g., invalid region name, permissions issue)

**Observe:**
- [ ] ✅ Status becomes "Failed"
- [ ] ✅ Red box appears: "❌ Task Failed"
- [ ] ✅ Error message from Minecraft is displayed
- [ ] ✅ Red button "Try Again" appears
- [ ] ✅ Clicking "Try Again" resets state and form can be resubmitted

**Expected Outcome:** ✅ PASS if all checkmarks are true

---

### Test 3: Extraction Error (Malformed Output)

**Note:** This requires manual backend testing or a task that produces invalid output.

**If outputJson is missing or invalid:**
- [ ] ✅ Status shows "Completed"
- [ ] ✅ Yellow box appears: "⏳ Processing task result..."
- [ ] ✅ Then red error box: "⚠️ Result Processing Error"
- [ ] ✅ Message: "Could not extract result from task output"
- [ ] ✅ Field remains empty
- [ ] ✅ Admin can retry

**Expected Outcome:** ✅ PASS if all checkmarks are true

---

### Test 4: Field Values Persist Across Polling

**Setup:** Same as Test 1, successful completion

**Steps:**
1. Complete test 1 successfully
2. Field is now populated with regionId
3. Switch tabs or refresh page (⚠️ Warning: don't do this on form page)
4. Return to form
5. **Observe:**
   - [ ] ✅ Field still has value
   - [ ] ✅ "✓ Auto-populated" badge is gone (extraction state not persisted)
   - [ ] ✅ Can proceed with form

**Expected Outcome:** ✅ PASS (form state persistence is separate concern)

---

### Test 5: Multiple World-Bound Fields

**Setup:** Form with multiple world tasks (if available)

**Example:** District form with both WgRegionId AND LocationCapture tasks

**Steps:**
1. Reach step with multiple world-bound fields
2. Submit first task (WgRegionId)
3. Wait for completion
4. **Observe:**
   - [ ] ✅ First field populates
   - [ ] ✅ Success message appears for first field
5. Submit second task (LocationId)
6. Wait for completion
7. **Observe:**
   - [ ] ✅ Second field populates independently
   - [ ] ✅ Each field manages its own state
   - [ ] ✅ Both success messages appear

**Expected Outcome:** ✅ PASS if all checkmarks are true

---

## Browser DevTools Checklist

### Network Tab
- [ ] POST /api/WorldTasks (create task)
- [ ] GET /api/WorldTasks/{id} (polling requests every 2 seconds)
- [ ] Polling stops after status becomes "Completed" ✅

### Console Tab
- [ ] Console shows: "✓ WorldTask {id} result extracted and field populated: tempregion_worldtask_14"
- [ ] No error messages about extraction failures
- [ ] No repeated warnings about polling

### React DevTools (if installed)
- [ ] WorldBoundFieldRenderer component shows state:
  - `extractionSucceeded: false` → `true` after completion
  - `extractionError: null` stays null on success
  - `taskId: 14` remains set
  - `task.status: "Completed"` final state

---

## Troubleshooting

### Issue: Field not populating but task shows "Completed"

**Possible Causes:**
1. outputJson in task response is missing
2. outputJson doesn't contain expected field (regionId, locationId, etc.)
3. Field is being populated but visual update delayed

**How to debug:**
1. Open Browser DevTools → Network tab
2. Find last GET /api/WorldTasks/{id} request
3. Click it → Response tab
4. Check `outputJson` value:
   ```json
   {
     "fieldName":"WgRegionId",
     "regionId":"tempregion_worldtask_14",
     "createdAt":1768726529094,
     "worldName":"world_KNK-DEV"
   }
   ```
5. Check if `regionId` field is present
6. If missing → Plugin issue (not creating output)
7. If present → Component state issue (console errors)

### Issue: Polling continues forever

**Possible Causes:**
1. Task completed but extraction failed
2. outputJson is invalid JSON
3. Browser console has errors

**How to debug:**
1. Open Browser DevTools → Console tab
2. Look for error messages
3. Check extractionError in React state
4. If error message appears in UI, that's the issue
5. Click "Try Again" button if available

### Issue: Claim code not displayed

**Possible Causes:**
1. Task creation failed
2. linkCode is null in response
3. Task status never becomes "Pending"

**How to debug:**
1. Open Browser DevTools → Network tab
2. Find POST /api/WorldTasks request
3. Check Response:
   - Is `linkCode` field populated?
   - Is `status: "Pending"`?
4. If both present, refresh form page
5. If not, check backend API response

---

## Performance Considerations

### Before Fix
- Component would poll indefinitely even after field populated
- Network requests: ~1 req/2sec forever
- User would have to manually complete form step

### After Fix
- Component polls only until extraction succeeds
- Network requests: stops after status="Completed"
- Estimated reduction: 95%+ of unnecessary requests (after ~10 second task)

### Example
- Task takes 10 seconds to complete
- Polling every 2 seconds = 5 requests
- After fix: all 5 requests still happen (necessary)
- Before fix: would continue for minutes if user leaves field on page

---

## Configuration & Customization

### Adding New Task Type

To add support for a new task type:

1. **Update TASK_OUTPUT_FIELD_MAP:**
```typescript
const TASK_OUTPUT_FIELD_MAP: Record<string, string> = {
    'RegionCreate': 'regionId',
    'LocationCapture': 'locationId',
    'MyNewTaskType': 'myFieldName',  // ← Add here
};
```

2. **Plugin must output this field:**
```json
{
  "fieldName":"MyField",
  "myFieldName":"extracted_value",
  "otherData":"..."
}
```

3. **Test using Test 1 process**

### Customizing UI Messages

Messages are in JSX blocks:
- Pending: Line ~150
- InProgress: Line ~165
- Completed Success: Line ~185
- Error: Line ~193
- Failure: Line ~203

---

## Related Documentation

- [WORLDTASK_WORKFLOW_ANALYSIS.md](WORLDTASK_WORKFLOW_ANALYSIS.md) - Technical deep dive
- [Minecraft Plugin Integration](../Repository/knk-plugin-v2/docs/PLUGIN_WORLDTASK_INTEGRATION.md)
- [API Contract](../Repository/knk-web-api-v2/SWAGGER_CONTRACT.md)

---

## Questions?

If something isn't working as expected:
1. Check browser console for error messages
2. Check Network tab for API responses
3. Refer to troubleshooting section above
4. Check if task completed successfully in Minecraft server logs

