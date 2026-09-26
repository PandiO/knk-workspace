# Private Messages & Social Spy — Design

**Status:** Draft — awaiting developer review (open questions in §5)
**Last updated:** 2026-09-26
**Linear:** _TBD_
**Sources:** `docs/specs/legacy/commands-v1.md` (§ "/message … /reply … socialSpy"), `commands-v2.md`
("v1 → v2 command comparison"), `events-v1.md` / `events-v2.md` (chat listeners), v1 source
`knk-v1-archive/src/UsefulCommands/MessageCommands.java`, `Main/Main.java`, `plugin.yml`, `Users/User.java`;
v2 source `knk-v2-archive` (searched); v3 `knk-plugin` `main` @ `f65ae2e` (read from a fresh clone — the
local checkout is on `claude/intelligent-newton-73pcsl`, whose messaging files are byte-identical) and
`claude/siege-minigame` @ `0fa6d06`; `knk-web-api` `master` @ `a102eea`; `docs/specs/user-features/{DESIGN,
RANK_DISPLAY,COMMAND_CATALOG_V3}.md`, `docs/specs/user-management/DESIGN.md`,
`docs/specs/inventory-menu/CONTENT_PORT_PLAN.md` §9 (CP7), `docs/specs/siege-minigame/{DESIGN,
IMPLEMENTATION_PLAN}.md`, `docs/vision/vision.md` §6.

Path shorthands: `P:` = `knk-plugin:knk-paper/src/main/java/net/knightsandkings/knk/paper/`,
`A:` = `knk-web-api:` (repo root), `v1:` = `knk-v1-archive:`.

---

## 0. Scope

**In:**
- `/msg` (aliases `/message`, `/tell`, `/whisper`, `/w`, `/m`, `/pm`) and `/reply` (`/r`) — the
  existing v3 rebuild, hardened (vanish, console, formatting, rate limiting, vanilla bypass).
- Social spy: `/socialspy` toggle, audience rules, exemption for owners' messages.
- Ignore list (`/ignore`, `/unignore`) persisted through knk-web-api; applies to PMs and public chat.
- PM logging for moderation: plugin-local file log first, server-side log + retention + web viewer later.
- Adventure components: coloured names, hover text, click-to-reply.

**Out (explicitly):**
- **Mute.** Neither v1, v2 nor v3 has one. Chat offences belong to the vision's jail/justice system
  (`docs/vision/vision.md` §6). This design only leaves a hook (§3.3.6) a later mute plugs into.
- **Mail / offline messages.** No legacy precedent (searched v1/v2 for `mail`, `offline message`).
- **AFK notices.** v1's AFK (`v1:src/Afk/`) never touched PMs and v3 has no AFK at all.
- **PM toggle** ("block all PMs"). No legacy precedent; ignore covers the harassment case.
- **Staff chat** (`/staffchat`) itself — only its coupling to social spy is changed (§3.3.4).
- Public-chat formatting and mention pings (KNG-7/KNG-8, `PlayerListener.onChat`) — only the ignore
  filter is added there.

---

## 1. Legacy design

### 1.1 v1 (Bukkit 1.8, `MessageCommands.java`)

**Commands** (`v1:plugin.yml:125-130`; registered `v1:src/Main/Main.java:647-650`):

| Command | Syntax | Permission | Behaviour |
|---|---|---|---|
| `/message` (alias `/msg`) | `<player> <message…>` | none | player-only (`:39`, else "You need to be a player to perform this command!"); `args.length >= 2` else usage `-/message <player> <message>` (`:42`, `:86`) |
| `/reply` (alias `/r`) | `<message…>` | none | player-only; needs a `msgReceived` entry (`:99`, else "You have nobody to reply to!" `:129`) and `args.length >= 1` (else `-/reply <message>` `:125`) |

**/message flow** (`v1:src/UsefulCommands/MessageCommands.java:37-92`): self-check compares the *typed* name
to the sender's name (`:45`, "You can't message yourself! Pretty weird that you tried tho.." `:82`); target via
`Bukkit.getPlayer(name)` (`:47`, **prefix match** on 1.8); message joined without a leading space (`:49-59`);
reply map written for **both** parties (`:63-64`); sender sees `§7[§9me -> <target>§7] <msg>` and target sees
`§7[§9<sender> -> me§7] <msg>` (`ColorOptions.message` = GRAY `v1:src/Handlers/ColorOptions.java:33`, `ChatColor.BLUE`,
`:65-66`); target hears `NOTE_PLING` volume **1.0**, pitch **1.0** (`:67`, `SoundHandler.java:42`). Offline target:
"This player is not online!" if `Users.existUser(name)`, else "No player could be found named <name>" (`:72-78`).

**/reply flow** (`:93-135`): partner username from `main.msgReceived` (`HashMap<UUID,String>`, `v1:src/Main/Main.java:303`),
`Bukkit.getPlayer(username)` (`:104`), else "This player is not online anymore!" (`:121`). Message built with a leading
space (`:106-110`). Only the *target's* map entry is refreshed (`:116`) — the sender's already points at the target.

