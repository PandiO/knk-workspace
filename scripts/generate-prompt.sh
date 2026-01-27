#!/bin/bash
# generate-prompt.sh
#
# Generates AI prompts from the AI_FEATURE_IMPLEMENTATION_WORKFLOW.md templates.
#
# Usage: ./scripts/generate-prompt.sh <feature-name> <phase-number> <step>
#
# Steps:
#   - refinement  : Step 1 - Requirements refinement
#   - requirements: Step 2 - Requirements & spec generation
#   - roadmap     : Step 3 - Roadmap generation
#   - impl        : Step 4 - Phase implementation
#   - test        : Step 5 - Testing scenarios
#   - commit      : Step 5 - Commit generation
#
# Examples:
#   ./scripts/generate-prompt.sh my-feature-name 1 impl
#   ./scripts/generate-prompt.sh my-feature-name 1 commit
#   ./scripts/generate-prompt.sh my-feature-name 1 test

set -e

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "Error: Feature name, phase number, and step are required"
    echo ""
    echo "Usage: ./scripts/generate-prompt.sh <feature-name> <phase-number> <step>"
    echo ""
    echo "Available steps:"
    echo "  refinement  - Step 1: Requirements refinement prompt"
    echo "  requirements- Step 2: Requirements & specification generation prompt"
    echo "  roadmap     - Step 3: Implementation roadmap generation prompt"
    echo "  impl        - Step 4: Phase implementation prompt"
    echo "  test        - Step 5: Testing scenarios prompt"
    echo "  commit      - Step 5: Commit generation prompt"
    echo ""
    echo "Examples:"
    echo "  ./scripts/generate-prompt.sh my-feature-name 1 impl"
    echo "  ./scripts/generate-prompt.sh my-feature-name 1 commit"
    echo "  ./scripts/generate-prompt.sh my-feature-name 1 test"
    exit 1
fi

FEATURE=$1
PHASE=$2
STEP=$3

case $STEP in
  refinement)
    cat << 'EOF'
================================================================================
STEP 1: Requirements Refinement Prompt
================================================================================

Feature Name: [feature-name]
Context: [brief description]
Related Components: [list affected repos: knk-web-api-v2, knk-web-app, knk-plugin-v2]

Request:
Analyze the existing codebase and help me refine requirements for [feature-name].
Please suggest:
1. Existing patterns or precedents in the codebase
2. Potential implementation approaches
3. Key decisions that need to be made
4. Any blockers or dependencies

Reference existing implementations:
- [path to reference implementation 1]
- [path to reference implementation 2]

Use docs/GIT_COMMIT_CONVENTIONS.md and docs/CODEMAP.md as guides.

================================================================================
EOF
    ;;

  requirements)
    cat << 'EOF'
================================================================================
STEP 2: Requirements & Specification Generation Prompt
================================================================================

Feature: [feature-name]
Status: Requirements & Specification Generation

Using the analysis from Step 1, generate three documents:

1. **REQUIREMENTS.md**
   - Functional requirements (must-have, nice-to-have)
   - Non-functional requirements (performance, scalability, etc.)
   - Constraints and dependencies
   - Acceptance criteria

2. **SPEC.md**
   - Detailed technical specification
   - Architecture overview
   - Component responsibilities
   - Data flow diagrams (in text/ASCII)
   - Error handling strategy
   - Integration points

3. **INSTRUCTIONS.md** (if needed per repo)
   - Implementation patterns to follow
   - Code style/naming conventions (reference existing code)
   - Testing requirements per component
   - Dependencies and versions

Context for generation:
- Affected repositories: [list]
- Similar features: [reference paths]
- Architecture guides: docs/CODEMAP.md
- Git conventions: docs/GIT_COMMIT_CONVENTIONS.md

Store outputs in: docs/features/[feature-name]/

================================================================================
EOF
    ;;

  roadmap)
    cat << 'EOF'
================================================================================
STEP 3: Implementation Roadmap Generation Prompt
================================================================================

Feature: [feature-name]
Status: Implementation Roadmap Generation

Based on the requirements and specification, generate a phased implementation roadmap.

Input documents:
- docs/features/[feature-name]/REQUIREMENTS.md
- docs/features/[feature-name]/SPEC.md

Output: docs/features/[feature-name]/IMPLEMENTATION_ROADMAP.md

