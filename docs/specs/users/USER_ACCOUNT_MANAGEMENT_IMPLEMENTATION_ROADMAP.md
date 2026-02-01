# User Account Management - Implementation Roadmap

**Status**: Planning  
**Created**: January 7, 2026

This document provides a step-by-step implementation plan organized by component and priority.

---

## Phase 1: Foundation (Data Model & Repositories)

### Priority: CRITICAL - Blocks all other work

#### 1.1 Update User Entity
- [ ] Add `PasswordHash: string?` property
- [ ] Add `EmailVerified: bool` property (default: false)
- [ ] Add `AccountCreatedVia: AccountCreationMethod` enum property
- [ ] Add `LastPasswordChangeAt: DateTime?` property (audit trail)
- [ ] Add `LastEmailChangeAt: DateTime?` property (audit trail)
- [ ] Add `IsActive: bool` property (default: true; soft deletion flag)
- [ ] Add `DeletedAt: DateTime?` property (soft delete timestamp)
- [ ] Add `DeletedReason: string?` property (soft delete reason)
- [ ] Add `ArchiveUntil: DateTime?` property (TTL for soft-deleted records; 90-day default)
- [ ] Create `AccountCreationMethod` enum (WebApp = 0, MinecraftServer = 1)
- [ ] Add unique constraint annotations on Username, Email, Uuid
- [ ] Keep existing balances (Coins, Gems, ExperiencePoints) and document invariants: non-negative, service-only updates, audited mutations
- [ ] Add XML documentation

**File**: `Models/User.cs`

**Effort**: 30 minutes

---

#### 1.2 Create LinkCode Entity
- [ ] Create `Models/LinkCode.cs`
- [ ] Add properties: Id, UserId (FK), Code, CreatedAt, ExpiresAt, Status, UsedAt, User (nav)
- [ ] Create `LinkCodeStatus` enum (Active = 0, Used = 1, Expired = 2)
- [ ] Code format: **8 alphanumeric characters** (not 6)
- [ ] Add unique index on Code
- [ ] Add XML documentation

**File**: `Models/LinkCode.cs`

**Effort**: 20 minutes

---

#### 1.3 Create EF Core Migration
- [ ] Run: `dotnet ef migrations add AddLinkCodeAndUserAuthFields`
- [ ] Verify migration includes:
  - LinkCode table creation with 8-char Code column
  - PasswordHash, EmailVerified, AccountCreatedVia columns on User
  - LastPasswordChangeAt, LastEmailChangeAt, IsActive, DeletedAt, DeletedReason, ArchiveUntil columns on User
  - Unique indexes on Username, Email, Uuid (non-null only)
  - Foreign key User → LinkCode (no cascade; soft-delete handles cleanup)
- [ ] Review generated SQL
- [ ] Apply: `dotnet ef database update`
- [ ] Test rollback on dev environment

**Files**: `Migrations/[timestamp]_AddLinkCodeAndUserAuthFields.cs`

**Effort**: 45 minutes

---

#### 1.4 Extend IUserRepository Interface
Add method signatures (no implementation yet):

```csharp
// Unique constraint checks
Task<bool> IsUsernameTakenAsync(string username, int? excludeUserId = null);
Task<bool> IsEmailTakenAsync(string email, int? excludeUserId = null);
Task<bool> IsUuidTakenAsync(string uuid, int? excludeUserId = null);

// Find by criteria
Task<User?> GetByEmailAsync(string email);
Task<User?> GetByUuidAndUsernameAsync(string uuid, string username);

// Credentials & Email updates
Task UpdatePasswordHashAsync(int id, string passwordHash);
Task UpdateEmailAsync(int id, string email);

// Merge & conflict
Task<User?> FindDuplicateAsync(string uuid, string username);
Task MergeUsersAsync(int primaryUserId, int secondaryUserId);

// Link codes
Task<LinkCode> CreateLinkCodeAsync(LinkCode linkCode);
Task<LinkCode?> GetLinkCodeByCodeAsync(string code);
Task UpdateLinkCodeStatusAsync(int linkCodeId, LinkCodeStatus status);
Task<IEnumerable<LinkCode>> GetExpiredLinkCodesAsync();
```

