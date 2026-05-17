# Build 01f — v0.1.0

Date: 2026-05-16

## Summary

Imported the free Magic Pack 9 set and folded its strongest effects into the
spell VFX review.

## Files changed

- `assets/_source/magic_and_explosions/magic_pack_09` — archived the free source pack
- `assets/vfx/magic/magic_pack_09` — added the working VFX copy
- `docs/ASSET_LIBRARY.md` — recorded ownership of `magic_pack_09`
- `docs/SPELL_VFX_REVIEW_2026-05-16.md` — added notes for Dark Bolt, Fire Bomb, Lightning, and Spark
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01e` to `01f`

## Problem

A new free pack had not yet been reviewed against the existing spell library.

## Solution

Imported the pack and evaluated its four effects. `Lightning` strengthens the
electric family, `Dark-Bolt` gives the dark school a cleaner projectile starter,
and `Fire-bomb` is distinctive enough to stay its own spell rather than being
forced into the Fireball line.

## Tuning knobs

- None. This build is asset intake and documentation only.

## Known follow-ups

- Decide later whether `spark` from Pack 9 or the existing spark effect becomes
  the preferred visual for the electric starter.
