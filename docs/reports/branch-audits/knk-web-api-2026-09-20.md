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
| `UserFeatures` | 2026-02-01 | Pandi Obsidian | content-verified merged (squash commit `6b4ceb4`, "Merge UserFeatures into Main") | unknown | none | **SAFE TO DELETE** (deleted) | Original mechanical checks (ancestry/empty-diff/`git cherry`) all missed this — `6b4ceb4` is a single-parent squash commit, so it's an ancestor of `master` but `origin/UserFeatures`'s own tip isn't, and `master` kept evolving afterward. Manually verified: of the 44 files added by this branch, all are functionally present in current `master` (23 byte-identical, 12 further modified since, 9 renamed/regenerated — see correction note below); `LinkCode`/`UserAuth` functionality confirmed present via symbol grep across `master`. |
| `integrate/archive/26/02/UserFeatures` | 2026-02-01 | Pandi Obsidian | content-verified merged (identical HEAD `33ab4e1` to `UserFeatures`, which is merged — see above) | unknown | none | **SAFE TO DELETE** (deleted) | Exact duplicate of `UserFeatures` (same commit hash), which is confirmed merged above. |
| `domainRegionMessages` | 2026-01-29 | Pandi Obsidian | content-verified merged (squash commit `8eda9d4`, "Merge domainRegionMessages into Main") | unknown | none | **SAFE TO DELETE** (deleted) | Same squash-merge pattern as `UserFeatures`. All 21 newly-added files from this branch are present in current `master` (9 identical, 12 further modified since). |
| `integrate/domainRegionMessages` (local name: `integrate/archive/26/02/domainRegionMessages`) | 2026-02-01 | Pandi Obsidian | content-verified merged — superset of `domainRegionMessages` (merged, see above) plus one extra commit whose content is also confirmed present in `master` | unknown | none functionally, but **not deleted this pass** — see note | **NEEDS REVIEW → likely SAFE TO DELETE, held back pending explicit confirmation** | All files touched by the one extra commit ("feat(users): add web-app-first account linking endpoint", `c1bc4ce`) exist in `master`, and `git grep` confirms `LinkMinecraftAccountAsync`/`link-minecraft-account` are present. Functionally this branch looks fully merged too, same as its sibling — but it wasn't named in the 2026-09-20 deletion request, so it was intentionally left alone this pass rather than deleted on inference. Recommend deleting in a follow-up once confirmed. |
| `archive/26/02/world-task-locationcapture` | 2026-02-26 | Pandi Obsidian | content-verified merged (`3d89802`, "Merge branch 'world-task-locationcapture'") | unknown | none | **SAFE TO DELETE** (deleted) | Originally flagged NEEDS REVIEW because `git cherry` showed 1 of 30 commits (`1e315f3`, "feat(api): add enchantment ability extension model") as not patch-matched into `master`. Manually verified this was a false negative: `master` contains the identical migration file `Migrations/20260225171241_AddAbilityDefinitionExtensionModel.cs` plus `Models/Item/AbilityDefinition.cs` and the associated service/repository/test files — same content, different commit hash (the patch-id changed slightly because of surrounding-context differences from other work applied in between). |

