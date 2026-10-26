# Plan: web app UX re-evaluation, dashboard CRUD hub + form wizard, SignalR (incl. world tasks)

**Status:** Accepted with the developer's decisions of 2026-10-26 (§7a). **No code written.** My own decisions are in §6;
the questions as asked are in §7.
**Date:** 2026-10-25
**Branch:** knk-workspace `claude/sharp-ptolemy-124hvw` (includes the 2026-10-24 dashboard handoff from
`claude/tender-cerf-elcye5`). Not merged into `main`.
**Code basis (read-only):** knk-web-app `main` `0d61270`, knk-web-api `master` `6f08383`, knk-plugin `main` `ee35fb1` (all 2026-10-25).
**Issues:** UX roadmap [#24](https://github.com/PandiO/knk-workspace/issues/24) (KNG-140) and sub-issues; dashboard hub
[#177](https://github.com/PandiO/knk-workspace/issues/177) (new); [#58](https://github.com/PandiO/knk-workspace/issues/58)
(KNG-60); [#39](https://github.com/PandiO/knk-workspace/issues/39) (KNG-145); SignalR
[#66](https://github.com/PandiO/knk-workspace/issues/66) (KNG-57) with phases #178–#184 (new); new bugs #185, #186.

> Issue numbers: the request named "KNG-140 (GitHub issue 4)" and "KNG-57 (GitHub issue 32)". #4 is an old closed PR
> and #32 is KNG-241 (VPS fallback). The migration report maps KNG-140 → **#24** and KNG-57 → **#66**; this plan uses those.

## 1. Documents written tonight

| Document | What |
|---|---|
| [reports/2026-10-25-web-app-ux-reevaluation.md](../../reports/2026-10-25-web-app-ux-reevaluation.md) | Every finding of the 2026-10-08 assessment cited by #24's sub-issues, re-checked on trunk: done / partly / open / obsolete, stale issue text, per-issue recommendation and priority, 10 new problems, overlap map with the dashboard/wizard work |
| [reports/2026-10-25-realtime-sync-inventory.md](../../reports/2026-10-25-realtime-sync-inventory.md) | Every poll, re-sync, TTL, pull-on-join, inbound channel and API publish point, with file:line; stale statements in #66, #121 and the architecture docs |
| [reports/2026-10-25-world-tasks-as-is.md](../../reports/2026-10-25-world-tasks-as-is.md) | World tasks end to end (model, state machine, codes, endpoints, plugin handlers, web polling, identity/presence), 14 verified problems, docs that contradict the code |
| [specs/realtime-signalr/DESIGN.md](../../specs/realtime-signalr/DESIGN.md) | SignalR design: two hubs, envelope, publisher, presence, event catalogue, reliability, world tasks over SignalR with the code fallback; 16 open decisions with proposed defaults |
| [specs/realtime-signalr/IMPLEMENTATION_PLAN.md](../../specs/realtime-signalr/IMPLEMENTATION_PLAN.md) | Phases S1–S6, WT1–WT2, branches, verification |
| [2026-10-24-dashboard-crud-hub-proposal.md](2026-10-24-dashboard-crud-hub-proposal.md) | The other session's design (unchanged except a "Filed" section); still valid on `0d61270` |

## 2. Re-evaluation in short

**Web app (details in the UX report):**
- Since 2026-10-08 the safety quick wins (KNG-141, merged 2026-10-18 — #24 still says "in progress"), Fluent removal,
  the form wizard chain, KNG-39/61/82/94 and invitations closed about a third of the cited findings: error toasts,
  error boundary, 404, account menu, landing, no `alert`/`window.confirm` left (`useConfirm`), wizard step names, a
  Cancel button, form export/import, Display Draft/Publish, explorer drawer, the `/form/` dead route.
- **The admin CRUD core is almost untouched:** CRUD-1/2/4, NAV-6 (dashboard round trip, no New, rows not links, no
  URL state), wizard footer/guard/blur validation, builders leave the page after Save, detail page header, 16 flat
  icon-only nav links. That is exactly what #177 + #58 + #39 + #109 address, so the developer's "dashboard and form
  wizard first" matches the evidence.
- Stale issue text in #24, #109, #71, #33, #139, #122, #104 (listed in the report; corrected by comments tonight).
- New verified problems: drafts/workflow sessions saved as **user 1** for every admin (**#186**, also blocks finding
  the world-task initiator); Game Settings / Siege pages gated on the wrong node (**#185**); the wizard marks a draft
  Completed **before** the entity is saved (added to #177); `ToastRegion` is error-only (success toast needed by
  #177 decision 2); Create New menu offers an unmapped type and misses ~15 mapped ones; detail page heading shows the
  display configuration's name; "Leave this form?" asked even with no changes; 10 pages without a title; a hard-coded
  `isDebugField === 4` debug block in production; logged-out `/join`, `/link`, `/leaderboards` have no header.

**SignalR / sync (details in the inventory):** no push exists except `RegionHttpServer`; a 2 s notification poll on
an in-memory queue lost on API restart; ~12 periodic re-syncs; TTLs mostly 60 s; **no path at all** for gate edits,
web freeze/active mode, group-node and grant edits (until TTL), balance-only changes; `RankChanged` only redraws (root
of part of #76); presence is join/quit only, not reliable enough to auto-claim on. The Java SignalR client fits
(same okhttp version). Alpha nginx already forwards WebSocket upgrades under `/api/`.

**World tasks:** web polls every 2 s, player tasks only via `/knk task-claim <code|id>`; codes unchecked, not unique,
never expire; tasks stay InProgress forever after cancel/quit/restart; double claims possible; creator from the request
body. Hardening (WT1, #180) is needed before or with the SignalR flow (WT2, #181).

## 3. Implementation order

Two tracks that touch different repos, so they can overlap; the developer tests one thing at a time, so the default
below runs them **staggered**: track A first, track B starts once A1 is in review.

### Track A — knk-web-app (+ small API changes), first

| Step | Issues | Content | Notes |
|---|---|---|---|
| **A1** | #177 link 1 (= #58 trimmed) | `/dashboard/:entityName` + last viewed type (localStorage); `returnTo` (reuse the existing sanitizer in `utils/returnTo.ts`, add `buildReturnTo`/`navigateBack`); Dashboard Edit/New carry it; Submit and Cancel honour it; refresh the table on return; **submit pending state** (await `onComplete` inside `saving`, re-entrancy guard, disabled strip/Cancel, "Saving {Type}…"); **save the entity before marking the draft Completed**; minimal **success toast** (a `success` kind on `ToastRegion` + `toast.success()`) replacing the 3 s modal | One branch `claude/kng-60-dashboard-hub` (name from the 2026-10-24 handoff) |
| **A2** | #177 link 2 (+ #81 part a, + #39 CRUD-2 menu) | Header "New {Type}" + ⚙; New in the empty state; open form hides the explorer, shows a breadcrumb (expose a `{label,to}[]` trail #30 can render later); flat explorer with "no display configuration" marker, View disabled; nav "Forms" → "Entity setup" + living docs; **proposed additions:** detail page header (entity name, Edit/Delete/Back with `returnTo`), metadata-driven Create New menu (fixes the unmapped `itemType`, fixes the double `navigate()`) | Q-U3, Q-U4 |
| **A-quick** | #185, #38 | Route gates (two `node=` props + nav); styling quick wins (`primary-dark`, `btn-tertiary`, `.btn inline-flex`) | Tiny PRs; any time, ideally between A1 and A2 test runs |
| **A3** | #109 (re-scoped) + #186 + #64 (FormWizard part) | First remove the debug block/`console.log`s in `FormWizard.tsx` (#64 part); sticky footer holding Cancel, dirty flag (prompt only when changed), `useBlocker` + `beforeunload`, blur validation + error summary, Save from any step in edit mode, single-line input for short strings; **#186** drafts/workflow sessions owned by the caller (API + web) | #186 is also a prerequisite for WT1/WT2 |
| **A4** | #39 remainder + #177 follow-up | `PagedEntityTable` controlled `query`/`onQueryChange` (keep the wizard pickers working), page/search/sort in the URL, rows as links, `aria-sort`; Drafts (n) chip and "New with: {config}" on the dashboard | |
| **A5** | #33 (a), #71, #30 | Accessible `Dialog` (FeedbackModal/ChildFormModal), confirm with reason; builders save in place + Duplicate; admin IA: route-meta table (titles), grouped nav, breadcrumbs | |
| then | #83 | Think-aloud with alpha testers on the new flow (after A2, ideally A4) | |
| later | #81 (b,c), #119, #26 (b,c), #108 quick bits, #139, #95(+#92), #122, #112, #104, #98, #117, #64 rest | per the priorities in the UX report §6 | |

### Track B — knk-web-api + knk-plugin (+ web app for WT2), SignalR

| Step | Issue | Content | Depends on |
|---|---|---|---|
| **B1 = S1** | #178 | Foundation: hubs, envelope, publisher, presence registry, plugin client with reconnect + resync, `realtime.server-id`, docs | design §12 answered |
| **B2 = S2** | #179 | User-state push (ranks, permissions, balances, freeze, mode, notifications over the hub) — the developer's first priority among events | S1 |
| **B3 = WT1** | #180 | World-task hardening (REST): state machine, cancel/release/expiry/lease, checked unique task codes, creator from JWT, plugin/web hygiene, world-tasks docs corrected | #186 (A3) |
| **B4 = WT2** | #181 | World tasks over SignalR: auto-claim for the online initiator, Accept/Decline for admin B, code fallback, live web status | S1, WT1 |
| **B5 = S3** | #182 | Config + entity push (EntityChanged, gates, domain access, settings, siege, lootbox) | S1 (after S2) |
| **B6 = S5** | #184 | Erasure push + catch-up | S1 |
| **B7 = S4** | #183 | Web live updates (dashboard refresh, presence badges) | S1, WT2, A2 |

S2 and WT1 can run in parallel. WT1's web part touches `WorldBoundFieldRenderer.tsx` and the form builder's task-type
list; schedule it after A3 (or coordinate) because A3 owns `FormWizard.tsx`.

### Suggested calendar (one developer test run at a time)

1. A1 → test. Meanwhile: A-quick PRs.
2. A2 → test. Meanwhile: B1 (S1) built (dev server only, `realtime.enabled: false` by default).
3. A3 (+#186) → test; B1 live check.
4. B2 (S2) → test. Then B3 (WT1) → test.
5. B4 (WT2) → test (the world-task experience the developer asked for).
6. A4, B5, then A5, B6, B7, #83.

## 4. Session chain shape (if run as a chain)

Each step above is one link with its own branch per repo and issue, started by the coordinator with the `add_repo`
lines in the prompt (global instructions "Session chains"). A1/A2 can share the branch `claude/kng-60-dashboard-hub`
(one feature); S1–S5 share `claude/realtime-signalr`; WT1 uses `claude/world-task-hardening`, WT2 continues on
`claude/realtime-signalr`.

## 5. GitHub updates made tonight

- **New:** #177 (dashboard CRUD hub, from the 2026-10-24 handoff, sub-issue of #24), #178–#184 (SignalR phases,
  sub-issues of #66), #185 and #186 (bugs, sub-issues of #24).
- **Comments** with the re-evaluation (status, stale text, recommendation, proposed priority) on #24, its
  sub-issues, #58, #39, #66, #76, #121, #68.
- **Not changed:** labels/priorities and bodies of existing issues (proposals are in the comments; Q-U1/Q-U2).

## 6. Decisions I took along the way (reversible)

| # | Decision | Why |
|---|---|---|
| D1 | Used #24 / #66 instead of the given #4 / #32 | Migration report mapping; #4/#32 are something else |
| D2 | Filed the hub issue #177 from the 2026-10-24 handoff ("To file in Linear") | Global instructions: every request gets an issue; Linear is read-only |
| D3 | Merged `claude/tender-cerf-elcye5` (the handoff, docs only) into this branch | Keep the plan and the design it builds on together for one merge |
| D4 | Added two findings to #177 (completed-before-save; error-only toast) instead of separate issues | Both are part of the submit change #177 already specifies |
| D5 | Filed #185 (route gates) and #186 (drafts as user 1) as separate bugs | Small, misleading/incorrect today; #186 also blocks WT1/WT2 |
| D6 | World-task hardening and the SignalR world-task flow are sub-issues of #66 | Developer asked for world tasks over SignalR; WT1 is the groundwork |
| D7 | No label/priority/body edits on existing issues; comments only | The re-scoping is the developer's call (Q-U1, Q-U2) |
| D8 | `docs/specs/world-tasks/*` not corrected yet; the as-is report wins until WT1 | Correct them with the code change so docs and code move together |
| D9 | ACTIVE_SESSIONS claim committed on this branch only | Session rule: push only to the designated branch; the row reaches `main` with the merge |
| D10 | SignalR design proposes defaults for all open points (Q1–Q16) instead of leaving gaps | The developer can accept or change them in one pass |

## 7. Questions for the developer (tomorrow)

**Dashboard / form wizard / UX**

| # | Question | My proposal |
|---|---|---|
| Q-U1 | Accept the re-scoping proposals? #33 split into (a) feedback primitives / (b) data-format primitives; #109 drops clickable steps (→ #68) and CRUD-9; #81 split (header / link-unlink / polish); #26 split (gates = #185 / units+confirms / audit); #104 → separate public site; #92 merged into #95; #38 tokens → #95, lootbox bits → #26 | Yes; I'll edit the issues once confirmed |
| Q-U2 | Priority changes? Proposed: #109 high, #30 high, #33 high (a part), #81 high (a part), #71 medium→medium-high, #122 low, #104 low, #139 medium (unchanged), #83 medium | Yes |
| Q-U3 | Put the detail page header (#81 a) into #177 link 2? | Yes (it is the hub's View target) |
| Q-U4 | Replace the hard-coded Create New menu with a metadata-driven one in #177 link 2 (CRUD-2, from #39)? | Yes |
| Q-U5 | Success toast: add a minimal `success` kind to `ToastRegion` in A1, full kit later (#33a)? | Yes |
| Q-U6 | User rows in the generic dashboard: keep edit there (blocked by #72/#148), or send User Edit to the player profile? | Send to the player profile; the generic form stays for create until #72/#148 are fixed |
| Q-U7 | #186: existing drafts owned by user 1 — leave as they are, or delete completed ones? | Leave; new rows get the right owner |
| Q-U8 | Start SignalR S1 while A2 is being built (staggered, §3), or only after the whole track A? | Staggered |
| Q-U9 | May I rewrite #24's body ("Order" and "Already done") to match the re-evaluation, or keep it as migrated and rely on the comment? | Rewrite |
| Q-U10 | Run the think-aloud (#83) after A2 or after A4? | After A2 (first impressions of the new hub), again later if needed |

**SignalR / world tasks** — DESIGN §12 Q1–Q16, the important ones:
- Q6: auto-claim for the online initiator without asking (they can type `cancel`)? → yes, as requested.
- Q7: initiator busy with another task → queue or code? → queue.
- Q8: admin B gets Accept/Decline (no silent claim), 2 min timeout? → yes.
- Q10: Pending expiry 30 min, lease 3 min, release (not fail) on lease expiry? → yes.
- Q11: rename the world-task "claim code" to "task code" (invitations own "claim code"); drop claiming by numeric id? → yes/yes.
- Q3: generic `EntityChanged` through an EF interceptor (vs. explicit calls in each service)? → interceptor.
- Q16: the 2026-10-08 "SignalR recommendation comment" on KNG-57 is in Linear and I couldn't read it from this
  session; please check it doesn't conflict with the design.

## 7a. Developer decisions (2026-10-26, asked in the session)

**Dashboard / form wizard / UX**
- Q-U1 re-scoping: **accepted** (#33 split, #81 split, #26 split, clickable steps #109 → #68, CRUD-9 own issue, #104 →
  separate public site, #92 under #95, #38 tokens → #95 and lootbox bits → #26).
- Q-U2 priorities: **applied** (#109, #30, #33 (a), #81 (a) high; #122, #104 low; #71 stays medium — no
  medium-high label exists, it is first in line among the mediums).
- Q-U3/Q-U4: **both** into #177 link 2: the detail page header (#81 a) and the metadata-driven Create New menu (no other
  issue plans the menu replacement; #39 CRUD-2 pointed at it and now points to #177).
- Q-U5: **minimal success toast in link 1**, the full kit (#33) later.
- Q-U6: User rows: **Edit opens the player profile**; the generic form stays for create until #72/#148 are fixed.
- Q-U7: #186: **delete all old drafts and workflow sessions** owned by user 1 (one-time cleanup with the fix).
- Q-U8: **SignalR S1 starts while A2 is built.**
- Q-U9: #24 body **rewritten** to match the re-evaluation.
- Q-U10: think-aloud (#83) **after A2**.

**SignalR / world tasks** (recorded in [DESIGN §12](../../specs/realtime-signalr/DESIGN.md)):
- Hubs and Java client as proposed; presence as proposed; periodic re-syncs kept ×4 slower; gate edits apply after
  a running match.
- Publishing: **option A now, option C (outbox) as the long-term target**, because the developer wants to build
  gameplay in the web app, which needs many detailed events and a robust feed. A is built behind one event sink so the
  switch stays local (DESIGN §4.3). Pros/cons and the decision matrix were given in the session; summary: A 29, C 31,
  B 19 of 39 weighted points; C wins on transactions and durability only.
- World tasks: **"Send to Minecraft" = auto** (offered to and claimed by the online initiator); a separate **"Hand off
  to…"** action; **busy check before sending** with Queue / Hand off / Replace / Cancel; admin B gets **Accept/Decline,
  2 min**; expiry 30 min, lease 3 min, release; **rename to "task code"**; id claims only with `knk.tasks.any`.
- New requirement from the answers: **world tasks anchored to the draft** so a task can always be found again from its
  form submission (DESIGN §8.7, part of #180): one session per draft, task linked to the draft and field, silent draft
  save on the first task, reattach and apply finished results on mount.
- Q9, Q13–Q15 confirmed (second round, 2026-10-26). Q16 closed: the 2026-10-08 Linear comment is superseded by this
  design.

**Second round (2026-10-26)**
- #192 (claim code dash, test run 1): **keep `XXXX-XXXX`**, the web fields show the separator themselves (players type or
  paste 8 characters); dash or space on the disconnect screen: **ask one or two testers first**.
- World tasks: Replace **releases** the held task (not cancel); sessions without a draft removed after **7 days**; the
  first task **saves the draft silently**.
- #71 stays medium; #38 raised to **medium**; #186 cleanup is a **script after a backup** (`scripts/maintenance/`).
- #104: **English only** for now; multi-language much later.
- #92: a **Light / Dark / System toggle in the account menu on all pages** (remembered per browser, dark palette on the
  #95 tokens), so testers can see both and give feedback; this replaces the "light admin / dark public" choice for now.

## 8. Next step

Start A1 (#177 link 1) from this plan and the 2026-10-24 handoff. S1 (#178) starts while A2 is built. No open questions.
