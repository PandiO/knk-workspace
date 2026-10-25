# Plugin permission checks and command visibility

**Status:** Implemented, live-tested by the developer and merged 2026-10-18: knk-plugin `main` `3ca5b3f`, knk-web-api `master` `ac3c869`. Linear [KNG-107](https://linear.app/kngpandi/issue/KNG-107)
**Last updated:** 2026-10-25 (§ 3: other plugins' nodes are Bukkit-only; `always-show` example)
**Related:** [`offline-security-cache.md`](offline-security-cache.md) (answers when the API can't be asked); [`api-connectivity.md`](api-connectivity.md) (no API call while DOWN); [`specs/user-features/DESIGN.md`](../specs/user-features/DESIGN.md) §2.2 (the resolution rules); KNG-24 (Bukkit-or-in-house checks), KNG-30 (completion sweep)

## 1. Problem

The plugin asked knk-web-api about every node separately (`GET /api/Users/{id}/permissions/check?node=`,
cached 30 s per node). Once `/knk help` and tab completion started listing only what the player can use, one
listing needed every node at once: in the live test (2026-10-18) a join sent 116 checks and the first `/knk help`
244, each 700-800 ms under that load, so help took about 10 s.

## 2. One permission set per player

`PermissionsDataAccess` (knk-core) answers checks from the player's **effective set**
(`GET /api/Users/{id}/permissions/effective`): every node declared for the player, its value and source holder.

- **One request per player per TTL** (`cache.entities.permissions.ttl-seconds`, 30). Checks arriving together on a
  cold cache share one load. `PlayerListener` loads the set during login (async pre-login, waits at most 2 s), so
  the join and the first command or listing need no request.
- **Resolved locally** by `EffectivePermissionResolver` with the API's rules: holders in chain order (the user's
  own grants, then the groups in precedence order); the first holder with any match decides; within a holder the
  most specific match wins (exact node, else the longest wildcard prefix) and a deny beats a grant of the same
  specificity; `knk.gate.*` also matches `knk.gate`; `*` matches everything; case-sensitive; no match = undeclared
  (no). Keep it in step with `PermissionResolutionService.CheckAsync` in knk-web-api.
- **Chain order:** since knk-web-api `ac3c869` each effective entry carries `sourceRank` (0 = the user, then the
  groups in precedence order), and every node resolves locally. Without it (an older API) a node is still exact
  whenever the order can't matter: the user's own grants come first, a single matching holder decides, and
  holders that agree decide. Only a node two groups disagree about is asked with a single-node check.
- **After the TTL:** cache-only checks (help, tab completion, the `/` list, broadcast audiences) answer from the
  last set while it reloads in the background, so listings never wait. While the API is DOWN only for
  `effective-set-stale-seconds` (90) more, then the [offline store](offline-security-cache.md) answers. Running
  a command waits for a current set (`whenAllowed`, `warm`), so a revoked node isn't used from an old set.
- **Changes:** a group, rank or node change made with `/knk user` drops and reloads the target's set, then
  re-sends their `/` list. A change made in the web app applies within the TTL (`/knk cache refresh` at once).
- **Offline store:** each node answered from a newly loaded set is recorded once per load; answers from an
  expired set are not. A set load that finds no user is passed on as an erasure (KNG-58).
- **Quit:** the player's set is dropped (`PlayerQuitEvent`, MONITOR).
- **Switch:** `cache.entities.permissions.resolve-from-effective-set: false` goes back to one request per node.

`CommandPermissions.warmForListing` (help, `/knk`) runs at once when the player's set is loaded and refreshes it
in the background; `warm` (executors that decide what to allow, e.g. `/knk user`) waits for current answers.

## 3. Command visibility

- **`/knk help`** lists the `/knk` subcommands the sender can use and the plugin's other commands they may use
  (plugin.yml text, filtered by node), 8 lines a page with a clickable footer (`/knk help <page>`).
  `/knk help <command>` describes one; a command the sender isn't offered reads as unknown.
- **Tab completion** offers only usable subcommands, actions, flags and player names (cached checks; a "no" is
  asked in the background). Gate commands offer open/close/toggle only for the gates the sender controls.
- **Nodeless `/knk` subcommands** (`user`, `currency`, `lootbox`, `discovery`, `road`, `location`) are listed only
  to holders of one of their action nodes and answer "no permission" instead of the usage to anyone else.
- **Standalone commands** every form of which needs a node (`CommandNodes`: `/tp`, `/fly`, `/heal`, `/pay`, ...)
  answer "no permission" instead of the usage and are left out of the `/` list for players holding none.
- **The `/` list** (`GatedCommandVisibilityListener`) also leaves out every `plugin:command` label and other
  plugins' commands the player can't run, or that declare no permission and have no permission test of their
  own (`OtherPluginCommandVisibility`; Bukkit checks only, ops see everything). Config `command-visibility.*`:
  `hide-namespaced`, `hide-other-plugins-without-permission`, `always-show`.
- **Other plugins' own permission checks** ask Bukkit, never KnK's model: a node granted to a group in the web
  app or with `/knk user … perm grant` doesn't reach them. Grant such nodes to every player in Bukkit's
  `permissions.yml`, and list the command in `always-show` when it declares no permission. Example: spark, with
  `spark.ping` in `permissions.yml` and `always-show: [spark]`
  ([production installation § 9.2](../guides/production-installation.md#92-dependencies)).
- **Usage lines** name only the action typed (`/knk currency lock`, `/knk user <p> gems`) or the held ones.

Hiding is cosmetic: every command still checks its own nodes when run.

## 4. Tests

- knk-core: `EffectivePermissionResolverTest` (the API's rules, ranked and unranked), `PermissionsDataAccessEffectiveSetTest`
  (one request for many nodes, shared cold loads, preload, stale answers, API DOWN, unknown user, unranked conflicts, invalidation).
- knk-paper: `CommandPermissionsTest` (`warmForListing`), `CommandRegistryPermissionsTest` (help listing and paging),
  `GatedCommandVisibilityListenerTest`, `OtherPluginCommandVisibilityTest`, `CompletionPermissionsTest`, per-command tests.
- knk-web-api: `PermissionResolutionServiceTests.GetEffectiveAsync_SourceRank_*`.
