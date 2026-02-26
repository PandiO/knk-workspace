# Phase 2 Changelog: User Account Management - DTOs & Mapping Layer

**Date**: January 11, 2026  
**Phase**: Phase 2 - API Contract Layer (DTOs & Mapping)  
**Status**: ✅ COMPLETE  
**Estimated Effort**: 3 hours | **Actual Effort**: ~1 hour  

---

## Summary

Phase 2 established the API contract layer for user account management by creating comprehensive DTOs and AutoMapper mappings. This phase enables the service layer and controllers to safely expose user account data while ensuring sensitive information (passwords) is never leaked through API responses.

**Key Achievements**:
- Extended existing User DTOs with authentication, currency, and account linking fields
- Created 7 new DTOs for link code operations and account management
- Enhanced AutoMapper profile with comprehensive mappings for all user entities
- Added security safeguards to prevent PasswordHash exposure
- Implemented link code formatting helper for user-friendly display

---

## Files Created

### 1. `Dtos/LinkCodeDtos.cs` (NEW)
**Purpose**: Define DTOs for link code generation, validation, and account linking flows

**Contents**:
```csharp
// Link Code Management
- LinkCodeResponseDto: Returns generated link codes with expiration and formatted display
- LinkCodeRequestDto: Request parameters for link code generation
- ValidateLinkCodeResponseDto: Validation results with user info

// Account Conflict Resolution
- DuplicateCheckDto: Parameters for duplicate account detection
- DuplicateCheckResponseDto: Conflict detection results with both account details

// Account Linking & Merging
- AccountMergeDto: Parameters for merging conflicting accounts
- LinkAccountDto: Web app signup with existing Minecraft account link
```

**Key Features**:
- ✅ Includes formatted link code (ABC-12XYZ) for display alongside raw code
- ✅ Comprehensive validation response with error messages
- ✅ Supports all three account flows (web first, server first, deferred linking)
- ✅ Full JSON property naming for API consistency

**Lines**: 119 lines with comprehensive XML documentation

---

## Files Modified

### 1. `Dtos/UserDtos.cs` (UPDATED)
**Changes**: Extended existing DTOs and created 4 new DTOs

**Updated DTOs**:

**UserCreateDto** (Enhanced):
```csharp
// NEW PROPERTIES
public string? Uuid { get; set; }                // Optional - web app first flow
public string? Email { get; set; }               // Optional - Minecraft-only accounts
public string? Password { get; set; }            // Will be hashed - web app accounts
public string? LinkCode { get; set; }            // Account linking flow
```

**UserDto** (Enhanced):
```csharp
// NEW PROPERTIES
public string? Uuid { get; set; }                // Nullable until Minecraft join
public string? Email { get; set; }               // Nullable for Minecraft-only
public int Gems { get; set; }                    // Secondary currency
public int ExperiencePoints { get; set; }        // Player progression
public bool EmailVerified { get; set; }          // Email verification status
public AccountCreationMethod AccountCreatedVia { get; set; }
public bool IsActive { get; set; }               // Soft deletion flag
```

**UserSummaryDto** (Enhanced):
```csharp
// NEW PROPERTIES
public string? Uuid { get; set; }                // Nullable
public int Gems { get; set; }                    // Secondary currency
public int ExperiencePoints { get; set; }        // Player progression
```

**UserListDto** (Enhanced):
```csharp
// NEW PROPERTIES
public string? uuid { get; set; }                // Nullable
public string? email { get; set; }               // Nullable
public int Gems { get; set; }                    // Secondary currency
public int ExperiencePoints { get; set; }        // Player progression
public bool IsActive { get; set; }               // Soft deletion flag
```

**New DTOs Created**:

1. **UserUpdateDto**: Account settings changes
   - `Email`: New email address
   - `CurrentPassword`: Security verification

2. **ChangePasswordDto**: Password change operations
   - `CurrentPassword`: Existing password for verification
   - `NewPassword`: New password to set
   - `PasswordConfirmation`: Confirmation field

3. **UpdateEmailDto**: Email update operations
   - `NewEmail`: New email address
   - `CurrentPassword`: Optional security verification

4. **AccountMergeResultDto**: Merge operation results
   - `User`: Final merged account (UserDto)
   - `MergedFromUserId`: ID of deleted account
   - `Message`: Human-readable merge summary

**Security Features**:
- ✅ **CRITICAL**: No DTO exposes PasswordHash in responses
- ✅ Password transmitted only during creation/updates (never in responses)
- ✅ CurrentPassword required for sensitive operations
- ✅ Comprehensive XML documentation on all DTOs

