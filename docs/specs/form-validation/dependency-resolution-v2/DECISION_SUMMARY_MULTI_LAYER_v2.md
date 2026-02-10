# Multi-Layer Dependency Resolution v2.0 - Decision Summary

**Document Purpose:** Quick reference for all key technical decisions  
**Date:** February 9, 2026  
**Status:** Approved for Implementation

---

## Overview

**Feature:** Enable validation rules to reference dependent field values across **single-hop entity relationships** (v1) with extensibility for multi-hop in v2.

**Example Flow:**
```
Form: Create District
  Step 1: Select Town (dependency field)
  Step 2: Select Location (dependent field)
            ↓
            Validates: Location must be inside Town.wgRegionId
            ↓
            Path: "Town.wgRegionId" (single-hop v1)
```

---

## Decision Matrix

### 1. Path Notation: Dot Notation (Entity.Property)

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| Syntax | `Entity.Property` | Industry standard, intuitive for admins |
| Single-hop | ✅ Required v1 | `Town.wgRegionId` |
| Multi-hop | ❌ Blocked v1 | `Town.District.wgRegionId` → Error in v1 |
| Collections | ⚠️ Not supported v1 | Planned for v2 with `[first]`, `[all]` operators |
| Case sensitivity | Entities: PascalCase, Properties: camelCase | Matches .NET conventions |
| Special chars | Only dots allowed | Prevents SQL injection, parsing errors |

**Example Paths:**
```
Valid v1:
  - "Town.wgRegionId"
  - "PublicAccessPoint.coordinates"
  - "District.name"

Invalid v1:
  - "Town.District.wgRegionId" (multi-hop)
  - "Towns[0].wgRegionId" (collection)
  - "TownId.wgRegionId" (field name, not entity)
```

---

### 2. Field Reference Strategy: Entity-First (Not Field-ID-First)

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| Admin Perspective | Entity name ("Town") | Mental model matches database entities |
| FormContext Key | Entity name ("Town") | `formContext["Town"]` = full entity object |
| Resolution Logic | Map entity → properties | Clear navigation path through data |
| UI Experience | Dropdown: "Town" → "wgRegionId" | Visual, prevents typos |

**Example:**
```
Admin selects dependency field: Town (which is a reference to Town entity)
System resolves: formContext["Town"].wgRegionId
Path stored: "Town.wgRegionId"
```

---

### 3. FormContext Dehydration: Pragmatic Hybrid

| Context | Hydration | Reasoning |
|---------|-----------|-----------|
| **Web App** | Full entity objects | Needed for validation UI, error display, suggestions |
| **WorldTask Payload** | Entity reference only | Plugin doesn't need full data; minimize payload |
| **Error Messages** | Pre-interpolated strings | Plugin just displays; no variable resolution needed |
| **Plugin formContext** | Minimal (only needed data) | Reduce memory/network overhead |

**Memory Profile:**
```
formContext = {
  Town: {id: 4, name: "Cinix", wgRegionId: "town_1", ...},  // Full
  WgRegionId: null,
  Location: null,
  _fieldMetadata: [...],  // For path resolution
  _resolvedDependencies: {123: "town_1"}  // Cached
}

→ Strip for WorldTask:
inputJson.dependencyFieldValue: {id: 4, name: "Cinix", wgRegionId: "town_1"}
inputJson.validationContext.formContext: {Town: {...}, WgRegionId: null, ...}
```

---

### 4. Dependency Resolution: Hybrid Pre-Resolution Strategy

| Component | Responsibility |
|-----------|-------------------|
| **Frontend** | Eager-load field values on form mount; call batch resolution endpoint on field change |
| **Backend** | Pre-resolve all paths; pre-interpolate placeholders into messages |
| **Minecraft Plugin** | Use pre-resolved values; display ready-to-use error messages |

