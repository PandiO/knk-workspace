# Siege alpha balance test plan — template

**Status:** Current (developer agreed 2026-11-16)
**Last updated:** 2026-11-16 (first version, from the developer's voice session on test run 1's balance lessons)
**Issues:** [PandiO/knk-workspace#651](https://github.com/PandiO/knk-workspace/issues/651) (balancing statistics),
[#652](https://github.com/PandiO/knk-workspace/issues/652) (test-run recording),
[#653](https://github.com/PandiO/knk-workspace/issues/653) (usability testing)

Copy this into a run's folder as `docs/reports/alpha-tests/test-run-<n>/test-run-<n>-balance-plan.md`, next to the
preparation plan and checklist ([closed alpha test runs](closed-alpha-test-runs.md) § 2, § 3). It adds balance and
usability rounds to the run; it doesn't replace the preparation plan.

Use this template to plan each balance-focused alpha test run of the Siege minigame. Each round tests a single change against target numbers that are set in advance.

## Lessons from test run 1

- Every player had end-game gear: full netherite with maximum vanilla enchantments, some custom enchantments, and two stacks of golden apples.
- Result: with 7–8 players, there were only about 2–3 deaths per match, and matches ran about 12 minutes.
- Takeaway: the setup tested an unrealistic loadout, and healing was far too plentiful, so kills almost never happened.

## 1. Run details

| Field | Value |
| --- | --- |
| Test run number |  |
| Date |  |
| Players expected |  |
| Scenario(s) |  |
| Build / branch |  |
| Goal of this run (one sentence) |  |

## 2. Target numbers (set before the run)

| Metric | Target | Notes |
| --- | --- | --- |
| Time to kill, two equal players | 5–10 s | Duel between equally equipped players |
| Deaths per player per match | 2–4 |  |
| Match length | 10–15 min |  |
| Objective captures per match |  |  |
| Siege weapon kills share |  | Share of all kills, once weapons exist |
| Gate destroyed by minute |  |  |

Adjust the targets to the feel you want, but write them down before you play.

## 3. Gear tiers

Define a few kits that represent points on the progression curve. Most rounds should use the mid tier.

| Tier | Armour | Weapon | Enchantments | Healing | Represents |
| --- | --- | --- | --- | --- | --- |
| Starter | e.g. leather / chain | Stone / iron sword | None | 0–2 golden apples | New player |
| Mid-game | e.g. iron, a diamond piece | Iron / diamond sword | Low vanilla levels | 2–4 golden apples | Typical player |
| Late-game | e.g. diamond / netherite | Netherite sword | High vanilla levels, no custom | 4–6 golden apples | Veteran |

## 4. Round plan

Change one thing per round, so you know what made the difference.

| Round | Kit tier | Healing | Variable changed | Everything else |
| --- | --- | --- | --- | --- |
| 1 | Mid | 2 golden apples | Baseline | Default settings |
| 2 | Mid | 0 golden apples | Healing | Same as round 1 |
| 3 | Late | 2 golden apples | Gear tier | Same as round 1 |
| 4 |  |  |  |  |

## 5. Data to collect

- **Per player:** kills, deaths, assists, damage dealt and taken, healing items used, siege points earned and spent.
- **Per match:** length, captures, gate damage over time, winner.
- **Siege weapons (once built):** shots fired, hits, damage and kills per weapon type and ammo type.
- Pull these from match history, the telemetry test run and the balancing statistics (#651), with logging added where it is missing.

## 6. After each round

Ask each player three quick questions (on top of the four standard 1–5 scores every run asks, [test runs guide](closed-alpha-test-runs.md) § 3):

1. Fun? (1–5)
2. Too easy, about right, or too hard to kill and die?
3. One thing that felt off?

## 7. Results and decisions

| Round | Metric vs target | Player feel | Decision / next change |
| --- | --- | --- | --- |
| 1 |  |  |  |
| 2 |  |  |  |
| 3 |  |  |  |

## 8. Usability tests (menus and web app)

Alongside the balance rounds, check that players can find and do things without too much effort.

**Scripted tasks.** Give each tester a few tasks per run and note whether they succeed:

| Task | Shortest path (clicks) | Success? | Time | Clicks used | Ease (1–7) | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| e.g. Join a siege match |  |  |  |  |  |  |
| e.g. Buy a ballista and place it |  |  |  |  |  |  |
| e.g. Find your match result |  |  |  |  |  |  |

**Watch a few testers.** Use a Discord screen share and ask them to think out loud. About five testers find most of the big problems. Don't help unless they're completely stuck, and note where they hesitate.

**Behaviour logging.** Record menu opens, clicks, back actions and closes with timestamps (a `ui` topic in the test-run recording). For the web app, use page and click events, or a self-hosted analytics tool. Look for:

- tasks started but not finished
- going back or reopening the same menu repeatedly
- clicks on items that do nothing
- much longer times or more clicks than the shortest path

**Tell testers up front** that their clicks are recorded for the test.

**Before building:** check what already exists. The player statistics telemetry already records `menu.opened` and `menu.action` for everyone, and `menu.click`, `combat.hit` and `gate.hit` for players in a telemetry test run ([player statistics design](../specs/player-statistics/DESIGN.md) § F.12). Reuse it before adding new logging (#652, #653).

## 9. Tips

- Test the middle of the progression curve more than its end.
- Healing is the biggest lever on time to kill. Tune it before tuning damage.
- Keep custom enchantments out of the baseline, and test them in their own round.
- Compare against the targets, not only against how it felt.
- Record the findings in the next run's preparation plan.
