Read docs/ai-agents/handoffs/ROAD_NAVIGATION_CHAIN.md first and follow it; it overrides anything below.

Implement road navigation **Phase 2e — api-client (`A/`: ports `C/ports/api/RoadNetworkQueryApi` /
`RoadNetworkCommandApi`, DTO records `A/dto/Road*Dto.java`, mappers `A/mapper/RoadMapper.java`, impls
`A/impl/RoadNetworkQueryApiImpl.java` / `RoadNetworkCommandApiImpl.java`, `BaseApiImpl.getConditional` (R17), wiring in
`A/client/KnkApiClient`)** from docs/specs/navigation/IMPLEMENTATION_PLAN.md, end to end (code, tests, commits, push to
`claude/road-navigation`, plan status block, progress report, handoff), as **link 6** of the chain. Charter §5 allows a
split at a commit boundary if it turns out too big; if you split, mark the status "partial" naming exactly which
classes/tests exist and hand the rest to link 7 as `…-phase-2e-2.md`.

State you start from:
- **Phase 1 is done** (link 1): knk-web-api `claude/road-navigation` `77e0a29` (cut from `master` `ccc8c02`). Its
  "Phase 1 status → What later phases must wire → Phase 2e (Java DTOs)" is your contract: mirror `W/Dtos/RoadDtos.cs`
  one to one, names are the `[JsonPropertyName]`s (camelCase); enums are strings by name; `flags` is a string array
  (`Oneway`, `NoGps`, `Closed`); `geometry` is `int[][]`; `stats` (profile, survey) is an opaque JSON object (Jackson
  `JsonNode`/`Map`, send `null` to keep it on a profile PUT); `PUT …/graph` returns `RoadTileUpsertResultDto`,
  `PUT api/road-edges/{id}` returns `RoadEdgeUpdateResultDto`, `POST api/road-nodes/anchor` takes `RoadNodeAnchorDto`,
  `POST api/road-seeds` takes `RoadSeedCreateDto`; errors are `{ "error": "ValidationFailed" | "NotFound" |
  "Conflict", "message" }`; R17: `ETag` is the quoted version (`"3"`), send it back verbatim in `If-None-Match`, weak
  tags (`W/"3"`) are accepted; surveys need `X-Acting-User-Id`. The route table is plan §1.5 (D3). Clone knk-web-api
  read-only for the exact DTO shapes (link 5 cloned it to `/home/user/pandio/knk-web-api` on branch
  `claude/road-navigation`; that path may not exist in your container — `GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1
  --branch claude/road-navigation https://github.com/PandiO/knk-web-api /home/user/pandio/knk-web-api` works
  anonymously).
