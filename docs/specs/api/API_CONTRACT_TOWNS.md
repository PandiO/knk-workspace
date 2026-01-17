# API Contract: Towns/Districts/Streets/Structures/Locations

Source of truth: spec/api/swagger.json (OpenAPI 3.0.1).
No fields or endpoints are invented. Anything not present in swagger is marked NOT IN CONTRACT.

---

## Endpoints Summary

Notes:
- Auth/Security: NOT IN CONTRACT (no securitySchemes or auth requirements specified in swagger.json excerpts).
- Regions: No standalone /api/Regions endpoints; region is represented via `wgRegionId` fields on entities.
- Roles: NOT IN CONTRACT for Towns vertical (no roles endpoints or schemas present related to Towns).

### Towns
- GET /api/Towns
  - Request: none
  - Response: 200 OK (schema unspecified in swagger excerpt → NOT IN CONTRACT)
- POST /api/Towns
  - Request: TownDto (application/json, text/json, application/*+json)
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- GET /api/Towns/{id}
  - Path params: `id: integer(int32)` required
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- PUT /api/Towns/{id}
  - Path params: `id: integer(int32)` required
  - Request: TownDto
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- DELETE /api/Towns/{id}
  - Path params: `id: integer(int32)` required
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- POST /api/Towns/search
  - Request: PagedQueryDto
  - Response: 200 OK → content: TownListDtoPagedResultDto (text/plain, application/json, text/json)

### Districts
- GET /api/Districts
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- POST /api/Districts
  - Request: DistrictDto
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- GET /api/Districts/{id}
  - Path params: `id: integer(int32)`
  - Query params (optional filtering of included fields): `townFields`, `streetFields`, `structureFields` (types unspecified in excerpt → NOT IN CONTRACT)
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- PUT /api/Districts/{id}
  - Path params: `id: integer(int32)`
  - Request: DistrictDto
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- DELETE /api/Districts/{id}
  - Path params: `id: integer(int32)`
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- POST /api/Districts/search
  - Request: PagedQueryDto
  - Response: 200 OK → content: DistrictListDtoPagedResultDto (text/plain, application/json, text/json)

### Streets
- GET /api/Streets
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- POST /api/Streets
  - Request: StreetDto
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- GET /api/Streets/{id}
  - Path params: `id: integer(int32)`
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- PUT /api/Streets/{id}
  - Path params: `id: integer(int32)`
  - Request: StreetDto
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- DELETE /api/Streets/{id}
  - Path params: `id: integer(int32)`
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- POST /api/Streets/search
  - Request: PagedQueryDto
  - Response: 200 OK → content: StreetListDtoPagedResultDto

### Structures
- GET /api/Structures
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- POST /api/Structures
  - Request: StructureDto
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- GET /api/Structures/{id}
  - Path params: `id: integer(int32)`
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- PUT /api/Structures/{id}
  - Path params: `id: integer(int32)`
  - Request: StructureDto
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- DELETE /api/Structures/{id}
  - Path params: `id: integer(int32)`
  - Response: 200 OK (schema unspecified → NOT IN CONTRACT)
- POST /api/Structures/search
  - Request: PagedQueryDto
  - Response: 200 OK → content: StructureListDtoPagedResultDto

### Locations (DTOs only)
- No explicit endpoints in provided excerpt for Locations CRUD.
- Location is embedded/linked via `locationId`/`location` in entity DTOs.
- Endpoints for Location are NOT IN CONTRACT (not present in swagger excerpt).

---

## Schemas Summary

Only schemas appearing in swagger.json for the above endpoints are listed. Properties reproduced verbatim with type and nullability; required fields are only those not marked nullable (OpenAPI indicates required array elsewhere — not present in excerpts → treat as optional unless noted).

### TownDto
Properties:
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `description: string, nullable: true`
- `createdAt: string(date-time), nullable: true`
- `allowEntry: boolean, nullable: true`
- `allowExit: boolean, nullable: true`
- `wgRegionId: string, nullable: true`
- `locationId: integer(int32), nullable: true`
- `location: LocationDto`
- `streetIds: array<integer(int32)>, nullable: true`
- `streets: array<TownStreetDto>, nullable: true`
- `districtIds: array<integer(int32)>, nullable: true`
- `districts: array<TownDistrictDto>, nullable: true`

Required: NOT IN CONTRACT (no `required` array provided in excerpt)

### TownListDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `description: string, nullable: true`
- `wgRegionId: string, nullable: true`

### TownListDtoPagedResultDto
- `items: array<TownListDto>, nullable: true`
- `totalCount: integer(int32)`
- `pageNumber: integer(int32)`
- `pageSize: integer(int32)`

### TownStreetDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`

### TownDistrictDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `description: string, nullable: true`
- `allowEntry: boolean, nullable: true`
- `allowExit: boolean, nullable: true`
- `wgRegionId: string, nullable: true`

---

### DistrictDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `description: string, nullable: true`
- `createdAt: string(date-time), nullable: true`
- `allowEntry: boolean, nullable: true`
- `allowExit: boolean, nullable: true`
- `wgRegionId: string, nullable: true`
- `locationId: integer(int32), nullable: true`
- `location: LocationDto`
- `townId: integer(int32)`
- `streetIds: array<integer(int32)>, nullable: true`
- `town: DistrictTownDto`
- `streets: array<DistrictStreetDto>, nullable: true`
- `structures: array<DistrictStructureDto>, nullable: true`

### DistrictListDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `description: string, nullable: true`
- `wgRegionId: string, nullable: true`
- `townId: integer(int32)`
- `townName: string, nullable: true`

### DistrictListDtoPagedResultDto
- `items: array<DistrictListDto>, nullable: true`
- `totalCount: integer(int32)`
- `pageNumber: integer(int32)`
- `pageSize: integer(int32)`

### DistrictStreetDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`

### DistrictStructureDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `description: string, nullable: true`
- `houseNumber: integer(int32), nullable: true`
- `streetId: integer(int32), nullable: true`

### DistrictTownDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `description: string, nullable: true`
- `allowEntry: boolean, nullable: true`
- `allowExit: boolean, nullable: true`
- `wgRegionId: string, nullable: true`
- `locationId: integer(int32), nullable: true`

---

### StreetDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `districtIds: array<integer(int32)>, nullable: true`
- `districts: array<StreetDistrictDto>, nullable: true`
- `structures: array<StreetStructureDto>, nullable: true`

### StreetListDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`

### StreetListDtoPagedResultDto
- `items: array<StreetListDto>, nullable: true`
- `totalCount: integer(int32)`
- `pageNumber: integer(int32)`
- `pageSize: integer(int32)`

### StreetDistrictDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `description: string, nullable: true`
- `allowEntry: boolean, nullable: true`
- `allowExit: boolean, nullable: true`
- `wgRegionId: string, nullable: true`

### StreetStructureDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `description: string, nullable: true`
- `houseNumber: integer(int32), nullable: true`
- `districtId: integer(int32), nullable: true`

---

### StructureDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `description: string, nullable: true`
- `createdAt: string(date-time), nullable: true`
- `allowEntry: boolean, nullable: true`
- `allowExit: boolean, nullable: true`
- `wgRegionId: string, nullable: true`
- `locationId: integer(int32), nullable: true`
- `streetId: integer(int32)`
- `districtId: integer(int32)`
- `houseNumber: integer(int32)`

### StructureListDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `description: string, nullable: true`
- `wgRegionId: string, nullable: true`
- `houseNumber: integer(int32)`
- `streetId: integer(int32)`
- `streetName: string, nullable: true`
- `districtId: integer(int32)`
- `districtName: string, nullable: true`

### StructureListDtoPagedResultDto
- `items: array<StructureListDto>, nullable: true`
- `totalCount: integer(int32)`
- `pageNumber: integer(int32)`
- `pageSize: integer(int32)`

---

### LocationDto
- `id: integer(int32), nullable: true`
- `name: string, nullable: true`
- `x: number(double), nullable: true`
- `y: number(double), nullable: true`
- `z: number(double), nullable: true`
- `yaw: number(float), nullable: true`
- `pitch: number(float), nullable: true`
- `world: string, nullable: true`

### LocationDtoPagedResultDto
- `items: array<LocationDto>, nullable: true`
- `totalCount: integer(int32)`
- `pageNumber: integer(int32)`
- `pageSize: integer(int32)`

---

### PagedQueryDto
- `pageNumber: integer(int32)`
- `pageSize: integer(int32)`
- `searchTerm: string, nullable: true`
- `sortBy: string, nullable: true`
- `sortDescending: boolean`
- `filters: object<string,string>, nullable: true`

---

## Regions & Roles

- Regions: Represented by `wgRegionId` string fields on TownDto, DistrictDto, StructureDto. No standalone Regions endpoints or schemas → NOT IN CONTRACT.
- Roles: No roles-related endpoints or schemas found in provided swagger.json excerpts → NOT IN CONTRACT.

---

## Notes
- Response content types include `text/plain`, `application/json`, `text/json` where specified.
- For endpoints where 200 OK response schema is not specified in the provided swagger excerpt, this document marks "NOT IN CONTRACT".
- Nullability in schemas implies optionality; required arrays were not observed in provided excerpts.
