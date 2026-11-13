# knk-plugin archive

**Status:** Current · **Last updated:** 2026-11-13 (created, PandiO/knk-workspace#304)

Status, audit and fix reports that sat in the knk-plugin repo (root and `docs/`) until 2026-11-13. They were moved
here unchanged apart from a header and their links (code links point at knk-plugin `b8aa582f7a`, the commit they were
moved from). They are historical: check the current code and [plugin architecture](../../architecture/plugin-architecture.md)
before relying on them.

| File | What it was |
|---|---|
| [STATUS_V2_BASELINE.md](STATUS_V2_BASELINE.md) | Baseline of the new plugin, 2025-12-14 |
| [ARCHITECTURE_AUDIT.md](ARCHITECTURE_AUDIT.md) | Audit of the Health vertical slice, 2025-12-14 |
| [MIGRATION_MODE_READONLY.md](MIGRATION_MODE_READONLY.md) | The read-only migration rule of 2025-12 (superseded) |
| [MIGRATION_READONLY_AUDIT_TOWN_LOCATION.md](MIGRATION_READONLY_AUDIT_TOWN_LOCATION.md) | Read-only audit of towns and locations |
| [MIGRATION_STREET_READONLY_SELFCHECK.md](MIGRATION_STREET_READONLY_SELFCHECK.md) | Read-only self-check of streets |
| [API_ERROR_FIXES.md](API_ERROR_FIXES.md) | Region enter/exit fixes for an unreachable API |
| [PHASE_1_COMPLETION.md](PHASE_1_COMPLETION.md), [PHASE_1_STATUS.md](PHASE_1_STATUS.md) | Plugin-auth Phase 1, 2026-01-29 (the other phase reports are in [specs/plugin-auth](../../specs/plugin-auth/)) |
| [GRADLE_BUILD_ISSUE.md](GRADLE_BUILD_ISSUE.md) | Gradle compile-cache problem during that phase |
| [TEST_FAILURE_ANALYSIS.md](TEST_FAILURE_ANALYSIS.md), [TEST_FIXES_SUMMARY.md](TEST_FIXES_SUMMARY.md) | Plugin-auth test failures and their fixes, 2026-01-30 |
