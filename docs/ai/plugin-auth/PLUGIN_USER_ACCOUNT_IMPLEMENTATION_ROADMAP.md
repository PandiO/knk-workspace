# Minecraft Plugin: User Account Management Implementation Roadmap

**Status**: Planning  
**Created**: January 29, 2026  
**Plugin**: knk-plugin-v2 (Paper/Spigot)  
**Dependencies**: knk-web-api-v2 (✅ Complete), knk-web-app (In Progress)

---

## Overview

This document provides a step-by-step implementation plan for integrating user account management features into the Minecraft plugin. The plugin will enable players to:

1. Create accounts via `/account create` command (email + password)
2. Link existing web app accounts via `/account link` command
3. View account status via `/account` command
4. Automatically sync with the backend API on player join

**Backend API Status**: ✅ **COMPLETE** (All endpoints available)  
**Frontend Status**: 🔄 In Progress (Login/Registration UI)  
**Plugin Status**: ❌ **NOT STARTED**

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Minecraft Plugin (knk-plugin-v2)            │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Commands   │  │ Join Handler │  │ Chat Capture │         │
│  │ /account xxx │  │   (UUID +    │  │   (Secure    │         │
│  │              │  │   Username)  │  │    Input)    │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                 │                  │                  │
│         └─────────────────┴──────────────────┘                  │
│                           │                                     │
│                  ┌────────▼────────┐                            │
│                  │   API Client    │                            │
│                  │  (HTTP Client)  │                            │
│                  └────────┬────────┘                            │
└───────────────────────────┼─────────────────────────────────────┘
                            │ HTTPS
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Backend API (knk-web-api-v2)                │
│                                                                 │
│  POST   /api/users                        (Create user)        │
│  GET    /api/users/check-duplicate        (Detect conflicts)   │
│  POST   /api/users/generate-link-code     (Get link code)      │
│  POST   /api/users/validate-link-code     (Validate code)      │
│  PUT    /api/users/{id}/change-password   (Update password)    │
│  PUT    /api/users/{id}/update-email      (Update email)       │
│  POST   /api/users/merge                  (Merge accounts)     │
│  POST   /api/users/link-account           (Link via code)      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Foundation (API Client & Configuration)

### Priority: CRITICAL - Blocks all other work
### Estimated Effort: 6-8 hours

#### 1.1 Create API Client Infrastructure

**Module**: `knk-api-client` (already exists in knk-plugin-v2)

**Tasks**:
- [ ] Create `UserApiClient.kt` in `knk-api-client/src/main/kotlin/com/mortisdevelopment/knk/api/client/`
- [ ] Add HTTP client dependency (OkHttp or similar)
- [ ] Implement base API configuration (base URL, headers, auth)
- [ ] Add error handling and response parsing
- [ ] Add logging for API calls

**Files**:
- `knk-api-client/src/main/kotlin/com/mortisdevelopment/knk/api/client/UserApiClient.kt` (new)
- `knk-api-client/build.gradle.kts` (add OkHttp dependency)

**Dependencies to Add**:
```kotlin
// knk-api-client/build.gradle.kts
dependencies {
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.google.code.gson:gson:2.10.1")
}
```

**Example Structure**:
```kotlin
class UserApiClient(
    private val baseUrl: String,
    private val apiKey: String? = null
) {
    private val client = OkHttpClient()
    private val gson = Gson()
    
    suspend fun checkDuplicate(uuid: String, username: String): DuplicateCheckResponse
    suspend fun createUser(request: CreateUserRequest): UserResponse
    suspend fun generateLinkCode(userId: Int): LinkCodeResponse
    suspend fun validateLinkCode(code: String): ValidateLinkCodeResponse
    suspend fun updateEmail(userId: Int, email: String): Boolean
    suspend fun changePassword(userId: Int, request: ChangePasswordRequest): Boolean
    suspend fun mergeAccounts(primaryId: Int, secondaryId: Int): UserResponse
    suspend fun linkAccount(request: LinkAccountRequest): UserResponse
}
```

**Effort**: 3-4 hours

---

#### 1.2 Create Data Models (DTOs)

**Module**: `knk-api-client`

**Tasks**:
- [ ] Create `models/` package
- [ ] Create request/response DTOs matching backend API
- [ ] Add Gson serialization annotations
- [ ] Add validation helpers

**Files to Create**:
- `knk-api-client/src/main/kotlin/com/mortisdevelopment/knk/api/models/UserDto.kt`
- `knk-api-client/src/main/kotlin/com/mortisdevelopment/knk/api/models/LinkCodeDto.kt`
- `knk-api-client/src/main/kotlin/com/mortisdevelopment/knk/api/models/AccountManagementDto.kt`

