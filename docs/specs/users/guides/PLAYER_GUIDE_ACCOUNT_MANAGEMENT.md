# Knights & Kings - Player Account Management Guide

**Version**: 1.0  
**Last Updated**: January 30, 2026  
**Plugin**: knk-plugin-v2

---

## Overview

The Knights & Kings Minecraft plugin now supports account management, allowing you to:

- **Create an account** with email and password to access the web app
- **Link your in-game account** with an existing web app account
- **Sync your progress** between Minecraft and the web app (coins, gems, experience)
- **View your account status** at any time
- **Resolve duplicate accounts** if you accidentally created multiple accounts

---

## Quick Start

### New Players

If you're joining for the first time:

1. Join the Minecraft server (an account is automatically created with your username)
2. Type `/account create` to add email and password
3. Follow the prompts to set up your account
4. You can now log in to the web app!

### Existing Web App Users

If you already have an account on the web app:

1. Join the Minecraft server
2. Log in to the web app
3. Navigate to your profile and click "Link Minecraft Account"
4. Copy the link code shown
5. In Minecraft, type `/account link <code>`
6. Your accounts are now linked!

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

### `/account create`

**Description**: Create an account with email and password (interactive flow)

**Usage**: `/account create`

**What happens**:
1. You'll be prompted to enter your email address
2. Then enter a password (minimum 8 characters)
3. Confirm your password
4. Your account is created and ready to use on the web app

**Example Flow**:
```
Player: /account create

Server: Step 1/3: Enter your email address
Server: (Type 'cancel' to abort)

Player: steve@example.com

Server: Email saved!
Server: Step 2/3: Enter your password (min 8 characters)

Player: MySecurePass123

Server: Password saved!
Server: Step 3/3: Confirm your password

Player: MySecurePass123

Server: Account created successfully! You can now log in on the web app.
```

**Important Notes**:
- ⚠️ Your chat messages will NOT be broadcast while entering email/password
- ⚠️ Type exactly what you want - no one else can see it
- ⚠️ You have 2 minutes to complete the flow (auto-cancels after timeout)
- ⚠️ Type `cancel` at any time to abort

**Common Errors**:
- `Invalid email format` - Make sure your email looks like: name@domain.com
- `Password must be at least 8 characters` - Use a longer password
- `Passwords don't match` - Flow restarts at password step, try again

**Permissions**: `knk.account.create` (default: all players)

---

### `/account link`

**Description**: Generate or use a link code to connect your Minecraft and web app accounts

**Usage**: 
- `/account link` - Generate a new link code
- `/account link <code>` - Use a link code from the web app

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

#### Scenario 2: Use Link Code (Web App → Minecraft)

**Use Case**: You created an account on the web app and want to link it to Minecraft

**Steps**:
1. Log in to the web app
2. Go to Profile → Link Minecraft Account
3. Click "Generate Link Code"
4. Copy the code
5. In Minecraft, type `/account link <code>`
6. Accounts are now linked!

**Example**:
```
Player: /account link XYZ-789

Server: Your accounts have been linked!
```

**Link Code Rules**:
- ⏱️ Codes expire after 20 minutes
- 🔒 Codes are single-use (one successful link invalidates the code)
- 🔄 You can generate a new code at any time
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

### Chat Input Timeout

**Cause**: You didn't complete the `/account create` flow within 2 minutes

**Solution**:
1. Start over with `/account create`
2. Type faster or prepare your email/password in advance (copy-paste works!)

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
- 🔐 **Chat is hidden** - Your email and password are NOT broadcast to other players during `/account create`
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

No! You can play without linking. However, linking gives you:
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
- Type carefully during `/account create` (no undo!)
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

### Version 1.0 (January 30, 2026)
- Initial release of account management system
- Commands: `/account`, `/account create`, `/account link`
- Auto-sync on player join
- Duplicate account detection and merging
- Secure chat capture for sensitive input

---

**Happy gaming!** 🎮⚔️👑
