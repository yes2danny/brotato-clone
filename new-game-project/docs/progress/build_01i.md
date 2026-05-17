# Build 01i — v0.1.0

Date: 2026-05-16

## Summary

Moved the spell tree into the between-wave flow and rebuilt it as a branching
spellbook-style map instead of an in-run list screen.

## Files changed

- `scripts/ui/menus/SpellTreeUI.gd` — rebuilt the spell tree as a branching constellation map
- `scripts/ui/shop/ShopUI.gd` — added Shop / Spellbook tabs during the between-wave screen
- `scripts/ui/hud/GameUI.gd` — removed the mid-wave spell tree spawn
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01h` to `01i`

## Problem

The first tree pass opened during combat and looked like a row list, which did not
match the intended fantasy or the provided visual references.

## Solution

The tree now appears only during the between-wave screen, beside the shop, and is
drawn as a branching spellbook map with connected nodes, side branches, and a
detail panel for hover text.

## Tuning knobs

- `SpellTreeUI.gd`
  - `BRANCH_LAYOUT`
  - `BRANCH_LABEL_POSITIONS`
- `ShopUI.gd`
  - tab order and panel sizing

## Known follow-ups

- Replace text-only labels with final spell icons.
- Add real unlock costs and path selection once the spell progression rules are locked.
- Further style-pass the tab chrome after the player judges the first branching layout.
