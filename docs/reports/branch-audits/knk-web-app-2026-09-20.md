# Branch audit — knk-web-app (2026-09-20)

**Base branch:** `main` (no `master` branch present).
**`gh` CLI:** not available in this environment — open-PR status could **not** be checked for any branch. Treat every "Open PR?" cell below as unverified; confirm manually on GitHub before acting on any recommendation here.
**Active-session cross-check:** `docs/ACTIVE_SESSIONS.md` (this repo) was read in full. It references only `knk-plugin` branch `gate-structure-animation` as in-progress work; no `knk-web-app` branch is named there. No local `active_sessions.md` file exists inside the `knk-web-app` checkout itself.
**Linear cross-check:** no ticket IDs were inferrable from any commit message or branch name in this repo, so step 6 (Linear match) is a no-op — nothing to report.

## Note on `archive/25/BoltSupplementation`

Local and remote refs for this branch have **diverged** — they are not the same commit:
- local `archive/25/BoltSupplementation` tip: `217d310`, last commit 2025-03-25 ("Squashed commit of the following:")
- `origin/archive/25/BoltSupplementation` tip: `1831dc0`, last commit 2025-10-26 ("Updated package-lock.json")

The remote has commits the local branch never fetched into itself (only into the remote-tracking ref). Both are analyzed separately below; the remote ref is the authoritative one for any GitHub-side action.

## Branch table

| Branch | Last Commit Date | Author | Merge Status | Open PR? | Unmerged Commits (if any) | Classification | Reason |
|---|---|---|---|---|---|---|---|
| `main` | 2026-02-26 | Pandi Obsidian | n/a (base) | n/a | — | **ACTIVE** | Protected branch (base/default branch). |
| `gate-animation-2` *(current checkout)* | 2026-09-17 | Pandi Obsidian | unmerged — 0 commits behind main, 45 ahead | not checked (`gh` unavailable) | 45 commits unique to branch | **ACTIVE** | Last commit 3 days ago (well within 30 days); contains all of `main`'s history plus 45 new commits — active in-progress work. |
| `feat/m2m-join-creation` *(remote-only, not checked out locally)* | 2026-02-16 | Pandi Oldenzeel (Mac) | **ancestry-merged** (`git merge-base --is-ancestor origin/feat/m2m-join-creation main` = true; 0 commits ahead, 17 behind) | not checked (`gh` unavailable) | none | **SAFE TO DELETE** | Fully contained in `main` by ancestry. Not referenced in `ACTIVE_SESSIONS.md`. |
| `gate-animation` | 2026-02-28 | Pandi Oldenzeel (Mac) | unmerged — non-empty diff (223 files), `git cherry`: 54/54 commits shown as `+` (not applied to main) | not checked (`gh` unavailable) | 54 commits, none applied | **LIKELY STALE** | 205 days inactive; superseded by newer duplicate branch `gate-animation-2` (see Duplicate pairs below), which has since diverged from a common ancestor and is the one receiving active commits. |
| `UserFeatures` | 2026-02-01 | Pandi Obsidian | unmerged — non-empty diff (257 files), `git cherry`: 66/66 commits `+` | not checked (`gh` unavailable) | 66 commits, none applied | **LIKELY STALE** | 231 days inactive. `UserFeatures` is a strict git ancestor of `integrate/archive/26/02/UserFeatures` (confirmed via `merge-base --is-ancestor`) — every commit on `UserFeatures` is already contained in that other branch, which has one further commit on top. Deleting `UserFeatures` loses nothing as long as `integrate/archive/26/02/UserFeatures` is kept. |
| `integrate/archive/26/02/UserFeatures` | 2026-02-01 | Pandi Obsidian | unmerged — non-empty diff (265 files), `git cherry`: 67/67 commits `+` | not checked (`gh` unavailable) | 67 commits, none applied | **NEEDS REVIEW** | Superset of `UserFeatures` (see above) — this is the "keeper" of that pair, but its 67 commits / 265 files are substantial, genuinely unmerged, and not obviously trivial. Needs a human decision on whether this work still matters before any deletion. |
| `archive/25/ChatGPT-UIObjectConfig` | 2026-02-03 | Pandi Obsidian | unmerged — non-empty diff (226 files), `git cherry`: 60 `+`, 1 `-` (commit `ca9282e` "Revert \"A bunch of stuff got removed for some reason\"" is already applied to main under a different hash) | not checked (`gh` unavailable) | 60 commits not yet in main (1 of 61 already applied) | **NEEDS REVIEW** | Duplicate/overlap pair with `integrate/archive/26/02/ChatGPT-UIObjectConfig` (see below) — same 226 files touched on both sides, but the two branches diverge from a common ancestor rather than one containing the other, so it isn't obvious which (if either) is safe to drop. |
| `integrate/archive/26/02/ChatGPT-UIObjectConfig` | 2026-02-01 | Pandi Obsidian | unmerged — non-empty diff (226 files), `git cherry`: 61/61 commits `+` | not checked (`gh` unavailable) | 61 commits, none applied | **NEEDS REVIEW** | Other half of the duplicate pair above. |
| `archive/26/02/world-tasks` | 2026-02-04 | Pandi Obsidian | unmerged — non-empty diff (3 files, +309/-17), `git cherry`: 1/1 commit `+` | not checked (`gh` unavailable) | 1 commit ("Merged world-tasks into this branch (world-tasks-2: ...") | **NEEDS REVIEW** | Small in scope (1 commit, 3 files) but the content itself (`FieldEditor.tsx`, `WorldBoundFieldRenderer.tsx`, `WorldTaskCta.tsx` — meaningful UI component changes, not comment-only or WIP markers) does not read as disposable WIP. 229 days inactive with no PR found — worth a quick human look rather than an automatic stale call. |
| `archive/25/BoltSupplementation` (local ref, `217d310`) | 2025-03-25 | Pandi Obsidian | unmerged — non-empty diff (81 files), `git cherry`: 24 `+`, 1 `-` | not checked (`gh` unavailable) | 24 commits not yet in main | **NEEDS REVIEW** | Local ref has diverged from its own remote-tracking branch (see note above) — needs reconciliation before any merge/delete decision is made from either side. |
| `archive/25/BoltSupplementation` (`origin/archive/25/BoltSupplementation`, `1831dc0`) | 2025-10-26 | PandiO | unmerged — non-empty diff (82 files), `git cherry`: 28 `+`, 1 `-` (commit `217d310` "Squashed commit of the following:" already applied to main) | not checked (`gh` unavailable) | 28 commits not yet in main | **NEEDS REVIEW** | Oldest-touched branch in the repo by commit age on the remote side, but 82 files / 28 unapplied commits is substantial content, not trivial WIP. Also see local/remote divergence note above. |

