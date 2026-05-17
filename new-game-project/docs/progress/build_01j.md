# Build 01j — v0.1.0

Date: 2026-05-16

## Summary

Made the between-wave modal responsive and gave the Spellbook tab a larger panel
so its branching tree fits inside the window that contains it.

## Files changed

- `scripts/ui/shop/ShopUI.gd` — scaled the shop with viewport size and resized per tab
- `scripts/ui/menus/SpellTreeUI.gd` — nudged the inner layout to better use the larger Spellbook canvas
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01i` to `01j`

## Problem

The shop stayed too small on large windows, and the Spellbook tree visibly
overflowed the smaller shop-sized modal.

## Solution

The between-wave window now scales from the viewport instead of using a small
fixed cap. The normal shop opens around half-screen size, while the Spellbook tab
expands into a much larger canvas as soon as it is selected.

## Tuning knobs

- `ShopUI.gd`
  - shop width/height viewport ratios
  - spellbook width/height viewport ratios
  - minimum modal sizes

## Known follow-ups

- Fine-tune final Spellbook spacing once the player judges the larger in-game layout.
- Consider a smoother size transition animation when switching tabs.
