# Your account: invitation, linking, login and password

**Status:** Current · **Last updated:** 2026-11-13 (§ Delete my data: the request and what the game server does, PandiO/knk-workspace#184, game-server part in `next`; brought over from the old guide on `next`)
**Checked against:** knk-web-app `main` `3ba747d`, knk-web-api `master` `75b5a00`, knk-plugin `main` `57884e9`
**Related:** [player handbook](player-handbook.md), [commands reference](commands.md), [invitations admin guide](../admin/invitations-admin-guide.md), [statistics and public profile](statistics-player-guide.md)

Your Knights and Kings account is one thing with two halves: your **Minecraft player** and your **web login** (an
email and a password on the website). This guide covers getting an account with an invitation, linking your
Minecraft account, logging in, staying logged in, and changing or resetting your password and email.

The closed alpha has been **invite-only since 2026-10-24**: you can't play or sign up without an invitation from
staff. Players who played before that keep their accounts (see [Played here before the invitations?](#played-here-before-the-invitations)).

## Contents

1. [What you need](#what-you-need)
2. [Sign up with an invitation](#sign-up-with-an-invitation)
3. [Cloudflare sign-in](#cloudflare-sign-in)
4. [Link your Minecraft account](#link-your-minecraft-account)
5. [Played here before the invitations?](#played-here-before-the-invitations)
6. [Logging in and sessions](#logging-in-and-sessions)
7. [Forgot your password](#forgot-your-password)
8. [Your Account page](#your-account-page)
9. [In game: `/account`](#in-game-account)
10. [Messages and what they mean](#messages-and-what-they-mean)
11. [Keeping your account safe](#keeping-your-account-safe)

## What you need

1. An **invitation** from staff: a personal invitation email, or a shared invitation code `KNK-XXXXX-XXXXX`.
2. An email address you can read.
3. Minecraft **Java Edition 26.3**. Bedrock players (Windows, consoles) can join the alpha through its crossplay
   bridge too; their Minecraft name gets a `BE_` prefix. The landing page still mentions Java only
   (PandiO/knk-workspace#449).
4. The server address `play.knightsandkings.net`, shown on the website's home page with a copy button.

## Sign up with an invitation

There are two kinds of invitation. Both create the same kind of account.

### A personal invitation email

1. Open the link in the mail ("You're invited to Knights & Kings"). The page **Accept your invitation** opens; the
   link disappears from the address bar, so bookmark nothing.
2. Your email is filled in and locked ("The invitation was sent to this address, so it's already verified").
3. Choose a **Password** and **Confirm password**, tick the closed-alpha rules (the game is unfinished, progress may
   be reset, and you keep what you see to yourself), and press **Create account**.

The page says until when the invitation is valid (normally 7 days). If you press **Log in** instead, the login
page's **Create an account** brings you back to the same invitation, as long as the tab stays open.

### A shared invitation code

1. Go to `/join` (**Join the closed alpha**) or open the `/join?code=…` link you were given.
2. Type the code into **Invitation code**. You type only the 10 letters and digits; the field shows `KNK-` and the
   dashes itself. Press **Continue**.
3. "Code KNK-… is valid." Type your **Email**, choose a password, tick the rules and press **Create account**.

A shared code works for a limited number of people and until a date; staff can also pause or replace it.

### Password rules

8 to 128 characters, not a common password and not an obvious pattern (`aaa`, `123`, keyboard rows). On the sign-up
pages the strength meter must reach at least **Fair** before **Create account** works.

### After **Create account**

You are logged in. Both pages show **What happens next** before you sign up: the Cloudflare step (when the site uses
it) and then joining the server. You land on **Link your Minecraft account**, or first on Cloudflare's page.

If the invitation stopped working while the form was open (used up, revoked, expired), the page shows "This
invitation is invalid or has expired. Ask whoever invited you for a new one." Every failure looks the same on
purpose. **This email is already in use by another account** means you already have an account: log in instead.

## Cloudflare sign-in

The alpha website sits behind Cloudflare Access. When it is on, signing up ends on **Your account is ready** with
these steps:

1. Press **Continue to Cloudflare sign-in**. Cloudflare's own page opens (the address bar leaves the site).
2. Type the **same email** you signed up with.
3. Cloudflare emails you a **6-digit code**, from `noreply@notify.cloudflare.com`, not from Knights and Kings. Check
   your spam folder. Enter the code.
4. You are back on the site, on **Link your Minecraft account**. This device stays signed in to Cloudflare for 30 days.

On a new device or browser, or after 30 days, Cloudflare asks again before the site opens ("First time on this
device? Cloudflare asks for your email…" on the login page). If a page says **Your Cloudflare sign-in has expired or
isn't active on this device**, press **Sign in with Cloudflare** and do the same again; your Knights and Kings login
stays.

The pages for signing up (`/invite`, `/join`, `/link`) open without Cloudflare, so you can always start there.

## Link your Minecraft account

Until your web account is linked, you can't play, and every page shows **Link your Minecraft account to play →**.

1. In Minecraft, add `play.knightsandkings.net` and join.
2. The server turns you away with a screen like:
   *"Knights & Kings is invite-only. Go to …/link and enter* **`K7QH-M2XA`** *(valid 15 minutes). Never give this code
   to anyone; staff never ask for it."*
3. On the website, logged in, open **Link your Minecraft account** (`/account/link`). Type the 8 letters and digits
   into **Code from the server**; the field shows `____-____` and adds the dash itself. Press **Link account**.
4. Your **Account** page now shows your Minecraft name as your username, and **✓ Minecraft Account Linked**.
5. Join again. You are in, with the first-join welcome and your starter kits. The chat says *"Your Minecraft account
   is now linked to the web account st***@…"*. If that isn't your address, tell staff right away. You also get a mail
   about the link.

About the claim code:

1. Joining again within the 15 minutes shows the **same** code; after that, joining gives a new one.
2. A refused code is not used up: "The same code stays valid for 15 minutes".
3. Letters that look alike are forgiving: an O is read as 0.
4. Five wrong codes in a row lock linking for 15 minutes: "Too many attempts. Try again in 15 minutes."
5. For your first 10 minutes in the game, the places you discover are announced together in one summary afterwards;
   the rewards come straight away.

### Joined the server before you signed up?

That works too.

1. Note the code from the disconnect screen and open `/link` on the website (no login needed).
2. Type the code under **Code from the server** and press **Continue**: "Verified: Minecraft account `<name>`".
3. Then either:
   - **Log in** if you already have an account, and press **Link `<name>` to my account**; or
   - under **New here? Create your account with an invitation**, open your invitation mail's link, or type your
     invitation code and press **Continue**. The sign-up page says "Your Minecraft account `<name>` will be linked to
     this account", and the link happens when you press **Create account**.
4. Join again and play.

The site keeps the verified code in that browser tab for its 15 minutes.

### Typed the code in the wrong place?

The **Create account** page (`/auth/register`) opens on **Sign up with your invitation**. Its field **Invitation code
or code from the server** takes either an invitation code or the code from the disconnect screen and sends you to the
right page. The **Log in** page's **Create an account** link also leads to the invitation sign-up.

## Played here before the invitations?

Accounts that existed on 2026-10-24 were carried over: you join without a code. To get a web login:

1. In game, type `/account link`. You get an 8-character code that is valid for **20 minutes**, and the website
   address. You can ask for a new code once a minute.
2. On the website open **Create account** (`/auth/register`) and click **Already playing and got a code from /account
   link?**.
3. Type the code into **Link code** and press **Check code**. "This code belongs to `<your name>`."
4. Choose your email and password and press **Create account**. You are logged in.

Codes only go from the game to the website, never the other way: `/account link <code>` in game does nothing but tell
you to enter it on the website.

**You already have a web login without a Minecraft account** (made before the invitations): get a code with
`/account link`, log in on the website and enter it on **Link your Minecraft account** (`/account/link`). Your web
login moves onto your Minecraft account, which keeps its statistics, groups and history; each balance becomes the
higher of the two. The old web-only account is retired. `/account` in game then shows your email. If the Minecraft
account already has its own web login, you get "This Minecraft account already has a web account. Log in with it,
or use Forgot password." and nothing changes.

## Logging in and sessions

**Log in** (`/auth/login`) takes your **Email or Minecraft name** and your **Password**.

1. **Remember me** off (the default): you stay logged in until you close the browser, at most 12 hours.
2. **Remember me** on: you stay logged in on this device for 30 days. Don't use it on a shared computer.
3. When a session runs out, the login page says "Your session expired. Log in again to continue" and takes you back
   to the page you were on.

Five wrong passwords within 15 minutes lock the account for 15 minutes: "Too many attempts. Try again in N minutes."
A wrong name and a wrong password give the same answer, "Invalid credentials."

### Log out, or log out everywhere

On your **Account** page, under **Session**:

1. **Log out** ends the session in this browser. The account menu (top right) has **Log out** too.
2. **Log out on all devices** ends every session of your account at once. Use it if you think someone else has
   access to your account, then change your password.

Changing your password or your email also logs you out everywhere else; the browser you made the change in stays
logged in. A password reset logs you out everywhere.

## Forgot your password

1. On **Log in**, click **Forgot password?**.
2. Type your account's email and press **Send Reset Link**. The page always answers "If an account with that email
   exists, reset instructions have been sent", so it never tells anyone which addresses have accounts.
3. Open the link in the mail within **30 minutes**. On **Choose New Password**, type and confirm the new password.
4. You are logged out on every device; log in with the new password.

Limits: one reset mail a minute per address, at most three an hour. A link that has expired or was already used
answers "Reset token is invalid or expired": ask for a new one.

A Minecraft account without a web login has no password to reset: get a code with `/account link` instead (see
[above](#played-here-before-the-invitations)). If you no longer have access to your email, ask staff.

## Your Account page

Open it from the account menu (top right) → **Account settings** (the page `/account`). It shows:

1. **Account Information:** username (your Minecraft name once linked; a generated `web-…` name before that), when
   the account was created, your Minecraft UUID, coins and gems, and **View transaction history**.
2. Your **discoveries** and **statistics**, once your Minecraft account is linked
   ([statistics guide](statistics-player-guide.md)).
3. **Email Address** with **Edit**: type the new email and your **Current Password**, press **Save**. Your other
   devices are logged out, and your **old** address gets a mail "Your Knights & Kings email was changed". When the
   site uses Cloudflare, use the new address at Cloudflare's next sign-in. The **Email verified** badge (from a
   personal invitation) goes away after a change; there is no way to verify a new address yet
   (PandiO/knk-workspace#139).
4. **Password** with **Change Password**: current password, new password twice, **Update Password**.
5. **Link Minecraft Account**, only while your account isn't linked, with a button to the linking page. Once linked:
   **✓ Minecraft Account Linked**. You can't unlink or switch the Minecraft account yourself: "Changing it is a staff
   action."
6. **Delete my data**: request deletion of your data by email confirmation; it runs five days after you confirm
   unless you cancel. The section lists what is deleted and what is kept without your name. See
   [Delete my data](#delete-my-data).
7. **Session**: **Log out** and **Log out on all devices**.

When your Minecraft name changes, your username follows it the next time you join.

### Delete my data

On the **Account** page, under **Delete my data**:

1. Press **Delete my data…**, then **Email me the confirmation link** (you need an email address on your account).
2. Open the link in the email to confirm. Nothing is deleted until you confirm.
3. Your data is deleted **five days** after you confirm. Until then the Account page shows the date, and you can press
   **Cancel deletion** to keep everything.

What is deleted: your statistics, privacy settings, discoveries, private-message logs, ranks and permissions, and your
username, email and Minecraft link. Your coin, gem and XP history and Siege match results are kept, without your name.
This can't be undone. Staff can also file the request for you; it then runs the same way, five days later.

**On the game server**, when the deletion runs. This part only happens on a game server that keeps a live connection
to the website (the server setting `realtime.enabled: true`); without it the game server does none of the steps below:

1. If you are online, you are disconnected with the message `Your account data has been deleted.` If you were in a
   siege, your own inventory, stats and position are given back to you first.
2. The game server then deletes what it keeps about you locally: your saved login data, cached ranks and permissions,
   ignore lists (yours, and you on other players' lists), statistics and discoveries not yet sent, private messages you
   sent or received in its logs, a saved siege inventory and a saved return point.
3. If such a server was offline or its connection was down at that moment, it catches up the next time it connects.

If you join again later, you start with a new account, as a new player (see
[Sign up with an invitation](#sign-up-with-an-invitation)). The game-server part (PandiO/knk-workspace#184) is in
knk-plugin `next` `745fcf6` and reaches the game server with the next release.

## In game: `/account`

| Command | What it does |
|---|---|
| `/account` (or `/acc`, `/account status`) | Shows your username, UUID, email (or **Not linked**), coins, gems and experience |
| `/account link` | Gives a code to create or link your web login (valid 20 minutes, once a minute) |

Without a web login, your first join's welcome ends with **[Link it now]**, which runs `/account link`; every later
join shows a one-line reminder with the same button. Full syntax: [commands reference](commands.md).

## Messages and what they mean

| Where | Message | What to do |
|---|---|---|
| Joining the server | "Knights & Kings is invite-only. Go to … and enter `XXXX-XXXX`" | Your Minecraft account isn't linked to an invited account yet: [link it](#link-your-minecraft-account) |
| Joining the server | "Can't check your access right now. Try again in a minute." | The game's services are down. Players who joined before get in after a few seconds; new players wait |
| Joining the server | "This account is deactivated. Contact staff if you think this is a mistake." | Staff deactivated the account; ask them |
| `/link`, `/account/link` | "This code is invalid or has expired." / "This code from the server is invalid or has expired." | Check the code, or join again for the current one |
| `/account/link` | "You need an invitation before you can link a Minecraft account." | Your web account wasn't created with an invitation; ask staff |
| `/account/link` | "Your web account is already linked to another Minecraft account. Changing it is a staff action." | Ask staff |
| `/account/link`, sign-up | "This Minecraft account already has a web account. Log in with it, or use Forgot password." | Log in with that account |
| Sign-up | "This invitation was sent to a different email address." | Use the address the invitation went to |
| Sign-up, link page | "You need an invitation to create an account." | The alpha is invite-only; ask staff for an invitation |
| Anywhere | "Too many attempts. Try again in N minutes." | Wait; it counts wrong passwords and wrong codes |
| Any page | "Your Cloudflare sign-in has expired or isn't active on this device" | Press **Sign in with Cloudflare** ([Cloudflare sign-in](#cloudflare-sign-in)) |

## Keeping your account safe

1. **Never give a code to anyone**: not the claim code, not an `/account link` code, not a reset link. Staff never
   ask for codes or passwords. Someone with your code can tie your Minecraft account to their web login.
2. If the chat names a web account that isn't yours after a link, tell staff right away. Staff can detach a web
   login from a Minecraft account; you then create your own with `/account link`.
3. Use **Log out on all devices** and change your password if you think someone else is logged in.
4. Passwords are stored only as hashes; nobody, staff included, can read them.

## Changes

1. 2026-11-13: § Delete my data: the **Delete my data** request and what the game server does when it runs
   (PandiO/knk-workspace#184, docs #400; game-server part in knk-plugin `next`), brought over from
   `PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md` on `next`.
2. 2026-11-13: rewritten for the invite-only flow and renamed from `PLAYER_GUIDE_ACCOUNT_MANAGEMENT.md` (PandiO/knk-workspace#299).
   The old guide's sections on `/account create`, merging in game and the account-settings layout of 2026-01 were
   removed; they described removed behaviour.
3. 2026-11-03: the register page's code field shows the dash (#229).
4. 2026-10-26: the claim code field shows `____-____` from the start (#196) and adds the dash (#192).
4. 2026-10-21: "Getting an account" rewritten for invite-only sign-up (KNG-218).
5. 2026-01-30: versions 1.0 and 1.1 (account commands, linking, merging).
