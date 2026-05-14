extends Resource
class_name XPDropSettings

# ─────────────────────────────────────────────
# XPDropSettings — ONE file to swap XP pickup art & tuning
#
# Edit: res://resources/items/xp_drops/xp_drop_settings.tres
#   • pickup_scene — drag any scene root (Area2D/Node2D) that has xp_value
#     if it extends the default XPGem behavior, or implement collection your way.
#   • xp_per_drop — applied when the spawned node has an "xp_value" property.
#   • spawn_scatter_radius — random XY offset so drops do not stack perfectly.
# ─────────────────────────────────────────────

@export_group("Replace this for new art / behavior")
@export var pickup_scene: PackedScene

@export_group("Tuning")
@export var xp_per_drop: int = 5
@export var spawn_scatter_radius: float = 18.0
