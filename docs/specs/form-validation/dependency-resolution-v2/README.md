# Multi-Layer Field Dependency Resolution v2.0

**Feature Status:** 📋 Architecture Complete - Ready for Phase 1 Implementation  
**Created:** February 8-9, 2026  
**Timeline:** 6 weeks (Phases 1-8)  
**Prerequisites:** Placeholder Interpolation (Phases 1-7 complete)

---

## Overview

This directory contains complete architectural design and implementation planning for the Multi-Layer Field Dependency Resolution v2.0 feature. This upgrade addresses a critical bug in FormField dependency path resolution and enables multi-hop navigation through entity relationships for field validation dependencies.

**Problem Solved:** FormField 60 (Location validation) incorrectly resolved to Town entity instead of FormField 61 (wgRegionId) due to heuristic fallback. The system lacked explicit dependency path specification.

**Solution:** Add explicit `DependencyPath` property to validation rules, create shared `IPathResolutionService` for both dependency resolution and placeholder interpolation systems, and implement comprehensive path validation.

---

## Document Index

### 🚀 Start Here (Quick Access)

1. **[IMPLEMENTATION_PACKAGE_COMPLETE.md](./IMPLEMENTATION_PACKAGE_COMPLETE.md)** ⭐
   - Complete team-ready implementation package
   - 6-week timeline breakdown
   - Readiness checklist
   - Team assignments by role

2. **[PHASE_1_DETAILED_CHECKLIST.md](./PHASE_1_DETAILED_CHECKLIST.md)** ⭐
   - Day-by-day Phase 1 tasks (1-1.5 developer days)
   - Code examples for IPathResolutionService
   - Unit test requirements (20+ tests)
   - Quality assurance checklist

### 📋 Architectural Design

3. **[ARCHITECTURAL_DECISIONS.md](./ARCHITECTURAL_DECISIONS.md)**
   - Q1: Shared IPathResolutionService (APPROVED ✅)
   - Q2: Validation timing - Both immediate + deferred (APPROVED ✅)
   - Q3: Plugin message format - Keep current (APPROVED ✅)
   - Complete rationale, technical design, benefits for each decision

