# New-session prompts: closed-alpha follow-ups (API packages, KNG-123 outage slice, KNG-103)

**Date:** 2026-10-11
**Status:** Ready to copy into fresh sessions (one session per prompt; they don't share files)
**Context:** [alpha go-live](../../guides/alpha-go-live.md), [NAS runbook](../../guides/closed-alpha-deployment-runbook.md),
[tracker](../../ACTIVE_SESSIONS.md)

The three can run in parallel: they touch different repos or different files. Watch for these overlaps:
- **Plugin branches in flight:** `claude/blissful-fermat-b7ihrz` (KNG-114 world loader, KNG-113 gates) and
  `claude/ui-ux-assessment-discussion-66vc2l` (KNG-128/129 onboarding) touch `KnKPlugin`, `PlayerListener` and the
  gate classes.
- **Prompt 1 is time-sensitive:** it should land before Codex rebuilds the alpha API (runbook Phase 3b).

---

## Prompt 1: knk-web-api vulnerable packages

```text
Fix the vulnerable NuGet packages in knk-web-api before the closed alpha's API image is rebuilt.

Read first: knk-workspace AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md, docs/ACTIVE_SESSIONS.md (claim
your files there), knk-web-api CLAUDE.md. Refresh all repos; work on a new branch from knk-web-api master.

Background: the NAS build of knk-web-api (docs/reports/2026-10-11-closed-alpha-infrastructure-progress.md §5)
reported two advisories:
- AutoMapper 12.0.1 (high, GHSA-rvv3-g6hj-g44x). knkwebapi_v2.csproj also has
  AutoMapper.Extensions.Microsoft.DependencyInjection 12.0.1, and the test project references both.
- OpenTelemetry.Instrumentation.AspNetCore 1.7.0 (moderate, GHSA-vh2m-22xx-q94f). The other OpenTelemetry packages
  are also 1.7.0.

Steps:
1. Run `dotnet list package --vulnerable --include-transitive` for both projects and record the output. Look for
   other findings as well.
2. Research each advisory: what is affected, which version first fixes it, and whether our usage is exposed.
   AutoMapper is used widely (about 32 profiles under Mapping/, many IMapper calls). Its newer major versions changed
   the license (a commercial license key from v15) and the DI registration: from v13 the
   Extensions.Microsoft.DependencyInjection package is merged into the main package. STOP AND ASK the developer before
   adopting a version that needs a license key. Present the options:
   a. a patched version without a license, if one exists;
   b. a licensed version;
   c. replacing AutoMapper (too large for now; estimate the effort only);
   d. accepting the risk for the alpha, with the reason and a mitigation.
   Wait for the developer's choice.
3. OpenTelemetry: upgrade all OpenTelemetry.* packages together to a patched version that supports net8.0. The
   alpha runs with Telemetry:Enabled=false, but the package is still loaded.
4. Build, then run the tests: `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`. Compare the failures
   with master: master has 4 known failures, so report any change. Watch for AutoMapper behaviour changes, such as
   AssertConfigurationIsValid, null-collection mapping and projection.
5. Re-run the vulnerable-package listing: it should be clean, or contain only the accepted items.
6. Commit, push and open a PR. In the PR body, list each package and version change, each advisory's status and the
   test results. Update the tracker. Add a line to the knk-workspace closed-alpha handoff so Codex builds Phase 3b
   from the merged commit.
```

---

## Prompt 2: knk-plugin, outage part of KNG-123

```text
Implement the closed-alpha outage part of KNG-123 in knk-plugin. The server must not freeze, and the ignore
filter must keep working, while knk-web-api is unreachable. The alpha runs on a NAS where the API restarts on every
deploy.

Read first: knk-workspace AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md, docs/ACTIVE_SESSIONS.md (claim
your files there), knk-plugin CLAUDE.md, Linear KNG-123, docs/architecture/offline-security-cache.md and
docs/reports/2026-10-06-offline-critical-data-inventory.md. Refresh all repos; work on a new branch from knk-plugin
main.

Scope (only these; the rest of KNG-123 stays open):
1. Main-thread waits on the API.
   - KNG-123 says the respawn blocks on a town lookup. Check this first: since KNG-52 rounds 3-4,
     GameSettingsManager.loadTowns runs async and PlayerListener.onPlayerRespawn reads pre-resolved data. If that is
     confirmed, record it on the issue and don't change it.
   - Then audit every `.join()` / `.get()` reachable on the main thread from an event handler or command. Starting
     points: EnchantmentInteractListener (lines ~75-112), EnchantmentEnchantTableListener:41,
     GatedCommandVisibilityListener:104, plus a grep over knk-paper/src/main. For each one, determine whether it can
     reach the network: some repositories may be local or cache-only.
   - Fix the ones that can block on the API: read from a cache or snapshot, or go async with a main-thread hop.
     Keep the behaviour otherwise identical.
   - Note: PlayerListener.onValidateLogin joins on purpose; it runs on AsyncPlayerPreLoginEvent, which is off the
     main thread.
2. Ignore lists fail open (paper/user/IgnoreService): during an outage the harassment filter is off.
   - Persist each player's last loaded list on disk and use it when the API fails.
   - Follow the KNG-58 store rules: fallback only, bounded age, deleted on erasure, listed in the privacy inventory.
     Reuse the OfflineSecurityStore mechanism (knk-core offline/), not a new cache.
   - Add the file to docs/reports/2026-10-06-offline-critical-data-inventory.md or the privacy inventory it points to.

Not in scope: gates snapshot (wait for KNG-113 to merge), siege config, hub/Game Settings scope, combat safezones,
and the generic stale-on-error layer.

Conflicts: two plugin branches in flight touch the same files.
- claude/blissful-fermat-b7ihrz (KNG-114/113): KnKPlugin, PlayerListener, gates.
- claude/ui-ux-assessment-discussion-66vc2l (KNG-128/129): KnKPlugin, PlayerListener, UserAccountListener,
  discovery/.
Keep your edits to those files minimal.

Tests: unit tests for every change. Never build a Location around an inline mock(World.class) (see knk-plugin
CLAUDE.md). Run `./gradlew build -x deployToDevServer`, which must have 0 failures, and report the counts per module.

Done:
- pushed branch and PR;
- the KNG-123 comment says which items are fixed and which remain;
- tracker row updated;
- a short in-game test list for the developer: stop the API while players are online, then die, use enchantments,
  run commands, and check that /ignore still filters.
```

---

## Prompt 3: KNG-103, re-running a domain's region step leaves the old region behind

```text
Fix Linear KNG-103: re-running the "Region and Location" step of an existing domain must replace its region. The
new region takes the final name (domain_<id>) and the old WorldGuard region is removed or redefined in place, in
WorldGuard and the database together.

Read first: knk-workspace AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md, docs/ACTIVE_SESSIONS.md (claim
your files there), the CLAUDE.md of knk-plugin and knk-web-api, Linear KNG-103 (full repro: District 17, world task
227, "target region name already exists: domain_17"), and docs/architecture/managed-worldguard-regions.md. Refresh
all repos; work on new branches from knk-plugin main and knk-web-api master.

Where to look:
- knk-plugin paper/tasks/WgRegionIdTaskHandler: the rename/finalize after the task.
- knk-plugin paper/http/RegionHttpServer /Regions/rename: the API calls this with X-API-Key.
- knk-web-api IDomainRegionNameFinalizer and the workflow step completion.
- KNG-111 (merged) made region lookups world-qualified: a Domain has WorldName. Keep renames in the domain's world.

Design questions to settle in code and document in the PR:
- Which side decides "replace": API, or the plugin when the target name exists and belongs to the same domain?
- Order: rename, delete, then DB update. What happens on partial failure? Never leave the DB pointing at a region
  that doesn't exist.
- Flags, priority and parent of the managed region must survive. The managed-regions reconciler
  (knk-core regions/managed/) may already re-apply them.
- Don't delete a region that belongs to another domain or isn't KnK-managed.

Also in scope: a way to clean up the leftover tempregion_worldtask_* regions. A "/knk regions repair" extension or
a one-off report is fine; describe the choice.

Tests: unit tests on both sides (plugin: the replace/rename decision with mocked WorldGuard; API: the finalizer).
Run `./gradlew build -x deployToDevServer` and
`dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` (master has 4 known failures; report any change).

Done:
- pushed branches and PRs;
- a KNG-103 comment with the cause and the fix;
- tracker row updated;
- an in-game test list for the developer: create a district, re-run its region step, check /rg list and the domain's
  WgRegionId, re-run it again, check there are no orphans.

Avoid the gate classes (KNG-113 branch) and keep KnKPlugin edits minimal (two other branches touch it).
```
