# Staff web app — admin guide

**Status:** Living document — update in place. Describes knk-web-app `next` `e6ba115` and knk-web-api `master` `45043a7`
(merged 2026-11-12/13; `next` adds #371, create and edit back on `knk.admin.content`, which reaches `main` when the
developer promotes `next`). Only the builders (§ 7) were smoke-tested by the developer (2026-11-11/12, all pass); navigation,
Entity setup without a nav link, the detail page, the relation picker, live updates, the settings pages and the
dashboard access model with bulk delete (§ 1, § 3) are **not live-tested** yet: their smoke tests are linked in each
section (the access model's is in closed alpha test run 2, checklist § 4c).
**Last updated:** 2026-11-13 (New, Edit and the forms need `knk.admin.content` again, #371, docs #378); 2026-11-13 (dashboard per area, disabled actions with "Requires …", bulk delete, export through the
API, names-only pickers, readable refusals; #280 AM3 and #205, docs #366); 2026-11-12 (first version,
PandiO/knk-workspace#337, #338, #340–#345)

How staff find their way around the web app's admin pages and use the content tools: the dashboard, Entity setup, the
detail page, the relation picker in forms, live updates, the form and display builders, and the settings pages. It
does not repeat the feature guides (siege, game settings, menus, …); it links to them.

## 1. Before you start

- You need a web account that is linked to your Minecraft account and in a staff group. What you see depends on the
  **permission nodes** of your groups: each admin page is shown only to holders of its node, and the API checks the
  same node again on every request. `*` and `knk.admin.*` match every admin node.
- **The dashboard is per area** ([#280](https://github.com/PandiO/knk-workspace/issues/280), merged 2026-11-13). Each
  type belongs to an area with its own node: `knk.admin.content` (items, categories, tags, …), `knk.admin.world`
  (domains, towns, districts, streets, …), `knk.kit.manage`, `knk.admin.lootbox.manage`, `knk.siege.admin.manage`,
  `knk.admin.road` and `knk.admin.user.manage` (users, permission groups). **Any one** of them opens the Dashboard
  and the detail pages; you see only the types of the areas you hold. **Creating and editing** (New, Edit, the
  forms) needs `knk.admin.content` as well as the type's area node
  ([#371](https://github.com/PandiO/knk-workspace/issues/371), developer decision 2026-11-13). Deleting needs
  `knk.admin.delete` on top, exporting `knk.admin.export`, and deleting several rows at once
  `knk.admin.delete.bulk`, which only the owner hands out. Entity setup's lists, the builders and the Minecraft
  catalogue need `knk.admin.content` too. Which rank holds what, and how to give someone an area node:
  [dashboard access admin guide](dashboard-access-admin-guide.md). The [changelog entries of 2026-11-12 and
  2026-11-13](../../CHANGELOG.md) list what changed for existing groups.
- **Buttons you can't use** are greyed out with what they need, on hover and next to them: "Requires
  knk.admin.delete", "Requires knk.admin.export", "Requires knk.admin.content". Bulk **Delete (n)** is hidden instead.
  After a node change, reload the page.

## 2. Finding your way: the bar, the admin sidebar and breadcrumbs

**The top bar** has **Home**, **Leaderboards**, **Guides**, **Dashboard** (only with an area node, § 1) and, last,
**Admin** (only when you hold the node of at least one admin page). A narrow window shows icons only, then a menu button.
The current link is highlighted: **Dashboard** also on Entity setup, the builders and every detail page; **Admin** on
the other admin pages.

**Admin** (`/admin`) is an overview of every admin page you may open, by group, with one line on what each is for.
Without any admin node it says "No admin pages". On every other admin page the same list is the **admin sidebar**:
on the left from a window width of 1280 px, below that behind an **Admin pages** button (Escape or a click outside
closes it).

| Group | Page | Node |
|---|---|---|
| Content | Dashboard | any area node (§ 1) |
| Content | Minecraft catalogue | `knk.admin.content` |
| World | Lootboxes | `knk.admin.lootbox.manage` |
| World | Domain discovery | `knk.admin.discovery` |
| World | Road network | `knk.admin.road` |
| World | Orphaned Locations | `knk.admin.location.orphans` |
| Players & support | Player moderation (and the player profiles) | `knk.admin.user.manage` |
| Players & support | Invitations | `knk.admin.invites` |
| Economy | Balance event log (and transaction details) | `knk.admin.currency.history` |
| Economy | Currency policy | `knk.admin.currency.policy` |
| Economy | Currency alerts | `knk.admin.currency.alerts` |
| Settings | Game settings | `knk.admin.config` |
| Settings | Siege settings | `knk.siege.admin.manage` |
| Settings | Mail log | `knk.admin.config` |
| Owner | Diagnostics, Data deletion requests, World analytics | owner nodes (`knk.owner.*`), exact grants only (`*` doesn't match them) |

A page you can't open isn't listed. If you open its address anyway you get "Staff only" (and the API refuses the
data). The Economy pages and Orphaned Locations used to be buttons on Player moderation; Invitations now shows for
`knk.admin.invites` (it was missing before, [#262](https://github.com/PandiO/knk-workspace/issues/262)).

**Breadcrumbs** above every admin page start with the group (a link to that group on `/admin`), then the pages
above this one: "Economy › Balance event log › Transaction", "Content › Dashboard". The open form and the detail
page draw their own trail ("Content › Dashboard › Town › Cinix"). The browser tab shows the page's title ("Road
network · Knights & Kings"; on a detail page the record's name and type).

Pages without a link of their own: Entity setup and the builders (§ 3), detail pages (from the dashboard's rows),
transaction details and player profiles (from their lists).

Smoke test: [admin navigation](../admin-navigation-smoke-test.md) (not run).

## 3. Dashboard and Entity setup

The **Dashboard** (`/dashboard/{Type}`) lists the records of one type: pick the type in the explorer on the left, then
search, sort and page; all of it is in the address, so Back and a shared link return to the same view. The explorer
lists only the types of your areas (§ 1); an address with a type of another area opens one of yours instead. A row is a
link to the record's **detail page** (§ 4); middle-click opens it in a new tab. Next to the type's title:

- **New {Type}** opens the type's default form; **Drafts (n)** lists your saved, unfinished forms of this type and
  **New with** offers its other published forms. These open the form wizard, which needs `knk.admin.content` on top of
  the type's area node; without it they are greyed out with "Requires knk.admin.content".
- **⚙ Configure {Type}** opens **Entity setup** for that type (`/forms/{Type}`): its form configurations, display
  configurations, Default Table Columns and saved progress. It needs `knk.admin.content` (greyed out otherwise; opening
  the address says "Staff only — This page needs the knk.admin.content permission").
- Without the type's create or edit node, or without `knk.admin.content`, **New** and **Edit** are greyed out with
  "Requires …"; without `knk.admin.delete`, so is **Delete**. **Edit** on a User opens the player profile and doesn't
  need `knk.admin.content`.

**Delete one row.** A row's **Delete** asks "Delete Street "Main Street"?" in a red dialog; after **Delete** a short
message says it was deleted. If it is still in use, the refusal offers **Show what uses it** (§ 4).

**Select rows.** Tick the boxes in the first column (the header box ticks the rows shown); the selection stays across
pages and searches of the type and is cleared when you pick another type. The bar above the table says "n selected"
with **Clear**, or "None selected · Export takes all N results".

**Delete (n)** ([#205](https://github.com/PandiO/knk-workspace/issues/205); red, before Export; only with
`knk.admin.delete.bulk`, and never for users and permission groups, which are deleted one at a time):
- It asks "Delete 3 Streets?" with the count and type. Nothing is deleted before you confirm, and it can't be undone.
- The rows are deleted one by one, 100 per request; a large selection shows "Deleting… n / N".
- Deleted rows leave the table and the selection. A row that couldn't be deleted **stays selected**, and a dialog
  "Deleted 2 of 3 Streets" lists it with the reason; a row still in use offers **Show what uses it**. If a request
  fails (network, too many requests), the run stops and the dialog lists the rows not tried.
- A short message sums it up ("Deleted 3 Streets.", or "Deleted 2 of 3 Streets; 1 weren't deleted."). Each request
  is one "Bulk delete on the dashboard" entry in your audit log (player profile → Activity).

**Export CSV** (needs `knk.admin.export`): with rows ticked it exports those, **in the order you ticked them**, with
their current values; with none it exports the whole search in its current sort, at most 10,000 rows (the bar says so
beforehand). The file `<Type>-<date>.csv` has the table's columns in table order (comma-separated, UTF-8, with `'`
before text that looks like a formula). The server reads the rows in one request ("Exporting N…"); each export is a
"Dashboard export" entry in the audit log with the type, the number of rows and "(selection)" or "(search)".

**There is no "Entity setup" link in the bar** ([#197](https://github.com/PandiO/knk-workspace/issues/197)). Reach it
with the dashboard's **⚙** on a type, with **Drafts (n)** → **All saved progress (Entity setup)**, or by typing
`/forms` in the address bar (the old `/admin/form-configurations` address still goes there). A type without a display
configuration has a muted marker in the explorer ("No display configuration – set one up via ⚙").

Smoke tests: [dashboard return § 14a](../dashboard-return-smoke-test.md#14a-no-entity-setup-nav-link-197),
[entity lists § 7](../entity-lists-url-state-smoke-test.md#7-checkbox-selection-and-export-csv-205-export-part-chain-3-v2) (selection and export),
[dashboard access § 8](../dashboard-access-smoke-test.md#8-web-app-am3) (areas, disabled actions, bulk delete, export;
test run 2 § 4c) (not run).

## 4. The detail page

The detail page (`/display/{Type}/{id}`, **View** on a dashboard row) shows one record with the sections of the type's
published display configuration. The header has the record's name and type, **Back** (to where you came from), **Edit**
and **Delete**. **Edit** needs the type's edit node and `knk.admin.content` (greyed out with "Requires …" otherwise;
a User's Edit opens the player profile instead).

**Reading it** ([#189](https://github.com/PandiO/knk-workspace/issues/189)):
- Values are plain text; an empty value is "-". A related record (a street's town, an item's category) is a link to its
  own detail page when you may read that type; otherwise it is plain text with "Opening X requires one of: …".
- Collections show a count in their title ("Streets 14") and 12 items per page with Previous / Next.
- A page that can't load says why: "You don't have access to Town "Cinix"." with the nodes that would allow it, "doesn't
  exist", "no detail page set up yet" (no display configuration), or "couldn't be loaded" with **Try again**.
- A value you can edit in place saves with Enter and cancels with Escape.

**Changing links** ([#188](https://github.com/PandiO/knk-workspace/issues/188)):
- **Select… / Change…** (a single link) and **Add…** (a collection) open a search dialog of existing records: type
  part of a name, records that are already linked say **Linked**. Picking one links it. If it already belongs to
  another parent (a category under another category), you are asked "Move … here?" naming the current parent; **Move
  here** moves it.
- **Unlink** only removes the link; the record itself stays (it asks first, not in red).
- **Delete** is a separate, red action on items and in the header: it deletes the record everywhere, after a red
  question that names it.
- A link that can't change here says why under the buttons, for example "A District always belongs to a town" or
  "An icon is required". A button you lack the node for is disabled with "Requires …" (for example "Delete: Requires
  knk.admin.delete", or "Requires knk.admin.world" on a town's links).
- Edits by others and a delete of the open record show live (§ 6).

**A delete that is refused because the record is still in use** (a street that structures point at) shows the API's
message with **Show what uses it** ([#44](https://github.com/PandiO/knk-workspace/issues/44)): the records per kind
("23 structures"), each a link to its detail page when you may read it, "… and n more" past 20. This works for a row's
Delete on the dashboard, the header's Delete and an item's Delete. Other refusals don't have it yet
([#289](https://github.com/PandiO/knk-workspace/issues/289)).

Known gaps: some relationship pairs can't be linked here yet, and link-table changes don't update live
([#287](https://github.com/PandiO/knk-workspace/issues/287)).

Smoke tests: [entity detail](../entity-detail-smoke-test.md), [relation picker and delete details § 4](../relation-picker-and-delete-details-smoke-test.md)
(not run).

## 5. Picking a related record in a form

A link field in a form (a town's domain, a structure's street, a list of tags) is a **search box**
([#191](https://github.com/PandiO/knk-workspace/issues/191)); the old "Select instance" table is gone. Start typing:
the first 8 matches show after a short pause, records created earlier in the same form on top, each with one detail
line. Arrow keys and Enter, or a click, pick one; Escape closes the list. In a list field a pick adds or removes one
record, up to the field's maximum. When there are more matches, keep typing, or press **Open full table** for the
full table with paging, sorting and filters.

Without read access to the related type (its area node), the box searches **by name only** (no full table) and says
so: "Names only: the full Street table needs one of: …". A type that can't be searched that way says "can't be searched
here. Requires one of: …"; a field with a narrowing filter says why it can't offer the list
([#288](https://github.com/PandiO/knk-workspace/issues/288)). **Create New** for a link field is offered only with
the related type's create node and `knk.admin.content`. A table you can't read (for example a picker's **Open full table**) says "You don't
have access to Category. Requires one of: …" instead of "Failed to load data".

Smoke test: [relation picker and delete details](../relation-picker-and-delete-details-smoke-test.md) (not run).

## 6. Live updates

While you have a page open, changes made by other staff show up by themselves
([#183](https://github.com/PandiO/knk-workspace/issues/183)):

- **Dashboard:** the table re-reads quietly (page, search and sort stay), with "Updated by alice at 21:52" above it
  ("Updated by alice, bob and 2 others" for several). Your own saves don't show this line.
- **Detail page:** the values change in place with the same line; if someone deletes the record you see "This Town was
  deleted by alice." with **Back**, and the old values stay readable.
- **Player moderation:** the **Online** / **Offline** badges follow players joining and leaving the game.
- **Player profile:** an **Online** or "Offline · last seen …" badge next to Reload, live.

You only get updates for data you may read: the type's area node (`knk.admin.content`, `knk.admin.world`, …), or
`knk.admin.user.manage` for players and their online state. A node taken away stops them within 30 seconds. If the
connection drops, nothing breaks: the page reads again once it is back, and Reload always works. The server can switch
live updates off (`Realtime__WebLiveUpdatesEnabled=false`, [alpha go-live § 5](../alpha-go-live.md)); the pages then
behave as before.

Smoke test: [realtime § S4](../realtime-smoke-test.md#s4--live-updates-in-the-web-app-183) (not run).

## 7. Form and display builders

Open a builder from Entity setup: **Create Form** / **Create Display**, or a configuration's ⋯ → **Edit**
([#71](https://github.com/PandiO/knk-workspace/issues/71); smoke-tested 2026-11-11/12).

**Drafts and Publish.** A builder works on a **draft**; staff keep using the **published** version until you publish.
- The header says **New**, **Draft** ("Never published: staff can't use this form yet."), **Published · changes not
  published** ("Staff still get the published version.") or **Published**, and whether there are unsaved changes.
- **Save** stores the draft and keeps the builder open ("Draft saved. Staff keep the published version until you
  publish."). **Save and close** saves and returns to Entity setup.
- **Publish…** checks the configuration, saves unsaved changes, then tells you what changes for staff before you
  confirm: steps or sections and fields added, removed or changed, a rename, a new order, whether it becomes (or stops
  being) the default and which one it replaces, and how many saved wizard drafts continue on the new version ("values
  of removed fields aren't used"). **Cancel** changes nothing. A refusal stays in the dialog.
- A **new** form or display is a draft until its first Publish: Entity setup shows a **Draft** badge, **Use** and
  **Set Default** are off, and the dashboard's New and New with don't offer it. A published one with saved changes
  shows **Unpublished changes**.
- **More → Discard unpublished changes…** goes back to the published version (red question).
- Leaving with unsaved changes (a link, the breadcrumb, Back or **Close**) asks "Leave without saving?"; a reload asks
  in the browser.

**More → Generate from metadata…** proposes steps or sections from the type's properties: values to a General step,
links to a Links step (a display gets Details, Related and one section per collection), with what each becomes and
what is left out and why. Untick what you don't want, **Add n fields**, then edit and **Save**.

**More → Duplicate…** (also in Entity setup's ⋯ menu) copies the **published** version under a new name as a new
draft and opens it. It is off while there are unsaved changes or before the first Publish.

**Preview** shows the working copy next to the builder (below it on a phone) with sample values, a real record you
pick, or empty. Nothing you type in the preview is saved and no in-game task is offered; display conditions aren't
applied in a form preview, and buttons and links do nothing in a display preview.

Saving, publishing, duplicating, discarding and generating need `knk.admin.content`.

> **Known limit ([#291](https://github.com/PandiO/knk-workspace/issues/291)):** a field's **validation rules** are saved
> at once, outside the draft: a rule you add, change or remove applies to the published form straight away, before
> Publish.

Smoke test: [form and display builders](../form-display-builders-smoke-test.md) (run 2026-11-11/12, all pass).

## 8. Dialogs, questions and messages

The web app uses the same few patterns everywhere ([#33](https://github.com/PandiO/knk-workspace/issues/33)):
- **Success** is a short message at the bottom of the screen ("Town saved"), gone after about 5 seconds (hovering
  keeps it). Warnings and errors stay a little longer.
- **Questions** ask before anything risky. A red button means it removes or switches off something; focus then starts
  on Cancel. Escape, × or a click outside answers no. Some actions need a **reason** for the audit log (freezing a
  player); the question waits until you type one.
- **Dialogs** (forms, editors, pickers) keep focus inside, close with Escape or ×, and don't close on a stray click
  outside, so nothing typed is lost. A child form (Create New inside a form) asks "Leave this form?" before it closes
  with unsaved changes.

Smoke test: [feedback primitives](../feedback-primitives-smoke-test.md) (not run).

## 9. Settings pages

Game settings, Siege settings, **Lootboxes → Settings**, **Currency policy** and **Road network** share one header
([#187](https://github.com/PandiO/knk-workspace/issues/187), [#26](https://github.com/PandiO/knk-workspace/issues/26)):
the title, "Last saved …" (the time; who saved it is not stored yet, [#190](https://github.com/PandiO/knk-workspace/issues/190)),
"n unsaved changes", **Reload**, **Discard** and **Save (n)**. Changed sections are marked. With unsaved changes,
leaving the page (or switching the Lootboxes tab) asks "Leave without saving?" (**Stay** keeps them); Discard and
Reload ask too. A refused save keeps your changes and shows the reason in the header. Fields show their **unit** and
one line of help, and what the typed value means: ticks "= 1 s", a world time "= 12:00 (noon)", ‰ and basis points as
a percentage, × for multipliers.

- **Game settings:** see [the Game Settings guide](../game-settings.md).
- **Siege settings:** see [authoring a siege scenario § 4](../authoring-a-siege-scenario.md#4-siege-settings-global).
- **Lootboxes → Settings** (`knk.admin.lootbox.manage`): the two chat announcement thresholds are a choice "★n and
  better" or **Never** (specials are always announced; a type can override it), with a preview of both announcements
  as the game shows them. The Odds tab shows small chances as "1 in N". Switching lootboxes off or on asks first
  ("Switch lootboxes off? Nothing spawns and no box can be claimed until they are switched on again …"); so do a
  type's **Enabled** on the Types tab (boxes already in the world stay) and a token grant rule on the Tokens tab (tokens
  already issued stay; switching on doesn't grant retroactively). Changes reach the game server at its next runtime
  refresh.
- **Currency policy** (`knk.admin.currency.policy`): coins and gems in two sections with **one Save**. The **lowest
  sender title** is picked from the title brackets. Switching a currency's payments off or on asks first ("Switch
  coins payments off? … no player can send coins with /pay until they are switched on again. Staff grants still
  work."); it applies at once and is recorded in the audit log. If someone else saved a currency meanwhile, that
  section says so and offers **Reload current policy**.
- **Road network** (`knk.admin.road`): the header's Save saves the navigation defaults per domain type together with
  the compass settings (a choice no longer saves on its own). Road profiles and stretches keep their own Save ("Save
  stretch #n") and are not counted in the header.

Detailed lootbox, currency and road guides are still to be written ([#300](https://github.com/PandiO/knk-workspace/issues/300),
[#298](https://github.com/PandiO/knk-workspace/issues/298)).

Smoke tests: [settings pages](../settings-pages-smoke-test.md), [data primitives](../data-primitives-smoke-test.md)
(not run).

## 10. Safe test procedure and common problems

Try changes on the dev server first. For the content tools: create a test record, link and unlink it on its detail
page, delete it; for a builder, Save and Preview before you Publish, and Publish outside play hours, because staff
get the new version at once.

| You see | Why | What to do |
|---|---|---|
| No **Dashboard** in the bar, or "Staff only" listing nodes | No area node | Add the area node of their work ([admin guide § 6](dashboard-access-admin-guide.md#6-giving-someone-an-area-node)) |
| A type isn't in the explorer, or "You don't have access to Town …" | The type's area node is missing | Add the area node (for towns `knk.admin.world`) |
| A button disabled with "Requires …" | That action's node is missing | Add the named node, or ask someone who has it |
| No **Delete (n)** when rows are ticked | No `knk.admin.delete.bulk` (owner-only), or users and permission groups | Ask the owner; delete users and groups one at a time |
| After **Delete (n)** some rows are still ticked | Those were refused; the dialog gave each reason | Fix the reason (**Show what uses it**), then delete again |
| **New** / **Edit** greyed out: "Requires knk.admin.content" | Creating and editing need the content node on top of the area node (#371) | Ask for `knk.admin.content` if you should create and edit |
| "Staff only — This page needs the knk.admin.content permission" on a form | Entity setup, the forms and the builders need the content node. The Lootboxes tabs' New/Edit, Road network's Rename and a detail page section's edit and Create New still lead there instead of being greyed out ([#380](https://github.com/PandiO/knk-workspace/issues/380)) | Ask for `knk.admin.content` |
| Delete refused with **Show what uses it** | Other records still point at it | Unlink or delete those first |
| Staff don't see a builder change | It is saved as a draft, not published | **Publish…** |
| A validation rule change applies before Publish | Known limit #291 | Change rules outside play hours |
| No "Updated by …" lines | Live updates off on the server, the connection is blocked, or you lack the type's area node | Reload; check `Realtime__WebLiveUpdatesEnabled` and the proxy's `/api/hubs/web` |
