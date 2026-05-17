# Build 01n — v0.1.0

Date: 2026-05-16

## Summary

Fixed the Spellbook resize helper so the project no longer calls unsupported
`to_local()` / `to_global()` methods on a `Control`.

## Files changed

- `scripts/ui/menus/SpellTreeUI.gd` — replaced invalid coordinate helpers with safe global-position math
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01m` to `01n`

## Problem

Godot reported: `Function "to_local()" not found in base self.` The resize helper
used coordinate helpers that belong to node types other than `Control`.

## Solution

Converted between root-relative and parent-relative UI positions using
`global_position` differences, which is valid for `Control` nodes.

## Tuning knobs

- none

## Known follow-ups

- Give the Spellbook a quick in-editor resize test now that the script parses again.
