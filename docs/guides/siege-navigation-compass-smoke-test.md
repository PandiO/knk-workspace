# Siege navigation compass — smoke test (KNG-234)

**Status:** To test (written 2026-10-22). **Last updated:** 2026-10-23 (run 1 findings: sky click, hub grant visibility)
**Branch under test:** `claude/siege-navigation-compass-pl2trj` in knk-plugin, knk-web-api, knk-web-app (knk-workspace for docs). Not merged; unit-tested only.
**Design:** [navigation-compass/DESIGN.md](../specs/navigation-compass/DESIGN.md) (§6 decisions, §8, §10, §11)
**Report back:** PASS / FAIL per step ID, plus for each FAIL the exact chat lines and what you did.

## 0. Prepare

1. **API:** run the branch and apply both migrations: `AddNavigationCompassSettings` and `AddSiegeNavigationItem` (`dotnet ef database update`). Existing siege rows become `Inherit` / off.
2. **Web app:** run the branch. **Plugin:** build `./gradlew build -x deployToDevServer` (JDK 25) or `:knk-paper:dev`; start the Paper 26.3 dev server.
3. **Form designer (needed for the scenario/lobby overrides, steps D6-D8):** a fresh import of the SiegeScenario and SiegeLobby seeds already has the Enum field `NavigationItem` ("Navigation compass"; `Inherit`, `Give`, `DoNotGive`; default `Inherit`). A database that imported the seeds earlier needs the same field added by hand in the form designer (seed import never overwrites).
4. **World:** a road network in the siege scenario's world and the player-start area (`/knk road ...`), so `/navigate` works there at all. A siege scenario with at least: a defender and an attacker team (each with a spawnpoint), an **instant-victory objective ("Keep") behind a gate**, and a **gate objective ("Gate")** that is closed at the start and owned by the defenders. Objectives need a location. Min players per scenario: use two accounts (A = defender, B = attacker) or alts; a third account C as a bystander for G3.
5. **Permissions:** `knk.navigate` is default true. Staff/admin account for the admin steps. Have `/siege admin start <lobby>` available (`knk.siege.admin.control`).
6. Start with the siege global switch **off** and the compass settings at their defaults.

## A. Settings page (web app, `/admin/roads` → "Navigation compass")

| ID | Do | Expect |
|---|---|---|
| A1 | Open the page | Card shows enabled, `COMPASS`, `Navigation Compass`, `Exact`, siege on, outside-siege off, empty targets; "Matches a COMPASS whose name is “Navigation Compass”"; Save disabled |
| A2 | Change material to `RECOVERY_COMPASS`, name `Siege Compass`, match `Contains`; Save | "Saved…" message; Save disabled again; reload the page → values stay |
| A3 | Material `not a material`; Save | Error from the API, your edit stays in the field, Save still enabled |
| A4 | Tick "Works outside sieges"; enter two lines (e.g. `town:<a real town>` and `<a real structure> spawn`); Save | Saved; the textarea is only editable while that box is ticked |
| A5 | Reset to defaults (`COMPASS`, `Navigation Compass`, `Exact`) and save | Saved; used for the rest of the test |

## B. Which item is the compass (wait ≤ 1 min after any settings change)

| ID | Do | Expect |
|---|---|---|
| B1 | Hold a plain `COMPASS`, right-click in the air (outside any siege, outside-siege still off) | Vanilla: nothing happens, no message |
| B2 | `/knk item rename Navigation Compass`, right-click again | Message: the compass "has no destinations here" (it *is* recognised). Colour codes in the name (`&6Navigation Compass`) still match |
| B3 | Rename it `Compass` | No longer recognised (no message) |
| B4 | In the web app create/use an item blueprint with material `COMPASS` and default display name `Navigation Compass`; `/knk itemblueprints give <id> <player>` | The given item is recognised at once (same message as B2) |
| B5 | Set `RECOVERY_COMPASS` + `Siege Compass` + `Contains` (A2); within a minute | A `RECOVERY_COMPASS` named e.g. `Elder Siege Compass II` is recognised; the old B2 item is not. Restore defaults afterwards |
| B6 | Untick "Compass item enabled", save, wait | No item is recognised any more. Re-enable |

## C. Outside a siege (general targets)

| ID | Do | Expect |
|---|---|---|
| C1 | With the A4 targets saved: right-click **at the sky** (no block or entity in reach), and also on a block | Chat `Compass 1/2: <first target>`, navigation starts (trail/HUD) |
| C2 | Right-click again; and again | `2/2: …`, then back to `1/2` (wraps). Clicking twice within ~¼ s counts once |
| C3 | Shift-right-click while navigating | "Navigation stopped." |
| C4 | Shift-right-click again | Navigation resumes to the last target |
| C5 | Right-click a door, chest or button with the compass in hand | The block works as normal (the compass does not hijack it); sneaking + right-click on a block does the compass action |
| C6 | Remove `knk.navigate` from your account (or test with an account without it) | "You don't have permission to use the navigation compass." |
| C7 | A target line that does not exist | Skipped; the count is lower |

## D. The siege gives the compass at the hub (warm-up)

