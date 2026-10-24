# Form validation: step completion conditions (KNG-186) and the rule result log (KNG-269) — smoke test

**Status:** To test (written 2026-10-24); both branch pairs pushed, not merged
**Last updated:** 2026-10-24
**Linear:** [KNG-186](https://linear.app/kngpandi/issue/KNG-186) · [KNG-269](https://linear.app/kngpandi/issue/KNG-269)
**Branches:** knk-web-api `claude/kng-186-form-condition-isactive` (`2abb38a`) + `claude/kng-269-validation-result-log` (`355b819`); knk-web-app `claude/kng-186-form-condition-isactive` (`4831f97`) + `claude/kng-269-validation-result-log` (`7403e85`). Both pairs branch from trunk; merge the two of each repo locally (they touch `FormWizard.tsx` in different places).

Run on the dev server with the four branches merged locally in knk-web-api and knk-web-app (or trunk once merged). The region rules need the plugin running. Keep three windows open while testing: the API console (every rule run prints `[VALIDATION_TRACE_BACKEND]` lines; a reuse prints `Answered from the result log`), the browser's network tab, and a SQL client on the dev DB. Record each step in **Findings** at the end.

## 0. Setup

1. **Back up the dev database.**
2. **API:** `dotnet build knkwebapi_v2.csproj`, then `dotnet ef database update`. Expected: migrations `FormConditionAndValidationIsActive` (two `IsActive` columns, default 1) and `AddFieldValidationRunLogs` (new table `FieldValidationRunLogs`) apply. Start the API; `appsettings.json` has the new `ValidationResultLog` section (`Enabled` true, `ExternalStateTtlHours` 24, `RetentionDays` 30).
3. **Plugin:** running, with the region HTTP endpoint reachable from the API (the region rules call it).
4. **Web app:** `npx npm@11 ci` if needed, `npm start`.
5. **Data:** a Town with a WorldGuard region, and a District created with the default District form that lies inside it. The District seed (v1) carries a `RegionContainment` rule on the district's region against `TownId`, which is the rule this test watches. Note the District's id (`<D>`) and its form configuration id (`<F>`, Forms page).
6. Handy SQL, used below as **"the rows"**:
   `SELECT Id, RuleId, SubjectType, SubjectId, IsValid, DependencyKey, ExecutedAt FROM FieldValidationRunLogs ORDER BY Id;`

## 1. KNG-186 — step completion conditions run

The builder has no UI for step conditions yet (filed as [KNG-274](https://linear.app/kngpandi/issue/KNG-274)), so they are authored through the API. You don't need to hand-write requests: open the web app in the browser **logged in as an admin**, press F12 → **Console**, paste the helper below once, then call it.

```js
// KNG-186 test helper: adds / switches / removes a Completion condition on the District form's
// "Region and access" step ("Allow entry must be ticked"). Paste once, then call e.g. knkStepCondition('add').
// It renews the access token first (the stored one is short-lived) the same way the web app does.
window.knkStepCondition = async function (action, entity = 'District', stepMatch = /region and access/i) {
    const api = 'http://localhost:5294/api';                      // the API's HTTP profile; change if yours differs
    const store = localStorage.getItem('knk.accessToken') ? localStorage : sessionStorage;
    const refresh = async () => {
        const r = await fetch(`${api}/Auth/refresh`, { method: 'POST', credentials: 'include', headers: { 'Content-Type': 'application/json' }, body: '{}' });
        if (!r.ok) throw new Error(`Could not renew the session (${r.status}): log in to the web app again, then retry.`);
        const token = (await r.json()).accessToken;
        store.setItem('knk.accessToken', token);
        return token;
    };
    let token = await refresh();
    const call = async (method, path, body, retry = true) => {
        const r = await fetch(`${api}/${path}`, { method, headers: { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' }, body: body ? JSON.stringify(body) : undefined });
        if (r.status === 401 && retry) { token = await refresh(); return call(method, path, body, false); }
        if (!r.ok) throw new Error(`${method} ${path} → ${r.status} ${await r.text()}`);
        return r.status === 204 ? null : r.json();
    };
    let config = await call('GET', `FormConfigurations/${entity}?defaultOnly=true`);
    if (Array.isArray(config)) config = config.find(c => c.isDefault) || config[0];
    const step = config.steps.find(s => stepMatch.test(s.stepName));
    if (!step) return console.error('No step matching', stepMatch, 'in', config.steps.map(s => s.stepName));
    const isTest = c => c.errorMessage === 'Allow entry before you continue.';
    step.conditions = (step.conditions || []).filter(c => !isTest(c));
    if (action === 'add' || action === 'on' || action === 'off') {
        step.conditions.push({
            conditionType: 'Completion',
            conditionJson: JSON.stringify({ conditions: [{ fieldName: 'AllowEntry', operator: 'Equals', value: true }] }),
            errorMessage: 'Allow entry before you continue.',
            ...(action === 'off' ? { isActive: false } : {})   // 'add' sends no flag on purpose: the API must store it as active
        });
    } else if (action !== 'remove') {
        return console.error("action must be 'add', 'on', 'off' or 'remove'");
    }
    await call('PUT', `FormConfigurations/${config.id}`, config);
    const saved = await call('GET', `FormConfigurations/${config.id}`);
    const savedStep = saved.steps.find(s => stepMatch.test(s.stepName));
    console.log(`Form ${saved.id} "${saved.configurationName}", step "${savedStep.stepName}" conditions:`, savedStep.conditions);
    console.log('Configuration has isActive property:', 'isActive' in saved);
    return savedStep.conditions;
};
```

| Call | Does | Use in step |
| -- | -- | -- |
| `knkStepCondition('add')` | adds the condition **without** an `isActive` → must come back `isActive: true` | 8 |
| `knkStepCondition('off')` | same condition with `isActive: false` | 11 |
| `knkStepCondition('on')` | back to active (sends `isActive: true` explicitly) | 11 → 12 |
| `knkStepCondition('remove')` | removes it | 14 |

If it says it could not renew the session, log in to the web app again and paste the helper again. The helper prints the saved step's `conditions` and whether the configuration JSON still carries an `isActive` (it must not, step 7). Refresh the wizard page after each call: the wizard loads the configuration when the form opens.

7. **Default is active.** In the GET body, every entry under a field's `validations` and a step's `conditions` (if any) carries `"isActive": true`; the configuration itself has **no** `isActive` property. Expected: no `false` anywhere unless you set one before.
   *What is being tested:* a **step condition** (`conditions` on a step) is a third thing next to a field's **Required** checkbox and a field's **validation rules**. Required is checked first on Next; a step condition is a rule over the step's values that the builder can't author yet, so it is added through the API here.
8. **Add a completion condition** to the **Region and access** step (its Boolean fields are optional, so Required can't get in the way), without an `isActive`:
   ```json
   { "conditionType": "Completion",
     "conditionJson": "{\"conditions\":[{\"fieldName\":\"AllowEntry\",\"operator\":\"Equals\",\"value\":true}]}",
     "errorMessage": "Allow entry before you continue." }
   ```
   PUT, then GET again. Expected: the condition is stored with `"isActive": true` (a request without the flag means active).
9. **It blocks Next.** Open the District in the wizard (Edit), go to **Region and access**, untick **Allow entry**, click **Next**. Expected: a red **toast** (the notification that slides in at the page edge, from `ToastRegion`; not a field border) saying "Allow entry before you continue.", the wizard stays on this step, nothing is saved. Before KNG-186 this condition never ran.
10. **It passes when met.** Tick Allow entry, Next. Expected: the next step.
11. **Switched off.** In the GET body set that condition's `"isActive": false` and PUT the whole body back; GET shows `false`. Untick Allow entry, Next. Expected: the next step, no toast. This proves the flag round-trips and that a stored `false` is the one thing that switches a condition off (until KNG-186 the API sent `false` for every condition).
12. **Export/import keeps the flag.** Forms page → the District form → **Export**. Expected: the file shows `"isActive": false` on that condition and no `isActive` on active conditions or validations (so the shipped seed files are unchanged). Import the file as a non-default copy. Expected: the copy's condition is `false`; the copy's other rules are active.
13. **Builder still saves.** Open the District form in the builder, change the description, Save. Expected: saves without error (the form configuration no longer sends `isActive`). Create a new configuration from scratch, Save, Expected: same.
14. **Clean up:** PUT the District form without the test condition (or leave it `false`).
    Findings so far (2026-10-24, developer): step 7 accepted, step 10 passes; step 9 was first written against the Required field Description, which the Required check catches before any condition runs, and was corrected to the optional Allow entry.

## 2. KNG-269 — the result log

Each step says what the API console, the browser and the rows should show.

15. **First run, one request.** Open District `<D>` (Edit), Next through every step, Submit, changing nothing. Expected: on the region step the network tab shows **one** `POST …/field-validation-rules/validate-batch` with `subjectType: "District"`, `subjectId: <D>` (not one `validate` per field); the API console prints `Calling RegionContainment.ValidateAsync()` and the plugin log shows the containment check; the rows hold one row per rule of this form with `SubjectType = District`, `SubjectId = <D>`, `DependencyKey = Town:<town id>`, `ExecutedAt` now.
16. **Second run, answered from the log.** Open `<D>` again, Next through, Submit. Expected: the console prints `Answered from the result log (run of …)` for each rule and **no** `Calling … ValidateAsync()`; the plugin log stays quiet; under the field the same pass/fail message shows with "**· checked N min ago**" and the button reads **Re-check**; the rows are unchanged (same `ExecutedAt`).
17. **Re-check.** Press **Re-check** on that field. Expected: the console shows the validator running; the "checked … ago" note disappears (a fresh run); the row's `ExecutedAt` moves to now; still one row per rule.
18. **Changed input.** Pick a different Town on the step the rule depends on, Next. Expected: the rule runs (console), the row is replaced (new `ExecutedAt`, new `DependencyKey`), still one row. Change the Town back, Next. Expected: runs again, since the row holds only the most recent input.
19. **Changed rule.** Forms → District form → the region field's **Validation rules** → edit the rule's error message (or toggle "Block step progression"), save. Open `<D>`, Next. Expected: the rule runs (the rule hash includes its messages and blocking flag); the row is replaced.
20. **Region redrawn.** Re-run the District's region step (draw the region again), save. Expected: the API log prints `Dropped N stored validation results about Domain <D> after its region changed`; the rows for `<D>` are gone. Open `<D>`, Next. Expected: the rule runs and a row is written again.
21. **TTL.** Age the rows: `UPDATE FieldValidationRunLogs SET ExecutedAt = DATE_SUB(ExecutedAt, INTERVAL 25 HOUR);`. Open `<D>`, Next. Expected: the region rule runs (external state, 24 h TTL). If the form has a `ConditionalRequired` or `ConditionalValueMatch` rule, that one is still answered from the log (pure rules never expire).
22. **Plugin down is not remembered.** Stop the plugin. Open `<D>`, Next. Expected: the amber "Validation could not be completed" result; the rows are **not** overwritten (`ExecutedAt` unchanged, or no row if you deleted them). Start the plugin, press **Re-run validation** / Re-check. Expected: the rule runs and the row is written.
23. **Create mode.** Create a new District. Expected: the first Next's `validate-batch` has no `subjectType` (no draft yet, nothing stored); once the draft exists (from the second step on, or after a save) requests carry `subjectType: "FormSubmissionProgress"`, `subjectId: <draft id>` and rows appear with that subject. Submit. Open the new District. Expected: its rules run once (the draft's rows are not re-used), then are answered from the log on the next open.
24. **Separate subjects, cascade.** Open a second District, Next through. Expected: its own rows next to `<D>`'s. Delete a rule in the builder. Expected: that rule's rows are gone (cascade). Re-create it afterwards if it was the region rule.
25. **Readiness stays live.** Run a Siege readiness check that covers the District (or any saved-entity rule check). Expected: the API console shows the validators running, no `Answered from the result log` line (readiness passes no subject).
26. **Switch off.** Set `"ValidationResultLog": { "Enabled": false }`, restart the API, open `<D>`, Next twice. Expected: both runs live, no new rows. Set it back to `true`.

## Findings

| Step | Result | Notes |
| -- | -- | -- |
| | | |
