# Architectural Decisions: Form Validation v2.0

**Date:** February 9, 2026  
**Status:** ✅ APPROVED BY PRODUCT OWNER  
**Impact:** Shapes implementation approach for Phases 1-8

---

## Executive Summary

Three critical architectural decisions have been made to guide the implementation of multi-layer dependency resolution v2.0 in alignment with the existing placeholder interpolation system.

---

## ✅ Decision 1: Shared PathResolutionService

### Status: APPROVED ✅

**Decision:** Both multi-layer dependency resolution (v2.0) and placeholder interpolation (Phases 1-7) should use a **single shared `IPathResolutionService`** abstraction.

### Rationale

| Aspect | Benefit |
|--------|---------|
| **DRY Principle** | Avoid duplicating path navigation logic across two systems |
| **Single Source of Truth** | One place to maintain path parsing, validation, navigation logic |
| **Consistency** | Both systems resolve paths identically (no divergence risk) |
| **Performance** | Shared caching + optimization strategies benefit both |
| **Testing** | Test once, benefits both dependency resolver and placeholder interpolator |
| **Maintenance** | Easy to extend path syntax (e.g., future collection operators) |

### Technical Design

```csharp
// Shared service interface (new)
public interface IPathResolutionService
{
    /// <summary>Navigate and resolve a path on a specific entity</summary>
    Task<object?> ResolvePathAsync(
        string entityTypeName,  // e.g., "Town"
        string path,           // e.g., "wgRegionId" or "Districts[0].Name"
        object? currentValue   // Current form value
    );
    
    /// <summary>Validate a path is syntactically correct and references exist</summary>
    Task<PathValidationResult> ValidatePathAsync(
        string entityTypeName,
        string path
    );
    
    /// <summary>Get include paths needed for EF Core optimization</summary>
    string[] GetIncludePathsForNavigation(string path);
}

// Used by both systems:
// 1. Dependency Resolution: Resolve "Town.wgRegionId" → Gets dependency field value
// 2. Placeholder Interpolation: Resolve "Town.Name" → Gets value for {Town.Name} placeholder
```

### Implementation Approach

**Phase 1:**
1. Create IPathResolutionService interface with core methods
2. Implement PathResolutionService class with:
   - Path parsing (dots, segments validation)
   - EF Core Include chain building
   - Entity property reflection
3. Add unit tests (80%+ coverage)

**Phase 2:**
1. Refactor placeholder interpolation Phase 2 code to use service
   - Current: Custom EF Include logic in PlaceholderResolutionService
   - New: Call shared IPathResolutionService
2. Dependency resolution uses same service
3. Integration tests verify both systems work

**Benefits:**
- ✅ No code duplication
- ✅ Single maintenance point
- ✅ Easy future enhancements (collection operators, smart filtering)
- ✅ Consistent behavior across systems

---

## ✅ Decision 2: Validation Timing (Both Immediate + Deferred)

### Status: APPROVED ✅

**Decision:** Validate dependency paths at **TWO points in time**:
1. **Immediate (on save):** Block invalid paths at creation time
2. **Deferred (health panel):** Comprehensive validation during form configuration review

### Rationale

| Timing | Purpose | Benefit | When |
|--------|---------|---------|------|
| **Immediate** | Catch syntax errors + property mismatches | Fast feedback, prevents invalid data | Admin saves validation rule |
| **Deferred** | Comprehensive validation (circular deps, required alignment) | Detailed analysis, helper suggestions | Form configuration panel review |

### What Gets Validated

**Immediate (on Save):**
```
1. ✅ Syntax: Exactly 1 dot in v1 ("Entity.Property")
2. ✅ Entity exists in metadata
3. ✅ Property exists on entity
4. ✅ Circular dependency detection (graph traversal)
```

**Deferred (in Health Panel):**
```
1. ✅ All immediate checks (shown again for clarity)
2. ✅ Field ordering: Dependency comes before dependent
3. ✅ Required field alignment: Entity requires → Form marks field required
4. ✅ Collection detection: Warn if path navigates collections in v1
5. ✅ Multi-hop detection: Warn if path too deep in v1
6. ✅ Placeholder validation: Message variables reference valid properties
7. ✅ Cross-validation: Rules don't create data inconsistencies
```

### Technical Design

**On Save (FieldValidationRuleController):**
```csharp
[HttpPost("rules")]
public async Task<ActionResult<FieldValidationRuleDto>> CreateRule(CreateFieldValidationRuleRequest req)
{
    // Immediate validation
    var pathValidation = await _pathResolutionService.ValidatePathAsync(
        req.DependencyPath
    );
    
    if (!pathValidation.IsValid)
    {
        return BadRequest(new {
            error = pathValidation.ErrorMessage,
            suggestion = pathValidation.Suggestion
        });
    }
    
    // Save only if valid
    var rule = new FieldValidationRule { ... };
    _db.FieldValidationRules.Add(rule);
    await _db.SaveChangesAsync();
    return Created(...);
}
```

**In Health Panel (ConfigurationHealthPanel.tsx):**
```tsx
const ValidationCheck = ({ rules, config }) => {
  const checks = [
    validateSyntax(rules),           // ✅ Syntax check
    validateProperties(rules),       // ✅ Property existence
    validateCircularDep(rules),      // ✅ Circular deps
    validateFieldOrdering(rules),    // ✅ Field order
    validateRequiredFields(rules),   // ✅ Required alignment
    validateCollections(rules),      // ✅ Collection handling
    validatePlaceholders(rules)      // ✅ Message variables
  ];
  
  return <HealthReport checks={checks} />;
};
```

### Benefits

