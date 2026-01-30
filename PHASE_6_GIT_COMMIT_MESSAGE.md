test(plugin-auth): implement Phase 6 - comprehensive testing infrastructure

Add complete testing suite for user account management features including
unit tests, integration tests, and manual testing documentation.

## Test Coverage

### Unit Tests (41 methods, 954 LOC)
- ChatCaptureManagerTest: 25 test methods
  * Account create flow validation
  * Account merge flow validation
  * Session management
  * Email/password validation
  * Edge case handling
  
- UserManagerTest: 16 test methods
  * Player join handling
  * Cache management
  * Configuration access
  * Thread safety verification

### Integration Tests (9 methods, 437 LOC)
- AccountCommandIntegrationTest
  * Full /account create flow
  * Full /account link flow
  * API error handling
  * Merge conflict resolution
  * Retry/timeout handling

### Manual Testing (25 scenarios)
- PHASE_6_MANUAL_TESTING_CHECKLIST.md
  * Player join scenarios (new & existing)
  * Command validation (/account create, /account link, /account)
  * Error handling (network, timeout, validation)
  * Edge cases (concurrent sessions, permissions, rate limiting)
  * Performance tests (load, memory leaks)
  * Bug report templates

## Technical Details

**Files Created**:
- knk-paper/src/test/java/net/knightsandkings/knk/paper/chat/ChatCaptureManagerTest.java
- knk-paper/src/test/java/net/knightsandkings/knk/paper/user/UserManagerTest.java
- knk-paper/src/test/java/net/knightsandkings/knk/paper/integration/AccountCommandIntegrationTest.java
- docs/ai/plugin-auth/PHASE_6_MANUAL_TESTING_CHECKLIST.md
- docs/ai/plugin-auth/PHASE_6_COMPLETION_REPORT.md

**Testing Framework**:
- JUnit 5 for test structure
- Mockito for mocking dependencies
- AAA (Arrange-Act-Assert) pattern
- Nested test classes for organization
- CompletableFuture async testing

**Test Statistics**:
- Total automated tests: 50 methods
- Total lines of test code: 1,391
- Manual test scenarios: 25
- Coverage: Unit + Integration + Manual

## Notes

Manual testing is the primary validation method due to Minecraft plugin
environment complexity. Automated tests provide logic validation and
regression prevention. All tests compile successfully.

Phase: 6/7 (Testing)
Roadmap: docs/ai/plugin-auth/PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md
Next Phase: Phase 7 - Documentation
