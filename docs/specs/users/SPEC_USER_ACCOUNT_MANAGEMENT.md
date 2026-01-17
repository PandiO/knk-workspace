# SPEC: User Account Management and Authentication Flows

**Status:** Requirements Definition  
**Last Updated:** January 7, 2026

## Overview

This specification defines the account creation, linking, and management flows for user accounts that span both the web application and Minecraft server. It covers the complete lifecycle of user account management, including password management, email linking, and account merging scenarios.

---

## Part A: General Requirements

### A.1 Account Creation Flows

#### Flow 1: Web App First
1. User fills out registration form (Email, Password, Minecraft Username)
2. System validates inputs and creates user account
3. User receives a **link code** (20-minute validity)
4. User joins Minecraft server later
5. System recognizes Minecraft UUID + Username
6. System prompts user to link accounts using the link code
7. Accounts are merged, UUID is recorded

#### Flow 2: Minecraft Server First
1. Player joins Minecraft server
2. System checks for existing user by UUID + Username
3. If not found, creates minimal user account (UUID, Username only)
4. Player can later provide email/password via `/account create` command
5. This triggers a step-by-step interactive procedure on the server

#### Flow 3: Minecraft to Web App (Deferred Email/Password)
1. Player has Minecraft-only account (no email/password)
2. Player executes `/account link` command on server
3. System generates a **link code** (20-minute validity)
4. Player uses link code in web app account creation form
5. System recognizes the code and links the new credentials to existing Minecraft account

### A.2 Link Code Lifecycle

- **Generation**: Created at three points:
  1. During web app account creation (sent to user)
  2. When user clicks `Generate Link Code` through web app account settings page
  3. When player executes `/account link` on Minecraft server
- **Format & Length**: **8 alphanumeric characters** (e.g., `ABC12XYZ`)
  - Formatted with hyphen for readability in UI: `ABC-12XYZ`
  - ~218 trillion possible combinations (62^8)
  - Significantly more secure than 6-char codes; still easily memorable/typeable
- **Validity**: 20 minutes from creation
- **Expiration Handling**: User must request new code via **Generation** points above
- **Storage**: Link codes must be stored in database with:
  - Associated User ID (nullable for web app first, populated for server-initiated)
  - Expiration timestamp
  - Status (active, used, expired)

### A.3 Unique Constraints

The following properties **must be globally unique** across all users:
- **UUID**: Once set, immutable and unique (null values allowed for web app-first accounts pre-linking)
- **Username**: Immutable and unique across both web app and Minecraft server
- **Email**: Unique and immutable once set (currently nullable for Minecraft-only accounts)

**Implementation Notes**:
- Database should enforce these constraints via unique indexes
- API and repository layer should validate before persistence
- Clear error messages if duplicate detected

### A.4 Password Management

- **Storage**: All passwords must be hashed using bcrypt (10-12 rounds; NOT plaintext)
- **Update Capability**: 
  - Via web app account settings page
  - Via `/account` command tree on Minecraft server
- **Validation Requirements** (Industry Standard - OWASP 2023):
  - Minimum length: **8 characters**
  - Maximum length: **128 characters**
  - **No forced complexity** (no requirement for uppercase, numbers, symbols)
  - **Blacklist weak passwords**: Reject top 1000 compromised passwords + common patterns (123456, password, qwerty, etc.)
  - Rationale: OWASP recommends length over complexity; users choose weak patterns when forced (P@ssw0rd!)
- **Confirmation**: Password changes should require current password verification for security

### A.5 Account Merging & Conflict Resolution

**Scenario**: Player created account on web app, then joins Minecraft server with same UUID/username, or attempts to link existing accounts.

**System Behavior**:
1. Detect that 2 user records exist for same player
2. Present user with both account states
3. Display primary stats for each:
   - Coins
   - Gems
   - Experience Points
4. User chooses which account to keep (winning account)
5. Losing account is **soft-deleted** with reason "Merged with user {primaryUserId}"
   - Set `IsActive = false`
   - Set `DeletedAt = UtcNow`
   - Set `DeletedReason = "Merged with user {primaryUserId}"`
   - Set `ArchiveUntil = UtcNow + 90 days`
6. **Winning account retains only its own values** (no consolidation):
   - Coins from winner
   - Gems from winner
   - Experience Points from winner
   - Email from winner (if set)
   - Password from winner (if set)
7. User is notified of completion with stats of merged account

**Data Retention**:
- Soft-deleted accounts remain in database for 90 days
- Can be recovered if merge was a mistake (support tool)
- After 90 days, eligible for hard delete via scheduled job
- Provides audit trail of deletions

### A.6 Email Verification

- **Current Decision**: Email verification is **optional**
- **Rationale**: User experience; not mandatory for account creation
- **Future Consideration**: May add optional email verification later (TBD)

### A.7 User Feedback & Notifications

All flows must provide:
- **Clear Status Messages**: At each step (success, error, pending confirmation)
- **Error Clarity**: Specific reasons for failures (duplicate email, invalid format, etc.)
- **Progress Indication**: For multi-step procedures (e.g., `/account create` step 1 of 3)
- **Next Steps**: Explicit guidance on what user should do next
- **Timeout Warnings**: For link code expiration (recommend warning at 15 minutes remaining)

---

