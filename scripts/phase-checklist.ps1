# phase-checklist.ps1
#
# Displays a checklist for implementing a feature phase.
#
# Usage: .\scripts\phase-checklist.ps1 -FeatureName "my-feature-name" -Phase 1
#
# Example: .\scripts\phase-checklist.ps1 -FeatureName "my-feature-name" -Phase 1

param(
    [Parameter(Mandatory=$true, HelpMessage="Feature name (e.g., 'my-feature-name')")]
    [string]$FeatureName,
    
    [Parameter(Mandatory=$true, HelpMessage="Phase number")]
    [int]$Phase
)

$ErrorActionPreference = "Stop"

# Validate input
if ([string]::IsNullOrWhiteSpace($FeatureName) -or $Phase -lt 1) {
    Write-Host "Error: Feature name and phase number are required" -ForegroundColor Red
    Write-Host "Usage: .\scripts\phase-checklist.ps1 -FeatureName 'my-feature-name' -Phase 1" -ForegroundColor Yellow
    exit 1
}

$prevPhase = $Phase - 1

$checklist = @"
╔════════════════════════════════════════════════════════════════╗
║  Feature: $FeatureName - Phase $Phase Implementation Checklist    ║
╚════════════════════════════════════════════════════════════════╝

📋 PRE-IMPLEMENTATION
────────────────────────────────────────────────────────────────
[ ] Feature branch created and checked out
[ ] PHASE_STATUS.md shows Phase $Phase as "in-progress"
[ ] All dependencies from Phase $prevPhase are complete
[ ] Reference implementations reviewed
[ ] All referenced docs updated (REQUIREMENTS.md, SPEC.md)

🔨 DURING IMPLEMENTATION
────────────────────────────────────────────────────────────────
[ ] Followed Step 4.2 prompt template from AI_FEATURE_IMPLEMENTATION_WORKFLOW.md
[ ] Referenced REQUIREMENTS.md and SPEC.md in implementation
[ ] Checked existing code patterns in each repository
[ ] No compilation errors reported
[ ] Tests added/updated for new components
[ ] Documentation updated as you implement

✅ POST-IMPLEMENTATION VERIFICATION
────────────────────────────────────────────────────────────────
[ ] All deliverables from roadmap are present
[ ] Code compiles without errors
[ ] Build output shows no warnings
[ ] Style matches existing codebase conventions
[ ] No breaking changes to existing functionality
[ ] Acceptance criteria from roadmap are met

🧪 TESTING
────────────────────────────────────────────────────────────────
[ ] Run unit tests: .\gradlew test (plugin) or npm test (web)
[ ] Run integration tests
[ ] Verify all acceptance criteria
[ ] Test edge cases mentioned in roadmap
[ ] Manual testing completed (if needed)

💾 COMMIT GENERATION
────────────────────────────────────────────────────────────────
[ ] Used Step 5.2 prompt template to generate commits
[ ] Generated commits follow GIT_COMMIT_CONVENTIONS.md
[ ] Commits cover all affected repositories:
    [ ] knk-web-api-v2
    [ ] knk-web-app
    [ ] knk-plugin-v2
    [ ] docs
[ ] Executed: git add . && git commit -m "..." -m "..."
[ ] Updated COMMIT_HISTORY.md with commit hashes

🎯 PHASE COMPLETION
────────────────────────────────────────────────────────────────
[ ] Updated PHASE_STATUS.md:
    - Mark Phase $Phase as ✅ COMPLETED
    - Mark Phase $($Phase + 1) as in-progress (if exists)
[ ] Pushed to feature branch: git push origin feature/$FeatureName
[ ] Ready for next phase (or final testing)

════════════════════════════════════════════════════════════════

📚 Reference Documentation:
   - AI_FEATURE_IMPLEMENTATION_WORKFLOW.md (Step 4, Step 5)
   - GIT_COMMIT_CONVENTIONS.md (commit format)
   - docs/features/$FeatureName/IMPLEMENTATION_ROADMAP.md (Phase $Phase details)
   - docs/CODEMAP.md (architecture reference)

════════════════════════════════════════════════════════════════
"@

Write-Host $checklist
