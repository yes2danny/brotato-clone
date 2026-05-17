# Build 01h — v0.1.0

Date: 2026-05-16

## Summary

Redesigned the spell hotbar so it reads like a game HUD instead of a debug panel.

## Files changed

- `scripts/ui/hud/SpellHotbarUI.gd` — replaced the old card-style hotbar with compact icon slots
- `resources/spells/spell_fireball.tres` — added a temporary fire icon
- `resources/spells/spell_ring_of_fire.tres` — added a matching ring icon for later use
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01g` to `01h`

## Problem

The starter spell slot looked bulky and utilitarian: lots of text, a tall panel,
and a debug-like readiness bar that did not match the rest of the game's pixel UI.

## Solution

Rebuilt the hotbar around the existing pixel HUD slot art. Slots are now smaller,
icon-first, school-colored, and show cooldown as a dark fill over the icon with a
small timer only while cooling down.

## Tuning knobs

- `SpellHotbarUI.gd`
  - `SLOT_W`
  - `SLOT_H`
  - `FRAME_SIZE`
  - `SLOT_GAP`

## Known follow-ups

- Replace temporary spell icons with final custom icons once the spell list settles.
- Revisit exact position/scale after the player tests it in motion.
