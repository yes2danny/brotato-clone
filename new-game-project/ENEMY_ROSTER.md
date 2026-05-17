# Enemy roster - live reference

Single source of truth for what is actually wired in the project right now,
with special attention to the live Wave 1-9 migration.

**Full megapack planning sheet:** [ENEMY_DESIGN_CATALOG.md](./ENEMY_DESIGN_CATALOG.md)

**Step-by-step enemy wiring workflow:** [ADDING_ENEMIES.md](./ADDING_ENEMIES.md)

---

## How spawning works today

| System | Behavior |
|--------|----------|
| `PoolState` | Holds the active enemy pool for the current run. |
| `wave_NN.tres` | Stores per-wave deltas only: `pool_additions` and `pool_removals`. |
| `WaveManager` | Applies the wave delta before each wave starts. |
| `EnemySpawner` | Rolls from `PoolState.get_pool()` and applies wave scaling from `WaveCurve`. |
| Run reset | Wave 1 starts from an empty pool, then `wave_01.tres` seeds the roster. |

This means a wave can be "wired" even if its `.tres` does not restate every
enemy in that wave. Earlier entries carry forward until later waves remove them.

---

## Verified Wave 1-9 state

This is the verified live state from the actual `wave_NN.tres` files in the
repo right now.

| Wave | Net pool after this wave | Notes |
|-----:|--------------------------|-------|
| 1 | dummy, green, blue | Starting seed roster |
| 2 | dummy, green, blue | Weight retune only |
| 3 | dummy, green, blue, dummy_lvl2, cyclop | Adds the missing middle dummy rung plus cyclop |
| 4 | dummy, green, blue, dummy_lvl2, cyclop | Green carry-forward is now explicitly retuned in `wave_04.tres` |
| 5 | dummy, green, blue, dummy_lvl2, cyclop, mimic | Adds Mimic LVL1 |
| 6 | dummy, green, blue, dummy_lvl2, cyclop, mimic, dummy_lvl3, goblin_barrel_red, dwarfette_lvl1 | Big mid-early expansion |
| 7 | prior pool + frogmonster, ent_lvl2 | Adds the first frog and ent |
| 8 | prior pool + mimic_lvl2, sorcerer_lvl1, orc_archer_green | Adds the first ranged-looking late-early bodies |
| 9 | blue, cyclop, mimic, goblin_barrel_red, dwarfette_lvl1, frogmonster, ent_lvl2, mimic_lvl2, sorcerer_lvl1, orc_archer_green, dwarfette_lvl2, goblinred | Retires dummy ladder + green, adds Dwarfette LVL2 and GoblinRed |

Waves 10-20 still need a separate reconciliation pass. This file only claims
Wave 1-9 as verified current state.

---

## Attack types in code

There are two live enemy behavior paths now:

| Script | Behavior |
|--------|----------|
| `scripts/enemies/ai/EnemyAI.gd` | Chase + contact damage |
| `scripts/enemies/ai/RangedEnemyAI.gd` | Spacing + projectile shots |

Practical read:

- Most of the early roster is still contact-based.
- `Enemy_Cyclop.tscn`, `Enemy_SorcererLVL1.tscn`, and `Enemy_OrcArcherGreen.tscn` already use ranged AI.

---

## Core stat anchors

These are still the main balance anchors that people keep comparing against
when tuning the roster.

| Tier | ID | Scene | Visual | Move speed | Max HP | Damage | Contact cooldown (s) | Rough contact DPS | Role |
|------|----|-------|--------|------------|--------|--------|----------------------|-------------------|------|
| 1 | `enemy_dummy` | `scenes/enemies/Enemy_Dummy.tscn` | Dummy LVL1 | 55 | 21 | 5 | 1.2 | ~4.2 | Tutorial fodder |
| 1 | `enemy_blue` | `scenes/enemies/Enemy_GoblinBlue.tscn` | Blue goblin (barrel) | 130 | 20 | 8 | 1.0 | ~8 | Fast swarm |
| 2 | `enemy_green` | `scenes/enemies/Enemy.tscn` | Green goblin (barrel) | 80 | 30 | 10 | 1.0 | ~10 | Balanced baseline |
| 2 | `enemy_cyclop` | `scenes/enemies/Enemy_Cyclop.tscn` | Cyclop archer | 70 | 110 | 16 | 1.2 | ~13.3 | Mid-wave bruiser / ranged anchor |
| 2 | `enemy_mimic` | `scenes/enemies/Enemy_Mimic.tscn` | Mimic LVL1 | 80 | 45 | 9 | 1.0 | ~9 | Capped ambush body |
| 3 | `enemy_red` | `scenes/enemies/Enemy_GoblinRed.tscn` | Heavy red goblin | 50 | 230 | 22 | 1.5 | ~14.7 | Slow tank / punishment body |

---

## Already wired as enemy scenes

- `Goblin_Barrel_01` -> Green
- `Goblin_Barrel_02` -> Blue
- `Goblin_Barrel_03` -> Barrel red
- `GoblinRed` -> heavy red goblin variant
- `Cyclop_Archer_01` -> Cyclop
- `Dummy_LVL1` -> Dummy
- `Dummy_LVL2` -> Dummy LVL2
- `Dummy_LVL3` -> Dummy LVL3
- `Mimic_LVL1` -> Mimic LVL1
- `Mimic_LVL2` -> Mimic LVL2
- `Dwarfette_LVL1` -> Dwarfette LVL1
- `Dwarfette_LVL2` -> Dwarfette LVL2
- `FrogMonster` -> FrogMonster
- `Ent_LVL2` -> Ent LVL2
- `Sorcerer_LVL1` -> Sorcerer LVL1
- `Orc_Archer_01` (green) -> Orc Archer green

Special / separate from the normal wave pool:

- `Enemy_TreasureGoblin.tscn` -> frequent special thief spawn

---

## Already used as player

- `Knight_LVL1`-`Knight_LVL4` are reserved for player progression visuals, not enemy pools.

---

## Good next picks

Priority assumes you want the next additions to stay readable and low-scope.

| Priority | Asset folder | Why it fits |
|----------|--------------|-------------|
| 1 | `Ent_LVL1` | Easy sibling to an already-live ent body |
| 2 | `Dummy_LVL4` | Clean extension of an already-live ladder |
| 3 | `RhinoMonster_01_Regular` | Good first elite once Wave 10+ gets attention |
| 4 | `Goblin_Regular_01`-`03` | Easy visual variety inside a familiar role |
| 5 | `MonsterSlasher_01` | Distinct silhouette without inventing a boss system |

Use caution with:

- `Monsterfly_01`: acceptable only if you are okay with a grounded "bug chaser" read for now.
- Higher sorcerers / ranged orcs: easiest once the current ranged body balance is settled.
- `FrogBoss`, `GameMaster`, `RhinoMonster_*`: best saved for Wave 10+ or boss passes.

---

## Summary answers

1. **How many wired?** `16` normal wave-pooled enemy scenes are live through Wave 9, plus `Enemy_TreasureGoblin` as a separate special spawn.
2. **Per-wave enemy types?** Yes. `PoolState` is the live source of truth and each wave file only applies deltas.
3. **Attack types?** Mostly contact, with ranged AI already live for Cyclop, Sorcerer LVL1, and Orc Archer green.
4. **What still needs fixing in early waves?** Mostly tracking and Wave 4 nuance, not a full missing-roster problem anymore.
