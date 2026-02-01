# Phase 4 Quick Start: Commands Implementation

**Status**: Ready to Implement  
**Dependency**: Phase 3 ✅ Complete  
**Estimated Effort**: 8-10 hours  
**Components Required**: 3 command classes + registry updates

---

## Overview

Phase 4 implements the user-facing commands that tie together all the chat capture and account management infrastructure from Phases 1-3.

---

## Command Structure Overview

### 1. `/account` - View Account Status
**Class**: `AccountCommand` extends `CommandExecutor`
**Flow**: Single-step, no user input required
**Purpose**: Display cached account information to player

### 2. `/account create` - Create Account with Email/Password
**Class**: `AccountCreateCommand` extends `CommandExecutor`  
**Flow**: Multi-step using ChatCaptureManager
**Flow Steps**: 
1. Player runs `/account create`
2. ChatCaptureManager starts flow
3. Player enters: email → password → password confirm
4. Command receives data via callback
5. Command calls API to update user account
6. Confirms to player

### 3. `/account link` - Link or Generate Link Code
**Class**: `AccountLinkCommand` extends `CommandExecutor`
**Flow**: Two scenarios
**Scenario A (No args)**: Generate link code
1. Player runs `/account link`
2. Command calls API to generate code
3. Display code to player
4. Player uses code in web app

**Scenario B (With code arg)**: Consume link code
1. Player runs `/account link ABC123`
2. Command validates code
3. If duplicate detected → start merge flow
4. If no duplicate → link accounts via API
5. Update cache and confirm

---

## Files to Create

### Phase 4 File List
```
knk-paper/src/main/java/net/knightsandkings/knk/paper/commands/
├── AccountCommand.java                 (View account status)
├── AccountCreateCommand.java           (Create account)
├── AccountLinkCommand.java             (Generate/consume link code)
└── AccountCommandRegistry.java         (Register all account commands)

knk-paper/src/main/resources/
└── plugin.yml                          (Update with new commands)
```

---

## Integration Points

### In KnKPlugin.onEnable()

Add command registration (after ChatCaptureManager initialization):

```java
// Register account commands (Phase 4)
registerAccountCommands();
getLogger().info("Account commands registered");
```

Add method:

```java
private void registerAccountCommands() {
    PluginCommand accountCmd = getCommand("account");
    if (accountCmd != null) {
        accountCmd.setExecutor(new AccountCommandRegistry(
            this,
            userManager,
            chatCaptureManager,
            userAccountApi,
            config
        ));
        getLogger().info("Registered /account command");
    } else {
        getLogger().warning("Failed to register /account command - not defined in plugin.yml?");
    }
}
```

### In plugin.yml

Update commands section (append to existing account command):

```yaml
commands:
  account:
    description: "Manage your in-game account"
    usage: "/account [create|link] [code]"
    aliases: [acc]
    permission: knk.account.use
```

---

## Implementation Hints

### For AccountCommand (View Status)

1. Get cached user data: `userManager.getCachedUser(player.getUniqueId())`
2. Display formatted account info
3. Check for duplicate flag: show warning if needed
4. Check email link status: show next steps

### For AccountCreateCommand

1. Check if player already has email linked (error if yes)
2. Call `chatCaptureManager.startAccountCreateFlow()` with callbacks:
   ```java
   chatCaptureManager.startAccountCreateFlow(
       player,
       (data) -> {
           // data contains: email, password
           handleAccountCreation(player, userData, data.get("email"), data.get("password"));
       },
       () -> {
           player.sendMessage(prefix + "§cAccount creation cancelled");
       }
   );
   ```
3. In callback:
   - Call API: `apiClient.updateEmail(userId, email)`
   - Call API: `apiClient.changePassword(userId, request)`
   - Update cache: `userManager.updateCachedUser(uuid, newData)`
   - Confirm to player

### For AccountLinkCommand

1. **If no args**: Generate link code
   - Call API: `apiClient.generateLinkCode(userId)`
   - Display code with expiry time
   
