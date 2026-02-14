# Multi-Layer Dependency Resolution v2.0 - Training Materials & FAQ

**Version:** 1.0  
**Date:** February 14, 2026  
**Audience:** Form administrators, business users, support staff

---

## Quick Start Checklist

Use this checklist when setting up your first dependency resolution rule:

```
☐ Step 1: Create a new validation rule
  - Go to Form Configuration
  - Click "Edit Validation Rules"
  - Click "+ New Rule"

☐ Step 2: Fill in basic information
  - Field: Select which field to validate
  - Validation Type: Choose validation type (LocationInsideRegion, ConditionalRequired, etc.)
  - Error Message: Write a clear error message

☐ Step 3: Add dependency (if needed)
  - Click "Add Dependency"
  - Use PathBuilder to select dependency
    1. Select entity (e.g., Town)
    2. Select property (e.g., wgRegionId)
  - Path should look like: "Town.wgRegionId"

☐ Step 4: Test before deploying
  - Use Configuration Health Panel
  - Check for errors (red) and warnings (yellow)
  - Test with sample data

☐ Step 5: Deploy
  - Publish form to production
  - Monitor for errors
```

---

## 5-Minute Video Script

**Duration:** 3-5 minutes  
**Focus:** Understanding dependency resolution for form admins

---

### Scene 1: Problem Statement (0:00-0:30)

**Narration:**
"Have you ever wanted to validate a form field based on values from another field? For example, checking if a location is within a specific town's boundaries?"

**Visual:**
- Show form with Town field and Location field
- Mark Location field in red (failed validation)
- Show error message: "Location is outside region"

---

### Scene 2: Solution (0:30-1:30)

**Narration:**
"Multi-layer dependency resolution lets you create validation rules that depend on other form fields. Here's how it works:"

**Visual:**
1. Open Form Configuration
2. Select a validation rule
3. Click "Add Dependency"
4. Show PathBuilder UI
   - Select "Town" entity
   - Select "wgRegionId" property
   - Results in path: "Town.wgRegionId"

**Narration:**
"The system automatically uses the town's region ID to validate the location. If the location falls outside that region, the user sees a personalized error message."

---

### Scene 3: Example Workflow (1:30-3:00)

**Narration:**
"Let me walk through a complete example. A user is creating a new district. First, they select a town."

**Visual:**
- User selects "Springfield" from Town dropdown
- Field shows: "Town: Springfield (wgRegionId: town_1)"

**Narration:**
"Next, they mark a location on a map. Our system automatically validates that the location is within Springfield's region."

**Visual:**
- User clicks on map at coordinates (100, 64, -200)
- Location field shows: "(100, 64, -200)"
- Red error appears: "Location (100, 64, -200) is outside Springfield region"

**Narration:**
"If they try to submit, the form prevents the submission with a clear error message. Once they pick a location within Springfield, the error disappears and they can submit."

**Visual:**
- User moves map pin inside Springfield region
- Error disappears, submit button becomes enabled
- Form submits successfully

**Narration:**
"The error messages are smart - they include actual values from your form to make them more helpful."

---

### Scene 4: Key Concepts (3:00-4:00)

**Narration:**
"Here are the key concepts to remember:

**Dependency:** A value from one field that another validation rule needs.

**Path:** The way to get that value. We write it as Entity.Property, like Town.wgRegionId.

**Form Context:** The data currently in your form. When you select a Town, it's available in the form context."

**Visual:**
- Show diagram of form context
- Show boxes for each field
- Highlight how Location depends on Town

---

### Scene 5: Getting Help (4:00-4:30)

**Narration:**
"If you're not sure if your configuration is correct, use the Configuration Health Panel. It'll tell you about any issues and how to fix them.

And if you need detailed help, check the Admin Guide or contact support."

**Visual:**
- Show Configuration Health Panel
- Show different issue types (errors in red, warnings in yellow)

---

## Common Configuration Scenarios

### Scenario 1: Location Validation

**What you want:**
- User selects a town
- User marks a location
- Location must be inside town's region

**Setup steps:**

