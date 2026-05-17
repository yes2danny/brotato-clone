# Spell VFX Review — 2026-05-16

This note is a first visual pass over the owned magic/explosion assets. The goal
is to preserve each spell's fantasy instead of forcing every cool effect into an
upgrade ladder that does not fit.

## Strongest spell candidates

### Fire line

- **Current Fireball** should stay a clean, fast, single-target starter.
- **Best evolution path:** Fireball -> Explosive Fireball -> Pillar Fireball
  - use a compact orange/red explosion on hit first
  - later add `fire_pillar` as the stronger AoE follow-up
- **Keep separate:** `ring_of_fire`
  - it reads as a self-centered aura spell, not as a Fireball upgrade
- **Possible separate fire spells:** `small_meteor`, `lava`, `lava_2`, `fire_transformation`

### Electric line

- `spark`, `lightning`, `electric_explosion_small`, `electric_loop`, and `energy` all fit a
  clean lightning family.
- Strong ladder:
  - Spark Bolt
  - Lightning Strike
  - Chain Spark / Charged Shot
  - Electric Burst
  - Electric Field
- `pulse` also fits here, but it feels more like a beam/rail spell than a normal
  lightning bolt.

### Poison / corruption line

- `acid`, `gas_explosion_green`, `poison_smoke`, `green_vortex`
- This is one of the clearest families in the whole library.
- Strong ladder:
  - Acid Glob
  - Toxic Burst
  - Poison Cloud
  - Corrupting Vortex

### Water line

- `water_drop`, `water_explosion`, `wave`, `water_whirl`
- Also very clean as a family.
- Strong ladder:
  - Water Drop
  - Splash Burst
  - Wave
  - Water Whirl

### Dark / curse line

- `dark_bolt`, `blackhole`, `blackhole_loop`, `skull`, `flame_skull`, `smoke_evil_face`,
  `blood_explosion`, `vfx_vortex`
- These do not all need to be one ladder, but they clearly belong to the same
  school.
- Best use:
  - Skull / Flame Skull as projectile spells
  - Black Hole as a separate gravity-control spell
  - Smoke Evil Face as curse/debuff flavor
  - Blood Explosion as a violent finisher or enemy-death trigger

## Effects that look especially good

- `fire_pillar`
- `fire_bomb`
- `ring_of_fire`
- `small_meteor`
- `electric_loop`
- `green_vortex`
- `poison_smoke`
- `water_whirl`
- `blackhole_loop`
- `pulse`
- the cleaner blue/white recent explosion effects from `explosions_pack_16`

These have a distinct silhouette and would read well in a busy top-down game.

## Effects to use carefully

- `flower`, `rings`, and some of the very tiny single-spark effects are nice,
  but visually quiet. They may disappear once enemies, bullets, pickups, and UI
  are all moving at once.
- Several older orange explosion variants are usable, but many overlap in role.
  They are better as impact choices, enemy deaths, barrels, bombs, or weapon hits
  than as headline spells.
- `flame_skull` is cool, but its cyan/green tint does not naturally belong in the
  same visual family as the current orange Fireball unless we deliberately make
  it a cursed-fire branch.

## Best evolution trees from what we own now

### Fireball family

1. Fireball — single target projectile
2. Explosive Fireball — same projectile, small splash on hit
3. Pillar Fireball — hit creates a `fire_pillar`

### Poison family

1. Acid Glob
2. Toxic Burst
3. Poison Cloud
4. Green Vortex

### Water family

1. Water Drop
2. Splash Burst
3. Wave
4. Water Whirl

### Electric family

1. Spark Bolt
2. Lightning Strike
3. Charged Spark
4. Electric Burst
5. Electric Field / Pulse Beam

### Dark projectile family

1. Dark Bolt
2. Skull Shot
3. Smoke Curse
4. Black Hole

## Effects that should probably stay separate spells

- `ring_of_fire`
- `blackhole` / `blackhole_loop`
- `fire_bomb`
- `small_meteor`
- `pulse`
- `water_whirl`
- `smoke_evil_face`

They each have a strong enough identity that forcing them to be "just the next
version" of something weaker would make the spell list feel smaller, not richer.

## Explosion pack notes

- The newer explosion packs have several cleaner, more readable hits that fit the
  game better than some of the older muddy ones.
- The older sets are still useful as:
  - bomb impacts
  - crate/barrel bursts
  - enemy death effects
  - weapon hit polish
- `explosions_pack_02` and `explosions_p2_loose` are **not exact file duplicates**
  based on a first hash check, so keep both for now.