2. **If with code arg**: Consume link code
   - Call API: `apiClient.validateLinkCode(code)` 
   - If invalid → show error
   - If valid:
     - Check for duplicate: `apiClient.checkDuplicate(...)`
     - If duplicate → start merge flow
     - If not → link account
     - Update cache
     - Confirm

### For Merge Flow Callback

```java
chatCaptureManager.startMergeFlow(
    player,
    accountACoin, accountAGems, accountAXp, accountAEmail,
    accountBCoin, accountBGems, accountBXp, accountBEmail,
    (data) -> {
        String choice = data.get("choice"); // "A" or "B"
        int primaryId = choice.equals("A") ? accountA.getId() : accountB.getId();
        int secondaryId = choice.equals("A") ? accountB.getId() : accountA.getId();
        
        // Call API to merge
        mergeAccounts(player, primaryId, secondaryId);
    },
    () -> {
        player.sendMessage(prefix + "§cMerge cancelled");
    }
);
```

---

## Error Handling

All commands should catch exceptions and:
1. Log to logger: `getLogger().severe("...")`
2. Display user-friendly message: `player.sendMessage(prefix + "§cError message")`
3. Never show stack traces to player
4. Optionally retry for transient errors

Example:
```java
try {
    // API call
} catch (Exception e) {
    logger.severe("Failed for " + player.getName() + ": " + e.getMessage());
    player.sendMessage(prefix + "§cFailed. Please try again later.");
    return true;
}
```

---

## Configuration Usage in Commands

Commands receive `KnkConfig config` which provides:

- `config.messages().prefix()` - Command prefix
- `config.messages().accountCreated()` - Account created message
- `config.messages().accountLinked()` - Account linked message
- `config.messages().linkCodeGenerated()` - Link code message
- `config.messages().invalidLinkCode()` - Invalid code message
- `config.messages().duplicateAccount()` - Duplicate warning
- `config.messages().mergeComplete()` - Merge complete message
- `config.account().linkCodeExpiryMinutes()` - Link code expiry
- `config.account().chatCaptureTimeoutSeconds()` - Chat capture timeout

---

## Permissions

Three permission nodes already defined in plugin.yml:

```yaml
knk.account.use:
  description: Ability to use /account command
  default: true
  
knk.account.create:
  description: Create account with email/password
  default: true
  
knk.account.admin:
  description: Admin account management
  default: op
```

Add permission checks in commands:
```java
if (!sender.hasPermission("knk.account.use")) {
    sender.sendMessage(prefix + "§cYou don't have permission");
    return true;
}
```

---

## Testing Points

Before Phase 4 is complete, test:

✅ `/account` displays status correctly  
✅ `/account create` starts flow  
✅ `/account create` validates email  
✅ `/account create` validates password  
✅ `/account create` completes successfully  
✅ `/account link` generates code  
✅ `/account link CODE` validates code  
✅ `/account link CODE` handles duplicate  
✅ `/account link CODE` merges accounts  
✅ Error cases display proper messages  
✅ Permissions are checked  

---

## Next Phase

After Phase 4 (Commands) is complete:
- Phase 5: Error Handling & Polish (logging, rate limiting, perms)
- Phase 6: Testing (unit tests, integration tests)
- Phase 7: Documentation

---

## Reference Code Patterns

### Bukkit CommandExecutor Pattern

```java
public class MyCommand implements CommandExecutor {
    @Override
    public boolean onCommand(CommandSender sender, Command cmd, 
                             String label, String[] args) {
        if (!(sender instanceof Player)) {
            sender.sendMessage("Only players can use this");
            return true;
        }
        
        Player player = (Player) sender;
        
        // Command logic here
        
        return true;
    }
}
```

### Async Tasks in Bukkit

```java
plugin.getServer().getScheduler().runTaskAsynchronously(plugin, () -> {
    // Async task
});

plugin.getServer().getScheduler().runTask(plugin, () -> {
    // Sync task (safe to use Bukkit API)
});

plugin.getServer().getScheduler().scheduleSyncDelayedTask(plugin, () -> {
    // Run on main thread after delay
}, delayTicks);
```

---

**Ready to start Phase 4 implementation!**
