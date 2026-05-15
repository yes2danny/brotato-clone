# Enemy design catalog (pre-wiring)

This is the **design source of truth** for every enemy in the megapack and how they slot into waves. **No code is wired from this doc yet** — it tells the next implementation pass what `WaveData` rows to build, what HP/damage to set on each scene, and which wave each enemy first appears in.

It is built around three locked-in facts from the current codebase:

- Player starts at **100 HP** (`HealthSystem.max_health` default — `Player.tscn` does not override).
- Player starts with **Rifle AR 1** (`scenes/player/Player.tscn` → `starting_weapon`): **14 dmg × 7.5 fire rate ≈ 105 DPS**.
- Each wave lasts **60 s** (`WaveManager.wave_duration`); spawn interval starts at **2.0 s** and floors at **0.5 s** by wave 8 (`EnemySpawner.increase_difficulty(0.2)`).

If any of those three numbers change, the wave-power table below must be rebalanced.

Related docs: [ENEMY_ROSTER.md](./ENEMY_ROSTER.md) (current build behavior), [ADDING_ENEMIES.md](./ADDING_ENEMIES.md) (scene-creation steps).

---

## 1. How to read this doc

The flow is: **player power curve → wave pools → per-enemy base stats → wiring plan.**

Every enemy below has **base stats** balanced for its **intro wave**. When that enemy reappears in a later wave it should get **harder via global wave multipliers**, not by being a brand-new scene. The multipliers are defined in §3. The same scene file (`Enemy_GoblinGreen.tscn`) can therefore show up in wave 1 with 30 HP and in wave 6 with ~60 HP without copy-pasting scenes.

### Legend

| Tag | Meaning |
|-----|---------|
| **R1** | Fodder swarm. Should die in **~0.15–0.3 s** of player DPS. |
| **R2** | Standard horde. **0.4–0.7 s** TTK. |
| **R3** | Bruiser. **0.8–1.2 s** TTK. |
| **R4** | Elite. **1.5–2.5 s** TTK. Few on screen at once. |
| **R5** | Boss / unique. **8–15 s** TTK, set-piece spawn. |
| **CT** | Contact damage only — works with today's `EnemyAI.gd`. |
| **CT→RNG** | Ship as contact; ranged AI is a future system. |
| **BOSS** | Custom scene with phases / arena rules; not in random pools. |
| **Weight** | Relative pick probability inside a wave pool. Higher = more frequent. |
| **Max alive** | Hard cap of this type on screen at once. Spawner skips when full. |

> **Weight + Max alive are not implemented yet.** They are the two fields `WaveData` needs added when we wire wave tables. See §6 for the wiring plan.

---

## 2. Player power curve (anchor for all enemy numbers)

The player buys items between waves. Realistic shop pacing in Brotato-likes lets a player gain **~15–25 % effective DPS per shop** and **~10–15 HP per shop** for the first 4–5 waves, then accelerate. Estimates below assume a **mid-skill player** spending most gold on damage and survival.

| Wave | Player DPS (start of wave) | Player HP | Notes |
|-----:|--------------------------:|---------:|-------|
| 1 | **105** | 100 | Starting kit only, no shop yet |
| 2 | 120 | 115 | First shop: +1 item (e.g. Pocket Sand +5 dmg, or Heart Charm +20 HP) |
| 3 | 140 | 130 | Second shop |
| 4 | 165 | 145 | Maybe 2nd weapon or Heavy Round (+10 dmg) |
| 5 | 200 | 165 | Spark Clock / Overclocked Toaster online |
| 6 | 240 | 185 | Weapon upgraded once (×1.15 dmg) |
| 7 | 285 | 205 | Two weapons leveled |
| 8 | 340 | 225 | Armor stacking starts |
| 9 | 405 | 250 | |
| 10 | 480 | 275 | Boss-tier player |
| 11+ | ×1.15 per wave | +15 / wave | Late-game runaway |

**Why this matters for HP design:** if wave 1 player DPS is 105 and a green goblin has 30 HP, TTK is **0.29 s** — that's an R2 feel. A red goblin at 80 HP in wave 1 would take **0.76 s** to kill (an R4 feel), which is why red goblin must be **pushed out of wave 1** when we wire pools.

