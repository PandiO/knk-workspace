# Authoring a siege scenario (admin how-to)

**Status:** Living document — update in place
**Last updated:** 2026-09-26 (siege Phase 9, overnight chain link 1; written from the code on `claude/siege-minigame`,
not yet walked through by an admin end to end)

How an admin builds a playable siege from nothing: a banner and a clan for the defenders, a **scenario** (the map and
rules), and a **lobby** that rotates scenarios and runs matches. Design background: `docs/specs/siege-minigame/DESIGN.md`
(vision §7). Screen-by-screen detail and the forms' ids: `docs/specs/siege-minigame/IMPLEMENTATION_PLAN.md` ("Phase 3
status", "Manual steps left").

**What you need:** the web app (logged in as an admin), the API, and the Minecraft server with knk-plugin running and
you in-game. Points (hub, spawnpoints, objectives) are captured in-game via **Send to Minecraft**, so capture needs
the server. Everything else works without it.

## Words used here

- **Scenario:** the saved map and mode. It holds the town, the districts that form the siege area, a hub, teams with
  spawnpoints, gates, objectives, match length and rewards.
- **Siege / match:** one live game played on a scenario.
- **Lobby:** a joinable queue (`/siege join <key>`). It holds timings, voting and a weighted rotation of scenarios.
  Only **enabled** lobbies reach the plugin.
- **Readiness:** the API's check that a scenario can be played. A lobby only puts **ready** scenarios up for voting.

## 1. Defender identity: banner and clan (once per town)

