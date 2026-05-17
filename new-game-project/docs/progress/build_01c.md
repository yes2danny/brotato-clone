# Build 01c — v0.1.0

Date: 2026-05-16

## Summary

Added the first playable spell loop: manual hotbar casting, a starter Fireball,
and a visible projectile so the player can actively use a spell from wave 1.

## Files changed

- `scripts/spells/SpellController.gd` — switched spells from auto-cast to manual slot casting
- `scripts/spells/data/SpellData.gd` — added fields needed by reusable spell effects
- `scripts/spells/effects/SpellProjectile.gd` — made the starter Fireball visibly render in-game
- `scripts/ui/hud/SpellHotbarUI.gd` — turned the hotbar into a clickable 3-slot control surface
- `scenes/player/Player.tscn` — wired the player to start with Fireball
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01b` → `01c`

## Problem

The first spell pass was only a prototype:

- spells fired automatically instead of when the player chose
- the hotbar mostly displayed state rather than controlling casts
- the starter projectile had no visible art, so the system looked broken in play

## Solution

Converted the spell loop to manual casting through hotbar slots `1`, `2`, and `3`.
The player now begins with a starter Fireball in slot 1, and the hotbar buttons
call the same casting route for future touch support.

The Fireball still uses the simple nearest-enemy targeting path, but now renders
with bright procedural projectile art so the cast is obvious during gameplay.
The controller/UI split was kept intact so later shop offers and level-up spell
mutations can build on the same structure.

## Tuning knobs

- `spell_fireball.tres`
  - `cooldown`
  - `base_damage`
  - `detection_range`
- `SpellProjectile.gd`
  - `move_speed`
  - `lifetime`

## Known follow-ups

- Add real imported spell art for Fireball instead of the temporary procedural projectile visual.
- Add the run-start spell picker instead of hard-wiring one starter spell.
- Add spell shop offers and level-up mutations after the core casting loop feels right.
