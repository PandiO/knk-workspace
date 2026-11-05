# Design themes: live comparison (rebrand phase 1, #95)

**Status:** Compared live by the developer on 2026-11-03 (all screens work; `brand` preferred, all three themes and the
picker stay); fix round done on knk-web-app `claude/design-tokens-95` (§ 6). Merged 2026-11-03 (knk-web-app `main` `c02b365`)
**Last updated:** 2026-11-04 (§ 7 page background, #231: approved, on by default; toggle in the cogwheel menu); 2026-11-04 (theme
switcher as a cogwheel for every visitor, knk-web-app `main` `865fe53`); 2026-11-03 (fourth theme `brand-red`); 2026-11-03 (fix round after the live comparison: brand primary orange, heading font on player pages
only, full-bleed auth pages, picker for alpha testers)
**Issue:** [PandiO/knk-workspace#95](https://github.com/PandiO/knk-workspace/issues/95) (token layer, contrast rules,
switchable themes); [#92](https://github.com/PandiO/knk-workspace/issues/92) (rebrand phases 2–4, sub-issue) holds the
open decisions below
**Branches:** knk-web-app `claude/design-tokens-95` (on `main` `1c9524d`); knk-workspace `claude/design-tokens-95` (this
guide, the architecture section, CHANGELOG, screenshots). No API or plugin change, no migration, no setting (one
optional build flag, below).
**Background:** [UX assessment §11](../reports/2026-10-08-web-app-ux-assessment.md#11-brand-alignment) (brand guide, gap
table, token design, contrast rules); brand guide `docs/vision/brand/huisstijlhandboek.pdf`.

The web app has four themes. Each one is a set of CSS variables; switching changes one attribute on the page, so it
is instant and needs no reload. Use them to compare designs in the running app, then decide which direction the
rebrand takes (#92).

## 1. How to switch

- **Theme switcher** (the cogwheel) → Current / Brand / Brand (red) / Proposal, each with a one-line description. The
  menu stays open, so you can flip back and forth. The choice is saved in this browser (localStorage) for every tab.
  - **Every visitor sees it**, logged in or not (developer request 2026-11-04, so new visitors can try the themes
    too): logged in it sits in the navigation bar, left of the account menu; logged out (landing, login, register and
    the other auth pages) it floats in the top-right corner. On a phone the menu spans the window under the bar.
  - Keyboard: Enter, Space or ArrowDown opens it on the selected theme; arrows, Home and End move; Escape closes it
    and puts the focus back on the cogwheel.
  - Build flag `REACT_APP_THEME_PICKER=off` hides it for everyone (the URL parameter below still works); unset or any
    other value shows it. Until 2026-11-04 the picker was a group in the account menu, for staff only, and the alpha
    build set `on` to show it to testers; that is no longer needed.
- **URL:** add `?theme=current`, `?theme=brand`, `?theme=brand-red` or `?theme=proposal` to any page. It applies to that tab only (it
  survives reloads and navigation in the tab), so two tabs can show two themes side by side. It works logged out too
  (landing, login), for anyone; it is harmless, as it only changes colours.
- No storage (private window, blocked site data): the picker and the URL parameter still work for the open tab.

Example side by side: `https://<host>/dashboard?theme=current` in one tab and `…/dashboard?theme=brand` in another.

## 2. What each theme changes

`brand-red` (added 2026-11-03 at the developer's request, to choose between red and orange quickly) is `brand` with
one difference: the primary family (buttons, links, focus ring, Create New) is brand red `#BE1622` with white text, as
`brand` had until the fix round of 2026-11-03. Everything else is `brand`'s: black nav, Lato,
Enchanted Land on player-facing pages, the full-bleed dark auth and landing. Primary and danger are the same red again
there, so Edit and Delete differ only by icon and label (every danger state keeps its icon and text).

| | `current` (default) | `brand` (`brand-red`: primary red) | `proposal` ("calm brand") |
|---|---|---|---|
| Idea | Today's look, rebuilt on tokens | The 2020 styleguide as written | Brand colours used sparingly; red only means danger |
| Primary (buttons, links, focus) | Blue `#2563EB` | Orange `#F29100` with black text; links, borders and focus in a darker orange (`#A35200`) | Charcoal `#353535`; focus ring dark orange |
| Call to action (landing "Create account") | Green (darker: AA fix) | Orange `#F29100`, black text | Orange, black text |
| Navigation bar | White | Black, orange active item, orange Create New (red Create New in `brand-red`) | Charcoal, orange active underline |
| Neutrals (all `gray-*`/`slate-*`) | Tailwind's cool greys | Pure greys around charcoal | Warm "parchment" greys |
| Page background | Light grey | Light grey | Parchment `#F5F2EC` |
| Login / register / link pages, landing | Light backdrop inside the page padding (as before) | Full-bleed black backdrop (the guide's "black for contrast") | Full-bleed charcoal backdrop |
| Danger | Red | Red (differs from the orange primary; icon + text always) | Brand red (`#BE1622`) |
| Info boxes | Blue | Charcoal/grey (the guide has no blue) | Steel blue |
| Body font | System sans (Inter was never loaded; unchanged) | Lato 2.015 | Lato 2.015 |
| Page titles (h1) on player-facing pages | Body font | Enchanted Land (demo) | Cinzel |
| Headings on manager and admin pages, the nav title | Body font | Lato | Lato |

Fonts: **Lato 2.015** (the latofonts.com release with Regular 400, Medium 500, SemiBold 600 and Bold 700; Google's Lato
has no 500/600) and **Cinzel** 600/700, both self-hosted under the SIL OFL 1.1 (`src/theme/fonts/`, licences next to
them). A browser only downloads a font once a theme uses it, so `current` loads none of them.

**Where the heading font goes (developer's rule, 2026-11-03):** the decorative heading font (Enchanted Land in `brand`,
Cinzel in `proposal`) is for **player-facing pages only**: landing, the auth pages, leaderboards and statistics, the
public player profile, siege match pages, the player's own account pages, the data-deletion confirmation and 404.
Manager and admin pages (dashboard, entity detail, form wizard, admin pages) and the nav title use Lato. The brand
guide itself sets no such limit: it names Enchanted Land as the heading font ("koptekst") for communication with
Lato as the body text; the split is the project's own rule. In code: a player-facing page calls `usePublicSurface()`
(`src/theme/surface.ts`), which marks `<html data-surface="public">`; only `h1`s under it get `--font-display`.

**Lato** stays the body and secondary font in `brand` (and `proposal`): the developer likes it, for example in the
dashboard tables (`PagedEntityTable`).

**Enchanted Land** (the guide's heading font, Dennis Ludlow / Sharkshock) is in `brand` since 2026-11-02 (developer
decision: try it while the project is a non-commercial hobby, to judge readability and accessibility). Notes:

- It is the **free demo** (`src/theme/fonts/enchanted-land-demo.woff2`, converted from the fontspace TTF, file
  otherwise unmodified; its readme is kept next to it, which the demo licence requires). Free for personal use;
  Sharkshock counts use as commercial once it "results in a personal, business, or corporate financial gain" (any
  income, also donations or a store): then a **webfont licence** is needed (sharkshock.net/license, one-time price,
  no page-view limits) and the full version can replace the demo.
- The demo draws only letters, digits, space, `!`, `.` and a few accented letters; other punctuation and most accents
  (`& ' - , : ?`, `é`, ...) are empty glyphs. The font face has a `unicode-range` of the drawn characters, so those
  fall back to Lato (visible in "Knights & Kings").
- One weight: headings are not faux-bolded. The designer advises against all caps.
- Things to judge: legibility of titles at 24–30px and how it sits next to Lato. `proposal` keeps Cinzel, so the two
  can be compared.

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

Compare in this order; the first six are on tokens, so they are a fair comparison (see § 5 for the rest).

1. **Landing** (`/`, logged out): CTA colour and text, the "Closed alpha" badge, headings (Enchanted Land in brand,
   Cinzel in proposal).
2. **Login** (`/auth/login`): backdrop (light / full-bleed black / full-bleed charcoal), card, field focus ring (Tab into a field), an
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

### Results of the developer's live comparison (2026-11-03)

Relayed by the UX/realtime chain coordinator. All screens work; the developer likes `brand`. All three themes and the
picker stay, so testers can try them too. Requested and done in the fix round (§ 6):

1. `brand` primary from red to the guide's orange (the orange of the selected nav item), with AA contrast; danger
   stays red, the red stays as an accent.
2. Enchanted Land only on player-facing pages; Lato on manager/admin headings and the nav title; the same split for
   Cinzel in `proposal`.
3. Lato stays the body/secondary font in `brand` (liked in the `PagedEntityTable`): no change.
4. The inset dark box on the auth pages looked odd: full-bleed backdrop for the auth and landing layout in `brand` and
   `proposal` (a prioritised #92 phase 2 item; the rest of phase 2 stays open). `current` keeps its layout.
5. The picker for testers: the alpha build set `REACT_APP_THEME_PICKER=on`; the app default stayed staff only.
   (Superseded 2026-11-04: the cogwheel switcher shows for every visitor, § 1.)

### Findings from the screenshots (2026-11-02, mocked data)

Things to look at in the live comparison. None of them block a decision.

- **brand (fixed 2026-11-03):** primary and danger were the same red, so Edit and Delete on the detail page differed
  only by icon and label. With the orange primary they differ by colour too.
- **brand / proposal, auth pages (fixed 2026-11-03):** the dark backdrop was a box inset from the window edges (the
  app's page padding around every route); it is full-bleed now.
- **proposal:** primary links are charcoal like the body text, so they are underlined in this theme. Create New in the
  charcoal bar uses the orange call-to-action colour (token `nav-action`).
- **Every theme:** colours on unmigrated components stay fixed: the purple "Patron" chip and yellow mode chip on the
  player profile, the green Edit / blue-grey View chips on the detail page's child cards.
- **brand / proposal (fixed 2026-11-03):** the fixed navigation bar had rounded corners and a border on every side
  (`.panel`): light notches at both ends of the dark bar, and in `brand` a red outline (the developer's report). The bar
  now has square corners and a bottom border only, in every theme; no red line under it.
- Seen in every theme and unrelated to colour (not changed here): the table search box on the dashboard is shorter
  than the explorer search; the form wizard's sticky footer is see-through and the "Town (Town) 9 fields" box above
  it looks like debug output; the detail page shows raw ISO dates.

## 4. Open decisions (#92)

Decided 2026-11-03 (developer, after the live comparison):

- **Q6 heading font:** Enchanted Land on player-facing pages only (Lato elsewhere); the demo for now; buy the webfont
  licence before the project has any income, and swap in the full version then.
- **Q7 light/dark split:** a light admin with a dark public/auth side. The full-bleed dark auth and landing layout is
  done; the rest of #92 phase 2 (dark public pages beyond auth and landing) stays open.
- **Primary colour in `brand`:** orange (was red); red is an accent and danger.

Still open:

- **Which theme becomes the default**, and whether the picker stays after the alpha (for example as a player-facing
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

## 6. Fix round after the live comparison (2026-11-03)

knk-web-app `claude/design-tokens-95` `64feecc`:

- **Orange primary in `brand`:** `--color-primary` `#F29100` with black `--color-primary-fg`; hover `#DE8000`.
  `text-primary`, `border-primary` and `ring-primary` read new tokens (`--color-primary-text` `#A35200`, 5:1 on the
  canvas; `--color-primary-text-dark`; `--color-primary-line` `#C46A00`, 3:1) through Tailwind's `textColor` /
  `borderColor` / `ringColor`, so no component changed for that. Text on a filled primary is `text-primary-fg` (36
  swaps of `text-white`, codemod pass `--primary-fg-only`). Focus is the dark orange; the bar's own controls use a new
  `--color-nav-focus` (orange on the black/charcoal bar). (The red line under the black bar was removed again the same day: see below.)
- **Heading font split:** `usePublicSurface()` in 16 player-facing pages; `h1` gets `--font-display` only under
  `data-surface="public"`. The nav title and the dashboard/detail titles are back on the body font.
- **Full-bleed auth and landing** in `brand` and `proposal` (`.public-full-bleed`: fixed to the window, below the nav).
- Contrast test updated for the new tokens (primary text/line, nav focus); a test for the surface hook.
- **Navigation bar** (developer's report 2026-11-03, `a47767e`): a thin red outline with red rounded corners around the
  bar in `brand`. The bar no longer uses `.panel`: bottom border only, square corners, in every theme (`current` loses
  its barely visible side borders and rounding); `brand`'s bar edge is dark grey instead of red. Checked in `brand`,
  `brand-red` and `proposal` at 1440 and 390 px.

## 7. Page background: landing image 1 behind every page (#231)

**Status:** approved by the developer on 2026-11-04 after the live comparison, **on by default** for every visitor;
merged 2026-11-04 into knk-web-app `main` `1cbee21` (from `claude/page-background-image-231` `6c4892c`). Turned off (by the visitor or the build), every page is pixel-identical to the app without it. Issue
[PandiO/knk-workspace#231](https://github.com/PandiO/knk-workspace/issues/231).

The landing page's image 1 sits fixed behind every page (`object-fit: cover`, so it fills the window at every width
without stretching). The colours that cover it today stay, but as translucent layers, so the image shows through.
Works in all four themes.

### How to switch

Without a choice of their own, every visitor gets the background. To turn it off or on again:

- **Theme switcher** (the cogwheel, § 1) → **Background image**, the last item under the four themes (a tick when on).
  Same visibility as the themes: every visitor, logged in (in the navigation bar) or out (floating top right); hidden
  only with `REACT_APP_THEME_PICKER=off`. Switches at once, the menu stays open; saved in this browser (localStorage)
  for every tab. Keyboard: End jumps to it.
- **URL:** `?bg=on` or `?bg=off` on any page, this tab only (kept for reloads and navigation in the tab), logged out
  too. Combine with the theme: `…/dashboard?theme=brand&bg=on` in one tab, `…/dashboard?theme=brand&bg=off` in another.
- **Build flag** `REACT_APP_PAGE_BACKGROUND=off` makes off the default for a build (a choice in the menu or `?bg=`
  still wins). Unset or any other value = on. The alpha build (`scripts/alpha-web/Dockerfile`) doesn't set it, so it
  gets the background.
- No storage (private window, blocked site data): the toggle and `?bg=` still work for the open tab.

### The layers and their opacity

Per theme as tokens in `src/theme/tokens.css`; the rules in `src/theme/pageBackground.css`.

| Layer | What | `current` | `brand` / `brand-red` | `proposal` |
|---|---|---|---|---|
| Page backdrop (`--page-bg-canvas-alpha`) | the grey page colour behind everything | 75 % | 75 % | 75 % |
| Cards (`--page-bg-surface-alpha`) | `bg-white`, `bg-surface`, `.panel`: cards, tables, panels, secondary buttons | 92 % | 88 % | 85 % |
| Auth backdrop (`--page-bg-backdrop-alpha`) | behind the login/register/link cards | 75 % (light, inside the page) | 75 % black, straight on the image | 75 % charcoal, straight on the image |

So the image shows at 25 % through the page backdrop and at 2–4 % through a card. Pages that paint their own
full-height page colour (account and admin pages) let the page backdrop through instead.

**Stay solid** (for readability, or because content scrolls under them): form fields, menus and list boxes, dialogs
and anything inside them, tooltips, everything positioned (dropdowns, sticky headers and footers, toasts), the quiet
grey blocks (table heads, the detail page's value boxes), the coloured alert and badge tints, the navigation bar (it
was already 95 % with a blur), and the cards on the dark auth backdrop in `brand`/`brand-red`/`proposal` (a white card
at 88 % over black would make grey text only 3.7:1).

### Contrast (WCAG AA)

The image has both extremes (darkest pixel almost black, lightest almost white), so every value is checked over pure
black and pure white: it holds wherever text lands. `src/theme/__tests__/contrast.test.ts` (extended) checks every
theme's text and UI pairs on a card over the page backdrop, the text on the page backdrop, and the auth backdrop text;
it fails the build if an alpha or colour is lowered below AA. The cards' alphas are set by their most demanding text
(slate-500 needs 91 % in `current`, grey-500 85 % in `brand`).

At 75 % over the darkest part of the image the page backdrop itself is mid grey (`#b6b7b8` in `current`). Mid-tone text
cannot reach 4.5:1 there, so **text straight on the page backdrop** (page titles, breadcrumbs, the "TOWN" eyebrow,
helper text above a card) is darker while the background is on: the muted text and the 500/600 greys take the theme's
700 grey, links/borders/focus rings take a new dark `--color-canvas-link` (`current` `#173C96`, `brand` `#693500`,
`brand-red` `#870F19`, `proposal` charcoal as before), and field borders the 700 grey. Inside cards, menus and fields
the theme's own colours come back.

Not covered: status-coloured text (red/green/amber) placed straight on the page backdrop outside a card or alert
(none in the screens checked), and screens still on raw Tailwind colours (§ 5).

### Image and loading

- `public/images/1-1920.avif` (104 kB) with `1-1920.webp` (153 kB) as fallback, 1920 × 1079, made from `1.jpg`
  (287 kB, unchanged); a `<picture>` picks AVIF where the browser takes it.
- Only requested while the background is on (off: nothing is loaded). Low fetch priority, so the page's own requests go
  first. Not on the landing page: its slideshow starts with image 1 itself, so the landing loads the picture once.

### Checklist (smoke test after the merge)

1. In a fresh private window (no stored choice), open the login page and then the dashboard: the background is there
   and the cogwheel's **Background image** is ticked. Untick it: it goes at once, the menu stays open and solid, and it
   stays off after a reload.
2. Flip through the four themes with the background on: page backdrop, cards and tables translucent; nav bar solid.
3. Dashboard (`/dashboard/Town`): explorer list and table readable; the search fields keep a visible border.
4. Entity detail page (`/display/<Type>/<id>`): breadcrumb, eyebrow and title on the backdrop readable; value boxes
   solid.
5. Form wizard (create and edit): step header, fields and the sticky footer readable while scrolling.
6. Login, register and `/link` logged out: in `brand`/`brand-red`/`proposal` the dark backdrop shows the
   image through it and the card is solid; in `current` the light backdrop box.
7. Landing page: unchanged (the slideshow); browser dev tools → Network: `1.jpg` once, no `1-1920.*`.
8. Phone width (390 px): the image covers the screen without stretching.
9. Two tabs: `?bg=on` and `?bg=off` side by side; reload each, the choice stays per tab.
10. Background off (menu or `?bg=off`): the app looks exactly as without it.
