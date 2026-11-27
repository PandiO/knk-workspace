# Active Sessions

**Status:** Living tracker · **Last updated:** 2026-11-27

Live tracker of in-progress work across the four Knights and Kings repos (`knk-workspace`, `knk-web-app`,
`knk-web-api`, `knk-plugin`), referenced by `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`.

**How to use this file:**
1. Read only the "In progress" table, fresh:
   `git fetch origin && git show origin/main:docs/ACTIVE_SESSIONS.md | awk '/^## /{p=/^## In progress/} p'`.
   A row overlapping your scope: stop and flag it.
2. Add a row when you start, scoped by **feature**, not by repo. One line of at most 400 characters: feature with
   issue link (`PandiO/knk-workspace#123`) and report link, branch and repos, owner, a short status. Detail belongs
   in the issue or report, not here.
3. Update Status and Last updated when you pause. When you finish, move the row verbatim to the current month's
   file of the [sessions archive](reports/sessions-archive/README.md); a row whose work is merged but waits for the
   developer's test stays here as "In review".
4. `python3 scripts/sessions-archive/archive_sessions.py --flag --gh` lists rows that look finished or are too long;
   `--move <lines>` moves rows to the archive. The manager run does this daily.
5. Parallel sessions edit this file: on a merge conflict keep both rows.
6. **Branch convention:** one standing branch per feature and repo; check for one before forking a new branch.


## In progress

