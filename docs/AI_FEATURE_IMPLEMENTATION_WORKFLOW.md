# AI-Assisted Feature Implementation Workflow

## Overview

This document provides a streamlined, templated process for implementing feature roadmaps efficiently using AI assistance. It reduces prompt engineering effort, maintains consistency, and automates repetitive steps.

**Target workflow:** Ideation → Requirements → Roadmap → Phased Implementation → Git Commits → Merge to Main

---

## Phase 0: Setup & Documentation

### 0.1 Create a Feature Directory

Before starting, create a dedicated feature workspace in `docs/`:

```
docs/features/
├── <feature-name>/
│   ├── REQUIREMENTS.md        (generated in step 2)
│   ├── SPEC.md                (generated in step 2)
│   ├── IMPLEMENTATION_ROADMAP.md (generated in step 3)
│   ├── PHASE_STATUS.md        (track progress, created in step 4)
│   ├── DECISIONS.md           (document trade-offs)
│   └── COMMIT_HISTORY.md      (track all commits per phase)
```

### 0.2 Create a Master Prompt Template

Create `docs/.ai-prompts/FEATURE_IMPLEMENTATION_MASTER.md` containing reusable prompt sections:

```markdown
# Master Feature Implementation Prompt Template

## [STEP 1] Refinement Phase
> Use this when clarifying requirements with the user

## [STEP 2] Documentation Generation
> Use this to generate requirements, spec, and instructions

## [STEP 3] Roadmap Generation
> Use this to create the implementation roadmap

## [STEP 4] Phase Implementation
> Use this for each phase implementation

## [STEP 5] Commit Generation
> Use this to generate standardized commits

## [STEP 6] Testing Validation
> Use this to verify phase success
```

---

## Step 1: Ideation & Requirements Refinement

### 1.1 Initial Prompt Template

```
Feature Name: [feature-name]
Context: [brief description]
Related Components: [list affected repos]

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
```

### 1.2 Store Decisions

For each major decision, document in `DECISIONS.md`:
```markdown
## Decision: [Decision Title]
- **Date:** [date]
- **Context:** [why this decision mattered]
- **Options Considered:** [list]
- **Chosen:** [which option]
- **Rationale:** [why]
- **Impact:** [what changed]
```

---

## Step 2: Documentation Generation

### 2.1 Requirements & Spec Generation Prompt

```
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
```

### 2.2 Review & Validate

Checklist before proceeding to Step 3:
- [ ] Requirements clearly state "what"
- [ ] Spec clearly states "how" 
- [ ] All acceptance criteria are measurable
- [ ] No conflicts between requirements and current architecture
- [ ] All dependencies are documented

---

## Step 3: Implementation Roadmap Generation

### 3.1 Roadmap Generation Prompt

```
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
```

### 3.2 Initialize Phase Tracking

Create `PHASE_STATUS.md`:

```markdown
# [Feature Name] - Phase Status

| Phase | Title | Status | Commits | Notes |
|-------|-------|--------|---------|-------|
| 1 | [title] | ⬜ not-started | — | — |
| 2 | [title] | ⬜ not-started | — | — |
| 3 | [title] | ⬜ not-started | — | — |

## Phase Commits

### Phase 1
- [ ] knk-web-api-v2: (pending)
- [ ] knk-web-app: (pending)
- [ ] knk-plugin-v2: (pending)
- [ ] docs: (pending)

### Phase 2
...
```

---

## Step 4: Phase Implementation (Repeated for Each Phase)

### 4.1 Pre-Implementation Checklist

Before asking AI to implement:
- [ ] Feature branch created and checked out
- [ ] Phase status marked as "in-progress"
- [ ] All dependencies from previous phases are complete
- [ ] Reference implementations available if needed

### 4.2 Phase Implementation Prompt

```
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
```

### 4.3 Post-Implementation Checklist

- [ ] Code compiles without errors
- [ ] All files created match roadmap deliverables
- [ ] Tests pass (if applicable)
- [ ] No compilation warnings or style issues
- [ ] Documentation updated

### 4.4 Update Phase Status

```markdown
### Phase [number] - [title] ✅ COMPLETED (January 25, 2026)

**Status:** Ready for testing and commit generation

**Deliverables verified:**
- ✅ [list items from roadmap]
- ✅ [list items]

**Build results:**
- knk-web-api-v2: ✅ Successful
- knk-web-app: ✅ Successful
- knk-plugin-v2: ✅ Successful

**Next steps:** Testing → Commit generation → Phase [N+1]
```

---

## Step 5: Testing & Commit Generation

### 5.1 Testing Prompt (Optional/On-Demand)

```
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
```

### 5.2 Commit Generation Prompt

Once testing passes:

```
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
```

### 5.3 Execute Commits

After AI generates commit messages, execute them:

```bash
# For each repository with changes
git add .
git commit -m "Subject" -m "Description"
```

Then update `COMMIT_HISTORY.md`:

