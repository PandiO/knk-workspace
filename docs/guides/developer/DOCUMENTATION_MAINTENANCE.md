# Documentation maintenance and release notes

**Status:** Active · **Last updated:** 2026-09-30

This guide applies to features and fixes in `knk-workspace`, `knk-plugin`, `knk-web-api` and `knk-web-app`. Documentation is part of implementation. Keep user promises in sync with code and verification. See [the feature register](../../FEATURE_REGISTER.md) for current coverage and [the changelog](../../CHANGELOG.md) for shipped changes.

## Which document answers which question?

| Question | Canonical place | Update trigger |
|---|---|---|
| What game are we building? | [`docs/vision/vision.md`](../../vision/vision.md) | Owner changes product intent or priority; the root `docs/vision.md` copy currently lags the Siege status and should be reconciled or retired in a separate vision edit. |
| What exists in v1/v2/v3, and how sure are we? | [`docs/FEATURE_REGISTER.md`](../../FEATURE_REGISTER.md), backed by [legacy scans](../../specs/legacy/README.md) | New evidence, design decision, feature branch, merge, or live test. |
| How does a feature behave, and why? | `docs/specs/<feature>/DESIGN.md` or the feature's current spec and decision log | Behavior, data model, permission, API or dependency changes. |
| What remains and where was it implemented? | `docs/specs/<feature>/IMPLEMENTATION_PLAN.md`, Linear issue, [ACTIVE_SESSIONS](../../ACTIVE_SESSIONS.md) | Every phase, pause, handoff and merge. Status must name branch/trunk and live-test state. |
| How do components communicate? | `docs/architecture/` and relevant API contracts in `docs/specs/api/` | Schema, API, events, integration and deployment contract changes. |
| How do developers build, configure, test and troubleshoot it? | `docs/guides/developer/`, feature-specific setup guide, root README in the affected repo | New dependency, migration, config, operational task or failure mode. |
| How do players and admins use it? | `docs/guides/users/` and feature guide (for example [Siege authoring](../authoring-a-siege-scenario.md)) | A command, permission, form, menu, economy rule or workflow changes. |
| What shipped? | [`docs/CHANGELOG.md`](../../CHANGELOG.md) | Merge to all required default branches; include follow-up correction on later merge. |
| What happened during an investigation? | Dated `docs/reports/` file | A new scan or audit; never silently rewrite a historical report. |

The `docs/specs/` layout is current. [AI_FEATURE_IMPLEMENTATION_WORKFLOW.md](AI_FEATURE_IMPLEMENTATION_WORKFLOW.md) contains older `docs/features/` examples; use its useful phase ideas but follow this guide's paths, the current feature plan, and active branch convention.

## Feature lifecycle

1. **Before implementation:** check [ACTIVE_SESSIONS](../../ACTIVE_SESSIONS.md), current default branches and related Linear items. Claim nonoverlapping scope. Add a register row if none exists, link legacy evidence, mark design/implementation separately. Write or update the feature spec; log unresolved owner decisions instead of quietly deciding policy.
2. **During work:** update the plan's phase status, contracts and architecture as implementation changes. Draft player and admin instructions alongside commands, menus, permissions, failure messages and setup. Record test limitations truthfully, especially when a plugin cannot compile or live Minecraft is unavailable.
3. **Before the merge PR:** review the diff across affected repos; update the register's source links and design status, but keep `branch` until merged. Check migration and config instructions, permission defaults, API usage, smoke-test steps, player/admin guides and accessibility of help/commands. State what is code-complete versus live-tested. Link docs changes in each code PR; a docs PR can merge after coordinated code PRs if it does not prematurely claim trunk status.
4. **At the coordinated trunk merge:** check the actual tip of each required default branch. Set implementation to `complete` or `partial`, merge to `trunk` or `mixed`, record remaining test work as `pending` or `mixed`, and add a concise **dated, player-readable** entry to [CHANGELOG.md](../../CHANGELOG.md) with links to the spec, issue and PRs or commits. Mention admin migration/config steps and known limitations where material. Merge the docs with the feature, or immediately after the final code merge. Do not mark a branch-only feature shipped.
5. **After live verification:** update verification in the register and plan, amend guide steps that differ from observed behavior, and use a subsequent changelog entry for actual shipped fixes. Close or relate follow-up Linear items. Move the session claim into Recently completed. Keep plans' old phase notes as history, but put current status at the top.

## Guide minimums

**Technical/developer:** architecture and component ownership; schema/API/permission contracts; configuration and migration; local/dev setup; test and rollback or recovery path if relevant; source links and limitations. Keep secrets, live hostnames and unverified performance claims out of public docs.

**Player:** who can use the feature, how to reach it, example command/menu path, costs/cooldowns/rewards, what denial/error means, and what other players can see. Use terms from the current UI, not old v1 aliases unless still supported.

**Admin:** prerequisites, permissions, config/form steps, world setup, safe test procedure, effects on existing data and likely failure modes. Point to the player guide instead of duplicating it.

**Changelog:** one entry per coherent shipped capability or correction, dated by merge, with plain behavior and relevant limitations. Keep unreleased design/branch work out of shipped entries. Older merges can be backfilled with evidence and labeled as such; never infer a precise release or live-test date from an old branch name.

## Consistency checks

- Search the repo for the previous feature or command name before finishing docs; link or correct stale current guides, leaving dated reports and archives intact.
- Validate local relative links and names against files. Review the register's implementation, merge and verification columns against code and documented tests rather than just Linear's Done status.
- If the vision, spec and code disagree, distinguish **intended**, **implemented** and **verified** states; create a follow-up decision or bug issue instead of silently rewriting history.
- Capture safe, shareable feature descriptions and screenshots only after behavior is verified. The register and changelog provide a factual basis for later marketing content, not a promise that every vision item is live.