1. **Create validation rule**
   - Field: Location
   - Type: LocationInsideRegion
   - Error Message: "Location {coordinates} is outside {regionName}"

2. **Add dependency**
   - Path: Town.wgRegionId
   - This tells the system: "Use the Town's region ID for validation"

3. **Test it**
   - Select a town
   - Try marking locations inside and outside its region
   - Verify error messages show town name and coordinates

---

### Scenario 2: Conditional Required Fields

**What you want:**
- Some fields are optional by default
- But become required if a certain option is selected
- Example: "If Town is selected, District Name becomes required"

**Setup steps:**

1. **Create validation rule**
   - Field: District Name
   - Type: ConditionalRequired
   - Error Message: "District name is required for {townName}"

2. **Add dependency**
   - Path: Town.name
   - This tells the system: "District Name is only required if Town has been selected"

3. **Test it**
   - Leave Tom unselected → District Name should be optional
   - Select a Town → District Name becomes required
   - Try submitting without District Name → See error message

---

### Scenario 3: Regional Containment

**What you want:**
- New structure must be within its parent district's boundaries
- Show which district's boundaries are being checked

**Setup steps:**

1. **Create validation rule**
   - Field: Structure Location
   - Type: LocationWithinDistrict
   - Error Message: "Structure must be within {districtName}"

2. **Add dependency**
   - Path: District.name
   - This tells the system: "Use the District's name for the error message"

3. **Test it**
   - Select a district
   - Try locations inside and outside its boundaries
   - Verify error messages show correct district name

---

## Troubleshooting Flowchart

```
Is validation not working?
│
├─→ Is the rule marked ACTIVE? ──No──→ Enable the rule
│
├─→ Is the dependency field filled? ──No──→ Tell user to fill dependency field first
│
├─→ Can you see the rule in Health Panel? ──No──→ Check if rule is assigned to right form/field
│
├─→ Does Health Panel show errors? ──Yes──→ Fix errors shown in Health Panel
│
└─→ Check the logs ──→ Contact support with rule ID and error message
```

---

## Frequently Asked Questions

### Q: What's the difference between "resolved", "pending", and "error" statuses?

**A:** These show whether the dependency was successfully resolved:

- **Resolved** ✅: Dependency found and ready to use
  - Example: User selected Town → system got its wgRegionId
  
- **Pending** ⏳: Waiting for user input
  - Example: Location validation depends on Town, but user hasn't selected Town yet
  
- **Error** ❌: Something went wrong
  - Example: Property doesn't exist, or circular dependency detected

---

### Q: Can I see which rules depend on which fields?

**A:** Yes! In Configuration Health Panel:
```
1. Open Form Configuration
2. Click "Configuration Health"
3. Scroll to "Dependencies" section
4. See all rules with their dependency paths
```

---

### Q: What if two rules use the same dependency path?

**A:** That's fine! The system resolves it once and reuses the value.

```
Example:
  Rule 1: Location validates against Town.wgRegionId
  Rule 2: BuildingType validates against Town.wgRegionId
  
  System resolves Town.wgRegionId once, uses for both rules
```

---

### Q: What happens if I delete a field that's used as a dependency?

**A:** Configuration Health Panel will show an error:
```
Error: Field 'Town' not found

Rules affected:
  - Rule 1: Location validation
  - Rule 2: BuildingType validation

Fix: Either restore the field, or remove the dependency
```

---

### Q: Can I use complex formulas in dependency paths?

**A:** Not in v1. Paths are simple: Entity.Property

```
Supported:   Town.wgRegionId
Not supported: Town.wgRegionId || District.wgRegionId
Not supported: Town.wgRegionId?.length > 0
```

v2 will support more complex scenarios.

---

### Q: How are dependency values cached?

**A:** System caches them for 5 minutes to improve performance:

```
Minute 0: User loads form → Get values from server, cache them
Minute 3: User changes a field → Use cached values
Minute 5: Cache expires → Get fresh values from server
```

---

### Q: What if a dependency value is null?

**A:** Validation won't run until the dependency field has a value:

```
User hasn't selected Town (null)
  → System can't resolve dependency
  → Form shows: "Please select a Town first"
  → Location validation is marked "pending"
```

