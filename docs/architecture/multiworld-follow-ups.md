# Multiworld — general follow-ups (KNG-118)

**Status:** Partly implemented. This branch (`wt/kng-118`, not merged, not live-tested): R14/A5, A9, D8/D9, U2. Several
other rows are done on the unmerged hub branch `claude/blissful-fermat-b7ihrz`. U4 is planned for after the form-wizard
chain merges. Linear [KNG-118](https://linear.app/kngpandi/issue/KNG-118).
**Last updated:** 2026-10-15
**Source:** the G rows of the dated [2026-10-10 multiworld capability audit](../reports/2026-10-10-multiworld-capability-audit.md)
§2 (on the hub branch; the report is a snapshot and is not edited). Hub-blocking rows are KNG-111 to KNG-117 and the
[hub design](../specs/hub/DESIGN.md) §16.

Background: since KNG-111 (API) and KNG-112 (plugin), merged to trunk, a domain knows its Minecraft world and region ids
are unique **per world** only. This page tracks the smaller, non-hub-blocking multiworld gaps the audit found.

## 1. Status per row

| Row | Gap | Status | Where |
|---|---|---|---|
| D3 | Deleting a Location deleted its Domain (cascade) | Done on the hub branch | api `bc7b06e`, `7ec345f` (409 `LocationInUseException`) |
| D8 | District inline Location could be saved with an empty world | **Done here** | §3; api `DistrictService` |
| D9 | World-task Location without a world became `"world"` | **Done here** | §3; api `WorkflowService.ExtractLocationDataFromTaskOutput` |
| A5 | Discovery granted by raw region id | **Done here** | [discovery DESIGN §3.11](../specs/domain-discovery/DESIGN.md) |
| A9 | Runtime-worlds report replaced the whole list (one server) | **Done here** | §2 |
| U2 | Location capture without a world became `'world'` | **Done here** | §3; app `WorldBoundFieldRenderer` |
| U4 | Pickers don't show or filter by world | Partly on trunk (world column, KNG-111); rest planned, §6 | after the form-wizard chain merges |
| U5 | Game Settings spawn pickers list every world | Done on the hub branch | app `378cf0a` |
| U6 | Override precedence drift | Done on the hub branch (decision 2026-10-12: hierarchy first, then weight; supersedes D13) | api `8e34954`, app `5625dd6`, workspace `ab1d705` |
| R14 | Discovery keys and spool by region id only | **Done here** | [discovery DESIGN §3.11](../specs/domain-discovery/DESIGN.md) |
| R10 | No `PlayerChangedWorldEvent` resync of the region tracker | Done on the hub branch | plugin `3ecfcf85` |
| L3 | `/knk location tp` defaulted a blank world to `"world"` | Done on the hub branch (main world instead) | plugin `3ecfcf85` |
| L6 | Game mode not re-applied on world change | By design, kept (§4) | — |
| L7 | Gate teleport with a blank/unloaded door world | Done on the hub branch | plugin `9ac8f338`, `cd418a23` (with KNG-113) |
| G6 | Gate redefine ignored the stored world; display cleanup ignored world | Done on the hub branch | plugin `9ac8f338`, `cd418a23` |
| S3 | Siege banner log dropped entries for unloaded worlds | Done on the hub branch | plugin `3ecfcf85` |
| P4 | `knk.mode.*` grants unverified in the live database | Check for the developer, §5 | — |
| D7, G5, R15 | Other G rows of the audit, not listed in KNG-118's text | Not done | D7 needs nothing while snapshots are read by door; G5 (gate name lookup, first match in any world) and R15 (navigation inherits R1, fixed by KNG-112) are untouched |

## 2. Runtime worlds per game server (A9)

`PUT api/GameSettings/runtime-worlds` takes an optional `serverId`. The plugin sends `game-settings.server-id` from
`config.yml` (default `"default"`).

- A report replaces **only that server's** worlds. Every entry carries `serverId` and `reportedAt`.
- Another server's worlds stay until it reports again, or drop out once it hasn't reported for 30 minutes (three of the
  plugin's 10-minute heartbeats). The drop happens on the next report of any server; the per-world settings blocks
  are kept.
- Reports without a server id (older plugins), and entries stored before this change, belong to `"default"`. Entries
  stored before this change have no report time, so the first report after the upgrade replaces them.
- The same world name on two servers is listed once per server. Game Settings stay keyed by world name, so both servers
  share that world's settings. The web app's domain world prompt lists such a world once.
- No migration: the list stays in the `RuntimeWorldsJson` column. `isPrimary` is still not read anywhere.

**Live check:** with two servers on one API, give them different `game-settings.server-id` values. The Game Settings
page then shows the worlds of both. Stop one server: its worlds disappear 30 minutes after its last report, at the other
server's next report (at most 10 minutes later).

## 3. No silent world defaults (D8, D9, U2)

A world the client didn't send is refused instead of invented:

- **D8 (API).** Creating or updating a District with a *new* inline Location (no id) and no world answers 400 ("The
  District's Location needs a world.") before anything is saved. Before, the Location was stored with an empty world.
  An *existing* inline Location (with an id) keeps its stored world when none is sent; before, an empty string
  overwrote it.
- **D9 (API).** `WorkflowService.ExtractLocationDataFromTaskOutput` returns no Location when the task output names no
  world, instead of one in `"world"`. It reads `World` (what the plugin's Location task writes), `world` and `worldName`
  in any casing; before it read only `worldName`. Nothing calls this helper today.
- **U2 (web app).** A Location capture whose task output has no world no longer becomes `'world'`. The field shows the
  existing "Could not extract result from task output" banner instead, and the admin captures again.

`LocationService` already refused a blank world on create and update; L3 (`/knk location tp`) is on the hub branch.

**Live check:** capture a Location in the hub world through a form's "Create in Minecraft". The saved Location has the
hub world, not `world`.

## 4. Game mode on world change (L6): by design

The world's game mode is applied at join and when the loading hold ends, not on every world change. This is Game
Settings decision D3 and stays as it is. A world-changing feature that needs a mode sets it itself; the hub portal
applies the destination world's mode (hub DESIGN). Revisit only if a vanilla portal or another plugin's teleport must
switch the mode; the hook would be a `PlayerChangedWorldEvent` handler in `GameSettingsManager`.

## 5. Mode node grants in the live database (P4)

No migration seeds `knk.mode.staff` or `knk.mode.owner`. Run on the live MySQL to see who holds them, directly or
through a matching wildcard (a trailing `*` is a prefix match not tied to dot boundaries, and a bare `*` matches all):

```sql
-- Grants that match knk.mode.staff or knk.mode.owner, on a user or a group.
SELECT g.Id, g.Node, g.Value, g.ExpiresAt,
       u.Username AS user_name, pg.Name AS group_name, pg.Weight, pg.ParentGroupId
FROM permission_grants g
LEFT JOIN users u ON u.Id = g.HolderId
LEFT JOIN permission_groups pg ON pg.Id = g.HolderId
WHERE g.Node IN ('knk.mode.staff', 'knk.mode.owner')
   OR (g.Node LIKE '%*' AND ('knk.mode.staff' LIKE CONCAT(LEFT(g.Node, CHAR_LENGTH(g.Node) - 1), '%')
                          OR 'knk.mode.owner' LIKE CONCAT(LEFT(g.Node, CHAR_LENGTH(g.Node) - 1), '%')))
ORDER BY g.Node, group_name, user_name;

-- Members of the groups found above (put their ids in the list). Child groups inherit from
-- their ParentGroupId chain, so also list groups whose parent chain reaches one of them.
SELECT pg.Name AS group_name, u.Username, upg.ExpiresAt
FROM user_permission_groups upg
JOIN permission_groups pg ON pg.Id = upg.PermissionGroupId
JOIN users u ON u.Id = upg.UserId
WHERE upg.PermissionGroupId IN (/* group ids */)
ORDER BY pg.Name, u.Username;
```

Check per player with the resolver: `GET api/Users/{id}/permissions/check?node=knk.mode.staff` (staff with
`knk.admin.user.manage`, or the plugin key). In game, each staff member runs `/staffmode` and the owner `/ownermode`. A
refusal means the node is missing; grant it with `/knk user <player> perm grant knk.mode.staff` or on their group in
the web app. Expected: the owner's group holds `knk.mode.owner`, the staff group `knk.mode.staff`, and no player group
gets either through a wildcard.

## 6. Plan for U4 (pickers by world), after the form-wizard chain merges

On trunk, KNG-111 already shows a World column in the Town, District, Domain, Structure and GateStructure pickers
(`objectConfigs.tsx` `worldColumn`). The chain branch (`claude/wonderful-darwin-u39k1o`, KNG-166) reworks those columns
through `utils/forms/pickerRowValues.ts` (`pickerWorldName`) and the picker list DTOs. Doing U4 against trunk now would
conflict, so it waits. Once the chain is merged:

1. **Location picker shows the world.** Add a `location` entry to `columnDefinitionsRegistry` with World and X/Y/Z
   columns, read through `pickerRowValues` so pinned and searched rows agree (`world` on Location, `worldName` on
   domains).
2. **API filter.** Honour `Filters["worldName"]` in the Town, District, Structure, GateStructure and Domain
   `SearchAsync`: case-insensitive, also matching domains without a world yet, the KNG-111 lookup rule.
   `LocationRepository.SearchAsync` already filters on `Filters["world"]`; make it case-insensitive.
3. **Picker filter.** `PagedEntityTable` gets an optional world dropdown (worlds from Game Settings `runtimeWorlds`,
   deduplicated) that sets that filter. A form field can preset it from context: the parent domain's world for a
   District's Town or a Structure's District, the captured region's world for a domain's Location. The admin can clear
   it.
4. **Tests:** the repository filters (in-memory DB) and the picker columns and filter (RTL).

## 7. Decisions for developer review

- **A5/R14:** discovery sends the world with region ids, rather than resolving domain ids in the plugin (discovery
  DESIGN §3.11). A known domain without a world doesn't hide a same-named region of a real world; that costs at most one
  extra request per region per session until domains are backfilled.
- **A9:** server id from a new `game-settings.server-id` key, default `"default"`, rather than reusing
  `lootboxes.server-id`. Other servers' entries go stale after 30 minutes.
- **D8:** a new inline Location without a world is refused (400), not given the District's resolved world.
- **D9:** the unused `ExtractLocationDataFromTaskOutput` was fixed rather than removed.