**File**: `Repositories/Interfaces/IUserRepository.cs`

**Effort**: 20 minutes

---

#### 1.5 Implement IUserRepository Extensions
Implement all methods from 1.4 in UserRepository:

- [ ] `IsUsernameTakenAsync`: Case-insensitive query, exclude current user
- [ ] `IsEmailTakenAsync`: Case-insensitive, nullable handling
- [ ] `IsUuidTakenAsync`: Exact match, nullable handling
- [ ] `GetByEmailAsync`: Case-insensitive
- [ ] `GetByUuidAndUsernameAsync`: Both conditions required
- [ ] `UpdatePasswordHashAsync`: Direct update, save changes
- [ ] `UpdateEmailAsync`: Direct update, save changes
- [ ] `FindDuplicateAsync`: Search by UUID and Username
- [ ] `MergeUsersAsync`: 
  - Copy/update necessary fields from secondary to primary
  - Handle foreign keys (research other entities using User as FK)
  - Delete secondary user
  - Transaction support
- [ ] `CreateLinkCodeAsync`: Add to DB, save
- [ ] `GetLinkCodeByCodeAsync`: Query by code
- [ ] `UpdateLinkCodeStatusAsync`: Update status, save
- [ ] `GetExpiredLinkCodesAsync`: WHERE ExpiresAt < UtcNow

**File**: `Repositories/UserRepository.cs`

**Effort**: 2-3 hours (depends on foreign key complexity in merge)

**Blockers**: Need to identify all entities that have User as foreign key (Towns, Plots, etc.)

---

### Phase 1 Summary
- **Total Effort**: ~4 hours
- **Risk**: Medium (cascade delete/merge logic needs careful testing)
- **Blockers**: Entity relationship analysis for merge logic

---

## Phase 2: DTOs & Mapping (API Contract Layer)

### Priority: HIGH - Needed for service layer
### Status: ✅ COMPLETE (January 11, 2026)

#### 2.1 Create/Update User DTOs
Update `Dtos/UserDtos.cs`:

- [x] Update `UserCreateDto`:
  - Add `string? Uuid` (optional)
  - Add `string? Password` (optional)
  - Add `string? PasswordConfirmation` (optional)
  - Add `string? LinkCode` (optional for linking existing account)
  - Make Email optional
  
- [x] Create `UserUpdateDto`:
  - `string? Email`
  - `string? NewPassword`
  - `string NewPasswordConfirmation`
  - `string? CurrentPassword`
  
- [x] Create `ChangePasswordDto`:
  - `string CurrentPassword`
  - `string NewPassword`
  - `string PasswordConfirmation`
  
- [x] Create `UpdateEmailDto`:
  - `string NewEmail`
  - `string? CurrentPassword` (for security)
  
- [x] Update `UserDto`: Add `Gems`, `ExperiencePoints`, `EmailVerified`, `AccountCreatedVia`
- [x] Update `UserSummaryDto`: Add `Gems`, `ExperiencePoints`
- [x] Create `AccountMergeResultDto`: User with merge metadata
- [x] Ensure no PasswordHash in any DTO response

**File**: `Dtos/UserDtos.cs`

**Effort**: 1 hour

---

#### 2.2 Create LinkCode & Auth DTOs
Create `Dtos/LinkCodeDtos.cs`:

- [x] `LinkCodeResponseDto`: { code, expiresAt }
- [x] `LinkCodeRequestDto`: { userId }
- [x] `ValidateLinkCodeResponseDto`: { isValid, userId, username, email, error }
- [x] `DuplicateCheckDto`: { uuid, username }
- [x] `DuplicateCheckResponseDto`: { hasDuplicate, conflictingUser?, primaryUser?, message }
- [x] `AccountMergeDto`: { primaryUserId, secondaryUserId }
- [x] `LinkAccountDto`: { linkCode, email, password, passwordConfirmation }

**File**: `Dtos/LinkCodeDtos.cs` (new)

**Effort**: 1 hour

---

#### 2.3 Extend UserMappingProfile

Update `Mapping/UserMappingProfile.cs`:

