# Build 01o — v0.1.0

Date: 2026-05-16

## Summary

Tightened the Spellbook hover card so it reads like a compact info panel instead
of a tall side window.

## Files changed

- `scenes/ui/menus/SpellTreeUI.tscn` — shortened the detail panel and tightened its spacing
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01n` to `01o`

## Problem

The Spellbook layout was much better, but the little hover panel was too tall for
the amount of information it contained.

## Solution

Reduced the panel height, tightened the vertical spacing, and nudged the body
text slightly smaller so the card feels lighter and more intentional.

## Tuning knobs

- `scenes/ui/menus/SpellTreeUI.tscn`
  - `DetailPanel` height
  - `DetailBox` separation
  - detail body font size

## Known follow-ups

- Once final spell descriptions exist, revisit the exact panel size against real
  content instead of placeholder text.
