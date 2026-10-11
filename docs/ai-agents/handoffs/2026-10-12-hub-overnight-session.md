# Handoff: hub overnight session (KNG-113, KNG-114, KNG-116, KNG-118, hub Phases 4–5)

**Date:** 2026-10-12 (overnight from 2026-10-11)
**Status:** Implemented on branches, not merged, not live-tested. All on `claude/blissful-fermat-b7ihrz`.
**Design:** hub [DESIGN §16](../../specs/hub/DESIGN.md). Earlier work: [KNG-111/112 handoff](2026-10-10-kng-111-112-multiworld-implementation.md).

The developer asked for designed, decision-free work only while they slept. Open decisions are listed at the end.

## Branches

| Repo | Base | What is on it | PR |
|---|---|---|---|
| knk-plugin | `main` `0396c7b4` (KNG-111/112 merged) | world loader (KNG-114), gates in several worlds (KNG-113), hub settings, Game Settings in the KNG-58 store, hub admission + rules, KNG-118 items | [#11](https://github.com/PandiO/knk-plugin/pull/11) |
| knk-web-api | `master` `917537a` | hub configuration, KNG-116 group check, migration `AddHubSettings` | [#8](https://github.com/PandiO/knk-web-api/pull/8) |
| knk-web-app | `main` `38854ba` | Game Settings page: hub card, exemption boxes, world-filtered spawn pickers | [#6](https://github.com/PandiO/knk-web-app/pull/6) |

Merge order: **API first** (migration + endpoints), then the web app, then the plugin. The plugin works against an API without the hub block: no hub means nothing changes.

## What changed

### Plugin
- **World loader (KNG-114):** `worlds.load` in `config.yml`. Live-checked 2026-10-11: the `hub` void world was created and reached with `/tp 2 65 2 hub`.
- **Gates (KNG-113):**
  - Each world animates only its own doors. A door without a world in its anchor goes to the main world, with a log line.
  - Animation tasks start and stop with their world.
  - `/gate tp` and `/gatedoor tp` refuse a door whose world isn't loaded.
  - Door region capture, redefine and save refuse while the player is in another world than the door. This is the likely cause of the 2026-10-11 trouble configuring a hub gate door.
  - A gate display in the wrong world is removed.
  - Partly live-checked 2026-10-11 and accepted.
- **Hub settings reach the plugin.** `KnkHubSettings` and `KnkHubRules`, plus the groups' outage fields and exemptions.
- **Game Settings in the KNG-58 store (decision 7).** The snapshot is a `gameSettings` field in `offline-security.json`. An old `game-settings-cache.json` is read once and moved to `game-settings-backups/`. With `offline-cache.enabled: false` the old file is used as before.
- **Hub admission:**
  - With a hub selected, every join is placed at the hub spawn in `AsyncPlayerSpawnLocationEvent`, before the player appears. The join teleport is skipped.
  - While the hub's world, region or spawn is missing, non-operators are refused with "The server's hub is not available right now".
- **Hub rules (§13 defaults), inside the hub region only:**
  - no combat, no damage, no building;
  - storage and item frames/paintings blocked;
  - drop/pickup, doors and NPCs allowed;
  - falling into the void returns you to the hub spawn.
  - `knk.hub.bypass` (op) lifts the building and interaction rules, not the damage rules.
- **Peaceful preset:** +1 health and +1 saturation every 20 ticks, +1 food every 10 ticks. Only in the hub region, only with `naturalRegeneration` on, and not in a Peaceful world.
- **KNG-118:**
  - region resync on a world change (R10);
  - `/knk location tp` sends a Location without a world to the main world (L3);
  - Siege banner log keeps entries for unloaded worlds (S3).

### API
- **`Domain.IsHub`** (hub-eligible only).
  - `GET/PUT api/GameSettings/hub/domains[/{id}]`.
  - Nested flagged domains are refused, and so is unflagging the selected hub.
- **Game Settings `hub` block** (`HubSettingsJson`):
  - the selected hub (must be flagged) and its spawn (must be in the hub's world);
  - the outage action (default SendToHub) and delay (0 = Uit);
  - the rules.
- **Group overrides:** `outageAction`, `outageDelaySeconds`, `exemptInStaffMode`, `exemptInOwnerMode`. Only a ticked box is stored, and only for an eligible group.
- **KNG-116:**
  - `GET api/PermissionGroups/{id}/permissions/check?node=` checks the group, then its parent chain, with user matching.
  - `GET api/GameSettings/hub/exemption-eligibility`.
- **Migration `AddHubSettings`:** two columns, no data changes. The CI steps (apply, no pending changes, roll back, re-apply) passed on a local MySQL 8.

### Web app
- **Game Settings "Hub" card:**
  - flag towns, districts and structures as hub-eligible (saved at once; the API's nested-hub refusal is shown);
  - choose the hub and its spawn;
  - set the outage action and delay;
  - set the rules and the Peaceful numbers.
- **Group overrides:**
  - own outage action and delay;
  - "Exempt while in staff/owner mode" boxes, shown only when the group effectively has the node. The source group is named.
- **Pickers:** a world's own spawn picker, and the hub spawn picker, list only places in that world (KNG-118 U5).

## Review
An independent review of the overnight diffs found 8 issues. All 8 are fixed and covered by tests where testable:
- barrels counted as doors;
- the void rescue never triggered below the region;
- a deleted hub domain locked out non-ops;
- a stale exemption box blocked every save;
- owners lost their game mode on join;
- web inputs the API rejects;
- the hub spawn was not re-resolved;
- the old cache file was deleted before the store write was confirmed.

Codex then reviewed the three PRs. All 9 findings are fixed, replied to and resolved:
- **API:**
  - the location-retention job could delete the hub spawn Location;
  - a domain without a world could be selected;
  - a nested flagged domain could be selected.
- **Plugin:**
  - a join into a hub whose AllowEntry is denied was moved out again by the domain-access join check;
  - `knk.hub.bypass` lifted the entity-damage rule;
  - a spawn outside the hub region still counted as usable.
- **Web app:**
  - domains without a spawn Location could not be flagged;
  - a failed load of the flagged domains read as "none flagged";
  - the save error used the lootbox 403 text.

## Verified (no live server for the hub part)
- **Plugin:** core 2046, api-client 258, paper 1639, all green.
- **API:** 2559 passed. The 4 failures also fail on `master` (`PathResolutionServiceTests` ×2, `FieldValidationServiceTests`, `ClientActivityStoreTests`). New: `HubSettingsServiceTests` (7), a `GameSettingsServiceTests` hub round trip and a retention test.
- **Web app:** `tsc` clean, `npm run build` passes, Game Settings component tests 31/31 (new `hubSettings.test.tsx`).

## Test checklist, in priority order
1. **Migration:** deploy the API, apply `AddHubSettings` and open the Game Settings page. Nothing else should have changed.
2. **No hub selected:** joins, `/spawn`, respawn and gates behave exactly as before. This is the default after the merge.
3. **Configure the hub:**
   - In "Hub", flag the hub Town or District and choose it.
   - Pick the hub spawn (only hub-world places are listed) and save.
   - Flagging a district inside a flagged town must be refused.
4. **Join:** you should appear at the hub spawn without first seeing the gameplay world. Try this as a non-op too.
5. **Hub rules:**
   - in the hub, a non-op cannot hit players or mobs, cannot break or place blocks, cannot open chests or item frames;
   - they can open doors, drop items and pick them up;
   - outside the hub region nothing changed;
   - with `knk.hub.bypass` (op) you can build.
6. **Peaceful preset:** on Normal difficulty, hurt yourself outside the hub and walk in. You should heal about 1 health per second and gain food. In a Peaceful world, nothing extra should happen.
7. **Fail closed:** temporarily remove the hub region (or select a domain whose region is missing). A non-op join is refused with the hub message, and an operator can still join. Restore it afterwards. The same happens when the hub spawn is moved outside the hub region.
8. **API down + restart:**
   - stop the API and restart the server;
   - the log should show "Using the cached settings";
   - joins still go to the hub;
   - `offline-security.json` should contain `gameSettings`.
9. **Exemption boxes:** a group without `knk.mode.staff` shows no box. Grant the node and the box appears, naming the group that grants it. Note: `knk.mode.*` nodes may not be seeded in the live DB (KNG-116 P4).
10. **Gate door in the hub:**
    - capture its regions while standing in the hub;
    - from the main world it should refuse with "Go to its world first".

## Open decisions (need the developer)
1. **Outage actions and the delay timer (§13 "remaining details"):**
   - what a staff/owner mode switch during an outage does;
   - how the delay timer behaves when the API recovers and drops again, or across a restart.
   - The actions themselves (None/SendToHub/Kick/SendToWorldSpawn) are configured but **not executed yet**.
2. **Return records and the Siege abort (§12, decision 6):** both are triggered by the outage actions, so they wait for decision 1.
3. **Hub → gameplay portal (§11):** the trigger (a WorldGuard region, a block, an NPC?), its readiness check, and how it clears return records. Until it exists, players leave the hub with `/spawn` or `/warp`, which nothing guards yet.
4. **Admission for active owners:** right now *every* join goes to the hub, owners too, per §1 "All joining players first enter a designated hub". Should active owner mode keep "join where I logged out"?
5. **Discovery per world (KNG-118 R14/A5):** discovery is still keyed by region id. The API already accepts domain ids. The fix changes the plugin's discovery spool and known-discoveries cache format, so it was not done overnight.
6. **Location deletes its Domain (KNG-118 D3):** the FK cascade is unchanged. Changing it changes behaviour.
7. **Group precedence drift (KNG-118 U6):** the web app orders overrides depth-first ("decision 2026-10-05"), while the API and plugin use weight-first (D13). One of them needs to change. Which is intended?