---

## 3. Global wave multipliers (the scaling engine)

These are the **two numbers that should be applied at spawn time** by a future `EnemySpawner` upgrade. Every enemy's base stats listed in §5 are its **intro-wave** values; later waves multiply.

```
final_max_health = base_hp  *  HP_MULT[wave]
final_damage     = base_dmg *  DMG_MULT[wave]
final_gold_drop  = base_gold *  GOLD_MULT[wave]    (optional)
```

| Wave | HP_MULT | DMG_MULT | Rationale |
|-----:|--------:|--------:|-----------|
| 1 | 1.00 | 1.00 | Baseline |
| 2 | 1.15 | 1.05 | First shop visit absorbed |
| 3 | 1.30 | 1.10 | |
| 4 | 1.50 | 1.15 | |
| 5 | 1.75 | 1.20 | |
| 6 | 2.00 | 1.30 | Player has ×1.15 weapon upgrade by here |
| 7 | 2.30 | 1.40 | |
| 8 | 2.60 | 1.50 | Spawn interval hits floor 0.5 s — fewer per second is impossible, so each enemy gets tougher instead |
| 9 | 3.00 | 1.65 | |
| 10 | 3.50 | 1.80 | Boss-tier scaling |
| W>10 | prev × 1.15 | prev × 1.10 | Compounded |

**Why HP scales faster than damage:** the player's offense compounds (damage + fire rate + extra weapons stack multiplicatively) so enemy HP must keep pace. The player's defense scales slower (armor, max HP, shields are mostly additive), so enemy damage rises gentler to avoid one-shotting.

**Sanity check — wave 6 green goblin:**
- Base 30 HP × HP_MULT[6] (2.00) = **60 HP**
- Player DPS wave 6 ≈ 240 → TTK = 60 / 240 = **0.25 s** ✓ (still R2 feel)
- Base 10 dmg × DMG_MULT[6] (1.30) = **13 dmg** per touch
- Player HP wave 6 ≈ 185, contact CD 1.0 s → ~14 hits to die ✓

The same goblin in wave 1 = 30 HP / 10 dmg, in wave 6 = 60 HP / 13 dmg. **One scene file, two threat levels.**

---

## 4. Per-wave pool composition (what spawns each wave)

Each wave's enemy pool is a small set (2–4 enemy types) with **weights** and **max-alive caps**. The spawner picks by weight every spawn tick, and refuses to spawn a type that's already at its cap.

Standard pool shape:
- **~70 % weight** on the wave's common fodder (R1 or low-R2).
- **~25 % weight** on the wave's pressure unit (R2 / R3).
- **~5 % weight** on an elite cameo (R3 / R4) when applicable.
- Bosses (R5) are **never** in random pools — they spawn as a scripted event.

### Wave 1 — "Tutorial pressure"
| Enemy | Rank | Weight | Max alive | Why |
|-------|------|------:|---------:|-----|
| `Dummy_LVL1` (new scene) | R1 | 65 | 8 | Slow, soft fodder — teaches spacing |
| `Goblin_Barrel_01` (green) | R2 | 35 | 6 | Standard pressure unit |

Result: about 2 dummies per 1 green goblin. No fast or tank units. **Cyclop, Red Goblin, Blue Goblin are NOT in this pool** (they currently are — this needs fixing when wave tables ship).

### Wave 2 — "Faster pace"
| Enemy | Rank | Weight | Max alive | Why |
|-------|------|------:|---------:|-----|
| `Dummy_LVL1` | R1 | 35 | 8 | Carries over |
| `Goblin_Barrel_01` (green) | R2 | 40 | 8 | Bumped cap |
| `Goblin_Barrel_02` (blue) | R1 | 25 | 4 | New: fast chaser, capped low |

### Wave 3 — "Adds a bruiser"
| Enemy | Rank | Weight | Max alive |
|-------|------|------:|---------:|
| `Goblin_Barrel_01` (green) | R2 | 40 | 8 |
| `Goblin_Barrel_02` (blue) | R1 | 30 | 5 |
| `Mushroom` (new) | R1 | 20 | 6 |
| `MonsterSlasher_01` (new) | R3 | 10 | 2 |

