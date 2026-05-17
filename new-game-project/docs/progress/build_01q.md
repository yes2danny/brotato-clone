# Build 01q — v0.1.0

Date: 2026-05-16

## Summary

Moved the Spellbook detail card to the right side and reshaped it into a much
shorter, wider plaque.

## Files changed

- `scenes/ui/menus/SpellTreeUI.tscn` — repositioned and resized the detail card
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01p` to `01q`

## Problem

The detail card was finally staying inside the window, but it still read too tall
and vertical for the tiny amount of text it contains.

## Solution

Shifted it toward the right side of the Spellbook and cut the height down by
roughly half while widening it, so it reads more like a low info plaque than a
skinny receipt.

## Tuning knobs

- `scenes/ui/menus/SpellTreeUI.tscn`
  - `DetailPanel` position and size

## Known follow-ups

- If the right-side placement feels good, future real descriptions should be
  written to fit this compact plaque style.
