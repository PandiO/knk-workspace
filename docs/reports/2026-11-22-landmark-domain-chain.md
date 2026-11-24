# Landmarks as a Domain subtype chain — progress report

**Status:** Running (2026-11-22: L1 in `next`, L2 in review) · **Last updated:** 2026-11-24 (L2 block)

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
   landmarks), import the `Landmark` form seed v3 (L1b; v2 need not be imported) and `Landmark.display` and make both
   the default (form 51 and its Region id projection are superseded). Deploy the API (phases 1, 2 and L1b) before the
   plugin (L3). (Coordinator, 2026-11-22 21:40 UTC: seed v3 replaces v2 here; L3 is in `next`, so the earlier "not
   before L3" warning no longer applies.)
2. **L2 #984 in `next` (tier:2):** smoke guide § 2 (8 steps, 6 automated, 2 partly); deploy: apply migration
   `AddLandmarkDiscoveryRule` (data only, a disabled `Landmark` discovery rule).
3. **Agent decisions to review:** L1 block § 4.1 item 5 (11 decisions), L2 block § 4.2 item 5 (7 decisions), each with
   alternatives, and § 3 below.
4. **L4 #986 in `next` (tier:2):** smoke guide § 4 (9 steps: 6 automated, 2 partly, 1 by hand; step 8 needs L3).
5. **L3 #985 in `next` (tier:2):** smoke guide § 3 (9 steps; `navigation.landmarks: true` for steps 5, 6, 8); deploy:
   no `config.yml` key; run `/knk regions repair` once after the plugin deploy. Decide: the gate check in
   `SimpleRegionTransitionService` compares against "gate" while the API sends "GateStructure" (block 4.3b item
   6.1): **answered 2026-11-24**, filed as #1015 (to check). #958: **fixed and in `next`** (fix link L3b, 2026-11-24:
   the NPC route line on a 1/4096 grid; scene order no longer matters). **Review:** paper-boot CI now takes about 32
   minutes (job limit 50, wait 2400 s) because L3b's check scenario replays the walk at x ≥ 32768 (about 3.5 minutes);
   a shorter check is possible later if CI time matters more.
6. **#1003 answered 2026-11-24 and in `next` (L4b):** the "Warp destination" step shows for every area kind. Deploy:
   import "Landmark - Default (seed v4)" as the default (instead of v3 or v2). Smoke § 1 step 2, § 4 step 1, § 5
   steps 5–6, and the by-hand parts of the new § 3.2 (steps carried over from the off-road guide).
7. **L1b (#952, #1003) in `next`:** smoke guide § 5; deploy: import the Landmark form seed v3 and make it the
   default (v2 need not be imported; after L4b: seed v4). #1006 **answered 2026-11-24**: it goes with #989 (the
   generic region lifecycle), now its sub-issue; until then the manual way out of managed-worldguard-regions § 7
   applies.
8. **Docs:** #1008 done and closed by its docs session (session_01R1w2UsgKAzYiVf45xr41DR; main docs PR #1011 merged
   into `next` `188ade30`); leftovers #1009 and #1010. The smoke § 1 wording fix (seed v3, step 14 after L3) is
   PandiO/knk-workspace#1012 into `next`, merged by the docs session.
