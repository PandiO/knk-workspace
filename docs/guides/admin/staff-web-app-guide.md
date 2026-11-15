# Staff web app — admin guide

**Status:** Current · **Last updated:** 2026-11-15 (release v0.3: the features of § 3–§ 7 below are released; § 3 row
actions scroll with the table again and Export as CSV downloads at once, #606, #607; PandiO/knk-workspace#577)
**Checked against:** knk-web-app `main` `3ba747d` and knk-web-api `master` `f445d21` (AM3 of #280 merged 2026-11-13 as
`e02ee79` / `45043a7`; #371, #374 and #383, create, edit and link changes on `knk.admin.content`, reached the default
branches with the promotion of `next` on 2026-11-13). Step conditions in the form builder and clickable form steps
(#88, #68), with their fixes #413 and #414, were released in `v0.2` (2026-11-14). Release `v0.3` (2026-11-15,
knk-web-app `main` `947923c`, knk-web-api `main` `2cc8254`) brought the dashboard row actions and row menu (#404–#406,
#606, #607), the Permission Grant table (#408), a group's Permissions panel (#50), read-only town Streets (#409) and the
Chain 3 follow-ups (#289, #288, #291). Only the builders (§ 7) were smoke-tested by the developer
(2026-11-11/12, all pass); navigation, Entity setup without a nav link, the detail page, the relation picker, live
updates, the settings pages and the dashboard access model with bulk delete (§ 1, § 3) are **not live-tested** yet:
their smoke tests are linked in each section (the access model's is in closed alpha test run 2, checklist § 4c). The
v0.3 features are covered by automated tests in CI; the developer smoke-tested `next` before the promotion
(2026-11-15), and the manual look in both themes is still open in their smoke tests.

How staff find their way around the web app's admin pages and use the content tools: the dashboard, Entity setup, the
detail page, the relation picker in forms, live updates, the form and display builders, and the settings pages. It
does not repeat the feature guides (siege, game settings, menus, …); it links to them. **Player moderation** and the
**player profile** (freeze, kick and ban, permissions, the timeline) are in the
[ranks, permissions and moderation guide](ranks-permissions-moderation-admin-guide.md) § 3 and § 5–7.

## 1. Before you start

- You need a web account that is linked to your Minecraft account and in a staff group. What you see depends on the
  **permission nodes** of your groups: each admin page is shown only to holders of its node, and the API checks the
  same node again on every request. `*` and `knk.admin.*` match every admin node.
- **The dashboard is per area** ([#280](https://github.com/PandiO/knk-workspace/issues/280), merged 2026-11-13). Each
  type belongs to an area with its own node: `knk.admin.content` (items, categories, tags, …), `knk.admin.world`
  (domains, towns, districts, streets, …), `knk.kit.manage`, `knk.admin.lootbox.manage`, `knk.siege.admin.manage`,
  `knk.admin.road` and `knk.admin.user.manage` (users, permission groups). **Any one** of them opens the Dashboard
  and the detail pages; you see only the types of the areas you hold. **Creating and editing** (New, Edit, the
  forms, a value edited in place) and changing a record's links on its detail page need `knk.admin.content` as well
  as the type's area node ([#371](https://github.com/PandiO/knk-workspace/issues/371),
  [#374](https://github.com/PandiO/knk-workspace/issues/374), developer decisions 2026-11-13); the API refuses a create
  or edit without it too. Three types are exempt and keep only their own node: users (Edit opens the player profile,
  `knk.admin.user.manage`), permission groups, and road profiles (edited in Road network's own card,
  `knk.admin.road`). Deleting needs
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

**Row actions** ([#405](https://github.com/PandiO/knk-workspace/issues/405),
[#606](https://github.com/PandiO/knk-workspace/issues/606)). Each row ends with three icon buttons, **View** (eye),
**Edit** (pencil) and **Delete** (bin); hover one for its name. They are the row's last column and scroll sideways with
the other columns on a wide type or a phone; the right-click menu below reaches View and Edit at any width. The
checkbox column stays pinned to the left edge; a soft shadow on its right edge shows that columns are scrolled under
it. A greyed-out button says why on hover: "Requires …" for a missing node, or for **View** "No display
configuration – set one up via ⚙". Every row has the same thin line under it; a selected row is green with a green bar
on its left edge ([#404](https://github.com/PandiO/knk-workspace/issues/404)).

**Right-click menu** ([#406](https://github.com/PandiO/knk-workspace/issues/406)). Right-click a row for **View**,
**Edit**, **Delete** and **Export as CSV**. From the keyboard, Tab to the row's link or one of its buttons and press
**Shift+F10** or the context-menu key; the menu opens under it.

- Arrow keys move through the items (Home and End jump to the first and last), Enter or Space chooses, Escape closes
  the menu and puts you back where you were. A click outside, scrolling or resizing the window also closes it.
- The items follow the same nodes as the buttons and the bar: an item you may not use stays in the menu, greyed out,
  with the reason under it ("Requires knk.admin.delete", "Requires knk.admin.export"; "Checking permission…" for a
  moment after the page opens). Delete from the menu asks the same question as the row's Delete button; Export as CSV
  on one row downloads a file with that row only (the same file as **Export CSV** below), straight away
  ([#607](https://github.com/PandiO/knk-workspace/issues/607)).
- **On a selection:** right-click a row that is ticked while other rows are ticked too, and **Delete** and **Export**
  take the whole selection: "Delete 3 Towns" and "Export 3 Towns as CSV". That Delete needs
  `knk.admin.delete.bulk`, like **Delete (n)**, and asks the same question; for users and permission groups it is
  greyed out with "… records can only be deleted one at a time.", and while a bulk delete runs with "A delete is
  running". View and Edit still open the row you clicked. On a row that isn't
  ticked, the menu acts on that row only.
- **Ctrl + right-click** (Cmd + right-click on a Mac) opens the browser's own menu instead, for "Open link in new tab",
  copy or inspect.

**Delete one row.** A row's **Delete** asks "Delete Street "Main Street"?" in a red dialog; after **Delete** a short
message says it was deleted. If it is still in use, the refusal offers **Show what uses it** (§ 4).

**Delete a form configuration** (Entity setup → a form's **⋯** → **Delete**). A form that another form opens as a
sub-form can't be deleted: the red "Delete failed" dialog says "This form configuration can't be deleted: it is still
used by 1 form field that opens it as a sub-form …" with **Show what uses it** (since v0.3,
[#289](https://github.com/PandiO/knk-workspace/issues/289)). It lists the form fields and steps, each with the form
(and step) it sits in, for example "Field of the form "Kingdom form" (Kingdom), step "Towns"". They are not links;
open that form in the builder and clear its **Sub-configuration** first. Saved drafts and form sessions that use it
are only counted. Reading the list needs `knk.admin.content`.

**Select rows.** Tick the boxes in the first column (the header box ticks the rows shown); the selection stays across
pages and searches of the type and is cleared when you pick another type. The bar above the table says "n selected"
with **Clear**, or "None selected · Export takes all N results".

**Delete (n)** ([#205](https://github.com/PandiO/knk-workspace/issues/205); red, before Export; only with
`knk.admin.delete.bulk`, and never for users and permission groups, which are deleted one at a time):
- It asks "Delete 3 Streets?" with the count and type. Nothing is deleted before you confirm, and it can't be undone.
- The rows are sent 100 per request, one request after the other; a large selection shows "Deleting… n / N".
- Deleted rows leave the table and the selection. A row that couldn't be deleted **stays selected**, and a dialog
  "Deleted 2 of 3 Streets" lists it with the reason; a row still in use offers **Show what uses it** beside its name,
  which loads that row's list under its reason (**Hide** folds it again; a link closes the dialog and opens the
  record). A row refused for another reason has no such button. If a request
  fails (network, too many requests), the run stops and the dialog lists the rows not tried.
- A short message sums it up ("Deleted 3 Streets.", or "Deleted 2 of 3 Streets; 1 weren't deleted."). Each request
  is one "Bulk delete on the dashboard" entry in your audit log (player profile → Activity).

**Export CSV** (needs `knk.admin.export`): with rows ticked it exports those, **in the order you ticked them**, with
their current values; with none it exports the whole search in its current sort, at most 10,000 rows (the bar says so
beforehand). The file `<Type>-<date>.csv` downloads straight away, without a dialog of the app's own (a browser set
to ask where to save each file still asks; that is the browser's setting, #607). It has the table's columns in table order (comma-separated, UTF-8, with `'`
before text that looks like a formula). The server reads the rows in one request ("Exporting N…"); each export is a
"Dashboard export" entry in the audit log with the type, the number of rows and "(selection)" or "(search)".

**Permission Grant** ([#408](https://github.com/PandiO/knk-workspace/issues/408), since v0.3;
needs `knk.admin.user.manage`): every grant and deny of every player and group in one table: **ID**, **Node**,
**Effect** ("Granted" or "Denied"), **Holder** ("Group #<id>" for a group, "User #<id>" for a player) and **Expires
(UTC)** ("Never" for a permanent one; expired rows stay listed). Search by part of the node; every column sorts.
The table is **read-only**: change a player's grants on their profile (Permissions tab) and a group's in the group's
Permissions panel (§ 4). **New** and **Edit** are still shown (greyed out with "Requires knk.admin.user.perm" without
that node) but can't save a grant ([#530](https://github.com/PandiO/knk-workspace/issues/530)); there is no Delete.
Without `knk.admin.user.manage` the explorer doesn't list the type. The ranks guide explains the nodes:
[ranks, permissions and moderation § 3](ranks-permissions-moderation-admin-guide.md#3-giving-someone-a-group-a-rank-or-a-node).

**There is no "Entity setup" link in the bar** ([#197](https://github.com/PandiO/knk-workspace/issues/197)). Reach it
with the dashboard's **⚙** on a type, with **Drafts (n)** → **All saved progress (Entity setup)**, or by typing
`/forms` in the address bar (the old `/admin/form-configurations` address still goes there). A type without a display
configuration has a muted marker in the explorer ("No display configuration – set one up via ⚙").

Smoke tests: [dashboard return § 14a](../dashboard-return-smoke-test.md#14a-no-entity-setup-nav-link-197),
[entity lists § 7](../entity-lists-url-state-smoke-test.md#7-checkbox-selection-and-export-csv-205-export-part-chain-3-v2) (selection and export),
[dashboard access § 8](../dashboard-access-smoke-test.md#8-web-app-am3) (areas, disabled actions, bulk delete, export;
test run 2 § 4c) (not run); row actions and the right-click menu in
[§ 8.5](../dashboard-access-smoke-test.md#85-row-actions-in-view-and-the-right-click-menu-404-405-406) (automated in CI;
the manual look in both themes and the export with real data not run); the Permission Grant table in
[§ 8.6](../dashboard-access-smoke-test.md#86-the-permissiongrant-table-408) (automated in CI; manual steps not run).

## 4. The detail page

The detail page (`/display/{Type}/{id}`, **View** on a dashboard row) shows one record with the sections of the type's
published display configuration. The header has the record's name and type, **Back** (to where you came from), **Edit**
and **Delete**. **Edit** needs the type's edit node and `knk.admin.content` (greyed out with "Requires …" otherwise;
a User's Edit opens the player profile instead).

**Reading it** ([#189](https://github.com/PandiO/knk-workspace/issues/189)):
- Values are plain text; an empty value is "-". A related record (a district's town, an item's category) is a link to its
  own detail page when you may read that type; otherwise it is plain text with "Opening X requires one of: …".
- Collections show a count in their title ("Streets 14") and 12 items per page with Previous / Next.
- A page that can't load says why: "You don't have access to Town "Cinix"." with the nodes that would allow it, "doesn't
  exist", "no detail page set up yet" (no display configuration), or "couldn't be loaded" with **Try again**.
- A value you can edit in place saves with Enter and cancels with Escape. Editing in place needs the type's edit node
  and `knk.admin.content` ([#383](https://github.com/PandiO/knk-workspace/issues/383); a user's values need
  `knk.admin.user.manage`); without them the field is greyed out with "Requires …".

**Changing links** ([#188](https://github.com/PandiO/knk-workspace/issues/188)):
- **Select… / Change…** (a single link) and **Add…** (a collection) open a search dialog of existing records: type
  part of a name, records that are already linked say **Linked**. Picking one links it. If it already belongs to
  another parent (a category under another category), you are asked "Move … here?" naming the current parent; **Move
  here** moves it.
- **Unlink** only removes the link; the record itself stays (it asks first, not in red).
- **Delete** is a separate, red action on items and in the header: it deletes the record everywhere, after a red
  question that names it.
- A link that can't change here says why under the buttons, for example "A Structure always belongs to one District"
  or "An icon is required". A button you lack the node for is disabled with "Requires …" (for example "Delete: Requires
  knk.admin.delete").
- **Select…, Change…, Unlink and Add… need the type's area node and `knk.admin.content`**
  ([#374](https://github.com/PandiO/knk-workspace/issues/374)): changing a link is an edit. Without the content node
  they are greyed out with "Requires knk.admin.content", and the hint line under the section says so. A world-only rank
  can still open a district and delete one of its streets (with `knk.admin.delete`), but not add or unlink one.
- **A town's Streets are read-only** ([#409](https://github.com/PandiO/knk-workspace/issues/409), since
  v0.3): they are the streets of the town's districts, each once, by name. The section shows "Streets are managed
  on the district: open a district to add or remove them." and has no **Add…**, **Unlink**, **Create New** or
  **Delete**; **View** and edit on a street still work. To give a town a street, open one of its districts and use
  **Streets → Add…** there; unlinking it from every district of the town removes it from the town. A street no longer
  has a town of its own. A Town form's Streets field does nothing any more (the API ignores it); remove it in the form
  builder if you like (the [town streets smoke test § 3](../town-streets-smoke-test.md) has a check that lists such forms).
- Known gap ([#380](https://github.com/PandiO/knk-workspace/issues/380)): a section's edit action on a related record
  and its **Create New** are not greyed out without `knk.admin.content`; they open the form, which then says "Staff
  only — This page needs the knk.admin.content permission".
- Edits by others and a delete of the open record show live (§ 6).

**A permission group's Permissions panel** ([#50](https://github.com/PandiO/knk-workspace/issues/50), since
v0.3). On a permission group's detail page (**Dashboard → Permission Group** → **View**), below the details:

1. **Permissions** lists the group's own nodes with **Effect** (Granted/Denied) and **Expires** ("Never", or a date
   with "expired" once it has passed), and how many players the group reaches, members of groups that inherit from it
   included. Reading needs `knk.admin.user.manage`; without it the page says "Staff only".
2. The form under the list (**Node**, **Grant**/**Deny**, **Expires**, **Save**) adds a node or changes one the group
   already has; **Expires** is empty by default (permanent). The pencil on a row puts it in the form. Saving needs
   `knk.admin.user.perm`, the node yourself, and a group ranked below your own; without `knk.admin.user.perm` the form
   and the row buttons are greyed out with "Requires knk.admin.user.perm", and a refusal from the API shows under the
   list ("You can only change groups ranked below your own.").
3. Changing a node between Granted and Denied (the row's change button, or **Save** with the other value) and
   **Remove** (the X) ask first, with how many players it affects and that online players get the change within
   seconds. **Cancel** changes nothing. Adding a node or changing only its expiry doesn't ask.
4. **History** lists every change to the group's nodes, newest first, 10 per page: When, Change ("Permission granted",
   "Permission updated", "Permission removed"), By and Details.

Node rules and what a change does in game: [ranks, permissions and moderation § 3.3](ranks-permissions-moderation-admin-guide.md#33-a-groups-own-nodes-and-new-groups).
Smoke test: [dashboard access § 8.7](../dashboard-access-smoke-test.md#87-a-permission-groups-own-grants-50)
(automated in CI; manual steps not run).

**A delete that is refused because the record is still in use** (a street that structures point at) shows the API's
message with **Show what uses it** ([#44](https://github.com/PandiO/knk-workspace/issues/44)): the records per kind
("23 structures"), each a link to its detail page when you may read it, "… and n more" past 20. This works for a row's
Delete on the dashboard, the header's Delete and an item's Delete; since
[#289](https://github.com/PandiO/knk-workspace/issues/289) (since v0.3) also for a form configuration in Entity setup
and the rows of a bulk delete (§ 3), and for records skipped when you delete what a form created:

- **Cancel form** → **Delete them**, or Entity setup → Saved Progress → a draft's trash icon → **Delete draft and
  them**, deletes the records created while filling in the form, newest first. One that something else now uses is
  skipped: the report says, for example, "Deleted 1 of 2." and "District '…': skipped: in use (used by
  Structure.DistrictId)" with **Show what uses it**. Its list has every reference the in-use check counted, also links
  that would have been removed with the record. A link closes the report and opens that record.

A delete that fails for another reason (the API is down) has no **Show what uses it**.

Known gaps: some relationship pairs can't be linked here yet, and link-table changes don't update live
([#287](https://github.com/PandiO/knk-workspace/issues/287)).

Smoke tests: [entity detail](../entity-detail-smoke-test.md), [relation picker and delete details § 4](../relation-picker-and-delete-details-smoke-test.md),
[town streets](../town-streets-smoke-test.md) (not run).

## 5. Picking a related record in a form

A link field in a form (a town's domain, a structure's street, a list of tags) is a **search box**
([#191](https://github.com/PandiO/knk-workspace/issues/191)); the old "Select instance" table is gone. Start typing:
the first 8 matches show after a short pause, records created earlier in the same form on top, each with one detail
line. Arrow keys and Enter, or a click, pick one; Escape closes the list. In a list field a pick adds or removes one
record, up to the field's maximum. When there are more matches, keep typing, or press **Open full table** for the
full table with paging, sorting and filters.

Without read access to the related type (its area node), the box searches **by name only** (no full table) and says
so: "Names only: the full Street table needs one of: …". A type that can't be searched that way says "can't be searched
here. Requires one of: …". A field whose picker is narrowed by filters (a siege objective's **Initial holder team**,
scoped to the scenario's teams) offers the **narrowed** list in this mode too, names only (since v0.3,
[#288](https://github.com/PandiO/knk-workspace/issues/288); before, it refused with "This list is narrowed by …"). Only
a filter the type's lookup doesn't take still refuses, in red with no rows: "This list is narrowed by <filter>, which
only the full <type> search can do. Requires one of: …"; ask for the type's area node, or have someone who holds it
fill in that field. **Create New** for a link field is offered only with
the related type's create node and `knk.admin.content`. A table you can't read (for example a picker's **Open full table**) says "You don't
have access to Category. Requires one of: …" instead of "Failed to load data".

Smoke test: [relation picker and delete details](../relation-picker-and-delete-details-smoke-test.md) § 1–2 (§ 2.4–2.5
lookup filters automated in CI; manual steps not run).

### 5.1 The steps of a form: Next, clicking a step, and what stops you

Released in v0.2 (2026-11-14; [#68](https://github.com/PandiO/knk-workspace/issues/68),
[#88](https://github.com/PandiO/knk-workspace/issues/88)); the developer's first run on 2026-11-13 found
[#413](https://github.com/PandiO/knk-workspace/issues/413) and [#414](https://github.com/PandiO/knk-workspace/issues/414),
fixed before that release (knk-web-app#20, #22).

A form shows its steps in a strip above the fields; at phone width the label "Step x of n" opens the same steps as a
list. You move with **Next** and **Back**, or by **clicking a step** (Tab reaches every step, Enter or Space
opens it). A step that a display condition hides is not in the strip and is never checked.

1. **Back is always allowed.** Clicking an earlier step, or Back, checks nothing and keeps what you typed.
2. **Forward is checked.** Clicking a later step runs, for the step you are on and every step in between, the same
   checks as Next: required fields, list sizes, field validations, the step's conditions (§ 7.1), the blocking
   validation rules, and on a step with linked entries (for example a siege scenario's Gates) the required fields of
   every entry. The step you clicked is not checked itself, only whether it may be opened.
3. **The first step that fails stops you.** A dialog `Can't go to "<step>" yet` names that step and lists the
   fields and messages. When it is the step you are on, it says `Finish "<step>" first:` and the messages are also
   on the fields. When it is a step in between, it says `"<step>" needs your attention first:` and has a button
   `Go to <step>`, which opens that step at once with the messages in place. A later step that can't be opened yet
   is listed as `"<step>" can't be opened yet: <message>`. **×** and **Close** always close the dialog.
4. **Warnings don't stop you.** A validation rule that only warns lets the jump through. After you land, a dialog
   `Now on "<step>"` lists them under "Warnings (these don't stop you)".
5. **A check that could not run doesn't stop you either.** When a rule needs the game server and the server can't be
   reached, the jump goes through and the same dialog lists the rule under "Not checked: the game server could not be
   reached". Check those again on their step before you submit. (Any rule that could not run is listed under that
   heading, also when the cause was something else, [#396](https://github.com/PandiO/knk-workspace/issues/396).)
6. **A failed step condition stays visible.** When Next, Submit or a jump is refused by a step condition (this step's
   "before leaving" condition or the next step's "before entering" one, § 7.1), the message shows as a toast and in red
   **above the Next button**, where it stays until you try again or go back. The fields the condition's failing rules
   read are **marked** too: the message in red under the field, with the field's error styling, like a field
   validation rule ([#414](https://github.com/PandiO/knk-workspace/issues/414)). With one rule its field is marked;
   with "match all" each field whose rule fails; with "match any" every field of the condition (it only fails when
   all of them do). A mark goes away as soon as the condition holds, while the message above Next stays until you
   try again. Only fields on the step you are on are marked: a rule on a field of an earlier step keeps the message
   above Next only. A field that already shows its own error keeps that error. A condition in hand-written JSON
   (§ 7.1) marks no field.
7. **A jump saves like Next.** Landing on a later step saves your progress as a draft, the same as pressing Next, and
   the jump waits for that save: if it fails, you stay where you are and the reason shows in the red banner at the
   top of the form. **Go to …** in the dialog doesn't wait: it opens the step straight away and
   saves the progress in the background ([#413](https://github.com/PandiO/knk-workspace/issues/413)). If that save
   fails, the reason shows in the red banner at the top of the form, and the next Next saves again.
8. **An edit form or a resumed draft checks itself once.** When you edit an existing record or continue a saved
   draft, the form runs the validation rules of every step once after loading, before you touch a field, so a step
   already shows what its rules say when you open it. Nothing is saved by that run. A new, empty form doesn't do it.
9. While the form is saving or submitting, the steps can't be clicked.

Smoke test: [form step conditions and step jump](../form-step-conditions-and-step-jump-smoke-test.md) § 2, § 5, § 6
(not run).

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

**Since v0.2** ([#88](https://github.com/PandiO/knk-workspace/issues/88),
[#68](https://github.com/PandiO/knk-workspace/issues/68)): a **Step conditions** card in the form builder (what must
hold before a step may be left or opened) and form steps you can click to jump.

**Validation rules are part of the draft** (since v0.3,
[#291](https://github.com/PandiO/knk-workspace/issues/291); before, a rule applied to the published form as soon as you
saved it). A field's **Cross-Field Validation Rules** say "Rules are part of the draft: they are kept when
you save this field and the form, and staff get them when you publish. Until then the form uses the published rules."

1. **Add Rule**, **Edit** → **Save Rule** and **Delete** change the draft only; a new rule shows **Not published**.
   Deleting asks "The rule is removed from the draft; the published form keeps it until you publish." **Save Field**
   and then **Save** keep the changes.
2. A field you added in this draft can get rules before its first Publish. **Depends On Field** offers this form's
   fields, the new ones too.
3. **Publish…** lists the rule changes under "What changes for staff", for example "Validation rules: 1 added, 1
   changed, 1 removed.", and applies them with the rest. **More → Discard unpublished changes…** drops them.
4. Publish is refused, with nothing published, when a rule depends on a field that is no longer in the form ("The <type>
   rule on "<label>" depends on a field that is no longer in the form. Edit or delete the rule."), when a rule's own
   field is gone, or when rules depend on each other in a circle. Edit or delete the rule, then publish.
5. A draft saved before this change has no rules in it: its fields show the published rules, and Publish leaves them
   as they are.

Smoke test: [form and display builders](../form-display-builders-smoke-test.md) (run 2026-11-11/12, all pass; § 11, the
rules in the draft, automated in CI, manual steps not run).

### 7.1 Step conditions

In `next` since 2026-11-13 ([#88](https://github.com/PandiO/knk-workspace/issues/88)); not live-tested. Needs
`knk.admin.content`, like the rest of the builder.

A step condition says what must hold before someone filling in the form may **leave** a step or **open** it. Select a
step in the form builder: below its Display Conditions is the **Step conditions** card. It says "No conditions", or
for example "2 conditions, 1 off".

**Add condition**, then set:

1. **When.** "Before leaving this step (Next / Submit)" is checked when the user presses Next or Submit on this step.
   "Before entering this step" is checked when the user tries to open this step from the one before it (Next, or a
   click on a step, § 5.1). A "before entering" condition on the first step is never checked, because the form opens
   there.
2. **active.** Untick it to keep the condition but have the form skip it ("Switched off: the form skips this
   condition.").
3. **Message.** What the form says when the condition fails. A "before leaving" condition **needs** a message before
   you can publish; a draft may be saved without one. A "before entering" condition without a message says "This step
   can't be opened yet."
4. **Rules.** Each rule is a field, an operator and a value. The field comes from this step, or, with **from an
   earlier step** ticked, from any step before it. A new "before entering" condition starts with a field of an earlier
   step, since its own step is still empty at that moment. With two or more rules a **match all / any** switch
   appears. "In words:" under the rules reads the condition back, for example "Allow entry is ticked and Name
   (earlier step) is not empty". A condition without rules always passes.

| Field type | Operators | Value |
|---|---|---|
| Text, date and time | is, is not, is greater than, is less than, contains, is empty, is not empty | text |
| Whole number, decimal | the same | a number |
| Tick box | the same | ticked / not ticked |
| Choice (enum) | the same | one of the field's values |
| A linked record, a list, a material or enchantment picker, banner layers | **is empty, is not empty** only | none ("no value needed") |

"is" and "is not" compare the exact value, so a tick box compares with ticked or not ticked and a number with a
number. A list from which every entry was removed counts as empty.

**Saving and publishing.** Conditions are part of the draft: **Save** stores them, and the form people fill in only
gets them on **Publish…**. Publish refuses with `Step "<name>" has a "before leaving" condition without a message`
until every such condition has a message.

**When a rule's field is gone.** If the field a rule reads was renamed, removed or moved to a later step, the rule's
field box turns red, shows the stored name with "(missing)" and says the rule can never hold. The **Configuration
health** panel under the builder lists it too, under General: `Step '<name>': a "before leaving" condition reads the
field '<field>', which is not on this step.` (a note instead of a warning when the condition is switched off). The
panel checks your working copy, in the order the steps have in the form. It never stops a save or a publish, so fix
the rule before you publish: a form with such an active condition can't get past that step.

**What the person filling in the form sees.** When a condition fails, its message shows in a toast and above the
Next button, and the fields its failing rules read on that step show the message in red, like a field validation rule
(§ 5.1 item 6, [#414](https://github.com/PandiO/knk-workspace/issues/414)). So name in the message what has to change,
for example `Tick Allow entry first.`

**Hand-written JSON.** A condition whose stored JSON was not made with this editor is shown as text in a **Condition
JSON** box and saved unchanged. The form only understands the editor's shape: JSON in another shape is not checked
(the condition always passes), and text that is not valid JSON always fails, so the step can't be left
([#397](https://github.com/PandiO/knk-workspace/issues/397)). Remove such a condition and build it again with rules.

Smoke test: [form step conditions and step jump](../form-step-conditions-and-step-jump-smoke-test.md) § 1–4 (not
run).

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
  type's **Spawns** chip (Enabled/Disabled) on the Types tab (it needs `knk.admin.content` too, greyed out with "Requires …" without it,
  [#383](https://github.com/PandiO/knk-workspace/issues/383)) (boxes already in the world stay) and a token grant rule on the Token items tab (tokens
  already issued stay; switching on doesn't grant retroactively). Changes reach the game server at its next runtime
  refresh.
- **Currency policy** (`knk.admin.currency.policy`): coins and gems in two sections with **one Save**. The **lowest
  sender title** is picked from the title brackets. Switching a currency's payments off or on asks first ("Switch
  coins payments off? … no player can send coins with /pay until they are switched on again. Staff grants still
  work."); it applies at once and is recorded in the audit log. If someone else saved a currency meanwhile, that
  section says so and offers **Reload current policy**.
- **Road network** (`knk.admin.road`): the header's Save saves the navigation defaults per domain type together with
  the compass settings (a choice no longer saves on its own). Road profiles and stretches keep their own Save ("Save
  stretch #n") and are not counted in the header. A stretch's **Create New Street** needs `knk.admin.content`
  (shown greyed out with the reason without it, #383).
- Known gap ([#380](https://github.com/PandiO/knk-workspace/issues/380)): **New** and **Edit** on the Lootboxes Types,
  Specials and Areas tabs and a stretch's street **Rename** open the form wizard and are not greyed out without
  `knk.admin.content`; without it they lead to "Staff only".

Lootboxes and currency in detail (every tab and field, what a switch does to boxes and tokens already out, the
policy's limits, corrections and reversals): [economy admin guide § 2 and § 4](economy-admin-guide.md#2-currency).
The road guide is still to be written ([#298](https://github.com/PandiO/knk-workspace/issues/298)).

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
| **Select…** / **Add…** / **Unlink**, a value edited in place, the Lootboxes **Enabled** toggle or **Create New Street** greyed out: "Requires knk.admin.content" | Changing a record is an edit and needs the content node (#374, #383) | Ask for `knk.admin.content` if you should change records |
| A save answers "Creating or editing … requires … and knk.admin.content." | The API asks for the type's write node and the content node on every create and edit (#374), except for users, permission groups and road profiles | Ask for `knk.admin.content` |
| Delete refused with **Show what uses it** | Other records still point at it | Unlink or delete those first |
| Staff don't see a builder change | It is saved as a draft, not published | **Publish…** |
| **Publish…** refused: `Step "…" has a "before leaving" condition without a message` | A step condition checked on Next has no message (§ 7.1) | Type the message, or remove the condition |
| A form can't get past a step and shows a condition's message whatever you fill in | The condition reads a field that is gone or has moved (red rule in the builder, Configuration health warning), or its JSON is not valid | Fix or remove the rule in the builder (§ 7.1) and publish |
| Clicking a step opens **Can't go to "…" yet** | A step before it is unfinished (§ 5.1) | Fix the listed fields, or **Go to …** |
| A validation rule change applies before Publish | A web app and API older than v0.3 (#291): rules were saved outside the draft | Deploy v0.3; since then rules wait for Publish |
| **Publish…** refused: "… depends on a field that is no longer in the form." or "… depend on each other in a circle" | A validation rule reads a field you removed, or rules form a loop (§ 7) | Edit or delete the rule, then publish |
| A form configuration's Delete fails with "still used by … form field that opens it as a sub-form" | Another form opens it as a sub-form | **Show what uses it**, clear that field's or step's Sub-configuration, delete again |
| A picker says "This list is narrowed by …, which only the full … search can do." | You search by name only and the field's filter isn't one the lookup takes (§ 5) | Ask for the type's area node, or let someone who has it fill in the field |
| No "Updated by …" lines | Live updates off on the server, the connection is blocked, or you lack the type's area node | Reload; check `Realtime__WebLiveUpdatesEnabled` and the proxy's `/api/hubs/web` |

## Changes

1. 2026-11-15: release v0.3: "in `next`" markers of #404–#406, #408, #409, #50, #289, #288, #291 now "since v0.3", and
   of #68, #88, #413, #414 "since v0.2"; § 3 row actions are the last column again (#606) and Export as CSV downloads
   at once (#607); PandiO/knk-workspace#577
2. 2026-11-15: § 3 and § 4 "Show what uses it" for a form configuration, bulk delete rows and records skipped as in
   use; § 5 lookup pickers keep their narrowing filters; § 7 validation rules in the draft, applied on Publish; § 10;
   pointer to the ranks guide for the player profile; #289, #288, #291, docs #597 (in `next`)
3. 2026-11-15: § 3 the read-only Permission Grant table; § 4 a permission group's Permissions panel and History; #408,
   #50, docs #576 (in `next`)
4. 2026-11-15: § 4 a town's Streets are read-only, managed on the district; #409, docs #559 (in `next`)
5. 2026-11-14: § 3 pinned View / Edit / Delete column, same row lines, right-click menu with Shift+F10 and the
   context-menu key, greyed-out items, selection, Ctrl/Cmd + right-click; #404, #405, #406, knk-web-app#17, docs #526
   (in `next`)
6. 2026-11-14: § 5.1 "Go to …" opens at once and saves in the background, a failed save shows in the banner;
   § 5.1 and § 7.1 a failed step condition marks its fields; #413, #414, knk-web-app#20, docs #482 (in `next`)
7. 2026-11-13: § 5.1 the steps of a form: clicking a step, what stops you; § 7.1 step conditions in the form builder;
   #68, #88, docs #395 (in `next`)
8. 2026-11-13: Select / Change / Unlink / Add need `knk.admin.content`, the API refuses creates and edits without it,
   #374, docs #385
9. 2026-11-13: New, Edit and the forms need `knk.admin.content` again, #371, docs #378
10. 2026-11-13: § 1, § 3, § 4, § 5, § 9, § 10 checked against the default branches: New, Edit, the forms, link changes,
   hot edit, the lootbox toggle and Create New Street need `knk.admin.content`, #371, #374, #383; known gap #380; docs
   #347
11. 2026-11-13: dashboard per area, disabled actions with "Requires …", bulk delete, export through the API, names-only
   pickers, readable refusals; #280 AM3 and #205, docs #366
12. 2026-11-12: first version, PandiO/knk-workspace#337, #338, #340–#345
