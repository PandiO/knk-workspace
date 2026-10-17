# Form wizard chain — smoke-test follow-ups

**Status:** Implemented, unit-tested, live test in progress (see "Live test" at the end); nothing merged, no PRs.
**Last updated:** 2026-10-16
**Belongs to:** the chain smoke test in [2026-10-11-form-wizard-chain.md](2026-10-11-form-wizard-chain.md) (sections A–F).
This file holds the fixes for what that test found, and the steps to check them.

## Branches

Branch `claude/wonderful-darwin-u39k1o` in all four repos.

- **knk-web-api, knk-web-app, knk-workspace:** started from `claude/jolly-archimedes-urhio9`, so they carry the
  whole chain and **replace that branch for merging**.
- **knk-plugin:** started from `main` `29bb6ff9`. The chain had no plugin changes.

| Repo | Commits on top of the chain |
|---|---|
| knk-web-api | `d2c8eaa` KNG-172, `6ac070c` KNG-173, `7faf3b1` + `d0f1928` KNG-166, `d9be7dd` KNG-169 |
| knk-web-app | `23382c4` KNG-167, `5b0f711` KNG-168, `1f819c8` KNG-173, `c4b2a86` KNG-172, `63a8e3e` + `9822e30` KNG-169, `ef2364f` KNG-166 |
| knk-plugin | `7e20152a` KNG-173, `cc6d981d` KNG-174 |

- **Migrations:** none new. The chain's two migrations still apply.
- **Merge order:**
  1. knk-web-api → `master`
  2. knk-web-app → `main`
  3. knk-plugin → `main` (independent of the other two)
  4. knk-workspace → `main`

## Tests

| Repo | Result |
|---|---|
| knk-web-api | 2646 passed, the same 4 known failures |
| knk-web-app | 861 passed, 4 known failures (was 5; KNG-169 fixed an outdated RoadsAdminPage test) |
| knk-plugin | `./gradlew build -x deployToDevServer`: 4005 passed, 0 failed |

## What changed

### [KNG-172](https://linear.app/kngpandi/issue/KNG-172) — opened form configurations can be deleted

- **Delete:** the repository detaches the configuration's workflow sessions. It deletes its drafts and the sub-form
  drafts under them, and its validation rules that depend on its own fields (a third blocker, found on a real MySQL
  8). All in one SaveChanges.
- **Refusal text:** lists only the references that block (Restrict/NoAction). A configuration used as a sub-form by
  another configuration is still refused, and only that use is named.
- **Forms page:** the delete confirm adds "Its N saved drafts are deleted too."

### [KNG-173](https://linear.app/kngpandi/issue/KNG-173) — warning is warning, block is block; failures name the parent

- **Plugin, region and location tasks:**
  - Every failure follows the rule's `isBlocking`. A warning shows "⚠ Validation warning", then saves.
  - Each failure adds `Must be inside District "…" (region domain_27).`, and the corners outside it for regions.
  - A missing parent region and a wrong world each get their own sentence.
  - The parent region is looked up in the dependency's own world.
  - All rules are checked, and a block beats a warning.
  - `select <region>` now runs the rules too.
- **API:** the rule's error text is followed by the same "Must be inside …" sentence, in the wizard check and the
  save check (`ValidationService`).
- **Web app:** relationship placeholders are the entity's name, not `[object Object]`.
- **Not done:** the web app can't yet say "that region doesn't exist". The plugin's contains-region endpoint answers
  `false` for a missing region, so the API can't tell it from "outside". Fixing that needs a different plugin answer
  (e.g. 404) plus an API change.

### [KNG-174](https://linear.app/kngpandi/issue/KNG-174) — one open world task at a time

- `/knk task claim` while a task is still open is refused before anything is claimed: "You still have task #N
  (WgRegionId) open. Finish it, or type 'cancel' to stop it, then claim again."