**socialSpy** (`:139-161`) — not a command, always on:
- Viewers with `k&k.staff` and **not** `k&k.owner` receive `§7[§9<sender> -> <target>§7] <msg>` **unless the sender
  holds `k&k.owner`** (`:146-151`) — owners' outgoing PMs are hidden from ordinary staff. (`commands-v1.md` omits this
  sender-owner exclusion.)
- Viewers in owner mode (`main.ownermodus.get(uuid) == true`) receive every PM (`:152-159`). Owners outside owner mode
  receive nothing; staff cannot turn it off.
- Participants excluded by `uuid != senderUUID` — reference comparison of `UUID`s (`:148`, `:155`).

**Related v1 state:** `ownermodus` (`v1:src/Main/Main.java:280`) is also v1's vanish: `User.setOwnerMode(true)` hides
the owner from everyone without `k&k.staff` (`v1:src/Users/User.java:863-893`). No ignore list, mute, PM toggle, mail,
or chat log exists anywhere in v1 (searched `mute`, `ignore`, `spy`, `mail`); the only mention machinery is
`PlayerListener.onChat`'s mention ping (`events-v1.md` §`onChat`, `PlayerListener.java:825-844`).

**v1 bugs/exploits worth not repeating:**
1. **Prefix-match misdirection.** `/msg Pan hi` resolves to "Pandi" and stores the typed "Pan" as the reply partner
   (`:64`); a later `/r` re-resolves "Pan" by prefix and can reach a *different* player who joined since.
2. **Self-message bypass** via prefix (`/msg Pan` while you are "Pandi" passes the `:45` check).
3. **Vanish leak.** `Bukkit.getPlayer` finds vanished owners, so `/msg <owner>` succeeds and reveals presence; the
   offline/unknown distinction (`:72-78`) also reveals whether an account exists.
4. **Account-existence oracle** (same `:72-78`): "not online" vs "no player named".
5. Reference-equality UUID checks in socialSpy (`:148`, `:155`), harmless in practice.
6. Reply partner stored by **username** — breaks on a name change; never cleared (`msgReceived.remove` never called).
7. `/reply` leading-space message (`:106-110`).

### 1.2 v2

