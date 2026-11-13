---
name: knk-digest
description: Write the Knights and Kings (K&K) daily digest and post it as one comment on the pinned "Daily digest" issue PandiO/knk-workspace#333. Use when asked to write, post or run the K&K daily digest, or when a scheduled weekday run starts you for it. Covers the six digest sections (ready for test in next, decisions needed, blocked, progress, new ideas, health), where each fact comes from (branches, PRs, issues, chain reports, the sessions board, CI), the quiet-day comment and the rule that the digest reads and reports but changes nothing.
---

# K&K daily digest

You write one comment on PandiO/knk-workspace#333 for the developer, each weekday evening (developer decisions
2026-11-12 and 2026-11-13; [DESIGN § 7](../../../docs/specs/ai-agent-workflow/DESIGN.md#7-manager-digest-and-notifications)).
The developer reads it after work and decides what to test, decide or unblock. Until the manager session exists, a
scheduled task starts a fresh session for this at 16:40 Europe/Amsterdam on weekdays.

## 1. Rules

1. **Read and report only.** Do not merge, push, close, label, comment anywhere else or start sessions. The one write
   is the digest comment on #333. A blocker you find goes into section 3; you do not fix it.
2. **Exactly one digest per weekday.** Before posting, read #333's comments: if a digest comment from today
   (Europe/Amsterdam date) already exists, one whose body starts with `## Daily digest <today's date>`, post nothing
   and stop. Other comments, such as the developer's replies, don't count.
3. **A quiet day still gets a comment:** "Nothing new since the last digest" plus the Health section. A missing
   comment means the run failed (developer decision 2026-11-13).
4. **Every list is numbered** (DESIGN § 4.6), so the developer can answer "2.3: yes". Link every issue, PR and report
   you mention. Keep it short: one line per item, details behind the link.
5. **Since the last digest** means since the creation time of the latest digest comment (`## Daily digest …`) on
   #333; for the first digest,
   the last 24 hours.
6. Commit messages and the comment never name the AI model.

## 2. Gather

Repos: PandiO/knk-workspace, knk-web-api (trunk `master`), knk-web-app, knk-plugin (trunk `main`). Use the GitHub MCP
tools (`list_pull_requests`, `list_issues`, `issue_read`, `pull_request_read`, `actions_list`, `list_commits`) and,
for search, `gh api -X GET search/issues -f q='…'`. Clone knk-workspace if you need its files (it is your session's
repository).

1. **What is in `next` but not on trunk**, per repo: PRs merged into `next` since the last promotion (base `next`,
   merged, merge commit not on trunk: compare with `git log origin/<trunk>..origin/next --merges --first-parent`).
   For each, its issue (`Closes`/`Part of` line), the issue's `tier:` label and its smoke-test guide (a
   `docs/guides/*smoke-test*.md` section or the PR's Testing section).
2. **Decisions:** in each chain progress report changed since the last digest (`docs/reports/*chain*.md` on
   knk-workspace `main`), the "Waiting for the developer" section and agent decisions in new link blocks; open issues
   with a decision or design question waiting on the developer (search `is:open` for "decision" in titles, and
   `status:in-review` issues whose last comment asks the developer something).
3. **Blocked:** the sessions board (`docs/ACTIVE_SESSIONS.md` on `main`, "In progress" and "Paused / blocked") and
   chain reports for rows or links marked blocked; open PRs into `next` with red CI or unresolved review threads older
   than a day.
4. **Progress:** links and PRs merged into `next` since the last digest, grouped by chain or issue; chains started or
   finished (board and reports).
5. **Ideas:** issues labelled `idea` created since the last digest.
6. **Health:**
   1. The latest CI run on `next` and on trunk for knk-web-api (`Build and test`, `Migrations (fresh DB)`),
      knk-web-app (`Build and test`) and knk-plugin (`Build`). A red run on `next` or trunk is the first line of the
      digest, above section 1.
   2. Open `documentation` issues: count, and any older than two weeks (global instructions, Shipping a change: debt
      cap above five or older than two weeks).
   3. Stale claims: "In progress" board rows whose last-updated date is more than three days old.
   4. Open Codex review findings on PRs already merged into `next` (the triage issue PandiO/knk-workspace#391 and any
      newer ones).

## 3. Write

Post with `add_issue_comment` on PandiO/knk-workspace#333, in this layout (sections with nothing in them say "None"):

```markdown
## Daily digest <YYYY-MM-DD>

<only if red: **Red build:** <repo> <branch> <workflow>, <run link>>

### 1. Ready for your test in `next`
1. <tier> <title> (<repo>#<pr>, issue #<n>): smoke steps <link>
### 2. Decisions needed
1. <what, where it is asked, the options in a few words> (<link>)
### 3. Blocked
1. <what is blocked>: <reason>, <what would unblock it> (<link>)
### 4. Progress
1. <chain or issue>: <what merged or finished> (<links>)
### 5. New raw ideas
1. #<n> <title>
### 6. Health
1. CI: next <green/red per repo>, trunk <green/red per repo>
2. Documentation issues: <count open>, oldest <age> (<links when over the cap>)
3. Stale claims: <rows or "none">
4. Open Codex findings on merged work: <count, link>

`next` is <n> merges ahead of trunk in total (<per repo>). Reply here to answer a numbered item.

---
_Generated by [Claude Code](https://claude.ai/code)_
```

Order section 1 biggest first: `tier:3` before `tier:2` before `tier:1`; within a tier, the larger change first. Give
`tier:1` items as one combined line per repo when there are more than five.

## 4. Finish

End with a short message: the comment's link, or why nothing was posted (already posted today, or an error with the
evidence). A run that cannot read GitHub posts nothing and says so; the missing comment is the signal.
