---
status: active
last_updated: 2026-09-20
---

# Concept-doc variant comparison

The SMB share's `archive/iCloud drive export/Documents/` folder contained six overlapping "concept document" files. This is a record of the line-by-line comparison used to decide which to keep, so the decision to drop five of them is auditable rather than asserted.

## Files compared

| File | Verdict |
|---|---|
| `Concept_KnightsAndKings_v0.2.docx` | **Kept** → [concept-v0.2-2020.md](concept-v0.2-2020.md) |
| `Concept_KnightsAndKings_v0.1.docx` | Dropped |
| `Concept_KnightsandKings_Koen.docx` | Dropped |
| `Concept_KnightsandKings_Short.pdf` | Dropped |
| `Concept_KnightsandKings(short).docx` | Dropped |
| `Concept_verhaallijn_KNK.docx` | **Kept separately** (not a variant of this cluster) → [concept-storyline.md](concept-storyline.md) |

## Method

Full text was extracted from each file and compared paragraph-by-paragraph against `v0.2`, the largest and most recent of the cluster.

## Findings

- **`(short).docx`** contains only the shared opening section (Working Title → Concept Paragraph and Unique Selling Points). Every sentence in it appears verbatim in `v0.2`. No unique content.
- **`Koen.docx`** contains the same opening plus a "Kingdoms, art and inspiration" section with lore/famous-names lists for 4 kingdoms (Men, Dragonborn, Elves, Dwarves — no Hobbit). Every one of those famous-names lists, colour codes, and inspiration links appears verbatim in `v0.2`'s Kingdoms section, which additionally includes a 5th kingdom (Hobbit) that `Koen.docx` lacks. No unique content lost by dropping it.
- **`Short.pdf`** is a PDF export of `Koen.docx` — identical text, same ending ("Skills" / "Clans" / "Magical wands" feature list). A format duplicate, not a separate revision.
- **`v0.1.docx`** is a full "game design document" — same product-design narrative, key-moments text, art/inspiration text, and Kingdoms section (word-for-word) as `v0.2`. `v0.2` is `v0.1` plus additional sections not present in `v0.1`: Monetization, User Interface (stub), MVP Systems and Features (including the full Titles table and Currency section), Combat, Skills, and the Professions/Ideas and Expansions section. No content in `v0.1` is absent from `v0.2`.
- **`verhaallijn.docx`** ("storyline") is not a variant of this document family at all — it's a short creation-myth/lore fragment (the Karath Urr / Morkoth origin story) that doesn't appear in any other source document. Kept on its own.

## Conclusion

Keeping only `v0.2.docx` (as `concept-v0.2-2020.md`) loses no feature, lore detail, or design decision found in `(short)`, `Koen`, `Short.pdf`, or `v0.1` — each is a strict subset of `v0.2`'s content. `verhaallijn.docx` was kept separately since it isn't part of this overlap at all.
