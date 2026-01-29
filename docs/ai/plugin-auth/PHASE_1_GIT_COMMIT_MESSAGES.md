# Phase 1 Git Commit Messages

**Feature**: plugin-auth  
**Phase**: 1 - Foundation (API Client & Configuration)  
**Date**: January 29, 2026  
**Status**: Ready for commit

---

## Repository: knk-plugin-v2

### Subject
```
feat(api-client): add user account management foundation
```

### Description
```
Implement Phase 1 of user account management for the Minecraft plugin,
establishing foundational API client infrastructure to communicate with
the backend user management endpoints.

This foundation enables the plugin to create accounts, generate link
codes, validate credentials, and handle account merging/linking flows
through a type-safe Java API client layer.

Components added:

DTOs (9 classes in knk-api-client/dto/user/):
- CreateUserRequest: supports minimal (UUID+username), full (email+password),
  and link code creation flows
- UserResponse: complete user data with id, username, UUID, email, coins,
  gems, experiencePoints, emailVerified, accountCreatedVia
- LinkCodeResponse: link code generation with code, expiresAt, formattedCode
- ValidateLinkCodeResponse: validation result with isValid, userId, username,
  email, error message
- DuplicateCheckResponse: duplicate detection with hasDuplicate,
  conflictingUser, primaryUser, message
- ChangePasswordRequest: password change with currentPassword, newPassword,
  passwordConfirmation
- LinkAccountRequest: account linking with linkCode, email, password,
  passwordConfirmation
- MergeAccountsRequest: account merge with primaryUserId, secondaryUserId
- LinkCodeRequest: link code generation with userId

API layer (knk-api-client/api/):
- UserAccountApi interface: 8 methods for all user account operations
- UserAccountApiImpl: complete HTTP client implementation using OkHttp,
  extends BaseApiImpl, includes error handling, logging, URL encoding
- KnkApiClient: integrated UserAccountApi with getUserAccountApi() getter

Configuration (knk-paper/config/):
- AccountConfig: linkCodeExpiryMinutes (20 min default),
  chatCaptureTimeoutSeconds (120 sec default), validation logic
- MessagesConfig: 7 message templates with format() helper for placeholder
  replacement (prefix, accountCreated, accountLinked, linkCodeGenerated,
  invalidLinkCode, duplicateAccount, mergeComplete)
- ConfigLoader: loads account and messages sections from config.yml with
  graceful defaults
- config.yml: added account and messages sections with default values

API endpoints mapped (all 8):
- POST /api/Users (create user)
- POST /api/Users/check-duplicate (detect duplicate accounts)
- POST /api/Users/generate-link-code (generate link code)
- POST /api/Users/validate-link-code/{code} (validate link code)
- PUT /api/Users/{id}/update-email (update email)
- PUT /api/Users/{id}/change-password (change password)
- POST /api/Users/merge (merge accounts)
- POST /api/Users/link-account (link account via code)

Build: All modules compile successfully (knk-core, knk-api-client, knk-paper)
Lines added: ~490 (11 new files, 4 modified files)
Dependencies: Uses existing OkHttp 4.12.0 and Jackson 2.17.2
Next: Phase 2 - Player Join Handler & User Sync

Related: docs/ai/plugin-auth/PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md
```

---

## Repository: docs

### Subject
```
docs(plugin-auth): add Phase 1 completion report
```

### Description
```
Document completion of Phase 1 implementation for user account management
in the Minecraft plugin.

This report summarizes all deliverables, acceptance criteria, build status,
and next steps for Phase 2. Created to track progress and maintain clear
documentation of the implementation roadmap.

Files added:
- docs/ai/plugin-auth/PHASE_1_COMPLETION_REPORT.md

The report includes:
- Summary of all deliverables (9 DTOs, API interface, implementation, config)
- API endpoints mapping table (8 endpoints)
- Build status verification (all modules SUCCESS)
- Code quality patterns followed
- Acceptance criteria checklist (all met)
- Draft commit message for Phase 1
- Next steps for Phase 2

Related: docs/ai/plugin-auth/PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md
```

---

## Git Commands (Execute These)