The roadmap must:
1. Break the feature into logical phases (typically 3-5 phases)
2. Each phase should:
   - Have a clear title and description
   - List all deliverables (code files, tests, docs)
   - Specify affected repositories
   - Include acceptance criteria (testable, measurable)
   - Note any dependencies on previous phases
3. Include a "Definition of Done" section
4. Mark each phase status (not-started, in-progress, completed)
5. Include an estimated effort level (small, medium, large)

Phase guidelines:
- Phase 1 should establish foundations/scaffolding
- Middle phases should implement core logic
- Final phase should integrate and polish
- Each phase should be independently committable

Reference examples:
- docs/data-access-unification/implementation-roadmap.md

Git conventions: docs/GIT_COMMIT_CONVENTIONS.md

================================================================================
EOF
    ;;

  impl)
    cat << 'EOF'
================================================================================
STEP 4: Phase Implementation Prompt
================================================================================

Feature: [feature-name]
Phase: [number] - [title]
Status: Implementation

Execute and implement Phase [number] based on the approved roadmap and requirements.

Reference documents:
- docs/features/[feature-name]/REQUIREMENTS.md
- docs/features/[feature-name]/SPEC.md
- docs/features/[feature-name]/IMPLEMENTATION_ROADMAP.md (Phase [number] section)

Implementation scope:
[Copy the entire Phase [number] section from IMPLEMENTATION_ROADMAP.md]

Affected repositories:
- knk-web-api-v2: [list what to implement]
- knk-web-app: [list what to implement]
- knk-plugin-v2: [list what to implement]

Guidelines:
- Follow existing code patterns in each repository
- Refer to docs/CODEMAP.md for architecture
- All code must be compilable/runnable
- Add unit tests for new components
- Update documentation as you implement

Validation:
After implementation, verify:
1. All components compile/run without errors
2. All deliverables from the roadmap are present
3. Code follows existing style conventions
4. No breaking changes to existing functionality
5. Acceptance criteria are met

Use docs/GIT_COMMIT_CONVENTIONS.md for commit format guidance (but don't commit yet).

================================================================================
EOF
    ;;

  test)
    cat << 'EOF'
================================================================================
STEP 5a: Testing Scenarios Prompt
================================================================================

Feature: [feature-name]
Phase: [number]

Please suggest testing scenarios for Phase [number] including:
1. Unit test cases with input/output examples
2. Integration test scenarios
3. Edge cases to verify
4. Manual testing steps if needed

Acceptance criteria from roadmap:
[Paste the acceptance criteria for this phase]

Testing focus:
- Verify all deliverables work as expected
- Check integration with existing components
- Validate error handling
- Confirm no regressions

================================================================================
EOF
    ;;

  commit)
    cat << 'EOF'
================================================================================
STEP 5b: Commit Generation Prompt
================================================================================

Feature: [feature-name]
Phase: [number]
Status: Commit Message Generation

Generate git commit messages for Phase [number] implementation.

Context:
- Feature: [feature-name]
- Phase: [number] - [title]
- Completion date: [date]

Deliverables implemented in this phase:
[Paste the deliverables list from IMPLEMENTATION_ROADMAP.md]

Affected repositories (generate one commit per repo that had changes):
- knk-web-api-v2
- knk-web-app
- knk-plugin-v2
- docs

For each repository, generate:
1. **Subject line:** Following docs/GIT_COMMIT_CONVENTIONS.md
   - Format: <type>(<scope>): <subject>
   - Type: feat, fix, refactor, etc.
   - Scope: relevant module/component
   - Max 50 characters, lowercase, imperative

2. **Description:**
   - Explain what was implemented (what)
   - Explain why each change was made (why)
   - Wrap at 72 characters
   - Include implementation notes if relevant
   - Add reference to feature roadmap doc

Reference example commits from docs/GIT_COMMIT_CONVENTIONS.md (section: Plugin examples)

Output format:
---
## knk-web-api-v2
**Subject:** [commit subject]
**Description:** [commit description]

## knk-web-app
**Subject:** [commit subject]
**Description:** [commit description]

...
---

================================================================================
EOF
    ;;

  *)
    echo "Error: Unknown step '$STEP'"
    echo ""
    echo "Valid steps: refinement, requirements, roadmap, impl, test, commit"
    exit 1
    ;;
esac

echo ""
echo "💡 Tip: Copy the prompt above and paste it into your AI chat."
echo "   Replace [feature-name], [phase], etc. with actual values."
echo ""
echo "📚 Reference: docs/AI_FEATURE_IMPLEMENTATION_WORKFLOW.md"
