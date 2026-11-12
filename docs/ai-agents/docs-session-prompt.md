# Docs session prompt

**Status:** Current · **Last updated:** 2026-11-12 (starts at the merge into `next`; finished rows go to the sessions archive; PandiO/knk-workspace#330) · 2026-11-10 (first version, PandiO/knk-workspace#292)

The implementing session uses this prompt when it starts a docs session after a merge: the feature's merge into `next`
once the global branch model applies, until then the merge into the default branch. The steps are in
[global instructions § Shipping a change](GLOBAL_AGENT_INSTRUCTIONS.md#shipping-a-change-documentation). Fill in the
`<…>` parts and send it as the prompt of a new session (`create_session`, `source_url`
`https://github.com/PandiO/knk-workspace`). The weekly docs check uses the same prompt for issues it finds without a
session. Keep the `add_repo` lines in the prompt, because a session can only attach repositories its prompt asks
for.

```text
Docs session for PandiO/knk-workspace#<docs issue> (Docs: <feature>), the documentation follow-up of
PandiO/knk-workspace#<feature issue>. The code is merged: <repo> <branch: next, or the default branch before the
branch model applies> <commit>, ... (PRs: <links>).

Setup: knk-workspace is attached. The code repos are public and readable without attaching: clone what you need with
`git clone --depth 1 -b <branch> https://github.com/PandiO/<repo>` (the branch named above; default branches:
knk-web-api master, knk-web-app main, knk-plugin main).
<Only if the seed is affected:> Attach PandiO/knk-dev-db-seed with add_repo (access read) and clone it.

1. Read AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md, docs/guides/developer/DOCUMENTATION_MAINTENANCE.md
   and docs/ACTIVE_SESSIONS.md. Add a tracker row for this docs issue and set it to status:in-progress.
2. Work through the issue's docs impact list against the merged code and the smoke-test results, not the plan. Use
   the guide minimums in the maintenance guide. Typical items: player guide, admin guide, developer guide or
   architecture doc, the register row, the guides index row in docs/guides/README.md, site/wiki pages, screenshots.
   Write player docs in English, in the terms the current UI uses.
3. If the code disagrees with the issue, the plan or the smoke test, document what the code does, and file a bug or
   decision issue for the difference. Don't document unmerged or unverified behaviour as shipped.
4. Work on branch claude/docs-<docs issue> from knk-workspace <base: next when the code is in next, else main>. When
   done, merge it into that base (docs only, describing merged behaviour): into next take next's updates by merge,
   never rebase, and merge with a merge commit, so the docs reach main with the feature's promotion; into main rebase it
   on main first, as before. Close the docs issue as completed with a comment that lists the files, and move the
   tracker row straight into docs/reports/sessions-archive/<YYYY-MM>.md (current month, newest first), not to
   Recently completed.
5. Anything left over (a guide that needs a decision, screenshots that need a live server) becomes a new
   documentation issue; mention it in the closing comment.
```
