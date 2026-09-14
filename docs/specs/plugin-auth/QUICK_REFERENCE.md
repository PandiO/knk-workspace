# Quick Reference: API Endpoints & DTO Mapping

**Purpose**: Quick lookup table for API endpoints and their corresponding DTOs  
**For**: Developers implementing Phase 1-4

---

## API Endpoints Reference

### User Creation

| Endpoint | Method | Request | Response | Phase |
|----------|--------|---------|----------|-------|
| `/api/Users` | `POST` | `CreateUserRequest` | `UserResponse` | 1 |

**CreateUserRequest Fields**:
- `username` (String, required)
- `uuid` (String, optional - auto-generated if null)
- `email` (String, optional)
- `password` (String, optional)
- `linkCode` (String, optional - for link flow)

**UserResponse Fields**:
- `id` (int)
- `username` (String)
- `uuid` (String)
- `email` (String)
- `coins` (int)
- `gems` (int)
- `experiencePoints` (int)
- `emailVerified` (boolean)
- `accountCreatedVia` (String - e.g., "plugin", "web")

---

### Duplicate Detection

| Endpoint | Method | Request | Response | Phase |
|----------|--------|---------|----------|-------|
| `/api/Users/check-duplicate` | `POST` | Query params | `DuplicateCheckResponse` | 1 |

**Query Parameters**:
- `uuid` (String)
- `username` (String)

**DuplicateCheckResponse Fields**:
- `hasDuplicate` (boolean)
- `conflictingUser` (UserResponse, nullable)
- `primaryUser` (UserResponse, nullable)
- `message` (String, nullable)

**Usage Example**:
```java
DuplicateCheckResponse check = userAccountApi
    .checkDuplicate("550e8400-e29b-41d4-a716-446655440000", "PlayerName")
    .get();
```

---

### Link Code Generation

| Endpoint | Method | Request | Response | Phase |
|----------|--------|---------|----------|-------|
| `/api/Users/generate-link-code` | `POST` | `LinkCodeRequest` | `LinkCodeResponse` | 2 |

**LinkCodeRequest Fields**:
- `userId` (int)

**LinkCodeResponse Fields**:
- `code` (String - e.g., "ABC-123")
- `expiresAt` (String - ISO 8601 timestamp)
- `formattedCode` (String - display format)

**Example Response**:
```json
{
  "code": "ABC-123",
  "expiresAt": "2026-01-29T12:25:00Z",
  "formattedCode": "ABC-123"
}
```

---

### Link Code Validation

| Endpoint | Method | Request | Response | Phase |
|----------|--------|---------|----------|-------|
| `/api/Users/validate-link-code/{code}` | `POST` | Path param | `ValidateLinkCodeResponse` | 2 |

**Path Parameters**:
- `{code}` (String - the code to validate)

**ValidateLinkCodeResponse Fields**:
- `isValid` (boolean)
- `userId` (int, nullable)
- `username` (String, nullable)
- `email` (String, nullable)
- `error` (String, nullable)

**Usage Example**:
```java
ValidateLinkCodeResponse validation = userAccountApi
    .validateLinkCode("ABC-123")
    .get();

if (validation.isValid()) {
    // Proceed to link
} else {
    // Show error: validation.error()
}
```

---

### Link Account

| Endpoint | Method | Request | Response | Phase |
|----------|--------|---------|----------|-------|
| `/api/Users/link-account` | `POST` | `LinkAccountRequest` | `UserResponse` | 2 |

**LinkAccountRequest Fields**:
- `linkCode` (String)
- `email` (String)
- `password` (String)
- `passwordConfirmation` (String)

**Response**: Merged `UserResponse` with:
- UUID now set to Minecraft player UUID
- Data includes combined coins/XP/gems from both accounts

---

### Update Email

| Endpoint | Method | Request | Response | Phase |
|----------|--------|---------|----------|-------|
| `/api/Users/{id}/update-email` | `PUT` | JSON body | `Boolean` | 4 |

**Path Parameters**:
- `{id}` (int - user ID)

**Request Body**:
```json
{
  "email": "newemail@example.com"
}
```

**Response**: `true` if successful, exception if failed

---

### Change Password

| Endpoint | Method | Request | Response | Phase |
|----------|--------|---------|----------|-------|
| `/api/Users/{id}/change-password` | `PUT` | `ChangePasswordRequest` | `Boolean` | 4 |

**Path Parameters**:
- `{id}` (int - user ID)