- The header reads `Task: GateStructure › LocationId`, or `Task: LocationId`, never `null`.

### [KNG-166](https://linear.app/kngpandi/issue/KNG-166) — picker columns

| Type | Picker columns |
|---|---|
| District | Town, World |
| Street | Districts, Towns |
| Structure | street + house number, District, Town |
| GateStructure | street + house number, District, Town, Doors |

- The list DTOs and the full read DTOs both carry these fields, so pinned rows and search rows show the same.
- **Admin column settings win:** a type with saved `defaultTableColumns` still shows only those columns, until they
  are cleared or the new keys are added.

### [KNG-167](https://linear.app/kngpandi/issue/KNG-167) — a capture keeps a typed Location name

Only X/Y/Z/Yaw/Pitch/World update. Name is filled only when empty.

### [KNG-168](https://linear.app/kngpandi/issue/KNG-168) — step strip

- **Wide screens:** a scrollable strip that keeps the current step in view. ‹ › buttons and fades appear only when
  steps are hidden on that side.
- **Narrow screens:** "Step 3 of 9 · Rotation" plus a progress bar.

### [KNG-169](https://linear.app/kngpandi/issue/KNG-169) — refusals explain why, no browser confirm boxes

- **Shared pieces:** `apiRefusalReason` / `failureReason` everywhere, and a shared `useConfirm` hook (FeedbackModal,
  red button for deletes).
- No `window.confirm` or `alert` is left.
- **API:** 22 DELETE actions leave a constraint refusal to the global filter, which names what blocks.
- **Wording guide:** in knk-web-app `README.md` → Conventions.

### Found in passing, not fixed