- ✅ **User-Friendly:** Fast feedback on obvious errors (save time)
- ✅ **Comprehensive:** Catch subtle issues during design review
- ✅ **Non-Blocking:** Health panel is optional review (doesn't require fixes)
- ✅ **Helpful Suggestions:** Both immediate + deferred show fix suggestions
- ✅ **Aligns with Placeholder Interpolation:** Mirrors existing validation model

---

## ✅ Decision 3: Plugin Message Interpolation (Keep Current)

### Status: APPROVED ✅

**Decision:** Keep current implementation where **Minecraft plugin receives message templates** and performs inline String.replace() with values it has locally.

### Rationale

| Aspect | Current Approach | Alternative | Winner |
|--------|------------------|-------------|--------|
| **Message Format** | Template with placeholders | Pre-interpolated | ✅ Current |
| **Plugin Delay** | None (instant) | Awaits API response | ✅ Current |
| **Plugin Logic** | Simple string replacement | Complex API integration | ✅ Current |
| **Offline Capability** | Works without API | Requires API | ✅ Current |
| **Performance** | Immediate feedback | Delayed (API roundtrip) | ✅ Current |

### Technical Design

**Plugin Receives:**
```json
{
  "validationContext": {
    "validationRules": [
      {
        "validationType": "LocationInsideRegion",
        "errorMessage": "Location {coordinates} is outside {regionName}'s boundary",
        "configJson": { ... },
        "dependencyFieldValue": { "id": 4, "name": "Springfield", "wgRegionId": "town_1" },
        "placeholders": {
          "regionName": "town_1"  // ← Optional: Backend-resolved values
        }
      }
    ]
  }
}
```

**Plugin Does:**
```java
public void validateLocationInsideRegion(WorldTask task, Player player) {
    // Extract from local context
    Location playerLoc = player.getLocation();
    ProtectedRegion parentRegion = getRegion(depValue.getWgRegionId());
    
    // Inline string replacement with LOCAL values
    String errorMsg = rule.get("errorMessage").getAsString();
    errorMsg = errorMsg.replace("{coordinates}", 
        String.format("(%.1f, %.1f, %.1f)", loc.getX(), loc.getY(), loc.getZ()));
    errorMsg = errorMsg.replace("{regionName}", parentRegion.getId());
    
    // Send directly to player (no API wait)
    player.sendMessage("§c" + errorMsg);
}
```

### Enhancement Strategy (Optional)

**For future values plugin can't resolve:**
- Backend optionally provides resolved values in `validationContext.placeholders`
- Plugin attempts replacements with provided values
- Plugin doesn't fail if placeholder unresolved
- Provides graceful degradation

**Example Flow:**
```
Placeholders needing resolution:
  {coordinates}    → Plugin has (player location) ✅ Replaces
  {regionName}     → Plugin has (WorldGuard region) ✅ Replaces  
  {townName}       → Plugin doesn't have; backend provides ✅ Replaces
  {violationCount} → Plugin has (boundary check) ✅ Replaces
```

### Benefits

- ✅ **Zero Latency:** No API roundtrip, instant feedback to player
- ✅ **Offline Safe:** Works even if backend temporarily unavailable
- ✅ **Simple Code:** Just string replacement, no complex logic
- ✅ **Backward Compatible:** Works with existing plugin code
- ✅ **Extensible:** Can accept optional pre-resolved values from backend
- ✅ **Aligns with Current Implementation:** Plugin code already does this

---

## Summary Table

| Decision | Option Chosen | Key Rationale | Implementation Timeline |
|----------|---------------|---------------|--------------------------|
| **Q1: Shared Service** | YES - Share IPathResolutionService | DRY + consistency | Phase 1-2 (refactor both systems) |
| **Q2: Validation Timing** | BOTH (Immediate + Deferred) | Fast feedback + comprehensive checks | Phase 1 (save) + Phase 3 (panel) |
| **Q3: Plugin Messages** | KEEP CURRENT (Templates) | Zero latency + offline safe | No changes to plugin |

---

## Implementation Impact

### Phase 1: Backend Foundation
- Create shared IPathResolutionService
- Add immediate path validation on save
- Update FieldValidationRule entity with DependencyPath property

### Phase 2: API Endpoints
- Use shared service for dependency resolution
- Refactor placeholder interpolation to use shared service
- Both systems now use identical path navigation logic

### Phase 3: Health Checks
- Add ConfigurationHealthPanel 7 validation checks
- Use shared service for comprehensive validation
- Provide fix suggestions based on check results

### Phase 4-8: Integration
- No additional complexity introduced
- Both systems work seamlessly together
- Timeline: 6 weeks (not 9 weeks due to placeholder pre-completion)

---

## Future Enhancements

These decisions enable natural evolution:

| Future Feature | Impact | Effort |
|---|---|---|
| Collection operators (`[first]`, `[all]`) | Extend IPathResolutionService | Medium |
| Smart property filtering | Add filtering layer to service | Low |
| Path history/autocomplete | Leverage service path analysis | Low |
| Multi-language placeholders | Service returns i18n keys | Low |

---

## Sign-Off

**Product Owner:** Approved ✅  
**Decision Date:** February 9, 2026  
**Implementation Start:** Week 2 (Phase 1)

---

## Reference Documents

- [SPEC_MULTI_LAYER_DEPENDENCIES_v2.md](./SPEC_MULTI_LAYER_DEPENDENCIES_v2.md) - Complete specification
- [IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md](./IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md) - Updated roadmap
- [PLACEHOLDER_INTERPOLATION_STRATEGY.md](./placeholder-interpolation/PLACEHOLDER_INTERPOLATION_STRATEGY.md) - Existing system
- [ANALYSIS_PLACEHOLDER_INTERPOLATION_ALIGNMENT.md](./ANALYSIS_PLACEHOLDER_INTERPOLATION_ALIGNMENT.md) - Alignment analysis