**Why Hybrid?**
- Frontend needs resolved values for immediate UI feedback (validation status, error display)
- Minecraft plugin doesn't have entity context; backend handles all complexity
- Reduces redundant work (backend doesn't re-resolve on validation)

**API Design:**

```http
POST /api/field-validation-rules/resolve-dependencies

Request:
{
  "fieldIds": [60, 61, 62],
  "formContextSnapshot": {"Town": {...}, "WgRegionId": null, ...},
  "formConfigurationId": 1
}

Response:
{
  "resolved": {
    "123": {status: "success", resolvedValue: "town_1", ...},
    "124": {status: "pending", message: "Town not yet filled", ...}
  }
}
```

---

### 5. Entity Property Suggestions: Show All (v1) + Smart Filter (v2)

| Decision | Scope | Implementation |
|----------|-------|-----------------|
| **v1: Show all properties** | All scalar + relationship properties | No filtering; admin sees full list |
| **v1: No smart filtering** | Not implemented | Documented for future feature |
| **v2: Smart filter** | Filter by validation type | Only show region properties for LocationInsideRegion |
| **UI Type** | Dropdown (not free-text) | Prevents spelling errors, typos |

**Why Dropdown?**
- ✅ User error protection (can't misspell or mistype)
- ✅ Visual guidance (see all available options)
- ✅ Real-time autocomplete
- ❌ Free-text input prone to errors

---

### 6. Collection Handling: v1 Exclusion, v2 Planning

| Feature | v1 | v2 |
|---------|-----|-------|
| **Single relationships** | ✅ Full support | ✅ Continue |
| **Collections (arrays)** | ❌ Blocked + Warning | ✅ [first], [all], [any] operators |
| **Error for collections** | Clear message | Pre-populated from v1 planning |
| **Documentation** | Include v2 design | Separate v2 spec |

**v1 Error Message:**
```
"Field 'Districts' resolves to a collection (array). 
Multi-layer collections are planned for v2. 
Please use single relationships for now."
```

**v2 Planned Syntax:**
```
Path: "Districts[first].Town.wgRegionId"
Meaning: Validate using first district's town region
```

---

### 7. Health Check Validation: Entity-Metadata-Based

| Check Type | Coverage | Action |
|------------|----------|--------|
| Field-Entity Alignment | 3-5 checks | Verify referenced entities exist |
| Property Existence | 5-10 checks | Verify paths reference valid properties |
| Required Field Completeness | Compare entity vs form | Warn if entity requires field but form marks optional |
| Collection Detection | Flags arrays in v1 | Block with clear message for v1 |
| Circular Dependencies | Graph traversal | Error: F(A→B→A detected |
| Field Ordering | Topological sort | Warn if dependency comes after dependent |

**ConfigurationHealthPanel Output:**
```
✅ Field Alignment (3/3 valid)
✅ Property Validation (5/5 valid)
⚠️  Required Field Completeness (1 warning)
✅ Collection Support (0 collections)
✅ Circular Dependencies (none)
✅ Field Ordering (correct)

Status: HEALTHY with 1 warning
```

---

### 8. Message Interpolation: Backend Pre-Interpolation

| Stage | Responsibility | Example |
|-------|-----------------|---------|
| **Admin creates rule** | Define template with placeholders | "Location {coordinates} is outside {townName}." |
| **Backend resolves** | Extract entity, build placeholders | `{townName: "Cinix", coordinates: "(X:1234, Z:5678)"}` |
| **Backend interpolates** | Replace placeholders in message | "Location (X:1234, Z:5678) is outside Cinix." |
| **Frontend/Plugin** | Display ready-to-use message | No further processing needed |

**Supported Placeholders:**
```
{entityName}      → Entity display name
{entityId}        → Entity ID
{fieldLabel}      → Form field label
{coordinates}     → Location X, Z coordinates
{regionName}      → Region identifier
{townName}        → Specific entity type name (flexible)
```

---

### 9. CircularDependency Prevention: Block at Creation

| Decision | Implementation |
|----------|-----------------|
| **When** | On FieldValidationRule creation |
| **Check** | Graph traversal algorithm (DFS) |
| **Action** | Return 400 Bad Request with error |
| **Message** | "Circular dependency detected: Field A → Field B → Field A" |

**Why Block at Creation?**
- Prevents runtime errors during validation
- Forces clean dependency design
- Easier to debug and maintain
- No circular waiting during resolution

---

### 10. UI Component Architecture: Modal-Based PathBuilder

| Device | Approach | Rationale |
|--------|----------|-----------|
| **Desktop (>1024px)** | Side-by-side dropdowns | Lots of space; direct feedback |
| **Tablet (768-1024px)** | Stacked dropdowns | Less space; still readable |
| **Mobile (<768px)** | Modal dialog + full-screen | Touch-friendly; prevents scrolling issues |

**Mobile Modal Design:**
```
┌──────────────────────────────┐
│ Dependency Path Config    [X] │
├──────────────────────────────┤
│                              │
│ Select Dependency Field:      │
│ [Town                      ▼] │
│                              │
│ Select Property:             │
│ [wgRegionId                ▼] │
│                              │
│ Example: "town_1"            │
│                              │
│ [Cancel]    [Save]           │
└──────────────────────────────┘
```

**Why Modal for Mobile?**
- Single-focus experience (reduces cognitive load)
- Prevents accidental scrolls
- Full keyboard support
- Touch-friendly button spacing

---

## Implementation Constraints & Boundaries

### v1 (Current Release) - Hard Constraints

✅ **Must Have:**
- Single-hop paths (`Entity.Property`)
- Dot notation syntax
- Entity-first references
- PathBuilder UI (dropdown-based)
- Health checks (7 types)
- Pre-resolution batch endpoint
- Pre-interpolated error messages

❌ **Must NOT Have (v1):**
- Multi-hop paths (`A.B.C`)
- Collection operators (`[first]`, `[all]`)
- Free-text path input (dropdowns only)
- Smart property filtering (show all)
- FormConfiguration versioning

### v2 (Future Release) - Planned Features

✅ **Planned for v2:**
- Multi-hop path support
- Collection operators
- Smart property filtering
- FormConfiguration versioning
- Advanced error reporting

---

## Security & Validation

### Path Validation Rules (v1)

```
1. Exactly one dot allowed: "Entity.Property"
2. No whitespace: "Entity.Property" (not "Entity . Property")
3. No special characters except dots
4. Left side must be valid entity field name from form
5. Right side must be valid property on entity (per metadata)
6. No circular dependencies: A→B→A blocked
```

### API Security

- ✅ Bound to FormConfiguration (can't resolve arbitrary entities)
- ✅ Path validation against entity metadata
- ✅ No dynamic code execution (no eval, no templates)
- ✅ Input sanitization on placeholders
- ✅ Authorization checks on all endpoints

---

## Testing Strategy

| Phase | Test Type | Coverage | Tools |
|-------|-----------|----------|-------|
| **Backend** | Unit tests | 80%+ | xUnit, Moq |
| **Integration** | API tests | 70%+ | Postman, xUnit |
| **Frontend** | Component tests | 80%+ | React Testing Library, Jest |
| **E2E** | User workflows | Critical paths | Cypress |
| **Load** | Batch resolution | 100+ rules | JMeter |
| **A11y** | WCAG 2.1 AA | All components | axe, manual |

---

## Database Changes Summary

### New/Modified Tables

```sql
-- Add column to existing table
ALTER TABLE dbo.FieldValidationRules
ADD DependencyPath NVARCHAR(500) NULL;

-- Add index for performance
CREATE INDEX IX_FieldValidationRules_DependencyPath 
ON dbo.FieldValidationRules(FormFieldId, DependencyPath);
```

**Backward Compatibility:**
- ✅ NULL column (existing rules unaffected)
- ✅ Legacy ConfigJson fallback if DependencyPath NULL
- ✅ No data migration required for v1

---

## Performance Targets

| Operation | Target Latency | Notes |
|-----------|-----------------|-------|
| Path resolution (single) | <50ms | In-memory lookup |
| Batch resolution (10 rules) | <100ms | Parallel processing |
| Batch resolution (100+ rules) | <500ms | Cached entity metadata |
| Health check (full config) | <200ms | Includes all 7 checks |
| UI path validation | <100ms | Real-time feedback |

---

## Rollback Plan

If issues discovered in production:

1. **Disable via feature flag** (if implemented)
2. **Revert DependencyPath usage** → Fall back to ConfigJson
3. **Disable new health checks** → Use only existing checks
4. **Database:** DependencyPath column remains (safe to keep), just unused

---

## Success Metrics

✅ **Feature is successful when:**
- Admin can create single-hop validation rules without errors
- FormRenderer executes validations correctly
- Error messages display properly on frontend and plugin
- ConfigurationHealthPanel catches 95%+ of configuration issues
- Load tests show <500ms resolution for 100+ rules
- WCAG 2.1 AA compliance verified
- Zero production incidents related to path resolution

---

## Next Steps

1. ✅ **Spec approved** (this document)
2. ✅ **Roadmap approved** (IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md)
3. 🔄 **Phase 1 starts:** Backend foundation (Week 1-2)
4. 🔄 **Phase 2 follows:** API endpoints (Week 2-3)
5. ... continue through Phase 8

**Go/No-Go Decision Point:** End of Phase 2
- If API endpoints working: Continue to Phase 3
- If significant issues: Pause and remediate

---

## Document References

- **Full Specification:** [SPEC_MULTI_LAYER_DEPENDENCIES_v2.md](./SPEC_MULTI_LAYER_DEPENDENCIES_v2.md)
- **Implementation Roadmap:** [IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md](./IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md)
- **Original v1 Spec:** [SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md](./SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md)
- **v1 Quick Reference:** [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)

---

**Approved By:** [Product Owner]  
**Approved Date:** February 9, 2026  
**Status:** Ready for Implementation Phase 1
