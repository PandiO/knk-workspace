# Feature spec template (`docs/specs/<feature>/DESIGN.md`)

The design session (`knk-design` skill) writes a spec from this template. Keep the section order; a section that does
not apply stays as its heading with one line saying why. Number everything (topics, decisions, questions), never
dashes or bullets. The worked example is the [Siege Survival design](../../../docs/specs/siege-survival/DESIGN.md).

Copy from the line below, replace every `<...>` and delete the hints in parentheses.

---

```markdown
# <Feature name> — <one-line subtitle>

**Status:** **Proposed** (<date>) — <n> open questions in § 12. (On approval: **Decided <date>** (developer).)
**Last updated:** <date> (<what changed>); <older dates, newest first>
**Issue:** [PandiO/knk-workspace#<n>](https://github.com/PandiO/knk-workspace/issues/<n>); phases as sub-issues in § 11.
**Dependencies:** <features, specs or issues this needs, or "none">.
**Authority:** <whose decisions define this: the developer's answers of <dates>; which older docs it supersedes>. This
document is the canonical specification, not a claim that the proposed entities, endpoints or behaviour exist.

Related: <links to related specs, guides, the smoke-test guide once it exists>.

## 1. Goal and scope

1. **Goal:** <what a player, admin or staff member can do afterwards, in plain words>.
2. **In scope (v1):** <numbered list>.
3. **Out of scope:** <numbered list, each with its issue id if it is planned later>.

## 2. Decision log

(Every decision, newest last. Who: `developer` or `agent`. A changed decision keeps its row: ~~old text~~ "superseded
by <id>". Agent decisions list their alternatives below the table.)

| ID | Date | Who | Decision |
|---|---|---|---|
| <X>01 | <date> | developer | <decision> |
| <X>02 | <date> | agent | <decision> (alternatives in 2.1) |

### 2.1 Agent decisions: alternatives

1. **<X>02 <topic>.** Chosen: <option>, because <why>.
    1. (a) <alternative>: <why not>.
    2. (b) <alternative>: <why not>.

## 3. Current state and legacy behaviour

1. **Built today (V3):** <entities, endpoints, services, plugin classes, pages to reuse, with paths and branch>.
2. **V1/V2:** <what players had in `knk-v1-archive` / `knk-v2-archive` or `docs/specs/legacy/`; keep, change or
   drop each, and why>.
3. **Related open work:** <issues and backlog items>.

## 4. Player and admin experience

(Step by step, as the player or admin sees it: commands, menus, pages, messages, permissions. Numbered.)

## 5. Rules

(The behaviour, one numbered rule per decision or group of decisions, citing the ids. Edge cases and refusals too.)

## 6. Data and API

1. **Entities and fields:** <new or changed, with migration note: additive or not>.
2. **Endpoints:** <method, route, access rule (default-deny), DTOs>.
3. **Web app:** <pages, forms, dashboard tables>.

## 7. Plugin

1. **`knk-core` (Bukkit-free):** <rules, state machines, calculations, the ports they use>.
2. **`knk-paper` adapters:** <listeners, commands, menus, schedulers behind those ports>.
3. **Configuration:** <`config.yml` keys with defaults; the feature flag, off by default, for risky work>.

## 8. Platform-specific parts

(Vision principle "Platform Independence". Every part that depends on Minecraft/Paper or a Bukkit plugin.)

| Part | Why platform-specific | Lives in | Port in `knk-core` |
|---|---|---|---|
| <e.g. block animation of a gate> | <Paper block API> | `knk-paper` <class/package> | <port name, or "none: no game logic"> |

## 9. Risks and integration checks

(What could break existing modes, performance or data; what must be checked in the code or live before building.)

## 10. Acceptance checklist

(One item per rule a test or a smoke step can check. Phases and smoke-test sections are built from these.)

| ID | Check | Phase |
|---|---|---|
| A01 | <observable result> | <phase> |

## 11. Phases

(Filled on approval. Each phase merges into `next` on its own, behind its flag where needed.)

| Phase | Scope | Acceptance | Repos | Tier | Flag | Sub-issue | Depends on |
|---|---|---|---|---|---|---|---|
| 1 | <scope> | A01–A04 | <repos> | tier:<n> | <key / none> | #<n> | — |

Smoke test: [guides/<feature>-smoke-test.md](../../guides/<feature>-smoke-test.md).

## 12. Open questions

(Numbered, each with options and the recommendation. "None" when all are answered. On approval, unanswered items
move to "After v1" below with their issue.)

1. **<topic>.** <question> Options: (a) <option>; (b) <option>. Recommendation: (a), because <why>.

### After v1

1. <item> (PandiO/knk-workspace#<n>).
```