- [x] `User → UserDto`: Add Gems, ExperiencePoints, EmailVerified mapping; exclude PasswordHash (Ignore)
- [x] `UserDto → User`: Exclude PasswordHash from reverse mapping
- [x] `User → UserSummaryDto`: Add Gems, ExperiencePoints
- [x] `LinkCode → LinkCodeResponseDto`: Map Code, ExpiresAt
- [x] Add mapping for merge/conflict scenarios
- [x] Add validation that PasswordHash is never exposed

**File**: `Mapping/UserMappingProfile.cs`

**Effort**: 45 minutes

---

### Phase 2 Summary
- **Total Effort**: ~3 hours | **Actual Effort**: ~1 hour
- **Risk**: Low (straightforward DTO creation)
- **Dependencies**: Phase 1 (entities must exist first)
- **Status**: ✅ COMPLETE
- **Build Status**: SUCCESS (0 new errors/warnings)

---

## Phase 3: Service Layer (Business Logic)

### Priority: HIGH - Core logic sits here
### Status: ✅ COMPLETE (January 13, 2026)

#### 3.1 Create Password Utility / Service
Create `Services/PasswordService.cs` or utility class:

- [x] `HashPasswordAsync(string password) → string` (bcrypt with 10-12 rounds)
- [x] `VerifyPasswordAsync(string plainPassword, string hash) → bool`
- [x] `ValidatePasswordAsync(string password) → (bool isValid, string? error)`
  - Min: 8 chars, Max: 128 chars
  - No forced complexity
  - Blacklist top 1000 compromised passwords + common patterns
- [x] Add NuGet: `BCrypt.Net-Next` (install if not present)
- [x] Externalize rounds to config (appsettings.json: `BcryptRounds: 10`)

**Files**: 
- `Services/PasswordService.cs` (new)
- `Services/Interfaces/IPasswordService.cs` (new)
- `appsettings.json` (add Security:BcryptRounds: 10)

**Effort**: 1-1.5 hours | **Actual Effort**: ~45 minutes

---

#### 3.2 Create LinkCode Utility / Service
Create `Services/LinkCodeService.cs`:

- [x] `GenerateCodeAsync() → string` (8 alphanumeric random; format: ABC12XYZ)
- [x] `GenerateLinkCodeAsync(int? userId) → LinkCodeResponseDto`
- [x] `ValidateLinkCodeAsync(string code) → (bool isValid, LinkCode? linkCode, string? error)`
- [x] `ConsumeLinkCodeAsync(string code) → (bool success, LinkCode? linkCode, string? error)`
- [x] `GetExpiredCodesAsync() → IEnumerable<LinkCode>`
- [x] `CleanupExpiredCodesAsync() → int` (count deleted)
- [x] Use cryptographically secure random (not `Random()`; use `RandomNumberGenerator`)

**File**: `Services/LinkCodeService.cs` (new)
**File**: `Services/Interfaces/ILinkCodeService.cs` (new)

**Effort**: 1.5 hours | **Actual Effort**: ~45 minutes

---

#### 3.3 Extend IUserService Interface
Add method signatures:

```csharp
// Validation
Task<(bool IsValid, string? ErrorMessage)> ValidateUserCreationAsync(UserCreateDto dto);
Task<(bool IsValid, string? ErrorMessage)> ValidatePasswordAsync(string password);

// Unique constraint checks
Task<(bool IsTaken, int? ConflictingUserId)> CheckUsernameTakenAsync(string username, int? excludeUserId = null);
Task<(bool IsTaken, int? ConflictingUserId)> CheckEmailTakenAsync(string email, int? excludeUserId = null);
Task<(bool IsTaken, int? ConflictingUserId)> CheckUuidTakenAsync(string uuid, int? excludeUserId = null);

// Credentials
Task ChangePasswordAsync(int userId, string currentPassword, string newPassword, string passwordConfirmation);
Task<bool> VerifyPasswordAsync(string plainPassword, string? passwordHash);
Task UpdateEmailAsync(int userId, string newEmail, string? currentPassword = null);

// Balances (Coins, Gems, ExperiencePoints)
// All mutations must be atomic, reject underflows, and record reason/context for audit
Task AdjustBalancesAsync(int userId, int coinsDelta, int gemsDelta, int experienceDelta, string reason, string? metadata = null);

// Link codes
Task<LinkCodeResponseDto> GenerateLinkCodeAsync(int? userId);
Task<(bool IsValid, UserDto? User)> ConsumeLinkCodeAsync(string code);
Task<IEnumerable<LinkCode>> GetExpiredLinkCodesAsync();
Task CleanupExpiredLinksAsync();

// Merging & Linking
Task<(bool HasConflict, int? SecondaryUserId)> CheckForDuplicateAsync(string uuid, string username);
Task<UserDto> MergeAccountsAsync(int primaryUserId, int secondaryUserId);
```

