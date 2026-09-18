# knk-web-app — Reading & Implementation Guide

**Status:** Living document — updated in place on each rescan
**Last updated:** 2026-09-18
**Companion docs:** `docs/architecture/web-app-architecture.md` (structure/data-flow),
`docs/reports/web-app-scan-2026-09-18.md` (dated raw findings this guide is based on)

Purpose: get a new session (human or AI) productive in this repo quickly, without
re-deriving what's already been mapped out. Read this before making changes; read the
architecture doc for the "why it's shaped this way"; read the scan report if you need
citations/line numbers for a specific claim.

## Before you start

- This repo is normally checked out as a sibling of `knk-workspace`, not nested under
  it — despite what this repo's own `CLAUDE.md` says about a `Repository/knk-web-app`
  layout. If the `@../../docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md` import in
  `knk-web-app/CLAUDE.md` doesn't resolve, that's why; the inline fallback summary in
  that file is accurate regardless.
- Check `knk-workspace/docs/ACTIVE_SESSIONS.md` before claiming work — scope your claim
  by **feature**, not just "knk-web-app", since most features span all three repos.
- `npm install && npm start` to run it; `npm run test:ci` before committing anything
  that touches `apiClients/`, `hooks/`, or `utils/` (38 existing unit tests, mostly
  covering those layers — see `find src -name "*.test.ts*"` for the current list).

## How the app is organized (read in this order)

1. **`src/App.tsx`** — the entire route table lives here, flat, in one file. Start
   here to find which page owns a URL you care about. Every protected route is wrapped
   in `<ProtectedRoute>`.
2. **`src/pages/`** — one file per route. Thin: they mostly wire a generic engine
   component (`FormWizard`, `DisplayWizard`, `PagedEntityTable`) to route params, not
   hand-rolled UI. If you're implementing a new entity's CRUD, you very likely don't
   need a new page at all — see "Adding a new entity" below.
3. **The two generic engines** — this is the part that's easy to miss if you go
   straight to a `pages/` file expecting to find the actual form/display markup:
   - **`src/components/FormWizard/`** — renders create/edit forms from a
     `FormConfigurationDto` (fetched via `formConfigClient`). The config itself is
     authored through `src/components/FormConfigBuilder/` (the admin UI at
     `/admin/form-configurations`).
   - **`src/components/DisplayWizard/`** — same pattern for read-only detail views,
     config authored via `src/components/DisplayConfigBuilder/`
     (`/admin/display-configurations`).
   - If a UI bug or feature request is about *how a specific entity's form/detail page
     looks or behaves*, check whether it's actually a **config problem** (fix the
     `FormConfigurationDto`/`DisplayConfigurationDto` via the builder UI or the
     backend) before touching the engine components — the engines are meant to be
     entity-agnostic.
4. **`src/config/objectConfigs.tsx`** — a *separate*, older, static per-entity config
   used only by `ObjectDashboard` (`/dashboard`) and the top-nav "Create New" menu.
   This is **not** the same registry the form/display engines use (see architecture
   doc's "two competing registries" note) — if you add a new entity type and it's not
   showing up on the dashboard or in "Create New", this is almost certainly why: you
   need to add it here explicitly.
5. **`src/apiClients/`** — one file per backend resource, all following the identical
   `ObjectManager`-subclass pattern (see architecture doc's "Data flow" section for the
   exact call chain). Once you've read one (`townClient.ts` is a short, representative
   example), you've effectively read the pattern for all 25.
