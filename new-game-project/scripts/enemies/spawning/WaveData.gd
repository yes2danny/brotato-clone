extends Resource

# ─────────────────────────────────────────────
# WaveData — Resource Definition
#
# Defines what happens in a single wave.
# Create a .tres file per wave in resources/enemies/waves/
# (e.g. wave_01.tres, wave_02.tres, wave_boss.tres)
#
# WaveManager will read these to know what to spawn and when.
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

# ── Enemy Mix ──
# List of enemy scenes to spawn during this wave.
# If empty, WaveManager falls back to the default enemy.
@export var enemy_scenes: Array[PackedScene] = []

# ── Special Flags ──
@export var is_boss_wave: bool = false               # Future: spawn a boss enemy
@export var music_override: AudioStream = null       # Future: different music for boss wave
