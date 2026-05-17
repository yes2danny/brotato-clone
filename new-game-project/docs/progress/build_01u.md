# Build 01u — v0.1.0

Date: 2026-05-16

## Summary

Moved the rotating shop quips into a framed strip using one of the newly supplied
tinyRPG UI boxes.

## Files changed

- `assets/_source/ui/tiny_rpg_mana_soul_gui/20250420manaTabD-Sheet.png` — added source copy
- `assets/ui/tiny_rpg_mana_soul_gui/atlas.png` — added runtime copy
- `docs/ASSET_LIBRARY.md` — recorded the newly owned UI strip
- `scripts/ui/shop/ShopUI.gd` — wrapped the quip line in a framed shop quip panel
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01t` to `01u`

## Problem

The rotating shop quips were visually loose at the bottom of the shop despite
having a perfect small UI-frame asset available.

## Solution

Imported the new frame strip and used the blue fourth panel as a stretched
nine-slice background for a compact quip box under the shop buttons.

## Tuning knobs

- `scripts/ui/shop/ShopUI.gd`
  - selected atlas region for the quip frame
  - quip panel size

## Known follow-ups

- If Danny prefers another color from the same strip, swap the atlas region
  without changing the layout.