```markdown
## Phase [number] Commits

### knk-web-api-v2
- Commit: `[commit-hash]`
- Subject: [subject]
- Date: [date]

### knk-web-app
- Commit: `[commit-hash]`
- Subject: [subject]
- Date: [date]

...
```

---

## Step 6: Repeat for Next Phase

Loop back to Step 4 for each remaining phase:

1. Update `PHASE_STATUS.md` - mark current as "completed", next as "in-progress"
2. Run Step 4 implementation prompt
3. Run Step 5 testing/commit prompt
4. Execute commits
5. Repeat

---

## Advanced: Automation Scripts

### Script 1: Create Feature Workspace

```bash
#!/bin/bash
# create-feature.sh

FEATURE_NAME=$1

mkdir -p "docs/features/$FEATURE_NAME"
touch "docs/features/$FEATURE_NAME/REQUIREMENTS.md"
touch "docs/features/$FEATURE_NAME/SPEC.md"
touch "docs/features/$FEATURE_NAME/IMPLEMENTATION_ROADMAP.md"
touch "docs/features/$FEATURE_NAME/DECISIONS.md"
touch "docs/features/$FEATURE_NAME/PHASE_STATUS.md"
touch "docs/features/$FEATURE_NAME/COMMIT_HISTORY.md"

echo "Created feature workspace: docs/features/$FEATURE_NAME/"
echo "Next: Run Step 2 documentation generation prompt"
```

Usage: `./create-feature.sh my-feature-name`

### Script 2: Phase Implementation Checklist

```bash
#!/bin/bash
# phase-checklist.sh

FEATURE=$1
PHASE=$2

cat << EOF
========================================
Feature: $FEATURE - Phase $PHASE
========================================

PRE-IMPLEMENTATION:
[ ] Feature branch created
[ ] Phase marked in-progress
[ ] Dependencies from Phase $((PHASE-1)) are complete
[ ] Reference implementations reviewed

POST-IMPLEMENTATION:
[ ] Code compiles without errors
[ ] All deliverables present
[ ] Code style matches existing patterns
[ ] No breaking changes
[ ] Tests added/updated
[ ] Documentation updated

TESTING:
[ ] Run unit tests
[ ] Run integration tests
[ ] Verify acceptance criteria
[ ] Test edge cases

COMMIT:
[ ] Request commit messages from AI
[ ] Execute git commits
[ ] Push to feature branch
[ ] Update COMMIT_HISTORY.md

========================================
EOF
```

### Script 3: Generate AI Prompt from Template

```bash
#!/bin/bash
# generate-prompt.sh

FEATURE=$1
PHASE=$2
STEP=$3  # impl, test, commit

case $STEP in
  impl)
    echo "=== PHASE IMPLEMENTATION PROMPT ==="
    echo "Feature: $FEATURE"
    echo "Phase: $PHASE"
    cat << 'EOF'
[Insert Step 4.2 template above, with substitutions]
EOF
    ;;
  test)
    echo "=== TESTING PROMPT ==="
    echo "Feature: $FEATURE"
    echo "Phase: $PHASE"
    cat << 'EOF'
[Insert Step 5.1 template above]
EOF
    ;;
  commit)
    echo "=== COMMIT GENERATION PROMPT ==="
    echo "Feature: $FEATURE"
    echo "Phase: $PHASE"
    cat << 'EOF'
[Insert Step 5.2 template above]
EOF
    ;;
esac
```

---

## Quick Reference: Prompt Templates by Step

### Step 1: Refinement
**Effort:** ~10 min with AI  
**Outcome:** Validated requirements  
**Template:** Section 1.1

### Step 2: Documentation
**Effort:** ~20 min with AI  
**Outcome:** Requirements, Spec, Instructions  
**Template:** Section 2.1

### Step 3: Roadmap
**Effort:** ~15 min with AI  
**Outcome:** Phased roadmap  
**Template:** Section 3.1

### Step 4: Implementation (per phase)
**Effort:** ~30-60 min per phase with AI  
**Outcome:** Working code  
**Template:** Section 4.2

### Step 5: Commit Generation
**Effort:** ~10 min with AI  
**Outcome:** Git commits pushed  
**Template:** Section 5.2

**Total per feature:** ~2-4 hours of AI interaction spread across phases

---

## Tips for Maximum Efficiency

### 1. **Reuse Approved Documents**
Don't re-generate specs if they're solid. Reference them in every phase prompt.

### 2. **Create Prompt Aliases**
Create shell aliases or shell scripts that auto-populate feature/phase names:
```bash
alias ai-phase="echo 'Feature: [FEATURE] Phase: [PHASE]\n'; cat docs/.ai-prompts/PHASE_IMPLEMENTATION.md"
```

