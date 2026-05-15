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
# This resource mainly supplies `enemy_pool` (and future boss / mini fields).
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
# List of enemy scenes to spawn during this wave.
# If empty, WaveManager falls back to the default enemy.
@export var enemy_scenes: Array[PackedScene] = []

# Array of WaveSpawnEntry to define weights and max caps.
@export var enemy_pool: Array[WaveSpawnEntry] = []

# ── Special Flags ──
@export var is_boss_wave: bool = false               # Future: spawn a boss enemy
@export var boss_scene: PackedScene = null           # The boss to spawn
@export var music_override: AudioStream = null       # Future: different music for boss wave
