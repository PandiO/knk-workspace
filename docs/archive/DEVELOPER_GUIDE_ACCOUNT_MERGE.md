# Developer Guide: Account Merge Logic & Foreign Key Handling

**Author**: Knights & Kings Development Team  
**Created**: January 17, 2026  
**Status**: Active  

This document explains the account merge implementation and foreign key relationship handling in the user account management system.

---

## Table of Contents

1. [Overview](#overview)
2. [When to Merge Accounts](#when-to-merge-accounts)
3. [Merge Strategy: Winner Takes All](#merge-strategy-winner-takes-all)
4. [Implementation Details](#implementation-details)
5. [Foreign Key Relationships](#foreign-key-relationships)
6. [Merge Process Step-by-Step](#merge-process-step-by-step)
7. [Soft Delete Implementation](#soft-delete-implementation)
8. [Testing Merge Operations](#testing-merge-operations)
9. [Rollback & Recovery](#rollback--recovery)
10. [Best Practices](#best-practices)

---

## Overview

Account merging addresses the scenario where a single player has **two user accounts** in the system:

1. **Minecraft-first account**: Created when player joins server (UUID + username only)
2. **Web-app-first account**: Created on website (email + password)

When the player links their accounts, we need to **merge** them into a single unified account.

**Key Decisions:**
- ✅ **Winner Takes All**: Primary account keeps all its data
- ✅ **Soft Delete**: Secondary account is marked deleted, not physically removed
- ✅ **Foreign Key Updates**: All references to secondary account are updated to primary
- ✅ **90-Day TTL**: Soft-deleted accounts are permanently deleted after 90 days

---

## When to Merge Accounts

### Scenario 1: Player Joins Minecraft First

```
Day 1: Player joins Minecraft server
  → System creates User (UUID, username)
  → No email, no password

Day 5: Player wants web access
  → Player generates link code from Minecraft
  → Player enters link code on website
  → Player provides email + password
  → System UPDATES existing account (no merge needed)
```

**No merge required** - just updating the existing account with email/password.

### Scenario 2: Player Creates Web Account First

```
Day 1: Player signs up on website
  → System creates User (email, password, optional username)
  → No UUID

Day 5: Player joins Minecraft server
  → System checks: username already exists?
  → YES → Duplicate detected
  → System creates NEW User (UUID, username) [Secondary]
  → Minecraft plugin prompts: "Link your accounts?"
  → Player generates link code
  → Player validates on website
  → System detects CONFLICT
  → System MERGES secondary into primary
```

**Merge required** - two separate accounts need to be consolidated.

### Scenario 3: Player Uses Different Usernames

```
Day 1: Website account (username: "KnightPlayer", email: knight@example.com)
Day 5: Joins Minecraft as "KnightPlayer123"
  → System creates new account (different username)
  → Player manually initiates merge via support/admin panel
```

**Manual merge** - admin intervention or player-initiated merge.

---

## Merge Strategy: Winner Takes All

### Design Decision

We use a **simple "winner takes all"** strategy rather than field-by-field consolidation:

❌ **NOT IMPLEMENTED: Consolidation Strategy**
```
Primary: { Coins: 100, Gems: 0, Email: "player@example.com" }
Secondary: { Coins: 50, Gems: 20, Email: null }
Merged: { Coins: 150, Gems: 20, Email: "player@example.com" }  // SUM
```

✅ **IMPLEMENTED: Winner Takes All**
```
Primary: { Coins: 100, Gems: 0, Email: "player@example.com" }
Secondary: { Coins: 50, Gems: 20, Email: null }
Merged: { Coins: 100, Gems: 0, Email: "player@example.com" }  // Keep primary
```

### Rationale

1. **Simplicity**: No complex business rules for field merging
2. **Predictability**: Players know which account will be kept (web account = primary)
3. **Avoid Exploits**: Can't create multiple accounts to accumulate coins then merge
4. **Clear Intent**: Web account (email-based) is the "real" identity; Minecraft accounts are secondary

### Future Enhancement: Balance Transfer

If needed, we can add **manual balance transfer** before merge:

```csharp
// Transfer balances from secondary to primary before merge
await _service.AdjustBalancesAsync(
    primaryUserId, 
    secondaryUser.Coins, 
    secondaryUser.Gems, 
    secondaryUser.ExperiencePoints,
    reason: $"Transfer from merged account {secondaryUserId}");

// Then merge (primary now has combined balances)
await _service.MergeAccountsAsync(primaryUserId, secondaryUserId);
```

---

## Implementation Details

### Location: `Repositories/UserRepository.cs`

```csharp
public async Task MergeUsersAsync(int primaryUserId, int secondaryUserId)
{
    using var transaction = await _context.Database.BeginTransactionAsync();
    
    try
    {
        var primaryUser = await _context.Users.FindAsync(primaryUserId);
        var secondaryUser = await _context.Users.FindAsync(secondaryUserId);

        if (primaryUser == null || secondaryUser == null)
        {
            throw new KeyNotFoundException("One or both users not found");
        }

        // 1. Update foreign key references
        await UpdateForeignKeyReferencesAsync(secondaryUserId, primaryUserId);

        // 2. Soft delete secondary user
        secondaryUser.IsActive = false;
        secondaryUser.DeletedAt = DateTime.UtcNow;
        secondaryUser.DeletedReason = $"Merged into user {primaryUserId}";
        secondaryUser.ArchiveUntil = DateTime.UtcNow.AddDays(90); // 90-day TTL

        // 3. Save changes
        await _context.SaveChangesAsync();
        await transaction.CommitAsync();
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}

private async Task UpdateForeignKeyReferencesAsync(int oldUserId, int newUserId)
{
    // Update all entities that reference the old user
    
    // Example: Towns
    await _context.Towns
        .Where(t => t.OwnerId == oldUserId)
        .ExecuteUpdateAsync(t => t.SetProperty(x => x.OwnerId, newUserId));

    // Example: Plots (if they exist)
    // await _context.Plots
    //     .Where(p => p.OwnerId == oldUserId)
    //     .ExecuteUpdateAsync(p => p.SetProperty(x => x.OwnerId, newUserId));

    // Add more FK updates as needed when new entities are added
}
```

### Service Layer: `Services/UserService.cs`

```csharp
public async Task<UserDto> MergeAccountsAsync(int primaryUserId, int secondaryUserId)
{
    if (primaryUserId <= 0)
    {
        throw new ArgumentException("Invalid primary user ID.", nameof(primaryUserId));
    }

    if (secondaryUserId <= 0)
    {
        throw new ArgumentException("Invalid secondary user ID.", nameof(secondaryUserId));
    }

    if (primaryUserId == secondaryUserId)
    {
        throw new ArgumentException("Cannot merge a user with itself.");
    }

    // Verify both users exist
    var primaryUser = await _repo.GetByIdAsync(primaryUserId);
    if (primaryUser == null)
    {
        throw new KeyNotFoundException($"Primary user with ID {primaryUserId} not found.");
    }

    var secondaryUser = await _repo.GetByIdAsync(secondaryUserId);
    if (secondaryUser == null)
    {
        throw new KeyNotFoundException($"Secondary user with ID {secondaryUserId} not found.");
    }

    // Perform merge (repository handles FK updates and soft delete)
    await _repo.MergeUsersAsync(primaryUserId, secondaryUserId);

    // Return updated primary user
    var mergedUser = await _repo.GetByIdAsync(primaryUserId);
    return _mapper.Map<UserDto>(mergedUser!);
}
```

---

## Foreign Key Relationships

### Current Foreign Key Relationships (As of January 2026)

| Entity | FK Column | Relationship | Cascade Behavior |
|--------|-----------|--------------|------------------|
| `Towns` | `OwnerId` | Town → User | **NO CASCADE** (manual update) |
| `LinkCodes` | `UserId` | LinkCode → User | **NO CASCADE** (manual cleanup) |

**No cascade deletes** are configured. This is intentional:
- We use **soft delete** for users
- Manual FK updates ensure we don't lose data
- Audit trail is preserved

### Future Relationships to Consider

As the system grows, these entities will need FK handling in merge:

| Entity (Future) | FK Column | Merge Behavior |
|-----------------|-----------|----------------|
| `Plots` | `OwnerId` | Transfer to primary user |
| `Structures` | `BuiltByUserId` | Transfer to primary user |
| `Transactions` | `UserId` | Keep historical record (don't update) |
| `AuditLogs` | `UserId` | Keep historical record (don't update) |
| `Sessions` | `UserId` | Invalidate secondary user sessions |
| `Permissions` | `UserId` | Transfer to primary user (or merge) |

### Adding New Foreign Keys: Checklist

When adding a new entity with a User foreign key:

1. **Decide merge behavior**:
   - Transfer ownership? (e.g., Towns, Plots)
   - Keep historical record? (e.g., Transactions, AuditLogs)
   - Invalidate/delete? (e.g., Sessions, LoginAttempts)

2. **Update `UserRepository.UpdateForeignKeyReferencesAsync`**:
   ```csharp
   // Add to UpdateForeignKeyReferencesAsync method
   await _context.YourNewEntity
       .Where(e => e.UserId == oldUserId)
       .ExecuteUpdateAsync(e => e.SetProperty(x => x.UserId, newUserId));
   ```

3. **Add test case**:
   ```csharp
   [Fact]
   public async Task MergeAccounts_ShouldTransferYourNewEntityOwnership()
   {
       // Test that FK is updated correctly
   }
   ```

---

## Merge Process Step-by-Step

### Step 1: Identify Accounts to Merge

```csharp
// Check for duplicate
var (hasDuplicate, secondaryUserId) = await _service.CheckForDuplicateAsync(uuid, username);

if (hasDuplicate && secondaryUserId.HasValue)
{
    // Duplicate detected
    var primary = await _service.GetByUuidAsync(uuid);  // UUID-based account
    var secondary = await _service.GetByIdAsync(secondaryUserId.Value);  // Username-based account
}
```

### Step 2: Validate Merge Request

```csharp
// Validate both users exist
if (primaryUser == null)
{
    throw new KeyNotFoundException("Primary user not found");
}

if (secondaryUser == null)
{
    throw new KeyNotFoundException("Secondary user not found");
}

// Validate not merging user with itself
if (primaryUserId == secondaryUserId)
{
    throw new ArgumentException("Cannot merge a user with itself");
}
```

### Step 3: Begin Transaction

```csharp
using var transaction = await _context.Database.BeginTransactionAsync();
```

### Step 4: Update Foreign Key References

```csharp
// Update all entities that reference secondary user
await UpdateForeignKeyReferencesAsync(secondaryUserId, primaryUserId);
```

### Step 5: Soft Delete Secondary User

```csharp
secondaryUser.IsActive = false;
secondaryUser.DeletedAt = DateTime.UtcNow;
secondaryUser.DeletedReason = $"Merged into user {primaryUserId}";
secondaryUser.ArchiveUntil = DateTime.UtcNow.AddDays(90);
```

### Step 6: Save & Commit

```csharp
await _context.SaveChangesAsync();
await transaction.CommitAsync();
```

### Step 7: Return Merged User

```csharp
var mergedUser = await _repo.GetByIdAsync(primaryUserId);
return _mapper.Map<UserDto>(mergedUser);
```

---

## Soft Delete Implementation

### User Model: `Models/User.cs`

```csharp
public class User
{
    // ... existing fields ...

    /// <summary>
    /// Indicates if the account is active (false = soft deleted)
    /// </summary>
    public bool IsActive { get; set; } = true;

    /// <summary>
    /// Timestamp when account was soft deleted
    /// </summary>
    public DateTime? DeletedAt { get; set; }

    /// <summary>
    /// Reason for soft deletion (e.g., "Merged into user 123")
    /// </summary>
    public string? DeletedReason { get; set; }

    /// <summary>
    /// Date when soft-deleted record should be permanently deleted (90-day TTL)
    /// </summary>
    public DateTime? ArchiveUntil { get; set; }
}
```

### Query Filter: Exclude Soft-Deleted by Default

```csharp
// ApplicationDbContext.cs
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    base.OnModelCreating(modelBuilder);

    // Global query filter: exclude soft-deleted users
    modelBuilder.Entity<User>().HasQueryFilter(u => u.IsActive);
}
```

**Note**: This global filter automatically excludes `IsActive = false` users from all queries.

### Querying Soft-Deleted Users

If you need to include soft-deleted users (e.g., admin panel):

```csharp
// Include soft-deleted users
var allUsers = await _context.Users
    .IgnoreQueryFilters()  // Bypass global filter
    .ToListAsync();

// Get only soft-deleted users
var deletedUsers = await _context.Users
    .IgnoreQueryFilters()
    .Where(u => !u.IsActive)
    .ToListAsync();
```

### Permanent Deletion (Cleanup Job)

```csharp
// Background job (e.g., Hangfire, cron job)
public async Task CleanupExpiredSoftDeletedUsersAsync()
{
    var expiredUsers = await _context.Users
        .IgnoreQueryFilters()
        .Where(u => !u.IsActive && u.ArchiveUntil < DateTime.UtcNow)
        .ToListAsync();

    foreach (var user in expiredUsers)
    {
        // Delete associated data (e.g., LinkCodes)
        var linkCodes = await _context.LinkCodes
            .Where(lc => lc.UserId == user.Id)
            .ToListAsync();
        _context.LinkCodes.RemoveRange(linkCodes);

        // Permanently delete user
        _context.Users.Remove(user);
    }

    await _context.SaveChangesAsync();

    // Log cleanup
    _logger.LogInformation($"Permanently deleted {expiredUsers.Count} expired users");
}
```

---

## Testing Merge Operations

### Unit Test: Service Layer

```csharp
[Fact]
public async Task MergeAccountsAsync_ShouldSoftDeleteSecondaryUser()
{
    // Arrange
    var primaryUser = new User { Id = 1, Username = "primary", Email = "primary@example.com" };
    var secondaryUser = new User { Id = 2, Username = "secondary", Uuid = "uuid123" };

    _mockUserRepository.Setup(r => r.GetByIdAsync(1)).ReturnsAsync(primaryUser);
    _mockUserRepository.Setup(r => r.GetByIdAsync(2)).ReturnsAsync(secondaryUser);
    _mockUserRepository.Setup(r => r.MergeUsersAsync(1, 2)).Returns(Task.CompletedTask);

    // Act
    var result = await _userService.MergeAccountsAsync(1, 2);

    // Assert
    _mockUserRepository.Verify(r => r.MergeUsersAsync(1, 2), Times.Once);
    Assert.NotNull(result);
}

[Fact]
public async Task MergeAccountsAsync_WithSameUserId_ShouldThrowException()
{
    // Arrange & Act & Assert
    await Assert.ThrowsAsync<ArgumentException>(
        () => _userService.MergeAccountsAsync(1, 1)
    );
}
```

### Integration Test: Full Workflow

```csharp
[Fact]
public async Task MergeAccounts_ShouldTransferTownOwnership()
{
    // Arrange
    var primaryUser = new User 
    { 
        Username = "primary", 
        Email = "primary@example.com", 
        Coins = 100 
    };
    var secondaryUser = new User 
    { 
        Username = "secondary", 
        Uuid = "uuid123", 
        Coins = 50 
    };

    _context.Users.AddRange(primaryUser, secondaryUser);
    await _context.SaveChangesAsync();

    var town = new Town 
    { 
        Name = "TestTown", 
        OwnerId = secondaryUser.Id 
    };
    _context.Towns.Add(town);
    await _context.SaveChangesAsync();

    // Act
    await _userService.MergeAccountsAsync(primaryUser.Id, secondaryUser.Id);

    // Assert
    var updatedTown = await _context.Towns.FindAsync(town.Id);
    Assert.Equal(primaryUser.Id, updatedTown.OwnerId); // Town now owned by primary user

    var deletedUser = await _context.Users
        .IgnoreQueryFilters()
        .FirstOrDefaultAsync(u => u.Id == secondaryUser.Id);
    Assert.False(deletedUser.IsActive); // Secondary user soft deleted
    Assert.NotNull(deletedUser.DeletedAt);
    Assert.NotNull(deletedUser.ArchiveUntil);
}
```

---

## Rollback & Recovery

### Rollback Within Transaction

If merge fails, the transaction automatically rolls back:

```csharp
using var transaction = await _context.Database.BeginTransactionAsync();

try
{
    // ... merge operations ...
    await transaction.CommitAsync();
}
catch (Exception ex)
{
    await transaction.RollbackAsync();
    _logger.LogError(ex, "Merge failed, rolled back transaction");
    throw;
}
```

### Manual Rollback (Admin Operation)

If you need to undo a merge after the fact:

```csharp
public async Task UndoMergeAsync(int primaryUserId, int secondaryUserId)
{
    var secondaryUser = await _context.Users
        .IgnoreQueryFilters()
        .FirstOrDefaultAsync(u => u.Id == secondaryUserId);

    if (secondaryUser == null || secondaryUser.IsActive)
    {
        throw new InvalidOperationException("Secondary user not found or not soft-deleted");
    }

    using var transaction = await _context.Database.BeginTransactionAsync();

    try
    {
        // 1. Restore secondary user
        secondaryUser.IsActive = true;
        secondaryUser.DeletedAt = null;
        secondaryUser.DeletedReason = null;
        secondaryUser.ArchiveUntil = null;

        // 2. Optionally: Transfer FKs back to secondary
        // (Only if you want to fully undo; usually not needed)

        await _context.SaveChangesAsync();
        await transaction.CommitAsync();

        _logger.LogWarning($"Merge undone: User {secondaryUserId} restored");
    }
    catch
    {
        await transaction.RollbackAsync();
        throw;
    }
}
```

---

## Best Practices

### 1. Always Use Transactions

```csharp
using var transaction = await _context.Database.BeginTransactionAsync();
try
{
    // Merge operations
    await transaction.CommitAsync();
}
catch
{
    await transaction.RollbackAsync();
    throw;
}
```

### 2. Log All Merges

```csharp
_logger.LogInformation(
    "User merge: Primary={PrimaryId}, Secondary={SecondaryId}, DeletedReason={Reason}",
    primaryUserId,
    secondaryUserId,
    secondaryUser.DeletedReason
);
```

### 3. Notify Users

Send email notification after merge:

```csharp
await _emailService.SendMergeNotificationAsync(
    primaryUser.Email,
    $"Your accounts have been successfully merged. Your new unified account ID is {primaryUserId}."
);
```

### 4. Maintain Audit Trail

Keep DeletedReason descriptive:

```csharp
secondaryUser.DeletedReason = $"Merged into user {primaryUserId} on {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC";
```

### 5. Test Foreign Key Updates

Always test that FKs are updated correctly when adding new entities:

```csharp
[Fact]
public async Task MergeAccounts_ShouldUpdate{EntityName}References()
{
    // Verify FK update
}
```

### 6. Consider Balance Transfers

If players should keep combined balances, transfer before merge:

```csharp
// Option 1: Manual transfer
await TransferBalancesAsync(secondaryUserId, primaryUserId);
await MergeAccountsAsync(primaryUserId, secondaryUserId);

// Option 2: Add to merge logic
private async Task MergeUsersWithBalanceTransferAsync(int primaryId, int secondaryId)
{
    var secondary = await _context.Users.FindAsync(secondaryId);
    await AdjustBalancesAsync(primaryId, secondary.Coins, secondary.Gems, secondary.ExperiencePoints, "Merge transfer");
    await MergeUsersAsync(primaryId, secondaryId);
}
```

---

## Future Enhancements

### 1. Merge Preview

Show what will happen before merge:

```csharp
public async Task<MergePreviewDto> PreviewMergeAsync(int primaryId, int secondaryId)
{
    return new MergePreviewDto
    {
        PrimaryUser = await GetByIdAsync(primaryId),
        SecondaryUser = await GetByIdAsync(secondaryId),
        AffectedTowns = await GetTownsByOwnerIdAsync(secondaryId),
        AffectedPlots = await GetPlotsByOwnerIdAsync(secondaryId),
        BalanceDifference = CalculateBalanceDiff(primary, secondary)
    };
}
```

### 2. Merge Approval Workflow

Require confirmation:

```csharp
// Step 1: Request merge
var mergeRequest = await RequestMergeAsync(primaryId, secondaryId);

// Step 2: User confirms via email link
await ConfirmMergeAsync(mergeRequest.Token);

// Step 3: Perform merge
await ExecuteMergeAsync(mergeRequest.Id);
```

### 3. Bulk Merge Detection

Find all accounts that should be merged:

```csharp
public async Task<List<MergeCandidateDto>> FindMergeCandidatesAsync()
{
    // Find users with same UUID but different accounts
    // Or same email but different UUIDs
}
```

---

## References

- [User Account Management Spec](SPEC_USER_ACCOUNT_MANAGEMENT.md)
- [Entity Relationships Analysis](RELATIONSHIP_DTO_MAPPING_ANALYSIS.md)
- [Phase 1 Implementation](CHANGELOG_PHASE1_USER_ACCOUNT_MANAGEMENT.md)

---

**Last Updated**: January 17, 2026  
**Maintained By**: Knights & Kings Backend Team
