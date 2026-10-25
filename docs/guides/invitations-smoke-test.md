# Invitations, email engine and admission gate — smoke test

**Status:** Written 2026-10-21 (invitations chain link 7, KNG-218). **Run on dev 2026-10-23/24** (Findings below: § 0–6
and § 8 passed or accepted, § 7 waits for the alpha); the feature is merged to every trunk since 2026-10-24.
**Last updated:** 2026-10-25 (§ 3 step 11 and § 4 step 16: the register and login pages in Invite mode, a claim code typed
as a link code — branch `claude/invite-only-register-page` in knk-web-app and knk-web-api, found on the alpha 2026-10-25);
2026-10-24
**Linear:** [KNG-218](https://linear.app/kngpandi/issue/KNG-218) (I3, this guide), parent
[KNG-205](https://linear.app/kngpandi/issue/KNG-205); the packages it checks: [KNG-206](https://linear.app/kngpandi/issue/KNG-206)
(E1), [KNG-207](https://linear.app/kngpandi/issue/KNG-207)/[KNG-208](https://linear.app/kngpandi/issue/KNG-208) (L0),
[KNG-212](https://linear.app/kngpandi/issue/KNG-212) (I1), [KNG-214](https://linear.app/kngpandi/issue/KNG-214) (I2),
[KNG-216](https://linear.app/kngpandi/issue/KNG-216) (A1)
**Design and plan:** [DESIGN.md](../specs/invitations/DESIGN.md), [IMPLEMENTATION_PLAN.md](../specs/invitations/IMPLEMENTATION_PLAN.md)
§ 8 (this guide's checklist) and § 9 (merge order) · **Architecture:**
[account-identity-and-admission.md](../architecture/account-identity-and-admission.md)
**Source checklists:** the "Live checklist" of each link in the
[invitations chain report](../reports/2026-10-21-invitations-chain.md); [email guide § 6](email.md);
[alpha go-live § 6.1 and § 11.1](alpha-go-live.md)

Manual checks for the whole invite-only feature. Sections 0–8 run on **dev** (dev API, web app and Paper server).
Sections marked **alpha** run on the live alpha during the switch-over (§ 9), in the order given there. Record each run
under **Findings** at the end, with the commits you tested.

**You need:**
- a dev API, web app and Paper server built from the feature branch heads (plugin on Paper 26.3 / Java 25, KNG-182);
- `online-mode=true` on the server, `web.public-url` set in the plugin's `config.yml`;
- an Admin web account (`knk.admin.invites`, `knk.admin.config`, `knk.admin.user.manage`), a non-admin staff account;
- **two Minecraft accounts**: one that has played before (grandfathered), and one that has never joined (the
  stranger), plus a mailbox per test address (or the pickup folder / API log, see § 1);
- MySQL for the `[MySqlFact]` tests (§ 0.2);
- for § 7 (Access sync): a Cloudflare test account with a Zero Trust email list, or the alpha's own (alpha only).

Settings that switch the feature on, all off by default:

| Where | Setting | Default (behaviour-neutral) | Invite-only |
|---|---|---|---|
| API | `Security__Registration__Mode` | `LinkCode` | `Invite` |
| Plugin `config.yml` | `admission.mode` | `whitelist` | `invite` |
| `server.properties` | `white-list` | `true` (alpha) | `false` |
| API | `CloudflareAccess__SyncEnabled` | `false` | `true` |

---

## 0. Before anything

### 0.1 Builds

Record the heads you test (`git rev-parse --short HEAD`) for knk-web-api, knk-web-app, knk-plugin. The plugin branch
must contain KNG-182 (plugin `main` since `857d4b1e`; the feature itself is on `main` since `d56e41da`).

### 0.2 Database and MySQL tests

1. Back up the dev DB. `dotnet ef database update` (or start the API) applies, in this order:
   `LinkCodePurpose`, `AddEmailOutbox`, `AddInvitations` (with the grandfathering backfill), `SeedInvitationStaffNode`,
   `SeedAlphaTesterGroup`.
2. Check:
   ```sql
   SELECT COUNT(*) FROM users WHERE IsActive = 1 AND DeletedAt IS NULL AND AdmittedAt IS NULL;      -- 0
   SELECT COUNT(*) FROM users WHERE (IsActive = 0 OR DeletedAt IS NOT NULL) AND AdmittedAt IS NOT NULL; -- 0
   SELECT g.Name, g.Weight, p.Name AS Parent FROM permission_groups g
     LEFT JOIN permission_groups p ON p.Id = g.ParentGroupId WHERE g.Name = 'Alpha Tester';             -- 1 row, 1, Default
   SELECT Node FROM permission_grants gr JOIN permission_groups g ON g.Id = gr.HolderId
     WHERE g.Name = 'Admin' AND Node = 'knk.admin.invites';                                             -- 1 row
   SELECT Purpose, COUNT(*) FROM linkcodes GROUP BY Purpose;                                            -- reset tokens are 1
   ```
   A pending reset token from before the migration still works (its `Purpose` is 1).
3. Run the migrations a second time on a copy that already has an `Alpha Tester` group: no second group, no error.
4. The chain's nine `[MySqlFact]`s (link-code fold, outbox rollback + unique key, invitation concurrency and backfill,
   claim registration rollback, `Alpha Tester` seed) → all pass. Lessons from the first run (2026-10-23):
   - `KNK_TEST_MYSQL` is a **server** connection without `Database=` (the tests create and drop `knk_test_*`
     databases). Take the API's own string from `dotnet user-secrets list` and drop the `Database=…;` part; typing the
     password by hand cost an hour of "Access denied".
   - The MySQL user needs `GRANT ALL PRIVILEGES ON \`knk\_test\_%\`.* TO '<user>'@'<your pc ip>'`. An account exists
     per user **and** host: `GRANT` answering "not allowed to create a user" means no row for your address.
   - Run the classes **sequentially**: in parallel, each class opens its own pool and a NAS MySQL hits "Too many
     connections" within minutes (59 of 124 failed that way; the invitations classes alone take ~3.5 min).
   - `KNK_SKIP_LEDGER_TRIGGERS=true` when the user has no SUPER (the ledger trigger tests are not this chain's).

   PowerShell:
   ```powershell
   $cs = (dotnet user-secrets list | Select-String '^ConnectionStrings:MySqlDbConnection = ').Line -replace '^ConnectionStrings:MySqlDbConnection = ', ''
   $env:KNK_TEST_MYSQL = $cs -replace 'Database=[^;]*;?', ''
   $env:KNK_SKIP_LEDGER_TRIGGERS = 'true'
   dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj --filter "Category=requires-mysql&(FullyQualifiedName~LinkMinecraftAccountMySqlTests|FullyQualifiedName~EmailOutboxMySqlTests|FullyQualifiedName~InvitationUseMySqlTests|FullyQualifiedName~AddInvitationsBackfillMySqlTests|FullyQualifiedName~ClaimRegistrationMySqlTests|FullyQualifiedName~SeedAlphaTesterGroupMySqlTests)" -- xUnit.ParallelizeTestCollections=false
   ```
   bash: `KNK_TEST_MYSQL="Server=…;User=…;Password=…" KNK_SKIP_LEDGER_TRIGGERS=true dotnet test … -- xUnit.ParallelizeTestCollections=false`.
   The whole `requires-mysql` set (currency, statistics, lootbox, …) is optional for this feature; run it with the same
   `-- xUnit.ParallelizeTestCollections=false` suffix or raise the server's `max_connections`.

---

## 1. Email engine (E1, KNG-206) — default settings

Full steps and troubleshooting: [email guide § 6–7](email.md). Mails go to the relay, the pickup folder
(`Email__Transport=Pickup`) or, with `Transport=Log` and `AllowLogTransport=true`, the API log.

1. **Start-up guard.** `ASPNETCORE_ENVIRONMENT=Production` with `Email__Provider=Log` → the API refuses to start and
   names `AllowLogTransport`. Add `Email__AllowLogTransport=true` → it starts. Run it with
   `dotnet run --no-launch-profile --urls http://localhost:5294`: the launch profile forces Development, in which the
   guard is off. Production also needs `ConnectionStrings__MySqlDbConnection` and a 32+ character `Security__Jwt__Secret`
   as environment variables (user-secrets load in Development only).
2. **Test mail.** `/admin/email` → *Send test mail to me* → row **Sent**, the mail (or `.eml`, or log line) exists.
3. **Reset mail.** *Forgot password* → mail with a working link → reset works, old sessions end; the row is Sent with no
   content left.
4. **Email-change notice.** Change the email on the account page, then as staff through the user form on
   `/admin/users/<id>` (there is no separate "update email" button; the form calls the staff endpoint) → the old address
   gets the notice both times.
5. **Privacy confirm.** Request data deletion → the confirm mail arrives. Cancel the request.
6. **Relay down.** Stop the relay → *Forgot password* still answers the usual message → row **Pending** with attempts
   and a last error → start the relay → **Sent**. A reset older than 30 min becomes **Expired** instead.
7. **Throttle.** Four resets for one address within an hour → the 4th row is **Suppressed**. `forgot-password` has
   its own per-address cooldown (`Security:PasswordResetRequestCooldownSeconds`, 60 s) that silently drops repeats,
   so either wait 70 s between requests or start the API with `Security__PasswordResetRequestCooldownSeconds=5` and
   post four requests 8 s apart to `api/Auth/forgot-password` (`{"email":"…"}`).
8. **Staff page access.** A staff member without `knk.admin.config` gets the "needs knk.admin.config" screen on
   `/admin/email` and no **Mail** nav entry.

## 2. Link hygiene and linking rules (L0, KNG-207/208) — default settings

1. **Plugin text.** `/account` with a wrong subcommand shows `/account [link|status]`; `/account link` ends with the
   red "Never give this code to anyone; staff never ask for it." line (an existing server keeps its old
   `messages.link-code-generated` in `config.yml`: delete the key or append the line, then restart); `/user statistics` on a Minecraft-only account
   shows the `/account link` hint.
2. **Registration unchanged.** `/account link` → `/auth/register` with the code works exactly as before.
3. **Fold (case B).** A web-only account (made before KNG-67) enters a code from a Minecraft-only account on
   `/account/link` → "your login moved", the header shows the Minecraft name, a reload keeps the session, the old row is
   soft-deleted, `/account` in game shows "web account linked", balances are the higher of each.
4. **Fold refused.** The same with a Minecraft account that already has a web login → "This Minecraft account already
   has a web account…", nothing changes.
5. **Attempt limit.** Five wrong codes on `/account/link` → the sixth answers "Too many attempts. Try again in 15
   minutes." even with a valid code.
6. **Cleanup.** After an hour the API log shows "Link code cleanup" (only when something changed); a used code older
   than 7 days is gone from `linkcodes`.

## 3. Invitations (I1, KNG-212)

**Under the default `Mode=LinkCode`:**
1. `POST api/Auth/register` with an `inviteCode` → 403 `InvitesDisabled`; `/admin/invitations` shows the "mode isn't
   Invite" warning; the landing page shows the invitation steps and "Already playing? Type `/account link` …".
2. A non-admin staff member without `knk.admin.invites` gets the "staff only" screen and no **Invitations** nav entry.

**Set `Security__Registration__Mode=Invite` and restart the API** (on dev only; on the alpha see § 9):
3. **Personal invite.** Admin → **Invitations** → personal invite for your test address (send email on) → result
   panel with *Copy link* and the mail status; `/admin/email` shows the Invitation row. The group select offers
   **Alpha Tester** (seeded by `SeedAlphaTesterGroup`).
4. **Sign-up.** Open the link: the address bar shows `/invite`, the email is locked; sign up → logged in, `/account`
   shows "Email verified"; the user is `web-…`, `AdmittedAt` and `InvitedVia*` are set, Default + Alpha Tester
   memberships, **no** SIGNUP_GRANT ledger entry; a Welcome mail is queued. The same link again → "invalid or has
   expired".
5. **Shared code.** 2 uses → `/join?code=…` with two addresses → both work; a third → invalid; the redemptions drawer
   lists both, emails masked.
6. **Lifecycle.** Pause → refused; resume → works; rotate → the old code refused, the new one works, uses kept;
   revoke → refused; expired (1 day, or edit `ExpiresAt`) → refused with the same message.
7. **Grandfathered sign-up.** `/account link` code of a grandfathered player → registration works; of an account the
   plugin created after the switch (`AdmittedAt` NULL) → "You need an invitation" with the `/join` link.

**Plan § 8 extra checks:**
8. **Guess flood.** `for i in $(seq 1 15); do curl -s -o /dev/null -w '%{http_code}\n' -X POST -H 'Content-Type: application/json' -d '{"code":"KNK-AAAAA-AAAAA"}' $API/api/Invitations/check; done`
   → after 10 in a minute (`RateLimiting__Auth__PermitPerMinute`), **429**. The answers before that are the same
   generic "invalid" for every code.
9. **Mail bomb.** Personal invite for one address, then *Resend* four times within the hour → the first three mails
   (create + 2 resends) are **Sent**, the 4th mail (3rd resend) is **Suppressed** (3 invitation mails per address per
   hour) and the 4th resend answers **429** ("resent 3 times in the last 24 hours"). Each resend kills the previous
   link.
10. **Revoked link from the mail.** Revoke a personal invite, then click the link in its mail → the same generic
    "invalid or has expired" page as for a made-up link (no "revoked" wording).
11. **No dead end from the login page or `/auth/register`** (alpha finding 2026-10-25, knk-web-app
    `claude/invite-only-register-page`, needs knk-web-api with `GET api/Auth/registration-info`). Logged out:
    `/auth/register` opens on **Sign up with your invitation** (no link-code field; "Already playing and got a code from
    `/account link`?" unfolds it); a shared code typed there → `/join?code=…` checked; `K7QH-M2XA` typed there →
    `/link?code=…` checked at once. `/auth/login` → **Create an account** → `/join` with the "invite-only" note. Open a
    personal invite link → **Log in** → the login page's **Create an account** → back on `/invite` with the same
    invitation (the token is kept for the tab; it is forgotten after sign-up or when the invite is invalid). Under
    `Mode=LinkCode` all of this is as before: `/auth/register` opens on the link code and the login page links to it.

## 4. Admission gate and claim linking (I2, KNG-214) — `Mode=Invite` + `admission.mode: invite`

Set the plugin's `admission.mode: invite`, restart the server, and set `white-list=false` (`/whitelist off`) unless the
step says otherwise.

1. **Default first.** With `admission.mode: whitelist` and `Mode=LinkCode`: joins behave as before, the log shows
   `[KnK Admission] admission.mode=whitelist`, the API log has no `Admission` request, and
   `curl -H "X-API-Key: $KEY" "$API/api/Admission/<any uuid>?name=Test"` answers `{"admitted":true}`.
2. **Stranger.** The never-joined account joins → the disconnect screen shows the lines as written (title, "Go to
   <url>/link and enter", the code in bold `XXXX-XXXX`, "(valid 15 minutes)", the warning) with line breaks. No `users`
   row is created. The server log says "Refused <name> (<uuid>): admission.kick" and **not** the code.
3. **Same code.** Rejoin within 15 min → the same code; the minutes count down.
4. **Event order (Paper 26.3).** Turn the vanilla whitelist **on**: the stranger still sees the gate's screen (not "You
   are not whitelisted"); an admitted player who is not on the whitelist gets the vanilla screen. Turn it off again.
5. **Web-first.** Personal invite → sign up → `/account/link` (steps; the unlinked banner is hidden there and shown on
   other pages) → join with the stranger → enter the code → `/account`: linked, username = the Minecraft name, banner
   gone; `/admin/email` shows Welcome and MinecraftLinked; the profile activity shows "Minecraft account linked"; the
   balance log shows the SIGNUP_GRANT once. Rejoin → admitted → first-join welcome and kits **once** and the
   discovery announcements held for `onboarding.discovery-quiet-minutes` (one summary afterwards), exactly as on a
   game-first join; chat shows "Your Minecraft account is now linked to the web account st***@…".
6. **Game-first.** A second new account joins → code → `/link` logged out → "Verified: <name>" → invitation code →
   `/join` shows "<name> will be linked" → sign up → linked at once, the invite used once → rejoin → admitted.
7. **Log in from `/link`.** `/link` logged out → *Log in* → back on `/link` with the code kept → "Link <name> to my
   account" → linked.
8. **Not admitted web account.** Needs a **valid** claim code (from a stranger's disconnect screen, step 2) and a web
   account that is **not** admitted. Invited accounts are admitted by their invite and get a generated `web-…`
   username until linked, so un-admit one by email, not by name:
   `UPDATE users SET AdmittedAt = NULL WHERE Email = 'tester2@example.com';`, log in as it, enter the stranger's code
   on `/account/link` → "You need an invitation …" (403). A made-up code answers "invalid or expired" instead, which
   is step 15's check, not this one.
9. **Grandfathered and operators.** A grandfathered player joins normally. An operator without an account joins (one
   "Failed to create user … 403" warning, no crash).
10. **Deactivated.** There is no deactivate button; `IsActive` is a plain field of the user record. As staff, open the
    user form (the same one as § 1 step 4) and untick **Is active** if the form shows it, otherwise
    `UPDATE users SET IsActive = 0 WHERE Email = 'tester2@example.com';` → its player gets "This account is
    deactivated" (a staff save also ends the account's web sessions). Afterwards set `IsActive = 1` again.
11. **Staff Access card.** Admin → player profile → **Access**: *Admit* on a not-admitted account (the button only
    shows while the card says "Not admitted"; use the `AdmittedAt = NULL` update from step 8 and reload) (confirm; activity
    "Admitted by staff"; the player now gets in); *Detach web login* on a linked account → its sessions end, it can't
    log in, the Minecraft account stays; `/account link` registration works for it again.
12. **Plugin create refused.** `$KEY` is the plugin key: `dotnet user-secrets list` in the API repo shows it as
    `Security:PluginApiKey` (the same value as the plugin's `api.auth.api-key`). Without the header the answer is 401.
    `curl -X POST -H "X-API-Key: $KEY" -H 'Content-Type: application/json' "$API/api/Users" -d '{"username":"Stranger","uuid":"<new uuid>"}'`
    → 403 `NotAdmitted`.
13. **Finish-linking reminder.** An invited account left unlinked for 2+ days (or edit `CreatedAt`) → one FinishLinking
    mail within the hour, none on later sweeps.

**Plan § 8 extra checks:**
14. **Claim code guesses.** Logged in as an invited, admitted, unlinked account, enter five wrong claim codes on
    `/account/link` → the sixth answers "Too many attempts. Try again in 15 minutes." even with the right code (per
    account, `Security:LinkAttempts`). `/link` logged out (`claim/check`) gets 429 after 20 a minute per IP.
15. **Expired claim code.** Wait 16 minutes after the disconnect screen, then enter the code → refused; the page says
    to join again for a new code. Rejoin → a **new** code.
16. **Claim code typed as a link code** (2026-10-25). Logged out, on `/auth/register` → "Already playing…" → type the
    disconnect-screen code **with its dash** into the link-code field → the field says it's the server's code, the
    button reads **Continue with this code** → `/link` shows "Verified: <name>" without retyping. Type it **without**
    the dash → "invalid or has expired" plus the hint "Is this the code the server showed you…" linking to `/link`.
    Logged in as an unlinked account, on `/account/link` type `k7qh-m2xo` (a look-alike O) → "Recognised as the code
    from the server's disconnect screen" → linked (the O was read as 0). Every claim refusal on `/link`,
    `/account/link` and the invite sign-up form ends with "The same code stays valid for 15 minutes…".

## 5. API outage with the gate on

1. **Known player, API down.** Stop the API. A player who joined before (offline cache) gets in after ~3 s; a new UUID
   gets "Can't check your access right now". Start the API: both work again.
2. **Operator during an outage** (plan § 8). With the API stopped, an operator joins **without** delay (no API call)
   and plays; `/knk health` shows the API DOWN.

## 6. Kill switches (plan § 8)

Run each, check the effect, then undo it.

| Switch | How | Expect |
|---|---|---|
| Gate off | `admission.mode: whitelist` in `config.yml` and **restart** the server (the `admission:` section is read at start-up only; `/knk reload` doesn't switch it) **and** `/whitelist on` | strangers get "You are not whitelisted", no claim codes, no `Admission` requests in the API log |
| Sign-up off | `Security__Registration__Mode=LinkCode`, recreate the API | a sign-up through an invite link or `/join` is refused with "Sign-up with an invitation isn't open yet…" (403 `InvitesDisabled`); `/account link` registration works as before |
| Access sync off | `CloudflareAccess__SyncEnabled=false`, recreate the API | no `cloudflare` requests; `/admin/invitations` line "Access sync: off"; the list stays as it was |
| Sign-up pages closed | delete the Cloudflare **bypass application** | `/invite/x` and `/join` show the Access login (alpha only) |

## 7. Cloudflare Access sync (A1, KNG-216)

On dev with a Cloudflare test account, or on the alpha as part of § 9 step 2. NAS and dashboard steps:
[alpha go-live § 6.1](alpha-go-live.md).

1. **Off.** `SyncEnabled` unset: no `cloudflare` requests; `/admin/invitations` "Access sync: off"; sign-up goes
   straight to `/account/link` (no PIN panel); the register response has no `accessGate`.
2. **Misconfigured.** `SyncEnabled=true` without a token → one start-up error naming `CloudflareAccess:ApiToken`, the
   line red with the same text, no calls.
3. **On.** Configured (list, token, proxy) → within a minute the line is green with the list size; the API log shows
   one "Cloudflare Access sync: n added …" line and no email addresses. A 403 here means the token's permission
   (Account → Zero Trust → Edit, L6-11) doesn't cover Gateway lists.
4. **Invite lifecycle.** Create a personal invite → its address is in the list within ~5 s; revoke → gone; resend an
   expired one → back.
5. **Shared-code sign-up.** The new address is in the list before the PIN panel shows; the panel names the address.
6. **Personal-invite sign-up** (address already listed) → registration succeeds; note whether the API logs an "inline
   add failed" warning (L6-7, duplicate append).
7. **Account changes.** Deactivate → removed within ~5 s; reactivate → back. Staff email change → old address out, new
   in. Merge → the merged-away address out.
8. **Proxy down.** Stop `cfproxy` → registration still works (≤ 5 s slower), the line turns red; start it → green on
   the next run, the missed add is made.
9. **Safety valve.** 30 removals at once (or `ListId` pointing at a list with 30 strangers) → "30 removals held back";
   `MaxRemovalsPerRun=50`, restart → removed.
10. **Staff include.** The policy's staff *Emails* include is unchanged throughout.
11. **Private window (alpha).** `/invite/x` and `/join` load without Access (and say "invalid invitation" for a made-up
    link); `/account` and `/api/Users/1` show the Access login; a sign-up gets the Cloudflare PIN mail and `/account/link`
    opens after it.

## 8. End-to-end on dev (plan § 6.4, the I2 "Done when")

With `Mode=Invite`, `admission.mode: invite`, whitelist off, all in one pass:
- [ ] **Web-first:** invite → account → join → disconnect with a code → link → rejoin → first-join welcome and kits once.
- [ ] **Game-first:** join → code → `/link` → invite → account → rejoin.
- [ ] **Grandfathered player:** joins normally.
- [ ] **Operator:** bypasses.
- [ ] **API stopped:** a known player gets in; a stranger gets "unavailable".
- [ ] **Staff "Detach web login":** works.

§ 0–8 passed on dev and the feature branches were merged on 2026-10-24 (plan § 9 steps 2–4; see the chain report).

---

## 9. Alpha switch-over (alpha)

The authoritative step list with the commands is [alpha go-live § 11.1](alpha-go-live.md); this section is the test
you run at each step. Runbook order for every deploy: **back up → migrator → API → web app → plugin**.

1. **Deploy behaviour-neutral** (`Mode=LinkCode`, `admission.mode: whitelist`, `SyncEnabled=false`, whitelist on).
   - [ ] § 0.2 checks on the alpha DB after the migrator (every active account admitted; `Alpha Tester` exists).
   - [ ] § 1 steps 1–3 (with the relay of KNG-211 if it is live, else the Log transport).
   - [ ] § 4 step 1 (gate answers admitted, no claim codes); a tester joins and plays as before.
2. **Access sync on + bypass application** (go-live § 6.1 steps 1–7).
   - [ ] § 7 steps 3, 4, 10, 11. Testers without an account got a personal invite **before** the sync was switched on.
3. **`Security__Registration__Mode=Invite`.**
   - [ ] § 3 steps 3–4: the developer invites a test address and signs up. The gate is still off, so there is no
         claim code yet: the account waits on `/account/link` until step 4.
4. **`admission.mode: invite`, restart, then `white-list=false`.**
   - [ ] § 4 step 2 and the join part of step 5 with the developer's second Minecraft account (the account from
         step 3); step 9; § 5 step 1 with a tester's consent.
5. **Alpha sections:** § 3 steps 8–10, § 4 steps 14–15, § 6 (gate-off switch only, then back on).

Done when (plan § 8): the alpha runs invite-only with the whitelist off, these sections passed, and KNG-205 and its
children are closed.

---

## Findings

| Date | Who | Heads (api / app / plugin) | Sections run | Result / issues |
|---|---|---|---|---|
| 2026-10-24 | Pandi (dev API, web app and Paper 26.3 dev server on the PC) | api `d78dc75` / app `eeea86f` / plugin `7bea0793` | § 4 steps 5, 6, 8, 10, 11 (retest) | **Accepted** by the developer. With this the whole guide is done on dev: § 0–6 and § 8 passed or accepted, § 7 skipped (no Cloudflare test account; covered by § 9 step 2 on the alpha). Branches ready to merge in the chain report's order. |
| 2026-10-24 | Pandi (dev API, web app and Paper 26.3 dev server on the PC) | api `d78dc75` / app `eeea86f` / plugin `90b01850` → `7bea0793` | § 4 (re-run), § 5, § 6, § 8 | § 4 steps 1–7, 9, 12–15 **passed** after `d78dc75` (14 got its 429 after 14 requests: earlier UI attempts count). **Defect found** at steps 5–6: the first join after a web-first or `/link` link got "Welcome back" and the discovery announcements at once, not the game-first first join; the plugin only marked a first join for an account it created itself. Fixed in plugin `7bea0793`: an admitted account the server has never seen gets the same first join (welcome, kits once, quiet discoveries); steps 5–6 to be re-run. Same commit guards the `TelemetryListener` NPE for a player without a user id (step 9's operator). Steps 8, 10, 11 were run against the wrong row (invited accounts are named `web-…`, so `WHERE Username = 'tester2'` matched nothing); guide reworded, to be re-run. § 5 **passed**. § 6 **passed** (Sign-up pages closed: accepted, no Cloudflare on dev). § 7 skipped (no Cloudflare test account). § 8 **passed**. |
| 2026-10-23 | Pandi (dev API, web app and Paper 26.3 dev server on the PC) | api `8f489b9` → `d78dc75` / app `eeea86f` / plugin `90b01850` | § 2, § 3, § 4 steps 1–5 | § 2 **passed** (the red warning line needs `messages.link-code-generated` updated in an existing server `config.yml`; the default has it). § 3 **passed** (3.0 only as `InvalidInvite`, run after the switch; 3.5 with an existing row). § 4: **defect found** — the second join of a stranger got "Can't check your access right now": a reused claim code read from MySQL serialized `expiresAt` without `Z`, the plugin's `Instant` parser threw, the gate fell to the offline store (which knew the dev-server regular and let it in). Fixed in api `d78dc75` (expiry stamped UTC + regression test); § 4 to be re-run from step 2. Also seen: `TelemetryListener.onUserDataLoaded` NPE when a player has no user row (follow-up, pre-existing). |
| 2026-10-23 | Pandi (dev API + web app on the PC, Pickup transport) | api `8f489b9` / app `eeea86f` / plugin `90b01850` | § 1 | **Passed**, all 8 steps. Three guide fixes folded in: the guard needs `--no-launch-profile`; the staff email change goes through the user form; the reset cooldown hides the throttle unless lowered. |
| 2026-10-23 | Pandi (dev DB on the NAS) | api `8f489b9` / app `eeea86f` / plugin `90b01850` | § 0 | **Passed.** Migrations applied, § 0.2 data checks OK, the chain's 9 `[MySqlFact]`s 9/9 green (sequential run, 206 s). Setup bumps folded into § 0.2. Full `requires-mysql` set in parallel exhausted the NAS's connections (59/124 failed on "Too many connections"), not re-run; not needed for this feature. |