**DTOs to Implement**:
```kotlin
// UserDto.kt
data class CreateUserRequest(
    val username: String,
    val uuid: String? = null,
    val email: String? = null,
    val password: String? = null,
    val linkCode: String? = null
)

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

// LinkCodeDto.kt
data class LinkCodeResponse(
    val code: String,
    val expiresAt: String,
    val formattedCode: String
)

data class ValidateLinkCodeResponse(
    val isValid: Boolean,
    val userId: Int?,
    val username: String?,
    val email: String?,
    val error: String?
)

// AccountManagementDto.kt
data class DuplicateCheckResponse(
    val hasDuplicate: Boolean,
    val conflictingUser: UserResponse?,
    val primaryUser: UserResponse?,
    val message: String?
)

data class ChangePasswordRequest(
    val currentPassword: String,
    val newPassword: String,
    val passwordConfirmation: String
)

data class LinkAccountRequest(
    val linkCode: String,
    val email: String,
    val password: String,
    val passwordConfirmation: String
)

data class MergeAccountsRequest(
    val primaryUserId: Int,
    val secondaryUserId: Int
)
```

**Effort**: 2 hours

---

#### 1.3 Add Configuration

**Module**: `knk-paper`

**Tasks**:
- [ ] Add API configuration to `config.yml`
- [ ] Create configuration data class
- [ ] Add validation for required settings

**Files**:
- `knk-paper/src/main/resources/config.yml` (update)
- `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/config/KnkConfig.kt` (update)

**Configuration Structure**:
```yaml
# config.yml
api:
  base-url: "http://localhost:5000"
  timeout-seconds: 30
  retry-attempts: 3
  
account:
  link-code-expiry-minutes: 20
  chat-capture-timeout-seconds: 120
  
messages:
  prefix: "&8[&6KnK&8] &r"
  account-created: "&aAccount created successfully! You can now log in on the web app."
  account-linked: "&aYour accounts have been linked!"
  link-code-generated: "&aYour link code is: &6{code}&a. Use this code in the web app. Expires in {minutes} minutes."
  invalid-link-code: "&cThis code is invalid or has expired. Use &6/account link &cto get a new one."
  duplicate-account: "&cYou have two accounts. Please choose which one to keep."
  merge-complete: "&aAccount merge complete. Your account now has {coins} coins, {gems} gems, and {exp} XP."
```

**Effort**: 1 hour

---

### Phase 1 Summary
- **Total Effort**: 6-7 hours
- **Risk**: Low (standard HTTP client setup)
- **Deliverables**: 
  - API client with all 8 endpoints
  - Complete DTO models
  - Configuration setup

---

## Phase 2: Player Join Handler & User Sync

### Priority: HIGH - Core integration point
### Estimated Effort: 4-6 hours

#### 2.1 Create User Manager

**Module**: `knk-paper`

**Tasks**:
- [ ] Create `UserManager` class to cache player data
- [ ] Add sync logic on player join
- [ ] Handle duplicate detection
- [ ] Store user data in memory for session

**Files**:
- `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/user/UserManager.kt` (new)
- `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/user/PlayerUserData.kt` (new)

**Implementation**:
```kotlin
// PlayerUserData.kt
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

// UserManager.kt
class UserManager(
    private val plugin: KnkPlugin,
    private val apiClient: UserApiClient
) {
    private val userCache = mutableMapOf<UUID, PlayerUserData>()
    
    suspend fun onPlayerJoin(player: Player): PlayerUserData {
        // 1. Check for duplicate
        val duplicateCheck = apiClient.checkDuplicate(
            uuid = player.uniqueId.toString(),
            username = player.name
        )
        
        // 2. Handle duplicate scenario
        if (duplicateCheck.hasDuplicate) {
            return handleDuplicateAccount(player, duplicateCheck)
        }
        
        // 3. Create or retrieve user
        val userData = if (duplicateCheck.primaryUser != null) {
            mapToPlayerUserData(duplicateCheck.primaryUser)
        } else {
            createMinimalUser(player)
        }
        
        // 4. Cache and return
        userCache[player.uniqueId] = userData
        return userData
    }
    
    private suspend fun createMinimalUser(player: Player): PlayerUserData {
        val response = apiClient.createUser(
            CreateUserRequest(
                username = player.name,
                uuid = player.uniqueId.toString()
            )
        )
        return mapToPlayerUserData(response)
    }
    
    private fun handleDuplicateAccount(
        player: Player, 
        check: DuplicateCheckResponse
    ): PlayerUserData {
        // Mark as having conflict, will be handled by command
        return mapToPlayerUserData(check.primaryUser!!).copy(
            hasDuplicateAccount = true,
            conflictingUserId = check.conflictingUser?.id
        )
    }
    
    fun getCachedUser(uuid: UUID): PlayerUserData? = userCache[uuid]
    
    fun updateCachedUser(uuid: UUID, data: PlayerUserData) {
        userCache[uuid] = data
    }
}
```

