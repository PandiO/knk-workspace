# Delivery lifecycle and documentation upkeep: audit and proposal

**Status:** Proposal, decisions recorded 2026-11-03 (§ 6), not yet applied · **Date:** 2026-11-03 · **Scope:** agent instructions in
`knk-workspace`, `knk-web-api`, `knk-web-app`, `knk-plugin`, `knk-dev-db-seed`, plus the docs they should keep current

**Evidence baseline:** the default branches of each repo as cloned on 2026-11-03 (`knk-workspace` at the tip of
`claude/happy-cerf-74sbro`, which branched from `main`).

## 1. Short answer

**No.** The agent entrypoints cover the *coordination* loop in detail: the tracker row, issue status labels, branches,
chains and handoffs. Agents follow that loop reliably because it is written into the file every agent reads first.
The *documentation* loop exists as well: [`guides/developer/DOCUMENTATION_MAINTENANCE.md`](../guides/developer/DOCUMENTATION_MAINTENANCE.md)
has a good feature lifecycle, guide minimums and a changelog rule. But **no agent entrypoint links to it**:

| File an agent reads first | Mentions the tracker, issues and branches | Mentions docs upkeep (guides, changelog, register) |
|---|---|---|
| `knk-workspace/AGENTS.md`, `CLAUDE.md` | yes | only folder layout and "reports are dated" |
| `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` | yes, about 120 lines | one paragraph on *where* docs go and what a handoff holds; no link to the maintenance guide, nothing on player/admin/install guides, changelog or register |
| `knk-web-api/AGENTS.md`, `CLAUDE.md` | via the global file | no; migrations are mentioned only as commands |
| `knk-web-app/AGENTS.md`, `CLAUDE.md` | via the global file | no |
| `knk-plugin/AGENTS.md`, `CLAUDE.md` | via the global file | no; the plugin also has its own `docs/` folder and old `PHASE_*`/`STATUS_*` files in its root |
| `knk-dev-db-seed` | **no `AGENTS.md` or `CLAUDE.md` at all** | n/a; only the `README.md` (good, but agents aren't told when to rebuild the seed) |
| `docs/ai-agents/AGENT-GUIDE.md`, `guardrails.md` | **empty files (0 lines)** | — |

The only route to the maintenance guide is the "Start here" table in `docs/README.md`, which the entrypoints don't send
agents to. So documentation gets updated when a handoff or prompt happens to ask for it, not because a rule requires it.

## 2. What is kept current, and what drifts

**Kept current (written into handoffs and chain prompts):** `CHANGELOG.md` (last entry 2026-11-01), the
`FEATURE_REGISTER.md` rows touched by recent work, smoke-test checklists per branch, the closed-alpha runbooks, and test
run folders.

**Drifting:**

- **Player guides.** `guides/users/commands.md` and `handleiding.md` carry `status: stale` and
  `last_updated: 2018-10-19` / `2018-10-03`. The guides index itself says there are no player or admin guides for
  currency, discoveries, lootboxes, kits, menus, ranks and moderation. Merged and live-tested features without a player
  guide include Siege (the authoring guide is admin-only), road navigation, invitations and accounts, player
  statistics, private messages, teleports/homes/warps and custom enchantments.
- **Guide index statuses don't move after a merge.** `guides/README.md` still lists the invitations smoke test and the
  email guide as "not merged, not run", while the register and changelog record KNG-205 as merged on 2026-10-24.
  Nobody is told to update the index row at merge time.
- **Installation and production.** `production-installation.md` is "Draft v1, not yet followed on a real production
  host". The NAS runbook is the real procedure and is ahead of it, so two install documents are diverging.
- **No record of what is deployed.** There are no git tags or releases in any component repo (0 tags in api, app and
  plugin). Nothing says which commit of each component runs on knk-alpha today. The changelog explicitly says it
  doesn't track deploys. The seed's content-patch procedure needs "the seed the server has", which is also recorded
  nowhere.
- **Inconsistent headers.** Bold `Status/Last updated` lines in most docs, YAML front matter in the old user guides, and
  very long "Last updated" lines that pile up change history (the register's header line runs to about 1,500
  characters). Those lines are hard to scan and invite merge conflicts.
- **Docs living in the component repos.** `knk-plugin/docs/` (ADRs, cache, migration mode, `ai/`) and root files such
  as `PHASE_1_COMPLETION.md`, `TEST_FIXES_SUMMARY.md`; `knk-web-app/TESTING_IMPLEMENTATION_SUMMARY.md`. This conflicts
  with "docs belong in `knk-workspace/docs/`" and nothing says which copy wins.
- **CI.** `knk-plugin` runs a build, `knk-web-api` runs migrations against a fresh DB, `knk-web-app` has no workflow,
  and no repo checks docs or links.

## 3. Proposal: one definition of done, enforced at the step agents already follow

Principle: put documentation duties **at the same checkpoints where agents already reliably act** (tracker row, issue
status label, PR) instead of in a guide they must remember to open.

### 3.1 Add a "Shipping a change" section to `GLOBAL_AGENT_INSTRUCTIONS.md` (highest impact)

Draft text:

> ## Shipping a change: documentation is part of done
>
> Follow [documentation maintenance](../guides/developer/DOCUMENTATION_MAINTENANCE.md). An issue is not ready for
> `status:in-review` until the docs below are drafted on the feature branch, and is not closed until they are on
> `main`. Answer each line in the PR's "Docs impact" section with the file you changed or `n/a (reason)`:
>
> 1. **Spec / plan:** status line and phase table say branch or trunk and live-test state.
> 2. **Architecture / API contract:** schema, endpoint, event, config or cross-component change.
> 3. **Developer guide / repo README:** new dependency, command, config key, migration or failure mode.
> 4. **Admin guide:** new or changed permission, form, config, world setup or recovery step.
> 5. **Player guide:** new or changed command, menu, cost, reward, message or web page a player sees.
> 6. **Install / production / runbook:** new env var, secret, port, container, migration or one-time script for a
>    deploy (production-installation, closed-alpha runbook, go-live).
> 7. **Seed:** new or changed content tables or ids that the seed or a live content patch must carry.
> 8. **Register, guides index, changelog:** register row; `guides/README.md` row status; a changelog entry at merge.
>
> If a guide that should exist doesn't, write the first version (guide minimums in the maintenance guide) or file an
> issue labelled `docs` and link it in the PR. "Docs later" without an issue id is not allowed.

Also: fill or delete the empty `AGENT-GUIDE.md` and `guardrails.md`. Empty files suggest there are rules that aren't
there.

### 3.2 PR templates in all five repos (makes 3.1 hard to skip)

Add `.github/pull_request_template.md` with `Closes PandiO/knk-workspace#…`, a summary, the tests run, live-test
state, and the eight-line **Docs impact** checklist above, each answered with the `knk-workspace` path changed, the
linked docs PR or `n/a`. Agents already read PR templates before opening PRs, so this is the most reliable enforcement
available without CI.

### 3.3 One line in each component repo's `AGENTS.md`

> Docs for changes here live in `knk-workspace/docs/` (not in this repo). Before asking for review, complete the
> "Shipping a change" checklist in the global instructions; repo-specific triggers: …

Repo-specific triggers:

- **knk-web-api:** a migration means the seed (3.6), production-installation § migrations and the runbook; a new
  setting means the config table in production-installation; a new endpoint means `docs/specs/api/`.
- **knk-web-app:** a new page, form or wording players see means the player guide; an admin page means the admin guide.
- **knk-plugin:** a command or permission node means `guides/users/commands.md` and
  `architecture/plugin-permission-checks.md`; `config.yml` keys mean the admin guide and production-installation.
- **knk-dev-db-seed:** see 3.6.

Also decide on `knk-plugin/docs/` and the root status files: move the still-relevant ones to `knk-workspace/docs/`
(ADRs to `architecture/adr/`) and archive the rest, or record that the plugin keeps code-level notes locally.

### 3.4 Give player and admin guides a home and a backlog

- Rebuild `guides/users/commands.md` **from the code** (the plugin's command catalogue and `plugin.yml`) and mark it
  as generated or checked against a named commit. Commands drift fastest and are the most visible.
- Replace `handleiding.md` with a short V3 player handbook index that links one page per feature area.
- File one `docs` issue per missing guide (the list in § 2), with a parent "Player and admin guide coverage" issue.
  Then it is real work in the work list rather than a note in the guides index.
- Add a **Docs** column to `FEATURE_REGISTER.md` (player / admin / dev guide: link, `missing #n` or `n/a`), so gaps
  appear in the same place as implementation status.

### 3.5 Deployment and releases: record what runs where

- Add a living `guides/deployments.md` (or `docs/DEPLOYMENTS.md` next to the changelog) with one row per deploy:
  date, environment (dev, knk-alpha), the commit of the api, app and plugin, the seed or patch applied, migrations
  run, one-time scripts run, who checked it, and a rollback note. Nobody needs to remember what is on the NAS any more.
- Tag what you deploy: `alpha-YYYY-MM-DD` (or semver per component) on each component's deployed commit. The
  changelog can then group entries by tag, and "Unreleased" means merged but not deployed.
- Make the NAS runbook the source of truth for knk-alpha, and turn `production-installation.md` into the
  environment-neutral version that is updated **from** each completed runbook phase. Otherwise mark it as superseded.
- Add one changelog subsection per release, "Admin steps for this deploy", collecting migrations, config keys and
  cleanup scripts from the entries. These items are currently scattered through entries, for example the user-1
  drafts cleanup script in the 2026-11-01 entry.

### 3.6 Seed repository

Add `AGENTS.md`/`CLAUDE.md` to `knk-dev-db-seed`: entrypoint to the global instructions, private repo (no secrets,
no raw exports), commands from the README, and **when to rebuild**: after an API migration that adds or changes
content tables, after content changes on dev that alpha needs, and before each alpha deploy (then record the seed or
patch in the deployment log, 3.5).

### 3.7 Maintenance cycle: catch the drift that gets through

- **Weekly docs-drift check** (a scheduled cloud session, or the developer's Sunday check-in prompt): list the last
  week's merges to each default branch and the files they touched, and compare them with the changelog, the register,
  the guide index and the command reference. File `docs` issues for gaps and write a dated `reports/` file. Read-only
  apart from issues and the report, so it is safe to run unattended.
- **Per test run:** the test-run preparation plan gets a line "guides testers will use are current", which turns the
  alpha runs into a check of the player guides.
- **Lightweight CI** (later): a markdown link checker on `knk-workspace`, a build-and-test workflow for `knk-web-app`,
  and optionally a check that fails a component PR whose body has an empty Docs impact section.

### 3.8 Header and format hygiene

Standardise on `**Status:** … · **Last updated:** YYYY-MM-DD (one-line reason)`: **only the latest change** in the
header, and history in git or a "Changes" section at the bottom. Convert the YAML front matter in the old user guides.
Allowed statuses: `Draft`, `Current`, `Needs review`, `Stale`, `Superseded`.

## 4. Suggested order

| # | Change | Effort | Why first |
|---|---|---|---|
| 1 | 3.1 global "Shipping a change" section + link to the maintenance guide | small | Every agent reads it; fixes the root cause |
| 2 | 3.2 PR templates (5 repos) + 3.3 repo `AGENTS.md` lines + 3.6 seed entrypoint | small | Enforcement at a step agents already follow |
| 3 | 3.5 deployment log + tags, starting with what runs on knk-alpha now | small to medium | Highest risk of being forgotten; needs the developer's memory while it is fresh |
| 4 | 3.4 `docs` issues for missing guides, register Docs column, regenerated commands reference | medium | Turns the backlog into tracked work |
| 5 | 3.7 weekly drift check | small | Safety net |
| 6 | 3.8 headers, plugin `docs/` consolidation, CI link check | medium | Hygiene |

## 5. Decisions for the developer

1. Docs duties as a **blocker** for `status:in-review` (proposed), or only for closing the issue?
2. Release identity: date tags such as `alpha-2026-11-03` across repos (proposed), or semver per component?
3. `production-installation.md`: keep it as the generic guide updated from the runbook (proposed), or retire it in
   favour of the runbook?
4. `knk-plugin/docs/`: move to the workspace (proposed), or keep code-level notes local?
5. Weekly drift check as a scheduled cloud session (proposed), or as a manual prompt?
6. Language of the player handbook (`handleiding.md` is Dutch; most current docs are English).

Nothing in this report has been applied yet. The developer's decisions are in § 6 and replace §§ 3–5 where they
differ.

## 6. Developer decisions (2026-11-03) and the revised plan

| # | Decision | Effect on the plan |
|---|---|---|
| 1 | Docs are written **after** the developer's smoke test, **before** merge; the docs checklist blocks closing the issue | § 3.1 is revised as below |
| 2 | Plugin `config.yml` changes are documented thoroughly; on each deployment they are merged into the dev and alpha configs | New § 6.2 |
| 3 | `production-installation.md` is the from-scratch guide | See § 6.3: the runbook covers different ground, so nothing is retired outright |
| 4 | All documentation lives in `knk-workspace`, including `knk-plugin/docs/` | § 3.3 consolidation goes ahead with the exceptions in § 6.4 |
| 5 | A weekly scheduled docs check | § 3.7 accepted |
| 6 | The player handbook is in English | § 3.4: replace `handleiding.md` with an English handbook and archive the Dutch file |
| 7 | Question: is the plan enough for a GitHub wiki or changelog? | Not yet; § 6.5 adds what is missing |

### 6.1 Lifecycle with a docs phase

`status:in-progress` → `status:in-review` (developer smoke test, fix rounds) → **`status:docs`** (new label: test
signed off, docs being written on the feature branches) → merge with the docs → closed.

- **At `in-review`:** the PR's "Docs impact" section lists *which* docs and config keys will change, without writing
  them yet. The smoke-test guide and anything needed to run the test on dev (config keys, migrations, scripts) must
  exist before testing, as now. The docs are written by a later, often fresh, session, which has only this list and the
  diff to go on.
- **At `docs`:** write or update every item on the list against the tested behaviour. Then the register, the guides
  index and the changelog entry, merged together with the code.
- **Closing:** the issue closes only when the code and docs are on the default branches and the deployment notes
  (§ 6.2) are in place.

### 6.2 Configuration changes (plugin `config.yml`, API settings)

The plugin calls `saveDefaultConfig()` (`KnKPlugin.onEnable`). That writes `config.yml` only when none exists, so new
keys never reach an existing server file and silently use the defaults built into the jar. Each change to
`knk-paper/src/main/resources/config.yml` or to an API setting therefore needs:

1. **A reference entry** in a living `guides/admin/plugin-configuration.md` (and an API settings table in
   `production-installation.md` § 4): key, type, default, what it does, safe values, which feature or issue added it,
   and whether a restart or `/reload` picks it up.
2. **A "Config to merge" item in the PR and the changelog entry**: added, renamed, removed or changed-default keys,
   with the YAML snippet to paste.
3. **A deployment-log step** (§ 3.5): for each environment, which keys were merged and checked.
4. **Later, a tool:** a small script or `/knk config diff` that lists keys present in the jar's default `config.yml`
   but missing from the server's file. This makes the manual merge checkable.

### 6.3 Install documents

`production-installation.md` is the only from-scratch guide (database, API, web app, Paper server with the plugin,
secrets, seed). The closed-alpha runbook is the NAS rollout log for one environment, and `alpha-go-live.md` is the
KNG-64 layer on top of it. Neither has the same goal, so neither is retired. Instead:

- `production-installation.md` stays canonical for "set up Knights and Kings from scratch". It gets a local
  development counterpart (`guides/developer/local-setup.md`), which is currently spread over the repos' `CLAUDE.md`
  files.
- The runbook and go-live keep only NAS- and alpha-specific steps and link to the installation guide for the rest.
  Each completed runbook phase feeds lessons back into the installation guide.
- Once the alpha is past go-live, `alpha-go-live.md` can be archived as a dated record.

### 6.4 Consolidating docs into the workspace

Move `knk-plugin/docs/` (ADRs to `architecture/adr/`, `ai/` to `ai-agents/`, the rest to `architecture/` or
`archive/`), the plugin's root `PHASE_*`/`STATUS_*`/`TEST_*` files, `knk-web-app/TESTING*.md` and
`knk-web-api/OBSERVABILITY.md`, leaving a pointer where something links to them. These stay in the component repos:

- a short `README.md` per repo (what it is, build/run quick start, link to the workspace docs; GitHub shows it on the
  repo page)
- `AGENTS.md`, `CLAUDE.md` and `.github/` (templates, workflows, copilot instructions)
- the seed repo's `README.md`, which is the manual for its tools (link to it from the workspace)

### 6.5 Changelog and wiki on GitHub

The plan gives the raw material (tags, a deployment log, a dated changelog). For project awareness and marketing it
also needs:

- **GitHub Releases** on `knk-workspace`, one per deploy tag, with notes in two parts: *What's new* (player language,
  no commit hashes) and *Admin steps* (migrations, config to merge, scripts). Changelog entries therefore start with
  a one-sentence player summary, followed by the technical detail.
- **A public player site instead of the built-in wiki.** The GitHub wiki is a separate git repo outside PRs, reviews
  and the agents' normal branch flow. A GitHub Pages site built from `docs/` (MkDocs Material or similar, via an
  Action) keeps one source of truth. It publishes only a curated part: the player handbook, feature pages, the release
  notes and the vision summary.
- **Feature pages** written for players (what it is, how to start, a screenshot), one per shipped feature in the
  register, created at the docs phase only after live verification (maintenance guide, "Consistency checks").
- **A media folder** (`docs/media/<feature>/`) for screenshots and clips from test runs, with a note on what may be
  shown publicly.
- **Public-repo hygiene:** `knk-workspace` is public. `nas-ops-access.md` and `production-installation.md` contain
  LAN addresses (`192.168.50.x`). The maintenance guide already says live hostnames stay out of public docs, so replace
  them with placeholders as part of § 3.8.