9. **Off-road smoke § 6 and § 7 (#698): answered 2026-11-24, done (L4b, #1009 closed):** superseded by landmark-domain
   § 3; the uncovered steps are in § 3.2.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 API model, migration, area kinds and parent (tier:3) | #983 | Merged into `next` 2026-11-22 18:37 UTC (knk-web-api `8cc4511b`, knk-workspace `724ebc10`) | `claude/landmark-domain`: knk-web-api `00ee3115` (after merging `next` `c647daf7`); `claude/landmark-domain-l1`: knk-workspace `ba0596e0` (coordinator, 2026-11-22: the heads in block 4.1 item 2 predate that merge) | [knk-web-api#82](https://github.com/PandiO/knk-web-api/pull/82), [knk-workspace#994](https://github.com/PandiO/knk-workspace/pull/994) | green on `00ee3115` (build-and-test, mysql-tests, fresh-database); knk-workspace no checks; Codex at its usage limit (skipped) | create_session session_01R1w2Uv1A4MYoi62zFJTnwz, started 2026-11-22 16:32 UTC |
| L2 API lists, discovery, warps and realtime (tier:2) | #984 | Merged into `next` 2026-11-22 19:45 UTC (knk-web-api `55d187d8`, knk-workspace `035f641f`) | `claude/landmark-domain-integration`: knk-web-api `2525be13`; `claude/landmark-domain-l2`: knk-workspace `fc64d3f2` | [knk-web-api#84](https://github.com/PandiO/knk-web-api/pull/84), [knk-workspace#1002](https://github.com/PandiO/knk-workspace/pull/1002) | green on `2525be13` (build-and-test, mysql-tests, fresh-database; push and PR runs); knk-workspace no checks; Codex at its usage limit (skipped) | create_session session_01R1w2Ux3HrcYVs53AugdtZW, started 2026-11-22 18:39 UTC |
| L3 Plugin (tier:2), also #958 (findings only) and the plugin part of #951 | #985 | Merged into `next` 2026-11-22 21:38 UTC (knk-plugin `14645895`, knk-workspace `e6bb8dfe`) | `claude/landmark-domain`: knk-plugin `31658c58`; `claude/landmark-domain-l3`: knk-workspace `43bcdbf3` | [knk-plugin#125](https://github.com/PandiO/knk-plugin/pull/125), [knk-workspace#1005](https://github.com/PandiO/knk-workspace/pull/1005) | green on `31658c58` (build, paper-boot; both runs, one build re-run for a `HarvestModuleTest` setup error outside the PR); Codex at its usage limit (skipped) | create_session session_01R1w2UtBFy9s4dBXQoeBMQF (blocked, network); rerun session_01R1w2UuLNw6Cr3qwUKQNvao in "Default Correct" (decision 14) |
| L4 Web app (tier:2) | #986 | Merged into `next` 2026-11-22 20:19 UTC (knk-web-app `8c9c3553`, knk-workspace `99da72cc`) | `claude/landmark-domain`: knk-web-app `4bc6b88d`; `claude/landmark-domain-l4`: knk-workspace `73e785d4` | [knk-web-app#78](https://github.com/PandiO/knk-web-app/pull/78), [knk-workspace#1004](https://github.com/PandiO/knk-workspace/pull/1004) | green on `4bc6b88d` (build-and-test, e2e; both runs); knk-workspace no checks; Codex at its usage limit (skipped) | create_session session_01R1w2UtGykzTGpUL4Ksj6S6, started 2026-11-22 19:46 UTC |
| L1b #952 region re-run left on a temp name, and #1003 Landmark form seed v3 (charter § 3 item 8; fix link) | #952, #1003 | Merged into `next` 2026-11-22 20:50 UTC (knk-web-api `3bc3cfd5`, knk-workspace `f7e4f671`); `domain_<id>` part of #952 split off to #1006 | `claude/landmark-domain-952`: knk-web-api `60fe2723`; `claude/landmark-domain-l1b`: knk-workspace `d06f362d` | [knk-web-api#85](https://github.com/PandiO/knk-web-api/pull/85), [knk-workspace#1007](https://github.com/PandiO/knk-workspace/pull/1007) | green on `60fe2723` (build-and-test, mysql-tests, fresh-database; both runs); Codex at its usage limit (skipped) | create_session session_01R1w2Ut1aonbYwio9RXX7mA, started 2026-11-22 20:20 UTC |
| L3b #958 NPC replay fails at scene origin x ≥ 32752 (developer decision 2026-11-24; fix link) | #958 | Merged into `next` 2026-11-24 12:20 UTC (knk-plugin `2c5d5846`, knk-workspace `f193120d`) | `claude/npc-replay-958`: knk-plugin `a888d8c6`, knk-workspace `a340f689` | [knk-plugin#126](https://github.com/PandiO/knk-plugin/pull/126), [knk-workspace#1018](https://github.com/PandiO/knk-workspace/pull/1018) | green on `a888d8c6` (build, paper-boot with 80 scenarios, both runs); Codex at its usage limit (skipped) | create_session session_01R1w2UuF3ht2BpNQtH69s5f in "Default Correct", 2026-11-24 08:13 UTC |
| L4b #1003 warp step for every area kind (seed v4) and #1009 off-road smoke §§ 6–7 superseded (developer decisions 2026-11-24; fix link) | #1003, #1009 | Merged into `next` 2026-11-24 09:55 UTC (knk-web-api `e06fd5c0`, knk-web-app `8be9e24c`, knk-workspace `d8eac5f2`); #1009 closed (docs) | `claude/landmark-warp-step-1003`: knk-web-api `a65baee9`, knk-web-app `f1d5491e`; `claude/landmark-domain-l4b`: knk-workspace `0a0d74bd` | [knk-web-api#86](https://github.com/PandiO/knk-web-api/pull/86), [knk-web-app#79](https://github.com/PandiO/knk-web-app/pull/79), [knk-workspace#1016](https://github.com/PandiO/knk-workspace/pull/1016) | green (API build-and-test, mysql-tests after one re-run of flaky #1017, fresh-database; web app build-and-test, e2e); Codex at its usage limit (skipped) | subagent of the coordinator, 2026-11-24 08:20–09:50 UTC |

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
16. **L4 checked and merged; seed v3 goes to L1b** (2026-11-22 20:20 UTC). L4 took its option (b): it filed #1003
    (seed v3) and asked on it whether the warp step should stay for point landmarks; it did not build the seed
    (coordinator decision 13's option, sent twice, was not acted on). Every check of skill § 6 held for L4 (CI green
    on `4bc6b88d`, Jest 2935 → 2951, Playwright 374 → 382, scope knk-web-app and three docs, 10 agent decisions,
    smoke § 4 tagged, #986 `status:in-review`, Codex at its usage limit), so it was merged; the missing display
    conditions are seed data and do not block the web app. Chosen for #1003: L1b builds seed v3 together with #952
    (both small knk-web-api changes, one knk-web-api link at a time), with the warp step following A17 as written
    (hidden without an own region) as the reversible default until the developer answers on #1003. Alternatives:
    (a) send L4 back to build the seed, rejected (L4 is done and the API part fits L1b); (b) a separate L4b link,
    rejected (a second knk-web-api link for one JSON file); (c) leave the warp step unconditional, rejected as the
    default (A17 is the approved acceptance text; DESIGN § 4.1 item 5 is only silent).
17. **L1b checked and merged into `next`** (2026-11-22 20:50 UTC). Every check of skill § 6 held: heads matched, both
    branches contained `next`, CI green on `60fe2723` (both runs), tests 5327 → 5344 passed, scope the region
    finalizer, the Landmark seed and their tests plus three docs, smoke § 5 tagged, #952/#1003 `status:in-review`,
    Codex at its usage limit. The coordinator read the finalizer change, since it redefines regions in place: it heals
    only on a retry for a row already stored on its temp region, only for names the API creates (sub-regions,
    `lootbox_area_`, `production_area_`, `siege_spot_`), and never when another row names the region; `domain_<id>` is
    left to #1006 (a plugin check of the existing region is needed). Alternatives: (a) hold the merge until #1006 is
    designed, rejected (the healed kinds are safe on their own); (b) heal `domain_<id>` too, rejected (a legacy region
    can carry the name, managed-worldguard-regions § 8 item 9).
18. **L3 checked and merged into `next`** (2026-11-22 21:38 UTC). Every check of skill § 6 held: heads matched and
    were level with `next` (#123 merged in without touching its lines), CI green on `31658c58` (build, paper-boot;
    the one red push-run `build` was a `HarvestModuleTest` setup error in an area the PR doesn't touch, green on its
    re-run), tests knk-core 3779 → 3809, knk-api-client 429 → 430, knk-paper 3490 → 3496, local paper-boot 79/79,
    scope knk-plugin plus three docs, smoke § 3 tagged (9 steps), 11 agent decisions, #985 `status:in-review`, Codex
    at its usage limit. #958 was not fixed: L3 narrowed it (a sharp threshold at scene origin x 32740/32752, only the
    group of 20 differs; suspects in `core/npc/nav/` group and crowd code or Citizens' follower path search, the area
    of the open NPC PRs #116–#119) and left the findings and a 4-minute reproduction on #958, as the coordinator's
    note allowed; the workaround (new scenarios registered last) holds. Nit, not fixed: the `paper-boot.yml` comment
    says 79 while `MIN_SCENARIOS` is 76 (the floor; 79 is the local total). Alternatives: (a) hold the merge for
    #958, rejected (outside the landmark code, in another session's area); (b) fix the comment before merging,
    rejected (comment only, no effect on the floor).
19. **At merge.** The documentation sub-issue #1008 ("Docs: Landmarks as a Domain subtype", `documentation`,
    `tier:1`) was created under #976 and its docs session started at once (session_01R1w2UsgKAzYiVf45xr41DR, base
    knk-workspace `next`). #976 and the link issues stay open, `status:in-review`, until the developer promotes `next`.
    The #25 and #698 coordinators were told the knk-plugin navigation slot is free.
