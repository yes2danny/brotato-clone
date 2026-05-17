# Build 01e — v0.1.0

Date: 2026-05-16

## Summary

Reviewed the owned spell VFX library and documented which effects fit best as
spell families, evolutions, or separate standalone spells.

## Files changed

- `docs/SPELL_VFX_REVIEW_2026-05-16.md` — added the first spell art-direction review
- `docs/ASSET_LIBRARY.md` — linked the review note and recorded the first duplicate check result
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01d` to `01e`

## Problem

The project owned many promising effects, but there was not yet a written guide
for which ones fit the game well or how they should relate to one another.

## Solution

Reviewed the visual library and grouped the strongest assets into likely spell
families: fire, electric, poison, water, and dark/curse. The review also marks
which effects should evolve from one another and which should remain separate
spells so their identity stays intact.

## Tuning knobs

- None. This build is documentation only.

## Known follow-ups

- Pick the first non-fire spell family to implement after Fireball feels right.
- Revisit the weaker/smaller effects in live gameplay before discarding them.
