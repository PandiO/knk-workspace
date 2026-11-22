# Landmarks as a Domain subtype chain — charter

**Status:** Ready to start (2026-11-22)
**Last updated:** 2026-11-22 (draft from the design session; the coordinator completes it at its first run)
**Issues:** parent [PandiO/knk-workspace#976](https://github.com/PandiO/knk-workspace/issues/976); sub-issues per
link below. Reference issues as `PandiO/knk-workspace#n` in component repos.
**Progress report:** (the coordinator creates it at its first run)
**Skills:** coordinator `.claude/skills/knk-coordinator/`, links `.claude/skills/knk-link/` (knk-workspace).

## 0. Binding documents

1. [specs/landmark-domain/DESIGN.md](../../specs/landmark-domain/DESIGN.md), status Decided 2026-11-22 (decisions
   LD01–LD25; developer LD01–LD10, agent LD07 and LD11–LD25, approved by the developer). On `next` from
   knk-workspace `0f7c3639`.
2. [guides/landmark-domain-smoke-test.md](../../guides/landmark-domain-smoke-test.md): the draft section per link
   (§ 1–§ 4), which each link updates to what it built.
3. Read alongside, not superseded: [specs/domain-subregions/DESIGN.md](../../specs/domain-subregions/DESIGN.md)
   (sub-regions, mirror, access flags, orphans), [specs/navigation-offroad/DESIGN.md](../../specs/navigation-offroad/DESIGN.md)
   § 6 (landmarks; § 6.1 items 1–2 and § 6.3 superseded),
   [architecture/domain-access-enforcement.md](../../architecture/domain-access-enforcement.md) (effect damage, flags).
4. The sub-issue text **and its comments** (decisions added later live there).

## 1. Links

| Link | Sub-issue | Tier | What | Repos | Branch | Base | Flag | Gate |
|---|---|---|---|---|---|---|---|---|
| L1 | #983 | tier:3 | API model: `Landmark : Domain` (TPT), nullable `WgRegionId`, the migration (rows dropped), `AreaKind`, the parent and one parent walk, `api/landmarks` on the hierarchy, `domain_<id>` region names, guarded `api/Domains` writes, access tests, Landmark seeds v2 | knk-web-api | `claude/landmark-domain` | `next` | none (LD24) | now (#981 may land first) |
| L2 | #984 | tier:2 | API integration: domain lists and search with the type and filter, the disabled Landmark discovery rule with the override, warps with the type word, landmark realtime changes | knk-web-api | `claude/landmark-domain-integration` | `next` | none | L1 merged into `next` |
| L3 | #985 | tier:2 | Plugin: LANDMARK managed kind, effect damage without landmarks, opt-in messages, discovery and warp wording, area union, `/knk landmark` without radius, realtime, `landmark_<id>` path removed | knk-plugin | `claude/landmark-domain` | `next` | none | L1 and L2 merged into `next` |
| L4 | #986 | tier:2 | Web app: DTOs on the domain base, `DOMAIN_ENTITY_TYPES`, type column and filter, pickers, parent picker, `DomainLandmarksPanel`, landmark list columns, e2e | knk-web-app | `claude/landmark-domain` | `next` | none | L1 and L2 merged into `next` |

## 2. Gates

1. "L<n> merged into `next`": `git rev-list --count origin/next..origin/<branch>` is 0 in every repo L<n> changed.
2. "L<n> done": L<n>'s block is in the progress report, its heads match `git ls-remote`, its checks passed.
3. No developer gate between links. L1 is tier:3: the developer's full manual check of guide § 1 comes before the
   promotion of `next`, not before the merge into `next`.

Order and parallelism: L1, then L2 (same repo); L3 and L4 may run together after L2, they share no component repo.

## 3. Chain notes

1. **Overlaps on the board.** The off-road navigation chain (#698) owns the landmark code of #708/#709 (merged into
   `next`, no link running, its smoke § 6 waits). L3 changes `core/navigation/` landmark classes
   (`LandmarkExtent`, `LandmarkProvider`, `ModelLandmarks`): check the off-road chain's row first and keep one knk-plugin
   navigation link at a time. L1 removes the landmark path that #945 added; #946 (production areas) keeps the generic
   owner lookup. #981 (CrownLand loop) touches `DomainMappingProfile` and is replaced by L1's parent walk; if it is open
   when L1 starts, L1 may take it over.
2. **Unchanged for existing modes.** Towns, districts, structures, gate structures, crown land and the production
   structures keep their behaviour: region still required, effect damage, messages and discovery as today. Every
   landmark behaviour is off or neutral by default (LD24).
3. **Migrations.** L1 only, and not additive: it drops the landmark rows (developer decision LD10, dev DB only;
   #708 is not promoted) and needs a working Down for the migrations workflow. L2 at most seed data.
4. **Dev DB.** After L1 the developer's edited Landmark form (form 51, with the Region id projection of 2026-11-22) is
   superseded by the seed v2 form (LD25); the developer recreates the test landmarks.
5. **Model for link sessions:** (the coordinator chooses and passes it explicitly).
