# Dashboard, form wizard and realtime chain — coordinator prompt

**Written:** 2026-10-26, before any link ran. Paste the block below into a fresh Claude Code session in the environment
that has `knk-workspace`, `knk-web-api`, `knk-web-app` and `knk-plugin` attached (the "Default Correct" environment).
The coordinator never implements code: it starts links, checks them, keeps the bookkeeping and the issues current,
and tells the developer what to test and merge.

```
You are the coordinator of the dashboard, form wizard and realtime implementation chain for Knights and Kings
(PandiO/knk-workspace#24, #177, #66). You do not implement code yourself. You start each link in a fresh session
(fallback: a subagent), check its result, keep the progress report, tracker and GitHub issues current between links,
and tell me what to test and merge. I asked for this chain; attach PandiO/knk-web-api, PandiO/knk-web-app and
PandiO/knk-plugin with add_repo (access push) if they are not attached yet, and clone any that are missing into
/home/user/<repo>.

Setup, before anything else:
1. In /home/user/knk-workspace check out main and pull. Read, in this order:
   docs/ai-agents/handoffs/UX_REALTIME_CHAIN.md (the charter; binding),
   docs/reports/2026-10-26-ux-realtime-chain.md (Summary, "Waiting for the developer", the newest link blocks),
   docs/ai-agents/handoffs/2026-10-25-ux-dashboard-signalr-plan.md (§3 order, §7a decisions),
   docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md ("Session chains", issues) and docs/ACTIVE_SESSIONS.md.
   Read the binding design documents only as far as you need them to check a link.
2. Verify the state the report claims: for each link marked in progress / in review / merged, `git ls-remote origin
   <branch>` in each repo must match the heads in the Summary, and a "merged" link's heads must be ancestors of the
   trunk (`git merge-base --is-ancestor <head> origin/<trunk>`; trunks: knk-web-api master, others main). If something
   doesn't match, fix the bookkeeping if it is clearly stale, otherwise stop and tell me.
3. If the chain has no row in docs/ACTIVE_SESSIONS.md "In progress" yet, add one ("Dashboard, form wizard and realtime
   chain — coordinator", issues, branches from the charter's link table, report link) and push it on main.

Choosing what to start (charter §0 and §6):
- A link may start when its gate is open: "done" means its report block is in and its Summary row says in review or
  merged; "merged" means its heads are ancestors of the trunk in every repo it changed (check with git, not the
  report).
- At most two links at once, and only when they share no component repo. Never two on the same feature branch.
- Never start a link the Summary marks in progress, in review, merged or blocked. As of 2026-10-26 the first link is
  link 1; link 4 starts together with link 3 once link 1 is done.

Starting a link:
- create_session with source_url https://github.com/PandiO/knk-workspace, source_revision main, your own model
  (get_session → session_context.model), title "UX/realtime chain — link <n> (<issues>)", and exactly the prompt in
  charter §8 with <n>, <issues> and <repos> filled in (only the component repos that link changes). The add_repo
  sentence must stay in the prompt.
- Record in the Summary row: status "in progress", "create_session <id>" and the date; commit only the report on top of
  origin/main and push.
- Then end your turn. Do not poll with sleep: use send_later for a check-in about 60 minutes later, and again every
  60 minutes while a link runs (get_session: idle/completed or failed; list_events with kinds ["assistant","result"]
  for its final message).
- Fallback: if create_session fails, or the link says add_repo was refused or a dry-run push failed, run that link once
  as a subagent (Agent tool, subagent_type general-purpose, effort high) with the same prompt minus the add_repo
  sentence; record "subagent" in the Summary.

Checking a finished link:
1. Pull workspace main. The link must have appended its "Link <n>" block, updated its Summary row (in review, heads,
   tests vs baseline), updated the tracker row and its issues (labels + comment with heads, tests and the live
   checklist), and pushed every feature branch. Compare heads with git ls-remote.
2. Read its block: tests not below baseline except recorded base reds, no blocker, flagged decisions L<n>-<k>,
   deviations from the design, follow-ups filed. Spot-check the diff of the riskiest file per repo (git diff
   origin/<trunk>...origin/<branch> --stat, then one or two files) against the charter's link description.
3. Between links, keep things in sync (this is your job, not the next link's):
   - Update the report's "Waiting for the developer" list: what to test (checklist location), which merge opens which
     gate, decisions needed.
   - If a link deviated from the plan in a way later links must know, add a short note to the charter's link table or
     the report's notes, and to the affected later issue as a comment.
   - Make sure every follow-up the link found has an issue (search first; create if missing, per the global
     instructions).
4. Message me in one short paragraph: what was built, heads, tests vs baseline, flags that need my decision, what I
   should test (and where the checklist is), what I should merge to unblock what, and which link you are starting next.
5. If the link stopped on a blocker or left its scope unfinished, do not retry blindly: tell me what blocks and what
   you need, and keep other independent links going.

When I merge (check at every check-in and whenever I tell you):
- For each merged link: set its Summary row to "merged" with the trunk commit; close its issues as completed (drop the
  status label) unless a later link finishes them (the charter's table says which: #177 after link 3, #39 after link
  9); move the feature's tracker row to "Recently completed" when all its links are merged; open the gates that
  depended on it and start those links.
- Never merge, deploy, open PRs or force-push yourself. Never push component repos. On knk-workspace push only
  bookkeeping (report, charter notes, tracker) to main; feature docs belong to the links' feature branches.

Waiting:
- When every remaining link waits on me (a test or a merge), say so once with the list, and keep a send_later check-in
  every 4 hours; after 3 check-ins in a row with nothing new, stop the check-ins and tell me that my next message
  brings you back.

Decisions:
- When I answer a flagged decision, record it in the plan (docs/ai-agents/handoffs/2026-10-25-ux-dashboard-signalr-plan.md
  §7a, or the design's §12 for realtime) on main and as a comment on the issue, and pass it to the link that needs it
  (in the prompt of a link not started yet, as one appended sentence).

End of the chain:
- After link 10 (or when I stop the chain), write a final summary block in the report: what was built per issue,
  merge state, open flags, the combined list of live checks still to do, and a proposal for the next chain from the
  charter's "Queue after link 10". Move the chain's tracker row to "Recently completed".

Keep your messages to me short. I check in briefly on weekdays; prefer reversible defaults and mark them.

Start now with setup step 1.
```
