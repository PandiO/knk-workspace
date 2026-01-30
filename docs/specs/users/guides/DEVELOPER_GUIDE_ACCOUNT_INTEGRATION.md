# Knights & Kings - Developer Guide: Account Integration

**Version**: 1.0  
**Last Updated**: January 30, 2026  
**Plugin**: knk-plugin-v2  
**Target Audience**: Plugin developers, contributors

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Module Structure](#module-structure)
3. [API Client Usage](#api-client-usage)
4. [User Manager](#user-manager)
5. [Chat Capture System](#chat-capture-system)
6. [Command Implementation](#command-implementation)
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
│  /account | /account create | /account link                     │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                     Business Logic Layer                        │
│  UserManager | ChatCaptureManager                               │
└────────────────────────┬────────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────────┐
│                     API Client Layer                            │
│  UserApiClient (HTTP communication)                             │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTPS
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Backend API (knk-web-api-v2)                │
│  UserController | UserService | UserRepository                  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Design Principles

1. **Separation of Concerns**: API client, business logic, and UI are separated
2. **Async Operations**: All API calls use Kotlin coroutines (suspend functions)
3. **Caching**: User data is cached in-memory during player sessions
4. **Security**: Sensitive input captured securely (chat events cancelled)
5. **Error Handling**: Graceful degradation with user-friendly messages

---

## Module Structure

### knk-api-client

**Purpose**: HTTP client for backend API communication

**Package Structure**:
```
knk-api-client/
├── src/main/kotlin/com/mortisdevelopment/knk/api/
│   ├── client/
│   │   ├── UserApiClient.kt          # Main API client
│   │   └── BaseApiClient.kt          # Shared HTTP logic
│   └── models/
│       ├── UserDto.kt                # User-related DTOs
│       ├── LinkCodeDto.kt            # Link code DTOs
│       └── AccountManagementDto.kt   # Merge/duplicate DTOs
└── build.gradle.kts
```

**Dependencies**:
```kotlin
dependencies {
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.google.code.gson:gson:2.10.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
}
```

---

### knk-paper

**Purpose**: Bukkit/Paper plugin implementation

**Package Structure**:
```
knk-paper/
├── src/main/kotlin/com/mortisdevelopment/knk/paper/
│   ├── user/
│   │   ├── UserManager.kt            # Session cache + sync
│   │   └── PlayerUserData.kt         # Data class
│   ├── chat/
│   │   ├── ChatCaptureManager.kt     # Input capture
│   │   └── ChatCaptureSession.kt     # Session state
│   ├── command/
│   │   ├── AccountCommand.kt         # /account
│   │   ├── AccountCreateCommand.kt   # /account create
│   │   └── AccountLinkCommand.kt     # /account link
│   ├── listener/
│   │   ├── PlayerJoinListener.kt     # Join event
│   │   └── ChatCaptureListener.kt    # Chat event
│   ├── config/
│   │   └── KnkConfig.kt              # Config data classes
│   └── KnkPlugin.kt                  # Main plugin class
└── src/main/resources/
    ├── plugin.yml
    └── config.yml
```

---

## API Client Usage

### UserApiClient

**Location**: `knk-api-client/src/main/kotlin/com/mortisdevelopment/knk/api/client/UserApiClient.kt`

**Initialization**:
```kotlin
val apiClient = UserApiClient(
    baseUrl = "http://localhost:5000",
    apiKey = null // Optional for authenticated endpoints
)
```

### Available Methods

#### 1. Check for Duplicate Accounts

**Purpose**: Detect if a player has multiple accounts (by UUID + username)

```kotlin
suspend fun checkDuplicate(uuid: String, username: String): DuplicateCheckResponse
```

**Example**:
```kotlin
val result = apiClient.checkDuplicate(
    uuid = player.uniqueId.toString(),
    username = player.name
)

if (result.hasDuplicate) {
    println("Duplicate found!")
    println("Primary: ${result.primaryUser?.username}")
    println("Conflicting: ${result.conflictingUser?.username}")
}
```

**Response Model**:
```kotlin
data class DuplicateCheckResponse(
    val hasDuplicate: Boolean,
    val conflictingUser: UserResponse?,
    val primaryUser: UserResponse?,
    val message: String?
)
```

---

#### 2. Create User

**Purpose**: Create a minimal user (UUID + username)

```kotlin
suspend fun createUser(request: CreateUserRequest): UserResponse
```

**Example**:
```kotlin
val newUser = apiClient.createUser(
    CreateUserRequest(
        username = "Steve123",
        uuid = "a1b2c3d4-...",
        email = null, // Optional
        password = null // Optional
    )
)

println("Created user ID: ${newUser.id}")
```

**Request Model**:
```kotlin
data class CreateUserRequest(
    val username: String,
    val uuid: String? = null,
    val email: String? = null,
    val password: String? = null,
    val linkCode: String? = null
)
```

**Response Model**:
```kotlin
data class UserResponse(
    val id: Int,
    val username: String,
    val uuid: String?,
    val email: String?,
    val coins: Int,
    val gems: Int,
    val experiencePoints: Int,
    val emailVerified: Boolean,
    val accountCreatedVia: String
)
```

---

#### 3. Generate Link Code

**Purpose**: Generate a code for linking Minecraft → Web App

```kotlin
suspend fun generateLinkCode(userId: Int): LinkCodeResponse
```

**Example**:
```kotlin
val linkCode = apiClient.generateLinkCode(userId = 42)

println("Link code: ${linkCode.formattedCode}") // "ABC-123"
println("Expires at: ${linkCode.expiresAt}")
```

**Response Model**:
```kotlin
data class LinkCodeResponse(
    val code: String,              // "ABC123" (raw)
    val expiresAt: String,         // ISO 8601 timestamp
    val formattedCode: String      // "ABC-123" (formatted)
)
```

---

#### 4. Validate Link Code

**Purpose**: Check if a link code is valid before using it

```kotlin
suspend fun validateLinkCode(code: String): ValidateLinkCodeResponse
```

**Example**:
```kotlin
val validation = apiClient.validateLinkCode("ABC123")

if (validation.isValid) {
    println("Code belongs to: ${validation.username}")
    println("Email: ${validation.email}")
} else {
    println("Error: ${validation.error}")
}
```

**Response Model**:
```kotlin
data class ValidateLinkCodeResponse(
    val isValid: Boolean,
    val userId: Int?,
    val username: String?,
    val email: String?,
    val error: String?
)
```

---

#### 5. Update Email

**Purpose**: Add or change user's email address

```kotlin
suspend fun updateEmail(userId: Int, email: String): Boolean
```

**Example**:
```kotlin
val success = apiClient.updateEmail(
    userId = 42,
    email = "steve@example.com"
)

if (success) {
    println("Email updated!")
}
```

---

#### 6. Change Password

**Purpose**: Set or update user's password

```kotlin
suspend fun changePassword(userId: Int, request: ChangePasswordRequest): Boolean
```

**Example**:
```kotlin
val success = apiClient.changePassword(
    userId = 42,
    request = ChangePasswordRequest(
        currentPassword = "", // Empty for first-time setup
        newPassword = "MySecurePass123",
        passwordConfirmation = "MySecurePass123"
    )
)
```

**Request Model**:
```kotlin
data class ChangePasswordRequest(
    val currentPassword: String,
    val newPassword: String,
    val passwordConfirmation: String
)
```

---

#### 7. Merge Accounts

**Purpose**: Combine two duplicate accounts into one

```kotlin
suspend fun mergeAccounts(primaryId: Int, secondaryId: Int): UserResponse
```

**Example**:
```kotlin
val merged = apiClient.mergeAccounts(
    primaryId = 42,   // Account to keep
    secondaryId = 99  // Account to delete
)

println("Merged account now has:")
println("  Coins: ${merged.coins}")
println("  Gems: ${merged.gems}")
println("  XP: ${merged.experiencePoints}")
```

---

#### 8. Link Account

**Purpose**: Link accounts using a link code (Web App → Minecraft)

```kotlin
suspend fun linkAccount(request: LinkAccountRequest): UserResponse
```

**Example**:
```kotlin
val linked = apiClient.linkAccount(
    LinkAccountRequest(
        linkCode = "ABC123",
        email = "steve@example.com",
        password = "MyPass123",
        passwordConfirmation = "MyPass123"
    )
)
```

**Request Model**:
```kotlin
data class LinkAccountRequest(
    val linkCode: String,
    val email: String,
    val password: String,
    val passwordConfirmation: String
)
```

---

### Error Handling

**All API methods throw exceptions on failure**:

```kotlin
try {
    val user = apiClient.createUser(request)
} catch (e: IOException) {
    // Network error (server unreachable)
    logger.severe("Network error: ${e.message}")
} catch (e: HttpException) {
    // HTTP error (4xx, 5xx)
    logger.severe("API error ${e.code}: ${e.message}")
} catch (e: Exception) {
    // Other errors
    logger.severe("Unexpected error: ${e.message}")
}
```

**Custom Exception**:
```kotlin
class HttpException(
    val code: Int,
    message: String
) : Exception("HTTP $code: $message")
```

---

## User Manager

**Location**: `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/user/UserManager.kt`

**Purpose**: 
- Cache user data during player sessions
- Handle player join sync
- Detect and manage duplicate accounts

### Class Structure

```kotlin
class UserManager(
    private val plugin: KnkPlugin,
    private val apiClient: UserApiClient
) {
    private val userCache = mutableMapOf<UUID, PlayerUserData>()
    
    suspend fun onPlayerJoin(player: Player): PlayerUserData
    fun getCachedUser(uuid: UUID): PlayerUserData?
    fun updateCachedUser(uuid: UUID, data: PlayerUserData)
    fun removeUser(uuid: UUID)
}
```

### PlayerUserData Model

```kotlin
data class PlayerUserData(
    val userId: Int,
    val username: String,
    val uuid: UUID,
    val email: String?,
    val coins: Int,
    val gems: Int,
    val experiencePoints: Int,
    val hasEmailLinked: Boolean,
    val hasDuplicateAccount: Boolean = false,
    val conflictingUserId: Int? = null
)
```

### Usage Example

```kotlin
// In PlayerJoinListener
@EventHandler
fun onPlayerJoin(event: PlayerJoinEvent) {
    val player = event.player
    
    plugin.launch {
        try {
            val userData = userManager.onPlayerJoin(player)
            
            if (userData.hasDuplicateAccount) {
                player.sendMessage("You have two accounts! Use /account merge")
            }
        } catch (e: Exception) {
            logger.severe("Failed to sync user: ${e.message}")
        }
    }
}
```

### Cache Lifecycle

1. **Created**: On `PlayerJoinEvent` (async API call)
2. **Updated**: When user runs `/account create` or `/account link`
3. **Cleared**: On `PlayerQuitEvent` (memory cleanup)

**Example**:
```kotlin
// Plugin cleanup
@EventHandler
fun onPlayerQuit(event: PlayerQuitEvent) {
    userManager.removeUser(event.player.uniqueId)
    chatCaptureManager.cancelSession(event.player)
}
```

---

## Chat Capture System

**Location**: `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/chat/ChatCaptureManager.kt`

**Purpose**: Securely capture sensitive input (email, password) without broadcasting to other players

### How It Works

1. Player runs `/account create`
2. ChatCaptureManager creates a session for that player
3. ChatCaptureListener intercepts all chat events from that player
4. Events are **cancelled** (not broadcast)
5. Input is validated and stored in session
6. When flow completes, callback is invoked

### ChatCaptureSession Model

```kotlin
enum class CaptureStep {
    EMAIL,
    PASSWORD,
    PASSWORD_CONFIRM,
    ACCOUNT_CHOICE // For merge scenario
}

enum class CaptureFlow {
    ACCOUNT_CREATE,
    ACCOUNT_MERGE
}

data class ChatCaptureSession(
    val playerId: UUID,
    val flow: CaptureFlow,
    var currentStep: CaptureStep,
    val startTime: Long = System.currentTimeMillis(),
    val data: MutableMap<String, String> = mutableMapOf(),
    var onComplete: suspend (Map<String, String>) -> Unit = {},
    var onCancel: suspend () -> Unit = {}
)
```

### Starting a Flow

**Account Creation Flow**:
```kotlin
chatCaptureManager.startAccountCreateFlow(
    player = player,
    onComplete = { email, password ->
        // Handle account creation
        apiClient.updateEmail(userId, email)
        apiClient.changePassword(userId, ChangePasswordRequest(
            currentPassword = "",
            newPassword = password,
            passwordConfirmation = password
        ))
        player.sendMessage("Account created!")
    },
    onCancel = {
        player.sendMessage("Cancelled.")
    }
)
```

**Merge Flow**:
```kotlin
chatCaptureManager.startMergeFlow(
    player = player,
    accountA = userResponseA,
    accountB = userResponseB,
    onComplete = { choice ->
        val primaryId = if (choice == "A") accountA.id else accountB.id
        val secondaryId = if (choice == "A") accountB.id else accountA.id
        
        val merged = apiClient.mergeAccounts(primaryId, secondaryId)
        player.sendMessage("Merge complete!")
    },
    onCancel = {
        player.sendMessage("Merge cancelled.")
    }
)
```

### Chat Event Listener

**Location**: `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/listener/ChatCaptureListener.kt`

```kotlin
class ChatCaptureListener(
    private val captureManager: ChatCaptureManager
) : Listener {
    
    @EventHandler(priority = EventPriority.LOWEST)
    suspend fun onAsyncPlayerChat(event: AsyncPlayerChatEvent) {
        if (captureManager.isCapturingChat(event.player.uniqueId)) {
            event.isCancelled = true // CRITICAL: Prevent broadcast
            captureManager.handleChatInput(event.player, event.message)
        }
    }
}
```

### Validation

**Email Validation**:
```kotlin
private fun isValidEmail(email: String): Boolean {
    return email.matches(
        Regex("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\$")
    )
}
```

**Password Validation**:
```kotlin
if (input.length < 8) {
    player.sendMessage("Password must be at least 8 characters.")
    return
}
```

### Timeout Protection

```kotlin
private fun startTimeoutTask(player: Player) {
    plugin.schedule(delay = config.account.chatCaptureTimeoutSeconds * 20L) {
        if (activeSessions.containsKey(player.uniqueId)) {
            player.sendMessage("Input timeout. Please start over.")
            cancelSession(player)
        }
    }
}
```

---

## Command Implementation

### Base Command Structure

All account commands follow this pattern:

```kotlin
class AccountCommand(
    private val plugin: KnkPlugin,
    private val userManager: UserManager,
    private val config: KnkConfig
) : CommandExecutor {
    
    override fun onCommand(
        sender: CommandSender,
        command: Command,
        label: String,
        args: Array<out String>
    ): Boolean {
        if (sender !is Player) {
            sender.sendMessage("Only players can use this command")
            return true
        }
        
        // Get cached user data
        val userData = userManager.getCachedUser(sender.uniqueId) ?: run {
            sender.sendMessage("${config.messages.prefix}&cPlease rejoin and try again")
            return true
        }
        
        // Command logic...
        
        return true
    }
}
```

### Registration

**In plugin.yml**:
```yaml
commands:
  account:
    description: View your account status
    usage: /account
    aliases: [acc]
    permission: knk.account.view
  accountcreate:
    description: Create account with email and password
    usage: /account create
    permission: knk.account.create
  accountlink:
    description: Generate or use link code
    usage: /account link [code]
    permission: knk.account.link
```

**In KnkPlugin.kt**:
```kotlin
override fun onEnable() {
    // ... initialization ...
    
    // Register commands
    getCommand("account")?.setExecutor(AccountCommand(this, userManager, config))
    getCommand("accountcreate")?.setExecutor(AccountCreateCommand(
        plugin = this,
        userManager = userManager,
        chatCaptureManager = chatCaptureManager,
        apiClient = apiClient,
        config = config
    ))
    getCommand("accountlink")?.setExecutor(AccountLinkCommand(
        plugin = this,
        userManager = userManager,
        chatCaptureManager = chatCaptureManager,
        apiClient = apiClient,
        config = config
    ))
}
```

---

## Event Listeners

### PlayerJoinListener

**Purpose**: Sync user data when player joins

```kotlin
class PlayerJoinListener(
    private val plugin: KnkPlugin,
    private val userManager: UserManager,
    private val config: KnkConfig
) : Listener {
    
    @EventHandler(priority = EventPriority.HIGH)
    fun onPlayerJoin(event: PlayerJoinEvent) {
        val player = event.player
        
        plugin.launch {
            try {
                val userData = userManager.onPlayerJoin(player)
                
                // Show account status
                when {
                    userData.hasDuplicateAccount -> {
                        player.sendMessage("${config.messages.prefix}${config.messages.duplicateAccount}")
                    }
                    !userData.hasEmailLinked -> {
                        player.sendMessage("${config.messages.prefix}&eLink your account!")
                        player.sendMessage("${config.messages.prefix}&eUse &6/account create")
                    }
                    else -> {
                        player.sendMessage("${config.messages.prefix}&aWelcome back!")
                    }
                }
            } catch (e: Exception) {
                plugin.logger.severe("Failed to sync user ${player.name}: ${e.message}")
                player.sendMessage("${config.messages.prefix}&cFailed to sync account.")
            }
        }
    }
}
```

**Registration**:
```kotlin
override fun onEnable() {
    server.pluginManager.registerEvents(
        PlayerJoinListener(this, userManager, config),
        this
    )
}
```

---

## Configuration

**Location**: `knk-paper/src/main/resources/config.yml`

**Example**:
```yaml
api:
  base-url: "http://localhost:5000"
  timeout-seconds: 30
  retry-attempts: 3

account:
  link-code-expiry-minutes: 20
  chat-capture-timeout-seconds: 120

messages:
  prefix: "&8[&6KnK&8] &r"
  account-created: "&aAccount created! Link email on web app."
  account-linked: "&aYour accounts have been linked!"
  link-code-generated: "&aLink code: &6{code} &a({minutes}min)"
  invalid-link-code: "&cInvalid/expired code. Use &6/account link &cfor new one."
  duplicate-account: "&cTwo accounts found. Use &6/account merge &cto resolve."
  merge-complete: "&aMerge complete! {coins} coins, {gems} gems, {exp} XP."
```

### Config Data Classes

**Location**: `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/config/KnkConfig.kt`

```kotlin
data class KnkConfig(
    val api: ApiConfig,
    val account: AccountConfig,
    val messages: MessagesConfig
)

data class ApiConfig(
    val baseUrl: String,
    val timeoutSeconds: Int,
    val retryAttempts: Int
)

data class AccountConfig(
    val linkCodeExpiryMinutes: Int,
    val chatCaptureTimeoutSeconds: Int
)

data class MessagesConfig(
    val prefix: String,
    val accountCreated: String,
    val accountLinked: String,
    val linkCodeGenerated: String,
    val invalidLinkCode: String,
    val duplicateAccount: String,
    val mergeComplete: String
) {
    fun format(template: String, placeholders: Map<String, String>): String {
        var result = template
        for ((key, value) in placeholders) {
            result = result.replace("{$key}", value)
        }
        return result
    }
}
```

### Loading Config

```kotlin
override fun onEnable() {
    saveDefaultConfig()
    val config = loadConfig()
    
    // Use config...
}

private fun loadConfig(): KnkConfig {
    val configFile = File(dataFolder, "config.yml")
    val yaml = YamlConfiguration.loadConfiguration(configFile)
    
    return KnkConfig(
        api = ApiConfig(
            baseUrl = yaml.getString("api.base-url") ?: "http://localhost:5000",
            timeoutSeconds = yaml.getInt("api.timeout-seconds", 30),
            retryAttempts = yaml.getInt("api.retry-attempts", 3)
        ),
        account = AccountConfig(
            linkCodeExpiryMinutes = yaml.getInt("account.link-code-expiry-minutes", 20),
            chatCaptureTimeoutSeconds = yaml.getInt("account.chat-capture-timeout-seconds", 120)
        ),
        messages = MessagesConfig(
            prefix = yaml.getString("messages.prefix") ?: "&8[&6KnK&8] &r",
            accountCreated = yaml.getString("messages.account-created") ?: "&aAccount created!",
            accountLinked = yaml.getString("messages.account-linked") ?: "&aAccounts linked!",
            linkCodeGenerated = yaml.getString("messages.link-code-generated") ?: "&aCode: {code}",
            invalidLinkCode = yaml.getString("messages.invalid-link-code") ?: "&cInvalid code",
            duplicateAccount = yaml.getString("messages.duplicate-account") ?: "&cDuplicate found",
            mergeComplete = yaml.getString("messages.merge-complete") ?: "&aMerged!"
        )
    )
}
```

---

## Testing

### Unit Tests

**UserManager Test**:
```kotlin
class UserManagerTest {
    private lateinit var mockApiClient: UserApiClient
    private lateinit var userManager: UserManager
    
    @BeforeEach
    fun setup() {
        mockApiClient = mockk<UserApiClient>()
        userManager = UserManager(mockPlugin, mockApiClient)
    }
    
    @Test
    fun `onPlayerJoin creates new user when none exists`() = runBlocking {
        val player = mockk<Player> {
            every { uniqueId } returns UUID.randomUUID()
            every { name } returns "TestPlayer"
        }
        
        coEvery { 
            mockApiClient.checkDuplicate(any(), any()) 
        } returns DuplicateCheckResponse(
            hasDuplicate = false,
            primaryUser = null,
            conflictingUser = null,
            message = null
        )
        
        coEvery {
            mockApiClient.createUser(any())
        } returns UserResponse(
            id = 1,
            username = "TestPlayer",
            uuid = player.uniqueId.toString(),
            email = null,
            coins = 0,
            gems = 0,
            experiencePoints = 0,
            emailVerified = false,
            accountCreatedVia = "minecraft"
        )
        
        val result = userManager.onPlayerJoin(player)
        
        assertEquals("TestPlayer", result.username)
        assertEquals(1, result.userId)
        assertFalse(result.hasDuplicateAccount)
    }
}
```

**ChatCaptureManager Test**:
```kotlin
class ChatCaptureManagerTest {
    private lateinit var captureManager: ChatCaptureManager
    
    @BeforeEach
    fun setup() {
        captureManager = ChatCaptureManager(mockPlugin, mockConfig)
    }
    
    @Test
    fun `email validation accepts valid emails`() {
        assertTrue(captureManager.isValidEmail("test@example.com"))
        assertTrue(captureManager.isValidEmail("user+tag@domain.co.uk"))
    }
    
    @Test
    fun `email validation rejects invalid emails`() {
        assertFalse(captureManager.isValidEmail("invalid"))
        assertFalse(captureManager.isValidEmail("@domain.com"))
        assertFalse(captureManager.isValidEmail("user@"))
    }
    
    @Test
    fun `account create flow progresses through steps`() = runBlocking {
        val player = mockk<Player>(relaxed = true)
        var completed = false
        
        captureManager.startAccountCreateFlow(
            player = player,
            onComplete = { email, password ->
                assertEquals("test@example.com", email)
                assertEquals("password123", password)
                completed = true
            },
            onCancel = {}
        )
        
        // Simulate user input
        captureManager.handleChatInput(player, "test@example.com")
        captureManager.handleChatInput(player, "password123")
        captureManager.handleChatInput(player, "password123")
        
        assertTrue(completed)
    }
}
```

---

## Best Practices

### 1. Always Use Coroutines for API Calls

**❌ Don't** (blocks main thread):
```kotlin
val user = apiClient.createUser(request) // BAD
```

**✅ Do** (async):
```kotlin
plugin.launch {
    try {
        val user = apiClient.createUser(request)
        // Handle success
    } catch (e: Exception) {
        // Handle error
    }
}
```

---

### 2. Cache User Data Efficiently

**❌ Don't** (repeated API calls):
```kotlin
fun onCommand(...) {
    val user = apiClient.getUser(playerId) // BAD: API call every command
}
```

**✅ Do** (use cache):
```kotlin
fun onCommand(...) {
    val user = userManager.getCachedUser(player.uniqueId) ?: run {
        player.sendMessage("Please rejoin")
        return
    }
}
```

---

### 3. Handle Errors Gracefully

**❌ Don't** (silent failure):
```kotlin
try {
    apiClient.createUser(request)
} catch (e: Exception) {
    // Do nothing
}
```

**✅ Do** (log and inform):
```kotlin
try {
    apiClient.createUser(request)
} catch (e: Exception) {
    logger.severe("Failed to create user: ${e.message}")
    player.sendMessage("Account service unavailable. Try again later.")
}
```

---

### 4. Validate Input

**❌ Don't** (no validation):
```kotlin
chatCaptureManager.startAccountCreateFlow(...)
// User inputs "invalid-email" → crashes later
```

**✅ Do** (validate before processing):
```kotlin
when (session.currentStep) {
    CaptureStep.EMAIL -> {
        if (!isValidEmail(input)) {
            player.sendMessage("Invalid email format")
            return
        }
        // Continue...
    }
}
```

---

### 5. Clean Up Resources

**❌ Don't** (memory leak):
```kotlin
// User logs out, session stays in memory forever
```

**✅ Do** (cleanup on quit):
```kotlin
@EventHandler
fun onPlayerQuit(event: PlayerQuitEvent) {
    userManager.removeUser(event.player.uniqueId)
    chatCaptureManager.cancelSession(event.player)
}
```

---

## Troubleshooting

### Issue: Chat events not being captured

**Symptom**: User's email/password is broadcast to other players

**Cause**: ChatCaptureListener not registered or wrong event priority

**Solution**:
1. Verify listener is registered in `KnkPlugin.onEnable()`:
   ```kotlin
   server.pluginManager.registerEvents(ChatCaptureListener(chatCaptureManager), this)
   ```
2. Ensure event priority is `LOWEST`:
   ```kotlin
   @EventHandler(priority = EventPriority.LOWEST)
   ```

---

### Issue: API calls timeout

**Symptom**: `IOException: timeout` or `SocketTimeoutException`

**Cause**: Backend API is slow or unreachable

**Solution**:
1. Increase timeout in config:
   ```yaml
   api:
     timeout-seconds: 60
   ```
2. Check backend API is running
3. Check network connectivity

---

### Issue: User data not syncing on join

**Symptom**: `/account` shows "Please rejoin"

**Cause**: `onPlayerJoin` failed or exception was thrown

**Solution**:
1. Check server logs for exceptions
2. Verify API client is initialized:
   ```kotlin
   override fun onEnable() {
       this.apiClient = UserApiClient(config.api.baseUrl)
       this.userManager = UserManager(this, apiClient)
       // ...
   }
   ```
3. Add debug logging:
   ```kotlin
   logger.info("Syncing user ${player.name}...")
   val userData = userManager.onPlayerJoin(player)
   logger.info("User synced: ${userData.userId}")
   ```

---

### Issue: Link codes always invalid

**Symptom**: "This code is invalid or has expired"

**Cause**: Code format mismatch or timestamp issue

**Solution**:
1. Strip formatting when sending to API:
   ```kotlin
   val rawCode = code.replace("-", "") // "ABC-123" → "ABC123"
   apiClient.validateLinkCode(rawCode)
   ```
2. Check system time is synchronized (NTP)
3. Verify backend expiry logic matches plugin config

---

## Code Examples

### Complete Command Implementation

**AccountCreateCommand.kt**:
```kotlin
package com.mortisdevelopment.knk.paper.command

import com.mortisdevelopment.knk.paper.KnkPlugin
import com.mortisdevelopment.knk.paper.user.UserManager
import com.mortisdevelopment.knk.paper.chat.ChatCaptureManager
import com.mortisdevelopment.knk.api.client.UserApiClient
import com.mortisdevelopment.knk.api.models.ChangePasswordRequest
import com.mortisdevelopment.knk.paper.config.KnkConfig
import kotlinx.coroutines.launch
import org.bukkit.command.Command
import org.bukkit.command.CommandExecutor
import org.bukkit.command.CommandSender
import org.bukkit.entity.Player

class AccountCreateCommand(
    private val plugin: KnkPlugin,
    private val userManager: UserManager,
    private val chatCaptureManager: ChatCaptureManager,
    private val apiClient: UserApiClient,
    private val config: KnkConfig
) : CommandExecutor {
    
    override fun onCommand(
        sender: CommandSender,
        command: Command,
        label: String,
        args: Array<out String>
    ): Boolean {
        if (sender !is Player) {
            sender.sendMessage("Only players can use this command")
            return true
        }
        
        val userData = userManager.getCachedUser(sender.uniqueId)
        if (userData == null) {
            sender.sendMessage("${config.messages.prefix}&cPlease rejoin and try again")
            return true
        }
        
        if (userData.hasEmailLinked) {
            sender.sendMessage("${config.messages.prefix}&cYou already have an email linked!")
            return true
        }
        
        chatCaptureManager.startAccountCreateFlow(
            player = sender,
            onComplete = { email, password ->
                handleAccountCreation(sender, userData.userId, email, password)
            },
            onCancel = {
                sender.sendMessage("${config.messages.prefix}&cAccount creation cancelled")
            }
        )
        
        return true
    }
    
    private fun handleAccountCreation(
        player: Player,
        userId: Int,
        email: String,
        password: String
    ) {
        plugin.launch {
            try {
                // Update email
                apiClient.updateEmail(userId, email)
                
                // Update password
                apiClient.changePassword(
                    userId = userId,
                    request = ChangePasswordRequest(
                        currentPassword = "",
                        newPassword = password,
                        passwordConfirmation = password
                    )
                )
                
                // Update cache
                val updatedData = userManager.getCachedUser(player.uniqueId)!!.copy(
                    email = email,
                    hasEmailLinked = true
                )
                userManager.updateCachedUser(player.uniqueId, updatedData)
                
                player.sendMessage("${config.messages.prefix}${config.messages.accountCreated}")
                
            } catch (e: Exception) {
                plugin.logger.severe("Failed to create account: ${e.message}")
                player.sendMessage("${config.messages.prefix}&cFailed to create account")
            }
        }
    }
}
```

---

## API Reference Summary

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `checkDuplicate()` | POST /api/users/check-duplicate | Detect duplicate accounts |
| `createUser()` | POST /api/users | Create minimal user |
| `generateLinkCode()` | POST /api/users/generate-link-code | Generate link code |
| `validateLinkCode()` | POST /api/users/validate-link-code/{code} | Validate link code |
| `updateEmail()` | PUT /api/users/{id}/update-email | Update user email |
| `changePassword()` | PUT /api/users/{id}/change-password | Change password |
| `mergeAccounts()` | POST /api/users/merge | Merge duplicate accounts |
| `linkAccount()` | POST /api/users/link-account | Link via link code |

---

## Further Reading

- **Backend API Documentation**: `/docs/specs/users/SPEC_USER_ACCOUNT_MANAGEMENT.md`
- **Plugin Architecture**: `/Repository/knk-plugin-v2/docs/ARCHITECTURE_AUDIT.md`
- **Frontend Integration**: `/docs/ai/frontend-auth/FRONTEND_USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md`
- **Git Conventions**: `/docs/GIT_COMMIT_CONVENTIONS.md`

---

**Questions or Issues?**  
File a GitHub issue or contact the development team.

**Happy coding!** 🚀
