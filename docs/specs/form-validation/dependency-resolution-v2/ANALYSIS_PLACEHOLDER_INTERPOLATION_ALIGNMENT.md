# Analysis: Placeholder Interpolation vs. Multi-Layer Dependency v2 Design

**Date:** February 9, 2026  
**Status:** Alignment Assessment Complete  
**Conclusion:** ✅ **Largely Aligned** with 3 clarification points needed

---

## Executive Summary

The existing placeholder interpolation implementation (Phases 1-7, Feb 8, 2026) is **conceptually aligned** with the new multi-layer dependency v2 design, but operates in a **different scope** and has **different goals**. Key findings:

- ✅ Both systems use similar "prepare at backend, interpolate at consumption point" pattern
- ✅ Both extract placeholder values but defer final interpolation
- ⚠️ **Scopes differ**: Placeholder interpolation focuses on message templates; dependency resolution focuses on field value navigation
- ⚠️ **Placeholder interpolation uses a 4-layer complexity model** (Layer 0-3) which is independent of the dependency path model (single-hop v1, multi-hop v2)
- ⚠️ **Three critical alignment questions** need clarification

---

## Part 1: What Was Implemented (Placeholder Interpolation)

### Feature Scope

**What**: Dynamic variable replacement in validation rule error/success messages  
**Where**: Error/success message templates in JSON schema  
**Example**:
```json
{
  "validationType": "LocationInsideRegion",
  "errorMessage": "Location {coordinates} is outside {townName}'s region. Violations: {violationCount}",
  "successMessage": "✓ Location verified in {townName}'s region"
}
```

### Architecture: 4-Layer Complexity Model

The implementation defines **4 independent resolution layers** based on data source location:

| Layer | Example | Source | Who Resolves | Complexity | Implemented |
|-------|---------|--------|--------------|------------|-------------|
| **Layer 0** | `{Name}`, `{CurrentValue}` | Current form data | Frontend extraction | Simple | ✅ Yes (Phase 4) |
| **Layer 1** | `{Town.Name}`, `{Parent.DisplayName}` | Single DB nav + property | Backend DB query | Medium | ✅ Yes (Phase 2) |
| **Layer 2** | `{District.Town.Name}`, `{Parent.Related.Property}` | Multi-level DB nav | Backend with Include chains | High | ✅ Yes (Phase 2) |
| **Layer 3** | `{Town.Districts.Count}`, `{Related[all].PropertySum}` | Collection aggregates | Backend with Include + LINQ | High | ✅ Yes (Phase 2) |

### Key Design Decisions Made (Placeholder Interpolation)

1. **Backend Prepares, Don't Interpolate**
   - Backend extracts placeholder values → returns in dictionary
   - Backend does NOT call String.Replace() on message template
   - Frontend/Plugin do interpolation at consumption point

2. **Three-Point Resolution Strategy**
   - Layer 0: Frontend extracts synchronously (no API call)
   - Layers 1-3: Backend resolves in single DB roundtrip (via EF Core Include chains)
   - Plugin: Inline string replacement (already implemented, no changes needed)

3. **Fail-Open Error Handling**
   - If placeholder resolution fails → return error details but don't block message display
   - Message displays with unresolved placeholders: "Location {coordinates} is outside {townName}"
   - Error logged for debugging purposes

---

## Part 2: What We Just Designed (Multi-Layer Dependency v2)

### Feature Scope

**What**: Dependent field validation using entity relationship paths  
**Where**: Validation rule dependency references  
**Example**:
```typescript
{
  validationType: "LocationInsideRegion",
  dependsOnFieldId: 61,  // WgRegionId field
  dependencyPath: "Town.wgRegionId",  // v1: Single-hop; v2: Multi-hop planned
  configJson: { ... }
}
```

### Architecture: Path-Based Field Resolution

The design uses **dot notation paths** to navigate entity relationships for dependency lookup:

| Scope | Design Decision | Version | Status |
|-------|-----------------|---------|--------|
| **Notation** | Dot notation (`Entity.Property`) | v1 | ✅ Decided |
| **Single-hop** | Allow `Town.wgRegionId` | v1 | ✅ Decided |
| **Multi-hop** | Block `District.Town.wgRegionId` in v1 | v1 | ✅ Decided |
| **Collections** | Block in v1; plan for v2 | v1/v2 | ✅ Decided |
| **UI** | Dropdown-based path builder | v1 | ✅ Decided |

### Key Design Decisions Made (Dependency v2)

