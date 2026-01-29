# Plugin Auth Implementation: Detailed Flows & Edge Cases

**Related**: [PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md](PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md)  
**Date**: January 29, 2026

---

## Table of Contents

1. [Plugin Wiring & Integration](#plugin-wiring--integration)
2. [State Management & Data Structures](#state-management--data-structures)
3. [Player Join Flow (State Machine)](#player-join-flow-state-machine)
4. [Chat Capture Flow (State Machine)](#chat-capture-flow-state-machine)
5. [Edge Cases & Error Handling](#edge-cases--error-handling)
6. [Frontend-Plugin Coordination](#frontend-plugin-coordination)
7. [Thread Safety & Concurrency](#thread-safety--concurrency)

---

## Plugin Wiring & Integration

### KnkPlugin.onEnable() Integration

**File**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/KnkPlugin.java`

**Pattern** (follows existing plugin architecture):

```java
@Override
public void onEnable() {
    // ... existing code (load config, auth provider, API client)
    
    // Line ~95: After existing APIs are wired
    // Wire UserAccountApi from client
    this.userAccountApi = apiClient.getUserAccountApi();
    getLogger().info("UserAccountApi wired from API client");
    
    // Create and register UserManager (Phase 2)
    this.userManager = new UserManager(this, userAccountApi, getLogger(), config.account());
    getLogger().info("UserManager initialized");
    
    // Create ChatCaptureManager (Phase 3)
    this.chatCaptureManager = new ChatCaptureManager(this, config.account(), config.messages(), getLogger());
    getLogger().info("ChatCaptureManager initialized");
    
    // Register listeners
    getServer().getPluginManager().registerEvents(
        new PlayerJoinListener(userManager, config.messages(), getLogger()),
        this
    );
    getServer().getPluginManager().registerEvents(
        new ChatCaptureListener(chatCaptureManager),
        this
    );
    getLogger().info("Account management listeners registered");
    
    // Register commands
    PluginCommand accountCmd = getCommand("account");
    if (accountCmd != null) {
        accountCmd.setExecutor(new AccountCommand(userManager, config.messages(), getLogger()));
    } else {
        getLogger().warning("Command /account not found in plugin.yml");
    }
}
```

### Plugin Fields

```java
// User account management (Phase 2+)
private UserAccountApi userAccountApi;
private UserManager userManager;
private ChatCaptureManager chatCaptureManager;

// Public getters
public UserAccountApi getUserAccountApi() {
    return userAccountApi;
}

public UserManager getUserManager() {
    return userManager;
}

public ChatCaptureManager getChatCaptureManager() {
    return chatCaptureManager;
}
```

### plugin.yml Registration

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
  knk.account.admin:
    description: "Admin account management"
    default: op
```

---

## State Management & Data Structures

### PlayerUserData Cache

**Immutable record** storing cached player account info:

```java
package net.knightsandkings.knk.paper.user;

import java.util.UUID;

public record PlayerUserData(
    int userId,                    // From API
    String username,               // From API
    UUID uuid,                     // Minecraft UUID
    String email,                  // May be null
    int coins,                     // Cached balance
    int gems,                      // Cached balance
    int experiencePoints,          // Cached balance
    boolean hasEmailLinked,        // Email linked status
    boolean hasDuplicateAccount,   // Set if conflict detected
    Integer conflictingUserId,     // ID of conflicting account (if any)
    long cacheTimestamp            // When loaded (for staleness checking)
) {
    /**
     * Check if cache data is stale (older than 5 minutes).
     * For real-time decisions (like balance display), consider refresh.
     */
    public boolean isStale() {
        return System.currentTimeMillis() - cacheTimestamp > 5 * 60 * 1000;
    }
}
```

### UserManager Cache Storage

```java
package net.knightsandkings.knk.paper.user;

import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.Optional;

public class UserManager {
    // Thread-safe cache (concurrent operations are atomic)
    private final ConcurrentHashMap<UUID, PlayerUserData> userCache = new ConcurrentHashMap<>();
    
    public Optional<PlayerUserData> getCachedUser(UUID uuid) {
        return Optional.ofNullable(userCache.get(uuid));
    }
    
    public void updateCachedUser(UUID uuid, PlayerUserData data) {
        userCache.put(uuid, data);
    }
    
    public void removeCachedUser(UUID uuid) {
        userCache.remove(uuid);
    }
}
```

**Lifecycle**:
- **Created**: AsyncPlayerPreLoginEvent (via API call)
- **Read**: PlayerJoinEvent (display welcome)
- **Updated**: Account command execution (sync after changes)
- **Cleared**: PlayerQuitEvent (memory cleanup)

### ChatCaptureSession State

```java
package net.knightsandkings.knk.paper.chat;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.UUID;

public enum CaptureStep {
    EMAIL,                // Waiting for email input
    PASSWORD,             // Waiting for password
    PASSWORD_CONFIRM,     // Waiting for confirmation
    ACCOUNT_CHOICE        // Waiting for A/B choice (merge scenario)
}

public class ChatCaptureSession {
    private final UUID playerId;
    private final CaptureFlow flow;
    private CaptureStep currentStep;
    private final long startTime;
    private final Map<String, String> data;  // email, password, choice
    private Runnable onComplete;
    private Runnable onCancel;
    
    // Constructor, getters, setters...
}

public enum CaptureFlow {
    ACCOUNT_CREATE,
    ACCOUNT_MERGE,
    PASSWORD_CHANGE  // Future
}

public class ChatCaptureManager {
    private final ConcurrentHashMap<UUID, ChatCaptureSession> activeSessions = new ConcurrentHashMap<>();
    
    public ChatCaptureSession startFlow(UUID playerId, CaptureFlow flow) {
        // Create session, add to map, start timeout task
    }
    
    public Optional<ChatCaptureSession> handleInput(UUID playerId, String input) {
        // Process input for active session
    }
    
    public void cancelSession(UUID playerId) {
        // Remove and cleanup
    }
}
```

---

## Player Join Flow (State Machine)

### Sequence Diagram

```
ASYNC THREAD: AsyncPlayerPreLoginEvent
  ├─ UserManager.onPlayerJoin(player)
  │  ├─ Check cache: userCache.get(uuid)
  │  │  └─ FOUND: return (skip API)
  │  │  └─ NOT FOUND: continue
  │  │
  │  ├─ Call userAccountApi.checkDuplicate(uuid, username)
  │  │  │
  │  │  ├─ UNIQUE: Create minimal user
  │  │  │  ├─ userAccountApi.createUser(uuid, username)
  │  │  │  ├─ On success: Cache UserSummary
  │  │  │  └─ On error: Log, continue (allow join)
  │  │  │
  │  │  ├─ DUPLICATE: Set flags
  │  │  │  ├─ hasDuplicateAccount = true
  │  │  │  ├─ conflictingUserId = conflict.id
  │  │  │  └─ Cache with flags
  │  │  │
  │  │  └─ API ERROR: Log, cache=null (fail-open)
  │  │
  │  └─ ALLOW LOGIN (never deny)
  │
MAIN THREAD: PlayerJoinEvent
  ├─ PlayerJoinListener.onJoin(player)
  │  ├─ Read cache: userCache.get(uuid)
  │  │  ├─ FOUND: Display welcome + balance
  │  │  │  └─ "Welcome! You have X coins"
  │  │  │
  │  │  └─ NOT FOUND: Generic welcome
  │  │     └─ "Welcome to KnK!"
  │  │
  │  ├─ If hasDuplicateAccount: Show prompt
  │  │  └─ "You have 2 accounts. Use /account merge"
  │  │
  │  └─ Log join
  │
END: Player in game, account synced
```

### Pseudo-Code for UserManager

```java
public class UserManager {
    private final KnkPlugin plugin;
    private final UserAccountApi userAccountApi;
    private final Logger logger;
    private final AccountConfig config;
    private final ConcurrentHashMap<UUID, PlayerUserData> userCache;
    
    /**
     * Called on AsyncPlayerPreLoginEvent (async thread - blocking is safe)
     */
    public PlayerUserData onPlayerJoin(UUID uuid, String username) {
        // 1. Check cache
        PlayerUserData cached = userCache.get(uuid);
        if (cached != null) {
            logger.fine("User " + uuid + " found in cache");
            return cached;
        }
        
        // 2. Check for duplicates
        try {
            DuplicateCheckResponse check = userAccountApi.checkDuplicate(uuid, username).get();
            
            if (check.hasDuplicate()) {
                // Duplicate detected - mark but allow join
                PlayerUserData data = new PlayerUserData(
                    check.conflictingUser().id(),
                    username,
                    uuid,
                    check.conflictingUser().email(),
                    check.conflictingUser().coins(),
                    0, // gems unknown
                    0, // exp unknown
                    false,
                    true,  // hasDuplicateAccount
                    check.primaryUser() != null ? check.primaryUser().id() : null,
                    System.currentTimeMillis()
                );
                userCache.put(uuid, data);
                logger.warning("Duplicate account detected for " + username);
                return data;
            }
            
            // 3. Create minimal user
            CreateUserRequest req = CreateUserRequest.minimalUser(uuid.toString(), username);
            UserResponse response = userAccountApi.createUser(req).get();
            
            PlayerUserData data = new PlayerUserData(
                response.id(),
                response.username(),
                uuid,
                response.email(),
                response.coins(),
                0,
                0,
                response.emailVerified(),
                false,  // No duplicate
                null,
                System.currentTimeMillis()
            );
            userCache.put(uuid, data);
            logger.info("Created and cached user: " + username);
            return data;
            
        } catch (CompletionException ex) {
            logger.warning("Failed to sync user on join: " + ex.getMessage());
            // IMPORTANT: Still allow join - fail-open approach
            return null;
        }
    }
}
```

---

## Chat Capture Flow (State Machine)

### Complete State Diagram

```
ENTRY: Player runs /account create

[STATE: INIT]
  ├─ Validate: Player not already captured
  ├─ Validate: Player not already has account
  └─ On error: Send message, return
  
[STATE: EMAIL_PROMPT]
  ├─ Show: "Type your email:"
  ├─ Create session: uuid, flow=ACCOUNT_CREATE, step=EMAIL
  ├─ Add to activeSessions
  ├─ Start timeout task (120 sec)
  └─ Listen for next chat message
  
ON CHAT MESSAGE (any message from player):
  ├─ ChatCaptureListener.onAsyncPlayerChat()
  │  └─ event.setCancelled(true)  [hide from others]
  │
  ├─ IF input == "cancel"
  │  ├─ cancelSession(uuid)
  │  ├─ Remove from activeSessions
  │  └─ Send "Cancelled"
  │  └─ RETURN
  │
  ├─ IF session not active (no entry in map)
  │  └─ Send to normal chat (not captured)
  │  └─ RETURN
  │
  ├─ ROUTE TO: handleChatInput(step=EMAIL, input)

[STATE: EMAIL_STEP]
  ├─ Validate: isValidEmail(input)
  │  ├─ INVALID: Send "Invalid email format"
  │  ├─ INVALID: Send "Try again:"
  │  └─ RETURN to EMAIL_PROMPT
  │
  ├─ Store: session.data["email"] = input
  ├─ Advance: session.currentStep = PASSWORD
  ├─ Reset: Start new timeout (120 sec)
  ├─ Send: "Type your password (8+ chars, 1 uppercase, 1 number):"
  └─ Wait for next input

[STATE: PASSWORD_STEP]
  ├─ Validate: isStrongPassword(input)
  │  ├─ WEAK: Send reason (e.g., "needs number")
  │  └─ RETURN to PASSWORD_PROMPT
  │
  ├─ Store: session.data["password"] = encrypt(input)
  ├─ Advance: session.currentStep = PASSWORD_CONFIRM
  ├─ Reset: Start new timeout
  ├─ Send: "Confirm your password:"
  └─ Wait for next input

[STATE: PASSWORD_CONFIRM_STEP]
  ├─ Validate: input == decrypt(session.data["password"])
  │  ├─ MISMATCH: Send "Passwords don't match"
  │  ├─ MISMATCH: Advance: currentStep = PASSWORD
  │  ├─ MISMATCH: Send "Type password again:"
  │  └─ RETURN to PASSWORD_PROMPT
  │
  ├─ COMPLETION: Call session.onComplete()
  │  │
  │  ├─ onComplete callback:
  │  │  ├─ userAccountApi.createUser(
  │  │  │    email=session.data["email"],
  │  │  │    password=session.data["password"],
  │  │  │    uuid=player.uuid,
  │  │  │    username=player.name
  │  │  │  )
  │  │  │
  │  │  ├─ ON SUCCESS:
  │  │  │  ├─ Update cache
  │  │  │  ├─ Send "Account created!"
  │  │  │  └─ Clear sensitive data from memory
  │  │  │
  │  │  └─ ON FAILURE:
  │  │     ├─ Log error
  │  │     ├─ Send "Creation failed: {error}"
  │  │     └─ Don't retry (user can run /account create again)
  │  │
  │  └─ Remove from activeSessions
  │  └─ COMPLETE
```

### Validation Functions

```java
private boolean isValidEmail(String email) {
    // Simple regex: at least one @ and one .
    return email.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
}

private boolean isStrongPassword(String password) {
    // Requirements: 8+ chars, 1 uppercase, 1 number
    if (password.length() < 8) return false;
    if (!password.matches(".*[A-Z].*")) return false;
    if (!password.matches(".*\\d.*")) return false;
    return true;
}
```

---

## Edge Cases & Error Handling

### Edge Case 1: Player Joins Before API Ready

**Scenario**: Plugin enables, player joins before backend responds to first request  
**Risk**: Player stuck in login screen, poor UX  
**Solution**:

1. **AsyncPlayerPreLoginEvent**: Try to fetch user, timeout after 30 seconds
2. **If timeout**: Log warning, do NOT kick player
3. **Cache**: Store `null` with timestamp
4. **PlayerJoinEvent**: Show generic welcome ("Welcome to KnK!")
5. **Next login**: Retry (cache miss after 5 min)

**Code**:
```java
try {
    UserResponse user = userAccountApi.createUser(req)
        .get(30, TimeUnit.SECONDS);  // Timeout
    userCache.put(uuid, data);
} catch (TimeoutException ex) {
    logger.warning("API timeout for user " + uuid + ", allowing login");
    // Continue (fail-open)
} catch (ExecutionException ex) {
    logger.warning("API error: " + ex.getCause().getMessage());
    // Continue
}
```

### Edge Case 2: Duplicate Account Detected

**Scenario**: Player has both Minecraft account (auto-created on join) and web account  
**Risk**: Coin/XP confusion, two separate profiles  
**Solution**:

1. **checkDuplicate()** returns: hasDuplicate=true, conflictingUser (web account), primaryUser (minecraft)
2. **Cache**: Set hasDuplicateAccount=true, conflictingUserId
3. **PlayerJoinEvent**: Display message: "You have 2 accounts. Use /account merge to choose"
4. **User action**: Runs `/account merge`
5. **Merge flow**: ChatCapture asks "A) Keep web account (X coins) or B) Keep Minecraft? Type A or B"
6. **Result**: One primary account, one deleted

### Edge Case 3: Player Quits During Chat Capture

**Scenario**: Player types email, then quits before password completion  
**Risk**: Orphaned session, data leak, incomplete account  
**Solution**:

1. **PlayerQuitEvent**: Register listener
2. **onQuit**: Call `chatCaptureManager.cancelSession(uuid)`
3. **Cancel logic**:
   - Remove from activeSessions map
   - Cancel timeout task
   - Clear session data from memory
4. **Result**: Session abandoned, no account created

**Code**:
```java
@EventHandler
public void onPlayerQuit(PlayerQuitEvent event) {
    chatCaptureManager.cancelSession(event.getPlayer().getUniqueId());
    userManager.removeCachedUser(event.getPlayer().getUniqueId());
}
```

### Edge Case 4: Timeout During Capture

**Scenario**: Player in EMAIL step, no input for 120 seconds  
**Risk**: Session hangs, player confused  
**Solution**:

1. **Start timeout task**: `plugin.schedule(delay=120*20)` (ticks)
2. **Task runs**: Check if session still active
3. **If active**:
   - Remove from activeSessions
   - Send "Session timed out. Type /account create to restart"
   - Clear data
4. **Result**: Clear UX, player can retry

**Code**:
```java
private void startTimeoutTask(Player player, ChatCaptureSession session) {
    plugin.getServer().getScheduler().scheduleSyncDelayedTask(
        plugin,
        () -> {
            ChatCaptureSession current = activeSessions.get(player.getUniqueId());
            if (current == session) {  // Same session (not already completed)
                cancelSession(player.getUniqueId());
                player.sendMessage("Session timed out");
            }
        },
        config.chatCaptureTimeoutSeconds() * 20L  // Convert seconds to ticks
    );
}
```

### Edge Case 5: Email Already In Use

**Scenario**: Player tries /account create with email from another account  
**Risk**: API returns 409 Conflict, user confused  
**Solution**:

1. **createUser() call**: Backend returns 409 with error message
2. **UserAccountApiImpl**: Catches HTTP 409, throws `ApiException` with message
3. **onComplete callback**: Try-catch wraps this
4. **On error**: Send "Email already in use. Use /account link to connect your accounts."
5. **Result**: Clear guidance to user

### Edge Case 6: Network Error Mid-Capture

**Scenario**: Wifi drops while capturing password  
**Risk**: Incomplete session, data inconsistency  
**Solution**:

1. **Timeout**: Session expires after 120 sec (no input)
2. **Cleanup**: Session removed from activeSessions
3. **Result**: Safe state (nothing persisted yet)
4. **Player**: Can reconnect and retry /account create

---

## Frontend-Plugin Coordination

### Link Code Flow (Cross-System)

**Sequence**:
1. **Player on web app**: Clicks "Link Game Account" button
2. **Web app**: Shows "Enter your in-game username: ___"
3. **Web app**: Calls `POST /api/users/generate-link-code` → gets code "ABC-123"
4. **Web app**: Shows to user: "Your code: ABC-123 (expires in 20 min)"
5. **Player in-game**: Runs `/account link ABC-123`
6. **Plugin**: Calls `userAccountApi.linkAccount(code=ABC-123)`
7. **Backend**: Validates code, links accounts
8. **Plugin**: Updates cache, shows "Accounts linked!"
9. **Web app**: On next sync, sees merged data

### Account Merge: Web App Awareness

**Note**: Web app DOES NOT know about duplicates (that's a Minecraft-only issue due to UUID collision).

**Merge flow exists entirely in plugin**:
1. checkDuplicate() detects conflict (Minecraft account + web account with same username)
2. Player runs `/account merge`
3. ChatCapture shows "Keep A) Web account (100 coins) or B) Minecraft (0 coins)?"
4. Player chooses
5. Backend merges, returns unified account
6. Cache updated locally
7. Web app sees merged data on next login

---

## Thread Safety & Concurrency

### Thread Model

| Component | Thread(s) | Why |
|-----------|-----------|-----|
| AsyncPlayerPreLoginEvent | Async (Bukkit) | For blocking API calls |
| PlayerJoinEvent | Main | Safe to display messages |
| PlayerQuitEvent | Main | Safe to cleanup |
| AsyncPlayerChatEvent | Async (Bukkit) | For capturing input |
| PlayerJoinListener | Main | Bukkit requirement |
| ChatCaptureListener | Main (if sync) or Async (if async) | Depends on registration |
| Command execution | Main | Commands run on main thread |
| UserManager.cache | ConcurrentHashMap | Thread-safe concurrent access |
| ChatCaptureManager.sessions | ConcurrentHashMap | Thread-safe concurrent access |

### Race Condition: Join During Chat Capture

**Scenario**: Player runs /account create, starts capture, quits, rejoins while timeout pending

**Timeline**:
- T=0: Player runs `/account create` (main thread)
- T=1: ChatCaptureSession created, added to activeSessions
- T=2: Timeout task scheduled (will fire at T+120)
- T=5: Player quits
- T=6: PlayerQuitEvent fires, calls cancelSession (removes from map, cancels task)
- T=10: Player rejoins
- T=11: PlayerJoinListener fires, creates NEW UserManager data
- T=120: Timeout task fires, checks if session exists - NO (was removed), does nothing

**Result**: Safe - timeout task checks session identity before firing

### Race Condition: Two APIcalls for Same User

**Scenario**: Two concurrent requests update cache

**Timeline**:
- T=0: userAccountApi.createUser() returns (async)
- T=1: update cache: userCache.put(uuid, data1)
- T=0: Another thread: userAccountApi.updateEmail() returns (async)
- T=1: update cache: userCache.put(uuid, data2)

**Result**: Last write wins (ConcurrentHashMap is atomic put)  
**Mitigation**: 
- Apply updates in order (use CompletableFuture.thenApply chaining)
- Or version-check before updating (include timestamp in cache)

### Safe Practices

✅ **DO**:
- Use `ConcurrentHashMap` for shared mutable state
- Use `CompletableFuture` for async operations
- Wrap with try-catch for error handling
- Log all exceptions (don't silently fail)

❌ **DON'T**:
- Share `HashMap` across threads (not thread-safe)
- Block on main thread (will freeze server)
- Assume single-threaded execution (Bukkit has multiple threads)

---

## Configuration Error Handling

### Missing Configuration

**Scenario**: config.yml missing `account` section  
**Handling**:

```java
public static AccountConfig load(ConfigurationSection config) {
    if (config == null) {
        logger.warning("No 'account' section in config.yml, using defaults");
        return defaultConfig();
    }
    
    int expiryMinutes = config.getInt("link-code-expiry-minutes", 20);
    int timeoutSeconds = config.getInt("chat-capture-timeout-seconds", 120);
    
    AccountConfig cfg = new AccountConfig(expiryMinutes, timeoutSeconds);
    cfg.validate();  // Throws if invalid
    return cfg;
}
```

### Invalid Configuration Values

**Scenario**: `link-code-expiry-minutes: -5`  
**Handling**:

```java
public void validate() {
    if (linkCodeExpiryMinutes <= 0) {
        throw new IllegalArgumentException(
            "account.link-code-expiry-minutes must be positive (got: " + 
            linkCodeExpiryMinutes + ")"
        );
    }
}
```

**onEnable() catches this**:

```java
try {
    config = ConfigLoader.load(getConfig());
} catch (IllegalArgumentException ex) {
    getLogger().severe("Configuration error: " + ex.getMessage());
    getLogger().severe("Plugin will not enable");
    setEnabled(false);  // Disable plugin
    return;
}
```

---

**Document Version**: 1.0  
**Last Updated**: January 29, 2026  
**Status**: Detailed reference for implementation
