# Knights & Kings - Player Account Management Guide

**Version**: 1.2  
**Last Updated**: October 21, 2026 (KNG-218: "Getting an account" rewritten for invite-only sign-up. **It describes the
invitations feature ([KNG-205](https://linear.app/kngpandi/issue/KNG-205)), merged 2026-10-24 but not yet switched on
for the alpha**; until the switch-over, new players follow "Existing players" below.) Before:
KNG-208, `/account create` and web → game linking removed.  
**Plugin**: knk-plugin

---

## Overview

The Knights & Kings Minecraft plugin now supports account management, allowing you to:

- **Get an account with an invitation**: sign up on the website, then join the server and link your Minecraft
  account with the code it shows you
- **Create your web login** from the game (players from before the invitations): `/account link` gives you a code to
  register with on the website
- **Link your in-game account** with an existing web app account (enter the same code on your Account page)
- **Sync your progress** between Minecraft and the web app (coins, gems, experience)
- **View your account status** at any time
- **Resolve duplicate accounts** if you accidentally created multiple accounts

---

## Quick Start

### Getting an account (new players, invite-only)

Knights & Kings is invite-only. You need an **invitation** from staff: either a personal invitation **email**, or a
**shared code** (`KNK-XXXXX-XXXXX`) posted for your group.

1. **Sign up.** Open the link in your invitation email (your address is filled in), or go to **/join** and enter the
   shared code with your email. Choose a password and accept the alpha rules.
2. **Cloudflare sign-in.** Press **Continue to Cloudflare sign-in**. The site is protected by Cloudflare: its page asks
   for your email — type the **same address** you signed up with — and Cloudflare emails you a **6-digit code** (sender
   Cloudflare, not Knights & Kings; check spam). Enter it and you're in on this device for 30 days. You then land on
   **Link your Minecraft account**. If the site ever says "Your Cloudflare sign-in has expired or isn't active on this
   device", press **Sign in with Cloudflare** and do the same again.
3. **Join the server** (`play.knightsandkings.net`, Java Edition 26.3). You're stopped with a screen like:
   *"Knights & Kings is invite-only. Go to …/link and enter `K7QH-M2XA` (valid 15 minutes)."*
4. **Enter that code** on the website. Your Minecraft name now shows on your account.
5. **Join again.** You're in, with the first-join welcome and starter kits. The chat confirms which web account
   (e.g. `st***@gmail.com`) is linked — if that isn't you, tell staff right away.

**Joined the server before you had an invitation?** That's fine: note the code from the screen, go to **/link**, and
the site keeps it for 15 minutes while you sign up with your invitation; your Minecraft account is linked in the same
step. The same code stays valid for 15 minutes: joining again shows it again, or a new one once it has expired. If you
end up on **Register** or **Log in** instead, they point you back to the invitation sign-up (typed the server's code into
a link-code field? it's recognised by its dash). **Never give the code to anyone; staff never ask for it.**

### Existing players (played before the invitations)

Your account was carried over: you keep joining as before, without a code. If you don't have a web login yet:

1. Join the Minecraft server
2. Type `/account link` to get an 8-character code and the website address
3. On the website, open **Register**; while sign-ups are invite-only it opens on the invitation step, so click
   **Already playing and got a code from /account link?** first. Enter the code, your email and a password
4. You can now log in to the web app! Codes only go from the game to the website, never the other way.

On your first join you get a welcome message with a **[Link it now]** button. Clicking it runs `/account link`, which
gives you a code and the web address to create your web account with. For your first 10 minutes, the places you
discover are announced together in one summary afterwards (you still get the rewards straight away; `/discoveries`
lists them). Until you have a web account, every later join shows a one-line reminder with the same button.

### Existing Web App Users

If you already have an account on the web app (email and password, no Minecraft account yet):

1. Join the Minecraft server and type `/account link` to get a code
2. Log in to the web app
3. Click the **Account icon** (user profile icon) in the top-right navigation
4. Select **"Account Settings"** from the dropdown menu
5. Scroll to the **"Link Minecraft Account"** section and enter the code
6. Your accounts are now linked! If your Minecraft account already existed on the server, your web login moves
   onto it and the Minecraft account keeps its stats, groups and balances (you stay logged in as that account).

---

## Web App Account Management

### Accessing Your Account Settings

Once logged in to the web app:

1. Look for the **Account icon** (user profile circle) in the top-right corner of the navigation bar
2. **Hover over** or **click** the icon to open the dropdown menu
3. Select **"Account Settings"** to view and manage your account

### Account Settings Page

The Account Settings page allows you to:

#### 📋 View Account Information
- **Username**: Your Minecraft or web app username
- **Account Created**: When your account was created
- **Minecraft UUID**: Your unique Minecraft player identifier (if linked)
- **Coins**: Your premium currency balance
- **Gems**: Your free currency balance

#### ✉️ Update Email Address
1. Click the **"Edit"** button next to your email
2. Enter your new email address
3. Click **"Save"** to update
4. You'll see a success message when complete

#### 🔑 Change Password
1. Click **"Change Password"**
2. Enter your **current password**
3. Enter your **new password** (minimum 8 characters)
4. **Confirm** your new password
5. Click **"Update Password"**
6. Your password is updated immediately

#### 🔗 Link Minecraft Account
If you created your account on the web app and haven't linked your Minecraft account yet:

1. Scroll to the **"Link Minecraft Account"** section
2. You'll see an input field for the link code
3. In Minecraft, type `/account link` to generate a code
4. Copy the code from Minecraft (click the chat line to copy it)
5. Paste it into the web app (8 characters, shown as XXX-XXXXX)
6. Click **"Link Account"**
7. Your Minecraft and web accounts are now connected! Never give this code to anyone; staff never ask for it.

**Note**: This section only appears if you don't have a linked Minecraft account yet.

### Navigation Menu

The account dropdown menu provides quick access to:

- **Account Settings** - Manage your account, email, password, and linking
- **Logout** - Sign out of the web app (you'll need to log in again)

---

## Commands

### `/account`

**Description**: View your current account status

**Usage**: `/account`

**Aliases**: `/acc`

**Example**:
```
/account
```

**Output**:
```
[KnK] === Your Account ===

  Username: Steve123
  UUID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
  Email: steve@example.com

  Coins: 1,250
  Gems: 45
  Experience: 3,780

```

**Permissions**: `knk.account.view` (default: all players)

---

### `/account link`

**Description**: Generate a link code to connect your Minecraft account with the website

**Usage**: 
- `/account link` - Generate a new link code
- `/account link <code>` - Not supported: codes are entered on the website, not in game. The command only
  tells you where the code goes.

#### Scenario 1: Generate Link Code (Minecraft → Web App)

**Use Case**: You want to link your Minecraft account to the web app

**Steps**:
1. In Minecraft, type `/account link`
2. Copy the 6-character code shown
3. Log in to the web app
4. Go to Profile → Link Minecraft Account
5. Enter the code
6. Accounts are now linked!

**Example**:
```
Player: /account link

Server: === Link Code ===
Server: 
Server:   ABC-123
Server: 
Server: Use this code in the web app to link your account
Server: Expires in 20 minutes
```

**Link Code Rules**:
- ⏱️ Codes expire after 20 minutes
- 🔒 Codes are single-use (one successful link invalidates the code)
- 🔄 You can generate a new code at any time
- 🤫 Never give the code to anyone: whoever has it can register your web login. Staff never ask for it.
- ❌ Invalid/expired codes show: "This code is invalid or has expired. Use /account link to get a new one."

**Permissions**: `knk.account.link` (default: all players)

---

## Account Merging (Duplicate Resolution)

### What is a Duplicate Account?

A duplicate account occurs when:
- You played Minecraft before creating a web app account (UUID-based account)
- You created a web app account before playing Minecraft (email-based account)
- You now have TWO accounts in the system

### How to Detect

When you join the server with a duplicate account, you'll see:

```
[KnK] You have two accounts. Please choose which one to keep.
[KnK] Use /account merge to resolve this.
```

### How to Merge

**Option 1: Automatic Merge (when linking)**

When you use `/account link <code>` and a duplicate is detected, you'll be prompted:

```
[KnK] === Account Merge Required ===

Account A:
  Coins: 1,000 | Gems: 20 | XP: 2,500
  Email: steve@example.com

Account B:
  Coins: 500 | Gems: 10 | XP: 1,200
  Email: Not linked

Type A or B to choose which account to keep
```

**Important**:
- 💰 The chosen account will receive the **SUM** of coins, gems, and XP from both accounts
- 📧 The chosen account will keep its email (if set)
- 🗑️ The other account will be deleted

**Example**:
```
Player: A

Server: Merge complete! Your account now has 1,500 coins, 30 gems, and 3,700 XP.
```

---

## Troubleshooting

### "Please rejoin the server and try again"

**Cause**: Your account data isn't cached yet (server might have restarted)

**Solution**: 
1. Leave the server
2. Rejoin
3. Try the command again

---

### "Account service temporarily unavailable"

**Cause**: The backend API is down or unreachable

**Solution**: 
1. Wait a few minutes and try again
2. If the issue persists, contact a server admin

---

### "You already have an email linked!"

**Cause**: You've already set up your account

**Solution**: 
- Use `/account` to view your current status
- If you need to change your email/password, use the web app (Profile → Settings)

---

### "Invalid email format"

**Cause**: Your email doesn't match the required format

**Valid Examples**:
- steve@example.com ✅
- player.name@domain.co.uk ✅
- user+tag@subdomain.domain.com ✅

**Invalid Examples**:
- steve (missing @domain)
- @example.com (missing name)
- steve@domain (missing .extension)

---

### "Password must be at least 8 characters"

**Cause**: Your password is too short

**Solution**: Use a password with 8 or more characters

**Tips for Secure Passwords**:
- Mix uppercase and lowercase letters
- Include numbers
- Include special characters (!@#$%^&*)
- Example: `MyPass123!`

---

### "Passwords don't match"

**Cause**: The password confirmation didn't match the original password

**Solution**: The flow automatically restarts at the password step. Type your password carefully and exactly the same both times.

---

### Link Code Expired

**Cause**: You waited more than 20 minutes to use the link code

**Solution**:
1. Generate a new code with `/account link`
2. Use it within 20 minutes

---

### Can't Find Link Code on Web App

**Cause**: You might be on the wrong page

**Solution**:
1. Log in to the web app
2. Click your username (top-right corner)
3. Select "Profile" or "Account Settings"
4. Look for "Link Minecraft Account" section
5. Click "Generate Link Code"

---

## Security & Privacy

### Is My Password Safe?

Yes! Here's how we protect your information:

- 🔒 **Passwords are hashed** - We never store your actual password
- 🔐 **Nothing sensitive in chat** - Your email and password are only ever typed on the website, never in game
- 🌐 **HTTPS encryption** - All data sent to the API is encrypted
- ⏱️ **Link codes expire** - Unused codes expire after 20 minutes
- 🔄 **Automatic logout** - Sessions expire for security

### What Data is Stored?

**In-Game**:
- Username
- UUID (Minecraft unique identifier)
- Coins, Gems, Experience Points

**Web App**:
- Email address
- Hashed password
- Account creation date
- Email verification status

**Never Stored**:
- IP addresses (except in temporary server logs)
- Chat messages
- Plain-text passwords

---

## Frequently Asked Questions (FAQ)

### Can I change my email or password?

Yes! But only through the web app:
1. Log in to the web app
2. Go to Profile → Settings
3. Click "Change Email" or "Change Password"

### Can I delete my account?

Contact a server administrator. Account deletion is permanent and cannot be undone.

### What happens if I lose access to my email?

Contact a server administrator with proof of ownership (account details, transaction history, etc.).

### Can I have multiple Minecraft accounts linked to one email?

No. One email = one account. If you have multiple Minecraft accounts, you'll need separate email addresses for each.

### Do I need to link my account to play?

**New players: yes.** Once the server is invite-only, you play by linking the Minecraft account to the account you
made with your invitation (see "Getting an account"). **Players from before the invitations: no.** You can play without
a web login. However, a web login gives you:
- Access to the web app (view stats, manage resources)
- Web-based inventory management
- Future features (leaderboards, events, etc.)

### What if I forget my password?

Use the "Forgot Password" feature on the web app login page. You'll receive a password reset link via email.

### Can I unlink my account?

Not currently supported. Contact a server administrator if you need to unlink.

### Will linking my account affect my in-game progress?

No! Linking only adds web app access. Your in-game progress (coins, gems, XP) stays the same.

If you choose to merge accounts, the **sum** of both accounts' resources is transferred to the chosen account.

---

## Tips & Best Practices

### ✅ DO:
- Use a strong, unique password
- Use a real email address (for password recovery)
- Link your account as soon as possible
- Keep your link code private

### ❌ DON'T:
- Share your password with anyone (including server admins)
- Share your link code publicly (anyone can use it)
- Use the same password as other websites
- Use simple passwords like "password123"
- Wait too long to use a link code (20-minute expiry)

---

## Support

Need help? Contact the server administrators:

- **In-Game**: Ask a moderator or admin
- **Discord**: [Server Discord Link]
- **Email**: [Support Email]

---

## Changelog

### Version 1.2 (October 21, 2026)
- "Getting an account" for invite-only sign-up: invitation → account → Cloudflare PIN → join → code → link (KNG-205;
  merged 2026-10-24, not yet live)
- Existing players keep `/account link`

### Version 1.1 (January 30, 2026)
- Added web app Account Management page
- Added account dropdown menu in navigation (replaces standalone logout)
- Players can now edit email and password directly in web app
- Improved UI for linking Minecraft accounts via web interface
- Updated authentication to use global state (AuthContext)

### Version 1.0 (January 30, 2026)
- Initial release of account management system
- Commands: `/account`, `/account create`, `/account link`
- Auto-sync on player join
- Duplicate account detection and merging
- Secure chat capture for sensitive input

---

**Happy gaming!** 🎮⚔️👑
