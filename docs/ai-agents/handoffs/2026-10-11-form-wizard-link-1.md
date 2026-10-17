Read docs/ai-agents/handoffs/FORM_WIZARD_CHAIN.md first (branch claude/jolly-archimedes-urhio9) and follow it;
it overrides anything below.

Implement link 1 — KNG-133: "Form wizard: an entity made with Create New on a List relationship field is never saved
(new District in a Street form is silently dropped)" end to end (code, tests, docs, commits, push to
claude/jolly-archimedes-urhio9, progress report, Linear, handoff) as link 1 of the chain.

State you start from: feature branch = trunk heads (knk-web-app `38854ba`, knk-web-api `917537a`, knk-plugin
`1b3e06c2`); knk-workspace branch carries the specs, charter and report. Tracker baselines on trunk (2026-10-11):
web app 654 passed / 5 failed, API 2550 passed / 4 failed — re-measure before changing anything.
What earlier links left for this link: nothing (first link). The coordinator only wrote docs and Linear issues.
Link-specific reading: docs/specs/form-configurations/FORM_WIZARD_SESSION_CONCEPTS.md §2.1-2.2, §3.1, §5 item 1;
Linear KNG-133. Code: knk-web-app src/components/FormWizard/FormWizard.tsx (handleOpenChildForm ~1793-1832,
handleChildFormComplete ~1885-1993), src/utils/forms/normalizeFormSubmission.ts (extractId ~79-101,
single-object branch ~451-468, handleCollectionRelationship ~478-512), FieldRenderers.tsx ListField (~1135-1415),
tests in src/components/FormWizard/__tests__/ (FormWizard.listCreateNew.ui.test.tsx) and
src/utils/forms/__tests__/normalizeFormSubmission.test.ts; knk-web-api Services/StreetService.cs (~69-79).
Open flags that affect this link: D1 = A is decided (save on child completion; Location stays embedded). Whether the
developer's Street form uses a List field or a many-to-many step for Districts is unknown — handle both, note it in
the live checklist.
Known risks: KNG-120 / KNG-132 unmerged edits in FormWizard.tsx (keep yours thin); a List field whose entity can't be
created on its own (required parent id) — check findParentLinkField prefill still works when persisting.
Next after you: link 2 (KNG-134).
