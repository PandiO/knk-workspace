#!/usr/bin/env python3
"""Move finished entries from the sessions board into monthly archive files.

The sessions board (docs/ACTIVE_SESSIONS.md) keeps only in-progress claims.
This script moves every entry of its "## Recently completed" section, verbatim,
into docs/reports/sessions-archive/YYYY-MM.md, chosen by the entry's date.
Everything else on the board ("In progress", "Paused / blocked", the notes at
the top) is left byte for byte as it is.

Entries
    The "Recently completed" section holds two kinds of entry:
    1. A heading entry: a "### ..." line and every line after it up to the next
       heading, table header or "## " section.
    2. A table row: a line starting with "|" under a table header, plus every
       following line that does not start a new row, heading or table (cells
       with a literal line break and prose paragraphs written under a row stay
       with that row).
    Text before the first entry and the table header lines stay on the board.

Date rule (which archive file an entry goes to)
    1. Heading entry: the first YYYY-MM-DD in the heading line.
    2. Table row: the last cell of the row's first line that starts with a
       YYYY-MM-DD date. That is the "Finished" cell of the four-column table,
       or the "Last updated" cell of a row copied in the six-column
       "In progress" layout.
    3. No date found: the entry goes to undated.md.

Archive files
    Each file has a short header, then "## Entries" (heading entries) and
    "## Table rows" (rows under a copy of their table header). New entries
    are merged in newest first; existing entries are never changed, removed or
    reordered. A table header is repeated after a row that spans several lines
    so the next rows render as a table again.

Safety check ("every line exactly once")
    Before writing anything the script compares the planned files with the
    current ones and aborts (exit 2, nothing written) unless:
    1. Every non-blank line of the original board appears on the new board plus
       in the lines added to the archive files exactly as many times as it
       appeared on the board (so a line that is on the board twice must end
       up twice).
    2. Table header and separator lines stay on the board as often as before.
       Archive files may carry any number of copies of them, because each
       archive table starts with its own header. The same goes for the archive
       header lines this script writes (title, status line, intro, section
       headings).
    3. No line of an existing archive file disappears, and existing archive
       entries keep their text and order.
    4. The board outside the "Recently completed" section is unchanged.

Duplicate guard ("already archived")
    The line check only compares the board with the lines this run adds, so
    it cannot see an entry that an earlier run already archived. Before
    anything else the script therefore looks for each entry it would move,
    verbatim (all its lines, as one block at line boundaries), in every
    archive file of the folder, whatever its month. If one is found it aborts
    (exit 2, nothing written) and lists them. This happens when the board was
    taken from a commit older than the archive files, for example after
    merging an archive branch and keeping the other side's board; see the
    archive README, "Merging a branch that ran the script".

Modes
    (default)   move the entries and write the files.
    --dry-run   plan and verify, print what would change, write nothing.
    --check     exit 1 if the board has entries waiting to be archived,
                0 if not; writes nothing.

Exit codes: 0 done / nothing to do, 1 --check found entries, 2 error or
verification failure (nothing written). Running it twice in a row changes
nothing the second time. Python 3 standard library only.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import os
import re
import sys
import tempfile
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_BOARD = REPO_ROOT / "docs" / "ACTIVE_SESSIONS.md"
DEFAULT_ARCHIVE_DIR = REPO_ROOT / "docs" / "reports" / "sessions-archive"

SECTION_RE = re.compile(r"^## Recently completed\s*$", re.IGNORECASE)
SEP_RE = re.compile(r"^\s*\|(\s*:?-{3,}:?\s*\|)+\s*$")
DATE_RE = re.compile(r"(\d{4})-(\d{2})-(\d{2})")
CELL_DATE_RE = re.compile(r"^(\d{4})-(\d{2})-(\d{2})(?!\d)")
LAST_UPDATED_RE = re.compile(r"(\*\*Last updated:\*\* )\d{4}-\d{2}-\d{2}")
ARCHIVE_SECTIONS = ("## Entries", "## Table rows")
SCAFFOLD_PATTERNS = (
    re.compile(r"^# Sessions archive"),
    re.compile(r"^\*\*Status:\*\*"),
    re.compile(r"^## (Entries|Table rows)\s*$"),
)
UNDATED = "undated"
INDEX_START = "<!-- archive-index:start -->"
INDEX_END = "<!-- archive-index:end -->"


class ArchiveError(Exception):
    """Raised when the board cannot be parsed or the line check fails."""


@dataclass
class Entry:
    kind: str  # "heading" or "row"
    lines: list[str]
    header: tuple[str, str] | None = None
    date: str | None = field(default=None)

    @property
    def month(self) -> str:
        return self.date[:7] if self.date else UNDATED


# --------------------------------------------------------------------------
# Parsing


def split_cells(line: str) -> list[str]:
    """Split a table line on pipes outside backtick spans and escapes."""
    cells, cur, tick, i = [], [], False, 0
    while i < len(line):
        ch = line[i]
        if ch == "\\" and i + 1 < len(line):
            cur.append(line[i : i + 2])
            i += 2
            continue
        if ch == "`":
            tick = not tick
        if ch == "|" and not tick:
            cells.append("".join(cur))
            cur = []
        else:
            cur.append(ch)
        i += 1
    cells.append("".join(cur))
    return cells[1:-1] if len(cells) > 2 else cells


def _valid(m: re.Match | None) -> str | None:
    if not m:
        return None
    y, mo, d = (int(g) for g in m.groups())
    try:
        return _dt.date(y, mo, d).isoformat()
    except ValueError:
        return None


def entry_date(entry: Entry) -> str | None:
    first = entry.lines[0]
    if entry.kind == "heading":
        return _valid(DATE_RE.search(first))
    found = None
    for cell in split_cells(first):
        d = _valid(CELL_DATE_RE.match(cell.strip()))
        if d:
            found = d
    return found


def is_header_at(lines: list[str], i: int) -> bool:
    return (
        lines[i].lstrip().startswith("|")
        and not SEP_RE.match(lines[i])
        and i + 1 < len(lines)
        and bool(SEP_RE.match(lines[i + 1]))
    )


def parse_block(lines: list[str]) -> tuple[list[str], list[Entry]]:
    """Return (kept lines, entries) for a block of markdown lines.

    Kept lines are everything that is not part of an entry: text before the
    first entry, table header and separator lines, and "## " lines.
    """
    kept: list[str] = []
    entries: list[Entry] = []
    current: Entry | None = None
    header: tuple[str, str] | None = None
    in_table = False

    def close() -> None:
        nonlocal current
        if current is not None:
            while current.lines and not current.lines[-1].strip():
                current.lines.pop()
            current.date = entry_date(current)
            entries.append(current)
            current = None

    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("## "):
            close()
            in_table = False
            kept.append(line)
        elif is_header_at(lines, i):
            close()
            header = (line, lines[i + 1])
            in_table = True
            kept.extend(header)
            i += 2
            continue
        elif line.startswith("### "):
            close()
            in_table = False
            current = Entry("heading", [line])
        elif in_table and line.lstrip().startswith("|"):
            close()
            current = Entry("row", [line], header=header)
        elif current is not None:
            current.lines.append(line)
        else:
            kept.append(line)
        i += 1
    close()
    return kept, entries


def split_board(text: str) -> tuple[list[str], list[str], list[str]]:
    """Split the board into (before, section, after) line lists."""
    lines = text.split("\n")
    start = next((i for i, l in enumerate(lines) if SECTION_RE.match(l)), None)
    if start is None:
        raise ArchiveError('board has no "## Recently completed" section')
    end = next(
        (i for i in range(start + 1, len(lines)) if lines[i].startswith("## ")),
        len(lines),
    )
    return lines[:start], lines[start:end], lines[end:]


def parse_archive(text: str) -> tuple[list[str], list[Entry], list[Entry]]:
    """Return (preamble, heading entries, row entries) of an archive file."""
    lines = text.rstrip("\n").split("\n")
    cut = len(lines)
    for i, line in enumerate(lines):
        if line.strip() in ARCHIVE_SECTIONS or line.startswith("### ") or (
            is_header_at(lines, i)
        ):
            cut = i
            break
    preamble = lines[:cut]
    while preamble and not preamble[-1].strip():
        preamble.pop()
    _, entries = parse_block(lines[cut:])
    return (
        preamble,
        [e for e in entries if e.kind == "heading"],
        [e for e in entries if e.kind == "row"],
    )


# --------------------------------------------------------------------------
# Rendering


def default_preamble(month: str, today: str) -> list[str]:
    title = (
        "# Sessions archive — undated entries"
        if month == UNDATED
        else f"# Sessions archive — {month}"
    )
    scope = (
        "Entries without a date the archive script could read"
        if month == UNDATED
        else f"Finished entries dated {month}"
    )
    return [
        title,
        "",
        f"**Status:** Archive, append-only · **Last updated:** {today}",
        "",
        f"{scope}, moved verbatim from the [sessions board](../../ACTIVE_SESSIONS.md) by",
        "[`archive_sessions.py`](../../../scripts/sessions-archive/archive_sessions.py), newest first.",
        "Entries are never edited here; see the [index](README.md) for the rules. Relative links inside",
        "entries were written for the board, so read them as relative to `docs/`.",
    ]


def scaffold_lines(month: str) -> set[str]:
    return {l for l in default_preamble(month, "0000-00-00") if l.strip()}


def merge_newest_first(new: list[Entry], old: list[Entry]) -> list[Entry]:
    """Insert new entries (sorted newest first) among the existing ones.

    Existing entries keep their relative order; a new entry goes before the
    first existing entry that is not newer than it.
    """
    new = sorted(new, key=lambda e: e.date or "", reverse=True)
    out, i, j = [], 0, 0
    while i < len(new) and j < len(old):
        if (new[i].date or "") >= (old[j].date or ""):
            out.append(new[i])
            i += 1
        else:
            out.append(old[j])
            j += 1
    return out + new[i:] + old[j:]


def render_archive(
    preamble: list[str], headings: list[Entry], rows: list[Entry]
) -> str:
    out = list(preamble)
    if headings:
        out += ["", "## Entries"]
        for e in headings:
            out += [""] + e.lines
    if rows:
        out += ["", "## Table rows", ""]
        prev: Entry | None = None
        for e in rows:
            if prev is None or e.header != prev.header or len(prev.lines) > 1:
                if prev is not None:
                    out.append("")
                out += list(e.header)
            out += e.lines
            prev = e
    return "\n".join(out) + "\n"


def render_board_section(lines: list[str]) -> list[str]:
    """Section lines with blank runs collapsed and a blank line before tables."""
    out: list[str] = []
    for i, line in enumerate(lines):
        if not line.strip() and out and not out[-1].strip():
            continue
        if is_header_at(lines, i) and out and out[-1].strip():
            out.append("")
        out.append(line)
    while out and not out[-1].strip():
        out.pop()
    out.append("")
    return out


# --------------------------------------------------------------------------
# Planning and verification


@dataclass
class Plan:
    board_old: str
    board_new: str
    archives_old: dict[Path, str | None]
    archives_new: dict[Path, str]
    moved: Counter
    duplicates: list[tuple[str, str]] = field(default_factory=list)

    @property
    def changed(self) -> bool:
        return self.board_new != self.board_old


def read(path: Path) -> str | None:
    return path.read_text(encoding="utf-8") if path.exists() else None


def already_archived(entries: list[Entry], archive_dir: Path) -> list[tuple[str, str]]:
    """Return (first line, archive file name) for every entry that an archive
    file of the folder already holds verbatim, as a block at line boundaries."""
    files = sorted(archive_dir.glob("*.md")) if archive_dir.is_dir() else []
    texts = [
        (p.name, "\n" + p.read_text(encoding="utf-8") + "\n")
        for p in files
        if p.name != "README.md"
    ]
    found = []
    for e in entries:
        block = "\n" + "\n".join(e.lines) + "\n"
        name = next((n for n, t in texts if block in t), None)
        if name:
            found.append((e.lines[0], name))
    return found


def plan(board_path: Path, archive_dir: Path, today: str) -> Plan:
    board_old = board_path.read_text(encoding="utf-8")
    before, section, after = split_board(board_old)
    kept, entries = parse_block(section[1:])
    moved = Counter(e.month for e in entries)
    archives_old: dict[Path, str | None] = {}
    archives_new: dict[Path, str] = {}
    if not entries:
        return Plan(board_old, board_old, archives_old, archives_new, moved)
    duplicates = already_archived(entries, archive_dir)

    for month in sorted(moved):
        path = archive_dir / f"{month}.md"
        old = read(path)
        archives_old[path] = old
        mine = [e for e in entries if e.month == month]
        if old is None:
            preamble, headings, rows = default_preamble(month, today), [], []
        else:
            preamble, headings, rows = parse_archive(old)
            preamble = [LAST_UPDATED_RE.sub(r"\g<1>" + today, l) for l in preamble]
        headings = merge_newest_first([e for e in mine if e.kind == "heading"], headings)
        rows = merge_newest_first([e for e in mine if e.kind == "row"], rows)
        archives_new[path] = render_archive(preamble, headings, rows)

    new_section = render_board_section([section[0], ""] + kept)
    board_new = "\n".join(before + new_section + after)
    return Plan(board_old, board_new, archives_old, archives_new, moved, duplicates)


def check_duplicates(p: Plan) -> None:
    """Raise ArchiveError if an entry to move is already in an archive file."""
    if not p.duplicates:
        return
    n = len(p.duplicates)
    shown = "\n  ".join(f"{name}: {line[:90]!r}" for line, name in p.duplicates[:10])
    more = f"\n  ... and {n - 10} more" if n > 10 else ""
    raise ArchiveError(
        f"{n} entr{'y is' if n == 1 else 'ies are'} already in the archive verbatim; "
        f"archiving {'it' if n == 1 else 'them'} again would duplicate {'it' if n == 1 else 'them'}:\n  "
        f"{shown}{more}\n"
        "The board probably comes from a commit older than the archive files (for example after a merge "
        "that kept the other side's board). Take the board that matches the archive files and apply only "
        "the newer board changes; see docs/reports/sessions-archive/README.md, "
        '"Merging a branch that ran the script".'
    )


def _nonblank(text: str | None) -> Counter:
    if not text:
        return Counter()
    return Counter(l for l in text.split("\n") if l.strip())


def _structure_lines(texts: list[str]) -> set[str]:
    out: set[str] = set()
    for text in texts:
        lines = text.split("\n")
        for i, line in enumerate(lines):
            if SEP_RE.match(line):
                out.add(line)
            elif is_header_at(lines, i):
                out.add(line)
    return out


def _is_subsequence(small: list[tuple], big: list[tuple]) -> bool:
    it = iter(big)
    return all(any(s == b for b in it) for s in small)


def verify(p: Plan) -> None:
    """Raise ArchiveError unless every board line ends up exactly once."""
    check_duplicates(p)
    problems: list[str] = []

    # 4. Board outside the section unchanged.
    b0, s0, a0 = split_board(p.board_old)
    b1, s1, a1 = split_board(p.board_new)
    if b0 != b1 or a0 != a1:
        problems.append('board changed outside "## Recently completed"')

    texts = [p.board_old, p.board_new] + [t for t in p.archives_old.values() if t]
    texts += list(p.archives_new.values())
    structure = _structure_lines(texts)
    scaffold: set[str] = set()
    for path in p.archives_new:
        scaffold |= scaffold_lines(path.stem)

    def is_struct(line: str) -> bool:
        return (
            line in structure
            or line in scaffold
            or any(r.match(line) for r in SCAFFOLD_PATTERNS)
        )

    board0, board1 = _nonblank(p.board_old), _nonblank(p.board_new)
    delta: Counter = Counter()
    for path, new in p.archives_new.items():
        delta.update(_nonblank(new))
        delta.subtract(_nonblank(p.archives_old.get(path)))

    for line in set(board0) | set(board1) | set(delta):
        if is_struct(line):
            if board1[line] != board0[line]:
                problems.append(f"table header/structure line not kept on board: {line[:100]!r}")
            continue
        total = board1[line] + delta[line]
        if delta[line] < 0:
            problems.append(f"line removed from an archive file: {line[:100]!r}")
        elif total < board0[line]:
            problems.append(f"line would be lost: {line[:100]!r}")
        elif total > board0[line]:
            problems.append(f"line would be duplicated or introduced: {line[:100]!r}")

    # 3. Existing archive entries keep text and order.
    for path, old in p.archives_old.items():
        if not old:
            continue
        _, oh, orow = parse_archive(old)
        _, nh, nrow = parse_archive(p.archives_new[path])
        for olds, news in ((oh, nh), (orow, nrow)):
            if not _is_subsequence([tuple(e.lines) for e in olds], [tuple(e.lines) for e in news]):
                problems.append(f"existing entries of {path.name} changed or reordered")

    if problems:
        raise ArchiveError("line check failed:\n  " + "\n  ".join(problems[:20]))


# --------------------------------------------------------------------------
# Index and writing


def update_index(archive_dir: Path, extra: list[Path]) -> tuple[Path, str | None, str] | None:
    """Regenerate the file list between the index markers of README.md."""
    readme = archive_dir / "README.md"
    old = read(readme)
    if old is None or INDEX_START not in old or INDEX_END not in old:
        return None
    names = {p.name for p in archive_dir.glob("*.md") if p.name != "README.md"}
    names |= {p.name for p in extra}
    dated = sorted((n for n in names if n != f"{UNDATED}.md"), reverse=True)
    items = [f"1. [{n[:-3]}]({n})" for n in dated]
    if f"{UNDATED}.md" in names:
        items.append(f"1. [Undated entries]({UNDATED}.md)")
    head, rest = old.split(INDEX_START, 1)
    _, tail = rest.split(INDEX_END, 1)
    new = head + INDEX_START + "\n" + "\n".join(items) + "\n" + INDEX_END + tail
    return readme, old, new


def write_atomic(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o644
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.", suffix=".tmp")
    with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    os.chmod(tmp, mode)
    os.replace(tmp, path)


def size(text: str) -> str:
    return f"{len(text.encode('utf-8'))} bytes, {text.count(chr(10))} lines"


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        description=__doc__.split("\n", 1)[0],
        epilog=__doc__.split("\n", 2)[2],
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--board", type=Path, default=DEFAULT_BOARD)
    ap.add_argument("--archive-dir", type=Path, default=DEFAULT_ARCHIVE_DIR)
    ap.add_argument("--today", help="date for the archive status line (default: today)")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="show the plan, write nothing")
    mode.add_argument("--check", action="store_true", help="exit 1 if entries wait to be archived")
    args = ap.parse_args(argv)
    today = args.today or _dt.date.today().isoformat()

    try:
        p = plan(args.board, args.archive_dir, today)
        if args.check:
            n = sum(p.moved.values())
            print(f"{n} entr{'y' if n == 1 else 'ies'} waiting to be archived")
            if p.duplicates:
                print(f"{len(p.duplicates)} of them already in the archive verbatim (a run would abort)")
            return 1 if n else 0
        if not p.changed:
            print("nothing to archive")
            return 0
        verify(p)
    except ArchiveError as exc:
        print(f"error: {exc}", file=sys.stderr)
        print("nothing written", file=sys.stderr)
        return 2

    print(f"board before: {size(p.board_old)}")
    print(f"board after:  {size(p.board_new)}")
    for path in sorted(p.archives_new):
        verb = "append to" if p.archives_old[path] else "create"
        print(f"{verb} {path.name}: {p.moved[path.stem]} entries")
    index = update_index(args.archive_dir, list(p.archives_new))
    if args.dry_run:
        print("dry run: nothing written")
        return 0
    for path, text in sorted(p.archives_new.items()):
        write_atomic(path, text)
    if index and index[1] != index[2]:
        write_atomic(index[0], index[2])
    write_atomic(args.board, p.board_new)  # last, after the archives exist
    print("done")
    return 0


if __name__ == "__main__":
    sys.exit(main())
