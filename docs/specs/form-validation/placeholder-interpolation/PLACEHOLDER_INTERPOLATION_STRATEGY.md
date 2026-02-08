# Placeholder Variable Interpolation Strategy

**Purpose:** Analyze where and when placeholder variables in validation error/success messages should be converted to actual values across the form-validation feature implementation.

**Created:** February 7, 2026  
**Status:** Analysis Complete

---

## Context: Placeholder Variables

### What Are Placeholders?

Admins configure validation rules with **configurable error/success messages containing placeholder variables**:

```json
{
  "validationType": "LocationInsideRegion",
  "errorMessage": "Location {coordinates} is outside {townName}'s boundaries. Please select a location within the region.",
  "successMessage": "Location is within town boundaries ✓"
}
```

### Common Placeholder Examples

From the QUICK_REFERENCE and implementation code:

| Placeholder | Validation Type | Meaning | Example Value |
|------------|-----------------|---------|----------------|
| `{regionName}` | LocationInsideRegion, RegionContainment | Parent/child region ID | `town_springfield` |
| `{coordinates}` | LocationInsideRegion | Location coordinates | `(125.5, 64.0, -350.2)` |
| `{townName}` | LocationInsideRegion, RegionContainment | Parent entity display name | `Springfield` |
| `{violationCount}` | RegionContainment | Number of boundary violations | `3` |
| `{entityName}` | Any | Parent entity name | `Town of Springfield` |

---

## Current Implementation Analysis

### 1. Minecraft Plugin (LocationTaskHandler.java)

**Location:** `validateLocationInsideRegion()` method, lines 358-429

**Current Behavior:** ✅ **Placeholders ARE interpolated at validation time**

```java
String errorMsg = rule.get("errorMessage").getAsString();
errorMsg = errorMsg.replace("{regionName}", parentRegionId);
errorMsg = errorMsg.replace("{coordinates}", 
    String.format("(%.2f, %.2f, %.2f)", location.getX(), location.getY(), location.getZ()));

// Also replaces in success case
player.sendMessage("§a✓ Location is inside region: " + parentRegion.getId());
```

**Characteristics:**
- Placeholders replaced **in the plugin** before returning to player
- Values extracted from **local context** (player location, WorldGuard regions)
- Messages sent directly to player chat
- No API communication of placeholder-containing messages

---

### 2. Web App FormWizard (FormWizard.tsx)

**Location:** Not yet analyzed in code, but documented in MINOR_GAPS_INVESTIGATION_RESULTS.md

**Current Behavior:** ✅ **Frontend has interpolation utility ready**

From `FieldRenderer.tsx` (line 187):
```tsx
const message = interpolatePlaceholders(validationResult.message, validationResult.placeholders);
```

**Characteristics:**
- Frontend has `interpolatePlaceholders()` utility function
- Expects `ValidationResultDto` with:
  - `message` field (contains placeholders: `"Location {coordinates} is outside {townName}..."`)
  - `placeholders` field (map: `{ "coordinates": "(125.5, 64.0, -350.2)", "townName": "Springfield" }`)
- Interpolation happens in **FieldRenderer component** (display time)

---

### 3. Backend API (knk-web-api-v2)

**Status:** ❓ **Not yet analyzed in implementation code**

**Expected Design (from spec):**
- FieldValidationService receives validation request with form context
- Performs validation logic (e.g., check location inside region)
- Returns `ValidationResultDto` with:
  - `message` containing **template with placeholders**
  - `placeholders` dictionary with actual values
  - `isValid`, `isBlocking` flags

---

## Design Decision: WHERE to Interpolate?

### Option A: **Backend API Handles All Interpolation** ❌ NOT RECOMMENDED

**Flow:**
```
Backend API validates
  → Extracts actual values from form context + database
  → Replaces placeholders in message
  → Returns message: "Location (125.5, 64.0, -350.2) is outside Springfield's boundaries..."
  → Frontend receives already-interpolated message
```

**Pros:**
- Single point of interpolation logic
- Simpler frontend code

