# create-feature.ps1
#
# Creates a feature workspace with template files for AI-assisted feature implementation.
# 
# Usage: .\scripts\create-feature.ps1 -FeatureName "my-feature-name"
#
# Creates:
#   docs/features/my-feature-name/
#   ├── REQUIREMENTS.md
#   ├── SPEC.md
#   ├── IMPLEMENTATION_ROADMAP.md
#   ├── PHASE_STATUS.md
#   ├── DECISIONS.md
#   └── COMMIT_HISTORY.md

param(
    [Parameter(Mandatory=$true, HelpMessage="Feature name (e.g., 'my-feature-name')")]
    [string]$FeatureName
)

$ErrorActionPreference = "Stop"

# Validate input
if ([string]::IsNullOrWhiteSpace($FeatureName)) {
    Write-Host "Error: Feature name is required" -ForegroundColor Red
    Write-Host "Usage: .\scripts\create-feature.ps1 -FeatureName 'my-feature-name'" -ForegroundColor Yellow
    exit 1
}

$featureDir = "docs/features/$FeatureName"

# Check if directory already exists
if (Test-Path $featureDir) {
    Write-Host "Error: Feature workspace already exists at $featureDir" -ForegroundColor Red
    exit 1
}

# Create directory structure
New-Item -ItemType Directory -Path $featureDir -Force | Out-Null

# Create template files
@(
    "REQUIREMENTS.md",
    "SPEC.md",
    "IMPLEMENTATION_ROADMAP.md",
    "PHASE_STATUS.md",
    "DECISIONS.md",
    "COMMIT_HISTORY.md"
) | ForEach-Object {
    New-Item -ItemType File -Path "$featureDir/$_" -Force | Out-Null
}

# Success message
Write-Host "`n✅ Created feature workspace: $featureDir/" -ForegroundColor Green
Write-Host ""
Write-Host "Files created:" -ForegroundColor Cyan
Write-Host "  - REQUIREMENTS.md (generated in Step 2)"
Write-Host "  - SPEC.md (generated in Step 2)"
Write-Host "  - IMPLEMENTATION_ROADMAP.md (generated in Step 3)"
Write-Host "  - PHASE_STATUS.md (track progress)"
Write-Host "  - DECISIONS.md (document trade-offs)"
Write-Host "  - COMMIT_HISTORY.md (track commits per phase)"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Follow Step 1 of docs/AI_FEATURE_IMPLEMENTATION_WORKFLOW.md for requirements refinement"
Write-Host "  2. Use Step 2 prompt template to generate REQUIREMENTS.md and SPEC.md"
Write-Host "  3. Use Step 3 prompt template to generate IMPLEMENTATION_ROADMAP.md"
Write-Host ""
Write-Host "Reference: docs/AI_FEATURE_IMPLEMENTATION_WORKFLOW.md" -ForegroundColor Yellow
