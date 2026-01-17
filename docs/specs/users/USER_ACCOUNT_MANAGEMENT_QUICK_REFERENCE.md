# User Account Management - Quick Reference Guide

**Last Updated:** January 7, 2026  
**Status:** Ready for Implementation ✅

---

## Design Decisions Summary

| Decision Area | Confirmed Choice |
|---------------|------------------|
| **Password Policy** | • Min: 8 chars, Max: 128 chars<br>• No forced complexity (no uppercase/numbers/symbols required)<br>• Blacklist: Top 1000 compromised + common patterns<br>• Hash: bcrypt with 10-12 rounds |
| **Link Code** | • Length: **8 alphanumeric characters**<br>• Format: ABC12XYZ<br>• Display: ABC-12XYZ (hyphenated)<br>• Validity: 20 minutes<br>• Entropy: ~218 trillion combinations |
| **Account Merge** | • User chooses winning account<br>• Keep winner's values only (no consolidation)<br>• Display both accounts with Coins/Gems/XP before choice |
| **Delete Strategy** | • **Soft delete** (IsActive = false)<br>• TTL: 90 days before hard delete<br>• Track: DeletedAt, DeletedReason, ArchiveUntil |
| **Audit Trail** | • **Minimal** (no separate audit table for MVP)<br>• Track in User model:<br>&nbsp;&nbsp;- LastPasswordChangeAt<br>&nbsp;&nbsp;- LastEmailChangeAt<br>&nbsp;&nbsp;- DeletedAt<br>&nbsp;&nbsp;- DeletedReason |
| **Foreign Keys** | • Currently: **None**<br>• Merge is straightforward<br>• Future: soft delete allows recovery if FK added |
| **Balances (Coins/Gems/XP)** | • No negative balances; reject underflows<br>• Mutations are atomic/serialized via service methods only<br>• Each change requires reason/type and is logged (Coins full audit; Gems/XP lighter but recoverable) |

---

## User Model Extensions

### New Properties to Add

```csharp
// Authentication & Security
public string? PasswordHash { get; set; }  // bcrypt hashed, 10-12 rounds
public bool EmailVerified { get; set; } = false;

// Metadata
public AccountCreationMethod AccountCreatedVia { get; set; }  // WebApp or MinecraftServer

// Audit Trail
public DateTime? LastPasswordChangeAt { get; set; }
public DateTime? LastEmailChangeAt { get; set; }

// Soft Delete
public bool IsActive { get; set; } = true;
public DateTime? DeletedAt { get; set; }
public string? DeletedReason { get; set; }
public DateTime? ArchiveUntil { get; set; }  // DeletedAt + 90 days
```

// Balances (Coins, Gems, ExperiencePoints) stay in the model
// Mutation rules: service methods only, atomic/serialized; reject underflows
// Logging: Coins require audit log; Gems/XP logged with lighter metadata but still recoverable

### Enums

```csharp
public enum AccountCreationMethod
{
    WebApp = 0,
    MinecraftServer = 1
}
```

---

## LinkCode Entity (New)

```csharp
public class LinkCode
{
    public int Id { get; set; }
    public int? UserId { get; set; }          // FK; nullable for web app first
    public string Code { get; set; }          // 8 alphanumeric (ABC12XYZ)
    public DateTime CreatedAt { get; set; }
    public DateTime ExpiresAt { get; set; }   // CreatedAt + 20 minutes
    public LinkCodeStatus Status { get; set; }
    public DateTime? UsedAt { get; set; }
    
    public User? User { get; set; }
}

public enum LinkCodeStatus
{
    Active = 0,
    Used = 1,
    Expired = 2
}
```

---

## Password Validation Rules

### Implementation Checklist

```csharp
public (bool IsValid, string? Error) ValidatePassword(string password)
{
    if (password.Length < 8)
        return (false, "Password must be at least 8 characters long.");
    
    if (password.Length > 128)
        return (false, "Password must not exceed 128 characters.");
    
    if (IsWeakPassword(password))  // Check against blacklist
        return (false, "This password is too common. Please choose a stronger one.");
    
    return (true, null);
}
```

### Weak Password Blacklist (Top Offenders)

