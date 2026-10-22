# Navigation compass — a guide item for sieges (and beyond)

**Status:** Implemented on `claude/siege-navigation-compass-pl2trj` in knk-plugin, knk-web-api and knk-web-app; **unit-tested, not yet live-tested** (see §8). Not merged.
**Last updated:** 2026-10-22 (§10 added: the siege gives the item)
**Linear:** [KNG-234](https://linear.app/kngpandi/issue/KNG-234)
**Builds on:** [navigation/DESIGN.md](../navigation/DESIGN.md) §6 (`/navigate`), [siege-minigame](../siege-minigame/) (objectives, teams), the item blueprints.

## 1. What it is

New players lose their way in the towns a siege is played in. The **navigation compass** is an item; during a siege
match:

- **Right-click** cycles to the next place that matters to the player's team and starts navigating there (the same
  guidance as `/navigate`: road trail, HUD arrow, walk legs).
- **Shift-right-click** is the on/off switch: it stops a running navigation; when none is running it brings back
  the last target (or starts the first one if the player never chose).

Outside a siege the same item cycles a list of destinations the admin configures (§5). Siege comes first.

## 2. The list a siege player cycles

Relevance is **holder-relative**, like the capture rules (knk-plugin `knk-core/.../core/siege/ObjectiveState`):
an objective held by the player's alliance is one to *defend*, any other is one to *capture*, whatever the teams are
called and however often recapture swapped the sides. Order, top first:

1. objectives **under attack** (an enemy of the holder stands in the radius) — defenders are sent to the fight,
   attackers to the capture in progress;
2. the team's own job — defenders their objectives, attackers the ones to capture;
3. the other kind;
4. the team's **spawn** (new players lose their way back too).

Objectives captured for good (nothing left to defend or take) and objectives without a location are left out.
Inside a group the scenario's objective order holds. The list is rebuilt on every click; the position is kept by a
stable key (`objective:<id>`, `spawn:<id>`), so an objective that moves to the top because it came under attack does
not make the next click skip or repeat an entry. Each selection says what it is: `Compass 2/5: Keep Gate (defend,
under attack, 62% held)`.

Code: `knk-core` `siege/SiegeCompassTargets` (pure, tested), `navigation/compass/CompassCycle`, `CompassUse`.

## 3. Which item is the compass (decoupled from the item)

The behaviour is bound to a **rule**, not to a coded item: an item is a compass when its **material** and its
**plain display name** match the rule (`CompassItemRule`). Colour codes (`§6`, `&6`, hex) and case are ignored on
both sides, the material may carry a `minecraft:` namespace, and the name is compared as `Exact` or `Contains`. A
blank display name means "material only". So an admin can create an item blueprint whose material and default
display name equal the rule, grant it from the blueprint, and it works at once. Default rule: `COMPASS` named
`Navigation Compass`.

The rule is **data**: stored by knk-web-api, edited on the web app's roads/navigation admin page (§4), read by the
plugin (`CompassSettingsStore`: from memory, refreshed in the background once a minute, last good value kept while
the API is down, defaults before the first answer).

## 4. Settings (web app + API)

`GET/PUT api/navigation-settings/compass` (`NavigationSettingsController`; writes need `knk.admin.road` or the plugin
key, like the other navigation settings). One row (`navigation_compass_settings`, id 1) created by the first save;
without a row the defaults are answered, so nothing is seeded. Fields:

| Field | Meaning | Default |
|---|---|---|
| `enabled` | master switch; false = no item is a compass | true |
| `material` | e.g. `COMPASS`, `minecraft:recovery_compass` | `COMPASS` |
| `displayName` | plain text, colour codes ignored; empty = any name | `Navigation Compass` |
| `nameMatch` | `Exact` / `Contains` | `Exact` |
| `siegeEnabled` | works in running siege matches | true |
| `generalEnabled` | works outside sieges | false |
| `generalTargets` | outside sieges: one `/navigate` argument per line, cycle order (≤ 50 lines of ≤ 100 chars) | empty |

Web app: `NavigationCompassCard` on `/admin/roads` (next to the per-domain-type navigation defaults, KNG-73),
with a live "Matches a COMPASS whose name is “Navigation Compass”" line.

## 5. Outside a siege

