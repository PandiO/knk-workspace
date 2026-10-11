# Closed alpha hardening (KNG-64) — smoke test

**Status:** Ready to run — branches merged with trunk 2026-10-11, not yet live-tested by the developer
**Last updated:** 2026-10-11
**Plan:** [specs/alpha-hardening/IMPLEMENTATION_PLAN.md](../specs/alpha-hardening/IMPLEMENTATION_PLAN.md) ·
**Automated run:** [reports/2026-10-08-alpha-hardening-verification.md](../reports/2026-10-08-alpha-hardening-verification.md) ·
**Linear:** [KNG-64](https://linear.app/kngpandi/issue/KNG-64) (KNG-65..71)

Run on the dev server with `claude/ui-ux-assessment-discussion-66vc2l` checked out in knk-web-api, knk-web-app,
knk-plugin and knk-workspace (each merged with its trunk on 2026-10-11). You need three accounts besides your
owner account (`*`):

- **Player:** a Minecraft alt **without** a web account yet (for registration), non-op.
- **Moderator:** a web account with only `knk.admin.user.manage`, `knk.admin.user.perm` and `knk.admin.user.group`.
- **Content staff:** a web account with `knk.admin.content` but **not** `knk.admin.world`.

Use a non-op alt for every in-game step: ops pass every in-game check. Record each step in **Findings** at the end.

## 0. Setup

1. **Back up the dev database.** The migration ends every existing session once.
2. **API secrets** (knk-web-api `CLAUDE.md`, "Dev secrets"): `appsettings*.json` no longer hold secrets. Rotate the
   dev DB password (it was committed before KNG-64), then from the knk-web-api root:
   `dotnet user-secrets set` for `ConnectionStrings:MySqlDbConnection`, `Security:Jwt:Secret`
   (`openssl rand -base64 48`), `Security:PluginApiKey` (`openssl rand -hex 32`) and, only with SMTP,
   `Email:SmtpPassword`. Keep `Email:Provider` = `Log`: reset and notice mails go to the API log.
3. **API:** `dotnet build knkwebapi_v2.csproj`, `dotnet ef database update` (applies
   `AddRefreshTokensAndTokenVersion` plus any trunk migrations you don't have yet), start the API.
   Expected: no "PluginApiKey is not set" warning; no "generated a temporary JWT secret" warning (you set one).
4. **Plugin:** `./gradlew build -x deployToDevServer`, then `./gradlew :knk-paper:dev`. Your existing `config.yml`
   keeps its old values, so add by hand: `api.auth.type: apikey`, `api.auth.api-key: <the same key>`,
   `api.allow-untrusted-ssl: false`, `region-http.bind-address: "127.0.0.1"` (the Paper host's LAN IP if the API runs on
   another machine), `region-http.port: 8081`, `web.public-url: "http://localhost:3000"`. Start the server.
5. **Web app:** `npm install`, `npm start` (API URL defaults to `http://localhost:5294/api`; set
   `REACT_APP_MC_SERVER_ADDRESS` to see your server address on the landing page).
6. **Grants:** give the Content staff account `knk.admin.content`; give your Admin role group `knk.admin.*` (or
   `knk.admin.content` + `knk.admin.world`). Owners with `*` / `knk.*` need nothing.

## 1. Automated security probe

7. From knk-workspace: `scripts/security/alpha-probe.sh http://localhost:5294 --player '<player login>:<password>'`
   with a throwaway **non-staff** web account (it logs that account out everywhere). Expected: `ALL CHECKS PASSED`
   (29 checks). The last check trips the login rate limiter for about a minute.

## 2. Plugin and API wiring

8. Server log: `RegionHttpServer listening on 127.0.0.1:8081 (X-API-Key required)`. `/knk health`: API connectivity UP.
9. `curl -i http://127.0.0.1:8081/api/regions/x` → **401**; with `-H "X-API-Key: <key>"` → not 401.
10. Region callbacks still work: as owner, edit a District or Town with a WorldGuard region in the web FormWizard (a
    region field that checks feasibility) → saves without errors; rename a region → the plugin log shows the call.
11. Join with the Player alt → its account is created (web `/admin/users`). Statistics and telemetry still flow
    (`/stats` shows data, the API log has no 401/403 for plugin calls).
12. After step 13, search the server log and the API log for the link code: it must not appear anywhere.

## 3. Registration and login (players)

13. In game as the Player alt: `/account link` → a code plus "register at `http://localhost:3000/auth/register`".
14. Web `/auth/register` → enter the code → "This code belongs to **<alt name>**" → choose email + password → you land
    logged in on `/account`. There is no username field.
15. Register again with the same code → refused at the code step ("This code is invalid or has expired …"). `/account link <code>` in game → explains that codes
    are entered on the website (it doesn't claim the accounts were linked).
16. Log out. Log in with the **Minecraft name**, then with the **email**: both work. "Remember me" is **unchecked** by
    default; without it, closing the browser ends the session; with it, the session survives a browser restart.
17. Wrong password 5× for one account → the 6th attempt says "Too many attempts. Try again in 15 minutes" (an unknown
    name gives the same "invalid" error as a wrong password, never "user not found").
18. Forgot password → the reset link is in the API log → set a new password → "Password reset successful" → log in
    with it. Another browser that was logged in as that account lands on the login page on its next action.

## 4. Sessions

19. Log in in two browsers. Account → **Log out on all devices** → the other browser lands on the login page with
    "Your session expired. Log in again to continue" on its next click.
20. Change the email (needs the current password) → the old address gets a notice (API log); this tab stays logged in.
21. (Optional, slow) Stay logged in > 30 minutes, then click around → no logout (the access token refreshes silently).
22. Logged in, stop the API and reload (the page can't load your account, which is expected), start the API again
    and reload → you're still logged in (an outage no longer ends the session).
23. Logged out, open `/account/transactions` → login → you're back on `/account/transactions`.

## 5. Roles and web access

24. As the Player: the nav has no Dashboard/Forms/admin links; `/dashboard`, `/forms`, `/admin/game-settings` show
    "Staff only".
25. As Content staff: Dashboard and Forms work; creating/editing a content entity (e.g. an item blueprint or a menu)
    works; saving a **world** entity (Domain, Town, Street, Location) shows a 403 error.
26. As owner: Dashboard, Forms, Game Settings (save a change and revert it), Roads, Diagnostics etc. all work.
27. As Moderator (`/admin/users`): grant yourself any node → refused; grant another user `*` or a node you don't hold →
    refused; assign the Staff group to someone → refused; detach a group from a parent group that holds nodes you
    don't have → refused. Granting a node you do hold to someone else → works.
28. Signed out: `/leaderboards` and `/players/<name>` work (public, viewer-filtered); signed in as the Player,
    `/account` shows Statistics and "Delete my data".

## 6. Landing and alpha UX

29. Landing (desktop and phone): title "Knights & Kings", favicon, server address with a working **Copy** button,
    "How to join" in 3 steps, readable white headings, slideshow behind the content.
30. Phone: tap the account icon → the menu opens → **Log out** works. An unknown URL shows the 404 page.
31. Browser console during login and registration: no password, token or email logged.

## 7. Seed export (knk-workspace)

32. `scripts/seed/export-seed.sh --defaults-file <reader.cnf> --database knightsandkings_dev_v2 --with-world --out seed/test`
    → "Seed written … world tables: yes" (no "Unclassified tables").
33. Import into a **fresh, migrated** throwaway DB with `import-seed.sh` → success line; the road graph and navigation
    defaults are there, `users` is empty. Edit `manifest.txt` to a wrong row count and import into another fresh DB →
    "row count mismatch", "import rolled back", the DB stays empty.

## Findings

| Step | Result | Notes |
|---|---|---|
| | | |
