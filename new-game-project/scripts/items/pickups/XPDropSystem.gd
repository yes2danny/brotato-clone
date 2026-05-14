extends Node

# ─────────────────────────────────────────────
# XPDropSystem (autoload)
# All XP ground drops go through here. Designers change ONE resource:
#   res://resources/items/xp_drops/xp_drop_settings.tres
# Code calls: XPDropSystem.spawn_drop(global_position [, scene_override])
# ─────────────────────────────────────────────

const SETTINGS_PATH := "res://resources/items/xp_drops/xp_drop_settings.tres"
const _FALLBACK_GEM := preload("res://scenes/items/pickups/XPGem.tscn")

var _settings: XPDropSettings


func _ready() -> void:
	_load_settings()


func _load_settings() -> void:
	if ResourceLoader.exists(SETTINGS_PATH):
		var res: Resource = load(SETTINGS_PATH)
		if res is XPDropSettings:
			_settings = res as XPDropSettings
			return
	push_warning("XPDropSystem: '%s' must be an XPDropSettings resource." % SETTINGS_PATH)
	_settings = XPDropSettings.new()
	_settings.pickup_scene = _FALLBACK_GEM
	_settings.xp_per_drop = 5
	_settings.spawn_scatter_radius = 18.0


## Spawn one XP pickup at [param at_global]. [param scene_override] is optional
## (per-enemy PackedScene in EnemyAI); if null, uses settings.pickup_scene.
func spawn_drop(at_global: Vector2, scene_override: PackedScene = null) -> void:
	call_deferred("_spawn_drop_deferred", at_global, scene_override)


func _spawn_drop_deferred(at_global: Vector2, scene_override: PackedScene = null) -> void:
	var world: Node = get_tree().current_scene
	if world == null:
		return

	var scene: PackedScene = scene_override
	if scene == null and _settings and _settings.pickup_scene:
		scene = _settings.pickup_scene
	if scene == null:
		scene = _FALLBACK_GEM

	var inst: Node = scene.instantiate()
	world.add_child(inst)

	var scatter: Vector2 = Vector2.ZERO
	if _settings and _settings.spawn_scatter_radius > 0.0:
		var r: float = _settings.spawn_scatter_radius
		scatter = Vector2(randf_range(-r, r), randf_range(-r, r))

	if inst is Node2D:
		(inst as Node2D).global_position = at_global + scatter
	elif inst is Node and "global_position" in inst:
		inst.set("global_position", at_global + scatter)

	var xp_amount: int = 5
	if _settings:
		xp_amount = _settings.xp_per_drop
	if "xp_value" in inst:
		inst.set("xp_value", xp_amount)