## Part B: API (knk-web-api-v2) Requirements

### B.1 Data Model Updates

#### User Entity Extensions

The existing `User` model must support:

**New Properties**:
- `PasswordHash: string?` (nullable; for web app accounts; hashed via bcrypt, 10-12 rounds)
- `EmailVerified: bool` (default false; for future email verification)
- `AccountCreatedVia: AccountCreationMethod` (enum: WebApp, MinecraftServer)
- `LastPasswordChangeAt: DateTime?` (audit trail; track when password was last changed)
- `LastEmailChangeAt: DateTime?` (audit trail; track when email was last changed)
- `IsActive: bool` (default true; soft deletion flag)
- `DeletedAt: DateTime?` (soft delete timestamp; null if active)
- `DeletedReason: string?` (soft delete reason; e.g., "Merged with user 1")
- `ArchiveUntil: DateTime?` (TTL for soft-deleted records; after this date, hard delete eligible)

**Existing Properties to Ensure**:
- `Uuid: string` (unique, nullable initially)
- `Username: string` (unique, immutable)
- `Email: string?` (unique, optional for Minecraft-only)
- `Coins: int`
- `Gems: int`
- `ExperiencePoints: int`
- `CreatedAt: DateTime`

**Balance Mutation Rules (Coins, Gems, ExperiencePoints)**:
- No negative balances; operations that would underflow must fail (do not clamp)
- Mutations must be atomic and serialized to prevent race conditions
- Each mutation requires a reason/type; record metadata for auditability
- Coins must be logged to an audit trail; Gems and ExperiencePoints must also be logged (lighter logging acceptable for XP but still recoverable)
- No direct property setters in application code; updates go through service methods that enforce validation and logging

#### LinkCode Entity (New)

```csharp
public class LinkCode
{
    public int Id { get; set; }
    public int? UserId { get; set; }          // FK to User; nullable for web app first flow
    public string Code { get; set; }          // Unique, 8 alphanumeric chars (e.g., ABC12XYZ)
    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }   // 20 minutes from CreatedAt
    public LinkCodeStatus Status { get; set; } // Active, Used, Expired
    public DateTime? UsedAt { get; set; }      // When code was consumed (if Status = Used)
    
    // Navigation
    public User? User { get; set; }
}

public enum LinkCodeStatus
{
    Active = 0,
    Used = 1,
    Expired = 2
}

public enum AccountCreationMethod
{
    WebApp = 0,
    MinecraftServer = 1
}
```

### B.2 DTO Requirements

#### User DTOs

**Existing DTOs** (`UserDto`, `UserCreateDto`, `UserSummaryDto`, `UserListDto`) must be extended:

**New/Updated UserCreateDto**:
```csharp
public class UserCreateDto
{
    public string Username { get; set; } = null!;
    public string? Uuid { get; set; }           // Optional; for Minecraft-initiated flow
    public string? Email { get; set; }          // Optional for Minecraft-first
    public string? Password { get; set; }       // Optional for Minecraft-first
    public string? PasswordConfirmation { get; set; }
    public string? LinkCode { get; set; }       // For linking existing Minecraft account
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

**New UserUpdateDto** (for account settings changes):
```csharp
public class UserUpdateDto
{
    public string? Email { get; set; }
    public string? NewPassword { get; set; }
    public string NewPasswordConfirmation { get; set; }
    public string? CurrentPassword { get; set; } // Required to change password
}
```

**New LinkCodeRequestDto**:
```csharp
public class LinkCodeRequestDto
{
    public int UserId { get; set; }  // User requesting the code
}
```

**New LinkCodeResponseDto**:
```csharp
public class LinkCodeResponseDto
{
    public string Code { get; set; } = null!;
    public DateTime ExpiresAt { get; set; }
}
```

**New AccountMergeDto**:
```csharp
public class AccountMergeDto
{
    public int PrimaryUserId { get; set; }  // Account to keep
    public int SecondaryUserId { get; set; } // Account to delete
}
```

### B.3 Repository Requirements

#### IUserRepository Interface Extensions

Add the following methods:

```csharp
// Unique constraint checks
Task<bool> IsUsernameTakenAsync(string username, int? excludeUserId = null);
Task<bool> IsEmailTakenAsync(string email, int? excludeUserId = null);
Task<bool> IsUuidTakenAsync(string uuid, int? excludeUserId = null);

// Find by multiple criteria
Task<User?> GetByEmailAsync(string email);
Task<User?> GetByUuidAndUsernameAsync(string uuid, string username);

// Password/credentials updates
Task UpdatePasswordHashAsync(int id, string passwordHash);
Task UpdateEmailAsync(int id, string email);

// Merge/conflict resolution
Task<User?> FindDuplicateAsync(string uuid, string username);
Task MergeUsersAsync(int primaryUserId, int secondaryUserId);

