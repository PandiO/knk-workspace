# Navigation and teleports — player guide

**Status:** Current · **Last updated:** 2026-11-13 (new guide: road navigation, teleports and requests, spawn, hub, warps, `/back`, staff moves and exemptions, PandiO/knk-workspace#298)
**Checked against:** knk-plugin `main` `57884e9`, knk-web-api `master` `75b5a00`, knk-web-app `main` `3ba747d` (desk check of the code; the behaviour itself was live-tested when each part merged, see [Sources](#sources))
**Related:** [player handbook](player-handbook.md), [commands](commands.md) (every command with its rank), [menus](menus-player-guide.md) (the teleport menu), [gate structures](gate-structures-player-guide.md) (passing gates), [admin guide](../admin/navigation-and-teleports-admin-guide.md)

This guide explains how to find your way around the Knights and Kings world and how to travel fast: road
navigation with `/navigate`, and the teleports `/spawn`, `/hub`, `/warp`, `/tpa`, `/tpahere` and `/back`.

## 1. Which one do I use?

| You want to… | Use | Costs | Who |
|---|---|---|---|
| Walk somewhere and be shown the way | `/navigate <place>` (`/nav`) | Free, no wait | Everyone |
| Go back to spawn | `/spawn` | Usually free; your rank may set a price | Everyone |
| Go to the hub | `/hub` | As `/spawn` | Everyone |
| Jump to a town, district or structure | `/warp <place>` or the teleport menu (`/warp`) | Often gems | Everyone |
| Go to a friend, or bring them to you | `/tpa <player>`, `/tpahere <player>` | Usually free | `/tpa` everyone, `/tpahere` Dragon Blood |
| Return to where you died | `/back` | Usually free | Dragon Blood |

"Everyone" means the Default rank. Which rank holds what: [commands § How access works](commands.md#how-access-works).

There are **no player homes** (`/home`, `/sethome`) in V3 yet. In V1 homes belonged to houses and rooms you owned;
property ownership has no V3 version yet. Whether simple homes come before that is an open decision
(PandiO/knk-workspace#447).

## 2. Road navigation: `/navigate`

`/navigate` is a guide, not a teleport: it draws a trail of particles along the roads to where you want to go, and
you walk (or ride) there yourself. Only you see your trail.

### 2.1 Starting and stopping

| Command | What it does |
|---|---|
| `/navigate <place>` | Starts a route. Tab completion offers the places of your world. |
| `/navigate <place> spawn` | Leads to the place's spawn point instead of its edge (towns, districts, structures). |
| `/navigate <place> region` | Leads to the nearest edge of the place's area instead of its spawn point. |
| `/navigate` | Shows where you are going and how far it still is, with a clickable **[Stop]**. |
| `/navigate stop` | Ends the route: "Navigation stopped." |

**What counts as a place:** a town, district, structure (gates too), a named location, a street or a named road
point. Type the name; capitals don't matter. If several places share it, you get "Several places are called "X" -
pick one:" with clickable choices such as `town:Kardenna` and `district:Kardenna`. You can type those forms yourself:
`town:`, `district:`, `structure:`, `location:`, `street:` and `node:`. A name the game doesn't know answers "No place
called "X" was found." and, if it is close to one, "Did you mean: …" with clickable names.

**Spawn or edge?** Without `spawn` or `region`, staff decide per kind of place where a route ends (out of the box:
the spawn point). Standing inside the place's area always counts as being there: "You are already in Kardenna."

### 2.2 What you see

- **The trail:** gold particles along the next 30 blocks of the route, kept to the middle of the road.
- **The boss bar:** the next street or the destination, the distance left and the time it takes at a sprint, for
  example `→ Merchantstreet · 340 m · ~1 min`. It fills up as you go.
- **The action bar:** an arrow pointing along the trail, useful with particles turned down.
- **Turn instructions** in chat when a junction comes within 20 blocks: "In 12 m: Turn left onto Merchantstreet".
- **Arrival:** a sound and "You have arrived at Kardenna Market." when you are within 4 blocks, or inside the place's
  area.

### 2.3 Off the road

You don't have to start on a road. Within 96 blocks of one, the trail first leads you to it along a path you can walk
(round buildings, up stairs and ladders, without big drops). The same happens at the end: a place up to 96 blocks from
the road gets a walked last stretch. A place you can reach within 48 blocks is walked to straight away, without the
roads.

- A place up to 256 blocks from any road: the trail ends at the road, then "No conventional path to X found." and the
  arrow in the action bar points the way until you are close enough for a walked path.
- "No conventional path to the road found.": you seem to be shut in (a walled yard, a room). Find a way out; the
  route continues.
- "No walkable way straight to X - following the roads instead.": a short walk was blocked, so the trail uses the
  roads.

### 2.4 Gates, closed areas and changes on the way

Routes only use roads you may use **now**:

- A closed or jammed gate blocks its road. A gate you are allowed to pass gets a hint such as "Hint: right-click the
  West Gate to pass." ([gate structures](gate-structures-player-guide.md)).
- A town, district or structure that doesn't let you in (or wouldn't let you out again) is routed around.
- If no open route exists, you are told why and led as far as you can go: "No open route to Cinix Keep - the West Gate
  is closed. Guiding you to the gate." or "You may not enter Kardenna Castle. Guiding you to its edge." At that point
  you get "End of the open route to X: … The route continues when it opens - /navigate stop to end."; the route stays
  active and continues when the way opens ("The way to X is open again - following it now.").
- While you walk: "The West Gate closed - recalculating.", "A shorter route opened - following it now.", "You left the
  road - recalculating." (after 2 seconds more than 8 blocks off the route).

### 2.5 When a route ends by itself

A route ends when you log out, die, change world, teleport more than 16 blocks, join a siege, or after 30 minutes
("Navigation to X ended - the session timed out."). If staff change the road network under you: "Navigation to X ended
- the road network changed."; start it again.

### 2.6 Refusals

| Reply | Meaning |
|---|---|
| "You're too far from a road - get within 96 blocks of one." | You are too far from any road; walk closer. (The number is the server's limit: 96 out of the box, 48 when staff turn walked paths off.) |
| "X is too far from any road." | The place is more than 256 blocks from a road. |
| "No road connects you to X." | Your road and the place's road aren't connected (an island, another valley). |
| "No route to X was found." | The roads connect but no route was found. Tell staff where. |
| "X is in another world." | Routes stay in your world. |
| "X has no location and no region to navigate to." | Staff haven't set up where the place is. |
| "No road network is loaded for <world> yet." | That world has no roads mapped yet. |
| "You can't navigate while frozen." · "Your account is still loading - try again in a moment." | Wait, or ask staff. |
| "You can't navigate while you are in a siege." | You are in a siege lobby. |

**In a siege match** `/navigate` only knows the match's places (objectives, gates), and the navigation compass you get
there points to them. See the Siege player guide (`siege-player-guide.md`, PandiO/knk-workspace#297).

## 3. Teleporting yourself

### 3.1 How every player teleport works

- **Warmup:** "You need to wait 5 seconds before teleporting... Don't move." The action bar counts down. Moving to
  another block, taking damage or dying cancels it ("Teleport cancelled: you moved." / "… you took damage."). Noble and higher wait 3 seconds;
  some ranks don't wait at all.
- **Cooldown:** after a teleport you wait 30 seconds before the next one of the same kind: "You can teleport again in
  N s." Your rank can change this.
- **Combat:** no teleporting within 10 seconds of hitting or being hit by a player: "You were in combat N s ago; wait
  M s."
- **Price:** a teleport that costs something says so when the warmup starts. You pay when you arrive, not before; if
  the teleport fails you get it back. Not enough money: "You can't afford the … this teleport costs!"
- **A safe landing:** if the spot isn't safe (lava, a wall), the game looks for a safe block close by; if there is
  none: "The destination isn't safe right now."
- **Other refusals:** "You can't teleport while frozen." · "You can't teleport during a siege. Use /siege leave to
  leave it." · a town's own entry message, else "You can't teleport there." · "Teleporting isn't available right
  now." (the game can't reach the web server; try again).

`/tpcancel` stops a teleport you are waiting for.

### 3.2 `/spawn` and `/hub`

`/spawn` takes you to spawn: the spot staff chose for your rank, else the server spawn. `/hub` takes you to the hub, if
the server has one ("The hub isn't available right now." if not). Both are free unless your rank sets a price. Each
has its own cooldown; your rank's spawn price and cooldown apply to both.

### 3.3 Warps: `/warp`, `/warps` and the teleport menu

Staff can open towns, districts and structures as teleport destinations ("warps").

| Command | What it does |
|---|---|
| `/warp` (`/point`) | Opens the teleport menu ([menus guide § Teleports](menus-player-guide.md#teleports)). |
| `/warps`, `/warp list` | Lists every destination with its type, price and `Available!` or `Locked! <reason>`; click one to go. |
| `/warp <place>` | Teleports you there. Two places with one name: `/warp town:Name`, `/warp district:Name`. |

A destination can need a **title** ("Reach title X to unlock"), a **premium tier** ("Premium tier X or higher
required") or that you **discovered** it first ("Discover X first"), and it can cost **gems**. When you arrive: "You paid
N gems and your new balance is M" and "You teleported to X." "No teleport destination named 'X'." means it doesn't
exist or isn't open as a warp; "X isn't available right now." means it was closed in the meantime.

### 3.4 Asking another player: `/tpa` and `/tpahere`

| Command | What it does |
|---|---|
| `/tpa <player>` | Asks to teleport **to** them. |
| `/tpahere <player>` | Asks them to teleport **to you** (Dragon Blood). |
| `/tpaccept [player]` (`/tpyes`), `/tpdeny [player]` (`/tpno`) | Answers the newest request, or that player's. The request also shows clickable **[Accept] [Deny]**. |
| `/tpcancel` | Withdraws your request. |

A request expires after 30 seconds. You can send one every 10 seconds, and a new one replaces your previous one. A
player can have 5 waiting requests at most; the oldest drops off. The warmup applies to whoever moves, and you land
where the other player is at that moment. A request is free unless staff set a price; the asker pays. Requests to or
from vanished staff aren't possible: they read as offline.

### 3.5 `/back`

`/back` takes you back to where you died, within 5 minutes and once per death (Dragon Blood). Staff can give a rank
`/back` after a warp, a `/tpa`/`/tpahere` or a `/spawn`/`/hub` too; `/back` then goes to the latest of those places.
Each place works once. Deaths in a siege and siege teleports aren't remembered. The usual warmup, cooldown, combat
and safe-spot rules apply. On success: "Teleported back to …". "/back is turned off on this server." means staff
turned it off.

## 4. When staff move you

Staff teleport instantly, without warmup or price, and only players of their own rank or lower. You see "<staff member> sent
you to spawn." (or the hub, or a place) unless they move you silently. Region and siege rules still apply to them.

Moderators can move **every** online player at once: `/spawn all`, `/hub all`, `/tphere all` and `/tp all <player>`
(to that player). This skips the staff member, players in staff or owner mode, and **exempt** players: ranks or
players given `knk.teleport.exempt.<hub|spawn|tp|tphere>` (or all four) aren't moved by other players' teleports of that
kind, also not one by one ("X is exempt from being teleported by others."). Only the owner can still move them. Ask
staff if you need an exemption, for example while recording.

## 5. Known issues

| Issue | What you may notice |
|---|---|
| PandiO/knk-workspace#176 | In a siege, objectives behind a closed gate now lead to that gate; the fix is merged and waits for the developer's test. |
| PandiO/knk-workspace#110 | Routes can't lead to a place's entrance yet (only its spawn or its edge). |
| PandiO/knk-workspace#140 | Places with extra areas (a castle's tower) are only known by their main area for `region` routes. |
| PandiO/knk-workspace#447 | No player homes (decision). |

## Sources

1. Code: knk-plugin `knk-paper/.../navigation/` (`NavigateCommand`, `NavigationMessages`), `teleport/`,
   `commands/{Spawn,Warp,Back}Command`, `hub/HubCommand`, `plugin.yml`, `config.yml` (`teleport:`, `navigation:`);
   knk-web-api `Models/Domain.cs`, `Models/PermissionGroup.cs`, `Services/TeleportGroupPolicy.cs`.
2. Specs: [road navigation design](../../specs/navigation/DESIGN.md) § 6, [walkable last-mile paths](../../specs/navigation/LAST_MILE_PATHFINDING.md),
   [teleport design](../../specs/teleport/DESIGN.md).
3. Live tests: [road navigation smoke test](../road-navigation-smoke-test.md) (merged 2026-10-08, follow-ups to
   2026-10-17), the teleport plan's smoke tests ([plan](../../specs/teleport/IMPLEMENTATION_PLAN.md), merged
   2026-09-28 and 2026-10-06), alpha run 1 package I (`all` forms and exemptions, #171, merged 2026-11-01).
