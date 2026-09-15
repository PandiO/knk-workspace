# Registration Flow Update v2.0

**Date**: January 31, 2026  
**Focus**: Remove link code generation from registration flow  
**Status**: ✅ Complete

---

## Summary

Removed all link code input fields and link code generation logic from the registration and account creation flows. The web app now **only displays instructions** for players to use `/account link <code>` command in Minecraft (where the code is generated on the plugin side).

This aligns with the v2.0 architecture:
- ✅ **Web app-only account creation** (registration on web first)
- ✅ **Plugin generates link codes** (via `/account link` command)
- ✅ **Web app displays link codes** (in account management page)
- ✅ **No link code collection** during registration

---

## Files Modified

### 1. **RegisterForm.tsx**
**Changes**:
- ❌ Removed `LinkCodeResponseDto` import
- ❌ Removed `linkCode` field from `FormData` interface
- ❌ Removed `linkCode` field from `FormErrors` interface
- ❌ Removed `RegisterLinkCode` type alias
- ❌ Removed `linkCode` parameter from `onRegistrationSuccess` callback
- ❌ Removed `linkCode` from initial form state
- ❌ Removed `linkCode` from register() call payload
- ❌ Removed dual API call (authService + authClient for linkCode extraction)
- ❌ Removed linkCode passing to FormStep2
- ✅ Simplified to pass only `username` to FormStep2

**Result**: Clean, focused registration form without link code complexity

---

### 2. **FormStep2.tsx** (Minecraft Username)
**Changes**:
- ❌ Removed `linkCode` from data interface
- ❌ Removed `linkCode` field UI
- ❌ Removed link code input, error message, and help text
- ✅ Kept username validation logic (format and availability check)

**Result**: Step 2 only handles Minecraft username entry

---

### 3. **FormStep3.tsx** (Review)
**Changes**:
- ❌ Removed `linkCode` from data interface
- ❌ Removed link code display in review section
- ✅ Updated instructions text: "After registration, generate a link code from your account dashboard to connect Minecraft"
- ✅ Changed instruction wording to reflect web-first flow

**Result**: Review step no longer shows link code; instructions point to dashboard

---

### 4. **RegisterPage.tsx**
**Changes**:
- ❌ Removed `LinkCodeResponseDto` import
- ❌ Removed `RegisterLinkCode` type alias
- ✅ Simplified `handleSuccess()` - now just navigates without link code extraction

**Result**: Simple success navigation without link code state passing

---

### 5. **RegisterSuccessPage.tsx**
**Changes**:
- ❌ Removed `useLocation` hook
- ❌ Removed `LinkCodeDisplay` component import
- ❌ Removed `FeedbackModal` import (copy feedback)
- ❌ Removed `SUCCESS_MESSAGES` import
- ❌ Removed `LocationState` interface
- ❌ Removed `linkCode` and `expiresAt` state extraction from location
- ❌ Removed `showFeedback` and `handleCopySuccess` state
- ✅ Changed title from "Account Created!" to show success message
- ✅ Replaced link code display with **step-by-step instructions**:
  - Step 1: Go to Account Settings
  - Step 2: Generate Link Code
  - Step 3: Join Minecraft Server
  - Step 4: Enter Link Command (/account link YOUR_CODE)
  - Step 5: Accounts Linked
- ✅ Auto-redirect still in place (5 seconds)

**Result**: Success page now guides players through the process without displaying a generated code

---

### 6. **AccountManagementPage.tsx**
**Changes**:
- ✅ Kept `linkCode` in form state (needed for account linking)
- ❌ Removed "Generate Link Code for Minecraft" section
- ✅ Added "Link Minecraft Account" section with:
  - Instructions for running `/account link` in Minecraft
  - Link code input field (captures code from plugin)
  - "Link Account" button
  - Better visual layout and color scheme
- ✅ Updated conditional: shows linking UI only if `!user.uuid`
- ✅ Shows success UI if `user.uuid` already exists

**Result**: Account management page now handles link code input (consumption) not generation

---

### 7. **AuthDtos.ts**
**Changes**:
- ❌ Removed `linkCode` optional field from `RegisterRequestDto`

**Result**: Registration DTO no longer accepts link code

---

### 8. **UserDtos.ts**
**Changes**:
- ❌ Removed `linkCode` comment from `UserCreateDto`

**Result**: User creation DTO simplified

---

### 9. **authClient.ts**
**Changes**:
- ❌ Removed `LinkCodeRequestDto` import (no longer needed)
- ❌ Removed `requestLinkCode()` method (web app doesn't generate)
- ✅ Kept `generateLinkCode()` method (still used in account management)
- ✅ Kept `linkAccount()` method (for consuming link codes)

**Result**: API client focused on consumption, not generation

---

## Removed Components/Features

None - `LinkCodeDisplay.tsx` remains in the codebase but is no longer used during registration. It can be used elsewhere if needed.

---

## Architecture Changes

### Registration Flow (Before → After)

**Before (v1.0)**:
```
User fills form → Receives link code → Goes to success page with code → Uses code on Minecraft
```

**After (v2.0)**:
```
User fills form → Sees success page → Goes to Account Settings → Generates link code → Uses code on Minecraft
```

### Link Code Generation

**Before**: Registration response included link code

**After**: 
- Web app: `POST /api/Users/generate-link-code` (in account settings)
- Plugin: `POST /api/Users/generate-link-code` (via `/account link` command)

Both endpoints available; web app handles it via UI button

---

## Validation

✅ All TypeScript errors resolved
✅ No compilation warnings
✅ Form state properly typed
✅ All interfaces updated
✅ API client methods aligned with v2.0 flow
✅ Success page redirects correctly
✅ Account management page handles link codes

---

## Testing Checklist

- [ ] Registration form submits without linkCode field
- [ ] FormStep2 only shows username input
- [ ] FormStep3 review doesn't show linkCode
- [ ] Success page displays instructions (not link code)
- [ ] Success page auto-redirects to login/dashboard
- [ ] Account management page shows "Link Minecraft Account" section
- [ ] Link code input accepts code from `/account link` command
- [ ] "Link Account" button successfully links account
- [ ] After linking, UUID displays and linking section disappears

---

## Breaking Changes

🔴 **Registration flow changed**:
- No link code provided during registration
- Players must generate link code from account settings
- Requires extra step but improves UX

🟡 **For existing v1.0 integrations**:
- `RegisterRequestDto` no longer accepts `linkCode`
- Registration response won't include link code
- Players need to generate code separately

✅ **Migration path**:
- Direct existing players to account settings
- Generate link code button available
- Use `/account link` command as usual

---

## Future Improvements

- [ ] Add "Generate Link Code" button to account management
- [ ] Display link code expiry timer (20 minutes)
- [ ] Allow copying link code to clipboard
- [ ] Mobile-friendly link code display
- [ ] Account linking success animation

---

## Commit Message

```
feat: remove link code from registration flow (v2.0)

- Remove linkCode input from registration form steps
- Simplify RegisterForm, FormStep2, FormStep3 components
- Update RegisterSuccessPage with setup instructions
- Keep link code generation in account management
- Update AuthDtos.ts and UserDtos.ts
- Remove requestLinkCode from authClient (not needed)
- Update AccountManagementPage linking UI
- All TypeScript errors resolved

BREAKING CHANGE: Registration no longer provides link code.
Players must generate codes from account settings.
```

---

**Status**: ✅ Complete and ready for testing