### Wave 4 — "First ranged read"
| Enemy | Rank | Weight | Max alive |
|-------|------|------:|---------:|
| `Goblin_Barrel_01` | R2 | 30 | 8 |
| `Goblin_Barrel_02` | R1 | 25 | 5 |
| `Cyclop_Archer_01` | R3 | 25 | 3 | Pushed from wave 1 to here |
| `MonsterSlasher_01` | R3 | 15 | 2 |
| `Dwarfette_LVL1` (new) | R2 | 5 | 2 | First mid-humanoid silhouette |

### Wave 5 — "Tanks arrive"
| Enemy | Rank | Weight | Max alive |
|-------|------|------:|---------:|
| `Goblin_Barrel_01` | R2 | 25 | 8 |
| `Cyclop_Archer_01` | R3 | 20 | 3 |
| `Goblin_Barrel_03` (red) | R4 | 15 | 2 | Finally introduced; capped at 2 |
| `Ent_LVL1` (new) | R3 | 20 | 3 |
| `Mimic_LVL1` (new) | R2 | 20 | 4 |

### Wave 6 — "Orc pressure"
| Enemy | Rank | Weight | Max alive |
|-------|------|------:|---------:|
| `Goblin_Barrel_01` | R2 | 20 | 8 |
| `Orc_Barbare_01` (new) | R3 | 25 | 4 |
| `Cyclop_Archer_01` | R3 | 15 | 3 |
| `Goblin_Barrel_03` (red) | R4 | 15 | 2 |
| `Ent_LVL1` | R3 | 15 | 3 |
| `Dwarfette_LVL2` (new) | R3 | 10 | 3 |

### Wave 7 — "Elite cameo"
| Enemy | Rank | Weight | Max alive |
|-------|------|------:|---------:|
| `Orc_Barbare_01` | R3 | 25 | 4 |
| `Goblin_Barrel_03` (red) | R4 | 15 | 2 |
| `Ent_LVL2` (new) | R3 | 20 | 3 |
| `Mimic_LVL2` (new) | R3 | 15 | 3 |
| `Rhino_01_Regular` (new) | R4 | 10 | 2 | First rhino — keep cap low |
| `Vampire_Archer_01` (new) | R4 | 5 | 1 | Rare fast elite |
| `MonsterSlasher_01` | R3 | 10 | 2 |

### Wave 8 — "Frozen wall"
| Enemy | Rank | Weight | Max alive |
|-------|------|------:|---------:|
| `Orc_Barbare_02` (new) | R3 | 20 | 4 |
| `Ent_LVL3` (new) | R4 | 20 | 3 |
| `Rhino_01_Regular` | R4 | 15 | 2 |
| `Rhino_07_Frozen` (new) | R4 | 10 | 2 | Slow-wall variant |
| `Goblin_Barrel_03` (red) | R4 | 15 | 3 |
| `Mimic_LVL3` (new) | R3 | 10 | 3 |
| `Vampire_Archer_01` | R4 | 10 | 2 |

### Wave 9 — "Boss prep + heavy mix"
| Enemy | Rank | Weight | Max alive |
|-------|------|------:|---------:|
| `Orc_Barbare_03` (new) | R4 | 20 | 3 |
| `Rhino_09_Radioactive` (new) | R4 | 15 | 2 | Glass elite — fast, high dmg, low HP |
| `Rhino_07_Frozen` | R4 | 10 | 2 |
| `Ent_LVL4` (new) | R4 | 15 | 3 |
| `Dwarfette_LVL4` (new) | R4 | 10 | 3 |
| `Mimic_LVL4` (new) | R4 | 10 | 3 |
| `Vampire_Archer_01` | R4 | 10 | 2 |
| Fodder (`Goblin_Barrel_01`) | R2 | 10 | 6 | Resource refill |

### Wave 10 — "Frog Boss"
- **Scripted spawn:** wave 10 starts the `FrogBoss` arena (single instance). Random pool spawns are **paused or reduced to 50 % rate** while boss is alive.
- Background fodder pool while boss is up:
  | Enemy | Rank | Weight | Max alive |
  |-------|------|------:|---------:|
  | `Mushroom` (re-skinned to frog tadpole if budget) | R1 | 60 | 6 |
  | `FrogMonster` (new) | R2 | 40 | 4 |

