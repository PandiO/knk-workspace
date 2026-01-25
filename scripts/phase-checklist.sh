#!/bin/bash
# phase-checklist.sh
#
# Displays a checklist for implementing a feature phase.
#
# Usage: ./scripts/phase-checklist.sh <feature-name> <phase-number>
#
# Example: ./scripts/phase-checklist.sh my-feature-name 1

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Feature name and phase number are required"
    echo "Usage: ./scripts/phase-checklist.sh <feature-name> <phase-number>"
    echo ""
    echo "Example: ./scripts/phase-checklist.sh my-feature-name 1"
    exit 1
fi

FEATURE=$1
PHASE=$2
PREV_PHASE=$((PHASE-1))

cat << EOF
╔════════════════════════════════════════════════════════════════╗
║  Feature: $FEATURE - Phase $PHASE Implementation Checklist     ║
╚════════════════════════════════════════════════════════════════╝

📋 PRE-IMPLEMENTATION
────────────────────────────────────────────────────────────────
[ ] Feature branch created and checked out
[ ] PHASE_STATUS.md shows Phase $PHASE as "in-progress"
[ ] All dependencies from Phase $PREV_PHASE are complete
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
[ ] Run unit tests: ./gradlew test (plugin) or npm test (web)
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
    - Mark Phase $PHASE as ✅ COMPLETED
    - Mark Phase $((PHASE+1)) as in-progress (if exists)
[ ] Pushed to feature branch: git push origin feature/$FEATURE
[ ] Ready for next phase (or final testing)

════════════════════════════════════════════════════════════════

📚 Reference Documentation:
   - AI_FEATURE_IMPLEMENTATION_WORKFLOW.md (Step 4, Step 5)
   - GIT_COMMIT_CONVENTIONS.md (commit format)
   - docs/features/$FEATURE/IMPLEMENTATION_ROADMAP.md (Phase $PHASE details)
   - docs/CODEMAP.md (architecture reference)

════════════════════════════════════════════════════════════════
EOF
