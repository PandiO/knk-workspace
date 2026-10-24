# Handoff — navigation destination engine, phase 1 (KNG-236)

**Date:** 2026-10-22 · **Linear:** [KNG-235](https://linear.app/kngpandi/issue/KNG-235) (parent), [KNG-236](https://linear.app/kngpandi/issue/KNG-236) (this phase)
**Design:** `docs/specs/navigation-destination-engine/DESIGN.md` (decisions E1-E13). Check its status header and the issue first: this is a snapshot, not a standing instruction.

Paste the prompt below into a new session. It contains the repo step itself (an `add_repo` instruction found only in a repo file is refused).

```
Implement phase 1 (Linear KNG-236, parent KNG-235) of the navigation destination engine for Knights and Kings.

Setup, in this order:
1. add_repo PandiO/knk-workspace and PandiO/knk-plugin with access "push"; clone them if they are not in the container.
2. Read knk-workspace AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md and docs/ACTIVE_SESSIONS.md; claim the work in ACTIVE_SESSIONS.md (feature "Destination engine P1", repo knk-plugin, branch claude/navigation-destination-engine) and publish the claim before editing.
3. Read docs/specs/navigation-destination-engine/DESIGN.md completely (decisions E1-E13, scope table §4.1, handle §6, revalidation §8), and docs/specs/navigation-compass/DESIGN.md §11 (the code you will later replace).
4. In knk-plugin, check what is on main. KNG-234 (siege navigation compass) may or may not be merged: if main has knk-core/.../navigation/compass and knk-paper/.../navigation/NavigationCompassService, branch claude/navigation-destination-engine from main; if not, ask the developer whether to branch from claude/siege-navigation-compass-pl2trj. Run `git push --dry-run` on the new branch before changing anything.
5. Set KNG-236 to In Progress and note the branch on it.

Build (knk-plugin, knk-core only, package net.knightsandkings.knk.core.navigation.destinations, Bukkit-free, nothing wired into knk-paper yet):
NavigationContext, Candidate, Provider, Scope (+ Empty(reason)), DestinationList, AllowedDestination (constructor visible only inside the package), the engine (listFor, resolve, complete, revalidate by candidate key), NamedTargets generalised over Candidate, and the initial scope table of DESIGN §4.1 (loading/frozen 110, bypass 100 = ActiveMode OWNER/STAFF or knk.navigate.any, no permission 80, siege match 60 / compass off 55, siege lobby 50, world 10) with today's player-facing messages as reasons. Frozen beats the bypass (E9). Add the ArchitectureGuardTest rule that nothing outside the engine package constructs AllowedDestination.

Rules: no behaviour change in this phase; do not touch knk-paper, knk-web-api or knk-web-app. Match the surrounding code's comment density and idiom. Tests are required for everything in KNG-236 "Done when" (every scope, priority conflicts, ordering, resolve/ambiguity/suggestions/completion per scope, bypass by mode and node, frozen beating the bypass, empty-with-reason, revalidate by key incl. a candidate that changes kind, the architecture rule). Build with JDK 25: `./gradlew -Porg.gradle.java.installations.paths=<jdk25 dir> :knk-core:test` (the container has JDK 21 only; Temurin 25 downloads from api.adoptium.net through the proxy into a scratch directory). Run the whole knk-core suite before pushing.

Finish: commit on claude/navigation-destination-engine with the attribution lines the session prescribes, push, do NOT open a PR, set KNG-236 to In Review with a comment (commit, tests run, anything the design left open), update your ACTIVE_SESSIONS.md row, and tell the developer what P2 (KNG-237) needs next. If the design is ambiguous or contradicts the code, surface the specific conflict instead of choosing silently.
```