```
123456, password, 12345678, qwerty, 123456789, 12345, 1234, 111111, 
1234567, dragon, 123123, baseball, abc123, football, monkey, letmein,
shadow, master, 666666, qwertyuiop, 123321, mustang, 1234567890,
michael, 654321, superman, 1qaz2wsx, 7777777, 121212, 000000, qazwsx,
admin, admin123, root, toor, pass, test, guest, info, adm, mysql,
user, administrator, oracle, ftp, pi, puppet, ansible, ec2-user, vagrant
```

**Recommendation**: Embed top 1000 list; see [SecLists](https://github.com/danielmiessler/SecLists/tree/master/Passwords) or [OWASP](https://owasp.org/www-community/password-special-characters).

---

## Link Code Generation

### Implementation

```csharp
public string GenerateLinkCode()
{
    const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    var random = new byte[8];
    
    using (var rng = RandomNumberGenerator.Create())
    {
        rng.GetBytes(random);
    }
    
    var code = new char[8];
    for (int i = 0; i < 8; i++)
    {
        code[i] = chars[random[i] % chars.Length];
    }
    
    return new string(code);  // e.g., "ABC12XYZ"
}

public string FormatLinkCodeForDisplay(string code)
{
    // ABC12XYZ → ABC-12XYZ
    if (code.Length == 8)
        return $"{code.Substring(0, 3)}-{code.Substring(3)}";
    
    return code;
}
```

---

## Account Flows Summary

### Flow 1: Web App First → Minecraft

```
1. User creates account on web app (email, password, minecraft username)
   POST /api/users { username, email, password } → Returns LinkCode
2. User joins Minecraft server later
   Server: GET /api/users/check-duplicate?uuid={uuid}&username={username}
3. If duplicate detected, prompt: "Use /account link {code}"
4. Player: /account link ABC12XYZ
   Server: POST /api/users/validate-link-code/ABC12XYZ → Links UUID
```

### Flow 2: Minecraft First → No Web App

```
1. Player joins server (no account yet)
   Server: POST /api/users { uuid, username } → Creates minimal account
2. Player plays without web app access (no email/password)
```

### Flow 3: Minecraft First → Add Web App Later

```
1. Player has Minecraft-only account
2. Player: /account link
   Server: POST /api/users/generate-link-code { userId } → Returns code
3. Player goes to web app, enters link code in registration
   Web: POST /api/users { email, password, linkCode } → Updates account
```

### Flow 4: Account Merge (Conflict)

```
1. Duplicate detected (2 accounts for same UUID/username)
2. System presents both accounts:
   A) Web App account: Coins 500, Gems 100, XP 5000
   B) Server account: Coins 0, Gems 0, XP 0
3. Player chooses A or B in chat
4. Winning account kept; losing account soft-deleted
   API: POST /api/users/merge { primaryUserId, secondaryUserId }
```

---

## Key API Endpoints to Implement

### Authentication & Linking

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/users/generate-link-code` | POST | Generate link code for user |
| `/api/users/validate-link-code/{code}` | POST | Validate link code & get user info |
| `/api/users/check-duplicate` | POST | Detect account conflicts |
| `/api/users/merge` | POST | Merge conflicting accounts |
| `/api/users/{id}/change-password` | PUT | Change user password |
| `/api/users/{id}/update-email` | PUT | Update user email |
| `/api/users/link-account` | POST | Link existing account via code |

### Request/Response Examples

**Generate Link Code**:
```json
Request:  POST /api/users/generate-link-code
Body:     { "userId": 1 }
Response: { "code": "ABC12XYZ", "expiresAt": "2026-01-07T15:30:00Z" }
```

**Validate Link Code**:
```json
Request:  POST /api/users/validate-link-code/ABC12XYZ
Response: { "isValid": true, "userId": 1, "username": "PlayerOne", "email": "player@example.com" }
```

**Check Duplicate**:
```json
Request:  POST /api/users/check-duplicate
Body:     { "uuid": "abc-123-def", "username": "PlayerOne" }
Response: { "hasDuplicate": true, "primaryUser": {...}, "conflictingUser": {...} }
```

---

## Minecraft Commands

### /account create
**Purpose**: Minecraft-only player adds email & password  
**Flow**: Interactive step-by-step (email → password → confirm)  
**Chat Capture**: Prevents messages from reaching server chat

### /account link
**Purpose**: Generate link code OR link with existing code  
**Syntax**:
- `/account link` → Generate code for web app usage
- `/account link {code}` → Link with web app account

### /account
**Purpose**: View account status  
**Output**:
```
=== Your Account ===
Username: PlayerOne
UUID: abc-123-def-456
Email: player@example.com | [Not linked]
Coins: 250 | Gems: 50 | Experience: 1200
Account created via: [Web App / Minecraft Server]
```

---

## Migration Checklist

### Database Changes

```sql
-- User table additions
ALTER TABLE Users ADD PasswordHash VARCHAR(255) NULL;
ALTER TABLE Users ADD EmailVerified BIT DEFAULT 0;
ALTER TABLE Users ADD AccountCreatedVia INT DEFAULT 1;
ALTER TABLE Users ADD LastPasswordChangeAt DATETIME NULL;
ALTER TABLE Users ADD LastEmailChangeAt DATETIME NULL;
ALTER TABLE Users ADD IsActive BIT DEFAULT 1;
ALTER TABLE Users ADD DeletedAt DATETIME NULL;
ALTER TABLE Users ADD DeletedReason VARCHAR(500) NULL;
ALTER TABLE Users ADD ArchiveUntil DATETIME NULL;

-- LinkCode table creation
CREATE TABLE LinkCodes (
    Id INT PRIMARY KEY IDENTITY,
    UserId INT NULL,
    Code VARCHAR(8) UNIQUE NOT NULL,
    CreatedAt DATETIME NOT NULL,
    ExpiresAt DATETIME NOT NULL,
    Status INT NOT NULL DEFAULT 0,
    UsedAt DATETIME NULL,
    FOREIGN KEY (UserId) REFERENCES Users(Id)
);

-- Indexes
CREATE UNIQUE INDEX IX_LinkCodes_Code ON LinkCodes(Code);
CREATE INDEX IX_LinkCodes_UserId ON LinkCodes(UserId);
CREATE INDEX IX_LinkCodes_ExpiresAt ON LinkCodes(ExpiresAt);
CREATE INDEX IX_Users_DeletedAt ON Users(DeletedAt);
```

---

## Configuration

### appsettings.json

```json
{
  "Security": {
    "BcryptRounds": 10,
    "LinkCodeExpirationMinutes": 20,
    "SoftDeleteRetentionDays": 90
  },
  "PasswordPolicy": {
    "MinLength": 8,
    "MaxLength": 128,
    "RequireComplexity": false,
    "UseWeakPasswordBlacklist": true
  }
}
```

---

## Testing Priorities

### High Priority Tests

1. **Password Validation**
   - [ ] 8 chars minimum enforced
   - [ ] 128 chars maximum enforced
   - [ ] Weak passwords rejected (123456, password, etc.)
   - [ ] Valid passwords accepted (no complexity required)

2. **Link Code Generation**
   - [ ] Generates 8 alphanumeric chars
   - [ ] Unique across database
   - [ ] Expires after 20 minutes
   - [ ] Cannot be reused after consumption

3. **Account Merge**
   - [ ] Detects duplicate UUID + username
   - [ ] Soft-deletes losing account
   - [ ] Winner retains all values
   - [ ] Sets ArchiveUntil = DeletedAt + 90 days

4. **Unique Constraints**
   - [ ] Username unique (case-insensitive)
   - [ ] Email unique (when non-null)
   - [ ] UUID unique (when non-null)

---

## NuGet Packages Required

```bash
dotnet add package BCrypt.Net-Next
```

---

## Estimated Effort

| Phase | Hours |
|-------|-------|
| Data Model & Migrations | 4h |
| DTOs & Mapping | 3h |
| Service Layer (incl. password/link code utils) | 6.5h |
| API Controllers | 6.5h |
| Testing | 12-14h |
| Documentation | 2h |
| **Total** | **34-37h** |

---

## Next Steps

1. ✅ Review this quick reference
2. ✅ Confirm all design decisions (done)
3. [ ] Set up test database
4. [ ] Install BCrypt.Net-Next
5. [ ] Download weak password list
6. [ ] Create feature branch
7. [ ] Start Phase 1: Update User model

---

**For Full Details**: See `SPEC_USER_ACCOUNT_MANAGEMENT.md`  
**For Implementation Steps**: See `USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md`
