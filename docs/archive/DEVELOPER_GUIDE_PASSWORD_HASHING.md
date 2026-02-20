# Developer Guide: Password Hashing & Security

**Author**: Knights & Kings Development Team  
**Created**: January 17, 2026  
**Status**: Active  

This document explains the password hashing implementation and security approach for the Knights & Kings user account management system.

---

## Table of Contents

1. [Overview](#overview)
2. [Why bcrypt?](#why-bcrypt)
3. [Implementation Details](#implementation-details)
4. [Configuration](#configuration)
5. [Security Considerations](#security-considerations)
6. [Password Policy](#password-policy)
7. [Migration & Upgrades](#migration--upgrades)
8. [Common Operations](#common-operations)
9. [Testing](#testing)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The Knights & Kings application uses **bcrypt** for password hashing, following OWASP 2023 guidelines for secure password storage.

**Key Features:**
- ✅ One-way hashing (cannot be reversed)
- ✅ Adaptive work factor (configurable rounds)
- ✅ Built-in salt generation (unique per password)
- ✅ Slow by design (resistant to brute-force attacks)
- ✅ Industry-standard algorithm (bcrypt since 1999)

**Library Used:** `BCrypt.Net-Next` (maintained .NET bcrypt implementation)

---

## Why bcrypt?

### Comparison of Hashing Algorithms

| Algorithm | Speed | Salt | Work Factor | Status | Recommendation |
|-----------|-------|------|-------------|--------|----------------|
| MD5 | Very Fast | No | No | ❌ Broken | Never use |
| SHA-1 | Very Fast | No | No | ❌ Broken | Never use |
| SHA-256 | Fast | Manual | No | ⚠️ Not ideal | Only with PBKDF2 |
| PBKDF2 | Configurable | Yes | Yes | ✅ Acceptable | Good alternative |
| bcrypt | Slow | Yes | Yes | ✅ Recommended | **Current choice** |
| scrypt | Slower | Yes | Yes | ✅ Excellent | Memory-intensive |
| Argon2 | Slowest | Yes | Yes | ✅ Best | Future consideration |

### Why We Chose bcrypt

1. **Battle-tested**: Used by major platforms for 20+ years
2. **Adaptive**: Can increase work factor as hardware improves
3. **Simple API**: Easy to use correctly
4. **Widely supported**: Available in all major languages
5. **OWASP recommended**: Listed in OWASP ASVS 4.0
6. **Good balance**: Security vs. performance vs. complexity

**Future Consideration:** Argon2 is the winner of the Password Hashing Competition (2015) and may be adopted in future if bcrypt proves insufficient.

---

## Implementation Details

### Location: `Services/PasswordService.cs`

```csharp
using BCrypt.Net;

public class PasswordService : IPasswordService
{
    private readonly int _bcryptRounds;

    public PasswordService(IConfiguration configuration)
    {
        // Read from appsettings.json, default to 10 rounds
        _bcryptRounds = configuration.GetValue<int>("Security:BcryptRounds", 10);
        
        // Validate bcrypt rounds (4-31 valid range)
        if (_bcryptRounds < 4 || _bcryptRounds > 31)
        {
            throw new ArgumentException("BcryptRounds must be between 4 and 31");
        }
    }

    public Task<string> HashPasswordAsync(string password)
    {
        if (string.IsNullOrEmpty(password))
        {
            throw new ArgumentException("Password cannot be null or empty", nameof(password));
        }

        // Generate hash with configured work factor
        var hash = BCrypt.Net.BCrypt.HashPassword(password, _bcryptRounds);
        return Task.FromResult(hash);
    }

    public Task<bool> VerifyPasswordAsync(string plainPassword, string hash)
    {
        if (string.IsNullOrEmpty(plainPassword) || string.IsNullOrEmpty(hash))
        {
            return Task.FromResult(false);
        }

        try
        {
            var isValid = BCrypt.Net.BCrypt.Verify(plainPassword, hash);
            return Task.FromResult(isValid);
        }
        catch
        {
            // Invalid hash format or verification error
            return Task.FromResult(false);
        }
    }
}
```

### How bcrypt Works

```
Input: "MySecurePassword123"
       ↓
1. Generate unique salt (automatic)
   Salt: "$2a$10$N9qo8uLOickgx2ZMRZoMye"
       ↓
2. Apply bcrypt algorithm with work factor (10 rounds = 2^10 = 1024 iterations)
   Hash: "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"
       ↓
3. Store in database
   PasswordHash: "$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy"
```

**Hash Format Breakdown:**

```
$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy
 │   │  │                      │
 │   │  │                      └─ Hash (31 chars)
 │   │  └─ Salt (22 chars)
 │   └─ Work factor (10 = 2^10 iterations)
 └─ Algorithm version (2a = bcrypt)
```

---

## Configuration

### appsettings.json

```json
{
  "Security": {
    "BcryptRounds": 10
  }
}
```

### Choosing Work Factor (Rounds)

| Rounds | Iterations | Time (approx) | Use Case |
|--------|------------|---------------|----------|
| 4 | 16 | <1ms | ❌ Testing only |
| 8 | 256 | ~10ms | ⚠️ Minimum for production |
| 10 | 1,024 | ~70ms | ✅ **Current setting** |
| 12 | 4,096 | ~300ms | ✅ High security |
| 14 | 16,384 | ~1.2s | ⚠️ May impact UX |
| 16 | 65,536 | ~5s | ❌ Too slow for login |

**Recommendation: 10-12 rounds**

- **10 rounds**: Good balance for most applications (current default)
- **12 rounds**: Better security, acceptable delay (~300ms)
- **14+ rounds**: Only for extremely sensitive applications

### When to Increase Rounds

Increase work factor when:
- Hardware becomes significantly faster (Moore's Law)
- Your threat model changes (handling more sensitive data)
- Login times are well below 200ms (you have room for more security)

**Do NOT increase if:**
- Users complain about slow logins
- Your server is under heavy load
- You don't have caching/rate limiting in place

---

## Security Considerations

### 1. Never Store Plain Passwords

❌ **NEVER DO THIS:**
```csharp
user.Password = "MyPassword123"; // WRONG!
await _repo.UpdateUserAsync(user);
```

✅ **ALWAYS DO THIS:**
```csharp
var hash = await _passwordService.HashPasswordAsync("MyPassword123");
user.PasswordHash = hash;
await _repo.UpdateUserAsync(user);
```

### 2. Never Log Passwords

❌ **BAD:**
```csharp
_logger.LogInformation($"User {username} logged in with password {password}");
```

✅ **GOOD:**
```csharp
_logger.LogInformation($"User {username} logged in successfully");
```

### 3. Never Expose Hashes in API Responses

The `UserDto` explicitly ignores `PasswordHash`:

```csharp
// Mapping/UserMappingProfile.cs
CreateMap<User, UserDto>()
    .ForMember(dest => dest.PasswordHash, opt => opt.Ignore());
```

### 4. Use HTTPS for Transmission

Passwords must be transmitted over HTTPS:
- Plain passwords are sent from client to server
- HTTPS encrypts the transmission
- Server immediately hashes upon receipt

### 5. Rate Limiting

Implement rate limiting to prevent brute-force attacks:

```csharp
// Example: Limit login attempts
[RateLimit(MaxRequests = 5, TimeWindowSeconds = 60)]
[HttpPost("login")]
public async Task<IActionResult> Login([FromBody] LoginDto dto)
{
    // Login logic
}
```

### 6. Password Reset Security

**NEVER** send passwords via email:

❌ **BAD:**
```
Subject: Password Reset
Your new password is: TempPass123
```

✅ **GOOD:**
```
Subject: Password Reset
Click this link to reset your password: 
https://knk.com/reset-password?token=abc123
(Link expires in 1 hour)
```

---

## Password Policy

Following **OWASP 2023 Guidelines**: *Length over complexity*

### Current Policy

- **Minimum length**: 8 characters
- **Maximum length**: 128 characters
- **Complexity**: NOT enforced (no uppercase/lowercase/numbers/symbols required)
- **Weak password blacklist**: Top 100 most common passwords blocked
- **Pattern detection**: Common patterns blocked (e.g., "password123", "qwerty123")

### Rationale

**Length > Complexity:**
- `correcthorsebatterystaple` (25 chars, all lowercase) = **STRONG**
- `P@s5w0rd` (8 chars, complex) = **WEAK**

**Why We Don't Enforce Complexity:**
- Users create predictable patterns (`Password1!`, `Welcome1!`)
- Long passphrases are more secure and easier to remember
- bcrypt makes brute-force attacks computationally expensive regardless

**Weak Password Blacklist:**

```csharp
private static readonly HashSet<string> WeakPasswords = new(StringComparer.OrdinalIgnoreCase)
{
    "123456", "password", "12345678", "qwerty", "123456789",
    "12345", "1234", "111111", "1234567", "dragon",
    "admin", "admin123", "root", "welcome", "password123",
    // ... +80 more
};
```

### Validation Flow

```
Password: "MyPassword123"
    ↓
1. Check length (8-128) → ✅ Pass
    ↓
2. Check weak password list → ✅ Pass (not in list)
    ↓
3. Check common patterns → ✅ Pass
    ↓
4. Hash with bcrypt → Store
```

---

## Migration & Upgrades

### Migrating from Another Hash Algorithm

If you're migrating from MD5/SHA1/SHA256:

```csharp
public async Task MigratePasswordAsync(int userId, string plainPassword)
{
    // 1. Verify old password using old algorithm
    var user = await _repo.GetByIdAsync(userId);
    if (!VerifyOldHash(plainPassword, user.PasswordHash))
    {
        throw new UnauthorizedAccessException("Invalid password");
    }

    // 2. Hash with bcrypt
    var newHash = await _passwordService.HashPasswordAsync(plainPassword);

    // 3. Update to bcrypt hash
    await _repo.UpdatePasswordHashAsync(userId, newHash);
}

private bool VerifyOldHash(string password, string hash)
{
    // Example for SHA256
    using var sha256 = SHA256.Create();
    var hashBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
    var oldHash = Convert.ToBase64String(hashBytes);
    return oldHash == hash;
}
```

**Strategy: Lazy Migration**
- Don't migrate all passwords at once
- Migrate each user's password on their next successful login
- Keep old hash verification code until all users have migrated

### Upgrading Work Factor

Increase work factor over time as hardware improves:

```csharp
public async Task UpgradeHashIfNeededAsync(int userId, string plainPassword)
{
    var user = await _repo.GetByIdAsync(userId);
    
    // Check if hash was created with old work factor
    var currentRounds = ExtractWorkFactor(user.PasswordHash);
    if (currentRounds < _bcryptRounds)
    {
        // Rehash with new work factor
        var newHash = await _passwordService.HashPasswordAsync(plainPassword);
        await _repo.UpdatePasswordHashAsync(userId, newHash);
    }
}

private int ExtractWorkFactor(string hash)
{
    // Format: $2a$10$...
    // Extract "10" from position 4-5
    return int.Parse(hash.Substring(4, 2));
}
```

---

## Common Operations

### 1. Register New User (Hash Password)

```csharp
// UserService.cs
public async Task<UserDto> CreateAsync(UserCreateDto userDto)
{
    // Hash password before storing
    var user = _mapper.Map<User>(userDto);
    
    if (!string.IsNullOrEmpty(userDto.Password))
    {
        user.PasswordHash = await _passwordService.HashPasswordAsync(userDto.Password);
    }
    
    user.CreatedAt = DateTime.UtcNow;
    await _repo.AddUserAsync(user);
    return _mapper.Map<UserDto>(user);
}
```

### 2. Login (Verify Password)

```csharp
// AuthService.cs (not yet implemented)
public async Task<UserDto?> LoginAsync(string email, string password)
{
    var user = await _repo.GetByEmailAsync(email);
    if (user == null)
    {
        return null; // Don't reveal if user exists
    }

    if (string.IsNullOrEmpty(user.PasswordHash))
    {
        return null; // Account not linked with password yet
    }

    var isValid = await _passwordService.VerifyPasswordAsync(password, user.PasswordHash);
    if (!isValid)
    {
        return null; // Invalid password
    }

    return _mapper.Map<UserDto>(user);
}
```

### 3. Change Password

```csharp
// UserService.cs
public async Task ChangePasswordAsync(int userId, string currentPassword, string newPassword, string passwordConfirmation)
{
    var user = await _repo.GetByIdAsync(userId);
    if (user == null)
    {
        throw new KeyNotFoundException($"User with ID {userId} not found.");
    }

    // Verify current password
    if (!string.IsNullOrEmpty(user.PasswordHash))
    {
        var isValidPassword = await _passwordService.VerifyPasswordAsync(currentPassword, user.PasswordHash);
        if (!isValidPassword)
        {
            throw new UnauthorizedAccessException("Current password is incorrect.");
        }
    }

    // Validate new password
    var (isValid, error) = await _passwordService.ValidatePasswordAsync(newPassword);
    if (!isValid)
    {
        throw new ArgumentException(error ?? "Invalid password.");
    }

    // Hash and update
    var newHash = await _passwordService.HashPasswordAsync(newPassword);
    await _repo.UpdatePasswordHashAsync(userId, newHash);
}
```

### 4. Reset Password (Forgot Password Flow)

```csharp
// Not yet implemented, but should follow this pattern:

// Step 1: Generate reset token
public async Task<string> GeneratePasswordResetTokenAsync(string email)
{
    var user = await _repo.GetByEmailAsync(email);
    if (user == null)
    {
        // Don't reveal if email exists
        return string.Empty;
    }

    var token = GenerateSecureToken();
    await _tokenService.StoreResetTokenAsync(user.Id, token, expiresIn: TimeSpan.FromHours(1));
    
    // Send email with token link
    await _emailService.SendPasswordResetEmailAsync(email, token);
    
    return token;
}

// Step 2: Reset password with token
public async Task ResetPasswordAsync(string token, string newPassword)
{
    var userId = await _tokenService.ValidateResetTokenAsync(token);
    if (userId == null)
    {
        throw new InvalidOperationException("Invalid or expired reset token");
    }

    var newHash = await _passwordService.HashPasswordAsync(newPassword);
    await _repo.UpdatePasswordHashAsync(userId.Value, newHash);
    
    // Invalidate token
    await _tokenService.InvalidateResetTokenAsync(token);
}
```

---

## Testing

### Unit Tests: `Tests/Services/PasswordServiceTests.cs`

```csharp
public class PasswordServiceTests
{
    [Fact]
    public async Task HashPasswordAsync_ShouldGenerateValidBcryptHash()
    {
        // Arrange
        var service = new PasswordService(_mockConfiguration.Object);
        var password = "MySecurePassword123";

        // Act
        var hash = await service.HashPasswordAsync(password);

        // Assert
        Assert.NotNull(hash);
        Assert.StartsWith("$2a$", hash); // bcrypt format
        Assert.Equal(60, hash.Length); // Standard bcrypt hash length
    }

    [Fact]
    public async Task VerifyPasswordAsync_WithCorrectPassword_ShouldReturnTrue()
    {
        // Arrange
        var service = new PasswordService(_mockConfiguration.Object);
        var password = "MySecurePassword123";
        var hash = await service.HashPasswordAsync(password);

        // Act
        var isValid = await service.VerifyPasswordAsync(password, hash);

        // Assert
        Assert.True(isValid);
    }

    [Fact]
    public async Task VerifyPasswordAsync_WithIncorrectPassword_ShouldReturnFalse()
    {
        // Arrange
        var service = new PasswordService(_mockConfiguration.Object);
        var password = "MySecurePassword123";
        var wrongPassword = "WrongPassword456";
        var hash = await service.HashPasswordAsync(password);

        // Act
        var isValid = await service.VerifyPasswordAsync(wrongPassword, hash);

        // Assert
        Assert.False(isValid);
    }

    [Theory]
    [InlineData("short")] // Too short
    [InlineData("123456")] // In blacklist
    [InlineData("password")] // In blacklist
    public async Task ValidatePasswordAsync_WithWeakPassword_ShouldReturnFalse(string password)
    {
        // Arrange
        var service = new PasswordService(_mockConfiguration.Object);

        // Act
        var (isValid, error) = await service.ValidatePasswordAsync(password);

        // Assert
        Assert.False(isValid);
        Assert.NotNull(error);
    }
}
```

---

## Troubleshooting

### Issue: Slow Login Times

**Symptom:** Users complaining about login delays

**Solution:**
1. Check bcrypt rounds in config (should be 10-12)
2. Profile login endpoint performance
3. Consider caching strategies (session tokens, JWT)
4. Reduce rounds if necessary (not below 10)

### Issue: Hash Verification Always Fails

**Possible Causes:**
1. Hash was corrupted during storage/retrieval
2. Different bcrypt library versions (salt format)
3. Encoding issues (UTF-8 vs UTF-16)
4. Hash was not stored correctly (truncated, null)

**Debug Steps:**
```csharp
// Log hash details
_logger.LogDebug($"Hash length: {hash.Length}");
_logger.LogDebug($"Hash format: {hash.Substring(0, 4)}");
_logger.LogDebug($"Hash work factor: {hash.Substring(4, 2)}");
```

### Issue: BCrypt.Net-Next Not Found

**Error:** `Could not load file or assembly 'BCrypt.Net-Next'`

**Solution:**
```bash
dotnet add package BCrypt.Net-Next --version 4.0.3
dotnet restore
```

### Issue: Configuration Not Loading

**Error:** `BcryptRounds must be between 4 and 31`

**Solution:**
Verify `appsettings.json` structure:
```json
{
  "Security": {
    "BcryptRounds": 10  // Must be int, not string
  }
}
```

---

## References

- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [BCrypt.Net-Next Documentation](https://github.com/BcryptNet/bcrypt.net)
- [bcrypt Algorithm (Niels Provos & David Mazières, 1999)](https://www.usenix.org/legacy/publications/library/proceedings/usenix99/provos/provos.pdf)

---

**Last Updated**: January 17, 2026  
**Maintained By**: Knights & Kings Security Team
