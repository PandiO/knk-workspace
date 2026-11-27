# Agent workflow decision history

**Status:** Current · **Last updated:** 2026-11-27 (created by splitting the global agent instructions,
PandiO/knk-workspace#1021)

Who decided what, when, and why, for the rules in the
[global agent instructions](GLOBAL_AGENT_INSTRUCTIONS.md). The global file keeps the rules an agent acts on; each rule
there points here with its id (`D<n>`). You don't need this file to follow a rule: read it when you need a decision's
date, its reason, what it replaced, or the history before it.

When a decision changes, add a new entry (or extend the entry with a dated line) and update the rule in the global
file; don't rewrite an old entry's meaning.

<a id="d1"></a>
## D1. GitHub Issues is the one work list (2026-10-15, 2026-10-25)

1. Developer decisions 2026-10-15 and 2026-10-25: the issues of `PandiO/knk-workspace` are the one list of work, also
   for work in the component repos, referenced as `PandiO/knk-workspace#123` (a bare `#123` resolves to the wrong repo
   from a component repo's commit or PR).
2. Linear (team KNG) was the work list until 2026-10-25, when its free issue limit made new issues impossible. It
   stays as a read-only archive. Every open KNG issue was copied with its id in the title (`[KNG-27] ...`); the Linear
   originals are Canceled with a "Moved to GitHub: PandiO/knk-workspace#n" comment. Issues closed before the move
   exist only in Linear; their links in docs stay valid.
3. Issue types are labels (`bug`, `feature`, `improvement`) because GitHub issue types need an organization account
   and this repo is user-owned.

<a id="d2"></a>
## D2. Board claims and additive edits (2026-11-12)

Developer decision 2026-11-12: a claim on `docs/ACTIVE_SESSIONS.md` blocks other work only when the other branch
changes the same lines or the claim is active on the same area. Additive edits elsewhere in a shared file may go ahead
and are logged as a decision with its alternatives. An old timestamp alone does not free a row.

<a id="d3"></a>
## D3. Finished board rows go straight to the archive (2026-11-12)

Developer decision 2026-11-12: a finished row moves from the board into
`docs/reports/sessions-archive/<YYYY-MM>.md` (newest first), not to "Recently completed". The script
`scripts/sessions-archive/archive_sessions.py` only cleans up rows left there.

<a id="d4"></a>
## D4. The `next` branch model (2026-11-12)

1. Developer decision 2026-11-12, [AI agent workflow design](../specs/ai-agent-workflow/DESIGN.md) § 2 and § 5:
   trunk = production, `next` = integration, feature branches from `next` by merge (never rebase), releases as tags
   on trunk, flags for risky work, risk tiers as issue labels, stacking only when the charter says so, chain
   bookkeeping on knk-workspace `main`.
2. The start condition (CI on the API and web-app default branches, PandiO/knk-workspace#328:
   `.github/workflows/ci.yml` on knk-web-api `main` and knk-web-app `main`) and the coordinator merge into `next` were
   confirmed by the developer the same day (setup chain, PandiO/knk-workspace#327). Before the condition held, feature
   branches started from the default branch, pull requests targeted it, and only the developer merged.
3. 2026-11-12: under the branch model, "at merge" in "Shipping a change" means the merge into `next`; closing the
   feature issue waits for the developer's promotion of `next` to trunk.
4. 2026-11-14: knk-web-api's default branch was renamed from `master` to `main`.

<a id="d5"></a>
## D5. Sessions merge their own pull requests into `next` outside a chain (2026-11-13)

Developer decision 2026-11-13; it replaces the 2026-11-12 rule that such pull requests wait for the developer. The
developer stays the gate at promotion, not at the merge into `next`. A `documentation` issue counts as `tier:1` and
gets that label when it is created.

<a id="d6"></a>
## D6. Codex review findings before a merge (2026-11-13, 2026-11-14)

1. Developer decision 2026-11-13: the ChatGPT Codex connector reviews every pull request; the merging session handles
   every finding before a merge into `next`, and a P1 blocks the merge until fixed or decided by the developer.
2. Developer decision 2026-11-14: when Codex is at its usage limit, continue without its review once the other checks
   hold and say so on the pull request and in the report block.

<a id="d7"></a>
## D7. Releases through the Release workflow (2026-11-13)

Developer decisions 2026-11-13: release tags go through `.github/workflows/release.yml` in knk-web-api, knk-web-app
and knk-plugin because cloud sessions cannot push tags (a tag push answers 403). The job runs in the GitHub
environment `release`, so the developer approves every run on GitHub. Sessions may run it as part of a promotion the
developer asked for.

<a id="d8"></a>
## D8. GitHub rulesets (2026-11-13)

Set up by the developer 2026-11-13. On knk-web-api, knk-web-app and knk-plugin, `main` and `next` need a pull request
(no approvals), the CI checks, every review conversation resolved and a merge commit, and cannot be deleted or
force-pushed. On knk-workspace, `main` and `next` are only protected against deletion and force pushes, so chain
bookkeeping can still be pushed to `main`. Tags `v*` cannot be deleted or moved anywhere. Agents act on GitHub as the
developer, so the rulesets guard against mistakes, not against agents.

<a id="d9"></a>
## D9. Agent workflow files go straight to knk-workspace `main` (2026-11-13)

Developer decision 2026-11-13. Why: every new session starts from `main`, so a rule that waits in `next` would not
reach agents until the next promotion. A pull request that mixes workflow files with game code or feature docs is
split.

<a id="d10"></a>
## D10. Session chains: route and `add_repo` (2026-10-11 to 2026-11-14)

1. Developer decision 2026-11-12: `create_session` is the preferred route for every link; the link attaches the other
   knk repositories with `add_repo`, allowed by a permission rule in knk-workspace `.claude/settings.json`
   (PandiO/knk-workspace#331). A subagent of the coordinator is the fallback.
2. History, before the rule existed: the new session's permission check only allowed `add_repo` when the request was
   in the session's **prompt**; an `add_repo` instruction found in a repo file was refused (form wizard chain,
   2026-10-11). On 2026-11-12 even a request in the prompt was refused when another session wrote the prompt, and the
   developer had to approve the attach (setup chain, PandiO/knk-workspace#327). That is why the coordinator still
   pastes the generated permissions block into every link prompt: it carries the authorization and the dry-run step.
3. 2026-11-14 observation (coordinator skill § 4.1.4): in Auto mode the attach is decided by a classifier, not the
   rule, so treat it as likely but not certain.

<a id="d11"></a>
## D11. Manager run and daily digest (2026-11-12, 2026-11-16)

1. Developer decision 2026-11-12 (DESIGN § 1.3, § 7, § 8.4); built 2026-11-16 (PandiO/knk-workspace#418).
2. 2026-11-16: a second run, "K&K manager (morning)" at 06:50, without a digest.
3. 2026-11-16: the manager closes `status:in-review` issues whose work and docs reached trunk; an open documentation
   follow-up carries the rest.

<a id="d12"></a>
## D12. Testing: automated first (2026-11-14, 2026-11-15)

1. Developer decision 2026-11-14: every change ships its proof in the automated suites, so the developer's evening
   check covers only what no suite can check and the developer's time goes to designing features. The same day
   "Branches" rules 3 and 7 gained the automated-first requirement.
2. Developer decision 2026-11-15: smoke-test guides keep every step in full and tag the automated ones.
3. Plugin scenarios on a real Paper server: CI job `paper-boot`, PandiO/knk-workspace#421. Backfill of features in
   `next`: PandiO/knk-workspace#511.
4. Code recipes (PandiO/knk-workspace#424): `knk-api-endpoint`, `knk-plugin-command` and `knk-entity-scaffold`,
   built from each repo's `main`; they replaced the former Copilot instruction files under `.github/`.

<a id="d13"></a>
## D13. Documentation is part of done (2026-11-03, 2026-11-10)

Developer decisions 2026-11-03 and 2026-11-10 (PandiO/knk-workspace#292): essential docs ship with the feature; the
rest is written asynchronously in a `documentation` issue and a separate session, so it never slows a merge. The
plugin `config.yml` deploy note exists because the plugin only writes `config.yml` when a server has none
(`saveDefaultConfig()`), so new keys silently run on the jar's defaults until merged by hand.

<a id="d14"></a>
## D14. Split of the global instructions (2026-11-27)

Token efficiency plan Phase 2 (PandiO/knk-workspace#1021, plan decided 2026-11-24): the global instructions were split
into the rules (the global file) and this history. The rules keep their meaning; only the dates, reasons and history
moved here.

<a id="d15"></a>
## D15. Detail moved out of the global file (2026-11-27)

The split ([D14](#d14)) shortened some rules to what every agent acts on. The detail below was in the global file
until 2026-11-27 and still holds; most of it also lives in the skill or guide named.

1. The board is the coordination board for Claude Code and Codex alike, wherever the repos are cloned. Don't assume
   every repo's default branch is `main` when you pick a base before the branch model applies.
2. Release workflow ([D7](#d7); also `knk-manager` skill): ref = the default branch, inputs `tag` (such as `v0.2`) and
   `sha` (the full 40-character trunk commit); it checks the input, then creates the tag and a GitHub release with
   generated notes. Sessions may run it as part of a promotion the developer asked for.
3. Rulesets ([D8](#d8)): no approvals are required; the required CI checks are `build-and-test` and `fresh-database`
   on the API, `build-and-test` on the web app and `build` on the plugin; on knk-workspace everything except chain
   bookkeeping still goes by pull request.
4. Design session ([`knk-design`](../../.claude/skills/knk-design/SKILL.md) skill, DESIGN § 1.2 and § 4): it asks the
   developer one question at a time, writes the spec with its decision log and open questions, and on approval splits
   it into phases with tiered sub-issues, writes each phase's first smoke-test section, drafts the charter and hands
   the feature to the manager to schedule.
5. Manager run order ([D11](#d11); also `knk-manager` skill): (1) red CI on `next` or trunk first, as a blocker; (2) act
   on the developer's replies on #333 (a numbered item's answer, "pause X", "bump Y", "promote", "start …"), marking
   each handled reply with a reaction; (3) promote only on the developer's explicit go, tags only through the Release
   workflow; (4) close `status:in-review` issues whose work and docs reached trunk; (5) sync `main` into `next` in every
   repo by pull request when `main` has commits `next` lacks; (6) archive finished board rows, list stale claims,
   suggest docs sessions over the debt cap and ask before starting an approved chain; (7) write the digest on #333.
6. Closed alpha runs (also [the guide](../guides/closed-alpha-test-runs.md)): each run has
   `docs/reports/alpha-tests/test-run-<n>/` with `test-run-<n>-preparation.md`, `-checklist.md` and `-findings.md`; the
   date goes in the headers, not the folder name. A fix package's open item goes into the next run's preparation plan
   as scope, the decisions table or known issues, not only into the package report or handoff.
7. Testing ([D12](#d12)): the Playwright suite runs in CI job `e2e`; MockBukkit/Mockito are test-only; the tagging rule
   applies to every smoke-test guide and checklist, whichever repo the change is in; the coordinator sends a change
   back under knk-coordinator § 6.
8. Docs ([D13](#d13)): the docs impact list exists so a later session can write the docs from it and the diff; the
   plugin configuration reference update covers the key's table and § 2.1; the docs session's `source_url` is
   `https://github.com/PandiO/knk-workspace`, its prompt is filled in with issue numbers, merged commits and base, and
   the documentation issue links the merged commits and PRs. Before the branch model applied, "at merge" meant the
   merge into the default branch and all three at-merge items happened then.
