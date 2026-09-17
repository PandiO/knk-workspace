# Knights and Kings — V3 Documentation Audit Instructions

**Purpose:** with the module scan reports and the consolidated feature-
completeness report in hand (see `v3-codebase-scan-instructions.md`), go
through the existing scattered V3 documentation — knk-workspace, Word/Google
Docs, SMB backups — and decide, per document, whether to **keep, rewrite,
merge, archive, or delete** it. The scans are ground truth about what the
code actually does; every existing doc gets checked against that ground
truth rather than taken at face value.

**Prerequisite:** all three module scans and the consolidated
feature-completeness report must exist before this pass starts — this is a
validation step, not a parallel one.

---

## Step 1 — Inventory the existing docs

Before judging anything, build a flat list of every V3-related document
across:

- `knk-workspace` (all of `docs/`, however currently organized)
- the SMB share (`D:\Shared\Werk\Knightsandkings\`), V3-relevant files only
- any Word/Google Docs the user separately points the session at

For each, record: file path/link, title, apparent topic, last-modified date,
and rough length. This inventory itself is a deliverable —
`docs/reports/v3-doc-inventory-<yyyy-mm-dd>.md` — even before any judgment
is applied, since simply seeing everything in one table is half the value.

## Step 2 — Classify each document

For every document in the inventory, compare its claims against the scan
reports and assign one status:

| Status | Meaning |
|---|---|
| **Keep** | Accurate, current, well-scoped, non-duplicate — matches the scan findings closely enough to trust as-is. Maybe light edits only. |
| **Rewrite** | Topic/scope is still valid and needed, but content is stale, wrong, or contradicts the scan findings — needs to be redone using the scan as source material. |
| **Merge** | Overlaps substantially with one or more other documents — fold into a single doc rather than keep N partial versions. |
| **Archive** | Historically useful (design rationale, decisions, V1/V2 context) but not something a current implementer needs open while working — move to `docs/archive/`. |
| **Delete** | Describes something that was never built, was built and then removed, or is superseded with no remaining reference value. |

For **Rewrite** and **Merge** candidates, note *why* — which specific scan
finding contradicts or outdates the doc — so the rewrite has a clear brief
rather than starting from scratch blind.

For **Delete** candidates, be conservative: if there's any doubt about
historical value, default to Archive instead. Deletion should be reserved
for genuinely redundant or actively misleading content.

## Step 3 — Check for format inconsistency separately from accuracy

A doc can be accurate but still poorly formatted relative to the others.
Track this independently so it doesn't get conflated with the keep/rewrite
decision:

- Does it follow the target structure (`vision/`, `architecture/`, `guides/`,
  `ai-agents/`, `specs/`, `backlog/`, `reports/`, `archive/`) already agreed
  for `knk-workspace`, or does it need to be moved/renamed to fit it?
- Does it use a consistent heading style / metadata header (title, status,
  last-updated) compared to other docs of the same type? If not, note that
  a **Keep** doc may still need a formatting pass, separate from a content
  rewrite.

## Step 4 — Produce the audit report and action plan

Output: `docs/reports/v3-doc-audit-<yyyy-mm-dd>.md`, a table with columns:

`Path/Link | Title | Status (Keep/Rewrite/Merge/Archive/Delete) | Reason | Target location in knk-workspace | Contradicts which scan finding (if any)`

Followed by a short prioritized action list — which rewrites matter most
(usually: anything MVP/siege-minigame related, or anything actively
misleading a current implementation effort) versus which can wait.

## Step 5 — Execute, in a separate pass

Don't execute moves/deletes/rewrites in the same session that produces the
audit report — review the table yourself first, since "delete" and "merge"
are the operations most worth a human sanity check. Once you've approved it,
a follow-up session (or several, split by target folder) can:

- Move Keep/Archive docs to their correct location and apply the format pass.
- Rewrite the Rewrite-flagged docs using the relevant scan report as source.
- Merge the Merge-flagged docs into single documents.
- Delete only what you've explicitly signed off on.

---

## Notes for the human (you)

- This pass is inherently more judgment-heavy than the code scan, so budget
  more of your own review time here rather than fully delegating the
  keep/delete calls — the agent can propose, but you should approve, especially
  for deletions.
- Good candidate order: run this audit doc-folder by doc-folder (e.g. vision
  docs first, then architecture, then feature specs) rather than all at once,
  so each batch is small enough to actually review.