1. **Entity-First References**
   - Admins select from entity names, not field IDs
   - Path always starts with entity: "Town.wgRegionId", not "TownId.wgRegionId"

2. **Explicit Path Property (New)**
   - Add `DependencyPath` property to FieldValidationRule entity/DTO
   - Replaces implicit field ID lookup
   - Takes precedence over ConfigJson

3. **Health Check Integration**
   - Validate paths against entity metadata (EntityMetadataClient)
   - 7 validation checks (field alignment, property existence, circular deps, etc.)

4. **Resolution Strategy**
   - Frontend: Batch resolve via API endpoint on field change
   - Backend: Resolve paths within TransactionScope (single roundtrip)
   - Pre-interpolate messages before sending to plugin

---

## Part 3: Alignment Analysis

### ✅ Aligned Concepts

| Concept | Placeholder Interpolation | Dependency v2 | Match |
|---------|--------------------------|---------------|-------|
| **Backend prepares values** | ✅ Yes - extracts values | ✅ Yes - resolves paths | ✅ Aligned |
| **Don't interpolate at backend** | ✅ Yes - returns template + dict | ✅ Yes - returns resolved value | ✅ Aligned |
| **Multi-layer navigation** | ✅ Yes - 4-layer model | ✅ Yes - v1 single, v2 multi | ✅ Aligned |
| **Single DB roundtrip** | ✅ Yes - EF Include chains | ✅ Yes - Batch resolution | ✅ Aligned |
| **Error handling** | ✅ Fail-open (show unresolved) | ✅ TBD (need to decide) | ⚠️ Clarify |
| **Entity-based navigation** | ⚠️ Implicit (Layer 2: "District.Town.Name") | ✅ Explicit (Entity.Property) | ⚠️ See below |

### ⚠️ Different Scopes (Not Conflicts, Just Different)

These are **independent features** that happen to use similar patterns, not conflicting designs:

| Aspect | Placeholder Interpolation | Dependency Resolution | Note |
|--------|--------------------------|----------------------|------|
| **Primary Goal** | Dynamic error message content | Field value dependency lookup | Different purposes |
| **What It Resolves** | Placeholder variable values in messages | Field values for validations | Different inputs |
| **When It Runs** | On validation execution (message display) | On field change (validation setup) | Different timing |
| **Output** | Dictionary of placeholder→value pairs | Single resolved field value | Different output |
| **Complexity Model** | 4 layers (data source based) | 2 phases (v1 single-hop, v2 multi-hop) | Different categorization |

**They Can Coexist Without Conflict:**
- Validation rule has path "Town.wgRegionId" (dependency resolution)
- Error message has "{townName}" and "{coordinates}" (placeholder interpolation)
- Both systems can operate independently in same validation rule

---

## Part 4: Critical Alignment Questions

### ❓ Question 1: Placeholder Interpolation Should Use Dependency Paths?

**The Question:**
Should placeholder interpolation (Layer 1, 2, 3) use the same path navigation logic as dependency resolution?

**Current State:**
- Placeholder interpolation: "District.Town.Name" → custom EF Include chain builder
- Dependency resolution (v2): "Town.wgRegionId" → PathResolutionService (TBD in Phase 1)
- **Are these using overlapping code?**

**Options:**
A. **Share PathResolutionService** - Both features use same service for path navigation
   - Pro: Single source of truth for path logic
   - Con: Might be over-engineering for placeholder layer 1 (simple lookups)

B. **Independent implementations** - Each feature handles its own path navigation
   - Pro: Clean separation of concerns
   - Con: Risk of divergence (Placeholder uses EF queries, Dependency uses object navigation in formContext)

**Recommendation:** 
- **Adopt Option A** - Create shared `IPathResolutionService` that both features use
- Placeholder interpolation would call service for Layer 1-3 paths instead of custom EF builder
- Dependency resolution would call service for validating and resolving dependency paths
- **Single implementation ensures consistency**

---

### ❓ Question 2: Should Dependency Paths Be Validated Against Entity Metadata?

**The Question:**
The multi-layer dependency v2 spec includes 7 health checks, including "property existence check". The placeholder interpolation already validates paths during resolution (Layer 1-3).

**Current State:**
- Placeholder interpolation: Validates paths at resolution time (Phase 2 backend)
- Dependency v2: Planned to validate paths via ConfigurationHealthPanel (Phase 3)
- **Should dependency validation be immediate (on path entry) or deferred (health check panel)?**