Dropped. `MessageCommands` is listed among the utilities with no v2 equivalent (`commands-v2.md`, "v1 → v2 command
comparison"); a search of `knk-v2-archive` for `msg`, `reply`, `tell`, `whisper`, `spy`, `mute`, `ignore` finds nothing.
v2's only chat listener (`v2:…/listeners/PlayerListener.java:186-234`, `events-v2.md`) formats public chat and pings
mentions.

### 1.3 v3 today (`knk-plugin` `main`)

Rebuilt on 2026-09-25 in commit `2df0383` ("Add rank/staff-management commands: … messaging"):

| Piece | Where | Behaviour |
|---|---|---|
| `/msg` (aliases `tell`, `w`), no permission | `knk-plugin:knk-paper/src/main/resources/plugin.yml:62-66`; `P:commands/MessageCommand.java`; registered `P:KnKPlugin.java:898` via `registerSimpleCommand` (no tab completer) | `args < 2` → YELLOW "Usage: /msg <player> <message>"; `Bukkit.getPlayerExact` (`:26`) → RED "No online player found named '<x>'." (`:28`, one message for offline/unknown — good); self → "You can't message yourself." (`:31-33`). **Console may send.** |
| `/reply` (alias `r`), no permission | `plugin.yml:68-72`; `P:commands/ReplyCommand.java`; `KnKPlugin.java:899` | player-only (`:60-62`); target null/offline → "No one to reply to." (`:69-71`). |
| `MessagingService` | `P:user/MessagingService.java` (created `KnKPlugin.java:473`) | Sender `§7[me -> X] §f<msg>`, target `§7[S -> me] §f<msg>` (message now WHITE, v1 GRAY) (`:30-31`); `BLOCK_NOTE_BLOCK_PLING` volume **0.5**, pitch 1.0 (`:32`); reciprocal `lastPartner` `ConcurrentHashMap<UUID,UUID>` written only when the sender is a player (`:34-37`); `forget(uuid)` exists (`:51-53`) but **nothing calls it**. |
| Social spy | `MessagingService.socialSpy` (`:55-66`) | Always on, to every online `Player.hasPermission("knk.staffchat")` except the two participants: `§8[Spy] S -> T: §7<msg>`. No toggle, no exemption, no log. |
| `knk.staffchat` | `plugin.yml:396-400`, `default: op` | Documented as "also determines who receives the /msg social spy". |

**Surrounding v3 systems:**
- **In-house permissions** (`docs/specs/user-features/DESIGN.md` §2) resolve through knk-web-api and are read in the
  plugin via `P:permissions/KnkPermissible.java` (sync cache-only + async; op bypass `:73-75`). **They are not bridged
  into Bukkit's `Permissible`** — no `addAttachment`/`PermissibleBase` anywhere in the plugin. So
  `online.hasPermission("knk.staffchat")` is true **only for ops** (plugin.yml default) unless a Bukkit permissions
  plugin is installed (none is declared: `plugin.yml:6-9` depends only on WorldGuard/WorldEdit). Social spy today =
  ops only; `StaffChatCommand` (`P:commands/StaffChatCommand.java:31,36`) has the same problem.
- **Vanish** = `ActiveMode` OWNER/STAFF (`P:modes/ModeService.java`): per-viewer `hidePlayer`/`showPlayer` (`:196-209`),
  visible to holders of `knk.mode.staff`/`knk.mode.owner`. So `Player.canSee(target)` is the correct "may this sender
  know the target is online" oracle — **but nothing in the plugin calls `canSee`** (searched). `/msg <vanished>` delivers
  and echoes the name: the v1 vanish leak is still present. Tab completion is safe by accident: with no `TabCompleter`,
  Bukkit's default `Command.tabComplete` lists only players the sender `canSee`.
- **Chat rendering** (KNG-7/8): `P:chat/ChatLineFormat.java` (Bukkit-free, unit-tested) + `PlayerListener.onChat`
  (`P:listeners/PlayerListener.java:319-360`, `AsyncChatEvent`, cached `UserSummary` via `getStale`), rank team colours
  in `P:utils/TabListTeam.java`. Public chat translates `&` codes for **every** player (`:327`).
- **Freeze** (`P:listeners/AdminFreezeListener.java:67-83`) cancels all chat and **all commands** for a frozen player,
  including `/msg` and `/r` — a frozen player cannot answer the staff member who froze them (v1's design intent was the
  opposite: "shouldn't be able to talk, only to the member of staff that freezed the player",
  `v1:src/UsefulCommands/FreezeCommands.java:21-22`).
- **Mute:** none (searched plugin and API for `mute`).
- **Audit log** (knk-web-api): `A:Models/AuditLogEntry.cs` (append-only, no FK to `User` by design), `A:Enums/AuditAction.cs`
  (0–11), `A:Services/AuditLogService.cs` `RecordAsync`, `GET api/audit-log` (`A:Controllers/AuditLogController.cs`,
  **no `[Authorize]`**), retention singleton `A:Models/AuditLogRetentionConfiguration.cs` (default **180** days) enforced
  daily by `A:Services/RetentionPolicyService.cs` (`RunAuditLogCleanupAsync`, `:100`).
- **API auth reality** (`CONTENT_PORT_PLAN.md` §9 "CP7 status"): the plugin ships `api.auth.type: none`
  (`knk-plugin:knk-paper/src/main/resources/config.yml:13-21`); knk-web-api has JWT only and most endpoints are anonymous;
  `RequireAdmin` (`A:Program.cs:148-156`) needs a role claim `TokenService` never issues. Anything the plugin writes, anyone
  on the network can write.
- **Paper command log:** Spigot's `commands.log` (default `true`) writes `<name> issued server command: /msg Bob hi` to
  `logs/latest.log` — so every PM is already persisted in plain text, with no retention limit, today.
- **Vanilla bypass:** plugin labels shadow vanilla `/msg`/`/tell`/`/w`, but `/minecraft:msg`, `/minecraft:tell`,
  `/minecraft:w`, `/teammsg`/`/tm` and `/me` remain (permission level 0, granted by default). They skip spy, ignore,
  logging and rate limits. `/teammsg` is worse than a PM: every non-premium player shares the `default` scoreboard team
  (`TabListTeam.java:40-43`), so `/tm` is an un-spied broadcast to all of them.
- **Siege command filter** (`claude/siege-minigame`): `SiegeConfiguration.AllowedCommands` default
  `"/siege,/msg,/r,/staffchat,/menu"` (`A:Models/Siege/SiegeConfiguration.cs:54`); `SiegeCommandFilter.label` strips the
  namespace and does **not** resolve aliases (`knk-core/…/core/siege/SiegeCommandFilter.java:40-49`). So in a siege `/tell`,
  `/w`, `/reply` are blocked while `/minecraft:msg` passes.

**v3 bugs/gaps (current code):**
1. Vanished staff reachable and revealed by `/msg` (above).
2. Social spy reaches ops only (Bukkit-node vs in-house-node mismatch); no toggle, no owner exemption.
3. Console can send, but nobody can `/r` to console and console cannot `/r` (`ReplyCommand.java:60`; `MessagingService.java:34`).
4. `MessagingService` Javadoc says the reply map is "updated one-directionally on reply (matches v1)"; the code writes both
   directions on every send. Behaviourally equivalent — the comment is wrong, not the code.
5. No rate limit, no length cap beyond the client's 256-char input, no ignore, no log beyond Paper's command log.
6. Legacy `ChatColor` strings; no hover/click.
7. Vanilla messaging commands bypass everything (above).

---

## 2. Gap analysis

| Capability | v1/v2 behaviour | v3 today | Reusable v3 component (path) | Work needed |
|---|---|---|---|---|
| `/msg` + aliases | `/message`,`/msg` (v1); none (v2) | `/msg`,`/tell`,`/w` | `P:commands/MessageCommand.java`, `plugin.yml:62-66` | S — add `message`,`whisper`,`m`,`pm`; tab completer |
| `/reply` | `/reply`,`/r`, username-keyed | `/reply`,`/r`, UUID-keyed | `P:user/MessagingService.java` | S — console partner, offline/vanish edge cases |
| Target resolution | prefix match; offline vs unknown messages | exact match; one "not found" message | `PlayerCommandSupport.onlinePlayer` (`P:commands/support/PlayerCommandSupport.java:83`) | S — `canSee`-aware resolver |
| Vanish safety | leaks | leaks via `/msg`; tab-complete safe | `ModeService` visibility (`P:modes/ModeService.java:196-209`) + `Player.canSee` | S |
| Social spy audience | staff always; owners only in owner mode; owners' PMs hidden from staff | Bukkit `knk.staffchat` → ops only | `KnkPermissible` (`P:permissions/KnkPermissible.java`) | M — `SpyService` with cached audience |
| Social spy toggle | none (always on) | none | player PDC (`NamespacedKey`/PDC already used across the plugin) | S |
| Ignore list | none | none | `UserAdminService.resolveTarget` (offline lookup), `UserCache` | M — API entity + endpoints + plugin cache + chat filter |
| PM log (local) | none (Bukkit log only) | Paper command log only | — | S |
| PM log (server) | none | none | `AuditLogEntry` pattern, `RetentionPolicyService`, `AuditLogRetentionConfiguration` | M — **blocked on plugin API auth (CP7)** |
| PM log viewer | none | none | `knk-web-app:src/pages/admin/PlayerProfilePage.tsx` (Recent activity pattern), `userManagementClient.ts` | S–M |
| Rate limit / spam | none | none | `InMemoryCooldownManager` (`P:enchantment/`) is enchant-specific; build a small limiter in knk-core | S |
| Formatting | legacy strings, GRAY/BLUE | legacy strings, GRAY/WHITE | `ColorOptions`, `TabListTeam` colours, Adventure (already used in `ChatLineFormat`) | S |
| Hover/click to reply | none | none | Adventure `ClickEvent.suggestCommand` / `HoverEvent.showText` (no precedent in plugin yet) | S |
| Sound | NOTE_PLING 1.0/1.0 | PLING 0.5/1.0 | `MessagingService.java:32` | S — config |
| Vanilla bypass | n/a (1.8) | open | `SiegeCommandFilterListener` pattern (`PlayerCommandPreprocessEvent`) | S |
| Frozen player can answer staff | intended, never built | blocked | `AdminFreezeListener.onCommand` (`:76-83`) | S |
| Mute | none | none | hook only | — (out of scope) |

**Reuse as-is:** `KnkPermissible`, `ModeService` visibility (via `canSee`), `ChatLineFormat`'s Bukkit-free-builder pattern,
`TabListTeam.resolve` colours, `UserCache.getStale`, `UserAdminService.resolveTarget`, `AuditLogEntry`'s no-FK
convention, `RetentionPolicyService`. **Extend:** `MessagingService` (becomes the orchestrator), `MessageCommand`/`ReplyCommand`,
`AdminFreezeListener`, `PlayerListener.onChat` (ignore filter), `AuditLogRetentionConfiguration` (second retention field),
`PlayerProfilePage`. **New:** knk-core `core/messaging/` rules, `SpyService`, `IgnoreService`, `PrivateMessageLogger`,
`VanillaMessagingBlockListener`, API `UserIgnore` + `PrivateMessageLogEntry` entities/endpoints.

---

## 3. v3 design

### 3.1 Data model (knk-web-api)

**`UserIgnore`** (Phase 2) — `A:Models/UserIgnore.cs`, migration `AddPrivateMessagesIgnoreList`:

| Column | Type | Notes |
|---|---|---|
| `Id` | int PK | |
| `UserId` | int, FK → `User.Id`, cascade delete | the player doing the ignoring |
| `IgnoredUserId` | int, FK → `User.Id`, cascade delete | |
| `CreatedAt` | DateTime (UTC) | |

Unique index `(UserId, IgnoredUserId)`; index `IgnoredUserId`. Service rules: no self-ignore; max **100** rows per user;
target must not hold `knk.msg.unignorable` (checked with `IPermissionResolutionService.CheckAsync`). Not
`[FormConfigurableEntity]` — managed only through its endpoints.

**`PrivateMessageLogEntry`** (Phase 3) — `A:Models/PrivateMessageLogEntry.cs`, migration `AddPrivateMessageLog`:

| Column | Type | Notes |
|---|---|---|
| `Id` | long PK | high volume |
| `SentAt` | DateTime (UTC) | plugin clock, set at send time |
| `ClientMessageId` | Guid, unique | plugin-generated; makes batch retries idempotent |
| `SenderUserId` / `RecipientUserId` | int? | plain columns, **no FK** (audit precedent, `AuditLogEntry.cs` summary); null = console |
| `SenderName` / `RecipientName` | varchar(16) | name at send time (survives renames/deletes) |
| `Content` | varchar(512) | plain text as typed |
| `Outcome` | enum `PrivateMessageOutcome` | `Delivered`, `BlockedIgnored`, `BlockedRateLimited`, `BlockedFrozen` |
| `ViaReply` | bool | |

Indexes `(SenderUserId, SentAt)`, `(RecipientUserId, SentAt)`, `SentAt`. Retention: new column
`AuditLogRetentionConfiguration.PrivateMessageRetentionDays` (default **30**), enforced by a third try/catch block in
`RetentionPolicyService` (`DeleteOlderThanAsync` on the new repository), same daily cadence.

No other schema: the social-spy toggle lives in player PDC (§4 D3), reply targets and rate-limit state are in-memory.

### 3.2 API endpoints (knk-web-api)

| Method + route | Controller | Body / response | Auth |
|---|---|---|---|
| `GET api/users/{id}/ignores` | new `A:Controllers/UserIgnoresController.cs` | `UserIgnoreDto[]` `{ignoredUserId, ignoredUsername, createdAt}` | plugin (anonymous today, like every plugin call) **or** JWT with `uid == id` |
| `PUT api/users/{id}/ignores/{ignoredUserId}` | same | 204 created/already present; 400 `SelfIgnore`; 400 `CannotIgnoreStaff`; 409 `IgnoreLimitReached`; 404 `UserNotFound` | same |
| `DELETE api/users/{id}/ignores/{ignoredUserId}` | same | 204 (idempotent) | same |
| `POST api/private-message-log/batch` | new `A:Controllers/PrivateMessageLogController.cs` | `CreatePrivateMessageLogEntryDto[]` (≤ 200) → `{accepted, duplicates}`; dedupe on `ClientMessageId` | **plugin principal only** (API-key scheme from CP7 option 1); 401 otherwise |
| `GET api/private-message-log?participantUserId=&otherUserId=&from=&to=&pageNumber=&pageSize=` | same | `PagedResultDto<PrivateMessageLogEntryDto>` (pageSize ≤ 100, newest first) | JWT **and** `IPermissionResolutionService.CheckAsync(uid, "knk.pmlog.read")`; 403 otherwise |
| `GET/PUT api/audit-log-retention-configuration` | existing controller | adds `privateMessageRetentionDays` (≥ 1) | unchanged |

DTOs in `A:Dtos/UserIgnoreDtos.cs`, `A:Dtos/PrivateMessageLogDtos.cs`; services `IUserIgnoreService`/`UserIgnoreService`,
`IPrivateMessageLogService`/`PrivateMessageLogService`; repositories under `A:Repositories/` + `Interfaces/`; registration
in `A:DependencyInjection/ServiceCollectionExtensions.cs`. JSON names camelCase via `[JsonPropertyName]`, enums as strings
(codebase convention, `AuditAction.cs` summary). Reading PM content is additionally written to the audit log as a new
`AuditAction.PrivateMessagesViewed = 12` (actor = viewer, target = `participantUserId`) so "who read whose PMs" is itself
auditable.

### 3.3 Plugin (knk-plugin)

#### 3.3.1 Commands (top-level, `registerTabCommand`, `TabExecutor`)

v3 convention (`COMMAND_CATALOG_V3.md` §0 + KNG-9 commands): player utilities are top-level Bukkit commands in
`plugin.yml`, registered in `KnKPlugin` via `registerTabCommand`, permission checks through `KnkPermissible`
(`PlayerCommandSupport.whenAllowed`), tests with JUnit 5 + Mockito (no MockBukkit).

| Command | Aliases | Permission (in-house) | Notes |
|---|---|---|---|
| `/msg <player> <message…>` | `message`, `tell`, `whisper`, `w`, `m`, `pm` | none (as v1/v3) | console allowed |
| `/reply <message…>` | `r` | none | console allowed (replies to its last partner) |
| `/socialspy [on\|off]` | `spy` | `knk.socialspy` | no arg = toggle; reports state |
| `/ignore [player]` | — | none | no arg = list (names + dates); with arg = toggle; works for offline targets |
| `/unignore <player>` | — | none | explicit remove |

Tab completion: player names filtered by `sender.canSee(p)` (console: all); `/unignore` completes from the sender's
ignore list; `/socialspy` completes `on`/`off`.

#### 3.3.2 Target resolution (vanish-safe)

New `P:commands/support/VisiblePlayers.java`: `Player find(CommandSender viewer, String name)` =
`Bukkit.getPlayerExact(name)` then `viewer instanceof Player p && !p.canSee(target) ? null : target`. Every "not found"
path prints the same line — `No online player found named '<name>'.` — whether the name is unknown, offline or vanished
(keeps v3's single message; no v1 account-existence oracle). Reusable by teleport (`/tpa`) and currency-payments (`/pay`).

#### 3.3.3 Reply targets

`core/messaging/ReplyTargets` (knk-core, Bukkit-free): `Map<ParticipantId, Link>` where `ParticipantId` is a player UUID
or the constant `CONSOLE`, and `Link = {partner, initiatedByPartner, at}`. Rules:
- Every delivered message sets `sender → (recipient, initiatedByPartner=false)` and
  `recipient → (sender, initiatedByPartner=true)` (reciprocal, as v1/v3). Blocked messages (ignored, rate-limited) set
  nothing.
- `/r` with no link → `Nobody to reply to.`
- Partner offline → `<name> is no longer online.` — **only if** the replier could see them when the link was created by
  the partner's message; otherwise the generic not-found line.
- Partner vanished and the replier can't see them: allowed only when `initiatedByPartner` (they chose to message you);
  otherwise generic not-found. A vanished staffer is never revealed by a reply they didn't invite.
- Partner relogged: link is by UUID, so `/r` still works (improves on v1's username key).
- Console: player → console messages appear in the server console as `[<name> -> me] <msg>`; console's `/r` targets its
  last partner.
- Links are dropped for a player when **that player** quits (their own "last conversation" resets); links pointing *at*
  a quitting player are kept (so `/r` after they rejoin works). Restart clears everything (in-memory, acceptable).

#### 3.3.4 Social spy

`P:user/SpyService.java`:
- **Audience** = online players with `knk.socialspy` **and** toggle on. Resolved with `KnkPermissible.hasPermissionAsync`
  on join, on `/socialspy`, and every `private-messages.spy.refresh-seconds` (60); cached in a
  `ConcurrentHashMap.newKeySet()`, so per-message fan-out does no permission I/O. Ops always qualify (KnkPermissible op
  bypass).
- **Toggle** stored in the player's PDC (`knk:socialspy`, byte), default **on** for anyone holding the node (v1: staff always
  saw PMs).
- **Exemption** (v1's owner rule, generalised): a PM where **either** participant holds `knk.socialspy.exempt` is shown only
  to spies who themselves hold `knk.socialspy.exempt`. (v1 only checked the sender; hiding both directions is the point of
  an owner's privacy.) Exempt status is cached alongside the audience.
- **Never shown to:** the two participants; spies with the toggle off (no backlog in-game).
- **Shown with outcome tags:** blocked-by-ignore attempts as `[Spy][ignored]`, rate-limited ones are **not** echoed (spam
  would reach staff too).
- `knk.staffchat` no longer controls the spy feed. (`/staffchat` keeps its Bukkit node for now — out of scope, see §4 D8.)

#### 3.3.5 Ignore list

`P:user/IgnoreService.java` + knk-core port `ports/api/UserIgnoresApi` + knk-api-client `impl/UserIgnoresApiImpl`
(+ `dto/UserIgnoreDto`, mapper). Per online player a `Set<Integer>` of ignored user ids, loaded async on join (via the
player's cached `UserSummary.id`), updated optimistically on `/ignore` and rolled back on API failure. Checks:
- PM: recipient ignores sender and sender lacks `knk.msg.bypass.ignore` → message not delivered, sender sees the normal
  echo (silent drop, §4 D5), spies see `[Spy][ignored]`, log outcome `BlockedIgnored`.
- Public chat: in `PlayerListener.onChat`, `e.viewers().removeIf(v -> v instanceof Player p && ignoreService.ignores(p, sender))`
  (thread-safe sets; `AsyncChatEvent` runs async). Staff with `knk.msg.unignorable` cannot be ignored (API enforces, plugin
  pre-checks for the message).
- Not loaded yet (cold join) → fail open (deliver).

#### 3.3.6 Send pipeline and gates

`MessagingService.send(sender, target, text, viaReply)` on the main thread:
1. **Gate chain** (`core/messaging/PrivateMessageGate` interface, first denial wins): `FrozenGate` (frozen sender may only
   message holders of `knk.freeze`; §3.3.9), `RateLimitGate`, `IgnoreGate`. A future mute registers one more gate — no
   other change.
2. **Length**: trim, reject empty, cap at `max-length` (256).
3. **Deliver** Adventure components (§3.3.7), play sound, update `ReplyTargets`.
4. **Spy** fan-out (§3.3.4).
5. **Log** (§3.3.8) — never blocks delivery.

Rate limit (`core/messaging/RateLimiter`, sliding window per sender): at most `rate-limit.max-messages` (**5**) per
`rate-limit.window-seconds` (**5**); identical text to the same recipient within `duplicate-window-seconds` (**10**) counts as
spam. Denied → `Slow down — you can send another message in <n>s.` Bypass `knk.msg.bypass.ratelimit`; console exempt.

#### 3.3.7 Messages / UX (Adventure)

Built in a Bukkit-free `P:chat/PrivateMessageFormat.java` (same pattern as `ChatLineFormat`, unit-tested). User text is
always `Component.text(text)` — never MiniMessage/legacy-parsed — so no formatting or click injection. Names use the
player's rank colour from `TabListTeam.resolve(...)` (owner DARK_PURPLE, staff BLUE, tier/default `nameColor`).

| To | Line | Hover | Click |
|---|---|---|---|
| Sender | `[me -> Bob] hi` — brackets/`->`/message `ColorOptions.message` (GRAY, v1), `me` BLUE, name rank colour | `Click to message Bob` | `suggestCommand("/msg Bob ")` |
| Recipient | `[Alice -> me] hi` | `Click to reply to Alice` + `Sent 21:04` | `suggestCommand("/msg Alice ")` (stable even if the reply target moves) |
| Spy | `[Spy] Alice -> Bob: hi` — DARK_GRAY prefix, GRAY message; `[Spy][ignored]` variant | `Private message · 21:04` (+ `via /r`) | none (avoid accidental replies) |
| Console | plain-text serialisation of the same lines | — | — |

Sound on receive: `BLOCK_NOTE_BLOCK_PLING`, volume `sound.volume` (**1.0**, v1), pitch `sound.pitch` (1.0); `sound.enabled`.
Errors (RED): `No online player found named '<name>'.` · `You can't message yourself.` · `Nobody to reply to.` ·
`<name> is no longer online.` · `Slow down — you can send another message in <n>s.` · `You can't ignore staff.` ·
`You can only message staff while frozen.` Info (GRAY/GREEN): `Social spy enabled.` / `disabled.` ·
`You are now ignoring <name>. You won't see their messages or chat.` · `You are no longer ignoring <name>.`
Usage (YELLOW) for `/msg` also carries `Private messages may be read by moderators.` (§5 Q4).

#### 3.3.8 Logging

`P:user/PrivateMessageLogger.java`, two sinks behind one interface:
- **Local file** (Phase 1): `plugins/KnightsAndKings/logs/private-messages-YYYY-MM-DD.log`, one line
  `ISO-time | outcome | sender(uuid) -> recipient(uuid) | text`, written by a single-thread executor; files older than
  `log.local-retention-days` (**30**) deleted on enable and daily.
- **API** (Phase 3): queue → `POST api/private-message-log/batch` every `log.flush-seconds` (**5**) or 50 entries; bounded
  queue (**1000**, drop oldest with a WARN); retry with the same `ClientMessageId`s. Enabled by `log.api-enabled` (default
  false until the plugin authenticates).

Paper's own command log still records every `/msg` line in `logs/latest.log`; §5 Q3 covers whether to filter it.

#### 3.3.9 Listeners and other plugin changes

- `P:listeners/VanillaMessagingBlockListener.java` (`PlayerCommandPreprocessEvent`, `LOWEST`): `/minecraft:msg|tell|w <…>`
  rewritten to `/msg <…>`; `/teammsg`, `/tm`, `/minecraft:teammsg`, `/minecraft:tm`, `/me`, `/minecraft:me` cancelled with
  `That command is disabled.` (bypass: ops). Uses the same label normalisation as `SiegeCommandFilter.label`.
- `AdminFreezeListener.onCommand`: let `/msg`, `/r` and aliases through for a frozen player; `FrozenGate` then restricts the
  target to `knk.freeze` holders (v1 intent).
- `PlayerQuitEvent` (`MONITOR`): `ReplyTargets.forget`, `SpyService.forget`, `IgnoreService.forget`,
  `RateLimiter.forget`.
- Siege (cross-feature): once aliases exist, `SiegeConfiguration.AllowedCommands` must list them or the filter must resolve
  aliases (§4 D9).

#### 3.3.10 config.yml

```yaml
private-messages:
  max-length: 256
  sound: { enabled: true, volume: 1.0, pitch: 1.0 }
  rate-limit: { max-messages: 5, window-seconds: 5, duplicate-window-seconds: 10 }
  spy: { refresh-seconds: 60 }
  log:
    local-enabled: true
    local-retention-days: 30
    api-enabled: false
    flush-seconds: 5
  block-vanilla-commands: true
```
Parsed into a `PrivateMessagesConfig` record in `P:config/KnkConfig.java` / `ConfigLoader.java`.

### 3.4 Web app (Phase 4)

`knk-web-app:src/pages/admin/PlayerProfilePage.tsx`: new "Private messages" panel (only rendered when the API returns 200;
403 hides it) — conversation list filtered by counterpart and date, newest first, paged; each row: time, direction,
counterpart, text, outcome badge. Client `src/apiClients/privateMessageLogClient.ts`, types
`src/types/dtos/privateMessageLog.ts`. Retention field added to the existing retention configuration form. Ignore lists are
not shown in the web app (not needed for MVP).

### 3.5 Permission nodes (in-house, via `KnkPermissible`)

| Node | Grant to | Effect |
|---|---|---|
| `knk.socialspy` | staff/owner groups | receive spy feed; use `/socialspy` |
| `knk.socialspy.exempt` | owner group | your PMs hidden from non-exempt spies; you see exempt PMs |
| `knk.msg.bypass.ignore` | staff | your PMs reach players who ignore you |
| `knk.msg.unignorable` | staff | cannot be ignored |
| `knk.msg.bypass.ratelimit` | staff | no PM rate limit |
| `knk.pmlog.read` | owner (web) | read the server-side PM log |
| `knk.freeze` (existing) | — | frozen players may message you |

Sending, replying and ignoring need **no** node (a fail-closed node would lock every non-op out until the developer authors
a grant for the Default group). Declare the nodes in `plugin.yml` `permissions:` for documentation with `default: op`,
matching existing entries.

### 3.6 Anti-exploit & concurrency

- Vanish: resolution via `canSee` (§3.3.2), replies (§3.3.3), tab completion filtered; spy lines never go to non-spies.
- Injection: user text only as `Component.text`; names are Mojang-validated.
- Bypass: vanilla commands blocked/rewritten (§3.3.9); siege filter alias gap flagged (§4 D9).
- Spam: rate limit + duplicate window; blocked attempts are not echoed to spies.
- Harassment: ignore list; staff unignorable so moderation contact stays possible.
- Forged logs: the batch endpoint accepts only the authenticated plugin principal; hence Phase 3 waits for plugin auth.
- Privacy: PM content readable server-side only with `knk.pmlog.read` + JWT, each read audited; 30-day retention.
- Threading: commands on the main thread; audience/ignore sets are concurrent sets written from async futures and read from
  both the main thread and `AsyncChatEvent`; `ReplyTargets` is a `ConcurrentHashMap`; the logger never runs I/O on the main
  thread.

### 3.7 Observability

Plugin: INFO line per `/socialspy` toggle and `/ignore` change; WARN on log-queue overflow or API batch failure; FINE per
blocked message with reason. `/knk health` gains `pm-log queue: <n>` (Phase 3). API: request metrics via existing
OpenTelemetry ASP.NET instrumentation; structured log per batch (`accepted`, `duplicates`); retention run logs deleted
count like the audit cleanup.

---

## 4. Decisions taken by default (review)

- **D1 (review):** Keep the no-permission model for `/msg`, `/r`, `/ignore` (v1 and current v3).
- **D2 (review):** Aliases `message`, `tell`, `whisper`, `w`, `m`, `pm` for `/msg`; `r` for `/reply`; `spy` for `/socialspy`.
- **D3 (review):** Social-spy toggle persisted in player PDC, not the API — survives restarts with zero API work; not visible
  in the web app. Default **on** for node holders.
- **D4 (review):** Exemption hides a PM if *either* participant is exempt (v1 checked only the sender).
- **D5 (review):** Ignored senders get a silent drop (normal echo), not an "X is ignoring you" notice.
- **D6 (review):** Ignore also hides the ignored player's public chat lines.
- **D7 (review):** PMs are plain text — no `&` codes (v1 behaviour), unlike public chat.
- **D8 (review):** `/staffchat` keeps `Player.hasPermission("knk.staffchat")` (ops-only in practice). Moving it onto
  `KnkPermissible` is a one-line follow-up, flagged but not in this feature.
- **D9 (review):** Siege: this feature adds a follow-up for `claude/siege-minigame` — resolve aliases in
  `SiegeCommandFilterListener` via the Bukkit command map before calling `SiegeCommandFilter.isAllowed` — rather than editing
  the persisted `AllowedCommands` string.
- **D10 (review):** Frozen players may `/msg`/`/r` holders of `knk.freeze` only (v1 intent), not only the freezer.
- **D11 (review):** Local file log on by default with 30-day retention; server-side log behind `log.api-enabled`.
- **D12 (review):** Server-side PM log retention default 30 days, stored as a second field on
  `AuditLogRetentionConfiguration` rather than a new singleton.

---

## 5. Open questions for the developer

1. **Server-side PM persistence — build it, and when?**
   (a) Plugin-local file log only; (b) server-side log after the plugin gets real API auth (CP7 option 1);
   (c) server-side now, accepting that anyone who can reach the API can write fake entries.
   **Recommended: (b)** — ship (a) in Phase 1, keep Phase 3 blocked on the CP7 auth decision.
2. **Server-side retention for PM content.** 7 / **30** / 90 / 180 (audit default) days. **Recommended: 30.**
3. **Paper's command log contains every PM in plain text with no retention.** (a) Leave it; (b) add a Log4j filter that
   drops `issued server command: /msg|/r|…` lines; (c) set `commands.log: false` in `spigot.yml` (loses all command logs).
   **Recommended: (b)** if you pick 1(b), else (a).
4. **Tell players PMs are monitored?** (a) One line in `/msg` usage + server rules; (b) a notice on first PM each session;
   (c) nothing. **Recommended: (a).**
5. **Who gets social spy?** (a) Staff + owners via `knk.socialspy`, owners' PMs hidden from staff via
   `knk.socialspy.exempt` (v1 parity); (b) owners only; (c) staff + owners, no exemption.
   **Recommended: (a).**
6. **Ignore list storage.** (a) knk-web-api `UserIgnore` table (survives world resets, visible to other tooling);
   (b) player PDC only (no API work, ~S instead of M). **Recommended: (a).**

---

## Doc/code discrepancies found

- `docs/specs/legacy/commands-v1.md` socialSpy entry omits the `!sender.hasPermission("k&k.owner")` condition
  (`MessageCommands.java:148`): staff never saw owners' outgoing PMs.
- `docs/specs/user-features/COMMAND_CATALOG_V3.md` (2026-09-25) does not list `/msg`, `/reply`, `/staffchat`, `/freeze`,
  `/unfreeze`, `/kit`, `/user`, `/fly`, … — added by `2df0383` and KNG-9 after the scan.
- `knk-plugin` `plugin.yml:396-400` / `StaffChatCommand` Javadoc: "holders of knk.staffchat" — only ops, since in-house
  grants never reach Bukkit's `hasPermission`.
- `MessagingService` Javadoc (`:20-21`) says the reply map is updated one-directionally on reply; the code is reciprocal.
- knk-plugin and knk-web-api `CLAUDE.md` say the plugin authenticates with a JWT bearer token; the plugin ships
  `auth.type: none` and the API has no plugin auth (confirmed by CP7 status).
- knk-web-api `CLAUDE.md` test path `tests/knkwebapi_v2.Tests/…` — the folder is `Tests/` (case-sensitive on Linux).