6. **`src/contexts/AuthContext.tsx`** — the only app-wide state. If you need
   `isLoggedIn`/`user`/`login`/`logout` anywhere, `useAuth()` (either the hook in
   `hooks/useAuth.ts` or importing directly from the context — they're the same thing)
   is the only mechanism; there's no Redux/Zustand to reach for instead.

## Conventions worth matching

- **New backend resource → new `apiClients/<resource>Client.ts`** extending
  `ObjectManager`, add an entry to the `Controllers` enum
  (`src/utils/enums.ts`) matching the backend's actual controller route segment
  (cross-check against `knk-web-api`, this repo's scan didn't verify that mapping).
- **New entity that needs a form/detail page** — prefer authoring a
  `FormConfigurationDto`/`DisplayConfigurationDto` through the existing builder UIs
  over writing a new bespoke page/component. Only reach for a hand-built page when the
  UI genuinely isn't just "fields in, entity out" (e.g. `GameSettingsPage`, which does
  cross-entity orchestration, not single-entity CRUD).
- **Auth-gated route** → wrap it in `<ProtectedRoute>` in `App.tsx`, same as every
  existing protected route.
- **Styling** — Tailwind utility classes for layout/spacing, Fluent UI components for
  interactive widgets where one fits; don't introduce CSS modules or
  styled-components (none exist in the repo today).
- **Don't add a `REACT_APP_*` env var for the API URL** — base URL config goes through
  `src/config/appConfig.ts` → `ConfigurationHelper.gatewayApiUrl`, by design (see
  architecture doc).

## Known traps (see scan report `docs/reports/web-app-scan-2026-09-18.md` for citations)

- **Don't copy `DynamicForm.tsx` or `ObjectView.tsx` as a starting point for anything.**
  Both are unreferenced predecessors to `FormWizard`/`DisplayWizard`; `DynamicForm.tsx`
  additionally imports apiClient modules that no longer exist. They're scan-flagged as
  deletion candidates, not examples to follow.
- **`DisplayWizardPage`'s edit/create actions are currently broken** — they navigate to
  `/form/...` (singular), but the real routes are `/forms/...` (plural). If you're
  touching that page, fix the path or confirm with the human owner whether that's
  intentionally disabled pending something else.
- **`EntityTypeConfigurationPage` exists but has no route** — if you need per-entity
  icon/color/sort configuration in the running app, you'll need to add the route and a
  nav link yourself; don't assume it's reachable today.
- **`FormWizardPage` hardcodes `userId = '1'`** for saved-progress tracking (line 120)
  — if you're working on that feature, this is a known gap, not a red herring.
- **Two entity registries, not one** — see `config/objectConfigs.tsx` note above. If
  something "works in Forms but not Dashboard" or vice versa, check this split first.

## Where to look for cross-repo context

- Auth/JWT shape and refresh-cookie behavior: cross-check against `knk-web-api`'s JWT
  config (`Security:Jwt` in its `appsettings.json`) — not re-verified from this repo's
  scan.
- Minecraft-account linking (`authClient.generateLinkCode`/`linkAccount`/
  `linkMinecraftAccount`, surfaced in `AccountManagementPage` and the registration
  flow): this is the web-app half of a feature that likely also touches `knk-plugin`'s
  account-linking flow — check the `knk-plugin` scan/architecture docs for the other
  half before assuming either side is complete.
- Gate structure/door fields in `config/objectConfigs.tsx`
  (`GateStructureConfig`/`GateDoorConfig`) are the current front-end shape of the
  siege-minigame gate feature — cross-check against `knk-plugin`'s `gates/` package and
  `knk-web-api`'s gate-structure endpoints before changing field shapes here, since all
  three need to agree.

## Open follow-ups from this scan (not yet actioned — read-only pass)

- Confirm whether `npm run build` actually fails on `DynamicForm.tsx`'s broken imports,
  or whether it's silently excluded — affects how urgently it needs removing.
- Decide whether to retire `config/objectConfigs.tsx` in favor of driving
  `ObjectDashboard` off live metadata, or keep both deliberately.
- `test_output.txt` (17.5 MB, tracked in git) should probably just be deleted and
  gitignored — flagged here for the human to sign off on removal per the workspace's
  audit-then-execute convention, not deleted in this pass.

See the full dated report (`docs/reports/web-app-scan-2026-09-18.md`) for every
finding with file/line citations, including the component and API-client inventory
tables.
