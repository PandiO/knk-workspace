# Knights & Kings - Developer Guide: Account Integration

**Version**: 2.0  
**Last Updated**: January 31, 2026  
**Plugin**: knk-plugin-v2  
**Target Audience**: Plugin developers, contributors

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Account Management Flow](#account-management-flow)
3. [Command Implementation](#command-implementation)
4. [API Client Usage](#api-client-usage)
5. [User Manager](#user-manager)
6. [Chat Capture System](#chat-capture-system)
7. [Event Listeners](#event-listeners)
8. [Configuration](#configuration)
9. [Testing](#testing)
10. [Best Practices](#best-practices)
11. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

The account management system follows a layered architecture:

```
┌─────────────────────────────────────────────────────────────────┐
│                     Commands Layer                              │
│         /account | /account link                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                     Business Logic Layer                        │
│  UserManager | ChatCaptureManager | Event Listeners             │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                     API Client Layer                            │
│  UserAccountApi (HTTP communication)                            │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTPS
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Backend API (knk-web-api-v2)                │
│  UsersController | UserService | UserRepository                 │
└─────────────────────────────────────────────────────────────────┘
```

### Key Design Principles

1. **Separation of Concerns**: API client, business logic, and UI are separated
2. **Async Operations**: All API calls use CompletableFuture
3. **Caching**: User data is cached in-memory during player sessions
4. **Security**: Link codes are single-use, time-limited (20 minutes)
5. **Error Handling**: Graceful degradation with user-friendly messages
6. **Web App First**: Email/password creation happens only in web app

---

## Account Management Flow

### Version 2.0 Changes (January 31, 2026)

**Removed**:
- `/account create` command
- In-game email/password collection
- ChatCaptureManager email/password flows
- Account creation flows via Minecraft

**Current Supported Flows**:

#### Flow 1: Web App → Minecraft (Recommended)
```
1. Player creates account on web app (email + password)
2. Player generates link code on web app
3. Player joins Minecraft server (minimal account auto-created)
4. Player uses: /account link <code>
5. System verifies code and links accounts
6. If duplicate detected, triggers merge flow
7. Accounts linked, all stats synced
```

#### Flow 2: Minecraft → Web App → Link
```
1. Player joins Minecraft server (minimal account auto-created)
2. Player creates account on web app
3. Player generates link code on web app
4. Player uses: /account link <code>
5. (Same as Flow 1, step 4+)
```

### Why This Approach?

- ✅ **Better UX**: Web form is better for email/password than chat input
- ✅ **Security**: Email/password not sent through Minecraft chat
- ✅ **Consistency**: Unified account creation on web app
- ✅ **Validation**: Email verification and password rules in one place
- ✅ **Simplicity**: Plugin code is simpler (no email/password flows)

---

## Command Implementation

### AccountCommand (`/account`)

**Location**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/commands/AccountCommand.java`

**Purpose**: Display account status

**Flow**:
```java
public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
    if (!(sender instanceof Player player)) {
        sender.sendMessage("Only players can use this command");
        return true;
    }

    PlayerUserData userData = userManager.getCachedUser(player.getUniqueId());
    if (userData == null) {
        sendPrefixed(player, "&cPlease rejoin the server and try again");
        return true;
    }

    // Display account info
    sendPrefixed(player, "&6=== Your Account ===");
    sendRaw(player, "  &eUsername: &f" + userData.username());
    sendRaw(player, "  &eUUID: &7" + userData.uuid());
    
    String emailValue = userData.hasEmailLinked()
        ? "&a" + userData.email()
        : "&cNot linked";
    sendRaw(player, "  &eEmail: " + emailValue);
    
    // Show link status
    if (!userData.hasEmailLinked()) {
        sendRaw(player, "  &7Use &6/account link &7to link your account");
    }
    
    return true;
}
```

**Key Points**:
- No longer suggests `/account create`
- Only `/account link` for linking
- Shows email status clearly

---

### AccountLinkCommand (`/account link`)

**Location**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/commands/AccountLinkCommand.java`

**Purpose**: Link Minecraft and web app accounts using link code

**Flow**:
```java
public boolean onCommand(CommandSender sender, Command command, String label, String[] args) {
    if (!(sender instanceof Player player)) {
        sender.sendMessage("Only players can use this command");
        return true;
    }

    // No args = show help
    if (args.length == 0) {
        sendPrefixed(player, "&eUsage: /account link <code>");
        sendPrefixed(player, "&7Example: /account link ABC12XYZ");
        return true;
    }

    String code = args[0];
    UserManager userData = userManager.getCachedUser(player.getUniqueId());
    
    // Validate code format (8 chars)
    if (code.length() != 8) {
        sendPrefixed(player, "&cInvalid code format (must be 8 characters)");
        return true;
    }

    // Call API to validate and link
    userAccountApi.validateLinkCode(code)
        .thenApply(result -> {
            if (!result.isValid()) {
                runSync(() -> sendPrefixed(player, "&cLink code expired or invalid"));
                return null;
            }
            
            // Check for duplicate
            Integer linkUserId = result.userId();
            Integer currentUserId = userData.userId();
            
            if (linkUserId != null && currentUserId != null && 
                !linkUserId.equals(currentUserId)) {
                // Duplicate detected, trigger merge flow
                triggerMergeFlow(player, userData, linkUserId);
            } else {
                // Simple link
                completeLink(player, userData);
            }
            return null;
        })
        .exceptionally(ex -> {
            runSync(() -> {
                plugin.getLogger().severe("Link failed: " + ex.getMessage());
                sendPrefixed(player, "&cFailed to link account");
            });
            return null;
        });
    
    return true;
}
```

**Key Points**:
- Accepts 8-character link code
- Validates on web app via API
- Handles merge if duplicates found
- Uses async CompletableFuture

---

## API Client Usage

### UserAccountApi Interface

**Location**: `knk-api-client/src/main/java/net/knightsandkings/knk/api/ports/UserAccountApi.java`

**Methods** (v2.0):
```java
// No longer has createUser with email/password
// No longer has updateEmail, changePassword

CompletableFuture<Object> checkDuplicate(String uuid, String username);

CompletableFuture<Object> validateLinkCode(String code);

CompletableFuture<Object> generateLinkCode(Integer userId);

CompletableFuture<Object> linkAccount(Object request);

CompletableFuture<Object> mergeAccounts(Object request);
```

### UserAccountApiImpl

**Location**: `knk-api-client/src/main/java/net/knightsandkings/knk/api/impl/UserAccountApiImpl.java`

**Removed in v2.0**:
```java
// ❌ REMOVED
updateEmail(Integer userId, String newEmail)
changePassword(Integer userId, Object request)
startAccountCreateFlow()
```

**Key Method**: `validateLinkCode`
```java
@Override
public CompletableFuture<Object> validateLinkCode(String code) {
    return CompletableFuture.supplyAsync(() -> {
        try {
            String url = baseUrl + "/Users/validate-link-code/" + encodeParam(code);
            String response = postJson(url, "{}"); // Empty body for POST
            return parse(response, ValidateLinkCodeResponseDto.class, url);
        } catch (IOException | ApiException ex) {
            throw new RuntimeException("Failed to validate link code", ex);
        }
    }, executor);
}
```

---

## User Manager

### PlayerUserData Class

**Location**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/user/PlayerUserData.java`

**Properties**:
```java
public record PlayerUserData(
    Integer userId,
    String username,
    UUID uuid,
    String email,              // Nullable
    Integer coins,
    Integer gems,
    Integer experiencePoints,
    Boolean hasEmailLinked,
    Boolean hasDuplicateAccount,
    String duplicateAccountInfo // Nullable
) {
    // Helper methods
    public boolean hasEmailLinked() { ... }
    public boolean hasDuplicateAccount() { ... }
    public PlayerUserData withEmailLinked(String email) { ... }
}
```

**Note**: No password field (never sent from server to plugin)

### UserManager Class

**Location**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/user/UserManager.java`

**Key Methods**:
```java
public class UserManager {
    // Cache management
    public PlayerUserData getCachedUser(UUID playerId) { ... }
    public void updateCachedUser(UUID playerId, PlayerUserData data) { ... }
    public void clearCachedUser(UUID playerId) { ... }
    
    // Account linking
    public CompletableFuture<Void> linkAccounts(UUID playerId, Integer userId) { ... }
    
    // Duplicate handling
    public CompletableFuture<Void> resolveDuplicates(UUID playerId, Integer winningUserId) { ... }
}
```

---

## Chat Capture System

### ChatCaptureManager (v2.0)

**Location**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/chat/ChatCaptureManager.java`

**Removed in v2.0**:
```java
// ❌ REMOVED
startAccountCreateFlow(Player player, Consumer<Map<String, String>> onComplete, Runnable onCancel)
handleAccountCreateInput(Player player, ChatCaptureSession session, String input)
```

**Still Supported**:
```java
// ✅ STILL AVAILABLE
startMergeFlow(Player player, /* account data */, Consumer<Map<String, String>> onComplete, Runnable onCancel)
handleMergeInput(Player player, ChatCaptureSession session, String input)
```

### CaptureFlow Enum

**Location**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/chat/CaptureFlow.java`

**v2.0**:
```java
public enum CaptureFlow {
    // ❌ REMOVED: ACCOUNT_CREATE
    
    // ✅ STILL AVAILABLE
    ACCOUNT_MERGE
}
```

---

## Event Listeners

### PlayerJoinListener

**Location**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/listeners/PlayerJoinListener.java`

**Changes in v2.0**:
```java
@EventHandler
public void onPlayerJoin(PlayerJoinEvent event) {
    Player player = event.getPlayer();
    
    // 1. Check/create user by UUID
    api.checkDuplicate(player.getUniqueId().toString(), player.getName())
        .thenAccept(response -> {
            if (response.hasDuplicate()) {
                // Flag for merge on next link attempt
                flagForMerge(player);
            } else {
                // Create minimal account if needed
                createMinimalUser(player);
            }
        });
}
```

**Key Changes**:
- No automatic `/account create` prompt
- Only shows account status on join
- Suggests `/account link` if not linked

### ChatCaptureListener

**Changes in v2.0**:
- Still handles ACCOUNT_MERGE flows
- No longer handles ACCOUNT_CREATE flows
- Simpler code path

---

## Configuration

### config.yml

**Version 2.0 Settings**:
```yaml
account:
  # Link code expiry (minutes)
  link_code_expiry_minutes: 20
  
  # Merge flow timeout (seconds)
  chat_capture_timeout_seconds: 120
  
  # Command cooldowns
  cooldowns:
    account_link_seconds: 10

messages:
  prefix: "§8[§6KnK§8]§r "
  
  # Removed in v2.0
  # account_created: "..."
  # account_create_prompt: "..."
  
  account_linked: "§aYour account is now linked!"
  link_code_invalid: "§cThis link code is invalid or has expired"
```

---

## Testing

### Unit Tests

**Changes in v2.0**:
- ❌ Removed `AccountCreateFlowTests`
- ✅ Kept `AccountLinkFlowTests`
- ✅ Kept `AccountMergeFlowTests`

**Test Structure**:
```
knk-paper/src/test/java/
├── chat/
│   ├── ChatCaptureManagerTest.java  (removed ACCOUNT_CREATE tests)
│   └── CaptureFlowTest.java
├── commands/
│   ├── AccountCommandTest.java      (updated)
│   └── AccountLinkCommandTest.java  (kept)
├── user/
│   └── UserManagerTest.java
└── integration/
    └── AccountCommandIntegrationTest.java (updated)
```

### Test Examples

**Test Link Code Validation**:
```java
@Test
@DisplayName("Should validate and use link code successfully")
void shouldValidateLinkCode() {
    // Arrange
    when(mockApi.validateLinkCode(eq("ABC12XYZ")))
        .thenReturn(CompletableFuture.completedFuture(
            new ValidateLinkCodeResponseDto(true, 2, "WebUser", "web@example.com")
        ));
    
    // Act
    accountLinkCommand.onCommand(mockPlayer, null, "account", new String[]{"ABC12XYZ"});
    
    // Assert
    verify(mockApi, timeout(1000)).validateLinkCode("ABC12XYZ");
    assertTrue(userManager.getCachedUser(testUUID).hasEmailLinked());
}
```

---

## Best Practices

### 1. Always Cache User Data

```java
// ✅ GOOD: Cache retrieved on join and reused
PlayerUserData data = userManager.getCachedUser(player.getUniqueId());

// ❌ BAD: Always querying API
CompletableFuture<UserData> user = api.getUser(id);
```

### 2. Use Async Operations

```java
// ✅ GOOD: Non-blocking
api.validateLinkCode(code)
    .thenAccept(result -> {
        runSync(() -> {
            // Do UI work on main thread
        });
    });

// ❌ BAD: Blocking
UserData user = api.getUser(id).get(); // Blocks server!
```

### 3. Handle API Errors Gracefully

```java
// ✅ GOOD: User-friendly error
.exceptionally(ex -> {
    runSync(() -> sendPrefixed(player, "&cAccount service unavailable. Try again later."));
    plugin.getLogger().severe("API Error: " + ex.getMessage());
    return null;
});

// ❌ BAD: Stack trace to player
throw new RuntimeException(ex);
```

### 4. Validate Input Before API Call

```java
// ✅ GOOD: Validate format first
if (code.length() != 8) {
    sendPrefixed(player, "&cInvalid code format");
    return true;
}

// ❌ BAD: Let API validate
api.validateLinkCode(code);
```

### 5. Clear Sensitive Data

```java
// ✅ GOOD: Clear sensitive data from sessions
session.clearSensitiveData();

// ❌ BAD: Leave passwords/codes in memory
```

---

## Troubleshooting

### API Error: "Email is required. (Parameter 'newEmail')"

**Cause**: Using old API that expected `email` instead of `newEmail`

**Fix**: This is fixed in UserAccountApiImpl (v2.0) - now sends `newEmail`

**Code**:
```java
String json = objectMapper.writeValueAsString(java.util.Map.of("newEmail", newEmail));
```

### API Error: "Empty response body"

**Cause**: 204 No Content response treated as error

**Fix**: Handle 204 as valid success response

**Code** (in BaseApiImpl):
```java
if (response.code() == 204) {
    return "";
}
```

### Command Doesn't Work

**Causes**:
1. Player doesn't have permission - check `knk.account.use` permission
2. User not cached - tell player to rejoin
3. API unavailable - check backend service

**Debug**:
```java
plugin.getLogger().fine("Link code: " + code);
plugin.getLogger().fine("User ID: " + userData.userId());
plugin.getLogger().info("API Request: validating link code");
```

### Link Code Invalid/Expired

**Common Issues**:
1. **Already used**: Each code is single-use
2. **Expired**: Codes only valid for 20 minutes
3. **Typo**: Code is case-sensitive

**API Response**:
```json
{
    "isValid": false,
    "error": "Invalid or expired link code"
}
```

---

## Migration Guide (v1.0 → v2.0)

### For Existing Installations

**Breaking Changes**:
1. `/account create` command removed
2. No more email/password input in Minecraft
3. ChatCaptureManager doesn't handle ACCOUNT_CREATE flow
4. UserAccountApi methods removed: `updateEmail`, `changePassword`

**Migration Steps**:
1. Update plugin JAR
2. Update configuration
3. Update documentation for players
4. Test link code flow on dev server

**No Database Changes Required**:
- User schema unchanged
- Link codes still work same way
- Duplicate detection still works

### For Players

**Required Action**:
1. Create account on web app (email + password)
2. Generate link code on web app
3. Use `/account link <code>` in Minecraft

**No Action Needed**:
- Already linked accounts work fine
- Stats continue to sync
- No data loss

---

## Version History

### Version 2.0 (January 31, 2026)
- **Removed**: `/account create` command
- **Removed**: In-game email/password collection
- **Removed**: ChatCaptureManager ACCOUNT_CREATE flows
- **Changed**: Account creation now web app only
- **Changed**: Link code generation now web app only
- **Updated**: Documentation and guides

### Version 1.0 (January 30, 2026)
- Initial release of account management system
- `/account`, `/account create`, `/account link` commands
- Auto-sync on player join
- Duplicate account detection and merging
- Chat capture for email/password input

---

**For questions or issues, contact the development team.**