// Link code operations
Task<LinkCode?> GetLinkCodeByCodeAsync(string code);
Task<LinkCode> CreateLinkCodeAsync(int? userId);
Task UpdateLinkCodeStatusAsync(int linkCodeId, LinkCodeStatus status);
Task<IEnumerable<LinkCode>> GetExpiredLinkCodesAsync(); // For cleanup
```

#### LinkCodeRepository (New)

```csharp
public interface ILinkCodeRepository
{
    Task<LinkCode> CreateAsync(LinkCode linkCode);
    Task<LinkCode?> GetByCodeAsync(string code);
    Task<LinkCode?> GetByIdAsync(int id);
    Task UpdateAsync(LinkCode linkCode);
    Task DeleteAsync(int id);
    Task<IEnumerable<LinkCode>> GetExpiredAsync(); // For scheduled cleanup
}
```

### B.4 Service Requirements

#### IUserService Interface Extensions

Add the following methods:

```csharp
// Account validation
Task<(bool IsValid, string? ErrorMessage)> ValidateUserCreationAsync(UserCreateDto dto);
Task<(bool IsValid, string? ErrorMessage)> ValidatePasswordAsync(string password);

// Unique constraint validation with meaningful errors
Task<(bool IsTaken, int? ConflictingUserId)> CheckUsernameTakenAsync(string username, int? excludeUserId = null);
Task<(bool IsTaken, int? ConflictingUserId)> CheckEmailTakenAsync(string email, int? excludeUserId = null);
Task<(bool IsTaken, int? ConflictingUserId)> CheckUuidTakenAsync(string uuid, int? excludeUserId = null);

// Password management
Task ChangePasswordAsync(int userId, string currentPassword, string newPassword, string passwordConfirmation);
Task<bool> VerifyPasswordAsync(string plainPassword, string? passwordHash);

// Link code management
Task<LinkCodeResponseDto> GenerateLinkCodeAsync(int? userId);
Task<(bool IsValid, UserDto? User)> ConsumeLinkCodeAsync(string code);
Task<IEnumerable<LinkCode>> GetExpiredLinkCodesAsync();
Task CleanupExpiredLinksAsync();

// Account linking & merging
Task<(bool HasConflict, int? SecondaryUserId)> CheckForDuplicateAsync(string uuid, string username);
Task<UserDto> MergeAccountsAsync(int primaryUserId, int secondaryUserId);
Task<UserDto> LinkExistingAccountAsync(int userId, UserUpdateDto updateDto);
```

#### LinkCodeService (New)

Handle all link code business logic:
- Generate codes (ensure uniqueness, randomness)
- Validate expiration
- Track usage
- Cleanup expired codes

### B.5 AutoMapper Profile Updates

#### UserMappingProfile Extensions

**Current gaps to address**:
- `PasswordHash`: Should NEVER be mapped to/from DTOs (security)
- `ExperiencePoints`: Currently missing from UserDto (add it)
- `Gems`: Currently missing from UserDto (add it)
- `EmailVerified`: New property, map appropriately
- `AccountCreatedVia`: New property, map to/from DTO
- `IsActive`: Consider including in list/detail views

**New Mappings**:
```csharp
// User → UserDto (include Gems, ExperiencePoints, EmailVerified, exclude PasswordHash)
CreateMap<User, UserDto>()
    .ForMember(d => d.PasswordHash, opt => opt.Ignore())
    .ForMember(d => d.Gems, opt => opt.MapFrom(s => s.Gems))
    .ForMember(d => d.ExperiencePoints, opt => opt.MapFrom(s => s.ExperiencePoints))
    .ForMember(d => d.EmailVerified, opt => opt.MapFrom(s => s.EmailVerified));

// LinkCode → LinkCodeResponseDto
CreateMap<LinkCode, LinkCodeResponseDto>();

// User → AccountMergeResultDto (show merged user with stats)
CreateMap<User, AccountMergeResultDto>()
    .ForMember(d => d.PasswordHash, opt => opt.Ignore());
```

**Security Note**: Ensure `PasswordHash` is never exposed in any DTO mapping.

### B.6 API Controller Requirements

#### UsersController Extensions

**New/Updated Endpoints**:

```csharp
// POST /api/users/generate-link-code
[HttpPost("generate-link-code")]
Task<IActionResult> GenerateLinkCode([FromBody] LinkCodeRequestDto request);
// Response: 200 OK { code, expiresAt }
// Errors: 400 Bad Request, 404 Not Found (user)

// POST /api/users/validate-link-code/{code}
[HttpPost("validate-link-code/{code}")]
Task<IActionResult> ValidateLinkCode(string code);
// Response: 200 OK { userId, username, email }
// Errors: 400 Bad Request (invalid/expired), 404 Not Found

// PUT /api/users/{id}/change-password
[HttpPut("{id:int}/change-password")]
Task<IActionResult> ChangePassword(int id, [FromBody] ChangePasswordDto dto);
// Response: 204 No Content
// Errors: 400 Bad Request, 401 Unauthorized, 404 Not Found

// PUT /api/users/{id}/update-email
[HttpPut("{id:int}/update-email")]
Task<IActionResult> UpdateEmail(int id, [FromBody] UpdateEmailDto dto);
// Response: 204 No Content
// Errors: 400 Bad Request (duplicate), 404 Not Found

// POST /api/users/check-duplicate
[HttpPost("check-duplicate")]
Task<IActionResult> CheckForDuplicate([FromBody] DuplicateCheckDto dto);
// Response: 200 OK { hasDuplicate, conflictingUser }
// Used by Minecraft plugin to detect merge scenarios

// POST /api/users/merge
[HttpPost("merge")]
Task<IActionResult> MergeAccounts([FromBody] AccountMergeDto dto);
// Response: 200 OK { mergedUser }
// Errors: 400 Bad Request, 404 Not Found

