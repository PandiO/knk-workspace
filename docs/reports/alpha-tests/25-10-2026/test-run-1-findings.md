# Closed alpha test run 1 — findings (2026-10-25)

**Status:** Triaged; all items filed as GitHub issues. Priorities are preliminary.
**Last updated:** 2026-10-25
**Issues:** parent [PandiO/knk-workspace#149](https://github.com/PandiO/knk-workspace/issues/149), one sub-issue per
item (#150–#176)
**Handoff (P0 + P1):** [2026-10-25-alpha-run-1-p0-p1.md](../../../ai-agents/handoffs/2026-10-25-alpha-run-1-p0-p1.md)

The developer's notes from the first closed-alpha test run (written in Dutch, "Todo lijst alpha test run 1"), plus
their follow-up comments the same day. Claude Code (cloud session) grouped them by feature, classified and
prioritised them, and filed the issues. Nothing was reproduced or traced in code; the component repos weren't
in the triage session.

**Priority:** P0 = breaks a match or can be exploited, fix before run 2 (`priority:urgent`) · P1 = fix before run 2
(`priority:high`) · P2 = later in the alpha (`priority:medium`) · P3 = backlog (`priority:low`)

## Summary

- **P0 (2):** a siege member who gets kicked can't rejoin
  ([#150](https://github.com/PandiO/knk-workspace/issues/150)). Freeze spam can't be countered; the developer's fix is
  admin-configurable enchantment values ([#151](https://github.com/PandiO/knk-workspace/issues/151)).
- **P1 (12):** #152–#162 and #176.
- **P2 (11):** #163–#173.
- **P3 (2):** #174, #175.
- **By type:** 10 bugs (2 to verify), 8 improvements, 9 new features — 27 issues.

## 1. Siege matches

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 1.1 | A siege member who gets kicked can't rejoin the match | Bug | **P0** | [#150](https://github.com/PandiO/knk-workspace/issues/150) |
| 1.2 | `/siege join <username>` for admins (also the fallback for 1.1) | Feature | P1 | [#152](https://github.com/PandiO/knk-workspace/issues/152) |
| 1.3 | A player who joins during a match gets no scoreboard format (colours etc.) | Bug | P2 | [#163](https://github.com/PandiO/knk-workspace/issues/163) |
| 1.4 | Clearer result message with more stats, also values that are 0 | Improvement | P2 | [#164](https://github.com/PandiO/knk-workspace/issues/164) |
| 1.5 | Siege results log: detailed in the web app, short in game with a link | Feature | P3 | [#174](https://github.com/PandiO/knk-workspace/issues/174) |

## 2. Siege rewards / match economy

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 2.1 | The losing team seems to get no rewards — verify | Bug (verify) | P1 | [#153](https://github.com/PandiO/knk-workspace/issues/153) |
| 2.2 | Extra rewards for gate damage and objective capture points | Improvement | P2 | [#165](https://github.com/PandiO/knk-workspace/issues/165) |
| 2.3 | Exploit-proof base reward for playing a full match | Improvement | P2 | [#166](https://github.com/PandiO/knk-workspace/issues/166) |

## 3. Gates: pass-through

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 3.1 | Siege defenders use animated pass-through (open, then close shortly after) instead of toggling the gate; check the current behaviour first | Improvement (verify) | P1 | [#154](https://github.com/PandiO/knk-workspace/issues/154) |
| 3.2 | Four pass-through styles: (a) animated, (b) snap open/close, (c) walk-path block removal, (d) teleport through | Feature | P2 | [#167](https://github.com/PandiO/knk-workspace/issues/167) |
| 3.3 | Snap and walk-path only visible to the player using it — spike first | Improvement | P2 | [#168](https://github.com/PandiO/knk-workspace/issues/168) |

The gate specs (`docs/specs/gate-structure-animation/`) don't list pass-through styles, so which styles exist today
must be checked in knk-plugin. For 3.3: blocks changed only on the player's client stay solid on the server, so its
movement check will probably snap the player back.

## 4. Custom enchantments and effects

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 4.1 + 4.5 | Freeze spam can't be countered. Developer decision 2026-10-25: fix it with admin-configurable values per enchantment (proc chance, cooldown on/off and length, duration, per-level multiplier) | Feature | **P0** | [#151](https://github.com/PandiO/knk-workspace/issues/151) |
| 4.2 | Frozen players are kicked for flying. Workaround since 15:02Z: `ALLOW_FLIGHT: "TRUE"` for the whole server ([report § 4](../../2026-10-25-alpha-update-api-6f08383d-plugin-ee35fb1d.md)), which also lets fly hacks through | Bug | P1 | [#155](https://github.com/PandiO/knk-workspace/issues/155) |
| 4.3 | Weaker defaults; freeze maybe an ability with a cooldown | Improvement | P1 | [#156](https://github.com/PandiO/knk-workspace/issues/156) |
| 4.4 | Player names visible during the flash/chaos effect | Bug | P2 | [#169](https://github.com/PandiO/knk-workspace/issues/169) |
| 4.6 | Boss bar with the remaining time of an effect like freeze | Feature | P2 | [#170](https://github.com/PandiO/knk-workspace/issues/170) |

## 5. Permissions, ranks and staff tools

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 5.1 | Only ops could open chests in towns. Denying it in domains is intended; add bypass nodes for moderators and admins (not the general staff rank); staff mode and owner mode always bypass | Improvement | P1 | [#157](https://github.com/PandiO/knk-workspace/issues/157) |
| 5.2 | Audit every KnK command for a permission node and add the missing ones (gamemode is op-only; KnK items) | Improvement | P1 | [#158](https://github.com/PandiO/knk-workspace/issues/158) |
| 5.3 | Notify permitted players when a join is refused (ban, whitelist, access mode), with the reason | Feature | P1 | [#159](https://github.com/PandiO/knk-workspace/issues/159) |

## 6. Teleport, spawn and hub

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 6.1 | `all` argument for `/hub`, `/spawn`, `/tp`, `/tphere`: online players of the same rank or lower; bypass node; staff and owner mode exempt | Feature | P2 | [#171](https://github.com/PandiO/knk-workspace/issues/171) |

Open question: what `/tp all <player>` means next to `/tphere all`.

## 7. Menus and console accessibility

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 7.1 | Configurable inventory item that opens `/menu` on click, for console players | Feature | P1 | [#160](https://github.com/PandiO/knk-workspace/issues/160) |

## 8. Crossplay (Bedrock/console)

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 8.1 | Console players' block breaks only show on their own client; suspected Geyser, Floodgate or MCXboxBroadcast | Bug | P1 | [#161](https://github.com/PandiO/knk-workspace/issues/161) |

## 9. Kits

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 9.1 | The kit hover tooltip runs off the screen: the "Other contents" line has no line breaks ([screenshot](kits-tooltip.webp)) | Bug | P2 | [#172](https://github.com/PandiO/knk-workspace/issues/172) |

## 10. Items

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 10.1 | `/knk item more`: fill the held stack to 64, or give a new stack when full | Feature | P3 | [#175](https://github.com/PandiO/knk-workspace/issues/175) |

## 11. Domain rules

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 11.1 | No effect damage (e.g. fire) inside domains unless a flag allows it | Improvement | P1 | [#162](https://github.com/PandiO/knk-workspace/issues/162) |

## 12. Combat / world cleanup

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 12.1 | Arrows on the ground disappear right away | Improvement | P2 | [#173](https://github.com/PandiO/knk-workspace/issues/173) |

## 13. Street navigation

| # | Finding | Type | Prio | Issue |
|---|---|---|---|---|
| 13.1 | Navigation to the northern gate sends attackers on the island to the crane (tester Ivo) | Bug | P1 | [#176](https://github.com/PandiO/knk-workspace/issues/176) |

## Original notes (developer, 2026-10-25)

```
Todo lijst alpha test run 1 (25-10-26)
- [ ] Permission nodes voor verbeteren en toevoegen aan juiste ranks:
    - [ ] Knk items
    - [ ] Gamemode
    - [ ] Worldinteractions (alleen ops kunnen nu kisten in towns openen
    - [ ] The kits description hover is gebugged over het hele scherm
    - [ ] Console spelers kunnen blocks slopen maar dit is alleen voor de client zichtbaar
    - [ ] Pijlen die op de grond liggen moeten gelijk verdwijnen
    - [ ] iemand kan gekickt worden door stuck zijn in freeze bijv.
    - [ ] Siegemember die gekickt wordt joined niet meer in de match. Dit moet gefixt
    - [ ] Passthrough laat gate niet automatisch dicht gaan in een match als verdediger
    - [ ] Iemand die joined tijdens siege match krijgt geen scoreboard format (kleur etc)
    - [ ] Freeze spammen is niet te counteren
    - [ ] Nav northern gate werkt niet voor attackers als ze op het eiland lopen. Ivo werd naar hijskraan gestuurd
    - [ ] Namen zie je in flash chaos effect
    - [ ] Admins moeten spelers in een siege kunnen voegen met een /siege join <username>
    - [ ] Custom enchantments moeten gedebuffed worden. [...] Kortom, meer customization voor admins.
    - [ ] Custom effects zoals freeze moeten een bossbar laten zien met hoelang je nog dat effect hebt
    - [ ] Siege results moeten in een logboek komen [...]
    - [ ] De siege result message aan het einde van een match moet duidelijker. [...]
    - [ ] Spelers moeten meer rewards krijgen in sieges. [...]
    - [ ] Effects damage zoals fire damage moet disabled zijn in domains, tenzij expliciet aangegeven.
```

The full wording of each note is in its issue. Follow-up comments from the developer the same day (all in the issues
above): chest denial in domains is intended (5.1); audit all commands, not only items (5.2); the console block bug may come from
Geyser/Floodgate/MCXboxBroadcast (8.1); new menu item (7.1); kit tooltip screenshot (9.1); the kick was the
`allow-flight` check (4.2); the four pass-through styles and client-only rendering (3.x); the `all` teleport argument
(6.1); join-refusal notifications (5.3); `/knk item more` (10.1); the fix for 4.1 is 4.5.

