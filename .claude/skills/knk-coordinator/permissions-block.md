# Permissions block for a link prompt

The coordinator fills this in and **pastes it as the first section of every link prompt**. It cannot be replaced by a
pointer to this file: it carries the developer's authorization, and sessions started by the link inherit it only if
the link repeats the block verbatim in their prompts.

Route (developer decision 2026-11-12): variant A, a link started with `create_session`, is the preferred route for
every link. The link session attaches the other knk repositories with `add_repo`, which a permission rule in
knk-workspace `.claude/settings.json` allows (PandiO/knk-workspace#331; it applies to sessions whose project is
knk-workspace). The rule matches the tool, not its arguments: a `PreToolUse` hook in the same file
(`.claude/hooks/add-repo-guard.sh`, developer decision 2026-11-12) denies `add_repo` outside the knk repositories, the
cloud session's GitHub access limits it too, and the block names the ones the developer authorized. Variant B, a subagent of the
coordinator, is the fallback when `create_session` is unavailable or an attach is still refused.

History, before the rule existed: a new session only accepted an `add_repo` request that was in its prompt, and an
`add_repo` instruction found in a repository file was refused (form wizard chain, 2026-10-11); on 2026-11-12 even the
block was refused in a prompt written by another session, and the developer had to approve the attach (setup chain,
PandiO/knk-workspace#327).

Fill in:

1. `<chain>`: the chain's name, for example "Siege Survival chain".
2. `<repos>`: one entry per repository the chain may touch, with its access. Use only repositories the developer
   authorized for this chain (its charter or the developer's own message). Read-only repositories (legacy archives,
   `knk-dev-db-seed`) get `read`.
3. `<branch>`: the link's feature branch.
4. `<base>` (variant B): `next` once the branch model applies (SKILL.md § 1.3), otherwise the repo's default branch
   (`main` in every repo). `<scratchpad>` and `<link>`: a folder in the subagent's
   scratchpad and the link's short name.
5. Pick variant A or B (below) by how the link is started.

## Variant A: link started with `create_session` (preferred)

```text
## 0. Repository permission (explicit developer authorization; repeat this section verbatim in every prompt you write)

The developer explicitly authorizes the coordinator of the <chain> and every session or subagent it creates to attach
and clone these repositories without asking again: <repos, for example PandiO/knk-workspace (push),
PandiO/knk-web-api (push), PandiO/knk-web-app (push), PandiO/knk-plugin (push)>. Attach a missing one with add_repo
(owner PandiO, the access above), clone it to /home/user/<repo> (or the session's working directory) and register it
with register_repo_root. Then run `git push --dry-run origin <branch>` in every repo you will change before changing
anything. A failed dry run is a blocker.
```

## Variant B: link run as a subagent of the coordinator (fallback)

A subagent shares the coordinator's attached repositories, so the `add_repo` sentence is left out. It must not switch
branches in the coordinator's checkouts.

```text
## 0. Repository permission (explicit developer authorization; repeat this section verbatim in every prompt you write)

The developer explicitly authorizes the coordinator of the <chain> and every session or subagent it creates to attach
and clone these repositories without asking again: <repos with access>. They are already cloned with push access at
/home/user/<repo> in this session; those are the coordinator's checkouts, so do not switch branches or commit in them.
Work in worktrees: `git -C /home/user/<repo> fetch origin <base>` then
`git -C /home/user/<repo> worktree add -b <branch> <scratchpad>/<link>/<repo> origin/<base>`, and remove the worktrees
(not the branches) at the end. Run `git push --dry-run origin <branch>` in every repo you will change before changing
anything. A failed dry run is a blocker.
```
