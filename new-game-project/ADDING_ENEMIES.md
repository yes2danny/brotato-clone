# How to Add a New Enemy Type

This guide is for future AI sessions and the developer. Follow these exact steps every time
you want to add a new enemy to the spawner pool. The system is already built — you just
need to wire up a new scene.

---

## Enemy Roster (already wired in)

**Full table (stats, tiers, spawn-by-wave behavior, attack types, next asset picks):** see [ENEMY_ROSTER.md](./ENEMY_ROSTER.md).

| Scene File | Color | Speed | HP | Damage | Role |
|---|---|---|---|---|---|
| `Enemy.tscn` | Green Goblin | 80 | 30 | 10 | Balanced starter |
| `Enemy_GoblinBlue.tscn` | Blue Goblin | 130 | 20 | 8 | Fast runner, dies easy |
| `Enemy_GoblinRed.tscn` | Red Goblin | 50 | 80 | 20 | Slow tank, hits hard |
| `Enemy_Cyclop.tscn` | Cyclop Archer | 70 | 60 | 15 | Mid-tier bruiser |
| `Enemy_Dummy.tscn` | Dummy | — | — | — | Early-wave fodder (retires ~wave 6) |
| `Enemy_Mimic.tscn` | Mimic | — | — | — | Capped rare spawn (wave 5–6) |
| `Enemy_GoblinRed.tscn` | Red Goblin | 50 | 80 | 20 | Slow tank |

Roster is **not** in `Main.tscn` anymore — see **PoolState + wave files** below.

---

## Quick reference — PoolState (read this first)

| Piece | Role |
|-------|------|
| `PoolState` autoload | Running list of who can spawn **right now** |
| `resources/enemies/waves/wave_NN.tres` | Per-wave **deltas only** — not the full roster |
| `pool_additions` | Add a type, or **upsert** weight / `max_alive` if already active |
| `pool_removals` | Drop a type by `PackedScene` (matched by path) |
| `EnemySpawner` | Weight-rolls from `PoolState.get_pool()` each spawn |

**Rules**

1. **New enemy type** → add one `WaveSpawnEntry` to `pool_additions` on the **first wave** it should appear. Do **not** edit later waves unless you retire or retune it.
2. **Retire a type** → put its scene in `pool_removals` on the wave it leaves. Stays gone until a later wave adds it again.
3. **Change spawn weight only** → on that wave, add a `WaveSpawnEntry` for that scene in `pool_additions` with the new weight (same path = in-place replace). You can list only the entries you are changing, or list everyone active that wave if you prefer a full rebalance snapshot (see `wave_06.tres`).
4. **`weight`** — higher = more common. Rough total across the pool is ~100 for easy mental math, not required.
5. **`max_alive`** — `0` = no per-type cap (global `N_max` from `WaveCurve` still applies). Use e.g. `3` for rare/elite types.
6. **Run start** — `GameManager.begin_new_run()` and wave 1 both call `PoolState.reset()`; wave 1’s `pool_additions` seeds the run.

**Inspector workflow (easiest)**

1. Open `resources/enemies/waves/wave_09.tres` (or whichever wave).
2. Under **Pool Additions**, add an element → set **Enemy Scene**, **Weight**, **Max Alive**.
3. To retire: under **Pool Removals**, add the `PackedScene` to remove.
4. Save. Play from wave 1 or use DevDebug **F6** to skip ahead.

Console on wave change: `[PoolState] wave N  +[...]  -[...]  → size=...`

---

## How to Add Another Enemy

### Step 1 — Find the sprite sheets

All character sprites are in:
```
res://assets/sprites/characters/megapack/<CharacterName>/
```

You need TWO files per enemy:
- `Idle_NxM.png` — the idle sprite sheet (usually N=2, M=1 means 2 frames horizontal)
- `Move_NxM.png` — the walk cycle sprite sheet (e.g. Move_10x1.png = 10 frames)

**To get frame size:** `total_width / frame_count = frame_width`. Height is the full image height.

Example: `Move_10x1.png` at 380×26px → each frame = 38×26px

### Step 2 — Create the scene file

Copy an existing enemy scene as your template:
- Copy `Enemy_GoblinBlue.tscn` for a sprite-sheet enemy (AtlasTexture slicing)
- Copy `Enemy.tscn` if frames are individual PNGs (no slicing needed)

Save the copy as `scenes/enemies/Enemy_YourName.tscn`

