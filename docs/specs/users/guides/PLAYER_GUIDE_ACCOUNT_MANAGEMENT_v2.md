# Knights & Kings - Player Account Management Guide

**Version**: 2.0  
**Last Updated**: January 31, 2026  
**Plugin**: knk-plugin-v2

---

## Overview

The Knights & Kings Minecraft plugin now supports account management, allowing you to:

- **Link your in-game account** with a web app account using a link code
- **Create a full account** on the web app with email and password
- **Sync your progress** between Minecraft and the web app (coins, gems, experience)
- **View your account status** at any time
- **Resolve duplicate accounts** if you accidentally created multiple accounts

---

## Quick Start

### New Players (Recommended Flow)

If you're joining for the first time:

1. Join the Minecraft server (an account is automatically created with your username and UUID)
2. Visit the web app and **create an account** (email and password required)
3. In your web app account settings, go to **"Link Minecraft Account"** section
4. Click **"Generate Link Code"** to create a code for your Minecraft account
5. In Minecraft, type `/account link ABC12XYZ` (replace with your actual code)
6. Your Minecraft and web accounts are now connected!
7. All your stats (coins, gems, experience) will sync between Minecraft and the web app

### Existing Web App Users

If you already have an account on the web app:

1. Join the Minecraft server (your Minecraft account will be created automatically)
2. Log in to the web app
3. Click the **Account icon** (user profile icon) in the top-right navigation
4. Select **"Account Settings"** from the dropdown menu
5. Scroll to the **"Link Minecraft Account"** section
6. Click **"Generate Link Code"** to create a new code
7. In Minecraft, type `/account link <code>` to link your accounts
8. Your accounts are now linked!

---

## In-Game Commands

### `/account`
View your account status and linked information in Minecraft.

**Shows**:
- Your username
- Your UUID
- Whether your email is linked
- Your coins, gems, and experience points
- Status of any duplicate accounts

**Usage**: `/account`

**Example**:
```
/account
```

**Output**:
```
[KnK] === Your Account ===

  Username: Steve123
  UUID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
  Email: ✓ steve@example.com

  Coins: 1,250
  Gems: 45
  Experience: 3,780
```

**Permissions**: `knk.account.use` (default: all players)

---

### `/account link [code]`
Link your Minecraft account with a web app account using a link code.

**Usage**: 
- `/account link ABC12XYZ` - Use a link code from the web app

#### How to Get a Link Code

**Steps**:
1. Log in to the web app
2. Click your **Account icon** (user profile circle) in top-right corner
3. Select **"Account Settings"**
4. Scroll to **"Link Minecraft Account"** section
5. Click **"Generate Link Code"**
6. Copy the code shown
7. In Minecraft, type: `/account link ABC12XYZ` (replace with your code)
8. You'll see a confirmation message

**Link Code Format**: 8 alphanumeric characters (e.g., `ABC12XYZ`)  
**Validity**: Link codes expire after 20 minutes  
**Usage**: One code can only be used once

**Example**:
```
Player: /account link ABC12XYZ

Server: Your accounts have been linked successfully!
Server: Welcome back!
```

**Common Errors**:
- `Invalid or expired link code` - Code may have expired or been used. Generate a new one in the web app.
- `Code not found` - Double-check you typed it correctly (case-sensitive)

**Permissions**: `knk.account.use` (default: all players)

---

## Web App Account Management

### Creating Your Account

1. Visit the web app
2. Click **"Sign Up"** or **"Create Account"**
3. Enter your **email address**
4. Create a **password** (minimum 8 characters)
5. Confirm your password
6. Click **"Create Account"**
7. You're now logged in!

**Password Requirements**:
- Minimum 8 characters
- No forced complexity (uppercase, numbers, symbols optional but recommended)
- Avoid weak passwords like "password123" or "123456"

### Accessing Your Account Settings

Once logged in to the web app:

1. Look for the **Account icon** (user profile circle) in the top-right corner of the navigation bar
2. **Click** the icon to open the dropdown menu
3. Select **"Account Settings"** to view and manage your account

### Account Settings Page

The Account Settings page allows you to:

#### 📋 View Account Information
- **Username**: Your Minecraft or web app username
- **Account Created**: When your account was created
- **Minecraft UUID**: Your unique Minecraft player identifier (if linked)
- **Coins**: Your premium currency balance
- **Gems**: Your free currency balance
- **Experience Points**: Your current XP

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
If you haven't linked your Minecraft account yet:

1. Scroll to the **"Link Minecraft Account"** section
2. Click **"Generate Link Code"** to create a new link code
3. The code will appear on your screen (format: XXXX-XXXX-XXXX)
4. Copy the code
5. In Minecraft, type `/account link <code>` (replace `<code>` with the code you copied)
6. Your Minecraft and web accounts are now connected!

