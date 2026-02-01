# Account Management Architecture Update - v2.0 (January 31, 2026)

## Summary

The Knights & Kings account management system has been refactored to follow a **web app first** approach for account creation. This document outlines the architectural changes from v1.0 to v2.0.

---

## Key Changes

### ❌ Removed Features

1. **`/account create` Command**
   - Players can no longer create accounts with email/password in Minecraft
   - All account creation now happens on the web app only

2. **In-Game Email/Password Input**
   - ChatCaptureManager no longer handles email/password flows
   - Removed `startAccountCreateFlow()` method
   - Removed `handleAccountCreateInput()` method
   - Removed `CaptureFlow.ACCOUNT_CREATE` enum value

3. **UserAccountApi Methods**
   - `updateEmail(Integer userId, String newEmail)` - removed
   - `changePassword(Integer userId, Object request)` - removed

4. **Test Files Updates**
   - Removed `AccountCreateCommand.java` class
   - Removed all `/account create` related tests
   - Removed `AccountCreateFlowTests` from integration tests
   - Updated `ChatCaptureManagerTest` to use merge flows instead

### ✅ Retained Features

1. **`/account` Command**
   - View account status (username, UUID, email status, coins, gems, XP)
   - No changes to command behavior

2. **`/account link [code]` Command**
   - Use link codes from web app to link accounts
   - Same functionality, enhanced documentation

3. **Web App Account Management**
   - Email and password management on web app
   - Link code generation on web app
   - Email verification (optional)

4. **Account Merging**
   - Duplicate detection when linking
   - Merge flow with account comparison
   - "Winner takes all" strategy for resources

5. **API Client Methods**
   - `validateLinkCode(String code)` - validate and consume link code
   - `generateLinkCode(Integer userId)` - generate new link code
   - `linkAccount(Object request)` - link accounts
   - `mergeAccounts(Object request)` - merge duplicate accounts
   - `checkDuplicate(String uuid, String username)` - detect duplicates

---

## Architectural Changes

### Before (v1.0)

```
Player in Minecraft
    │
    ├─→ /account create
    │   ├─→ Chat capture: email
    │   ├─→ Chat capture: password
    │   ├─→ API call: updateEmail()
    │   ├─→ API call: changePassword()
    │   └─→ Account created ✓
    │
    └─→ /account link [code]
        ├─→ API call: validateLinkCode()
        └─→ Accounts linked ✓
```

### After (v2.0)

```
Player on Web App                  Player in Minecraft
    │                                  │
    ├─→ Create Account                 │
    │   (email + password)              │
    │                                  │
    ├─→ Generate Link Code             │
    │   (20 minute expiry)              │
    │                                  ├─→ Join Server
    │                                  │   └─→ Minimal account auto-created
    │                                  │
    │   Copy Code ──────────────────→ /account link [code]
    │                                  │
    │                                  ├─→ API: validateLinkCode()
    │                                  ├─→ Check for duplicate
    │                                  ├─→ If duplicate: merge flow
    │                                  └─→ Accounts linked ✓
```

---

## API Changes

### UserAccountApi Interface

#### Removed Methods
```java
// v1.0 - Email management
updateEmail(Integer userId, String newEmail)

// v1.0 - Password management
changePassword(Integer userId, Object request)

// v1.0 - Account creation
createUser(Object request)
```

#### Retained Methods
```java
// v2.0 - Link code validation
validateLinkCode(String code)

// v2.0 - Link code generation
generateLinkCode(Integer userId)

// v2.0 - Account linking
linkAccount(Object request)

// v2.0 - Account merging
mergeAccounts(Object request)

// v2.0 - Duplicate detection
checkDuplicate(String uuid, String username)
```

---

## Implementation Files Changed

### Plugin Changes

**Files Deleted**:
- `knk-paper/src/main/java/.../commands/AccountCreateCommand.java`

**Files Modified**:

1. **AccountCommandRegistry.java**
   - Removed registration of "create" subcommand
   - Kept only "status" and "link" subcommands

2. **AccountCommand.java**
   - Removed `/account create` suggestion
   - Now only suggests `/account link`

3. **ChatCaptureManager.java**
   - Removed `startAccountCreateFlow()` method
   - Removed `handleAccountCreateInput()` method
   - Kept only `startMergeFlow()` for duplicate resolution

4. **CaptureFlow.java**
   - Removed `ACCOUNT_CREATE` enum value
   - Kept only `ACCOUNT_MERGE`

5. **UserAccountListener.java**
   - Updated welcome messages
   - Removed `/account create` from help text

