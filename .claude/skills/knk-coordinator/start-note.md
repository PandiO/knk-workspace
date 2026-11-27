# Coordinator start note template

The prompt a coordinator gives the fresh coordinator it starts at a hand-over (`knk-coordinator` § 3.9). It carries
only what the new session cannot read in the charter and the progress report: who is running, what to take over and
what comes next. Bring the charter and the report up to date first (§ 3.9 step 1); the note points at them instead of
repeating them.

Copy from the line below, replace every `<...>` and delete the hints in parentheses.

---

```markdown
## 0. Repository permission

(The chain's § 0 permissions block, filled in and pasted verbatim from the link prompts of this chain, with the
coordinator as its subject. A pointer is not enough.)

## 1. Who you are

1. Load the `knk-coordinator` skill (knk-workspace `.claude/skills/knk-coordinator/`) and follow it; start at § 3.10
   ("Starting as a fresh coordinator").
2. You are coordinator <n> of the <Chain> chain (parent PandiO/knk-workspace#<parent>). You take over from
   `<old session id>`, which handed over on <date> because of <the phase boundary after <group> | the 300k ceiling |
   a cold-cache wake-up above 200k>, at <context>k context. It has ended: send it nothing.
3. Charter: `docs/ai-agents/handoffs/<FEATURE>_CHAIN.md`. Progress report: `docs/reports/<date>-<feature>-chain.md`.
   Read the charter, report § 1–3, the newest link block (§ 4.<n>) and the open sub-issues; not the whole report.
4. Rule set (§ 1.3): <the `next` branch model applies | old rules: nobody in the chain merges>, <and the charter's
   exceptions, such as links from `main`>.
5. Model for link sessions: <model id>.

## 2. Running now

(One line per running link, or "Nothing runs.". Every link here was told your session id by `send_message`.)

1. L<n> (#<sub-issue>): `create_session` `<session id>`, <working | handed over, PR #<n> waits for <...>>; last
   checked <time>.

## 3. Take over

1. **PR subscriptions:** call `subscribe_pr_activity` for <PandiO/<repo>#<n>, ...> (I have unsubscribed). Or "None".
2. **Check-in:** schedule one `send_later` check-in for all running links at about <time> (§ 5.5). Mine are
   cancelled. Or "None: nothing runs".
3. **Owed answers or pending messages:** <a question a link asked that waits for the developer, ...>. Or "None".

## 4. Next

1. **Next gate:** <L<n> once <gate>, checked with <command>>. **Next hand-over point:** <after group ...>.
2. **Waiting for the developer:** report § 1 items <numbers>, or "Nothing".
3. **Notes:** <anything the charter and the report don't say yet; normally nothing>.
```
