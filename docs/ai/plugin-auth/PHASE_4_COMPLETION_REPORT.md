# Phase 4 Implementation: Commands (Account Management)
## Status: ✅ COMPLETE

**Phase**: 4 - Commands Implementation  
**Date Started**: January 29, 2026  
**Date Completed**: January 29, 2026  
**Build Status**: ✅ SUCCESS (`:knk-paper:test`)  
**Test Status**: ✅ PASS  

---

## Overview

Phase 4 adds the player-facing account commands for the Minecraft plugin. The commands wire together the existing API client, user cache, and chat capture flow to allow players to view account status, create accounts, link accounts, and resolve duplicates via the merge flow.

---

## Deliverables

### ✅ Command Handlers

#### 1) AccountCommandRegistry (Dispatcher)
**File**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/commands/AccountCommandRegistry.java`

Registers and routes subcommands:
- `status` (alias: `view`)
- `create`
- `link`

Handles permission checks and default status view on `/account`.

#### 2) AccountCommand (Status)
**File**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/commands/AccountCommand.java`

Displays cached account data:
- Username, UUID, email status
- Coins, gems, XP
- Guidance for linking and duplicate resolution

#### 3) AccountCreateCommand
**File**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/commands/AccountCreateCommand.java`

Starts chat capture flow for email/password and updates the account via API:
- `updateEmail`
- `changePassword`
- Cache updated on success

#### 4) AccountLinkCommand
**File**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/commands/AccountLinkCommand.java`

Handles both link scenarios:
- Generate link code (no args)
- Validate/consume link code (with arg)
- Detect duplicate → merge flow
- Cache updated after link or merge

---

### ✅ Integration Updates

#### KnKPlugin command registration
**File**: `knk-paper/src/main/java/net/knightsandkings/knk/paper/KnKPlugin.java`

- Registers `/account` command executor via `AccountCommandRegistry`.

#### plugin.yml permissions
**File**: `knk-paper/src/main/resources/plugin.yml`

Added permissions:
- `knk.account.create`
- `knk.account.admin`

---

### ✅ Tests

**File**: `knk-paper/src/test/java/net/knightsandkings/knk/paper/commands/AccountCommandRegistryTest.java`

Coverage:
- Default routing to status when no args
- Permission denial for create
- Usage message for unknown subcommands

---

## Notes

- Duplicate account prompt in `UserAccountListener` now points to `/account link` to align with the merge flow implemented in Phase 4.
- API calls remain async and player-facing messages are dispatched on the main thread.

---

## Next Steps

- Phase 5: Error handling and polish (retry logic, rate limits, improved logging)
- Phase 6: Testing (unit + integration)
- Phase 7: Documentation (player/dev guides)