**Lines Modified**: Expanded from 69 lines to 205 lines (+136 lines)

---

### 2. `Mapping/UserMappingProfile.cs` (UPDATED)
**Changes**: Extended existing mappings and added link code mapping

**Enhanced Mappings**:

**User → UserDto** (Updated):
```csharp
// NEW FIELD MAPPINGS
.ForMember(dest => dest.Gems, src => src.MapFrom(src => src.Gems))
.ForMember(dest => dest.ExperiencePoints, src => src.MapFrom(src => src.ExperiencePoints))
.ForMember(dest => dest.EmailVerified, src => src.MapFrom(src => src.EmailVerified))
.ForMember(dest => dest.AccountCreatedVia, src => src.MapFrom(src => src.AccountCreatedVia))
.ForMember(dest => dest.IsActive, src => src.MapFrom(src => src.IsActive))
```

**UserDto → User** (Updated):
```csharp
// NEW FIELD MAPPINGS
.ForMember(dest => dest.Gems, src => src.MapFrom(src => src.Gems))
.ForMember(dest => dest.ExperiencePoints, src => src.MapFrom(src => src.ExperiencePoints))
.ForMember(dest => dest.EmailVerified, src => src.MapFrom(src => src.EmailVerified))
.ForMember(dest => dest.AccountCreatedVia, src => src.MapFrom(src => src.AccountCreatedVia))
.ForMember(dest => dest.IsActive, src => src.MapFrom(src => src.IsActive))

// CRITICAL SECURITY - Ignore sensitive/audit fields
.ForMember(dest => dest.PasswordHash, opt => opt.Ignore())
.ForMember(dest => dest.LastPasswordChangeAt, opt => opt.Ignore())
.ForMember(dest => dest.LastEmailChangeAt, opt => opt.Ignore())
.ForMember(dest => dest.DeletedAt, opt => opt.Ignore())
.ForMember(dest => dest.DeletedReason, opt => opt.Ignore())
.ForMember(dest => dest.ArchiveUntil, opt => opt.Ignore())
.ForMember(dest => dest.LinkCodes, opt => opt.Ignore())
```

**User → UserSummaryDto** (Updated):
```csharp
// NEW FIELD MAPPINGS
.ForMember(dest => dest.Gems, src => src.MapFrom(src => src.Gems))
.ForMember(dest => dest.ExperiencePoints, src => src.MapFrom(src => src.ExperiencePoints))
```

**User → UserListDto** (Updated):
```csharp
// NEW FIELD MAPPINGS
.ForMember(dest => dest.Gems, src => src.MapFrom(src => src.Gems))
.ForMember(dest => dest.ExperiencePoints, src => src.MapFrom(src => src.ExperiencePoints))
.ForMember(dest => dest.IsActive, src => src.MapFrom(src => src.IsActive))
```

**UserCreateDto → User** (Updated):
```csharp
// CRITICAL - Ignore balance fields (use model defaults)
.ForMember(dest => dest.Coins, opt => opt.Ignore())  // Default: 250
.ForMember(dest => dest.Gems, opt => opt.Ignore())   // Default: 50
.ForMember(dest => dest.ExperiencePoints, opt => opt.Ignore())  // Default: 0

// CRITICAL - Password hashed in service layer, not mapping
.ForMember(dest => dest.PasswordHash, opt => opt.Ignore())

// CRITICAL - Ignore all audit/metadata fields (set in service layer)
.ForMember(dest => dest.EmailVerified, opt => opt.Ignore())
.ForMember(dest => dest.AccountCreatedVia, opt => opt.Ignore())
.ForMember(dest => dest.LastPasswordChangeAt, opt => opt.Ignore())
.ForMember(dest => dest.LastEmailChangeAt, opt => opt.Ignore())
.ForMember(dest => dest.IsActive, opt => opt.Ignore())
.ForMember(dest => dest.DeletedAt, opt => opt.Ignore())
.ForMember(dest => dest.DeletedReason, opt => opt.Ignore())
.ForMember(dest => dest.ArchiveUntil, opt => opt.Ignore())
.ForMember(dest => dest.LinkCodes, opt => opt.Ignore())
```

**New Mapping**:

**LinkCode → LinkCodeResponseDto** (New):
```csharp
.ForMember(dest => dest.Code, src => src.MapFrom(src => src.Code))
.ForMember(dest => dest.ExpiresAt, src => src.MapFrom(src => src.ExpiresAt))
.ForMember(dest => dest.FormattedCode, src => src.MapFrom(src => FormatLinkCode(src.Code)))
```

