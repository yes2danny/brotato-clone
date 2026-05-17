# Build 01b — v0.1.0

Date: 2026-05-16

## Summary

Fixed the Treasure Goblin's stuttering left-right movement when hunting gold near
the player. Goblins now wander/orbit around coin piles instead of glitching back
and forth across the flee-range boundary.

## Files changed

- `scripts/enemies/ai/TreasureGoblinAI.gd` — rewrote `_process_hunting()`
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01a` → `01b`

## Problem

The old hunting logic was a hard binary:

- Player within 280px of goblin → **flee** straight away from player
- Player further than 280px → **chase** straight toward nearest coin

When the player stood near a coin pile, the goblin crossed the 280px boundary
multiple times per second, flipping its movement direction every frame. Result:
the stutter that looked like a teleporting glitch.

A secondary issue: the boost (dash) was triggered any time the player was
within full flee range, so goblins constantly looked panicked.

## Solution

Replaced the if/else flee-or-chase switch with a **blended steering** system.
Every physics frame the goblin sums three force vectors and normalizes:

1. **Gold pull** — toward the nearest uncollected coin. Weight fades as the
   goblin gets within ~120px so it doesn't slam into the pile.
2. **Player repulsion** — away from the player, with a squared falloff (`t * t`)
   inside flee_range. Smooth ramp instead of an on/off switch.
3. **Orbit tangent** — a vector perpendicular to the gold direction so the
   goblin curves around the pile. The orbit side is chosen to lead away from
   the player so the arcs look intentional.

A small time-based sine **wobble** is added so motion looks organic. The phase
is offset by `global_position.x` so multiple goblins don't wobble in sync.

The arena-edge center-pull from the old code is preserved to prevent the goblin
from getting cornered while orbiting.

The boost trigger was tightened from `flee_range` (280px) to `flee_range * 0.6`
(~168px) so dashes only fire when the player is closing in for the kill.

The retreat-when-low-gold and hiding behaviors were left untouched — those were
working as intended.

## Tuning knobs

In `_process_hunting()`:

- `approach_weight` divisor (currently `/ 120.0`) — bigger = more wandering near
  the pile, smaller = more direct approach.
- `wobble * 0.15` magnitude — bigger = more organic drift, smaller = stiffer.
- `away_from_player * threat * 1.6` — bigger = more dramatic player avoidance.
- `panic_range = flee_range * 0.6` — controls when the dash boost fires.

## Known follow-ups

- Multiple goblins don't actively avoid clumping into each other yet — they may
  still pile up on the same coin. Could add a simple separation force later.
- The wobble uses `Time.get_ticks_msec()` which is fine but not framerate-tied;
  worth re-checking if we ever change physics tick rate.
