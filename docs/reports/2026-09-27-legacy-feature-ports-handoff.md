# Legacy feature ports — merge & deploy handoff

**Status:** Implementation complete on five feature branches; awaiting developer smoke tests and merge
**Last updated:** 2026-09-27
**Linear:** KNG-17 (teleport), KNG-18 (private messages), KNG-19 (lootboxes), KNG-20 (domain discovery),
KNG-21 + KNG-22 (currency ledger & payments; KNG-23 folded in as duplicate)

One page to take the five branches from "done on a branch" to "running on the dev server". The detail for each phase
(commits, tests, deviations, per-phase smoke tests) is in each feature's `IMPLEMENTATION_PLAN.md` "Phase N status" sections.
Designs + resolved decisions: `docs/specs/{currency-payments,domain-discovery,teleport,private-messages,lootboxes}/DESIGN.md` §5.

## 1. Branch tips (all pushed, worktrees clean)

| Branch | knk-web-api | knk-plugin | knk-web-app |
|---|---|---|---|
| `claude/currency-payments` — **merged to trunk 2026-09-27** (api `5639a50`, plugin `0d01b52`, app `c4ed753`) | `edb77e8` | `7f056b3` | `6eed4a0` |
| `claude/domain-discovery` — trunk (PM + currency) merged in 2026-09-27, **in smoke test** | `f370bdd` | `88d5c16` | `f0d59c4` |
| `claude/teleport` | `d4daef5` | `c954c30` | `c12b39b` |
| `claude/private-messages` — **merged to trunk 2026-09-27** (api `7daca13`, plugin `316315e`, app `7db6f46`) | `fbf280d` | `0fed5f4` | `354d4f4` |
| `claude/lootboxes` — trunk (PM + currency) merged in 2026-09-27, **ready for smoke test** (plugin.yml fix `e954187`) | `7c47e88` | `e954187` | `3bb92da` |

All five branches contain trunk **including the siege merge** (api `67f451e`, plugin `716fb3c`, web-app `4fba7d0`). Every
plugin branch has a GitHub Actions `Build` workflow (`.github/workflows/build.yml`) and was green on its tip; API suites show
only the 5 known baseline failures; web-app suites only the 16 known trunk failures.

## 2. Merge order

1. **`claude/currency-payments`** first — KNG-22 security hardening (service-key auth, fail-closed) and the ledger that
   everything else posts through. Every other branch already contains its KNG-22 commits (`7d441be`/`be0cfc3`/`4a3c304`),
   and discovery/teleport contain the ledger core (`d5c1418`) + `3630436`.
