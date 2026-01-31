# Account Management v2.0 - Quick Reference (January 31, 2026)

## What Changed?

| Feature | v1.0 | v2.0 |
|---------|------|------|
| `/account` | ✅ View status | ✅ View status (no changes) |
| `/account create` | ✅ Create account in-game | ❌ **REMOVED** |
| `/account link` | ✅ Link with code | ✅ Link with code (no changes) |
| Email/Password input | ✅ In chat | ❌ Only on web app |
| Account creation | ✅ Minecraft plugin | ❌ Only on web app |
| Link code generation | ✅ Plugin + web app | ❌ Only on web app |

---

## New Player Flow (v2.0)

```
1. Create account on web app      ← NEW: Do this first
   (email + password)

2. Generate link code on web app  ← NEW: Get code here
   (20 minute validity)

3. Join Minecraft server          ← Auto-creates minimal account
   (with UUID + username)

4. Use /account link <code>       ← Same as before
   (provide link code from step 2)

5. Accounts linked! ✓             ← Merge if needed
```

---

## Player Commands

### `/account`
**Status**: ✅ **UNCHANGED**

Show account info:
```
/account
→ Username, UUID, email status
→ Coins, gems, experience
→ Duplicate account status
```

### `/account link [code]`
**Status**: ✅ **UNCHANGED**

Link with code from web app:
```
/account link ABC12XYZ
→ Valid code: "Accounts linked!"
→ Invalid code: "Link code invalid or expired"
```

### `/account create`
**Status**: ❌ **REMOVED**

Use web app instead:
```
1. Go to web app
2. Create account (email + password)
3. Generate link code
4. Use: /account link [code]
```

---

## Web App: Generate Link Code

**Current Flow (v2.0)**:
```
1. Log in to web app
2. Click Account icon (top-right)
3. Select "Account Settings"
4. Find "Link Minecraft Account" section
5. Click "Generate Link Code"
6. Copy the 8-character code
7. Use in Minecraft: /account link ABC12XYZ
```

---

## Developer Quick Reference

### Removed Classes/Methods

**Removed Entirely**:
- `AccountCreateCommand.java` - Command class

**Removed Methods**:
- `ChatCaptureManager.startAccountCreateFlow()`
- `ChatCaptureManager.handleAccountCreateInput()`
- `UserAccountApi.updateEmail()`
- `UserAccountApi.changePassword()`
- `CaptureFlow.ACCOUNT_CREATE` enum

**Removed Flows**:
- `ACCOUNT_CREATE` capture flow

### Still Available

**Commands**:
- `AccountCommand.java` - `/account` command
- `AccountLinkCommand.java` - `/account link` command

**Flows**:
- `ACCOUNT_MERGE` capture flow (for duplicates)

**API Methods**:
- `validateLinkCode(String code)`
- `generateLinkCode(Integer userId)`
- `linkAccount(Object request)`
- `mergeAccounts(Object request)`

### API Bug Fixes

**Fixed Issues**:
1. ✅ `updateEmail()` now sends `"newEmail"` instead of `"email"`
2. ✅ `BaseApiImpl` now handles 204 No Content responses

---

## Troubleshooting

### Link Code Issues

**"Link code invalid or expired"**
- Code only valid for 20 minutes
- Each code can only be used once
- Generate a new code on web app

**"Invalid code format"**
- Code must be exactly 8 characters
- Example: `ABC12XYZ`

### Account Creation Issues

**❌ No `/account create` in v2.0**
- Use web app instead
- Visit web app → Create Account
- Set email and password there

### Account Linking Issues

**"You already have an email linked!"**
- Account already linked
- Change email/password on web app
- Don't use `/account create` (doesn't exist in v2.0)

---

## Key Differences

### v1.0 (Old)
```
Problem: Players create accounts in Minecraft chat
- Email validation weak
- Password not hidden in chat
- Two places to create accounts (web + plugin)
- Inconsistent rules between web and plugin
```

### v2.0 (New)
```
Benefit: Single account creation on web app
+ Proper email validation
+ Password rules enforced
+ Consistent experience everywhere
+ Players with phones can create account while playing
```

---

## Migration Checklist

**For Server Admins**:
- [ ] Update plugin JAR
- [ ] Test `/account` command
- [ ] Test `/account link` command
- [ ] Verify `/account create` is gone
- [ ] Update player documentation

**For Players**:
- [ ] Create account on web app (if not already done)
- [ ] Generate link code on web app
- [ ] Join server
- [ ] Use `/account link [code]`

---

## Important URLs

- **Web App**: [Your web app URL]
- **Account Settings**: [Web app]/settings (after login)
- **Generate Link Code**: Account Settings → Link Minecraft Account

---

## Links for Documentation

- **Player Guide**: `PLAYER_GUIDE_ACCOUNT_MANAGEMENT_v2.md`
- **Developer Guide**: `DEVELOPER_GUIDE_ACCOUNT_INTEGRATION_v2.md`
- **Full Update Details**: `ACCOUNT_MANAGEMENT_v2_UPDATE.md`
- **Spec (Unchanged)**: `SPEC_USER_ACCOUNT_MANAGEMENT.md`

---

## Quick FAQ

**Q: Where do I create my account now?**
A: On the web app only. Visit the web app and sign up.

**Q: Where do I change my email/password?**
A: On the web app, in Account Settings.

**Q: How do I link my Minecraft account?**
A: Generate link code on web app → Use `/account link [code]` in Minecraft.

**Q: Can I still create an account just from Minecraft?**
A: No, not in v2.0. You must create account on web app first.

**Q: What if I'm already linked?**
A: No action needed. Everything still works the same.

**Q: Is my data lost?**
A: No. All accounts, coins, gems, and XP are preserved.

---

**Version 2.0 Release Date: January 31, 2026**
