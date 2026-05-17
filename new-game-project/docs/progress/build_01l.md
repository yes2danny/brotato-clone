# Build 01l — v0.1.0

Date: 2026-05-16

## Summary

Converted the Spellbook from a code-positioned layout into a hand-authored Godot
scene with draggable spell nodes and live connector lines.

## Files changed

- `scenes/ui/menus/SpellTreeUI.tscn` — added the editable Spellbook scene
- `scenes/ui/menus/SpellNode.tscn` — added reusable hand-placeable spell nodes
- `scripts/ui/menus/SpellTreeUI.gd` — reduced the tree script to behavior only
- `scripts/ui/menus/SpellNode.gd` — added node hover/click behavior
- `scripts/ui/menus/SpellTreeLink.gd` — added live editor-following connector lines
- `scripts/ui/shop/ShopUI.gd` — now loads the authored Spellbook scene
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01k` to `01l`

## Problem

The Spellbook layout was locked inside hardcoded coordinate tables, which made a
visual screen awkward to art-direct by hand.

## Solution

Moved the layout into a real Godot scene. Spell nodes are now visible children in
the editor that can be dragged around directly, while connector lines follow the
node centers automatically. The script keeps only interaction behavior such as
hover, click, and the detail panel.

## Tuning knobs

- `scenes/ui/menus/SpellTreeUI.tscn`
  - drag node positions directly in the editor
  - move branch labels directly in the editor
- `scripts/ui/menus/SpellTreeLink.gd`
  - connector thickness/colors if needed later

## Known follow-ups

- Let Danny hand-compose the final tree silhouette in the editor.
- Replace placeholder labels with final spell icons after the spell list settles.
