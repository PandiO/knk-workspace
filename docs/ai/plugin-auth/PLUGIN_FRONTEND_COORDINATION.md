# Plugin-Frontend Coordination Guide

**Purpose**: Show how knk-plugin-v2 and knk-web-app coordinate for user account management  
**Related**: 
- [PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md](PLUGIN_USER_ACCOUNT_IMPLEMENTATION_ROADMAP.md)
- [IMPLEMENTATION_DETAILS_AND_EDGE_CASES.md](IMPLEMENTATION_DETAILS_AND_EDGE_CASES.md)

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    Web Browser (knk-web-app)                   │
│                                                                 │
│  Login Screen ──→ Register ──→ Account Dashboard              │
│    │                 │              │                          │
│    │ (UUID)          │ (Email)      │ Link Game Account        │
│    │                 │              └─────┐                    │
│    └─────────────────┴─────────────────────┤                   │
│                                            │                   │
│                                            ▼                   │
│                               +────────────────────+            │
│                               │ Generate Link Code │            │
│                               │ Code: ABC-123      │            │
│                               │ Expires: 20 min    │            │
│                               +────────────────────+            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                                  │ HTTPS
                                  ▼
                        ┌──────────────────┐
                        │  Backend API     │
                        │  knk-web-api-v2  │
                        │                  │
                        │ POST /api/users  │
                        │ POST /api/users/ │
                        │ validate-link    │
                        │ ...              │
                        └──────────────────┘
                                  ▲
                                  │ HTTPS
                                  │
┌─────────────────────────────────┴─────────────────────────────────┐
│                      Minecraft Server (knk-plugin-v2)             │
│                                                                   │
│  Player joins → Auto-sync account via checkDuplicate             │
│     │                                                             │
│     │ Has duplicate?                                              │
│     ├─ YES: Show merge prompt                                     │
│     └─ NO: Show balance                                           │
│                                                                   │
│  /account create ──→ ChatCapture(email, password) ──→ API call  │
│                                                                   │
│  /account link ABC-123 ──→ Validate + Link ──→ Cache update      │
│                                                                   │
│  /account merge ──→ Choose account ──→ Merge in API ──→ Sync     │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

---

## Use Case 1: New Player - Create Account in Plugin

### Flow

```
Player (in game)
  │
  ├─ Runs: /account create
  │
  ├─ Plugin: Starts ChatCapture
  │   │
  │   ├─ Prompt: "Enter email:"
  │   ├─ Prompt: "Enter password:"
  │   ├─ Prompt: "Confirm password:"
  │   │
  │   └─ Calls: userAccountApi.createUser(email, password, uuid, username)
  │
  ├─ Backend: Creates user account
  │   │
  │   ├─ Stores: {email, uuid, username, password_hash}
  │   └─ Returns: UserResponse(id=123, ...)
  │
  ├─ Plugin: Caches user data
  │   └─ Message: "Account created! Email: me@example.com"
  │
  └─ Result: Player now has linked account
     ├─ In-game: Can view /account (shows email, balance)
     └─ Web app: Must login with email to see account
```

### Missing Pieces

**Question**: Should web app show newly created accounts automatically?

**Current behavior**:
1. Player creates account in-game
2. Web app does NOT automatically know
3. Player must login on web app with same email/password

**Potential issue**: 
- Player creates account in-game, goes to web app
- Sees "Login" screen (no auto-populate of email)
- Must remember email they just typed in game
- Bad UX if names differ

**Recommendation**: 
- Add optional **QR code** or **link code** to in-game message
- Show: "Or link on web app: knk.example.com/link/ABC-123"
- Web app landing page detects QR → auto-fills link code
- User still sets password on web app (extra security step)

---

## Use Case 2: Existing Web User - Link Game Account

### Flow (Detailed)

