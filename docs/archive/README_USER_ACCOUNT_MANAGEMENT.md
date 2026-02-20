# Knights & Kings Web API v2 - User Account Management

**Status**: ✅ Phase 6 Complete (Documentation & Cleanup)  
**Last Updated**: January 17, 2026  

This README documents the User Account Management system and new endpoints added in Phases 1-6.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture](#architecture)
3. [API Endpoints](#api-endpoints)
4. [Authentication Endpoints](#authentication-endpoints)
5. [Account Management Endpoints](#account-management-endpoints)
6. [Configuration](#configuration)
7. [Developer Guides](#developer-guides)
8. [Testing](#testing)
9. [Common Workflows](#common-workflows)
10. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Prerequisites

- .NET 8.0 or higher
- PostgreSQL or SQL Server (depends on configuration)
- BCrypt.Net-Next NuGet package (already included)

### Build & Run

```bash
# Build
dotnet build

# Run with watch (auto-reload on changes)
dotnet watch run --project knkwebapi_v2.csproj

# Run with Swagger UI
./run-with-swagger.sh

# Access API
# Swagger UI: http://localhost:5000/swagger
# Health Check: http://localhost:5000/health
```

### Run Tests

```bash
# Run all tests
dotnet test

# Run specific test file
dotnet test Tests/Services/UserServiceTests.cs

# Run with coverage
dotnet test /p:CollectCoverage=true
```

---

## Architecture

### Layer Overview

```
┌─────────────────────────────────────────────────────────┐
│ HTTP Requests                                           │
├─────────────────────────────────────────────────────────┤
│ Controllers (UsersController.cs)                        │
│  - Request validation & routing                         │
│  - Call service methods                                 │
│  - Return standardized responses                        │
├─────────────────────────────────────────────────────────┤
│ Services (UserService, PasswordService, LinkCodeService)│
│  - Business logic                                       │
│  - Validation & security                                │
│  - Orchestration of operations                          │
├─────────────────────────────────────────────────────────┤
│ Repositories (UserRepository)                           │
│  - Data access layer                                    │
│  - EF Core queries                                      │
│  - Foreign key management                               │
├─────────────────────────────────────────────────────────┤
│ Database (User, LinkCode tables)                        │
│  - Persistent storage                                   │
│  - Indexes & constraints                                │
└─────────────────────────────────────────────────────────┘
```

### Key Services

| Service | Purpose |
|---------|---------|
| `PasswordService` | Password hashing, verification, validation (bcrypt) |
| `LinkCodeService` | Link code generation, validation, consumption (20-min expiration) |
| `UserService` | User CRUD, validation, account merging, balance management |
| `UserRepository` | Data access, foreign key updates, soft delete |

---

## API Endpoints

### Get User Information

#### `GET /api/users`
Returns all active users (excludes soft-deleted).

**Response:**
```json
[
  {
    "id": 1,
    "username": "knight_player",
    "email": "knight@example.com",
    "uuid": "a1b2c3d4-e5f6-4a8b-9c0d-1e2f3a4b5c6d",
    "coins": 100,
    "gems": 50,
    "experiencePoints": 1500,
    "emailVerified": false,
    "accountCreatedVia": 0,
    "createdAt": "2026-01-10T15:30:00Z"
  }
]
```

#### `GET /api/users/{id}`
Get user by ID with full details.

**Response:**
```json
{
  "id": 1,
  "username": "knight_player",
  "email": "knight@example.com",
  "uuid": "a1b2c3d4-e5f6-4a8b-9c0d-1e2f3a4b5c6d",
  "coins": 100,
  "gems": 50,
  "experiencePoints": 1500,
  "emailVerified": false,
  "accountCreatedVia": 0,
  "createdAt": "2026-01-10T15:30:00Z"
}
```

#### `GET /api/users/uuid/{uuid}`
Get user summary by Minecraft UUID (used by Minecraft plugin).

**Response:**
```json
{
  "id": 1,
  "username": "knight_player",
  "uuid": "a1b2c3d4-e5f6-4a8b-9c0d-1e2f3a4b5c6d",
  "coins": 100,
  "gems": 50,
  "experiencePoints": 1500
}
```

#### `GET /api/users/username/{username}`
Get user summary by username.

**Response:**
```json
{
  "id": 1,
  "username": "knight_player",
  "coins": 100,
  "gems": 50,
  "experiencePoints": 1500
}
```

---

## Create User

### `POST /api/users`
Create new user account.

**Request:**
```json
{
  "username": "new_player",
  "email": "player@example.com",
  "password": "SecurePassword123",
  "passwordConfirmation": "SecurePassword123",
  "uuid": null
}
```

**Supported Flows:**

1. **Web App First** (email + password):
```json
{
  "username": "web_player",
  "email": "web@example.com",
  "password": "MySecurePass123",
  "passwordConfirmation": "MySecurePass123"
}
```

2. **Minecraft First** (UUID + username):
```json
{
  "username": "mc_player",
  "uuid": "a1b2c3d4-e5f6-4a8b-9c0d-1e2f3a4b5c6d"
}
```

**Response (201 Created):**
```json
{
  "id": 2,
  "username": "new_player",
  "email": "player@example.com",
  "coins": 0,
  "gems": 0,
  "experiencePoints": 0,
  "emailVerified": false,
  "accountCreatedVia": 0,
  "createdAt": "2026-01-17T10:00:00Z"
}
```

**Error Responses:**
- `400 Bad Request`: Validation failed (weak password, username too short, etc.)
- `409 Conflict`: Duplicate username, email, or UUID

---

## Authentication Endpoints

### `POST /api/users/generate-link-code`
Generate a link code for account linking.

**Request:**
```json
{
  "userId": 1
}
```

**Response (200 OK):**
```json
{
  "code": "ABC12XYZ",
  "expiresAt": "2026-01-17T10:20:00Z"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid user ID
- `404 Not Found`: User not found

---

### `POST /api/users/validate-link-code/{code}`
Validate and consume a link code.

**URL Parameters:**
- `code`: 8-character link code (e.g., `ABC12XYZ`)

**Response (200 OK):**
```json
{
  "isValid": true,
  "userId": 1,
  "username": "knight_player",
  "email": "knight@example.com"
}
```

**When Invalid:**
```json
{
  "isValid": false,
  "error": "Invalid or expired link code"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid code format

---

### `PUT /api/users/{id}/change-password`
Change user password.

**Request:**
```json
{
  "currentPassword": "OldPassword123",
  "newPassword": "NewPassword456",
  "passwordConfirmation": "NewPassword456"
}
```

**Response (204 No Content)**

**Error Responses:**
- `400 Bad Request`: New password too weak or doesn't match confirmation
- `401 Unauthorized`: Current password incorrect
- `404 Not Found`: User not found

---

### `PUT /api/users/{id}/update-email`
Update user email address.

**Request:**
```json
{
  "newEmail": "newemail@example.com",
  "currentPassword": "CurrentPassword123"
}
```

**Response (204 No Content)**

**Error Responses:**
- `400 Bad Request`: Invalid email format
- `401 Unauthorized`: Current password incorrect
- `404 Not Found`: User not found
- `409 Conflict`: Email already in use

---

## Account Management Endpoints

### `POST /api/users/check-duplicate`
Check for duplicate accounts (used by Minecraft server).

**Request:**
```json
{
  "uuid": "a1b2c3d4-e5f6-4a8b-9c0d-1e2f3a4b5c6d",
  "username": "player_name"
}
```

**Response (200 OK) - No Duplicate:**
```json
{
  "hasDuplicate": false,
  "message": "No duplicate accounts found"
}
```

**Response (200 OK) - Duplicate Detected:**
```json
{
  "hasDuplicate": true,
  "primaryUser": {
    "id": 1,
    "username": "player_name",
    "uuid": "a1b2c3d4-e5f6-4a8b-9c0d-1e2f3a4b5c6d",
    "coins": 100,
    "gems": 50,
    "experiencePoints": 1500
  },
  "conflictingUser": {
    "id": 2,
    "username": "player_name",
    "coins": 0,
    "gems": 0,
    "experiencePoints": 0
  },
  "message": "Duplicate accounts detected. Please merge them."
}
```

---

### `POST /api/users/merge`
Merge two user accounts.

**Request:**
```json
{
  "primaryUserId": 1,
  "secondaryUserId": 2
}
```

**Response (200 OK):**
```json
{
  "user": {
    "id": 1,
    "username": "knight_player",
    "email": "knight@example.com",
    "uuid": "a1b2c3d4-e5f6-4a8b-9c0d-1e2f3a4b5c6d",
    "coins": 100,
    "gems": 50,
    "experiencePoints": 1500
  },
  "mergedFromUserId": 2,
  "message": "Successfully merged account 2 into 1"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid IDs or operation failed
- `404 Not Found`: One or both users not found

**Merge Behavior:**
- ✅ Primary account keeps all its data (winner takes all)
- ✅ Secondary account is soft-deleted (marked deleted, not removed)
- ✅ Foreign keys (e.g., Towns) are updated to point to primary
- ✅ 90-day archive period before permanent deletion

---

### `POST /api/users/link-account`
Link Minecraft account with email/password.

**Request:**
```json
{
  "linkCode": "ABC12XYZ",
  "email": "player@example.com",
  "password": "NewPassword123",
  "passwordConfirmation": "NewPassword123"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "username": "knight_player",
  "email": "player@example.com",
  "uuid": "a1b2c3d4-e5f6-4a8b-9c0d-1e2f3a4b5c6d",
  "coins": 0,
  "gems": 0,
  "experiencePoints": 0,
  "emailVerified": false
}
```

**Error Responses:**
- `400 Bad Request`: Invalid link code, weak password, password mismatch
- `409 Conflict`: Email already in use

---

## Configuration

### appsettings.json

```json
{
  "Security": {
    "BcryptRounds": 10
  }
}
```

### Environment Variables

```bash
# Database connection
CONNECTION_STRING=Server=localhost;Database=knk_db;User Id=sa;Password=...

# API settings
ASPNETCORE_ENVIRONMENT=Development
ASPNETCORE_URLS=http://localhost:5000
```

---

## Developer Guides

Read the comprehensive developer guides for detailed information:

### 📖 [Developer Guide: Validation Rules](DEVELOPER_GUIDE_VALIDATION.md)
How to add new validation rules to user creation, password validation, and email validation.

**Topics:**
- Validation architecture
- Adding password rules
- Adding user creation rules
- Adding email validators
- Custom field validators
- Testing validators
- Best practices

### 🔐 [Developer Guide: Password Hashing](DEVELOPER_GUIDE_PASSWORD_HASHING.md)
How the bcrypt password hashing system works and security considerations.

**Topics:**
- Why bcrypt
- Implementation details
- Configuration (work factor/rounds)
- Security considerations
- Password policy (OWASP guidelines)
- Migration & upgrades
- Common operations
- Troubleshooting

### 🔗 [Developer Guide: Account Merge & Foreign Keys](DEVELOPER_GUIDE_ACCOUNT_MERGE.md)
How account merging works and how to handle foreign key relationships.

**Topics:**
- When to merge accounts
- Merge strategy (winner takes all)
- Implementation details
- Foreign key relationships
- Merge process step-by-step
- Soft delete implementation
- Testing merge operations
- Rollback & recovery

---

## Testing

### Test Structure

```
Tests/
  Services/
    UserServiceTests.cs (25+ tests)
    LinkCodeServiceTests.cs (28+ tests)
    PasswordServiceTests.cs
  Integration/
    AccountManagementIntegrationTests.cs (18+ tests)
    UniqueConstraintIntegrationTests.cs (20+ tests)
  Api/
    UsersControllerTests.cs (25+ tests)
```

### Run Tests

```bash
# All tests
dotnet test

# Specific test file
dotnet test Tests/Services/UserServiceTests.cs

# Specific test
dotnet test --filter UserServiceTests.ValidateUserCreationAsync_WithDuplicateUsername_ShouldFail

# With coverage
dotnet test /p:CollectCoverage=true
```

### Test Statistics

- **Total Test Cases**: 128+
- **Services Covered**: ✅ UserService, LinkCodeService, PasswordService
- **Integration Scenarios**: ✅ Web app first, Minecraft first, merge flows
- **Unique Constraints**: ✅ Username, email, UUID
- **Security**: ✅ Password hashing, verification

---

## Common Workflows

### Workflow 1: Web App User Registration

```bash
# 1. Create user with email + password
POST /api/users
{
  "username": "new_player",
  "email": "player@example.com",
  "password": "SecurePass123",
  "passwordConfirmation": "SecurePass123"
}
→ 201 Created (User created with ID=1)

# 2. User can now log in (when auth endpoints are implemented)
# 3. User can link Minecraft later with generated link code
```

### Workflow 2: Minecraft Server User

```bash
# 1. Player joins Minecraft server
# Minecraft plugin creates user:
POST /api/users
{
  "username": "mc_player",
  "uuid": "a1b2c3d4-e5f6-4a8b-9c0d-1e2f3a4b5c6d"
}
→ 201 Created (User created with ID=1)

# 2. Later, player wants web access
# Player requests link code in game/web
POST /api/users/generate-link-code
{
  "userId": 1
}
→ 200 OK { "code": "ABC12XYZ", "expiresAt": "..." }

# 3. Player enters code on website
POST /api/users/validate-link-code/ABC12XYZ
→ 200 OK { "isValid": true, "userId": 1, ... }

# 4. Player sets email/password
POST /api/users/link-account
{
  "linkCode": "ABC12XYZ",
  "email": "player@example.com",
  "password": "Password123",
  "passwordConfirmation": "Password123"
}
→ 200 OK (Account linked)
```

### Workflow 3: Account Duplication & Merge

```bash
# Player created account on website: User ID=1 (email-based)
# Player joins server with different account: User ID=2 (UUID-based)

# 1. Minecraft plugin detects duplicate
POST /api/users/check-duplicate
{
  "uuid": "...",
  "username": "player_name"
}
→ 200 OK { "hasDuplicate": true, "primaryUser": {...}, "conflictingUser": {...} }

# 2. Admin/system initiates merge
POST /api/users/merge
{
  "primaryUserId": 1,
  "secondaryUserId": 2
}
→ 200 OK (User 2 soft-deleted, all references updated)

# 3. User ID=2 is now soft-deleted
# All towns, plots, etc. now owned by User ID=1
# User ID=2 deleted permanently after 90 days (if not restored)
```

### Workflow 4: Password Change

```bash
# 1. User requests password change
PUT /api/users/1/change-password
{
  "currentPassword": "OldPassword123",
  "newPassword": "NewPassword456",
  "passwordConfirmation": "NewPassword456"
}
→ 204 No Content (Password updated)

# 2. Old password no longer works (bcrypt verified)
# 3. New password is hashed and stored
```

---

## Error Responses

### Standard Error Format

All errors follow this format:

```json
{
  "error": "ErrorCode",
  "message": "Human-readable error message"
}
```

### Common Error Codes

| Code | HTTP Status | Meaning | Example |
|------|-------------|---------|---------|
| `ValidationFailed` | 400 | Input validation error | Username too short |
| `DuplicateUsername` | 409 | Username already taken | "Username is already taken" |
| `DuplicateEmail` | 409 | Email already registered | "Email is already in use" |
| `InvalidPassword` | 400 | Password doesn't meet policy | "Password too weak" |
| `UserNotFound` | 404 | User doesn't exist | User ID not found |
| `InvalidLinkCode` | 400 | Link code invalid/expired | Code expired or used |
| `InvalidArgument` | 400 | Invalid request parameters | Merge with self |
| `OperationFailed` | 400 | Operation couldn't complete | Database error |

---

## Security Best Practices

### Password Storage
- ✅ Passwords hashed with bcrypt (10 rounds)
- ✅ Unique salt per password
- ✅ Never logged or exposed in responses
- ❌ Never stored in plain text

### API Security
- ✅ Use HTTPS for all requests
- ✅ Validate all inputs server-side
- ✅ Rate limit sensitive endpoints
- ✅ Sanitize error messages (don't reveal if email exists)

### Database
- ✅ Foreign key constraints
- ✅ Soft delete (data preserved)
- ✅ Unique indexes (username, email, UUID)
- ✅ Nullable fields where appropriate

---

## Troubleshooting

### Issue: "BcryptRounds must be between 4 and 31"
Check appsettings.json - BcryptRounds must be integer between 4-31 (default: 10).

### Issue: "Duplicate username" error when creating user
Username already exists. Use different username or check database.

### Issue: "Invalid or expired link code"
Link code expired (20-minute window) or already used. Generate new code.

### Issue: "Merge failed"
Check that both user IDs exist and are different. Review logs for FK update errors.

### Issue: Password verification always fails
Ensure password was hashed with bcrypt before storing. Check hash format starts with `$2a$`.

---

## Phase Status

| Phase | Component | Status |
|-------|-----------|--------|
| 1 | Data Model & Repositories | ✅ COMPLETE |
| 2 | DTOs & Mapping | ✅ COMPLETE |
| 3 | Service Layer | ✅ COMPLETE |
| 4 | API Controllers | ✅ COMPLETE |
| 5 | Testing (128+ tests) | ✅ COMPLETE |
| 6 | Documentation & Cleanup | ✅ COMPLETE |

---

## Next Steps

Future enhancements under consideration:

- [ ] Email verification flow
- [ ] Password reset / "Forgot Password"
- [ ] Session invalidation on password change
- [ ] Comprehensive audit logging
- [ ] Background job for link code cleanup (Hangfire)
- [ ] Account deactivation (soft disable)
- [ ] Rate limiting on password attempts
- [ ] 2FA / MFA support
- [ ] OAuth2 integration

---

## Related Documentation

- [User Account Management Spec](../../../docs/specs/users/SPEC_USER_ACCOUNT_MANAGEMENT.md)
- [Implementation Roadmap](../../../docs/specs/users/USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md)
- [Phase 5 Testing Summary](README_PHASE_5_TESTING.md)
- [Validation Improvements](VALIDATION_IMPROVEMENTS.md)

---

## Support

For issues or questions:

1. Check this README and developer guides
2. Search existing GitHub issues
3. Review test cases for examples
4. Contact Knights & Kings Development Team

---

**Last Updated**: January 17, 2026  
**Version**: v2 (Phase 6)  
**Maintained By**: Knights & Kings Backend Team