**Note**: This section only appears if you don't have a linked Minecraft account yet. Link codes expire after 20 minutes.

### Navigation Menu

The account dropdown menu provides quick access to:

- **Account Settings** - Manage your account, email, password, and link your Minecraft account
- **Logout** - Sign out of the web app (you'll need to log in again)

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
[KnK] You have multiple accounts. Your accounts will need to be linked.
[KnK] Follow the in-game prompts to resolve this.
```

### How to Merge

**When Linking with `/account link <code>`**

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

**Choose Wisely**:
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

### "Invalid or expired link code"

**Cause**: 
- Code has expired (link codes only last 20 minutes)
- Code was already used
- Code was typed incorrectly

**Solution**:
1. Log in to the web app
2. Go to Account Settings → Link Minecraft Account
3. Click "Generate Link Code" to create a new one
4. Use it within 20 minutes

---

### Link Code Not Working

**Common Issues**:

**Typed it wrong**:
- Make sure you copied the code exactly
- Link codes are case-sensitive
- Example: `ABC12XYZ` is different from `abc12xyz`

**Code expired**:
- Link codes only work for 20 minutes
- If you waited too long, generate a new code in the web app

**Already used**:
- Each code can only be used once
- If you made a mistake, generate a new code

---

### "You already have a linked email!"

**Cause**: You've already set up your account

**Solution**: 
- Use `/account` to view your current status
- If you need to change your email/password, use the web app (Account Settings)

---

### Chat Input Timeout

**Cause**: You didn't complete a flow within 2 minutes (if applicable)

**Solution**:
1. Start over with the command
2. Type faster or prepare your information in advance

---

### Can't Find Link Code on Web App

**Cause**: You might be on the wrong page

**Solution**:
1. Log in to the web app
2. Click your **Account icon** (top-right corner)
3. Select **"Account Settings"**
4. Look for **"Link Minecraft Account"** section
5. Click **"Generate Link Code"**

---

## Security & Privacy

### Is My Password Safe?

Yes! Here's how we protect your information:

- 🔒 **Passwords are hashed** - We never store your actual password
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

**Never Stored**:
- IP addresses (except in temporary server logs)
- Plain-text passwords

---

## Frequently Asked Questions (FAQ)

### Do I have to link my account to play?

No! You can play without linking. However, linking gives you:
- Access to the web app (view stats, manage resources)
- Web-based inventory management
- Future features (leaderboards, events, etc.)

### How do I change my email or password?

Through the web app:
1. Log in to the web app
2. Go to Account Settings
3. Click "Edit" next to your email or "Change Password"

### What if I forget my password?

Use the "Forgot Password" feature on the web app login page. You'll receive a password reset link via email.

### Can I delete my account?

Contact a server administrator. Account deletion is permanent and cannot be undone.

### What happens if I lose access to my email?

Contact a server administrator with proof of ownership (account details, transaction history, etc.).

### Can I have multiple Minecraft accounts linked to one email?

No. One email = one account. If you have multiple Minecraft accounts, you'll need separate email addresses for each.

### What if I link the wrong Minecraft account?

Contact a server administrator. They can unlink your accounts so you can link again with the correct account.

### Will linking my account affect my in-game progress?

No! Linking only adds web app access. Your in-game progress (coins, gems, XP) stays the same unless merging accounts.

If you choose to merge accounts, the **sum** of both accounts' resources is transferred to the chosen account.

### How long does it take to link my account?

Instant! As soon as you enter the link code in Minecraft, your accounts are connected.

---

## Tips & Best Practices

### ✅ DO:
- Create an account on the web app first
- Generate a link code in the web app
- Use a strong, unique password
- Use a real email address (for password recovery)
- Link your account as soon as possible
- Keep your link code private
- Copy-paste your link code (less chance of typos)

### ❌ DON'T:
- Share your password with anyone (including server admins)
- Share your link code publicly (anyone can use it)
- Use the same password as other websites
- Use simple passwords like "password123"
- Wait too long to use a link code (20-minute expiry)
- Type your link code manually (copy-paste is safer)

---

## Support

Need help? Contact the server administrators:

- **In-Game**: Ask a moderator or admin
- **Discord**: [Server Discord Link]
- **Email**: [Support Email]

---

## Changelog

### Version 2.0 (January 31, 2026)
- **Removed** `/account create` command - account creation now only on web app
- **Changed** workflow: Players must create accounts on web app first
- **Updated** link code generation to web app only
- Players now use `/account link [code]` to link Minecraft with web app accounts
- Streamlined process for new players

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
