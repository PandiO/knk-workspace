# Handoff: hub overnight session (KNG-113, KNG-114, KNG-116, KNG-118, hub Phases 4–5)

**Date:** 2026-10-12 (overnight from 2026-10-11)
**Status:** Implemented on branches, not merged, not live-tested. All on `claude/blissful-fermat-b7ihrz`. Continued in the day session of 2026-10-12 (decisions 8-13, below).
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

## Day session 2026-10-12 (decisions 8-14)

The developer answered the open decisions ([DESIGN §16.7](../../specs/hub/DESIGN.md)). Built on the same branches:

| Repo | Commits | What |
|---|---|---|
| knk-plugin | `fed45a3c`, `a2533bb7`, `4d8c307a`, `6125ad43` | joins (decision 8), outage actions + timer + return records + Siege abort (9, 10, 6), portal (11), staff/owner mode joins in place (14), review fixes |
| knk-web-api | `bc7b06e`, `cc9ced1`, `644acce`, `8e34954`, `7ec345f` | Location delete keeps its domain (12, migration `LocationDeleteKeepsDomain`), Siege end reason `ApiOutage`, `hub.portalRegionIds`, group precedence option (i) (13) |
| knk-web-app | `ef57c7a`, `5625dd6`, `a17cb46` | "Portal regions" field, override order option (i) (13), review fix |

An independent review of the day session found 12 issues; all are fixed (DESIGN §16.7 "small choices"). The most important: Siege lobbies stopped by an outage now restart when the API is back; the return offer ends when the player leaves the hub, is refused while frozen, and keeps an unsafe spot instead of deleting it; evacuations use the plugin transfer.

- **Plugin tests:** core 2058, api-client 258, paper 1656, all green.
- **API tests:** 2565 passed; the same 4 failures as on `master`. The migration was checked on a local MySQL 8: apply, no pending changes, roll back one step, re-apply.
- **Web app:** `tsc` clean, the build passes, Game Settings tests 33/33.

### Extra test steps for the day session
11. **Joins with a hub (decision 8):**
    - a player with no group spawn arrives at the hub;
    - a group with its own join spawn arrives there;
    - a "join where they logged out" group and an owner stay where they logged out.
12. **Portal:**
    - put a small WorldGuard region in the hub, add its id under "Portal regions" and save;
    - walk in: you go to your group's join spawn, else the default join spawn;
    - with the API stopped, a non-exempt player is told the game world can't be entered.
13. **Outage actions:**
    - set the hub's outage action to "Send to the hub" with a 30 s delay, stand in gameplay as a non-op, and stop the API;
    - after about 30 s plus detection you are moved to the hub with a message;
    - `/spawn` out of the hub is refused;
    - start the API: a clickable "[Return to where you were]" appears, and clicking it returns you once (a second click does nothing).
14. **Outage timer:**
    - stop the API, start it, and stop it again within a few seconds: the delay keeps counting from the first stop;
    - restarting the server during an outage keeps it too (`hub-outage.json`).
15. **Exemption:** tick "Exempt while in staff mode" for your group and enter staff mode; an outage leaves you alone. Leave staff mode during the outage and the action applies within a second.
16. **Kick:** a group with action Kick is kicked with the outage message. Rejoining during the outage puts them in the hub, with the return offer after recovery.
17. **Siege:** during a match, trigger an outage. The match is aborted (no winner), everyone gets their things back once at their pre-match spot, and then the action applies.
18. **Location delete:** deleting a Location that a town uses is refused with "This location is the location of Town '…'". Nothing is deleted.
19. **Staff/owner mode join:** log out in staff mode somewhere in gameplay and rejoin: you are where you logged out, also with a hub and during an outage.
20. **Group precedence (option (i)):** give a test account a child group with a lower weight than its parent, both held. The child's Game Settings override (e.g. join message) and a deny on the child win over the parent's. The Game Settings page lists the child above its parent.
21. **Leaving the hub ends the offer:** after an outage, walk out of the hub (or `/spawn`) instead of clicking the return; the offer ends with a message.

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
None from this session: decisions 1-5 of the overnight list and the precedence follow-up were answered on 2026-10-12 (DESIGN §16.7). Not done, but not waiting on a decision:
- **Discovery per world (KNG-118 R14/A5):** it changes the discovery spool and cache format.
- **KNG-118 D8/D9/U2/U4:** they wait for KNG-133, which has claimed the files.