```
Player (on web app)
  │
  ├─ Clicks: "Link Minecraft Account"
  │
  ├─ Web app shows:
  │   ┌─────────────────────────────────────┐
  │   │ Link Your Game Account              │
  │   │                                     │
  │   │ Enter your in-game username:        │
  │   │ [___________________]               │
  │   │                                     │
  │   │ [Generate Code Button]              │
  │   └─────────────────────────────────────┘
  │
  ├─ Player types: "PlayerName123"
  │
  ├─ Clicks: "Generate Code"
  │
  ├─ Web app calls: POST /api/users/generate-link-code
  │   └─ Backend: Creates code "ABC-123", expires in 20 min
  │
  ├─ Web app displays:
  │   ┌─────────────────────────────────────┐
  │   │ Your Link Code:                     │
  │   │                                     │
  │   │    ABC-123                          │
  │   │                                     │
  │   │ Enter this in-game:                 │
  │   │ /account link ABC-123               │
  │   │                                     │
  │   │ Expires in: 20:00 (countdown)       │
  │   └─────────────────────────────────────┘
  │
  └─ Web app stores: linkCode, expiresAt, waitingForLink=true

Player (in-game)
  │
  ├─ Sees chat message: "Generate link code with /account link"
  │
  ├─ Runs: /account link ABC-123
  │
  ├─ Plugin: Validates code
  │   │
  │   ├─ Calls: userAccountApi.validateLinkCode("ABC-123")
  │   │   └─ Backend: Validates code, returns userId
  │   │
  │   ├─ Calls: userAccountApi.linkAccount(linkCode=ABC-123, uuid=..., username=...)
  │   │   └─ Backend: Links UUID to existing web account
  │   │
  │   └─ Plugin: Shows "Accounts linked!"
  │
  └─ Result: Merged account
     │
     ├─ In-game: UUID now associated with web account
     │   └─ Next join: Fetches web account data (coins, email, etc.)
     │
     └─ Web app: On next page load, shows merged data
        ├─ UUID in account: matches player's UUID
        └─ Balance: now includes in-game coins

Web app
  │
  ├─ Option 1: Real-time (WebSocket)
  │   └─ Backend sends: "Account linked!" event
  │   └─ Web app: Updates UI immediately
  │
  └─ Option 2: Lazy (next page load)
      └─ Web app: Fetches account data on page refresh
      └─ Shows: "Your game account is now linked!"
```

### Edge Case: Code Expires Before Linking

**Timeline**:
- T=0: Web app generates code (expires at T=1200)
- T=1100: Code visible in browser
- T=1200: Code expires (backend no longer accepts it)
- T=1210: Player runs `/account link ABC-123`
- Plugin: Calls validateLinkCode() → Backend returns 404 or 400
- Plugin: Shows "Code expired or invalid"
- Player: Must go back to web app and request new code

**Mitigation**:
- Web app: Countdown timer showing remaining time
- Web app: "Refresh" button to request new code
- Plugin: Check code expiry before sending to backend

---

## Use Case 3: Duplicate Accounts - Merge in Plugin

### Scenario

**Setup**:
- Player has web app account: `web_user@example.com` (UUID unknown initially)
- Player joins Minecraft: Auto-creates account with UUID + username
- Backend detects: Same username on both accounts → conflict!

### Flow

```
Player joins Minecraft
  │
  ├─ checkDuplicate(uuid=ABC, username="PlayerName")
  │   │
  │   └─ Backend: Finds 2 accounts with same username
  │       ├─ Minecraft account (UUID=ABC)
  │       └─ Web account (no UUID yet)
  │       └─ Returns: hasDuplicate=true
  │
  ├─ Plugin: Caches with hasDuplicateAccount=true
  │
  ├─ PlayerJoinEvent: Sends message
  │   │
  │   └─ "You have 2 accounts. Use /account merge to choose which one to keep."
  │
  └─ Player joined, can play
     (but see merge message)

Player runs: /account merge
  │
  ├─ Plugin: Starts merge flow (ChatCapture)
  │   │
  │   ├─ Fetches: conflictingUser data from cache
  │   │   ├─ Account A: "web_user" (100 coins from web)
  │   │   └─ Account B: "PlayerName" (0 coins, fresh)
  │   │
  │   ├─ Shows: "Which account to keep?"
  │   │   │
  │   │   ├─ "A) web_user (100 coins)"
  │   │   └─ "B) PlayerName (0 coins)"
  │   │
  │   └─ Prompts: "Type A or B:"
  │
  ├─ Player types: "A"
  │
  ├─ Plugin: Calls userAccountApi.mergeAccounts(primaryId=..., secondaryId=...)
  │   │
  │   └─ Backend: Merges, deletes secondary account
  │       ├─ Keeps: web account (all coins/XP)
  │       ├─ Updates: UUID to point to Minecraft player
  │       └─ Returns: Merged UserResponse
  │
  ├─ Plugin: Updates cache
  │   └─ hasDuplicateAccount = false
  │
  └─ Message: "Accounts merged! You now have 100 coins."

Web app (if open)
  │
  ├─ Option 1: Real-time notification (WebSocket)
  │   └─ Backend sends: "Account linked to UUID=ABC"
  │   └─ Web app: Updates UUID field
  │
  └─ Option 2: Next page load
      └─ Fetches account data
      └─ Shows: UUID now populated
```

