# Navigation destination engine — smoke test

**Status:** Draft from the design (2026-11-18); no steps run. Steps not yet automated (the links tag them).
**Last updated:** 2026-11-18 (draft from the design refresh, phases 1, 2, 3, 4, 4b and 5)
**Design:** [specs/navigation-destination-engine/DESIGN.md](../specs/navigation-destination-engine/DESIGN.md) · **Issue:**
[PandiO/knk-workspace#25](https://github.com/PandiO/knk-workspace/issues/25)

The engine decides which places a player may navigate to. Phases 1 and 2 change nothing a player sees; phases 3 and 4
are behind `navigation.destination-engine` (default `false`), and with it off navigation must behave exactly as
before. Phase 4b removes the flag. Acceptance ids (A01…) are in DESIGN § 13; sections are sized by the phase's tier
(proposed, DESIGN § 10).

Accounts and data used throughout:

1. **Player:** an ordinary account with `knk.navigate` (default), not staff.
2. **Staff:** an account that can switch owner or staff mode and freeze players (`/knk mode staff`).
3. **Bypass:** an ordinary account given `knk.navigate.any` (not granted by default).
4. **Dev world:** the world with the road network, at least one town with a spawn Location, one district without a
   spawn Location (region only), one named street and one Location target; a second world with a domain of its own.
5. **Siege:** a siege scenario with two teams, at least one capture objective behind a closed gate (#176), and the
   navigation compass enabled for sieges in the web app's compass settings.

## 1. Phase 1: pure engine in knk-core (#96, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

Nothing is wired in this phase: the engine is code and tests only. The manual check is that nothing changed.

### 1.0 Preconditions

1. Deployed: plugin build from `next` with phase 1 merged.
2. Settings: none new.
3. Accounts and data: Player, Staff; the dev world; the siege scenario.

### 1.1 Steps

1. Read the P1 pull request's Testing section. **Expected:** tests for every scope of DESIGN § 4.1 (A01–A06), name
   resolution in the world and in a match (A07), other-world places (A08), the handle rule in `ArchitectureGuardTest`
   and revalidation by key, and a landmark-like provider in the World scope (A09), all green in CI.
2. As Player, `/navigate` a town, a street and a Location target, and press Tab after `/navigate ` and after a few
   letters. **Expected:** the same routes, messages and suggestions as before the update.
3. As Player in a running siege match, right-click the compass a few times and type `/navigate ` with Tab.
   **Expected:** the same objectives and team spawn as before, in the same order; other places are refused with the
   same message.

## 2. Phase 2: navigation model and offline snapshot (#103, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 2.0 Preconditions

1. Deployed: knk-web-api from `next` with the domain search Location field; plugin build from `next` with phase 2.
2. Settings: `navigation.destinations.stale-after-days: 14` (default).
3. Accounts and data: Staff; the dev world with a town that has a spawn Location and a district without one.

### 2.1 Steps

1. As Staff in the web app or with an API client, run the domain search (`POST api/Domains/search`). **Expected:** each
   domain carries `location` (x, y, z, yaw, pitch, world) when it has one and `null` when it has none; the other
   fields are unchanged. (A10)
2. Start the server with the API up and wait a minute. **Expected:**
   `plugins/KnK/offline/navigation-model.json` exists, holds domains, Locations and compass settings, and no player
   names or UUIDs. (A11)
3. Stop the web API, restart the game server, then as Player `/navigate` the town by name. **Expected:** before the
   engine is switched on (phase 3) this still behaves as today; the server log shows the snapshot was loaded at
   start-up, with its age. (A12, the player-facing part is phase 3's step 3.3)
4. Stop the server, replace the snapshot file's content with `{ broken`, start again. **Expected:** a log line that
   the snapshot was ignored, no error that stops the plugin; the next good refresh writes a new file. (A13)
5. With the API up, rename the town in the web app and wait for the next refresh (about a minute). **Expected:** the
   snapshot holds the new name and not the old one. (A14)

## 3. Phase 3: switch-over behind the flag (#69, tier:3)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 3.0 Preconditions

1. Deployed: plugin build from `next` with phases 1 to 3; knk-web-api as in § 2.
2. Settings: first `navigation.destination-engine: false`, then `true` (`/knk reload` or a restart, as the link's
   deploy notes say).
3. Accounts and data: Player, Staff, Bypass; the dev world and the second world; the siege scenario.

### 3.1 Flag off

1. With the flag off, repeat § 1.1 steps 2 and 3. **Expected:** exactly today's behaviour. (A16)

### 3.2 Flag on, outside a siege

1. As Player, `/navigate <town>`, `/navigate <town> spawn`, `/navigate <district> region`, `/navigate street:<name>`
   and `/navigate location:<name>`. **Expected:** the same routes as with the flag off; no delay at click time. (A17)
2. As Player, Tab after `/navigate ` and after `town:`. **Expected:** the same suggestions as with the flag off; places
   of the second world are not suggested. (A17, A08)
3. As Player, `/navigate <domain of the second world>`. **Expected:** "… is in another world" as today. (A08)
4. As Player, type a misspelt town name. **Expected:** "unknown destination" and a "did you mean" line as today. (A07)
5. As Player, right-click the compass outside a siege with general targets configured. **Expected:** it cycles the
   configured targets as today; with the general switch off it says "The navigation compass has no destinations
   here." while `/navigate` still works. (A19)
6. As Staff, run `/knk road why <town>`. **Expected:** the explanation as today. (A20)
7. As Player, walk a route that passes a domain whose road access is "Ignored". **Expected:** the route uses its
   roads as before. (A21)

### 3.3 Flag on, API down

1. Stop the web API, restart the game server, then as Player `/navigate <town>` and right-click the compass.
   **Expected:** the town is found and routed from the snapshot; the compass uses the saved settings, not the
   defaults. (A12, A17)
2. Stop the server, delete `navigation-model.json`, start with the API still down, then `/navigate ` with Tab.
   **Expected:** streets and named nodes are offered; towns are not; `/navigate` and the compass say "Some places
   aren't available while the web API is down.". (A13)

### 3.4 Flag on, in a siege match

1. As Player in a running match, Tab after `/navigate `. **Expected:** only the match's objectives, the team spawn and
   `stop`. (A18)
2. As Player, `/navigate objective:<name>` and `/navigate <start of an objective name>`. **Expected:** both start a
   route to that objective. (A18, A07)
3. As Player, `/navigate <town>`. **Expected:** refused; the message names the match's destinations. (A18)
4. As Player of the attacking team, select the objective behind the closed gate with the compass. **Expected:** the
   route leads to the gate, not the capture point (#176). (A18)
5. Switch the compass off for sieges in the web app, wait a minute, then `/navigate ` and right-click the compass.
   **Expected:** `/navigate` says "This match has no destinations to navigate to."; the compass says "The navigation
   compass is switched off during sieges.". (A05, A19)
6. As Bypass in the match, `/navigate <town>`. **Expected:** a route starts (the bypass lists everything). (A03)
7. As Player, select an objective with the compass, stop with shift-click, then shift-click again. **Expected:** the
   compass resumes the same objective while it is still listed. (A19)

## 4. Phase 4: hard blocks as scopes and live re-validation (#62, tier:3)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 4.0 Preconditions

1. Deployed: plugin build from `next` with phases 1 to 4.
2. Settings: `navigation.destination-engine: true`.
3. Accounts and data: Player, Staff, Bypass; the siege scenario.

### 4.1 Steps

1. As Player right after joining (account still loading), `/navigate <town>`. **Expected:** "Your account is still
   loading - try again in a moment.". (A22)
2. As Staff, freeze Player, then as Player `/navigate <town>`. **Expected:** "You can't navigate while frozen.". (A22)
3. As Staff in staff mode, have another staff member of higher rank freeze you, then `/navigate <town>`. **Expected:**
   refused while frozen, as for anyone (E9). (A02, A25)
4. Remove `knk.navigate` from Player, `/navigate <town>`. **Expected:** "You don't have permission to use
   /navigate.". (A22, A04)
5. As Player in a siege lobby before the match, `/navigate <town>` and right-click the compass. **Expected:**
   `/navigate`: "You can't navigate while you are in a siege."; the compass: "The navigation compass works once the
   siege match has started.". (A22, A06)
6. As Player, start a route to a town, then join a siege lobby. **Expected:** the route ends at once with "You can't
   navigate while you are in a siege.". (A23, A24, A26)
7. As Player in a running match, navigate to a capture objective; let the other team capture it so it is no longer
   listed for you. **Expected:** the route ends at once with the scope's reason; if it is still listed as "defend",
   the route keeps going. (A23, A24, A25)
8. As Player, navigate to an objective, then let the match end. **Expected:** the route ends at once with the reason
   of the scope you are in now. (A24)
9. As Staff in staff mode in a match, `/navigate <town>`; then switch staff mode off. **Expected:** the route starts;
   after switching off it ends at once with the match's reason. (A25)
10. As Player navigating to a town, have Staff freeze you. **Expected:** the route ends at once with "You can't
    navigate while frozen.". (A23, A24)

## 5. Phase 4b: removal of the old paths and the flag (sub-issue to be filed on approval, tier:2)

*Draft from the design (2026-11-18); the link updates it to what was built and tags the automated steps.*

### 5.0 Preconditions

1. Deployed: plugin build from `next` with phase 4b; the developer has run § 3 and § 4 with the flag on.
2. Settings: `navigation.destination-engine` removed from `config.yml` (the deploy notes say so).
3. Accounts and data: as in § 3.

### 5.1 Steps

1. Start the server without the flag. **Expected:** no warning about an unknown or missing key; navigation uses the
   engine. (A27)
2. Repeat § 3.2 steps 1, 2 and 5, § 3.4 steps 1, 3 and 5, and § 4.1 steps 5 and 6. **Expected:** as written there.
   (A28)

## 6. Phase 5: arena duels provider and scope (#55, tier:2)

*Draft from the design (2026-11-18); written in full when the arena duels work is merged and the phase is scheduled.*

### 6.0 Preconditions

1. Deployed: plugin build from `next` with phase 5 and the arena duels work.
2. Settings: arena duels enabled.
3. Accounts and data: two Players in a duel.

### 6.1 Steps

1. As a Player in a running duel, Tab after `/navigate ` and `/navigate <town>`. **Expected:** only the duel's places
   are offered; the town is refused with the duel's reason. (A29)
2. As a Player queued or in the duel's lobby, `/navigate <town>`. **Expected:** refused with the duel's reason. (A29)
3. After the duel, `/navigate <town>`. **Expected:** a route starts as usual. (A29)
