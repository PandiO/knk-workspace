# Knights & Kings changelog

This is a human-readable record of capabilities merged into the V3 default branches. It is not a complete commit log or a promise that code has been deployed to a public server. See [the feature register](FEATURE_REGISTER.md) for design, branch and live-verification status. Entries before this changelog was established on **2026-09-28** are a selective backfill from merge records and feature plans; linked plans describe the precise live-test coverage.

## Unreleased — on feature branches, not merged

- **Form wizard: footer, unsaved-changes guard, blur validation, Save on any step; drafts per admin** —
  knk-web-app and knk-web-api `claude/form-wizard-edit-mode` (PandiO/knk-workspace#109, #186, #64 FormWizard part;
  UX/realtime chain link 5, 2026-10-26). Not merged, not live-tested. The form's buttons (Cancel, Previous, Save
  Draft, Next/Submit) stick to the bottom of the window; leaving a form with unsaved changes (a link, Back, the
  breadcrumb, a reload) asks first, and Cancel no longer asks when nothing changed; a field is checked when it loses the
  focus, and a refused Next shows a summary that links to the fields; editing an existing entity can be saved from
  any step ("Save changes"); one-line text fields are inputs ("Multi-line text" toggle in the field editor for the
  rest). Drafts and workflow sessions now belong to the logged-in admin (they were all saved as user 1, so Saved
  Progress was shared): the API takes the owner from the login. One-time cleanup after deploy and a backup:
  `scripts/maintenance/remove-user1-drafts-and-workflow-sessions.sql`. The debug logs in the form wizard are gone.
  Live checklist: [guides/form-wizard-edit-mode-smoke-test.md](guides/form-wizard-edit-mode-smoke-test.md).

## 2026-10-26

