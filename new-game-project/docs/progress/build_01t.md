# Build 01t — v0.1.0

Date: 2026-05-16

## Summary

Fixed the shop title collapsing into a one-letter-wide vertical stack after the
lantern decoration pass.

## Files changed

- `scripts/ui/shop/ShopUI.gd` — gave the shop title a real minimum width and disabled title wrapping
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01s` to `01t`

## Problem

Adding the decorative title row let `Rift Resupply` shrink too far inside the
horizontal container, so Godot wrapped it one character per line.

## Solution

Kept the lanterns, but gave the title a fixed minimum width and turned wrapping
off for that label so it stays a normal title.

## Tuning knobs

- `scripts/ui/shop/ShopUI.gd`
  - title minimum width

## Known follow-ups

- None from this fix; this was a straight regression repair.
