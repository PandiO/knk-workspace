# Decision matrix template

For a larger choice: a framework, technology, library or external service (DESIGN § 4.4; examples: SignalR for the
realtime channel, BlueMap vs Dynmap for maps). The design session writes it; **the developer decides**. Put it in the
spec as a subsection, or in `docs/specs/<feature>/DECISION-<topic>.md` when it is long, and link it from the open
question that asks for the choice.

Copy from the line below and replace every `<...>`.

---

```markdown
## <n>. Decision matrix: <topic>

**Status:** Proposed <date> — the developer decides. (On a decision: Decided <date> (developer), option <x>; log id <X>nn.)
**Question:** <the choice in one sentence, and why it has to be made now>.

### <n>.1 Options

1. **<Option A>** (<version, licence, link>): <what it is in one line>.
2. **<Option B>** (<...>): <...>.
3. **<Build it ourselves / do nothing>**: always consider it.

### <n>.2 Considerations and weights

(Weights add up to 100. Platform independence is always one of them: vision principle, DESIGN § 4.7.)

1. **<Consideration>** (<weight>): <what good looks like>.
2. **Platform independence** (<weight>): how much K&K would have to rebuild on another engine.
3. **Effort to build and maintain** (<weight>): <...>.
4. **Fit with what exists** (<weight>): <current stack, hosting, existing code>.

### <n>.3 Matrix

(Score 1–5 per option; weighted total = sum of score × weight / 5, out of 100.)

| Consideration | Weight | <Option A> | <Option B> | <Option C> |
|---|---|---|---|---|
| <Consideration> | <w> | <score> | <score> | <score> |
| Platform independence | <w> | <score> | <score> | <score> |
| Effort | <w> | <score> | <score> | <score> |
| Fit | <w> | <score> | <score> | <score> |
| **Weighted total** | 100 | **<t>** | **<t>** | **<t>** |

### <n>.4 Pros and cons

1. **<Option A>.**
    1. Pros: <numbered>.
    2. Cons: <numbered>.
2. **<Option B>.** <...>

### <n>.5 Recommendation

<Option>, because <the deciding considerations>. Reversible? <how hard it is to change later>. What would change the
recommendation: <facts>.
```