1. `/forms/bannerdesign` → Name, base colour → Submit. Reopen it → Layers → Create New per pattern layer.
2. `/forms/clan` → Name, NPC (tick it for a town's default NPC clan), chat colour → Identity: Banner, **Default clan
   for town** → Submit.

The town's default clan is listed first when you pick a team's clan. A team can also be **ad-hoc**: no clan, with its
own name, chat colour and banner, saved only in that scenario.

## 2. The scenario

The scenario form (`/forms/siegescenario`) has 9 steps. You'll save it several times: teams, gates and objectives need
a saved scenario, and an objective's gate must already be saved in the scenario's Gates.

1. **General:** Name, Town (Select instance).
2. **Districts:** one join entry per district of the town that forms the siege area. This area is locked down during a
   match and your gate picks are checked against it.
3. **Hub & entry:** Hub location → **Send to Minecraft**, stand on the spot in-game and confirm. The hub is where
   players gather before the round (T-15) and where the area lockdown starts. Also: min/max players, optional minimum
   title, rules text.
4. **Match length, Rewards:** the defaults are fine for a first scenario.
5. **Submit** (first save). Teams, Gates and Objectives say "save first" until now; that's expected.
6. Reopen (dashboard → Edit) → **Teams:** at least 2 teams in at least 2 alliance groups, with at least one
   **Defender**.
   - Defender: role Defender, alliance group 1, clan = the town's default.
   - Attacker: role Attacker, alliance group 2, a clan or an ad-hoc identity.
   - For each team: Edit instance → **Spawnpoints** → Create New → Location → **Send to Minecraft** on the spawn → Submit.
7. **Gates:** a join entry per gate that takes part: owner team (empty = the first Defender), state at match start
   (OPEN/CLOSED), damageable → **Submit the scenario** (gates only save here).
8. Reopen → **Objectives:** at least one, ideally with one **Instant victory** objective (the keep/town hall).
   - Location objective: Name → Capture point → **Send to Minecraft** on the capture spot.
   - Gate objective: pick a saved gate. The "Gate behaviour" step then asks for its state on capture.
   - Per objective, you also set: the holder at start (a team, or none), capture points (default 500), capture radius
     (2.5), and spawn-when-held (a held objective is a spawn option for its holder).
9. **Readiness** (last step): must say **Ready**. Fix every error and press Re-check.

### Readiness codes

| Code | Fix |
| --- | --- |
| `TEAMS_MIN_TWO`, `ALLIANCES_MIN_TWO`, `DEFENDER_REQUIRED` | add teams / put them in different alliance groups / make one a Defender |
| `TEAM_NO_SPAWNPOINT` | give that team a spawnpoint |
| `TEAM_IDENTITY_INCOMPLETE` | an ad-hoc team needs a name, chat colour and banner |
| `PLAYERS_MIN_BELOW_TEAM_COUNT`, `PLAYERS_MAX_BELOW_MIN`, `DURATION_RANGE_INVALID` | fix the numbers on Hub & entry / Match length |
| `OBJECTIVES_MIN_ONE`, `OBJECTIVE_NO_CAPTURE_LOCATION` | add an objective / capture its point |
| `OBJECTIVE_GATE_NOT_SELECTED` | add that gate on the Gates step and Submit first |
| `OBJECTIVE_HOLDER_NOT_IN_SCENARIO`, `GATE_OWNER_NOT_IN_SCENARIO` | pick one of this scenario's teams |
| `DISTRICT_OUTSIDE_TOWN`, `GATE_OUTSIDE_SCENARIO_AREA` | pick districts/gates of this town and area |
| `HUB_OUTSIDE_TOWN`, `SPAWNPOINT_OUTSIDE_TOWN`, `OBJECTIVE_OUTSIDE_TOWN` | re-capture that point inside the town region |
| `TOWN_HAS_NO_REGION` | give the town a WorldGuard region first |
| warning `NO_INSTANT_VICTORY_OBJECTIVE` | allowed. The match is then decided on time and holdings |
| warning `LOCKDOWN_WITHOUT_DISTRICTS` | add districts, or untick the scenario's "Lockdown scenario area" |
| warning `SPATIAL_CHECKS_UNAVAILABLE` / `_SKIPPED` | the server was down, so the "outside town" checks didn't run. Re-check with it up |

## 3. The lobby

`/forms/siegelobby` → Name, **Key** (`[a-z0-9_-]`, what players type in `/siege join <key>`), Enabled → Timings
(matchmaking ≥ 60 s, cooldown) → Voting (1–3 candidates, optional Random) → **Rotation:** a join entry per scenario
with a **Weight** (higher = more often a candidate).

A fresh database contains one **disabled example lobby** (key `example`, no rotation). You can edit it, add a rotation
and enable it. The seed never changes an existing lobby with the key `example`, but it recreates the lobby if that key
is free, so to get rid of it rename its key (or leave it disabled) instead of deleting it.

## 4. Siege settings (global)

Nav **Siege Settings** (`/admin/siege-configuration`) holds the server-wide tuning: capture step, headshot multiplier,
banned commands, non-member gate view, title brackets and so on. The capture step defaults to the developer's playtest
tuning: attack A1 10, A2 2 (10 on instant-victory objectives), defence 6/3/6. Save sends only the changed fields.

## 5. Put it live

1. In-game: `/siege admin reload`. The plugin picks up lobby, scenario and settings changes only here or when a lobby
   enters cooldown, never mid-match.
2. `/siege admin list` → your lobby, and how many rotation scenarios are ready.
3. `/siege admin start <key>` if the lobby isn't running; players `/siege join <key>`, `/siege vote`.
4. After a match: rewards go to participants still present at the end (win, holding, capture). History is under
   `GET /api/siege-matches`.

## Pitfalls

- Gates and gate objectives: **Submit after adding gates**, then add the gate objectives. The objective's gate picker
  lists only saved gates.
- Editing a scenario that's on a running lobby's rotation takes effect at the next reload/cooldown. A match in progress
  keeps the version it started with.
- During a match the scenario's gates are under siege control: the owner team's alliance opens and closes them, and
  others see the pre-lockdown gates (see Siege Settings → non-member gate view). The gates are restored after the match,
  and on the next plugin start if the server crashed mid-match.
