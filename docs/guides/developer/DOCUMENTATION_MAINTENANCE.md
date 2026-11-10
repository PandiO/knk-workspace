# Documentation maintenance and release notes

**Status:** Active · **Last updated:** 2026-11-10 (link to the plugin configuration reference, #295); 2026-11-10 (essential docs before merge, the rest in a `documentation` follow-up issue and session, PandiO/knk-workspace#292)

This guide applies to features and fixes in `knk-workspace`, `knk-plugin`, `knk-web-api` and `knk-web-app`. Documentation is part of implementation. Keep user promises in sync with code and verification. See [the feature register](../../FEATURE_REGISTER.md) for current coverage and [the changelog](../../CHANGELOG.md) for shipped changes.

## Which document answers which question?

| Question | Canonical place | Update trigger |
|---|---|---|
| What game are we building? | [`docs/vision/vision.md`](../../vision/vision.md) | Owner changes product intent or priority; the root `docs/vision.md` copy currently lags the Siege status and should be reconciled or retired in a separate vision edit. |
| What exists in v1/v2/v3, and how sure are we? | [`docs/FEATURE_REGISTER.md`](../../FEATURE_REGISTER.md), backed by [legacy scans](../../specs/legacy/README.md) | New evidence, design decision, feature branch, merge, or live test. |
| How does a feature behave, and why? | `docs/specs/<feature>/DESIGN.md` or the feature's current spec and decision log | Behavior, data model, permission, API or dependency changes. |
| What remains and where was it implemented? | `docs/specs/<feature>/IMPLEMENTATION_PLAN.md`, GitHub issue, [ACTIVE_SESSIONS](../../ACTIVE_SESSIONS.md) | Every phase, pause, handoff and merge. Status must name branch/trunk and live-test state. |
| How do components communicate? | `docs/architecture/` and relevant API contracts in `docs/specs/api/` | Schema, API, events, integration and deployment contract changes. |
| How do developers build, configure, test and troubleshoot it? | `docs/guides/developer/`, feature-specific setup guide, root README in the affected repo | New dependency, migration, config, operational task or failure mode. |
| How do players and admins use it? | `docs/guides/users/` and feature guide (for example [Siege authoring](../authoring-a-siege-scenario.md)) | A command, permission, form, menu, economy rule or workflow changes. |
| What shipped? | [`docs/CHANGELOG.md`](../../CHANGELOG.md) | Merge to all required default branches; include follow-up correction on later merge. |
| What happened during an investigation? | Dated `docs/reports/` file | A new scan or audit; never silently rewrite a historical report. |

The `docs/specs/` layout is current. [AI_FEATURE_IMPLEMENTATION_WORKFLOW.md](AI_FEATURE_IMPLEMENTATION_WORKFLOW.md) contains older `docs/features/` examples; use its useful phase ideas but follow this guide's paths, the current feature plan, and active branch convention.

## Feature lifecycle

1. **Before implementation:** check [ACTIVE_SESSIONS](../../ACTIVE_SESSIONS.md), current default branches and related issues (GitHub; Linear read-only for work before 2026-10-25). Claim nonoverlapping scope. Add a register row if none exists, link legacy evidence, mark design/implementation separately. Write or update the feature spec; log unresolved owner decisions instead of quietly deciding policy.
2. **During work:** update the plan's phase status, contracts and architecture as implementation changes. Draft player and admin instructions alongside commands, menus, permissions, failure messages and setup. Record test limitations truthfully, especially when a plugin cannot compile or live Minecraft is unavailable.
3. **At `status:in-review`:** draft the PR's **Docs impact** list (every guide, spec, register row and site page the change affects and how behaviour changed) and the deploy notes. The smoke-test guide and whatever is needed to run it on dev exist before the developer's test, as now.
4. **Before merge (essential docs, on the feature branches):** correct the docs impact list after the test and fix rounds. Write the **deploy notes**: plugin `config.yml` keys added, renamed or removed and changed defaults (with the YAML to paste; the plugin's `saveDefaultConfig()` never adds new keys to an existing server file, so they are merged by hand on dev and alpha at every deploy), API settings and secrets, migrations, one-time scripts, ports and seed changes. Update the configuration references, the [plugin configuration reference](../admin/plugin-configuration.md) (the key's table and § 2.1) and [production installation](../production-installation.md) when these change. Set the spec/plan status, the smoke-test guide's status and the register's merge column. Then check the actual tip of each required default branch and add a dated changelog entry to [CHANGELOG.md](../../CHANGELOG.md): one sentence a player understands first, then the technical detail, links to the spec, issue and PRs or commits, and an **Admin steps** list. Do not mark a branch-only feature shipped.
5. **At merge:** close the feature issue as completed. Put everything on the docs impact list that isn't done yet into one `documentation` sub-issue, `Docs: <feature>`, and start a new session for it right away with the [docs-session prompt](../../ai-agents/docs-session-prompt.md) ([global instructions § Shipping a change](../../ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md#shipping-a-change-documentation)).
6. **Docs session (asynchronous):** player, admin and developer guides, architecture, the register's implementation and verification columns, the [guides index](../README.md) row, site or wiki pages and screenshots, written against the merged code and the test results. It amends guide steps that differ from observed behaviour and files issues for gaps it can't close.
7. **After live verification and before deploys:** update verification in the register and plan, and use a later changelog entry for actual shipped fixes. Before a deploy to knk-alpha or a tester run, the open player and admin guide items of the features in it are closed, or the developer accepts the gap in the run's preparation plan. Move the session claim into Recently completed. Keep plans' old phase notes as history, but put current status at the top.

## Guide minimums

**Technical/developer:** architecture and component ownership; schema/API/permission contracts; configuration and migration; local/dev setup; test and rollback or recovery path if relevant; source links and limitations. Keep secrets, live hostnames and unverified performance claims out of public docs.

**Player:** who can use the feature, how to reach it, example command/menu path, costs/cooldowns/rewards, what denial/error means, and what other players can see. Use terms from the current UI, not old v1 aliases unless still supported.

**Admin:** prerequisites, permissions, config/form steps, world setup, safe test procedure, effects on existing data and likely failure modes. Point to the player guide instead of duplicating it.

**Changelog:** one entry per coherent shipped capability or correction, dated by merge. Start with one sentence a player understands, then plain behaviour, relevant limitations and **Admin steps** (config keys to merge, migrations, scripts). Keep unreleased design/branch work out of shipped entries. Older merges can be backfilled with evidence and labeled as such; never infer a precise release or live-test date from an old branch name.

## Consistency checks

- Search the repo for the previous feature or command name before finishing docs; link or correct stale current guides, leaving dated reports and archives intact.
- Validate local relative links and names against files. Review the register's implementation, merge and verification columns against code and documented tests rather than just an issue's closed state.
- If the vision, spec and code disagree, distinguish **intended**, **implemented** and **verified** states; create a follow-up decision or bug issue instead of silently rewriting history.
- Capture safe, shareable feature descriptions and screenshots only after behavior is verified. The register and changelog provide a factual basis for later marketing content, not a promise that every vision item is live.
