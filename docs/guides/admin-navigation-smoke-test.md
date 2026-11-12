# Web app admin navigation: route table, admin sidebar, breadcrumbs (#30) — smoke test

**Status:** Written 2026-11-05 for knk-web-app `claude/admin-ia-30` (chain 2 link W4); **merged 2026-11-12** (knk-web-app `main` `1371951`); not run by the developer
**Last updated:** 2026-11-12 (merged; run on `main`, docs #340); 2026-11-06 (§ 1: Dashboard kept in the bar, LW4-1)
**Issues:** [PandiO/knk-workspace#30](https://github.com/PandiO/knk-workspace/issues/30) (layout routes, route-meta
table, grouped admin sidebar, breadcrumbs; sub-issue of [#24](https://github.com/PandiO/knk-workspace/issues/24));
[#262](https://github.com/PandiO/knk-workspace/issues/262) (Invitations link never showed)
**Branches:** merged 2026-11-12 into knk-web-app `main` `1371951` (with #197, #187, #33 and chain 3 V1–V7); the
feature branch was knk-web-app `claude/admin-ia-30`. No API or plugin change, no migration, no setting.
**Chain:** [UX_CHAIN_2.md](../ai-agents/handoffs/UX_CHAIN_2.md) link W4; report
[2026-11-05-ux-chain-2.md](../reports/2026-11-05-ux-chain-2.md) (W4 block). Design notes:
[web-app architecture § Routes, layouts and the admin sidebar](../architecture/web-app-architecture.md#routes-layouts-and-the-admin-sidebar).

Web app only: knk-web-app `main` (from `1371951`), `npx npm@11 ci` if needed, `npm start`, against the dev
API on trunk. You need **two accounts**: the owner (or an admin with `*`), and a **staff account with only some
nodes**, for example `knk.admin.currency.history`, `knk.admin.invites`, `knk.admin.config` and
`knk.admin.location.orphans` and **not** `knk.admin.user.manage` (grant them on a test user in its player profile,
or a test group). Run the sections in the `current` and the `brand` theme (cogwheel theme switcher), once with the
page background on and once off, and sections 2 and 4 once at phone width (390 px). Record each step in
**Findings** at the end. Because the branch contains #197, #187 and #33, their smoke tests can run on the same
checkout ([dashboard return § 14a](dashboard-return-smoke-test.md), [data primitives](data-primitives-smoke-test.md),
[feedback primitives](feedback-primitives-smoke-test.md)); § 14a holds as written for the bar's **Dashboard** (kept
in the bar, LW4-1), and the sidebar's **Dashboard** is highlighted on the same pages.

What changed for you: the top bar has **Home, Leaderboards, Guides, Dashboard** (content staff only) **and Admin**;
every admin page is in a grouped
sidebar (Content, World, Players & support, Economy, Settings, Owner) that lists only what your permissions open;
every admin page has a breadcrumb trail and a tab title; **Admin** opens an overview of your pages. URLs are
unchanged.

## 1. The bar

1. As the owner: the bar reads **Home, Leaderboards, Guides, Dashboard, Admin** (labels, icons only or the menu
   button, depending on the width). **Dashboard** stays in the bar (LW4-1, developer's decision 2026-11-06) for staff
   who may open the dashboard (`knk.admin.content`, the same check as the dashboard page). No Game Settings,
   Moderation, … links in the bar any more.
2. **Dashboard** is underlined (current) on the dashboard (`/dashboard`, `/dashboard/Town`), Entity setup (`/forms`,
   `/forms/Town`, an open form), the form and display builders and a detail page (View on a row); **Admin** is not
   underlined there. **Admin** is underlined on every other admin page: `/admin`, Minecraft catalogue, Moderation,
   Game settings, Diagnostics; **Dashboard** is not. On Leaderboards, Leaderboards is current; on a public player
   profile (`/players/{name}`) too; on the enchantment guide, Guides.
3. Log in as a player without any staff node: **Home, Leaderboards, Guides** only; `/admin` says "No admin pages".

## 2. The admin sidebar (owner)

1. **Admin** → `/admin`: cards per group with each page and one line on what it is for: Content (Dashboard,
   Minecraft catalogue), World (Lootboxes, Domain discovery, Road network, Orphaned Locations), Players & support
   (Player moderation, Invitations), Economy (Balance event log, Currency policy, Currency alerts), Settings (Game
   settings, Siege settings, Mail log), Owner (Diagnostics, Data deletion requests, World analytics). No sidebar next
   to the overview.
2. Open any page from there. From 1280 px wide the grouped sidebar is on the left, the page's link highlighted. The
   sidebar stays put when the page scrolls.
3. Pages below a sidebar page keep its link highlighted: a player profile (Moderation → a row) → **Player
   moderation**; a transaction (Balance event log → a row) → **Balance event log**; Entity setup (Dashboard → ⚙), a
   form builder (Create Form) and a detail page (View) → **Dashboard**.
4. Below 1280 px (and at 390 px): an **Admin pages** button above the page opens the same list; a choice, Escape or a
   click outside closes it. Nothing scrolls sideways (except Entity setup at 390 px, which already did on `main`:
   see the W4 block).
5. **Invitations** is in the sidebar (#262: the old nav link never showed, not even for the owner).

## 3. Breadcrumbs and titles

1. Game settings: trail **Settings › Game settings**, page heading "Game settings" (was "Game Manager Settings"),
   tab "Game settings · Knights & Kings". Siege settings: heading "Siege settings" (was "Siege configuration").
2. A player profile: **Players & support › Player moderation › Player profile**; "Player moderation" goes back to
   the list; "Players & support" opens `/admin` at that group.
3. A transaction: **Economy › Balance event log › Transaction**.
4. Dashboard → Town: **Content › Dashboard**; the dashboard still fills the window without a page scrollbar.
5. ⚙ on Town (Entity setup): **Content › Dashboard › Town › Entity setup** (LW1-2: the lists had no way back
   before). "Town" opens the dashboard on Town.
6. Edit a row (open form): **Content › Dashboard › Town › Edit {name}** (the form's own trail, now with the group in
   front). With unsaved changes a crumb still asks "Leave this form?".
7. View a row (detail page): **Content › Dashboard › Town › {name}**; tab "{name} · Town · Knights & Kings".
8. Create Form on Entity setup: **Content › Dashboard › Entity setup › Form builder**.
9. Tab titles on pages that had none: Road network, Mail log, Invitations, Minecraft catalogue, Leaderboards,
   Diagnostics, Data deletion requests, World analytics, Orphaned Locations, a public player profile ("Player").
10. Old URLs still work: `/admin/form-configurations` and `/admin/display-configurations` open Entity setup; every
    bookmark of an admin page opens the same page as before.

## 4. Staff account with only some nodes

Log in with the partial account (see the top: currency history, invites, config, orphaned locations; no moderator
node).

1. The bar has **Admin** but no **Dashboard** (no `knk.admin.content`). `/admin` and the sidebar list exactly: World (Orphaned Locations), Players & support
   (Invitations), Economy (Balance event log), Settings (Game settings, Mail log). No Moderation, Dashboard,
   Siege settings, Currency policy/alerts, Owner.
2. **Balance event log** and **Orphaned Locations** open from the sidebar (before #30 they were buttons on
   Moderation only, which this account can't open).
3. Type `/admin/users` (Moderation): "Staff only … needs the `knk.admin.user.manage` permission", with the sidebar
   still there. Type `/admin/siege-configuration`: the same for `knk.siege.admin.manage`.
4. At 390 px: **Admin pages** lists the same five pages; the trail sits under the button.

## 5. Themes, background and errors

1. In `brand` with the background on: the sidebar is a translucent card like the others, the current link has an
   orange tint, group headings are muted capitals; with the background off the same on the plain page colour. In
   `current`: the same in blue.
2. A page that fails to render (if you meet one) shows "Something went wrong on this page" **inside** the admin
   layout: the bar and the sidebar keep working (one error boundary per layout, X-4).

## Findings

| Step | Result | Notes |
|---|---|---|
| | | |
