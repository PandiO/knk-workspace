# Multi-Layer Dependency Resolution v2.0 - Admin Guide

**Version:** 1.0  
**Date:** February 14, 2026  
**Audience:** System Administrators, Form Configuration Administrators  
**Last Updated:** February 14, 2026

---

## Table of Contents

1. [Overview](#overview)
2. [Key Concepts](#key-concepts)
3. [Getting Started](#getting-started)
4. [Creating Validation Rules with Dependencies](#creating-validation-rules-with-dependencies)
5. [Using the PathBuilder](#using-the-pathbuilder)
6. [Configuration Health Panel](#configuration-health-panel)
7. [Common Scenarios](#common-scenarios)
8. [Troubleshooting](#troubleshooting)
9. [FAQ](#faq)

---

## Overview

Multi-Layer Dependency Resolution allows you to create validation rules that depend on values from other form fields. This enables sophisticated validation across related entities.

**Example:**
When a user selects a Town, a Location field must be validated to ensure it falls within that Town's protected region.

### Key Features

- ✅ Select dependencies via visual PathBuilder dropdowns
- ✅ Automatic validation of dependency paths
- ✅ Health panel shows configuration issues with fix suggestions
- ✅ Support for single-level relationships (v1)
- ✅ Clear error messages in forms

---

## Key Concepts

### What is a Dependency?

A dependency is a value from another form field that a validation rule needs to function.

**Analogy:**
```
Think of it like a recipe:
  Recipe: "LocationInsideRegion"
  Ingredient: "Must have Town region ID"
  How to get ingredient: "Use the Town field value → get its wgRegionId"
```

### Dependency Path Notation

Paths use dot notation to navigate relationships:

```
Town.wgRegionId
├─ Town: The entity you're getting a value from
└─ wgRegionId: The property on that entity
```

**Valid v1 Paths (Single-Hop):**
```
✅ Town.wgRegionId
✅ District.name
✅ Structure.coordinates
```

**Invalid v1 Paths (Multi-Hop, Future v2):**
```
❌ Town.Districts[0].name        (multi-hop, not in v1)
❌ District.Town.wgRegionId      (multi-hop, not in v1)
❌ Town                           (missing property, needs dot)
```

### Form Context

The "form context" is the data currently in the form as the user fills it out.

**Example Form Context:**
```json
{
  "Town": {
    "id": 1,
    "name": "Springfield",
    "wgRegionId": "town_1",
    "boundaryPoints": [...]
  },
  "District": {
    "id": 5,
    "name": "North District"
  },
  "Location": {
    "x": 100,
    "y": 64,
    "z": -200
  }
}
```

---

## Getting Started

### Step 1: Access Form Configuration

1. Navigate to **Admin** → **Forms** → **Form Configuration**
2. Select the form you want to edit
3. Click **"Edit Validation Rules"** button

### Step 2: Create a New Validation Rule

1. Click **"+ New Rule"** button
2. Fill in basic information:
   - **Field:** Select which field this rule validates
   - **Validation Type:** Choose LocationInsideRegion, ConditionalRequired, etc.
   - **Error Message:** Write an error message (can include placeholders like {regionName})

### Step 3: Add Dependency (Optional)

1. If your validation rule needs values from other fields:
   - Click **"Add Dependency"** button
   - Select the dependency using **PathBuilder**
   - Click **"Save Rule"**

---

## Creating Validation Rules with Dependencies

### Example 1: Location Must Be Inside Town Region

**Goal:** When user selects a Town and then enters a Location, validate that the location is within the town's protected region.

**Setup:**

1. **Field:** Location
2. **Validation Type:** LocationInsideRegion
3. **Error Message:** "Location {coordinates} is outside {regionName}'s boundary"
4. **Dependency Path:** `Town.wgRegionId`

**How It Works:**
```
User selects Town → Gets wgRegionId via dependency path
User enters Location → System validates: is this location inside wgRegionId?
If outside → Show error: "Location (100, 64, -200) is outside town_1's boundary"
```

### Example 2: Conditional Required Field

**Goal:** If Town is selected, District Name becomes required.

**Setup:**

1. **Field:** District Name
2. **Validation Type:** ConditionalRequired
3. **Error Message:** "District name is required for {townName}"
4. **Dependency Path:** `Town.name`

**How It Works:**
```
User doesn't select Town → District Name optional
User selects Town → District Name becomes required
If user tries to save without District Name:
  Show error: "District name is required for Springfield"
```

### Example 3: Regional Containment Check

**Goal:** Ensure new structure is within its parent district's boundaries.

**Setup:**

1. **Field:** Structure Location
2. **Validation Type:** LocationWithinDistrict
3. **Error Message:** "Structure location must be within {districtName} district"
4. **Dependency Path:** `District.name`

---

## Using the PathBuilder

The PathBuilder is a visual tool for selecting dependency paths without typing.

### How to Use PathBuilder

1. Click **"Select Dependency"** in the Add Dependency dialog
2. **PathBuilder Window Opens:**

```
┌─────────────────────────────────────┐
│ Select Dependency                   │
├─────────────────────────────────────┤
│                                     │
│ Step 1: Select Entity               │
│ ┌───────────────────────────────┐   │
│ │ ▼ Town                        │   │
│ └───────────────────────────────┘   │
│                                     │
│ Available properties for Town:      │
│ • id (number)                       │
│ • name (string)                     │
│ • wgRegionId (string)               │
│ • description (string)              │
│ • boundaryPoints (array)            │
│ • createdAt (datetime)              │
│                                     │
│ Step 2: Select Property             │
│ ┌───────────────────────────────┐   │
│ │ ▼ wgRegionId                  │   │
│ └───────────────────────────────┘   │
│                                     │
│ Selected Path: Town.wgRegionId      │
│                                     │
│ [Cancel]  [Select]                  │
└─────────────────────────────────────┘
```

### Step-by-Step

1. **Step 1:** Click dropdown to select an entity (e.g., "Town")
   - Shows all entities available in this form

2. **Step 2:** Click property dropdown to select a property (e.g., "wgRegionId")
   - Shows all properties on the selected entity
   - Properties are organized by type (scalars, relationships, arrays)

3. **Step 3:** See the complete path: `Town.wgRegionId`

4. **Step 4:** Click "Select" to save the dependency

### Filtering Properties

Properties are displayed with their type information:

```
✓ id (number)           - Safe for all validations
✓ name (string)         - Safe for display in messages
✓ wgRegionId (string)   - Safe for region lookups
✓ boundaryPoints (array) ⚠️ Advanced - v2 feature
```

---

## Configuration Health Panel

The Health Panel checks your form configuration for common issues and inconsistencies.

### Accessing the Health Panel

1. Open Form Configuration
2. Click **"Configuration Health"** button in the toolbar
3. Health panel opens with analysis results

### Understanding Health Check Results

```
Health Check Results for: District Creation Form
═════════════════════════════════════════════════

✅ Field Alignment (3/3 valid)
   All form fields reference valid entities

✅ Property Existence (5/5 paths valid)
   ✓ Town.wgRegionId exists
   ✓ District.name exists
   ✓ Structure.coordinates exists

⚠️  Field Order (1 warning)
   Warning: Field "Location" (Step 3) depends on "Town" (Step 1)
   → Correct order ✓ (dependency comes first)

⚠️  Required Fields (1 warning)
   Warning: Town.name is required by the entity but not enforced in form
   → Recommendation: Mark "Town" as Required in form

✅ Circular Dependencies (0 detected)
   No circular dependencies found

✅ Valid Paths (0 errors)
   All property paths are valid

Status: HEALTHY ✓ (1 warning)
```

### Interpreting Red Issues (Errors)

❌ **Red issues block form usage.** Fix them before deploying the form.

**Example Error:**
```
Property 'invalidProp' not found on Town entity
Available properties: id, name, wgRegionId, description, ...
Fix: Update the dependency path to use a valid property
```

### Interpreting Yellow Warnings (Recommendations)

⚠️ **Yellow warnings are recommendations.** Forms work, but functionality may be incomplete.

**Example Warning:**
```
Town.name is required by entity but not enforced in form
→ Users might create towns without names
→ Either mark Town as required, or make it optional on the entity
```

### Common Health Check Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| "Property not found" | Typo in dependency path | Use PathBuilder to select valid property |
| "Field ordering" | Dependency field comes after dependent field | Reorder form steps |
| "Required misalignment" | Entity requires field, but form doesn't enforce it | Mark field as required in form |
| "Circular dependency" | Field A depends on B, B depends on A | Remove one dependency |

---

## Common Scenarios

### Scenario 1: District Creation with Location Validation

**Requirements:**
- User selects a Town
- User enters a District name
- User marks a location on a map
- Location must be validated to be within Town region

**Form Structure:**
```
Step 1: Town Selection
  └─ Town field (required, select)

Step 2: District Details
  └─ District Name (required, text)

Step 3: Location
  └─ Location (required, coordinates)
  └─ Validation Rule: "LocationInsideRegion"
     └─ Depends on: Town.wgRegionId
```

**Validation Rule Setup:**
```
Field: Location
Validation Type: LocationInsideRegion
Error Message: "Location {coordinates} is outside {regionName}"
Dependency Path: Town.wgRegionId
Active: Yes
```

### Scenario 2: Conditional Building Permissions

**Requirements:**
- Some validation only applies if a specific Town is selected
- Different towns have different rules
- Rules are pre-configured, not custom per-instance

**Form Structure:**
```
Step 1: Location Details
  └─ Town (required, select)
  └─ Building Type (required, select)

Step 2: Validation (depends on Town)
  └─ Building Location (conditional, coordinates)
  └─ Rule: "BuildingInZone" (active only for certain towns)
     └─ Depends on: Town.buildingZoneId
```

**Setup:**
```
1. Create validation rule with Dependency Path: Town.buildingZoneId
2. In ConfigJson, add: "activeTowns": ["town_1", "town_3"]
3. Validation only runs if Town is in the activeTowns list
```

### Scenario 3: Nested Entity Validation (Future v2)

**Note:** This is planned for v2. Not supported in v1.

**Future Example:**
```
Validation depends on: District.Town.wgRegionId
Step: Multi-hop path navigation (v2 feature)
```

---

## Troubleshooting

### Issue 1: "Property Not Found" Error

**Symptom:**
```
Error: "Property 'townRegionId' not found on Town entity"
Available properties: id, name, wgRegionId, description
```

**Cause:** Typo in the property name or property doesn't exist on the entity

**Solution:**
1. Go back to the validation rule
2. Click "Edit Dependency"
3. Use PathBuilder to re-select the property
4. Common typos to check:
   - `townRegionId` → should be `wgRegionId`
   - `rgn_id` → should be `wgRegionId`

### Issue 2: "Entity Not Found" Error

**Symptom:**
```
Error: "Entity 'Township' not found"
```

**Cause:**
- Entity doesn't exist in system metadata
- Typo in entity name
- Entity was deleted

**Solution:**
1. Verify the entity exists: **Admin** → **Entities** → Search for "Town"
2. If entity was deleted, recreate it or update form to use different entity
3. Use PathBuilder dropdown which only shows valid entities

### Issue 3: Validation Not Running

**Symptom:**
- User fills in form fields
- No validation error appears even though dependency is invalid

**Possible Causes:**
1. **Rule is inactive** - Check if rule has `Active: Yes`
2. **Dependency field is empty** - User hasn't filled in the dependency field yet
3. **Rule not assigned to field** - Check field configuration

**Solution:**
1. Open Form Configuration
2. Check Health Panel for issues
3. Verify rule is marked `Active: Yes`
4. Verify dependency field is in an earlier form step
5. Try submitting form to see all validation errors

### Issue 4: Circular Dependency Detected

**Symptom:**
```
Health Panel Error: "Circular dependency detected: Field A → Field B → Field A"
```

**Cause:** Two rules create a cycle (Field A depends on B, Field B depends on A)

**Solution:**
1. Open the Health Panel and locate the warning
2. Click "View Details" to see which rules are involved
3. Remove one of the dependencies
4. Re-run Health Check to verify

**Example Fix:**
```
BEFORE (Circular):
  Rule 1: Location depends on Town
  Rule 2: Town depends on Location  ← Problem

AFTER (Fixed):
  Rule 1: Location depends on Town  ← Keep this one
  (Remove Rule 2)
```

---

## FAQ

### Q: Can I use the same dependency path in multiple rules?

**A:** Yes! It's actually common. For example:

```
Rule 1: Location field depends on Town.wgRegionId
Rule 2: Building Type field depends on Town.wgRegionId
```

Both rules can use the same dependency path. The system will resolve it once and cache the value.

### Q: What happens if a user doesn't fill in the dependency field?

**A:** The dependent validation rule will show as "pending" (not yet validated).

```
User hasn't selected Town yet
  → Location field validation shows: "Waiting for Town selection"
  → Red exclamation icon indicates pending state
  → User can't submit until all dependencies are satisfied
```

### Q: Can I use complex expressions in dependency paths?

**A:** In v1, no. Paths are simple property navigation only.

```
Supported:   Town.wgRegionId
NOT supported: Town.wgRegionId || District.wgRegionId
NOT supported: Town.wgRegionId?.length > 0
```

v2 will support more complex scenarios.

### Q: What if the dependency value is null?

**A:** The validation will not run until the dependency field has a value.

```
User hasn't selected a Town (null)
  → System can't resolve dependency
  → Validation rule shows as "pending"
  → Form prevents submission with clear message: "Select Town first"
```

### Q: How does error message interpolation work?

**A:** Placeholders in error messages are automatically filled with resolved values.

```
Error Message Template: "Location {coordinates} is outside {regionName}"

When validation fails:
  {coordinates}  → Replaced with user's entered location: "(100, 64, -200)"
  {regionName}   → Replaced with dependency value: "Springfield Region"

Final Error: "Location (100, 64, -200) is outside Springfield Region's boundary"
```

### Q: Does the system auto-suggest placeholders for error messages?

**A:** Yes! When you enter an error message, the system shows available placeholders:

```
┌─────────────────────────────────┐
│ Error Message                   │
├─────────────────────────────────┤
│ Location                        │
│ Available placeholders:         │
│ • {coordinates}  (from input)   │
│ • {regionName}   (from Town)    │
│ • {townName}     (from Town)    │
└─────────────────────────────────┘
```

### Q: What's the difference between v1 and v2?

**v1 (Current):**
- ✅ Single-hop paths: `Town.wgRegionId`
- ✅ Simple entities and scalars
- ✅ Single-level relationships
- ❌ No multi-hop: `Town.District.wgRegionId`
- ❌ No collection operators: `Towns[first].wgRegionId`

**v2 (Planned):**
- ✅ Everything in v1
- ✅ Multi-hop paths
- ✅ Collection operators: `[first]`, `[last]`, `[all]`
- ✅ Complex validation results with per-item breakdowns

### Q: Can I use dependencies with custom validation types?

**A:** Only with validation types that support dependencies. Not all validation types use dependencies.

**Supports Dependencies:**
- LocationInsideRegion
- LocationWithinDistrict
- ConditionalRequired
- RegionContainment

**Doesn't Support Dependency Paths:**
- MaxLength
- MinValue
- Pattern
- Custom scripts (use validation-specific logic instead)

Check your validation type's documentation.

### Q: How are dependency values cached?

**A:** System uses in-memory caching with a 5-minute TTL (time-to-live).

```
User loads form:
  1. Fetch dependency values from server → Cache for 5 minutes
  2. User stays on form > 5 minutes
  3. Cache expires → Next change triggers fresh fetch
```

This improves performance for users filling out long forms.

### Q: Is there a way to see what dependencies my form has?

**A:** Yes! Use the Configuration Health Panel.

1. Open Form Configuration
2. Click "Configuration Health"
3. Scroll to "Dependencies" section to see all rules with paths

---

## Support & Feedback

**For Issues:**
- Check this guide's Troubleshooting section
- Review the Configuration Health Panel for specific errors
- Contact your system administrator

**For Feature Requests:**
- Multi-hop dependencies? Planned for v2
- Custom validation types with dependencies? Submit feature request
- Collection operators? Coming in v2

---

**Guide Version:** 1.0  
**Last Updated:** February 14, 2026  
**Next Review:** August 2026