### Wave 11+ — "Free pool with global scaling"
After wave 10 the pool merges everything from wave 7–9 with HP_MULT and DMG_MULT compounding by 1.15 / 1.10 per wave. `GameMaster` is the **wave 20 boss** (or true endless milestone).

---

## 5. Enemy catalog — base stats

All stats below are **intro-wave values**. Multiply by `HP_MULT[wave]` / `DMG_MULT[wave]` for later appearances. `Move speed` and `Contact CD` are **not scaled** (those define identity, not difficulty).

### 5.1 Wired enemies (currently in `Main.tscn`)

Stats below are **target base HP after the rebalance**. The currently wired numbers are listed under "Today" so you can see what to edit in each scene file.

| Asset folder | Scene | Rank | Attack | Speed | Today HP | **Target Base HP** | Today Dmg | **Target Base Dmg** | CD | Intro wave |
|--------------|-------|------|--------|------:|---------:|--------------------:|----------:|--------------------:|---:|----------:|
| `Goblin_Barrel_01` (Green) | `Enemy.tscn` | R2 | CT | 80 | 30 | **30** (keep) | 10 | **10** (keep) | 1.0 | 1 |
| `Goblin_Barrel_02` (Blue) | `Enemy_GoblinBlue.tscn` | R1 | CT | 130 | 20 | **20** (keep) | 8 | **8** (keep) | 1.0 | 2 |
| `Cyclop_Archer_01` | `Enemy_Cyclop.tscn` | R3 | CT→RNG | 70 | 60 | **110** | 15 | **16** | 1.2 | 4 |
| `Goblin_Barrel_03` (Red) | `Enemy_GoblinRed.tscn` | R4 | CT | 50 | 80 | **230** | 20 | **22** | 1.5 | 5 |

**TTK check at intro wave:** Green @ wave 1 → 30 HP / 105 DPS = **0.29 s** (R2). Blue @ wave 2 → 23 HP / 120 DPS = **0.19 s** (R1). Cyclop @ wave 4 → 165 HP / 165 DPS = **1.0 s** (R3). Red @ wave 5 → 403 HP / 200 DPS = **2.01 s** (R4). All on target.

**Immediate action:** edit `Enemy_Cyclop.tscn` and `Enemy_GoblinRed.tscn` to the new HP numbers. The current wired values were tuned before any wave scaling existed and are way too soft for the curve in §2–§3.

### 5.2 Player skins (do NOT add to enemy pools)

`Knight_LVL1` – `LVL4` are reserved for the player and progression skins.

### 5.3 New scenes — priority queue

These are the scenes worth building **before** anything else, ranked by impact-per-effort.

| Order | Folder | Rank | Speed | Base HP | Dmg | CD | Intro wave | Weight in intro | Max alive | Notes |
|------:|--------|------|------:|--------:|----:|---:|----------:|----------------:|----------:|-------|
| 1 | `Dummy_LVL1` | R1 | 55 | 21 | 5 | 1.2 | 1 | 65 | 8 | Wave-1 fodder. 21 HP = 2 Glock shots / ~0.2 s rifle TTK |
| 2 | `Mushroom` | R1 | 65 | 22 | 7 | 1.1 | 3 | 20 | 6 | Distinct silhouette for variety |
| 3 | `MonsterSlasher_01` | R3 | 88 | 108 | 14 | 0.9 | 3 | 10 | 2 | High-DPS melee read; cap low. Wave-3 TTK ≈ 1.0 s |
| 4 | `Ent_LVL1` | R3 | 42 | 115 | 13 | 1.3 | 5 | 20 | 3 | Slow wall — different tank fantasy than red goblin |
| 5 | `Dwarfette_LVL1` | R2 | 72 | 55 | 12 | 1.0 | 4 | 5 | 2 | Mid-humanoid for silhouette variety |
| 6 | `Mimic_LVL1` | R2 | 78 | 57 | 13 | 1.0 | 5 | 20 | 4 | Ambush flavor (future: spawn-from-prop) |
| 7 | `Orc_Barbare_01` (Green) | R3 | 68 | 120 | 15 | 1.1 | 6 | 25 | 4 | Late-pool muscle. Wave-6 TTK ≈ 1.0 s |
| 8 | `Rhino_01_Regular` | R4 | 60 | 250 | 20 | 1.2 | 7 | 10 | 2 | First true elite. Wave-7 TTK ≈ 2.0 s |
| 9 | `Vampire_Archer_01` | R4 | 110 | 185 | 16 | 1.0 | 7 | 5 | 1 | Rare fast elite — capped at 1 because deadliest contact DPS. TTK ≈ 1.5 s (intentionally a bit lower-HP R4 because speed makes him scary) |
| 10 | `Rhino_07_Frozen` | R4 | 45 | 330 | 18 | 1.3 | 8 | 10 | 2 | Slow-wall variant. Wave-8 TTK ≈ 2.5 s |
| 11 | `Rhino_09_Radioactive` | R4 | 75 | 205 | 24 | 1.0 | 9 | 15 | 2 | Glass-cannon elite. Wave-9 TTK ≈ 1.5 s |