### 3. **Batch AI Requests**
Group related requests:
- Generation: Req + Spec + Roadmap in one interaction
- Implementation: Full phase in one request (don't ask per-file)
- Commits: Generate all 4 repo commits in one request

### 4. **Use Incremental Refinement**
If Phase 1 seems large, ask AI to split it further:
```
This phase seems large. Can you split it into Phase 1a (foundations) 
and Phase 1b (integration)?
```

### 5. **Maintain a PR Template**
Before merging, use a PR checklist:
```markdown
## Feature: [name]
## Status: Ready for Merge

- [ ] All phases complete
- [ ] All commits squashed/rebased
- [ ] Tests pass in CI
- [ ] Documentation updated
- [ ] Commits follow GIT_COMMIT_CONVENTIONS
- [ ] Reviewed by [team member]
```

### 6. **Version Your Roadmaps**
Add timestamps and revision notes:
```markdown
# [Feature] Implementation Roadmap

**Version:** 1.0  
**Last Updated:** January 25, 2026  
**Status:** Active

## Changes from v0.9
- Moved X to Phase 2 (was Phase 1)
- Split Y into separate deliverables
```

### 7. **Keep Phase Size Manageable**
Ideal phase = 1-2 working days of implementation  
If larger, split into smaller phases

### 8. **Document Blockers**
If a phase is blocked, document it:
```markdown
## Phase [X] - BLOCKED
- **Reason:** [reason]
- **Unblock date:** [estimated]
- **Workaround:** [if any]
```

---

## Integration with Existing Workflow

### With Feature Branches
```bash
git checkout -b feature/my-feature-name
# Step 1-3: Create docs
git add docs/features/my-feature-name/
git commit -m "docs: initialize feature roadmap for my-feature-name"

# Per phase:
# Step 4: Implement
# Step 5: Commit
git push origin feature/my-feature-name
```

### With GitHub/GitLab CI
Add to `.github/workflows/feature-validate.yml`:
```yaml
name: Feature Phase Validation
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Check PHASE_STATUS.md exists
        run: test -f docs/features/*/PHASE_STATUS.md
      - name: Build & Test (per phase requirements)
        run: ./gradlew build && npm test
```

### With Issue Tracking
Link phases to GitHub issues:
```markdown
## Phase [N]: [Title]
Tracked in: #[issue-number]
Status: [status]
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Phase takes longer than expected | Split into sub-phases; refine acceptance criteria |
| AI generates code that doesn't compile | Provide more specific build errors in next prompt |
| Commit messages vary in style | Reference GIT_COMMIT_CONVENTIONS.md in each prompt |
| Lost track of progress | Keep PHASE_STATUS.md updated after each phase |
| Unclear requirements | Return to Step 1; refine before continuing |
| Merge conflicts on main | Rebase feature branch: `git rebase main` |

---

## Example: Complete Workflow for One Feature

```
[User initiates feature]
  ↓
[Step 1: Refinement discussion with AI] → 10 min
  ↓
[Step 2: AI generates Requirements + Spec + Instructions] → 20 min
  ↓
[Step 3: AI generates Implementation Roadmap] → 15 min
  ↓
[Phase 1 Implementation cycle] → 40 min
  └─ Step 4: Implement Phase 1 → 30 min
  └─ Step 5: Generate + Execute Commits → 10 min
  ↓
[Phase 2 Implementation cycle] → 40 min
  ↓
[Phase 3 Implementation cycle] → 40 min
  ↓
[Testing & QA] → 30 min
  ↓
[Merge to main] → 5 min

TOTAL: ~3-4 hours of AI interaction + manual testing
```

---

## Checklist for Every Phase

Copy this before starting each phase:

```
## Phase [N] Implementation Checklist

### Pre-Implementation
- [ ] Feature branch exists and is current
- [ ] PHASE_STATUS.md shows Phase N as "in-progress"
- [ ] Previous phases are complete
- [ ] All referenced documents are up-to-date

### During Implementation
- [ ] Followed Step 4.2 prompt template
- [ ] Referenced REQUIREMENTS.md and SPEC.md
- [ ] Checked existing code patterns
- [ ] No compilation errors
- [ ] Tests added/updated

### Post-Implementation
- [ ] All deliverables from roadmap are present
- [ ] Code compiles without errors
- [ ] Style matches existing codebase
- [ ] No breaking changes to existing code
- [ ] Acceptance criteria verified

### Commit Generation
- [ ] Used Step 5.2 prompt template
- [ ] Generated commits for all affected repos
- [ ] Followed GIT_COMMIT_CONVENTIONS.md
- [ ] Executed git commits
- [ ] Updated COMMIT_HISTORY.md

### Phase Completion
- [ ] Updated PHASE_STATUS.md
- [ ] Pushed to feature branch
- [ ] Ready for next phase (or final testing)
```

---

## References

- [Git Commit Conventions](GIT_COMMIT_CONVENTIONS.md)
- [CODEMAP](CODEMAP.md) (for architecture reference)
- [Data Access Unification Example](features/data-access-unification/) (reference implementation)

---

**Version:** 1.0  
**Last Updated:** January 25, 2026  
**Status:** Active  
**Maintainer:** Development Team