**In the file, change:**
1. The `uid=""` to something unique (e.g. `uid://enemy_yourname`)
2. `ext_resource` paths for Idle and Move textures to your new character's files
3. The `AtlasTexture` `region = Rect2(x, 0, frame_width, frame_height)` values
   - Each frame steps by `frame_width` on the X axis
   - Frame 0: Rect2(0, 0, w, h), Frame 1: Rect2(w, 0, w, h), Frame 2: Rect2(2*w, 0, w, h), etc.
4. The `load_steps` count at the top — it must equal (number of ext_resources + number of sub_resources + 1)
5. The node stats: `move_speed`, `damage`, `contact_cooldown`, and `max_health`

**Enemy role design guidelines (keep scope small!):**
- Fast + low HP: speed 120-150, max_health 15-25
- Balanced: speed 70-90, max_health 30-50
- Tank: speed 40-60, max_health 70-100

### Step 3 — Wire it into the pool via a wave file

The spawner reads its roster from the **PoolState** autoload, not from
`Main.tscn`. Each wave's `.tres` in `resources/enemies/waves/` only carries
the delta against the prior wave:

- `pool_additions: Array[WaveSpawnEntry]` — upsert. New scene → appended.
  Existing scene → replaced in place (use this to retune weight / max_alive).
- `pool_removals: Array[PackedScene]` — retire from the active pool.

So adding a new enemy is just: pick the wave where it should first appear,
open that `wave_NN.tres` in the Inspector, and add a `WaveSpawnEntry` to its
`pool_additions` array. It will persist on every later wave automatically
until some later wave puts the same scene in `pool_removals`.

Example — drop Knight_LVL1 into the pool at wave 9:

```
[ext_resource type="PackedScene" uid="uid://enemy_knight_lvl1" path="res://scenes/enemies/Enemy_Knight.tscn" id="9_knight"]

[sub_resource type="Resource" id="Resource_knight"]
script = ExtResource("1_entry")
enemy_scene = ExtResource("9_knight")
weight = 18.0
max_alive = 0

[resource]
...
pool_additions = Array[ExtResource("1_entry")]([SubResource("Resource_knight")])
```

You only need to touch **wave_09.tres**. No edits to waves 10–20.

To retire a type, add it to `pool_removals` on the wave it should leave:

```
pool_removals = Array[PackedScene]([ExtResource("3_dummy"), ExtResource("7_mimic")])
```

That's it. Hit Play and the new roster will appear from that wave on.

---

## How EnemySpawner Works

`scripts/enemies/spawning/EnemySpawner.gd` no longer holds the roster itself.
On every spawn tick it asks `PoolState.get_pool()` for the currently active
`Array[WaveSpawnEntry]` and weight-rolls one (respecting `max_alive` caps).

`scripts/systems/PoolState.gd` (autoload) maintains the running pool. At the
start of each wave, `WaveManager._start_wave()` does:

```gdscript
PoolState.apply_wave(wave_data, current_wave)
```

`apply_wave()` first runs `pool_removals` (match by `enemy_scene.resource_path`),
then upserts `pool_additions`. The pool persists across waves; only the
deltas live in the `.tres` file. `PoolState.reset()` is called from
`GameManager.begin_new_run()` and at the top of wave 1 so a new run always
starts from an empty roster.

The legacy `enemy_pool` field still works as a one-shot full-pool override
when both delta arrays are empty — keep it empty in new wave files.

---

## How EnemyAI Works (same script for every enemy)

All enemies share `scripts/enemies/ai/EnemyAI.gd`. The per-enemy differences are just
`@export` values set on the root CharacterBody2D node in each scene:

| Export var | What it does |
|---|---|
| `move_speed` | How fast it chases (pixels/sec) |
| `damage` | Contact damage per hit |
| `contact_cooldown` | Seconds between damage ticks |
| `xp_gem_scene` | What gem to drop on death (always XPGem.tscn) |

HealthSystem on each enemy controls HP:
| Export var | What it does |
|---|---|
| `max_health` | Starting HP |

---

## Sprite Sheet Animation Format Reference

### Using a sprite sheet (AtlasTexture) — for most enemies

