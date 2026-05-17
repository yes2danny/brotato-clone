# Build 01z — v0.1.0

Date: 2026-05-17

## Summary

Added a detailed spell progression design doc so the Spellbook can move from
auto-level unlocks toward a real branch-based 20-wave progression system.

## Files changed

- `docs/SPELL_BRANCH_UNLOCK_PLAN.md` — new design plan covering branch unlocks,
  run pacing, mastery conditions, slot rules, and implementation phases
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01y` to `01z`

## Problem

The project already had a visible Spellbook tree, manual spell slots, and 26
defined spell nodes in `SpellTreeData.gd`, but the underlying progression was
still mostly "hit level X and auto-unlock a spell." That did not match the
shape of the UI, did not fit the 20-wave structure very well, and risked making
late spells feel cheap instead of earned.

## Solution

Wrote a repo doc that audits the live spell setup first, then proposes a
two-layer progression model:

- permanent branch unlocks across many runs
- meaningful branch growth and capstone scarcity inside one run

The plan also separates visual Spellbook promise from real implementation state,
calls out which spells still need unique behavior to feel special, and lays out
a phased path for turning the current spell prototype into a real progression
system.

## Known follow-ups

- Implement the first progression slice from the doc instead of auto-unlocking
  by plain level.
- Add a permanent save-backed branch unlock layer before exposing every branch
  from the start.
- Give key late spells more unique behavior so capstones feel real, not just
  stronger versions of the same generic effect scenes.
