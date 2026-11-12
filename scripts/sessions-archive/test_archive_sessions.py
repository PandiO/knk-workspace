"""Unit tests for archive_sessions.py (stdlib unittest).

Run from the repo root:
    python3 -m unittest discover -s scripts/sessions-archive -v
"""

from __future__ import annotations

import io
import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import archive_sessions as A  # noqa: E402

HEADER = "| Feature | Repos touched | Finished | Notes / link |"
SEP = "|---|---|---|---|"

BOARD = f"""# Active Sessions

**How to use this file:**
- Keep rows short.

## In progress

| Feature | Repos / files claimed | Owner | Status | Started | Last updated |
|---|---|---|---|---|---|
| Live work | knk-plugin `x` | session | working | 2026-11-01 | 2026-11-12 |

## Recently completed

### 2026-11-12 — Heading entry A — done

Body of A with a [link](specs/a.md).

### 2026-10-30 — Heading entry B (#1)

Body of B.

{HEADER}
{SEP}
| Row one | knk-web-api `a|b` | 2026-11-10 | note one |
| Row two | knk-plugin | 2026-10-04 | note two |
| Row three, six columns | repo | session | done | 2026-09-20 | 2026-09-21 |
| Row four with a line break in a cell | repo | 2026-09-22 | first part
second part of the cell. |

**Verified:** prose written under row four.

| Row five without a date | repo | soon | note |
| Row six duplicate text | repo | 2026-10-04 | note two |

## Paused / blocked

| Feature | Repos / files claimed | Blocked on | Last updated |
|---|---|---|---|
| _(none currently)_ | | | |
"""


def run(argv: list[str]) -> tuple[int, str, str]:
    out, err = io.StringIO(), io.StringIO()
    with redirect_stdout(out), redirect_stderr(err):
        rc = A.main(argv)
    return rc, out.getvalue(), err.getvalue()


class ArchiveTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.board = root / "ACTIVE_SESSIONS.md"
        self.board.write_text(BOARD, encoding="utf-8")
        self.arch = root / "reports" / "sessions-archive"
        self.arch.mkdir(parents=True)
        (self.arch / "README.md").write_text(
            f"# Index\n\n{A.INDEX_START}\n{A.INDEX_END}\n", encoding="utf-8"
        )
        self.args = ["--board", str(self.board), "--archive-dir", str(self.arch), "--today", "2026-11-12"]

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def snapshot(self) -> dict[str, str]:
        root = Path(self.tmp.name)
        return {str(p.relative_to(root)): p.read_text(encoding="utf-8") for p in sorted(root.rglob("*.md"))}

    # ------------------------------------------------------------------

    def test_parse_dates(self) -> None:
        _, section, _ = A.split_board(BOARD)
        kept, entries = A.parse_block(section[1:])
        self.assertEqual(
            [(e.kind, e.month) for e in entries],
            [
                ("heading", "2026-11"),
                ("heading", "2026-10"),
                ("row", "2026-11"),
                ("row", "2026-10"),
                ("row", "2026-09"),  # six columns: last date cell = Last updated
                ("row", "2026-09"),
                ("row", "undated"),
                ("row", "2026-10"),
            ],
        )
        self.assertEqual(entries[4].date, "2026-09-21")
        self.assertIn(HEADER, kept)
        self.assertIn("**Verified:** prose written under row four.", entries[5].lines)
        self.assertEqual(entries[5].lines[1], "second part of the cell. |")

    def test_dry_run_writes_nothing(self) -> None:
        before = self.snapshot()
        rc, out, _ = run(self.args + ["--dry-run"])
        self.assertEqual(rc, 0)
        self.assertIn("dry run: nothing written", out)
        self.assertIn("create 2026-10.md: 3 entries", out)
        self.assertEqual(self.snapshot(), before)

    def test_check_mode(self) -> None:
        before = self.snapshot()
        rc, out, _ = run(self.args + ["--check"])
        self.assertEqual(rc, 1)
        self.assertIn("8 entries waiting", out)
        self.assertEqual(self.snapshot(), before)
        self.assertEqual(run(self.args)[0], 0)
        self.assertEqual(run(self.args + ["--check"])[0], 0)

    def test_run_moves_everything_and_keeps_the_rest(self) -> None:
        rc, _, err = run(self.args)
        self.assertEqual(rc, 0, err)
        board = self.board.read_text(encoding="utf-8")
        before, _, after = A.split_board(BOARD)
        nbefore, nsection, nafter = A.split_board(board)
        self.assertEqual((before, after), (nbefore, nafter))
        self.assertEqual(nsection, ["## Recently completed", "", HEADER, SEP, ""])

        oct_ = (self.arch / "2026-10.md").read_text(encoding="utf-8")
        self.assertTrue(oct_.startswith("# Sessions archive — 2026-10\n"))
        self.assertIn("### 2026-10-30 — Heading entry B (#1)\n\nBody of B.", oct_)
        self.assertEqual(oct_.count("| note two |"), 2)
        sep_ = (self.arch / "2026-09.md").read_text(encoding="utf-8")
        # the table header is repeated after the multi-line row four
        self.assertLess(sep_.index("Row four"), sep_.index("Row three"))  # newest first
        self.assertEqual(sep_.count(HEADER), 2)
        self.assertTrue((self.arch / "undated.md").exists())
        readme = (self.arch / "README.md").read_text(encoding="utf-8")
        self.assertIn("1. [2026-11](2026-11.md)\n1. [2026-10](2026-10.md)\n1. [2026-09](2026-09.md)\n1. [Undated entries](undated.md)", readme)

        # every non-blank original line present exactly once (headers aside)
        total = A._nonblank(board)
        for p in self.arch.glob("[0-9u]*.md"):
            total.update(A._nonblank(p.read_text(encoding="utf-8")))
        for line, n in A._nonblank(BOARD).items():
            if line not in (HEADER, SEP):
                self.assertEqual(total[line], n, line)

    def test_second_run_changes_nothing(self) -> None:
        self.assertEqual(run(self.args)[0], 0)
        first = self.snapshot()
        rc, out, _ = run(self.args + ["--today", "2026-12-01"])
        self.assertEqual(rc, 0)
        self.assertIn("nothing to archive", out)
        self.assertEqual(self.snapshot(), first)

    def test_appends_to_existing_month_without_rewriting(self) -> None:
        self.assertEqual(run(self.args)[0], 0)
        old_nov = (self.arch / "2026-11.md").read_text(encoding="utf-8")
        _, old_head, old_rows = A.parse_archive(old_nov)

        board = self.board.read_text(encoding="utf-8").replace(
            "## Recently completed\n",
            "## Recently completed\n\n### 2026-11-13 — Newer heading\n\nNew body.\n"
            "\n### 2026-11-01 — Older heading in the same month\n\nOlder body.\n",
        ).replace(SEP + "\n\n## Paused", SEP + "\n| New row | repo | 2026-11-11 | n |\n\n## Paused")
        self.board.write_text(board, encoding="utf-8")
        rc, _, err = run(self.args + ["--today", "2026-11-13"])
        self.assertEqual(rc, 0, err)

        new_nov = (self.arch / "2026-11.md").read_text(encoding="utf-8")
        _, new_head, new_rows = A.parse_archive(new_nov)
        self.assertEqual(
            [e.lines[0] for e in new_head],
            [
                "### 2026-11-13 — Newer heading",
                "### 2026-11-12 — Heading entry A — done",
                "### 2026-11-01 — Older heading in the same month",
            ],
        )
        self.assertEqual([e.lines for e in new_head if e.date == "2026-11-12"], [e.lines for e in old_head])
        self.assertEqual([e.lines[0][:9] for e in new_rows], ["| New row", "| Row one"])
        self.assertIn("**Last updated:** 2026-11-13", new_nov)
        # other months untouched
        self.assertNotIn("Newer heading", (self.arch / "2026-10.md").read_text(encoding="utf-8"))

    def _assert_aborts(self) -> None:
        before = self.snapshot()
        rc, _, err = run(self.args)
        self.assertEqual(rc, 2)
        self.assertIn("line check failed", err)
        self.assertIn("nothing written", err)
        self.assertEqual(self.snapshot(), before)

    def test_abort_when_a_line_would_be_lost(self) -> None:
        real = A.render_archive

        def drop_last_line(preamble, headings, rows):
            return "\n".join(real(preamble, headings, rows).rstrip("\n").split("\n")[:-1]) + "\n"

        with mock.patch.object(A, "render_archive", drop_last_line):
            self._assert_aborts()

    def test_abort_when_a_line_would_be_duplicated(self) -> None:
        real = A.render_archive

        def duplicate(preamble, headings, rows):
            return real(preamble, headings + headings[:1], rows)

        with mock.patch.object(A, "render_archive", duplicate):
            self._assert_aborts()

    def test_abort_when_an_existing_archive_line_would_go(self) -> None:
        (self.arch / "2026-10.md").write_text(
            "# Sessions archive — 2026-10\n\n**Status:** Archive, append-only · **Last updated:** 2026-10-31\n\n"
            "## Entries\n\n### 2026-10-01 — Old entry\n\nOld body.\n",
            encoding="utf-8",
        )
        real = A.parse_archive

        def forget_entries(text):
            pre, _, rows = real(text)
            return pre, [], rows

        with mock.patch.object(A, "parse_archive", forget_entries):
            self._assert_aborts()

    def test_abort_when_in_progress_would_change(self) -> None:
        real = A.plan

        def tamper(*a, **k):
            p = real(*a, **k)
            p.board_new = p.board_new.replace("| working |", "| paused |")
            return p

        with mock.patch.object(A, "plan", tamper):
            self._assert_aborts()

    def test_missing_section_is_an_error(self) -> None:
        self.board.write_text("# Board\n\n## In progress\n", encoding="utf-8")
        rc, _, err = run(self.args)
        self.assertEqual(rc, 2)
        self.assertIn("Recently completed", err)


if __name__ == "__main__":
    unittest.main()
