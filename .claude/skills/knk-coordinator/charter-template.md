# Chain charter template

A charter holds only what is particular to one chain: its links, gates and binding documents. Setup, hard rules,
blockers and the report block format are in the `knk-link` skill; the loop, starting links, checks and merges are in the
`knk-coordinator` skill. Do not copy them into the charter. Put a charter at
`docs/ai-agents/handoffs/<FEATURE>_CHAIN.md` on knk-workspace `main` (chain bookkeeping). The design session drafts it
(DESIGN § 4.2.3); the coordinator completes it at its first run.

Copy from the line below, replace every `<...>` and delete the hints in parentheses.

---

```markdown
# <Feature> chain — charter

**Status:** <Ready to start | Running | Paused (why) | Done> (<date>)
**Last updated:** <date>
**Issues:** parent [PandiO/knk-workspace#<n>](https://github.com/PandiO/knk-workspace/issues/<n>); sub-issues per
link below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** [reports/<date>-<feature>-chain.md](../../reports/<date>-<feature>-chain.md)
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/` (knk-workspace).

## 0. Binding documents

1. [specs/<feature>/DESIGN.md](../../specs/<feature>/DESIGN.md), status Decided <date> (decisions <ids>).
2. <implementation plan, decision records, evidence reports; name the sections that bind which link>.
3. The sub-issue text **and its comments** (decisions added later live there).

## 1. Links

(One row per link. Tier from the sub-issue label. Base: `next` once the branch model applies, otherwise the default
branch; name another feature's branch only for stacked, uncertain work, DESIGN § 5.4. Flag: the config key that keeps
risky work off in `next`, or "none".)

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | #<n> | tier:<1-3> | <scope in one or two sentences> | <repos> | `claude/<feature>` | `next` | <key, default off / none> | now |
| L2 | #<n> | tier:<1-3> | <scope> | <repos> | `claude/<feature>` | `next` | <...> | L1 merged into `next` |

## 2. Gates

(How each gate is checked against the actual branches; the coordinator never trusts the tracker for this.)

1. "L<n> merged into `<base>`": `git rev-list --count origin/<base>..origin/<branch>` is 0 in every repo L<n>
   changed.
2. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed.
3. <Gates that need the developer, such as a live test or a decision, with the issue where it is recorded.>

Order and parallelism: <for example "at most one link per component repo at a time; L3 and L4 may run together, they
share no component repo">.

## 3. Chain notes

(Only what the skills don't cover; delete the section if empty.)

1. Overlaps with other "In progress" rows on the sessions board, and how they are kept mechanical.
2. Behaviour that must stay unchanged for existing modes, and the flag that guarantees it.
3. Migrations: which link may add one (at most one, additive, per link).
4. Model for link sessions: <model id> (passed explicitly to `create_session`).
```
