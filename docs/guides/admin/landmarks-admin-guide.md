# Landmarks — admin guide

**Status:** Current for `next` (not released): knk-web-api `next` `3bc3cfd5`, knk-plugin `next` `14645895`, knk-web-app `next` `8c9c3553` (desk check against the code; the developer's smoke test has not run yet) · **Last updated:** 2026-11-22 (new guide: landmarks as a Domain subtype, PandiO/knk-workspace#976, docs #1008)
**Design:** [specs/landmark-domain/DESIGN.md](../../specs/landmark-domain/DESIGN.md) (supersedes the landmark parts of [navigation-offroad/DESIGN.md](../../specs/navigation-offroad/DESIGN.md) § 6.1 and § 6.3)
**Related:** [player guide § 2.7 and § 3.3](../users/navigation-and-teleports-player-guide.md) (what players see; not repeated here), [smoke test](../landmark-domain-smoke-test.md), [domain sub-regions admin guide](domain-subregions-admin-guide.md), [navigation and teleports admin guide § 3.2](navigation-and-teleports-admin-guide.md#32-warps-teleport-destinations), [dashboard access admin guide § 2](dashboard-access-admin-guide.md), [plugin configuration § 4.15](plugin-configuration.md) `navigation.landmarks`, [managed WorldGuard regions § 7](../../architecture/managed-worldguard-regions.md)

For staff who make and look after landmarks: named places of the world ("the old well", "the throne room") that
players can `/navigate` to, warp to and discover. Since PandiO/knk-workspace#976 a landmark **is a domain**, like a
town, district or structure: it shows in the domain lists, can have a region with sub-regions, entry and exit rules,
enter and leave messages, discovery and a warp. Every one of those is off or neutral until you switch it on.

## 1. Permissions and prerequisites

| Node | Gives |
|---|---|
| `knk.admin.world.landmark` | Create, edit and delete landmarks: the landmark form, `api/landmarks` writes, edits of a landmark from the domain dashboard (`PUT`/`DELETE api/Domains/{id}`), and `/knk landmark` in game. Matched by `knk.admin.world.*`, not by `knk.admin.world` alone |
| `knk.admin.content` | Needed with the node above to create and edit |
| `knk.admin.delete` | Needed with the node above to delete |
| `knk.admin.world` | The domain dashboard, the landmark form's Parent picker and its world check (both read `api/Domains`). Landmark staff need it as well |
| `knk.admin.discovery` | The discovery settings and the per-domain overrides (§ 3.5) |

Holding `knk.admin.world` without `knk.admin.world.landmark` lets you see landmarks in the domain dashboard, but
editing or deleting one is refused with 403 "This domain is a landmark: changing it requires the
knk.admin.world.landmark permission." Reading landmarks (`GET api/landmarks`) needs no login.

You need:

1. knk-web-api, knk-web-app and knk-plugin from `next` with the deploy steps of § 6 done.
2. For `/navigate` to landmarks and for `/knk landmark`: `navigation.landmarks: true` and
   `navigation.destination-engine: true` in the plugin's `config.yml` (restart). With `navigation.landmarks: false`,
   `/knk landmark` answers "Landmarks are off on this server (navigation.landmarks: false in config.yml)." and
   `/navigate` doesn't offer landmarks. Everything else in this guide (regions, access, messages, discovery, warps)
   works with it off.

## 2. Where landmarks live

1. **Web app, landmark list:** dashboard → Landmark. Columns World, Point, Parent (with its type), Area, Region and
   In /navigate.
2. **Web app, domain list:** dashboard → Domain. Landmarks are listed with the type "Landmark" next to towns,
   districts and structures; the **Type** filter next to the search box keeps one type. A landmark's Edit opens the
   landmark form, its row (with a Domain display configuration) the landmark's page.
3. **A domain's page:** the **Landmarks** panel lists the landmarks whose parent it is; on a landmark's page it lists
   that landmark's child landmarks, never the landmark itself.
4. **In game:** `/knk landmark` (§ 4).

## 3. Making a landmark with the form

Use the form "Landmark - Default (seed v3)" (§ 6 item 3). Its steps:

### 3.1 Landmark and Location

1. **Name** (at most 100 characters, unique per world among landmarks) and **Description**.
2. **Parent:** the domain the landmark belongs to (the "linked domain"). Any domain, another landmark too. Leave it
   empty for a top-level landmark. The picker shows each option's type ("Type: Town", "Type: Landmark") and, for a
   saved landmark, leaves out the landmark itself and the landmarks below it. Nothing checks that the landmark lies
   inside its parent: its region may reach outside it, and it still has the parent as WorldGuard parent there, so the
   parent's flags (a town's `pvp deny`, for example) apply to the whole landmark region.
3. **Offer in /navigate:** on by default.
4. **Location:** the pin, where `/navigate` and a warp lead. Capture it in game. A pin taken from a domain's spawn
   point is copied: the landmark gets its own Location at the same spot and the domain keeps its spawn.

### 3.2 Area

| Area | What it means | What it owns |
|---|---|---|
| **Point** (`None`) | The landmark is its pin. `/navigate` arrives within `navigation.arrive-distance` of it | No region, no sub-regions, no access flags |
| **Own region** (`OwnRegion`) | The landmark has its own WorldGuard region: draw one with Send to Minecraft on the Region field, or name an existing region no other domain holds. A round area is a cylinder selection (`//sel cyl`), saved as a cylinder-shaped polygon region; the old radius area is gone | Its region, renamed `domain_<id>` on save, and its sub-regions `domain_<id>_sub_<n>` |
| **Linked domain's area** (`LinkedDomain`) | The landmark uses its parent's main region and sub-regions as its area. Only offered while the parent has a region | Nothing: entering that area is entering the parent, so the parent's messages, discovery and entry rules apply, not the landmark's |

**Route preference** (0.25 to 4.0, default 1.0) weights routes through the landmark's area in the `preferred` route
mode ([plugin configuration](plugin-configuration.md) `navigation.preference-max`).

The form refuses "Area Own region needs a region: draw one or name an existing region." and "Area Linked domain's area
needs a parent with a region."; without a parent it shows "Linked domain's area is offered once the parent has a
region." Changing the area away from Own region leaves the landmark's regions in WorldGuard under the usual orphan
and retention rules ([domain sub-regions admin guide](domain-subregions-admin-guide.md)).

With **Point** and **Linked domain's area**, Area is the last step. The steps below show with **Own region** only.

### 3.3 Access and messages (Own region)

1. **Allow entry**, **Allow exit**: on by default. They work as on any domain: the plugin syncs `knk-allow-entry`,
   `knk-allow-exit` and `knk-domain-id` onto the landmark's region and its sub-regions within a minute, or at once
   with `/knk regions repair`.
2. **Show enter and leave messages:** off by default. On: one "You are now entering <name>." and one "You are now
   leaving <name>." per crossing, nothing when a player walks between the landmark's own regions. A town's message
   wins when a player enters the town and a landmark in it at once.

### 3.4 Warp destination (Own region)

The domain teleport fields, labelled **Warp destination**, **Price (gems)**, **Minimum title**, **Minimum premium
tier** and **Discovered landmarks only**; all work as in the
[navigation and teleports admin guide § 3.2](navigation-and-teleports-admin-guide.md#32-warps-teleport-destinations).
Off by default. Players reach a landmark warp with `/warp landmark:<name>` or the teleport menu. "Discovered landmarks
only" stays locked for everyone while the landmark's discovery is off (§ 3.5).

Seed v3 shows this step only with Own region, as the acceptance check A17 says. Whether a point landmark should keep
its warp is the developer's open question on [PandiO/knk-workspace#1003](https://github.com/PandiO/knk-workspace/issues/1003);
the API accepts the warp fields for every area.

### 3.5 Sub-regions (Own region)

The domain sub-region step: draw more regions that count as one area with the main region (one message per
crossing, arrival anywhere in them, the same access flags). See the
[domain sub-regions admin guide](domain-subregions-admin-guide.md).

### 3.6 Discovery

There is no discovery field on the form. Discovery uses the existing rules:

1. The **`Landmark` type rule** in the discovery settings (listed last) is **disabled**, with small XP and coin
   rewards, no gems and no ancestors. Leave it disabled: turning it on makes every Own region landmark discoverable.
2. To make one landmark discoverable, add a **per-domain override** for it in the overrides card ("Add override"
   offers landmarks with the type word Landmark) and switch it on.
3. Only an Own region landmark is discovered (a player has to enter its region). A point has nothing to enter; a
   Linked domain's area landmark is discovered as its parent.

## 4. In game: `/knk landmark`

Needs `knk.admin.world.landmark` and `navigation.landmarks: true`. A landmark is named by its name or `#id`.

| Command | What it does |
|---|---|
| `/knk landmark create <name>` | A point landmark at your position. |
| `/knk landmark create <name> region <id>` | An Own region landmark on an existing region no other domain holds. |
| `/knk landmark list` | The landmarks of your world, with their area and parent. |
| `/knk landmark show <landmark>` | Id, position, area ("region domain_<id> and 1 sub-region", "the area of <parent>", "point only"), "Parent: <name> (<type>) #<id>", "Enter and leave messages: on/off", "In /navigate". |
| `/knk landmark move <landmark>` | Moves the pin to where you stand. |
| `/knk landmark link <landmark> <domain>` | Sets the parent ("Linked … to <domain> (<type>)."). Tab offers every domain, other landmarks too, but not the landmark itself. Two domains with one name: use `#id`. |
| `/knk landmark unlink <landmark>` | Removes the parent. |
| `/knk landmark delete <landmark>` | Deletes the landmark. |

The radius form is gone: `/knk landmark create <name> radius <n>` is refused with "The radius area is gone: draw a
round region with //sel cyl, then use region <id>." and the usage line. Area, access, messages, warp and sub-regions
are set in the web app.

## 5. The region on the game server

An Own region landmark's region is a managed region of kind `LANDMARK`: WorldGuard parent = the parent domain's main
region (none for a top-level landmark), priority = the parent's priority + 10 and at least 30, and no category flags
of its own (no `pvp`, `entry`, `mob-spawning`), so it inherits the parent's. The startup repair and
`/knk regions repair` restore that parent and priority. A landmark never makes a spot safe from effect damage and
never turns it back on: inside a wilderness landmark fire, lava and poison hurt as outside it; inside a landmark in a
town the town's rule applies. Details: [managed WorldGuard regions § 7](../../architecture/managed-worldguard-regions.md),
[domain access enforcement](../../architecture/domain-access-enforcement.md).

## 6. Deploy steps

In this order (the full notes are the changelog entries of #983, #984, #985, #986 and #952/#1003):

1. **Back up the database.** Then deploy knk-web-api with the migrations `LandmarkAsDomain` and
   `AddLandmarkDiscoveryRule`. `LandmarkAsDomain` is **not additive: it deletes every landmark row** and rebuilds
   `landmarks` as a child table of `domains` (`domains.WgRegionId` becomes nullable). Only the dev database has
   landmarks; recreate them by hand afterwards. Old `landmark:<id>` navigation targets no longer resolve.
   `AddLandmarkDiscoveryRule` adds the disabled `Landmark` discovery rule (data only).
2. Deploy knk-web-app, then knk-plugin. The plugin reads only the new landmark fields, so it must not run against an
   API from before the migrations.
3. In the web app, import the seeds `Landmark` (form, "Landmark - Default (seed v3)") and `Landmark.display`, and
   make both the default for Landmark. Seed v2 need not be imported; an older Landmark configuration (seed v1, v2 or
   an edited one) stays in the database but names fields that no longer exist: switch it off as default.
4. Run `/knk regions repair` once in game (or restart the server), so existing landmark regions get their `LANDMARK`
   parent and priority.
5. No new `config.yml` key, API setting or permission node.

## 7. A safe test

On the dev server, with a test town that has a region:

1. Make a point landmark with no parent; `/knk landmark show` it: "point only", no parent.
2. Make an Own region landmark in the wilderness with a small drawn region; check `/rg info domain_<id>`: no parent,
   priority 30, the access flags and `knk-domain-id <id>`.
3. Make an Own region landmark inside the town with the town as parent; check `/rg info`: the town's region as
   parent, the town's priority + 10.
4. Switch messages on for one of them and walk in and out with a test player.
5. Delete the test landmarks when done (their `domain_<id>` regions stay in WorldGuard, see § 9).

The full check list is the [smoke test](../landmark-domain-smoke-test.md).

## 8. When something goes wrong

| What you see | Why, and what to do |
|---|---|
| 403 "This domain is a landmark: changing it requires the knk.admin.world.landmark permission." | You edited a landmark from the domain dashboard without the landmark node. Get `knk.admin.world.landmark` (§ 1). |
| The Parent picker or the world check stays empty | Landmark staff without `knk.admin.world`: the picker reads `api/Domains`. |
| "Area Linked domain's area needs a parent with a region." | The parent is a point landmark or a domain without a region. Pick another parent or another area. |
| "Domain <name> (#<id>) is inside this landmark: a landmark can't be its own ancestor." | The parent you picked is below this landmark. |
| "A landmark named "…" already exists in world …" | Names are unique per world among landmarks. |
| The form shows Extent, Region id or Radius fields | An old Landmark form is the default. Import seed v3 and make it the default (§ 6 item 3). |
| `/knk landmark` says landmarks are off | `navigation.landmarks: false` on that server (§ 1). |
| A landmark region has no parent or a wrong priority | Run `/knk regions repair`; the plugin log lists "landmarks unavailable (…)" when it could not read `api/landmarks`. |
| A renamed landmark still shows its old name in `/navigate` | The realtime connection to the API is down; `/knk cache refresh` or wait for the 60 s model refresh. |
| A landmark region stays on `tempregion_worldtask_<n>` after a failed re-run | A domain's own `domain_<id>` is not healed automatically (#1006); use the manual way out of [managed WorldGuard regions § 7](../../architecture/managed-worldguard-regions.md). |

## 9. Effects on existing data

1. The migration deletes all landmark rows (§ 6 item 1); regions already named `landmark_<n>` stay in WorldGuard and
   are no longer used.
2. Deleting a landmark, or changing its area away from Own region, leaves its `domain_<id>` and sub-regions in
   WorldGuard, as for any domain.
3. Turning a landmark's warp, messages or discovery on changes nothing for other domains.

## Sources

1. Code: knk-web-api `Models/Landmark.cs`, `Services/LandmarkService.cs`, `Controllers/LandmarksController.cs`,
   `Controllers/DomainsController.cs`, `Dtos/LandmarkDtos.cs`, `Data/FormConfigurationSeeds/Landmark.json`,
   migrations `20261122164836_LandmarkAsDomain` and `20261122184739_AddLandmarkDiscoveryRule`; knk-plugin
   `knk-paper/.../commands/LandmarkAdminCommand.java`, `knk-core/.../landmarks/`,
   `knk-core/.../regions/managed/DomainRegionSpecs.java`, `knk-core/.../regions/DomainEffectDamage.java`,
   `knk-core/.../regions/SimpleRegionTransitionService.java`; knk-web-app `src/config/objectConfigs.tsx`,
   `src/components/FormWizard/FormWizard.tsx`, `src/components/landmarks/`.
2. [Design](../../specs/landmark-domain/DESIGN.md), [chain report](https://github.com/PandiO/knk-workspace/blob/main/docs/reports/2026-11-22-landmark-domain-chain.md)
   (on `main`), the changelog entries of #983–#986 and #952/#1003.
