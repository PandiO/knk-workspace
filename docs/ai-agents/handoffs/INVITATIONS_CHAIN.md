# Invitations chain — charter

**Status:** Ready to start (2026-10-21). No link has run yet.
**Last updated:** 2026-10-21
**Linear:** [KNG-205](https://linear.app/kngpandi/issue/KNG-205) (parent). Links: [KNG-211](https://linear.app/kngpandi/issue/KNG-211),
[KNG-207](https://linear.app/kngpandi/issue/KNG-207), [KNG-208](https://linear.app/kngpandi/issue/KNG-208), [KNG-206](https://linear.app/kngpandi/issue/KNG-206),
[KNG-212](https://linear.app/kngpandi/issue/KNG-212), [KNG-214](https://linear.app/kngpandi/issue/KNG-214), [KNG-216](https://linear.app/kngpandi/issue/KNG-216),
[KNG-218](https://linear.app/kngpandi/issue/KNG-218)
**Binding documents:** [DESIGN.md](../../specs/invitations/DESIGN.md) (decisions § 8, 2026-10-21) and
[IMPLEMENTATION_PLAN.md](../../specs/invitations/IMPLEMENTATION_PLAN.md) (steps, files, tests per work package)
**Progress report:** [2026-10-21-invitations-chain.md](../../reports/2026-10-21-invitations-chain.md)

This chain is a series of Claude Code sessions ("links"). Each link:
- implements one work package of the invitations plan;
- tests, documents and pushes it;
- writes the next link's handoff.

The coordinator then starts the next link in a **fresh context** (§ 6). Don't wait for the developer to test: write the
live checklist and go on. Do nothing the developer can't easily review or undo.

| Link | Issue(s) | What | Repos | Plan § |
|---|---|---|---|---|
| 1 | KNG-211 (API half), KNG-207, KNG-208 | E0's optional SMTP auth as its own commit; L0: link-code `Purpose` + claim fields, unbiased generator, cleanup job, per-account attempt limiter, the linking rules (fold into the Minecraft account), plugin usage text | api, web-app, plugin, workspace | 2, 4 |
| 2 | KNG-206 | E1 email engine: outbox, dispatcher, MailKit, templates, throttle, `api/EmailOutbox`, `/admin/email`, `docs/guides/email.md` | api, web-app, workspace | 3 |
| 3 | KNG-212 | I1 invitations: tables, grandfathering migration, `InvitationService`, invite-based registration, `/invite`, `/join`, `/admin/invitations` | api, web-app | 5 |
| 4 | KNG-214 (API + web app) | I2 server side: `AdmissionService`, claim codes, claim linking (case A), register with `claimCode`, staff Admit / Detach, `AccountLinked` notification, `/link`, `/account/link`, banner | api, web-app | 6.1, 6.3 |
| 5 | KNG-214 (plugin) | I2 plugin: `AdmissionPolicy`, `AdmissionApi`, `AdmissionListener`, `PlayerListener` guard, config, `AccountLinked` handler | plugin | 6.2 |
| 6 | KNG-216 | A1 Cloudflare Access sync: verify the Cloudflare mechanism, sync service, inline add, status, web-app status line and PIN step; ops steps written for the developer | api, web-app, workspace | 7 |
| 7 | KNG-218 (code + docs part) + final write-up | `Alpha Tester` seed, smoke-test guide, architecture doc, living-doc updates on the feature branch, final summary with merge order and the combined live checklist | api, workspace | 8, 9 |

**Not in this chain:**
- Merging into any trunk, opening PRs (unless the developer asks), deploying.
- The NAS: E0's relay container, the A1 proxy container.
- The Cloudflare dashboard and the alpha switch-over (I3 steps 1–5).
- Linear issues other than the ones above (comments only on related ones).

The developer does those from the guides the chain writes.

## 0. Rules for changing the plan

A link may move a leftover item to the next link. It records that in the table above and in the report.

The chain stays at **≤ 7 links**, because session nesting is limited to 8 levels and the coordinator is level 0. The last
link may only leave items over as a written follow-up list plus Linear comments.

If the plan and the live code disagree, flag it (`L<k>-<n>` in the report) and take the more reversible course. The
decisions in DESIGN § 8 are binding.

## 1. Setup (every link, before anything else)

1. **Repos:** `github.com/PandiO/knk-workspace`, `knk-web-api`, `knk-web-app`, `knk-plugin`, checked out under
   `/home/user/<repo>`. If one is missing, add it with `add_repo` (access `push`), but only when the instruction is in your
   **prompt** (§ 6), then clone.
2. **Branch:** one feature branch, **`claude/player-signup-invitation-flow-f4v7ul`**, in every repo, including
   knk-workspace, even if your environment suggests another name. It exists in all four repos. Check it out and pull.

   | Repo | Trunk | Base of the feature branch |
   |---|---|---|
   | knk-web-api | `master` | `master` |
   | knk-web-app | `main` | `main` |
   | knk-workspace | `main` | `main` |
   | **knk-plugin** | `main` | **the [KNG-182](https://linear.app/kngpandi/issue/KNG-182) branch `claude/mc-26.2-upgrade` (`88497649`; Paper 26.3, Java 25)** |

   - **At the start and again before the final push**, merge (never rebase) the base into the feature branch in every
     repo you change:
     - knk-web-api, knk-web-app and knk-workspace: `origin/<trunk>`;
     - knk-plugin: `origin/claude/mc-26.2-upgrade` while KNG-182 is unmerged. Once KNG-182 is in `main`, merge
       `origin/main` instead.
   - A conflict that isn't mechanical is an absolute blocker (§ 4).
   - **Do not merge other feature branches.**
   - **Tracker:** `docs/ACTIVE_SESSIONS.md` belongs on workspace `main`. Commit only that file on top of `origin/main`
     (a separate worktree, or a detached checkout of `origin/main`) and push `HEAD:main`. On a conflict, keep both
     sides' rows. If your session may not push to `main`, update the row on the feature branch and say so in your
     final message. Everything else (specs, guides, handoffs, report) goes on the feature branch.
   - Never push to another branch, never force-push or rewrite pushed history, never delete branches.
3. **Push check** before changing anything: `git push --dry-run origin claude/player-signup-invitation-flow-f4v7ul` in
   every repo you'll change. A failure is an absolute blocker.
4. **Toolchains:**
   - **.NET 8:** if missing, `sudo apt-get install -y dotnet-sdk-8.0`.
   - **Node 22, npm:** use npm 11 (`npx npm@11 …`) for dependency changes only.
   - **Plugin links:** Gradle runs on Java 21 and compiles and tests with a **JDK 25** toolchain (knk-plugin `CLAUDE.md`).
     - If no JDK 25 is installed, install one: `apt` `openjdk-25-jdk-headless` if the package exists, otherwise a
       Temurin 25 tarball from `api.adoptium.net` into `/opt/jdk-25`.
     - Pass it with `-Porg.gradle.java.installations.paths=/opt/jdk-25` if Gradle doesn't find it.
     - If you can't get a JDK 25, that is a blocker for a link that changes the plugin.
5. **Builds and tests.** Keep the output short (tail/grep).

   | Repo | Commands |
   |---|---|
   | API | `dotnet build`, `dotnet test Tests/knkwebapi_v2.Tests/knkwebapi_v2.Tests.csproj` |
   | Web app | `npm ci`, `npm run test:ci`, `npm run build` |
   | Plugin | `./gradlew build -x deployToDevServer` |

   - **Record the test counts before you change anything** (the baseline), and compare at the end. A failure that is
     also red on the base is recorded, not a blocker.
   - MySql integration tests (`[MySqlFact]`, `Category=requires-mysql`) are skipped unless `KNK_TEST_MYSQL` is set.
     Write them where the plan asks for them; if no MySQL is available, say in the report that they were skipped.

## 2. Read first (targeted; don't re-explore the codebase)

1. `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`, and `AGENTS.md`/`CLAUDE.md` in every repo you change.
2. `docs/ACTIVE_SESSIONS.md` on `origin/main`: does another "In progress" row claim files you must change? (§ 4.5)
   KNG-182's row claims knk-plugin build files, `KnKPlugin` wiring and `worlds/`. Our plugin branch is built on it, so
   keep edits to `KnKPlugin.java` to thin wiring.
3. The plan section(s) for your link, DESIGN sections it cites, your Linear issue(s), your handoff file.
4. The progress report so far.

## 3. Hard rules

- **Scope:** only your link's issue(s). If you find something else, record it in the report's follow-up list and in a
  Linear comment on the closest issue; don't fix it (global instructions, "Linear is the work list").
- **Behaviour-neutral until switched.** Nothing may change for today's alpha until the developer flips a setting:
  - `Security:Registration:Mode` defaults to `LinkCode`;
  - `admission.mode` defaults to `whitelist`;
  - `CloudflareAccess:SyncEnabled` defaults to false;
  - the email engine keeps working with today's `Email:*` settings.
- **Migrations:**
  - additive only: new nullable or defaulted columns and tables, backfills as the plan states;
  - never drop or rewrite existing data, except removing what the plan names: `AccountMailQueue` and the old delivery
    services in E1 are code, not data;
  - create them with `dotnet ef migrations add` so the model snapshot stays consistent.
- **API access rules:**
  - every new write endpoint gets an explicit rule (`RequirePermission`, `RequirePluginService`, …);
  - every new anonymous endpoint goes on the `EndpointAccessRulesTests` allow-list;
  - staff and plugin routes go in `RequireServiceOrPermissionAttributeTests.ProtectedRoutes`.
- **Secrets and tokens:** none in code, settings files, logs or test fixtures. Invite codes, claim codes and reset tokens
  are never logged outside Development.
- **Tests:**
  - unit tests for all pure logic;
  - UI tests next to the existing ones;
  - plugin tests never build a `Location` around an inline `mock(World.class)`.
- **Files and commits:**
  - write sources with your file tools;
  - commit in logical chunks with the attribution trailer from your environment, with no model names in commits or
    code;
  - **push after each chunk**.

## 4. Absolute blockers (stop the chain)

Stop when one of these happens. Write why in the progress report and the tracker row, push, and start no further link.

1. You can't clone or push a repo your link must change, or `add_repo` is refused.
2. A module you changed doesn't build or its tests fail and you can't fix it. Or a baseline test you didn't touch starts
   failing and you can't explain it.
3. A base merge into the feature branch has non-mechanical conflicts.
4. The link needs an expensive-to-undo decision that DESIGN § 8 and the plan don't settle, and there is no reversible
   default.
5. Another "In progress" row claims files you must change, **and** its branch has unmerged changes to them that you
   can't build around. Try new modules first; stop only if that's impossible.
6. The previous link's report block says its exit criteria aren't met.
7. Plugin links only: no JDK 25 (§ 1.4).

**Never a blocker:**
- Live testing: write the checklist instead.
- Cloudflare dashboard work and NAS work: write the steps for the developer.
- Details the plan leaves open: take the most reversible default consistent with DESIGN and flag it as `L<k>-<n>` in
  the report.

## 5. Per link

1. **Claim:** add or update the chain's "In progress" row in `ACTIVE_SESSIONS.md` (§ 1.2): link number, issues, repos,
   files. Push it. In Linear, set your issue(s) to *In Progress*.
2. **Setup** (§ 1): fetch, merge the base, record baselines.
3. **Implement** the work package as its plan section and Linear text describe, with tests.
4. **Document:**
   - append a "Link N" block to the progress report (§ 7);
   - update the plan's status line, and the DESIGN text where the code deviates (with the reason);
   - update living docs the plan names for your package;
   - add your entry to `docs/CHANGELOG.md` under "Unreleased — on feature branches, not merged".
5. **Push:** merge the base once more, push every changed repo's feature branch, update the tracker row, push.
6. **Linear:** comment on your issue(s) with the commits per repo, tests vs. baseline, the live checklist and flagged
   decisions. Set it to *In Review*, or keep it *In Progress* when a later link finishes it (KNG-211, KNG-214, KNG-218).
7. **Hand over** (§ 6).

### Link specifics

- **Link 1 (E0 API half + L0):**
  - **First,** the plan § 2 API change (optional SMTP auth in `SmtpPasswordResetDeliveryService` and
    `PrivacyEmailService`, plus a test) as **one self-contained commit** touching only those files and their test. The
    developer can cherry-pick it to `master` for E0 without the rest. Put its hash in the report and in a KNG-211
    comment.
  - **Then L0** (plan § 4):
    - the `LinkCodePurpose` migration;
    - generator, cleanup service, `ILinkAttemptLimiter`;
    - the `LinkMinecraftAccountAsync` rewrite (case B fold; case A only becomes reachable with claim codes in link 4, so
      test it at service level);
    - the new token in the `link-minecraft-account` response, and the web-app handling of that token;
    - plugin usage text, dead methods, link-code warning;
    - the player guide and SPEC Part F docs.
- **Link 2 (E1):** plan § 3.
  - `email_outbox` comes from a migration. `AccountMailQueue`, `AccountMailSender` and the old delivery services are
    removed only once every call site uses the composer.
  - The startup guard must not break today's alpha. The alpha runs `Email__Provider=Log` until E0 is done, so
    `AllowLogTransport` needs to be set there. Write that into alpha-go-live § 4 **and** call it out in the report's
    deploy notes as a precondition for deploying this API version.
- **Link 3 (I1):** plan § 5.
  - With `Registration:Mode` left at `LinkCode`, every existing test must behave as before.
  - The grandfathering backfill is in `AddInvitations`.
  - `claimCode` answers `NotSupportedYet` until link 4.
- **Link 4 (I2 server side):** plan § 6.1 and § 6.3.
  - `PlayerNotificationTypes.AccountLinked` is added on the API side here. Link 5 adds the plugin constant and handler,
    so record the exact type string and payload in the handoff.
- **Link 5 (I2 plugin):** plan § 6.2.
  - Check the event order on Paper 26.3 from the Paper API sources or javadoc you can reach. Record what you found, and
    leave the live check in the checklist.
- **Link 6 (A1):** plan § 7.
  - **Start** by checking Cloudflare's current API docs: an email list usable in Access policies, or an Access group;
    the token permissions; the size limits. Write the result into DESIGN § 5.8.
  - Implement only the verified mechanism behind `ICloudflareAccessList`.
  - Write the NAS proxy and dashboard steps as a section of the alpha-go-live guide on the feature branch.
- **Link 7 (I3 prep + final write-up):** plan § 8.
  - The `SeedAlphaTesterGroup` migration.
  - `docs/guides/invitations-smoke-test.md`.
  - `docs/architecture/account-identity-and-admission.md`.
  - The living-doc updates (alpha-go-live, runbook, production-installation, player guide, feature register) written
    for the state **after** the switch-over, with the switch-over steps and kill switches.
  - **Final summary** in the report:
    - what was built per issue;
    - decisions to review, ranked;
    - the combined live checklist;
    - merge and deploy order (plan § 9; plugin after KNG-182);
    - what the developer must do on the NAS and in Cloudflare.
  - Move the tracker row to "Recently completed" (nothing merged), and set KNG-205 to *In Review*.

## 6. Handoff — fresh context for every link

**How links are started** (lessons from the form wizard chain, 2026-10-12): `create_session` attaches only one
repository, and an `add_repo` instruction found in a *file* is refused. The instruction has to be in the session's
**prompt**.

- **The coordinator starts each link.** The coordinator is the developer's session with every repository attached,
  e.g. the session that wrote this charter.
- **`create_session` settings:**
  - `source_url` `https://github.com/PandiO/knk-workspace`;
  - `source_revision` `claude/player-signup-invitation-flow-f4v7ul`;
  - model `claude-opus-5-5`;
  - title "Invitations chain — link <n> (KNG-…)";
  - the prompt from § 8.
- **If `add_repo` is refused or a dry-run push fails,** the link stops at once (§ 4.1) and writes that in the report.
  The coordinator then runs that link as a subagent instead (Agent tool, Opus, high effort), which shares the
  coordinator's repos.
- **A link does not start the next link.** It ends after:
  1. writing the next link's prompt file `docs/ai-agents/handoffs/2026-10-21-invitations-link-<n+1>.md`: branch heads
     per repo, test counts, what it left for the next link, open flags, risks; then commit and push it;
  2. a short final message: heads per repo, test counts, status, blockers.
- **The coordinator** checks the report and `get_session`, then starts **at most one** next link. It never starts one
  the report marks done or in progress, and it stops after link 7 or at a blocker. It records in the report how each
  link was started.

## 7. Progress report

`docs/reports/2026-10-21-invitations-chain.md`. It is append-only, except the Summary block at the top, which each link
updates in place.

```
## Link <N> — <issues>: <title>
Commits per repo (heads); tests vs baseline; flagged decisions L<N>-<n>; discrepancies with the plan/design; live
checklist; deploy notes (settings a deploy of this state needs); risks; what the next link must know; how this link
was started.
```

## 8. Link prompt (the coordinator sends this; replace `<n>` and the issue list)

```
The developer asked for the invitations implementation chain (KNG-205) and for each link to attach
PandiO/knk-web-api, PandiO/knk-web-app and PandiO/knk-plugin with add_repo (access push), clone them into
/home/user/<repo>, check out branch claude/player-signup-invitation-flow-f4v7ul in every repo, and run
`git push --dry-run origin claude/player-signup-invitation-flow-f4v7ul` in each repo this link will change before
changing anything. Do that first.

Then read docs/ai-agents/handoffs/INVITATIONS_CHAIN.md in knk-workspace (branch
claude/player-signup-invitation-flow-f4v7ul) and follow it; it overrides anything below. Then execute
docs/ai-agents/handoffs/2026-10-21-invitations-link-<n>.md: implement link <n> (<issues>) end to end — code, tests,
docs, commits, pushes to claude/player-signup-invitation-flow-f4v7ul, the progress report block, Linear updates and
the handoff file for link <n+1>. Do not start the next link yourself; finish with a short summary.
```