`ACTIVE_SESSIONS.md` in the docs repo does not reference any `knk-web-api` branch by name (it currently only tracks `knk-plugin`'s `gate-structure-animation` work). No Linear issue references were inferrable from these commit messages (best-effort check only).

## Correction (2026-09-20, same-day follow-up)

The initial pass of this audit classified `UserFeatures`, `integrate/archive/26/02/UserFeatures`, `domainRegionMessages`, and `archive/26/02/world-task-locationcapture` as LIKELY STALE / NEEDS REVIEW, because the three mechanical checks this audit relies on (ancestry, empty-diff-against-`master`-tip, and `git cherry` patch-id matching) all under-reported what was actually merged. The repo owner supplied the actual merge-commit hashes (`6b4ceb4`, `8eda9d4`, `3d89802`), which were then independently verified — not merely trusted — by checking that:

1. each merge commit is a real ancestor of `origin/master`,
2. the files each branch introduced are present (byte-identical or since-modified, not missing) in current `master`, and
3. for the one apparent gap (`1e315f3` on `archive/26/02/world-task-locationcapture`), the same migration/model/service content exists in `master` under a different commit hash.

Root cause: these were **squash-style single-parent "merge" commits** (not real 2-parent git merges), made against the branch's fork point rather than current `master` tip, and `master` continued to evolve afterward (EF migrations got regenerated with new timestamps, some top-level changelog/phase-report markdown files were cleaned up). That combination defeats ancestry checks, empty-diff checks, and patch-id-based `git cherry` checks simultaneously, even though the content is genuinely merged. This is a useful pattern to watch for in future audits of this repo: **if a branch's last commit predates a same-day commit titled "Merge X into Main" that *is* an ancestor of `master`, check content presence directly (added-file diff + symbol grep) rather than trusting the mechanical checks alone.**

These four branches, plus their local counterparts, were deleted per explicit user request after the above verification (see Execution log).

## Summary

| Classification | Count |
|---|---|
| ACTIVE | 2 (`master`, `gate-animation`) |
| SAFE TO DELETE (deleted) | 4 (`UserFeatures`, `integrate/archive/26/02/UserFeatures`, `domainRegionMessages`, `archive/26/02/world-task-locationcapture`) |
| NEEDS REVIEW | 1 (`integrate/domainRegionMessages` — functionally merged per above, held back pending explicit confirmation) |
| LIKELY STALE | 0 |

## Duplicate / overlap pairs

- **`UserFeatures` vs. `integrate/archive/26/02/UserFeatures`** — identical HEAD commit (`33ab4e1`). Both confirmed merged into `master`; both deleted.
- **`domainRegionMessages` vs. `integrate/domainRegionMessages`** — `domainRegionMessages` is a strict git ancestor of `integrate/domainRegionMessages`. Both are now confirmed merged into `master` in substance. `domainRegionMessages` was deleted; `integrate/domainRegionMessages` was intentionally left in place pending explicit confirmation (see table above).

## Deletion checklist

- [x] `UserFeatures` — content confirmed merged via squash commit `6b4ceb4`; deleted locally and on `origin` 2026-09-20.
- [x] `integrate/archive/26/02/UserFeatures` — exact duplicate of `UserFeatures` (same commit); deleted locally and on `origin` 2026-09-20.
- [x] `domainRegionMessages` — content confirmed merged via squash commit `8eda9d4`; deleted locally and on `origin` 2026-09-20.
- [x] `archive/26/02/world-task-locationcapture` — content confirmed merged via `3d89802`, including the one commit `git cherry` had missed; deleted locally and on `origin` 2026-09-20.

## Needs your judgment

**NEEDS REVIEW:**
- [ ] `integrate/domainRegionMessages` — functionally merged per the correction above (superset of the now-deleted `domainRegionMessages`, plus one more commit also confirmed present in `master`), but not named in the 2026-09-20 deletion request, so left in place. Recommend a follow-up confirmation to delete it too.

**Also flagged (not a branch-classification issue, but surfaced during this audit):**
- The local checkout of `archive/26/02/world-task-locationcapture` in this environment had 32 commits that were never pushed to `origin/archive/26/02/world-task-locationcapture` (and was 30 commits behind what *was* on origin) before this branch was deleted. Those local-only commits no longer have a remote home now that the origin branch is gone — whoever owns that local checkout should check whether that unpushed work is still needed (it may still be recoverable locally via reflog/`git fsck` if the local branch ref is later needed, but it is not on `origin` or in `master`).

**Not checked:**
- Open PR status for every branch above is **unknown** — the `gh` CLI was not available in this environment. This wasn't re-verified before deletion; if any of the four deleted branches had an open PR pointing at it, that PR is now pointing at a deleted branch (GitHub does not delete the PR itself, but it can no longer be merged as-is). Worth a quick check at github.com/PandiO/knk-web-api/pulls if there's reason to think one existed.

## Execution log (2026-09-20)

All four branches on the deletion checklist above were deleted, both locally (in the `Repository/knk-web-api` checkout under this workspace) and on `origin`:

- [x] `UserFeatures` (local `33ab4e1`, origin deleted)
- [x] `domainRegionMessages` (local `ea1422d`, origin deleted)
- [x] `archive/26/02/world-task-locationcapture` (local `6e00821`, origin deleted)
- [x] `integrate/archive/26/02/UserFeatures` (local `33ab4e1`, origin deleted)

`gate-animation` (active) and `master` (default) were untouched. `integrate/domainRegionMessages` was untouched per the "Needs your judgment" note above.
