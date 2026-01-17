# Legacy location bronnen (knk)

- Eigen model: [knk/src/main/java/net/knightsandkings/model/location/Location.java](knk/src/main/java/net/knightsandkings/model/location/Location.java)
  - JPA `@Entity` met velden `id:int`, `world:org.bukkit.World` (`@Convert` met WorldConverter naar kolom `world_name`), `X/Y/Z:double`, `Pitch/Yaw:float`, `location:org.bukkit.Location` (`@Transient`). Wereld en coördinaten worden opgeslagen als aparte kolommen; Pitch/Yaw/XYZ altijd `nullable = false`.
  - Constructors accepteren `org.bukkit.Location` en kopiëren velden; `getLocation()` reconstrueert een Bukkit `Location` wanneer `location` transient is. Teleporthulpmethoden (`TeleportNearby`, `canTeleport`, `FreeOfPlayers`) gebruiken Bukkit types.
  - Relaties: talrijke entiteiten houden een `@OneToOne` verwijzing naar dit type via `location_id` (zie hieronder). Cascade `ALL` betekent dat locaties meegepersist/geserialiseerd worden.

- Converter: [knk/src/main/java/net/knightsandkings/hibernate/converter/WorldConverter.java](knk/src/main/java/net/knightsandkings/hibernate/converter/WorldConverter.java)
  - `AttributeConverter<World, String>` die `World.getName()` opslaat en via `Bukkit.getWorld(name)` laadt. Gebruikt door het `world` veld van de Location-entity.

- Bukkit → primitive mapper: [knk/src/main/java/net/knightsandkings/util/CreationLocationMapper.java](knk/src/main/java/net/knightsandkings/util/CreationLocationMapper.java)
  - Simpele DTO met velden `worldName:String`, `x/y/z:double`, `yaw/pitch:float` die direct uit een Bukkit `Location` worden gelezen. Geen usages gevonden in de codebase (alleen definitie).

- Creation stage voor Location: [knk/src/main/java/net/knightsandkings/creation/CreationStageLocation.java](knk/src/main/java/net/knightsandkings/creation/CreationStageLocation.java)
  - Velden: `requiredRegionStage:CreationStageRegion` (transient), `requiredRegion:ProtectedRegion` (`@Convert` via `WGRegionConverter`, kolom `required_region_id`), `maxLocations:int`, `result:List<Location>` (`@ManyToMany` naar tabel `stage_location_results`).
  - `execute()` maakt nieuwe `Location` uit de spelerpositie (`new Location(org.bukkit.Location)`), valideert optioneel WorldGuard-regio, en voegt toe aan `result` mits uniek. `cleanup()` verwijdert locaties die nog door andere entiteiten worden gebruikt (Dominion/MGObjective/MGSpawnpoint/MGScenario/KNKBlock afhankelijkheden via repositories).
  - Gebruikt in creatieflows van dominion/structuur-achtigen en minigame stages (zie use cases hieronder).

## Entiteiten die de legacy Location opslaan

- Dominion-basis + subtypen: [knk/src/main/java/net/knightsandkings/model/dominion/Dominion.java](knk/src/main/java/net/knightsandkings/model/dominion/Dominion.java)
  - `location:Location` (`@OneToOne`, `@JoinColumn(name="location_id")`, `@Cascade ALL`, `@Access PROPERTY`). Wordt gevuld in `createInstance()` vanuit CreationStageLocation-gegevens en gebruikt om WorldGuard-regio te bouwen; `regionName` houdt WG-id bij.
  - Subklassen erven dezelfde locatie: [Town](knk/src/main/java/net/knightsandkings/model/dominion/Town.java), [District](knk/src/main/java/net/knightsandkings/model/dominion/District.java), [Structure](knk/src/main/java/net/knightsandkings/model/dominion/Structure.java), [Warehouse](knk/src/main/java/net/knightsandkings/model/dominion/Warehouse.java), [Gate](knk/src/main/java/net/knightsandkings/model/dominion/Gate.java). Creationstages in deze klassen voegen telkens een `CreationStageLocation` toe voor de centrale positie; bij opslaan wordt de `location`-relatie weggeschreven via `location_id`.
  - Gate heeft aanvullend `guardLocations:List<Location>` (transient) voor wachters; niet gepersisteerd.

- Blocks: [knk/src/main/java/net/knightsandkings/model/item/KNKBlock.java](knk/src/main/java/net/knightsandkings/model/item/KNKBlock.java)
  - `location:Location` (`@OneToOne`, `@JoinColumn(name="location_id", nullable=false)`, `@Cascade ALL`) koppelt een block-itemtype aan een opgeslagen Location.

- Minigame objecten:
  - [MGObjective](knk/src/main/java/net/knightsandkings/model/minigame/MGObjective.java): `location:Location` (`@OneToOne`, `@JoinColumn(name="location_id")`, `@Cascade ALL`), gebruikt als capture point; CreationStageLocation gebruikt in creatie.
  - [MGSpawnpoint](knk/src/main/java/net/knightsandkings/model/minigame/MGSpawnpoint.java): `location:Location` (`@OneToOne`, `@JoinColumn(name="location_id")`, `@Cascade ALL`), spawnpositie; veilig-zone taken teleporteren spelers naar de Bukkit `Location` binnen het object.
  - [MGScenario](knk/src/main/java/net/knightsandkings/model/minigame/MGScenario.java): `hubLocation:Location` (`@OneToOne` op getter, `@JoinColumn(name="hub_location_id")`, `@Cascade ALL`), hub/spawn voor scenario; wordt gezet via creation stage selecties.
  - [MGTeam](knk/src/main/java/net/knightsandkings/model/minigame/MGTeam.java) houdt `spawnpoints:List<MGSpawnpoint>`; locaties komen via de spawnpoints.

## Opslag/serialisatie

- Coördinaten en rotatie worden als primitive kolommen op de Location-tabel opgeslagen (`world_name`, `x`, `y`, `z`, `pitch`, `yaw`).
- Verwijzingen vanuit entiteiten gebeuren via `location_id` (of `hub_location_id`) met cascade `ALL`, dus locatie records worden meegeschreven/verwijderd met de eigenaar.
- World wordt als string bewaard via `WorldConverter`; Bukkit `Location` instanties blijven transient en worden on-demand opgebouwd.
- CreationStageLocation koppelt locaties aan stages via join table `stage_location_results` en valideert optional WorldGuard-regio’s (kolommen `required_region_stage`, `required_region_id`).