20. **`next` green after the last merges** (checked 2026-11-22 22:12 UTC): knk-web-api `3bc3cfd5` (Build and test,
    Migrations), knk-web-app `8c9c3553` (Build and test, End-to-end), knk-plugin `14645895` (Build, Paper boot test).
    Smoke guide § 1 on `next` still has wording from before L3, L4 and L1b (steps 2–3 name seed v2, § 1.0 item 1 the
    in-between state, step 14 "before L3"); handed to the docs session #1008 to correct in its docs PR rather than a
    coordinator push to `next` (skill § 7.6). Final report on #976.
21. **The developer's answers of 2026-11-24** (asked through the ask-user prompt, five questions) and what followed:
    1. #1003, warp step: "Show for every area". Chosen: fix link **L4b** builds a Landmark form seed v4 (the seeds
       README: a changed seed ships with a new `configurationGuid` and name, so v3 cannot change in place), updates
       L4's e2e test, DESIGN (LD26, A17, § 4.1 item 5) and the smoke guide. Alternatives: (a) change v3 in place,
       rejected (an import never overwrites, so databases with v3 would keep the old form); (b) leave it to the docs
       session, rejected (code and seed change).
    2. #1006: "Recently an issue was added to consolidate domain wg region retention, removal, cleanup operations",
       read as: it goes with #989 (the generic region lifecycle, scope item 3, one generic replace decision). Made a
       sub-issue of #989, comments on both. Alternatives: (a) a fix link now, rejected (the developer pointed to #989);
       (b) close it, rejected (the problem stays until #989 lands).
    3. #958: "Separate session now". Chosen: fix link **L3b** with `create_session` in "Default Correct" (plugin, one
       component repo), out of the lines of the open NPC PRs #116–#119, out of `core/navigation/`. Alternatives: (a)
       hand it to the NPC navigation chain, rejected (the developer asked for a separate session now).
    4. Gate check: "File an issue to check". Filed #1015 (`bug`, `tier:1`, `knk-plugin`).
    5. Off-road smoke § 6/§ 7: "Close as superseded". The docs session's leftover #1009 (rewrite them) changes to:
       move the uncovered steps into landmark-domain § 3, then mark the off-road sections superseded; given to **L4b**
       (it edits the same smoke guide). The off-road coordinator is told and may take the off-road file edit itself.
    6. Route of L4b: a subagent of the coordinator, because it changes two component repos (knk-web-api, knk-web-app)
       and L4's `create_session` attach of knk-web-api was refused once (skill § 4.1.4.2). L3b and L4b share no
       component repo.
