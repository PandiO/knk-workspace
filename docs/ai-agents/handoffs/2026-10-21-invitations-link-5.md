# Invitations chain — link 5: I2 plugin — admission gate, AccountLinked handler (KNG-214, plugin)

**Written:** 2026-10-21 by link 4 (KNG-214 API + web app), after it finished.
**Charter:** [INVITATIONS_CHAIN.md](INVITATIONS_CHAIN.md). Read it first; it overrides this file.
**Plan:** [IMPLEMENTATION_PLAN.md](../../specs/invitations/IMPLEMENTATION_PLAN.md) § 6.2 (and § 6.3a, link 4's as-built note);
[DESIGN.md](../../specs/invitations/DESIGN.md) § 5.1, § 5.2, § 5.5.
**Previous link's report block:** [2026-10-21-invitations-chain.md](../../reports/2026-10-21-invitations-chain.md) "Link 4".

## State at hand-over

| Repo | Branch `claude/player-signup-invitation-flow-f4v7ul` | Base | Tests at hand-over |
|---|---|---|---|
| knk-workspace | link 4 docs commit(s) on top of the merge of `main` | `main` | — |
| knk-web-api | `44c5f63` (`4d1fe00` admission/linking/staff, `44c5f63` `UserDto.admitted`) | `master` `2d71155` (merged, unchanged) | **2904 passed, 4 failed, 81 skipped** (the 4 known-red: `PathResolutionServiceTests` ×2, `FieldValidationServiceTests.ValidateConditionalRequiredAsync_WithConditionMet_ValidatesRequired`, `ClientActivityStoreTests.RecordsRequestsIntoRollingBuckets`; red on `master` too) |
| knk-web-app | `60ec323` (`a3f00fd` staff card, `60ec323` `/link`, `/account/link`, banner) | `main` `e30c815` | **165 suites / 997 tests**; build compiles with `main`'s pre-existing warnings |
| knk-plugin | `30b10e6e` (unchanged since link 1) | `claude/mc-26.2-upgrade` `88497649` (KNG-182, unmerged; unchanged on 2026-10-21) | core 2168 / api-client 264 / paper 1870, 0 failures (link 1's numbers; re-take the baseline) |

- **Link 4's exit criteria are met**: § 6.1 and § 6.3 built and pushed, builds green, counts above the baseline, the 4
  known-red unchanged, the `Mode=LinkCode` auth suites unchanged; 1 new `[MySqlFact]` written and skipped.
- **Tracker:** the chain's row is on workspace `main`. Update it there (charter § 1.2).
- **Toolchains:** this link changes the plugin: **JDK 25 is required** (charter § 1.4; link 1 installed a Temurin 25
  to `/opt/jdk-25`, a fresh container won't have it). Gradle runs on Java 21; pass
  `-Porg.gradle.java.installations.paths=/opt/jdk-25` if it doesn't find the toolchain. Build:
  `./gradlew build -x deployToDevServer`. The clone is shallow; fetch the base with
  `git fetch origin +claude/mc-26.2-upgrade:refs/remotes/origin/claude/mc-26.2-upgrade`.
- **Repos you change:** knk-plugin and knk-workspace (docs, report, handoff). Dry-run pushes in both.

## The API contract you build against (link 4, exact)

**Admission check** — `GET api/Admission/{uuid}?name={name}` with the plugin key (`X-API-Key`, as every
`RequirePluginService` route; the existing `KnkApiClient` auth does it).
- `uuid`: any form `Guid.TryParse` reads; send `UUID.toString()`. `name`: `^[A-Za-z0-9_]{1,16}$`. Otherwise **400**
  `{"error":"InvalidRequest","message":…}`.
- **200** bodies (camelCase JSON):
  - `{"admitted":true,"reason":null,"code":null,"expiresAt":null}` — let them in. Always this while the API's
    `Security:Registration:Mode` isn't `Invite`.
  - `{"admitted":false,"reason":"NotAdmitted","code":"K7QH-M2XA","expiresAt":"2026-10-21T12:15:00Z"}` — `code` is
    already formatted `XXXX-XXXX` for the screen; the same code comes back on a rejoin until it expires or is used.
    Derive `{minutes}` from `expiresAt` (the API's `Admission:ClaimCodeMinutes`, default 15), don't hard-code 15.
  - `{"admitted":false,"reason":"Deactivated","code":null,"expiresAt":null}` — deactivated or deleted account.
- An admitted check also makes the account's name follow the Mojang name (when no other account holds it).

**`AccountLinked` notification** (on `GET api/PlayerNotifications/pending`, acknowledged with
`POST api/PlayerNotifications/acknowledge {ids}`, as the existing types):
- `type`: **`"AccountLinked"`** (`PlayerNotificationTypes.AccountLinked`).
- Payload field **`accountLinked`**: `{"maskedEmail":"st***@example.com"}` (`AccountLinkedNotificationDto`; the
  API's `EmailMask`: first two characters of the local part, or one when it is ≤ 2, `***`, then `@domain`; `***`
  when there is no address).
- `userId`, `uuid`, `username` are the linked account's (the Minecraft name). Queued after every new link (case A or B,
  claim or `/account link` code). It lives 24 h in the API's in-memory queue; deliver it on the player's next join if
  they are offline, as the plan's message says: *"Your Minecraft account is now linked to the web account
  {maskedEmail}. Not you? Tell staff right away."*

**`POST api/Users` (create on first join)** under `Mode=Invite`: a UUID without an admitted account answers **403**
`{"error":"NotAdmitted",…}` (L4-5). With the gate in front only admitted players (who have accounts) and **operators**
get through; an operator without an account will hit this 403. Make the plugin handle it without breaking the join
(log a warning, no account), and say so in the report.

**Web routes** for the kick message: `{web.public-url}/link` exists (`/link`, works logged out). Players with an account
use `/account/link`, which accepts the same claim code.

## Your work (plan § 6.2), in this order

1. **Claim** (charter § 5.1): tracker row on `main`; KNG-214 stays *In Progress* (link 5 finishes the issue; set it to
   *In Review* at the end if § 6.2 is complete).
2. **Setup** (charter § 1): fetch, merge `origin/claude/mc-26.2-upgrade` (or `origin/main` if KNG-182 has merged by
   then), JDK 25, dry-run pushes in knk-plugin and knk-workspace, baselines.
3. **knk-core:** `ports/api/AdmissionApi`, `domain/admission/AdmissionResult`, `admission/AdmissionPolicy` (Bukkit-free,
   every branch of plan § 6.2 "Rules"), `PlayerNotification.AccountLinked` (core enum/constant next to the existing types).
4. **knk-api-client:** `AdmissionApiImpl` + DTO, wired into `KnkApiClient`; the `accountLinked` payload on the
   notification DTO.
5. **knk-paper:** `paper/admission/AdmissionListener` (`AsyncPlayerPreLoginEvent`, LOWEST, 3 s timeout, operator bypass,
   `OfflineSecurityStore` fallback, `disallow(KICK_WHITELIST, component)`), `PlayerListener.onValidateLogin` early return
   when not `ALLOWED`, the `AccountLinked` handler in `tasks/PlayerNotificationPoller`, `config.yml` keys
   (`admission.mode: whitelist` default, `api-timeout-ms`, `link-url`, the three messages). Thin wiring in `KnKPlugin`.
6. **Check on Paper 26.3** from the Paper API sources or javadoc you can reach: `AsyncPlayerPreLoginEvent` after Mojang
   auth and before the whitelist; multi-line component disconnect messages. Record what you found; leave the live check
   in the checklist (charter "Link 5" specifics).
7. **Docs, report block "Link 5", plan status (§ 6.2 as built), CHANGELOG, Linear, handoff for link 6**
   (`2026-10-21-invitations-link-6.md`, A1 / KNG-216).

## Open flags (for context; none block you)

Link 1: L1-1…L1-7. Link 2: L2-1…L2-12. Link 3: L3-1…L3-12. Link 4: L4-1 claim codes need an admitted web account;
L4-2 linked mail/notice/audit on every new link; L4-3 name follows only when free; L4-4 Admission answer shape, `Open` =
admitted; **L4-5 plugin create refused for non-admitted UUIDs, operators included**; L4-6 register with `claimCode`
codes; L4-7 detach refusals; L4-8 Admit idempotent, no admit-by-claim-code; L4-9 FinishLinking sweep; L4-10
`UserDto.admitted`; L4-11 landing copy before the switch; L4-12/13/14 web-app code entry, kept claim code, account
page pointer; L4-15 mail dedupe; L4-16 in-memory notice. Details in the report.

## Risks to keep in mind

- **`admission.mode` must default to `whitelist`** (behaviour-neutral, charter § 3); the vanilla whitelist stays the
  kill switch.
- Fail-closed for strangers when the API is down (DESIGN § 5.2) — but only in `invite` mode.
- KNG-182's tracker row claims `KnKPlugin` wiring, build files and `worlds/`: keep `KnKPlugin.java` edits to thin wiring
  and don't touch build files.
- Plugin tests never build a `Location` around an inline `mock(World.class)`.
- Do not let anyone switch `Mode=Invite` on the alpha before this plugin is deployed (report "Link 4" deploy notes).

## Exit criteria

- § 6.2 built and pushed on JDK 25; plugin build green; counts ≥ the baseline; `admission.mode` defaults to `whitelist`.
- The Paper 26.3 event-order finding recorded; the live checks in the checklist.
- The handoff file for link 6 (`2026-10-21-invitations-link-6.md`, A1 / KNG-216) written and pushed.
