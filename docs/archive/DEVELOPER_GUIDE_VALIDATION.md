# Developer Guide: Adding Account Validation Rules

**Author**: Knights & Kings Development Team  
**Created**: January 17, 2026  
**Status**: Active  

This guide explains how to add new validation rules to the user account management system.

---

## Table of Contents

1. [Overview](#overview)
2. [Validation Architecture](#validation-architecture)
3. [Adding Password Validation Rules](#adding-password-validation-rules)
4. [Adding User Creation Validation Rules](#adding-user-creation-validation-rules)
5. [Adding Email Validation Rules](#adding-email-validation-rules)
6. [Adding Custom Field Validators](#adding-custom-field-validators)
7. [Testing Your Validators](#testing-your-validators)
8. [Best Practices](#best-practices)

---

## Overview

The validation system follows a layered approach:

```
Controller → Service Layer → Validation Services → Repository
     ↓             ↓                ↓                    ↓
  DTOs      Business Logic    Validation Logic     Data Access
```

**Key Principles:**
- Validation happens in the **Service Layer** before data reaches the repository
- Password validation is handled by `PasswordService`
- User creation validation is handled by `UserService.ValidateUserCreationAsync`
- All validation methods return tuples: `(bool IsValid, string? ErrorMessage)`

---

## Validation Architecture

### Current Validators

| Validator | Location | Purpose |
|-----------|----------|---------|
| `PasswordService.ValidatePasswordAsync` | `Services/PasswordService.cs` | Password strength, length, blacklist |
| `UserService.ValidateUserCreationAsync` | `Services/UserService.cs` | Username, email, UUID uniqueness, password |
| `UserService.IsValidEmail` | `Services/UserService.cs` | Email format validation |

### Validation Flow

```
1. Controller receives request
2. Controller calls Service.ValidateXAsync()
3. Service performs validation checks
4. Service returns (bool IsValid, string? Error)
5. Controller returns 400 BadRequest if invalid
6. Controller proceeds with operation if valid
```

---

## Adding Password Validation Rules

### Location: `Services/PasswordService.cs`

**Example: Add Minimum Uppercase Letter Requirement**

```csharp
public async Task<(bool IsValid, string? Error)> ValidatePasswordAsync(string password)
{
    if (string.IsNullOrEmpty(password))
    {
        return (false, "Password is required.");
    }

    // Existing: Length check
    if (password.Length < 8)
    {
        return (false, "Password must be at least 8 characters long.");
    }

    if (password.Length > 128)
    {
        return (false, "Password must not exceed 128 characters.");
    }

    // NEW: Minimum uppercase letter requirement
    if (!password.Any(char.IsUpper))
    {
        return (false, "Password must contain at least one uppercase letter.");
    }

    // Existing: Weak password blacklist
    if (WeakPasswords.Contains(password))
    {
        return (false, "This password is too common. Please choose a stronger password.");
    }

    // Existing: Common pattern detection
    if (IsCommonPattern(password))
    {
        return (false, "Password contains a common pattern. Please choose a more unique password.");
    }

    return (true, null);
}
```

**Configuration Option:**

You can make validation rules configurable via `appsettings.json`:

```json
{
  "Security": {
    "BcryptRounds": 10,
    "PasswordPolicy": {
      "MinLength": 8,
      "MaxLength": 128,
      "RequireUppercase": true,
      "RequireLowercase": false,
      "RequireDigit": false,
      "RequireSpecialChar": false
    }
  }
}
```

Then read in `PasswordService` constructor:

```csharp
private readonly int _minLength;
private readonly bool _requireUppercase;

public PasswordService(IConfiguration configuration)
{
    _bcryptRounds = configuration.GetValue<int>("Security:BcryptRounds", 10);
    _minLength = configuration.GetValue<int>("Security:PasswordPolicy:MinLength", 8);
    _requireUppercase = configuration.GetValue<bool>("Security:PasswordPolicy:RequireUppercase", false);
}
```

---

## Adding User Creation Validation Rules

### Location: `Services/UserService.cs`

**Example: Add Username Profanity Filter**

```csharp
public async Task<(bool IsValid, string? ErrorMessage)> ValidateUserCreationAsync(UserCreateDto dto)
{
    if (dto == null)
    {
        return (false, "User data is required.");
    }

    // Validate username
    if (string.IsNullOrWhiteSpace(dto.Username))
    {
        return (false, "Username is required.");
    }

    if (dto.Username.Length < 3 || dto.Username.Length > 50)
    {
        return (false, "Username must be between 3 and 50 characters.");
    }

    // NEW: Profanity filter
    if (ContainsProfanity(dto.Username))
    {
        return (false, "Username contains inappropriate language.");
    }

    // Check username uniqueness
    var (usernameTaken, _) = await CheckUsernameTakenAsync(dto.Username);
    if (usernameTaken)
    {
        return (false, "Username is already taken.");
    }

    // ... rest of validation
    
    return (true, null);
}

// Helper method
private bool ContainsProfanity(string text)
{
    var profanityList = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
    {
        // Add profanity words here
        "badword1", "badword2"
    };

    return profanityList.Any(word => text.Contains(word, StringComparison.OrdinalIgnoreCase));
}
```

**Better Approach: External Profanity Service**

```csharp
// Add to constructor
private readonly IProfanityFilterService _profanityFilter;

public UserService(
    IUserRepository repo, 
    IMapper mapper,
    IPasswordService passwordService,
    ILinkCodeService linkCodeService,
    IProfanityFilterService profanityFilter)
{
    _repo = repo;
    _mapper = mapper;
    _passwordService = passwordService;
    _linkCodeService = linkCodeService;
    _profanityFilter = profanityFilter;
}

// In validation
if (await _profanityFilter.ContainsProfanityAsync(dto.Username))
{
    return (false, "Username contains inappropriate language.");
}
```

---

## Adding Email Validation Rules

### Current Implementation: `Services/UserService.cs`

The current email validator uses basic regex. You can enhance it:

**Example: Add Email Domain Whitelist**

```csharp
private static readonly HashSet<string> AllowedEmailDomains = new(StringComparer.OrdinalIgnoreCase)
{
    "gmail.com",
    "yahoo.com",
    "outlook.com",
    "hotmail.com",
    "knk-game.com"
};

private bool IsValidEmail(string email)
{
    if (string.IsNullOrWhiteSpace(email))
    {
        return false;
    }

    try
    {
        var addr = new System.Net.Mail.MailAddress(email);
        
        // Basic format check
        if (addr.Address != email)
        {
            return false;
        }

        // NEW: Domain whitelist check
        var domain = email.Split('@').LastOrDefault();
        if (domain == null || !AllowedEmailDomains.Contains(domain))
        {
            return false;
        }

        return true;
    }
    catch
    {
        return false;
    }
}
```

**Example: Add Disposable Email Detection**

```csharp
private static readonly HashSet<string> DisposableEmailDomains = new(StringComparer.OrdinalIgnoreCase)
{
    "tempmail.com",
    "guerrillamail.com",
    "10minutemail.com",
    "mailinator.com"
};

private bool IsValidEmail(string email)
{
    // ... existing validation ...

    // NEW: Block disposable emails
    var domain = email.Split('@').LastOrDefault();
    if (domain != null && DisposableEmailDomains.Contains(domain))
    {
        return false;
    }

    return true;
}
```

---

## Adding Custom Field Validators

### Example: Add Age Verification

**Step 1: Add field to DTO**

```csharp
// Dtos/UserDtos.cs
public class UserCreateDto
{
    public string Username { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? Password { get; set; }
    public string? PasswordConfirmation { get; set; }
    public string? Uuid { get; set; }
    
    // NEW: Age field
    public DateTime? DateOfBirth { get; set; }
}
```

**Step 2: Add validation in UserService**

```csharp
public async Task<(bool IsValid, string? ErrorMessage)> ValidateUserCreationAsync(UserCreateDto dto)
{
    // ... existing validations ...

    // NEW: Age validation (must be 13+)
    if (dto.DateOfBirth.HasValue)
    {
        var age = CalculateAge(dto.DateOfBirth.Value);
        if (age < 13)
        {
            return (false, "You must be at least 13 years old to create an account.");
        }
    }

    return (true, null);
}

private int CalculateAge(DateTime dateOfBirth)
{
    var today = DateTime.UtcNow;
    var age = today.Year - dateOfBirth.Year;
    if (dateOfBirth.Date > today.AddYears(-age)) age--;
    return age;
}
```

**Step 3: Update Entity (if persisting)**

```csharp
// Models/User.cs
public class User
{
    // ... existing fields ...
    
    public DateTime? DateOfBirth { get; set; }
}
```

**Step 4: Update Migration**

```bash
dotnet ef migrations add AddDateOfBirthToUser
dotnet ef database update
```

---

## Testing Your Validators

### Unit Tests Location: `Tests/Services/UserServiceTests.cs`

**Example: Test Age Validation**

```csharp
[Fact]
public async Task ValidateUserCreationAsync_WhenUnder13_ShouldFail()
{
    // Arrange
    var dto = new UserCreateDto
    {
        Username = "youngplayer",
        Email = "young@example.com",
        Password = "SecurePass123",
        PasswordConfirmation = "SecurePass123",
        DateOfBirth = DateTime.UtcNow.AddYears(-10) // 10 years old
    };

    // Act
    var (isValid, error) = await _userService.ValidateUserCreationAsync(dto);

    // Assert
    Assert.False(isValid);
    Assert.Contains("must be at least 13 years old", error);
}

[Fact]
public async Task ValidateUserCreationAsync_When13OrOlder_ShouldPass()
{
    // Arrange
    var dto = new UserCreateDto
    {
        Username = "teenplayer",
        Email = "teen@example.com",
        Password = "SecurePass123",
        PasswordConfirmation = "SecurePass123",
        DateOfBirth = DateTime.UtcNow.AddYears(-14) // 14 years old
    };

    _mockUserRepository
        .Setup(r => r.IsUsernameTakenAsync(dto.Username, null))
        .ReturnsAsync(false);
    _mockUserRepository
        .Setup(r => r.IsEmailTakenAsync(dto.Email, null))
        .ReturnsAsync(false);

    // Act
    var (isValid, error) = await _userService.ValidateUserCreationAsync(dto);

    // Assert
    Assert.True(isValid);
    Assert.Null(error);
}
```

### Integration Tests Location: `Tests/Integration/`

**Example: Test Complete Flow with New Validation**

```csharp
[Fact]
public async Task CreateUser_WithUnder13_ShouldReturn400()
{
    // Arrange
    var createDto = new UserCreateDto
    {
        Username = "youngplayer",
        Email = "young@example.com",
        Password = "SecurePass123",
        PasswordConfirmation = "SecurePass123",
        DateOfBirth = DateTime.UtcNow.AddYears(-10)
    };

    // Act
    var response = await _client.PostAsJsonAsync("/api/users", createDto);

    // Assert
    Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    var error = await response.Content.ReadFromJsonAsync<ErrorResponse>();
    Assert.Equal("ValidationFailed", error.Error);
    Assert.Contains("13 years old", error.Message);
}
```

---

## Best Practices

### 1. Keep Validation Logic in Service Layer

❌ **BAD: Validation in Controller**
```csharp
[HttpPost]
public async Task<IActionResult> Create([FromBody] UserCreateDto user)
{
    if (user.Username.Length < 3)
    {
        return BadRequest("Username too short");
    }
    // ...
}
```

✅ **GOOD: Validation in Service**
```csharp
[HttpPost]
public async Task<IActionResult> Create([FromBody] UserCreateDto user)
{
    var (isValid, error) = await _service.ValidateUserCreationAsync(user);
    if (!isValid)
    {
        return BadRequest(new { error = "ValidationFailed", message = error });
    }
    // ...
}
```

### 2. Return Descriptive Error Messages

❌ **BAD: Generic Errors**
```csharp
return (false, "Invalid data");
```

✅ **GOOD: Specific Errors**
```csharp
return (false, "Username must be between 3 and 50 characters.");
```

### 3. Make Validators Testable

- Use dependency injection for external services
- Keep helper methods pure (no side effects)
- Use configuration for thresholds

### 4. Consider Performance

- Validate cheap operations first (null checks, length)
- Validate expensive operations last (database lookups, API calls)
- Cache blacklists/whitelists in static readonly collections

```csharp
// Good order: cheap → expensive
public async Task<(bool IsValid, string? Error)> ValidateUserCreationAsync(UserCreateDto dto)
{
    // 1. Null check (cheap)
    if (dto == null) return (false, "User data is required.");
    
    // 2. Length check (cheap)
    if (dto.Username.Length < 3) return (false, "Username too short.");
    
    // 3. Pattern check (medium)
    if (ContainsProfanity(dto.Username)) return (false, "Inappropriate username.");
    
    // 4. Database lookup (expensive)
    var (taken, _) = await CheckUsernameTakenAsync(dto.Username);
    if (taken) return (false, "Username taken.");
    
    return (true, null);
}
```

### 5. Consistent Error Format

Always use the same error response structure:

```csharp
return BadRequest(new { error = "ErrorCode", message = "Human-readable message" });
```

Error codes should be:
- `ValidationFailed` - Input validation errors
- `DuplicateUsername` - Username already taken
- `DuplicateEmail` - Email already taken
- `InvalidPassword` - Password doesn't meet policy
- `UserNotFound` - User doesn't exist

---

## Common Validation Patterns

### Pattern 1: Field Length Validation

```csharp
if (string.IsNullOrWhiteSpace(field))
{
    return (false, "Field is required.");
}

if (field.Length < minLength || field.Length > maxLength)
{
    return (false, $"Field must be between {minLength} and {maxLength} characters.");
}
```

### Pattern 2: Uniqueness Validation

```csharp
var (isTaken, conflictingId) = await CheckFieldTakenAsync(field, excludeCurrentUserId);
if (isTaken)
{
    return (false, "Field is already in use.");
}
```

### Pattern 3: Format Validation

```csharp
if (!Regex.IsMatch(field, pattern))
{
    return (false, "Field has invalid format.");
}
```

### Pattern 4: Dependency Validation

```csharp
if (hasPasswordField && string.IsNullOrEmpty(passwordConfirmation))
{
    return (false, "Password confirmation is required when setting a password.");
}

if (password != passwordConfirmation)
{
    return (false, "Password and confirmation do not match.");
}
```

---

## Validation Checklist

When adding a new validation rule:

- [ ] Determine correct layer (Service > Repository > Controller)
- [ ] Write validation method returning `(bool IsValid, string? Error)`
- [ ] Add unit tests for valid and invalid cases
- [ ] Add integration test for full workflow
- [ ] Update error handling in controller
- [ ] Document the rule in this guide
- [ ] Update Swagger documentation with new error responses
- [ ] Consider making rule configurable (appsettings.json)
- [ ] Verify performance impact (especially for database calls)

---

## Additional Resources

- [OWASP Password Guidelines](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [User Account Management Spec](SPEC_USER_ACCOUNT_MANAGEMENT.md)
- [Testing Guide](README_PHASE_5_TESTING.md)

---

**Last Updated**: January 17, 2026  
**Maintained By**: Knights & Kings Backend Team
