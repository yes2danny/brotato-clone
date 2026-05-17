# Build 01s — v0.1.0

Date: 2026-05-16

## Summary

Imported the new UI packs, documented what Danny owns, and added the first small
shop decoration from the medieval/fantasy UI haul.

## Files changed

- `assets/_source/ui/*` — organized the four newly supplied UI packs
- `assets/ui/fantasy_ui_paid/atlas.png` — added runtime copy of the paid fantasy UI atlas
- `assets/ui/medieval_ui_paid/atlas.png` — added runtime copy of the paid medieval prop atlas
- `docs/ASSET_LIBRARY.md` — recorded the owned UI packs
- `docs/UI_PACK_REVIEW_2026-05-16.md` — noted what fits the current game best
- `scripts/ui/shop/ShopUI.gd` — added small lantern accents around the shop title
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01r` to `01s`

## Problem

The new UI packs were still loose outside the project, and it was not yet clear
which parts actually fit the game's cleaner dark-gold visual language.

## Solution

Imported the packs into named source folders, added the strongest paid atlases to
runtime UI assets, documented the visual read on each pack, and used only a light
touch in the shop first: small medieval lanterns flanking the title.

## Tuning knobs

- `scripts/ui/shop/ShopUI.gd`
  - `_shop_prop(...)` atlas region and displayed lantern size

## Known follow-ups

- The paid fantasy atlas has better future candidates for menu/inventory framing
  than for a full shop reskin.
- If Danny likes the warmer accent direction, the next tasteful move is probably
  the main menu or future Inventory tab rather than replacing every shop frame.
