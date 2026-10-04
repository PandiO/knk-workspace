# Session Linear closeout — 2026-10-04

Status: requested issues are implemented, documented, pushed and marked Done in Linear. Live checks
remain with the developer where noted in the issue-specific reports.

| Issue | Default-branch / feature-branch evidence | Final state |
|---|---|---|
| KNG-24 | knk-plugin `main` merge `1a69ec3` (`ed6a92f`, `89a0b3b`, `0211f80`) | Done |
| KNG-25 | knk-plugin `main` merge `1a69ec3` (`9fcdd7f`) | Done |
| KNG-26 | knk-web-api `master` `ae0b3ad`; knk-web-app `main` `fc66101` | Done |
| KNG-28 | knk-plugin `main` merge `1a69ec3` (`da1f02b`; matrix coverage `db474e4`) | Done |
| KNG-29 | knk-plugin `main` `ee7824c`; lore-color follow-up on API `master` `c0c2b22` | Done |
| KNG-30 | knk-plugin `main` `52ce855`, retained through merge `1a69ec3` | Done |
| KNG-38 | API/app branches `codex/kng-38-permission-holder-search` at `3dd1e26` / `e26b3f6` | Done; branches remain unmerged |

## Backlog-branch merge

`claude/backlog-bugs` was merged into the KNG-30-aware plugin `main` with merge commit `1a69ec3`.
The two expected conflicts were resolved by combining both behaviors:

- `/freeze` and `/unfreeze` retain KNG-30's vanish-aware player completion while using KNG-24's
  in-house permission gate and command visibility handling; `/staffchat` uses the same permission gate.
- `/knk` retains KNG-30's alias normalization and KNG-24's permission check before completing a
  subcommand.
- Permission-gated commands without a completer return an explicit empty list, so `/staffchat` does
  not fall back to Bukkit's all-online-player suggestions.

The post-merge `./gradlew build -x deployToDevServer` passed across knk-core, knk-api-client and
knk-paper. No live/in-game checks were run.

