# Progress report template

One report per chain at `docs/reports/<date>-<feature>-chain.md` on knk-workspace `main` (chain bookkeeping: commit only
this file, the charter or `docs/ACTIVE_SESSIONS.md` on top of `origin/main`, push `HEAD:main`; on a conflict fetch,
rebase that one commit and keep both sides). The coordinator creates it at its first run and keeps sections 1–3
current. Each link appends its block to section 4 and updates its own summary row. Blocks are append-only: a later
correction is a new dated line in the block, not a rewrite.

Copy from the line below, replace every `<...>` and delete the hints in parentheses.

---

```markdown
# <Feature> chain — progress report

**Status:** <Running | Paused (why) | Done> (<date>) · **Last updated:** <date>

**Issue:** [PandiO/knk-workspace#<parent>](https://github.com/PandiO/knk-workspace/issues/<parent>), links
[#<n>](https://github.com/PandiO/knk-workspace/issues/<n>) (L1), ...
**Charter:** [handoffs/<FEATURE>_CHAIN.md](../ai-agents/handoffs/<FEATURE>_CHAIN.md).

## 1. Waiting for the developer

(Kept current by the coordinator. Only what needs the developer: blockers, decisions, live tests, merges or promotion,
settings the agents cannot change. Write "Nothing." when empty.)

1. <item>

## 2. Summary

| Link | Issue | Status | Branch heads | PR | CI | How started |
|---|---|---|---|---|---|---|
| L1 <title> | #<n> | <Not started / Running / In review / Merged into next / Blocked (why)> | `<branch>`: <repo> `<sha>`, ... | <PR links> | <green / red / none> | <create_session session_... / subagent (reason)> |

## 3. Coordinator decisions

(Numbered. Each: what was decided, why, and every alternative considered; DESIGN § 4.3.)

1. **<Topic>.** Chosen: <option>, because <reason>. Alternatives: (a) <...>; (b) <...>.

## 4. Link blocks

_(Each link appends its block here when it finishes.)_
```

---

## Link block (appended by the link under "## 4. Link blocks")

```markdown
### 4.<n> L<n> — <title> (#<sub-issue>)

1. **Scope done.** <numbered sub-items: what changed, per repo and file area>
2. **Commits and heads.** <repo> `<branch>` at `<sha>` (<count> commits, base `<next|default>` at `<sha>`), ...
3. **PRs.** <links>, base `<next|default>`. Not merged.
4. **Tests, baseline → result.**
    1. <repo>: baseline on `<base>` <counts>; result on the branch <counts>; CI run <id> <green/red>.
    2. Known reds (also red on the base): <list or "none">.
5. **Decisions (DESIGN § 4.3).**
    1. *<Topic>.* Chosen: <option>, because <reason>. Alternatives: (a) <...>; (b) <...>.
6. **Out of scope, noted.** <issue numbers filed or commented, or "None">.
7. **Blockers.** <what, evidence, proposal; or "None">.
8. **At merge / what the developer must do.** <numbered: settings, labels, migrations, live checks, config keys with
   the YAML; or "Nothing beyond merging">.
9. **Notes for later links.** <or "None">.
```
