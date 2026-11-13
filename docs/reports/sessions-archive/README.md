# Sessions archive

**Status:** Living index · **Last updated:** 2026-11-13

Finished entries from the [sessions board](../../ACTIVE_SESSIONS.md), one file per month
([DESIGN § 8](../../specs/ai-agent-workflow/DESIGN.md)). The board keeps only in-progress claims; when a session
finishes, its row moves here verbatim. Nothing is deleted.

## Rules

1. A finished row goes to the file of the month it finished (`YYYY-MM.md`), newest first. Entries already in a file
   are never edited, removed or reordered.
2. [`scripts/sessions-archive/archive_sessions.py`](../../../scripts/sessions-archive/archive_sessions.py) does the
   move: it takes every entry of the board's "Recently completed" section, picks the month from the entry's date and
   checks, before writing, that every line of the board ends up exactly once on the board or in the archive. Run it
   with `--dry-run` first to see the plan; `--check` exits 1 while entries are waiting. Its `--help` holds the full
   rules.
3. Which date counts: a `### YYYY-MM-DD — ...` heading's date; for a table row, the last cell that starts with a date
   (the "Finished" cell, or "Last updated" for a row in the six-column "In progress" layout). An entry with no date
   goes to `undated.md` (created only when such an entry turns up).
4. Relative links inside entries were written for the board in `docs/`, so read them as relative to `docs/`.
5. Each file has its own table header; the header is repeated after a row that spans several lines so the next rows
   still render as a table.
6. **Duplicate guard.** The script refuses to run (exit 2, nothing written) when an entry it would move is already in
   any archive file verbatim, and lists those entries. `--check` reports them too. This stops the wrong merge below.

## Merging a branch that ran the script

The board changes all day, so a branch that ran the script holds a board and archive files that are older than the
default branch's board by the time it merges. Two ways to bring it in:

1. **Preferred: run the script on fresh `main`.** Do not merge the branch's generated commit (the one that changes
   `docs/ACTIVE_SESSIONS.md` and the `YYYY-MM.md` files).
    1. `git switch main && git pull`.
    2. Cherry-pick only the branch's commits that change the script, its tests and this README, oldest first. The pull
       request names them; for PandiO/knk-workspace#336 see its "Admin steps". A conflict on the board's "How to use"
       lines: keep both sides.
    3. `python3 scripts/sessions-archive/archive_sessions.py --dry-run`, then without `--dry-run`, then `--check`
       (expect `0 entries waiting to be archived`).
    4. Commit the board and the archive files, push `main`.
2. **If the branch was already merged** (or must be merged whole), `docs/ACTIVE_SESSIONS.md` conflicts. Taking the
   default branch's board and running the script is wrong: that board still lists every entry the branch already
   archived, and the duplicate guard now stops the run. Instead:
    1. Take the branch's board: in the merge, `git checkout --theirs docs/ACTIVE_SESSIONS.md` (when merging the branch
       into `main`; `--ours` when merging `main` into the branch), then `git add docs/ACTIVE_SESSIONS.md`.
    2. Apply only the default branch's board changes since the merge base:
       `git diff $(git merge-base HEAD MERGE_HEAD) main -- docs/ACTIVE_SESSIONS.md > /tmp/board.diff`, then
       `git apply --3way /tmp/board.diff` (use the branch name for `main` and `MERGE_HEAD` as fits the direction).
    3. In a conflict hunk in "Recently completed", keep only the entries the default branch added there since the merge
       base; drop the old entries, which are already archived. Keep the default branch's side of every other hunk
       ("In progress", "Paused / blocked").
    4. `git add docs/ACTIVE_SESSIONS.md`, finish the merge, then run the script as in way 1, items 3 and 4. It moves only
       the new entries; if it stops with "already in the archive verbatim", an old entry is still on the board.

## Files

<!-- archive-index:start -->
1. [2026-11](2026-11.md)
1. [2026-10](2026-10.md)
1. [2026-09](2026-09.md)
<!-- archive-index:end -->
