# Domain access (AllowEntry / AllowExit) — enforcement on the game server

**Status:** Implemented, **live-tested by the developer and merged to trunk 2026-10-08** (knk-plugin `main` `790c662`, knk-web-api `master` `be7b70e`; feature commits `dfffcb7` / `32fca08`). Linear [KNG-56](https://linear.app/kngpandi/issue/KNG-56) (follows [KNG-55](https://linear.app/kngpandi/issue/KNG-55))
**Last updated:** 2026-10-08 (merged; live checklist §6 passed)
**Decision record:** [`reports/2026-10-06-domain-access-enforcement-options.md`](../reports/2026-10-06-domain-access-enforcement-options.md) (option C chosen by the developer on 2026-10-06)
**Related:** [`managed-worldguard-regions.md`](managed-worldguard-regions.md) (parent/priority/category flags on the same regions); KNG-57 (SignalR push), KNG-58 (offline cache for other data)

## 1. The rule

A player may not move **into** a domain whose `AllowEntry` is false, nor **out of** one whose `AllowExit` is false.

- **Every domain counts.** Every domain the move enters or leaves counts, not only the innermost or highest-priority one. A closed town stays closed at a border it shares with an open district. Moving between districts *inside* a closed town crosses no town border, so it is not refused.
- **Who passes:**
  - the **owners and members** of the region (WorldGuard owners/members, including those of parent regions);
  - holders of **`knk.region.bypass`** (also carried by a staff teleport of another player);
  - holders of **WorldGuard's region bypass** (`worldguard.region.bypass.<world>`, which ops have).

The rule itself is `knk-core/.../core/regions/access/RegionAccessRules` (pure, unit-tested).

## 2. Where the rules live — on the WorldGuard regions

Each domain's region carries three custom WorldGuard flags:

| Flag | Value |
|---|---|
| `knk-allow-entry` | `allow` / `deny` (from `Domain.AllowEntry`) |
| `knk-allow-exit` | `allow` / `deny` (from `Domain.AllowExit`) |
| `knk-domain-name` | the domain's name, for messages |

- **Persistence.** WorldGuard saves them with the region (regions file or database), so the **last synced rules are enforced at startup, at join and while knk-web-api is down**.
- **Registration.** They are registered in `KnKPlugin.onLoad` (`DomainAccessFlags`), before WorldGuard loads its regions.
- **Not WorldGuard's own `entry`/`exit`.** Those exempt region members by default and test only the highest-priority region, so they can't express the rule (options report §4A). WorldGuard itself does nothing with these flags.

**Sync** (`DomainAccessFlagSync`, logic in `core/regions/access/AccessFlagSync`):
- **Source:** `GET /api/Domains/access-rules` (knk-web-api, `DomainsController`) lists every domain that has a region, with id, name, wgRegionId, allowEntry, allowExit and domainType.
- **When it runs:**
  - at startup, after `regions.access.sync.delay-ticks`, with retries;
  - every `interval-minutes` (default 5);
  - on `/knk regions repair`;
  - right after a new domain region is finalized;
  - later, on a push from the API (KNG-57).
- **Writes:** a region whose flags differ is corrected. Flags on a region no domain owns any more are cleared, because a stale `deny` would lock players out for good.
- **Idempotent:** a repeat run with the same rules changes nothing and doesn't save.
- **On failure:** if the API is unreachable, nothing is touched.

**First deployment:** the flags exist only after the first successful sync. Until the API has been reached once after deploying, no rule is enforced, exactly as before.

## 3. Who enforces what

| Case | Mechanism |
|---|---|
| Walk, sprint, jump, glide, swim, ride a vehicle, mount a vehicle (WorldGuard "embark"), teleport (commands, ender pearl, chorus fruit) | `DomainAccessHandler`, a **WorldGuard session handler**. WorldGuard calls `onCrossBoundary` with the regions entered and left since the player's last allowed position. A refusal makes WorldGuard put the player back there (vehicles are stopped and sent back). WorldGuard only advances that position on an allowed move, so holding W into a border is refused on every step. |
| Mount any entity (not only vehicles) | `DomainAccessListener.onMount` (`EntityMountEvent`). Judged as a move from the player to the mount: no mounting out of a domain you may not leave, nor into one you may not enter. |
| Respawn | WorldGuard can't cancel a respawn. `DomainAccessListener.onRespawn` (HIGHEST) replaces a respawn point the player may not reach *from where they died*: a bed inside a closed domain, or a point outside a domain they may not leave. The replacement is the first allowed of: world spawn, the top of the death spot, the death spot. WorldGuard's session is then re-synced one tick later. Siege participants keep the match respawn. |
| Join | `DomainAccessListener.onUserDataLoaded`: a player standing inside a domain they may not enter is sent to the world spawn once their account has loaded (bypass is known then). It works without the API because the flags are local. |
| Teleport engine's up-front refusal (`/tp`, `/warp`, `/tpa`, ...) | `RegionTeleportRestriction` → `DomainAccessService.preview`: same rules, same flags. |

**Messages.** "You are not allowed to enter/leave X." is shown in the action bar at most once per `regions.access.message-interval-ms` (2 s, like WorldGuard).

**Load guard** (`RefusalGuard`). Only a refusal *rate* no honest client reaches leads to action: by default more than 20 refusals per second over 3 s. Pushing a border by hand gives a few per second.
- First breach: teleport to the world spawn.
- A repeat within 60 s: a kick.
- Configurable under `regions.access.load-guard`, or off.

## 4. What the region tracker still does

`WorldGuardRegionTracker` / `WorldGuardRegionListener` (now at MONITOR) **enforce nothing**. They describe moves WorldGuard allowed, from the API's domain data:
- welcome messages;
- gate control and on-demand district gate loading;
- `OnRegionEnterEvent`/`OnRegionLeaveEvent`.

`SimpleRegionTransitionService` is built with `accessChecks=false`, so a resident entering their own closed district still gets the welcome message.

## 5. Limits and follow-ups

- **Owners/residents:** no domain owner or resident data exists in knk-web-api yet (vision §2.6 `controlledBy` is long-term). Today only WorldGuard owners/members on the region pass, set by hand with `/rg addmember` or left from v1. Syncing them from the domain model is a follow-up once it exists.
- **Rule changes** reach the game server within `interval-minutes`, or immediately with `/knk regions repair`, until the SignalR push (KNG-57) lands.
- **Staff bypass during an outage:** `knk.region.bypass` is still read from the in-memory permission cache. During an outage only ops (and WorldGuard bypass holders) pass. Disk-backed permissions: KNG-58.
- **Road navigation** (unmerged branch) still asks `DomainAccessEvaluator` over the API cache. When it merges, point it at the flags (`DomainAccessService.preview` / `RegionAccessRules`), so routing and enforcement agree.
- **Mounting** is judged from the player's position to the mount's position. A mount that is moved *into* a closed domain while ridden is WorldGuard's `RIDE` case.

## 6. Live checklist (developer) — passed 2026-10-08

With a non-bypass account:
1. Hold W into an AllowEntry=false district, and out of an AllowExit=false one. Every step is refused, with one message per 2 s.
2. Glide, swim and ride a horse and a boat across both borders.
3. Mount a horse standing just inside the closed district from outside, and one just outside the no-exit district from inside.
4. Set a bed inside the closed district and die outside it: you respawn at the world spawn. Die inside the no-exit district with the world spawn outside: you respawn inside.
5. Stop knk-web-api, restart the server, and join inside the closed district: you are moved to spawn. Walk into it: refused.
6. Change AllowEntry in the web app: it is enforced within 5 min, or at once after `/knk regions repair`.
7. Add yourself as a region member (`/rg addmember`): you pass. A `knk.region.bypass` holder passes.
8. `/rg info` on a domain region shows `knk-allow-entry`, `knk-allow-exit` and `knk-domain-name`.
