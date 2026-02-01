# Phase 1 File Structure & Code Layout

**Purpose**: Show exact file paths, package structure, and code organization for Phase 1  
**Related**: [PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md](PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md)

---

## File Tree

```
Repository/knk-plugin-v2/
├── knk-api-client/
│   ├── build.gradle.kts (update: add dependencies)
│   └── src/main/java/net/knightsandkings/knk/api/
│       ├── UserAccountApi.java (NEW)
│       ├── impl/
│       │   └── UserAccountApiImpl.java (NEW)
│       ├── dto/
│       │   └── user/
│       │       ├── CreateUserRequest.java (NEW)
│       │       ├── UserResponse.java (NEW)
│       │       ├── LinkCodeResponse.java (NEW)
│       │       ├── ValidateLinkCodeResponse.java (NEW)
│       │       ├── DuplicateCheckResponse.java (NEW)
│       │       ├── ChangePasswordRequest.java (NEW)
│       │       ├── LinkAccountRequest.java (NEW)
│       │       ├── MergeAccountsRequest.java (NEW)
│       │       └── LinkCodeRequest.java (NEW)
│       └── client/
│           └── KnkApiClient.java (UPDATE: add UserAccountApi)
│
├── knk-paper/
│   ├── src/main/java/net/knightsandkings/knk/paper/
│   │   ├── KnkPlugin.java (UPDATE: Phase 2+)
│   │   ├── config/
│   │   │   ├── KnkConfig.java (UPDATE: add AccountConfig, MessagesConfig)
│   │   │   └── ConfigLoader.java (UPDATE: load account/messages sections)
│   │   ├── user/ (NEW - Phase 2)
│   │   │   ├── UserManager.java
│   │   │   └── PlayerUserData.java
│   │   ├── chat/ (NEW - Phase 3)
│   │   │   ├── ChatCaptureManager.java
│   │   │   └── ChatCaptureSession.java
│   │   ├── listeners/ (UPDATE + NEW - Phase 2-3)
│   │   │   ├── PlayerListener.java (update)
│   │   │   ├── PlayerJoinListener.java (NEW - Phase 2)
│   │   │   └── ChatCaptureListener.java (NEW - Phase 3)
│   │   └── commands/ (NEW - Phase 4)
│   │       └── AccountCommand.java
│   │
│   └── src/main/resources/
│       ├── config.yml (UPDATE: add account/messages sections)
│       └── plugin.yml (UPDATE: add account command)
│
└── docs/
    └── ai/plugin-auth/
        ├── PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md (this roadmap)
        ├── IMPLEMENTATION_DETAILS_AND_EDGE_CASES.md (deep dive)
        ├── PLUGIN_FRONTEND_COORDINATION.md (cross-system design)
        ├── PHASE_1_CODE_STRUCTURE.md (THIS FILE)
        └── README.md (navigation guide)
```

---

## Package Structure

### knk-api-client (Shared API Layer)

```
net.knightsandkings.knk.api
├── UserAccountApi.java ................................. Interface contract
├── impl/
│   ├── BaseApiImpl.java .................................. Existing base class
│   └── UserAccountApiImpl.java .......................... Implementation (NEW)
├── client/
│   └── KnkApiClient.java ................................ Main API client facade
├── dto/user/ .............................................. User-specific DTOs
│   ├── CreateUserRequest.java
│   ├── UserResponse.java
│   ├── LinkCodeResponse.java
│   ├── ValidateLinkCodeResponse.java
│   ├── DuplicateCheckResponse.java
│   ├── ChangePasswordRequest.java
│   ├── LinkAccountRequest.java
│   ├── MergeAccountsRequest.java
│   └── LinkCodeRequest.java
└── [existing packages] ................................... UsersQueryApi, etc.
```

### knk-paper (Plugin Implementation)

```
net.knightsandkings.knk.paper
├── KnkPlugin.java ......................................... Main plugin class
├── config/
│   ├── KnkConfig.java
│   │   └── AccountConfig record (NEW)
│   │   └── MessagesConfig record (NEW)
│   └── ConfigLoader.java
├── user/ (Phase 2)
│   ├── UserManager.java
│   └── PlayerUserData.java
├── chat/ (Phase 3)
│   ├── ChatCaptureManager.java
│   └── ChatCaptureSession.java
├── listeners/
│   ├── PlayerListener.java (existing, may extend)
│   ├── PlayerJoinListener.java (NEW - Phase 2)
│   └── ChatCaptureListener.java (NEW - Phase 3)
├── commands/ (Phase 4)
│   └── AccountCommand.java
└── [existing packages] .................................... cache, regions, etc.
```

---

## Phase 1 File Details

### 1. UserAccountApi.java (Interface)

**Location**: `knk-api-client/src/main/java/net/knightsandkings/knk/api/UserAccountApi.java`