**Cons:**
- ❌ **Plugin doesn't receive interpolated messages** (plugin has its own validation logic)
- ❌ Plugin must duplicate interpolation code
- ❌ Breaks separation of concerns (API shouldn't know about display language/format)
- ❌ Cannot accommodate plugin-specific formatting (Minecraft color codes, etc.)

---

### Option B: **Frontend Handles All Interpolation** ❌ PARTIALLY CORRECT

**Flow:**
```
Backend API validates
  → Returns message with placeholders: "Location {coordinates} is outside {townName}..."
  → Returns placeholders map: { coordinates: "...", townName: "..." }
  → Frontend interpolates at display time
  → Frontend receives final message from FieldRenderer
```

**Pros:**
- ✅ Frontend can control formatting
- ✅ Supports i18n (internationalization)
- ✅ Decouples API from display logic

**Cons:**
- ❌ **Doesn't solve the plugin problem**
- ❌ Plugin still needs its own interpolation logic
- ⚠️ Requires API to return both message template AND placeholder values

---

### Option C: **Dual Strategy - Backend PREPARES, Point-of-Use INTERPOLATES** ✅ RECOMMENDED

**Flow for Backend API Validation (FormWizard usage):**
```
1. Backend validates field value against rule
2. Backend extracts placeholder values from:
   - Validated field (e.g., Location coordinates)
   - Form context (dependency field values)
   - Database (parent entity properties like name)
3. Backend returns:
   {
     "isValid": false,
     "message": "Location {coordinates} is outside {townName}'s boundaries...",
     "placeholders": {
       "coordinates": "(125.5, 64.0, -350.2)",
       "townName": "Springfield",
       "regionName": "town_springfield"
     },
     "isBlocking": true
   }
4. Frontend receives this DTO
5. FieldRenderer interpolates using utility: interpolatePlaceholders(message, placeholders)
6. User sees final message: "Location (125.5, 64.0, -350.2) is outside Springfield's boundaries..."
```

**Flow for Plugin WorldTask Validation (Minecraft usage):**
```
1. Plugin receives WorldTask with validation rules in InputJson
2. InputJson includes:
   {
     "validationContext": {
       "validationRules": [
         {
           "validationType": "LocationInsideRegion",
           "errorMessage": "Location {coordinates} is outside {townName}...",
           "dependencyFieldValue": { /* Town entity */ }
         }
       ]
     }
   }
3. Plugin's validateLocationInsideRegion() method:
   a. Extracts values from local context (WorldGuard, player location)
   b. Replaces placeholders inline (like current implementation)
   c. Displays interpolated message to player in chat
4. Plugin also calls API to validate (for confirmation)
5. If API returns different result, plugin handles conflict
```

**Pros:**
- ✅ **Backend prepares values but doesn't interpolate** (clean separation)
- ✅ **Frontend interpolates at display time** (FormWizard scenario)
- ✅ **Plugin interpolates at validation time** (WorldTask scenario)
- ✅ Each layer formats for its own context (HTML, Minecraft chat codes)
- ✅ Supports i18n naturally
- ✅ Both paths work independently

**Cons:**
- ⚠️ Requires plugin to mirror some backend interpolation logic
- ⚠️ Must keep interpolation code in sync (frontend utility + plugin code)

---

## Implementation Details

### Backend API Responsibility

**In `FieldValidationService.ValidateAsync()`:**

```csharp
public async Task<ValidationResultDto> ValidateAsync(
    FieldValidationRule rule, 
    object fieldValue, 
    FormSubmissionProgressDto formContext)
{
    // 1. Execute validation logic
    var isValid = await ValidateLocationInsideRegion(rule, fieldValue, formContext);
    
    // 2. Extract placeholder values (do NOT interpolate)
    var placeholders = new Dictionary<string, string>();
    
    if (!isValid)
    {
        // Extract from various sources
        var dependencyField = formContext.GetFieldValue(rule.DependsOnFieldId);
        var parentEntity = await _entityService.GetAsync(dependencyField);
        
        var location = fieldValue as LocationDto;
        var region = await _worldGuardService.GetRegionAsync(parentEntity.WgRegionId);
        
        // Collect placeholder values
        placeholders["coordinates"] = $"({location.X:F1}, {location.Z:F1})";
        placeholders["townName"] = parentEntity.DisplayName;
        placeholders["regionName"] = region.Id;
    }
    
    // 3. Return template + placeholders (NOT interpolated message)
    return new ValidationResultDto
    {
        IsValid = isValid,
        Message = rule.ErrorMessage,  // Contains {coordinates}, {townName}, etc.
        Placeholders = placeholders,
        IsBlocking = rule.IsBlocking
    };
}
```

**Key Principle:** Backend extracts AND RETURNS placeholder values but does NOT perform String.Replace()

---

### Frontend Utility Function

**Location:** `knk-web-app/src/utils/placeholderInterpolation.ts`

```typescript
export const interpolatePlaceholders = (
  message: string | undefined,
  placeholders?: { [key: string]: string }
): string => {
  if (!message) return '';
  if (!placeholders) return message;
  
  let result = message;
  Object.entries(placeholders).forEach(([key, value]) => {
    result = result.replace(`{${key}}`, value || '');
  });
  return result;
};
```

**Usage in FieldRenderer:**

```tsx
const ValidationFeedback: React.FC<{validationResult}> = ({ validationResult }) => {
  const finalMessage = interpolatePlaceholders(
    validationResult.message,
    validationResult.placeholders
  );
  
  return (
    <div className="text-red-700">
      {finalMessage}
    </div>
  );
};
```

---

### Plugin Interpolation (Minecraft)

**Location:** `LocationTaskHandler.validateLocationInsideRegion()`

**Current Implementation is Correct:** ✅

```java
String errorMsg = rule.get("errorMessage").getAsString();

// Extract placeholder values from LOCAL context
String parentRegionId = extractParentRegionId(depValue, config);
ProtectedRegion parentRegion = regionManager.getRegion(parentRegionId);
BlockVector3 blockLoc = BlockVector3.at(location.getX(), location.getY(), location.getZ());

// Inline interpolation (at validation time)
errorMsg = errorMsg.replace("{regionName}", parentRegion.getId());
errorMsg = errorMsg.replace("{coordinates}", 
    String.format("(%.2f, %.2f, %.2f)", location.getX(), location.getY(), location.getZ()));

// Send interpolated message to player
player.sendMessage("§c" + errorMsg);
```

**Why This Is Correct for Plugin:**
- Plugin has immediate access to WorldGuard data and player location
- No way to fetch additional entity data (e.g., parent Town name) without API call
- User expects immediate feedback (cannot wait for API)
- Should NOT delay validation for API round-trip

---

## Implementation Plan

### Phase 1: Backend API (knk-web-api-v2)

1. **Create ValidationResultDto:**
   ```csharp
   public class ValidationResultDto
   {
       public bool IsValid { get; set; }
       public string Message { get; set; }  // Template with {placeholders}
       public Dictionary<string, string> Placeholders { get; set; } = new();
       public bool IsBlocking { get; set; }
   }
   ```

2. **Update FieldValidationService:**
   - Implement `ValidateLocationInsideRegion()` to extract placeholder values
   - Implement `ValidateRegionContainment()` to extract placeholder values
   - Implement `ValidateConditionalRequired()` for simple string matching
   - **Key:** Extract values, return template + map. Do NOT call String.Replace()

3. **Update ValidationRuleController:**
  - Implement `POST /api/field-validations/validate-field` endpoint
   - Accepts: rule config, field value, form context
   - Returns: ValidationResultDto with template + placeholders

---

### Phase 2: Frontend (knk-web-app)

1. **Create interpolation utility:**
   - File: `src/utils/placeholderInterpolation.ts`
   - Function: `interpolatePlaceholders(message, placeholders)`
   - Simple string replacement logic

2. **Update FieldRenderer:**
  - Call `/api/field-validations/validate-field` on field change (debounced)
   - Receive ValidationResultDto
   - Call `interpolatePlaceholders()` before display
   - Show final message to user

3. **Update FormWizard:**
   - Add validation state management
   - Track pending validations
   - Block progression if blocking validation fails

---

### Phase 3: Minecraft Plugin (knk-plugin-v2)

**No changes needed!** Current implementation in `LocationTaskHandler.validateLocationInsideRegion()` is already correct.

The plugin:
- Receives validation rules with placeholder templates in InputJson
- Interpolates values it has locally (coordinates, region IDs)
- For parent entity properties (like Town name), it can either:
  - **Option A:** Accept missing value (skip placeholder if not available)
  - **Option B:** Make optional API call to fetch parent entity
  - **Option C:** Have web app pre-resolve values and pass in InputJson

---

## Placeholder Values - Data Sources

### LocationInsideRegion

| Placeholder | Source | Availability | Notes |
|------------|--------|--------------|-------|
| `{coordinates}` | Field value (Location object) | Always available | Format: `(X, Y, Z)` |
| `{regionName}` | WorldGuard API (plugin) or DB (backend) | Dependent field filled | Region ID |
| `{townName}` | Parent entity from DB | Dependent field filled | Entity display name |

### RegionContainment

| Placeholder | Source | Availability | Notes |
|------------|--------|--------------|-------|
| `{regionName}` | Field value | Always available | Child region ID |
| `{violationCount}` | WorldGuard boundary check | When validation fails | Count of out-of-bounds points |
| `{townName}` | Parent entity from DB | Dependent field filled | Parent entity name |

### ConditionalRequired

| Placeholder | Source | Availability | Notes |
|------------|--------|--------------|-------|
| `{fieldName}` | Form metadata | Always available | Display name of required field |
| `{dependencyValue}` | Form context | Dependency filled | Value that triggered requirement |

---

## Validation: API Contract Update

The API contract for validation responses should be updated:

```http
POST /api/field-validations/validate

Request:
{
  "fieldValidationRuleId": 42,
  "fieldValue": { "x": 100, "y": 64, "z": -200 },
  "formContext": { /* current form data */ }
}

Response (200 OK):
{
  "isValid": false,
  "message": "Location {coordinates} is outside {townName}'s boundaries.",
  "placeholders": {
    "coordinates": "(100, 64, -200)",
    "townName": "Springfield"
  },
  "isBlocking": true
}
```

---

## Summary: Three-Layer Interpolation Strategy

| Layer | Component | When | How | Output |
|-------|-----------|------|-----|--------|
| **Backend** | FieldValidationService | Validation execution | Extract values, return template | ValidationResultDto with placeholders map |
| **Frontend** | FieldRenderer | Display time | Call interpolatePlaceholders() utility | HTML with interpolated message |
| **Plugin** | LocationTaskHandler | Player chat | String.replace() inline | Chat message with color codes |

---

## Key Decision: Backend Returns Template, Not Interpolated Message

**Reason:** Enables each consumer to format as needed:
- Frontend: Uses plain text, can add HTML styling
- Plugin: Adds Minecraft color codes (§c, §a, §e)
- Future: Mobile app, API docs, etc. can format differently

**This is the industry standard** (similar to i18n/localization pattern where backends return message IDs or templates, clients do the final rendering).
