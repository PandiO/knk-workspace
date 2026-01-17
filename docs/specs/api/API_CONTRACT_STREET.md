# API Contract: Streets

**Source**: `spec/api/swagger.json`  
**Entity**: Street

## Read Endpoints (Implemented)

### GET /api/Streets/{id}
**Operation**: `GetStreetById`  
**Parameters**:
- `id` (path, required): integer (int32)

**Responses**:
- 200: OK (returns `StreetDto`)

### POST /api/Streets/search
**Request Body**: `PagedQueryDto`
```json
{
  "pageNumber": integer,
  "pageSize": integer,
  "searchTerm": string (nullable),
  "sortBy": string (nullable),
  "sortDescending": boolean,
  "filters": object (nullable)
}
```

**Responses**:
- 200: OK (returns `StreetListDtoPagedResultDto`)

## Write Endpoints (NOT Implemented - Out of Scope)

### GET /api/Streets
Returns all streets (unfiltered list)  
**Status**: Not implemented (use search instead)

### POST /api/Streets
Create new street  
**Status**: NOT IMPLEMENTED (write operation - out of scope for READ-ONLY migration)

### PUT /api/Streets/{id}
Update existing street  
**Status**: NOT IMPLEMENTED (write operation - out of scope for READ-ONLY migration)

### DELETE /api/Streets/{id}
Delete street  
**Status**: NOT IMPLEMENTED (write operation - out of scope for READ-ONLY migration)

## Schemas

### StreetDto (Detail)
```json
{
  "id": integer (int32, nullable),
  "name": string (nullable),
  "districtIds": array of integer (int32, nullable),
  "districts": array of StreetDistrictDto (nullable),
  "structures": array of StreetStructureDto (nullable)
}
```

**Properties**:
- `id` (integer, nullable): Unique identifier
- `name` (string, nullable): Street name
- `districtIds` (array of integer, nullable): IDs of districts this street belongs to
- `districts` (array of StreetDistrictDto, nullable): Embedded district information
- `structures` (array of StreetStructureDto, nullable): Structures on this street

### StreetListDto (Summary)
```json
{
  "id": integer (int32, nullable),
  "name": string (nullable)
}
```

**Properties**:
- `id` (integer, nullable): Unique identifier
- `name` (string, nullable): Street name

### StreetListDtoPagedResultDto
```json
{
  "items": array of StreetListDto (nullable),
  "totalCount": integer (int32),
  "pageNumber": integer (int32),
  "pageSize": integer (int32)
}
```

**Properties**:
- `items` (array of StreetListDto, nullable): List items for current page
- `totalCount` (integer): Total number of items across all pages
- `pageNumber` (integer): Current page number (1-based)
- `pageSize` (integer): Number of items per page

### StreetDistrictDto (Embedded)
```json
{
  "id": integer (int32, nullable),
  "name": string (nullable),
  "description": string (nullable),
  "allowEntry": boolean (nullable),
  "allowExit": boolean (nullable),
  "wgRegionId": string (nullable)
}
```

**Properties**:
- `id` (integer, nullable): District ID
- `name` (string, nullable): District name
- `description` (string, nullable): District description
- `allowEntry` (boolean, nullable): Entry allowed flag (READ-ONLY display)
- `allowExit` (boolean, nullable): Exit allowed flag (READ-ONLY display)
- `wgRegionId` (string, nullable): WorldGuard region ID (READ-ONLY display)

### StreetStructureDto (Embedded)
```json
{
  "id": integer (int32, nullable),
  "name": string (nullable),
  "description": string (nullable),
  "houseNumber": integer (int32, nullable),
  "districtId": integer (int32, nullable)
}
```

**Properties**:
- `id` (integer, nullable): Structure ID
- `name` (string, nullable): Structure name
- `description` (string, nullable): Structure description
- `houseNumber` (integer, nullable): House number on street
- `districtId` (integer, nullable): District ID this structure belongs to

## Notes

- All fields are nullable as per Swagger schema
- `wgRegionId` in `StreetDistrictDto` is for READ-ONLY display (no region creation/update)
- No create/update DTOs exist in the API
- Search endpoint uses POST with `PagedQueryDto` body (standard pattern)