// POST /api/users/link-account
[HttpPost("link-account")]
Task<IActionResult> LinkExistingAccount([FromBody] LinkAccountDto dto);
// For Minecraft-only account adding email/password via link code
// Response: 200 OK { user }
// Errors: 400 Bad Request, 404 Not Found
```

**Updated GET /api/users/{id:int}**:
- Ensure response includes `Gems`, `ExperiencePoints`, `EmailVerified`
- Never include `PasswordHash` or `PasswordConfirmation` in response

**Updated POST /api/users** (Create):
- Validate unique constraints before creation
- Hash password if provided
- Handle link code if provided
- Return meaningful conflict errors (duplicate username, email, etc.)

### B.7 Validation & Error Handling

**Input Validation**:
- Username: Non-empty, max 256 chars, valid Minecraft username format (alphanumeric + underscores)
- Email: Valid format, unique if provided
- Password: **8-128 characters, no forced complexity, reject weak/blacklisted passwords**
  - Minimum: 8 characters
  - Maximum: 128 characters
  - No requirement for uppercase, numbers, or symbols
  - Reject if in blacklist of top 1000 compromised passwords
  - Reject common patterns: 123456, qwerty, password, admin, etc.
- UUID: Valid UUID format (36 chars with hyphens)
- Link Code: 8 alphanumeric characters, within 20-minute window

**Error Responses** (use consistent format):
```csharp
// Duplicate constraint violation
{
  "error": "ValidationFailed",
  "message": "Username 'PlayerOne' is already in use.",
  "field": "username",
  "code": "DuplicateUsername"
}

// Password mismatch
{
  "error": "ValidationFailed",
  "message": "Password confirmation does not match.",
  "field": "passwordConfirmation",
  "code": "PasswordMismatch"
}

