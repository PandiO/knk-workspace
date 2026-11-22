# Landmarks as a Domain subtype chain — progress report

**Status:** Running (2026-11-22: L1 in `next`, L2 in review) · **Last updated:** 2026-11-22 (L2 block)

**Issue:** [PandiO/knk-workspace#976](https://github.com/PandiO/knk-workspace/issues/976), links
[#983](https://github.com/PandiO/knk-workspace/issues/983) (L1), [#984](https://github.com/PandiO/knk-workspace/issues/984) (L2),
[#985](https://github.com/PandiO/knk-workspace/issues/985) (L3), [#986](https://github.com/PandiO/knk-workspace/issues/986) (L4).
**Charter:** [handoffs/LANDMARK_DOMAIN_CHAIN.md](../ai-agents/handoffs/LANDMARK_DOMAIN_CHAIN.md).
**Coordinator:** session_01R1w2UtYX9XFbTVUFy6zJUb (cloud), started 2026-11-22 on the developer's go ("Start it now",
design session of 2026-11-22).

## 1. Waiting for the developer

1. **L1 #983 in `next` (tier:3), for your test before the promotion of `next`:** smoke guide
   `docs/guides/landmark-domain-smoke-test.md` § 1 in full (14 steps; the automated ones are tagged). Deploy first:
   back up the dev DB, apply migration `LandmarkAsDomain` (it deletes every landmark row; recreate your test
   landmarks), import the `Landmark` form seed v2 and `Landmark.display` and make both the default (form 51 and its
   Region id projection are superseded). Don't put `next` on a server players use before L3 (#985) is in it too
   (until then the plugin treats a landmark's own region as a domain region for effect damage).
2. **L2 #984 in `next` (tier:2):** smoke guide § 2 (8 steps, 6 automated, 2 partly); deploy: apply migration
   `AddLandmarkDiscoveryRule` (data only, a disabled `Landmark` discovery rule).
3. **Agent decisions to review:** L1 block § 4.1 item 5 (11 decisions), L2 block § 4.2 item 5 (7 decisions), each with
   alternatives, and § 3 below.
4. **Off-road smoke § 6 and § 7 (landmarks, #698):** the off-road coordinator asked you on #698 whether they close as
   superseded by this chain; this chain's guide § 3 covers landmark navigation on the new model (L3).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 API model, migration, area kinds and parent (tier:3) | #983 | Merged into `next` 2026-11-22 18:37 UTC (knk-web-api `8cc4511b`, knk-workspace `724ebc10`) | `claude/landmark-domain`: knk-web-api `00ee3115` (after merging `next` `c647daf7`); `claude/landmark-domain-l1`: knk-workspace `ba0596e0` (coordinator, 2026-11-22: the heads in block 4.1 item 2 predate that merge) | [knk-web-api#82](https://github.com/PandiO/knk-web-api/pull/82), [knk-workspace#994](https://github.com/PandiO/knk-workspace/pull/994) | green on `00ee3115` (build-and-test, mysql-tests, fresh-database); knk-workspace no checks; Codex at its usage limit (skipped) | create_session session_01R1w2Uv1A4MYoi62zFJTnwz, started 2026-11-22 16:32 UTC |
| L2 API lists, discovery, warps and realtime (tier:2) | #984 | Merged into `next` 2026-11-22 19:45 UTC (knk-web-api `55d187d8`, knk-workspace `035f641f`) | `claude/landmark-domain-integration`: knk-web-api `2525be13`; `claude/landmark-domain-l2`: knk-workspace `fc64d3f2` | [knk-web-api#84](https://github.com/PandiO/knk-web-api/pull/84), [knk-workspace#1002](https://github.com/PandiO/knk-workspace/pull/1002) | green on `2525be13` (build-and-test, mysql-tests, fresh-database; push and PR runs); knk-workspace no checks; Codex at its usage limit (skipped) | create_session session_01R1w2Ux3HrcYVs53AugdtZW, started 2026-11-22 18:39 UTC |
| L3 Plugin (tier:2) | #985 | Running (rerun started 2026-11-22 19:51 UTC; first run blocked at setup, block 4.3) | `claude/landmark-domain`: knk-plugin (none yet); `claude/landmark-domain-l3`: knk-workspace (none yet) | none | none | create_session session_01R1w2UtBFy9s4dBXQoeBMQF (19:46 UTC, environment "Default": blocked, `repo.papermc.io` refused); rerun create_session session_01R1w2UuLNw6Cr3qwUKQNvao in environment "Default Correct" (19:51 UTC, decision 14) |
| L4 Web app (tier:2) | #986 | Done, in review (2026-11-22) | `claude/landmark-domain`: knk-web-app `4bc6b88`; `claude/landmark-domain-l4`: knk-workspace `73e785d4` | PandiO/knk-web-app#78, PandiO/knk-workspace#1004 | knk-web-app `4bc6b88`: build-and-test, e2e green; knk-workspace no checks; Codex at its usage limit | create_session session_01R1w2UtGykzTGpUL4Ksj6S6, started 2026-11-22 19:46 UTC |
| L1b #952 region re-run left on a temp name (charter § 3 item 8, fix link) | #952 | Queued: starts once L4's knk-web-api seed branch `claude/landmark-domain-l4-seed` is merged (one knk-web-api link at a time) | `claude/landmark-domain-952`: knk-web-api; `claude/landmark-domain-l1b`: knk-workspace | none | none | (not started; `create_session`) |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model, because `.github/workflows/ci.yml` is on `main` of knk-web-api and
   knk-web-app (checked 2026-11-22 after a fresh fetch). Links branch from `next`, their PRs target `next`, and the
   coordinator merges them into `next` once the checks of skill § 6 hold. Bases at the first run: knk-web-api `next`
   `4d9bea33` (CI green: Build and test, Migrations), knk-web-app `next` `ac28717e`, knk-plugin `next` `167bb56c`,
   knk-workspace `next` `0f7c3639`. Alternatives: none (the old rules apply only without CI on both default branches).
2. **Route and model.** Chosen: `create_session` for every link (skill § 4.1.1), with the coordinator's own model passed
   explicitly and no effort level (the developer asked for none), because each link changes one component repo plus
   knk-workspace, so it attaches a single repository (skill § 4.1.4.2). On a refused `add_repo` or a failed dry run the
   link is rerun as a subagent of the coordinator with the same prompt (variant B). Alternatives: (a) subagents from the
   start, which keeps the coordinator's context busy for the length of a tier:3 link and is meant for links with two or
   more component repos; (b) a smaller model for the tier:2 links, rejected for consistency across the chain.
3. **knk-workspace branch per link.** Chosen: the docs of each link (changelog entry, smoke-guide section, spec status)
   go on `claude/landmark-domain-l<n>` in knk-workspace, from `next`, with its own PR into `next`. The charter names the
   component-repo branches only, and one shared knk-workspace branch would have L3 and L4 pushing to the same branch
   while they run together. Alternatives: (a) `claude/landmark-domain` for every link in knk-workspace, rejected
   (concurrent pushes from L3 and L4, and a reused branch after L1's merge); (b) docs inside the component-repo PR,
   rejected (the smoke guide and changelog live in knk-workspace).
4. **#981 (CrownLand loop in `GetParentDomainDecisions`).** Chosen: L1 takes #981 over, as the charter allows (§ 3.1
   note 1): #981 is open, has no branch, PR, board row or comment (checked 2026-11-22), and LD23's parent walk replaces
   the code it fixes. L1 covers #981's tests (a `CrownLand` and a bare `Domain` mapped to `DomainRegionDecisionDto` and
   through `search-region-decisions` return without parents) and comments on #981 with its PR; #981 stays open until the
   developer promotes `next`, like the chain's issues. Alternatives: (a) a separate tier:1 fix first, rejected (it edits
   the same lines L1 replaces, so a conflict and the work twice); (b) leave #981 to the manager, rejected (two sessions
   on `DomainMappingProfile` at once).
5. **Overlaps at the start** (board fetched 2026-11-22, `origin/main` `60c127c0`).
    1. Off-road navigation chain #698: owns the landmark code of #708/#709, no link running, no API link queued. It does
       not block L1 or L2 (knk-web-api). For L3 (knk-plugin `core/navigation/` landmark classes) the coordinator checks
       its row and the navigation destination engine chain's row (#25, its L5 #747 is a knk-plugin navigation link
       waiting on a live test) before starting, and keeps one knk-plugin navigation link at a time across the three
       chains. Alternatives: (a) treat the #698 claim as a blocker for the whole chain, rejected (no running link, the
       code is merged into `next`); (b) ask the off-road coordinator to hand over the landmark files, not needed while
       it has no link.
    2. #945 landmark region path (`landmark_<id>`, merged into `next` via knk-web-api#77, board row archived
       2026-11-22): L1 removes it per LD14; #946 (production areas) keeps the generic owner lookup. No active claim.
    3. No other "In progress" row claims knk-web-api domain, landmark or region files; no knk-web-api PR is open.