That's **11 new scenes** to cover waves 1–10 cleanly. Anything beyond is reskins or boss work.

### 5.4 Deeper levels (LVL2–LVL4 of each line)

These exist as **distinct scenes** so we can swap them in via wave tables instead of relying purely on multipliers. Each LVL bump is roughly +25 % HP and +1–2 dmg over the previous level. The wave multiplier still stacks on top.

| Folder | Rank | Speed | Base HP | Dmg | CD | Intro wave | TTK at intro |
|--------|------|------:|--------:|----:|---:|----------:|-------------:|
| `Dummy_LVL2` | R1 | 60 | 24 | 6 | 1.1 | 2 | 0.23 s |
| `Dummy_LVL3` | R2 | 68 | 54 | 9 | 1.0 | 3 | 0.50 s |
| `Dummy_LVL4` | R2 | 75 | 55 | 11 | 1.0 | 4 | 0.50 s |
| `Dwarfette_LVL2` | R3 | 70 | 120 | 14 | 1.0 | 6 | 1.00 s |
| `Dwarfette_LVL3` | R3 | 68 | 124 | 16 | 1.1 | 7 | 1.00 s |
| `Dwarfette_LVL4` | R4 | 65 | 270 | 18 | 1.1 | 9 | 2.00 s |
| `Ent_LVL2` | R3 | 40 | 124 | 16 | 1.3 | 7 | 1.00 s |
| `Ent_LVL3` | R4 | 38 | 262 | 18 | 1.4 | 8 | 2.00 s |
| `Ent_LVL4` | R4 | 36 | 270 | 20 | 1.4 | 9 | 2.00 s |
| `Mimic_LVL2` | R3 | 76 | 124 | 16 | 1.0 | 7 | 1.00 s |
| `Mimic_LVL3` | R3 | 74 | 131 | 17 | 1.1 | 8 | 1.00 s |
| `Mimic_LVL4` | R4 | 72 | 270 | 19 | 1.1 | 9 | 2.00 s |
| `Orc_Barbare_02` (Blue) | R3 | 72 | 131 | 15 | 1.0 | 8 | 1.00 s |
| `Orc_Barbare_03` (Red) | R4 | 58 | 270 | 20 | 1.2 | 9 | 2.00 s |

### 5.5 Goblin Regulars — differentiated, not duplicated

Old draft had Regulars almost identical to Barrels. Fixed: **Regulars are tougher, slower melee; Barrels are the flighty/fragile line.** Now they pull in different directions.

| Folder | Rank | Speed | Base HP | Dmg | CD | Intro wave | Notes |
|--------|------|------:|--------:|----:|---:|----------:|-------|
| `Goblin_Regular_01` (Green) | R3 | 65 | 114 | 14 | 1.1 | 5 | Tougher counterpart to barrel green. TTK ≈ 1.0 s |
| `Goblin_Regular_02` (Blue) | R2 | 100 | 60 | 12 | 1.0 | 6 | Faster than regular green, slower than blue barrel. TTK ≈ 0.5 s |
| `Goblin_Regular_03` (Red) | R4 | 45 | 262 | 22 | 1.4 | 8 | Mini-tank — between red barrel and ent. TTK ≈ 2.0 s |