// Link code expired
{
  "error": "LinkCodeExpired",
  "message": "Link code expired. Please request a new one.",
  "code": "LinkCodeExpired"
}
```

---

## Part C: Web App (knk-web-app) Requirements

### C.1 New Pages/Flows

#### Account Creation / Registration Flow
- Multi-step form:
  1. Username field (with real-time uniqueness check)
  2. Email field (with format validation)
  3. Password & confirmation fields
  4. Optional: Link code input field (for Minecraft-initiated accounts)
- Displays generated link code after success
- Progress indicator (step 1 of 3, etc.)

#### Account Settings / Management Page
- Edit email
- Change password (with current password verification)
- View account creation method (Web App vs Minecraft Server)
- View creation date
- Display UUID if linked from Minecraft

#### Account Linking Page
- If user created account first on web app:
  - Display generated link code
  - Instructions for using `/account link {code}` on Minecraft server
  - Expiration countdown (20 minutes)
  - Option to regenerate code
  
#### Account Merge/Conflict Resolution UI
- Display both conflicting accounts side-by-side
- Show stats for each (Coins, Gems, Experience)
- Clear radio buttons or buttons to select primary account
- Confirmation dialog before merge
- Success message with stats of merged account

### C.2 API Client Updates

**New API Client Methods** (in appropriate service file):
```typescript
// User service extensions
generateLinkCode(userId: number): Promise<{ code: string; expiresAt: Date }>
validateLinkCode(code: string): Promise<User>
changePassword(userId: number, current: string, newPassword: string, confirm: string): Promise<void>
updateEmail(userId: number, newEmail: string): Promise<void>
checkForDuplicate(uuid: string, username: string): Promise<{ hasDuplicate: boolean; conflictingUser?: User }>
mergeAccounts(primaryId: number, secondaryId: number): Promise<User>
linkExistingAccount(linkCode: string, email: string, password: string): Promise<User>
```

### C.3 Form Validation

**Client-side validation**:
- Email format
- Password strength (length + complexity if required)
- Password confirmation match
- Username non-empty, valid format

**Server-side validation** (via API):
- All of above
- Unique constraints (username, email, uuid)
- Link code validity and expiration

### C.4 UX Considerations

- **Clear Labels**: Differentiate between Minecraft username and email
- **Help Text**: Explain what link codes are and why they're needed
- **Error Messages**: Specific, actionable feedback
- **Loading States**: Show during API calls
- **Success Feedback**: Confirm changes saved
- **Link Code Countdown**: Visual indicator of expiration (changing color as it approaches 5 minutes)

---

## Part D: Minecraft Plugin (knk-plugin-v2) Requirements

### D.1 Commands

#### /account create
**Purpose**: Minecraft-only player adds email and password to their account

**Interactive Flow**:
1. `System`: "Please provide your email address. Type it in chat (it won't be visible to others)."
2. `Player` types email
3. `System`: Validates email (format, uniqueness)
   - If invalid: "Email format is invalid. Please try again." → Repeat step 1
   - If taken: "This email is already in use. Please use a different one." → Repeat step 1
4. `System`: "Please provide a password (at least 8 characters). Type it in chat."
5. `Player` types password
6. `System`: "Please confirm your password by typing it again."
7. `Player` types password again
   - If mismatch: "Passwords do not match. Please try again." → Repeat step 4
8. `System`: Makes API call to update user with email/password hash
   - Success: "Account updated successfully! You can now log in on the web app."
   - Failure: "Failed to update account. Please try again later or contact support."
9. `System`: Removes player from "in-chat-capture mode"

**Chat Capture**: During this flow, `OnPlayerChatEvent` must:
- Capture all chat from this player
- Prevent chat from reaching server chat
- Display appropriate prompt messages in player's chat

#### /account link
**Purpose**: Player requests link code (to complete account on web app) OR links existing account

**Scenario A**: Minecraft-only player wants to add email/password via web app
1. `Player`: `/account link`
2. `System`: Generates link code via API
3. `System`: "Your account link code is: ABC123. Use this code in the web app to add email and password. This code expires in 20 minutes."
4. Code is logged for easy copying (optionally formatted for visibility)

**Scenario B**: Player created web app account first, UUID/username matches
1. `Player`: `/account link {code}`
2. `System`: Validates code via API
3. If valid:
   - `System`: "Linking your Minecraft account with your web app account..."
   - API call to consume link code and update UUID
   - Success: "Your accounts have been linked! You can now use the web app."
4. If invalid/expired:
   - `System`: "This code is invalid or has expired. Use `/account link` to get a new one."

**Scenario C**: Conflict detected (2 accounts for same UUID/username)
1. After validation detects conflict:
2. `System`: "You have two accounts linked to this player. Please choose which one to keep by typing 'A' or 'B' in chat."
3. Display both accounts:
   - Account A: Created via [WebApp/Server], Coins: X, Gems: Y, Experience: Z
   - Account B: Created via [WebApp/Server], Coins: X, Gems: Y, Experience: Z
4. Player in chat-capture mode; can only type 'A' or 'B'
   - Invalid input: "Please type 'A' or 'B'."
5. After selection:
   - `System`: "You chose Account A. Account B has been deleted."
   - Data from Account A retained

#### /account [no args]
**Purpose**: View current account status

**Output**:
```
=== Your Account ===
Username: PlayerOne
UUID: {uuid}
Email: player@example.com | [Not linked]
Coins: 250 | Gems: 50 | Experience: 1200
Account created via: [Web App / Minecraft Server]
Last updated: 2026-01-07
```

### D.2 Server-Side Account Management

#### On Player Join
1. Capture `Player.getUniqueId()` (UUID)
2. Capture `Player.getName()` (username)
3. Call API: `GET /api/users/uuid/{uuid}` or check by UUID + username
4. If user exists:
   - Retrieve user data
   - Update last-seen timestamp (optional)
5. If not found:
   - Create minimal user via API: `POST /api/users` with UUID, username only
   - No email or password yet
   - This user can play but cannot access web app

#### Chat Event Interception
- Monitor all `AsyncPlayerChatEvent` (or sync version)
- Check if player is in "input-capture mode"
  - If yes: Cancel event, capture input, process according to command flow
  - If no: Allow chat to proceed normally

#### Link Code Validation on Server
- When player uses `/account link {code}`:
  - Validate format (basic check: non-empty, reasonable length)
  - Call API to validate: `POST /api/users/validate-link-code/{code}`
  - If API returns success, apply merge logic

### D.3 Data Flow to API

**Player Join**:
```
1. Plugin: Player UUID = abc-123-def, Username = PlayerOne
2. Plugin: GET /api/users/check-duplicate?uuid=abc-123-def&username=PlayerOne
3. API: Checks if user with this UUID/username exists
   - If exists: Return existing user data
   - If not exists: Create new user, return it
