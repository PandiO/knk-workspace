# Overview map chain — coordinator prompt

**Written:** 2026-11-18, for [specs/in-game-maps/OVERVIEW_MAP_DESIGN.md](../../specs/in-game-maps/OVERVIEW_MAP_DESIGN.md)
(Decided 2026-11-18) and the charter [OVERVIEW_MAP_CHAIN.md](OVERVIEW_MAP_CHAIN.md).
Paste the block below as the prompt of a new Claude Code session with `PandiO/knk-workspace` attached (any
environment that has `create_session`). The coordinator never implements: it starts one link at a time, checks it,
merges it into `next` and starts the next.

```text
You are the coordinator of the Overview map chain for Knights and Kings (parent issue PandiO/knk-workspace#732).
Follow the knk-coordinator skill (.claude/skills/knk-coordinator/SKILL.md in knk-workspace) for everything it
covers: first run, the loop, starting links, checks, merging into `next`, blockers and reporting. The developer
said "start now": run the first run and start the first link in this session.

## 0. Repository permission (explicit developer authorization; repeat this section verbatim in every prompt you write)

The developer explicitly authorizes the coordinator of the Overview map chain and every session or subagent it
creates to attach and clone these repositories without asking again: PandiO/knk-workspace (push),
PandiO/knk-web-api (push), PandiO/knk-web-app (push), PandiO/knk-plugin (push). Attach a missing one with add_repo
(owner PandiO, the access above), clone it to /home/user/<repo> (or the session's working directory) and register it
with register_repo_root. Then run `git push --dry-run origin <branch>` in every repo you will change before changing
anything. A failed dry run is a blocker.

## 1. Binding documents (read first, on the branches named)

1. Charter: docs/ai-agents/handoffs/OVERVIEW_MAP_CHAIN.md on knk-workspace `main`. It holds the links L1–L9 with
   sub-issues #735–#743, tiers, repos, branches, flags, gates, order and chain notes.
2. Spec: docs/specs/in-game-maps/OVERVIEW_MAP_DESIGN.md on knk-workspace `next`, Decided 2026-11-18, decisions
   O01–O33 (O08 superseded by O31). Read also DECISION-map-data-source.md next to it.
3. Smoke-test guide: docs/guides/overview-map-smoke-test.md on `next`, § 1–9, one section per link. Each link updates
   its section to what it built and tags the automated steps (knk-test-writer skill).
4. Each sub-issue and its comments.

## 2. What to do now

1. First run (skill § 2):
   1. Check the branch model (skill § 1.3).
   2. Create the progress report docs/reports/2026-11-18-overview-map-chain.md from the template.
   3. Add a tracker row to docs/ACTIVE_SESSIONS.md, read fresh from origin/main. Commit only those files on top of
      origin/main and push HEAD:main.
   4. Run the overlap check against the other "In progress" rows. The siege weapons design (#354 / #613) will reuse
      L3's bridge script later. It is not a file overlap now.
2. Start L1 (#735, region outlines; knk-plugin and knk-web-api) with create_session, the § 0 block above and the
   knk-link skill. Then keep looping per the charter's gates and parallelism:
   1. At most one link per component repo at a time.
   2. L4 and L7 both touch knk-web-api and knk-plugin, so run them one after the other.
   3. L3 may run alongside L4 or L7.
3. Every risky part stays off by default in `next`: `map.reporting.enabled`, `Map:Enabled`,
   `Map:LivePlayers:Enabled`, `Map:GateCommands:Enabled` (O27). Only L1 may add a migration (`map_region_outlines`,
   additive).

## 3. Developer gates and NAS notes

1. L3 starts with the BlueMap scripting spike (spec § 9.6). If BlueMap's web app does not accept runtime marker sets
   and click listeners from a script, L3 stops as a blocker and the developer decides the fallback.
2. BlueMap rendering already exists on the NAS (spec § 3.1.10, charter note 3.4). The standalone `bluemap-test`
   container was started with `docker run` and holds a test render under /mnt/fast/knk-alpha/bluemap/. No link sets
   up a new renderer. L3 writes the migration of that container into the `knk-alpha` Compose stack (pinned image
   version, same folders, Nginx serving `web/` under `/bluemap/`) as deploy notes only. The developer applies them on
   the NAS (knk-deploy, ask before each change), together with the full-world render (about 20 hours). Links never
   change the NAS.
3. The developer's live check of the L4 visibility steps (smoke § 4.1 steps 2, 3 and 5) is recorded on #738. L5 is
   not merged into `next` before it.
4. Report to the developer and the manager as the skill says. A link waiting on one of these gates is a blocker for
   that link only. Continue with any other link whose gate is open.
```