**Effort**: 3 hours

---

#### 2.2 Create Player Join Listener

**Module**: `knk-paper`

**Tasks**:
- [ ] Create join event listener
- [ ] Call UserManager on join
- [ ] Show welcome message
- [ ] Prompt for account linking if needed

**Files**:
- `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/listener/PlayerJoinListener.kt` (new)

**Implementation**:
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
                        player.sendMessage("${config.messages.prefix}&eUse &6/account merge &eto resolve this.")
                    }
                    !userData.hasEmailLinked -> {
                        player.sendMessage("${config.messages.prefix}&eLink your account to access the web app!")
                        player.sendMessage("${config.messages.prefix}&eUse &6/account create &eor &6/account link")
                    }
                    else -> {
                        player.sendMessage("${config.messages.prefix}&aWelcome back, ${player.name}!")
                    }
                }
            } catch (e: Exception) {
                plugin.logger.severe("Failed to sync user ${player.name}: ${e.message}")
                player.sendMessage("${config.messages.prefix}&cFailed to sync account. Please contact an admin.")
            }
        }
    }
}
```

**Effort**: 2 hours

---

#### 2.3 Register Components

**Tasks**:
- [ ] Register UserManager in plugin
- [ ] Register listener
- [ ] Add dependency injection

**Files**:
- `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/KnkPlugin.kt` (update)

**Effort**: 1 hour

---

### Phase 2 Summary
- **Total Effort**: 6 hours
- **Risk**: Low (standard event handling)
- **Deliverables**:
  - User sync on join
  - Duplicate detection
  - User data caching

---

## Phase 3: Chat Capture System (Secure Input)

### Priority: CRITICAL - Required for /account create
### Estimated Effort: 6-8 hours

#### 3.1 Create Chat Capture Manager

**Module**: `knk-paper`

**Tasks**:
- [ ] Create chat capture system for sensitive input
- [ ] Support multi-step flows (email → password → confirm)
- [ ] Cancel events while capturing
- [ ] Timeout after inactivity
- [ ] Store encrypted input temporarily

**Files**:
- `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/chat/ChatCaptureManager.kt` (new)
- `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/chat/ChatCaptureSession.kt` (new)

**Implementation**:
```kotlin
// ChatCaptureSession.kt
enum class CaptureStep {
    EMAIL,
    PASSWORD,
    PASSWORD_CONFIRM,
    ACCOUNT_CHOICE // For merge scenario
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

enum class CaptureFlow {
    ACCOUNT_CREATE,
    ACCOUNT_MERGE
}

// ChatCaptureManager.kt
class ChatCaptureManager(
    private val plugin: KnkPlugin,
    private val config: KnkConfig
) {
    private val activeSessions = mutableMapOf<UUID, ChatCaptureSession>()
    
    fun startAccountCreateFlow(
        player: Player,
        onComplete: suspend (email: String, password: String) -> Unit,
        onCancel: suspend () -> Unit
    ) {
        val session = ChatCaptureSession(
            playerId = player.uniqueId,
            flow = CaptureFlow.ACCOUNT_CREATE,
            currentStep = CaptureStep.EMAIL,
            onComplete = { data ->
                onComplete(data["email"]!!, data["password"]!!)
            },
            onCancel = onCancel
        )
        
        activeSessions[player.uniqueId] = session
        
        // Send initial prompt
        player.sendMessage("${config.messages.prefix}&eStep 1/3: Enter your email address")
        player.sendMessage("${config.messages.prefix}&7(Type 'cancel' to abort)")
        
        // Start timeout task
        startTimeoutTask(player)
    }
    
    fun startMergeFlow(
        player: Player,
        accountA: UserResponse,
        accountB: UserResponse,
        onComplete: suspend (choice: String) -> Unit,
        onCancel: suspend () -> Unit
    ) {
        val session = ChatCaptureSession(
            playerId = player.uniqueId,
            flow = CaptureFlow.ACCOUNT_MERGE,
            currentStep = CaptureStep.ACCOUNT_CHOICE,
            onComplete = { data ->
                onComplete(data["choice"]!!)
            },
            onCancel = onCancel
        )
        
        activeSessions[player.uniqueId] = session
        
        // Display account comparison
        player.sendMessage("${config.messages.prefix}&6=== Account Merge Required ===")
        player.sendMessage("")
        player.sendMessage("&eAccount A:")
        player.sendMessage("  &7Coins: &a${accountA.coins} &7| Gems: &b${accountA.gems} &7| XP: &6${accountA.experiencePoints}")
        player.sendMessage("  &7Email: &f${accountA.email ?: "&cNot linked"}")
        player.sendMessage("")
        player.sendMessage("&eAccount B:")
        player.sendMessage("  &7Coins: &a${accountB.coins} &7| Gems: &b${accountB.gems} &7| XP: &6${accountB.experiencePoints}")
        player.sendMessage("  &7Email: &f${accountB.email ?: "&cNot linked"}")
        player.sendMessage("")
        player.sendMessage("${config.messages.prefix}&eType &6A &eor &6B &eto choose which account to keep")
    }
    
    suspend fun handleChatInput(player: Player, message: String): Boolean {
        val session = activeSessions[player.uniqueId] ?: return false
        
        // Check for cancel
        if (message.equals("cancel", ignoreCase = true)) {
            cancelSession(player)
            return true
        }
        
        when (session.flow) {
            CaptureFlow.ACCOUNT_CREATE -> handleAccountCreateInput(player, session, message)
            CaptureFlow.ACCOUNT_MERGE -> handleMergeInput(player, session, message)
        }
        
        return true // Event is cancelled
    }
    
    private suspend fun handleAccountCreateInput(
        player: Player, 
        session: ChatCaptureSession, 
        input: String
    ) {
        when (session.currentStep) {
            CaptureStep.EMAIL -> {
                if (!isValidEmail(input)) {
                    player.sendMessage("${config.messages.prefix}&cInvalid email format. Please try again.")
                    return
                }
                session.data["email"] = input
                session.currentStep = CaptureStep.PASSWORD
                player.sendMessage("${config.messages.prefix}&aEmail saved!")
                player.sendMessage("${config.messages.prefix}&eStep 2/3: Enter your password (min 8 characters)")
            }
            
            CaptureStep.PASSWORD -> {
                if (input.length < 8) {
                    player.sendMessage("${config.messages.prefix}&cPassword must be at least 8 characters. Try again.")
                    return
                }
                session.data["password"] = input
                session.currentStep = CaptureStep.PASSWORD_CONFIRM
                player.sendMessage("${config.messages.prefix}&aPassword saved!")
                player.sendMessage("${config.messages.prefix}&eStep 3/3: Confirm your password")
            }
            
            CaptureStep.PASSWORD_CONFIRM -> {
                if (input != session.data["password"]) {
                    player.sendMessage("${config.messages.prefix}&cPasswords don't match. Starting over...")
                    session.currentStep = CaptureStep.PASSWORD
                    session.data.remove("password")
                    player.sendMessage("${config.messages.prefix}&eStep 2/3: Enter your password (min 8 characters)")
                    return
                }
                
                // Complete
                completeSession(player, session)
            }
            
            else -> {}
        }
    }
    
    private suspend fun handleMergeInput(
        player: Player,
        session: ChatCaptureSession,
        input: String
    ) {
        when (input.uppercase()) {
            "A", "B" -> {
                session.data["choice"] = input.uppercase()
                completeSession(player, session)
            }
            else -> {
                player.sendMessage("${config.messages.prefix}&cPlease type 'A' or 'B'")
            }
        }
    }
    
    private suspend fun completeSession(player: Player, session: ChatCaptureSession) {
        activeSessions.remove(player.uniqueId)
        session.onComplete(session.data)
    }
    
    private suspend fun cancelSession(player: Player) {
        val session = activeSessions.remove(player.uniqueId) ?: return
        player.sendMessage("${config.messages.prefix}&cCancelled.")
        session.onCancel()
    }
    
    fun isCapturingChat(playerId: UUID): Boolean = activeSessions.containsKey(playerId)
    
    private fun isValidEmail(email: String): Boolean {
        return email.matches(Regex("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\$"))
    }
    
    private fun startTimeoutTask(player: Player) {
        plugin.schedule(delay = config.account.chatCaptureTimeoutSeconds * 20L) {
            if (activeSessions.containsKey(player.uniqueId)) {
                player.sendMessage("${config.messages.prefix}&cInput timeout. Please start over.")
                cancelSession(player)
            }
        }
    }
}
```

**Effort**: 4 hours

---

#### 3.2 Create Chat Event Listener

**Module**: `knk-paper`

**Tasks**:
- [ ] Intercept chat events
- [ ] Route to ChatCaptureManager if active
- [ ] Cancel event to prevent broadcast

**Files**:
- `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/listener/ChatCaptureListener.kt` (new)

**Implementation**:
```kotlin
class ChatCaptureListener(
    private val captureManager: ChatCaptureManager
) : Listener {
    
    @EventHandler(priority = EventPriority.LOWEST)
    suspend fun onAsyncPlayerChat(event: AsyncPlayerChatEvent) {
        if (captureManager.isCapturingChat(event.player.uniqueId)) {
            event.isCancelled = true
            captureManager.handleChatInput(event.player, event.message)
        }
    }
}
```

**Effort**: 1 hour

---

#### 3.3 Add Security Measures

**Tasks**:
- [ ] Clear sensitive data from memory after use
- [ ] Add timeout protection
- [ ] Log security events (failed attempts)

**Effort**: 1 hour

---

### Phase 3 Summary
- **Total Effort**: 6 hours
- **Risk**: Medium (chat interception timing)
- **Deliverables**:
  - Secure chat capture
  - Multi-step input flows
  - Timeout protection

---

## Phase 4: Commands Implementation

### Priority: HIGH - User-facing features
### Estimated Effort: 8-10 hours

#### 4.1 Implement /account create Command

**Module**: `knk-paper`

**Tasks**:
- [ ] Create command class
- [ ] Start chat capture flow
- [ ] Call API to update user
- [ ] Handle success/failure

**Files**:
- `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/command/AccountCreateCommand.kt` (new)

**Implementation**:
```kotlin
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
            sender.sendMessage("${config.messages.prefix}&cPlease rejoin the server and try again")
            return true
        }
        
        if (userData.hasEmailLinked) {
            sender.sendMessage("${config.messages.prefix}&cYou already have an email linked!")
            sender.sendMessage("${config.messages.prefix}&eUse &6/account &eto view your account")
            return true
        }
        
        // Start chat capture flow
        chatCaptureManager.startAccountCreateFlow(
            player = sender,
            onComplete = { email, password ->
                handleAccountCreation(sender, userData, email, password)
            },
            onCancel = {
                sender.sendMessage("${config.messages.prefix}&cAccount creation cancelled")
            }
        )
        
        return true
    }
    
    private suspend fun handleAccountCreation(
        player: Player,
        userData: PlayerUserData,
        email: String,
        password: String
    ) {
        try {
            // Update email
            apiClient.updateEmail(userData.userId, email)
            
            // Update password
            apiClient.changePassword(
                userId = userData.userId,
                request = ChangePasswordRequest(
                    currentPassword = "", // No current password for first-time setup
                    newPassword = password,
                    passwordConfirmation = password
                )
            )
            
            // Update cache
            val updatedData = userData.copy(hasEmailLinked = true)
            userManager.updateCachedUser(player.uniqueId, updatedData)
            
            player.sendMessage("${config.messages.prefix}${config.messages.accountCreated}")
            
        } catch (e: Exception) {
            plugin.logger.severe("Failed to create account for ${player.name}: ${e.message}")
            player.sendMessage("${config.messages.prefix}&cFailed to create account. Please try again later.")
        }
    }
}
```

**Effort**: 3 hours

---

#### 4.2 Implement /account link Command

**Module**: `knk-paper`

**Tasks**:
- [ ] Handle two scenarios: generate code OR consume code
- [ ] Generate link code (no args)
- [ ] Validate and consume link code (with arg)
- [ ] Handle merge conflicts

**Files**:
- `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/command/AccountLinkCommand.kt` (new)

**Implementation**:
```kotlin
class AccountLinkCommand(
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
        
        val userData = userManager.getCachedUser(sender.uniqueId) ?: run {
            sender.sendMessage("${config.messages.prefix}&cPlease rejoin the server and try again")
            return true
        }
        
        plugin.launch {
            when (args.size) {
                0 -> generateLinkCode(sender, userData)
                1 -> consumeLinkCode(sender, userData, args[0])
                else -> {
                    sender.sendMessage("${config.messages.prefix}&cUsage: /account link [code]")
                }
            }
        }
        
        return true
    }
    
    private suspend fun generateLinkCode(player: Player, userData: PlayerUserData) {
        try {
            val response = apiClient.generateLinkCode(userData.userId)
            
            player.sendMessage("${config.messages.prefix}&6=== Link Code ===")
            player.sendMessage("")
            player.sendMessage("  &e${response.formattedCode}")
            player.sendMessage("")
            player.sendMessage("${config.messages.prefix}&7Use this code in the web app to link your account")
            player.sendMessage("${config.messages.prefix}&7Expires in ${config.account.linkCodeExpiryMinutes} minutes")
            
        } catch (e: Exception) {
            plugin.logger.severe("Failed to generate link code for ${player.name}: ${e.message}")
            player.sendMessage("${config.messages.prefix}&cFailed to generate link code")
        }
    }
    
    private suspend fun consumeLinkCode(player: Player, userData: PlayerUserData, code: String) {
        try {
            val validation = apiClient.validateLinkCode(code)
            
            if (!validation.isValid) {
                player.sendMessage("${config.messages.prefix}${config.messages.invalidLinkCode}")
                return
            }
            
            // Check if this would create a duplicate
            val duplicateCheck = apiClient.checkDuplicate(
                uuid = player.uniqueId.toString(),
                username = player.name
            )
            
            if (duplicateCheck.hasDuplicate) {
                handleMergeConflict(player, duplicateCheck)
                return
            }
            
            // Link the account
            val linkedUser = apiClient.linkAccount(
                LinkAccountRequest(
                    linkCode = code,
                    email = validation.email ?: "",
                    password = "", // Already set in web app
                    passwordConfirmation = ""
                )
            )
            
            // Update cache
            val updatedData = userData.copy(
                email = linkedUser.email,
                hasEmailLinked = true
            )
            userManager.updateCachedUser(player.uniqueId, updatedData)
            
            player.sendMessage("${config.messages.prefix}${config.messages.accountLinked}")
            
        } catch (e: Exception) {
            plugin.logger.severe("Failed to consume link code for ${player.name}: ${e.message}")
            player.sendMessage("${config.messages.prefix}&cFailed to link account")
        }
    }
    
    private suspend fun handleMergeConflict(player: Player, check: DuplicateCheckResponse) {
        chatCaptureManager.startMergeFlow(
            player = player,
            accountA = check.primaryUser!!,
            accountB = check.conflictingUser!!,
            onComplete = { choice ->
                val primaryId = if (choice == "A") check.primaryUser.id else check.conflictingUser!!.id
                val secondaryId = if (choice == "A") check.conflictingUser!!.id else check.primaryUser.id
                
                mergeAccounts(player, primaryId, secondaryId)
            },
            onCancel = {
                player.sendMessage("${config.messages.prefix}&cMerge cancelled")
            }
        )
    }
    
    private suspend fun mergeAccounts(player: Player, primaryId: Int, secondaryId: Int) {
        try {
            val merged = apiClient.mergeAccounts(primaryId, secondaryId)
            
            val updatedData = userManager.getCachedUser(player.uniqueId)!!.copy(
                coins = merged.coins,
                gems = merged.gems,
                experiencePoints = merged.experiencePoints,
                hasDuplicateAccount = false,
                conflictingUserId = null
            )
            userManager.updateCachedUser(player.uniqueId, updatedData)
            
            player.sendMessage(
                "${config.messages.prefix}${config.messages.mergeComplete}"
                    .replace("{coins}", merged.coins.toString())
                    .replace("{gems}", merged.gems.toString())
                    .replace("{exp}", merged.experiencePoints.toString())
            )
            
        } catch (e: Exception) {
            plugin.logger.severe("Failed to merge accounts for ${player.name}: ${e.message}")
            player.sendMessage("${config.messages.prefix}&cFailed to merge accounts")
        }
    }
}
```

**Effort**: 4 hours

---

#### 4.3 Implement /account Command

**Module**: `knk-paper`

**Tasks**:
- [ ] Display current account status
- [ ] Show balances (coins, gems, XP)
- [ ] Show email link status

**Files**:
- `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/command/AccountCommand.kt` (new)

**Implementation**:
```kotlin
class AccountCommand(
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
        
        val userData = userManager.getCachedUser(sender.uniqueId) ?: run {
            sender.sendMessage("${config.messages.prefix}&cPlease rejoin the server and try again")
            return true
        }
        
        sender.sendMessage("${config.messages.prefix}&6=== Your Account ===")
        sender.sendMessage("")
        sender.sendMessage("  &eUsername: &f${userData.username}")
        sender.sendMessage("  &eUUID: &7${userData.uuid}")
        sender.sendMessage("  &eEmail: ${if (userData.hasEmailLinked) "&a${userData.email}" else "&cNot linked"}")
        sender.sendMessage("")
        sender.sendMessage("  &6Coins: &e${userData.coins}")
        sender.sendMessage("  &bGems: &3${userData.gems}")
        sender.sendMessage("  &dExperience: &5${userData.experiencePoints}")
        sender.sendMessage("")
        
        if (!userData.hasEmailLinked) {
            sender.sendMessage("  &7Use &6/account create &7or &6/account link &7to link email")
        }
        
        if (userData.hasDuplicateAccount) {
            sender.sendMessage("  &c⚠ Duplicate account detected!")
            sender.sendMessage("  &7Use &6/account link &7to resolve")
        }
        
        return true
    }
}
```

**Effort**: 1 hour

---

#### 4.4 Register Commands

**Tasks**:
- [ ] Register commands in plugin.yml
- [ ] Register command executors in plugin class

**Files**:
- `knk-paper/src/main/resources/plugin.yml` (update)
- `knk-paper/src/main/kotlin/com/mortisdevelopment/knk/paper/KnkPlugin.kt` (update)

**plugin.yml**:
```yaml
commands:
  account:
    description: View your account status
    usage: /account
    aliases: [acc]
  accountcreate:
    description: Create account with email and password
    usage: /account create
  accountlink:
    description: Generate or use link code
    usage: /account link [code]
