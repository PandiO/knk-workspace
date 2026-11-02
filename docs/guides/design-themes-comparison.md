# Design themes: live comparison (rebrand phase 1, #95)

**Status:** Written 2026-11-02 for knk-web-app `claude/design-tokens-95`; not merged, not compared yet
**Last updated:** 2026-11-02
**Issue:** [PandiO/knk-workspace#95](https://github.com/PandiO/knk-workspace/issues/95) (token layer, contrast rules,
switchable themes); [#92](https://github.com/PandiO/knk-workspace/issues/92) (rebrand phases 2–4, sub-issue) holds the
open decisions below
**Branches:** knk-web-app `claude/design-tokens-95` (on `main` `1c9524d`); knk-workspace `claude/design-tokens-95` (this
guide, the architecture section, CHANGELOG, screenshots). No API or plugin change, no migration, no setting (one
optional build flag, below).
**Background:** [UX assessment §11](../reports/2026-10-08-web-app-ux-assessment.md#11-brand-alignment) (brand guide, gap
table, token design, contrast rules); brand guide `docs/vision/brand/huisstijlhandboek.pdf`.

The web app has three themes. Each one is a set of CSS variables; switching changes one attribute on the page, so it
is instant and needs no reload. Use them to compare designs in the running app, then decide which direction the
rebrand takes (#92).

## 1. How to switch

- **Account menu** (top right, the person icon) → **Theme (design comparison)** → Current / Brand / Proposal. The menu
  stays open, so you can flip back and forth. The choice is saved in this browser (localStorage) for every tab.
  - Shown to staff only: anyone with the moderator node (`knk.admin.user.manage`) or the content node
    (`knk.admin.content`). Players never see it.
  - Build flag `REACT_APP_THEME_PICKER`: `on` shows it to every logged-in user (local testing), `off` hides it for
    everyone. Unset = staff only.
- **URL:** add `?theme=current`, `?theme=brand` or `?theme=proposal` to any page. It applies to that tab only (it
  survives reloads and navigation in the tab), so two tabs can show two themes side by side. It works logged out too
  (landing, login), for anyone; it is harmless, as it only changes colours.
- No storage (private window, blocked site data): the picker and the URL parameter still work for the open tab.

Example side by side: `https://<host>/dashboard?theme=current` in one tab and `…/dashboard?theme=brand` in another.

## 2. What each theme changes

| | `current` (default) | `brand` | `proposal` ("calm brand") |
|---|---|---|---|
| Idea | Today's look, rebuilt on tokens | The 2020 styleguide as written | Brand colours used sparingly; red only means danger |
| Primary (buttons, links, focus) | Blue `#2563EB` | Brand red `#BE1622` | Charcoal `#353535`; focus ring dark orange |
| Call to action (landing "Create account") | Green (darker: AA fix) | Orange `#F29100`, black text | Orange, black text |
| Navigation bar | White | Black, orange active underline | Charcoal, orange active underline |
| Neutrals (all `gray-*`/`slate-*`) | Tailwind's cool greys | Pure greys around charcoal | Warm "parchment" greys |
| Page background | Light grey | Light grey | Parchment `#F5F2EC` |
| Login / register / link pages | Light backdrop | Black backdrop (the guide's "black for contrast") | Charcoal backdrop |
| Danger | Red | Red (close to brand red: icon + text always) | Brand red (`#BE1622`) |
| Info boxes | Blue | Charcoal/grey (the guide has no blue) | Steel blue |
| Body font | System sans (Inter was never loaded; unchanged) | Lato 2.015 | Lato 2.015 |
| Headings (h1, h2, the nav title) | Body font | Cinzel (stand-in for Enchanted Land) | Cinzel |

Fonts: **Lato 2.015** (the latofonts.com release with Regular 400, Medium 500, SemiBold 600 and Bold 700; Google's Lato
has no 500/600) and **Cinzel** 600/700, both self-hosted under the SIL OFL 1.1 (`src/theme/fonts/`, licences next to
them). Enchanted Land is **not** used: its licence is open (#92 Q6). Cinzel is a free Roman-capitals display face picked
as a placeholder; it is legible, but it is not calligraphic like Enchanted Land. A browser only downloads a font once a
theme uses it, so `current` loads none of them.

**`current` vs `main`:** the same, apart from these accessibility fixes (they apply in every theme):

- Secondary text: `text-gray-400` (2.5:1 on white) → `text-muted` (4.5:1 or more), in all 50+ files. Disabled and
  placeholder text keep `gray-400` (WCAG exempts them).
- Form fields: every text field gets a 2px focus ring (about 104 fields had none); field borders are darker (3:1, was
  1.5:1); a field in the error state shows a red border (it had none); every field error has an alert icon in front.
- Primary button hover goes darker instead of lighter (white on the lighter blue was 3.7:1); button focus rings are
  solid instead of 50 % transparent.
- Status text is a shade darker where it failed AA: green and amber text and buttons (`-600` → `-700`), danger red a
  hair darker on the grey page background.

## 3. Checklist for the live comparison

Compare in this order; the first five are fully on tokens, so they are a fair comparison (see § 5 for the rest).

1. **Landing** (`/`, logged out): CTA colour and text, the "Closed alpha" badge, headings (Cinzel in brand/proposal).
2. **Login** (`/auth/login`): backdrop (light / black / charcoal), card, field focus ring (Tab into a field), an
   error (wrong password).
3. **Dashboard** (`/dashboard/<type>`): navigation bar, explorer, table head and rows, selected row, New/Configure
   buttons, a success toast (save something).
4. **Form wizard** (New on the dashboard): step header, fields, a required field left empty → Next (error border, icon,
   error summary), Save Draft / Previous / Next buttons.
5. **Entity detail** (open a row): header, sections, action buttons (Edit, Delete — danger stays readable as danger).
6. **Player profile** (Moderation → a player; and `/players/<name>`): badges, tabs, the danger actions (ban, lock).
7. Keyboard: Tab through the nav, the account menu (arrow keys), a form: the focus ring is visible in every theme.
8. Phone width (or the browser's device mode): the nav menu button and its panel in each theme.
9. Decide: which theme (or which parts of each) becomes the rebrand; note it on #92 with the answers to Q6/Q7 below.

Screenshots of the screens in each theme (taken with mocked data):
[`reports/assets/2026-11-design-themes/`](../reports/assets/2026-11-design-themes/).

## 4. Open decisions (#92)

- **Q6 heading font:** buy the Enchanted Land webfont licence, or keep a free stand-in (Cinzel now) or Lato headings
  plus an SVG wordmark? With the licence, add the font files under `src/theme/fonts/` and set `--font-display` in the
  brand theme.
- **Q7 light/dark split:** a light admin with a dark public side (recommended in the assessment; the brand and
  proposal themes show this with the dark auth backdrop and nav), or dark everywhere? A full dark admin theme is not
  built: it would be a fourth token set, and the screens below still on raw colours would need migrating first.
- **Primary colour:** brand red as the primary (brand) or charcoal with red kept for danger (proposal)? Brand red and
  error red are close, so with `brand` every danger state relies on its icon and text.
- **Which theme becomes the default**, and whether the picker stays (for example as a player-facing dark/light
  choice) or goes once the rebrand is decided.

## 5. Coverage: what is on tokens

All screens follow a theme's **neutrals**, primary colour, nav and fonts: the `gray-*`/`slate-*` ramps and `primary`
are theme variables. What differs per screen is whether its **status and accent colours** (blue, red, green, amber)
were moved to tokens; where not, they stay Tailwind blue/red/green in every theme.

Migrated (codemod `scripts/codemods/tokens-95.js` in knk-web-app): the navigation and account menu, toasts, Create New
menu, breadcrumbs, the shared button/input/panel classes, the dashboard (`ObjectDashboard`, explorer, `PagedEntityTable`),
the form wizard (`FormWizardPage`, every `FormWizard/*` component), the entity detail page (`DisplayWizard/*`), the
admin player profile and the public player profile, the landing page CTA and all auth pages and forms.

Not migrated (still raw blue/red/green/amber in places; neutrals do follow the theme): the form and display
configuration builders, Game Settings and its cards, Siege settings, lootboxes, discovery, roads, Minecraft catalogue,
invitations and mail admin, moderation list, economy pages, owner pages (diagnostics, privacy, analytics),
leaderboards and statistics, siege match pages, account pages, world-task renderers (`Workflow/*`). `npm run
lint:colors` in knk-web-app lists them with counts and reports any file that gains raw colour classes.
