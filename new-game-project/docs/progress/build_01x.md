# Build 01x — v0.1.0

Date: 2026-05-16

## Summary

Replaced the fragile responsive-scaling layout in the Spellbook tab with a
fixed-size centered Canvas, so spell nodes can no longer be flung outside the
gold border at large window sizes.

## Files changed

- `scripts/ui/menus/SpellTreeUI.gd` — rewrote the layout pass to only re-center the authored Canvas and pin the DetailPanel
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01w` to `01x`

## Problem

The Spellbook tab tried to be responsive: on first open it captured every spell
node's position as a fraction of `SpellTreeUI`'s current size, then on resize it
multiplied those fractions by the new size. The capture step ran via
`call_deferred`, but the TabContainer hadn't finished growing to its new minimum
size yet — so the captured "reference size" came out much smaller than the
final size. On the very next resize tick, every node was multiplied by
`actual_size / way_too_small_reference`, which pushed Fire Bomb, Ring of Fire,
Black Hole, Skull Shot, Blood Explosion, Smoke Curse, and Water Whirl past the
gold border entirely.

Build 01w tried to dodge this by only capturing once the Spellbook tab was
visible, but the underlying race (capture vs. final layout settling) was still
present, so the same bug returned at larger window sizes.

## Solution

Dropped the runtime scaling entirely. The hand-authored Canvas inside
`SpellTreeUI.tscn` is already a fixed 1060 x 730 pose — the script now keeps it
at that exact size, simply re-centering it horizontally as the Spellbook window
changes width. Spell nodes, branch labels, and connector lines are children of
Canvas, so they move with it as a single block instead of being individually
re-positioned. The floating DetailPanel is repositioned just outside Canvas's
right edge each layout pass, with clamping so it can never spill outside the
gold border.

Result: the tree always looks like the authored composition, no matter how the
Spellbook window resizes, and there is no timing-sensitive capture step left to
break.

## Tuning knobs

- `scripts/ui/menus/SpellTreeUI.gd`
  - `CANVAS_SIZE`, `CANVAS_TOP`, `CANVAS_MIN_LEFT` — Canvas size and placement
  - `DETAIL_PANEL_SIZE`, `DETAIL_PANEL_MARGIN`, `DETAIL_PANEL_TOP_OFFSET` — hover card placement

## Known follow-ups

- If Danny wants the empty space beside Canvas to feel less bare at very wide
  window sizes, the next move is to expand Canvas (and rewrite the layout
  doc) rather than re-introducing runtime scaling.
- If a future redesign genuinely needs the tree to grow with the window,
  prefer scaling Canvas's `scale` property (with `pivot_offset`) over moving
  individual children — that keeps all positions in lockstep instead of
  relying on a captured baseline.
