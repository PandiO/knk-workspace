# Landmarks as a Domain subtype — smoke test

**Status:** Draft from the design (2026-11-22); no steps run. Steps not yet automated (the links tag them).
**Last updated:** 2026-11-22 (draft from the design, phases 1–4)
**Design:** [specs/landmark-domain/DESIGN.md](../specs/landmark-domain/DESIGN.md) · **Issue:**
[PandiO/knk-workspace#976](https://github.com/PandiO/knk-workspace/issues/976)

## 1. Phase 1: API model, migration, area kinds and parent (#983, tier:3)

*Draft from the design (2026-11-22); the link updates it to what was built and tags the automated steps.*

### 1.0 Preconditions

1. Deployed: knk-web-api from `next` with the phase 1 migration applied to the dev DB; knk-web-app and knk-plugin
   from `next` (the region task and the rename run through the plugin).
2. Settings: none new.
3. Accounts and data:
    1. A staff account with `knk.admin.world.landmark`, `knk.admin.content` and `knk.admin.delete` ("landmark staff").
    2. A staff account with `knk.admin.world` and `knk.admin.content` but without `knk.admin.world.landmark`
       ("domain staff").
    3. A test town with a region in the dev world, and a crown land with a region (Territory V1 on `next`).
    4. The Landmark form v2 as the default Landmark form (seed import or the startup seeder).

### 1.1 Steps

1. Before the migration, note that the dev DB has landmark rows (the landmark list shows them). Apply the migration
   and reload the landmark list. **Expected:** the list is empty; the migration reported no error; the Landmark form
   that opens is the v2 form (Area offers None, Own region, Linked domain's area; no Radius). (A02)
2. As landmark staff, create a landmark with the v2 form: a name, a pin captured in game, Area `None`, no parent.
   **Expected:** it saves; `GET api/landmarks/{id}` shows area kind None and no region; `GET api/Domains/{id}` returns
   it with domain type `Landmark`. (A01)
3. As domain staff, try to create a town without a region (the town form with the region left empty, or
   `POST api/Towns` without `wgRegionId`). **Expected:** refused with the region-required message; nothing is saved.
   (A01)
4. As landmark staff, create a landmark with Area `Own region`: Send to Minecraft on the region field, draw a round
   area with `//sel cyl` in game, confirm, and submit the form. **Expected:** in game `/rg info` shows a cylinder-shaped
   region named `domain_<id>` (the landmark's id); the landmark's region field shows `domain_<id>`; no
   `tempregion_worldtask_*` region is left. (A04)
5. On the landmark of step 4, add a sub-region in the sub-region step (draw a second region) and save. **Expected:**
   the sub-region is named `domain_<id>_sub_<n>`. (A04)
6. Create a landmark with Area `Linked domain's area` and the test town as parent. **Expected:** it saves; the landmark
   has no region of its own (`GET api/landmarks/{id}`), its parent is the town. (A03)
7. Try Area `Linked domain's area` without a parent, then with the point-only landmark of step 2 as parent.
   **Expected:** both refused with a message that the area needs a parent with a region; nothing is saved. (A03)
8. Call `POST api/Domains/search-region-decisions` (top-down) with the region of step 4, then with its sub-region of
   step 5, then with the crown land's region; and `GET api/Domains/by-region/<region>` for each. **Expected:** every
   call answers at once; the landmark comes back with its parent chain (none for a top-level landmark, the town when
   it has the town as parent); the crown land comes back without parents; the API's memory stays flat. (A05)
9. Give the landmark of step 4 the test town as parent and repeat the first call of step 8. **Expected:** the
   landmark's decision lists the town as parent. (A05)
10. As domain staff, open the landmark of step 2 from the domain dashboard and rename it, then try to delete it.
    **Expected:** both refused (403, a no-permission message); nothing changes. (A06)
11. As landmark staff, rename the same landmark from the domain dashboard, then try a name longer than 100 characters
    and a name another landmark in the same world already has. **Expected:** the first rename saves; the other two
    are refused with the landmark name messages. (A06)

## 2. Phase 2: API lists, discovery, warps and realtime (#984, tier:2)

*Draft from the design (2026-11-22); the link updates it to what was built and tags the automated steps.*

### 2.0 Preconditions

1. Deployed: knk-web-api from `next` with phases 1 and 2; knk-web-app from `next`.
2. Settings: none new.
3. Accounts and data: landmark staff; the landmarks of § 1.

### 2.1 Steps

1. Open the domain list in the dashboard. **Expected:** the landmarks are listed with the type `Landmark`;
   filtering on that type shows only landmarks. (A07)
2. Open the discovery settings. **Expected:** a `Landmark` type rule exists and is disabled; a landmark has no
   discovery until its override turns it on. Turn the override on for the own-region landmark of § 1 step 4. (A08)
3. On the same landmark, switch the warp on with a price of 1 gem and save. **Expected:** the teleport destinations
   (`GET api/TeleportDestinations` or the warp list in the web app) list it with the type word `landmark` and the
   price. (A09)
4. Edit a landmark's name while the dev server runs. **Expected:** the API sends a realtime change for the landmark
   (the plugin log shows it received a `Landmark` change). (A16, API side)

## 3. Phase 3: plugin (#985, tier:2)

*Draft from the design (2026-11-22); the link updates it to what was built and tags the automated steps.*

### 3.0 Preconditions

1. Deployed: the plugin from `next` on the dev server, with the API and web app of phases 1 and 2.
2. Settings: `navigation.landmarks: true`.
3. Accounts and data: landmark staff; a normal player account; a wilderness landmark with its own region and one with
   its own region inside the test town (the town as parent).

### 3.1 Steps

1. Switch Allow entry off on the wilderness landmark, wait for the access sync (or `/knk regions repair`) and walk
   into its region with the player. **Expected:** the player is kept out with the domain's no-entry message; with
   Allow entry on again, the player walks in. (A10)
2. With the player, stand in fire and lava inside the wilderness landmark region, then inside the landmark in the
   town. **Expected:** in the wilderness landmark the player takes damage as outside it; in the town landmark no effect
   damage, as anywhere in the town. (A11)
3. With messages off on the wilderness landmark, walk in and out; switch "Show enter and leave messages" on, give it
   a sub-region next to the main region, and walk in, across into the sub-region, and out. **Expected:** nothing with
   messages off; with messages on, one enter message, nothing when crossing into the sub-region, one leave message.
   (A12)
4. As staff, run `/rg info domain_<id>` for the town landmark, then `/knk regions repair` and again `/rg info`.
   **Expected:** parent = the town's main region, priority = the town region's priority + 10, no category flags;
   unchanged after the repair. (A13)
5. With the player, `/navigate` with tab completion, then navigate to the wilderness landmark and walk into its
   sub-region first; navigate to the linked-domain landmark of § 1 step 6 and walk into the town. **Expected:** each
   landmark is offered once; arrival is announced on entering the sub-region; the linked-domain landmark arrives on
   entering the town. (A14)
6. As staff, `/knk landmark create Test radius 10`, then `/knk landmark link <wilderness landmark> <test town>` with
   tab completion. **Expected:** the radius form is refused with the usage line; `link` sets the town as parent and
   does not offer the landmark itself. (A15)
7. With the override of § 2 step 2 on, walk the player into that landmark for the first time; then `/warp
   landmark:<name>` from elsewhere; switch "requires discovery" on and try with a player who has not discovered it.
   **Expected:** a discovery message and reward once; the warp works with its price; the undiscovered player is
   refused. (A08, A09)
8. Rename a landmark in the web app and use `/navigate` tab completion in game. **Expected:** the new name shows
   within a few seconds, without a restart. (A16)

## 4. Phase 4: web app (#986, tier:2)

*Draft from the design (2026-11-22); the link updates it to what was built and tags the automated steps.*

### 4.0 Preconditions

1. Deployed: knk-web-app from `next` with phases 1 and 2 of the API.
2. Settings: none.
3. Accounts and data: landmark staff; the test town with a landmark as child.

### 4.1 Steps

1. Open a new landmark form and switch Area between `None`, `Own region` and `Linked domain's area`. **Expected:** the
   sub-region, access, messages, discovery and warp steps show only with `Own region`. (A17)
2. Open the domain list and filter on the type `Landmark`. **Expected:** a type column, and only landmarks after the
   filter. (A07)
3. Open the parent picker of a landmark that has a child landmark. **Expected:** domains show their type; the landmark
   itself and its child are not offered. (A18)
4. Open the test town's page, then the child landmark's page. **Expected:** the town lists its landmark; the landmark's
   page does not list itself as its own landmark.