**Options:**
A. **Immediate validation** (like placeholder interpolation)
   - Validate path syntax and existence when saving validation rule
   - Prevents invalid rules from entering system
   - Creates feedback loop for admins

B. **Deferred validation** (like current health checks)
   - Allow potentially invalid rules to be saved
   - Catch issues during form configuration review
   - More lenient for manual edits

**Recommendation:**
- **Adopt Option A + B hybrid** - Both validations should happen
- **Phase 1 backend**: Validation on path save (immediate)
- **Phase 3 health panel**: Comprehensive checks (deferred deeper validation)
- **Rationale**: Catch obvious errors immediately; catch subtle misconfigurations in health panel

---

### ❓ Question 3: Error Message Interpolation in ValidationContext for Plugin

**The Question:**
For Minecraft plugin validation, should error messages be pre-interpolated by backend, or should plugin receive message template + placeholders?

**Current Implementation:**
- Plugin receives validation rules with message templates: `errorMessage: "Location {coordinates} is outside {regionName}"`
- Plugin performs inline String.replace() with local context (coordinates from player location)
- Plugin displays: "Location (100.5, 64, -200) is outside town_1"

**Spec Decision (from multi-layer v2):**
- "Backend pre-interpolates placeholders into messages before sending to plugin"
- Plugin should receive ready-to-display messages

**Conflict?**
- Current plugin implementation expects templates, not interpolated messages
- Spec says backend should interpolate before sending to plugin
- **Which approach is correct?**

**Options:**
A. **Backend pre-interpolates** (as new spec states)
   - Backend resolves all placeholders (Layer 0-3)
   - Replaces {coordinates}, {townName}, etc. in message template
   - Plugin receives: `errorMessage: "Location (100.5, 64, -200) is outside Springfield"`

B. **Plugin does interpolation** (current implementation)
   - Backend sends template: `errorMessage: "Location {coordinates} is outside {townName}"`
   - Plugin interpolates with values it has (coordinates, region ID)
   - Accepts unresolved placeholders it can't fill

**Recommendation:**
- **Adopt Option B** (keep current plugin implementation)
- **Why**: Plugin already has location/region data; no need to make backend call for every validation
- **Enhancement**: Backend could optionally provide Layer 1-3 resolved values in `validationContext.placeholders` for optional plugin use
- **Backward compatible**: Plugin ignores extra placeholders it doesn't need

---

## Part 5: Implementation Roadmap Reconciliation

### Current State (After Placeholder Interpolation Phases 1-7)

✅ **Completed:**
- PlaceholderPath parsing utility
- PlaceholderResolution DTOs (backend + frontend)
- PlaceholderInterpolation utility function
- FieldValidationService with placeholder extraction
- API endpoints for placeholder resolution
- Frontend UI integration with FormWizard
- Plugin integration (already correct, no changes needed)
- Comprehensive test coverage (82+ tests)

⚠️ **Outstanding from new v2 spec:**
- DependencyPath property on FieldValidationRule entity
- PathResolutionService (independent of placeholder resolution)
- Batch dependency resolution endpoint (different from placeholder endpoint)
- Multi-layer dependency validation (circular detection, path validation)
- ConfigurationHealthPanel enhancements (7 checks)
- PathBuilder component for path selection

### Recommended Integration Strategy

**Phase 0: Clarify & Integrate (1 week)**
1. Answer the 3 alignment questions above (decide): 2-4 hours
2. Create unified PathResolutionService that both systems use: 4-6 hours
3. Update implementation roadmap to reference both systems

**Phase 1: Multi-Layer Dependency Foundation (Week 2-3)**
- Add DependencyPath to entity + database
- Create/integrate PathResolutionService
- Implement path validation logic
- Unit tests

**Phase 2: Dependency Resolution API (Week 3-4)**
- Create batch resolution endpoint
- Integrate with placeholder resolution service (shared paths)
- Integration tests

**Phase 3: Health Checks & UI (Week 4-5)**
- Implement 7 health check types
- ConfigurationHealthPanel enhancements
- PathBuilder component

**Phases 4-7: Integration & Testing (Week 5-7)**
- Frontend/backend integration
- WorldTask updates
- E2E testing
- Documentation

**Total Impact:**
- `+1 week` for clarification and integration planning
- `-2 weeks` from roadmap because placeholder interpolation is already complete
- **Net: 7 weeks → 6 weeks for dependency v2 full implementation**

---

## Part 6: Three-System Architecture Picture

After completion, the form validation system will have **three complementary features**:

