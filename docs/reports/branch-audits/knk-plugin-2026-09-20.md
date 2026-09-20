# Branch Audit — knk-plugin — 2026-09-20

Default branch: `main`. All checks below compare against `origin/main`
(`gh` CLI was not available in this environment, so open-PR status could
**not** be checked for any branch — treat "Open PR?" as unknown rather than
"none" until verified manually, e.g. via the GitHub web UI at
github.com/PandiO/knk-plugin/pulls).

**Read this before trusting the mechanical checks alone.** This repo uses
single-parent "squash" commits to fold feature branches into `main`
(`git log --oneline | grep -i merge` on `main` turns up `(feat): Merged
UserFeatures into Main`, `(feat): Merge DataAccessUnification branch into
Main`, `(feat): Merge WGRegionHandler into Main` — all single-parent, not
real two-parent merges) — the exact same pattern that caused the
`knk-web-api` audit earlier today to initially misclassify four merged
branches as stale. Ancestry (`--merged`) and patch-id matching
(`git cherry`) both miss this, because the squash commit's diff doesn't
patch-id-match the branch's individual commits. This audit therefore did
an extra pass for every branch that failed the standard checks: diffing
the branch tip directly against the specific squash commit that claims to
merge it, and spot-checking whether the files it touches exist (and match)
on current `main`. That pass reversed the classification of five branches
from what ancestry/cherry alone would have suggested.

