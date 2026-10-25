# Linear → GitHub Issues migration

**Status:** Done 2026-10-25 · **Last updated:** 2026-10-25 · **Session:** Claude Code (cloud), branch `claude/loving-feynman-m2ve99`

## Why

Linear's free plan caps a workspace at 250 non-archived issues. The cap was hit on 2026-10-24 (275 issues), after which agents could not file new issues and the tracker collected "To file in Linear" notes. On 2026-10-25 the developer chose to move the work list to the GitHub issues of `PandiO/knk-workspace`. GitHub has no issue cap, the repos already live there, and every agent session already has the GitHub tools. Linear stays as a read-only archive, so all existing `KNG-n` links keep working.

## What was done

1. **Open issues copied:** all 112 open KNG issues (15 In Progress/In Review, 97 Backlog) were recreated:
   - The title is `[KNG-n] <Linear title>`, so a search for `[KNG-n]` finds the copy.
   - The body opens with a header line linking the Linear issue (status, priority, created date), followed by the Linear description verbatim. Linear mention tags became markdown links to the Linear issue.
   - Labels: `linear-import`, a type label (`bug` / `feature` / `improvement`), `priority:*`, and `status:in-progress` / `status:in-review`.
   - The four open parents became GitHub parents with sub-issues: KNG-83 → #22, KNG-37 → #23, KNG-140 → #24, KNG-235 → #25. Sub-issues of parents that are Done in Linear (KNG-197, KNG-182, KNG-253) have no GitHub parent; the header names the Linear parent.
   - Comments, history, attachments and closed issues were not copied; they stay in Linear.
