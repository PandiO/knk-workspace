# Alpha test run 1 — package F: siege results (2026-10-27)

**Status:** In review. Pushed on `claude/alpha-run-1-results` (stacked on package E's `claude/alpha-run-1-rewards`):
knk-plugin `61f1008` (from E `3461708`), knk-web-api `1972569` (from E `16a47f5`), knk-web-app `6917a0f` (from E
`ead3b39`). Not merged, not deployed, not live-tested
**Last updated:** 2026-10-27
**Issues:** [PandiO/knk-workspace#163](https://github.com/PandiO/knk-workspace/issues/163) (scoreboard),
[#164](https://github.com/PandiO/knk-workspace/issues/164) (result message),
[#198](https://github.com/PandiO/knk-workspace/issues/198) (post-match phase),
[#199](https://github.com/PandiO/knk-workspace/issues/199) (final countdown),
[#174](https://github.com/PandiO/knk-workspace/issues/174) (results log); parent
[#149](https://github.com/PandiO/knk-workspace/issues/149)
**Handoff:** [2026-10-27-alpha-run-1-p2-p3.md](../../../ai-agents/handoffs/2026-10-27-alpha-run-1-p2-p3.md) § 1 ·
**Findings:** [test-run-1-findings.md](test-run-1-findings.md) (1.3, 1.4, 1.5) · **Design:**
[siege DESIGN.md § 6.10](../../../specs/siege-minigame/DESIGN.md#610-results-final-countdown-and-the-post-match-phase-alpha-run-1-2026-10-27-not-merged),
§ 5.4, § 7.6, § 11

Claude Code (background subagent of the P2/P3 coordinator session) implemented all five issues as the developer
decided on 2026-10-27.

## 1. What the code did, and what changed

| Issue | Found on E's branch | Change |
|---|---|---|
| #163 scoreboard | `SiegeScoreboardPresenter` gave members per-team boards at the start and on a rejoin/admin join (`memberJoinedMatch` was already wired for #150/#152, so a rejoining **member** did get the board). But the tab name `[Team] name [K/D]` was set with `Player.playerListName`, which every player sees, and the board was taken away at `matchEnded`. Non-members saw the siege tab names on the shared board; nothing marked members there. | **Plugin:** `[K/D]` is now a `PLAYER_LIST` objective (fixed number format `[k/d]`) on the siege boards only; no global tab name any more. On the shared `ScoreboardUtil` board a member moves to a twin of their rank team (`default.siege`, `tier_12.siege`, `staff.siege` …: same colour and prefix, suffix ` [Siege]`) from the start or their late join until they are restored (`ScoreboardUtil.setSiegeTag`); `setScoreboard` (rank refreshes) keeps the tag. Non-members keep the shared board unchanged. `AfkPresentation` reads the shared board for a tagged member. |
| #198 post-match | The match ended in `ENDING` and members were restored at once. | **Core:** new `SiegePhase.POST_MATCH` (match-active, blocks discovery). `endMatch` goes there for `postMatchSeconds` (> 0), else `ENDING` as before; at 0 s `PostMatchOverEffect` + cooldown. `stop()` during it emits `PostMatchOverEffect` (no second end). **Plugin:** at the end `complete` is sent as before, the members are teleported to the scenario hub (respawned/fire out) with a Victory!/Defeat/Draw title and the return time; sidebar "Match over / Return in". The round is kept (`SiegeLobbyRuntime.matchOver`), released when the time is up. `/siege leave` restores at once ("result and rewards are kept"); quit restores like a normal end; an outage action sends just that member home; respawn goes to the hub. Kept rejoin places end with the match. **API:** `SiegeConfiguration.PostMatchSeconds` (default 30, 0–600), migration `AddSiegePostMatchSeconds`. **Web app:** Siege settings "After the match". |
| #164 result | "Your match: k kills, d deaths, best streak, captures" plus the KNG-16 reward lines and a grey detail line. | `SiegeResultMessage`: `[Siege] Victory! 5 kills · 2 deaths · +120 coins, +12 XP [details] [match page]`; hover: lobby/outcome, end reason, team, kills, deaths, best streak, captures, gate damage, active of match time, rewards (coins with the KNG-16 breakdown, gems, XP, win, objectives gained, captures, gate damage steps, taking part), zeros included. `SiegeResultDelivery` shows it once: with the rewards when `complete` answers first, else after 5 s without them and a "Your rewards: …" line (own hover) when they come; spooled and unrecorded rounds say why there are none. |
| #199 countdown | — | `FinalCountdownEffect` for each of the last 15 s of `IN_PROGRESS`: action bar "The siege ends in N seconds", hat tick (higher pitch for the last 5), title for the last 5; sidebar time red. |
| #174 results log | Per-match rows existed (`siege_matches`, participants, objective results). `GET api/siege-matches` and `{id}` are not `[AllowAnonymous]`: default-deny gives anonymous visitors 401, and they return every number unfiltered. | **API:** `[AllowAnonymous]` `GET api/siege-matches/public/users/{userId}?limit=` and `public/{id}` (finished matches only, `SiegeMatchHistoryService`): match facts public, each participant's numbers filtered by their statistics visibility in the `siege` context (see § 2). **Web app:** "Siege matches" table (20 newest) on `/players/:username`, public page `/siege/matches/:id`. **Plugin:** `/siege history` (last 5, asked as the player via `X-Acting-User-Id`), `[details]` links and a profile link; `SiegeMatchHistoryApi` port. |

### Decisions taken here (review)

- **Public access (#174):** the existing GETs stay as they are; two new read-only anonymous endpoints serve the public
  pages. Visibility maps the participant's numbers to the existing statistics settings (kills → `pvp_kills`, deaths,
  best streak → `highest_killstreak`, captures → `objectives_captured`, `gate_damage`, coins/gems → `economy`, in the
  `siege` context): self and staff see all, other signed-in players what is set to Everyone, anonymous visitors none.
  Who played, teams, outcome, objectives and capturers, XP and active time are public (XP gained and active playtime
  are always-public statistics). Running matches aren't shown.
- **Base URL (#164/#174):** the plugin uses its own `web.public-url` (`config.yml`, already used for `/account link`),
  which must hold the same value as the API's `App:PublicBaseUrl`. No API change. Empty: no links.
- **`[K/D]`** moved from a global custom tab name to a `PLAYER_LIST` objective on the siege boards (only members see
  it). Other members' names in a member's tab list carry the siege team prefix as before.
- **Post-match default 30 s**, also used when an older API sends no value; the plugin's pre-#198 compatibility
  constructors (tests) mean 0. Leave/quit during the wait don't count as leaving the match (no `participantLeft`,
  rewards kept). An admin can `/siege admin stop` to cut the wait short (the match stays recorded).
- **Combat** outside the running match now says "There is no fighting outside the running match." (was "The siege
  hasn't started yet.", also shown at the hub after the end).

## 2. Package G (#169) and the merge

G's branch (`claude/alpha-run-1-effects`, knk-plugin `911eb2a`, not merged, not in this base) routes board changes
through `utils/ViewerScoreboards`. A trial merge (`git merge-tree`) of F's head with G's conflicts only in
`SiegeScoreboardPresenter.java`; `ScoreboardUtil.java` and `KnKPlugin.java` merge cleanly. Expected resolution:

- F keeps every board assignment in two helpers, `SiegeScoreboardPresenter.setBoard(player, board)` and
  `boardOf(player)`. Their bodies become `ViewerScoreboards.set(player, board)` and `ViewerScoreboards.current(player)`
  (add the `utils.ViewerScoreboards` import); keep F's version of `show`/`restore`, which already call the helpers.
- `ScoreboardUtil.setScoreboard` takes G's `ViewerScoreboards.set(p, scoreboard)` line; F's siege tag only moves the
  player between teams on the shared board (no board assignment), so it needs nothing from G. G's name-tag mirror
  copies team prefixes and suffixes, so the ` [Siege]` suffix shows in the victim's mirror too (name tags hidden).
- The `PLAYER_LIST` objective is copied by G's `syncObjectives` like the sidebar.

## 3. Tests

| Repo | Baseline (E's head) | `claude/alpha-run-1-results` |
|---|---|---|
| knk-plugin `gradle build -x deployToDevServer` (JDK 25 toolchain) | `3461708`: core 2387, api-client 283 (2 skipped), paper 2227 (18 skipped), 0 failures | `61f1008`: core 2392, api-client 286 (2 skipped), paper 2241 (18 skipped), 0 failures; build green. GitHub Actions "Build": success on `d1c674b` (`61f1008` was running at writing time) |
| knk-web-api `dotnet test` | **not run** (NuGet blocked in this sandbox) | **not run**. Changed files syntax-checked with Roslyn (0 diagnostics). GitHub Actions "Migrations (fresh DB)" on `1972569`: **success** (builds, every migration applies to an empty MySQL 8, no pending model changes) |
| knk-web-app `npm run test:ci` (npm 11) | `ead3b39`: 205 suites, 1323 tests, all passed | `6917a0f`: 206 suites, 1329 tests, all passed; `tsc --noEmit`: 9 errors, all in test files, same as the baseline |

New tests: core `SiegeLobbyStateMachineTest` (post-match wait then cooldown, timeout to post-match, stop during the
wait, countdown covers exactly the last 15 s; full loop with the countdown), `SiegePhaseTest`; api-client
`SiegeMapperTest` (postMatchSeconds incl. default and 0), `SiegeMatchHistoryApiImplTest`; paper
`SiegeResultMessageTest` (compact line, hover with zeros, granted/pending/spooled/unrecorded, outcome per alliance,
URL, delivery once / follow-up), `SiegeHistoryMessageTest`, `ScoreboardUtilTest` (tag team names). API (written,
**not run here**): `SiegeMatchHistoryServiceTests` (facts public, anonymous hidden, per-setting visibility for
signed-in players, own row, staff, finished only, aborted), `SiegeConfigurationServiceTests` (post-match default and
range), `EndpointAccessRulesTests` allow-list. Web app: `SiegeMatchPage.test.tsx`, profile list tests, settings field.

**The developer must run `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` on `1972569`** (with E's
tests; baseline on `master`: 4 known reds per the handoff).

## 4. Live checklist for test run 2

Before: apply the migrations (E's and `AddSiegePostMatchSeconds`); set `web.public-url` in the plugin's `config.yml`
to the API's `App:PublicBaseUrl`; deploy plugin, API and web app from the package branches.

1. **#163:** start a match with two players; a third player (not a member) keeps the normal tab list/board, and sees
   both members as `Name [Siege]` in the tab list and over their heads. Members see the siege sidebar, team colours
   and `[k/d]` in their tab list. A member who disconnects and rejoins (or is added with `/siege join <player>`) gets
   the siege board and team colours again. After the return the tag is gone.
2. **#199:** the last 15 s: action bar countdown with a tick each second, big number titles for 5..1, red time.
3. **#198:** at the end everyone is at the scenario hub with a Victory!/Defeat title and the return time; no fighting;
   inventory guards and command filter still apply. After 30 s (or the configured time) everyone is back where they
   were with their own inventory. `/siege leave` returns at once. A disconnect during the wait: on rejoin you are at
   your pre-siege spot with your items. Set "After the match" to 0: everyone returns at once (old behaviour).
4. **#164:** one result line per player; hover shows all stats and rewards, zeros as 0; the rewards match the
   scenario amounts. With the API briefly down at the end: the line says rewards are confirmed later.
5. **#174:** `[match page]` opens `/siege/matches/<id>`; signed out you see teams, players and objectives but numbers
   "Hidden"; signed in as a player you see your own row, others per their visibility settings. The player profile
   lists "Siege matches". In game `/siege history` lists the last 5 with working links.

## 5. Follow-ups and flags

- **API tests not run** in this session (see § 3).
- **G merge** in `SiegeScoreboardPresenter` as in § 2.
- `web.public-url` and `App:PublicBaseUrl` are two settings for one value; the plugin doesn't fetch it from the API.
- Statistics visibility "Friends" is treated as Nobody on the match pages, as everywhere (KNG-35 pending).