```

**Effort**: 1 hour

---

### Phase 4 Summary
- **Total Effort**: 9 hours
- **Risk**: Medium (command logic + API integration)
- **Deliverables**:
  - /account create (interactive flow)
  - /account link (generate + consume)
  - /account (status display)
  - Account merge via chat UI

---

## Phase 5: Error Handling & Polish

### Priority: MEDIUM
### Estimated Effort: 4-6 hours

#### 5.1 Add Comprehensive Error Handling

**Tasks**:
- [ ] Add retry logic for API calls
- [ ] Handle network timeouts gracefully
- [ ] Show user-friendly error messages
- [ ] Log detailed errors for debugging

**Effort**: 2 hours

---

#### 5.2 Add Logging

**Tasks**:
- [ ] Log all API calls (debug level)
- [ ] Log account creations/merges (info level)
- [ ] Log errors (error level)
- [ ] Add performance metrics

**Effort**: 1 hour

---

#### 5.3 Add Permissions

**Tasks**:
- [ ] Create permission nodes
- [ ] Add permission checks to commands
- [ ] Document permissions

**Permissions**:
```yaml
permissions:
  knk.account.view:
    description: View account status
    default: true
  knk.account.create:
    description: Create account with email/password
    default: true
  knk.account.link:
    description: Link account with web app
    default: true
  knk.account.admin:
    description: Admin account management
    default: op