## Summary of counts

- **ACTIVE:** 2 (`main`, `gate-animation-2`)
- **SAFE TO DELETE:** 1 (`feat/m2m-join-creation`)
- **LIKELY STALE:** 2 (`gate-animation`, `UserFeatures`)
- **NEEDS REVIEW:** 6 (`integrate/archive/26/02/UserFeatures`, `archive/25/ChatGPT-UIObjectConfig`, `integrate/archive/26/02/ChatGPT-UIObjectConfig`, `archive/26/02/world-tasks`, `archive/25/BoltSupplementation` local, `archive/25/BoltSupplementation` remote)

Total branches analyzed: 11 (10 named branches, with `archive/25/BoltSupplementation` counted twice for its diverged local/remote refs), plus `main`.

## Duplicate / overlap pairs

1. **`gate-animation` vs. `gate-animation-2`** — both touch gate-structure-animation work. File overlap is only 35 of 223 (`gate-animation`) / 84 (`gate-animation-2`) changed files, and they diverge from a common ancestor rather than one being built on the other — so this looks like an abandoned first attempt (`gate-animation`, last commit 2026-02-28) followed by a restart (`gate-animation-2`, actively committed as recently as 2026-09-17). **Recommended keeper: `gate-animation-2`** — it's the one receiving current work. `gate-animation` is flagged LIKELY STALE above rather than SAFE TO DELETE, since it does carry 54 unique unapplied commits that nobody has confirmed are safe to lose.

2. **`UserFeatures` vs. `integrate/archive/26/02/UserFeatures`** — confirmed strict ancestor relationship: every commit on `UserFeatures` is already present on `integrate/archive/26/02/UserFeatures`, which has exactly one additional commit on top (67 vs. 66 unique-from-main commits; 256 of `UserFeatures`'s 257 changed files also appear in the other branch's diff). **Recommended keeper: `integrate/archive/26/02/UserFeatures`** (strict superset, no content loss). `UserFeatures` is redundant once the superset branch is kept.

3. **`archive/25/ChatGPT-UIObjectConfig` vs. `integrate/archive/26/02/ChatGPT-UIObjectConfig`** — both touch exactly the same 226 files against `main`, but neither is a git ancestor of the other (they diverge from a common commit `b8795e8`), so this is **not** a simple superset case like pair #2. By last-commit date, `archive/25/ChatGPT-UIObjectConfig` (2026-02-03) is marginally more recent than `integrate/archive/26/02/ChatGPT-UIObjectConfig` (2026-02-01) — but the branch naming convention in this repo (`integrate/...` implying a landed/integrated version of an `archive/...` branch) suggests the opposite intent. **No confident keeper recommendation** — this needs a human to actually diff the two branches' content (not just file lists) and decide which one reflects the intended final state. Both are marked NEEDS REVIEW rather than one being called a clear duplicate to drop.

## Deletion checklist (SAFE TO DELETE only)

- [ ] `feat/m2m-join-creation` (remote-only) — content confirmed already in `main` via ancestry (`git merge-base --is-ancestor origin/feat/m2m-join-creation main`), 0 unique commits, no local checkout to worry about, not referenced in `ACTIVE_SESSIONS.md`. Note: `gh` was unavailable to confirm there's no open PR pointing at this branch — do a manual check on GitHub before deleting.

## Needs your judgment (not recommended for removal — surfaced only)

**LIKELY STALE:**
- [ ] `gate-animation` — 205 days inactive, superseded by `gate-animation-2`, but still carries 54 unapplied commits.
- [ ] `UserFeatures` — 231 days inactive, but content is a confirmed strict subset of `integrate/archive/26/02/UserFeatures`.

**NEEDS REVIEW:**
- [ ] `integrate/archive/26/02/UserFeatures` — 67 substantial unapplied commits, 265 files; likely keeper of pair #2 above but not confirmed still wanted.
- [ ] `archive/25/ChatGPT-UIObjectConfig` — half of an ambiguous duplicate pair (#3 above).
- [ ] `integrate/archive/26/02/ChatGPT-UIObjectConfig` — other half of that same ambiguous pair.
- [ ] `archive/26/02/world-tasks` — single non-trivial commit (form/workflow UI changes) never merged; small enough to review quickly.
- [ ] `archive/25/BoltSupplementation` (local ref `217d310`) — diverged from its own remote-tracking branch; reconcile before deciding.
- [ ] `archive/25/BoltSupplementation` (remote ref `1831dc0`) — oldest branch by commit date (2025-10-26 last touch on remote), 28 unapplied commits across 82 files.