---

### Q: Can I use the same error message for multiple validation types?

**A:** Yes, but different types use different placeholders:

```
Error Message: "Location {coordinates} is outside {regionName}"

For LocationInsideRegion:
  {coordinates} = (100, 64, -200)
  {regionName} = town_1
  
For ConditionalRequired:
  {coordinates} might not be available
  {regionName} might not be available
  
Stick to placeholders that make sense for your validation type
```

---

### Q: What's the best practice for error messages?

**A:**

✅ **Good:**
- "Location (100, 64, -200) is outside Springfield region"
- "District name is required for Springfield"
- "Structure must be at least 10 blocks from region boundary"

❌ **Bad:**
- "Error validating location" (vague)
- "Invalid input for field 3" (no context)
- "Dependency path Town.wgRegionId is unresolved" (technical jargon)

**Formula:** "{User Action} {Condition} {Why}"
- "Location (100, 64, -200)" ← User action/data
- " is outside" ← Condition
- "Springfield region" ← Why

---

### Q: What if I need a validation that's not in the list?

**A:** You have two options:

1. **Use with existing type**: Map your validation to a similar type
   - "Must be at least X distance from boundary" → Use LocationInsideRegion type

2. **Request new type**: Contact development team
   - Document what validation you need
   - Provide example of rules that need it
   - Team will implement in future release

---

### Q: How do I know if my configuration is correct?

**A:** Use Configuration Health Panel:

1. Open Form Configuration
2. Click "Configuration Health"
3. Look for:
   - ❌ Red errors → Must fix before using
   - ⚠️ Yellow warnings → Recommended fixes
   - ✅ Green checks → All good

---

### Q: Can I test a rule before deploying?

**A:** Yes:

1. Create the rule in dev environment
2. Run Configuration Health Panel
3. Have a test user fill out the form
4. Verify validation works correctly
5. Then publish to production

---

### Q: What happens if I reorder form steps?

**A:** Configuration Health Panel will warn you if reordering breaks dependencies:

```
Warning: Location field (Step 3) depends on Town field (Step 1)
Status: ✅ Correct - dependency comes before dependent
```

If you move Town after Location:

```
Warning: Location field (Step 2) depends on Town field (Step 3)
Status: ❌ Error - dependency comes AFTER dependent
Fix: Reorder steps so Town comes before Location
```

---

### Q: What's the difference between a "rule" and a "dependency"?

**A:**

- **Rule**: A validation that must pass
  - Example: "Location must be inside region"
  
- **Dependency**: A value that a rule needs to function
  - Example: Rule needs "Town.wgRegionId" to know which region

One rule can have multiple dependencies (future v2).

---

### Q: Can I see error messages before users see them?

**A:** Yes, in two ways:

1. **In the UI during testing**: Fill out form, trigger validation
2. **In Configuration Health Panel**: See template + placeholders
   ```
   Template: "Location {coordinates} is outside {regionName}"
   Placeholders: {coordinates}, {regionName}
   ```

---

### Q: What should I do if I see a circular dependency error?

**A:**

1. **Understand the problem:**
   ```
   Rule A: Field 1 depends on Field 2
   Rule B: Field 2 depends on Field 1
   Result: Circular dependency, system can't resolve
   ```

2. **Fix it:**
   - Delete one of the rules
   - OR change one rule to not depend on the other field

3. **Re-verify:**
   - Run Configuration Health Panel
   - Should show: "✅ Circular Dependencies (0 detected)"

---

## Advanced Tips

### Tip 1: Use Meaningful Field Names

Good field names make dependencies obvious:

```
✅ Field names: "Town", "District", "Location"
   Dependencies: "Town.wgRegionId" → Clear what it does

❌ Field names: "Field 1", "Field 2", "Field 3"
   Dependencies: "Field 1.prop" → Confusing
```

---

### Tip 2: Document Dependencies

Add a note in the rule description:

```
Validation Rule: LocationInsideRegion
Error Message: "Location {coordinates} is outside {regionName}"
Dependency: Town.wgRegionId
Notes: "Validates that location is within selected town's boundaries"
```

---

### Tip 3: Test Edge Cases