4. Plugin: Store user data in memory (PlayerManager or similar)
```

**Account Create (/account create)**:
```
1. Plugin: Captures email and password from player chat
2. Plugin: PUT /api/users/{userId}/update-email {email}
3. API: Validates email, checks uniqueness, updates
4. Plugin: PUT /api/users/{userId}/change-password {newPassword}
5. API: Hashes password, updates
6. Plugin: Shows success message
```

**Link Code Generation (/account link)**:
```
1. Plugin: POST /api/users/generate-link-code {userId}
2. API: Returns {code, expiresAt}
3. Plugin: Displays code to player with expiration time
```

**Link Code Consumption (/account link {code})**:
```
1. Plugin: POST /api/users/validate-link-code/{code}
2. API: Checks if code is valid and not expired
3. API: Returns associated user data (if any) and validation status
4. Plugin: If valid, call POST /api/users/merge or update UUID
5. Plugin: Show success/failure message
```

### D.4 UX Messaging

All messages should:
- Be clear and non-technical
- Provide next steps
- Include error details if applicable
- Use consistent formatting (e.g., === Section ===)

---

## Part E: Implementation Checklist for API Components

### E.1 User Model & Entity

**Tasks**:
- [ ] Add properties: `PasswordHash`, `EmailVerified`, `AccountCreatedVia`, `LastModifiedAt`, `IsActive`
- [ ] Create `AccountCreationMethod` enum
- [ ] Add data annotations for unique constraints (Username, Email, Uuid)
- [ ] Update FormConfigurableEntity metadata if needed

**Files**:
- `Models/User.cs`

### E.2 LinkCode Entity & Migration

**Tasks**:
- [ ] Create `LinkCode.cs` model with properties and navigation
- [ ] Create `LinkCodeStatus` enum
- [ ] Generate EF Core migration: `dotnet ef migrations add AddLinkCodeEntity`
- [ ] Apply migration: `dotnet ef database update`

**Files**:
- `Models/LinkCode.cs`
- `Migrations/[timestamp]_AddLinkCodeEntity.cs`

### E.3 DTOs

**Tasks**:
- [ ] Update `UserCreateDto`: Add UUID, LinkCode, make Email/Password optional
- [ ] Create `UserUpdateDto` with Email, NewPassword, CurrentPassword fields
- [ ] Create `ChangePasswordDto` for password-only changes
- [ ] Create `LinkCodeRequestDto`, `LinkCodeResponseDto`
- [ ] Create `AccountMergeDto`, `DuplicateCheckDto`
- [ ] Create `LinkAccountDto` for linking existing account via link code

**Files**:
- `Dtos/UserDtos.cs` (extend existing)
- `Dtos/LinkCodeDtos.cs` (new)
- `Dtos/AccountManagementDtos.cs` (new)

### E.4 Repository Layer

#### IUserRepository Extensions

**Tasks**:
- [ ] Add `IsUsernameTakenAsync(string username, int? excludeUserId)`
- [ ] Add `IsEmailTakenAsync(string email, int? excludeUserId)`
- [ ] Add `IsUuidTakenAsync(string uuid, int? excludeUserId)`
- [ ] Add `GetByEmailAsync(string email)`
- [ ] Add `GetByUuidAndUsernameAsync(string uuid, string username)`
- [ ] Add `UpdatePasswordHashAsync(int id, string passwordHash)`
- [ ] Add `UpdateEmailAsync(int id, string email)`
- [ ] Add `FindDuplicateAsync(string uuid, string username)`
- [ ] Add `MergeUsersAsync(int primaryUserId, int secondaryUserId)` (cascade delete secondary)
- [ ] Add `CreateLinkCodeAsync(LinkCode linkCode)` and retrieval methods
- [ ] Add `UpdateLinkCodeStatusAsync(int linkCodeId, LinkCodeStatus status)`
- [ ] Add `GetExpiredLinkCodesAsync()`

**Files**:
- `Repositories/Interfaces/IUserRepository.cs`

#### UserRepository Implementation

**Tasks**:
- [ ] Implement all IUserRepository extensions
- [ ] Add SQL queries for uniqueness checks (case-insensitive for username)
- [ ] Implement cascade logic for merge (handle foreign keys appropriately; TBD on other entities)
- [ ] Implement LinkCode CRUD operations (or separate LinkCodeRepository)

**Files**:
- `Repositories/UserRepository.cs`

#### ILinkCodeRepository (Optional, can be in UserRepository)

**Tasks**:
- [ ] Create interface if separate repository needed
- [ ] Implement CRUD + expiration queries

**Files**:
- `Repositories/Interfaces/ILinkCodeRepository.cs`
- `Repositories/LinkCodeRepository.cs` (if separate)

### E.5 Service Layer

#### IUserService Extensions

**Tasks**:
- [ ] Add `ValidateUserCreationAsync(UserCreateDto)` → returns (bool isValid, string? error)
- [ ] Add `ValidatePasswordAsync(string password)` → checks length + complexity
- [ ] Add `CheckUsernameTakenAsync` with conflict details
- [ ] Add `CheckEmailTakenAsync` with conflict details
- [ ] Add `CheckUuidTakenAsync` with conflict details
- [ ] Add `ChangePasswordAsync(int, currentPassword, newPassword, confirm)`
- [ ] Add `VerifyPasswordAsync(string plain, string? hash)` → bcrypt comparison
- [ ] Add `GenerateLinkCodeAsync(int? userId)` → creates 20-min code
- [ ] Add `ConsumeLinkCodeAsync(string code)` → validates, marks used, returns user
- [ ] Add `GetExpiredLinkCodesAsync()`
- [ ] Add `CleanupExpiredLinksAsync()` (scheduled/manual)
- [ ] Add `CheckForDuplicateAsync(string uuid, string username)`
- [ ] Add `MergeAccountsAsync(int primary, int secondary)` → orchestrates merge
- [ ] Add `LinkExistingAccountAsync(int userId, UserUpdateDto)` (for link code flow)

**Files**:
- `Services/Interfaces/IUserService.cs`

#### UserService Implementation

**Tasks**:
- [ ] Implement all new methods
- [ ] Use bcrypt (install NuGet: `BCrypt.Net-Next`) for password hashing
- [ ] Generate random alphanumeric link codes (secure random, 6 chars recommended)
- [ ] Add detailed validation messages (see Part B.7)
- [ ] Implement merge logic with transaction support
- [ ] Add logging for key operations (merge, password change, etc.)

**Files**:
- `Services/UserService.cs`

#### ILinkCodeService (Optional)

**Tasks**:
- [ ] If separate service, handle LinkCode lifecycle
- [ ] Generation, validation, expiration, cleanup

**Files**:
- `Services/Interfaces/ILinkCodeService.cs`
- `Services/LinkCodeService.cs` (if separate)

### E.6 AutoMapper Profiles

#### UserMappingProfile Updates

**Tasks**:
- [ ] Update `User → UserDto`: Add Gems, ExperiencePoints, EmailVerified; exclude PasswordHash
- [ ] Update `UserDto → User`: Ensure PasswordHash not set from DTO
- [ ] Add mapping for `LinkCode → LinkCodeResponseDto`
- [ ] Add mapping for new DTOs (UpdateDto, ChangePasswordDto, etc.)
- [ ] Add mapping for merge/conflict scenarios
- [ ] Ensure no PasswordHash exposure in any direction

**Files**:
- `Mapping/UserMappingProfile.cs`

### E.7 Controllers

#### UsersController Updates

**Tasks**:
- [ ] Update `Create` endpoint: Validate link code if provided, hash password, return link code in response
- [ ] Update `GetByIdAsync`: Ensure response includes Gems, ExperiencePoints
- [ ] Add `POST /api/users/generate-link-code` endpoint
- [ ] Add `POST /api/users/validate-link-code/{code}` endpoint
- [ ] Add `PUT /api/users/{id}/change-password` endpoint
- [ ] Add `PUT /api/users/{id}/update-email` endpoint
- [ ] Add `POST /api/users/check-duplicate` endpoint
- [ ] Add `POST /api/users/merge` endpoint
- [ ] Add `POST /api/users/link-account` endpoint
- [ ] Add appropriate error handling + detailed messages

**Files**:
- `Controllers/UsersController.cs`

### E.8 Database & Migrations

**Tasks**:
- [ ] Add unique constraints: Username, Email, Uuid (with null handling for Uuid)
- [ ] Create LinkCode table with foreign key to User
- [ ] Add new columns to User table (PasswordHash, EmailVerified, AccountCreatedVia, LastModifiedAt, IsActive)
- [ ] Ensure indexes on frequently queried fields (Email, Uuid, Username)
- [ ] Test rollback/migration on development environment

**Files**:
- `Migrations/[timestamp]_*.cs` (multiple)

### E.9 Configuration & Dependency Injection

**Tasks**:
- [ ] Register UserRepository, UserService in DI (already done, verify)
- [ ] Register LinkCodeRepository/Service if separate (TBD)
- [ ] Register password hashing service or utility
- [ ] Configure bcrypt rounds (recommend 10-12)

**Files**:
- `Program.cs` or `DependencyInjection/ServiceCollectionExtensions.cs`

### E.10 Testing

**Tasks**:
- [ ] Unit tests for UserService validation methods
- [ ] Unit tests for password hashing/verification
- [ ] Unit tests for link code generation and expiration
- [ ] Integration tests for merge scenarios
- [ ] Integration tests for unique constraint enforcement
- [ ] E2E tests for account creation flows

**Files**:
- `Tests/Services/UserServiceTests.cs` (new/extended)
- `Tests/Integration/AccountManagementTests.cs` (new)

---

## Part F: Design Decisions (CONFIRMED) ✅

### Confirmed Specifications

1. **Foreign Key References** ✅ **DECIDED: None Currently**
   - No other entities reference User as of January 2026
   - Simplifies merge logic: no cascade concerns
   - Future-proof: when relationships added, merge logic can be extended

2. **Link Code Length & Format** ✅ **DECIDED: 8 Characters**
   - Format: 8 alphanumeric characters (e.g., "ABC12XYZ")
   - Display: Formatted with hyphen for readability ("ABC-12XYZ")
   - Entropy: ~218 trillion combinations (62^8)
   - Rationale: Significant security gain with minimal UX cost; future-proof if validity extends

3. **Password Complexity Requirements** ✅ **DECIDED: OWASP Standard (8-128 chars, no complexity)**
   - Minimum length: **8 characters**
   - Maximum length: **128 characters**
   - **No forced complexity** (no uppercase, numbers, symbols required)
   - **Blacklist weak passwords**: Reject top 1000 compromised + common patterns (123456, password, qwerty, etc.)
   - Rationale: OWASP 2023 recommends length over complexity; better UX, stronger accounts in practice

4. **Account Merge Behavior** ✅ **DECIDED: Winner's Values Only**
   - Keep only winning account's values (Coins, Gems, Experience, Email, Password)
   - No consolidation/summing of currencies
   - User chooses which account to keep, fully informed by stats display
   - Rationale: Prevents abuse; user has complete choice and visibility

5. **Soft Delete vs. Hard Delete** ✅ **DECIDED: Soft Delete with 90-Day TTL**
   - Use soft delete: Set `IsActive = false`, `DeletedAt = UtcNow`
   - Time-to-Live: 90 days before hard delete eligibility
   - Reason tracking: Store `DeletedReason` for audit trail
   - Rationale: Recovery if needed; audit trail; no permanent data loss risk

6. **Audit Logging** ✅ **DECIDED: Minimal Trail (MVP)**
   - No separate AuditLog entity needed for MVP
   - Track in User model only:
     - `LastPasswordChangeAt: DateTime?` (when password last changed)
     - `LastEmailChangeAt: DateTime?` (when email last changed)
     - `DeletedAt: DateTime?` (from soft delete)
     - `DeletedReason: string?` (from soft delete)
   - Rationale: Provides accountability without complexity; sufficient for MVP, extensible later

### Future Enhancement Decisions (Out of MVP Scope)

- **Password Reset**: Email-based password reset (future)
- **Email Verification**: Optional email verification flow (future)
- **Session Invalidation**: Invalidate sessions on password change (future, auth system dependent)
- **Account Deactivation**: User-initiated account deactivation (future)
- **Audit Log Entity**: Separate audit table for full compliance (future if GDPR needed)
- **Link Code Cleanup Job**: Scheduled background job for expired code deletion (future)

---

## Part G: Related Entities & Data Relationships

**Status**: No breaking changes required
- Currently, **no other entities reference User as of January 2026**
- Merge logic is straightforward: just update User record
- When relationships are added in future (Towns, Plots, etc.):
  - Soft-deleted accounts can have FK constraint changes (reassign, cascade, or keep as-is)
  - Audit trail from soft delete provides recovery capability

---

## Appendix: Example API Flows

### Scenario 1: Web App First Account Creation
```
1. POST /api/users
   Request: { username: "PlayerOne", email: "p@example.com", password: "secure123", passwordConfirmation: "secure123" }
   Response: 201 Created { id: 1, username: "PlayerOne", email: "p@example.com", uuid: null, linkCode: { code: "ABC123", expiresAt: "2026-01-07T21:45:00Z" } }

