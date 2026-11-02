# Custom enchantments: from op-only to rank permissions (handoff)

**Status:** Ready to start (2026-10-26). No issue filed yet; the session files it first.
**Last updated:** 2026-10-26
**Issues:** to file as a sub-issue of [PandiO/knk-workspace#149](https://github.com/PandiO/knk-workspace/issues/149)
(finding F6 of the [command permission scan](https://github.com/PandiO/knk-workspace/blob/claude/alpha-run-1-permissions/docs/reports/2026-10-26-command-permission-scan.md),
also in the package C comment on [#158](https://github.com/PandiO/knk-workspace/issues/158))

## Prompt (paste into a new cloud session started on knk-workspace)

```
Fix the op-only rule for custom enchantments (abilities and all other custom enchantments) in Knights and Kings.
I (the developer) ask you to add the repository knk-plugin with add_repo (owner PandiO, access push) and clone it
to /home/user/knk-plugin; knk-workspace is already attached. Then, in knk-workspace, fetch branch
claude/adoring-bardeen-94lfsf and read docs/ai-agents/handoffs/2026-10-26-custom-enchantment-permissions.md; it is
binding. Read AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md and docs/ACTIVE_SESSIONS.md from main, and
knk-plugin's AGENTS.md. First file the GitHub issue described in § 2 of the handoff (sub-issue of
PandiO/knk-workspace#149) and give me its number; scope everything after that by it. Work on branch
claude/custom-enchantment-permissions in every repo you change, created from that repo's default branch, and run
git push --dry-run on it before editing. Don't seed rank grants (I add the nodes to the Default rank myself after
the implementation), don't merge, deploy, open PRs or touch the NAS. Finish with one paragraph: issue number,
heads, tests, the exact node list for me to grant to Default, and flags.
```

## 1. What is wrong

Found by alpha run 1 package C (scan F6, 2026-10-26), not yet reproduced live:

- Activating a custom enchantment is gated by Bukkit's `player.hasPermission("customenchantments.<id>")`, e.g.
  `EnchantmentInteractListener` (knk-paper `listeners/`, SUPPORT enchantments on right-click: chaos, flash chaos,
  health boost, armor repair, resistance, invisibility) and `EnchantmentCommandValidator`.
- These per-enchantment nodes aren't declared in `plugin.yml`, so Bukkit's default applies: **op only**. The in-house
  rank system never reaches Bukkit permissions, so no rank grant helps. In the alpha only ops can use abilities.
- The `/ce` subcommand nodes (`customenchantments.command.add`, `.remove`, `.reload`, `.info.others`,
  `.cooldown.clear`, `.cooldown.clear.others`) are Bukkit-only checks too.

The developer decided on 2026-10-26: custom enchantments are permission-based, through the rank system. The nodes go
to the **Default** rank; the developer adds them there by hand after the implementation.

## 2. Issue to file first

In `PandiO/knk-workspace`, as a sub-issue of #149, labels `bug` and `priority:high`, title like
"Custom enchantments are op-only: use rank permissions". Body: the findings of § 1 (with file paths), the
developer's decision, the scope of § 3, and "Default rank grants: done by the developer after implementation".
Then `status:in-progress` on it while you work.

## 3. Scope

- Verify every place a custom enchantment checks a permission before it works: SUPPORT activation, on-hit/attack
  effects, passive/armour effects, `/ce` subcommands, tab completion. List them in the issue.
- Route every such check through the in-house permission check (the one ranks reach), keeping Bukkit/op as a
  fallback the same way the rest of the plugin does. Package C (knk-plugin `claude/alpha-run-1-permissions`, not
  merged) added helpers for this (`MenuPermissions`, `GatePassThroughRules`); reuse the pattern on `main`, or, if
  those helpers aren't on `main` yet, write the smallest equivalent and note the overlap for the merge.
- Declare the nodes in `plugin.yml` with `default: op` (so ops keep them, and nobody gets them without a rank):
  per enchantment `customenchantments.<id>`, a wildcard `customenchantments.*` (or a documented group node such as
  `customenchantments.use.*`) that covers every enchantment, and the existing `/ce` subcommand nodes. Make sure the
  in-house check honours the wildcard, so the developer can grant one node to Default.
- Enchantments added later (new ids from the API) must be covered by the wildcard without a plugin change.
- Tests for the check (granted via rank, wildcard, denied, op fallback).

Not in scope: seeding rank grants (knk-web-api), changing enchantment values or cooldowns (package B), any other
permission node.

## 4. Context and conflicts

- Package B (`claude/alpha-run-1-enchantments`, knk-plugin `fcb2e08a`) changed `/ce` and the enchantment executor;
  package C (`claude/alpha-run-1-permissions`, `352cdd7c`) changed `plugin.yml` and the permission helpers. Neither is
  merged as of 2026-10-26. Check `main` first; if they are still unmerged, branch from `main`, keep the diff small and
  name the files that will conflict in the issue comment.
- knk-plugin: Gradle on Java 21, compiles and tests with JDK 25 (knk-plugin `CLAUDE.md`); install a JDK 25 as in the
  alpha run 1 handoff § 2.4 if none is present.

## 5. Done

- Code pushed on `claude/custom-enchantment-permissions`; `./gradlew test` and `./gradlew build -x deployToDevServer`
  green (or known reds listed).
- Issue: comment with branch, commits, tests, the **exact node list for the developer to grant to Default** (and any
  for Staff/Admin, e.g. the `/ce` admin nodes, as a suggestion), and a live checklist (non-op Default player with the
  nodes granted can use each enchantment type; without them, can't; op still can). Label `status:in-review`.
- `docs/ACTIVE_SESSIONS.md` row (claim before editing, update when done); a short dated report under `docs/reports/`;
  `FEATURE_REGISTER.md` / guides updated where behaviour changed.
