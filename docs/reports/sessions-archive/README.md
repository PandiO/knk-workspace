# Sessions archive

**Status:** Living index · **Last updated:** 2026-11-12

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
   goes to [undated.md](undated.md).
4. Relative links inside entries were written for the board in `docs/`, so read them as relative to `docs/`.
5. Each file has its own table header; the header is repeated after a row that spans several lines so the next rows
   still render as a table.

## Files

<!-- archive-index:start -->
<!-- archive-index:end -->
