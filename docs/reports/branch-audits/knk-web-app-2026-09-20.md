# Branch audit — knk-web-app (2026-09-20)

**Base branch:** `main` (no `master` branch present).
**`gh` CLI:** not available in this environment — open-PR status could **not** be checked for any branch. Treat every "Open PR?" cell below as unverified; confirm manually on GitHub before acting on any recommendation here.
**Active-session cross-check:** `docs/ACTIVE_SESSIONS.md` (this repo) was read in full. It references only `knk-plugin` branch `gate-structure-animation` as in-progress work; no `knk-web-app` branch is named there. No local `active_sessions.md` file exists inside the `knk-web-app` checkout itself.
**Linear cross-check:** no ticket IDs were inferrable from any commit message or branch name in this repo, so step 6 (Linear match) is a no-op — nothing to report.

**Revision note (same day):** the first pass of this audit classified several branches from `git diff --stat` / `git cherry` counts alone. A follow-up pass read the actual diff content and cross-branch `git cherry` comparisons (not just each branch vs. `main`) for every LIKELY STALE and NEEDS REVIEW branch. That changed the picture materially in three cases — see the per-branch reasons below, all of which now cite specific commits/files rather than "unclear."

**Owner decision (same day, repo owner via chat, not derivable from git alone):** the repo owner (Pandi) reviewed the findings above and made an explicit call that overrides the mechanical classification for some branches — recorded here rather than silently changing the table, since the underlying git facts (e.g. `archive/25/ChatGPT-UIObjectConfig` genuinely having unique functionality) haven't changed, only the decision to accept that loss:
- All branches under the top-level `archive/` namespace are to be treated as archived/not relevant, **including** `archive/25/ChatGPT-UIObjectConfig` and `archive/26/02/world-tasks` — accepting the loss of their confirmed-unique content (the field-validation-rule-builder feature and `WorldTaskCta.tsx` respectively, see the per-branch reasons and Duplicate pair #3 below).
- `archive/25/BoltSupplementation` was already independently classified LIKELY STALE and is covered by the same "archive/ = not relevant" call.
- `integrate/archive/26/02/ChatGPT-UIObjectConfig` (top-level `integrate/` namespace) is also believed not relevant, per the owner, and is being provisionally accepted on that basis.
- `integrate/archive/26/02/UserFeatures` (top-level `integrate/` namespace) is **explicitly held back** — the owner will check this one personally before any decision. Do not delete it on the strength of this report alone. (`UserFeatures`, the plain top-level branch, is unaffected either way: it was already confirmed to be a strict content subset of this branch, so its fate follows whatever is decided for `integrate/archive/26/02/UserFeatures`.)

This section is a decision log, not a new automated classification — the Classification column below still reflects what the git checks alone support.

**Correction (2026-09-20, later same day):** the two passes above both compared each branch to `main` using `git diff main...branch` (three-dot / merge-base-relative) and `git cherry main branch`. Both are blind to a manual squash commit landed directly on `main` that doesn't share a patch-id with the original branch commits — which is exactly what happened here. Grepping `main`'s own log for `merge.*into main` turned up three such commits missed by both earlier passes:

- `7fad30e` "(feat): Merged UserFeatures into Main" — squash-merged **`integrate/archive/26/02/UserFeatures`** into `main`.
- `7a7903a` "(feat): merge ChatGPT-UIObjectConfig into Main" — squash-merged **`integrate/archive/26/02/ChatGPT-UIObjectConfig`** into `main` (230 files, ~46k lines — essentially the whole branch).
- `dfbdeef` "Merged ChatGPT-UIObjectConfig into Main:" — a later, much smaller hand-port of just the field-validation-rule-builder fix from **`archive/25/ChatGPT-UIObjectConfig`** (197 lines, `FieldEditor.tsx`) that Duplicate pair #3 below had flagged as missing from the `integrate/` branch. That gap was already closed by hand before this audit ran.

Recomputing with `git diff main branch` (two-dot, current tips, which correctly reflects squash-merged content) instead of the three-dot fork-point diff:

| Branch | Real remaining diff vs. current `main` | Files that exist only on the branch (nowhere in `main`) |
|---|---|---|
| `UserFeatures` | 63 files, +4586/-11484 | `src/components/Workflow/WorldTaskCta.tsx`, `src/pages/TownCreateWizardPage.tsx` |
| `integrate/archive/26/02/UserFeatures` | 62 files, +5412/-9516 | `src/components/Workflow/WorldTaskCta.tsx`, `src/components/FormWizard/FieldRenderer.tsx` (see note) |
| `archive/25/ChatGPT-UIObjectConfig` | 102 files, +5410/-15479 | `src/components/FormWizard/FieldRenderer.tsx` (see note), `src/components/Workflow/WorldTaskCta.tsx` |
| `integrate/archive/26/02/ChatGPT-UIObjectConfig` | 101 files, +5413/-15665 | same two as above |

Most of the remaining diff in each row is `main` having moved on independently since the squash-merge (net deletions from the branch's perspective, not lost work). Two real findings survive:

1. **`WorldTaskCta.tsx` (284 lines)** — a form-completion CTA component. Confirmed absent from `main` across all four rows above. This is the same gap flagged in the original NEEDS REVIEW reasoning for `archive/26/02/world-tasks`; it's now confirmed to survive the squash-merges too, not just present on branches nobody merged yet.
2. **`TownCreateWizardPage.tsx` (253 lines, a real multi-step town-creation wizard page)** — exists **only** on plain `UserFeatures`. It is **not** on `integrate/archive/26/02/UserFeatures` (most likely deleted in that branch's one extra commit, whose message is literally "A bunch of stuff got removed for some reason") and not on `main`. **This reverses the earlier claim that `UserFeatures` has zero content beyond `integrate/archive/26/02/UserFeatures`** — it does not. `UserFeatures` should not be deleted on the assumption that `integrate/archive/26/02/UserFeatures` (or `main`) already has everything it has.

`src/components/FormWizard/FieldRenderer.tsx` is a false alarm, not a real gap: `main` commit `9c82931` ("Removed unused duplicate of FieldRenderer") deliberately deleted 588 lines of it as dead code, so its absence from `main` is intentional, not lost work.

No equivalent "merge.*into main" marker exists for `gate-animation`, `archive/25/BoltSupplementation`, or `archive/26/02/world-tasks` — those three were not found merged into `main` by any method and the earlier findings for them stand.

## Note on `archive/25/BoltSupplementation` — resolved, not a real divergence

The first pass flagged local vs. remote as diverged (different tip commits). Re-checked with `git merge-base --is-ancestor`: **local `archive/25/BoltSupplementation` is a strict ancestor of `origin/archive/25/BoltSupplementation`** — the local branch ref is simply 4 commits behind its own remote-tracking branch (nobody ran `git pull` on it locally after those commits were pushed). There is no conflicting history, nothing to reconcile. The remote ref (`origin/archive/25/BoltSupplementation`, tip `1831dc0`) is authoritative and treated as "the branch" below; local is not a separate row anymore.

## Branch table

| Branch | Last Commit Date | Author | Merge Status | Open PR? | Unmerged Commits (if any) | Classification | Reason |
|---|---|---|---|---|---|---|---|
| `main` | 2026-02-26 | Pandi Obsidian | n/a (base) | n/a | — | **ACTIVE** | Protected branch (base/default branch). |
| `gate-animation-2` *(current checkout)* | 2026-09-17 | Pandi Obsidian | unmerged — 0 commits behind main, 45 ahead | not checked (`gh` unavailable) | 45 commits unique to branch | **ACTIVE** | Last commit 3 days ago (well within 30 days); contains all of `main`'s history plus 45 new commits — active in-progress work. |
| `feat/m2m-join-creation` *(remote-only, not checked out locally)* | 2026-02-16 | Pandi Oldenzeel (Mac) | **ancestry-merged** (`git merge-base --is-ancestor origin/feat/m2m-join-creation main` = true; 0 commits ahead, 17 behind) | not checked (`gh` unavailable) | none | **SAFE TO DELETE** | Fully contained in `main` by ancestry. Not referenced in `ACTIVE_SESSIONS.md`. |
| `gate-animation` | 2026-02-28 | Pandi Oldenzeel (Mac) | unmerged — non-empty diff (223 files) against `main`; not ancestry-merged | not checked (`gh` unavailable) | 55 commits vs. `main`, but **confirmed zero unique content** — see reason | **LIKELY STALE** | Read the actual commits, not just the diff stat: 51 of `gate-animation`'s 55 commits are shared history with `archive/25/ChatGPT-UIObjectConfig` (same merge-base `c5d3cf5`). The remaining 4 commits are genuinely gate-specific (`1c9df75` gate API client, `ab93f43` gate structure form config, `ec3d49d` icon update, `31f8283` gate config validation test) — and `git cherry gate-animation-2 gate-animation` shows **all 4 of those exact commits already have an equivalent patch in `gate-animation-2`**. Net: `gate-animation` contributes nothing that isn't already covered by keeping `gate-animation-2` + `archive/25/ChatGPT-UIObjectConfig`. Safe to drop once both of those are retained. |
| `archive/25/ChatGPT-UIObjectConfig` | 2026-02-03 | Pandi Obsidian | unmerged — non-empty diff (226 files) against `main`; not ancestry-merged | not checked (`gh` unavailable) | 61 commits vs. `main` (1 already applied: `ca9282e`) | **NEEDS REVIEW** | Forms half of a near-duplicate pair with `integrate/archive/26/02/ChatGPT-UIObjectConfig` — see "Duplicate pairs" below for the resolved recommendation. This branch is the one with the **more complete** content (has a working field-validation-rule-builder feature the other branch lost). |
| `integrate/archive/26/02/ChatGPT-UIObjectConfig` | 2026-02-01 | Pandi Obsidian | unmerged — non-empty diff (226 files) against `main`; not ancestry-merged | not checked (`gh` unavailable) | 62 commits vs. `main` (1 already applied via equivalent patch) | **NEEDS REVIEW** | Other half of the pair. **Missing ~197 lines of real functionality** (`ValidationRuleBuilder`, `fieldValidationRuleClient`, `DisplayConditionBuilder`, value-projection mapping) that `archive/25/ChatGPT-UIObjectConfig` has — confirmed by reading `FieldEditor.tsx`'s actual diff between the two branches. It does add a small "UI Configurations" nav link and one one-line bugfix (`dep.object` vs. `dep` in `DynamicForm.tsx`) that the other branch lacks. Not a clean duplicate — do not delete either side without first porting the missing pieces into whichever one is kept. |
| `UserFeatures` | 2026-02-01 | Pandi Obsidian | unmerged — non-empty diff (257 files) against `main`; not ancestry-merged | not checked (`gh` unavailable) | 67 commits vs. `main`, **confirmed zero unique content** | **LIKELY STALE** | Confirmed by ancestry check, not just file-list overlap: `UserFeatures` is a **strict git ancestor** of `integrate/archive/26/02/UserFeatures` — every single commit on `UserFeatures` is already on the other branch, which has exactly one further commit (`252a487`, itself a squash of two commits including the same "a bunch of stuff got removed" incident seen in the ChatGPT-UIObjectConfig pair). Deleting `UserFeatures` loses nothing as long as `integrate/archive/26/02/UserFeatures` is kept. |
| `integrate/archive/26/02/UserFeatures` | 2026-02-01 | Pandi Obsidian | unmerged — non-empty diff (265 files) against `main`; not ancestry-merged | not checked (`gh` unavailable) | 68 commits vs. `main`, none applied to `main` | **NEEDS REVIEW** | Confirmed keeper of the `UserFeatures` pair (strict superset, see above). Still substantial genuinely-unmerged content (68 commits / 265 files) relative to `main` itself — a human should confirm this feature work is still wanted before any merge/delete decision, this audit only clears it relative to its sibling branch. |
| `archive/26/02/world-tasks` | 2026-02-04 | Pandi Obsidian | unmerged — non-empty diff (3 files, +309/-17) against `main`; not ancestry-merged | not checked (`gh` unavailable) | 1 commit (`17f3cee`), not applied anywhere else | **NEEDS REVIEW** | Checked whether its content survives elsewhere: it does **not**. `src/components/Workflow/WorldTaskCta.tsx` (284 lines, a form-completion CTA component) exists **only** on this branch — it's absent from both `main` and the active `gate-animation-2` branch. Its other two touched files (`FieldEditor.tsx`, `WorldBoundFieldRenderer.tsx`) look like older revisions that `gate-animation-2` has since reworked further, so those two are likely superseded — but `WorldTaskCta.tsx` is real, specific, at-risk content. Do not delete this branch without deciding whether that component still needs to be ported into `gate-animation-2`. |
| `archive/25/BoltSupplementation` (`origin/archive/25/BoltSupplementation`, tip `1831dc0`) | 2025-10-26 | PandiO | unmerged — non-empty diff (82 files) against `main`; not ancestry-merged | not checked (`gh` unavailable) | 29 commits vs. `main` (1 already applied via equivalent patch) | **LIKELY STALE** | Read the actual commit log: this is an early, self-contained "Bolt AI"-generated UI prototype phase (`DataTable`, `StructuresOverview`, `ObjectView`, a Cypress suite, a landing-page slideshow) dated Aug–Oct 2025. Cross-checked with `git cherry` against both `gate-animation-2` and `archive/25/ChatGPT-UIObjectConfig` — essentially no overlap (28 of 29 commits unmatched against each). `main` has its own independently-built `ObjectView.tsx`; `StructuresOverview`/`DataTable` under those names don't exist in `main` at all, i.e. this line of work was not carried forward, it was superseded by a separate rebuild. Reads as an abandoned early prototype rather than live unique work — still flagged for a human glance given its size (82 files) before deleting outright. |

## Summary of counts

- **ACTIVE:** 2 (`main`, `gate-animation-2`)
- **SAFE TO DELETE:** 1 (`feat/m2m-join-creation`)
- **LIKELY STALE:** 3 (`gate-animation`, `UserFeatures`, `archive/25/BoltSupplementation`)
- **NEEDS REVIEW:** 4 (`archive/25/ChatGPT-UIObjectConfig`, `integrate/archive/26/02/ChatGPT-UIObjectConfig`, `integrate/archive/26/02/UserFeatures`, `archive/26/02/world-tasks`)

Total branches analyzed: 10 named branches (`archive/25/BoltSupplementation` now counted once, see resolved-divergence note above), plus `main`.

## Duplicate / overlap pairs

1. **`gate-animation` vs. `gate-animation-2`** — resolved with high confidence. They diverge from a common ancestor rather than one containing the other, but every commit in `gate-animation` that isn't shared history with `archive/25/ChatGPT-UIObjectConfig` has a confirmed equivalent patch already in `gate-animation-2` (`git cherry gate-animation-2 gate-animation`: exactly the 4 gate-specific commits show as already applied). **Recommended keeper: `gate-animation-2`.** `gate-animation` can be dropped once `gate-animation-2` and `archive/25/ChatGPT-UIObjectConfig` (or its content) are retained — it adds nothing beyond those two.

2. **`UserFeatures` vs. `integrate/archive/26/02/UserFeatures`** — resolved with high confidence. Confirmed strict git-ancestor relationship (not just similar file lists): `UserFeatures` is fully contained in `integrate/archive/26/02/UserFeatures`, which has exactly one additional commit on top. **Recommended keeper: `integrate/archive/26/02/UserFeatures`.** `UserFeatures` is redundant.

3. **`archive/25/ChatGPT-UIObjectConfig` vs. `integrate/archive/26/02/ChatGPT-UIObjectConfig`** — **not a clean duplicate**, resolved differently than the first pass guessed. Direct diff between the two tips is small (3 files) and readable in full:
   - `archive/25/ChatGPT-UIObjectConfig` has a working **field-validation-rule-builder** feature (`ValidationRuleBuilder`, `fieldValidationRuleClient`, `DisplayConditionBuilder`, value-projection mapping — ~197 lines in `FieldEditor.tsx` alone) that is **missing** from `integrate/archive/26/02/ChatGPT-UIObjectConfig` (most likely lost during whatever rebase/rework produced the `integrate/` branch — both branches carry a commit referencing "a bunch of stuff got removed for some reason").
   - `integrate/archive/26/02/ChatGPT-UIObjectConfig` has a small "UI Configurations" nav-bar link and a one-line bugfix in `DynamicForm.tsx` (`dep.object` vs. `dep`) that `archive/25/ChatGPT-UIObjectConfig` lacks.
   - **Recommendation:** treat `archive/25/ChatGPT-UIObjectConfig` as primary (it has the larger, functioning feature), port the nav link and the one-line fix over from `integrate/...`, then retire `integrate/archive/26/02/ChatGPT-UIObjectConfig`. This is a manual porting step, not a mechanical delete, so both stay NEEDS REVIEW until that's done.

## Deletion checklist (SAFE TO DELETE only)

- [ ] `feat/m2m-join-creation` (remote-only) — content confirmed already in `main` via ancestry (`git merge-base --is-ancestor origin/feat/m2m-join-creation main`), 0 unique commits, no local checkout to worry about, not referenced in `ACTIVE_SESSIONS.md`. Note: `gh` was unavailable to confirm there's no open PR pointing at this branch — do a manual check on GitHub before deleting.

## Deletion checklist — owner-confirmed (2026-09-20, updated after the correction above)

- [x] `archive/25/ChatGPT-UIObjectConfig` — its one real unique piece (field-validation-rule-builder) is **already in `main`** via `dfbdeef`, confirmed by the correction above, not just accepted-as-lost. Its only remaining gap is `WorldTaskCta.tsx`, shared with the rest of the family (see below). Safe per owner's `archive/` policy, and lower-risk than originally reported.
- [ ] `archive/26/02/world-tasks` — owner accepts loss of `WorldTaskCta.tsx` (284 lines). This is now the **last remaining copy anywhere** once the other `archive/`/`integrate/` branches below are also deleted — worth a final check that nobody wants this component before this branch goes.
- [ ] `archive/25/BoltSupplementation` — already LIKELY STALE by the mechanical checks; owner confirms via the same policy. Unaffected by this correction (no merge marker found for it on `main`).
- [x] `integrate/archive/26/02/ChatGPT-UIObjectConfig` — confirmed **already squash-merged into `main`** via `7a7903a` (230 files, ~46k lines — essentially the full branch). Owner's "not relevant" call is now backed by a direct git finding, not just judgment. Only gap is the shared `WorldTaskCta.tsx`.

## Held back — do not delete without reading this

- **`integrate/archive/26/02/UserFeatures`** — owner is checking this one personally. Confirmed **already squash-merged into `main`** via `7fad30e`; remaining diff is mostly `main`'s later independent work, plus the shared `WorldTaskCta.tsx` gap. Lower-risk than originally reported.
- **`UserFeatures` (plain branch) — re-flagged, do NOT tie its fate to `integrate/archive/26/02/UserFeatures`.** The earlier report said this branch was a pure subset with nothing unique — **that was wrong.** It alone holds `src/pages/TownCreateWizardPage.tsx` (253 lines, a real town-creation wizard page), which is absent from `integrate/archive/26/02/UserFeatures`, from `main`, and from every other branch checked in this audit. If `UserFeatures` is deleted (or left to rot after `integrate/...` is decided on) without someone looking at this file, it is gone for good — there is no other copy anywhere in this repo.

## Cross-branch summary: where does `WorldTaskCta.tsx` actually live?

Confirmed present **only** on: `UserFeatures`, `integrate/archive/26/02/UserFeatures`, `archive/25/ChatGPT-UIObjectConfig`, `integrate/archive/26/02/ChatGPT-UIObjectConfig`, `archive/26/02/world-tasks`. Absent from `main` and from the active `gate-animation-2` branch.

**Owner decision (2026-09-20, later same day): `WorldTaskCta.tsx` is confirmed obsolete.** This was the last remaining real gap on `archive/25/ChatGPT-UIObjectConfig`, `integrate/archive/26/02/ChatGPT-UIObjectConfig`, `integrate/archive/26/02/UserFeatures`, and `archive/26/02/world-tasks` — with this confirmed obsolete, none of those four branches carry any known unrecovered content. Only `TownCreateWizardPage.tsx` on plain `UserFeatures` remains unresolved (see held-back note above — unaffected by this decision, it's a different file).

## Final deletion list (2026-09-20)

Safe to delete now, per the mechanical checks plus the owner decisions recorded in this report:

- [ ] `feat/m2m-join-creation` — ancestry-merged into `main` via a real `git merge` commit (`29d8c37`).
- [ ] `gate-animation` — confirmed zero unique content once `gate-animation-2` and `archive/25/ChatGPT-UIObjectConfig`'s content (already in `main`) are accounted for.
- [ ] `archive/25/ChatGPT-UIObjectConfig` — substantially squash-merged into `main` (`dfbdeef`); its only remaining gap, `WorldTaskCta.tsx`, is now confirmed obsolete.
- [ ] `integrate/archive/26/02/ChatGPT-UIObjectConfig` — squash-merged into `main` (`7a7903a`); same resolved `WorldTaskCta.tsx` gap.
- [ ] `archive/26/02/world-tasks` — its one unique file, `WorldTaskCta.tsx`, is now confirmed obsolete; its other changes were already superseded by `gate-animation-2`.
- [ ] `archive/25/BoltSupplementation` — old, self-contained, unreferenced prototype phase; owner-confirmed via the `archive/` policy.
- [ ] `integrate/archive/26/02/UserFeatures` — squash-merged into `main` (`7fad30e`); its only known gap, `WorldTaskCta.tsx`, is now confirmed obsolete. **Still listed as held-back per the owner's request to check it personally — the data no longer shows a blocker, but the hold stands until the owner says otherwise.**

**Not on this list, do not delete:**
- `UserFeatures` (plain branch) — still holds `TownCreateWizardPage.tsx`, confirmed nowhere else in the repo. Unaffected by the `WorldTaskCta.tsx` decision.
- `main`, `gate-animation-2` — protected / active, never candidates.

## Execution log (2026-09-20)

All 6 branches on the final deletion list above were deleted, both locally and on `origin`:

- [x] `feat/m2m-join-creation` (origin only, no local ref existed)
- [x] `gate-animation`
- [x] `archive/25/ChatGPT-UIObjectConfig`
- [x] `integrate/archive/26/02/ChatGPT-UIObjectConfig`
- [x] `archive/26/02/world-tasks`
- [x] `archive/25/BoltSupplementation`

Confirmed via `git fetch --prune` afterward — repo now has exactly `main`, `gate-animation-2`, `UserFeatures`, `integrate/archive/26/02/UserFeatures` remaining, matching the held-back list above.

**New finding during cleanup, unaudited by any earlier pass:** `origin/25/BoltSupplementation` (no `archive/` prefix) is a *separate ref* that happened to point at the exact same commit (`1831dc0`) as the just-deleted `archive/25/BoltSupplementation` — same content, not new unique work. It is also, unusually, set as this **repository's default branch on GitHub** (`origin/HEAD` pointed to it). `git push origin --delete "25/BoltSupplementation"` was attempted and rejected by GitHub for exactly that reason ("refusing to delete the current branch"). **Action needed from the repo owner:** on GitHub.com, go to Settings → Branches and change the default branch to `main`, then this leftover ref can be deleted. Not done here — outside git's/this tool's reach.