Note on local vs. remote state: the local checkout has two branches with
unpushed commits beyond their `origin` counterparts —
`integrate/main-wgregionhandler` (8 local-only commits, all enchantment
work already independently confirmed present in `main`, so nothing at
risk) and `gate-structure-animation` (3 local-only commits, dated
2026-09-19 and 2026-09-20 — i.e. today — clearly active in-progress work
that just hasn't been pushed yet). This audit evaluates the **origin
(pushed) refs** throughout, since those are what a branch-deletion
decision actually acts on.

## Branches

| Branch | Last Commit Date | Author | Merge Status | Open PR? | Unmerged Commits (if any) | Classification | Reason |
|---|---|---|---|---|---|---|---|
| `main` | 2026-09-20 | Pandi Obsidian | n/a (default branch) | n/a | n/a | **ACTIVE** | Protected default branch. |
| `gate-structure-animation` | 2026-09-17 (origin) / 2026-09-20 (local) | Pandi Obsidian | unmerged (0 behind, 62 ahead of `main`) | unknown (gh unavailable) | 62 commits, none yet in `main` | **ACTIVE** | Last commit 3 days ago (today, on the unpushed local copy); explicitly referenced in `docs/ACTIVE_SESSIONS.md` under both "In progress" history and "Recently completed" entries dated 2026-09-20. Currently checked out. |
| `UserFeatures` | 2026-02-01 | Pandi Obsidian | content-verified merged (is a git ancestor of `integrate/UserFeatures`, which is itself content-verified merged — see below) | unknown | none | **SAFE TO DELETE** | Ancestry/`git cherry` both say unmerged (17/17 commits unmatched), but that's the squash-commit blind spot described above. `UserFeatures`'s tip is a strict ancestor of `integrate/UserFeatures`'s tip, which matches the `main`-ancestor squash commit `5d8feea` ("Merged UserFeatures into Main") almost exactly. No unique content at risk. |
| `integrate/UserFeatures` | 2026-02-01 | Pandi Obsidian | content-verified merged (99%+ match to squash commit `5d8feea`, confirmed ancestor of `main`) | unknown | none | **SAFE TO DELETE** | `git diff 5d8feea origin/integrate/UserFeatures` is only 138 lines across 3 files, all *removals* `main` made afterward (dead code cleanup in `KnKPlugin.java`, `PlayerListener.java`, one test) — `main` has strictly more cleanup, nothing from this branch is missing. |
| `archive/26/02/DataAccessUnification` | 2026-01-26 | Pandi Obsidian | content-verified merged (exact 0-line diff vs squash commit `f293633`, confirmed ancestor of `main`) | unknown | none | **SAFE TO DELETE** | Byte-identical tree match to `f293633` ("Squashed commit of Data Access Unification feature"), which is a direct ancestor of `main`. |
| `archive/26/02/DataAccessUnificationIntegration` | 2026-02-02 | Pandi Obsidian | content-verified merged (exact 0-line diff vs squash commit `ffc93c5`, confirmed ancestor of `main`) | unknown | none | **SAFE TO DELETE** | Byte-identical tree match to `ffc93c5` ("Merge DataAccessUnification branch into Main"), a direct ancestor of `main`. |
| `archive/26/02/WGRegionHandler` | 2026-02-24 | Pandi Obsidian | mixed — content partially verified, partially genuinely unmerged | unknown | 12 commits not patch-matched to `main`; of those, spot-checked files are mostly present/identical on `main` except `WgRegionIdTaskHandler.java` (95-line divergence — `main`'s version evolved further) and ~20 `spec/*.md` doc files (Towns/Location/Street specs, `CHANGES_SUMMARY.md`, `IMPLEMENTATION_ROADMAP.md`, etc.) that exist on this branch but nowhere on `main` | **NEEDS REVIEW** | Most of the branch's actual feature code (region rename tool, retention task, WorldGuard management command, region HTTP server) is confirmed present and byte-identical on `main` — likely landed via the real two-parent merge `542b6ab` rather than these squash commits. But one handler file has diverged, and the branch carries a batch of spec docs not found anywhere on `main`. Worth a quick look before deleting in case those docs are wanted, but this is very likely safe to delete after that check — it is not "no activity, trivial diff" stale. |
| `integrate/WGRegionHandler` | 2026-02-02 | Pandi Obsidian | content-verified merged (exact 0-line diff vs squash commit `0c5a565`, confirmed ancestor of `main`) | unknown | none | **SAFE TO DELETE** | Byte-identical tree match to `0c5a565` ("Merge WGRegionHandler into Main"), a direct ancestor of `main`. Not a git ancestor of `archive/26/02/WGRegionHandler` (they diverged from a shared starting point — see Duplicate/overlap below), but this one's content landed cleanly. |
| `integrate/main-wgregionhandler` | 2026-02-24 (origin) / 2026-02-26 (local, 8 more commits) | Pandi Obsidian | ancestry-merged — literal git ancestor of `origin/main` | unknown | none | **SAFE TO DELETE** | `git merge-base --is-ancestor` confirms this branch (including the local checkout's 8 extra enchantment-phase commits) is fully contained in `main`'s history via the real two-parent merge `542b6ab`. |
| `CustomEnchantments` | 2026-01-13 | Pandi Oldenzeel (Mac) | cherry-matched — sole commit's patch-id identical to commit `b7bc904` on `main` | unknown | none | **SAFE TO DELETE** | `git cherry` marks the one commit `-` (already applied); verified independently by comparing patch-ids directly — exact match to `b7bc904` ("Initial requirements analysis for Custom Enchantments feature"), which is on `main`. |
| `InventoryMenus` | 2026-01-17 | Pandi Obsidian | unmerged | unknown | 1 commit — "Initial requirement assessment for inventory menus" (adds `docs/INVENTORY_MENU_IMPLEMENTATION_ROADMAP.md`, 1954 lines) | **LIKELY STALE** | Single planning-doc commit (no code), ~8 months old, content confirmed genuinely absent from `main` (no matching file, no log reference), no open PR found, not referenced in `docs/ACTIVE_SESSIONS.md`. Looks like an abandoned early-stage requirements doc rather than a feature that's still wanted — flagged for human review before deletion since it is real (if inactive) content. |

`docs/ACTIVE_SESSIONS.md` in the docs repo references only `gate-structure-animation` (both an in-progress-history entry and two "Recently completed" rows dated 2026-09-20); no other `knk-plugin` branch is mentioned. No Linear issue ID patterns (e.g. `KNK-123`) were found in any branch name or commit message — best-effort check only, no external Linear lookup performed.

## Summary

| Classification | Count |
|---|---|
| ACTIVE | 2 (`main`, `gate-structure-animation`) |
| SAFE TO DELETE | 7 (`UserFeatures`, `integrate/UserFeatures`, `archive/26/02/DataAccessUnification`, `archive/26/02/DataAccessUnificationIntegration`, `integrate/WGRegionHandler`, `integrate/main-wgregionhandler`, `CustomEnchantments`) |
| NEEDS REVIEW | 1 (`archive/26/02/WGRegionHandler`) |
| LIKELY STALE | 1 (`InventoryMenus`) |

## Duplicate / overlap pairs

- **`UserFeatures` vs. `integrate/UserFeatures`** — `UserFeatures` is a strict git ancestor of `integrate/UserFeatures` (same lineage, not a parallel restart). `integrate/UserFeatures` is the natural keeper by construction, but both are now content-verified merged into `main`, so it doesn't matter which is kept — both are recommended for deletion.
- **`archive/26/02/DataAccessUnification` vs. `archive/26/02/DataAccessUnificationIntegration`** — same pattern: `DataAccessUnification` is a strict ancestor of `DataAccessUnificationIntegration`. Both content-verified merged; both recommended for deletion.
- **`archive/26/02/WGRegionHandler` vs. `integrate/WGRegionHandler`** — these are *not* ancestors of each other; `git cherry` shows they share a run of identical early commits (`62c7f28`, `6ab6e78`, `7b339ed`, `3172a41`, `a24ddfb`, `f8025a5`, plus rebased duplicates of several of those) before diverging — a genuine parallel-fork situation, not a simple supersede. `integrate/WGRegionHandler` is the one whose content cleanly landed in `main` (exact match to `0c5a565`) — recommend keeping/deleting it as merged. `archive/26/02/WGRegionHandler` continued on for three more weeks past that point (last commit 2026-02-24 vs. 2026-02-02) with additional commits that only partly show up on `main`; it's the one that needs the human look (see NEEDS REVIEW above), not the automatic "obvious keeper."

## Deletion checklist

- [ ] `UserFeatures` — content confirmed merged (ancestor of `integrate/UserFeatures`, itself matching ancestor-of-`main` squash commit `5d8feea`); no open PR found (unverified, gh unavailable).
- [ ] `integrate/UserFeatures` — content confirmed merged (138-line residual vs. `5d8feea` is `main`-side cleanup only); no open PR found (unverified).
- [ ] `archive/26/02/DataAccessUnification` — content confirmed merged (exact match to ancestor-of-`main` commit `f293633`); no open PR found (unverified).
- [ ] `archive/26/02/DataAccessUnificationIntegration` — content confirmed merged (exact match to ancestor-of-`main` commit `ffc93c5`); no open PR found (unverified).
- [ ] `integrate/WGRegionHandler` — content confirmed merged (exact match to ancestor-of-`main` commit `0c5a565`); no open PR found (unverified).
- [ ] `integrate/main-wgregionhandler` — literal git ancestor of `main`; no open PR found (unverified).
- [ ] `CustomEnchantments` — sole commit's patch-id confirmed identical to `main` commit `b7bc904`; no open PR found (unverified).

## Needs your judgment

**NEEDS REVIEW:**
- [ ] `archive/26/02/WGRegionHandler` — most feature code confirmed present/identical on `main` (likely via the real merge `542b6ab`), but `WgRegionIdTaskHandler.java` has a genuine 95-line divergence and the branch carries ~20 `spec/*.md` files not present anywhere on `main`. Recommend a quick look at whether those docs are wanted before deleting; the code itself is very likely safe to drop.

**LIKELY STALE:**
- [ ] `InventoryMenus` — single 1954-line planning-doc commit from 2026-01-17, content confirmed absent from `main`, no PR, not referenced in `docs/ACTIVE_SESSIONS.md`. Looks abandoned rather than in-flight, but flagged rather than auto-recommended since the content itself was never verified against any other doc location (e.g. it may have been superseded by design work that now lives in the `knk-workspace` docs repo instead of this one — worth a glance there before deleting).

**Not checked:**
- Open PR status for every branch above is **unknown** — the `gh` CLI was not available in this environment. Worth a quick check at github.com/PandiO/knk-plugin/pulls before acting on the checklist above, particularly for `archive/26/02/WGRegionHandler` and `InventoryMenus`.
- Local-only unpushed commits: `gate-structure-animation` has 3 commits (2026-09-19/20) not yet on `origin` — already active/expected, no action needed. `integrate/main-wgregionhandler` has 8 local-only commits, all independently confirmed already present in `main`'s history, so no unique content is at risk there either.