```java
package net.knightsandkings.knk.api;

import java.util.concurrent.CompletableFuture;
import net.knightsandkings.knk.api.dto.user.*;

/**
 * User account management API contract.
 * Defines methods for creating accounts, generating link codes, etc.
 */
public interface UserAccountApi {
    
    /**
     * Create a new user account.
     * Supports: minimal (UUID+username), full (email+password), link code flows
     */
    CompletableFuture<UserResponse> createUser(CreateUserRequest request);
    
    /**
     * Check for duplicate accounts (same username)
     */
    CompletableFuture<DuplicateCheckResponse> checkDuplicate(String uuid, String username);
    
    /**
     * Generate a link code for account linking
     */
    CompletableFuture<LinkCodeResponse> generateLinkCode(int userId);
    
    /**
     * Validate a link code before using it
     */
    CompletableFuture<ValidateLinkCodeResponse> validateLinkCode(String code);
    
    /**
     * Update user's email address
     */
    CompletableFuture<Boolean> updateEmail(int userId, String email);
    
    /**
     * Change user's password
     */
    CompletableFuture<Boolean> changePassword(int userId, ChangePasswordRequest request);
    
    /**
     * Merge two user accounts
     */
    CompletableFuture<UserResponse> mergeAccounts(int primaryId, int secondaryId);
    
    /**
     * Link existing web account to Minecraft UUID
     */
    CompletableFuture<UserResponse> linkAccount(LinkAccountRequest request);
}
```

**Size**: ~85 lines

---

### 2. UserAccountApiImpl.java (Implementation)

**Location**: `knk-api-client/src/main/java/net/knightsandkings/knk/api/impl/UserAccountApiImpl.java`

**Key features**:
- Extends `BaseApiImpl` (inherits retry logic, error handling)
- Uses OkHttp for HTTP calls
- Jackson for JSON serialization
- Async via CompletableFuture
- Error handling: Catches API errors, wraps in CompletableFuture

**Structure**:
```java
package net.knightsandkings.knk.api.impl;

public class UserAccountApiImpl extends BaseApiImpl implements UserAccountApi {
    
    private static final String USERS_ENDPOINT = "/api/Users";
    
    public UserAccountApiImpl(KnkApiClient client) {
        super(client);
    }
    
    @Override
    public CompletableFuture<UserResponse> createUser(CreateUserRequest request) {
        // POST /api/Users
        // Return parsed UserResponse
    }
    
    @Override
    public CompletableFuture<DuplicateCheckResponse> checkDuplicate(String uuid, String username) {
        // POST /api/Users/check-duplicate?uuid=...&username=...
        // Return parsed DuplicateCheckResponse
    }
    
    // ... 6 more methods ...
}
```

**Size**: ~150-200 lines

---

### 3. DTOs (9 Files in dto/user/)

Each DTO is a simple Java record with Jackson annotations:

#### CreateUserRequest.java
```java
@JsonIgnoreProperties(ignoreUnknown = true)
public record CreateUserRequest(
    @JsonProperty("username") String username,
    @JsonProperty("uuid") String uuid,
    @JsonProperty("email") String email,
    @JsonProperty("password") String password,
    @JsonProperty("linkCode") String linkCode
) {
    // Factory methods
    public static CreateUserRequest minimalUser(String uuid, String username) { ... }
    public static CreateUserRequest fullUser(...) { ... }
}
```

**Size**: ~40-60 lines each

**Total for all 9 DTOs**: ~450 lines

---

### 4. KnkConfig.java Updates

**Location**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/config/KnkConfig.java`

**Additions**:
```java
public record AccountConfig(
    int linkCodeExpiryMinutes,
    int chatCaptureTimeoutSeconds
) {
    public void validate() { ... }
    public static AccountConfig defaultConfig() { ... }
}

public record MessagesConfig(
    String prefix,
    String accountCreated,
    String accountLinked,
    String linkCodeGenerated,
    String invalidLinkCode,
    String duplicateAccount,
    String mergeComplete
) {
    public String format(String template, Map<String, String> placeholders) { ... }
    public static MessagesConfig defaultConfig() { ... }
}
```

**Size**: +100 lines

---

### 5. ConfigLoader.java Updates

**Location**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/config/ConfigLoader.java`

**Additions**:
```java
public static AccountConfig loadAccountConfig(ConfigurationSection section) {
    if (section == null) {
        logger.warning("No 'account' section, using defaults");
        return AccountConfig.defaultConfig();
    }
    
    int expiryMinutes = section.getInt("link-code-expiry-minutes", 20);
    int timeoutSeconds = section.getInt("chat-capture-timeout-seconds", 120);
    
    AccountConfig config = new AccountConfig(expiryMinutes, timeoutSeconds);
    config.validate();
    return config;
}

public static MessagesConfig loadMessagesConfig(ConfigurationSection section) {
    // Similar pattern
}
```

**Size**: +50 lines

---

### 6. config.yml Updates

**Location**: `knk-paper/src/main/resources/config.yml`

**Additions**:
```yaml
account:
  link-code-expiry-minutes: 20
  chat-capture-timeout-seconds: 120

messages:
  prefix: "&8[&6KnK&8] &r"
  account-created: "&aAccount created successfully! Link email on web app to sync progress."
  account-linked: "&aYour accounts have been linked!"
  link-code-generated: "&aYour link code is: &6{code}&a (expires in {minutes} min)"
  invalid-link-code: "&cInvalid or expired code. Use &6/account link &cto get a new one."
  duplicate-account: "&cYou have two accounts. Use &6/account merge &cto resolve."
  merge-complete: "&aMerge complete! You now have {coins} coins, {gems} gems, {exp} XP."
```

