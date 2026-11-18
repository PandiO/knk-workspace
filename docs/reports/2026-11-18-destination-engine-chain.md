# Navigation destination engine chain — progress report

**Status:** Running (2026-11-18) · **Last updated:** 2026-11-18

**Issue:** [PandiO/knk-workspace#25](https://github.com/PandiO/knk-workspace/issues/25), links
[#96](https://github.com/PandiO/knk-workspace/issues/96) (L1),
[#103](https://github.com/PandiO/knk-workspace/issues/103) (L2),
[#69](https://github.com/PandiO/knk-workspace/issues/69) (L3),
[#62](https://github.com/PandiO/knk-workspace/issues/62) (L4),
[#747](https://github.com/PandiO/knk-workspace/issues/747) (L5),
[#55](https://github.com/PandiO/knk-workspace/issues/55) (L6).
**Charter:** [handoffs/DESTINATION_ENGINE_CHAIN.md](../ai-agents/handoffs/DESTINATION_ENGINE_CHAIN.md).
**Coordinator:** session_01R1w2UvZSm3y5hAXB8VfYuv (cloud).

## 1. Waiting for the developer

1. Nothing yet. Later: the live test of smoke § 3 and § 4 with `navigation.destination-engine: true` once L3 and L4
   are in `next` (gate of L5), and the timing of L6 (arena duels, asked on #25 before it starts).

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 P1 pure engine in knk-core | #96 | Merged into next (2026-11-18) | `claude/navigation-destination-engine`: knk-plugin `64ca8815`, knk-workspace `7eb86cc3` | [knk-plugin#78](https://github.com/PandiO/knk-plugin/pull/78) (merge `1105ec15`), [knk-workspace#754](https://github.com/PandiO/knk-workspace/pull/754) (merge `732ba191`) | build + paper-boot green on the PR; Codex skipped (usage limit) | create_session session_01R1w2Uw3gPf2REJMYZEGE6a |
| L2 P2 model, snapshot, domain search Location | #103 | Running | `claude/navigation-destination-engine`: knk-web-api new, knk-plugin from `next` `1105ec15` | — | — | subagent of the coordinator (two repos besides knk-workspace, SKILL § 4.1.4 item 2) |
| L3 P3 switch-over behind the flag | #69 | Not started | — | — | — | — |
| L4 P4 hard blocks as scopes, live re-validation | #62 | Not started | — | — | — | — |
| L5 phase 4b removal of old paths and the flag | #747 | Not started | — | — | — | — |
| L6 P5 arena duels provider and scope | #55 | Not started | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from or merge in `next`, PRs target `next`, the
   coordinator merges into `next`), because `.github/workflows/ci.yml` is on `origin/main` of both knk-web-api and
   knk-web-app (checked 2026-11-18). Alternatives: (a) old rules (developer merges) — not applicable once CI runs.
2. **Gate of L1.** Open: DESIGN on knk-workspace `next` has status "Decided 2026-11-18"; knk-plugin
   `claude/navigation-destination-engine` is at `ea368a8b` as the charter says (1 commit ahead of `next` `7f4bdd3a`,
   369 behind). Alternatives: none.
3. **Overlap check before L1 (charter § 2.2, § 2.3).** Board read fresh from `origin/main` 2026-11-18. Chosen: start
   L1 now. The off-road chain (#698) has no link running (its row: "Waiting for the developer", L8 waits for #96, #103,
   #69), and L1 only changes knk-core destination-engine code. The overview map chain (#732) has L3/L4 running in
   knk-plugin map reporting, not navigation; no shared lines. The NPC navigation follow-ups chain (#358) is in review
   with no link running. Order agreed by message with the off-road coordinator (session_01R1w2UuBBnWjqekMFxEMefN).
   Alternatives: (a) wait for the off-road live tests — not needed, no off-road link runs; (b) run L1 as a subagent —
   not needed, L1 needs only knk-plugin besides knk-workspace.
4. **Route for L1.** Chosen: create_session with variant A of the permissions block, because L1 needs one repository
   besides knk-workspace (SKILL § 4.1.4 item 2). Alternatives: (a) subagent (variant B) — the fallback if `add_repo` is
   refused.
5. **Parallel L2 API part.** Chosen: not yet; L2 starts as one link (API and plugin) after L1 is merged, because
   knk-web-api work is small (a DTO field and an `Include`) and one link per issue keeps the check simple.
   Alternatives: (a) start the knk-web-api part now as a separate session, which the charter allows — revisit if L1
   runs long.

6. **L1 check (2026-11-18).** Chosen: merge knk-plugin#78 into `next` (merge `1105ec15`) after the § 6 checks: heads
   match, `next` moved by two overview-map commits during the link but `git merge-tree` showed no conflict and the
   files do not overlap, PR CI `build` and `paper-boot` green, scope only `core/navigation/destinations/` and
   `ArchitectureGuardTest`, knk-core 3 151 → 3 221 with 0 failures, decisions logged, Codex at its usage limit (rule 4
   exception, noted on the PR). knk-workspace#754 was sent back once for a missing changelog entry (the other chains'
   links ship one with the feature), then merged (`732ba191`). Alternatives: (a) merge #754 without the entry and add
   it at the end of the chain — rejected, the global rules ship the changelog entry with the feature; (b) write the
   entry myself — rejected, the coordinator does not implement and the link session was idle with full context.
7. **Order with the off-road chain (2026-11-18, by message with session_01R1w2UuBBnWjqekMFxEMefN).** Chosen: L1 then
   L2 run now; when an off-road link (L10 step 2 on #712 or L5 #705) becomes ready, it gets the window after L2 and
   before L3, and I hold L3 until it is merged into `next`. I tell that coordinator when L2 and when L3 are merged (L3
   opens its L8 #708). Alternatives: (a) run L1–L3 back to back first — delays off-road work that waits only on the
   developer; (b) let the off-road links go before L2 — neither was ready.
8. **Route for L2.** Chosen: a subagent of this session (variant B), because L2 changes two repositories besides
   knk-workspace (SKILL § 4.1.4 item 2). Scope follows the charter and DESIGN § 10 over the October text of #103:
   the providers reading the model (`CatalogueProvider`, `CompassTargetsProvider`) belong to L3. Alternatives: (a)
   create_session with two `add_repo` calls — refused attaches were seen with several repos; (b) split L2 into an API
   and a plugin session — the API part is small and one link per issue keeps the check simple.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — P1 pure engine in knk-core (#96)

1. **Scope done.**
    1. knk-plugin: the October P1 branch reused (E14); `origin/next` `7f4bdd3a` merged in (merge `295ea235`); the one
       conflict in `ArchitectureGuardTest` keeps both `onlyTheDestinationEngineConstructsAllowedDestination` and
       `sharedShapingPackageDoesNotUseNpcPackages`; nothing else conflicted.
    2. knk-plugin `core/navigation/destinations` (commit `64ca8815`), the deltas of DESIGN § 10.2.4: new `Reason(code,
       text)` on `Scope.Empty`, `Listed.reasonWhenEmpty`, `DestinationList`, `Resolution` and `Revalidation` (E15);
       codes `loading`, `frozen`, `no-permission`, `siege-compass-off`, `siege-match-empty`, `siege-lobby` and the
       engine's `no-longer-listed`; scope 55 with today's "This match has no destinations to navigate to."; scope 60
       empty gives the same text under `siege-match-empty`; `Place.Point.arrivalRadius` (E16) and the `landmark:<id>`
       key documented; no list cache (E18), documented and tested.
    3. New tests: `ReasonTest` (4), `LandmarkLikeProviderTest` (7, the § 3.2 provider: listed in World, hidden by every
       exclusive scope, listed for the bypass, other world resolved apart, rename keeps the session), arrival radius in
       `CandidateTest`, codes/texts/no-cache in `InitialScopesTest` and `DestinationEngineTest`.
    4. knk-workspace (`55c4fb13`): smoke guide § 1 rewritten to what was built, 9 of 11 steps tagged; DESIGN § 10.2
       item 7 (what was applied, for P3/P4).
    5. Nothing wired into the plugin: no behaviour change, no config key, no migration. No file outside
       `core/navigation/destinations/` and `ArchitectureGuardTest` changed in knk-plugin.
2. **Commits and heads.** knk-plugin `claude/navigation-destination-engine` at `64ca8815` (3 commits over `next`:
   `ea368a8b`, merge `295ea235`, `64ca8815`; base `next` at `7f4bdd3a`). knk-workspace
   `claude/navigation-destination-engine` at `55c4fb13` (1 commit, base `next` at the time of branching, 0 behind).
3. **PRs.** [PandiO/knk-plugin#78](https://github.com/PandiO/knk-plugin/pull/78) (`Closes PandiO/knk-workspace#96`),
   [PandiO/knk-workspace#754](https://github.com/PandiO/knk-workspace/pull/754) (`Part of`), both base `next`. Not
   merged.
4. **Tests, baseline → result.**
    1. knk-plugin `./gradlew build -x deployToDevServer` (JDK 21 Gradle, JDK 25 toolchain): baseline on `next`
       `7f4bdd3a` knk-core 3 151, knk-api-client 344 (2 skipped), knk-paper 2 957 (18 skipped), 0 failures; branch
       knk-core 3 221 (+70: 69 engine tests, 1 architecture rule), knk-api-client 344 (2 skipped), knk-paper 2 957
       (18 skipped), 0 failures. PR CI: `build` green; `paper-boot` was still running when this block was written.
    2. Known reds: none.
    3. Codex: at its code-review usage limit on both PRs (its comment on #78 and #754); skipped under global
       "Branches" rule 4's usage-limit exception, said on both PRs. No findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *Compass item vs. siege switch (§ 10.2.4 item 2).* Chosen: one `Siege.compassEnabled`, documented as
       `item().enabled() && siegeEnabled()` and built by the P3 adapter, because the two only ever matter together.
       Alternatives: (a) a second `compassItemEnabled` field: more fields for the same rule.
    2. *Empty match list.* Chosen: scope 60 refuses with `siege-match-empty` and today's text, matching today's
       `/navigate`. Alternatives: (a) no reason, as in October: the adapter would invent the text; (b) reuse
       `siege-compass-off`: the compass words the cases differently.
    3. *Reason on the API.* Chosen: `Reason` replaces the `String` reason everywhere. Alternatives: (a) a parallel code
       field: two fields that can disagree.
    4. *Arrival radius.* Chosen: nullable `Double` on `Place.Point`, positive and finite, 4-argument constructor kept.
       Alternatives: (a) a separate `Place.Area`: every `Point` consumer needs a second case.
    5. *Cache (E18).* Chosen: no cache in P1; a model-backed cache belongs with the model (P2/P3). Alternatives: (a) a
       cache keyed by (scope, world, modelVersion) now: nothing model-backed exists yet to cache.
6. **Out of scope, noted.** None.
7. **Blockers.** None.
8. **At merge / what the developer must do.** Nothing beyond merging: no config key, no migration. Changelog entry and
   the `documentation` sub-issue at the merge into `next` (the coordinator's step). Smoke § 1 steps 10 and 11 (nothing
   changed) are manual.
9. **Notes for later links.**
    1. P3 adapters: switch on `Reason.code()`, not the text; the compass maps `siege-lobby` to "works once the siege
       match has started." and `siege-compass-off` to "switched off during sieges."; build `Siege.compassEnabled`
       from the item rule and `siegeEnabled`.
    2. `Revalidation.reason()` is a `Reason` too (`no-longer-listed` for a dropped key) for P4's
       `DESTINATION_NOT_ALLOWED`.
    3. Off-road L8 (#708): `LandmarkLikeProviderTest` is the contract; register the provider as one more World
       provider in `InitialScopes.create`, use `Place.Point(..., radius)` or `Place.Region`.
    4. Maven Central through the proxy: a Gradle init script putting `repo.papermc.io/repository/maven-public/` first
       (named repo moved to index 0) plus one `--refresh-dependencies` gave a clean build.
