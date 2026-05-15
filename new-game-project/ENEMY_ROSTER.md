# Enemy roster — design reference

Single source of truth for **what is implemented today**, **how spawning works by wave**, **attack capabilities**, and **which asset packs make sense as next enemies**.

**Full megapack table (every character, rank, suggested stats, recommended wave when pools exist):** [ENEMY_DESIGN_CATALOG.md](./ENEMY_DESIGN_CATALOG.md)

For the step-by-step workflow to wire a new scene, see [ADDING_ENEMIES.md](./ADDING_ENEMIES.md).

---

## How spawning works today (important)

| System | Behavior |
|--------|----------|
| **Enemy mix** | `EnemySpawner.enemy_scenes` in `scenes/world/Main.tscn` is a **flat pool**. Every spawn picks **uniformly at random** from all scenes in the array. There is **no** per-wave enemy whitelist in code yet. |
| **Wave number** | `WaveManager.current_wave` increments after each wave. Wave duration default: **60 s** (`WaveManager.wave_duration`). |
| **Difficulty ramp** | Between waves, `EnemySpawner.increase_difficulty(0.2)` runs: **`spawn_interval` decreases by 0.2 s** per wave completed, floored at **`min_spawn_interval` (0.5 s)**. Enemy **stats do not scale** with wave — only **spawn rate** does. |
| **Starting spawn interval** | **2.0 s** between spawns (`EnemySpawner.spawn_interval` default; not overridden in `Main.tscn` for the spawner node). |

**Effective spawn interval at the start of wave `W` (1-based), before any other edits:**

`max(0.5, 2.0 − 0.2 × (W − 1))`

| Wave `W` | Approx. spawn interval (s) |
|----------|----------------------------|
| 1 | 2.0 |
| 2 | 1.8 |
| 3 | 1.6 |
| 4 | 1.4 |
| 5 | 1.2 |
| 6 | 1.0 |
| 7 | 0.8 |
| 8+ | **0.5** (floor) |

So: **every wired enemy can appear from wave 1 onward**; later waves are harder because **more enemies per minute**, not because reds replace blues automatically.

**Future hook (not wired):** `scripts/enemies/spawning/WaveData.gd` defines per-wave `enemy_scenes`, duration, and spawn interval, but **`WaveManager` does not read `.tres` wave files yet**. When that is implemented, this document’s “spawn by wave” column can be replaced with data-driven rows per wave file.

---

## Attack types in the codebase

All enemies use **`scripts/enemies/ai/EnemyAI.gd`**:

- **Chase + contact damage only** — damage applies when the enemy’s body **collides with the player** during `move_and_slide`, respecting `contact_cooldown`.
- **No ranged attacks, no projectiles, no separate melee hitboxes** in the shared AI.

**Interpretation for this roster:**

| Tag | Meaning |
|-----|---------|
| **Contact (body)** | Only damage type implemented. |

Sprites named “Archer” or “Sorcerer” in the asset pack are **visual flavor** until a separate ranged system exists.

---

## Wired enemies (in-game now)

These four scenes are listed in `Main.tscn` → `EnemySpawner.enemy_scenes`.

**Tier** is an informal **design rank** for relative threat in the current contact-only combat (HP, damage per second-ish from cooldown, speed). Not stored in game data.

| Tier | ID | Scene | Visual | Move speed | Max HP | Damage | Contact cooldown (s) | Rough contact DPS | Role |
|------|-----|--------|--------|------------|--------|--------|----------------------|-------------------|------|
| 1 | `enemy_blue` | `scenes/enemies/Enemy_GoblinBlue.tscn` | Blue goblin (barrel) | 130 | 20 | 8 | 1.0 | ~8 | Fast swarm / glass cannon |
| 2 | `enemy_green` | `scenes/enemies/Enemy.tscn` | Green goblin (barrel) | 80 | 30 | 10 | 1.0 | ~10 | Default / balanced |
| 2 | `enemy_cyclop` | `scenes/enemies/Enemy_Cyclop.tscn` | Cyclop (archer art) | 70 | 60 | 15 | 1.2 | ~12.5 | Mid bulk |
| 3 | `enemy_red` | `scenes/enemies/Enemy_GoblinRed.tscn` | Red goblin (barrel) | 50 | 80 | 20 | 1.5 | ~13.3 | Slow tank / punishing touch |

**Gold on kill** (for economy tuning): `EnemyAI._compute_gold_drop()` uses `max_health` and `damage` plus optional `gold_drop_bonus` / `gold_drop_multiplier` (defaults unused on current scenes). Tougher enemies pay slightly more by formula.

---

## Asset pack: already used vs good next picks

Full folder list and workflow: [ADDING_ENEMIES.md](./ADDING_ENEMIES.md) (section **Full Character Roster**).

### Already wired as enemies

- `Goblin_Barrel_01` → Green  
- `Goblin_Barrel_02` → Blue  
- `Goblin_Barrel_03` → Red  
- `Cyclop_Archer_01` → Cyclop  

### Already used as player

- `Knight_LVL1`–`Knight_LVL4` — reserve for player skins / progression, not recommended as generic horde enemies without a deliberate reason.

### Strong candidates for **next** enemy scenes (same AI, low scope)

Priority assumes you still want **contact-only** chasers and **one new role per addition**.

| Priority | Asset folder | Why it fits |
|----------|--------------|-------------|
| 1 | `Dummy_LVL1` (then 2–4) | Reads as **training fodder**; good for a **very low HP / low damage** tier-0 or wave-1-flavored enemy once you add wave-specific pools. |
| 2 | `Goblin_Regular_01`–`03` | **Same fantasy line** as current goblins; easy palette/variant for **slightly different stats** without new art logic. |
| 3 | `Ent_LVL1`–`4` | Clear **slow tank** silhouette; different read than red barrel goblin (similar role, different fantasy). |
| 4 | `Mushroom` or `MonsterSlasher_01` | Distinct **silhouettes** for variety in the random pool. |
| 5 | `Orc_Barbare_*` or `Orc_Archer_*` | Good **“heavier”** reads for late-pool or future high-tier rows — **Archer name is cosmetic** until ranged AI exists. |

### Good for **later** or needs **extra systems**

| Asset / idea | Caveat |
|--------------|--------|
| `Monsterfly_01` | Reads as flyer; with current AI it **still slides on the ground**. Fine as a “bug chaser”; true flight needs new movement. |
| `Sorcerer_LVL*`, ranged orcs | **Needs projectile / cast state** not in `EnemyAI.gd` today. |
| `FrogBoss`, `RhinoMonster_*`, `GameMaster` | Natural **boss or elite** scope — usually one-off scenes, not random horde filler. |
| `Mimic_LVL*` | Fun **ambush** identity; might want spawn rules or a different spawn table when WaveData is wired. |
| `Vampire_Archer_01` | Documented in ADDING_ENEMIES as a **fast elite** candidate — still contact-only unless you add ranged. |

---

## Summary answers

1. **How many wired?** **Four** (green, blue, red barrel goblins + cyclop).  
2. **Per-wave enemy types?** **Not yet** — all four share the same pool from wave 1; difficulty is **spawn interval** only.  
3. **Attack types?** **Contact only** on all current enemies.  
4. **Best next models (quick):** **Dummy** (fodder), **Goblin_Regular** (variants), **Ent** (alternate tank), then **orc / mushroom / slasher** for silhouette variety; add **ranged behavior** only when you extend AI beyond contact damage.

When `WaveManager` reads `WaveData` `.tres` files, update the **“How spawning works”** section and add a table per wave file listing `enemy_scenes` and timings.