### 5.6 Rhinos — pruned to 3 distinct picks

Old draft had 10 rhinos at near-identical R4. Fixed: pick three with **clear identities**; the other seven become palette skins for `Rhino_01_Regular` (swap texture only, same scene).

| Folder | Rank | Speed | Base HP | Dmg | CD | Intro wave | Identity & TTK |
|--------|------|------:|--------:|----:|---:|----------:|----------------|
| `Rhino_01_Regular` | R4 | 60 | 250 | 20 | 1.2 | 7 | Baseline elite. TTK ≈ 2.0 s |
| `Rhino_07_Frozen` | R4 | 45 | 330 | 18 | 1.3 | 8 | Slow wall. TTK ≈ 2.5 s |
| `Rhino_09_Radioactive` | R4 | 75 | 205 | 24 | 1.0 | 9 | Glass-cannon. TTK ≈ 1.5 s |

**Defer:** Silver, Gold, Devil, Orc, OrcRedSkinned, Bioluminescent, Oniric — keep folders, treat as **palette skins** of `Rhino_01_Regular` until you have visual budget to differentiate.

### 5.7 Sorcerers — wire ONE pre-ranged

Until projectile AI exists, multiple sorcerers are just identical melee chasers. Pick one mid-tier and shelve the rest.

| Folder | Rank | Speed | Base HP | Dmg | CD | Intro wave | Notes |
|--------|------|------:|--------:|----:|---:|----------:|-------|
| `Sorcerer_LVL2` | R3 | 73 | 120 | 14 | 1.1 | 6 | Wire as contact for now. TTK ≈ 1.0 s |
| `Sorcerer_LVL1/3/4` | — | — | — | — | — | **defer** | Add after ranged AI |
| `Orc_Archer_*` | — | — | — | — | — | **defer** | Add after ranged AI |

### 5.8 Bosses — separate scope, NOT in random pools

Bosses are **one-off scripted scenes** with phases, telegraphs, an intro VFX, and a dedicated reward. They need their own design doc — placeholder targets here so we know the HP / damage band.

**Bosses use absolute HP — they are NOT multiplied by `HP_MULT`.** Otherwise late-game bosses balloon to absurd numbers and feel unkillable. Set their HP directly per wave they're tied to.

| Folder | Rank | Boss wave | Player DPS that wave | **Absolute HP** | Dmg | Phases | Total fight TTK | Notes |
|--------|------|----------:|---------------------:|----------------:|----:|-------:|----------------:|-------|
| `FrogBoss` | R5 | 10 | ~480 | **5,000** | 28 (CT) | 2 (HP threshold 50 %) | ~10 s | Phase 2 should add a telegraphed leap |
| `GameMaster` | R5 | 20 | ~1,500 (projected) | **24,000** | 38 (CT + future RNG) | 3 | ~16 s | Finale — needs ranged AI and phase scripts |

**Action item:** when bosses are next on the menu, write a separate `BOSS_DESIGN.md` covering arena rules, telegraphs, phase HP thresholds, and reward drops. Don't try to cram boss design into wave-pool tables.

### 5.9 Misc — flagged as future systems

| Folder | Status | Why it's deferred |
|--------|--------|-------------------|
| `Monsterfly_01` | Defer | "Flyer" needs vertical movement / ignore-collision rules — not in `EnemyAI.gd` |
| `FrogMonster` | Wire at wave 10 | OK as contact, supports FrogBoss flavor |

---

## 6. Wiring plan — what code changes this implies

This doc requires **three** new pieces in the engine. None of them are written yet.

### 6.1 Required engine extensions

1. **`WaveData.tres` resources, one per wave** — fields: `enemy_pool` (array of structs), `duration`, `spawn_interval`, `boss_scene` (optional), `hp_mult`, `dmg_mult`. Existing `scripts/enemies/spawning/WaveData.gd` is already a stub; needs filling out.
2. **`EnemySpawner` upgrade** — read current `WaveData`, pick by weight, respect `max_alive` per type. Today it picks uniformly from a flat array.
3. **Per-spawn stat scaling** — when `EnemyAI` spawns, multiply `max_health` by `WaveData.hp_mult` and `damage` by `WaveData.dmg_mult`. This is the only way the same scene gets harder each wave.

