# Link code format and in-game registration confirmation — smoke test checklist

**Status:** Written 2026-11-14 for #484 and #485; in review on `claude/smoke-fixes-484-485-487` (knk-web-api and
knk-plugin, PRs into `next`); automated in CI; manual steps not run (the plugin's message choice and join drain are
unit tests; the chat in game waits for simulated players, [#540](https://github.com/PandiO/knk-workspace/issues/540))
**Last updated:** 2026-11-14 (steps marked `[automated]` where a knk-plugin test covers them, plugin backfill
[#511](https://github.com/PandiO/knk-workspace/issues/511)); 2026-11-14
**Issues:** [PandiO/knk-workspace#484](https://github.com/PandiO/knk-workspace/issues/484) (link code `XXXX-XXXX`),
[PandiO/knk-workspace#485](https://github.com/PandiO/knk-workspace/issues/485) (confirmation in game)
**Related:** [plugin configuration § 4.18](admin/plugin-configuration.md#418-messages) (`messages.web-account-registered`),
[invitations smoke test](invitations-smoke-test.md) (claim codes and the admission gate),
[realtime smoke test](realtime-smoke-test.md)

What changed: the link code from `/account link` reads `XXXX-XXXX` in game, like the claim code and the web app's code
field (it read `XXX-XXXXX`). After a player registers on the website with that code (game-first registration), the game
tells them once that their website account is ready and linked: within seconds when online, a couple of seconds after
their next join when offline. A link code entered on the Account page shows the existing `admission.account-linked`
notice the same way. Write down any step that fails, with the server and API log lines.

## 0. Setup

1. Deploy the API and the plugin from `claude/smoke-fixes-484-485-487` (or `next` once merged; both). No migration and
   no API setting.
2. Plugin `config.yml`: `web.public-url` set (e.g. `https://dev.knightsandkings.net`). The new key
   `messages.web-account-registered` may stay out: the jar's default is used. To see your own text, paste it under
   `messages:` (YAML in the changelog's Admin steps) and restart.
3. A Minecraft account without a web login (a fresh alt, or one whose web login you delete on the dev database), with
   admission mode `whitelist` or `open`, or an admitted account in `invite` mode.
4. Note `realtime.enabled` (sections 2 and 3 are run with it on and off).

## 1. The link code reads XXXX-XXXX (#484)

1. In game `/account link`. Expected: `Your link code is ABCD-EFGH` with the dash after **four** characters (it was after
   three: `7KL-MZU0T`).
2. Click the code line (copies it). On the website `/auth/register`, paste it into the code field. Expected: the field
   shows the same `XXXX-XXXX`, and the code is accepted.
3. Type the same code without the dash, in lower case, or with a space instead of the dash: the field shows
   `XXXX-XXXX` each time. (An older code shown as `XXX-XXXXX` and pasted still works: the field drops the dash.)

## 2. Game-first registration, player online (#485)

0. [automated] An `AccountLinked` notice with `via` = `register` shows `messages.web-account-registered` (masked
   address, the login line with `web.public-url`, left out without one; the template is configurable and ships in the
   bundled config): knk-plugin `AccountLinkedNotifierTest` (`aGameFirstRegistrationShowsTheRegisteredMessage`,
   `withoutAPublicUrlTheLoginLineIsLeftOut`, `theRegisteredTemplateIsConfigurable`,
   `theBundledConfigShipsTheDefaultRegisteredMessage`). Manual (steps 1–5): the push or poll reaching a real player and
   the chat in a real client (#540).

1. Stay in game. On the website register with the code from § 1, an email and a password.
2. Expected within a few seconds, once, in chat:
   `Your website account is ready and linked to this Minecraft account.`,
   `Log in at <web.public-url> with jo***@example.com or your Minecraft name <name>.` (your address masked),
   `Not you? Tell staff right away.`
3. Log out of the website and log in with the Minecraft name and the password: it works.
4. Rejoin the server: the message does not come again.
5. Repeat §§ 1–2 with `realtime.enabled` the other way (a new account, or reset the web login). With realtime off the
   message comes from the 2 s notification poll; with it on, from the push.

## 3. Game-first registration, player offline (#485)

0. [automated] A join while the hub is connected schedules one notification drain; while it is down the poll covers
   it: knk-plugin `NotificationJoinDrainTest`. Manual (steps 1–4): a real join (#540).

1. In game `/account link`, note the code, log out of the server.
2. Register on the website with it.
3. Join the server. Expected: the three lines from § 2 about two seconds after the join messages, once.
4. Run this with realtime **on** too: before this change, a notice for an offline player waited for the next hub
   reconnect while the hub was connected; now a join drains it (`NotificationJoinDrain`).

## 4. Link on the Account page (#485)

0. [automated] A link on the Account page or a claim keeps the `admission.account-linked` notice, not the registration
   text: knk-plugin `AccountLinkedNotifierTest.aLinkOnTheAccountPageOrAClaimKeepsTheAdmissionMessage`,
   `showsTheMaskedAddressAndTheWarning`. Manual (steps 1–3): the link in the web app and the chat in game (#540).

1. A web-only account (registered with an invite, no Minecraft account), logged in on the website.
2. A Minecraft account without a web login runs `/account link`; enter that code on the website's Account page (link
   Minecraft account).
3. Expected in game, online or on the next join: the existing notice
   `Your Minecraft account is now linked to the web account jo***@example.com.` / `Not you? Tell staff right away.`
   (`admission.account-linked`), not the registration text.

## 5. No message when it fails (#485)

1. `/account link`, then on the website register with a wrong code (change one character): refused, nothing in game.
2. Wait until the code has expired (`Security:LinkCodeExpirationMinutes`, default 20; or set it to 1 on the dev API),
   then register with it: refused ("invalid or has expired"), nothing in game.
3. Register with a password confirmation that doesn't match: refused, nothing in game; the code still works afterwards.