**ChangePasswordRequest Fields**:
- `currentPassword` (String)
- `newPassword` (String)
- `passwordConfirmation` (String)

**Usage Example**:
```java
ChangePasswordRequest req = new ChangePasswordRequest(
    "OldPass123",
    "NewPass456",
    "NewPass456"
);
userAccountApi.changePassword(123, req).get();
```

---

### Merge Accounts

| Endpoint | Method | Request | Response | Phase |
|----------|--------|---------|----------|-------|
| `/api/Users/merge` | `POST` | `MergeAccountsRequest` | `UserResponse` | 3 |

**MergeAccountsRequest Fields**:
- `primaryUserId` (int - account to keep)
- `secondaryUserId` (int - account to delete)

**Response**: Merged `UserResponse` with:
- ID of primary account
- Combined coins/gems/XP
- Secondary account deleted
- UUID updated if needed

**Important Notes**:
- Primary account is kept
- Secondary account is deleted
- All data from both accounts is merged
- Backend decides merge rules (XP stacking, etc.)

---

## DTO Quick Reference

### Request DTOs (What Plugin Sends)

| DTO | Fields | Phase | Example |
|-----|--------|-------|---------|
| `CreateUserRequest` | username, uuid, email, password, linkCode | 1 | `CreateUserRequest.minimalUser(uuid, name)` |
| `LinkCodeRequest` | userId | 2 | `new LinkCodeRequest(123)` |
| `LinkAccountRequest` | linkCode, email, password, passwordConfirmation | 2 | Manual construction |
| `ChangePasswordRequest` | currentPassword, newPassword, passwordConfirmation | 4 | Manual construction |
| `MergeAccountsRequest` | primaryUserId, secondaryUserId | 3 | Manual construction |

### Response DTOs (What Plugin Receives)

| DTO | When Used | Key Fields |
|-----|-----------|------------|
| `UserResponse` | After create/link/merge | id, username, uuid, email, coins, gems |
| `LinkCodeResponse` | After code generation | code, expiresAt, formattedCode |
| `ValidateLinkCodeResponse` | After code validation | isValid, userId, username, error |
| `DuplicateCheckResponse` | After duplicate check | hasDuplicate, conflictingUser, primaryUser |

---

## Error Handling by Endpoint

### Common Error Codes