| Feature | Repos / files claimed | Owner (human / session) | Status | Started | Last updated |
|---|---|---|---|---|---|
| Token efficiency chain — coordinator ([#987](https://github.com/PandiO/knk-workspace/issues/987); [report](reports/2026-11-27-token-efficiency-chain.md)) | knk-workspace from `main`: `.claude/skills/`, `docs/ai-agents/`, this board, `scripts/sessions-archive/` | Coordinator 2 `session_01R1w2UuEXhepWcgm7ApQ7rs`, cloud | In progress: L0–L5 merged (`main` and `next`); L6 (#1022) running | 2026-11-27 | 2026-11-27 |
| Regions get the right kind at creation ([#991](https://github.com/PandiO/knk-workspace/issues/991)) | `claude/region-domain-type-991` from `next`: knk-web-api `DomainRegionNameFinalizer` | Session, local desktop | **In progress** | 2026-11-22 | 2026-11-22 |
| Landmarks as a Domain subtype chain — coordinator ([#976](https://github.com/PandiO/knk-workspace/issues/976); [report](reports/2026-11-22-landmark-domain-chain.md)) | `claude/landmark-*` from `next`: all four repos | Coordinator session_01R1w2UtYX9XFbTVUFy6zJUb | **In review:** every link merged into `next`; waits for the developer's test | 2026-11-22 | 2026-11-24 |
| NPC ladder down from a roof hatch ([#956](https://github.com/PandiO/knk-workspace/issues/956)) | `claude/npc-ladder-down-956` from `next`: knk-plugin `ClimbHold`, knk-workspace | Session, local desktop | **In review:** knk-plugin#119, knk-workspace#964 not merged | 2026-11-21 | 2026-11-21 |
| NPC push return loop ([#953](https://github.com/PandiO/knk-workspace/issues/953)) | `claude/npc-push-return-loop-953` from `next`: knk-plugin `core/npc/nav/`, knk-workspace | Session, local desktop | **In review:** knk-plugin#117, knk-workspace#957 not merged | 2026-11-21 | 2026-11-21 |
| NPC protect command `/knk npc nav protect` ([#954](https://github.com/PandiO/knk-workspace/issues/954)) | `claude/npc-protect-command-954` from `next`: knk-plugin `paper/npc/nav/`, knk-workspace | Session, local desktop | **In review:** knk-plugin#116, knk-workspace#959 wait for the developer's OK | 2026-11-21 | 2026-11-21 |
| NPC goal not reachable on foot ([#848](https://github.com/PandiO/knk-workspace/issues/848)) | `claude/npc-unreachable-goal-848` from `next`: knk-plugin `NpcNavigationService`, knk-workspace | Session, local desktop | **In review:** knk-plugin#118, knk-workspace#960 wait for the developer's OK | 2026-11-21 | 2026-11-21 |
| Siege shop chain — coordinator ([#611](https://github.com/PandiO/knk-workspace/issues/611); [report](reports/2026-11-20-siege-shop-chain.md)) | `claude/siege-shop-l<n>` from `next`: all four repos | Coordinator session_01R1w2UuyXat2GBcJjHG3RRV | **In review:** L1–L6 merged into `next`; waits for the developer's smoke tests | 2026-11-20 | 2026-11-20 |
| Siege weapons chain — coordinator ([#354](https://github.com/PandiO/knk-workspace/issues/354); [report](reports/2026-11-19-siege-weapons-chain.md)) | `claude/siege-weapons-l<n>` from `next`: all four repos | Coordinator session_01R1w2UuyXat2GBcJjHG3RRV | **Paused (blocked):** L1, L2, L2b in `next`; L3 #784 waits for #614 and the developer | 2026-11-19 | 2026-11-19 |
| Production, storage and transport chain — coordinator ([#22](https://github.com/PandiO/knk-workspace/issues/22); [report](reports/2026-11-19-production-chain.md)) | `claude/item-identity-141`, `claude/production-*` from `next`: all four repos | Coordinator session_01R1w2UtB6J4UtRJL3foJgcj | **Waiting for the developer:** L0–P12 in `next`; L28 #249 and smoke tests open | 2026-11-19 | 2026-11-21 |
| Off-road navigation and walk-trail quality chain — coordinator ([#698](https://github.com/PandiO/knk-workspace/issues/698); [report](reports/2026-11-17-navigation-offroad-chain.md)) | `claude/offroad-*` from `next`: knk-plugin, knk-workspace | Coordinator session_01R1w2UuBBnWjqekMFxEMefN | **In review:** all merged into `next`; waits for promotion | 2026-11-17 | 2026-11-25 |
| Dashboard tables: related entity names instead of ids ([#608](https://github.com/PandiO/knk-workspace/issues/608)) | `claude/related-display-fields-608`: knk-workspace, knk-web-api, knk-web-app | Link session for manager session_01R1w2UsqRcMCKuAL6TKeZaY | **Phase 1:** design written, waits for the developer's OK | 2026-11-15 | 2026-11-15 |
| Chain 3 follow-ups chain — coordinator ([#564](https://github.com/PandiO/knk-workspace/issues/564); [report](reports/2026-11-15-chain3-followups-chain.md)) | from `next`: all four repos | Coordinator session_01R1w2UtFH53Hvmd8EZwoE7Y | **In review:** L1–L7 merged into `next`; waits for the developer's test | 2026-11-15 | 2026-11-15 |
| Staff web app follow-ups chain — coordinator ([#517](https://github.com/PandiO/knk-workspace/issues/517); [report](reports/2026-11-14-staff-web-followups-chain.md)) | from `next`: knk-web-app, knk-web-api | Coordinator session, cloud | **In review:** L1–L3 merged into `next`; waits for the developer's test | 2026-11-14 | 2026-11-15 |
| NPC navigation follow-ups chain — coordinator ([#358](https://github.com/PandiO/knk-workspace/issues/358); [report](reports/2026-11-14-npc-navigation-followups-chain.md)) | `claude/npc-followups-l<n>` from `next`: knk-plugin, knk-workspace | Coordinator session_01R1w2Ut1nDWtU1DGnKEVrmy | **In review:** links merged into `next`; waits for the developer's retest | 2026-11-14 | 2026-11-18 |
| Web app chain 3: screens, access model, small fixes — coordinator ([#24](https://github.com/PandiO/knk-workspace/issues/24); [report](reports/2026-11-08-ux-chain-3.md)) | `claude/dashboard-access-280` and others: knk-web-app, knk-web-api, knk-workspace | Coordinator session_01CgFbaWUY3PLpXfaGJnN7h4 | **In review:** AM3 not merged; P1 #261 open, other links closed | 2026-11-08 | 2026-11-12 |
| NPC behavior model for guards ([#234](https://github.com/PandiO/knk-workspace/issues/234)) | `claude/npc-behavior-model`: knk-workspace `specs/npc-platform/BEHAVIOR_MODEL.md` | Design sessions (developer) | **In review:** docs only, PR #235 not merged | 2026-11-04 | 2026-11-05 |
| Citizens verification for NPC hybrid navigation ([#241](https://github.com/PandiO/knk-workspace/issues/241); [report](reports/2026-11-10-citizens-desk-check-and-spike.md)) | `claude/npc-behavior-model` (PR #235): knk-workspace report and guide | Cloud session_01R1w2Uw7oSFwa5Hr2kgeQxq | **In review:** #242 closed; #243, #244 verdicts "go with caveats" | 2026-11-10 | 2026-11-11 |
| Siege pre-game gate view ([#213](https://github.com/PandiO/knk-workspace/issues/213)) and gate pass-through styles (#167) | `claude/siege-pregame-gate-view`: knk-plugin, knk-web-api, knk-web-app | Developer / cloud session | **In review:** not merged; developer tests it in the next alpha run | 2026-11-02 | 2026-11-03 |
| Ability cooldown boss bars ([#202](https://github.com/PandiO/knk-workspace/issues/202); #201 closed) | `claude/enchantments-201-202`: merged into trunk, not deployed | Session, cloud | **In review:** waits for the developer's re-check of #202 | 2026-11-02 | 2026-11-02 |
| Siege Survival implementation chain ([#41](https://github.com/PandiO/knk-workspace/issues/41); [report](reports/2026-11-03-siege-survival-chain.md)) | `claude/siege-survival`: knk-plugin, knk-web-api | Coordinator session, cloud | **In review:** S1–S5, S7, S8 done; paused at the live-test gates | 2026-11-03 | 2026-11-08 |
| Invisibility hides armour and held items ([#211](https://github.com/PandiO/knk-workspace/issues/211); [report](reports/2026-11-02-invisibility-full-hide-and-lore-wrap.md)) | `claude/invisibility-full-hide`: knk-plugin, merged into `main` | Session, cloud | **In review:** waits for the developer's live check | 2026-11-02 | 2026-11-02 |
| Alpha run 1 P2/P3 fixes — coordinator ([#149](https://github.com/PandiO/knk-workspace/issues/149)) | `claude/alpha-run-1-*`: all four repos; F, G, I merged | Developer + coordinator session | **In review:** waits for the developer's tests and merges | 2026-10-27 | 2026-11-03 |
| Closed alpha: Bedrock crossplay trial ([#43](https://github.com/PandiO/knk-workspace/issues/43); [report](reports/2026-10-24-alpha-crossplay-trial.md)) | NAS `knk-alpha`: Geyser, Floodgate, playit tunnel | Session, cloud | **In progress (working)** | 2026-10-24 | 2026-10-24 |
| Bedrock menu transitions (cross-play finding 2026-10-24) | `claude/cool-lovelace-70r1e2`: knk-plugin, merged into `main` `262c1095` | Session | **In review:** waits for the developer's closed-alpha check | 2026-10-24 | 2026-10-25 |
| Navigation destination engine chain — coordinator ([#25](https://github.com/PandiO/knk-workspace/issues/25); [report](reports/2026-11-18-destination-engine-chain.md)) | `claude/navigation-destination-engine` from `next`: knk-plugin, knk-web-api | Coordinator session_01R1w2UvZSm3y5hAXB8VfYuv | **Waiting for the developer:** L1–L4 in `next`; L5 #747 waits for testing | 2026-11-18 | 2026-11-23 |
| Alpha performance metrics + capacity guide (KNG-232) | `claude/kng-232-perf-metrics`: knk-plugin, knk-web-api, merged | Session | **In review:** waits for the developer's live check | 2026-10-22 | 2026-10-22 |
| Arena duels P8 (KNG-222) | `claude/arena-duels`: all four repos, not merged | P8 session | **In review:** waits for the developer's live test | 2026-10-21 | 2026-10-21 |
| Closed alpha Phase 4: Minecraft container on the NAS (KNG-225; [report](reports/2026-10-24-alpha-api-4aeb794-and-plugin-stage-2.md)) | NAS `knk-alpha` stack | Session, cloud | **In review:** Stage 2 done 2026-10-24 | 2026-10-21 | 2026-10-24 |

## Recently completed

| Feature | Repos touched | Finished | Notes / link |
|---|---|---|---|

## Paused / blocked

| Feature | Repos / files claimed | Blocked on | Last updated |
|---|---|---|---|
| _(none currently)_ | | | |
