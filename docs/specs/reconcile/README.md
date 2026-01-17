# spec/reconcile/

Reconciliation documents bridging legacy and v2 designs.

## Purpose
Explicitly map legacy patterns/concepts to v2 architecture decisions, validating that nothing is lost or invented.

## Contents
- `RECONCILE_*.md`: Per-subsystem mappings (e.g., RECONCILE_TOWNS.md)
  - Legacy field → v2 model field (or TBD if no source)
  - Legacy flow → v2 async port/command
  - Anti-patterns → clean architecture replacements
- Decision journals: Why certain legacy patterns are retained vs. refactored

## Principles
- **Source-grounded:** Every v2 field traceable to legacy source or explicit TBD.
- **Bidirectional:** Can reverse-lookup legacy from v2 and vice versa.
- **Transparent:** Show trade-offs (e.g., losing ORM cache for async clarity).

## Audience
Architects, code reviewers, stakeholders validating no-regression guarantee.