```

**Effort**: 1 hour

---

#### 5.4 Add Rate Limiting

**Tasks**:
- [ ] Prevent spam of /account create
- [ ] Limit link code generation frequency
- [ ] Add cooldowns

**Effort**: 2 hours

---

### Phase 5 Summary
- **Total Effort**: 6 hours
- **Risk**: Low
- **Deliverables**:
  - Error handling
  - Logging
  - Permissions
  - Rate limiting

---

## Phase 6: Testing

### Priority: HIGH - Ensures reliability
### Estimated Effort: 8-10 hours

#### 6.1 Unit Tests

**Tasks**:
- [ ] Test ChatCaptureManager flows
- [ ] Test UserManager caching
- [ ] Test email validation
- [ ] Test password validation (client-side)

**Files**:
- `knk-paper/src/test/kotlin/com/mortisdevelopment/knk/paper/chat/ChatCaptureManagerTest.kt`
- `knk-paper/src/test/kotlin/com/mortisdevelopment/knk/paper/user/UserManagerTest.kt`

**Effort**: 4 hours

---

#### 6.2 Integration Tests

**Tasks**:
- [ ] Test API client against real backend
- [ ] Test full /account create flow
- [ ] Test full /account link flow
- [ ] Test merge flow
- [ ] Test error scenarios

**Effort**: 4 hours

---

#### 6.3 Manual Testing Checklist

**Scenarios to Test**:
- [ ] Player joins (new account created)
- [ ] Player joins (existing account loaded)
- [ ] /account create with valid input
- [ ] /account create with invalid email
- [ ] /account create with weak password
- [ ] /account create timeout
- [ ] /account link (generate code)
- [ ] /account link {code} (link account)
- [ ] /account link {code} (duplicate detected)
- [ ] Account merge (choose A)
- [ ] Account merge (choose B)
- [ ] /account (display status)
- [ ] Network error handling
- [ ] API timeout handling

**Effort**: 2 hours

---

### Phase 6 Summary
- **Total Effort**: 10 hours
- **Risk**: Low
- **Deliverables**:
  - Unit tests
  - Integration tests
  - Manual test results

---

## Phase 7: Documentation

### Priority: MEDIUM
### Estimated Effort: 3-4 hours

#### 7.1 Player Documentation

**Tasks**:
- [ ] Create player guide (markdown)
- [ ] Document all commands with examples
- [ ] Create troubleshooting section

**Files**:
- `Repository/knk-plugin-v2/docs/PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md` (new)

**Effort**: 2 hours

---

#### 7.2 Developer Documentation

**Tasks**:
- [ ] Document API client usage
- [ ] Document chat capture system
- [ ] Add code examples

**Files**:
- `Repository/knk-plugin-v2/docs/DEVELOPER_GUIDE_ACCOUNT_INTEGRATION.md` (new)

**Effort**: 2 hours

---

### Phase 7 Summary
- **Total Effort**: 4 hours
- **Risk**: Low
- **Deliverables**:
  - Player guide
  - Developer guide

---

## Implementation Priority Matrix

| Phase | Component | Duration | Risk | Blocker | Priority |
|-------|-----------|----------|------|---------|----------|
| 1 | API Client & Config | 6-8h | Low | None | CRITICAL |
| 2 | Join Handler & Sync | 4-6h | Low | Phase 1 | HIGH |
| 3 | Chat Capture | 6-8h | Med | Phase 1 | CRITICAL |
| 4 | Commands | 8-10h | Med | Phase 1-3 | HIGH |
| 5 | Error Handling | 4-6h | Low | Phase 1-4 | MEDIUM |
| 6 | Testing | 8-10h | Low | Phase 1-5 | HIGH |
| 7 | Documentation | 3-4h | Low | Phase 1-6 | MEDIUM |

**Total Estimated Effort**: 39-52 hours (5-6.5 days)

---

## Recommended Timeline

### Week 1: Foundation (Phases 1-2)
- **Days 1-2**: API Client, DTOs, Configuration (Phase 1)
- **Days 3-4**: UserManager, Join Handler, Listener (Phase 2)
- **Day 5**: Integration testing of Phase 1-2

### Week 2: Core Features (Phases 3-4)
- **Days 1-2**: Chat Capture System (Phase 3)
- **Days 3-5**: Command Implementation (Phase 4)

### Week 3: Polish & Testing (Phases 5-7)
- **Days 1-2**: Error Handling, Logging, Permissions (Phase 5)
- **Days 3-4**: Testing (Phase 6)
- **Day 5**: Documentation (Phase 7)

---

## Dependencies

### Backend API Endpoints (✅ All Available)

| Endpoint | Status | Purpose |
|----------|--------|---------|
| `POST /api/users` | ✅ | Create minimal user (UUID + username) |
| `POST /api/users/check-duplicate` | ✅ | Detect account conflicts |
| `POST /api/users/generate-link-code` | ✅ | Generate link code |
| `POST /api/users/validate-link-code/{code}` | ✅ | Validate link code |
| `PUT /api/users/{id}/update-email` | ✅ | Update email |
| `PUT /api/users/{id}/change-password` | ✅ | Update password |
| `POST /api/users/merge` | ✅ | Merge duplicate accounts |
| `POST /api/users/link-account` | ✅ | Link via link code |

### External Dependencies (To Add)

```kotlin
// knk-api-client/build.gradle.kts
dependencies {
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.google.code.gson:gson:2.10.1")
    
    // Coroutines (if not already present)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-jdk8:1.7.3")
}
```

---

## Getting Started Checklist

- [ ] Review SPEC_USER_ACCOUNT_MANAGEMENT.md Part D (Minecraft requirements)
- [ ] Verify backend API is running and accessible
- [ ] Test backend endpoints with Postman/curl
- [ ] Set up development server for testing
- [ ] Configure test database
- [ ] Create feature branch: `feature/plugin-account-management`
- [ ] Begin Phase 1: API Client setup

---

## Success Criteria

### Functional Requirements ✅
- [ ] Players can create accounts via `/account create`
- [ ] Players can generate link codes via `/account link`
- [ ] Players can link web app accounts via `/account link {code}`
- [ ] Players can view account status via `/account`
- [ ] Players can resolve duplicate accounts via merge flow
- [ ] Account data syncs on player join
- [ ] Sensitive input captured securely (no chat broadcast)

### Non-Functional Requirements ✅
- [ ] All API calls have retry logic
- [ ] All errors logged appropriately
- [ ] All user-facing messages are clear and helpful
- [ ] All commands have permission checks
- [ ] All flows have timeout protection
- [ ] Rate limiting prevents abuse

### Testing Requirements ✅
- [ ] Unit tests pass (80%+ coverage)
- [ ] Integration tests pass
- [ ] Manual testing checklist complete
- [ ] No blocking bugs

---

## Future Enhancements (Out of MVP Scope)

- [ ] `/account password` - Change password in-game
- [ ] `/account email` - Change email in-game
- [ ] `/account delete` - Delete account (soft delete)
- [ ] GUI-based account creation (inventory UI)
- [ ] Email verification in-game
- [ ] 2FA support
- [ ] Account recovery flow
- [ ] Admin commands for account management

---

## Related Documentation

- **Backend Specification**: [docs/specs/users/SPEC_USER_ACCOUNT_MANAGEMENT.md](../../specs/users/SPEC_USER_ACCOUNT_MANAGEMENT.md)
- **Backend Roadmap**: [docs/specs/users/USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md](../../specs/users/USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md)
- **Frontend Roadmap**: [docs/ai/frontend-auth/FRONTEND_USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md](../frontend-auth/FRONTEND_USER_ACCOUNT_MANAGEMENT_IMPLEMENTATION_ROADMAP.md)
- **Plugin Architecture**: [Repository/knk-plugin-v2/docs/ARCHITECTURE_AUDIT.md](../../../Repository/knk-plugin-v2/docs/ARCHITECTURE_AUDIT.md)

---

**Document Version**: 1.0  
**Last Updated**: January 29, 2026  
**Ready to Start**: ✅ Yes (backend complete, frontend in progress)