4. **[INTEGRATION_BRIDGE.md](./INTEGRATION_BRIDGE.md)**
   - How dependency resolution + placeholder interpolation work together
   - Complete request lifecycle with diagrams
   - Shared service definition (IPathResolutionService interface)
   - Code examples (C#, Java)
   - Error handling strategy
   - Testing approach
   - Timeline impact: 6 weeks (saved 3 weeks)

### 📖 Complete Specifications

5. **[SPEC_MULTI_LAYER_DEPENDENCIES_v2.md](./SPEC_MULTI_LAYER_DEPENDENCIES_v2.md)**
   - Complete technical specification (350+ lines)
   - All 10 design decisions with rationale
   - Backend, frontend, and UI specifications
   - API contracts with request/response examples
   - Data dehydration patterns

6. **[IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md](./IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md)**
   - 9 phases with detailed tasks (600+ lines)
   - Code examples for each phase (C#, TypeScript, Java)
   - Time estimates (8-12 hours per phase)
   - Parallelization opportunities
   - Acceptance criteria and test specifications

7. **[DECISION_SUMMARY_MULTI_LAYER_v2.md](./DECISION_SUMMARY_MULTI_LAYER_v2.md)**
   - 10 key design decisions in matrix format
   - v1 vs v2 scope boundaries
   - Success metrics
   - Risk mitigation strategies

### 🔍 Analysis & Investigation

8. **[THREE_POINT_ANALYSIS_SUMMARY.md](./THREE_POINT_ANALYSIS_SUMMARY.md)**
   - Frontend revert status (WorldTaskCta.tsx)
   - Component usage analysis (dead code discovery)
   - Placeholder interpolation alignment findings

9. **[ANALYSIS_PLACEHOLDER_INTERPOLATION_ALIGNMENT.md](./ANALYSIS_PLACEHOLDER_INTERPOLATION_ALIGNMENT.md)**
   - Detailed alignment analysis between both systems (5000+ words)
   - 3 critical architectural questions identified
   - Feature interaction diagram
   - Timeline impact (+6 weeks saved due to pre-completion)

---

## Key Architectural Decisions

### Decision 1: Shared IPathResolutionService ✅
**Answer:** YES - Both systems share the service  
**Why:** DRY principle, single source of truth, consistency  
**Impact:** +2 days refactoring in Phase 2 (net zero to timeline)

### Decision 2: Validation Timing ✅
**Answer:** BOTH - Immediate (on save) + Deferred (health panel)  
**Why:** Fast feedback for admins + comprehensive system checks  
**Implementation:** Phase 1 (immediate) + Phase 3 (7 health checks)

### Decision 3: Plugin Message Format ✅
**Answer:** KEEP CURRENT - Template-based interpolation  
**Why:** Zero latency, offline-safe, backward-compatible  
**Impact:** No changes needed to plugin code

---

## Implementation Timeline

```
✅ Week 1: Planning & Architecture (COMPLETE - Feb 8-9, 2026)
   - All architectural decisions finalized
   - Complete design documentation created
   - Integration strategy defined

➡️ Week 2-3: Phase 1-2 (Backend Foundation - READY TO START)
   - Create IPathResolutionService interface
   - Add DependencyPath property to entity
   - Database migration
   - Dependency resolution API endpoints
   - Refactor placeholder interpolation to use shared service

⏳ Week 3-4: Phase 2 Completion
   - Both systems using shared service
   - Path validation working identically

⏳ Week 4-5: Phase 3-4 (Health Checks + Frontend Data Layer)
   - 7 validation check types in ConfigurationHealthPanel
   - TypeScript DTOs and API client updates
   - useEnrichedFormContext hook

⏳ Week 5-6: Phase 5-6 (UI Components)
   - PathBuilder component (dropdown-based)
   - ValidationRuleBuilder integration
   - WCAG 2.1 AA accessibility

⏳ Week 6: Phase 7-8 (Integration & Testing)
   - Minecraft plugin integration
   - E2E test suite (20+ scenarios)
   - Load testing (100+ rules)
   - Documentation complete

📅 Week 7+: Phase 9 (Future Planning)
   - Collection operators ([first], [all])
   - Multi-hop paths
   - Smart property filtering
```

**Total Duration:** 6 weeks  
**Original Estimate:** 9 weeks  
**Time Saved:** 3 weeks (placeholder interpolation Phases 1-7 already complete)

---

## For Different Roles

### Backend Developers
**Start Here:**
1. [PHASE_1_DETAILED_CHECKLIST.md](./PHASE_1_DETAILED_CHECKLIST.md) - Day-by-day tasks
2. [INTEGRATION_BRIDGE.md](./INTEGRATION_BRIDGE.md) - "Shared Service" section
3. Phases 1-2 in [IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md](./IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md)

**Your Deliverables:**
- IPathResolutionService interface and implementation
- DependencyPath property added to FieldValidationRule entity
- Database migration script
- 20+ unit tests (80%+ coverage)
- API endpoints for dependency resolution

### Frontend Developers
**Start Here:**
1. [DECISION_SUMMARY_MULTI_LAYER_v2.md](./DECISION_SUMMARY_MULTI_LAYER_v2.md) - Quick overview
2. [INTEGRATION_BRIDGE.md](./INTEGRATION_BRIDGE.md) - "Data Flow" section
3. Phases 4-6 in [IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md](./IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md)

**Your Deliverables:**
- TypeScript DTOs for new API responses
- PathBuilder component (dropdown-based UI)
- Integration with ValidationRuleBuilder
- 25+ component tests

### QA/Test Engineers
**Start Here:**
1. Phase 8 in [IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md](./IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md)
2. "Testing Strategy" in [INTEGRATION_BRIDGE.md](./INTEGRATION_BRIDGE.md)

**Your Deliverables:**
- E2E test suite (20+ critical path scenarios)
- Load testing (100+ rules, <500ms target)
- Accessibility testing (WCAG 2.1 AA compliance)

### Tech Leads/Architects
**Start Here:**
1. [ARCHITECTURAL_DECISIONS.md](./ARCHITECTURAL_DECISIONS.md) - All 3 decisions
2. [INTEGRATION_BRIDGE.md](./INTEGRATION_BRIDGE.md) - Complete integration strategy
3. [SPEC_MULTI_LAYER_DEPENDENCIES_v2.md](./SPEC_MULTI_LAYER_DEPENDENCIES_v2.md) - Full spec

**Your Responsibilities:**
- Review and approve shared service design
- Verify alignment with overall architecture
- Coordinate Phase 1 kickoff

---

## Critical Code Components

### IPathResolutionService (Phase 1)
```csharp
public interface IPathResolutionService
{
    // Navigate dot-notation path to resolve value
    Task<object?> ResolvePathAsync(
        string entityTypeName, 
        string path, 
        object? entityInstance
    );
    
    // Validate path exists for entity type
    Task<PathValidationResult> ValidatePathAsync(
        string entityTypeName, 
        string path
    );
    
    // Get EF Include paths for efficient loading
    string[] GetIncludePathsForNavigation(string path);
}
```

### DependencyPath Property (Phase 1)
```csharp
public class FieldValidationRule
{
    // Existing properties...
    public int Id { get; set; }
    public int FormFieldId { get; set; }
    
    // NEW: Explicit dependency path
    public string? DependencyPath { get; set; }  // e.g., "Town.wgRegionId"
}
```

---

## Dependencies & Prerequisites

### Completed (✅)
- Placeholder Interpolation Phases 1-7 (Aug 2025 - Feb 2026)
  - 82+ test cases passing
  - 4-layer placeholder architecture operational
  - See: [../placeholder-interpolation/](../placeholder-interpolation/)

### Required Before Phase 1
- None - Ready to start immediately

### External Dependencies
- Entity Framework Core (existing)
- IEntityMetadataProvider service (existing)
- IRepositoryFactory service (existing)

---

## Success Criteria

### Phase 1 Complete When:
- [ ] IPathResolutionService interface defined and approved
- [ ] PathResolutionService implementation complete
- [ ] 20+ unit tests passing (80%+ coverage)
- [ ] DependencyPath property added to entity
- [ ] Database migration applied successfully
- [ ] Zero breaking changes to existing code

### v2.0 Launch Ready When:
- [ ] All 8 phases complete
- [ ] E2E tests: 20+ scenarios passing
- [ ] Load tests: <500ms for 100 rules
- [ ] ConfigurationHealthPanel shows 7 check types
- [ ] PathBuilder UI accessible (WCAG 2.1 AA)
- [ ] Documentation complete (user + developer guides)
- [ ] Plugin integration tested end-to-end

---

## Related Documentation

- **Parent Directory:** [../](../) - Form validation root specs
- **Placeholder Interpolation:** [../placeholder-interpolation/](../placeholder-interpolation/)
- **Original Spec (v1):** [../SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md](../SPEC_INTER_FIELD_VALIDATION_DEPENDENCIES.md)
- **Git Conventions:** [../../../GIT_COMMIT_CONVENTIONS.md](../../../GIT_COMMIT_CONVENTIONS.md)

---

## Questions or Blockers?

### Architecture Questions
Refer to: [INTEGRATION_BRIDGE.md](./INTEGRATION_BRIDGE.md)

### Implementation Questions
Refer to: [IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md](./IMPLEMENTATION_ROADMAP_MULTI_LAYER_v2.md)

### Decision Rationale
Refer to: [ARCHITECTURAL_DECISIONS.md](./ARCHITECTURAL_DECISIONS.md)

### Placeholder Alignment
Refer to: [ANALYSIS_PLACEHOLDER_INTERPOLATION_ALIGNMENT.md](./ANALYSIS_PLACEHOLDER_INTERPOLATION_ALIGNMENT.md)

---

**Status:** ✅ Architecture Complete - Ready for Phase 1 Implementation  
**Next Action:** Backend team start Phase 1 (Week 2)

Good luck! 🚀
