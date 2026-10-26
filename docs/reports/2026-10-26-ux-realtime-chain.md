# Dashboard, form wizard and realtime chain — progress report

**Status:** In progress — link 1 running (2026-10-26)
**Last updated:** 2026-10-26
**Charter:** [UX_REALTIME_CHAIN.md](../ai-agents/handoffs/UX_REALTIME_CHAIN.md) · **Coordinator prompt:**
[2026-10-26-ux-realtime-coordinator-prompt.md](../ai-agents/handoffs/2026-10-26-ux-realtime-coordinator-prompt.md)
**Base at start:** knk-web-app `main` `0d61270`, knk-web-api `master` `6f08383`, knk-plugin `main` `ee35fb1` (re-check:
later merges on the trunks happen; each link records its own base).

## Summary

Status values: `ready` (gate open), `waiting: <gate>`, `in progress`, `in review` (pushed, waiting for the developer's
test), `merged`, `blocked: <reason>`.

| Link | Issues | Branch | Status | Started | Heads (api / web-app / plugin / workspace) | Tests vs baseline |
|---|---|---|---|---|---|---|
| 1 | #177 (link 1), #58 | `claude/kng-60-dashboard-hub` | in progress | create_session session_01Lr2FyBpZG3fDCq51LuFgSM, 2026-10-26 (a first subagent run was stopped by the developer before pushing anything) | — | — |
| 2 | #185, #38, #192 | `claude/route-gates-185`, `claude/styling-quick-wins-38`, `claude/claim-code-field-192` | waiting: link 1 done | — | — | — |
| 3 | #177 (link 2), #81, #39 (menu) | `claude/kng-60-dashboard-hub` | waiting: link 1 done | — | — | — |
| 4 | #178 | `claude/realtime-signalr` | waiting: link 1 done (then together with link 3) | — | — | — |
| 5 | #64 (FormWizard), #109, #186 | `claude/form-wizard-edit-mode` | waiting: links 1 and 3 merged | — | — | — |
| 6 | #179 | `claude/realtime-signalr` | waiting: link 4 done | — | — | — |
| 7 | #180 | `claude/world-task-hardening` | waiting: link 5 merged | — | — | — |
| 8 | #181 | `claude/realtime-signalr` | waiting: link 6 done, link 7 merged | — | — | — |
| 9 | #39 (rest), #177 follow-up | `claude/entity-lists-url-state` | waiting: link 3 merged | — | — | — |
| 10 | #182 | `claude/realtime-signalr` | waiting: link 8 done | — | — | — |

## Waiting for the developer

(The coordinator keeps this list current: links in review with their checklist location, merges that unblock a gate,
flagged decisions.)

- Nothing yet.

## Follow-ups filed by links

- None yet.

---

<!-- Link blocks are appended below, in the order the links finish. -->
