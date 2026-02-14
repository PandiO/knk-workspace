# Multi-Layer Dependency Resolution v2.0 - API Reference

**Version:** 1.0  
**Date:** February 14, 2026  
**Base URL:** `/api/field-validations`  
**Authentication:** Bearer token (Authorization header)

---

## Table of Contents

1. [Endpoint Summary](#endpoint-summary)
2. [Endpoint Details](#endpoint-details)
3. [DTOs](#dtos)
4. [Error Responses](#error-responses)
5. [Examples](#examples)

---

## Endpoint Summary

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/resolve-dependencies` | Batch resolve dependency values |
| POST | `/validate` | Validate a field against its rules |
| GET | `/rules/{id}` | Get a specific validation rule |
| GET | `/configuration-health/{configId}` | Check configuration for issues |

---

## Endpoint Details

### POST /resolve-dependencies

Batch resolve multiple dependencies for a form configuration.

**Purpose:** Given a form configuration and a list of field IDs, resolve their validation rule dependencies.

**Request:**
```http
POST /api/field-validations/resolve-dependencies
Content-Type: application/json
Authorization: Bearer {token}

{
  "fieldIds": [1, 3, 5],
  "formConfigurationId": 42
}
```

**Request DTO:**
```csharp
public class DependencyResolutionRequest
{
    /// <summary>List of field IDs to resolve dependencies for</summary>
    public List<int> FieldIds { get; set; }

    /// <summary>Form configuration ID (form context)</summary>
    public int FormConfigurationId { get; set; }
}
```

**Response (200 OK):**
```json
{
  "resolvedDependencies": [
    {
      "ruleId": 1,
      "fieldId": 3,
      "status": "resolved",
      "dependencyFieldValue": "town_1",
      "errorDetail": null
    },
    {
      "ruleId": 2,
      "fieldId": 5,
      "status": "pending",
      "dependencyFieldValue": null,
      "errorDetail": "Dependency field 'Town' not populated"
    }
  ],
  "hasErrors": false,
  "errorSummary": null
}
```

**Response DTO:**
```csharp
public class DependencyResolutionResponse
{
    /// <summary>List of resolved dependencies</summary>
    public List<ResolvedDependency> ResolvedDependencies { get; set; }

    /// <summary>Whether any errors occurred</summary>
    public bool HasErrors { get; set; }

    /// <summary>Summary of errors (if any)</summary>
    public string? ErrorSummary { get; set; }
}

public class ResolvedDependency
{
    /// <summary>ID of the validation rule</summary>
    public int RuleId { get; set; }

    /// <summary>ID of the field being validated</summary>
    public int FieldId { get; set; }

    /// <summary>Resolution status: "resolved", "pending", or "error"</summary>
    public string Status { get; set; }

    /// <summary>The resolved dependency value</summary>
    public object? DependencyFieldValue { get; set; }

    /// <summary>Error details if status is "error"</summary>
    public string? ErrorDetail { get; set; }
}
```

**Status Values:**

| Status | Meaning | Example |
|--------|---------|---------|
| **resolved** | Dependency successfully resolved | Town.wgRegionId = "town_1" |
| **pending** | Waiting for dependency field input | User hasn't selected Town yet |
| **error** | Dependency could not be resolved | Property doesn't exist, or circular dependency |

**Response Status Codes:**

| Code | Meaning |
|------|---------|
| 200 | Success - dependencies processed |
| 400 | Bad request - invalid field IDs or config |
| 404 | Form configuration not found |
| 500 | Server error |

**Example cURL:**
```bash
curl -X POST \
  https://api.example.com/api/field-validations/resolve-dependencies \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "fieldIds": [1, 3, 5],
    "formConfigurationId": 42
  }'
```

---

### POST /validate

Validate a single field against its validation rules.

**Purpose:** Execute validation rules for a specific field and get interpolated error messages.

**Request:**
```http
POST /api/field-validations/validate
Content-Type: application/json
Authorization: Bearer {token}

{
  "fieldId": 3,
  "fieldValue": {
    "x": 100,
    "y": 64,
    "z": -200
  },
  "formContext": {
    "Town": {
      "id": 1,
      "wgRegionId": "town_1",
      "name": "Springfield"
    }
  }
}
```

**Request DTO:**
```csharp
public class FieldValidationRequest
{
    /// <summary>Field being validated</summary>
    public int FieldId { get; set; }

    /// <summary>Current value of the field</summary>
    public object? FieldValue { get; set; }

    /// <summary>Current form context (all field values)</summary>
    public Dictionary<string, object> FormContext { get; set; }
}
```

**Response (200 OK):**
```json
{
  "isValid": false,
  "message": "Location (100, 64, -200) is outside Springfield region",
  "placeholders": {
    "coordinates": "(100, 64, -200)",
    "regionName": "Springfield"
  },
  "isBlocking": true
}
```

**Response DTO:**
```csharp
public class FieldValidationResult
{
    /// <summary>Whether validation passed</summary>
    public bool IsValid { get; set; }

    /// <summary>Error message (pre-interpolated)</summary>
    public string? Message { get; set; }

    /// <summary>Original placeholder values (for debugging)</summary>
    public Dictionary<string, string>? Placeholders { get; set; }

    /// <summary>Whether form submission should be blocked</summary>
    public bool IsBlocking { get; set; }
}
```

**Response Status Codes:**

| Code | Meaning |
|------|---------|
| 200 | Validation complete (isValid indicates result) |
| 400 | Bad request - missing required fields |
| 404 | Field not found |
| 500 | Server error |

**Example cURL:**
```bash
curl -X POST \
  https://api.example.com/api/field-validations/validate \
  -H "Authorization: Bearer eyJhbG..." \
  -H "Content-Type: application/json" \
  -d '{
    "fieldId": 3,
    "fieldValue": {"x": 100, "y": 64, "z": -200},
    "formContext": {"Town": {"id": 1, "wgRegionId": "town_1"}}
  }'
```

---

### GET /rules/{id}

Get details of a specific validation rule.

**Purpose:** Retrieve a validation rule with its configuration and dependency information.

**Request:**
```http
GET /api/field-validations/rules/1
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "formConfigurationId": 42,
  "formFieldId": 3,
  "validationType": "LocationInsideRegion",
  "dependencyPath": "Town.wgRegionId",
  "isActive": true,
  "errorMessage": "Location {coordinates} is outside {regionName}",
  "configJson": {
    "checkRadius": 100
  },
  "createdAt": "2026-02-14T10:30:00Z",
  "updatedAt": "2026-02-14T10:30:00Z"
}
```

**Response DTO:**
```csharp
public class FieldValidationRuleDto
{
    public int Id { get; set; }
    public int FormConfigurationId { get; set; }
    public int FormFieldId { get; set; }
    public string ValidationType { get; set; }
    public string? DependencyPath { get; set; }
    public bool IsActive { get; set; }
    public string? ErrorMessage { get; set; }
    public string? ConfigJson { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
```

**Response Status Codes:**

| Code | Meaning |
|------|---------|
| 200 | Rule found |
| 404 | Rule not found |
| 500 | Server error |

---

### GET /configuration-health/{configId}

Perform comprehensive validation of a form configuration.

**Purpose:** Check form configuration for issues (circular dependencies, field ordering, missing properties, etc.).

**Request:**
```http
GET /api/field-validations/configuration-health/42
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "formConfigurationId": 42,
  "isHealthy": false,
  "propertyExistenceIssues": [
    {
      "ruleId": 5,
      "fieldName": "Location",
      "path": "InvalidEntity.property",
      "message": "Entity 'InvalidEntity' not found",
      "suggestion": "Did you mean 'District'?"
    }
  ],
  "fieldOrderingIssues": [
    {
      "ruleId": 3,
      "dependentField": "Location",
      "dependencyField": "Town",
      "message": "Dependency field must come before dependent field",
      "currentOrder": {
        "dependency": "Step 3",
        "dependent": "Step 2"
      }
    }
  ],
  "circularDependencyIssues": [],
  "requiredFieldIssues": [
    {
      "fieldName": "Town",
      "message": "Required by entity but not enforced in form",
      "suggestion": "Mark field as required"
    }
  ],
  "collectionWarnings": [],
  "healthCheckSummary": "1 error, 1 warning. Configuration needs attention."
}
```

**Response DTO:**
```csharp
public class FormConfigurationHealthCheckResult
{
    public int FormConfigurationId { get; set; }
    public bool IsHealthy { get; set; }
    public List<PropertyExistenceIssue> PropertyExistenceIssues { get; set; }
    public List<FieldOrderingIssue> FieldOrderingIssues { get; set; }
    public List<CircularDependencyIssue> CircularDependencyIssues { get; set; }
    public List<RequiredFieldIssue> RequiredFieldIssues { get; set; }
    public List<CollectionWarning> CollectionWarnings { get; set; }
    public string HealthCheckSummary { get; set; }
}

public class PropertyExistenceIssue
{
    public int RuleId { get; set; }
    public string FieldName { get; set; }
    public string Path { get; set; }
    public string Message { get; set; }
    public string? Suggestion { get; set; }
}

public class FieldOrderingIssue
{
    public int RuleId { get; set; }
    public string DependentField { get; set; }
    public string DependencyField { get; set; }
    public string Message { get; set; }
    public OrderInfo CurrentOrder { get; set; }
}

public class CircularDependencyIssue
{
    public int RuleId { get; set; }
    public string Message { get; set; }
    public List<int> InvolvedRuleIds { get; set; }
    public string? Suggestion { get; set; }
}

public class RequiredFieldIssue
{
    public string FieldName { get; set; }
    public string Message { get; set; }
    public string? Suggestion { get; set; }
}

public class CollectionWarning
{
    public int RuleId { get; set; }
    public string FieldName { get; set; }
    public string Message { get; set; }
    public string Feature { get; set; } // e.g., "v2: Collection operators"
}
```

**Response Status Codes:**

| Code | Meaning |
|------|---------|
| 200 | Health check complete |
| 404 | Form configuration not found |
| 500 | Server error |

---

## DTOs

### DependencyResolutionRequest

```json
{
  "fieldIds": [1, 2, 3],
  "formConfigurationId": 42
}
```

### DependencyResolutionResponse

```json
{
  "resolvedDependencies": [
    {
      "ruleId": 1,
      "fieldId": 3,
      "status": "resolved",
      "dependencyFieldValue": "town_1",
      "errorDetail": null
    }
  ],
  "hasErrors": false,
  "errorSummary": null
}
```

### FieldValidationRequest

```json
{
  "fieldId": 3,
  "fieldValue": { "x": 100, "y": 64, "z": -200 },
  "formContext": {
    "Town": { "id": 1, "wgRegionId": "town_1" }
  }
}
```

### FieldValidationResult

```json
{
  "isValid": false,
  "message": "Location (100, 64, -200) is outside town_1 region",
  "placeholders": {
    "coordinates": "(100, 64, -200)",
    "regionName": "town_1"
  },
  "isBlocking": true
}
```

---

## Error Responses

### 400 Bad Request

```json
{
  "error": "BadRequest",
  "message": "Missing required field: fieldId",
  "details": {
    "missingFields": ["fieldId"]
  }
}
```

### 404 Not Found

```json
{
  "error": "NotFound",
  "message": "Form configuration with ID 999 not found"
}
```

### 500 Internal Server Error

```json
{
  "error": "InternalServerError",
  "message": "Error resolving dependencies",
  "traceId": "0HN1GOJM765PR:00000001"
}
```

---

## Examples

### Complete Workflow Example

**1. User loads form:**
```bash
# Frontend calls on form load
POST /api/field-validations/resolve-dependencies
{
  "fieldIds": [1, 2, 3, 4, 5],
  "formConfigurationId": 42
}
```

**2. User selects Town and enters Location:**
```bash
# Frontend calls when Location field changes
POST /api/field-validations/validate
{
  "fieldId": 3,
  "fieldValue": {"x": 100, "y": 64, "z": -200},
  "formContext": {
    "Town": {"id": 1, "wgRegionId": "town_1", "name": "Springfield"},
    "Location": {"x": 100, "y": 64, "z": -200}
  }
}

# Response indicates validation failure with interpolated message
{
  "isValid": false,
  "message": "Location (100, 64, -200) is outside Springfield region",
  "isBlocking": true
}
```

**3. Admin checks configuration health:**
```bash
GET /api/field-validations/configuration-health/42

# Response shows any issues
{
  "isHealthy": true,
  "propertyExistenceIssues": [],
  "fieldOrderingIssues": [],
  ...
}
```

### Error Example

**Invalid dependency path:**
```bash
POST /api/field-validations/resolve-dependencies
{
  "fieldIds": [3],
  "formConfigurationId": 42
}

# Response
{
  "resolvedDependencies": [
    {
      "ruleId": 1,
      "fieldId": 3,
      "status": "error",
      "dependencyFieldValue": null,
      "errorDetail": "Property 'nonExistent' not found on Town. Available: id, name, wgRegionId, ..."
    }
  ],
  "hasErrors": true,
  "errorSummary": "1 resolution error"
}
```

---

## Rate Limiting

The API implements rate limiting to prevent abuse:

```
- 100 requests per minute per API key
- Batch endpoint: additional 10 second timeout for large payloads (100+ rules)
```

Rate limit information is returned in response headers:

```http
HTTP/1.1 200 OK
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1613049060
```

---

## Versioning

This documentation describes **v1.0** of the API.

**Future Versions (v2.0):**
- Multi-hop path support: `Town.District.wgRegionId`
- Collection operators: `Towns[first].wgRegionId`
- Advanced filtering and querying

Current v1.0 clients will continue to work with v2.0 (backward compatible).

---

**API Documentation Version:** 1.0  
**Last Updated:** February 14, 2026  
**Next Review:** August 2026
