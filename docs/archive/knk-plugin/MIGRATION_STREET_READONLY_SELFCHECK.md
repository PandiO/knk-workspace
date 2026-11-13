# Street Entity Migration - READ-ONLY Self-Check

**Status:** Historical (self-check under the superseded [read-only migration rule](MIGRATION_MODE_READONLY.md)) · **Last updated:** 2026-11-13 (moved into knk-workspace, PandiO/knk-workspace#304)

_Moved from `knk-plugin/MIGRATION_STREET_READONLY_SELFCHECK.md` at `b8aa582f7a` ([source](https://github.com/PandiO/knk-plugin/blob/b8aa582f7a/MIGRATION_STREET_READONLY_SELFCHECK.md)). The text below is unchanged apart from links; it was not rewritten._


**Date**: ${new Date().toISOString().split('T')[0]}  
**Migration**: Street entity (TASK A + TASK B)  
**Compliance**: READ-ONLY mode per `docs/MIGRATION_MODE_READONLY.md`

## ✅ READ-ONLY Compliance Verification

### 1. ✅ No create/update/delete methods in ports or implementations

**knk-core/ports/api/StreetsQueryApi.java**:
- ✅ `CompletableFuture<Page<StreetSummary>> search(PagedQuery query)` - READ operation
- ✅ `CompletableFuture<StreetDetail> getById(int id)` - READ operation
- ❌ NO create/update/delete methods

**knk-api-client/impl/StreetsQueryApiImpl.java**:
- ✅ `search(PagedQuery)` → POST /api/Streets/search (search is READ-only)
- ✅ `getById(int)` → GET /api/Streets/{id} (READ-only)
- ❌ NO write methods implemented

### 2. ✅ Only GET and search POST endpoints used

**Endpoints from swagger.json**:
- ✅ `GET /api/Streets/{id}` - Used in `StreetsQueryApiImpl.getById()`
- ✅ `POST /api/Streets/search` - Used in `StreetsQueryApiImpl.search()` (read-only search)
- ❌ `POST /api/Streets` - NOT implemented (create)
- ❌ `PUT /api/Streets/{id}` - NOT implemented (update)
- ❌ `DELETE /api/Streets/{id}` - NOT implemented (delete)

### 3. ✅ No Create/Update DTOs exist

**DTOs created** (all for READ operations):
- `StreetListDto` - summary DTO for list results
- `StreetDto` - detail DTO for getById
- `StreetDistrictDto` - embedded read-only district info
- `StreetStructureDto` - embedded read-only structure info
- `StreetListDtoPagedResultDto` - paged result wrapper

**DTOs NOT created** (would be for write operations):
- ❌ NO StreetCreateDto
- ❌ NO StreetUpdateDto
- ❌ NO StreetCommandDto

### 4. ✅ No world-binding code (WorldGuard, PendingWorldBinding, etc.)

**knk-core/domain/streets**:
- `StreetSummary.java` - Plain data record (id, name)
- `StreetDetail.java` - Plain data record with embedded lists
- `StreetDistrict.java` - Contains `wgRegionId` field but READ-ONLY for display
- `StreetStructure.java` - Plain data record
- ❌ NO WorldGuard region creation/update logic
- ❌ NO PendingWorldBinding references
- ❌ NO Bukkit/Paper imports

**knk-paper/commands/StreetsDebugCommand.java**:
- ✅ READ-only commands: `/knk streets list`, `/knk street <id>`
- ✅ Display-only output (ChatColor formatting)
- ✅ Shows `wgRegionId` but does NOT mutate regions
- ❌ NO region creation commands
- ❌ NO world mutation logic

### 5. ✅ All fields traceable to swagger.json

**StreetListDto** (`spec/api/swagger.json` lines 5537-5546):
- ✅ `id` (integer, nullable)
- ✅ `name` (string, nullable)

**StreetDto** (`spec/api/swagger.json` lines 5515-5536):
- ✅ `id` (integer, nullable)
- ✅ `name` (string, nullable)
- ✅ `districtIds` (array of integer, nullable)
- ✅ `districts` (array of StreetDistrictDto, nullable)
- ✅ `structures` (array of StreetStructureDto, nullable)

**StreetDistrictDto** (`spec/api/swagger.json` lines 5481-5514):
- ✅ `id` (integer, nullable)
- ✅ `name` (string, nullable)
- ✅ `description` (string, nullable)
- ✅ `allowEntry` (boolean, nullable)
- ✅ `allowExit` (boolean, nullable)
- ✅ `wgRegionId` (string, nullable)

**StreetStructureDto** (`spec/api/swagger.json` lines 5547-5560+):
- ✅ `id` (integer, nullable)
- ✅ `name` (string, nullable)
- ✅ `description` (string, nullable)
- ✅ `houseNumber` (integer, nullable)
- ✅ `districtId` (integer, nullable)

**StreetListDtoPagedResultDto** (standard paging pattern from swagger):
- ✅ `items` (array of StreetListDto, nullable)
- ✅ `totalCount` (integer)
- ✅ `pageNumber` (integer)
- ✅ `pageSize` (integer)

---

## 📄 Files Changed/Added

### Documentation (TASK A)
1. `spec/api/API_CONTRACT_STREET.md` - Street API contract from swagger.json
2. `spec/reconcile/RECONCILE_STREET.md` - Street reconciliation doc (no legacy sources found)

### knk-core Module
3. `knk-core/src/main/java/net/knightsandkings/knk/core/domain/streets/StreetSummary.java`
4. `knk-core/src/main/java/net/knightsandkings/knk/core/domain/streets/StreetDistrict.java`
5. `knk-core/src/main/java/net/knightsandkings/knk/core/domain/streets/StreetStructure.java`
6. `knk-core/src/main/java/net/knightsandkings/knk/core/domain/streets/StreetDetail.java`
7. `knk-core/src/main/java/net/knightsandkings/knk/core/ports/api/StreetsQueryApi.java`

### knk-api-client Module
8. `knk-api-client/src/main/java/net/knightsandkings/knk/api/dto/StreetListDto.java`
9. `knk-api-client/src/main/java/net/knightsandkings/knk/api/dto/StreetDistrictDto.java`
10. `knk-api-client/src/main/java/net/knightsandkings/knk/api/dto/StreetStructureDto.java`
11. `knk-api-client/src/main/java/net/knightsandkings/knk/api/dto/StreetDto.java`
12. `knk-api-client/src/main/java/net/knightsandkings/knk/api/dto/StreetListDtoPagedResultDto.java`
13. `knk-api-client/src/main/java/net/knightsandkings/knk/api/mapper/StreetsMapper.java`
14. `knk-api-client/src/main/java/net/knightsandkings/knk/api/impl/StreetsQueryApiImpl.java`
15. `knk-api-client/src/main/java/net/knightsandkings/knk/api/client/KnkApiClient.java` - Added StreetsQueryApi getter + initialization

### knk-paper Module
16. `knk-paper/src/main/java/net/knightsandkings/knk/paper/commands/StreetsDebugCommand.java`
17. `knk-paper/src/main/java/net/knightsandkings/knk/paper/KnKPlugin.java` - Wired StreetsQueryApi
18. `knk-paper/src/main/java/net/knightsandkings/knk/paper/commands/KnkAdminCommand.java` - Registered /knk streets commands

---

## 🏗️ Build Verification

```bash
.\gradlew.bat build -x test
```

**Result**: ✅ BUILD SUCCESSFUL in 3s  
**Modules Compiled**:
- ✅ knk-core
- ✅ knk-api-client
- ✅ knk-paper

**Plugin deployed**: `knk-paper-1.0-SNAPSHOT.jar` → DEV_SERVER_1.21.10/plugins

---

## 🎯 Deliverable Summary

**Street entity migration complete in strict READ-ONLY mode**:
- ✅ All 5 READ-ONLY guardrails verified
- ✅ 18 files created/modified
- ✅ Build successful
- ✅ Commands available: `/knk streets list [page] [size]`, `/knk street <id>`
- ✅ No write operations, no world mutations, no Create/Update DTOs
- ✅ All fields traceable to `spec/api/swagger.json`

**Compliance**: 100% adherent to `docs/MIGRATION_MODE_READONLY.md`
