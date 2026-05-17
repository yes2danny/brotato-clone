# Build 01r — v0.1.0

Date: 2026-05-16

## Summary

Tightened the Shop tab so the resupply screen stops wasting vertical space while
leaving the large Spellbook layout intact.

## Files changed

- `scripts/ui/shop/ShopUI.gd` — reduced Shop-only modal height and removed unnecessary vertical stretching inside item cards
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01q` to `01r`

## Problem

The Shop window had too much empty vertical space, and the offer cards were being
stretched far taller than their actual content needed.

## Solution

Made the Shop tab itself shorter than the Spellbook tab, lowered the minimum card
height, and removed the vertical expand flags that were forcing card contents to
spread apart. The cards should now read as dense offers instead of tall columns.

## Tuning knobs

- `scripts/ui/shop/ShopUI.gd`
  - Shop-tab `desired_h`
  - Shop-tab `min_h`
  - card minimum height

## Known follow-ups

- After Danny sees the new density in-game, tune whether the shop wants a touch
  more width, a touch less height, or both.
