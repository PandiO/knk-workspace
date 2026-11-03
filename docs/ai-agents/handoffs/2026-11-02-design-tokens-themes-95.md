# Handoff: design token layer with switchable themes for comparison (#95)

**Status:** Ready to start
**Last updated:** 2026-11-02
**Issue:** [PandiO/knk-workspace#95](https://github.com/PandiO/knk-workspace/issues/95) (rebrand phase 1; #92 phases
2–4 is its sub-issue and stays out of scope)

## Prompt (paste into a new session)

You implement PandiO/knk-workspace#95 in knk-web-app: rebrand phase 1. It adds a design token layer with contrast rules. On top of it, a theme switch lets the developer compare designs live in the running app.

**Setup.** Repositories: knk-workspace and knk-web-app. Add any that are missing with add_repo. Then:
1. Read `knk-workspace/AGENTS.md`, `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` and `docs/ACTIVE_SESSIONS.md`.
   Add a row to `docs/ACTIVE_SESSIONS.md` claiming #95 and push it to knk-workspace `main`.
2. Create `claude/design-tokens-95`:
   - in knk-web-app, from `origin/main`;
   - in knk-workspace, from `origin/main`, for the feature docs.

   Run `git push --dry-run` on both before changing anything.

**Read first:**
- #95 with all its comments. They add these to the scope:
  - the `text-gray-400` contrast sweep (133 uses);
  - fields with no focus ring (`focus:ring-primary` without a ring width, about 104 fields);
  - fields in the error state (`border-red-300`) with no border.
- `docs/reports/2026-10-08-web-app-ux-assessment.md` §11 (brand alignment). §11.3 has the token layer design: keep the Tailwind key `primary` so the 427 usages switch without component edits. §11.4 has the contrast rules.
- `docs/reports/2026-10-25-web-app-ux-reevaluation.md`, the #95 and #92 sections.
- The brand guide `docs/vision/brand/huisstijlhandboek.pdf`:
  - Colours: orange `#F29100`, dark red `#BE1622`, black, charcoal `#353535`, white.
  - Body font: Lato.
  - Headings: Enchanted Land. Its licence is not settled (#92 Q6).

**What the developer wants (2026-11-02).** Compare designs live by switching between them in the running app:
1. **`current`**, the default: today's look, rebuilt on the tokens. With this theme on, the app must look the same as `main` today, apart from the accessibility fixes from the #95 comments (contrast, focus ring, error border).
2. **`brand`**: based on the brand guide.
   - Red/orange as primary and CTA.
   - Black and charcoal neutrals where the guide asks for them.
   - Lato, self-hosted under the OFL (Lato 2.0 if available; otherwise state which weights you have).
   - No Enchanted Land: its licence is open (#92). Use a free stand-in heading font, or none, and say which.
   - Danger must stay distinguishable from brand red: always an icon and text, never colour alone.
3. **`proposal`** (optional): your own suggestion, for example a dark public side with a light admin (#92 Q7), or a calmer variant of the brand colours. Skip it if you can't make it clearly different and good, and say why.

**How the switch works:**
- Themes are sets of CSS variables under `:root[data-theme="…"]`; Tailwind reads the variables.
- Add a theme picker in the navigation's user menu, or a small floating control.
  - Show it only to logged-in staff, or behind a flag such as `REACT_APP_THEME_PICKER`.
  - Players never see it.
- A `?theme=` URL parameter also selects a theme, so the developer can open two tabs side by side.
- Persist the choice in `localStorage`, wrapped in try/catch.
- Switching is instant, with no reload.

**Contrast:**
- Every text/background and UI pair of every theme passes WCAG AA (text 4.5:1; large text and UI 3:1).
- Add a unit test that computes the ratios from the token values, so a failing pair breaks the build.

**Migration (most-used screens first):** nav, buttons, inputs, tables, cards, badges, toasts.
- Replace raw colour classes (`blue-600`, `gray-*`, `slate-*`) with semantic tokens: `primary`, `primary-dark`, `surface`, `text`, `muted`, `border`, `danger`, `success`, `warning`.
- Add a grep or lint check that reports new raw colour classes; report it rather than failing CI.
- List the screens you didn't migrate.
- A theme is only a fair comparison where the screens use tokens. Prioritise what the developer will look at:
  - dashboard;
  - form wizard;
  - an entity detail page;
  - player profile;
  - login/landing.

**Overlap.** knk-web-app has unmerged feature branches that change screens this work touches:
- `claude/entity-lists-url-state` (link 9: `PagedEntityTable`, dashboard, `FormWizardPage.tsx`);
- `claude/world-task-hardening` (link 7: `FormWizard.tsx`, `ChildFormModal.tsx`, `FieldEditor.tsx`);
- `claude/realtime-signalr` (link 8).

Don't base on them; keep class swaps mechanical so the later merges stay easy. Do a trial merge of each into your head and list the conflicting files in your summary.

**Checks:**
- `npx npm@11 ci`, `npm run test:ci`. Baseline (knk-web-app `main` `439ad85`, 2026-11-02): all green, 1379 tests; #204 is merged.
- `npx tsc --noEmit`: the baseline is 0 errors (#63 and #200 merged); don't add any.
- `CI=true npm run build`: compiles with 0 warnings since `439ad85` (#200), so a new lint warning fails the build. (Before 2026-11-02 the baseline was 1 red test, 9 tsc errors and 24 build warnings.)
- Use the npm 11 lock file only.
- If Playwright/Chromium is available, take screenshots of the five priority screens in each theme, light only. Put them on the workspace branch under `docs/reports/assets/2026-11-design-themes/`.

**Docs (workspace feature branch):**
- A short `docs/guides/design-themes-comparison.md`:
  - how to switch themes;
  - what each theme changes;
  - a checklist for the developer's live comparison;
  - the open decisions (#92 Q6 font licence, Q7 light/dark split).
- The web-app architecture doc: the token layer section.
- CHANGELOG under Unreleased.

**Finish:**
- Commits with `-c user.name="Claude" -c user.email="noreply@anthropic.com"` and the session's attribution trailers; push both branches.
- Don't merge, open a PR or force-push.
- Comment on #95 with:
  - the heads;
  - tests, tsc and build against the baseline;
  - the themes built and how to switch;
  - the migrated and not-migrated screens;
  - the trial-merge conflicts;
  - decisions taken.

  End the comment with a blank line, `---` and `_Generated by [Claude Code](https://claude.ai/code)_`. Set the label `status:in-review`.
- Update your `ACTIVE_SESSIONS.md` row to "in review" with the heads, and push it to workspace `main`.
- End with a short summary.