2. **`claude/domain-discovery`** — at merge, switch discovery's `ApplyTitleProgressionAsync` call to currency's
   identical-signature version (`234f8f3`) so discovery-triggered title bonuses are ledger-posted too (one-line change;
   expect `UserService` conflicts — keep currency's side).
3. **`claude/teleport`** — contains discovery `fb94564`/`54b29ec`; merge after discovery.
4. **`claude/private-messages`** and **`claude/lootboxes`** — independent of 2–3; any order after currency.

Expected merge friction: EF model snapshot (regenerate/merge so `dotnet ef migrations has-pending-model-changes` reports
none; never drop a feature's migration), `KnKPlugin.java` wiring, `plugin.yml`, `config.yml`, menu seeds, web-app
`entityApiMapping.ts` / `objectConfigs.tsx` / `enums.ts` / `Navigation.tsx`. `AuditAction` numbers were pre-allocated per
feature (teleport 12, lootboxes 13–14, PMs 15–16, discovery 17–18, currency 19–29) so they don't collide. The `usePermission`
hook and `StaffRoute node` prop were cherry-picked identically into several web-app branches — they merge cleanly.

After merging: unify the three vanish-safe lookup helpers (private-messages `commands/support/VisiblePlayers`, teleport
`VisibleTargetResolver`, currency `currency/VisiblePlayers`) and wire teleport's
`TeleportRequestService.setIgnoreCheck(IgnoreService::ignores)`.

## 3. Dev-server setup (once, before smoke tests)

1. **Service key:** `openssl rand -hex 32` → API `Security:PluginApiKey`; plugin `config.yml` `api.auth.type: apikey` +
   `api.auth.api-key` (same value). Existing configs still say `type: none`; the plugin refuses to start with `apikey` and
   an empty key. Deploy API and plugin together (the API now fails closed without the key).
2. **Migrations:** `dotnet ef database update`. Before it, check for negative / over-cap balances (the KNG-22 CHECK-constraint
   migration clamps them). The ledger immutability-trigger migration needs `TRIGGER` plus SUPER or
   `log_bin_trust_function_creators=1` (binary logging is on by default on MySQL 9.6); otherwise run the update with
   `KNK_SKIP_LEDGER_TRIGGERS=true`.
3. **Menus (create-only seeds):** on an existing DB the hub keeps its layout — add the Discoveries tile (slot 20) and the
   Teleport tile (slot 24) via the MenuTemplates API, or delete the `main` hub row so it re-seeds; restart Paper.
4. **FormConfigurations:** lootbox admin forms — POST the 7 payloads in `docs/specs/lootboxes/PHASE_4_FORMCONFIGS.md`
   (join entries first); domain forms — add the five teleport fields (`TeleportEnabled`, `TeleportPriceGems`,
   `TeleportMinTitleBracketId`, `TeleportMinPremiumGroupId`, `TeleportRequiresDiscovery`) to Town/District/Structure; remove
   coins/gems from the User form (the API ignores them now).
5. **Plugin config (existing servers):** `private-messages.api-enabled: true`, `private-messages.filter-command-log: true`;
   new `teleport.*`, `discovery.*`, `lootboxes.*`, `currency.*` blocks all have defaults.
6. **Permission grants** (in-house permission groups):

| Group | Nodes |
|---|---|
| Default | `knk.teleport.request`, `knk.teleport.spawn`, `knk.teleport.warp` (`knk.lootbox.open`/`.odds`, `knk.baltop` are seeded) |
| Noble | `knk.teleport.warmup.short` |
| Dragon Blood | `knk.teleport.request.here`, `knk.teleport.back` |
| Staff | `knk.socialspy`, `knk.msg.unignorable`, `knk.msg.bypass.ignore`, optional `knk.msg.bypass.ratelimit`, `knk.freeze`, `knk.teleport.staff`, `.staff.others`, `.staff.silent`, `knk.region.bypass`, `knk.teleport.bypass.*`, `knk.admin.discovery`, `knk.lootbox.admin.*`, `knk.admin.currency.*` |
| Owner | `knk.socialspy.exempt`, `knk.pmlog.read` |
| Web admins | `knk.admin.lootbox.manage`, `knk.admin.discovery`, `knk.admin.currency.*`, `knk.admin.config`, `knk.siege.admin.manage` (siege setup), `knk.gate.admin` (gate overrides) — `knk.admin.*` / `*` covers these |

## 4. Smoke tests

Each plan's "Phase N status" sections list the in-game checks for that phase; the highest-value ones:
- **Currency:** `/pay` online + offline player, ≥ 100,000 confirm prompt, daily cap, API stopped mid-payment → one payment;
  staff `/knk user X coins set …`; web balance log → reverse a grant; SQL-edit a balance → "Run now" → R1 alert switches
  coin transfers off → re-enable in the policy page.
- **Discovery:** new Town in/out/in; join inside a District; teleport into a Structure; `/disc`; reset + rediscover;
  none from the siege hub teleport until restored (queued players still discover).
- **Teleport:** `/tp` forms + `-s`; `/tpa` accept/deny/expire; `/spawn`; paid `/warp` (move during warmup → no charge);
  warp menu from the hub; `/back` after death (lava → safe ground, void refused); all blocked for siege members.
- **Private messages:** vanish-safe `/msg`, `/r` from console, `/socialspy`, `/ignore`, PM log panel on a profile, no `/msg`
  lines in `latest.log`, all PM aliases work in a siege match.
- **Lootboxes:** enable one type + create an area (`/knk lootbox area create` from a WorldEdit selection); box spawns,
  click (and a box right next to you still opens — line-of-sight check), daily cap; token items (duplicate copy → second
  open removes all copies; renamed ender chest does nothing); refused while in a siege.

## 4b. Smoke-test log

- 2026-09-27 — **private messages** passed (D3 → KNG-25, G blocked by pre-existing KNG-24, K untested) and was merged
  to trunk. Its KNG-22 commits are now on trunk too, so trunk requires the service key from here on.
- 2026-09-27 — **currency** smoke-tested (A–K; L siege untested); findings fixed on the branch (see the plan's "Smoke
  test + fixes" section) and merged to trunk. Decisions: XP increases need coin/gem rights and count against the staff
  cap; account merge/link keeps the highest balance per currency (`MERGE_CARRYOVER`).
- 2026-09-27 — **domain discovery** smoke-tested (A–G; C2 and H untested). Findings fixed on the branch: web reset →
  plugin resync, players who joined while the API was down are now tracked and spooled by UUID, and the Structure → GateStructure
  cascade prompt. Awaiting a re-test of those three, then merge. Side finding: siege safezone message (KNG-28), under investigation.

## 5. Decisions still open for the developer

1. ~~**Currency — XP grants vs. the staff cap:**~~ **Decided 2026-09-27:** XP increases need coins+gems rights and count against the cap. holders of `knk.admin.user.xp` can raise XP and trigger title bonuses (up to
   ~4M coins + 600 gems per player, once per bracket) outside the per-staff daily grant cap. Count bonuses against the
   cap, or require the coins/gems nodes for XP increases? (Recommended: require the coins/gems nodes for XP *increases*.)
2. ~~**Currency — account linking forfeits the in-game balance:**~~ **Decided 2026-09-27:** keep the highest balance per currency. linking a Minecraft account to an existing web account
   treats the Minecraft account as the secondary, so its coins/gems are forfeited (pre-existing behaviour, matches Q6).
   Confirm, or make linking keep the higher/combined balance.
3. ~~**Discovery — matchmaking:**~~ **Decided 2026-09-27:** queued players keep discovering; the exclusion starts at the
   hub teleport and lasts until the member is restored (plugin `8f83b11`, `SiegePhase.blocksDiscovery`).

## 6. Known follow-ups (not blocking)

- Flaky test: `WorldGuardCombatSafezonesTest.anExemptedPairIsNotProtected` failed once on CI (plugin run 36280730111, attempt
  1) and passed on re-run — investigate (don't skip).
- Stale claims in `knk-plugin/CLAUDE.md` and `knk-web-api/CLAUDE.md` (auth, menu package, pollers, test path, `/metrics`) —
  suggested as a separate task.
- Still anonymous on trunk: `POST api/Users` without a UUID (web sign-up, intended), `GameSettings` PUT, GateStructures/
  GateDoors CRUD.
- Currency: no Prometheus `/metrics` endpoint (OTLP only), no ledger CSV export, no economy overview page, hashed-IP alt
  signal (Phase 5b) not built; plugin staff balance changes still use the deprecated `PUT Users/{id}/balances`.
- Trunk: `WorldGuardRegionListener` judges PLUGIN-cause teleports, so a siege hub/return spot inside an
  AllowEntry/AllowExit=false domain could block siege's own teleports.
- `COMMAND_CATALOG_V3.md` / `EVENT_CATALOG_V3.md` are stale (don't list any of the new commands/listeners).
