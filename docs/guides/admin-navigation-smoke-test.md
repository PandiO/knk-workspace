# Web app admin navigation: route table, admin sidebar, breadcrumbs (#30) — smoke test

**Status:** automated in CI; manual steps not run. Written 2026-11-05 for knk-web-app `claude/admin-ia-30` (chain 2 link W4); **merged 2026-11-12** (knk-web-app `main` `1371951`); 20 of 24 steps automated 2026-11-14 ([#511](https://github.com/PandiO/knk-workspace/issues/511)); found there: [#535](https://github.com/PandiO/knk-workspace/issues/535) (Mail log and Invitations scroll sideways at 390 px)
**Last updated:** 2026-11-14 (steps marked `[automated]` with their test, backfill #511); 2026-11-12 (merged; run on `main`, docs #340); 2026-11-06 (§ 1: Dashboard kept in the bar, LW4-1)
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

Steps marked `[automated]` run in CI (knk-web-app Playwright spec `e2e/admin-navigation.spec.ts`, CI job `e2e`, and the Jest tests next to the
layout, CI job `build-and-test`); you don't repeat them. Left for you: the themes, the sticky sidebar, three trails.

## 1. The bar

1. [automated] As the owner the bar reads **Home, Leaderboards, Guides, Dashboard, Admin**, no Game Settings or
   Moderation links: `e2e/admin-navigation.spec.ts`
2. [automated] **Dashboard** is current on the dashboard and Entity setup, **Admin** on the other admin pages,
   Leaderboards on Leaderboards: `e2e/admin-navigation.spec.ts`, `src/layouts/__tests__/AdminLayout.test.tsx`
3. [automated] A player without staff nodes: **Home, Leaderboards, Guides** only; `/admin` says "No admin pages": `e2e/admin-navigation.spec.ts`

## 2. The admin sidebar (owner)

1. [automated] `/admin` lists every group with each page and what it is for, without a sidebar: `e2e/admin-navigation.spec.ts`, `src/layouts/__tests__/AdminLayout.test.tsx`
2. [automated] From 1280 px the grouped sidebar is there with the page's link current: `e2e/admin-navigation.spec.ts`. *(Manual, a look: the
   sidebar stays put when the page scrolls.)*
3. [automated] Pages below a sidebar page keep its link current (player profile → Player moderation, a transaction →
   Balance event log, the dashboard → Dashboard): `e2e/admin-navigation.spec.ts`, `src/layouts/__tests__/AdminLayout.test.tsx`
4. [automated] Below 1280 px the **Admin pages** button opens the list; Escape, a click outside and a choice close it; at
   390 px nothing scrolls sideways on Game settings: `e2e/admin-navigation.spec.ts`. Mail log and Invitations do scroll sideways at 390 px:
   [#535](https://github.com/PandiO/knk-workspace/issues/535).
5. [automated] **Invitations** is in the sidebar (#262): `e2e/admin-navigation.spec.ts`

## 3. Breadcrumbs and titles

1. [automated] Game settings: trail **Settings › Game settings**, heading "Game settings", tab "Game settings ·
   Knights & Kings": `e2e/admin-navigation.spec.ts`
2. [automated] A player profile: **Players & support › Player moderation › Player profile**; "Players & support"
   opens `/admin` at that group: `e2e/admin-navigation.spec.ts`
3. [automated] A transaction: **Economy › Balance event log › Transaction**: `e2e/admin-navigation.spec.ts`
4. [automated] Dashboard → Town: **Content › Dashboard**, the dashboard fills the window without a page scrollbar: `e2e/admin-navigation.spec.ts`
5. [automated] ⚙ on Town (Entity setup): **Content › Dashboard › Town › Entity setup**; "Town" opens the dashboard on
   Town: `e2e/admin-navigation.spec.ts`
6. *(Manual, not automated yet.)* Edit a row (open form): **Content › Dashboard › Town › Edit {name}**; with unsaved
   changes a crumb still asks "Leave this form?".
7. [automated] View a row (detail page): **Content › Dashboard › Town › {name}**, tab "{name} · Town · Knights &
   Kings": `src/pages/__tests__/DisplayWizardPage.header.test.tsx`, `src/layouts/__tests__/AdminLayout.test.tsx` ("lets a page draw its own trail")
8. *(Manual, not automated yet.)* Create Form on Entity setup: **Content › Dashboard › Entity setup › Form builder**.
9. [automated] Tab titles on Road network, Mail log, Invitations, Minecraft catalogue, Leaderboards, Diagnostics, Data
   deletion requests, World analytics, Orphaned Locations: `e2e/admin-navigation.spec.ts`
10. [automated] `/admin/form-configurations` and `/admin/display-configurations` open Entity setup: `e2e/admin-navigation.spec.ts`, `src/layouts/__tests__/AdminLayout.test.tsx`

## 4. Staff account with only some nodes

1. [automated] The bar has **Admin** but no **Dashboard**; `/admin` lists exactly Orphaned Locations, Invitations,
   Balance event log, Game settings, Mail log: `e2e/admin-navigation.spec.ts`, `src/layouts/__tests__/AdminLayout.test.tsx`
2. [automated] **Balance event log** and **Orphaned Locations** open from the sidebar: `e2e/admin-navigation.spec.ts`
3. [automated] `/admin/users` and `/admin/siege-configuration` say "Staff only" with the node, the sidebar stays: `e2e/admin-navigation.spec.ts`
4. [automated] At 390 px **Admin pages** lists the same five pages: `e2e/admin-navigation.spec.ts`

## 5. Themes, background and errors

1. *(Manual: visual check of the themes.)* In `brand` with the background on: the sidebar is a translucent card like the
   others, the current link has an orange tint, group headings are muted capitals; with the background off the same on
   the plain page colour. In `current`: the same in blue.
2. *(Manual: needs a page that fails to render.)* A page that fails to render shows "Something went wrong on this page"
   **inside** the admin layout: the bar and the sidebar keep working (one error boundary per layout, X-4).

## Findings

| Step | Result | Notes |
|---|---|---|
| | | |
