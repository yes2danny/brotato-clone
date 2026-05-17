# Build 01k — v0.1.0

Date: 2026-05-16

## Summary

Expanded the shop content to better fill the larger between-wave window, added a
future-facing Inventory tab, and spaced the Spellbook branches farther apart.

## Files changed

- `scripts/ui/shop/ShopUI.gd` — enlarged shop content and added an Inventory tab stub
- `scripts/ui/menus/SpellTreeUI.gd` — widened the branch layout to reduce overlap
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01j` to `01k`

## Problem

After making the between-wave modal responsive, the shop contents still occupied
too little of the available room, while the Spellbook branches remained too
clustered in the larger canvas.

## Solution

Scaled up the shop cards, icons, spacing, and text to better inhabit the larger
window; added an Inventory placeholder tab for the future equipment view; and
spread all spell families farther apart on the Spellbook map.

## Tuning knobs

- `ShopUI.gd`
  - normal shop modal ratios
  - card height
  - item spacing
- `SpellTreeUI.gd`
  - `BRANCH_LAYOUT`
  - `BRANCH_LABEL_POSITIONS`

## Known follow-ups

- Replace the Inventory placeholder with real build contents later.
- Continue a visual polish pass on Spellbook once the wider spacing is approved.
