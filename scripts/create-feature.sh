#!/bin/bash
# create-feature.sh
# 
# Creates a feature workspace with template files for AI-assisted feature implementation.
# 
# Usage: ./scripts/create-feature.sh my-feature-name
#
# Creates:
#   docs/features/my-feature-name/
#   ├── REQUIREMENTS.md
#   ├── SPEC.md
#   ├── IMPLEMENTATION_ROADMAP.md
#   ├── PHASE_STATUS.md
#   ├── DECISIONS.md
#   └── COMMIT_HISTORY.md

set -e

if [ -z "$1" ]; then
    echo "Error: Feature name is required"
    echo "Usage: ./scripts/create-feature.sh <feature-name>"
    echo ""
    echo "Example: ./scripts/create-feature.sh my-feature-name"
    exit 1
fi

FEATURE_NAME=$1
FEATURE_DIR="docs/features/$FEATURE_NAME"

# Check if directory already exists
if [ -d "$FEATURE_DIR" ]; then
    echo "Error: Feature workspace already exists at $FEATURE_DIR"
    exit 1
fi

# Create directory structure
mkdir -p "$FEATURE_DIR"

# Create template files
touch "$FEATURE_DIR/REQUIREMENTS.md"
touch "$FEATURE_DIR/SPEC.md"
touch "$FEATURE_DIR/IMPLEMENTATION_ROADMAP.md"
touch "$FEATURE_DIR/PHASE_STATUS.md"
touch "$FEATURE_DIR/DECISIONS.md"
touch "$FEATURE_DIR/COMMIT_HISTORY.md"

# Success message
echo "✅ Created feature workspace: $FEATURE_DIR/"
echo ""
echo "Files created:"
echo "  - REQUIREMENTS.md (generated in Step 2)"
echo "  - SPEC.md (generated in Step 2)"
echo "  - IMPLEMENTATION_ROADMAP.md (generated in Step 3)"
echo "  - PHASE_STATUS.md (track progress)"
echo "  - DECISIONS.md (document trade-offs)"
echo "  - COMMIT_HISTORY.md (track commits per phase)"
echo ""
echo "Next steps:"
echo "  1. Follow Step 1 of docs/AI_FEATURE_IMPLEMENTATION_WORKFLOW.md for requirements refinement"
echo "  2. Use Step 2 prompt template to generate REQUIREMENTS.md and SPEC.md"
echo "  3. Use Step 3 prompt template to generate IMPLEMENTATION_ROADMAP.md"
echo ""
echo "Reference: docs/AI_FEATURE_IMPLEMENTATION_WORKFLOW.md"
