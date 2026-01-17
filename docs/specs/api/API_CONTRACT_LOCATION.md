# API Contract – Location

Bron: spec/api/swagger.json (OpenAPI 3.0.1)

## Endpoints
- GET /api/Locations
- POST /api/Locations (body: LocationDto)
- GET /api/Locations/{id}
- PUT /api/Locations/{id} (body: LocationDto)
- DELETE /api/Locations/{id}
- POST /api/Locations/search (body: PagedQueryDto → returns LocationDtoPagedResultDto)

Gerelateerde entiteiten bevatten Location-velden:
- TownDto.location: LocationDto
- DistrictDto.location: LocationDto
- Domain.Location: Location (server-side schema)

## Schemas

### LocationDto
- id: integer (int32), nullable
- name: string, nullable
- x: number (double), nullable
- y: number (double), nullable
- z: number (double), nullable
- yaw: number (float), nullable
- pitch: number (float), nullable
- world: string, nullable

Opmerking: Alle properties zijn gemarkeerd als nullable in de swagger; er is geen required-lijst gedefinieerd.

### Location (server-side)
- Id: integer (int32)
- Name: string, nullable
- X: number (double)
- Y: number (double)
- Z: number (double)
- Yaw: number (float)
- Pitch: number (float)
- World: string, nullable

Opmerking: In dit schema ontbreken `nullable` markers bij numerieke velden; er is geen expliciete `required`-array aanwezig.

### LocationDtoPagedResultDto
- items: array of LocationDto, nullable
- totalCount: integer (int32)
- pageNumber: integer (int32)
- pageSize: integer (int32)

## Wereld-identificatie
- world: string (naam/id) zoals gepresenteerd in DTO/schemas. Er zijn geen aparte `worldId` of `worldUuid` velden in de swagger.
- Er zijn geen `serverId` of `worldUuid` properties gespecificeerd.

## Required vs Optional
- Voor LocationDto zijn alle velden `nullable: true` volgens swagger.
- Endpoints specificeren geen aanvullende `required` validatie voor DTO-velden in de contract-definitie.

## Gebruik in andere DTOs
- TownDto: `locationId` (integer, nullable) + `location` (LocationDto)
- DistrictDto: `locationId` (integer, nullable) + `location` (LocationDto)
- Domain: `LocationId` (integer, nullable) + `Location` (Location)

Bovenstaande is direct overgenomen uit spec/api/swagger.json zonder aannames.
