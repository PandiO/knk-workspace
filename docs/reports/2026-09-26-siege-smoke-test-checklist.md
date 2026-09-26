# Siege minigame — smoke-test checklist

**Status:** Open — to be ticked off live by the developer
**Last updated:** 2026-09-26 (after the second smoke-test round of fixes; branch heads: web-api `6757812`,
plugin `dfbdf79`, web-app `3e5770e`)

Everything below is code-complete on the `claude/siege-minigame` branches but **not verified in game**. The knk-paper
module from Phase 6b on was written in a cloud container that can't compile it, so step 0 comes first. Detailed
per-phase steps: `docs/specs/siege-minigame/IMPLEMENTATION_PLAN.md` (each phase's "Manual live verification").

Already verified by the developer (2026-09-26 first pass): `/menu` → Siege tile → join via the menu with an op and a
non-op account, admin skip of matchmaking, match start, menu background panes for op and non-op.

Accounts: **A** (op/owner), **B** (default player), **C** (third account, non-member) where a step needs one.

## 0. Build and start

- [ ] Pull `claude/siege-minigame` in knk-plugin, knk-web-api, knk-web-app.
- [ ] knk-plugin: `./gradlew build -x deployToDevServer` compiles. Fix anything it reports first (knk-paper is uncompiled
      from 6b on; includes two trunk merges). knk-paper unit tests pass (Phase 5 baseline 259 + trunk's new tests).
- [ ] knk-web-api: `dotnet ef database update` applies trunk's new migrations (`AddGradeDropChanceAndEnchantCap`,
      `AddPermissionGroupDisplayColors`, `PremiumRanksInheritDefault`, plus KNG-16's if any). No siege migration is new.
- [ ] Start the API: log shows the seeds, including "SiegeLobby seed: created the disabled example lobby 'example'"
      (first start only) and the siege menu seeds.
- [ ] `./gradlew :knk-paper:dev`, start DEV_SERVER_1.21.10: no errors at enable; log has "Siege runtime initialized"
      and no "Siege gate integration disabled".
- [ ] knk-web-app: `npm start`; nav shows **Siege Settings** next to Game Settings; Moderation only for staff.

## 1. Settings, seeds, docs (Phase 9)

- [ ] Siege Settings page loads; the dev DB keeps its own capture values (A1 10 / A2 2 / IV A2 10 / D 6/3/6).
- [ ] The lobby list shows the disabled `example` lobby; `/siege admin list` in game does **not** list it.
- [ ] Optional: skim `docs/guides/authoring-a-siege-scenario.md` against the web app.

## 2. Menus and commands (8b + today)

- [ ] `/siege` as a non-member opens the overview; as a member opens your siege's Information.
- [ ] `/siege menu`, `/siegemenu`, `/sgm` as a member (matchmaking, hub, in progress) open Information; as a
      non-member → "You aren't in a siege". `/sm` still toggles staff mode.
- [ ] During a match `/sgm` is allowed by the command filter; a blocked command's message lists "/siege, /sgm".
- [ ] Overview: lobbies, member counts; Information: vote candidates + Random with counts, click to vote/unvote,
      join/leave button (leave needs a double click), member list with heads/titles/teams.
- [ ] Menu background panes are **gray** (not light gray) on every menu.

## 3. Match start: gates, area, banners

- [ ] At the hub (T-15): log "N gate structure(s) locked down for match X"; DB `siege_match_gate_snapshots` rows and
      `gate_structures.CurrentSiegeId` set; selected gates go to their initial state, other district gates open.
- [ ] C inside a scenario district at T-15 is moved out; C walking or `/tp`-ing in is refused during the round.
- [ ] Match start: every objective shows a banner **standing on the floor**, in the **holding team's full banner**
      (patterns included). If one is missing, the log says "banner spot x,y,z isn't air" — clear it or re-capture.
- [ ] Capture rings (flame particles) are at floor level, including The Keep; capturing works when standing on the
      floor inside the ring.
- [ ] The spawn picker opens once at match start (only if your team has 2+ options).

## 4. Capture feedback (today)

- [ ] B steps into an enemy-held objective ring:
  - [ ] B's alliance: goat horn ("Ponder"), crit particles, chat "B began capturing <objective>!".
  - [ ] Holder's alliance: bell, angry-villager particles, chat "<objective> is being captured by [team]! (n%)".
  - [ ] B hears a pling every second, pitch rising with progress; members nearby see enchanted-hit sparks around B.
  - [ ] Stepping out and back in within 15 s does **not** re-announce; after 15 s it does.
- [ ] A defender steps in and pushes the progress back:
  - [ ] Holders: goat horn ("Sing"), happy-villager particles, chat "<name> began defending <objective> (n% captured)."
  - [ ] Attackers: low bass note, smoke, chat "The enemy is pushing you back at <objective>!".
  - [ ] The defender hears a chime every second, pitch rising as the progress recovers.
- [ ] A lone defender on an untouched objective triggers nothing.
- [ ] Banner animation: while capturing, the banner steps through the gradient from holder colour towards the
      attacker's colour; at capture it switches to the capturer's full banner; totem burst at the capture point;
      existing level-up / wither sounds and chat lines.
- [ ] With recapture on: the old holders' counter-attack is announced as "began **retaking**".
- [ ] The main (instant-victory) objective keeps the winner's banner after it's taken.

## 5. Gates during the match (7a) and non-member view (7b)

- [ ] Owner alliance right-clicks a closed selected gate → opens; again → closes. Enemy → "held by the enemy";
      C → "part of the siege"; area gate → "held open".
- [ ] Attackers can damage a damageable selected gate until destroyed; defenders can't damage their own; area gates
      take no damage.
- [ ] Capturing a gate objective opens the gate (its "state on capture") and hands control to the capturers.
- [ ] C outside the area sees the gates as before the lockdown; relog/teleport keeps that view; C can't walk through
      gates that look closed; brief flicker while a gate animates is expected.
- [ ] Optional: Siege Settings → Non-member gate view = PassThroughOnly, `/siege admin reload` between matches → C
      sees the real gates, no fake collision.

## 6. Deaths and respawns (today)

- [ ] Die several times: **no** spawn picker after each death; you respawn at your remembered choice.
- [ ] Choose a held objective as spawn (menu "Change spawnpoint" or `/siege spawn`); let the enemy capture it →
      message "Your team lost <objective>: you respawn at your team's spawnpoint again. Change it in /siege menu";
      next respawn is at the team spawnpoint.
- [ ] Change the spawn through `/sgm` → "Change spawnpoint" mid-life: the next respawn uses it.
- [ ] Custom-enchant weapons work on enemies during the siege **inside a town** (KNG-11 exemption) and still don't
      work on players in town outside sieges.

## 7. Match end and rewards (6 / 6b / today)

- [ ] Give A a premium rank with a SalaryMultiplier (e.g. 1.5) and a PersonalSalaryMultiplier (e.g. 2) first.
- [ ] Play to the end. Chat shows the stats line, then per currency in the shared reward format:
      "Siege reward: 250 ×2 Personal ×1.5 <Rank> = +750 coins", "Siege reward: +25 XP", "+1 gems", then a gray
      "win · 2 objectives gained · 1 capture" line. B (no multipliers) sees "Siege reward: +250 coins".
- [ ] A title promotion from siege XP shows the usual promotion message with its (multiplied) title bonus lines.
- [ ] `GET /api/siege-matches` → the match `Completed`; participants' `coinsAwarded` equal chat and the balance
      change; `baseCoins`/`coinMultiplier`/`coinMultipliers` on the complete response.
- [ ] Gates return to their pre-lockdown state; snapshots deleted; `CurrentSiegeId` null; C can enter the area again.
- [ ] Inventories, locations and scoreboards are restored.
- [ ] An hourly salary message during a match is fine (accepted).

## 8. Failure paths (6b / 7a)

- [ ] Stop the API before a match ends → "Your rewards couldn't be confirmed yet"; file
      `plugins/KnightsAndKings/siege-vault/pending-results/<id>.json`. Start the API, then the next draw or a restart →
      file gone, log "Delivered spooled result", balances granted once.
- [ ] Kill the server mid-match, restart → log "Startup recovery aborted 1 match(es)" and "Gate recovery restored N
      gate structure(s)"; players get their inventories back; gates correct.
- [ ] `/siege admin stop <lobby>` mid-match → row `Aborted` (AdminStopped), no balance change, lobby stays stopped;
      `/siege admin start <lobby>` resumes matchmaking.

## Known watch items

- Trunk's rank re-sync (`ScoreboardUtil.setScoreboard`) would replace a siege member's scoreboard if staff change
  their rank mid-match.
- A `complete` call for a match that was already recorded returns the stored result without the multiplier
  breakdown: the reward line then shows the total only. A spooled result replayed later is the first real call, so
  it still has the breakdown.