**Lines**: ~12

---

### 7. KnkApiClient.java Updates

**Location**: `knk-api-client/src/main/java/net/knightsandkings/knk/api/client/KnkApiClient.java`

**Changes**:
```java
public class KnkApiClient {
    // ... existing fields ...
    
    // Add field
    private final UserAccountApi userAccountApi;
    
    // In constructor
    this.userAccountApi = new UserAccountApiImpl(this);
    
    // Add getter
    public UserAccountApi getUserAccountApi() {
        return userAccountApi;
    }
}
```

**Size**: +10 lines

---

### 8. plugin.yml Updates

**Location**: `knk-paper/src/main/resources/plugin.yml`

**Additions**:
```yaml
commands:
  account:
    description: "Manage your in-game account"
    usage: "/account [create|link]"
    aliases: [acc]
    permission: knk.account.use

permissions:
  knk.account.use:
    description: "Allows player to manage their account"
    default: true
```

**Lines**: ~10

---

### 9. Dependencies Update

**Location**: `knk-api-client/build.gradle.kts`

**No changes needed** (OkHttp and Jackson already in project)

---

## Phase 1 Code Checklist

### Files to CREATE (11 new)
- [x] UserAccountApi.java
- [x] UserAccountApiImpl.java
- [x] CreateUserRequest.java
- [x] UserResponse.java
- [x] LinkCodeResponse.java
- [x] ValidateLinkCodeResponse.java
- [x] DuplicateCheckResponse.java
- [x] ChangePasswordRequest.java
- [x] LinkAccountRequest.java
- [x] MergeAccountsRequest.java
- [x] LinkCodeRequest.java

### Files to UPDATE (4 modified)
- [x] KnkApiClient.java (add UserAccountApi)
- [x] KnkConfig.java (add AccountConfig, MessagesConfig)
- [x] ConfigLoader.java (load account/messages)
- [x] config.yml (add account and messages sections)
- [x] plugin.yml (add account command) - if not already there

### Files to CREATE (Phase 2+, not Phase 1)
- [ ] UserManager.java
- [ ] PlayerUserData.java
- [ ] PlayerJoinListener.java
- [ ] ChatCaptureManager.java
- [ ] ChatCaptureSession.java
- [ ] ChatCaptureListener.java
- [ ] AccountCommand.java

---

## Code Organization Best Practices

### Package Organization
- **DTOs**: All in `api.dto.user` (shared between API layers)
- **Implementation**: `api.impl` (hide implementation details)
- **Config**: `paper.config` (plugin-specific)
- **Managers**: `paper.user`, `paper.chat` (Phase 2+)
- **Listeners**: `paper.listeners` (Phase 2+)
- **Commands**: `paper.commands` (Phase 4)

### Naming Conventions
- **Interfaces**: `UserAccountApi` (no "I" prefix)
- **Implementations**: `UserAccountApiImpl` (suffix with "Impl")
- **Records**: `CreateUserRequest`, `UserResponse` (no "DTO" suffix needed)
- **Config records**: `AccountConfig`, `MessagesConfig`
- **Managers**: `UserManager`, `ChatCaptureManager`
- **Listeners**: `PlayerJoinListener`, `ChatCaptureListener`

### Imports
```java
// API imports
import net.knightsandkings.knk.api.UserAccountApi;
import net.knightsandkings.knk.api.impl.UserAccountApiImpl;
import net.knightsandkings.knk.api.dto.user.*;

// Config imports
import net.knightsandkings.knk.paper.config.KnkConfig;

// Bukkit/Spigot
import org.bukkit.plugin.PluginCommand;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;

// Async
import java.util.concurrent.CompletableFuture;

// Jackson
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
```

---

## Build & Compilation

### Gradle Build Command
```bash
# From knk-plugin-v2 root
./gradlew :knk-api-client:build
./gradlew :knk-paper:build
./gradlew :knk-paper:fatJar  # if packaging needed
```

### Expected Compilation Time
- First build: ~30-45 seconds
- Incremental: ~5-10 seconds

### Common Issues
1. **Missing imports**: Ensure all Jackson annotations imported
2. **Package name mismatch**: Double-check package declaration
3. **Syntax error in DTO**: Records must have correct semicolon syntax

---

## Phase 1 Summary

| Metric | Value |
|--------|-------|
| **New files** | 11 |
| **Modified files** | 5 |
| **Total lines added** | ~490 |
| **Packages affected** | 3 (api, api.impl, paper.config) |
| **Dependencies added** | 0 (OkHttp + Jackson already present) |
| **Build time** | ~40 seconds |
| **Complexity** | Low (mostly data classes + HTTP wrapper) |

---

**Document Version**: 1.0  
**Last Updated**: January 29, 2026  
**Ready for Implementation**: ✅ YES

**Next**: Create these files following the structure above, then proceed to Phase 2