- `logging.errorHandler.next(...)` messages are never shown: `App.tsx` never renders `errorContent`. Check this
  against [KNG-141](https://linear.app/kngpandi/issue/KNG-141) (error toasts).
- Saving default columns on the Forms page reports success even when the save was refused
  (`useEntityMetadata.createConfiguration`/`updateConfiguration` swallow errors).

## Test steps (section G, after the chain's E/F)

Build and deploy the plugin from this branch: `./gradlew :knk-paper:dev`, then restart the dev server. Run the API
and web app from this branch.

### G1. Delete a form configuration (KNG-172)

1. Delete the GateStructure and GateDoor copies left over from E3/E4. Expect a confirm naming their saved drafts,
   and the delete succeeds.
2. Import a fresh copy, open it with Use, cancel, and delete it. Expect success.
3. **Optional:** try to delete a siege join seed that `SiegeScenario` uses as a sub-form. Expect a refusal naming
   only "form step(s) that use it as a sub-form".

### G2. Warning vs block in Minecraft (KNG-173)

1. **Warning:** use the GateStructure seed with District "kng-162 step d2.5". Claim the Region task and `save` a
   selection that sticks out of the district. Expect all of:
   - "⚠ Validation warning";
   - `Must be inside District "kng-162 step d2.5" (region domain_27).`;
   - the corners outside it;
   - "saving anyway", and the task completes.
2. **Missing region:** if `domain_27` really doesn't exist in `knk_hub`, expect instead: `District "…" has region
   domain_27, but that region doesn't exist in world knk_hub, so the check couldn't run.` It is still a warning.
   This shows why it failed on 2026-10-12.
3. **Wrong world:** stand in another world and `save`. Expect the "is in world …, but District … is in world
   knk_hub" sentence.
4. **Block:** in the builder, set the rule to blocking and repeat step 1. Expect "✗ Validation failed", the same
   names, and nothing saved. Set it back afterwards.
5. **Web app:** expect the same rule's warning to end with `Must be inside District "…" (region …).`

### G3. One task at a time (KNG-174)

1. Leave a Region task open, then claim the spawn Location task. Expect "You still have task #… open …", and the
   Location task stays Pending.
2. Type `cancel`, then claim again. The claim works, and the header reads `Task: … › LocationId`.
3. **Location capture:** `save` works. A capture outside the parent warns or blocks per the rule, with the
   "Must be inside" line, shown once.

### G4. Pickers (KNG-166)

1. **District picker:** in a Street form, the Districts picker shows Town for existing rows and for a District
   created with Create New.
2. **Structure / GateStructure pickers:** e.g. SiegeObjective → Gate shows street + number, District, Town.
3. If a picker still shows only ID + Name, that type has saved table columns. Clear them in the column editor.

### G5. Location name (KNG-167)

In a Location child form, type a Name, then Send to Minecraft and capture. The Name stays, and the coordinates
fill in.

### G6. Step strip (KNG-168)

1. Open the GateDoor seed on a wide window. The steps scroll, the current step stays visible, and ‹ › show only
   when steps are hidden on that side.
2. Narrow the window below about 640 px. Expect "Step N of M · name" plus a bar.

### G7. Refusal messages (KNG-169)

1. Delete something that is in use, e.g. a Street with a Structure. Expect "This street can't be deleted: it is
   still used by 1 structure. …".
2. In the form builder, change the default configuration and delete a validation rule. Expect a modal, not a
   browser box.

## Live test

### 2026-10-16, run 1

Plugin, API and web app from this branch. The chain's sections 0, A–D, E1–E5, F1 and F2.1–F2.3 had passed on
2026-10-12 (their findings are the issues above).

- **Setup:** done; GateDoor default set back to 12 (the E4 copy had been imported as default).
- **G1.1:** the GateStructure copies deleted. The GateDoor copy (configuration 45) **failed**: EF refused with
  "association between FormField and DisplayCondition has been severed". GateDoor's toggles and Rotation step have
  display conditions that read other fields of the same configuration (`SourceFormFieldId`, required, Restrict),
  and KNG-172 only cleared the validation rules. **Fixed** in knk-web-api `f33fd10`: the delete also removes the
  display conditions of the configuration's steps and fields. `FormConfigurationDeleteTests` now has a field
  condition and a step condition and failed with the same error before the fix. API: 2643 passed, 8 failed (the
  4 known plus the 4 date-dependent ones noted on 2026-10-12). Retest G1.1–G1.3.
- **E6:** accepted without running.
- **F2.5:** configuration 9 has nothing the seed lacks. The seed's House number field isn't needed for a gate:
  removed from `GateStructure.json` in knk-web-api `251ea5c` (in place, since the seed hasn't been merged; a gate
  saved through it keeps 0, which the pickers hide). The dev DB's imported v1 copy still has the field; delete
  it in the builder or re-import after deleting the copy.

### 2026-10-17, run 2

- **F3.1 failed:** creating a new GateStructure's region (rule failing: region outside the district) answered
  500, "A possible object cycle was detected … `$.Metadata.DependencyValue.TeleportMinPremiumGroup.ParentGroup.
  ChildGroups…`". `ValidationService` replaces an id-only dependency by the saved record (since 459ea5f, also on
  `master`) and returned that tracked entity in `Metadata.DependencyValue`; its navigations were fixed up with
  permission groups loaded earlier in the request, which point at each other. Only a failed rule's result carries
  the metadata. **Fixed** in knk-web-api `65435bd`: the metadata echoes the value the form sent, the validator still
  gets the record. New test in `ValidationServiceDependencyRecordTests`. API: 2644 passed, the same 8 failures.
  Retest F3 from step 1.
- **F4:** passed. F4.2 works for Districts and Gates; the developer wants M2M steps whose join entry has nothing to
  fill to pick the related entities directly: [KNG-183](https://linear.app/kngpandi/issue/KNG-183) (backlog).
- **F5:** siege seeds made default (F5.1). F5.2 not run yet (Readiness is the last step of the SiegeScenario form,
  edit mode only). F5.3 (undo) dropped: see F6.
- **F6:** the developer keeps the seeds as the defaults.