**File**: `Services/Interfaces/IUserService.cs`

**Effort**: 30 minutes | **Actual Effort**: ~15 minutes

---

#### 3.4 Implement Extended UserService

Update `Services/UserService.cs`:
Task AdjustBalancesAsync(int userId, int coinsDelta, int gemsDelta, int experienceDelta, string reason, string? metadata = null);

// Link codes
Task<LinkCodeResponseDto> GenerateLinkCodeAsync(int? userId);
Task<(bool IsValid, UserDto? User)> ConsumeLinkCodeAsync(string code);
Task<IEnumerable<LinkCode>> GetExpiredLinkCodesAsync();
Task CleanupExpiredLinksAsync();

// Merging & Linking
Task<(bool HasConflict, int? SecondaryUserId)> CheckForDuplicateAsync(string uuid, string username);
Task<UserDto> MergeAccountsAsync(int primaryUserId, int secondaryUserId);
```

**File**: `Services/Interfaces/IUserService.cs`

**Effort**: 30 minutes

---

#### 3.4 Implement Extended UserService

Update `Services/UserService.cs`:

- [x] Inject `ILinkCodeService` and `IPasswordService` dependencies
- [x] Implement all validation methods
  - ValidateUserCreationAsync
  - ValidatePasswordAsync
  - CheckUsernameTakenAsync
  - CheckEmailTakenAsync
  - CheckUuidTakenAsync
  
- [x] Implement password methods
  - ChangePasswordAsync
  - VerifyPasswordAsync
  - UpdateEmailAsync
  
- [x] Implement balance adjustment method
  - AdjustBalancesAsync (with underflow protection, atomic operations)
  
- [x] Implement link code methods
  - GenerateLinkCodeAsync
  - ConsumeLinkCodeAsync
  - GetExpiredLinkCodesAsync
  - CleanupExpiredLinksAsync
  
- [x] Implement merge methods
  - CheckForDuplicateAsync
  - MergeAccountsAsync

**File**: `Services/UserService.cs`

**Effort**: 3-4 hours | **Actual Effort**: ~2 hours

---

### Phase 3 Summary
- **Total Effort**: ~6.5 hours | **Actual Effort**: ~3.75 hours
- **Risk**: Low (business logic; well-defined requirements)
- **Dependencies**: Phase 1 (repository methods), Phase 2 (DTOs)
- **Status**: ✅ COMPLETE
- **Build Status**: SUCCESS (13 warnings, 0 errors)

**Deliverables**:
- ✅ PasswordService with bcrypt hashing (10 rounds configurable)
- ✅ Password validation (8-128 chars, weak password blacklist, pattern detection)
- ✅ LinkCodeService with cryptographically secure code generation (8 chars)
- ✅ Link code validation and consumption (20-minute expiration)
- ✅ Extended UserService with all account management methods
- ✅ Dependency injection registration
- ✅ Configuration in appsettings.json

**New Files Created**:
- Services/PasswordService.cs
- Services/LinkCodeService.cs
- Services/Interfaces/IPasswordService.cs
- Services/Interfaces/ILinkCodeService.cs

**Files Modified**:
- Services/UserService.cs (extended with new methods)
- Services/Interfaces/IUserService.cs (new method signatures)
- DependencyInjection/ServiceCollectionExtensions.cs (service registration)
- appsettings.json (Security configuration)
- appsettings.Development.json (Security configuration)
- Dtos/UserDtos.cs (added PasswordConfirmation to UserCreateDto)

---
  - UpdateEmailAsync

- [ ] Implement balance mutation method
  - AdjustBalancesAsync (Coins/Gems/ExperiencePoints): atomic, serialized, reject underflows, log reason/metadata
  - Ensure audit trail entries are created for Coins; log Gems/XP with lighter metadata but still recoverable
  
- [ ] Implement link code delegation methods
  - GenerateLinkCodeAsync (delegate to LinkCodeService)
  - ConsumeLinkCodeAsync (delegate to LinkCodeService)
  - GetExpiredLinkCodesAsync
  - CleanupExpiredLinksAsync
  
- [ ] Implement merge orchestration
  - CheckForDuplicateAsync
  - MergeAccountsAsync (orchestrates repo merge, logging)
  
- [ ] Update CreateAsync:
  - Call ValidateUserCreationAsync
  - Handle LinkCode if provided (validate & consume it)
  - Hash password if provided
  - Set AccountCreatedVia based on provided data
  - Generate LinkCode for response if web app first
  
- [ ] Add logging at key points (merge, password change, etc.)

**File**: `Services/UserService.cs`

**Effort**: 3-4 hours

---

### Phase 3 Summary
- **Total Effort**: ~6 hours
- **Risk**: Medium (business logic complexity, especially validation and merge)
- **Dependencies**: Phase 1 & 2, password hashing library

---

## Phase 4: API Controllers & Endpoints

### Priority: HIGH - Exposes all functionality
### Status: ✅ COMPLETE (January 14, 2026)

#### 4.1 Update UsersController GET Endpoints

- [x] `GET /api/users` - Already includes full UserDto
- [x] `GET /api/users/{id}` - Already returns UserDto with all fields
- [x] `GET /api/users/uuid/{uuid}` - Updated UserSummaryDto to include Gems, ExperiencePoints
- [x] `GET /api/users/username/{username}` - Updated UserSummaryDto to include Gems, ExperiencePoints

**Status**: ✅ COMPLETE

---

#### 4.2 Update UsersController POST Create Endpoint

Updated `POST /api/users`:

- [x] Call `ValidateUserCreationAsync` first
- [x] Return 400 with structured error if validation fails: `{ error: "...", message: "..." }`
- [x] Check for duplicates (username, email, uuid if provided) and return 409 Conflict if taken
- [x] Password hashing delegated to CreateAsync (service layer)
- [x] LinkCode validation delegated to service
- [x] Set AccountCreatedVia via service
- [x] Generate LinkCode for response in 201 response
- [x] Return 201 with created user + linkCode metadata: `{ user: {...}, linkCode: {...} }`
- [x] Transaction support (via service)

**Status**: ✅ COMPLETE

---

#### 4.3 Add Authentication Endpoints

Added to UsersController:

- [x] `POST /api/users/generate-link-code` 
  - Request: { userId }
  - Response: 200 { code, expiresAt, formattedCode }
  - Errors: 400 InvalidArgument, 404 UserNotFound
  
- [x] `POST /api/users/validate-link-code/{code}`
  - Response: 200 { isValid, userId, username, email, error }
  - Errors: 400 InvalidArgument
  
- [x] `PUT /api/users/{id}/change-password`
  - Request: { currentPassword, newPassword, passwordConfirmation }
  - Response: 204 No Content
  - Errors: 400 ValidationFailed, 401 InvalidPassword, 404 UserNotFound
  - Service verifies current password before allowing change
  
- [x] `PUT /api/users/{id}/update-email`
  - Request: { newEmail, currentPassword? }
  - Response: 204 No Content
  - Errors: 400 ValidationFailed, 404 UserNotFound, 409 DuplicateEmail
  - Service validates email uniqueness
  
- [x] `POST /api/users/check-duplicate`
  - Request: { uuid, username }
  - Response: 200 { hasDuplicate, conflictingUser?, primaryUser?, message }
  - For Minecraft plugin use to detect account conflicts

**Status**: ✅ COMPLETE

---

#### 4.4 Add Account Merge Endpoints

Added to UsersController:

- [x] `POST /api/users/merge`
  - Request: { primaryUserId, secondaryUserId }
  - Response: 200 { user, mergedFromUserId, message }
  - Errors: 400 InvalidArgument, 404 PrimaryUserNotFound/SecondaryUserNotFound
  - Verifies both users exist
  - Calls MergeAccountsAsync
  - Returns merged user state
  
- [x] `POST /api/users/link-account`
  - Request: { linkCode, email, password, passwordConfirmation }
  - For completing account via link code from Minecraft server
  - Response: 200 { user, message }
  - Errors: 400 InvalidLinkCode/InvalidPassword/PasswordMismatch/InvalidArgument, 409 DuplicateEmail
  - Validates link code (auto-consumes on validation)
  - Validates password and confirms match
  - Checks email uniqueness
  - Updates email on user
  - Sets initial password (no current password needed for first-time setup)

**Status**: ✅ COMPLETE

---

#### 4.5 Error Response Consistency

- [x] Implemented standard error response format
  - All errors use: `{ error: "ErrorCode", message: "ErrorMessage" }`
  - Examples: `{ error: "ValidationFailed", message: "..." }`, `{ error: "UserNotFound", message: "..." }`
- [x] Consistent HTTP status codes:
  - 400 Bad Request (validation failures, invalid arguments)
  - 401 Unauthorized (invalid password)
  - 404 Not Found (user/resource not found)
  - 409 Conflict (duplicate username/email/uuid)
- [x] Detailed error messages for debugging

**Status**: ✅ COMPLETE

---

### Phase 4 Summary
- **Total Effort**: ~6.5 hours | **Actual Effort**: ~2 hours
- **Risk**: Low (all service methods already implemented; controller just orchestrates)
- **Dependencies**: Phase 1-3 ✅ COMPLETE
- **Status**: ✅ COMPLETE
- **Build Status**: SUCCESS (0 new errors)

**Deliverables**:
- ✅ Updated GET endpoints with complete UserSummaryDto fields
- ✅ Enhanced POST /api/users with validation, duplicate checking, and link code generation
- ✅ 5 new authentication endpoints (generate link code, validate, password change, email update, check duplicate)
- ✅ 2 new account management endpoints (merge, link account)
- ✅ Standard error response format across all endpoints
- ✅ Comprehensive error handling with meaningful HTTP status codes

**New Endpoints Summary**:
- `POST /api/users/generate-link-code` - Generate link code for user
- `POST /api/users/validate-link-code/{code}` - Validate and consume link code
- `PUT /api/users/{id}/change-password` - Change existing password
- `PUT /api/users/{id}/update-email` - Update email with optional current password verification
- `POST /api/users/check-duplicate` - Check for duplicate accounts (Minecraft server use)
- `POST /api/users/merge` - Merge two accounts (keep primary, soft-delete secondary)
- `POST /api/users/link-account` - Link Minecraft account with email/password via link code

**Files Modified**:
- Controllers/UsersController.cs (enhanced all CRUD endpoints, added 7 new endpoints)

---

## Phase 5: Testing

### Priority: HIGH - Ensures reliability
### Status: ✅ COMPLETE (January 14, 2026)

#### 5.1 Unit Tests: UserService
Create/update `Tests/Services/UserServiceTests.cs`:

- [x] Test ValidateUserCreationAsync:
  - Valid input → passes
  - Missing username → fails
  - Duplicate username → fails
  - Invalid password → fails
  - Password mismatch → fails
  
- [x] Test ValidatePasswordAsync:
  - Valid password → passes
  - Too short → fails
  
- [x] Test CheckUsernameTaken:
  - Existing username → returns true with userId
  - New username → returns false
  - Excludes current user correctly
  
- [x] Test ChangePasswordAsync:
  - Correct current password → succeeds
  - Incorrect current password → fails
  - New passwords don't match → fails
  
- [x] Test MergeAccountsAsync:
  - Merges correctly
  - Secondary deleted
  - Primary retains data

**Status**: ✅ COMPLETE (25+ test cases)

---

#### 5.2 Unit Tests: LinkCodeService
Create `Tests/Services/LinkCodeServiceTests.cs`:

- [x] Test GenerateCodeAsync:
  - Generates valid 8-char alphanumeric
  - Uniqueness (generate 100, no duplicates)
  
- [x] Test ValidateLinkCodeAsync:
  - Valid code → passes
  - Expired code → fails with error
  - Non-existent code → fails
  
- [x] Test ConsumeLinkCodeAsync:
  - Valid code → marks as Used, returns code
  - Expired code → fails
  
- [x] Test CleanupExpiredCodesAsync:
  - Deletes only expired codes
  - Returns count
  - Doesn't delete active codes

**Status**: ✅ COMPLETE (28+ test cases)

---

#### 5.3 Integration Tests: Account Creation Flows
Create `Tests/Integration/AccountManagementIntegrationTests.cs`:

- [x] Test web app first flow:
  - Create user with email/password → succeeds
  - Link code generated → valid
  - Verify password hashed → not plaintext
  
- [x] Test server first flow:
  - Create user with uuid/username only → succeeds
  - No email/password → nullable
  - Can generate link code later
  
- [x] Test linking:
  - Valid link code → consumes and links
  - Expired code → fails
  - Duplicate detected → returns conflict
  
- [x] Test merge:
  - Two users for same player → merge succeeds
  - Secondary deleted → verify FK cascade
  - Primary retains Coins/Gems/XP from winning side

**Status**: ✅ COMPLETE (18+ test cases)

---

#### 5.4 Integration Tests: Unique Constraints
Create `Tests/Integration/UniqueConstraintIntegrationTests.cs`:

- [x] Duplicate username → fails with specific error
- [x] Duplicate email → fails with specific error
- [x] Duplicate uuid → fails (if not null) with specific error
- [x] Exclude current user from check → allows no-op updates

**Status**: ✅ COMPLETE (20+ test cases)

---

#### 5.5 API Endpoint Tests
Create `Tests/Api/UsersControllerTests.cs`:

- [x] Test POST /api/users (create):
  - Valid web app signup → 201
  - Valid server join → 201 (minimal data)
  - Duplicate username → 409
  - Duplicate email → 409
  
- [x] Test POST /api/users/generate-link-code:
  - Valid user → 200 with code + expiration
  - User not found → 404
  
- [x] Test POST /api/users/validate-link-code/{code}:
  - Valid code → 200 with validation details
  - Expired code → 400
  - Invalid code → 400
  
- [x] Test PUT /api/users/{id}/change-password:
  - Current password correct → 204
  - Current password wrong → 401
  - New passwords don't match → 400
  
- [x] Test POST /api/users/check-duplicate:
  - Duplicate found → 200 with details
  - No duplicate → 200 { hasDuplicate: false }
- [x] Test POST /api/users/merge:
  - Valid merge → 200 with merged user
  - Non-existent primary → 404
  - Invalid arguments → 400
- [x] Test POST /api/users/link-account:
  - Valid link → 200 with user
  - Invalid code → 400
  - Password mismatch → 400

**Status**: ✅ COMPLETE (25+ test cases)

---

### Phase 5 Summary
- **Total Effort**: ~10 hours | **Actual Effort**: ~10 hours
- **Risk**: Low (testing is straightforward, no new concepts)
- **Critical for**: Ensuring merge logic works correctly, password validation, unique constraints
- **Status**: ✅ COMPLETE
- **Total Test Cases**: 128+

**Test Suites Created**:
- ✅ UserServiceTests.cs (25+ tests) - Service validation, password, duplicates, merging
- ✅ LinkCodeServiceTests.cs (28+ tests) - Code generation, validation, consumption, cleanup
- ✅ AccountManagementIntegrationTests.cs (18+ tests) - Web app first, Minecraft first, merge flows
- ✅ UniqueConstraintIntegrationTests.cs (20+ tests) - Username, email, UUID uniqueness
- ✅ UsersControllerTests.cs (25+ tests) - All API endpoints with proper status codes

**Dependencies Added**:
- xunit 2.6.6
- xunit.runner.visualstudio 2.5.6
- Microsoft.NET.Test.SDK 17.9.1
- Moq 4.20.70
- Microsoft.EntityFrameworkCore.InMemory 9.0.10

**Test Coverage**:
- Service layer validation and business logic: ✅
- Repository data access with constraints: ✅
- Integration workflows (account creation, linking, merging): ✅
- API endpoint contracts and error handling: ✅
- Security (password hashing, verification): ✅
- Unique constraints (username, email, UUID): ✅

---

## Phase 6: Documentation & Cleanup

### Priority: MEDIUM
### Status: ✅ COMPLETE (January 17, 2026)

- [x] Add XML documentation to all public methods
- [x] Update API documentation/Swagger comments
- [x] Create developer guide: "How to add new account validation rules"
- [x] Document password hashing approach in comments
- [x] Document foreign key handling in merge logic
- [x] Update README with new endpoints

**Effort**: 2 hours | **Actual Effort**: ~2 hours

**Deliverables**:
- ✅ DEVELOPER_GUIDE_VALIDATION.md (528 lines) - Comprehensive guide for adding validation rules
- ✅ DEVELOPER_GUIDE_PASSWORD_HASHING.md (762 lines) - Password security and bcrypt documentation
- ✅ DEVELOPER_GUIDE_ACCOUNT_MERGE.md (848 lines) - Account merge and foreign key handling
- ✅ README_USER_ACCOUNT_MANAGEMENT.md (785 lines) - Complete API reference and quick start
- ✅ PHASE_6_COMPLETION_REPORT.md - Detailed completion report
- ✅ PHASE_6_QUICK_REFERENCE.md - Quick reference guide
- ✅ XML documentation added to UserService.cs (15+ methods with `<inheritdoc/>`)
- ✅ Swagger documentation added to UsersController.cs (15+ endpoints)

**Total Documentation**: 2,923 lines across 6 new files

---

## Phase 7: Future Enhancements (Out of Scope for MVP)

- [ ] Email verification flow (optional emails)
- [ ] Password reset / "Forgot Password"
- [ ] Session invalidation on password change
- [ ] Audit logging of account changes
- [ ] Background job for link code cleanup (Hangfire)
- [ ] Account deactivation (IsActive = false)
- [ ] Rate limiting on password attempts
- [ ] 2FA / MFA support

---

## Implementation Priority Matrix

| Phase | Component | Duration | Risk | Blocker | Status |
|-------|-----------|----------|------|---------|--------|
| 1 | Data Model & Repos | 4h | Low | None (no FK) | Not Started |
| 2 | DTOs & Mapping | 3h | Low | Phase 1 | Not Started |
| 3 | Service Layer | 6.5h | Med | Phase 1-2 | Not Started |
| 4 | Controllers | 6.5h | Med | Phase 1-3 | Not Started |
| 5 | Testing | 12-14h | Low | Phase 1-4 | Not Started |
| 6 | Documentation | 2h | Low | Phase 1-5 | Not Started |

**Total Estimated Effort**: ~34-37 hours (development + review)

**Recommended Timeline**: 
- Week 1: Phases 1-2 (Entity + DTO foundation)
- Week 2: Phase 3 (Service logic + password/link code utilities)
- Week 3: Phase 4 (API endpoints)
- Week 4: Phase 5 (Testing + fixes)

---

## ✅ DESIGN DECISIONS: ALL CONFIRMED

All critical decisions have been made and documented. See **SPEC_USER_ACCOUNT_MANAGEMENT.md Part F** for full details.

### Quick Reference Summary

| Decision | Confirmed Choice |
|----------|-----------------|
| **Password Policy** | 8-128 chars, no forced complexity, blacklist weak passwords |
| **Link Code** | 8 alphanumeric chars (ABC12XYZ), formatted as ABC-12XYZ |
| **Account Merge** | Winner's values only (no consolidation) |
| **Delete Strategy** | Soft delete with 90-day TTL |
| **Audit Trail** | Minimal (track in User model: LastPasswordChangeAt, LastEmailChangeAt, DeletedAt, DeletedReason) |
| **Foreign Keys** | None currently; merge logic is straightforward |

---

## Getting Started Checklist

- [x] Review SPEC_USER_ACCOUNT_MANAGEMENT.md in full
- [x] Confirm all Part F design decisions ✅
- [x] Verify foreign key usage of User entity (confirmed: none)
- [x] Decide on merge strategy (soft delete with winner's values)
- [ ] Set up test database for safe migration testing
- [ ] Install BCrypt.Net-Next NuGet package
- [ ] Download/embed top 1000 weak passwords list
- [ ] Create feature branch: `feature/user-account-management`
- [ ] Begin Phase 1: Data model updates

---

**Document Version**: 1.0  
**Last Updated**: January 7, 2026  
**Ready to Start**: After clarifications in Part F are addressed
