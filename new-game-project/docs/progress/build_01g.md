# Build 01g — v0.1.0

Date: 2026-05-16

## Summary

Added the first in-game spell-path screen using the existing skill-tree UI art.

## Files changed

- `scripts/spells/data/SpellTreeData.gd` — added the shared spell-path definitions
- `scripts/ui/menus/SpellTreeUI.gd` — added the new player-facing spell tree overlay
- `scripts/ui/hud/GameUI.gd` — spawns the spell tree during runs
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01f` to `01g`

## Problem

The project had spell ideas and matching skill-tree art, but no visible map
showing how spell families should grow or where the remaining gaps were.

## Solution

Created a simple spell tree that opens with `T` during a run. It uses the
existing colored skill-tree slot art, shows the main evolution line for each
school, marks art gaps with hollow placeholder nodes, and keeps standalone
spells separate from forced upgrade chains.

## Tuning knobs

- `SpellTreeData.gd`
  - branch order
  - node names
  - `has_art` flags for owned vs missing visuals
- `SpellTreeUI.gd`
  - panel size
  - row spacing
  - node sizing

## Known follow-ups

- Replace text-only nodes with final spell icons once the spell list is locked.
- Connect future unlock rules and level-up offers to `SpellTreeData.gd`.
- Decide later whether this lives only on `T`, inside pause, or inside a proper spellbook menu.
