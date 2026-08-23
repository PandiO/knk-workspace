# GateStructure FormConfiguration – Deel B

**Status**: Ontwerp, nog niet geïmplementeerd
**Afhankelijk van**: Deel A (Display Conditions)

Dit document beschrijft welke FormConfiguration er voor `GateStructure` gebouwd moet worden en
welke velden per gate type relevant zijn. Deze veldmatrix ontbrak in de bestaande documentatie.

---

## 1. Gate types

Er zijn vier types, gedefinieerd in [GateStructureEnums.cs](../../../Repository/knk-web-api-v2/Models/GateStructureEnums.cs):

| GateType | MotionType | GeometryDefinitionMode | Rotatie |
| --- | --- | --- | --- |
| `SLIDING` | keuze: `VERTICAL` of `LATERAL` | `PLANE_GRID` | nee |
| `TRAP` | `VERTICAL` (afgeleid) | `PLANE_GRID` | nee |
| `DRAWBRIDGE` | `ROTATION` (afgeleid) | `PLANE_GRID` | ja, 90° |
| `DOUBLE_DOORS` | `ROTATION` (afgeleid) | `FLOOD_FILL` | ja, 90° gespiegeld |

`GeometryDefinitionMode` is volledig afleidbaar uit `GateType` en wordt daarom niet als
invulbaar veld aangeboden. Hetzelfde geldt voor `MotionType`, behalve bij `SLIDING`.

**GeometryDefinitionMode betekent:**
- `PLANE_GRID` – de poort is een rechthoek, bepaald door drie punten (anchor + twee referentiepunten).
- `FLOOD_FILL` – de poort is onregelmatig; het systeem zoekt vanaf seed-blokken naar buiten (BFS).

---

## 2. Veldmatrix

### Altijd aanwezig

| Step | Velden |
| --- | --- |
| General Information | `Name`, `DomainId`, `DistrictId`, `StreetId`, `FaceDirection`, `GateType`, `IsActive`, `IconMaterialRefId` |
| Animation & Blocks | `AnimationDurationTicks`, `AnimationTickRate`, `FallbackMaterialRefId`, `TileEntityPolicy` |
| Health, Regions & Combat | `HealthMax`, `IsInvincible`, `CanRespawn`, `RespawnRateSeconds`, `ShowHealthDisplay`, `HealthDisplayMode`, `HealthDisplayYOffset`, `RegionClosedId`, `RegionOpenedId`, `AllowContinuousDamage`, `ContinuousDamageMultiplier`, `ContinuousDamageDurationSeconds` |
| Pass-Through & Siege | `AllowPassThrough`, `IsOverridable`, `AnimateDuringSiege`, `IsSiegeObjective` |

### Type-afhankelijk

| Veld | SLIDING | TRAP | DRAWBRIDGE | DOUBLE_DOORS |
| --- | --- | --- | --- | --- |
| `MotionType` | invulbaar | afgeleid | afgeleid | afgeleid |
| `AnchorPointId` | verplicht | verplicht | verplicht | – |
| `ReferencePoint1Id` | verplicht | verplicht | verplicht | – |
| `ReferencePoint2Id` | verplicht | verplicht | verplicht | – |
| `GeometryWidth` / `GeometryHeight` / `GeometryDepth` | ja | ja | ja | – |
| `SeedBlocks` | – | – | – | verplicht |
| `ScanMaxBlocks` / `ScanMaxRadius` | – | – | – | ja |
| `ScanMaterialWhitelist` / `ScanMaterialBlacklist` / `ScanPlaneConstraint` | – | – | – | ja |
| `HingeAxisId` | – | – | verplicht | verplicht |
| `RotationMaxAngleDegrees` | – | – | ja | ja |
| `LeftDoorSeedBlockId` / `RightDoorSeedBlockId` | – | – | – | verplicht |
| `MirrorRotation` | – | – | – | ja |

### Veld-conditioneel binnen een step

| Veld | Zichtbaar wanneer |
| --- | --- |
| `PassThroughDurationSeconds` | `AllowPassThrough == true` |
| `PassThroughConditionsJson` | `AllowPassThrough == true` |
| `ContinuousDamageMultiplier` | `AllowContinuousDamage == true` |
| `ContinuousDamageDurationSeconds` | `AllowContinuousDamage == true` |
| `HealthDisplayMode` | `ShowHealthDisplay == true` |
| `HealthDisplayYOffset` | `ShowHealthDisplay == true` |
| `RespawnRateSeconds` | `CanRespawn == true` |

---

## 3. Stepindeling met display conditions

| # | Step | Display condition |
| --- | --- | --- |
| 1 | General Information | altijd |
| 2 | Geometry: Plane Grid | `GateType` In `[SLIDING, TRAP, DRAWBRIDGE]` |
| 3 | Geometry: Flood Fill | `GateType` == `DOUBLE_DOORS` |
| 4 | Motion: Sliding | `GateType` == `SLIDING` |
| 5 | Motion: Rotation | `GateType` In `[DRAWBRIDGE, DOUBLE_DOORS]` |
| 6 | Animation & Blocks | altijd |
| 7 | Health, Regions & Combat | altijd |
| 8 | Pass-Through & Siege | altijd |

Step 5 bevat `HingeAxisId` en `RotationMaxAngleDegrees` voor beide types, plus
`LeftDoorSeedBlockId`, `RightDoorSeedBlockId` en `MirrorRotation` met een veld-conditie
`GateType == DOUBLE_DOORS`.

---

## 4. Openstaande werkzaamheden

1. **Enum-opties in de builder** – afgerond in Deel A: `MetadataService` levert nu `enumValues`
   per enum-property, en `DisplayConditionBuilder` gebruikt die voor de waarde-dropdowns.
   `FieldRenderers` leest enum-opties nog uit de legacy comma-separated `defaultValue`; die moet
   nog omgezet worden naar de metadata-route.
2. **Locatie-velden via WorldTask** – `AnchorPoint`, `ReferencePoint1/2`, `HingeAxis`,
   `LeftDoorSeedBlock`, `RightDoorSeedBlock` en `SeedBlocks` zijn in-game te prikken punten.
   Deze blijven ephemeral in `WorldTask.OutputJson` tot de `GateStructure` daadwerkelijk
   wordt aangemaakt.
3. **Afgeleide velden** – `GeometryDefinitionMode` en (buiten SLIDING) `MotionType` moeten
   server-side uit `GateType` gezet worden, zodat ze niet in het formulier hoeven te staan.
4. **Seeden van de configuratie** – de bovenstaande configuratie inclusief display conditions
   aanmaken als default voor `GateStructure`, via `POST /api/formconfigurations` of een seeder.
5. **End-to-end verificatie** – FormConfig → FormSubmission → `GateStructure` aangemaakt →
   plugin laadt gate → animatie draait → `IsOpened` synchroniseert.