2. User joins Minecraft server later
   Server: GET /api/users/check-duplicate?uuid=abc-123-def&username=PlayerOne
   API: Detects match on username, returns user (uuid now null vs abc-123-def)
   API Response: { id: 1, uuid: null, username: "PlayerOne", ... hasDuplicate: true }

3. Server prompts: "Use /account link ABC123 to link your accounts"

4. Player: /account link ABC123
   Server: POST /api/users/validate-link-code/ABC123
   API: Confirms valid, returns user
   Server: PUT /api/users/1 { uuid: "abc-123-def" }
   API: Links UUID to user
   API Response: 204 No Content
   Server: "Accounts linked! Welcome back."
```

### Scenario 2: Minecraft First, Then Web App
```
1. Player joins Minecraft server
   Server: GET /api/users/check-duplicate?uuid=abc-123-def&username=PlayerOne
   API: No match found
   Server: POST /api/users { uuid: "abc-123-def", username: "PlayerOne" }
   API Response: 201 { id: 2, uuid: "abc-123-def", username: "PlayerOne", email: null, ... }

2. Player later uses /account link
   Server: POST /api/users/generate-link-code { userId: 2 }
   API Response: { code: "XYZ789", expiresAt: "2026-01-07T21:45:00Z" }
   Server: "Your link code is XYZ789"

