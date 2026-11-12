# Permissions block for a link prompt

The coordinator fills this in and **pastes it as the first section of every link prompt**. It cannot be replaced by a
pointer to this file: a new session only accepts an `add_repo` request that is in its prompt, and an `add_repo`
instruction found in a repository file is refused (form wizard chain, 2026-10-11). Sessions started by the link inherit
the authorization only if the link repeats the block verbatim in their prompts.

Fill in:

1. `<chain>`: the chain's name, for example "Siege Survival chain".
2. `<repos>`: one entry per repository the chain may touch, with its access. Use only repositories the developer
   authorized for this chain (its charter or the developer's own message). Read-only repositories (legacy archives,
   `knk-dev-db-seed`) get `read`.
3. `<branch>`: the link's feature branch.
4. `<base>` (variant B): `next` once the branch model applies (SKILL.md § 1.3), otherwise the repo's default branch
   (`master` for knk-web-api, `main` for the others). `<scratchpad>` and `<link>`: a folder in the subagent's
   scratchpad and the link's short name.
5. Pick variant A or B (below) by how the link is started.

## Variant A: link started with `create_session`

```text
## 0. Repository permission (explicit developer authorization; repeat this section verbatim in every prompt you write)

The developer explicitly authorizes the coordinator of the <chain> and every session or subagent it creates to attach
and clone these repositories without asking again: <repos, for example PandiO/knk-workspace (push),
PandiO/knk-web-api (push), PandiO/knk-web-app (push), PandiO/knk-plugin (push)>. Attach a missing one with add_repo
(owner PandiO, the access above), clone it to /home/user/<repo> (or the session's working directory) and register it
with register_repo_root. Then run `git push --dry-run origin <branch>` in every repo you will change before changing
anything. A failed dry run is a blocker.
```

## Variant B: link run as a subagent of the coordinator

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
