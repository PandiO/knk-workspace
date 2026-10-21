# Arena duels chain — charter and session prompts

**Status:** Ready. No phase has started.
**Last updated:** 2026-10-21
**Linear:** [KNG-197](https://linear.app/kngpandi/issue/KNG-197) (design, Done) → phases [KNG-209](https://linear.app/kngpandi/issue/KNG-209) (P0), [KNG-210](https://linear.app/kngpandi/issue/KNG-210) (P1), [KNG-213](https://linear.app/kngpandi/issue/KNG-213) (P2), [KNG-215](https://linear.app/kngpandi/issue/KNG-215) (P3), [KNG-217](https://linear.app/kngpandi/issue/KNG-217) (P4), [KNG-219](https://linear.app/kngpandi/issue/KNG-219) (P5), [KNG-220](https://linear.app/kngpandi/issue/KNG-220) (P6), [KNG-221](https://linear.app/kngpandi/issue/KNG-221) (P7), [KNG-222](https://linear.app/kngpandi/issue/KNG-222) (P8)
**Design (binding):** [DESIGN.md](../../specs/arena-duels/DESIGN.md) and [IMPLEMENTATION_PLAN.md](../../specs/arena-duels/IMPLEMENTATION_PLAN.md) on knk-workspace `main`. Accepted by the developer 2026-10-21.
**Progress report:** `docs/reports/2026-10-21-arena-duels-chain.md`. The first session creates it; every session appends one section.

**State on 2026-10-21:**

| Repo | Ref | Commit |
|---|---|---|
| knk-web-api | `master` | `2d711557` |
| knk-web-app | `main` | `e30c8152` |
| knk-plugin | `main` | `79be4882` |
| knk-plugin | KNG-182 branch `claude/mc-26.2-upgrade` (Minecraft 26.3; ready and only waiting to be merged, per the developer) | `88497649` |
| knk-workspace | `main` | `bb605748` |

No `claude/arena-duels` branch exists yet.

There are two ways to run this:
- **Option A:** one coordinator session that starts and checks the phase sessions itself (§3).
- **Option B:** the developer starts one session per phase, using the prompts in §4.

Both use the rules in §1 and the order in §2.

---

## 1. Rules for every phase session

1. **Read first**, on knk-workspace `main`:
   - `AGENTS.md`
   - `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`
   - `docs/ACTIVE_SESSIONS.md`
   - this charter
   - the arena-duels `DESIGN.md` and `IMPLEMENTATION_PLAN.md`; your phase section in the plan is your scope

   Then each changed repo's `AGENTS.md` / `CLAUDE.md`. In knk-plugin that includes the test rule: keep a mocked `World` in a field.
2. **Repos**: `github.com/PandiO/knk-workspace`, `knk-web-api`, `knk-web-app`, `knk-plugin`, checked out under `/home/user/<repo>`. If one is missing, add it with `add_repo` (access `push`) and clone it. Before your first change, run `git push --dry-run` on the feature branch of every repo you will change.
3. **One feature branch per repo, `claude/arena-duels`**:

   | Repo | Create the branch from |
   |---|---|
   | knk-web-api | `origin/master` |
   | knk-web-app | `origin/main` |
   | knk-plugin | `origin/claude/mc-26.2-upgrade` (KNG-182), **not `main`** |
   | knk-workspace | `origin/main` (for docs) |

   - The first session that touches a repo creates the branch; later sessions check it out and pull.
   - **knk-plugin**: once KNG-182 has merged into `main`, the next session to touch the plugin merges `origin/main` into `claude/arena-duels`, and `main` is the base from then on.
   - At the start, and again before your last push, merge the current trunk into the feature branch.
   - **Never rebase, amend or force-push.** Don't merge other feature branches.
4. **Several sessions may share a branch at the same time** (waves in §2). Keep your commits to your phase's files. Before every push, `git fetch` and merge `origin/claude/arena-duels`, then re-run your tests. If the push is rejected, repeat. A conflict you can't resolve mechanically is a blocker: stop and report it (step 10).
5. **Tracker**:
   - Before editing, add a row for **your phase** to `docs/ACTIVE_SESSIONS.md` "In progress", as a single commit straight on knk-workspace `main`: feature `Arena duels P<n> (KNG-…)`, repos and files claimed, branch, status, dates.
   - Update the row when you pause. Move it to "Recently completed" when you finish.
   - One row per phase, so parallel sessions don't edit the same line. On a conflict in that file, keep both rows.
6. **Linear**:
   - Set your issue to **In Progress** when you start.
   - When you push, set it to **In Review** with a comment: commits per repo, test results, what still needs a live check, leftovers.
   - The developer's live test moves it to Done (P8).
   - Anything found in passing and left out gets its own issue (or a comment on the issue that covers it). Never leave it only in the report.
7. **Build and test**: run the repo's checks, measure the baseline first, and report known-red tests as known.
   - knk-plugin: `./gradlew build -x deployToDevServer`, with Java 25 / Paper 26.3 from the KNG-182 toolchain. A plain `build` deploys to the dev server.
   - knk-web-api: `dotnet build`, then `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj`. New write endpoints go in `EndpointAccessRulesTests`.
   - knk-web-app: `npx -y npm@11 ci`, then `npm run test:ci`. The lock file needs npm 11.
   - Push only when green, or when the reds are known baseline reds.
8. **Docs**:
   - Update living docs your phase changes (named in the plan section), on knk-workspace `claude/arena-duels`.
   - If code has to differ from the design, don't silently diverge. Record the point and why in the report and as a Linear comment on KNG-197, and pick the reversible option.
   - Never reopen a developer decision (DESIGN §13).
9. **Progress report**: append a section to `docs/reports/2026-10-21-arena-duels-chain.md` on knk-workspace `claude/arena-duels`. Include:
   - phase and issue
   - commits per repo
   - tests (counts, known reds)
   - what you built that later phases rely on (class names, endpoints, ports)
   - deviations and open questions
   - the live checks to add to P8
10. **Not allowed**:
    - merging into any trunk (`main`/`master`), opening PRs, deploying
    - touching the developer's servers, databases or the dev server
    - changing Linear issues outside this feature (comments are fine)
    - widening scope beyond your phase

    When blocked, push what is safe, write the blocker in the report, the tracker row and the Linear issue, and stop.

## 2. Order and waves

| Wave | Phases (can run in parallel) | Starts when |
|---|---|---|
| 1 | **P0** KNG-209 (plugin: shared hooks) ‖ **P1** KNG-210 (API + web app, then the plugin read side) ‖ **P3** KNG-215 (plugin `knk-core/core/duel`, pure) | now |
| 2 | **P2** KNG-213 (API) | P1 pushed (it needs the Arena entities) |
| 3 | **P4** KNG-217 (plugin runtime) | P0, P2 and P3 pushed |
| 4 | **P5** KNG-219 (UI) ‖ **P6** KNG-220 (announcements, menus) ‖ **P7** KNG-221 (stats + web-app pages) | P4 pushed; P7 needs only P2 and may start in wave 3 |
| 5 | **P8** KNG-222 (guide, smoke-test checklist, then the developer's live test and merge) | P0–P7 pushed |

**Overlap**: P0, P1 (plugin part) and P3 all touch the knk-plugin branch in wave 1.
- P3 only adds files under `knk-core/.../core/duel/`.
- P0 owns `KnKPlugin` wiring, `core/minigame/`, the vault and `DomainAccessHandler`.
- P1's plugin part is the `ArenasApi` port/client, the gateway in `DataAccessFactory`, and the managed-region kind mapping and policy. **P1 does its plugin part after P0 has pushed** (or coordinates by merging P0's pushed commits first). It does the API and web-app work before that.

---

## 3. Option A — coordinator prompt

Paste this into one new session in the environment that has all four repos attached ("Default Correct").

```text
You are the COORDINATOR of the Knights and Kings "arena duels" implementation chain.
You do not implement phases yourself; you start, watch and check one session per
phase, in waves, and keep the chain's bookkeeping straight.

SETUP
- Repos: github.com/PandiO/knk-workspace, knk-web-api, knk-web-app, knk-plugin.
  If any is missing, add it with add_repo (access push) and clone it to /home/user/<repo>.
- Read on knk-workspace main: AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md
  (especially "Session chains"), docs/ACTIVE_SESSIONS.md, and
  docs/ai-agents/handoffs/ARENA_DUELS_CHAIN.md (this chain's charter; it is binding),
  then docs/specs/arena-duels/DESIGN.md and IMPLEMENTATION_PLAN.md.
- Add one tracker row "Arena duels chain — coordinator (KNG-197 phases)" on
  knk-workspace main (single commit). Phase sessions add their own rows.

RUNNING THE WAVES (charter §2)
- For each phase, start a session with create_session (model claude-opus-5-5,
  source_url = the repo the phase changes most, title "Arena duels P<n> (KNG-…)").
  Its prompt is the phase prompt from charter §4, verbatim. Every phase prompt
  begins with the add_repo + clone + `git push --dry-run` steps for the other repos,
  because add_repo is only allowed when the request is in the session's prompt.
- Start every phase of a wave together. Only start the next wave once each phase it
  depends on has pushed. A phase counts as pushed when its Linear issue is In Review,
  its commits are on origin/claude/arena-duels, its report section exists and its
  tests are green or known-red. Check this yourself (git fetch, read the report,
  get_session / list_events); don't take a session's word for it.
- If create_session or add_repo is refused, run that phase as a subagent (Agent
  tool, model opus, the same phase prompt). Subagents share your repos.
- Watch for drift between parallel sessions on the same branch (charter §1.4).
  If two sessions conflict, interrupt the later one and tell it how to resolve.
- If a phase fails or stalls, read its transcript, fix the cause in the next prompt
  (or re-run it), and record what happened in the progress report.
- Don't change the design. Questions that need the developer go into one list at
  the end of the progress report and as a comment on KNG-197. Keep going with the
  reversible default named in DESIGN.md wherever one exists.

AFTER WAVE 4
- Start P8 (charter §4, P8 prompt). P8 writes the guide and the smoke-test checklist
  and stops before the live test; the developer runs that.
- Then write the chain summary at the end of the progress report:
  - commits per repo
  - merge order (knk-plugin follows KNG-182)
  - the combined live checklist
  - open questions for the developer
  - follow-up issues filed
- Move your tracker row to Recently completed and tell the developer in one short
  message what is ready to test. Never merge into a trunk, open PRs or deploy.
```

## 4. Option B — one prompt per phase

The developer starts each session in the environment with all four repos, in the wave order of §2. The prompts are self-contained, and each also works as the coordinator's phase prompt.

### P0 — KNG-209: shared minigame hooks (wave 1)

```text
Implement arena duels Phase 0 — Linear KNG-209 — end to end: code, tests, docs, push,
Linear, tracker, progress report.

SETUP: repos knk-workspace, knk-web-api, knk-web-app, knk-plugin under /home/user. Add any
that are missing with add_repo (access push) and clone them. Read
docs/ai-agents/handoffs/ARENA_DUELS_CHAIN.md on knk-workspace main and follow its §1 rules;
they override anything below. Then read the arena-duels DESIGN.md §11 and
IMPLEMENTATION_PLAN.md "Phase 0", and the Linear issue KNG-209 (acceptance list).
Run `git push --dry-run` on knk-plugin claude/arena-duels (create it from
origin/claude/mc-26.2-upgrade if it doesn't exist yet).

SCOPE (knk-plugin only; a refactor with NO behaviour change):
- core/minigame/MinigameParticipation port + MinigameRegistry composite + a
  SiegeParticipation adapter. Replace every siege lambda in KnKPlugin with a registry
  call: safezone ~898, stats context ~1328, headshots ~1361, discovery ~1406,
  navigation ~1559, outage ~2635, /hub ~2672, domain-access respawn ~2776, lootbox
  ~2965/~3080, scoreboard ~3423, teleport restriction + BackDeathExclusion ~3430.
  Line numbers are from main 79be4882; re-find them on the KNG-182 base.
  ScoreboardUtil and HubOutageService take the registry.
- MinigamePlayerVault, extracted from SiegePlayerVault and keyed by
  (minigame, matchToken). Siege keeps its siege-vault/ files and they still restore.
  KNG-199 (siege kit mode) will reuse it; keep the API general.
- A DomainAccessExemptions port consulted by DomainAccessHandler (entry/exit
  exemption + confinement), empty by default.

DONE WHEN: the plan's Phase 0 tests pass and every existing siege test is green;
pushed; KNG-209 In Review with commits and tests; tracker row; a progress-report
section that names the new ports (P1, P3 and P4 build on them) and the live siege
check for P8 (outage release, /hub refusal, safezone enchant effects, vault restore
after a quit).
```

### P1 — KNG-210: Arena domain types and settings (wave 1)

```text
Implement arena duels Phase 1 — Linear KNG-210 — end to end: code, tests, docs, push,
Linear, tracker, progress report.

SETUP: repos knk-workspace, knk-web-api, knk-web-app, knk-plugin under /home/user. Add any
that are missing with add_repo (access push) and clone them. Read
docs/ai-agents/handoffs/ARENA_DUELS_CHAIN.md on knk-workspace main and follow its §1 rules;
they override anything below. Then read the arena-duels DESIGN.md §4.1–4.2, D12, D16 and
IMPLEMENTATION_PLAN.md "Phase 1", and the Linear issue KNG-210. Run `git push --dry-run`
on claude/arena-duels in knk-web-api, knk-web-app and knk-plugin (create each per
charter §1.3 if missing).

ORDER: do the API and web-app parts first. Do the knk-plugin part only once KNG-209 (P0)
has pushed to knk-plugin claude/arena-duels; merge that first (charter §2 overlap).

SCOPE:
- knk-web-api:
  - Arena : Structure (table arenas) with lobby/exit locations and every duel setting
    in DESIGN §4.2 with its default
  - ArenaBattleground : Domain (arena_battlegrounds; spawn A/B; AllowEntry default false)
  - ArenaSpectatorArea : Domain (arena_spectator_areas; 0..n per arena)
  - ArenaKit join (ordered)
  - TPT mapping like GateStructure (Properties/KnKDbContext.cs); migration AddArenas
  - validation (DESIGN §4.2); DTOs, mapping, services, ArenasController
  - GET for plugin and logged-in users; writes need StaffPermissions.ManageWorld;
    EndpointAccessRulesTests updated
  - IDomainRegionNameFinalizer parents District → Arena → children; discovery and
    navigation defaults off for battlegrounds
  - FormConfiguration seeds in Data/FormConfigurationSeeds/ (KNG-139 pattern; the Arena
    form in steps: General, Negotiation & stakes, Eligibility & abuse limits,
    Gear & kits, Timing & queue, Announcements; plus the battleground and
    spectator-area forms)
  - seed arena_2 + its 8 flagged battlegrounds; region ids are in
    knk-workspace docs/reports/2026-09-28-v1-permissions-worldguard-inventory.md
- knk-web-app: the forms render and save; add only what the generic FormWizard
  can't already do.
- knk-plugin:
  - ArenasApi port + api-client implementation + a cache-first gateway in
    DataAccessFactory
  - managed-region kinds by domain type (Arena → ARENA, battleground → BATTLEGROUND,
    spectator area → plain child)
  - the BATTLEGROUND policy without `entry deny`, keeping `pvp allow`
- Docs: managed-worldguard-regions.md §3/§5/§8, and a short comment on KNG-49.

DONE WHEN: the plan's Phase 1 tests pass; pushed; KNG-210 In Review; tracker row;
a report section that names the entities, endpoints and the plugin gateway (P2, P4 and
P6 build on them) and the live checks for P8.
```

### P2 — KNG-213: match record, stake ledger, review tiers, restrictions (wave 2)

```text
Implement arena duels Phase 2 — Linear KNG-213 — end to end: code, tests, docs, push,
Linear, tracker, progress report.

SETUP: repos knk-workspace, knk-web-api, knk-web-app, knk-plugin under /home/user. Add any
that are missing with add_repo (access push) and clone them. Read
docs/ai-agents/handoffs/ARENA_DUELS_CHAIN.md on knk-workspace main and follow its §1 rules;
they override anything below. Then read the arena-duels DESIGN.md §4.3, §6.5, §7, §10
and IMPLEMENTATION_PLAN.md "Phase 2", the Linear issue KNG-213, and the P1 section of
docs/reports/2026-10-21-arena-duels-chain.md (on knk-workspace claude/arena-duels).
Check that KNG-210 (P1) has pushed to knk-web-api claude/arena-duels; if it hasn't,
stop and say so. Run `git push --dry-run` on knk-web-api and knk-plugin claude/arena-duels.

SCOPE (knk-web-api; knk-plugin only for the api-client):
- DuelMatch (duel_matches) + enums (strings) + migration AddDuelMatches.
- Currency:
  - reasons DUEL_STAKE / DUEL_PAYOUT / DUEL_FEE and the system account SYS_DUEL,
    following the rules at the top of Services/Currency/CurrencyReasons.cs
  - decide how the fee leaves SYS_DUEL (DESIGN §7.1) and record the choice in the report
  - reconcile invariant Σ SYS_DUEL = 0 per closed match
- DuelMatchService (the shape of SiegeMatchService, RunLockedAsync):
  Create / StartFight / Complete / Cancel / Release / Void / Revert / Confiscate /
  AbortUnfinished / GetByToken, idempotent as specified.
  Revert/Confiscate use ReverseAsync with AllowPartial and refund the loser first.
- Eligibility via TransferPolicyEvaluator with the arena's overrides; the pair, cooldown,
  daily-cap and ratio limits; gems refused.
- Review tiers:
  - signals S1–S6, with thresholds in a web-editable DuelPolicy singleton
  - tier 1 → paid + DUEL_FLAG CurrencyAlert; tier 2 → held + DUEL_HOLD, through
    ICurrencyAlertService
  - a FIRST FLAG NEVER HOLDS; acknowledged false positives don't count
  - escalation counts by pair and by beneficiary
  - value-moving invites are refused while a hold is open
- DuelRestriction: stakes-only, player or pair, optional expiry; create/lift; audited.
- Controller:
  - writes [RequirePluginService]; staff actions need the new node
    knk.admin.duel.review (matched by knk.admin.*); GETs for logged-in users
  - EndpointAccessRulesTests updated
- CurrencyAnomalyDetector: R3/R4 read DUEL_PAYOUT as a flow from loser to winner;
  a per-pair rule; DUEL_PAYOUT excluded from R7.
- knk-plugin: a DuelMatchesApi port + api-client implementation with Idempotency-Key
  headers (no runtime yet).

DONE WHEN: the plan's Phase 2 test list passes; pushed; KNG-213 In Review; tracker row;
a report section with the endpoint contract (P4 and P7 build on it) and the live checks
for P8.
```

### P3 — KNG-215: pure core rules (wave 1)

```text
Implement arena duels Phase 3 — Linear KNG-215 — end to end: code, tests, docs, push,
Linear, tracker, progress report.

SETUP: repos knk-workspace and knk-plugin under /home/user (add with add_repo, access
push, and clone if missing). Read docs/ai-agents/handoffs/ARENA_DUELS_CHAIN.md on
knk-workspace main and follow its §1 rules; they override anything below. Then read
the arena-duels DESIGN.md §5, §6, §8.1, §8.4 (the kit-choice deadline) and
IMPLEMENTATION_PLAN.md "Phase 3", and the Linear issue KNG-215. Run `git push --dry-run`
on knk-plugin claude/arena-duels (create it from origin/claude/mc-26.2-upgrade if it
doesn't exist).

SCOPE (knk-plugin module knk-core, new package core/duel/, Bukkit-free; add files
only, don't edit P0's files):
- DuelOfferBook: offer ids/versions, MaxOffers turns, expiry, limits, cooldown, toggle,
  forget on quit.
- StakeContract validation.
- DuelPhase + DuelStateMachine returning DuelEffects: an end-once guard, the agreed-draw
  window, time limit 0 = none, the kit-choice deadline (first eligible kit).
- DuelCombatRules.decide (the DESIGN §8.1 matrix).
- BattlegroundAllocator + ArenaQueue: MaxQueuedMatches, MaxWaitSeconds.
- DuelEscrowState: HELD, spoils.

Shared knk-plugin branch: P0 runs at the same time (charter §1.4, §2 overlap).

DONE WHEN: the plan's Phase 3 unit tests pass; pushed; KNG-215 In Review; tracker row;
a report section that lists the public API of core/duel for P4.
```

### P4 — KNG-217: duel runtime (wave 3)

```text
Implement arena duels Phase 4 — Linear KNG-217 — end to end: code, tests, docs, push,
Linear, tracker, progress report.

SETUP: repos knk-workspace, knk-web-api, knk-web-app, knk-plugin under /home/user. Add any
that are missing with add_repo (access push) and clone them. Read
docs/ai-agents/handoffs/ARENA_DUELS_CHAIN.md on knk-workspace main and follow its §1 rules;
they override anything below. Then read the arena-duels DESIGN.md §5, §6.5, §7, §8 and
IMPLEMENTATION_PLAN.md "Phase 4", the Linear issue KNG-217, and the P0–P3 sections of
docs/reports/2026-10-21-arena-duels-chain.md. Check that KNG-209, KNG-213 and KNG-215
have all pushed; if not, stop and say so. If KNG-182 has merged into knk-plugin main by
now, merge origin/main into claude/arena-duels first. Run `git push --dry-run` on
knk-plugin claude/arena-duels.

SCOPE (knk-plugin):
- DuelService (1 s ticker; async API, never block on HTTP), registered in
  MinigameRegistry.
- TeleportKind ARENA (player warmup, no cooldown or charge) and ARENA_SYSTEM (instant,
  safe-spot check, no audit), with WarmupPolicy and the TeleportService kind branches
  updated. The KNG-182 branch already adds HUB. The lobby teleport runs for both
  players together; if either fails, cancel and refund.
- Restrictions:
  - DuelTeleportRestriction, a command filter, an inventory guard
  - DuelCombatListener (HIGHEST un-cancel/deny)
  - a DisallowedPVPEvent handler: check the event exists in the WorldGuard build on
    the KNG-182 branch, and record the outcome
  - the safezone exemption through the registry
- Battleground access via DomainAccessExemptions: entry for the allocated pair; exit
  refused in COUNTDOWN/FIGHT with a one-shot pass for the exit teleport; countdown
  freeze.
- Gear modes (DESIGN §8.4–8.5):
  - kit modes: the vault in the lobby teleport's commit step (a pre-commit hook on
    TeleportPlan), restored at once if the move fails; the kit granted on arrival via
    KitGrantPlacer with no cost, cooldown or access check (KIT_CHOICE: placeholder,
    swapped on pick, locked at the countdown); the knk_duel_loan PDC tag; kit
    consumables blocked in warmup; restore on ENDING, cancel/abort, quit, outage, and
    on join after a crash
  - drop mode: spoils captured in the death event (spool written first); a forfeit
    takes the quitter's inventory
  - held deliveries: holdsLootDrops from LOCKING until the restore (lootbox reel items
    and other item deliveries come after the restore); opening a lootbox is refused
    during a match
- Death, respawn and quit listeners (a quit cancels or forfeits by phase).
- DuelEscrowSpool (atomic YAML; inventory → ender chest → CLAIM_PENDING; HELD),
  pending-results replay, startup recovery (DESIGN §7.3).
- Siege joinDenial refuses duelists.
- Leave the proposal UI, commands, menus and announcements to P5/P6. Expose the service
  methods they need and list them in the report.

DONE WHEN: the plan's Phase 4 tests pass (mocked Worlds kept in fields); pushed;
KNG-217 In Review; tracker row; a report section with the service API for P5/P6 and the
live checks for P8.
```

### P5 — KNG-219: negotiation UI and commands (wave 4)

```text
Implement arena duels Phase 5 — Linear KNG-219 — end to end: code, tests, docs, push,
Linear, tracker, progress report.

SETUP: repos knk-workspace and knk-plugin under /home/user (add with add_repo, access
push, and clone if missing). Read docs/ai-agents/handoffs/ARENA_DUELS_CHAIN.md on
knk-workspace main and follow its §1 rules; they override anything below. Then read the
arena-duels DESIGN.md §6 and IMPLEMENTATION_PLAN.md "Phase 5", the Linear issue
KNG-219, and the P4 section of docs/reports/2026-10-21-arena-duels-chain.md. Check that
KNG-217 has pushed; if not, stop and say so. Run `git push --dry-run` on knk-plugin
claude/arena-duels. P6 and P7 may run at the same time (charter §1.4).

SCOPE (knk-plugin):
- The /duel tree and /arena (DESIGN §6.1), registered in plugin.yml and CommandNodes:
  knk.duel (default true); staff /knk duel … with knk.admin.duel.
- DuelProposalEditor: a hand-rolled 54-slot inventory with every click cancelled:
  - a gear-mode cycle with only the arena's allowed modes
  - a FIXED_KIT picker
  - items added by clicking your own bottom inventory (nothing moves during
    negotiation)
  - coin +/- buttons and anvil input
  - fee, eligibility and limit warnings
- DuelOfferView (Accept/Counter/Decline; no Counter on the last allowed offer).
- Clickable, id-stamped chat offers with a 10 s expiry warning; drop mode in capitals.
- The KIT_CHOICE picker in warmup (menu + chat prompt, the opponent's pick shown).
- The lock-in sequence (DESIGN §6.5) wired to P4's service.

DONE WHEN: the plan's Phase 5 tests pass; pushed; KNG-219 In Review; tracker row;
a report section with the live checks for P8.
```

### P6 — KNG-220: announcements, menus and spectating (wave 4)

```text
Implement arena duels Phase 6 — Linear KNG-220 — end to end: code, tests, docs, push,
Linear, tracker, progress report.

SETUP: repos knk-workspace, knk-web-api, knk-plugin under /home/user (add with add_repo,
access push, and clone if missing). Read docs/ai-agents/handoffs/ARENA_DUELS_CHAIN.md on
knk-workspace main and follow its §1 rules; they override anything below. Then read the
arena-duels DESIGN.md §9 and IMPLEMENTATION_PLAN.md "Phase 6", the Linear issue
KNG-220, and the P1 and P4 sections of docs/reports/2026-10-21-arena-duels-chain.md.
Check that KNG-217 has pushed; if not, stop and say so. Run `git push --dry-run` on
knk-web-api and knk-plugin claude/arena-duels. P5 and P7 may run at the same time
(charter §1.4).

SCOPE:
- knk-plugin:
  - DuelAnnouncer: warmup-start broadcast with [Spectate] [Details]; result and draw
    announcements; "pending review" for held results; per-arena toggles; a spam
    cooldown
  - the duel sidebar and boss bar for duelists and for players in the arena's
    spectator area (the scoreboard predicate goes through the registry)
- knk-web-api: menu templates in MenuTemplateSeed:
  - duel_matches: live matches
  - duel_match_detail: kits, stake items, coins, stats as visible to the viewer
  - arena_main: info, live matches, queue, [Spectate], [Challenge a player],
    [My claims], rules
- knk-plugin: DuelMenuFeature. The spectate action starts the spectator area's
  domain WARP, so the teleport engine and the warp conditions (title, premium,
  discovery, gem price) apply. The area is also reachable on foot and by /warp.

DONE WHEN: the plan's Phase 6 tests pass; pushed; KNG-220 In Review; tracker row;
a report section with the live checks for P8.
```

### P7 — KNG-221: statistics and web-app pages (wave 3 or 4)

```text
Implement arena duels Phase 7 — Linear KNG-221 — end to end: code, tests, docs, push,
Linear, tracker, progress report.

SETUP: repos knk-workspace, knk-web-api, knk-web-app, knk-plugin under /home/user. Add any
that are missing with add_repo (access push) and clone them. Read
docs/ai-agents/handoffs/ARENA_DUELS_CHAIN.md on knk-workspace main and follow its §1 rules;
they override anything below. Then read the arena-duels DESIGN.md §10.3, §11 and
IMPLEMENTATION_PLAN.md "Phase 7", the Linear issue KNG-221, and the P2 section of
docs/reports/2026-10-21-arena-duels-chain.md. Check that KNG-213 has pushed; if not,
stop and say so. Run `git push --dry-run` on claude/arena-duels in knk-web-api,
knk-web-app and knk-plugin.

SCOPE:
- knk-web-api:
  - DuelStatisticsProjector (wins/losses/draws from duel_matches; a forfeit is a loss;
    cancelled, aborted and voided matches count nothing), registered in
    StatisticsProjectionService
  - `duel` added to the projection-owned guard
  - visibility default `everyone` for duel W/L/D; players can change it in their
    statistics settings
- knk-plugin: StatisticsContextResolver returns `duel` for match participants (through
  the registry). Use P4's participation if it has pushed; otherwise add the resolver
  hook and note it.
- knk-web-app (npm 11):
  - a "Duels" admin page: history with filters; match detail (stakes, spoils,
    telemetry, signals, tier); Release/Void on held results; Revert/Confiscate on paid
    results with a required reason, showing what was recovered and what is still
    missing; clear escalation
  - a duel-restrictions page (player or pair, optional expiry, lift; shown on the
    player's staff profile)
  - a DuelPolicy settings page
  - duel alerts already appear on the existing currency alerts page (new rule codes);
    no new alert UI
- Docs: the player-statistics DESIGN mentions the `duel` context.

DONE WHEN: the plan's Phase 7 tests pass; pushed; KNG-221 In Review; tracker row;
a report section with the live checks for P8.
```

### P8 — KNG-222: guide, smoke test and merge (wave 5)

```text
Prepare arena duels Phase 8 — Linear KNG-222 — for the developer's live test: guide,
docs, the combined smoke-test checklist, and the merge plan. Then stop. Merging happens
only after the developer signs off, in a later message.

SETUP: repos knk-workspace, knk-web-api, knk-web-app, knk-plugin under /home/user. Add any
that are missing with add_repo (access push) and clone them. Read
docs/ai-agents/handoffs/ARENA_DUELS_CHAIN.md on knk-workspace main and follow its §1 rules;
they override anything below. Then read IMPLEMENTATION_PLAN.md "Phase 8", the Linear
issue KNG-222, and the whole of docs/reports/2026-10-21-arena-duels-chain.md. Check
that KNG-209, 210, 213, 215, 217, 219, 220 and 221 have all pushed and are In Review;
list any that aren't and stop if one is missing. Run `git push --dry-run` on every
claude/arena-duels branch.

SCOPE:
- In every repo, merge the current trunk into claude/arena-duels. knk-plugin: merge
  main if KNG-182 has landed, otherwise keep claude/mc-26.2-upgrade as the base and say
  so. Then run the full build and tests in every repo.
- Write docs/guides/arena-duels.md:
  - admin setup: the arena domain, battlegrounds, spectator area and its warp, duel
    settings, eligible kits, DuelPolicy, reviews, restrictions
  - a player how-to
- Update: the feature register row, specs/README.md, managed-worldguard-regions.md,
  domain-access-enforcement.md, and teleport DESIGN (ARENA / ARENA_SYSTEM).
  Prepare the CHANGELOG entry, to be added at merge.
- Write the combined smoke-test checklist: plan Phase 8 steps 1–15, plus every live
  check the phase report sections added, plus P0's siege regression check. Include the
  setup steps the developer needs (deploy from the branches, seed arena_2, set the
  locations).
- Write the merge plan: order, the commits to merge, and the knk-plugin dependency on
  KNG-182.

DONE WHEN: everything is pushed on the claude/arena-duels branches; KNG-222 In Review
with the checklist linked; tracker row; the chain summary at the end of the progress
report; one short message to the developer saying what to test and how. After the
developer's sign-off (a later message), merge per the plan, add the CHANGELOG entry,
set KNG-197's phase issues to Done, and move the tracker rows to Recently completed.
```

---

## 5. Known context for every session

- **Siege kit mode** ([KNG-199](https://linear.app/kngpandi/issue/KNG-199)) is not in this chain. It reuses P0's vault and P4's kit loan; keep both general.
- **Doc corrections** in [KNG-198](https://linear.app/kngpandi/issue/KNG-198) are not in this chain.
- **The API stores no IP data.** Alt detection is behaviour-only (DESIGN §10.4). Don't add IP logging.
- **Currency alerts** already have a web page, an acknowledge flow and an in-game notifier (`CurrencyAlertService`, `CurrencyAlertNotifier`). Duel alerts reuse them by rule code.
- **Item delivery chain** is inventory → ender chest → claim. [KNG-90](https://linear.app/kngpandi/issue/KNG-90) (reward inbox) is not built. Don't depend on it; the duel spool's `CLAIM_PENDING` + `/duel claim` is the fallback.
