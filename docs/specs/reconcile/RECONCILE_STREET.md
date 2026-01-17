# Reconciliation: Street Entity

**Purpose**: Compare legacy Street entity with Web API contract to determine READ-ONLY MVP scope.

**Sources**:
- `spec/api/swagger.json` (Streets endpoints + StreetDto/StreetListDto schemas)
- `spec/api/API_CONTRACT_STREET.md`
- Legacy repo: Not found (`knk-legacy-plugin/spec/SOURCES_STREET.md`, `SPEC_STREET.md`, `LOGIC_CANDIDATES_STREET.md` do not exist)

## Field Reconciliation

| Field | API | Legacy | Status | Notes |
|-------|-----|--------|--------|-------|
| `id` | ✓ (int32, nullable) | ? | CONFIRMED-BY-API | Primary identifier |
| `name` | ✓ (string, nullable) | ? | CONFIRMED-BY-API | Street name |
| `districtIds` | ✓ (array, nullable) | ? | CONFIRMED-BY-API | IDs of associated districts |
| `districts` | ✓ (StreetDistrictDto[], nullable) | ? | CONFIRMED-BY-API | Embedded district info (read-only) |
| `structures` | ✓ (StreetStructureDto[], nullable) | ? | CONFIRMED-BY-API | Structures on this street (read-only) |

**Legend**:
- **CONFIRMED-BY-API**: Field exists in `swagger.json` and will be implemented
- **LEGACY-ONLY**: Field exists in legacy but not in API (not implemented)
- **API-ONLY**: Field exists in API but not in legacy (implemented as-is)
- **TBD**: Unclear; needs further investigation (document in spec/, not in code)

## Endpoint Reconciliation

| Endpoint | API | Legacy | Status | Notes |
|----------|-----|--------|--------|-------|
| GET /api/Streets/{id} | ✓ | ? | CONFIRMED-BY-API | Get street by ID |
| POST /api/Streets/search | ✓ | ? | CONFIRMED-BY-API | Search/list streets (paginated) |
| POST /api/Streets | ✓ | ? | API-ONLY (SKIPPED) | Create - out of scope for READ-ONLY |
| PUT /api/Streets/{id} | ✓ | ? | API-ONLY (SKIPPED) | Update - out of scope for READ-ONLY |
| DELETE /api/Streets/{id} | ✓ | ? | API-ONLY (SKIPPED) | Delete - out of scope for READ-ONLY |

## Domain Logic Candidates

**Note**: Legacy spec files (`SOURCES_STREET.md`, `SPEC_STREET.md`, `LOGIC_CANDIDATES_STREET.md`) not found in `knk-legacy-plugin/spec/`. Business rules unknown.

Potential legacy behaviors to investigate later:
- Street creation workflow (out of scope for READ-ONLY)
- Street-District associations (read-only display for now)
- Structure assignment to streets (read-only display for now)
- Validation rules for street names (TBD - not in API contract)

## MVP Scope (Now): READ-ONLY

**What we implement**:
1. **knk-core**:
   - Domain models: `StreetSummary` (id, name), `StreetDetail` (id, name, districts[], structures[])
   - Port: `StreetsQueryApi` with:
     - `CompletableFuture<Page<StreetSummary>> search(PagedQuery query)`
     - `CompletableFuture<StreetDetail> getById(int id)`

2. **knk-api-client**:
   - DTOs: `StreetListDto`, `StreetDto`, `StreetDistrictDto`, `StreetStructureDto`, `StreetListDtoPagedResultDto`
   - Mappers: DTO → domain
   - Client: `StreetsQueryApiImpl` (OkHttp, async, GET /api/Streets/{id} and POST /api/Streets/search)

3. **knk-paper**:
   - Commands:
     - `/knk streets list [page] [size]` → search
     - `/knk street <id>` → getById
   - Async execution; main-thread scheduling for output

**What we DO NOT implement**:
- Create/update/delete operations
- Street creation workflows
- WorldGuard region creation/updates
- Hybrid web-app/plugin flows
- Any persistence mutations from the plugin

## Future Work (TBD)

- Hybrid create/edit flows (requires ADR approval + design in `spec/CREATE_FLOW_SPLIT_STREETS.md`)
- Street validation rules (if not handled by API)
- Street-District association management (if needed beyond read-only display)
- Integration with legacy `model.street.*` classes (behavior extraction only, not structure copying)

## Notes

- No legacy spec files found; behavior/rules unknown
- API contract is complete for read operations
- All fields in `StreetDto` are nullable
- `districts[]` and `structures[]` are embedded read-only arrays
- `wgRegionId` in `StreetDistrictDto` is for display only (no mutations)