Hub = the last `hubSecondsBeforeStart` seconds before the match (default 15). Players are teleported there and their inventory is saved. No ItemBlueprint is needed: the siege builds the item from the compass rule of the web settings (material + display name).

**The plugin holds the siege configuration of a round (frozen).** A change of the global switch, a scenario or a lobby in the web app reaches the plugin only at the lobby's next cooldown or after `/siege admin reload`, and a lobby already in matchmaking/hub/match applies it afterwards ("new configuration applies at its next cooldown" in the console). So: change the setting, run `/siege admin reload`, let the current round finish (or `/siege admin skip <lobby>` / `stop` + `start`), then test the **next** round. At the hub the console prints one line per round: `[Navigation] Siege lobby '<key>', scenario '<name>': navigation compass at the hub = GIVE|no (lobby=…, scenario=…, global=… as loaded for this round)`. No such line at all = the plugin build lacks the hub grant (rebuild from the branch head); `global=false` = the round started before the setting reached the plugin.

| ID | Do | Expect |
|---|---|---|
| D1 | Global switch **off** (Siege configuration page, "Navigation compass"); join with A and B, let the hub phase start | No compass given |
| D2 | Tick "Give the navigation compass at the hub" on the Siege configuration page; Save; next match, at the hub | Both get a compass named like the rule, with the two-line how-to lore, and the chat line "You received a Navigation Compass…" |
| D3 | At the hub, right-click it | "works once the siege match has started" — no navigation yet |
| D4 | Leave the match / let it end | The compass is gone with the inventory restore; your own items are back exactly as before; the compass is not in the restored inventory |
| D5 | Join with a **full inventory** | Message "Your inventory is full, so you did not get…"; nothing dropped on the ground; your inventory intact after the restore |
| D6 | Scenario form: `NavigationItem = DoNotGive` with the global on | No compass. (Needs step 0.3) |
| D7 | Scenario `DoNotGive` but lobby form `NavigationItem = Give` | Compass given (lobby wins) |
| D8 | Lobby `DoNotGive`, scenario `Give` | None. Set both back to `Inherit` and the global on for the rest |
| D9 | Join already carrying a matching compass | No second one given |
| D10 | Compass settings: siege unticked, or item disabled | Nothing is given even with the global on. Restore |

## E. In the match (starts after the hub; use `/siege admin start <lobby>` if it does not start by itself)

| ID | Do | Expect |
|---|---|---|
| E1 | A (defender) right-click | `Compass 1/N: <objective> (defend…)`, navigation starts. Keep going: own objectives first, **team spawn last**, wraps |
| E2 | B (attacker) right-click | Objectives to capture first (`capture…`), then others, team spawn last |
| E3 | B stands on an objective (capture progress starts) | On the next click by A **and** B that objective is first with `under attack` and the `% held` / `% to go` figure; a click after it moved does not skip or repeat entries |
| E4 | Shift-right-click while navigating, again | Stops, then resumes the same target |
| E5 | Die and respawn | Compass still in the inventory (death keeps the inventory); shift-right-click resumes |
| E6 | `/navigate Kardenna` (a real town) | Refused: `"Kardenna" is not part of this match. You can navigate to: …` listing the match destinations; `/navigate`, `/nav` are not blocked by the siege command filter |
| E7 | `/navigate keep` (or a unique start of an objective name) | Navigates there; an ambiguous start lists the choices; `/navigate stop` and `/navigate` (status) work |
| E8 | Tab-complete `/navigate <Tab>` | Only `stop` and the match destinations |
| E9 | An objective far from any road | Falls back to the HUD arrow like any `/navigate` destination (not a failure) |

## F. Gates keep their real state

| ID | Do | Expect |
|---|---|---|
| F1 | B (attacker) navigates to **Keep** while **Gate** is still closed and defender-owned | Guided up to the gate, told it is locked for a siege (partial route); never through it |
| F2 | B captures **Gate** (it opens per `gateStateOnCapture`) | The route continues through by itself, no new click needed |
| F3 | A (defender) navigates to Keep while their own Gate is closed | Route passes it with a "right-click the … to pass" hint |
| F4 | Destroy/open the gate by other means mid-route | The route updates to the new state |
| F5 | C (bystander, not in the match) stands in town and uses `/navigate` | Unaffected: normal behaviour, carried through per the siege's non-member rule |

## G. Before the match and robustness

| ID | Do | Expect |
|---|---|---|
| G1 | A in the siege lobby (queued) or at the hub: `/navigate <anything>` | Refused: "can't navigate while you are in a siege" |
| G2 | Stop the API mid-match; click the compass | Still works (settings and the match are in memory); the match is not affected |
| G3 | With the API still stopped, restart the plugin/server, then use a compass outside a siege | **Known limitation:** the default rule applies until the API answers; custom rules are not remembered across a restart (the destination engine, KNG-235, fixes this) |
| G4 | Admin `/siege admin stop <lobby>` while holding the compass | Compass disappears with the restore; `/knk road why …` and normal `/navigate` work again outside the siege |

## What to report

For each ID: PASS/FAIL. For FAILs: the chat lines, whether the road network/objective location was in range, and `/knk road why <destination>` output for navigation problems. Also note anything awkward (wording, order, timing) even when it passes.
