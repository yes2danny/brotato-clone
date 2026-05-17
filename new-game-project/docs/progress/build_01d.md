# Build 01d — v0.1.0

Date: 2026-05-16

## Summary

Imported the next batch of purchased magic/explosion packs and added a durable
asset library note so future purchases can be checked against what is already owned.

## Files changed

- `docs/ASSET_LIBRARY.md` — added the owned-pack catalog and intake rules
- `assets/_source/magic_and_explosions/*` — archived the newly purchased raw packs
- `assets/vfx/magic/*` — added new magic pack folders and standalone effects
- `assets/vfx/explosions/*` — added new explosion pack folders and loose sets
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01c` to `01d`

## Problem

The project now owns enough VFX packs that it would be easy to rebuy the same
asset later or forget which effects already exist.

## Solution

Imported the new March folders into the project asset library and recorded each
owned pack in one searchable document. Similar-looking explosion sets are kept
separate until they are visually confirmed as duplicates.

## Tuning knobs

- None. This build is asset organization only.

## Known follow-ups

- Visually review the new packs and tag strong candidates for specific spell ideas.
- Verify whether `explosions_pack_02` and `explosions_p2_loose` overlap or are truly separate.
