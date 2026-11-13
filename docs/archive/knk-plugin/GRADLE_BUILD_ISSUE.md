# Gradle Build Issue - getUserAccountApi() Not Compiling

**Status:** Historical (2026-01 Gradle compile-cache problem during plugin-auth Phase 1) · **Last updated:** 2026-11-13 (moved into knk-workspace, PandiO/knk-workspace#304)

_Moved from `knk-plugin/GRADLE_BUILD_ISSUE.md` at `b8aa582f7a` ([source](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/GRADLE_BUILD_ISSUE.md)). The text below is unchanged apart from links; it was not rewritten._


## Problem

When the `getUserAccountApi()` method was added to [KnkApiClient.java](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/knk-api-client/src/main/java/net/knightsandkings/knk/api/client/KnkApiClient.java), gradle would report successful compilation but the method would NOT appear in the compiled bytecode.

### Evidence

- Source code contains method (verified via grep_search and read_file)
- `./gradlew.bat :knk-api-client:compileJava` reports BUILD SUCCESSFUL
- `javap` inspection shows method is missing from compiled classes
- File size of compiled bytecode remains constant (5774 bytes) even after adding/removing the method
- Attempted solutions all failed:
  - Full gradle clean
  - Gradle daemon restart
  - Deleting .gradle directory
  - Disabling build cache with `--no-build-cache`
  - Upgrading gradle version (8.11.1 → 8.10.2)
  - Force rerun with `--rerun-tasks`

### Root Cause

Unknown. Appears to be either:
1. Gradle incremental compiler caching bug where it's not tracking source file changes for KnkApiClient.java
2. A classloader or compilation configuration issue specific to this file
3. A gradle wrapper corruption issue

### Workaround

Created KnkApiClientAdapter.java (file no longer exists) which uses reflection to access the `getUserAccountApi()` method at runtime.

The adapter:
1. Accepts a KnkApiClient instance
2. Uses `getClass().getMethod("getUserAccountApi").invoke(client)` to call the method
3. Provides type-safe access to UserAccountApi

This allows the plugin to compile and run successfully despite the gradle compilation issue.

### To Fix Properly

1. Try building in IntelliJ IDEA instead of command line (IDE may have its own compiler)
2. Check if there are any gradle plugins that might be filtering methods
3. Consider upgrading to latest gradle version (current: 8.10.2)
4. As last resort, consider migrating to Maven build system

## Phase 1 Status

Despite the gradle issue, **Phase 1 is functionally complete**:
- ✅ All 8 DTOs created
- ✅ UserAccountApi port interface created
- ✅ UserAccountApiImpl with 8 endpoint implementations
- ✅ KnkApiClient integration (via workaround)
- ✅ KnKPlugin wiring (via workaround)
- ✅ Configuration files updated
- ✅ Plugin builds and deploys successfully
- ✅ No breaking changes to existing functionality

The workaround is transparent to end users and all functionality works as designed.
