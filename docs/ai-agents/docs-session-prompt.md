# Docs session prompt

**Status:** Current · **Last updated:** 2026-11-16 (shrunk to a starter; the procedure moved to the `knk-docs-session` skill, PandiO/knk-workspace#425)

The implementing session uses this starter when it starts a docs session after a merge: the feature's merge into
`next` once the global branch model applies, until then the merge into the default branch
([global instructions § Shipping a change](GLOBAL_AGENT_INSTRUCTIONS.md#shipping-a-change-documentation)). The
weekly docs check uses it for issues it finds without a session. Fill in the `<…>` parts and send it as the prompt
of a new session (`create_session`, `source_url` `https://github.com/PandiO/knk-workspace`, the model passed
explicitly). The procedure is in the [`knk-docs-session` skill](../../.claude/skills/knk-docs-session/SKILL.md).
Keep the `add_repo` line when the seed is affected: a session can only attach repositories its prompt asks for.

```text
Docs session for PandiO/knk-workspace#<docs issue> (Docs: <feature>), the documentation follow-up of
PandiO/knk-workspace#<feature issue>. The code is merged: <repo> <branch: next, or main before the branch model
applies> <commit>, ... (PRs: <links>). Base for the docs branch: knk-workspace <next | main>.

Follow the knk-docs-session skill (.claude/skills/knk-docs-session/SKILL.md) for setup, the docs, the merge and the
finish.
<Only if the seed is affected:> Attach PandiO/knk-dev-db-seed with add_repo (access read) and clone it.
```

## Changes

1. 2026-11-14: knk-web-api's trunk renamed from `master` to `main`; Codex at its usage limit: merge without it
2. 2026-11-13: Codex findings handled before the docs PR merges
3. 2026-11-12: starts at the merge into `next`; docs PR into `next`, merged by the docs session itself, a developer
   decision; finished rows go to the sessions archive; PandiO/knk-workspace#330
4. 2026-11-10: first version, PandiO/knk-workspace#292
