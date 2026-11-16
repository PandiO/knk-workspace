# Smoke-test section template (first draft from the design)

On approval, the design session writes each phase's first section of the feature's smoke-test guide
(`docs/guides/<feature>-smoke-test.md`) from the spec's acceptance items (`knk-design` § 6.4; this folds in
PandiO/knk-workspace#422). The link that builds the phase updates the section to what was built and tags the steps its
tests cover (`knk-test-writer` § 4). Style: the existing `docs/guides/*-smoke-test.md` guides.

## Size by tier

1. `tier:1`: no section, or one line under the phase heading: "Covered by the automated tests of #<n>; quick pass:
   <one action and what you should see>."
2. `tier:2`: short, three to eight steps that show the behaviour works, including the most likely refusal.
3. `tier:3`: full, one step (or more) per acceptance item of the phase, refusals and edge cases included.

## Rules

1. Every step in full: what to do, with which account or role, where, and the expected result. Write it as if no test
   existed; never shorten a step because a test will cover it.
2. No `[automated: …]` tags in the draft: the tests do not exist yet. The link adds them (`knk-test-writer` § 4).
3. Name the acceptance ids (A01…) a step checks, so the link can map tests to steps.
4. Preconditions list what must be deployed (API, web app, plugin, migration, `config.yml` keys, the flag turned on)
   and the test data or accounts.

## New guide header

Use this only when the guide does not exist yet.

```markdown
# <Feature> — smoke test

**Status:** Draft from the design (<date>); no steps run. Steps not yet automated (the links tag them).
**Last updated:** <date> (draft from the design, phases <list>)
**Design:** [specs/<feature>/DESIGN.md](../specs/<feature>/DESIGN.md) · **Issue:**
[PandiO/knk-workspace#<n>](https://github.com/PandiO/knk-workspace/issues/<n>)
```

## Section

Copy from the line below for each phase and replace every `<...>`.

---

```markdown
## <n>. Phase <p>: <phase name> (#<sub-issue>, tier:<t>)

*Draft from the design (<date>); the link updates it to what was built and tags the automated steps.*

### <n>.0 Preconditions

1. Deployed: <API with migration <name> / web app / plugin build from `next`>.
2. Settings: <`config.yml` keys with values, the flag `<key>: true`>.
3. Accounts and data: <roles, a test town, a scenario, ...>.

### <n>.1 Steps

1. <Action, with role and place>. **Expected:** <what you see>. (A01)
2. <Refusal: action without permission>. **Expected:** <message, nothing changes>. (A02)
3. <...>
```