6. **Order.** Chosen: L1 now; L2 once L1 is merged into `next` (same repo, one link per component repo); L3 and L4
   together once L2 is merged (they share no component repo; their knk-workspace branches differ, decision 3).
   Alternatives: (a) L4 in parallel with L2, rejected (the charter gates L4 on L2 for the list type and filter).
7. **Migration and flag exceptions for L1.** The knk-link skill allows only additive migrations and puts tier:3 work
   behind a flag; the charter overrides both for L1: its one migration is not additive (drops the landmark rows,
   LD10, dev DB only; charter § 3.3) and needs a working Down, and there is no flag (LD24, every landmark behaviour is
   off or neutral by default). The L1 prompt says so. Alternatives: none (charter and approved design).
8. **L1 checked and merged into `next`** (2026-11-22 18:37 UTC). Chosen: merge, because every check of skill § 6
   held: block and summary row in place; heads matched `git ls-remote` after L1 merged `next` (#988, #991) into its
   branch; both PRs clean against `next`; CI green on knk-web-api `00ee3115` (build-and-test, mysql-tests,
   fresh-database); tests 5223 → 5258 passed (129 MySQL skipped; 5441 passed with MySQL locally); scope only
   knk-web-api and three knk-workspace docs; 12 agent decisions logged; no flag per the charter (LD24); #983
   `status:in-review`; every smoke step of § 1 kept in full and tagged. Codex reached its usage limit on every attempt,
   so the PRs were merged without its review (developer decision 2026-11-14); in its place the coordinator read the
   migration (Up empties `landmarks` before the rebuild, TPT keys and SET NULL parent, Down removes the landmark domains
   before `WgRegionId` is NOT NULL again) and `Services/DomainParents.cs` (one walk, cycle guard, depth cap; CrownLand
   and bare domains end without parents) and found nothing to fix. Noted, not fixed: Up leaves the old landmark pins'
   Location rows without a user and Down the new ones (dev DB only, harmless). Alternatives: (a) send L1 back for a
   Codex review once the limit resets, rejected (the developer's rule says merge without it); (b) a separate
   review subagent, not needed after the read above.
9. **L2 checked and merged into `next`** (2026-11-22 19:45 UTC). Chosen: merge; every check of skill § 6 held: heads
   matched, both branches contained `next`, PRs clean with the template, CI green on knk-web-api `2525be13` (push and
   PR runs), tests 5313 → 5327 passed (the one local MySQL red also fails on `next` locally and passes in CI), scope
   knk-web-api plus three docs, migration `AddLandmarkDiscoveryRule` additive (one disabled row, Down deletes it),
   7 agent decisions logged, #984 `status:in-review`, smoke § 2 tagged. Codex at its usage limit, merged without it.
   API `next` CI after the L1 merge (`8cc4511b`) was green (Build and test, Migrations). Alternatives: none needed.
10. **L3 and the shared knk-plugin navigation slot.** Chosen: L3 takes the slot now, agreed by message with the
    destination engine coordinator (#25, session_01R1w2UvZSm3y5hAXB8VfYuv: its L5 #747 waits for the developer's live
    test and, if its gate opens, for L3's merge) and the off-road coordinator (#698, session_01R1w2UuBBnWjqekMFxEMefN:
    no plugin link running or queued). Their requests are in L3's prompt (golden transcripts and flag-off tests
    unchanged, nothing new only on the flag-off path, `knk.navigate` granted in tests). Alternatives: (a) wait for
    #747, rejected (its gate is closed and has no date); (b) start L3 without asking, rejected (the slot is shared).
11. **Overlap with PandiO/knk-plugin#123 (#991, developer-run, open).** It adds `ManagedRegionKind.forNewRegion` and
    changes the kind line of `ManagedRegionsBootstrap.finalizeNewRegion`. Chosen: L3 goes ahead and keeps to other
    lines (a new LANDMARK constant, new `fromDomainType` arms and `DomainRegionSpecs` entries, its own test class),
    because the edits are additive elsewhere in the same files (developer decision 2026-11-12); a later merge stays
    mechanical. Alternatives: (a) hold L3 until #123 merges, rejected (no date, the developer merges it); (b) let L3
    take over #991's change, rejected (another session's open PR).
12. **L4 with L3.** Chosen: start L4 (knk-web-app) at the same time, as the charter allows; no knk-web-app PR is open
    and the #608 claim on `objectConfigs.tsx` (PermissionGrant, design waiting) is not active. L3 and L4 write
    separate knk-workspace branches and keep their changelog entries as separate blocks.
13. **L4's A17 finding: Landmark form seed v3 in knk-web-api** (2026-11-22 19:50 UTC). L4 found that seed v2 (L1) has
    no display conditions, so every step shows for every area kind, against DESIGN § 4.1 and A17. Chosen: L4 adds a
    small knk-web-api branch `claude/landmark-domain-l4-seed` from `next` with only the Landmark form seed v3 (new
    `configurationGuid`, default for Landmark, `displayConditionGroups` on `AreaKind = OwnRegion` for the Region field
    and the access/messages, warp and sub-region steps) and its seed test, PR into `next`, `Part of #986`; no knk-web-api
    link is running, so one link per component repo still holds. Seed v3 supersedes v2 in the deploy notes. If L4's
    `add_repo` is refused, it files a follow-up issue and the coordinator gets the seed done separately. Alternatives:
    (a) a follow-up issue and an e2e test with a mocked config only, rejected as the first choice (the form on `next`
    would keep showing steps for every area kind); (b) a Landmark rule hard-coded in the web app's `FormWizard`,
    rejected (form config duplicated in code); (c) change v2 in place, rejected (LD25: an import never overwrites an
    existing configuration).
14. **L3's first run blocked by the network; rerun in "Default Correct"** (2026-11-22 19:51 UTC). The first L3
    session ran in the environment "Default" (package registries only), where `repo.papermc.io`,
    `maven.enginehub.org`, `jitpack.io` and `maven.citizensnpcs.co` are refused, so the plugin could not compile; it
    stopped with nothing changed (block 4.3). Chosen: rerun L3 with `create_session` in the developer's environment
    "Default Correct" (`env_018Anjpntcn3H2W8a9ZJTQ1R`, saved for the four K&K repositories), same prompt plus a rerun
    note, because that is the environment saved for these repositories and a new session is the only way onto it (a
    running session is not moved onto an unrestricted network). Alternatives: (a) the subagent fallback, rejected (the
    coordinator also runs in "Default"; `repo.papermc.io` answers 403 here too); (b) propose the four hosts for
    "Default", rejected for now (it changes every session on the developer's default environment for one
    repository's needs); (c) wait for the developer, rejected (the saved environment answers it). Later plugin links
    should start in "Default Correct" from the first run.
15. **Charter § 3 item 8 (bugs picked up by the chain) was missed at the link starts.** The design session added it to
    the charter on `main` at 17:16 UTC (`637b32ae`, developer decision 2026-11-22: "tell the coordinator to pick up the
    remaining relevant bugs too"), after L1 had started (16:32 UTC); the coordinator did not re-read the charter before
    starting L2, L3 and L4, against skill § 3.1. Found at 20:00 UTC through L4's message. Effects and choices:
    1. #952 (L1's part, the region finalizer): L1 is merged without it. Chosen: a small fix link **L1b** on knk-web-api
       (`claude/landmark-domain-952` from `next`, `Closes #952`), started with `create_session` as soon as L4's seed
       branch is merged, so knk-web-api keeps one link at a time. Alternatives: (a) send it to the idle L1 session,
       rejected (links start in a fresh context; L1 is closed out); (b) start it now beside L4's seed branch, rejected
       (one link per component repo, although the files differ); (c) leave it to the docs session or the manager,
       rejected (the charter gives it to this chain).
    2. #958 and the plugin part of #951 (L3): relayed to the L3 rerun at 20:02 UTC with L4's bounds contract
       (`{"regionId", "bounds": {minX..maxZ}}` in the region task result); the knk-plugin PR closes #958 and is `Part of`
       #951.
    3. The web-app part of #951 (L4): already in L4's work (it read the charter); its knk-web-app PR closes #951.
    4. From now on the coordinator re-reads the charter from `origin/main` before every link start and check.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — API model, migration, area kinds and parent (#983)

1. **Scope done.**
    1. knk-web-api model: `Landmark : Domain` (TPT, `landmarks` keyed by the domain id), `Domain.WgRegionId` nullable
       (LD11), `AreaKind`, `ParentDomainId` (SET NULL), `ShowEnterLeaveMessages`; `ExtentKind`, `RegionId`, `Radius`
       gone.
    2. Migration `LandmarkAsDomain` (made with `dotnet ef migrations add`, then edited): drops the landmark rows first
       (LD10), rebuilds the table, makes `domains.WgRegionId` nullable; Down deletes the landmark domains first and
       restores the #708 table.
    3. One parent walk `Services/DomainParents.cs` (LD23) in `DomainMappingProfile.GetParentDomainDecisions` (ends
       the CrownLand loop, #981), `DomainRepository.GetByAnyRegionAsync`, `DomainRegionNameFinalizer`
       (`ParentRegionIdAsync`, pass order) and the landmark parent rules.
    4. `LandmarkService` / `LandmarkRepository` / DTOs / mapping on the hierarchy (area kinds, parent and cycle rule,
       pin copy LD17, name LD18, defaults LD24, warp checks); `domain_<id>` names via the domain path, the #945
       `landmark_<id>` path removed (finalizer, `RegionService.RenameLandmarkRegionAsync`, temp-region release).
    5. `DomainsController`: `PUT`/`DELETE api/Domains/{id}` on a landmark need `knk.admin.world.landmark` and run the
       landmark rules (LD19); plain domain writes without a region stay 400. `search-region-decisions` returns a
       landmark innermost (A05).
    6. Seeds: Landmark form seed v2 and Landmark display seed v2 (LD25).
    7. knk-workspace: changelog entry with deploy notes, smoke guide § 1 as built (14 steps, tagged), DESIGN status.
2. **Commits and heads.** knk-web-api `claude/landmark-domain` at `ca417528` (3 commits, base `next` at `4d9bea33`);
   knk-workspace `claude/landmark-domain-l1` at `e5d781e8` (1 commit plus a merge of `origin/next` for a changelog
   conflict with #990, base `next` at `0f7c3639`).
3. **PRs.** PandiO/knk-web-api#82 (`Closes PandiO/knk-workspace#983`), PandiO/knk-workspace#994 (`Part of`), base
   `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` `4d9bea33` build 0 errors, 5223 passed, 129 skipped (MySQL, no
       `KNK_TEST_MYSQL`), 5352 total; result at `ca417528` 5258 passed, 129 skipped, 5387 total (35 new tests, the
       landmark service and rename tests rewritten); at `12896982` with `KNK_TEST_MYSQL` on a local MySQL 8.0.46,
       5386 passed, 0 skipped. Migrations workflow steps run locally (up on empty DB, no pending model changes, down
       to 0, up again), plus Up over #708 rows and Down with landmark domains present. CI on the PR: Build and test,
       mysql-tests and fresh-database green on `12896982` and `ca417528` (the second, duplicate mysql-tests run of
       `ca417528` was still running when this block was written; its twin passed).
    2. Known reds (also red on the base): none.
    3. Acceptance: A01 `LandmarkServiceTests`, `RegionStillRequiredTests`; A02 `LandmarkAsDomainTests` and the
       Migrations workflow; A03 `LandmarkServiceTests.LinkedDomain_*`; A04 `LandmarkRegionRenameTests`; A05
       `DomainParentWalkTests`; A06 `DomainsControllerLandmarkTests`.
    4. Codex: no review on either PR, the connector's code-review usage limit was reached (asked again after each
       push); finished without it (developer decision 2026-11-14). A self-review found and fixed one bug
       (`ca417528`: the `PUT api/Domains/{id}` landmark answer would have been a JSON cycle).
5. **Decisions (DESIGN § 4.3).**
    1. *Old field names between L1 and L3.* Chosen: keep `domainId`, `extentKind` (`None`/`Region`), `regionId`,
       `radius` (null) as a read and write projection; a `Region` naming the area's current main region keeps the
       stored area; a radius is refused. The plugin on `next` keeps working until L3. Alternatives: (a) drop them and
       deploy L1 with L3: `/knk landmark` and landmark navigation broken on `next` in between; (b) emulate the radius:
       against LD08.
    2. *LinkedDomain in that projection.* Chosen: `Region` with the parent's main region (arrival in the parent's
       area). Alternative: (a) `None`, arrival at the pin only.
    3. *Landmark in `search-region-decisions`.* Chosen: one innermost slot; bottom-up keys start one higher with a
       landmark. Alternatives: (a) leave landmarks out until L3 (A05 asks for them); (b) key −1.
    4. *Rights on `api/Domains` landmark writes.* Chosen: the class rule `knk.admin.world` plus
       `knk.admin.world.landmark`; smoke guide landmark staff also hold `knk.admin.world` for the domain dashboard.
       Alternative: (a) the landmark node alone, needing a resource-aware filter instead of the pinned class rule.
    5. *Region required for plain domains.* Chosen: in `DomainsController` (where model binding enforced it).
       Alternative: (a) in `DomainService`, breaking callers that use the service without a region.
    6. *Children of a deleted landmark.* Chosen: made top level, a LinkedDomain child becomes a point. Alternative:
       (a) LinkedDomain without parent, refused at the next save.
    7. *Type sent to the plugin's rename.* Chosen: `Landmark` (before L3 the plugin treats it as STRUCTURE).
       Alternative: (a) null like a bare domain, which L3 could not tell apart.
    8. *Description on the v2 form.* Chosen: required (metadata check on non-nullable `Domain.Description`); the API
       accepts none (empty). Alternative: (a) a default on `Domain.Description` for every type.
    9. *Display seed version.* Chosen: "seed v2" like the form (no v1 existed). Alternative: (a) v1.
    10. *Landmark world.* Chosen: the pin's world set by `LandmarkService`, one-owner check there. Alternative: (a)
        `DomainWorldResolver`.
    11. *Answer of `PUT api/Domains/{id}` on a landmark.* Chosen: the landmark DTO. Alternatives: (a) the entity: a
        JSON cycle through the loaded sub-regions; (b) an untracked reread of the entity.
    12. *Merge commit without trailers.* The merge of `origin/next` into the knk-workspace branch (`e5d781e8`) kept
        git's default message without the trailer lines; it was pushed before this was noticed and is not rewritten
        (no force-push).
6. **Out of scope, noted.** `DomainMappingProfile.GetChildDomainDecisions` is unused and has the old loop shape;
   left as it is (comment on #981). No issue filed.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Back up the dev DB, then apply migration `LandmarkAsDomain`: every landmark row is deleted; recreate the test
       landmarks (v2 form or `/knk landmark create`).
    2. Import the `Landmark` form seed v2 and `Landmark.display` and make both the default; seed v1 and form 51 are
       superseded (the Region id projection is not carried over, #975).
    3. Deploy L1 to a server players use only together with L3 (effect damage and the LANDMARK managed kind are
       L3's); details in the changelog entry.
    4. Run smoke guide § 1 before the promotion of `next` (tier:3).
    5. #981 has `status:in-review` with #983 and stays open until `next` is promoted.
9. **Notes for later links.**
    1. L2 (#984): `api/Domains` lists, search and lookups include landmarks already, with no type field (`GET
       api/Domains/{id}` returns the entity) and no type filter; `TeleportDestinationService.DomainType` answers
       `Domain` for a landmark (add `Landmark`, type word `landmark`); `DiscoveryRepository` builds nodes for towns,
       districts and structures only, so a landmark has no discovery node yet; no `Landmark` discovery rule exists
       (a missing rule means not discoverable). The landmark search accepts `parentDomainId` and `domainId`.
    2. L3 (#985): read `areaKind`, `wgRegionId`, `subRegionIds`, `parentDomainId` and `parentDomain.wgRegionId` from
       `api/landmarks`; the region rename and `access-rules` carry `domainType` `Landmark`; `search-region-decisions`
       puts a landmark innermost (top-down after the structure, bottom-up key 0); a LinkedDomain area's sub-regions
       are the parent's (`by-region` / `api/Domains` of the parent). After L3 and L4, a later change can drop the
       #708 projection fields from the DTOs.
    3. L4 (#986): the form seed v2 field names (`ParentDomainId`, `AreaKind` enum `LandmarkAreaKind`, `WgRegionId`
       with the region task, `SubRegions`, access, messages, warp); `LandmarkListDto` has `parentDomain*`,
       `areaKind`, `wgRegionId` plus the old `domain*`/`extentKind` names; the domain panel's `domainId` filter still
       works.

### 4.2 L2 — API lists, discovery, warps and realtime (#984)

1. **Scope done.**
    1. Domain search (A07, LD20): `POST api/Domains/search` filters `domainType` (exact types, comma separated, any
       case; an unknown type matches nothing) and `excludeSubtreeOf` (a domain and every landmark below it, for the
       parent picker); landmarks already carried `domainType` `Landmark` (verified, L1's note was about `GET
       api/Domains/{id}`, which still returns the entity).
    2. Discovery (A08, LD15): migration `AddLandmarkDiscoveryRule` (made with `dotnet ef migrations add`, data only)
       seeds the `Landmark` rule disabled; `DiscoveryRewardRule.DomainTypes` gains `Landmark`; landmarks with
       `AreaKind` `OwnRegion` are discovery nodes (parent = `ParentDomainId`), so the per-domain override makes one
       discoverable; the ancestor walk follows landmark parents (bound 8).
    3. Warps (A09, LD21): `TeleportDestinationService.DomainType` answers `Landmark`, ranked last; "requires
       discovery" locked until the landmark was discovered (which needs its discovery on).
    4. Realtime (LD22): `Landmark` in `RealtimeEntityChangeMap.EntityTypes`, keyed by `WgRegionId`.
    5. knk-workspace: changelog entry with deploy notes, smoke guide § 2 as built (8 steps, tagged), DESIGN status.
2. **Commits and heads.** knk-web-api `claude/landmark-domain-integration` at `2525be13` (2 commits, base `next` at
   `8cc4511b`); knk-workspace `claude/landmark-domain-l2` at `fc64d3f2` (1 commit, base `next` at `724ebc10`).
   `origin/next` did not move in either repo while L2 ran (checked before the push), so no merge was needed.
3. **PRs.** PandiO/knk-web-api#84 (`Closes PandiO/knk-workspace#984`), PandiO/knk-workspace#1002 (`Part of`), base
   `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` `8cc4511b` build 0 errors, 5313 passed, 129 skipped (MySQL, no
       `KNK_TEST_MYSQL`), 5442 total; result at `2525be13` 5327 passed, 131 skipped, 5458 total (16 new tests; 3
       discovery tests updated for the fifth type). With `KNK_TEST_MYSQL` on a local MySQL 8.0.46: 5457 passed, 1
       failed (item 4.2). Migrations workflow steps run locally (update on an empty DB, no pending model changes,
       down past the new migration removes the row, down to 0, up again). CI on the PR: Build and test, mysql-tests and fresh-database green on `2525be13` (both runs, push and PR).
    2. Known reds: `MinecraftCatalogMySqlTests.UpgradePath_PhaseTwoKeepsRows_ConstraintsWaitForTheBackfill_ThenApply`
       fails locally with "Unknown column 'ArmorTrimMaterial'" on `next` `8cc4511b` as well (checked in a worktree of
       the base); not caused by L2. In CI (mysql-tests on `2525be13`) the same test passed, so it depends on the local MySQL 8.0.46 setup.
    3. Acceptance: A07 `LandmarkDomainIntegrationTests.Search_*`, `LandmarkDomainSearchMySqlTests`; A08
       `LandmarkDomainIntegrationTests.TheLandmarkRule_*`/`ALandmarkWithItsOverrideOn_*`/`OnlyALandmarkWithItsOwnRegion_*`,
       `AddLandmarkDiscoveryRuleTests`; A09 `LandmarkDomainIntegrationTests.ALandmarkWithItsWarpOn_*`/`RequiresDiscovery_*`;
       realtime `ConfigEntityEventTests.Map_ALandmarkChange_*`, `Interceptor_ALandmarkSave_*`.
    4. Codex: no review on either PR, the connector's code-review usage limit was reached; finished without it
       (developer decision 2026-11-14), said so on both PRs.
5. **Decisions (DESIGN § 4.3).**
    1. *Type filter semantics.* Chosen: the exact runtime type, matching the `domainType` column (`Structure` leaves
       out gates). Alternatives: (a) include subtypes: filter and column disagree; (b) 400 on an unknown type: the
       other search filters ignore bad values, and nothing wider is returned.
    2. *Parent-picker exclusion.* Chosen: an API filter `excludeSubtreeOf`. Alternatives: (a) the web app with
       `excludeIds`: it would first need the whole landmark tree; (b) nothing in L2: LD20 is in this link's binding.
    3. *Discovery nodes.* Chosen: landmarks with `OwnRegion` only. Alternatives: (a) every landmark: a point has nothing
       to enter and a `LinkedDomain` landmark would count in totals against rule 6; (b) `LinkedDomain` as an alias of
       its parent: duplicates the parent's discovery.
    4. *Rule values.* Chosen: disabled, the structure placeholders, no gems, `IncludeAncestors` false (LD09: the region
       may reach outside its parent). Alternatives: (a) all zeros: an override that only switches discovery on gives
       nothing; (b) ancestors on: entering a landmark outside its town would discover the town.
    5. *Migration, not seeder.* Chosen: a data migration, as `AddDomainDiscovery` seeds the other rules and a missing
       row means "not discoverable even with an override". Alternative: (a) a missing rule read as disabled defaults in
       code: differs from the other types.
    6. *`GET api/Domains` and `GET api/Domains/{id}`.* Left returning the entity (no type field). Alternative: (a) a
       computed `DomainType` on `Domain`: changes every domain's JSON and the form metadata reflection.
    7. *Summary `byType.enabled` for Landmark.* Left as the type rule's flag (false), as its DTO documents, also when
       overrides make landmarks discoverable. Alternative: (a) enabled when any domain of the type is: changes the
       staff "Disabled" tag for every type.
6. **Out of scope, noted.** The local MySQL known red of item 4.2 (Minecraft catalog upgrade path); no issue filed
   (green in CI, local only).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply migration `AddLandmarkDiscoveryRule` (data only, inserts the disabled `Landmark` rule).
    2. Run smoke guide § 2 when convenient (tier:2; 6 of 8 steps automated).
9. **Notes for later links.**
    1. L3 (#985): skip `POST api/Domains/search` items with `domainType == "Landmark"` in the navigation catalogue;
       realtime `EntityChanged` with `type` `"Landmark"`, `id` the domain id, `key` the landmark's own `WgRegionId`
       (null for `None` and `LinkedDomain`), plus the usual `DomainAccessChanged`/`TeleportDestinationsChanged`;
       teleport destinations `domainType` `"Landmark"` (type word `landmark`); discovery grants carry `domainType`
       `"Landmark"`; the summary's `byType` has a `Landmark` row with `enabled` false while `total` can be > 0, so a
       player view that hides disabled types would hide landmark discoveries.
    2. L4 (#986): `filters.domainType` (`"Landmark"`, or several comma separated) and `filters.excludeSubtreeOf` (the
       edited landmark's id) on `POST api/Domains/search`; the type column reads `domainType`; discovery settings list
       the `Landmark` rule last.

### 4.3 L3 — Plugin (#985)

1. **Scope done.** None: the link stopped at setup on a blocker (item 7). No code or docs changed.
2. **Commits and heads.** No commits. Branches not created on the remote: knk-plugin `claude/landmark-domain` and
   knk-workspace `claude/landmark-domain-l3` (both dry-run pushes from `origin/next` succeeded).
3. **PRs.** None.
4. **Tests, baseline → result.**
    1. knk-plugin: no baseline. `./gradlew build -x deployToDevServer` on `next` `822eb39b` fails at
       `:knk-core:compileJava`, because the dependencies can't be downloaded (item 7).
    2. Known reds: not measured.
5. **Decisions (DESIGN § 4.3).**
    1. *Stop instead of writing the code without a build.* Chosen: stop at setup, because the link could not compile or
       test anything, and the link skill lists a module that doesn't build as a blocker. Alternatives: (a) write the
       changes without compiling them and push them: the code would be unchecked, CI would be the first compiler, and
       a rerun would have to review all of it again; (b) do only the knk-workspace docs: the smoke-guide section and
       deploy notes have to describe what was built, so they would be guesses.
6. **Out of scope, noted.** None.
7. **Blockers.**
    1. *The session's network can't reach the plugin's Maven repositories.* Evidence: the session runs in the
       environment "Default" (limited network, package managers only). Gradle gets HTTP 403 from the agent proxy
       ("no rule or network setting allows this host") for `repo.papermc.io` (`paper-api:26.3.build.205-stable`);
       `maven.enginehub.org`, `jitpack.io` and `maven.citizensnpcs.co` are refused too. Maven Central and the Gradle
       plugin portal are reachable. The environment saved for knk-workspace and knk-plugin, "Default Correct"
       (`env_018Anjpntcn3H2W8a9ZJTQ1R`, unrestricted network), can't be switched to from here: a session that another
       session created can't change its environment.
    2. Setup otherwise worked: `add_repo` for knk-plugin, clone, `register_repo_root`, both dry-run pushes, and JDK 25
       (`openjdk-25-jdk-headless` from the Ubuntu noble archive after an `apt-get update`; `api.adoptium.net` is refused
       too).
    3. *Proposal.* Rerun L3 with `create_session` and `environment_id` `env_018Anjpntcn3H2W8a9ZJTQ1R` ("Default
       Correct"), with the same prompt. Or add the four hosts to the allowed hosts of "Default" (environment settings,
       Network access) and rerun there.
8. **At merge / what the developer must do.** Nothing to merge. For a rerun in "Default": allow `repo.papermc.io`,
   `maven.enginehub.org`, `jitpack.io` and `maven.citizensnpcs.co` (or use "Default Correct").
9. **Notes for later links.**
    1. The rerun of L3: JDK 25 comes from `sudo apt-get update` and then `sudo apt-get install -y openjdk-25-jdk-headless`
       (the package is missing before the update); build with
       `-Porg.gradle.java.installations.paths=/usr/lib/jvm/java-25-openjdk-amd64`.

### 4.4 L4 — Web app (#986)

1. **Scope done.**
    1. DTOs: `DomainBaseDto` (optional region); `LandmarkDto` on it; `LandmarkListDto` on the new names (`areaKind`,
       `wgRegionId`, `parentDomain*`).
    2. `landmark` in `DOMAIN_ENTITY_TYPES` (world check on save, sub-region parent link).
    3. Domain lists and pickers: Type column, Type filter (`domainType`); picker options "Type: …" (A07, A18).
    4. Domain dashboard: a landmark row opens the landmark page, its Edit the landmark form (DESIGN § 4.3).
    5. Landmark form: area words, "Linked domain's area" only while the parent has a region (A17, second half), the
       parent picker with `excludeSubtreeOf` on a saved landmark (A18); Enum fields gain `settingsJson.enumLabels`.
    6. `DomainLandmarksPanel` by `parentDomainId`, on a landmark's page too (children only); landmark list columns
       Parent, Area, Region.
    7. Discovery types gain `Landmark` (last); the overrides card offers landmarks.
    8. #951 web part: a region task result with `bounds` fills the step's empty MinX…MaxZ.
    9. knk-workspace: changelog entry with deploy notes, smoke guide § 4 as built (9 steps, tagged), DESIGN status.
2. **Commits and heads.** knk-web-app `claude/landmark-domain` at `4bc6b88` (2 commits, base `next` at `1d7c23b`);
   knk-workspace `claude/landmark-domain-l4` at `73e785d4` (1 commit, base `next` at `035f641f`). Neither `next` moved
   while L4 ran (checked before the final push), so no merge was needed.
3. **PRs.** PandiO/knk-web-app#78 (`Closes PandiO/knk-workspace#986`, `Part of PandiO/knk-workspace#951`),
   PandiO/knk-workspace#1004 (`Part of`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-app: `npm run test:ci` 347 suites, 2935 tests → 350 suites, 2951 tests, all passed; `npx tsc --noEmit`
       0 → 0 errors; `CI=true npm run build` passed → passed; Playwright 374 tests in 38 files → 382 passed (8 new in
       `e2e/landmark-domain.spec.ts`; `e2e/landmarks.spec.ts` updated). CI on the PR: build-and-test and e2e green.
    2. Known reds: none.
    3. Acceptance: A07 `landmark-domain.spec.ts` "shows each domain with its type …", `landmarks.test.ts`; A17
       "shows the region, access, warp and sub-region steps only with Own region" (mocked form with the conditions,
       see decision 1) and "offers Linked domain's area only with a parent that has a region", `landmarkForm.test.ts`;
       A18 "the parent picker shows the type and leaves out the landmark and its descendants"; DESIGN § 4.3 "edits a
       landmark with the landmark form …"; #951 "a drawn region's bounding box fills the empty bounds …",
       `regionTaskBounds.test.ts`.
    4. Codex: no review on either PR, the connector's code-review usage limit was reached; finished without it
       (developer decision 2026-11-14), said so on both PRs.
5. **Decisions (DESIGN § 4.3).**
    1. *A17 step visibility.* Chosen: not in L4; the steps hide through display conditions the API's Landmark form seed
       v2 doesn't carry, so follow-up #1003 (seed v3, with the conditions spelled out) and a deploy note to add them in
       the form builder meanwhile; the e2e test drives a mocked form with them. Asked the coordinator first (no answer
       before the rest was done, so option (b) of that message). Alternatives: (a) a seed v3 on a knk-web-api branch in
       L4: outside the prompt's repos; (c) a Landmark-only visibility rule in FormWizard: duplicates the form
       configuration in code.
    2. *Warp step without Own region.* Chosen: A17 as written in the test (warp hidden without Own region), and the
       question raised on #1003, since DESIGN § 4.1 item 5 and § 3 item 2 (v1 warp points) read as warps for points
       too. Alternative: (a) leave warp always visible: contradicts A17.
    3. *Linked domain's area.* Chosen: web-app rule (`landmarkForm.ts`) on the picked parent's `wgRegionId`, looked up
       with `GET api/Domains/{id}` when only the id is known; the option stays while unknown and when it is the stored
       value (then the API's message shows). Alternatives: (a) only the API's refusal on save: A17 asks the form to
       offer it only with a region; (b) a display condition: can't read the parent's data.
    4. *Parent picker exclusion.* Chosen: the wizard adds `excludeSubtreeOf` for Landmark/ParentDomainId on a saved
       landmark; the pinned rows ("Created in this form") drop only the landmark itself. Alternative: (a) a seed
       `pickerFilters` token `{id?}`: needs the seed again and the form values have no `id`.
    5. *Landmarks panel on a landmark's page.* Chosen: shown, listing the child landmarks (LD23 allows landmark
       parents), the landmark itself filtered out. Alternative: (a) hidden on landmark pages as before: child
       landmarks then have no list.
    6. *Opening a landmark from the domain list.* Chosen: only rows with `domainType` `Landmark` open as Landmark
       (LD24: other types unchanged). Alternative: (a) every row as its own type: changes the other types' pages.
    7. *Type filter values.* Chosen: a fixed list of the API's concrete types (Town … Landmark, CrownLand,
       Warehouse, ProductionStructure). Alternative: (a) types from the loaded rows: the filter would change with the
       page.
    8. *#951 result shape.* Chosen: `bounds: {minX, minY, minZ, maxX, maxY, maxZ}` (top-level keys accepted too),
       sent to the coordinator for L3; only empty, visible bound fields of the same step are filled. Alternative: (a)
       wait for L3's shape: L3 runs at the same time.
    9. *#951 closing keyword.* Chosen: `Part of #951` here, since L3 holds the plugin part; whichever of L3/L4 merges
       last closes it. Alternative: (a) `Closes` here: would close it before the plugin part.
    10. *World check for landmarks.* Chosen: `landmark` in `DOMAIN_ENTITY_TYPES` as the charter says; the check reads
        `api/Domains` (World area), as the parent picker does. Alternative: (a) skip the check for landmarks (the pin
        gives the world): a second rule for one type.
6. **Out of scope, noted.** #1003 (Landmark seed v3 display conditions, with the warp question). The domain
   dashboard's row links need a Domain display configuration (unchanged behaviour); not filed.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Deploy knk-web-app with phases 1 and 2 of the API; no settings, no migration.
    2. Decide on #1003 (warp step for point landmarks) and import seed v3 once built; until then add the "Area equals
       OwnRegion" conditions in the form builder by hand if wanted.
    3. Run smoke guide § 4 when convenient (tier:2; 6 of 9 steps automated, step 8 needs L3's plugin).
9. **Notes for later links.**
    1. L3 (#985): the region task's outputJson `bounds` object (block coordinates, whole numbers) is what the web app
       reads for #951; the PR that merges last closes #951.
    2. A later change can drop the #708 fields (`domainId`, `extentKind`, …) from `LandmarkListDto` in the API: the web
       app no longer reads them (the read DTO keeps them typed as deprecated).