- **Dashboard explorer: one scrollbar, favourite types on top** — knk-web-app `main` `c3c0c9f`, merged `--no-ff` from `claude/dashboard-explorer-194`
  (PandiO/knk-workspace#194; UX/realtime chain link 3b, 2026-10-26). The explorer's list is the only thing that
  scrolls (it showed two scrollbars). A star on every type marks it a favourite: favourites are listed at the top
  A–Z, the rest A–Z below; kept per browser (localStorage). Live checklist: `guides/dashboard-return-smoke-test.md`
  section 9a.
- **Dashboard header spacing** — knk-web-app `main` `c3c0c9f`, merged `--no-ff` from `claude/dashboard-header-195` (PandiO/knk-workspace#195; UX/realtime
  chain link 3b, 2026-10-26). The dashboard no longer starts against the app's top header: explorer, title and the
  "New {Type}" / ⚙ buttons start 24 px lower, on one row, centred on each other and lined up with the table; the
  buttons are the same height, and on a phone a long "New {Type}" is cut off instead of pushing ⚙ off-screen. Live
  checklist: `guides/dashboard-return-smoke-test.md` section 8a.
- **Claim code field shows the dash from the start** — knk-web-app `main` `c3c0c9f`, merged `--no-ff` from `claude/claim-code-dash-196`
  (PandiO/knk-workspace#196, follow-up of #192; UX/realtime chain link 3b, 2026-10-26). On `/link` and `/account/link`
  the field shows `____-____` while empty and keeps the dash visible while the first four characters are typed
  (`K7__-____`); paste, autofill, Backspace/Delete across the dash and capitals work as before. Pasting the same code
  without its dash over the whole field no longer loses a character. Live checklist: `guides/invitations-smoke-test.md`
  step 17a.
- **Dashboard keeps its place; Submit waits for the save** — knk-web-app `main` `7ba0f4b`, merged `--no-ff` from `claude/kng-60-dashboard-hub`
  (PandiO/knk-workspace#177 link 1, #58; UX/realtime chain link 1, 2026-10-26). Not live-tested yet. The
  dashboard's type is in the URL (`/dashboard/{type}`; bare `/dashboard` reopens the last viewed type). Edit opens the
  form with `returnTo`, and Submit and Cancel go back to that dashboard type (the table reloads). Submit stays
  "Submitting…" with a "Saving {Type}…" line until the entity is saved; a second click does nothing. The draft is marked
  Completed only after the entity was saved. A success toast replaces the 3 s "Form completed" modal. Live checklist:
  `guides/dashboard-return-smoke-test.md`.
- **Dashboard as the CRUD hub: New, Configure, breadcrumbs, detail page header, Create New from metadata** — knk-web-app
  `main` `7ba0f4b`, merged `--no-ff` from `claude/kng-60-dashboard-hub` (PandiO/knk-workspace#177 link 2, #81, #39 Create New menu; UX/realtime chain link 3,
  2026-10-26). Not live-tested yet. "New {Type}" and a cogwheel to the type's Entity setup page next to the
  dashboard title, "New {Type}" in an empty table. One flat explorer list; types without a display configuration are
  marked and their View is disabled. An open form hides the explorer and shows a breadcrumb back to where it was opened.
  The detail page shows the entity's name with Back, Edit and Delete and its own tab title. Edit on a User row opens the
  player profile. The nav "Create New" menu lists every type the app can create (from the entity metadata; no more
  `itemType`, about 15 types added) and navigates once. The nav and page "Forms" are now "Entity setup" (route `/forms`).
  Live checklist: `guides/dashboard-return-smoke-test.md` sections 8–14.
- **Game Settings and Siege settings open only for the node their API checks** — knk-web-app `main` `7ba0f4b`, merged `--no-ff` from `claude/route-gates-185`
  (PandiO/knk-workspace#185; UX/realtime chain link 2, 2026-10-26). Not live-tested yet. `/admin/game-settings`
  and its nav link need `knk.admin.config`, `/admin/siege-configuration` and its link `knk.siege.admin.manage`
  (before: the moderator node `knk.admin.user.manage`, so a moderator got an editable page, "The hub-eligible domains
  could not be loaded" and a refused Save). Without the node the link is hidden and the page says "Staff only" with the
  node it needs. Live checklist: `guides/alpha-hardening-smoke-test.md` step 27a.
- **Buttons and inputs look as intended** — knk-web-app `main` `7ba0f4b`, merged `--no-ff` from `claude/styling-quick-wins-38` (PandiO/knk-workspace#38;
  UX/realtime chain link 2, 2026-10-26). Not live-tested yet. `primary-dark` exists (`#1d4ed8`), so the primary
  CTAs (login, register, account, every `FeedbackModal` confirm) darken on hover; `.btn*` are `inline-flex` with a gap,
  so an icon sits beside its label instead of above it; `btn-tertiary` (Save Draft) is styled; form fields that set
  `border-gray-300`/`border-slate-300` without a width (Game Settings, the builders, lootbox filters) and `.input` show a
  1px border. The `text-gray-400` contrast sweep stays with #95. Live checklist: the link 2 block of
  `reports/2026-10-26-ux-realtime-chain.md` (knk-workspace `main`).
- **Claim code fields show the separator themselves** — knk-web-app `main` `7ba0f4b`, merged `--no-ff` from `claude/claim-code-field-192`
  (PandiO/knk-workspace#192; UX/realtime chain link 2, 2026-10-26; closed alpha test run 1, #149). Not live-tested yet. On `/link` and `/account/link` the code field shows `XXXX-XXXX` as the player types or pastes the 8
  characters (with or without a dash, or with a space); the player never types the dash, the caret stays put, and
  Backspace/Delete work across it. The register page's invitation step checks 8 plain characters as a claim code
  first and goes on to `/link` verified when it is one. The separator is one constant (`CLAIM_CODE_SEPARATOR`, a dash
  until the testers decide; the API and the disconnect screen use a dash too). The link-code field and its #57 hints are
  unchanged. Live checklist: `guides/invitations-smoke-test.md` step 17.

## 2026-10-25

- **Invincible gates refuse ignition** — hotfix, knk-plugin `main` `ee35fb1`, merged `--no-ff` from `claude/adoring-wright-ejn8f7` on 2026-10-25 (developer decision 2026-10-25; not in Linear,
  free issue limit). Not live-tested yet. Before, a flame arrow, fire charge, flint and steel or Fire Aspect hit on an effectively-invincible gate (door
  flag or structure `IsInvincibleOverride`) started a burn whose damage no-op'd while its fire and smoke showed for the whole
  duration. Now `GateDoorHitService.handleIgnite` fires no `GateDoorIgniteEvent` for such a gate, and `GateFireSystem` puts out a
  burning gate that becomes invincible (a siege override mid-burn). Direct hits are unchanged (event fires, `HealthSystem` no-ops).
- **Invite-only onboarding: the Cloudflare step in every flow, no dead end from `/auth/register` or the login page,
  claim codes recognised in link-code fields** — knk-web-api `master` `fa28f7ea` and knk-web-app `main` `0d612702`, merged `--no-ff` from `claude/invite-only-register-page`
  (2026-10-25; comment on KNG-218, no issue of its own — free issue limit; found on the alpha with the first two
  testers). New anonymous `GET api/Auth/onboarding-info` (`registrationMode`, `accessGate`, `publicBaseUrl`; to add to
  the Cloudflare bypass). With the Access sync on: the sign-up form's done step lists Cloudflare's email + 6-digit code
  step and its button is a **full page load** (the in-app navigation skipped Cloudflare and every call then failed
  with "Network error"); `/invite`, `/join`, `/link` and the login page show the journey with that step; a missing
  Cloudflare session is recognised (health probe, opaque redirect) and answered with one banner, "Sign in with
  Cloudflare"; the invitation, welcome, finish-linking and password-reset mails carry the step (`{{#accessGate}}` blocks).
  With the sync off nothing about Cloudflare shows. Under `Mode=Invite` the register page opens on an invitation step (invitation code → `/join`, the
  server's `XXXX-XXXX` code → `/link?code=`, the link-code form behind "Already playing and got a code from
  `/account link`?"), the login page's **Create an account** continues the invite flow (`/invite` with the kept personal
  invitation, `/link` with a verified claim code, else `/join`), the invite and join forms' **Log in** returns to them, a
  claim code typed with its dash into a link-code field is routed to the claim flow (look-alikes folded on
  `/account/link`), and every claim refusal says the code stays valid for 15 minutes. Deployed to the alpha the same day (API `alpha-fa28f7ea`, web `alpha-0d612702`); waiting for the tester's check.
- **Menu startup validation keeps retrying while the API is down** — knk-plugin `main` `ad5786c`, merged `--no-ff` from
  `claude/menu-validation-retry` on 2026-10-25 (not in Linear, free issue limit). The 2026-10-24 retry only re-listed the templates; on the dev server the list came back
  while every per-key fetch still failed (the connectivity monitor still reported the API down), and the pass ended with
  nothing validated. Now a template that can't be fetched keeps the pass retrying (10 s, 20 s, 40 s, then every minute) until
  every listed menu is validated or blocked, and the API-recovery event (KNG-115) starts a pass at once. Not live-tested yet (the merge of the siege follow-ups before it was).

## 2026-10-24

- **Siege playtest follow-ups (2026-10-24)** — merged `--no-ff` from `claude/dreamy-fermi-4h2ldl`: knk-plugin `main` `75d619b`,
  knk-web-api `master` `1aba1ee` (migration `AddSiegeSkipSeconds`), knk-web-app `main` `4a9537e`, knk-workspace `main`; not in
  Linear (free issue limit). Live run 1 by the developer the same day: every section works except the menu validation retry
  with the API down at plugin start (continued on knk-plugin branch `claude/menu-validation-retry`). Five changes from the test round:
  (1) a melee hit on a gate door with a **Fire Aspect** weapon has a chance per level (`gates.fire-aspect.ignite-chance-per-level`,
  15 % × level) of setting the block alight like a flaming arrow; (2) the new **Cleaving** custom enchantment (I–IV): gate hits
  ×1.25/×1.5/×1.75/×2, and a right-click on a door block is a charged strike of 5/6/7/8 such hits (netherite sword: 50/72/98/128 of a
  500 HP gate) with wood-break sounds and splinters, then a 60/50/40/30 s per-player cooldown (`gates.cleaving` in `config.yml`;
  the API's ability catalogue and permanent enchant books know it too); (3) the **spawn picker opens at the team split** in the hub
  (no picker at match start; the start teleports everyone to their choice; the Information menu's "Change spawnpoint" shows from the
  hub on); (4) the **spawn menu shrinks** to its options, and `MenuTemplateSeed.RepairSiegeLayoutAsync` fixes the growth, minimum
  height and spawn-button phases of siege menus seeded before these layout changes (seeds are create-only, so an existing database
  kept the old 5/6-row static menus); (5) **`/siege skip` seconds are settings**: `PlayerSkipMatchmakingSeconds` (60) and
  `AdminSkipMatchmakingSeconds` (31) on the global siege configuration, web app → Siege settings → "Skipping matchmaking"
  (migration `AddSiegeSkipSeconds`; the plugin floors both at one second before voting closes).
  Two defects found in the developer's second round the same day and fixed on the branch: (a) with the API down when the
  plugin started, every inventory menu stayed unavailable until a restart (the startup validation lists the templates once)
  - the list is now retried (10 s, 20 s, 40 s, then every minute), a menu the validation never saw is validated on its first
  open, and a siege menu that falls back to chat logs why - **the retry did not help on the dev server** (the per-key fetches
  still fail while the connectivity monitor reports the API down and the pass then ends without another retry; see the
  `claude/menu-validation-retry` branch); (b) a member waiting in the **server hub** was never moved to the
  scenario hub or their spawnpoint: the hub is a domain with AllowExit off and the siege used a plain teleport, which the
  domain-access rule refuses - siege teleports now use the same scoped border-crossing transfer as the hub's portal and
  outage actions, and a refused siege teleport is logged instead of ignored.

- **Domain names: whitespace and newlines trimmed** (not in Linear, free issue limit; knk-web-api `master` `09cf7e4` + `ac0f160`,
  knk-web-app `main` `83609f7`, knk-plugin `main` `1593e70`; merged directly, no PR; not live-tested). The dev database held
  districts named `Residential District\n`: the form wizard's String field is a textarea, so Enter added a newline the API stored as is,
  and the action bar in game showed `You are now entering Residential District []`. `Domain.Name` now trims in its setter, and
  Town, District, Structure, GateStructure and `POST`/`PUT api/Domains` trim `Name` and `Description` at both ends in one place
  (`DomainNameRules`) and refuse a name that is empty after trimming (400). The plugin strips names defensively as well. **Deploy:**
  migration `TrimDomainNames` strips the whitespace from the existing `domains.Name` rows (data only, nothing to undo). The web app
  drops a line break at either end of any String field on submit (plain spaces stay: a chat prefix means them).
- **Form wizard: step completion conditions run** ([KNG-186](https://linear.app/kngpandi/issue/KNG-186); knk-web-api `master` `a38c8ee`,
  knk-web-app `main` `00e4af6`, merged directly, no PR; smoke-tested by the developer, [guide](guides/form-validation-result-log-smoke-test.md)).
  A step's completion condition ("Allow entry must be ticked before you continue") now stops Next while it fails. The API sent every
  condition and field validation as inactive before, so none ever ran. `StepCondition` and `FieldValidation` have a real `IsActive`
  (migration `FormConditionAndValidationIsActive`, default on), kept by save, clone and export/import; the form configuration's own
  never-set flag is gone. The builder can't author step conditions yet ([KNG-274](https://linear.app/kngpandi/issue/KNG-274)).
- **Form wizard: validation rules remember their last run** ([KNG-269](https://linear.app/kngpandi/issue/KNG-269); same merges).
  The API keeps the most recent run of each API-backed rule per entity (or per draft) and answers from it while the rule and the
  inputs it reads are unchanged, so re-opening an entity no longer re-runs every region check against the game server. Region
  rules expire after 24 h (`ValidationResultLog:ExternalStateTtlHours`), a redrawn region drops its rows, a check the plugin
  couldn't complete is never remembered, and the log never blocks a form if it can't be read. A step's rules go in one
  `validate-batch` request; a reused result shows "checked … ago" with a **Re-check** that runs the rule for real.
- **Invite-only sign-up, email engine, admission gate and web-first linking — merged, off by default**
  ([KNG-205](https://linear.app/kngpandi/issue/KNG-205) with KNG-206, KNG-207, KNG-208, KNG-211 (API half), KNG-212,
  KNG-214, KNG-216, KNG-218; knk-web-api `master` `4aeb794`, knk-web-app `main` `b7c0e88`, knk-plugin `main`
  `d56e41da`, merged directly, no PR; smoke-tested by the developer on dev 2026-10-23/24, every section of the
  [invitations smoke test](guides/invitations-smoke-test.md) passed or accepted except § 7, which needs the alpha's
  Cloudflare). The seven chain links below are now on the trunks. Nothing changes until the switch-over
  ([alpha go-live § 11.1](guides/alpha-go-live.md)): `Security:Registration:Mode` stays `LinkCode`, the plugin's
  `admission.mode` stays `whitelist`, `CloudflareAccess:SyncEnabled` stays false. **Deploy:** five migrations
  (`LinkCodePurpose`, `AddEmailOutbox`, `AddInvitations`, `SeedInvitationStaffNode`, `SeedAlphaTesterGroup`); outside
  Development the API refuses to start with the Log transport unless `Email__AllowLogTransport=true` (until the relay);
  the plugin's `config.yml` needs `web.public-url`, the `admission:` section (missing = whitelist) and the new
  `messages.link-code-generated` text, which an existing file keeps old. Two defects found on dev and fixed: a claim
  code reused from the database was sent without a UTC marker and the plugin fell back to its offline store (api
  `d78dc75`); the first join after a web-first or `/link` link got "Welcome back" and every discovery message at once
  instead of the first-join welcome, kits and quiet minutes (plugin `7bea0793`, which also stops a crash in the join
  telemetry for an operator without an account).
- **Invitations chain, link 7: rollout preparation (I3) — the chain is complete**
  ([KNG-218](https://linear.app/kngpandi/issue/KNG-218), parent [KNG-205](https://linear.app/kngpandi/issue/KNG-205);
  branch `claude/player-signup-invitation-flow-f4v7ul`: knk-web-api `8f489b9`). A data migration seeds the **Alpha
  Tester** group (weight 1, under Default, no extra permissions) that invitations grant by default; it leaves an
  existing group of that name alone. New: the [invitations smoke test](guides/invitations-smoke-test.md) (every check
  of the email engine, invitations, the admission gate, the Access sync, the kill switches and the alpha switch-over)
  and the living [account identity and admission](architecture/account-identity-and-admission.md) architecture doc.
  The alpha go-live guide, the closed-alpha runbook, the production installation guide and the player account guide
  describe the invite-only state after the switch-over, with the five switch-over steps and the kill switches
  ([alpha go-live § 11.1](guides/alpha-go-live.md)). Merged 2026-10-24 (entry above).
- **Invitations chain, link 6: Cloudflare Access sync and the sign-up bypass (A1)**
  ([KNG-216](https://linear.app/kngpandi/issue/KNG-216); branch `claude/player-signup-invitation-flow-f4v7ul`:
  knk-web-api `641f9c1`, knk-web-app `eeea86f`). With `CloudflareAccess__SyncEnabled=true`, the API keeps the
  Cloudflare Zero Trust email list `knk-api-testers` in sync: a new personal invite's address is added within seconds,
  a revoke, an unused expiry, a deactivation, a deletion or a merge removes it, and a sign-up with a shared code adds
  the new address during registration. Calls go through a `cfproxy` forward proxy that only allows
  `api.cloudflare.com`. `/admin/invitations` shows "Access sync: last OK 12:04 · 0 pending", red with the error, and
  the sign-up page tells new players that Cloudflare emails them a one-time PIN next. The NAS and dashboard steps
  (proxy, list, policy, token, bypass application for the sign-up pages, 30-day session) are in alpha go-live § 6.1.
  Off by default, so deploying changes nothing.
- **Invitations chain, link 5: admission gate on the game server (I2, plugin)**
  ([KNG-214](https://linear.app/kngpandi/issue/KNG-214); branch `claude/player-signup-invitation-flow-f4v7ul`:
  knk-plugin `90b01850`, on the KNG-182 branch). With `admission.mode: invite` in the plugin's `config.yml`, the game
  server asks the API about every connecting player right after Mojang sign-in: admitted accounts and operators get in,
  a new player is turned away with the claim code and the `/link` address on the disconnect screen, a deactivated
  account is refused. If the API doesn't answer within 3 seconds, players the server already knows still get in and
  strangers are asked to try again. A refused player no longer gets an account created. After a link the player sees
  "Your Minecraft account is now linked to the web account st\*\*\*@example.com. Not you? Tell staff right away." in
  game. The default stays `admission.mode: whitelist`, so deploying the plugin changes nothing until the switch-over.
 
- **Invitations chain, link 4: admission gate (server side), claim codes and Minecraft linking (I2)**
  ([KNG-214](https://linear.app/kngpandi/issue/KNG-214); branch `claude/player-signup-invitation-flow-f4v7ul`:
  knk-web-api `4d1fe00` + `44c5f63`, knk-web-app `a3f00fd` + `60ec323`). The API answers the game server's new
  pre-login question `GET api/Admission/{uuid}` (plugin key): with `Security:Registration:Mode=Invite` a player without
  an admitted account gets a claim code `XXXX-XXXX` for the disconnect screen (15 minutes, one per player), a
  deactivated one is refused; in every other mode everyone is admitted, so nothing changes until the switch. `/link`
  (open without an account) checks that code; a logged-in player links straight away, a new player signs up with an
  invitation and is linked in the same step. `/account/link` is the new onboarding page after an invitation sign-up
  and takes both claim codes and `/account link` codes; a banner reminds unlinked players. Linking a web account to
  Minecraft gives the starting balance, a "linked" mail and an in-game notice with the masked address. Staff get
  **Admit** and **Detach web login** on the player profile. An unlinked invited account gets one reminder mail after
  two days. The landing page shows the new join steps. The game server's side follows in link 5.

- **Invitations chain, link 3: invitations and invite-based registration (I1)**
  ([KNG-212](https://linear.app/kngpandi/issue/KNG-212); branch `claude/player-signup-invitation-flow-f4v7ul`:
  knk-web-api `77042fd` + `8ca8507`, knk-web-app `dfa5cdd` + `18f3c9f`). Staff with the new node `knk.admin.invites`
  (granted to Admin by a seed migration) get **Invitations** (`/admin/invitations`): personal invites by email, in
  bulk, emailed or as copy-links (single use, 7 days by default, at most 30), and shared codes `KNK-XXXXX-XXXXX` with
  a label and a use cap (5 by default, at most 50); links and codes are shown once and only their SHA-256 is stored;
  resend (rotates the link, 3 a day), rotate, pause/resume, revoke, and a redemptions drawer. `/invite/:token` (the
  address shown locked and verified, the token removed from the address bar) and `/join?code=` sign up with an
  invitation once `Security:Registration:Mode=Invite` is set, creating a web account (`web-…` name, no starting
  balance until Minecraft is linked) and taking the use in one conditional UPDATE. The default stays `LinkCode`:
  today's `/account link` registration is unchanged and invite fields are refused. Migration `AddInvitations`
  grandfathers every active account as admitted; accounts the plugin creates are admitted until the mode is
  `Invite`. Account page: "Email verified" badge.

- **Invitations chain, link 2: the email engine (E1)** ([KNG-206](https://linear.app/kngpandi/issue/KNG-206); branch
  `claude/player-signup-invitation-flow-f4v7ul`: knk-web-api `0d7ec4a` + `a8b42ca`, knk-web-app `aecd811`). Every mail
  now goes through a persistent `email_outbox` table, written in the same transaction as the change that causes it, and
  a background dispatcher that retries (1 min … 4 h, Failed after 6 attempts), drops reset mails whose link expired, and
  deletes the content once sent. MailKit replaces `System.Net.Mail`; HTML and text templates share one layout; a
  throttle caps mails per recipient (3 per kind, 6 in total per hour) and per day (300). Password reset, the
  email-change notice and the data-deletion mails use it, and a staff email change now notifies the old address too.
  Staff with `knk.admin.config` get **Mail** (`/admin/email`): the mail log with masked addresses, Retry and "Send test
  mail to me". New settings `Email:Transport`, `Email:AllowLogTransport`, `App:PublicBaseUrl` and others; outside
  Development the API refuses to start with the Log transport unless `Email:AllowLogTransport=true` (the alpha needs it
  until its relay works). [Email guide](guides/email.md).

- **Invitations chain, link 1: optional SMTP auth (E0 API half), link-code hygiene and the linking rules (L0)**
  ([KNG-211](https://linear.app/kngpandi/issue/KNG-211), [KNG-207](https://linear.app/kngpandi/issue/KNG-207),
  [KNG-208](https://linear.app/kngpandi/issue/KNG-208); branch `claude/player-signup-invitation-flow-f4v7ul`:
  knk-web-api `110451f` + `bb4b9ee`, knk-web-app `2bf70ab`, knk-plugin `30b10e6e` on the KNG-182 branch). With
  `Email:SmtpUsername` empty the reset and privacy mails go out without SMTP credentials, for the alpha's mail relay
  (`110451f` is self-contained for a cherry-pick to `master`). `linkcodes` rows carry a `Purpose` (link, password
  reset, admission claim) instead of being told apart by length; link codes are drawn without modulo bias; an hourly
  job expires and, after 7 days, deletes finished codes; five wrong codes block an account for 15 minutes (429
  `TooManyAttempts`). Linking a web-only account to an existing Minecraft account now folds the web login **into
  the Minecraft account** (decision I7): it keeps its id, stats, groups and balances (the higher of each), the shell
  is soft-deleted and signed out, and the web app is logged into the merged account. 409 `AlreadyRegistered` /
  `AlreadyLinked` refusals. The plugin's `/account` usage no longer lists `create`, the dead merge flow is gone and the
  link-code message ends with "Never give this code to anyone; staff never ask for it."

## 2026-10-23

- **Gate doors: open-door scans that work as expected** ([KNG-268](https://linear.app/kngpandi/issue/KNG-268),
  [KNG-270](https://linear.app/kngpandi/issue/KNG-270), [KNG-271](https://linear.app/kngpandi/issue/KNG-271); knk-plugin
  `main` `6ad683f8`, knk-web-api `master` `a853d37`, knk-web-app `main` `1d79af0`, merged directly, no PR; live-tested
  by the developer).
  - **Pairing along the slide.** A sliding door with an open-door scan moves each block to the open block straight
    along its slide; blocks no longer change columns (that jammed door 17).
  - **Empty open-door anchor = the anchor.** For a door that opens inside its own box, leave the open-door anchor
    empty: the scan starts at the anchor. An open scan made from another point than the one it is read from (anchor
    moved, cleared or edited) is ignored with a console warning until you scan again.
  - **Scans that can't work are refused** with the reason: a region door without its captured region (the message
    names `/gatedoor capture <id> opened|closed`), an open scan on a flood-fill door, a door without an anchor. A failed
    scan shows its reason once, and scan lists show "N blocks scanned." instead of a card per block and a broken picker.
  - **Deploy.** Import **GateDoor seed v3** and make it the default: it explains the open-door anchor and when an
    open-door scan is needed ([admin guide](guides/admin/gate-structures-admin-guide.md)).

- **Gate doors: no more jamming on their own decoration, and a GateDoor dashboard** ([KNG-272](https://linear.app/kngpandi/issue/KNG-272),
  [KNG-273](https://linear.app/kngpandi/issue/KNG-273); knk-plugin `main` `c09e9483`, knk-web-api `master` `85c0a26`,
  knk-web-app `main` `0ed300c`, merged directly, no PR; live-tested by the developer).
  - **Decorated doors move.** A door whose blocks of different materials follow each other in the direction it moves
    (chains above a portcullis, a decorated top row) jammed on its own blocks: a fence rising into the cell a chain had
    just left found the chain there and called it an obstruction. The door now clears such a cell first. A block a
    player puts in the way still jams it.
  - **GateDoor dashboard.** The web app's dashboard and GateDoor pickers list doors across all gates, with the gate's
    name, through the new `POST api/GateDoors/search` (search on door or gate name, filters gate, type, state, active).
  - **Configuring a door like this.** A door that rises and loses its chains needs no open-state scan: motion distance
    plus *Clip to geometry bounds* removes the chains as they leave the door box
    ([admin guide](guides/admin/gate-structures-admin-guide.md)). The open-scan pitfalls found on the way are fixed in
    the entry above.

- **Domain sub-regions: one domain, several WorldGuard regions** ([KNG-253](https://linear.app/kngpandi/issue/KNG-253),
  phases KNG-254–KNG-259; knk-web-api `master` `779629e`, knk-plugin `main` `9dfd7aae`, knk-web-app `main` `bf0d142`, merged directly, no PR; smoke-tested by the developer). A town, district,
  structure or gate can have extra regions besides its main one, added in a new "Sub-regions" step of its form. Example:
  a garrison gate's round tower next to its house.
  - **Naming.** Each sub-region is drawn through its own world task and renamed `domain_<id>_sub_<n>` on save.
  - **Copy of the main region.** The game server keeps every sub-region a copy of the main region: priority, flags,
    owners, members, with the main region as parent. This runs every 5 minutes, on `/knk regions repair` and on the new
    `/knk regions sync`.
  - **One domain.** Walking between a domain's regions gives no enter or leave message and no access refusal, even
    with Allow exit off. A door location in the tower counts as inside the gate. Discovery and analytics count the
    domain once.
  - **Round selections.** `//sel cyl` (and ellipsoid, convex) now becomes a polygon along its block outline, for every
    region a world task draws. Before, it became the box around it.
  - **Removed sub-regions.** One no domain lists is orphaned within two syncs, and the daily cleanup deletes it after
    `regions.temp-retention.days` (14). `/knk regions temp [purge]` lists and purges orphans.
  - **Fixes on the way.**
    - `knk-creation-timestamp` and the new orphan mark are now read back after a restart. Temp regions used to read as
      "without a creation time" after one.
    - A gate's edit form lists its sub-regions.
  - **Deploy.** Run the migration `DomainSubRegions`, import the seeds (`DomainSubRegion`; Town, District and Structure
    v2; GateStructure v3; display seeds v2), and deploy API and plugin together
    ([admin guide](guides/admin/domain-subregions-admin-guide.md), [design](specs/domain-subregions/DESIGN.md)).
  - **Not yet.** Placement checks for a drawn sub-region ([KNG-261](https://linear.app/kngpandi/issue/KNG-261)), and
    navigation knowing sub-regions ([KNG-260](https://linear.app/kngpandi/issue/KNG-260)).

- **Enchantments from the server scan, vanilla and custom in one picker** ([KNG-250](https://linear.app/kngpandi/issue/KNG-250);
  knk-web-api `master` `a1f8838`, knk-web-app `main` `f9ee73c`, knk-plugin `main` `c7806b87`, merged directly, no PR;
  live-tested by the developer). The **Scan server** of the Minecraft catalogue now reads the server's enchantments too,
  plus knk-plugin's 12 custom enchantments as `knk:<id>`. Old rows in another notation (a custom `chaos` saved without
  namespace) merge into the scanned row; unknown rows nothing uses are deleted and used ones become Missing. Every
  enchantment gets an enchantment definition (existing ones are linked, never deleted), so the item blueprint and lootbox
  pickers offer every vanilla and custom enchantment. The enchantment picker in forms searches the database, shows
  vanilla and custom together with a Custom badge and an All / Vanilla / Custom filter, and never creates anything on a
  pick any more (fixes [KNG-243](https://linear.app/kngpandi/issue/KNG-243)). The catalogue page shows the enchantment
  counters and "Missing enchantments still used". The built-in enchantment list and the hybrid picker are gone. Run the
  migration `MinecraftEnchantmentCatalogFields`, deploy plugin and API together and scan
  ([admin guide](guides/admin/minecraft-catalogue-admin-guide.md), [plan §12](specs/minecraft-catalog/IMPLEMENTATION_PLAN.md)).

- **Non-op players can pick up a world lootbox inside a protected region** ([KNG-266](https://linear.app/kngpandi/issue/KNG-266);
  knk-plugin `main` `1fbcb046`, merged directly, no PR; smoke-tested by the developer). WorldGuard refused the click on
  a box in a spawn area inside a domain region to anyone who isn't a member, so only ops could pick boxes up there. The
  plugin now tells WorldGuard to allow clicks on lootbox entities only; every other entity in the region stays protected.

- **Item blueprint Category filter in the web app, child categories included** ([KNG-263](https://linear.app/kngpandi/issue/KNG-263);
  knk-web-app `main` `b83e376`, merged directly, no PR; checked by the developer). The
  item blueprint list and every item blueprint picker get a Category filter that lists the category tree; choosing
  "Weapons" also shows the blueprints in Swords and Bows. The API's item blueprint search already worked this way (since
  2026-09-26), and so does the in-game item catalogue's category button. The list also shows each blueprint's category.

- **Item blueprints are cached for their own configured time** ([KNG-262](https://linear.app/kngpandi/issue/KNG-262),
  item blueprints only; knk-plugin `main` `64f39d28`, merged directly, no PR; smoke-tested by the developer).
  The plugin now keeps item blueprints for `cache.entities.itemBlueprints.ttl-minutes` (20 minutes) instead of the
  global 60 s, so the catalogue, kits and `/knk ib give` call the API far less often. A blueprint edited in the web app
  reaches the game within 20 minutes, or at once after `/knk cache refresh`. The other entities still use the global TTL.

- **Menu paging: the right page number and a fast item catalogue** ([KNG-230](https://linear.app/kngpandi/issue/KNG-230),
  [KNG-231](https://linear.app/kngpandi/issue/KNG-231); knk-plugin `main` `fae0b3b2`,
  merged directly, no PR; smoke-tested by the developer). Pager arrows show the current page instead of "Page 1/N" in every paged menu. Changing
  page re-renders from the open menu instead of fetching its template again. While a page loads, its arrows turn into a
  clock "Loading page N…" (and the action bar says it after half a second); further clicks wait for it; a failed load
  puts the previous page back with a message. The item catalogue keeps built pages for a minute, shared by all players,
  and loads the next page in the background, so paging forward is usually instant.

## 2026-10-22

- **Minecraft catalogue from the server itself** ([KNG-200](https://linear.app/kngpandi/issue/KNG-200); knk-web-api
  `master` `4f34f58`, knk-web-app `main` `0622a87`, knk-plugin `main` `69c93885`, merged directly, no PR). **Scan server** on
  the new admin page `/admin/minecraft-catalog` has knk-plugin read the server's registry (a headless WorldTask). The API
  stores every item and block with its name, item/block flags, default block state and a picture from a versioned public
  asset source (PrismarineJS, then InventivetalentDev), keeping ids, merging rows that only differ in notation, deleting
  unreferenced rows the server doesn't know and marking referenced ones Missing. Material pickers search this database
  only: items by default (`categoryFilter` BLOCK/ANY/BANNER), with name, key and icon; no more duplicate rows or poor
  search. The item blueprint overview shows the item's picture. The page also lists missing icons (with your own URL as
  override), an audit with **Merge into…**, and a backfill. The built-in material list (1.21.4, half of its icon URLs
  broken) and the hybrid picker are gone; a new database stays empty until its first scan. Run the two migrations as the
  [admin guide](guides/admin/minecraft-catalogue-admin-guide.md) describes. Live-tested by the developer on Minecraft 26.3
  (1812 entries). Follow-ups: [KNG-250](https://linear.app/kngpandi/issue/KNG-250) (enchantments),
  [KNG-251](https://linear.app/kngpandi/issue/KNG-251) (block-state picker). In passing: the object dashboard and form
  pickers now find their column definitions (the lookup was case-sensitive).

- **Performance metrics for the closed alpha** ([KNG-232](https://linear.app/kngpandi/issue/KNG-232); knk-plugin
  `main` `390d88a4`, knk-web-api `master` `3658cf2`, merged directly, no PR; unit-tested, not live-tested, everything off by default). The plugin can serve a Prometheus `/metrics` (`metrics.enabled`, off by default, bearer token) with TPS, tick
  time, players, chunks and entities per world, JVM heap/off-heap/GC, process CPU/RSS, the container's memory working set
  against its limit, API-call latency and the cost of 16 recurring tasks. The API's `/metrics` is now real
  (`Telemetry__Prometheus__Enabled` + a bearer token; the earlier note that it existed was wrong) and adds .NET runtime,
  HTTP client, process/cgroup and database-command metrics. Read the
  [performance metrics and capacity guide](guides/performance-metrics-and-capacity.md) for the collection stack, load
  steps, acceptance thresholds and the NAS-vs-cloud decision.

- **Default forms and display pages for the rest of the game content** ([KNG-139](https://linear.app/kngpandi/issue/KNG-139);
  knk-web-api `master` `3eac5ec`, knk-web-app `main` `0736ef3`, merged directly, no PR). 30 more bundled form seeds
  (Town, District, Street, Structure, Location; User, permission groups and grants, banners, Clan; grades, tags,
  categories, enchantments, item blueprints; kits and lootboxes), reworked from the dev forms with a description on
  every step and field and their known bugs fixed, and 7 display seeds (Structure, GateStructure with a warp and
  navigation section, User, ItemBlueprint, EnchantmentDefinition, MinecraftMaterialRef, ItemBlueprintDefaultEnchantment).
  Display configurations get **Export JSON** and **Import / Seeds** like form configurations (`knk-displayconfig/1`).
  Import both from the configuration lists and make them the default. Smoke-tested by the developer on 2026-10-22:
  every step passed or was accepted. Follow-ups: [KNG-243](https://linear.app/kngpandi/issue/KNG-243),
  [KNG-244](https://linear.app/kngpandi/issue/KNG-244), [KNG-246](https://linear.app/kngpandi/issue/KNG-246),
  [KNG-247](https://linear.app/kngpandi/issue/KNG-247), [KNG-248](https://linear.app/kngpandi/issue/KNG-248);
  details in the [seed review notes](reports/2026-10-19-kng-139-seed-review-notes.md).
- **Form saves keep what they should** ([KNG-195](https://linear.app/kngpandi/issue/KNG-195); same merges). A
  Structure's spawn point captured in game is saved; editing a player no longer unfreezes them or resets their email
  verification, account origin, gender, active state or gate pass-through; picking the empty option of an optional
  list no longer makes the save fail; a material or vanilla enchantment that isn't in the database yet is saved from
  the picker; saving a custom enchantment keeps its ability.

- **Gates can be warp destinations, and the gate form has the /navigate and road settings**
  ([KNG-229](https://linear.app/kngpandi/issue/KNG-229); knk-web-api `master` `be9f4e1`, merged directly, no PR). The
  bundled form seed "GateStructure - Default (seed v2)" adds "Entry rule on roads" and "Navigate to", plus a "Warp
  destination" step (on/off, price in gems, minimum title, minimum premium tier, discovered gates only), as on the
  Structure form. The API now stores a gate's warp settings; before, `GateStructureService` ignored them, although
  `/warp` already listed gates. A save without the warp step (the plugin, the v1 form) keeps them. Import the seed from
  Import / Seeds and make it the default; it imports next to v1. Smoke-tested by the developer on 2026-10-22: every step
  passed or was accepted.

## 2026-10-21

- **The plugin runs on Minecraft 26.3** ([KNG-182](https://linear.app/kngpandi/issue/KNG-182); knk-plugin `main`
  `857d4b1e`, merged directly, no PR). Paper 26.3 build 205 on Java 25 (Gradle 8.14 itself still runs on Java 21),
  `api-version` 26.3, WorldEdit 7.4.6 and WorldGuard 7.0.20 (the dev server runs FastAsyncWorldEdit 2.16.1). The world
  loader also finds worlds in Paper 26.x's `<level>/dimensions/minecraft/<name>/`, where Paper moves the hub and the
  other worlds on their first load, so the second start no longer reports the hub missing. Offline `/inventory` and
  `/enderchest` read `<world>/players/data`. Paper converts the world storage on the first 26.3 start; it can't be
  undone. Live-tested by the developer on `DEV_SERVER_26.3` on 2026-10-18 and 2026-10-20
  ([smoke test](guides/minecraft-26.3-upgrade-smoke-test.md)): every step passed or was accepted except the hub
  tiles of `/menu`, which were hidden because the server had started while the API was down
  ([KNG-201](https://linear.app/kngpandi/issue/KNG-201), not a 26.3 problem). The same startup-only shape was found
  in siege, gates and regions ([KNG-202](https://linear.app/kngpandi/issue/KNG-202),
  [KNG-203](https://linear.app/kngpandi/issue/KNG-203), [KNG-204](https://linear.app/kngpandi/issue/KNG-204)).
- **`/hub` takes any player to the hub** ([KNG-188](https://linear.app/kngpandi/issue/KNG-188); reached knk-plugin
  `main` with KNG-182 at `857d4b1e`, through the KNG-182 branch). Its three live checks are still to run. `/hub` goes to the hub spawn selected on the Game
  Settings page through the regular teleport engine: warmup, movement and combat cancel, the safe-spot check, and the
  siege, freeze and outage guards. It has its own cooldown, and the groups' spawn settings set its cooldown and price.
  Without a usable hub it says "The hub isn't available right now." and moves nobody. Staff can send a player with
  `/hub <player> [-s]`. `/hub return` is unchanged ([hub DESIGN §16.8](specs/hub/DESIGN.md)).

## 2026-10-19

- **Drawbridges swing as one straight plank, including arched doors**
  ([KNG-193](https://linear.app/kngpandi/issue/KNG-193); knk-plugin `main` `79be4882`, knk-web-api `master` `2d71155`,
  merged directly, no PR). A `ROTATION` door with a horizontal hinge was drawn mid-swing as a cloud of individually
  rotated blocks with a rigid fit, a residual and a snap on top, so its parts moved at different speeds. It is now
  played back as whole-door keyframes precomputed at load (`DrawbridgeKeyframes`): a digital-line plank from the hinge
  to the tip, one keyframe per tip-cell change, the closed scan verbatim at one end and the open scan verbatim (or a
  deck `MotionDistanceBlocks` long, counted in blocks) at the other; the door's own shape is the mask, so an arched
  door scanned in REGION mode with a material whitelist keeps its arch. The old path stays behind
  `gates.rotation.keyframes-enabled` until [KNG-194](https://linear.app/kngpandi/issue/KNG-194) removes it. The GateDoor
  form seed v2 adds the deck length for rotating doors and a "Door materials" field for region and flood-fill scans.
  Live-tested by the developer on gate door 14 (2026-10-19); the cardinal, arched, switch and fall-back checks of
  [guides/gate-smoke-test.md §3](guides/gate-smoke-test.md) were accepted without a run.

## 2026-10-18

- **Many-to-many form steps without a carrier field keep their relationships**
  ([KNG-190](https://linear.app/kngpandi/issue/KNG-190); knk-web-app `main` `e30c815`, merged directly, no PR).
  The wizard only kept a many-to-many step's relationships when its FormConfiguration also had a List field named
  after the step's related property, which the builder neither adds nor requires, so every add, remove and re-order
  on such a step was dropped. The wizard now adds that field when it loads a form. The seeded forms already had it.
  Also: the three web-app test suites that failed on `main` pass again (`test:ci` 154/154), and a duplicate, unused
  `useEnrichedFormContext` is gone. Ported from the stale `claude/bold-goodall-7eg00l` branch; live-tested by the
  developer (2026-10-18).

- **Fields asked in more than one form step share one value**
  ([KNG-120](https://linear.app/kngpandi/issue/KNG-120); knk-web-app `main` `0027677`, merged directly, no PR).
  A FormConfiguration can ask for the same property in two steps (the default District form asks for the Location
  twice). Filling the first copy left the second empty, and on submit the empty copy overwrote the value with null.
  Now changing either copy updates the other, in both directions and for every way a value changes (typing, value
  projections, child-form results, ItemScan); a resumed draft fills empty copies; an empty copy never overwrites a
  filled one on submit. Live-tested by the developer on the District form (2026-10-18).

- **The items catalogue shows each item with its default enchantments**
  ([KNG-175](https://linear.app/kngpandi/issue/KNG-175); knk-plugin `main` `147806d8`, merged directly, no PR).
  The `/menu` item catalogue built its icons from the blueprint alone, so the vanilla enchantments and custom
  enchantment lines a kit or `/knk itemblueprints give` adds were missing. It now builds them the same way
  (`assembleDefaults`), from the enchantments the blueprint already carries. Unit-tested; merged at the
  developer's request, no in-game result recorded.

- **Re-running a domain's region step replaces its region instead of leaving an orphan**
  ([KNG-103](https://linear.app/kngpandi/issue/KNG-103); knk-plugin `main` `e574f45` ([#12](https://github.com/PandiO/knk-plugin/pull/12)),
  knk-web-api `master` `73c70d5` ([#10](https://github.com/PandiO/knk-web-api/pull/10))). [Architecture](architecture/managed-worldguard-regions.md) §7.
  - Drawing a new region for an existing Town, District, Structure or Gate and saving it now gives the new region the
    domain's `domain_<id>` name. The old `domain_<id>` is redefined in place, keeping its parent, priority, owners,
    members and flags, and child regions stay linked. Before, the rename was refused, so the domain stayed on
    `tempregion_worldtask_<n>` and the old region stayed behind.
  - The API names the domain's previous region; the plugin only removes the domain's own `domain_<id>` or a temp
    region, and puts everything back if a step fails.
  - **`/knk regions temp`** reports leftover temp regions and `domain_<id>` regions no domain uses;
    **`/knk regions temp purge [hours]`** deletes unused temp regions older than `hours` (default 24).
  - Domains the old bug already left on a temp name are fixed once by hand (§7).
  - Live-tested by the developer (2026-10-18).

- **Commands show only what a player can use, and permission checks no longer flood the API**
  ([KNG-107](https://linear.app/kngpandi/issue/KNG-107); knk-plugin `main` `3ca5b3f`, knk-web-api `master`
  `ac3c869`; merged directly, no PR). [Architecture](architecture/plugin-permission-checks.md).
  - **`/knk help`** lists the `/knk` subcommands and the plugin's other commands the player may use, 8 lines a page
    with clickable page links (`/knk help <page>`); a command they can't use reads as unknown.
  - **Tab completion** offers only usable subcommands, actions, flags and player names; gate commands only the
    gates the player controls.
  - **"No permission" instead of the usage** for `/knk` subcommands and standalone commands the player holds no
    node for; usage lines name only the action typed or the held ones.
  - **The "/" list** leaves out commands the player can't run, every `plugin:command` form, and other plugins'
    commands they can't use (config `command-visibility.*`, `always-show` for exceptions). Ops see everything.
  - **One permission load per player:** checks resolve from the player's effective set, loaded at login and
    refreshed every 30 s, instead of one API request per node (a join sent 116 and `/knk help` 244, about 10 s).
    The API's effective set now carries `sourceRank`; the plugin also works with an API without it. A change made
    with `/knk user` applies at once.
  - Live-tested by the developer (smoke test and two retests, 2026-10-18).

## 2026-10-17

- **Gate doors refuse a Reference point 2 that isn't straight above the anchor**
  ([KNG-132](https://linear.app/kngpandi/issue/KNG-132); knk-web-app `main` `7c00508`, knk-plugin `main`
  `82455cf`). Both reference points are measured from the anchor: point 1 along the bottom edge (width), point 2
  straight up (height). A point 2 above point 1 gave a slanted height of 2, the block
  scan stored the wrong blocks and the door jammed. The GateDoor form now refuses such a point and says where it
  should be, the plugin's block scan refuses it too, and loading such a door logs a warning. The field descriptions
  come from the GateDoor form seed (KNG-139). Unit-tested; smoke-tested in game and merged by the developer.
- **Form wizard: child forms save what they create, sessions remember it, and ready-made gate and siege forms**
  ([KNG-133](https://linear.app/kngpandi/issue/KNG-133)…[KNG-139](https://linear.app/kngpandi/issue/KNG-139),
  [KNG-162](https://linear.app/kngpandi/issue/KNG-162), [KNG-164](https://linear.app/kngpandi/issue/KNG-164) and the
  smoke-test follow-ups KNG-166…169, KNG-172…174; branch `claude/wonderful-darwin-u39k1o`, which replaced
  `claude/jolly-archimedes-urhio9`: knk-web-api `master` `2929972`, knk-web-app `main` `bbd0dae`, knk-plugin `main` `5643ae6a`; merged
  directly, no PRs). **Needs two additive migrations** before the new web app runs against a database:
  `AddFormFieldSelectionLimits`, `AddFormSubmissionProgressCreatedEntities` (the dev DB has them).
  - **Child forms:** a "Create New" entity on a List field is saved when its form completes, and a form refuses to
    submit an entity that was never saved. **Edit instance** opens with the values the form holds. Editing loads
    List relationships (`districtIds`).
  - **Required lists and limits:** a required List refuses an empty list; minimum/maximum selections are stored and
    enforced.
  - **Step names** in the progress bar and as the title in edit mode, Boolean descriptions. Many steps scroll
    sideways; on a phone "Step 3 of 9 · Name" opens a list of all steps (KNG-168).
  - **Session entities:** what a form created is pinned in every picker of that type ("Created in this form", New),
    also after resuming a draft. **Cancel form** and deleting a draft ask whether to keep (default) or delete what
    child forms saved; in-use entities are skipped with the reason.
  - **Export / import:** Export JSON per form configuration, Import / Seeds with a dry run; never overwrites. Ten
    bundled seed forms: GateStructure (no house number), GateDoor and the siege set. On the dev DB the seeds are the
    defaults.
  - **Pickers** show the columns that tell rows apart (District: Town; Street: Districts, Towns; gates and structures:
    street + number, District, Town); saved columns map to them, and "Use built-in columns" clears saved ones
    (KNG-166).
  - **Refusals explain themselves:** a refused delete names what still uses the item ("This street can't be
    deleted: it is still used by 1 structure."), confirmations are in-app modals, no browser boxes (KNG-169).
    A form configuration that was opened can be deleted; its drafts go with it (KNG-172).
  - **Minecraft validation:** warning is warning and block is block; failures name what the region or location must
    be inside, a missing parent region or a wrong world get their own sentence (KNG-173). One open world task at a
    time, readable task header (KNG-174). A typed Location name survives a capture (KNG-167).
  - **Fixed along the way (live test):** a failed region rule no longer answers 500 (object cycle); a form rule's
    changed dependency path is saved; the rule builder finds a parent form's fields again (it showed "Property
    'Town' not found on entity 'SiegeObjective'").
  - **Live:** smoke-tested by the developer 2026-10-12 and 2026-10-16/17, all sections passed or accepted
    ([chain report](reports/2026-10-11-form-wizard-chain.md),
    [follow-ups and live test](reports/2026-10-12-form-wizard-chain-smoke-followups.md)). Follow-ups in Linear:
    KNG-183 (M2M direct pick), KNG-184 (clickable steps), KNG-185 (refusal details), KNG-186 (`isActive` never
    set), KNG-187 (web app: wrong world / missing region), KNG-188 (`/hub`).

- **The hub: a protected arrival world, API-outage actions and portals** ([KNG-109](https://linear.app/kngpandi/issue/KNG-109),
  KNG-113, KNG-114, KNG-116, KNG-117; knk-web-api `547d2b2` [#8](https://github.com/PandiO/knk-web-api/pull/8), knk-web-app
  `e86af25` [#6](https://github.com/PandiO/knk-web-app/pull/6), knk-plugin `9f31db6` [#11](https://github.com/PandiO/knk-plugin/pull/11)).
  - **Worlds:** KnK loads the worlds listed in `worlds.load` (e.g. a void `hub`). Gates animate only in their own world.
  - **Admission:** a Town, District or Structure can be selected as the hub on the Game Settings page. Joining players
    then arrive at its spot before they appear, also while the API is down. A missing hub refuses non-ops.
  - **Hub rules:** no combat or building, storage and item frames closed, doors and NPCs open (past WorldGuard), and the
    Peaceful heal/feed preset.
  - **API outage:** per hub or per group, Do nothing, Send to the hub, Kick or Send to world spawn, after a delay counted
    from the first failed health check. A Siege match is aborted.
  - **After the outage:** players get a clickable return to their spot, with fallbacks for an unsafe spot.
  - **Portals:** WorldGuard regions that take players into the game. Leaving otherwise says "use the portal".
  - **Also changed:** group overrides rank by hierarchy, then weight. Deleting a Location never deletes its domain.
  - **Live:** smoke-tested by the developer in three runs ([report](reports/2026-10-17-hub-smoke-test.md)). The remaining
    checks and Siege were accepted without a run.

Delegated batch of 2026-10-15 (`claude/linear-issues-delegation-k1trkm`), merged with trunk: knk-web-api `181bf3f`
([#11](https://github.com/PandiO/knk-web-api/pull/11)), knk-web-app `2fcbeae` ([#7](https://github.com/PandiO/knk-web-app/pull/7)),
knk-plugin `ad3bc48` ([#14](https://github.com/PandiO/knk-plugin/pull/14)). Developer live check 2026-10-17: KNG-171, KNG-121 (T1-T3),
KNG-125 and KNG-126 passed; KNG-121 T4, KNG-124 and KNG-118 accepted without a run.

- **Commands answer at once during an API outage** ([KNG-171](https://linear.app/kngpandi/issue/KNG-171); knk-plugin
  `77235931`). While `/knk health` shows DOWN, reads skip the API instead of trying three times: `/msg`, `/tpa` and
  `/knk help` no longer wait about a second. Permission checks answer from memory or the offline store with the same
  rules (a last-known deny stays a deny, an expired answer counts as denied). Writes still go to the API. Switch:
  `api.connectivity.skip-api-while-down` (on). See [architecture](architecture/api-connectivity.md) and the
  [outage smoke test](guides/api-outage-smoke-test.md).
- **Walk paths keep out of a region the player could not leave again** ([KNG-121](https://linear.app/kngpandi/issue/KNG-121);
  knk-plugin `8f28d65f`). The "no way out" rule of the road router now applies to walk legs too (direct mode, the
  walk to the road, the last leg): a region that allows entry but not exit is avoided unless the destination is in it.
- **Shut in close to a road: "No conventional path to the road found."** ([KNG-124](https://linear.app/kngpandi/issue/KNG-124);
  knk-plugin `e2955728`). A player within 8 blocks of the route but not on it gets a short check search; if they are
  boxed in, they get the message once. A player on the road sees no change.
- **Inventory menus: item blinker** ([KNG-125](https://linear.app/kngpandi/issue/KNG-125); knk-plugin `aaeb8e48`).
  New `BLINK` display mode: the item alternates with a yellow glass pane (same name and lore) every 10 ticks, its
  clicks keep working, and it stops on close. First user: the open group selector in the statistics visibility menu.
- **Staff note forms say why Reverse / Apply can't run yet** ([KNG-126](https://linear.app/kngpandi/issue/KNG-126);
  knk-web-app `7f5b9a8`). The transaction Reverse form and the Adjust balance card show a live "n / 10 characters"
  counter, and submitting with a short reason explains what is missing instead of doing nothing. Disabled buttons
  now look disabled.
- **Multiworld follow-ups** ([KNG-118](https://linear.app/kngpandi/issue/KNG-118), the items not already on the hub
  branch; knk-plugin `8ca2f1c9` `e9cc237b`, knk-web-api `d91a141` `3e666da` `faf9885`, knk-web-app `6c3d4bf`).
  Discoveries are kept per world (same region id in two worlds = two discoveries; spool file version 3, old files
  still read). The loaded-worlds report is kept per server (`game-settings.server-id`). A District's new inline
  Location, a world-task Location and a web capture without a world are refused instead of landing in a world named
  "world". Status of every row: [multiworld follow-ups](architecture/multiworld-follow-ups.md).

## 2026-10-11

- **Editing a domain's Location in its child form no longer blocks the domain form**
  ([KNG-130](https://linear.app/kngpandi/issue/KNG-130); knk-web-api `master` `917537a`,
  knk-web-app `main` `38854ba`). Renaming a Town's Location from the Town form made the Location boundary check fail
  ("outside the boundaries") and the Town form could not be submitted. The child form returned the Location's id as
  text, which the API could not read; the check never reached the region. Not caused by the multiworld work
  (KNG-111). The API now reads a text id, the web app keeps the id a number, and a Location value the check cannot
  read now says so instead of "outside the boundaries". Unit-tested; accepted and merged by the developer.
- **Recapturing a point of an existing gate door checks the gate's region again**
  ([KNG-131](https://linear.app/kngpandi/issue/KNG-131); knk-web-app `main` `38854ba`,
  knk-plugin `main` `1b3e06c2`). Capturing a Location in game for an existing GateDoor (e.g. its reference point)
  failed with "Location {coordinates} is outside {parentEntityName}'s boundaries" even inside the gate's region: the
  plugin got the gate's id instead of the gate, and looked for a region named "21". The web app now sends the saved
  gate. When the plugin can't find a region it now says so and follows the rule's blocking setting, and the
  coordinates and parent name are always filled in. Not caused by the multiworld work. Unit-tested; accepted and
  merged by the developer.
- **API background services log a database outage once** (KNG-115 live-test follow-up; knk-web-api `master`
  `f409271`). With MySQL stopped, the rank expiry sweep, the currency monitor and the location retention scheduler
  printed a full `MySqlException` stack trace on every iteration. They now log one short warning when the database
  becomes unreachable and one line when it is back. Other errors are still logged in full every time. See
  [architecture](architecture/api-connectivity.md#api-background-services-during-a-database-outage). Unit-tested;
  not yet checked against a stopped MySQL.
- **Dying resets combat and freezes** (knk-plugin `main` `c0ad2a9b`; trunk follow-up found in the
  [KNG-34 smoke test](guides/player-statistics-smoke-test.md), findings 6 and 7). After dying, a player can teleport
  again straight away: death clears their teleport combat tag (the killer stays tagged). A player frozen by the
  Freeze enchantment can move again after respawning, and HealthBoost's heal-over-time stops when the player dies.
  The other enchantment effects are potion effects, which death already clears. Unit-tested; not yet checked in game.
- **New players get the first-join kits** ([KNG-81](https://linear.app/kngpandi/issue/KNG-81), plugin half; knk-plugin
  `main` `0ee516aa`). A player the server has never seen now receives every kit marked "Grant on first join" a moment
  after joining, exactly once. A relog grants nothing more, and an existing account never gets them. Three causes,
  all fixed: `KnKPlugin` built two caches, and the join listener read the one that never held the new account; the
  account created at pre-login was not marked as new; and the plugin misread the API's create response
  (`{user, linkCode}`), so creating the account failed before it was cached. That last one was already broken
  before. Live-tested 2026-10-11.
- **API connectivity: one up/down view of the API** ([KNG-115](https://linear.app/kngpandi/issue/KNG-115)): live-tested
  by the developer and merged. knk-web-api `master` `17ee730`, knk-plugin `main` `b5eee6e`.
  - The API's `GET /health/ready` now checks MySQL: 503 `unhealthy` when the database is down (never a 500), 200
    otherwise. A database outage is logged once when it starts and once when it ends.
  - The plugin probes `/health/ready` at the API root every 10 s (5 s timeout, never cached). It keeps one state:
    DOWN after 3 failed probes, UP after 2 passing ones. Each change fires `ApiConnectivityChangedEvent` on the main
    thread and is logged. `/knk health` shows the state, how long it has held and the last probe. Settings:
    `config.yml` → `api.connectivity`.
  - Nothing reacts to the event yet; offline security (KNG-58), hub outage actions (KNG-109/114) and Siege
    containment (KNG-117) will subscribe. See [architecture](architecture/api-connectivity.md).
- Players in owner mode or staff mode no longer show in the multiplayer server list ([KNG-127](https://linear.app/kngpandi/issue/KNG-127);
  knk-plugin `main` `ac2855a`). They were already hidden in game and in the tab list; the server list still counted them
  and showed their names when hovering over the player count. Now they are left out of both, and the Game Settings MOTD's
  `{online}` shows the same lowered count. The list has no viewer, so they are hidden there from staff too. Not yet
  checked in game.
- **Player statistics, leaderboards, owner diagnostics, GDPR deletion and world analytics** ([KNG-34](https://linear.app/kngpandi/issue/KNG-34),
  with [KNG-14](https://linear.app/kngpandi/issue/KNG-14)): merged after a live smoke test of all 27 steps
  ([guide and findings](guides/player-statistics-smoke-test.md)). knk-web-api `master` `34b8f9b`, knk-plugin `main`
  `aa5df70a`, knk-web-app `main` `5f40f93`. Six migrations (`AddPlayerStatistics` … `SeedStatisticsStaffNodes`).
  - **Statistics:** logins, active and AFK time (`/afk`, auto-AFK with an `[AFK]` tab marker in the group color), distance
    on foot, flying and in vehicles (mounts included), highest fall, PvP/PvE kills, deaths, damage, killstreaks, Siege
    results, coins/gems/XP earned and spent from the ledger (all past activity imported), title history, discoveries.
    Spooled to disk while the API is down.
  - **Privacy:** every statistic has its own visibility (Nobody by default, Friends, Everyone), set in game
    (`/stats settings`, a clearer group menu) or on `/account`, with a preview before group changes and a check for
    changes made elsewhere meanwhile.
  - **Read surfaces:** Profile → Statistics, `/stats [player]`, `/leaderboard` (`/lb <board> [period]` opens the board
    menu), web `/account`, `/players/<name>`, `/leaderboards` and a staff panel. Boards rank only statistics shown to
    everyone, cap repeat kills of the same victim at 3 a day, and support owner exclusions.
  - **Owner tools:** `/owner/telemetry` (diagnostic events, test runs, enhanced mode, player timeline), `/owner/privacy`
    (GDPR deletion: player requests with an email link, staff requests, 5-day grace period, erasure),
    `/owner/analytics` (movement heatmaps, menu funnels including Escape closes, domain entries/exits). Owner nodes
    `knk.owner.*`; wildcards unlock only analytics and leaderboard exclusions (D24). Moderators and Admins get
    `knk.admin.statistics.view`, Admins also `knk.admin.privacy.request`.
  - Kill switches in the plugin and API config. Follow-ups: [KNG-125](https://linear.app/kngpandi/issue/KNG-125)
    (menu item blinker), [KNG-126](https://linear.app/kngpandi/issue/KNG-126) (Reverse button feedback, trunk).

## 2026-10-10

- Gate teleports land somewhere safe, and gate doors no longer hurt players ([KNG-105](https://linear.app/kngpandi/issue/KNG-105),
  [KNG-106](https://linear.app/kngpandi/issue/KNG-106); knk-plugin `main` `8457657`). `/gatedoor tp` puts you on the
  ground next to the door, in front of or behind it, never inside its blocks or its opening, and refuses when there is
  no safe spot within 4 blocks. `/gate tp` uses the gate's spawn point (its Location) when set, else a safe spot by its
  first door, and says which. A closing or opening door (including a drawbridge's swing) now moves players, mobs,
  dropped items and vehicles with their riders out of its way before its blocks land, to solid ground on their own
  side when there is room; before, the collision check looked the wrong way while a door closed, and the push sent
  people behind a door through it. Anyone found inside door blocks (after a teleport, on join) is moved out, and door
  blocks cause no suffocation damage (`gates.safety.door-suffocation-damage: false`). Live-tested 2026-10-10.
- The first-join kit grant now runs once per player ([KNG-81](https://linear.app/kngpandi/issue/KNG-81), API half;
  knk-web-api `master` `d5293fd`, migration `AddUserFirstJoinKitsGrantedAt`). A repeated or simultaneous
  grant-first-join call (a quick relog) no longer adds a second kit claim or second lootbox tokens; players already
  holding a first-join kit are marked as granted. Live-tested against the API 2026-10-10. The game server does not
  trigger the grant yet: the plugin half (one `CacheManager` in `KnKPlugin`) is still open.
- Walk paths get through tall buildings ([KNG-108](https://linear.app/kngpandi/issue/KNG-108); knk-plugin `main`
  `a388c70`). A walk path may now be 5 blocks longer for every block of height between the player and where they are
  going, so the way down a tower's spiral stair (the Keep Tower Roof: 168 blocks for 29 of height) is found. From
  such a roof the player gets the full path to the road instead of "Having trouble determining the route - guiding
  you to the nearest road.", and a destination on a roof gets a full path up. Setting:
  `navigation.walk.climb-allowance` (5; 0 = as before). A server `config.yml` needs no change. Known gap, not new: a
  player shut in within 8 blocks of a road is not told so ([KNG-124](https://linear.app/kngpandi/issue/KNG-124)).
- The game server now knows the domain of every region it preloads ([KNG-122](https://linear.app/kngpandi/issue/KNG-122);
  knk-plugin `main` `68022ce3`). The API answers a region lookup with at most one town, district and structure, so
  preloading several districts at once (when the road network loads, after `/knk cache refresh`, or for the regions at
  a spot) kept only one of them. The others were looked up later, one at a time, blocking routes for up to 3 seconds,
  and an overlapping second district could go unnoticed. The server now asks about each region on its own, a few at a
  time. The API and the web app are unchanged.
- A required yes/no (Boolean) field left unticked no longer blocks **Next** in FormWizard forms
  ([KNG-53](https://linear.app/kngpandi/issue/KNG-53); knk-web-app `main` `955fa20`). The KNG-26 fix only covered a
  brand-new form; resumed drafts saved before it and edit forms whose record had no value still held an empty value
  behind the unticked box. Every way a form is filled in now treats an unticked box as `false`. Also fixed: a saved
  `false` in a child/join form (e.g. a siege gate's Damageable) showed ticked when the field's default is on.
  Live-tested 2026-10-10.
- Domain forms accept an empty nullable field again ([KNG-119](https://linear.app/kngpandi/issue/KNG-119); knk-web-api
  `master` `a9e68f0` with migration `ClearPlaceholderFormFieldDefaults`). Editing a Town, District, Structure or
  GateStructure with **Road Access Override** (or Navigation Default Override, or another optional number, yes/no
  or choice field) left empty failed: entity metadata gave such fields the made-up default value "default", the
  Form Builder saved it on the field, and the form submitted it for the empty value. Metadata now reports no default
  for them, and the migration removes the saved "default" from existing form fields (text fields are left alone).
  An empty override follows the domain type again. The web app is unchanged.
- Navigation takes a road that a no-entry region covers only in part ([KNG-110](https://linear.app/kngpandi/issue/KNG-110),
  finding P4; knk-plugin `main` `4b9ddca4`). A region now blocks a road only where it covers the road's whole width:
  one free block beside it is enough, and the trail moves onto the free part, so the region's border does not push
  the player back. A region over the whole width blocks as before; for a player who may not leave a region, a stretch
  whose middle is in it still counts as inside. New: a region a player may enter but not leave blocks the way to a
  destination outside it ("You could not leave X again"), so navigation no longer leads players into it on the way
  somewhere else; a destination inside it is still reached. `/knk road status` counts the road pieces with such gaps.
  No new settings; the API and the web app are unchanged.
- Game Settings are applied in game ([KNG-52](https://linear.app/kngpandi/issue/KNG-52); knk-web-api `master`
  `8cce48d` with migration `AddGameSettingsMotdAndGroupOverrides`, knk-plugin `main` `973aa68b`, knk-web-app `main`
  `12c1d60`).
  - **What the page controls:**
    - the join and leave messages (`{player}`, `{group}`, `{title}`);
    - where regular players arrive on join (also the `/spawn` destination);
    - the server-list MOTD;
    - per world: the default game mode on join, a time lock, the weather rule (Normal, Constant, Blocked,
      Weighted) and the spawn point.
  - **Respawn per world:** synced with the join spawn, the world spawn (beds and anchors ignored), the server's
    choice (beds count), a chosen spot or the nearest town.
  - **Permission groups** can override the join and leave message, the spawn (a chosen spot, or "where they
    logged out" like owners) and the respawn. A player's groups count in the teleport-fee order (highest Weight
    first, each followed by its parents).
  - **Behaviour changes:**
    - **The hard-coded "respawn in town 4" is gone.** Respawn follows the page; choose Town 4 there to keep it.
    - Saving the page now needs `knk.admin.config`.
    - A staff `/weather` in a world with a weather rule asks for confirmation first.
    - The plugin keeps working from `plugins/KnightsAndKings/game-settings-cache.json` while the API is down.
  - **Spawn picker:** redesigned (a card for the chosen spot, a grouped searchable list with type chips). It now
    lists Structures, which were missing because the web app called a Locations route that doesn't exist.

- Navigation reaches destinations further off-road ([KNG-75](https://linear.app/kngpandi/issue/KNG-75) step 2;
  knk-plugin `main` `8f2b7c30`). A destination may now be up to 256 blocks from a road (was 48). Within 96 blocks of
  where the road ends, the last stretch is a walk path; further out, the player is told "No conventional path to X
  found." and the HUD arrow and distance point the way until they are within 96 blocks, when a walk path takes over.
  Walk paths may now be up to 144 blocks long (was 96), and walks of up to 96 blocks, also to the road at the start,
  no longer fall back to a straight line for lack of captured terrain. Settings: `navigation.max-destination-distance`,
  `navigation.destination-walk-range`, `navigation.walk.max-length` (a server `config.yml` that spells out
  `max-length: 96` keeps the old cap - change it to 144). With walk paths off, nothing changes. KNG-75 is complete;
  follow-ups [KNG-108](https://linear.app/kngpandi/issue/KNG-108) (tall buildings) and KNG-36 (longer walks).

## 2026-10-09

- A navigating player off the road gets a walk path to it ([KNG-75](https://linear.app/kngpandi/issue/KNG-75) step 1;
  knk-plugin `main` `c4141f90`). The trail shows the way to where the route starts (stairs, ladders, doors the
  player may open) instead of a straight line, and the road guidance starts once the player reaches the road; no
  "You left the road" on the way there. The player may now start up to 96 blocks from a road (was 48), measured in
  plain 3D, so a tower roof above a road works; height still decides which road (a bridge over a road). Shut in:
  "No conventional path to the road found."; a way too long to work out (a tall spiral stair): "Having trouble
  determining the route - guiding you to the nearest road." with the part of the path found. Setting:
  `navigation.max-start-distance`. With walk paths off, nothing changes. Follow-up for tall buildings:
  [KNG-108](https://linear.app/kngpandi/issue/KNG-108).
- Location retention is merged ([KNG-80](https://linear.app/kngpandi/issue/KNG-80); knk-web-api `master` `c397585`,
  knk-web-app `main` `d10e3dd`, knk-plugin `main` `68a5310`). A weekly check (Sunday 04:00 server time, configurable,
  plus "Run check now") flags Locations that still have the default name and that nothing uses, read from the database
  model rather than a hand-kept list, after a 7-day grace period. Staff review them under Player moderation → Orphaned
  Locations and keep or delete each one; nothing is deleted automatically, and a delete re-checks first. Kept Locations
  come back after 6 months or when they change. Online staff get one digest per run with something new;
  `/knk location orphans` and `/knk location tp <id>` work in game. New Moderator and Admin permission groups carry the
  new `knk.admin.location.*` nodes. Live-tested 2026-10-09
  ([smoke test](guides/location-retention-smoke-test.md), findings F1-F3 fixed). Follow-up: KNG-107.
- Gate commands get two layers ([KNG-77](https://linear.app/kngpandi/issue/KNG-77),
  [KNG-78](https://linear.app/kngpandi/issue/KNG-78), [KNG-79](https://linear.app/kngpandi/issue/KNG-79);
  knk-plugin `main` `5b1cc8b`, knk-web-api `master` `6192af0`):
  - `/gate` (`/knk gate`) acts on a whole gate and all its doors; `/gatedoor` (`/knk gatedoor`) acts on one door.
  - Both have open, close and **toggle**.
  - `here` picks the gate or door within 15 blocks, with a clickable choice when several are in range.
  - With no target, open, close, toggle, info and repair use the gate you are looking at, including an open one.
  - Per-id permissions now mean structure ids (`knk.gate.*`); door nodes are `knk.gatedoor.*`.
  - "here" is a reserved gate and door name.
  - See [architecture/gate-commands.md](architecture/gate-commands.md).
- The web app's entity navigator (left sidebar on the Dashboard and Forms pages) can be searched (display name or
  internal name) and sorted A–Z/Z–A ([KNG-61](https://linear.app/kngpandi/issue/KNG-61); knk-web-app `main`
  `ce47817`). On the Dashboard, types with a published default display configuration are listed under "Entities".
  The rest are in a collapsed "Without display configuration" group, and the Dashboard opens on the first
  "Entities" type. The sort direction and the group's open/closed state are remembered per page. Narrow-screen
  layout: [KNG-94](https://linear.app/kngpandi/issue/KNG-94).
- A navigation destination high above a road is no longer "too far from any road"
  ([KNG-75](https://linear.app/kngpandi/issue/KNG-75), finding N15; knk-plugin `main` `9f466a9f`). Destinations
  are measured to the nearest road in plain 3D; the player's own position still counts height ×4, so a player on
  a bridge keeps snapping to the bridge. A tower roof 28 blocks above a road is reached by road, then a walk path up.
  Setting: `navigation.destination-snap-vertical-weight` (default 1).
- Resetting a player's discovery on their moderation profile now asks in the app's own dialog instead of the
  browser's `confirm` ([KNG-40](https://linear.app/kngpandi/issue/KNG-40); knk-web-app `main` `6d23238`). After
  the reset the row leaves the list at once and a green line confirms it. The other `window.confirm` prompts are
  [KNG-82](https://linear.app/kngpandi/issue/KNG-82).
- Domain access refusals are also said in chat ([KNG-74](https://linear.app/kngpandi/issue/KNG-74); knk-plugin
  `main` `fd869aa`). The first "You are not allowed to enter/leave X." of a refusal episode goes to chat as well as
  the action bar. An episode is the first refusal after 10 s without one, or a different refusal. The `/navigate`
  arrow keeps off the action bar for about 3 s after a refusal, so the message can be read. Settings:
  `regions.access.chat-quiet-period-ms` and `action-bar-hold-ms`.
- Road navigation fixes from the live test, merged to knk-plugin `main`
  ([KNG-27](https://linear.app/kngpandi/issue/KNG-27), [KNG-51](https://linear.app/kngpandi/issue/KNG-51)):
  - a gate closing behind the player no longer blocks the route; the route is judged by the part of each road still
    ahead;
  - a nearby destination the walk path cannot reach is tried by road ("following the roads instead");
  - a destination on the open side of a closed gate is reached;
  - with no open route, the player is guided as close to the destination as the open roads go.

## 2026-10-08

- Road navigation is merged ([KNG-27](https://linear.app/kngpandi/issue/KNG-27); knk-plugin `main` `f9026cb`,
  knk-web-api `master` `4c570fa`, knk-web-app `main` `b51eba0`). The road graph is built per tile from the world's
  road materials, with curated tiles that only propose changes after their first build, admin tools (`/knk road …`) and
  a web-app road admin page. `/navigate` (`/nav`) guides players along the roads with a particle trail and a HUD to a
  Location, Town, District, Structure (gates included, also as `gate:`), street or named road node. It respects gate
  state, pass-through rights, domain entry/exit rules and sieges, and re-routes on live changes. Design:
  [navigation](specs/navigation/DESIGN.md).
- Walkable last-mile paths ([KNG-51](https://linear.app/kngpandi/issue/KNG-51)): near a target, and after the road
  ends, the trail follows a path a player can walk (stairs, ladders, doors they may open, no regions they may not
  enter) instead of a straight line. Without one it says "No conventional path to X found."
  ([last-mile design](specs/navigation/LAST_MILE_PATHFINDING.md)).
- Live-tested on the dev server 2026-10-07/08 ([smoke-test guide](guides/road-navigation-smoke-test.md), findings
  N1-N12). Still open: the siege check (C6). Follow-ups: KNG-73, KNG-74, KNG-75, KNG-76.

## 2026-10-06

- PermissionGrant forms can now search for and pick a holder (a user or a permission group) in the web app: the web-app half of the PermissionHolder lookup is merged ([KNG-38](https://linear.app/kngpandi/issue/KNG-38), knk-web-app `main` `24b60ac`), completing the API half from 2026-10-04.

## 2026-10-05

- The lootbox opening reel's passing items now carry real enchantments ([KNG-54](https://linear.app/kngpandi/issue/KNG-54)), rolled from the box's own enchant rolls and shown with the grade the box gives them, so the winner is no longer the only enchanted item on the reel ([lootboxes design §3.9](specs/lootboxes/DESIGN.md)).
- Blueprint item descriptions without a colour of their own now render dark gray instead of vanilla purple lore (this fixes Flaming Samurai).
- Every route that spawns an item from a blueprint (lootbox delivery and reel, kits, `/knk itemblueprints give`) now builds it through one `BlueprintItemAssembler` entry point, and `/ce add` shares the custom-enchantment lore pipeline with `/ce remove`; see the [item render pipeline](architecture/item-render-pipeline.md). knk-plugin `main` `74607a9`.
- Fixed `/ce remove` leaving a stray blank line at the top of an item's lore after removing its last custom enchantment; removal now shares the same lore re-compose as applying one (knk-plugin `main` `e55e87f`).

## 2026-10-04

- Held a lootbox opening-reel item that comes up while the player is in a siege until their own inventory is restored, instead of losing it with the siege inventory ([KNG-44](https://linear.app/kngpandi/issue/KNG-44), [plan](specs/lootboxes/IMPLEMENTATION_PLAN.md)).
- Replaced the lootbox admin Types tab's ~14 per-type odds requests with one staff-only batch endpoint, `GET api/LootboxTypes/odds` ([KNG-45](https://linear.app/kngpandi/issue/KNG-45), [plan](specs/lootboxes/IMPLEMENTATION_PLAN.md)).
- Completed the plugin command-completion sweep with permission-filtered subcommands, vanish-aware player names, cached offline names where supported, fixed-value suggestions and explicit suppression of Bukkit's fallback suggestions ([KNG-30](https://linear.app/kngpandi/issue/KNG-30)).
- Fixed non-op staff access to `/freeze`, `/unfreeze`, `/staffchat` and `/knk` through the in-house permission model, and corrected the `/minecraft:tell`/`w` secure-chat mismatch ([KNG-24](https://linear.app/kngpandi/issue/KNG-24), [KNG-25](https://linear.app/kngpandi/issue/KNG-25)).
- Ensured siege members enter matches in survival so spawn-safe-zone damage denial is observable, and completed stable item-lore section spacing plus coherent lootbox special-description coloring ([KNG-28](https://linear.app/kngpandi/issue/KNG-28), [KNG-29](https://linear.app/kngpandi/issue/KNG-29)).
- Corrected untouched PermissionGroup premium-tier fields to submit `false` rather than `null` ([KNG-26](https://linear.app/kngpandi/issue/KNG-26)).
- Added the API half of the polymorphic PermissionHolder lookup used by PermissionGrant forms ([KNG-38](https://linear.app/kngpandi/issue/KNG-38)); its web-app half remains on the feature branch and is not yet part of the default-branch UI.

## 2026-10-02

- Added the maintained V1 → V2 → V3 [feature register](FEATURE_REGISTER.md), documented feature and guide updates at merge, and established this changelog ([KNG-33](https://linear.app/kngpandi/issue/KNG-33), [PR #5](https://github.com/PandiO/knk-workspace/pull/5)).

## 2026-09-29 — Backfilled from documented trunk merges

- Added managed WorldGuard-region ownership, priority and category-flag policy with idempotent startup repair. The live in-game smoke test remains tracked by [KNG-46](https://linear.app/kngpandi/issue/KNG-46) ([architecture](architecture/managed-worldguard-regions.md)).
- Modernized the shared AI-agent workflow and portable repository entrypoints ([KNG-32](https://linear.app/kngpandi/issue/KNG-32)).

## 2026-09-28 — Backfilled from documented trunk merges

- Completed the teleport feature merge, including requests, spawn/warps and ignore integration ([KNG-17](https://linear.app/kngpandi/issue/KNG-17), [design](specs/teleport/DESIGN.md)). Housing-linked `/home` remains separate scope.

## 2026-09-27 — Backfilled from documented trunk merges

- Added a permanent coin/gem transaction ledger and secure player payments, balance commands and administration ([KNG-21](https://linear.app/kngpandi/issue/KNG-21), [design](specs/currency-payments/DESIGN.md)).
- Added first-entry Town, District and Structure discoveries, rewards and a Discoveries menu ([KNG-20](https://linear.app/kngpandi/issue/KNG-20), [plan](specs/domain-discovery/IMPLEMENTATION_PLAN.md)).
- Expanded private messages with ignore, social-spy controls and moderation history ([KNG-18](https://linear.app/kngpandi/issue/KNG-18)). Its secure-chat follow-up was later completed in [KNG-25](https://linear.app/kngpandi/issue/KNG-25).
- Added world lootboxes, token pickups and an opening reel ([KNG-19](https://linear.app/kngpandi/issue/KNG-19)). The second live retest and remaining decisions are tracked in [KNG-31](https://linear.app/kngpandi/issue/KNG-31).

## 2026-09-26 — Backfilled from documented trunk merges

- Merged the Siege MVP: configurable scenarios, teams, objectives, live matches and player menus, following two live smoke-test rounds. Scheduled lobbies are later scope ([siege plan](specs/siege-minigame/IMPLEMENTATION_PLAN.md)).
- Added title and premium-tier display in game chat/tab list ([KNG-7](https://linear.app/kngpandi/issue/KNG-7), [KNG-8](https://linear.app/kngpandi/issue/KNG-8)).
- Ported general enchantment books and grade-based application limits ([KNG-5](https://linear.app/kngpandi/issue/KNG-5), [KNG-6](https://linear.app/kngpandi/issue/KNG-6)).
- Corrected hourly title salary and join-time payouts ([KNG-16](https://linear.app/kngpandi/issue/KNG-16)).

## 2026-09-25 — Backfilled from documented trunk merges

- Merged the persisted kit system, grant commands and kit authoring workflow. First-join grant remained to be confirmed live in the [kit plan](specs/kits/IMPLEMENTATION_PLAN.md).

For older implementation detail, consult [feature plans](specs/README.md), [dated reports](reports/) and the repository histories. Do not interpret the first date of a branch or issue as a release date.
