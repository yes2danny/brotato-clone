# Build 01v — v0.1.0

Date: 2026-05-16

## Summary

Swapped the shop quip box to the wider tinyRPG button strip so it reads less
stretched at shop width.

## Files changed

- `assets/_source/ui/tiny_rpg_mana_soul_gui/20250421manaSoulButtonB-Sheet.png` — added source copy
- `assets/ui/tiny_rpg_mana_soul_gui/button_b_atlas.png` — added runtime copy
- `docs/ASSET_LIBRARY.md` — updated the tinyRPG strip note
- `scripts/ui/shop/ShopUI.gd` — switched the quip panel to the wider frame atlas
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01u` to `01v`

## Problem

The first framed strip worked, but it visibly looked stretched when expanded wide
enough to hold the longer shop quips.

## Solution

Replaced it with the wider button-strip variant, which is naturally closer to
the shape we need for a long text plaque.

## Tuning knobs

- `scripts/ui/shop/ShopUI.gd`
  - selected quip-frame atlas and slice region

## Known follow-ups

- If Danny finds an even longer-native plaque later, this system is now easy to
  swap again without changing the rest of the shop.
