# SPEC: User / Player Account System (Source-Grounded)

This specification is derived exclusively from:
- **Legacy implementation**: User.java, UserStatistics.java, UserStatisticsDaily.java, UserLogin.java, UserLoginError.java
- **Usage patterns**: PlayerListener.java, MenuListener.java, Event handlers, Command integration
- **Related entities**: UserRepository, MGMember, Dominion ownership references

All domain concepts are grounded in actual source code. TBD sections identify gaps requiring stakeholder confirmation.

---

## Part A: Core User Entity (Confirmed from User.java)

### User Profile & Identity

**Confirmed Fields (v2 Architecture):**
- `id: Integer` (Primary Key, database surrogate identifier; auto-generated; required for multilateral create flow)
- `uuid: UUID` (Unique Index; represents Minecraft player UUID; nullable at creation; set on first Minecraft join)
- `username: String` (player name; max 256 chars; required; stored as-is from Minecraft server or web app input)
- `created: DateTime` (creation timestamp; set at record creation or first Minecraft login; immutable)
- `email: String` (optional; for web app accounts; nullable for Minecraft-only accounts)
- `hostAddress: String` (player's IP address as string; nullable; captured at login time)
- `inetAddress: InetAddress` (@Transient in legacy; runtime network address object; not persisted)

**v2 Creation Flow Architecture:**
1. **Web App Path**: User creates account → generates `id` (via API) → `uuid` remains null until first Minecraft join → on join, UUID captured
2. **Minecraft Path**: Player joins server → Player exists or new record created with `uuid` → API assigns/retrieves `id` → full sync to web app

**Use-Cases:**
- Identify player across web and Minecraft platforms
- Support deferred UUID binding (web app signup before Minecraft join)
- Track player account creation date across platforms
- Store IP address for security/audit purposes
- Retrieve user context during gameplay events

**Constraints:**
- `id` is immutable once created
- `uuid` is immutable once set; can be null initially
- `username` mirrors Minecraft server identity (if Minecraft player) or web app input
- `username` + `uuid` together form unique identity (once UUID set)
- Username uniqueness: TBD (enforcement across platforms)
- Email uniqueness: TBD (if required for web app)

---

### Currency & Economic System

**Confirmed Fields (v2 - Dual Currency):**
- `coins: Integer` (primary in-game currency; tied to real money/premium; default 250; non-negative; stored as INT)
- `gems: Integer` (secondary in-game currency; alt economy or free-to-play; default 50; non-negative; stored as INT)
- `experiencePoints: Integer` (player progression XP; default 0; non-negative; stored as INT)

Note: Legacy system used single `cash` field (default 100). v2 splits into Coins (premium) and Gems (free).

**Confirmed Methods:**
- `getCoins(): Integer` – retrieve current coin balance
- `setCoins(int): void` – set coin balance (via transaction service, not direct)
- `addCoins(int): void` – increment coins (must be atomic transaction)
- `removeCoins(int): void` – decrement coins, with floor at 0 (prevents negative)
- `getGems(): Integer` – retrieve current gem balance
- `setGems(int): void` – set gem balance
- `addGems(int): void` – increment gems
- `removeGems(int): void` – decrement gems, with floor at 0
- `getExperiencePoints(): Integer` – retrieve XP
- `addExperiencePoints(int): void` – increment XP (non-negative result)

**Use-Cases:**
- Track primary premium currency (tied to real-money purchases)
- Track secondary free currency (earned in-game)
- Enable purchases, trades, rewards
- Display balance in UI/menus/web app
- Enforce payment constraints

**⚠️ CRITICAL: Banking-Grade Balance Handling (Coins, Gems, ExperiencePoints)**

Balance updates for Coins, Gems, and ExperiencePoints **MUST** implement:

1. **Optimistic Locking**: Use version/timestamp field to detect concurrent modifications
   ```
   UPDATE User SET Coins = @newCoins, Version = Version + 1 
   WHERE Id = @id AND Version = @expectedVersion
   ```

2. **Audit Trail**: Log all balance changes with:
   - Timestamp
   - Previous balance
   - New balance
   - Delta (amount added/removed)
   - Reason/transaction type (purchase, refund, reward, etc.)
   - Initiator (player, system, admin)

3. **Atomic Transactions**: All balance operations must be ACID-compliant; no partial updates

4. **Rollback Capability**: Failed transactions must restore previous balance; maintain transaction history

5. **Rate Limiting**: Prevent rapid-fire balance updates from same source (fraud detection)

6. **Reconciliation**: Daily/weekly reconciliation against transaction audit trail

7. **No Direct Setter**: Coins/Gems/ExperiencePoints should be updated only through service methods (Add*/Remove*/AddExperiencePoints), never direct property assignment

**Business Rules:**
- Balance cannot go negative for Coins, Gems, or ExperiencePoints; attempts to remove more than available must fail (return error, not clamp)
- Starting coins on account creation: 250
- Starting gems on account creation: 50
- Starting experiencePoints on account creation: 0
- All coin/gem/XP operations require reason/transaction type
- Coin transactions must be logged to separate audit table; Gems and ExperiencePoints should also be logged (XP logging can be lighter but must retain audit trail)
- Concurrent updates must be serialized (no race conditions)
- Large coin changes (>1000) may require approval/logging at INFO level

---

### Inventory & Stash Management

**Confirmed Fields:**
- `stashedItems: List<Item>` (@ManyToMany, lazy-loaded; join table: `user_items_stashed`)

**Confirmed Methods:**
- `getStashedItems(): List<Item>` – retrieve stashed items (initializes empty list if null)
- `setStashedItems(List<Item>): void` – replace entire stash
- `addStashedItem(Item): boolean` – add item if not already present; returns success flag
- `removeStashedItem(Item): boolean` – remove item; returns success flag
- `giveItem(Item, int): void` – add item to player inventory or stash if inventory full

**Use-Cases:**
- Allow players to store items offline
- Manage player inventory overflow (if inventory full, items go to stash)
- Retrieve/restore items on demand

**Business Rules:**
- Stash prevents inventory overflow; items automatically move to stash when inventory is full
- Duplicate detection: same Item cannot be stashed twice
- Stash is persistent across logout/login

---

## Part B: Runtime Session & Interaction State

### Login/Logout Session Tracking

**Confirmed Fields:**
- `player: Player` (@Transient; Spigot runtime object; valid only during active session)
- `loginEvent: UserLogin` (@Transient; session metadata for current login)
- `newUser: boolean` (@Transient; flag indicating first-time login; used for onboarding)

**Confirmed Methods:**
- `login(Player, InetAddress): void` – initialize session on player join
  - Sets player reference
  - Creates UserLogin event object with timestamp and IP address
  - Increments login statistics
  - Initializes daily statistics if needed, or validates existing daily stats (TBD: validation logic)
- `logout(): void` – finalize session on player disconnect
  - Records logout timestamp in UserLogin

**Related Entity: UserLogin**
- `id: Integer` (auto-generated)
- `user: User` (many-to-one cascade)
- `loginDate: Date` (set at login)
- `logoutDate: Date` (set at logout)
- `totalPlayTime: Long` (milliseconds; calculated as logoutDate - loginDate)
- `hostAddress: String` (IP captured at login)

**Use-Cases:**
- Track session duration
- Record play history (login/logout events)
- Audit IP address changes
- Prevent duplicate logins
- Identify new vs returning players

**Business Rules:**
- New users receive initial cash (100) at first login
- Daily stats reset if previous daily record is stale (not today's date)
- Session persists only while player is online
- IP address captured immutably at session start

---

### Statistics & Achievement Tracking

**Confirmed Fields (UserStatistics):**
- **Session Stats:** `logins: int` (cumulative login count)
- **Economy:** `cashEarned: int`, `cashSpent: int` (lifetime totals)
- **Combat (General):**
  - `kills: int`, `deaths: int`
  - `minigameKills: int`, `minigameDeaths: int`
  - `siegeKills: int`, `siegeDeaths: int`
- **Minigame:** `minigameWins: int`, `minigameLosses: int`
- **Siege:** `siegeWins: int`, `siegeLosses: int`
- **Objectives:** `objectivesCaptured: int` (siege/minigame objectives)
- **Damage & Combat Metrics:**
  - `gateDamage: double` (structural damage in sieges)
  - `damageDealt: double`, `damageReceived: double` (total combat)
  - `arrowsFired: int`, `headshots: int`
  - `highestKillstreak: int`
- **Movement:** `distanceTraveled: double` (blocks or meters; TBD: unit)
- **Environmental:** `highestFall: double` (fall distance survived)

**Related Entity: UserStatisticsDaily (extends UserStatistics)**
- Inherits all fields from UserStatistics
- Additional field: `date: Date` (current day at creation)
- Method: `isValid(): boolean` – returns true if date matches today (for daily reset logic)

**Confirmed Methods:**
- `getStatistics(): UserStatistics` – retrieve full lifetime stats
- `addLogins(int): void` – increment login count (called during login)
- [Implied] Methods to increment combat, economy, and minigame stats (TBD: exact method names)

**Use-Cases:**
- Track lifetime player achievements
- Display leaderboards (kills, wins, earnings, etc.)
- Daily/weekly statistics snapshots
- Progress reporting and analytics

**Business Rules:**
- Stats are cumulative; never reset except for daily stats
- Daily stats reset automatically if date changes (validated at login)
- Stats increment during gameplay events (kill, death, capture, etc.)
- User must have statistics object; auto-created if missing at login

---

### Communication & In-Game Messaging

**Confirmed Methods:**
- `sendMessage(String): void` – send chat message to player
- `sendMessage(List<String>): void` – send multiple chat messages
- `sendABMessage(String): void` – send Action Bar message (header-like display)
- `sendABMessage(List<String>, int): void` – send sequence of Action Bar messages with interval (milliseconds)
- `playSound(Sound, float, float): void` – play sound at player location
  - Parameters: sound type, volume (default 1.0 if -1), pitch (default 1.0 if -1)

**Use-Cases:**
- Notify player of events (login, item received, quest progress)
- Display temporary status messages (countdown, damage indicator)
- Audio feedback for actions
- Multi-step announcements with delays

---

### Menu/Inventory Management

**Confirmed Fields:**
- `menu: Menu` (@Transient; current open inventory menu)
- `previousMenu: Menu` (@Transient; previous menu for "back" navigation)
- `menuViewers: List<User>` (@Transient; other players viewing this player's menu in real-time)
- `menuViewing: User` (@Transient; if this player is viewing another player's menu, reference to that player)

**Confirmed Methods:**
- `getMenu(): Menu` – retrieve current open menu
- `setMenu(Menu): void` – set current menu
- `openMenu(Menu): void` – open new menu in player's inventory screen
  - Closes previous menu if different
  - Notifies all viewers that player opened a new menu
  - Returns early if menu is already open
- `closeMenu(boolean): void` – close current menu
  - `resetCursor: true` → closes inventory immediately (centers cursor)
  - `resetCursor: false` → keeps inventory open
  - Stores previous menu for back navigation
  - Notifies all viewers that menu was closed
  - Cascades: if menu has pending close, executes that too
- `getMenuViewers(): List<User>` – list of players viewing this menu
- `getMenuViewing(): User` – if viewing another player's menu, return that player

**Use-Cases:**
- Inventory-based UI system for shops, crafting, dialogs
- Real-time collaborative menu viewing (spectating)
- Back button navigation
- Menu-driven workflows (creation stages, configuration)

**Business Rules:**
- Only one menu open per player at a time
- Opening new menu auto-closes previous (unless same menu)
- Menu viewers see updates in real-time
- Closing menu preserves previous menu for navigation history
- Viewer notifications sent on open/close events

---

## Part C: Integration with Related Systems

### Statistics Context in Login Flow

```
Player joins server
  → PlayerListener.PlayerJoinEvent triggered
  → User.login(player, inetAddress) called
  → If User.statistics == null:
       Create new UserStatistics
       Create new UserStatisticsDaily
  → Else if daily stats exist:
       Validate isValid() (date == today)
       If invalid (date mismatch):
         Delete old UserStatisticsDaily
         Create new UserStatisticsDaily
  → Increment statistics.logins
```

**TBD:**
- How are daily statistics actually reset/managed?
- Is UserStatisticsDaily persisted or transient?

---

### Minigame Integration (MGMember Pattern)

In minigames (MGMember, Siege, etc.):
- User object is wrapped as MGMember
- MGMember tracks: kills, deaths, team, captured objectives, stored inventory
- User.playSound, sendMessage used for in-game events
- User.statistics updated after minigame ends (kills/deaths/wins incremented)

---

### Dominion/Town Ownership & Permissions

**Not directly persisted on User, but User references exist in:**
- Town/District/Street may track owner (TBD: confirmed in source)
- User.uuid used as lookup key for permission checks
- User context required for access control decisions

---

### Login Error Tracking (UserLoginError)

**Related Entity: UserLoginError**
- `id: Integer` (auto-generated)
- `uuid: UUID` (user UUID)
- `errorDate: Date`
- `loginAttempts: int` (incremented on each failed attempt; MAX_LOGIN_ATTEMPTS = 3)
- `stackTraceString: String` (nullable; full exception trace for debugging)

**Use-Cases:**
- Track failed login attempts
- Lock out account after repeated failures (TBD: lockout duration)
- Debugging login issues
- Security audit trail

**Business Rules:**
- Account locked if loginAttempts >= 3
- Error records persist across reboots
- TBD: Is error cleared after successful login or timed expiry?

---

## Part D: Display & Serialization

### Menu/UI Integration

**Implemented Methods:**
- `getDescription(): List<String>` – returns formatted description lines for display
- `getVarDescription(): List<String>` – template with variables (e.g., "%getUuid%", "%getCash%")
- `createMenuItemStack(): ItemStack` – returns ItemStack for menu representation
- `createMenuDescription(): List<String>` – description for menu context
- `createMenuVarDescription(): List<String>` – variable template for menu

**Variable Templates Used:**
```
"UUID: %getUuid%"
"Created: %getCreatedString%"
"Username: %getName%"
"Cash: %getCash%"
"Description: "
```

**Use-Cases:**
- Display player profile in menus
- Show player stats in lists
- Social profile visualization

---

### Utility Methods

**Confirmed Methods:**
- `getName(): String` – get player username
- `getCreatedString(): String` – get creation date as string
- `convertVariable(String): Object` – reflective field lookup; returns formatted value (e.g., cash as currency)
- `getId(): UUID` – returns player UUID (from IPersistent interface)
- `getKeyClass(): Class<UUID>` – returns UUID.class

---

## Part E: External Contracts & Constraints

### Persistence Contracts

**Source: User.java annotations**
- `@Entity`, `@Table(name = "user")`
- `@Id` on uuid
- Persisted to database table `user`
- Relationships: OneToOne (statistics, cascaded), ManyToMany (stashedItems)
- Transient fields (player, loginEvent, menu, etc.) are runtime-only

### Interfaces Implemented

- `IPersistent<UUID>` – entities with UUID identity and repository pattern
- `IDisplayable<UUID>` – UI representation contract

---

## Part F: Known Gaps & TBD Items

1. **Daily Statistics Reset Logic**: Is UserStatisticsDaily actually persisted? When/how is it reset?
2. **Audit Trail**: Are cash transactions logged somewhere?
3. **Account Lockout**: How long does a locked account stay locked after login failures?
4. **IP Address Rotation**: Is it normal for players to have multiple IPs? Should IP changes trigger alerts?
5. **Name Changes**: Does Minecraft allow name changes? How is legacy username handled?
6. **Statistics Increment Methods**: What are the exact method names for incrementing combat/economy stats?
7. **Stash Item Limits**: Is there a max stash size?
8. **Maximum Cash Balance**: Is there a cap, or unlimited?
9. **Menu Viewer Notifications**: Current text is hardcoded; should be localized/configurable?
10. **Ownership Relations**: How are towns/districts/streets linked to owner User? (TBD: confirmed in source)

---

## Part G: Implementation Recommendations for v2

Based on legacy analysis:

1. **Separate Session from Persistence**: Keep Player, loginEvent, menus as transient; only persist core profile + statistics.

2. **Statistics Archival**: Consider separate tables for daily/weekly/monthly snapshots vs. cumulative stats.

3. **Audit Logging**: Add explicit audit table for cash transactions (add, remove, earn, spend).

4. **Type-Safe Methods**: Instead of `convertVariable(String)`, use type-safe getters or annotations.

5. **Async Statistics**: Minigame stats update frequently; consider async batch updates to reduce DB writes.

6. **Menu System Refactor**: Replace @Transient menu fields with explicit queue/state machine (more testable).

7. **Login Error Handling**: Consider separate service with configurable lockout strategy.

8. **IP Tracking**: Consider separate IpAddress table with history; current hostAddress field is basic.

---

## Appendix: Source Files Referenced

- `/Repository/knk/src/main/java/net/knightsandkings/model/user/User.java`
- `/Repository/knk/src/main/java/net/knightsandkings/model/user/UserStatistics.java`
- `/Repository/knk/src/main/java/net/knightsandkings/model/user/UserStatisticsDaily.java`
- `/Repository/knk/src/main/java/net/knightsandkings/model/user/UserLogin.java`
- `/Repository/knk/src/main/java/net/knightsandkings/model/user/UserLoginError.java`
- `/Repository/knk/src/main/java/net/knightsandkings/listeners/PlayerListener.java` (login/logout events)
- `/Repository/knk/src/main/java/net/knightsandkings/model/minigame/MGMember.java` (gameplay integration)
- `/Repository/knk/src/main/java/net/knightsandkings/dal/repository/UserRepository.java` (data access)