### 6.2 Order of implementation (small scope first)

| Step | Work | Why it's the next thing |
|-----:|------|-------------------------|
| 1 | Build `Enemy_Dummy.tscn` from `Goblin_Barrel_02` template, use stats from §5.3 row 1 | Lets wave 1 actually have a soft fodder |
| 2 | In `Main.tscn`, **remove** Blue/Red/Cyclop from `EnemySpawner.enemy_scenes` temporarily | Stops wave 1 over-pressure today even before wave tables ship |
| 3 | Extend `WaveData.gd` with the fields in §6.1, save `wave_01.tres`–`wave_03.tres` first | Smallest demo of the system |
| 4 | Patch `WaveManager` to load `wave_NN.tres` and feed it to `EnemySpawner` | Wire it up |
| 5 | Patch `EnemySpawner` to honor `weight` + `max_alive` | Composition rules |
| 6 | Patch `EnemyAI` spawn to apply `hp_mult` + `dmg_mult` from current `WaveData` | Scaling |
| 7 | Build new scenes in priority order from §5.3 | Content fill |
| 8 | Saves `wave_04.tres` – `wave_10.tres` | Full curve |
| 9 | Build `FrogBoss.tscn` + scripted spawn hook in `WaveManager` | First boss |

Stop after step 6 and playtest waves 1–3 with the new system before doing 7+.

### 6.3 Interim fix (do this even before WaveData exists)

While the full system is being built, you can buy time in **one minute** by editing `Main.tscn`:

- Set `EnemySpawner.enemy_scenes = [ExtResource("Enemy.tscn")]` only (green goblin alone).
- Add `Enemy_Dummy.tscn` to that array once it exists.
- Reintroduce the others when their wave tables are ready.

That alone fixes "wave 1 is brutal because cyclop is in the pool."

---

## 7. Gold drop hints (tune as you go)

`EnemyAI._compute_gold_drop()` already uses `max_health` and `damage` plus `gold_drop_bonus` / `gold_drop_multiplier`. The catalog **does not set those today** — recommended starting bonuses below so elites feel worth killing:

| Rank | `gold_drop_bonus` (flat) | `gold_drop_multiplier` |
|------|-----:|-----:|
| R1 | 0 | 1.0 |
| R2 | 0 | 1.0 |
| R3 | +1 | 1.1 |
| R4 | +3 | 1.25 |
| R5 (boss) | +50 lump (drop pile) | n/a |

These get applied on the **scene file**, not multiplied by wave (or the late-game economy explodes).

---

## 8. Row count + status

| Category | Count |
|----------|------:|
| Wired enemies | 4 |
| Player skins (not enemies) | 4 |
| New scenes — priority queue (§5.3) | 11 |
| Deeper LVL scenes (§5.4) | 14 |
| Goblin Regulars (§5.5) | 3 |
| Rhino picks (§5.6) | 3 |
| Sorcerer wired (§5.7) | 1 |
| Bosses (§5.8) | 2 |
| **Total catalog rows** | **42** |
| Folders deferred (sorcerer 3, orc archer 3, rhino 7, monsterfly) | 14 |

Compared to the old catalog's 54 rows: **trimmed by 12**, because duplicates (rhino skins, sorcerer chasers, goblin regular reskins) were either pruned or marked palette-only. The roster is smaller and **more designed**.

---

## 9. What still needs your decisions before wiring

These are open questions that should be answered before step 1 of §6.2:

1. **Starting weapon — is `Rifle AR 1` final?** If you swap to Glock (49 DPS) the wave 1 enemy HP needs to drop by ~50 %. If you swap to Scar H (110 DPS) the numbers above mostly hold.
2. **Wave count for a run.** This doc assumes Brotato-style 10–20 waves. If you want endless, §3 scaling already supports it via the compounding row.
3. **Boss cadence.** Wave 10 + 20 is a guess. Could be 5 / 10 / 15 / 20 instead.
4. **Spawn cap concept.** Are `max_alive` caps **per type** (this doc), **per rank**, or **total on screen**? Per-type is easiest to wire and reads cleanest.

Answer those four and the implementation pass has no ambiguity.
