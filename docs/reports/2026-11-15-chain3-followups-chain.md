# Chain 3 follow-ups chain — progress report

**Status:** Running (2026-11-15) · **Last updated:** 2026-11-15

**Issue:** [PandiO/knk-workspace#564](https://github.com/PandiO/knk-workspace/issues/564), links
[#399](https://github.com/PandiO/knk-workspace/issues/399) (L1),
[#290](https://github.com/PandiO/knk-workspace/issues/290) (L2),
[#289](https://github.com/PandiO/knk-workspace/issues/289) (L3),
[#291](https://github.com/PandiO/knk-workspace/issues/291) (L4),
[#288](https://github.com/PandiO/knk-workspace/issues/288) (L5),
[#565](https://github.com/PandiO/knk-workspace/issues/565) (L6, part of #119)
**Charter:** [handoffs/CHAIN3_FOLLOWUPS_CHAIN.md](../ai-agents/handoffs/CHAIN3_FOLLOWUPS_CHAIN.md).

## 1. Waiting for the developer

1. **Before L6 (#565): kick and ban from the web?** Optional item 5 of the #119 API needs: a staff command relay to the
   game server (realtime `PlayerKick`/`PlayerBan` with reason, audited, with nodes). It changes moderation behaviour,
   so it needs your yes/no. Without an answer, L6 builds items 1–4 only.

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 Temp region releases | #399 | Done, in review (2026-11-15) | knk-web-api `a0b5ff3f`, knk-workspace `86adf724` | [knk-web-api#33](https://github.com/PandiO/knk-web-api/pull/33), [knk-workspace#572](https://github.com/PandiO/knk-workspace/pull/572) | green (runs 43702385149, 43702462646) | create_session session_01R1w2Uvbubw539aKYxgnvjR |
| L2 List field cards at 390 px | #290 | Done, in review (2026-11-15) | web-app `8cb616b`, workspace `b61c6456` | [web-app#38](https://github.com/PandiO/knk-web-app/pull/38), [#571](https://github.com/PandiO/knk-workspace/pull/571) | green (PR run); push-run flake #573 | create_session session_01R1w2UswAebrDAEEFqUHA3e |
| L3 "Show what uses it" for more refusals | #289 | Not started | — | — | — | — |
| L4 Builder rules and templates into the draft | #291 | Not started | — | — | — | — |
| L5 Lookup applies picker filters | #288 | Not started | — | — | — | — |
| L6 Player profile API part | #565 | Not started | — | — | — | — |

## 3. Coordinator decisions

1. **Rule set.** Chosen: the `next` branch model (links branch from `next`, PRs into `next`, the coordinator merges),
   because `.github/workflows/ci.yml` is on `origin/main` of knk-web-api and knk-web-app (checked 2026-11-15).
   Alternatives: (a) old rules, developer merges: no longer apply once CI runs on both trunks.
2. **Bookkeeping on `main`.** Chosen: push bookkeeping commits directly to knk-workspace `main`, because global
   instructions "Branches" rules 9–10 (on `main` `d0a9baf9`) say the knk-workspace ruleset only blocks deletion and
   force pushes and a push dry run to `main` succeeds. Alternatives: (a) a bookkeeping PR merged by me, as the chain
   prompt suggested in case direct pushes are refused: the fallback if a real push is refused.
3. **#119 as a link.** Chosen: a new sub-issue #565 for the API part, because #119 is already a sub-issue of #24 and an
   issue has one parent; moving it would drop it from the UX roadmap. Alternatives: (a) re-parent #119 to #564;
   (b) link #119 without a sub-issue: the chain rules scope every link by its sub-issue.
4. **Tiers.** Chosen: as the developer listed them (#399, #290, #289 `tier:1`; #291, #288, #565 `tier:2`); parent
   #564 `tier:2` (highest of its links).
5. **Decisions in the developer's go.** Recorded on #291 (rules and add-from-template into the draft, option 2) and
   #288 (lookup applies narrowing filters, labels only), so the links don't ask again. Kick/ban for L6 is not settled
   by the go ("ask the developer before building anything that changes moderation behaviour beyond the issue"): asked
   in § 1, default without an answer is to leave it out. Alternatives: (a) let L6 ask: subagent links cannot ask
   (staff chain lesson, decision 11 of its report).
6. **Order and parallelism.** Chosen: L1 ∥ L2, then L3, L4, L5, L6 in the developer's order, because L1 is API-only
   and L2 web-only; L3 is web-only and waits for L2; L4–L6 change both repos. Alternatives: (a) run L3 in parallel
   with L1 if it needs no API: L1 holds knk-web-api only briefly, so the gain is small and L3 may need the API.
7. **Overlap check (2026-11-15).** No open PRs in knk-web-api or knk-web-app; no unmerged `claude/*` branch changes
   `TempRegionReleaseService` or `FormWizard/FieldRenderers.tsx`. The staff chain's L3 (#407) is running on
   `PlayerProfilePage.tsx`: not a blocker for L1–L5; L6 rechecks it and keeps to separate lines. Alternatives: (a) hold
   L6 until the staff chain finishes: decided at L6's start.
8. **Route.** Chosen: `create_session` (variant A) for L1 and L2 with model `claude-opus-5-5`, because each needs one
   component repo; subagents for L4–L6 (two component repos, coordinator skill § 4.1.4). Fallback a subagent.
9. **#387.** Not merged (PR #553 into `next` open): links use today's nodes and say so.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_

### 4.1 L1 — Temp region releases: serverId required, no starvation (#399)

1. **Scope done.**
    1. knk-web-api `Controllers/WorldTasksController.cs`: `GET api/WorldTasks/temp-region-releases` answers 400 `{ error: "serverId is required." }` for a blank or missing `serverId`, as `GET open` does.
    2. knk-web-api `Services/TempRegionReleaseService.cs`: `ListDueAsync` reads the due rows by id in pages of `ScanLimit` (200) until `max` are listed or no due row is left; an Information log when more than a page waited. `ScanLimit` is now `public const` for the tests.
    3. knk-workspace docs: `architecture/managed-worldguard-regions.md` §7, `specs/world-tasks/README.md` endpoint table, `CHANGELOG.md` "Unreleased" entry. Plugin contract unchanged.
2. **Commits and heads.** knk-web-api `claude/temp-region-releases-399` at `a0b5ff3f` (1 commit, base `next` at `dcbb1f8`); knk-workspace `claude/temp-region-releases-399` at `86adf724` (1 commit plus a merge of `origin/next` for the CHANGELOG, both entries kept).
3. **PRs.** [knk-web-api#33](https://github.com/PandiO/knk-web-api/pull/33) (Part of #399), [knk-workspace#572](https://github.com/PandiO/knk-workspace/pull/572) (Closes #399), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-api: baseline on `next` `dcbb1f8`: build 0 errors, 4169 passed, 98 skipped (MySQL, no `KNK_TEST_MYSQL`); result: 4175 passed, 98 skipped, 0 failed (6 new: `ListTempRegionReleases_NeedsAServerId` ×3, `ListTempRegionReleases_PassesTheServerAndMax`, `ListDue_MoreThanAPageOfWaitingRows_DoesNotHideALaterRelease` (checked red on the old service), `ListDue_StopsAtMax_AcrossPages`; own/unassigned releases still covered by `ListDue_ReleasesOfAnotherServerAreLeftOut_UnknownServerGoesToAll`). CI runs 43702385149 / 43702462646 (build-and-test, fresh-database) green.
    2. Known reds: none.
    3. Smoke guide: no step changes.
    4. Codex: at its code-review usage limit on both PRs (said so on each); no findings to handle.
5. **Decisions (DESIGN § 4.3).**
    1. *Starvation fix.* Chosen: page by id past the rows looked at, in one call, because it needs no migration and keeps the oldest-first order. Alternatives: (a) "last checked" column ordering: a migration and a write per poll; (b) an in-memory cursor across calls: a release can still wait several polls, lost on restart.
    2. *Cost bound.* Chosen: no page cap, because the 30-day keep period bounds the table. Alternatives: (a) a cap of N pages: starvation again past N×200 waiting rows.
    3. *Where the 400 lives.* Chosen: the controller only, like `GET open`. Alternatives: (a) throw in the service: no other caller, more churn.
6. **Out of scope, noted.** None.
7. **Blockers.** None.
8. **At merge / what the developer must do.** Nothing beyond merging (no settings, migrations or plugin `config.yml` keys).
9. **Notes for later links.** None; permission nodes not needed (#387 not merged).

### 4.2 L2 — List field cards at 390 px (#290)

1. **Scope done.**
    1. knk-web-app `components/FormWizard/FieldRenderers.tsx` `ListField`: the "Selected (n):" cards wrap at narrow
       widths. The name block keeps at least 12rem and the first line; × and **Edit instance** move to their own line
       under it; a long name wraps (`break-words`) instead of being truncated. Desktop: one row as before. The cards
       are a labelled list (`<ul aria-label="Selected <field label>">`); the name uses `text-success-strong` instead
       of the raw `text-green-900`.
    2. knk-web-app `e2e/form-wizard-list-field.spec.ts` (new, mocked API) and `structureForm` / `structureMetadata`
       in `e2e/fixtures/forms.ts`: 390 px (name fully visible, buttons on screen and not over the name, no sideways
       scroll, × still removes) and 1280 px (one row: name, ×, Edit instance).
    3. knk-workspace: smoke guide `relation-picker-and-delete-details-smoke-test.md` § 6.2–6.3 (both `[automated]`),
       `docs/CHANGELOG.md` entry under Unreleased.
2. **Commits and heads.** knk-web-app `claude/list-field-cards-290` at `8cb616b` (1 commit, base `next` at
   `4278102`); knk-workspace `claude/list-field-cards-290` at `b61c6456` (1 commit, base `next`).
3. **PRs.** [PandiO/knk-web-app#38](https://github.com/PandiO/knk-web-app/pull/38) (Part of #290),
   [PandiO/knk-workspace#571](https://github.com/PandiO/knk-workspace/pull/571) (Closes #290), base `next`. Not merged.
4. **Tests, baseline → result.**
    1. knk-web-app: baseline on `next` `4278102` Jest 304 suites / 2615 tests passed, `tsc` clean, build compiled,
       Playwright 110 passed, `lint:colors` 2389; result on the branch Jest 2615 passed, `tsc` and `typecheck:e2e`
       clean, build compiled, Playwright 112 passed (2 new), `lint:colors` 2388. The new 390 px test fails on the old
       layout (name 26 px wide for 187 px of text); the desktop test passes on old and new. CI: PR run [43702120631](https://github.com/PandiO/knk-web-app/actions/runs/43702120631) e2e and
       build-and-test green; the push run [43702068462](https://github.com/PandiO/knk-web-app/actions/runs/43702068462) e2e red in the
       untouched `e2e/data-table.spec.ts:36` (Enter on a header, try and retry), green in the PR run of the same commit
       and 15/15 locally: a flake, filed as [#573](https://github.com/PandiO/knk-workspace/issues/573).
    2. Known reds (also red on the base): none.
5. **Decisions (DESIGN § 4.3).**
    1. *Wrap or icon button.* Chosen: wrap (buttons on their own line), because the "Edit instance" label stays
       readable and the Jest tests that find it by name keep working. Alternatives: (a) icon-only Edit button: hides
       the label, needs an aria-label, changes desktop too; (b) hide the ID line on phones: frees no width.
    2. *Long names.* Chosen: wrap instead of truncate at every width, because a typical name looks the same and a
       long one stays readable. Alternatives: (a) keep `truncate`: a name longer than the row is still cut;
       (b) wrap on phones only: a breakpoint rule for no gain.
    3. *Colour.* Chosen: `text-success-strong` (text on success tints) for the name. Alternatives: (a) keep
       `text-green-900`: a raw colour in a line already changed.
    4. *Picker list in the spec.* Chosen: the spec presses Escape to close the picker's result list before using the
       card, and #570 tracks the picker bug. Alternatives: (a) fix the picker here: `RelationPicker.tsx` is outside the
       charter's `ListField` scope; (b) click × twice: hides the bug in the test.
6. **Out of scope, noted.** [#570](https://github.com/PandiO/knk-workspace/issues/570): in a relation picker, the first
   tap outside the open result list misses (the in-flow list closes on blur, the page shrinks and moves under the
   pointer).
7. **Blockers.** None. Codex: at its code-review usage limit on both PRs (said so on each); no findings handled.
8. **At merge / what the developer must do.** Nothing beyond merging. No settings, migrations or permission nodes
   (#387 not needed).
9. **Notes for later links.** L3 (knk-web-app): `FieldRenderers.tsx` `ListField` changed only in the selected-cards
   block; the e2e fixture `structureForm` (Structure form with a Districts list field) and the `Districts/search` mock
   in `e2e/form-wizard-list-field.spec.ts` can be reused. Open the picker list and press Escape before clicking near it
   (#570).