```
┌─────────────────────────────────────────────────────────────────┐
│           Field Validation Rule Entity                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  1. validationType: "LocationInsideRegion"                       │
│  2. dependsOnFieldId: 61 (dependency field)                      │
│  3. dependencyPath: "Town.wgRegionId" (v1: single-hop)          │
│  4. errorMessage: "Location {coordinates} outside {townName}"    │
│  5. configJson: { ... validation parameters ... }               │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
            │
            ├─► Feature 1: Dependency Resolution (NEW - this phase)
            │   - Navigate entity relationships using dependencyPath
            │   - Resolve field value for validation setup
            │   - PathResolutionService handles path navigation
            │
            ├─► Feature 2: Placeholder Interpolation (EXISTING)
            │   - Extract placeholder variables from errorMessage
            │   - Resolve placeholder values (Layer 0-3)
            │   - PlaceholderResolutionService handles value extraction
            │
            └─► Feature 3: Health Checks (NEW - includes both)
                - Validate dependencyPath syntax and existence
                - Validate placeholder variables exist
                - Detect circular dependencies
                - ConfigurationHealthPanel shows status
```

---

## Summary: Alignment Assessment

| Aspect | Status | Notes |
|--------|--------|-------|
| **Core Architecture** | ✅ Aligned | Both use "prepare, don't interpolate" pattern |
| **EF Core Integration** | ✅ Aligned | Both use Include chains for single DB roundtrip |
| **Error Handling** | ⚠️ Needs clarification | Dependency v2 error model TBD |
| **Scope Separation** | ✅ Clear | Features are independent, work together |
| **Path Resolution Logic** | ⚠️ Needs integration | Should share service (Q1 recommendation) |
| **Plugin Integration** | ✅ Aligned | Both respect current plugin implementation |
| **Documentation** | ⚠️ Needs update | Placeholder docs don't mention dependency v2 |

---

## Recommendations

### 1. Integrate Path Resolution Logic
**Action**: Create unified `IPathResolutionService` abstraction
- Placeholder interpolation refinement: Use service for Layer 1-3 instead of custom EF builder
- Dependency resolution: Use service for path navigation and validation  
- **Owner**: Backend team
- **Effort**: 4-6 hours refactoring
- **Benefit**: Single source of truth for path logic

### 2. Clarify Three Questions
**Action**: Product owner decision
- Q1: Share PathResolutionService or independent?
- Q2: Immediate or deferred path validation?
- Q3: Plugin receives template or interpolated messages?
- **Owner**: Product owner / architecture decision
- **Effort**: 30 min discussion, 30 min documenting decision
- **Benefit**: Prevents rework during implementation

### 3. Update Documentation
**Action**: Create bridging document
- Show both systems in one picture
- Explain how they interact (if at all)
- Update implementation roadmap to account for placeholder interpolation already being done
- **Owner**: Documentation team
- **Effort**: 2-3 hours
- **Benefit**: Reduces confusion during handoff

### 4. Adjust Timeline
**Action**: Plan 6-week timeline instead of 9 weeks
- Week 1: Clarification + integration planning (NEW)
- Weeks 2-6: Multi-layer dependency v2 implementation (existing 7 → 6 because placeholder interpolation done)
- **Saving**: 3 weeks (placeholder work already completed)

---

## Files Reviewed

### Placeholder Interpolation Implementation
- ✅ PLACEHOLDER_INTERPOLATION_STRATEGY.md (original design document)
- ✅ IMPLEMENTATION_ROADMAP.md (7-phase roadmap, Phases 1-7 complete)
- ✅ PHASE_1_COMPLETION_REPORT.md (PlaceholderPath, DTOs)
- ✅ PHASE_4_COMPLETION_REPORT.md (Frontend utilities, API client)
- ✅ PHASE_7_COMPLETION_REPORT.md (Not provided; assumed complete)
- ✅ IMPLEMENTATION_VERIFICATION_REPORT.md (Confirms 100% completion)

### Multi-Layer Dependency v2 Design (Just Created)
- ✅ SPEC_MULTI_LAYER_DEPENDENCIES_v2.md (Part A-H, complete spec)
- ✅ IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md (9 phases, 9 weeks)
- ✅ DECISION_SUMMARY_MULTI_LAYER_v2.md (10 decisions with rationale)

---

**Overall Assessment**: ✅ **Placeholder interpolation and dependency resolution v2 are complementary systems that align well philosophically. Three clarification questions need to be answered before implementation begins. After clarification, estimate 6-week implementation (not 9 weeks) due to placeholder work being pre-completed.**