6. **PlayerUserData.java**
   - Documentation updated
   - No structural changes

### API Client Changes

**Files Modified**:

1. **UserAccountApiImpl.java**
   - Removed `createUser()` with email/password
   - Removed `updateEmail()` method
   - Removed `changePassword()` method
   - Fixed HTTP 204 response handling

2. **BaseApiImpl.java**
   - Fixed 204 No Content response handling
   - Now recognizes 204 as valid success (no body required)

### Test Files

**Files Deleted**:
- `knk-paper/src/test/.../AccountCreateFlowTests` nested class

**Files Modified**:

1. **AccountCommandIntegrationTest.java**
   - Removed `accountCreateCommand` field
   - Removed entire `AccountCreateFlowTests` nested class
   - Kept `AccountLinkFlowTests`

2. **ChatCaptureManagerTest.java**
   - Removed `AccountCreateFlowTests` nested class
   - Replaced all `startAccountCreateFlow()` calls with `startMergeFlow()` in other tests
   - Kept `AccountMergeFlowTests`

---

## Configuration Changes

### config.yml

**Removed Settings**:
```yaml
# No longer needed
account:
  chat_capture:
    email_step_prompt: "..."
    password_step_prompt: "..."
```

**Retained Settings**:
```yaml
account:
  link_code_expiry_minutes: 20
  chat_capture_timeout_seconds: 120
  cooldowns:
    account_link_seconds: 10
```

---

## Database (No Changes)

**User Schema**: Unchanged
- Still has `uuid`, `username`, `email`, `passwordHash`, etc.
- No migration needed

**Link Codes**: Unchanged
- Still stored with `userId`, `code`, `expiryTime`, `isConsumed`
- No migration needed

**Account Merge Records**: Unchanged
- Soft deletion tracking remains same

---

## Documentation Updates

### New Files Created

1. **PLAYER_GUIDE_ACCOUNT_MANAGEMENT_v2.md**
   - Updated quick start for new flow
   - Removed `/account create` references
   - Clear instructions for web app → Minecraft flow

2. **DEVELOPER_GUIDE_ACCOUNT_INTEGRATION_v2.md**
   - Updated architecture diagrams
   - New account management flows
   - API changes documented
   - Migration guide for developers

### Files to Deprecate

- `PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md` (v1.0)
- `DEVELOPER_GUIDE_ACCOUNT_INTEGRATION.md` (v1.0)

---

## Migration Path for Users

### Existing Linked Accounts
✅ **No action needed** - Continue working normally

### New Players
1. Create account on web app (email + password)
2. Generate link code on web app
3. Join Minecraft server
4. Use `/account link [code]`

### Minecraft-Only Players (No Email)
1. Create account on web app
2. Generate link code
3. Use `/account link [code]` to link
4. Merge if duplicates detected

---

## Rationale for Changes

### Why Remove In-Game Account Creation?

1. **Better UX**: Web forms are better for email validation than chat input
2. **Security**: Email/password not broadcast through Minecraft chat
3. **Consistency**: Single source of truth (web app) for account creation
4. **Validation**: Email verification and password rules in one place
5. **Simplicity**: Plugin code is simpler (less complexity = fewer bugs)
6. **Mobile**: Players can create account on phone while playing

### Why Keep `/account link`?

1. **Necessary**: Must link Minecraft UUID to web account
2. **Convenient**: No need to alt-tab or switch device
3. **Quick**: One command to link, no typing email/password
4. **Safe**: Link code is temporary and single-use

---

## Testing Checklist

- [x] Build compiles without errors
- [x] No test failures
- [x] `/account` command shows status
- [x] `/account link` works with valid code
- [x] Invalid codes rejected
- [x] Expired codes rejected
- [x] Duplicate detection triggers
- [x] Merge flow works correctly
- [x] Chat capture still works for merge flow
- [x] Account data cached properly
- [x] API error handling graceful

---

## Known Issues

None at this time.

---

## Future Enhancements

1. **Email Verification**: Optional email verification flow on web app
2. **Password Recovery**: Forgot password flow via email
3. **Link Code History**: View previously generated codes
4. **Account Activity**: Show linked devices and locations
5. **2FA**: Optional two-factor authentication

---

## Support & Questions

For questions about this update:
- **Developers**: See DEVELOPER_GUIDE_ACCOUNT_INTEGRATION_v2.md
- **Players**: See PLAYER_GUIDE_ACCOUNT_MANAGEMENT_v2.md
- **Issues**: Report with detailed error logs

---

**Update completed: January 31, 2026**
