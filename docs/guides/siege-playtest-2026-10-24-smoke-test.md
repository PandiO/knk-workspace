# Siege playtest follow-ups (2026-10-24) — smoke test

**Status:** Not run yet. Implemented on branch `claude/dreamy-fermi-4h2ldl` in knk-plugin, knk-web-api, knk-web-app and knk-workspace after the developer's siege test round of 2026-10-24; unit tests pass in all three repos, nothing seen live yet.
**Branch tested:** `claude/dreamy-fermi-4h2ldl` (all four repos).
**Design:** [siege-minigame/DESIGN.md](../specs/siege-minigame/DESIGN.md) §6.4–6.6 and §11.1, [MENU_TEMPLATES.md](../specs/siege-minigame/MENU_TEMPLATES.md) C.3/C.4; the gate numbers are in knk-plugin's `config.yml` under `gates.fire-aspect` and `gates.cleaving`.
**Report back:** PASS / FAIL per step ID, plus for each FAIL the exact chat lines and what you did.

## 0. Prepare

1. **API:** run the branch and apply the migration `AddSiegeSkipSeconds` (`dotnet ef database update`). The existing configuration row gets the former fixed values (player 60 s, admin 31 s). Start the API once: the menu seed now also runs `RepairSiegeLayoutAsync`, which sets the three siege menus to `Dynamic` growth with their minimum heights and lets the "Change spawnpoint" button show in the hub. The log says `Siege menu layout repair complete. Templates updated: N`.
2. **Web app:** run the branch. **Plugin:** build `./gradlew build -x deployToDevServer` (JDK 25) or `:knk-paper:dev`; start the Paper 26.3 dev server. An existing `config.yml` keeps working (every new key has a default); copy the `gates.fire-aspect` and `gates.cleaving` blocks over if you want to tune them.
3. **Items:** a netherite sword with Fire Aspect II, and a weapon with the Cleaving lore line — `/ce add cleaving 4` (and 1, to compare) on a netherite sword, or a permanent "Enchanted Book (Cleaving IV)" from the seeded blueprints.
4. **Scenario:** one with a gate objective (closed, defender-owned, default 500 HP) and a defender team with two spawnpoints or a held `SpawnWhenHeld` objective, so the picker has something to show. Two accounts: A = defender, B = attacker.

## A. Fire Aspect on a gate

| ID | Do | Expect |
|---|---|---|
| A1 | As B (enemy of the gate's owner) in a running match, hit the closed gate door ~20 times with the Fire Aspect II sword | About a third of the hits set the struck block alight (fire charge sound, the usual door fire); the gate's HP also drops per hit as before |
| A2 | Keep hitting the same block | A burning block's fire is refreshed, not stacked; the fire-tick damage shows in the gate's HP display |
| A3 | As A (defender) hit your own gate with the same sword | Nothing catches fire (the siege veto), as with a flaming arrow |
| A4 | Outside a siege, as a survival player, hit any closed active gate | The chance applies too (the gate package rule, not a siege one) |

## B. Cleaving

| ID | Do | Expect |
|---|---|---|
| B1 | As B, left-click the closed gate with Cleaving IV on a netherite sword (no Sharpness) | 16 HP per hit (8 × 2); Cleaving I gives 10 |
| B2 | Right-click the door block with Cleaving IV | Wood-break and axe sounds, splinters, action bar "Cleaving strike!", the gate loses 128 HP; the gate does **not** open or react as a pass-through click |
| B3 | Right-click again at once | Action bar "Cleaving strike ready in N s" (counting down from 30), no damage, the click behaves as usual (enemy gate: "This gate is held by the enemy.") |
| B4 | Wait 30 s and right-click again | Another strike. With Cleaving I the cooldown is 60 s and the strike 50 HP (II: 50 s / 72 HP, III: 40 s / 98 HP) |
| B5 | As A (defender) right-click your own closed gate with a Cleaving sword | No strike, no cooldown started; the gate opens as before |
| B6 | Right-click with the sword in the off hand | No strike |
| B7 | Hit a mob or player with the Cleaving sword | Nothing special happens (it only works on gate doors) |

## C. Spawn picker in the pre-game lobby

| ID | Do | Expect |
|---|---|---|
| C1 | Join a lobby and let matchmaking run to the team split (T-10, you are at the hub) | Right after the "You are on team …" message the spawn menu opens for everyone whose team has 2+ options ("Choose a place to spawn"; header lore: "Change it later from the siege menu."). The menu is 2 rows for ≤ 9 options |
| C2 | Pick an option | Chat: "You will start the siege at X and respawn there too." No teleport yet |
| C3 | Open `/siege menu` while still at the hub | The "Change spawnpoint" compass shows (it used to show only in a running match); its lore says "Current: X" |
| C4 | Let the match start | You start at X; **no** spawn menu opens at the start |
| C5 | Die once | You respawn at X and no picker opens (the choice is remembered) |
| C6 | Change the spawn from `/siege menu` → Change spawnpoint during the match, then die | You respawn at the new choice |
| C7 | A member whose team has a single spawnpoint | No picker at the split; they start at that spawnpoint |

## D. Menu sizes

| ID | Do | Expect |
|---|---|---|
| D1 | `/siege` with one lobby in matchmaking | The overview is 2 rows: header + the lobby row |
| D2 | Open the lobby's Information with 3 players joined during matchmaking | 4 rows: header, votes/join, divider, one player row — no empty rows below |
| D3 | The same menu once the match runs with 3 objectives | 3 rows: header, divider, one objective row |
| D4 | The spawn menu with 2 options | 2 rows |

If a menu is still 5 or 6 rows after D1–D4, check the API log line from step 0.1: the repair only touches rows whose `Growth` is still `Static`; if the templates were deleted and re-created from the seed they are already right.

## E. Skip settings (web app → Siege settings → "Skipping matchmaking")

| ID | Do | Expect |
|---|---|---|
| E1 | Open the page | Two new fields: "Player skip leaves (seconds)" 60 and "Admin skip leaves (seconds)" 31 |
| E2 | Set the player value to 90, Save | "Saved 1 setting."; a reload shows 90 |
| E3 | Set the admin value to 0, Save | Refused: "adminSkipMatchmakingSeconds must be between 1 and 86400 seconds." |
| E4 | `/siege admin reload`, then as a player with `knk.siege.skip`: `/siege skip <lobby>` during a 5-minute matchmaking | "Shortened matchmaking of …: the siege begins in 1m 30s." |
| E5 | Set the player value to 10 (below "vote closes" 30), reload, skip again in a fresh matchmaking | Matchmaking is shortened to 31 s, not 10 — the floor is one second before voting closes |