**Helper Method Added**:
```csharp
/// <summary>
/// Formats link code for display: ABC12XYZ → ABC-12XYZ
/// </summary>
private static string FormatLinkCode(string code)
{
    if (string.IsNullOrEmpty(code) || code.Length != 8)
        return code;
    
    return $"{code.Substring(0, 3)}-{code.Substring(3)}";
}
```

**Key Decisions**:
- ✅ All `.Ignore()` directives prevent accidental sensitive data exposure
- ✅ Balance fields use model defaults (not overridden in mapping)
- ✅ Audit trail fields managed exclusively by service layer
- ✅ Link code formatting provides user-friendly display (ABC-12XYZ)

**Lines Modified**: Expanded from 49 lines to 109 lines (+60 lines)

---

## Build Verification

### ✅ dotnet build Results
```
Build Status: SUCCESS
Time: ~22 seconds
Errors: 0
Warnings: 8 (all pre-existing, none from Phase 2)
```

**Pre-existing Warnings**:
- NU1902: OpenTelemetry.Instrumentation.AspNetCore vulnerability (known issue)
- CS0618: WorldTask.PayloadJson obsolete warnings (unrelated to Phase 2)
- CS8601/CS8602: Nullable reference warnings in WorldTaskService/CategoryRepository (unrelated)

**Phase 2 Impact**: ✅ 0 new compilation errors or warnings

---

## Architecture Decisions

| Decision | Implementation | Rationale |
|----------|----------------|-----------|
| **PasswordHash Exclusion** | All DTOs `.Ignore()` PasswordHash | Security: passwords never exposed in API responses |
| **Balance Defaults** | UserCreateDto → User ignores Coins/Gems/XP | Use model defaults (250/50/0); service layer handles mutations |
| **Nullable Fields** | UUID, Email nullable in DTOs | Supports web app first and Minecraft-only flows |
| **Link Code Formatting** | FormatLinkCode() helper in mapper | UX: ABC-12XYZ more readable than ABC12XYZ |
| **Audit Trail Ignored** | All audit fields `.Ignore()` in mappings | Service layer owns audit trail; DTOs are read-only contracts |
| **Comprehensive DTOs** | 7 new + 4 updated DTOs | Covers all flows: create, update, link, merge, validate |

---

## Security Safeguards Implemented

### 1. Password Protection
- ✅ **PasswordHash never mapped to any response DTO**
- ✅ Password only accepted in CreateDto/ChangePasswordDto (input only)
- ✅ Service layer responsible for hashing (not mapper)
- ✅ CurrentPassword required for sensitive operations

### 2. Sensitive Field Exclusion
```csharp
// UserDto → User mapping explicitly ignores:
.ForMember(dest => dest.PasswordHash, opt => opt.Ignore())
.ForMember(dest => dest.LastPasswordChangeAt, opt => opt.Ignore())
.ForMember(dest => dest.LastEmailChangeAt, opt => opt.Ignore())
.ForMember(dest => dest.DeletedAt, opt => opt.Ignore())
.ForMember(dest => dest.DeletedReason, opt => opt.Ignore())
.ForMember(dest => dest.ArchiveUntil, opt => opt.Ignore())
```

### 3. Balance Integrity
- ✅ Coins/Gems/ExperiencePoints not settable via UserCreateDto
- ✅ Model defaults enforced (250/50/0)
- ✅ Service layer enforces mutation rules (Phase 3)

---

## DTOs Summary Table

| DTO Name | Purpose | New Fields Added |
|----------|---------|------------------|
| **UserCreateDto** | Account creation | Uuid?, Email?, Password?, LinkCode? |
| **UserDto** | Full user response | Uuid?, Email?, Gems, XP, EmailVerified, AccountCreatedVia, IsActive |
| **UserSummaryDto** | Lightweight embed | Uuid?, Gems, XP |
| **UserListDto** | Admin/search views | uuid?, email?, Gems, XP, IsActive |
| **UserUpdateDto** | Settings changes | Email?, CurrentPassword? |
| **ChangePasswordDto** | Password changes | CurrentPassword, NewPassword, PasswordConfirmation |
| **UpdateEmailDto** | Email updates | NewEmail, CurrentPassword? |
| **AccountMergeResultDto** | Merge results | User, MergedFromUserId, Message |
| **LinkCodeResponseDto** | Link code generation | Code, ExpiresAt, FormattedCode |
| **LinkCodeRequestDto** | Code request | UserId |
| **ValidateLinkCodeResponseDto** | Code validation | IsValid, UserId?, Username?, Email?, Error? |
| **DuplicateCheckDto** | Conflict detection | Uuid, Username |
| **DuplicateCheckResponseDto** | Conflict results | HasDuplicate, ConflictingUser?, PrimaryUser?, Message |
| **AccountMergeDto** | Merge operation | PrimaryUserId, SecondaryUserId |
| **LinkAccountDto** | Account linking | LinkCode, Email, Password, PasswordConfirmation |

