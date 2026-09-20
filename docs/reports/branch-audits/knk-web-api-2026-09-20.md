# Branch Audit — knk-web-api — 2026-09-20

Default branch: `master`. All checks below compare against `origin/master`
(`gh` CLI was not available in this environment, so open-PR status could
**not** be checked for any branch — treat "Open PR?" as unknown rather than
"none" until verified manually, e.g. via the GitHub web UI).

Note on local vs. remote state: the local checkout of
`archive/26/02/world-task-locationcapture` has 32 commits not present on
`origin/archive/26/02/world-task-locationcapture` (and is missing 30 commits
that *are* on origin), i.e. this working copy has diverged significantly
from the pushed branch. This audit evaluates the **origin (pushed) refs**
throughout, since those are what a deletion/cleanup decision actually acts
on — the local divergence is a separate, working-copy-only issue worth
flagging to whoever owns this checkout, not a branch-hygiene issue in the
shared repo.

## Branches

| Branch | Last Commit Date | Author | Merge Status | Open PR? | Unmerged Commits (if any) | Classification | Reason |
|---|---|---|---|---|---|---|---|
| `master` | 2026-02-26 | Pandi Obsidian | n/a (default branch) | n/a | n/a | **ACTIVE** | Protected default branch. |
| `gate-animation` | 2026-09-17 | Pandi Obsidian | unmerged (41 ahead, 0 behind) | unknown (gh unavailable) | 40 commits, none yet in master | **ACTIVE** | Currently checked-out branch; last commit 3 days ago, well within the 30-day window. |
| `UserFeatures` | 2026-02-01 | Pandi Obsidian | unmerged (23 ahead, 35 behind); `git cherry`: 23/23 not applied | unknown | All 23 commits (e.g. "feat: implement v2.0 registration flow with deferred link code generation") | **NEEDS REVIEW** | Real, non-trivial unmerged feature (registration flow v2.0), no activity in 231 days. Also the "keeper" side of a duplicate pair — see below; identical HEAD commit (`33ab4e1`) to `integrate/archive/26/02/UserFeatures`. |
| `integrate/archive/26/02/UserFeatures` | 2026-02-01 | Pandi Obsidian | unmerged (23 ahead, 35 behind); `git cherry`: 23/23 not applied | unknown | Same 23 commits as `UserFeatures` | **LIKELY STALE** | Points at the exact same commit (`33ab4e1`) as `UserFeatures` — zero unique content. No activity in 231 days, no open PR found, not referenced in `ACTIVE_SESSIONS.md`. Redundant name for the same branch; superseded by `UserFeatures` per duplicate check below. |
| `domainRegionMessages` | 2026-01-29 | Pandi Obsidian | unmerged (18 ahead, 35 behind); `git cherry`: 18/18 not applied | unknown | All 18 commits (e.g. "fix(validation): validate draft health checks") | **LIKELY STALE** | Strict ancestor of `integrate/domainRegionMessages` (see duplicate check) — every commit here is also on that branch, plus 2 more and a later date. No activity in 234 days, not referenced in `ACTIVE_SESSIONS.md`. Superseded by the integrate branch. |
| `integrate/domainRegionMessages` (local name: `integrate/archive/26/02/domainRegionMessages`) | 2026-02-01 | Pandi Obsidian | unmerged (20 ahead, 35 behind); `git cherry`: 20/20 not applied | unknown | All 20 commits, incl. "feat(users): add web-app-first account linking endpoint" (the 2 commits beyond `domainRegionMessages`) | **NEEDS REVIEW** | Real unmerged feature work (account linking, draft health-check validation), superset/keeper of the `domainRegionMessages` pair, 231 days inactive. Decide whether to finish integrating or abandon. |
| `archive/26/02/world-task-locationcapture` | 2026-02-26 | Pandi Obsidian | unmerged by ancestry/diff, but **cherry-matched 29/30** | unknown | 1 commit: `1e315f3` "feat(api): add enchantment ability extension model" (2026-02-25) | **NEEDS REVIEW** | 29 of 30 commits are already applied to `master` under different hashes (`git cherry` shows `-` for all but one) — master's "Merge branch 'world-task-locationcapture'" commit brought nearly everything in already. Only `1e315f3` (a real, non-trivial change: new `AbilityDefinition` model, EF migration, service + repository changes, and tests — 11 files, 2164 lines) is genuinely at risk of being lost if this branch is deleted. Per audit rules, this must go to NEEDS REVIEW rather than a delete recommendation despite the branch otherwise looking abandoned (206 days inactive). |

