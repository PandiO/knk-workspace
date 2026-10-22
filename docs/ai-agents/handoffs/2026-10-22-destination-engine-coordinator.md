# Handoff — coordinator session for the navigation destination engine (KNG-235)

**Date:** 2026-10-22 · **Linear:** [KNG-235](https://linear.app/kngpandi/issue/KNG-235) (parent), phases KNG-236 (P1), KNG-237 (P2), KNG-238 (P3), KNG-239 (P4), KNG-240 (P5)
**Design:** `docs/specs/navigation-destination-engine/DESIGN.md` (decisions E1-E13). Check its status header, the issues and `docs/ACTIVE_SESSIONS.md` first: this file is a snapshot, not a standing instruction.
**Pattern:** "Session chains" in `docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md`: one coordinator with every repo attached starts each link; links do not start the next link.
**Single-phase start (no coordinator):** `2026-10-22-destination-engine-p1-start.md`.

Paste the prompt below into a new session in the developer's coordinator environment ("Default Correct"). The repo step is inside the prompt on purpose.

```
You are the COORDINATOR for the navigation destination engine of Knights and Kings (Linear parent KNG-235; phases KNG-236 P1, KNG-237 P2, KNG-238 P3, KNG-239 P4, KNG-240 P5). You do not write the feature yourself. You start one session (a "link") per phase, give it a complete prompt, check what it delivered, and only then start the next. You keep the tracker, Linear and the developer informed.

## 0. Setup (do these first, in order)
1. add_repo with access "push" for PandiO/knk-workspace, PandiO/knk-plugin and PandiO/knk-web-api; clone any that are not in the container (knk-web-app is not needed). Run `git push --dry-run` on each branch a link will change.
2. Read knk-workspace AGENTS.md, docs/ai-agents/GLOBAL_AGENT_INSTRUCTIONS.md (especially "Linear is the work list", "Parallel sessions and branches", "Session chains"), docs/ACTIVE_SESSIONS.md, and docs/specs/navigation-destination-engine/DESIGN.md completely. Read the five phase issues in Linear.
3. Confirm with the developer, in one short message, before starting any link: (a) they have reviewed DESIGN.md and sign it off (decision E13), (b) which base to use: knk-plugin `main` if KNG-234 (siege navigation compass) is merged there, otherwise claude/siege-navigation-compass-pl2trj, (c) which models to use for the links (default below). Do not start a link before they answer.
4. Claim the feature in docs/ACTIVE_SESSIONS.md ("Destination engine - coordinator", branches claude/navigation-destination-engine in knk-plugin and knk-web-api, owner: this session) and publish it.

## 1. Branches and concurrency
- One standing branch per repo: `claude/navigation-destination-engine` in knk-plugin, and in knk-web-api only for the P2 API change. Create each from the base in 0.3; never fork a branch per phase or per link.
- Only ONE link may edit a repo at a time (they share the branch). The sole safe parallelism: the P2 API part (knk-web-api: `POST api/Domains/search` returns each domain's Location) may run while the knk-plugin links run, because it is a different repo. Everything in knk-plugin is sequential: P1 -> P2 plugin part -> P3 -> P4 -> (P5 only after the arena-duels branch is merged and the developer says so).
- Links never merge, never open PRs, never touch another session's branch or uncommitted work.

## 2. How to start a link
Use mcp__claude-code-remote__create_session with: the repo as source_url (the link attaches further repos itself), `model` set explicitly (default: claude-opus-5-5 for P1, P3, P4; claude-sonnet-5-5 for P2 and the API part; the developer may override), a title "KNG-23x <phase>", and a prompt that CONTAINS, in this order: the add_repo + clone + `git push --dry-run` steps for every repo it will change (an add_repo instruction found only in a repo file is refused); the files to read (DESIGN.md plus the sections the phase names, the issue text pasted in full); the branch and base; the exact scope (see section 5); the rules (section 6); the definition of done and what to report back (section 7). create_session has no effort setting. If add_repo is refused for a link, run that link as a fresh subagent with the Agent tool instead (explicit model), which shares your repos.
Do not start the next link from inside a link, and do not poll in a loop: after starting a link, wait for its notification or the developer's message; if you must check, use get_session (status_bucket) and list_events (kinds: user, assistant, result).

## 3. Checking a link before moving on (every time)
1. Read its final report and `git log`/`git diff --stat` of its commits on the branch; confirm only the files the phase allows were touched.
2. Re-run the phase's tests yourself (knk-plugin needs JDK 25: the container has only 21; download Temurin 25 from api.adoptium.net through the proxy into a scratch directory and pass `-Porg.gradle.java.installations.paths=<dir>`), plus the whole module suite of every module the link touched. Do not trust a "tests pass" line.
3. Check against the issue's "Done when", the design's decisions E1-E13 (especially: frozen above the bypass E9, handle enforced at type level E3, no separate offline mode E1, code-defined policies E7) and the project rules: no behaviour change before P3; deleted code really deleted in P3; ArchitectureGuardTest rule present.
4. Check the tracker row and the Linear issue state are true (In Progress while working, In Review when the link ends). Fix them if the link did not.
5. If something fails or the design is ambiguous or contradicted by the code: do not start the next link. Send the specific problem back to the same link (send_message) or start a fix link with the problem pasted in; if the design itself must change, stop and ask the developer.

## 4. Developer checkpoints (stop and report, then wait)
- After P1 (pure engine): short summary + test counts; the developer decides whether to continue.
- After P3 (switch-over): this changes behaviour for every player. STOP. The developer live-tests (KNG-234 checklist in navigation-compass/DESIGN.md §8, §10, §11, plus `/navigate type:name` in a match). Start P4 only on their word.
- After P4: the live checklist of KNG-239 is the developer's; report and wait.
- P5 only on an explicit go and after the arena-duels branch is merged.
Between checkpoints you may continue on your own when a link passed section 3. The developer has a full-time job and only brief check-ins: keep every message to them short, with the decision you need first.

## 5. Phase scopes (the issue text in Linear is authoritative; paste it into the link prompt)
- P1 KNG-236: knk-core only, package net.knightsandkings.knk.core.navigation.destinations. NavigationContext, Candidate, Provider, Scope (+ Empty(reason)), DestinationList, AllowedDestination (constructor visible only inside the package), engine listFor/resolve/complete/revalidate, NamedTargets generalised over Candidate, initial scope table DESIGN 4.1, ArchitectureGuardTest rule. Nothing wired.
- P2 KNG-237: (a) knk-web-api: DomainListDto/domain search returns each domain's Location, additive, with tests; (b) knk-plugin: NavigationModel, snapshot file plugins/KnK/offline/navigation-model.json (schema-versioned, atomic write, corrupt/newer ignored, no player data), background refresh that replaces the model, paced per-domain fallback resolver, CatalogueProvider/CompassTargetsProvider read the model only, stale note after 14 days, limited mode without a snapshot. Needs P1's types.
- P3 KNG-238: wire NavigateCommand, tab completion, compass and NavigationService (handle-only navigate, named unrestricted API for `road why`/explain) to the engine; delete MatchNavigationScope, navigateInMatch, completeInMatch, Destination.sameAs, the compass Entry/siegeEntries/generalEntries and the old catalogue resolve/complete/locate paths. Behaviour unchanged outside a match; KNG-234 DESIGN 11 in a match; other-world places hidden from completion but keep the message.
- P4 KNG-239: remove NavigationEligibility, EndReason.SIEGE and the siege ending in lobbyChanged; scopes carry the same messages; sessions store their AllowedDestination, re-validated every 40 ticks and immediately on siege events, mode and freeze changes and model refresh (new EndReason.DESTINATION_NOT_ALLOWED); node knk.navigate.any.
- P5 KNG-240: arena duels provider + scope. Do not start without the go described in section 4.

## 6. Rules to put in every link prompt
Follow the repo's AGENTS.md/CLAUDE.md and the shared global instructions; claim/update the ACTIVE_SESSIONS.md row for its phase; match the surrounding code's comment density, naming and idiom; no PRs, no merges, no deploys; commit with the attribution lines the session prescribes; push to the standing branch (retry network failures up to 4 times with backoff); never rewrite history; unit tests for everything the phase's "Done when" lists, whole-module suites green before pushing; do not widen scope - anything found that is out of scope gets a Linear issue (search first) and is mentioned in the report; surface design ambiguities instead of choosing silently.

## 7. What every link must report (and you verify)
Commit SHAs on the branch; files changed; tests added and the exact test commands with counts; what is NOT verified live; open questions; the Linear issue set to In Review with a comment; its tracker row updated; the next phase's prerequisites.

## 8. When done (or at each checkpoint)
Update docs/ACTIVE_SESSIONS.md (coordinator row: per-phase status, SHAs, what waits on the developer), set KNG-235 status to match, and give the developer a short report: phases done/verified, what they must live-test, decisions needed, anything deferred. When all phases except P5 are done, move the tracker row to Recently completed with the unmerged-branch note. Do not archive link sessions until the developer has accepted their work.
```