| HTTP Code | Meaning | Plugin Action |
|-----------|---------|---------------|
| 200 | Success | Process response |
| 400 | Bad request (invalid input) | Show user message, don't retry |
| 401 | Unauthorized | Check auth headers, log warning |
| 404 | Not found (code/user doesn't exist) | Show "Not found" error |
| 409 | Conflict (email in use, duplicate) | Show helpful message |
| 500 | Server error | Retry with exponential backoff |
| 503 | Service unavailable | Retry with exponential backoff |
| Timeout | Network timeout | Retry with exponential backoff |

### Retry Strategy (BaseApiImpl)

```
Max retries: 3
Backoff: Exponential (100ms initial, 2.0 multiplier, 5s max)
Retryable: 5xx, timeouts
Non-retryable: 4xx (bad request)
```

---

## Plugin Implementation Flowchart

### Player Creates Account (`/account create`)

```
START
  │
  ├─ Check: Player already has account?
  │  └─ YES: Show "You already have account"
  │  └─ NO: Continue
  │
  ├─ Check: Player captured in chat already?
  │  └─ YES: Show "Already creating account"
  │  └─ NO: Continue
  │
  ├─ START CHAT CAPTURE
  │  │
  │  ├─ Prompt: "Enter email:"
  │  ├─ Wait for chat input → Validate email
  │  │
  │  ├─ Prompt: "Enter password:"
  │  ├─ Wait for chat input → Validate strength
  │  │
  │  ├─ Prompt: "Confirm password:"
  │  ├─ Wait for chat input → Compare
  │  │
  │  └─ CALLBACK: Send to API
  │     │
  │     ├─ POST /api/Users
  │     │  ├─ uuid = player.uuid
  │     │  ├─ username = player.name
  │     │  ├─ email = captured_email
  │     │  ├─ password = captured_password
  │     │
  │     ├─ Response: UserResponse
  │     │  └─ Update cache
  │     │
  │     └─ Message: "Account created!"
  │
  └─ END
```

### Player Links Account (`/account link {code}`)

```
START
  │
  ├─ Validate: Code format (not empty)
  │  └─ INVALID: Show "Invalid code format"
  │
  ├─ API: POST /api/Users/validate-link-code/{code}
  │  │
  │  ├─ Response: ValidateLinkCodeResponse
  │  │  ├─ isValid = true: Continue
  │  │  ├─ isValid = false: Show error
  │  │
  │  └─ If valid: Proceed
  │
  ├─ START CHAT CAPTURE (for password verification)
  │  │
  │  ├─ Prompt: "Enter password:"
  │  ├─ Wait for input
  │  │
  │  └─ CALLBACK
  │     │
  │     ├─ API: POST /api/Users/link-account
  │     │  ├─ linkCode = {code}
  │     │  ├─ password = captured_password
  │     │  ├─ email = validated_email (from validate response)
  │     │
  │     ├─ Response: UserResponse
  │     │  └─ UUID now linked
  │     │
  │     └─ Message: "Account linked!"
  │
  └─ END
```

---

## Configuration Reference

### config.yml Structure

```yaml
account:
  link-code-expiry-minutes: 20           # How long code is valid
  chat-capture-timeout-seconds: 120      # Max time for input

messages:
  prefix: "&8[&6KnK&8] &r"               # Message prefix
  account-created: "..."                 # After /account create
  account-linked: "..."                  # After /account link
  link-code-generated: "... {code} ..."  # With placeholders
  invalid-link-code: "..."               # Code expired/invalid
  duplicate-account: "..."               # Duplicate detected
  merge-complete: "... {coins} {gems} ..." # After merge
```

### Message Placeholders

| Placeholder | Value | Used In |
|------------|-------|---------|
| `{code}` | Link code (e.g., "ABC-123") | link-code-generated |
| `{minutes}` | Minutes until expiry | link-code-generated |
| `{coins}` | Total coins after merge | merge-complete |
| `{gems}` | Total gems after merge | merge-complete |
| `{exp}` | Total XP after merge | merge-complete |

**Format Example**:
```
config.messages.format(
    config.messages.linkCodeGenerated(),
    Map.of("code", "ABC-123", "minutes", "20")
)
// Result: "Your link code is: ABC-123 (expires in 20 min)"
```

---

## Quick Troubleshooting

### API Returns 409 (Conflict)

**Cause**: Email already in use

**Solution**: Show message "Email in use. Use /account link instead"

**Code**:
```java
} catch (HttpException ex) {
    if (ex.statusCode() == 409) {
        player.sendMessage("Email already in use. Use /account link");
    }
}
```

### Timeout on checkDuplicate()

**Cause**: API unresponsive, BaseApiImpl retrying

**Solution**: Allow join, don't block player

**Code**:
```java
try {
    check = userAccountApi.checkDuplicate(uuid, username).get(30, TimeUnit.SECONDS);
} catch (TimeoutException ex) {
    logger.warning("Timeout checking duplicate for " + uuid);
    // Continue (fail-open)
}
```

### Chat Capture Never Completes

**Cause**: Player didn't type in time, or password mismatch

**Solution**: Timeout task removes session, shows "Session timed out"

**Code**:
```java
// Timeout task in ChatCaptureManager
plugin.schedule(delay=config.chatCaptureTimeoutSeconds() * 20) {
    ChatCaptureSession current = activeSessions.get(playerUuid);
    if (current != null) {
        cancelSession(playerUuid);
        player.sendMessage("Session timed out");
    }
}
```

### Cache Shows Wrong Data

**Cause**: Concurrent updates, cache not thread-safe

**Solution**: Use ConcurrentHashMap, update atomically

**Code**:
```java
// CORRECT: Atomic put
userCache.put(uuid, newData);

// WRONG: Not thread-safe
userCache.get(uuid).coins = newCoins;
```

---

## Performance Tips

### Reduce API Calls

- **Cache results**: Use userCache for 5 minutes
- **Batch operations**: If possible, combine requests
- **Lazy load**: Only fetch full user data on demand

### Reduce Chat Capture Wait

- **Pre-validate**: Check input format before prompting next step
- **Default values**: Remember player's email if possible
- **Auto-advance**: Move to next step immediately after validation

### Monitor Performance

- **Log timings**: "User creation took XXXms"
- **Track failures**: "API call failed: XXX, retry attempt Y"
- **Alert on slow**: If operation takes >5s, log warning

---

**Quick Reference Version**: 1.0  
**Last Updated**: January 29, 2026  
**Status**: Ready for use during implementation