### For knk-plugin-v2
```bash
cd Repository/knk-plugin-v2

# Stage all Phase 1 changes
git add knk-api-client/src/main/java/net/knightsandkings/knk/api/dto/user/
git add knk-api-client/src/main/java/net/knightsandkings/knk/api/UserAccountApi.java
git add knk-api-client/src/main/java/net/knightsandkings/knk/api/impl/UserAccountApiImpl.java
git add knk-api-client/src/main/java/net/knightsandkings/knk/api/client/KnkApiClient.java
git add knk-paper/src/main/java/net/knightsandkings/knk/paper/config/KnkConfig.java
git add knk-paper/src/main/java/net/knightsandkings/knk/paper/config/ConfigLoader.java
git add knk-paper/src/main/resources/config.yml

# Commit with message
git commit -m "feat(api-client): add user account management foundation

Implement Phase 1 of user account management for the Minecraft plugin,
establishing foundational API client infrastructure to communicate with
the backend user management endpoints.

This foundation enables the plugin to create accounts, generate link
codes, validate credentials, and handle account merging/linking flows
through a type-safe Java API client layer.

Components added:

DTOs (9 classes in knk-api-client/dto/user/):
- CreateUserRequest: supports minimal (UUID+username), full (email+password),
  and link code creation flows
- UserResponse: complete user data with id, username, UUID, email, coins,
  gems, experiencePoints, emailVerified, accountCreatedVia
- LinkCodeResponse: link code generation with code, expiresAt, formattedCode
- ValidateLinkCodeResponse: validation result with isValid, userId, username,
  email, error message
- DuplicateCheckResponse: duplicate detection with hasDuplicate,
  conflictingUser, primaryUser, message
- ChangePasswordRequest: password change with currentPassword, newPassword,
  passwordConfirmation
- LinkAccountRequest: account linking with linkCode, email, password,
  passwordConfirmation
- MergeAccountsRequest: account merge with primaryUserId, secondaryUserId
- LinkCodeRequest: link code generation with userId

API layer (knk-api-client/api/):
- UserAccountApi interface: 8 methods for all user account operations
- UserAccountApiImpl: complete HTTP client implementation using OkHttp,
  extends BaseApiImpl, includes error handling, logging, URL encoding
- KnkApiClient: integrated UserAccountApi with getUserAccountApi() getter

Configuration (knk-paper/config/):
- AccountConfig: linkCodeExpiryMinutes (20 min default),
  chatCaptureTimeoutSeconds (120 sec default), validation logic
- MessagesConfig: 7 message templates with format() helper for placeholder
  replacement (prefix, accountCreated, accountLinked, linkCodeGenerated,
  invalidLinkCode, duplicateAccount, mergeComplete)
- ConfigLoader: loads account and messages sections from config.yml with
  graceful defaults
- config.yml: added account and messages sections with default values

API endpoints mapped (all 8):
- POST /api/Users (create user)
- POST /api/Users/check-duplicate (detect duplicate accounts)
- POST /api/Users/generate-link-code (generate link code)
- POST /api/Users/validate-link-code/{code} (validate link code)
- PUT /api/Users/{id}/update-email (update email)
- PUT /api/Users/{id}/change-password (change password)
- POST /api/Users/merge (merge accounts)
- POST /api/Users/link-account (link account via code)

Build: All modules compile successfully (knk-core, knk-api-client, knk-paper)
Lines added: ~490 (11 new files, 4 modified files)
Dependencies: Uses existing OkHttp 4.12.0 and Jackson 2.17.2
Next: Phase 2 - Player Join Handler & User Sync

Related: docs/ai/plugin-auth/PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md"
```

### For docs
```bash
cd <workspace_root>

# Stage documentation
git add docs/ai/plugin-auth/PHASE_1_COMPLETION_REPORT.md
git add docs/ai/plugin-auth/PHASE_1_GIT_COMMIT_MESSAGES.md

# Commit with message
git commit -m "docs(plugin-auth): add Phase 1 completion report

Document completion of Phase 1 implementation for user account management
in the Minecraft plugin.

This report summarizes all deliverables, acceptance criteria, build status,
and next steps for Phase 2. Created to track progress and maintain clear
documentation of the implementation roadmap.

Files added:
- docs/ai/plugin-auth/PHASE_1_COMPLETION_REPORT.md
- docs/ai/plugin-auth/PHASE_1_GIT_COMMIT_MESSAGES.md

The report includes:
- Summary of all deliverables (9 DTOs, API interface, implementation, config)
- API endpoints mapping table (8 endpoints)
- Build status verification (all modules SUCCESS)
- Code quality patterns followed
- Acceptance criteria checklist (all met)
- Draft commit message for Phase 1
- Next steps for Phase 2

Related: docs/ai/plugin-auth/PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md"
```

---

## Commit Checklist

Before executing commits, verify:

### knk-plugin-v2
- [x] Subject: `feat(api-client): add user account management foundation`
- [x] Subject is under 50 characters (47 chars)
- [x] Subject is lowercase and imperative mood
- [x] Subject has no period at the end
- [x] Description exists and explains what/why
- [x] Description paragraphs wrap at 72 characters
- [x] Description includes component breakdown
- [x] Description references roadmap document
- [x] Footer includes related documentation link

### docs
- [x] Subject: `docs(plugin-auth): add Phase 1 completion report`
- [x] Subject is under 50 characters (47 chars)
- [x] Subject is lowercase and imperative mood
- [x] Subject has no period at the end
- [x] Description exists and explains what/why
- [x] Description paragraphs wrap at 72 characters
- [x] Description references roadmap document

---

## Notes

1. **No commits for knk-web-api-v2 or knk-web-app**: Phase 1 only affected the plugin
   and documentation repositories.

2. **Follow-up**: After committing, consider pushing to remote and creating a PR if
   working in a feature branch.

3. **Verification**: Run `git log -1 --oneline` after each commit to verify the
   subject line appears correctly.

4. **Future phases**: Use this same template structure for Phase 2+ commits,
   updating the phase number and deliverables accordingly.

---

**Generated**: January 29, 2026  
**Conventions**: docs/GIT_COMMIT_CONVENTIONS.md  
**Status**: Ready for execution