- **Phases 2a-2d are done** (links 2-5): knk-plugin `claude/road-navigation` **`a82db3c`** (trunk `main` still
  `eb1d68c`, nothing to merge), knk-core **1364 tests green** (baseline before 2d: 1280) via the plan §0.4 scratch
  build (**not Gradle**, see risks). What 2e maps to/from, all in knk-core:
  - 2c (`C/roads/build/`): `TileBuildResult(builderVersion, cellCount, levelCount, nodes, edges, warnings)` with
    `Node(key, existingId, x, y, z, kind)` and `Edge(existingId, fromKey, toKey, geometry List<int[]>, length, avgWidth,
    profileId, gateDoorIds, domainIds, regionIds)` → `RoadTileGraphUpsertDto` (`warnings = warningTexts()`, `kind =
    kind.apiName()`); `ProfileSet.Profile(id, name, enabled, widthMin, widthMax, scopeTownIds, materials)` with
    `ProposedProfile.Material(material, RoadMaterialRole.fromApiName(role), ambiguous, centreShare, edgeShare,
    samples)` ← `RoadProfileDto`; `NodeMatcher.PreviousGraph(nodes: PreviousNode(id, x, y, z,
    RoadNodeKind.fromApiName(kind), locked), edges: PreviousEdge(id, fromNodeId, toNodeId, geometry))` and
    `SkeletonGraph.Anchor(id, x, y, z)` ← a tile graph download (see the plan's "Phase 2c status → What later phases
    must wire → 2e").
  - 2d (`C/domain/roads/`, `C/roads/route/`): `RoadEdge(id, fromNodeId, toNodeId, geometry List<int[]>, length,
    avgWidth, OptionalInt profileId, OptionalInt streetId, costMultiplier, Set<RoadEdgeFlag> flags, gateDoorIds,
    domainIds, regionIds, RoadEdgeSource source, boolean stale)` ← `RoadEdgeDto` (`flags` via
    `RoadEdgeFlag.fromApiName`, `source` via `RoadEdgeSource.fromApiName`, `stale = "Stale".equals(status)`);
    `RoadNode(id, x, y, z, RoadNodeKind.fromApiName(kind), name, componentId)` ← `RoadNodeDto`;
    `RoadNetworkSnapshot.Profile(id, name, RoadClass.fromApiName(roadClass), costMultiplier)` and
    `RoadNetworkSnapshot.Street(id, name)` ← the meta's `profiles[]` / `streets[]` (see the plan's "Phase 2d status →
    What later phases must wire → 2e"). `RoadClass`, `RoadEdgeFlag`, `RoadEdgeSource`, `RoadNodeKind`,
    `RoadMaterialRole` all have `apiName()`/`fromApiName()`.
  - 2b: `ProfileLearner` produces the profile the plugin `PUT`s (D5) — its `StatsJson` v1 layout is fixed by the
    plugin (plan "Phase 2b status"); the DTO carries `stats` opaquely.
- **knk-web-app:** untouched; not needed.
- **Workspace `main`** carries the progress report `docs/reports/2026-09-27-road-navigation-chain.md` (append your
  Phase 2e section, refresh the summary table — 2e row is "in progress (link 6)") and the tracker row in
  `docs/ACTIVE_SESSIONS.md` (already names Phase 2e in progress with the file list; update as you go).
- **Baselines to record:** knk-core 1364 at `a82db3c`; knk-api-client test count **not yet measured** by any link
  (29 test files under `knk-api-client/src/test/java/net/knightsandkings/knk/api/`) — measure it with the scratch
  build before changing anything; `./gradlew :knk-api-client:test` will fail on `paper-api` resolution via knk-core —
  record that too.

What earlier phases say Phase 2e must wire (plan "2e API client"):
- Ports in `C/ports/api/` (Bukkit-free, `CompletableFuture` like the existing ports there): `RoadNetworkQueryApi`
  (`tiles(world)`, `tileGraph(world, x, z, etag)` → `Conditional<RoadTileGraph>` {notModified, body, etag},
  `meta(world)`, `profiles()`, `seeds(world)` — D12 `seed-locations` box query), `RoadNetworkCommandApi`
  (`upsertTileGraph`, `markDirty`, `saveProfile`, `createSurvey(…, actingUserId)`, seed/node/edge review calls).
  Decide (plan §0.2) whether the port types are the knk-core records above or thin knk-core DTO records — the
  existing ports use knk-core domain records (`C/domain/…`), so prefer mapping in `A/mapper/RoadMapper` and keeping
  the ports on knk-core types; number the decision.
- Impls extend `BaseApiImpl` (`CompletableFuture.supplyAsync(..., executor)` like `A/impl/DiscoveriesApiImpl`),
  constructed in `A/client/KnkApiClient` (constructor ~L136-188, field + getter like `discoveriesApi` L113/L167/L281).
- R17: add `ConditionalResponse getConditional(String url, String etag)` to `BaseApiImpl` returning `{notModified,
  body, etag}` — 304 is **not** an error there (today `execute` throws `ApiException` on every non-2xx incl. 304);
  don't change the behaviour of the existing `get`/`postJson`/`putJson`/`delete`.
- Tests: mapper round-trips (DTO ↔ knk-core records, both directions where both exist); conditional GET 200/304.
  `mockwebserver` is **not** a dependency of knk-api-client (only `okhttp 4.12.0`, `jackson-databind 2.17.2`,
  `jackson-datatype-jsr310 2.17.2`, junit) — use an OkHttp `Interceptor` that answers canned responses (plan 2e:
  "otherwise a stubbed interceptor"); don't add a dependency without noting it as a decision.

Phase-specific reading: plan §0 (esp. 0.2, 0.4), §1 (D3 routes, D5 profile PUT, D11 `regionIds`, D12 seeds), §2 R17,
"Phase 1 status" (whole block — the contract, the route table, decisions 1, 11, 12), "Phase 2c status → What later
phases must wire → 2e", "Phase 2d status → What later phases must wire → 2e", "2e API client". knk-plugin: `A/impl/
BaseApiImpl.java`, `A/impl/DiscoveriesApiImpl.java` + its port `C/ports/api/DiscoveriesApi.java`, `A/dto/` naming and
`@JsonProperty` conventions, `A/mapper/` style, `A/client/KnkApiClient.java`, one existing impl test under
`knk-api-client/src/test/…/impl/` for the test style. knk-web-api (read-only): `Dtos/RoadDtos.cs`, `Controllers/Road*.cs`
for the exact routes and status codes.

Open flags that affect this phase: none. Decisions to take alone (plan §0.2): port type choice (above), the
`Conditional<T>` record's shape and package, how `stats` is carried (`JsonNode` vs `Map<String, Object>`), whether the
tile graph port returns one record per tile or the raw DTO. Take the reversible default and number it in your status
block.

Known risks:
- **Network (same as links 1-5):** `repo.papermc.io` and `maven.enginehub.org` return HTTP 000/403 — re-check per
  charter §1.5; if still blocked, use the scratch build (recipe in the plan's "Phase 2a status" block; the 2c/2d status
  blocks add what the `Vector` stub must cover and `testRuntimeOnly("org.junit.platform:junit-platform-launcher")` for
  Gradle 8.10). For knk-api-client add a second source set / project in the scratch build with knk-core's main sources
  on its classpath plus `okhttp 4.12.0` and `jackson 2.17.2` (+ jsr310), all on Maven Central (note knk-core itself
  pins jackson 2.15.2 — the real build resolves to 2.17.2 through the api-client; do the same). Put
  `org.gradle.workers.max=2`, `systemProp.org.gradle.internal.repository.max.tentatives=12`,
  `systemProp.org.gradle.internal.repository.initial.backoff=2000` in `~/.gradle/gradle.properties` before the first
  run, then `--offline`. Say "not compiled with Gradle" in your status.
- **Toolchain:** Java 21 present, Gradle wrapper 8.10.2 downloads fine. The knk-plugin clone may be shallow (`--depth 1`
  of `main`): `git fetch --depth 60 origin claude/road-navigation:refs/remotes/origin/claude/road-navigation` then
  `git checkout -b claude/road-navigation origin/claude/road-navigation`.
- **Repo layout:** the knk-plugin clone lands at `/home/user/knk-plugin` (not `Repository/knk-plugin`); the workspace
  clone may be in detached HEAD — `git branch -f main HEAD && git checkout main`, then `git pull origin main` before
  editing docs (other sessions push to `main`).
- **Scope:** `C/ports/api/RoadNetwork*Api.java`, `A/dto/Road*`, `A/mapper/RoadMapper`, `A/impl/RoadNetwork*ApiImpl`,
  `A/impl/BaseApiImpl` (additive only), `A/client/KnkApiClient` (additive) and tests — no paper code, no cache
  (Phase 3's `RoadNetworkCache`), no changes to `C/roads/**`, `C/navigation/**`, `C/domain/roads/**` beyond what a
  mapper genuinely needs (if a record lacks a field the API sends, add it with a decision note rather than a second
  record).
- **Size:** "S" — many small records. Commit and push after each logical part (ports; DTOs + mapper + tests;
  `getConditional` + test; impls + wiring).

Next after you: **Phase 3** (knk-plugin paper: config R16, wiring, extractions R8-R11/R25, snapshot grid, build job +
queue, survey session, dirty tracker, `/knk road`, overlay) — it cannot be compiled in the cloud (knk-paper needs
paper-api); the charter says implement by careful reading and mark "not compiled". Write
`docs/ai-agents/handoffs/<date>-road-navigation-phase-3.md` and start it per charter §6 (or `…-phase-2e-2.md` if you
split 2e).
