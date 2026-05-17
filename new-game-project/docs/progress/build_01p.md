# Build 01p — v0.1.0

Date: 2026-05-16

## Summary

Locked the Spellbook detail card inside the Spellbook window so resize behavior
can no longer let it drift or spill outside the frame.

## Files changed

- `scripts/ui/menus/SpellTreeUI.gd` — clamps the detail card position and size to the Spellbook bounds
- `scenes/ui/menus/SpellTreeUI.tscn` — clips detail-card contents inside the card
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01o` to `01p`

## Problem

The hover/detail card could still become visually oversized relative to the
Spellbook and extend outside the window even after making the authored card shorter.

## Solution

Added a real bounds check: whenever the Spellbook lays itself out, the detail
card now gets clamped inside the Spellbook frame and shrinks first if the window
is ever too small to contain it. The panel also clips its contents instead of
letting children draw beyond the card.

## Tuning knobs

- `scripts/ui/menus/SpellTreeUI.gd`
  - `DETAIL_PANEL_MARGIN`

## Known follow-ups

- If Danny wants the card even more compact after this, tune the authored card
  dimensions knowing it will now stay safely inside the window.