No branch is a candidate for **SAFE TO DELETE**: none are merged into `master` by ancestry, none have an empty diff against `master`, and none have *all* commits cherry-matched (the closest, `archive/26/02/world-task-locationcapture`, is missing exactly one).

`ACTIVE_SESSIONS.md` in the docs repo does not reference any `knk-web-api` branch by name (it currently only tracks `knk-plugin`'s `gate-structure-animation` work). No Linear issue references were inferrable from these commit messages (best-effort check only).

## Summary

| Classification | Count |
|---|---|
| ACTIVE | 2 (`master`, `gate-animation`) |
| SAFE TO DELETE | 0 |
| LIKELY STALE | 2 (`integrate/archive/26/02/UserFeatures`, `domainRegionMessages`) |
| NEEDS REVIEW | 3 (`UserFeatures`, `integrate/domainRegionMessages`, `archive/26/02/world-task-locationcapture`) |

## Duplicate / overlap pairs

- **`UserFeatures` vs. `integrate/archive/26/02/UserFeatures`** — identical HEAD commit (`33ab4e1`), i.e. these are literally the same content under two names. **Recommended keeper: `UserFeatures`** (shorter, canonical name; the `integrate/` prefix suggests it was meant as a temporary staging copy). Once a human confirms `UserFeatures` is being kept, `integrate/archive/26/02/UserFeatures` can be deleted with zero content loss — but it's held in LIKELY STALE rather than SAFE TO DELETE here because the underlying feature itself is still unmerged into `master`.
- **`domainRegionMessages` vs. `integrate/domainRegionMessages`** — `domainRegionMessages` is a strict git ancestor of `integrate/domainRegionMessages` (confirmed via `git merge-base --is-ancestor`); the integrate branch contains every commit from `domainRegionMessages` plus 2 more ("Updated from Main" and "feat(users): add web-app-first account linking endpoint"), and has a later last-commit date. **Recommended keeper: `integrate/domainRegionMessages`** — it's the strictly-newer, more-complete version. `domainRegionMessages` can be deleted without any content loss once `integrate/domainRegionMessages` is confirmed as the branch being carried forward.

## Deletion checklist

No branches currently qualify as SAFE TO DELETE under this audit's rules — every unmerged branch has at least some content not yet cherry-matched into `master` (or is an unmerged duplicate whose *sibling* copy, not the branch itself, is the redundant one). Nothing is checked off below; this section is intentionally empty pending human review of the NEEDS REVIEW / LIKELY STALE branches above.

- [ ] _(none — see "Needs your judgment" below)_

## Needs your judgment

**LIKELY STALE:**
- [ ] `integrate/archive/26/02/UserFeatures` — exact duplicate of `UserFeatures` (same commit), 231 days inactive. Delete only after confirming `UserFeatures` is the copy being kept.
- [ ] `domainRegionMessages` — strict subset of `integrate/domainRegionMessages`, 234 days inactive. Delete only after confirming `integrate/domainRegionMessages` is the copy being kept.

**NEEDS REVIEW:**
- [ ] `UserFeatures` — 23 unmerged commits implementing a v2.0 registration flow, 231 days inactive. Decide: finish/merge, or intentionally abandon (and if abandoning, take `integrate/archive/26/02/UserFeatures` with it).
- [ ] `integrate/domainRegionMessages` — 20 unmerged commits (draft health-check validation + web-app-first account linking), 231 days inactive. Decide: finish/merge, or abandon (and take `domainRegionMessages` with it).
- [ ] `archive/26/02/world-task-locationcapture` — 29/30 commits already merged into `master` under different hashes; only `1e315f3` ("feat(api): add enchantment ability extension model" — new `AbilityDefinition` model, EF migration, service/repository wiring, tests) is unique and unmerged. Recommend cherry-picking that one commit onto `master` (or a fresh short-lived branch) before deleting this branch, rather than deleting it outright.

**Also flagged (not a branch-classification issue, but surfaced during this audit):**
- The local checkout of `archive/26/02/world-task-locationcapture` in this environment has 32 commits that were never pushed to `origin/archive/26/02/world-task-locationcapture` (and is 30 commits behind what *is* on origin). Whoever owns that checkout should reconcile it — it currently only exists locally.

**Not checked:**
- Open PR status for every branch above is **unknown** — the `gh` CLI was not available in this environment. Verify manually before deleting anything with a real reason to suspect an open PR (e.g. via github.com/PandiO/knk-web-api/pulls).
