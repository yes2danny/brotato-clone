# Enemy roster — design reference

Single source of truth for **what is implemented today**, **how spawning works by wave**, **attack capabilities**, and **which asset packs make sense as next enemies**.

**Full megapack table (every character, rank, suggested stats, recommended wave when pools exist):** [ENEMY_DESIGN_CATALOG.md](./ENEMY_DESIGN_CATALOG.md)

For the step-by-step workflow to wire a new scene, see [ADDING_ENEMIES.md](./ADDING_ENEMIES.md).

---

## How spawning works today (important)

| System | Behavior |
|--------|----------|
| **Active roster** | The **`PoolState` autoload** (`scripts/systems/PoolState.gd`) holds an `Array[WaveSpawnEntry]` representing what is currently in rotation. `EnemySpawner` weight-rolls from that list every spawn tick (respecting per-type `max_alive` caps). |
| **Per-wave deltas** | Each `resources/enemies/waves/wave_NN.tres` declares two arrays: `pool_additions` (upserts — add or retune weight/cap) and `pool_removals` (retire by `PackedScene`). `WaveManager._start_wave()` calls `PoolState.apply_wave(wave_data, n)` before activating the spawner. The pool persists between waves; only the delta lives in each `.tres`. |
| **Wave number** | `WaveManager.current_wave` increments after each wave. Wave duration is sourced from `WaveCurve.wave_duration_seconds(W)` (roadmap v2). |
| **Difficulty ramp** | `EnemySpawner.apply_wave_data()` reads `WaveCurve` to set `spawn_interval`, `N_max`, `hp_mult`, and `dmg_mult` for the wave (multiplied by the spawner's `extra_*` knobs). Enemy stats DO scale with wave via `apply_wave_scaling()` on each instance. |
| **Run reset** | `GameManager.begin_new_run()` calls `PoolState.reset()`, and `WaveManager._start_wave()` also resets when `current_wave == 1` — so the wave_01.tres `pool_additions` is the only seed for the roster on a fresh run. |

### Current per-wave roster (from `wave_NN.tres`)

| Wave | Net pool after this wave | Authored as |
|-----:|--------------------------|-------------|
| 1 | dummy, green, blue | `pool_additions = [dummy(40), green(35), blue(25)]` |
| 2 | dummy, green, blue | weights upserted |
| 3 | dummy, green, blue, cyclop | `+cyclop(20)` |
| 4 | dummy, green, blue, cyclop | weight tune |
| 5 | dummy, green, blue, cyclop, mimic | `+mimic(20, cap 3)` |
| 6 | green, blue, cyclop, red | `−dummy, −mimic, +red(10)` |
| 7–14 | green, blue, cyclop, red | weight tunes only |
| 15 | green, blue, cyclop, red | partial tune (3 entries) |
| 16–19 | green, blue, cyclop, red | weight tunes |
| 20 | dummy, green, blue, cyclop | `−red, +dummy(18)` |

So later waves are harder because **the pool composition shifts toward
tankier types and `WaveCurve` keeps cranking spawn rate + HP/DMG** — not
because every wave file has to re-list the entire roster.

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

These scenes appear in the various `resources/enemies/waves/wave_NN.tres`
`pool_additions` arrays; `PoolState` keeps the union of "currently active"
entries for the spawner.

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
| `Mimic_LVL*` | Already wired into wave 5 as a capped (`max_alive = 3`) ambush type that retires at wave 6 via `pool_removals`. |
| `Vampire_Archer_01` | Documented in ADDING_ENEMIES as a **fast elite** candidate — still contact-only unless you add ranged. |

---

## Summary answers

1. **How many wired?** **Six** scenes — green, blue, red barrel goblins, cyclop, dummy, mimic — cycled in and out of the active pool by the `wave_NN.tres` deltas.
2. **Per-wave enemy types?** **Yes** — `PoolState` is the autoload source of truth. `wave_NN.tres` only carries `pool_additions` / `pool_removals` against the prior wave; everything else persists automatically.
3. **Attack types?** **Contact only** on all current enemies.
4. **Best next models (quick):** **Goblin_Regular** (variants), **Ent** (alternate tank), then **orc / mushroom / slasher** for silhouette variety; add **ranged behavior** only when you extend AI beyond contact damage.
