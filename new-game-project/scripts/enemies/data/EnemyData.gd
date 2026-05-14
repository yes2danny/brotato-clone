extends Resource

# ─────────────────────────────────────────────
# EnemyData — Resource Definition
#
# This is a DATA SCHEMA, not a gameplay script.
# Instead of hardcoding enemy stats everywhere, you create
# a .tres file for each enemy type (e.g. slime.tres, skeleton.tres)
# and fill in these fields in the Godot Inspector.
#
# HOW TO USE:
#   1. In Godot: right-click resources/enemies/data/ → New Resource
#   2. Search for "EnemyData" → create it
#   3. Fill in the stats in the Inspector
#   4. Drag the .tres file onto your EnemyAI node's "data" export slot
# ─────────────────────────────────────────────

class_name EnemyData

# ── Identity ──
@export var enemy_name: String = "Unknown Enemy"
@export var enemy_sprite: Texture2D = null          # Drag sprite here in Inspector

# ── Combat Stats ──
@export var max_health: int = 30
@export var move_speed: float = 80.0
@export var damage: int = 10                         # Contact damage per hit
@export var contact_cooldown: float = 1.0            # Seconds between hits

# ── Rewards ──
@export var xp_on_death: int = 5                    # How much XP the gem it drops is worth
@export var score_on_death: int = 10                # Future: score system

# ── Wave Scaling ──
# These let you define how this enemy type scales per wave.
# e.g. health_scale_per_wave = 0.1 → +10% health each wave
@export var health_scale_per_wave: float = 0.05
@export var speed_scale_per_wave: float = 0.02