2. **"To file" items filed:** the tracker's 15 "To file in Linear" notes became issues (table below). Four record work that was already done and were closed as completed. The menu-validation retry row matched the existing KNG-201 (#144), so it got a comment and `status:in-review` instead of a new issue.
3. **Conventions:** [GLOBAL_AGENT_INSTRUCTIONS](../ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md#github-issues-is-the-work-list) "GitHub Issues is the work list" (types as labels, status labels, `PandiO/knk-workspace#n` references, `Closes PandiO/knk-workspace#n` from any repo). `AGENTS.md`, `ACTIVE_SESSIONS.md` (header, "To file" notes → issue links), `DOCUMENTATION_MAINTENANCE.md`, `FEATURE_REGISTER.md` and the QOL backlog banner were updated to match.

**Issue types:** GitHub issue types (Bug/Feature/Task) need an organization account. `PandiO` is a user account, so GitHub dropped the types on create; type labels are used instead.

**Issue numbers:** the copies are #22–#148 except the tracker items listed below. Numbers interleave because six batches ran in parallel.

## Follow-ups (updated 2026-10-25, later the same day)

- **Label colours: done.** `bug` red, `feature` blue, `improvement` purple, `status:in-progress` yellow, `status:in-review` green, `priority:urgent|high|medium|low` red → light blue, `linear-import` grey. `priority:urgent` was created (no imported issue used it).
- **Component repos: nothing to change.** The `AGENTS.md`/`CLAUDE.md` files of knk-plugin, knk-web-api and knk-web-app never mention Linear. They defer to the shared global instructions, which now say GitHub. The remaining `Linear KNG-n` mentions are code comments citing closed issues (KNG-5, 6, 17, 41, 42); those Linear links still resolve, so they stay as history.
- [ ] **Project board (developer, GitHub UI):** Claude Code sessions can't create Projects (GraphQL is blocked and the REST API only reaches repository endpoints). Steps:
  1. github.com → your profile → Projects → **New project** → *Table*, name it "Knights and Kings".
  2. ⋯ → **Workflows** → enable **Auto-add to project** with filter `repo:PandiO/knk-workspace is:issue` (adds new issues), and **Item closed** → Status *Done*.
  3. Add the existing issues once: in the project, paste `repo:PandiO/knk-workspace is:issue is:open` in the add-item search and select all (or run *Auto-add* backfill if offered).
  4. Save views filtered on the labels, which stay the source of truth (agents can't edit Project fields): **In progress** `label:"status:in-progress"`, **In review** `label:"status:in-review"`, **Backlog** `is:open -label:"status:in-progress" -label:"status:in-review"` (sort by labels for priority), **Bugs** `is:open label:bug`.

  The plain issue list with the same filters works without a Project too.

## Tracker items filed 2026-10-25

| GitHub | Item | State |
|---|---|---|
| [#43](https://github.com/PandiO/knk-workspace/issues/43) | Closed alpha: Bedrock crossplay trial | open, in progress |
| [#45](https://github.com/PandiO/knk-workspace/issues/45) | Seeded rows that may be demo data | open |
| [#48](https://github.com/PandiO/knk-workspace/issues/48) | Docs: production-installation.md G10 / §12.3 after KNG-232 | open |
| [#51](https://github.com/PandiO/knk-workspace/issues/51) | Gates: invincible gates refuse ignition | open, in review |
| [#57](https://github.com/PandiO/knk-workspace/issues/57) | Invite-only onboarding fixes | open, in review |
| [#61](https://github.com/PandiO/knk-workspace/issues/61) | Domain names trimmed on create/update | open, in review |
| [#63](https://github.com/PandiO/knk-workspace/issues/63) | knk-web-app tsc errors in sessionPinnedRows.test.ts | open |
| [#67](https://github.com/PandiO/knk-workspace/issues/67) | Region entry action bar missing-glyph box | open, in review |
| [#70](https://github.com/PandiO/knk-workspace/issues/70) | Closed alpha Phase 7: backups deferred to beta | open |
| [#72](https://github.com/PandiO/knk-workspace/issues/72) | User form can't create a web account | open |
| [#75](https://github.com/PandiO/knk-workspace/issues/75) | Workflow step_progress duplicate-key race | open |
| [#80](https://github.com/PandiO/knk-workspace/issues/80) | Seeding:IncludeExamples + alpha cleanup | closed (done) |
| [#82](https://github.com/PandiO/knk-workspace/issues/82) | Approved seed data set + fresh dev world | closed (done) |
| [#87](https://github.com/PandiO/knk-workspace/issues/87) | Closed alpha Phase 6: web app ingress | closed (done) |
| [#90](https://github.com/PandiO/knk-workspace/issues/90) | Closed alpha Phase 5: playit.gg | closed (done) |

## KNG → GitHub mapping (112 open issues)

| Linear | GitHub | Hierarchy |
|---|---|---|
| [KNG-14](https://linear.app/kngpandi/issue/KNG-14) | [#93](https://github.com/PandiO/knk-workspace/issues/93) |  |
| [KNG-27](https://linear.app/kngpandi/issue/KNG-27) | [#78](https://github.com/PandiO/knk-workspace/issues/78) |  |
| [KNG-35](https://linear.app/kngpandi/issue/KNG-35) | [#129](https://github.com/PandiO/knk-workspace/issues/129) |  |
| [KNG-37](https://linear.app/kngpandi/issue/KNG-37) | [#23](https://github.com/PandiO/knk-workspace/issues/23) |  |
| [KNG-47](https://linear.app/kngpandi/issue/KNG-47) | [#115](https://github.com/PandiO/knk-workspace/issues/115) |  |
| [KNG-48](https://linear.app/kngpandi/issue/KNG-48) | [#105](https://github.com/PandiO/knk-workspace/issues/105) |  |
| [KNG-49](https://linear.app/kngpandi/issue/KNG-49) | [#130](https://github.com/PandiO/knk-workspace/issues/130) |  |
| [KNG-50](https://linear.app/kngpandi/issue/KNG-50) | [#41](https://github.com/PandiO/knk-workspace/issues/41) | sub-issue of [#23](https://github.com/PandiO/knk-workspace/issues/23) |
| [KNG-57](https://linear.app/kngpandi/issue/KNG-57) | [#66](https://github.com/PandiO/knk-workspace/issues/66) |  |
| [KNG-60](https://linear.app/kngpandi/issue/KNG-60) | [#58](https://github.com/PandiO/knk-workspace/issues/58) |  |
| [KNG-62](https://linear.app/kngpandi/issue/KNG-62) | [#50](https://github.com/PandiO/knk-workspace/issues/50) |  |
| [KNG-72](https://linear.app/kngpandi/issue/KNG-72) | [#126](https://github.com/PandiO/knk-workspace/issues/126) |  |
| [KNG-83](https://linear.app/kngpandi/issue/KNG-83) | [#22](https://github.com/PandiO/knk-workspace/issues/22) |  |
| [KNG-84](https://linear.app/kngpandi/issue/KNG-84) | [#97](https://github.com/PandiO/knk-workspace/issues/97) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-85](https://linear.app/kngpandi/issue/KNG-85) | [#91](https://github.com/PandiO/knk-workspace/issues/91) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-86](https://linear.app/kngpandi/issue/KNG-86) | [#86](https://github.com/PandiO/knk-workspace/issues/86) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-87](https://linear.app/kngpandi/issue/KNG-87) | [#79](https://github.com/PandiO/knk-workspace/issues/79) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-88](https://linear.app/kngpandi/issue/KNG-88) | [#74](https://github.com/PandiO/knk-workspace/issues/74) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-89](https://linear.app/kngpandi/issue/KNG-89) | [#65](https://github.com/PandiO/knk-workspace/issues/65) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-90](https://linear.app/kngpandi/issue/KNG-90) | [#60](https://github.com/PandiO/knk-workspace/issues/60) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-91](https://linear.app/kngpandi/issue/KNG-91) | [#56](https://github.com/PandiO/knk-workspace/issues/56) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-93](https://linear.app/kngpandi/issue/KNG-93) | [#110](https://github.com/PandiO/knk-workspace/issues/110) |  |
| [KNG-95](https://linear.app/kngpandi/issue/KNG-95) | [#141](https://github.com/PandiO/knk-workspace/issues/141) |  |
| [KNG-96](https://linear.app/kngpandi/issue/KNG-96) | [#138](https://github.com/PandiO/knk-workspace/issues/138) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-97](https://linear.app/kngpandi/issue/KNG-97) | [#134](https://github.com/PandiO/knk-workspace/issues/134) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-98](https://linear.app/kngpandi/issue/KNG-98) | [#127](https://github.com/PandiO/knk-workspace/issues/127) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-99](https://linear.app/kngpandi/issue/KNG-99) | [#53](https://github.com/PandiO/knk-workspace/issues/53) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-100](https://linear.app/kngpandi/issue/KNG-100) | [#124](https://github.com/PandiO/knk-workspace/issues/124) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-101](https://linear.app/kngpandi/issue/KNG-101) | [#120](https://github.com/PandiO/knk-workspace/issues/120) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-102](https://linear.app/kngpandi/issue/KNG-102) | [#113](https://github.com/PandiO/knk-workspace/issues/113) | sub-issue of [#22](https://github.com/PandiO/knk-workspace/issues/22) |
| [KNG-140](https://linear.app/kngpandi/issue/KNG-140) | [#24](https://github.com/PandiO/knk-workspace/issues/24) |  |
| [KNG-142](https://linear.app/kngpandi/issue/KNG-142) | [#38](https://github.com/PandiO/knk-workspace/issues/38) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-143](https://linear.app/kngpandi/issue/KNG-143) | [#33](https://github.com/PandiO/knk-workspace/issues/33) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-144](https://linear.app/kngpandi/issue/KNG-144) | [#30](https://github.com/PandiO/knk-workspace/issues/30) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-145](https://linear.app/kngpandi/issue/KNG-145) | [#39](https://github.com/PandiO/knk-workspace/issues/39) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-146](https://linear.app/kngpandi/issue/KNG-146) | [#109](https://github.com/PandiO/knk-workspace/issues/109) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-147](https://linear.app/kngpandi/issue/KNG-147) | [#71](https://github.com/PandiO/knk-workspace/issues/71) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-148](https://linear.app/kngpandi/issue/KNG-148) | [#81](https://github.com/PandiO/knk-workspace/issues/81) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-149](https://linear.app/kngpandi/issue/KNG-149) | [#26](https://github.com/PandiO/knk-workspace/issues/26) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-150](https://linear.app/kngpandi/issue/KNG-150) | [#122](https://github.com/PandiO/knk-workspace/issues/122) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-151](https://linear.app/kngpandi/issue/KNG-151) | [#119](https://github.com/PandiO/knk-workspace/issues/119) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-152](https://linear.app/kngpandi/issue/KNG-152) | [#117](https://github.com/PandiO/knk-workspace/issues/117) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-153](https://linear.app/kngpandi/issue/KNG-153) | [#112](https://github.com/PandiO/knk-workspace/issues/112) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-154](https://linear.app/kngpandi/issue/KNG-154) | [#108](https://github.com/PandiO/knk-workspace/issues/108) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-155](https://linear.app/kngpandi/issue/KNG-155) | [#104](https://github.com/PandiO/knk-workspace/issues/104) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-156](https://linear.app/kngpandi/issue/KNG-156) | [#98](https://github.com/PandiO/knk-workspace/issues/98) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-157](https://linear.app/kngpandi/issue/KNG-157) | [#95](https://github.com/PandiO/knk-workspace/issues/95) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-158](https://linear.app/kngpandi/issue/KNG-158) | [#92](https://github.com/PandiO/knk-workspace/issues/92) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-159](https://linear.app/kngpandi/issue/KNG-159) | [#139](https://github.com/PandiO/knk-workspace/issues/139) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-160](https://linear.app/kngpandi/issue/KNG-160) | [#64](https://github.com/PandiO/knk-workspace/issues/64) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-161](https://linear.app/kngpandi/issue/KNG-161) | [#83](https://github.com/PandiO/knk-workspace/issues/83) | sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24) |
| [KNG-163](https://linear.app/kngpandi/issue/KNG-163) | [#85](https://github.com/PandiO/knk-workspace/issues/85) |  |
| [KNG-170](https://linear.app/kngpandi/issue/KNG-170) | [#76](https://github.com/PandiO/knk-workspace/issues/76) |  |
| [KNG-176](https://linear.app/kngpandi/issue/KNG-176) | [#35](https://github.com/PandiO/knk-workspace/issues/35) |  |
| [KNG-177](https://linear.app/kngpandi/issue/KNG-177) | [#52](https://github.com/PandiO/knk-workspace/issues/52) |  |
| [KNG-178](https://linear.app/kngpandi/issue/KNG-178) | [#49](https://github.com/PandiO/knk-workspace/issues/49) |  |
| [KNG-179](https://linear.app/kngpandi/issue/KNG-179) | [#107](https://github.com/PandiO/knk-workspace/issues/107) |  |
| [KNG-180](https://linear.app/kngpandi/issue/KNG-180) | [#102](https://github.com/PandiO/knk-workspace/issues/102) |  |
| [KNG-181](https://linear.app/kngpandi/issue/KNG-181) | [#147](https://github.com/PandiO/knk-workspace/issues/147) |  |
| [KNG-183](https://linear.app/kngpandi/issue/KNG-183) | [#73](https://github.com/PandiO/knk-workspace/issues/73) |  |
| [KNG-184](https://linear.app/kngpandi/issue/KNG-184) | [#68](https://github.com/PandiO/knk-workspace/issues/68) |  |
| [KNG-185](https://linear.app/kngpandi/issue/KNG-185) | [#44](https://github.com/PandiO/knk-workspace/issues/44) |  |
| [KNG-187](https://linear.app/kngpandi/issue/KNG-187) | [#36](https://github.com/PandiO/knk-workspace/issues/36) |  |
| [KNG-189](https://linear.app/kngpandi/issue/KNG-189) | [#28](https://github.com/PandiO/knk-workspace/issues/28) |  |
| [KNG-191](https://linear.app/kngpandi/issue/KNG-191) | [#137](https://github.com/PandiO/knk-workspace/issues/137) |  |
| [KNG-192](https://linear.app/kngpandi/issue/KNG-192) | [#133](https://github.com/PandiO/knk-workspace/issues/133) | Linear parent KNG-182 (Done in Linear, not copied) |
| [KNG-194](https://linear.app/kngpandi/issue/KNG-194) | [#59](https://github.com/PandiO/knk-workspace/issues/59) |  |
| [KNG-196](https://linear.app/kngpandi/issue/KNG-196) | [#146](https://github.com/PandiO/knk-workspace/issues/146) | sub-issue of [#23](https://github.com/PandiO/knk-workspace/issues/23) |
| [KNG-198](https://linear.app/kngpandi/issue/KNG-198) | [#135](https://github.com/PandiO/knk-workspace/issues/135) |  |
| [KNG-199](https://linear.app/kngpandi/issue/KNG-199) | [#125](https://github.com/PandiO/knk-workspace/issues/125) |  |
| [KNG-201](https://linear.app/kngpandi/issue/KNG-201) | [#144](https://github.com/PandiO/knk-workspace/issues/144) |  |
| [KNG-202](https://linear.app/kngpandi/issue/KNG-202) | [#31](https://github.com/PandiO/knk-workspace/issues/31) |  |
| [KNG-203](https://linear.app/kngpandi/issue/KNG-203) | [#84](https://github.com/PandiO/knk-workspace/issues/84) |  |
| [KNG-204](https://linear.app/kngpandi/issue/KNG-204) | [#94](https://github.com/PandiO/knk-workspace/issues/94) |  |
| [KNG-209](https://linear.app/kngpandi/issue/KNG-209) | [#111](https://github.com/PandiO/knk-workspace/issues/111) | Linear parent KNG-197 (Done in Linear, not copied) |
| [KNG-210](https://linear.app/kngpandi/issue/KNG-210) | [#29](https://github.com/PandiO/knk-workspace/issues/29) | Linear parent KNG-197 (Done in Linear, not copied) |
| [KNG-213](https://linear.app/kngpandi/issue/KNG-213) | [#118](https://github.com/PandiO/knk-workspace/issues/118) | Linear parent KNG-197 (Done in Linear, not copied) |
| [KNG-215](https://linear.app/kngpandi/issue/KNG-215) | [#123](https://github.com/PandiO/knk-workspace/issues/123) | Linear parent KNG-197 (Done in Linear, not copied) |
| [KNG-217](https://linear.app/kngpandi/issue/KNG-217) | [#54](https://github.com/PandiO/knk-workspace/issues/54) | Linear parent KNG-197 (Done in Linear, not copied) |
| [KNG-219](https://linear.app/kngpandi/issue/KNG-219) | [#46](https://github.com/PandiO/knk-workspace/issues/46) | Linear parent KNG-197 (Done in Linear, not copied) |
| [KNG-220](https://linear.app/kngpandi/issue/KNG-220) | [#42](https://github.com/PandiO/knk-workspace/issues/42) | Linear parent KNG-197 (Done in Linear, not copied) |
| [KNG-221](https://linear.app/kngpandi/issue/KNG-221) | [#131](https://github.com/PandiO/knk-workspace/issues/131) | Linear parent KNG-197 (Done in Linear, not copied) |
| [KNG-222](https://linear.app/kngpandi/issue/KNG-222) | [#37](https://github.com/PandiO/knk-workspace/issues/37) | Linear parent KNG-197 (Done in Linear, not copied) |
| [KNG-223](https://linear.app/kngpandi/issue/KNG-223) | [#106](https://github.com/PandiO/knk-workspace/issues/106) |  |
| [KNG-224](https://linear.app/kngpandi/issue/KNG-224) | [#114](https://github.com/PandiO/knk-workspace/issues/114) | Linear parent KNG-197 (Done in Linear, not copied) |
| [KNG-225](https://linear.app/kngpandi/issue/KNG-225) | [#89](https://github.com/PandiO/knk-workspace/issues/89) |  |
| [KNG-226](https://linear.app/kngpandi/issue/KNG-226) | [#132](https://github.com/PandiO/knk-workspace/issues/132) |  |
| [KNG-228](https://linear.app/kngpandi/issue/KNG-228) | [#100](https://github.com/PandiO/knk-workspace/issues/100) |  |
| [KNG-232](https://linear.app/kngpandi/issue/KNG-232) | [#101](https://github.com/PandiO/knk-workspace/issues/101) |  |
| [KNG-233](https://linear.app/kngpandi/issue/KNG-233) | [#77](https://github.com/PandiO/knk-workspace/issues/77) |  |
| [KNG-235](https://linear.app/kngpandi/issue/KNG-235) | [#25](https://github.com/PandiO/knk-workspace/issues/25) |  |
| [KNG-236](https://linear.app/kngpandi/issue/KNG-236) | [#96](https://github.com/PandiO/knk-workspace/issues/96) | sub-issue of [#25](https://github.com/PandiO/knk-workspace/issues/25) |
| [KNG-237](https://linear.app/kngpandi/issue/KNG-237) | [#103](https://github.com/PandiO/knk-workspace/issues/103) | sub-issue of [#25](https://github.com/PandiO/knk-workspace/issues/25) |
| [KNG-238](https://linear.app/kngpandi/issue/KNG-238) | [#69](https://github.com/PandiO/knk-workspace/issues/69) | sub-issue of [#25](https://github.com/PandiO/knk-workspace/issues/25) |
| [KNG-239](https://linear.app/kngpandi/issue/KNG-239) | [#62](https://github.com/PandiO/knk-workspace/issues/62) | sub-issue of [#25](https://github.com/PandiO/knk-workspace/issues/25) |
| [KNG-240](https://linear.app/kngpandi/issue/KNG-240) | [#55](https://github.com/PandiO/knk-workspace/issues/55) | sub-issue of [#25](https://github.com/PandiO/knk-workspace/issues/25) |
| [KNG-241](https://linear.app/kngpandi/issue/KNG-241) | [#32](https://github.com/PandiO/knk-workspace/issues/32) |  |
| [KNG-242](https://linear.app/kngpandi/issue/KNG-242) | [#47](https://github.com/PandiO/knk-workspace/issues/47) |  |
| [KNG-244](https://linear.app/kngpandi/issue/KNG-244) | [#40](https://github.com/PandiO/knk-workspace/issues/40) |  |
| [KNG-246](https://linear.app/kngpandi/issue/KNG-246) | [#34](https://github.com/PandiO/knk-workspace/issues/34) |  |
| [KNG-247](https://linear.app/kngpandi/issue/KNG-247) | [#27](https://github.com/PandiO/knk-workspace/issues/27) |  |
| [KNG-248](https://linear.app/kngpandi/issue/KNG-248) | [#148](https://github.com/PandiO/knk-workspace/issues/148) |  |
| [KNG-249](https://linear.app/kngpandi/issue/KNG-249) | [#145](https://github.com/PandiO/knk-workspace/issues/145) |  |
| [KNG-251](https://linear.app/kngpandi/issue/KNG-251) | [#143](https://github.com/PandiO/knk-workspace/issues/143) |  |
| [KNG-252](https://linear.app/kngpandi/issue/KNG-252) | [#99](https://github.com/PandiO/knk-workspace/issues/99) |  |
| [KNG-260](https://linear.app/kngpandi/issue/KNG-260) | [#140](https://github.com/PandiO/knk-workspace/issues/140) | Linear parent KNG-253 (Done in Linear, not copied) |
| [KNG-261](https://linear.app/kngpandi/issue/KNG-261) | [#142](https://github.com/PandiO/knk-workspace/issues/142) | Linear parent KNG-253 (Done in Linear, not copied) |
| [KNG-262](https://linear.app/kngpandi/issue/KNG-262) | [#121](https://github.com/PandiO/knk-workspace/issues/121) |  |
| [KNG-264](https://linear.app/kngpandi/issue/KNG-264) | [#136](https://github.com/PandiO/knk-workspace/issues/136) |  |
| [KNG-265](https://linear.app/kngpandi/issue/KNG-265) | [#128](https://github.com/PandiO/knk-workspace/issues/128) |  |
| [KNG-267](https://linear.app/kngpandi/issue/KNG-267) | [#116](https://github.com/PandiO/knk-workspace/issues/116) |  |
| [KNG-274](https://linear.app/kngpandi/issue/KNG-274) | [#88](https://github.com/PandiO/knk-workspace/issues/88) |  |
