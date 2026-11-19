# Siege weapons chain — charter

**Status:** Ready to start (2026-11-19) — drafted by the design session; the coordinator completes it at its first run.
**Last updated:** 2026-11-19 (L2b #799 added by the coordinator on the developer's decision)
**Issues:** parent [PandiO/knk-workspace#354](https://github.com/PandiO/knk-workspace/issues/354); sub-issues per
link below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** set by the coordinator at its first run (`docs/reports/<date>-siege-weapons-chain.md`).
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/` (knk-workspace).

## 0. Binding documents

1. [specs/siege-minigame/SIEGE_WEAPONS.md](../../specs/siege-minigame/SIEGE_WEAPONS.md) on `next`, status Decided
   2026-11-19 (decisions W1–W75; acceptance A01–A36 in § 14.1; phases in § 14.2).
2. [specs/siege-minigame/DECISION-weapon-state.md](../../specs/siege-minigame/DECISION-weapon-state.md) (W63: the
   plugin owns weapon state, the API relays) binds L8 and L9.
3. [guides/siege-weapons-smoke-test.md](../../guides/siege-weapons-smoke-test.md) on `next`: § <n> belongs to L<n>; each
   link updates its section to what was built and tags the automated steps.
4. [specs/siege-minigame/DESIGN.md](../../specs/siege-minigame/DESIGN.md): the Siege minigame the weapons extend.
5. The sub-issue text **and its comments** (decisions added later live there).

## 1. Links

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | #782 | tier:3 | Entities, API, form seeds, unlocks (A01) | knk-web-api, knk-web-app | `claude/siege-weapons-l1` | `next` | none (data only) | now |
| L2 | #783 | tier:2 | Spots through world tasks, size class relative to facing (A02–A03) | knk-plugin, knk-web-api | `claude/siege-weapons-l2` | `next` | `siege.weapons.enabled`, default `false` | L1 merged into `next` |
| L2b | #799 | tier:2 | Spots through the web form's world task (developer decision 2026-11-19): form-field task type, plugin handler on L2's rules, web app fan-out; L2's in-game command removed | knk-plugin, knk-web-api, knk-web-app | `claude/siege-weapons-l2b` | `next` | `siege.weapons.enabled`, default `false` | L2 merged into `next` |
| L3 | #784 | tier:3 | Buying, placement, paste, build phase, crash and match-end restore (A04–A08, A12–A13) | knk-plugin, knk-web-api | `claude/siege-weapons-l3` | `next` | `siege.weapons.enabled` | L2 merged; #356, #611, #614 merged into `next` |
| L4 | #785 | tier:3 | Weapon damage, cracks, wreck, spot cooldown, info display, statistics (A09–A11, A14, A35) | knk-plugin, knk-web-api | `claude/siege-weapons-l4` | `next` | `siege.weapons.enabled` | L3 merged |
| L5 | #786 | tier:3 | Ballista direct fire (A15–A22) | knk-plugin | `claude/siege-weapons-l5` | `next` | `siege.weapons.enabled` | L4 merged |
| L6 | #787 | tier:3 | Trebuchet and catapult in game: aiming with preview arc, projectile, spread, impact, line of sight (A19–A27, A36) | knk-plugin | `claude/siege-weapons-l6` | `next` | `siege.weapons.enabled` | L5 merged (same repo) |
| L7 | #788 | tier:3 | Ammo effects: damage types, fall-off, knockback, fire, poison, spawn protection (A28–A29) | knk-plugin | `claude/siege-weapons-l7` | `next` | `siege.weapons.enabled` | L6 merged; #615 for ground fire (the rest can go without it) |
| L8 | #789 | tier:3 | Page credential and API relay over SignalR (A30–A31, A34) | knk-web-api, knk-plugin | `claude/siege-weapons-l8` | `next` | `siege.weapons.enabled` | L7 merged |
| L9 | #790 | tier:3 | Targeting mode on the map page, snapshot tiles and proxy (A32–A33) | knk-web-app, knk-web-api | `claude/siege-weapons-l9` | `next` | `siege.weapons.enabled` | L8 merged; #613 merged into `next` |

## 2. Gates

1. "L<n> merged into `next`": `git rev-list --count origin/next..origin/claude/siege-weapons-l<n>` is 0 in every repo
   L<n> changed.
2. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed.
3. External gates: #356 (siege points), #611 (siege shop), #614 (schematic pipeline) before L3; #613 (tactical map)
   before L9; #615 (siege fire) only for L7's ground fire. Check them on `next` the same way, never on the board.
4. Live test: the developer runs the smoke-test section of each tier:3 link before the coordinator calls the chain
   done; findings go on that link's sub-issue.

Order and parallelism: at most one link per component repo at a time. L1–L8 are sequential (each shares a repo with
the next). L9 is mostly web app work but also touches knk-web-api, so it waits for L8.

## 3. Chain notes

1. Overlaps: the Siege minigame and gate code in knk-plugin (`siege/`, `gates/`) is shared with other Siege work;
   check the sessions board for rows on those packages before starting L3–L7.
2. Existing Siege matches must behave as before while `siege.weapons.enabled` is `false` (A04); every plugin link keeps
   that true.
3. Migrations: L1 adds the tables (additive). L3, L4 and L8 may add one additive migration each if they need it
   (sub-issue § 6); no other link.
4. Model for link sessions: set by the coordinator.