```
✅ Normal case: User selects Town, enters valid location
✅ Edge case 1: User doesn't select Town, tries to enter location
✅ Edge case 2: User selects Town, enters location at exact boundary
✅ Edge case 3: User selects one Town, then changes to different Town
```

---

### Tip 4: Use Health Panel Regularly

Don't wait for errors in production:

```
After creating rules: Run Health Panel → Fix warnings
Before deploying: Run Health Panel → Verify all green
After updating form: Run Health Panel → Catch issues early
```

---

## Support Resources

### Where to Find Help

| Question | Resource |
|----------|----------|
| "How do I set up a rule?" | Admin Guide (this site) |
| "What does an error mean?" | Troubleshooting section above |
| "What's the API?" | API Reference |
| "I need to implement custom logic" | Developer Guide |
| "Something is broken" | Contact support with rule ID |

### Getting Support

1. **Check Configuration Health Panel** - Often tells you exactly what's wrong
2. **Read the Admin Guide** - Covers 90% of questions
3. **Check this FAQ** - Common issues and solutions
4. **Contact support** - Include:
   - Form name and ID
   - Rule ID (if applicable)
   - Error message (if any)
   - Steps to reproduce

---

## Glossary

- **Dependency:** A value from another field that a validation rule needs
- **Dependency Path:** The way to navigate to a value (Entity.Property)
- **Entity:** A data type in the system (Town, District, Structure)
- **Form Context:** All field values currently in the form
- **Health Panel:** Tool for checking configuration for issues
- **Interpolation:** Replacing placeholders with actual values in messages
- **Placeholder:** A variable in an error message (like {coordinates})
- **Resolved:** Dependency value was successfully found
- **Pending:** Waiting for dependency field to be filled
- **Error:** Dependency couldn't be resolved

---

## Quick Reference Card (Print This!)

```
╔════════════════════════════════════════════════════════════╗
║  Multi-Layer Dependency Resolution - Quick Reference      ║
╠════════════════════════════════════════════════════════════╣
║                                                            ║
║  CREATING A RULE with DEPENDENCY:                         ║
║                                                            ║
║  1. New Rule → Select field & validation type             ║
║  2. Add Dependency → Use PathBuilder                       ║
║  3. Select entity (e.g., Town)                            ║
║  4. Select property (e.g., wgRegionId)                    ║
║  5. Save → Path becomes: Town.wgRegionId                 ║
║  6. Test in Health Panel                                  ║
║                                                            ║
╠════════════════════════════════════════════════════════════╣
║  DEPENDENCY STATUSES:                                      ║
║                                                            ║
║  ✅ Resolved  = Found & ready                             ║
║  ⏳ Pending   = Waiting for user input                     ║
║  ❌ Error    = Could not be resolved                      ║
║                                                            ║
╠════════════════════════════════════════════════════════════╣
║  PATH SYNTAX (v1):                                         ║
║                                                            ║
║  ✅ Town.wgRegionId       (single property)               ║
║  ✅ District.name         (string property)               ║
║  ❌ Town.Districts[0].name (multi-hop - future v2)        ║
║                                                            ║
╠════════════════════════════════════════════════════════════╣
║  PLACEHOLDER EXAMPLES:                                     ║
║                                                            ║
║  {coordinates}  → Current location value                  ║
║  {regionName}   → From dependency value                   ║
║  {townName}     → From dependency value                   ║
║                                                            ║
╠════════════════════════════════════════════════════════════╣
║  TROUBLESHOOTING:                                          ║
║                                                            ║
║  Problem              → Solution                          ║
║  Rule not working     → Check: Is it ACTIVE?             ║
║  Property not found   → Use PathBuilder (not manual)     ║
║  Circular error       → Delete one of the rules          ║
║  Unsure if OK         → Click "Configuration Health"     ║
║                                                            ║
╠════════════════════════════════════════════════════════════╣
║  RESOURCES:   Admin Guide | API Reference | Support      ║
╚════════════════════════════════════════════════════════════╝
```

---

**Training Materials Version:** 1.0  
**Last Updated:** February 14, 2026  
**Next Review:** August 2026