When `generalEnabled`, the compass cycles `generalTargets`, each resolved by the `/navigate` catalogue
(`town:Kardenna`, `Market Square spawn`, …; a trailing `spawn`/`region` is honoured). A line the catalogue cannot
find is skipped. This is the first, deliberately simple provider; smarter ones (nearest shops, quest targets,
a player's own home) can be added behind the same `Entry` list in `NavigationCompassService`.

## 6. Decisions to review (taken as reversible defaults)

| # | Decision | Why / how to undo |
|---|---|---|
| C1 | **Navigation is now allowed for members of a *running* match.** Plan D2 ("navigation ends when the player joins a siege") still holds for the lobby, the hub and the wait after a match. `NavigationEligibility.siegeMembersOutsideMatch` is wired in `KnKPlugin`; `NavigationService.lobbyChanged` no longer ends sessions while the lobby is `IN_PROGRESS`. | The compass needs it. Undo: wire `siegeMembers` again. |
| C2 | **A match member's route goes through the lockdown's gates as if they were open** (`NavigationAccess.gateAvailability`, `SiegeGateController.isLockdownMember`). | A closed siege gate is the fight; routing would otherwise fail ("locked for a siege") at exactly the objective behind it. Non-members keep the old rule. |
| C3 | `/navigate` typed in a match is still subject to `SiegeConfiguration.AllowedCommands`; the compass is the supported way. | No new command-filter exception. |
| C4 | Shift-**right**-click only (no left-click gesture). | Left-click in the air with a compass is easy to do by accident. |
| C5 | The compass honours `knk.navigate` (default true). | Same node as `/navigate`. |
| C6 | A click on an interactable block (door, chest, button) is left to the block unless the player sneaks; a handled click denies the item's own use (an ender pearl does not fly). | Does not break gate/door interaction in a siege. |
| C7 | 250 ms click cooldown. | A client can send one click twice, which would skip an entry. |
| C8 | Settings live in their own table, not in the Game Settings object. | The developer asked for the navigation page; Game Settings stays about the server's global behaviour. |

## 7. Code map

| Repo | Where |
|---|---|
| knk-core | `navigation/compass/{CompassItemRule,CompassSettings,CompassCycle,CompassUse}`, `siege/SiegeCompassTargets`, `ports/api/NavigationCompassSettingsApi` |
| knk-api-client | `NavigationCompassSettingsApiImpl`, `dto/NavigationCompassSettingsDto`, `mapper/NavigationCompassSettingsMapper`, `KnkApiClient#getNavigationCompassSettingsApi` |
| knk-paper | `navigation/{NavigationCompassService,NavigationCompassListener,CompassSettingsStore,CompassMessages}`, `NavigationEligibility`, `NavigationService#lobbyChanged`, `NavigationAccess`, `SiegeGateController#isLockdownMember`, wiring at the end of `KnKPlugin#initializeNavigation` |
| knk-web-api | `Models/NavigationCompassSettings`, `Services/NavigationCompassSettingsService`, `NavigationSettingsController`, migration `AddNavigationCompassSettings` |
| knk-web-app | `components/admin/roads/NavigationCompassCard`, `roadClient`, `RoadDtos` |

## 8. Verification

Unit tests (all green on 2026-10-22): core `CompassItemRuleTest`, `CompassCycleTest`, `CompassSettingsTest`,
`CompassUseTest`, `SiegeCompassTargetsTest`; api-client `NavigationCompassSettingsApiImplTest`; paper
`NavigationCompassServiceTest`, `CompassSettingsStoreTest`, `CompassMessagesTest`, `NavigationEligibilityTest`, two
new `NavigationServiceTest` cases; web-api `NavigationCompassSettingsTests` (+ the endpoint-access and DI tests);
web-app `NavigationCompassCard.test.tsx` and the updated `RoadsAdminPage.test.tsx`.

**Not verified live** — needs a siege with a road network in the scenario's world:

1. Grant a `COMPASS` named `Navigation Compass` (or an item blueprint with that material/name) before a match; in the
   match right-click cycles, the trail/HUD appear, shift-right-click stops and resumes.
2. As a defender and as an attacker the order is as in §2; start a capture and see the objective jump to the top.
3. A route to an objective behind a closed lockdown gate is planned through the gate (C2).
4. Change the material/name on `/admin/roads`; within a minute the new item works and the old one stops.
5. Outside a siege with `generalEnabled` and a couple of `generalTargets`.
6. The siege's world has to have a road network and the objective locations have to be reachable by it; an objective
   far from any road falls back to the HUD arrow like any `/navigate` destination.

## 9. Open follow-ups (not built)

- Smarter outside-siege providers (§5).
- A siege `AllowedCommands` entry so `/navigate stop` works in a match (C3).
- Localised/configurable compass messages.

## 10. The siege gives the compass at the hub (added 2026-10-22)

Developer request: three levels of siege configuration decide whether players get the compass at the start of the
match, so new players have it without an admin handing it out.

**Levels and precedence (decision C9, reversible):** most specific wins — **lobby → scenario → global**.

| Level | Where | Values | Default |
|---|---|---|---|
| Global | `SiegeConfiguration.GiveNavigationItem` (Siege configuration page, "Navigation compass") | on / off | **off** (deploying changes nothing until switched on) |
| Scenario | `SiegeScenario.NavigationItem` | `Inherit` / `Give` / `DoNotGive` | `Inherit` |
| Lobby | `SiegeLobby.NavigationItem` | `Inherit` / `Give` / `DoNotGive` | `Inherit` |

A level that says `Inherit` defers to the next one up; the global level always decides. The API passes each level's
**raw** value in `GET api/siege-lobbies/runtime-config`; the plugin resolves them per match
(`SiegeNavigationItem.resolve(lobby, scenario, global)`, tested), because the lobby × scenario pair is only known when
a scenario is drawn. (Global as a kill switch that beats lobby and scenario was the other reading; say so if that is
wanted — it is a one-line change in `SiegeNavigationItem`.)

**When it is given (C10):** at the **hub** (the warm-up, `onSendToHub`), right after the vault snapshot and
`prepareForMatch`, via the new observer hook `SiegeMatchObserver.memberReadiedAtHub`. It is added to the **live**
inventory only, never the saved one.

**When it is taken away (C11):** nothing extra is coded. The vault restore (`SiegePlayerVault.applyInventory`: clear the
inventory, then set the saved contents) runs at match end, on leave/kick, on quit and on rejoin after a crash, and it
removes the compass with everything else the match put there. The siege inventory guards already stop members dropping
or storing items, and a death keeps the inventory (`SiegeDeathRespawnListener`), so the compass stays for the match.

**What is given (C12):** an item built from the compass settings (§4): the rule's material, the rule's display name
(`&` colour codes allowed; "Navigation Compass" if the name is blank), a two-line how-to lore. It is checked against the
rule before it is handed out, so a player never holds a dead item. Nothing is given when: the compass or its siege use
is switched off in the settings, the rule's material is not a real item, or the player already carries an item the rule
accepts. A full inventory gets a message and nothing is dropped. Granting an item from an item blueprint (instead of the
rule's own look) is not built.

**At the hub the compass does not navigate yet** (navigation is refused in the lobby/hub, §6 C1); clicking it says it
works once the match has started.

**Forms (needs a manual step, C13):** scenarios and lobbies are edited through the dynamic form wizard, whose bundled
seeds (`SiegeScenario.json`, `SiegeLobby.json`) are import-once and are referenced by GUID from other seeds
(`SiegeObjective`, `SiegeSpawnpoint`), so I did not ship a "v2" seed. Add one **Enum** field to each form in the form
designer: field name `NavigationItem`, label "Navigation compass", values `Inherit`, `Give`, `DoNotGive`, default
`Inherit` (SiegeScenario: e.g. on the step with "Allow recapture"; SiegeLobby: on the "General"/"Timings" step). The
global switch is a checkbox on the Siege configuration page and needs no form work.

**Migration:** `AddSiegeNavigationItem` (existing rows get `Inherit` / off).

**Live test additions:** (a) global on, lobby/scenario Inherit → compass in the inventory at the hub, gone after the match
and the restore; (b) scenario `DoNotGive` with global on → none; (c) lobby `Give` with scenario `DoNotGive` → given;
(d) a full inventory → message, nothing dropped, nothing lost at restore; (e) a player already carrying a matching
compass gets no second one; (f) leave mid-match → compass gone with the restore.