3. Player goes to web app, registers with email/password, enters code
   Web: POST /api/users { username: "PlayerOne", email: "p@example.com", password: "secure123", linkCode: "XYZ789" }
   API: Finds existing user by link code, updates email/password
   API Response: 201 { id: 2, ... }

4. Account now fully set up
```

### Scenario 3: Account Merge Conflict
```
1. Duplicate detected:
   Server: GET /api/users/check-duplicate?uuid=abc-123-def&username=PlayerOne
   API Response: { hasDuplicate: true, conflictingUser: { id: 1 }, primaryUser: { id: 2 } }

2. Server prompts player in chat-capture mode:
   "You have 2 accounts. Choose A or B:
    A) Created 2026-01-05 via Web App - Coins: 500, Gems: 100, XP: 5000
    B) Created 2026-01-06 via Server - Coins: 0, Gems: 0, XP: 0"

3. Player: A
   Server: POST /api/users/merge { primaryUserId: 1, secondaryUserId: 2 }
   API: Deletes user 2, confirms user 1 is linked to uuid abc-123-def
   API Response: 200 { user: { id: 1, uuid: "abc-123-def", ... } }

4. Server: "Account merged. Keeping web app account with 500 coins, 100 gems."
```

---

## Appendix: Code Structure Example

### Sample Service Method Implementation

```csharp
public async Task<(bool IsValid, string? ErrorMessage)> ValidateUserCreationAsync(UserCreateDto dto)
{
    // Check username
    if (string.IsNullOrWhiteSpace(dto.Username))
        return (false, "Username is required.");
    
    if (dto.Username.Length < 3 || dto.Username.Length > 256)
        return (false, "Username must be between 3 and 256 characters.");
    
    var usernameTaken = await _repo.IsUsernameTakenAsync(dto.Username);
    if (usernameTaken)
        return (false, $"Username '{dto.Username}' is already in use.");
    
    // Check email if provided
    if (!string.IsNullOrWhiteSpace(dto.Email))
    {
        var emailTaken = await _repo.IsEmailTakenAsync(dto.Email);
        if (emailTaken)
            return (false, $"Email '{dto.Email}' is already in use.");
    }
    
    // Check password if provided
    if (!string.IsNullOrWhiteSpace(dto.Password))
    {
        var (isValid, error) = ValidatePassword(dto.Password);
        if (!isValid)
            return (false, error);
        
        if (dto.Password != dto.PasswordConfirmation)
            return (false, "Password confirmation does not match.");
    }
    
    return (true, null);
}

private (bool IsValid, string? Error) ValidatePassword(string password)
{
    if (password.Length < 8)
        return (false, "Password must be at least 8 characters long.");
    
    // Add more rules as needed (uppercase, numbers, symbols, etc.)
    
    return (true, null);
}
```

---

**Document Version**: 1.0  
**Last Review**: Not yet reviewed  
**Next Review**: After stakeholder feedback
