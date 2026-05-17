# Build 01m — v0.1.0

Date: 2026-05-16

## Summary

Recorded Danny's preferred hand-authored Spellbook layout and made the tree keep
its shape when the Spellbook window changes size.

## Files changed

- `docs/SPELLBOOK_LAYOUT_REFERENCE.md` — wrote down the intended current layout
- `scripts/ui/menus/SpellTreeUI.gd` — preserves layout proportions on resize
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01l` to `01m`

## Problem

The Spellbook finally had a hand-tuned layout Danny liked, but there was no saved
reference for that exact composition and a larger window could leave the tree
looking pinned to old positions.

## Solution

Saved the current node/label placement in a reference note and made the runtime
UI remember the first real on-screen arrangement as its master pose. If the
window size changes, the nodes, labels, and hover panel now move proportionally
while the pixel-art assets stay crisp.

## Tuning knobs

- `docs/SPELLBOOK_LAYOUT_REFERENCE.md`
  - the current intended layout map
- `scripts/ui/menus/SpellTreeUI.gd`
  - the resize behavior and which controls follow it

## Known follow-ups

- If Danny redraws the tree later, refresh the reference note so it matches the
  new preferred composition.