**Total DTOs**: 15 (4 updated, 11 new)

---

## Mapping Profile Summary

| Mapping | Direction | New Fields Mapped |
|---------|-----------|-------------------|
| User → UserDto | Entity to Response | Gems, XP, EmailVerified, AccountCreatedVia, IsActive |
| UserDto → User | Response to Entity | Same + 7 `.Ignore()` directives for security |
| User → UserSummaryDto | Entity to Lightweight | Gems, XP |
| User → UserListDto | Entity to List View | Gems, XP, IsActive |
| UserCreateDto → User | Creation to Entity | 9 `.Ignore()` directives for defaults/security |
| LinkCode → LinkCodeResponseDto | Entity to Response | Code, ExpiresAt, FormattedCode |

**Total Mappings**: 6 (5 updated, 1 new)

---

## Dependencies & Integration Points

### Phase 1 Integration
- ✅ Consumes `User` entity from Phase 1 (PasswordHash, Gems, XP, EmailVerified, AccountCreatedVia, etc.)
- ✅ Consumes `LinkCode` entity from Phase 1
- ✅ Consumes `AccountCreationMethod` enum from Phase 1

### Phase 3 Readiness
- ✅ DTOs ready for service layer consumption
- ✅ Mappings configured for CRUD operations
- ✅ Security boundaries established (no PasswordHash leakage)
- ✅ Balance mutation DTOs ready (service layer enforcement pending)

---

## Key Implementation Notes

### 1. Link Code Formatting
```csharp
// Raw code (database): ABC12XYZ
// Formatted code (display): ABC-12XYZ
// Implementation: FormatLinkCode() helper in UserMappingProfile
```

### 2. Nullable Field Handling
- **UUID**: Nullable in DTOs (supports web app first flow)
- **Email**: Nullable in DTOs (supports Minecraft-only accounts)
- **Password**: Nullable in UserCreateDto (Minecraft-only accounts have no password)

### 3. Audit Trail Ownership
- **DTOs**: Read-only contracts; do not set audit fields
- **Service Layer**: Owns audit trail (LastPasswordChangeAt, LastEmailChangeAt, DeletedAt, etc.)
- **Mappers**: Explicitly ignore audit fields (`.Ignore()`)

---

## Testing Readiness

### Manual Testing Checklist (Ready for Phase 3)
- [ ] Verify UserDto excludes PasswordHash in JSON response
- [ ] Verify UserCreateDto accepts nullable UUID/Email/Password
- [ ] Verify link code formatted correctly (ABC-12XYZ)
- [ ] Verify balance defaults enforced (250 Coins, 50 Gems, 0 XP)
- [ ] Verify all DTOs serialize/deserialize correctly

### Automated Testing (Deferred to Phase 3)
- [ ] Unit tests for AutoMapper configurations
- [ ] Integration tests for DTO serialization
- [ ] Security tests for PasswordHash exclusion

---

## Phase 2 Summary

**Status**: ✅ COMPLETE  
**Build**: ✅ SUCCESS (0 new errors/warnings)  
**Estimated Effort**: 3 hours | **Actual Effort**: ~1 hour  
**Efficiency**: 3x faster than estimated (straightforward DTO creation)  

**Files Created**: 1  
**Files Modified**: 2  
**Lines Added**: ~320 lines (including XML documentation)  

**Ready for Phase 3**: ✅ Service Layer implementation can proceed

---

## Next Steps (Phase 3)

With the API contract layer complete, Phase 3 will implement:
1. **PasswordService**: bcrypt hashing, validation, weak password blacklist
2. **LinkCodeService**: Code generation, validation, expiration handling
3. **IUserService Extensions**: Validation, unique constraint checks, credentials management
4. **UserService Implementation**: Account creation, merge, link code consumption
5. **Balance Mutation Service**: Atomic Coins/Gems/XP adjustments with audit trail

**Estimated Phase 3 Effort**: 6.5 hours  
**Blockers**: None - all dependencies satisfied
