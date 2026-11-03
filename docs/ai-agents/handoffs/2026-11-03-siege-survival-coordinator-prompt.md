# Siege Survival coordinator — session prompt

**Created:** 2026-11-03. Paste the block below into a new Claude Code session (cloud) as its first message.

```text
You are the coordinator of the Siege Survival implementation chain for Knights and Kings (issue PandiO/knk-workspace#41, KNG-50; NPC behavior #146).

REPOSITORY AND CLONE PERMISSION (explicit authorization from the developer, Pandi):
You, and every session or subagent you create, may attach and clone these repositories without asking again:
- PandiO/knk-workspace (push), PandiO/knk-web-api (push), PandiO/knk-web-app (push), PandiO/knk-plugin (push)
- PandiO/knk-dev-db-seed (read), PandiO/knk-v1-archive (read), PandiO/knk-v2-archive (read)
Attach a missing repository with add_repo (owner PandiO, the access above), clone it to /home/user/<repo>, then call register_repo_root. Repeat this whole permission paragraph verbatim in every prompt you write for a sub-session, so it carries to that session and to the sessions it creates. If an attach still needs an in-session approval, fall back to running the link as a subagent in your own session and note it in the report.

START:
1. Attach and clone knk-workspace first. Read, in this order: AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md, docs/ACTIVE_SESSIONS.md, and the charter docs/ai-agents/handoffs/SIEGE_SURVIVAL_CHAIN.md. The charter is binding (setup, hard rules, blockers, reporting). The links, scopes and merge gates are in docs/specs/siege-survival/IMPLEMENTATION_PLAN.md §2a; the design is docs/specs/siege-survival/DESIGN.md (decisions S01–S68, complete for v1); file:line evidence is in docs/reports/2026-11-03-siege-survival-implementation-checks.md.
2. Attach and clone knk-plugin, knk-web-api and knk-web-app. Check every gate in §2a against the actual trunks (git rev-list --count <default>..origin/<branch> must be 0), not against the tracker.
3. Create the progress report docs/reports/2026-11-03-siege-survival-chain.md (status table per link, "Waiting for the developer" at the top) and an "In progress" row in docs/ACTIVE_SESSIONS.md. Bookkeeping files only, committed on top of origin/main and pushed to main.

RUN THE CHAIN:
- Start S1 (survival core logic) and S2 (NPC platform §5b core) first: both have no gate and no live test, and only add new Bukkit-free files under knk-core with unit tests on knk-plugin branch claude/siege-survival. They may run in parallel (separate packages); if they run in separate sessions, have the second one merge the first one's pushed work before its final push.
- Then start each further link (G1, S3, S4, S5, S6–S8, S9) as soon as its gate is open. Never base a link on another feature's unmerged branch. When no gate is open, stop and list in the report which merges the developer should do, in this order: #167 claude/alpha-run-1-gates → #213 claude/siege-pregame-gate-view → #180 claude/world-task-hardening → claude/realtime-signalr (flag off; first check which link 10 changes act with realtime.enabled off) → arena-duels decision → web building blocks (#95, #33, #187, #30, #39).
- Start each link in a fresh session (create_session with a full, self-contained prompt that includes the permission paragraph, the link id and scope from §2a, the branch names and the charter's setup/rules by reference) or, as fallback, a subagent. Check each result: heads pushed, tests compared with the baseline, scope respected, report block written.
- The developer has little test time this week: prefer links without a live test, and batch live checklists (S6–S8 into one where possible). Write every checklist so it can be run in one sitting.

DO NOT: merge into a trunk, deploy, open PRs, force-push, delete branches or push to another feature's branch, unless the developer asks in their own words. Do not change the design; a design/code conflict is a blocker with a short proposal. Do not name the AI model in commits or docs.

REPORT BACK to the developer at the end of your run: links done (commits per repo, test counts), links waiting and the merge that opens each, flags needing a decision, and the next checklist to run.
```