```
[ext_resource type="Texture2D" path="res://...Move_10x1.png" id="5_move"]

[sub_resource type="AtlasTexture" id="AtlasTexture_m0"]
atlas = ExtResource("5_move")
region = Rect2(0, 0, 38, 26)       ← frame 0: x=0

[sub_resource type="AtlasTexture" id="AtlasTexture_m1"]
atlas = ExtResource("5_move")
region = Rect2(38, 0, 38, 26)      ← frame 1: x=frame_width

[sub_resource type="AtlasTexture" id="AtlasTexture_m2"]
atlas = ExtResource("5_move")
region = Rect2(76, 0, 38, 26)      ← frame 2: x=frame_width*2
...
```

Each `AtlasTexture` is one frame — you need one per frame of animation.

### Using individual PNGs — for the green goblin (Enemy.tscn)

When the sprite pack gives you individual files like `000.png`, `001.png`... just reference
each one directly as its own `ext_resource Texture2D`. No AtlasTexture slicing needed.

---

## Full Character Roster — assets/sprites/characters/megapack/

**Design sheet (rank, attack intent, suggested HP/damage, recommended first wave):** [ENEMY_DESIGN_CATALOG.md](./ENEMY_DESIGN_CATALOG.md)

Every folder listed here is a separate character with its own sprite sheets.
Check inside each folder for Idle and Move sheets before building a scene.

### ✅ Already wired as enemy scenes
- Goblin_Barrel_01 (Green Skinned)   → Enemy.tscn            (balanced starter)
- Goblin_Barrel_02 (Blue Skinned)    → Enemy_GoblinBlue.tscn (fast runner)
- Goblin_Barrel_03 (Red Skinned)     → Enemy_GoblinRed.tscn  (slow tank)
- Cyclop_Archer_01                   → Enemy_Cyclop.tscn     (mid-tier bruiser)

### ✅ Already used as player character
- Knight_LVL1   → Player.tscn (player character — Idle + Move sprite sheets)
- Knight_LVL2   — available for player upgrade skins
- Knight_LVL3   — available for player upgrade skins
- Knight_LVL4   — available for player upgrade skins

### 🔲 Not yet wired — available for future enemy or player scenes

**Goblins (more variants)**
- Goblin_Regular_01 (Green Skinned)
- Goblin_Regular_02 (Blue Skinned)
- Goblin_Regular_03 (Red Skinned)

**Dummies (great for early wave fodder)**
- Dummy_LVL1
- Dummy_LVL2
- Dummy_LVL3
- Dummy_LVL4

**Dwarfettes (could be a tougher mid-tier)**
- Dwarfette_LVL1
- Dwarfette_LVL2
- Dwarfette_LVL3
- Dwarfette_LVL4

**Ents (tree monsters — slow tank feel)**
- Ent_LVL1
- Ent_LVL2
- Ent_LVL3
- Ent_LVL4

**Frogs (could be fast/jumpy feel)**
- FrogBoss
- FrogMonster

**Mimics (surprise/ambush enemy idea)**
- Mimic_LVL1
- Mimic_LVL2
- Mimic_LVL3
- Mimic_LVL4

**Orcs (strong enemies for later waves)**
- Orc_Archer_01 (Green Skinned)
- Orc_Archer_02 (Blue Skinned)
- Orc_Archer_03 (Red Skinned)
- Orc_Barbare_01 (Green Skinned)
- Orc_Barbare_02 (Blue Skinned)
- Orc_Barbare_03 (Red Skinned)

**Rhino Monsters (10 color variants — great for elite/boss variants)**
- RhinoMonster_01_Regular
- RhinoMonster_02_Silver
- RhinoMonster_03_Gold
- RhinoMonster_04_Devil
- RhinoMonster_05_Orc
- RhinoMonster_06_OrcRedSkinned
- RhinoMonster_07_Frozen
- RhinoMonster_08_Bioluminescent
- RhinoMonster_09_Radioactive
- RhinoMonster_10_Oniric

**Other monsters**
- MonsterSlasher_01
- Monsterfly_01
- Mushroom

**Sorcerers (could be a ranged-feel enemy)**
- Sorcerer_LVL1
- Sorcerer_LVL2
- Sorcerer_LVL3
- Sorcerer_LVL4

**Special / unique**
- GameMaster   — unique character, maybe save for a boss
- Vampire_Archer_01 — great for a fast elite enemy

---

Remember: **keep scope small**. Don't add enemies just to add them. Add a new type when
you want a specific gameplay role (swarm fodder, elite bruiser, boss, etc.).
When the game needs more variety, pick ONE new enemy and follow the steps above.
