# Build 01w — v0.1.0

Date: 2026-05-16

## Summary

Fixed the Spellbook resize regression caused by capturing its layout while the
hidden tree was still living inside the smaller Shop tab.

## Files changed

- `scripts/ui/menus/SpellTreeUI.gd` — captures a fresh reference layout only when the Spellbook actually opens
- `scripts/ui/shop/ShopUI.gd` — opens/closes the tree with the real tab state instead of opening it while hidden
- `scripts/systems/BuildInfo.gd` — bumped BUILD_ID from `01v` to `01w`

## Problem

After the Shop tab was made shorter, the Spellbook could capture its layout from
the wrong parent size before the Spellbook tab was visible. When the real larger
tab opened, the tree scaled from that bad baseline and appeared broken.

## Solution

Stopped opening the Spellbook tree while the Shop tab is active. The tree now
captures its master pose only when the Spellbook tab itself opens, using the
correct real window size.

## Tuning knobs

- none

## Known follow-ups

- If the quip-frame swap still feels visually negligible, decide separately
  whether it is worth keeping; it is unrelated to this Spellbook regression.
