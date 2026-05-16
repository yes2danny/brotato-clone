extends Resource

# ─────────────────────────────────────────────
# WaveData — Resource Definition
#
# Defines what happens in a single wave.
# Create a .tres file per wave in resources/enemies/waves/
# (e.g. wave_01.tres, wave_02.tres, wave_boss.tres)
#
# WaveManager applies `WaveCurve` (see docs/Main_ENEMY_WAVE_ROADMAP_V2.html §3–§4) for:
# wave_duration, spawn_interval, min_spawn_interval, hp_mult, dmg_mult, N_max.
#
# ── Pool model (v3) ───────────────────────────
# Each wave is now described as **deltas** against the running PoolState
# autoload, not as a full pool list:
#
#   `pool_additions` (Array[WaveSpawnEntry])
#       Upsert: entries are appended to the active pool, OR — if a scene with
#       the same `resource_path` is already active — replace it in place to
#       tune weight / max_alive. Use this for both new roster entries
#       ("introduce Knight_LVL1") AND for weight rebalancing on existing
#       entries.
#
#   `pool_removals` (Array[PackedScene])
#       Retire every active entry whose `enemy_scene.resource_path` matches.
#       Use this when a type cycles out ("dummy and mimic exit at wave 6").
#       The change is permanent until something is added back later.
#
# Wave 1 should populate `pool_additions` with the starting roster; PoolState
# is empty before then. Anything not touched by a wave persists from the
# previous wave automatically.
#
# Legacy `enemy_pool` is kept as a fallback: if a file leaves both delta
# arrays empty AND fills `enemy_pool`, PoolState treats that as a hard reset
# of the entire pool to those entries (one-shot full override). New wave
# files should not use this — author with the delta arrays.
# ─────────────────────────────────────────────

class_name WaveData

# ── Wave Identity ──
@export var wave_number: int = 1
@export var wave_label: String = "Wave 1"            # Display name (e.g. "Boss Wave!")

# ── Timing ──
@export var wave_duration: float = 30.0              # How many seconds this wave lasts
@export var break_duration: float = 3.0              # Pause after this wave before the next

# ── Spawning ──
@export var spawn_interval: float = 2.0              # Seconds between enemy spawns
@export var min_spawn_interval: float = 0.5          # Floor — never faster than this

# ── Scaling ──
@export var hp_mult: float = 1.0
@export var dmg_mult: float = 1.0

# ── Enemy Mix ──
# Fallback flat-list of enemy scenes if no pool is active. Rarely used since
# PoolState supplies the weighted roster now.
@export var enemy_scenes: Array[PackedScene] = []

# ── PoolState deltas (v3) ──
## Entries to add or upsert into the active pool. Upserts let you tune
## weight / max_alive on an existing roster entry without re-listing the
## whole pool. Match is by `enemy_scene.resource_path`.
@export var pool_additions: Array[WaveSpawnEntry] = []

## Scenes to retire from the active pool. Match is by `resource_path`.
@export var pool_removals: Array[PackedScene] = []

## DEPRECATED — legacy full-pool override. Authoring path:
##  - New waves: leave empty, use `pool_additions` / `pool_removals`.
##  - Old waves: if non-empty AND both delta arrays are empty, PoolState will
##    treat this as a hard reset of the entire pool.
@export var enemy_pool: Array[WaveSpawnEntry] = []

# ── Special Flags ──
@export var is_boss_wave: bool = false               # Future: spawn a boss enemy
@export var boss_scene: PackedScene = null           # The boss to spawn
@export var music_override: AudioStream = null       # Future: different music for boss wave
