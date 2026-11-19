# Overview map chain — progress report

**Status:** In review; F1 and F2 merged, dev smoke run passed (2026-11-19) · **Last updated:** 2026-11-19

**Issue:** [PandiO/knk-workspace#732](https://github.com/PandiO/knk-workspace/issues/732), links
[#735](https://github.com/PandiO/knk-workspace/issues/735) (L1), [#736](https://github.com/PandiO/knk-workspace/issues/736) (L2),
[#737](https://github.com/PandiO/knk-workspace/issues/737) (L3), [#738](https://github.com/PandiO/knk-workspace/issues/738) (L4),
[#739](https://github.com/PandiO/knk-workspace/issues/739) (L5), [#740](https://github.com/PandiO/knk-workspace/issues/740) (L6),
[#741](https://github.com/PandiO/knk-workspace/issues/741) (L7), [#742](https://github.com/PandiO/knk-workspace/issues/742) (L8),
[#743](https://github.com/PandiO/knk-workspace/issues/743) (L9)
**Charter:** [handoffs/OVERVIEW_MAP_CHAIN.md](../ai-agents/handoffs/OVERVIEW_MAP_CHAIN.md).
**Spec:** [specs/in-game-maps/OVERVIEW_MAP_DESIGN.md](https://github.com/PandiO/knk-workspace/blob/next/docs/specs/in-game-maps/OVERVIEW_MAP_DESIGN.md)
on `next` (Decided 2026-11-18, O01–O33, O08 superseded by O31); smoke guide
[guides/overview-map-smoke-test.md](https://github.com/PandiO/knk-workspace/blob/next/docs/guides/overview-map-smoke-test.md) on `next`.

## 1. Waiting for the developer

1. **L1 (#735) smoke test (tier:3):** L1 is in `next` (knk-web-api `562f504`, knk-plugin `7f4bdd3a`). Deploy the API
   from `next` and apply the migration `AddMapRegionOutlines` (additive); deploy the plugin from `next`, paste
   `map:` / `reporting:` / `enabled: true` into `config.yml` (needs `realtime.enabled: true`) and follow smoke guide § 1
   (manual parts of steps 1–7). Optional: `@codex review` on knk-web-api#45, knk-plugin#76, knk-workspace#749 (Codex
   was at its usage limit).
2. **L2 (#736) smoke test (tier:3):** L2 is in `next` (knk-web-api `612ad62`). With the API from `next`, set
   `Map__Enabled=true` and follow smoke guide § 2 (new settings with defaults in production-installation § 4.3; no
   migration). Optional: `@codex review` on knk-web-api#46 and knk-workspace#751 (Codex at its limit / failed).
3. **L3 (#737) NAS steps and smoke test (tier:2):** L3 is in `next` (knk-web-app `f551804d`). The BlueMap spike
   passed (v5.29, evidence on #737). **Runbook Phase 10 applied on the NAS 2026-11-18** by the developer (steps 1–3, 5–8):
   `bluemap` service in the `knk-alpha` stack (profile-gated), `webapp.conf` bridge script and `client-decompression`,
   web image `knk-web-app:alpha-909e7089-bluemap` (the running alpha revision plus only the `location /bluemap/`
   block, so no unpromoted code reached the alpha), web files written with `bluemap -g`; `/bluemap/` loads through
   Cloudflare Access. The **full-world render (steps 4 and 9) is skipped by the developer's decision**: only the
   already rendered area is used now and in the near future, and the render mask stays. `/bluemap` without the
   trailing slash falls through to the web app's 404 (redirect not added yet). The `bridge.js` 404 in the viewer's
   console is expected until `next` is promoted. Remaining: after the promotion, set `Map__Enabled=true` and follow
   smoke guide § 3. Optional: `@codex review` on knk-web-app#50 (Codex at its limit).
4. **L4 (#738) live check: done 2026-11-18** (comment on #738: steps 2, 3 and 5 pass; step 3's `/ownermode` part not
   run, no second staff account). L5 is merged. Remaining for L4/L5: the `mode: "owner"` case when a second staff
   account is at hand, and smoke guide § 5 once the map is live (§ 3).
5. **L6 (#740) smoke test (tier:2):** L6 is in `next` (knk-web-app `01ad4d9a`). With the map on (§ 3), run smoke guide
   § 6. Towns and districts have no seeded default display configuration: until one is made in the display builder,
   their "Details" shows a one-line message. Optional: `@codex review` on knk-web-app#51, knk-workspace#755.

6. **L7 (#741) smoke test (tier:3):** L7 is in `next` (knk-web-api `0308377d`, knk-plugin `02aa110e`). Set
   `Map__GateCommands__Enabled=true`, deploy the plugin from `next` connected to the hub and follow smoke guide § 7
   (10 steps: 4 automated, 6 partly automated). No migration, no plugin setting.

7. **L8 (#742) smoke test (tier:2):** L8 is in `next` (knk-web-app `de43f6be`). After § 3 and § 7 are deployed, run
   smoke guide § 8 (9 steps: 3 automated, 6 partly automated) as a `knk.gate.admin` holder.

8. **L9 (#743) smoke test (tier:2):** L9 is in `next` (knk-web-app `eff6ed98`). With the live players layer on (§ 5),
   run smoke guide § 9 with moderators holding different nodes. Decide whether a kick-only moderator should see
   "Open profile" (it ends on the profile page's no-access answer; A20 asks for the link).
9. **Chain finished; promotion of `next` is yours.** All nine links are in `next` (knk-web-api `6094276`, knk-plugin
   `3e04ba8f`, knk-web-app `eff6ed9`, knk-workspace `8328c9da`). Docs follow-up: #766, docs session
   `session_01R1w2UuMzfZ1Z1FB7pV7iXR`; its player and admin guide items gate a deploy to knk-alpha. #732 and its
   sub-issues stay open (`status:in-review`) until you promote `next`.
10. **Fix links F1 and F2 merged into `next` (2026-11-19, on your go).** F1 (#750, knk-plugin `c0ca56e4`: sub-region
    outlines reported after the access sync) and F2 (#757 Escape in the map frame, #809 "Open profile" disabled with a
    tooltip; knk-web-app `ee73be3f`). Your smoke steps: § 1 step 8, § 3 step 4, § 5 step 7, § 9 steps 1, 3 and 4. No
    config key, setting or migration. Known limit (F1): a sub-region that is deleted is not reported as removed, so
    its outline stays on the map until the next full outline report of that domain. #772 (direct `/bluemap` visits
    go to `/map`, relative redirects) is merged into `next` (`8487a058`): rebuild the alpha `web` image with its
    `nginx.conf` together with the promotion, not before.
11. **Dev smoke run 2026-11-19 (yours): passed** §§ 1 (incl. step 8, F1), 3 steps 2–9 (incl. F2's Escape), 4, 5, 6
    and 9 on a local stack from `next`, with BlueMap's static `web/` copied into the web app's `public/bluemap/`. No
    findings in the code: the permanent district volumes were the spike's static `wg2bluemap` marker sets, now removed
    on the NAS (`config/maps/overworld.conf` block emptied, `web/.../live/markers.json` cleaned, backups kept). Ideas
    filed: #825 (hide or group dots when zoomed out), #826 (town region drawn like the spike's markers). Details on
    #732.
12. **NAS BlueMap settings applied 2026-11-19 (yours):** player skins from mc-heads.net (your choice:
    `&heads=https://mc-heads.net/avatar/{uuid}/16` on the bridge line of `config/webapp.conf`, then `bluemap -g`;
    every viewer's browser asks that service for the heads) and the start position over Cinix (`start-pos: { x: 1408,
    z: -522 }` in `config/maps/overworld.conf` and `"startPos":[1408,-522]` in `web/maps/overworld/settings.json`).
    Backups `*.bak-heads-*` and `*.bak-startpos-*` next to the files. Both show on the alpha after the promotion.
13. **Still open for you:** § 3 step 1 on the NAS after the promotion (rebuild the `web` image with the `next`
    `nginx.conf`), the `/ownermode` case of the L4 check (a second staff account), and when to promote `next`.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Region outlines | #735 | Merged into `next` 2026-11-18 (knk-web-api `562f504`, knk-plugin `7f4bdd3a`, knk-workspace `ac4b620f`); waiting for the developer's smoke test § 1 | `claude/overview-map-outlines`: knk-web-api `253a6ee`, knk-plugin `cf3a975a`, knk-workspace `e6e815dd` (from `next`) | [knk-web-api#45](https://github.com/PandiO/knk-web-api/pull/45), [knk-plugin#76](https://github.com/PandiO/knk-plugin/pull/76), [knk-workspace#749](https://github.com/PandiO/knk-workspace/pull/749) | API green; plugin build and paper-boot green | create_session session_01R1w2UuqJyStWv2zia5FTQg (2026-11-18, decision 3) |
| L2 Public map API | #736 | Merged into `next` 2026-11-18 (knk-web-api `612ad62`, knk-workspace `55d01897`); waiting for the developer's smoke test § 2 | `claude/overview-map-public-api`: knk-web-api `3a014f8`, knk-workspace `fcde4be8` (from `next`) | [knk-web-api#46](https://github.com/PandiO/knk-web-api/pull/46), [knk-workspace#751](https://github.com/PandiO/knk-workspace/pull/751) | API green on `3a014f8` (build-and-test, mysql-tests, fresh-database); knk-workspace no CI | create_session session_01R1w2UvvpPXaMVExy9eZZpL (2026-11-18) |
| L3 `/map` page | #737 | Merged into `next` 2026-11-18 (knk-web-app `f551804d`, knk-workspace `0f0f8e7f`); waiting for the NAS deploy notes (runbook Phase 10), the full-world render and the developer's smoke test § 3 | `claude/overview-map-page`: knk-web-app `ee9a68d`, knk-workspace `23b028dc` (from `next`) | [knk-web-app#50](https://github.com/PandiO/knk-web-app/pull/50), [knk-workspace#753](https://github.com/PandiO/knk-workspace/pull/753) | web app green on `ee9a68d` (build-and-test, e2e); knk-workspace no CI | create_session session_01R1w2UtuNmGWaJ6a65D2YeS (2026-11-18) |
| L4 Live players backend | #738 | Merged into `next` 2026-11-18 (knk-web-api `f2f523c3`, knk-plugin `ef4e99d9`, knk-workspace `d9c07b37`); waiting for the developer's live check of smoke § 4.1 steps 2, 3 and 5 on #738 (gates L5's merge) | `claude/overview-map-players-api`: knk-web-api `a9ed3af`, knk-plugin `8b1efdcc`, knk-workspace `09982caa` (from `next`) | [knk-web-api#47](https://github.com/PandiO/knk-web-api/pull/47), [knk-plugin#77](https://github.com/PandiO/knk-plugin/pull/77), [knk-workspace#752](https://github.com/PandiO/knk-workspace/pull/752) | API green (build-and-test, mysql-tests, fresh-database); plugin build and paper-boot green | create_session session_01R1w2UwcYKiPMueCHWqsys4 (2026-11-18) |
| L5 Live players layer | #739 | Merged into `next` 2026-11-18 (knk-web-app `5501be96`, knk-workspace `f7ea5ed9`) after the developer's L4 check on #738; waiting for the developer's smoke test § 5 | `claude/overview-map-players-page`: knk-web-app `bc17a48`, knk-workspace `69244809` (from `next`) | [knk-web-app#52](https://github.com/PandiO/knk-web-app/pull/52), [knk-workspace#756](https://github.com/PandiO/knk-workspace/pull/756) | Web app green on `bc17a48` (build-and-test, e2e); knk-workspace no CI; Codex at its limit | create_session session_01R1w2UwXPWsCYjRUw6RoxVH (2026-11-18) |
| L6 Staff details | #740 | Merged into `next` 2026-11-18 (knk-web-app `01ad4d9a`, knk-workspace `a130f2d6`); waiting for the developer's smoke test § 6 | `claude/overview-map-staff-details`: knk-web-app `1443cf5`, knk-workspace `fe64919d` (from `next`) | [knk-web-app#51](https://github.com/PandiO/knk-web-app/pull/51), [knk-workspace#755](https://github.com/PandiO/knk-workspace/pull/755) | Web app green (build-and-test, e2e); Codex at its limit | subagent of the coordinator (2026-11-18; the create_session attempt session_01R1w2UuaEs6VbL7BVnR7ZTJ was refused the knk-web-app attach, decision 10) |
| L7 Gate commands backend | #741 | Merged into `next` 2026-11-18 (knk-web-api `0308377d`, knk-plugin `02aa110e`, knk-workspace `b7820e99`); waiting for the developer's smoke test § 7 | `claude/overview-map-gate-commands`: knk-web-api `16e4157`, knk-plugin `1f8bb3c7`, knk-workspace `8368b901` (from `next`) | [knk-web-api#48](https://github.com/PandiO/knk-web-api/pull/48), [knk-plugin#79](https://github.com/PandiO/knk-plugin/pull/79), [knk-workspace#758](https://github.com/PandiO/knk-workspace/pull/758) | API green (build-and-test, mysql-tests, fresh-database); plugin build and paper-boot green | create_session session_01R1w2UxDt6K1RcnDPPagNAN (2026-11-18) |
| L8 Gate command buttons | #742 | Merged into `next` 2026-11-18 (knk-web-app `de43f6be`, knk-workspace `bf28138d`); waiting for the developer's smoke test § 8 | `claude/overview-map-gate-buttons`: knk-web-app `05a30ea`, knk-workspace `9fad9531` (from `next`) | [knk-web-app#53](https://github.com/PandiO/knk-web-app/pull/53), [knk-workspace#759](https://github.com/PandiO/knk-workspace/pull/759) | Web app build-and-test green on `05a30ea`, e2e running at report time (local full run 176 passed); knk-workspace no CI; Codex at its limit | create_session session_01R1w2UvQqqmQ9NwMTQbq3Cb (2026-11-18) |
| L9 Player context panel | #743 | Merged into `next` 2026-11-18 (knk-web-app `eff6ed98`, knk-workspace `8328c9da`); waiting for the developer's smoke test § 9 | `claude/overview-map-moderation`: knk-web-app `1ff5418`, knk-workspace `553c751b` (from `next`) | [knk-web-app#55](https://github.com/PandiO/knk-web-app/pull/55), [knk-workspace#765](https://github.com/PandiO/knk-workspace/pull/765) | Web app push runs green on `1ff5418` (build-and-test, e2e), pull_request runs running at report time (local full run: Jest 2754, e2e 191 passed); knk-workspace no CI; Codex at its limit | create_session session_01R1w2Uw4EdZTG53RQ7gnyQ3 (2026-11-18) |
| F1 Sub-region outlines at startup | #750 | Merged into `next` 2026-11-19 (knk-plugin `c0ca56e4`, knk-workspace `7330f0b6`); waiting for smoke § 1 step 8 | `claude/overview-map-f1-subregions`: knk-plugin `23e71315`, knk-workspace `90c4eabb` (from `next`) | [knk-plugin#93](https://github.com/PandiO/knk-plugin/pull/93), [knk-workspace#811](https://github.com/PandiO/knk-workspace/pull/811) | build and paper-boot green on `23e71315`; tests 7078 → 7106 (14 new), 0 failed; Codex at its limit | create_session session_01R1w2Uvrr2qFRCUBSxjXe7Y (2026-11-19) |
| F2 Escape in the map frame, "Open profile" disabled | #757, #809 | Merged into `next` 2026-11-19 (knk-web-app `ee73be3f`, knk-workspace `ac437102`); waiting for smoke § 3 step 4, § 5 step 7, § 9 | `claude/overview-map-f2-panel-fixes`: knk-web-app `c1e4dc9`, knk-workspace `72714c17` (from `next`) | [knk-web-app#59](https://github.com/PandiO/knk-web-app/pull/59), [knk-workspace#812](https://github.com/PandiO/knk-workspace/pull/812) | build-and-test and e2e green on `c1e4dc9`; Jest 2787 → 2791, 44 map e2e specs pass; Codex at its limit | create_session session_01R1w2UuSPaZGzxZKERwXfh3 (2026-11-19) |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from `next`, PRs target `next`, the coordinator merges
   into `next`), because on 2026-11-18 `.github/workflows/ci.yml` exists on `origin/main` of both knk-web-api and
   knk-web-app (skill § 1.3). Bases at the first run: knk-plugin `next` `1f414d08`, knk-web-api `next` `8ec54e1`,
   knk-web-app `next` `e7c9265`, knk-workspace `next` `afc4e09b`. Alternatives: (a) the old rules (default branch, the
   developer merges): not applicable once CI runs on both default branches.
2. **Overlap check for L1** (sessions board read from `origin/main` `145fadbb`, 2026-11-18). Chosen: no blocking
   overlap; L1 starts now. No "In progress" row has a running link in L1's areas: the off-road navigation chain (#698)
   has no link running and works in `core/roads/`, `core/navigation/`; the NPC follow-ups chain (#358) and chain 3
   follow-ups (#564) are in review, already merged into `next` (their region work, `TempRegionRetentionTask`,
   `WgRegionIdTaskHandler`, is in L1's base); the dashboard tables row (#608) waits for the developer's OK before
   building. Shared files L1 will touch additively: knk-plugin `KnKPlugin.java` (wiring), `config.yml` (new `map:`
   block), `plugin.yml` only if needed, the managed-region reconciler and `WorldGuardRegionRenamer` (one call each to
   report outlines); knk-web-api `Properties/KnKDbContext.cs` (one `DbSet` and its configuration), the game hub (one
   method), DI registration. L1 is told to keep to new files plus these additive hooks. The siege weapons design
   (#354 / #613) will reuse L3's bridge script later; that is not a file overlap now. Alternatives: (a) wait for the
   in-review chains to be promoted: no reason, their changes are already in `next`; (b) treat the shared hot files
   as a block: not needed, the edits are additive (developer decision 2026-11-12).
3. **Route for L1.** Chosen: `create_session` (knk-workspace source, Auto mode, same model as the coordinator), as the
   developer asked in the coordinator prompt; fallback a subagent of this coordinator with the same prompt (variant B)
   if the link's `add_repo` for knk-plugin or knk-web-api is refused or its dry run fails. Alternatives: (a) a subagent
   from the start, which skill § 4.1.4.2 suggests for links needing two repositories besides knk-workspace: the
   developer's own instruction takes precedence (skill § 1.1); (b) a session without Auto mode: it would ask the
   developer before other tool calls.

4. **L1 check and merge (2026-11-18).** Chosen: merge knk-web-api#45, knk-plugin#76 and knk-workspace#749 into `next`
   with merge commits (API first, the schema), because every check in skill § 6 held: heads matched, branches
   contained `next`, scope limited to the sub-issue (new files plus additive hooks), CI green on both code PRs
   (API build-and-test, mysql-tests, fresh-database; plugin build, paper-boot), tests above baseline, flag off by
   default, decisions logged, smoke § 1 tagged, #735 `status:in-review`. Codex was at its usage limit on all three PRs
   (noted on each; developer decision 2026-11-14). Alternatives: (a) wait for a Codex review after the limit resets:
   the rule says merge without it; (b) merge the API PR alone first: no benefit, the plugin side is off by default.
5. **Route for L2.** Chosen: `create_session` (one repository besides knk-workspace), as for L1, whose attach
   worked. Alternatives: (a) a subagent: only the fallback.

6. **L2 check and merge (2026-11-18).** Chosen: merge knk-web-api#46 and knk-workspace#751 into `next` with merge
   commits: every skill § 6 check held (heads matched, branch contained `next`, scope API-only plus docs, CI green
   build-and-test / mysql-tests / fresh-database, tests 4294 → 4333 with 0 failed, O32 field sets pinned by tests,
   `Map:Enabled` off by default, decisions logged, smoke § 2 tagged, #736 in review). Codex at its limit on #46 and
   failed on #751, noted on both. CI on `next` after L1: knk-web-api green; knk-plugin build green, paper-boot still
   running at merge time (L2 does not touch the plugin). Alternatives: (a) wait for the plugin's paper-boot on `next`
   before merging an API-only PR: no dependency between them.
7. **L3 and L4 in parallel.** Chosen: start both now, as the charter allows (L3 knk-web-app, L4 knk-plugin +
   knk-web-api; one link per component repo). Shared only knk-workspace (`CHANGELOG.md`, smoke guide § 3 / § 4, this
   report): each link keeps to its own entry, section, row and block. Route for both: `create_session`; L4 needs two
   repositories besides knk-workspace, where skill § 4.1.4.2 suggests a subagent, but L1's identical two-repo attach
   worked in this chain, and a subagent would block this coordinator's session for hours. Fallback: rerun as a
   subagent on a refused attach. Alternatives: (a) L4 as a subagent from the start; (b) run L3 and L4 one after the
   other: slower with no file overlap to justify it.

8. **L3 check and merge (2026-11-18).** Chosen: merge knk-web-app#50 and knk-workspace#753 into `next` with merge
   commits: every skill § 6 check held (heads matched, branch contained `next`, scope web app plus deploy notes and
   docs, nothing applied to the NAS, CI green build-and-test and e2e, Jest 2672 → 2699 and Playwright 149 → 160 with
   the real `bridge.js` in a fake BlueMap, spike evidence on #737, smoke § 3 tagged, #737 in review). Codex at its
   limit on #50, noted. Alternatives: (a) hold the merge until the NAS render exists: the live steps are the
   developer's test of `next`, not a merge gate.
9. **L6 started after L3.** Chosen: start L6 (#740, knk-web-app) now; L5 (needs L3, L4 and the developer's L4
   visibility check) cannot start yet, and L6's only gate is L3. Route `create_session` (one repository besides
   knk-workspace). Alternatives: (a) wait and run L5 first in charter order: L5's gate is closed.

10. **L6 rerun as a subagent.** The `create_session` link (session_01R1w2UuaEs6VbL7BVnR7ZTJ) was refused
    `add_repo` for knk-web-app by Auto mode's classifier ("[Unauthorized Access]") and stopped without changes.
    Chosen: rerun L6 as a subagent of this coordinator with the same prompt (variant B, worktrees under the
    coordinator's scratchpad), per skill § 4.1.4.3. Alternatives: (a) retry the attach in that session: the skill
    forbids it; (b) start a new session in a non-Auto mode: it would ask the developer before other tool calls.
    Lesson: the classifier is not consistent (L1–L4 attaches worked); later single-repo links still try
    `create_session` first.

11. **L4 check and merge (2026-11-18).** Chosen: merge knk-web-api#47, knk-plugin#77 and knk-workspace#752 into `next`
    with merge commits (API, plugin, docs). Every skill § 6 check held: heads matched, code branches contained
    `next`, scope limited to #738 (additive edits incl. `SiegeService.runningMatchApiId` for the match filter), CI
    green (API build-and-test, mysql-tests, fresh-database; plugin build, paper-boot), tests API 4333 → 4372 and
    plugin core 3151 → 3161 / paper 2957 → 2963 with 0 failed, every audience's response body tested (removing the
    visibility filter fails 4 tests), flags off by default, 13 decisions logged, smoke § 4 tagged with the three
    visibility steps manual, #738 in review. Codex at its limit on all three. The knk-workspace branch conflicted with
    L3's merge in four header/entry lines (CHANGELOG, smoke guide, production-installation, spec status): mechanical,
    resolved on the branch by merging `origin/next` and keeping both sides (`64ec62de`), per skill § 7.3.
    Alternatives: (a) send the conflict back to L4: a mechanical merge is the coordinator's per the skill; (b) hold
    L4 until the developer's live check: the charter gates L5's merge on it, not L4's.
12. **L7 started after L4.** Chosen: start L7 (#741, knk-web-api + knk-plugin) now: its gate (L2 merged) is open and
    L4 freed both repositories (L4 and L7 run one after the other, charter). Route `create_session` with the subagent
    fallback (decision 10). L5 waits: L6 holds knk-web-app, and L5's merge waits for the developer's L4 check.
    Alternatives: (a) L5 first: knk-web-app is busy with L6.

13. **L6 check and merge (2026-11-18).** Chosen: merge knk-web-app#51 and knk-workspace#755 into `next` with merge
    commits: every skill § 6 check held (heads matched, the web-app branch contained `next`, scope web app plus docs,
    the renderer's `compact` prop defaults off so other pages are unchanged, CI green build-and-test and e2e, Jest
    2699 → 2712 and Playwright 160 → 166 incl. the no-request case for viewers without the node, smoke § 6 tagged,
    #740 in review). Codex failed / at its limit on both, noted. The knk-workspace branch conflicted mechanically
    with L4's docs in three header/entry spots; resolved on the branch keeping both sides (`6f78871e`).
    Alternatives: (a) send it back to the subagent: a mechanical merge is the coordinator's (skill § 7.3).
14. **L5 started after L6.** Chosen: start L5 (#739, knk-web-app) now: its gate (L3 and L4 merged) is open and L6 freed
    knk-web-app. Its merge into `next` still waits for the developer's live check of the L4 visibility steps on #738
    (charter gate 4). Route `create_session` with the subagent fallback (decision 10). Alternatives: (a) wait for the
    developer's check before starting: the gate is on the merge, not the work.

15. **L5 checked, merge held for gate 4 (2026-11-18).** Every skill § 6 check held for knk-web-app#52 and
    knk-workspace#756: heads matched, both branches contain `next`, scope web app plus docs (one out-of-folder line:
    `translateAlternateColorCodes` in `MinecraftLegacyPreview.tsx` exported for reuse, no behaviour change), CI green
    build-and-test and e2e, Jest 2712 → 2733 and Playwright 166 → 176, no players request while the flag is off,
    bridge protocol v1 unchanged (optional fields only), smoke § 5 tagged, #739 in review, follow-up #757 filed.
    Chosen: hold the merge until the developer records the L4 visibility check on #738 (charter gate 4). Alternatives:
    (a) merge now behind the flag: the charter makes the developer's check a hard gate for this merge. L8 (#742) waits
    for L7, and starting it before L5 is in `next` would branch both from the same `MapPage` without L5's edits;
    L9 (#743) waits for L5 in `next`.

16. **L7 check and merge (2026-11-18).** Chosen: merge knk-web-api#48, knk-plugin#79 and knk-workspace#758 into `next`
    with merge commits. Every skill § 6 check held: heads matched; the API branch contained `next`; the plugin branch
    was 4 commits behind `next` (the destination engine P1 merge #78 from another chain) but merged without conflict
    (skill § 6.2 allows "the PR shows no conflicts"; `next` CI is checked after the merge); scope limited to #741
    (new controller, service, hub method, plugin handler and realtime sync; `KnKPlugin` wiring additive; existing
    gate operations called unchanged); CI green (API build-and-test, mysql-tests, fresh-database; plugin build,
    paper-boot); tests API 4372 → 4406, plugin core 3161 → 3176, api-client 344 → 347, paper 2963 → 2972, 0 failed;
    `Map:GateCommands:Enabled` off by default (404); 403 / 400 / 409 / 503 / 504 and the audit log tested; smoke § 7
    tagged; #741 in review. Codex at its limit on all three. The knk-workspace branch conflicted in one changelog spot
    with the destination engine's entry; resolved on the branch keeping both (`20ea39fc`). Alternatives: (a) merge
    `next` into the plugin branch and wait another 25 minutes for paper-boot: no textual conflict, and `next` CI
    covers the combination.
17. **L8 started after L7.** Chosen: start L8 (#742, knk-web-app) now: its gate (L3 and L7 merged) is open and no link
    runs in knk-web-app. L5 is finished but held for gate 4, so L8 is told to keep away from L5's files
    (`MapPage.tsx`, the bridge) and only add in shared ones, and to merge `next` again before its PRs. Alternatives:
    (a) wait for the developer's L4 check so L5 lands first: it could take days; the overlap is small and additive.

18. **L8 check and merge (2026-11-18).** Chosen: merge knk-web-app#53 and knk-workspace#759 into `next` with merge
    commits: every skill § 6 check held (heads matched, branches contained `next`, scope web app plus docs, edits in
    shared map files additive, `MapPage.tsx` and the bridge untouched, CI green build-and-test and e2e on push and PR
    runs, Jest 2712 → 2720 and Playwright 166 → 176, flag off → no buttons and no requests, smoke § 8 tagged, #742 in
    review). Codex at its limit on both. The docs PR merged a few minutes before the web-app PR because GitHub held
    the latter for its required PR `e2e` run. Alternatives: (a) wait for the developer's L4 check and land L5 first:
    could take days.
19. **L5 kept merge-ready.** Chosen: merge `origin/next` (now with L7 and L8) into L5's branches myself and resolve
    the mechanical conflicts keeping both sides: `MapDtos.ts` (L5's player DTOs and L8's gate-command DTOs both
    appended at the end), and the docs headers, changelog and spec § 6.3.6 (L8's as-built item renumbered to 7). CI
    re-runs on the new web-app head; L5 then merges as soon as the developer's check is on #738. Alternatives:
    (a) resolve at merge time: delays L5 by a CI cycle after the developer's go.

20. **Gate 4 passed; L5 merged; L9 started (2026-11-18).** The developer recorded the L4 visibility check on #738 at
    15:53 (steps 2, 3 and 5 pass on the dev server with plugin `next` `073fa4cf`, API `next` `6094276`; the
    `/ownermode` half of step 3 not run) and wrote "The L5 merge (#739) can go ahead". Chosen: merge knk-web-app#52
    (`54d8a01`, CI green, already contained `next`) and knk-workspace#756 after merging `next` into it again (one
    changelog conflict with the destination engine P3 entry, both kept, `c2d16a08`); then start L9 (#743), its gate
    (L5 merged) being open and knk-web-app free. Route `create_session` with the subagent fallback (decision 10).
    Alternatives: (a) wait for the `/ownermode` case: the developer explicitly cleared the merge; the case is listed
    in § 1 item 4.

21. **L9 check and merge; end of the chain (2026-11-18).** Chosen: merge knk-web-app#55 (`1ff5418`, CI green on push
    and PR runs, Jest 2741 → 2754, Playwright 191 passed incl. 5 new) and knk-workspace#765 into `next` with merge
    commits; every skill § 6 check held (scope: map code plus one `getByUuid` client method and its DTO; existing
    moderation hooks unchanged; Codex at its limit). Then the "At merge" steps (skill § 7.9): documentation sub-issue
    #766 with the remaining docs impact items and a docs session started with the docs-session starter
    (`session_01R1w2UuMzfZ1Z1FB7pV7iXR`). The tracker row stays "In review" until the developer accepts.
    Alternatives: (a) write the remaining docs in this coordinator: the global instructions keep them in a separate
    session so merges stay fast.
22. **#772 merged; fix links started (2026-11-19, developer's go).** The developer reviewed the status and said:
    merge #772, start #750 and #757, and for the kick-only moderator make "Open profile" disabled with a tooltip
    (filed as #809, tier:2, sub-issue of #732). Chosen:
    1. Merge knk-workspace#772 into `next` with a merge commit (`8487a058`). knk-workspace has no CI; the scratch nginx
       checks are in the PR; Codex was at its limit (noted on the PR).
    2. Two fix links in parallel, both with `create_session` (one component repository each, so the classifier route
       of skill § 4.1.4 applies): **F1** #750 in knk-plugin (session_01R1w2Uvrr2qFRCUBSxjXe7Y, branch
       `claude/overview-map-f1-subregions`; knk-web-api read only, stop and report if the API must change) and **F2**
       #757 plus #809 in knk-web-app (session_01R1w2UuSPaZGzxZKERwXfh3, branch `claude/overview-map-f2-panel-fixes`).
       #757 and #809 share one link because both change the `/map` page code in knk-web-app (one link per component
       repo).
    3. Links put their report blocks in their PR bodies and on their issues; the coordinator copies them here, as
       this session's direct pushes to `main` are refused (HTTP 403 on 2026-11-18, refused again 2026-11-19);
       bookkeeping goes through PR #773.
    4. Overlap check (board read from `origin/main`, 2026-11-19): the siege weapons L2b (#799, knk-plugin world-task
       handlers, knk-web-app `FormWizard`) and the production chain (territory L1–L3 in `next`, which reuse the
       outline reporting) touch neither `src/pages/map/`, `src/components/map/` nor `public/bluemap-bridge/`; F1 is
       told to build on the territory changes in `next`. No blocker.
    Alternatives: (a) one link for all three issues: needs knk-plugin and knk-web-app, so the subagent route, and
    serialises independent work; (b) #809 hidden instead of disabled, per spec § 5 rule 13: the developer chose
    disabled with a tooltip, logged by F2 as a spec decision.

23. **F2 and F1 checks and merges (2026-11-19).** Both links stopped on the account's 5-hour usage limit at about
    12:45 UTC and were resumed at 16:05 on the developer's "try again". Chosen:
    1. Merge knk-web-app#59 and knk-workspace#812 (F2) into `next` with merge commits: every skill § 6 check held
       (web app branch contained `next`; scope 9 map files; CI green; Jest 2787 → 2791; the new Escape e2e tests fail
       without the bridge listener; Codex at its limit). Before the merge I added `72714c17` to the docs branch: O34
       and § 5 item 12 now cite the hidden-not-disabled rule in § 6.3.5 / § 6.3.8 instead of § 5 rule 13 (F2's
       finding; my issue #809 had cited the wrong rule).
    2. F2's agent decisions: Escape from the frame as the new additive v1 type `escapePressed` (O35) rather than moving
       focus to the panel; a panel-local tooltip (the web app has no shared one), shown on tap, hidden on blur.
    3. Merge knk-plugin#93 and knk-workspace#811 (F1) into `next` with merge commits: build and paper-boot green on
       `23e71315`; plugin tests 7078 → 7106 (14 new), 0 failed; scope 7 files (`MapReportingService`, `MapReporting`,
       `DomainAccessFlagSync`, `KnKPlugin` wiring, tests); API untouched; Codex at its limit. Plugin `next` had moved
       by the siege weapons L2b merge (other files); the test merge was clean. The F1 docs branch conflicted with
       F2's smoke guide header and change list: I merged `next` into it (`90c4eabb`), keeping both.
    4. F1's agent decisions: a separate `reportSubRegions` with its own remembered set (also resent by `resendAll`);
       later syncs send only new sub-regions; the hook sits on the access sync, after the mirror. **Known limit:** a
       sub-region that disappears is not sent as removed (block item 5.3); recorded in § 1 item 10, not filed.
    Alternatives: (a) send F1 back to merge `next` again itself: the conflict was in docs header lines only, so
    resolving it here kept the merge mechanical and saved a round trip; (b) wait for Codex: skipped under the usage
    limit rule.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — Region outlines: plugin reports, API table `map_region_outlines` (#735)

1. **Scope done.**
    1. knk-web-api: model `MapRegionOutline`, table `map_region_outlines` (migration `AddMapRegionOutlines`, additive:
       one table, unique (WorldName, WgRegionId), index on DomainId, FK to `domains` SET NULL); `Services/Map/`
       `MapRegionOutlineService` (upsert by world and lower-case region id, removals, domain link through
       `Domain.WgRegionId` or `domain_sub_regions`, validation) and `MapOutlinePoints`; contracts
       `Realtime/Contracts/MapContracts.cs`; game hub method `ReportRegionOutlines` (one method); one `DbSet` and its
       configuration; one DI line.
    2. knk-plugin: knk-core `map/` (`RegionOutlinePort`, `RegionOutline`, `RegionRef`, `OutlinePoint`,
       `MapReportSender`, `MapReportingService`); knk-paper `map/` (`RegionOutlineAdapter` on WorldGuard,
       `MapReporting` wiring). Additive hooks: `ManagedRegionRepairService.setAfterRun`,
       `ManagedRegionsBootstrap.afterRepair`, `WgRegionIdTaskHandler.setRenameListener` (called after a successful
       rename), one resync hook in `KnKPlugin.initializeRealtime`, wiring in `KnKPlugin` next to the managed regions;
       `config.yml` `map.reporting.enabled: false`.
    3. knk-workspace: smoke guide § 1 (7 steps, all partly automated, tagged), plugin configuration reference § 4.29
       with § 2.1 and § 3 rows, changelog entry under "Unreleased", spec status line and § 6.1.1 stored shape.
2. **Commits and heads.** knk-web-api `claude/overview-map-outlines` at `253a6ee` (1 commit, base `next` at
   `8ec54e1`); knk-plugin `claude/overview-map-outlines` at `cf3a975a` (2 commits, base `next` at `1f414d08`);
   knk-workspace `claude/overview-map-outlines` at `e6e815dd` (1 commit, base `next` at `b1581488`). All up to date
   with `origin/next` at the time of the PRs.
3. **PRs.** [knk-web-api#45](https://github.com/PandiO/knk-web-api/pull/45),
   [knk-plugin#76](https://github.com/PandiO/knk-plugin/pull/76),
   [knk-workspace#749](https://github.com/PandiO/knk-workspace/pull/749) (`Closes #735`; the others `Part of`), base
   `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` 4277 passed, 100 skipped (MySQL, no `KNK_TEST_MYSQL`), 0 failed; branch 4294
       passed, 100 skipped, 0 failed (+17: `MapRegionOutlineServiceTests` 11, `AddMapRegionOutlinesTests` 4,
       `RealtimeHubTests` 2). CI on `253a6ee`: build-and-test, mysql-tests (migration on real MySQL) and
       fresh-database green.
    2. knk-plugin: baseline on `next` knk-core 3138, knk-api-client 344 (2 skipped), knk-paper 2953 (18 skipped), 0
       failed; branch 3151 / 344 (2 skipped) / 2957 (18 skipped), 0 failed (+17: `MapReportingServiceTest` 10,
       `ManagedRegionRepairServiceTest` 3, `RegionOutlineAdapterTest` 4). CI on `cf3a975a`: build green; paper-boot
       green (completed 2026-11-18 10:35 UTC).
    3. Known reds (also red on the base): none.
    4. Environment: Maven Central answered about 20 % of requests with 404 through this container's proxy, and Gradle
       caches the misses. Local plugin builds used the build's own repositories plus a scratchpad file repository of
       the reported-missing artifacts fetched from the same Maven Central URLs (local init script, not committed).
       The workspace's fast-check hook (plain Gradle) keeps failing on two cached Guava-dependency jars for that
       reason; GitHub CI is unaffected.
    5. Codex: at its usage limit on all three PRs (noted on each PR); no review, no findings handled.
5. **Decisions (DESIGN § 4.3).**
    1. *Hub argument shape.* Chosen: one object `{ outlines: [...], removed: [{wgRegionId, worldName}] }`, so a rename
       stores the new region and deletes the old name in one message. Alternatives: (a) a bare list (spec wording
       `ReportRegionOutlines(list)`): a rename would leave the temp name's row behind; (b) a second hub method for
       removals: one more access surface for no gain.
    2. *Domain link.* Chosen: the API resolves a nullable `DomainId` when it stores the row (main region or
       sub-region, a domain without a world matches any world), FK SET NULL; the plugin sends only world and region
       id. Alternatives: (a) the plugin sends the domain id: the repair's specs carry no id, and the API is the
       authority; (b) no link column: L2 would have to join on strings every time.
    3. *Rename hook location.* Chosen: `WgRegionIdTaskHandler.renameRegionInternal` after a successful
       `WorldGuardRegionRenamer.rename` (a listener setter, like the existing finalizers), because the renamer is a
       stateless static utility and the caller knows the world and the replaced region. Alternatives: (a) a static
       listener in `WorldGuardRegionRenamer` (the charter note's wording): global state in a pure helper; (b) the
       existing `RegionFinalizer` lambda: it gets neither the old name nor sub-region renames.
    4. *Startup hook location.* Chosen: an after-run listener on `ManagedRegionRepairService` (the repair that drives
       the reconciler), so startup and `/knk regions repair` both report. Alternatives: (a) inside
       `ManagedRegionReconciler`: it is also called per region on creation and knows nothing of "all domains".
    5. *Hub not connected yet.* Chosen: remember the last domain region set and resend it on every hub (re)connect
       through the realtime resync hooks. Alternatives: (a) queue failed messages: stale shapes; (b) report only at
       startup: lost when the repair finishes before the hub connects, or the API restarts.
    6. *Message size.* Chosen: split reports at about 24,000 characters (API keeps SignalR's 32 KB receive default);
       outlines over 1000 points are skipped and logged. Alternatives: (a) raise the API's
       `MaximumReceiveMessageSize`: a global hub change outside L1's additive scope.
    7. *Config keys.* Chosen: only `map.reporting.enabled` now. Alternatives: (a) also
       `map.reporting.interval-ticks` (O27): it is L4's player-report interval and nothing in L1 reads it.
    8. *Coordinates.* Chosen: WorldGuard's points as given (block coordinates, inclusive; a cuboid's four corners).
       Alternatives: (a) +1 on max edges for exact block borders: a rendering choice for L2/L3.
6. **Out of scope, noted.** [#750](https://github.com/PandiO/knk-workspace/issues/750): existing domain sub-regions
   are reported only when renamed, not at startup (the repair never sees sub-regions).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Apply the migration `AddMapRegionOutlines` (additive) with the API from `next`.
    2. To try it: paste into the plugin's `config.yml` (needs `realtime.enabled: true`), then smoke guide § 1:
       ```yaml
       map:
         reporting:
           enabled: true
       ```
    3. Optional: `@codex review` on the three PRs once the Codex limit resets.
9. **Notes for later links.**
    1. L2 reads `map_region_outlines`: `WgRegionId` (lower case), `WorldName`, `PointsJson` as `[[x,z],...]` (parse
       with `knkwebapi_v2.Services.Map.MapOutlinePoints.Parse`), `MinY`, `MaxY`, `DomainId` (nullable hint; the
       domain's own `WgRegionId` stays the authority), `UpdatedAt`. A domain's shape is its main region row plus its
       sub-region rows with the same `DomainId` (#750 for older sub-regions). Rows without a domain (stale or
       non-domain regions) should be ignored. The marker version (spec § 6.2.2) is L2's; L1 publishes no
       `EntityChanged` for outlines.
    2. L4 adds `map.reporting.interval-ticks` and the player report to `MapReportingService` (same class, spec § 7.1)
       and can reuse `MapReporting` for the wiring and `MapReportSender` for the hub.
    3. Hand edits to a region (`/rg redefine`) are reported at the next repair, not at once.

### 4.2 L2 — Public map API: config, markers, panel DTOs, `map` rate limit, access tests (#736)

1. **Scope done.**
    1. knk-web-api: `Controllers/MapController.cs` (`api/Map`, all `[AllowAnonymous]`: `config`, `markers`,
       `towns/{id}`, `districts/{id}`, `structures/{id}` with gate doors), the `[MapEnabled]` resource filter (404 before
       the action while `Map:Enabled` is off); `Dtos/MapDtos.cs` (O32 allow-list DTOs); `Services/Map/MapPublicService.cs`
       (`IMapPublicService`, `MapMarkerCache` singleton, `MapGeometry.Centroid`); `Configuration/MapOptions.cs`. Additive
       edits: the `map` policy in `RateLimitingSetup.cs`, three DI lines, `Map` and `RateLimiting:Map` in
       `appsettings.json`, five routes in `EndpointAccessRulesTests.AnonymousAllowList` and `ReadAccessRulesTests`
       (`P`). No migration.
    2. knk-workspace: smoke guide § 2 (7 steps: 2 automated, 5 partly automated, tagged), production installation
       § 4.3 (`Map__*`, `RateLimiting__Map__PermitPerMinute`), changelog entry, spec status line and § 6.2.8 as built.
2. **Commits and heads.** knk-web-api `claude/overview-map-public-api` at `3a014f8` (1 commit, base `next` at
   `562f504`); knk-workspace `claude/overview-map-public-api` at `fcde4be8` (1 commit, base `next` at `ac4b620f`). Both
   up to date with `origin/next` at the time of the PRs.
3. **PRs.** [knk-web-api#46](https://github.com/PandiO/knk-web-api/pull/46) (`Part of #736`),
   [knk-workspace#751](https://github.com/PandiO/knk-workspace/pull/751) (`Closes #736`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` 4294 passed, 100 skipped (MySQL, no `KNK_TEST_MYSQL`), 0 failed; branch 4333
       passed, 100 skipped, 0 failed (+39: `MapPublicServiceTests` 16, `MapPublicDtoFieldTests` 18,
       `MapControllerPipelineTests` 5; the two access tests extended). A03 and A06 run through the real controller,
       the real default-deny filter and the real rate limiter on a test server; A04 and A05 on an in-memory database,
       A05 also by reflection on every `Map*Dto`. Seen failing once: removing `[MapEnabled]` and adding a `wgRegionId`
       field each fail the tests (A06's 120 comes from the shipped `appsettings.json`, which the test host loads).
    2. Known reds: none.
    3. Codex: at its usage limit on knk-web-api#46 and failed on knk-workspace#751 (noted on both PRs); no review, no
       findings handled.
5. **Decisions (DESIGN § 4.3).**
    1. *Marker version.* Chosen: a short SHA-256 of the marker content; the built set is reused for
       `Map:Markers:CacheSeconds` (30 s), so a changed domain or outline gets a new version within that time.
       Alternatives: (a) bump on `EntityChanged` from the save interceptor: outline writes publish none (L1) and it
       hooks a shared file; (b) the newest `UpdatedAt`: misses domain renames.
    2. *Outline points (L1 note 5.8).* Chosen: served as stored (block coordinates, inclusive); the bridge draws them
       through the block centres (+0.5); a centroid pin already has +0.5. Alternatives: (a) +1 on max edges in the
       API: only right for cuboids, wrong for polygons.
    3. *Centroid pin height.* Chosen: `y: null`, the bridge picks the height. Alternatives: (a) `MaxY` or the middle
       of the range: a region up to the build limit puts the pin in the sky.
    4. *Domain shape.* Chosen: the main region row by the domain's own `WgRegionId` (any case, in its world when set),
       then rows linked by `DomainId` whose region id is still one of the domain's sub-regions; unlinked and stale rows
       ignored. The centroid uses the main region (else the first sub-region). Alternatives: (a) every row with the
       `DomainId`: a domain moved to another region would keep its old shape.
    5. *Door state.* Chosen: `openState` string of the effective state (`open`, `closed`, `opening`, `closing`,
       `jammed`; structure overrides applied), `isDestroyed` effective too. Alternatives: (a) a bool: loses jammed and
       the moving states.
    6. *Ids in public panels.* Chosen: none beyond the entity's own (district and town by name, no door ids), as the
       smoke draft says. Markers carry `townId` / `districtId` for the town toggle. Alternatives: (a) door ids for gate
       commands: L7/L8 read them from a staff route.
    7. *Under siege.* Chosen: `CurrentSiegeId` set and its match `Created` or `InProgress` (the rule of
       `SiegeMatchGateService`). Alternatives: (a) `CurrentSiegeId` alone: a stale pointer would show a siege.
    8. *Later parts in config.* Chosen: `livePlayers {enabled, pollIntervalMs}` and `gateCommands {enabled}` present
       and always off; no `Map:LivePlayers` / `Map:GateCommands` keys read yet. Alternatives: (a) read those flags now:
       turning one on before its phase exists would send the page to routes that answer 404; (b) leave the fields out:
       the spec lists enabled parts and the polling interval in § 6.2.1.
    9. *Disabled response.* Chosen: a resource filter on the controller returns 404 before model binding or the
       service (nothing is read). Alternatives: (a) remove the routes at startup: a settings reload would need a
       restart.
    10. *Layering.* Chosen: one service on `KnKDbContext`, like L1's `MapRegionOutlineService`. Alternatives: (a)
        repositories for read-only projections: more files, no reuse.
6. **Out of scope, noted.** None new. #750 (older sub-regions not reported) still limits district shapes.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing to keep it off. To try it: `Map__Enabled=true` in `/etc/knk/api.env`, then smoke guide § 2.
    2. Optional: `@codex review` on both PRs once the Codex limit resets.
9. **Notes for later links.**
    1. L3: `GET api/Map/config` then `GET api/Map/markers`; reload markers when `markerVersion` changes. Label distance
       `null` = every zoom. Draw outline points +0.5; a centroid pin has `y: null`. Districts carry `townId`,
       structures `townId` and `districtId`. Panels: `towns/{id}`, `districts/{id}`, `structures/{id}` (404 for an
       unknown id or another type). Door `openState` is lower case.
    2. L4: add `GET api/Map/players` to `MapController` (it inherits the `map` limit and the `[MapEnabled]` 404), set
       `config.livePlayers` from `Map:LivePlayers:*` in `MapPublicService.GetConfigAsync`, pin the route in both access
       tests and add its DTOs to `MapPublicDtoFieldTests.Pinned` (the test fails for an unpinned `Map*Dto`). Arena pins
       and `Map:Labels:Arena` are ready in config.
    3. L7: set `config.gateCommands.enabled` from `Map:GateCommands:Enabled`; the public panel has no door ids.

### 4.3 L3 — `/map` page, BlueMap bridge, pins, flash and toggle, public panels, action registry (#737)

1. **Spike (spec § 9.6, charter gate 3): passed.** BlueMap **v5.29** (tag `v5.29`, commit `a61e143f`, 2026-10-10;
   image `ghcr.io/bluemap-minecraft/bluemap:v5.29@sha256:bb49bfde…301e`). Evidence from the web app source at that tag,
   posted on [#737](https://github.com/PandiO/knk-workspace/issues/737#issuecomment-6976627917): `BlueMapApp.load()`
   appends a `<script>` per `webapp.conf` `scripts` entry after the maps load; `main.js` exposes `window.bluemap` and
   `window.BlueMap` (with `MarkerSet`, `HtmlMarker`, `ExtrudeMarker`, …); `new BlueMap.MarkerSet(id)` added to
   `bluemap.mapViewer.markers` takes `updateMarkersFromData` at runtime; clicks reach `elementObject.onClick` (HTML/POI
   markers, `CSS2DRenderer.js`) and `onClick` (extrude, raycast); camera through `controlsManager` and the
   `bluemapCameraMoved` / `bluemapMapChanged` events; postMessage to the parent works from the script. One caveat
   found and handled: BlueMap's `NormalMarkerManager` reloads `live/markers.json` every 10 s and removes every root
   marker set that file doesn't list; the bridge wraps the root's `updateMarkerSetsFromData` to add its own set ids to
   the ignore list (tested).
2. **Scope done.**
    1. knk-web-app: `pages/map/MapPage.tsx` (public route `/map`); `components/map/`: `BlueMapFrame`,
       `bridgeProtocol.ts` (v1 envelopes, page-side origin/source/version guard), `mapMarkers.ts` (markers → bridge
       payload, +0.5), `MapPanel` (side panel, bottom sheet on phones), `mapActionRegistry.ts`,
       `defaultMapRegistrations.ts`, `widgets/` (town with "Show region", district, structure, `GateDoorsWidget`),
       `useMapAvailability`; `apiClients/mapClient.ts`, `types/dtos/map/MapDtos.ts`; `public/bluemap-bridge/bridge.js`.
       Additive edits: `routeTable.ts` (route `map`, `MAP_ROUTE_ID`), `Navigation.tsx` (one filter), `LandingPage.tsx`
       (one link), `App.tsx`, `utils/enums.ts`, `e2e/fixtures/auth.ts` (`mockSession` answers `Map/config` 404),
       `README.md` (`REACT_APP_BLUEMAP_URL`).
    2. knk-workspace: closed-alpha runbook **Phase 10** (deploy notes, not applied: `bluemap-test` → profile-gated
       `bluemap` render service, nginx serves `web/` under `/bluemap/`, `webapp.conf` bridge and
       `client-decompression`, version pin, rollback); `scripts/alpha-web/compose.bluemap-service.yaml` (new),
       `nginx.conf` `location /bluemap/` (checked with `nginx -t` and a scratch nginx), README row; smoke guide § 3
       (11 steps: 1 automated, 9 partly automated, 1 manual only, tagged); changelog entry; spec status and § 6.3.5 as
       built; production installation § 4.3 note.
3. **Commits and heads.** knk-web-app `claude/overview-map-page` at `ee9a68d` (2 commits, base `next` at `e7c9265`);
   knk-workspace `claude/overview-map-page` at `23b028dc` (1 commit, base `next` at `55d01897`). Both up to date with
   `origin/next` at the time of the PRs.
4. **PRs.** [knk-web-app#50](https://github.com/PandiO/knk-web-app/pull/50) (`Part of #737`),
   [knk-workspace#753](https://github.com/PandiO/knk-workspace/pull/753) (`Closes #737`), base `next`. Not merged.
5. **Tests, baseline → result.**
    1. knk-web-app: Jest baseline 308 suites / 2672 tests → 313 / 2699, all green (+27: `bridgeProtocol` 8,
       `mapMarkers` 5, `mapActionRegistry` 7 (A22), `GateDoorsWidget` 4, `useMapAvailability` 3; the `routeTable` pins
       updated for the new route). Playwright 149 → 160 passed (+11 in `e2e/overview-map.spec.ts`, A07–A10; 4 repeats
       green). The specs serve a fake BlueMap web app that loads the **real** `bridge.js` (map ids named like the NAS
       render, so the `?worlds=` mapping runs too). `tsc`, `typecheck:e2e`, `CI=true npm run build` clean. CI on `ee9a68d` green (build-and-test, e2e; push and pull_request runs).
    2. knk-workspace: docs only; links and anchors checked by hand.
    3. Known reds: none.
    4. Codex: at its usage limit on knk-web-app#50 (review failed for `ee9a68d`); noted on both PRs; no findings
       handled.
6. **Decisions (DESIGN § 4.3).**
    1. *Keeping the bridge's markers.* Chosen: wrap the root marker set's `updateMarkerSetsFromData` so BlueMap's
       10 s marker-file reload ignores the bridge's sets. Alternatives: (a) re-add the sets after each reload: pins
       blink every 10 s; (b) write our markers into BlueMap's `markers.json`: a writer on the NAS and no live updates.
    2. *Pin drawing.* Chosen: two HTML markers per pin, a dot always and the label with the API's `maxDistance`.
       Alternatives: (a) BlueMap POI markers: need an icon file and show the label BlueMap's way; (b) one HTML marker:
       the label distance would hide the pin as well.
    3. *World ↔ BlueMap map.* Chosen: `bridge.js?worlds=<mapId>:<world>` in `webapp.conf`; a map id equal to the world
       name needs none. Alternatives: (a) rename the NAS map config to the world name: moves the tile folder (re-render);
       (b) an API setting: a new key in another link's repo.
    4. *Hosting.* Chosen: nginx serves BlueMap's static `web/` (`client-decompression: true`, 204 for unrendered tiles);
       BlueMap runs as a profile-gated render job on the same folders. Alternatives: (a) keep BlueMap's own web server
       (`-w`) and proxy to it: a second long-running server, and the spec has nginx serve `web/`; (b) watch mode
       (`-u`): the world is a snapshot copy, nothing to watch.
    5. *Framing.* Chosen: `X-Frame-Options: SAMEORIGIN` on `/bluemap/` only; the site keeps `DENY`. Alternatives:
       (a) a CSP `frame-ancestors`: the site has no CSP yet.
    6. *Signed-out entry.* Chosen: a map link on the start page, because the signed-out site has no top bar; signed in
       the bar has "Map"; both only while the map is on. Alternatives: (a) show the bar signed out: changes the public
       site's layout.
    7. *Staff widgets and actions.* Chosen: hidden without their node (anonymous viewers never see them).
       Alternatives: (a) the #280 rule, disabled with "Requires <node>": staff buttons for every anonymous visitor.
    8. *Marker version check.* Chosen: `config` every 60 s, markers reloaded when `markerVersion` changes.
       Alternatives: (a) no re-check: rule 2 asks for the reload; (b) every 10 s: the API's cache is 30 s anyway.
    9. *Centroid pin height.* Chosen: BlueMap's `terrainHeightAt`, retried while tiles load, else Y 64. Alternatives:
       (a) the region's `maxY`: L2 rejected it (pins in the sky).
    10. *Toggle.* Chosen: towns only (O05), one at a time (bridge group `town-toggle`), kept when the panel closes.
        Alternatives: (a) a toggle per district: not in the design.
    11. *`setPlayers` now.* Chosen: the bridge already draws name labels and reports `playerClicked`, so L5 changes
        no bridge message. Alternatives: (a) leave it to L5: L5 would change the bridge script.
    12. *Other specs.* Chosen: `mockSession` answers `Map/config` with 404 (map off). Alternatives: (a) mock it in each
        spec: every strict spec would need it.
    13. *nginx.conf.* Chosen: edit `scripts/alpha-web/nginx.conf` directly (inert without the mount: 404).
        Alternatives: (a) a snippet in the docs only: easy to miss at the next image build.
7. **Out of scope, noted.** None new. Player guide and site pages: follow-up in the docs issue at merge.
8. **Blockers.** None.
9. **At merge / what the developer must do.**
    1. Nothing to keep it off (`Map__Enabled` stays false: no map anywhere in the web app).
    2. On the NAS (`knk-deploy`, ask before each change): closed-alpha runbook Phase 10, then the full-world render
       (about 20 h). Check the game world name for `?worlds=` (the NAS map id is `overworld`).
    3. Then `Map__Enabled=true` and smoke guide § 3 (the live steps wait for step 2).
    4. Optional: `@codex review` on both PRs once the Codex limit resets.
10. **Notes for later links.**
    1. L5: `setPlayers {players: [{uuid, label, world, x, y, z}]}` exists; the bridge draws `.knk-player` labels and
       posts `playerClicked {uuid}`, which `MapPage.onBridgeMessage` ignores today (wire it there). Add optional
       payload fields (tags, colours) rather than new meanings. `arena` is already a `MapEntityKind`; add arena pins in
       `mapMarkers.toBridgeMarkers` with `labels.arena`.
    2. L6: `mapActionRegistry.addWidget('structure', 'staff', { id, node: 'knk.admin.world', Component })` (and per
       kind); the panel checks nodes only for registered staff entries, so anonymous viewers make no permission calls.
    3. L8: `mapActionRegistry.addAction('structure', { id, label, node: 'knk.gate.admin', visible: d => d.gate !== null,
       run: async (d, ctx) => { …; ctx.reload(); } })`. `MapPanelContext` has no map config yet; add
       `gateCommands.enabled` to it if the buttons must follow the flag. Door ids are not in the public panel (L2).
    4. L9: add a `player` registration once `playerClicked` is wired (L5); `MapEntityKind` and `parseBridgeMessage`
       need the new kind only if players come through `markerClicked`.
    5. The bridge protocol v1 is frozen (O14): #613 adds message types or a new version.

### 4.4 L4 — Live players backend: plugin reports, per-audience snapshots, arena pins (#738)

1. **Scope done.**
    1. knk-web-api: game hub `ReportMapPlayers` (one method; `PlayerLeft` one line to drop the player);
       `Services/Map/MapPlayerRegistry` (latest report per player, three missed intervals, fail-closed unknown mode),
       `Services/Map/MapPlayerSnapshots` (three audience snapshots per tick, `MapPlayerLabels` as `ChatLineFormat`,
       label cache), `Services/Map/MapLivePlayerData` (labels from `IUserService.GetByUuidAsync` and the `knk.mode.*`
       rank, arena pins from running `SiegeMatch` rows at the objective gate's marker pin); `GET api/Map/players` on
       `MapController` (anonymous, `map` limit, `[MapEnabled]`, 404 while `Map:LivePlayers:Enabled` is off,
       `no-store`); `config.livePlayers` from `Map:LivePlayers:*`; DTOs `MapPlayersDto`, `MapPlayerDto`,
       `MapPlayerLabelDto`, `MapArenaDto`; settings `Map:LivePlayers:Enabled` (false), `PollIntervalMs` (2000),
       `LabelCacheSeconds` (60). Additive: three DI lines, `appsettings.json` `Map:LivePlayers`, the route in both
       access tests, the DTOs in `MapPublicDtoFieldTests.Pinned` (plus one reviewed name exception, `MapPlayerDto.uuid`).
       No migration.
    2. knk-plugin: knk-core `map/OnlinePlayerSnapshotPort`, `OnlinePlayerPosition`, the player report in
       `MapReportingService`; knk-paper `map/PaperOnlinePlayerSnapshot` and `MapReporting.startPlayerReports`
       (main-thread snapshot timed as `map.player_snapshot`, async send). Additive: `KnKPlugin` (suppliers in the
       existing `MapReporting.create` call, one start line after `initializeRealtime`), `SiegeService.runningMatchApiId`,
       `config.yml` `map.reporting.interval-ticks: 40`.
    3. knk-workspace: smoke guide § 4 (9 steps: 1 automated, 5 partly automated and tagged, steps 2, 3 and 5 full
       manual), plugin configuration § 4.29 and § 2.1 row, production installation § 4.3, changelog entry, spec status
       line, § 6.2.9 and § 7.4 as built.
2. **Commits and heads.** knk-web-api `claude/overview-map-players-api` at `a9ed3af` (1 commit, base `next` at
   `612ad62`); knk-plugin `claude/overview-map-players-api` at `8b1efdcc` (1 commit, base `next` at `7f4bdd3a`);
   knk-workspace `claude/overview-map-players-api` at `09982caa` (1 commit, base `next` at `55d01897`). All up to date
   with `origin/next` at the time of the PRs.
3. **PRs.** [knk-web-api#47](https://github.com/PandiO/knk-web-api/pull/47),
   [knk-plugin#77](https://github.com/PandiO/knk-plugin/pull/77) (both `Part of #738`),
   [knk-workspace#752](https://github.com/PandiO/knk-workspace/pull/752) (`Closes #738`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` 4333 passed, 100 skipped (MySQL, no `KNK_TEST_MYSQL`), 0 failed; branch 4372
       passed, 100 skipped, 0 failed (+39: `MapPlayersPipelineTests` 7, `MapPlayerSnapshotsTests` 10,
       `MapPlayerRegistryTests` 6, `MapPlayerLabelsTests` 5, `MapLivePlayerDataTests` 4, `RealtimeHubTests` 3,
       `MapPublicDtoFieldTests` 4). Each audience's raw response body is checked through the real controller,
       default-deny filter, JWT bearer and rate limiter (A12, A14). Seen failing: removing the visibility filter fails
       4 tests. CI on `a9ed3af`: build-and-test, mysql-tests and fresh-database green.
    2. knk-plugin: baseline on `next` knk-core 3151, knk-api-client 344 (2 skipped), knk-paper 2957 (18 skipped), 0
       failed; branch 3161 / 344 (2 skipped) / 2963 (18 skipped), 0 failed (+16: `MapReportingServicePlayersTest` 10,
       `PaperOnlinePlayerSnapshotTest` 6). CI on `8b1efdcc`: build green; paper-boot green (completed 2026-11-18 11:54 UTC).
    3. Known reds (also red on the base): none.
    4. Environment: Maven Central through this container's proxy again answered some requests with 404 (L1's note).
       Local plugin builds used a scratchpad retry mirror (a small local HTTP server retrying Central and the Gradle
       plugin portal, plus an init script; not committed). Baselines ran in a separate worktree of `origin/next`.
       MockBukkit's `waitAsyncTasksFinished` cancels repeating tasks, so the scheduler test polls for the async send.
    5. Codex: at its usage limit on all three PRs (noted on each PR); no review, no findings handled.
5. **Decisions (DESIGN § 4.3).**
    1. *Snapshot tick.* Chosen: built lazily on the first request after `PollIntervalMs` ran out, one build at a time
       (`SemaphoreSlim`), all three audiences in one build; requests answer from the stored set (O21). Alternatives: (a)
       a background timer building every tick: works while nobody watches; (b) filtering per request: O21 rules it out.
    2. *Audience check.* Chosen: `IPermissionReadCache.HoldsAnyAsync` with `knk.mode.staff` / `knk.mode.owner` (30 s
       cache, wildcards via the resolver); a missing or invalid token is anonymous. Alternatives: (a) uncached
       `CheckAnyAsync`: a database read per 2 s poll per viewer; (b) a JWT claim: tokens carry no nodes.
    3. *Logged-in snapshot.* Chosen: built separately with the same content as the anonymous one (O08 is superseded
       by O31, nothing differs today). Alternatives: (a) serve the anonymous object to logged-in viewers: the spec
       names three snapshots and a later difference would need a new code path.
    4. *Match players in the "may see hidden" snapshot.* Chosen: listed with a `minigame` tag (spec § 5 rule 8: left
       out of every snapshot except that one). Alternatives: (a) left out everywhere (the sub-issue's shorter wording):
       the spec rule is the binding one.
    5. *Unknown mode value.* Chosen: hidden (tag `hidden` for staff viewers). Alternatives: (a) treat as no mode: a
       future mode would leak to the public.
    6. *Label data.* Chosen: `IUserService.GetByUuidAsync` (title, tier, group colours with group ids, the data behind
       the chat line) and the rank by `knk.mode.owner` / `knk.mode.staff`, as `PlayerListener`; the plugin's fixed
       owner/staff/default colours mirrored as `&` codes; cached per player for `LabelCacheSeconds` (60). A UUID
       without an account gets its presence name in default colours. Alternatives: (a) the plugin sends the label: the
       spec puts label parts in the API (O23); (b) no cache: about five queries per player every tick.
    7. *Arena pin.* Chosen: one pin per running match (`SiegeMatch` created or in progress, as L2's "under siege") at
       the first objective gate (by `SortOrder`) with a marker pin, else the scenario's lowest gate id with one; no pin
       (logged once) otherwise; count = reported players with that match id. Tag "Siege", label
       "[Siege] n players" ("1 player" singular). Alternatives: (a) the objective's `Location`: siege objectives in
       use are gates and the markers already resolve gate pins; (b) the match's roster count: O24 says live
       participants.
    8. *Minigame id.* Chosen: two fields, `minigame` (`siege`) and `matchId` (the API's `SiegeMatch` id from
       `SiegeService.runningMatchApiId`; null until the API answered the start, then the player is still hidden but
       no pin is drawn). "In a running match" = lobby phase `IN_PROGRESS` and on the roster (`runningMatchOf`);
       hub-phase lobby members still show. Alternatives: (a) the match token: the API stores no token; (b) hide
       lobby members at the hub too: O13 speaks of a running match.
    9. *Report shape and size.* Chosen: `{intervalMs, players: [...]}`, positions to 0.1 block, yaw whole degrees,
       split below L1's 24,000-character budget (260 characters per player assumed); upsert per player in the API, so
       split messages need no "complete set" marker; one empty report when the server empties. Alternatives: (a)
       replace a server's set per message: a split report would drop players; (b) send every interval even when empty:
       needless traffic.
    10. *`interval-ticks` bounds.* Chosen: clamped to 10..1200 in the plugin, the API clamps the interval to
        0.5..60 s for the drop rule. Alternatives: (a) unbounded: 1 tick would report 20 times a second.
    11. *Hub flag check.* Chosen: the hub ignores reports while `Map:LivePlayers:Enabled` is off, so nothing is held.
        Alternatives: (a) keep them anyway: memory for a disabled feature.
    12. *Route wiring.* Chosen: the action resolves `MapPlayerSnapshots` and the options from request services, so
        `MapController`'s constructor (and L2's pipeline tests) stay unchanged. Alternatives: (a) constructor
        injection: L2's tests would need the new services registered.
    13. *uuid in a public DTO.* Chosen: `MapPlayerDto.uuid` (the head and L9's player panel need it; a Minecraft UUID is
        public), as a reviewed exception in `NoPublicMapDto_NamesARegionOwnerOrPermission`. Alternatives: (a) name
        only: heads by name break on renames and L9 needs a stable id.
6. **Out of scope, noted.** None new.
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing to keep it off; no migration.
    2. The live check of smoke § 4.1 steps 2, 3 and 5 (visibility) on #738 before L5 is merged: API from `next` with
       `Map__Enabled=true` and `Map__LivePlayers__Enabled=true`; plugin `config.yml`:
       ```yaml
       map:
         reporting:
           enabled: true
           interval-ticks: 40
       ```
       (needs `realtime.enabled: true`), then smoke guide § 4.
9. **Notes for later links.**
    1. L5: poll `GET api/Map/players` every `config.livePlayers.pollIntervalMs` (only when `config.livePlayers.enabled`).
       Draw `players` by `uuid` (head) with `label` parts: `[rankTag]` in `bracketColor`/`textColor`, `-{braced}-`
       (bold when `bracedBold`), `name`; colours are the `&` code strings as the groups store them (the plugin
       parses the same strings with `LegacyStyles`). Tags: `afk`, `mode` (`staff`, `owner`, `hidden`), `minigame`
       (`Siege`) — the last two only reach staff viewers. `arenas[]` have `label`, `playerCount` and a `pin` like the
       markers (`y` may be null); label distance `config.labels.arena`. Send the JWT when logged in: it selects the
       audience. Responses are `no-store`.
    2. L7: `GameServerHub` now also has `ReportMapPlayers`; `MapController` has `GetPlayers`. `MapOptions` has a
       `LivePlayers` block; add `GateCommands` beside it.
    3. L9: `MapPlayerDto.uuid` is the player's Minecraft UUID (lower case), for the moderation panel.

### 4.5 L5 — Live players layer on the page (#739)

1. **Scope done.**
    1. knk-web-app: `components/map/useLivePlayers.ts` (polls `GET api/Map/players` only while
       `config.livePlayers.enabled`: at once, then every `intervalMs` of the last answer, else `pollIntervalMs`,
       clamped 0.5–60 s, one request at a time, none while the tab is hidden, players cleared after three failed polls;
       the JWT goes with it through `serviceCall`); `components/map/mapPlayers.ts` (the `ChatLineFormat` line
       `[RANK]-{braced}- name` as styled parts, `&` codes read with the existing legacy-text parser into `#RRGGBB` and
       formats; tags Staff mode, Owner mode, Hidden mode, minigame, AFK; the v1 `setPlayers` entry with the optional
       `parts` and `tags`); `components/map/PlayerCard.tsx` (`PlayerCard`, `MapPlayerPanel` with `children` for #743);
       arena pins `mapMarkers.toArenaPins` (kind `arena`, `labels.arena`), sent with `setMarkers` only when the arenas
       change; `bridge.js` draws one HTML marker per player at head height (coloured label, only `#RRGGBB` accepted;
       tags; head from `?heads=<address with {uuid}>`, else BlueMap's `assets/steve.png`; AFK dimmed);
       `MapPage.onBridgeMessage` handles `playerClicked`. Additive: `MapDtos.ts` (players DTOs),
       `mapClient.getPlayers`, `translateAlternateColorCodes` exported, `e2e/fixtures/map.ts` (players fixtures,
       `serveFakeBlueMap(page, bridgeQuery)`), `bridgeProtocol.ts` (optional `parts`, `tags`). `MapPanel` and
       `mapActionRegistry` unchanged. No API change, no migration.
    2. knk-workspace: smoke guide § 5 (8 steps: 1 automated, 7 partly automated, tagged), changelog entry, spec status
       line and § 6.3.6 as built, closed-alpha runbook Phase 10 step 3 (optional `heads=`, with the privacy note).
2. **Commits and heads.** knk-web-app `claude/overview-map-players-page` at `bc17a48` (1 commit, base `next` at
   `01ad4d9`); knk-workspace `claude/overview-map-players-page` at `69244809` (1 commit, base `next` at `a130f2d6`).
   Both up to date with `origin/next` at the time of the PRs.
3. **PRs.** [knk-web-app#52](https://github.com/PandiO/knk-web-app/pull/52) (`Part of #739`),
   [knk-workspace#756](https://github.com/PandiO/knk-workspace/pull/756) (`Closes #739`), base `next`. Not merged
   (charter gate 4: the developer's live check of the L4 visibility steps on #738 first).
4. **Tests, baseline → result.**
    1. knk-web-app: Jest 315 suites / 2712 tests → 318 / 2733, all green (+21: `mapPlayers` 12, `useLivePlayers` 6,
       `PlayerCard` 3). Playwright 166 → 176 passed (+10 in `e2e/overview-map-players.spec.ts`: A11 heads, labels and
       movement; A13/A15 colours, bold and the AFK tag; A12 staff viewer's tags and the token on every poll; A14 arena
       pin; A16 quit; name card; phone bottom sheet; `heads=`; flag off without a players request; 3 repeats green).
       Seen failing: the AFK tag removed → 3 Jest red. `tsc`, `typecheck:e2e`, `CI=true npm run build` clean. The
       Playwright baseline 166 is L6's count on the same `next` commit. CI on `bc17a48`: build-and-test and e2e green (push and pull_request runs).
    2. knk-workspace: docs only; links and anchors checked by hand.
    3. Known reds: none.
    4. Codex: at its usage limit on knk-web-app#52 and knk-workspace#756 (review failed; noted on both PRs); no findings handled.
5. **Decisions (DESIGN § 4.3).**
    1. *Player click target.* Chosen: a separate `MapPlayerPanel` with `PlayerCard`, extendable through `children`,
       because the registry is keyed by numeric ids and the spec names `PlayerCard` / `PlayerModerationPanel` as
       components (§ 6.3.1). Alternatives: (a) a `player` kind in `mapActionRegistry`: widens `MapEntityKind` (bridge
       protocol) and the numeric `id` of every registration.
    2. *Heads.* Chosen: BlueMap's default head unless `heads=` is set in `webapp.conf`, because a skin service sees
       every viewer's IP address. Alternatives: (a) a fixed third-party service by default: a privacy choice for the
       developer; (b) no head: O07 asks for one.
    3. *Arena pin ids.* Chosen: the position in the list (the API sends none; no `arena` panel, so a click opens
       nothing). Alternatives: (a) a hash of the pin position: no use until arenas get a panel.
    4. *Hidden tab.* Chosen: no polls while the tab is hidden. Alternatives: (a) keep polling: rate limit and server
       work for nobody.
    5. *Poll failures.* Chosen: players cleared after three failed polls in a row (the API's own drop rule).
       Alternatives: (a) clear at once: one network blip blanks the map; (b) never: stale players stay.
    6. *Label weight.* Chosen: normal weight with bold only where the chat line is bold, on a dark strip as in game.
       Alternatives: (a) the pins' semi-bold: bold titles would not stand out.
6. **Out of scope, noted.** [#757](https://github.com/PandiO/knk-workspace/issues/757): Escape doesn't close the map
   panel after a click inside the map (focus is in the iframe; also L3's place panel).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing to keep it off; no migration, no new setting (`Map__LivePlayers__Enabled` from L4 turns the layer on).
    2. Optional: `&heads=<address with {uuid}>` on the bridge line of BlueMap's `webapp.conf` (runbook Phase 10 step 3);
       choose a service only if the privacy trade-off is fine.
    3. Smoke guide § 5 with the § 3 and § 4 deployments.
9. **Notes for later links.**
    1. L9: `playerClicked` opens `MapPlayerPanel` (`components/map/PlayerCard.tsx`) from `MapPage`; put
       `PlayerModerationPanel` in its `children` (the clicked player's `MapPlayerDto` is `clickedPlayer` in `MapPage`,
       `uuid` lower case). The panel's `player` is null when the player left the viewer's snapshot.
    2. `useLivePlayers` returns the whole snapshot (`players`, `arenas`); reuse it rather than a second poll.

### 4.6 L6 — Staff details: compact display-configuration renderer (#740)

1. **Scope done.**
    1. knk-web-app: `DisplayWizard` `compact` prop (passed on to `DisplaySection` and `CollectionSection`; default
       false, the detail page unchanged; the prop type in `DisplayModels.ts`): no header, every collection a collapsed
       `<details>` with its name and count, values read-only with links to related records, no buttons, hot edit or
       pickers, and no checks of the edit, link or delete nodes. New `components/map/staffDetailsRegistrations.tsx`
       (staff widget `staff-details` under `knk.admin.world` for town, district and structure through
       `mapActionRegistry.addWidget`; `structureEntityType`) and `components/map/widgets/StaffDetailsWidget.tsx`
       ("Details", "Open full page" to `/display/<type>/<id>?returnTo=/map`, the compact renderer), lazily loaded.
       Additive edit: one call in `createMapActionRegistry`. `MapPanel` unchanged. No API change, no migration.
    2. knk-workspace: smoke guide § 6 (7 steps: 2 automated, 5 partly automated, tagged), changelog entry, spec status
       line and § 6.3.3 as built.
2. **Commits and heads.** knk-web-app `claude/overview-map-staff-details` at `1443cf5` (1 commit, base `next` at
   `f551804`); knk-workspace `claude/overview-map-staff-details` at `fe64919d` (1 commit, base `next` at `0f0f8e7f`).
   Both up to date with `origin/next` at the time of the PRs.
3. **PRs.** [knk-web-app#51](https://github.com/PandiO/knk-web-app/pull/51) (`Part of #740`),
   [knk-workspace#755](https://github.com/PandiO/knk-workspace/pull/755) (`Closes #740`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-app: Jest 313 suites / 2699 tests → 315 / 2712, all green (+13: `DisplayWizard.compact` 6,
       `staffDetails` 7; L3's pin "no staff widgets yet" in `mapActionRegistry` now pins `knk.admin.world`).
       Playwright 160 → 166 passed (+6 in `e2e/overview-map-staff-details.spec.ts`, A17: staff details with "Open full
       page", read-only with links, collapsed collections, phone; player without the node: no Details and no
       `DisplayConfigurations` / `Structures` request; anonymous: also no permission check). Seen failing once (compact
       branch disabled: 2 Jest red; node changed: 4 e2e red). `tsc`, `typecheck:e2e`, `CI=true npm run build` clean.
       The Playwright baseline 160 is L3's count on the same `next` commit. CI on `1443cf5`: build-and-test and e2e green (push and pull_request runs).
    2. knk-workspace: docs only; links and anchors checked by hand.
    3. Known reds: none.
    4. Codex: at its usage limit on knk-web-app#51 and knk-workspace#755 (review failed; noted on both PRs); no
       findings handled.
5. **Decisions (DESIGN § 4.3).**
    1. *Type of a gate.* Chosen: `GateStructure` when the public panel has `gate` (same id; the API seeds its display
       configuration with doors and siege settings). Alternatives: (a) always `Structure` (the smoke draft's
       wording): a gate's details would miss its gate fields.
    2. *Node.* Chosen: the fixed `knk.admin.world` for town, district and structure (their world area node; L3's
       note). Alternatives: (a) the type's `readNodes` from `Metadata/entities`: one more request for every viewer, and
       extra read nodes such as `knk.admin.config` would open staff details to non-world staff.
    3. *Loading.* Chosen: `React.lazy` for the widget: anonymous viewers don't download the renderer, and the registry
       module stays free of router imports. Alternatives: (a) a static import: a bigger map page and
       `react-router-dom` mocks in every registry test.
    4. *Collapsed collections.* Chosen: native `<details>`/`<summary>`, paged above 12 items like the full page.
       Alternatives: (a) a custom toggle button: compact mode would then have buttons.
    5. *Problems in compact form* (no configuration, no access, error). Chosen: one line in the section, the public
       part stays. Alternatives: (a) the full page's problem box with Back / Try again: page-sized buttons in a panel.
6. **Out of scope, noted.** None new. Towns and districts have no seeded default display configuration; their
   "Details" says so in one line until staff create one (smoke § 6.0).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing: no flag, no settings, no migration. The section appears only where the map is on (`Map__Enabled`).
    2. Smoke guide § 6 with the § 3 deployment (waits for the NAS render).
    3. Optional: `@codex review` on both PRs once the Codex limit resets.
9. **Notes for later links.**
    1. L8 / L9: `MapPanel` renders staff widgets in the "Staff details" section and actions below it; the staff
       details widget has id `staff-details` per kind. Register further staff widgets with other ids; registering the
       same id replaces it.
    2. The compact renderer is reusable: `<DisplayWizard entityTypeName=... entityId=... compact />` (needs a router).

### 4.7 L7 — Gate commands backend: endpoint, hub command, plugin handler (#741)

1. **Scope done.**
    1. knk-web-api: `Controllers/GateCommandsController` (`POST api/GateStructures/{id}/commands`, own controller on the
       `api/GateStructures` prefix, `[RequirePermission(GateAdmin)]` only), `Services/Map/GateCommandService`,
       singleton `Services/Map/GateCommandWaiter`, DTOs `GateCommandRequestDto` / `GateCommandResponseDto`, hub contract
       `GateCommand` v1 (`GateCommandPayload`) and `GateCommandResultDto` in `Realtime/Contracts/MapContracts.cs`, game hub
       `GateCommandResult`, `AuditAction.GateCommandSent` (65) and `AuditSubjectTypes.GateStructure`, `MapOptions.GateCommands`
       (`Enabled` false, `TimeoutSeconds` 5), `config.gateCommands.enabled` from the flag. Additive shared edits: two DI
       lines, `appsettings.json` `Map:GateCommands`, one hub method, the pin in `EndpointAccessRulesTests`, three hub
       tests. No migration (the audit action is stored as text).
    2. knk-plugin: knk-core `gates/command/GateCommandHandler`; knk-api-client `realtime/GateCommandEvents`; knk-paper
       `realtime/GateCommandRealtimeSync`; `KnKPlugin.registerGateCommandSync` (one call after `registerModerationSync`
       plus the method). The existing gate operations (`GateManager.openGate` / `closeGate`, `GateCommandSupport.repair`)
       are called, not changed. No `config.yml` key.
    3. knk-workspace: smoke guide § 7 (10 steps: 4 automated, 6 partly automated, tagged), changelog entry, production
       installation § 4.3 `Map__GateCommands__*`, spec status line, § 6.2.10 and § 7.5 as built; `origin/next` merged in
       (L6's entries kept beside L7's).
2. **Commits and heads.** knk-web-api `claude/overview-map-gate-commands` at `16e4157` (1 commit, base `next` at
   `f2f523c`); knk-plugin `claude/overview-map-gate-commands` at `1f8bb3c7` (1 commit, base `next` at `ef4e99d9`);
   knk-workspace `claude/overview-map-gate-commands` at `8368b901` (1 commit plus the merge of `next` at `a130f2d6`). All
   up to date with `origin/next` at the time of the PRs.
3. **PRs.** [knk-web-api#48](https://github.com/PandiO/knk-web-api/pull/48),
   [knk-plugin#79](https://github.com/PandiO/knk-plugin/pull/79) (both `Part of #741`),
   [knk-workspace#758](https://github.com/PandiO/knk-workspace/pull/758) (`Closes #741`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` 4372 passed, 100 skipped (MySQL, no `KNK_TEST_MYSQL`), 0 failed; branch 4406
       passed, 100 skipped, 0 failed (+34: `GateCommandServiceTests` 26 through the real controller and service,
       `GateCommandsPipelineTests` 3 through routing, JWT, default-deny and `RequirePermission`, `RealtimeHubTests` 3
       including a real game-hub round trip, `EndpointAccessRulesTests` 1, `MapPublicServiceTests` 1). Covers 403 without
       `knk.gate.admin` (also with `knk.admin.world`), 409 during a siege match on the gate, 503 without a game server,
       400 for a foreign door, 504 timeout with a late answer ignored, the audit entry per command, flag off (404,
       nothing sent or audited). Seen failing: disabling the siege or the door check fails 4 tests. CI on `16e4157`: build-and-test, mysql-tests and fresh-database green (push and pull_request runs).
    2. knk-plugin: baseline on `next` knk-core 3161, knk-api-client 344 (2 skipped), knk-paper 2963 (18 skipped), 0
       failed; branch 3176 / 347 (2 skipped) / 2972 (18 skipped), 0 failed (+27: `GateCommandHandlerTest` 15 with the real
       `GateManager`, `GateCommandEventsTest` 3, `GateCommandRealtimeSyncTest` 9 with the real `GateCommandSupport.repair`
       persisting through a mocked `GateDoorsApi`). CI on `1f8bb3c7`: build green; paper-boot green (completed 2026-11-18 12:45 UTC).
    3. Known reds (also red on the base): none.
    4. Environment: Maven Central and the Gradle plugin portal through this container's proxy again answered some
       requests with 404 (L1/L4's note); local plugin builds used a scratchpad retry mirror for those two only (a small
       local HTTP server plus an init script; not committed). The EngineHub repository refused the mirror (403), so it
       stays direct.
    5. Codex: at its usage limit on all three PRs (noted on each PR); no review, no findings handled.
5. **Decisions (DESIGN § 4.3).**
    1. *Where the endpoint lives.* Chosen: a new `GateCommandsController` on the `api/GateStructures` prefix (as
       `PlayerModerationController` on `api/Users`). Alternatives: (a) an action on `GateStructuresController`: a
       shared file with a class-level `DashboardReads` rule; the new controller is additive.
    2. *Status codes.* Chosen: 200 for the game server's `done` and `refused` (body `result` and `message`), 409 for
       `siege` (API check or the game server's lockdown), 504 for `timeout`; flag off 404 `GateCommandsOff`, like the
       other map flags. Alternatives: (a) 409 or 422 for `refused`: the panel shows the game server's reason either
       way, and an error status would hide the door states; (b) 200 for a timeout: the command's fate is unknown.
    3. *Siege test in the API.* Chosen: the gate's `CurrentSiegeId` is a match created or in progress, the same test as
       the public panel's "under siege" (§ 6.2.8), so the panel and the endpoint agree. Alternatives: (a) any running
       match whose scenario lists the gate: the lockdown sets `CurrentSiegeId`, so this adds a query for no case seen.
    4. *Siege test in the plugin.* Chosen: the live siege lockdown (`SiegeGateController.lobbyIdOf`). Alternatives: (a)
       the cached `currentSiegeId`: can be stale after a match and would refuse wrongly.
    5. *What is audited.* Chosen: every command past validation, with its outcome (`done`, `refused`, `siege`,
       `no-game-server`, `timeout`), one entry after the result. Alternatives: (a) also malformed requests (400/404):
       not commands; (b) an entry before sending plus one after: two rows per command for no extra information.
    6. *Which game server.* Chosen: every connected game server gets the command; the first answer per command id wins,
       later ones are ignored. Alternatives: (a) route by the gate's world: needs a world → server map the API doesn't
       keep; one game server today.
    7. *Whole-gate result.* Chosen: `done` when at least one door acted or already was in the asked state, else
       `refused`; per door `outcome` (`started`, `already`, `repaired`, `skipped`) and `reason`. Alternatives: (a)
       `refused` when any door is skipped: an inactive door would block the whole gate.
    8. *Staff door list for L8.* Chosen: no new endpoint; the existing `GET api/GateStructures/{id}/doors`
       (`GateDoorsController`, any login or the plugin key) gives door ids, names and states. Alternatives: (a) door ids
       in the public panel DTO: O32 keeps public fields to the allow-list.
6. **Out of scope, noted.** None new. The web app's audit-log action labels and the realtime contract catalogue
   (realtime DESIGN § 6) get `GateCommandSent` / `GateCommand` in the documentation follow-up (PR docs impact lines).
7. **Blockers.** None.
8. **At merge / what the developer must do.**
    1. Nothing to keep it off; no migration, no plugin key.
    2. To test: API `Map__GateCommands__Enabled=true` (`Map__GateCommands__TimeoutSeconds=5` default), plugin from
       `next` connected to the hub (`realtime.enabled: true`), then smoke guide § 7 (A18, A19).
9. **Notes for later links.**
    1. L8: show the buttons only when `config.gateCommands.enabled` and the viewer holds `knk.gate.admin`; door ids from
       `GET api/GateStructures/{id}/doors`. Send `POST api/GateStructures/{id}/commands` `{action, doorId?}` (leave
       `doorId` out for "whole gate"). Show `message`; 200 has `result` `done` or `refused`, 409 `GateInSiege` (disable
       with "Gate is in a running siege"; the public panel's `underSiege` predicts it), 503 "no game server", 504
       timeout ("timed out after 5 s"). Re-read the panel after the result: `doors[].state` may still be `opening`.

### 4.8 L8 — Gate command buttons in the panel (#742)

1. **Scope done.**
    1. knk-web-app: staff widget `gate-commands` in `mapActionRegistry` (`components/map/gateCommandRegistrations.tsx`,
       `widgets/GateCommandsWidget.tsx`) under `knk.gate.admin`, visible for a gate while `config.gateCommands.enabled`;
       Open, Close, Toggle and Repair for the whole gate (no `doorId`) and per door (ids from
       `GET api/GateStructures/{id}/doors`); `apiClients/gateCommandClient.ts` (`POST api/GateStructures/{id}/commands`,
       35 s client timeout); result shown (done, refused with reason, 409 "Gate is in a running siege", 503, 504, other
       errors with the API's message), then the panel and the door list are read again; disabled with "Gate is in a
       running siege" while `underSiege` or after a 409. `MapPanelContext.gateCommands.enabled` from the shared config
       answer (`useMapAvailability`, no extra request); `visible(data, context)` gets the context (additive); a panel
       reload keeps its data and widgets mounted until the fresh data arrives. DTO types appended to `MapDtos.ts`; e2e
       fixtures in a new `e2e/fixtures/mapGateCommands.ts`. Not touched: `MapPage.tsx`, the bridge, `mapClient.ts`,
       `e2e/fixtures/map.ts` (L5 overlap).
    2. knk-workspace: smoke guide § 8 (9 steps: 3 automated, 6 partly automated, tagged), spec § 6.3.6 as built and
       status line, changelog entry.
2. **Commits and heads.** knk-web-app `claude/overview-map-gate-buttons` at `05a30ea` (1 commit on `next` `01ad4d9`);
   knk-workspace `claude/overview-map-gate-buttons` at `9fad9531` (1 commit on `next`). Both up to date with
   `origin/next` when the PRs were opened.
3. **PRs.** [knk-web-app#53](https://github.com/PandiO/knk-web-app/pull/53) (`Part of #742`),
   [knk-workspace#759](https://github.com/PandiO/knk-workspace/pull/759) (`Closes #742`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. Jest `npm run test:ci`: 315 suites / 2712 passed → 316 / 2720 passed (+8 `gateCommands.test.tsx`;
       `mapActionRegistry.test.tsx` now expects `knk.gate.admin` among the structure nodes; `GateDoorsWidget.test.tsx`
       context gets the new field).
    2. Playwright, all specs: 166 passed → 176 passed (+10 `overview-map-gate-commands.spec.ts`, also green with
       `--repeat-each=3`).
    3. `tsc --noEmit`, `typecheck:e2e`, `CI=true npm run build`: green → green. Known reds: none.
    4. Acceptance: A18 page side (e2e and Jest; door animation in game by hand, smoke § 8 steps 2–3), A22 (the buttons
       are a registry registration; no bridge change).
    5. CI on `05a30ea`: build-and-test green; e2e still running when this block was written (see the final message).
    6. Codex: at its usage limit on both PRs (noted on each PR); no review, no findings handled.
5. **Decisions (DESIGN § 4.3).**
    1. *Widget, not registry actions.* Chosen: one staff widget, because per-door buttons and the result need their own
       state. Alternatives: (a) whole-gate `addAction` entries plus a door widget: one feature in two places, and the
       action bar can't show results; (b) one action per door: door ids are not in the public panel.
    2. *Hidden, not disabled, without the node.* Chosen: hidden (the panel's rule since L3); `useActionGate` inside the
       widget shares the permission cache. Alternatives: (a) disabled with "Requires knk.gate.admin": shows gate
       buttons to every logged-in player.
    3. *Flag source.* Chosen: the page load's shared `api/Map/config` answer. Alternatives: (a) a `MapPanel` prop from
       `MapPage`: touches `MapPage.tsx` (L5 overlap); (b) a config request per panel: extra traffic. Consequence: a
       flag change needs a page reload (smoke § 8.0).
    4. *Placement.* Chosen: gate commands above the staff "Details". Alternatives: (a) below: buttons pushed out of view
       by the long details.
    5. *409 lock.* Chosen: stays until the panel is reopened or `underSiege` turns from true to false. Alternatives: (a)
       cleared on every re-read: the public flag can lag the API and re-enable buttons that will be refused.
    6. *Reload behaviour.* Chosen: `MapPanel` keeps the current data on a reload (the result would otherwise vanish when
       the widgets unmount). Alternatives: (a) keep "Loading…" and lift the result into the panel: a larger change to
       the panel's API.
6. **Out of scope, noted.** None. The admin guide and register lines are follow-ups for the documentation issue (PR
   docs impact).
7. **Notes for later links.** L9: `visible(data, context)` now gets `MapPanelContext`; a panel reload no longer
   unmounts widgets. On merging L5: `MapDtos.ts` has L8's types at the end; `MapPage.tsx`, the bridge, `mapClient.ts`
   and `e2e/fixtures/map.ts` are unchanged by L8.

### 4.9 L9 — Player context panel with moderation actions (#743)

1. **Scope done.**
    1. knk-web-app: `components/map/PlayerModerationPanel.tsx` as the `children` of `MapPlayerPanel` (two added lines in
       `MapPage.tsx`; `PlayerCard.tsx` unchanged). The panel opens for any of `knk.freeze`, `knk.unfreeze`, `knk.kick`,
       `knk.ban`, `knk.admin.user.manage`, checked through the shared per-page permission cache on a player click. It
       renders nothing until one is allowed: anonymous viewers make no request, and a viewer without any node makes only
       the five checks. The user id comes from the existing `GET api/Users/uuid/{uuid}` (new
       `userManagementClient.getByUuid` and a minimal `UserByUuidDto` in `UserProfileSummaryDtos.ts`); a 404 says the
       player has no web account. The actions are "Freeze…" or "Unfreeze" by state (with the reason while frozen),
       "Kick…" and "Ban…". Each one shows only under its own node and goes through the unchanged `usePlayerFreeze` /
       `usePlayerKickBan` (same dialogs, endpoints, toasts and audit entries). "Open profile" links to
       `/admin/users/<id>`. Not touched: the moderation hooks, `PlayerProfilePage`, the bridge, `mapClient.ts`,
       `e2e/fixtures/map.ts`, `objectConfigs`, `entityApiMapping`, the landmark pages. No API change, no migration, no
       flag.
    2. knk-workspace: smoke guide § 9 (8 steps: 3 automated, 4 partly automated, 1 manual only, tagged), spec § 6.3.8
       as built and the last-updated line, changelog entry (merged `origin/next`; both sides of the changelog conflict
       kept).
2. **Commits and heads.** knk-web-app `claude/overview-map-moderation` at `1ff5418` (1 commit on `next` `5501be9`);
   knk-workspace `claude/overview-map-moderation` at `553c751b` (1 commit and a merge of `origin/next`). Both were up
   to date with `origin/next` when the PRs were opened.
3. **PRs.** [knk-web-app#55](https://github.com/PandiO/knk-web-app/pull/55) (`Part of #743`),
   [knk-workspace#765](https://github.com/PandiO/knk-workspace/pull/765) (`Closes #743`), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. Jest `npm run test:ci`: 319 suites / 2741 passed → 320 / 2754 passed (+12 `PlayerModerationPanel.test.tsx`,
       +1 `userManagementClient` `getByUuid`). The existing `usePlayerFreeze` / `usePlayerKickBan` / profile tests are
       unchanged and green.
    2. Playwright, all specs: 191 passed, all green (186 existing + 5 new `overview-map-moderation.spec.ts`; the base was
       not run separately; new fixture
       `e2e/fixtures/mapModeration.ts`).
    3. `tsc --noEmit`, `typecheck:e2e`, `CI=true npm run build`: green → green. Known reds: none.
    4. Acceptance: A20 (e2e "a viewer with only knk.kick ...", Jest; the kick in game by hand, smoke § 9 steps 1–2),
       A21 (e2e logged-in and anonymous, Jest).
    5. CI on `1ff5418`: push runs build-and-test and e2e green; the pull_request runs were still running when this
       block was written (see the final message).
    6. Codex: at its usage limit on both PRs (noted on each PR). No review, so no findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *UUID → user id.* Chosen: the existing `GET api/Users/uuid/{uuid}` (any login), because it needs no API change
       and the map API resolves labels with the same lookup. Alternatives: (a) `userId` in `MapPlayerDto`: an API
       change, and it widens the public allow-list (O32); (b) user search by name: ambiguous, and it needs
       `knk.admin.user.manage`.
    2. *Freeze / Unfreeze.* Chosen: one button by frozen state, as on the profile. Alternatives: (a) both at once, as
       the draft smoke step listed them: one of the two always does nothing.
    3. *Hidden, not disabled.* Chosen: hidden (A20 "sees only Kick", § 5 rule 13). Alternatives: (a) the profile's
       #280 "Requires <node>" disabled buttons: contradicts A20.
    4. *"Open profile" without `knk.admin.user.manage`.* Chosen: shown to every panel viewer, as A20 says; the profile
       page keeps its own gate, so a kick-only moderator gets its "no access" answer (smoke § 9 step 3). Alternatives:
       (a) hide it without the node: contradicts A20.
    5. *Player who left the snapshot.* Chosen: L5's "no longer on the map" without the moderation section.
       Alternatives: (a) keep the section mounted: needs a `MapPlayerPanel` change, and the profile page covers this
       case.
    6. *When the nodes are checked.* Chosen: on the first player click (the panel mounts then; answers are cached for
       the page load). Alternatives: (a) at page load: permission traffic for every logged-in visitor who never clicks
       a player.
6. **Out of scope, noted.** For the developer to decide (no issue filed): A20 combined with the profile's
   `knk.admin.user.manage` route gate means a kick-only moderator's "Open profile" leads to "no access". The admin
   guide and register lines are follow-ups for the documentation issue (PR docs impact).
7. **Notes for later links.** None; L9 is the chain's last link. For the docs session: smoke § 9, spec § 6.3.8.
