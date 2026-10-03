# Sequential backlog fixes — 2026-10-03

Implementation record for KNG-26, KNG-28, KNG-29, KNG-30 and KNG-38. All code is pushed. Per the
developer's instruction, no live or smoke testing was performed; feature branches remain unmerged
until that verification is complete.

| Issue | Outcome | Remote evidence | Verification | Merge state |
|---|---|---|---|---|
| KNG-26 | Untouched FormWizard boolean fields normalize to `false`; `PermissionGroup.IsPremiumTier` publishes a false default through metadata. | knk-web-app `main` `fc66101`; knk-web-api `master` `ae0b3ad` | Focused Jest tests and `tsc --noEmit` pass; API metadata regression test added (the initial environment lacked .NET). | On default branches |
| KNG-28 | Siege members are switched to survival with flight disabled after their pre-match state is vaulted, preventing creative immunity from suppressing the damage event and safe-zone denial message. The full attacker/defender, multi-spawn and projectile matrix remains covered. | knk-plugin branch `claude/backlog-bugs`: behavior `da1f02b`; trunk regression coverage `db474e4` | Full Gradle build on `claude/backlog-bugs` green; matrix tests green | Branch pushed, not merged |
| KNG-29 | Lore is composed into stable enchantment, description and grade/origin sections with exactly one spacer at section boundaries; reapplication is idempotent. | knk-plugin `main` `ee7824c` | Targeted lore tests and full Gradle suite pass | On default branch |
| KNG-30 | Every plugin command has explicit completion behavior: permission-filtered subcommands, vanish-safe online players, cached offline names where supported, fixed values/catalog names, and no Bukkit player-name fallback for argumentless commands. | knk-plugin branch `codex/kng-30-command-completion-sweep` `52ce855`; [command audit](2026-10-03-command-completion-sweep.md) `f515bbb` | Full Gradle suite passes | Branch pushed, not merged |
| KNG-38 | Added read-only `PermissionHolders` search/get endpoints that union Users and PermissionGroups by display name, plus FormWizard search and edit-hydration client mappings. | knk-web-api branch `codex/kng-38-permission-holder-search` `3dd1e26`; knk-web-app same branch `e26b3f6` | 148 permission-area API tests, frontend `tsc --noEmit`, and focused Jest tests pass | Branches pushed, not merged |

## Live checks left to the developer

- KNG-26: create a PermissionGroup without touching Premium Tier and confirm `isPremiumTier=false`.
- KNG-28: enter siege in creative, confirm the hub changes the member to survival, and verify the
  defender receives the denial message when hitting an attacker in the attacker's spawn safe zone.
- KNG-29: inspect generated and subsequently enchanted items for exactly one spacer between sections.
- KNG-30: exercise staff/player completion with vanished players and representative offline targets.
- KNG-38: render and use `PermissionGrant.Holder` in FormWizard for both a User and PermissionGroup.

KNG-30 and the broader `claude/backlog-bugs` branch touch some of the same command-registration
files. The trial-merge resolution notes are in `2026-10-03-linear-bug-sweep.md`.