22. **L4b checked and merged into `next`** (2026-11-24 09:55 UTC). Every check of skill § 6 held: heads matched, all
    three branches contained `next`, scope as asked, CI green (API after one re-run of a flaky MySQL test outside the
    change, filed #1017), tests at or above baseline, decisions logged, smoke steps tagged, Codex at its usage limit.
    The coordinator read the seed diff: v4 differs from v3 only in GUIDs, name, description and the dropped warp-step
    condition. #1009 closed (docs in `next`); the off-road coordinator was told. Alternatives: none needed.
23. **L3b checked and merged into `next`** (2026-11-24 12:20 UTC). Every check of skill § 6 held: heads matched, both
    branches contained `next`, scope (`RouteFollower`, `NavGroup`, the replay scenario, `PaperScenarios`,
    `paper-boot.yml`, three docs) out of the open NPC PRs' lines and out of `core/navigation/`, CI green on
    `a888d8c6` (build, paper-boot 80 scenarios, both runs), tests knk-core 3809 → 3813 (others unchanged), block 4.6
    with four decisions, #958 `status:in-review`, Codex at its usage limit. The coordinator read the fix: the route
    line's x and z on a 1/4096 grid (exact as a double anywhere in the world border; the root cause was the lost
    fraction bit from x 32768 with a road along a block face) and a `NavGroup` queue fix the exact coordinates
    exposed. Accepted with a flag for the developer: paper-boot's wait 1800 → 2400 s and job limit 40 → 50 minutes
    for the 3.5-minute check scenario. Alternatives: (a) send L3b back for a shorter check scenario, rejected (the full
    replay is the proof the developer's issue asked for; shortening it is reversible later); (b) hold the merge for
    the developer, rejected (CI time is not a merge gate).

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

### 4.3b L3 rerun — Plugin (#985)

1. **Scope done.**
    1. knk-api-client: `LandmarkDto`/`LandmarkMapper` read `areaKind`, `wgRegionId`, `subRegionIds`, `parentDomainId`,
       `parentDomain.wgRegionId`, `showEnterLeaveMessages` and write `parentDomainId`, `areaKind`, `wgRegionId`; the
       #708 projection is no longer read or written.
    2. knk-core landmarks and navigation: `LandmarkAreaKind`; `KnkLandmark`/`LandmarkWrite` on the new model; the
       navigation `Landmark` holds the area's region ids (main first); `LandmarkExtent` is a point or an area (cylinder
       gone, LD08); `LandmarkProvider` routes to the main region with the other regions as arrival (LD22);
       `LandmarkWeights.UnionArea` weights the union once; the snapshot file writes `regionIds` and still reads an old
       `REGION` extent.
    3. knk-paper navigation: `Destination.areaRegionIds`, `HandleDestinations`, `RegionShapes.domainRegionIds`
       (WorldGuard: the other regions with the main region's `knk-domain-id`, for a `LinkedDomain` parent's
       sub-regions); `ModelLandmarks` adds them for the weights; `NavigationService` (two small changes, item 5.3).
    4. Managed regions (LD13, A13): `ManagedRegionKind.LANDMARK` (floor 30, parent + 10, no flags) as a new constant and
       `fromDomainType` arm; `DomainRegionSpecs.landmarks`; `ManagedRegionSpecSource` and `ManagedRegionsBootstrap`
       read `api/landmarks` (a failed read is a warning). `finalizeNewRegion`'s kind line and `forNewRegion` (#123)
       untouched; a test pins `forNewRegion("Landmark")` = LANDMARK. Paper-boot scenario
       `landmark-region-is-managed-under-its-parent` (registered last), `MIN_SCENARIOS` 76.
    5. `DomainEffectDamage` leaves landmarks out (LD12, A11).
    6. Messages (LD15, A12): `LandmarkMessageSettings` (landmarks with `showEnterLeaveMessages`, from `api/landmarks`
       at start-up and on realtime); `SimpleRegionTransitionService.setLandmarkMessages` and a landmark message after
       town, district and structure; the gate check null-safe (§ 7.2 item 4).
    7. Wording (A08, A09): "the landmark" / "Landmark" / "Landmarks", lodestone icon; the discoveries summary counts
       landmarks although the type rule is off; `/warp landmark:<name>` (already worked through the type word, now
       tested).
    8. `/knk landmark` (A15): `create … radius <n>` refused with the way to a round region and the usage line; `link`
       never offers or takes the landmark itself; `show` tells area, parent and messages.
    9. Realtime (A16): `LandmarkRealtime` (catalogue entry, region cache, coalesced navigation-model and message
       refresh); `NavigationDomainChanges.DOMAIN_TYPES` gains `Landmark`.
    10. `landmark_<id>` path removed (LD14): the temp-region cleanup's landmark owner lookup; the two landmark region
        scenarios use `domain_<id>`.
    11. #951 plugin part (charter § 3 item 8.2): the WgRegionId task's result (`RegionCreate`, `ReagionCreate`,
        `RegionClaim`) carries `bounds` {`minX` … `maxZ`}; the shape was sent to L4 and matches L4's reader.
    12. knk-workspace: changelog block (after L4's) with deploy notes, smoke guide § 3 as built (9 steps, tagged),
        DESIGN status line.
2. **Commits and heads.** knk-plugin `claude/landmark-domain` at `31658c58` (6 commits plus a merge of `origin/next`
   `3f39f15a`, base `next` at `822eb39b`); knk-workspace `claude/landmark-domain-l3` at `43bcdbf3` (1 commit plus a
   fast-forward to `99da72cc` and a merge of `f7e4f671` with L1b's docs, base `next` at `035f641f`). Both are level
   with `origin/next` (checked before this block).
3. **PRs.** PandiO/knk-plugin#125 (`Closes PandiO/knk-workspace#985`, `Part of PandiO/knk-workspace#951`),
   PandiO/knk-workspace#1005 (`Part of`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin: baseline on `next` `822eb39b` `./gradlew build -x deployToDevServer` green: knk-core 3779,
       knk-api-client 429 (2 skipped), knk-paper 3490 (18 skipped). Result at `31658c58` (with `next` `3f39f15a`,
       which adds #123's `NewRegionKindTest`): knk-core 3809, knk-api-client 430 (2 skipped), knk-paper 3496 (18
       skipped), green. Obsolete radius and `landmark_<id>` tests were rewritten or removed. CI on the PR: `build` and
       `paper-boot` green on `31658c58`; the push run's `build` failed once in `HarvestModuleTest` with a JUnit
       `IOException` in the test's own setup (untouched area; 3 of 3 local passes) and passed on its one re-run.
       Local paper-boot (pinned Paper 26.3-205, WorldEdit, WorldGuard, Citizens): 79 of 79 passed.
    2. Known reds: none.
    3. Acceptance: A08/A09 `DiscoveryLandmarkTest`, `WarpTargetsTest.aLandmarkIsAWarpTarget_*`; A10
       `AccessFlagSyncTest.aLandmarksOwnRegion*`, `LandmarkTransitionMessagesTest.aLandmarkWithEntryOff_*`; A11
       `DomainEffectDamageTest.aLandmarkNeverMakesASafeZone_*`; A12 `LandmarkTransitionMessagesTest`; A13
       `LandmarkRegionKindTest` and the scenario; A14 `LandmarkProviderTest`, `NavigationServiceLandmarkTest`,
       `ModelLandmarksTest`, `LandmarkWeightsTest`, `HandleDestinationsLandmarkTest`; A15 `LandmarkCommandArgsTest`,
       `LandmarkAdminCommandTest`; A16 `LandmarkRealtimeTest`; API data `LandmarksApiImplTest`; #951
       `WgRegionIdTaskOutputTest`.
    4. Codex: no review on either PR, the connector's code-review usage limit was reached; finished without it, said
       so on both PRs.
5. **Decisions (DESIGN § 4.3).**
    1. *A `LinkedDomain` area's sub-regions.* Chosen: the model holds the parent's main region; the server adds the
       other regions with the same `knk-domain-id` (the access sync puts it on every region of a domain), once per
       navigation and per weights pass. `api/landmarks` lists no parent sub-regions. Alternatives: (a) an extra
       `by-region`/`api/Domains` call per landmark at model refresh: more API calls and a second source; (b) read the
       access rules in the model refresh: couples the navigation model to the access sync.
    2. *Arrival over a union.* Chosen: route to the main region (goals and walk target unchanged), arrival in any of the
       area's regions. Alternatives: (a) a union `RegionShape` for routing: `RegionShape` is one polygon, and every
       goal path in `NavigationService` would change; (b) one destination per region: the landmark would be listed
       several times (LD22).
    3. *`NavigationService` touch (for #25).* Two small changes on the engine path: `navigate(player, handle)` calls
       `withDomainRegions` once, `insideRegion` also checks the area's other regions; `NavigateCommand.withMode` and
       the flag check untouched. The arrival-radius mechanics of `Destination`/`Place.Point` stay (no provider sets one
       now; the cylinder test is inlined in `Destination`), so #747 can remove them with the old path. Alternative:
       (a) remove the arrival radius now: more `NavigationService` edits while #747 deletes that code anyway.
    4. *Where the messages switch comes from.* Chosen: `LandmarkMessageSettings` read from `api/landmarks` (start-up,
       realtime), off for an unknown landmark. The region decisions don't carry `showEnterLeaveMessages`.
       Alternatives: (a) add the field to `DomainRegionDecisionDto`: an API change outside this link (worth a
       follow-up when the projection is dropped); (b) a per-transition API call: on the movement hot path.
    5. *Landmark message priority and wording.* Chosen: after town, district and structure (innermost), "You are now
       entering <name>." / "You are now leaving <name>." like a town. Alternative: (a) the district form with the
       parent name: a landmark's parent may be any domain or none.
    6. *Gate check.* Chosen: null-safe only (`"gate".equals(type)`), behaviour unchanged; the API's type is
       `GateStructure`, so this check never matches today. Alternative: (a) also match `GateStructure`: would start
       opening gates on entry, a behaviour change outside the link (noted, item 6).
    7. *Repair source.* Chosen: `api/landmarks` beside towns, districts and structures, a failed read only a warning.
       Alternative: (a) fail the repair: one unreadable leaf list would stop the whole hierarchy's repair.
    8. *Nested landmark parents.* Chosen: WorldGuard parent = `parentDomain.wgRegionId`; a landmark under a point or
       `LinkedDomain` landmark is top level. Alternative: (a) walk up to the nearest region: needs the parent chain,
       which `api/landmarks` doesn't give.
    9. *Discoveries summary for staff.* Chosen: the `Landmark` row counts like an enabled type when `total` > 0, else
       "Disabled". Alternative: (a) keep "Disabled": hides that some landmarks are discoverable (L2's note).
    10. *`/knk landmark create` radius detection.* Chosen: refused only where the old keyword stood (`… radius <n>` or a
        trailing `radius`), so "Radius tower" stays a name. Alternative: (a) any word `radius`: refuses real names.
    11. *Snapshot file.* Chosen: write `regionIds`, keep reading `extent`/`regionId` (schema 1, additive).
        Alternative: (a) schema 2: an older plugin would discard the whole offline model.
6. **Out of scope, noted.**
    1. The gate check in `SimpleRegionTransitionService` compares the type with `gate` while the API sends
       `GateStructure`, so `GateControlPort` is never triggered from transitions; not filed (it may be intended: gates
       are opened elsewhere); for the developer to decide.
    2. `DomainRegionDecisionDto` could carry `showEnterLeaveMessages` when the #708 projection is dropped (L1's note
       9.2), which would make `LandmarkMessageSettings` unnecessary.
7. **Blockers.** None for #985. #958 (charter § 3 item 8.2) is **not fixed**, as the coordinator's message allows:
   a local 4-minute reproduction and a sharp threshold by scene origin (pass up to origin x 32740, fail from 32752;
   only the group of 20 differs, the leader alone is identical) are on #958; the remaining suspects are the group and
   crowd code in `core/npc/nav/` and Citizens' path search for followers, which the open NPC PRs #116–#119 touch.
   Proposal: an NPC-navigation session takes #958 with that reproduction; the workaround (new scenarios last) holds.
8. **At merge / what the developer must do.**
    1. No `config.yml` key. Deploy with knk-web-api phases 1 and 2.
    2. Run `/knk regions repair` once after the deploy (existing landmark regions get their LANDMARK parent and
       priority).
    3. Run smoke guide § 3 when convenient (tier:2; 9 steps, most partly automated).
    4. Decide on item 6.1 (gate check) and who takes #958.
9. **Notes for later links.**
    1. A later API change can drop the #708 projection from the landmark DTOs: knk-plugin no longer reads it.
    2. #958's reproduction: a copy of `tools/paper-boot/boot-test.sh` that sets `testing.scenarios.origin.x` and sends
       `knk scenario run npc-replay-quarry-to-keep` (details on the issue).

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
3. **PRs.** PandiO/knk-web-app#78 (`Closes PandiO/knk-workspace#986` and `#951`),
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
       Update after the block was first written: the coordinator's answer (a) arrived late; `add_repo` for
       knk-web-api was then refused by this session's permission check, so per the coordinator's fallback (b) stands
       and the coordinator gets seed v3 (#1003) done separately.
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
    9. *#951 closing keyword.* First `Part of #951`; changed to `Closes PandiO/knk-workspace#951` in #78 on the
       coordinator's instruction (2026-11-22), the plugin part being L3's.
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
       reads for #951; #78 closes #951.
    2. A later change can drop the #708 fields (`domainId`, `extentKind`, …) from `LandmarkListDto` in the API: the web
       app no longer reads them (the read DTO keeps them typed as deprecated).

### 4.5 L1b — Region re-run left on a temp name (#952) and Landmark form seed v3 (#1003)

1. **Scope done.**
    1. #952 (`Services/DomainRegionNameFinalizer.cs`): on a retry for a row already stored on its temp region (an
       update whose previous region equals the current one, or `FinalizeAllAsync`, which now passes each sub-region's,
       lootbox area's, production area's and siege spot's current region), the finalizer names the row's own final
       name as `replaceRegionId` (`HealableSubRegionFinalNameAsync`, `HealableOwnedFinalNameAsync`), unless a domain,
       sub-region, lootbox area, production area or siege spot names it. Covered: `domain_<id>_sub_<n>`,
       `lootbox_area_<id>`, `production_area_<id>`, `siege_spot_<id>`. Not covered: `domain_<id>` (decision 1,
       follow-up #1006). A first save and a real re-run behave as before.
    2. #1003 (`Data/FormConfigurationSeeds/Landmark.json`): "Landmark - Default (seed v3)", configuration
       `8cefaf90-b32d-543b-b16f-73b5254c07f9`, seed v2 plus "AreaKind Equals `OwnRegion`" on the Area step's
       `WgRegionId` (FormField) and the steps "Access and messages", "Warp destination", "Sub-regions" (FormStep), as
       `GateDoor.json`; seeds README entry. v2 kept (not deleted, not default).
    3. knk-workspace: changelog block (its own, under Unreleased) with deploy notes; smoke guide § 1.0 and § 4.0 name
       seed v3, § 4 step 4 the v3 name, new § 5 "Fixes picked up by the chain" (5 steps, tagged);
       `architecture/managed-worldguard-regions.md` § 7 #952 paragraph.
2. **Commits and heads.** knk-web-api `claude/landmark-domain-952` at `60fe2723` (2 commits: `6ac72c43` #952,
   `60fe2723` seed v3; base `next` `55d187d8`); knk-workspace `claude/landmark-domain-l1b` at `d06f362d` (1 commit,
   base `next` `99da72cc`). Neither `next` moved while L1b ran (checked before opening the PRs), so no merge was needed.
3. **PRs.** PandiO/knk-web-api#85 (`Closes PandiO/knk-workspace#952`, `Part of #1003`), PandiO/knk-workspace#1007
   (`Part of #952`, `Part of #1003`), base `next`. Not merged. `Part of #1003`: the developer has not answered the
   warp question on #1003.
4. **Tests, baseline → result.**
    1. knk-web-api: `dotnet build` 0 errors → 0 errors; `dotnet test` 5327 passed, 131 skipped, 0 failed → 5344
       passed, 131 skipped, 0 failed (new: 16 in `Services/TempNameHealTests`, 1
       `FormConfigurationSeedFilesTests.LandmarkSeed_V3_ShowsTheOwnRegionParts_OnlyForAnOwnRegion`). The 131 skipped
       are the MySQL tests (no `KNK_TEST_MYSQL` locally); CI ran them. CI on #85: green on `60fe2723` (build-and-test, mysql-tests, fresh-database; push and PR runs).
    2. Changed pinned tests (decision 5): `LootboxAreaRegionRenameTests.Update_WithTheSameTempRegion_RetriesTheRename_ReplacingItsOwnFinalName`
       (renamed from `…_WithoutReplacing`), `LootboxAreaRegionRenameTests.FinalizeAll_AlsoRenamesAreasStillOnATempName`,
       `DomainSubRegionTests.FinalizeAll_RenamesSubRegionsLeftOnATempName_AfterTheDomains`; the v2 seed test now
       checks v3 (`LandmarkSeed_IsV3_…`).
    3. Known reds: none.
    4. Codex: the review failed on both PRs, usage limit reached, no inline findings; finished without it (developer
       decision 2026-11-14), said so on both PRs.
5. **Decisions (DESIGN § 4.3).**
    1. *Owners #952 heals.* Chosen: sub-regions, lootbox areas, production areas, siege spots (names only the v3 API
       creates); `domain_<id>` left out, since a v2 region can carry it (managed-worldguard-regions.md § 8 item 9) and
       the plugin's in-place redefine keeps the existing region's owners, members and flags. Alternatives: (a) heal
       `domain_<id>` too: a v2 orphan's legacy owners and flags would land on the new domain; (b) a creation-timestamp
       or `knk-domain-id` check on the existing region: a plugin change (L3 holds knk-plugin), filed as #1006 and
       reported to the coordinator (the prompt's "stop that part"); (c) an API record of a domain's earlier region:
       none exists, and adding one needs a migration (out of scope).
    2. *When to heal.* Chosen: only on a retry for a row already stored on its temp region. Alternatives: (a) on every
       finalize (the issue's wording): a first save would redefine any existing region carrying the row's name;
       (b) prefer the final name over a temp previous region on a real re-run: the plugin takes one replace target and
       the next retry heals anyway.
    3. *Guard.* Chosen: every other row kind names the final name → no replace (`OtherUserOfRegionAsync`, and
       `DomainRegionOwnership` plus the owned kinds for sub-regions). Alternative: (a) the re-run path's
       `RegionHolderAsync` (production areas never hold): too loose for a region that is not yet the row's.
    4. *Seed v3 GUIDs.* Chosen: the seeds README rule (configuration uuid5(v2, "seed-v3"), every step/field uuid5(v2,
       its v2 GUID), as GateDoor v2 → v3), so the condition reads v3's own AreaKind field `44a1e7e9-…` (derived from
       v2's `11b2f868-…` named in the prompt; the importer requires the condition's field to be in the same file).
       Alternative: (a) keep the v2 GUIDs: against the convention, duplicates GUIDs across configurations.
    5. *Pinned tests.* Chosen: change the three tests that pinned "no replace on a retry", the behaviour #952 changes.
       Alternative: (a) keep them by healing only in a new code path: two retry behaviours for one state.
    6. *Warp step (#1003).* Chosen: A17 as written (coordinator decision 16), stated in #85, #1007 and on #1003 with the
       one-edit reversal. Alternative: (a) unconditional warp step: waits for the developer.
6. **Out of scope, noted.**
    1. #1006 (filed): heal `domain_<id>` too, with a plugin check of the existing region first.
    2. A redefined sub-region that the mirror had already marked orphaned (`knk-orphaned-since`) keeps its flags; the
       plugin's orphan handling is expected to clear the mark once the sub-region is listed again. Not verified (no
       plugin run); smoke guide § 5 covers a lootbox area only by hand.
7. **Blockers.** None. The `domain_<id>` part stopped by design (decision 1), as the prompt asked.
8. **At merge / what the developer must do.**
    1. Import the `Landmark` form seed v3 and make it the default (v2 need not be imported).
    2. Answer #1003's warp question; if a point landmark keeps its warp, one seed edit (and the same in the form
       designer) makes "Warp destination" unconditional, then #1003 can close.
    3. Decide on #1006 (the `domain_<id>` heal with a plugin check).
    4. Run smoke guide § 5 when convenient (tier:2; steps 1–3 need a stopped game server between drawing and saving).
9. **Notes for later links.**
    1. L3 (#985) and #1006: the API already sends `replaceRegionId` equal to the target for these owners on a retry;
       a plugin check of the existing region (decision 1 (b)) would make the domain heal safe.

### 4.6 L3b — NPC replay fails at scene origin x ≥ 32752 (#958)

1. **Scope done.**
    1. Root cause: a double has one bit less for the fraction from x 32768 (2^15) on. The replay's road runs along the
       block face x 1412 (real). Real x 1407…1418 lies below 32768 in a scene from 32740 and at or above it in one
       from 32752. So after the real-to-scene move, those line points rounded to the other side of the face, and the
       corridor shaper made a different stretch there (1411.53 115 −531.84 against 1412.0 115 −532.0). Everywhere
       else both scenes are in the same range and the line is bit-identical after the move, hence the sharp
       threshold. Found by logging every waypoint list handed to Citizens and every stage of `RouteFollower.next` at
       both origins:
        1. The road lines differ only in the last bits.
        2. The block centres are identical, and the shaper's output is the first real difference.
        3. Each stage gives the same result on an exactly translated input.
        4. So it is not the plugin's coordinate keys, Citizens, chunk loading or the group code.
        5. L3's "leader alone identical" held for the outcome; its waypoints already differed.
    2. knk-plugin `core/npc/nav/RouteFollower`: the road line and the resampled line on a grid of 1/4096 block
       (`LINE_GRID`), exact as a double anywhere within the world border. The replay's 1449 waypoint lists are
       identical at origin 32740 and 32752.
    3. knk-plugin `core/npc/nav/group/NavGroup`: with exact arcs, `NavGroupFinishTripTest` showed an existing gap. A
       follower held behind another at a closed gate ended its own leg back (rejoin) on the spot of the follower ahead.
       Before, rounding made it overshoot into the door's margin, where `backOutOf` queued it; it still ended 0.1 from
       that follower, and the test passed by timing. The follower now keeps the index its last hand-out stopped
       before (`cutIdx`, set in `send` and `backOutOf`), and a queued follower's rejoin target stops a queue's length
       before it.
    4. knk-plugin scenario `npc-replay-quarry-to-keep-past-32768` (`NpcSnapshotReplayScenario.pastTheBinade()`): the
       replay with the snapshot's settings in a scene at world x 32768 or beyond. Its first check fails further west,
       so it has to be registered from the 45th scenario on. It runs in about 3.5 minutes. `PaperScenariosTest`,
       `MIN_SCENARIOS` 80. The comment "new scenarios go after the NPC replays" in `PaperScenarios` is removed
       (prompt § 2.3, proof in item 4.3).
    5. knk-workspace: changelog entry (no admin steps); `guides/developer/plugin-scenarios.md` § 1 item 6 (scene order
       no longer matters) and item 14 (the new scenario); `guides/developer/ci.md` § 7 and § 7.1 (paper-boot waits
       2400 s, job timeout 50 minutes, about 32 minutes for 80 scenarios).
    6. knk-plugin `.github/workflows/paper-boot.yml`: `MIN_SCENARIOS` 80, `--expect-timeout` 2400, `timeout-minutes` 50.
2. **Commits and heads.**
    1. knk-plugin `claude/npc-replay-958` at `a888d8c6` (4 commits: `a5e5cf24` grid, `92c4bd6c` group queue,
       `97350ce7` scenario, `a888d8c6` paper-boot timeout; base `next` `14645895`, which did not move).
    2. knk-workspace `claude/npc-replay-958` at `a340f689` (`3baaaea5` docs, a merge of `origin/next` `d8eac5f2`,
       `a340f689` CI guide; base `next`).
3. **PRs.** [knk-plugin#126](https://github.com/PandiO/knk-plugin/pull/126) (`Closes PandiO/knk-workspace#958`),
   [knk-workspace#1018](https://github.com/PandiO/knk-workspace/pull/1018) (`Part of #958`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer`: baseline on `next` `14645895`: knk-core 3809, knk-api-client
       430 (2 skipped), knk-paper 3496 (18 skipped), 0 failures. Branch: knk-core 3813 (+4 `RouteFollowerGridTest`),
       knk-api-client 430, knk-paper 3496, 0 failures. CI on #126: the first run on `97350ce7` passed 79 scenarios and ran out of the 1800 s wait during the 80th
       (the new check); with `--expect-timeout 2400` and a 50-minute job (`a888d8c6`) build and paper-boot are green
       on `a888d8c6` (both runs, 80 scenarios).
    2. Fails before the fix:
        1. `RouteFollowerGridTest`: 3 of 4 fail without the grid.
        2. `npc-replay-quarry-to-keep-past-32768` alone at origin 35056 (its CI position) without the grid: FAIL,
           "falls from the climb 17: knk-sc-0 from 1424 49 -515 to 1429 46 -516 …", as on #115. With the grid:
           PASS (4151 ticks).
    3. Local paper-boot (the pinned Paper 26.3-205, WorldEdit 7.4.6, WorldGuard 7.0.20, Citizens b4269):
        1. `npc-replay-quarry-to-keep` alone at origin 32740 and 32752 before the fix: PASS and FAIL. After the fix
           both PASS with identical reports.
        2. The final code with three empty scenarios registered before all others (the replay at scene 44, where it
           failed): 83 of 83 passed (replay 7261 ticks).
    4. Known reds: none.
    5. Codex: at its usage limit on both PRs (review failed, no findings); finished without it, said so on both PRs.
5. **Decisions (DESIGN § 4.3).**
    1. *Where to fix.* Chosen: the route line in `RouteFollower` (`core/npc/nav`), the input every NPC stretch is built
       from; outside `core/navigation/` and outside the lines of knk-plugin #116 to #119 (none of them touches
       `RouteFollower`, `NavGroup` or `NpcSnapshotReplayScenario`). Alternatives: (a) make the corridor shaper's face
       and tie decisions tolerant: in `core/navigation/` (prompt § 3.3), and a tolerance moves the problem rather
       than removing it; (b) snap only the input road line: resampled points (a + d·t) round at their own magnitude
       again; (c) place the scenario's scene elsewhere: hides the bug for real routes.
    2. *Grid size.* Chosen: 1/4096 block (12 fraction bits plus 25 for 30,000,000 fit a double's 53). Alternatives:
       (a) 1/1024: coarser than needed; (b) 1/65536: exact as well, no benefit.
    3. *Group queue gap.* Chosen: cap a queued follower's rejoin target at its place in the queue (a fix inside this
       link, since the grid turned `NavGroupFinishTripTest` red and the test detects a real pile-up). Alternatives:
       (a) step a still follower back out of its queue gap every tick: broke two `NavGroupTest` cases (stuck spells,
       an outside follower at the edge); (b) change or loosen the test: it caught a real pile-up; (c) leave it red
       as a blocker: the fix is small and covered by the existing tests.
    4. *Check scenario.* Chosen: a second registration of the replay with the snapshot's settings only, checking its
       own scene position. Alternatives: (a) both configurations: about 3.5 more minutes of CI for walks that never
       failed; (b) move the existing replay to a later index: depends on registration order, the rule being removed.
6. **Out of scope, noted.**
    1. Local paper-boot in this environment: Citizens b4269 downloads its Adventure libraries at startup with libby,
       and that download fails inside the server here (the same URLs work from a plain JVM). Worked around by
       pre-filling `plugins/Citizens/lib` with libby run outside the server. CI is not affected. Not filed (an
       environment matter, not a plugin bug).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing beyond merging (no config key, no migration). CI's paper-boot runs one more scenario (about 3.5
       minutes) and now takes about 32 minutes in a 50-minute job.
9. **Notes for later links.**
    1. A scenario can be registered anywhere in `PaperScenarios` again.
    2. Plugin code that decides by comparing a coordinate with a block face or a tie should get its inputs from
       `RouteFollower.line()` (on the grid), not from raw road points.
    3. The knk-workspace merge commit `96e1e803` has git's default message without the commit trailers (pushed
       before I noticed; no force-push).

### 4.7 L4b — warp step for every area kind (seed v4) and off-road smoke §§ 6–7 superseded (#1003, #1009)

_Written by the coordinator from the subagent's final report (2026-11-24); the subagent did not edit this file._

1. **Scope done.**
    1. knk-web-api: Landmark form seed v4 ("Landmark - Default (seed v4)", `configurationGuid`
       `0e58df82-02fb-59c1-9969-5a0a6ce15194` = uuid5(v3, "seed-v4"), steps and fields uuid5(v3, their v3 GUID)): v3
       without the "Warp destination" step's display condition (LD26); seeds README v4 paragraph and table row; seed
       tests pin v4; new `LandmarkDomainIntegrationTests.APointLandmark_AndALinkedOne_WithTheirWarpOn_AreDestinations_AtTheirPins`.
       No migration, no API code change.
    2. knk-web-app: the A17 e2e test and its mocked form follow seed v4 (renamed "shows the region, access and
       sub-region steps only with Own region, and the warp step for every area (A17, LD26)").
    3. knk-workspace: DESIGN LD26, A17 and § 4.1 item 5; smoke guide seed v4 (§ 1.0, § 1 steps 2–3, § 4.0, § 4 steps
       1 and 4, § 5 step 5) and new § 5 step 6 (a point and a linked landmark as warp destinations); new § 3.2 "Carried
       over from the off-road guide" (27 steps); `navigation-offroad-smoke-test.md` § 6 (6.0–6.5) and § 7 (7.0, 7.1)
       superseded with the step mapping, headings and numbers kept; changelog block with the deploy note.
2. **Commits and heads.** knk-web-api `claude/landmark-warp-step-1003` `a65baee9` (base `next` `3bc3cfd5`); knk-web-app
   `claude/landmark-warp-step-1003` `f1d5491e` (base `8c9c355`); knk-workspace `claude/landmark-domain-l4b` `0a0d74bd`
   (base `baf9ef74`). `next` did not move during the link.
3. **PRs.** PandiO/knk-web-api#86 (`Closes #1003`), PandiO/knk-web-app#79 (`Part of #1003`),
   PandiO/knk-workspace#1016 (`Closes #1009`, `Part of #1003`); merged into `next` by the coordinator.
4. **Tests, baseline → result.**
    1. knk-web-api: build 0 → 0 errors; 5344 → 5345 passed, 131 skipped (MySQL, run in CI), 0 failed. The renamed
       seed tests fail against v3 and pass against v4.
    2. knk-web-app: Jest 2951 → 2951; tsc 0 → 0; build passed; typecheck:e2e passed; Playwright 382 → 382 (one test
       renamed; it fails against the old mock).
    3. knk-workspace: link check over the changed docs, 0 broken (CHANGELOG and `plugin-configuration.md` anchors
       into the off-road headings included); every test named in § 3.2 exists on `next`.
    4. Known reds: the pull-request run's mysql-tests failed once in
       `DiscoveryLedgerMySqlTests.TitleCrossing_PostsTheXpOnceAndAppliesTheBonusOnce` (outside this change), green on
       the push run and the re-run; filed as flaky #1017.
    5. Codex: usage limit on all three PRs; finished without it, said so on each.
5. **Decisions (DESIGN § 4.3).**
    1. *Extra API test for LD26.* Chosen: a warp-destination test for a point and a linked landmark, since the seed
       only shows the step. Alternatives: (a) seed test only; (b) a plugin test, out of the link's repos (covered by
       `WarpTargetsTest`).
    2. *README table.* Chosen: a one-row table under the v4 paragraph, as other v3 entries have. Alternative: (a)
       paragraph only.
    3. *Where carried-over steps go.* Chosen: one § 3.2 inside § 3. Alternatives: (a) spread into §§ 1, 2, 4 (splits
       the mapping, renumbers cited steps); (b) a new top-level section (against "§ 3").
    4. *What counts as covered.* Chosen: drop an old step only when §§ 1–5 check the same behaviour on the new model or
       the behaviour is gone (radius, `landmark_<id>`, `AddLandmarks`); partly covered steps keep their uncovered half.
       Alternative: (a) carry every step (duplicates).
    5. *Off-road headings.* Chosen: keep every heading (6.0–6.5, 7.0, 7.1) with a mapping list, because other docs link
       them. Alternative: (a) one note per top-level section (breaks the § 6.3 links).
    6. *New smoke § 5 step 6.* Chosen, because LD26 is player-visible and the other steps test warps only on own
       regions. Alternative: (a) change only the expected form steps.
6. **Out of scope, noted.** #1017 (flaky MySQL test, filed). Docs follow-ups added to #1010: the landmarks admin guide
   and `guides/README.md` still name seed v3 and "Warp destination (Own region)"; the `navigation.landmarks` row of
   `plugin-configuration.md` points to off-road § 6.3 instead of landmark-domain § 3.
7. **Blockers.** None.
8. **At merge / what the developer must do.** Import "Landmark - Default (seed v4)" and make it the default (v3 need
   not be imported; if it was, switch it off as default); smoke § 1 step 2, § 4 step 1, § 5 steps 5–6 and the by-hand
   parts of § 3.2.
9. **Notes for later links.** None.