### Important: Web App Doesn't Know About Merge

**Why?**: Duplicates only exist in plugin (Minecraft-specific)

**Web app sees**:
- After merge: Single account with UUID + balance
- No record of the "merge flow" (it's plugin-internal)

**Implication**: No merge UI needed in web app (only in plugin)

---

## Use Case 4: Password Change Coordination

### Current State

**Backend endpoint exists**: `PUT /api/users/{id}/change-password`

**Plugin can implement**: In-game password change (future)

**Web app implements**: Browser-based password change

### How They Coordinate

```
Web app: User changes password
  │
  ├─ POST /api/users/{id}/change-password (email=..., newPassword=...)
  │   └─ Backend: Validates, updates hash
  │
  └─ No sync needed to plugin (password stored only on backend)

In-game (future):
  │
  ├─ /account password <new-password>
  │
  ├─ ChatCapture: Email + old password (verification)
  │
  ├─ POST /api/users/{id}/change-password
  │   └─ Backend: Validates, updates
  │
  └─ Message: "Password changed"

Result: Both change same backend record
  └─ Player can use new password on web app immediately
```

**Note**: No cross-notification needed (password is server-side only)

---

## Use Case 5: Email Update Coordination

### Current State

**Backend endpoint exists**: `PUT /api/users/{id}/update-email`

**Plugin should implement**: In-game email update (Phase 4+)

**Web app implements**: Browser-based email update

### How They Coordinate

```
Web app: User updates email
  │
  ├─ Old email verification (send link to old email?)
  │   └─ Backend: Validates email ownership
  │
  ├─ POST /api/users/{id}/update-email
  │   └─ Backend: Updates, sends verification link
  │
  └─ Message: "Check your new email for verification link"

In-game:
  │
  ├─ /account email <new-email>
  │
  ├─ POST /api/users/{id}/update-email
  │   └─ Backend: Updates email
  │
  └─ Message: "Email updated! Check your email for verification link."

Result: Same email field updated in backend
  └─ Both players see new email on next sync
```

**Note**: Email verification link is backend-specific (not plugin-aware)

---

## API Response Handling

### Example 1: createUser Success

**Backend Response** (HTTP 200):
```json
{
  "id": 123,
  "username": "PlayerName",
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "email": "me@example.com",
  "coins": 0,
  "gems": 0,
  "experiencePoints": 0,
  "emailVerified": false,
  "accountCreatedVia": "plugin"
}
```

**Plugin handling**:
```java
UserResponse response = userAccountApi.createUser(request).get();
PlayerUserData data = new PlayerUserData(
    response.id(),
    response.username(),
    request.uuid(),
    response.email(),
    response.coins(),
    response.gems(),
    response.experiencePoints(),
    response.emailVerified(),
    false,  // no duplicate
    null,
    System.currentTimeMillis()
);
userCache.put(uuid, data);
```

### Example 2: checkDuplicate - Conflict Found

**Backend Response** (HTTP 200):
```json
{
  "hasDuplicate": true,
  "conflictingUser": {
    "id": 100,
    "username": "web_user",
    "email": "web@example.com",
    "coins": 150
  },
  "primaryUser": {
    "id": 123,
    "username": "PlayerName",
    "email": null,
    "coins": 0
  },
  "message": "Multiple accounts found with same username"
}
```

**Plugin handling**:
```java
DuplicateCheckResponse check = userAccountApi.checkDuplicate(uuid, username).get();
if (check.hasDuplicate()) {
    PlayerUserData data = new PlayerUserData(
        check.conflictingUser().id(),
        check.conflictingUser().username(),
        uuid,
        check.conflictingUser().email(),
        check.conflictingUser().coins(),
        0, 0,
        false,
        true,  // hasDuplicateAccount = true
        check.primaryUser().id(),  // conflictingUserId
        System.currentTimeMillis()
    );
    userCache.put(uuid, data);
}
```

### Example 3: linkAccount Success

**Request**:
```json
{
  "linkCode": "ABC-123",
  "email": "web@example.com",
  "password": "SecurePass123"
}
```

**Backend Response** (HTTP 200):
```json
{
  "id": 100,
  "username": "web_user",
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "email": "web@example.com",
  "coins": 150,
  "gems": 0,
  "experiencePoints": 1000,
  "emailVerified": true,
  "accountCreatedVia": "web"
}
```

**Plugin handling**: Updates cache with new UUID linkage

---

## Recommendations for Frontend Integration

### 1. Add Visual Link Code Generation

**Current**: Web app shows code, user must type in-game

**Improved**: Add QR code or deep link

```
Web app shows:
┌─────────────────────────────────┐
│ Link Code: ABC-123              │
│                                 │
│ [QR Code Image]                 │
│                                 │
│ Or in-game: /account link ABC-123
│                                 │
│ Expires in: 18:45               │
└─────────────────────────────────┘
```

**Benefits**:
- Faster linking (no typing)
- Fewer errors
- Mobile-friendly (scan QR on phone)

### 2. Add Real-Time Sync Notification

**Current**: Plugin knows when link succeeds, web app doesn't

**Improved**: Backend notifies web app via WebSocket

```java
// Backend sends to web socket:
{
  "type": "account_linked",
  "uuid": "550e8400-...",
  "message": "Your game account is now linked!"
}

// Web app receives:
// → Updates UI: Shows UUID + link status
// → Refreshes balance display
```

### 3. Add Merge Status to Web App

**Current**: Merge only visible in plugin

**Improved**: Web app shows "Pending merge" if duplicate detected

```
Web app account dashboard:
┌──────────────────────────────────┐
│ Account Status                   │
│                                  │
│ ⚠️ PENDING MERGE                 │
│ You have 2 game accounts.        │
│ Merge in-game: /account merge    │
│                                  │
│ Account A: web_user (100 coins)  │
│ Account B: PlayerName (0 coins)  │
└──────────────────────────────────┘
```

### 4. Add Link Code Expiry to Web App

**Current**: Timer in browser memory (resets on page reload)

**Improved**: Backend tracks expiry, web app polls for status

```
Web app polls: GET /api/users/current/link-code-status
Response:
{
  "hasActiveLinkCode": true,
  "code": "ABC-123",
  "expiresAt": "2026-01-29T12:25:00Z",
  "remainingSeconds": 1200
}

Web app: Displays countdown, auto-refreshes before expiry
```

---

## Conflict Resolution Matrix

| Scenario | Plugin | Web App | Resolution |
|----------|--------|--------|-----------|
| Account creation | ✅ Create minimal | ❌ N/A | Plugin creates, web app links |
| Email update | ⏳ Future | ✅ Now | Both update same backend field |
| Password change | ⏳ Future | ✅ Now | Both update same backend hash |
| Link code gen | ❌ N/A | ✅ Now | Web app generates, plugin consumes |
| Account merge | ✅ Merge picker | ❌ N/A | Plugin merges, web app sees result |
| Duplicate detect | ✅ Yes | ❌ No | Plugin handles, web app notified |

---

## Summary

**Key Principles**:

1. **Plugin is Minecraft-specific**: Account creation, merging, chat capture
2. **Web app is browser-specific**: Login, link code generation, email management
3. **Backend is central**: Stores all data, makes merge/link decisions
4. **Real-time sync**: Plugin and web app should notify each other via WebSocket (future enhancement)
5. **Graceful degradation**: If one system is down, the other continues to work

---

**Document Version**: 1.0  
**Last Updated**: January 29, 2026  
**Status**: Reference for cross-system design
